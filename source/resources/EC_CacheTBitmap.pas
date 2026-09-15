{$EXCESSPRECISION OFF}
unit EC_CacheTBitmap;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types,
  Classes,
  EC_Buf,
  EC_Cache;
type
  TCTBitmapControlEC = class;
  TCTBitmapEC = class;
  TCTBitmapControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCTBitmapEC = class(TCacheDataEC)
    TransBuffer: Pointer;
    PixelSize: TPoint;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireCachedTransBitmap(Control: TCacheControlEC): TCTBitmapEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Str,
  GR_Main,
  GR_GraphBuf;

procedure TCTBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCTBitmapControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCTBitmapEC) = nil then
  begin
    Control := TCTBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCTBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCTBitmapEC.Create;
end;

function AcquireCachedTransBitmap(Control: TCacheControlEC): TCTBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCTBitmapEC) as TCTBitmapEC;
end;

function TCTBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedTransBitmap(Self);
end;

constructor TCTBitmapEC.Create;
begin
  inherited Create;
end;

destructor TCTBitmapEC.Destroy;
begin
  if TransBuffer <> nil then
  begin
    FreeMem(TransBuffer);
    TransBuffer := nil;
  end;
  inherited Destroy;
end;

procedure TCTBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Bitmap: TGraphBufGR;
  ByteCount: Cardinal;
begin
  Bitmap := TGraphBufGR.Create(False);
  Bitmap.LoadImage(SourceBuffer);
  Bitmap.ApplyOperations(LoadOption);
  ByteCount :=
      Ex_OKGR_TransBuf_Build_WORD(
          Bitmap.GetPixels,
          Bitmap.PitchBytes,
          Bitmap.Width,
          Bitmap.Height,
          nil,
          0
      );
  if ByteCount < 1 then
    raise Exception.Create('TCTBitmapEC.Load. Error load file.');
  GetMem(TransBuffer, ByteCount);
  Ex_OKGR_TransBuf_Build_WORD(
      Bitmap.GetPixels,
      Bitmap.PitchBytes,
      Bitmap.Width,
      Bitmap.Height,
      TransBuffer,
      0
  );
  ResidentBytes := ByteCount;
  PixelSize.X := Bitmap.Width;
  PixelSize.Y := Bitmap.Height;
  Bitmap.Free;
end;

procedure LinkRecoveredTypes;
begin
  TCTBitmapEC.ClassName;
end;
end.
