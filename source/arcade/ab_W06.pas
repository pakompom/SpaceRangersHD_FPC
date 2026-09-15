{$EXCESSPRECISION OFF}
unit ab_W06;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_Tail,
  ab_Global,
  ab_Object,
  ab_WorldImage;
type
  TabW06 = class;
  TabW06 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Exploding: Boolean;
    GapB9: array[0..2] of Byte;
    ExpireTick: Integer;
    TurnSpeed: Single;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer; Offset: Single);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  ab_Ship,
  GlobalsV;

constructor TabW06.Create;
begin
  inherited Create;
  MaxSpeed := 100;
  Mass := 1;
  Thrust := 1.2;
  CollisionRadius := 1;
  Collidable := False;
  TurnSpeed := 10;
end;

destructor TabW06.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;

procedure TabW06.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
var
  Heading, HeadingDelta: Double;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 20;
  if Offset <> 0 then
  begin
    Heading := WrapHeadingDegrees(State.BearingDegrees + 90);
    HeadingDelta := HeadingDifferenceDegrees(Heading, State.BearingDegrees);
    AdvanceSphericalBearingState(
        State.LongitudeDegrees,
        State.PolarAngleDegrees,
        Heading,
        SphereRadius,
        Offset
    );
    State.BearingDegrees := WrapHeadingDegrees(Heading + HeadingDelta);
  end;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w06_f', 'GAI,Bm.AB.w06_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW06.Advance;
var
  Collision: TabObject;
  Enemy: TabShip;
  Bearing: TSphericalBearingDistance;
begin
  inherited Advance;
  if not Exploding then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if Collision = SourceObject then
      Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and not Exploding then
  begin
    if Collision <> nil then
      Collision.ApplyDamage(Damage, SourceObject, False);
    Exploding := True;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w06a_f', 'GAI,Bm.AB.w06a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if not Exploding and (Collision = nil) then
  begin
    if SourceObject <> nil then
    begin
      Enemy := SourceObject as TabShip;
      Enemy := Enemy.FindNearestEnemyWithBearing(Self, Bearing);
      if Enemy <> nil then
        if Bearing.Distance < 400 then
        begin
          if Bearing.BearingDeltaDegrees < -TurnSpeed then
            Bearing.BearingDeltaDegrees := -TurnSpeed
          else if Bearing.BearingDeltaDegrees > TurnSpeed then
            Bearing.BearingDeltaDegrees := TurnSpeed;
          State.BearingDegrees := State.BearingDegrees + Bearing.BearingDeltaDegrees;
        end;
    end;
  end
  else if Exploding then
    DeletionPending := Image.Finished;
end;

procedure TabW06.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
end;
end.
