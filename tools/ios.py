"""Build an iOS app with the pinned Pascal compiler and static C dependencies."""

import json
import platform
import plistlib
import shutil
import subprocess
from pathlib import Path

from build_support import (
    BuildStamp,
    build_codecs,
    build_okgf,
    compile_native,
    file_state,
    output,
    require_tool,
    run_step,
    sdl_source,
)
from compiler import prepare_compiler
from pascal import build_paszlib, compile_pascal, pascal_flags
from targets import IOS_MIN_VERSION, ROOT, BuildConfig

APPLICATION_ID = "io.github.pakompom.spacerangershd"


def apple_tools(config: BuildConfig) -> tuple[str, str, str]:
    if platform.system() != "Darwin":
        raise RuntimeError("iOS builds require macOS and Xcode.")
    sdk_name = "iphoneos" if config.target == "ios" else "iphonesimulator"
    sdk = output("xcrun", "--sdk", sdk_name, "--show-sdk-path")
    arch = config.ios_arch
    triple = f"{arch}-apple-ios{IOS_MIN_VERSION}"
    if config.target == "ios-simulator":
        triple += "-simulator"
    return sdk, arch, triple


def cmake_options(sdk: str, arch: str, prefix: Path) -> list[str]:
    return [
        "-DCMAKE_SYSTEM_NAME=iOS",
        f"-DCMAKE_OSX_SYSROOT={sdk}",
        f"-DCMAKE_OSX_ARCHITECTURES={arch}",
        f"-DCMAKE_SYSTEM_PROCESSOR={arch}",
        f"-DCMAKE_OSX_DEPLOYMENT_TARGET={IOS_MIN_VERSION}",
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
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


def build_ios(config: BuildConfig, rebuild: bool) -> Path:
    sdk, arch, triple = apple_tools(config)
    for name in ("cmake", "ninja", "clang"):
        require_tool(name)
    config.create_directories()
    compiler, flags = prepare_compiler(config)
    # Native @available checks need Clang's platform-version helpers. FPC invokes
    # ld directly, so it does not add the target's compiler runtime automatically.
    compiler_runtime = Path(output("xcrun", "clang", "-target", triple, "-print-libgcc-file-name"))
    if not compiler_runtime.is_file():
        raise FileNotFoundError(f"Clang compiler runtime not found: {compiler_runtime}")
    prefix = config.work / "dependencies/prefix"
    build_codecs(config.work, cmake_options(sdk, arch, prefix), rebuild)
    native = build_okgf(
        config.work,
        config.release,
        *cmake_options(sdk, arch, prefix),
        "-DBUILD_SHARED_LIBS=OFF",
        rebuild=rebuild,
        jobs=6,
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
        compiler_runtime,
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
    compile_pascal(
        config.work,
        [
            compiler,
            *flags,
            *pascal_flags(config.release, paszlib),
            "-dSRHD_IOS",
            "-XMSRGameMain",
            f"-FU{config.units}",
            f"-FE{config.binary_directory}",
            f"-Fl{native}",
            f"-Fl{prefix / 'lib'}",
            f'-k"{launcher}"',
            "-k-lokgf",
            "-k-ljpeg",
            "-k-lpng16",
            "-k-lz",
            "-k-lobjc",
            "-k-ObjC",
            *(arg for name in frameworks for arg in ("-k-framework", f"-k{name}")),
            f'-k"{compiler_runtime}"',
            ROOT / "source/Rangers.dpr",
        ],
        rebuild,
        executable,
        tuple(libraries),
    )
    verify_executable(executable, config.target, arch)
    package_ios(config)
    return config.artifact


def package_ios(config: BuildConfig) -> None:
    info = {
        "CFBundleExecutable": "Rangers",
        "CFBundleIdentifier": APPLICATION_ID,
        "CFBundleName": "Space Rangers HD",
        "CFBundleDisplayName": "Space Rangers HD",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "0.1",
        "MinimumOSVersion": IOS_MIN_VERSION,
        "UIDeviceFamily": [1, 2],
        "UIFileSharingEnabled": True,
        "LSSupportsOpeningDocumentsInPlace": True,
        "UIApplicationSupportsIndirectInputEvents": True,
        "UIRequiresFullScreen": True,
        "UIStatusBarHidden": True,
        "UILaunchScreen": {},
        "UIApplicationSceneManifest": {
            "UIApplicationSupportsMultipleScenes": False,
            "UISceneConfigurations": {
                "UIWindowSceneSessionRoleApplication": [
                    {
                        "UISceneConfigurationName": "SDL",
                        "UISceneDelegateClassName": "SDLUIKitSceneDelegate",
                    }
                ],
            },
        },
        "UISupportedInterfaceOrientations": [
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        ],
    }
    info_file = config.artifact / "Info.plist"
    contents = plistlib.dumps(info)
    if not info_file.is_file() or info_file.read_bytes() != contents:
        info_file.write_bytes(contents)
    # Simulator installs accept ad-hoc signatures. Device signing is a separate
    # user identity step; this recipe deliberately produces an unsigned app.
    if config.target == "ios-simulator":
        stamp = BuildStamp(config.work / "sign-inputs.json")

        def signature() -> str:
            return json.dumps(file_state([config.binary_directory / "Rangers", info_file]))

        if not stamp.matches(signature(), config.artifact / "_CodeSignature/CodeResources"):
            # Signing modifies the executable; record its state after success.
            with stamp.recording(signature):
                run_step(
                    config.work, "sign", ["codesign", "--force", "--sign", "-", config.artifact]
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


def select_simulator(inventory: dict, requested: str | None = None) -> dict:
    devices = [
        {**device, "runtime": runtime.rsplit(".", 1)[-1].replace("-", " ", 1).replace("-", ".")}
        for runtime, group in inventory["devices"].items()
        if ".iOS-" in runtime
        for device in group
        if device.get("isAvailable")
    ]
    if not devices:
        raise RuntimeError("Create an iOS simulator in Xcode after installing its runtime.")
    if requested:
        matches = [device for device in devices if device["udid"] == requested]
        if not matches:
            matches = [device for device in devices if device["name"] == requested]
    else:
        matches = [device for device in devices if device["state"] == "Booted"]
        if not matches and len(devices) == 1:
            matches = devices
    if len(matches) == 1:
        return matches[0]
    choices = "\n".join(
        f"  {device['udid']}  {device['name']} ({device['runtime']}, {device['state']})"
        for device in devices
    )
    reason = (
        f"Simulator {requested!r} is missing or ambiguous." if requested else "Select a simulator."
    )
    raise RuntimeError(f"{reason} Pass --simulator with a device name or UDID:\n{choices}")


def run_simulator(
    config: BuildConfig, game_directory: Path | None = None, simulator: str | None = None
) -> None:
    if not (config.artifact / "Rangers").is_file():
        raise RuntimeError("Build the matching ios-simulator profile first.")
    if game_directory is not None and not game_directory.is_dir():
        raise FileNotFoundError(f"Game directory does not exist: {game_directory}")
    # Resolve the selected Xcode's viewer before booting or installing anything.
    # Xcode 27 moved it from Developer/Applications to Contents/Applications.
    developer = Path(output("xcode-select", "-p"))
    viewers = (
        developer.parent / "Applications/DeviceHub.app",
        developer / "Applications/Simulator.app",
    )
    viewer = next((path for path in viewers if path.is_dir()), None)
    if viewer is None:
        raise RuntimeError(f"Cannot find Simulator or Device Hub in {developer.parent}.")
    inventory = json.loads(output("xcrun", "simctl", "list", "devices", "available", "-j"))
    device = select_simulator(inventory, simulator)
    identifier = device["udid"]
    print(f"Using {device['name']} ({device['runtime']}, {config.ios_arch}).", flush=True)
    if device["state"] != "Booted":
        subprocess.run(["xcrun", "simctl", "boot", identifier], check=True)
    subprocess.run(["xcrun", "simctl", "bootstatus", identifier, "-b"], check=True)
    subprocess.run(["xcrun", "simctl", "install", identifier, config.artifact], check=True)
    data = Path(output("xcrun", "simctl", "get_app_container", identifier, APPLICATION_ID, "data"))
    if game_directory is not None:
        # Explicit --game-dir imports owned assets into this test app's sandbox.
        print("Importing game assets…", flush=True)
        shutil.copytree(game_directory, data / "Documents/Game", dirs_exist_ok=True)
    print(f"Game data: {data / 'Documents/Game'}", flush=True)
    print(f"Logs and saves: {data / 'Library/Application Support/SpaceRangersHD'}", flush=True)
    subprocess.run(["open", "-a", viewer], check=True)
    subprocess.run(
        ["xcrun", "simctl", "launch", "--terminate-running-process", identifier, APPLICATION_ID],
        check=True,
    )
