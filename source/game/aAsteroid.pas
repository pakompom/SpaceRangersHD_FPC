{$EXCESSPRECISION OFF}
unit aAsteroid;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  SE_Space,
  aEFilm,
  aGalaxy;
type
  TAsteroid = class;
  TAsteroid = class(TObjectEx)
    Id: Cardinal;
    CurrentStar: TStar;
    Position: TPointF;
    PhysicsPosition: TPointF;
    Velocity: TPointF;
    Mass: Single;
    GravityForceFactor: Single;
    InverseMass: Single;
    MineralCount: Integer;
    GraphObject: TObjectSE;
    FilmObject: TEFilmObj;
    constructor Create;
    destructor Destroy; override;
    procedure Init(Star: TStar; const GraphKey: WideString);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
    procedure RespawnIfOutsideSystem;
    procedure PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean);
    procedure AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean);
    procedure Respawn;
    procedure SpawnSiblingAsteroidInCurrentStar;
    procedure IntegrateMotion(TimeScale: Single);
    procedure WritePredictedPositions(Positions: PPointF; Count: Integer);
    function GetDisplayName: WideString; overload;
    function GetDisplayName(const Template: WideString): WideString; overload;
    function GetInfoText: WideString; overload;
    function GetInfoText(const Template: WideString): WideString; overload;
  end;
const
  AsteroidGravitationalConstant: Single = 6.672041391597716e-11;
implementation
uses
  Classes,
  Math,
  SE_Process,
  SE_Asteroid,
  Globals,
  aMyFunction,
  EC_Str,
  EC_Mem,
  aConst,
  aPlayer,
  aShip,
  GR_Main;
const
  // Preserve native Extended constants. DCC32's decimal conversion rounds plain
  // 2e30 and 6e-9 one mantissa bit above the constants in this binary.
  AsteroidCentralMass = 2e30 - 137438953472.0;
  AsteroidWorldScale = 5.9999999999999999993e-9;
  AsteroidInverseScaleSquared = 27777777777777777.78;

constructor TAsteroid.Create;
begin
  inherited Create;
  if Galaxy <> nil then
  begin
    Id := Galaxy.NextAsteroidId;
    Inc(Galaxy.NextAsteroidId);
  end;
end;

destructor TAsteroid.Destroy;
begin
  if GraphObject <> nil then
    ReleaseSpaceObject(GraphObject);
  inherited Destroy;
end;

procedure TAsteroid.Init(Star: TStar; const GraphKey: WideString);
begin
  CurrentStar := Star;
  RetainSpaceObject(
      GraphObject,
      CreateSpaceObjectByName('Asteroid', GraphKey, Classes.Point(0, 0))
  );
  Respawn;
end;

procedure TAsteroid.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddWideStringZ(GraphObject.GraphKey);
  Buffer.AddSingle(PhysicsPosition.X);
  Buffer.AddSingle(PhysicsPosition.Y);
  Buffer.AddSingle(Velocity.X);
  Buffer.AddSingle(Velocity.Y);
  Buffer.AddSingle(Mass);
  Buffer.AddIntegerValue(MineralCount);
end;

procedure TAsteroid.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextAsteroidId <= Id then
    Galaxy.NextAsteroidId := Id + 1;
  RetainSpaceObject(GraphObject, TAsteroidSE.Create(Buffer.ReadWideString, Classes.Point(0, 0)));
  PhysicsPosition.X := Buffer.GetSingle;
  PhysicsPosition.Y := Buffer.GetSingle;
  Velocity.X := Buffer.GetSingle;
  Velocity.Y := Buffer.GetSingle;
  Mass := Buffer.GetSingle;
  InverseMass := 1 / Mass;
  GravityForceFactor := AsteroidGravitationalConstant * Mass * AsteroidCentralMass;
  MineralCount := Buffer.GetInt32;
  Position.X := PhysicsPosition.X * AsteroidWorldScale;
  Position.Y := PhysicsPosition.Y * AsteroidWorldScale;
end;

procedure TAsteroid.RespawnIfOutsideSystem;
begin
  if Position.X * Position.X + Position.Y * Position.Y > Sqr(CurrentStar.MapDiameter) then
    Respawn;
end;

procedure TAsteroid.PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean);
begin
  if RecordFilm then
  begin
    FilmObject := PrimaryFilm.AddObject(Id, GraphObject);
    PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
    PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
  end;
end;

procedure TAsteroid.AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean);
begin
  IntegrateMotion(200 / CurrentStar.MovementStepCount);
  if RecordFilm then
    PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
end;

procedure TAsteroid.Respawn;
var
  Angle, Radius, Speed, Reserved: Single; // Native reserves one additional scalar slot.
begin
  Mass := 1000000;
  InverseMass := 1 / Mass;
  GravityForceFactor := AsteroidGravitationalConstant * Mass * AsteroidCentralMass;
  Angle := HeadingDegreesToRadians(NextRandomIntRange(0, 360, CurrentStar.RandomState));
  Radius := CurrentStar.MapDiameter / 2 + 800 + 2000;
  Radius := Radius + NextRandomIntRange(0, 1000, CurrentStar.RandomState);
  if Radius > CurrentStar.MapDiameter then
    Radius := CurrentStar.MapDiameter - 50 - NextRandomIntRange(0, 100, CurrentStar.RandomState);
  Position.X := Sin(Angle) * Radius;
  Position.Y := -Cos(Angle) * Radius;
  PhysicsPosition.X := Position.X * (1 / AsteroidWorldScale);
  PhysicsPosition.Y := Position.Y * (1 / AsteroidWorldScale);
  Speed := NextRandomIntRange(0, 3000, CurrentStar.RandomState) + 7000;
  Angle := ArcTan2(0.0 - Position.X, -(0.0 - Position.Y));
  Angle :=
      Angle
          + HeadingDegreesToRadians(NextRandomIntRange(-10, 10, CurrentStar.RandomState) + 25)
              * (2 * NextRandomIntRange(0, 1, CurrentStar.RandomState) - 1);
  Velocity.X := Sin(Angle) * Speed;
  Velocity.Y := -Cos(Angle) * Speed;
  MineralCount := NextRandomIntRange(20, 99, CurrentStar.RandomState);
  if Galaxy <> nil then
    if GetPlayer <> nil then
      if (GetPlayer.CurrentStar <> CurrentStar) or not GetPlayer.InNormalSpace then
        if (Galaxy.GodModEnabled = 2)
            and (NextRandomIntRange(0, 100, CurrentStar.RandomState) > 50) then
          SpawnSiblingAsteroidInCurrentStar;
end;

procedure TAsteroid.SpawnSiblingAsteroidInCurrentStar;
var
  Asteroid: TAsteroid;
  Text: WideString;
  Index, VariantCount, Variant: Integer;
begin
  if CurrentStar.BackgroundImage < 10 then
    Text :=
        GameDataConfig
            .GetBlockByPath('StyleAsteroid')
            .GetParam('0' + IntToWideString(CurrentStar.BackgroundImage))
  else
    Text :=
        GameDataConfig
            .GetBlockByPath('StyleAsteroid')
            .GetParam(IntToWideString(CurrentStar.BackgroundImage));
  Index :=
      NextRandomIntRange(0, CountDelimitedPartsW(Text, ',') div 2 - 1, CurrentStar.RandomState) * 2;
  VariantCount := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, Index + 1, ','));
  Text := ExtractDelimitedPartW(Text, Index, ',');
  Variant := NextRandomIntRange(0, VariantCount - 1, CurrentStar.RandomState);
  Asteroid := TAsteroid.Create;
  if Variant < 10 then
    Asteroid.Init(CurrentStar, 'Asteroid.' + Text + '0' + IntToWideString(Variant))
  else
    Asteroid.Init(CurrentStar, 'Asteroid.' + Text + IntToWideString(Variant));
  CurrentStar.Asteroids.Add(Asteroid);
end;

procedure TAsteroid.IntegrateMotion(TimeScale: Single);
var
  ForceY, ForceX, DeltaY, DeltaX, AccelY, AccelX, InverseDistance, Force, DistanceSquared: Single;
begin
  DeltaX := 0.0 - Position.X;
  DeltaY := 0.0 - Position.Y;
  DistanceSquared := DeltaX * DeltaX + DeltaY * DeltaY;
  InverseDistance := 1 / Sqrt(DistanceSquared);
  if DistanceSquared < 10000 then
    DistanceSquared := 10000;
  Force := GravityForceFactor / (DistanceSquared * AsteroidInverseScaleSquared);
  ForceX := DeltaX * InverseDistance * Force;
  ForceY := DeltaY * InverseDistance * Force;
  AccelX := ForceX * InverseMass;
  AccelY := ForceY * InverseMass;
  Velocity.X := Velocity.X + AccelX * TimeScale * 19968;
  Velocity.Y := Velocity.Y + AccelY * TimeScale * 19968;
  PhysicsPosition.X := PhysicsPosition.X + Velocity.X * TimeScale * 19968;
  PhysicsPosition.Y := PhysicsPosition.Y + Velocity.Y * TimeScale * 19968;
  Position.X := PhysicsPosition.X * AsteroidWorldScale;
  Position.Y := PhysicsPosition.Y * AsteroidWorldScale;
end;

procedure TAsteroid.WritePredictedPositions(Positions: PPointF; Count: Integer);
var
  SavedPosition, SavedPhysicsPosition, SavedVelocity: TPointF;
  Index: Integer;
begin
  SavedPosition := Position;
  SavedPhysicsPosition := PhysicsPosition;
  SavedVelocity := Velocity;
  for Index := 0 to Count - 1 do
  begin
    IntegrateMotion(1);
    WriteSingleEC(Positions, Position.X);
    Positions := AddPointerOffset(Positions, 4);
    WriteSingleEC(Positions, Position.Y);
    Positions := AddPointerOffset(Positions, 4);
  end;
  Position := SavedPosition;
  PhysicsPosition := SavedPhysicsPosition;
  Velocity := SavedVelocity;
end;

function TAsteroid.GetDisplayName: WideString;
begin
  Result := GetDisplayName(LocalizedText('Asteroid.Name'));
end;

// CHANGE: PERFORMANCE - Batch callers can share the unchanged localized template.
function TAsteroid.GetDisplayName(const Template: WideString): WideString;
begin
  Result := Template;
  ReplaceTextToken(Result, '<Number>', IntToWideString(Id), '<color=255,240,100>');
end;

function TAsteroid.GetInfoText: WideString;
begin
  Result := GetInfoText(LocalizedText('Asteroid.Text'));
end;

function TAsteroid.GetInfoText(const Template: WideString): WideString;
var
  Speed: Single;
begin
  Result := Template;
  ReplaceTextToken(Result, '<Number>', IntToWideString(Id), '<color=255,240,100>');
  Speed := Sqrt(Sqr(Velocity.X) + Sqr(Velocity.Y));
  Speed := Speed * 200 * 19968 * AsteroidWorldScale;
  ReplaceTextToken(Result, '<Speed>', IntToWideString(Round(Speed)), '<color=255,240,100>');
  ReplaceTextToken(Result, '<Count>', IntToWideString(MineralCount), '<color=255,240,100>');
end;

end.
