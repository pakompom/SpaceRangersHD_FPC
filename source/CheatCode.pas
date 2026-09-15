{$EXCESSPRECISION OFF}
unit CheatCode;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  ab_Global,
  Classes;
type
  TCheatList = class;
  PointerToTCheatEntry = ^TCheatEntry;
  TCheatCallback = procedure;
  PCheatEntry = PointerToTCheatEntry;
  TCheatEntry = record
    Text: WideString;
    Callback: TCheatCallback;
  end;
  TCheatList = class(TList)
    function AddEntry(Entry: PCheatEntry): Integer;
    destructor Destroy; override;
    function GetEntry(Index: Integer): PCheatEntry;
    function AddCheat(Text: WideString; Callback: TCheatCallback): Integer;
  end;
var
  CheatCandidateIndex: Integer = 0;
  CheatPrefixLength: Integer = 0;
  CheatPrefixSum: Integer = 0;
procedure AddCheatPoints(Points: Integer);
procedure ReportCheat(Points: Integer; const Name: WideString);
procedure CheatRepair;
procedure CheatKlissanmax;
procedure CheatPiratemax;
procedure CheatWarriormax;
procedure CheatKlissancall;
procedure CheatPiratecall;
procedure CheatRangerpoints;
procedure CheatNextrank;
procedure CheatCoolweapon;
procedure CheatLowcostweapon;
procedure CheatBomb;
procedure CheatRobotforce;
procedure CheatArtefact;
procedure CheatMoney;
procedure CheatDrop;
procedure CheatPacking;
procedure CheatKlissanitem;
procedure CheatWeaponstrength;
procedure CheatTenbomb;
procedure CheatRangersdream;
procedure CheatRndbase;
procedure CheatMapsector;
procedure CheatHugemoney;
procedure CheatPelengsurprise;
procedure CheatSuperhull;
procedure CheatBoom;
procedure CheatHaterangers;
procedure CheatPirates;
procedure CheatGun;
procedure CheatVertix;
procedure CheatDevice;
procedure CheatArts;
procedure CheatModule;
procedure CheatSkill;
procedure CheatProgram;
procedure CheatIllness;
procedure CheatStimulant;
procedure CheatIdeal;
procedure CheatShowmap;
procedure CheatMedal;
procedure SetCheatDominatorLevel(Level: Integer);
procedure CheatHorror;
procedure CheatNightmare;
procedure CheatHell;
procedure CheatTechnic;
procedure CheatAmmo;
procedure CheatGod;
procedure CheatHole;
procedure CheatWin;
procedure CheatHweapon;
procedure CheatUltrascan;
procedure CheatTentm;
procedure CheatEncharge;
procedure CheatExpa;
procedure CheatMadeinchina;
procedure CheatZawarudo;
procedure ShowCheatFeedback(Text: WideString);
function IsCheatMessageBoxOpen: Boolean;
procedure HandleDebugKey(Key: Word);
procedure CheatMakedump;
procedure CheatFitness;
procedure CheatExtraone;
procedure CheatSudo;
procedure CheatEvents;
procedure CheatSeed;
procedure CheatInfos;
procedure LinkRecoveredTypes;
implementation
uses
  aCalc,
  aKling,
  GI_MessageLoop,
  GI_MessageBox,
  aGalaxy,
  ThreadCalc,
  aPlayer,
  aShip,
  aItem,
  aConst,
  aMyFunction,
  fStarMap,
  Globals,
  GlobalsV,
  aPlanet,
  aGalaxyEvent,
  SysUtils,
  GR_Main,
  fShip2,
  fRating2,
  EC_Mem,
  Math,
  ab_Ship,
  ab_Hit,
  ab_Object,
  fPanelMain,
  aGalaxyStruct,
  fEquipmentShop,
  fScore,
  fAbout,
  fHangar,
  fScaner,
  fGoodsShop2,
  fPlanet,
  fPlanetNO,
  fInfo,
  aRanger,
  aTranclucator,
  aRuins,
  aNormalShip,
  SE_Space,
  SE_Process,
  EC_Struct,
  fRuinsTalk,
  EC_BlockPar,
  fListBox,
  fTextBox,
  SE_Hole,
  aScript,
  fGameSettings2,
  GI_GraphButton,
  fGalaxy2,
  fSaveManager,
  EC_Str;
// @unit-initialization $876748
// @unit-finalization $50CAC8
var
  CheatEntries: TCheatList; // @addr $88A41C

function TCheatList.AddEntry(Entry: PCheatEntry): Integer;
begin
  Result := inherited Add(Entry);
end;

destructor TCheatList.Destroy;
var
  Index: Integer;
begin
  for Index := 0 to Count - 1 do
    Dispose(GetEntry(Index));
  inherited;
end;

function TCheatList.GetEntry(Index: Integer): PCheatEntry;
begin
  Result := inherited Items[Index];
end;

function TCheatList.AddCheat(Text: WideString; Callback: TCheatCallback): Integer;
var
  Entry: PCheatEntry;
begin
  New(Entry);
  Entry.Text := Text;
  Entry.Callback := Callback;
  Result := AddEntry(Entry);
end;

procedure AddCheatPoints(Points: Integer);
var
  PreviousPoints: Integer;
begin
  PreviousPoints := Galaxy.GetCheatPoints;
  Galaxy.SetCheatPoints(PreviousPoints + Points);
end;

procedure ReportCheat(Points: Integer; const Name: WideString);
var
  Text: WideString;
  Parent: TMessageLoopGI;
  Event: TGalaxyEvent;
begin
  Text := LocalizedColorText('Cheat.Info');
  ReplaceTextToken(Text, '<Name>', Name, '<color=255,240,100>');
  ReplaceTextToken(Text, '<CheatPoints>', WideString(IntToStr(Points)), '<color=255,240,100>');
  if Galaxy <> nil then
  begin
    AddCheatPoints(Points);
    Event := AddGalaxyEvent('PlayerEntersCheatCode');
    Event.AddTextData(CheatEntries.GetEntry(CheatCandidateIndex).Text);
    Event.AddData(Points);
  end;
  Text := Text + #13#10 + LocalizedColorText('Cheat.Ok');
  // Native code reads the total without a nil-galaxy guard.
  ReplaceTextToken(
      Text,
      '<AllPoints>',
      WideString(IntToStr(Galaxy.GetCheatPoints)),
      '<color=255,240,100>'
  );
  if ShipScreen.IsOpen then
    Parent := ShipScreen
  else if RangerRatingScreen.IsOpen then
    Parent := RangerRatingScreen
  else
    Parent := TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI;
  ShowMessageBoxGI(Parent, Text, mbgCancel);
  FullFrameRedrawRequested := True;
  Parent.InvalidateViewport;
  Parent.DrawQueuedUpdateRects;
  if ShipScreen.IsOpen then
  begin
    ShipScreen.Flag3BC := True;
    ShipScreen.FlagD4 := True;
    ShipScreen.PlayTransitionSounds := False;
    ShipScreen.CloseClicked(nil);
  end;
end;

procedure CheatRepair;
var
  I: Integer;
  Item: TEquipment;
begin
  if (Galaxy <> nil)
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace then
  begin
    for I := 0 to GetPlayer.Inventory.Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Inventory[I]);
      if (Item.ItemType = t_Hull)
          or ((Item.EquippedFlag <> 0) and (Item.ConditionPercent < 90)) then
        Item.Repair;
    end;
    for I := 0 to GetPlayer.Artefacts.Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Artefacts[I]);
      if (Item.EquippedFlag <> 0) and (Item.ConditionPercent < 90) then
        Item.Repair;
    end;
    ReportCheat(40, 'REPAIR');
  end;
end;

procedure CheatKlissanmax;
var
  PlanetIndex, StarIndex: Integer;
  Planet: TPlanet;
  Star: TStar;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for StarIndex := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[StarIndex]);
      if (Star.ControlFaction = sfDominators) and (Star.Status.CustomFaction = '') then
      begin
        PlanetIndex := -1;
        while True do
        begin
          if Star.ShipTypeCounts[stKling] >= 12 then
            Break;
          Planet := nil;
          repeat
            Inc(PlanetIndex);
            if PlanetIndex >= Star.Planets.Count then
              PlanetIndex := 0;
            // Preserve DCC32 O- receiver-before-index evaluation.
            Planet := TPlanet(TList(PAnsiChar(Star.Planets) + 0)[PlanetIndex]);
          until Planet.OwnerId <> Byte(oiUninhabited);
          Planet.SpawnWeightedDominatorShip;
        end;
      end;
    end;
    ReportCheat(20, 'KLISSANMAX');
  end;
end;

procedure CheatPiratemax;
var
  PlanetIndex, StarIndex: Integer;
  Planet: TPlanet;
  Star: TStar;
  Created: Integer;
begin
  Created := 0;
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for StarIndex := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[StarIndex]);
      if (Star.ControlFaction = sfPirates) and (Star.Status.CustomFaction = '') then
      begin
        PlanetIndex := -1;
        while True do
        begin
          if Star.CountPirateShips(True) >= 12 then
            Break;
          Planet := nil;
          repeat
            Inc(PlanetIndex);
            if PlanetIndex >= Star.Planets.Count then
              PlanetIndex := 0;
            Planet := TPlanet(TList(PAnsiChar(Star.Planets) + 0)[PlanetIndex]);
          until Planet.OwnerId <> Byte(oiUninhabited);
          Planet.BuyWarrior(100);
          Inc(Created);
          if Created >= 500 then
          begin
            ShowCheatFeedback('Sudden break');
            Break;
          end;
        end;
      end;
    end;
    ReportCheat(20, 'PIRATEMAX');
  end;
end;

procedure CheatWarriormax;
var
  PlanetIndex, StarIndex: Integer;
  Planet: TPlanet;
  Star: TStar;
  Created: Integer;
begin
  Created := 0;
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for StarIndex := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[StarIndex]);
      if (Star.ControlFaction = sfCoalition) and (Star.Status.CustomFaction = '') then
        for PlanetIndex := 0 to Star.Planets.Count - 1 do
        begin
          Planet := TPlanet(Star.Planets[PlanetIndex]);
          if Planet.OwnerId <> Byte(oiUninhabited) then
            while (Planet.Warriors.Count < RemapClamped(Planet.Radius, 60, 100, 2, 6))
                and (Created < 500) do
            begin
              Planet.BuyWarrior(100);
              Inc(Created);
            end;
        end;
    end;
    ReportCheat(20, 'WARRIORMAX');
  end;
end;

procedure CheatKlissancall;
var
  DistanceIndex, ShipIndex, Sent, Eligible: Integer;
  Star: TStar;
  Ship: TShip;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    Sent := 0;
    for DistanceIndex := 1 to Galaxy.Stars.Count - 1 do
    begin
      Star := TObject(GetPlayer.CurrentStar.StarDistances[DistanceIndex].Star) as TStar;
      if (Star.ControlFaction = sfDominators)
          and (Star.Battle = 0)
          and Galaxy.HasUnresolvedDominatorSeries([dsBlazer, dsKeller, dsTerron])
          and (Star.Status.CustomFaction = '') then
      begin
        Eligible := 0;
        for ShipIndex := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(TList(PAnsiChar(Star.Ships) + 0)[ShipIndex]);
          if (Ship.OwnerId = Byte(oiDominator))
              and (Ship.Order = soNone)
              and Ship.InNormalSpace
              and not Ship.HasIndependentScriptFaction then
            Inc(Eligible);
        end;
        if Eligible > 2 then
          for ShipIndex := 0 to Star.Ships.Count - 1 do
          begin
            Ship := TShip(TList(PAnsiChar(Star.Ships) + 0)[ShipIndex]);
            if (Ship.OwnerId = Byte(oiDominator))
                and (Ship.Order = soNone)
                and Ship.InNormalSpace
                and not Ship.HasIndependentScriptFaction then
            begin
              Ship.OrderJump(GetPlayer.CurrentStar, True);
              Inc(Sent);
              Dec(Eligible);
              if Eligible <= 2 then
                Break;
            end;
          end;
        if Sent > 20 then
          Break;
      end;
    end;
    ReportCheat(20, 'KLISSANCALL');
  end;
end;

procedure CheatPiratecall;
var
  DistanceIndex, ShipIndex, Sent, Eligible: Integer;
  Star: TStar;
  Ship: TShip;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    Sent := 0;
    for DistanceIndex := 1 to Galaxy.Stars.Count - 1 do
    begin
      Star := TObject(GetPlayer.CurrentStar.StarDistances[DistanceIndex].Star) as TStar;
      if (Star.ControlFaction = sfPirates)
          and (Star.Battle = 0)
          and (Star.Status.CustomFaction = '') then
      begin
        Eligible := 0;
        for ShipIndex := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(TList(PAnsiChar(Star.Ships) + 0)[ShipIndex]);
          if (Ship.OwnerId = Byte(oiPirate))
              and (Ship.Order = soNone)
              and Ship.InNormalSpace
              and not Ship.HasIndependentScriptFaction then
            Inc(Eligible);
        end;
        if Eligible > 2 then
          for ShipIndex := 0 to Star.Ships.Count - 1 do
          begin
            Ship := TShip(TList(PAnsiChar(Star.Ships) + 0)[ShipIndex]);
            if (Ship.OwnerId = Byte(oiPirate))
                and (Ship.Order = soNone)
                and Ship.InNormalSpace
                and not Ship.HasIndependentScriptFaction then
            begin
              Ship.OrderJump(GetPlayer.CurrentStar, True);
              Inc(Sent);
              Dec(Eligible);
              if Eligible <= 2 then
                Break;
            end;
          end;
        if Sent > 20 then
          Break;
      end;
    end;
    ReportCheat(20, 'PIRATECALL');
  end;
end;

procedure CheatRangerpoints;
begin
  if (Galaxy <> nil)
      and (CurrentScreenId <> screenShip)
      and (GetPlayer <> nil)
      and GetPlayer.IsDockedToShip
      and (GetPlayer.DockedTo.TypeId = Byte(rstRangerCenter))
      and (GetPlayer.FreeExperience < 1000) then
  begin
    GetPlayer.GainExperience(1000, 0);
    ReportCheat(150, 'RANGERPOINTS');
  end;
end;

procedure CheatNextrank;
begin
  ReportCheat(90, 'NEXTRANK');
  if (Galaxy <> nil) and (GetPlayer <> nil) and (CurrentScreenId <> screenShip) then
  begin
    if GetPlayer.Rank <> 7 then
      GetPlayer.AddRankPoints(GetPlayer.GetRankPointsToNextRank);
    if GetPlayer.PirateClanReal and (GetPlayer.PirateRank <> 7) then
      GetPlayer.AddPirateRankPoints(GetPlayer.GetPirateRankPointsToNextRank);
  end;
  if CurrentScreenId = screenRuinsTalk then
  begin
    RuinsTalkScreen.I_Start;
    RuinsTalkScreen.RestartTextPresentation;
  end;
end;

procedure CheatCoolweapon;
var
  Item: TEquipment;
begin
  if (Galaxy <> nil)
      and (CurrentScreenId <> screenShip)
      and (GetPlayer <> nil)
      and GetPlayer.IsOnPlanet then
  begin
    RestoreTemporaryShopStock;
    Item := TWeapon.Create;
    GetPlayer.CurrentPlanet.EquipmentShop.Add(Item);
    (Item as TWeapon)
        .Init(
            TItemType(RandomIntRange(58, 61)),
            RandomIntRange(50, 100),
            RandomIntRange(4, 8),
            RaceToOwner(GetPlayer.CurrentPlanet.RaceId));
    (Item as TWeapon).Improve(ikAny);
    BuildTemporaryShopSlotGrid;
    if CurrentScreenId = screenEquipmentShop then
    begin
      EquipmentShopScreen.BuildGoodsControls;
      EquipmentShopScreen.UpdateScrollButtons;
    end;
    ReportCheat(100, 'COOLWEAPON');
  end;
end;

procedure CheatLowcostweapon;
var
  Item: TWeapon;
  Info: PWeaponInfo;
begin
  if (Galaxy <> nil)
      and (CurrentScreenId <> screenShip)
      and (GetPlayer <> nil)
      and GetPlayer.IsOnPlanet then
  begin
    RestoreTemporaryShopStock;
    Info := Galaxy.SelectWeaponInfo(RandomIntRange(1, 100000), [0], 8, 1);
    Item :=
        CreateGeneratedWeapon(
            Info,
            RandomIntRange(14, 200),
            RandomIntRange(1, 8),
            RaceToOwner(GetPlayer.CurrentPlanet.RaceId)
        );
    GetPlayer.CurrentPlanet.EquipmentShop.Add(Item);
    Item.Cost := RandomIntRange(1, 10);
    if Item.Weight > 100 then
      Item.Improve(ikMajor);
    BuildTemporaryShopSlotGrid;
    if CurrentScreenId = screenEquipmentShop then
    begin
      EquipmentShopScreen.BuildGoodsControls;
      EquipmentShopScreen.UpdateScrollButtons;
    end;
    ReportCheat(20, 'LOWCOSTWEAPON');
  end;
end;

procedure CheatBomb;
var
  Item: TArtefact;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    Item := TArtefact.Create;
    Item.Init(GetPlayer.HomePlanet.OwnerId, t_ArtefactBomb);
    GetPlayer.Artefacts.Add(Item);
    Item := TArtefact.Create;
    Item.Init(GetPlayer.HomePlanet.OwnerId, t_ArtefactBomb);
    GetPlayer.Artefacts.Add(Item);
    GetPlayer.RefreshDerivedStats(True);
    StarMapScreen.MainPanel.RefreshMoneyAndCargo;
    ReportCheat(60, 'BOMB');
  end;
end;

procedure CheatRobotforce;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) and not GetPlayer.InHyperspace then
  begin
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 0));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 1));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 2));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 3));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 4));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 6));
    GetPlayer.Artefacts.Add(CreateConfiguredArtefactByItemType(t_ArtefactTranclucator, 7));
    GetPlayer.RefreshDerivedStats(True);
    ReportCheat(60, 'ROBOTFORCE');
  end;
end;

procedure CheatArtefact;
var
  Item: TItem;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) and (CurrentScreenId = screenArcadeBattle) then
  begin
    Item :=
        CreateRandomLootItem(
            ilpAnyAvailable,
            RaceToOwner(GetPlayer.HomePlanet.RaceId),
            RandomIntRange(1, 1000000000)
        );
    if Item is TArtefact then
      GetPlayer.Artefacts.Add(Item)
    else
      GetPlayer.Inventory.Add(Item);
    GetPlayer.RefreshDerivedStats(True);
    ReportCheat(40, 'ARTEFACT');
  end;
end;

procedure CheatMoney;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
    if (GetPlayer.InNormalSpace
            and (CurrentScreenId = screenStarMap)
            and (StarMapScreen.Mode = smmOrders))
        or (CurrentScreenId = screenPlanet)
        or (CurrentScreenId = screenPlanetNO)
        or (CurrentScreenId = screenGoodsShop)
        or (CurrentScreenId = screenEquipmentShop) then
    begin
      GetPlayer.SetMoney(GetPlayer.Money + 10000);
      if CurrentScreenId = screenStarMap then
        StarMapScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenPlanet then
        PlanetScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenPlanetNO then
        UninhabitedPlanetScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenGoodsShop then
      begin
        GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
        GoodsShopScreen.RefreshGoodsDisplay;
      end
      else if CurrentScreenId = screenEquipmentShop then
        EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo;
      ReportCheat(40, 'MONEY');
    end;
end;

procedure CheatDrop;
var
  Ship, Nearest: TShip;
  I: Integer;
  Distance, BestDistance: Single;
  Item: TEquipment;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    BestDistance := 1.0e30;
    Nearest := nil;
    for I := 0 to GetPlayer.CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(GetPlayer.CurrentStar.Ships[I]);
      if (GetPlayer <> Ship)
          and (BlazerShip <> Ship)
          and (KellerShip <> Ship)
          and (TerronShip <> Ship)
          and (Ship.TypeId in [stKling..stWarrior])
          and not Ship.IsOutsideStarSpace then
      begin
        Distance := PointDistanceSquared(Ship.Position, GetPlayer.Position);
        if Distance < BestDistance then
        begin
          BestDistance := Distance;
          Nearest := Ship;
        end;
      end;
    end;
    if Nearest <> nil then
    begin
      Ship := Nearest;
      for I := Ship.Inventory.Count - 1 downto 0 do
      begin
        Item := TEquipment(Ship.Inventory[I]);
        if (Item.ItemType <> t_Hull)
            and ((Item.ItemType <> t_Engine) or (Item.EquippedFlag = 0))
            and ((Item.ItemType <> t_FuelTanks) or (Item.EquippedFlag = 0)) then
          Ship.DropCarriedItemAsMovingLoot(Item);
      end;
      Ship.RefreshDerivedStats(True);
      ReportCheat(60, 'DROP');
    end;
  end;
end;

procedure CheatPacking;
var
  Item: TItem;
  I: Integer;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and not GetPlayer.InHyperspace
      and ((CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode = smmOrders)) then
  begin
    for I := 1 to GetPlayer.Inventory.Count - 1 do
    begin
      Item := TItem(GetPlayer.Inventory[I]);
      if Item.ItemType <> t_Hull then
        Item.Weight := Max(1, Item.Weight div 2);
    end;
    for I := 0 to GetPlayer.Artefacts.Count - 1 do
    begin
      Item := TItem(GetPlayer.Artefacts[I]);
      if Item.ItemType = t_ArtefactTranclucator then
        TTranclucator((Item as TArtefactTranclucator).Ship).ArtefactSize :=
            Max(1, Item.Weight div 2);
      Item.Weight := Max(1, Item.Weight div 2);
    end;
    GetPlayer.RefreshDerivedStats(True);
    StarMapScreen.MainPanel.RefreshMoneyAndCargo;
    ReportCheat(300, 'PACKING');
  end;
end;

procedure CheatKlissanitem;
var
  Item: TWeapon;
  Info: PWeaponInfo;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.IsDockedToShip
      and (CurrentScreenId <> screenShip)
      and (GetPlayer.DockedTo.TypeId = Byte(rstScienceBase)) then
  begin
    Info := Galaxy.SelectWeaponInfo(RandomIntRange(1, 100000), [4], 8, 1);
    Item := CreateGeneratedWeapon(Info, RandomIntRange(77, 200), RandomIntRange(1, 8), 5);
    case RandomIntRange(1, 3) of
      1: Item.DominatorSeries := dsBlazer;
      2: Item.DominatorSeries := dsKeller;
      3: Item.DominatorSeries := dsTerron;
    end;
    GetPlayer.Inventory.Add(Item);
    GetPlayer.RefreshDerivedStats(True);
    if CurrentScreenId = screenRuinsTalk then
      StarMapScreen.MainPanel.RefreshMoneyAndCargo
    else if CurrentScreenId = screenGoodsShop then
    begin
      GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
      GoodsShopScreen.RefreshGoodsDisplay;
    end
    else if CurrentScreenId = screenEquipmentShop then
      EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo
    else if CurrentScreenId = screenInfo then
      InfoScreen.MainPanel.RefreshMoneyAndCargo;
    ReportCheat(160, 'KLISSANITEM');
  end;
end;

procedure CheatWeaponstrength;
var
  I, J, K: Integer;
  Star: TStar;
  Ship: TShip;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.IsDockedToShip
      and (CurrentScreenId <> screenShip)
      and (GetPlayer.DockedTo.TypeId = Byte(rstPirateBase)) then
  begin
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[I]);
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J]);
        if not (Ship.TypeId in [stKling, stTranclucator..Ord(rstCustomStation)]) then
          if not ((Ship.TypeId = stPirate)
              or (GetPlayer = Ship)
              or ((Ship.TypeId = stRanger) and ((Ship as TRanger).PreferredCareer = rcPirate))) then
          begin
            if GetPlayer <> Ship.PartnerShip then
              Ship.ChangeRelationToRanger(GetPlayer, -60);
          end
          else
          begin
            for K := 1 to Ship.WeaponCount do
            begin
              Ship.Weapons[K].MaxDamage :=
                  Min(255, Ship.Weapons[K].MaxDamage + RandomIntRange(10, 20));
              if GetPlayer <> Ship then
                Ship.ChangeRelationToRanger(GetPlayer, 50);
            end;
            Ship.RefreshDerivedStats(True);
          end;
      end;
    end;
    GetPlayer.CareerStatus[Ord(rcPirate)] := 100;
    GetPlayer.ChangePlanetRelations(nil, rcmDecrease, 60, [0, 2, 3, 4]);
    if CurrentScreenId = screenRuinsTalk then
      StarMapScreen.MainPanel.RefreshMoneyAndCargo
    else if CurrentScreenId = screenGoodsShop then
    begin
      GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
      GoodsShopScreen.RefreshGoodsDisplay;
    end
    else if CurrentScreenId = screenEquipmentShop then
      EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo
    else if CurrentScreenId = screenInfo then
      InfoScreen.MainPanel.RefreshMoneyAndCargo;
    ReportCheat(200, 'WEAPONSTRENGTH');
  end;
end;

procedure CheatTenbomb;
var
  Item: TArtefact;
  Radius, Angle: Single;
  I: Integer;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    for I := 0 to 9 do
    begin
      Item := TArtefact.Create;
      Item.Init(GetPlayer.HomePlanet.OwnerId, t_ArtefactBomb);
      Radius := RandomIntRange(300, 700);
      Angle := HeadingDegreesToRadians(RandomIntRange(0, 360));
      Item.Position.X := GetPlayer.Position.X + Sin(Angle) * Radius;
      Item.Position.Y := GetPlayer.Position.Y - Cos(Angle) * Radius;
      GetPlayer.CurrentStar.Items.Add(Item);
      Item.GetGraphObject.AttachToSpace(SpaceProcess.Space);
      Item.DestroyFlag := 2;
    end;
    ReportCheat(140, 'TENBOMB');
  end;
end;

procedure CheatRangersdream;
var
  Item: TProtoplasm;
  Count, Total: Integer;
  X, Y: Single;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    Total := 0;
    while Total < 10000 do
    begin
      Item := TProtoplasm.Create;
      if 10000 - Total < 100 then
        Count := 10000 - Total
      else
        Count := RandomIntRange(10, 100);
      Item.Init(Count, 1);
      Inc(Total, Count);
      Item.DominatorSeries := TDominatorSeries(RandomIntRange(0, 2));
      repeat
        X := RandomIntRange(-250, 250);
        Y := RandomIntRange(-250, 250);
      until (Sqr(X) + Sqr(Y) > Sqr(50)) and (Sqr(X) + Sqr(Y) < Sqr(250));
      Item.Position.X := GetPlayer.Position.X + X;
      Item.Position.Y := GetPlayer.Position.Y + Y;
      GetPlayer.CurrentStar.Items.Add(Item);
      Item.GetGraphObject.AttachToSpace(SpaceProcess.Space);
    end;
    ReportCheat(140, 'RANGERSDREAM');
  end;
end;

procedure CheatRndbase;
var
  Station: TRuins;
  Ship: TShip;
  I, TotalKinds, Remaining, Choice: Integer;
  Kind: Byte;
  Kinds: TShipTypeMask; // Shared DCU set has the native word-aligned local layout.
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    TotalKinds := 7;
    Remaining := TotalKinds;
    Kinds := [6..12];
    for I := 0 to GetPlayer.CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(GetPlayer.CurrentStar.Ships[I]);
      if Ship is TRuins then
      begin
        Dec(Remaining);
        Exclude(Kinds, Ship.TypeId);
      end;
    end;
    if TotalKinds - Remaining < 3 then
    begin
      Choice := RandomIntRange(1, Remaining);
      I := 0;
      for Kind := 6 to 12 do
        if Kind in Kinds then
        begin
          Inc(I);
          if I = Choice then
          begin
            Station := TRuins.Create;
            Station.Init(TStationType(Kind), GetPlayer.CurrentStar, '');
            Break;
          end;
        end;
      ReportCheat(30, 'RNDBASE');
    end;
  end;
end;

procedure CheatMapsector;
var
  I: Integer;
  Constellation: TConstellation;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.IsDockedToShip
      and (CurrentScreenId <> screenShip)
      and (GetPlayer.DockedTo.TypeId = Byte(rstPirateBase)) then
  begin
    I := 0;
    // Native search skips hidden sectors here, then randomly seeks a hidden one.
    while I < Galaxy.Constellations.Count do
    begin
      if TConstellation(Galaxy.Constellations[I]).Visible then
        Break;
      Inc(I);
    end;
    if I < Galaxy.Constellations.Count then
    begin
      repeat
        Constellation :=
            TConstellation(
                Galaxy.Constellations[RandomIntRange(0, Galaxy.Constellations.Count - 1)]
            );
      until not Constellation.Visible;
      Constellation.Visible := True;
      ReportCheat(20, 'MAPSECTOR');
    end;
  end;
end;

procedure CheatHugemoney;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
    if (GetPlayer.InNormalSpace
            and (CurrentScreenId = screenStarMap)
            and (StarMapScreen.Mode = smmOrders))
        or (CurrentScreenId = screenPlanet)
        or (CurrentScreenId = screenPlanetNO)
        or (CurrentScreenId = screenGoodsShop)
        or (CurrentScreenId = screenEquipmentShop) then
    begin
      GetPlayer.SetMoney((GetPlayer.Money div 1000000 + 1) * 1000000);
      if CurrentScreenId = screenStarMap then
        StarMapScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenPlanet then
        PlanetScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenPlanetNO then
        UninhabitedPlanetScreen.MainPanel.RefreshMoneyAndCargo
      else if CurrentScreenId = screenGoodsShop then
      begin
        GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
        GoodsShopScreen.RefreshGoodsDisplay;
      end
      else if CurrentScreenId = screenEquipmentShop then
        EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo;
      ReportCheat(300, 'HUGEMONEY');
    end;
end;

procedure CheatPelengsurprise;
var
  Item: TItem;
  I: Integer;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.IsOnPlanet
      and (GetPlayer.CurrentPlanet.OwnerId = Byte(oiPeleng))
      and (CurrentScreenId <> screenShip) then
  begin
    for I := 0 to TemporaryShopSlots.Count - 1 do
    begin
      Item := TShopSlot(TemporaryShopSlots[I]).Item;
      if (Item <> nil) and (Item is TWeapon) then
        (Item as TWeapon).Range := (Item as TWeapon).Range * 2;
    end;
    GetPlayer.ChangePlanetRelations(nil, rcmDecrease, 50, [0, 2, 3, 4]);
    ReportCheat(100, 'PELENGSURPRISE');
  end;
end;

procedure CheatSuperhull;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and not GetPlayer.InHyperspace
      and ((CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode = smmOrders)) then
  begin
    GetPlayer.GetHull.Weight := Min(2000, Round(GetPlayer.GetHull.Weight * 1.3));
    GetPlayer.GetHull.HullPoints := GetPlayer.GetHull.Weight;
    GetPlayer.RefreshDerivedStats(True);
    GetPlayer.RefreshGraphicSize;
    StarMapScreen.MainPanel.RefreshMoneyAndCargo;
    ReportCheat(250, 'SUPERHULL');
  end;
end;

procedure CheatBoom;
var
  I: Integer;
  Ship: TShip;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    if (CurrentScreenId = screenArcadeBattle) and (KellerArcadeShip = nil) then
      for I := PlayerArcadeShip.Enemies.Count - 1 downto 0 do
        TabHit(PlayerArcadeShip.Enemies[I])
            .ApplyDamage(
                Round(TabHit(PlayerArcadeShip.Enemies[I]).Health * 2 / ShieldDamageScale),
                nil,
                False);
    if CurrentScreenId = screenStarMap then
      for I := 0 to GetPlayer.CurrentStar.Ships.Count - 1 do
      begin
        Ship := TShip(GetPlayer.CurrentStar.Ships[I]);
        if (GetPlayer <> Ship)
            and not Ship.InHyperspace
            and ((Ship.CurrentPlanet = nil)
                or (Ship.CurrentPlanet.OwnerId <> Byte(oiUninhabited))) then
          Ship.DestroyQueued := True;
      end;
    ReportCheat(30, 'BOOM');
  end;
end;

procedure CheatHaterangers;
const
  ShipTypes = [htPirate..htDiplomat];
  Owners = [0..7];
var
  I: Integer;
  Ship: TShip;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    ReportCheat(10, 'HATERANGERS');
    for I := 0 to Galaxy.Rangers.Count - 1 do
    begin
      Ship := TShip(Galaxy.Rangers[I]);
      (Ship as TRanger).ChangeShipRelations(nil, rcmDecrease, 80, ShipTypes, Owners);
    end;
  end;
end;

procedure CheatPirates;
var
  I, Attempts: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.IsDockedToShip
      and (CurrentScreenId <> screenShip)
      and (GetPlayer.DockedTo.TypeId = Byte(rstPirateBase)) then
  begin
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[I]);
      if (Star.ControlFaction in [sfCoalition, sfPirates]) and (Star.Status.CustomFaction = '') then
      begin
        Attempts := 0;
        repeat
          Planet := TPlanet(Star.Planets[RandomIntRange(0, Star.Planets.Count - 1)]);
          if Planet.OwnerId in [Ord(oiMaloc)..Ord(oiGaal), Ord(oiPirate)] then
          begin
            Planet.BuyPirate(100);
            Break;
          end;
          Inc(Attempts);
        until Attempts = 6;
      end;
    end;
    ReportCheat(100, 'PIRATES');
  end;
end;

procedure CheatGun;
var
  Kind: Byte;
  I: Integer;
  Info: PWeaponInfo;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for I := 1 to CountItemTypesInMask([Ord(t_Weapon1)..Ord(t_Weapon18)]) do
    begin
      Kind := GetItemTypeFromMask([Ord(t_Weapon1)..Ord(t_Weapon18)], I);
      GetPlayer.Inventory.Add(
          CreateGeneratedEquipment(
              TItemType(Kind),
              Round(WeaponInfos[Kind].AverageSize * EquipmentSizeFactors[5]),
              Galaxy.TechLevel,
              GetPlayer.OwnerId
          )
      );
    end;
    for I := 0 to Galaxy.CustomWeaponTypes.Count - 1 do
    begin
      Info := Galaxy.CustomWeaponTypes[I];
      if Info.Availability <> waSystemOnly then
        GetPlayer.Inventory.Add(
            CreateGeneratedWeapon(
                Info,
                Round(Info.AverageSize * EquipmentSizeFactors[5]),
                Galaxy.TechLevel,
                GetPlayer.OwnerId
            )
        );
    end;
    ReportCheat(10, 'GUN');
  end;
end;

procedure CheatVertix;
var
  Owner: Byte;
  Item: TEquipment;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for Owner := 0 to 4 do
    begin
      Item := CreateGeneratedEquipment(t_Weapon14, 20, Galaxy.TechLevel, Owner);
      GetPlayer.Inventory.Add(Item);
    end;
    ReportCheat(10, 'VERTIX');
  end;
end;

procedure CheatDevice;
var
  Kind: Byte;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for Kind := 43 to 49 do
      GetPlayer.Inventory.Add(
          CreateGeneratedEquipment(
              TItemType(Kind),
              Round(GetAverageItemSize(Kind) * EquipmentSizeFactors[5]),
              8,
              GetPlayer.OwnerId
          )
      );
    ReportCheat(10, 'DEVICE');
  end;
end;

procedure CheatArts;
var
  I: Integer;
  Item: TEquipment;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for I := 0 to Length(ArtefactLootPools[3]) - 1 do
    begin
      Item :=
          TObject(CreateConfiguredArtefactByItemType(ArtefactLootPools[3][I], GetPlayer.OwnerId))
              as TEquipmentWithActCode;
      GetPlayer.Artefacts.Add(Item);
    end;
    for I := 0 to Length(CustomArtefactLootPools[3]) - 1 do
    begin
      Item := TArtefactCustom.Create;
      Item.ConfigBlockName := CustomArtefactLootPools[3][I];
      TArtefactCustom(Item).LoadConfig(True);
      TArtefact(Item).Init(GetPlayer.OwnerId, Item.ItemType);
      GetPlayer.Artefacts.Add(Item);
    end;
    for I := 0 to Length(UselessItemLootPools[3]) - 1 do
    begin
      Item := TUselessItem.Create;
      TUselessItem(Item).Init(UselessItemLootPools[3][I], dsBlazer, 0, False);
      Item.OwnerId := GetPlayer.OwnerId;
      GetPlayer.Inventory.Add(Item);
    end;
    ReportCheat(10, 'ARTS');
  end;
end;

procedure CheatModule;
var
  I: Integer;
  Item: TMicroModule;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for I := 0 to MicroModuleTemplateCount - 1 do
      if not MicroModuleTemplates[I].SpecialOnly then
      begin
        Item := TMicroModule.Create;
        Item.Init(I);
        GetPlayer.Inventory.Add(Item);
      end;
    ReportCheat(10, 'MODULE');
  end;
end;

procedure CheatSkill;
var
  I: Byte;
  Ship: TShip;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    Ship := nil;
    if GetInnermostScreenLoop = HangarScreen then
      Ship := HangarScreen.SelectedShip
    else if GetInnermostScreenLoop = ScannerScreen then
      Ship := ScannerScreen.ShipToInspect
    else if GetInnermostScreenLoop = ShipScreen then
      Ship := PlayerHoldShip;
    if Ship = nil then
      Ship := GetPlayer;
    ReportCheat(10, 'SKILL');
    for I := 0 to 5 do
      Ship.BaseSkills[I] := 6;
    if GetInnermostScreenLoop = ScannerScreen then
      ScannerScreen.CloseClicked(nil)
    else if GetInnermostScreenLoop = ShipScreen then
      ShipScreen.CloseClicked(nil);
  end;
end;

procedure CheatProgram;
var
  I: Byte;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for I := Low(ProgramNames) to High(ProgramNames) do
      GetPlayer.ProgramCounts[I] := 100;
    ReportCheat(10, 'PROGRAM');
  end;
end;

procedure CheatIllness;
var
  I: Integer;
  Player: TPlayer;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    Player := GetPlayer;
    for I := 1 to 12 do
    begin
      Player.CaptainHealth[I].Progress := 100;
      Player.CaptainHealth[I].AppliedTurn := Galaxy.CurrentTurn;
      Player.CaptainHealth[I].ExpireTurn := Galaxy.CurrentTurn + 365;
    end;
    ReportCheat(10, 'ILLNESS');
  end;
end;

procedure CheatStimulant;
var
  I: Integer;
  Player: TPlayer;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    Player := GetPlayer;
    for I := 13 to 24 do
    begin
      Player.CaptainHealth[I].Progress := 100;
      Player.CaptainHealth[I].AppliedTurn := Galaxy.CurrentTurn;
      Player.CaptainHealth[I].ExpireTurn := Galaxy.CurrentTurn + 365;
    end;
    ReportCheat(10, 'STIMULANT');
  end;
end;

procedure CheatIdeal;
var
  I: Integer;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) and (GetPlayer.GetHull <> nil) then
    for I := 0 to HullSeriesCount - 1 do
      if HullSeriesDefinitions[I].SystemName = '99' then
      begin
        GetPlayer.GetHull.HullSeries := I;
        ReportCheat(10, 'IDEAL');
        Break;
      end;
end;

procedure CheatShowmap;
var
  I: Integer;
  Constellation: TConstellation;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    for I := 0 to Galaxy.Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Galaxy.Constellations[I]);
      if (MainPiratePlanet = nil)
          or (MainPiratePlanet.CurrentStar.Constellation <> Constellation) then
        Constellation.Visible := True;
    end;
    ReportCheat(10, 'SHOWMAP');
  end;
end;

procedure CheatMedal;
var
  I, J, LastAward: Integer;
  Award: Byte;
  Found: Boolean;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    ReportCheat(10, 'MEDAL');
    LastAward := StrToInt(AnsiString(LookupLocalizedTextByKey('Reward.Count'))) - 1;
    if GetPlayer.AwardIds = nil then
      GetPlayer.AwardIds := TList.Create;
    for I := 0 to LastAward do
    begin
      Found := False;
      for J := 0 to GetPlayer.AwardIds.Count - 1 do
      begin
        Award := Byte(GetPlayer.AwardIds[J]);
        if Award = I then
        begin
          Found := True;
          Break;
        end;
      end;
      if not Found then
        GetPlayer.AddAward(I);
    end;
  end;
end;

procedure SetCheatDominatorLevel(Level: Integer);
var
  Name: WideString;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    case Level of
      1: Name := 'HORROR';
      2: Name := 'NIGHTMAR';
      3: Name := 'HELL';
    end;
    if Galaxy.DominatorModLevel <> Level then
      Galaxy.DominatorModLevel := Level
    else
      Galaxy.DominatorModLevel := 0;
    ReportCheat(10, Name);
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure CheatHorror;
begin
  SetCheatDominatorLevel(1);
end;

procedure CheatNightmare;
begin
  SetCheatDominatorLevel(2);
end;

procedure CheatHell;
begin
  SetCheatDominatorLevel(3);
end;

procedure CheatTechnic;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    if Galaxy.TechnicModEnabled <> 1 then
      Galaxy.TechnicModEnabled := 1
    else
      Galaxy.TechnicModEnabled := 0;
    ReportCheat(10, 'TECHNIC');
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure CheatAmmo;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    if Galaxy.AmmoModEnabled <> 1 then
      Galaxy.AmmoModEnabled := 1
    else
      Galaxy.AmmoModEnabled := 0;
    ReportCheat(10, 'AMMO');
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure CheatGod;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) and (Galaxy.GodModEnabled in [0, 1]) then
  begin
    Galaxy.GodModEnabled := 1 - Galaxy.GodModEnabled;
    ReportCheat(10, 'GOD');
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure CheatHole;
var
  Items: TList;
  Index, Count: Integer;
  Hole: THole;
  Angle, Radius: Single;
  MapName: WideString;
  Parent: TMessageLoopGI;
  Block: TBlockParEC;
  Event: TGalaxyEvent;
  procedure CheatHoleAddName(
      Text: WideString
  ); // @addr $50ABE4 @ida "void __usercall $name(unsigned __int16 *Text@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x50AD41 0x50AD4F" @note "Nested in CheatHole; appends an owned PWideString to the list at ParentFrame-4. Caller removes the static link."
  var
    Cell: PWideString;
  begin
    New(Cell);
    Cell^ := Text;
    Items.Add(Cell);
  end;
begin
  if (Galaxy <> nil)
      and (GetPlayer <> nil)
      and GetPlayer.InNormalSpace
      and (CurrentScreenId = screenStarMap)
      and (StarMapScreen.Mode = smmOrders) then
  begin
    Parent := TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI;
    Items := TList.Create;
    Block := GameDataConfig.GetBlock('ABMap');
    Count := Block.GetBlockCount;
    for Index := 0 to Count do
      if Index < Count then
        CheatHoleAddName(Block.GetBlockByIndex(Index).GetParam('Path'))
      else
        CheatHoleAddName('ABMap.map_boss');
    if ShowListDialog(Parent, Index, LocalizedColorText('Cheat.SelectABMap'), Items, 0, 0) = 1 then
    begin
      MapName := PWideString(Items[Index])^;
      AddCheatPoints(10);
      if Galaxy <> nil then
      begin
        Event := AddGalaxyEvent('PlayerEntersCheatCode');
        Event.AddTextData('Hole');
        Event.AddData(10);
      end;
      Hole := THole.Create;
      Hole.InitializeGraphic('');
      THoleSE(Hole.Graphic).SetState(1);
      Hole.Star1 := GetPlayer.CurrentStar;
      Hole.Star2 := GetPlayer.CurrentStar;
      Hole.ArcadeMapName := MapName;
      Angle := ArcTan2(GetPlayer.Position.X, -GetPlayer.Position.Y);
      Radius :=
          Max(
              GetPlayer.CurrentStar.SafeRadius + 100,
              Sqrt(PointDistanceSquared(GetPlayer.Position, MakePointF(0, 0))) + 200
          );
      Hole.Position1 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
      Angle := HeadingDegreesToRadians(RandomIntRange(0, 359));
      Radius := RandomIntRange(1000, 2000);
      Hole.Position2 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
      Hole.CreatedTurn := Galaxy.CurrentTurn;
      Hole.HoleType := 1;
      StarMapScreen.PendingHoleRefresh := Hole;
      Galaxy.Holes.Add(Hole);
    end;
    while Items.Count > 0 do
    begin
      // Native cleanup frees only the cell, leaving its string allocation intact.
      Dispose(Pointer(Items[0]));
      Items.Delete(0);
    end;
    Items.Free;
    RequestedScreenId := CurrentScreenId;
    Parent.RequestClose(1);
  end;
end;

procedure CheatWin;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) and (CurrentScreenId <> screenArcadeBattle) then
  begin
    AddCheatPoints(10);
    ScoreScreen.RecordPlayerResult(True);
    AboutScreen.ReturnToScores := True;
    RequestedScreenId := screenAbout;
    (TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI).RequestClose(1);
  end;
end;

procedure CheatHweapon;
var
  I: Integer;
  Item: TEquipment;
begin
  if GetPlayer <> nil then
  begin
    for I := 0 to GetPlayer.Inventory.Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Inventory[I]);
      if (Item.EquippedFlag <> 0) and (Item is TWeapon) then
        with Item as TWeapon do
        begin
          TechLevel := 8;
          MinDamage := CalculateGeneratedMinDamage;
          MaxDamage := CalculateStandardMaxDamage;
          Range := CalculateStandardRange;
          Cost := CalculateGeneratedWeaponCost(GetWeaponInfo, Weight, TechLevel, OwnerId);
          if GetWeaponInfo.ShotType in [wstTorpedo, wstMissile, wstRocket] then
          begin
            AmmoCapacity := CalculateGeneratedAmmoCapacity;
            if MicroModuleIndex <> 0 then
              Inc(
                  AmmoCapacity,
                  MicroModuleTemplates[Item.MicroModuleIndex - 1].StatBonuses[Ord(bonAmmo)]
              );
            if SpecialModuleIndex <> 0 then
              Inc(
                  AmmoCapacity,
                  MicroModuleTemplates[Item.SpecialModuleIndex - 1].StatBonuses[Ord(bonAmmo)]
              );
          end;
        end;
    end;
    ReportCheat(10, 'HWEAPON');
  end;
end;

procedure CheatUltrascan;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    if Galaxy.UltraScanModEnabled <> 1 then
      Galaxy.UltraScanModEnabled := 1
    else
      Galaxy.UltraScanModEnabled := 0;
    ReportCheat(10, 'ULTRASCAN');
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure CheatTentm;
var
  I: Integer;
  Item: TArtefactTransmitter;
begin
  if GetPlayer <> nil then
  begin
    for I := 1 to 10 do
    begin
      Item :=
          TArtefactTransmitter(
              CreateConfiguredArtefactByItemType(t_ArtefactTransmitter, GetPlayer.OwnerId)
          );
      Item.Power := 100;
      GetPlayer.Artefacts.Add(Item);
    end;
    ReportCheat(10, 'TENTM');
  end;
end;

procedure CheatEncharge;
var
  I: Integer;
  Item: TArtefact;
begin
  if GetPlayer <> nil then
  begin
    for I := 0 to GetPlayer.Artefacts.Count - 1 do
    begin
      Item := TArtefact(GetPlayer.Artefacts[I]);
      if (Item is TArtefactTransmitter) and (TArtefactTransmitter(Item).Power <= 1000) then
        Inc(TArtefactTransmitter(Item).Power, 100);
    end;
    ReportCheat(10, 'ENCHARGE');
  end;
end;

procedure CheatExpa;
begin
  if GetPlayer <> nil then
  begin
    Inc(GetPlayer.FreeExperience, 1000000);
    ReportCheat(10, 'EXPA');
  end;
end;

procedure CheatMadeinchina;
var
  I: Integer;
  Item: TEquipment;
begin
  if GetPlayer <> nil then
  begin
    // The native loop deliberately starts at one.
    for I := 1 to GetPlayer.Inventory.Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Inventory[I]);
      if Item.EquippedFlag <> 0 then
        Item.OwnerId := Byte(oiUninhabited);
    end;
    ReportCheat(10, 'MADEINCHINA');
  end;
end;

procedure CheatZawarudo;
begin
  if GetPlayer <> nil then
  begin
    if Galaxy.StasisModEnabled <> 1 then
      Galaxy.StasisModEnabled := 1
    else
      Galaxy.StasisModEnabled := 0;
    ReportCheat(10, 'ZAWARUDO');
    StarMapScreen.RefreshScoreModsLabel;
  end;
end;

procedure ShowCheatFeedback(Text: WideString);
begin
  if Galaxy = nil then
    ShowMessageBoxGI(nil, Text, mbgOK)
  else
    AddOrUpdatePlayerBubble(0, Galaxy.CurrentTurn, Text, '');
end;

function IsCheatMessageBoxOpen: Boolean;
var
  Instance: TObject;
  Index: Integer;
begin
  Result := False;
  for Index := MessageLoopStack.Count - 1 downto 0 do
  begin
    Instance := TObject(MessageLoopStack[Index]);
    if Instance is TMessageBoxGI then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure HandleDebugKey(Key: Word);
  function SumCheatPrefix(
      Index,
      Count: Integer
  ): Integer; // @addr $50B884 @ida "int __usercall $name@<eax>(int Index@<eax>, int Count@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x50B99D"
  var
    Position: Integer;
  begin
    Result := 0;
    for Position := 1 to Count do
      Inc(Result, Ord(CheatEntries.GetEntry(Index).Text[Position]));
  end;
begin
  if IsCheatMessageBoxOpen then
    Exit;
  if (Galaxy <> nil) and Galaxy.CheatsDisabled then
    Exit;
  // The native subtract/test chain is DCC32 set membership, not a case statement.
  if not (Integer(TurnCalculationPhase) in [0, 2, 4, 6]) then
    Exit;
  while True do
  begin
    if CheatEntries.Count - 1 < CheatCandidateIndex then
    begin
      CheatCandidateIndex := 0;
      CheatPrefixLength := 0;
      CheatPrefixSum := 0;
      Exit;
    end;
    if (Length(CheatEntries.GetEntry(CheatCandidateIndex).Text) >= CheatPrefixLength + 1)
        and (Ord(CheatEntries.GetEntry(CheatCandidateIndex).Text[CheatPrefixLength + 1]) = Key)
        and (SumCheatPrefix(CheatCandidateIndex, CheatPrefixLength) = CheatPrefixSum) then
      Break;
    Inc(CheatCandidateIndex);
  end;
  Inc(CheatPrefixLength);
  Inc(CheatPrefixSum, Key);
  if Length(CheatEntries.GetEntry(CheatCandidateIndex).Text) = CheatPrefixLength then
  begin
    if CheatEntries.Count > CheatCandidateIndex then
      CheatEntries.GetEntry(CheatCandidateIndex).Callback;
    CheatCandidateIndex := 0;
    CheatPrefixLength := 0;
    CheatPrefixSum := 0;
  end;
end;

procedure CheatMakedump;
begin
  if (GetPlayer <> nil)
      and not Galaxy.IronWill
      and not GetPlayer.InHyperspace
      and (Galaxy.FinalizationName = '')
      and (CurrentScreenId
          in [
              screenHangar,
              screenPlanet,
              screenPlanetNO,
              screenEquipmentShop,
              screenGovernment,
              screenStarMap,
              screenRuinsTalk,
              screenInfo,
              screenGoodsShop])
      and (TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).ChildLoop = nil) then
  begin
    aCalc.WaitForTurnCalculationUI;
    Galaxy.CampaignFlag183 := 1;
    CaptureSavePreview;
    CaptureGalaxyPreview(TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]));
    aCalc.WaitForTurnCalculationUI;
    SaveManagerReturnScreenId := CurrentScreenId;
    SaveManagerMode := smmSave;
    RequestedScreenId := screenSaveManager;
    TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).RequestClose(1);
  end;
end;

procedure CheatFitness;
var
  Block: TBlockParEC;
  FileName: WideString;
  Index, Number: Integer;
  Path: WideString;
  Item: TEquipment;
begin
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    FileName := GetGameUserDirectory + 'PlayerFit.txt';
    Block := TBlockParEC.Create;
    Number := 1;
    Block.AddParam('GameVersion', '2.1.2500');
    Block.AddParam(GetPlayer.GetLocalizedTypeName, GetPlayer.GetName);
    for Index := 0 to GetPlayer.Inventory.Count - 1 do
    begin
      Item := GetPlayer.Inventory[Index];
      if (Item is THull) or (Item.EquippedFlag <> 0) then
      begin
        if Item is TWeapon then
        begin
          Path := 'Weapon' + IntToStr(Number);
          Inc(Number);
        end
        else
          Path := ItemTypeNames[Ord(Item.ItemType)];
        Item.SaveToBlock(Block.AddBlockByPath(Path));
      end;
    end;
    Number := 1;
    for Index := 0 to GetPlayer.Artefacts.Count - 1 do
    begin
      Item := GetPlayer.Artefacts[Index];
      if Item.EquippedFlag <> 0 then
      begin
        Path := 'Artefact' + IntToStr(Number);
        Inc(Number);
        Item.SaveToBlock(Block.AddBlockByPath(Path));
      end;
    end;
    Block.SaveTextFile(PWideChar(FileName), True, False);
    Block.Free;
    ReportCheat(0, 'FITNESS');
  end;
end;

procedure CheatExtraone;
var
  I, Count: Integer;
  Good: Byte;
  Item: TEquipment;
begin
  if GetPlayer <> nil then
  begin
    Count := GetPlayer.Inventory.Count;
    for I := 1 to Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Inventory[I]);
      if (Item.EquippedFlag = 0) and (Item.ScriptItem = nil) and not (Item is TTreasureMap) then
      begin
        if Item is TCountableItem then
        begin
          (Item as TCountableItem).StackCount := (Item as TCountableItem).StackCount * 2;
          Item.Weight := Item.Weight * 2;
        end
        else
        begin
          Item := TEquipment(Item.Clone);
          if Item <> nil then
            GetPlayer.Inventory.Add(Item);
        end;
      end;
    end;
    Count := GetPlayer.Artefacts.Count;
    for I := 0 to Count - 1 do
    begin
      Item := TEquipment(GetPlayer.Artefacts[I]);
      if (Item.EquippedFlag = 0) and (Item.ScriptItem = nil) then
      begin
        Item := TEquipment(Item.Clone);
        if Item <> nil then
          GetPlayer.Artefacts.Add(Item);
      end;
    end;
    for Good := 0 to 7 do
      GetPlayer.CargoGoods[Good].Count := GetPlayer.CargoGoods[Good].Count * 2;
    GetPlayer.RefreshDerivedStats(True);
    ReportCheat(10, 'EXTRAONE');
  end;
end;

procedure CheatSudo;
var
  Value, ScriptName: WideString;
  Quote: WideChar;
  Index, Count: Integer;
  Script: TScript;
  Found: Boolean;
begin
  if Galaxy <> nil then
    aCalc.WaitForTurnCalculationUI;
  Value := '';
  if ShowTextInputDialog(
          TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI,
          'Enter script command',
          Value,
          255,
          0,
          0)
      = 1 then
    try
      Count := Length(Value);
      if Count > 0 then
      begin
        Quote := Value[1];
        // The native double-quote test compares against two characters.
        if (Quote = #39) or (WideString(Quote) = '""') then
        begin
          for Index := 2 to Count do
            if Value[Index] = Quote then
              Break;
          if Index < Count then
          begin
            ScriptName := CopyWideStringUnchecked(Value, 2, Index - 2);
            Value := CopyWideStringUnchecked(Value, Index + 1, Count - Index);
            Found := False;
            if Galaxy <> nil then
              for Index := 0 to Galaxy.Scripts.Count - 1 do
              begin
                Script := TScript(Galaxy.Scripts[Index]);
                if Script.ScriptFileName = ScriptName then
                begin
                  Found := True;
                  ExecuteScriptText(Value, Script.InitCode.LocalVar);
                  Break;
                end;
              end;
            if not Found then
              raise Exception.Create('Error, script with name ' + ScriptName + 'is not found');
          end;
        end
        else
          ExecuteScriptText(Value, nil);
      end;
    except
      on E: Exception do
        ShowMessageBoxGI(
            TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI,
            E.Message,
            mbgCancel
        );
    end;
  if Galaxy <> nil then
    aCalc.WaitForTurnCalculationUI;
end;

procedure CheatEvents;
var
  Event: TGalaxyEvent;
  Index, I: Integer;
begin
  if Galaxy <> nil then
  begin
    Index := Galaxy.GalaxyEvents.Count - 1;
    AppendLogLineThreadSafe('----------------------------------------');
    AppendLogLineThreadSafe('Events:');
    AppendLogLineThreadSafe('----------------------------------------');
    while Index >= 0 do
    begin
      Event := TGalaxyEvent(Galaxy.GalaxyEvents[Index]);
      AppendLogLineThreadSafe(AnsiString(Event.EventType));
      AppendLogLineThreadSafe(
          AnsiString(FormatGameTurnDate(Event.Turn) + ' (' + IntToStr(Event.Turn) + ')')
      );
      if Event.TextData <> nil then
      begin
        AppendLogLineThreadSafe('  Text data:');
        for I := 0 to Event.TextData.Count - 1 do
          AppendLogLineThreadSafe(AnsiString('  ' + PWideString(Event.TextData[I])^));
      end;
      if Event.Data <> nil then
      begin
        AppendLogLineThreadSafe('  Data:');
        for I := 0 to Event.Data.Count - 1 do
          AppendLogLineThreadSafe('  ' + IntToStr(Integer(Event.Data[I])));
        AppendLogLineThreadSafe('');
      end;
      Dec(Index);
    end;
    AppendLogLineThreadSafe('----------------------------------------');
  end;
end;

procedure CheatSeed;
var
  Value: WideString;
begin
  if TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]) = NewGameScreen then
    if (NewGameScreen.GetByName('ButExtended') as TGraphButtonGI).Down then
    begin
      if NewGameSeedText = '' then
      begin
        Randomize;
        NewGameSeedText := IntToWideString(RandomIntRange(100000, MaxInt));
      end;
      Value := NewGameSeedText;
      if ShowTextInputDialog(NewGameScreen, 'SEED', Value, 30, 0, 0) = 1 then
        NewGameSeedText := Value;
    end;
end;

procedure CheatInfos;
var
  Star: TStar;
  Ship: TShip;
  Info: PCustomShipInfo;
  I, J, K: Integer;
  PrintedHeader: Boolean;
begin
  if Galaxy <> nil then
  begin
    AppendLogLineThreadSafe('----------------------------------------');
    AppendLogLineThreadSafe('ShipInfos:');
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[I]);
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J]);
        PrintedHeader := False;
        for K := 0 to Ship.CustomShipInfos.Count - 1 do
        begin
          Info := Ship.CustomShipInfos[K];
          if not Info.DeleteQueued then
          begin
            if not PrintedHeader then
            begin
              AppendLogLineThreadSafe('----------------------------------------');
              AppendLogLineThreadSafe(AnsiString(Ship.GetFullName(' ')));
            end;
            PrintedHeader := True;
            AppendLogLineThreadSafe(
                AnsiString(
                    Info.TypeName
                        + ' '
                        + IntToStr(Info.Data[1])
                        + ','
                        + IntToStr(Info.Data[2])
                        + ','
                        + IntToStr(Info.Data[3])
                        + ',"'
                        + Info.TextData1
                        + '","'
                        + Info.TextData2
                        + '","'
                        + Info.TextData3
                        + '"'
                )
            );
          end;
        end;
      end;
    end;
    AppendLogLineThreadSafe('----------------------------------------');
  end;
end;

// Compiler unit entry $876748 registers the native command order.
// Compiler unit entry $50CAC8 calls the virtual destructor directly.
procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TArtefactTranclucator.ClassName;
  TArtefactTransmitter.ClassName;
  TCountableItem.ClassName;
  TEquipmentWithActCode.ClassName;
  TGraphButtonGI.ClassName;
  THull.ClassName;
  TMessageBoxGI.ClassName;
  TMessageLoopGI.ClassName;
  TRanger.ClassName;
  TRuins.ClassName;
  TStar.ClassName;
  TTreasureMap.ClassName;
  TWeapon.ClassName;
end;
initialization
  CheatEntries := TCheatList.Create;
  CheatEntries.AddCheat('REPAIR', CheatRepair);
  CheatEntries.AddCheat('KLISSANMAX', CheatKlissanmax);
  CheatEntries.AddCheat('PIRATEMAX', CheatPiratemax);
  CheatEntries.AddCheat('WARRIORMAX', CheatWarriormax);
  CheatEntries.AddCheat('KLISSANCALL', CheatKlissancall);
  CheatEntries.AddCheat('PIRATECALL', CheatPiratecall);
  CheatEntries.AddCheat('RANGERPOINTS', CheatRangerpoints);
  CheatEntries.AddCheat('NEXTRANK', CheatNextrank);
  CheatEntries.AddCheat('COOLWEAPON', CheatCoolweapon);
  CheatEntries.AddCheat('LOWCOSTWEAPON', CheatLowcostweapon);
  CheatEntries.AddCheat('BOMB', CheatBomb);
  CheatEntries.AddCheat('ARTEFACT', CheatArtefact);
  CheatEntries.AddCheat('MONEY', CheatMoney);
  CheatEntries.AddCheat('DROP', CheatDrop);
  CheatEntries.AddCheat('PACKING', CheatPacking);
  CheatEntries.AddCheat('KLISSANITEM', CheatKlissanitem);
  CheatEntries.AddCheat('WEAPONSTRENGTH', CheatWeaponstrength);
  CheatEntries.AddCheat('TENBOMB', CheatTenbomb);
  CheatEntries.AddCheat('RNDBASE', CheatRndbase);
  CheatEntries.AddCheat('MAPSECTOR', CheatMapsector);
  CheatEntries.AddCheat('HUGEMONEY', CheatHugemoney);
  CheatEntries.AddCheat('PELENGSURPRISE', CheatPelengsurprise);
  CheatEntries.AddCheat('SUPERHULL', CheatSuperhull);
  CheatEntries.AddCheat('BOOM', CheatBoom);
  CheatEntries.AddCheat('HATERANGERS', CheatHaterangers);
  CheatEntries.AddCheat('PIRATES', CheatPirates);
  CheatEntries.AddCheat('GUN', CheatGun);
  CheatEntries.AddCheat('VERTIX', CheatVertix);
  CheatEntries.AddCheat('DEVICE', CheatDevice);
  CheatEntries.AddCheat('ARTS', CheatArts);
  CheatEntries.AddCheat('MODULE', CheatModule);
  CheatEntries.AddCheat('SKILL', CheatSkill);
  CheatEntries.AddCheat('PROGRAM', CheatProgram);
  CheatEntries.AddCheat('ILLNESS', CheatIllness);
  CheatEntries.AddCheat('STIMULANT', CheatStimulant);
  CheatEntries.AddCheat('IDEAL', CheatIdeal);
  CheatEntries.AddCheat('SHOWMAP', CheatShowmap);
  CheatEntries.AddCheat('MEDAL', CheatMedal);
  CheatEntries.AddCheat('HORROR', CheatHorror);
  CheatEntries.AddCheat('NIGHTMARE', CheatNightmare);
  CheatEntries.AddCheat('HELL', CheatHell);
  CheatEntries.AddCheat('TECHNIC', CheatTechnic);
  CheatEntries.AddCheat('AMMO', CheatAmmo);
  CheatEntries.AddCheat('GOD', CheatGod);
  CheatEntries.AddCheat('HOLE', CheatHole);
  CheatEntries.AddCheat('WIN', CheatWin);
  CheatEntries.AddCheat('HWEAPON', CheatHweapon);
  CheatEntries.AddCheat('ULTRASCAN', CheatUltrascan);
  CheatEntries.AddCheat('TENTM', CheatTentm);
  CheatEntries.AddCheat('ENCHARGE', CheatEncharge);
  CheatEntries.AddCheat('EXPA', CheatExpa);
  CheatEntries.AddCheat('MADEINCHINA', CheatMadeinchina);
  CheatEntries.AddCheat('ZAWARUDO', CheatZawarudo);
  CheatEntries.AddCheat('FITNESS', CheatFitness);
  CheatEntries.AddCheat('EXTRAONE', CheatExtraone);
  CheatEntries.AddCheat('ROBOTFORCE', CheatRobotforce);
  CheatEntries.AddCheat('RANGERSDREAM', CheatRangersdream);
  CheatEntries.AddCheat('MAKEDUMP', CheatMakedump);
  CheatEntries.AddCheat('SEED', CheatSeed);
  CheatEntries.AddCheat('SUDO', CheatSudo);
  CheatEntries.AddCheat('EVENTS', CheatEvents);
  CheatEntries.AddCheat('INFOS', CheatInfos);
finalization
  CheatEntries.Destroy;
end.
