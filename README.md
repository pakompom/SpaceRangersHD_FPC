# Space Rangers HD — Free Pascal Port

A Free Pascal port of **Space Rangers HD: A War Apart**, based on the
recovered Delphi source and intended to preserve the original game behavior.

Supported platforms:

- Linux x86_64
- macOS ARM64
- Android ARM64 (8.0+)
- WebAssembly (browser)

See [BUILDING.md](BUILDING.md) for dependencies and build/run instructions.

The source was generated from
[SpaceRangersHD_decomp at `7342a10`](https://github.com/pakompom/SpaceRangersHD_decomp/tree/7342a10dc1a0dcaa242ea4bc8c33e29c0eb6bdc0),
which reconstructs the **2026-08-11 prerelease** build.

## Layout

- `source/`: game source, organized by subsystem.
- `tools/`: build, run, compiler bootstrap, and formatting scripts.
- `platform/`: Pascal windowing, input, graphics, audio, and OS services.
- `platform/wasm/`: browser page and adapters to Emscripten's host runtime.
- `platform/android/`: Android launcher, SDL activity, resource import and native entry point.
- `native/`: OKGF and SDL build integration for desktop, Android and the browser.
- `vendor/okgf/`: pinned [OKGF](https://github.com/pakompom/okgf) submodule.
- `vendor/fpc/`: pinned [FPC fork](https://github.com/pakompom/fpc_sr) submodule.

## Documentation

- [Build setup](BUILDING.md)
- [Development gotchas](DEVELOPING.md)
- [Delphi-to-FPC changes](CHANGES.md)
- [Attribution](NOTICE.md) and [license](LICENSE)
- [Personal branch with enhancements](https://github.com/pakompom/SpaceRangersHD_FPC/tree/personal)

Development uses LLMs such as GPT-6 Astra through Codex.
