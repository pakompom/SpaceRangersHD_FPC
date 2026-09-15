{$EXCESSPRECISION OFF}
unit EC_CacheBuf;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Cache;
type
  TCBufControlEC = class;
  TCBufEC = class;
  TCBufControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCBufEC = class(TCacheDataEC)
    Buffer: TBufEC;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreateBuffer(Control: TCacheControlEC): TCBufEC;
procedure LinkRecoveredTypes;
implementation

uses
  Math,
  GR_Main;

procedure TCBufControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCBufControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCBufEC) = nil then
  begin
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
function TCBufControlEC.CreateData: TCacheDataEC;
begin
  Result := TCBufEC.Create;
end;
function AcquireOrCreateBuffer(Control: TCacheControlEC): TCBufEC;

begin

  Result := Control.AcquireDataFromConfig(TCBufEC) as TCBufEC;
  Result.Buffer.SetPosition(0);
end;
function TCBufControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateBuffer(Self);
end;
constructor TCBufEC.Create;
begin
  inherited Create;
end;
destructor TCBufEC.Destroy;
begin
  if Buffer <> nil then
  begin
    Buffer.Free;
    Buffer := nil;
  end;
  inherited Destroy;
end;
procedure TCBufEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  Buffer := TBufEC.Create;
  Buffer.AddBytes(SourceBuffer.Data, SourceBuffer.DataSize);
end;
procedure LinkRecoveredTypes;
begin
  TCBufEC.ClassName;
end;
end.
