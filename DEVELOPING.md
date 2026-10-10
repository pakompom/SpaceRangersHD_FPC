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

## Mobile UI

The mobile UI reuses the original controls and artwork. Render resolution, UI
size and camera zoom can change independently.

`GameMobileUiEnabled` selects the layout from the Mobile UI setting; Automatic
follows the platform. `GameWindowIsMobile` identifies the Android host, so touch
input, fullscreen behavior and native overlays remain available with either UI.
Apply layout preferences during the normal interface reload, before building
controls: close callbacks must still see the mode that created their tree.

- **Window coordinates, output pixels and game coordinates are different.**
  SDL reports window points; rendering uses physical pixels; game layout uses
  logical coordinates. `GameWindow.TGamePresentation` calculates the output
  rectangle and input conversions from the same display measurements. Android
  density defines the size of a dp; it is not the screen's measured PPI.
  `GetGameMobileUiScale` converts a desired dp size to game-screen units.

- **Scaling a control also scales its position.**
  `AbsolutePosition` and `HitTestBounds` store unscaled coordinates. The effective
  display scale multiplies both the absolute origin and the dimensions.
  Use `GI_Main.PlaceControlAtScreen` to set a rendered position and effective
  scale, or `ScaledChildPosition` to anchor a child to a moving parent. Assign
  `DisplayScale` directly only for a scale relative to the parent. Camera zoom
  uses the world's child scale so it does not resize the HUD or dialogs.

- **Drawing and input must use the same conversions.**
  Despite its name, `ScreenToLogicalPoint` accepts game-screen coordinates, not
  physical pixels. For visibility checks in scaled controls, use
  `ControlViewportBounds` and `ControlIntersectsViewport` rather than comparing
  unscaled bounds with the screen dimensions.

- **Preparing a control tree is not the same as resizing it.**
  Replacing artwork, reparenting controls and changing inventory cells happen
  once per loaded tree. Keep those steps separate from positioning controls or
  refreshing their text. Share layout measurements through `GI_LayoutMetrics`;
  keep artwork cut positions with the relevant skin. Preserve the original
  corners, bevels and distinctive shapes when composing larger panels.

- **A touch gesture has one owner.**
  Controls declare whether they accept taps, held actions, dragging or scrolling.
  The recognizer sends touch and drag messages before synthesizing mouse taps.
  A tap activates its original eligible target on release. Scrolling or cancelling
  must not activate a different row under the finger. Inventory and slider drags
  keep their own behavior. Inspection selection is separate from gesture ownership.

- **Callbacks and screen changes can invalidate control references.**
  The control tree owns its children; references held by screens and helpers are
  borrowed and become invalid on a rebuild. A callback can open a dialog or
  destroy a control, so check references before using them again. Modal transitions
  cancel held actions and discard pending releases to prevent click-through.

- **Scrollable tooltips must survive leaving their source icon.**
  Hover updates and hide timers use `KeepMobileTooltipVisible` before replacing
  or hiding a description. Icon-leave callbacks use `DeferMobileTooltipLeave`.
  This keeps the tooltip open while the pointer is inside or it owns a scroll
  gesture, even if that drag leaves the frame. It dismisses normally afterward;
  explicit screen or gameplay dismissals still apply. The deferred timer belongs
  to the tooltip body and is cancelled when that body is deactivated or destroyed.

- **Android views and game controls live on different threads.**
  Java views and the keyboard belong to the Java UI thread. SDL events pass input
  and configuration changes to the game thread, which owns game controls,
  rendering and SDL hint updates. Native desktop previews can check layout and
  input routing, but do not reproduce Android's keyboard, activity lifecycle,
  cutouts or graphics driver.

## Formatting

Pascal source uses [pasfmt](https://github.com/integrated-application-development/pasfmt)
with `pasfmt.toml`. `tools/format.py` also uses clang-format, Ruff,
cmake-format, and xmllint.

```sh
./tools/format.py
./tools/format.py --check
```
