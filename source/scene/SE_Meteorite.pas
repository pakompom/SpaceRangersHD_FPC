{$EXCESSPRECISION OFF}
unit SE_Meteorite;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  SE_Space,
  Types;
type
  TMeteoriteSE = class;
  TMeteoriteSE = class(TObjectSE)
    ImagePath: WideString;
    TimerInterval: Integer;
    Speed: Single;
    Angle: Single;
    Animation: TgaiGI;
    MoveTimer: PSpaceTimerSE;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    constructor Create(GraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    function IsNearView(Point: TPointF): Boolean;
    procedure PlaceRandomly;
    procedure RestartOutsideView;
    procedure AdvanceMotion(Timer: PSpaceTimerSE; UserData: Integer);
  end;
implementation
uses
  Globals,
  Math,
  GlobalsV,
  GR_Main,
  GI_Main,
  EC_Str,
  aMyFunction,
  SE_Process;

constructor TMeteoriteSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
end;

destructor TMeteoriteSE.Destroy;
begin
  inherited Destroy;
end;

procedure TMeteoriteSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  ConfigureLoopSound('Comet');
  ConfigureRandomSound('Comet');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  Animation.SetImagePath(ImagePath);
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPosition(TruncatePointF(Position));
  Animation.SetPositionModeW(True);
  Animation.SequenceIndex := 0;
  Animation.UpdateAutoGeometry;
  Animation.RestartPlayback;
  PlaceRandomly;
  MoveTimer := Space.CreateTimer(TimerInterval, TimerInterval, AdvanceMotion, 0);
end;

procedure TMeteoriteSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if MoveTimer <> nil then
  begin
    Space.DeleteTimer(MoveTimer);
    MoveTimer := nil;
  end;
  if Animation <> nil then
  begin
    Animation.Free;
    Animation := nil;
  end;
  inherited DetachFromSpace;
end;

procedure TMeteoriteSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
    Animation.SetPosition(TruncatePointF(APosition));
end;

function TMeteoriteSE.IsNearView(Point: TPointF): Boolean;
var
  Height, Width: Single;
begin
  Width := Cardinal(GameScreenWidth);
  Height := Cardinal(GameScreenHeight);
  Result :=
      (SpaceViewPosition.X - Width < Point.X)
          and (SpaceViewPosition.X + Width > Point.X)
          and (SpaceViewPosition.Y - Height < Point.Y)
          and (SpaceViewPosition.Y + Height > Point.Y);
end;

procedure TMeteoriteSE.PlaceRandomly;
var
  Radius: Single;
  Bound: Integer;
begin
  if Space <> nil then
  begin
    Radius := TProcessSE(Space.Process).SystemRadius;
    Bound := Round(Radius);
    SetPosition(MakePointF(RandomIntRange(-Bound, Bound), RandomIntRange(-Bound, Bound)));
  end;
end;

procedure TMeteoriteSE.RestartOutsideView;
var
  Radius: Single;
  Bound: Integer;
  StartPoint, EndPoint, Intersection: TPointF;
begin
  if Space <> nil then
  begin
    Radius := TProcessSE(Space.Process).SystemRadius;
    repeat
      Bound := Round(Radius);
      EndPoint := MakePointF(RandomIntRange(-Bound, Bound), RandomIntRange(-Bound, Bound));
      StartPoint :=
          MakePointF(
              EndPoint.X + Sin(Pi + Angle) * (Radius * 4),
              EndPoint.Y - Cos(Pi + Angle) * (Radius * 4)
          );
    until SegmentIntersectsRectEdges(
            StartPoint,
            EndPoint,
            MakePointF(-Radius * 1.2, -Radius * 1.2),
            MakePointF(1.2 * Radius, 1.2 * Radius),
            Intersection)
        and not IsNearView(Intersection);
    SetPosition(Intersection);
  end;
end;

procedure TMeteoriteSE.AdvanceMotion(Timer: PSpaceTimerSE; UserData: Integer);
var
  Limit: Single;
begin
  SetPosition(MakePointF(Position.X + Sin(Angle) * Speed, Position.Y - Cos(Angle) * Speed));
  Limit := TProcessSE(Space.Process).SystemRadius * 1.3;
  if ((-Limit > Position.X)
          or (Position.X > Limit)
          or (-Limit > Position.Y)
          or (Position.Y > Limit))
      and not IsNearView(Position) then
    RestartOutsideView;
end;

procedure TMeteoriteSE.LoadTemplate(Block: TBlockParEC);
var
  Range: TPointF;
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  TimerInterval := ExtractDigitsToIntW(Block.GetParam('Time'));
  Range := GetFloatPointGI(Block.GetParam('Speed'));
  Speed := RandomFloatRange(Range.X, Range.Y);
  Angle := HeadingDegreesToRadians(ExtractDecimalToSingleW(Block.GetParam('Angle')));
end;

procedure TMeteoriteSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

end.
