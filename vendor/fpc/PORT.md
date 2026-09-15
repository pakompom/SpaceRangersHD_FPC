# Vendored Free Pascal

FPC 3.3.1 from [upstream main](https://gitlab.com/freepascal.org/fpc/source),
revision `00152d58c951b22a2a1165d18367c60d57c5abdd`.

This source snapshot contains the compiler, runtime library, top-level build
files, and the `rtl-objpas`, `fcl-base`, `fcl-process`, and `pthreads` packages
used by the game.

## Local changes

- [LLVM assembler targets](compiler/llvm/agllvm.pas): enable Android ARM64.
- [Android target](compiler/systems/i_android.pas): select LLVM's exception
  unwinding convention.
- [Exception runtime](rtl/inc/psabieh.inc): link Android's NDK libunwind.
- [Unwind tables](compiler/cfidwarf.pas): let LLVM generate frame information
  for its final machine code.
- [Android linker](compiler/systems/t_android.pas): use a section present in
  LLD's default linker script.

The game build bootstraps this source with `tools/compiler.py` and stores the
compiler and target runtimes in `.local/fpc/`.

The compiler uses the [GNU GPL v2](LICENSE). Runtime and package licenses are
included in their source directories, including the [runtime license](rtl/COPYING.txt)
and its [linking exception](rtl/COPYING.FPC), retained for the modified runtime.
