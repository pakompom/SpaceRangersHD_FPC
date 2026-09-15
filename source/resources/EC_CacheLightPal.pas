{$EXCESSPRECISION OFF}
unit EC_CacheLightPal;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Windows,
  Classes,
  EC_Buf,
  EC_Cache;
type
  TCLightPalControlEC = class;
  TCLightPalEC = class;
  TCLightPalControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCLightPalEC = class(TCacheDataEC)
    PaletteData: PWord;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreateLightPalette(Control: TCacheControlEC): TCLightPalEC;
procedure GetLightPaletteMaskInfo(
    Mask: Cardinal;
    Shift: PCardinal;
    BitCount: PCardinal;
    LevelCount: PCardinal
);
function BuildLightPalette(
    Palette: PCardinal;
    ColorCount: Integer;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal
): PWord;
procedure FreeLightPalette(Palette: PWord);
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GR_Main,
  GR_GraphBufPal,
  EC_Mem,
  SysUtils;

procedure TCLightPalControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCLightPalControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCLightPalEC) = nil then
  begin
    Control := TCLightPalControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCLightPalControlEC.CreateData: TCacheDataEC;
begin
  Result := TCLightPalEC.Create;
end;

function AcquireOrCreateLightPalette(Control: TCacheControlEC): TCLightPalEC;
begin
  Result := Control.AcquireDataFromConfig(TCLightPalEC) as TCLightPalEC;
end;

function TCLightPalControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateLightPalette(Self);
end;

procedure GetLightPaletteMaskInfo(Mask: Cardinal; Shift, BitCount, LevelCount: PCardinal);
begin
  Shift^ := 0;
  BitCount^ := 0;
  LevelCount^ := 0;
  if Mask <> 0 then
  begin
    while Mask and 1 = 0 do
    begin
      Inc(Shift^);
      Mask := Mask shr 1;
    end;
    while Mask and 1 <> 0 do
    begin
      Inc(BitCount^);
      Mask := Mask shr 1;
    end;
    LevelCount^ := 1 shl BitCount^;
  end;
end;

function BuildLightPalette(
    Palette: PCardinal;
    ColorCount: Integer;
    RedMask, GreenMask, BlueMask: Cardinal
): PWord;
const
  BrightnessBits = 6;
  BrightnessLevels = 1 shl BrightnessBits;
var
  RShift,
  RBits,
  RLevels,
  RDiscard,
  GShift,
  GBits,
  GLevels,
  GDiscard,
  BShift,
  BBits,
  BLevels,
  BDiscard: Cardinal;
  First, Dest: PWord;
  Red, Green, Blue: Double;
  ColorIndex, Brightness: Integer;
  R, G, B: Cardinal;
  Factor: Double;
begin
  GetLightPaletteMaskInfo(RedMask, @RShift, @RBits, @RLevels);
  RDiscard := 8 - RBits;
  GetLightPaletteMaskInfo(GreenMask, @GShift, @GBits, @GLevels);
  GDiscard := 8 - GBits;
  GetLightPaletteMaskInfo(BlueMask, @BShift, @BBits, @BLevels);
  BDiscard := 8 - BBits;
  First := AllocEC((ColorCount shl BrightnessBits) * SizeOf(First^));
  Dest := First;
  for ColorIndex := 0 to ColorCount - 1 do
  begin
    Red := Palette^ and $FF;
    Green := (Palette^ shr 8) and $FF;
    Blue := (Palette^ shr 16) and $FF;
    Brightness := 0;
    repeat
      Factor := Brightness / (BrightnessLevels - 1);
      R := Trunc(Red * Factor);
      G := Trunc(Green * Factor);
      B := Trunc(Blue * Factor);
      Dest^ :=
          (Word(R shr RDiscard) shl RShift)
              or (Word(G shr GDiscard) shl GShift)
              or (Word(B shr BDiscard) shl BShift);
      Dest := PWord(PtrUInt(Dest) + 2);
      Inc(Brightness);
    until Brightness = BrightnessLevels;
    Palette := PCardinal(PtrUInt(Palette) + 4);
  end;
  Result := First;
end;

procedure FreeLightPalette(Palette: PWord);
begin
  if Palette <> nil then
    FreeEC(Palette);
end;

constructor TCLightPalEC.Create;
begin
  inherited Create;
  PaletteData := nil;
end;

destructor TCLightPalEC.Destroy;
begin
  if PaletteData <> nil then
  begin
    FreeLightPalette(PaletteData);
    PaletteData := nil;
  end;
  inherited Destroy;
end;

procedure TCLightPalEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Bitmap: TGraphBufPalGR;
begin
  Bitmap := nil;
  try
    Bitmap := TGraphBufPalGR.Create;
    Bitmap.LoadImage(SourceBuffer);
    if (Bitmap.PaletteCount < 1) or (Bitmap.PaletteCount > 256) or (Bitmap.Palette = nil) then
      raise Exception.Create('TCLightPalEC.Load. In error create light palette. ');
    PaletteData :=
        BuildLightPalette(
            PCardinal(Bitmap.Palette),
            Bitmap.PaletteCount,
            CurrentPixelFormat.RedMask,
            CurrentPixelFormat.GreenMask,
            CurrentPixelFormat.BlueMask
        );
    if PaletteData = nil then
      raise Exception.Create('TCLightPalEC.Load. Out error create light palette.');
  finally
    if Bitmap <> nil then
      Bitmap.Free;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TCLightPalEC.ClassName;
end;
end.
