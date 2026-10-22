unit GameWindow;

{$MODE DELPHI}
{$POINTERMATH ON}

interface

uses
  Classes,
  Types,
  GameInput,
  SDL2;

type
  // Values are stored in CFG.TXT as MobileUI; missing preferences use Automatic.
  TGameUiMode = (gumAutomatic, gumDesktop, gumMobile);

  TGameDisplayMetrics = record
    // Window coordinates are SDL points; output and touch slop are physical
    // pixels. Density converts Android dp to output pixels, not measured PPI.
    WindowSize, OutputSize: TPoint;
    Density: Double;
    TouchSlop: Integer;
  end;

  // One metrics snapshot owns the integer presentation rectangle and its
  // forward/inverse mappings. SDL window points differ from output pixels.
  TGamePresentation = record
    Metrics: TGameDisplayMetrics;
    LogicalSize: TPoint;
    OutputRect: TRect;
    procedure OutputToLogical(X, Y: Double; out LogicalX, LogicalY: Double);
    function WindowToLogical(X, Y: Integer): TPoint;
    function LogicalToWindow(X, Y: Integer): TPoint;
    // Physical output pixels per logical unit, using the rounded viewport.
    function PixelScale: Double;
  end;

function CalculateGamePresentation(const Metrics: TGameDisplayMetrics; Width, Height: Integer): TGamePresentation;

procedure InitializeGameVideo;
function GameWindowUsesCanvas: Boolean;
function GameWindowHasSystemCursor: Boolean;
function GamePointerCursorVisible: Boolean;
function GameWindowIsMobile: Boolean;
function GameWindowIsFullscreenOnly: Boolean;
// Android: shows the on-screen keyboard for a text field, placing SDL's editor
// at Bounds (input coordinates, as pointer messages report them) so the system
// can keep the field visible. The Controls keyboard button reuses these bounds
// until ForgetGameTextInputBounds. Other platforms ignore both calls.
procedure ShowGameTextInput(const Bounds: TRect);
procedure ForgetGameTextInputBounds;
// Commit layout policy only when rebuilding the control tree. Live docking
// changes remain pending while a dialog or screen delays the rebuild.
procedure ConfigureGameUi(Mode: TGameUiMode);
procedure CommitGameUiLayout;
function GameMobileUiEnabled: Boolean;
function GameUiLayoutChangePending: Boolean;
function GameWindowUsesNativeRaster: Boolean;
function GameWindowUsesRenderResolution: Boolean;
procedure GetGameWindowLogicalSize(out Width, Height: Integer);
function GetGameWindowPixelScale: Single;
function GetGameDisplayMetrics: TGameDisplayMetrics;
function GetGamePresentationRect(Width, Height: Integer): TRect;
function GetGameMobileUiScale(DpPerSourcePixel: Single = 1): Single;
procedure GetGameAutomaticLayoutSize(MinWidth, MinHeight: Integer; out Width, Height: Integer);
procedure OpenGameWindow(Width, Height: Integer; Windowed, VSync: Boolean);
procedure CloseGameWindow;
// Best-effort state snapshot: unavailable SDL queries are diagnostic warnings.
procedure LogGameVideoDiagnostics;
function PollGameMessage(out Message: TGameMessage): Boolean;
function PostGameMessage(Message, WParam: Cardinal; LParam: Integer): Boolean;
function GameWindowFocused: Boolean;
function GameMouseInWindow: Boolean;
function GamePointerAllowsEdgeScroll: Boolean;
function GameKeyState(Key: Integer): SmallInt;
function GameDoubleClickTime: Cardinal;
procedure GetGameMouse(out Point: TPoint);
procedure WarpGameMouse(X, Y: Integer);
function ShowGameCursor(Show: Boolean): Integer;
procedure SetGameWindowTitle(const Title: UnicodeString);
procedure MinimizeGameWindow;
function OpenGameURL(const URL: UnicodeString): Boolean;
function GetGameClipboard: UnicodeString;
procedure SetGameClipboard(const Text: UnicodeString);
procedure DiscardGameTextCharacter;
procedure WaitGameMessages(Timeout: Cardinal);
function GameMessageBox(const Text, Title: UnicodeString; Options: Cardinal): Integer;
procedure ShowGameDialog(const Text: UnicodeString);
function GameMessagesPending: Boolean;
procedure CancelGamePointerInput;
procedure SetGameArcadeControls(Flags: Integer);

var
  // Read by settings; apply changes through ConfigureGameUi at a tree rebuild.
  GameUiMode: TGameUiMode = gumAutomatic;
  OnGameActivated, OnGameDeactivated: TNotifyEvent;
  GameSDLWindow: PSDL_Window;
  GameSDLRenderer: PSDL_Renderer;
  GameTextureGeneration, GameTargetGeneration: LongInt;
  GameDisplayGeneration: LongInt = 1;
  GamePresentedFrames: QWord;

implementation

uses
{$IF Defined(DARWIN) and not Defined(SRHD_IOS)}
  GameCocoaCursor,
{$ENDIF}
  SysUtils,
  Math,
  GameTouch,
  GameSystem,
  GameDiagnostics,
  GameSDLDiagnostics,
  URIParser;

type
  TGameVideoLogSnapshot = record
    Configuration, RendererDescription, WindowDescription: UnicodeString;
    Window: PSDL_Window;
    Renderer: PSDL_Renderer;
    ModeFlags: Cardinal;
    TextureGeneration: LongInt;
  end;

const
  DiagnosticWindowModeFlags = SDL_WINDOW_FULLSCREEN_DESKTOP or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_RESIZABLE;

var
  VideoInitialized: Boolean;
  VideoFaulted: Boolean;
  DisplayModeWarningLogged: Boolean;
  LastVideoLog: TGameVideoLogSnapshot;
  DesktopMouseAvailable: Boolean;
  BrowserWindow: Boolean;
  MobileWindow, FullscreenOnlyWindow, AppInBackground: Boolean;
  MobileUiEnabled: Boolean;
  UiDisplayMetrics: TGameDisplayMetrics;
  MobileDensity: Double;
  HasPendingDisplayChange: Boolean;
  PostedMessageType: Cardinal;
  TextInput: UnicodeString;
  TextPosition: Integer;
  WheelRemainder: Double;
  WheelMessage: TGameMessage;
  CursorCount: Integer;
  LastTimerTick: QWord;
  LogicalWidth, LogicalHeight: Integer;
  PendingEvent: TSDL_Event;
  HasPendingEvent: Boolean;
  Touch: TGameTouch;
  TouchMouse: TPoint;
  TouchMouseActive: Boolean;
  PointerCursorActive: Boolean;
  TouchMode: Integer;
  TouchSlop: Integer;
  HasPendingActivation: Boolean;
  PendingActivation: Cardinal;
  ArcadeControls: Cardinal;

{$IFDEF ANDROID}
var
  AndroidKeyboardSession: Boolean;
  // Window coordinates of the focused text field; W = 0 when unknown.
  AndroidTextInputRect: TSDL_Rect;
{$ENDIF}

{$IFDEF SWITCH}
var
  HandheldMode: Boolean;

procedure SwitchPollInput(Window: PSDL_Window); cdecl; external name 'sr_switch_poll_input';
function SwitchMouseButtons: Cardinal; cdecl; external name 'sr_switch_mouse_buttons';
function SwitchKeyboardState: PByte; cdecl; external name 'sr_switch_keyboard_state';
function SwitchHandheld: LongInt; cdecl; external name 'sr_switch_handheld';
procedure SwitchTouchPosition(X, Y: Integer); cdecl; external name 'sr_switch_touch_position';
{$ENDIF}

function CombinedMouseState(State: Cardinal): Cardinal;
begin
  Result := State;
{$IFDEF SWITCH}
  Result := Result or SwitchMouseButtons;
{$ENDIF}
end;

function GameMouseState(X, Y: PInteger): Cardinal;
begin
  Result := CombinedMouseState(SDL_GetMouseState(X, Y));
end;

procedure SetGameArcadeControls(Flags: Integer);
var
  Value: AnsiString;
begin
  if not GameWindowIsMobile or (Integer(ArcadeControls and $FF) = Flags) then
    Exit;
  // Each visibility/group change invalidates queued input from the old overlay.
  ArcadeControls := ((ArcadeControls + $100) and $7FFFFF00) or Cardinal(Flags);
  Value := AnsiString(UIntToStr(ArcadeControls));
  SDL_SetHint('SRHD_ARCADE_CONTROLS', PAnsiChar(Value));
end;

procedure LogGameVideo(const Text: UnicodeString);
begin
  LogGameMessage(gllInfo, 'video', Text);
end;

procedure CancelGamePointerInput;
begin
  if Touch <> nil then
    Touch.Cancel;
  WheelRemainder := 0;
end;

function WatchRendererReset(UserData: Pointer; Event: PSDL_Event): Integer; cdecl;
begin
  // SDL can lose the device inside RenderPresent, before PollGameMessage runs.
  // Mark handles immediately; recreation and redraw stay on the render thread.
  if Event^.Kind = SDL_RENDER_DEVICE_RESET then
    InterlockedIncrement(GameTextureGeneration);
  if (Event^.Kind = SDL_RENDER_DEVICE_RESET) or (Event^.Kind = SDL_RENDER_TARGETS_RESET) then
    InterlockedIncrement(GameTargetGeneration);
  if ((Event^.Kind = SDL_WINDOWEVENT) and (Event^.Window.Event in [6, 18]))
      or (Event^.Kind = SDL_RENDER_DEVICE_RESET)
      or (Event^.Kind = SDL_RENDER_TARGETS_RESET) then
    InterlockedIncrement(GameDisplayGeneration);
  Result := 1;
end;

procedure RefreshGameCursor;
begin
  // Reapply visibility without changing the game's ShowCursor counter. SDL's
  // show/hide call is a no-op when it already records the requested state.
  SDL_ShowCursor(Ord(CursorCount >= 0));
  SDL_SetCursor(nil);
{$IF Defined(DARWIN) and not Defined(SRHD_IOS)}
  // SDL's Cocoa backend only queues cursor-rectangle invalidation. After an
  // application switch, AppKit's current cursor can still be the game's cursor
  // while macOS displays the other application's arrow. Set it immediately so
  // restoration does not depend on the mouse leaving and re-entering the view.
  if GameWindowFocused and (SDL_GetMouseFocus = GameSDLWindow) then
    ReapplyCocoaCursor;
{$ENDIF}
end;

procedure InitializeGameVideo;
var
  Driver: string;
  Format: TFormatSettings;
  Version: TSDL_Version;
begin
  if VideoInitialized then
    Exit;
  // Native display drivers assume C's masked floating-point exceptions. Apply
  // the game's mask before SDL can initialize a driver (Metal may overflow
  // internal sampler calculations), rather than waiting for GR_DXInit.
  ClearExceptions(False);
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  SDL_SetMainReady;
  InstallGameSDLDiagnostics;
  SDL_GetVersion(Version);
  LogGameVideo(SysUtils.Format('SDL version=%d.%d.%d', [Version.Major, Version.Minor, Version.Patch]));
  // Handle native fingers ourselves; synthesized mouse presses commit game
  // actions before the user can distinguish a tap from a drag.
  SDL_SetHint('SDL_TOUCH_MOUSE_EVENTS', '0');
  SDL_SetHint('SDL_MOUSE_TOUCH_EVENTS', '0');
{$IFDEF ANDROID}
  // SDL_HINT_ORIENTATIONS retains its iOS name on Android too. Without it,
  // SDL's resizable window overrides the manifest and permits portrait.
  SDL_SetHint('SDL_IOS_ORIENTATIONS', 'LandscapeLeft LandscapeRight');
  SDL_SetHint('SDL_RENDER_LOGICAL_SIZE_MODE', 'letterbox');
  SDL_SetHint('SDL_ANDROID_TRAP_BACK_BUTTON', '1');
  // Accept hardware text without opening the IME at startup. Controls > Keyboard
  // enables SDL keyboard management for the lifetime of that explicit session.
  SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '0');
{$ENDIF}
  CheckGameSDL(SDL_InitSubSystem(SDL_INIT_VIDEO or SDL_INIT_TIMER), 'SDL_InitSubSystem(video/timer)');
  // These desktop backends provide real global coordinates. Other backends
  // (notably Wayland) may return cached window coordinates from the same API.
  // SDL spells its Android backend "Android", unlike the lower-case desktop
  // names. Normalize before selecting mobile sizing and keyboard behavior.
  Driver := LowerCase(string(SDL_GetCurrentVideoDriver));
  LogGameVideo('SDL video driver=' + Driver);
  DesktopMouseAvailable := (Driver = 'cocoa') or (Driver = 'windows') or (Driver = 'x11');
  BrowserWindow := Driver = 'emscripten';
  MobileWindow := (Driver = 'android') or (Driver = 'uikit');
  FullscreenOnlyWindow := MobileWindow or (Driver = 'switch');
  MobileUiEnabled := MobileWindow;
{$IFDEF SWITCH}
  HandheldMode := SwitchHandheld <> 0;
  MobileUiEnabled := HandheldMode;
{$ENDIF}
  Format := DefaultFormatSettings;
  Format.DecimalSeparator := '.';
  MobileDensity := StrToFloatDef(string(SDL_GetHint('SRHD_UI_DENSITY')), 1, Format);
  if (MobileDensity <= 0) or IsNan(MobileDensity) or IsInfinite(MobileDensity) then
    MobileDensity := 1;
  TouchSlop := EnsureRange(StrToIntDef(string(SDL_GetHint('SRHD_TOUCH_SLOP')), 8), 1, 256);
  PostedMessageType := SDL_RegisterEvents(1);
  if PostedMessageType = Cardinal(-1) then
    RaiseGameSDLError('SDL_RegisterEvents(game messages, count=1)');
  SDL_AddEventWatch(WatchRendererReset, nil);
  Touch := TGameTouch.Create;
  VideoInitialized := True;
end;

function GameWindowHasSystemCursor: Boolean;
begin
{$IFDEF SWITCH}
  Result := False;
{$ELSE}
  Result := True;
{$ENDIF}
end;

function GamePointerCursorVisible: Boolean;
begin
{$IFDEF SWITCH}
  Result := (SwitchHandheld = 0) or PointerCursorActive;
{$ELSE}
  Result := True;
{$ENDIF}
end;

function GameWindowUsesCanvas: Boolean;
begin
  InitializeGameVideo;
  Result := BrowserWindow;
end;

function GameWindowIsMobile: Boolean;
begin
  InitializeGameVideo;
  Result := MobileWindow;
end;

function GameWindowIsFullscreenOnly: Boolean;
begin
  InitializeGameVideo;
  Result := FullscreenOnlyWindow;
end;

function DesiredMobileUi: Boolean;
begin
  case GameUiMode of
    gumDesktop: Result := False;
    gumMobile: Result := True;
  else
{$IFDEF SWITCH}
    Result := SwitchHandheld <> 0;
{$ELSE}
    Result := MobileWindow;
{$ENDIF}
  end;
end;

procedure ConfigureGameUi(Mode: TGameUiMode);
begin
  InitializeGameVideo;
  GameUiMode := Mode;
  MobileUiEnabled := DesiredMobileUi;
  CommitGameUiLayout;
end;

procedure CommitGameUiLayout;
begin
  // Layout dimensions and density belong to the control tree. Presentation
  // still follows the live surface while a safe tree rebuild is deferred.
  UiDisplayMetrics := GetGameDisplayMetrics;
end;

function GameMobileUiEnabled: Boolean;
begin
  InitializeGameVideo;
  Result := MobileUiEnabled;
end;

function GameUiLayoutChangePending: Boolean;
var
  Metrics: TGameDisplayMetrics;
begin
  InitializeGameVideo;
  Result := MobileUiEnabled <> DesiredMobileUi;
  if MobileUiEnabled then
  begin
    Metrics := GetGameDisplayMetrics;
    Result :=
        Result
            or (Metrics.Density <> UiDisplayMetrics.Density)
            or (Metrics.OutputSize.X <> UiDisplayMetrics.OutputSize.X)
            or (Metrics.OutputSize.Y <> UiDisplayMetrics.OutputSize.Y);
  end;
end;

function GameWindowUsesNativeRaster: Boolean;
begin
  // Android keeps full-resolution rendering with either layout. Desktop opts
  // into the same raster/input transform when using independently scaled UI.
  Result := GameWindowIsFullscreenOnly or GameMobileUiEnabled;
end;

function GameWindowUsesRenderResolution: Boolean;
begin
  InitializeGameVideo;
  // Browser and Android surfaces belong to the host. Resolution settings choose
  // the game's layout, without changing the display's physical resolution.
  Result := BrowserWindow or FullscreenOnlyWindow;
end;

procedure GetGameAutomaticLayoutSize(MinWidth, MinHeight: Integer; out Width, Height: Integer);
var
  Metrics: TGameDisplayMetrics;
  Scale: Double;
begin
  Metrics := GetGameDisplayMetrics;
  Width := Metrics.OutputSize.X;
  Height := Metrics.OutputSize.Y;
  if (Width <= 0) or (Height <= 0) then
  begin
    Width := MinWidth;
    Height := MinHeight;
  end;
  // Mobile UI requests one dp per source pixel; desktop UI uses output pixels.
  // Both retain the complete minimum layout. Continuous fitting avoids size
  // jumps between displays with equivalent dp dimensions.
  Scale := 1;
  if GameMobileUiEnabled then
    Scale := Max(1.0, Metrics.Density);
  Scale := Min(Scale, Min(Width / MinWidth, Height / MinHeight));
  Width := Max(MinWidth, Round(Width / Scale));
  Height := Max(MinHeight, Round(Height / Scale));
end;

function GetGameDisplayMetrics: TGameDisplayMetrics;
var
  Mode: TSDL_DisplayMode;
begin
  InitializeGameVideo;
  Result := Default(TGameDisplayMetrics);
  Result.Density := MobileDensity;
{$IFDEF SWITCH}
  // The handheld's 720p panel needs larger touch targets than a TV layout.
  if SwitchHandheld <> 0 then
    Result.Density := 1.5 * MobileDensity;
{$ENDIF}
  Result.TouchSlop := TouchSlop;
  if GameSDLWindow <> nil then
  begin
    SDL_GetWindowSize(GameSDLWindow, Result.WindowSize.X, Result.WindowSize.Y);
    SDL_GetWindowSizeInPixels(GameSDLWindow, Result.OutputSize.X, Result.OutputSize.Y);
    // Desktop UI sizes use window points, including Retina's backing scale.
    // Keep Android's supplied density: its window points are physical pixels.
    if not FullscreenOnlyWindow then
      Result.Density := Max(1.0, Result.OutputSize.X / Max(1, Result.WindowSize.X));
  end
  else
  begin
    Mode := Default(TSDL_DisplayMode);
    if SDL_GetCurrentDisplayMode(0, Mode) < 0 then
    begin
      Mode := Default(TSDL_DisplayMode);
      // Zero dimensions select the caller's minimum layout.
      if not DisplayModeWarningLogged then
        LogGameMessage(gllWarning, 'video', 'SDL_GetCurrentDisplayMode(display=0): ' + GameSDLErrorMessage);
      DisplayModeWarningLogged := True;
    end
    else
      DisplayModeWarningLogged := False;
    Result.OutputSize := Types.Point(Mode.W, Mode.H);
{$IFDEF SWITCH}
    // SDL's Switch backend reports 1080p as its initial desktop mode even
    // when undocked. Match the physical surface before creating the window.
    if SwitchHandheld <> 0 then
      Result.OutputSize := Types.Point(1280, 720);
{$ENDIF}
    Result.WindowSize := Result.OutputSize;
  end;
end;

function CalculateGamePresentation(const Metrics: TGameDisplayMetrics; Width, Height: Integer): TGamePresentation;
var
  W, H: Integer;
  Scale: Double;
begin
  Result.Metrics := Metrics;
  Result.LogicalSize := Types.Point(Max(1, Width), Max(1, Height));
  W := Max(1, Metrics.OutputSize.X);
  H := Max(1, Metrics.OutputSize.Y);
  Scale := Min(W / Result.LogicalSize.X, H / Result.LogicalSize.Y);
  Width := Min(W, Max(1, Round(Result.LogicalSize.X * Scale)));
  Height := Min(H, Max(1, Round(Result.LogicalSize.Y * Scale)));
  Result.OutputRect.Left := (W - Width) div 2;
  Result.OutputRect.Top := (H - Height) div 2;
  Result.OutputRect.Right := Result.OutputRect.Left + Width;
  Result.OutputRect.Bottom := Result.OutputRect.Top + Height;
end;

procedure TGamePresentation.OutputToLogical(X, Y: Double; out LogicalX, LogicalY: Double);
begin
  LogicalX := (X - OutputRect.Left) * LogicalSize.X / (OutputRect.Right - OutputRect.Left);
  LogicalY := (Y - OutputRect.Top) * LogicalSize.Y / (OutputRect.Bottom - OutputRect.Top);
end;

function TGamePresentation.WindowToLogical(X, Y: Integer): TPoint;
var
  LX, LY: Double;
begin
  OutputToLogical(X * Metrics.OutputSize.X / Max(1, Metrics.WindowSize.X), Y * Metrics.OutputSize.Y / Max(1, Metrics.WindowSize.Y), LX, LY);
  Result := Types.Point(Floor(LX), Floor(LY));
end;

function TGamePresentation.LogicalToWindow(X, Y: Integer): TPoint;
begin
  Result.X :=
      Round(
          (OutputRect.Left + X * (OutputRect.Right - OutputRect.Left) / LogicalSize.X) * Metrics.WindowSize.X / Max(1, Metrics.OutputSize.X)
      );
  Result.Y :=
      Round(
          (OutputRect.Top + Y * (OutputRect.Bottom - OutputRect.Top) / LogicalSize.Y) * Metrics.WindowSize.Y / Max(1, Metrics.OutputSize.Y)
      );
end;

function TGamePresentation.PixelScale: Double;
begin
  Result := Min((OutputRect.Right - OutputRect.Left) / LogicalSize.X, (OutputRect.Bottom - OutputRect.Top) / LogicalSize.Y);
end;

function GetGamePresentationRect(Width, Height: Integer): TRect;
begin
  Result := CalculateGamePresentation(GetGameDisplayMetrics, Width, Height).OutputRect;
end;

procedure GetGameWindowLogicalSize(out Width, Height: Integer);
begin
  Width := LogicalWidth;
  Height := LogicalHeight;
end;

function GetGameWindowPixelScale: Single;
begin
  Result := 1;
  if (GameSDLWindow = nil) or (LogicalWidth <= 0) or (LogicalHeight <= 0) then
    Exit;
  Result := CalculateGamePresentation(GetGameDisplayMetrics, LogicalWidth, LogicalHeight).PixelScale;
end;

function GetGameMobileUiScale(DpPerSourcePixel: Single): Single;
var
  Scale: Double;
begin
  // Source artwork size -> game-logical size. Callers bound this desired dp
  // scale to their usable area; raster resolution and world zoom stay separate.
  Result := 1;
  if GameMobileUiEnabled then
  begin
    Scale := 1;
    if (LogicalWidth > 0) and (LogicalHeight > 0) then
      Scale := CalculateGamePresentation(UiDisplayMetrics, LogicalWidth, LogicalHeight).PixelScale;
    Result := UiDisplayMetrics.Density * DpPerSourcePixel / Scale;
  end;
end;

procedure LogGameVideoDiagnostics;
var
  RendererInfo: TSDL_RendererInfo;
  Metrics: TGameDisplayMetrics;
  OutputWidth, OutputHeight: Integer;
  RendererSize, Description: UnicodeString;
  ModeFlags: Cardinal;
begin
  if SDL_GetRendererInfo(GameSDLRenderer, RendererInfo) < 0 then
  begin
    LogGameMessage(gllWarning, 'video', 'SDL_GetRendererInfo: ' + GameSDLErrorMessage);
    LastVideoLog.RendererDescription := '';
  end
  else
  begin
    Description :=
        'Renderer: name='
            + UTF8Decode(UTF8String(RendererInfo.Name))
            + ' flags=$'
            + IntToHex(RendererInfo.Flags, 8)
            + ' maximum-texture='
            + IntToStr(RendererInfo.MaxTextureWidth)
            + 'x'
            + IntToStr(RendererInfo.MaxTextureHeight);
    if (LastVideoLog.Renderer <> GameSDLRenderer)
        or (LastVideoLog.TextureGeneration <> GameTextureGeneration)
        or (LastVideoLog.RendererDescription <> Description) then
      LogGameVideo(Description);
    LastVideoLog.RendererDescription := Description;
  end;
  LastVideoLog.Renderer := GameSDLRenderer;
  LastVideoLog.TextureGeneration := GameTextureGeneration;
  if GameSDLWindow = nil then
  begin
    Description := 'Window diagnostics unavailable: no SDL window';
    if LastVideoLog.WindowDescription <> Description then
      LogGameVideo(Description);
    LastVideoLog.WindowDescription := Description;
    LastVideoLog.Window := nil;
    LastVideoLog.ModeFlags := 0;
    Exit;
  end;
  Metrics := Default(TGameDisplayMetrics);
  SDL_GetWindowSize(GameSDLWindow, Metrics.WindowSize.X, Metrics.WindowSize.Y);
  SDL_GetWindowSizeInPixels(GameSDLWindow, Metrics.OutputSize.X, Metrics.OutputSize.Y);
  if SDL_GetRendererOutputSize(GameSDLRenderer, OutputWidth, OutputHeight) < 0 then
  begin
    LogGameMessage(gllWarning, 'video', 'SDL_GetRendererOutputSize: ' + GameSDLErrorMessage);
    RendererSize := 'unavailable';
  end
  else
    RendererSize := IntToStr(OutputWidth) + 'x' + IntToStr(OutputHeight) + ' pixels';
  ModeFlags := SDL_GetWindowFlags(GameSDLWindow) and DiagnosticWindowModeFlags;
  Description :=
      Format(
              'Window state: window=%dx%d points drawable=%dx%d pixels ',
              [Metrics.WindowSize.X, Metrics.WindowSize.Y, Metrics.OutputSize.X, Metrics.OutputSize.Y])
          + 'renderer='
          + RendererSize
          + Format(
              ' logical=%dx%d high-dpi=%s',
              [LogicalWidth, LogicalHeight, BoolToStr((ModeFlags and SDL_WINDOW_ALLOW_HIGHDPI) <> 0, True)])
          + ' mode-flags=$'
          + IntToHex(ModeFlags, 8);
  if (LastVideoLog.Window <> GameSDLWindow) or (LastVideoLog.WindowDescription <> Description) then
    LogGameVideo(Description);
  LastVideoLog.WindowDescription := Description;
  LastVideoLog.Window := GameSDLWindow;
  LastVideoLog.ModeFlags := ModeFlags;
end;

procedure OpenGameWindow(Width, Height: Integer; Windowed, VSync: Boolean);
var
  Flags: Cardinal;
  PreviousTarget: PSDL_Texture;
  TargetGeneration: LongInt;
  Created: Boolean;
  WindowSize: TPoint;
  ErrorText, Configuration: UnicodeString;
  CurrentModeFlags: Cardinal;
begin
  if VideoFaulted then
    raise Exception.Create('Video initialization cannot be retried after a native graphics fault');
  try
    InitializeGameVideo;
    // The browser controls canvas size and fullscreen through CSS and user gestures.
    if BrowserWindow then
      Windowed := True;
    if FullscreenOnlyWindow then
      Windowed := False;
    Configuration :=
        Format('Configure window: logical=%dx%d windowed=%s vsync=%s', [Width, Height, BoolToStr(Windowed, True), BoolToStr(VSync, True)]);
    CurrentModeFlags := 0;
    if GameSDLWindow <> nil then
      CurrentModeFlags := SDL_GetWindowFlags(GameSDLWindow) and DiagnosticWindowModeFlags;
    // Suppress duplicate descriptions only. The configuration calls below must
    // still run to restore SDL state after drawing, device resets and retries.
    if (LastVideoLog.Configuration <> Configuration)
        or (LastVideoLog.Window <> GameSDLWindow)
        or (LastVideoLog.Renderer <> GameSDLRenderer)
        or (LastVideoLog.ModeFlags <> CurrentModeFlags) then
      LogGameVideo(Configuration);
    TargetGeneration := GameTargetGeneration;
    LogicalWidth := Width;
    LogicalHeight := Height;
    if (GameSDLWindow <> nil) and (GameSDLRenderer = nil) then
      CloseGameWindow;
    Created := GameSDLWindow = nil;
    if Created then
    begin
      try
        WindowSize := Types.Point(Width, Height);
{$IFDEF SWITCH}
        WindowSize := GetGameDisplayMetrics.OutputSize;
{$ENDIF}
        Flags := SDL_WINDOW_ALLOW_HIGHDPI;
        if BrowserWindow or FullscreenOnlyWindow then
          Flags := Flags or SDL_WINDOW_RESIZABLE;
        LogGameVideo(Format('SDL_CreateWindow(size=%dx%d points, flags=$%s)', [WindowSize.X, WindowSize.Y, IntToHex(Flags, 8)]));
        GameSDLWindow := SDL_CreateWindow('Rangers', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WindowSize.X, WindowSize.Y, Flags);
        if GameSDLWindow = nil then
          RaiseGameSDLError(Format('SDL_CreateWindow(%dx%d points, flags=$%s)', [WindowSize.X, WindowSize.Y, IntToHex(Flags, 8)]));
        Flags := SDL_RENDERER_ACCELERATED or SDL_RENDERER_TARGETTEXTURE;
        if VSync then
          Flags := Flags or SDL_RENDERER_PRESENTVSYNC;
        LogGameVideo(Format('SDL_CreateRenderer(accelerated, target textures, vsync=%s)', [BoolToStr(VSync, True)]));
        GameSDLRenderer := SDL_CreateRenderer(GameSDLWindow, -1, Flags);
        ErrorText := '';
        if GameSDLRenderer = nil then
        begin
          ErrorText := GameSDLErrorMessage;
          LogGameMessage(gllWarning, 'video', 'Accelerated renderer unavailable; trying software renderer: ' + ErrorText);
          LogGameVideo('SDL_CreateRenderer(software, target textures)');
          GameSDLRenderer := SDL_CreateRenderer(GameSDLWindow, -1, SDL_RENDERER_SOFTWARE or SDL_RENDERER_TARGETTEXTURE);
        end;
        if GameSDLRenderer = nil then
          RaiseGameSDLError('SDL_CreateRenderer(software, target textures); accelerated attempt: ' + ErrorText + '; software attempt');
{$IFDEF SWITCH}
        // Switch SDL suppresses touch/mouse polling while text input is active.
        // The right-stick button opens the software keyboard explicitly.
        SDL_StopTextInput;
{$ELSE}
  {$IFDEF ANDROID}
        AndroidKeyboardSession := False;
        SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '0');
        SDL_StartTextInput;
  {$ELSE}
        if MobileWindow then
        begin
          SDL_EventState(SDL_TEXTINPUT, SDL_ENABLE);
          SDL_EventState(SDL_TEXTEDITING, SDL_ENABLE);
        end
        else
          SDL_StartTextInput;
  {$ENDIF}
{$ENDIF}
      except
        if ExceptObject is Exception then
          AddGameExceptionContext(Exception(ExceptObject), 'Creating game window and renderer');
        // Native faults leave driver state unspecified. Do not call it again.
        if GameExceptionPreventsRecovery(ExceptObject) then
          raise;
        // Creation may raise through a native driver instead of returning nil.
        // Never leave a window that makes the next attempt skip renderer creation.
        try
          CloseGameWindow;
        except
          LogCurrentGameException('video', 'Secondary failure cleaning up window creation');
        end;
        raise;
      end;
    end;
    // SDL's browser resize handler follows the canvas CSS size. Keep the selected
    // game resolution in the renderer instead of replacing the canvas dimensions.
    if not BrowserWindow and not FullscreenOnlyWindow then
      SDL_SetWindowSize(GameSDLWindow, Width, Height);
    Flags := 0;
    if not Windowed then
      Flags := SDL_WINDOW_FULLSCREEN_DESKTOP;
{$IFNDEF SWITCH}
    // Switch has one fullscreen surface; desktop fullscreen would force 1080p.
    CheckGameSDL(SDL_SetWindowFullscreen(GameSDLWindow, Flags), 'SDL_SetWindowFullscreen(flags=' + IntToStr(Flags) + ')');
{$ENDIF}
    // Native raster drawing uses our explicit integer viewport for both input
    // and presentation, avoiding SDL's separate floor-rounded viewport.
    PreviousTarget := SDL_GetRenderTarget(GameSDLRenderer);
    if TargetGeneration <> GameTargetGeneration then
      PreviousTarget := nil;
    CheckGameSDL(SDL_SetRenderTarget(GameSDLRenderer, nil), 'SDL_SetRenderTarget(window)');
    try
      if GameWindowUsesNativeRaster then
        CheckGameSDL(SDL_RenderSetLogicalSize(GameSDLRenderer, 0, 0), 'SDL_RenderSetLogicalSize(0, 0)')
      else
        CheckGameSDL(SDL_RenderSetLogicalSize(GameSDLRenderer, Width, Height), Format('SDL_RenderSetLogicalSize(%d, %d)', [Width, Height]));
    except
      // A restoration error is secondary; preserve the configuration failure.
      try
        CheckGameSDL(SDL_SetRenderTarget(GameSDLRenderer, PreviousTarget), 'SDL_SetRenderTarget(restore after configuration failure)');
      except
        if GameExceptionPreventsRecovery(ExceptObject) then
          VideoFaulted := True;
        LogCurrentGameException('video', 'Secondary failure restoring renderer target');
      end;
      raise;
    end;
    CheckGameSDL(SDL_SetRenderTarget(GameSDLRenderer, PreviousTarget), 'SDL_SetRenderTarget(restore)');
    CheckGameSDL(SDL_RenderSetVSync(GameSDLRenderer, Ord(VSync)), 'SDL_RenderSetVSync(' + IntToStr(Ord(VSync)) + ')');
    SDL_ShowCursor(Ord(CursorCount >= 0));
    if Created then
    begin
      // SDL's Android display mode can precede the first surface dimensions.
      // Let the game compare Auto again once a real surface exists.
      HasPendingDisplayChange := GameWindowUsesNativeRaster;
      // Wayland maps the window only after a buffer is presented. The game waits
      // for real focus before drawing its loading screen, so supply the first
      // buffer here to avoid waiting for focus on an invisible surface.
      CheckGameSDL(SDL_SetRenderDrawColor(GameSDLRenderer, 0, 0, 0, 255), 'SDL_SetRenderDrawColor');
      CheckGameSDL(SDL_RenderClear(GameSDLRenderer), 'SDL_RenderClear');
      SDL_RenderPresent(GameSDLRenderer);
    end;
    LogGameVideoDiagnostics;
    LastVideoLog.Configuration := Configuration;
  except
    if GameExceptionPreventsRecovery(ExceptObject) then
      VideoFaulted := True;
    if ExceptObject is Exception then
      AddGameExceptionContext(Exception(ExceptObject), 'Configuring game window');
    raise;
  end;
end;

procedure CloseGameWindow;
var
  Renderer: PSDL_Renderer;
  Window: PSDL_Window;
begin
  try
    LastVideoLog := Default(TGameVideoLogSnapshot);
    Renderer := GameSDLRenderer;
    Window := GameSDLWindow;
    // Clear ownership before native teardown, which itself may raise.
    GameSDLRenderer := nil;
    GameSDLWindow := nil;
{$IFDEF ANDROID}
    AndroidKeyboardSession := False;
{$ENDIF}
    TextInput := '';
    TextPosition := 0;
    CancelGamePointerInput;
    TouchMouseActive := False;
    PointerCursorActive := False;
    HasPendingActivation := False;
    HasPendingDisplayChange := False;
    if VideoFaulted then
      Exit;
    if Window <> nil then
      SDL_StopTextInput;
    if Renderer <> nil then
      SDL_DestroyRenderer(Renderer);
    if Window <> nil then
      SDL_DestroyWindow(Window);
  except
    if GameExceptionPreventsRecovery(ExceptObject) then
      VideoFaulted := True;
    if ExceptObject is Exception then
      AddGameExceptionContext(Exception(ExceptObject), 'Closing game window');
    raise;
  end;
end;

function KeyFromScanCode(ScanCode: Integer): Cardinal;
begin
  if (ScanCode >= 4) and (ScanCode <= 29) then
    Exit(ScanCode - 4 + Ord('A'));
  if (ScanCode >= 30) and (ScanCode <= 38) then
    Exit(ScanCode - 30 + Ord('1'));
  if (ScanCode >= 58) and (ScanCode <= 69) then
    Exit(ScanCode - 58 + 112);
  if (ScanCode >= 89) and (ScanCode <= 97) then
    Exit(ScanCode - 89 + 97);
  case ScanCode of
    225, 229: Result := 16;
    224, 228: Result := 17;
    226, 230: Result := 18;
    80: Result := 37;
    82: Result := 38;
    79: Result := 39;
    81: Result := 40;
    74: Result := 36;
    77: Result := 35;
    75: Result := 33;
    78: Result := 34;
    76: Result := 46;
    73: Result := 45;
    40, 88: Result := 13;
    41: Result := 27;
    44: Result := 32;
    42: Result := 8;
    43: Result := 9;
    39: Result := Ord('0');
    98: Result := 96;
    57: Result := 20;
    72: Result := 19;
    45: Result := 189;
    46: Result := 187;
    270: Result := VK_ESCAPE; // SDL_SCANCODE_AC_BACK, including Android Back.
    47: Result := 219;
    48: Result := 221;
    49: Result := 220;
    51: Result := 186;
    52: Result := 222;
    53: Result := 192;
    54: Result := 188;
    55: Result := 190;
    56: Result := 191;
    87: Result := 107;
    86: Result := 109;
    85: Result := 106;
    84: Result := 111;
    99: Result := 110;
  else
    Result := 0;
  end;
end;

function MouseKeys(State: Cardinal): Cardinal;
begin
  Result := 0;
  if State and 1 <> 0 then
    Result := Result or MK_LBUTTON;
  if State and 4 <> 0 then
    Result := Result or MK_RBUTTON;
  if State and 2 <> 0 then
    Result := Result or MK_MBUTTON;
  if GameKeyState(VK_SHIFT) < 0 then
    Result := Result or MK_SHIFT;
  if GameKeyState(VK_CONTROL) < 0 then
    Result := Result or MK_CONTROL;
end;

// Direct mouse queries and warps use window points, while SDL has already
// converted queued events to the logical resolution. Mirror the window's
// letterboxing here, independently of the currently selected render texture.
procedure WindowTransform(out Scale: Double; out OffsetX, OffsetY: Integer);
var
  Width, Height: Integer;
begin
  SDL_GetWindowSize(GameSDLWindow, Width, Height);
  Scale := Min(Width / Max(1, LogicalWidth), Height / Max(1, LogicalHeight));
  if Scale <= 0 then
    Scale := 1;
  OffsetX := Trunc((Width - LogicalWidth * Scale) / 2);
  OffsetY := Trunc((Height - LogicalHeight * Scale) / 2);
end;

function WindowPoint(X, Y: Integer): TPoint;
var
  Scale: Double;
  OffsetX, OffsetY: Integer;
  Presentation: TGamePresentation;
begin
  if GameWindowUsesNativeRaster then
  begin
    Presentation := CalculateGamePresentation(GetGameDisplayMetrics, LogicalWidth, LogicalHeight);
    Exit(Presentation.WindowToLogical(X, Y));
  end;
  WindowTransform(Scale, OffsetX, OffsetY);
  Result := Types.Point(Floor((X - OffsetX) / Scale), Floor((Y - OffsetY) / Scale));
end;

// The inverse of WindowPoint, for handing input coordinates back to SDL.
function LogicalWindowPoint(X, Y: Integer): TPoint;
var
  Scale: Double;
  OffsetX, OffsetY: Integer;
  Presentation: TGamePresentation;
begin
  if GameWindowUsesNativeRaster then
  begin
    Presentation := CalculateGamePresentation(GetGameDisplayMetrics, LogicalWidth, LogicalHeight);
    Exit(Presentation.LogicalToWindow(X, Y));
  end;
  WindowTransform(Scale, OffsetX, OffsetY);
  Result := Types.Point(Round(X * Scale) + OffsetX, Round(Y * Scale) + OffsetY);
end;

procedure ShowGameTextInput(const Bounds: TRect);
{$IFDEF ANDROID}
var
  TopLeft, BottomRight: TPoint;
{$ENDIF}
begin
{$IFDEF ANDROID}
  if AppInBackground or (GameSDLWindow = nil) then
    Exit;
  TopLeft := LogicalWindowPoint(Bounds.Left, Bounds.Top);
  BottomRight := LogicalWindowPoint(Bounds.Right, Bounds.Bottom);
  AndroidTextInputRect.X := TopLeft.X;
  AndroidTextInputRect.Y := TopLeft.Y;
  AndroidTextInputRect.W := Max(1, BottomRight.X - TopLeft.X);
  AndroidTextInputRect.H := Max(1, BottomRight.Y - TopLeft.Y);
  // An open keyboard keeps its editor; SDL reads the rectangle when it shows one.
  if AndroidKeyboardSession and (SDL_IsTextInputActive <> 0) then
    Exit;
  SDL_SetTextInputRect(@AndroidTextInputRect);
  // The same session as the Controls keyboard button: Back or that button ends it.
  SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '1');
  SDL_StartTextInput;
  AndroidKeyboardSession := True;
{$ENDIF}
end;

procedure ForgetGameTextInputBounds;
begin
{$IFDEF ANDROID}
  AndroidTextInputRect := Default(TSDL_Rect);
{$ENDIF}
end;

function PollGameMessage(out Message: TGameMessage): Boolean;
var
  Event: TSDL_Event;
  Step, X, Y, OffsetX, OffsetY: Integer;
  Amount, Scale, FingerX, FingerY: Double;
  Point: TPoint;
  Phase: TTouchPhase;
  Presentation: TGamePresentation;
{$IFDEF ANDROID}
  InputRect: TSDL_Rect;
{$ENDIF}

  procedure CancelInput;
  begin
    CancelGamePointerInput;
    TextInput := '';
    TextPosition := 0;
    Message.Message := WM_GAME_CANCEL_INPUT;
  end;

begin
{$IFDEF ANDROID}
  if AndroidKeyboardSession and (SDL_IsTextInputActive = 0) and (SDL_EventState(SDL_TEXTEDITING, SDL_QUERY) = SDL_DISABLE) then
  begin
    // SDL's UI-thread Back handler disables text and editing separately. Wait
    // for both, so it cannot disable editing after we restart hardware input.
    // At this point SDL has also requested editor cleanup.
    // Resume hardware text without showing the IME; the next button press starts
    // a new SDL-managed keyboard session with a fresh Android input connection.
    AndroidKeyboardSession := False;
    SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '0');
    SDL_StartTextInput;
  end;
{$ENDIF}
{$IFDEF SWITCH}
  SwitchPollInput(GameSDLWindow);
  if HandheldMode <> (SwitchHandheld <> 0) then
  begin
    HandheldMode := SwitchHandheld <> 0;
    HasPendingDisplayChange := True;
    InterlockedIncrement(GameDisplayGeneration);
  end;
{$ENDIF}
  Result := True;
  Message := Default(TGameMessage);
  repeat
    if HasPendingDisplayChange then
    begin
      HasPendingDisplayChange := False;
      Message.Message := WM_GAME_DISPLAY_CHANGED;
      Exit;
    end;
    if HasPendingActivation then
    begin
      HasPendingActivation := False;
      Message.Message := WM_ACTIVATEAPP;
      Message.WParam := PendingActivation;
      Exit;
    end;
    if (Touch <> nil) and Touch.Poll(Message) then
    begin
      TouchMouseActive := True;
      TouchMouse := Types.Point(SmallInt(Message.LParam), SmallInt(Message.LParam shr 16));
      Exit;
    end;
    if TextPosition <= Length(TextInput) then
      if TextPosition > 0 then
      begin
        Message.Message := WM_CHAR;
        Message.WParam := Ord(TextInput[TextPosition]);
        Message.LParam := 1;
        Inc(TextPosition);
        Exit;
      end;
    if Abs(WheelRemainder) >= 1 then
    begin
      Step := Sign(WheelRemainder);
      WheelRemainder := WheelRemainder - Step;
      Message := WheelMessage;
      Message.WParam := Message.WParam or (Cardinal(Word(Step * WHEEL_DELTA)) shl 16);
      Exit;
    end;
    if HasPendingEvent then
    begin
      Event := PendingEvent;
      HasPendingEvent := False;
    end
    else if SDL_PollEvent(Event) = 0 then
      Break;
    // JNI overlay messages are queued by the native Android launcher. Check
    // their codes before our registered event (which may equal SDL_USEREVENT).
{$IFDEF ANDROID}
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $53524B42) then
    begin
      if AppInBackground or (GameSDLWindow = nil) then
        Continue;
      if AndroidKeyboardSession and (SDL_IsTextInputActive <> 0) then
      begin
        // Use the same editor cleanup and hardware-input recovery as Back.
        SDL_StopTextInput;
        Continue;
      end;
      InputRect := AndroidTextInputRect;
      if InputRect.W = 0 then
      begin
        InputRect.W := 400;
        InputRect.H := 40;
      end;
      SDL_SetTextInputRect(@InputRect);
      // Leave keyboard management enabled until Back or the next button press
      // stops input and releases the hidden Java editor and its old contents.
      SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '1');
      SDL_StartTextInput;
      AndroidKeyboardSession := True;
      Continue;
    end;
{$ENDIF}
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $53524143) then
    begin
      if AppInBackground
          or (ArcadeControls and 1 = 0)
          or (Cardinal(PtrUInt(Event.User.Data2)) and $FFFFFF00 <> ArcadeControls and $FFFFFF00) then
        Continue;
      Message.Message := WM_GAME_ARCADE_INPUT;
      Message.WParam := Cardinal(PtrUInt(Event.User.Data2)) and 3;
      Message.LParam := Integer(PtrInt(Event.User.Data1));
      Exit;
    end;
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $53524354) then
    begin
      CancelInput;
      Exit;
    end;
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $5352494D) then
    begin
      TouchMode := PtrInt(Event.User.Data1) and 3;
      Continue;
    end;
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $53524444) then
    begin
      // Java sends densityDpi; keep SDL hint reads and density changes on the
      // game thread, because SDL's hint storage is not thread-safe.
      if not MobileWindow or (PtrInt(Event.User.Data1) <= 0) then
        Continue;
      TouchSlop := EnsureRange(Round(TouchSlop * (PtrInt(Event.User.Data1) / 160.0) / MobileDensity), 1, 256);
      MobileDensity := PtrInt(Event.User.Data1) / 160.0;
      InterlockedIncrement(GameDisplayGeneration);
      Message.Message := WM_GAME_DISPLAY_CHANGED;
      Exit;
    end;
    if (Event.Kind = SDL_USEREVENT) and (Event.User.Code = $53525343) then
    begin
      if AppInBackground then
        Continue;
      Step := Sign(PtrInt(Event.User.Data1));
      if Step = 0 then
        Continue;
      // The Android controls overlay has no game-space coordinates. Resolve
      // its target here, after queued touches have updated the virtual cursor.
      // Touch-to-mouse synthesis is disabled, so SDL's mouse position is stale.
      GetGameMouse(Point);
      Message.Message := WM_MOUSEWHEEL;
      Message.WParam := MouseKeys(GameMouseState(nil, nil)) or (Cardinal(Word(Step * WHEEL_DELTA)) shl 16);
      Message.LParam := PackGamePoint(Point.X, Point.Y);
      Exit;
    end;
    if Event.Kind = PostedMessageType then
    begin
      Message.Message := Cardinal(Event.User.Code);
      Message.WParam := Cardinal(PtrUInt(Event.User.Data1));
      Message.LParam := Integer(PtrInt(Event.User.Data2));
      Exit;
    end;
    case Event.Kind of
      SDL_APP_WILLENTERBACKGROUND, SDL_APP_DIDENTERBACKGROUND:
      begin
        if AppInBackground then
          Continue;
        AppInBackground := True;
        CancelInput;
        HasPendingActivation := True;
        PendingActivation := 0;
        Exit;
      end;
      SDL_APP_DIDENTERFOREGROUND:
      begin
        AppInBackground := False;
        RefreshGameCursor;
        Message.Message := WM_ACTIVATEAPP;
        Message.WParam := 1;
        Exit;
      end;
      SDL_RENDER_TARGETS_RESET, SDL_RENDER_DEVICE_RESET:
      begin
        Message.Message := WM_GAME_RENDER_RESET;
        Exit;
      end;
      SDL_QUIT_EVENT:
      begin
        Message.Message := WM_CLOSE;
        Exit;
      end;
      SDL_WINDOWEVENT:
        case Event.Window.Event of
          6, 18: // SDL_WINDOWEVENT_SIZE_CHANGED / DISPLAY_CHANGED (Retina scale can change).
          begin
            if not GameWindowUsesNativeRaster then
              Continue;
            Message.Message := WM_GAME_DISPLAY_CHANGED;
            Exit;
          end;
          3:
          begin
            Message.Message := WM_PAINT;
            Exit;
          end;
          12, 13:
          begin
            if Event.Window.Event = 13 then
            begin
              CancelInput;
              HasPendingActivation := True;
              PendingActivation := 0;
              Exit;
            end;
            if Event.Window.Event = 12 then
              RefreshGameCursor;
            Message.Message := WM_ACTIVATEAPP;
            Message.WParam := Ord(Event.Window.Event = 12);
            Exit;
          end;
          10: // SDL_WINDOWEVENT_ENTER: restore the cursor even before another motion event.
          begin
            RefreshGameCursor;
            GetGameMouse(Point);
            Message.Message := WM_MOUSEMOVE;
            Message.WParam := MouseKeys(GameMouseState(nil, nil));
            Message.LParam := PackGamePoint(Point.X, Point.Y);
            Exit;
          end;
          11:
          begin
            Message.Message := WM_MOUSELEAVE;
            Exit;
          end;
        end;
      SDL_KEYDOWN, SDL_KEYUP:
      begin
        Message.Message := WM_KEYDOWN;
        if Event.Kind = SDL_KEYUP then
          Message.Message := WM_KEYUP;
        Message.WParam := KeyFromScanCode(Event.Key.Keysym.ScanCode);
        Message.LParam := 1;
        if Event.Key.Repeated <> 0 then
          Message.LParam := Message.LParam or (1 shl 30);
        if Message.WParam <> 0 then
          Exit;
      end;
      SDL_TEXTINPUT:
      begin
        // The game consumes UTF-16 code units; SDL commits UTF-8 text.
        TextInput := UTF8Decode(PAnsiChar(@Event.Text.Text[0]));
        TextPosition := 1;
      end;
      SDL_MOUSEMOTION:
      begin
        if Event.Motion.Which = SDL_TOUCH_MOUSEID then
          Continue;
        TouchMouseActive := False;
        if (Event.Motion.XRel <> 0) or (Event.Motion.YRel <> 0) then
          PointerCursorActive := True;
        Message.Message := WM_MOUSEMOVE;
        Message.WParam := MouseKeys(CombinedMouseState(Event.Motion.State));
        Point := Types.Point(Event.Motion.X, Event.Motion.Y);
        if GameWindowUsesNativeRaster then
          Point := WindowPoint(Point.X, Point.Y);
        Message.LParam := PackGamePoint(Point.X, Point.Y);
        Exit;
      end;
      SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
      begin
        if Event.Button.Which = SDL_TOUCH_MOUSEID then
          Continue;
        TouchMouseActive := False;
        PointerCursorActive := True;
        case Event.Button.Button of
          1: Message.Message := WM_LBUTTONDOWN;
          2: Message.Message := WM_MBUTTONDOWN;
          3: Message.Message := WM_RBUTTONDOWN;
        else
          Continue;
        end;
        if Event.Kind = SDL_MOUSEBUTTONUP then
          Inc(Message.Message)
        else if Event.Button.Clicks = 2 then
          Inc(Message.Message, 2);
        Message.WParam := MouseKeys(GameMouseState(nil, nil));
        Point := Types.Point(Event.Button.X, Event.Button.Y);
        if GameWindowUsesNativeRaster then
          Point := WindowPoint(Point.X, Point.Y);
        Message.LParam := PackGamePoint(Point.X, Point.Y);
        Exit;
      end;
      SDL_MOUSEWHEEL:
      begin
        Amount := Event.Wheel.PreciseY;
        if Amount = 0 then
          Amount := Event.Wheel.Y;
        if IsNan(Amount) or IsInfinite(Amount) then
          Continue;
        // SDL already applied the user's natural-scroll preference.
        WheelRemainder := WheelRemainder + Amount;
        WheelMessage.Message := WM_MOUSEWHEEL;
        WheelMessage.WParam := MouseKeys(GameMouseState(@X, @Y));
        Point := Types.Point(Event.Wheel.MouseX, Event.Wheel.MouseY);
        if GameWindowUsesNativeRaster then
          Point := WindowPoint(Point.X, Point.Y);
        WheelMessage.LParam := PackGamePoint(Point.X, Point.Y);
      end;
      SDL_FINGERDOWN, SDL_FINGERMOTION, SDL_FINGERUP:
      begin
        if AppInBackground or (Event.Finger.TouchID = SDL_MOUSE_TOUCHID) then
          Continue;
        // Indirect trackpads already provide cursor/wheel events. Consuming
        // their raw contacts as touchscreen taps would produce duplicate clicks.
        if SDL_GetTouchDeviceType(Event.Finger.TouchID) <> SDL_TOUCH_DEVICE_DIRECT then
          Continue;
        Phase := tpMove;
        if Event.Kind = SDL_FINGERDOWN then
          Phase := tpDown
        else if Event.Kind = SDL_FINGERUP then
          Phase := tpUp;
        if GameWindowUsesNativeRaster then
        begin
          // With SDL's logical-size transform disabled, fingers are normalized
          // to the complete output. Use exactly the integer destination used by
          // presentation, including any intentional aspect-ratio letterbox.
          Presentation := CalculateGamePresentation(GetGameDisplayMetrics, LogicalWidth, LogicalHeight);
          Presentation.OutputToLogical(
              Event.Finger.X * Presentation.Metrics.OutputSize.X,
              Event.Finger.Y * Presentation.Metrics.OutputSize.Y,
              FingerX,
              FingerY
          );
          Scale := Presentation.PixelScale;
        end
        else
        begin
          // Desktop SDL still transforms normalized fingers into logical space.
          FingerX := Event.Finger.X * LogicalWidth;
          FingerY := Event.Finger.Y * LogicalHeight;
          WindowTransform(Scale, OffsetX, OffsetY);
        end;
        // Reject contacts that begin outside the displayed game, but retain
        // their move/up events so dragging out of the view still releases it.
        // SDL clamps desktop/browser letterbox contacts to the normalized edge;
        // their original position is lost. Do not turn those into edge clicks.
        if (Phase = tpDown) and not GameWindowUsesNativeRaster and ((FingerX <= 0) or (FingerY <= 0)) then
          Continue;
        if (Phase = tpDown) and ((FingerX < 0) or (FingerX >= LogicalWidth) or (FingerY < 0) or (FingerY >= LogicalHeight)) then
          Continue;
        PointerCursorActive := False;
{$IFDEF SWITCH}
        // Resume stick control from the last touch, without generating a
        // synthetic mouse event that would reveal the cursor again.
        SwitchTouchPosition(
            Round(Event.Finger.X * Presentation.Metrics.WindowSize.X),
            Round(Event.Finger.Y * Presentation.Metrics.WindowSize.Y)
        );
{$ENDIF}
        Touch.Feed(
            Phase,
            Event.Finger.TouchID,
            Event.Finger.FingerID,
            FingerX,
            FingerY,
            Max(4, TouchSlop / Scale),
            TouchMode,
            Event.Finger.Timestamp,
            GameDoubleClickTime
        );
      end;
    end;
  until False;
  if GetTickCount64 - LastTimerTick >= 100 then
  begin
    LastTimerTick := GetTickCount64;
    Message.Message := WM_TIMER;
    Message.WParam := 1;
    Exit;
  end;
  Result := False;
end;

function PostGameMessage(Message, WParam: Cardinal; LParam: Integer): Boolean;
var
  Event: TSDL_Event;
begin
  Event := Default(TSDL_Event);
  Event.Kind := PostedMessageType;
  Event.User.Code := Integer(Message);
  Event.User.Data1 := Pointer(PtrUInt(WParam));
  Event.User.Data2 := Pointer(PtrInt(LParam));
  Result := SDL_PushEvent(Event) = 1;
end;

function GameWindowFocused: Boolean;
begin
  Result := (GameSDLWindow <> nil) and not AppInBackground and (SDL_GetWindowFlags(GameSDLWindow) and SDL_WINDOW_INPUT_FOCUS <> 0);
end;

function GameKeyState(Key: Integer): SmallInt;
var
  Keys: PByte;
{$IFDEF SWITCH}
  ControllerKeys: PByte;
{$ENDIF}
  Count, Index, Mask: Integer;
begin
  Result := 0;
  if AppInBackground then
    Exit;
  if Key in [1, 2, 4] then
  begin
    Mask := 1;
    if Key = 2 then
      Mask := 4
    else if Key = 4 then
      Mask := 2;
    if GameMouseState(nil, nil) and Cardinal(Mask) <> 0 then
      Result := -32768;
    Exit;
  end;
  Keys := SDL_GetKeyboardState(@Count);
{$IFDEF SWITCH}
  ControllerKeys := SwitchKeyboardState;
{$ENDIF}
  for Index := 0 to Count - 1 do
    if ((Keys[Index] <> 0)
{$IFDEF SWITCH}
            or (ControllerKeys[Index] <> 0)
{$ENDIF}
        )
        and (KeyFromScanCode(Index) = Cardinal(Key)) then
      Exit(-32768);
end;

function GameDoubleClickTime: Cardinal;
var
  Value: PAnsiChar;
begin
  Value := SDL_GetHint('SDL_MOUSE_DOUBLE_CLICK_TIME');
  Result := 500;
  if Value <> nil then
    Result := StrToIntDef(string(Value), 500);
end;

procedure GetGameMouse(out Point: TPoint);
var
  X, Y, WindowX, WindowY: Integer;
begin
  if TouchMouseActive then
  begin
    Point := TouchMouse;
    Exit;
  end;
  if (GameSDLWindow <> nil) and DesktopMouseAvailable then
  begin
    // The original GetCursorPos + ScreenToClient also works outside the window.
    // SDL_GetMouseState stays at its last (clamped) position on mouse leave,
    // which would leave the software cursor painted along the window edge.
    SDL_GetGlobalMouseState(@X, @Y);
    SDL_GetWindowPosition(GameSDLWindow, WindowX, WindowY);
    Dec(X, WindowX);
    Dec(Y, WindowY);
  end
  else if (GameSDLWindow <> nil) and (SDL_GetMouseFocus <> GameSDLWindow) then
  begin
    // Without desktop coordinates, only the fact that the mouse is outside is
    // known. Keep its software image and hover hit tests outside the game too.
    Point := Types.Point(Low(SmallInt), Low(SmallInt));
    Exit;
  end
  else
    GameMouseState(@X, @Y);
  if GameSDLRenderer = nil then
  begin
    Point := Types.Point(X, Y);
    Exit;
  end;
  Point := WindowPoint(X, Y);
end;

function GameMouseInWindow: Boolean;
begin
  Result := GameWindowFocused and (TouchMouseActive or (SDL_GetMouseFocus = GameSDLWindow));
end;

function GamePointerAllowsEdgeScroll: Boolean;
begin
  // Android uses explicit panning, including when a mouse is connected.
  // Elsewhere, a released finger must not act as a parked desktop cursor.
  Result := not GameWindowIsMobile and GamePointerCursorVisible and not TouchMouseActive;
end;

procedure WarpGameMouse(X, Y: Integer);
var
  OffsetX, OffsetY: Integer;
  Scale: Double;
  Presentation: TGamePresentation;
  Point: TPoint;
begin
  if TouchMouseActive then
  begin
    TouchMouse := Types.Point(X, Y);
    Exit;
  end;
  if GameSDLRenderer = nil then
    Exit;
  if GameWindowUsesNativeRaster then
  begin
    Presentation := CalculateGamePresentation(GetGameDisplayMetrics, LogicalWidth, LogicalHeight);
    Point := Presentation.LogicalToWindow(X, Y);
    SDL_WarpMouseInWindow(GameSDLWindow, Point.X, Point.Y);
    Exit;
  end;
  WindowTransform(Scale, OffsetX, OffsetY);
  SDL_WarpMouseInWindow(GameSDLWindow, Round(X * Scale) + OffsetX, Round(Y * Scale) + OffsetY);
end;

function ShowGameCursor(Show: Boolean): Integer;
begin
  if Show then
    Inc(CursorCount)
  else
    Dec(CursorCount);
  SDL_ShowCursor(Ord(CursorCount >= 0));
  Result := CursorCount;
end;

procedure SetGameWindowTitle(const Title: UnicodeString);
begin
  SDL_SetWindowTitle(GameSDLWindow, PAnsiChar(UTF8Encode(Title)));
end;

procedure MinimizeGameWindow;
begin
  SDL_MinimizeWindow(GameSDLWindow);
end;

function OpenGameURL(const URL: UnicodeString): Boolean;
var
  Target: UTF8String;
begin
  // Local documents need normalized paths and URI escaping, especially for
  // mod directories containing spaces or the game's backslash separators.
  Target := UTF8Encode(URL);
  if Pos('://', Target) = 0 then
    Target := FilenameToURI(UTF8Encode(ExpandFileName(NativeGamePath(URL))));
  // Opening an external document is optional platform functionality. Failure
  // must not unwind the current game session (Switch has no URL handler).
  Result := SDL_OpenURL(PAnsiChar(Target)) = 0;
end;

function GetGameClipboard: UnicodeString;
var
  Text: PAnsiChar;
begin
  Text := SDL_GetClipboardText;
  try
    Result := UTF8Decode(Text);
  finally
    SDL_free(Text);
  end;
end;

procedure SetGameClipboard(const Text: UnicodeString);
begin
  CheckGameSDL(SDL_SetClipboardText(PAnsiChar(UTF8Encode(Text))), 'SDL_SetClipboardText');
end;

procedure DiscardGameTextCharacter;
var
  Event: TSDL_Event;
begin
  // Opening encyclopedia search with I must not insert that hotkey into the edit.
  // Remove one UTF-16 character, retaining any remainder of an SDL text commit.
  if (TextPosition > 0) and (TextPosition <= Length(TextInput)) then
  begin
    Inc(TextPosition);
    Exit;
  end;
  if HasPendingEvent and (PendingEvent.Kind = SDL_TEXTINPUT) then
  begin
    Event := PendingEvent;
    HasPendingEvent := False;
  end
  else if SDL_PeepEvents(@Event, 1, 2, SDL_TEXTINPUT, SDL_TEXTINPUT) <> 1 then
    Exit;
  TextInput := UTF8Decode(PAnsiChar(@Event.Text.Text[0]));
  TextPosition := 2;
end;

function GameMessagesPending: Boolean;
begin
  Result :=
      HasPendingEvent
          or HasPendingActivation
          or HasPendingDisplayChange
          or ((Touch <> nil) and Touch.Pending)
          or (TextPosition > 0) and (TextPosition <= Length(TextInput))
          or (Abs(WheelRemainder) >= 1)
          or (SDL_HasEvents(0, $FFFF) <> 0);
end;

procedure WaitGameMessages(Timeout: Cardinal);
begin
  if GameMessagesPending then
    Exit;
  // Waiting must not consume an input message; deliver it in the next UI pump.
  HasPendingEvent := SDL_WaitEventTimeout(PendingEvent, Min(Timeout, Cardinal(High(Integer)))) = 1;
end;

function GameMessageBox(const Text, Title: UnicodeString; Options: Cardinal): Integer;
var
  Data: TSDL_MessageBoxData;
  Buttons: array[0..1] of TSDL_MessageBoxButton;
  TextUtf8, TitleUtf8: UTF8String;
begin
  TextUtf8 := UTF8Encode(Text);
  TitleUtf8 := UTF8Encode(Title);
  Data := Default(TSDL_MessageBoxData);
  FillChar(Buttons, SizeOf(Buttons), 0);
  Data.Flags := $40;
  if Options and $10 <> 0 then
    Data.Flags := $10;
  Data.Window := GameSDLWindow;
  Data.Title := PAnsiChar(TitleUtf8);
  Data.Message := PAnsiChar(TextUtf8);
  Buttons[0].Flags := 1;
  Buttons[0].ID := 1;
  Buttons[0].Text := 'OK';
  Buttons[1].Flags := 2;
  Buttons[1].ID := 2;
  Buttons[1].Text := 'Cancel';
  Data.ButtonCount := 1;
  if Options and $F <> 0 then
    Data.ButtonCount := 2;
  if Options and $F = 4 then
  begin
    Buttons[0].ID := 6;
    Buttons[0].Text := 'Yes';
    Buttons[1].ID := 7;
    Buttons[1].Text := 'No';
  end;
  Data.Buttons := @Buttons;
  CheckGameSDL(SDL_ShowMessageBox(Data, Result), 'SDL_ShowMessageBox');
  if Result < 0 then
    Result := Buttons[Data.ButtonCount - 1].ID;
end;

procedure ShowGameDialog(const Text: UnicodeString);
begin
  CheckGameSDL(SDL_ShowSimpleMessageBox($10, 'Space Rangers', PAnsiChar(UTF8Encode(Text)), GameSDLWindow), 'SDL_ShowSimpleMessageBox');
end;

finalization
  try
    CloseGameWindow;
  except
    LogCurrentGameException('video', 'Closing game window during shutdown');
  end;
  FreeAndNil(Touch);
  if VideoInitialized and not VideoFaulted then
  begin
    try
      SDL_DelEventWatch(WatchRendererReset, nil);
      SDL_QuitSubSystem(SDL_INIT_VIDEO or SDL_INIT_TIMER);
    except
      LogCurrentGameException('video', 'Shutting down SDL video');
    end;
  end;
end.
