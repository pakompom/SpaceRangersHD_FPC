"""Command execution and incremental native builds shared by the build recipes."""

import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import time
from collections.abc import Callable, Iterable, Iterator
from contextlib import contextmanager
from functools import lru_cache
from pathlib import Path

from targets import ROOT


def require_tool(name: str) -> Path:
    path = shutil.which(name)
    if path is None:
        raise FileNotFoundError(f"Required tool not found: {name}")
    return Path(path).resolve()


def output(*command: str) -> str:
    return subprocess.check_output(command, text=True, stderr=subprocess.STDOUT).strip()


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


def build_okgf(
    work: Path,
    release: bool,
    *options: str,
    rebuild: bool = False,
    wasm: bool = False,
    android: bool = False,
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
            *(["6"] if wasm or android else []),
            *(["--clean-first"] if rebuild or compiler_changed else []),
        ],
    )
    return directory
