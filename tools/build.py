#!/usr/bin/env python3
"""Build Space Rangers HD for desktop, Android or the browser."""

import argparse
import json
import os
import plistlib
import re
import resource
import shlex
import shutil
import subprocess
import time
import zipfile
from pathlib import Path

from compiler import prepare_compiler
from targets import desktop_directory, desktop_target

ROOT = Path(__file__).resolve().parents[1]
PASCAL_FLAGS = ("-Mdelphi", "-FcUTF8")
PASCAL_INPUT_SUFFIXES = {
    ".pas",
    ".pp",
    ".inc",
    ".dpr",
    ".lpr",
    ".ppu",
    ".o",
    ".a",
    ".res",
    ".rc",
    ".s",
    ".as",
    ".ico",
    ".bmp",
    ".png",
    ".manifest",
}


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
    compiler = require_tool(str(command[0]))
    stat = compiler.stat()
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
            str(compiler),
            stat.st_mtime_ns,
            stat.st_ctime_ns,
            stat.st_size,
            environment,
        ]
    )


def file_state(paths) -> list:
    """Conservative input inventory, including removals and preserved mtimes."""
    result = []
    for path in sorted(set(map(Path, paths))):
        try:
            stat = path.stat()
            result.append([str(path), stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns])
        except FileNotFoundError:
            result.append([str(path), None])
    return result


def pascal_state(command: list[str | Path], dependencies: tuple[Path, ...]) -> str:
    roots = {Path(str(arg)[3:]) for arg in command if str(arg).startswith(("-Fu", "-Fi"))}
    sources = [Path(arg) for arg in command if str(arg).endswith((".pas", ".pp", ".dpr", ".lpr"))]
    roots.update(path.parent for path in sources)
    # Search paths include nested game directories. Visit each source tree once.
    roots = {path for path in roots if not any(parent in roots for parent in path.parents)}
    files = [
        path
        for root in roots
        for path in root.rglob("*")
        if path.suffix.lower() in PASCAL_INPUT_SUFFIXES and path.is_file()
    ]
    files.extend(sources)
    files.extend(dependencies)
    # Missing or externally replaced generated units also invalidate the cache.
    for arg in command:
        if str(arg).startswith("-FU"):
            files.extend(Path(str(arg)[3:]).glob("*.ppu"))
            files.extend(Path(str(arg)[3:]).glob("*.o"))
    return json.dumps(file_state(files))


def compile_pascal(
    work: Path,
    command: list[str | Path],
    rebuild: bool,
    artifact: Path,
    dependencies: tuple[Path, ...] = (),
) -> bool:
    # FPC tracks unit/source dependencies, but not every change to compiler options.
    stamp = work / "pascal-command.json"
    inputs = work / "pascal-inputs.json"
    # LLVM object emission runs a separate Clang executable. Its replacement
    # must invalidate the game/package objects as well as the compiler's RTL.
    directory = next((str(arg)[3:] for arg in reversed(command) if str(arg).startswith("-FD")), "")
    prefix = next((str(arg)[3:] for arg in reversed(command) if str(arg).startswith("-XP")), "")
    clang = require_tool(str(Path(directory) / (prefix + "clang")))
    signature = json.dumps([command_signature(command), file_state([clang])])
    state = pascal_state(command, dependencies)
    same_command = stamp.is_file() and stamp.read_text() == signature
    previous_inputs = inputs.read_text() if inputs.is_file() else ""
    same_inputs = previous_inputs == state
    if not rebuild and same_command and same_inputs and artifact.is_file():
        print("Pascal code is up to date.", flush=True)
        return False
    # FPC compares source timestamps at whole-second resolution. A preserved
    # timestamp (or two edits in one second) must really invalidate the PPUs.
    invalidate_units = False
    if not same_inputs:
        linked_files = set(map(str, dependencies))
        try:
            before = {e[0]: e[1:] for e in json.loads(previous_inputs) if e[0] not in linked_files}
            after = {e[0]: e[1:] for e in json.loads(state) if e[0] not in linked_files}
            invalidate_units = before.keys() != after.keys() or any(
                old != after[name]
                and (
                    len(old) != 3
                    or len(after[name]) != 3
                    or Path(name).suffix in (".ppu", ".o")
                    or old[1] // 1_000_000_000 == after[name][1] // 1_000_000_000
                )
                for name, old in before.items()
            )
        except (ValueError, TypeError):
            invalidate_units = True
    if rebuild or not same_command or invalidate_units or ("-Ur" in command and not same_inputs):
        if "-Ur" in command:
            # Released dependencies ignore -B; invalidate their generated PPUs
            # before recompiling this package with its own language mode.
            for unit in work.glob("*.ppu"):
                unit.unlink()
        build_command = [command[0], "-B", *command[1:]]
    else:
        build_command = command
    # A failed build must not leave units compiled with a mixture of settings.
    stamp.write_text("")
    run_step(work, "pascal", build_command)
    stamp.write_text(signature)
    inputs.write_text(pascal_state(command, dependencies))
    return True


def compile_native(
    work: Path,
    command: list[str | Path],
    rebuild: bool,
    tools: tuple[Path, ...] = (),
) -> None:
    target = Path(command[command.index("-o") + 1])
    stamp = work / f"{target.stem}-command.json"
    depfile = work / f"{target.stem}.d"
    command = [*command, "-MD", "-MF", depfile]
    signature = json.dumps([command_signature(command), file_state(tools)])

    def state() -> str:
        dependencies = shlex.split(depfile.read_text().replace("\\\n", "").split(": ", 1)[1])
        return json.dumps([signature, file_state([work / name for name in dependencies])])

    if (
        not rebuild
        and target.is_file()
        and depfile.is_file()
        and stamp.is_file()
        and stamp.read_text()
    ):
        try:
            unchanged = stamp.read_text() == state()
        except (IndexError, ValueError):
            unchanged = False
        if unchanged:
            print(f"{target.stem} is up to date.", flush=True)
            return
    stamp.write_text("")
    run_step(work, target.stem, command)
    stamp.write_text(state())


def configure_native(work: Path, directory: Path, command: list[str | Path]) -> bool:
    """Configure when needed; report same-path compiler replacements requiring a clean."""
    stamp = directory / "configure-command.json"
    cache = directory / "CMakeCache.txt"
    inputs = [ROOT / "native/CMakeLists.txt", *ROOT.glob("native/*.patch")]

    def signature() -> str:
        compilers = (
            re.findall(r"^CMAKE_(?:C|CXX)_COMPILER:[^=]+=(.+)$", cache.read_text(), re.MULTILINE)
            if cache.is_file()
            else []
        )
        return json.dumps(
            [
                command_signature(command),
                file_state(inputs),
                file_state(Path(path).resolve() for path in compilers),
            ]
        )

    previous = stamp.read_text() if stamp.is_file() else ""
    if not cache.is_file() or previous != signature():
        try:
            old_state = json.loads(previous)
            old_compilers = {entry[0]: entry[1:] for entry in old_state[2]}
        except (ValueError, IndexError, TypeError):
            old_compilers = {}
        run_step(work, "configure", command)
        current = signature()
        stamp.write_text(current)
        # CMake tracks changed flags and sources itself, but build systems do
        # not necessarily notice replacement of a compiler at an unchanged path.
        return any(
            entry[0] in old_compilers and old_compilers[entry[0]] != entry[1:]
            for entry in json.loads(current)[2]
        )
    return False


def link_native(
    work: Path,
    command: list[str | Path],
    inputs: list[Path],
    outputs: list[Path],
    rebuild: bool,
) -> None:
    stamp = work / "link-command.json"
    signature = json.dumps([command_signature(command), file_state(inputs)])
    if (
        not rebuild
        and all(path.is_file() for path in outputs)
        and stamp.is_file()
        and stamp.read_text() == signature
    ):
        print("Linked game is up to date.", flush=True)
        return
    stamp.write_text("")
    run_step(work, "link", command)
    stamp.write_text(signature)


def copy_if_changed(source: Path, destination: Path) -> bool:
    if destination.is_file() and source.read_bytes() == destination.read_bytes():
        return False
    shutil.copy2(source, destination)
    return True


def build_okgf(work: Path, release: bool, *options: str, rebuild: bool = False) -> Path:
    directory = work / "native"
    configuration = "Release" if release else "RelWithDebInfo"
    compiler_changed = configure_native(work, directory, [
        "cmake", "-S", ROOT / "native", "-B", directory, f"-DCMAKE_BUILD_TYPE={configuration}",
        "-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG",
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
            *(["--clean-first"] if rebuild or compiler_changed else []),
        ],
    )
    return directory


def pascal_flags(release: bool, *platform_paths: Path) -> list[str]:
    search_paths = [
        *platform_paths,
        ROOT / "platform",
        ROOT / "vendor/fpc/packages/oggvorbis/src",
        ROOT / "vendor/fpc/packages/fcl-image/src",
        ROOT / "vendor/fpc/packages/pasjpeg/src",
        ROOT / "source",
        *sorted(path for path in (ROOT / "source").rglob("*") if path.is_dir()),
    ]
    return [
        *PASCAL_FLAGS,
        "-O4" if release else "-O2",
        *(["-OoAUTOINLINE"] if release else []),
        # -O4 enables field reordering and fast math; override it afterward.
        "-OoNOORDERFIELDS",
        "-OoNOFASTMATH",
        "-gl",
        f"-Fi{ROOT / 'source'}",
        *(f"-Fu{path}" for path in search_paths),
    ]


def build_paszlib(
    work: Path, compiler: Path, compiler_flags: list[str], rebuild: bool, *options: str
) -> Path:
    directory = work / "paszlib"
    directory.mkdir(parents=True, exist_ok=True)
    # This FPC package uses ObjFPC syntax. Build released units separately so
    # a game rebuild in Delphi mode does not recompile the package in that mode.
    compile_pascal(directory, [
        compiler, *compiler_flags, "-Mobjfpc", "-Ur", "-O2", *options,
        f"-FU{directory}", f"-FE{directory}",
        f"-Fu{ROOT / 'vendor/fpc/packages/hash/src'}",
        ROOT / "vendor/fpc/packages/paszlib/src/paszlib.pas",
    ], rebuild, directory / "paszlib.ppu")  # fmt: skip
    return directory


def build_macos(release: bool, rebuild: bool = False, *, lto: bool = False) -> Path:
    compiler, compiler_flags = prepare_compiler("macos", run_step, lto=lto)
    clang = require_tool("clang")
    sdk = output("xcrun", "--show-sdk-path")
    work = desktop_directory(ROOT, "macos", release, lto)
    app = work / "Space Rangers HD.app"
    libraries = app / "Contents/MacOS"
    units = work / "units"
    for directory in (libraries, units):
        directory.mkdir(parents=True, exist_ok=True)

    native = build_okgf(
        work,
        release,
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0",
        f"-DCMAKE_C_COMPILER={clang}",
        "-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG -g",
        rebuild=rebuild,
    )
    # Signing changes the bundled copy. Compare the original library's state,
    # rather than treating the added signature as a new source change.
    copy_stamp = work / "okgf-copy.json"
    copy_state = json.dumps(file_state([native / "libokgf.dylib"]))
    changed = (
        not (libraries / "libokgf.dylib").is_file()
        or not copy_stamp.is_file()
        or copy_stamp.read_text() != copy_state
    )
    if changed:
        shutil.copy2(native / "libokgf.dylib", libraries)
        copy_stamp.write_text(copy_state)
    paszlib = build_paszlib(work, compiler, compiler_flags, rebuild, "-Aclang-llvm-darwin")
    changed = compile_pascal(work, [
        compiler, *compiler_flags, *pascal_flags(release, paszlib), "-Aclang-llvm-darwin",
        f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        f"-Fl{output('brew', '--prefix')}/lib",
        "-k-lokgf", "-k-rpath", "-k@executable_path", f"-XR{sdk}",
        # Retain the linker's generated object so dsymutil can read LTO DWARF.
        *(["-k-object_path_lto", f'-k"{work / "lto.o"}"'] if lto else []),
        ROOT / "source/Rangers.dpr",
    ], rebuild, libraries / "Rangers", (native / "libokgf.dylib",)) or changed  # fmt: skip
    for name in ("Rangers", "libokgf.dylib"):
        if changed or not (libraries / f"{name}.dSYM").is_dir():
            run_step(work, f"symbols-{name}", [
                "xcrun", "dsymutil", libraries / name, "-o", libraries / f"{name}.dSYM",
            ])  # fmt: skip
            changed = True
    info = plistlib.dumps(
        {
            "CFBundleExecutable": "Rangers",
            "CFBundleIdentifier": "org.spacerangershd.fpc",
            "CFBundleName": "Space Rangers HD",
            "CFBundleDisplayName": "Space Rangers HD",
            "CFBundlePackageType": "APPL",
            "CFBundleVersion": "1",
            "NSHighResolutionCapable": True,
            "LSMinimumSystemVersion": "11.0",
        }
    )
    info_file = app / "Contents/Info.plist"
    if not info_file.is_file() or info_file.read_bytes() != info:
        info_file.write_bytes(info)
        changed = True
    if changed or not (app / "Contents/_CodeSignature/CodeResources").is_file():
        run_step(work, "sign", ["codesign", "--force", "--deep", "--sign", "-", app])
    return app


def build_linux(release: bool, rebuild: bool = False, *, lto: bool = False) -> Path:
    work = desktop_directory(ROOT, "linux", release, lto)
    libraries, units = (work / name for name in ("bin", "units"))
    for directory in (libraries, units):
        directory.mkdir(parents=True, exist_ok=True)
    # Check system dependencies before the more expensive compiler bootstrap.
    require_tool("cmake")
    require_tool("pkg-config")
    require_tool("clang")
    require_tool("ld.lld")
    subprocess.run(
        ["pkg-config", "--print-errors", "--exists", "sdl2 >= 2.26", "vorbisfile", "ogg"],
        check=True,
    )
    native = build_okgf(work, release, rebuild=rebuild)
    copy_if_changed(native / "libokgf.so", libraries / "libokgf.so")
    compiler, compiler_flags = prepare_compiler("linux", run_step, lto=lto)
    # FPC's LLVM exception runtime uses libgcc; -n disables system fpc.cfg.
    libgcc = Path(output("clang", "-print-libgcc-file-name"))
    if not libgcc.is_file():
        raise FileNotFoundError("Clang cannot locate libgcc; install the GCC runtime.")
    compiler_flags += [f"-Fl{libgcc.parent}"]
    paszlib = build_paszlib(work, compiler, compiler_flags, rebuild)
    # CMake finds C libraries; FPC needs the corresponding native search paths.
    library_flags = shlex.split(output("pkg-config", "--libs-only-L", "sdl2", "vorbisfile"))
    compile_pascal(work, [
        compiler, *compiler_flags, *pascal_flags(release, paszlib),
        f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        *("-Fl" + flag[2:] for flag in library_flags),
        # LLD resolves command-line -l before FPC's script SEARCH_DIR entries.
        # FPC reparses -k options; quote the whole linker argument for spaced paths.
        f'-k"-L{libraries}"', "-k-lokgf", "-k--enable-new-dtags", "-k-rpath", "-k$ORIGIN",
        ROOT / "source/Rangers.dpr",
    ], rebuild, libraries / "Rangers", (libraries / "libokgf.so", libgcc))  # fmt: skip
    return libraries / "Rangers"


def latest_sdk_directory(parent: Path, prefix: str = "") -> Path:
    """Select a numbered SDK release, excluding preview installations."""
    versions = {}
    for path in parent.iterdir():
        version = path.name.removeprefix(prefix)
        if path.is_dir() and path.name.startswith(prefix) and re.fullmatch(r"\d+(\.\d+)*", version):
            versions[tuple(map(int, version.split(".")))] = path
    if not versions:
        raise FileNotFoundError(f"No installed SDK releases found in {parent}")
    return versions[max(versions)]


def build_wasm(release: bool, rebuild: bool = False, *, lto: bool = False) -> Path:
    emcc = require_tool("emcc")
    emxx = require_tool("em++")
    toolchain = Path(output("em-config", "LLVM_ROOT"))
    work = ROOT / ".local/wasm" / ("release" if release else "debug")
    if lto:
        work = work.with_name(work.name + "-lto")
    units, binary = work / "units", work / "bin"
    for directory in (work, units, binary):
        directory.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("EM_CACHE", str(ROOT / ".local/emscripten-cache"))
    os.environ.setdefault("EMCC_CORES", "6")
    os.environ.setdefault("BINARYEN_CORES", "6")
    compiler, flags = prepare_compiler("wasm", run_step, toolchain, lto=lto)
    paszlib = build_paszlib(work, compiler, flags, rebuild)
    native = work / "native"
    compiler_changed = configure_native(work, native, [
        "emcmake", "cmake", "-S", ROOT / "native", "-B", native,
        "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG",
        *(["-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"] if lto else []),
    ])  # fmt: skip
    run_step(
        work,
        "okgf",
        [
            "cmake",
            "--build",
            native,
            "--parallel",
            "6",
            *(["--clean-first"] if rebuild or compiler_changed else []),
        ],
    )
    compile_pascal(work, [
        compiler, *flags, *pascal_flags(release, paszlib, ROOT / "platform/wasm"),
        "-Cn", "-XMFPC_GAME_MAIN", f"-FU{units}", f"-FE{binary}",
        ROOT / "source/Rangers.dpr",
    ], rebuild, binary / "ppas.sh")  # fmt: skip
    # FPC writes the transitive object list into its deferred linker command.
    # Let Emscripten perform the final link so libc, SDL and the JS loader agree
    # on shared memory, exceptions and filesystem configuration.
    commands = [
        shlex.split(line)
        for line in (binary / "ppas.sh").read_text().splitlines()
        if "wasm-ld" in line
    ]
    link = next((line for line in commands if line and Path(line[0]).name == "wasm-ld"), [])
    objects = [arg for arg in link if arg.endswith(".o")]
    if not objects:
        raise RuntimeError("FPC did not write a WebAssembly object list to ppas.sh.")
    platform = ROOT / "platform/wasm"
    cache = (native / "CMakeCache.txt").read_text()
    sdl_source = re.search(r"^SDL2_SOURCE_DIR:STATIC=(.+)$", cache, re.MULTILINE)
    if sdl_source is None:
        raise RuntimeError("CMake did not record the SDL2 source directory.")
    native_tools = (emcc, toolchain / "clang", toolchain / "wasm-ld")
    native_objects = []
    for source in sorted(platform.glob("*.cpp")):
        obj = work / (source.stem + ".o")
        compile_native(work, [
            emxx,
            "-O2", "-pthread", "-fwasm-exceptions", "-sWASM_LEGACY_EXCEPTIONS=0",
            "-std=c++17", f"-I{Path(sdl_source[1]) / 'include'}",
            *(["-flto"] if lto else []), "-c", source, "-o", obj,
        ], rebuild, native_tools)  # fmt: skip
        native_objects.append(obj)
    link_native(work, [
        emxx, "-O2", "-pthread", "-fwasm-exceptions", "-sWASM_LEGACY_EXCEPTIONS=0",
        *(["-flto"] if lto else []), *objects, *native_objects,
        native / "libokgf.a", native / "libSDL2.a",
        "-sUSE_LIBJPEG=1", "-sUSE_LIBPNG=1", "-sUSE_ZLIB=1", "-sUSE_VORBIS=1",
        "-sWASMFS=1", "-sFORCE_FILESYSTEM=1", "-sPROXY_TO_PTHREAD=1",
        "-sPTHREAD_POOL_SIZE=16", "-sALLOW_BLOCKING_ON_MAIN_THREAD=0",
        "-sALLOW_MEMORY_GROWTH=1", "-sINITIAL_MEMORY=134217728", "-sMAXIMUM_MEMORY=2147483648",
        "-sSTACK_SIZE=8388608", "-sDEFAULT_PTHREAD_STACK_SIZE=8388608",
        "-sEXIT_RUNTIME=1", "-sASSERTIONS=1", "-sGL_ENABLE_GET_PROC_ADDRESS=1",
        "-sOFFSCREEN_FRAMEBUFFER=1", "-sJS_MATH=0", "-g2", "-Wl,--threads=6",
        "-o", binary / "srhd-fpc.js",
    ], [*map(Path, objects), *native_objects, native / "libokgf.a", native / "libSDL2.a", *native_tools],
       [binary / "srhd-fpc.js", binary / "srhd-fpc.wasm"], rebuild)  # fmt: skip
    copy_if_changed(platform / "index.html", binary / "index.html")
    return binary / "index.html"


def prepare_android_binutils(directory: Path, toolchain: Path) -> None:
    for name, executable in (
        ("clang", "clang"),
        ("ld", "ld.lld"),
        ("ar", "llvm-ar"),
        ("strip", "llvm-strip"),
    ):
        link = directory / f"aarch64-linux-android-{name}"
        link.unlink(missing_ok=True)
        link.symlink_to(toolchain / executable)


def build_android(release: bool, rebuild: bool = False) -> Path:
    required = ("ANDROID_HOME", "ANDROID_NDK_HOME", "ANDROID_PREFIX", "SDL_SOURCE")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Set installed dependency paths: " + ", ".join(missing))
    sdk, ndk, prefix, sdl_source = (
        Path(os.environ[name]).expanduser().resolve() for name in required
    )
    toolchain = next((ndk / "toolchains/llvm/prebuilt").glob("*/bin"), None)
    if toolchain is None:
        raise FileNotFoundError(f"No LLVM toolchain found in {ndk}")
    platform = ROOT / "platform/android"
    work = ROOT / ".local/android"
    libraries, units, binutils = (work / name for name in ("lib", "units", "bin"))
    for directory in (libraries, units, binutils):
        directory.mkdir(parents=True, exist_ok=True)
    prepare_android_binutils(binutils, toolchain)
    compiler, compiler_flags = prepare_compiler("android", run_step, toolchain)

    native = build_okgf(
        work,
        release,
        "-G",
        "Ninja",
        f"-DCMAKE_TOOLCHAIN_FILE={ndk}/build/cmake/android.toolchain.cmake",
        "-DANDROID_ABI=arm64-v8a",
        "-DANDROID_PLATFORM=android-26",
        f"-DCMAKE_FIND_ROOT_PATH={prefix}",
        rebuild=rebuild,
    )
    shutil.copy2(native / "libokgf.so", libraries)
    shutil.copy2(prefix / "lib/libSDL2.so", libraries)
    run_step(work, "native", [
        toolchain / "aarch64-linux-android26-clang", "-shared", "-fPIC",
        "-O3" if release else "-O2", f"-I{prefix}/include", f"-I{prefix}/include/SDL2",
        f"-I{platform}", ROOT / "platform/game_native.c", platform / "android_native.c",
        f"-L{prefix}/lib", "-lSDL2_mixer", "-lSDL2", "-ljpeg", "-llog", "-landroid", "-lm",
        "-Wl,-z,max-page-size=16384", "-Wl,-soname,libgamenative.so",
        "-o", libraries / "libgamenative.so",
    ])  # fmt: skip
    system_libraries = toolchain.parent / "sysroot/usr/lib/aarch64-linux-android"
    clang_libraries = Path(output(str(toolchain / "clang"), "-print-resource-dir")) / "lib/linux"
    compile_pascal(work, [
        compiler, *compiler_flags, "-Tandroid", *pascal_flags(release, platform),
        "-Aclang-llvm", "-Cg", f"-Fl{clang_libraries}/aarch64",
        "-XPaarch64-linux-android-",
        f"-FD{binutils}", f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        f"-Fl{system_libraries}/26", f"-Fl{system_libraries}", f'-k"-L{system_libraries}/26"',
        "-k-z", "-kmax-page-size=16384", "-k-lm", "-k--no-undefined",
        platform / "main.lpr",
    ], rebuild, libraries / "libmain.so", (libraries / "libokgf.so", libraries / "libgamenative.so"))  # fmt: skip
    return package_android(work, sdk, sdl_source, prefix, toolchain)


def package_android(work: Path, sdk: Path, sdl_source: Path, prefix: Path, toolchain: Path) -> Path:
    java_home = os.environ.get("JAVA_HOME")
    java = Path(java_home).expanduser() / "bin" if java_home else require_tool("javac").parent
    sdk_tools = latest_sdk_directory(sdk / "build-tools")
    android_jar = latest_sdk_directory(sdk / "platforms", "android-") / "android.jar"
    platform = ROOT / "platform/android"
    classes, dex = work / "classes", work / "dex"
    for directory in (classes, dex):
        directory.mkdir(exist_ok=True)
    sources = sorted(
        [
            *platform.glob("java/**/*.java"),
            *(sdl_source / "android-project/app/src/main/java").rglob("*.java"),
        ]
    )
    run_step(work, "java", [
        java / "javac", "-encoding", "UTF-8", "--release", "8", "-classpath", android_jar,
        "-d", classes, *sources,
    ])  # fmt: skip
    run_step(work, "dex", [
        sdk_tools / "d8", "--lib", android_jar, "--min-api", "26", "--output", dex,
        *sorted(classes.rglob("*.class")),
    ])  # fmt: skip
    unsigned = work / "unsigned.apk"
    run_step(work, "package", [
        sdk_tools / "aapt2", "link", "-I", android_jar,
        "--manifest", platform / "AndroidManifest.xml", "--version-code", "1",
        "--version-name", "0.1", "-o", unsigned,
    ])  # fmt: skip
    with zipfile.ZipFile(unsigned, "a", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(dex / "classes.dex", "classes.dex")
        for name in ("libSDL2.so", "libokgf.so", "libgamenative.so", "libmain.so"):
            packaged = work / f"stripped-{name}"
            shutil.copy2(work / "lib" / name, packaged)
            run_step(
                work, f"strip-{name}", [toolchain / "llvm-strip", "--strip-unneeded", packaged]
            )
            archive.write(packaged, f"lib/arm64-v8a/{name}")
        archive.write(ROOT / "vendor/okgf/LICENSE", "assets/licenses/OKGF.txt")
        archive.write(sdl_source / "LICENSE.txt", "assets/licenses/SDL2.txt")
        licenses = prefix / "share/licenses"
        for path in sorted(licenses.rglob("*")):
            if path.is_file():
                archive.write(path, "assets/licenses/" + str(path.relative_to(licenses)))
    return sign_android_apk(work, unsigned, sdk_tools, java)


def sign_android_apk(work: Path, unsigned: Path, sdk_tools: Path, java: Path) -> Path:
    aligned = work / "aligned.apk"
    run_step(work, "align", [sdk_tools / "zipalign", "-f", "-P", "16", "4", unsigned, aligned])
    key = work / "debug.keystore"
    if not key.exists():
        run_step(work, "key", [
            java / "keytool", "-genkeypair", "-keystore", key, "-alias", "androiddebugkey",
            "-storepass", "android", "-keypass", "android", "-keyalg", "RSA", "-validity", "10000",
            "-dname", "CN=Android Debug,O=Android,C=US",
        ])  # fmt: skip
    apk = work / "Rangers.apk"
    run_step(work, "sign", [
        sdk_tools / "apksigner", "sign", "--ks", key, "--ks-pass", "pass:android",
        "--out", apk, aligned,
    ])  # fmt: skip
    run_step(work, "verify", [sdk_tools / "apksigner", "verify", apk])
    return apk


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--target",
        choices=("linux", "macos", "android", "wasm"),
        default=desktop_target(),
    )
    parser.add_argument("--release", action="store_true", help="Build an optimized release.")
    parser.add_argument("--lto", action="store_true", help="Enable LLVM LTO (desktop or browser).")
    parser.add_argument(
        "--rebuild", action="store_true", help="Rebuild all game units and native code."
    )
    args = parser.parse_args()
    if args.lto and args.target == "android":
        parser.error("--lto is not supported for Android builds.")
    try:
        soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
        desired = 4096 if hard == resource.RLIM_INFINITY else min(4096, hard)
        resource.setrlimit(resource.RLIMIT_NOFILE, (max(soft, desired), hard))
        if args.target == "wasm":
            artifact = build_wasm(args.release, args.rebuild, lto=args.lto)
        elif args.target == "android":
            artifact = build_android(args.release, args.rebuild)
        elif args.target == "linux":
            artifact = build_linux(args.release, args.rebuild, lto=args.lto)
        else:
            artifact = build_macos(args.release, args.rebuild, lto=args.lto)
    except subprocess.CalledProcessError as error:
        parser.exit(1, error.output or str(error))
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"{error}\n")
    print(f"Built: {artifact}")


if __name__ == "__main__":
    main()
