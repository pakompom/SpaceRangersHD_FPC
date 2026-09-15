{$EXCESSPRECISION OFF}
unit GR_GraphBuf;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  Direct3D9,
  Types;
type
  TGraphBufGR = class;
  TPixelFormatGR = class;
  PointerToTColorBGRA = ^TColorBGRA;
  PointerToTColorRGBA = ^TColorRGBA;
  PointerToTColorRGBAArray = ^TColorRGBAArray;
  PointerToTPixelWordsGR = ^TPixelWordsGR;
  TPixelFormatGR = class(TObject)
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    RedShift: Cardinal;
    GreenShift: Cardinal;
    BlueShift: Cardinal;
    AlphaShift: Cardinal;
    RedLevels: Cardinal;
    GreenLevels: Cardinal;
    BlueLevels: Cardinal;
    AlphaLevels: Cardinal;
    RedBits: Cardinal;
    GreenBits: Cardinal;
    BlueBits: Cardinal;
    AlphaBits: Cardinal;
    BytesPerPixel: Integer;
    TotalChannelBits: Cardinal;
    procedure RebuildChannelMetrics;
    function PackRgbBytes(Red: Byte; Green: Byte; Blue: Byte): Cardinal;
    function PackRgb(Red: Integer; Green: Integer; Blue: Integer): Cardinal;
    function PackNormalizedRgb(Red: Double; Green: Double; Blue: Double): Cardinal;
    function InterpolateRgb(First: Cardinal; Second: Cardinal; Amount: Single): Cardinal;
    function UnpackRed(Color: Cardinal): Byte;
    function UnpackGreen(Color: Cardinal): Byte;
    function UnpackBlue(Color: Cardinal): Byte;
  end;
  TColorRGBA = packed record
    R: Byte;
    G: Byte;
    B: Byte;
    A: Byte;
  end;
  PColorRGBA = PointerToTColorRGBA;
  TColorRGBAArray = array[0..0] of TColorRGBA;
  PColorRGBAArray = PointerToTColorRGBAArray;
  TColorBGRA = packed record
    B: Byte;
    G: Byte;
    R: Byte;
    A: Byte;
  end;
  PColorBGRA = PointerToTColorBGRA;
  TPixelWordsGR = array[0..0] of Word;
  PPixelWordsGR = PointerToTPixelWordsGR;
  TGraphBufGR = class(TObjectEx)
    Width: Integer;
    Height: Integer;
    PitchBytes: Integer;
    Pixels: Pointer;
    StorageKind: Integer;
    BitsPerPixel: Integer;
    BytesPerPixel: Integer;
    UseTexture: Boolean;
    UsesTextureStorage: Boolean;
    TextureFlag22: Boolean;
    Gap23: array[0..0] of Byte;
    Texture: IDirect3DTexture9;
    TextureLocked: Boolean;
    TextureLockedReadOnly: Boolean;
    Gap2A: array[0..1] of Byte;
    constructor Create(AUseTexture: Boolean);
    destructor Destroy; override;
    procedure Clear;
    function GetPixels: Pointer;
    procedure AllocateNative(Width: Integer; Height: Integer);
    procedure AllocateNativePitch(Width: Integer; Height: Integer; PitchBytes: Integer);
    procedure AttachPixels(Width: Integer; Height: Integer; PitchBytes: Integer; Data: Pointer);
    procedure AllocateRgbaTight(Width: Integer; Height: Integer);
    procedure AllocateRgba(Width: Integer; Height: Integer; PitchBytes: Integer);
    procedure AllocateRgbTight(Width: Integer; Height: Integer);
    procedure AllocateRgb(Width: Integer; Height: Integer; PitchBytes: Integer);
    procedure AllocateGrayscale(Width: Integer; Height: Integer);
    procedure LoadImage(Buffer: TBufEC);
    procedure LoadImageRgba(Buffer: TBufEC);
    procedure LoadImageRgb(Buffer: TBufEC);
    procedure LoadImageGrayscale(Buffer: TBufEC);
    function GetPixel16(X: Integer; Y: Integer): Cardinal;
    procedure SetPixel16(X: Integer; Y: Integer; Color: Cardinal);
    function GetBrightness16(X: Integer; Y: Integer): Cardinal;
    procedure BlendPixel16(X: Integer; Y: Integer; Color: Cardinal; Alpha: Byte);
    procedure DrawAlphaLine16(
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer;
        Color: Word;
        Alpha: Byte;
        Clip: TRect
    );
    function GetPixel32(X: Integer; Y: Integer): Cardinal;
    procedure DrawHorizontalLine16(X: Integer; Y: Integer; Count: Integer; Color: Cardinal);
    procedure DrawVerticalLine16(X: Integer; Y: Integer; Count: Integer; Color: Cardinal);
    procedure DrawHorizontalLine16Clipped(
        X: Integer;
        Y: Integer;
        Count: Integer;
        Color: Cardinal;
        Clip: TRect
    );
    procedure DrawVerticalLine16Clipped(
        X: Integer;
        Y: Integer;
        Count: Integer;
        Color: Cardinal;
        Clip: TRect
    );
    procedure DrawLine16(First: TPoint; Last: TPoint; Color: Cardinal);
    procedure DrawAnimatedLine16(
        First: TPoint;
        Last: TPoint;
        Color: Cardinal;
        Phase: Integer;
        Clip: TRect
    );
    procedure DrawShadowLine16(
        First: TPoint;
        Last: TPoint;
        Color: Cardinal;
        Phase: Integer;
        Clip: TRect;
        ShadowPixels: Pointer;
        ShadowPitch: Integer
    );
    procedure DrawAlphaTrapezium16(
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer;
        X3: Integer;
        X4: Integer;
        Color: Word;
        Alpha: Byte;
        constref Clip: TRect
    );
    procedure DrawLine16Clipped(First: TPoint; Last: TPoint; Color: Cardinal; Clip: TRect);
    procedure DrawAntialiasedLine(FirstPoint: TPoint; SecondPoint: TPoint; Color: Cardinal);
    procedure ClearPixels;
    procedure FillPixels(Value: Byte);
    procedure FillPixels16(Color: Word);
    procedure FillRect32(Rect: TRect; Color: Cardinal);
    procedure ScaleAlpha(Rect: TRect; Alpha: Byte);
    procedure FlipHorizontal16;
    procedure RotateLeft16;
    procedure Stretch16(Width: Cardinal; Height: Cardinal);
    procedure ConvertRgbTo565;
    procedure Convert565ToRgb;
    procedure ShiftLight16(Shift: Integer; Rect: TRect);
    procedure DrawCircle16(
        Center: TPoint;
        Radius: Integer;
        OutlineColor: Cardinal;
        FillColor: Cardinal;
        Clip: TRect
    );
    procedure DrawCircle8(
        Center: TPoint;
        Radius: Integer;
        OutlineColor: Cardinal;
        FillColor: Cardinal;
        Clip: TRect
    );
    procedure ApplyOperations(const Operations: WideString);
    procedure RescaleRgb(Width: Integer; Height: Integer);
    procedure RescaleRgba(Width: Integer; Height: Integer; Filter: Integer);
    procedure RescaleBilinearRgba(Width: Integer; Height: Integer);
    procedure FillPolygon32(Points: array of TPoint; Color: Cardinal);
    function GetPixelCentroid: TPoint;
    procedure CopyRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect);
    procedure BlendRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect);
    procedure MakeShadow;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SavePng(FileName: WideString);
    procedure SaveBmp(FileName: WideString);
    procedure SaveJpeg(FileName: WideString; Quality: Integer);
    procedure DrawNinePatch(
        X: Integer;
        Y: Integer;
        Width: Integer;
        Height: Integer;
        Source: TGraphBufGR;
        SourceRect: TRect;
        Borders: TRect
    );
    procedure RescaleWithAspect(
        Width: Cardinal;
        Height: Cardinal;
        CropToAspect: Boolean;
        HorizontalAlign: Integer;
        VerticalAlign: Integer;
        Filter: Integer
    );
    procedure RescaleRGBA_HW(
        Width: Cardinal;
        Height: Cardinal;
        CropToAspect: Boolean;
        HorizontalAlign: Integer;
        VerticalAlign: Integer
    );
    procedure Crop(Rect: TRect);
    procedure AdjustBrightness(Percent: Integer);
    procedure ConvertToGrayscale;
    function GetTexture: IDirect3DTexture9;
    procedure LoadFromScreen(UnusedOption: Byte);
    procedure LockTexture(ReadOnly: Boolean);
    procedure UnlockTexture;
    procedure ConvertBgraToRgb24;
    procedure DrawAntialiasedCircle16(
        Center: TPoint;
        Radius: Integer;
        Color: Cardinal;
        Clip: TRect
    );
    procedure DrawAntialiasedLine16(
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer;
        Color: Cardinal;
        Alpha: Integer;
        Clip: TRect
    );
  end;
implementation
uses
  GameNative,
  EC_OKGF,
  EC_Mem,
  GR_DX,
  GR_Main,
  EC_Str,
  GlobalsV,
  Math,
  SysUtils,
  Classes,
  Windows;

procedure TPixelFormatGR.RebuildChannelMetrics;
var
  Mask: Cardinal;
begin
  RedShift := 0;
  RedBits := 0;
  RedLevels := 0;
  GreenShift := 0;
  GreenBits := 0;
  GreenLevels := 0;
  BlueShift := 0;
  BlueBits := 0;
  BlueLevels := 0;
  AlphaShift := 0;
  AlphaBits := 0;
  AlphaLevels := 0;
  if RedMask <> 0 then
  begin
    Mask := RedMask;
    while Mask and 1 = 0 do
    begin
      Inc(RedShift);
      Mask := Mask shr 1;
    end;
    while Mask and 1 <> 0 do
    begin
      Inc(RedBits);
      Mask := Mask shr 1;
    end;
    RedLevels := 1 shl RedBits;
  end;
  if GreenMask <> 0 then
  begin
    Mask := GreenMask;
    while Mask and 1 = 0 do
    begin
      Inc(GreenShift);
      Mask := Mask shr 1;
    end;
    while Mask and 1 <> 0 do
    begin
      Inc(GreenBits);
      Mask := Mask shr 1;
    end;
    GreenLevels := 1 shl GreenBits;
  end;
  if BlueMask <> 0 then
  begin
    Mask := BlueMask;
    while Mask and 1 = 0 do
    begin
      Inc(BlueShift);
      Mask := Mask shr 1;
    end;
    while Mask and 1 <> 0 do
    begin
      Inc(BlueBits);
      Mask := Mask shr 1;
    end;
    BlueLevels := 1 shl BlueBits;
  end;
  if AlphaMask <> 0 then
  begin
    Mask := AlphaMask;
    while Mask and 1 = 0 do
    begin
      Inc(AlphaShift);
      Mask := Mask shr 1;
    end;
    while Mask and 1 <> 0 do
    begin
      Inc(AlphaBits);
      Mask := Mask shr 1;
    end;
    AlphaLevels := 1 shl AlphaBits;
  end;
  TotalChannelBits := RedBits + GreenBits + BlueBits + AlphaBits;
end;

function TPixelFormatGR.PackRgbBytes(Red, Green, Blue: Byte): Cardinal;
begin
  Result := PackNormalizedRgb(Red / 255, Green / 255, Blue / 255);
end;

function TPixelFormatGR.PackRgb(Red, Green, Blue: Integer): Cardinal;
begin
  Result := PackNormalizedRgb(Red / 255, Green / 255, Blue / 255);
end;

function TPixelFormatGR.PackNormalizedRgb(Red, Green, Blue: Double): Cardinal;
begin
  Result :=
      (Cardinal(Trunc(Red * (RedLevels - 1))) shl RedShift)
          or (Cardinal(Trunc(Green * (GreenLevels - 1))) shl GreenShift)
          or (Cardinal(Trunc(Blue * (BlueLevels - 1))) shl BlueShift);
end;

function TPixelFormatGR.InterpolateRgb(First, Second: Cardinal; Amount: Single): Cardinal;
var
  R1, G1, B1, R2, G2, B2: Integer;
begin
  R1 := (First shr RedShift) mod RedLevels;
  G1 := (First shr GreenShift) mod GreenLevels;
  B1 := (First shr BlueShift) mod BlueLevels;
  R2 := (Second shr RedShift) mod RedLevels;
  G2 := (Second shr GreenShift) mod GreenLevels;
  B2 := (Second shr BlueShift) mod BlueLevels;
  Result :=
      (Cardinal(Trunc(R1 + (R2 - R1) * Amount)) shl RedShift)
          or (Cardinal(Trunc(G1 + (G2 - G1) * Amount)) shl GreenShift)
          or (Cardinal(Trunc(B1 + (B2 - B1) * Amount)) shl BlueShift);
end;

function TPixelFormatGR.UnpackRed(Color: Cardinal): Byte;
begin
  if TotalChannelBits = 16 then
    Result := Color shr 8
  else
    Result := Color shr 7;
end;

function TPixelFormatGR.UnpackGreen(Color: Cardinal): Byte;
begin
  if TotalChannelBits = 16 then
    Result := Color shr 3
  else
    Result := Color shr 2;
end;

function TPixelFormatGR.UnpackBlue(Color: Cardinal): Byte;
begin
  Result := Byte(Color) shl 3;
end;

constructor TGraphBufGR.Create(AUseTexture: Boolean);
begin
  inherited Create;
  Width := 0;
  Height := 0;
  PitchBytes := 0;
  StorageKind := 0;
  BitsPerPixel := 0;
  BytesPerPixel := 0;
  UseTexture := AUseTexture and HardwareRenderingEnabled;
  UsesTextureStorage := False;
  TextureFlag22 := False;
  Texture := nil;
  TextureLocked := False;
  TextureLockedReadOnly := False;
end;

destructor TGraphBufGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TGraphBufGR.Clear;
begin
  UnlockTexture;
  if StorageKind = 0 then
  begin
    if not UsesTextureStorage and (Pixels <> nil) then
      FreeEC(Pixels);
    Pixels := nil;
  end;
  Texture := nil;
  UsesTextureStorage := False;
  TextureFlag22 := False;
  Width := 0;
  Height := 0;
  PitchBytes := 0;
  StorageKind := 0;
  BitsPerPixel := 0;
  BytesPerPixel := 0;
end;

function TGraphBufGR.GetPixels: Pointer;
begin
  LockTexture(False);
  Result := Pixels;
end;

procedure TGraphBufGR.AllocateNative(Width, Height: Integer);
var
  Locked: TD3DLockedRect;
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 16;
  BytesPerPixel := SizeOf(Word);
  if UseTexture then
  begin
    Texture := GR_CreateTexture(Width, Height, D3DFMT_R5G6B5, D3DPOOL_MANAGED);
    if Texture <> nil then
    begin
      Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY);
      Self.PitchBytes := Locked.Pitch;
      Texture.UnlockRect(0);
      UsesTextureStorage := True;
    end;
  end
  else
  begin
    Self.PitchBytes := CurrentPixelFormat.BytesPerPixel * Width;
    if Self.PitchBytes and 3 <> 0 then
      Self.PitchBytes := Self.PitchBytes + 4 - (Self.PitchBytes and 3);
    Pixels := AllocEC(Self.PitchBytes * Self.Height);
    if (Self.PitchBytes and 3 <> 0) or (PtrUInt(Pixels) and 3 <> 0) then
      raise Exception.Create('TGraphBufGR.CreateN');
  end;
end;

procedure TGraphBufGR.AllocateNativePitch(Width, Height, PitchBytes: Integer);
var
  Locked: TD3DLockedRect;
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 16;
  BytesPerPixel := SizeOf(Word);
  if UseTexture then
  begin
    Texture := GR_CreateTexture(Width, Height, D3DFMT_R5G6B5, D3DPOOL_MANAGED);
    if Texture <> nil then
    begin
      Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY);
      Self.PitchBytes := Locked.Pitch;
      Texture.UnlockRect(0);
      UsesTextureStorage := True;
    end;
  end
  else
  begin
    Self.PitchBytes := PitchBytes;
    Pixels := AllocEC(Self.PitchBytes * Self.Height);
  end;
end;

procedure TGraphBufGR.AttachPixels(Width, Height, PitchBytes: Integer; Data: Pointer);
begin
  Clear;
  Pixels := Data;
  Self.Width := Width;
  Self.Height := Height;
  Self.PitchBytes := PitchBytes;
  StorageKind := 1;
  BytesPerPixel := Cardinal(Self.PitchBytes) div Cardinal(Self.Width);
  BitsPerPixel := BytesPerPixel * 8;
end;

procedure TGraphBufGR.AllocateRgbaTight(Width, Height: Integer);
var
  Locked: TD3DLockedRect;
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 32;
  BytesPerPixel := SizeOf(TColorRGBA);
  if UseTexture then
  begin
    Texture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    if Texture <> nil then
    begin
      Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY);
      Self.PitchBytes := Locked.Pitch;
      Texture.UnlockRect(0);
      UsesTextureStorage := True;
    end;
  end
  else
  begin
    Self.PitchBytes := Width * SizeOf(TColorRGBA);
    Pixels := AllocEC(Self.PitchBytes * Self.Height);
  end;
end;

procedure TGraphBufGR.AllocateRgba(Width, Height, PitchBytes: Integer);
var
  Locked: TD3DLockedRect;
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 32;
  BytesPerPixel := SizeOf(TColorRGBA);
  if UseTexture then
  begin
    Texture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    if Texture <> nil then
    begin
      Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY);
      Self.PitchBytes := Locked.Pitch;
      Texture.UnlockRect(0);
      UsesTextureStorage := True;
    end;
  end
  else
  begin
    Self.PitchBytes := PitchBytes;
    Pixels := AllocEC(Self.PitchBytes * Self.Height);
  end;
end;

procedure TGraphBufGR.AllocateRgbTight(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 24;
  BytesPerPixel := 3;
  Self.PitchBytes := Width * 3;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;

procedure TGraphBufGR.AllocateRgb(Width, Height, PitchBytes: Integer);
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 24;
  BytesPerPixel := 3;
  Self.PitchBytes := PitchBytes;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;

procedure TGraphBufGR.AllocateGrayscale(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width;
  Self.Height := Height;
  BitsPerPixel := 8;
  BytesPerPixel := 1;
  Self.PitchBytes := Width;
  if Self.PitchBytes and 3 <> 0 then
    Self.PitchBytes := Self.PitchBytes + 4 - (Self.PitchBytes and 3);
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
  if (Self.PitchBytes and 3 <> 0) or (PtrUInt(Pixels) and 3 <> 0) then
    raise Exception.Create('TGraphBufGR.CreateBYTE');
end;

procedure TGraphBufGR.LoadImage(Buffer: TBufEC);
var
  Context: POkgfReadContext;
begin
  Clear;
  Context := BeginImageRead(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then
    raise Exception.Create(
        'TGraphBufGR.LoadFromBuf. Error load file 1 (buf size='
            + IntToWideString(Buffer.DataSize)
            + ')');
  AllocateNative(Width, Height);
  Context :=
      Pointer(
          ReadImagePixels(
              Context,
              GetPixels,
              PitchBytes,
              CurrentPixelFormat.RedMask,
              CurrentPixelFormat.GreenMask,
              CurrentPixelFormat.BlueMask,
              CurrentPixelFormat.AlphaMask,
              CurrentPixelFormat.BytesPerPixel
          )
      );
  if Context = nil then
    raise Exception.Create(
        'TGraphBufGR.LoadFromBuf. Error load file 2 (buf size='
            + IntToWideString(Buffer.DataSize)
            + ')');
end;

procedure TGraphBufGR.LoadImageRgba(Buffer: TBufEC);
var
  Context: POkgfReadContext;
begin
  Clear;
  Context := BeginImageRead(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufRGBA. Error load file');
  AllocateRgbaTight(Width, Height);
  Context :=
      Pointer(ReadImagePixels(Context, GetPixels, PitchBytes, $FF0000, $FF00, $FF, $FF000000, 4));
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufRGBA. Error load file');
end;

procedure TGraphBufGR.LoadImageRgb(Buffer: TBufEC);
var
  Context: POkgfReadContext;
begin
  Clear;
  Context := BeginImageRead(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufRGB. Error load file');
  AllocateRgbTight(Width, Height);
  Context := Pointer(ReadImagePixels(Context, GetPixels, PitchBytes, $FF, $FF00, $FF0000, 0, 3));
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufRGB. Error load file');
end;

procedure TGraphBufGR.LoadImageGrayscale(Buffer: TBufEC);
var
  Context: POkgfReadContext;
begin
  Clear;
  Context := BeginImageRead(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufGrayscale. Error load file');
  AllocateGrayscale(Width, Height);
  Context := Pointer(ReadImagePixels(Context, GetPixels, PitchBytes, $FF, 0, 0, 0, 1));
  if Context = nil then
    raise Exception.Create('TGraphBufGR.LoadFromBufGrayscale. Error load file');
end;

function TGraphBufGR.GetPixel16(X, Y: Integer): Cardinal;
var
  Data: PByteArray;
  Pixel: PWord;
begin
  LockTexture(True);
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Result := Pixel^;
end;

procedure TGraphBufGR.SetPixel16(X, Y: Integer; Color: Cardinal);
var
  Data: PByteArray;
  Pixel: PWord;
begin
  LockTexture(False);
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Pixel^ := Color;
end;

function TGraphBufGR.GetBrightness16(X, Y: Integer): Cardinal;
var
  Color: Cardinal;
  Data: PByteArray;
  Pixel: PWord;
begin
  LockTexture(True);
  Result := 0;
  if (X < 0) or (Y < 0) or (Width - 1 < X) or (Height - 1 < Y) then
    Exit;
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Color := Pixel^;
  if CurrentPixelFormat.TotalChannelBits = 16 then
    Result := (Color and 31) + ((Color shr 6) and 31) + ((Color shr 11) and 31)
  else
    Result := (Color and 31) + ((Color shr 5) and 31) + ((Color shr 10) and 31);
end;

procedure TGraphBufGR.BlendPixel16(X, Y: Integer; Color: Cardinal; Alpha: Byte);
begin
  LockTexture(False);
  GR_Main.BlendPixel16(AddPointerOffset(Pixels, Y * PitchBytes + X * SizeOf(Word)), Color, Alpha);
end;

procedure TGraphBufGR.DrawAlphaLine16(
    X1, Y1, X2, Y2: Integer;
    Color: Word;
    Alpha: Byte;
    Clip: TRect
);
begin
  LockTexture(False);
  Ex_OKGR_Line_DrawClip_Alpha_16(Pixels, PitchBytes, X1, Y1, X2, Y2, Color, Alpha, Clip);
end;

function TGraphBufGR.GetPixel32(X, Y: Integer): Cardinal;
begin
  LockTexture(True);
  Result := ReadDWordEC(AddPointerOffset(Pixels, Y * PitchBytes + X * SizeOf(TColorRGBA)));
end;

procedure TGraphBufGR.DrawHorizontalLine16(X, Y, Count: Integer; Color: Cardinal);
var
  P: PByte;
  I: Integer;
begin
  if Count = 0 then
    Exit;
  if Count < 0 then
  begin
    X := X + Count + 1;
    Count := -Count
  end;
  LockTexture(False);
  P := PByte(Pixels) + Y * PitchBytes + X * 2;
  for I := 1 to Count do
  begin
    PWord(P)^ := Word(Color);
    Inc(P, 2)
  end;
end;

procedure TGraphBufGR.DrawVerticalLine16(X, Y, Count: Integer; Color: Cardinal);
var
  P: PByte;
  I: Integer;
begin
  if Count = 0 then
    Exit;
  if Count < 0 then
  begin
    Y := Y + Count + 1;
    Count := -Count
  end;
  LockTexture(False);
  P := PByte(Pixels) + Y * PitchBytes + X * 2;
  for I := 1 to Count do
  begin
    PWord(P)^ := Word(Color);
    Inc(P, PitchBytes)
  end;
end;

procedure TGraphBufGR.DrawHorizontalLine16Clipped(
    X, Y, Count: Integer;
    Color: Cardinal;
    Clip: TRect
);
begin
  if Count = 0 then
    Exit;
  if Count < 0 then
  begin
    X := X + Count + 1;
    Count := -Count;
  end;
  if (Y < Clip.Top) or (Y >= Clip.Bottom) or (X >= Clip.Right) or (X + Count <= Clip.Left) then
    Exit;
  if X < Clip.Left then
  begin
    Dec(Count, Clip.Left - X);
    X := Clip.Left;
  end;
  if X + Count > Clip.Right then
    Dec(Count, X + Count - Clip.Right);
  DrawHorizontalLine16(X, Y, Count, Color);
end;

procedure TGraphBufGR.DrawVerticalLine16Clipped(X, Y, Count: Integer; Color: Cardinal; Clip: TRect);
begin
  if Count = 0 then
    Exit;
  if Count < 0 then
  begin
    Y := Y + Count + 1;
    Count := -Count;
  end;
  if (X < Clip.Left) or (X >= Clip.Right) or (Y >= Clip.Bottom) or (Y + Count <= Clip.Top) then
    Exit;
  if Y < Clip.Top then
  begin
    Dec(Count, Clip.Top - Y);
    Y := Clip.Top;
  end;
  if Y + Count > Clip.Bottom then
    Dec(Count, Y + Count - Clip.Bottom);
  DrawVerticalLine16(X, Y, Count, Color);
end;

procedure TGraphBufGR.DrawLine16(First, Last: TPoint; Color: Cardinal);
begin
  if First.Y = Last.Y then
    DrawHorizontalLine16(First.X, First.Y, Last.X - First.X + 1, Color)
  else if First.X = Last.X then
    DrawVerticalLine16(First.X, First.Y, Last.Y - First.Y + 1, Color)
  else
  begin
    LockTexture(False);
    Ex_OKGR_Line_Draw_WORD(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color);
  end;
end;

procedure TGraphBufGR.DrawAnimatedLine16(
    First, Last: TPoint;
    Color: Cardinal;
    Phase: Integer;
    Clip: TRect
);
begin
  LockTexture(False);
  Ex_OKGR_AnimLine_Draw_16(
      Pixels,
      PitchBytes,
      First.X,
      First.Y,
      Last.X,
      Last.Y,
      Color,
      Phase,
      Clip
  );
end;

procedure TGraphBufGR.DrawShadowLine16(
    First, Last: TPoint;
    Color: Cardinal;
    Phase: Integer;
    Clip: TRect;
    ShadowPixels: Pointer;
    ShadowPitch: Integer
);
begin
  LockTexture(False);
  Ex_OKGR_AnimShadowLine_Draw_16(
      Pixels,
      PitchBytes,
      First.X,
      First.Y,
      Last.X,
      Last.Y,
      Color,
      Phase,
      Clip,
      ShadowPixels,
      ShadowPitch
  );
end;

procedure TGraphBufGR.DrawAlphaTrapezium16(
    X1, Y1, X2, Y2, X3, X4: Integer;
    Color: Word;
    Alpha: Byte;
    constref Clip: TRect
);
begin
  LockTexture(False);
  if Alpha = 64 then
    Ex_OKGR_Alpha64Trapezium_16(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip)
  else if Alpha = 128 then
    Ex_OKGR_Alpha128Trapezium_16(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip);
end;

procedure TGraphBufGR.DrawLine16Clipped(First, Last: TPoint; Color: Cardinal; Clip: TRect);
var
  InclusiveClip: TRect;
begin
  if (First.X >= Clip.Left)
      and (First.Y >= Clip.Top)
      and (First.X < Clip.Right)
      and (First.Y < Clip.Bottom)
      and (Last.X >= Clip.Left)
      and (Last.Y >= Clip.Top)
      and (Last.X < Clip.Right)
      and (Last.Y < Clip.Bottom) then
    DrawLine16(First, Last, Color)
  else if First.Y = Last.Y then
    DrawHorizontalLine16Clipped(First.X, First.Y, Last.X - First.X + 1, Color, Clip)
  else if First.X = Last.X then
    DrawVerticalLine16Clipped(First.X, First.Y, Last.Y - First.Y + 1, Color, Clip)
  else
  begin
    InclusiveClip.Left := Clip.Left;
    InclusiveClip.Top := Clip.Top;
    InclusiveClip.Right := Clip.Right - 1;
    InclusiveClip.Bottom := Clip.Bottom - 1;
    LockTexture(False);
    Ex_OKGR_Line_DrawClip_WORD(
        Pixels,
        PitchBytes,
        First.X,
        First.Y,
        Last.X,
        Last.Y,
        Color,
        InclusiveClip
    );
  end;
end;

procedure TGraphBufGR.DrawAntialiasedLine(FirstPoint, SecondPoint: TPoint; Color: Cardinal);
var
  Slope, DX, DY, Gap, EndX, EndY, InterY, Coverage1, Coverage2: Double;
  X, FirstX, LastX, FirstY, LastY: Integer;
  Steep: Boolean;
  Temp, X1, Y1, X2, Y2: Double;
  function LineFraction(
      Value: Double
  ): Double; // @addr $866B20 @ida "double __userpurge $name@<st0>(double Value@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x00867012 0x00867056 0x00867070 0x00867182 0x008671CB 0x008671E2 0x008672E3 0x008672FD"
  begin
    Result := Value - Floor(Value);
  end;
  procedure PlotLinePixel(
      X, Y: Integer;
      Color: Cardinal;
      Alpha: Integer
  ); // @addr $866B8C @ida "void __userpurge $name(int X@<eax>, int Y@<edx>, unsigned int Color@<ecx>, int Alpha@<^0>, void *ParentFrame@<^4>);" @stackpop 4 @calls "0x008670A3 0x008670CA 0x008670F2 0x00867119 0x0086721E 0x00867251 0x00867287 0x008672BC 0x00867330 0x00867357 0x0086737F 0x008673A6"
  var
    Source, Dest: PColorRGBA;
    Denominator: Cardinal;
    function BlendLineChannel(
        DestColor,
        DestAlpha,
        SourceColor,
        SourceAlpha,
        Denominator: Cardinal
    ): Cardinal; // @addr $866B4C @ida "unsigned int __userpurge $name@<eax>(unsigned int DestColor@<eax>, unsigned int DestAlpha@<edx>, unsigned int SourceColor@<ecx>, unsigned int SourceAlpha@<^4>, unsigned int Denominator@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x00866D3F 0x00866D6E 0x00866D9E"
    begin
      Result :=
          ((255 - SourceAlpha) * DestColor * DestAlpha + SourceAlpha * SourceColor * 255)
              div Denominator;
    end;
  begin
    if (Alpha = 0)
        or (X < 0)
        or (Y < 0)
        or (Cardinal(Width) <= Cardinal(X))
        or (Cardinal(Height) <= Cardinal(Y)) then
      Exit;
    Source := @Color;
    Source.A := Alpha;
    Dest := AddPointerOffset(Pixels, PitchBytes * Y + X * SizeOf(TColorRGBA));
    if (Dest.A = 0) or (Source.A = 255) then
      Dest^ := Source^
    else if Dest.A = 255 then
    begin
      Dest.R := ((255 - Source.A) * Dest.R + Source.R * Source.A) div 255;
      Dest.G := ((255 - Source.A) * Dest.G + Source.G * Source.A) div 255;
      Dest.B := ((255 - Source.A) * Dest.B + Source.B * Source.A) div 255;
    end
    else
    begin
      Denominator := 255 * 255 - (255 - Source.A) * (255 - Dest.A);
      Dest.R := BlendLineChannel(Dest.R, Dest.A, Source.R, Source.A, Denominator);
      Dest.G := BlendLineChannel(Dest.G, Dest.A, Source.G, Source.A, Denominator);
      Dest.B := BlendLineChannel(Dest.B, Dest.A, Source.B, Source.A, Denominator);
    end;
  end;
begin
  LockTexture(False);
  X1 := FirstPoint.X;
  Y1 := FirstPoint.Y;
  X2 := SecondPoint.X;
  Y2 := SecondPoint.Y;
  DX := X2 - X1;
  DY := Y2 - Y1;
  if (DX = 0) and (DY = 0) then
    Exit;
  if Abs(DX) > Abs(DY) then
    Steep := False
  else
  begin
    Steep := True;
    Temp := X1;
    X1 := Y1;
    Y1 := Temp;
    Temp := X2;
    X2 := Y2;
    Y2 := Temp;
    Temp := DX;
    DX := DY;
    DY := Temp;
  end;
  if X1 > X2 then
  begin
    Temp := X1;
    X1 := X2;
    X2 := Temp;
    Temp := Y1;
    Y1 := Y2;
    Y2 := Temp;
    DX := X2 - X1;
    DY := Y2 - Y1;
  end;
  Slope := DY / DX;
  EndX := Floor(X1 + 0.5);
  EndY := Y1 + (EndX - X1) * Slope;
  Gap := 1 - LineFraction(X1 + 0.5);
  FirstX := Floor(X1 + 0.5);
  FirstY := Floor(EndY);
  Coverage1 := (1 - LineFraction(EndY)) * Gap;
  Coverage2 := LineFraction(EndY) * Gap;
  if Steep then
  begin
    PlotLinePixel(FirstY, FirstX, Color, Ceil(Coverage1 * 255));
    PlotLinePixel(FirstY + 1, FirstX, Color, Ceil(Coverage2 * 255));
  end
  else
  begin
    PlotLinePixel(FirstX, FirstY, Color, Ceil(Coverage1 * 255));
    PlotLinePixel(FirstX, FirstY + 1, Color, Ceil(Coverage2 * 255));
  end;
  X := FirstX + 1;
  InterY := EndY + Slope;
  EndX := Floor(X2 + 0.5);
  EndY := Y2 + (EndX - X2) * Slope;
  Gap := 1 - LineFraction(X2 - 0.5);
  LastX := Floor(X2 + 0.5);
  LastY := Floor(EndY);
  while LastX - 1 >= X do
  begin
    Coverage1 := 1 - LineFraction(InterY);
    Coverage2 := LineFraction(InterY);
    if Steep then
    begin
      PlotLinePixel(Floor(InterY), X, Color, Ceil(Coverage1 * 255));
      PlotLinePixel(Floor(InterY) + 1, X, Color, Ceil(Coverage2 * 255));
    end
    else
    begin
      PlotLinePixel(X, Floor(InterY), Color, Ceil(Coverage1 * 255));
      PlotLinePixel(X, Floor(InterY) + 1, Color, Ceil(Coverage2 * 255));
    end;
    InterY := InterY + Slope;
    Inc(X);
  end;
  Coverage1 := (1 - LineFraction(EndY)) * Gap;
  Coverage2 := LineFraction(EndY) * Gap;
  if Steep then
  begin
    PlotLinePixel(LastY, LastX, Color, Ceil(Coverage1 * 255));
    PlotLinePixel(LastY + 1, LastX, Color, Ceil(Coverage2 * 255));
  end
  else
  begin
    PlotLinePixel(LastX, LastY, Color, Ceil(Coverage1 * 255));
    PlotLinePixel(LastX, LastY + 1, Color, Ceil(Coverage2 * 255));
  end;
end;

procedure TGraphBufGR.ClearPixels;
begin
  LockTexture(False);
  FillChar(Pixels^, PitchBytes * Height, 0);
end;

procedure TGraphBufGR.FillPixels(Value: Byte);
begin
  LockTexture(False);
  FillMemory(Pixels, PitchBytes * Height, Value);
end;

procedure TGraphBufGR.FillPixels16(Color: Word);
begin
  LockTexture(False);
  Ex_OKGR_Fill_WORD(Pixels, PitchBytes, Width, Height, Color);
end;

procedure TGraphBufGR.FillRect32(Rect: TRect; Color: Cardinal);
var
  X, Y: Integer;
  P: PCardinal;
begin
  LockTexture(False);
  for Y := Rect.Top to Rect.Bottom - 1 do
  begin
    P := PCardinal(PByte(Pixels) + Y * PitchBytes + Rect.Left * 4);
    for X := Rect.Left to Rect.Right - 1 do
    begin
      P^ := Color;
      Inc(P)
    end
  end
end;

procedure TGraphBufGR.ScaleAlpha(Rect: TRect; Alpha: Byte);
var
  X, Y: Integer;
  P, Table: PByte;
begin
  LockTexture(False);
  Table := PByte(Ex_OKGF_MulTable256x256) + Integer(Alpha) * 256;
  for Y := Rect.Top to Rect.Bottom - 1 do
  begin
    P := PByte(Pixels) + Y * PitchBytes + Rect.Left * 4 + 3;
    for X := Rect.Left to Rect.Right - 1 do
    begin
      P^ := Table[P^];
      Inc(P, 4)
    end
  end
end;

procedure TGraphBufGR.FlipHorizontal16;
var
  LeftRow, RightRow, LeftPixel, RightPixel: PWord;
  Temp: Word;
  X, Y: Integer;
begin
  LockTexture(False);
  LeftRow := Pixels;
  RightRow := Pointer(PtrUInt(Pixels) + (Width - 1) * 2);
  for Y := 0 to Height - 1 do
  begin
    LeftPixel := LeftRow;
    RightPixel := RightRow;
    for X := 0 to (Width shr 1) - 1 do
    begin
      Temp := RightPixel^;
      RightPixel^ := LeftPixel^;
      PPixelWordsGR(LeftPixel)^[0] := Temp;
      Inc(LeftPixel);
      Dec(RightPixel);
    end;
    Inc(PByte(LeftRow), PitchBytes);
    Inc(PByte(RightRow), PitchBytes);
  end;
end;

procedure TGraphBufGR.RotateLeft16;
var
  X, Y: Integer;
  Source: Pointer;
  DestRows: Integer;
  Dest, NewPixels: Pointer;
  NewWidth, NewHeight, NewPitch: Integer;
begin
  if (StorageKind = 1) or (Cardinal(Width) < 1) or (Cardinal(Height) < 1) then
    Exit;
  NewWidth := Height;
  NewHeight := Width;
  NewPitch := NewWidth * SizeOf(Word);
  NewPixels := AllocEC(NewHeight * NewPitch);
  Source := Pixels;
  Y := Height;
  DestRows := NewHeight;
  Dest := AddPointerOffset(NewPixels, (NewHeight - 1) * NewPitch);
  while Y > 0 do
  begin
    X := Width;
    while X > 0 do
    begin
      WriteWordEC(Dest, ReadWordEC(Source));
      Dec(DestRows);
      Dest := AddPointerOffset(Dest, -NewPitch);
      if DestRows <= 0 then
      begin
        DestRows := NewHeight;
        Dest := AddPointerOffset(Dest, NewPitch * NewHeight + SizeOf(Word));
      end;
      Source := AddPointerOffset(Source, SizeOf(Word));
      Dec(X);
    end;
    Source := AddPointerOffset(Source, PitchBytes - Width * SizeOf(Word));
    Dec(Y);
  end;
  FreeEC(Pixels);
  Pixels := NewPixels;
  Width := NewWidth;
  Height := NewHeight;
  PitchBytes := NewPitch;
end;

procedure TGraphBufGR.Stretch16(Width, Height: Cardinal);
var
  Data: Pointer;
begin
  if (Width = Cardinal(Self.Width)) and (Height = Cardinal(Self.Height)) then
    Exit;
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then
    Exit;
  Data := AllocEC(Width * Height * SizeOf(Word));
  Ex_OKGR_StretchGdi_WORD(Data, Width, Height, Pixels, Self.Width, Self.Height);
  FreeEC(Pixels);
  Pixels := Data;
  Self.Width := Width;
  Self.Height := Height;
  PitchBytes := Width * SizeOf(Word);
end;

procedure TGraphBufGR.ConvertRgbTo565;
var
  Data: Pointer;
  NewPitch: Integer;
  NewTexture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
begin
  if (Cardinal(Width) < 1) or (Cardinal(Height) < 1) then
    Exit;
  if UseTexture then
  begin
    NewTexture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    NewTexture.LockRect(0, Locked, nil, 0);
    NewPitch := Locked.Pitch;
    Data := Locked.Bits;
  end
  else
  begin
    NewPitch := Width * SizeOf(Word);
    Data := AllocEC(Height * NewPitch);
  end;
  Ex_OKGF_ConvertRGBto565(Pixels, Data, NewPitch, Width, Height);
  if (StorageKind = 0) and (Pixels <> nil) then
    FreeEC(Pixels);
  if UseTexture then
  begin
    NewTexture.UnlockRect(0);
    Texture := NewTexture;
  end
  else
    Pixels := Data;
  PitchBytes := NewPitch;
  BitsPerPixel := 16;
  BytesPerPixel := SizeOf(Word);
end;

procedure TGraphBufGR.Convert565ToRgb;
var
  Data: Pointer;
  NewPitch: Integer;
begin
  if (Cardinal(Width) < 1) or (Cardinal(Height) < 1) then
    Exit;
  LockTexture(True);
  NewPitch := Width * 3;
  Data := AllocEC(Height * NewPitch);
  Ex_OKGF_Convert565toRGB(Pixels, PitchBytes, Data, NewPitch, Width, Height);
  UnlockTexture;
  if UsesTextureStorage then
  begin
    Texture := nil;
    UsesTextureStorage := False;
  end
  else if (StorageKind = 0) and (Pixels <> nil) then
    FreeEC(Pixels);
  Pixels := Data;
  PitchBytes := NewPitch;
  BitsPerPixel := 24;
  BytesPerPixel := 3;
end;

procedure TGraphBufGR.ShiftLight16(Shift: Integer; Rect: TRect);
begin
  LockTexture(False);
  if Pixels = nil then
    Exit;
  Ex_OKGR_ShrLight_16(
      AddPointerOffset(Pixels, Rect.Left * SizeOf(Word) + Rect.Top * PitchBytes),
      PitchBytes,
      Rect.Right - Rect.Left,
      Rect.Bottom - Rect.Top,
      Shift
  );
end;

procedure TGraphBufGR.DrawCircle16(
    Center: TPoint;
    Radius: Integer;
    OutlineColor, FillColor: Cardinal;
    Clip: TRect
);
var
  InclusiveClip: TRect;
begin
  LockTexture(False);
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  Ex_OKGR_Circle_DrawFillClip_WORD(
      Pixels,
      PitchBytes,
      Center.X,
      Center.Y,
      Radius,
      FillColor,
      InclusiveClip
  );
  if OutlineColor <> FillColor then
    Ex_OKGR_Circle_DrawClip_WORD(
        Pixels,
        PitchBytes,
        Center.X,
        Center.Y,
        Radius,
        OutlineColor,
        InclusiveClip
    );
end;

procedure TGraphBufGR.DrawCircle8(
    Center: TPoint;
    Radius: Integer;
    OutlineColor, FillColor: Cardinal;
    Clip: TRect
);
var
  InclusiveClip: TRect;
begin
  LockTexture(False);
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  Ex_OKGR_Circle_DrawFillClip_BYTE(
      Pixels,
      PitchBytes,
      Center.X,
      Center.Y,
      Radius,
      FillColor,
      InclusiveClip
  );
  if OutlineColor <> FillColor then
    Ex_OKGR_Circle_DrawClip_BYTE(
        Pixels,
        PitchBytes,
        Center.X,
        Center.Y,
        Radius,
        OutlineColor,
        InclusiveClip
    );
end;

procedure TGraphBufGR.ApplyOperations(const Operations: WideString);
var
  Count, i: Integer;
  Part, Value: WideString;
begin
  Count := CountDelimitedPartsW(Operations, '&');
  for i := 0 to Count - 1 do
  begin
    Part := ExtractDelimitedPartW(Operations, i, '&');
    if CountDelimitedPartsW(Part, '=') <= 1 then
    begin
      if Part = '270' then
        RotateLeft16;
    end
    else
    begin
      Value := ExtractDelimitedPartW(Part, 0, '=');
      if Value = 'Stretch' then
      begin
        Value := ExtractDelimitedPartW(Part, 1, '=');
        if CountDelimitedPartsW(Value, ',') > 1 then
          Stretch16(
              StrToInt(ExtractDelimitedPartW(Value, 0, ',')),
              StrToInt(ExtractDelimitedPartW(Value, 1, ','))
          );
      end;
    end;
  end;
end;

procedure TGraphBufGR.RescaleRgb(Width, Height: Integer);
var
  Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then
    Exit;
  if (Self.Width = Width) and (Self.Height = Height) then
    Exit;
  Data := AllocEC(Width * 3 * Height);
  Ex_OKGF_Rescale(
      Data,
      Width,
      Height,
      Width * 3,
      Pixels,
      Self.Width,
      Self.Height,
      PitchBytes,
      3,
      5
  );
  if StorageKind = 0 then
    FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data;
  Self.Width := Width;
  Self.Height := Height;
  PitchBytes := Width * 3;
end;

procedure TGraphBufGR.RescaleRgba(Width, Height, Filter: Integer);
var
  Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then
    Exit;
  if (Self.Width = Width) and (Self.Height = Height) then
    Exit;
  Data := AllocEC(Width * SizeOf(TColorRGBA) * Height);
  Ex_OKGF_Rescale(
      Data,
      Width,
      Height,
      Width * SizeOf(TColorRGBA),
      Pixels,
      Self.Width,
      Self.Height,
      PitchBytes,
      4,
      Filter
  );
  if StorageKind = 0 then
    FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data;
  Self.Width := Width;
  Self.Height := Height;
  PitchBytes := Width * SizeOf(TColorRGBA);
end;

// CHANGE: BUGFIX - Use bilinear filtering for background resizing to avoid a brightness grid.
procedure TGraphBufGR.RescaleBilinearRgba(Width, Height: Integer);
var
  X, Y, SourceX, YPosition, YStep, XStep, PixelX, NextPixelX, FractionX: Integer;
  BottomWeight, TopWeight, TopLeftWeight, TopRightWeight, BottomLeftWeight, BottomRightWeight:
      Integer;
  TopRow, BottomRow: PColorRGBAArray;
  Dest: PColorRGBA;
  Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then
    Exit;
  if (Self.Width = Width) and (Self.Height = Height) then
    Exit;
  Data := AllocEC(Width * SizeOf(TColorRGBA) * Height);
  YPosition := 0;
  XStep := ((Self.Width - 1) shl 16) div Width;
  YStep := ((Self.Height - 1) shl 16) div Height;
  Dest := Data;
  for Y := 0 to Height - 1 do
  begin
    SourceX := YPosition shr 16;
    TopRow := AddPointerOffset(Pixels, PitchBytes * SourceX);
    if Self.Height - 1 > SourceX then
      Inc(SourceX);
    BottomRow := AddPointerOffset(Pixels, PitchBytes * SourceX);
    SourceX := 0;
    BottomWeight := (YPosition and $FFFF) + 1;
    TopWeight := ((not YPosition) and $FFFF) + 1;
    for X := 0 to Width - 1 do
    begin
      PixelX := SourceX shr 16;
      NextPixelX := Min(PixelX + 1, Self.Width - 1);
      FractionX := SourceX and $FFFF;
      TopRightWeight := (TopWeight * FractionX) shr 16;
      TopLeftWeight := TopWeight - TopRightWeight;
      BottomRightWeight := (BottomWeight * FractionX) shr 16;
      BottomLeftWeight := BottomWeight - BottomRightWeight;
      Dest.R :=
          (TopRow^[PixelX].R * TopLeftWeight
                  + TopRow^[NextPixelX].R * TopRightWeight
                  + BottomRow^[PixelX].R * BottomLeftWeight
                  + BottomRow^[NextPixelX].R * BottomRightWeight)
              shr 16;
      Dest.G :=
          (TopRow^[PixelX].G * TopLeftWeight
                  + TopRow^[NextPixelX].G * TopRightWeight
                  + BottomRow^[PixelX].G * BottomLeftWeight
                  + BottomRow^[NextPixelX].G * BottomRightWeight)
              shr 16;
      Dest.B :=
          (TopRow^[PixelX].B * TopLeftWeight
                  + TopRow^[NextPixelX].B * TopRightWeight
                  + BottomRow^[PixelX].B * BottomLeftWeight
                  + BottomRow^[NextPixelX].B * BottomRightWeight)
              shr 16;
      Dest.A :=
          (TopRow^[PixelX].A * TopLeftWeight
                  + TopRow^[NextPixelX].A * TopRightWeight
                  + BottomRow^[PixelX].A * BottomLeftWeight
                  + BottomRow^[NextPixelX].A * BottomRightWeight)
              shr 16;
      Inc(SourceX, XStep);
      Inc(Dest);
    end;
    Inc(YPosition, YStep);
  end;
  if StorageKind = 0 then
    FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data;
  Self.Width := Width;
  Self.Height := Height;
  PitchBytes := Width * SizeOf(TColorRGBA);
end;

procedure TGraphBufGR.FillPolygon32(Points: array of TPoint; Color: Cardinal);
var
  i, Count, Y, NextY, LeftX, NextLeftX, RightX, NextRightX: Integer;
  Top, Bottom, LeftStart, RightStart, LeftEnd, RightEnd: Integer;
  Clip: TRect;
begin
  Count := Length(Points);
  if Count < 3 then
    Exit;
  Clip := Classes.Rect(0, 0, Width, Height);
  Top := 0;
  Bottom := 0;
  for i := 1 to Count - 1 do
  begin
    if Points[i].Y < Points[Top].Y then
      Top := i;
    if Points[i].Y > Points[Bottom].Y then
      Bottom := i;
  end;
  if Points[Top].Y = Points[Bottom].Y then
    Exit;
  LeftStart := Top;
  RightStart := Top;
  LeftEnd := Top;
  RightEnd := Top;
  LeftX := Points[Top].X;
  RightX := LeftX;
  Y := Points[Top].Y;
  repeat
    if Points[LeftEnd].Y = Y then
    begin
      while Points[LeftEnd].Y = Y do
      begin
        LeftStart := LeftEnd;
        Dec(LeftEnd);
        if LeftEnd < 0 then
          LeftEnd := Count - 1;
      end;
      if Points[Top].Y = Y then
        LeftX := Points[LeftStart].X;
    end;
    if Points[RightEnd].Y = Y then
    begin
      while Points[RightEnd].Y = Y do
      begin
        RightStart := RightEnd;
        Inc(RightEnd);
        if RightEnd >= Count then
          RightEnd := 0;
      end;
      if Points[Top].Y = Y then
        RightX := Points[RightStart].X;
    end;
    if Points[RightEnd].Y < Points[LeftEnd].Y then
    begin
      NextY := Points[RightEnd].Y;
      NextRightX := Points[RightEnd].X;
      NextLeftX :=
          (Points[RightEnd].Y - Points[LeftStart].Y)
                  * (Points[LeftEnd].X - Points[LeftStart].X)
                  div (Points[LeftEnd].Y - Points[LeftStart].Y)
              + Points[LeftStart].X;
    end
    else
    begin
      NextY := Points[LeftEnd].Y;
      NextLeftX := Points[LeftEnd].X;
      NextRightX :=
          (Points[RightEnd].X - Points[RightStart].X)
                  * (Points[LeftEnd].Y - Points[RightStart].Y)
                  div (Points[RightEnd].Y - Points[RightStart].Y)
              + Points[RightStart].X;
    end;
    if (LeftX < RightX) = (NextLeftX < NextRightX) then
      Ex_OKGR_FillTrapezium_DWORD(
          Pixels,
          PitchBytes,
          RightX,
          LeftX,
          Y,
          NextRightX,
          NextLeftX,
          NextY,
          Color,
          Clip
      )
    else
      Ex_OKGR_FillTrapezium_DWORD(
          Pixels,
          PitchBytes,
          LeftX,
          RightX,
          Y,
          NextLeftX,
          NextRightX,
          NextY,
          Color,
          Clip
      );
    LeftX := NextLeftX;
    RightX := NextRightX;
    Y := NextY;
  until Points[Bottom].Y = Y;
end;

function TGraphBufGR.GetPixelCentroid: TPoint;
var
  X, Y, Count: Integer;
begin
  Result.X := 0;
  Result.Y := 0;
  Count := 0;
  for Y := 0 to Height - 1 do
    for X := 0 to Width - 1 do
      if GetPixel32(X, Y) <> 0 then
      begin
        Inc(Result.X, X);
        Inc(Result.Y, Y);
        Inc(Count);
      end;
  if Count < 1 then
    Result := Classes.Point(0, 0)
  else
    Result := Classes.Point(Result.X div Count, Result.Y div Count);
end;

procedure TGraphBufGR.CopyRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect);
var
  Y, W, H: Integer;
  S, D: PByte;
begin
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;
  if (W <= 0) or (H <= 0) then
    Exit;
  S := PByte(Source.GetPixels) + Rect.Top * Source.PitchBytes + Rect.Left * 4;
  D := PByte(GetPixels) + Dest.Y * PitchBytes + Dest.X * 4;
  for Y := 1 to H do
  begin
    Move(S^, D^, W * 4);
    Inc(S, Source.PitchBytes);
    Inc(D, PitchBytes)
  end
end;

procedure TGraphBufGR.BlendRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect);
var
  X, Y, C, A, W, H: Integer;
  S, D, Table: PByte;
begin
  W := Rect.Right - Rect.Left;
  H := Rect.Bottom - Rect.Top;
  Table := Ex_OKGF_MulTable256x256;
  for Y := 0 to H - 1 do
  begin
    S := PByte(Source.GetPixels) + (Rect.Top + Y) * Source.PitchBytes + Rect.Left * 4;
    D := PByte(GetPixels) + (Dest.Y + Y) * PitchBytes + Dest.X * 4;
    for X := 0 to W - 1 do
    begin
      A := S[3];
      for C := 0 to 2 do
        D[C] := Byte(Table[Integer(S[C]) * 256 + A] + Table[Integer(D[C]) * 256 + 255 - A]);
      D[3] := Min(255, Integer(D[3]) + A);
      Inc(S, 4);
      Inc(D, 4)
    end
  end
end;

procedure TGraphBufGR.MakeShadow;
var
  X, Y: Integer;
  P: PCardinal;
begin
  for Y := 0 to Height - 1 do
  begin
    P := PCardinal(PByte(GetPixels) + Y * PitchBytes);
    for X := 0 to Width - 1 do
    begin
      P^ := (P^ shr 2) and $FF000000;
      Inc(P)
    end
  end
end;

procedure TGraphBufGR.SaveToBuffer(Buffer: TBufEC);
var
  Size: Integer;
begin
  Buffer.Clear;
  Buffer.AddDWord(Width);
  Buffer.AddDWord(Height);
  Buffer.AddDWord(PitchBytes);
  Size := PitchBytes * Height;
  Buffer.SetSize(Buffer.DataSize + Size);
  CopyMemory(AddPointerOffset(Buffer.Data, Buffer.Position), GetPixels, Size);
end;

procedure TGraphBufGR.LoadFromBuffer(Buffer: TBufEC);
var
  Size: Integer;
begin
  Clear;
  Buffer.ExpandZlibPayloadInPlace;
  Width := Buffer.GetUInt32;
  Height := Buffer.GetUInt32;
  PitchBytes := Buffer.GetUInt32;
  Size := PitchBytes * Height;
  if Buffer.DataSize - Buffer.Position < Size then
    RaiseWideMessage('load bin');
  Pixels := AllocEC(Size);
  CopyMemory(GetPixels, AddPointerOffset(Buffer.Data, Buffer.Position), Size);
  BytesPerPixel := Cardinal(PitchBytes) div Cardinal(Width);
  BitsPerPixel := BytesPerPixel * 8;
end;

procedure TGraphBufGR.SavePng(FileName: WideString);
begin
  LockTexture(True);
  WritePngFile(PAnsiChar(AnsiString(FileName)), GetPixels, PitchBytes, Width, Height, 1, 1);
end;

procedure TGraphBufGR.SaveBmp(FileName: WideString);
begin
  LockTexture(True);
  WriteBmpFile(
      PAnsiChar(AnsiString(FileName)),
      GetPixels,
      PitchBytes,
      32,
      $FF0000,
      $FF00,
      $FF,
      0,
      Width,
      Height
  );
end;

procedure TGraphBufGR.SaveJpeg(FileName: WideString; Quality: Integer);
begin
  if sr_save_jpeg(
          PAnsiChar(NativePath(UTF8Encode(FileName))),
          GetPixels,
          Width,
          Height,
          PitchBytes,
          BytesPerPixel,
          Quality)
      = 0 then
    raise Exception.Create('Could not write JPEG: ' + UTF8Encode(FileName))
end;

procedure TGraphBufGR.DrawNinePatch(
    X, Y, Width, Height: Integer;
    Source: TGraphBufGR;
    SourceRect, Borders: TRect
);
var
  TileRect: TRect;
  procedure TilePatch(
      X, Y, Width, Height: Integer;
      Rect: TRect
  ); // @addr $868D90 @ida "void __userpurge $name(int X@<eax>, int Y@<edx>, int Width@<ecx>, int Height@<^4>, TRect *Rect@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x869065 0x8690AB 0x8690EB 0x869131 0x86917D"
  var
    TileX, TileY, TileWidth, TileHeight: Integer;
  begin
    TileWidth := Rect.Right - Rect.Left;
    if TileWidth <= 0 then
      Exit;
    TileHeight := Rect.Bottom - Rect.Top;
    if TileHeight <= 0 then
      Exit;
    TileY := 0;
    while TileY < Height do
    begin
      if TileY + TileHeight > Height then
        Rect.Bottom := Height - TileY + Rect.Top;
      TileX := 0;
      while TileX < Width do
      begin
        if TileX + TileWidth > Width then
          CopyRect32(
              Classes.Point(X + TileX, Y + TileY),
              Source,
              Classes.Rect(Rect.Left, Rect.Top, Width - TileX + Rect.Left, Rect.Bottom)
          )
        else
          CopyRect32(Classes.Point(X + TileX, Y + TileY), Source, Rect);
        Inc(TileX, TileWidth);
      end;
      Inc(TileY, TileHeight);
    end;
  end;
begin
  if Width <= 0 then
    Width := Self.Width - X;
  if Height <= 0 then
    Height := Self.Height - Y;
  if SourceRect.Right <= SourceRect.Left then
    SourceRect.Right := Source.Width;
  if SourceRect.Bottom <= SourceRect.Top then
    SourceRect.Bottom := Source.Height;
  TileRect :=
      Classes.Rect(
          SourceRect.Left,
          SourceRect.Top,
          SourceRect.Left + Borders.Left,
          SourceRect.Top + Borders.Top
      );
  CopyRect32(Classes.Point(X, Y), Source, TileRect);
  TileRect :=
      Classes.Rect(
          SourceRect.Right - Borders.Right,
          SourceRect.Top,
          SourceRect.Right,
          SourceRect.Top + Borders.Top
      );
  CopyRect32(Classes.Point(X + Width - Borders.Right, Y), Source, TileRect);
  TileRect :=
      Classes.Rect(
          SourceRect.Left,
          SourceRect.Bottom - Borders.Bottom,
          SourceRect.Left + Borders.Left,
          SourceRect.Bottom
      );
  CopyRect32(Classes.Point(X, Y + Height - Borders.Bottom), Source, TileRect);
  TileRect :=
      Classes.Rect(
          SourceRect.Right - Borders.Right,
          SourceRect.Bottom - Borders.Bottom,
          SourceRect.Right,
          SourceRect.Bottom
      );
  CopyRect32(
      Classes.Point(X + Width - Borders.Right, Y + Height - Borders.Bottom),
      Source,
      TileRect
  );
  TileRect :=
      Classes.Rect(
          SourceRect.Left + Borders.Left,
          SourceRect.Top,
          SourceRect.Right - Borders.Right,
          SourceRect.Top + Borders.Top
      );
  TilePatch(X + Borders.Left, Y, Width - Borders.Left - Borders.Right, Borders.Top, TileRect);
  TileRect :=
      Classes.Rect(
          SourceRect.Left + Borders.Left,
          SourceRect.Bottom - Borders.Bottom,
          SourceRect.Right - Borders.Right,
          SourceRect.Bottom
      );
  TilePatch(
      X + Borders.Left,
      Y + Height - Borders.Bottom,
      Width - Borders.Left - Borders.Right,
      Borders.Bottom,
      TileRect
  );
  TileRect :=
      Classes.Rect(
          SourceRect.Left,
          SourceRect.Top + Borders.Top,
          SourceRect.Left + Borders.Left,
          SourceRect.Bottom - Borders.Bottom
      );
  TilePatch(X, Y + Borders.Top, Borders.Left, Height - Borders.Top - Borders.Bottom, TileRect);
  TileRect :=
      Classes.Rect(
          SourceRect.Right - Borders.Right,
          SourceRect.Top + Borders.Top,
          SourceRect.Right,
          SourceRect.Bottom - Borders.Bottom
      );
  TilePatch(
      X + Width - Borders.Right,
      Y + Borders.Top,
      Borders.Right,
      Height - Borders.Top - Borders.Bottom,
      TileRect
  );
  TileRect :=
      Classes.Rect(
          SourceRect.Left + Borders.Left,
          SourceRect.Top + Borders.Top,
          SourceRect.Right - Borders.Right,
          SourceRect.Bottom - Borders.Bottom
      );
  TilePatch(
      X + Borders.Left,
      Y + Borders.Top,
      Width - Borders.Left - Borders.Right,
      Height - Borders.Top - Borders.Bottom,
      TileRect
  );
end;

procedure TGraphBufGR.RescaleWithAspect(
    Width, Height: Cardinal;
    CropToAspect: Boolean;
    HorizontalAlign, VerticalAlign, Filter: Integer
);
var
  Left, Top, CropWidth, CropHeight: Cardinal;
  Source, Dest: Pointer;
  SourcePitch, DestPitch: Integer;
  NewTexture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
begin
  if (Width = Cardinal(Self.Width)) and (Height = Cardinal(Self.Height)) then
    Exit;
  Left := 0;
  Top := 0;
  if CropToAspect then
  begin
    CropWidth := Self.Width;
    CropHeight := Round((Height / Width) * Cardinal(Self.Width));
    if CropHeight > Cardinal(Self.Height) then
    begin
      CropWidth := Round((Width / Height) * Cardinal(Self.Height));
      CropHeight := Self.Height;
    end;
    if HorizontalAlign = 1 then
      Left := (Cardinal(Self.Width) - CropWidth) shr 1
    else if HorizontalAlign = 2 then
      Left := Cardinal(Self.Width) - CropWidth
    else
      Left := 0;
    if VerticalAlign = 1 then
      Top := (Cardinal(Self.Height) - CropHeight) shr 1
    else if VerticalAlign = 2 then
      Top := Cardinal(Self.Height) - CropHeight
    else
      Top := 0;
    if ((Width = Cardinal(Self.Width)) and (Height < Cardinal(Self.Height)))
        or ((Height = Cardinal(Self.Height)) and (Width < Cardinal(Self.Width))) then
    begin
      Crop(Classes.Rect(Left, Top, Left + CropWidth, Top + CropHeight));
      Exit;
    end;
  end
  else
  begin
    CropWidth := Self.Width;
    CropHeight := Self.Height;
  end;
  if UseTexture and (BitsPerPixel = 32) then
  begin
    NewTexture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    NewTexture.LockRect(0, Locked, nil, 0);
    Dest := Locked.Bits;
    DestPitch := Locked.Pitch;
  end
  else
  begin
    DestPitch := Width * BytesPerPixel;
    Dest := AllocEC(Height * DestPitch);
  end;
  if UsesTextureStorage and (Texture <> nil) then
  begin
    Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY);
    Source := Locked.Bits;
    SourcePitch := Locked.Pitch;
  end
  else
  begin
    Source := Pixels;
    SourcePitch := PitchBytes;
  end;
  Ex_OKGF_Rescale(
      Dest,
      Width,
      Height,
      DestPitch,
      AddPointerOffset(Source, Top * SourcePitch + Left * BytesPerPixel),
      CropWidth,
      CropHeight,
      SourcePitch,
      BytesPerPixel,
      Filter
  );
  if UseTexture and (BitsPerPixel = 32) then
  begin
    if not TextureFlag22 then
      Texture := nil;
    NewTexture.UnlockRect(0);
    Texture := NewTexture;
    TextureLocked := False;
    UsesTextureStorage := True;
    Pixels := nil;
  end
  else
  begin
    if StorageKind = 0 then
      FreeEC(Pixels);
    StorageKind := 0;
    Pixels := Dest;
    Texture := nil;
  end;
  Self.Width := Width;
  Self.Height := Height;
  PitchBytes := DestPitch;
end;

procedure TGraphBufGR.RescaleRGBA_HW(
    Width, Height: Cardinal;
    CropToAspect: Boolean;
    HorizontalAlign, VerticalAlign: Integer
);
var
  Left, Top, CropWidth, CropHeight: Cardinal;
begin
  if (Width = 0) or (Height = 0) or (Self.Width < 1) or (Self.Height < 1) then
    Exit;
  if (Width = Cardinal(Self.Width)) and (Height = Cardinal(Self.Height)) then
    Exit;
  // Native uses D3D StretchRect with linear filtering. OKGF filter 1 is a
  // different downsampling kernel: its unnormalized weights create a grid
  // at ratios such as 1920 -> 1280. Reuse the recovered bilinear routine,
  // retaining the native aspect crop and alignment before resizing.
  if CropToAspect then
  begin
    CropWidth := Self.Width;
    CropHeight := Round((Height / Width) * Cardinal(Self.Width));
    if CropHeight > Cardinal(Self.Height) then
    begin
      CropWidth := Round((Width / Height) * Cardinal(Self.Height));
      CropHeight := Self.Height;
    end;
    if HorizontalAlign = 1 then
      Left := (Cardinal(Self.Width) - CropWidth) shr 1
    else if HorizontalAlign = 2 then
      Left := Cardinal(Self.Width) - CropWidth
    else
      Left := 0;
    if VerticalAlign = 1 then
      Top := (Cardinal(Self.Height) - CropHeight) shr 1
    else if VerticalAlign = 2 then
      Top := Cardinal(Self.Height) - CropHeight
    else
      Top := 0;
    if (CropWidth <> Cardinal(Self.Width)) or (CropHeight <> Cardinal(Self.Height)) then
      Crop(Classes.Rect(Left, Top, Left + CropWidth, Top + CropHeight));
  end;
  RescaleBilinearRgba(Width, Height);
end;

procedure TGraphBufGR.Crop(Rect: TRect);
var
  Y, NewWidth, NewHeight: Integer;
  Source, Dest: Pointer;
  NewPitch: Integer;
  NewTexture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
begin
  NewWidth := Rect.Right - Rect.Left;
  NewHeight := Rect.Bottom - Rect.Top;
  if (NewWidth <= 0)
      or (NewHeight <= 0)
      or (Rect.Left < 0)
      or (Rect.Left >= Width)
      or (Rect.Right > Width)
      or (Rect.Top < 0)
      or (Rect.Top >= Height)
      or (Rect.Bottom > Height) then
    Exit;
  if UseTexture then
  begin
    if BitsPerPixel = 16 then
      NewTexture := GR_CreateTexture(NewWidth, NewHeight, D3DFMT_R5G6B5, D3DPOOL_MANAGED)
    else if BitsPerPixel = 32 then
      NewTexture := GR_CreateTexture(NewWidth, NewHeight, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    NewTexture.LockRect(0, Locked, nil, 0);
    Dest := Locked.Bits;
    NewPitch := Locked.Pitch;
  end
  else
  begin
    NewPitch := NewWidth * BytesPerPixel;
    Dest := AllocEC(NewHeight * NewPitch);
  end;
  LockTexture(True);
  Source := AddPointerOffset(Pixels, Rect.Top * PitchBytes + Rect.Left * BytesPerPixel);
  Y := 0;
  while Y < NewHeight do
  begin
    CopyMemory(
        AddPointerOffset(Dest, Y * NewPitch),
        AddPointerOffset(Source, Y * PitchBytes),
        NewWidth * BytesPerPixel
    );
    Inc(Y);
  end;
  UnlockTexture;
  if UseTexture then
  begin
    NewTexture.UnlockRect(0);
    if not TextureFlag22 then
      Texture := nil;
    Texture := NewTexture;
  end
  else
  begin
    if StorageKind = 0 then
      FreeEC(Pixels);
    StorageKind := 0;
    Pixels := Dest;
  end;
  Width := NewWidth;
  Height := NewHeight;
  PitchBytes := NewPitch;
end;

procedure TGraphBufGR.AdjustBrightness(Percent: Integer);
var
  X, Y, C, B, G, R: Integer;
  Pixel: PByte;
  Table: array[0..255] of SmallInt;
begin
  for C := 0 to 255 do
  begin
    Table[C] := (Percent + 100) * C div 100;
    Table[C] := Max(0, Min(255, Table[C]));
  end;
  if BitsPerPixel = 16 then
  begin
    for Y := 0 to Height - 1 do
    begin
      Pixel := Pointer(PtrUInt(GetPixels) + PitchBytes * Y);
      for X := 0 to Width - 1 do
      begin
        C := PWord(Pixel)^;
        B := (C and 31) shl 3;
        G := (C shr 3) and $FC;
        R := (C shr 8) and $F8;
        B := Table[B];
        G := Table[G];
        R := Table[R];
        C := (B shr 3) or ((G shr 2) shl 5) or ((R shr 3) shl 11);
        PWord(Pixel)^ := C;
        Inc(Pixel, 2);
      end;
    end;
  end
  else if BitsPerPixel = 32 then
  begin
    for Y := 0 to Height - 1 do
    begin
      Pixel := Pointer(PtrUInt(GetPixels) + PitchBytes * Y);
      for X := 0 to Width - 1 do
      begin
        Pixel^ := Table[Pixel^];
        PByte(PtrUInt(Pixel) + 1)^ := Table[PByte(PtrUInt(Pixel) + 1)^];
        PByte(PtrUInt(Pixel) + 2)^ := Table[PByte(PtrUInt(Pixel) + 2)^];
        Inc(Pixel, 4);
      end;
    end;
  end;
end;

procedure TGraphBufGR.ConvertToGrayscale;
var
  X, Y: Integer;
  Pixel: PByte;
  C, R, G, B, RWeight, GWeight, BWeight: Cardinal;
begin
  if BitsPerPixel = 16 then
  begin
    RWeight := 19595;
    GWeight := 38469;
    BWeight := 7471;
    for Y := 0 to Height - 1 do
    begin
      Pixel := Pointer(PtrUInt(GetPixels) + PitchBytes * Y);
      for X := 0 to Width - 1 do
      begin
        C := PWord(Pixel)^;
        R := (C shr 11) and 31;
        G := ((C shr 5) and 63) shr 1;
        B := C and 31;
        R := (R * RWeight + G * GWeight + B * BWeight) shr 16;
        G := R * 2;
        B := R;
        C := (R shl 11) or (G shl 5) or B;
        PWord(Pixel)^ := C;
        Inc(Pixel, 2);
      end;
    end;
  end
  else if BitsPerPixel = 32 then
  begin
    for Y := 0 to Height - 1 do
    begin
      Pixel := Pointer(PtrUInt(GetPixels) + PitchBytes * Y);
      for X := 0 to Width - 1 do
      begin
        B := Pixel^;
        G := PByte(PtrUInt(Pixel) + 1)^;
        R := PByte(PtrUInt(Pixel) + 2)^;
        C := Trunc(R * 0.299 + G * 0.587 + B * 0.114);
        Pixel^ := C;
        PByte(PtrUInt(Pixel) + 1)^ := C;
        PByte(PtrUInt(Pixel) + 2)^ := C;
        Inc(Pixel, 4);
      end;
    end;
  end;
end;

function TGraphBufGR.GetTexture: IDirect3DTexture9;
var
  Locked: TD3DLockedRect;
  Y: Cardinal;
  RowBytes: Integer;
  procedure CopyRgbToOpaqueRgba(
      Dest: Pointer;
      DestPitch: Integer;
      Source: Pointer;
      SourcePitch, Width, Height: Integer
  ); // @addr $86A154 @ida "void __userpurge $name(void *Dest@<eax>, int DestPitch@<edx>, void *Source@<ecx>, int SourcePitch@<^8>, int Width@<^4>, int Height@<^0>, void *ParentFrame@<^12>);" @stackpop 12 @calls "0x86A2BE"
  var
    X, Y: Integer;
  begin
    Y := 0;
    while Y < Height do
    begin
      X := 0;
      while X < Width do
      begin
        CopyMemory(
            AddPointerOffset(Dest, X * SizeOf(TColorRGBA)),
            AddPointerOffset(Source, X * 3),
            3
        );
        PByte(AddPointerOffset(Dest, X * SizeOf(TColorRGBA) + 3))^ := 255;
        Inc(X);
      end;
      Dest := AddPointerOffset(Dest, DestPitch);
      Source := AddPointerOffset(Source, SourcePitch);
      Inc(Y);
    end;
  end;
begin
  if not UsesTextureStorage and (Texture = nil) then
  begin
    if BitsPerPixel = 24 then
    begin
      Texture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
      Texture.LockRect(0, Locked, nil, 0);
      CopyRgbToOpaqueRgba(Locked.Bits, Locked.Pitch, Pixels, PitchBytes, Width, Height);
      Texture.UnlockRect(0);
    end
    else
    begin
      if BitsPerPixel = 16 then
        Texture := GR_CreateTexture(Width, Height, D3DFMT_R5G6B5, D3DPOOL_MANAGED)
      else if BitsPerPixel = 32 then
        Texture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
      Texture.LockRect(0, Locked, nil, 0);
      RowBytes := Width * BytesPerPixel;
      Y := 0;
      while Y < Cardinal(Height) do
      begin
        CopyMemory(
            AddPointerOffset(Locked.Bits, Locked.Pitch * Y),
            AddPointerOffset(Pixels, PitchBytes * Y),
            RowBytes
        );
        Inc(Y);
      end;
      Texture.UnlockRect(0);
    end;
  end;
  UnlockTexture;
  Result := Texture;
end;

procedure TGraphBufGR.LoadFromScreen(UnusedOption: Byte);
var
  Offscreen, RenderTarget: IDirect3DSurface9;
  Locked: TD3DLockedRect;
  Y: Cardinal;
  ErrorCode: Integer;
  Desc: TD3DSurfaceDesc;
  procedure SetRowAlpha(
      Pixels: Pointer;
      Count, Alpha: Integer
  ); // @addr $86A400 @ida "void __usercall $name(void *Pixels@<eax>, int Count@<edx>, int Alpha@<ecx>, void *ParentFrame@<^0>);"
  var
    X: Integer;
  begin
    Alpha := Alpha and $FF;
    for X := 0 to Count - 1 do
      PByte(AddPointerOffset(Pixels, X * SizeOf(TColorRGBA) + 3))^ := Alpha;
  end;
begin
  try
    if HardwareRenderingEnabled then
    begin
      ErrorCode := Direct3DDevice.GetRenderTarget(0, RenderTarget);
      if ErrorCode = 0 then
      begin
        ErrorCode := RenderTarget.GetDesc(Desc);
        if ErrorCode = 0 then
        begin
          ErrorCode :=
              Direct3DDevice.CreateOffscreenPlainSurface(
                  Desc.Width,
                  Desc.Height,
                  Desc.Format,
                  D3DPOOL_SYSTEMMEM,
                  Offscreen,
                  nil
              );
          if ErrorCode = 0 then
          begin
            ErrorCode := Direct3DDevice.GetRenderTargetData(RenderTarget, Offscreen);
            if ErrorCode = 0 then
            begin
              Clear;
              Width := Desc.Width;
              Height := Desc.Height;
              BitsPerPixel := 32;
              BytesPerPixel := SizeOf(TColorRGBA);
              if UseTexture then
              begin
                Texture :=
                    GR_CreateTexture(
                        GameScreenWidth,
                        GameScreenHeight,
                        D3DFMT_A8R8G8B8,
                        D3DPOOL_MANAGED
                    );
                UsesTextureStorage := True;
                LockTexture(False);
              end
              else
              begin
                PitchBytes := Width * SizeOf(TColorRGBA);
                Pixels := AllocEC(Height * PitchBytes);
              end;
              if Pixels <> nil then
              begin
                Offscreen.LockRect(Locked, nil, 0);
                for Y := 0 to Cardinal(Height) - 1 do
                begin
                  CopyMemory(
                      AddPointerOffset(Pixels, PitchBytes * Y),
                      AddPointerOffset(Locked.Bits, Locked.Pitch * Y),
                      Width * SizeOf(TColorRGBA)
                  );
                  SetRowAlpha(AddPointerOffset(Pixels, PitchBytes * Y), Width, 255);
                end;
                Offscreen.UnlockRect;
              end;
              UnlockTexture;
            end
            else
              raise Exception.Create(
                  'TGraphBufGR.LoadFromScreen()::GetRenderTargetData fail ('
                      + IntToStr(ErrorCode)
                      + ')');
            Offscreen := nil;
          end
          else
            raise Exception.Create(
                'TGraphBufGR.LoadFromScreen()::CreateOffscreenPlainSurface fail ('
                    + IntToStr(ErrorCode)
                    + ')');
        end
        else
          raise Exception.Create(
              'TGraphBufGR.LoadFromScreen()::GetDesc fail (' + IntToStr(ErrorCode) + ')');
        RenderTarget := nil;
      end
      else
        raise Exception.Create(
            'TGraphBufGR.LoadFromScreen()::GetRenderTarget fail (' + IntToStr(ErrorCode) + ')');
    end
    else
    begin
      AllocateNative(GameScreenWidth, GameScreenHeight);
      try
        Ex_OKGR_Copy_XY_XY_WORD(
            GetPixels,
            PitchBytes,
            0,
            0,
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            0,
            0,
            GameScreenWidth,
            GameScreenHeight
        );
      except
        raise Exception.Create('Error in TGraphBufGR.LoadFromScreen()::OKGR_Copy_XY_XY_WORD');
      end;
    end;
  except
    Clear;
    AllocateNative(GameScreenWidth, GameScreenHeight);
  end;
end;

procedure TGraphBufGR.LockTexture(ReadOnly: Boolean);
var
  Locked: TD3DLockedRect;
begin
  // CPU-only buffers (notably the minimap) temporarily draw with hardware
  // disabled. Invalidate their uploaded texture on every writable access.
  if not ReadOnly and not UsesTextureStorage then
    Texture := nil;

  if HardwareRenderingEnabled and (Self = ScreenRenderBuffer) then
    if sr_gpu_software_pixels(Pixels, PitchBytes) = 0 then
      raise Exception.Create('SDL software fallback: ' + string(sr_error));

  if TextureLockedReadOnly and not ReadOnly then
    UnlockTexture;
  if not TextureLocked then
  begin
    if not UsesTextureStorage or (Texture = nil) then
    begin
      TextureLocked := False;
      Exit;
    end;
    if ReadOnly then
      Texture.LockRect(0, Locked, nil, D3DLOCK_READONLY)
    else
      Texture.LockRect(0, Locked, nil, 0);
    Pixels := Locked.Bits;
    PitchBytes := Locked.Pitch;
    TextureLockedReadOnly := ReadOnly;
    TextureLocked := True;
  end;
end;

procedure TGraphBufGR.UnlockTexture;
begin
  if TextureLocked then
  begin
    TextureLocked := False;
    TextureLockedReadOnly := False;
    if UsesTextureStorage and (Texture <> nil) then
    begin
      Pixels := nil;
      Texture.UnlockRect(0);
    end;
  end;
end;

procedure TGraphBufGR.ConvertBgraToRgb24;
var
  NewPixels, Dest, Source: Pointer;
  NewPitch: Integer;
  X, Y: Cardinal;
begin
  if Cardinal(Width) < 1 then
    Exit;
  if Cardinal(Height) < 1 then
    Exit;
  LockTexture(True);
  NewPitch := Width * 3;
  NewPixels := AllocEC(NewPitch * Height);
  Dest := NewPixels;
  Source := Pixels;
  Y := 0;
  while Y < Cardinal(Height) do
  begin
    X := 0;
    while X < Cardinal(Width) do
    begin
      PByte(AddPointerOffset(Dest, X * 3))^ :=
          PByte(AddPointerOffset(Source, X * SizeOf(TColorRGBA) + 2))^;
      PByte(AddPointerOffset(Dest, X * 3 + 1))^ :=
          PByte(AddPointerOffset(Source, X * SizeOf(TColorRGBA) + 1))^;
      PByte(AddPointerOffset(Dest, X * 3 + 2))^ :=
          PByte(AddPointerOffset(Source, X * SizeOf(TColorRGBA)))^;
      Inc(X);
    end;
    Dest := AddPointerOffset(Dest, NewPitch);
    Source := AddPointerOffset(Source, PitchBytes);
    Inc(Y);
  end;
  UnlockTexture;
  if UsesTextureStorage then
  begin
    Texture := nil;
    UsesTextureStorage := False;
  end
  else if StorageKind = 0 then
  begin
    if Pixels <> nil then
      FreeEC(Pixels);
  end;
  Pixels := NewPixels;
  PitchBytes := NewPitch;
  BitsPerPixel := 24;
  BytesPerPixel := 3;
end;

procedure TGraphBufGR.DrawAntialiasedCircle16(
    Center: TPoint;
    Radius: Integer;
    Color: Cardinal;
    Clip: TRect
);
var
  X, Y, SignX, SignY, Quadrant: Integer;
  PreviousCoverage, Coverage: Single;
  PreviousX: Integer;
  procedure PlotCirclePixel16(
      X,
      Y,
      Alpha: Integer
  ); // @addr $86AC88 @ida "void __usercall $name(int X@<eax>, int Y@<edx>, int Alpha@<ecx>, void *ParentFrame@<^0>);" @calls "0x86ad6f 0x86ad8f 0x86ae87 0x86aeb8 0x86AEED 0x86AF19"
  begin
    if (X >= Clip.Left) and (X < Clip.Right) and (Y >= Clip.Top) and (Y < Clip.Bottom) then
      BlendPixel16(X, Y, Color, Alpha);
  end;
begin
  X := Radius;
  PreviousX := Radius;
  Y := 0;
  PreviousCoverage := 0;
  Quadrant := 0;
  while Quadrant < 4 do
  begin
    SignX := 2 * (Quadrant mod 2) - 1;
    SignY := 2 * (Quadrant div 2 mod 2) - 1;
    PlotCirclePixel16(Center.X + SignX * X, Center.Y + SignY * Y, 255);
    PlotCirclePixel16(Center.X + SignX * Y, Center.Y + SignY * X, 255);
    Inc(Quadrant);
  end;
  while X > Y do
  begin
    Inc(Y);
    Coverage := Sqrt(Sqr(Radius) - Sqr(Y));
    Coverage := Ceil(Coverage) - Coverage;
    if Coverage < PreviousCoverage then
      Dec(X);
    if X < Y then
      Break;
    if (X = Y) and (PreviousX = X) then
      Break;
    Quadrant := 0;
    while Quadrant < 4 do
    begin
      SignX := 2 * (Quadrant mod 2) - 1;
      SignY := 2 * (Quadrant div 2 mod 2) - 1;
      PlotCirclePixel16(Center.X + SignX * X, Center.Y + SignY * Y, Trunc((1 - Coverage) * 255));
      PlotCirclePixel16(Center.X + SignX * Y, Center.Y + SignY * X, Trunc((1 - Coverage) * 255));
      if X - 1 >= Y then
      begin
        PlotCirclePixel16(Center.X + (X - 1) * SignX, Center.Y + SignY * Y, Trunc(255 * Coverage));
        PlotCirclePixel16(Center.X + SignX * Y, Center.Y + (X - 1) * SignY, Trunc(255 * Coverage));
      end;
      Inc(Quadrant);
    end;
    PreviousCoverage := Coverage;
    PreviousX := X;
  end;
end;

procedure TGraphBufGR.DrawAntialiasedLine16(
    X1, Y1, X2, Y2: Integer;
    Color: Cardinal;
    Alpha: Integer;
    Clip: TRect
);
var
  Slope, DX, DY, Gap, EndX, EndY, InterY, Coverage1, Coverage2: Double;
  X, FirstX, LastX, FirstY, LastY: Integer;
  Steep: Boolean;
  Temp, StartX, StartY, FinishX, FinishY: Double;
  function LineFraction16(
      Value: Double
  ): Double; // @addr $86AF54 @ida "double __userpurge $name@<st0>(double Value@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x86b27a 0x86b2be 0x86B2D8 0x86B3D6 0x86b41f 0x86B436 0x86b523 0x86B53D"
  begin
    Result := Value - Floor(Value);
  end;
  procedure PlotLinePixel16(
      X,
      Y,
      Alpha: Integer
  ); // @addr $86AF80 @ida "void __usercall $name(int X@<eax>, int Y@<edx>, int Alpha@<ecx>, void *ParentFrame@<^0>);" @calls "0x86B306 0x86B328 0x86B34B 0x86B36D 0x86B46D 0x86b49b 0x86b4cc 0x86B4FC 0x86B56B 0x86b58d 0x86b5b0 0x86b5d2"
  begin
    if (X >= Clip.Left)
        and (X < Clip.Right)
        and (Y >= Clip.Top)
        and (Y < Clip.Bottom)
        and (Alpha > 0) then
      BlendPixel16(X, Y, Color, Alpha);
  end;
begin
  StartX := X1;
  StartY := Y1;
  FinishX := X2;
  FinishY := Y2;
  DX := FinishX - StartX;
  DY := FinishY - StartY;
  if (DX = 0) and (DY = 0) then
    Exit;
  if Abs(DX) > Abs(DY) then
    Steep := False
  else
  begin
    Steep := True;
    Temp := StartX;
    StartX := StartY;
    StartY := Temp;
    Temp := FinishX;
    FinishX := FinishY;
    FinishY := Temp;
    Temp := DX;
    DX := DY;
    DY := Temp;
  end;
  if StartX > FinishX then
  begin
    Temp := StartX;
    StartX := FinishX;
    FinishX := Temp;
    Temp := StartY;
    StartY := FinishY;
    FinishY := Temp;
    DX := FinishX - StartX;
    DY := FinishY - StartY;
  end;
  Slope := DY / DX;
  EndX := Floor(StartX + 0.5);
  EndY := StartY + (EndX - StartX) * Slope;
  Gap := 1 - LineFraction16(StartX + 0.5);
  FirstX := Floor(StartX + 0.5);
  FirstY := Floor(EndY);
  Coverage1 := (1 - LineFraction16(EndY)) * Gap;
  Coverage2 := LineFraction16(EndY) * Gap;
  if Steep then
  begin
    PlotLinePixel16(FirstY, FirstX, Ceil(Alpha * Coverage1));
    PlotLinePixel16(FirstY + 1, FirstX, Ceil(Alpha * Coverage2));
  end
  else
  begin
    PlotLinePixel16(FirstX, FirstY, Ceil(Alpha * Coverage1));
    PlotLinePixel16(FirstX, FirstY + 1, Ceil(Alpha * Coverage2));
  end;
  X := FirstX + 1;
  InterY := EndY + Slope;
  EndX := Floor(FinishX + 0.5);
  EndY := FinishY + (EndX - FinishX) * Slope;
  Gap := 1 - LineFraction16(FinishX - 0.5);
  LastX := Floor(FinishX + 0.5);
  LastY := Floor(EndY);
  while LastX - 1 >= X do
  begin
    Coverage1 := 1 - LineFraction16(InterY);
    Coverage2 := LineFraction16(InterY);
    if Steep then
    begin
      PlotLinePixel16(Floor(InterY), X, Ceil(Alpha * Coverage1));
      PlotLinePixel16(Floor(InterY) + 1, X, Ceil(Alpha * Coverage2));
    end
    else
    begin
      PlotLinePixel16(X, Floor(InterY), Ceil(Alpha * Coverage1));
      PlotLinePixel16(X, Floor(InterY) + 1, Ceil(Alpha * Coverage2));
    end;
    InterY := InterY + Slope;
    Inc(X);
  end;
  Coverage1 := (1 - LineFraction16(EndY)) * Gap;
  Coverage2 := LineFraction16(EndY) * Gap;
  if Steep then
  begin
    PlotLinePixel16(LastY, LastX, Ceil(Alpha * Coverage1));
    PlotLinePixel16(LastY + 1, LastX, Ceil(Alpha * Coverage2));
  end
  else
  begin
    PlotLinePixel16(LastX, LastY, Ceil(Alpha * Coverage1));
    PlotLinePixel16(LastX, LastY + 1, Ceil(Alpha * Coverage2));
  end;
end;

end.
