{$EXCESSPRECISION OFF}
unit ab_W11;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Struct,
  GI_Tail,
  ab_Global,
  ab_Object,
  ab_WorldImage;
type
  TabW11 = class;
  TabW11 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Exploding: Boolean;
    GapB9: array[0..6] of Byte;
    LastTrailPosition: TVector3D;
    ExpireTick: Integer;
    TurnSpeed: Single;
    TrailImages: TList;
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

constructor TabW11.Create;
begin
  inherited Create;
  MaxSpeed := 40;
  TurnSpeed := 0.2;
  Mass := 1;
  Thrust := 0.8;
  CollisionRadius := 5;
  Collidable := False;
  TrailImages := TList.Create;
end;

destructor TabW11.Destroy;
var
  Index: Integer;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  if TrailImages <> nil then
  begin
    for Index := 0 to TrailImages.Count - 1 do
      ab_WorldImage_Delete(TrailImages[Index]);
    TrailImages.Free;
    TrailImages := nil;
  end;
  inherited Destroy;
end;

procedure TabW11.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
var
  Heading, HeadingDelta: Double;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  LastTrailPosition := GetWorldPosition;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 70;
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
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w11_f', 'GAI,Bm.AB.w11_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW11.Advance;
var
  Collision: TabObject;
  Enemy: TabShip;
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
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w11b_f', 'GAI,Bm.AB.w11b_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if not Exploding and (Collision = nil) then
  begin
    if SourceObject <> nil then
    begin
      Enemy := SourceObject as TabShip;
      Enemy := Enemy.FindNearestEnemy(Self);
      if Enemy <> nil then
        with BearingAndDistanceTo(Enemy) do
        begin
          if BearingDeltaDegrees < -TurnSpeed then
            BearingDeltaDegrees := -TurnSpeed
          else if BearingDeltaDegrees > TurnSpeed then
            BearingDeltaDegrees := TurnSpeed;
          State.BearingDegrees := State.BearingDegrees + BearingDeltaDegrees;
        end;
    end;
  end
  else if Exploding then
    DeletionPending := Image.Finished;
end;

procedure TabW11.UpdateVisuals;
var
  Entry: PabWorldImage;
  Index, Sample: Integer;
  Position, TrailPosition, Delta: TVector3D;
begin
  inherited UpdateVisuals;
  if not Exploding then
  begin
    Position := GetWorldPosition;
    Delta.X := -(LastTrailPosition.X - Position.X) / 4;
    Delta.Y := -(LastTrailPosition.Y - Position.Y) / 4;
    Delta.Z := -(LastTrailPosition.Z - Position.Z) / 4;
    for Sample := 0 to 3 do
    begin
      Entry := nil;
      for Index := 0 to TrailImages.Count - 1 do
      begin
        Entry := TrailImages[Index];
        if Entry.Finished then
          Break;
        Entry := nil;
      end;
      TrailPosition :=
          MakeVector3D(
              Sample * Delta.X + Position.X,
              Sample * Delta.Y + Position.Y,
              Sample * Delta.Z + Position.Z
          );
      if Entry = nil then
      begin
        Entry := ab_WorldImage_Create(TrailPosition, 'GAI,Bm.AB.w11a_f', 'GAI,Bm.AB.w11a_s', False);
        ab_WorldImage_SetLooping(Entry, False);
        ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
        TrailImages.Add(Entry);
      end
      else
      begin
        ab_WorldImage_Set(Entry, TrailPosition, 'GAI,Bm.AB.w11a_f', 'GAI,Bm.AB.w11a_s');
        ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
        ab_WorldImage_SetLooping(Entry, False);
      end;
    end;
    LastTrailPosition := Position;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
end;
end.
