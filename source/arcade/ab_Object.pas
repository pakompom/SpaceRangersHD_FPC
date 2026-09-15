{$EXCESSPRECISION OFF}
unit ab_Object;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Struct,
  GI_MessageLoop,
  GI_Tail,
  ab_Global,
  GR_Sound;
type
  TabObject = class;
  TabObject = class(TObjectEx)
    Prev: TabObject;
    Next: TabObject;
    GapC: array[0..3] of Byte;
    State: TSphericalBearingState;
    Mass: Double;
    Thrust: Double;
    Velocity: TPointF;
    MaxSpeed: Double;
    SpeedScale: Double;
    DistanceTravelled: Double;
    CollisionRadius: Double;
    Collidable: Boolean;
    Gap61: array[0..6] of Byte;
    ZoneRadius: Double;
    DeletionPending: Boolean;
    WallCollisionEnabled: Boolean;
    GravityEnabled: Boolean;
    ZoneDamageEnabled: Boolean;
    Active: Boolean;
    Gap75: array[0..2] of Byte;
    SourceObject: TabObject;
    InitialRandomSeed: Cardinal;
    RandomState: Cardinal;
    SoundDelay: Integer;
    SoundPath: WideString;
    SoundGroup: Integer;
    Sound: TSoundBufferControl;
    WeaponDamageScale: Single;
    AmmoRechargeScale: Single;
    MovementScale: Single;
    GravityScale: Single;
    RegenerationRate: Single;
    DamageTakenScale: Single;
    LuckScale: Single;
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); virtual;
    procedure UpdateState; virtual;
    procedure Advance; virtual;
    procedure UpdateVisuals; virtual;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); virtual;
    constructor Create;
    destructor Destroy; override;
    function GetWorldPosition: TVector3D;
    function GetProjectedPosition: TVector3D;
    function DistanceTo(Other: TabObject): Double;
    function BearingAndDistanceTo(Other: TabObject): TSphericalBearingDistance;
    function GetProjectedHeading(Position: TVector3D): Double;
    procedure ChangeSpeed(Delta: Double);
    function CollidesWith(Other: TabObject): Boolean;
    function FindCollision: TabObject;
    function RandomRange(BoundA: Integer; BoundB: Integer): Integer;
  end;
var
  FirstArcadeObject: TabObject = nil;
  LastArcadeObject: TabObject = nil;
procedure ab_Object_Clear;
procedure ab_Object_Add(Obj: TabObject);
procedure ab_Object_Delete(Obj: TabObject);
procedure ab_Object_QueueImageLoads(PendingLoads: TList; Owner: TObjectGI);
procedure ab_Object_UpdateSounds;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  Globals,
  GlobalsV,
  ab_Hit,
  ab_Ship,
  ab_ShipAI,
  ab_Zone,
  ab_StopLine;

constructor TabObject.Create;
begin
  inherited Create;
  MaxSpeed := 5;
  SpeedScale := 1;
  DistanceTravelled := 0;
  WallCollisionEnabled := False;
  GravityEnabled := False;
  ZoneDamageEnabled := False;
  Active := True;
  Collidable := True;
  SoundDelay := -1;
  InitialRandomSeed := AdvanceRandomSeed(ArcadeBattleScreen.RandomSeed);
  RandomState := InitialRandomSeed;
  WeaponDamageScale := 1;
  AmmoRechargeScale := 1;
  MovementScale := 1;
  GravityScale := 1;
  RegenerationRate := 0;
  DamageTakenScale := 1;
  LuckScale := 1;
end;

destructor TabObject.Destroy;
var
  Obj: TabObject;
begin
  if Sound <> nil then
  begin
    Sound.Free;
    Sound := nil;
  end;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj.SourceObject = Self then
      Obj.SourceObject := nil;
    Obj := Obj.Next;
  end;
  inherited Destroy;
end;

function TabObject.GetWorldPosition: TVector3D;
begin
  Result :=
      SphericalToVector3D(
          HeadingDegreesToRadians(State.LongitudeDegrees),
          HeadingDegreesToRadians(State.PolarAngleDegrees),
          SphereRadius
      );
end;

function TabObject.GetProjectedPosition: TVector3D;
begin
  Result := GetWorldPosition;
  Result := ProjectPointByMatrix(SphereProjectionMatrix, Result);
end;

function TabObject.DistanceTo(Other: TabObject): Double;
var
  ArcAngle, TargetPolar, SourcePolar, LongitudeDelta, Value: Double;
begin
  TargetPolar := HeadingDegreesToRadians(Other.State.PolarAngleDegrees);
  SourcePolar := HeadingDegreesToRadians(State.PolarAngleDegrees);
  LongitudeDelta :=
      HeadingDegreesToRadians(
          WrapHeadingDegrees(Other.State.LongitudeDegrees - State.LongitudeDegrees)
      );
  Value :=
      Cos(TargetPolar) * Cos(SourcePolar)
          + Sin(TargetPolar) * Sin(SourcePolar) * Cos(LongitudeDelta);
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  ArcAngle := ArcCos(Value);
  Result := ArcAngle / (2 * Pi) * 2 * Pi * SphereRadius;
end;

function TabObject.BearingAndDistanceTo(Other: TabObject): TSphericalBearingDistance;
begin
  Result := GetSphericalBearingAndDistance(State, Other.State);
end;

function TabObject.GetProjectedHeading(Position: TVector3D): Double;
var
  ForwardState: TSphericalBearingState;
  ForwardPosition: TVector3D;
begin
  ForwardState := State;
  ForwardState := AdvanceSphericalStateOnCurrentSphere(ForwardState, 10);
  ForwardPosition :=
      SphericalToVector3D(
          HeadingDegreesToRadians(ForwardState.LongitudeDegrees),
          HeadingDegreesToRadians(ForwardState.PolarAngleDegrees),
          SphereRadius
      );
  ForwardPosition := ProjectPointByMatrix(SphereProjectionMatrix, ForwardPosition);
  if (Position.X = ForwardPosition.X) and (Position.Y = ForwardPosition.Y) then
  begin
    Result := 0;
    Exit;
  end;
  Result :=
      PointBearingDegrees(
          MakePointF(Position.X, Position.Y),
          MakePointF(ForwardPosition.X, ForwardPosition.Y)
      );
end;

procedure TabObject.ChangeSpeed(Delta: Double);
var
  Speed, Angle: Double;
begin
  Speed := Sqrt(Sqr(Velocity.X) + Sqr(Velocity.Y));
  if Speed = 0 then
    Exit;
  Angle := Math.ArcTan2(Velocity.X, -Velocity.Y);
  Speed := Max(0, Speed + Delta);
  Velocity.X := Sin(Angle) * Speed;
  Velocity.Y := -Cos(Angle) * Speed;
end;

function TabObject.CollidesWith(Other: TabObject): Boolean;
begin
  if (CollisionRadius <= 0) or (Other.CollisionRadius <= 0) then
  begin
    Result := False;
    Exit;
  end;
  if (not Collidable) and (not Other.Collidable) then
  begin
    Result := False;
    Exit;
  end;
  if (Other is TabHit) and ((Other as TabHit).Health <= 0) then
  begin
    Result := False;
    Exit;
  end;
  Result := CollisionRadius + Other.CollisionRadius >= DistanceTo(Other);
end;

function TabObject.FindCollision: TabObject;
var
  Obj: TabObject;
begin
  if (ArcadeTickCount and 1) <> 0 then
  begin
    Result := nil;
    Exit;
  end;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if (Obj <> Self) and CollidesWith(Obj) then
    begin
      Result := Obj;
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Result := nil;
end;

procedure TabObject.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
begin
end;

procedure TabObject.UpdateState;
begin
end;

procedure TabObject.Advance;
var
  Force: TPointF;
  TravelBearing, ArcDistance, HeadingDelta, ReflectedSpeed: Double;
  Factor, Limit: Single;
  Zone: PabZone;
  Bearing, Distance, UnusedResult: Double;
begin
  Force := MakePointF(0, 0);
  if Thrust <> 0 then
  begin
    Force.X :=
        Force.X + Sin(HeadingDegreesToRadians(State.BearingDegrees)) * Thrust * MovementScale;
    Force.Y :=
        Force.Y - Cos(HeadingDegreesToRadians(State.BearingDegrees)) * Thrust * MovementScale;
  end;
  if GravityEnabled then
  begin
    Zone := ab_Zone_FindNearestEnabled(State.LongitudeDegrees, State.PolarAngleDegrees);
    if Zone <> nil then
    begin
      ComputeSphericalBearingAndDistance(
          Bearing,
          Distance,
          State.LongitudeDegrees,
          State.PolarAngleDegrees,
          0,
          Zone.Longitude,
          Zone.PolarAngle,
          SphereRadius
      );
      Limit := 2;
      if PlayerArcadeShip = Self then
        if Sqr(Velocity.X) + Sqr(Velocity.Y) > Sqr(2.0) then
          Limit := 8;
      if Zone.GravityStrength < 0 then
        Factor := -Min(Limit / 2, Abs(Zone.GravityStrength) * Mass / (Sqr(Distance) + 0.1))
      else
        Factor := Min(Limit, Abs(Zone.GravityStrength) * Mass / (Sqr(Distance) + 0.1));
      Bearing := HeadingDegreesToRadians(WrapHeadingDegrees(Bearing));
      Force.X := Force.X + Sin(Bearing) * Factor * GravityScale;
      Force.Y := Force.Y - Cos(Bearing) * Factor * GravityScale;
    end;
  end;
  if ZoneDamageEnabled and ((Self as TabHit).Health > 0) then
  begin
    Zone := FirstZone;
    while Zone <> nil do
    begin
      if Zone.DamagePerTick <> 0 then
      begin
        ComputeSphericalBearingAndDistance(
            Bearing,
            Distance,
            Zone.Longitude,
            Zone.PolarAngle,
            0,
            State.LongitudeDegrees,
            State.PolarAngleDegrees,
            SphereRadius
        );
        if Zone.Radius + ZoneRadius + 5 > Distance then
        begin
          if Zone.DamagePerTick < 0 then
          begin
            (Self as TabHit).Health :=
                Min((Self as TabHit).MaxHealth, (Self as TabHit).Health + -Zone.DamagePerTick);
          end
          else
          begin
            ApplyDamage(Zone.DamagePerTick, nil, False);
            if Self is TabShipAI then
              (Self as TabShipAI).NoticeDamagingZone(Zone);
          end;
        end;
      end;
      Zone := Zone.Next;
    end;
  end;
  Factor := 1 / Mass;
  Velocity.X := Velocity.X + Force.X * Factor;
  Velocity.Y := Velocity.Y + Force.Y * Factor;
  ArcDistance := Sqrt(Sqr(Velocity.X) + Sqr(Velocity.Y));
  if MaxSpeed * SpeedScale < ArcDistance then
    ArcDistance := MaxSpeed * SpeedScale;
  ArcDistance :=
      Max(
          0,
          ArcDistance
              - RemapClamped(ArcDistance, 0, MaxSpeed, SphereLowSpeedDrag, SphereHighSpeedDrag)
      );
  TravelBearing := PointBearingDegrees(MakePointF(0, 0), Velocity);
  if PlayerArcadeShip = Self then
  begin
    PlayerArcadeShip.TurnSpeed :=
        RemapClamped(ArcDistance, 0, MaxSpeed, PlayerSlowTurnSpeed, PlayerFastTurnSpeed);
    Limit := PlayerDriftTurnStep;
    Factor := HeadingDifferenceDegrees(TravelBearing, State.BearingDegrees);
    if Abs(Factor) < 90 then
    begin
      if -Limit > Factor then
        TravelBearing := WrapHeadingDegrees(TravelBearing - Limit)
      else if Factor > Limit then
        TravelBearing := WrapHeadingDegrees(TravelBearing + Limit);
    end
    else
    begin
      Factor :=
          HeadingDifferenceDegrees(TravelBearing, WrapHeadingDegrees(State.BearingDegrees + 180));
      if -Limit > Factor then
        TravelBearing := WrapHeadingDegrees(TravelBearing - Limit)
      else if Factor > Limit then
        TravelBearing := WrapHeadingDegrees(TravelBearing + Limit);
    end;
  end;
  if ArcDistance <> 0 then
  begin
    if WallCollisionEnabled then
    begin
      if ab_StopLine_ReflectMovement(
          State,
          AdvanceSphericalStateAlongBearing(State, TravelBearing, ArcDistance),
          HeadingDelta,
          ReflectedSpeed,
          UnusedResult) then
      begin
        ArcDistance := ReflectedSpeed;
        TravelBearing := WrapHeadingDegrees(TravelBearing + HeadingDelta);
      end;
      State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + UnusedResult);
    end;
    if ArcDistance > 0 then
    begin
      State := AdvanceSphericalStateAndTravelBearing(State, TravelBearing, ArcDistance);
      DistanceTravelled := DistanceTravelled + ArcDistance;
      Velocity.X := Sin(HeadingDegreesToRadians(TravelBearing)) * ArcDistance;
      Velocity.Y := -Cos(HeadingDegreesToRadians(TravelBearing)) * ArcDistance;
    end
    else
    begin
      Velocity.X := 0;
      Velocity.Y := 0;
    end;
  end
  else
  begin
    Velocity.X := 0;
    Velocity.Y := 0;
  end;
end;

procedure TabObject.UpdateVisuals;
begin
end;

procedure TabObject.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;

function TabObject.RandomRange(BoundA, BoundB: Integer): Integer;
begin
  RandomState := 16807 * (RandomState mod 127773) - 2836 * (RandomState div 127773);
  Result := Integer(RandomState) - 1;
  if Result < 0 then
    Result := -Result;
  if BoundA <= BoundB then
    Result := BoundA + Result mod (BoundB - BoundA + 1)
  else
    Result := BoundB + Result mod (BoundA - BoundB + 1);
end;

procedure ab_Object_Clear;
begin
  while not (FirstArcadeObject = nil) do
    ab_Object_Delete(LastArcadeObject);
end;

procedure ab_Object_Add(Obj: TabObject);
begin
  if LastArcadeObject <> nil then
    LastArcadeObject.Next := Obj;
  Obj.Prev := LastArcadeObject;
  Obj.Next := nil;
  LastArcadeObject := Obj;
  if FirstArcadeObject = nil then
    FirstArcadeObject := Obj;
end;

procedure ab_Object_Delete(Obj: TabObject);
begin
  if Obj.Prev <> nil then
    Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then
    Obj.Next.Prev := Obj.Prev;
  if LastArcadeObject = Obj then
    LastArcadeObject := Obj.Prev;
  if FirstArcadeObject = Obj then
    FirstArcadeObject := Obj.Next;
  Obj.Free;
end;

procedure ab_Object_QueueImageLoads(PendingLoads: TList; Owner: TObjectGI);
var
  Obj: TabObject;
begin
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    Obj.QueueImageLoad(PendingLoads, Owner);
    Obj := Obj.Next;
  end;
end;

procedure ab_Object_UpdateSounds;
var
  Obj: TabObject;
  Index: Integer;
  Playing, Closest: TabObject;
  BestDistance, Distance, Volume: Single;
  Counts: array[0..14] of Integer;
  Position: TVector3D;
begin
  for Index := 0 to 14 do
    Counts[Index] := 0;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj.SoundDelay > 0 then
      Dec(Obj.SoundDelay);
    if (Obj.SoundDelay = 0) and (Obj.SoundGroup >= 9000) and (Obj.SoundGroup <= 9014) then
      Inc(Counts[Obj.SoundGroup - 9000]);
    Obj := Obj.Next;
  end;
  for Index := 0 to 14 do
    if Counts[Index] > 0 then
    begin
      Closest := nil;
      Playing := nil;
      BestDistance := 1e20;
      Obj := FirstArcadeObject;
      while Obj <> nil do
      begin
        if (Obj.SoundDelay = 0) and (Index + 9000 = Obj.SoundGroup) then
        begin
          if Obj.Sound <> nil then
            Playing := Obj;
          Position := Obj.GetProjectedPosition;
          if IsDepthBeforeSphereHorizon(Position.Z) then
          begin
            Distance := Sqr(Position.X) + Sqr(Position.Y);
            if Distance < BestDistance then
            begin
              BestDistance := Distance;
              Closest := Obj;
            end;
          end;
        end;
        Obj := Obj.Next;
      end;
      if (Playing <> nil) and (Closest <> Playing) then
      begin
        Playing.Sound.Free;
        Playing.Sound := nil;
      end;
      if Closest <> nil then
      begin
        if Closest.Sound = nil then
        begin
          Closest.Sound := TSoundBufferControl.Create;
          Closest.Sound.Configure(Closest.SoundPath, Closest.SoundGroup, True);
        end;
        Volume := (Sqrt(BestDistance) - 100) * (1 / 300);
        if Volume < 0 then
          Volume := 0
        else if Volume > 1 then
          Volume := 1;
        Closest.Sound.SetVolume(1 - Volume);
      end;
    end;
end;

procedure LinkRecoveredTypes;
begin
  TabHit.ClassName;
  TabShipAI.ClassName;
end;
end.
