unit GameGraphics;
{$MODE delphi}
{$POINTERMATH ON}
// The game submits transformed 2D vertices through its original drawing interfaces.
interface
uses
  Direct3D9;
function CreateGameGraphics: IDirect3D9;
implementation
uses
  GameGraphicsBase,
  SDL2,
  GameWindow,
  Classes,
  SyncObjs,
  Math,
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
    Handle: PSDL_Texture;
    TextureFormat: Cardinal;
    Generation: LongInt;
    Dirty, Locked, ReadOnly, Screen, Target: Boolean;
    constructor Create(
        W, H: Integer;
        Format, Pool: Cardinal;
        IsTarget: Boolean;
        IsScreen: Boolean = False
    );
    destructor Destroy; override;
    function Storage: TSDLStorage;
    procedure Realize;
    procedure ReadPixels(Dest: Pointer; DestPitch: Integer; DestFormat: Cardinal);
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
    LinearFilter, Wireframe: Boolean;
    ScreenSurface: IDirect3DSurface9;
    Gamma: TD3DGammaRamp;
    GammaEnabled: Boolean;
    GammaPixels: array of Cardinal;
    GammaTexture: PSDL_Texture;
    TargetGeneration: LongInt;
    constructor Create(var Parameters: TD3DPresentParameters);
    destructor Destroy; override;
    function TestCooperativeLevel: LongInt; stdcall; override;
    function Reset(var Parameters): LongInt; stdcall; override;
    function GetBackBuffer(
        SwapChain, BackBuffer, BackBufferType: Cardinal;
        out Surface: IDirect3DSurface9
    ): LongInt; stdcall; override;
    function SetFVF(FVF: Cardinal): LongInt; stdcall; override;
    function SetVertexShader(Shader: IDirect3DVertexShader9): LongInt; stdcall; override;
    procedure SetGammaRamp(SwapChain, Flags: Cardinal; const Ramp); stdcall; override;
    function ColorFill(
        Surface: IDirect3DSurface9;
        Rect: PRect;
        Color: Cardinal
    ): LongInt; stdcall; override;
    function StretchRect(
        Source: IDirect3DSurface9;
        SourceRect: PRect;
        Dest: IDirect3DSurface9;
        DestRect: PRect;
        Filter: Cardinal
    ): LongInt; stdcall; override;
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

var
  RetiredTextures: TThreadList;

procedure CollectTextures;
var
  Items: TList;
  Index: Integer;
begin
  Items := RetiredTextures.LockList;
  try
    for Index := 0 to Items.Count - 1 do
      SDL_DestroyTexture(Items[Index]);
    Items.Clear;
  finally
    RetiredTextures.UnlockList;
  end;
end;

function PixelFormat(Format: Cardinal): Cardinal;
begin
  // XRGB's unused high byte must not become transparency (notably AVI frames).
  if Format = D3DFMT_R5G6B5 then
    Result := SDL_PIXELFORMAT_RGB565
  else if Format = D3DFMT_X8R8G8B8 then
    Result := SDL_PIXELFORMAT_XRGB8888
  else
    Result := SDL_PIXELFORMAT_ARGB8888;
end;

function ColorValue(Color: Cardinal): TSDL_Color;
begin
  Result.R := Color shr 16;
  Result.G := Color shr 8;
  Result.B := Color;
  Result.A := Color shr 24;
end;

function SDLRect(Rect: TRect): TSDL_Rect;
begin
  Result.X := Rect.Left;
  Result.Y := Rect.Top;
  Result.W := Rect.Right - Rect.Left;
  Result.H := Rect.Bottom - Rect.Top;
end;

procedure Check(Value: Integer);
begin
  if Value < 0 then
    raise Exception.Create('SDL renderer: ' + string(SDL_GetError));
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
  Require(
      Format in [D3DFMT_R5G6B5, D3DFMT_A8R8G8B8, D3DFMT_X8R8G8B8],
      'texture format ' + IntToStr(Format)
  );
  Desc.Width := W;
  Desc.Height := H;
  Desc.Format := Format;
  Desc.Pool := Pool;
  Desc.ResourceType := 1; // D3DRTYPE_SURFACE, including texture level descriptions.
  if Format = D3DFMT_R5G6B5 then
    Bpp := 2
  else
    Bpp := 4;
  Pitch := (W * Bpp + 3) and not 3;
  Pixels := AllocMem(SizeUInt(Pitch) * H);
  Screen := IsScreen;
  Target := IsTarget;
  Dirty := not Target;
end;
destructor TSDLStorage.Destroy;
begin
  // Cache eviction may run on a worker. SDL textures must be destroyed on
  // the renderer thread, even though their Pascal pixel storage can be freed here.
  if Handle <> nil then
    RetiredTextures.Add(Handle);
  FreeMem(Pixels);
  inherited Destroy;
end;
function TSDLStorage.Storage: TSDLStorage;
begin
  Result := Self
end;
procedure TSDLStorage.Realize;
var
  Access: Integer;
  CurrentGeneration: LongInt;
begin
  if Target then
    CurrentGeneration := GameTargetGeneration
  else
    CurrentGeneration := GameTextureGeneration;
  if (Handle <> nil) and (Generation <> CurrentGeneration) then
  begin
    SDL_DestroyTexture(Handle);
    Handle := nil;
    // Ordinary textures have authoritative CPU pixels. Render targets do not:
    // discard any old readback and let the game redraw their lost contents.
    if Target then
      FillChar(Pixels^, SizeUInt(Pitch) * Desc.Height, 0);
    Dirty := True;
  end;
  if Handle <> nil then
    Exit;
  Access := SDL_TEXTUREACCESS_STATIC;
  if Target then
    Access := SDL_TEXTUREACCESS_TARGET;
  TextureFormat := PixelFormat(Desc.Format);
  if Target then
    TextureFormat := SDL_PIXELFORMAT_ARGB8888;
  Handle := SDL_CreateTexture(GameSDLRenderer, TextureFormat, Access, Desc.Width, Desc.Height);
  Require(Handle <> nil, string(SDL_GetError));
  Generation := CurrentGeneration;
end;

procedure TSDLStorage.Upload;
var
  Converted: array of Cardinal;
begin
  Require(not Locked, 'drawing a locked texture');
  Realize;
  if Dirty then
  begin
    if PixelFormat(Desc.Format) = TextureFormat then
      Check(SDL_UpdateTexture(Handle, nil, Pixels, Pitch))
    else
    begin
      SetLength(Converted, SizeUInt(Desc.Width) * Desc.Height);
      Check(
          SDL_ConvertPixels(
              Desc.Width,
              Desc.Height,
              PixelFormat(Desc.Format),
              Pixels,
              Pitch,
              TextureFormat,
              @Converted[0],
              Desc.Width * 4
          )
      );
      Check(SDL_UpdateTexture(Handle, nil, @Converted[0], Desc.Width * 4));
    end;
    Dirty := False;
  end;
end;

procedure TSDLStorage.ReadPixels(Dest: Pointer; DestPitch: Integer; DestFormat: Cardinal);
var
  Previous: PSDL_Texture;
begin
  Realize;
  Previous := SDL_GetRenderTarget(GameSDLRenderer);
  Check(SDL_SetRenderTarget(GameSDLRenderer, Handle));
  try
    Check(SDL_RenderReadPixels(GameSDLRenderer, nil, PixelFormat(DestFormat), Dest, DestPitch));
  finally
    Check(SDL_SetRenderTarget(GameSDLRenderer, Previous));
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
    ReadPixels(Pixels, Pitch, Desc.Format);
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
constructor TSDLDevice.Create(var Parameters: TD3DPresentParameters);
begin
  inherited Create;
  Reset(Parameters);
  LinearFilter := True;
end;

destructor TSDLDevice.Destroy;
begin
  SDL_DestroyTexture(GammaTexture);
  CurrentTexture := nil;
  CurrentTarget := nil;
  ScreenSurface := nil;
  CollectTextures;
  inherited Destroy;
end;

function TSDLDevice.Reset(var Parameters): LongInt;
var
  Params: TD3DPresentParameters;
  WindowWidth, WindowHeight: Integer;
begin
  if GameSDLRenderer <> nil then
    TestCooperativeLevel;
  Move(Parameters, Params, SizeOf(Params));
  // Direct3D accepts zero back-buffer dimensions in windowed mode and takes
  // the client size. The game sets that size before creating/resetting the device.
  // A browser canvas follows CSS independently of the requested game size.
  if Params.Windowed and ((Params.BackBufferWidth = 0) or (Params.BackBufferHeight = 0)) then
  begin
    Require(GameSDLWindow <> nil, 'window for automatic back-buffer size');
    if GameWindowUsesCanvas then
      GetGameWindowLogicalSize(WindowWidth, WindowHeight)
    else
      SDL_GetWindowSize(GameSDLWindow, WindowWidth, WindowHeight);
    if Params.BackBufferWidth = 0 then
      Params.BackBufferWidth := WindowWidth;
    if Params.BackBufferHeight = 0 then
      Params.BackBufferHeight := WindowHeight;
  end;
  OpenGameWindow(
      Params.BackBufferWidth,
      Params.BackBufferHeight,
      Params.Windowed,
      Params.PresentationInterval <> D3DPRESENT_INTERVAL_IMMEDIATE
  );
  ScreenSurface :=
      TSDLSurface.Create(
          TSDLStorage.Create(
              Params.BackBufferWidth,
              Params.BackBufferHeight,
              D3DFMT_A8R8G8B8,
              D3DPOOL_DEFAULT,
              True,
              True
          )
      );
  Clip := Types.Rect(0, 0, Params.BackBufferWidth, Params.BackBufferHeight);
  SDL_DestroyTexture(GammaTexture);
  GammaTexture := nil;
  Result := SetRenderTarget(0, ScreenSurface);
  TargetGeneration := GameTargetGeneration;
  Move(Params, Parameters, SizeOf(Params));
end;

function TSDLDevice.TestCooperativeLevel: LongInt;
begin
  if TargetGeneration <> GameTargetGeneration then
  begin
    // SDL has already recreated its device. Rebind through Realize rather than
    // resetting the window again, which can itself trigger another SDL reset.
    Check(SDL_SetRenderTarget(GameSDLRenderer, nil));
    SDL_DestroyTexture(GammaTexture);
    GammaTexture := nil;
    if CurrentTarget <> nil then
      SetRenderTarget(0, CurrentTarget);
    TargetGeneration := GameTargetGeneration;
  end;
  Result := 0;
end;
function TSDLDevice.GetBackBuffer(
    SwapChain, BackBuffer, BackBufferType: Cardinal;
    out Surface: IDirect3DSurface9
): LongInt;
begin
  Surface := ScreenSurface;
  Result := 0;
end;
function TSDLDevice.SetFVF(FVF: Cardinal): LongInt;
begin
  Require(FVF = (D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1), 'vertex format');
  Result := 0;
end;
function TSDLDevice.SetVertexShader(Shader: IDirect3DVertexShader9): LongInt;
begin
  Require(Shader = nil, 'vertex shader');
  Result := 0;
end;
procedure TSDLDevice.SetGammaRamp(SwapChain, Flags: Cardinal; const Ramp);
var
  Index: Integer;
begin
  Move(Ramp, Gamma, SizeOf(Gamma));
  GammaEnabled := False;
  for Index := 0 to 255 do
    if (Gamma.Red[Index] <> Index * 257)
        or (Gamma.Green[Index] <> Index * 257)
        or (Gamma.Blue[Index] <> Index * 257) then
      GammaEnabled := True;
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
  TestCooperativeLevel;
  A := ImageOf(Source);
  B := ImageOf(Dest);
  Require(
      A.Target
          and not B.Target
          and (A.Desc.Width = B.Desc.Width)
          and (A.Desc.Height = B.Desc.Height),
      'readback dimensions'
  );
  A.ReadPixels(B.Pixels, B.Pitch, B.Desc.Format);
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
  A.Upload;
  Check(SDL_SetRenderTarget(GameSDLRenderer, A.Handle));
  Check(SDL_RenderSetLogicalSize(GameSDLRenderer, 0, 0));
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
  Result := TestCooperativeLevel;
end;
function TSDLDevice.EndScene: LongInt;
begin
  Result := 0
end;
{$IFDEF FPC_WASM_EMSCRIPTEN}
procedure BrowserWaitFrame; cdecl; external name 'fpc_browser_wait_frame';
procedure BrowserFramePresented; cdecl; external name 'fpc_browser_presented';
{$ENDIF}

function TSDLDevice.Present(
    SourceRect, DestRect: PRect;
    DestWindow: Cardinal;
    DirtyRegion: Pointer
): LongInt;
var
  Screen: TSDLStorage;
  Texture: PSDL_Texture;
  Index: SizeInt;
  Color: Cardinal;
  OutputWidth, OutputHeight, Filter: Integer;
  Scale: Double;
begin
  TestCooperativeLevel;
  Screen := ImageOf(ScreenSurface);
  Screen.Upload;
  Texture := Screen.Handle;
  if GammaEnabled then
  begin
    SetLength(GammaPixels, SizeUInt(Screen.Desc.Width) * Screen.Desc.Height);
    Screen.ReadPixels(@GammaPixels[0], Screen.Desc.Width * 4, D3DFMT_A8R8G8B8);
    for Index := 0 to High(GammaPixels) do
    begin
      Color := GammaPixels[Index];
      GammaPixels[Index] :=
          $FF000000
              or (Cardinal(Gamma.Red[(Color shr 16) and $FF] shr 8) shl 16)
              or (Cardinal(Gamma.Green[(Color shr 8) and $FF] shr 8) shl 8)
              or (Gamma.Blue[Color and $FF] shr 8);
    end;
    if GammaTexture = nil then
      GammaTexture :=
          SDL_CreateTexture(
              GameSDLRenderer,
              SDL_PIXELFORMAT_ARGB8888,
              SDL_TEXTUREACCESS_STREAMING,
              Screen.Desc.Width,
              Screen.Desc.Height
          );
    Require(GammaTexture <> nil, string(SDL_GetError));
    Check(SDL_UpdateTexture(GammaTexture, nil, @GammaPixels[0], Screen.Desc.Width * 4));
    Texture := GammaTexture;
  end;
  Check(SDL_SetRenderTarget(GameSDLRenderer, nil));
  // Use the same SDL logical view that transforms mouse events. Manual scaling
  // in physical pixels would give SDL2-compat's Retina events a different scale.
  Check(SDL_RenderSetLogicalSize(GameSDLRenderer, Screen.Desc.Width, Screen.Desc.Height));
  Check(SDL_RenderSetClipRect(GameSDLRenderer, nil));
  Check(SDL_SetRenderDrawColor(GameSDLRenderer, 0, 0, 0, 255));
  Check(SDL_RenderClear(GameSDLRenderer));
  Check(SDL_SetTextureBlendMode(Texture, SDL_BLENDMODE_NONE));
  // Sampling the final image is independent of the game's sprite filters.
  // Preserve exact pixel multiples; interpolate fractional scaling (including
  // downscaling) so adjacent source pixels do not acquire unequal screen sizes.
  Check(SDL_GetRendererOutputSize(GameSDLRenderer, OutputWidth, OutputHeight));
  Scale := Min(OutputWidth / Screen.Desc.Width, OutputHeight / Screen.Desc.Height);
  Filter := SDL_ScaleModeLinear;
  if (Scale >= 1) and (Scale = Trunc(Scale)) then
    Filter := SDL_ScaleModeNearest;
  Check(SDL_SetTextureScaleMode(Texture, Filter));
  Check(SDL_RenderCopy(GameSDLRenderer, Texture, nil, nil));
{$IFDEF FPC_WASM_EMSCRIPTEN}
  // Submit drawing before waiting; the browser presents the completed buffer
  // at its own refresh cadence, which need not be 60 Hz.
  Check(SDL_RenderFlush(GameSDLRenderer));
  BrowserWaitFrame;
{$ENDIF}
  SDL_RenderPresent(GameSDLRenderer);
  Inc(GamePresentedFrames);
{$IFDEF FPC_WASM_EMSCRIPTEN}
  BrowserFramePresented;
{$ENDIF}
  // A device reset may have happened in Present itself. Never rebind the old
  // target handle: D3D11 has already freed its backend storage at this point.
  TestCooperativeLevel;
  CollectTextures;
  Result := SetRenderTarget(0, CurrentTarget);
end;
function TSDLDevice.Clear(
    RectCount: Cardinal;
    Rects: PRect;
    Flags, Color: Cardinal;
    Z: Single;
    Stencil: Cardinal
): LongInt;
begin
  TestCooperativeLevel;
  Require((RectCount = 0) and (Flags = 1), 'partial/depth clear');
  Check(
      SDL_SetRenderDrawColor(
          GameSDLRenderer,
          Byte(Color shr 16),
          Byte(Color shr 8),
          Byte(Color),
          Byte(Color shr 24)
      )
  );
  Check(SDL_RenderClear(GameSDLRenderer));
  Result := 0
end;
function TSDLDevice.SetRenderState(State, Value: Cardinal): LongInt;
begin
  case State of
    8:
    begin
      Require(Value in [D3DFILL_WIREFRAME, D3DFILL_SOLID], 'fill mode');
      Wireframe := Value = D3DFILL_WIREFRAME
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
var
  Value: TSDL_Rect;
begin
  Require(Rect <> nil, 'nil scissor');
  Clip := Rect^;
  Value := SDLRect(Clip);
  Check(SDL_RenderSetClipRect(GameSDLRenderer, @Value));
  Result := 0;
end;
function TSDLDevice.GetScissorRect(out Rect: TRect): LongInt;
begin
  Rect := Clip;
  Result := 0
end;
function TSDLDevice.ColorFill(Surface: IDirect3DSurface9; Rect: PRect; Color: Cardinal): LongInt;
var
  Previous: IDirect3DSurface9;
  Value: TSDL_Rect;
begin
  Previous := CurrentTarget;
  SetRenderTarget(0, Surface);
  try
    Check(SDL_SetRenderDrawBlendMode(GameSDLRenderer, SDL_BLENDMODE_NONE));
    Check(
        SDL_SetRenderDrawColor(
            GameSDLRenderer,
            Byte(Color shr 16),
            Byte(Color shr 8),
            Byte(Color),
            Byte(Color shr 24)
        )
    );
    if Rect = nil then
      Check(SDL_RenderClear(GameSDLRenderer))
    else
    begin
      Value := SDLRect(Rect^);
      Check(SDL_RenderFillRect(GameSDLRenderer, @Value));
    end;
  finally
    SetRenderTarget(0, Previous);
  end;
  Result := 0;
end;

function TSDLDevice.StretchRect(
    Source: IDirect3DSurface9;
    SourceRect: PRect;
    Dest: IDirect3DSurface9;
    DestRect: PRect;
    Filter: Cardinal
): LongInt;
var
  Previous: IDirect3DSurface9;
  Image: TSDLStorage;
  A, B: TSDL_Rect;
  PA, PB: PSDL_Rect;
begin
  Image := ImageOf(Source);
  Image.Upload;
  Previous := CurrentTarget;
  SetRenderTarget(0, Dest);
  try
    PA := nil;
    PB := nil;
    if SourceRect <> nil then
    begin
      A := SDLRect(SourceRect^);
      PA := @A;
    end;
    if DestRect <> nil then
    begin
      B := SDLRect(DestRect^);
      PB := @B;
    end;
    Check(SDL_SetTextureBlendMode(Image.Handle, SDL_BLENDMODE_NONE));
    Check(SDL_SetTextureScaleMode(Image.Handle, Ord(Filter = D3DTEXF_LINEAR)));
    Check(SDL_RenderSetClipRect(GameSDLRenderer, nil));
    Check(SDL_RenderCopy(GameSDLRenderer, Image.Handle, PA, PB));
  finally
    SetRenderTarget(0, Previous);
    SetScissorRect(@Clip);
  end;
  Result := 0;
end;

function TSDLDevice.DrawPrimitiveUP(
    PrimitiveType, PrimitiveCount: Cardinal;
    Data: Pointer;
    Stride: Cardinal
): LongInt;
type
  TGameVertex = packed record
    X, Y, Z, RHW: Single;
    Color: Cardinal;
    U, V: Single;
  end;
  PGameVertex = ^TGameVertex;
var
  Image: TSDLStorage;
  Texture: PSDL_Texture;
  Vertices: array of TSDL_Vertex;
  Indices: array of Integer;
  Count, Index, A, B, C: Integer;
  Source: PGameVertex;
  Value: TSDL_Rect;
  Color: TSDL_Color;

  procedure DrawEdge(First, Last: Integer);
  const
    Order: array[0..5] of Integer = (0, 1, 2, 0, 2, 3);
  var
    Line: array[0..3] of TSDL_Vertex;
    DX, DY, Distance, NX, NY: Single;
  begin
    Color := Vertices[First].Color;
    DX := Vertices[Last].Position.X - Vertices[First].Position.X;
    DY := Vertices[Last].Position.Y - Vertices[First].Position.Y;
    Distance := Sqrt(DX * DX + DY * DY);
    if CompareMem(@Color, @Vertices[Last].Color, SizeOf(Color)) or (Distance = 0) then
    begin
      Check(SDL_SetRenderDrawColor(GameSDLRenderer, Color.R, Color.G, Color.B, Color.A));
      Check(
          SDL_RenderDrawLineF(
              GameSDLRenderer,
              Vertices[First].Position.X,
              Vertices[First].Position.Y,
              Vertices[Last].Position.X,
              Vertices[Last].Position.Y
          )
      );
      Exit;
    end;
    // SDL's line primitive has one color. A one-pixel strip retains the game's
    // interpolated endpoint colors and alpha, including wireframe triangle edges.
    NX := -DY * 0.5 / Distance;
    NY := DX * 0.5 / Distance;
    Line[0] := Vertices[First];
    Line[1] := Vertices[Last];
    Line[2] := Vertices[Last];
    Line[3] := Vertices[First];
    Line[0].Position.X := Line[0].Position.X + NX;
    Line[0].Position.Y := Line[0].Position.Y + NY;
    Line[1].Position.X := Line[1].Position.X + NX;
    Line[1].Position.Y := Line[1].Position.Y + NY;
    Line[2].Position.X := Line[2].Position.X - NX;
    Line[2].Position.Y := Line[2].Position.Y - NY;
    Line[3].Position.X := Line[3].Position.X - NX;
    Line[3].Position.Y := Line[3].Position.Y - NY;
    Check(SDL_RenderGeometry(GameSDLRenderer, nil, @Line, Length(Line), @Order, Length(Order)));
  end;

begin
  TestCooperativeLevel;
  Require(Stride >= SizeOf(TGameVertex), 'vertex stride');
  if PrimitiveCount = 0 then
    Exit(0);
  case PrimitiveType of
    D3DPT_POINTLIST: Count := PrimitiveCount;
    D3DPT_LINESTRIP: Count := PrimitiveCount + 1;
    D3DPT_TRIANGLELIST: Count := PrimitiveCount * 3;
    D3DPT_TRIANGLEFAN: Count := PrimitiveCount + 2;
  else
    raise Exception.Create('Unsupported primitive type');
  end;
  SetLength(Vertices, Count);
  for Index := 0 to Count - 1 do
  begin
    Source := PGameVertex(PByte(Data) + SizeUInt(Index) * Stride);
    // D3D9 addresses pixel centers at integers; SDL uses half-integers.
    Vertices[Index].Position.X := Source.X + 0.5;
    Vertices[Index].Position.Y := Source.Y + 0.5;
    Vertices[Index].Color := ColorValue(Source.Color);
    Vertices[Index].TexCoord.X := Source.U;
    Vertices[Index].TexCoord.Y := Source.V;
  end;
  Texture := nil;
  if CurrentTexture <> nil then
  begin
    Image := ImageOf(CurrentTexture);
    Image.Upload;
    Texture := Image.Handle;
    Check(SDL_SetTextureBlendMode(Texture, SDL_BLENDMODE_BLEND));
    Check(SDL_SetTextureScaleMode(Texture, Ord(LinearFilter)));
  end;
  Value := SDLRect(Clip);
  Check(SDL_RenderSetClipRect(GameSDLRenderer, @Value));
  Check(SDL_SetRenderDrawBlendMode(GameSDLRenderer, SDL_BLENDMODE_BLEND));
  if PrimitiveType = D3DPT_POINTLIST then
    for Index := 0 to Count - 1 do
    begin
      Color := Vertices[Index].Color;
      Check(SDL_SetRenderDrawColor(GameSDLRenderer, Color.R, Color.G, Color.B, Color.A));
      Check(
          SDL_RenderDrawPointF(
              GameSDLRenderer,
              Vertices[Index].Position.X,
              Vertices[Index].Position.Y
          )
      );
    end
  else if PrimitiveType = D3DPT_LINESTRIP then
    for Index := 0 to Count - 2 do
      DrawEdge(Index, Index + 1)
  else
  begin
    SetLength(Indices, PrimitiveCount * 3);
    for Index := 0 to Integer(PrimitiveCount) - 1 do
    begin
      if PrimitiveType = D3DPT_TRIANGLEFAN then
      begin
        A := 0;
        B := Index + 1;
        C := Index + 2;
      end
      else
      begin
        A := Index * 3;
        B := A + 1;
        C := A + 2;
      end;
      Indices[Index * 3] := A;
      Indices[Index * 3 + 1] := B;
      Indices[Index * 3 + 2] := C;
      if Wireframe then
      begin
        DrawEdge(A, B);
        DrawEdge(B, C);
        DrawEdge(C, A);
      end;
    end;
    if not Wireframe then
      Check(
          SDL_RenderGeometry(
              GameSDLRenderer,
              Texture,
              @Vertices[0],
              Count,
              @Indices[0],
              Length(Indices)
          )
      );
  end;
  Result := 0;
end;

type
  TSDLGraphics = class(TInterfacedObject, IDirect3D9)
  private
    CanvasModes: array of TSDL_DisplayMode;
    procedure BuildCanvasModes;
    function DesktopMode(out Value: TSDL_DisplayMode): Integer;
  public
    function RegisterSoftwareDevice(InitializeFunction: Pointer): LongInt; stdcall;
    function GetAdapterCount: Cardinal; stdcall;
    function GetAdapterIdentifier(
        Adapter: Cardinal;
        Flags: Cardinal;
        out Identifier: TD3DAdapterIdentifier9
    ): LongInt; stdcall;
    function GetAdapterModeCount(Adapter: Cardinal; Format: Cardinal): Cardinal; stdcall;
    function EnumAdapterModes(
        Adapter: Cardinal;
        Format: Cardinal;
        Mode: Cardinal;
        out DisplayMode
    ): LongInt; stdcall;
    function GetAdapterDisplayMode(Adapter: Cardinal; out DisplayMode): LongInt; stdcall;
    function CheckDeviceType(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        DisplayFormat: Cardinal;
        BackBufferFormat: Cardinal;
        Windowed: LongBool
    ): LongInt; stdcall;
    function CheckDeviceFormat(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        AdapterFormat: Cardinal;
        Usage: Cardinal;
        ResourceType: Cardinal;
        CheckFormat: Cardinal
    ): LongInt; stdcall;
    function CheckDeviceMultiSampleType(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        Format: Cardinal;
        Windowed: LongBool;
        MultiSample: Cardinal;
        QualityLevels: PCardinal
    ): LongInt; stdcall;
    function CheckDepthStencilMatch(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        AdapterFormat: Cardinal;
        RenderTargetFormat: Cardinal;
        DepthStencilFormat: Cardinal
    ): LongInt; stdcall;
    function CheckDeviceFormatConversion(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        SourceFormat: Cardinal;
        TargetFormat: Cardinal
    ): LongInt; stdcall;
    function GetDeviceCaps(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        out Caps: TD3DCaps9
    ): LongInt; stdcall;
    function GetAdapterMonitor(Adapter: Cardinal): Cardinal; stdcall;
    function CreateDevice(
        Adapter: Cardinal;
        DeviceType: Cardinal;
        FocusWindow: Cardinal;
        BehaviorFlags: Cardinal;
        var Parameters: TD3DPresentParameters;
        out Device: IDirect3DDevice9
    ): LongInt; stdcall;
  end;

function TSDLGraphics.RegisterSoftwareDevice(InitializeFunction: Pointer): LongInt;
begin
  Result := -2147467263;
end;
function TSDLGraphics.GetAdapterCount: Cardinal;
begin
  Result := 1;
end;
function TSDLGraphics.GetAdapterIdentifier(
    Adapter, Flags: Cardinal;
    out Identifier: TD3DAdapterIdentifier9
): LongInt;
begin
  FillChar(Identifier, SizeOf(Identifier), 0);
  StrPCopy(PAnsiChar(@Identifier.Description), 'SDL2 renderer');
  StrPCopy(PAnsiChar(@Identifier.Driver), 'SDL2');
  Result := 0;
end;
function TSDLGraphics.DesktopMode(out Value: TSDL_DisplayMode): Integer;
var
  Bounds: TSDL_Rect;
  Caps: TD3DCaps9;
  MaxWidth, MaxHeight: Integer;
  Scale: Double;
begin
  Result := SDL_GetCurrentDisplayMode(0, Value);
  if not GameWindowUsesCanvas then
    Exit;
  // Browser display modes describe the whole screen in CSS pixels. Auto must
  // fit the actual viewport; multiplying it by Retina density shrinks the UI.
  if SDL_GetDisplayUsableBounds(0, Bounds) = 0 then
    if (Bounds.W > 0) and (Bounds.H > 0) then
    begin
      Value := Default(TSDL_DisplayMode);
      GetDeviceCaps(0, D3DDEVTYPE_HAL, Caps);
      MaxWidth := Min(7680, Caps.MaxTextureWidth);
      MaxHeight := Min(4320, Caps.MaxTextureHeight);
      Scale := Max(1.0, Max(1024.0 / Bounds.W, 720.0 / Bounds.H));
      Scale := Min(Scale, Min(MaxWidth / Bounds.W, MaxHeight / Bounds.H));
      // Preserve aspect unless an extreme viewport cannot satisfy both the
      // game's minimum layout size and the renderer's maximum dimensions.
      Value.W := EnsureRange(Round(Bounds.W * Scale), Min(1024, MaxWidth), MaxWidth);
      Value.H := EnsureRange(Round(Bounds.H * Scale), Min(720, MaxHeight), MaxHeight);
      Result := 0;
    end;
end;

procedure TSDLGraphics.BuildCanvasModes;
const
  Presets: array[0..13] of TPoint = (
      (X: 1024; Y: 768),
      (X: 1280; Y: 720),
      (X: 1280; Y: 800),
      (X: 1366; Y: 768),
      (X: 1440; Y: 900),
      (X: 1600; Y: 900),
      (X: 1680; Y: 1050),
      (X: 1920; Y: 1080),
      (X: 1920; Y: 1200),
      (X: 2048; Y: 1152),
      (X: 2560; Y: 1440),
      (X: 2560; Y: 1600),
      (X: 2880; Y: 1800),
      (X: 3840; Y: 2160)
  );
var
  Mode, Swap: TSDL_DisplayMode;
  Caps: TD3DCaps9;
  Bounds: TSDL_Rect;
  DPI: Single;
  Density: Double;
  W, H, I, J: Integer;

  procedure Add(Width, Height: Integer);
  var
    Index: Integer;
  begin
    if (Width < 1024)
        or (Height < 720)
        or (Width > 7680)
        or (Height > 4320)
        or (Cardinal(Width) > Caps.MaxTextureWidth)
        or (Cardinal(Height) > Caps.MaxTextureHeight) then
      Exit;
    for Index := 0 to High(CanvasModes) do
      if (CanvasModes[Index].W = Width) and (CanvasModes[Index].H = Height) then
        Exit;
    Index := Length(CanvasModes);
    SetLength(CanvasModes, Index + 1);
    CanvasModes[Index].W := Width;
    CanvasModes[Index].H := Height;
  end;

begin
  // These are render resolutions, not hardware display-switch requests. SDL's
  // browser driver exposes only one screen mode, although any canvas size works.
  CanvasModes := nil;
  GetDeviceCaps(0, D3DDEVTYPE_HAL, Caps);
  for I := 0 to High(Presets) do
    Add(Presets[I].X, Presets[I].Y);
  if DesktopMode(Mode) = 0 then
    Add(Mode.W, Mode.H);
  Density := 1;
  if SDL_GetDisplayDPI(0, @DPI, nil, nil) = 0 then
    // The browser SDL driver reports 96 DPI times devicePixelRatio.
    if (DPI > 0) and not IsNan(DPI) and not IsInfinite(DPI) then
      Density := DPI / 96.0;
  if SDL_GetDisplayUsableBounds(0, Bounds) = 0 then
  begin
    Add(Bounds.W, Bounds.H);
    Add(Round(Bounds.W * Density), Round(Bounds.H * Density));
  end;
  if SDL_GetCurrentDisplayMode(0, Mode) = 0 then
  begin
    Add(Mode.W, Mode.H);
    Add(Round(Mode.W * Density), Round(Mode.H * Density));
  end;
  if GameSDLWindow <> nil then
  begin
    // Renderer output size may describe a bound offscreen texture instead.
    SDL_GetWindowSizeInPixels(GameSDLWindow, W, H);
    Add(W, H);
  end;
  // Keep this snapshot stable while the game enumerates its indexed choices.
  for I := 1 to High(CanvasModes) do
  begin
    J := I;
    while (J > 0)
        and ((CanvasModes[J].W < CanvasModes[J - 1].W)
            or ((CanvasModes[J].W = CanvasModes[J - 1].W)
                and (CanvasModes[J].H < CanvasModes[J - 1].H))) do
    begin
      Swap := CanvasModes[J];
      CanvasModes[J] := CanvasModes[J - 1];
      CanvasModes[J - 1] := Swap;
      Dec(J);
    end;
  end;
end;

function TSDLGraphics.GetAdapterModeCount(Adapter, Format: Cardinal): Cardinal;
begin
  if GameWindowUsesCanvas then
  begin
    BuildCanvasModes;
    Exit(Length(CanvasModes));
  end;
  Result := Max(0, SDL_GetNumDisplayModes(0));
end;
function TSDLGraphics.EnumAdapterModes(Adapter, Format, Mode: Cardinal; out DisplayMode): LongInt;
var
  Value: TSDL_DisplayMode;
  Data: array[0..3] of Cardinal;
begin
  if GameWindowUsesCanvas then
  begin
    if Mode >= Cardinal(Length(CanvasModes)) then
      Exit(-1);
    Value := CanvasModes[Mode];
    Result := 0;
  end
  else
    Result := SDL_GetDisplayMode(0, Mode, Value);
  if Result = 0 then
  begin
    Data[0] := Value.W;
    Data[1] := Value.H;
    Data[2] := Value.RefreshRate;
    Data[3] := D3DFMT_X8R8G8B8;
    Move(Data, DisplayMode, SizeOf(Data));
  end;
end;
function TSDLGraphics.GetAdapterDisplayMode(Adapter: Cardinal; out DisplayMode): LongInt;
var
  Value: TSDL_DisplayMode;
  Data: array[0..3] of Cardinal;
begin
  Result := DesktopMode(Value);
  if Result = 0 then
  begin
    Data[0] := Value.W;
    Data[1] := Value.H;
    Data[2] := Value.RefreshRate;
    Data[3] := D3DFMT_X8R8G8B8;
    Move(Data, DisplayMode, SizeOf(Data));
  end;
end;
function TSDLGraphics.CheckDeviceType(
    Adapter, DeviceType, DisplayFormat, BackBufferFormat: Cardinal;
    Windowed: LongBool
): LongInt;
begin
  Result := 0;
end;
function TSDLGraphics.CheckDeviceFormat(
    Adapter,
    DeviceType,
    AdapterFormat,
    Usage,
    ResourceType,
    CheckFormat: Cardinal
): LongInt;
begin
  if CheckFormat in [D3DFMT_A8R8G8B8, D3DFMT_X8R8G8B8, D3DFMT_R5G6B5] then
    Result := 0
  else
    Result := -2147467263;
end;
function TSDLGraphics.CheckDeviceMultiSampleType(
    Adapter, DeviceType, Format: Cardinal;
    Windowed: LongBool;
    MultiSample: Cardinal;
    QualityLevels: PCardinal
): LongInt;
begin
  if QualityLevels <> nil then
    QualityLevels^ := 0;
  if MultiSample = 0 then
    Result := 0
  else
    Result := -2147467263;
end;
function TSDLGraphics.CheckDepthStencilMatch(
    Adapter,
    DeviceType,
    AdapterFormat,
    RenderTargetFormat,
    DepthStencilFormat: Cardinal
): LongInt;
begin
  Result := -2147467263;
end;
function TSDLGraphics.CheckDeviceFormatConversion(
    Adapter,
    DeviceType,
    SourceFormat,
    TargetFormat: Cardinal
): LongInt;
begin
  Result := 0;
end;
function TSDLGraphics.GetDeviceCaps(Adapter, DeviceType: Cardinal; out Caps: TD3DCaps9): LongInt;
var
  Info: TSDL_RendererInfo;
  Index: Integer;
begin
  FillChar(Caps, SizeOf(Caps), 0);
  Info := Default(TSDL_RendererInfo);
  if GameSDLRenderer <> nil then
    SDL_GetRendererInfo(GameSDLRenderer, Info)
  else
    // Caps are queried before device creation. Use the first target-capable
    // accelerated driver, matching OpenGameWindow's renderer preference.
    for Index := 0 to SDL_GetNumRenderDrivers - 1 do
      if SDL_GetRenderDriverInfo(Index, Info) = 0 then
        if Info.Flags and (SDL_RENDERER_ACCELERATED or SDL_RENDERER_TARGETTEXTURE)
            = (SDL_RENDERER_ACCELERATED or SDL_RENDERER_TARGETTEXTURE) then
          Break;
  // A zero maximum means the driver does not impose/report a fixed limit.
  Caps.MaxTextureWidth := Info.MaxTextureWidth;
  Caps.MaxTextureHeight := Info.MaxTextureHeight;
  if Caps.MaxTextureWidth = 0 then
    Caps.MaxTextureWidth := 16384;
  if Caps.MaxTextureHeight = 0 then
    Caps.MaxTextureHeight := 16384;
  Caps.MaxTextureAspectRatio := Max(Caps.MaxTextureWidth, Caps.MaxTextureHeight);
  Caps.MaxAnisotropy := 1;
  Result := 0;
end;
function TSDLGraphics.GetAdapterMonitor(Adapter: Cardinal): Cardinal;
begin
  Result := 0;
end;
function TSDLGraphics.CreateDevice(
    Adapter, DeviceType, FocusWindow, BehaviorFlags: Cardinal;
    var Parameters: TD3DPresentParameters;
    out Device: IDirect3DDevice9
): LongInt;
begin
  Device := TSDLDevice.Create(Parameters);
  Result := 0;
end;
function CreateGameGraphics: IDirect3D9;
begin
  InitializeGameVideo;
  Result := TSDLGraphics.Create;
end;

initialization
  RetiredTextures := TThreadList.Create;
finalization
  CollectTextures;
  RetiredTextures.Free;
end.
