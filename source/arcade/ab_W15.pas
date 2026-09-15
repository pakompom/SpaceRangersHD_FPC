{$EXCESSPRECISION OFF}
unit ab_W15;
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
  TabW15 = class;
  TabW15 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Phase: Integer;
    TurnSpeed: Single;
    TurnBias: Single;
    ExpireTick: Integer;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer; Angle: Single);
    procedure Explode;
  end;
var
  W15ProjectileCount: Integer = 0;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GlobalsV,
  ab_Ship,
  aMyFunction;

constructor TabW15.Create;
var
  Obj: TabObject;
begin
  inherited Create;
  MaxSpeed := 12;
  Mass := 1;
  Thrust := 1.5;
  TurnSpeed := 1;
  CollisionRadius := 5;
  Collidable := True;
  Inc(W15ProjectileCount);
  if W15ProjectileCount > 50 then
  begin
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if (Obj is TabW15) and (TabW15(Obj).Phase <> 2) then
      begin
        (Obj as TabW15).Explode;
        Break;
      end;
      Obj := Obj.Next;
    end;
  end;
end;

destructor TabW15.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  Dec(W15ProjectileCount);
  inherited Destroy;
end;

procedure TabW15.Launch(Owner: TabObject; Amount: Integer; Angle: Single);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 1500;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w15_f', 'GAI,Bm.AB.w15_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW15.Explode;
begin
  Phase := 2;
  ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w15a_f', 'GAI,Bm.AB.w15a_s');
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  ab_WorldImage_SetLooping(Image, False);
end;

procedure TabW15.Advance;
var
  Collision: TabObject;
  Enemy: TabShip;
begin
  inherited Advance;
  if Phase <> 2 then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  if ArcadeTickCount mod 150 = 0 then
    TurnBias := RandomIntRange(25, 40) * (RandomIntRange(0, 1) * 2 - 1);
  Collision := nil;
  if Phase <> 2 then
  begin
    Collision := FindCollision;
    if (Collision <> nil)
        and (SourceObject <> nil)
        and (Collision is TabShip)
        and (TabShip(SourceObject).Enemies.IndexOf(Collision) < 0) then
      Collision := nil;
    if Collision = SourceObject then
      Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and (Phase <> 2) then
  begin
    if Collision <> nil then
      Collision.ApplyDamage(Damage, SourceObject, False);
    Phase := 2;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w15a_f', 'GAI,Bm.AB.w15a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if (Phase = 0) and (DistanceTravelled > 400) then
  begin
    MaxSpeed := 5;
    Phase := 1;
  end
  else if Phase = 1 then
  begin
    if SourceObject <> nil then
    begin
      Enemy := SourceObject as TabShip;
      Enemy := Enemy.FindNearestEnemy(Self);
      if Enemy <> nil then
        with BearingAndDistanceTo(Enemy) do
        begin
          BearingDeltaDegrees := BearingDeltaDegrees + TurnBias;
          if BearingDeltaDegrees < -TurnSpeed then
            BearingDeltaDegrees := -TurnSpeed
          else if BearingDeltaDegrees > TurnSpeed then
            BearingDeltaDegrees := TurnSpeed;
          State.BearingDegrees := State.BearingDegrees + BearingDeltaDegrees;
        end;
    end;
  end
  else if Phase = 2 then
    DeletionPending := Image.Finished;
end;

procedure TabW15.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
  TabW15.ClassName;
end;
end.
