{$EXCESSPRECISION OFF}
unit ab_W08;
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
  TabW08 = class;
  TabW08 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Exploding: Boolean;
    GapB9: array[0..2] of Byte;
    Generation: Integer;
    ExpireTick: Integer;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(
        Owner: TabObject;
        Amount: Integer;
        Angle: Single;
        AGeneration: Integer;
        Origin: TabObject
    );
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  ab_Ship,
  GlobalsV,
  aMyFunction;

constructor TabW08.Create;
begin
  inherited Create;
  MaxSpeed := 100;
  Mass := 1;
  Thrust := 0.8;
  CollisionRadius := 5;
  Collidable := False;
end;

destructor TabW08.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;

procedure TabW08.Launch(
    Owner: TabObject;
    Amount: Integer;
    Angle: Single;
    AGeneration: Integer;
    Origin: TabObject
);
begin
  SourceObject := Owner;
  Damage := Amount;
  if Origin <> nil then
    State := Origin.State
  else
    State := Owner.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  if Owner <> nil then
    Velocity := Owner.Velocity
  else if Origin <> nil then
    Velocity := Origin.Velocity
  else
    Velocity := MakePointF(0, 0);
  Generation := AGeneration;
  if Generation = 0 then
    ExpireTick := ArcadeTickCount + 30
  else
    ExpireTick := ArcadeTickCount + 15;
  if Generation = 0 then
  begin
    Image :=
        ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w08_f', 'GAI,Bm.AB.w08_s', False);
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  end
  else
  begin
    Image :=
        ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w08b_f', 'GAI,Bm.AB.w08b_s', False);
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  end;
end;

procedure TabW08.Advance;
var
  Collision: TabObject;
  Child: TabW08;
begin
  inherited Advance;
  if not Exploding then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 200) and (Collision = SourceObject) then
      Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and not Exploding then
  begin
    if Collision <> nil then
      Collision.ApplyDamage(Damage, SourceObject, False)
    else if Generation <= 1 then
    begin
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(
          SourceObject as TabShip,
          Damage div 3,
          RandomIntRange(0, 360),
          Generation + 1,
          Self
      );
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(
          SourceObject as TabShip,
          Damage div 3,
          RandomIntRange(0, 360),
          Generation + 1,
          Self
      );
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(
          SourceObject as TabShip,
          Damage div 3,
          RandomIntRange(0, 360),
          Generation + 1,
          Self
      );
    end;
    Exploding := True;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w08a_f', 'GAI,Bm.AB.w08a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if Exploding then
    DeletionPending := Image.Finished;
end;

procedure TabW08.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
end;
end.
