# Building

## macOS

The macOS ARM64 build requires Python 3, FPC 3.2.2 for bootstrapping, GNU Make,
Xcode command-line tools, CMake, pkg-config, SDL2, SDL2_mixer, libjpeg, and libpng.

The build creates the vendored FPC 3.3.1 LLVM compiler in `.local/fpc/` on first
use and rebuilds it when its source changes. `FPC_BOOTSTRAP` selects the installed
bootstrap compiler. The same generated compiler serves macOS and Android, with
a runtime compiled for each target. Pascal compiles through LLVM IR and Clang;
C code also uses Clang.

```sh
git submodule update --init --recursive
./tools/build.py
./tools/run.py --game-dir=/path/to/game
```

Place the game assets in `game/` using this layout:

```text
game/
  INSTALL.TXT
  INSTALL_ENGLISH.TXT
  INSTALL_RUSSIAN.TXT
  CFG.TXT
  CFG/        # configuration data and language subfolders
  DATA/*.pkg  # original game packages
```

Optional mods go in `game/Mods/` and are selected through the original mod manager.

`game/` is ignored by Git. With assets there, run `./tools/run.py` without arguments.
Generated output stays in `.local/`.
Use `--release` with both scripts for an optimized build.

Saves/settings default to `~/Library/Application Support/SpaceRangersHD/`.
Game options include `--user-dir=/path/to/profile`, `--language=english`,
`--renderer=sdl`, and `--transitions=original`.

To open a save in the galaxy observer:

```sh
./tools/run.py --observer-save=/path/to/save.sav --user-dir=/path/to/observer-profile
```

## Android

`./tools/build.py --target android` produces `.local/android/Rangers.apk`.
Build from macOS ARM64 with the bootstrap tools above, JDK 21, CMake, Ninja,
and the Android SDK/NDK. Set these dependency paths:

- `ANDROID_HOME`: SDK with platform/build-tools 35 or newer.
- `ANDROID_NDK_HOME`: NDK installation.
- `ANDROID_PREFIX`: Android ARM64 libraries/headers for SDL2, SDL2_mixer, libjpeg,
  and libpng; SDL2_mixer and image libraries are linked statically.
- `SDL_SOURCE`: matching SDL2 source tree, supplying its Android Java classes.

Android Pascal and C code use the NDK's LLVM tools. The vendored compiler includes
[Android LLVM support](vendor/fpc/PORT.md).

`JAVA_HOME` selects the JDK. The APK contains code; the launcher imports game
resources from a ZIP of the `game/` layout above:

```sh
ditto -c -k --keepParent game .local/game.zip
```

After applying mods or settings that need a restart, tap Play in the launcher.
`--release` enables optimized native code. Keep `.local/android/debug.keystore`
for subsequent updates signed with the same local key.

## Formatting

Install [pasfmt](https://github.com/integrated-application-development/pasfmt),
clang-format, Ruff, cmakelang (`cmake-format`), and libxml2 (`xmllint`).
Run `./tools/format.py` to format Pascal, C, Java, Python, CMake, and XML source;
`./tools/format.py --check` checks the same files.

## Source comments

In Pascal game source, place comments beside changed statements, declarations, or routines:

```pascal
// CHANGE: ENHANCEMENT - Add search bookmark navigation.
// CHANGE: BUGFIX - Avoid floating-point underflow near path endpoints.
// CHANGE: PERFORMANCE - Reuse rendered thumbnails within a turn.
```

Use `PORTABILITY`, `LIMITATION`, or `CLEANUP` for those kinds of game-source changes.
Keep comments short and explain the reason. Use the same category at related
sites so a text search finds them together.
