{$EXCESSPRECISION OFF}
unit aMissile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aConst,
  EC_Buf,
  EC_Struct,
  SE_Space,
  aEFilm,
  aGalaxy,
  aGalaxyStruct,
  aItem,
  aShip;
type
  TCustomMissile = class;
  TMissile = class;
  TMissile = class(TObjectEx)
    Graphic: TObjectSE;
    Id: Cardinal;
    WeaponId: Integer;
    ItemType: Byte;
    TechLevel: Byte;
    Gap12: array[0..1] of Byte;
    MinDamage: Integer;
    MaxDamage: Integer;
    MicroModuleIndex: Integer;
    SpecialModuleIndex: Integer;
    Position: TPointF;
    Direction: Single;
    Speed: Single;
    MaximumSpeed: Single;
    CurrentStar: TStar;
    OwnerShip: TShip;
    Target: TObject;
    PreviousTarget: TObject;
    ShotIndex: Integer;
    TurnDirection: Single;
    SourceHeading: Single;
    FlightTicks: Integer;
    DestroyQueued: Boolean;
    Gap59: array[0..2] of Byte;
    FilmObject: TEFilmObj;
    SavedTargetKind: Byte;
    SavedPreviousTargetKind: Byte;
    Gap62: array[0..1] of Byte;
    LastTargetPosition: TPointF;
    LastTargetDistance: Single;
    OvershootTicks: Integer;
    procedure SaveToBuffer(Buffer: TBufEC); virtual;
    procedure LoadFromBuffer(Buffer: TBufEC; World: TGalaxy); virtual;
    function GetGraphSuffix: WideString; virtual;
    function GetWeaponInfo: PWeaponInfo; virtual;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeShot(
        Star: TStar;
        OwnerShip: TShip;
        Weapon: TWeapon;
        Target: TObject;
        ShotIndex: Integer
    );
    procedure InitializeUnownedShot(
        Star: TStar;
        Target: TObject;
        X: Integer;
        Y: Integer;
        Direction: Single;
        MinDamage: Integer;
        MaxDamage: Integer;
        MaximumSpeed: Single;
        ItemType: Byte;
        ModuleIndex: Integer;
        SpecialIndex: Integer
    );
    procedure ResolveLoadedReferences(World: TGalaxy);
    function GetGraphObject: TObjectSE;
    procedure PrepareTurnMovement(StepIndex: Integer; RecordFilm: Boolean; PlayShotSound: Boolean);
    function StepDay(StepIndex: Integer; RecordFilm: Boolean): TObject;
    function TryReturnToOwner(
        StepIndex: Integer;
        RecordFilm: Boolean;
        PreviousPosition: TPointF;
        Ship: TShip
    ): Boolean;
    procedure RetargetTorpedo;
    function GetDisplayName: WideString;
    function GetInfoText: WideString;
    function CanBeHit(Attacker: TShip; UnusedWeapon: TWeapon): Boolean;
    procedure ClearReferencesTo(Obj: TObject);
    function GetShotVisual: Integer;
  end;
  TCustomMissile = class(TMissile)
    WeaponInfo: PWeaponInfo;
    procedure SaveToBuffer(Buffer: TBufEC); override;
    procedure LoadFromBuffer(Buffer: TBufEC; World: TGalaxy); override;
    function GetGraphSuffix: WideString; override;
    function GetWeaponInfo: PWeaponInfo; override;
    procedure InitializeShot(
        Star: TStar;
        OwnerShip: TShip;
        Weapon: TWeapon;
        Target: TObject;
        ShotIndex: Integer
    );
    procedure InitializeUnownedShot(
        Star: TStar;
        Target: TObject;
        X: Integer;
        Y: Integer;
        Direction: Single;
        MinDamage: Integer;
        MaxDamage: Integer;
        MaximumSpeed: Single;
        WeaponName: WideString;
        ModuleIndex: Integer;
        SpecialIndex: Integer
    );
  end;
procedure LinkRecoveredTypes;
implementation
uses
  SE_Process,
  Classes,
  GR_Main,
  SE_Weapon,
  EC_BlockPar,
  Math,
  Globals,
  GlobalsV,
  SysUtils,
  aMyFunction,
  aAsteroid,
  aPlayer,
  aKling;

constructor TMissile.Create;
begin
  inherited Create;
  if Galaxy <> nil then
  begin
    Id := Galaxy.NextMissileId;
    Inc(Galaxy.NextMissileId);
  end;
  WeaponId := 0;
  PreviousTarget := nil;
  LastTargetDistance := 1E20;
end;

destructor TMissile.Destroy;
var
  Index: Integer;
begin
  if Graphic <> nil then
    ReleaseSpaceObject(Graphic);
  if CurrentStar <> nil then
  begin
    CurrentStar.ClearTargetReferences(Self);
    Index := CurrentStar.Missiles.IndexOf(Self);
    if Index >= 0 then
      CurrentStar.Missiles.Delete(Index);
  end;
  inherited Destroy;
end;

procedure TMissile.InitializeShot(
    Star: TStar;
    OwnerShip: TShip;
    Weapon: TWeapon;
    Target: TObject;
    ShotIndex: Integer
);
var
  DY, DX: Single;
  ShotCount, SpeedBonus, SpecialBonus: Integer;
begin
  Star.Missiles.Add(Self);
  CurrentStar := Star;
  Self.OwnerShip := OwnerShip;
  Self.Target := Target;
  WeaponId := Weapon.Id;
  ItemType := Byte(Weapon.ItemType);
  MinDamage := OwnerShip.GetWeaponMinDamage(Weapon);
  MicroModuleIndex := Weapon.MicroModuleIndex;
  SpecialModuleIndex := Weapon.SpecialModuleIndex;
  MaxDamage := OwnerShip.GetWeaponMaxDamage(Weapon);
  SpeedBonus := Self.OwnerShip.GetTotalStatBonus(Ord(bonMissileSpeed));
  SpecialBonus := 0;
  if SpecialModuleIndex > 0 then
    SpecialBonus := MicroModuleTemplates[SpecialModuleIndex - 1].StatBonuses[Ord(bonMissileSpeed)];
  if MicroModuleIndex > 0 then
  begin
    Inc(SpeedBonus, MicroModuleTemplates[MicroModuleIndex - 1].StatBonuses[Ord(bonMissileSpeed)]);
    if SpecialBonus < 0 then
      Inc(
          SpecialBonus,
          Round(
              SpecialBonus
                  * MicroModuleTemplates[MicroModuleIndex - 1]
                      .StatBonuses[Ord(bonExtraAkrinPenalty)]
                  * 0.0001
          )
      )
    else
      Inc(
          SpecialBonus,
          Round(
              SpecialBonus
                  * MicroModuleTemplates[MicroModuleIndex - 1].StatBonuses[Ord(bonExtraAkrinEff)]
                  * 0.0001
          )
      );
  end;
  Inc(SpeedBonus, SpecialBonus);
  TechLevel := Weapon.TechLevel;
  Self.ShotIndex := ShotIndex;
  ShotCount := Weapon.GetShotCount;
  Direction := OwnerShip.MovementDirection;
  Position := OwnerShip.Position;
  if ShotIndex > 0 then
  begin
    Direction :=
        Direction - 60 / (ShotCount + 3) * ((ShotIndex + 1) div 2) * (2 * (ShotIndex mod 2) - 1);
    DX := Sin(HeadingDegreesToRadians(Direction));
    DY := -Cos(HeadingDegreesToRadians(Direction));
    Position := MakePointF(Position.X + -DX * 8, Position.Y + -DY * 8);
  end;
  MaximumSpeed :=
      Max(
          GetWeaponInfo.MissileMinSpeed div 10,
          RemapClamped(
                  TechLevel,
                  1,
                  8,
                  GetWeaponInfo.MissileMinSpeed,
                  GetWeaponInfo.MissileMaxSpeed)
              + SpeedBonus
      );
end;

procedure TCustomMissile.InitializeShot(
    Star: TStar;
    OwnerShip: TShip;
    Weapon: TWeapon;
    Target: TObject;
    ShotIndex: Integer
);
begin
  WeaponInfo := Weapon.GetWeaponInfo;
  inherited InitializeShot(Star, OwnerShip, Weapon, Target, ShotIndex);
end;

procedure TMissile.InitializeUnownedShot(
    Star: TStar;
    Target: TObject;
    X, Y: Integer;
    Direction: Single;
    MinDamage, MaxDamage: Integer;
    MaximumSpeed: Single;
    ItemType: Byte;
    ModuleIndex, SpecialIndex: Integer
);
begin
  Star.Missiles.Add(Self);
  CurrentStar := Star;
  OwnerShip := nil;
  Self.Target := Target;
  WeaponId := 0;
  Self.ItemType := ItemType;
  MicroModuleIndex := ModuleIndex;
  SpecialModuleIndex := SpecialIndex;
  Self.MinDamage := MinDamage;
  Self.MaxDamage := MaxDamage;
  Self.Direction := Direction;
  Position := MakePointF(X, Y);
  Self.MaximumSpeed := MaximumSpeed;
  TechLevel := 1;
  ShotIndex := 0;
end;

procedure TCustomMissile.InitializeUnownedShot(
    Star: TStar;
    Target: TObject;
    X, Y: Integer;
    Direction: Single;
    MinDamage, MaxDamage: Integer;
    MaximumSpeed: Single;
    WeaponName: WideString;
    ModuleIndex, SpecialIndex: Integer
);
begin
  WeaponInfo := Galaxy.RequireCustomWeaponInfo(WeaponName);
  inherited InitializeUnownedShot(
      Star,
      Target,
      X,
      Y,
      Direction,
      MinDamage,
      MaxDamage,
      MaximumSpeed,
      Byte(WeaponInfo.ItemType),
      ModuleIndex,
      SpecialIndex
  );
end;

procedure TMissile.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddDWord(WeaponId);
  Buffer.AddAnsiChar(AnsiChar(ItemType));
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddIntegerValue(MinDamage);
  Buffer.AddIntegerValue(MaxDamage);
  Buffer.AddIntegerValue(MicroModuleIndex);
  if MicroModuleIndex > 0 then
    Buffer.AddDWord(MicroModuleTemplates[MicroModuleIndex - 1].ConfigNameHash);
  Buffer.AddIntegerValue(SpecialModuleIndex);
  if SpecialModuleIndex > 0 then
    Buffer.AddDWord(MicroModuleTemplates[SpecialModuleIndex - 1].ConfigNameHash);
  Buffer.AddSingle(Position.X);
  Buffer.AddSingle(Position.Y);
  Buffer.AddSingle(Direction);
  Buffer.AddSingle(TurnDirection);
  if CurrentStar = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(CurrentStar.Id);
  if OwnerShip = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(OwnerShip.Id);
  if Target = nil then
    Buffer.AddAnsiChar(AnsiChar(0))
  else if Target is TShip then
  begin
    Buffer.AddAnsiChar(AnsiChar(1));
    Buffer.AddDWord((Target as TShip).Id);
  end
  else if Target is TItem then
  begin
    Buffer.AddAnsiChar(AnsiChar(2));
    Buffer.AddDWord((Target as TItem).Id);
  end
  else if Target is TAsteroid then
  begin
    Buffer.AddAnsiChar(AnsiChar(3));
    Buffer.AddDWord((Target as TAsteroid).Id);
  end
  else if Target is TMissile then
  begin
    Buffer.AddAnsiChar(AnsiChar(4));
    Buffer.AddDWord((Target as TMissile).Id);
  end
  else
    Buffer.AddAnsiChar(AnsiChar(0));
  Buffer.AddAnsiChar(AnsiChar(ShotIndex));
  Buffer.AddIntegerValue(FlightTicks);
  Buffer.AddSingle(SourceHeading);
  Buffer.AddSingle(Speed);
  Buffer.AddSingle(MaximumSpeed);
  if PreviousTarget = nil then
    Buffer.AddAnsiChar(AnsiChar(0))
  else if PreviousTarget is TShip then
  begin
    Buffer.AddAnsiChar(AnsiChar(1));
    Buffer.AddDWord((PreviousTarget as TShip).Id);
  end
  else if PreviousTarget is TItem then
  begin
    Buffer.AddAnsiChar(AnsiChar(2));
    Buffer.AddDWord((PreviousTarget as TItem).Id);
  end
  else if PreviousTarget is TAsteroid then
  begin
    Buffer.AddAnsiChar(AnsiChar(3));
    Buffer.AddDWord((PreviousTarget as TAsteroid).Id);
  end
  else if PreviousTarget is TMissile then
  begin
    Buffer.AddAnsiChar(AnsiChar(4));
    Buffer.AddDWord((PreviousTarget as TMissile).Id);
  end
  else
    Buffer.AddAnsiChar(AnsiChar(0));
  Buffer.AddSingle(LastTargetPosition.X);
  Buffer.AddSingle(LastTargetPosition.Y);
  Buffer.AddSingle(LastTargetDistance);
end;

procedure TCustomMissile.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(WeaponInfo.ConfigName);
  inherited SaveToBuffer(Buffer);
end;

procedure TMissile.LoadFromBuffer(Buffer: TBufEC; World: TGalaxy);
var
  ModuleNumber: Integer;
  function FindLegacyMissileMicroModuleIndex(
      ConfigNumber: Integer
  ): Integer; // @addr $4F0A5C @ida "int __usercall $name@<eax>(int ConfigNumber@<eax>, void *ParentFrame@<^0>);" @note "Nested legacy lookup; caller pops the unused static link."
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to High(MicroModuleTemplates) do
      if MicroModuleTemplates[I].ConfigNumber = ConfigNumber then
      begin
        Result := I + 1;
        Exit;
      end;
  end;
begin
  Id := Buffer.GetUInt32;
  if Id >= World.NextMissileId then
    World.NextMissileId := Id + 1;
  if LoadedSaveVersion >= 159 then
    WeaponId := Buffer.GetUInt32;
  ItemType := Byte(MigrateSavedItemType(Buffer.GetByte));
  TechLevel := Buffer.GetByte;
  if LoadedSaveVersion >= 100 then
  begin
    MinDamage := Buffer.GetInt32;
    MaxDamage := Buffer.GetInt32;
  end
  else
  begin
    MinDamage := Buffer.GetByte;
    MaxDamage := Buffer.GetByte;
  end;
  if LoadedSaveVersion >= 157 then
  begin
    MicroModuleIndex := ReadSavedMicroModuleIndex(Buffer);
    SpecialModuleIndex := ReadSavedMicroModuleIndex(Buffer);
  end
  else if LoadedSaveVersion >= 82 then
  begin
    MicroModuleIndex := Buffer.GetInt32;
    SpecialModuleIndex := Buffer.GetInt32;
    if LoadedSaveVersion >= 98 then
    begin
      if MicroModuleIndex > 0 then
      begin
        ModuleNumber := Buffer.GetInt32;
        if ((High(MicroModuleTemplates) + 1) < MicroModuleIndex)
            or (MicroModuleTemplates[MicroModuleIndex - 1].ConfigNumber <> ModuleNumber) then
          MicroModuleIndex := FindLegacyMissileMicroModuleIndex(ModuleNumber);
      end;
      if SpecialModuleIndex > 0 then
      begin
        ModuleNumber := Buffer.GetInt32;
        if ((High(MicroModuleTemplates) + 1) < SpecialModuleIndex)
            or (MicroModuleTemplates[SpecialModuleIndex - 1].ConfigNumber <> ModuleNumber) then
          SpecialModuleIndex := FindLegacyMissileMicroModuleIndex(ModuleNumber);
      end;
    end;
  end
  else
  begin
    MicroModuleIndex := 0;
    SpecialModuleIndex := 0;
  end;
  if LoadedSaveVersion < 98 then
  begin
    if MicroModuleIndex <> 0 then
    begin
      if MicroModuleTemplates[MicroModuleIndex - 1].ConfigNumber > 24 then
        Inc(MicroModuleIndex);
      if MicroModuleTemplates[MicroModuleIndex - 1].ConfigNumber > 124 then
        Inc(MicroModuleIndex);
      if MicroModuleTemplates[MicroModuleIndex - 1].ConfigNumber > 219 then
        Inc(MicroModuleIndex);
    end;
    if SpecialModuleIndex <> 0 then
    begin
      if MicroModuleTemplates[SpecialModuleIndex - 1].ConfigNumber > 24 then
        Inc(SpecialModuleIndex);
      if MicroModuleTemplates[SpecialModuleIndex - 1].ConfigNumber > 124 then
        Inc(SpecialModuleIndex);
      if MicroModuleTemplates[SpecialModuleIndex - 1].ConfigNumber > 219 then
        Inc(SpecialModuleIndex);
    end;
  end;
  Position.X := Buffer.GetSingle;
  Position.Y := Buffer.GetSingle;
  Direction := Buffer.GetSingle;
  TurnDirection := Buffer.GetSingle;
  CurrentStar := TStar(Buffer.GetUInt32);
  OwnerShip := TShip(Buffer.GetUInt32);
  SavedTargetKind := Buffer.GetByte;
  if SavedTargetKind = 0 then
    Target := nil
  else
    Target := TObject(Buffer.GetUInt32);
  ShotIndex := Buffer.GetByte;
  FlightTicks := Buffer.GetInt32;
  SourceHeading := Buffer.GetSingle;
  Speed := Buffer.GetSingle;
  if LoadedSaveVersion >= 95 then
    MaximumSpeed := Buffer.GetSingle
  else
    MaximumSpeed :=
        RemapClamped(TechLevel, 1, 8, GetWeaponInfo.MissileMinSpeed, GetWeaponInfo.MissileMaxSpeed);
  SavedPreviousTargetKind := Buffer.GetByte;
  if SavedPreviousTargetKind = 0 then
    PreviousTarget := nil
  else
    PreviousTarget := TObject(Buffer.GetUInt32);
  LastTargetPosition.X := Buffer.GetSingle;
  LastTargetPosition.Y := Buffer.GetSingle;
  LastTargetDistance := Buffer.GetSingle;
end;

procedure TCustomMissile.LoadFromBuffer(Buffer: TBufEC; World: TGalaxy);
begin
  WeaponInfo := World.RequireCustomWeaponInfo(Buffer.ReadWideString);
  inherited LoadFromBuffer(Buffer, World);
end;

procedure TMissile.ResolveLoadedReferences(World: TGalaxy);
begin
  CurrentStar := TObject(World.IdToStar(Cardinal(CurrentStar))) as TStar;
  OwnerShip := TObject(World.IdToShip(Cardinal(OwnerShip), True)) as TShip;
  if SavedTargetKind = 1 then
    Target := TObject(World.IdToShip(Cardinal(Target), True)) as TShip
  else if SavedTargetKind = 2 then
    Target := TObject(World.IdToItem(Cardinal(Target), True)) as TItem
  else if SavedTargetKind = 3 then
    Target := TObject(World.IdToAsteroid(Cardinal(Target))) as TAsteroid
  else if SavedTargetKind = 4 then
    Target := TObject(World.IdToMissile(Cardinal(Target))) as TMissile;
  if SavedPreviousTargetKind = 1 then
    PreviousTarget := TObject(World.IdToShip(Cardinal(PreviousTarget), True)) as TShip
  else if SavedPreviousTargetKind = 2 then
    PreviousTarget := TObject(World.IdToItem(Cardinal(PreviousTarget), True)) as TItem
  else if SavedPreviousTargetKind = 3 then
    PreviousTarget := TObject(World.IdToAsteroid(Cardinal(PreviousTarget))) as TAsteroid
  else if SavedPreviousTargetKind = 4 then
    PreviousTarget := TObject(World.IdToMissile(Cardinal(PreviousTarget))) as TMissile;
end;

function TMissile.GetGraphObject: TObjectSE;
begin
  if Graphic = nil then
  begin
    RetainSpaceObject(
        Graphic,
        CreateSpaceObjectByName('Missile', 'Missile.w' + GetGraphSuffix, Classes.Point(0, 0))
    );
    Graphic.SetPosition(Position);
    Graphic.SetAngle(HeadingDegreesToByte(Direction));
    Graphic.SetAlpha(255);
  end;
  Result := Graphic;
end;

procedure TMissile.PrepareTurnMovement(StepIndex: Integer; RecordFilm, PlayShotSound: Boolean);
var
  PathLength, TurnFraction: Single;
  Config, Palette: TBlockParEC;
begin
  if RecordFilm then
  begin
    FilmObject := PrimaryFilm.AddObject(Id, GetGraphObject);
    PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
    PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, HeadingDegreesToByte(Direction));
    PrimaryFilm.AttachObject(StepIndex, FilmObject);
    if PlayShotSound then
    begin
      if Self is TCustomMissile then
        Config := GameDataConfig.GetBlockByPath('SE.' + GetWeaponInfo.PrimarySE)
      else
        Config := GameDataConfig.GetBlockByPath('SE.Weapon.' + IntToStr(ItemType - 50));
      Palette := Config.FindBlock('Palettes');
      if Palette <> nil then
        Palette := Palette.FindBlock(IntToStr(GetShotVisual));
      if (Palette <> nil) and (Palette.CountParams('SoundShot') > 0) then
        PrimaryFilm.PlayObjectSound(StepIndex, FilmObject, Palette.GetParam('SoundShot'))
      else if Config.CountParams('SoundShot') > 0 then
        PrimaryFilm.PlayObjectSound(StepIndex, FilmObject, Config.GetParam('SoundShot'))
      else if Self is TCustomMissile then
        PrimaryFilm.PlayObjectSound(StepIndex, FilmObject, 'Sound.shot' + GetWeaponInfo.ConfigName)
      else
        PrimaryFilm.PlayObjectSound(StepIndex, FilmObject, 'Sound.shot' + IntToStr(ItemType - 50));
    end;
  end;
  if FlightTicks = 0 then
  begin
    if OwnerShip <> nil then
    begin
      SourceHeading := OwnerShip.MovementDirection;
      Speed := Max(OwnerShip.Speed, MaximumSpeed);
      PathLength := 0;
      if (OwnerShip.MovementPath <> nil) and (OwnerShip.MovementPath.NodeCount > 0) then
      begin
        PathLength := OwnerShip.MovementPath.GetLength;
        TurnFraction := StepIndex / CurrentStar.MovementStepCount;
        if 1 - TurnFraction = 0 then
          PathLength := 0
        else
          PathLength := PathLength / (1 - TurnFraction);
        if HeadingDifferenceDegrees(
                OwnerShip.MovementDirection,
                RadiansToHeadingDegrees(
                    ArcTan2(
                        OwnerShip.MovementPath.ActiveTail.Position.X - OwnerShip.Position.X,
                        -(OwnerShip.MovementPath.ActiveTail.Position.Y - OwnerShip.Position.Y)
                    )
                ))
            < 0 then
          TurnDirection := -1
        else
          TurnDirection := 1;
      end
      else
        TurnDirection := 1;
      // The initial maximum above is overwritten in the native routine too.
      Speed := PathLength + 100;
      if Speed < 200 then
        Speed := 200;
    end
    else
    begin
      Speed := MaximumSpeed;
      SourceHeading := 0;
      TurnDirection := 0;
    end;
    Inc(FlightTicks);
  end;
  OvershootTicks := -1;
end;

function TMissile.StepDay(StepIndex: Integer; RecordFilm: Boolean): TObject;
var
  StepScale, TargetHeading, Delta, Separation: Double;
  PreviousPosition, TargetPosition: TPointF;
  OtherMissile: TMissile;
  I, J, VerticalSign: Integer;
  Asteroid: TAsteroid;
  Ship: TShip;
  HasTarget: Boolean;
  Item: TItem;
  DesiredSpeed, DistanceSquared: Single;
  Drop: PMovingDropItemEntry;
  Effect: TObjectSE;
  EffectFilm: TEFilmObj;
  Stage: Integer;
begin
  Stage := 0;
  try
    Result := nil;
    PreviousPosition := Position;
    StepScale := 200 / CurrentStar.MovementStepCount;
    Inc(FlightTicks, Round(StepScale));
    TargetPosition := MakePointF(0, 0);
    HasTarget := False;
    DesiredSpeed := MaximumSpeed;
    Stage := 1;
    if FlightTicks < 200 then
    begin
      Stage := 2;
      if OwnerShip <> nil then
      begin
        Stage := 3;
        Delta := OwnerShip.MovementDirection - SourceHeading;
        SourceHeading := OwnerShip.MovementDirection;
        Separation := ShotIndex * 0.1 + 0.1;
        if Delta > 0 then
          Delta := Delta - Separation * StepScale
        else if Delta < 0 then
          Delta := Delta + Separation * StepScale;
        if Delta < -0.5 * StepScale then
          Delta := -0.5 * StepScale
        else if Delta > 0.5 * StepScale then
          Delta := 0.5 * StepScale;
        Direction := WrapHeadingDegrees(Direction + Delta);
        if RecordFilm then
          PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, HeadingDegreesToByte(Direction));
        Position.X :=
            Position.X + Sin(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
        Position.Y :=
            Position.Y - Cos(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
      end
      else
      begin
        Stage := 4;
        Position.X :=
            Position.X + Sin(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
        Position.Y :=
            Position.Y - Cos(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
      end;
    end
    else
    begin
      Stage := 5;
      RetargetTorpedo;
      Stage := 6;
      if Target <> nil then
      begin
        if (Target is TShip)
            and (TShip(Target).CurrentStar = CurrentStar)
            and TShip(Target).InNormalSpace then
        begin
          Stage := 7;
          TargetPosition := TShip(Target).Position;
          HasTarget := True;
        end
        else if Target is TItem then
        begin
          Stage := 8;
          TargetPosition := TItem(Target).Position;
          HasTarget := True;
        end
        else if Target is TAsteroid then
        begin
          Stage := 9;
          TargetPosition := TAsteroid(Target).Position;
          HasTarget := True;
        end
        else if Target is TMissile then
        begin
          Stage := 10;
          TargetPosition := TMissile(Target).Position;
          HasTarget := True;
        end
        else
        begin
          Stage := 11;
          PreviousTarget := Target;
          Target := nil;
        end;
      end;
      if HasTarget then
      begin
        Stage := 12;
        VerticalSign := -1;
        if (FlightTicks > 1)
            and (LastTargetPosition.X = TargetPosition.X)
            and (LastTargetPosition.Y = TargetPosition.Y) then
        begin
          Stage := 13;
          DistanceSquared := PointDistanceSquared(Position, TargetPosition);
          if (LastTargetDistance < DistanceSquared) and (OvershootTicks < 0) then
            OvershootTicks := RandomIntRange(Round(Speed / 40), Round(Speed / 10));
          LastTargetDistance := DistanceSquared;
          if OvershootTicks > 0 then
          begin
            VerticalSign := 1;
            Dec(OvershootTicks);
          end;
        end;
        LastTargetPosition := TargetPosition;
        TargetHeading :=
            RadiansToHeadingDegrees(
                ArcTan2(
                    TargetPosition.X - Position.X,
                    (TargetPosition.Y - Position.Y) * VerticalSign
                )
            );
        Stage := 14;
        Delta := HeadingDifferenceDegrees(Direction, TargetHeading);
        if Abs(Delta) <= 3 * StepScale then
          Direction := TargetHeading
        else
        begin
          if Delta < 0 then
            Direction := WrapHeadingDegrees(Direction - 3 * StepScale)
          else
            Direction := WrapHeadingDegrees(Direction + 3 * StepScale);
        end;
        Stage := 14;
        if RecordFilm then
          PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, HeadingDegreesToByte(Direction));
      end;
      Stage := 15;
      if Abs(Speed - DesiredSpeed) <= 10 then
        Speed := DesiredSpeed
      else if Speed < DesiredSpeed then
        Speed := Speed + 10
      else if Speed > DesiredSpeed then
        Speed := Speed - 10;
      Position.X :=
          Position.X + Sin(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
      Position.Y :=
          Position.Y - Cos(HeadingDegreesToRadians(Direction)) * (Speed / 200 * StepScale);
    end;
    Stage := 16;
    if RecordFilm then
      PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
    Stage := 17;
    for I := 0 to CurrentStar.Missiles.Count - 1 do
    begin
      Stage := 18;
      OtherMissile := TMissile(CurrentStar.Missiles[I]);
      if (OtherMissile <> Self)
          and ((Target = OtherMissile) or (OtherMissile.Target = Self))
          and SegmentIntersectsCircle(PreviousPosition, Position, OtherMissile.Position, 10) then
      begin
        Stage := 19;
        if RecordFilm then
        begin
          Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0), 0, -1);
          EffectFilm := PrimaryFilm.AddObject(0, Effect);
          PrimaryFilm.SetObjectPosition(StepIndex, EffectFilm, Position);
          PrimaryFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
          PrimaryFilm.AttachObject(StepIndex, EffectFilm);
          PrimaryFilm.DetachObject(StepIndex, FilmObject);
          ReleaseSpaceObject(Graphic);
          PrimaryFilm.DetachObject(StepIndex, OtherMissile.FilmObject);
          ReleaseSpaceObject(OtherMissile.Graphic);
        end;
        OtherMissile.DestroyQueued := True;
        DestroyQueued := True;
        Exit;
      end;
    end;
    Stage := 20;
    for I := 0 to CurrentStar.Items.Count - 1 do
    begin
      Stage := 21;
      Item := TItem(CurrentStar.Items[I]);
      Stage := 22;
      if ((GetWeaponInfo.ShotType <> wstTorpedo) or (Target = Item))
          and SegmentIntersectsCircle(PreviousPosition, Position, Item.Position, 10) then
      begin
        Stage := 23;
        J := CurrentStar.MovingDropItems.Count - 1;
        while J >= 0 do
        begin
          Drop := CurrentStar.MovingDropItems[J];
          if Drop.Payload = Item then
            Break;
          Dec(J);
        end;
        if J < 0 then
        begin
          Result := Item;
          Exit;
        end;
      end;
    end;
    Stage := 24;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Stage := 25;
      Ship := TShip(CurrentStar.Ships[I]);
      if not Ship.IsHullDestroyed and Ship.InNormalSpace then
      begin
        if TryReturnToOwner(StepIndex, RecordFilm, PreviousPosition, Ship) then
          Exit;
        if (OwnerShip <> Ship)
            and ((Target = Ship)
                or (OwnerShip = nil)
                or (OwnerShip.GetRelationLevelToShip(Ship) = rlHostile)) then
        begin
          Stage := 26;
          if SegmentIntersectsCircle(PreviousPosition, Position, Ship.Position, 20) then
          begin
            Result := Ship;
            Exit;
          end;
        end;
      end;
    end;
    Stage := 27;
    for I := 0 to CurrentStar.Asteroids.Count - 1 do
    begin
      Asteroid := TAsteroid(CurrentStar.Asteroids[I]);
      Stage := 28;
      if SegmentIntersectsCircle(PreviousPosition, Position, Asteroid.Position, 10) then
      begin
        Result := Asteroid;
        Exit;
      end;
    end;
    Stage := 29;
    if SegmentIntersectsCircle(
        PreviousPosition,
        Position,
        MakePointF(0, 0),
        CurrentStar.Radius * 0.7) then
    begin
      if RecordFilm then
      begin
        Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0), 0, -1);
        EffectFilm := PrimaryFilm.AddObject(0, Effect);
        PrimaryFilm.SetObjectPosition(StepIndex, EffectFilm, Position);
        PrimaryFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
        PrimaryFilm.AttachObject(StepIndex, EffectFilm);
        PrimaryFilm.DetachObject(StepIndex, FilmObject);
        ReleaseSpaceObject(Graphic);
      end;
      DestroyQueued := True;
      Exit;
    end;
    begin
      Stage := 30;
      if (FlightTicks > 1000)
          and ((Target = nil)
              or not (FlightTicks * 0.005 * MaximumSpeed < GetWeaponInfo.MissileRange)) then
      begin
        if RecordFilm then
        begin
          Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0), 0, -1);
          EffectFilm := PrimaryFilm.AddObject(0, Effect);
          PrimaryFilm.SetObjectPosition(StepIndex, EffectFilm, Position);
          PrimaryFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
          PrimaryFilm.AttachObject(StepIndex, EffectFilm);
          PrimaryFilm.DetachObject(StepIndex, FilmObject);
          ReleaseSpaceObject(Graphic);
        end;
        DestroyQueued := True;
        Exit;
      end;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create('Error in procedure TMissile.StepDay, label = ' + IntToStr(Stage));
    end;
  end;
end;

function TMissile.TryReturnToOwner(
    StepIndex: Integer;
    RecordFilm: Boolean;
    PreviousPosition: TPointF;
    Ship: TShip
): Boolean;
var
  I: Integer;
  FoundWeapon: Boolean;
  Item: TItem;
  Weapon: TWeapon;
  Effect: TObjectSE;
  EffectFilm: TEFilmObj;
begin
  Result := False;
  if (GetWeaponInfo.ShotType = wstTorpedo)
      and (OwnerShip <> nil)
      and (Ship = OwnerShip)
      and (Target = OwnerShip)
      and SegmentIntersectsCircle(PreviousPosition, Position, Ship.Position, 20) then
  begin
    FoundWeapon := False;
    for I := 1 to Ship.WeaponCount do
    begin
      Weapon := Ship.Weapons[I];
      if (Weapon <> nil) and (Weapon.Id = WeaponId) then
      begin
        FoundWeapon := True;
        if Weapon.Ammo < Weapon.AmmoCapacity then
          Inc(Weapon.Ammo);
        Break;
      end;
    end;
    if not FoundWeapon then
      for I := 1 to Ship.Inventory.Count - 1 do
      begin
        Item := Ship.Inventory[I];
        if Item.Id = WeaponId then
        begin
          if (Item is TWeapon) and (TWeapon(Item).Ammo < TWeapon(Item).AmmoCapacity) then
            Inc(TWeapon(Item).Ammo);
          Break;
        end;
      end;
    if RecordFilm then
    begin
      Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0), 0, -1);
      EffectFilm := PrimaryFilm.AddObject(0, Effect);
      PrimaryFilm.SetObjectPosition(StepIndex, EffectFilm, Position);
      PrimaryFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
      PrimaryFilm.AttachObject(StepIndex, EffectFilm);
      PrimaryFilm.DetachObject(StepIndex, FilmObject);
      ReleaseSpaceObject(Graphic);
    end;
    DestroyQueued := True;
    Result := True;
  end;
end;

procedure TMissile.RetargetTorpedo;
var
  BestDistance, Distance: Single;
  I: Integer;
  Ship, BestShip: TShip;
begin
  if (GetWeaponInfo.ShotType = wstTorpedo)
      and (OwnerShip <> nil)
      and ((Target = nil) or (Target = OwnerShip)) then
  begin
    BestDistance := 1E30;
    BestShip := nil;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if not Ship.IsOutsideStarSpace
          and (Ship <> PreviousTarget)
          and (Ship.GetRelationLevelToShip(OwnerShip) <= rlHostile)
          and (not (OwnerShip is TKling)
              or not (OwnerShip as TKling).IsPlayerCamouflageEffective(Ship))
          and (not (Ship is TKling)
              or not (Ship as TKling).IsPlayerCamouflageEffective(OwnerShip)) then
      begin
        Distance := PointDistance(Ship.Position, Position);
        if (Distance <= 700) and (Distance < BestDistance) then
        begin
          BestDistance := Distance;
          BestShip := Ship;
        end;
      end;
    end;
    if BestShip <> nil then
      Target := BestShip
    else if OwnerShip.InNormalSpace and (OwnerShip.CurrentStar = CurrentStar) then
      Target := OwnerShip
    else
      Target := nil;
  end;
end;

function TMissile.GetDisplayName: WideString;
begin
  Result := LocalizedText('Items.Weapon.Missile.' + GetGraphSuffix + '.Name');
  if SpecialModuleIndex <> 0 then
    Result := Result + ' ' + MicroModuleTemplates[SpecialModuleIndex - 1].Name;
end;

function TMissile.GetInfoText: WideString;
var
  SpeedText, DamageText: WideString;
  DamageFactor: Single;
begin
  Result := LocalizedText('Items.Weapon.Missile.' + GetGraphSuffix + '.Text') + #13#10;
  if OwnerShip <> nil then
    Result :=
        Result
            + FormatText1(
                LocalizedText('Items.Weapon.Missile.TextFrom'),
                '<color=255,240,100>',
                '<Name>',
                OwnerShip.GetName)
            + #13#10;
  if (Target <> nil) and (Target is TAsteroid) then
    Result :=
        Result
            + FormatText1(
                LocalizedText('Items.Weapon.Missile.TextTarget'),
                '<color=255,240,100>',
                '<Name>',
                TAsteroid(Target).GetDisplayName)
            + #13#10
  else if (Target <> nil) and (Target is TItem) then
    Result :=
        Result
            + FormatText1(
                LocalizedText('Items.Weapon.Missile.TextTarget'),
                '<color=255,240,100>',
                '<Name>',
                TItem(Target).GetDisplayName)
            + #13#10
  else if (Target <> nil) and (Target is TShip) then
    Result :=
        Result
            + FormatText1(
                LocalizedText('Items.Weapon.Missile.TextTarget'),
                '<color=255,240,100>',
                '<Name>',
                TShip(Target).GetName)
            + #13#10
  else if (Target <> nil) and (Target is TMissile) then
    Result :=
        Result
            + FormatText1(
                LocalizedText('Items.Weapon.Missile.TextTarget'),
                '<color=255,240,100>',
                '<Name>',
                TMissile(Target).GetDisplayName)
            + #13#10
  else
    Result := Result + LocalizedText('Items.Weapon.Missile.TextNoTarget') + #13#10;
  if OwnerShip <> nil then
    if GetPlayer.HasScannerArtefact(OwnerShip) then
    begin
      if GetPlayer.CanResolveObjectWithScanner(OwnerShip)
          or (GetPlayer = OwnerShip)
          or (GetPlayer = OwnerShip.PartnerShip)
          or (OwnerShip.TypeId = stTranclucator) then
      begin
        SpeedText := IntToStr(Round(Speed));
        if (OwnerShip.TypeId = stKling) and ((OwnerShip as TKling).KlingType = ktBoss) then
          DamageFactor := Galaxy.InterpolateDifficulty(-1, 0.7, 1, 1.2, 1.5) * 2
        else
          DamageFactor := 1;
        DamageText :=
            IntToStr(Round(MinDamage * DamageFactor))
                + '-'
                + IntToStr(Round(MaxDamage * DamageFactor));
      end
      else
      begin
        SpeedText := '???';
        DamageText := '???';
      end;
      Result :=
          Result
              + FormatText1(
                  LocalizedText('Items.Weapon.Missile.TextSpeed'),
                  '<color=255,240,100>',
                  '<Speed>',
                  SpeedText)
              + ', ';
      Result :=
          Result
              + FormatText1(
                  LocalizedText('Items.Weapon.Missile.TextDamage'),
                  '<color=255,240,100>',
                  '<Damage>',
                  DamageText)
              + #13#10;
    end;
end;

function TMissile.CanBeHit(Attacker: TShip; UnusedWeapon: TWeapon): Boolean;
var
  Roll: Integer;
begin
  if Attacker = nil then
    Roll := NextRandomIntRange(1, 100, Galaxy.RandomState)
  else
  begin
    if (Attacker is TKling) and (Ord((Attacker as TKling).KlingType) = 0) then
    begin
      Result := True;
      Exit;
    end;
    Roll := NextRandomIntRange(1, 100, Attacker.RandomState);
  end;
  Result := Roll <= GetWeaponInfo.MissileChanceToBeHit;
end;

procedure TMissile.ClearReferencesTo(Obj: TObject);
begin
  if OwnerShip = Obj then
    OwnerShip := nil;
  if Target = Obj then
    Target := nil;
  if PreviousTarget = Obj then
    PreviousTarget := nil;
end;

function TMissile.GetShotVisual: Integer;
begin
  if (SpecialModuleIndex = 0) or (MicroModuleTemplates[SpecialModuleIndex - 1].ShotVisual = -1) then
    Result := GetWeaponInfo.DefaultPalette
  else
    Result := MicroModuleTemplates[SpecialModuleIndex - 1].ShotVisual;
end;

function TMissile.GetGraphSuffix: WideString;
begin
  Result := '';
  if SpecialModuleIndex <> 0 then
    Result := MicroModuleTemplates[SpecialModuleIndex - 1].MissileGraph;
  if Result = '' then
    Result := IntToStr(ItemType - 50 + 1);
end;

function TCustomMissile.GetGraphSuffix: WideString;
begin
  Result := '';
  if SpecialModuleIndex <> 0 then
    Result := MicroModuleTemplates[SpecialModuleIndex - 1].MissileGraph;
  if Result = '' then
    Result := WeaponInfo.ConfigName;
end;

function TMissile.GetWeaponInfo: PWeaponInfo;
begin
  Result := @WeaponInfos[ItemType];
end;

function TCustomMissile.GetWeaponInfo: PWeaponInfo;
begin
  Result := WeaponInfo;
end;

procedure LinkRecoveredTypes;
begin
  TAsteroid.ClassName;
  TCustomMissile.ClassName;
  TItem.ClassName;
  TKling.ClassName;
  TMissile.ClassName;
  TShip.ClassName;
  TStar.ClassName;
  TWeapon.ClassName;
end;
end.
