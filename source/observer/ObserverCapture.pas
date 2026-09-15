{$EXCESSPRECISION OFF}
unit ObserverCapture;

// Immutable presentation data. Only the simulation worker writes a recording;
// the UI receives it after the worker has finished. Never retains game pointers.
interface
uses
  Classes,
  Contnrs,
  Types,
  EC_Struct,
  aGalaxy,
  aEObjInfo;
const
  ObserverSamples = 201;
type
  TObserverPose = record
    Position: TPointF;
    Angle: Byte;
    Visible: Boolean;
    Hull, HullMax, Speed, Order: Integer;
  end;
  TObserverTrack = class
    Key: AnsiString;
    Kind: Integer;
    GraphKey, SceneClass, Name: WideString;
    Category, Info, Equipment, Portrait, TargetInfo: WideString;
    ShipInfo: TEOTShip;
    PlanetInfo: TEOTPlanet;
    ItemInfo: TEOTItem;
    OrbitRadius: Double;
    Mineral: Boolean;
    Size: TPoint;
    Radius, SurfaceStep, RotationInterval, SurfaceOffset: Integer;
    DepartureStep: Integer;
    RingKind, Owner: Byte;
    Poses: array[0..ObserverSamples - 1] of TObserverPose;
  end;
  TObserverTrackSlot = record
    Id: Cardinal;
    Kind: Integer;
    Track: TObserverTrack;
  end;
  TObserverTrackIndex = array of TObserverTrackSlot;
  TObserverEffect = class
    AtTime: Double;
    SourceKey, TargetKey: AnsiString;
    SourcePosition, TargetPosition: TPointF;
    TargetSize: TPoint;
    GraphKey: WideString;
    Palette, Damage, Destruction: Integer;
    Color: Cardinal;
    Destroyed: Boolean;
  end;
  TObserverTransit = class
    ShipId, OriginId, DestinationId: Cardinal;
    Owner: Byte;
    Name: WideString;
    TotalDays, RemainingDays: Integer;
    BeginProgress, EndProgress, BeginAt, EndAt: Double;
    DeparturePosition, ArrivalPosition: TPointF;
    Departed, Arrived: Boolean;
  end;
  TObserverSystem = class
    Id, Steps, Background, Diameter, Ships, Faction: Integer;
    Name: WideString;
    MapPosition: TPointF;
    Tracks: TFPHashObjectList;
    Effects: Contnrs.TObjectList;
    CapturedStep: Integer;
    constructor Create(Star: TStar);
    destructor Destroy; override;
    procedure Capture(Star: TStar; Step: Integer);
  private
    TrackIndex: TObserverTrackIndex;
    procedure GrowTrackIndex;
    function FindTrackSlot(ObjectId: Cardinal; Kind: Integer): SizeUInt;
  end;
  TObserverRecording = class
    Turn: Integer;
    Systems, Transits: TFPHashObjectList;
    constructor Create;
    destructor Destroy; override;
    procedure Capture(Star: TStar; Step, StepCount: Integer);
    procedure CaptureAll;
    procedure CaptureTransit(ShipObject: TObject; AtTime: Double; Initial: Boolean);
    procedure CaptureTransits(Initial: Boolean);
  end;
var
  ObserverWriting: TObserverRecording;
procedure CaptureObserverStep(Star: TObject; Step, StepCount: Integer);
procedure CaptureObserverHit(
    Star, Source, Target, Weapon: TObject;
    Damage: Integer;
    Color: Cardinal;
    Kind: Integer
);
function SampleObserverPose(
    Track: TObserverTrack;
    Progress: Double;
    Steps: Integer;
    Still: Boolean
): TObserverPose;
implementation
uses
  SysUtils,
  Math,
  aShip,
  aPlayer,
  aPlanet,
  aAsteroid,
  aMissile,
  aItem,
  SE_Space,
  SE_Process,
  SE_Planet,
  SE_Star,
  SE_Ruins,
  EC_Str,
  aMyFunction,
  aConst,
  aGalaxyStruct,
  GlobalsV,
  ObserverHooks;

function SampleObserverPose(
    Track: TObserverTrack;
    Progress: Double;
    Steps: Integer;
    Still: Boolean
): TObserverPose;
var
  A, B, D: Integer;
  F: Double;
  Next: TObserverPose;
begin
  if Still then
    Exit(Track.Poses[0]);
  Progress := EnsureRange(Progress, 0.0, 1.0) * Steps;
  A := Floor(Progress);
  B := Min(A + 1, Steps);
  F := Progress - A;
  Result := Track.Poses[A];
  Next := Track.Poses[B];
  if Result.Visible and (Next.Visible or ((B > 0) and (Track.DepartureStep = B))) then
  begin
    Result.Position.X := Result.Position.X + (Next.Position.X - Result.Position.X) * F;
    Result.Position.Y := Result.Position.Y + (Next.Position.Y - Result.Position.Y) * F;
    D := (Integer(Next.Angle) - Integer(Result.Angle) + 384) mod 256 - 128;
    Result.Angle := Byte((Integer(Result.Angle) + Round(D * F) + 256) mod 256);
  end;
end;

constructor TObserverSystem.Create(Star: TStar);
begin
  inherited Create;
  Id := Star.Id;
  Name := Star.Name;
  Background := Star.BackgroundImage;
  Diameter := Star.ComputeMapDiameter;
  MapPosition := Star.Position;
  Faction := Ord(Star.ControlFaction);
  Steps := Star.MovementStepCount;
  if Steps <= 0 then
    Steps := 50;
  Tracks := TFPHashObjectList.Create(True);
  Effects := Contnrs.TObjectList.Create(True);
end;

destructor TObserverSystem.Destroy;
begin
  Tracks.Free;
  Effects.Free;
  inherited Destroy
end;

// CHANGE: PERFORMANCE - Resolve existing tracks by numeric identity without
// allocating and hashing a string for every object at every simulation step.
// Keep managed array allocation/finalization out of the per-pose lookup path.
procedure TObserverSystem.GrowTrackIndex;
var
  NewIndex: TObserverTrackIndex;
  I: SizeInt;
  Slot, Mask: SizeUInt;
begin
  SetLength(NewIndex, Max(16, Length(TrackIndex) * 2));
  Mask := Length(NewIndex) - 1;
  for I := 0 to High(TrackIndex) do
    if TrackIndex[I].Track <> nil then
    begin
      Slot :=
          ((SizeUInt(TrackIndex[I].Id) * 2654435761)
                  xor (SizeUInt(Cardinal(TrackIndex[I].Kind)) * 2246822519))
              and Mask;
      while NewIndex[Slot].Track <> nil do
        Slot := (Slot + 1) and Mask;
      NewIndex[Slot] := TrackIndex[I];
    end;
  TrackIndex := NewIndex;
end;

function TObserverSystem.FindTrackSlot(ObjectId: Cardinal; Kind: Integer): SizeUInt;
var
  Mask: SizeUInt;
begin
  if Tracks.Count >= Length(TrackIndex) div 2 then
    GrowTrackIndex;
  Mask := Length(TrackIndex) - 1;
  Result :=
      ((SizeUInt(ObjectId) * 2654435761) xor (SizeUInt(Cardinal(Kind)) * 2246822519)) and Mask;
  while (TrackIndex[Result].Track <> nil)
      and ((TrackIndex[Result].Id <> ObjectId) or (TrackIndex[Result].Kind <> Kind)) do
    Result := (Result + 1) and Mask;
end;

procedure TObserverSystem.Capture(Star: TStar; Step: Integer);
var
  I, J, StatusCount: Integer;
  Ship: TShip;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Missile: TMissile;
  Item: TItem;
  Track: TObserverTrack;
  NewTrack, SavedRandom, AsteroidTextReady: Boolean;
  AsteroidName, AsteroidInfo: WideString;
  GoodsReady: set of 0..7;
  GoodsText: array[0..7] of record
    Portrait, Info: WideString;
  end;
  GoodsKind: Integer;
  procedure Add(
      Id: Cardinal;
      Kind: Integer;
      Graphic: TObjectSE;
      const Position: TPointF;
      Angle: Byte;
      const Name: WideString
  );
  var
    Key: AnsiString;
    P: TPlanetSE;
    Slot: SizeUInt;
  begin
    Track := nil;
    NewTrack := False;
    if (Graphic = nil) or (Graphic.GraphKey = '') then
      Exit;
    Slot := FindTrackSlot(Id, Kind);
    Track := TrackIndex[Slot].Track;
    if Track = nil then
    begin
      NewTrack := True;
      Key := IntToStr(Kind) + ':' + UIntToStr(Id);
      Track := TObserverTrack.Create;
      Tracks.Add(Key, Track);
      TrackIndex[Slot].Id := Id;
      TrackIndex[Slot].Kind := Kind;
      TrackIndex[Slot].Track := Track;
      Track.Key := Key;
      Track.Kind := Kind;
      Track.Name := Name;
      Track.GraphKey := Graphic.GraphKey;
      Track.SceneClass := ClassSEtoName(Graphic);
      Track.Size := Graphic.Size;
      if Graphic is TPlanetSE then
      begin
        P := TPlanetSE(Graphic);
        Track.Radius := P.Radius;
        Track.RingKind := P.RingKind;
        Track.SurfaceStep := P.SurfaceMapStep;
        Track.SurfaceOffset := P.SurfaceMapOffset;
        Track.RotationInterval := Max(10, P.RotationTimerInterval);
        Track.Owner := P.MinimapOwner;
      end;
    end;
    Track.Poses[Step].Visible := True;
    Track.Poses[Step].Position := Position;
    Track.Poses[Step].Angle := Angle;
  end;
begin
  Step := EnsureRange(Step, 0, ObserverSamples - 1);
  CapturedStep := Step;
  AsteroidTextReady := False;
  GoodsReady := [];
  // A boundary may be captured again; explicitly remove stale presence bits.
  for I := 0 to Tracks.Count - 1 do
    TObserverTrack(Tracks[I]).Poses[Step].Visible := False;
  Add(Star.Id, 0, Star.Graphic, MakePointF(0, 0), 0, Star.Name);
  if Track <> nil then
  begin
    Track.Radius := Star.Radius;
    Track.Category := 'Star system';
    Track.Info := IntToStr(Star.Planets.Count) + ' planets';
    if Star.Graphic is TStarSE then
      Track.Portrait := TStarSE(Star.Graphic).StaticImagePath;
  end;
  for I := 0 to Star.Planets.Count - 1 do
  begin
    Planet := TPlanet(Star.Planets[I]);
    Add(Planet.Id, 1, TObjectSE(Planet.Graphic), Planet.GetPosition, 0, Planet.Name);
    if (Track <> nil) and NewTrack then
    begin
      Track.Category := 'Planet';
      Track.OrbitRadius := Planet.Orbit.Radius;
      Track.PlanetInfo.OwnerId := Planet.OwnerId;
      Track.PlanetInfo.RaceId := Planet.RaceId;
      Track.PlanetInfo.Population := Planet.Population;
      Track.PlanetInfo.Economy := Planet.Economy;
      Track.PlanetInfo.Government := Planet.Government;
      Track.PlanetInfo.Relation := Planet.GetRelationLevelToShip(GetPlayer);
      Track.PlanetInfo.Faction := Planet.GetFactionResourceName;
      Track.PlanetInfo.UnexploredWater := Planet.WaterTiles - Planet.WaterExplored;
      Track.PlanetInfo.UnexploredLand := Planet.LandTiles - Planet.LandExplored;
      Track.PlanetInfo.UnexploredHills := Planet.HillTiles - Planet.HillExplored;
      Track.PlanetInfo.TreasureHint := Planet.BuildNonCivilTreasureHintText;
      Track.Equipment :=
          'Orbit  '
              + IntToStr(Round(Planet.Orbit.Radius))
              + #13#10
              + 'Unexplored water / land / hills  '
              + IntToStr(Track.PlanetInfo.UnexploredWater)
              + ' / '
              + IntToStr(Track.PlanetInfo.UnexploredLand)
              + ' / '
              + IntToStr(Track.PlanetInfo.UnexploredHills)
              + #13#10
              + Track.PlanetInfo.TreasureHint;
      Track.Owner := Planet.OwnerId;
      Track.Info :=
          Planet.GetNativeRaceName
              + #13#10
              + Planet.GetGovernmentName
              + #13#10
              + PlanetEconomyInfo[Ord(Planet.Economy)].DisplayName
              + #13#10
              + 'Population  '
              + IntToStr(Planet.Population);
    end;
  end;
  Ships := 0;
  for I := 0 to Star.Ships.Count - 1 do
  begin
    Ship := TShip(Star.Ships[I]);
    if not Ship.InNormalSpace or Ship.DestroyQueued then
      Continue;
    Inc(Ships);
    Add(
        Ship.Id,
        2,
        Ship.Graphic,
        Ship.Position,
        HeadingDegreesToByte(Ship.MovementDirection),
        Ship.Name
    );
    if Track <> nil then
    begin
      Track.Poses[Step].Hull := Ship.GetHull.HullPoints;
      Track.Poses[Step].HullMax := Ship.GetHull.Weight;
      Track.Poses[Step].Speed := Ship.Speed;
      Track.Poses[Step].Order := Ord(Ship.Order);
      if NewTrack then
      begin
        Track.Owner := Ship.OwnerId;
        Track.Category := Ship.GetLocalizedTypeName;
        Track.Info := OwnerInfo[Ship.OwnerId and $7F].DisplayName;
        Track.ShipInfo.FullName := Ship.GetFullName(' ');
        Track.ShipInfo.Faction := Ship.GetFactionNameKey;
        Track.ShipInfo.DefenseText :=
            Ship.GetManeuverabilitySummary
                + IntToStr(Integer(Ship.GetDefensePercent) and $7F)
                + '% + '
                + IntToStr(Ship.GetArmor);
        Track.ShipInfo.DamageText := Ship.GetWeaponDamageSummary;
        Track.ShipInfo.HullFragility := Ship.GetHull.GetFragilityFactor([]);
        Track.ShipInfo.Relation := Ship.GetRelationLevelToShip(GetPlayer);
        Track.ShipInfo.CombatStatusText := Ship.GetCombatStatusDescription(StatusCount, True);
        Track.ShipInfo.CombatStatusCount := StatusCount;
        Track.Portrait := Ship.GetShipPortraitImagePath;
        if Ship.Graphic is TRuinsSE then
          Track.Portrait := TRuinsSE(Ship.Graphic).StaticImagePath;
        if Ship.OrderTarget is TStar then
          Track.TargetInfo := TStar(Ship.OrderTarget).Name
        else if Ship.OrderTarget is TPlanet then
          Track.TargetInfo := TPlanet(Ship.OrderTarget).Name
        else if Ship.OrderTarget is TShip then
          Track.TargetInfo := TShip(Ship.OrderTarget).Name;
        Track.Equipment :=
            'Jump range  '
                + IntToStr(Ship.JumpRange)
                + #13#10
                + 'Credits  '
                + IntToStr(Ship.Money)
                + #13#10
                + 'Repair  '
                + Ship.GetRepairPointsSummary;
        Track.Equipment := Track.Equipment + #13#10 + 'Skills  ';
        for J := 0 to 5 do
          Track.Equipment :=
              Track.Equipment + IntToStr(Ship.GetEffectiveSkillLevel(TPilotSkill(J), False)) + ' ';
        if Ship.FuelTanks <> nil then
          Track.Equipment :=
              Track.Equipment
                  + #13#10
                  + 'Fuel  '
                  + IntToStr(Ship.FuelTanks.Fuel)
                  + ' / '
                  + IntToStr(Ship.FuelTanks.Capacity);
        if Track.TargetInfo <> '' then
          Track.Equipment := Track.Equipment + #13#10 + 'Destination  ' + Track.TargetInfo;
        Track.Equipment :=
            Track.Equipment + #13#10 + '<color=255,240,160>Weapons: damage / range</color>';
        for J := 1 to Ship.WeaponCount do
          if Ship.Weapons[J] <> nil then
            Track.Equipment :=
                Track.Equipment
                    + #13#10
                    + Ship.Weapons[J].GetShortName
                    + '  '
                    + IntToStr(Ship.GetWeaponMinDamage(Ship.Weapons[J]))
                    + '-'
                    + IntToStr(Ship.GetWeaponMaxDamage(Ship.Weapons[J]))
                    + ' / '
                    + IntToStr(Ship.GetWeaponRange(Ship.Weapons[J]));
        Track.Equipment := Track.Equipment + #13#10 + '<color=255,240,160>Equipment / hold</color>';
        for J := 0 to Ship.Inventory.Count - 1 do
        begin
          Item := TItem(Ship.Inventory[J]);
          Track.Equipment :=
              Track.Equipment + #13#10 + Item.GetShortName + '  (' + IntToStr(Item.Weight) + ')';
          if Item is TEquipment then
            Track.Equipment :=
                Track.Equipment + '  ' + IntToStr(Round(TEquipment(Item).ConditionPercent)) + '%';
        end;
        for J := 0 to 7 do
          if Ship.CargoGoods[J].Count > 0 then
            Track.Equipment :=
                Track.Equipment
                    + #13#10
                    + GoodsMarket[J].DisplayName
                    + '  '
                    + IntToStr(Ship.CargoGoods[J].Count);

      end;
    end;
  end;
  for I := 0 to Star.Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Star.Asteroids[I]);
    Add(Asteroid.Id, 3, Asteroid.GraphObject, Asteroid.Position, 0, '');
    if (Track <> nil) and NewTrack then
    begin
      // CHANGE: PERFORMANCE - Store names once per track and share localized templates.
      // Keep the cache local so script/configuration changes between samples are respected.
      if not AsteroidTextReady then
      begin
        AsteroidName := LocalizedText('Asteroid.Name');
        AsteroidInfo := LocalizedText('Asteroid.Text');
        AsteroidTextReady := True;
      end;
      Track.Name := Asteroid.GetDisplayName(AsteroidName);
      Track.Category := 'Asteroid';
      Track.Info := Asteroid.GetInfoText(AsteroidInfo)
    end;
  end;
  for I := 0 to Star.Missiles.Count - 1 do
  begin
    Missile := TMissile(Star.Missiles[I]);
    if not Missile.DestroyQueued then
    begin
      Add(
          Missile.Id,
          4,
          Missile.Graphic,
          Missile.Position,
          HeadingDegreesToByte(Missile.Direction),
          ''
      );
      if (Track <> nil) and NewTrack then
      begin
        Track.Name := Missile.GetDisplayName;
        Track.Category := 'Missile';
        Track.Info := Missile.GetInfoText;
        if Missile.OwnerShip <> nil then
          Track.Owner := Missile.OwnerShip.OwnerId;
      end;
    end;
  end;
  for I := 0 to Star.Items.Count - 1 do
  begin
    Item := TItem(Star.Items[I]);
    // Remote systems lazily create cargo graphics. Use the presentation RNG
    // for that descriptor, including saves with chaotic random mode enabled.
    SavedRandom := ObserverVisualRandom;
    ObserverVisualRandom := True;
    try
      // CHANGE: PERFORMANCE - Avoid rebuilding localized loot names at every simulation step.
      Add(Item.Id, 5, Item.GetGraphObject, Item.Position, 0, '');
      if (Track <> nil) and NewTrack then
        Track.Name := Item.GetDisplayName;
    finally
      ObserverVisualRandom := SavedRandom
    end;
    if (Track <> nil) and NewTrack then
    begin
      Track.Mineral := (Item is TGoods) and TGoods(Item).NaturalFlag;
      if Track.Mineral then
        Track.Category := 'Minerals'
      else
        Track.Category := 'Cargo / loot';
      Track.ItemInfo.Weight := Item.Weight;
      Track.ItemInfo.Cost := Item.Cost;
      Track.ItemInfo.ItemType := Item.ItemType;
      Track.ItemInfo.Faction := Item.GetOwnerConfigName;
      Track.ItemInfo.ConditionPercent := 100;
      Track.ItemInfo.Fragility := 1;
      if Item is TEquipment then
      begin
        Track.ItemInfo.ConditionPercent := TEquipment(Item).ConditionPercent;
        Track.ItemInfo.Fragility := TEquipment(Item).GetFragilityFactor([])
      end;
      if Item is TGoods then
      begin
        // CHANGE: PERFORMANCE - Thousands of mineral drops share these two strings.
        // Only cache within this capture; names and numeric item data remain per object.
        GoodsKind := Ord(Item.ItemType);
        if GoodsKind in [0..7] then
        begin
          if not (GoodsKind in GoodsReady) then
          begin
            GoodsText[GoodsKind].Portrait := 'GI,' + GetItemTypeBitmapPath(Item.ItemType);
            GoodsText[GoodsKind].Info :=
                LocalizedText('Items.Goods.Text.' + IntToStr(GoodsKind + 1));
            Include(GoodsReady, GoodsKind);
          end;
          Track.Portrait := GoodsText[GoodsKind].Portrait;
          Track.Info := GoodsText[GoodsKind].Info;
        end
        else
        begin
          Track.Portrait := 'GI,' + GetItemTypeBitmapPath(Item.ItemType);
          Track.Info := LocalizedText('Items.Goods.Text.' + IntToStr(GoodsKind + 1));
        end;
      end
      else
      begin
        Track.Portrait := 'GI,' + Item.GetBitmapResourceName + 's';
        Track.Info := Item.GetInfoText('<color=255,240,100>', nil)
      end;
    end;
  end;
end;

constructor TObserverRecording.Create;
begin
  inherited Create;
  Systems := TFPHashObjectList.Create(True);
  Transits := TFPHashObjectList.Create(True);
  Turn := Galaxy.CurrentTurn;
  CaptureTransits(True);
end;
destructor TObserverRecording.Destroy;
begin
  Systems.Free;
  Transits.Free;
  inherited Destroy
end;
procedure TObserverRecording.Capture(Star: TStar; Step, StepCount: Integer);
var
  S: TObserverSystem;
  Key: AnsiString;
  I: Integer;
begin
  Key := UIntToStr(Star.Id);
  S := TObserverSystem(Systems.Find(Key));
  if S = nil then
  begin
    S := TObserverSystem.Create(Star);
    Systems.Add(Key, S)
  end;
  S.Steps := EnsureRange(StepCount, 1, ObserverSamples - 1);
  S.Capture(Star, Min(Step, S.Steps));
  for I := 0 to Star.Ships.Count - 1 do
    CaptureTransit(TObject(Star.Ships[I]), Step / S.Steps, False);
end;
procedure TObserverRecording.CaptureAll;
var
  I: Integer;
  Star: TStar;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    Capture(Star, 0, Star.MovementStepCount);
  end;
end;
procedure TObserverRecording.CaptureTransit(ShipObject: TObject; AtTime: Double; Initial: Boolean);
var
  Ship: TShip;
  T: TObserverTransit;
  Origin, Destination: TStar;
  Key: AnsiString;
  Angle, Radius: Double;
  S: TObserverSystem;
  Track: TObserverTrack;
  Step: Integer;
begin
  Ship := TShip(ShipObject);
  Key := IntToStr(Ship.Id);
  T := TObserverTransit(Transits.Find(Key));
  if not Ship.InHyperspace then
  begin
    if (T <> nil)
        and not T.Arrived
        and (Ship.CurrentStar <> nil)
        and (Ship.CurrentStar.Id = T.DestinationId) then
    begin
      T.EndAt := Max(T.BeginAt, AtTime);
      T.EndProgress := 1;
      T.RemainingDays := 0;
      T.ArrivalPosition := Ship.Position;
      T.Arrived := True;
    end;
    Exit;
  end;
  // Teleports and black-hole transitions are not ordinary interstellar flight.
  if (Ship.Order <> soJump) or Ship.DestroyQueued or not (Ship.OrderTarget is TStar) then
    Exit;
  Destination := TStar(Ship.OrderTarget);
  if Ship.CurrentStar <> Destination then
    Origin := Ship.CurrentStar
  else
    Origin := Ship.TransitOriginStar;
  if (Origin = nil) or (Destination = nil) or (Origin = Destination) then
    Exit;
  if T = nil then
  begin
    T := TObserverTransit.Create;
    Transits.Add(Key, T);
    T.ShipId := Ship.Id;
    T.Name := Ship.Name;
    T.Owner := Ship.OwnerId;
    T.OriginId := Origin.Id;
    T.DestinationId := Destination.Id;
    T.TotalDays := Max(Ship.OrderStateData, Ship.CalculateJumpTravelDays(Origin, Destination));
    T.TotalDays := Max(1, T.TotalDays);
    T.EndAt := 1;
    if Initial then
      T.BeginAt := 0
    else
      T.BeginAt := AtTime;
    T.DeparturePosition := Ship.Position;
    T.Departed := not Initial;
    // Position and heading remain at the departure while in hyperspace.
    // This is the same deterministic arrival geometry as PrepareTurnMovement;
    // the actual entry sample replaces it when the ship arrives.
    Angle := Ship.MovementDirection;
    if Ship.AbductedByPirateClan then
      Angle := PointBearingDegrees(Destination.Position, Origin.Position);
    Angle :=
        HeadingDegreesToRadians(
            WrapHeadingDegrees(
                Angle + Abs(Int64(Cardinal(Destination.GenerationSeed + Ship.Seed))) mod 10 - 5
            )
        );
    Radius := -Destination.ComputeMapDiameter / 2;
    T.ArrivalPosition := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
    if Ship.AbductedByPirateClan
        and (Destination.Dominion <> nil)
        and TShip(Destination.Dominion).InNormalSpace
        and (TShip(Destination.Dominion).CurrentStar = Destination) then
      T.ArrivalPosition := TShip(Destination.Dominion).Position;
    // The countdown decrements during preparation, before movement. Reach the
    // endpoint on the preceding turn, rather than jumping there at arrival.
    if Initial then
      T.BeginProgress := EnsureRange(1 - (Ship.OrderStateData - 1) / T.TotalDays, 0.0, 1.0)
    else
      T.BeginProgress := 0;
    if T.Departed then
    begin
      S := TObserverSystem(Systems.Find(UIntToStr(T.OriginId)));
      if S <> nil then
      begin
        Track := TObserverTrack(S.Tracks.Find('2:' + Key));
        Step := EnsureRange(Round(AtTime * S.Steps), 0, S.Steps);
        if (Track <> nil) and (Step > 0) then
        begin
          Track.DepartureStep := Step;
          Track.Poses[Step].Position := T.DeparturePosition;
          Track.Poses[Step].Angle := HeadingDegreesToByte(Ship.MovementDirection);
        end;
      end;
    end;
  end;
  T.RemainingDays := Max(0, Ship.OrderStateData);
  T.EndProgress := EnsureRange(1 - (T.RemainingDays - 1) / T.TotalDays, T.BeginProgress, 1.0);
end;

procedure TObserverRecording.CaptureTransits(Initial: Boolean);
var
  I, J: Integer;
  Star: TStar;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
      CaptureTransit(TObject(Star.Ships[J]), Ord(not Initial), Initial);
  end;
  for J := 0 to Galaxy.ShipsInTransit.Count - 1 do
    CaptureTransit(TObject(Galaxy.ShipsInTransit[J]), Ord(not Initial), Initial);
end;
procedure CaptureObserverHit(
    Star, Source, Target, Weapon: TObject;
    Damage: Integer;
    Color: Cardinal;
    Kind: Integer
);
var
  S: TObserverSystem;
  E, Extra: TObserverEffect;
  Info: PWeaponInfo;
  function ObjectPosition(Obj: TObject): TPointF;
  begin
    if Obj is TShip then
      Result := TShip(Obj).Position
    else if Obj is TMissile then
      Result := TMissile(Obj).Position
    else if Obj is TAsteroid then
      Result := TAsteroid(Obj).Position
    else if Obj is TItem then
      Result := TItem(Obj).Position
    else
      Result := MakePointF(0, 0);
  end;
  function ObjectKey(Obj: TObject): AnsiString;
  begin
    Result := '';
    if Obj is TShip then
      Result := '2:' + IntToStr(TShip(Obj).Id)
    else if Obj is TMissile then
      Result := '4:' + UIntToStr(TMissile(Obj).Id)
    else if Obj is TAsteroid then
      Result := '3:' + UIntToStr(TAsteroid(Obj).Id)
    else if Obj is TItem then
      Result := '5:' + IntToStr(TItem(Obj).Id);
  end;
begin
  if (ObserverWriting = nil) or (Star = nil) or (Target = nil) then
    Exit;
  S := TObserverSystem(ObserverWriting.Systems.Find(IntToStr(TStar(Star).Id)));
  if S = nil then
    Exit;
  E := TObserverEffect.Create;
  S.Effects.Add(E);
  E.AtTime := S.CapturedStep / Max(1, S.Steps);
  E.SourcePosition := ObjectPosition(Source);
  E.TargetPosition := ObjectPosition(Target);
  E.SourceKey := ObjectKey(Source);
  E.TargetKey := ObjectKey(Target);
  E.Damage := Damage;
  E.Color := Color;
  E.GraphKey := 'Weapon.NoGraph';
  if Weapon is TWeapon then
  begin
    Info := TWeapon(Weapon).GetWeaponInfo;
    E.GraphKey := Info.PrimarySE;
    E.Palette := TWeapon(Weapon).GetShotPalette;
    if Info.ShotType = wstAreaDamage then
      E.GraphKey := Info.SecondarySE;
    if E.GraphKey = '' then
      E.GraphKey := 'Weapon.NoGraph';
  end;
  if Target is TShip then
  begin
    E.Destroyed := TShip(Target).IsHullDestroyed;
    if TShip(Target).Graphic <> nil then
      E.TargetSize := TShip(Target).Graphic.Size;
  end;
  if Kind = 1 then // A missile actually impacted a ship.
  begin
    E.GraphKey := 'Weapon.MissileHit';
    E.Palette := TMissile(Source).GetShotVisual;
    E.SourcePosition := E.TargetPosition;
    E.SourceKey := E.TargetKey
  end;
  if (Kind = 2) or (Kind = 3) then
  begin
    Extra := TObserverEffect.Create;
    S.Effects.Add(Extra);
    Extra.AtTime := E.AtTime;
    Extra.GraphKey := 'Weapon.Asteroid';
    Extra.SourcePosition := E.TargetPosition;
    Extra.TargetPosition := E.TargetPosition;
    // Fixed impact position: the asteroid respawns elsewhere immediately.
    E.TargetKey := '';
  end;
  if Kind = 5 then
  begin
    E.GraphKey := 'Weapon.Asteroid';
    E.SourceKey := '';
    E.SourcePosition := E.TargetPosition
  end;
  if Kind = 4 then
  begin
    E.Destroyed := True;
    E.Destruction := 3;
    E.TargetKey := ''
  end;
end;
procedure CaptureObserverStep(Star: TObject; Step, StepCount: Integer);
begin
  if ObserverWriting <> nil then
    ObserverWriting.Capture(TStar(Star), Step, StepCount);
end;
end.
