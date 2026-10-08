unit SDL2;

{$MODE DELPHI}
{$PACKRECORDS C}

// SDL is a C API. Native alignment and cdecl apply equally to 32- and 64-bit hosts.
{$IFDEF UNIX}
  {$LINKLIB SDL2}
{$ENDIF}

interface

const
{$IFDEF WASI}
  // Static C objects use the default WebAssembly import namespace.
  SDL2Library = 'env';
{$ELSEIF Defined(MSWINDOWS)}
  SDL2Library = 'SDL2.dll';
{$ELSE}
  SDL2Library = 'SDL2';
{$ENDIF}
  SDL_INIT_TIMER = $00000001;
  SDL_INIT_AUDIO = $00000010;
  SDL_INIT_VIDEO = $00000020;
  SDL_WINDOW_SHOWN = $00000004;
  SDL_WINDOW_RESIZABLE = $00000020;
  SDL_WINDOW_ALLOW_HIGHDPI = $00002000;
  SDL_WINDOW_FULLSCREEN_DESKTOP = $00001001;
  SDL_WINDOW_INPUT_FOCUS = $00000200;
  SDL_WINDOWPOS_CENTERED = $2FFF0000;
  SDL_RENDERER_SOFTWARE = 1;
  SDL_RENDERER_ACCELERATED = 2;
  SDL_RENDERER_PRESENTVSYNC = 4;
  SDL_RENDERER_TARGETTEXTURE = 8;
  SDL_TEXTUREACCESS_STATIC = 0;
  SDL_TEXTUREACCESS_STREAMING = 1;
  SDL_TEXTUREACCESS_TARGET = 2;
  SDL_PIXELFORMAT_RGB565 = $15151002;
  SDL_PIXELFORMAT_ARGB8888 = $16362004;
  SDL_PIXELFORMAT_XRGB8888 = $16161804;
  SDL_BLENDMODE_NONE = 0;
  SDL_BLENDMODE_BLEND = 1;
  SDL_ScaleModeNearest = 0;
  SDL_ScaleModeLinear = 1;
  SDL_QUIT_EVENT = $100;
  SDL_WINDOWEVENT = $200;
  SDL_KEYDOWN = $300;
  SDL_KEYUP = $301;
  SDL_TEXTINPUT = $303;
  SDL_MOUSEMOTION = $400;
  SDL_MOUSEBUTTONDOWN = $401;
  SDL_MOUSEBUTTONUP = $402;
  SDL_MOUSEWHEEL = $403;
  SDL_RENDER_TARGETS_RESET = $2000;
  SDL_RENDER_DEVICE_RESET = $2001;
  SDL_USEREVENT = $8000;
  SDL_MUTEX_TIMEDOUT = 1;
  SDL_MUTEX_MAXWAIT = Cardinal($FFFFFFFF);
  AUDIO_F32SYS = $8120;

type
  PSDL_Window = Pointer;
  PSDL_Renderer = Pointer;
  PSDL_Texture = Pointer;
  PSDL_Mutex = Pointer;
  PSDL_Cond = Pointer;
  TSDL_Rect = record
    X, Y, W, H: Integer;
  end;
  PSDL_Rect = ^TSDL_Rect;
  TSDL_FPoint = record
    X, Y: Single;
  end;
  TSDL_Color = record
    R, G, B, A: Byte;
  end;
  TSDL_Vertex = record
    Position: TSDL_FPoint;
    Color: TSDL_Color;
    TexCoord: TSDL_FPoint;
  end;
  TSDL_RendererInfo = record
    Name: PAnsiChar;
    Flags, FormatCount: Cardinal;
    Formats: array[0..15] of Cardinal;
    MaxTextureWidth, MaxTextureHeight: Integer;
  end;
  TSDL_DisplayMode = record
    Format: Cardinal;
    W, H, RefreshRate: Integer;
    DriverData: Pointer;
  end;
  TSDL_Keysym = record
    ScanCode, Sym: Integer;
    Modifiers: Word;
    Unused: Cardinal;
  end;
  TSDL_KeyboardEvent = record
    Kind, Timestamp, WindowID: Cardinal;
    State, Repeated, Padding2, Padding3: Byte;
    Keysym: TSDL_Keysym;
  end;
  TSDL_TextInputEvent = record
    Kind, Timestamp, WindowID: Cardinal;
    Text: array[0..31] of AnsiChar;
  end;
  TSDL_WindowEvent = record
    Kind, Timestamp, WindowID: Cardinal;
    Event, Padding1, Padding2, Padding3: Byte;
    Data1, Data2: Integer;
  end;
  TSDL_MouseMotionEvent = record
    Kind, Timestamp, WindowID, Which, State: Cardinal;
    X, Y, XRel, YRel: Integer;
  end;
  TSDL_MouseButtonEvent = record
    Kind, Timestamp, WindowID, Which: Cardinal;
    Button, State, Clicks, Padding: Byte;
    X, Y: Integer;
  end;
  TSDL_MouseWheelEvent = record
    Kind, Timestamp, WindowID, Which: Cardinal;
    X, Y: Integer;
    Direction: Cardinal;
    PreciseX, PreciseY: Single;
    MouseX, MouseY: Integer;
  end;
  TSDL_UserEvent = record
    Kind, Timestamp, WindowID: Cardinal;
    Code: Integer;
    Data1, Data2: Pointer;
  end;
  TSDL_Event = record
  case Integer of
    0: (Kind: Cardinal);
    1: (Key: TSDL_KeyboardEvent);
    2: (Text: TSDL_TextInputEvent);
    3: (Window: TSDL_WindowEvent);
    4: (Motion: TSDL_MouseMotionEvent);
    5: (Button: TSDL_MouseButtonEvent);
    6: (Wheel: TSDL_MouseWheelEvent);
    7: (User: TSDL_UserEvent);
    8: (Padding: array[0..6] of QWord);
  end;
  PSDL_Event = ^TSDL_Event;
  TSDL_EventFilter = function(UserData: Pointer; Event: PSDL_Event): Integer; cdecl;
  TSDL_AudioCallback = procedure(UserData: Pointer; Stream: PByte; Length: Integer); cdecl;
  TSDL_AudioSpec = record
    Frequency: Integer;
    Format: Word;
    Channels, Silence: Byte;
    Samples, Padding: Word;
    Size: Cardinal;
    Callback: TSDL_AudioCallback;
    UserData: Pointer;
  end;
  PSDL_AudioSpec = ^TSDL_AudioSpec;
  TSDL_MessageBoxButton = record
    Flags: Cardinal;
    ID: Integer;
    Text: PAnsiChar;
  end;
  TSDL_MessageBoxData = record
    Flags: Cardinal;
    Window: PSDL_Window;
    Title, Message: PAnsiChar;
    ButtonCount: Integer;
    Buttons: Pointer;
    ColorScheme: Pointer;
  end;

function SDL_GetRendererInfo(
    Renderer: PSDL_Renderer;
    out Info: TSDL_RendererInfo
): Integer; cdecl; external SDL2Library;
function SDL_GetNumRenderDrivers: Integer; cdecl; external SDL2Library;
function SDL_GetRenderDriverInfo(
    Index: Integer;
    out Info: TSDL_RendererInfo
): Integer; cdecl; external SDL2Library;
procedure SDL_SetMainReady; cdecl; external SDL2Library;
function SDL_InitSubSystem(Flags: Cardinal): Integer; cdecl; external SDL2Library;
procedure SDL_QuitSubSystem(Flags: Cardinal); cdecl; external SDL2Library;
function SDL_GetError: PAnsiChar; cdecl; external SDL2Library;
function SDL_GetHint(Name: PAnsiChar): PAnsiChar; cdecl; external SDL2Library;
function SDL_GetPerformanceFrequency: QWord; cdecl; external SDL2Library;
function SDL_GetCPUCount: Integer; cdecl; external SDL2Library;
function SDL_GetSystemRAM: Integer; cdecl; external SDL2Library;
procedure SDL_free(Data: Pointer); cdecl; external SDL2Library;
function SDL_CreateMutex: PSDL_Mutex; cdecl; external SDL2Library;
procedure SDL_DestroyMutex(Mutex: PSDL_Mutex); cdecl; external SDL2Library;
function SDL_LockMutex(Mutex: PSDL_Mutex): Integer; cdecl; external SDL2Library;
function SDL_UnlockMutex(Mutex: PSDL_Mutex): Integer; cdecl; external SDL2Library;
function SDL_CreateCond: PSDL_Cond; cdecl; external SDL2Library;
procedure SDL_DestroyCond(Cond: PSDL_Cond); cdecl; external SDL2Library;
function SDL_CondBroadcast(Cond: PSDL_Cond): Integer; cdecl; external SDL2Library;
function SDL_CondWaitTimeout(
    Cond: PSDL_Cond;
    Mutex: PSDL_Mutex;
    Timeout: Cardinal
): Integer; cdecl; external SDL2Library;
function SDL_CreateWindow(
    Title: PAnsiChar;
    X, Y, W, H: Integer;
    Flags: Cardinal
): PSDL_Window; cdecl; external SDL2Library;
procedure SDL_DestroyWindow(Window: PSDL_Window); cdecl; external SDL2Library;
function SDL_GetCurrentVideoDriver: PAnsiChar; cdecl; external SDL2Library;
function SDL_GetWindowFlags(Window: PSDL_Window): Cardinal; cdecl; external SDL2Library;
procedure SDL_SetWindowTitle(Window: PSDL_Window; Title: PAnsiChar); cdecl; external SDL2Library;
procedure SDL_SetWindowPosition(Window: PSDL_Window; X, Y: Integer); cdecl; external SDL2Library;
procedure SDL_GetWindowPosition(
    Window: PSDL_Window;
    out X, Y: Integer
); cdecl; external SDL2Library;
procedure SDL_SetWindowBordered(
    Window: PSDL_Window;
    Bordered: Integer
); cdecl; external SDL2Library;
procedure SDL_SetWindowSize(Window: PSDL_Window; W, H: Integer); cdecl; external SDL2Library;
procedure SDL_GetWindowSize(Window: PSDL_Window; out W, H: Integer); cdecl; external SDL2Library;
procedure SDL_GetWindowSizeInPixels(
    Window: PSDL_Window;
    out W, H: Integer
); cdecl; external SDL2Library;
function SDL_SetWindowFullscreen(
    Window: PSDL_Window;
    Flags: Cardinal
): Integer; cdecl; external SDL2Library;
procedure SDL_RaiseWindow(Window: PSDL_Window); cdecl; external SDL2Library;
procedure SDL_SetWindowGrab(Window: PSDL_Window; Grabbed: Integer); cdecl; external SDL2Library;
procedure SDL_MinimizeWindow(Window: PSDL_Window); cdecl; external SDL2Library;
function SDL_GetNumDisplayModes(Display: Integer): Integer; cdecl; external SDL2Library;
function SDL_GetDisplayUsableBounds(
    Display: Integer;
    out Bounds: TSDL_Rect
): Integer; cdecl; external SDL2Library;
function SDL_GetDisplayDPI(
    Display: Integer;
    Diagonal, Horizontal, Vertical: PSingle
): Integer; cdecl; external SDL2Library;
function SDL_GetDisplayMode(
    Display, Mode: Integer;
    out Value: TSDL_DisplayMode
): Integer; cdecl; external SDL2Library;
function SDL_GetCurrentDisplayMode(
    Display: Integer;
    out Value: TSDL_DisplayMode
): Integer; cdecl; external SDL2Library;
function SDL_CreateRenderer(
    Window: PSDL_Window;
    Index: Integer;
    Flags: Cardinal
): PSDL_Renderer; cdecl; external SDL2Library;
procedure SDL_DestroyRenderer(Renderer: PSDL_Renderer); cdecl; external SDL2Library;
function SDL_RenderSetLogicalSize(
    Renderer: PSDL_Renderer;
    W, H: Integer
): Integer; cdecl; external SDL2Library;
function SDL_RenderSetVSync(
    Renderer: PSDL_Renderer;
    VSync: Integer
): Integer; cdecl; external SDL2Library;
function SDL_CreateTexture(
    Renderer: PSDL_Renderer;
    Format: Cardinal;
    Access, W, H: Integer
): PSDL_Texture; cdecl; external SDL2Library;
procedure SDL_DestroyTexture(Texture: PSDL_Texture); cdecl; external SDL2Library;
function SDL_UpdateTexture(
    Texture: PSDL_Texture;
    Rect: PSDL_Rect;
    Pixels: Pointer;
    Pitch: Integer
): Integer; cdecl; external SDL2Library;
function SDL_SetTextureBlendMode(
    Texture: PSDL_Texture;
    Mode: Integer
): Integer; cdecl; external SDL2Library;
function SDL_SetTextureScaleMode(
    Texture: PSDL_Texture;
    Mode: Integer
): Integer; cdecl; external SDL2Library;
function SDL_SetRenderTarget(
    Renderer: PSDL_Renderer;
    Texture: PSDL_Texture
): Integer; cdecl; external SDL2Library;
function SDL_GetRenderTarget(Renderer: PSDL_Renderer): PSDL_Texture; cdecl; external SDL2Library;
function SDL_RenderSetClipRect(
    Renderer: PSDL_Renderer;
    Rect: PSDL_Rect
): Integer; cdecl; external SDL2Library;
function SDL_SetRenderDrawColor(
    Renderer: PSDL_Renderer;
    R, G, B, A: Byte
): Integer; cdecl; external SDL2Library;
function SDL_SetRenderDrawBlendMode(
    Renderer: PSDL_Renderer;
    Mode: Integer
): Integer; cdecl; external SDL2Library;
function SDL_RenderClear(Renderer: PSDL_Renderer): Integer; cdecl; external SDL2Library;
function SDL_RenderFillRect(
    Renderer: PSDL_Renderer;
    Rect: PSDL_Rect
): Integer; cdecl; external SDL2Library;
function SDL_RenderCopy(
    Renderer: PSDL_Renderer;
    Texture: PSDL_Texture;
    Source, Dest: PSDL_Rect
): Integer; cdecl; external SDL2Library;
function SDL_RenderGeometry(
    Renderer: PSDL_Renderer;
    Texture: PSDL_Texture;
    Vertices: Pointer;
    VertexCount: Integer;
    Indices: PInteger;
    IndexCount: Integer
): Integer; cdecl; external SDL2Library;
function SDL_RenderDrawPointF(
    Renderer: PSDL_Renderer;
    X, Y: Single
): Integer; cdecl; external SDL2Library;
function SDL_RenderDrawLineF(
    Renderer: PSDL_Renderer;
    X1, Y1, X2, Y2: Single
): Integer; cdecl; external SDL2Library;
function SDL_RenderReadPixels(
    Renderer: PSDL_Renderer;
    Rect: PSDL_Rect;
    Format: Cardinal;
    Pixels: Pointer;
    Pitch: Integer
): Integer; cdecl; external SDL2Library;
function SDL_GetRendererOutputSize(
    Renderer: PSDL_Renderer;
    out Width, Height: Integer
): Integer; cdecl; external SDL2Library;
function SDL_RenderFlush(Renderer: PSDL_Renderer): Integer; cdecl; external SDL2Library;
procedure SDL_RenderPresent(Renderer: PSDL_Renderer); cdecl; external SDL2Library;
function SDL_ConvertPixels(
    W, H: Integer;
    SourceFormat: Cardinal;
    Source: Pointer;
    SourcePitch: Integer;
    DestFormat: Cardinal;
    Dest: Pointer;
    DestPitch: Integer
): Integer; cdecl; external SDL2Library;
function SDL_WaitEventTimeout(
    out Event: TSDL_Event;
    Timeout: Integer
): Integer; cdecl; external SDL2Library;
function SDL_PeepEvents(
    Events: PSDL_Event;
    Count, Action: Integer;
    Minimum, Maximum: Cardinal
): Integer; cdecl; external SDL2Library;
function SDL_PollEvent(out Event: TSDL_Event): Integer; cdecl; external SDL2Library;
function SDL_PushEvent(var Event: TSDL_Event): Integer; cdecl; external SDL2Library;
procedure SDL_AddEventWatch(
    Filter: TSDL_EventFilter;
    UserData: Pointer
); cdecl; external SDL2Library;
procedure SDL_DelEventWatch(
    Filter: TSDL_EventFilter;
    UserData: Pointer
); cdecl; external SDL2Library;
function SDL_HasEvents(MinKind, MaxKind: Cardinal): Integer; cdecl; external SDL2Library;
function SDL_RegisterEvents(Count: Integer): Cardinal; cdecl; external SDL2Library;
procedure SDL_StartTextInput; cdecl; external SDL2Library;
procedure SDL_StopTextInput; cdecl; external SDL2Library;
function SDL_GetKeyboardState(Count: PInteger): PByte; cdecl; external SDL2Library;
function SDL_GetModState: Integer; cdecl; external SDL2Library;
function SDL_GetMouseState(X, Y: PInteger): Cardinal; cdecl; external SDL2Library;
function SDL_GetGlobalMouseState(X, Y: PInteger): Cardinal; cdecl; external SDL2Library;
function SDL_GetMouseFocus: PSDL_Window; cdecl; external SDL2Library;
procedure SDL_WarpMouseInWindow(Window: PSDL_Window; X, Y: Integer); cdecl; external SDL2Library;
function SDL_CreateRGBSurfaceFrom(
    Pixels: Pointer;
    W, H, Depth, Pitch: Integer;
    RMask, GMask, BMask, AMask: Cardinal
): Pointer; cdecl; external SDL2Library;
procedure SDL_FreeSurface(Surface: Pointer); cdecl; external SDL2Library;
function SDL_CreateColorCursor(
    Surface: Pointer;
    HotX, HotY: Integer
): Pointer; cdecl; external SDL2Library;
procedure SDL_SetCursor(Cursor: Pointer); cdecl; external SDL2Library;
procedure SDL_FreeCursor(Cursor: Pointer); cdecl; external SDL2Library;
function SDL_ShowCursor(Visible: Integer): Integer; cdecl; external SDL2Library;
function SDL_GetClipboardText: PAnsiChar; cdecl; external SDL2Library;
function SDL_SetClipboardText(Text: PAnsiChar): Integer; cdecl; external SDL2Library;
function SDL_ShowMessageBox(
    constref Data: TSDL_MessageBoxData;
    out Button: Integer
): Integer; cdecl; external SDL2Library;
function SDL_ShowSimpleMessageBox(
    Flags: Cardinal;
    Title, Message: PAnsiChar;
    Window: PSDL_Window
): Integer; cdecl; external SDL2Library;
function SDL_OpenURL(URL: PAnsiChar): Integer; cdecl; external SDL2Library;
{$IFDEF FPC_WASM_EMSCRIPTEN}
// Device construction and destruction share the browser callback's thread.
// SDL's common close frees its work buffer before unregistering that callback.
function SDL_OpenAudioDevice(
    Device: PAnsiChar;
    IsCapture: Integer;
    Desired, Obtained: PSDL_AudioSpec;
    AllowedChanges: Integer
): Cardinal; cdecl; external name 'sr_fpc_open_audio_device';
procedure SDL_CloseAudioDevice(Device: Cardinal); cdecl; external name 'sr_fpc_close_audio_device';
{$ELSE}
function SDL_OpenAudioDevice(
    Device: PAnsiChar;
    IsCapture: Integer;
    Desired, Obtained: PSDL_AudioSpec;
    AllowedChanges: Integer
): Cardinal; cdecl; external SDL2Library;
procedure SDL_CloseAudioDevice(Device: Cardinal); cdecl; external SDL2Library;
{$ENDIF}
procedure SDL_PauseAudioDevice(Device: Cardinal; Pause: Integer); cdecl; external SDL2Library;
{$IFDEF FPC_WASM_EMSCRIPTEN}
// SDL's Emscripten callback drains on the browser thread without a device lock.
// Serialize queue access there; the caller retains its PCM until this returns.
function SDL_QueueAudio(
    Device: Cardinal;
    Data: Pointer;
    Length: Cardinal
): Integer; cdecl; external name 'sr_fpc_queue_audio';
function SDL_GetQueuedAudioSize(
    Device: Cardinal
): Cardinal; cdecl; external name 'sr_fpc_queued_audio_size';
{$ELSE}
function SDL_QueueAudio(
    Device: Cardinal;
    Data: Pointer;
    Length: Cardinal
): Integer; cdecl; external SDL2Library;
function SDL_GetQueuedAudioSize(Device: Cardinal): Cardinal; cdecl; external SDL2Library;
{$ENDIF}

implementation

end.
