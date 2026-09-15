{$EXCESSPRECISION OFF}
unit EC_CacheAlphaBitmap;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types,
  Classes,
  EC_Buf,
  EC_Cache,
  GR_DX,
  GR_GraphBuf,
  Direct3D9;
type
  TCAlphaBitmapControlEC = class;
  TCAlphaBitmapEC = class;
  TCAlphaBitmapControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCAlphaBitmapEC = class(TCacheDataEC)
    TransBuf16: Pointer;
    TransAlphaBuf16: Pointer;
    AlphaBuf: Pointer;
    PixelSize: TPoint;
    SurfaceCache: TTextureGR;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
    procedure Draw16(Dest: Pointer; Pitch: Integer; X: Integer; Y: Integer; Clip: TRect);
    procedure DecodeToGraphBuf(Buffer: TGraphBufGR);
    function GetTexture: IDirect3DTexture9;
  end;
function AcquireOrCreateAlphaBitmap(Control: TCacheControlEC): TCAlphaBitmapEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Mem,
  GR_Main,
  Windows;

procedure TCAlphaBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCAlphaBitmapControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCAlphaBitmapEC) = nil then
  begin
    Control := TCAlphaBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCAlphaBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCAlphaBitmapEC.Create;
end;

function AcquireOrCreateAlphaBitmap(Control: TCacheControlEC): TCAlphaBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCAlphaBitmapEC) as TCAlphaBitmapEC;
end;

function TCAlphaBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateAlphaBitmap(Self);
end;

constructor TCAlphaBitmapEC.Create;
begin
  SurfaceCache := nil;
  inherited Create;
end;

destructor TCAlphaBitmapEC.Destroy;
begin
  if TransBuf16 <> nil then
  begin
    FreeEC(TransBuf16);
    TransBuf16 := nil;
  end;
  if TransAlphaBuf16 <> nil then
  begin
    FreeEC(TransAlphaBuf16);
    TransAlphaBuf16 := nil;
  end;
  if AlphaBuf <> nil then
  begin
    FreeEC(AlphaBuf);
    AlphaBuf := nil;
  end;
  if SurfaceCache <> nil then
  begin
    FreeTextureCache(SurfaceCache);
    SurfaceCache := nil;
  end;
  inherited Destroy;
end;

procedure TCAlphaBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Bitmap: TGraphBufGR;
  ByteCount: Cardinal;
begin
  Bitmap := TGraphBufGR.Create(False);
  Bitmap.LoadImageRgba(SourceBuffer);
  ResidentBytes := 0;
  ByteCount :=
      Ex_OKGR_TransBuf_BuildFromRGBA_16(
          Bitmap.GetPixels,
          Bitmap.PitchBytes,
          Bitmap.Width,
          Bitmap.Height,
          nil
      );
  if ByteCount < 1 then
    raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransBuf16 := AllocEC(ByteCount);
  Ex_OKGR_TransBuf_BuildFromRGBA_16(
      Bitmap.GetPixels,
      Bitmap.PitchBytes,
      Bitmap.Width,
      Bitmap.Height,
      TransBuf16
  );
  Inc(ResidentBytes, ByteCount);
  ByteCount :=
      Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
          Bitmap.GetPixels,
          Bitmap.PitchBytes,
          Bitmap.Width,
          Bitmap.Height,
          nil
      );
  if ByteCount < 1 then
    raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransAlphaBuf16 := AllocEC(ByteCount);
  Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
      Bitmap.GetPixels,
      Bitmap.PitchBytes,
      Bitmap.Width,
      Bitmap.Height,
      TransAlphaBuf16
  );
  Inc(ResidentBytes, ByteCount);
  ByteCount :=
      Ex_OKGR_AlphaBuf_BuildFromRGBA(
          Bitmap.GetPixels,
          Bitmap.PitchBytes,
          Bitmap.Width,
          Bitmap.Height,
          nil
      );
  if ByteCount < 1 then
    raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  AlphaBuf := AllocEC(ByteCount);
  Ex_OKGR_AlphaBuf_BuildFromRGBA(
      Bitmap.GetPixels,
      Bitmap.PitchBytes,
      Bitmap.Width,
      Bitmap.Height,
      AlphaBuf
  );
  Inc(ResidentBytes, ByteCount);
  PixelSize.X := Bitmap.Width;
  PixelSize.Y := Bitmap.Height;
  Bitmap.Free;
end;

procedure TCAlphaBitmapEC.Draw16(Dest: Pointer; Pitch, X, Y: Integer; Clip: TRect);
var
  InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  Ex_OKGR_AlphaBuf_DrawClip_16(Dest, Pitch, X, Y, AlphaBuf, InclusiveClip);
  Ex_OKGR_TransAlphaBuf_DrawClip_WORD(Dest, Pitch, X, Y, TransAlphaBuf16, InclusiveClip);
  Ex_OKGR_TransBuf_DrawClip_WORD(Dest, Pitch, X, Y, TransBuf16, InclusiveClip);
end;

procedure TCAlphaBitmapEC.DecodeToGraphBuf(Buffer: TGraphBufGR);
begin
  Buffer.AllocateRgbaTight(PixelSize.X, PixelSize.Y);
  Buffer.ClearPixels;
  Ex_OKGR_AlphaBuf_Draw_RGBA(Buffer.GetPixels, Buffer.PitchBytes, AlphaBuf);
  Ex_OKGR_TransAlphaBuf_Draw_RGBA(Buffer.GetPixels, Buffer.PitchBytes, TransAlphaBuf16);
  Ex_OKGR_TransBuf_Draw_RGBA(Buffer.GetPixels, Buffer.PitchBytes, TransBuf16);
end;

function TCAlphaBitmapEC.GetTexture: IDirect3DTexture9;
var
  Buffer: TGraphBufGR;
  Texture: IDirect3DTexture9;
begin
  if SurfaceCache = nil then
    SurfaceCache := CreateTextureCache;
  Texture := SurfaceCache.GetSurface(0);
  if Texture = nil then
  begin
    Buffer := TGraphBufGR.Create(False);
    DecodeToGraphBuf(Buffer);
    Texture :=
        CreateTextureFromPixels(
            Buffer.Width,
            Buffer.Height,
            21,
            Buffer.GetPixels,
            Buffer.PitchBytes,
            1
        );
    Buffer.Free;
    SurfaceCache.SetSurface(Texture, 0);
  end;
  Result := Texture;
end;

procedure LinkRecoveredTypes;
begin
  TCAlphaBitmapEC.ClassName;
end;
end.
