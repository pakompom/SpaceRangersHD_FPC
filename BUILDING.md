# Building

## Requirements

Desktop builds use the host architecture on Linux and macOS: x86_64 or AArch64.
The x86_64 game and runtime require an x86-64-v2 CPU (SSE4.2 and POPCNT).
Requires Python 3.10+, FPC 3.2.2, GNU Make, CMake 3.20+, pkg-config, Clang 14+, and development
libraries for SDL2 2.26+ (or SDL2-compat), libogg, libvorbis, libjpeg, and libpng.

- Linux: binutils and `ld.lld` in addition to Clang.
- macOS: Xcode command-line tools and Homebrew.

AVI playback needs Xvid: `libxvidcore.so.4` on Linux, `xvidcore` on macOS.
`FPC_BOOTSTRAP` overrides the installed compiler used to bootstrap the pinned FPC.

## Build and run

```sh
git submodule update --init --recursive
./tools/build.py
./tools/run.py --game-dir=/path/to/game
```

The scripts detect the host OS; `--target=linux` or `--target=macos` selects it
explicitly. Resources default to `game/` when `--game-dir` is omitted.

The scripts set FPC's `-jN` to use up to six parallel LLVM assembly jobs, capped
by the detected logical CPU count. This limit does not adapt to available RAM.

- `--release`: `-O4` instead of the default `-O2`.
- `--lto`: enable LLVM link-time optimization.
- `--rebuild`: rebuild all game units and native code (build script only).

Use matching `--target`, `--release` and `--lto` options for build and run.
Configurations are `debug` and `release`, with a `-lto` suffix when
enabled; compiler and runtime caches live in `.local/fpc/<cpu>-<system>/`.

| Platform | Output |
| --- | --- |
| Linux | `.local/linux-<cpu>/<profile>/bin/`: `Rangers` and `libokgf.so` |
| macOS | `.local/<profile>/Space Rangers HD.app` |

Linux CPU names are `x86_64` and `aarch64`. Keep the Linux executable and OKGF
library together; SDL and codecs remain system dependencies.

## Browser

Browser builds require Python, FPC, GNU Make, CMake, host Clang and Emscripten.
SDL2 and the codec dependencies are downloaded during the build. The browser
must support WebAssembly threads and exception handling.

```sh
./tools/build.py --target=wasm --release
./tools/run.py --target=wasm --release --game-dir=/path/to/game
```

Open `http://127.0.0.1:8788/` and select **Start game**. The server streams the
original game assets and supplies the isolation headers needed for shared memory.
Saves are stored in this browser. Use `--port` to select a different server port.
The browser files are in `.local/wasm/release/bin/`; `--lto` is also supported.

## Android

Requires Python 3.10+ with current patch updates, FPC 3.2.2, GNU Make, CMake,
Ninja, host Clang, JDK 17+, Android SDK platform 35, build-tools 35+ and NDK r28+.
Build on macOS or x86_64 Linux for ARM64 devices running Android 8.0+.
Set `ANDROID_HOME`, `ANDROID_NDK_HOME` or `JAVA_HOME` to override tool locations.

```sh
./tools/build.py --target=android
```

The APK is `.local/android-arm64/debug/Rangers.apk`; `--release` and `--lto`
select other profiles. Install it, copy your game folder to the device, and select
**Select game folder** in the launcher. Keep `build/android-signing/` to sign
updates with the same key.

Release symbols are kept in `build/android-symbols/<build-id>/` for crash diagnostics.
Android builds currently omit Xvid, so AVI cinematics do not play.

The package ID and default version are defined in `tools/targets.py`; local rebuilds
do not bump the version. `ANDROID_VERSION_CODE` and `ANDROID_VERSION_NAME` override
the APK version; `ANDROID_BUILD_TOOLS_VERSION` selects an installed SDK build-tools
version instead of the newest one.

## iOS (experimental)

Requires macOS with full Xcode, an iOS SDK, Python 3.10+, FPC 3.2.2, GNU Make,
CMake 3.24+ and Ninja. The C dependencies are built for the selected iOS SDK;
desktop SDL and codec packages are not used. For MacPorts:

```sh
sudo port install fpc python313 cmake gmake ninja pkgconfig
export DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
python3.13 tools/build.py --target=ios-simulator
python3.13 tools/run.py --target=ios-simulator --game-dir=/path/to/game
```

The simulator uses the host CPU (`x86_64` on Intel or `aarch64` on Apple Silicon).
The app is `.local/ios-simulator-<cpu>/debug/SpaceRangersHD.app`. The run command
boots an available iPhone simulator, installs the app, and copies the supplied
game directory into its sandbox. Without resources, the launcher displays
instructions for importing them through Files.

```sh
python3.13 tools/build.py --target=ios
```

The device output is an unsigned ARM64 app at
`.local/ios-aarch64/debug/SpaceRangersHD.app`, targeting iOS 15+. It needs an
Apple development/distribution identity and provisioning profile before it can
be installed on an iPhone or iPad. Simulator ad-hoc signing does not provide
device signing. Original game assets are not bundled. On a device, put them in
`Documents/Game` using Files or Finder file sharing; saves live in
`Library/Application Support/SpaceRangersHD` inside the app sandbox.

The port is experimental. AVI cinematics and the original Windows planetary
battle DLL are unavailable. Building an app does not verify gameplay on hardware.

The pinned FPC and OKGF submodules stay unchanged. The iOS build applies the
patches in `native/` to isolated build copies: FPC needs a current LLVM simulator
triple, and OKGF needs a static library. Neither patch affects desktop or Android
builds.
