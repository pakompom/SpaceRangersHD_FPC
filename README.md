# Space Rangers HD — FPC Enhanced Port

A personal, opinionated Free Pascal port of **Space Rangers HD: A War Apart**,
based on the [original decompilation](https://github.com/pakompom/SpaceRangersHD_decomp).
Breaking changes can happen at any time.

This port is developed exclusively with LLMs such as GPT-6 Astra through Codex.

- [Additions and behavior changes](ADDITIONS.md)
- [Building and running](BUILDING.md)
- [MIT license for custom additions](LICENSE) and [attribution](NOTICE.md)

Free Pascal is vendored so compiler and runtime bug fixes can be maintained
alongside the port. Both macOS and Android builds use its LLVM backend. See the
[FPC changes](vendor/fpc/PORT.md) for the compiler fixes and Android support.

## Source

- `source/`: Pascal game code, grouped by subsystem.
- `platform/`: native compatibility, SDL, and Android runtime.
- `native/`: OKGF build integration.
- `tools/`: build, run, and formatting scripts.
- `vendor/okgf/`: pinned [OKGF](https://github.com/pakompom/okgf) submodule.
- `vendor/fpc/`: Free Pascal compiler, runtime, and required packages.
