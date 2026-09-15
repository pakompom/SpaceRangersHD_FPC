{$EXCESSPRECISION OFF}
unit ab_W01;
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
  TabW01 = class;
  TabW01 = class(TabObject)
    ValueB0: Single;
    Damage: Integer;
    Image: PabWorldImage;
    Exploding: Boolean;
    GapBD: array[0..2] of Byte;
    TrailDistance: Single;
    GapC4: array[0..3] of Byte;
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

constructor TabW01.Create;
begin
  inherited Create;
  MaxSpeed := 100;
  ValueB0 := 500;
  TurnSpeed := 4;
  Mass := 1;
  Thrust := 1.2;
  CollisionRadius := 1;
  Collidable := False;
  TrailImages := TList.Create;
end;

destructor TabW01.Destroy;
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

procedure TabW01.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
var
  Heading, HeadingDelta: Double;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  LastTrailPosition := GetWorldPosition;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 30;
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
  TrailDistance := 0;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w01_f', 'GAI,Bm.AB.w01_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW01.Advance;
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
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w01b_f', 'GAI,Bm.AB.w01b_s');
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

procedure TabW01.UpdateVisuals;
var
  Entry: PabWorldImage;
  Index: Integer;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  if not Exploding and (DistanceTravelled > TrailDistance) then
  begin
    TrailDistance := 0;
    Entry := nil;
    for Index := 0 to TrailImages.Count - 1 do
    begin
      Entry := TrailImages[Index];
      if Entry.Finished then
        Break;
      Entry := nil;
    end;
    if Entry = nil then
    begin
      Entry := ab_WorldImage_Create(GetWorldPosition, 'GAI,Bm.AB.w01a_f', '', False);
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
      TrailImages.Add(Entry);
    end
    else
    begin
      ab_WorldImage_Set(Entry, GetWorldPosition, 'GAI,Bm.AB.w01a_f', '');
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
    end;
    Entry := nil;
    for Index := 0 to TrailImages.Count - 1 do
    begin
      Entry := TrailImages[Index];
      if Entry.Finished then
        Break;
      Entry := nil;
    end;
    Position := GetWorldPosition;
    Position :=
        MakeVector3D(
            (Position.X + LastTrailPosition.X) / 2,
            (Position.Y + LastTrailPosition.Y) / 2,
            (Position.Z + LastTrailPosition.Z) / 2
        );
    if Entry = nil then
    begin
      Entry := ab_WorldImage_Create(Position, 'GAI,Bm.AB.w01a_f', '', False);
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
      TrailImages.Add(Entry);
    end
    else
    begin
      ab_WorldImage_Set(Entry, Position, 'GAI,Bm.AB.w01a_f', '');
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
    end;
    LastTrailPosition := GetWorldPosition;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TabShip.ClassName;
end;
end.
