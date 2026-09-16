# Building

## macOS ARM64

Requires Python 3, FPC 3.2.2 for bootstrapping, GNU Make,
Xcode command-line tools, CMake, pkg-config, SDL2 2.26 or newer, libogg, libvorbis, libjpeg, and libpng.
AVI cinematics also need a native Xvid library (`xvidcore`).
`FPC_BOOTSTRAP` selects the installed bootstrap compiler.

```sh
git submodule update --init --recursive
./tools/build.py
./tools/run.py --game-dir=/path/to/game
```

The build script bootstraps the pinned FPC LLVM compiler into `.local/fpc/`.
Normal builds use `-O2`. Use `--release` with both build and run scripts for
release builds (`-O4`).

All builds use an RTL compiled with `CLASSESINLINE`; the pinned FPC also marks
the list error routine `noreturn`, allowing safe list accesses to optimize better.
macOS link-time optimization is a separate opt-in. Pass `--lto` to both scripts:

```sh
./tools/build.py --release --lto
./tools/run.py --release --lto
```

Normal builds keep their existing output paths. LTO builds use `.local/release-lto/`
or `.local/debug-lto/`, with separate RTL and game-unit caches. Switching between
them does not rebuild the compiler or overwrite the other configuration.
LTO takes longer to link. Android currently builds without LTO.

`./tools/build.py --rebuild` forces a game rebuild.

Game resources default to the ignored `game/` directory. `--game-dir` selects
another location. Build output is stored under `.local/`.

## Windows (32-bit)

Requires Git, FPC 3.2.2 for i386-win32, and 32-bit SDL2 2.26 or newer (only
`SDL2.dll` is needed). No C compiler: the build reuses the game's own `okgf.dll`.

```bat
git submodule update --init --recursive
./tools/build-win32.cmd
```

The script builds `source/Rangers.dpr` with the installed FPC into
`.local\win32\Rangers.exe` — not with the pinned fork. Point the `FPC` variable at
`fpc.exe` if FPC is not in `PATH`.

The executable has to sit next to the game's libraries: copy it into the game
directory (replacing `Rangers.exe`) and put `SDL2.dll` there as well. Windows
builds are 32-bit by design — script DLL mods and the original 32-bit `okgf.dll`
and `MatrixGame.dll` work only that way. Step-by-step instructions and the x86
specific changes: [docs/build-win32.md](docs/build-win32.md).

## Formatting

Pascal source uses [pasfmt](https://github.com/integrated-application-development/pasfmt)
with `pasfmt.toml`. `tools/format.py` also uses clang-format, Ruff,
cmake-format, and xmllint.

```sh
./tools/format.py
./tools/format.py --check
```
