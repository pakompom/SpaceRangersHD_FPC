# Development gotchas

- **`Double` variables can still get Single-precision arithmetic.**
  [`GameOptions.inc`](source/GameOptions.inc) enables `LEGACYPC24`, which rounds
  arithmetic to a 24-bit significand even when the destination is `Double`.
  This also affects instrumentation added to game units: converting absolute
  clock readings to floating-point seconds before subtracting can erase short
  intervals. Keep timestamps and subtraction in 64-bit integer ticks or
  nanoseconds; convert only the elapsed interval for display.

- **Turning that directive off does not reset the CPU's precision mode.**
  On x86, game threads also set x87 to 24-bit precision. The setting follows the
  thread into called code, including code compiled without `LEGACYPC24`.
  For a helper needing ordinary precision, account for both settings and restore
  any floating-point environment you change.

- **`Extended` is not equally wide everywhere.**
  It is 80-bit on our x86 targets, but Double-sized on ARM64 and Wasm. Even where
  the storage matches `Double`, substituting that spelling can change evaluation
  order: the fork retains the source type for `DELPHIORDER` scheduling.

- **Stateful expressions need not run left-to-right.**
  `DELPHIORDER` changes FPC's usual scheduling independently of `LEGACYPC24`.
  Two RNG calls can exchange which operand receives which value yet finish with
  the same seed. Use explicit sequencing for new code with interacting effects;
  a matching final seed alone cannot verify the result.

- **A wider destination does not widen earlier integer arithmetic.**
  `DELPHIINTEGER32` keeps arithmetic on narrow operands at 32 bits. For new
  64-bit calculations, widen an operand before the operation. Script cells are
  also wide enough to carry pointers, while script scalar arithmetic stays 32-bit.

- **A copied `WideString` may still share its buffer.**
  Writing through `PWideChar` can alter the source string too. Detach the
  destination before raw writes; see `TVarEC.PackAnsiString` in
  [`EC_Expression.pas`](source/script/EC_Expression.pas).

## Formatting

Pascal source uses [pasfmt](https://github.com/integrated-application-development/pasfmt)
with `pasfmt.toml`. `tools/format.py` also uses clang-format, Ruff,
cmake-format, and xmllint.

```sh
./tools/format.py
./tools/format.py --check
```
