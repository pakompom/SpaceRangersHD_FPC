{$EXCESSPRECISION OFF}
unit GR_GraphBufPal;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_OKGF,
  EC_Buf,
  EC_Struct,
  GR_GraphBuf;
type
  TGraphBufPalGR = class;
  TGraphBufPalGR = class(TObjectEx)
    Width: Integer;
    Height: Integer;
    PitchBytes: Integer;
    BytesPerPixel: Integer;
    Pixels: Pointer;
    PaletteCount: Integer;
    Palette: PColorRGBA;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AllocateTight(AWidth: Integer; AHeight: Integer; APaletteCount: Integer);
    procedure AllocateBuffer(
        AWidth: Integer;
        AHeight: Integer;
        APaletteCount: Integer;
        APitchBytes: Integer
    );
    function GetPaletteColor(Index: Integer): Cardinal;
    procedure SetPalette(Source: PColorRGBA; Count: Integer);
    function GetPixelIndex(X: Integer; Y: Integer): Byte;
    procedure LoadImage(Buffer: TBufEC);
    procedure ClearPixels;
    procedure FillPixels(Value: Byte);
  end;
implementation
uses
  Math,
  EC_Mem,
  GR_Main,
  SysUtils,
  Windows;

constructor TGraphBufPalGR.Create;
begin
  inherited Create;
end;

destructor TGraphBufPalGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TGraphBufPalGR.Clear;
begin
  if Pixels <> nil then
  begin
    FreeEC(Pixels);
    Pixels := nil;
  end;
  Width := 0;
  Height := 0;
  PitchBytes := 0;
  if Palette <> nil then
  begin
    FreeEC(Palette);
    Palette := nil;
  end;
  PaletteCount := 0;
end;

procedure TGraphBufPalGR.AllocateTight(AWidth, AHeight, APaletteCount: Integer);
begin
  Clear;
  Width := AWidth;
  Height := AHeight;
  PitchBytes := AWidth;
  PaletteCount := APaletteCount;
  Pixels := AllocEC(PitchBytes * Height);
  Palette := AllocEC(APaletteCount * SizeOf(Palette^));
end;

procedure TGraphBufPalGR.AllocateBuffer(AWidth, AHeight, APaletteCount, APitchBytes: Integer);
begin
  Clear;
  Width := AWidth;
  Height := AHeight;
  PitchBytes := APitchBytes;
  if PitchBytes and 3 <> 0 then
    PitchBytes := PitchBytes + 4 - (PitchBytes and 3);
  PaletteCount := APaletteCount;
  Pixels := AllocEC(PitchBytes * Height);
  Palette := AllocEC(APaletteCount * SizeOf(Palette^));
  if (PitchBytes and 3 <> 0) or (PtrUInt(Pixels) and 3 <> 0) then
    raise Exception.Create('TGraphBufPalGR.CreateN');
end;

function TGraphBufPalGR.GetPaletteColor(Index: Integer): Cardinal;
begin
  Result := PCardinal(AddPointerOffset(Palette, Index * SizeOf(Palette^)))^;
end;

procedure TGraphBufPalGR.SetPalette(Source: PColorRGBA; Count: Integer);
begin
  if PaletteCount <> Count then
  begin
    PaletteCount := Count;
    Palette := ReAllocREC(Palette, PaletteCount * SizeOf(Palette^));
  end;
  CopyMemory(Palette, Source, Count * SizeOf(Source^));
end;

function TGraphBufPalGR.GetPixelIndex(X, Y: Integer): Byte;
var
  Data: PByteArray;
begin
  Data := Pixels;
  Result := Data^[Y * PitchBytes + X];
end;

procedure TGraphBufPalGR.LoadImage(Buffer: TBufEC);
var
  Context: POkgfReadContext;
begin
  Clear;
  Context :=
      BeginIndexedImageRead(
          Buffer.Data,
          Buffer.DataSize,
          Width,
          Height,
          PaletteCount,
          BytesPerPixel
      );
  if Context = nil then
    raise Exception.Create('TGraphBufPalGR.LoadFromFile. Error load file');
  AllocateBuffer(Width, Height, PaletteCount, Width * BytesPerPixel);
  Context := Pointer(ReadIndexedImagePixels(Context, Pixels, PitchBytes, Palette));
  if Context = nil then
    raise Exception.Create('TGraphBufPalGR.LoadFromFile. Error load file');
end;

procedure TGraphBufPalGR.ClearPixels;
begin
  FillChar(Pixels^, PitchBytes * Height, 0);
end;

procedure TGraphBufPalGR.FillPixels(Value: Byte);
begin
  FillMemory(Pixels, PitchBytes * Height, Value);
end;

end.
