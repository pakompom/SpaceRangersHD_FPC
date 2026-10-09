#!/usr/bin/env python3
"""Build Space Rangers HD for Linux, macOS, Android ARM64, or the browser."""

import argparse
import json
import os
import plistlib
import resource
import shlex
import shutil
import subprocess
from pathlib import Path

from android import build_android
from build_support import (
    BuildStamp,
    build_okgf,
    compile_native,
    copy_if_changed,
    file_state,
    link_native,
    output,
    require_tool,
    run_step,
    sdl_source,
)
from compiler import prepare_compiler
from pascal import build_paszlib, compile_pascal, pascal_flags
from targets import ROOT, BuildConfig, add_build_arguments


def build_macos(config: BuildConfig, rebuild: bool) -> Path:
    compiler, compiler_flags = prepare_compiler(config.target, lto=config.lto)
    clang = require_tool("clang")
    sdk = output("xcrun", "--show-sdk-path")
    work, libraries, units = config.work, config.binary_directory, config.units
    config.create_directories()

    native = build_okgf(
        work,
        config.release,
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0",
        f"-DCMAKE_C_COMPILER={clang}",
        "-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG -g",
        rebuild=rebuild,
    )
    # Signing changes the bundled copy. Compare the original library's state,
    # rather than treating the added signature as a new source change.
    copy_stamp = BuildStamp(work / "okgf-copy.json")
    copy_state = json.dumps(file_state([native / "libokgf.dylib"]))
    changed = not copy_stamp.matches(copy_state, libraries / "libokgf.dylib")
    if changed:
        with copy_stamp.recording(copy_state):
            shutil.copy2(native / "libokgf.dylib", libraries)
    paszlib = build_paszlib(work, compiler, compiler_flags, rebuild, "-Aclang-llvm-darwin")
    changed = compile_pascal(work, [
        compiler, *compiler_flags, *pascal_flags(config.release, paszlib), "-Aclang-llvm-darwin",
        f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        f"-Fl{output('brew', '--prefix')}/lib",
        "-k-lokgf", "-k-rpath", "-k@executable_path", f"-XR{sdk}",
        # Retain the linker's generated object so dsymutil can read LTO DWARF.
        *(["-k-object_path_lto", f'-k"{work / "lto.o"}"'] if config.lto else []),
        ROOT / "source/Rangers.dpr",
    ], rebuild, libraries / "Rangers", (native / "libokgf.dylib",)) or changed  # fmt: skip
    package_macos(config, changed)
    return config.artifact


def package_macos(config: BuildConfig, changed: bool) -> None:
    """Update debug symbols and bundle metadata before ad-hoc signing."""
    work, app, libraries = config.work, config.artifact, config.binary_directory
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


def build_linux(config: BuildConfig, rebuild: bool) -> Path:
    work, libraries, units = config.work, config.binary_directory, config.units
    config.create_directories()
    # Check system dependencies before the more expensive compiler bootstrap.
    require_tool("cmake")
    require_tool("pkg-config")
    require_tool("clang")
    require_tool("ld.lld")
    subprocess.run(
        ["pkg-config", "--print-errors", "--exists", "sdl2 >= 2.26", "vorbisfile", "ogg"],
        check=True,
    )
    native = build_okgf(work, config.release, rebuild=rebuild)
    copy_if_changed(native / "libokgf.so", libraries / "libokgf.so")
    compiler, compiler_flags = prepare_compiler(config.target, lto=config.lto)
    # FPC's LLVM exception runtime uses libgcc; -n disables system fpc.cfg.
    libgcc = Path(output("clang", "-print-libgcc-file-name"))
    if not libgcc.is_file():
        raise FileNotFoundError("Clang cannot locate libgcc; install the GCC runtime.")
    compiler_flags += [f"-Fl{libgcc.parent}"]
    paszlib = build_paszlib(work, compiler, compiler_flags, rebuild)
    # CMake finds C libraries; FPC needs the corresponding native search paths.
    library_flags = shlex.split(output("pkg-config", "--libs-only-L", "sdl2", "vorbisfile"))
    compile_pascal(work, [
        compiler, *compiler_flags, *pascal_flags(config.release, paszlib),
        f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        *("-Fl" + flag[2:] for flag in library_flags),
        # LLD resolves command-line -l before FPC's script SEARCH_DIR entries.
        # FPC reparses -k options; quote the whole linker argument for spaced paths.
        f'-k"-L{libraries}"', "-k-lokgf", "-k--enable-new-dtags", "-k-rpath", "-k$ORIGIN",
        ROOT / "source/Rangers.dpr",
    ], rebuild, libraries / "Rangers", (libraries / "libokgf.so", libgcc))  # fmt: skip
    return config.artifact


def build_wasm(config: BuildConfig, rebuild: bool) -> Path:
    emcc = require_tool("emcc")
    emxx = require_tool("em++")
    toolchain = Path(output("em-config", "LLVM_ROOT"))
    work, units, binary = config.work, config.units, config.binary_directory
    config.create_directories()
    os.environ.setdefault("EM_CACHE", str(ROOT / ".local/emscripten-cache"))
    os.environ.setdefault("EMCC_CORES", "6")
    os.environ.setdefault("BINARYEN_CORES", "6")
    compiler, flags = prepare_compiler(config.target, toolchain, lto=config.lto)
    paszlib = build_paszlib(work, compiler, flags, rebuild)
    native = build_okgf(
        work,
        config.release,
        *(["-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"] if config.lto else []),
        rebuild=rebuild,
        wasm=True,
    )
    compile_pascal(work, [
        compiler, *flags, *pascal_flags(config.release, paszlib, ROOT / "platform/wasm"),
        "-Cn", "-XMFPC_GAME_MAIN", f"-FU{units}", f"-FE{binary}",
        ROOT / "source/Rangers.dpr",
    ], rebuild, binary / "ppas.sh")  # fmt: skip
    link_wasm(config, native, (emcc, toolchain / "clang", toolchain / "wasm-ld"), emxx, rebuild)
    copy_if_changed(ROOT / "platform/wasm/index.html", binary / "index.html")
    return config.artifact


def link_wasm(
    config: BuildConfig,
    native: Path,
    native_tools: tuple[Path, ...],
    emxx: Path,
    rebuild: bool,
) -> None:
    """Compile browser adapters and link FPC's object list with Emscripten."""
    work, binary = config.work, config.binary_directory
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
    sdl = sdl_source(native)
    native_objects = []
    for source in sorted(platform.glob("*.cpp")):
        obj = work / (source.stem + ".o")
        compile_native(work, [
            emxx,
            "-O2", "-pthread", "-fwasm-exceptions", "-sWASM_LEGACY_EXCEPTIONS=0",
            "-std=c++17", f"-I{sdl / 'include'}",
            *(["-flto"] if config.lto else []), "-c", source, "-o", obj,
        ], rebuild, native_tools)  # fmt: skip
        native_objects.append(obj)
    link_native(work, [
        emxx, "-O2", "-pthread", "-fwasm-exceptions", "-sWASM_LEGACY_EXCEPTIONS=0",
        *(["-flto"] if config.lto else []), *objects, *native_objects,
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    add_build_arguments(parser)
    parser.add_argument(
        "--rebuild", action="store_true", help="Rebuild all game units and native code."
    )
    args = parser.parse_args()
    config = BuildConfig(args.target, args.release, args.lto)
    try:
        soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
        desired = 4096 if hard == resource.RLIM_INFINITY else min(4096, hard)
        resource.setrlimit(resource.RLIMIT_NOFILE, (max(soft, desired), hard))
        builders = {
            "linux": build_linux,
            "macos": build_macos,
            "wasm": build_wasm,
            "android": build_android,
        }
        artifact = builders[config.target](config, args.rebuild)
    except subprocess.CalledProcessError as error:
        parser.exit(1, error.output or str(error))
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"{error}\n")
    print(f"Built: {artifact}")


if __name__ == "__main__":
    main()
