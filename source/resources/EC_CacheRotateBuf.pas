{$EXCESSPRECISION OFF}
unit EC_CacheRotateBuf;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Cache;
type
  TCRotateBufControlEC = class;
  TCRotateBufEC = class;
  TCRotateBufControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCRotateBufEC = class(TCacheDataEC)
    Buffer: Pointer;
    procedure LoadFromKey(const Key: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreateRotateBuf(Control: TCacheControlEC): TCRotateBufEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Str,
  GR_Main,
  GR_GraphBuf;

procedure TCRotateBufControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCRotateBufControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCRotateBufEC) = nil then
  begin
    Control := TCRotateBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCRotateBufControlEC.CreateData: TCacheDataEC;
begin
  Result := TCRotateBufEC.Create;
end;

function AcquireOrCreateRotateBuf(Control: TCacheControlEC): TCRotateBufEC;
begin
  Result := Control.AcquireDataFromDirectKey(TCRotateBufEC) as TCRotateBufEC;
end;

function TCRotateBufControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateRotateBuf(Self);
end;

constructor TCRotateBufEC.Create;
begin
  inherited Create;
  Buffer := nil;
end;

destructor TCRotateBufEC.Destroy;
begin
  if Buffer <> nil then
  begin
    Ex_OKGR_RotateBuf_Free(Buffer);
    Buffer := nil;
  end;
  inherited Destroy;
end;

procedure TCRotateBufEC.LoadFromKey(const Key: WideString);
begin
  if CountDelimitedPartsW(Key, ',') <> 6 then
    raise Exception.Create('TCRotateBufEC.Load. Error create rotate buf.');
  Buffer :=
      Ex_OKGR_RotateBuf_Build(
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 0, ','))),
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 1, ','))),
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 2, ','))),
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 3, ','))),
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 4, ','))),
          StrToInt(AnsiString(ExtractDelimitedPartW(Key, 5, ',')))
      );
  if Buffer = nil then
    raise Exception.Create('TCRotateBufEC.Load. Error create rotate buf.');
end;

procedure LinkRecoveredTypes;
begin
  TCRotateBufEC.ClassName;
end;
end.
