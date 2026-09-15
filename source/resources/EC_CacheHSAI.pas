{$EXCESSPRECISION OFF}
unit EC_CacheHSAI;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Cache,
  GR_DX,
  GR_GraphBuf,
  Direct3D9;
type
  TCHSAIControlEC = class;
  TCHSAIEC = class;
  PointerToTHSAIHeaderEC = ^THSAIHeaderEC;
  THSAIHeaderEC = packed record
    Gap0: array[0..3] of Byte;
    Width: Integer;
    Height: Integer;
    PitchBytes: Integer;
    FrameCount: Cardinal;
    FrameStride: Cardinal;
    Gap18: array[0..23] of Byte;
    PalettePresent: Cardinal;
  end;
  PHSAIHeaderEC = PointerToTHSAIHeaderEC;
  TCHSAIControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCHSAIEC = class(TCacheDataEC)
    BlobData: Pointer;
    Header: PHSAIHeaderEC;
    Width: Integer;
    Height: Integer;
    FrameSurfaceCache: TTextureGR;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
    function GetFrameCount: Cardinal;
    function GetFrameIndexPlane(FrameIndex: Cardinal): Pointer;
    function GetFramePalette(FrameIndex: Cardinal): PColorRGBA;
    function GetOrCreateFrameSurface(FrameIndex: Cardinal): IDirect3DTexture9;
    function GetSourcePitchBytes: Integer;
  end;
function AcquireCachedHSAI(Control: TCacheControlEC): TCHSAIEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Mem,
  GR_Main,
  Windows;

procedure TCHSAIControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCHSAIControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCHSAIEC) = nil then
  begin
    Control := TCHSAIControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCHSAIControlEC.CreateData: TCacheDataEC;
begin
  Result := TCHSAIEC.Create;
end;

function AcquireCachedHSAI(Control: TCacheControlEC): TCHSAIEC;
begin
  Result := Control.AcquireDataFromConfig(TCHSAIEC) as TCHSAIEC;
end;

function TCHSAIControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedHSAI(Self);
end;

constructor TCHSAIEC.Create;
begin
  FrameSurfaceCache := nil;
  inherited Create;
end;

destructor TCHSAIEC.Destroy;
begin
  if BlobData <> nil then
  begin
    FreeEC(BlobData);
    BlobData := nil;
  end;
  if FrameSurfaceCache <> nil then
  begin
    FreeTextureCache(FrameSurfaceCache);
    FrameSurfaceCache := nil;
  end;
  inherited Destroy;
end;

function TCHSAIEC.GetFrameCount: Cardinal;
begin
  Result := Header.FrameCount;
end;

function TCHSAIEC.GetFrameIndexPlane(FrameIndex: Cardinal): Pointer;
begin
  if FrameIndex >= Header.FrameCount then
    Result := nil
  else
    Result := AddPointerOffset(BlobData, SizeOf(THSAIHeaderEC) + FrameIndex * Header.FrameStride);
end;

function TCHSAIEC.GetFramePalette(FrameIndex: Cardinal): PColorRGBA;
begin
  if FrameIndex >= Header.FrameCount then
    Result := nil
  else if Header.PalettePresent = 0 then
    Result := nil
  else
    Result :=
        AddPointerOffset(
            BlobData,
            SizeOf(THSAIHeaderEC)
                + FrameIndex * Header.FrameStride
                + Header.PitchBytes * Header.Height
        );
end;

function TCHSAIEC.GetOrCreateFrameSurface(FrameIndex: Cardinal): IDirect3DTexture9;
var
  Texture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
begin
  if FrameSurfaceCache = nil then
    FrameSurfaceCache := CreateTextureCache;
  Texture := FrameSurfaceCache.GetSurface(FrameIndex);
  if Texture = nil then
  begin
    Texture := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    if Texture <> nil then
    begin
      Texture.LockRect(0, Locked, nil, 0);
      if Locked.Bits <> nil then
      begin
        ExpandPaletteToBgra(
            Locked.Bits,
            Locked.Pitch,
            Width,
            Height,
            GetFrameIndexPlane(FrameIndex),
            Width,
            GetFramePalette(FrameIndex)
        );
        Texture.UnlockRect(0);
      end;
    end;
    FrameSurfaceCache.SetSurface(Texture, FrameIndex);
  end;
  Result := Texture;
end;

function TCHSAIEC.GetSourcePitchBytes: Integer;
begin
  Result := Header.PitchBytes;
end;

procedure TCHSAIEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  if SourceBuffer.DataSize < SizeOf(THSAIHeaderEC) then
    raise Exception.Create('Error Load HSAI');
  BlobData := AllocEC(SourceBuffer.DataSize);
  CopyMemory(BlobData, SourceBuffer.Data, SourceBuffer.DataSize);
  ResidentBytes := SourceBuffer.DataSize;
  Header := BlobData;
  Width := Header.Width;
  Height := Header.Height;
end;

procedure LinkRecoveredTypes;
begin
  TCHSAIEC.ClassName;
end;
end.
