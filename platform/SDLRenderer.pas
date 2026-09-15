unit SDLRenderer;
{$MODE delphi}
{$EXCESSPRECISION OFF}
// Host-only bridge from the recovered 2D D3D interface to SDL's GPU renderer.
interface
uses
  Direct3D9;
function CreateSDLDevice(Width, Height: Integer): IDirect3DDevice9;
implementation
uses
  SDLRendererBase,
  GameNative,
  SysUtils,
  Types;
type
  TSDLStorage = class;
  ISDLImage = interface
    ['{978C2C44-FC5D-495B-A582-BBAA03C0FC43}']
    function Storage: TSDLStorage;
  end;
  TSDLStorage = class(TInterfacedObject, ISDLImage)
    Desc: TD3DSurfaceDesc;
    Pitch: Integer;
    Pixels: Pointer;
    Handle: Pointer;
    Dirty, Locked, ReadOnly, Screen, Target: Boolean;
    constructor Create(
        W, H: Integer;
        Format, Pool: Cardinal;
        IsTarget: Boolean;
        IsScreen: Boolean = False
    );
    destructor Destroy; override;
    function Storage: TSDLStorage;
    procedure Upload;
    procedure Lock(out Data: TD3DLockedRect; Rect: PRect; Flags: Cardinal);
    procedure Unlock;
  end;
  TSDLTexture = class(TSDLResourceBase, IDirect3DTexture9, ISDLImage)
    Image: ISDLImage;
    constructor Create(AImage: ISDLImage);
    function Storage: TSDLStorage;
    function SetLOD(NewLOD: Cardinal): Cardinal; stdcall;
    function GetLOD: Cardinal; stdcall;
    function GetLevelCount: Cardinal; stdcall;
    function SetAutoGenFilterType(Filter: Cardinal): LongInt; stdcall;
    function GetAutoGenFilterType: Cardinal; stdcall;
    procedure GenerateMipSubLevels; stdcall;
    function GetLevelDesc(Level: Cardinal; out Desc: TD3DSurfaceDesc): LongInt; stdcall;
    function GetSurfaceLevel(Level: Cardinal; out Surface: IDirect3DSurface9): LongInt; stdcall;
    function LockRect(
        Level: Cardinal;
        out LockedRect: TD3DLockedRect;
        Rect: PRect;
        Flags: Cardinal
    ): LongInt; stdcall;
    function UnlockRect(Level: Cardinal): LongInt; stdcall;
    function AddDirtyRect(Rect: PRect): LongInt; stdcall;
  end;
  TSDLSurface = class(TSDLResourceBase, IDirect3DSurface9, ISDLImage)
    Image: ISDLImage;
    constructor Create(AImage: ISDLImage);
    function Storage: TSDLStorage;
    function GetContainer(const IID: TGUID; out Container): LongInt; stdcall;
    function GetDesc(out Desc: TD3DSurfaceDesc): LongInt; stdcall;
    function LockRect(
        out LockedRect: TD3DLockedRect;
        Rect: PRect;
        Flags: Cardinal
    ): LongInt; stdcall;
    function UnlockRect: LongInt; stdcall;
    function GetDC(out DC: Cardinal): LongInt; stdcall;
    function ReleaseDC(DC: Cardinal): LongInt; stdcall;
  end;
  TSDLDevice = class(TSDLDeviceBase)
    CurrentTexture: IDirect3DBaseTexture9;
    CurrentTarget: IDirect3DSurface9;
    Clip: TRect;
    LinearFilter, FlatShading: Boolean;
    constructor Create(W, H: Integer);
    function GetAvailableTextureMem: Cardinal; stdcall; override;
    function CreateTexture(
        Width, Height, Levels, Usage, Format, Pool: Cardinal;
        out Texture: IDirect3DTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; override;
    function CreateRenderTarget(
        Width, Height, Format, MultiSample, MultiSampleQuality: Cardinal;
        Lockable: LongBool;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; override;
    function CreateOffscreenPlainSurface(
        Width, Height, Format, Pool: Cardinal;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; override;
    function UpdateTexture(Source, Dest: IDirect3DBaseTexture9): LongInt; stdcall; override;
    function GetRenderTargetData(Source, Dest: IDirect3DSurface9): LongInt; stdcall; override;
    function SetRenderTarget(
        Index: Cardinal;
        Surface: IDirect3DSurface9
    ): LongInt; stdcall; override;
    function GetRenderTarget(
        Index: Cardinal;
        out Surface: IDirect3DSurface9
    ): LongInt; stdcall; override;
    function BeginScene: LongInt; stdcall; override;
    function EndScene: LongInt; stdcall; override;
    function Present(
        SourceRect, DestRect: PRect;
        DestWindow: Cardinal;
        DirtyRegion: Pointer
    ): LongInt; stdcall; override;
    function Clear(
        RectCount: Cardinal;
        Rects: PRect;
        Flags, Color: Cardinal;
        Z: Single;
        Stencil: Cardinal
    ): LongInt; stdcall; override;
    function SetRenderState(State, Value: Cardinal): LongInt; stdcall; override;
    function SetTexture(
        Stage: Cardinal;
        Texture: IDirect3DBaseTexture9
    ): LongInt; stdcall; override;
    function SetTextureStageState(Stage, State, Value: Cardinal): LongInt; stdcall; override;
    function SetSamplerState(Sampler, State, Value: Cardinal): LongInt; stdcall; override;
    function SetScissorRect(Rect: PRect): LongInt; stdcall; override;
    function GetScissorRect(out Rect: TRect): LongInt; stdcall; override;
    function DrawPrimitiveUP(
        PrimitiveType, PrimitiveCount: Cardinal;
        Data: Pointer;
        Stride: Cardinal
    ): LongInt; stdcall; override;
  end;

procedure Check(Value: Integer);
begin
  if Value = 0 then
    raise Exception.Create('SDL renderer: ' + string(sr_error));
end;
procedure Require(Condition: Boolean; const Operation: string);
begin
  if not Condition then
    raise Exception.Create('SDL renderer: unsupported ' + Operation);
end;
function ImageOf(Value: IInterface): TSDLStorage;
var
  Image: ISDLImage;
begin
  Require(Supports(Value, ISDLImage, Image), 'foreign resource');
  Result := Image.Storage;
end;
constructor TSDLStorage.Create(W, H: Integer; Format, Pool: Cardinal; IsTarget, IsScreen: Boolean);
var
  Bpp: Integer;
begin
  inherited Create;
  Require((W > 0) and (H > 0) and (W <= 16384) and (H <= 16384), 'texture dimensions');
  Require(Format in [D3DFMT_R5G6B5, D3DFMT_A8R8G8B8], 'texture format ' + IntToStr(Format));
  Desc.Width := W;
  Desc.Height := H;
  Desc.Format := Format;
  Desc.Pool := Pool;
  Desc.ResourceType := 3;
  if Format = D3DFMT_R5G6B5 then
    Bpp := 2
  else
    Bpp := 4;
  Pitch := (W * Bpp + 3) and not 3;
  Pixels := AllocMem(SizeUInt(Pitch) * H);
  Screen := IsScreen;
  Target := IsTarget;
  if not Screen then
  begin
    Handle := sr_gpu_image_create(W, H, Format, Ord(IsTarget));
    Check(Ord(Handle <> nil));
  end;
  Dirty := not Target;
end;
destructor TSDLStorage.Destroy;
begin
  sr_gpu_image_free(Handle);
  FreeMem(Pixels);
  inherited Destroy;
end;
function TSDLStorage.Storage: TSDLStorage;
begin
  Result := Self
end;
procedure TSDLStorage.Upload;
begin
  Require(not Locked, 'drawing a locked texture');
  if Dirty then
  begin
    Check(sr_gpu_image_upload(Handle, Pixels, Pitch));
    Dirty := False;
  end;
end;
procedure TSDLStorage.Lock(out Data: TD3DLockedRect; Rect: PRect; Flags: Cardinal);
var
  X, Y, Bpp: Integer;
begin
  Require(not Locked, 'nested texture lock');
  X := 0;
  Y := 0;
  if Rect <> nil then
  begin
    Require(
        (Rect.Left >= 0)
            and (Rect.Top >= 0)
            and (Rect.Right <= Integer(Desc.Width))
            and (Rect.Bottom <= Integer(Desc.Height))
            and (Rect.Right > Rect.Left)
            and (Rect.Bottom > Rect.Top),
        'lock rectangle'
    );
    X := Rect.Left;
    Y := Rect.Top;
  end;
  if Target then
    Check(sr_gpu_read(Handle, Pixels, Pitch, Desc.Format));
  if Desc.Format = D3DFMT_R5G6B5 then
    Bpp := 2
  else
    Bpp := 4;
  Data.Bits := PByte(Pixels) + Y * Pitch + X * Bpp;
  Data.Pitch := Pitch;
  Locked := True;
  ReadOnly := (Flags and D3DLOCK_READONLY) <> 0;
end;
procedure TSDLStorage.Unlock;
begin
  Require(Locked, 'unlock without lock');
  if not ReadOnly then
    Dirty := True;
  Locked := False;
end;
constructor TSDLTexture.Create(AImage: ISDLImage);
begin
  inherited Create;
  Image := AImage
end;
function TSDLTexture.Storage: TSDLStorage;
begin
  Result := Image.Storage
end;
function TSDLTexture.SetLOD(NewLOD: Cardinal): Cardinal;
begin
  Require(NewLOD = 0, 'mip level');
  Result := 0
end;
function TSDLTexture.GetLOD: Cardinal;
begin
  Result := 0
end;
function TSDLTexture.GetLevelCount: Cardinal;
begin
  Result := 1
end;
function TSDLTexture.SetAutoGenFilterType(Filter: Cardinal): LongInt;
begin
  Require(False, 'automatic mipmaps');
  Result := 0
end;
function TSDLTexture.GetAutoGenFilterType: Cardinal;
begin
  Result := 0
end;
procedure TSDLTexture.GenerateMipSubLevels;
begin
  Require(False, 'automatic mipmaps')
end;
function TSDLTexture.GetLevelDesc(Level: Cardinal; out Desc: TD3DSurfaceDesc): LongInt;
begin
  Require(Level = 0, 'mip level');
  Desc := Storage.Desc;
  Result := 0
end;
function TSDLTexture.GetSurfaceLevel(Level: Cardinal; out Surface: IDirect3DSurface9): LongInt;
begin
  Require(Level = 0, 'mip level');
  Surface := TSDLSurface.Create(Image);
  Result := 0
end;
function TSDLTexture.LockRect(
    Level: Cardinal;
    out LockedRect: TD3DLockedRect;
    Rect: PRect;
    Flags: Cardinal
): LongInt;
begin
  Require(Level = 0, 'mip level');
  Storage.Lock(LockedRect, Rect, Flags);
  Result := 0
end;
function TSDLTexture.UnlockRect(Level: Cardinal): LongInt;
begin
  Require(Level = 0, 'mip level');
  Storage.Unlock;
  Result := 0
end;
function TSDLTexture.AddDirtyRect(Rect: PRect): LongInt;
begin
  Storage.Dirty := True;
  Result := 0
end;
constructor TSDLSurface.Create(AImage: ISDLImage);
begin
  inherited Create;
  Image := AImage
end;
function TSDLSurface.Storage: TSDLStorage;
begin
  Result := Image.Storage
end;
function TSDLSurface.GetContainer(const IID: TGUID; out Container): LongInt;
begin
  Require(False, 'surface container');
  Result := 0
end;
function TSDLSurface.GetDesc(out Desc: TD3DSurfaceDesc): LongInt;
begin
  Desc := Storage.Desc;
  Result := 0
end;
function TSDLSurface.LockRect(
    out LockedRect: TD3DLockedRect;
    Rect: PRect;
    Flags: Cardinal
): LongInt;
begin
  Storage.Lock(LockedRect, Rect, Flags);
  Result := 0
end;
function TSDLSurface.UnlockRect: LongInt;
begin
  Storage.Unlock;
  Result := 0
end;
function TSDLSurface.GetDC(out DC: Cardinal): LongInt;
begin
  Require(False, 'GDI DC');
  DC := 0;
  Result := 0
end;
function TSDLSurface.ReleaseDC(DC: Cardinal): LongInt;
begin
  Require(False, 'GDI DC');
  Result := 0
end;
constructor TSDLDevice.Create(W, H: Integer);
begin
  inherited Create;
  CurrentTarget :=
      TSDLSurface.Create(TSDLStorage.Create(W, H, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, True, True));
  Clip := Types.Rect(0, 0, W, H);
  LinearFilter := True;
end;
function TSDLDevice.GetAvailableTextureMem: Cardinal;
begin
  Result := 512 * 1024 * 1024
end; // Cache budget, not a physical VRAM query.
function TSDLDevice.CreateTexture(
    Width, Height, Levels, Usage, Format, Pool: Cardinal;
    out Texture: IDirect3DTexture9;
    SharedHandle: PCardinal
): LongInt;
begin
  Require((Levels <= 1) and (Usage = 0) and (SharedHandle = nil), 'texture options');
  Texture := TSDLTexture.Create(TSDLStorage.Create(Width, Height, Format, Pool, False));
  Result := 0;
end;
function TSDLDevice.CreateRenderTarget(
    Width, Height, Format, MultiSample, MultiSampleQuality: Cardinal;
    Lockable: LongBool;
    out Surface: IDirect3DSurface9;
    SharedHandle: PCardinal
): LongInt;
begin
  Require(
      (MultiSample = 0) and (MultiSampleQuality = 0) and (SharedHandle = nil),
      'target options'
  );
  Surface := TSDLSurface.Create(TSDLStorage.Create(Width, Height, Format, D3DPOOL_DEFAULT, True));
  Result := 0;
end;
function TSDLDevice.CreateOffscreenPlainSurface(
    Width, Height, Format, Pool: Cardinal;
    out Surface: IDirect3DSurface9;
    SharedHandle: PCardinal
): LongInt;
begin
  Require(SharedHandle = nil, 'shared surface');
  Surface := TSDLSurface.Create(TSDLStorage.Create(Width, Height, Format, Pool, False));
  Result := 0;
end;
function TSDLDevice.UpdateTexture(Source, Dest: IDirect3DBaseTexture9): LongInt;
var
  A, B: TSDLStorage;
begin
  A := ImageOf(Source);
  B := ImageOf(Dest);
  Require(
      (A.Desc.Width = B.Desc.Width)
          and (A.Desc.Height = B.Desc.Height)
          and (A.Desc.Format = B.Desc.Format),
      'texture copy dimensions'
  );
  Move(A.Pixels^, B.Pixels^, SizeUInt(A.Pitch) * A.Desc.Height);
  B.Dirty := True;
  Result := 0;
end;
function TSDLDevice.GetRenderTargetData(Source, Dest: IDirect3DSurface9): LongInt;
var
  A, B: TSDLStorage;
begin
  A := ImageOf(Source);
  B := ImageOf(Dest);
  Require(
      A.Target
          and not B.Target
          and (A.Desc.Width = B.Desc.Width)
          and (A.Desc.Height = B.Desc.Height),
      'readback dimensions'
  );
  Check(sr_gpu_read(A.Handle, B.Pixels, B.Pitch, B.Desc.Format));
  B.Dirty := True;
  Result := 0;
end;
function TSDLDevice.SetRenderTarget(Index: Cardinal; Surface: IDirect3DSurface9): LongInt;
var
  A: TSDLStorage;
begin
  Require(Index = 0, 'target index');
  A := ImageOf(Surface);
  Require(A.Target, 'non-target surface');
  Check(sr_gpu_target(A.Handle));
  CurrentTarget := Surface;
  Result := 0;
end;
function TSDLDevice.GetRenderTarget(Index: Cardinal; out Surface: IDirect3DSurface9): LongInt;
begin
  Require(Index = 0, 'target index');
  Surface := CurrentTarget;
  Result := 0
end;
function TSDLDevice.BeginScene: LongInt;
begin
  Result := 0
end;
function TSDLDevice.EndScene: LongInt;
begin
  Result := 0
end;
function TSDLDevice.Present(
    SourceRect, DestRect: PRect;
    DestWindow: Cardinal;
    DirtyRegion: Pointer
): LongInt;
begin
  Require(
      (SourceRect = nil) and (DestRect = nil) and (DestWindow = 0) and (DirtyRegion = nil),
      'partial presentation'
  );
  Check(sr_gpu_present);
  Result := 0;
end;
function TSDLDevice.Clear(
    RectCount: Cardinal;
    Rects: PRect;
    Flags, Color: Cardinal;
    Z: Single;
    Stencil: Cardinal
): LongInt;
begin
  Require((RectCount = 0) and (Flags = 1), 'partial/depth clear');
  Check(sr_gpu_clear(Color));
  Result := 0
end;
function TSDLDevice.SetRenderState(State, Value: Cardinal): LongInt;
begin
  case State of
    8:
    begin
      Require(Value in [2, 3], 'shading');
      FlatShading := Value = 2
    end;
    27, 174, 22: Require(Value = 1, 'blend/scissor/cull state');
    19: Require(Value = 5, 'source blend');
    20: Require(Value = 6, 'destination blend');
  else
    Require(False, 'render state ' + IntToStr(State));
  end;
  Result := 0;
end;
function TSDLDevice.SetTexture(Stage: Cardinal; Texture: IDirect3DBaseTexture9): LongInt;
begin
  Require(Stage = 0, 'texture stage');
  CurrentTexture := Texture;
  Result := 0
end;
function TSDLDevice.SetTextureStageState(Stage, State, Value: Cardinal): LongInt;
begin
  Require((Stage = 0) and (State = 4) and (Value = 4), 'texture alpha operation');
  Result := 0
end;
function TSDLDevice.SetSamplerState(Sampler, State, Value: Cardinal): LongInt;
begin
  Require((Sampler = 0) and (State in [5, 6, 7]) and (Value in [1, 2]), 'sampler state');
  if State in [5, 6] then
    LinearFilter := Value = 2;
  Result := 0;
end;
function TSDLDevice.SetScissorRect(Rect: PRect): LongInt;
begin
  Require(Rect <> nil, 'nil scissor');
  Clip := Rect^;
  Check(sr_gpu_clip(Clip.Left, Clip.Top, Clip.Right, Clip.Bottom));
  Result := 0;
end;
function TSDLDevice.GetScissorRect(out Rect: TRect): LongInt;
begin
  Rect := Clip;
  Result := 0
end;
function TSDLDevice.DrawPrimitiveUP(
    PrimitiveType, PrimitiveCount: Cardinal;
    Data: Pointer;
    Stride: Cardinal
): LongInt;
var
  Image: TSDLStorage;
  Handle: Pointer;
begin
  Handle := nil;
  if CurrentTexture <> nil then
  begin
    Image := ImageOf(CurrentTexture);
    Image.Upload;
    Handle := Image.Handle
  end;
  Check(
      sr_gpu_draw(
          Handle,
          PrimitiveType,
          PrimitiveCount,
          Data,
          Stride,
          Ord(LinearFilter),
          Ord(FlatShading)
      )
  );
  Result := 0;
end;
function CreateSDLDevice(Width, Height: Integer): IDirect3DDevice9;
begin
  Result := TSDLDevice.Create(Width, Height)
end;
end.
