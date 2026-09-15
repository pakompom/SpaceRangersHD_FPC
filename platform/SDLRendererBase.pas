unit SDLRendererBase;
{$MODE delphi}
{$EXCESSPRECISION OFF}
// Host adapter base. Unimplemented D3D operations fail explicitly; no native ABI changes.
interface
uses
  Direct3D9,
  Types,
  SysUtils;
type
  TSDLDeviceBase = class(TInterfacedObject, IDirect3DDevice9)
  public
    function TestCooperativeLevel: LongInt; stdcall; virtual;
    function GetAvailableTextureMem: Cardinal; stdcall; virtual;
    function EvictManagedResources: LongInt; stdcall; virtual;
    function GetDirect3D(out Direct3D: IDirect3D9): LongInt; stdcall; virtual;
    function GetDeviceCaps(out Caps: TD3DCaps9): LongInt; stdcall; virtual;
    function GetDisplayMode(SwapChain: Cardinal; out Mode): LongInt; stdcall; virtual;
    function GetCreationParameters(out Parameters): LongInt; stdcall; virtual;
    function SetCursorProperties(
        XHotSpot: Cardinal;
        YHotSpot: Cardinal;
        CursorBitmap: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    procedure SetCursorPosition(X: Integer; Y: Integer; Flags: Cardinal); stdcall; virtual;
    function ShowCursor(Show: LongBool): LongBool; stdcall; virtual;
    function CreateAdditionalSwapChain(
        var Parameters;
        out SwapChain: IDirect3DSwapChain9
    ): LongInt; stdcall; virtual;
    function GetSwapChain(
        Index: Cardinal;
        out SwapChain: IDirect3DSwapChain9
    ): LongInt; stdcall; virtual;
    function GetNumberOfSwapChains: Cardinal; stdcall; virtual;
    function Reset(var Parameters): LongInt; stdcall; virtual;
    function Present(
        SourceRect: PRect;
        DestRect: PRect;
        DestWindow: Cardinal;
        DirtyRegion: Pointer
    ): LongInt; stdcall; virtual;
    function GetBackBuffer(
        SwapChain: Cardinal;
        BackBuffer: Cardinal;
        BackBufferType: Cardinal;
        out Surface: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    function GetRasterStatus(SwapChain: Cardinal; out Status): LongInt; stdcall; virtual;
    function SetDialogBoxMode(Enable: LongBool): LongInt; stdcall; virtual;
    procedure SetGammaRamp(SwapChain: Cardinal; Flags: Cardinal; const Ramp); stdcall; virtual;
    procedure GetGammaRamp(SwapChain: Cardinal; out Ramp); stdcall; virtual;
    function CreateTexture(
        Width: Cardinal;
        Height: Cardinal;
        Levels: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Texture: IDirect3DTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateVolumeTexture(
        Width: Cardinal;
        Height: Cardinal;
        Depth: Cardinal;
        Levels: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Texture: IDirect3DVolumeTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateCubeTexture(
        EdgeLength: Cardinal;
        Levels: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Texture: IDirect3DCubeTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateVertexBuffer(
        Length: Cardinal;
        Usage: Cardinal;
        FVF: Cardinal;
        Pool: Cardinal;
        out Buffer: IDirect3DVertexBuffer9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateIndexBuffer(
        Length: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Buffer: IDirect3DIndexBuffer9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateRenderTarget(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        MultiSample: Cardinal;
        MultiSampleQuality: Cardinal;
        Lockable: LongBool;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function CreateDepthStencilSurface(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        MultiSample: Cardinal;
        MultiSampleQuality: Cardinal;
        Discard: LongBool;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function UpdateSurface(
        Source: IDirect3DSurface9;
        SourceRect: PRect;
        Dest: IDirect3DSurface9;
        DestPoint: PPoint
    ): LongInt; stdcall; virtual;
    function UpdateTexture(
        Source: IDirect3DBaseTexture9;
        Dest: IDirect3DBaseTexture9
    ): LongInt; stdcall; virtual;
    function GetRenderTargetData(
        Source: IDirect3DSurface9;
        Dest: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    function GetFrontBufferData(
        SwapChain: Cardinal;
        Dest: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    function StretchRect(
        Source: IDirect3DSurface9;
        SourceRect: PRect;
        Dest: IDirect3DSurface9;
        DestRect: PRect;
        Filter: Cardinal
    ): LongInt; stdcall; virtual;
    function ColorFill(
        Surface: IDirect3DSurface9;
        Rect: PRect;
        Color: Cardinal
    ): LongInt; stdcall; virtual;
    function CreateOffscreenPlainSurface(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall; virtual;
    function SetRenderTarget(
        Index: Cardinal;
        Surface: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    function GetRenderTarget(
        Index: Cardinal;
        out Surface: IDirect3DSurface9
    ): LongInt; stdcall; virtual;
    function SetDepthStencilSurface(Surface: IDirect3DSurface9): LongInt; stdcall; virtual;
    function GetDepthStencilSurface(out Surface: IDirect3DSurface9): LongInt; stdcall; virtual;
    function BeginScene: LongInt; stdcall; virtual;
    function EndScene: LongInt; stdcall; virtual;
    function Clear(
        RectCount: Cardinal;
        Rects: PRect;
        Flags: Cardinal;
        Color: Cardinal;
        Z: Single;
        Stencil: Cardinal
    ): LongInt; stdcall; virtual;
    function SetTransform(State: Cardinal; const Matrix): LongInt; stdcall; virtual;
    function GetTransform(State: Cardinal; out Matrix): LongInt; stdcall; virtual;
    function MultiplyTransform(State: Cardinal; const Matrix): LongInt; stdcall; virtual;
    function SetViewport(const Viewport): LongInt; stdcall; virtual;
    function GetViewport(out Viewport): LongInt; stdcall; virtual;
    function SetMaterial(const Material): LongInt; stdcall; virtual;
    function GetMaterial(out Material): LongInt; stdcall; virtual;
    function SetLight(Index: Cardinal; const Light): LongInt; stdcall; virtual;
    function GetLight(Index: Cardinal; out Light): LongInt; stdcall; virtual;
    function LightEnable(Index: Cardinal; Enable: LongBool): LongInt; stdcall; virtual;
    function GetLightEnable(Index: Cardinal; out Enable: LongBool): LongInt; stdcall; virtual;
    function SetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall; virtual;
    function GetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall; virtual;
    function SetRenderState(State: Cardinal; Value: Cardinal): LongInt; stdcall; virtual;
    function GetRenderState(State: Cardinal; out Value: Cardinal): LongInt; stdcall; virtual;
    function CreateStateBlock(
        BlockType: Cardinal;
        out StateBlock: IDirect3DStateBlock9
    ): LongInt; stdcall; virtual;
    function BeginStateBlock: LongInt; stdcall; virtual;
    function EndStateBlock(out StateBlock: IDirect3DStateBlock9): LongInt; stdcall; virtual;
    function SetClipStatus(const Status): LongInt; stdcall; virtual;
    function GetClipStatus(out Status): LongInt; stdcall; virtual;
    function GetTexture(
        Stage: Cardinal;
        out Texture: IDirect3DBaseTexture9
    ): LongInt; stdcall; virtual;
    function SetTexture(Stage: Cardinal; Texture: IDirect3DBaseTexture9): LongInt; stdcall; virtual;
    function GetTextureStageState(
        Stage: Cardinal;
        State: Cardinal;
        out Value: Cardinal
    ): LongInt; stdcall; virtual;
    function SetTextureStageState(
        Stage: Cardinal;
        State: Cardinal;
        Value: Cardinal
    ): LongInt; stdcall; virtual;
    function GetSamplerState(
        Sampler: Cardinal;
        State: Cardinal;
        out Value: Cardinal
    ): LongInt; stdcall; virtual;
    function SetSamplerState(
        Sampler: Cardinal;
        State: Cardinal;
        Value: Cardinal
    ): LongInt; stdcall; virtual;
    function ValidateDevice(out PassCount: Cardinal): LongInt; stdcall; virtual;
    function SetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall; virtual;
    function GetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall; virtual;
    function SetCurrentTexturePalette(Palette: Cardinal): LongInt; stdcall; virtual;
    function GetCurrentTexturePalette(out Palette: Cardinal): LongInt; stdcall; virtual;
    function SetScissorRect(Rect: PRect): LongInt; stdcall; virtual;
    function GetScissorRect(out Rect: TRect): LongInt; stdcall; virtual;
    function SetSoftwareVertexProcessing(Software: LongBool): LongInt; stdcall; virtual;
    function GetSoftwareVertexProcessing: LongBool; stdcall; virtual;
    function SetNPatchMode(Segments: Single): LongInt; stdcall; virtual;
    function GetNPatchMode: Single; stdcall; virtual;
    function DrawPrimitive(
        PrimitiveType: Cardinal;
        StartVertex: Cardinal;
        PrimitiveCount: Cardinal
    ): LongInt; stdcall; virtual;
    function DrawIndexedPrimitive(
        PrimitiveType: Cardinal;
        BaseVertexIndex: Integer;
        MinVertexIndex: Cardinal;
        VertexCount: Cardinal;
        StartIndex: Cardinal;
        PrimitiveCount: Cardinal
    ): LongInt; stdcall; virtual;
    function DrawPrimitiveUP(
        PrimitiveType: Cardinal;
        PrimitiveCount: Cardinal;
        Data: Pointer;
        Stride: Cardinal
    ): LongInt; stdcall; virtual;
    function DrawIndexedPrimitiveUP(
        PrimitiveType: Cardinal;
        MinVertexIndex: Cardinal;
        VertexCount: Cardinal;
        PrimitiveCount: Cardinal;
        IndexData: Pointer;
        IndexFormat: Cardinal;
        Data: Pointer;
        Stride: Cardinal
    ): LongInt; stdcall; virtual;
    function ProcessVertices(
        SourceStartIndex: Cardinal;
        DestIndex: Cardinal;
        VertexCount: Cardinal;
        DestBuffer: IDirect3DVertexBuffer9;
        Declaration: IDirect3DVertexDeclaration9;
        Flags: Cardinal
    ): LongInt; stdcall; virtual;
    function CreateVertexDeclaration(
        Elements: Pointer;
        out Declaration: IDirect3DVertexDeclaration9
    ): LongInt; stdcall; virtual;
    function SetVertexDeclaration(
        Declaration: IDirect3DVertexDeclaration9
    ): LongInt; stdcall; virtual;
    function GetVertexDeclaration(
        out Declaration: IDirect3DVertexDeclaration9
    ): LongInt; stdcall; virtual;
    function SetFVF(FVF: Cardinal): LongInt; stdcall; virtual;
    function GetFVF(out FVF: Cardinal): LongInt; stdcall; virtual;
    function CreateVertexShader(
        ByteCode: PCardinal;
        out Shader: IDirect3DVertexShader9
    ): LongInt; stdcall; virtual;
    function SetVertexShader(Shader: IDirect3DVertexShader9): LongInt; stdcall; virtual;
  end;
  TSDLResourceBase = class(TInterfacedObject, IDirect3DResource9)
  public
    function GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall; virtual;
    function SetPrivateData(
        const Guid: TGUID;
        Data: Pointer;
        DataSize: Cardinal;
        Flags: Cardinal
    ): LongInt; stdcall; virtual;
    function GetPrivateData(
        const Guid: TGUID;
        Data: Pointer;
        var DataSize: Cardinal
    ): LongInt; stdcall; virtual;
    function FreePrivateData(const Guid: TGUID): LongInt; stdcall; virtual;
    function SetPriority(NewPriority: Cardinal): Cardinal; stdcall; virtual;
    function GetPriority: Cardinal; stdcall; virtual;
    procedure PreLoad; stdcall; virtual;
    function GetType: Cardinal; stdcall; virtual;
  end;
implementation
function TSDLDeviceBase.TestCooperativeLevel: LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.TestCooperativeLevel');
end;

function TSDLDeviceBase.GetAvailableTextureMem: Cardinal; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetAvailableTextureMem');
end;

function TSDLDeviceBase.EvictManagedResources: LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.EvictManagedResources');
end;

function TSDLDeviceBase.GetDirect3D(out Direct3D: IDirect3D9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetDirect3D');
end;

function TSDLDeviceBase.GetDeviceCaps(out Caps: TD3DCaps9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetDeviceCaps');
end;

function TSDLDeviceBase.GetDisplayMode(SwapChain: Cardinal; out Mode): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetDisplayMode');
end;

function TSDLDeviceBase.GetCreationParameters(out Parameters): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetCreationParameters');
end;

function TSDLDeviceBase.SetCursorProperties(
    XHotSpot: Cardinal;
    YHotSpot: Cardinal;
    CursorBitmap: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetCursorProperties');
end;

procedure TSDLDeviceBase.SetCursorPosition(X: Integer; Y: Integer; Flags: Cardinal); stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetCursorPosition');
end;

function TSDLDeviceBase.ShowCursor(Show: LongBool): LongBool; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.ShowCursor');
end;

function TSDLDeviceBase.CreateAdditionalSwapChain(
    var Parameters;
    out SwapChain: IDirect3DSwapChain9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateAdditionalSwapChain');
end;

function TSDLDeviceBase.GetSwapChain(
    Index: Cardinal;
    out SwapChain: IDirect3DSwapChain9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetSwapChain');
end;

function TSDLDeviceBase.GetNumberOfSwapChains: Cardinal; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetNumberOfSwapChains');
end;

function TSDLDeviceBase.Reset(var Parameters): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.Reset');
end;

function TSDLDeviceBase.Present(
    SourceRect: PRect;
    DestRect: PRect;
    DestWindow: Cardinal;
    DirtyRegion: Pointer
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.Present');
end;

function TSDLDeviceBase.GetBackBuffer(
    SwapChain: Cardinal;
    BackBuffer: Cardinal;
    BackBufferType: Cardinal;
    out Surface: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetBackBuffer');
end;

function TSDLDeviceBase.GetRasterStatus(SwapChain: Cardinal; out Status): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetRasterStatus');
end;

function TSDLDeviceBase.SetDialogBoxMode(Enable: LongBool): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetDialogBoxMode');
end;

procedure TSDLDeviceBase.SetGammaRamp(SwapChain: Cardinal; Flags: Cardinal; const Ramp); stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetGammaRamp');
end;

procedure TSDLDeviceBase.GetGammaRamp(SwapChain: Cardinal; out Ramp); stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetGammaRamp');
end;

function TSDLDeviceBase.CreateTexture(
    Width: Cardinal;
    Height: Cardinal;
    Levels: Cardinal;
    Usage: Cardinal;
    Format: Cardinal;
    Pool: Cardinal;
    out Texture: IDirect3DTexture9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateTexture');
end;

function TSDLDeviceBase.CreateVolumeTexture(
    Width: Cardinal;
    Height: Cardinal;
    Depth: Cardinal;
    Levels: Cardinal;
    Usage: Cardinal;
    Format: Cardinal;
    Pool: Cardinal;
    out Texture: IDirect3DVolumeTexture9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateVolumeTexture');
end;

function TSDLDeviceBase.CreateCubeTexture(
    EdgeLength: Cardinal;
    Levels: Cardinal;
    Usage: Cardinal;
    Format: Cardinal;
    Pool: Cardinal;
    out Texture: IDirect3DCubeTexture9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateCubeTexture');
end;

function TSDLDeviceBase.CreateVertexBuffer(
    Length: Cardinal;
    Usage: Cardinal;
    FVF: Cardinal;
    Pool: Cardinal;
    out Buffer: IDirect3DVertexBuffer9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateVertexBuffer');
end;

function TSDLDeviceBase.CreateIndexBuffer(
    Length: Cardinal;
    Usage: Cardinal;
    Format: Cardinal;
    Pool: Cardinal;
    out Buffer: IDirect3DIndexBuffer9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateIndexBuffer');
end;

function TSDLDeviceBase.CreateRenderTarget(
    Width: Cardinal;
    Height: Cardinal;
    Format: Cardinal;
    MultiSample: Cardinal;
    MultiSampleQuality: Cardinal;
    Lockable: LongBool;
    out Surface: IDirect3DSurface9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateRenderTarget');
end;

function TSDLDeviceBase.CreateDepthStencilSurface(
    Width: Cardinal;
    Height: Cardinal;
    Format: Cardinal;
    MultiSample: Cardinal;
    MultiSampleQuality: Cardinal;
    Discard: LongBool;
    out Surface: IDirect3DSurface9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateDepthStencilSurface');
end;

function TSDLDeviceBase.UpdateSurface(
    Source: IDirect3DSurface9;
    SourceRect: PRect;
    Dest: IDirect3DSurface9;
    DestPoint: PPoint
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.UpdateSurface');
end;

function TSDLDeviceBase.UpdateTexture(
    Source: IDirect3DBaseTexture9;
    Dest: IDirect3DBaseTexture9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.UpdateTexture');
end;

function TSDLDeviceBase.GetRenderTargetData(
    Source: IDirect3DSurface9;
    Dest: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetRenderTargetData');
end;

function TSDLDeviceBase.GetFrontBufferData(
    SwapChain: Cardinal;
    Dest: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetFrontBufferData');
end;

function TSDLDeviceBase.StretchRect(
    Source: IDirect3DSurface9;
    SourceRect: PRect;
    Dest: IDirect3DSurface9;
    DestRect: PRect;
    Filter: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.StretchRect');
end;

function TSDLDeviceBase.ColorFill(
    Surface: IDirect3DSurface9;
    Rect: PRect;
    Color: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.ColorFill');
end;

function TSDLDeviceBase.CreateOffscreenPlainSurface(
    Width: Cardinal;
    Height: Cardinal;
    Format: Cardinal;
    Pool: Cardinal;
    out Surface: IDirect3DSurface9;
    SharedHandle: PCardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateOffscreenPlainSurface');
end;

function TSDLDeviceBase.SetRenderTarget(
    Index: Cardinal;
    Surface: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetRenderTarget');
end;

function TSDLDeviceBase.GetRenderTarget(
    Index: Cardinal;
    out Surface: IDirect3DSurface9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetRenderTarget');
end;

function TSDLDeviceBase.SetDepthStencilSurface(Surface: IDirect3DSurface9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetDepthStencilSurface');
end;

function TSDLDeviceBase.GetDepthStencilSurface(out Surface: IDirect3DSurface9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetDepthStencilSurface');
end;

function TSDLDeviceBase.BeginScene: LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.BeginScene');
end;

function TSDLDeviceBase.EndScene: LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.EndScene');
end;

function TSDLDeviceBase.Clear(
    RectCount: Cardinal;
    Rects: PRect;
    Flags: Cardinal;
    Color: Cardinal;
    Z: Single;
    Stencil: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.Clear');
end;

function TSDLDeviceBase.SetTransform(State: Cardinal; const Matrix): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetTransform');
end;

function TSDLDeviceBase.GetTransform(State: Cardinal; out Matrix): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetTransform');
end;

function TSDLDeviceBase.MultiplyTransform(State: Cardinal; const Matrix): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.MultiplyTransform');
end;

function TSDLDeviceBase.SetViewport(const Viewport): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetViewport');
end;

function TSDLDeviceBase.GetViewport(out Viewport): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetViewport');
end;

function TSDLDeviceBase.SetMaterial(const Material): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetMaterial');
end;

function TSDLDeviceBase.GetMaterial(out Material): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetMaterial');
end;

function TSDLDeviceBase.SetLight(Index: Cardinal; const Light): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetLight');
end;

function TSDLDeviceBase.GetLight(Index: Cardinal; out Light): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetLight');
end;

function TSDLDeviceBase.LightEnable(Index: Cardinal; Enable: LongBool): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.LightEnable');
end;

function TSDLDeviceBase.GetLightEnable(Index: Cardinal; out Enable: LongBool): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetLightEnable');
end;

function TSDLDeviceBase.SetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetClipPlane');
end;

function TSDLDeviceBase.GetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetClipPlane');
end;

function TSDLDeviceBase.SetRenderState(State: Cardinal; Value: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetRenderState');
end;

function TSDLDeviceBase.GetRenderState(State: Cardinal; out Value: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetRenderState');
end;

function TSDLDeviceBase.CreateStateBlock(
    BlockType: Cardinal;
    out StateBlock: IDirect3DStateBlock9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateStateBlock');
end;

function TSDLDeviceBase.BeginStateBlock: LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.BeginStateBlock');
end;

function TSDLDeviceBase.EndStateBlock(out StateBlock: IDirect3DStateBlock9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.EndStateBlock');
end;

function TSDLDeviceBase.SetClipStatus(const Status): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetClipStatus');
end;

function TSDLDeviceBase.GetClipStatus(out Status): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetClipStatus');
end;

function TSDLDeviceBase.GetTexture(
    Stage: Cardinal;
    out Texture: IDirect3DBaseTexture9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetTexture');
end;

function TSDLDeviceBase.SetTexture(
    Stage: Cardinal;
    Texture: IDirect3DBaseTexture9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetTexture');
end;

function TSDLDeviceBase.GetTextureStageState(
    Stage: Cardinal;
    State: Cardinal;
    out Value: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetTextureStageState');
end;

function TSDLDeviceBase.SetTextureStageState(
    Stage: Cardinal;
    State: Cardinal;
    Value: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetTextureStageState');
end;

function TSDLDeviceBase.GetSamplerState(
    Sampler: Cardinal;
    State: Cardinal;
    out Value: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetSamplerState');
end;

function TSDLDeviceBase.SetSamplerState(
    Sampler: Cardinal;
    State: Cardinal;
    Value: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetSamplerState');
end;

function TSDLDeviceBase.ValidateDevice(out PassCount: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.ValidateDevice');
end;

function TSDLDeviceBase.SetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetPaletteEntries');
end;

function TSDLDeviceBase.GetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetPaletteEntries');
end;

function TSDLDeviceBase.SetCurrentTexturePalette(Palette: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetCurrentTexturePalette');
end;

function TSDLDeviceBase.GetCurrentTexturePalette(out Palette: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetCurrentTexturePalette');
end;

function TSDLDeviceBase.SetScissorRect(Rect: PRect): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetScissorRect');
end;

function TSDLDeviceBase.GetScissorRect(out Rect: TRect): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetScissorRect');
end;

function TSDLDeviceBase.SetSoftwareVertexProcessing(Software: LongBool): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetSoftwareVertexProcessing');
end;

function TSDLDeviceBase.GetSoftwareVertexProcessing: LongBool; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetSoftwareVertexProcessing');
end;

function TSDLDeviceBase.SetNPatchMode(Segments: Single): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetNPatchMode');
end;

function TSDLDeviceBase.GetNPatchMode: Single; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetNPatchMode');
end;

function TSDLDeviceBase.DrawPrimitive(
    PrimitiveType: Cardinal;
    StartVertex: Cardinal;
    PrimitiveCount: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.DrawPrimitive');
end;

function TSDLDeviceBase.DrawIndexedPrimitive(
    PrimitiveType: Cardinal;
    BaseVertexIndex: Integer;
    MinVertexIndex: Cardinal;
    VertexCount: Cardinal;
    StartIndex: Cardinal;
    PrimitiveCount: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.DrawIndexedPrimitive');
end;

function TSDLDeviceBase.DrawPrimitiveUP(
    PrimitiveType: Cardinal;
    PrimitiveCount: Cardinal;
    Data: Pointer;
    Stride: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.DrawPrimitiveUP');
end;

function TSDLDeviceBase.DrawIndexedPrimitiveUP(
    PrimitiveType: Cardinal;
    MinVertexIndex: Cardinal;
    VertexCount: Cardinal;
    PrimitiveCount: Cardinal;
    IndexData: Pointer;
    IndexFormat: Cardinal;
    Data: Pointer;
    Stride: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.DrawIndexedPrimitiveUP');
end;

function TSDLDeviceBase.ProcessVertices(
    SourceStartIndex: Cardinal;
    DestIndex: Cardinal;
    VertexCount: Cardinal;
    DestBuffer: IDirect3DVertexBuffer9;
    Declaration: IDirect3DVertexDeclaration9;
    Flags: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.ProcessVertices');
end;

function TSDLDeviceBase.CreateVertexDeclaration(
    Elements: Pointer;
    out Declaration: IDirect3DVertexDeclaration9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateVertexDeclaration');
end;

function TSDLDeviceBase.SetVertexDeclaration(
    Declaration: IDirect3DVertexDeclaration9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetVertexDeclaration');
end;

function TSDLDeviceBase.GetVertexDeclaration(
    out Declaration: IDirect3DVertexDeclaration9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetVertexDeclaration');
end;

function TSDLDeviceBase.SetFVF(FVF: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetFVF');
end;

function TSDLDeviceBase.GetFVF(out FVF: Cardinal): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.GetFVF');
end;

function TSDLDeviceBase.CreateVertexShader(
    ByteCode: PCardinal;
    out Shader: IDirect3DVertexShader9
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.CreateVertexShader');
end;

function TSDLDeviceBase.SetVertexShader(Shader: IDirect3DVertexShader9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DDevice9.SetVertexShader');
end;

function TSDLResourceBase.GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.GetDevice');
end;

function TSDLResourceBase.SetPrivateData(
    const Guid: TGUID;
    Data: Pointer;
    DataSize: Cardinal;
    Flags: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.SetPrivateData');
end;

function TSDLResourceBase.GetPrivateData(
    const Guid: TGUID;
    Data: Pointer;
    var DataSize: Cardinal
): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.GetPrivateData');
end;

function TSDLResourceBase.FreePrivateData(const Guid: TGUID): LongInt; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.FreePrivateData');
end;

function TSDLResourceBase.SetPriority(NewPriority: Cardinal): Cardinal; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.SetPriority');
end;

function TSDLResourceBase.GetPriority: Cardinal; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.GetPriority');
end;

procedure TSDLResourceBase.PreLoad; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.PreLoad');
end;

function TSDLResourceBase.GetType: Cardinal; stdcall;
begin
  raise Exception.Create('SDL renderer: unsupported IDirect3DResource9.GetType');
end;

end.
