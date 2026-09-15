{$EXCESSPRECISION OFF}
unit EC_OKGF;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GR_GraphBuf,
  Types;
type
  PointerToTOkgfReadContext = ^TOkgfReadContext;
  {$Z4}
  TOkgfImageKind = (
      oikUnknown = 0,
      oikBmp = 1,
      oikIndexedBmp = 2,
      oikJpeg = 3,
      oikPng = 4,
      oikIndexedPsd = 5,
      oikGrayscalePsd = 6,
      oikRgbPsd = 7,
      oikCmykPsd = 8
  );
  TOkgfReadContext = record
    CodecContext: Pointer;
    ImageKind: TOkgfImageKind;
    Width: Integer;
    Height: Integer;
    PaletteCount: Integer;
    SourceData: Pointer;
    SourceSize: Integer;
    OwnsSource: Integer;
  end;
  POkgfReadContext = PointerToTOkgfReadContext;

procedure OKGR_PixelAlpha_16(
    Pixel: Pointer;
    Color: Word;
    Alpha: Byte
); cdecl; external 'okgf' name 'OKGR_PixelAlpha_16';
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
); cdecl; external 'okgf' name 'OKGF_Triangle_16';
procedure OKGF_LineIp_16(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    Color1: Cardinal;
    X2: Integer;
    Y2: Integer;
    Color2: Cardinal
); cdecl; external 'okgf' name 'OKGF_LineIp_16';
function OKGF_ReadStart_Buf(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer
): POkgfReadContext; cdecl; external 'okgf' name 'OKGF_ReadStart_Buf';
function OKGF_Read(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    BytesPerPixel: Integer
): Integer; cdecl; external 'okgf' name 'OKGF_Read';
function OKGF_ReadStartPal_Buf(
    Source: Pointer;
    SourceSize: Integer;
    out Width: Integer;
    out Height: Integer;
    out PaletteCount: Integer;
    out BytesPerPixel: Integer
): POkgfReadContext; cdecl; external 'okgf' name 'OKGF_ReadStartPal_Buf';
function OKGF_ReadPal(
    Context: POkgfReadContext;
    Pixels: Pointer;
    PitchBytes: Integer;
    Palette: PColorRGBA
): Integer; cdecl; external 'okgf' name 'OKGF_ReadPal';
function OKGF_Write_PNG_File(
    FileName: PAnsiChar;
    Pixels: Pointer;
    PitchBytes: Integer;
    Width: Integer;
    Height: Integer;
    HasAlpha: Integer;
    SwapRedBlue: Integer
): Integer; cdecl; external 'okgf' name 'OKGF_Write_PNG_File';
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
): Integer; cdecl; external 'okgf' name 'OKGF_Write_BMP_File';
function OKGF_MulTable256x256: Pointer; cdecl; external 'okgf' name 'OKGF_MulTable256x256';
procedure OKGR_StretchGdi_WORD(
    Dest: Pointer;
    Width: Cardinal;
    Height: Cardinal;
    Source: Pointer;
    SourceWidth: Cardinal;
    SourceHeight: Cardinal
); cdecl; external 'okgf' name 'OKGR_StretchGdi_WORD';
procedure OKGR_Fill_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Color: Word
); cdecl; external 'okgf' name 'OKGR_Fill_WORD';
procedure OKGF_ConvertRGBto565(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGF_ConvertRGBto565';
procedure OKGF_Convert565toRGB(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGF_Convert565toRGB';
procedure OKGR_ShrLight_16(
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Shift: Integer
); cdecl; external 'okgf' name 'OKGR_ShrLight_16';
procedure OKGR_Line_Draw_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word
); cdecl; external 'okgf' name 'OKGR_Line_Draw_WORD';
procedure OKGR_Line_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_Line_DrawClip_WORD';
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
); cdecl; external 'okgf' name 'OKGR_Line_DrawClip_Alpha_16';
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
); cdecl; external 'okgf' name 'OKGR_AnimLine_Draw_16';
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
); cdecl; external 'okgf' name 'OKGR_AnimShadowLine_Draw_16';
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
); cdecl; external 'okgf' name 'OKGR_Alpha64Trapezium_16';
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
); cdecl; external 'okgf' name 'OKGR_Alpha128Trapezium_16';
procedure OKGR_Circle_DrawClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_Circle_DrawClip_WORD';
procedure OKGR_Circle_DrawClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_Circle_DrawClip_BYTE';
procedure OKGR_Circle_DrawFillClip_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Word;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_Circle_DrawFillClip_WORD';
procedure OKGR_Circle_DrawFillClip_BYTE(
    Pixels: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Byte;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_Circle_DrawFillClip_BYTE';
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
); cdecl; external 'okgf' name 'OKGR_FillTrapezium_DWORD';
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
); cdecl; external 'okgf' name 'OKGF_Rescale';
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
); cdecl; external 'okgf' name 'OKGR_HACopy_XY_XY_16';
procedure OKGR_CopySingleBuf_XY_XY_WORD(
    Pixels: Pointer;
    Pitch: Integer;
    DestX: Integer;
    DestY: Integer;
    SourceX: Integer;
    SourceY: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGR_CopySingleBuf_XY_XY_WORD';
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
); cdecl; external 'okgf' name 'OKGR_Copy_XY_XY_WORD';
procedure OKGR_AlphaBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_AlphaBuf_Draw_RGBA';
procedure OKGR_TransAlphaBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_TransAlphaBuf_Draw_RGBA';
procedure OKGR_AlphaIndexed_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_Draw_RGBA';
procedure OKGR_AlphaIndexed_AlphaDraw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_AlphaDraw_RGBA';
procedure OKGR_TransBuf_Draw_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_TransBuf_Draw_RGBA';
procedure OKGR_TransBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_TransBuf_DrawClip_WORD';
procedure OKGR_TransBuf_HADrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_TransBuf_HADrawClip_16';
function OKGR_TransBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external 'okgf' name 'OKGR_TransBuf_BuildFromRGBA_16';
procedure OKGR_TransAlphaBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_TransAlphaBuf_DrawClip_WORD';
procedure OKGR_AlphaBuf_DrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_AlphaBuf_DrawClip_16';
function OKGR_TransAlphaBuf_BuildFromRGBA_16(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external 'okgf' name 'OKGR_TransAlphaBuf_BuildFromRGBA_16';
function OKGR_AlphaBuf_BuildFromRGBA(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer
): Integer; cdecl; external 'okgf' name 'OKGR_AlphaBuf_BuildFromRGBA';
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
); cdecl; external 'okgf' name 'OKGR_AlphaSimpleBuf_Draw_16';
procedure OKGR_AlphaIndexed_CopyDrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_CopyDrawClip_WORD';
procedure OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_CopyDrawClip_Alpha_16';
procedure OKGR_AlphaIndexed_AlphaDrawClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_AlphaDrawClip_16';
procedure OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Alpha: Byte
); cdecl; external 'okgf' name 'OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16';
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
); cdecl; external 'okgf' name 'OKGR_PalCopy_XY_XY_WORD';
procedure OKGF_Convert565toBGR(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGF_Convert565toBGR';
procedure OKGF_Convert565toBGRA(
    Source: Pointer;
    SourcePitch: Integer;
    Dest: Pointer;
    DestPitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGF_Convert565toBGRA';
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
); cdecl; external 'okgf' name 'OKGF_Convert_8888to565';
procedure OKGR_F5_DrawRGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_F5_DrawRGBA';
procedure OKGR_F6_DrawRGBA(
    Dest: Pointer;
    Pitch: Integer;
    Source: Pointer
); cdecl; external 'okgf' name 'OKGR_F6_DrawRGBA';
procedure OKGR_MaskBuf_DrawClip_DWORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Cardinal;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_MaskBuf_DrawClip_DWORD';
procedure OKGR_MaskBuf_DrawClip_WORD(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    Color: Word;
    constref Clip: TRect
); cdecl; external 'okgf' name 'OKGR_MaskBuf_DrawClip_WORD';
procedure OKGR_TransBuf_FillAlphaClip_RGBA(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Cardinal
); cdecl; external 'okgf' name 'OKGR_TransBuf_FillAlphaClip_RGBA';
procedure OKGR_TransBuf_FillAlphaClip_16(
    Dest: Pointer;
    Pitch: Integer;
    X: Integer;
    Y: Integer;
    Source: Pointer;
    constref Clip: TRect;
    Color: Word
); cdecl; external 'okgf' name 'OKGR_TransBuf_FillAlphaClip_16';
function OKGR_TransBuf_Build_WORD(
    Source: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Dest: Pointer;
    TransparentColor: Word
): Integer; cdecl; external 'okgf' name 'OKGR_TransBuf_Build_WORD';
function OKGR_RotateBuf_Build(
    Width: Integer;
    Height: Integer;
    SourceWidth: Integer;
    SourceHeight: Integer;
    CenterX: Integer;
    CenterY: Integer
): Pointer; cdecl; external 'okgf' name 'OKGR_RotateBuf_Build';
procedure OKGR_RotateBuf_Free(Buffer: Pointer); cdecl; external 'okgf' name 'OKGR_RotateBuf_Free';
function OKGR_Planet2_TemplBuild(
    Source: Pointer;
    Pitch: Integer;
    Height: Integer;
    TextureWidth: Integer;
    TextureHeight: Integer;
    var ByteCount: Integer
): Pointer; cdecl; external 'okgf' name 'OKGR_Planet2_TemplBuild';
procedure OKGR_Planet2_TemplDel(
    TemplateData: Pointer
); cdecl; external 'okgf' name 'OKGR_Planet2_TemplDel';
function OKGR_Line_CopyFromBuf_WORD(
    Source: Pointer;
    Dest: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer; cdecl; external 'okgf' name 'OKGR_Line_CopyFromBuf_WORD';
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
); cdecl; external 'okgf' name 'OKGR_CopyTrans_XY_XY_WORD';
function OKGF_DXVersion: Cardinal; cdecl; external 'okgf' name 'DXVersion';
procedure OKGR_RotateBuf_Draw_BYTE(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer;
    Angle: Byte;
    RotationMap: Pointer
); cdecl; external 'okgf' name 'OKGR_RotateBuf_Draw_BYTE';
procedure OKGR_Light_BYTE(
    Pixels: Pointer;
    PixelStride: Integer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
    Alpha: Byte
); cdecl; external 'okgf' name 'OKGR_Light_BYTE';
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
); cdecl; external 'okgf' name 'OKGR_AlphaSimpleBufPalAlpha_Draw_16';
function OKGR_Line_Clip(
    var X1: Integer;
    var Y1: Integer;
    var X2: Integer;
    var Y2: Integer;
    constref Clip: TRect
): Integer; cdecl; external 'okgf' name 'OKGR_Line_Clip';
function OKGR_Line_CopyToBuf_WORD(
    Dest: Pointer;
    Source: Pointer;
    Pitch: Integer;
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer
): Integer; cdecl; external 'okgf' name 'OKGR_Line_CopyToBuf_WORD';
function OKGR_LineColor_Clip(
    var X1: Integer;
    var Y1: Integer;
    var Color1: Cardinal;
    var X2: Integer;
    var Y2: Integer;
    var Color2: Cardinal;
    constref Clip: TRect
): Integer; cdecl; external 'okgf' name 'OKGR_LineColor_Clip';
procedure OKGR_ShrLightMask_16(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    Width: Integer;
    Height: Integer
); cdecl; external 'okgf' name 'OKGR_ShrLightMask_16';
function OKGR_LightBuf_Create(
    Width: Integer;
    Height: Integer
): Pointer; cdecl; external 'okgf' name 'OKGR_LightBuf_Create';
procedure OKGR_LightBuf_Destroy(
    Buffer: Pointer
); cdecl; external 'okgf' name 'OKGR_LightBuf_Destroy';
procedure OKGR_LightBuf_SetSme(
    Buffer: Pointer;
    X: Integer;
    Y: Integer
); cdecl; external 'okgf' name 'OKGR_LightBuf_SetSme';
procedure OKGR_LightBuf_Init(
    Buffer: Pointer;
    Value: Byte
); cdecl; external 'okgf' name 'OKGR_LightBuf_Init';
procedure OKGR_LightBuf_LoadFromPalBuf(
    Buffer: Pointer;
    Source: Pointer;
    Width: Integer;
    Height: Integer;
    Pitch: Integer;
    Palette: PColorRGBA
); cdecl; external 'okgf' name 'OKGR_LightBuf_LoadFromPalBuf';
procedure OKGR_LightBuf_Rotate(
    Dest: Pointer;
    Source: Pointer;
    RotationMap: Pointer;
    Angle: Byte
); cdecl; external 'okgf' name 'OKGR_LightBuf_Rotate';
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
); cdecl; external 'okgf' name 'OKGR_Planet2_DrawAndLight_32';
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
); cdecl; external 'okgf' name 'OKGR_Planet2_DrawAndLightClip_16';
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
); cdecl; external 'okgf' name 'OKGR_Planet3_DrawAndLight_32';
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
); cdecl; external 'okgf' name 'OKGR_Planet3_DrawAndLightClip_16';
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
); cdecl; external 'okgf' name 'OKGR_Planet4_DrawAndLight_32';
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
); cdecl; external 'okgf' name 'OKGR_Planet4_DrawAndLightClip_16';
procedure OKGR_RotateBuf_Draw_DWORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer
); cdecl; external 'okgf' name 'OKGR_RotateBuf_Draw_DWORD';
procedure OKGR_RotateBuf_Size(
    X: Integer;
    Y: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    var Bounds: TRect
); cdecl; external 'okgf' name 'OKGR_RotateBuf_Size';
procedure OKGR_RotateBuf_DrawTransClip_WORD(
    Dest: Pointer;
    DestPitch: Integer;
    Source: Pointer;
    SourcePitch: Integer;
    CenterX: Integer;
    CenterY: Integer;
    Angle: Byte;
    RotationMap: Pointer;
    const Clip: TRect
); cdecl; external 'okgf' name 'OKGR_RotateBuf_DrawTransClip_WORD';

implementation
uses
  Math,
  RangersSupport,
  SysUtils,
  Windows;
end.
