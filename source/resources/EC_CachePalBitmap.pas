{$EXCESSPRECISION OFF}
unit EC_CachePalBitmap;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  GR_GraphBufPal,
  EC_Cache,
  Classes;
type
  TCPalBitmapControlEC = class;
  TCPalBitmapEC = class;
  TCPalBitmapControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCPalBitmapEC = class(TCacheDataEC)
    Bitmap: TGraphBufPalGR;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreatePalBitmap(Control: TCacheControlEC): TCPalBitmapEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GR_Main;

procedure TCPalBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCPalBitmapControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCPalBitmapEC) = nil then
  begin
    Control := TCPalBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCPalBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCPalBitmapEC.Create;
end;

function AcquireOrCreatePalBitmap(Control: TCacheControlEC): TCPalBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCPalBitmapEC) as TCPalBitmapEC;
end;

function TCPalBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreatePalBitmap(Self);
end;

constructor TCPalBitmapEC.Create;
begin
  inherited Create;
  Bitmap := TGraphBufPalGR.Create;
end;

destructor TCPalBitmapEC.Destroy;
begin
  if Bitmap <> nil then
  begin
    Bitmap.Free;
    Bitmap := nil;
  end;
  inherited Destroy;
end;

procedure TCPalBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  Bitmap.LoadImage(SourceBuffer);
  ResidentBytes :=
      Bitmap.PitchBytes * Bitmap.Height + Bitmap.PaletteCount * SizeOf(Bitmap.Palette^);
end;

procedure LinkRecoveredTypes;
begin
  TCPalBitmapEC.ClassName;
end;
end.
