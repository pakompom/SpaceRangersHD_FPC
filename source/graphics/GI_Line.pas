{$EXCESSPRECISION OFF}
unit GI_Line;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  Types;
type
  TLineGI = class;
  TLineGI = class(TObjectGI)
    Color: Cardinal;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetColor(Value: Cardinal);
    procedure LoadLineProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GlobalsV,
  Classes,
  GI_Main,
  GR_DX,
  GR_Main;

constructor TLineGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
end;

destructor TLineGI.Destroy;
begin
  inherited Destroy;
end;

procedure TLineGI.Clear;
begin
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  inherited Clear;
end;

procedure TLineGI.SetColor(Value: Cardinal);
begin
  if Color <> Value then
  begin
    Color := Value;
    Invalidate;
  end;
end;

procedure TLineGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadLineProperties(Block);
end;

procedure TLineGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadLineProperties(Block);
end;

procedure TLineGI.LoadLineProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Color') > 0 then
    Color := GetColorGI(Block.GetParam('Color'));
end;

procedure TLineGI.Draw(ClipRect: TRect);
begin
  if HardwareRenderingEnabled then
    DrawAlphaLine(
        HitTestBounds.Left,
        HitTestBounds.Top,
        HitTestBounds.Right - 1,
        HitTestBounds.Bottom - 1,
        Color565ToArgb(Color),
        255,
        @ClipRect
    )
  else
    ScreenRenderBuffer.DrawLine16Clipped(
        Classes.Point(HitTestBounds.Left, HitTestBounds.Top),
        Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1),
        Color,
        ClipRect
    );
end;

end.
