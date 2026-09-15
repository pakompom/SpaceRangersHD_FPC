{$EXCESSPRECISION OFF}
unit ab_W09;
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
  TabW09 = class;
  TabW09 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Phase: Integer;
    ExpireTick: Integer;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer);
    procedure LaunchChild(Parent: TabW09; Angle: Single);
  end;
implementation
uses
  Math,
  aMyFunction,
  ab_Ship,
  GlobalsV;

constructor TabW09.Create;
begin
  inherited Create;
  MaxSpeed := 12;
  Mass := 1;
  Thrust := 1;
  CollisionRadius := 5;
  Collidable := False;
end;

destructor TabW09.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;

procedure TabW09.Launch(Owner: TabObject; Amount: Integer);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 120;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w09_f', 'GAI,Bm.AB.w09_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW09.LaunchChild(Parent: TabW09; Angle: Single);
begin
  SourceObject := Parent.SourceObject;
  Damage := Parent.Damage div 20;
  State := Parent.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  Velocity := MakePointF(0, 0);
  MaxSpeed := 100;
  Thrust := 2.5;
  Phase := 2;
  ExpireTick := ArcadeTickCount + 20;
  Image :=
      ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w09b_f', 'GAI,Bm.AB.w09b_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW09.Advance;
var
  Index: Integer;
  Collision: TabObject;
  Enemy: TabShip;
  Child: TabW09;
begin
  inherited Advance;
  if (Phase <> 1) and (Phase <> 3) then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  if (Phase = 0) and (DistanceTravelled > 100) then
    MaxSpeed := 13;
  if (Phase = 0) and (DistanceTravelled > 300) then
    MaxSpeed := 8;
  Collision := nil;
  if (Phase <> 1) and (Phase <> 3) then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 200) and (Phase = 0) and (Collision = SourceObject) then
      Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and (Phase <> 1) and (Phase <> 3) then
  begin
    if Collision <> nil then
      Collision.ApplyDamage(Damage, SourceObject, False);
    if Phase = 0 then
    begin
      Phase := 1;
      ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w09a_f', 'GAI,Bm.AB.w09a_s');
      ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Image, False);
    end
    else
    begin
      Phase := 3;
      ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w09c_f', 'GAI,Bm.AB.w09c_s');
      ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Image, False);
    end;
  end
  else if (Phase = 0) and (ArcadeTickCount mod 3 = 0) and (SourceObject <> nil) then
  begin
    for Index := 0 to TabShip(SourceObject).Enemies.Count - 1 do
    begin
      Enemy := TabShip(SourceObject).Enemies[Index];
      with BearingAndDistanceTo(Enemy) do
        if (Distance < 400) and (Enemy.Health > 0) then
        begin
          Child := TabW09.Create;
          ab_Object_Add(Child);
          Child.LaunchChild(Self, BearingDeltaDegrees);
        end;
    end;
  end
  else if (Phase = 1) or (Phase = 3) then
    DeletionPending := Image.Finished;
end;

procedure TabW09.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

end.
