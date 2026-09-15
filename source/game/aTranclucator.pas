{$EXCESSPRECISION OFF}
unit aTranclucator;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aConst,
  EC_Buf,
  aGalaxy,
  aGalaxyStruct,
  aPlanet,
  aShip;
type
  TTranclucator = class;
  {$Z1}
  TTranclucatorCollectionKind = (
      tckOther = 0,
      tckArtefact = 1,
      tckMicroModule = 2,
      tckEquipment = 3,
      tckUseless = 4,
      tckGoods = 5,
      tckCountable = 6
  );
  {$Z4}
  TTranclucatorStorageKind = (tskPlanet = 1, tskStation = 2);
  TTranclucator = class(TShip)
    ArtefactSize: Integer;
    ArtefactSystemName: WideString;
    OwnerShip: TShip;
    FollowOwner: Boolean;
    SeekItems: Boolean;
    AutoArrange: Boolean;
    StoreOnLanding: Boolean;
    CollectionPermissions: array[0..6] of Boolean;
    StoragePermissions: array[1..2] of Boolean;
    Gap4E9: array[0..2] of Byte;
    procedure SaveToBuffer(Buffer: TBufEC); override;
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy); override;
    procedure ResolveLoadedReferences(Galaxy: TGalaxy); override;
    procedure ClearObjectReferences; override;
    procedure NextDay; override;
    procedure NextDayLogic; override;
    procedure AssignWeaponTargetsInStar; override;
    function GetName: WideString; override;
    function GetFullName(const Separator: WideString): WideString; override;
    function GetGreetingShipCategory: Byte; override;
    function GetHomeStar: TStar; override;
    function GetDominantCareer: TRangerCareer; override;
    function GetStrengthScaledPirateStatus: Byte; override;
    function GetDesiredCargoFreeSpace: Integer; override;
    procedure RefuelAtLocation; override;
    function EvaluateStatBonus(BonusKind: TEquipmentBonusKind; Value: Integer): Single; override;
    procedure RepairBrokenEquipmentAtLocation; override;
    procedure BuildReachablePlanetQueue; override;
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override;
    procedure SelectEnemyShipInStar; override;
    procedure EngageEnemyShip; override;
    function RelationToRanger(Ranger: Pointer): Byte; override;
    procedure ChangeRelationToRanger(Ranger: Pointer; Amount: Integer); override;
    procedure ReactToAttack(Attacker: TShip); override;
    function RelationToNonRanger(Ship: TShip): Byte; override;
    function RecomputeFearState: Boolean; override;
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override;
    function TrustsAttackRequester(Ship: TShip): Boolean; override;
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override;
    procedure ProcessCombatDialogue; override;
    procedure ReactToExtortionDemand(Ranger: Pointer); override;
    function BuildMoneyExtortionResponse(
        OtherShip: TShip;
        var Response: WideString;
        DemandedAmount: Integer
    ): Boolean; override;
    function BuildCargoExtortionResponse(
        OtherShip: TShip;
        var Response: WideString
    ): Boolean; override;
    function BuildTrucePaymentResponse(
        OtherShip: TShip;
        var Response: WideString;
        OfferedAmount: Integer
    ): Boolean; override;
    function BuildAttackRequestResponse(
        Requester: TShip;
        var Response: WideString;
        Target: TShip
    ): Boolean; override;
    function AcceptPartnershipOffer(
        OtherShip: TShip;
        var Response: WideString;
        PaymentAmount: Integer
    ): Boolean; override;
    function BuildPartnershipOfferResponse(
        OtherShip: TShip;
        var Response: WideString;
        PaymentAmount: Integer
    ): Boolean; override;
    procedure RefreshCurrentStanding; override;
    constructor Create;
    destructor Destroy; override;
    procedure ClearCollectionPermissions;
    procedure SetCollectionPermission(Kind: TTranclucatorCollectionKind; Enabled: Boolean);
    function GetCollectionPermission(Kind: TTranclucatorCollectionKind): Boolean;
    procedure ResetStoragePermissions;
    procedure SetStoragePermission(Kind: TTranclucatorStorageKind; Enabled: Boolean);
    function GetStoragePermission(Kind: TTranclucatorStorageKind): Boolean;
    procedure Init(AOwnerShip: TShip; Faction: Byte; BasicEquipment: Boolean);
    function CanFollowOwnerInCurrentStar: Boolean;
    procedure TransferUnequippedCargo(Destination: TShip);
    procedure StoreUnequippedCargoAt(Location: TObject);
    function UnloadCargoForPlayerOwner: Boolean;
    function TryLandForStorage: Boolean;
    function ConvertToStoredArtefact: Boolean;
    procedure UpdateFreeFlightOrder;
    function TryCollectPreferredFloatingLoot(MaxTravelDays: Integer): Boolean;
    procedure EquipEssentialInventory;
  end;
var
  TranclucatorSkillBonusWeights: array[22..27] of Integer = (100, 100, 80, 80, 60, 60);
  TranclucatorSlotBonusWeights: array[13..20] of Integer = (100, 100, 200, 100, 200, 75, 10, 30);
procedure LinkRecoveredTypes;
implementation
uses
  EC_Struct,
  Classes,
  SysUtils,
  Math,
  GR_Main,
  GlobalsV,
  aMyFunction,
  aItem,
  aPlayer,
  aRuins,
  aScript,
  aAsteroid;

constructor TTranclucator.Create;
begin
  inherited Create;
  ClearCollectionPermissions;
  ResetStoragePermissions;
  AutoArrange := False;
  StoreOnLanding := False;
  ArtefactSize := 0;
end;

destructor TTranclucator.Destroy;
begin
  inherited Destroy;
end;

procedure TTranclucator.ClearCollectionPermissions;
var
  Kind: TTranclucatorCollectionKind;
begin
  for Kind := Low(TTranclucatorCollectionKind) to High(TTranclucatorCollectionKind) do
    CollectionPermissions[Ord(Kind)] := False;
end;

procedure TTranclucator.SetCollectionPermission(
    Kind: TTranclucatorCollectionKind;
    Enabled: Boolean
);
begin
  CollectionPermissions[Ord(Kind)] := Enabled;
end;

function TTranclucator.GetCollectionPermission(Kind: TTranclucatorCollectionKind): Boolean;
begin
  Result := CollectionPermissions[Ord(Kind)];
end;

procedure TTranclucator.ResetStoragePermissions;
var
  Kind: Integer;
begin
  for Kind := 1 to 2 do
    StoragePermissions[Ord(Kind)] := False;
  SetStoragePermission(tskPlanet, True);
end;

procedure TTranclucator.SetStoragePermission(Kind: TTranclucatorStorageKind; Enabled: Boolean);
begin
  case Kind of
    tskPlanet: StoragePermissions[Ord(tskPlanet)] := Enabled;
    tskStation: StoragePermissions[Ord(tskStation)] := Enabled;
  end;
end;

function TTranclucator.GetStoragePermission(Kind: TTranclucatorStorageKind): Boolean;
begin
  Result := False;
  case Kind of
    tskPlanet: Result := StoragePermissions[Ord(tskPlanet)];
    tskStation: Result := StoragePermissions[Ord(tskStation)];
  end;
end;

procedure TTranclucator.Init(AOwnerShip: TShip; Faction: Byte; BasicEquipment: Boolean);
var
  WeaponType: Byte;
  MaximumHullSize: Integer;
  function RandomHullLevel: Integer; // @addr $65C908 @calls "0x65CC45" @ida "int __usercall $name@<eax>(void *ParentFrame@<^0>);" @stackpop 0
  begin
    Result := NextRandomIntRange(1, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 1, 8)), RandomState);
  end;
  function RandomEquipmentLevel: Integer; // @addr $65C974 @calls "0x65CC5E 0x65CC9C 0x65CCC4 0x65CCEC" @ida "int __usercall $name@<eax>(void *ParentFrame@<^0>);" @stackpop 0
  begin
    Result := NextRandomIntRange(1, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 1, 4)), RandomState);
  end;
  function RandomEquipmentSize(
      BaseSize: Integer
  ): Integer; // @addr $65C9E0 @calls "0x65CB63 0x65CBB2 0x65CC6D 0x65CCAB 0x65CCD3 0x65CCFB 0x65CD49" @ida "int __usercall $name@<eax>(int BaseSize@<eax>, void *ParentFrame@<^0>);" @stackpop 0
  begin
    Result :=
        NextRandomIntRange(
            Round(BaseSize * EquipmentSizeFactors[3]),
            Round(BaseSize * EquipmentSizeFactors[4]),
            RandomState
        );
  end;
begin
  TypeId := stTranclucator;
  if AOwnerShip <> nil then
  begin
    OwnerShip := AOwnerShip;
    CurrentStar := AOwnerShip.CurrentStar;
    CurrentStar.Ships.Add(Self);
  end
  else
  begin
    OwnerShip := nil;
    CurrentStar := nil;
  end;
  OwnerId := Faction;
  HomePlanet := nil;
  CurrentPlanet := nil;
  Position := MakePointF(0, 0);
  MovementDirection := 0;
  Name := '';
  ChameleonActive := False;
  GraphDominator := Galaxy.GraphDominatorSurfacesEnabled;
  if BasicEquipment then
  begin
    CreateAndEquipHull(
        Round(NextRandomIntRange(200, 300, RandomState) * HullCapacityScale),
        1,
        OwnerId,
        -1,
        False
    );
    CreateAndEquipFuelTanks(10, 1, OwnerId);
    CreateAndEquipEngine(RandomEquipmentSize(EngineBaseSize), 2, OwnerId);
    WeaponType := NextRandomIntRange(0, 2, RandomState) + 50;
    CreateAndEquipWeapon(
        WeaponType,
        RandomEquipmentSize(WeaponInfos[WeaponType].AverageSize),
        1,
        OwnerId
    );
  end
  else
  begin
    MaximumHullSize := Round(RemapClamped(Galaxy.TechLevel, 3, 8, 300, 800) * HullCapacityScale);
    CreateAndEquipHull(
        NextRandomIntRange(Round(HullCapacityScale * 200), MaximumHullSize, RandomState),
        RandomHullLevel,
        OwnerId,
        -1,
        False
    );
    CreateAndEquipEngine(RandomEquipmentSize(EngineBaseSize), RandomEquipmentLevel, OwnerId);
    CreateAndEquipFuelTanks(10, 1, OwnerId);
    CreateAndEquipDefGenerator(
        RandomEquipmentSize(DefGeneratorBaseSize),
        RandomEquipmentLevel,
        OwnerId
    );
    CreateAndEquipRepairRobot(
        RandomEquipmentSize(RepairRobotBaseSize),
        RandomEquipmentLevel,
        OwnerId
    );
    CreateAndEquipCargoHook(RandomEquipmentSize(CargoHookBaseSize), RandomEquipmentLevel, OwnerId);
    WeaponType := NextRandomIntRange(0, 2, RandomState) + 50;
    CreateAndEquipWeapon(
        WeaponType,
        RandomEquipmentSize(WeaponInfos[WeaponType].AverageSize),
        1,
        OwnerId
    );
    BaseSkills[0] :=
        NextRandomIntRange(0, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 0, 6)), RandomState);
    BaseSkills[1] :=
        NextRandomIntRange(0, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 0, 6)), RandomState);
    BaseSkills[2] :=
        NextRandomIntRange(0, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 0, 6)), RandomState);
  end;
  TechKnowledge := 8;
  if GetCargoFreeSpace < 0 then
    GetHull.Weight := GetHull.Weight + Abs(GetCargoFreeSpace);
  RefreshGraphicSize;
  RefreshDerivedStats(True);
  RefreshCurrentStanding;
end;

procedure TTranclucator.SaveToBuffer(Buffer: TBufEC);
var
  Kind: TTranclucatorCollectionKind;
  StorageKind: Integer;
begin
  inherited SaveToBuffer(Buffer);
  if OwnerShip = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(OwnerShip.Id);
  Buffer.AddBoolean(FollowOwner);
  Buffer.AddBoolean(SeekItems);
  Buffer.AddBoolean(AutoArrange);
  Buffer.AddIntegerValue(ArtefactSize);
  if ArtefactSystemName = '' then
    Buffer.AddBoolean(False)
  else
  begin
    Buffer.AddBoolean(True);
    Buffer.AddWideStringZ(ArtefactSystemName);
  end;
  for Kind := Low(TTranclucatorCollectionKind) to High(TTranclucatorCollectionKind) do
    Buffer.AddBoolean(CollectionPermissions[Ord(Kind)]);
  for StorageKind := 1 to 2 do
    Buffer.AddBoolean(StoragePermissions[Ord(StorageKind)]);
  Buffer.AddBoolean(StoreOnLanding);
end;

procedure TTranclucator.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
var
  I, OldItemCount: Integer;
  Kind: TTranclucatorCollectionKind;
  StorageKind: Integer;
  procedure ReadOldPermission(
      ItemType: Byte
  ); // @addr $65CFE0 @calls "0x65D1E3" @ida "void __usercall $name(unsigned __int8 ItemType@<al>, void *ParentFrame@<^0>);" @stackpop 0
  var
    Enabled: Boolean;
  begin
    Enabled := Buffer.GetBoolean;
    case ItemType of
      0: CollectionPermissions[Ord(tckGoods)] := Enabled;
      8: CollectionPermissions[Ord(tckArtefact)] := Enabled;
      43: CollectionPermissions[Ord(tckEquipment)] := Enabled;
      69: CollectionPermissions[Ord(tckCountable)] := Enabled;
      70: CollectionPermissions[Ord(tckUseless)] := Enabled;
      71: CollectionPermissions[Ord(tckMicroModule)] := Enabled;
    end;
  end;
begin
  inherited LoadFromBuffer(Buffer, Galaxy);
  OwnerShip := TShip(Buffer.GetUInt32);
  FollowOwner := Buffer.GetBoolean;
  SeekItems := Buffer.GetBoolean;
  AutoArrange := Buffer.GetBoolean;
  ArtefactSize := Buffer.GetInt32;
  if LoadedSaveVersion < 129 then
    Buffer.GetByte;
  if (LoadedSaveVersion >= 86) and Buffer.GetBoolean then
    ArtefactSystemName := Buffer.ReadWideString;
  if LoadedSaveVersion >= 131 then
    for Kind := Low(TTranclucatorCollectionKind) to High(TTranclucatorCollectionKind) do
      CollectionPermissions[Ord(Kind)] := Buffer.GetBoolean
  else
  begin
    if LoadedSaveVersion < 78 then
      OldItemCount := 68
    else if LoadedSaveVersion < 96 then
      OldItemCount := 72
    else if LoadedSaveVersion < 127 then
      OldItemCount := 73
    else
      OldItemCount := 74;
    for I := 0 to OldItemCount - 1 do
      ReadOldPermission(Byte(MigrateSavedItemType(I)));
  end;
  for StorageKind := 1 to 2 do
    StoragePermissions[StorageKind] := Buffer.GetBoolean;
  StoreOnLanding := Buffer.GetBoolean;
end;

procedure TTranclucator.ResolveLoadedReferences(Galaxy: TGalaxy);
begin
  OwnerShip := TObject(Galaxy.IdToShip(Integer(OwnerShip), True)) as TShip;
  inherited ResolveLoadedReferences(Galaxy);
end;

procedure TTranclucator.ClearObjectReferences;
begin
  OwnerShip := nil;
  inherited ClearObjectReferences;
end;

procedure TTranclucator.NextDay;
begin
  inherited NextDay;
  if (ScriptShip <> nil) and HasScriptControl then
  begin
    ScriptNextDay;
    if ScriptShip <> nil then
      Exit;
  end;
  NextDayLogic;
  if (ScriptShip <> nil) and not HasScriptControl then
    ScriptNextDay;
end;

// Zero-byte pointer additions retain the native evaluation order of IndexOf.
procedure TTranclucator.NextDayLogic;
var
  Stage: Integer;
begin
  Stage := 1;
  try
    if (GetEngine = nil) or (GetFuelTanks = nil) then
      EquipEssentialInventory;
    Stage := 2;
    if AutoArrange or (OwnerShip = nil) then
    begin
      AutoEquipInventory;
      AutoEquipArtefacts;
    end;
    RepairBrokenEquipmentAtLocation;
    Stage := 3;
    if IsOnPlanet or IsDockedToShip then
    begin
      Stage := 4;
      if StoreOnLanding then
      begin
        Stage := 5;
        if not ConvertToStoredArtefact then
          UnloadCargoForPlayerOwner;
      end
      else
      begin
        Stage := 6;
        UnloadCargoForPlayerOwner;
        if CargoFreeSpace < 0 then
        begin
          Stage := 7;
          DropCargoUntilNotOverloaded;
          if CargoFreeSpace < 0 then
            ConvertToStoredArtefact
          else
            OrderTakeoff;
        end;
      end;
      Stage := 8;
    end
    else if InNormalSpace then
    begin
      Stage := 9;
      AssignWeaponTargetsInStar;
      Stage := 10;
      if CargoFreeSpace < 0 then
      begin
        Stage := 11;
        DropCargoUntilNotOverloaded;
      end
      else if not (SeekItems and (CargoFreeSpace > 0) and TryCollectPreferredFloatingLoot(50)) then
        if not (SeekItems and TryLandForStorage) then
          if FollowOwner and (OwnerShip <> nil) then
          begin
            Stage := 12;
            OrderFollowShip(OwnerShip, 0, False);
          end
          else
          begin
            Stage := 13;
            if not OrderAbsolute then
              UpdateFreeFlightOrder;
          end;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create(
          AnsiString(
              'Error in procedure TTranclucator.NextDayLogic '
                  + GetFullName(' ')
                  + ' label = '
                  + WideString(IntToStr(Stage))
          ));
    end;
  end;
end;

function TTranclucator.GetName: WideString;
begin
  Result := GetFullName(' ');
end;

function TTranclucator.GetFullName(const Separator: WideString): WideString;
var
  Path, DisplayName, TypeName: WideString;
begin
  if Name <> '' then
    DisplayName := Name
  else
    DisplayName :=
        LookupLocalizedTextByKey('Artefacts.ArtTranclucator.Name')
            + '-'
            + WideString(IntToStr(Cardinal(Id)));
  if TypeNameOverrideKey = '' then
    Result := DisplayName
  else
  begin
    Path := 'ShipType.' + ShipTypeNames[stTranclucator].Name + '.' + TypeNameOverrideKey;
    if LanguageDataConfig.CountParamsByPath(Path) > 0 then
      TypeName := LocalizedText(Path)
    else
      TypeName := LocalizedText('ShipType.TypeName.' + TypeNameOverrideKey);
    if TypeName <> '' then
      Result := TypeName + Separator + Name
    else
      Result := Name;
  end;
end;

function TTranclucator.GetGreetingShipCategory: Byte;
begin
  Result := gscTransport; // Native default category, also used for transports.
end;

function TTranclucator.GetDominantCareer: TRangerCareer;
begin
  Result := rcWarrior;
end;

function TTranclucator.GetHomeStar: TStar;
begin
  Result := nil;
end;

function TTranclucator.GetStrengthScaledPirateStatus: Byte;
begin
  Result := 100;
end;

function TTranclucator.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
end;

function TTranclucator.CanFollowOwnerInCurrentStar: Boolean;
begin
  Result :=
      FollowOwner
          and (OwnerShip <> nil)
          and (OwnerShip.CurrentStar = CurrentStar)
          and not OwnerShip.InHyperspace;
end;

procedure TTranclucator.RefuelAtLocation;
begin
  if GetFuelTanks <> nil then
    GetFuelTanks.Fuel := GetFuelTanks.Capacity;
end;

procedure TTranclucator.RepairBrokenEquipmentAtLocation;
begin
  if (GetEngine <> nil) and ((GetEngine.BrokenFlag <> 0) or (GetEngine.ConditionPercent < 1)) then
  begin
    GetEngine.ConditionPercent := 1;
    GetEngine.BrokenFlag := 0;
  end;
  if (GetFuelTanks <> nil)
      and ((GetFuelTanks.BrokenFlag <> 0) or (GetFuelTanks.ConditionPercent < 1)) then
  begin
    GetFuelTanks.ConditionPercent := 1;
    GetFuelTanks.BrokenFlag := 0;
  end;
end;

procedure TTranclucator.TransferUnequippedCargo(Destination: TShip);
var
  I: Integer;
  Item: TEquipment;
  Artefact: TArtefact;
  Good: Byte;
  procedure AddGoods(
      Good: Byte;
      Quantity, Cost: Integer
  ); // @addr $65DAF0 @ida "void __usercall $name(unsigned __int8 Good@<al>, int Quantity@<edx>, int Cost@<ecx>, void *ParentFrame@<^0>);" @note "Nested helper; caller-popped static link, destination at ParentFrame-4."
  begin
    if Quantity > 0 then
    begin
      Inc(Destination.CargoGoods[Good].Count, Quantity);
      Inc(Destination.CargoGoods[Good].TotalCost, Cost);
    end;
  end;
begin
  for I := Inventory.Count - 1 downto 0 do
  begin
    Item := TEquipment(Inventory[I + 0]);
    if Item.EquippedFlag = 0 then
    begin
      Inventory.Delete(Inventory.IndexOf(Pointer(PAnsiChar(Item) + 0)));
      Destination.Inventory.Add(Item);
    end;
  end;
  for I := Artefacts.Count - 1 downto 0 do
  begin
    Artefact := TArtefact(Artefacts[I + 0]);
    if Artefact.EquippedFlag = 0 then
    begin
      Artefacts.Delete(Artefacts.IndexOf(Pointer(PAnsiChar(Artefact) + 0)));
      Destination.Artefacts.Add(Artefact);
    end;
  end;
  for Good := 0 to 7 do
    with CargoGoods[Good] do
    begin
      AddGoods(Good, Count, TotalCost);
      Count := 0;
      TotalCost := 0;
      PurchasedCount := 0;
      PurchasedTotalCost := 0;
    end;
  RefreshDerivedStats(True);
  if GetPlayer = Destination then
    GetPlayer.RefreshStorageBubbles;
end;

// The +0 index/pointer expressions below preserve native DCC32 argument scheduling.
procedure TTranclucator.StoreUnequippedCargoAt(Location: TObject);
var
  Good: Byte;
  I: Integer;
  Item: TEquipment;
  Artefact: TArtefact;
begin
  if not (Location is TPlanet)
      or ((Location as TPlanet).OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)]) then
  begin
    for I := Inventory.Count - 1 downto 0 do
    begin
      Item := TEquipment(Inventory[I + 0]);
      if Item.EquippedFlag = 0 then
      begin
        GetPlayer.AddItemToPlayerStorage(Item, Location, -1);
        Inventory.Delete(Inventory.IndexOf(Pointer(PAnsiChar(Item) + 0)));
      end;
    end;
    for I := Artefacts.Count - 1 downto 0 do
    begin
      Artefact := TArtefact(Artefacts[I + 0]);
      if Artefact.EquippedFlag = 0 then
      begin
        GetPlayer.AddItemToPlayerStorage(Artefact, Location, -1);
        Artefacts.Delete(Artefacts.IndexOf(Pointer(PAnsiChar(Artefact) + 0)));
      end;
    end;
    for Good := 0 to 7 do
      with CargoGoods[Good] do
      begin
        GetPlayer.AddGoodsToPlayerStorage(Good, Count, TotalCost, Location, -1);
        Count := 0;
        TotalCost := 0;
        PurchasedCount := 0;
        PurchasedTotalCost := 0;
      end;
    RefreshDerivedStats(True);
    GetPlayer.RefreshStorageBubbles;
  end;
end;

function TTranclucator.UnloadCargoForPlayerOwner: Boolean;
begin
  Result := False;
  if (OwnerShip <> nil) and (GetPlayer <> nil) and (GetPlayer = OwnerShip) then
  begin
    if IsOnPlanet then
    begin
      StoreUnequippedCargoAt(CurrentPlanet);
      if CargoFreeSpace >= 0 then
        OrderTakeoff;
      Result := True;
    end
    else if IsDockedToShip then
    begin
      StoreUnequippedCargoAt(DockedTo);
      if (CargoFreeSpace >= 0) and DockedTo.InNormalSpace then
        OrderTakeoff
      else
        OrderNone(False);
      Result := True;
    end;
  end;
end;

function TTranclucator.TryLandForStorage: Boolean;
var
  I: Integer;
  Location: TObject;
  Planet: TPlanet;
  Ship: TShip;
  Distance, BestDistance: Double;
begin
  Result := False;
  if (OwnerShip <> nil)
      and (GetPlayer <> nil)
      and (GetPlayer = OwnerShip)
      and HasLooseNonScriptItemsOrGoods then
  begin
    BestDistance := 10000;
    Location := nil;
    if GetStoragePermission(tskPlanet) then
      for I := 0 to CurrentStar.Planets.Count - 1 do
      begin
        Planet := TPlanet(CurrentStar.Planets[I]);
        if (Planet.OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)])
            and (Planet.GetRelationLevelToShip(GetPlayer) >= rlNormal) then
        begin
          Distance := PointDistance(Position, Planet.GetPosition);
          if BestDistance >= Distance then
          begin
            Location := Planet;
            BestDistance := Distance;
          end;
        end;
      end;
    if GetStoragePermission(tskStation) then
      for I := 0 to CurrentStar.Ships.Count - 1 do
      begin
        Ship := TShip(CurrentStar.Ships[I]);
        if (Ship is TRuins)
            and (Ship.GetRelationLevelToShip(GetPlayer) >= rlNormal)
            and Ship.CanDock(Self) then
        begin
          Distance := PointDistance(Position, Ship.Position);
          if BestDistance >= Distance then
          begin
            Location := Ship;
            BestDistance := Distance;
          end;
        end;
      end;
    if Location <> nil then
    begin
      OrderLanding(Location, True);
      Result := True;
    end;
  end;
end;

function TTranclucator.ConvertToStoredArtefact: Boolean;
var
  I, Index: Integer;
  Location: TObject;
  Artefact: TArtefactTranclucator;
begin
  Result := False;
  StoreOnLanding := False;
  SeekItems := False;
  FollowOwner := False;
  if IsOnPlanet then
    Location := CurrentPlanet
  else if IsDockedToShip then
    Location := DockedTo
  else
    Exit;
  if (OwnerShip <> nil)
      and (not (Location is TPlanet)
          or ((Location as TPlanet).OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)])) then
  begin
    EnemyShip := nil;
    TruceShip := nil;
    PartnerShip := nil;
    OrderNone(False);
    AfterburnerActive := False;
    for I := 1 to WeaponCount do
      Weapons[I].Target := nil;
    if ScriptShip <> nil then
      (ScriptShip as TScriptShip).Script.UnbindShip(Self);
    if CurrentStar <> nil then
    begin
      Index := CurrentStar.Ships.IndexOf(Self);
      if Index >= 0 then
        CurrentStar.Ships.Delete(Index);
    end;
    CurrentStar := nil;
    DockedTo := nil;
    CurrentPlanet := nil;
    if GetEngine <> nil then
      GetEngine.OutputPercent := 100;
    StoreUnequippedCargoAt(Location);
    Artefact := TArtefactTranclucator.Create;
    Artefact.InitTranclucator(GetHull.OwnerId, OwnerShip, Self);
    OwnerShip.AddItemToPlayerStorage(Artefact, Location, -1);
    GetPlayer.RefreshStorageBubbles;
    OwnerShip.RefreshDerivedStats(True);
    ScriptItemsAct($2E, Artefact, Location, 0);
    GetPlayer.ScriptItemsAct($2E, Artefact, Location, 0);
    Result := True;
  end;
end;

procedure TTranclucator.UpdateFreeFlightOrder;
begin
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    OrderFollowShip(EnemyShip, 1, False)
  else if (OwnerShip <> nil)
      and (OwnerShip.CurrentStar = CurrentStar)
      and OwnerShip.InNormalSpace then
  begin
    if (OwnerShip.Order = soFollowShip)
        and (OwnerShip.EnemyShip = OwnerShip.OrderTarget)
        and (OwnerShip.EnemyShip <> Self) then
      OrderFollowShip(OwnerShip.EnemyShip, 1, False)
    else
      OrderFollowShip(OwnerShip, 0, False);
  end
  else if (OwnerShip <> nil)
      and (OwnerShip.CurrentStar = CurrentStar)
      and (OwnerShip.CurrentPlanet <> nil) then
    OrderMove(OwnerShip.CurrentPlanet.GetPosition, False)
  else
    OrderRandomFreeFlightMove;
end;

procedure TTranclucator.BuildReachablePlanetQueue;
begin
end;

function TTranclucator.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := False;
end;

function TTranclucator.TryCollectPreferredFloatingLoot(MaxTravelDays: Integer): Boolean;
var
  I: Integer;
  Item, TargetItem: TItem;
  HaveTarget: Boolean;
  Distance, BestDistance: Double;
begin
  Result := False;
  if IsEquipmentUsable(GetCargoHook) and (Speed >= 1) then
  begin
    HaveTarget := False;
    TargetItem := nil;
    BestDistance := 10000;
    for I := 0 to CurrentStar.Items.Count - 1 do
    begin
      Item := TItem(CurrentStar.Items[I]);
      if (CalculateCargoHookPower(GetCargoHook) >= Item.Weight)
          and ((Item.ScriptItem = nil) or (TScriptItem(Item.ScriptItem).Name = ''))
          and not (Item is TArtefactTranclucator) then
      begin
        if Item is TGoods then
        begin
          if not CollectionPermissions[Ord(tckGoods)] then
            Continue;
        end
        else if Item is TArtefact then
        begin
          if not CollectionPermissions[Ord(tckArtefact)] then
            Continue;
        end
        else if Item is TMicroModule then
        begin
          if not CollectionPermissions[Ord(tckMicroModule)] then
            Continue;
        end
        else if Item is TCountableItem then
        begin
          if not CollectionPermissions[Ord(tckCountable)] then
            Continue;
        end
        else if Item is TUselessItem then
        begin
          if not CollectionPermissions[Ord(tckUseless)] then
            Continue;
        end
        else if Byte(Item.ItemType) in [Ord(t_FuelTanks)..Ord(t_CustomWeapon)] then
        begin
          if not CollectionPermissions[Ord(tckEquipment)] then
            Continue;
        end
        else if not CollectionPermissions[Ord(tckOther)] then
          Continue;
        if (CountOtherShipsTargetingItem(Item) <= 0)
            and (CargoFreeSpace - GetReservedPickupWeight >= Item.Weight) then
        begin
          if IsItemInPickupRange(Item) then
            AddPickupTarget(Item, False)
          else
          begin
            Distance := PointDistance(Position, Item.Position);
            if (MaxTravelDays >= Distance / Speed) and (BestDistance >= Distance) then
            begin
              TargetItem := Item;
              HaveTarget := True;
              BestDistance := Distance;
            end;
          end;
        end;
      end;
    end;
    if TargetItem <> nil then
      OrderMove(GetPickupApproachPosition(TargetItem.Position), True);
    if not HaveTarget and (Order = soMove) then
      OrderNone(False);
    if Order = soMove then
      Result := True;
  end;
end;

procedure TTranclucator.EquipEssentialInventory;
var
  I: Integer;
  Item: TItem;
begin
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TItem(Inventory[I]);
    case Byte(Item.ItemType) of
      Ord(t_FuelTanks):
        if GetFuelTanks = nil then
          EquipItem(Item as TFuelTanks)
        else if GetFuelTanks.Weight > Item.Weight then
        begin
          UnequipSlot(Byte(GetFuelTanks.ItemType), 0);
          EquipItem(Item as TFuelTanks);
        end;
      Ord(t_Engine):
        if GetEngine = nil then
          EquipItem(Item as TEngine)
        else if CalculateItemEffectiveness(Item) > CalculateItemEffectiveness(GetEngine) then
        begin
          UnequipSlot(Byte(GetEngine.ItemType), 0);
          EquipItem(Item as TEngine);
        end;
    end;
  end;
  RefreshDerivedStats(True);
end;

procedure TTranclucator.AssignWeaponTargetsInStar;
var
  I, J, AssignedCount: Integer;
  Ship: TShip;
  Weapon: TWeapon;
  Distance: Double;
  Asteroid: TAsteroid;
begin
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I];
    Weapon.Target := nil;
  end;
  AssignedCount := 0;
  if OwnerShip <> nil then
  begin
    // The native code repeats the owner guard before following its enemy.
    if (OwnerShip <> nil)
        and (OwnerShip.EnemyShip <> nil)
        and (OwnerShip.EnemyShip <> Self)
        and (OwnerShip.EnemyShip.CurrentStar = CurrentStar)
        and OwnerShip.EnemyShip.InNormalSpace then
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J];
        if (Weapon.Target = nil)
            and IsEquipmentUsable(Weapon)
            and (PointDistanceSquared(Position, OwnerShip.EnemyShip.Position)
                <= Sqr(GetWeaponRange(Weapon))) then
        begin
          Weapon.Target := OwnerShip.EnemyShip;
          Inc(AssignedCount);
          if WeaponCount = AssignedCount then
            Exit;
        end;
      end;
    if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J];
        if (Weapon.Target = nil)
            and IsEquipmentUsable(Weapon)
            and (PointDistanceSquared(Position, EnemyShip.Position)
                <= Sqr(GetWeaponRange(Weapon))) then
        begin
          Weapon.Target := EnemyShip;
          Inc(AssignedCount);
          if WeaponCount = AssignedCount then
            Exit;
        end;
      end;
    if CurrentStar.Battle <> 0 then
      for I := 0 to CurrentStar.Ships.Count - 1 do
      begin
        Ship := TShip(CurrentStar.Ships[I]);
        if (Ship.OwnerId = Byte(oiDominator)) and Ship.InNormalSpace then
        begin
          Distance := PointDistance(Position, Ship.Position);
          for J := 1 to WeaponCount do
          begin
            Weapon := Weapons[J];
            if (Weapon.Target = nil)
                and IsEquipmentUsable(Weapon)
                and (GetWeaponRange(Weapon) >= Distance) then
            begin
              Weapon.Target := Ship;
              Inc(AssignedCount);
              if WeaponCount = AssignedCount then
                Exit;
            end;
          end;
        end;
      end;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if Ship.InNormalSpace
          and (Ship <> Self)
          and (Ship <> OwnerShip)
          and ((RelationToShip(Ship) < 10) or (Ship = EnemyShip) or (Ship.EnemyShip = Self)) then
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J];
          if (Weapon.Target = nil)
              and IsEquipmentUsable(Weapon)
              and (PointDistanceSquared(Position, Ship.Position)
                  <= Sqr(GetWeaponRange(Weapon))) then
          begin
            Weapon.Target := Ship;
            Inc(AssignedCount);
            if WeaponCount = AssignedCount then
              Exit;
          end;
        end;
    end;
    if GetPlayer.CurrentStar = CurrentStar then
      for I := 0 to CurrentStar.Asteroids.Count - 1 do
      begin
        Asteroid := TAsteroid(CurrentStar.Asteroids[I]);
        Distance := PointDistanceSquared(Position, Asteroid.Position);
        if Distance <= 1000000 then
          for J := 1 to WeaponCount do
          begin
            Weapon := Weapons[J];
            if not (Byte(Weapon.GetWeaponInfo^.ShotType) in [Ord(wstAreaDamage)..Ord(wstRocket)])
                and (Weapon.Target = nil)
                and IsEquipmentUsable(Weapon)
                and (Sqr(GetWeaponRange(Weapon)) >= Distance) then
            begin
              Weapon.Target := Asteroid;
              Inc(AssignedCount);
              if WeaponCount = AssignedCount then
                Exit;
              Break;
            end;
          end;
      end;
  end;
end;

procedure TTranclucator.SelectEnemyShipInStar;
begin
  EnemyShip := nil;
end;

procedure TTranclucator.EngageEnemyShip;
begin
end;

function TTranclucator.RelationToNonRanger(Ship: TShip): Byte;
begin
  if Ship.TypeId in [stKling, stTranclucator] then
    Result := 50
  else
    Result := 100;
end;

function TTranclucator.RelationToRanger(Ranger: Pointer): Byte;
begin
  Result := 100;
end;

procedure TTranclucator.ChangeRelationToRanger(Ranger: Pointer; Amount: Integer);
begin
end;

procedure TTranclucator.ReactToAttack(Attacker: TShip);
begin
  if (OwnerShip = nil)
      or ((OwnerShip <> Attacker)
          and (not (Attacker is TTranclucator)
              or (TTranclucator(Attacker).OwnerShip <> OwnerShip))) then
    EnemyShip := Attacker;
end;

function TTranclucator.RecomputeFearState: Boolean;
begin
  Result := False;
end;

function TTranclucator.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := False;
end;

function TTranclucator.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := Ship = OwnerShip;
end;

function TTranclucator.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := Ship = OwnerShip;
end;

procedure TTranclucator.ProcessCombatDialogue;
begin
end;

procedure TTranclucator.ReactToExtortionDemand(Ranger: Pointer);
begin
end;

function TTranclucator.BuildMoneyExtortionResponse(
    OtherShip: TShip;
    var Response: WideString;
    DemandedAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;

function TTranclucator.BuildCargoExtortionResponse(
    OtherShip: TShip;
    var Response: WideString
): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;

function TTranclucator.BuildTrucePaymentResponse(
    OtherShip: TShip;
    var Response: WideString;
    OfferedAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;

function TTranclucator.BuildAttackRequestResponse(
    Requester: TShip;
    var Response: WideString;
    Target: TShip
): Boolean;
begin
  Result := True;
  Response := LookupVisibleTalkText('Talk.Tranclucator.Attack.Ok', Requester);
  SetJointAttackTarget(Requester, Target);
  FollowOwner := False;
  SeekItems := False;
end;

function TTranclucator.AcceptPartnershipOffer(
    OtherShip: TShip;
    var Response: WideString;
    PaymentAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;

function TTranclucator.BuildPartnershipOfferResponse(
    OtherShip: TShip;
    var Response: WideString;
    PaymentAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;

procedure TTranclucator.RefreshCurrentStanding;
var
  StandingMode: Integer;
begin
  StandingMode := GetScriptStandingOverrideMode;
  if StandingMode = ssmCustomFaction then
    CurrentStanding := ssCustom
  else if StandingMode <> ssmFixed then
  begin
    if OwnerShip = nil then
      CurrentStanding := ssUnaligned
    else
    begin
      OwnerShip.RefreshCurrentStanding;
      if (OwnerShip.CurrentStar = CurrentStar)
          or (OwnerShip.CurrentStanding in [ssCoalitionMilitary, ssPirateMilitary]) then
        CurrentStanding := OwnerShip.CurrentStanding
      else if OwnerShip.CurrentStanding in [ssCoalitionActive, ssCoalitionPassive] then
      begin
        if Byte(CurrentStar.ControlFaction) in [0, 1] then
          CurrentStanding := ssCoalitionActive
        else
          CurrentStanding := ssNeutral;
      end
      else if OwnerShip.CurrentStanding in [ssPiratePassive, ssPirateActive] then
      begin
        if Byte(CurrentStar.ControlFaction) in [1, 2] then
          CurrentStanding := ssPirateActive
        else
          CurrentStanding := ssNeutral;
      end
      else
        CurrentStanding := OwnerShip.CurrentStanding;
    end;
  end;
end;

function TTranclucator.EvaluateStatBonus(BonusKind: TEquipmentBonusKind; Value: Integer): Single;
const
  ScannableDamageFlags = [dkScanBonus..dkDroidBlock];
begin
  Result := 0;
  if Value = 0 then
    Exit;
  case BonusKind of
    bonHull: Result := Value * 200;
    bonFuel: Result := 0;
    bonSpeed: Result := Value;
    bonJump: Result := 0;
    bonRadar: Result := 0;
    bonScan:
      Result := Value * 20 * (Integer(CountWeaponsByDamageFlags(ScannableDamageFlags)) and $7F);
    bonDroid: Result := Value * 10 / Math.Max(0.1, GetHull.GetFragilityFactor([]));
    bonHook:
      Result := (Value * 0.1 + Math.Min(Value, HullBaseSize * EquipmentSizeFactors[5])) * 1.0;
    bonDef: Result := Value * 5 * 100 / Math.Max(5, 100 - Value) * 45 / Math.Max(5, 45 - Value);
    bonWEnergy: Result := Value * 10;
    bonWSplinter: Result := Value * 10;
    bonWMissile: Result := (Ord(GetRadarRange > 0) * 0.9 + 0.1) * (Value * 10);
    bonWRadius:
      Result := Sqr(Math.Max(100, SmoothedEnemySpeed) / Math.Max(100, SmoothedSpeed)) * Value;
    bonHookRadius: Result := Value * 0.1;
    bonMass:
      Result :=
          RemapClamped(Value, HullMassEvaluationStart, HullMassEvaluationEnd, 1, 0.333) * 5000;
    bonSlotRadar:
      if (GetSlotCount(sskRadar) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetRadar <> nil) and (Value < 0) then
        Result :=
            -TranclucatorSlotBonusWeights[Ord(BonusKind)]
                - TranclucatorSlotBonusWeights[18] * (Integer(CountMissileWeapons) and $7F)
      else if (GetSlotCount(sskRadar) = 1) and (Value < 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotScaner:
      if (GetSlotCount(sskScanner) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetScanner <> nil) and (Value < 0) then
        Result :=
            -TranclucatorSlotBonusWeights[Ord(BonusKind)]
                - (Integer(CountWeaponsByDamageFlags(ScannableDamageFlags)) and $7F)
                    * 0.1
                    * TranclucatorSlotBonusWeights[18]
      else if (GetSlotCount(sskScanner) = 1) and (Value < 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotDroid:
      if (GetSlotCount(sskRepairRobot) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetRepairRobot <> nil) and (Value < 0) then
        Result := -TranclucatorSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskRepairRobot) = 1) and (Value < 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotHook:
      if (GetSlotCount(sskCargoHook) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetCargoHook <> nil) and (Value < 0) then
        Result := -TranclucatorSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskCargoHook) = 1) and (Value < 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotDef:
      if (GetSlotCount(sskDefGenerator) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetDefGenerator <> nil) and (Value < 0) then
        Result := -TranclucatorSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskDefGenerator) = 1) and (Value < 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotWeapon:
    begin
      if (GetSlotCount(sskWeapon) < 5) and (Value > 0) then
        Result :=
            Math.Min(Value, 5 - GetSlotCount(sskWeapon))
                * TranclucatorSlotBonusWeights[Ord(BonusKind)];
      if Value < 0 then
        Result :=
            Math.Max(Value, -GetSlotCount(sskWeapon))
                * TranclucatorSlotBonusWeights[Ord(BonusKind)];
      if (Integer(CountEquippedWeapons) and $7F) > Math.Max(Value + GetSlotCount(sskWeapon), 1) then
        Result :=
            Result
                - ((Integer(CountEquippedWeapons) and $7F)
                        - Math.Max(1, Value + GetSlotCount(sskWeapon)))
                    * (TranclucatorSlotBonusWeights[Ord(BonusKind)] * 0.6);
    end;
    bonSlotArt:
    begin
      if (GetSlotCount(sskArtefact) < DefaultHullSlotCounts[8]) and (Value > 0) then
        Result :=
            Math.Min(Value, DefaultHullSlotCounts[8] - GetSlotCount(sskArtefact))
                * TranclucatorSlotBonusWeights[Ord(BonusKind)];
      if Value < 0 then
        Result :=
            Math.Max(Value, -GetSlotCount(sskArtefact))
                * TranclucatorSlotBonusWeights[Ord(BonusKind)];
      if (Artefacts <> nil)
          and (Artefacts.Count > Math.Max(Value + GetSlotCount(sskArtefact), 0)) then
        Result := -1000;
    end;
    bonSlotForsage:
      if (GetSlotCount(sskAfterburner) = 0) and (Value > 0) then
        Result := TranclucatorSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskAfterburner) = 1) and (Value < 0) then
        Result := -TranclucatorSlotBonusWeights[Ord(BonusKind)];
    bonSkill1..bonSkill6:
    begin
      if Value > 0 then
        Result :=
            Math.Min(
                    6
                        - (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F),
                    Value)
                * TranclucatorSkillBonusWeights[Ord(BonusKind)];
      if (Value > 0)
          and (Value
                  + (Integer(
                          GetEffectiveSkillLevel(
                              TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                          ))
                      and $7F)
              > 6) then
        Result :=
            (Value
                        + (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F)
                        - 6)
                    * (TranclucatorSkillBonusWeights[Ord(BonusKind)] * 0.05)
                + Result;
      if Value < 0 then
        Result :=
            Math.Min(
                    Integer(
                            GetEffectiveSkillLevel(
                                TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                            ))
                        and $7F,
                    -Value)
                * -TranclucatorSkillBonusWeights[Ord(BonusKind)];
      if (Value < 0)
          and (Value
                  + (Integer(
                          GetEffectiveSkillLevel(
                              TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                          ))
                      and $7F)
              < 0) then
        Result :=
            (Value
                        + (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F))
                    * (TranclucatorSkillBonusWeights[Ord(BonusKind)] * 0.03)
                + Result;
    end;
  else
    Result := 0;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TArtefactTranclucator.ClassName;
  TCountableItem.ClassName;
  TEngine.ClassName;
  TFuelTanks.ClassName;
  TGoods.ClassName;
  TMicroModule.ClassName;
  TPlanet.ClassName;
  TRuins.ClassName;
  TScriptShip.ClassName;
  TShip.ClassName;
  TTranclucator.ClassName;
  TUselessItem.ClassName;
end;
end.
