{$EXCESSPRECISION OFF}
unit aEObjInfo;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aConst,
  EC_Struct,
  EC_Buf,
  aGalaxy,
  aGalaxyStruct;
type
  TEObjInfo = class;
  PointerToTEOTAsteroid = ^TEOTAsteroid;
  PointerToTEOTCustomStarInfo = ^TEOTCustomStarInfo;
  PointerToTEOTItem = ^TEOTItem;
  PointerToTEOTMissile = ^TEOTMissile;
  PointerToTEOTPlanet = ^TEOTPlanet;
  PointerToTEOTShip = ^TEOTShip;
  PEPlanetInfo = PointerToTEOTPlanet;
  TEOTCustomStarInfo = record
    Name: WideString;
    ImagePath: WideString;
    Text: WideString;
    Distance: Integer;
  end;
  PEShipInfo = PointerToTEOTShip;
  TEOTPlanet = record
    Id: Cardinal;
    Name: WideString;
    OwnerId: Byte;
    RaceId: Byte;
    GapA: array[0..1] of Byte;
    Population: Integer;
    Economy: TPlanetEconomy;
    Government: TPlanetGovernment;
    Relation: TRelationLevel;
    Gap13: array[0..0] of Byte;
    UnexploredWater: Integer;
    UnexploredLand: Integer;
    UnexploredHills: Integer;
    TreasureHint: WideString;
    Faction: WideString;
  end;
  PEItemInfo = PointerToTEOTItem;
  TEOTShip = record
    Id: Cardinal;
    Name: WideString;
    FullName: WideString;
    OwnerId: Byte;
    DominatorSeries: TDominatorSeries;
    GapE: array[0..1] of Byte;
    TypeName: WideString;
    Speed: Integer;
    HullCapacity: Integer;
    HullPoints: Integer;
    HullFragility: Double;
    OutsideNormalSpace: Boolean;
    ScannerResolved: Boolean;
    Gap2A: array[0..1] of Byte;
    DefenseText: WideString;
    DamageText: WideString;
    RepairPoints: Integer;
    Relation: TRelationLevel;
    Gap39: array[0..2] of Byte;
    WinChance: Integer;
    PortraitImage: WideString;
    CombatStatusCount: Integer;
    CombatStatusText: WideString;
    Faction: WideString;
  end;
  PEAsteroidInfo = PointerToTEOTAsteroid;
  TEOTItem = record
    Id: Cardinal;
    Name: WideString;
    ImagePath: WideString;
    ItemType: TItemType;
    GapD: array[0..2] of Byte;
    InfoText: WideString;
    Weight: Integer;
    Cost: Integer;
    OwnerId: Byte;
    Gap1D: array[0..2] of Byte;
    ConditionPercent: Double;
    Fragility: Double;
    DominatorSeries: TDominatorSeries;
    Gap31: array[0..2] of Byte;
    Faction: WideString;
  end;
  PEMissileInfo = PointerToTEOTMissile;
  TEOTAsteroid = record
    Id: Cardinal;
    Name: WideString;
    InfoText: WideString;
  end;
  PECustomSystemInfo = PointerToTEOTCustomStarInfo;
  TEOTMissile = record
    Id: Cardinal;
    Name: WideString;
    InfoText: WideString;
  end;
  TEObjInfo = class(TObjectEx)
    StarName: WideString;
    StarRadius: Integer;
    Planets: array of TEOTPlanet;
    Ships: array of TEOTShip;
    Items: array of TEOTItem;
    Asteroids: array of TEOTAsteroid;
    Missiles: array of TEOTMissile;
    CustomSystemInfos: array of TEOTCustomStarInfo;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromStar(Star: TStar);
    function FindPlanet(ObjectId: Cardinal): PEPlanetInfo;
    function FindShip(ObjectId: Cardinal): PEShipInfo;
    function FindItem(ObjectId: Cardinal): PEItemInfo;
    function FindAsteroid(ObjectId: Cardinal): PEAsteroidInfo;
    function FindMissile(ObjectId: Cardinal): PEMissileInfo;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Version: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Classes,
  SysUtils,
  aPlanet,
  aShip,
  aItem,
  aAsteroid,
  aMissile,
  aPlayer,
  aMyFunction,
  aKling,
  aRanger,
  aRuins,
  GR_Main;

constructor TEObjInfo.Create;
begin
  inherited Create;
end;

destructor TEObjInfo.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TEObjInfo.Clear;
begin
  StarName := '';
  StarRadius := 0;
  Planets := nil;
  Ships := nil;
  Items := nil;
  Asteroids := nil;
  Missiles := nil;
  CustomSystemInfos := nil;
end;

procedure TEObjInfo.LoadFromStar(Star: TStar);
const
  NoDamageFlags = [dkEnergy..dkDroidBlock] - [dkEnergy..dkDroidBlock];
  WearableItemTypes = [0..79] - [0..7, 9, 23..25, 35..38, 42, 69..72, 74..79];
var
  Index, StatusCount: Integer;
  Planet: TPlanet;
  Ship: TShip;
  Item: TItem;
  Asteroid: TAsteroid;
  Missile: TMissile;
  CustomInfo: TCustomSystemInfo;
  Relation: TRelationLevel;
  Stage: Integer;
begin
  Stage := 0;
  try
    StarName := Star.Name;
    StarRadius := Star.Radius;
    Stage := 1;
    SetLength(Planets, Star.Planets.Count);
    for Index := 0 to Star.Planets.Count - 1 do
    begin
      Planet := Star.Planets[Index];
      Planets[Index].Id := Planet.Id;
      Planets[Index].Name := Planet.Name;
      Planets[Index].OwnerId := Planet.OwnerId;
      Planets[Index].RaceId := Planet.RaceId;
      Planets[Index].Population := Planet.Population;
      Planets[Index].Economy := Planet.Economy;
      Planets[Index].Government := Planet.Government;
      Planets[Index].Relation := Planet.GetRelationLevelToShip(GetPlayer);
      Planets[Index].UnexploredWater := Planet.WaterTiles - Planet.WaterExplored;
      Planets[Index].UnexploredLand := Planet.LandTiles - Planet.LandExplored;
      Planets[Index].UnexploredHills := Planet.HillTiles - Planet.HillExplored;
      Planets[Index].TreasureHint := Planet.BuildNonCivilTreasureHintText;
      Planets[Index].Faction := Planet.GetFactionResourceName;
    end;
    Stage := 2;
    SetLength(Ships, Star.Ships.Count);
    for Index := 0 to Star.Ships.Count - 1 do
    begin
      Ship := Star.Ships[Index];
      Ships[Index].Id := Ship.Id;
      Ships[Index].Name := Ship.Name;
      Ships[Index].OutsideNormalSpace := not Ship.InNormalSpace;
      Stage := 20;
      if GetPlayer <> Ship then
      begin
        Stage := 21;
        Ships[Index].FullName := WrapTextInColor(Ship.GetFullName(' '), InfoNameColorTag);
        if (Ship <> nil) and (GetPlayer = Ship.PartnerShip) then
          Ships[Index].FullName :=
              Ships[Index].FullName
                  + #13#10
                  + WrapTextInColor(
                      LookupLocalizedTextByKey('FormInfo.Partner'),
                      '<color=255,240,100>');
        if (Ship is TKling)
            and ((Ship as TKling).ActiveProgramAppliedTurn > 0)
            and ((Ship as TKling).ActiveProgramId in [6..11]) then
          Ships[Index].FullName :=
              Ships[Index].FullName
                  + #13#10
                  + WrapTextInColor(
                      LocalizedText(
                          'Programms.'
                              + ProgramNames[(Ship as TKling).ActiveProgramId]
                              + '.AddToShipInfo'
                      ),
                      '<color=255,0,0>');
      end
      else
      begin
        Stage := 22;
        Ships[Index].FullName := WrapTextInColor(Ship.GetFullName(' '), InfoNameColorTag);
      end;
      Stage := 23;
      Ships[Index].OwnerId := Ship.OwnerId;
      if Ships[Index].OwnerId = Byte(oiDominator) then
        Ships[Index].DominatorSeries := (Ship as TKling).DominatorSeries;
      if Ship is TRanger then
        Ships[Index].TypeName := (Ship as TRanger).GetCharacterName
      else
        Ships[Index].TypeName := Ship.GetLocalizedTypeName;
      Ships[Index].Speed := Ship.CalculateSpeed;
      Ships[Index].HullCapacity := Ship.GetHull.Weight;
      Ships[Index].HullPoints := Ship.GetHull.HullPoints;
      Ships[Index].HullFragility := Ship.GetHull.GetFragilityFactor(NoDamageFlags);
      if GetPlayer.CanResolveObjectWithScanner(Ship) or (GetPlayer = Ship) then
        Ships[Index].ScannerResolved := True
      else
        Ships[Index].ScannerResolved := False;
      Stage := 24;
      Ships[Index].RepairPoints := -1;
      Ships[Index].DamageText := WrapTextInColor('???', '');
      Ships[Index].DefenseText := IntToStr(Integer(Ship.GetDefensePercent) and $7F) + '%';
      if GetPlayer.CanResolveObjectWithScanner(Ship)
          or (GetPlayer = Ship)
          or (GetPlayer = Ship.PartnerShip)
          or (Ship.TypeId = stTranclucator) then
      begin
        Stage := 25;
        Ships[Index].DefenseText :=
            Ships[Index].DefenseText + ' + ' + WrapTextInColor(IntToStr(Ship.GetArmor), '');
        if GetPlayer.HasScannerArtefact(Ship) then
        begin
          if Ship.GetRepairRobot <> nil then
            Ships[Index].RepairPoints := Ship.CalculateRepairPoints(Ship.GetRepairRobot)
          else
            Ships[Index].RepairPoints := 0;
          Ships[Index].DamageText := WrapTextInColor(Ship.GetWeaponDamageSummary, '');
          Ships[Index].DefenseText := Ship.GetManeuverabilitySummary + Ships[Index].DefenseText;
        end;
      end;
      if not GetPlayer.HasScannerArtefact(Ship) then
        Ships[Index].DamageText := '';
      Stage := 26;
      Relation := Ship.GetRelationLevelToShip(GetPlayer);
      Ships[Index].Relation := Relation;
      if Relation <> rlHostile then
        if Ship is TRuins then
          if Ship.RangerRelations <> nil then
            if Ship.RangerRelations.Count > 0 then
            begin
              Relation :=
                  RelationValueToLevel(
                      Byte(Ship.RangerRelations[Galaxy.Rangers.IndexOf(GetPlayer)])
                  );
              if Relation <> rlHostile then
                Ships[Index].Relation := Relation;
            end;
      Stage := 27;
      if (GetPlayer <> Ship)
          and not (Ship is TRuins)
          and (GetPlayer.CountActiveArtefacts(Ord(t_ArtefactAnalyzer)) > 0)
          and GetPlayer.CanResolveObjectWithScanner(Ship) then
        Ships[Index].WinChance := Integer(GetPlayer.GetWinChancePercent(Ship)) and $7F
      else
        Ships[Index].WinChance := -1;
      Stage := 28;
      Ships[Index].PortraitImage := Ship.GetShipPortraitImagePath;
      Stage := 29;
      if not GetPlayer.HasScannerArtefact(Ship) then
        Ships[Index].CombatStatusText := Ship.GetCombatStatusDescription(StatusCount, False)
      else
        Ships[Index].CombatStatusText := Ship.GetCombatStatusDescription(StatusCount, True);
      Ships[Index].CombatStatusCount := StatusCount;
      Ships[Index].Faction := Ship.GetFactionNameKey;
    end;
    Stage := 3;
    SetLength(Items, Star.Items.Count);
    for Index := 0 to Star.Items.Count - 1 do
    begin
      Item := Star.Items[Index];
      Stage := 30;
      Items[Index].Id := Item.Id;
      Items[Index].ItemType := Item.ItemType;
      Items[Index].Weight := Item.Weight;
      Items[Index].Cost := Item.Cost;
      if Byte(Item.ItemType) in WearableItemTypes then
      begin
        Items[Index].ConditionPercent := (Item as TEquipment).ConditionPercent;
        Items[Index].Fragility := (Item as TEquipment).GetFragilityFactor(NoDamageFlags);
      end
      else
      begin
        Items[Index].ConditionPercent := 100;
        Items[Index].Fragility := 1;
      end;
      if Item is TGoods then
      begin
        Stage := 31;
        Items[Index].ImagePath := 'GI,' + GetItemTypeBitmapPath(Item.ItemType);
        Items[Index].Name :=
            WrapTextInColor(GoodsMarket[Byte(Item.ItemType)].DisplayName, InfoNameColorTag);
        Items[Index].InfoText :=
            LocalizedText('Items.Goods.Text.' + IntToStr(Byte(Item.ItemType) + 1));
        Items[Index].OwnerId := Byte(oiUninhabited);
      end
      else
      begin
        Stage := 32;
        Items[Index].ImagePath := 'GI,' + Item.GetBitmapResourceName + 's';
        Items[Index].Name := WrapTextInColor(Item.GetDisplayName, InfoNameColorTag);
        Items[Index].InfoText := Item.GetInfoText('<color=255,240,100>', nil);
        Items[Index].OwnerId := Item.OwnerId;
      end;
      if Item is TEquipment then
      begin
        Stage := 33;
        Items[Index].DominatorSeries := (Item as TEquipment).DominatorSeries;
      end;
      Items[Index].Faction := Item.GetOwnerConfigName;
    end;
    Stage := 4;
    SetLength(Asteroids, Star.Asteroids.Count);
    for Index := 0 to Star.Asteroids.Count - 1 do
    begin
      Asteroid := Star.Asteroids[Index];
      Asteroids[Index].Id := Asteroid.Id;
      Asteroids[Index].Name := Asteroid.GetDisplayName;
      Asteroids[Index].InfoText := Asteroid.GetInfoText;
    end;
    Stage := 5;
    SetLength(Missiles, Star.Missiles.Count);
    for Index := 0 to Star.Missiles.Count - 1 do
    begin
      Missile := Star.Missiles[Index];
      Missiles[Index].Id := Missile.Id;
      Missiles[Index].Name := Missile.GetDisplayName;
      Missiles[Index].InfoText := Missile.GetInfoText;
    end;
    Stage := 5;
    SetLength(CustomSystemInfos, Star.CustomSystemInfos.Count);
    for Index := 0 to Star.CustomSystemInfos.Count - 1 do
    begin
      CustomInfo := TCustomSystemInfo(Star.CustomSystemInfos[Index]);
      CustomSystemInfos[Index].Name := CustomInfo.Name;
      CustomSystemInfos[Index].ImagePath := CustomInfo.Icon;
      CustomSystemInfos[Index].Text := CustomInfo.Info;
      CustomSystemInfos[Index].Distance := CustomInfo.Distance;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create(
          'Error in procedure TEObjInfo.LoadFromStar, label = ' + IntToStr(Stage));
    end;
  end;
end;

function TEObjInfo.FindPlanet(ObjectId: Cardinal): PEPlanetInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Planets) do
    if Planets[Index].Id = ObjectId then
    begin
      Result := @Planets[Index];
      Exit;
    end;
  Result := nil;
end;

function TEObjInfo.FindShip(ObjectId: Cardinal): PEShipInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Ships) do
    if Ships[Index].Id = ObjectId then
    begin
      Result := @Ships[Index];
      Exit;
    end;
  Result := nil;
end;

function TEObjInfo.FindItem(ObjectId: Cardinal): PEItemInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Items) do
    if Items[Index].Id = ObjectId then
    begin
      Result := @Items[Index];
      Exit;
    end;
  Result := nil;
end;

function TEObjInfo.FindAsteroid(ObjectId: Cardinal): PEAsteroidInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Asteroids) do
    if Asteroids[Index].Id = ObjectId then
    begin
      Result := @Asteroids[Index];
      Exit;
    end;
  Result := nil;
end;

function TEObjInfo.FindMissile(ObjectId: Cardinal): PEMissileInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Missiles) do
    if Missiles[Index].Id = ObjectId then
    begin
      Result := @Missiles[Index];
      Exit;
    end;
  Result := nil;
end;

procedure TEObjInfo.SaveToBuffer(Buffer: TBufEC);
var
  Index: Integer;
begin
  Buffer.AddWideStringZ(StarName);
  Buffer.AddIntegerValue(StarRadius);
  Buffer.AddAnsiChar(AnsiChar(High(Planets) + 1));
  for Index := 0 to High(Planets) do
  begin
    Buffer.AddDWord(Planets[Index].Id);
    Buffer.AddWideStringZ(Planets[Index].Name);
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].OwnerId));
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].RaceId));
    Buffer.AddIntegerValue(Planets[Index].Population);
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].Economy));
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].Government));
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].Relation));
    Buffer.AddIntegerValue(Planets[Index].UnexploredWater);
    Buffer.AddIntegerValue(Planets[Index].UnexploredLand);
    Buffer.AddIntegerValue(Planets[Index].UnexploredHills);
    Buffer.AddWideStringZ(Planets[Index].TreasureHint);
    Buffer.AddWideStringZ(Planets[Index].Faction);
  end;
  Buffer.AddWideChar(WideChar(High(Ships) + 1));
  for Index := 0 to High(Ships) do
  begin
    Buffer.AddDWord(Ships[Index].Id);
    Buffer.AddWideStringZ(Ships[Index].Name);
    Buffer.AddWideStringZ(Ships[Index].FullName);
    Buffer.AddAnsiChar(AnsiChar(Ships[Index].OwnerId));
    Buffer.AddAnsiChar(AnsiChar(Ships[Index].DominatorSeries));
    Buffer.AddWideStringZ(Ships[Index].TypeName);
    Buffer.AddIntegerValue(Ships[Index].Speed);
    Buffer.AddIntegerValue(Ships[Index].HullCapacity);
    Buffer.AddIntegerValue(Ships[Index].HullPoints);
    Buffer.AddSingle(Ships[Index].HullFragility);
    Buffer.AddWideStringZ(Ships[Index].DefenseText);
    Buffer.AddAnsiChar(AnsiChar(Ships[Index].Relation));
    Buffer.AddIntegerValue(Ships[Index].WinChance);
    Buffer.AddWideStringZ(Ships[Index].PortraitImage);
    Buffer.AddIntegerValue(Ships[Index].RepairPoints);
    Buffer.AddWideStringZ(Ships[Index].DamageText);
    Buffer.AddBoolean(Ships[Index].ScannerResolved);
    Buffer.AddIntegerValue(Ships[Index].CombatStatusCount);
    Buffer.AddWideStringZ(Ships[Index].CombatStatusText);
    Buffer.AddWideStringZ(Ships[Index].Faction);
  end;
  Buffer.AddWideChar(WideChar(High(Items) + 1));
  for Index := 0 to High(Items) do
  begin
    Buffer.AddDWord(Items[Index].Id);
    Buffer.AddWideStringZ(Items[Index].Name);
    Buffer.AddWideStringZ(Items[Index].ImagePath);
    Buffer.AddAnsiChar(AnsiChar(Items[Index].ItemType));
    Buffer.AddWideStringZ(Items[Index].InfoText);
    Buffer.AddIntegerValue(Items[Index].Weight);
    Buffer.AddIntegerValue(Items[Index].Cost);
    Buffer.AddAnsiChar(AnsiChar(Items[Index].OwnerId));
    Buffer.AddSingle(Items[Index].ConditionPercent);
    Buffer.AddSingle(Items[Index].Fragility);
    Buffer.AddAnsiChar(AnsiChar(Items[Index].DominatorSeries));
    Buffer.AddWideStringZ(Items[Index].Faction);
  end;
  Buffer.AddWideChar(WideChar(High(Asteroids) + 1));
  for Index := 0 to High(Asteroids) do
  begin
    Buffer.AddDWord(Asteroids[Index].Id);
    Buffer.AddWideStringZ(Asteroids[Index].Name);
    Buffer.AddWideStringZ(Asteroids[Index].InfoText);
  end;
  Buffer.AddWideChar(WideChar(High(Missiles) + 1));
  for Index := 0 to High(Missiles) do
  begin
    Buffer.AddDWord(Missiles[Index].Id);
    Buffer.AddWideStringZ(Missiles[Index].Name);
    Buffer.AddWideStringZ(Missiles[Index].InfoText);
  end;
  Buffer.AddWideChar(WideChar(High(CustomSystemInfos) + 1));
  for Index := 0 to High(CustomSystemInfos) do
  begin
    Buffer.AddWideStringZ(CustomSystemInfos[Index].Name);
    Buffer.AddWideStringZ(CustomSystemInfos[Index].ImagePath);
    Buffer.AddWideStringZ(CustomSystemInfos[Index].Text);
    Buffer.AddIntegerValue(CustomSystemInfos[Index].Distance);
  end;
end;

procedure TEObjInfo.LoadFromBuffer(Buffer: TBufEC; Version: Integer);
var
  Count, Index: Integer;
begin
  Clear;
  StarName := Buffer.ReadWideString;
  StarRadius := Buffer.GetInt32;
  if Version <= 5 then
    Buffer.GetByte;
  Count := Buffer.GetByte;
  SetLength(Planets, Count);
  for Index := 0 to Count - 1 do
  begin
    Planets[Index].Id := Buffer.GetUInt32;
    Planets[Index].Name := Buffer.ReadWideString;
    Planets[Index].OwnerId := Buffer.GetByte;
    Planets[Index].RaceId := Buffer.GetByte;
    Planets[Index].Population := Buffer.GetInt32;
    Planets[Index].Economy := TPlanetEconomy(Buffer.GetByte);
    Planets[Index].Government := TPlanetGovernment(Buffer.GetByte);
    Planets[Index].Relation := TRelationLevel(Buffer.GetByte);
    Planets[Index].UnexploredWater := Buffer.GetInt32;
    Planets[Index].UnexploredLand := Buffer.GetInt32;
    Planets[Index].UnexploredHills := Buffer.GetInt32;
    Planets[Index].TreasureHint := Buffer.ReadWideString;
    if Version >= 6 then
      Planets[Index].Faction := Buffer.ReadWideString
    else
      Planets[Index].Faction := 'None';
  end;
  Count := Buffer.GetWord;
  SetLength(Ships, Count);
  for Index := 0 to Count - 1 do
  begin
    Ships[Index].Id := Buffer.GetUInt32;
    Ships[Index].Name := Buffer.ReadWideString;
    Ships[Index].FullName := Buffer.ReadWideString;
    Ships[Index].OwnerId := Buffer.GetByte;
    Ships[Index].DominatorSeries := TDominatorSeries(Buffer.GetByte);
    Ships[Index].TypeName := Buffer.ReadWideString;
    Ships[Index].Speed := Buffer.GetInt32;
    Ships[Index].HullCapacity := Buffer.GetInt32;
    Ships[Index].HullPoints := Buffer.GetInt32;
    Ships[Index].HullFragility := Buffer.GetSingle;
    Ships[Index].DefenseText := Buffer.ReadWideString;
    Ships[Index].Relation := TRelationLevel(Buffer.GetByte);
    Ships[Index].WinChance := Buffer.GetInt32;
    Ships[Index].PortraitImage := Buffer.ReadWideString;
    if Version >= 3 then
    begin
      Ships[Index].RepairPoints := Buffer.GetInt32;
      Ships[Index].DamageText := Buffer.ReadWideString;
    end;
    if Version >= 4 then
      Ships[Index].ScannerResolved := Buffer.GetBoolean;
    Ships[Index].CombatStatusCount := Buffer.GetInt32;
    Ships[Index].CombatStatusText := Buffer.ReadWideString;
    if Version >= 6 then
      Ships[Index].Faction := Buffer.ReadWideString
    else
      Ships[Index].Faction := 'None';
  end;
  Count := Buffer.GetWord;
  SetLength(Items, Count);
  for Index := 0 to Count - 1 do
  begin
    Items[Index].Id := Buffer.GetUInt32;
    Items[Index].Name := Buffer.ReadWideString;
    Items[Index].ImagePath := Buffer.ReadWideString;
    Items[Index].ItemType := TItemType(Buffer.GetByte);
    Items[Index].InfoText := Buffer.ReadWideString;
    Items[Index].Weight := Buffer.GetInt32;
    Items[Index].Cost := Buffer.GetInt32;
    Items[Index].OwnerId := Buffer.GetByte;
    Items[Index].ConditionPercent := Buffer.GetSingle;
    Items[Index].Fragility := Buffer.GetSingle;
    Items[Index].DominatorSeries := TDominatorSeries(Buffer.GetByte);
    if Version >= 6 then
      Items[Index].Faction := Buffer.ReadWideString
    else
      Items[Index].Faction := 'None';
  end;
  Count := Buffer.GetWord;
  SetLength(Asteroids, Count);
  for Index := 0 to Count - 1 do
  begin
    Asteroids[Index].Id := Buffer.GetUInt32;
    Asteroids[Index].Name := Buffer.ReadWideString;
    Asteroids[Index].InfoText := Buffer.ReadWideString;
  end;
  Count := Buffer.GetWord;
  SetLength(Missiles, Count);
  for Index := 0 to Count - 1 do
  begin
    Missiles[Index].Id := Buffer.GetUInt32;
    Missiles[Index].Name := Buffer.ReadWideString;
    Missiles[Index].InfoText := Buffer.ReadWideString;
  end;
  if Version >= 5 then
  begin
    Count := Buffer.GetWord;
    SetLength(CustomSystemInfos, Count);
    for Index := 0 to High(CustomSystemInfos) do
    begin
      CustomSystemInfos[Index].Name := Buffer.ReadWideString;
      CustomSystemInfos[Index].ImagePath := Buffer.ReadWideString;
      CustomSystemInfos[Index].Text := Buffer.ReadWideString;
      CustomSystemInfos[Index].Distance := Buffer.GetInt32;
    end;
  end
  else
    CustomSystemInfos := nil;
end;

procedure LinkRecoveredTypes;
begin
  TEquipment.ClassName;
  TGoods.ClassName;
  TKling.ClassName;
  TRanger.ClassName;
  TRuins.ClassName;
end;
end.
