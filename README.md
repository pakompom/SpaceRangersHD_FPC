# Space Rangers HD — FPC Enhanced Port

A personal, opinionated Free Pascal port of **Space Rangers HD: A War Apart**,
based on the [original decompilation](https://github.com/pakompom/SpaceRangersHD_decomp).
Breaking changes can happen at any time.

- [Additions and behavior changes](ADDITIONS.md)
- [Building and running](BUILDING.md)
- [MIT license for custom additions](LICENSE) and [attribution](NOTICE.md)

## Source

- `source/`: Pascal game code, grouped by subsystem.
- `platform/`: native compatibility, SDL, and Android runtime.
- `native/`: OKGF build integration.
- `tools/`: build, run, and formatting scripts.
- `vendor/okgf/`: pinned [OKGF](https://github.com/pakompom/okgf) submodule.
