{$EXCESSPRECISION OFF}
unit aTransport;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aConst,
  EC_BlockPar,
  EC_Buf,
  aGalaxy,
  aGalaxyStruct,
  aNormalShip,
  aPlanet,
  aShip,
  aItem;
type
  TTransport = class;
  {$Z1}
  TTransportType = (ttTransport = 0, ttLiner = 1, ttDiplomat = 2);
  TTransport = class(TNormalShip)
    TransportType: TTransportType;
    Gap511: array[0..2] of Byte;
    procedure SaveToBuffer(Buffer: TBufEC); override;
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy); override;
    procedure ResolveLoadedReferences(Galaxy: TGalaxy); override;
    procedure NextDay; override;
    procedure NextDayLogic; override;
    procedure AssignWeaponTargetsInStar; override;
    function GetName: WideString; override;
    function GetFullName(const Separator: WideString): WideString; override;
    function GetTypeNameKey: WideString; override;
    function GetGreetingShipCategory: Byte; override;
    function GetHomeStar: TStar; override;
    function GetDominantCareer: TRangerCareer; override;
    function GetStrengthScaledPirateStatus: Byte; override;
    function GetDesiredCargoFreeSpace: Integer; override;
    procedure RefuelAtLocation; override;
    function AdjustItemEvaluation(
        Item: TItem;
        PriceMode: Byte;
        Effectiveness: Single
    ): Single; override;
    function EvaluateStatBonus(BonusKind: TEquipmentBonusKind; Value: Integer): Single; override;
    function EvaluateWeaponDamage(
        Weapon: TWeapon;
        IncludeAdditiveBonuses: Boolean;
        BaseDamage: Single
    ): Single; override;
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
    destructor Destroy; override;
    procedure InitGenerated(
        Planet: TPlanet;
        InitialMoney: Integer;
        SubType: TTransportType;
        RandomizeSubType: Boolean
    );
    function SelectRepairOrTradePlanet: TPlanet;
    function SelectTradePlanet: TPlanet;
    procedure ProcessTrading;
    procedure ProcessUnseenProgression;
    procedure TryOfferRansomToPursuer;
  end;
var
  TransportSkillBonusWeights: array[22..27] of Integer = (80, 80, 100, 100, 60, 5);
  TransportSlotBonusWeights: array[13..20] of Integer = (200, 0, 150, 0, 150, 50, 0, 0);
procedure LinkRecoveredTypes;
implementation
uses
  EC_Struct,
  aPlayer,
  aGalaxyEvent,
  aMissile,
  aAsteroid,
  aScript,
  Classes,
  Math,
  Windows,
  SysUtils,
  aRanger,
  aTranclucator,
  GR_Main,
  Globals,
  GlobalsV,
  EC_Str,
  aMyFunction;

destructor TTransport.Destroy;
begin
  Dec(HomePlanet.HomeTransportCount);
  Dec(Galaxy.TransportCount);
  inherited Destroy;
end;

procedure TTransport.InitGenerated(
    Planet: TPlanet;
    InitialMoney: Integer;
    SubType: TTransportType;
    RandomizeSubType: Boolean
);
var
  I: Integer;
  Ranger: TRanger;
  Good: Byte;
  procedure SelectUniqueName(
      Config: TBlockParEC
  ); // @addr $71E62C @ida "void __usercall $name(TBlockParEC *Config@<eax>, void *ParentFrame@<^0>);" @note "Nested name-selection helper; caller-popped static link and parent Self at -4."
  var
    Index, Attempt, I, J, LastIndex, FirstIndex: Integer;
    Ship: TShip;
    Star: TStar;
    Duplicate: Boolean;
    Block: TBlockParEC;
  begin
    if Config = nil then
      Exit;
    if Config.CountBlocks('Transport' + TransportTypeNames[Ord(TransportType)]) > 0 then
      Block := Config.GetBlock('Transport' + TransportTypeNames[Ord(TransportType)])
    else if Config.CountBlocks('Transport') > 0 then
      Block := Config.GetBlock('Transport')
    else
      Exit;
    if RaceToOwner(PilotRace) = OwnerId then
      Block := Block.GetBlock(OwnerToSys(OwnerId))
    else if Block.CountBlocks(OwnerToSys(OwnerId) + OwnerToSys(RaceToOwner(PilotRace))) > 0 then
      Block := Block.GetBlock(OwnerToSys(OwnerId) + OwnerToSys(RaceToOwner(PilotRace)))
    else if Block.CountBlocks(OwnerToSys(OwnerId)) > 0 then
      Block := Block.GetBlock(OwnerToSys(OwnerId))
    else if Block.CountBlocks(OwnerToSys(RaceToOwner(PilotRace))) > 0 then
      Block := Block.GetBlock(OwnerToSys(RaceToOwner(PilotRace)));
    FirstIndex := 0;
    LastIndex := Block.GetParamCount - 1;
    Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
    for Attempt := FirstIndex to LastIndex do
    begin
      Name := Block.GetParamValue(Index);
      Duplicate := False;
      for I := 0 to Galaxy.Stars.Count - 1 do
      begin
        Star := Galaxy.Stars[I];
        for J := 0 to Star.Ships.Count - 1 do
        begin
          Ship := Star.Ships[J];
          if (Self <> Ship)
              and (Ship.TypeId = stTransport)
              and ((Ship as TTransport).Name = Name) then
          begin
            Duplicate := True;
            Break;
          end;
        end;
      end;
      if not Duplicate then
        Break;
      IncrementWrapped(Index, FirstIndex, LastIndex);
      if Attempt = LastIndex then
        Name := Name + ' ' + '-' + IntToStr(Cardinal(Id) mod 100 + 1) + '-';
    end;
  end;
begin
  Inc(Galaxy.TransportCount);
  Inc(Planet.HomeTransportCount);
  HomePlanet := Planet;
  CurrentPlanet := HomePlanet;
  CurrentStar := CurrentPlanet.CurrentStar;
  CurrentStar.Ships.Add(Self);
  PilotRace := HomePlanet.RaceId;
  OwnerId := RaceToOwner(PilotRace);
  SetMoney(InitialMoney);
  TypeId := stTransport;
  if RandomizeSubType then
    case NextRandomIntRange(0, 100, RandomState) of
      0..45: TransportType := ttTransport;
      46..79: TransportType := ttLiner;
      80..100: TransportType := ttDiplomat;
    end
  else
    TransportType := SubType;
  Name := '';
  SelectUniqueName(ModShipNameConfig);
  if Length(GetName) = 0 then
    SelectUniqueName(LanguageDataConfig.GetBlock('ShipName'));
  for Good := 0 to 7 do
  begin
    CargoGoods[Good].Count := 0;
    CargoGoods[Good].TotalCost := 0;
  end;
  if GetPlayer <> nil then
  begin
    Rank := NextRandomIntRange(0, GetPlayer.Rank, RandomState);
    if Rank > 3 then
      Rank := 3;
    AddRankPoints(NextRandomIntRange(0, CoalitionRankPointThresholds[Rank] div 2, RandomState));
    if not Galaxy.IsZeroStartingExperienceEnabled then
    begin
      GainExperience(
          Round(
              RemapClamped(
                  ShortInt(Rank + Byte(0)),
                  0,
                  3,
                  TotalSkillTrainingCost div 10,
                  TotalSkillTrainingCost div 4
              )
          ),
          0
      );
      GainExperience(
          Round(
              RemapClamped(
                  Galaxy.TechLevel,
                  3,
                  8,
                  TotalSkillTrainingCost div 20,
                  NextRandomIntRange(
                      TotalSkillTrainingCost div 20,
                      TotalSkillTrainingCost div 3,
                      RandomState
                  )
              )
          ),
          0
      );
    end;
  end;
  ChameleonActive := False;
  GraphDominator := Galaxy.GraphDominatorSurfacesEnabled;
  I := 5;
  case TransportType of
    ttTransport: I := 3;
    ttLiner: I := 4;
    ttDiplomat: I := 5;
  end;
  CreateAndEquipHull(
      Round(HullBaseSize * EquipmentSizeFactors[I]),
      1,
      OwnerId,
      SelectRandomHullSeries,
      HomePlanet.OwnerId = Byte(oiPirate)
  );
  CreateAndEquipFuelTanks(
      Round(FuelTanksBaseSize * EquipmentSizeFactors[5]),
      1,
      HomePlanet.OwnerId
  );
  CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 1, HomePlanet.OwnerId);
  if (NextRandomIntRange(1, 10, RandomState) > 9)
      and (GetSlotCountForItemType(Ord(t_CargoHook)) > 0) then
    CreateAndEquipCargoHook(
        CargoHookBaseSize,
        NextRandomIntRange(1, 1, RandomState),
        HomePlanet.OwnerId
    );
  if GetSlotCount(sskWeapon) > WeaponCount then
    CreateAndEquipWeapon(
        Ord(t_Weapon1),
        WeaponInfos[Ord(t_Weapon1)].AverageSize,
        1,
        HomePlanet.OwnerId
    );
  if GetSlotCountForItemType(Ord(t_Radar)) > 0 then
    CreateAndEquipRadar(
        Round(EquipmentSizeFactors[NextRandomIntRange(2, 4, RandomState)] * RadarBaseSize),
        1,
        HomePlanet.OwnerId
    );
  TrainSkillsAutomatically;
  RefreshDerivedStats(True);
  RefreshCurrentStanding;
  SmoothedSpeed := Speed;
  SmoothedEnemySpeed := Speed;
  BuyEquipmentAtLocation(True);
  BuyEquipmentAtLocation(True);
  for I := 0 to Galaxy.Rangers.Count - 1 do
  begin
    Ranger := Galaxy.Rangers[I];
    RangerRelations.Add(Pointer(OwnerRelations[OwnerId, Ranger.OwnerId]));
  end;
end;

procedure TTransport.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TransportType));
end;

procedure TTransport.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
begin
  inherited LoadFromBuffer(Buffer, Galaxy);
  TransportType := TTransportType(Buffer.GetByte);
end;

procedure TTransport.ResolveLoadedReferences(Galaxy: TGalaxy);
begin
  inherited ResolveLoadedReferences(Galaxy);
end;

procedure TTransport.NextDay;
begin
  inherited NextDay;
  try
    if TradeExperience > 0 then
    begin
      if IsHealthEffectActive(22) then
        GainExperience(Round(TradeExperience * 1.5), 4)
      else
        GainExperience(TradeExperience, 4);
      TradeExperience := 0;
    end;
    if (ScriptShip <> nil) and HasScriptControl then
    begin
      ScriptNextDay;
      if ScriptShip <> nil then
        Exit;
    end;
    NextDayLogic;
    if (ScriptShip <> nil) and not HasScriptControl then
      ScriptNextDay;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create('Error in procedure TTransport.NextDay ' + GetFullName(' '));
    end;
  end;
end;

procedure TTransport.NextDayLogic;
var
  Destination: TPointF;
  Planet: TPlanet;
  Stage: Integer;
begin
  Stage := 0;
  try
    if CurrentPlanet <> nil then
    begin
      Stage := 1;
      if CurrentPlanet.OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)] then
      begin
        Stage := 2;
        RepairBrokenEquipmentAtLocation;
        AutoEquipInventory;
        OptimizeInventory;
        RefuelAtLocation;
        ReloadWeaponAmmo;
        if RepairHullAtLocation then
          Exit;
        ProcessTrading;
        BuyEquipmentAtLocation(False);
        RestoreEssentialEquipment;
        ProcessUnseenProgression;
        TrainSkillsAutomatically;
        if TransportType = ttLiner then
          SetMoney(Money + Galaxy.ComputeScaledMiniMoney(CurrentPlanet.OwnerId));
        if TransportType = ttDiplomat then
          SetMoney(
              Money
                  + Galaxy.ComputeScaledMiniMoney(CurrentPlanet.OwnerId)
                      * ((Cardinal(GetEffectiveSkillLevel(psCharisma)) + 1) shr 1)
          );
      end;
      OrderTakeoff;
      Stage := 3;
    end
    else if DockedTo <> nil then
    begin
      if DockedTo.InNormalSpace then
        OrderTakeoff
      else
        OrderNone(False);
    end
    else
    begin
      Stage := 4;
      if InNormalSpace then
      begin
        Stage := 5;
        BuildReachablePlanetQueue;
        Stage := 6;
        if RecomputeFearState then
          TryOfferRansomToPursuer;
        ProcessCombatDialogue;
        AssignWeaponTargetsInStar;
        if not InFear then
        begin
          Stage := 7;
          SelectEnemyShipInStar;
          EngageEnemyShip;
        end
        else
        begin
          Stage := 8;
          if (Order <> soLand) and (Order <> soJump) then
            NavigateToEscapePlanet(True);
          if (Order in [soLand, soJump])
              and (EstimateOrderTravelTurns > 4)
              and (EnemyShip <> nil)
              and (EnemyShip.OrderTarget = Self)
              and (EnemyShip.TypeId in [stRanger, stPirate])
              and (EnemyShip.EstimateOrderTravelTurns < 3)
              and (NextRandomUnitFloat(RandomState) < 0.2)
              and (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 2 = 0) then
            if JettisonCargoGoodsTowardTargetValue(
                Max(200, Galaxy.ComputeScaledMiniMoney(OwnerId) div 2)) then
              NotifyFearCargoDrop(EnemyShip);
        end;
        if Order = soNone then
        begin
          Stage := 9;
          Planet := SelectRepairOrTradePlanet;
          if Planet = nil then
          begin
            Destination.X := NextRandomIntRange(-2000, 2000, RandomState);
            Destination.Y := NextRandomIntRange(-2000, 2000, RandomState);
            OrderMove(Destination, False);
          end
          else if CurrentStar = Planet.CurrentStar then
            OrderLanding(Planet, False)
          else
            OrderJump(Planet.CurrentStar, False);
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create(
          'Error in procedure TTransport.NextDayLogic '
              + GetFullName(' ')
              + ' label = '
              + IntToStr(Stage));
    end;
  end;
end;

function TTransport.SelectRepairOrTradePlanet: TPlanet;
begin
  if HasHullDamageOrBrokenEquippedItems then
    Result := NavigateToQueuedPlanet(False)
  else
    Result := SelectTradePlanet;
end;

function TTransport.SelectTradePlanet: TPlanet;
var
  Attempts: Integer;
begin
  if PlanetQueue.Count > 0 then
  begin
    Attempts := Round(RemapClamped(Galaxy.GetCoalitionToPirateSystemRatio, 0.3, 1, 4, 1));
    repeat
      Result := PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)];
      Dec(Attempts);
    until (Attempts = 0) or Result.IsCoalitionOwned;
  end
  else
    Result := nil;
end;

procedure TTransport.BuildReachablePlanetQueue;
var
  I, J: Integer;
  Planet: TPlanet;
  Star: TStar;
  SmallestShipCount: Integer;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if (HomePlanet <> LastDockedPlanet)
      and (JumpRange >= PointDistance(HomePlanet.CurrentStar.Position, CurrentStar.Position))
      and (GetHull.HullPoints > GetHull.Weight * 0.5)
      and HomePlanet.IsCoalitionOwned then
    PlanetQueue.Add(HomePlanet)
  else
  begin
    SmallestShipCount := 100000;
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TObject(CurrentStar.StarDistances[I].Star) as TStar;
      if (CurrentStar.StarDistances[I].Distance <= JumpRange)
          and ((Star.Ships.Count <= 15)
              or (Star.Ships.Count <= SmallestShipCount)
              or (PlanetQueue.Count <= 0))
          and (Star.ControlFaction <> sfDominators)
          and (Star.Constellation.Id <> 20)
          and (Star.Status.CustomFaction = '') then
        for J := 0 to Star.Planets.Count - 1 do
        begin
          Planet := Star.Planets[J];
          if (Planet.OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)])
              and (Planet <> LastDockedPlanet)
              and ((LastDockedPlanet.CurrentStar = CurrentStar)
                  or (CurrentStar = Star)
                  or (CurrentStar.ControlFaction = sfDominators)
                  or (CurrentStar.Status.CustomFaction <> '')) then
          begin
            PlanetQueue.Add(Planet);
            SmallestShipCount := Min(SmallestShipCount, Star.Ships.Count);
          end;
        end;
    end;
  end;
end;

function TTransport.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId <> Byte(oiDominator);
end;

procedure TTransport.ProcessTrading;
var
  Good: Byte;
  Quantity: Integer;
begin
  case TransportType of
    ttTransport:
      for Good := 0 to 7 do
      begin
        if (Good in [Ord(t_Food)..Ord(t_Narcotics)])
            and (CurrentPlanet.Goods[Good].Count > 0)
            and (ShopGoodsPurchasePrice(Good, nil) < GoodsMarket[Good].AveragePrice)
            and (CargoFreeSpace > 0) then
        begin
          Quantity := Min(Trunc(Money / ShopGoodsPurchasePrice(Good, nil)), CargoFreeSpace);
          Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
          BuyGoodsFromLocation(Good, Quantity);
        end
        else if CargoGoods[Good].Count > 0 then
          if (ShopGoodsSellPrice(Good, nil) > GetAverageCargoCost(Good))
              or (NextRandomUnitFloat(RandomState) < 0.2) then
            SellGoodsToLocation(Good, CargoGoods[Good].Count);
      end;
    ttLiner:
      for Good := 0 to 7 do
      begin
        if (Good in [0..3, 5, 7])
            and (CurrentPlanet.Goods[Good].Count > 0)
            and (ShopGoodsPurchasePrice(Good, nil) < GoodsMarket[Good].AveragePrice)
            and (CargoFreeSpace > 0) then
        begin
          Quantity := Min(Trunc(Money / ShopGoodsPurchasePrice(Good, nil)), CargoFreeSpace);
          Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
          BuyGoodsFromLocation(Good, Quantity);
        end
        else if CargoGoods[Good].Count > 0 then
          if (ShopGoodsSellPrice(Good, nil) > GetAverageCargoCost(Good))
              or (NextRandomUnitFloat(RandomState) < 0.2) then
            SellGoodsToLocation(Good, CargoGoods[Good].Count);
      end;
    ttDiplomat:
      for Good := 0 to 7 do
      begin
        if (Good in [2, 3, 5..7])
            and (CurrentPlanet.Goods[Good].Count > 0)
            and (ShopGoodsPurchasePrice(Good, nil) < GoodsMarket[Good].AveragePrice)
            and (CargoFreeSpace > 0) then
        begin
          Quantity := Min(Trunc(Money / ShopGoodsPurchasePrice(Good, nil)), CargoFreeSpace);
          Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
          BuyGoodsFromLocation(Good, Quantity);
        end
        else if CargoGoods[Good].Count > 0 then
          if (ShopGoodsSellPrice(Good, nil) > GetAverageCargoCost(Good))
              or (NextRandomUnitFloat(RandomState) < 0.2) then
            SellGoodsToLocation(Good, CargoGoods[Good].Count);
      end;
  end;
end;

procedure TTransport.RepairBrokenEquipmentAtLocation;
var
  I: Integer;
  Equipment: TEquipment;
  Artefact: TArtefact;
begin
  for I := 0 to Inventory.Count - 1 do
  begin
    Equipment := Inventory[I];
    if (Equipment.BrokenFlag <> 0) or (Equipment.ConditionPercent < 20) then
      Equipment.Repair;
  end;
  if CanRepairArtefactsAtLocation then
    for I := 0 to Artefacts.Count - 1 do
    begin
      Artefact := Artefacts[I];
      if (Artefact.BrokenFlag <> 0) or (Artefact.ConditionPercent < 20) then
        if Artefact.EquippedFlag <> 0 then
          Artefact.Repair;
    end;
end;

function TTransport.GetHomeStar: TStar;
begin
  Result := HomePlanet.CurrentStar;
end;

function TTransport.GetName: WideString;
begin
  Result := Name;
end;

function TTransport.GetFullName(const Separator: WideString): WideString;
var
  Path, Text: WideString;
begin
  if TypeNameOverrideKey = '' then
    Result :=
        LocalizedText('ShipType.' + OwnerToSys(RaceToOwner(PilotRace)) + '.' + GetTypeNameKey)
            + Separator
            + Name
  else
  begin
    Path := 'ShipType.' + OwnerToSys(RaceToOwner(PilotRace)) + '.' + TypeNameOverrideKey;
    if LanguageDataConfig.CountParamsByPath(Path) > 0 then
      Text := LocalizedText(Path)
    else
      Text := LocalizedText('ShipType.TypeName.' + TypeNameOverrideKey);
    if Text <> '' then
      Result := Text + Separator + Name
    else
      Result := Name;
  end;
end;

function TTransport.GetTypeNameKey: WideString;
begin
  Result := TransportTypeNames[Ord(TransportType)];
end;

function TTransport.GetGreetingShipCategory: Byte;
begin
  case TransportType of
    ttTransport: Result := gscTransport;
    ttLiner: Result := gscLiner;
  else
    Result := gscDiplomat;
  end;
end;

function TTransport.GetDominantCareer: TRangerCareer;
begin
  Result := rcTrader;
end;

function TTransport.GetStrengthScaledPirateStatus: Byte;
begin
  Result := 0;
end;

function TTransport.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
  case TransportType of
    ttTransport: Result := Trunc(GetHull.Weight * 0.3);
    ttLiner: Result := Integer(Trunc(GetHull.Weight * 0.1)) + 30;
    ttDiplomat: Result := Integer(Trunc(GetHull.Weight * 0.1)) + 10;
  end;
end;

procedure TTransport.RefuelAtLocation;
begin
  if GetFuelTanks <> nil then
    GetFuelTanks.Fuel := GetFuelTanks.Capacity;
end;

procedure TTransport.ProcessUnseenProgression;
var
  Award: Byte;
begin
  if (DaysSincePlayerSeen >= 60) and (GetPlayer <> nil) then
  begin
    if NextRandomUnitFloat(RandomState) < 0.06 then
      GainExperience(
          SeededRandomIntRange(100, 500, Seed + Cardinal(Galaxy.CurrentTurn div 59) + 789),
          0
      );
    if (GetPlayer.Rank > Rank) and (NextRandomUnitFloat(RandomState) < 0.03) and (Rank < 4) then
    begin
      AddRankPoints(NextRandomIntRange(10, 20, RandomState));
      TryPromoteRank;
    end;
    if (NextRandomUnitFloat(RandomState) < 0.01)
        and ((AwardIds = nil) or (2 * Rank > AwardIds.Count)) then
    begin
      case TransportType of
        ttTransport:
          Award :=
              SelectAward(
                  RaceToOwner(CurrentPlanet.RaceId),
                  [atAccomplishment, atCowardice],
                  [stKling..Ord(rstCustomStation)]
              );
        ttLiner:
          Award :=
              SelectAward(
                  RaceToOwner(CurrentPlanet.RaceId),
                  [atAccomplishment],
                  [stKling..Ord(rstCustomStation)]
              );
        ttDiplomat:
          Award :=
              SelectAward(
                  RaceToOwner(CurrentPlanet.RaceId),
                  [atAccomplishment..atPerfidy],
                  [stKling..Ord(rstCustomStation)]
              );
      else
        Award := 255;
      end;
      if Award <> AwardNotFound then
        AddAward(Award);
    end;
  end;
end;

function TTransport.RelationToNonRanger(Ship: TShip): Byte;
var
  Value: Integer;
begin
  if Ship.TypeId = stTransport then
  begin
    Value :=
        Round(
            OwnerRelations[
                    Integer(RaceToOwner(PilotRace)) and $7F,
                    Integer(RaceToOwner(Ship.PilotRace)) and $7F]
                * (0.7 * PlanetRaceMarket[PilotRace].FriendlyRelationScale)
        );
    if Value > 100 then
      Value := 100;
    Result := Value;
  end
  else if Ship.TypeId = stPirate then
  begin
    Value :=
        Round(
            OwnerRelations[
                    Integer(RaceToOwner(PilotRace)) and $7F,
                    Integer(RaceToOwner(Ship.PilotRace)) and $7F]
                * (0.5 * PlanetRaceMarket[PilotRace].PirateRelationFactor)
        );
    // Native's reversed clamp always produces 20, but still performs the calculation.
    Value := Min(20, Max(Value, 70));
    Result := Value;
  end
  else if Ship.TypeId = Byte(rstDominion) then
    Result := 40
  else if Ship.TypeId = Byte(rstPirateBase) then
    Result := 50
  else if Ship.TypeId in [stKling, stTranclucator] then
    Result := 50
  else
    Result := 100;
end;

function TTransport.RelationToRanger(Ranger: Pointer): Byte;
begin
  Result := Byte(RangerRelations[Galaxy.Rangers.IndexOf(TObject(Ranger) as TRanger)]);
end;

procedure TTransport.ChangeRelationToRanger(Ranger: Pointer; Amount: Integer);
var
  Relation: Byte;
  Value, Index: Integer;
begin
  Index := Galaxy.Rangers.IndexOf(TObject(Ranger) as TRanger);
  Relation := Byte(RangerRelations[Index]);
  if (TShip(Ranger).GetEffectiveSkillLevel(psCharisma) > 0) and (Amount > 0) then
    Inc(
        Amount,
        Round(Amount * (Integer(TShip(Ranger).GetEffectiveSkillLevel(psCharisma)) and $7F) * 0.2)
    );
  Value := Amount + Relation;
  if Value < 0 then
    Relation := 0
  else if Value > 100 then
    Relation := 100
  else
    Relation := Value;
  RangerRelations[Index] := Pointer(Relation);
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then
    EnemyShip := TShip(Ranger);
end;

procedure TTransport.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.TypeId = stRanger then
  begin
    ChangeRelationToRanger(Attacker, -10);
    if (Attacker.PartnerShip <> nil) and (Attacker.PartnerShip.TypeId = stRanger) then
      ChangeRelationToRanger(Attacker.PartnerShip, -5);
    if Attacker is TTranclucator then
      if TTranclucator(Attacker).OwnerShip <> nil then
        if TTranclucator(Attacker).OwnerShip.TypeId = stRanger then
          ChangeRelationToRanger(TTranclucator(Attacker).OwnerShip, -10);
  end;
end;

function TTransport.RecomputeFearState: Boolean;
var
  Ship: TShip;
  I, EnemyCount: Integer;
  Tolerance, Threat: Double;
begin
  if HasNoUsableWeapons and (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then
  begin
    Result := True;
    InFear := True;
    Exit;
  end;
  Result :=
      (GetHull.HullPoints < GetHull.Weight * 0.2)
          or ((EnemyShip <> nil)
              and ((EnemyShip.OrderTarget = Self) or (GetPlayer = EnemyShip))
              and AcceptsRansomDemandFrom(EnemyShip));
  if not Result then
  begin
    Threat := 0;
    EnemyCount := 0;
    Tolerance := RemapClamped(GetHull.HullPoints, 50, GetHull.Weight, 0, 3);
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := CurrentStar.Ships[I];
      if Ship.InNormalSpace and (Ship <> Self) then
      begin
        if Ship = EnemyShip then
        begin
          Threat := Ship.ChanceToWin(Self) + Threat;
          Inc(EnemyCount);
        end
        else if ((Ship.EnemyShip = Self) and (Ship.OrderTarget = Self))
            or ((Ship.RelationToShip(Self) < 10)
                and (PointDistanceSquared(Position, Ship.Position) < 250000)) then
        begin
          Threat := Ship.ChanceToWin(Self) + Threat;
          if (EnemyShip = nil)
              or (EnemyShip.CurrentStar <> CurrentStar)
              or EnemyShip.IsOutsideStarSpace then
            EnemyShip := Ship
          else if (EnemyShip <> Ship) and (OrderTarget <> EnemyShip) then
            if PointDistanceSquared(EnemyShip.Position, Position)
                > PointDistanceSquared(Ship.Position, Position) then
              EnemyShip := Ship;
        end;
      end;
    end;
    if (EnemyCount - 1) * Threat * 0.5 + Threat > Tolerance then
      Result := True;
  end;
  InFear := Result;
end;

procedure TTransport.TryOfferRansomToPursuer;
var
  Response: WideString;
  Amount: Integer;
  LowOffer, HighOffer: Single;
  Accepted: Boolean;
  Ship: TShip;
begin
  if InNormalSpace
      and (EnemyShip <> nil)
      and (EnemyShip.OrderTarget = Self)
      and (EnemyShip.TruceShip <> Self)
      and (Money > 100)
      and not CanEscapePursuer(EnemyShip)
      and not (EnemyShip.TypeId in NonNegotiatingShipTypes)
      and (EnemyShip.GetMaxWeaponRange * EnemyShip.GetMaxWeaponRange
          >= PointDistanceSquared(Position, EnemyShip.Position))
      and (((Galaxy.CurrentTurn * EnemyShip.Id mod 3 = 0)
              and (NextRandomUnitFloat(RandomState) > 0.2))
          or (GetHullIntegrityPercent < 20))
      and not NoTalk
      and not EnemyShip.NoTalk then
  begin
    LowOffer := Min(Money, GetWealthScaledAmount(1));
    HighOffer := Min(Money, (GetWealthScaledAmount(4) + EnemyShip.GetWealthScaledAmount(4)) * 0.5);
    Amount :=
        Round(Max(100, RemapClamped(GetHull.HullPoints, 0, GetHull.Weight, HighOffer, LowOffer)));
    Ship := EnemyShip;
    Accepted := Ship.BuildTrucePaymentResponse(Self, Response, Amount);
    if (GetPlayer <> Ship) and (GetPlayer.CurrentStar = CurrentStar) then
      NotifyTruceOffer(Ship, Response, Amount);
    if Accepted and RecomputeFearState then
      TryOfferRansomToPursuer;
  end;
end;

function TTransport.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
var
  LicenseFactor, AbductionFactor: Single;
begin
  if (GetPlayer = Ship) and (GetPlayer.PirateLicenseTicks > 0) then
    LicenseFactor := 1.2
  else
    LicenseFactor := 1;
  if AbductedByPirateClan then
    AbductionFactor := 0.5
  else
    AbductionFactor := 1;
  Result :=
      (GetHull.Weight * (0.5 * LicenseFactor * OwnerInfo[OwnerId].FearThresholdScale + 0.2)
              > GetHull.HullPoints)
          and (LicenseFactor * OwnerInfo[OwnerId].FearThresholdScale
              > ChanceToWin(Ship) * AbductionFactor);
end;

function TTransport.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := RelationToShip(Ship) >= 30;
end;

function TTransport.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result :=
      (Integer(RelationToShip(Ship)) and $7F)
              + RemapClamped(Ship.Strength, 0.9 * Strength, Strength * 3, 0, 100)
          > 110;
end;

procedure TTransport.AssignWeaponTargetsInStar;
var
  I, J, Assigned: Integer;
  Ship: TShip;
  Weapon: TWeapon;
  Item: TItem;
  Asteroid: TAsteroid;
  Distance: Single;
  Missile: TMissile;
begin
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I];
    Weapon.Target := nil;
  end;
  Assigned := 0;
  if CurrentStar.Battle <> 0 then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := CurrentStar.Ships[I];
      if (Ship.OwnerId = Byte(oiDominator)) and Ship.InNormalSpace then
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J];
          if (not (Weapon.GetWeaponInfo^.ShotType in [wstTorpedo..wstRocket]) or (Weapon.Ammo <> 0))
              and (Weapon.Target = nil)
              and IsEquipmentUsable(Weapon) then
            if PointDistanceSquared(Position, Ship.Position) <= Sqr(GetWeaponRange(Weapon)) then
            begin
              Weapon.Target := Ship;
              Inc(Assigned);
              if Assigned = WeaponCount then
                Exit;
            end;
        end;
    end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    for J := 1 to WeaponCount do
    begin
      Weapon := Weapons[J];
      if (not (Weapon.GetWeaponInfo^.ShotType in [wstTorpedo..wstRocket]) or (Weapon.Ammo <> 0))
          and (Weapon.Target = nil)
          and IsEquipmentUsable(Weapon) then
        if PointDistanceSquared(Position, EnemyShip.Position) <= Sqr(GetWeaponRange(Weapon)) then
        begin
          Weapon.Target := EnemyShip;
          Inc(Assigned);
          if Assigned = WeaponCount then
            Exit;
        end;
    end;
  for I := 0 to CurrentStar.Missiles.Count - 1 do
  begin
    Missile := CurrentStar.Missiles[I];
    if (Missile.Target = Self) and (Missile.OwnerShip <> Self) then
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J];
        if not (Weapon.GetWeaponInfo^.ShotType in [wstTorpedo..wstRocket])
            and (Weapon.Target = nil)
            and IsEquipmentUsable(Weapon) then
          if PointDistanceSquared(Position, Missile.Position) <= Sqr(GetWeaponRange(Weapon)) then
          begin
            Weapon.Target := Missile;
            Inc(Assigned);
            if Assigned = WeaponCount then
              Exit;
            Break;
          end;
      end;
  end;
  if GetPlayer.CurrentStar = CurrentStar then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do
    begin
      Asteroid := CurrentStar.Asteroids[I];
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance <= 1000000 then
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J];
          // Native asteroid targeting can overwrite an existing assignment.
          if not (Weapon.GetWeaponInfo^.ShotType in [wstAreaDamage..wstRocket])
              and IsEquipmentUsable(Weapon) then
            if Sqr(GetWeaponRange(Weapon)) >= Distance then
            begin
              Weapon.Target := Asteroid;
              Inc(Assigned);
              if Assigned = WeaponCount then
                Exit;
              Break;
            end;
        end;
    end;
  if Galaxy.GetAIJunkToleranceLevel < CurrentStar.Items.Count then
    for I := 0 to CurrentStar.Items.Count - 1 do
    begin
      Item := CurrentStar.Items[I];
      if ((Item.ScriptItem = nil) or (TScriptItem(Item.ScriptItem).Name = ''))
          and ((Item.ItemType = t_Minerals)
              or (2 * Galaxy.GetAIJunkToleranceLevel <= CurrentStar.Items.Count))
          and ((Item.ItemType = t_Minerals) or (Item.OwnerId = Byte(oiDominator))) then
        if (GetPlayer.CurrentStar <> CurrentStar)
            or not GetPlayer.InNormalSpace
            or (GetRelationLevelToShip(GetPlayer) <= rlBad)
            or (PointDistance(GetPlayer.Position, Item.Position) >= 800)
            or ((NextRandomUnitFloat(RandomState) <= 0.1)
                and (PointDistance(GetPlayer.Position, Item.Position) >= 200)) then
          if CanSafelyDetonateItem(Item) and not IsRecentlyDroppedItem(Item) then
            for J := 1 to WeaponCount do
            begin
              Weapon := Weapons[J];
              if not (Weapon.GetWeaponInfo^.ShotType in [wstAreaDamage..wstRocket])
                  and (Weapon.Target = nil)
                  and IsEquipmentUsable(Weapon) then
                if PointDistanceSquared(Position, Item.Position) <= Sqr(GetWeaponRange(Weapon)) then
                begin
                  Weapon.Target := Item;
                  Inc(Assigned);
                  if Assigned = WeaponCount then
                    Exit;
                  Break;
                end;
            end;
    end;
  if GetPlayer <> nil then
    if GetPlayer.CurrentStar = CurrentStar then
      if GetPlayer.InNormalSpace and IsPlayerChameleonEffectiveAgainstSelf then
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J];
          if (not (Weapon.GetWeaponInfo^.ShotType in [wstTorpedo..wstRocket]) or (Weapon.Ammo <> 0))
              and (Weapon.Target = nil)
              and IsEquipmentUsable(Weapon) then
            if PointDistanceSquared(Position, GetPlayer.Position)
                <= Sqr(GetWeaponRange(Weapon)) then
            begin
              Weapon.Target := GetPlayer;
              Inc(Assigned);
              if Assigned = WeaponCount then
                Exit;
            end;
        end;
end;

procedure TTransport.SelectEnemyShipInStar;
var
  I: Integer;
  Ship: TShip;
begin
  if ((EnemyShip = nil)
          or (EnemyShip.CurrentStar <> CurrentStar)
          or (EnemyShip.CurrentStanding in [ssDominator, ssCustom]))
      and (UsableWeaponCount <> 0)
      and ((CurrentStar.ControlFaction <> sfCoalition)
          or (CurrentStar.Status.CustomFaction <> '')) then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := CurrentStar.Ships[I];
      if (Ship.CurrentStanding in [ssDominator, ssCustom]) and Ship.InNormalSpace then
      begin
        EnemyShip := Ship;
        if ChanceToWin(Ship) - OwnerInfo[OwnerId].FearThresholdScale > 0 then
          Break;
      end;
    end;
end;

procedure TTransport.EngageEnemyShip;
begin
  if Order = soFollowShip then
    OrderNone(False);
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
  begin
    if (CurrentStar.ControlFaction <> sfPirates) or (CurrentStar.Battle <> 0) then
      OrderFollowShip(EnemyShip, 1, False);
    if ChanceToWin(EnemyShip) < 0.9 then
      RequestAlliesAttackShip(EnemyShip);
  end;
end;

procedure TTransport.ProcessCombatDialogue;
begin
  if (EnemyShip <> nil)
      and (OrderTarget = EnemyShip)
      and (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 7 = 0)
      and (ChanceToWin(EnemyShip) < 1.3)
      and (GetHullIntegrityPercent > 30) then
    RequestAlliesAttackShip(EnemyShip);
end;

procedure TTransport.ReactToExtortionDemand(Ranger: Pointer);
begin
  if (GetPlayer = Ranger) or (NextRandomUnitFloat(RandomState) < 0.05) then
  begin
    ChangeRelationToRanger(Ranger, -15);
    HomePlanet.ChangeRelationToRanger(Ranger, -2);
    (TObject(Ranger) as TRanger).AddPirateCareerActivity(2);
  end;
end;

function TTransport.BuildMoneyExtortionResponse(
    OtherShip: TShip;
    var Response: WideString;
    DemandedAmount: Integer
): Boolean;
var
  NextDemandTurn: Integer;
  LicenseFactor: Single;
  procedure PayDemand; // @addr $721DBC @ida "void __usercall $name(void *ParentFrame@<^0>);" @note "Nested response helper with caller-popped static link."
  var
    Event: TGalaxyEvent;
  begin
    AbductedByPirateClan := False;
    if GetPlayer = OtherShip then
    begin
      LastPlayerExtortionTurn := Galaxy.CurrentTurn;
      Event := AddGalaxyEvent('PlayerExtortsMoney');
      Event.AddData(DemandedAmount);
      Event.AddData(TypeId);
      Event.AddData(CurrentStar.Id);
      Event.AddData(Id);
      Event.AddData(OwnerId);
      Event.AddTextData(GetName);
      Event.AddTextData(TypeNameOverrideKey);
      if GetPlayer.PirateLicenseTicks > 0 then
      begin
        GetPlayer.SetMoney(GetPlayer.Money + Round(DemandedAmount * 0.9));
        Inc(GetPlayer.PendingPirateLicenseCash, Round(DemandedAmount * 0.1));
        if GetPlayer.PendingPirateLicenseCash > 100000000 then
          GetPlayer.PendingPirateLicenseCash := 100000000;
      end
      else
        GetPlayer.SetMoney(GetPlayer.Money + DemandedAmount);
    end
    else
      OtherShip.SetMoney(OtherShip.Money + DemandedAmount);
    SetMoney(Money - DemandedAmount);
    OtherShip.TruceWithShip(Self);
    if OtherShip.OwnerId = Byte(oiPirate) then
      TNormalShip(OtherShip).AddPirateRankPoints(1);
    if OtherShip is TRanger then
      (OtherShip as TRanger).ApplyExtortionReputationPenalty(Self);
  end;
begin
  Result := False;
  if (GetPlayer = OtherShip) and (GetPlayer.PirateLicenseTicks > 0) then
    LicenseFactor := 0.8
  else
    LicenseFactor := 1;
  NextDemandTurn := LastPlayerExtortionTurn + 30;
  if OtherShip is TRanger then
    ReactToExtortionDemand(OtherShip);
  if (GetPlayer <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then
    EnemyShip := OtherShip;
  if OtherShip.TruceShip = Self then
    Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and PlayerExtortionPactActive then
    Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and (Galaxy.CurrentTurn < NextDemandTurn) then
    Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact', OtherShip)
  else if not AcceptsRansomDemandFrom(OtherShip) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'No', OtherShip)
  else if CanEscapePursuer(OtherShip) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'LongDistance', OtherShip)
  else if DemandedAmount
      > RemapClamped(
          (Integer(GetWinChancePercent(OtherShip)) and $7F) * LicenseFactor,
          0,
          100,
          GetWealthScaledAmount(4),
          GetWealthScaledAmount(2)) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'SumIsVeryBig', OtherShip)
  else if Money < DemandedAmount then
    Response := LookupVisibleTalkText('Talk.Money.AnswerNotMoney', OtherShip)
  else
  begin
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'Ok', OtherShip);
    PayDemand;
    Result := True;
  end;
end;

function TTransport.BuildCargoExtortionResponse(
    OtherShip: TShip;
    var Response: WideString
): Boolean;
var
  Forced: Boolean;
  NextDemandTurn: Integer;
  procedure DropDemand; // @addr $722498 @ida "void __usercall $name(void *ParentFrame@<^0>);" @note "Nested response helper with caller-popped static link."
  var
    Good: Byte;
    Pass, Count, TotalValue, LowValue, HighValue: Integer;
    Enough: Boolean;
    Divisor: Single;
    Event: TGalaxyEvent;
  begin
    AbductedByPirateClan := False;
    TotalValue := 0;
    Enough := False;
    LowValue := GetWealthScaledAmount(1);
    HighValue := GetWealthScaledAmount(4);
    for Pass := 1 to 3 do
    begin
      for Good := 0 to 7 do
        if CargoGoods[Good].Count > 0 then
        begin
          Divisor :=
              RemapClamped(
                  CargoGoods[Good].Count * GoodsMarket[Good].AveragePrice,
                  LowValue,
                  HighValue,
                  2,
                  8
              );
          Count := Max(Int64(1), Round(CargoGoods[Good].Count / Divisor));
          Inc(TotalValue, Count * GoodsMarket[Good].AveragePrice);
          DropGoodsIntoSpace(Good, Count);
          if TotalValue > HighValue then
          begin
            Enough := True;
            Break;
          end;
        end;
      if Enough then
        Break;
    end;
    OtherShip.TruceWithShip(Self);
    if GetPlayer = OtherShip then
    begin
      LastPlayerExtortionTurn := Galaxy.CurrentTurn;
      Event := AddGalaxyEvent('PlayerExtortsGoods');
      Event.AddData(TotalValue);
      Event.AddData(TypeId);
      Event.AddData(CurrentStar.Id);
      Event.AddData(Id);
      Event.AddData(OwnerId);
      Event.AddTextData(GetName);
      Event.AddTextData(TypeNameOverrideKey);
    end;
    OtherShip.OrderMove(Position, True);
    if OtherShip is TRanger then
      (OtherShip as TRanger).ApplyExtortionReputationPenalty(Self);
    if OtherShip.OwnerId = Byte(oiPirate) then
      TNormalShip(OtherShip).AddPirateRankPoints(1);
  end;
begin
  Result := False;
  Forced := (GetPlayer = OtherShip) and OtherShip.IsHealthEffectActive(14);
  NextDemandTurn := LastPlayerExtortionTurn + 30;
  if OtherShip is TRanger then
    ReactToExtortionDemand(OtherShip);
  if (GetPlayer <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then
    EnemyShip := OtherShip;
  if OtherShip.TruceShip = Self then
    Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and PlayerExtortionPactActive then
    Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and (Galaxy.CurrentTurn < NextDemandTurn) then
    Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact', OtherShip)
  else if not AcceptsRansomDemandFrom(OtherShip) and not Forced then
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'No', OtherShip)
  else if CanEscapePursuer(OtherShip) and not Forced then
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'LongDistance', OtherShip)
  else if not HasCargoGoods then
    Response := LookupVisibleTalkText('Talk.Goods.AnswerNotGoods', OtherShip)
  else
  begin
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'Ok', OtherShip);
    DropDemand;
    if GetPlayer = OtherShip then
      PlayerExtortionPactActive := True;
    Result := True;
  end;
end;

function TTransport.BuildTrucePaymentResponse(
    OtherShip: TShip;
    var Response: WideString;
    OfferedAmount: Integer
): Boolean;
var
  NextDemandTurn: Integer;
  procedure AcceptPayment; // @addr $722B2C @ida "void __usercall $name(void *ParentFrame@<^0>);" @note "Nested response helper with caller-popped static link."
  begin
    OtherShip.SetMoney(OtherShip.Money - OfferedAmount);
    SetMoney(Money + OfferedAmount);
    TruceWithShip(OtherShip);
  end;
begin
  Result := False;
  NextDemandTurn := LastPlayerExtortionTurn + 30;
  if OtherShip is TRanger then
    (OtherShip as TRanger).AddTraderCareerActivity(1);
  if OtherShip.TruceShip = Self then
    Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and PlayerExtortionPactActive then
    Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact', OtherShip)
  else if (GetPlayer = OtherShip) and (Galaxy.CurrentTurn < NextDemandTurn) then
    Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact', OtherShip)
  else if RecomputeFearState
      or ((ChanceToWin(OtherShip) < 1) and (GetHullIntegrityPercent < 40))
      or (ChanceToWin(OtherShip) < 0.2)
      or (OfferedAmount
          > RemapClamped(
              Integer(GetWinChancePercent(OtherShip)) and $7F,
              0,
              100,
              GetWealthScaledAmount(1),
              GetWealthScaledAmount(4))) then
  begin
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'Ok', OtherShip);
    AcceptPayment;
    Result := True;
  end
  else
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'No', OtherShip);
end;

function TTransport.BuildAttackRequestResponse(
    Requester: TShip;
    var Response: WideString;
    Target: TShip
): Boolean;
  procedure AcceptRequest; // @addr $722E8C @ida "void __usercall $name(void *ParentFrame@<^0>);" @note "Nested response helper with caller-popped static link."
  begin
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Ok', Requester);
    SetJointAttackTarget(Requester, Target);
    Result := True;
  end;
begin
  Result := False;
  if Requester is TRanger then
  begin
    if Target.TypeId in [stRanger..stPirate] then
      Target.ChangeRelationToRanger(Requester, -20);
    if (Target.OwnerId = Byte(oiDominator)) or (Target.TypeId = stPirate) then
      (Requester as TRanger).AddWarriorCareerActivity(1)
    else
      (Requester as TRanger).AddPirateCareerActivity(8);
  end;
  if (OrderTarget = Target) and (GetRelationLevelToShip(Target) = rlHostile) then
    AcceptRequest
  else if TruceShip = Target then
    Response :=
        FormatText1(
            LookupVisibleTalkText('Talk.Attack.WeAlreadyHavePact', Requester),
            '<color=255,240,100>',
            '<Target>',
            Target.GetName
        )
  else if RelationToShip(Target) >= 30 then
  begin
    if not (Target is TTranclucator) then
      Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriends', Requester)
    else if TTranclucator(Target).OwnerShip = Self then
      Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'ItsMyTranc', Requester)
    else if TTranclucator(Target).OwnerShip = Requester then
      Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'ItsYourTranc', Requester)
    else
      Response :=
          LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriendsTranc', Requester);
  end
  else if not TrustsAttackRequester(Requester) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Suspect', Requester)
  else if InFear or AcceptsRansomDemandFrom(Target) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Fear', Requester)
  else if HasLockedOrFollowOrder then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'HaveBusiness', Requester)
  else
    AcceptRequest;
end;

function TTransport.AcceptPartnershipOffer(
    OtherShip: TShip;
    var Response: WideString;
    PaymentAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;

function TTransport.BuildPartnershipOfferResponse(
    OtherShip: TShip;
    var Response: WideString;
    PaymentAmount: Integer
): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;

function TTransport.AdjustItemEvaluation(
    Item: TItem;
    PriceMode: Byte;
    Effectiveness: Single
): Single;
const
  NoFlags = [];
var
  MoneyPenalty, EffectivenessScale, WeightPenalty, FragilityScale: Single;
  Price: Integer;
  DesiredFreeFraction, DesiredMoneyFraction, HullValueScale: Single;
begin
  case TransportType of
    ttTransport:
    begin
      DesiredMoneyFraction := 0.2;
      FragilityScale := 0.8;
      HullValueScale := 0.1;
    end;
    ttLiner:
    begin
      DesiredMoneyFraction := 0.14;
      FragilityScale := 1;
      HullValueScale := 0.5;
    end;
    ttDiplomat:
    begin
      DesiredMoneyFraction := 0.1;
      FragilityScale := 1.2;
      HullValueScale := 1;
    end;
  else
    DesiredMoneyFraction := 1;
    FragilityScale := 1;
    HullValueScale := 1;
  end;
  if Item.ItemType in [t_FuelTanks, t_Radar, t_Scaner, t_CargoHook] then
    FragilityScale := FragilityScale * 0.5;
  if StrengthInAverageRanger < 0.3 then
    DesiredMoneyFraction := DesiredMoneyFraction * 0.7;
  if StrengthInAverageRanger > 0.9 then
    DesiredMoneyFraction := DesiredMoneyFraction * 1.5;
  DesiredMoneyFraction :=
      Min(
          0.99,
          Max(
              0.01,
              (Galaxy.CountFactionStars(Ord(sfCoalition))
                          / (Galaxy.CountFactionStars(Ord(sfCoalition))
                              + 1
                              + Galaxy.CountFactionStars(Ord(sfPirates)))
                      + 0.1)
                  * DesiredMoneyFraction
          )
      );
  DesiredFreeFraction := Max(0.01, Min(0.99, GetDesiredCargoFreeSpace / Max(100, GetHull.Weight)));
  MoneyPenalty :=
      Sqr((1 / Max(0.01, SmoothedMoneyFraction) - 1) / (1 / DesiredMoneyFraction - 1))
          / Max(SmoothedWealth * 0.05, 1000);
  EffectivenessScale := 2 / Max(10, SmoothedEquipmentEffectiveness);
  WeightPenalty :=
      Sqr((1 / Max(0.01, SmoothedFreeCapacityFraction) - 1) / (1 / DesiredFreeFraction - 1))
          / Max(10, GetHull.Weight * 0.1);
  if (Item.OwnerId = OwnerId) and (TransportType = ttDiplomat) then
    EffectivenessScale := EffectivenessScale * 1.1;
  MoneyPenalty := MoneyPenalty * 0.01 * (100 + SeededRandomIntRange(-15, 15, Id + Seed));
  EffectivenessScale :=
      EffectivenessScale * 0.01 * (100 + SeededRandomIntRange(-15, 15, Seed + 3 * Id));
  WeightPenalty := WeightPenalty * 0.01 * (100 + SeededRandomIntRange(-15, 15, Seed + 5 * Id));
  case PriceMode of
    4: Price := Item.Cost;
    3: Price := Item.CalculateResaleValue(GetEffectiveSkillLevel(psTrading));
    1: Price := -Item.Cost;
    2: Price := 0;
    0:
    begin
      Price := 0;
      WeightPenalty := 0;
      FragilityScale := 0;
    end;
  else
    Price := 0;
    WeightPenalty := 0;
  end;
  if Item.ItemType <> t_Hull then
    Result :=
        Effectiveness
                * EffectivenessScale
                * (1 + (2 - TEquipment(Item).GetFragilityFactor(NoFlags)) * FragilityScale)
            - Item.Weight * WeightPenalty
            - Price * MoneyPenalty
  else
    Result :=
        (Item.Weight * HullValueScale / Max(0.01, TEquipment(Item).GetFragilityFactor(NoFlags))
                    + Effectiveness)
                * EffectivenessScale
            + Item.Weight * WeightPenalty
            - Price * 0.25 * MoneyPenalty;
end;

function TTransport.EvaluateStatBonus(BonusKind: TEquipmentBonusKind; Value: Integer): Single;
const
  ScannerFlags = [dkScanBonus..dkDroidBlock];
  NoFlags = [];
begin
  Result := 0;
  if Value = 0 then
    Exit;
  case BonusKind of
    bonHull: Result := Value * 150;
    bonFuel: Result := Value * 3.5;
    bonSpeed: Result := Value * 1.1;
    bonJump: Result := Value * 30;
    bonRadar: Result := Value * 0.07;
    bonScan:
      Result := Value * 3 + Value * 20 * (Integer(CountWeaponsByDamageFlags(ScannerFlags)) and $7F);
    bonDroid: Result := Value * 8 / Max(0.1, GetHull.GetFragilityFactor(NoFlags));
    bonDef: Result := Value * 6 * 100 / Max(5, 100 - Value) * 45 / Max(5, 45 - Value);
    bonWEnergy: Result := Value * 9;
    bonWSplinter: Result := Value * 9;
    bonWMissile: Result := Value * 9 * (0.1 + ShortInt(GetRadarRange > 0) * 0.9);
    bonWRadius: Result := Value * 1.2 * Sqr(Max(100, SmoothedEnemySpeed) / Max(100, SmoothedSpeed));
    bonMass:
      Result :=
          RemapClamped(
                  Value + GetHull.Weight * 0.2,
                  HullMassEvaluationStart,
                  HullMassEvaluationEnd,
                  1,
                  0.333)
              * 5500;
    bonSlotRadar:
      if (GetSlotCount(sskRadar) = 0) and (Value > 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetRadar <> nil) and (Value < 0) then
        Result :=
            -TransportSlotBonusWeights[Ord(BonusKind)]
                - TransportSlotBonusWeights[18] * (Integer(CountMissileWeapons) and $7F)
      else if (GetSlotCount(sskRadar) = 1) and (Value < 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotDroid:
      if (GetSlotCount(sskRepairRobot) = 0) and (Value > 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetRepairRobot <> nil) and (Value < 0) then
        Result := -TransportSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskRepairRobot) = 1) and (Value < 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotDef:
      if (GetSlotCount(sskDefGenerator) = 0) and (Value > 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * 0.3
      else if (GetDefGenerator <> nil) and (Value < 0) then
        Result := -TransportSlotBonusWeights[Ord(BonusKind)]
      else if (GetSlotCount(sskDefGenerator) = 1) and (Value < 0) then
        Result := TransportSlotBonusWeights[Ord(BonusKind)] * -0.3;
    bonSlotWeapon:
    begin
      if (GetSlotCount(sskWeapon) < 5) and (Value > 0) then
        Result :=
            Min(Value, 5 - GetSlotCount(sskWeapon)) * TransportSlotBonusWeights[Ord(BonusKind)];
      if Value < 0 then
        Result := Max(Value, -GetSlotCount(sskWeapon)) * TransportSlotBonusWeights[Ord(BonusKind)];
      if (Integer(CountEquippedWeapons) and $7F) > Max(Value + GetSlotCount(sskWeapon), 1) then
        Result :=
            Result
                - (TransportSlotBonusWeights[Ord(BonusKind)] * 0.6)
                    * ((Integer(CountEquippedWeapons) and $7F)
                        - Max(1, Value + GetSlotCount(sskWeapon)));
    end;
    bonSkill1..bonSkill6:
    begin
      if Value > 0 then
        Result :=
            Min(
                    6
                        - (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F),
                    Value)
                * TransportSkillBonusWeights[Ord(BonusKind)];
      if (Value > 0)
          and (Value
                  + (Integer(
                          GetEffectiveSkillLevel(
                              TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                          ))
                      and $7F)
              > 6) then
        Result :=
            Result
                + (TransportSkillBonusWeights[Ord(BonusKind)] * 0.05)
                    * (Value
                        + (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F)
                        - 6);
      if Value < 0 then
        Result :=
            Min(
                    Integer(
                            GetEffectiveSkillLevel(
                                TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                            ))
                        and $7F,
                    -Value)
                * -TransportSkillBonusWeights[Ord(BonusKind)];
      if (Value < 0)
          and (Value
                  + (Integer(
                          GetEffectiveSkillLevel(
                              TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                          ))
                      and $7F)
              < 0) then
        Result :=
            Result
                + (TransportSkillBonusWeights[Ord(BonusKind)] * 0.03)
                    * (Value
                        + (Integer(
                                GetEffectiveSkillLevel(
                                    TPilotSkill(EquipmentBonusSkills[Ord(BonusKind) - 22])
                                ))
                            and $7F));
    end;
  else
    Result := 0;
  end;
  if (TransportType = ttDiplomat)
      and (BonusKind in [bonSpeed, bonWEnergy..bonWRadius, bonSlotWeapon, bonSkill5, bonMass]) then
    Result := Result * 1.3;
  if (TransportType = ttTransport) and (BonusKind in [bonFuel, bonJump]) then
    Result := Result * 1.3;
  if (TransportType = ttLiner) and (BonusKind in [bonHull, bonRadar, bonDroid, bonDef]) then
    Result := Result * 1.3;
  if BonusKind in [bonSkill1..bonSkill6] then
    Result :=
        Result
            * 0.01
            * (100 + SeededRandomIntRange(-50, 50, Seed + 131 * Ord(BonusKind)))
            * RaceSkillEvaluationFactors[PilotRace, EquipmentBonusSkills[Ord(BonusKind) - 22]]
  else
    Result := Result * 0.01 * (100 + SeededRandomIntRange(-20, 20, Seed + 131 * Ord(BonusKind)));
end;

function TTransport.EvaluateWeaponDamage(
    Weapon: TWeapon;
    IncludeAdditiveBonuses: Boolean;
    BaseDamage: Single
): Single;
const
  ScannerFlags = [dkScanBonus..dkDroidBlock];
  ShockFlags = [dkShock];
  AcidFlags = [dkAcid];
var
  ScannerFactor, StatusFactor: Single;
  Flags: TDamageFlagSet;
  SpeedFactor: Single;
  I, ShotTotal: Integer;
begin
  Flags := Weapon.GetDamageFlags;
  if (Flags * ScannerFlags <> []) and (GetScanner <> nil) and (GetRadar <> nil) then
    ScannerFactor :=
        RemapClamped(
            GetScannerPower
                - (Integer(
                        DefenseDamageFactorToPercent(
                            GetGeneratedDefenseDamageFactor(Galaxy.TechLevel)
                        ))
                    and $7F)
                + 1,
            -5,
            10,
            0.1,
            2
        )
  else
    ScannerFactor := 0;
  Result := BaseDamage * GetWeaponArtefactDamageFactor(Weapon);
  if dkDestruct in Flags then
    Result := Result * 1.1;
  if dkDrain in Flags then
    Result := Result * 1.5;
  if dkShock in Flags then
    Result := Result * (1.1 + (Integer(CountWeaponsByDamageFlags(ShockFlags)) and $7F) * 0.05);
  StatusFactor := 1;
  if dkScanBonus in Flags then
    StatusFactor := StatusFactor * (1 + ScannerFactor * 0.1);
  if dkBonusToDamaged in Flags then
    StatusFactor := StatusFactor * (1 + ScannerFactor * 0.1);
  if dkReduceEngine in Flags then
    StatusFactor := StatusFactor * (1 + ScannerFactor * 0.1);
  StatusFactor := StatusFactor - 1;
  if IncludeAdditiveBonuses then
  begin
    if dkReduceEngine in Flags then
      Result := Result + ScannerFactor * 10;
    if dkBlockWeapon in Flags then
      Result := Result + ScannerFactor * 10;
    Result := Result + Integer(CountWeaponsByDamageFlags(AcidFlags)) * Weapon.GetShotCount;
    if dkAcid in Flags then
    begin
      ShotTotal := 1;
      for I := 1 to Integer(CountEquippedWeapons) and $7F do
        Inc(ShotTotal, Weapons[I].GetShotCount);
      Result := Result + ShotTotal * 2;
    end;
  end;
  SpeedFactor :=
      Max(100, SmoothedEnemySpeed)
          * GetHull.Weight
          / (HullBaseSize * Max(100, SmoothedSpeed * EquipmentSizeFactors[1]));
  case Byte(Weapon.GetWeaponInfo.ShotType) of
    Ord(wstRocket): Result := Result * 1.0 * Weapon.GetShotCount * (1 + StatusFactor);
    Ord(wstMissile):
      Result :=
          Result
              * (1 + Weapon.GetWeaponInfo.SecondaryDamageRadius * 0.2 * 0.01 + StatusFactor)
              * Weapon.GetShotCount;
    Ord(wstTorpedo):
      Result :=
          Result * (1 + Weapon.GetWeaponInfo.SecondaryDamageRadius * 0.2 * 0.01 + StatusFactor);
    Ord(wstChain): Result := Result * (1.1 + (Weapon.GetShotCount - 1) * 0.2) * (1 + StatusFactor);
    Ord(wstSplash):
      Result :=
          Result
              * (1
                  + Weapon.GetWeaponInfo.SecondaryDamageRadius * 0.2 * 0.01 * SpeedFactor
                  + StatusFactor);
    Ord(wstAreaDamage):
      Result := Result * (1 + Weapon.Range * 0.16 * 0.01 * SpeedFactor + StatusFactor);
  else
    Result := Result * (1 + StatusFactor);
  end;
  Result := Result * Weapon.GetAttackCount;
  Result :=
      Result * 0.01 * (100 + SeededRandomIntRange(-20, 20, Seed + Weapon.GetWeaponInfo.TypeHash));
end;

procedure TTransport.RefreshCurrentStanding;
var
  StandingMode: Integer;
begin
  StandingMode := GetScriptStandingOverrideMode;
  if StandingMode = ssmCustomFaction then
    CurrentStanding := ssCustom
  else if StandingMode <> ssmFixed then
  begin
    if (CurrentSystemKills.Pirate > 0) and (Galaxy.CoalitionDefeatedTurn = 0) then
      CurrentStanding := ssCoalitionActive
    else
      CurrentStanding := ssCoalitionPassive;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TRanger.ClassName;
  TStar.ClassName;
  TTranclucator.ClassName;
  TTransport.ClassName;
end;
end.
