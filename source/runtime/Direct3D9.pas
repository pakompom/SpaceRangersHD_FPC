{$EXCESSPRECISION OFF}
unit Direct3D9;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types;
const
  D3DADAPTER_DEFAULT = 0;
  D3DDEVTYPE_HAL = 1;
  D3DCREATE_MULTITHREADED = $4;
  D3DCREATE_SOFTWARE_VERTEXPROCESSING = $20;
  D3DCREATE_HARDWARE_VERTEXPROCESSING = $40;
  D3DPRESENT_INTERVAL_DEFAULT = 0;
  D3DPRESENT_INTERVAL_ONE = 1;
  D3DPRESENT_INTERVAL_IMMEDIATE = $80000000;
  D3DSWAPEFFECT_DISCARD = 1;
  D3DSWAPEFFECT_FLIP = 2;
  D3DBACKBUFFER_TYPE_MONO = 0;
  D3DMULTISAMPLE_NONE = 0;
  D3DCLEAR_TARGET = $1;
  D3DFVF_XYZRHW = $004;
  D3DFVF_DIFFUSE = $040;
  D3DFVF_TEX1 = $100;
  D3DFMT_R8G8B8 = 20;
  D3DFMT_A8R8G8B8 = 21;
  D3DFMT_X8R8G8B8 = 22;
  D3DFMT_R5G6B5 = 23;
  D3DFMT_A8 = 28;
  D3DPOOL_DEFAULT = 0;
  D3DPOOL_MANAGED = 1;
  D3DPOOL_SYSTEMMEM = 2;
  D3DLOCK_READONLY = $10;
  D3DPT_POINTLIST = 1;
  D3DPT_LINESTRIP = 3;
  D3DPT_TRIANGLELIST = 4;
  D3DPT_TRIANGLEFAN = 6;
  D3DRS_FILLMODE = 8;
  D3DFILL_WIREFRAME = 2;
  D3DFILL_SOLID = 3;
  D3DRS_SRCBLEND = 19;
  D3DRS_DESTBLEND = 20;
  D3DRS_CULLMODE = 22;
  D3DRS_ALPHABLENDENABLE = 27;
  D3DRS_SCISSORTESTENABLE = 174;
  D3DBLEND_SRCALPHA = 5;
  D3DBLEND_INVSRCALPHA = 6;
  D3DCULL_NONE = 1;
  D3DTSS_ALPHAOP = 4;
  D3DTOP_MODULATE = 4;
  D3DSAMP_MAGFILTER = 5;
  D3DSAMP_MINFILTER = 6;
  D3DSAMP_MIPFILTER = 7;
  D3DTEXF_LINEAR = 2;
type
  IDirect3D9 = interface;
  IDirect3DBaseTexture9 = interface;
  IDirect3DCubeTexture9 = interface;
  IDirect3DDevice9 = interface;
  IDirect3DIndexBuffer9 = interface;
  IDirect3DResource9 = interface;
  IDirect3DStateBlock9 = interface;
  IDirect3DSurface9 = interface;
  IDirect3DSwapChain9 = interface;
  IDirect3DTexture9 = interface;
  IDirect3DVertexBuffer9 = interface;
  IDirect3DVertexDeclaration9 = interface;
  IDirect3DVertexShader9 = interface;
  IDirect3DVolumeTexture9 = interface;
  TD3DAdapterIdentifier9 = packed record
    Driver: array[0..511] of AnsiChar;
    Description: array[0..511] of AnsiChar;
    DeviceName: array[0..31] of AnsiChar;
    DriverVersion: Int64;
    VendorId: Cardinal;
    DeviceId: Cardinal;
    SubSysId: Cardinal;
    Revision: Cardinal;
    DeviceIdentifier: TGUID;
    WHQLLevel: Cardinal;
  end;
  TD3DCaps9 = packed record
    CapabilitiesPrefix: array[0..87] of Byte;
    MaxTextureWidth: Cardinal;
    MaxTextureHeight: Cardinal;
    MaxVolumeExtent: Cardinal;
    MaxTextureRepeat: Cardinal;
    MaxTextureAspectRatio: Cardinal;
    MaxAnisotropy: Cardinal;
    CapabilitiesTail: array[0..191] of Byte;
  end;
  TD3DGammaRamp = packed record
    Red: array[0..255] of Word;
    Green: array[0..255] of Word;
    Blue: array[0..255] of Word;
  end;
  TD3DPresentParameters = record
    BackBufferWidth: Cardinal;
    BackBufferHeight: Cardinal;
    BackBufferFormat: Cardinal;
    BackBufferCount: Cardinal;
    MultiSampleType: Cardinal;
    MultiSampleQuality: Cardinal;
    SwapEffect: Cardinal;
    DeviceWindow: Cardinal;
    Windowed: LongBool;
    EnableAutoDepthStencil: LongBool;
    AutoDepthStencilFormat: Cardinal;
    Flags: Cardinal;
    FullScreenRefreshRateInHz: Cardinal;
    PresentationInterval: Cardinal;
  end;
  TD3DLockedRect = packed record
    Pitch: Integer;
    Bits: Pointer;
  end;
  TD3DSurfaceDesc = packed record
    Format: Cardinal;
    ResourceType: Cardinal;
    Usage: Cardinal;
    Pool: Cardinal;
    MultiSampleType: Cardinal;
    MultiSampleQuality: Cardinal;
    Width: Cardinal;
    Height: Cardinal;
  end;
  IDirect3D9 = interface(IInterface)
    ['{81BDCBCA-64D4-426D-AE8D-AD0147F4275C}']
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
  IDirect3DSwapChain9 = interface(IInterface)
  end;
  IDirect3DVolumeTexture9 = interface(IInterface)
  end;
  IDirect3DCubeTexture9 = interface(IInterface)
  end;
  IDirect3DVertexBuffer9 = interface(IInterface)
  end;
  IDirect3DIndexBuffer9 = interface(IInterface)
  end;
  IDirect3DVertexDeclaration9 = interface(IInterface)
    ['{DD13C59C-36FA-4098-A8FB-C7ED39DC8546}']
    function GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall;
    function GetDeclaration(Elements: Pointer; var ElementCount: Cardinal): LongInt; stdcall;
  end;
  IDirect3DVertexShader9 = interface(IInterface)
    ['{EFC5557E-6265-4613-8A94-43857889EB36}']
    function GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall;
    function GetFunction(Data: Pointer; var ByteCount: Cardinal): LongInt; stdcall;
  end;
  IDirect3DStateBlock9 = interface(IInterface)
    ['{B07C4FE5-310D-4BA8-A23C-4F0F206F218B}']
    function GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall;
    function Capture: LongInt; stdcall;
    function Apply: LongInt; stdcall;
  end;
  IDirect3DResource9 = interface(IInterface)
    ['{05EEC05D-8F7D-4362-B999-D1BAF357C704}']
    function GetDevice(out Device: IDirect3DDevice9): LongInt; stdcall;
    function SetPrivateData(
        const Guid: TGUID;
        Data: Pointer;
        DataSize: Cardinal;
        Flags: Cardinal
    ): LongInt; stdcall;
    function GetPrivateData(
        const Guid: TGUID;
        Data: Pointer;
        var DataSize: Cardinal
    ): LongInt; stdcall;
    function FreePrivateData(const Guid: TGUID): LongInt; stdcall;
    function SetPriority(NewPriority: Cardinal): Cardinal; stdcall;
    function GetPriority: Cardinal; stdcall;
    procedure PreLoad; stdcall;
    function GetType: Cardinal; stdcall;
  end;
  IDirect3DBaseTexture9 = interface(IDirect3DResource9)
    ['{580CA87E-1D3C-4D54-991D-B7D3E3C298CE}']
    function SetLOD(NewLOD: Cardinal): Cardinal; stdcall;
    function GetLOD: Cardinal; stdcall;
    function GetLevelCount: Cardinal; stdcall;
    function SetAutoGenFilterType(Filter: Cardinal): LongInt; stdcall;
    function GetAutoGenFilterType: Cardinal; stdcall;
    procedure GenerateMipSubLevels; stdcall;
  end;
  IDirect3DTexture9 = interface(IDirect3DBaseTexture9)
    ['{85C31227-3DE5-4F00-9B3A-F11AC38C18B5}']
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
  IDirect3DSurface9 = interface(IDirect3DResource9)
    ['{0CFBAF3A-9FF6-429A-99B3-A2796AF8B89B}']
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
  IDirect3DDevice9 = interface(IInterface)
    ['{D0223B96-BF7A-43FD-92BD-A43B0D82B9EB}']
    function TestCooperativeLevel: LongInt; stdcall;
    function GetAvailableTextureMem: Cardinal; stdcall;
    function EvictManagedResources: LongInt; stdcall;
    function GetDirect3D(out Direct3D: IDirect3D9): LongInt; stdcall;
    function GetDeviceCaps(out Caps: TD3DCaps9): LongInt; stdcall;
    function GetDisplayMode(SwapChain: Cardinal; out Mode): LongInt; stdcall;
    function GetCreationParameters(out Parameters): LongInt; stdcall;
    function SetCursorProperties(
        XHotSpot: Cardinal;
        YHotSpot: Cardinal;
        CursorBitmap: IDirect3DSurface9
    ): LongInt; stdcall;
    procedure SetCursorPosition(X: Integer; Y: Integer; Flags: Cardinal); stdcall;
    function ShowCursor(Show: LongBool): LongBool; stdcall;
    function CreateAdditionalSwapChain(
        var Parameters;
        out SwapChain: IDirect3DSwapChain9
    ): LongInt; stdcall;
    function GetSwapChain(Index: Cardinal; out SwapChain: IDirect3DSwapChain9): LongInt; stdcall;
    function GetNumberOfSwapChains: Cardinal; stdcall;
    function Reset(var Parameters): LongInt; stdcall;
    function Present(
        SourceRect: PRect;
        DestRect: PRect;
        DestWindow: Cardinal;
        DirtyRegion: Pointer
    ): LongInt; stdcall;
    function GetBackBuffer(
        SwapChain: Cardinal;
        BackBuffer: Cardinal;
        BackBufferType: Cardinal;
        out Surface: IDirect3DSurface9
    ): LongInt; stdcall;
    function GetRasterStatus(SwapChain: Cardinal; out Status): LongInt; stdcall;
    function SetDialogBoxMode(Enable: LongBool): LongInt; stdcall;
    procedure SetGammaRamp(SwapChain: Cardinal; Flags: Cardinal; const Ramp); stdcall;
    procedure GetGammaRamp(SwapChain: Cardinal; out Ramp); stdcall;
    function CreateTexture(
        Width: Cardinal;
        Height: Cardinal;
        Levels: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Texture: IDirect3DTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
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
    ): LongInt; stdcall;
    function CreateCubeTexture(
        EdgeLength: Cardinal;
        Levels: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Texture: IDirect3DCubeTexture9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function CreateVertexBuffer(
        Length: Cardinal;
        Usage: Cardinal;
        FVF: Cardinal;
        Pool: Cardinal;
        out Buffer: IDirect3DVertexBuffer9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function CreateIndexBuffer(
        Length: Cardinal;
        Usage: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Buffer: IDirect3DIndexBuffer9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function CreateRenderTarget(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        MultiSample: Cardinal;
        MultiSampleQuality: Cardinal;
        Lockable: LongBool;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function CreateDepthStencilSurface(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        MultiSample: Cardinal;
        MultiSampleQuality: Cardinal;
        Discard: LongBool;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function UpdateSurface(
        Source: IDirect3DSurface9;
        SourceRect: PRect;
        Dest: IDirect3DSurface9;
        DestPoint: PPoint
    ): LongInt; stdcall;
    function UpdateTexture(
        Source: IDirect3DBaseTexture9;
        Dest: IDirect3DBaseTexture9
    ): LongInt; stdcall;
    function GetRenderTargetData(
        Source: IDirect3DSurface9;
        Dest: IDirect3DSurface9
    ): LongInt; stdcall;
    function GetFrontBufferData(SwapChain: Cardinal; Dest: IDirect3DSurface9): LongInt; stdcall;
    function StretchRect(
        Source: IDirect3DSurface9;
        SourceRect: PRect;
        Dest: IDirect3DSurface9;
        DestRect: PRect;
        Filter: Cardinal
    ): LongInt; stdcall;
    function ColorFill(Surface: IDirect3DSurface9; Rect: PRect; Color: Cardinal): LongInt; stdcall;
    function CreateOffscreenPlainSurface(
        Width: Cardinal;
        Height: Cardinal;
        Format: Cardinal;
        Pool: Cardinal;
        out Surface: IDirect3DSurface9;
        SharedHandle: PCardinal
    ): LongInt; stdcall;
    function SetRenderTarget(Index: Cardinal; Surface: IDirect3DSurface9): LongInt; stdcall;
    function GetRenderTarget(Index: Cardinal; out Surface: IDirect3DSurface9): LongInt; stdcall;
    function SetDepthStencilSurface(Surface: IDirect3DSurface9): LongInt; stdcall;
    function GetDepthStencilSurface(out Surface: IDirect3DSurface9): LongInt; stdcall;
    function BeginScene: LongInt; stdcall;
    function EndScene: LongInt; stdcall;
    function Clear(
        RectCount: Cardinal;
        Rects: PRect;
        Flags: Cardinal;
        Color: Cardinal;
        Z: Single;
        Stencil: Cardinal
    ): LongInt; stdcall;
    function SetTransform(State: Cardinal; const Matrix): LongInt; stdcall;
    function GetTransform(State: Cardinal; out Matrix): LongInt; stdcall;
    function MultiplyTransform(State: Cardinal; const Matrix): LongInt; stdcall;
    function SetViewport(const Viewport): LongInt; stdcall;
    function GetViewport(out Viewport): LongInt; stdcall;
    function SetMaterial(const Material): LongInt; stdcall;
    function GetMaterial(out Material): LongInt; stdcall;
    function SetLight(Index: Cardinal; const Light): LongInt; stdcall;
    function GetLight(Index: Cardinal; out Light): LongInt; stdcall;
    function LightEnable(Index: Cardinal; Enable: LongBool): LongInt; stdcall;
    function GetLightEnable(Index: Cardinal; out Enable: LongBool): LongInt; stdcall;
    function SetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall;
    function GetClipPlane(Index: Cardinal; Plane: PSingle): LongInt; stdcall;
    function SetRenderState(State: Cardinal; Value: Cardinal): LongInt; stdcall;
    function GetRenderState(State: Cardinal; out Value: Cardinal): LongInt; stdcall;
    function CreateStateBlock(
        BlockType: Cardinal;
        out StateBlock: IDirect3DStateBlock9
    ): LongInt; stdcall;
    function BeginStateBlock: LongInt; stdcall;
    function EndStateBlock(out StateBlock: IDirect3DStateBlock9): LongInt; stdcall;
    function SetClipStatus(const Status): LongInt; stdcall;
    function GetClipStatus(out Status): LongInt; stdcall;
    function GetTexture(Stage: Cardinal; out Texture: IDirect3DBaseTexture9): LongInt; stdcall;
    function SetTexture(Stage: Cardinal; Texture: IDirect3DBaseTexture9): LongInt; stdcall;
    function GetTextureStageState(
        Stage: Cardinal;
        State: Cardinal;
        out Value: Cardinal
    ): LongInt; stdcall;
    function SetTextureStageState(
        Stage: Cardinal;
        State: Cardinal;
        Value: Cardinal
    ): LongInt; stdcall;
    function GetSamplerState(
        Sampler: Cardinal;
        State: Cardinal;
        out Value: Cardinal
    ): LongInt; stdcall;
    function SetSamplerState(Sampler: Cardinal; State: Cardinal; Value: Cardinal): LongInt; stdcall;
    function ValidateDevice(out PassCount: Cardinal): LongInt; stdcall;
    function SetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall;
    function GetPaletteEntries(Palette: Cardinal; Entries: Pointer): LongInt; stdcall;
    function SetCurrentTexturePalette(Palette: Cardinal): LongInt; stdcall;
    function GetCurrentTexturePalette(out Palette: Cardinal): LongInt; stdcall;
    function SetScissorRect(Rect: PRect): LongInt; stdcall;
    function GetScissorRect(out Rect: TRect): LongInt; stdcall;
    function SetSoftwareVertexProcessing(Software: LongBool): LongInt; stdcall;
    function GetSoftwareVertexProcessing: LongBool; stdcall;
    function SetNPatchMode(Segments: Single): LongInt; stdcall;
    function GetNPatchMode: Single; stdcall;
    function DrawPrimitive(
        PrimitiveType: Cardinal;
        StartVertex: Cardinal;
        PrimitiveCount: Cardinal
    ): LongInt; stdcall;
    function DrawIndexedPrimitive(
        PrimitiveType: Cardinal;
        BaseVertexIndex: Integer;
        MinVertexIndex: Cardinal;
        VertexCount: Cardinal;
        StartIndex: Cardinal;
        PrimitiveCount: Cardinal
    ): LongInt; stdcall;
    function DrawPrimitiveUP(
        PrimitiveType: Cardinal;
        PrimitiveCount: Cardinal;
        Data: Pointer;
        Stride: Cardinal
    ): LongInt; stdcall;
    function DrawIndexedPrimitiveUP(
        PrimitiveType: Cardinal;
        MinVertexIndex: Cardinal;
        VertexCount: Cardinal;
        PrimitiveCount: Cardinal;
        IndexData: Pointer;
        IndexFormat: Cardinal;
        Data: Pointer;
        Stride: Cardinal
    ): LongInt; stdcall;
    function ProcessVertices(
        SourceStartIndex: Cardinal;
        DestIndex: Cardinal;
        VertexCount: Cardinal;
        DestBuffer: IDirect3DVertexBuffer9;
        Declaration: IDirect3DVertexDeclaration9;
        Flags: Cardinal
    ): LongInt; stdcall;
    function CreateVertexDeclaration(
        Elements: Pointer;
        out Declaration: IDirect3DVertexDeclaration9
    ): LongInt; stdcall;
    function SetVertexDeclaration(Declaration: IDirect3DVertexDeclaration9): LongInt; stdcall;
    function GetVertexDeclaration(out Declaration: IDirect3DVertexDeclaration9): LongInt; stdcall;
    function SetFVF(FVF: Cardinal): LongInt; stdcall;
    function GetFVF(out FVF: Cardinal): LongInt; stdcall;
    function CreateVertexShader(
        ByteCode: PCardinal;
        out Shader: IDirect3DVertexShader9
    ): LongInt; stdcall;
    function SetVertexShader(Shader: IDirect3DVertexShader9): LongInt; stdcall;
  end;
const
  D3DERR_DEVICENOTRESET = -2005530519;
type
  TDirect3DCreate9 = function(SDKVersion: Cardinal): Pointer; stdcall;
var
  Direct3DCreate9: TDirect3DCreate9;
function CreateDirect3D9(SDKVersion: Cardinal): IDirect3D9; stdcall;
implementation
uses
  Math;

function CreateDirect3D9(SDKVersion: Cardinal): IDirect3D9; stdcall;
begin
  Result := IDirect3D9(Direct3DCreate9(SDKVersion));
  if Result <> nil then
    Result._Release;
end;

end.
