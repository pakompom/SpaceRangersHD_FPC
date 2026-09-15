#!/usr/bin/env python3
"""Build Space Rangers HD for macOS or Android ARM64."""

import argparse
import json
import os
import plistlib
import re
import resource
import shlex
import shutil
import subprocess
import zipfile
from pathlib import Path

from compiler import prepare_compiler

ROOT = Path(__file__).resolve().parents[1]
PASCAL_FLAGS = ("-Mdelphi", "-FcUTF8")


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


def command_signature(command: list[str | Path]) -> str:
    compiler = Path(command[0]).resolve()
    stat = compiler.stat()
    return json.dumps([list(map(str, command)), str(compiler), stat.st_mtime_ns, stat.st_size])


def compile_pascal(work: Path, command: list[str | Path], rebuild: bool) -> None:
    # FPC tracks unit/source dependencies, but not every change to compiler options.
    stamp = work / "pascal-command.json"
    signature = command_signature(command)
    if rebuild or not stamp.is_file() or stamp.read_text() != signature:
        command = [command[0], "-B", *command[1:]]
    # A failed build must not leave units compiled with a mixture of settings.
    stamp.write_text("")
    run_step(work, "pascal", command)
    stamp.write_text(signature)


def compile_native(work: Path, command: list[str | Path], rebuild: bool) -> None:
    stamp = work / "native-command.json"
    depfile = work / "native.d"
    target = Path(command[command.index("-o") + 1])
    command = [*command, "-MD", "-MF", depfile]
    signature = command_signature(command)
    if (
        not rebuild
        and target.is_file()
        and depfile.is_file()
        and stamp.is_file()
        and stamp.read_text() == signature
    ):
        dependencies = shlex.split(depfile.read_text().replace("\\\n", "").split(": ", 1)[1])
        if dependencies and all(
            (work / name).is_file()
            and (work / name).stat().st_mtime_ns <= target.stat().st_mtime_ns
            for name in dependencies
        ):
            print("Native platform code is up to date.", flush=True)
            return
    stamp.write_text("")
    run_step(work, "native", command)
    stamp.write_text(signature)


def build_okgf(work: Path, release: bool, *options: str, rebuild: bool = False) -> Path:
    directory = work / "native"
    configuration = "Release" if release else "RelWithDebInfo"
    run_step(work, "configure", [
        "cmake", "-S", ROOT / "native", "-B", directory, f"-DCMAKE_BUILD_TYPE={configuration}",
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
            *(["--clean-first"] if rebuild else []),
        ],
    )
    return directory


def pascal_flags(release: bool, *platform_paths: Path) -> list[str]:
    search_paths = [
        *platform_paths,
        ROOT / "platform",
        ROOT / "source",
        *sorted(path for path in (ROOT / "source").rglob("*") if path.is_dir()),
    ]
    return [
        *PASCAL_FLAGS,
        "-O4" if release else "-O2",
        # -O4 enables field reordering and fast math; override it afterward.
        "-OoNOORDERFIELDS",
        "-OoNOFASTMATH",
        "-gl",
        *(f"-Fu{path}" for path in search_paths),
    ]


def build_macos(release: bool, rebuild: bool = False) -> Path:
    compiler, compiler_flags = prepare_compiler("macos", run_step)
    clang = require_tool("clang")
    sdk = output("xcrun", "--show-sdk-path")
    work = ROOT / ".local" / ("release" if release else "debug")
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
        "-DCMAKE_C_FLAGS_RELEASE=-O3 -DNDEBUG -g",
        rebuild=rebuild,
    )
    shutil.copy2(native / "libokgf.dylib", libraries)
    cflags = shlex.split(output("pkg-config", "--cflags", "sdl2", "SDL2_mixer", "libjpeg"))
    ldflags = shlex.split(output("pkg-config", "--libs", "sdl2", "SDL2_mixer", "libjpeg"))
    native_object = work / "game_native.o"
    # Keep the object: dsymutil needs its DWARF after linking the library.
    compile_native(work, [
        clang, "-c", "-O3" if release else "-O2", "-g",
        "-Wall", "-Wextra", "-mmacosx-version-min=11.0",
        ROOT / "platform/game_native.c", *cflags, "-o", native_object,
    ], rebuild)  # fmt: skip
    run_step(work, "native-link", [
        clang, "-dynamiclib", "-mmacosx-version-min=11.0", native_object, *ldflags,
        "-Wl,-install_name,@rpath/libgamenative.dylib", "-o", libraries / "libgamenative.dylib",
    ])  # fmt: skip
    compile_pascal(work, [
        compiler, *compiler_flags, *pascal_flags(release), "-Aclang-llvm-darwin",
        f"-FU{units}", f"-FE{libraries}", f"-Fl{libraries}",
        "-k-lgamenative", "-k-lokgf", "-k-lz", "-k-rpath", "-k@executable_path", f"-XR{sdk}",
        ROOT / "source/Rangers.dpr",
    ], rebuild)  # fmt: skip
    for name in ("Rangers", "libgamenative.dylib", "libokgf.dylib"):
        run_step(work, f"symbols-{name}", [
            "xcrun", "dsymutil", libraries / name, "-o", libraries / f"{name}.dSYM",
        ])  # fmt: skip
    (app / "Contents/Info.plist").write_bytes(
        plistlib.dumps(
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
    )
    run_step(work, "sign", ["codesign", "--force", "--deep", "--sign", "-", app])
    return app


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
        f"-Fl{system_libraries}/26", f"-Fl{system_libraries}", f"-k-L{system_libraries}/26",
        "-k-z", "-kmax-page-size=16384", "-k-lm", "-k--no-undefined",
        platform / "main.lpr",
    ], rebuild)  # fmt: skip
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
    parser.add_argument("--target", choices=("macos", "android"), default="macos")
    parser.add_argument("--release", action="store_true", help="Build an optimized release.")
    parser.add_argument(
        "--rebuild", action="store_true", help="Rebuild all game units and native code."
    )
    args = parser.parse_args()
    try:
        build = build_android if args.target == "android" else build_macos
        soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
        desired = 4096 if hard == resource.RLIM_INFINITY else min(4096, hard)
        resource.setrlimit(resource.RLIMIT_NOFILE, (max(soft, desired), hard))
        artifact = build(args.release, args.rebuild)
    except subprocess.CalledProcessError as error:
        parser.exit(1, error.output or str(error))
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"{error}\n")
    print(f"Built: {artifact}")


if __name__ == "__main__":
    main()
