{$EXCESSPRECISION OFF}
unit GI_ShrLight;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  GR_GraphBuf,
  Types;
type
  TShrLightGI = class;
  {$Z1}
  TShrLightKindGI = (slkAll = 0, slkBuffer = 1);
  TShrLightGI = class(TObjectGI)
    Kind: TShrLightKindGI;
    Gap121: array[0..2] of Byte;
    LightShift: Integer;
    LightBuffer: TGraphBufGR;
    Gap12C: array[0..11] of Byte;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetKind(Value: TShrLightKindGI);
    procedure SetLightShift(Value: Integer);
    procedure LoadLightProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GlobalsV,
  EC_Mem,
  GR_DX,
  GR_Main,
  SysUtils;

constructor TShrLightGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := slkAll;
  LightShift := 1;
end;

destructor TShrLightGI.Destroy;
begin
  if LightBuffer <> nil then
  begin
    LightBuffer.Free;
    LightBuffer := nil;
  end;
  inherited Destroy;
end;

procedure TShrLightGI.Clear;
begin
  if LightBuffer <> nil then
  begin
    LightBuffer.Free;
    LightBuffer := nil;
  end;
  Kind := slkAll;
  LightShift := 1;
  inherited Clear;
end;

procedure TShrLightGI.SetKind(Value: TShrLightKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    if Kind = slkBuffer then
    begin
      LightBuffer := TGraphBufGR.Create(False);
      LightBuffer.AllocateGrayscale(ClientSize.X, ClientSize.Y);
      LightBuffer.FillPixels(0);
    end
    else if LightBuffer <> nil then
    begin
      LightBuffer.Free;
      LightBuffer := nil;
    end;
    Invalidate;
  end;
end;

procedure TShrLightGI.SetLightShift(Value: Integer);
begin
  if LightShift <> Value then
  begin
    LightShift := Value;
    Invalidate;
  end;
end;

procedure TShrLightGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if Kind = slkBuffer then
  begin
    LightBuffer.AllocateGrayscale(Size.X, Size.Y);
    LightBuffer.FillPixels(0);
  end;
end;

procedure TShrLightGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadLightProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TShrLightGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadLightProperties(Block);
end;

procedure TShrLightGI.LoadLightProperties(Block: TBlockParEC);
var
  Text: WideString;
begin
  if Block.CountParams('ShrLight') > 0 then
    SetLightShift(StrToInt(AnsiString(Block.GetParam('ShrLight'))));
  if Block.CountParams('Kind') > 0 then
  begin
    Text := Block.GetParam('Kind');
    if Text = 'All' then
      SetKind(slkAll)
    else if Text = 'Buf' then
      SetKind(slkBuffer);
  end;
end;

procedure TShrLightGI.Draw(ClipRect: TRect);
var
  Alpha: Integer;
begin
  if HardwareRenderingEnabled then
  begin
    Alpha := 255;
    if LightShift = 2 then
      Alpha := 128
    else if LightShift = 0 then
      Exit
    else if LightShift = -2 then
      Alpha := 64
    else
      AppendLogLineThreadSafe('FShrLight=' + IntToStr(LightShift));
    if Kind = slkBuffer then
      DrawColoredRect(0, 0, GameScreenWidth, GameScreenHeight, 0, Alpha, True, @ClipRect)
    else if Kind = slkAll then
      DrawColoredRect(0, 0, GameScreenWidth, GameScreenHeight, 0, Alpha, True, @ClipRect);
  end
  else if Kind = slkBuffer then
    Ex_OKGR_ShrLightMask_16(
        AddPointerOffset(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2
        ),
        ScreenRenderBuffer.PitchBytes,
        AddPointerOffset(
            LightBuffer.GetPixels,
            (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes
                + (ClipRect.Left - HitTestBounds.Left)
        ),
        LightBuffer.PitchBytes,
        ClipRect.Right - ClipRect.Left,
        ClipRect.Bottom - ClipRect.Top
    )
  else if Kind = slkAll then
    ScreenRenderBuffer.ShiftLight16(LightShift, ClipRect);
end;

end.
