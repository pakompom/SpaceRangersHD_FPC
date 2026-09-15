# Space Rangers HD — FPC Enhanced Port

A personal, opinionated Free Pascal port of **Space Rangers HD: A War Apart**,
based on the [original decompilation](https://github.com/pakompom/SpaceRangersHD_decomp).
Breaking changes can happen at any time.

The `personal` branch contains this enhanced port. The [`main` branch](https://github.com/pakompom/SpaceRangersHD_FPC/tree/main)
starts from the original recovered source for a port limited to FPC and platform
compatibility changes.

https://github.com/user-attachments/assets/724f0543-1cb1-4b46-bb47-95ab45cbdfee

This port is developed exclusively with LLMs such as GPT-6 Astra through Codex.

- [Additions and behavior changes](ADDITIONS.md)
- [Building and running](BUILDING.md)
- [MIT license for custom additions](LICENSE) and [attribution](NOTICE.md)

Free Pascal is pinned as the [fpc_sr](https://github.com/pakompom/fpc_sr) submodule,
which retains upstream history and carries our compiler and runtime fixes.
Both macOS and Android builds use its LLVM backend. See the
[FPC changes](vendor/fpc/PORT.md) for the compiler fixes and Android support.

## Source

- `source/`: Pascal game code, grouped by subsystem.
- `platform/`: native compatibility, SDL, and Android runtime.
- `native/`: OKGF build integration.
- `tools/`: build, run, and formatting scripts.
- `vendor/okgf/`: pinned [OKGF](https://github.com/pakompom/okgf) submodule.
- `vendor/fpc/`: pinned [Free Pascal fork](https://github.com/pakompom/fpc_sr) submodule.
