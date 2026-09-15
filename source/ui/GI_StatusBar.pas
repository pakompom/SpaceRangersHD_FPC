{$EXCESSPRECISION OFF}
unit GI_StatusBar;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_Image,
  GI_MessageLoop,
  GI_Panel,
  Types;
type
  TStatusBarGI = class;
  TStatusBarGI = class(TPanelGI)
    Minimum: Double;
    Maximum: Double;
    Value: Double;
    LeftImage: TImageGI;
    CenterImage: TImageGI;
    RightImage: TImageGI;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetRange(MinValue: Double; MaxValue: Double);
    procedure SetValue(NewValue: Double);
    procedure UpdateImageLayout;
    procedure LoadStatusProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GR_Main,
  Classes,
  EC_Str,
  GI_Main;

constructor TStatusBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  LeftImage := TImageGI.Create(Self);
  CenterImage := TImageGI.Create(Self);
  RightImage := TImageGI.Create(Self);
  LeftImage.SetDepth(1);
  LeftImage.SetImageKindX(ikxLeft);
  LeftImage.SetImageKindY(ikyCenter);
  CenterImage.SetDepth(1);
  CenterImage.SetImageKindX(ikxLeftFill);
  CenterImage.SetImageKindY(ikyCenter);
  RightImage.SetDepth(1);
  RightImage.SetImageKindX(ikxLeft);
  RightImage.SetImageKindY(ikyCenter);
  Minimum := 0;
  Maximum := 100;
end;

destructor TStatusBarGI.Destroy;
begin
  LeftImage.Free;
  CenterImage.Free;
  RightImage.Free;
  inherited Destroy;
end;

procedure TStatusBarGI.Clear;
begin
  Minimum := 0;
  Maximum := 100;
  inherited Clear;
end;

procedure TStatusBarGI.SetRange(MinValue, MaxValue: Double);
begin
  if MinValue > MaxValue then
    MinValue := MaxValue;
  if (MinValue <> Minimum) or (MaxValue <> Maximum) then
  begin
    Minimum := MinValue;
    Maximum := MaxValue;
    UpdateImageLayout;
    Invalidate;
  end;
end;

procedure TStatusBarGI.SetValue(NewValue: Double);
begin
  if NewValue < Minimum then
    NewValue := Minimum;
  if NewValue > Maximum then
    NewValue := Maximum;
  if NewValue <> Value then
  begin
    Value := NewValue;
    UpdateImageLayout;
    Invalidate;
  end;
end;

procedure TStatusBarGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateImageLayout;
  Invalidate;
end;

procedure TStatusBarGI.UpdateImageLayout;
var
  Width: Integer;
begin
  if Maximum - Minimum = 0 then
    Width := 0
  else
    Width := Round((Value - Minimum) / (Maximum - Minimum) * ClientSize.X);
  if Minimum = Value then
  begin
    LeftImage.SetSize(Classes.Point(0, ClientSize.Y));
    CenterImage.SetSize(Classes.Point(0, ClientSize.Y));
    RightImage.SetSize(Classes.Point(0, ClientSize.Y));
  end
  else if LeftImage.GetContentSize.X + RightImage.GetContentSize.X >= Width then
  begin
    LeftImage.SetSize(Classes.Point(LeftImage.GetContentSize.X, ClientSize.Y));
    CenterImage.SetSize(Classes.Point(0, ClientSize.Y));
    RightImage.SetSize(Classes.Point(RightImage.GetContentSize.X, ClientSize.Y));
    LeftImage.SetPosition(Classes.Point(0, 0));
    CenterImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
    RightImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
  end
  else
  begin
    LeftImage.SetSize(Classes.Point(LeftImage.GetContentSize.X, ClientSize.Y));
    CenterImage.SetSize(
        Classes.Point(Width - LeftImage.ClientSize.X - RightImage.ClientSize.X, ClientSize.Y)
    );
    RightImage.SetSize(Classes.Point(RightImage.GetContentSize.X, ClientSize.Y));
    LeftImage.SetPosition(Classes.Point(0, 0));
    CenterImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
    RightImage.SetPosition(Classes.Point(LeftImage.ClientSize.X + CenterImage.ClientSize.X, 0));
    CenterImage.SetImageKindX(ikxLeftFill);
  end;
end;

procedure TStatusBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadStatusProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TStatusBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadStatusProperties(Block);
end;

procedure TStatusBarGI.LoadStatusProperties(Block: TBlockParEC);
begin
  if Block.CountParams('ImageLeft') > 0 then
    LeftImage.SetImagePath(Block.GetParam('ImageLeft'));
  if Block.CountParams('ImageMiddle') > 0 then
    CenterImage.SetImagePath(Block.GetParam('ImageMiddle'));
  if Block.CountParams('ImageRight') > 0 then
    RightImage.SetImagePath(Block.GetParam('ImageRight'));
  if (Block.CountParams('Min') > 0) and (Block.CountParams('Max') > 0) then
    SetRange(
        ExtractDecimalToSingleW(Block.GetParam('Min')),
        ExtractDecimalToSingleW(Block.GetParam('Max'))
    );
  if Block.CountParams('Cur') > 0 then
    SetValue(ExtractDecimalToSingleW(Block.GetParam('Cur')));
  UpdateImageLayout;
end;

end.
