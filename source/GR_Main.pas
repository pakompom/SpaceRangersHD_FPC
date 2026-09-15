{$EXCESSPRECISION OFF}
unit GR_Main;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  RTLFileSystem,
  GR_Music,
  DirectSound,
  EC_Thread,
  GR_Sound,
  EC_Data,
  EC_OKGF,
  EC_Buf,
  GR_GraphBufPal,
  Direct3D9,
  EC_Cache,
  EC_BlockPar,
  EC_Str,
  GR_GraphBuf,
  SyncObjs,
  Classes,
  Types;
const
  RuntimeLogFileName = 'Rangers.log';
type
  TCursorUnit = class;
  TWindowMessageCallbackGR =
      procedure(Message: Cardinal; WParam: Cardinal; LParam: Integer) of object;
  TRuntimeCallbackGR = procedure;
  TDebugKeyCallbackGR = procedure(Key: Word);
  TTriangleRasterizer16 =
      procedure(
          Pixels: Pointer;
          Pitch: Integer;
          X1: Integer;
          Y1: Integer;
          Color1: Cardinal;
          X2: Integer;
          Y2: Integer;
          Color2: Cardinal;
          X3: Integer;
          Y3: Integer;
          Color3: Cardinal;
          Clip: PRect
      ); cdecl;
  TLineRasterizer16 =
      procedure(
          Pixels: Pointer;
          Pitch: Integer;
          X1: Integer;
          Y1: Integer;
          Color1: Cardinal;
          X2: Integer;
          Y2: Integer;
          Color2: Cardinal
      ); cdecl;

  TBlendPixel16 = procedure(Pixel: Pointer; Color: Word; Alpha: Byte); cdecl;

  TMemoryStatusEx = packed record
    Length: Cardinal;
    MemoryLoad: Cardinal;
    TotalPhys: UInt64;
    AvailPhys: UInt64;
    TotalPageFile: UInt64;
    AvailPageFile: UInt64;
    TotalVirtual: UInt64;
    AvailVirtual: UInt64;
    AvailExtendedVirtual: UInt64;
  end;
  TDisplayModeGR = packed record
    Width: Cardinal;
    Height: Cardinal;
    RefreshRate: Cardinal;
    Format: Cardinal;
  end;
  TCursorUnit = class(TObject)
    Prev: TCursorUnit;
    Next: TCursorUnit;
    Name: WideString;
    ImagePath: WideString;
    HotSpot: TPoint;
  end;

var
  RuntimeActive: Boolean;
  VSyncEnabled: Boolean;
  PathGrowEnabled: Boolean;
  ShowSystemMouse: Boolean;
  ScreenRenderBuffer: TGraphBufGR;
  RenderScratchBuffer: TGraphBufGR;
  AuxRenderBuffer: TGraphBufGR;
  SelectedLanguage: WideString;
  RequestedLanguage: WideString;
  AvailableLanguageCodes: WideString;
  OverrideGameUserDirectory: WideString;
  CurrentPixelFormat: TPixelFormatGR;
  GameScreenWidth: Integer;
  GameScreenHeight: Integer;
  PresentationWidth: Integer;
  PresentationHeight: Integer;
  ViewportOffset: TPoint;
  AlternateViewportEnabled: Boolean;
  GameScreenRect: TRect;
  PresentationRect: TRect;
  ScrollInteriorRect: TRect;
  MainWindowHandle: Cardinal;
  WideCaseTable: array of TWideCasePair;
function GlobalMemoryStatusEx(var Status: TMemoryStatusEx): LongBool; stdcall;
var
  InstallConfig: TBlockParEC;
  LanguageInstallConfig: TBlockParEC;
  UserSettingsConfig: TBlockParEC;
  MainDataConfig: TBlockParEC;
  LanguageDataConfig: TBlockParEC;
  UiStyleConfig: TBlockParEC;
  SelectedMods: WideString;
  SelectedModsDisplaySuffix: WideString;
  LoadedSaveModSet: WideString;
  SuppressModRetryPrompt: Boolean = False;
  SkipModsOnReload: Boolean = False;
  WindowedModeRequested: Boolean = False;
  ExitScreenLoop: Boolean = False;
  FullFrameRedrawRequested: Boolean = True;
  DisplayBrightness: Single = 0;
  DisplayContrast: Single = 0;
  RobotBrightness: Single = 0;
  RobotContrast: Single = 0;
  OffscreenFrameUpdated: Boolean = False;
  OffscreenLastPresentationTick: Cardinal = 0;
  InterfaceBlendPalette: Pointer = nil;
  RequestedRefreshRate: Integer = 0;
  PresentWithoutLimit: Boolean = False;
  DisableHardwareVertexProcessing: Boolean = False;
  DisableMultithreadFlag: Boolean = False;
  DisableTripleBuffer: Boolean = False;
  ModInstallConfigs: TList = nil;
  ModLanguageInstallConfigs: TList = nil;
  ApplyEditableSaveOnLoad: Boolean = False;
  EditableSaveFileName: WideString = '';
  PlatformCheckAnchor: Integer = -35753766;
  ModShipNameConfig: TBlockParEC = nil;
  ModRuinNameConfig: TBlockParEC = nil;
  NewGameSeedText: WideString = '';
  CacheLoadLoggingEnabled: Boolean = False;
  SoundManager: TSoundControl = nil;
  MusicManager: TMusicControl = nil;
  ShowFrameRate: Boolean = False;
  RecordingFrames: Boolean = False;
  RecordingFrameBuffers: TList = nil;
  FirstRegisteredCursor: TCursorUnit = nil;
  LastRegisteredCursor: TCursorUnit = nil;
  BuildVersionMismatch: Boolean = False;
  SessionLogLock: TCriticalSection = nil;
  DebugKeyCallback: TDebugKeyCallbackGR = nil;
  CustomCursorEnabled: Boolean = True;
  DirectXVersion: Cardinal = 0;
  RecordingFrameCount: Integer = 0;
  RecordingFrameInterval: Integer = 50;
  LastRecordingFrameTick: Cardinal = 0;
  UnknownPresentState: Integer = 0;
  LastMouseMessageTick: Cardinal = 0;
  RobotBattleActive: Boolean = False;
  ProcessorCoreCount: Integer = 1;
  Direct3D: IDirect3D9 = nil;
  Direct3DDevice: IDirect3DDevice9 = nil;
  OffscreenTexture: IDirect3DTexture9 = nil;
  OffscreenFillViewport: Boolean = False;
  UseDesktopDisplayMode: Boolean = False;
  GameDisplayModeCount: Integer = 0;
  SelectedGameDisplayMode: Integer = -1;
  SmallestGameDisplayMode: Integer = -1;
  UseAutomaticRobotDisplayMode: Boolean = False;
  RobotDisplayModeCount: Integer = 0;
  SelectedRobotDisplayMode: Integer = -1;
  AltResolutionSwitch: Boolean = False;
  LastPresentationTick: Cardinal = 0;
  PresentationFrameRate: Cardinal = 0;
  RuntimeWatchdog: TThreadEC = nil;
  PresentationDepth: Integer = 0;
  EditableSaveBlock: TBlockParEC;
  GameDataConfig: TBlockParEC;
  NewGameSettingsConfig: TBlockParEC;
  UiDepthConfig: TBlockParEC;
  CacheDataRoot: TDataEC;
  GlobalCache: TCacheEC;
  SessionLog: TextFile;
  SavePreviewGraph: TGraphBufGR;
  SecondarySavePreviewGraph: TGraphBufGR;
  PerformanceCounterFrequency: Int64;
  DebugCommandMessage: Cardinal;
  SuppressExceptionLogCopy: Boolean;
  BlendPixel16: TBlendPixel16;
  TriangleRasterizer16: TTriangleRasterizer16;
  LineRasterizer16: TLineRasterizer16;
  RuntimeExitCheckCallback1: procedure;
  RuntimeExitCheckCallback2: procedure;
  RuntimeStartupTick: Cardinal;
  MainRuntimeThreadId: Cardinal;
  DesktopDisplayMode: TDisplayModeGR;
  Direct3DPresentParameters: TD3DPresentParameters;
  PreviousPresentParameters: TD3DPresentParameters;
  GameDisplayModes: array of TDisplayModeGR;
  RobotDisplayModes: array of TDisplayModeGR;
  ExtraScreenWidth: Integer;
  ExtraScreenHeight: Integer;
  CachedGameUserDirectory: WideString = '';
procedure LogMemoryUsage;
function Ex_OKGF_MulTable256x256: Pointer;
function Ex_OKGF_DXVersion: Cardinal;
function BeginImageRead(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer
): POkgfReadContext;
function ReadImagePixels(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    BytesPerPixel: Integer
): Integer;
function BeginIndexedImageRead(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer;
    out PaletteCount: Integer;
    out BytesPerPixel: Integer
): POkgfReadContext;
function ReadIndexedImagePixels(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    Palette: PColorRGBA
): Integer;
function WritePngFile(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes: Integer;
    Width: Integer;
    Height: Integer;
    HasAlpha: Integer;
    SwapRedBlue: Integer
): Integer;
function WriteBmpFile(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes: Integer;
    BitsPerPixel: Integer;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    Width: Integer;
    Height: Integer
): Integer;
procedure Ex_OKGR_AlphaBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_TransAlphaBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_AlphaIndexed_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_AlphaIndexed_AlphaDraw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_TransBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_TransBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
procedure Ex_OKGR_TransBuf_HADrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
function Ex_OKGR_TransBuf_Build_WORD(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer;
    TransparentColor: Word
): Integer;
function Ex_OKGR_TransBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer;
procedure Ex_OKGR_TransAlphaBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
procedure Ex_OKGR_AlphaBuf_DrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
function Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer;
function Ex_OKGR_AlphaBuf_BuildFromRGBA(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer;
procedure Ex_OKGR_AlphaSimpleBuf_Draw_16(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_AlphaSimpleBufPalAlpha_Draw_16(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer;
    Palette: PColorRGBA
);
procedure Ex_OKGR_MaskBuf_DrawClip_DWORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Cardinal;
    constref Clip: TRect
);
procedure Ex_OKGR_MaskBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Word;
    constref Clip: TRect
);
procedure Ex_OKGR_TransBuf_FillAlphaClip_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Cardinal
);
procedure Ex_OKGR_TransBuf_FillAlphaClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Word
);
procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
);
procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
);
function Ex_OKGR_RotateBuf_Build(
    Width: Integer;
    Height: Integer;
    SourceWidth: Integer;
    SourceHeight: Integer;
    CenterX: Integer;
    CenterY: Integer
): Pointer;
procedure Ex_OKGR_RotateBuf_Free(Buffer: Pointer);
procedure Ex_OKGR_RotateBuf_Size(
    X: Integer;
    Y: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    var Bounds: TRect
);
procedure Ex_OKGR_RotateBuf_Draw_DWORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer
);
procedure Ex_OKGR_RotateBuf_Draw_BYTE(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    Angle: Byte;
    RotationMap: Pointer
);
procedure Ex_OKGR_RotateBuf_DrawTransClip_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    const Clip: TRect
);
function Ex_OKGR_LightBuf_Create(Width: Integer; Height: Integer): Pointer;
procedure Ex_OKGR_LightBuf_Destroy(Buffer: Pointer);
procedure Ex_OKGR_LightBuf_SetSme(Buffer: Pointer; X: Integer; Y: Integer);
procedure Ex_OKGR_LightBuf_Init(Buffer: Pointer; Value: Byte);
procedure Ex_OKGR_LightBuf_LoadFromPalBuf(
    Buffer: Pointer;
    Source: Pointer;
    Width: Integer;
    Height: Integer;
    Pitch: Integer;
    Palette: PColorRGBA
);
procedure Ex_OKGR_LightBuf_Rotate(
    Dest: Pointer;
    Source: Pointer;
    RotationMap: Pointer;
    Angle: Byte
);
function Ex_OKGR_Planet2_TemplBuild(
    Source: Pointer;
    Pitch: Integer;
    Height: Integer;
    TextureWidth: Integer;
    TextureHeight: Integer;
    var ByteCount: Integer
): Pointer;
procedure Ex_OKGR_Planet2_TemplDel(TemplateData: Pointer);
procedure Ex_OKGR_Planet2_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer
);
procedure Ex_OKGR_Planet2_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer;
    const Clip: TRect
);
procedure Ex_OKGR_Planet3_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer
);
procedure Ex_OKGR_Planet3_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer;
    const Clip: TRect
);
procedure Ex_OKGR_Planet4_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer
);
procedure Ex_OKGR_Planet4_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData: Pointer;
    Source: Pointer;
    SourcePitch: Integer;
    WidthMask: Integer;
    MapOffset: Integer;
    LightBuffer: Pointer;
    Palette: Pointer;
    X: Integer;
    Y: Integer;
    const Clip: TRect
);
procedure Ex_OKGR_Copy_XY_XY_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_PalCopy_XY_XY_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Palette: Pointer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_CopyTrans_XY_XY_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer;
    TransparentColor: Word
);
procedure Ex_OKGR_CopySingleBuf_XY_XY_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    DestX: Integer;
    DestY: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_HACopy_XY_XY_16(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_StretchGdi_WORD(
    Dest: Pointer;
    Width: Cardinal;
    Height: Cardinal;
    Source: Pointer;
    SourceWidth: Cardinal;
    SourceHeight: Cardinal
);
procedure Ex_OKGR_Fill_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Color: Word
);
procedure Ex_OKGF_ConvertRGBto565(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGF_Convert565toRGB(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGF_Convert565toBGR(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGF_Convert565toBGRA(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGF_Convert_8888to565(
    Dest: Pointer;
    DestPitch: Integer;
    DestX: Integer;
    DestY: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_ShrLight_16(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Shift: Integer
);
procedure Ex_OKGR_ShrLightMask_16(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure Ex_OKGR_Light_BYTE(
    Pixels: Pointer;
    PixelStride: Integer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Alpha: Byte
);
procedure Ex_OKGR_Circle_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
);
procedure Ex_OKGR_Circle_DrawClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
);
procedure Ex_OKGR_Circle_DrawFillClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
);
procedure Ex_OKGR_Circle_DrawFillClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
);
function Ex_OKGR_Line_Clip(
    var X1: Integer;
    var Y1: Integer;
    var X2: Integer;
    var Y2: Integer;
    const Clip: TRect
): Integer;
function Ex_OKGR_LineColor_Clip(
    var X1: Integer;
    var Y1: Integer;
    var Color1: Cardinal;
    var X2: Integer;
    var Y2: Integer;
    var Color2: Cardinal;
    const Clip: TRect
): Integer;
procedure Ex_OKGR_Line_Draw_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word
);
procedure Ex_OKGR_Line_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    constref Clip: TRect
);
function Ex_OKGR_Line_CopyToBuf_WORD(
    Dest: Pointer;
    Source: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer;
function Ex_OKGR_Line_CopyFromBuf_WORD(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer;
procedure Ex_OKGR_Line_DrawClip_Alpha_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    Alpha: Byte;
    constref Clip: TRect
);
procedure Ex_OKGR_AnimLine_Draw_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    Phase: Integer;
    constref Clip: TRect
);
procedure Ex_OKGR_AnimShadowLine_Draw_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    Phase: Integer;
    constref Clip: TRect;
    ShadowPixels: Pointer;
    ShadowPitch: Integer
);
procedure Ex_OKGR_Alpha64Trapezium_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    X3: Integer;
    X4: Integer;
    Color: Word;
    constref Clip: TRect
);
procedure Ex_OKGR_Alpha128Trapezium_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    X3: Integer;
    X4: Integer;
    Color: Word;
    constref Clip: TRect
);
procedure Ex_OKGR_FillTrapezium_DWORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    X2: Integer;
    Y1: Integer;
    X3: Integer;
    X4: Integer;
    Y2: Integer;
    Color: Cardinal;
    constref Clip: TRect
);
procedure Ex_OKGF_Rescale(
    Dest: Pointer;
    Width: Integer;
    Height: Integer;
    DestPitch: Integer;
    Source: Pointer;
    SourceWidth: Integer;
    SourceHeight: Integer;
    SourcePitch: Integer;
    BytesPerPixel: Integer;
    Filter: Integer
);
procedure Ex_OKGR_F5_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure Ex_OKGR_F6_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
procedure ApplyProcessAffinity;
procedure CheckRuntimeWatchdog;
procedure CreateStartupLogFile;
procedure InitializePlatformRuntimeAndMainWindow;
procedure LoadLanguageAndPackages;
procedure LoadSelectedModInstallBlocks;
procedure ResetInstalledPackageState;
procedure FinalizePlatformRuntime;
function HasWow64Support: Boolean;
procedure ApplyMainWindowGeometry;
procedure ShowAndFocusMainWindow;
procedure LoadDatConfigAndModOverrides;
procedure FreeDatConfigRoots;
procedure InitializeRuntimeAndSettings;
procedure FinalizeRuntimeAndSettings;
procedure EnumerateAndSelectDisplayModes;
procedure ConfigureDefaultRenderState;
procedure PreparePresentationParameters;
procedure GR_DXInit;
procedure GR_DXReset;
procedure FreeScreenRenderBuffers;
procedure ApplyGammaRamp(Brightness: Single; Contrast: Single);
function GR_WinMessage(Callback: TWindowMessageCallbackGR): Integer;
function MainWindowProc(
    Window: Cardinal;
    Message: Cardinal;
    WParam: Cardinal;
    LParam: Integer
): Integer; stdcall;
function BeginFramePresentation: Boolean;
procedure EndFramePresentation;
procedure PresentScreenBuffer;
procedure DrawOffscreenTexture;
procedure CaptureScreenBackground(ApplyEffects: Boolean; UnusedOption: Byte);
procedure CaptureSavePreview;
procedure FreeSavePreviewBuffers;
procedure CopyBgraToRgb24(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer
);
procedure CaptureRecordingFrame;
procedure FlushRecordingFrames;
procedure DrawTransparentBuffer16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Clip: TRect;
    HalfAlpha: Boolean
);
procedure CopyPalettedBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Palette: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    constref Clip: TRect
);
procedure CopyGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect;
    HalfAlpha: Boolean;
    UnusedOption: Boolean
);
procedure CopyBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    Clip: TRect;
    UnusedOption: Boolean
);
procedure CopyTransparentGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect;
    TransparentColor: Word
);
procedure DrawAlphaGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect
);
procedure DrawAlphaBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    constref Clip: TRect
);
procedure DrawPaletteAlphaBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: TGraphBufPalGR;
    Clip: TRect
);
procedure ExpandPaletteToBgra(
    Dest: Pointer;
    DestPitch: Integer;
    Width: Cardinal;
    Height: Cardinal;
    Source: Pointer;
    SourcePitch: Integer;
    Palette: Pointer
);
procedure BlendPaletteBuffer16Clipped(
    Dest: Pointer;
    DestPitch: Integer;
    X: Integer;
    Y: Integer;
    Source: TGraphBufPalGR;
    Clip: TRect
);
procedure DrawGradientLine16Clipped(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    Color1: Cardinal;
    X2: Integer;
    Y2: Integer;
    Color2: Cardinal;
    Clip: TRect
);
function IsVirtualKeyDown(Key: Integer): Boolean;
function LookupLocalizedTextByKey(const Path: WideString): WideString;
function LookupLocalizedTextOrEmpty(const Path: WideString): WideString;
function GiResourceVariant: Integer;
function GiResourceSuffix: WideString;
function GiScalePixels(Value: Integer): Integer;
function GiScalePixelsEx(Value: Integer; AlternateValue: Integer): Integer;
procedure AppendLogLineThreadSafe(const Text: AnsiString);
procedure AppendLogTextThreadSafe(const Text: AnsiString);
procedure AppendDebugLogLine(const Text: AnsiString);
procedure AppendOptionalDebugLogLine(const Text: AnsiString);
procedure WriteTextFileThreadSafe(FileName: AnsiString; Text: AnsiString);
function IsInstallFeatureEnabled(const Path: WideString): Boolean;
function AddCursorUnit: TCursorUnit;
procedure RemoveCursorUnit(Cursor: TCursorUnit);
function FindCursorByName(const Name: WideString): TCursorUnit;
procedure PostMouseMoveMessage;
function MeasureCpuClockMHz: Double;
function ReadRegistryText(
    Root: Cardinal;
    KeyPath: WideString;
    ValueName: WideString;
    DefaultValue: WideString
): WideString;
function ReadRegistryInteger(
    Root: Cardinal;
    KeyPath: WideString;
    ValueName: WideString;
    DefaultValue: Integer
): Integer;
procedure RaiseWideMessage(const Message: WideString);
function Direct3DErrorText(Code: Integer): AnsiString;
function FormatUnixDateTime(Value: Cardinal): WideString;
procedure LoadInformationColorTags;
function GetStyleColorGI(
    StyleName: WideString;
    DefaultRed: Integer;
    DefaultGreen: Integer;
    DefaultBlue: Integer
): Cardinal;
function GetStyleColorTagGI(
    StyleName: WideString;
    DefaultRed: Integer;
    DefaultGreen: Integer;
    DefaultBlue: Integer
): WideString;
function GetGameUserDirectory: WideString;
function GetClipboardWideText: WideString;
procedure SetClipboardWideText(Text: WideString);
procedure LogPresentationParameters;
procedure LogExceptionBackTrace;
var
  CacheInfoThumbnails: Boolean = True;
  FastTravelTransitions: Boolean = True;
implementation
uses
  ZLib,
  CrashSymbols,
  GameNative,
  SDLRenderer,
  GI_Main,
  DirectXRenderException,
  aPacket,
  DateUtils,
  Robot,
  GI_MessageLoop,
  MMSystem,
  EC_Mem,
  GR_DX,
  Globals,
  aMyFunction,
  MessageText,
  GlobalsV,
  Math,
  Forms,
  SysUtils,
  Messages,
  ActiveX,
  Windows;
// @unit-initialization $876738
// @unit-finalization $4D5A48
var
  StartupState:
      Cardinal; // @addr $88A218 @note "Cleared by settings initialization; no retained reader found, original meaning unresolved."
  ScreenCenterX: Cardinal; // @addr $88A21C
  ScreenCenterY: Cardinal; // @addr $88A220
  LastWindowMessageTick: Cardinal; // @addr $88A224
  MessageIdle: Boolean; // @addr $88A228
{$I-}
procedure LogExceptionBackTrace;
var
  I: Integer;
begin
  AppendLogLineThreadSafe(DescribeCodeAddress(ExceptAddr));
  for I := 0 to ExceptFrameCount - 1 do
    AppendLogLineThreadSafe(DescribeCodeAddress(ExceptFrames[I]));
end;
procedure LogMemoryUsage;
begin
  AppendLogLineThreadSafe('Native macOS allocator')
end;
function Ex_OKGF_MulTable256x256: Pointer;
begin
  try
    Result := OKGF_MulTable256x256;
  except
    raise Exception.Create('Error in OKGF_MulTable256x256');
  end;
end;
function Ex_OKGF_DXVersion: Cardinal;
begin
  try
    Result := OKGF_DXVersion;
  except
    raise Exception.Create('Error in OKGF_DXVersion');
  end;
end;
function BeginImageRead(
    Source: Pointer;
    SourceSize: Integer;
    out Width, Height: Integer
): POkgfReadContext;
begin
  try
    Result := OKGF_ReadStart_Buf(Source, SourceSize, Width, Height);
  except
    raise Exception.Create('Error in OKGF_ReadStart_Buf');
  end;
end;
function ReadImagePixels(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    RedMask, GreenMask, BlueMask, AlphaMask: Cardinal;
    BytesPerPixel: Integer
): Integer;
begin
  try
    Result :=
        OKGF_Read(
            Context,
            Pixels,
            PitchBytes,
            RedMask,
            GreenMask,
            BlueMask,
            AlphaMask,
            BytesPerPixel
        );
  except
    raise Exception.Create('Error in OKGF_Read');
  end;
end;
function BeginIndexedImageRead(
    Source: Pointer;
    SourceSize: Integer;
    out Width, Height, PaletteCount, BytesPerPixel: Integer
): POkgfReadContext;
begin
  try
    Result := OKGF_ReadStartPal_Buf(Source, SourceSize, Width, Height, PaletteCount, BytesPerPixel);
  except
    raise Exception.Create('Error in OKGF_ReadStartPal_Buf');
  end;
end;
function ReadIndexedImagePixels(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    Palette: PColorRGBA
): Integer;
begin
  try
    Result := OKGF_ReadPal(Context, Pixels, PitchBytes, Palette);
  except
    raise Exception.Create('Error in OKGF_ReadPal');
  end;
end;
function WritePngFile(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes, Width, Height, HasAlpha, SwapRedBlue: Integer
): Integer;
begin
  try
    Result :=
        OKGF_Write_PNG_File(FileName, Pixels, PitchBytes, Width, Height, HasAlpha, SwapRedBlue);
  except
    raise Exception.Create('Error in OKGF_Write_PNG_File');
  end;
end;
function WriteBmpFile(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes, BitsPerPixel: Integer;
    RedMask, GreenMask, BlueMask, AlphaMask: Cardinal;
    Width, Height: Integer
): Integer;
begin
  try
    Result :=
        OKGF_Write_BMP_File(
            FileName,
            Pixels,
            PitchBytes,
            BitsPerPixel,
            RedMask,
            GreenMask,
            BlueMask,
            AlphaMask,
            Width,
            Height
        );
  except
    raise Exception.Create('Error in OKGF_Write_BMP_File');
  end;
end;
procedure Ex_OKGR_AlphaBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_AlphaBuf_Draw_RGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_AlphaBuf_Draw_RGBA');
  end;
end;
procedure Ex_OKGR_TransAlphaBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_TransAlphaBuf_Draw_RGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_TransAlphaBuf_Draw_RGBA');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_AlphaIndexed_Draw_RGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_Draw_RGBA');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_AlphaDraw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_AlphaIndexed_AlphaDraw_RGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_AlphaDraw_RGBA');
  end;
end;
procedure Ex_OKGR_TransBuf_Draw_RGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_TransBuf_Draw_RGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_TransBuf_Draw_RGBA');
  end;
end;
procedure Ex_OKGR_TransBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_TransBuf_DrawClip_WORD(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_TransBuf_DrawClip_WORD');
  end;
end;
procedure Ex_OKGR_TransBuf_HADrawClip_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_TransBuf_HADrawClip_16(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_TransBuf_HADrawClip_16');
  end;
end;
function Ex_OKGR_TransBuf_Build_WORD(
    Source: Pointer;
    Pitch, Width, Height: Integer;
    Dest: Pointer;
    TransparentColor: Word
): Integer;
begin
  try
    Result := OKGR_TransBuf_Build_WORD(Source, Pitch, Width, Height, Dest, TransparentColor);
  except
    raise Exception.Create('Error in OKGR_TransBuf_Build_WORD');
  end;
end;
function Ex_OKGR_TransBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch, Width, Height: Integer;
    Dest: Pointer
): Integer;
begin
  try
    Result := OKGR_TransBuf_BuildFromRGBA_16(Source, Pitch, Width, Height, Dest);
  except
    raise Exception.Create('Error in OKGR_TransBuf_BuildFromRGBA_16');
  end;
end;
procedure Ex_OKGR_TransAlphaBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_TransAlphaBuf_DrawClip_WORD(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_TransAlphaBuf_DrawClip_WORD');
  end;
end;
procedure Ex_OKGR_AlphaBuf_DrawClip_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_AlphaBuf_DrawClip_16(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_AlphaBuf_DrawClip_16');
  end;
end;
function Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch, Width, Height: Integer;
    Dest: Pointer
): Integer;
begin
  try
    Result := OKGR_TransAlphaBuf_BuildFromRGBA_16(Source, Pitch, Width, Height, Dest);
  except
    raise Exception.Create('Error in OKGR_TransAlphaBuf_BuildFromRGBA_16');
  end;
end;
function Ex_OKGR_AlphaBuf_BuildFromRGBA(
    Source: Pointer;
    Pitch, Width, Height: Integer;
    Dest: Pointer
): Integer;
begin
  try
    Result := OKGR_AlphaBuf_BuildFromRGBA(Source, Pitch, Width, Height, Dest);
  except
    raise Exception.Create('Error in OKGR_AlphaBuf_BuildFromRGBA');
  end;
end;
procedure Ex_OKGR_AlphaSimpleBuf_Draw_16(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer
);
begin
  try
    OKGR_AlphaSimpleBuf_Draw_16(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height
    );
  except
    raise Exception.Create('Error in OKGR_AlphaSimpleBuf_Draw_16');
  end;
end;
procedure Ex_OKGR_AlphaSimpleBufPalAlpha_Draw_16(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer;
    Palette: PColorRGBA
);
begin
  try
    OKGR_AlphaSimpleBufPalAlpha_Draw_16(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height,
        Palette
    );
  except
    raise Exception.Create('Error in OKGR_AlphaSimpleBufPalAlpha_Draw_16');
  end;
end;
procedure Ex_OKGR_MaskBuf_DrawClip_DWORD(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    Color: Cardinal;
    constref Clip: TRect
);
begin
  try
    OKGR_MaskBuf_DrawClip_DWORD(Dest, Pitch, X, Y, Source, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_MaskBuf_DrawClip_DWORD');
  end;
end;
procedure Ex_OKGR_MaskBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_MaskBuf_DrawClip_WORD(Dest, Pitch, X, Y, Source, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_MaskBuf_DrawClip_WORD');
  end;
end;
procedure Ex_OKGR_TransBuf_FillAlphaClip_RGBA(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Cardinal
);
begin
  try
    OKGR_TransBuf_FillAlphaClip_RGBA(Dest, Pitch, X, Y, Source, Clip, Color);
  except
    raise Exception.Create('Error in OKGR_TransBuf_FillAlphaClip_RGBA');
  end;
end;
procedure Ex_OKGR_TransBuf_FillAlphaClip_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Word
);
begin
  try
    OKGR_TransBuf_FillAlphaClip_16(Dest, Pitch, X, Y, Source, Clip, Color);
  except
    raise Exception.Create('Error in OKGR_TransBuf_FillAlphaClip_16');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_WORD(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_AlphaIndexed_CopyDrawClip_WORD(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_CopyDrawClip_WORD');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
);
begin
  try
    OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(Dest, Pitch, X, Y, Source, Clip, Alpha);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_CopyDrawClip_Alpha_16');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect
);
begin
  try
    OKGR_AlphaIndexed_AlphaDrawClip_16(Dest, Pitch, X, Y, Source, Clip);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_AlphaDrawClip_16');
  end;
end;
procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
);
begin
  try
    OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(Dest, Pitch, X, Y, Source, Clip, Alpha);
  except
    raise Exception.Create('Error in OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16');
  end;
end;
function Ex_OKGR_RotateBuf_Build(
    Width,
    Height,
    SourceWidth,
    SourceHeight,
    CenterX,
    CenterY: Integer
): Pointer;
begin
  try
    Result := OKGR_RotateBuf_Build(Width, Height, SourceWidth, SourceHeight, CenterX, CenterY);
  except
    raise Exception.Create('Error in OKGR_RotateBuf_Build');
  end;
end;
procedure Ex_OKGR_RotateBuf_Free(Buffer: Pointer);
begin
  try
    OKGR_RotateBuf_Free(Buffer);
  except
    raise Exception.Create('Error in OKGR_RotateBuf_Free');
  end;
end;
procedure Ex_OKGR_RotateBuf_Size(
    X, Y: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    var Bounds: TRect
);
begin
  try
    OKGR_RotateBuf_Size(X, Y, Angle, RotationMap, Bounds);
  except
    raise Exception.Create('Error in OKGR_RotateBuf_Size');
  end;
end;
procedure Ex_OKGR_RotateBuf_Draw_DWORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch, CenterX, CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer
);
begin
  try
    OKGR_RotateBuf_Draw_DWORD(
        Dest,
        DestPitch,
        Source,
        SourcePitch,
        CenterX,
        CenterY,
        Angle,
        RotationMap
    );
  except
    raise Exception.Create('Error in OKGR_RotateBuf_Draw_DWORD');
  end;
end;
procedure Ex_OKGR_RotateBuf_Draw_BYTE(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch, Width, Height: Integer;
    Angle: Byte;
    RotationMap: Pointer
);
begin
  try
    OKGR_RotateBuf_Draw_BYTE(
        Dest,
        DestPitch,
        Source,
        SourcePitch,
        Width,
        Height,
        Angle,
        RotationMap
    );
  except
    raise Exception.Create('Error in OKGR_RotateBuf_Draw_BYTE');
  end;
end;
procedure Ex_OKGR_RotateBuf_DrawTransClip_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch, CenterX, CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    const Clip: TRect
);
begin
  try
    OKGR_RotateBuf_DrawTransClip_WORD(
        Dest,
        DestPitch,
        Source,
        SourcePitch,
        CenterX,
        CenterY,
        Angle,
        RotationMap,
        Clip
    );
  except
    raise Exception.Create('Error in OKGR_RotateBuf_DrawTransClip_WORD');
  end;
end;
function Ex_OKGR_LightBuf_Create(Width, Height: Integer): Pointer;
begin
  try
    Result := OKGR_LightBuf_Create(Width, Height);
  except
    raise Exception.Create('Error in OKGR_LightBuf_Create');
  end;
end;
procedure Ex_OKGR_LightBuf_Destroy(Buffer: Pointer);
begin
  try
    OKGR_LightBuf_Destroy(Buffer);
  except
    raise Exception.Create('Error in OKGR_LightBuf_Destroy');
  end;
end;
procedure Ex_OKGR_LightBuf_SetSme(Buffer: Pointer; X, Y: Integer);
begin
  try
    OKGR_LightBuf_SetSme(Buffer, X, Y);
  except
    raise Exception.Create('Error in OKGR_LightBuf_SetSme');
  end;
end;
procedure Ex_OKGR_LightBuf_Init(Buffer: Pointer; Value: Byte);
begin
  try
    OKGR_LightBuf_Init(Buffer, Value);
  except
    raise Exception.Create('Error in OKGR_LightBuf_Init');
  end;
end;
procedure Ex_OKGR_LightBuf_LoadFromPalBuf(
    Buffer, Source: Pointer;
    Width, Height, Pitch: Integer;
    Palette: PColorRGBA
);
begin
  try
    OKGR_LightBuf_LoadFromPalBuf(Buffer, Source, Width, Height, Pitch, Palette);
  except
    raise Exception.Create('Error in OKGR_LightBuf_LoadFromPalBuf');
  end;
end;
procedure Ex_OKGR_LightBuf_Rotate(Dest, Source, RotationMap: Pointer; Angle: Byte);
begin
  try
    OKGR_LightBuf_Rotate(Dest, Source, RotationMap, Angle);
  except
    raise Exception.Create('Error in OKGR_LightBuf_Rotate');
  end;
end;
function Ex_OKGR_Planet2_TemplBuild(
    Source: Pointer;
    Pitch, Height, TextureWidth, TextureHeight: Integer;
    var ByteCount: Integer
): Pointer;
begin
  try
    Result :=
        OKGR_Planet2_TemplBuild(Source, Pitch, Height, TextureWidth, TextureHeight, ByteCount);
  except
    raise Exception.Create('Error in OKGR_Planet2_TemplBuild');
  end;
end;
procedure Ex_OKGR_Planet2_TemplDel(TemplateData: Pointer);
begin
  try
    OKGR_Planet2_TemplDel(TemplateData);
  except
    raise Exception.Create('Error in OKGR_Planet2_TemplDel');
  end;
end;
procedure Ex_OKGR_Planet2_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer
);
begin
  try
    OKGR_Planet2_DrawAndLight_32(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y
    );
  except
    raise Exception.Create('Error in OKGR_Planet2_DrawAndLight_32');
  end;
end;
procedure Ex_OKGR_Planet2_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer;
    const Clip: TRect
);
begin
  try
    OKGR_Planet2_DrawAndLightClip_16(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y,
        Clip
    );
  except
    raise Exception.Create('Error in OKGR_Planet2_DrawAndLightClip_16');
  end;
end;
procedure Ex_OKGR_Planet3_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer
);
begin
  try
    OKGR_Planet3_DrawAndLight_32(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y
    );
  except
    raise Exception.Create('Error in OKGR_Planet3_DrawAndLight_32');
  end;
end;
procedure Ex_OKGR_Planet3_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer;
    const Clip: TRect
);
begin
  try
    OKGR_Planet3_DrawAndLightClip_16(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y,
        Clip
    );
  except
    raise Exception.Create('Error in OKGR_Planet3_DrawAndLightClip_16');
  end;
end;
procedure Ex_OKGR_Planet4_DrawAndLight_32(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer
);
begin
  try
    OKGR_Planet4_DrawAndLight_32(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y
    );
  except
    raise Exception.Create('Error in OKGR_Planet4_DrawAndLight_32');
  end;
end;
procedure Ex_OKGR_Planet4_DrawAndLightClip_16(
    Dest: Pointer;
    DestPitch: Integer;
    TemplateData, Source: Pointer;
    SourcePitch, WidthMask, MapOffset: Integer;
    LightBuffer, Palette: Pointer;
    X, Y: Integer;
    const Clip: TRect
);
begin
  try
    OKGR_Planet4_DrawAndLightClip_16(
        Dest,
        DestPitch,
        TemplateData,
        Source,
        SourcePitch,
        WidthMask,
        MapOffset,
        LightBuffer,
        Palette,
        X,
        Y,
        Clip
    );
  except
    raise Exception.Create('Error in OKGR_Planet4_DrawAndLightClip_16');
  end;
end;
procedure Ex_OKGR_Copy_XY_XY_WORD(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer
);
begin
  try
    OKGR_Copy_XY_XY_WORD(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height
    );
  except
    raise Exception.Create('Error in OKGR_Copy_XY_XY_WORD');
  end;
end;
procedure Ex_OKGR_PalCopy_XY_XY_WORD(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY: Integer;
    Palette: Pointer;
    Width, Height: Integer
);
begin
  try
    OKGR_PalCopy_XY_XY_WORD(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Palette,
        Width,
        Height
    );
  except
    raise Exception.Create('Error in OKGR_PalCopy_XY_XY_WORD');
  end;
end;
procedure Ex_OKGR_CopyTrans_XY_XY_WORD(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer;
    TransparentColor: Word
);
begin
  try
    OKGR_CopyTrans_XY_XY_WORD(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height,
        TransparentColor
    );
  except
    raise Exception.Create('Error in OKGR_CopyTrans_XY_XY_WORD');
  end;
end;
procedure Ex_OKGR_CopySingleBuf_XY_XY_WORD(
    Pixels: Pointer;
    Pitch, DestX, DestY, SourceX, SourceY, Width, Height: Integer
);
begin
  try
    OKGR_CopySingleBuf_XY_XY_WORD(Pixels, Pitch, DestX, DestY, SourceX, SourceY, Width, Height);
  except
    raise Exception.Create('Error in OKGR_CopySingleBuf_XY_XY_WORD');
  end;
end;
procedure Ex_OKGR_HACopy_XY_XY_16(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer
);
begin
  try
    OKGR_HACopy_XY_XY_16(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height
    );
  except
    raise Exception.Create('Error in OKGR_HACopy_XY_XY_16');
  end;
end;
procedure Ex_OKGR_StretchGdi_WORD(
    Dest: Pointer;
    Width, Height: Cardinal;
    Source: Pointer;
    SourceWidth, SourceHeight: Cardinal
);
begin
  try
    OKGR_StretchGdi_WORD(Dest, Width, Height, Source, SourceWidth, SourceHeight);
  except
    raise Exception.Create('Error in OKGR_StretchGdi_WORD');
  end;
end;
procedure Ex_OKGR_Fill_WORD(Pixels: Pointer; Pitch, Width, Height: Integer; Color: Word);
begin
  try
    OKGR_Fill_WORD(Pixels, Pitch, Width, Height, Color);
  except
    raise Exception.Create('Error in OKGR_Fill_WORD');
  end;
end;
procedure Ex_OKGF_ConvertRGBto565(Source, Dest: Pointer; Pitch, Width, Height: Integer);
begin
  try
    OKGF_ConvertRGBto565(Source, Dest, Pitch, Width, Height);
  except
    raise Exception.Create('Error in OKGF_ConvertRGBto565');
  end;
end;
procedure Ex_OKGF_Convert565toRGB(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch, Width, Height: Integer
);
begin
  try
    OKGF_Convert565toRGB(Source, SourcePitch, Dest, DestPitch, Width, Height);
  except
    raise Exception.Create('Error in OKGF_Convert565toRGB');
  end;
end;
procedure Ex_OKGF_Convert565toBGR(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch, Width, Height: Integer
);
begin
  try
    OKGF_Convert565toBGR(Source, SourcePitch, Dest, DestPitch, Width, Height);
  except
    raise Exception.Create('Error in OKGF_Convert565toBGR');
  end;
end;
procedure Ex_OKGF_Convert565toBGRA(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch, Width, Height: Integer
);
begin
  try
    OKGF_Convert565toBGRA(Source, SourcePitch, Dest, DestPitch, Width, Height);
  except
    raise Exception.Create('Error in OKGF_Convert565toBGRA');
  end;
end;
procedure Ex_OKGF_Convert_8888to565(
    Dest: Pointer;
    DestPitch, DestX, DestY: Integer;
    Source: Pointer;
    SourcePitch, SourceX, SourceY, Width, Height: Integer
);
begin
  try
    OKGF_Convert_8888to565(
        Dest,
        DestPitch,
        DestX,
        DestY,
        Source,
        SourcePitch,
        SourceX,
        SourceY,
        Width,
        Height
    );
  except
    raise Exception.Create('Error in OKGF_Convert_8888to565');
  end;
end;
procedure Ex_OKGR_ShrLight_16(Pixels: Pointer; Pitch, Width, Height, Shift: Integer);
begin
  try
    OKGR_ShrLight_16(Pixels, Pitch, Width, Height, Shift);
  except
    raise Exception.Create('Error in OKGR_ShrLight_16');
  end;
end;
procedure Ex_OKGR_ShrLightMask_16(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch, Width, Height: Integer
);
begin
  try
    OKGR_ShrLightMask_16(Dest, DestPitch, Source, SourcePitch, Width, Height);
  except
    raise Exception.Create('Error in OKGR_ShrLightMask_16');
  end;
end;
procedure Ex_OKGR_Light_BYTE(
    Pixels: Pointer;
    PixelStride, Pitch, Width, Height: Integer;
    Alpha: Byte
);
begin
  try
    OKGR_Light_BYTE(Pixels, PixelStride, Pitch, Width, Height, Alpha);
  except
    raise Exception.Create('Error in OKGR_Light_BYTE');
  end;
end;
procedure Ex_OKGR_Circle_DrawClip_WORD(
    Pixels: Pointer;
    Pitch, X, Y, Radius: Integer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_Circle_DrawClip_WORD(Pixels, Pitch, X, Y, Radius, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Circle_DrawClip_WORD');
  end;
end;
procedure Ex_OKGR_Circle_DrawClip_BYTE(
    Pixels: Pointer;
    Pitch, X, Y, Radius: Integer;
    Color: Byte;
    constref Clip: TRect
);
begin
  try
    OKGR_Circle_DrawClip_BYTE(Pixels, Pitch, X, Y, Radius, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Circle_DrawClip_BYTE');
  end;
end;
procedure Ex_OKGR_Circle_DrawFillClip_WORD(
    Pixels: Pointer;
    Pitch, X, Y, Radius: Integer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_Circle_DrawFillClip_WORD(Pixels, Pitch, X, Y, Radius, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Circle_DrawFillClip_WORD');
  end;
end;
procedure Ex_OKGR_Circle_DrawFillClip_BYTE(
    Pixels: Pointer;
    Pitch, X, Y, Radius: Integer;
    Color: Byte;
    constref Clip: TRect
);
begin
  try
    OKGR_Circle_DrawFillClip_BYTE(Pixels, Pitch, X, Y, Radius, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Circle_DrawFillClip_BYTE');
  end;
end;
function Ex_OKGR_Line_Clip(var X1, Y1, X2, Y2: Integer; const Clip: TRect): Integer;
begin
  try
    Result := OKGR_Line_Clip(X1, Y1, X2, Y2, Clip);
  except
    raise Exception.Create('Error in OKGR_Line_Clip');
  end;
end;
function Ex_OKGR_LineColor_Clip(
    var X1, Y1: Integer;
    var Color1: Cardinal;
    var X2, Y2: Integer;
    var Color2: Cardinal;
    const Clip: TRect
): Integer;
begin
  try
    Result := OKGR_LineColor_Clip(X1, Y1, Color1, X2, Y2, Color2, Clip);
  except
    raise Exception.Create('Error in Ex_OKGR_LineColor_Clip');
  end;
end;
procedure Ex_OKGR_Line_Draw_WORD(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Word);
begin
  try
    OKGR_Line_Draw_WORD(Pixels, Pitch, X1, Y1, X2, Y2, Color);
  except
    raise Exception.Create('Error in OKGR_Line_Draw_WORD');
  end;
end;
procedure Ex_OKGR_Line_DrawClip_WORD(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_Line_DrawClip_WORD(Pixels, Pitch, X1, Y1, X2, Y2, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Line_DrawClip_WORD');
  end;
end;
function Ex_OKGR_Line_CopyToBuf_WORD(
    Dest, Source: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer
): Integer;
begin
  try
    Result := OKGR_Line_CopyToBuf_WORD(Dest, Source, Pitch, X1, Y1, X2, Y2);
  except
    raise Exception.Create('Error in OKGR_Line_CopyToBuf_WORD');
  end;
end;
function Ex_OKGR_Line_CopyFromBuf_WORD(
    Source, Dest: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer
): Integer;
begin
  try
    Result := OKGR_Line_CopyFromBuf_WORD(Source, Dest, Pitch, X1, Y1, X2, Y2);
  except
    raise Exception.Create('Error in OKGR_Line_CopyFromBuf_WORD');
  end;
end;
procedure Ex_OKGR_Line_DrawClip_Alpha_16(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer;
    Color: Word;
    Alpha: Byte;
    constref Clip: TRect
);
begin
  try
    OKGR_Line_DrawClip_Alpha_16(Pixels, Pitch, X1, Y1, X2, Y2, Color, Alpha, Clip);
  except
    raise Exception.Create('Error in OKGR_Line_DrawClip_Alpha_16');
  end;
end;
procedure Ex_OKGR_AnimLine_Draw_16(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer;
    Color: Word;
    Phase: Integer;
    constref Clip: TRect
);
begin
  try
    OKGR_AnimLine_Draw_16(Pixels, Pitch, X1, Y1, X2, Y2, Color, Phase, Clip);
  except
    raise Exception.Create('Error in OKGR_AnimLine_Draw_16');
  end;
end;
procedure Ex_OKGR_AnimShadowLine_Draw_16(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2: Integer;
    Color: Word;
    Phase: Integer;
    constref Clip: TRect;
    ShadowPixels: Pointer;
    ShadowPitch: Integer
);
begin
  try
    OKGR_AnimShadowLine_Draw_16(
        Pixels,
        Pitch,
        X1,
        Y1,
        X2,
        Y2,
        Color,
        Phase,
        Clip,
        ShadowPixels,
        ShadowPitch
    );
  except
    raise Exception.Create('Error in OKGR_AnimShadowLine_Draw_16');
  end;
end;
procedure Ex_OKGR_Alpha64Trapezium_16(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2, X3, X4: Integer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_Alpha64Trapezium_16(Pixels, Pitch, X1, Y1, X2, Y2, X3, X4, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Alpha64Trapezium_16');
  end;
end;
procedure Ex_OKGR_Alpha128Trapezium_16(
    Pixels: Pointer;
    Pitch, X1, Y1, X2, Y2, X3, X4: Integer;
    Color: Word;
    constref Clip: TRect
);
begin
  try
    OKGR_Alpha128Trapezium_16(Pixels, Pitch, X1, Y1, X2, Y2, X3, X4, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_Alpha128Trapezium_16');
  end;
end;
procedure Ex_OKGR_FillTrapezium_DWORD(
    Pixels: Pointer;
    Pitch, X1, X2, Y1, X3, X4, Y2: Integer;
    Color: Cardinal;
    constref Clip: TRect
);
begin
  try
    OKGR_FillTrapezium_DWORD(Pixels, Pitch, X1, X2, Y1, X3, X4, Y2, Color, Clip);
  except
    raise Exception.Create('Error in OKGR_FillTrapezium_DWORD');
  end;
end;
procedure Ex_OKGF_Rescale(
    Dest: Pointer;
    Width, Height, DestPitch: Integer;
    Source: Pointer;
    SourceWidth, SourceHeight, SourcePitch, BytesPerPixel, Filter: Integer
);
begin
  try
    OKGF_Rescale(
        Dest,
        Width,
        Height,
        DestPitch,
        Source,
        SourceWidth,
        SourceHeight,
        SourcePitch,
        BytesPerPixel,
        Filter
    );
  except
    raise Exception.Create('Error in OKGF_Rescale');
  end;
end;
procedure Ex_OKGR_F5_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_F5_DrawRGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_F5_DrawRGBA');
  end;
end;
procedure Ex_OKGR_F6_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer);
begin
  try
    OKGR_F6_DrawRGBA(Dest, Pitch, Source);
  except
    raise Exception.Create('Error in OKGR_F6_DrawRGBA');
  end;
end;
procedure ApplyProcessAffinity;
begin
end;
procedure CheckRuntimeWatchdog;
begin
  if (RuntimeWatchdog <> nil) and not RuntimeWatchdog.IsRunning then
    raise Exception.Create('Runtime worker stopped')
end;
procedure CreateStartupLogFile;
var
  LogPath: AnsiString;
  procedure ArchivePreviousLog(const PreviousPath: AnsiString);
  var
    ArchiveDirectory, ArchivePath: AnsiString;
    Index: Integer;
  begin
    if not RTLFileSystem.FileExists(PreviousPath) then
      Exit;
    ArchiveDirectory := GetGameUserDirectory + 'Logs/';
    if not ForceDirectories(ArchiveDirectory) then
      raise Exception.Create('Cannot create log archive: ' + ArchiveDirectory);
    ArchivePath := ArchiveDirectory + 'Rangers-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now);
    Index := 0;
    while RTLFileSystem.FileExists(ArchivePath + '-' + IntToStr(Index) + '.log') do
      Inc(Index);
    ArchivePath := ArchivePath + '-' + IntToStr(Index) + '.log';
    if not SysUtils.RenameFile(PreviousPath, ArchivePath) then
      raise Exception.Create('Cannot preserve previous log: ' + PreviousPath);
  end;
begin
  LogPath := GetGameUserDirectory + RuntimeLogFileName;
  ArchivePreviousLog(LogPath);
  AssignFile(SessionLog, LogPath);
  Rewrite(SessionLog);

  Writeln(SessionLog, 'Start');

  CloseFile(SessionLog);

end;
procedure InitializePlatformRuntimeAndMainWindow;
begin
  if SessionLogLock = nil then
    SessionLogLock := TCriticalSection.Create;
  PerformanceCounterFrequency := 1000;
  if not InitializePackageCollection then
    raise Exception.Create('Cannot initialize package collection');
  MainWindowHandle := 1;
  InstallConfig := TBlockParEC.Create;
  InstallConfig.LoadFromTextFileWithEncodingProbe('INSTALL.TXT', False);
  QuestMessages := TQuestMessages.Create;
end;
procedure LoadLanguageAndPackages;
begin
  if RequestedLanguage <> '' then
  begin
    if not RTLFileSystem.FileExists('install_' + RequestedLanguage + '.txt') then
    begin
      AppendLogLineThreadSafe('Not installed - ' + RequestedLanguage);
      RequestedLanguage := '';
    end
    else
      SelectedLanguage := RequestedLanguage;
  end;
  if SelectedLanguage <> '' then
    if not RTLFileSystem.FileExists('install_' + SelectedLanguage + '.txt') then
    begin
      AppendLogLineThreadSafe('Not installed - ' + SelectedLanguage + ', try to switch to russian');
      SelectedLanguage := 'russian';
    end;
  if SelectedLanguage = '' then
    SelectedLanguage := 'russian';
  // Keep the else: DCC32 emits the native jump at $4CBAB6 after the raise.
  if not RTLFileSystem.FileExists('install_' + SelectedLanguage + '.txt') then
    raise Exception.Create('Not installed language: ' + SelectedLanguage)
  else
  begin
    LanguageInstallConfig := TBlockParEC.Create;
    LanguageInstallConfig.LoadFromTextFileWithEncodingProbe(
        PWideChar('install_' + SelectedLanguage + '.txt'),
        False
    );
  end;
  ModInstallConfigs := TList.Create;
  ModLanguageInstallConfigs := TList.Create;
  LoadSelectedModInstallBlocks;
  if not LoadConfiguredPackages then
    raise Exception.Create('Error while openning package files');
end;
procedure LoadSelectedModInstallBlocks;
var
  Index: Integer;
  ModNames, ModPath: WideString;
  Block: TBlockParEC;
begin
  ModNames := '';
  // CHANGE: PORTABILITY - Resolve Windows-style mod paths through the native filesystem.
  if RTLFileSystem.FileExists('Mods\ModCFG.txt') then
  begin
    Block := TBlockParEC.Create;
    Block.LoadFromTextFileWithEncodingProbe('Mods\ModCFG.txt', False);
    if Block.CountParams('CurrentMod') > 0 then
      ModNames := TrimWideString(Block.GetParam('CurrentMod'));
    SelectedMods := ModNames;
    SelectedModsDisplaySuffix := ', ' + SelectedMods + ',';
    if ModNames <> '' then
    begin
      if SkipModsOnReload then
        AppendLogLineThreadSafe('Trying to reload without mods')
      else
        AppendLogLineThreadSafe('CurrentMod=' + ModNames);
    end;
    Block.Free;
  end
  else
  begin
    SelectedMods := '';
    SelectedModsDisplaySuffix := '';
  end;
  if not SkipModsOnReload then
  begin
    Index := 0;
    repeat
      ModPath := TrimWideString(ExtractDelimitedPartW(ModNames, Index, ','));
      if ModPath <> '' then
        ModPath := ModPath + '\';
      if RTLFileSystem.FileExists('Mods\' + ModPath + 'Install.txt') then
      begin
        Block := TBlockParEC.Create;
        ModInstallConfigs.Add(Block);
        Block
            .LoadFromTextFileWithEncodingProbe(PWideChar('Mods\' + ModPath + 'Install.txt'), False);
      end;
      if RTLFileSystem.FileExists('Mods\' + ModPath + 'Install_' + SelectedLanguage + '.txt') then
      begin
        Block := TBlockParEC.Create;
        ModLanguageInstallConfigs.Add(Block);
        Block.LoadFromTextFileWithEncodingProbe(
            PWideChar('Mods\' + ModPath + 'Install_' + SelectedLanguage + '.txt'),
            False
        );
      end;
      Inc(Index);
    until Index >= CountDelimitedPartsW(ModNames, ',');
  end;
end;
procedure ResetInstalledPackageState;
var
  I: Integer;
begin
  FinalizePackageCollection;
  InitializePackageCollection;
  for I := 0 to ModInstallConfigs.Count - 1 do
    TObject(ModInstallConfigs[I]).Free;
  ModInstallConfigs.Clear;
  for I := 0 to ModLanguageInstallConfigs.Count - 1 do
    TObject(ModLanguageInstallConfigs[I]).Free;
  ModLanguageInstallConfigs.Clear;
end;
procedure FinalizePlatformRuntime;
begin
  FreeSavePreviewBuffers;
  if InstallConfig <> nil then
  begin
    InstallConfig.Free;
    InstallConfig := nil;
  end;
  if LanguageInstallConfig <> nil then
  begin
    LanguageInstallConfig.Free;
    LanguageInstallConfig := nil;
  end;
  FinalizePackageCollection;
  DestroyWindow(MainWindowHandle);
  MainWindowHandle := 0;
  CoUninitialize;
end;
function HasWow64Support: Boolean;
begin
  Result := False
end;
procedure ApplyMainWindowGeometry;
begin
end;
procedure ShowAndFocusMainWindow;
begin
end;
procedure LoadDatConfigAndModOverrides;
var
  ModNames, ModPath: WideString;
  HasOverrides: Boolean;
  Block: TBlockParEC;
  Data: TDataEC;
  Index: Integer;
  procedure LoadBlockDatConfig(
      Root: TBlockParEC;
      FileName: WideString
  ); // @ida "void __usercall $name(TBlockParEC *Root@<eax>, unsigned __int16 *FileName@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4CC7E7,0x4CC89C,0x4CC93B,0x4CCA24" @addr 0x4CC57C @note "An empty tree produces a log warning, not an exception from this wrapper."
  begin
    Root.LoadFromEncryptedDatFile(FileName);
    if (Root.GetBlockCount <= 0) and (Root.GetParamCount <= 0) then
      AppendLogLineThreadSafe('Warning! <' + FileName + '> is empty!');
  end;
  procedure LoadCacheDatConfig(
      Root: TDataEC;
      FileName: WideString
  ); // @ida "void __usercall $name(TDataEC *Root@<eax>, unsigned __int16 *FileName@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4CCA99,0x4CCB4E" @addr 0x4CC660
  begin
    Root.LoadFromEncryptedDatFile(FileName);
    if Root.IsEmpty then
      AppendLogLineThreadSafe('Warning! <' + FileName + '> is empty!');
  end;
begin
  MainDataConfig := TBlockParEC.Create;
  ModNames := '';
  if not SkipModsOnReload and RTLFileSystem.FileExists('Mods\ModCFG.txt') then
  begin
    Block := TBlockParEC.Create;
    Block.LoadFromTextFileWithEncodingProbe('Mods\ModCFG.txt', False);
    if Block.CountParams('CurrentMod') > 0 then
      ModNames := TrimWideString(Block.GetParamByPath('CurrentMod'));
    Block.Free;
  end;
  HasOverrides := False;
  LoadBlockDatConfig(MainDataConfig, 'CFG\Main.dat');
  Index := 0;
  if not SkipModsOnReload then
  begin
    repeat
      ModPath := TrimWideString(ExtractDelimitedPartW(ModNames, Index, ','));
      if ModPath <> '' then
        ModPath := ModPath + '\';
      if RTLFileSystem.FileExists('Mods\' + ModPath + 'CFG\Main.dat') then
      begin
        HasOverrides := True;
        Block := TBlockParEC.Create;
        LoadBlockDatConfig(Block, 'Mods\' + ModPath + 'CFG\Main.dat');
        MainDataConfig.MergeFrom(Block);
        Block.Clear;
        Block.Free;
      end;
      Inc(Index);
    until Index >= CountDelimitedPartsW(ModNames, ',');
  end;
  if DumpLoadedConfig then
    MainDataConfig.SaveTextFile('Main.txt', False, True);
  LanguageDataConfig := TBlockParEC.Create;
  LoadBlockDatConfig(
      LanguageDataConfig,
      'CFG\' + LanguageInstallConfig.GetParam('Lang') + '\Lang.dat'
  );
  Index := 0;
  if not SkipModsOnReload then
  begin
    repeat
      ModPath := TrimWideString(ExtractDelimitedPartW(ModNames, Index, ','));
      if ModPath <> '' then
        ModPath := ModPath + '\';
      if RTLFileSystem.FileExists(
          'Mods\' + ModPath + 'CFG\' + LanguageInstallConfig.GetParam('Lang') + '\Lang.dat') then
      begin
        HasOverrides := True;
        Block := TBlockParEC.Create;
        LoadBlockDatConfig(
            Block,
            'Mods\' + ModPath + 'CFG\' + LanguageInstallConfig.GetParam('Lang') + '\Lang.dat'
        );
        LanguageDataConfig.MergeFrom(Block);
        Block.Clear;
        Block.Free;
      end;
      Inc(Index);
    until Index >= CountDelimitedPartsW(ModNames, ',');
  end;
  if DumpLoadedConfig then
    LanguageDataConfig.SaveTextFile('Lang.txt', False, True);
  CacheDataRoot := TDataEC.Create;
  LoadCacheDatConfig(CacheDataRoot, 'CFG\CacheData.dat');
  Index := 0;
  if not SkipModsOnReload then
  begin
    repeat
      ModPath := TrimWideString(ExtractDelimitedPartW(ModNames, Index, ','));
      if ModPath <> '' then
        ModPath := ModPath + '\';
      if RTLFileSystem.FileExists('Mods\' + ModPath + 'CFG\CacheData.dat') then
      begin
        HasOverrides := True;
        Data := TDataEC.Create;
        LoadCacheDatConfig(Data, 'Mods\' + ModPath + 'CFG\CacheData.dat');
        CacheDataRoot.MergeFrom(Data);
        Data.Free;
      end;
      Inc(Index);
    until Index >= CountDelimitedPartsW(ModNames, ',');
  end;
  if DumpLoadedConfig then
  begin
    Block := TBlockParEC.Create;
    CacheDataRoot.WriteToBlock(Block);
    Block.SaveTextFile('CacheData.txt', False, True);
    Block.Free;
  end;
  if HasOverrides and (ModNames = '') then
  begin
    SelectedMods := 'Custom mod';
    SelectedModsDisplaySuffix := '';
    AppendLogLineThreadSafe('Custom mod');
  end;
end;
procedure FreeDatConfigRoots;
begin
  if CacheDataRoot <> nil then
  begin
    CacheDataRoot.Free;
    CacheDataRoot := nil;
  end;
  if LanguageDataConfig <> nil then
  begin
    LanguageDataConfig.Free;
    LanguageDataConfig := nil;
  end;
  GameDataConfig := nil;
  if MainDataConfig <> nil then
  begin
    MainDataConfig.Free;
    MainDataConfig := nil;
  end;
end;
procedure InitializeRuntimeAndSettings;
var
  ModuleName, Text, ExtraText: WideString;
  Block: TBlockParEC;
  Index, Count, BufferSize: Integer;
  Frame: Pointer;
  Cursor: TCursorUnit;
begin
  StartupState := 0;
  FinalizeRuntimeAndSettings;
  UserSettingsConfig := TBlockParEC.Create;
  Text := GetGameUserDirectory + 'CFG.TXT';
  if not RTLFileSystem.FileExists(AnsiString(Text)) then
  begin
    AppendLogTextThreadSafe('Creating cfg.txt ... ');
    CopyFileW('cfg.txt', PWideChar(Text), False);
    UserSettingsConfig.LoadFromTextFileWithEncodingProbe(PWideChar(Text), True);
    UserSettingsConfig.AddParam('CurrentVersion', '2.1.2500');
    UserSettingsConfig.AddParam('VideoMemSizeLimit', '256');
    if RunningUnderWine then
    begin
      UserSettingsConfig.AddParam('RunOnWineWithoutWarning', 'True');
      ShowWineWarning := True;
    end;
    UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
    AppendLogLineThreadSafe('ok!');
  end
  else
  begin
    UserSettingsConfig.LoadFromTextFileWithEncodingProbe(PWideChar(Text), True);
    if UserSettingsConfig.CountParamsByPath('CurrentVersion') = 0 then
    begin
      AppendLogTextThreadSafe('Updating cfg.txt content ... ');
      UserSettingsConfig.AddParam('CurrentVersion', '2.1.2500');
      UserSettingsConfig.SetOrAddParam('HardwareRender', 'True');
      UserSettingsConfig.SetOrAddParam('MultiThread', 'False');
      UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
      AppendLogLineThreadSafe('ok!');
    end
    else if UserSettingsConfig.GetParamByPathOrMarker('CurrentVersion') <> '2.1.2500' then
    begin
      AppendLogTextThreadSafe('Updating cfg.txt version ... ');
      if (UserSettingsConfig.GetParam('CurrentVersion') = '2.1.1800')
          and (UserSettingsConfig.CountParamsByPath('CountFilmSave') > 0)
          and (UserSettingsConfig.GetParamByPathOrMarker('CountFilmSave') = '30') then
        UserSettingsConfig.SetOrAddParam('CountFilmSave', '7');
      UserSettingsConfig.SetOrAddParam('CurrentVersion', '2.1.2500');
      UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
      AppendLogLineThreadSafe('ok!');
    end;
    if UserSettingsConfig.CountParamsByPath('VideoMemSizeLimit') = 0 then
    begin
      AppendLogTextThreadSafe('Updating cfg.txt content ... ');
      UserSettingsConfig.AddParam('VideoMemSizeLimit', '256');
      UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
      AppendLogLineThreadSafe('ok!');
    end;
    if RunningUnderWine then
      if (UserSettingsConfig.CountParams('RunOnWineWithoutWarning') = 0)
          or not ParseEnabledNameGI(
              TrimWideString(
                  UserSettingsConfig.GetParamByPathOrMarker('RunOnWineWithoutWarning')
              )) then
      begin
        if UserSettingsConfig.CountParams('RunOnWineWithoutWarning') = 0 then
          UserSettingsConfig.AddParam('RunOnWineWithoutWarning', 'True')
        else
          UserSettingsConfig.SetOrAddParam('RunOnWineWithoutWarning', 'True');
        UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
        ShowWineWarning := True;
      end;
  end;
  EditableSaveBlock := TBlockParEC.Create;
  NewGameSettingsConfig := TBlockParEC.Create;
  Text := GetGameUserDirectory + 'newgame.txt';
  if RTLFileSystem.FileExists(AnsiString(PWideChar(Text))) then
    NewGameSettingsConfig.LoadFromTextFileWithEncodingProbe(PWideChar(Text), True);
  if UserSettingsConfig.CountParamsByPath('MultiThread') > 0 then
    MultiThreadEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('MultiThread'));
  ApplyProcessAffinity;
  PathGrowEnabled := True;
  if UserSettingsConfig.CountParams('PathGrow') > 0 then
    PathGrowEnabled :=
        ParseEnabledNameGI(TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('PathGrow')));
  ShowSystemMouse := False;
  ShowSystemMouse := False;
  if RTLFileSystem.FileExists('Mods\ShipName.txt') then
  begin
    ModShipNameConfig := TBlockParEC.Create;
    ModShipNameConfig.LoadFromTextFileWithEncodingProbe('Mods\ShipName.txt', False);
  end;
  if RTLFileSystem.FileExists('Mods\RuinName.txt') then
  begin
    ModRuinNameConfig := TBlockParEC.Create;
    ModRuinNameConfig.LoadFromTextFileWithEncodingProbe('Mods\RuinName.txt', False);
  end;
  if RTLFileSystem.FileExists('MusicChange.txt') then
  begin
    MainDataConfig.GetBlock('Music').Clear;
    MainDataConfig.GetBlock('Music').LoadFromTextFileWithEncodingProbe('MusicChange.txt', False);
  end;
  CacheDataRoot.AddMissingFromBlock(LanguageDataConfig.GetBlockByPath('PlanetQuest'));
  GlobalCache := TCacheEC.Create;
  GlobalCache.SetDataRoot(CacheDataRoot);
  GlobalCache.ResidentByteLimit := 0;
  if UserSettingsConfig.CountParams('CacheSize') > 0 then
    GlobalCache.ResidentByteLimit :=
        (ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('CacheSize')) shl 10) shl 10;
  if GlobalCache.ResidentByteLimit <= $1000000 then
    GlobalCache.ResidentByteLimit := $18000000;
  AppendLogLineThreadSafe('Cache Size=' + IntToStr(GlobalCache.ResidentByteLimit div 1024) + ' KB');
  if UserSettingsConfig.CountParams('Brightness') > 0 then
    DisplayBrightness :=
        ParseDecimalToSingleW(UserSettingsConfig.GetParamByPathOrMarker('Brightness'));
  if UserSettingsConfig.CountParams('Contrast') > 0 then
    DisplayContrast := ParseDecimalToSingleW(UserSettingsConfig.GetParamByPathOrMarker('Contrast'));
  if UserSettingsConfig.CountParams('RobotBrightness') > 0 then
    RobotBrightness :=
        ParseDecimalToSingleW(UserSettingsConfig.GetParamByPathOrMarker('RobotBrightness'));
  if UserSettingsConfig.CountParams('RobotContrast') > 0 then
    RobotContrast :=
        ParseDecimalToSingleW(UserSettingsConfig.GetParamByPathOrMarker('RobotContrast'));
  if UserSettingsConfig.CountParams('3D') > 0 then
    ThreeDimensionalModeEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('3D'));
  UiStyleConfig := MainDataConfig.GetBlockByPath('ML');
  GameDataConfig := MainDataConfig.GetBlockByPath('Data');
  LoadInformationColorTags;
  UiDepthConfig := MainDataConfig.GetBlockByPath('ZPos');
  PlanetDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('Planet'));
  ShipPathDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathShip'));
  ShipPathEndDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathEndShip'));
  UnitPathDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPath'));
  UnitPathEndDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathEnd'));
  ActionButtonDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ButtonAction'));
  GalaxyStarDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyStar'));
  GalaxyStarNameDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyStarName'));
  GalaxyWarDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyWar'));
  ConstellationLineDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ConstellationLine'));
  ConstellationColorDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ConstellationColor'));
  if UserSettingsConfig.CountParamsByPath('Sound') > 0 then
    SoundEnabled := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('Sound'));
  if UserSettingsConfig.CountParamsByPath('SoundInSpace') > 0 then
    SoundInSpaceEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SoundInSpace'));
  if UserSettingsConfig.CountParamsByPath('SoundVolume') > 0 then
    SoundVolume :=
        StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('SoundVolume'))) / 100;
  if SoundVolume > 1 then
    SoundVolume := 1;
  if SoundVolume < 0 then
    SoundVolume := 0;
  if UserSettingsConfig.CountParamsByPath('RobotSoundVolume') > 0 then
    RobotSoundVolume :=
        StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('RobotSoundVolume'))) / 100;
  if RobotSoundVolume > 1 then
    RobotSoundVolume := 1;
  if RobotSoundVolume < 0 then
    RobotSoundVolume := 0;
  if not IsInstallFeatureEnabled('Sound') then
    SoundEnabled := False;
  if not IsInstallFeatureEnabled('SoundInSpace') then
    SoundInSpaceEnabled := False;
  if UserSettingsConfig.CountParamsByPath('Music') > 0 then
    MusicEnabled := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('Music'));
  if UserSettingsConfig.CountParamsByPath('MusicInSpace') > 0 then
    MusicInSpaceEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('MusicInSpace'));
  if UserSettingsConfig.CountParamsByPath('MusicInHyper') > 0 then
    MusicInHyperEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('MusicInHyper'));
  if UserSettingsConfig.CountParamsByPath('MusicInPlanet') > 0 then
    MusicInPlanetEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('MusicInPlanet'));
  if UserSettingsConfig.CountParamsByPath('MusicVolume') > 0 then
    MusicVolume :=
        StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('MusicVolume'))) / 100;
  if MusicVolume > 1 then
    MusicVolume := 1;
  if MusicVolume < 0 then
    MusicVolume := 0;
  if UserSettingsConfig.CountParamsByPath('RobotMusicVolume') > 0 then
    RobotMusicVolume :=
        StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('RobotMusicVolume'))) / 100;
  if RobotMusicVolume > 1 then
    RobotMusicVolume := 1;
  if RobotMusicVolume < 0 then
    RobotMusicVolume := 0;
  if not IsInstallFeatureEnabled('Music') then
    MusicEnabled := False;
  if not IsInstallFeatureEnabled('MusicInSpace') then
    MusicInSpaceEnabled := False;
  Block := LanguageDataConfig.GetBlock('CaseConv');
  Count := Block.GetParamCount;
  SetLength(WideCaseTable, Count);
  for Index := 0 to Count - 1 do
  begin
    WideCaseTable[Index].LowerChar := Block.GetParamName(Index)[1];
    WideCaseTable[Index].UpperChar := Block.GetParamValue(Index)[1];
  end;
  AppendLogLineThreadSafe('Loading configuration files.... ok!');
  AppendLogLineThreadSafe('Creating window.... ok!');
  if SoundEnabled then
    AppendLogLineThreadSafe('Sound interfaces are:')
  else
    AppendLogLineThreadSafe('Sound is disabled...');
  if sr_is_headless <> 0 then
  begin
    SoundEnabled := False;
    MusicEnabled := False
  end;
  SoundManager := TSoundControl.Create;
  MusicManager := TMusicControl.Create;
  if XonarSoundDevice then
    if (UserSettingsConfig.CountParams('RunWithXonarWithoutWarning') = 0)
        or not ParseEnabledNameGI(
            TrimWideString(
                UserSettingsConfig.GetParamByPathOrMarker('RunWithXonarWithoutWarning')
            )) then
    begin
      if UserSettingsConfig.CountParams('RunWithXonarWithoutWarning') = 0 then
        UserSettingsConfig.AddParam('RunWithXonarWithoutWarning', 'True')
      else
        UserSettingsConfig.SetOrAddParam('RunWithXonarWithoutWarning', 'True');
      Text := GetGameUserDirectory + 'CFG.TXT';
      UserSettingsConfig.SaveTextFile(PWideChar(Text), True, False);
      ShowXonarWarning := True;
    end;
  GR_DXInit;
  ScreenCenterX := Cardinal(GameScreenWidth) shr 1;
  ScreenCenterY := Cardinal(GameScreenHeight) shr 1;
  ShowAndFocusMainWindow;
  if not ShowSystemMouse then
    ShowCursor(False);
  AppendLogLineThreadSafe(AnsiString('Sound=' + BoolToWideString(SoundEnabled)));
  AppendLogLineThreadSafe(AnsiString('Music=' + BoolToWideString(MusicEnabled)));
  InterfaceBlendPalette := AllocEC(512);
  for Index := 0 to 255 do
  begin
    WriteWordEC(
        AddPointerOffset(InterfaceBlendPalette, 2 * Index),
        CurrentPixelFormat.PackRgbBytes(8, 32, 255)
    );
    BlendPixel16(
        AddPointerOffset(InterfaceBlendPalette, 2 * Index),
        CurrentPixelFormat.PackRgbBytes(200, 128, 128),
        Index
    );
  end;
  if RecordingFrameBuffers <> nil then
  begin
    for Index := 0 to RecordingFrameBuffers.Count - 1 do
      FreeEC(RecordingFrameBuffers[Index]);
    RecordingFrameBuffers.Clear;
    RecordingFrameBuffers.Free;
    RecordingFrameBuffers := nil;
  end;
  if UserSettingsConfig.CountParamsByPath('FilmBufSize') > 0 then
  begin
    BufferSize := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('FilmBufSize'));
    if BufferSize > 0 then
    begin
      RecordingFrameBuffers := TList.Create;
      Count := ((BufferSize shl 10) shl 10) div (GameScreenWidth * GameScreenHeight * 2) + 1;
      AppendLogLineThreadSafe('FilmFrame=' + IntToStr(Count));
      for Index := 0 to Count - 1 do
      begin
        Frame := AllocEC(GameScreenWidth * GameScreenHeight * 2);
        RecordingFrameBuffers.Add(Frame);
      end;
    end;
  end;
  if UserSettingsConfig.CountParamsByPath('FilmFPS') > 0 then
    RecordingFrameInterval :=
        1000 div ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('FilmFPS'));
  Block := MainDataConfig.GetBlockByPath('Graph.Cursor');
  for Index := 0 to Block.GetBlockCount - 1 do
  begin
    Cursor := AddCursorUnit;
    Cursor.Name := Block.GetBlockNameByIndex(Index);
    Cursor.ImagePath := Block.GetBlockByIndex(Index).GetParam('Image');
    Cursor.HotSpot := GetPointGI(Block.GetBlockByIndex(Index).GetParam('Sme'));
  end;
  if LanguageDataConfig.GetParamByPathOrMarker('BV.BV') <> '2.1.2500' then
  begin
    AppendLogLineThreadSafe('Build version mismatch with Lang.dat!');
    BuildVersionMismatch := True;
  end;
  if MainDataConfig.GetParamByPathOrMarker('BV.BV') <> '2.1.2500' then
  begin
    AppendLogLineThreadSafe('Build version mismatch with Main.dat!');
    BuildVersionMismatch := True;
  end;
  if CacheDataRoot.FindEntry('BV').ChildData.FindEntry('BV').SharedFileRef.FileRef.FileName
      <> '2.1.2500' then
  begin
    AppendLogLineThreadSafe('Build version mismatch with CacheData.dat!');
    BuildVersionMismatch := True;
  end;
end;
procedure FinalizeRuntimeAndSettings;
begin
  while not (FirstRegisteredCursor = nil) do
    RemoveCursorUnit(LastRegisteredCursor);
  if InterfaceBlendPalette <> nil then
  begin
    FreeEC(InterfaceBlendPalette);
    InterfaceBlendPalette := nil;
  end;
  if SoundManager <> nil then
    SoundManager.SignalStop;
  if MusicManager <> nil then
  begin
    MusicManager.Free;
    MusicManager := nil;
  end;
  if SoundManager <> nil then
  begin
    SoundManager.Free;
    SoundManager := nil;
  end;
  if GlobalCache <> nil then
  begin
    GlobalCache.Free;
    GlobalCache := nil;
  end;
  if ModShipNameConfig <> nil then
  begin
    ModShipNameConfig.Free;
    ModShipNameConfig := nil;
  end;
  if ModRuinNameConfig <> nil then
  begin
    ModRuinNameConfig.Free;
    ModRuinNameConfig := nil;
  end;
  if UserSettingsConfig <> nil then
  begin
    UserSettingsConfig.Free;
    UserSettingsConfig := nil;
  end;
  FreeScreenRenderBuffers;
  WideCaseTable := nil;
end;
procedure EnumerateAndSelectDisplayModes;
var
  Index, ModeCount: Integer;
  Resolution, ModeKey: WideString;
  SmallestArea: Integer;
  Modes: TBlockParEC;
  Mode: TDisplayModeGR;
  // Native reserves 16 unused local bytes here; original type is unresolved.
  UnusedLocal: array[0..15] of Byte;
begin
  // CHANGE: PORTABILITY - Feed SDL display modes into the original resolution selection.
  if sr_display_mode(
          -1,
          DesktopDisplayMode.Width,
          DesktopDisplayMode.Height,
          DesktopDisplayMode.RefreshRate)
      = 0 then
  begin
    DesktopDisplayMode.Width := 1024;
    DesktopDisplayMode.Height := 768;
    DesktopDisplayMode.RefreshRate := 60;
  end;
  DesktopDisplayMode.Format := D3DFMT_X8R8G8B8;
  FillChar(Mode, SizeOf(Mode), 0);
  GameDisplayModeCount := 0;
  SelectedGameDisplayMode := -1;
  SmallestGameDisplayMode := -1;
  SmallestArea := -1;
  RobotDisplayModeCount := 0;
  SelectedRobotDisplayMode := -1;
  Resolution := '';
  if UserSettingsConfig.CountParams('VideoMode') > 0 then
    Resolution := TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('VideoMode'));
  if CountDelimitedPartsW(Resolution, ',') > 1 then
  begin
    GameScreenWidth := ExtractDigitsToIntW(ExtractDelimitedPartW(Resolution, 0, ','));
    GameScreenHeight := ExtractDigitsToIntW(ExtractDelimitedPartW(Resolution, 1, ','));
    RequestedRefreshRate := 0;
    if CountDelimitedPartsW(Resolution, ',') > 2 then
      RequestedRefreshRate := ExtractDigitsToIntW(ExtractDelimitedPartW(Resolution, 2, ','));
  end
  else
  begin
    GameScreenWidth := 0;
    GameScreenHeight := 0;
    RequestedRefreshRate := 0;
  end;
  // Native keeps the VideoMode text when RobotResolution is absent.
  if UserSettingsConfig.CountParams('RobotResolution') > 0 then
    Resolution := TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('RobotResolution'));
  if CountDelimitedPartsW(Resolution, ',') > 1 then
  begin
    RobotSettings.ScreenWidth := ExtractDigitsToIntW(ExtractDelimitedPartW(Resolution, 0, ','));
    RobotSettings.ScreenHeight := ExtractDigitsToIntW(ExtractDelimitedPartW(Resolution, 1, ','));
  end
  else
  begin
    RobotSettings.ScreenWidth := 0;
    RobotSettings.ScreenHeight := 0;
  end;
  UseDesktopDisplayMode := False;
  if (Cardinal(GameScreenWidth) < 1024) or (Cardinal(GameScreenHeight) < 720) then
  begin
    GameScreenWidth := DesktopDisplayMode.Width;
    GameScreenHeight := DesktopDisplayMode.Height;
    UseDesktopDisplayMode := True;
  end;
  UseAutomaticRobotDisplayMode := False;
  if (RobotSettings.ScreenWidth < 1024) or (RobotSettings.ScreenHeight < 720) then
    UseAutomaticRobotDisplayMode := True;
  ModeCount := sr_display_mode_count;
  if (DesktopDisplayMode.Format <> D3DFMT_X8R8G8B8)
      and (DesktopDisplayMode.Format <> D3DFMT_A8R8G8B8) then
    DesktopDisplayMode.Format := D3DFMT_X8R8G8B8;
  Modes := TBlockParEC.Create;
  for Index := 0 to ModeCount - 1 do
  begin
    if sr_display_mode(Index, Mode.Width, Mode.Height, Mode.RefreshRate) = 0 then
      Continue;
    Mode.Format := DesktopDisplayMode.Format;
    if Mode.Height >= 720 then
    begin
      ModeKey := SysUtils.IntToHex(Int64(Mode.Width), 6) + SysUtils.IntToHex(Int64(Mode.Height), 6);
      if (Modes.CountParams(ModeKey) <= 0)
          or (SysUtils.StrToInt(AnsiString(ExtractDelimitedPartW(Modes.GetParam(ModeKey), 0, ',')))
              < Integer(Mode.RefreshRate)) then
        Modes.SetOrAddParam(
            ModeKey,
            WideString(SysUtils.IntToStr(Int64(Mode.RefreshRate)) + ',' + SysUtils.IntToStr(Index))
        );
    end;
  end;
  GameDisplayModeCount := Modes.GetParamCount;
  RobotDisplayModeCount := Modes.GetParamCount;
  SetLength(GameDisplayModes, GameDisplayModeCount + 2);
  SetLength(RobotDisplayModes, RobotDisplayModeCount + 2);
  AppendLogLineThreadSafe(
      'Desktop Resolution='
          + SysUtils.IntToStr(Int64(DesktopDisplayMode.Width))
          + 'x'
          + SysUtils.IntToStr(Int64(DesktopDisplayMode.Height))
  );
  AppendLogTextThreadSafe('Available Resolutions=');
  for Index := 0 to Modes.GetParamCount - 1 do
  begin
    ModeKey := Modes.GetParamValue(Index);
    sr_display_mode(
        SysUtils.StrToInt(AnsiString(ExtractDelimitedPartW(ModeKey, 1, ','))),
        Mode.Width,
        Mode.Height,
        Mode.RefreshRate
    );
    GameDisplayModes[Index] := Mode;
    RobotDisplayModes[Index] := Mode;
    if (SmallestArea < 0) or (Integer(Mode.Width * Mode.Height) < SmallestArea) then
    begin
      SmallestArea := Mode.Width * Mode.Height;
      SmallestGameDisplayMode := Index;
    end;
    if (Mode.Width = Cardinal(GameScreenWidth)) and (Mode.Height = Cardinal(GameScreenHeight)) then
      SelectedGameDisplayMode := Index;
    if (Cardinal(RobotSettings.ScreenWidth) = Mode.Width)
        and (Cardinal(RobotSettings.ScreenHeight) = Mode.Height) then
      SelectedRobotDisplayMode := Index;
    if Index > 0 then
      AppendLogTextThreadSafe(', ');
    AppendLogTextThreadSafe(
        SysUtils.IntToStr(Int64(Mode.Width)) + 'x' + SysUtils.IntToStr(Int64(Mode.Height))
    );
  end;
  Modes.Free;
  if GameDisplayModeCount = 0 then
  begin
    AppendLogTextThreadSafe('No supported resolutions found!');
    if (Cardinal(GameScreenWidth) < 1024) or (Cardinal(GameScreenHeight) < 720) then
    begin
      AlternateViewportEnabled := True;
      ViewportOffset := Classes.Point(0, 0);
      PresentationWidth := GameScreenWidth;
      PresentationHeight := GameScreenHeight;
      RobotSettings.ScreenWidth := GameScreenWidth;
      RobotSettings.ScreenHeight := GameScreenHeight;
      if ScaleViewportToWindow then
      begin
        if Cardinal(GameScreenWidth) > Cardinal(GameScreenHeight) then
        begin
          GameScreenHeight := 720;
          GameScreenWidth :=
              Cardinal(GameScreenHeight * PresentationWidth) div Cardinal(PresentationHeight);
        end
        else
        begin
          GameScreenWidth := 1024;
          GameScreenHeight :=
              Cardinal(GameScreenWidth * PresentationHeight) div Cardinal(PresentationWidth);
        end;
      end
      else
      begin
        GameScreenWidth := Math.Max(1024, Int64(Cardinal(GameScreenWidth)));
        GameScreenHeight := Math.Max(720, Int64(Cardinal(GameScreenHeight)));
      end;
      HardwareRenderingEnabled := False;
    end;
  end;
  GameDisplayModes[GameDisplayModeCount].Width := 0;
  GameDisplayModes[GameDisplayModeCount].Height := 0;
  GameDisplayModes[GameDisplayModeCount].RefreshRate := DesktopDisplayMode.RefreshRate;
  RobotDisplayModes[RobotDisplayModeCount].Width := 0;
  RobotDisplayModes[RobotDisplayModeCount].Height := 0;
  if UseDesktopDisplayMode then
    SelectedGameDisplayMode := GameDisplayModeCount;
  if UseAutomaticRobotDisplayMode then
    SelectedRobotDisplayMode := RobotDisplayModeCount;
  Inc(GameDisplayModeCount);
  Inc(RobotDisplayModeCount);
  if SelectedGameDisplayMode = -1 then
  begin
    SelectedGameDisplayMode := GameDisplayModeCount;
    GameDisplayModes[SelectedGameDisplayMode].Width := GameScreenWidth;
    GameDisplayModes[SelectedGameDisplayMode].Height := GameScreenHeight;
    Inc(GameDisplayModeCount);
  end;
  if SelectedRobotDisplayMode = -1 then
  begin
    SelectedRobotDisplayMode := RobotDisplayModeCount;
    RobotDisplayModes[SelectedRobotDisplayMode].Width := RobotSettings.ScreenWidth;
    RobotDisplayModes[SelectedRobotDisplayMode].Height := RobotSettings.ScreenHeight;
    Inc(RobotDisplayModeCount);
  end;
  AppendLogLineThreadSafe('');
  ExtraScreenWidth := GameScreenWidth - 1024;
  ExtraScreenHeight := GameScreenHeight - 768;
  GameScreenRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  PresentationRect := Classes.Rect(0, 0, PresentationWidth, PresentationHeight);
end;
procedure ConfigureDefaultRenderState;
begin
  Direct3DDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
  Direct3DDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
  Direct3DDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
  Direct3DDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Direct3DDevice.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);
  Direct3DDevice.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
  Direct3DDevice.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
  Direct3DDevice.SetRenderState(D3DRS_SCISSORTESTENABLE, 1);
  Direct3DDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
end;
procedure PreparePresentationParameters;
begin
  PreviousPresentParameters := Direct3DPresentParameters;
  with Direct3DPresentParameters do
  begin
    ZeroMemory(@Direct3DPresentParameters, SizeOf(Direct3DPresentParameters));
    Windowed := WindowedModeRequested and (Cardinal(GameScreenHeight) < DesktopDisplayMode.Height);
    DeviceWindow := MainWindowHandle;
    if DisableTripleBuffer then
      BackBufferCount := 1
    else
      BackBufferCount := 2;
    BackBufferFormat := DesktopDisplayMode.Format;
    PresentationInterval := D3DPRESENT_INTERVAL_IMMEDIATE;
    if Windowed then
    begin
      if VSyncEnabled then
        PresentationInterval := D3DPRESENT_INTERVAL_DEFAULT;
      SwapEffect := D3DSWAPEFFECT_DISCARD;
    end
    else
    begin
      if VSyncEnabled then
        PresentationInterval := D3DPRESENT_INTERVAL_ONE;
      SwapEffect := D3DSWAPEFFECT_FLIP;
      if UseDesktopDisplayMode then
      begin
        BackBufferWidth := DesktopDisplayMode.Width;
        BackBufferHeight := DesktopDisplayMode.Height;
        FullScreenRefreshRateInHz := DesktopDisplayMode.RefreshRate;
      end
      else
      begin
        BackBufferWidth := GameDisplayModes[SelectedGameDisplayMode].Width;
        BackBufferHeight := GameDisplayModes[SelectedGameDisplayMode].Height;
        if RequestedRefreshRate > 0 then
          FullScreenRefreshRateInHz := RequestedRefreshRate
        else
          FullScreenRefreshRateInHz := GameDisplayModes[SelectedGameDisplayMode].RefreshRate;
      end;
    end;
    PresentationFrameRate := FullScreenRefreshRateInHz;
    if PresentationFrameRate = 0 then
      PresentationFrameRate := DesktopDisplayMode.RefreshRate;
    if PresentationFrameRate = 0 then
      PresentationFrameRate := 50;
  end;
end;
procedure GR_DXInit;

var
  I, MiniMapSize: Integer;
  Angle: Single;

begin
  FreeScreenRenderBuffers;
  HardwareRenderingEnabled := False;
  HardwareRenderingRequested := False;
  ThreeDimensionalModeEnabled := False;
  WindowedModeRequested := True;
  VSyncEnabled := True;
  if UserSettingsConfig.CountParams('VSync') > 0 then
    VSyncEnabled := ParseEnabledNameGI(UserSettingsConfig.GetParam('VSync'));
  if UserSettingsConfig.CountParams('Window') > 0 then
    WindowedModeRequested := ParseEnabledNameGI(UserSettingsConfig.GetParam('Window'));
  Direct3DPresentParameters.Windowed := WindowedModeRequested;
  ScaleViewportToWindow := True;
  AlternateViewportEnabled := False;
  EnumerateAndSelectDisplayModes;
  PresentationWidth := GameScreenWidth;
  PresentationHeight := GameScreenHeight;
  PresentationRect := GameScreenRect;
  PresentationFrameRate := DesktopDisplayMode.RefreshRate;
  if sr_window_open(GameScreenWidth, GameScreenHeight) = 0 then
    raise Exception.Create('SDL window: ' + string(sr_error));

  HardwareRenderingEnabled := sr_gpu_active <> 0;
  HardwareRenderingRequested := HardwareRenderingEnabled;
  if HardwareRenderingEnabled then
  begin
    Direct3DDevice := CreateSDLDevice(GameScreenWidth, GameScreenHeight);
    MaxTextureSize := Types.Point(4096, 4096);
    ConfigureDefaultRenderState;
  end;
  AppendLogLineThreadSafe(
      'Renderer: '
          + string(sr_renderer_name)
          + '; GPU drawing='
          + BoolToStr(HardwareRenderingEnabled, True)
  );

  CurrentPixelFormat := TPixelFormatGR.Create;
  CurrentPixelFormat.RedMask := $F800;
  CurrentPixelFormat.GreenMask := $7E0;
  CurrentPixelFormat.BlueMask := $1F;
  CurrentPixelFormat.AlphaMask := 0;
  CurrentPixelFormat.BytesPerPixel := 2;
  CurrentPixelFormat.RebuildChannelMetrics;
  BlendPixel16 := OKGR_PixelAlpha_16;
  TriangleRasterizer16 := OKGF_Triangle_16;
  LineRasterizer16 := OKGF_LineIp_16;
  ScreenRenderBuffer := TGraphBufGR.Create(False);
  RenderScratchBuffer := TGraphBufGR.Create(False);
  AuxRenderBuffer := TGraphBufGR.Create(False);
  ScreenRenderBuffer.AllocateNativePitch(GameScreenWidth, GameScreenHeight, 2 * GameScreenWidth);
  ScreenRenderBuffer.ClearPixels;
  MiniMapSize := 156;
  if GameDataConfig.CountParams('MiniMapBufSize') > 0 then
    MiniMapSize := ExtractDigitsToIntW(GameDataConfig.GetParam('MiniMapBufSize'));
  RenderScratchBuffer.AllocateNative(MiniMapSize, MiniMapSize);
  for I := 0 to 360 do
  begin
    Angle := I * (3.1415926 / 180);
    CircleCos[I] := Cos(Angle);
    CircleSin[I] := Sin(Angle)
  end;
  for I := 0 to 359 do
    LineAlphaTable[I] := Trunc(Cos(I / 180 * 3.14159265354) * 127 + 128);
  PendingPointCapacity := 1024;
  SetLength(PendingPoints, PendingPointCapacity);
end;
procedure GR_DXReset;
begin
  if sr_window_options(Ord(WindowedModeRequested), Ord(VSyncEnabled)) = 0 then
    raise Exception.Create('SDL display options: ' + string(sr_error));
  PresentScreenBuffer;
end;
procedure FreeScreenRenderBuffers;
begin
  if RenderScratchBuffer <> nil then
  begin
    RenderScratchBuffer.Free;
    RenderScratchBuffer := nil;
  end;
  if AuxRenderBuffer <> nil then
  begin
    AuxRenderBuffer.Free;
    AuxRenderBuffer := nil;
  end;
  if ScreenRenderBuffer <> nil then
  begin
    ScreenRenderBuffer.Free;
    ScreenRenderBuffer := nil;
  end;
  PresentationDepth := 0;
end;
procedure ApplyGammaRamp(Brightness, Contrast: Single);
var
  Index, Value: Integer;
  LowInput, LowOutput, HighInput, HighOutput: Single;
  LowIndex, HighIndex: Integer;
  Level, Step: Single;
  Ramp: TD3DGammaRamp;
begin
  if Brightness >= 0 then
  begin
    LowInput := 0;
    LowOutput := Brightness * 0.5;
    HighInput := 1 - Brightness * 0.5;
    HighOutput := 1;
  end
  else
  begin
    LowInput := -Brightness * 0.5;
    LowOutput := 0;
    HighInput := 1;
    HighOutput := 1 - -Brightness * 0.5;
  end;
  Step := (HighOutput - LowOutput) / (HighInput - LowInput);
  Level := (0.5 - LowInput) * Step + LowOutput;
  LowInput := LowInput + 0.4 * Contrast * Level;
  HighInput := HighInput - (1 - Level) * (0.4 * Contrast);
  LowIndex := Round(LowInput * 255);
  HighIndex := Round(HighInput * 255);
  Value := Round(Max(0, LowOutput) * 65535);
  for Index := 0 to LowIndex - 1 do
  begin
    Ramp.Red[Index] := Value;
    Ramp.Green[Index] := Value;
    Ramp.Blue[Index] := Value;
  end;
  Level := LowOutput;
  Step := (HighOutput - LowOutput) / (HighIndex - LowIndex);
  for Index := LowIndex to HighIndex - 1 do
  begin
    if (Index >= 0) and (Index <= 255) then
    begin
      Value := Round(Max(0, Level) * 65535);
      if Value < 0 then
        Value := 0
      else if Value > 65535 then
        Value := 65535;
      Ramp.Red[Index] := Value;
      Ramp.Green[Index] := Value;
      Ramp.Blue[Index] := Value;
    end;
    Level := Level + Step;
  end;
  Value := Round(Min(1.0, HighOutput) * 65535);
  for Index := HighIndex to 255 do
  begin
    Ramp.Red[Index] := Value;
    Ramp.Green[Index] := Value;
    Ramp.Blue[Index] := Value;
  end;
  sr_set_gamma(@Ramp.Red[0], @Ramp.Green[0], @Ramp.Blue[0]);
end;
function GR_WinMessage(Callback: TWindowMessageCallbackGR): Integer;

var
  E: TNativeEvent;

begin

  if SoundManager <> nil then
    SoundManager.UpdateFades;
  if MusicManager <> nil then
    MusicManager.Update;
  while sr_poll(E) <> 0 do
  begin
    case E.Message of
      WM_CLOSE:
      begin
        ExitScreenLoop := True;
        Exit(0)
      end;
      WM_ACTIVATEAPP:
      begin
        RuntimeActive := E.WParam <> 0;
        Application.Active := RuntimeActive
      end;
      WM_PAINT:
        if ScreenRenderBuffer <> nil then
          PresentScreenBuffer;
    end;
    if Assigned(Callback) then
      Callback(E.Message, E.WParam, E.LParam);
  end;
  if ExitScreenLoop then
    Result := 0
  else
    Result := 1;

  // The continuous loop accounts for its own sleep. An active-window sleep
  // here falls outside that clock and makes film playback slower than real time.
  if not RuntimeActive then
    Sleep(10);

end;
function MainWindowProc(Window, Message, WParam: Cardinal; LParam: Integer): Integer; stdcall;
begin
  if Message = WM_CLOSE then
    ExitScreenLoop := True;
  Result := 0
end;
function BeginFramePresentation: Boolean;
begin
  Inc(PresentationDepth);
  Result := True;
end;
procedure EndFramePresentation;
begin
  if PresentationDepth > 0 then
  begin
    Dec(PresentationDepth);

    if PresentationDepth = 0 then
      // SDL owns presentation pacing. The old millisecond gate discarded
      // frames and competed with VSync's refresh boundary.
      PresentScreenBuffer;

  end;
end;
procedure PresentScreenBuffer;
begin
  if ScreenRenderBuffer = nil then
    Exit;

  if HardwareRenderingEnabled then
  begin
    if sr_gpu_present = 0 then
      raise Exception.Create('SDL GPU presentation: ' + string(sr_error));
    Exit;
  end;

  if sr_present(ScreenRenderBuffer.GetPixels, ScreenRenderBuffer.PitchBytes) = 0 then
    raise Exception.Create('SDL presentation: ' + string(sr_error));
end;
procedure DrawOffscreenTexture;
var
  X, Y: Integer;
  Width, Height, ViewWidth, ViewHeight: Cardinal;
  Desc: TD3DSurfaceDesc;
begin
  if OffscreenTexture <> nil then
  begin
    if not OffscreenFrameUpdated then
      if timeGetTime - OffscreenLastPresentationTick < 100 then
        Exit;
    OffscreenLastPresentationTick := timeGetTime;
    OffscreenTexture.GetLevelDesc(0, Desc);
    if AlternateViewportEnabled then
    begin
      ViewWidth := PresentationWidth;
      ViewHeight := PresentationHeight;
    end
    else
    begin
      ViewWidth := GameScreenWidth;
      ViewHeight := GameScreenHeight;
    end;
    Width := ViewWidth;
    Height := Round((Desc.Height / Desc.Width) * ViewWidth);
    if ((Height > ViewHeight) and not OffscreenFillViewport)
        or ((Height < ViewHeight) and (OffscreenFillViewport <> False)) then
    begin
      Width := Round((Desc.Width / Desc.Height) * ViewHeight);
      Height := ViewHeight;
    end;
    X := Integer(ViewWidth - Width) div 2;
    Y := Integer(ViewHeight - Height) div 2;
    Direct3DDevice.Clear(0, nil, D3DCLEAR_TARGET, 0, 1, 0);
    if HardwareRenderingEnabled then
      DrawTextureSized(
          OffscreenTexture,
          X,
          Y,
          Width,
          Height,
          255,
          $FFFFFF,
          @GameScreenRect,
          False,
          False
      )
    else
    begin
      Direct3DDevice.BeginScene;
      DrawTextureSized(
          OffscreenTexture,
          X,
          Y,
          Width,
          Height,
          255,
          $FFFFFF,
          @GameScreenRect,
          False,
          False
      );
      Direct3DDevice.EndScene;
      Direct3DDevice.Present(nil, nil, 0, nil);
    end;
  end;
end;
procedure CaptureScreenBackground(ApplyEffects: Boolean; UnusedOption: Byte);
begin
  AuxRenderBuffer.LoadFromScreen(UnusedOption);
  if ApplyEffects then
  begin
    if BackgroundShade then
      AuxRenderBuffer.AdjustBrightness(-50);
    if BackgroundGrayscale then
      AuxRenderBuffer.ConvertToGrayscale;
  end;
end;
procedure CaptureSavePreview;
begin
  FreeSavePreviewBuffers;
  SavePreviewGraph := TGraphBufGR.Create(False);
  SavePreviewGraph.LoadFromScreen(0);
  if HardwareRenderingEnabled then
  begin
    SavePreviewGraph.RescaleWithAspect(300, 225, True, 1, 1, 5);
    SavePreviewGraph.ConvertBgraToRgb24;
  end
  else
  begin
    SavePreviewGraph.Convert565ToRgb;
    SavePreviewGraph.RescaleWithAspect(300, 225, True, 1, 1, 5);
  end;
  SecondarySavePreviewGraph := TGraphBufGR.Create(False);
  SecondarySavePreviewGraph.AllocateNativePitch(300, 225, 900);
end;
procedure FreeSavePreviewBuffers;
begin
  if SavePreviewGraph <> nil then
  begin
    SavePreviewGraph.Free;
    SavePreviewGraph := nil;
  end;
  if SecondarySavePreviewGraph <> nil then
  begin
    SecondarySavePreviewGraph.Free;
    SecondarySavePreviewGraph := nil;
  end;
end;
procedure CopyBgraToRgb24(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch, Width, Height: Integer
);
var
  X, Y: Integer;
begin
  Y := 0;
  while Y < Height do
  begin
    X := 0;
    while X < Width do
    begin
      PByte(AddPointerOffset(Dest, X * 3))^ := PByte(AddPointerOffset(Source, X * 4 + 2))^;
      PByte(AddPointerOffset(Dest, X * 3 + 1))^ := PByte(AddPointerOffset(Source, X * 4 + 1))^;
      PByte(AddPointerOffset(Dest, X * 3 + 2))^ := PByte(AddPointerOffset(Source, X * 4))^;
      Inc(X);
    end;
    Dest := AddPointerOffset(Dest, DestPitch);
    Source := AddPointerOffset(Source, SourcePitch);
    Inc(Y);
  end;
end;
procedure CaptureRecordingFrame;
begin
  if timeGetTime - LastRecordingFrameTick >= Cardinal(RecordingFrameInterval) then
  begin
    Ex_OKGR_Copy_XY_XY_WORD(
        RecordingFrameBuffers[RecordingFrameCount],
        GameScreenWidth * 2,
        0,
        0,
        ScreenRenderBuffer.GetPixels,
        ScreenRenderBuffer.PitchBytes,
        0,
        0,
        GameScreenWidth,
        GameScreenHeight
    );
    Inc(RecordingFrameCount);
    if RecordingFrameCount >= RecordingFrameBuffers.Count then
      FlushRecordingFrames;
    LastRecordingFrameTick := timeGetTime;
  end;
end;
procedure FlushRecordingFrames;
begin
  if RecordingFrameCount <> 0 then
    raise Exception.Create('Recording is disabled in the FPC port')
end;
procedure DrawTransparentBuffer16(
    Dest: Pointer;
    Pitch, X, Y: Integer;
    Source: Pointer;
    Clip: TRect;
    HalfAlpha: Boolean
);
var
  InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  if HalfAlpha then
    Ex_OKGR_TransBuf_HADrawClip_16(Dest, Pitch, X, Y, Source, InclusiveClip)
  else
    Ex_OKGR_TransBuf_DrawClip_WORD(Dest, Pitch, X, Y, Source, InclusiveClip);
end;
procedure CopyPalettedBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source, Palette: Pointer;
    SourcePitch, Width, Height: Integer;
    constref Clip: TRect
);
var
  SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (X + Width - 1 < Clip.Left)
      or (Y + Height - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_PalCopy_XY_XY_WORD(
      Dest,
      DestPitch,
      X,
      Y,
      Source,
      SourcePitch,
      SourceX,
      SourceY,
      Palette,
      Width,
      Height
  );
end;
procedure CopyGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect;
    HalfAlpha, UnusedOption: Boolean
);
var
  SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (Source.Width + X - 1 < Clip.Left)
      or (Source.Height + Y - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  if HalfAlpha then
    Ex_OKGR_HACopy_XY_XY_16(
        Dest,
        DestPitch,
        X,
        Y,
        Source.GetPixels,
        Source.PitchBytes,
        SourceX,
        SourceY,
        Width,
        Height
    )
  else
    Ex_OKGR_Copy_XY_XY_WORD(
        Dest,
        DestPitch,
        X,
        Y,
        Source.GetPixels,
        Source.PitchBytes,
        SourceX,
        SourceY,
        Width,
        Height
    );
end;
procedure CopyBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: Pointer;
    SourcePitch, Width, Height: Integer;
    Clip: TRect;
    UnusedOption: Boolean
);
var
  SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (X + Width - 1 < Clip.Left)
      or (Y + Height - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_Copy_XY_XY_WORD(
      Dest,
      DestPitch,
      X,
      Y,
      Source,
      SourcePitch,
      SourceX,
      SourceY,
      Width,
      Height
  );
end;
procedure CopyTransparentGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect;
    TransparentColor: Word
);
var
  SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (Source.Width + X - 1 < Clip.Left)
      or (Source.Height + Y - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_CopyTrans_XY_XY_WORD(
      Dest,
      DestPitch,
      X,
      Y,
      Source.GetPixels,
      Source.PitchBytes,
      SourceX,
      SourceY,
      Width,
      Height,
      TransparentColor
  );
end;
procedure DrawAlphaGraphBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: TGraphBufGR;
    Clip: TRect
);
var
  SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (Source.Width + X - 1 < Clip.Left)
      or (Source.Height + Y - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_AlphaSimpleBuf_Draw_16(
      Dest,
      DestPitch,
      X,
      Y,
      Source.GetPixels,
      Source.PitchBytes,
      SourceX,
      SourceY,
      Width,
      Height
  );
end;
procedure DrawAlphaBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: Pointer;
    SourcePitch, Width, Height: Integer;
    constref Clip: TRect
);
var
  SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (X + Width - 1 < Clip.Left)
      or (Y + Height - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_AlphaSimpleBuf_Draw_16(
      Dest,
      DestPitch,
      X,
      Y,
      Source,
      SourcePitch,
      SourceX,
      SourceY,
      Width,
      Height
  );
end;
procedure DrawPaletteAlphaBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: TGraphBufPalGR;
    Clip: TRect
);
var
  SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (X + 0 + Source.Width - 1 < Clip.Left)
      or (Y + 0 + Source.Height - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  Ex_OKGR_AlphaSimpleBufPalAlpha_Draw_16(
      Dest,
      DestPitch,
      X,
      Y,
      Source.Pixels,
      Source.PitchBytes,
      SourceX,
      SourceY,
      Width,
      Height,
      Source.Palette
  );
end;
procedure ExpandPaletteToBgra(
    Dest: Pointer;
    DestPitch: Integer;
    Width, Height: Cardinal;
    Source: Pointer;
    SourcePitch: Integer;
    Palette: Pointer
);
var
  X, Y: Cardinal;
  Offset: Cardinal;
begin
  for Y := 0 to Height - 1 do
  begin
    for X := 0 to Width - 1 do
    begin
      Offset := PByte(PtrUInt(Source) + X)^ shl 2;
      PByte(PtrUInt(Dest) + X * 4)^ := PByte(PtrUInt(Palette) + Offset + 2)^;
      PByte(PtrUInt(Dest) + X * 4 + 1)^ := PByte(PtrUInt(Palette) + Offset + 1)^;
      PByte(PtrUInt(Dest) + X * 4 + 2)^ := PByte(PtrUInt(Palette) + Offset)^;
      PByte(PtrUInt(Dest) + X * 4 + 3)^ := PByte(PtrUInt(Palette) + Offset + 3)^;
    end;
    Source := AddPointerOffset(Source, SourcePitch);
    Dest := AddPointerOffset(Dest, DestPitch);
  end;
end;
procedure BlendPaletteBuffer16Clipped(
    Dest: Pointer;
    DestPitch, X, Y: Integer;
    Source: TGraphBufPalGR;
    Clip: TRect
);
var
  SourcePixels: Pointer;
  Width: Integer;
  Palette, MulTable: Pointer;
  ColumnCount, SourceSkip, DestSkip, Height: Integer;
  SourceX, SourceY: Integer;
  Color, Alpha, OldPixel, NewPixel, Inverse, RedShift, GreenMask: Cardinal;
begin
  if (X >= Clip.Right)
      or (Y >= Clip.Bottom)
      or (X + Source.Width - 1 < Clip.Left)
      or (Y + Source.Height - 1 < Clip.Top) then
    Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if X + Width - 1 >= Clip.Right then
    Dec(Width, X + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then
    Dec(Height, Y + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  SourcePixels := Pointer(PAnsiChar(Source.Pixels) + SourceY * Source.PitchBytes + SourceX);
  Dest := Pointer(PAnsiChar(Dest) + Y * DestPitch + X * 2);
  SourceSkip := Source.PitchBytes - Width;
  DestSkip := DestPitch - Width * 2;
  MulTable := Ex_OKGF_MulTable256x256;
  Palette := Source.Palette;
  ColumnCount := Width;
  // Preserve the native table lookup, channel truncation and packed addition.
  if CurrentPixelFormat.TotalChannelBits = 16 then
  begin
    RedShift := 8;
    GreenMask := $7E0
  end
  else
  begin
    RedShift := 7;
    GreenMask := $3E0
  end;
  while Height > 0 do
  begin
    for ColumnCount := 0 to Width - 1 do
    begin
      Color := PCardinal(Palette)[PByte(SourcePixels)^];
      Alpha := Color shr 24;
      if Alpha <> 0 then
      begin
        Inverse := (255 - Alpha) * 256;
        Alpha := Alpha * 256;
        OldPixel := PWord(Dest)^;
        NewPixel := (Cardinal(PByte(MulTable)[Alpha + (Color and 255)]) shr 3) shl (RedShift + 3);
        NewPixel :=
            NewPixel
                or ((Cardinal(PByte(MulTable)[Alpha + ((Color shr 8) and 255)]) shl (RedShift - 5))
                    and GreenMask);
        NewPixel := NewPixel or (PByte(MulTable)[Alpha + ((Color shr 16) and 255)] shr 3);
        NewPixel :=
            NewPixel
                + ((Cardinal(PByte(MulTable)[Inverse + ((OldPixel shr RedShift) and $F8)]) shr 3)
                    shl (RedShift + 3));
        NewPixel :=
            NewPixel
                + ((Cardinal(
                            PByte(MulTable)[
                                Inverse
                                    + ((OldPixel shr (RedShift - 5))
                                        and (GreenMask shr (RedShift - 5)))
                            ])
                        shl (RedShift - 5))
                    and GreenMask);
        NewPixel := NewPixel + (PByte(MulTable)[Inverse + ((OldPixel shl 3) and $F8)] shr 3);
        PWord(Dest)^ := Word(NewPixel);
      end;
      Inc(PByte(SourcePixels));
      Inc(PByte(Dest), 2);
    end;
    Inc(PByte(SourcePixels), SourceSkip);
    Inc(PByte(Dest), DestSkip);
    Dec(Height);
  end;
end;
procedure DrawGradientLine16Clipped(
    Pixels: Pointer;
    Pitch, X1, Y1: Integer;
    Color1: Cardinal;
    X2, Y2: Integer;
    Color2: Cardinal;
    Clip: TRect
);
begin
  if Ex_OKGR_LineColor_Clip(X1, Y1, Color1, X2, Y2, Color2, Clip) <> 0 then
    LineRasterizer16(
        ScreenRenderBuffer.GetPixels,
        ScreenRenderBuffer.PitchBytes,
        X1,
        Y1,
        Color1,
        X2,
        Y2,
        Color2
    );
end;
function IsVirtualKeyDown(Key: Integer): Boolean;
begin
  Result := GetAsyncKeyState(Key) and $8000 = $8000;
end;
function LookupLocalizedTextByKey(const Path: WideString): WideString;
begin
  Result := LanguageDataConfig.GetParamByPathOrMarker(Path);
end;
function LookupLocalizedTextOrEmpty(const Path: WideString): WideString;
begin
  if LanguageDataConfig.CountParamsByPath(Path) > 0 then
    Result := LanguageDataConfig.GetParamByPathOrMarker(Path)
  else
    Result := '';
end;
function GiResourceVariant: Integer;
begin
  Result := 2;
end;
function GiResourceSuffix: WideString;
begin
  Result := '2';
end;
function GiScalePixels(Value: Integer): Integer;
begin
  Result := Value;
end;
function GiScalePixelsEx(Value, AlternateValue: Integer): Integer;
begin
  Result := Value;
end;
procedure AppendLogLineThreadSafe(const Text: AnsiString);
begin
  if SessionLogLock = nil then
    SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  Append(SessionLog);
  Writeln(SessionLog, Text);
  CloseFile(SessionLog);

  SessionLogLock.Leave;
end;
procedure AppendLogTextThreadSafe(const Text: AnsiString);
begin
  if SessionLogLock = nil then
    SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  Append(SessionLog);
  Write(SessionLog, Text);
  CloseFile(SessionLog);

  SessionLogLock.Leave;
end;
procedure AppendDebugLogLine(const Text: AnsiString);
var
  Log: TextFile;
begin
  if SessionLogLock = nil then
    SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  AssignFile(Log, '#####add.log');
  if not RTLFileSystem.FileExists('#####add.log') then
    Rewrite(Log)
  else
    Append(Log);
  Writeln(Log, Text);
  CloseFile(Log);
  SessionLogLock.Leave;
end;
procedure AppendOptionalDebugLogLine(const Text: AnsiString);
var
  Log: TextFile;
begin
  if RTLFileSystem.FileExists('#####add.log') then
  begin
    if SessionLogLock = nil then
      SessionLogLock := TCriticalSection.Create;
    SessionLogLock.Enter;
    AssignFile(Log, '#####add.log');
    Append(Log);
    Writeln(Log, Text);
    CloseFile(Log);
    SessionLogLock.Leave;
  end;
end;
procedure WriteTextFileThreadSafe(FileName, Text: AnsiString);
var
  F: TextFile;
begin
  if SessionLogLock = nil then
    SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  AssignFile(F, FileName);
  Rewrite(F);
  Writeln(F, Text);
  CloseFile(F);
  SessionLogLock.Leave;
end;
function IsInstallFeatureEnabled(const Path: WideString): Boolean;
begin
  if InstallConfig.CountParamsByPath(Path) < 1 then
    Result := False
  else
    Result := ParseEnabledNameGI(InstallConfig.GetParamByPathOrMarker(Path));
end;
function AddCursorUnit: TCursorUnit;
var
  Cursor: TCursorUnit;
begin
  Cursor := TCursorUnit.Create;
  if LastRegisteredCursor <> nil then
    LastRegisteredCursor.Next := Cursor;
  Cursor.Prev := LastRegisteredCursor;
  Cursor.Next := nil;
  LastRegisteredCursor := Cursor;
  if FirstRegisteredCursor = nil then
    FirstRegisteredCursor := Cursor;
  Result := Cursor;
end;
procedure RemoveCursorUnit(Cursor: TCursorUnit);
begin
  if Cursor.Prev <> nil then
    Cursor.Prev.Next := Cursor.Next;
  if Cursor.Next <> nil then
    Cursor.Next.Prev := Cursor.Prev;
  if LastRegisteredCursor = Cursor then
    LastRegisteredCursor := Cursor.Prev;
  if FirstRegisteredCursor = Cursor then
    FirstRegisteredCursor := Cursor.Next;
  Cursor.Free;
end;
function FindCursorByName(const Name: WideString): TCursorUnit;
var
  Cursor: TCursorUnit;
begin
  Cursor := FirstRegisteredCursor;
  while Cursor <> nil do
  begin
    if Cursor.Name = Name then
    begin
      Result := Cursor;
      Exit;
    end;
    Cursor := Cursor.Next;
  end;
  raise Exception.Create('GR_CursorFind');
end;
procedure PostMouseMoveMessage;
var
  Point: TPoint;
begin
  GetCursorPos(Point);
  ScreenToClient(MainWindowHandle, Point);
  PostMessage(MainWindowHandle, WM_MOUSEMOVE, 0, Word(Point.X) or (Word(Point.Y) shl 16));
end;
function MeasureCpuClockMHz: Double;
begin
  Result := 0
end;
function ReadRegistryText(Root: Cardinal; KeyPath, ValueName, DefaultValue: WideString): WideString;
begin
  Result := DefaultValue
end;
function ReadRegistryInteger(
    Root: Cardinal;
    KeyPath, ValueName: WideString;
    DefaultValue: Integer
): Integer;
begin
  Result := DefaultValue
end;
procedure RaiseWideMessage(const Message: WideString);
begin
  raise Exception.Create(Message);
end;
function Direct3DErrorText(Code: Integer): AnsiString;
begin
  Result := '';
  case Code of
    0: Result := 'D3D_OK';
    -2005530600: Result := 'D3DERR_WRONGTEXTUREFORMAT';
    -2005530599: Result := 'D3DERR_UNSUPPORTEDCOLOROPERATION';
    -2005530598: Result := 'D3DERR_UNSUPPORTEDCOLORARG';
    -2005530597: Result := 'D3DERR_UNSUPPORTEDALPHAOPERATION';
    -2005530596: Result := 'D3DERR_UNSUPPORTEDALPHAARG';
    -2005530595: Result := 'D3DERR_TOOMANYOPERATIONS';
    -2005530594: Result := 'D3DERR_CONFLICTINGTEXTUREFILTER';
    -2005530593: Result := 'D3DERR_UNSUPPORTEDFACTORVALUE';
    -2005530591: Result := 'D3DERR_CONFLICTINGRENDERSTATE';
    -2005530590: Result := 'D3DERR_UNSUPPORTEDTEXTUREFILTER';
    -2005530586: Result := 'D3DERR_CONFLICTINGTEXTUREPALETTE';
    -2005530585: Result := 'D3DERR_DRIVERINTERNALERROR';
    -2005530522: Result := 'D3DERR_NOTFOUND';
    -2005530521: Result := 'D3DERR_MOREDATA';
    -2005530520: Result := 'D3DERR_DEVICELOST';
    -2005530519: Result := 'D3DERR_DEVICENOTRESET';
    -2005530518: Result := 'D3DERR_NOTAVAILABLE';
    -2005532292: Result := 'D3DERR_OUTOFVIDEOMEMORY';
    -2005530517: Result := 'D3DERR_INVALIDDEVICE';
    -2005530516: Result := 'D3DERR_INVALIDCALL';
    -2005530515: Result := 'D3DERR_DRIVERINVALIDCALL';
  else
    Result := SysUtils.IntToStr(Code);
    Exit;
  end;
  Result := Result + ' (' + SysUtils.IntToStr(Code) + ')';
end;
function FormatUnixDateTime(Value: Cardinal): WideString;
var
  DateValue: TDateTime;
begin
  DateValue := UnixToDateTime(Value);
  Result := DateTimeToStr(DateValue);
end;
procedure LoadInformationColorTags;
var
  Block: TBlockParEC;
begin
  InfoNameColorTag := '<color=57,239,255>';
  InfoHullSeriesColorTag := '<color=82,166,255>';
  if GameDataConfig.CountBlocks('StyleColor') > 0 then
  begin
    Block := GameDataConfig.GetBlock('StyleColor');
    if Block.CountParamsByPath('InfoNameColor') > 0 then
      InfoNameColorTag := '<color=' + Block.GetParamByPath('InfoNameColor') + '>';
    if Block.CountParamsByPath('InfoHullSeriesColor') > 0 then
      InfoHullSeriesColorTag := '<color=' + Block.GetParamByPath('InfoHullSeriesColor') + '>';
  end;
end;
function GetStyleColorGI(
    StyleName: WideString;
    DefaultRed, DefaultGreen, DefaultBlue: Integer
): Cardinal;
var
  Style: TBlockParEC;
  ColorText: WideString;
begin
  if GameDataConfig.CountBlocks('StyleColor') > 0 then
  begin
    Style := GameDataConfig.GetBlock('StyleColor');
    if Style.CountParamsByPath(StyleName) > 0 then
    begin
      ColorText := Style.GetParamByPath(StyleName);
      Result :=
          CurrentPixelFormat.PackRgb(
              ExtractDigitsToIntW(ExtractDelimitedPartW(ColorText, 0, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(ColorText, 1, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(ColorText, 2, ','))
          );
      Exit;
    end;
  end;
  Result := CurrentPixelFormat.PackRgb(DefaultRed, DefaultGreen, DefaultBlue);
end;
function GetStyleColorTagGI(
    StyleName: WideString;
    DefaultRed, DefaultGreen, DefaultBlue: Integer
): WideString;
var
  Style: TBlockParEC;
begin
  if GameDataConfig.CountBlocks('StyleColor') > 0 then
  begin
    Style := GameDataConfig.GetBlock('StyleColor');
    if Style.CountParamsByPath(StyleName) > 0 then
    begin
      Result := Style.GetParamByPath(StyleName);
      Result := '<color=' + Style.GetParamByPath(StyleName) + '>';
      Exit;
    end;
  end;
  Result :=
      '<color='
          + IntToWideString(DefaultRed)
          + ','
          + IntToWideString(DefaultGreen)
          + ','
          + IntToWideString(DefaultBlue)
          + '>';
end;
function GetGameUserDirectory: WideString;
begin
  Result := IncludeTrailingPathDelimiter(UTF8Encode(OverrideGameUserDirectory));
end;
function GetClipboardWideText: WideString;
begin
  Result := UTF8Decode(AnsiString(sr_clipboard_get));
end;
procedure SetClipboardWideText(Text: WideString);
begin
  sr_clipboard_set(PAnsiChar(UTF8Encode(Text)));
end;
procedure LogPresentationParameters;
var
  CurrentValue, PreviousValue: Cardinal;
  Text: WideString;
  procedure LogPresentationField(
      Name: WideString
  ); // @addr $4D548C @ida "void __usercall $name(unsigned __int16 *Name@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4D5638,0x4D5654,0x4D5670,0x4D568C,0x4D56A8,0x4D56C4,0x4D56E0,0x4D56FC,0x4D5732,0x4D5768,0x4D5784,0x4D57A0,0x4D57BC,0x4D57D8"
  begin
    if CurrentValue = PreviousValue then
      Text := Name + ' = ' + SysUtils.IntToStr(Int64(CurrentValue))
    else
      Text :=
          Name
              + ' = '
              + SysUtils.IntToStr(Int64(CurrentValue))
              + ', previous value = '
              + SysUtils.IntToStr(Int64(PreviousValue));
    AppendLogLineThreadSafe(Text);
  end;
begin
  AppendLogLineThreadSafe('');
  AppendLogLineThreadSafe('D3DPresent structure:');
  CurrentValue := Direct3DPresentParameters.BackBufferWidth;
  PreviousValue := PreviousPresentParameters.BackBufferWidth;
  LogPresentationField('BackBufferWidth');
  CurrentValue := Direct3DPresentParameters.BackBufferHeight;
  PreviousValue := PreviousPresentParameters.BackBufferHeight;
  LogPresentationField('BackBufferHeight');
  CurrentValue := Direct3DPresentParameters.BackBufferCount;
  PreviousValue := PreviousPresentParameters.BackBufferCount;
  LogPresentationField('BackBufferCount');
  CurrentValue := Direct3DPresentParameters.BackBufferFormat;
  PreviousValue := PreviousPresentParameters.BackBufferFormat;
  LogPresentationField('BackBufferFormat');
  CurrentValue := Direct3DPresentParameters.MultiSampleQuality;
  PreviousValue := PreviousPresentParameters.MultiSampleQuality;
  LogPresentationField('MultiSampleQuality');
  CurrentValue := Direct3DPresentParameters.MultiSampleType;
  PreviousValue := PreviousPresentParameters.MultiSampleType;
  LogPresentationField('MultiSampleType');
  CurrentValue := Direct3DPresentParameters.SwapEffect;
  PreviousValue := PreviousPresentParameters.SwapEffect;
  LogPresentationField('SwapEffect');
  CurrentValue := Direct3DPresentParameters.DeviceWindow;
  PreviousValue := PreviousPresentParameters.DeviceWindow;
  LogPresentationField('hDeviceWindow');
  CurrentValue := Ord(Boolean(Direct3DPresentParameters.Windowed) = True);
  PreviousValue := Ord(Boolean(PreviousPresentParameters.Windowed) = True);
  LogPresentationField('Windowed');
  CurrentValue := Ord(Boolean(Direct3DPresentParameters.EnableAutoDepthStencil) = True);
  PreviousValue := Ord(Boolean(PreviousPresentParameters.EnableAutoDepthStencil) = True);
  LogPresentationField('EnableAutoDepthStencil');
  CurrentValue := Direct3DPresentParameters.AutoDepthStencilFormat;
  PreviousValue := PreviousPresentParameters.AutoDepthStencilFormat;
  LogPresentationField('AutoDepthStencilFormat');
  CurrentValue := Direct3DPresentParameters.Flags;
  PreviousValue := PreviousPresentParameters.Flags;
  LogPresentationField('Flags');
  CurrentValue := Direct3DPresentParameters.FullScreenRefreshRateInHz;
  PreviousValue := PreviousPresentParameters.FullScreenRefreshRateInHz;
  LogPresentationField('FullScreen_RefreshRateInHz');
  CurrentValue := Direct3DPresentParameters.PresentationInterval;
  PreviousValue := PreviousPresentParameters.PresentationInterval;
  LogPresentationField('PresentationInterval');
  AppendLogLineThreadSafe('');
end;
function GlobalMemoryStatusEx(var Status: TMemoryStatusEx): LongBool; stdcall;
begin
  FillChar(Status, SizeOf(Status), 0);
  Status.Length := SizeOf(Status);
  sr_memory(Status.TotalPhys, Status.AvailPhys);
  Status.TotalVirtual := Status.TotalPhys;
  Status.AvailVirtual := Status.AvailPhys;
  Result := True
end;
end.
