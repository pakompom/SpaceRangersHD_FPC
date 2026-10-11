"""Command execution and incremental native builds shared by the build recipes."""

import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import tarfile
import time
import urllib.request
from collections.abc import Callable, Iterable, Iterator
from contextlib import contextmanager
from functools import lru_cache
from pathlib import Path

from targets import ROOT

DEPENDENCY_SOURCES = {
    "jpeg": (
        "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.2/libjpeg-turbo-3.1.2.tar.gz",
        "8f0012234b464ce50890c490f18194f913a7b1f4e6a03d6644179fa0f867d0cf",
    ),
    "png": (
        "https://download.sourceforge.net/libpng/libpng-1.6.50.tar.gz",
        "708f4398f996325819936d447f982e0db90b6b8212b7507e7672ea232210949a",
    ),
    "ogg": (
        "https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz",
        "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705",
    ),
    "vorbis": (
        "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz",
        "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b",
    ),
}


def require_tool(name: str) -> Path:
    path = shutil.which(name)
    if path is None:
        raise FileNotFoundError(f"Required tool not found: {name}")
    return Path(path).resolve()


def output(*command: str) -> str:
    # Callers parse stdout as paths, versions, or JSON. Keep diagnostics separate.
    return subprocess.check_output(command, text=True).strip()


def run_step(work: Path, name: str, command: list[str | Path]) -> None:
    """Keep each build step's output beside its generated files."""
    log = work / f"{name}.log"
    print(f"Building {name}…", flush=True)
    started = time.monotonic()
    with log.open("w") as stream:
        try:
            subprocess.run(
                [str(arg) for arg in command],
                cwd=work,
                stdout=stream,
                stderr=subprocess.STDOUT,
                check=True,
            )
        except subprocess.CalledProcessError as error:
            print("\n".join(log.read_text(errors="replace").splitlines()[-30:]))
            raise RuntimeError(f"{name} failed; see {log}") from error
    print(f"Built {name} in {time.monotonic() - started:.1f}s.", flush=True)


def command_signature(command: list[str | Path]) -> str:
    """Track arguments, executable replacement, and build-affecting environment."""
    compiler = require_tool(str(command[0]))
    environment = {
        key: os.environ.get(key)
        for key in (
            "CC",
            "CXX",
            "CFLAGS",
            "CXXFLAGS",
            "CPPFLAGS",
            "LDFLAGS",
            "CPATH",
            "C_INCLUDE_PATH",
            "CPLUS_INCLUDE_PATH",
            "LIBRARY_PATH",
            "SDKROOT",
            "MACOSX_DEPLOYMENT_TARGET",
            "EMCC_CFLAGS",
            "EMMAKEN_CFLAGS",
            "EM_CONFIG",
        )
    }
    return json.dumps(
        [
            list(map(str, command)),
            content_state([compiler]),
            environment,
        ]
    )


@lru_cache(maxsize=128)
def _content_digest(path: Path, _metadata: tuple[int, ...]) -> str:
    # Metadata only avoids rehashing unchanged files within this process. It is
    # not part of the persistent identity: restoring an archive changes ctime.
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def content_state(paths: Iterable[str | Path]) -> list:
    """Inventory contents for build tools and recipes restored across runners."""
    result = []
    for path in sorted(set(map(Path, paths))):
        try:
            stat = path.stat()
            metadata = (stat.st_ino, stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns)
            result.append([str(path), _content_digest(path, metadata)])
        except FileNotFoundError:
            result.append([str(path), None])
    return result


def file_state(paths: Iterable[str | Path]) -> list:
    """Inventory [path, size, mtime_ns, ctime_ns], or [path, None] if missing.

    Include ctime to catch replacements and edits that preserve mtime.
    """
    result = []
    for path in sorted(set(map(Path, paths))):
        try:
            stat = path.stat()
            result.append([str(path), stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns])
        except FileNotFoundError:
            result.append([str(path), None])
    return result


class BuildStamp:
    """Record success only after a step and its final signature both complete.

    Signatures are opaque strings so existing cache formats remain usable.
    A failed step leaves an empty stamp, even if old output files still exist.
    """

    def __init__(self, path: Path):
        self.path = path
        self.previous = path.read_text() if path.is_file() else ""

    def matches(self, signature: str, *outputs: Path) -> bool:
        return (
            bool(signature)
            and self.previous == signature
            and all(path.is_file() for path in outputs)
        )

    @contextmanager
    def recording(self, signature: str | Callable[[], str]) -> Iterator[None]:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("")
        self.previous = ""
        yield
        # Depfiles and generated units are available only after the command.
        current = signature() if callable(signature) else signature
        self.path.write_text(current)
        self.previous = current


def compile_native(
    work: Path,
    command: list[str | Path],
    rebuild: bool,
    tools: tuple[Path, ...] = (),
) -> None:
    target = Path(command[command.index("-o") + 1])
    stamp = BuildStamp(work / f"{target.stem}-command.json")
    depfile = work / f"{target.stem}.d"
    command = [*command, "-MD", "-MF", depfile]
    signature = json.dumps([command_signature(command), file_state(tools)])

    def state() -> str:
        dependencies = shlex.split(depfile.read_text().replace("\\\n", "").split(": ", 1)[1])
        return json.dumps([signature, file_state([work / name for name in dependencies])])

    try:
        current = state()
    except (FileNotFoundError, IndexError, ValueError):
        current = ""
    if not rebuild and stamp.matches(current, target, depfile):
        print(f"{target.stem} is up to date.", flush=True)
        return
    with stamp.recording(state):
        run_step(work, target.stem, command)


def configure_native(work: Path, directory: Path, command: list[str | Path]) -> bool:
    """Configure when needed; report same-path compiler replacements requiring a clean."""
    stamp = BuildStamp(directory / "configure-command.json")
    cache = directory / "CMakeCache.txt"
    inputs = [ROOT / "native/CMakeLists.txt", *ROOT.glob("native/*.patch")]

    def signature() -> str:
        compilers = (
            re.findall(r"^CMAKE_(?:C|CXX)_COMPILER:[^=]+=(.+)$", cache.read_text(), re.MULTILINE)
            if cache.is_file()
            else []
        )
        # The NDK toolchain sets compiler variables without caching them.
        # CMake's generated language files still record the actual tools.
        for language in ("C", "CXX"):
            for config in directory.glob(f"CMakeFiles/*/CMake{language}Compiler.cmake"):
                compilers.extend(
                    re.findall(
                        rf'^set\(CMAKE_{language}_COMPILER "([^"]+)"\)',
                        config.read_text(),
                        re.MULTILINE,
                    )
                )
        return json.dumps(
            [
                command_signature(command),
                content_state(inputs),
                content_state(Path(path).resolve() for path in compilers),
            ]
        )

    if not stamp.matches(signature(), cache):
        try:
            old_state = json.loads(stamp.previous)
            old_compilers = {entry[0]: entry[1:] for entry in old_state[2]}
            unknown_compilers = False
        except (ValueError, IndexError, TypeError):
            old_compilers = {}
            # A failed configure may already have updated CMakeCache.txt.
            # Without the previous signature we cannot trust existing objects.
            unknown_compilers = cache.is_file()
        with stamp.recording(signature):
            run_step(work, "configure", command)
        # CMake tracks changed flags and sources itself, but build systems do
        # not necessarily notice replacement of a compiler at an unchanged path.
        return unknown_compilers or any(
            entry[0] in old_compilers and old_compilers[entry[0]] != entry[1:]
            for entry in json.loads(stamp.previous)[2]
        )
    return False


def sdl_source(native: Path) -> Path:
    cache = (native / "CMakeCache.txt").read_text()
    match = re.search(r"^SDL2_SOURCE_DIR:[^=]+=(.+)$", cache, re.MULTILINE)
    if match is None:
        raise RuntimeError("CMake did not record SDL2_SOURCE_DIR")
    return Path(match[1])


def link_native(
    work: Path,
    command: list[str | Path],
    inputs: list[Path],
    outputs: list[Path],
    rebuild: bool,
) -> None:
    stamp = BuildStamp(work / "link-command.json")
    signature = json.dumps([command_signature(command), file_state(inputs)])
    if not rebuild and stamp.matches(signature, *outputs):
        print("Linked game is up to date.", flush=True)
        return
    with stamp.recording(signature):
        run_step(work, "link", command)


def copy_if_changed(source: Path, destination: Path) -> bool:
    if destination.is_file() and source.read_bytes() == destination.read_bytes():
        return False
    shutil.copy2(source, destination)
    return True


def dependency_source(name: str) -> Path:
    url, checksum = DEPENDENCY_SOURCES[name]
    # Keep the path already recorded in existing Android CMake caches.
    source = ROOT / ".local/android-sources" / f"{name}-{checksum[:12]}"
    if (source / ".complete").is_file():
        return source
    downloads = ROOT / ".local/downloads"
    downloads.mkdir(parents=True, exist_ok=True)
    archive = downloads / url.rsplit("/", 1)[1]
    if not archive.is_file():
        partial = archive.with_suffix(archive.suffix + ".partial")
        print(f"Downloading {url}", flush=True)
        urllib.request.urlretrieve(url, partial)
        partial.replace(archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != checksum:
        raise RuntimeError(f"Dependency checksum mismatch: {archive}")
    source.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as contents:
        for member in contents.getmembers():
            parts = member.name.split("/", 1)
            if len(parts) == 2 and parts[1]:
                member.name = parts[1]
                contents.extract(member, source, filter="data")
    (source / ".complete").write_text(checksum)
    return source


def build_codecs(work: Path, options: list[str], rebuild: bool) -> None:
    """Build pinned codec archives with the platform's CMake toolchain and prefix."""
    dependencies = {
        "jpeg": [
            "-DENABLE_SHARED=OFF",
            "-DENABLE_STATIC=ON",
            "-DWITH_TURBOJPEG=OFF",
            "-DWITH_SIMD=ON",
            "-DWITH_TOOLS=OFF",
        ],
        "png": [
            "-DPNG_SHARED=OFF",
            "-DPNG_STATIC=ON",
            "-DPNG_FRAMEWORK=OFF",
            "-DPNG_TESTS=OFF",
            "-DPNG_TOOLS=OFF",
        ],
        "ogg": [],
        "vorbis": [],
    }
    for name, extra in dependencies.items():
        directory = work / "dependencies" / name
        build = directory / "build"
        directory.mkdir(parents=True, exist_ok=True)
        changed = configure_native(directory, build, [
            "cmake", "-S", dependency_source(name), "-B", build, "-G", "Ninja",
            "-DCMAKE_BUILD_TYPE=Release", *options, "-DBUILD_SHARED_LIBS=OFF", *extra,
        ])  # fmt: skip
        run_step(directory, name, [
            "cmake", "--build", build, "--parallel", "6",
            *(["--clean-first"] if rebuild or changed else []),
        ])  # fmt: skip
        # On Darwin, reinstalling also runs ranlib on the archives. Avoid
        # changing their timestamps and forcing a game relink on every build.
        manifest = build / "install_manifest.txt"
        stamp = BuildStamp(directory / "install-inputs.json")

        def install_state(build: Path = build, manifest: Path = manifest) -> str:
            installed = manifest.read_text().splitlines() if manifest.is_file() else []
            return json.dumps(file_state([
                build / "configure-command.json", manifest, *build.rglob("*.a"), *installed,
            ]))  # fmt: skip

        if not stamp.matches(install_state(), manifest):
            with stamp.recording(install_state):
                run_step(directory, "install", ["cmake", "--install", build])


def build_okgf(
    work: Path,
    release: bool,
    *options: str,
    rebuild: bool = False,
    wasm: bool = False,
    jobs: int | None = None,
) -> Path:
    directory = work / "native"
    # Browser native dependencies use -O2 in both game profiles.
    configuration = "Release" if release or wasm else "RelWithDebInfo"
    # Platform options may supply their own release flags (Android retains symbols).
    release_flags = (
        []
        if any(option.startswith("-DCMAKE_C_FLAGS_RELEASE=") for option in options)
        else ["-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG"]
    )
    compiler_changed = configure_native(work, directory, [
        *(["emcmake"] if wasm else []),
        "cmake", "-S", ROOT / "native", "-B", directory, f"-DCMAKE_BUILD_TYPE={configuration}",
        *release_flags,
        *options,
    ])  # fmt: skip
    run_step(
        work,
        "okgf",
        [
            "cmake",
            "--build",
            directory,
            "--parallel",
            *([str(jobs)] if jobs is not None else []),
            *(["--clean-first"] if rebuild or compiler_changed else []),
        ],
    )
    return directory
