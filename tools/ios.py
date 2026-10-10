"""Build an iOS app with the pinned Pascal compiler and static C dependencies."""

import json
import os
import platform
import plistlib
import shlex
import shutil
import subprocess
from pathlib import Path

from android import dependency_source
from build_support import (
    build_okgf,
    compile_native,
    configure_native,
    link_native,
    output,
    require_tool,
    run_step,
    sdl_source,
)
from compiler import prepare_compiler
from pascal import build_paszlib, compile_pascal, pascal_flags
from targets import ROOT, BuildConfig, host_cpu

MINIMUM_IOS = "15.0"
APPLICATION_ID = "io.github.pakompom.spacerangershd"


def apple_tools(config: BuildConfig) -> tuple[str, str, str]:
    if platform.system() != "Darwin":
        raise RuntimeError("iOS builds require macOS and Xcode.")
    sdk_name = "iphoneos" if config.target == "ios" else "iphonesimulator"
    sdk = output("xcrun", "--sdk", sdk_name, "--show-sdk-path")
    arch = "arm64" if config.target == "ios" or host_cpu() == "aarch64" else "x86_64"
    triple = f"{arch}-apple-ios{MINIMUM_IOS}"
    if config.target == "ios-simulator":
        triple += "-simulator"
    return sdk, arch, triple


def cmake_options(sdk: str, arch: str, prefix: Path) -> list[str]:
    return [
        "-DCMAKE_SYSTEM_NAME=iOS",
        f"-DCMAKE_OSX_SYSROOT={sdk}",
        f"-DCMAKE_OSX_ARCHITECTURES={arch}",
        f"-DCMAKE_SYSTEM_PROCESSOR={arch}",
        f"-DCMAKE_OSX_DEPLOYMENT_TARGET={MINIMUM_IOS}",
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DBUILD_TESTING=OFF",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        f"-DCMAKE_INSTALL_PREFIX={prefix}",
        f"-DCMAKE_PREFIX_PATH={prefix}",
        f"-DCMAKE_FIND_ROOT_PATH={prefix}",
        "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER",
        "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY",
        "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY",
        "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY",
    ]


def build_dependencies(config: BuildConfig, sdk: str, arch: str, rebuild: bool) -> Path:
    prefix = config.work / "dependencies/prefix"
    options = {
        "jpeg": [
            "-DENABLE_SHARED=OFF",
            "-DENABLE_STATIC=ON",
            "-DWITH_TURBOJPEG=OFF",
            "-DWITH_SIMD=OFF",
            "-DWITH_TOOLS=OFF",
            "-DWITH_TESTS=OFF",
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
    for name, extra in options.items():
        work = config.work / "dependencies" / name
        directory = work / "build"
        work.mkdir(parents=True, exist_ok=True)
        changed = configure_native(
            work,
            directory,
            [
                "cmake",
                "--fresh",
                "-S",
                dependency_source(name),
                "-B",
                directory,
                "-G",
                "Ninja",
                "-DCMAKE_BUILD_TYPE=Release",
                *cmake_options(sdk, arch, prefix),
                *extra,
            ],
        )
        run_step(
            work,
            name,
            [
                "cmake",
                "--build",
                directory,
                "--parallel",
                "4",
                *(["--clean-first"] if rebuild or changed else []),
            ],
        )
        run_step(work, "install", ["cmake", "--install", directory])
    return prefix


def build_ios(config: BuildConfig, rebuild: bool) -> Path:
    sdk, arch, triple = apple_tools(config)
    for name in ("cmake", "ninja", "clang"):
        require_tool(name)
    config.create_directories()
    compiler, flags = prepare_compiler(config.target, lto=config.lto)
    os.environ["SDKROOT"] = sdk
    prefix = build_dependencies(config, sdk, arch, rebuild)
    native = build_okgf(
        config.work, config.release, *cmake_options(sdk, arch, prefix), rebuild=rebuild, ios=True
    )
    paszlib = build_paszlib(config.work, compiler, flags, rebuild)
    launcher = config.work / "ios-main.o"
    compile_native(
        config.work,
        [
            "clang",
            "-target",
            triple,
            "-isysroot",
            sdk,
            "-O2",
            "-fobjc-arc",
            f"-I{sdl_source(native) / 'include'}",
            "-c",
            ROOT / "platform/ios/main.m",
            "-o",
            launcher,
        ],
        rebuild,
    )
    # FPC's Darwin main stub forwards argc/argv/envp and initializes its RTL.
    # UIKit starts first; the launcher prepares paths before entering this stub.
    libraries = [
        native / "libokgf.a",
        native / "libSDL2.a",
        *sorted((prefix / "lib").glob("*.a")),
        launcher,
    ]
    frameworks = (
        "UIKit",
        "Foundation",
        "CoreAudio",
        "AudioToolbox",
        "AVFoundation",
        "CoreGraphics",
        "CoreMotion",
        "GameController",
        "Metal",
        "QuartzCore",
        "OpenGLES",
        "CoreHaptics",
    )
    executable = config.binary_directory / "Rangers"
    pascal_output = config.work / "pascal"
    pascal_output.mkdir(exist_ok=True)
    compile_pascal(
        config.work,
        [
            compiler,
            *flags,
            *pascal_flags(config.release, paszlib),
            "-dSRHD_IOS",
            "-XMSRGameMain",
            "-Cn",
            f"-FU{config.units}",
            f"-FE{pascal_output}",
            f"-Fl{native}",
            f"-Fl{prefix / 'lib'}",
            f'-k"{launcher}"',
            "-k-lokgf",
            "-k-ljpeg",
            "-k-lpng16",
            "-k-lz",
            "-k-lvorbisfile",
            "-k-lvorbis",
            "-k-logg",
            "-k-lobjc",
            "-k-ObjC",
            *(arg for name in frameworks for arg in ("-k-framework", f"-k{name}")),
            ROOT / "source/Rangers.dpr",
        ],
        rebuild,
        pascal_output / "ppas.sh",
        tuple(libraries),
    )
    link_ios(config, executable, libraries, rebuild)
    verify_executable(executable, config.target, arch)
    info = {
        "CFBundleExecutable": "Rangers",
        "CFBundleIdentifier": APPLICATION_ID,
        "CFBundleName": "Space Rangers HD",
        "CFBundleDisplayName": "Space Rangers HD",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "0.1",
        "MinimumOSVersion": MINIMUM_IOS,
        "UIDeviceFamily": [1, 2],
        "UIFileSharingEnabled": True,
        "LSSupportsOpeningDocumentsInPlace": True,
        "UIApplicationSupportsIndirectInputEvents": True,
        "UIRequiresFullScreen": True,
        "UIStatusBarHidden": True,
        "UILaunchScreen": {},
        "UISupportedInterfaceOrientations": [
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        ],
    }
    (config.artifact / "Info.plist").write_bytes(plistlib.dumps(info))
    # Simulator installs accept ad-hoc signatures. Device signing is a separate
    # user identity step; this recipe deliberately produces an unsigned app.
    if config.target == "ios-simulator":
        run_step(config.work, "sign", ["codesign", "--force", "--sign", "-", config.artifact])
    return config.artifact


def link_ios(config: BuildConfig, executable: Path, libraries: list[Path], rebuild: bool) -> None:
    """Use FPC's complete object list with Xcode's current platform-version flags."""
    script = config.work / "pascal/ppas.sh"
    commands = [
        shlex.split(line) for line in script.read_text().splitlines() if "-filelist " in line
    ]
    command = next((line for line in commands if line and Path(line[0]).name == "ld"), None)
    if command is None:
        raise RuntimeError("FPC did not write a Darwin linker command to ppas.sh.")
    legacy = "-iphoneos_version_min" if config.target == "ios" else "-ios_simulator_version_min"
    index = command.index(legacy)
    sdk_name = "iphoneos" if config.target == "ios" else "iphonesimulator"
    sdk_version = output("xcrun", "--sdk", sdk_name, "--show-sdk-version")
    platform_name = "ios" if config.target == "ios" else "ios-simulator"
    command[index : index + 2] = ["-platform_version", platform_name, MINIMUM_IOS, sdk_version]
    command[0] = output("xcrun", "--find", "ld")
    if config.target == "ios":
        # FPC emits pointers in packed constants without 8-byte alignment.
        # Classic dyld relocations support these; chained fixups do not.
        command.append("-no_fixup_chains")
    filelist = Path(command[command.index("-filelist") + 1])
    objects = [
        Path(line) if Path(line).is_absolute() else config.work / line
        for line in filelist.read_text().splitlines()
        if line
    ]
    link_native(
        config.work, command, [script, filelist, *objects, *libraries], [executable], rebuild
    )


def verify_executable(executable: Path, target: str, arch: str) -> None:
    headers = output("xcrun", "vtool", "-show-build", str(executable))
    expected = "IOS" if target == "ios" else "IOSSIMULATOR"
    if not any(line.split() == ["platform", expected] for line in headers.splitlines()):
        raise RuntimeError(f"Wrong Mach-O platform in {executable}: {headers}")
    actual = output("xcrun", "lipo", "-archs", str(executable))
    if actual != arch:
        raise RuntimeError(f"Expected {arch}, got {actual} in {executable}")
    dependencies = output("xcrun", "otool", "-L", str(executable)).splitlines()[1:]
    for line in dependencies:
        name = line.strip().split(" (", 1)[0]
        if not name.startswith(("/usr/lib/", "/System/Library/")):
            raise RuntimeError(f"Unbundled dependency in iOS app: {name}")
    print(f"Verified iOS Mach-O: {arch}, {expected}, system dependencies only.", flush=True)


def run_simulator(config: BuildConfig, game_directory: Path | None = None) -> None:
    if not (config.artifact / "Rangers").is_file():
        raise RuntimeError("Build the matching ios-simulator profile first.")
    inventory = json.loads(output("xcrun", "simctl", "list", "devices", "available", "-j"))
    devices = [
        device
        for runtime, group in inventory["devices"].items()
        if ".iOS-" in runtime
        for device in group
        if device.get("isAvailable") and device["name"].startswith("iPhone")
    ]
    if not devices:
        raise RuntimeError("Install an iOS simulator runtime in Xcode first.")
    device = next((item for item in devices if item["state"] == "Booted"), devices[0])
    identifier = device["udid"]
    if device["state"] != "Booted":
        subprocess.run(["xcrun", "simctl", "boot", identifier], check=True)
    subprocess.run(["xcrun", "simctl", "bootstatus", identifier, "-b"], check=True)
    subprocess.run(["xcrun", "simctl", "install", identifier, config.artifact], check=True)
    if game_directory is not None:
        if not game_directory.is_dir():
            raise FileNotFoundError(f"Game directory does not exist: {game_directory}")
        data = Path(
            output("xcrun", "simctl", "get_app_container", identifier, APPLICATION_ID, "data")
        )
        # Explicit --game-dir imports owned assets into this test app's sandbox.
        shutil.copytree(game_directory, data / "Documents/Game", dirs_exist_ok=True)
    subprocess.run(["open", "-a", "Simulator"], check=True)
    subprocess.run(["xcrun", "simctl", "launch", identifier, APPLICATION_ID], check=True)
