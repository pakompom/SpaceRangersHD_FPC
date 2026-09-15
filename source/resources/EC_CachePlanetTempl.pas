{$EXCESSPRECISION OFF}
unit EC_CachePlanetTempl;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Cache,
  Classes;
type
  TCPlanetTemplControlEC = class;
  TCPlanetTemplEC = class;
  TCPlanetTemplControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCPlanetTemplEC = class(TCacheDataEC)
    TemplateData: Pointer;
    ImageHeight: Integer;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireOrCreatePlanetTemplate(Control: TCacheControlEC): TCPlanetTemplEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  EC_CachePalBitmap,
  EC_Struct,
  GR_Main,
  EC_Str,
  GR_GraphBuf,
  SysUtils;

procedure TCPlanetTemplControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCPlanetTemplControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCPlanetTemplEC) = nil then
  begin
    Control := TCPlanetTemplControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCPlanetTemplControlEC.CreateData: TCacheDataEC;
begin
  Result := TCPlanetTemplEC.Create;
end;

function AcquireOrCreatePlanetTemplate(Control: TCacheControlEC): TCPlanetTemplEC;
begin
  Result := Control.AcquireDataFromConfig(TCPlanetTemplEC) as TCPlanetTemplEC;
end;

function TCPlanetTemplControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreatePlanetTemplate(Self);
end;

constructor TCPlanetTemplEC.Create;
begin
  inherited Create;
  TemplateData := nil;
  ImageHeight := 0;
end;

destructor TCPlanetTemplEC.Destroy;
begin
  if TemplateData <> nil then
  begin
    Ex_OKGR_Planet2_TemplDel(TemplateData);
    TemplateData := nil;
    ImageHeight := 0;
  end;
  inherited Destroy;
end;

procedure TCPlanetTemplEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Bitmap: TGraphBufGR;
  TextureWidth, TextureHeight: Integer;
begin
  Bitmap := TGraphBufGR.Create(False);
  Bitmap.LoadImageRgba(SourceBuffer);
  TextureWidth := ExtractDigitsToIntW(ExtractDelimitedPartW(LoadOption, 0, ','));
  TextureHeight := ExtractDigitsToIntW(ExtractDelimitedPartW(LoadOption, 1, ','));
  TemplateData :=
      Ex_OKGR_Planet2_TemplBuild(
          Bitmap.GetPixels,
          Bitmap.PitchBytes,
          Bitmap.Height,
          TextureWidth,
          TextureHeight,
          ResidentBytes
      );
  if TemplateData = nil then
    raise Exception.Create('TCPlanetTemplEC.Load. Error create template planet.');
  ImageHeight := Bitmap.Height;
  Bitmap.Free;
end;

procedure LinkRecoveredTypes;
begin
  TCPlanetTemplEC.ClassName;
end;
end.
