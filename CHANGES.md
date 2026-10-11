# Porting and behavior reference

Key differences from the recovered Delphi source, compatibility behavior retained by the
port, and the source files that implement them.

## Compiler and Delphi semantics

- **Compiler settings.** `source/GameOptions.inc` centralizes wrapping arithmetic,
  short-circuit Boolean evaluation and maximum field alignment, plus the FPC fork's
  `LEGACYPC24`, `DELPHIORDER` and `DELPHIINTEGER32` directives. These preserve
  arithmetic boundaries and expression scheduling; optimization levels come from the
  build configuration.
- **Floating-point environment.** `source/GR_Main.pas` and `source/game/ThreadCalc.pas`
  use FPC's `Math` unit to select masked exceptions, nearest rounding and 24-bit x87
  precision. CPUs without selectable precision retain their native mode. SDL startup in
  `platform/GameWindow.pas` masks exceptions before native drivers initialize.
- **Portable low-level operations.** Pascal replaces x86 assembly for memory access,
  CRC, UTF-16 comparison, buffer reads, script arrays and geometry. Fixed-width values,
  comparison results, float bit casts and signed seed arithmetic remain explicit. Start
  with `source/core/EC_Mem.pas`, `source/core/EC_Str.pas`, `source/core/CrcUnit.pas` and
  `source/core/aMyFunction.pas`.
- **Loop counters.** Searches explicitly reproduce Delphi Win32's exhausted `for`
  counters, matching indices on `Break`, and relevant skipped-loop values. This affects
  collision searches, script selection/filtering, weighted choices and text scans;
  representative code is in `source/script/aScriptFun.pas`, `source/game/aConst.pas` and
  `source/core/EC_Str.pas`. Do not simplify these back to loops whose final counter is
  compiler-dependent.
- **Shared strings.** `UpperCaseWideString` and `LowerCaseWideString` in
  `source/core/EC_Str.pas`, and `TVarEC.PackAnsiString` in
  `source/script/EC_Expression.pas`, detach `WideString` storage before raw writes. This
  preserves callers' strings and read-only literals while retaining the game's case
  table and script packing format.
- **Bézier precision.** `TSPath.ResampleBezierRange` in `source/core/aPath.pas` uses
  `source/core/aBezierPC24.pas` to keep a 24-bit significand with a separately scaled
  exponent. This avoids underflow on long paths where `Extended` is Double-sized, while
  preserving forward accumulation, intermediate rounding, heading unwrapping, sample
  timing and the final endpoint.

## Pointer widths, memory layouts and native interfaces

- **Script values.** `source/script/EC_Expression.pas` and
  `source/script/aScriptFun.pas` carry full object addresses through cells, references,
  assignments, comparisons, decimal strings and cross-script calls. Scalar integer/DWORD
  arithmetic and serialized scalar fields remain 32-bit, including overflow and masked
  shifts. Float-valued shifts use `ScriptShiftInt64` for Delphi's separate 64-bit helper
  count rules.
- **In-memory handles.** Dialog/timer payloads, film object handles, GAI cache entries,
  heap handles and the planetary-battle snapshot token use native pointer widths. Film
  command overlays are sized for their pointer fields while the serialized film layout
  stays unchanged. See `source/ui/GI_MessageLoop.pas`, `source/scene/aEFilm.pas`,
  `source/resources/EC_CacheGAI.pas` and `MemorySnapshotGalaxyToken` in
  `source/game/aSaveLoad.pas`.
- **Fields instead of Win32 offsets.** Equipment and score access uses named fields;
  storage allocations use actual record sizes. `TGalaxy.XorProtectedState` in
  `source/game/aGalaxy.pas` preserves complete encoded pointers and excludes pointer
  fields using their real addresses and sizes.
- **Internal table alignment.** `TEconomyInfo`, `TGoodsInfo` and `TOwnerInfo` in
  `source/game/aConst.pas` use ordinary records so static string pointers are naturally
  aligned for Darwin chained fixups. These tables are accessed through fields, not
  serialized as raw records; packing is retained where an external layout requires it.
- **C ABI declarations.** OKGF clipping rectangles in `source/GR_Main.pas` and SDL
  message-box data in `platform/SDL2.pas` use `constref` for C pointer arguments.
  `OKGR_Planet2_TemplDel` is a procedure; its game-facing wrapper returns zero. Wasm
  uses the static C import namespace for OKGF.

## Platform runtime and media

- **Startup.** `source/Rangers.dpr` initializes thread and Unicode managers before game
  units. Android builds a shared library exporting `AndroidGameMain` as `sr_fpc_main`,
  called after SDL establishes application paths. Android/WASI use FPC's Unicode
  manager; their builds omit the desktop resource section.
- **OS services.** `platform/GameWindow.pas` and `platform/GameInput.pas` replace
  VCL/Win32 windowing and input with SDL2, preserving game message/key values. Clipboard
  and document opening also use SDL. `platform/GameSystem.pas` provides user paths,
  timestamps and OS-based CPU/memory queries; `platform/GameHeap.pas` uses FPC
  allocation while retaining private heaps' bulk destruction.
- **Graphics and sound interfaces.** `platform/GameGraphics.pas` and
  `platform/GameAudio.pas` back the existing interfaces with SDL2, including CPU pixel
  access, render targets, gamma ramps, PCM streaming and position notifications.
- **Media codecs.** `source/audio/VorbisFile.pas` uses FPC's native ABI declarations.
  `TGraphBufGR.SaveJpeg` in `source/graphics/GR_GraphBuf.pas` uses FPC's image package.
  `platform/GameAVI.pas` reads AVI chunks in Pascal and uses native Xvid decoding,
  replacing Video for Windows.

## Files, packages and saved state

- **Filesystem boundaries.** `source/resources/EC_File.pas` and
  `source/resources/EC_HsFile.pas` use FPC file I/O and convert separators at the
  filesystem boundary, keeping package lookup keys separate. `NativeGamePath` in
  `platform/GameSystem.pas` resolves case differences on Unix, including loose resources
  and existing output directories. BMP/PNG paths retain Unicode names until passed to
  OKGF.
- **Profiles and discovery.** User paths preserve UTF-8 names and ignore relative
  `XDG_DATA_HOME`; a failed resource-directory change is reported. Saves consistently
  use `Save`, including temporary output. Languages, mod resources, saves and robot maps
  retain case-insensitive matching. `ScanModFolders` in `source/resources/aModsInfo.pas`
  scans explicit directories, preserving the caller's working directory and avoiding
  false mod detections.
- **Package layout and access.** `source/resources/EC_HsFile.pas` keeps
  `DiskPackEntrySize` at 158 bytes while allowing native pointers in memory. Read-only
  packages are supported; WASI uses its descriptor-close API. Per-entry next-block
  offsets avoid rescanning compressed chains during sequential reads; random/interleaved
  access still seeks correctly. This cache does not alter package or save formats.
- **Compression formats.** `source/graphics/EC_OKGF.pas` implements ZL01 buffer
  compression and ZL02 package-block decoding with Pascal zlib. Original headers,
  compression levels, size limits, decoded-length checks and the header-only size query
  are retained.
- **Language settings.** `source/screens/fCfgSettings.pas` falls back to a language code
  when its install file or display name is missing or blank. An empty language list
  preserves the selected language; temporary configurations are released on errors.

## Drawing, presentation and desktop input

- **Software raster operations.** `source/graphics/GR_GraphBuf.pas`,
  `source/graphics/GR_gi.pas` and `source/resources/EC_CacheFont.pas` replace assembly
  while retaining lookup-table rounding, forward overlapping copies, RGB565/RGB555
  blending and saturated alpha addition. Empty pixel loops no longer wrap into buffer
  overruns; the original line-drawing register corruption is not reproduced. Saved-pixel
  restoration is also Pascal.
- **Presentation coordinates.** `GameWindow.TGamePresentation` shares the viewport
  between drawing and input, including high-DPI output and alternate viewports. Windowed
  mode remains available at desktop-sized or larger resolutions, and `OpenGameWindow`
  presents a cleared frame so Wayland can map the surface. Runtime reinitialization
  refreshes the detected display mode; canvas settings show the resolved dimensions for
  Auto resolution.
- **Frame pacing and device resets.** `source/ui/GI_MessageLoop.pas` lets SDL
  vsync/browser callbacks pace presentation without the extra legacy delays, and
  measures FPS from submitted frames. `platform/GameGraphics.pas` recreates textures
  after device loss, redraws discarded render targets and observes resets before reusing
  handles.
- **Scaling and captures.** Texture-filter changes preserve queued draws; clipping
  follows pixel-center coverage, rotated sprites retain smooth filtering, and text
  edges/small tiles avoid dark padding seams. Tall images use the correct tile-column
  stride. Cached backgrounds use Pascal bilinear resampling, avoiding SDL calls on
  workers; unchanged captures avoid writable pixel locks. See
  `source/graphics/GI_GraphBuf.pas` and `source/graphics/GR_GraphBuf.pas`.
- **Cursor and scrolling.** `source/ui/GI_Cursor.pas` updates artwork and hotspot
  together, padding images for outlying hotspots. Cursors refresh on re-entry/focus
  return, with `platform/GameCocoaCursor.pas` handling macOS visibility.
  `GamePointerAllowsEdgeScroll` gates edge scrolling by focus and pointer location,
  preserving keyboard scrolling, sensitivity and letterbox edges while disabling
  mouse-edge scrolling on Android.
- **Text wrapping.** `TCFontEC.WrapTaggedTextIntoLines` in
  `source/resources/EC_CacheFont.pas` explicitly advances the scan, including past
  oversized glyphs/tags, preventing stalled or unbounded wrapping.

## Worker lifetime and error reporting

- **Common worker contract.** `source/core/EC_Thread.pas` uses FPC threads and
  `platform/GameEvents.pas` uses SDL conditions for multi-event waits.
  `TThreadEC.CheckFailure` transfers failures with worker backtraces before completion
  is accepted. Cache completion events and entries remain alive while callers wait.
- **Calculation and saves.** `source/game/ThreadCalc.pas` reports generation/simulation
  failures with stage and seed context on the main thread, cancels dependent work and
  exits instead of using a partially updated galaxy. `FinalizeSaveWriter` in
  `source/game/aSaveLoad.pas` drains queued saves, releases locks and reports pending
  failures; fatal cleanup logs secondary save errors without replacing the original
  failure.
- **Audio and resources.** `platform/GameAudio.pas` reports mixer failures on the main
  thread and joins the mixer before closing its device. `source/audio/GR_Music.pas`
  retains playback events across tracks and signals completion on decoder failure.
  Ether, music and file locks are released on exceptions; failed GAI loaders are joined
  before freeing images.
- **Script shutdown.** `StopScriptRequestThread` in `source/script/aScript.pas` cancels
  and joins requests before UI/calculation teardown. Calculation and script-dialog waits
  observe cancellation. The engine frees its worker, and `source/core/EC_Ether.pas`
  frees ether entries and their lock.
- **Exception context.** `GR_WinMessage` in `source/GR_Main.pas` and handlers in
  `source/ui/GI_MessageLoop.pas` add message, transition or drawing context while
  re-raising the original exception, preserving its class, address and backtrace.

## Mobile layout and interaction

Mobile layouts reuse the original artwork and controls. The **Mobile UI** setting
selects Automatic/Yes/No on every platform; Automatic follows the Android host.
`GameMobileUiEnabled` controls layout independently of `GameWindowIsMobile`, so Android
input, fullscreen behavior and native overlays remain available with either layout.
Applying the setting reloads the interface.

- **Sizing and rebuilds.** `source/ui/GI_LayoutMetrics.pas` and `GetGameMobileUiScale`
  share density-based fitting at the display's pixel resolution. The HUD/radar scale
  separately from the world; camera zoom and optional pinch zoom preserve hit testing
  and anchors. Screen rasters resize at frame boundaries, while safe UI reloads retain
  the game, fit active dialogs and release old screens, including achievements. Captures
  keep display resolution, with separate buffers for nested dialogs.
- **Gesture ownership.** `platform/GameTouch.pas` and `source/ui/GI_MessageLoop.pas`
  distinguish completed taps, dragging, scrolling and camera gestures. Taps activate
  their original control; crossing another answer or button cannot select it. Press
  feedback appears on touch-down, with hold-repeat for quantity/cargo controls. Focus
  loss and modal transitions cancel presses, drags and repeats without release actions.
- **Inspection.** `source/ui/GI_Inspection.pas`, `source/screens/fGalaxy2.pas` and
  `source/screens/fStarMap.pas` let the first tap inspect equipment, destinations or
  floating cargo before a second tap acts. Purchase confirmations and special targeting
  remain intact. Tooltips keep fixed headers/footers and scroll the body;
  `KeepMobileTooltipVisible` and `DeferMobileTooltipLeave` prevent premature dismissal
  while reading.
- **Defaults.** Android profiles start from bundled defaults instead of imported desktop
  preferences. Mobile dialogue starts at the second-largest text size and quests at the
  largest, while saved font choices remain respected.

| Area | Behavior and source entry points |
| --- | --- |
| Menus, settings and dialogs | Larger menus, readable settings rows, integrated slider end buttons and fitted quantity/confirmation panels. `source/ui/GI_SettingsLayout.pas`, `source/screens/fMainForm.pas`, `source/screens/fGameMenu.pas`, `source/screens/fCount1.pas`. |
| HUD, inventory and shops | Independently scaled bottom panel/radar, separate ship services/storage, larger paged cells and aligned hit tests during panel motion. `source/screens/fPanelMain.pas`, `source/ui/GI_ShipLayout.pas`, `source/screens/fShip2.pas`, `source/screens/fEquipmentShop.pas`. |
| Dialogue, scanning and space | Government/station panes fit above the HUD; scanner/probe panels and action markers enlarge without changing world positions or covering inspection targets. `source/ui/GI_DialogueLayout.pas`, `source/screens/fScaner.pas`, `source/screens/fStarMap.pas`. |
| Text quests | Content-sized choices, left-aligned prose, complete fixed-layout statistics/diagrams, optional enlarged statistics, compact toolbar and scrolling. `source/quests/TextQuestInterface.pas`, `source/quests/TextFieldClass.pas`, `source/quests/QuestArtwork.pas`. |
| Arcade | Larger controls/results independent of the battle view, with simultaneous directional steering and weapon-group firing. `TfAB.ApplyMobileSteering` in `source/arcade/ab_MainForm.pas` and `platform/android/java/io/github/pakompom/spacerangershd/ArcadeControls.java`. |

## Preserved gameplay quirks and targeted corrections

- **Shop quotas.** `LegacyPlanetShopQuota` in `source/game/aPlanet.pas` replaces reads
  past the race table with explicit next-race/station accesses. Weapon-subtype counting,
  offer selection and RNG consumption remain unchanged.
- **Address-dependent item size.** `GetAverageItemSize` in `source/game/aConst.pas`
  explicitly takes the cached food trade-name pointer's low 32 bits as a signed value
  for custom weapons. Treasure hints in `source/game/aPlanet.pas` retain 32-bit
  multiplication overflow. This historical quirk still depends on allocation addresses.
- **Arcade exit shuffle.** `TfAB.ABSpaceBuild` in `source/arcade/ab_MainForm.pas`
  retains the zero-filled portal-count field and ten RNG calls per node. A declared
  `Exits[-1]` slot models the original stack overlap, initialized from map-center Y and
  carried between nodes, without an out-of-bounds access.
- **Loop-dependent outcomes.** `TPlanet.TriggerGovernmentRevolution` keeps the rolled
  government separate from a forced selection: an exhausted byte counter chooses no
  goods event. Quest fallback retains its exhausted-scan result, and
  `TNormalShip.CollectLiberationRewards` keeps a zero counter when both text scans are
  empty. See `source/game/aPlanet.pas`, `source/quests/LocationClass.pas` and
  `source/game/aNormalShip.pas`.
- **Object lifetime and ownership.** Arcade actions guard a destroyed player ship while
  retaining pause/exit/victory shortcuts; hovered space is cleared before destruction.
  See `source/arcade/ab_MainForm.pas` and `source/arcade/ab_Space.pas`.
  Missile-owner/tranclucator and point-defense comparisons in `source/game/aGalaxy.pas`
  preserve full pointers.

## Removed and restricted legacy code

- Empty placeholder units, unused registry/Direct3D helpers, the inactive Delphi
  exception hook and VFW import were removed. Redundant nonvirtual hooks and dead
  statements were trimmed while retaining required overrides and RNG calls.
- Original process-module/DLL inspection, Toolhelp/whitelist code, the disabled
  FGInt/RSA integrity snapshot and Steam leaderboard hooks were removed.
  `TGalaxy.ComputeIntegrityChecksum` in `source/game/aGalaxy.pas` still returns zero.
  Active protected state, resource CRC checks/snapshot refresh, the daily shared RNG
  draw, save layouts, local scores and score-file export remain.
- Script DLL calls and the original Steam/MatrixGame wrappers remain limited to 32-bit
  Windows. See `platform/GameScriptLibrary.pas`, `source/SimpleSteamApi.pas` and
  `source/game/Robot.pas`.
