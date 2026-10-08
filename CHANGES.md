# Delphi-to-FPC changes

This changelog records game-source changes for Free Pascal compatibility.

- Honor requested windowed mode at desktop-sized and larger resolutions. Set
  explicit back-buffer dimensions and use SDL centering for oversized windows.
- Preserve the original exception and raise address in `GR_WinMessage`, adding
  the message-processing stage to its message.
- Use each language's code as its settings label when its install file or
  `LangName` is missing, or the name is blank. Release the temporary language
  configuration if loading raises an exception.
- Guard arcade ship actions after player-ship destruction, including Q/W/E
  weapon shortcuts and battle entry, while preserving pause, exit, and the
  victory-panel Tab shortcut. Clear the hovered space before arcade cleanup
  and when deleting that space.
- Preserve the full galaxy pointer in the private memory-snapshot token used
  around planetary battle transitions on 64-bit targets.
- Keep script DWORD arithmetic at 32 bits, including overflow and the original
  masked shift counts. Preserve full-width storage for object references passed
  through script variables, assignments and comparisons on 64-bit targets.
  Float-valued shifts retain Delphi's separate 64-bit helper count rules.
- Preserve native arcade exit shuffling, including its zero-filled portal-count
  field and ten RNG calls per node. Model the original `Exits[-1]` stack overlap
  as an explicit array slot initialized from the map-center Y coordinate and
  carried between nodes, preserving exit values without out-of-bounds access.
- Remove the unused VFW import, which pulled `AVIFIL32.DLL` into Unix builds
  despite video playback already using `GameAVI`.
- Present an initial cleared SDL frame when creating the window. Wayland needs
  this buffer to map the surface before the game can receive activation and
  start drawing its loading screen.
- Detach shared WideString results before case conversion or script `toansi`
  packing writes through raw pointers. Preserve the game's configured case
  table and the caller's string, including read-only literals and shared strings
  on Unix.
- Update cursor image and hotspot together. Rebuilding a new cropped image with
  the previous hotspot could fail SDL's bounds check during cursor transitions.
- Preserve full pointer width when inspecting a missile owner's tranclucator
  and comparing missile ownership in point-defense targeting.
- Cancel and join script-request work before destroying UI/calculation state;
  free its worker with the script engine. The leaked worker otherwise kept
  waiting on SDL's event condition during process shutdown. Its wait for turn
  calculation now also observes cancellation.
- Preserve the original exception class, message and address when adding
  message-loop context; re-raise it instead of replacing it with a generic error.
- Ignore relative `XDG_DATA_HOME` values, preserve UTF-8 user-directory names,
  and report failed resource-directory changes instead of silently using the
  caller's working directory.

- Preserve Delphi Win32's exhausted-loop behavior in asteroid collision searches,
  script ship/group/state selection, planet filters, quest-event fallback,
  weighted item/text selection and numeric/quoted-text scans. Advance search
  indices explicitly, retaining the matching index on `Break` and the incoming
  counter on exposed skipped-loop paths. Record the revolution's rolled
  government separately: exhausting its descending byte counter selects no goods
  event, including when the attempt limit forces a new government. Reproduce the
  reward function's zeroed counter when both congratulations-text scans are empty.

- Preserve Bézier path smoothing on targets where `Extended` is Double-sized
  (including ARM64). The original x87 recurrence starts with `(1-t)^(count-1)`;
  with the 199 controls allowed by ship movement, this underflows near the end
  in Double and pulls samples toward the origin. Evaluate the second half with
  reversed controls and `1-t`, preserving the curve, heading unwrapping, sample
  timing and final endpoint. Keep the original evaluation order on targets with
  wider `Extended`. The game selects 24-bit x87 arithmetic precision while
  retaining the wider exponent range; this fix restores the mathematical curve
  on ARM64 without reproducing that intermediate rounding.

- Share game compiler directives in `GameOptions.inc` and leave optimization
  levels to the build settings instead of disabling optimization in each unit.
- Replace out-of-bounds planet-shop quota reads with explicit next-race and
  station quota accesses. Preserve the original weapon-subtype counting, offer
  selection and RNG consumption without depending on adjacent table placement.
- Preserve the original custom-weapon average-size quirk by explicitly reading
  the cached food trade-name pointer as a signed 32-bit value, taking its low
  32 bits on wider targets. Retain 32-bit multiplication overflow in treasure
  hints; this historical behavior remains dependent on allocation addresses.
- Replace x86 assembly in memory access, CRC, rectangle intersection, UTF-16
  comparisons, buffer reads, script arrays, geometry and saved-pixel restoration
  with Pascal. Preserve fixed-width buffer values and native comparison results.
- Replace graphics and font assembly with Pascal, retaining lookup-table color
  rounding, forward overlapping copies, RGB565/RGB555 blending and saturated
  alpha addition. Empty pixel loops no longer wrap their counters and overrun
  buffers; the original line-drawing register corruption is not reproduced.
- Configure floating-point exceptions, rounding and x87 precision through FPC's
  `Math` unit in the renderer and calculation threads. CPUs without selectable
  precision use their native precision.
- Allocate game memory through FPC on Windows, Linux and macOS. Private heaps
  retain bulk destruction; their handles follow the host pointer width.
- Use FPC file I/O for packages and loose files, converting path separators at
  the filesystem boundary. Keep package directory entries at 158 bytes on disk
  while allowing native-sized pointers in memory. Allow read-only packages when
  write access is unavailable; use WASI's descriptor-close API on that target.
  Remember each compressed entry's next block offset to avoid rescanning earlier
  headers during sequential reads. Interleaved entries still seek explicitly;
  random reads retain the chain lookup. This transient cache does not change
  package contents or saved-game formats.
- Decode ZL02 package blocks through FPC's Pascal zlib implementation, retaining
  the original DLL's header and decoded-length checks.
- Encode and decode ZL01 buffers through Pascal zlib, retaining the original
  compression levels, size limit and header-only size query. The buffer format
  remains unchanged.
- Initialize FPC's thread and Unicode managers before game units on Unix and
  WASI. Omit the desktop executable's resource section on WASI.
- Replace VCL/Win32 windowing, input, cursors, clipboard and document opening
  with direct Pascal SDL2 calls. Preserve game message/key values and map window
  coordinates through the displayed game viewport, including high-DPI scaling.
- Back the existing drawing and sound interfaces with SDL2. Keep CPU pixel
  access, render targets, gamma ramps, PCM streaming and position notifications.
  Native drivers receive the game's floating-point exception mask before startup.
- Recreate textures after SDL device loss and redraw discarded render targets.
  Observe resets during presentation before reusing the old texture handles.
- Run workers through FPC threads and preserve multi-event waits with SDL
  condition variables. Transfer worker failures to the caller before publishing
  completion; retain cache completion events and entries while callers wait.
- Free script ether entries and their lock during destruction instead of the
  original unmatched unlock. Release ether, music and resource-file locks on
  exceptions, and join failed GAI loaders before releasing their image data
  during destruction.
- Rescale cached backgrounds with Pascal bilinear interpolation, retaining crop
  alignment and pixel-center sampling without using SDL rendering on workers.
- Retain music playback events across tracks, and make script-dialog waits
  respond to calculation shutdown before releasing their UI and script state.
  Signal music completion even when opening or cleaning up a decoder fails.
- Decode Vorbis through FPC's native ABI declarations and encode JPEG screenshots
  through FPC's Pascal image package. Read AVI frame chunks in Pascal and use
  native Xvid decoding, replacing Video for Windows.
- Use FPC file enumeration, timestamps, Unicode case conversion and OS-specific
  user directories. Normalize filesystem paths separately from package keys and
  consistently use `Save` for save files, including their temporary output.
- Preserve Windows' case-insensitive file matching for installed languages,
  mod language resources, saves and robot maps. Keep the current language when
  the settings screen has no language choices, instead of saving an empty code.
  Resolve mismatched filesystem path components on Unix, including loose mod
  resources and existing output directories. Normalize BMP/PNG writer paths
  before passing them to OKGF, retaining Unicode names until that boundary.
- Replace timestamp-counter CPU probes with OS queries and the original fallback;
  use native memory queries for physical memory and FPC heap usage on Unix.
- Keep legacy script DLL calls and the original Steam/MatrixGame wrappers limited
  to 32-bit Windows.
- Remove obsolete process-module inspection and original-DLL checksum checks,
  including the Toolhelp import, whitelist, registry helper and unused integrity
  markers. Preserve resource-file CRC checks, their snapshot refresh and the
  daily shared RNG draw.
- Make Delphi's coordinate-list float bit casts and signed seed arithmetic
  explicit. Disambiguate the game's point type from FPC's `Types.TPointF`.
- Advance the text-wrapping scan explicitly instead of relying on Delphi's
  exhausted `for` counter, which otherwise stalls on the final character in FPC.
- Declare C record-pointer arguments with `constref`, preserving the original
  OKGF clipping-rectangle ABI and SDL's message-box data pointer across targets.
  Declare `OKGR_Planet2_TemplDel` as a procedure to match its C ABI; the game-facing
  wrapper returns zero after cleanup. Use the static C import namespace for
  OKGF on Wasm.
- Share SDL's logical window resolution between presentation and mouse events.
  Refresh the detected display mode on runtime reinitialization. For the canvas
  backend, use the existing list-style resolution selector and show Auto's
  actual dimensions.
  Let SDL vsync and browser refresh callbacks pace presentation without applying
  the legacy millisecond limit and an additional loop delay. Calculate the
  FPS label from submitted frames and elapsed time rather than update iterations.
  Query the desktop cursor for window-leave handling where supported, and refresh
  the game cursor on re-entry instead of retaining a stale position at the edge.
  Refresh native cursor visibility on focus return, applying AppKit's current
  cursor immediately on macOS when the pointer stays inside the game window.
- Preserve native object addresses through script integer cells, references,
  decimal strings, cross-script arguments and array lookup. Keep signed `int`
  arithmetic and serialized script scalar fields at 32 bits.
- Widen dialog, timer and UI payloads, film object handles and GAI frame-cache
  entries to the host pointer size. Size in-memory film command overlays for
  their pointer fields while retaining the original serialized film layout.
- Address ship equipment and score counters through their fields instead of
  fixed Win32 object offsets; allocate storage records by their actual size.
  Preserve the full encoded player pointer and pointer fields excluded from
  in-memory state protection.
