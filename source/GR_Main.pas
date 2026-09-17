unit GR_Main;

{$I GameOptions.inc}
{$POINTERMATH ON}

interface

uses
  GameSystem,
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

type

  TCCInterface = class;

  TCursorUnit = class;

  PointerToTCCSnapshot = ^TCCSnapshot;

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

  TMemoryStatusEx = TGameMemoryStatus;

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

  PCCSnapshot = PointerToTCCSnapshot;

  TCCSnapshot = record
    Prev: PCCSnapshot;
    Next: PCCSnapshot;
    ResourceChecksumFailed: Boolean;
    TamperDetected: Boolean;
    Flag0A: Boolean;
    GapB: array[0..0] of Byte;
    ProtectedStateXorSeed: Integer;
    Value10: Integer;
    IntegrityStatus: Integer;
    IntegrityError: Integer;
    IntegrityChecksum: Cardinal;
    IntegrityChecksum1: Cardinal;
    IntegrityChecksum2: Cardinal;
    EncodedCheatPoints: Integer;
    EditableStateApplied: Boolean;
    Gap2D: array[0..2] of Byte;
  end;

  TCCInterface = class(TObject)
    Buffer: TBufEC;
    SnapshotHead: PCCSnapshot;
    Lock: TCriticalSection;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function GetSnapshot: PCCSnapshot;
    function CreateDecoy: PCCSnapshot;
    function CreateEmptySnapshot: PCCSnapshot;
    function CopySnapshot(Source: PCCSnapshot): PCCSnapshot;
    procedure CommitSnapshot(Snapshot: PCCSnapshot);
    procedure ClearSnapshots;
    function GetResourceChecksumFailed: Boolean;
    procedure SetResourceChecksumFailed(Value: Boolean);
    function GetTamperDetected: Boolean;
    procedure SetTamperDetected(Value: Boolean);
    function GetFlag0A: Boolean;
    procedure SetFlag0A(Value: Boolean);
    function GetEditableStateApplied: Boolean;
    procedure SetEditableStateApplied(Value: Boolean);
    function GetProtectedStateXorSeed: Integer;
    procedure SetProtectedStateXorSeed(Value: Integer);
    function GetValue10: Integer;
    procedure SetValue10(Value: Integer);
    function GetIntegrityStatus: Integer;
    procedure SetIntegrityStatus(Value: Integer);
    function GetIntegrityError: Integer;
    procedure SetIntegrityError(Value: Integer);
    function GetIntegrityChecksum: Cardinal;
    procedure SetIntegrityChecksum(Value: Cardinal);
    function GetIntegrityChecksum1: Cardinal;
    procedure SetIntegrityChecksum1(Value: Cardinal);
    function GetIntegrityChecksum2: Cardinal;
    procedure SetIntegrityChecksum2(Value: Cardinal);
    function GetEncodedCheatPoints: Integer;
    procedure SetEncodedCheatPoints(Value: Integer);
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

const
{$IFDEF MSWINDOWS}
  OkgfLibraryName = 'okgf.dll';
{$ELSE}
  OkgfLibraryName = 'okgf';
{$ENDIF}

function OKGF_MulTable256x256: Pointer; cdecl; external OkgfLibraryName name 'OKGF_MulTable256x256';

function OKGF_DXVersion: Cardinal; cdecl; external OkgfLibraryName name 'DXVersion';

function OKGF_ReadStart_Buf(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer
): POkgfReadContext; cdecl; external OkgfLibraryName name 'OKGF_ReadStart_Buf';

function OKGF_Read(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    BytesPerPixel: Integer
): Integer; cdecl; external OkgfLibraryName name 'OKGF_Read';

function OKGF_ReadStartPal_Buf(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer;
    out PaletteCount: Integer;
    out BytesPerPixel: Integer
): POkgfReadContext; cdecl; external OkgfLibraryName name 'OKGF_ReadStartPal_Buf';

function OKGF_ReadPal(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    Palette: PColorRGBA
): Integer; cdecl; external OkgfLibraryName name 'OKGF_ReadPal';

function OKGF_Write_PNG_File(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes: Integer;
    Width: Integer;
    Height: Integer;
    HasAlpha: Integer;
    SwapRedBlue: Integer
): Integer; cdecl; external OkgfLibraryName name 'OKGF_Write_PNG_File';

function OKGF_Write_BMP_File(
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
): Integer; cdecl; external OkgfLibraryName name 'OKGF_Write_BMP_File';

procedure OKGR_AlphaBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_AlphaBuf_Draw_RGBA';

procedure OKGR_TransAlphaBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_TransAlphaBuf_Draw_RGBA';

procedure OKGR_AlphaIndexed_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_Draw_RGBA';

procedure OKGR_AlphaIndexed_AlphaDraw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_AlphaDraw_RGBA';

procedure OKGR_TransBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_TransBuf_Draw_RGBA';

// OKGF takes a pointer to each clipping rectangle. Delphi Win32 passed these
// const records by reference; FPC may pass their contents in registers instead.
// Keep the pointer ABI explicit at the C boundary (original call at $4C8644,
// OKGR_AlphaBuf_DrawClip_16 reads that pointer at okgf.dll:$1005365D).
procedure OKGR_TransBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_TransBuf_DrawClip_WORD';

procedure OKGR_TransBuf_HADrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_TransBuf_HADrawClip_16';

function OKGR_TransBuf_Build_WORD(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer;
    TransparentColor: Word
): Integer; cdecl; external OkgfLibraryName name 'OKGR_TransBuf_Build_WORD';

function OKGR_TransBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_TransBuf_BuildFromRGBA_16';

procedure OKGR_TransAlphaBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_TransAlphaBuf_DrawClip_WORD';

procedure OKGR_AlphaBuf_DrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_AlphaBuf_DrawClip_16';

function OKGR_TransAlphaBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_TransAlphaBuf_BuildFromRGBA_16';

function OKGR_AlphaBuf_BuildFromRGBA(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_AlphaBuf_BuildFromRGBA';

procedure OKGR_AlphaSimpleBuf_Draw_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_AlphaSimpleBuf_Draw_16';

procedure OKGR_AlphaSimpleBufPalAlpha_Draw_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_AlphaSimpleBufPalAlpha_Draw_16';

procedure OKGR_MaskBuf_DrawClip_DWORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Cardinal;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_MaskBuf_DrawClip_DWORD';

procedure OKGR_MaskBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Word;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_MaskBuf_DrawClip_WORD';

procedure OKGR_TransBuf_FillAlphaClip_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Cardinal
); cdecl; external OkgfLibraryName name 'OKGR_TransBuf_FillAlphaClip_RGBA';

procedure OKGR_TransBuf_FillAlphaClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Word
); cdecl; external OkgfLibraryName name 'OKGR_TransBuf_FillAlphaClip_16';

procedure OKGR_AlphaIndexed_CopyDrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_CopyDrawClip_WORD';

procedure OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_CopyDrawClip_Alpha_16';

procedure OKGR_AlphaIndexed_AlphaDrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_AlphaDrawClip_16';

procedure OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
); cdecl; external OkgfLibraryName name 'OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16';

function OKGR_RotateBuf_Build(
    Width: Integer;
    Height: Integer;
    SourceWidth: Integer;
    SourceHeight: Integer;
    CenterX: Integer;
    CenterY: Integer
): Pointer; cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_Build';

procedure OKGR_RotateBuf_Free(
    Buffer: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_Free';

procedure OKGR_RotateBuf_Size(
    X: Integer;
    Y: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    var Bounds: TRect
); cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_Size';

procedure OKGR_RotateBuf_Draw_DWORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_Draw_DWORD';

procedure OKGR_RotateBuf_Draw_BYTE(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    Angle: Byte;
    RotationMap: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_Draw_BYTE';

procedure OKGR_RotateBuf_DrawTransClip_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_RotateBuf_DrawTransClip_WORD';

function OKGR_LightBuf_Create(
    Width: Integer;
    Height: Integer
): Pointer; cdecl; external OkgfLibraryName name 'OKGR_LightBuf_Create';

procedure OKGR_LightBuf_Destroy(
    Buffer: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_LightBuf_Destroy';

procedure OKGR_LightBuf_SetSme(
    Buffer: Pointer;
    X: Integer;
    Y: Integer
); cdecl; external OkgfLibraryName name 'OKGR_LightBuf_SetSme';

procedure OKGR_LightBuf_Init(
    Buffer: Pointer;
    Value: Byte
); cdecl; external OkgfLibraryName name 'OKGR_LightBuf_Init';

procedure OKGR_LightBuf_LoadFromPalBuf(
    Buffer: Pointer;
    Source: Pointer;
    Width: Integer;
    Height: Integer;
    Pitch: Integer;
    Palette: PColorRGBA
); cdecl; external OkgfLibraryName name 'OKGR_LightBuf_LoadFromPalBuf';

procedure OKGR_LightBuf_Rotate(
    Dest: Pointer;
    Source: Pointer;
    RotationMap: Pointer;
    Angle: Byte
); cdecl; external OkgfLibraryName name 'OKGR_LightBuf_Rotate';

function OKGR_Planet2_TemplBuild(
    Source: Pointer;
    Pitch: Integer;
    Height: Integer;
    TextureWidth: Integer;
    TextureHeight: Integer;
    var ByteCount: Integer
): Pointer; cdecl; external OkgfLibraryName name 'OKGR_Planet2_TemplBuild';

function OKGR_Planet2_TemplDel(
    TemplateData: Pointer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_Planet2_TemplDel';

procedure OKGR_Planet2_DrawAndLight_32(
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
); cdecl; external OkgfLibraryName name 'OKGR_Planet2_DrawAndLight_32';

procedure OKGR_Planet2_DrawAndLightClip_16(
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
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Planet2_DrawAndLightClip_16';

procedure OKGR_Planet3_DrawAndLight_32(
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
); cdecl; external OkgfLibraryName name 'OKGR_Planet3_DrawAndLight_32';

procedure OKGR_Planet3_DrawAndLightClip_16(
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
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Planet3_DrawAndLightClip_16';

procedure OKGR_Planet4_DrawAndLight_32(
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
); cdecl; external OkgfLibraryName name 'OKGR_Planet4_DrawAndLight_32';

procedure OKGR_Planet4_DrawAndLightClip_16(
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
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Planet4_DrawAndLightClip_16';

procedure OKGR_Copy_XY_XY_WORD(
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
); cdecl; external OkgfLibraryName name 'OKGR_Copy_XY_XY_WORD';

procedure OKGR_PalCopy_XY_XY_WORD(
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
); cdecl; external OkgfLibraryName name 'OKGR_PalCopy_XY_XY_WORD';

procedure OKGR_CopyTrans_XY_XY_WORD(
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
); cdecl; external OkgfLibraryName name 'OKGR_CopyTrans_XY_XY_WORD';

procedure OKGR_CopySingleBuf_XY_XY_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    DestX: Integer;
    DestY: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGR_CopySingleBuf_XY_XY_WORD';

procedure OKGR_HACopy_XY_XY_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_HACopy_XY_XY_16';

procedure OKGR_StretchGdi_WORD(
    Dest: Pointer;
    Width: Cardinal;
    Height: Cardinal;
    Source: Pointer;
    SourceWidth: Cardinal;
    SourceHeight: Cardinal
); cdecl; external OkgfLibraryName name 'OKGR_StretchGdi_WORD';

procedure OKGR_Fill_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Color: Word
); cdecl; external OkgfLibraryName name 'OKGR_Fill_WORD';

procedure OKGF_ConvertRGBto565(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGF_ConvertRGBto565';

procedure OKGF_Convert565toRGB(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGF_Convert565toRGB';

procedure OKGF_Convert565toBGR(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGF_Convert565toBGR';

procedure OKGF_Convert565toBGRA(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGF_Convert565toBGRA';

procedure OKGF_Convert_8888to565(
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
); cdecl; external OkgfLibraryName name 'OKGF_Convert_8888to565';

procedure OKGR_ShrLight_16(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Shift: Integer
); cdecl; external OkgfLibraryName name 'OKGR_ShrLight_16';

procedure OKGR_ShrLightMask_16(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external OkgfLibraryName name 'OKGR_ShrLightMask_16';

procedure OKGR_Light_BYTE(
    Pixels: Pointer;
    PixelStride: Integer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Alpha: Byte
); cdecl; external OkgfLibraryName name 'OKGR_Light_BYTE';

procedure OKGR_Circle_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Circle_DrawClip_WORD';

procedure OKGR_Circle_DrawClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Circle_DrawClip_BYTE';

procedure OKGR_Circle_DrawFillClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Circle_DrawFillClip_WORD';

procedure OKGR_Circle_DrawFillClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Circle_DrawFillClip_BYTE';

procedure OKGR_PixelAlpha_16(
    Pixel: Pointer;
    Color: Word;
    Alpha: Byte
); cdecl; external OkgfLibraryName name 'OKGR_PixelAlpha_16';

function OKGR_Line_Clip(
    var X1: Integer;
    var Y1: Integer;
    var X2: Integer;
    var Y2: Integer;
    constref Clip: TRect
): Integer; cdecl; external OkgfLibraryName name 'OKGR_Line_Clip';

function OKGR_LineColor_Clip(
    var X1: Integer;
    var Y1: Integer;
    var Color1: Cardinal;
    var X2: Integer;
    var Y2: Integer;
    var Color2: Cardinal;
    constref Clip: TRect
): Integer; cdecl; external OkgfLibraryName name 'OKGR_LineColor_Clip';

procedure OKGR_Line_Draw_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word
); cdecl; external OkgfLibraryName name 'OKGR_Line_Draw_WORD';

procedure OKGR_Line_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Line_DrawClip_WORD';

function OKGR_Line_CopyToBuf_WORD(
    Dest: Pointer;
    Source: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_Line_CopyToBuf_WORD';

function OKGR_Line_CopyFromBuf_WORD(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer; cdecl; external OkgfLibraryName name 'OKGR_Line_CopyFromBuf_WORD';

procedure OKGR_Line_DrawClip_Alpha_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    Alpha: Byte;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_Line_DrawClip_Alpha_16';

procedure OKGR_AnimLine_Draw_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    Phase: Integer;
    constref Clip: TRect
); cdecl; external OkgfLibraryName name 'OKGR_AnimLine_Draw_16';

procedure OKGR_AnimShadowLine_Draw_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_AnimShadowLine_Draw_16';

procedure OKGR_Alpha64Trapezium_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_Alpha64Trapezium_16';

procedure OKGR_Alpha128Trapezium_16(
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
); cdecl; external OkgfLibraryName name 'OKGR_Alpha128Trapezium_16';

procedure OKGR_FillTrapezium_DWORD(
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
); cdecl; external OkgfLibraryName name 'OKGR_FillTrapezium_DWORD';

procedure OKGF_Rescale(
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
); cdecl; external OkgfLibraryName name 'OKGF_Rescale';

procedure OKGR_F5_DrawRGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_F5_DrawRGBA';

procedure OKGR_F6_DrawRGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external OkgfLibraryName name 'OKGR_F6_DrawRGBA';

procedure OKGF_Triangle_16(
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
); cdecl; external OkgfLibraryName name 'OKGF_Triangle_16';

procedure OKGF_LineIp_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    Color1: Cardinal;
    X2: Integer;
    Y2: Integer;
    Color2: Cardinal
); cdecl; external OkgfLibraryName name 'OKGF_LineIp_16';

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

  StartupChecksumAnchor: Integer = 0;

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

  OnMessageIdle: TRuntimeCallbackGR;

  OnMessageResume: TRuntimeCallbackGR;

  CCInterface: TCCInterface;

  RuntimeStartupTick: Cardinal;

  MainRuntimeThreadId: TThreadID;

  DesktopDisplayMode: TDisplayModeGR;

  Direct3DPresentParameters: TD3DPresentParameters;

  PreviousPresentParameters: TD3DPresentParameters;

  GameDisplayModes: array of TDisplayModeGR;

  RobotDisplayModes: array of TDisplayModeGR;

  ExtraScreenWidth: Integer;

  ExtraScreenHeight: Integer;

  EncodedPlatformModuleNames: array[0..8] of AnsiString = (
      'loinbaosgaga-10a',
      'loinbavrokrablius-->0',
      'loinbaveohrablissufainlae',
      'mhastorhinxagrakmae',
      'ookogifa',
      'sotoenalm^_^aucah',
      'sotoenalm^_^aupki',
      'xavriadeccomrie',
      'zoloimba'
  );

  CachedGameUserDirectory: WideString = '';

procedure CheckPlatformModules;

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
    const FileName: UnicodeString;
    Pixels: Pointer;
    PitchBytes: Integer;
    Width: Integer;
    Height: Integer;
    HasAlpha: Integer;
    SwapRedBlue: Integer
): Integer;

function WriteBmpFile(
    const FileName: UnicodeString;
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
    const Clip: TRect
);

procedure Ex_OKGR_TransBuf_HADrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect
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
    const Clip: TRect
);

procedure Ex_OKGR_AlphaBuf_DrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect
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
    const Clip: TRect
);

procedure Ex_OKGR_MaskBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Word;
    const Clip: TRect
);

procedure Ex_OKGR_TransBuf_FillAlphaClip_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect;
    Color: Cardinal
);

procedure Ex_OKGR_TransBuf_FillAlphaClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect;
    Color: Word
);

procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect
);

procedure Ex_OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect;
    Alpha: Byte
);

procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect
);

procedure Ex_OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    const Clip: TRect;
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

function Ex_OKGR_Planet2_TemplDel(TemplateData: Pointer): Integer;

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
    const Clip: TRect
);

procedure Ex_OKGR_Circle_DrawClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    const Clip: TRect
);

procedure Ex_OKGR_Circle_DrawFillClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    const Clip: TRect
);

procedure Ex_OKGR_Circle_DrawFillClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect;
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    Clip: TRect
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
    Clip: TRect
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

{$IFDEF MSWINDOWS}
function ReadRegistryText(
    Root: PtrUInt;
    KeyPath: WideString;
    ValueName: WideString;
    DefaultValue: WideString
): WideString;

function ReadRegistryInteger(
    Root: PtrUInt;
    KeyPath: WideString;
    ValueName: WideString;
    DefaultValue: Integer
): Integer;
{$ENDIF}

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

function ComputeMachineFingerprintCRC: Cardinal;

function GetClipboardWideText: WideString;

procedure SetClipboardWideText(Text: WideString);

procedure LogPresentationParameters;

implementation

uses
  GameGraphics,
  GameAudio,
  GameInput,
  SDL2,
  GI_Main,
  DirectXRenderException,
{$IFDEF MSWINDOWS}
  TlHelp32,
{$ENDIF}
  aPacket,
  DateUtils,
  Robot,
  GI_MessageLoop,
  EC_Mem,
  GR_DX,
  Globals,
  aMyFunction,
  MessageText,
  GlobalsV,
{$IFDEF MSWINDOWS}
  // Math last on Windows: the Windows unit declares min/max for LongInt (windef
  // macros), which would otherwise hide the Math overloads used with
  // floating-point arguments here.
  GameWindow,
  Windows,
  Registry,
  Math,
{$ELSE}
  Math,
  GameWindow,
{$ENDIF}
  SysUtils;

var
  StartupState:
      Cardinal; { Cleared by settings initialization; no retained reader found, original meaning unresolved. }
  ScreenCenterX: Cardinal;
  ScreenCenterY: Cardinal;
  LastWindowMessageTick: Cardinal;
  MessageIdle: Boolean;

{$I-}

procedure CheckPlatformModules;
{$IFDEF MSWINDOWS}
var
  GameDirectory, ModulePath: AnsiString;
  Snapshot: THandle;
  SteamProcessId: Cardinal;
  Index, FailureOffset: Integer;
  Found: Boolean;
  DllSuffix: WideString;
  SteamClientPath: AnsiString;
  Entry: TModuleEntry32;

  function MatchesModuleDirectoryPrefix(
      Prefix,
      Path: AnsiString
  ): Boolean; { Nested helper. Requires Prefix no longer than Path, but compares only characters 1 through Length(Prefix)-1. }
  var
    CharacterIndex, CharacterCount: Integer;
  begin
    Result := False;
    if Length(Prefix) > Length(Path) then
      Exit;
    CharacterIndex := 1;
    CharacterCount := Min(Length(Prefix), Length(Path));
    while CharacterIndex < CharacterCount do
    begin
      if Prefix[CharacterIndex] <> Path[CharacterIndex] then
        Exit;
      Inc(CharacterIndex);
    end;
    Result := True;
  end;

begin
  // This build disables the checks, but Delphi O- retained their native bytes.
  Exit;
  DllSuffix := 'll';
  DllSuffix := '.d' + DllSuffix;
  Snapshot := CreateToolhelp32Snapshot(8, GetCurrentProcessId);
  if Snapshot <> INVALID_HANDLE_VALUE then
  begin
    GameDirectory := AnsiLowerCase(ExtractFilePath(ParamStr(0)));
    Entry.dwSize := SizeOf(Entry);
    if Module32First(Snapshot, Entry) then
    begin
      repeat
        if MatchesModuleDirectoryPrefix(
            GameDirectory,
            AnsiLowerCase(ExtractFilePath(AnsiString(Entry.szExePath)))) then
        begin
          Found := False;
          ModulePath := AnsiLowerCase(AnsiString(Entry.szModule));
          for Index := 0 to 8 do
          begin
            // Decoded: 'libogg-0.dll', 'libvorbis-0.dll', 'libvorbisfile.dll',
            // 'matrixgame.dll', 'okgf.dll', 'steam_ach.dll', 'steam_api.dll',
            // 'xvidcore.dll', 'zlib.dll'.
            if WideString(ModulePath)
                = DecodeTextW(WideString(EncodedPlatformModuleNames[Index])) + DllSuffix then
            begin
              Found := True;
              Break;
            end;
          end;
          if not Found then
          begin
            FailureOffset := 4;
            PInteger(PAnsiChar(@PlatformCheckAnchor) + FailureOffset)^ :=
                RandomIntRange(1000000000, 2000000000);
            CloseHandle(Snapshot);
            Exit;
          end;
        end;
      until not Module32Next(Snapshot, Entry);
    end;
    CloseHandle(Snapshot);
  end;
  SteamClientPath :=
      AnsiLowerCase(
          AnsiString(
              ReadRegistryText(
                  HKEY_CURRENT_USER,
                  DecodeTextW(
                      'Sdonf6t4wdabrden\7Vga4l-v7ef\3Sdt6e8a,mu\gAcczt1i2v3e2Pvrnohcyetsrs'
                  ), // Decoded: 'Software\Valve\Steam\ActiveProcess'
                  DecodeTextW('S4tgefadm.ClliitevnvteDtlfls'),
                  ''
              )
          )
      ); // Decoded: 'SteamClientDll'
  SteamProcessId :=
      ReadRegistryInteger(
          HKEY_CURRENT_USER,
          DecodeTextW('Sdonf6t4wdabrden\7Vga4l-v7ef\3Sdt6e8a,mu\gAcczt1i2v3e2Pvrnohcyetsrs'),
          'pid',
          0
      ); // Decoded: 'Software\Valve\Steam\ActiveProcess'
  Snapshot := CreateToolhelp32Snapshot(8, GetCurrentProcessId);
  if Snapshot <> INVALID_HANDLE_VALUE then
  begin
    Entry.dwSize := SizeOf(Entry);
    if Module32First(Snapshot, Entry) then
    begin
      Found := False;
      // Native deliberately advances before inspecting the first path here.
      while Module32Next(Snapshot, Entry) do
      begin
        ModulePath := AnsiLowerCase(AnsiString(Entry.szExePath));
        if ModulePath = SteamClientPath then
        begin
          Found := True;
          Break;
        end;
      end;
      if not Found then
      begin
        FailureOffset := 4;
        PInteger(PAnsiChar(@PlatformCheckAnchor) + FailureOffset)^ :=
            RandomIntRange(1000000000, 2000000000);
        CloseHandle(Snapshot);
        Exit;
      end;
    end;
    CloseHandle(Snapshot);
  end;
  Found := False;
  Snapshot := CreateToolhelp32Snapshot(8, SteamProcessId);
  if Snapshot <> INVALID_HANDLE_VALUE then
  begin
    Entry.dwSize := SizeOf(Entry);
    if Module32First(Snapshot, Entry) then
      if AnsiLowerCase(AnsiString(Entry.szExePath))
          = AnsiLowerCase(
              AnsiString(
                  WideString(ExtractFilePath(SteamClientPath)) + DecodeTextW('s1t2eda5mg.he7xie')
              )) then // Decoded: 'steam.exe'
      begin
        while Module32Next(Snapshot, Entry) do
        begin
          ModulePath := AnsiLowerCase(AnsiString(Entry.szExePath));
          if ModulePath = SteamClientPath then
          begin
            Found := True;
            Break;
          end;
        end;
      end;
    CloseHandle(Snapshot);
  end;
  if not Found then
  begin
    FailureOffset := 4;
    PInteger(PAnsiChar(@PlatformCheckAnchor) + FailureOffset)^ :=
        RandomIntRange(1000000000, 2000000000);
  end;
end;
{$ELSE}
begin
  // The original module check is disabled on Windows as well.
end;
{$ENDIF}

procedure LogMemoryUsage;
var
  Status: TMemoryStatusEx;
begin
  Status.Length := SizeOf(Status);
  QueryGameMemory(Status);
  AppendLogLineThreadSafe('Memory Info');
  AppendLogLineThreadSafe('Physical Memory:');
  AppendLogLineThreadSafe(
      'Used=' + SysUtils.IntToStr((Status.TotalPhys - Status.AvailPhys) shr 10) + ' KB'
  );
  AppendLogLineThreadSafe('Available=' + SysUtils.IntToStr(Status.AvailPhys shr 10) + ' KB');
  AppendLogLineThreadSafe('Total=' + SysUtils.IntToStr(Status.TotalPhys shr 10) + ' KB');
  AppendLogLineThreadSafe('Virtual Memory:');
  AppendLogLineThreadSafe(
      'Used=' + SysUtils.IntToStr((Status.TotalVirtual - Status.AvailVirtual) shr 10) + ' KB'
  );
  AppendLogLineThreadSafe('Available=' + SysUtils.IntToStr(Status.AvailVirtual shr 10) + ' KB');
  AppendLogLineThreadSafe('Total=' + SysUtils.IntToStr(Status.TotalVirtual shr 10) + ' KB');
  if GlobalCache <> nil then
    AppendLogLineThreadSafe(
        'Cache Size=' + SysUtils.IntToStr(GlobalCache.ResidentBytes shr 10) + ' KB'
    );
  AppendLogLineThreadSafe(
      'Textures Cache Size=' + SysUtils.IntToStr(Int64(ResidentTextureBytes shr 10)) + ' KB'
  );
end;

constructor TCCInterface.Create;
begin
  inherited Create;
  Lock := SyncObjs.TCriticalSection.Create;
  Randomize;
  Buffer := TBufEC.Create;
  CommitSnapshot(CreateEmptySnapshot);
end;

destructor TCCInterface.Destroy;
begin
  Lock.Free;
  Buffer.Free;
  ClearSnapshots;
  inherited Destroy;
end;

procedure TCCInterface.Reset;
begin
  Lock.Enter;
  Buffer.Clear;
  ClearSnapshots;
  CommitSnapshot(CreateEmptySnapshot);
  Lock.Leave;
end;

function TCCInterface.GetSnapshot: PCCSnapshot;
var
  Entry: PCCSnapshot;
begin
  Entry := SnapshotHead;
  while (Entry.Prev = nil) or (Entry.Next.Prev = Entry) do
    Entry := Entry.Next;
  Result := Entry.Next;
end;

function TCCInterface.CreateDecoy: PCCSnapshot;
begin
  New(Result);
  Result.ResourceChecksumFailed := Random(11) > 9;
  Result.TamperDetected := Random(11) > 8;
  Result.Flag0A := Random(11) > 9;
  Result.ProtectedStateXorSeed := Random(2000000000);
  Result.Value10 := Random(1000);
  Result.IntegrityStatus := Random(1000);
  Result.IntegrityError := Ord(Random(11) > 8) * Random(1000);
  Result.IntegrityChecksum := Random(2000000000);
  Result.IntegrityChecksum1 := Random(2000000000);
  Result.IntegrityChecksum2 := Random(2000000000);
  Result.EncodedCheatPoints := Random(2000000000);
  Result.EditableStateApplied := Random(11) > 9;
end;

function TCCInterface.CreateEmptySnapshot: PCCSnapshot;
begin
  New(Result);
  Result.ResourceChecksumFailed := False;
  Result.TamperDetected := False;
  Result.Flag0A := False;
  Result.ProtectedStateXorSeed := 0;
  Result.Value10 := 0;
  Result.IntegrityStatus := 0;
  Result.IntegrityError := 0;
  Result.IntegrityChecksum := 0;
  Result.IntegrityChecksum1 := 0;
  Result.IntegrityChecksum2 := 0;
  Result.EncodedCheatPoints := 0;
  Result.EditableStateApplied := False;
end;

function TCCInterface.CopySnapshot(Source: PCCSnapshot): PCCSnapshot;
begin
  New(Result);
  Result.ResourceChecksumFailed := Source.ResourceChecksumFailed;
  Result.TamperDetected := Source.TamperDetected;
  Result.Flag0A := Source.Flag0A;
  Result.ProtectedStateXorSeed := Source.ProtectedStateXorSeed;
  Result.Value10 := Source.Value10;
  Result.IntegrityStatus := Source.IntegrityStatus;
  Result.IntegrityError := Source.IntegrityError;
  Result.IntegrityChecksum := Source.IntegrityChecksum;
  Result.IntegrityChecksum1 := Source.IntegrityChecksum1;
  Result.IntegrityChecksum2 := Source.IntegrityChecksum2;
  Result.EncodedCheatPoints := Source.EncodedCheatPoints;
  Result.EditableStateApplied := Source.EditableStateApplied;
end;

procedure TCCInterface.CommitSnapshot(Snapshot: PCCSnapshot);
var
  RingCount, PrefixCount, OldPrefixCount: Integer;
  Entry, Added: PCCSnapshot;
begin
  OldPrefixCount := 0;
  if SnapshotHead <> nil then
  begin
    Entry := GetSnapshot;
    Added := SnapshotHead;
    while Entry <> Added do
    begin
      Inc(OldPrefixCount);
      Added := Added.Next;
    end;
  end;
  RingCount := Random(3) + 3;
  PrefixCount := Random(3) + 3;
  while PrefixCount = OldPrefixCount do
    PrefixCount := Random(3) + 3;
  Entry := Snapshot;
  Added := nil;
  while RingCount > 0 do
  begin
    Dec(RingCount);
    Added := CreateDecoy;
    Added.Next := Entry;
    Entry.Prev := Added;
    Entry := Added;
  end;
  Added.Prev := Snapshot;
  Snapshot.Next := Added;
  Entry := Snapshot;
  while PrefixCount > 0 do
  begin
    Dec(PrefixCount);
    Added := CreateDecoy;
    Added.Next := Entry;
    Entry.Prev := Added;
    Entry := Added;
  end;
  Added.Prev := nil;
  if SnapshotHead <> nil then
    ClearSnapshots;
  SnapshotHead := Added;
end;

procedure TCCInterface.ClearSnapshots;
var
  Snapshot, Entry, Next: PCCSnapshot;
begin
  Snapshot := GetSnapshot;
  SnapshotHead := nil;
  Entry := Snapshot.Next;
  while Entry <> Snapshot do
  begin
    Next := Entry.Next;
    Dispose(Entry);
    Entry := Next;
  end;
  while Entry <> nil do
  begin
    Next := Entry.Prev;
    Dispose(Entry);
    Entry := Next;
  end;
end;

function TCCInterface.GetResourceChecksumFailed: Boolean;
begin
  Lock.Enter;
  Result := GetSnapshot.ResourceChecksumFailed;
  Lock.Leave;
end;

procedure TCCInterface.SetResourceChecksumFailed(Value: Boolean);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.ResourceChecksumFailed := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetTamperDetected: Boolean;
begin
  Lock.Enter;
  Result := GetSnapshot.TamperDetected;
  Lock.Leave;
end;

procedure TCCInterface.SetTamperDetected(Value: Boolean);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.TamperDetected := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetFlag0A: Boolean;
begin
  Lock.Enter;
  Result := GetSnapshot.Flag0A;
  Lock.Leave;
end;

procedure TCCInterface.SetFlag0A(Value: Boolean);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.Flag0A := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetEditableStateApplied: Boolean;
begin
  Lock.Enter;
  Result := GetSnapshot.EditableStateApplied;
  Lock.Leave;
end;

procedure TCCInterface.SetEditableStateApplied(Value: Boolean);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.EditableStateApplied := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetProtectedStateXorSeed: Integer;
begin
  Lock.Enter;
  Result := GetSnapshot.ProtectedStateXorSeed;
  Lock.Leave;
end;

procedure TCCInterface.SetProtectedStateXorSeed(Value: Integer);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.ProtectedStateXorSeed := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetValue10: Integer;
begin
  Lock.Enter;
  Result := GetSnapshot.Value10;
  Lock.Leave;
end;

procedure TCCInterface.SetValue10(Value: Integer);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.Value10 := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetIntegrityStatus: Integer;
begin
  Lock.Enter;
  Result := GetSnapshot.IntegrityStatus;
  Lock.Leave;
end;

procedure TCCInterface.SetIntegrityStatus(Value: Integer);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.IntegrityStatus := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetIntegrityError: Integer;
begin
  Lock.Enter;
  Result := GetSnapshot.IntegrityError;
  Lock.Leave;
end;

procedure TCCInterface.SetIntegrityError(Value: Integer);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.IntegrityError := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetIntegrityChecksum: Cardinal;
begin
  Lock.Enter;
  Result := GetSnapshot.IntegrityChecksum;
  Lock.Leave;
end;

procedure TCCInterface.SetIntegrityChecksum(Value: Cardinal);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.IntegrityChecksum := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetIntegrityChecksum1: Cardinal;
begin
  Lock.Enter;
  Result := GetSnapshot.IntegrityChecksum1;
  Lock.Leave;
end;

procedure TCCInterface.SetIntegrityChecksum1(Value: Cardinal);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.IntegrityChecksum1 := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetIntegrityChecksum2: Cardinal;
begin
  Lock.Enter;
  Result := GetSnapshot.IntegrityChecksum2;
  Lock.Leave;
end;

procedure TCCInterface.SetIntegrityChecksum2(Value: Cardinal);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.IntegrityChecksum2 := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
end;

function TCCInterface.GetEncodedCheatPoints: Integer;
begin
  Lock.Enter;
  Result := GetSnapshot.EncodedCheatPoints;
  Lock.Leave;
end;

procedure TCCInterface.SetEncodedCheatPoints(Value: Integer);
var
  Snapshot: PCCSnapshot;
begin
  Lock.Enter;
  Snapshot := CopySnapshot(GetSnapshot);
  Snapshot.EncodedCheatPoints := Value;
  CommitSnapshot(Snapshot);
  Lock.Leave;
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
    const FileName: UnicodeString;
    Pixels: Pointer;
    PitchBytes, Width, Height, HasAlpha, SwapRedBlue: Integer
): Integer;
var
  NativeName: AnsiString;
begin
  // OKGF uses fopen: translate OS paths here, including recorded BMP frames.
{$IFDEF MSWINDOWS}
  NativeName := AnsiString(NativeGamePath(FileName));
{$ELSE}
  NativeName := UTF8Encode(NativeGamePath(FileName));
{$ENDIF}
  try
    Result :=
        OKGF_Write_PNG_File(
            PAnsiChar(NativeName),
            Pixels,
            PitchBytes,
            Width,
            Height,
            HasAlpha,
            SwapRedBlue
        );
  except
    raise Exception.Create('Error in OKGF_Write_PNG_File');
  end;
end;

function WriteBmpFile(
    const FileName: UnicodeString;
    Pixels: Pointer;
    PitchBytes, BitsPerPixel: Integer;
    RedMask, GreenMask, BlueMask, AlphaMask: Cardinal;
    Width, Height: Integer
): Integer;
var
  NativeName: AnsiString;
begin
  // OKGF uses fopen: translate OS paths here, including recorded BMP frames.
{$IFDEF MSWINDOWS}
  NativeName := AnsiString(NativeGamePath(FileName));
{$ELSE}
  NativeName := UTF8Encode(NativeGamePath(FileName));
{$ENDIF}
  try
    Result :=
        OKGF_Write_BMP_File(
            PAnsiChar(NativeName),
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect;
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
    const Clip: TRect;
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
    const Clip: TRect
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
    const Clip: TRect;
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
    const Clip: TRect
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
    const Clip: TRect;
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

function Ex_OKGR_Planet2_TemplDel(TemplateData: Pointer): Integer;
begin
  try
    Result := OKGR_Planet2_TemplDel(TemplateData);
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect;
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
    const Clip: TRect
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
    const Clip: TRect
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
    const Clip: TRect
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
{$IFDEF MSWINDOWS}
var
  Mask: PtrUInt;
begin
  Mask := 1;
  if MultiThreadEnabled then
  begin
    while SetProcessAffinityMask(GetCurrentProcess, Mask) do
      Mask := (Mask shl 1) or 1;
    Exit;
  end;
  SetProcessAffinityMask(GetCurrentProcess, Mask);
end;
{$ELSE}
begin
  // FPC workers are scheduled by the host OS; no process-wide CPU pinning.
end;
{$ENDIF}

procedure CheckRuntimeWatchdog;
begin
  // The original jumped into generated x86 bytes to crash on watchdog failure.
  // Report the same fatal condition without executing data as machine code.
  if (RuntimeWatchdog <> nil) and not RuntimeWatchdog.IsRunning then
    raise EWorkerFailure.Create('Runtime watchdog stopped');
end;

procedure CreateStartupLogFile;
begin
  AssignFile(SessionLog, GetGameUserDirectory + '########.log');
  Rewrite(SessionLog);
  Writeln(SessionLog, 'Start');
  CloseFile(SessionLog);
end;

procedure InitializePlatformRuntimeAndMainWindow;
begin
  InitializeGameVideo;
  DirectSoundCreate := CreateGameSound;
  DirectSoundEnumerate := EnumerateGameSound;
  DebugCommandMessage := $C000;
  DirectXVersion := $090000;
  CopyGameFile('#ship_c.dbf', '#ship.dbf');
  AppendLogLineThreadSafe('Build=2.1.2500 (11 August 2026)');
  PerformanceCounterFrequency := SDL_GetPerformanceFrequency;
  if not InitializePackageCollection then
    raise Exception.Create('Error while initializing package files');
  // The UI uses this as an identity token. SDL owns the actual native window.
  MainWindowHandle := 1;
  InstallConfig := TBlockParEC.Create;
  InstallConfig.LoadFromTextFileWithEncodingProbe('install.txt', False);
  QuestMessages := TQuestMessages.Create;
end;

procedure LoadLanguageAndPackages;
begin
  if RequestedLanguage <> '' then
  begin
    if not FileExists(NativeGamePath('install_' + RequestedLanguage + '.txt')) then
    begin
      AppendLogLineThreadSafe('Not installed - ' + RequestedLanguage);
      RequestedLanguage := '';
    end
    else
      SelectedLanguage := RequestedLanguage;
  end;
  if SelectedLanguage <> '' then
    if not FileExists(NativeGamePath('install_' + SelectedLanguage + '.txt')) then
    begin
      AppendLogLineThreadSafe('Not installed - ' + SelectedLanguage + ', try to switch to russian');
      SelectedLanguage := 'russian';
    end;
  if SelectedLanguage = '' then
    SelectedLanguage := 'russian';
  // Keep the else: DCC32 emits the native jump at $4CBAB6 after the raise.
  if not FileExists(NativeGamePath('install_' + SelectedLanguage + '.txt')) then
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
  if FileExists(NativeGamePath('Mods\ModCFG.txt')) then
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
      if FileExists(NativeGamePath('Mods\' + ModPath + 'Install.txt')) then
      begin
        Block := TBlockParEC.Create;
        ModInstallConfigs.Add(Block);
        Block
            .LoadFromTextFileWithEncodingProbe(PWideChar('Mods\' + ModPath + 'Install.txt'), False);
      end;
      if FileExists(NativeGamePath('Mods\' + ModPath + 'Install_' + SelectedLanguage + '.txt')) then
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
  // Drop every device-owned image before SDL destroys its renderer.
  OffscreenTexture := nil;
  Direct3DDevice := nil;
  Direct3D := nil;
  CloseGameWindow;
  MainWindowHandle := 0;
end;

function HasWow64Support: Boolean;
{$IFDEF MSWINDOWS}
type
  TGetNativeSystemInfo = procedure(var Info: TSystemInfo); stdcall;
  TIsWow64Process = function(Process: THandle; var IsWow64: LongBool): LongBool; stdcall;
var
  Module: HModule;
  NativeSystemInfo: TGetNativeSystemInfo;
  IsWow64Process: TIsWow64Process;
  Wow64: LongBool;
  Supported: Boolean;
  Info: TSystemInfo;
begin
  Supported := False;
  Module := GetModuleHandle('kernel32.dll');
  NativeSystemInfo := GetProcAddress(Module, 'GetNativeSystemInfo');
  if Assigned(NativeSystemInfo) then
  begin
    NativeSystemInfo(Info);
    IsWow64Process := GetProcAddress(Module, 'IsWow64Process');
    if Assigned(IsWow64Process) then
      if IsWow64Process(GetCurrentProcess, Wow64) then
        if Wow64 then
          if GetProcAddress(GetModuleHandle('kernel32.dll'), 'Wow64DisableWow64FsRedirection')
              <> nil then
            if GetProcAddress(Module, 'GetSystemWow64DirectoryA') <> nil then
              if GetProcAddress(GetModuleHandle('advapi32.dll'), 'RegDeleteKeyExA') <> nil then
                Supported := True;
  end
  else
    GetSystemInfo(Info);
  Result := Supported;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

procedure ApplyMainWindowGeometry;
var
  Style: Cardinal;
  Width, Height: Integer;
  Bounds: TRect;
begin
  if AlternateViewportEnabled then
  begin
    Width := PresentationWidth;
    Height := PresentationHeight;
  end
  else
  begin
    Width := GameScreenWidth;
    Height := GameScreenHeight;
  end;
  if Direct3DPresentParameters.Windowed then
  begin
    if (UserSettingsConfig.CountParams('ShowCaption') > 0)
        and not ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('ShowCaption'))) then
      Style := $10000000
    else
      Style := $10CA0000;
    if UserSettingsConfig.CountParams('OverrideWindowPosition') > 0 then
    begin
      Bounds.Left :=
          ExtractSignedDigitsToIntW(
              ExtractDelimitedPartW(
                  TrimWideString(
                      UserSettingsConfig.GetParamByPathOrMarker('OverrideWindowPosition')
                  ),
                  0,
                  ','
              )
          );
      Bounds.Top :=
          ExtractSignedDigitsToIntW(
              ExtractDelimitedPartW(
                  TrimWideString(
                      UserSettingsConfig.GetParamByPathOrMarker('OverrideWindowPosition')
                  ),
                  1,
                  ','
              )
          );
    end
    else
    begin
      Bounds.Left := (DesktopDisplayMode.Width - Cardinal(Width)) div 2;
      Bounds.Top := (DesktopDisplayMode.Height - Cardinal(Height)) div 2;
    end;
    Bounds.Right := Bounds.Left + Width;
    Bounds.Bottom := Bounds.Top + Height;
  end
  else
  begin
    Style := $90080000;
    Bounds.Left := 0;
    Bounds.Top := 0;
    Bounds.Right := Width;
    Bounds.Bottom := Height;
  end;
  // Window changes preserve the current target, so recover a pending SDL loss
  // before that handle can be saved and rebound by OpenGameWindow.
  if Direct3DDevice <> nil then
    Direct3DDevice.TestCooperativeLevel;
  OpenGameWindow(Width, Height, Direct3DPresentParameters.Windowed, VSyncEnabled);
  if Direct3DPresentParameters.Windowed then
  begin
    SDL_SetWindowPosition(GameSDLWindow, Bounds.Left, Bounds.Top);
    SDL_SetWindowBordered(GameSDLWindow, Ord(Style <> $10000000));
  end;
end;

procedure ShowAndFocusMainWindow;
begin
  SDL_RaiseWindow(GameSDLWindow);
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
  ); { An empty tree produces a log warning, not an exception from this wrapper. }
  begin
    Root.LoadFromEncryptedDatFile(FileName);
    if (Root.GetBlockCount <= 0) and (Root.GetParamCount <= 0) then
      AppendLogLineThreadSafe('Warning! <' + FileName + '> is empty!');
  end;

  procedure LoadCacheDatConfig(Root: TDataEC; FileName: WideString);
  begin
    Root.LoadFromEncryptedDatFile(FileName);
    if Root.IsEmpty then
      AppendLogLineThreadSafe('Warning! <' + FileName + '> is empty!');
  end;

begin
  MainDataConfig := TBlockParEC.Create;
  ModNames := '';
  if not SkipModsOnReload and FileExists(NativeGamePath('Mods\ModCFG.txt')) then
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
      if FileExists(NativeGamePath('Mods\' + ModPath + 'CFG\Main.dat')) then
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
      if FileExists(
          NativeGamePath(
              'Mods\' + ModPath + 'CFG\' + LanguageInstallConfig.GetParam('Lang') + '\Lang.dat'
          )) then
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
      if FileExists(NativeGamePath('Mods\' + ModPath + 'CFG\CacheData.dat')) then
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
  SavedChecksumFailed: Boolean;
{$IFDEF MSWINDOWS}
  Reg: TRegistry;
{$ENDIF}
  MemoryStatus: TMemoryStatusEx;

  procedure VerifyStartupModuleChecksum; { Nested startup helper; checks the module path at parent-frame -4 and writes the signed integrity marker. }
  var
    MarkerOffset: Integer;
  begin
    CCInterface.SetResourceChecksumFailed(False);
    VerifyResourceFileChecksum(ModuleName);
    MarkerOffset := 8;
    if CCInterface.GetResourceChecksumFailed then
      PInteger(PAnsiChar(@StartupChecksumAnchor) - MarkerOffset)^ :=
          RandomIntRange(1000000000, 2000000000)
    else if PInteger(PAnsiChar(@StartupChecksumAnchor) - MarkerOffset)^ <= 0 then
      PInteger(PAnsiChar(@StartupChecksumAnchor) - MarkerOffset)^ :=
          RandomIntRange(-2000000000, -1000000000);
    CCInterface.SetResourceChecksumFailed(False);
  end;

begin
  StartupState := 0;
  FinalizeRuntimeAndSettings;
{$IFDEF MSWINDOWS}
  Text :=
      TrimWideString(
          ReadRegistryText(
              HKEY_LOCAL_MACHINE,
              'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'ProductName',
              ''
          )
      );
  if HasWow64Support then
    ExtraText := ' [x64] build '
  else
    ExtraText := ' [x86] build ';
  ModuleName :=
      TrimWideString(
          ReadRegistryText(
              HKEY_LOCAL_MACHINE,
              'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'CurrentBuild',
              ''
          )
      );
  if ExtractDigitsToIntW(ModuleName) >= 22000 then
    Text := ReplaceAllWideString(Text, 'Windows 10', 'Windows 11');
  if RunningUnderWine then
    AppendLogLineThreadSafe(
        AnsiString('Wine compatibility mode is set to ''' + Text + ExtraText + ModuleName + '''')
    )
  else
    AppendLogLineThreadSafe(AnsiString('Operating System=' + Text + ExtraText + ModuleName));
  Index := 0;
  Count := 0;
  while True do
  begin
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      if Reg.KeyExists('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)) then
        Inc(Count)
      else
        Break;
      Inc(Index);
    finally
      Reg.Free;
    end;
  end;
  Index := 0;
  Text :=
      TrimWideString(
          ReadRegistryText(
              HKEY_LOCAL_MACHINE,
              WideString('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)),
              'Identifier',
              ''
          )
      );
  ExtraText :=
      TrimWideString(
          ReadRegistryText(
              HKEY_LOCAL_MACHINE,
              WideString('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)),
              'ProcessorNameString',
              ''
          )
      );
{$ELSE}
  AppendLogLineThreadSafe('Operating System=' + {$I %FPCTARGETOS%});
  Count := SDL_GetCPUCount;
  ExtraText := {$I %FPCTARGETCPU%};
{$ENDIF}
  if Count <= 1 then
    ModuleName := ' (1 core)'
  else
    ModuleName := WideString(' (' + IntToStr(Count) + ' cores)');
  ProcessorCoreCount := Max(Count, 1);
  AppendLogLineThreadSafe(AnsiString('Processor=' + ExtraText + ModuleName));
  AppendLogLineThreadSafe(
      'CPU Clock='
          + IntToStr(Round(Min(Min(MeasureCpuClockMHz, MeasureCpuClockMHz), MeasureCpuClockMHz)))
          + ' MHz'
  );
  MemoryStatus.Length := SizeOf(MemoryStatus);
  QueryGameMemory(MemoryStatus);
  AppendLogLineThreadSafe(
      'Physical Memory Total=' + IntToStr(MemoryStatus.TotalPhys div $100000) + ' MB'
  );
  AppendLogLineThreadSafe(
      'Physical Memory Available=' + IntToStr(MemoryStatus.AvailPhys div $100000) + ' MB'
  );
  AppendLogLineThreadSafe(
      'Page File Total=' + IntToStr(MemoryStatus.TotalPageFile div $100000) + ' MB'
  );
  AppendLogLineThreadSafe(
      'Page File Available=' + IntToStr(MemoryStatus.AvailPageFile div $100000) + ' MB'
  );
  AppendLogLineThreadSafe(
      'Virtual Memory Total=' + IntToStr(MemoryStatus.TotalVirtual div $100000) + ' MB'
  );
  AppendLogLineThreadSafe(
      'Virtual Memory Available=' + IntToStr(MemoryStatus.AvailVirtual div $100000) + ' MB'
  );
  UserSettingsConfig := TBlockParEC.Create;
  Text := GetGameUserDirectory + 'CFG.TXT';
  if not FileExists(NativeGamePath(AnsiString(Text))) then
  begin
    AppendLogTextThreadSafe('Creating cfg.txt ... ');
    CopyGameFile('cfg.txt', Text);
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
  if FileExists(NativeGamePath(AnsiString(PWideChar(Text)))) then
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
  if UserSettingsConfig.CountParams('ShowSystemMouse') > 0 then
    ShowSystemMouse :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('ShowSystemMouse'))
        );
  if FileExists(NativeGamePath('Mods\ShipName.txt')) then
  begin
    ModShipNameConfig := TBlockParEC.Create;
    ModShipNameConfig.LoadFromTextFileWithEncodingProbe('Mods\ShipName.txt', False);
  end;
  if FileExists(NativeGamePath('Mods\RuinName.txt')) then
  begin
    ModRuinNameConfig := TBlockParEC.Create;
    ModRuinNameConfig.LoadFromTextFileWithEncodingProbe('Mods\RuinName.txt', False);
  end;
  if FileExists('MusicChange.txt') then
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
    if MemoryStatus.AvailVirtual > $48000000 then
      GlobalCache.ResidentByteLimit := $18000000
    else
      GlobalCache.ResidentByteLimit :=
          Min(Int64(Cardinal(MemoryStatus.AvailVirtual) div 3), Int64($18000000));
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
    ShowGameCursor(False);
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
  SavedChecksumFailed := CCInterface.GetResourceChecksumFailed;
{$IF Defined(MSWINDOWS) and Defined(CPU386)}
  Text := 'll';
  Text := '.d' + Text;
  ModuleName := DecodeTextW('sotoenalm^_^aucah') + Text; // Decoded: 'steam_ach'
  if GetModuleHandleW(PWideChar(ModuleName)) <> 0 then
    VerifyStartupModuleChecksum;
  ModuleName := DecodeTextW('sotoenalm^_^aupki') + Text; // Decoded: 'steam_api'
  if GetModuleHandleW(PWideChar(ModuleName)) <> 0 then
    VerifyStartupModuleChecksum;
  ModuleName := DecodeTextW('zoloimba') + Text; // Decoded: 'zlib'
  VerifyStartupModuleChecksum;
  ModuleName := DecodeTextW('MhastorhinxaGrakmae') + Text; // Decoded: 'MatrixGame'
  VerifyStartupModuleChecksum;
  ModuleName := DecodeTextW('ookogifa') + Text; // Decoded: 'okgf'
  VerifyStartupModuleChecksum;
  ModuleName := DecodeTextW('xavriadeccomrie') + Text; // Decoded: 'xvidcore'
  VerifyStartupModuleChecksum;
  ExtraText := 'ib';
  ExtraText := 'l' + ExtraText;
  ModuleName := ExtraText + DecodeTextW('osgaga-10a') + Text; // Decoded: 'ogg-0'
  VerifyStartupModuleChecksum;
  ModuleName := ExtraText + DecodeTextW('vrokrablius-->0') + Text; // Decoded: 'vorbis-0'
  VerifyStartupModuleChecksum;
  ModuleName := ExtraText + DecodeTextW('veohrablissufainlae') + Text; // Decoded: 'vorbisfile'
  VerifyStartupModuleChecksum;
{$ENDIF}
  CCInterface.SetResourceChecksumFailed(SavedChecksumFailed);
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
  if GameDisplayModeCount = 0 then
    Direct3D.GetAdapterDisplayMode(D3DADAPTER_DEFAULT, DesktopDisplayMode);
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
  ModeCount := Direct3D.GetAdapterModeCount(D3DADAPTER_DEFAULT, DesktopDisplayMode.Format);
  if (DesktopDisplayMode.Format <> D3DFMT_X8R8G8B8)
      and (DesktopDisplayMode.Format <> D3DFMT_A8R8G8B8) then
    DesktopDisplayMode.Format := D3DFMT_X8R8G8B8;
  Modes := TBlockParEC.Create;
  for Index := 0 to ModeCount - 1 do
  begin
    Direct3D.EnumAdapterModes(D3DADAPTER_DEFAULT, DesktopDisplayMode.Format, Index, Mode);
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
    Direct3D.EnumAdapterModes(
        D3DADAPTER_DEFAULT,
        DesktopDisplayMode.Format,
        SysUtils.StrToInt(AnsiString(ExtractDelimitedPartW(ModeKey, 1, ','))),
        Mode
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
    System.FillChar(Pointer(@Direct3DPresentParameters)^, SizeOf(Direct3DPresentParameters), 0);
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
  Code: Integer;
  Surface: IDirect3DSurface9;
  Index, MiniMapSize: Integer;
  Angle: Single;
  DeviceFlags: Cardinal;
  Identifier: TD3DAdapterIdentifier9;
  Caps: TD3DCaps9;
begin
  FreeScreenRenderBuffers;
  WindowedModeRequested := False;
  if UserSettingsConfig.CountParams('Window') > 0 then
    WindowedModeRequested :=
        ParseEnabledNameGI(TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('Window')));
  VSyncEnabled := False;
  if UserSettingsConfig.CountParams('VSync') > 0 then
    VSyncEnabled :=
        ParseEnabledNameGI(TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('VSync')));
  HardwareRenderingRequested := False;
  if UserSettingsConfig.CountParams('HardwareRender') > 0 then
    HardwareRenderingRequested :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('HardwareRender'))
        );
  HardwareRenderingEnabled :=
      HardwareRenderingRequested
          and (not RunningUnderWine
              or ((UserSettingsConfig.CountParams('AllowHardwareRenderUnderWine') <> 0)
                  and ParseEnabledNameGI(
                      TrimWideString(
                          UserSettingsConfig.GetParamByPathOrMarker('AllowHardwareRenderUnderWine')
                      ))));
  ScaleViewportToWindow := True;
  if UserSettingsConfig.CountParams('RenderModeScale') > 0 then
    ScaleViewportToWindow :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('RenderModeScale'))
        );
  TextureManagerDisabled := False;
  if UserSettingsConfig.CountParams('DisableTextureManager') > 0 then
    TextureManagerDisabled :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('DisableTextureManager'))
        );
  PresentWithoutLimit := False;
  if UserSettingsConfig.CountParams('DisableFrameLimit') > 0 then
    PresentWithoutLimit :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('DisableFrameLimit'))
        );
  DisableHardwareVertexProcessing := False;
  if UserSettingsConfig.CountParams('DisableHWVertexProcessing') > 0 then
    DisableHardwareVertexProcessing :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('DisableHWVertexProcessing'))
        );
  DisableMultithreadFlag := False;
  if UserSettingsConfig.CountParams('DisableMultithreadFlag') > 0 then
    DisableMultithreadFlag :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('DisableMultithreadFlag'))
        );
  DisableTripleBuffer := False;
  if UserSettingsConfig.CountParams('DisableTripleBuffer') > 0 then
    DisableTripleBuffer :=
        ParseEnabledNameGI(
            TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('DisableTripleBuffer'))
        );
  ScreenRenderBuffer := TGraphBufGR.Create(True);
  RenderScratchBuffer := TGraphBufGR.Create(True);
  AuxRenderBuffer := TGraphBufGR.Create(True);
  // $133F and $FCFF selects nearest rounding, single x87 precision and masked exceptions.
  // Fixed-precision CPUs retain their native precision through FPC.
  ClearExceptions(False);
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  SetRoundMode(rmNearest);
  SetPrecisionMode(pmSingle);
  try
    if Direct3D = nil then
    begin
      Direct3D := CreateGameGraphics;
      // Native constructs this exception without raising it.
      if Direct3D = nil then
        EDirectXRender.Create('GR_DXInit()::Direct3DCreate9(...)');
      AppendLogLineThreadSafe('Initializing DX9.... ok!');
      Direct3D.GetAdapterIdentifier(D3DADAPTER_DEFAULT, 0, Identifier);
      AppendLogLineThreadSafe('Videocard=' + AnsiString(Identifier.Description));
      AppendLogLineThreadSafe('Driver=' + AnsiString(Identifier.Driver));
    end;
    SupportedMultiSamples := nil;
    SupportedMultiSampleCount := 0;
    for Index := 0 to 16 do
      if Direct3D.CheckDeviceMultiSampleType(
              D3DADAPTER_DEFAULT,
              D3DDEVTYPE_HAL,
              D3DFMT_A8R8G8B8,
              False,
              Index,
              nil)
          = 0 then
      begin
        SetLength(SupportedMultiSamples, SupportedMultiSampleCount + 1);
        SupportedMultiSamples[SupportedMultiSampleCount] := Index;
        Inc(SupportedMultiSampleCount);
      end;
    if Direct3D.GetDeviceCaps(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, Caps) = 0 then
      MaximumAnisotropy := Caps.MaxAnisotropy;
    MaxTextureSize.X := Caps.MaxTextureWidth;
    MaxTextureSize.Y := Caps.MaxTextureHeight;
    AppendLogLineThreadSafe(
        'Max Texture Size='
            + IntToStr(Int64(Caps.MaxTextureWidth))
            + 'x'
            + IntToStr(Int64(Caps.MaxTextureHeight))
    );
    EnumerateAndSelectDisplayModes;
    PreparePresentationParameters;
    ApplyMainWindowGeometry;
    if Direct3DDevice = nil then
    begin
      DeviceFlags := 0;
      if not DisableMultithreadFlag then
        DeviceFlags := D3DCREATE_MULTITHREADED;
      if not DisableHardwareVertexProcessing then
        Code :=
            Direct3D.CreateDevice(
                D3DADAPTER_DEFAULT,
                D3DDEVTYPE_HAL,
                MainWindowHandle,
                DeviceFlags or D3DCREATE_HARDWARE_VERTEXPROCESSING,
                Direct3DPresentParameters,
                Direct3DDevice
            )
      else
        Code := -1;
      if Code <> 0 then
        Code :=
            Direct3D.CreateDevice(
                D3DADAPTER_DEFAULT,
                D3DDEVTYPE_HAL,
                MainWindowHandle,
                DeviceFlags or D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                Direct3DPresentParameters,
                Direct3DDevice
            );
      if (Code <> 0) or (Direct3DDevice = nil) then
      begin
        AppendLogLineThreadSafe(
            'Error: GR_DXInit()::GR_Direct3D.CreateDevice, failed to create device, trying to switch to minimal resolution...'
        );
        SelectedGameDisplayMode := SmallestGameDisplayMode;
        GameScreenWidth := GameDisplayModes[SelectedGameDisplayMode].Width;
        GameScreenHeight := GameDisplayModes[SelectedGameDisplayMode].Height;
        PresentationWidth := GameScreenWidth;
        PresentationHeight := GameScreenHeight;
        ExtraScreenWidth := GameScreenWidth - 1024;
        ExtraScreenHeight := GameScreenHeight - 768;
        GameScreenRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
        PresentationRect := Classes.Rect(0, 0, PresentationWidth, PresentationHeight);
        WindowedModeRequested := True;
        AlternateViewportEnabled := False;
        PreparePresentationParameters;
        ApplyMainWindowGeometry;
        Code :=
            Direct3D.CreateDevice(
                D3DADAPTER_DEFAULT,
                D3DDEVTYPE_HAL,
                MainWindowHandle,
                DeviceFlags or D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                Direct3DPresentParameters,
                Direct3DDevice
            );
        if (Code <> 0) or (Direct3DDevice = nil) then
        begin
          LogPresentationParameters;
          raise EDirectXRender.CreateCode('GR_DXInit()::GR_Direct3D.CreateDevice', Code);
        end;
      end;
      Direct3DDevice.GetRenderTarget(0, Surface);
      Direct3DDevice.ColorFill(Surface, nil, 0);
      Direct3DDevice.GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, Surface);
      Direct3DDevice.ColorFill(Surface, nil, 0);
      Direct3DDevice.GetBackBuffer(0, 1, D3DBACKBUFFER_TYPE_MONO, Surface);
      Direct3DDevice.ColorFill(Surface, nil, 0);
      AppendLogLineThreadSafe('Initializing Direct3D device... ok!');
    end
    else
    begin
      Code := Direct3DDevice.Reset(Direct3DPresentParameters);
      if Code <> 0 then
      begin
        LogPresentationParameters;
        raise EDirectXRender.CreateCode('GR_DXInit()::GR_D3DDevice.Reset', Code);
      end;
      AppendLogLineThreadSafe('Re-initializing Direct3D device... ok!');
    end;
    AvailableTextureBytes := Direct3DDevice.GetAvailableTextureMem;
    ReservedTextureBytes :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('VideoMemSizeLimit'));
    AppendLogLineThreadSafe(
        'Available Video Memory=' + IntToStr(Int64(AvailableTextureBytes shr 10)) + ' KB'
    );
    if Integer(ReservedTextureBytes) > 0 then
    begin
      AppendLogLineThreadSafe(
          'Available Video Memory Override='
              + IntToStr(Integer(ReservedTextureBytes shl 10))
              + ' KB'
      );
      ReservedTextureBytes := AvailableTextureBytes - ((ReservedTextureBytes shl 10) shl 10);
    end;
    UserSettingsConfig.GetParam('VideoMemSizeLimit');
    for Index := Low(DrawVertices) to High(DrawVertices) do
    begin
      DrawVertices[Index].Z := 1;
      DrawVertices[Index].RHW := 1;
    end;
    Direct3DDevice.SetVertexShader(nil);
    Direct3DDevice.SetFVF(D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1);
    ConfigureDefaultRenderState;
    AppendLogTextThreadSafe('Display Mode=');
    if not Direct3DPresentParameters.Windowed then
    begin
      AppendLogTextThreadSafe(
          IntToStr(Int64(Direct3DPresentParameters.BackBufferWidth))
              + 'x'
              + IntToStr(Int64(Direct3DPresentParameters.BackBufferHeight))
              + ' '
              + IntToStr(Int64(Direct3DPresentParameters.FullScreenRefreshRateInHz))
              + 'Hz'
      );
      if AlternateViewportEnabled then
        AppendLogLineThreadSafe(
            ' ['
                + IntToStr(Int64(Cardinal(GameScreenWidth)))
                + 'x'
                + IntToStr(Int64(Cardinal(GameScreenHeight)))
                + ']'
        );
    end
    else
    begin
      if AlternateViewportEnabled then
        AppendLogTextThreadSafe(
            IntToStr(Int64(Cardinal(PresentationWidth)))
                + 'x'
                + IntToStr(Int64(Cardinal(PresentationHeight)))
                + ' ['
        );
      AppendLogTextThreadSafe(
          IntToStr(Int64(Cardinal(GameScreenWidth)))
              + 'x'
              + IntToStr(Int64(Cardinal(GameScreenHeight)))
      );
      if AlternateViewportEnabled then
        AppendLogTextThreadSafe(']');
    end;
    AppendLogLineThreadSafe('');
  except
    on E: EDirectXRender do
    begin
      ThreeDimensionalModeEnabled := False;
      Direct3DDevice := nil;
      Direct3D := nil;
    end;
  end;
  CurrentPixelFormat := TPixelFormatGR.Create;
  CurrentPixelFormat.RedMask := $F800;
  CurrentPixelFormat.GreenMask := $7E0;
  CurrentPixelFormat.BlueMask := $1F;
  CurrentPixelFormat.AlphaMask := 0;
  CurrentPixelFormat.BytesPerPixel := 2;
  CurrentPixelFormat.RebuildChannelMetrics;
  BlendPixel16 := @OKGR_PixelAlpha_16;
  TriangleRasterizer16 := @OKGF_Triangle_16;
  LineRasterizer16 := @OKGF_LineIp_16;
  ScreenRenderBuffer.AllocateNativePitch(GameScreenWidth, GameScreenHeight, 2 * GameScreenWidth);
  if GameDataConfig.CountParams('MiniMapBufSize') > 0 then
    MiniMapSize := ExtractDigitsToIntW(GameDataConfig.GetParam('MiniMapBufSize'))
  else
    MiniMapSize := 156;
  RenderScratchBuffer.AllocateNative(MiniMapSize, MiniMapSize);
  ApplyGammaRamp(DisplayBrightness, DisplayContrast);
  // Native uses two different approximations of pi for these tables.
  for Index := Low(CircleCos) to High(CircleCos) do
  begin
    Angle := Index * (3.1415926 / 180);
    CircleCos[Index] := Cos(Angle);
    CircleSin[Index] := Sin(Angle);
  end;
  for Index := Low(LineAlphaTable) to High(LineAlphaTable) do
    LineAlphaTable[Index] := Trunc(Cos(Index / 180 * 3.14159265354) * 127 + 128);
  PendingPointCapacity := 1024;
  SetLength(PendingPoints, PendingPointCapacity);
end;

procedure GR_DXReset;
var
  ErrorCode: Integer;
begin
  PreparePresentationParameters;
  if not Direct3DPresentParameters.Windowed then
    ApplyMainWindowGeometry;
  if Direct3DDevice = nil then
  begin
    ErrorCode :=
        Direct3D.CreateDevice(
            D3DADAPTER_DEFAULT,
            D3DDEVTYPE_HAL,
            MainWindowHandle,
            D3DCREATE_MULTITHREADED or D3DCREATE_HARDWARE_VERTEXPROCESSING,
            Direct3DPresentParameters,
            Direct3DDevice
        );
    if ErrorCode <> 0 then
      ErrorCode :=
          Direct3D.CreateDevice(
              D3DADAPTER_DEFAULT,
              D3DDEVTYPE_HAL,
              MainWindowHandle,
              D3DCREATE_MULTITHREADED or D3DCREATE_SOFTWARE_VERTEXPROCESSING,
              Direct3DPresentParameters,
              Direct3DDevice
          );
    if (ErrorCode <> 0) or (Direct3DDevice = nil) then
    begin
      LogPresentationParameters;
      raise EDirectXRender.CreateCode('GR_DXReset()::GR_Direct3D.CreateDevice(...)', ErrorCode);
    end;
  end
  else
  begin
    ErrorCode := Direct3DDevice.Reset(Direct3DPresentParameters);
    if ErrorCode <> 0 then
    begin
      LogPresentationParameters;
      raise EDirectXRender.CreateCode('GR_DXReset()::GR_D3DDevice.Reset(...)', ErrorCode);
    end;
  end;
  Direct3DDevice.SetVertexShader(nil);
  Direct3DDevice.SetFVF(D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1);
  ConfigureDefaultRenderState;
  if Direct3DPresentParameters.Windowed then
    ApplyMainWindowGeometry;
  ShowAndFocusMainWindow;
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
  if Direct3DDevice = nil then
    Exit;
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
  Direct3DDevice.SetGammaRamp(0, 0, Ramp);
end;

function GR_WinMessage(Callback: TWindowMessageCallbackGR): Integer;
var
  ContinueLoop, Stage: Integer;
  Msg: TGameMessage;
begin
  Stage := 0;
  try
    if SoundManager <> nil then
      SoundManager.UpdateFades;
    Stage := 1;
    ContinueLoop := 1;
    while True do
    begin
      if ExitScreenLoop then
      begin
        Result := 0;
        Exit;
      end;
      Stage := 2;
      if (GameTickCount - LastWindowMessageTick > 5000) and not MessageIdle then
      begin
        MessageIdle := True;
        if Assigned(OnMessageIdle) then
          OnMessageIdle;
      end;
      Stage := 3;
      if LastMouseMessageTick <> 0 then
        if (GameTickCount - LastMouseMessageTick > 100) and RuntimeActive then
        begin
          LastMouseMessageTick := GameTickCount;
          PostMouseMoveMessage;
        end;
      Stage := 4;
      while PollGameMessage(Msg) do
      begin
        Stage := 5;
        if MessageIdle and Assigned(OnMessageResume) then
          OnMessageResume;
        MessageIdle := False;
        LastWindowMessageTick := GameTickCount;
        Stage := 6;
        Stage := 7;
        if Msg.message <> DebugCommandMessage then
          if Msg.message = WM_QUIT then
            ContinueLoop := 0;
        Stage := 8;
        if Msg.message = WM_MOUSEMOVE then
        begin
          LastMouseMessageTick := 0;
        end;
        Stage := 9;
        MainWindowProc(MainWindowHandle, Msg.Message, Msg.WParam, Msg.LParam);
        Stage := 10;
        if Assigned(Callback) and GameWindowFocused then
          Callback(Msg.message, Msg.wParam, Msg.lParam);
      end;
      Stage := 11;
      if (ContinueLoop = 0) or RuntimeActive then
        Break;
      SysUtils.Sleep(1);
    end;
    Result := ContinueLoop;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create(
          'Error in procedure GR_WinMessage, label = ' + SysUtils.IntToStr(Stage));
    end;
  end;
end;

function MainWindowProc(Window, Message, WParam: Cardinal; LParam: Integer): Integer; stdcall;
var
  Origin: TPoint;
  Bounds: TRect;
  Index: Integer;
begin
  if Message = WM_GAME_RENDER_RESET then
  begin
    if Direct3DDevice <> nil then
      Direct3DDevice.TestCooperativeLevel;
    FullFrameRedrawRequested := True;
    // Include modal loops and paused parents: their shared screen target was
    // lost too. Queue directly even when a continuous loop disables invalidation.
    if MessageLoopStack <> nil then
      for Index := 0 to MessageLoopStack.Count - 1 do
        TMessageLoopGI(MessageLoopStack[Index]).UpdateRects.AddRect(GameScreenRect);
  end
  else if Message = WM_ACTIVATEAPP then
  begin
    if WParam <> 0 then
    begin
      if Direct3DDevice <> nil then
        if Direct3DDevice.TestCooperativeLevel = D3DERR_DEVICENOTRESET then
          GR_DXReset;
      if not Direct3DPresentParameters.Windowed then
      begin
        Origin := Classes.Point(GameScreenRect.Left, GameScreenRect.Top);

        Bounds :=
            Classes.Rect(
                Origin.X + GameScreenRect.Left,
                Origin.Y + GameScreenRect.Top,
                Origin.X + GameScreenRect.Right,
                Origin.Y + GameScreenRect.Bottom
            );
        SDL_SetWindowGrab(GameSDLWindow, 1);
      end;
      if Assigned(OnGameActivated) then
        OnGameActivated(nil);
    end
    else
    begin
      if Direct3DDevice <> nil then
        Direct3DDevice.TestCooperativeLevel;
      if not Direct3DPresentParameters.Windowed then
        SDL_SetWindowGrab(GameSDLWindow, 0);
      if Assigned(OnGameDeactivated) then
        OnGameDeactivated(nil);
    end;
    if WParam <> 0 then
    begin
      if CurrentScreenId = screenPlanetNO then
        TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).UpdateActionCursor(False)
      else if (CurrentScreenId = screenShip) or (CurrentScreenId = screenStarMap) then
        TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).UpdateActionCursor(True);
      if (TMessageLoopGI(RegisteredScreens[Ord(screenShip)]) <> nil)
          and (TMessageLoopGI(RegisteredScreens[Ord(screenShip)]).GetActionParentLoop <> nil)
          and (TMessageLoopGI(RegisteredScreens[Ord(screenShip)]).GetActionParentLoop
              = TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)])) then
        TMessageLoopGI(RegisteredScreens[Ord(screenShip)]).UpdateActionCursor(True);
    end;
  end
  else if Message = WM_DESTROY then
  begin
    if ExitScreenLoop then
      PostGameMessage(WM_QUIT, 0, 0);
  end
  else if Message = WM_ERASEBKGND then
  begin
    Result := 1;
    Exit;
  end
  else if Message = WM_PAINT then
  begin
    if Direct3DPresentParameters.Windowed then
      PresentScreenBuffer;
  end
  else if Message = WM_MOUSEMOVE then
  begin
  end
  else if Message = WM_LBUTTONDOWN then
  begin
  end
  else if Message = WM_LBUTTONUP then
  begin
  end
  else if Message = WM_RBUTTONDOWN then
  begin
  end
  else if Message = WM_RBUTTONUP then
  begin
  end
  else if (Message = WM_SYSKEYDOWN) and (WParam in [VK_MENU, VK_LEFT..VK_DOWN]) then
  begin
    Result := 1;
    Exit;
  end
  else if (Message = WM_SYSKEYUP) and (WParam in [VK_MENU, VK_LEFT..VK_DOWN]) then
  begin
    Result := 1;
    Exit;
  end
  else if Message = WM_KEYDOWN then
  begin
    if (WParam = Ord('R'))
        and IsVirtualKeyDown(VK_CONTROL)
        and IsVirtualKeyDown(VK_SHIFT)
        and IsVirtualKeyDown(VK_MENU)
        and (CurrentScreenId <> screenNone) then
    begin
    end;
  end
  else if Message = WM_CLOSE then
    ExitScreenLoop := True
  else if Message = WM_CANCELMODE then
    RuntimeActive := False
  else if Message = WM_SETCURSOR then
  begin
    Result := 1;
    Exit;
  end
  else if Message = WM_TIMER then
  begin
    CheckRuntimeWatchdog;
    Result := 1;
    Exit;
  end;
  Result := 0;
end;

function BeginFramePresentation: Boolean;
begin
  Inc(PresentationDepth);
  Result := True;
end;

procedure EndFramePresentation;
var
  Tick: Cardinal;
begin
  if PresentationDepth > 0 then
  begin
    Dec(PresentationDepth);
    if PresentationDepth = 0 then
    begin
      if PresentWithoutLimit then
        PresentScreenBuffer
      else
      begin
        Tick := GameTickCount;
        if 1000 div PresentationFrameRate < Tick - LastPresentationTick then
        begin
          LastPresentationTick := Tick;
          PresentScreenBuffer;
        end;
      end;
    end;
  end;
end;

procedure PresentScreenBuffer;
begin
  if HardwareRenderingEnabled then
  begin
    Direct3DDevice.EndScene;
    Direct3DDevice.Present(nil, nil, 0, nil);
    Direct3DDevice.BeginScene;
  end
  else if OffscreenTexture = nil then
  begin
    Direct3DDevice.BeginScene;
    if not AlternateViewportEnabled then
      DrawTexture(ScreenRenderBuffer.GetTexture, 0, 0, 255, $FFFFFF, nil, False, False)
    else if ScaleViewportToWindow then
      DrawTextureSized(
          ScreenRenderBuffer.GetTexture,
          0,
          0,
          PresentationWidth,
          PresentationHeight,
          255,
          $FFFFFF,
          nil,
          False,
          False
      )
    else
      DrawTexture(
          ScreenRenderBuffer.GetTexture,
          ViewportOffset.X,
          ViewportOffset.Y,
          255,
          $FFFFFF,
          nil,
          False,
          False
      );
    Direct3DDevice.EndScene;
    Direct3DDevice.Present(nil, nil, 0, nil);
  end;
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
      if GameTickCount - OffscreenLastPresentationTick < 100 then
        Exit;
    OffscreenLastPresentationTick := GameTickCount;
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
  if GameTickCount - LastRecordingFrameTick >= Cardinal(RecordingFrameInterval) then
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
    LastRecordingFrameTick := GameTickCount;
  end;
end;

procedure FlushRecordingFrames;
var

  FirstFrameNumber, Index: Integer;
  Directory: AnsiString;
  Frame: TGraphBufGR;
  FileName: AnsiString;
  FindData: TSearchRec;
begin
  if RecordingFrameCount >= 1 then
  begin
    Directory := GetCurrentDir;
    SetCurrentDir(NativeGamePath('Film'));
    FirstFrameNumber := -1;
    if SysUtils.FindFirst('*', faAnyFile, FindData) = 0 then
    begin
      repeat
        if (FindData.Attr and faDirectory) <> faDirectory then
          FirstFrameNumber :=
              Max(FirstFrameNumber, ExtractDigitsToIntW(WideString(AnsiString(FindData.Name))));
      until SysUtils.FindNext(FindData) <> 0;
      SysUtils.FindClose(FindData);
    end;
    SetCurrentDir(NativeGamePath(Directory));
    Inc(FirstFrameNumber);
    Frame := TGraphBufGR.Create(False);
    Frame.AllocateNativePitch(
        ScreenRenderBuffer.Width,
        ScreenRenderBuffer.Height,
        ScreenRenderBuffer.Width * 3
    );
    for Index := 0 to RecordingFrameCount - 1 do
    begin
      Ex_OKGF_Convert565toBGR(
          RecordingFrameBuffers[Index],
          GameScreenWidth * 2,
          Frame.GetPixels,
          Frame.PitchBytes,
          Frame.Width,
          Frame.Height
      );
      FileName :=
          AnsiString('Film\' + IntToFixedWidthWideString(FirstFrameNumber + Index, 6) + '.bmp');
      WriteBmpFile(
          FileName,
          Frame.GetPixels,
          Frame.PitchBytes,
          24,
          $FF,
          $FF00,
          $FF0000,
          0,
          Frame.Width,
          Frame.Height
      );
    end;
    Frame.Free;
    RecordingFrameCount := 0;
  end;
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
    Clip: TRect
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
    Clip: TRect
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
      Offset := PByte(PAnsiChar(Source) + X)^ shl 2;
      PColorBGRA(PAnsiChar(Dest) + X * SizeOf(TColorBGRA)).B :=
          PByte(@PColorRGBA(PAnsiChar(Palette) + Offset).B)^;
      PByte(@PColorBGRA(PAnsiChar(Dest) + X * SizeOf(TColorBGRA)).G)^ :=
          PByte(@PColorRGBA(PAnsiChar(Palette) + Offset).G)^;
      PByte(@PColorBGRA(PAnsiChar(Dest) + X * SizeOf(TColorBGRA)).R)^ :=
          PColorRGBA(PAnsiChar(Palette) + Offset).R;
      PByte(@PColorBGRA(PAnsiChar(Dest) + X * SizeOf(TColorBGRA)).A)^ :=
          PByte(@PColorRGBA(PAnsiChar(Palette) + Offset).A)^;
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
  SourcePixels: PByte;
  DestPixel: PByte;
  Width: Integer;
  Palette, MulTable: Pointer;
  Column, Row, SourceSkip, DestSkip, Height: Integer;
  SourceX, SourceY: Integer;
  RedShift, GreenShift, GreenMask: Integer;
  Color, Pixel, Blended: Cardinal;
  Foreground, Background: PByte;

  function ScaleRgb(Red, Green, Blue: Byte; TableRow: PByte): Cardinal;
  begin
    Result :=
        ((Cardinal(TableRow[Red]) and $F8) shl RedShift)
            or ((Cardinal(TableRow[Green]) and GreenMask) shl GreenShift)
            or (Cardinal(TableRow[Blue]) shr 3);
  end;

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
  SourcePixels := PByte(PAnsiChar(Source.Pixels) + SourceY * Source.PitchBytes + SourceX);
  Dest := Pointer(PAnsiChar(Dest) + Y * DestPitch + X * 2);
  SourceSkip := Source.PitchBytes - Width;
  DestSkip := DestPitch - Width * 2;
  MulTable := Ex_OKGF_MulTable256x256;
  Palette := Source.Palette;
  if CurrentPixelFormat.TotalChannelBits = 16 then
  begin
    RedShift := 8;
    GreenShift := 3;
    GreenMask := $FC;
  end
  else
  begin
    RedShift := 7;
    GreenShift := 2;
    GreenMask := $F8;
  end;
  DestPixel := Dest;
  for Row := 1 to Height do
  begin
    for Column := 1 to Width do
    begin
      Color := ReadDWordEC(PAnsiChar(Palette) + Integer(SourcePixels^) * SizeOf(Cardinal));
      if Color shr 24 <> 0 then
      begin
        Foreground := PByte(PAnsiChar(MulTable) + Integer(Color shr 24) * 256);
        Background := PByte(PAnsiChar(MulTable) + (255 - Integer(Color shr 24)) * 256);
        Pixel := ReadWordEC(DestPixel);
        // Quantize each contribution before adding, as in the RGB565/RGB555 loops.
        // Combining full-precision channels first changes the low color bits.
        Blended := ScaleRgb(Byte(Color), Byte(Color shr 8), Byte(Color shr 16), Foreground);
        Inc(
            Blended,
            ScaleRgb(
                (Pixel shr RedShift) and $F8,
                (Pixel shr GreenShift) and GreenMask,
                (Pixel shl 3) and $F8,
                Background
            )
        );
        WriteWordEC(DestPixel, Word(Blended));
      end;
      Inc(SourcePixels);
      Inc(DestPixel, SizeOf(Word));
    end;
    Inc(SourcePixels, SourceSkip);
    Inc(DestPixel, DestSkip);
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
  Result := GameKeyState(Key) and $8000 = $8000;
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
    SessionLogLock := SyncObjs.TCriticalSection.Create;
  SessionLogLock.Enter;
  Append(SessionLog);
  Writeln(SessionLog, Text);
  CloseFile(SessionLog);
  SessionLogLock.Leave;
end;

procedure AppendLogTextThreadSafe(const Text: AnsiString);
begin
  if SessionLogLock = nil then
    SessionLogLock := SyncObjs.TCriticalSection.Create;
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
    SessionLogLock := SyncObjs.TCriticalSection.Create;
  SessionLogLock.Enter;
  AssignFile(Log, '#####add.log');
  if not FileExists('#####add.log') then
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
  if FileExists('#####add.log') then
  begin
    if SessionLogLock = nil then
      SessionLogLock := SyncObjs.TCriticalSection.Create;
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
    SessionLogLock := SyncObjs.TCriticalSection.Create;
  SessionLogLock.Enter;
  AssignFile(F, NativeGamePath(FileName));
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
  GetGameMouse(Point);

  PostGameMessage(WM_MOUSEMOVE, 0, Word(Point.X) or (Word(Point.Y) shl 16));
end;

function MeasureCpuClockMHz: Double;
begin
  Result := GameCpuClockMHz;
end;

{$IFDEF MSWINDOWS}
function ReadRegistryText(Root: PtrUInt; KeyPath, ValueName, DefaultValue: WideString): WideString;
var
  Key: HKey;
  ValueType: Cardinal;
  Data: Pointer;
  ByteCount: Cardinal;
begin
  if RegOpenKeyExA(Root, PAnsiChar(AnsiString(KeyPath)), 0, KEY_READ, Key) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    Exit;
  end;

  ByteCount := 2048;
  Data := AllocEC(ByteCount);
  if RegQueryValueExA(Key, PAnsiChar(AnsiString(ValueName)), nil, @ValueType, Data, @ByteCount)
      <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    RegCloseKey(Key);
    FreeEC(Data);
    Exit;
  end;

  if ValueType <> REG_SZ then
    Result := DefaultValue
  else
    Result := PAnsiChar(Data);
  FreeEC(Data);
  RegCloseKey(Key);
end;

function ReadRegistryInteger(
    Root: PtrUInt;
    KeyPath, ValueName: WideString;
    DefaultValue: Integer
): Integer;
var
  Key: HKey;
  ValueType: Cardinal;
  Value: Integer;
  ByteCount: Cardinal;
begin
  if RegOpenKeyExA(Root, PAnsiChar(AnsiString(KeyPath)), 0, KEY_READ, Key) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    Exit;
  end;

  ByteCount := 4;
  if RegQueryValueExA(Key, PAnsiChar(AnsiString(ValueName)), nil, @ValueType, @Value, @ByteCount)
      <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    RegCloseKey(Key);
    Exit;
  end;

  if ValueType <> REG_DWORD then
    Result := DefaultValue
  else
    Result := Value;
  RegCloseKey(Key);
end;

{$ENDIF}

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
  if CachedGameUserDirectory <> '' then
    Exit(CachedGameUserDirectory);
  if OverrideGameUserDirectory <> '' then
    CachedGameUserDirectory :=
        IncludeTrailingPathDelimiter(NativeGamePath(OverrideGameUserDirectory))
  else
    CachedGameUserDirectory := GameUserDirectory;
  ForceDirectories(NativeGamePath(CachedGameUserDirectory));
  Result := CachedGameUserDirectory;
end;

function ComputeMachineFingerprintCRC: Cardinal;
var
  Buffer: TBufEC;
  ProcessorName: AnsiString;
  Serial, Flags: Cardinal;
begin
{$IFDEF MSWINDOWS}
  Serial := 0;
  GetVolumeInformationA('c:\', nil, 0, @Serial, Flags, Flags, nil, 0);
  ProcessorName :=
      AnsiString(
          ReadRegistryText(
              HKEY_LOCAL_MACHINE,
              'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
              'ProcessorNameString',
              ''
          )
      );
{$ELSE}
  // The fingerprint is an integrity seed, not a hardware identifier on Unix.
  Serial := 0;
  ProcessorName := {$I %FPCTARGETCPU%} +':' + GetEnvironmentVariable('HOSTNAME');
{$ENDIF}
  Buffer := TBufEC.Create;
  Buffer.AddInt32(Serial);
  if Length(ProcessorName) > 0 then
    Buffer.AddBytes(Pointer(ProcessorName), Length(ProcessorName));
  Result := Buffer.ComputeCrc32;
  Buffer.Clear;
  Buffer.Free;
end;

function GetClipboardWideText: WideString;
begin
  Result := GetGameClipboard;
end;

procedure SetClipboardWideText(Text: WideString);
begin
  SetGameClipboard(Text);
end;

procedure LogPresentationParameters;
var
  CurrentValue, PreviousValue: Cardinal;
  Text: WideString;

  procedure LogPresentationField(Name: WideString);
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

end.
