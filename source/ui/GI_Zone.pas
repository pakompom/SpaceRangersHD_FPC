{$EXCESSPRECISION OFF}
unit GI_Zone;
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
  TZoneGI = class;
  {$Z1}
  TZoneKindGI = (zkRect = 0, zkCircle = 1);
  TZoneGI = class(TObjectGI)
    Kind: TZoneKindGI;
    CursorInside: Boolean;
    Gap122: array[0..5] of Byte;
    EnterCallback: TObjectNotifyEventGI;
    LeaveCallback: TObjectNotifyEventGI;
    ZoneMouseDownCallback: TObjectMouseEventGI;
    ZoneMouseUpCallback: TObjectMouseEventGI;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure Invalidate; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetKind(Value: TZoneKindGI);
    function HitTest(Point: TPoint): Boolean;
    procedure LoadZoneProperties(Block: TBlockParEC);
  end;
implementation
uses
  aMyFunction,
  EC_Struct,
  Math,
  GR_Main;

constructor TZoneGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;

destructor TZoneGI.Destroy;
begin
  inherited Destroy;
end;

procedure TZoneGI.SetKind(Value: TZoneKindGI);
begin
  if Kind <> Value then
    Kind := Value;
end;

procedure TZoneGI.Invalidate;
begin
end;

function TZoneGI.HitTest(Point: TPoint): Boolean;
var
  Diameter: Integer;
begin
  Result := False;
  if Kind = zkRect then
    Result := ContainsPoint(Point)
  else if Kind = zkCircle then
  begin
    if HitTestBounds.Right - HitTestBounds.Left < HitTestBounds.Bottom - HitTestBounds.Top then
      Diameter := HitTestBounds.Right - HitTestBounds.Left
    else
      Diameter := HitTestBounds.Bottom - HitTestBounds.Top;
    Result :=
        Sqr(Diameter / 2)
            >= PointDistanceSquared(
                MakePointF(
                    (HitTestBounds.Left + HitTestBounds.Right) div 2,
                    (HitTestBounds.Top + HitTestBounds.Bottom) div 2
                ),
                PointToPointF(Point));
  end;
end;

procedure TZoneGI.OnActivate;
begin
  inherited OnActivate;
  if HitTest(MessageLoop.GetCursorPoint) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then
        EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if CursorInside then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if HitTest(MessageLoop.GetCursorPoint) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then
        EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if CursorInside then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessMouseMove(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then
        EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then
        EnterCallback(Self);
    end;
    if Assigned(ZoneMouseDownCallback) then
      ZoneMouseDownCallback(Self, KeyState, Point);
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then
        EnterCallback(Self);
    end;
    if Assigned(ZoneMouseUpCallback) then
      ZoneMouseUpCallback(Self, KeyState, Point);
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then
      LeaveCallback(Self);
  end;
end;

procedure TZoneGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadZoneProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TZoneGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadZoneProperties(Block);
end;

procedure TZoneGI.LoadZoneProperties(Block: TBlockParEC);
var
  Value: WideString;
begin
  if Block.CountParams('Kind') > 0 then
  begin
    Value := Block.GetParam('Kind');
    if Value = 'Rect' then
      SetKind(zkRect)
    else if Value = 'Circle' then
      SetKind(zkCircle);
  end;
end;

procedure TZoneGI.UpdateAutoGeometry;
begin
  inherited UpdateAutoGeometry;
end;

end.
