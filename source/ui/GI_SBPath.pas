{$EXCESSPRECISION OFF}
unit GI_SBPath;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_Image,
  GI_MessageLoop,
  Types;
type
  TSBPathGI = class;
  TSBPathGI = class(TObjectGI)
    PointCount: Integer;
    Points: array of TPoint;
    Minimum: Integer;
    Maximum: Integer;
    Position: Integer;
    Dragging: Boolean;
    Gap135: array[0..2] of Byte;
    ThumbImage: TImageGI;
    HitRadius: Integer;
    ChangeCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(Path: WideString);
    procedure SetPositionValue(Value: Integer);
    procedure UpdateThumbPosition;
    function PositionFromPointIndex(Index: Integer): Integer;
    function FindClosestPoint(Point: TPoint; var DistanceSquared: Integer): Integer;
    procedure LoadPathProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GR_Main,
  Classes,
  SysUtils,
  GI_Main;

constructor TSBPathGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ThumbImage := TImageGI.Create(Self);
  Minimum := 0;
  Maximum := 100;
  Position := 0;
  HitRadius := 40;
  UpdateThumbPosition;
end;

destructor TSBPathGI.Destroy;
begin
  inherited Destroy;
end;

procedure TSBPathGI.Clear;
begin
  PointCount := 0;
  Points := nil;
  ThumbImage.Clear;
  inherited Clear;
end;

procedure TSBPathGI.SetImagePath(Path: WideString);
begin
  ThumbImage.SetImagePath(Path);
  ThumbImage.SetSize(ThumbImage.GetContentSize);
  ThumbImage.SetOrigin(Classes.Point(ThumbImage.ClientSize.X div 2, ThumbImage.ClientSize.Y div 2));
end;

procedure TSBPathGI.SetPositionValue(Value: Integer);
begin
  if Position = Value then
    Exit;
  if Value < Minimum then
    Value := Minimum;
  if Value > Maximum then
    Value := Maximum;
  if Position = Value then
    Exit;
  Position := Value;
  UpdateThumbPosition;
  if Assigned(ChangeCallback) then
    ChangeCallback(Self);
end;

procedure TSBPathGI.UpdateThumbPosition;
begin
  if PointCount < 1 then
    Exit;
  if Maximum - Minimum < 1 then
    ThumbImage.SetPosition(Points[0])
  else
    ThumbImage
        .SetPosition(Points[Round((Position - Minimum) / (Maximum - Minimum) * (PointCount - 1))]);
end;

function TSBPathGI.PositionFromPointIndex(Index: Integer): Integer;
begin
  if PointCount < 2 then
    Result := Minimum
  else
    Result := Round(Index / (PointCount - 1) * (Maximum - Minimum) + Minimum);
end;

function TSBPathGI.FindClosestPoint(Point: TPoint; var DistanceSquared: Integer): Integer;
var
  BestDistance, BestIndex, Distance, I: Integer;
begin
  BestDistance := 99999999;
  BestIndex := -1;
  for I := 0 to PointCount - 1 do
  begin
    Distance := Sqr(Point.X - Points[I].X) + Sqr(Point.Y - Points[I].Y);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      BestIndex := I;
    end;
  end;
  DistanceSquared := BestDistance;
  Result := BestIndex;
end;

procedure TSBPathGI.OnActivate;
begin
  inherited OnActivate;
  Dragging := False;
end;

procedure TSBPathGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Dragging := False;
end;

procedure TSBPathGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;

procedure TSBPathGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
end;

procedure TSBPathGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var
  Index, Distance: Integer;
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if PointCount < 1 then
    Exit;
  Index := FindClosestPoint(ToLocalPoint(Point), Distance);
  if Sqr(HitRadius) > Distance then
  begin
    Position := PositionFromPointIndex(Index);
    UpdateThumbPosition;
    Dragging := True;
    if Assigned(ChangeCallback) then
      ChangeCallback(Self);
  end
  else
    Dragging := False;
end;

procedure TSBPathGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  Dragging := False;
end;

procedure TSBPathGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var
  Index, Distance: Integer;
begin
  inherited ProcessMouseMove(KeyState, LocalPosition);
  if not Dragging then
    Exit;
  Index := FindClosestPoint(ToLocalPoint(Point), Distance);
  if Sqr(HitRadius) > Distance then
  begin
    Position := PositionFromPointIndex(Index);
    UpdateThumbPosition;
    Dragging := True;
    if Assigned(ChangeCallback) then
      ChangeCallback(Self);
  end
  else
    Dragging := False;
end;

procedure TSBPathGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadPathProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TSBPathGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadPathProperties(Block);
end;

procedure TSBPathGI.LoadPathProperties(Block: TBlockParEC);
var
  Path: TBlockParEC;
  I: Integer;
begin
  if Block.CountBlocks('Path') > 0 then
  begin
    Points := nil;
    Path := Block.GetBlock('Path');
    PointCount := Path.GetParamCount;
    SetLength(Points, PointCount);
    for I := 0 to PointCount - 1 do
      Points[I] := GetPointGI(Path.GetParamValue(I));
  end;
  if Block.CountParams('Image') > 0 then
    SetImagePath(Block.GetParam('Image'));
  if Block.CountParams('Min') > 0 then
    Minimum := StrToInt(Block.GetParam('Min'));
  if Block.CountParams('Max') > 0 then
    Maximum := StrToInt(Block.GetParam('Max'));
  if Minimum > Maximum then
    Minimum := Maximum;
  if Block.CountParams('Position') > 0 then
    SetPositionValue(StrToInt(Block.GetParam('Position')));
  if Block.CountParams('RadiusHit') > 0 then
    HitRadius := StrToInt(Block.GetParam('RadiusHit'));
  UpdateThumbPosition;
end;

end.
