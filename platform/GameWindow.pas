unit GameWindow;

{$MODE DELPHI}
{$POINTERMATH ON}

interface

uses
  Classes,
  Types,
  GameInput,
  SDL2;

procedure InitializeGameVideo;
function GameWindowUsesCanvas: Boolean;
procedure GetGameWindowLogicalSize(out Width, Height: Integer);
procedure OpenGameWindow(Width, Height: Integer; Windowed, VSync: Boolean);
procedure CloseGameWindow;
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
procedure OpenGameURL(const URL: UnicodeString);
function GetGameClipboard: UnicodeString;
procedure SetGameClipboard(const Text: UnicodeString);
procedure DiscardGameTextCharacter;
procedure WaitGameMessages(Timeout: Cardinal);
function GameMessageBox(const Text, Title: UnicodeString; Options: Cardinal): Integer;
procedure ShowGameDialog(const Text: UnicodeString);
function GameMessagesPending: Boolean;
procedure CancelGamePointerInput;

var
  OnGameActivated, OnGameDeactivated: TNotifyEvent;
  GameSDLWindow: PSDL_Window;
  GameSDLRenderer: PSDL_Renderer;
  GameTextureGeneration, GameTargetGeneration: LongInt;
  GamePresentedFrames: QWord;

implementation

uses
{$IFDEF DARWIN}
  GameCocoaCursor,
{$ENDIF}
  SysUtils,
  Math,
  GameTouch,
  GameSystem,
  URIParser;

var
  VideoInitialized: Boolean;
  DesktopMouseAvailable: Boolean;
  BrowserWindow: Boolean;
  MobileWindow, AppInBackground: Boolean;
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
  TouchMode: Integer;
  TouchSlop: Integer;
  HasPendingActivation: Boolean;
  PendingActivation: Cardinal;

procedure CheckSDL(Value: Integer);
begin
  if Value < 0 then
    raise Exception.Create(string(SDL_GetError));
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
  Result := 1;
end;

procedure RefreshGameCursor;
begin
  // Reapply visibility without changing the game's ShowCursor counter. SDL's
  // show/hide call is a no-op when it already records the requested state.
  SDL_ShowCursor(Ord(CursorCount >= 0));
  SDL_SetCursor(nil);
{$IFDEF DARWIN}
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
begin
  if VideoInitialized then
    Exit;
  // Native display drivers assume C's masked floating-point exceptions. Apply
  // the game's mask before SDL can initialize a driver (Metal may overflow
  // internal sampler calculations), rather than waiting for GR_DXInit.
  ClearExceptions(False);
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  SDL_SetMainReady;
  // Handle native fingers ourselves; synthesized mouse presses commit game
  // actions before the user can distinguish a tap from a drag.
  SDL_SetHint('SDL_TOUCH_MOUSE_EVENTS', '0');
  SDL_SetHint('SDL_MOUSE_TOUCH_EVENTS', '0');
{$IFDEF ANDROID}
  SDL_SetHint('SDL_ORIENTATIONS', 'LandscapeLeft LandscapeRight');
  SDL_SetHint('SDL_ANDROID_TRAP_BACK_BUTTON', '1');
  // Android's keyboard is opened explicitly by Controls > Keyboard. Keep this
  // policy in force during video initialization, window creation and resume;
  // restoring the default permits SDL to request an IME asynchronously.
  SDL_SetHint('SDL_ENABLE_SCREEN_KEYBOARD', '0');
{$ENDIF}
  CheckSDL(SDL_InitSubSystem(SDL_INIT_VIDEO or SDL_INIT_TIMER));
  // These desktop backends provide real global coordinates. Other backends
  // (notably Wayland) may return cached window coordinates from the same API.
  // SDL spells its Android backend "Android", unlike the lower-case desktop
  // names. Normalize before selecting mobile sizing and keyboard behavior.
  Driver := LowerCase(string(SDL_GetCurrentVideoDriver));
  DesktopMouseAvailable := (Driver = 'cocoa') or (Driver = 'windows') or (Driver = 'x11');
  BrowserWindow := Driver = 'emscripten';
  MobileWindow := Driver = 'android';
  TouchSlop := EnsureRange(StrToIntDef(string(SDL_GetHint('SRHD_TOUCH_SLOP')), 8), 1, 256);
  PostedMessageType := SDL_RegisterEvents(1);
  if PostedMessageType = Cardinal(-1) then
    raise Exception.Create('Registering game messages: ' + string(SDL_GetError));
  SDL_AddEventWatch(WatchRendererReset, nil);
  Touch := TGameTouch.Create;
  VideoInitialized := True;
end;

function GameWindowUsesCanvas: Boolean;
begin
  InitializeGameVideo;
  Result := BrowserWindow;
end;

procedure GetGameWindowLogicalSize(out Width, Height: Integer);
begin
  Width := LogicalWidth;
  Height := LogicalHeight;
end;

procedure OpenGameWindow(Width, Height: Integer; Windowed, VSync: Boolean);
var
  Flags: Cardinal;
  PreviousTarget: PSDL_Texture;
  TargetGeneration: LongInt;
  Created: Boolean;
begin
  InitializeGameVideo;
  // The browser controls canvas size and fullscreen through CSS and user gestures.
  if BrowserWindow then
    Windowed := True;
  if MobileWindow then
    Windowed := False;
  TargetGeneration := GameTargetGeneration;
  LogicalWidth := Width;
  LogicalHeight := Height;
  Created := GameSDLWindow = nil;
  if Created then
  begin
    Flags := SDL_WINDOW_ALLOW_HIGHDPI;
    if BrowserWindow then
      Flags := Flags or SDL_WINDOW_RESIZABLE;
    GameSDLWindow :=
        SDL_CreateWindow(
            'Rangers',
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            Width,
            Height,
            Flags
        );
    if GameSDLWindow = nil then
      raise Exception.Create(string(SDL_GetError));
    Flags := SDL_RENDERER_ACCELERATED or SDL_RENDERER_TARGETTEXTURE;
    if VSync then
      Flags := Flags or SDL_RENDERER_PRESENTVSYNC;
    GameSDLRenderer := SDL_CreateRenderer(GameSDLWindow, -1, Flags);
    if GameSDLRenderer = nil then
      GameSDLRenderer :=
          SDL_CreateRenderer(
              GameSDLWindow,
              -1,
              SDL_RENDERER_SOFTWARE or SDL_RENDERER_TARGETTEXTURE
          );
    if GameSDLRenderer = nil then
    begin
      SDL_DestroyWindow(GameSDLWindow);
      GameSDLWindow := nil;
      raise Exception.Create(string(SDL_GetError));
    end;
    // Enable UTF-8 commits without calling SDL_StartTextInput on Android: that
    // API also requests the soft keyboard. The Java overlay opens it directly.
    if MobileWindow then
    begin
      SDL_EventState(SDL_TEXTINPUT, SDL_ENABLE);
      SDL_EventState(SDL_TEXTEDITING, SDL_ENABLE);
    end
    else
      SDL_StartTextInput;
  end;
  // SDL's browser resize handler follows the canvas CSS size. Keep the selected
  // game resolution in the renderer instead of replacing the canvas dimensions.
  if not BrowserWindow and not MobileWindow then
    SDL_SetWindowSize(GameSDLWindow, Width, Height);
  Flags := 0;
  if not Windowed then
    Flags := SDL_WINDOW_FULLSCREEN_DESKTOP;
  CheckSDL(SDL_SetWindowFullscreen(GameSDLWindow, Flags));
  // Configure the window view, not an offscreen texture's view. SDL then maps
  // mouse events and the presented frame to the same logical resolution,
  // including Retina pixels; disabling this leaves SDL2-compat events scaled.
  PreviousTarget := SDL_GetRenderTarget(GameSDLRenderer);
  if TargetGeneration <> GameTargetGeneration then
    PreviousTarget := nil;
  CheckSDL(SDL_SetRenderTarget(GameSDLRenderer, nil));
  try
    CheckSDL(SDL_RenderSetLogicalSize(GameSDLRenderer, Width, Height));
  finally
    CheckSDL(SDL_SetRenderTarget(GameSDLRenderer, PreviousTarget));
  end;
  CheckSDL(SDL_RenderSetVSync(GameSDLRenderer, Ord(VSync)));
  SDL_ShowCursor(Ord(CursorCount >= 0));
  if Created then
  begin
    // Wayland maps the window only after a buffer is presented. The game waits
    // for real focus before drawing its loading screen, so supply the first
    // buffer here to avoid waiting for focus on an invisible surface.
    CheckSDL(SDL_SetRenderDrawColor(GameSDLRenderer, 0, 0, 0, 255));
    CheckSDL(SDL_RenderClear(GameSDLRenderer));
    SDL_RenderPresent(GameSDLRenderer);
  end;
end;

procedure CloseGameWindow;
begin
  if GameSDLWindow <> nil then
    SDL_StopTextInput;
  SDL_DestroyRenderer(GameSDLRenderer);
  GameSDLRenderer := nil;
  SDL_DestroyWindow(GameSDLWindow);
  GameSDLWindow := nil;
  TextInput := '';
  TextPosition := 0;
  CancelGamePointerInput;
  TouchMouseActive := False;
  HasPendingActivation := False;
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
var
  Modifiers: Integer;
begin
  Result := 0;
  if State and 1 <> 0 then
    Result := Result or MK_LBUTTON;
  if State and 4 <> 0 then
    Result := Result or MK_RBUTTON;
  if State and 2 <> 0 then
    Result := Result or MK_MBUTTON;
  Modifiers := SDL_GetModState;
  if Modifiers and $3 <> 0 then
    Result := Result or MK_SHIFT;
  if Modifiers and $C0 <> 0 then
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
begin
  WindowTransform(Scale, OffsetX, OffsetY);
  Result := Types.Point(Floor((X - OffsetX) / Scale), Floor((Y - OffsetY) / Scale));
end;

function PollGameMessage(out Message: TGameMessage): Boolean;
var
  Event: TSDL_Event;
  Step, X, Y, OffsetX, OffsetY: Integer;
  Amount, Scale: Double;
  Point: TPoint;
  Phase: TTouchPhase;

  procedure CancelInput;
  begin
    CancelGamePointerInput;
    TextInput := '';
    TextPosition := 0;
    Message.Message := WM_GAME_CANCEL_INPUT;
  end;

begin
  Result := True;
  Message := Default(TGameMessage);
  repeat
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
      Message.WParam :=
          MouseKeys(SDL_GetMouseState(nil, nil)) or (Cardinal(Word(Step * WHEEL_DELTA)) shl 16);
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
            Message.WParam := MouseKeys(SDL_GetMouseState(nil, nil));
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
        Message.Message := WM_MOUSEMOVE;
        Message.WParam := MouseKeys(Event.Motion.State);
        Message.LParam := PackGamePoint(Event.Motion.X, Event.Motion.Y);
        Exit;
      end;
      SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
      begin
        if Event.Button.Which = SDL_TOUCH_MOUSEID then
          Continue;
        TouchMouseActive := False;
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
        Message.WParam := MouseKeys(SDL_GetMouseState(nil, nil));
        Message.LParam := PackGamePoint(Event.Button.X, Event.Button.Y);
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
        WheelMessage.WParam := MouseKeys(SDL_GetMouseState(@X, @Y));
        WheelMessage.LParam := PackGamePoint(Event.Wheel.MouseX, Event.Wheel.MouseY);
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
        // SDL2 clamps letterbox touches to the normalized edges. Reject initial
        // contacts there, including SDL backends that retain outside coordinates.
        if (Phase = tpDown)
            and ((Event.Finger.X <= 0)
                or (Event.Finger.X >= 1)
                or (Event.Finger.Y <= 0)
                or (Event.Finger.Y >= 1)) then
          Continue;
        WindowTransform(Scale, OffsetX, OffsetY);
        // SDL's renderer already maps normalized finger events into its logical
        // viewport, just as it scales queued mouse events.
        Touch.Feed(
            Phase,
            Event.Finger.TouchID,
            Event.Finger.FingerID,
            Event.Finger.X * LogicalWidth,
            Event.Finger.Y * LogicalHeight,
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
  Result :=
      (GameSDLWindow <> nil)
          and not AppInBackground
          and (SDL_GetWindowFlags(GameSDLWindow) and SDL_WINDOW_INPUT_FOCUS <> 0);
end;

function GameKeyState(Key: Integer): SmallInt;
var
  Keys: PByte;
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
    if SDL_GetMouseState(nil, nil) and Cardinal(Mask) <> 0 then
      Result := -32768;
    Exit;
  end;
  Keys := SDL_GetKeyboardState(@Count);
  for Index := 0 to Count - 1 do
    if (Keys[Index] <> 0) and (KeyFromScanCode(Index) = Cardinal(Key)) then
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
    SDL_GetMouseState(@X, @Y);
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
  // A released finger leaves a hover location, not a parked desktop cursor.
  // Touch panning is explicit; an edge tap must never start perpetual motion.
  Result := not TouchMouseActive;
end;

procedure WarpGameMouse(X, Y: Integer);
var
  OffsetX, OffsetY: Integer;
  Scale: Double;
begin
  if TouchMouseActive then
  begin
    TouchMouse := Types.Point(X, Y);
    Exit;
  end;
  if GameSDLRenderer = nil then
    Exit;
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

procedure OpenGameURL(const URL: UnicodeString);
var
  Target: UTF8String;
begin
  // Local documents need normalized paths and URI escaping, especially for
  // mod directories containing spaces or the game's backslash separators.
  Target := UTF8Encode(URL);
  if Pos('://', Target) = 0 then
    Target := FilenameToURI(UTF8Encode(ExpandFileName(NativeGamePath(URL))));
  CheckSDL(SDL_OpenURL(PAnsiChar(Target)));
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
  CheckSDL(SDL_SetClipboardText(PAnsiChar(UTF8Encode(Text))));
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
  CheckSDL(SDL_ShowMessageBox(Data, Result));
  if Result < 0 then
    Result := Buttons[Data.ButtonCount - 1].ID;
end;

procedure ShowGameDialog(const Text: UnicodeString);
begin
  CheckSDL(
      SDL_ShowSimpleMessageBox($10, 'Space Rangers', PAnsiChar(UTF8Encode(Text)), GameSDLWindow)
  );
end;

finalization
  CloseGameWindow;
  FreeAndNil(Touch);
  if VideoInitialized then
  begin
    SDL_DelEventWatch(WatchRendererReset, nil);
    SDL_QuitSubSystem(SDL_INIT_VIDEO or SDL_INIT_TIMER);
  end;
end.
