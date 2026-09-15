{$EXCESSPRECISION OFF}
unit ab_W14;
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
  TabW14 = class;
  TabW14 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Phase: Integer;
    ExpireTick: Integer;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer; Angle: Single);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  GlobalsV,
  ab_Ship;

constructor TabW14.Create;
begin
  inherited Create;
  MaxSpeed := 25;
  Mass := 1;
  Thrust := 1.5;
  CollisionRadius := 5;
  Collidable := True;
end;

destructor TabW14.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;

procedure TabW14.Launch(Owner: TabObject; Amount: Integer; Angle: Single);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 150;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w14_f', 'GAI,Bm.AB.w14_s', True);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW14.Advance;
var
  Collision: TabObject;
begin
  inherited Advance;
  if Phase <> 1 then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if Phase <> 1 then
  begin
    Collision := FindCollision;
    if (Collision <> nil)
        and (SourceObject <> nil)
        and (Collision is TabShip)
        and (TabShip(SourceObject).Enemies.IndexOf(Collision) < 0) then
      Collision := nil
    else if Collision = SourceObject then
      Collision := nil
    else if Collision is TabW14 then
      Collision := nil;
  end;
  { Native launch sets ExpireTick, but flight expires by half-circumference. }
  if ((DistanceTravelled > Pi * SphereRadius) or (Collision <> nil)) and (Phase <> 1) then
  begin
    if Collision <> nil then
      Collision.ApplyDamage(Damage, SourceObject, False);
    Phase := 1;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w14a_f', 'GAI,Bm.AB.w14a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if Phase = 1 then
    DeletionPending := Image.Finished;
end;

procedure TabW14.UpdateVisuals;
var
  Frame: Integer;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  if Phase = 0 then
  begin
    Position := GetWorldPosition;
    Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
    Frame :=
        Round(GetProjectedHeading(Position) / 360 * Image.Image.GaiImageControl.SequenceFrameCount);
    if Frame >= Image.Image.GaiImageControl.SequenceFrameCount then
      Frame := 0;
    Image.Image.GaiImageControl.SetSequenceFrame(Frame);
  end;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
  TabW14.ClassName;
end;
end.
