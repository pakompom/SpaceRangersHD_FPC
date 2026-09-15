{$EXCESSPRECISION OFF}
unit ab_Global;

{$R-}
{$Q-}
{$B-}
{$A8}

interface

uses
  EC_Struct,
  SE_Process,
  EC_Buf,
  Types;

const

  abkRegeneration = 0;

  abkSpeed = 1;

  abkSlow = 2;

  abkWeaponLock = 3;

  abkDamage = 4;

  abkRecharge = 5;

  abkShield = 6;

  abkInvisibility = 7;

  ArcadeBonusKindMask = $FF;

  ArcadeHiddenBonusFlag = $80000000;

type

  TMatrix4D = array[0..3] of array[0..3] of Double;

  TSphericalBearingState = record
    LongitudeDegrees: Double;
    PolarAngleDegrees: Double;
    BearingDegrees: Double;
  end;

  TSphericalBearingDistance = record
    BearingDeltaDegrees: Double;
    Distance: Double;
  end;

var

  ArcadeViewMode: Byte = 0;

  ArcadeSpaceProcess: TProcessSE = nil;

  ArcadeTickCount: Integer;

  ArcadeFrameCount: Integer;

  ArcadeMapVersion: Cardinal;

  SphereViewState: TSphericalBearingState;

  SphereViewMatrix: TMatrix4D;

  SpherePerspectiveMatrix: TMatrix4D;

  SphereProjectionMatrix: TMatrix4D;

  ArcadeMapViewPosition: TPoint;

  ArcadeMapCenter: TPoint;

  ArcadeMapBounds: TRect;

  ArcadeGridMode: Integer;

  ArcadeMapColorBuffer: TBufEC;

  ArcadeAutopilotEnabled: Boolean;

  ArcadeEnemiesDefeated: Boolean;

  ArcadeLastInputTick: Integer;

  SphereRadius: Double = 1000;

  SphereCameraDistance: Double = 2300;

  SphereNearCameraOffset: Double = 1300;

  SphereFarCameraOffset: Double = 20000;

  SphereFieldOfView: Double = 88;

  CameraFollowStep: Double = 14;

  CameraLookAheadDistance: Double = 0;

  PlayerDriftTurnStep: Single = 1.8;

  PlayerInitialTurnSpeed: Single = 3.3;

  PlayerFastTurnSpeed: Single = 2.5;

  PlayerSlowTurnSpeed: Single = 3.8;

  SphereLowSpeedDrag: Single = 0.007;

  SphereHighSpeedDrag: Single = 0.18;

  ArcadeMapNodeRadius: Integer = 60;

  ArcadeMapPanMargin: Integer = 200;

  ArcadePathStep: Single = 4;

  ArcadePathArcStep: Single = 4;

  SphereProjectedRadius: Single = 1;

  SphereNearHorizonDepth: Single = -1;

  SphereHorizonDepth: Single = 0;

  SphereFarHorizonDepth: Single = 1;

  ShipFrontDepth: Single = 20;

  ShipBackDepth: Single = 30;

  ShipTailFrontDepth: Single = 21;

  ShipTailBackDepth: Single = 31;

  ItemFrontDepth: Single = 21;

  HitFrontDepth: Single = 19;

  HitBackDepth: Single = 29;

  WorldImageFrontDepth: Single = 22;

  WorldImageBackDepth: Single = 28;

  ExplosionFrontDepth: Single = 18;

  ExplosionBackDepth: Single = 28;

  ArcadeMapPalette: array[0..35] of Cardinal = (
      $FF28AC00,
      $8028AC00,
      $C028AC00,
      $0028AC00,
      $C028AC00,
      $C0FFFFFF,
      $FF003CFF,
      $80003CFF,
      $C0003CFF,
      $00003CFF,
      $C0003CFF,
      $C0FFFFFF,
      $FFFFFF00,
      $80FFFF00,
      $C0FFFF00,
      $00FFFF00,
      $C0FFFF00,
      $C0FFFFFF,
      $FFFFA636,
      $80FFA636,
      $C0FFA636,
      $00FFA636,
      $C0FFA636,
      $C0FFFFFF,
      $FFC80000,
      $80C80000,
      $C0C80000,
      $00C80000,
      $C0C80000,
      $C0FFFFFF,
      $FFA6002B,
      $80A6002B,
      $C0A6002B,
      $00A6002B,
      $C0A6002B,
      $C0FFFFFF
  );

  BonusRespawnSeconds: array[0..5] of Integer = (40, 60, 80, 100, 100, 150);

  BonusDurationSeconds: array[0..7] of Integer = (12, 50, 40, 50, 40, 50, 60, 60);

  RegenerationHealthPerTick: Integer = 1;

  SpeedBonusScale: Single = 1.2;

  SpeedPenaltyScale: Single = 0.7;

  WeaponDamageBonusScale: Single = 1.5;

  AmmoRechargeBonusScale: Single = 2;

  ShieldDamageScale: Single = 0.4;

  OtherInvisibleAlpha: Single = 0.2;

  PlayerInvisibleAlpha: Single = 0.5;

  RevealAfterFiringMs: Integer = 5500;

  WeaponSwitchDelayMs: Integer = 1200;

  ArcadeHighDangerThreshold: Single = 70;

  ManualCargoPickupDistance: Single = 200;

  CargoPickupDistance: Single = 80;

function MakeSphericalBearingState(
    LongitudeDegrees: Double;
    PolarAngleDegrees: Double;
    BearingDegrees: Double
): TSphericalBearingState;

function SphericalToVector3D(
    LongitudeRadians: Double;
    PolarAngleRadians: Double;
    Radius: Double
): TVector3D;

procedure VectorToSphericalAngles(
    Vector: TVector3D;
    var LongitudeDegrees: Double;
    var PolarAngleDegrees: Double
);

procedure AdvanceSphericalBearingState(
    var LongitudeDegrees: Double;
    var PolarAngleDegrees: Double;
    var BearingDegrees: Double;
    SphereRadius: Double;
    ArcDistance: Double
);

function AdvanceSphericalStateOnCurrentSphere(
    Source: TSphericalBearingState;
    ArcDistance: Double
): TSphericalBearingState;

function AdvanceSphericalStateAlongBearing(
    Source: TSphericalBearingState;
    TravelBearingDegrees: Double;
    ArcDistance: Double
): TSphericalBearingState;

function AdvanceSphericalStateAndTravelBearing(
    Source: TSphericalBearingState;
    var TravelBearingDegrees: Double;
    ArcDistance: Double
): TSphericalBearingState;

procedure ComputeSphericalBearingAndDistance(
    var BearingDeltaDegrees: Double;
    var Distance: Double;
    SourceLongitudeDegrees: Double;
    SourcePolarAngleDegrees: Double;
    SourceBearingDegrees: Double;
    TargetLongitudeDegrees: Double;
    TargetPolarAngleDegrees: Double;
    SphereRadius: Double
);

procedure ComputeSphericalDistance(
    var Distance: Double;
    SourceLongitudeDegrees: Double;
    SourcePolarAngleDegrees: Double;
    UnusedSourceBearingDegrees: Double;
    TargetLongitudeDegrees: Double;
    TargetPolarAngleDegrees: Double;
    SphereRadius: Double
);

function GetSphericalBearingAndDistance(
    Source: TSphericalBearingState;
    Target: TSphericalBearingState
): TSphericalBearingDistance;

procedure UpdateSphereProjectionMetrics;

function IsDepthBeforeSphereHorizon(ProjectedDepth: Double): Boolean;

function NormalizeVector3D(const Source: TVector3D): TVector3D;

function CrossProduct3D(const A: TVector3D; const B: TVector3D): TVector3D;

function DotProduct3D(const A: TVector3D; const B: TVector3D): Double;

procedure ClearMatrix4D(var Matrix: TMatrix4D);

procedure SetIdentityMatrix4D(var Matrix: TMatrix4D);

function BuildZAxisRotationMatrix(AngleRadians: Double): TMatrix4D;

function BuildPerspectiveProjectionMatrix(
    NearPlane: Double;
    FarPlane: Double;
    FovRadians: Double;
    ProjectionScale: Double
): TMatrix4D;

function BuildLookAtMatrix(
    const CameraPos: TVector3D;
    const TargetPos: TVector3D;
    const UpVector: TVector3D
): TMatrix4D;

function InvertMatrix4D(const Matrix: TMatrix4D): TMatrix4D;

function MultiplyMatrix4D(const Left: TMatrix4D; const Right: TMatrix4D): TMatrix4D;

function ProjectPointByMatrix(const Matrix: TMatrix4D; const Source: TVector3D): TVector3D;

function TryIntersectRayWithSphere(
    RayOrigin: TVector3D;
    RayPointOnRay: TVector3D;
    SphereCenter: TVector3D;
    SphereRadius: Double;
    var HitPoint: TVector3D
): Boolean;

implementation

uses
  Math,
  aMyFunction,
  GR_Main;

{ @routine $4EC5A4 MakeSphericalBearingState }
function MakeSphericalBearingState(
    LongitudeDegrees,
    PolarAngleDegrees,
    BearingDegrees: Double
): TSphericalBearingState;
begin
  Result.LongitudeDegrees := LongitudeDegrees;
  Result.PolarAngleDegrees := PolarAngleDegrees;
  Result.BearingDegrees := BearingDegrees;
end;
{ @end $4EC5A4 }

{ @routine $4EC5DC SphericalToVector3D }
function SphericalToVector3D(LongitudeRadians, PolarAngleRadians, Radius: Double): TVector3D;
var
  V: TVector3D;
begin
  V.X := Sin(PolarAngleRadians) * Radius;
  V.Y := -Cos(PolarAngleRadians) * Radius;
  V.Z := 0;
  Result.X := Sin(LongitudeRadians) * V.X;
  Result.Y := V.Y;
  Result.Z := -Cos(LongitudeRadians) * V.X;
end;
{ @end $4EC5DC }

{ @routine $4EC664 VectorToSphericalAngles }
procedure VectorToSphericalAngles(
    Vector: TVector3D;
    var LongitudeDegrees, PolarAngleDegrees: Double
);
var
  Radius: Double;
begin
  Radius := Sqrt(Sqr(Vector.X) + Sqr(Vector.Y) + Sqr(Vector.Z));
  PolarAngleDegrees := RadiansToHeadingDegrees(ArcCos(-Vector.Y / Radius));
  LongitudeDegrees := RadiansToHeadingDegrees(Pi - ArcTan2(Vector.X, Vector.Z));
end;
{ @end $4EC664 }

{ @routine $4EC71C AdvanceSphericalBearingState }
procedure AdvanceSphericalBearingState(
    var LongitudeDegrees, PolarAngleDegrees, BearingDegrees: Double;
    SphereRadius, ArcDistance: Double
);
var
  ArcAngle, NewPolar, OldPolar, LongitudeDelta, OldBearing, NewBearing, InvSin, Value: Double;
  Reverse: Boolean;
begin
  if ArcDistance < 0 then
  begin
    Reverse := True;
    ArcDistance := -ArcDistance;
    BearingDegrees := WrapHeadingDegrees(BearingDegrees + 180);
  end
  else
    Reverse := False;
  OldBearing := HeadingDegreesToRadians(BearingDegrees);
  ArcAngle := ArcDistance / (2 * Pi * SphereRadius) * Pi * 2;
  OldPolar := HeadingDegreesToRadians(PolarAngleDegrees);
  NewPolar :=
      ArcCos(Cos(OldPolar) * Cos(ArcAngle) + Sin(OldPolar) * Sin(ArcAngle) * Cos(OldBearing));
  if NewPolar < 0.00001 then
    InvSin := 99999999
  else
    InvSin := 1 / Sin(NewPolar);
  Value :=
      (Sin(OldPolar) * Cos(ArcAngle) - Cos(OldPolar) * Sin(ArcAngle) * Cos(OldBearing)) * InvSin;
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  LongitudeDelta := ArcCos(Value);
  Value :=
      (Sin(ArcAngle) * Cos(OldPolar) - Cos(ArcAngle) * Sin(OldPolar) * Cos(OldBearing)) * InvSin;
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  NewBearing := ArcCos(Value);
  if BearingDegrees > 180 then
  begin
    BearingDegrees := WrapHeadingDegrees(RadiansToHeadingDegrees(Pi + NewBearing));
    LongitudeDegrees :=
        WrapHeadingDegrees(LongitudeDegrees - RadiansToHeadingDegrees(LongitudeDelta));
  end
  else
  begin
    BearingDegrees := WrapHeadingDegrees(RadiansToHeadingDegrees(Pi - NewBearing));
    LongitudeDegrees :=
        WrapHeadingDegrees(LongitudeDegrees + RadiansToHeadingDegrees(LongitudeDelta));
  end;
  PolarAngleDegrees := RadiansToHeadingDegrees(NewPolar);
  if Reverse then
    BearingDegrees := WrapHeadingDegrees(BearingDegrees + 180);
end;
{ @end $4EC71C }

{ @routine $4ECB08 AdvanceSphericalStateOnCurrentSphere }
function AdvanceSphericalStateOnCurrentSphere(
    Source: TSphericalBearingState;
    ArcDistance: Double
): TSphericalBearingState;
begin
  Result := Source;
  AdvanceSphericalBearingState(
      Result.LongitudeDegrees,
      Result.PolarAngleDegrees,
      Result.BearingDegrees,
      SphereRadius,
      ArcDistance
  );
end;
{ @end $4ECB08 }

{ @routine $4ECB5C AdvanceSphericalStateAlongBearing }
function AdvanceSphericalStateAlongBearing(
    Source: TSphericalBearingState;
    TravelBearingDegrees, ArcDistance: Double
): TSphericalBearingState;
var
  RelativeBearing: Double;
begin
  Result := Source;
  RelativeBearing := HeadingDifferenceDegrees(TravelBearingDegrees, Result.BearingDegrees);
  AdvanceSphericalBearingState(
      Result.LongitudeDegrees,
      Result.PolarAngleDegrees,
      TravelBearingDegrees,
      SphereRadius,
      ArcDistance
  );
  Result.BearingDegrees := WrapHeadingDegrees(TravelBearingDegrees + RelativeBearing);
end;
{ @end $4ECB5C }

{ @routine $4ECBE0 AdvanceSphericalStateAndTravelBearing }
function AdvanceSphericalStateAndTravelBearing(
    Source: TSphericalBearingState;
    var TravelBearingDegrees: Double;
    ArcDistance: Double
): TSphericalBearingState;
var
  RelativeBearing: Double;
begin
  Result := Source;
  RelativeBearing := HeadingDifferenceDegrees(TravelBearingDegrees, Result.BearingDegrees);
  AdvanceSphericalBearingState(
      Result.LongitudeDegrees,
      Result.PolarAngleDegrees,
      TravelBearingDegrees,
      SphereRadius,
      ArcDistance
  );
  Result.BearingDegrees := WrapHeadingDegrees(TravelBearingDegrees + RelativeBearing);
end;
{ @end $4ECBE0 }

{ @routine $4ECC6C ComputeSphericalBearingAndDistance }
procedure ComputeSphericalBearingAndDistance(
    var BearingDeltaDegrees, Distance: Double;
    SourceLongitudeDegrees,
    SourcePolarAngleDegrees,
    SourceBearingDegrees,
    TargetLongitudeDegrees,
    TargetPolarAngleDegrees,
    SphereRadius: Double
);
var
  ArcAngle, TargetPolar, SourcePolar, LongitudeDelta, Bearing, Value: Double;
begin
  TargetPolar := HeadingDegreesToRadians(TargetPolarAngleDegrees);
  SourcePolar := HeadingDegreesToRadians(SourcePolarAngleDegrees);
  LongitudeDelta :=
      HeadingDegreesToRadians(WrapHeadingDegrees(TargetLongitudeDegrees - SourceLongitudeDegrees));
  Value :=
      Cos(TargetPolar) * Cos(SourcePolar)
          + Sin(TargetPolar) * Sin(SourcePolar) * Cos(LongitudeDelta);
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  ArcAngle := ArcCos(Value);
  Distance := ArcAngle / (2 * Pi) * 2 * Pi * SphereRadius;
  if ArcAngle = 0 then
  begin
    BearingDeltaDegrees := 0;
    Exit;
  end;
  Value :=
      (Sin(SourcePolar) * Cos(TargetPolar)
              - Cos(SourcePolar) * Sin(TargetPolar) * Cos(LongitudeDelta))
          / Sin(ArcAngle);
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  Bearing := ArcCos(Value);
  if HeadingDifferenceDegrees(SourceLongitudeDegrees, TargetLongitudeDegrees) < 0 then
    Bearing := -Bearing;
  BearingDeltaDegrees :=
      HeadingDifferenceDegrees(SourceBearingDegrees, RadiansToHeadingDegrees(Bearing));
end;
{ @end $4ECC6C }

{ @routine $4ECEFC ComputeSphericalDistance }
procedure ComputeSphericalDistance(
    var Distance: Double;
    SourceLongitudeDegrees,
    SourcePolarAngleDegrees,
    UnusedSourceBearingDegrees,
    TargetLongitudeDegrees,
    TargetPolarAngleDegrees,
    SphereRadius: Double
);
var
  ArcAngle, TargetPolar, SourcePolar, LongitudeDelta, Value: Double;
begin
  TargetPolar := HeadingDegreesToRadians(TargetPolarAngleDegrees);
  SourcePolar := HeadingDegreesToRadians(SourcePolarAngleDegrees);
  LongitudeDelta :=
      HeadingDegreesToRadians(WrapHeadingDegrees(TargetLongitudeDegrees - SourceLongitudeDegrees));
  Value :=
      Cos(TargetPolar) * Cos(SourcePolar)
          + Sin(TargetPolar) * Sin(SourcePolar) * Cos(LongitudeDelta);
  if Value < -1 then
    Value := -1
  else if Value > 1 then
    Value := 1;
  ArcAngle := ArcCos(Value);
  Distance := ArcAngle / (2 * Pi) * 2 * Pi * SphereRadius;
end;
{ @end $4ECEFC }

{ @routine $4ED04C GetSphericalBearingAndDistance }
function GetSphericalBearingAndDistance(
    Source,
    Target: TSphericalBearingState
): TSphericalBearingDistance;
begin
  ComputeSphericalBearingAndDistance(
      Result.BearingDeltaDegrees,
      Result.Distance,
      Source.LongitudeDegrees,
      Source.PolarAngleDegrees,
      Source.BearingDegrees,
      Target.LongitudeDegrees,
      Target.PolarAngleDegrees,
      SphereRadius
  );
end;
{ @end $4ED04C }

{ @routine $4ED0B4 UpdateSphereProjectionMetrics }
procedure UpdateSphereProjectionMetrics;
var
  Angle: Double;
  V, Target, Up: TVector3D;
  View, Projection, Combined: TMatrix4D;
begin
  V := MakeVector3D(0, 0, SphereCameraDistance);
  Target := MakeVector3D(0, 0, 0);
  Up := MakeVector3D(0, 1, 0);
  View := BuildLookAtMatrix(V, Target, Up);
  Projection :=
      BuildPerspectiveProjectionMatrix(
          SphereCameraDistance - SphereRadius - 100,
          SphereCameraDistance + SphereRadius + 100,
          HeadingDegreesToRadians(SphereFieldOfView),
          Cardinal(GameScreenWidth)
      );
  Combined := MultiplyMatrix4D(Projection, View);
  Angle := 90 - (90 - RadiansToHeadingDegrees(ArcSin(SphereRadius / SphereCameraDistance)));
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereHorizonDepth := V.Z;
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle - 15)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereNearHorizonDepth := V.Z;
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle + 15)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereFarHorizonDepth := V.Z;
  V := MakeVector3D(SphereRadius, 0, 0);
  V := ProjectPointByMatrix(Combined, V);
  SphereProjectedRadius := Max(Abs(V.X), Abs(V.Y));
end;
{ @end $4ED0B4 }

{ @routine $4ED3C0 IsDepthBeforeSphereHorizon }
function IsDepthBeforeSphereHorizon(ProjectedDepth: Double): Boolean;
begin
  Result := ProjectedDepth < SphereHorizonDepth;
end;
{ @end $4ED3C0 }

{ @routine $4ED3E0 NormalizeVector3D }
function NormalizeVector3D(const Source: TVector3D): TVector3D;
var
  Scale: Double;
begin
  Scale := 1.0 / Sqrt(Source.X * Source.X + Source.Y * Source.Y + Source.Z * Source.Z);
  Result.X := Source.X * Scale;
  Result.Y := Source.Y * Scale;
  Result.Z := Source.Z * Scale;
end;
{ @end $4ED3E0 }

{ @routine $4ED460 CrossProduct3D }
function CrossProduct3D(const A, B: TVector3D): TVector3D;
begin
  Result.X := A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.Z * B.X - A.X * B.Z;
  Result.Z := A.X * B.Y - A.Y * B.X;
end;
{ @end $4ED460 }

{ @routine $4ED4D4 DotProduct3D }
function DotProduct3D(const A, B: TVector3D): Double;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;
{ @end $4ED4D4 }

{ @routine $4ED514 ClearMatrix4D }
procedure ClearMatrix4D(var Matrix: TMatrix4D);
var
  I, J: Integer;
begin
  for I := 0 to 3 do
    for J := 0 to 3 do
      Matrix[I, J] := 0;
end;
{ @end $4ED514 }

{ @routine $4ED558 SetIdentityMatrix4D }
procedure SetIdentityMatrix4D(var Matrix: TMatrix4D);
begin
  Matrix[0, 0] := 1;
  Matrix[1, 0] := 0;
  Matrix[2, 0] := 0;
  Matrix[3, 0] := 0;
  Matrix[0, 1] := 0;
  Matrix[1, 1] := 1;
  Matrix[2, 1] := 0;
  Matrix[3, 1] := 0;
  Matrix[0, 2] := 0;
  Matrix[1, 2] := 0;
  Matrix[2, 2] := 1;
  Matrix[3, 2] := 0;
  Matrix[0, 3] := 0;
  Matrix[1, 3] := 0;
  Matrix[2, 3] := 0;
  Matrix[3, 3] := 1;
end;
{ @end $4ED558 }

{ @routine $4ED624 BuildZAxisRotationMatrix }
function BuildZAxisRotationMatrix(AngleRadians: Double): TMatrix4D;
var
  C, S: Double;
begin
  C := Cos(AngleRadians);
  S := Sin(AngleRadians);
  SetIdentityMatrix4D(Result);
  Result[0, 0] := C;
  Result[1, 1] := C;
  Result[0, 1] := -S;
  Result[1, 0] := S;
end;
{ @end $4ED624 }

{ @routine $4ED69C BuildPerspectiveProjectionMatrix }
function BuildPerspectiveProjectionMatrix(
    NearPlane,
    FarPlane,
    FovRadians,
    ProjectionScale: Double
): TMatrix4D;
var
  C, S, Q: Double;
begin
  C := Cos(FovRadians * 0.5);
  S := Sin(FovRadians * 0.5);
  Q := S / (1.0 - NearPlane / FarPlane);
  ClearMatrix4D(Result);
  Result[0, 0] := C * ProjectionScale;
  Result[1, 1] := C * ProjectionScale;
  Result[2, 2] := Q;
  Result[3, 2] := -Q * NearPlane;
  Result[2, 3] := S;
end;
{ @end $4ED69C }

{ @routine $4ED748 BuildLookAtMatrix }
function BuildLookAtMatrix(const CameraPos, TargetPos, UpVector: TVector3D): TMatrix4D;
var
  Forward, Right, Up: TVector3D;
begin
  SetIdentityMatrix4D(Result);
  Forward :=
      MakeVector3D(TargetPos.X - CameraPos.X, TargetPos.Y - CameraPos.Y, TargetPos.Z - CameraPos.Z);
  Forward := NormalizeVector3D(Forward);
  Right := CrossProduct3D(UpVector, Forward);
  Up := CrossProduct3D(Forward, Right);
  Right := NormalizeVector3D(Right);
  Up := NormalizeVector3D(Up);
  Result[0, 0] := Right.X;
  Result[1, 0] := Right.Y;
  Result[2, 0] := Right.Z;
  Result[0, 1] := Up.X;
  Result[1, 1] := Up.Y;
  Result[2, 1] := Up.Z;
  Result[0, 2] := Forward.X;
  Result[1, 2] := Forward.Y;
  Result[2, 2] := Forward.Z;
  Result[3, 0] := -DotProduct3D(Right, CameraPos);
  Result[3, 1] := -DotProduct3D(Up, CameraPos);
  Result[3, 2] := -DotProduct3D(Forward, CameraPos);
end;
{ @end $4ED748 }

{ @routine $4EDD68 InvertMatrix4D }
function InvertMatrix4D(const Matrix: TMatrix4D): TMatrix4D;
var
  Permutations: array[0..3] of Integer;
  Solution: array[0..3] of Double;
  I, J: Integer;
  PermutationSign: Double;
  Factors: TMatrix4D;

  // @nested $4ED8D0 SolveMatrix4DLuSystem
  procedure SolveMatrix4DLuSystem(
      const Factors: TMatrix4D
  ); // @addr 0x4ED8D0 @ida "void __usercall $name(const TMatrix4D *Factors@<eax>, void *ParentFrame@<^0>);"
  var
    I, J, FirstNonzero, Pivot: Integer;
    Sum: Double;
  begin
    FirstNonzero := -1;
    for I := 0 to 3 do
    begin
      Pivot := Permutations[I];
      Sum := Solution[Pivot];
      Solution[Pivot] := Solution[I];
      if FirstNonzero >= 0 then
        for J := FirstNonzero to I - 1 do
          Sum := Sum - Factors[I, J] * Solution[J]
      else if Sum <> 0 then
        FirstNonzero := I;
      Solution[I] := Sum;
    end;
    for I := 3 downto 0 do
    begin
      Sum := Solution[I];
      for J := I + 1 to 3 do
        Sum := Sum - Factors[I, J] * Solution[J];
      Solution[I] := Sum / Factors[I, I];
    end;
  end;

  // @nested $4EDA20 DecomposeMatrix4DLu
  procedure DecomposeMatrix4DLu(
      var Matrix: TMatrix4D;
      var PermutationSign: Double
  ); // @addr 0x4EDA20 @ida "void __usercall $name(TMatrix4D *Matrix@<eax>, double *PermutationSign@<edx>, void *ParentFrame@<^0>);"
  var
    Big, Temp, Sum, Magnitude: Double;
    I, Pivot, J, K: Integer;
    Scales: array[0..3] of Double;
  begin
    PermutationSign := 1;
    for I := 0 to 3 do
    begin
      Big := 0;
      for J := 0 to 3 do
      begin
        Magnitude := Abs(Matrix[I, J]);
        if Magnitude > Big then
          Big := Magnitude;
      end;
      Scales[I] := 1 / Big;
    end;
    for J := 0 to 3 do
    begin
      I := 0;
      while I < J do
      begin
        Sum := Matrix[I, J];
        K := 0;
        while K < I do
        begin
          Sum := Sum - Matrix[I, K] * Matrix[K, J];
          Inc(K);
        end;
        Matrix[I, J] := Sum;
        Inc(I);
      end;
      Pivot := 0;
      Big := 0;
      for I := J to 3 do
      begin
        Sum := Matrix[I, J];
        K := 0;
        while K < J do
        begin
          Sum := Sum - Matrix[I, K] * Matrix[K, J];
          Inc(K);
        end;
        Matrix[I, J] := Sum;
        Temp := Abs(Sum) * Scales[I];
        if Temp >= Big then
        begin
          Big := Temp;
          Pivot := I;
        end;
      end;
      if J <> Pivot then
      begin
        for K := 0 to 3 do
        begin
          Temp := Matrix[Pivot, K];
          Matrix[Pivot, K] := Matrix[J, K];
          Matrix[J, K] := Temp;
        end;
        PermutationSign := -PermutationSign;
        Scales[Pivot] := Scales[J];
      end;
      Permutations[J] := Pivot;
      if Matrix[J, J] = 0 then
        Matrix[J, J] := 1E-20;
      if J <> 3 then
      begin
        Temp := 1 / Matrix[J, J];
        for I := J + 1 to 3 do
          Matrix[I, J] := Matrix[I, J] * Temp;
      end;
    end;
  end;

begin
  Factors := Matrix;
  DecomposeMatrix4DLu(Factors, PermutationSign);
  for J := 0 to 3 do
  begin
    for I := 0 to 3 do
      Solution[I] := 0;
    Solution[J] := 1;
    SolveMatrix4DLuSystem(Factors);
    for I := 0 to 3 do
      Result[I, J] := Solution[I];
  end;
end;
{ @end $4EDD68 }

{ @routine $4EDE1C MultiplyMatrix4D }
function MultiplyMatrix4D(const Left, Right: TMatrix4D): TMatrix4D;
var
  I, J, K: Integer;
begin
  ClearMatrix4D(Result);
  for I := 0 to 3 do
    for J := 0 to 3 do
      for K := 0 to 3 do
        Result[I, J] := Left[K, J] * Right[I, K] + Result[I, J];
end;
{ @end $4EDE1C }

{ @routine $4EDEAC ProjectPointByMatrix }
function ProjectPointByMatrix(const Matrix: TMatrix4D; const Source: TVector3D): TVector3D;
// Portable equivalent of the native x87 homogeneous projection.
var
  InvW: Double;
begin
  InvW :=
      1.0
          / (Matrix[0, 3] * Source.X
              + Matrix[1, 3] * Source.Y
              + Matrix[2, 3] * Source.Z
              + Matrix[3, 3]);
  Result.X :=
      (Matrix[0, 0] * Source.X + Matrix[1, 0] * Source.Y + Matrix[2, 0] * Source.Z + Matrix[3, 0])
          * InvW;
  Result.Y :=
      (Matrix[0, 1] * Source.X + Matrix[1, 1] * Source.Y + Matrix[2, 1] * Source.Z + Matrix[3, 1])
          * InvW;
  Result.Z :=
      (Matrix[0, 2] * Source.X + Matrix[3, 2] + Matrix[1, 2] * Source.Y + Matrix[2, 2] * Source.Z)
          * InvW;
end;
{ @end $4EDEAC }

{ @routine $4EDF2C TryIntersectRayWithSphere }
function TryIntersectRayWithSphere(
    RayOrigin, RayPointOnRay, SphereCenter: TVector3D;
    SphereRadius: Double;
    var HitPoint: TVector3D
): Boolean;
var
  T, OtherT, Projection, Discriminant, DistanceSquared: Double;
  Direction, CenterDelta: TVector3D;
begin
  Direction.X := RayPointOnRay.X - RayOrigin.X;
  Direction.Y := RayPointOnRay.Y - RayOrigin.Y;
  Direction.Z := RayPointOnRay.Z - RayOrigin.Z;
  T := 1 / Sqrt(Direction.X * Direction.X + Direction.Y * Direction.Y + Direction.Z * Direction.Z);
  Direction.X := Direction.X * T;
  Direction.Y := Direction.Y * T;
  Direction.Z := Direction.Z * T;
  CenterDelta.X := SphereCenter.X - RayOrigin.X;
  CenterDelta.Y := SphereCenter.Y - RayOrigin.Y;
  CenterDelta.Z := SphereCenter.Z - RayOrigin.Z;
  DistanceSquared :=
      CenterDelta.X * CenterDelta.X + CenterDelta.Y * CenterDelta.Y + CenterDelta.Z * CenterDelta.Z;
  Projection :=
      CenterDelta.X * Direction.X + CenterDelta.Y * Direction.Y + CenterDelta.Z * Direction.Z;
  Discriminant := Sqr(SphereRadius) - DistanceSquared + Projection * Projection;
  if Discriminant <= 0 then
  begin
    Result := False;
    Exit;
  end;
  Discriminant := Sqrt(Discriminant);
  if Projection < Discriminant then
  begin
    T := Projection + Discriminant;
    OtherT := Projection - Discriminant;
  end
  else
  begin
    T := Projection - Discriminant;
    OtherT := Projection + Discriminant;
  end;
  if Abs(T) < 0.001 then
    T := OtherT;
  HitPoint.X := Direction.X * T + RayOrigin.X;
  HitPoint.Y := Direction.Y * T + RayOrigin.Y;
  HitPoint.Z := Direction.Z * T + RayOrigin.Z;
  Result := T > 0.001;
end;
{ @end $4EDF2C }

end.
