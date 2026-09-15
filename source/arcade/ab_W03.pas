{$EXCESSPRECISION OFF}
unit ab_W03;
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
  TabW03 = class;
  TabW03 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Exploding: Boolean;
    GapB9: array[0..2] of Byte;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer; Offset: Single);
    procedure Explode;
  end;
var
  ProjectileCount: Integer = 0;
procedure LinkRecoveredTypes;
implementation
uses
  Math;

constructor TabW03.Create;
var
  Obj: TabObject;
begin
  inherited Create;
  MaxSpeed := 12;
  Mass := 1;
  Thrust := 1;
  CollisionRadius := 1;
  Collidable := False;
  Inc(ProjectileCount);
  if ProjectileCount > 30 then
  begin
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if (Obj is TabW03) and not TabW03(Obj).Exploding then
      begin
        (Obj as TabW03).Explode;
        Break;
      end;
      Obj := Obj.Next;
    end;
  end;
end;

destructor TabW03.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  Dec(ProjectileCount);
  inherited Destroy;
end;

procedure TabW03.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  if Offset <> 0 then
    State := AdvanceSphericalStateOnCurrentSphere(State, Offset);
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w03_f', 'GAI,Bm.AB.w03_s', False);
  ab_WorldImage_SetFrameMode(Image, afmRandomStart);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW03.Explode;
begin
  Exploding := True;
  ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w03a_f', 'GAI,Bm.AB.w03a_s');
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  ab_WorldImage_SetLooping(Image, False);
end;

procedure TabW03.Advance;
var
  Collision: TabObject;
begin
  inherited Advance;
  if not Exploding then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  if DistanceTravelled > 500 then
    MaxSpeed := 8;
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 500) and (Collision = SourceObject) then
      Collision := nil;
  end;
  if (Collision <> nil) and not Exploding then
  begin
    if Collision <> nil then
    begin
      Collision.Velocity := MakePointF(Velocity.X / 2, Velocity.Y / 2);
      Collision.ApplyDamage(Damage, SourceObject, False);
    end;
    Explode;
  end
  else if Exploding then
    DeletionPending := Image.Finished;
end;

procedure TabW03.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

procedure LinkRecoveredTypes;
begin
  TabW03.ClassName;
end;
end.
