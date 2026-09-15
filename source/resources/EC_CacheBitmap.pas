{$EXCESSPRECISION OFF}
unit EC_CacheBitmap;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Cache,
  GR_GraphBuf;
type
  TCBitmapControlEC = class;
  TCBitmapEC = class;
  TCBitmapControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCBitmapEC = class(TCacheDataEC)
    Bitmap: TGraphBufGR;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreateBitmap(Control: TCacheControlEC): TCBitmapEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GR_Main;

procedure TCBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCBitmapControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCBitmapEC) = nil then
  begin
    Control := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCBitmapEC.Create;
end;

function AcquireOrCreateBitmap(Control: TCacheControlEC): TCBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCBitmapEC) as TCBitmapEC;
end;

function TCBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateBitmap(Self);
end;

constructor TCBitmapEC.Create;
begin
  inherited Create;
  Bitmap := TGraphBufGR.Create(False);
end;

destructor TCBitmapEC.Destroy;
begin
  if Bitmap <> nil then
  begin
    Bitmap.Free;
    Bitmap := nil;
  end;
  inherited Destroy;
end;

procedure TCBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  if LoadOption = 'RGBA' then
    Bitmap.LoadImageRgba(SourceBuffer)
  else if LoadOption = 'Gray' then
    Bitmap.LoadImageGrayscale(SourceBuffer)
  else if LoadOption = 'RGB' then
    Bitmap.LoadImageRgb(SourceBuffer)
  else
    Bitmap.LoadImage(SourceBuffer);
  ResidentBytes := Bitmap.PitchBytes * Bitmap.Height;
end;

procedure LinkRecoveredTypes;
begin
  TCBitmapEC.ClassName;
end;
end.
