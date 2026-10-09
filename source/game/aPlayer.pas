unit aPlayer;

{$I GameOptions.inc}

interface

uses
  aConst,
  Achievements,
  Classes,
  EC_BlockPar,
  EC_Buf,
  EC_Struct,
  aGalaxy,
  aItem,
  aMyFunction,
  aPlanet,
  aRanger,
  aRuins,
  aShip,
  aGalaxyStruct;

type

  TJournalRecord = class;

  TPlayer = class;

  PointerToTStorageEntry = ^TStorageEntry;

  TPlanetBattleHistoryEntry = packed record
    MapId: Integer;
    Statistics: TPlanetBattleStatistics;
    ResultCode: Integer;
    CompletionMode: Integer;
    DateTurn: Integer;
  end;

  TStorageEntry = packed record
    LocationOwner: TObject;
    SlotIndex: Integer;
    Item: TItem;
  end;

  PStorageEntry = PointerToTStorageEntry;

  TEquipmentConfiguration = packed record
    EquipmentIds: array[0..11] of Integer;
    ArtefactIds: array[0..31] of Integer;
  end;

  TJournalRecord = class(TObjectEx)
    DateTurn: Integer;
    Text: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
  end;

  TStorageHeaderColumns = record
    Size: Integer;
    Cost: Integer;
  end;

  TStorageHeaderColumnTable = array[1..2] of TStorageHeaderColumns;

  TStorageDividerLengthTable = array[1..2] of Integer;

  TProbeSummaryColumns = record
    Heading: Integer;
    Size: Integer;
    Exploration: Integer;
    Condition: Integer;
    Status: Integer;
  end;

  TProbeSummaryColumnTable = array[1..2] of TProbeSummaryColumns;

  TStorageItemColumns = record
    Heading: Integer;
    Size: Integer;
    Cost: Integer;
  end;

  TStorageItemColumnTable = array[1..2] of TStorageItemColumns;

  TPlayer = class(TRanger)
    InPrison: Boolean;
    TalkLocked: Boolean;
    ScanLocked: Boolean;
    HyperspaceKillCount: Integer;
    BlackHoleKillCount: Integer;
    DominatorKillsByType: array[TKlingType] of Integer;
    ScriptShipBindings: TList;
    QuestTargetKillShip: TShip;
    QuestTargetDefendShip: TShip;
    QuestTargetDefendStar: TStar;
    StorageEntries: TList;
    DebtAmount: Integer;
    DebtDueTurn: Integer;
    DebtDefaultCount: Integer;
    DepositAmount: Integer;
    DepositStartTurn: Integer;
    DepositDayCount: Integer;
    DepositInterestRate: Single;
    MedicalPolicyTicks: Integer;
    PirateLicenseTicks: Integer;
    PirateLicenseCash: Integer;
    PendingPirateLicenseCash: Integer;
    QueuedTravelTarget: TStar;
    StationServiceLastUseTurns: array[TCoalitionProject] of Integer;
    StatusEffectSourceNames: array[TCaptainHealthEffect] of WideString;
    DiseaseImmunity: Byte;
    ProgramRewardStocks: array[TProgramIndex] of Integer;
    LastDominatorProgramRewardTurn: Integer;
    DestroyedDominatorHullMass: Integer;
    Satellites: TObjectList;
    PlanetBattleHistory: array of TPlanetBattleHistoryEntry;
    PlanetBattles: Integer;
    LastPlanetBattleTurn: Integer;
    DeclinePlanetBattleOffers: Boolean;
    DiseaseContractionCount: Word;
    StimulantPurchaseCount: Word;
    PrisonStaysCompleted: Word;
    SatelliteTilesExplored: Integer;
    NationalityChangeCount: Integer;
    SideChangeCount: Integer;
    SelectedEquipmentConfiguration: Integer;
    EquipmentConfigurations: array[0..9] of TEquipmentConfiguration;
    PiratePartners: TList;
    UnresolvedFlagsDA8: array[0..5] of Boolean;
    JournalRecords: TObjectList;
    NewsEntries: TList;
    PendingDockDialogue: Byte;
    NoJump: Boolean;
    PirateClanReal: Boolean;
    AchievementStats: TAchievementStats;
    ExperienceByDominators: Integer;
    ExperienceByPirates: Integer;
    ExperienceByNormals: Integer;
    ExperienceByTraderCareer: Integer;
    RuinsMode: Byte;
    RuinsProxy: TShip;
    RuinsSavedDockedTo: TShip;
    RuinsSavedPlanet: TPlanet;
    RuinsStatusText: WideString;
    AwardedAchievementKeys: TBlockParEC;
    BombKillsThisTurn: Integer;
    ChameleonLogic: array[TDominatorSeries] of Byte;
    procedure SaveToBuffer(Buffer: TBufEC); override;
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy); override;
    procedure ResolveLoadedReferences(Galaxy: TGalaxy); override;
    procedure SaveToBlock(Block: TBlockParEC); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure NextDay; override;
    function CalculateSpeed: Integer; override;
    procedure RefreshCurrentStanding; override;
    constructor Create;
    destructor Destroy; override;
    procedure InitializePlayerAtPlanet(
        Planet: TPlanet;
        InitialMoney: Integer;
        CharacterPreset: Integer
    );
    procedure ApplyCharacterPreset(
        Planet: TPlanet;
        InitialMoney: Integer;
        CharacterPreset: Integer
    );
    function ComputeDepositAccruedValue: Integer;
    procedure RechargeTransmitters;
    procedure ApplyBioArtefactHealthEffects;
    function MayTakeSubCrack: Boolean;
    function GetSubCrackCost: Integer;
    function GetPirateServiceDiscount: TPercent;
    function CountProgramRewardStocks: Integer;
    function TryAwardDominatorPrograms(Victim: TShip): Boolean;
    function FindProfitableTradeRoute(
        Nearby: Boolean;
        Seed: Cardinal;
        var PurchasePlanet: TPlanet;
        var SalePlanet: TPlanet;
        var Good: Byte;
        GoodsMask: TItemTypeMask
    ): Boolean;
    function HasDeployedSatellites: Boolean;
    function HasSatelliteOnPlanet(Planet: TPlanet): Boolean;
    function GetStorageColumnHeaderText: WideString;
    function GetStorageDividerText: WideString;
    function BuildDeployedSatelliteSummary(var LineCount: Integer): WideString;
    function GetSatelliteExplorationTurns(Satellite: TSatellite): Integer;
    function CanAccessSurfaceLootItem(Item: TItem): Boolean;
    procedure ReportIdleSatellites(Star: TStar);
    function CanAccessHoldGoods(Good: Byte): Boolean;
    function CanAccessStoredItem(Item: TItem): Boolean;
    function CountStoredItemUnits(Location: TObject; ItemType: TItemType): Integer;
    procedure RepairDuplicateStorageSlots(Location: TObject);
    function FindNextStorageSlot(Location: TObject): Integer;
    function GetStorageSlotExtent(Location: TObject): Integer;
    function FindStorageIndexByLocationAndSlot(Location: TObject; Slot: Integer): Integer;
    function FindStorageGoodsByLocationAndType(Location: TObject; Good: Byte): Integer;
    function FindMergeableStorageItemByLocation(Location: TObject; Item: TCountableItem): Integer;
    procedure ShiftStorageSlotsAtOrAfter(Location: TObject; Slot: Integer);
    procedure CloseVacantStorageSlot(Location: TObject; Slot: Integer);
    function HasAccessibleStorageAt(Location: TObject): Boolean;
    function CountPartnersInNormalSpace: Byte;
    function GetShipRatingComparison(Ship: TShip): Byte;
    function GetShipRankComparison(Ship: TShip): Byte;
    function GetShipPirateRankComparison(Ship: TShip): Byte;
    function GetShipStrengthComparison(Ship: TShip): Byte;
    function BuildTranclucatorStorageSummary(var LineCount: Integer): WideString;
    function CompareStorageEntries(Left: PStorageEntry; Right: PStorageEntry): Integer;
    procedure SortStorageEntries;
    procedure RefreshStorageBubbles;
    procedure BuildStorageBubbles;
    function SelectPlanetBattleMap: Integer;
    procedure SaveEquipmentConfiguration(Index: Integer);
    procedure ApplyEquipmentConfiguration(Index: Integer);
    function HasEquipmentConfiguration(Index: Integer): Boolean;
    function GetAvailableNodeCount(Carrier: TShip): Integer;
    procedure ConsumeAvailableNodes(Count: Integer; Carrier: TShip);
    function GetMaxPiratePartners: Integer;
    function GetMaxDominionShips: Integer;
    procedure AddJournalRecord(Text: WideString);
    procedure DeleteJournalRecord(Index: Integer);
    procedure ClearJournal;
    function ExportJournal: WideString;
    procedure SortNewsEntries;
    procedure TrimNewsEntries(KeepCount: Integer);
    function ExportNews: WideString;
    procedure MergeGalaxyNews;
    procedure RefreshNewsAtLocation;
    procedure CreateRuinsProxy;
    procedure EnterRuinsMode(Mode: Integer);
    procedure CloseRuinsModeScreen;
    procedure ExitRuinsMode;
    function CanSelectShipTarget(Ship: TShip): Boolean;
    function CanScanShip(Ship: TShip): Boolean;
  end;

var

  ArcadeKellerDefeats: Integer;

  ArcadeKellerReward: TObject;

  // This is an in-memory object address; the XOR key is the original DWORD.
  EncodedPlayer: PtrUInt = $B1CD15D3;

  StorageHeaderColumns: TStorageHeaderColumnTable =
      ((Size: 300; Cost: 380), (Size: 400; Cost: 490));

  StorageDividerLengths: TStorageDividerLengthTable = (76, 98);

  ProbeSummaryColumns: TProbeSummaryColumnTable = (
      (Heading: 190; Size: 160; Exploration: 220; Condition: 280; Status: 295),
      (Heading: 250; Size: 200; Exploration: 280; Condition: 370; Status: 390)
  );

  TranclucatorSummaryWidths: TStorageDividerLengthTable = (180, 240);

  StorageItemColumns: TStorageItemColumnTable =
      ((Heading: 190; Size: 300; Cost: 380), (Heading: 250; Size: 400; Cost: 490));

function GetPlayer: TPlayer;

procedure SetPlayer(Player: TPlayer; Galaxy: TGalaxy);

implementation

uses
  GI_MessageLoop,
  aNormalShip,
  SysUtils,
  GR_Main,
  EC_Str,
  Math,
  Globals,
  SimpleSteamApi,
  aScript,
  aKling,
  fEquipmentShop,
  GlobalsV,
  aTranclucator;

constructor TJournalRecord.Create;
begin
  inherited Create;
  DateTurn := 0;
  Text := '';
end;

destructor TJournalRecord.Destroy;
begin
  inherited Destroy;
end;

procedure TJournalRecord.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddIntegerValue(DateTurn);
  Buffer.AddWideStringZ(Text);
end;

procedure TJournalRecord.LoadFromBuffer(Buffer: TBufEC);
begin
  DateTurn := Buffer.GetInt32;
  Text := Buffer.ReadWideString;
end;

function GetPlayer: TPlayer;
begin
  Result := TPlayer(EncodedPlayer xor $B1CD15D3);
end;

procedure SetPlayer(Player: TPlayer; Galaxy: TGalaxy);
begin
  if Galaxy <> nil then
  begin
    EncodedPlayer := PtrUInt(Player) xor $B1CD15D3;
    if Player = nil then
      Galaxy.PlayerRangerIndex := -1
    else if Galaxy.Rangers = nil then
      Galaxy.PlayerRangerIndex := -1
    else
      Galaxy.PlayerRangerIndex := Galaxy.Rangers.IndexOf(Player);
  end;
end;

constructor TPlayer.Create;
var
  ServiceIndex: TCoalitionProject;
  I, J: Integer;
  RewardIndex: TProgramIndex;
  KillIndex: TKlingType;
  LogicIndex: TDominatorSeries;
begin
  inherited Create;
  StorageEntries := TList.Create;
  TalkLocked := False;
  ScanLocked := False;
  ScriptShipBindings := TList.Create;
  HyperspaceKillCount := 0;
  BlackHoleKillCount := 0;
  for KillIndex := Low(TKlingType) to High(TKlingType) do
    DominatorKillsByType[KillIndex] := 0;
  for LogicIndex := Low(TDominatorSeries) to High(TDominatorSeries) do
    ChameleonLogic[LogicIndex] := 0;
  DebtAmount := 0;
  DebtDueTurn := 0;
  DebtDefaultCount := 0;
  DepositAmount := 0;
  DepositStartTurn := 0;
  DepositDayCount := 0;
  DepositInterestRate := 0;
  // The native constructor really uses the current turn for this duration field.
  if Galaxy <> nil then
    MedicalPolicyTicks := Galaxy.CurrentTurn;
  PirateLicenseTicks := 0;
  PirateLicenseCash := 0;
  PendingPirateLicenseCash := 0;
  for ServiceIndex := Low(StationServiceLastUseTurns) to High(StationServiceLastUseTurns) do
    StationServiceLastUseTurns[ServiceIndex] := 150;
  for I := 1 to 24 do
    StatusEffectSourceNames[TCaptainHealthEffect(I)] := '';
  DiseaseImmunity := 50;
  for RewardIndex := Low(ProgramRewardStocks) to High(ProgramRewardStocks) do
    ProgramRewardStocks[RewardIndex] := 0;
  LastDominatorProgramRewardTurn := 0;
  DestroyedDominatorHullMass := 0;
  PlanetBattles := 0;
  LastPlanetBattleTurn := 0;
  DeclinePlanetBattleOffers := False;
  Satellites := TObjectList.Create;
  DiseaseContractionCount := 0;
  StimulantPurchaseCount := 0;
  PrisonStaysCompleted := 0;
  SatelliteTilesExplored := 0;
  NationalityChangeCount := 0;
  SideChangeCount := 0;
  ArcadeKellerDefeats := 0;
  ArcadeKellerReward := nil;
  SelectedEquipmentConfiguration := 0;
  for I := 0 to 9 do
  begin
    for J := 0 to 11 do
      EquipmentConfigurations[I].EquipmentIds[J] := 0;
    for J := 0 to 31 do
      EquipmentConfigurations[I].ArtefactIds[J] := 0;
  end;
  PiratePartners := TList.Create;
  for I := 0 to 5 do
    UnresolvedFlagsDA8[I] := True;
  JournalRecords := TObjectList.Create;
  NewsEntries := TList.Create;
  PirateClanReal := False;
  AchievementStats := TAchievementStats.Create;
  RuinsMode := 0;
  RuinsProxy := nil;
  RuinsSavedDockedTo := nil;
  RuinsSavedPlanet := nil;
  AwardedAchievementKeys := TBlockParEC.Create;
  QueuedTravelTarget := nil;
end;

destructor TPlayer.Destroy;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  if ScriptShipBindings <> nil then
  begin
    while ScriptShipBindings.Count > 0 do
      TScriptShip(ScriptShipBindings[0]).Script.UnbindShip(Self);
    ScriptShipBindings.Clear;
    ScriptShipBindings.Free;
    ScriptShipBindings := nil;
  end;
  if CurrentStar <> nil then
  begin
    I := CurrentStar.Ships.IndexOf(Self);
    if I >= 0 then
      CurrentStar.Ships.Delete(I);
  end;
  if StorageEntries <> nil then
  begin
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := PStorageEntry(StorageEntries[I]);
      if Entry <> nil then
      begin
        if Entry.Item <> nil then
        begin
          Entry.Item.Free;
          Entry.Item := nil;
        end;
        Dispose(Entry);
        StorageEntries[I] := nil;
      end;
    end;
    StorageEntries.Clear;
    StorageEntries.Free;
    StorageEntries := nil;
  end;
  if Satellites <> nil then
  begin
    Satellites.Free;
    Satellites := nil;
  end;
  if PiratePartners <> nil then
  begin
    PiratePartners.Free;
    PiratePartners := nil;
  end;
  if JournalRecords <> nil then
  begin
    JournalRecords.Free;
    JournalRecords := nil;
  end;
  TrimNewsEntries(0);
  NewsEntries.Clear;
  NewsEntries.Free;
  NewsEntries := nil;
  if RuinsProxy <> nil then
  begin
    RuinsProxy.Free;
    RuinsProxy := nil;
  end;
  AwardedAchievementKeys.Free;
  AwardedAchievementKeys := nil;
  inherited Destroy;
end;

procedure TPlayer.SaveToBuffer(Buffer: TBufEC);
var
  I, J, ConfigurationCount, SlotCount, ListCount, NewsCount: Integer;
  Entry: PStorageEntry;
  ServiceIndex: TCoalitionProject;
  RewardIndex: TProgramIndex;
  News: PPlanetNewsEntry;
  KillIndex: TKlingType;
  LogicIndex: TDominatorSeries;
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddBoolean(InPrison);
  Buffer.AddBoolean(TalkLocked);
  Buffer.AddBoolean(ScanLocked);
  Buffer.AddIntegerValue(HyperspaceKillCount);
  Buffer.AddIntegerValue(BlackHoleKillCount);
  for KillIndex := Low(TKlingType) to High(TKlingType) do
    Buffer.AddIntegerValue(DominatorKillsByType[KillIndex]);
  for LogicIndex := Low(TDominatorSeries) to High(TDominatorSeries) do
    Buffer.AddAnsiChar(AnsiChar(ChameleonLogic[LogicIndex]));
  Buffer.AddIntegerValue(StorageEntries.Count);
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := PStorageEntry(StorageEntries[I]);
    if Entry.LocationOwner is TPlanet then
    begin
      Buffer.AddAnsiChar(#0);
      Buffer.AddDWord((Entry.LocationOwner as TPlanet).Id);
    end
    else
    begin
      Buffer.AddAnsiChar(#1);
      Buffer.AddDWord((Entry.LocationOwner as TShip).Id);
    end;
    Buffer.AddIntegerValue(Entry.SlotIndex);
    Buffer.AddAnsiChar(AnsiChar(Entry.Item.ItemType));
    Entry.Item.SaveToBuffer(Buffer);
  end;
  Buffer.AddIntegerValue(DebtAmount);
  Buffer.AddIntegerValue(DebtDueTurn);
  Buffer.AddIntegerValue(DebtDefaultCount);
  Buffer.AddIntegerValue(DepositAmount);
  Buffer.AddIntegerValue(DepositStartTurn);
  Buffer.AddIntegerValue(DepositDayCount);
  Buffer.AddSingle(DepositInterestRate);
  Buffer.AddIntegerValue(MedicalPolicyTicks);
  Buffer.AddIntegerValue(PirateLicenseTicks);
  Buffer.AddIntegerValue(PirateLicenseCash);
  Buffer.AddIntegerValue(PendingPirateLicenseCash);
  if QueuedTravelTarget = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(QueuedTravelTarget.Id);
  for ServiceIndex := Low(StationServiceLastUseTurns) to High(StationServiceLastUseTurns) do
    Buffer.AddIntegerValue(StationServiceLastUseTurns[ServiceIndex]);
  for I := 1 to 24 do
    Buffer.AddWideStringZ(StatusEffectSourceNames[TCaptainHealthEffect(I)]);
  Buffer.AddAnsiChar(AnsiChar(DiseaseImmunity));
  for RewardIndex := Low(ProgramRewardStocks) to High(ProgramRewardStocks) do
    Buffer.AddIntegerValue(ProgramRewardStocks[RewardIndex]);
  Buffer.AddIntegerValue(LastDominatorProgramRewardTurn);
  Buffer.AddIntegerValue(DestroyedDominatorHullMass);
  Buffer.AddIntegerValue(Satellites.Count);
  for I := 0 to Satellites.Count - 1 do
    TSatellite(Satellites[I]).SaveToBuffer(Buffer);
  Buffer.AddIntegerValue(High(PlanetBattleHistory) + 1);
  for I := 0 to High(PlanetBattleHistory) do
  begin
    Buffer.AddIntegerValue(PlanetBattleHistory[I].MapId);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.SignedTimeMs);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.RobotsBuilt);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.RobotsDestroyed);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.TurretsBuilt);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.TurretsDestroyed);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].Statistics.BuildingsDestroyed);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].ResultCode);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].CompletionMode);
    Buffer.AddIntegerValue(PlanetBattleHistory[I].DateTurn);
  end;
  Buffer.AddIntegerValue(PlanetBattles);
  Buffer.AddIntegerValue(LastPlanetBattleTurn);
  Buffer.AddBoolean(DeclinePlanetBattleOffers);
  Buffer.AddWideChar(WideChar(DiseaseContractionCount));
  Buffer.AddWideChar(WideChar(StimulantPurchaseCount));
  Buffer.AddWideChar(WideChar(PrisonStaysCompleted));
  Buffer.AddIntegerValue(SatelliteTilesExplored);
  Buffer.AddWideChar(WideChar(NationalityChangeCount));
  Buffer.AddWideChar(WideChar(SideChangeCount));
  Buffer.AddAnsiChar(AnsiChar(SelectedEquipmentConfiguration));
  ConfigurationCount := 10;
  Buffer.AddAnsiChar(AnsiChar(ConfigurationCount));
  for I := 0 to ConfigurationCount - 1 do
  begin
    SlotCount := 12;
    Buffer.AddWideChar(WideChar(SlotCount));
    for J := 0 to SlotCount - 1 do
      Buffer.AddDWord(EquipmentConfigurations[I].EquipmentIds[J]);
    SlotCount := 32;
    Buffer.AddWideChar(WideChar(SlotCount));
    for J := 0 to SlotCount - 1 do
      Buffer.AddDWord(EquipmentConfigurations[I].ArtefactIds[J]);
  end;
  Buffer.AddAnsiChar(AnsiChar(PiratePartners.Count));
  for I := 0 to PiratePartners.Count - 1 do
    Buffer.AddDWord(TShip(PiratePartners[I]).Id);
  ListCount := 6;
  Buffer.AddAnsiChar(AnsiChar(ListCount));
  for I := 0 to ListCount - 1 do
    Buffer.AddBoolean(UnresolvedFlagsDA8[I]);
  ListCount := JournalRecords.Count;
  Buffer.AddDWord(JournalRecords.Count);
  for I := 0 to ListCount - 1 do
    TJournalRecord(JournalRecords[I]).SaveToBuffer(Buffer);
  NewsCount := NewsEntries.Count;
  Buffer.AddWideChar(WideChar(NewsCount));
  for I := 0 to NewsCount - 1 do
  begin
    News := PPlanetNewsEntry(NewsEntries[I]);
    Buffer.AddDWord(News.Id);
    Buffer.AddDWord(News.Turn);
    Buffer.AddAnsiChar(AnsiChar(News.NewsType));
    Buffer.AddWideStringZ(News.Text);
  end;
  Buffer.AddAnsiChar(AnsiChar(PendingDockDialogue));
  Buffer.AddBoolean(NoJump);
  Buffer.AddBoolean(PirateClanReal);
  AchievementStats.SaveToBuffer(Buffer);
  Buffer.AddIntegerValue(ExperienceByDominators);
  Buffer.AddIntegerValue(ExperienceByPirates);
  Buffer.AddIntegerValue(ExperienceByNormals);
  Buffer.AddIntegerValue(ExperienceByTraderCareer);
  Buffer.AddAnsiChar(AnsiChar(RuinsMode));
  if RuinsProxy = nil then
    CreateRuinsProxy;
  (RuinsProxy as TRuins).SaveToBuffer(Buffer);
  if RuinsMode > 0 then
  begin
    if RuinsSavedDockedTo = nil then
      Buffer.AddDWord(0)
    else
      Buffer.AddDWord(RuinsSavedDockedTo.Id);
    if RuinsSavedPlanet = nil then
      Buffer.AddDWord(0)
    else
      Buffer.AddDWord(RuinsSavedPlanet.Id);
  end;
  Buffer.AddWideStringZ(RuinsStatusText);
  Buffer.AddIntegerValue(AwardedAchievementKeys.GetBlockCount);
  for I := 0 to AwardedAchievementKeys.GetBlockCount - 1 do
    Buffer.AddWideStringZ(AwardedAchievementKeys.GetBlockNameByIndex(I));
end;

procedure TPlayer.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
var
  I, Count, J, ConfigurationCount, SlotCount, PartnerCount: Integer;
  Entry: PStorageEntry;
  ServiceIndex: TCoalitionProject;
  RewardIndex: TProgramIndex;
  Satellite: TSatellite;
  Journal: TJournalRecord;
  News: PPlanetNewsEntry;
  AchievementIndex: Integer;
  Data: PAchievementData;
  KillIndex: TKlingType;
  LogicIndex: TDominatorSeries;
begin
  inherited LoadFromBuffer(Buffer, Galaxy);
  if LoadedSaveVersion <= 164 then
    ClearRecentlyDroppedItems;
  InPrison := Buffer.GetBoolean;
  TalkLocked := Buffer.GetBoolean;
  ScanLocked := Buffer.GetBoolean;
  HyperspaceKillCount := Buffer.GetInt32;
  BlackHoleKillCount := Buffer.GetInt32;
  if LoadedSaveVersion >= 89 then
    for KillIndex := Low(TKlingType) to High(TKlingType) do
      DominatorKillsByType[KillIndex] := Buffer.GetInt32
  else if LoadedSaveVersion >= 74 then
  begin
    for KillIndex := ktBoss to ktShtip do
      DominatorKillsByType[KillIndex] := Buffer.GetInt32;
    DominatorKillsByType[ktBertor] := 0;
    DominatorKillsByType[ktKlig] := 0;
  end
  else
    for KillIndex := Low(TKlingType) to High(TKlingType) do
      DominatorKillsByType[KillIndex] := 0;
  if LoadedSaveVersion >= 155 then
    for LogicIndex := Low(TDominatorSeries) to High(TDominatorSeries) do
      ChameleonLogic[LogicIndex] := Buffer.GetByte;
  Count := Buffer.GetInt32;
  if (Count < 0) or (Count > MaxSavedListCount) then
    raise EAbort.Create('Err');
  for I := 0 to Count - 1 do
  begin
    New(Entry);
    if Buffer.GetByte = 0 then
      Entry.LocationOwner := TObject(Buffer.GetUInt32 or StoredItemPlanetFlag)
    else
      Entry.LocationOwner := TObject(Buffer.GetUInt32);
    Entry.SlotIndex := Buffer.GetInt32;
    Entry.Item := CreateItemByType(MigrateSavedItemType(Buffer.GetByte));
    StorageEntries.Add(Entry);
    Entry.Item.LoadFromBuffer(Buffer, Galaxy);
  end;
  DebtAmount := Buffer.GetInt32;
  DebtDueTurn := Buffer.GetInt32;
  DebtDefaultCount := Buffer.GetInt32;
  DepositAmount := Buffer.GetInt32;
  DepositStartTurn := Buffer.GetInt32;
  DepositDayCount := Buffer.GetInt32;
  DepositInterestRate := Buffer.GetSingle;
  MedicalPolicyTicks := Buffer.GetInt32;
  if LoadedSaveVersion >= 103 then
  begin
    PirateLicenseTicks := Buffer.GetInt32;
    PirateLicenseCash := Buffer.GetInt32;
    PendingPirateLicenseCash := Buffer.GetInt32;
  end
  else
  begin
    PirateLicenseTicks := 0;
    PirateLicenseCash := 0;
    PendingPirateLicenseCash := 0;
  end;
  if LoadedSaveVersion >= 108 then
    QueuedTravelTarget := TStar(Buffer.GetUInt32)
  else
    QueuedTravelTarget := nil;
  for ServiceIndex := Low(StationServiceLastUseTurns) to High(StationServiceLastUseTurns) do
    StationServiceLastUseTurns[ServiceIndex] := Buffer.GetInt32;
  for I := 1 to 24 do
    StatusEffectSourceNames[TCaptainHealthEffect(I)] := Buffer.ReadWideString;
  DiseaseImmunity := Buffer.GetByte;
  if LoadedSaveVersion < 49 then
  begin
    ProgramRewardStocks[prgKellerCall] := 0;
    for RewardIndex := prgLogicalNegation to High(ProgramRewardStocks) do
      ProgramRewardStocks[RewardIndex] := Buffer.GetInt32;
  end
  else
    for RewardIndex := Low(ProgramRewardStocks) to High(ProgramRewardStocks) do
      ProgramRewardStocks[RewardIndex] := Buffer.GetInt32;
  LastDominatorProgramRewardTurn := Buffer.GetInt32;
  DestroyedDominatorHullMass := Buffer.GetInt32;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Satellite := TSatellite.Create;
    Satellites.Add(Satellite);
    Satellite.LoadFromBuffer(Buffer, Galaxy);
  end;
  Count := Buffer.GetInt32;
  SetLength(PlanetBattleHistory, Count);
  for I := 0 to Count - 1 do
  begin
    PlanetBattleHistory[I].MapId := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.SignedTimeMs := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.RobotsBuilt := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.RobotsDestroyed := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.TurretsBuilt := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.TurretsDestroyed := Buffer.GetInt32;
    PlanetBattleHistory[I].Statistics.BuildingsDestroyed := Buffer.GetInt32;
    PlanetBattleHistory[I].ResultCode := Buffer.GetInt32;
    PlanetBattleHistory[I].CompletionMode := Buffer.GetInt32;
    PlanetBattleHistory[I].DateTurn := Buffer.GetInt32;
  end;
  PlanetBattles := Buffer.GetInt32;
  LastPlanetBattleTurn := Buffer.GetInt32;
  if LoadedSaveVersion >= 59 then
    DeclinePlanetBattleOffers := Buffer.GetBoolean
  else
    DeclinePlanetBattleOffers := False;
  DiseaseContractionCount := Buffer.GetWord;
  StimulantPurchaseCount := Buffer.GetWord;
  PrisonStaysCompleted := Buffer.GetWord;
  SatelliteTilesExplored := Buffer.GetInt32;
  NationalityChangeCount := Buffer.GetWord;
  SideChangeCount := Buffer.GetWord;
  SelectedEquipmentConfiguration := 0;
  SelectedEquipmentConfiguration := Buffer.GetByte;
  ConfigurationCount := Buffer.GetByte;
  for I := 0 to ConfigurationCount - 1 do
  begin
    SlotCount := Buffer.GetWord;
    for J := 0 to SlotCount - 1 do
      EquipmentConfigurations[I].EquipmentIds[J] := Buffer.GetUInt32;
    SlotCount := Buffer.GetWord;
    for J := 0 to SlotCount - 1 do
      EquipmentConfigurations[I].ArtefactIds[J] := Buffer.GetUInt32;
  end;
  PartnerCount := Buffer.GetByte;
  for I := 0 to PartnerCount - 1 do
    PiratePartners.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetByte;
  for I := 0 to Count - 1 do
    UnresolvedFlagsDA8[I] := Buffer.GetBoolean;
  Count := Buffer.GetUInt32;
  if (Count < 0) or (Count > MaxSavedListCount) then
    raise EAbort.Create('Err');
  for I := 0 to Count - 1 do
  begin
    Journal := TJournalRecord.Create;
    JournalRecords.Add(Journal);
    Journal.LoadFromBuffer(Buffer);
  end;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > MaxSavedListCount) then
    raise EAbort.Create('Err');
  for I := 0 to Count - 1 do
  begin
    New(News);
    NewsEntries.Add(News);
    News.Id := Buffer.GetUInt32;
    News.Turn := Buffer.GetUInt32;
    News.NewsType := TGalaxyNewsKind(Buffer.GetByte);
    News.Text := Buffer.ReadWideString;
  end;
  PendingDockDialogue := Buffer.GetByte;
  NoJump := Buffer.GetBoolean;
  PirateClanReal := Buffer.GetBoolean;
  AchievementStats.LoadFromBuffer(Buffer);
  ExperienceByDominators := Buffer.GetInt32;
  ExperienceByPirates := Buffer.GetInt32;
  if LoadedSaveVersion >= 57 then
    ExperienceByNormals := Buffer.GetInt32;
  ExperienceByTraderCareer := Buffer.GetInt32;
  if LoadedSaveVersion >= 51 then
  begin
    RuinsMode := Buffer.GetByte;
    RuinsProxy := TRuins.Create;
    (RuinsProxy as TRuins).LoadFromBuffer(Buffer, Galaxy);
  end
  else
  begin
    RuinsMode := 0;
    RuinsProxy := nil;
  end;
  if RuinsMode > 0 then
  begin
    RuinsSavedDockedTo := TShip(Buffer.GetUInt32);
    RuinsSavedPlanet := TPlanet(Buffer.GetUInt32);
  end
  else
  begin
    RuinsSavedDockedTo := nil;
    RuinsSavedPlanet := nil;
  end;
  if LoadedSaveVersion >= 114 then
    RuinsStatusText := Buffer.ReadWideString
  else
    RuinsStatusText := '';
  if LoadedSaveVersion >= 120 then
  begin
    Count := Buffer.GetInt32;
    for I := 0 to Count - 1 do
      AwardedAchievementKeys.AddChildBlock(Buffer.ReadWideString);
  end
  else if LoadedSaveVersion >= 99 then
  begin
    for AchievementIndex := 0 to 82 do
      if Buffer.GetBoolean then
        AwardedAchievementKeys
            .AddChildBlock(WideString(AchievementDefinitionTable[AchievementIndex].Key));
  end
  else if LoadedSaveVersion >= 55 then
  begin
    for AchievementIndex := 0 to 61 do
      if Buffer.GetBoolean then
        AwardedAchievementKeys
            .AddChildBlock(WideString(AchievementDefinitionTable[AchievementIndex].Key));
  end;
  if GetAvailableAchievementCount > 0 then
  begin
    for AchievementIndex := 1 to 82 do
    begin
      Data := GetAchievementData(WideString(AchievementDefinitionTable[AchievementIndex].Key));
      if Data <> nil then
      begin
        if Data.Achieved then
          if AwardedAchievementKeys.CountBlocks(
                  WideString(AchievementDefinitionTable[AchievementIndex].Key))
              <= 0 then
            AwardedAchievementKeys
                .AddChildBlock(WideString(AchievementDefinitionTable[AchievementIndex].Key));
        if not Data.Achieved then
          if AwardedAchievementKeys.CountBlocks(
                  WideString(AchievementDefinitionTable[AchievementIndex].Key))
              > 0 then
            AwardedAchievementKeys
                .DeleteChildBlock(WideString(AchievementDefinitionTable[AchievementIndex].Key));
        FreeAchievementData(Data);
      end;
    end;
  end;
  LastLoadedPlayerName := Name;
  RefreshPlayerQuestTargets;
end;

procedure TPlayer.ResolveLoadedReferences(Galaxy: TGalaxy);
var
  I: Integer;
  Found: Boolean;
  Item: TItem;
  Entry: PStorageEntry;
begin
  inherited ResolveLoadedReferences(Galaxy);
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := PStorageEntry(StorageEntries[I]);
    if Cardinal(Entry.LocationOwner) and StoredItemPlanetFlag <> 0 then
      Entry.LocationOwner := Galaxy.IdToPlanet(Cardinal(Entry.LocationOwner) and TaggedObjectIdMask)
    else
      Entry.LocationOwner := Galaxy.IdToShip(Cardinal(Entry.LocationOwner), True);
    Entry.Item.ResolveLoadedReferences(Galaxy);
  end;
  for I := 0 to Satellites.Count - 1 do
    TSatellite(Satellites[I]).ResolveLoadedReferences(Galaxy);
  I := 0;
  while PiratePartners.Count > I do
  begin
    PiratePartners[I] := Galaxy.IdToShip(Cardinal(PiratePartners[I]), False);
    if PiratePartners[I] <> nil then
      Inc(I)
    else
      PiratePartners.Delete(I);
  end;
  if QueuedTravelTarget <> nil then
    QueuedTravelTarget := Galaxy.IdToStar(Cardinal(QueuedTravelTarget));
  if RuinsMode > 0 then
    RuinsProxy.CurrentStar := CurrentStar;
  if RuinsSavedPlanet <> nil then
    RuinsSavedPlanet := TObject(Galaxy.IdToPlanet(Cardinal(RuinsSavedPlanet))) as TPlanet;
  if RuinsSavedDockedTo <> nil then
    RuinsSavedDockedTo := TObject(Galaxy.IdToShip(Cardinal(RuinsSavedDockedTo), True)) as TShip;
  if (LoadedSaveVersion < 146) and (CurrentPlanet = nil) and (DockedTo = nil) then
  begin
    Found := False;
    for I := 1 to Inventory.Count - 1 do
    begin
      Item := TItem(Inventory[I]);
      if (Item is TEngine) and (TEngine(Item).TechLevel <= 7) then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      if GetEngine <> nil then
        UnequipItem(GetEngine);
      CreateAndEquipEngine(EngineBaseSize, 3, OwnerId);
    end;
    Found := False;
    for I := 1 to Inventory.Count - 1 do
    begin
      Item := TItem(Inventory[I]);
      if (Item is TFuelTanks) and (TFuelTanks(Item).TechLevel <= 7) then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      if GetFuelTanks <> nil then
        UnequipItem(GetFuelTanks);
      CreateAndEquipFuelTanks(FuelTanksBaseSize, 3, OwnerId);
    end;
  end;
end;

procedure TPlayer.SaveToBlock(Block: TBlockParEC);
var
  I: TProgramIndex;
begin
  Block.AddParam(
      DecodeTextW('InChukriSotoanriIndo'),
      WideString(IntToStr(CurrentStar.Id))
  ); // 'ICurStarId'
  inherited SaveToBlock(Block);
  Block.AddParam(DecodeTextW('D5eyb7tn'), WideString(IntToStr(DebtAmount))); // 'Debt'
  Block.AddParam(DecodeTextW('DDe3bgt5Dha6t7ej'), WideString(IntToStr(DebtDueTurn))); // 'DebtDate'
  Block
      .AddParam(DecodeTextW('Dbe5bht6C7njt8'), WideString(IntToStr(DebtDefaultCount))); // 'DebtCnt'
  Block.AddParam(DecodeTextW('D0ehp7ojsgi4td'), WideString(IntToStr(DepositAmount))); // 'Deposit'
  Block.AddParam(
      DecodeTextW('Dbe5p7ojsriet4Dga6t7ek'),
      WideString(IntToStr(DepositStartTurn))
  ); // 'DepositDate'
  Block.AddParam(
      DecodeTextW('D0ebp5o3sfi3t5Dha7y8'),
      WideString(IntToStr(DepositDayCount))
  ); // 'DepositDay'
  Block.AddParam(
      DecodeTextW('Dpeupto5seiwtfPye6rucieon9t'),
      WideString(FloatToStr(DepositInterestRate))
  ); // 'DepositPercent'
  Block.AddParam(
      DecodeTextW('Mmejd6Ptoel4i6c7yi'),
      WideString(IntToStr(MedicalPolicyTicks))
  ); // 'MedPolicy'
  for I := Low(ProgramCounts) to High(ProgramCounts) do
    Block.AddParam(ProgramNames[I], WideString(IntToStr(ProgramCounts[I])));
  Block.AddParam(
      DecodeTextW('Emxjp7D8o5m'),
      WideString(IntToStr(ExperienceByDominators))
  ); // 'ExpDom'
  Block.AddParam(DecodeTextW('E3xrp5P6i7r'), WideString(IntToStr(ExperienceByPirates))); // 'ExpPir'
  Block
      .AddParam(DecodeTextW('Emx8p7C4oga6'), WideString(IntToStr(ExperienceByNormals))); // 'ExpCoa'
  Block.AddParam(
      DecodeTextW('Ekx7peTwr3af'),
      WideString(IntToStr(ExperienceByTraderCareer))
  ); // 'ExpTra'
end;

procedure TPlayer.LoadFromBlock(Block: TBlockParEC);
var
  I: TProgramIndex;
begin
  inherited LoadFromBlock(Block);
  DebtAmount := StrToInt(AnsiString(Block.GetParam(DecodeTextW('D5eyb7tn')))); // 'Debt'
  DebtDueTurn :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('DDe3bgt5Dha6t7ej')))); // 'DebtDate'
  DebtDefaultCount :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Dbe5bht6C7njt8')))); // 'DebtCnt'
  DepositAmount := StrToInt(AnsiString(Block.GetParam(DecodeTextW('D0ehp7ojsgi4td')))); // 'Deposit'
  DepositStartTurn :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Dbe5p7ojsriet4Dga6t7ek')))); // 'DepositDate'
  DepositDayCount :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('D0ebp5o3sfi3t5Dha7y8')))); // 'DepositDay'
  DepositInterestRate :=
      ExtractDecimalToSingleW(
          Block.GetParam(DecodeTextW('Dpeupto5seiwtfPye6rucieon9t'))
      ); // 'DepositPercent'
  MedicalPolicyTicks :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Mmejd6Ptoel4i6c7yi')))); // 'MedPolicy'
  for I := Low(ProgramCounts) to High(ProgramCounts) do
    ProgramCounts[I] := StrToInt(AnsiString(Block.GetParam(ProgramNames[I])));
  ExperienceByDominators :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Emxjp7D8o5m')))); // 'ExpDom'
  ExperienceByPirates :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('E3xrp5P6i7r')))); // 'ExpPir'
  ExperienceByNormals :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Emx8p7C4oga6')))); // 'ExpCoa'
  ExperienceByTraderCareer :=
      StrToInt(AnsiString(Block.GetParam(DecodeTextW('Ekx7peTwr3af')))); // 'ExpTra'
end;

procedure TPlayer.InitializePlayerAtPlanet(Planet: TPlanet; InitialMoney, CharacterPreset: Integer);
begin
  inherited InitializeAtPlanet(Planet, InitialMoney);
  BaseNodes :=
      RoundAndTruncateToTens(
          BaseNodes * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].ArcadeRewardScale
      );
  PreferredCareer := rcTrader;
  CareerStatus[rcTrader] := 0;
  CareerStatus[rcWarrior] := 0;
  CareerStatus[rcPirate] := 0;
  EminentProgress[rcTrader] := 0;
  EminentProgress[rcPirate] := 0;
  EminentProgress[rcWarrior] := 0;
  BaseSkills[psAccuracy] := 0;
  BaseSkills[psManeuverability] := 0;
  BaseSkills[psTechnical] := 0;
  BaseSkills[psTrading] := 0;
  BaseSkills[psCharisma] := 0;
  BaseSkills[psLeadership] := 0;
end;

procedure TPlayer.ApplyCharacterPreset(Planet: TPlanet; InitialMoney, CharacterPreset: Integer);
var
  I, Quantity: Integer;
  Kind: TItemType;
  Item: TObject;
  Entry: PStorageEntry;
begin
  for I := Inventory.Count - 1 downto 0 do
  begin
    Item := TObject(Inventory[I]);
    Inventory.Delete(I);
    Item.Free;
  end;
  for Kind := Low(PShipEquipmentCacheView(@Hull).Slots)
      to High(PShipEquipmentCacheView(@Hull).Slots) do
    PShipEquipmentCacheView(@Hull).Slots[Kind] := nil;
  for I := 1 to 5 do
    Weapons[I] := nil;
  WeaponCount := 0;
  case Ord(OwnerId) * 5 + CharacterPreset of
    1:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 20, [oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 2, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[1]),
          3,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
    end;
    2:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.5, 0.9) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 1, [oiFeyan, oiGaal]);
      ChangePlanetRelations(nil, rcmIncrease, 40, [oiPeleng, oiHuman]);
      CreateAndEquipHull(NextRandomIntRange(240, 270, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[1]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
          3,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_Flux,
          Round(WeaponInfos[t_Flux].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
    end;
    3:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.2, 1.4) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiHuman, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(290, 320, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      GetFuelTanks.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetEngine.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[1]), 1, OwnerId);
      GetRadar.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      GetCargoHook.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipWeapon(
                  t_IndustrialLaser,
                  Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
                  1,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(20, 80, RandomState);
    end;
    4:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.1) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(230, 250, RandomState), 2, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_Flux,
          Round(WeaponInfos[t_Flux].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
    end;
    5:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.9, 2.1) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiPeleng, oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(210, 230, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[4]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 3, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
    end;
    6:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 2.3, 2.5) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 25, [oiMaloc, oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(210, 230, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[4]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 3, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
    end;
    7:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.4, 2.0) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 30, [oiMaloc, oiHuman, oiFeyan, oiGaal]);
      ChangePlanetRelations(nil, rcmCapAt, 60, [oiPeleng]);
      CreateAndEquipHull(NextRandomIntRange(230, 260, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
    end;
    8:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.1) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 50, [oiPeleng, oiHuman, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(280, 320, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      GetFuelTanks.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetEngine.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      GetRadar.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      GetCargoHook.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipWeapon(
                  t_FragmentationCannon,
                  Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
                  3,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(20, 80, RandomState);
    end;
    9:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.9, 2.0) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 30, [oiHuman, oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(7, 17, RandomState);
      (Entry.Item as TGoods).Init(t_Luxury, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Luxury)].AveragePrice div 4);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    10:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.1) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiHuman]);
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiFeyan]);
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      GetFuelTanks.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetEngine.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      GetRadar.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      GetCargoHook.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipWeapon(
                  t_MissileLauncher,
                  Round(WeaponInfos[t_MissileLauncher].AverageSize * EquipmentSizeFactors[3]),
                  1,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(60, 90, RandomState);
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(4, 10, RandomState);
      (Entry.Item as TGoods).Init(t_Narcotics, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Narcotics)].AveragePrice div 2);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    11:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.3, 0.5) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 15, [oiPeleng]);
      CreateAndEquipHull(NextRandomIntRange(210, 230, RandomState), 2, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipDefGenerator(Round(DefGeneratorBaseSize * EquipmentSizeFactors[2]), 3, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
          2,
          OwnerId
      );
    end;
    12:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.5, 2.0) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 90, [oiMaloc, oiPeleng]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 2, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      GetFuelTanks.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetEngine.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[1]), 1, OwnerId);
      GetRadar.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetCargoHook.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipWeapon(
                  t_IndustrialLaser,
                  Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
                  1,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(20, 80, RandomState);
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(100, 200, RandomState);
      (Entry.Item as TGoods).Init(t_Minerals, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Minerals)].AveragePrice div 2);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    13:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.3, 1.5) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 25, [oiMaloc]);
      ChangePlanetRelations(nil, rcmIncrease, 30, [oiPeleng, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(280, 310, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipScanner(Round(ScannerBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
    end;
    14:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.1, 1.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiPeleng, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(240, 260, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[3]), 3, OwnerId);
      CreateAndEquipScanner(Round(ScannerBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[4]),
          2,
          OwnerId
      );
    end;
    15:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiMaloc]);
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiFeyan]);
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(10, 35, RandomState), [oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[4]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          3,
          OwnerId
      );
    end;
    16:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiHuman, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(250, 270, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          3,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_Flux,
          Round(WeaponInfos[t_Flux].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
    end;
    17:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 70, [oiMaloc, oiPeleng]);
      CreateAndEquipHull(NextRandomIntRange(230, 250, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[3]), 2, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_MissileLauncher,
          Round(WeaponInfos[t_MissileLauncher].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
    end;
    18:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiPeleng, oiHuman, oiFeyan, oiGaal]);
      ChangePlanetRelations(nil, rcmCapAt, 25, [oiMaloc]);
      CreateAndEquipHull(NextRandomIntRange(290, 320, RandomState), 1, OwnerId, -1, False)
              .HullPoints :=
          NextRandomIntRange(50, 150, RandomState);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[1]), 1, OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipWeapon(
                  t_IndustrialLaser,
                  Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[4]),
                  1,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
    end;
    19:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 15, [oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(270, 290, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 2, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[2]),
          3,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_Flux,
          Round(WeaponInfos[t_Flux].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
    end;
    20:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiMaloc, oiHuman, oiGaal]);
      ChangePlanetRelations(nil, rcmCapAt, 90, [oiPeleng]);
      ChangePlanetRelations(nil, rcmCapAt, 60, [oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(230, 250, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
          1,
          OwnerId
      );
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(14, 20, RandomState);
      (Entry.Item as TGoods).Init(t_Narcotics, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Narcotics)].AveragePrice div 2);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    21:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.2, 0.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiHuman, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(230, 250, RandomState), 2, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 2, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          3,
          OwnerId
      );
      CreateAndEquipWeapon(
          t_FragmentationCannon,
          Round(WeaponInfos[t_FragmentationCannon].AverageSize * EquipmentSizeFactors[3]),
          2,
          OwnerId
      );
    end;
    22:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 1.2, 1.3) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmRaiseTo, 60, [oiMaloc, oiPeleng, oiHuman, oiFeyan, oiGaal]);
      CreateAndEquipHull(NextRandomIntRange(220, 230, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipScanner(Round(ScannerBaseSize * EquipmentSizeFactors[4]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
    end;
    23:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.2) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiMaloc]);
      CreateAndEquipHull(NextRandomIntRange(280, 310, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipScanner(Round(ScannerBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
          1,
          OwnerId
      );
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(15, 30, RandomState);
      (Entry.Item as TGoods).Init(t_Luxury, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Luxury)].AveragePrice div 2);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    24:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.2) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 35, [oiMaloc, oiPeleng, oiHuman, oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(250, 260, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 1, OwnerId);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipScanner(Round(ScannerBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[3]), 2, OwnerId);
      CreateAndEquipRepairRobot(Round(RepairRobotBaseSize * EquipmentSizeFactors[3]), 2, OwnerId);
      CreateAndEquipWeapon(
          t_IndustrialLaser,
          Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[3]),
          1,
          OwnerId
      );
      New(Entry);
      GetPlayer.StorageEntries.Add(Entry);
      Entry.Item := TGoods.Create;
      Quantity := NextRandomIntRange(10, 20, RandomState);
      (Entry.Item as TGoods).Init(t_Alcohol, Quantity);
      Entry.Item.Cost := Quantity * (GoodsMarket[Ord(t_Alcohol)].AveragePrice div 2);
      if GetPlayer.DockedTo <> nil then
        Entry.LocationOwner := GetPlayer.DockedTo
      else
        Entry.LocationOwner := GetPlayer.CurrentPlanet;
      Entry.SlotIndex := 0;
    end;
    25:
    begin
      SetMoney(
          RoundAndTruncateToTens(
              SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.2) * InitialMoney
          )
      );
      ChangePlanetRelations(nil, rcmCapAt, 15, [oiMaloc, oiPeleng, oiFeyan]);
      CreateAndEquipHull(NextRandomIntRange(280, 300, RandomState), 1, OwnerId, -1, False);
      CreateAndEquipFuelTanks(Round(FuelTanksBaseSize * EquipmentSizeFactors[3]), 1, OwnerId);
      GetFuelTanks.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipEngine(Round(EngineBaseSize * EquipmentSizeFactors[1]), 2, OwnerId);
      GetEngine.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipRadar(Round(RadarBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetRadar.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipCargoHook(Round(CargoHookBaseSize * EquipmentSizeFactors[2]), 1, OwnerId);
      GetCargoHook.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipWeapon(
                  t_IndustrialLaser,
                  Round(WeaponInfos[t_IndustrialLaser].AverageSize * EquipmentSizeFactors[2]),
                  1,
                  OwnerId)
              .ConditionPercent :=
          NextRandomIntRange(10, 50, RandomState);
    end;
  end;
  GetHull.Weight :=
      RoundAndTruncateToTens(
          GetHull.Weight
              * HullCapacityScale
              / GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].QuestTimeAndExperienceFactor
      );
  RefreshDerivedStats(True);
  while CargoFreeSpace
      < 15.0 / GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].GoodsEventDurationFactor do
  begin
    Inc(GetHull.Weight, 5);
    RefreshDerivedStats(True);
  end;
  case Galaxy.DifficultyLevels[7] of
    0: Inc(GetHull.Weight, 30);
    1: Inc(GetHull.Weight, 10);
    2: Inc(GetHull.Weight, 5);
  end;
  GetHull.HullPoints := GetHull.Weight;
  RefreshDerivedStats(True);
  RefreshGraphicSize;
  RefreshAssignedItemSlots;
  HomePlanet.ChangeRelationToRanger(GetPlayer, 100);
  for I := 1 to 24 do
    StatusEffectSourceNames[TCaptainHealthEffect(I)] := '';
end;

procedure TPlayer.NextDay;
var
  I, J, LastDisease, FirstDisease, TargetValue: Integer;
  LocationId: Cardinal;
  Found: Integer;
  Ship: TShip;
  Star: TStar;
  Item: TEquipment;
  Text: WideString;
  ResistanceFactor: Single;
  Binding: TScriptShip;
  LocalSeed: Cardinal;
  StimulantExcess, Stage: Integer;
begin
  Stage := 0;
  try
    if (Galaxy.CurrentTurn <= LastProcessedTurn) and (Galaxy.StasisModEnabled <> 1) then
      Exit;
    begin
      inherited NextDay;
      Stage := 1;
      if ScriptShipBindings <> nil then
      begin
        I := ScriptShipBindings.Count - 1;
        while I >= 0 do
        begin
          if ScriptShipBindings.Count <= I then
            I := ScriptShipBindings.Count - 1
          else
          begin
            Binding := TScriptShip(ScriptShipBindings[I]);
            if Binding.Script <> nil then
              Binding.Script.RunShipState(Binding);
            Dec(I);
          end;
        end;
      end;
      Stage := 2;
      if (Galaxy.CurrentTurn
                  mod (((Integer(Galaxy.GenerationSeed) + Galaxy.CurrentTurn) div 1000) mod 10 + 2)
              = 0)
          and (DiseaseImmunity > 0) then
        Dec(DiseaseImmunity);
      { Native O- code retains this unreachable lower clamp on the byte field. }
      if DiseaseImmunity < 0 then
        DiseaseImmunity := 0;
      if DiseaseImmunity > 100 then
        DiseaseImmunity := 100;
      if not InNormalSpace then
        AchievementStats.StarFuelCollected := 0;
      if MedicalPolicyTicks > 0 then
      begin
        Dec(MedicalPolicyTicks);
        LastMedicalPolicyTicks := MedicalPolicyTicks;
        if MedicalPolicyTicks = 0 then
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              PickLocalizedTextVariant('GalaxyNews.MedPolicy.End', Galaxy.CurrentTurn div 10),
              ''
          );
      end;
      if PendingPirateLicenseCash > 0 then
      begin
        GainExperience(
            Round(PendingPirateLicenseCash * CareerStatus[rcPirate] * 0.001),
            esNormalShips
        );
        Inc(PirateLicenseCash, PendingPirateLicenseCash);
        PendingPirateLicenseCash := 0;
        if PirateLicenseCash > MaxMonetaryValue then
          PirateLicenseCash := MaxMonetaryValue;
      end;
      if PirateLicenseTicks > 0 then
      begin
        Dec(PirateLicenseTicks);
        if PirateLicenseTicks = 0 then
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              PickLocalizedTextVariant('GalaxyNews.PirateLicense.End', Galaxy.CurrentTurn div 10),
              ''
          )
        else if Galaxy.ShipTypeCounts[rstDominion] <= 0 then
        begin
          Found := 0;
          for I := 0 to Galaxy.Stars.Count - 1 do
          begin
            Star := TStar(Galaxy.Stars[I]);
            for J := 0 to Star.Ships.Count - 1 do
              if TShip(Star.Ships[J]).TypeId = rstDominion then
              begin
                Inc(Found);
                Break;
              end;
            if Found > 0 then
              Break;
          end;
          if Found = 0 then
          begin
            PirateLicenseTicks := 0;
            AddOrUpdatePlayerBubble(
                pmGalaxyNews,
                Galaxy.CurrentTurn,
                PickLocalizedTextVariant(
                    'GalaxyNews.PirateLicense.DeadAllCB',
                    Galaxy.CurrentTurn div 10
                ),
                ''
            );
          end;
        end;
      end;
      if (PirateLicenseCash > 0) and (PirateLicenseTicks <= 0) then
      begin
        if PirateLicenseCash <= 1000 then
          PirateLicenseCash := 0
        else if PirateLicenseCash <= 20000 then
          Dec(PirateLicenseCash, 1000)
        else
          PirateLicenseCash := Round(PirateLicenseCash * 0.95);
      end;
      if Money < 0 then
        SetMoney(0)
      else if Money > MaxMonetaryValue then
        SetMoney(MaxMonetaryValue);
      Stage := 3;
      if InNormalSpace then
        for I := 0 to CurrentStar.Ships.Count - 1 do
        begin
          Ship := TShip(CurrentStar.Ships[I]);
          if Ship.InNormalSpace then
            Ship.DaysSincePlayerSeen := 0;
        end;
      Stage := 4;
      for I := 0 to Inventory.Count - 1 do
      begin
        Item := TEquipment(Inventory[I]);
        if (Item.ItemType = t_Engine) and (Item.EquippedFlag = 0) then
        begin
          if (Item as TEngine).OutputPercent + 10 > 100 then
            (Item as TEngine).OutputPercent := 100
          else
            Inc((Item as TEngine).OutputPercent, 10);
        end;
      end;
      Stage := 5;
      RechargeTransmitters;
      ApplyBioArtefactHealthEffects;
      RefreshNewsAtLocation;
      Stage := 6;
      if (CountActiveDiseases < 3)
          and (((CurrentPlanet <> nil) and not HasDiseaseFromCurrentPlanet)
              or ((DockedTo <> nil) and not HasDiseaseFromCurrentDockedShip)
              or InNormalSpace) then
      begin
        FirstDisease := 1;
        LastDisease := 12;
        I := NextRandomIntRange(FirstDisease, LastDisease, RandomState);
        for J := FirstDisease to LastDisease do
        begin
          IncrementWrapped(I, FirstDisease, LastDisease);
          with CaptainHealthDefinitions[TCaptainHealthEffect(I)] do
          begin
            if (Galaxy.CurrentTurn < GalaxyWarmupTurns)
                or CaptainHealthDefinitions[TCaptainHealthEffect(I)].Disabled then
              Continue;
            if (CurrentPlanet <> nil)
                and not (hlPlanet
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations) then
              Continue;
            if (DockedTo <> nil)
                and not (hlDocked
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations) then
              Continue;
            if InNormalSpace
                and not (hlNormalSpace
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations)
                and not (hlCombat
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations) then
              Continue;
            if InNormalSpace
                and (hlCombat in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations) then
              if (EnemyShip = nil)
                  or not EnemyShip.IsAttackingShip(Self)
                  or (GetHullIntegrityPercent > 50)
                  or ((TCaptainHealthEffect(I) = heHolyFanaticism)
                      and (EnemyShip.OwnerId <> oiDominator)) then
                Continue;
            if (CurrentPlanet <> nil)
                and not (CurrentPlanet.OwnerId
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedLocationOwners) then
              if (CurrentPlanet.OwnerId = oiUninhabited)
                  or not (RaceToOwner(CurrentPlanet.RaceId)
                      in CaptainHealthDefinitions[TCaptainHealthEffect(I)]
                          .AllowedLocationOwners) then
                Continue;
            if (DockedTo <> nil)
                and not (RaceToOwner(DockedTo.PilotRace)
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedLocationOwners)
                and not (DockedTo.OwnerId
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedLocationOwners) then
              Continue;
            if (RaceToOwner(PilotRace) in AllowedOwners)
                and (GetRangerRatingBand in AllowedRatingBands)
                and (Rank in AllowedRanks)
                and (GetDominantCareer in AllowedCareers)
                and (CaptainHealth[TCaptainHealthEffect(I)].Progress <= 0.0)
                and (CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn + TurnsPerYear
                    <= Galaxy.CurrentTurn) then
            begin
              if IsHealthEffectActive(heComplexImmunocide) then
                ResistanceFactor := 0.1
              else
                ResistanceFactor := 1.0;
              if IsHealthEffectActive(heBloodDjogar) then
                ResistanceFactor := ResistanceFactor * 5.0;
              ResistanceFactor := (CountActiveArtefacts(t_ArtBio) + 1) * ResistanceFactor;
              if CurrentPlanet <> nil then
                LocationId := CurrentPlanet.Id
              else if DockedTo <> nil then
                LocationId := DockedTo.Id
              else
                LocationId := CurrentStar.Id;
              LocalSeed :=
                  Galaxy.GenerationSeed
                      + Cardinal(I)
                      + LocationId
                      + Cardinal(Galaxy.CurrentTurn div 3);
              if NextRandomFloatRange(0.0, 1.0, LocalSeed)
                      * RemapClamped(DiseaseImmunity, 0.0, 100.0, 50.0, 300.0)
                      * ResistanceFactor
                  <= InfectionChance
                      * 2.0
                      * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]]
                          .GoodsEventDurationFactor then
              begin
                CaptainHealth[TCaptainHealthEffect(I)].Progress := 0.1;
                if InNormalSpace
                    and (hlCombat
                        in CaptainHealthDefinitions[TCaptainHealthEffect(I)].Locations) then
                  CaptainHealth[TCaptainHealthEffect(I)].Progress := 99.9999;
                CaptainHealth[TCaptainHealthEffect(I)].AppliedTurn := Galaxy.CurrentTurn;
                CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn :=
                    Galaxy.CurrentTurn
                        + Round(
                            RemapClamped(
                                    SeededRandomUnitFloat(
                                        Integer(Galaxy.GenerationSeed) + I + Galaxy.CurrentTurn
                                    ),
                                    0.0,
                                    1.0,
                                    0.5,
                                    3.0)
                                * CaptainHealthDefinitions[TCaptainHealthEffect(I)].Duration);
                if CurrentPlanet <> nil then
                  StatusEffectSourceNames[TCaptainHealthEffect(I)] := CurrentPlanet.GetFullName(' ')
                else if DockedTo <> nil then
                  StatusEffectSourceNames[TCaptainHealthEffect(I)] := DockedTo.GetName
                else
                  StatusEffectSourceNames[TCaptainHealthEffect(I)] := CurrentStar.Name;
              end;
            end;
          end;
        end;
      end;
      Stage := 7;
      for I := 1 to 12 do
        if CaptainHealth[TCaptainHealthEffect(I)].Progress <> 0.0 then
        begin
          if CaptainHealth[TCaptainHealthEffect(I)].Progress < 100.0 then
          begin
            if I in [1..3] then
            begin
              if (CurrentPlanet <> nil) or (DockedTo <> nil) then
                CaptainHealth[TCaptainHealthEffect(I)].Progress := 100.0;
            end
            else
              CaptainHealth[TCaptainHealthEffect(I)].Progress :=
                  SeededRandomUnitFloat(Integer(Galaxy.GenerationSeed) - I + Galaxy.CurrentTurn)
                          * CaptainHealthDefinitions[TCaptainHealthEffect(I)].DevelopmentRate
                          * 2.0
                      + CaptainHealth[TCaptainHealthEffect(I)].Progress
                      + 0.01;
            if CaptainHealth[TCaptainHealthEffect(I)].Progress >= 100.0 then
            begin
              CaptainHealth[TCaptainHealthEffect(I)].Progress := 100.0;
              Inc(CaptainHealth[TCaptainHealthEffect(I)].ApplicationCount);
              CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn :=
                  Galaxy.CurrentTurn
                      + Round(
                          RemapClamped(
                                  SeededRandomUnitFloat(
                                      Integer(Galaxy.GenerationSeed) + I + Galaxy.CurrentTurn
                                  ),
                                  0.0,
                                  1.0,
                                  0.9,
                                  2.0)
                              * CaptainHealthDefinitions[TCaptainHealthEffect(I)].Duration);
              Text :=
                  LocalizedColorText(WideString('Illness.Illness.' + IntToStr(I - 1) + '.Start'));
              AddOrUpdatePlayerBubble(
                  pmGalaxyNews,
                  Galaxy.CurrentTurn,
                  FormatText2(
                      Text,
                      TextHighlightColorTag,
                      '<Date>',
                      Galaxy.FormatTurnDate(-1),
                      '<Name>',
                      CaptainHealthDefinitions[TCaptainHealthEffect(I)].Name
                  ),
                  ''
              );
              AchievementStats.CheckAllDiseasesAchievement;
              Inc(DiseaseContractionCount);
            end;
          end
          else if (CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn <= Galaxy.CurrentTurn)
              and (not (I in [1..3]) or not CurrentStar.RecordingTurnFilm) then
          begin
            CaptainHealth[TCaptainHealthEffect(I)].Progress := 0.0;
            StatusEffectSourceNames[TCaptainHealthEffect(I)] := '';
            Text := LocalizedColorText(WideString('Illness.Illness.' + IntToStr(I - 1) + '.End'));
            AddOrUpdatePlayerBubble(
                pmGalaxyNews,
                Galaxy.CurrentTurn,
                FormatText2(
                    Text,
                    TextHighlightColorTag,
                    '<Date>',
                    Galaxy.FormatTurnDate(-1),
                    '<Name>',
                    CaptainHealthDefinitions[TCaptainHealthEffect(I)].Name
                ),
                ''
            );
          end;
        end;
      Stage := 8;
      for I := 13 to 24 do
        if (CaptainHealth[TCaptainHealthEffect(I)].Progress = 100.0)
            and (CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn <= Galaxy.CurrentTurn) then
        begin
          Text :=
              LocalizedColorText(WideString('Illness.Stimulant.' + IntToStr(I - 12 - 1) + '.End'));
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              FormatText1(Text, TextHighlightColorTag, '<Date>', Galaxy.FormatTurnDate(-1)),
              ''
          );
          CaptainHealth[TCaptainHealthEffect(I)].Progress := 0.0;
        end;
      Stage := 9;
      for I := 1 to 1 do
        if (RadiationHealth[I].Progress <> 0.0)
            and (RadiationHealth[I].ExpireTurn <= Galaxy.CurrentTurn) then
        begin
          Text := LocalizedColorText(WideString('Illness.ExtraIllness.' + IntToStr(I) + '.End'));
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              FormatText1(Text, TextHighlightColorTag, '<Date>', Galaxy.FormatTurnDate(-1)),
              ''
          );
          RadiationHealth[I].Progress := 0.0;
        end;
      Stage := 10;
      StimulantExcess := CountActiveStimulants - GetPlayer.GetTotalStatBonus(bonStimCapacity);
      { The native one-pass loop retains its dormant footer after Break. }
      while StimulantExcess >= 2 do
      begin
        I := 6;
        if CaptainHealth[TCaptainHealthEffect(I)].Progress <= 0.0 then
        begin
          LocalSeed := Galaxy.GenerationSeed + Cardinal(Galaxy.CurrentTurn);
          if Sqr(Max(0, StimulantExcess - CountActiveArtefacts(t_ArtBio))) * 0.4
              > NextRandomFloatRange(0.0, 1000.0, LocalSeed) then
            if (RaceToOwner(PilotRace)
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedOwners)
                and (GetRangerRatingBand
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedRatingBands)
                and (Rank in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedRanks)
                and (GetDominantCareer
                    in CaptainHealthDefinitions[TCaptainHealthEffect(I)].AllowedCareers) then
            begin
              CaptainHealth[TCaptainHealthEffect(I)].Progress := 100.0;
              CaptainHealth[TCaptainHealthEffect(I)].ExpireTurn :=
                  Galaxy.CurrentTurn
                      + Round(
                          RemapClamped(
                                  SeededRandomUnitFloat(
                                      Integer(Galaxy.GenerationSeed) + I + Galaxy.CurrentTurn
                                  ),
                                  0.0,
                                  1.0,
                                  0.5,
                                  3.0)
                              * CaptainHealthDefinitions[TCaptainHealthEffect(I)].Duration);
              Inc(CaptainHealth[TCaptainHealthEffect(I)].ApplicationCount);
              Text :=
                  LocalizedColorText(WideString('Illness.Illness.' + IntToStr(I - 1) + '.Start'));
              AddOrUpdatePlayerBubble(
                  pmGalaxyNews,
                  Galaxy.CurrentTurn,
                  FormatText2(
                      Text,
                      TextHighlightColorTag,
                      '<Date>',
                      Galaxy.FormatTurnDate(-1),
                      '<Name>',
                      CaptainHealthDefinitions[TCaptainHealthEffect(I)].Name
                  ),
                  ''
              );
              Inc(DiseaseContractionCount);
              AchievementStats.CheckAllDiseasesAchievement;
            end;
        end;
        Break;
      end;
      Stage := 11;
      if IsHealthEffectActive(heMysteriousLuatanza)
          and (Galaxy.CurrentTurn > CaptainHealth[heMysteriousLuatanza].AppliedTurn + 15)
          and (Galaxy.CurrentTurn mod 14 = 0) then
      begin
        if SeededRandomUnitFloat(Integer(Galaxy.GenerationSeed) + 1736605 + Galaxy.CurrentTurn)
            > 0.8 then
        begin
          TargetValue :=
              NextRandomIntRange(
                  Galaxy.ComputeScaledSmallMoney(oiHuman),
                  Galaxy.ComputeScaledAverageMoney(oiHuman),
                  RandomState
              );
          SetMoney(TargetValue + Money);
          SoundManager.PlaySound('Sound.Sell');
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              FormatText2(
                  PickLocalizedTextVariant(
                      'GalaxyNews.IllNews.IllLuatan',
                      Seed * Cardinal(Galaxy.CurrentTurn div 10)
                  ),
                  TextHighlightColorTag,
                  '<Date>',
                  Galaxy.FormatTurnDate(-1),
                  '<Money>',
                  WideString(IntToStr(TargetValue))
              ),
              ''
          );
        end
        else
          AddOrUpdatePlayerBubble(
              pmGalaxyNews,
              Galaxy.CurrentTurn,
              FormatText1(
                  PickLocalizedTextVariant(
                      'GalaxyNews.IllNews.IllLuatanNo',
                      Seed * Cardinal(Galaxy.CurrentTurn div 10)
                  ),
                  TextHighlightColorTag,
                  '<Date>',
                  Galaxy.FormatTurnDate(-1)
              ),
              ''
          );
      end;
      Stage := 12;
      if IsHealthEffectActive(heAkaSezyanka)
          and InNormalSpace
          and HasCargoGoods
          and (SeededRandomUnitFloat(Integer(Galaxy.GenerationSeed) + 135432 + Galaxy.CurrentTurn)
              > 0.8)
          and (Galaxy.CurrentTurn mod 21 = 0) then
      begin
        TargetValue :=
            NextRandomIntRange(
                Galaxy.ComputeScaledMiniMoney(oiHuman),
                Galaxy.ComputeScaledBigMoney(oiHuman),
                RandomState
            );
        JettisonCargoGoodsTowardTargetValue(TargetValue);
        SoundManager.PlaySound('Sound.Sell');
        AddOrUpdatePlayerBubble(
            pmGalaxyNews,
            Galaxy.CurrentTurn,
            FormatText1(
                PickLocalizedTextVariant(
                    'GalaxyNews.IllNews.IllSeciyanka',
                    Seed * Cardinal(Galaxy.CurrentTurn div 10)
                ),
                TextHighlightColorTag,
                '<Date>',
                Galaxy.FormatTurnDate(-1)
            ),
            ''
        );
      end;
      Stage := 13;
      RefreshDerivedStats(True);
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create('Error in procedure TPlayer.NextDay, label = ' + IntToStr(Stage));
    end;
  end;
end;

function TPlayer.ComputeDepositAccruedValue: Integer;
var
  Base, Exponent, LimitRatio: Extended;
begin
  Result := 0;
  if DepositAmount > 0 then
  begin
    Base := 0.01 * DepositInterestRate / 12 + 1;
    Exponent := DepositDayCount / TurnsPerYear * 12;
    LimitRatio := MaxMonetaryValue / DepositAmount;
    if Ln(Base) * Exponent > Ln(LimitRatio) then
      Result := MaxMonetaryValue
    else
      Result := Round(Power(Base, Exponent) * DepositAmount);
  end;
end;

procedure TPlayer.RechargeTransmitters;
var
  Item: TItem;
  Transmitter: TArtefactTransmitter;
  I: Integer;
begin
  for I := 0 to GetPlayer.Artefacts.Count - 1 do
  begin
    Item := TItem(GetPlayer.Artefacts[I]);
    if Item.ItemType = t_ArtefactTransmitter then
    begin
      Transmitter := Item as TArtefactTransmitter;
      Inc(Transmitter.Power);
    end;
  end;
end;

procedure TPlayer.ApplyBioArtefactHealthEffects;
var
  Selected: Integer;
  I: TCaptainHealthEffect;
  Count, J: Integer;
begin
  for J := 1 to CountActiveArtefacts(t_ArtBio) do
  begin
    if HasActiveDisease and (NextRandomIntRange(1, 100, RandomState) <= 20) then
    begin
      Selected := NextRandomIntRange(1, CountActiveDiseases, RandomState);
      Count := 0;
      for I := Low(TCaptainDisease) to High(TCaptainDisease) do
        if CaptainHealth[I].Progress = 100.0 then
        begin
          Inc(Count);
          if Count = Selected then
          begin
            Dec(CaptainHealth[I].ExpireTurn);
            Break;
          end;
        end;
    end;
    if HasActiveStimulant and (NextRandomIntRange(1, 100, RandomState) <= 50) then
    begin
      Selected := NextRandomIntRange(1, CountActiveStimulants, RandomState);
      Count := 0;
      for I := Low(TCaptainStimulant) to High(TCaptainStimulant) do
        if CaptainHealth[I].Progress = 100.0 then
        begin
          Inc(Count);
          if Count = Selected then
          begin
            Inc(CaptainHealth[I].ExpireTurn);
            Break;
          end;
        end;
    end;
  end;
end;

function TPlayer.MayTakeSubCrack: Boolean;
begin
  Result :=
      Galaxy.IsDominatorSeriesUnresolved(dsTerron)
          and (Galaxy.CurrentTurn > 2000)
          and ((Galaxy.CurrentTurn mod (Galaxy.CurrentTurn mod 11 + 20) = 0)
              or (Galaxy.CurrentTurn > 4000))
          and not HasProgram(prgSabCrack);
end;

function TPlayer.GetSubCrackCost: Integer;
begin
  Result := Round(100000.0 / GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].QuestMoneyFactor);
end;

function TPlayer.GetPirateServiceDiscount: TPercent;
begin
  Result := Round(CareerStatus[rcPirate] / 1.3) + 1;
end;

function TPlayer.CountProgramRewardStocks: Integer;
var
  I: TProgramIndex;
begin
  Result := 0;
  for I := Low(ProgramRewardStocks) to High(ProgramRewardStocks) do
    Inc(Result, ProgramRewardStocks[I]);
end;

function TPlayer.TryAwardDominatorPrograms(Victim: TShip): Boolean;
var
  ProgramIndex: TProgramIndex;
  Count: Integer;
begin
  Inc(DestroyedDominatorHullMass, Victim.GetHull.Weight);
  if ((Victim as TKling).KlingType in [ktEquantor..ktSmersh, ktBertor])
      and (DestroyedDominatorHullMass
          > Galaxy.ScaleIntByTechLevel(500, 3000)
              * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].GoodsEventDurationFactor)
      and (Galaxy.CurrentTurn
          > TurnsPerYear
                  * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].GoodsEventDurationFactor
              + LastDominatorProgramRewardTurn) then
  begin
    LastDominatorProgramRewardTurn := Galaxy.CurrentTurn;
    DestroyedDominatorHullMass := 0;
    ProgramIndex := SelectProgramReward;
    Count := GetProgramRewardCount(ProgramIndex);
    Inc(ProgramRewardStocks[ProgramIndex], Count);
    if Galaxy.CoalitionDefeatedTurn = 0 then
      AddOrUpdatePlayerBubble(
          pmGalaxyNews,
          Galaxy.CurrentTurn,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.WB.NewProgramm',
                  Seed * Cardinal(Galaxy.CurrentTurn div 10)
              ),
              TextHighlightColorTag,
              '<Count>',
              IntToStr(Count),
              '<Programm>',
              GetProgramName(ProgramIndex)
          ),
          ''
      );
    Result := True;
  end
  else
    Result := False;
end;

function TPlayer.FindProfitableTradeRoute(
    Nearby: Boolean;
    Seed: Cardinal;
    var PurchasePlanet, SalePlanet: TPlanet;
    var Good: Byte;
    GoodsMask: TItemTypeMask
): Boolean;
var
  I, J, JumpRange: Integer;
  UnusedRouteLocal1, UnusedRouteLocal2, UnusedRouteLocal3: Integer;
  BuyPlanet, SellPlanet, BestBuyPlanet, BestSellPlanet: TPlanet;
  UnusedGoodsLocal1, UnusedGoodsLocal2: Integer;
  BestGood, Kind: Byte;
  Score, BestScore: Single;
begin
  if GetEngine <> nil then
    JumpRange := Max(Galaxy.ScaleIntByTechLevel(8, 20), GetEngine.JumpRange)
  else
    JumpRange := Galaxy.ScaleIntByTechLevel(8, 30);
  Score := 0;
  BestScore := Score;
  BestBuyPlanet := nil;
  BestSellPlanet := nil;
  BestGood := 0;
  for I := 0 to Galaxy.Planets.Count - 1 do
  begin
    BuyPlanet := Galaxy.Planets[I];
    if not BuyPlanet.CurrentStar.IsConstellationVisible then
      Continue;
    if not (BuyPlanet.OwnerId in PlanetOwnerMasks.Coalition) then
      Continue;
    for J := 0 to Galaxy.Planets.Count - 1 do
    begin
      SellPlanet := Galaxy.Planets[J];
      if not SellPlanet.CurrentStar.IsConstellationVisible then
        Continue;
      if not (SellPlanet.OwnerId in PlanetOwnerMasks.Coalition) then
        Continue;
      if (PurchasePlanet = BuyPlanet) or (SalePlanet = SellPlanet) or (SellPlanet = BuyPlanet) then
        Continue;
      if Nearby then
      begin
        if PointDistance(CurrentStar.Position, BuyPlanet.CurrentStar.Position)
            > Min(JumpRange, 20) then
          Continue;
        if PointDistance(CurrentStar.Position, SellPlanet.CurrentStar.Position)
            > Min(2 * JumpRange, 40) then
          Continue;
      end
      else
      begin
        Score :=
            PointDistance(CurrentStar.Position, BuyPlanet.CurrentStar.Position)
                + PointDistance(BuyPlanet.CurrentStar.Position, SellPlanet.CurrentStar.Position);
        if (Score < 40)
            or (PointDistance(CurrentStar.Position, BuyPlanet.CurrentStar.Position) < 20)
            or (PointDistance(CurrentStar.Position, SellPlanet.CurrentStar.Position) < 30) then
          Continue;
        if (Score < 70)
            and (PointDistance(CurrentStar.Position, BuyPlanet.CurrentStar.Position)
                < Min(30, JumpRange))
            and (PointDistance(BuyPlanet.CurrentStar.Position, SellPlanet.CurrentStar.Position)
                < Min(30, JumpRange)) then
          Continue;
      end;
      for Kind := 0 to 7 do
        if Kind in GoodsMask then
          if GoodsLegalOnPlanet[Kind, BuyPlanet.RaceId, BuyPlanet.Government] then
            if GoodsLegalOnPlanet[Kind, SellPlanet.RaceId, SellPlanet.Government] then
              if (BuyPlanet.RelationToShip(Self) >= 20)
                  and (SellPlanet.RelationToShip(Self) >= 20)
                  and (SeededRandomUnitFloat(
                          Kind * Seed * BuyPlanet.GenerationSeed + SellPlanet.GenerationSeed)
                      >= 0.2) then
              begin
                Score :=
                    ShopGoodsSellPrice(Kind, SellPlanet) / ShopGoodsPurchasePrice(Kind, BuyPlanet);
                if Score >= 1.11 then
                  if (ShopGoodsSellPrice(Kind, SellPlanet) - 5
                          >= ShopGoodsPurchasePrice(Kind, BuyPlanet))
                      and (GoodsMarket[Kind].BaseStock div 3 <= BuyPlanet.Goods[Kind].Count) then
                  begin
                    Score :=
                        Score
                            * RemapClamped(
                                BuyPlanet.Goods[Kind].Count,
                                GoodsMarket[Kind].BaseStock div 3,
                                GoodsMarket[Kind].BaseStock * 1.1,
                                0.7,
                                1.5);
                    Score :=
                        Score
                            * RemapClamped(
                                PointDistance(CurrentStar.Position, BuyPlanet.CurrentStar.Position)
                                    / JumpRange,
                                0,
                                2,
                                1.3,
                                1);
                    Score :=
                        Score
                            * RemapClamped(
                                PointDistance(
                                        BuyPlanet.CurrentStar.Position,
                                        SellPlanet.CurrentStar.Position)
                                    / JumpRange,
                                0,
                                3,
                                1.3,
                                1);
                    Score :=
                        Score
                            * SeededRandomFloatRange(
                                Kind * BuyPlanet.GenerationSeed * SellPlanet.GenerationSeed
                                    + Seed * J,
                                1,
                                2.1);
                    if Score > BestScore then
                    begin
                      BestScore := Score;
                      BestBuyPlanet := BuyPlanet;
                      BestSellPlanet := SellPlanet;
                      BestGood := Kind;
                    end;
                  end;
              end;
    end;
  end;
  if BestScore > 0 then
  begin
    PurchasePlanet := BestBuyPlanet;
    SalePlanet := BestSellPlanet;
    Good := BestGood;
    Result := True;
  end
  else
    Result := False;
end;

function TPlayer.HasDeployedSatellites: Boolean;
var
  I: Integer;
  Satellite: TSatellite;
begin
  for I := 0 to Satellites.Count - 1 do
  begin
    Satellite := TSatellite(GetPlayer.Satellites[I]);
    if Satellite.TargetPlanet <> nil then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TPlayer.HasSatelliteOnPlanet(Planet: TPlanet): Boolean;
var
  I: Integer;
  Satellite: TSatellite;
begin
  for I := 0 to Satellites.Count - 1 do
  begin
    Satellite := GetPlayer.Satellites[I];
    if Satellite.TargetPlanet = Planet then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TPlayer.GetStorageColumnHeaderText: WideString;
var
  Text: WideString;
begin
  Text := TextHighlightColorTag;
  Text :=
      Text
          + '<td='
          + IntToStr(StorageHeaderColumns[GiResourceVariant].Size)
          + '><align=right>'
          + LocalizedText('FormShip.StorageInfo.Size')
          + '</align>';
  Text :=
      Text
          + '<td='
          + IntToStr(StorageHeaderColumns[GiResourceVariant].Cost)
          + '><align=right>'
          + LocalizedText('FormShip.StorageInfo.Cost')
          + '</align>';
  Text := Text + EndColorTag;
  Result := Text;
end;

function TPlayer.GetStorageDividerText: WideString;
begin
  Result :=
      WrapTextInColor(StringOfChar('-', StorageDividerLengths[GiResourceVariant]), GrayColorTag);
end;

function TPlayer.BuildDeployedSatelliteSummary(var LineCount: Integer): WideString;
var
  I, J, HeaderCount, Condition, ExplorationTurns: Integer;
  Satellite: TSatellite;
  Text, RemainingText, SizeText, ExplorationText, ConditionText, StatusText, TempText, Divider:
      WideString;
  Planet: TPlanet;
begin
  Divider := GetStorageDividerText;
  Text := '';
  LineCount := 0;
  for I := 0 to Galaxy.Planets.Count - 1 do
  begin
    HeaderCount := 0;
    Planet := TPlanet(Galaxy.Planets[I]);
    for J := 0 to Satellites.Count - 1 do
    begin
      Satellite := TSatellite(GetPlayer.Satellites[J]);
      if Satellite.TargetPlanet = Planet then
      begin
        if HeaderCount = 0 then
        begin
          TempText :=
              FormatText1(
                  LocalizedText('FormShip.StorageInfo.Star'),
                  '',
                  '<Star>',
                  (TObject(Satellite.TargetPlanet) as TPlanet).CurrentStar.Name
              );
          TempText :=
              WrapTextInColor(TempText + '. ', TextHighlightColorTag)
                  + WrapTextInColor(
                      (TObject(Satellite.TargetPlanet) as TPlanet).GetFullName(' ') + '.',
                      TextHighlightColorTag);
          RemainingText := ' ' + LocalizedText('FormShip.StorageInfo.PlanetNO');
          if Planet.WaterTiles - Planet.WaterExplored > 0 then
            ReplaceTextToken(
                RemainingText,
                '<Water>',
                IntToStr(Planet.WaterTiles - Planet.WaterExplored),
                AzureColorTag
            )
          else
            ReplaceTextToken(RemainingText, '<Water>', '-', GrayColorTag);
          if Planet.LandTiles - Planet.LandExplored > 0 then
            ReplaceTextToken(
                RemainingText,
                '<Land>',
                IntToStr(Planet.LandTiles - Planet.LandExplored),
                GreenColorTag
            )
          else
            ReplaceTextToken(RemainingText, '<Land>', '-', GrayColorTag);
          if Planet.HillTiles - Planet.HillExplored > 0 then
            ReplaceTextToken(
                RemainingText,
                '<Hill>',
                IntToStr(Planet.HillTiles - Planet.HillExplored),
                GoldColorTag
            )
          else
            ReplaceTextToken(RemainingText, '<Hill>', '-', GrayColorTag);
          TempText := TempText + RemainingText;
          Text :=
              Text
                  + #13#10
                  + Divider
                  + #13#10
                  + '<td='
                  + IntToStr(ProbeSummaryColumns[GiResourceVariant].Heading)
                  + '><align=center>'
                  + TempText
                  + '</align>'
                  + #13#10
                  + Divider
                  + #13#10;
          Inc(HeaderCount);
          Inc(LineCount);
        end;
        SizeText := WrapTextInColor(IntToStr(Satellite.Weight), GreenColorTag);
        TempText := '';
        if Satellite.WaterExplorationRate > 0 then
          TempText :=
              TempText + WrapTextInColor(IntToStr(Satellite.WaterExplorationRate), AzureColorTag)
        else
          TempText := TempText + WrapTextInColor('-', GrayColorTag);
        TempText := TempText + '/';
        if Satellite.LandExplorationRate > 0 then
          TempText :=
              TempText + WrapTextInColor(IntToStr(Satellite.LandExplorationRate), GreenColorTag)
        else
          TempText := TempText + WrapTextInColor('-', GrayColorTag);
        TempText := TempText + '/';
        if Satellite.HillExplorationRate > 0 then
          TempText :=
              TempText + WrapTextInColor(IntToStr(Satellite.HillExplorationRate), GoldColorTag)
        else
          TempText := TempText + WrapTextInColor('-', GrayColorTag);
        ExplorationText := TempText;
        Condition := Trunc(Satellite.ConditionPercent);
        if Satellite.ConditionPercent > 0 then
          TempText :=
              IntToStr(Condition)
                  + '.'
                  + IntToStr(Trunc(Satellite.ConditionPercent * 10) mod 10)
                  + '%'
        else
          TempText := '0.0%';
        if Condition > 75 then
          TempText := WrapTextInColor(TempText, GreenColorTag)
        else if Condition > 50 then
          TempText := WrapTextInColor(TempText, TextHighlightColorTag)
        else if Condition > 25 then
          TempText := WrapTextInColor(TempText, GoldColorTag)
        else
          TempText := WrapTextInColor(TempText, RedColorTag);
        ConditionText := TempText;
        StatusText := '';
        ExplorationTurns := GetSatelliteExplorationTurns(Satellite);
        if ExplorationTurns = 0 then
          StatusText :=
              ' ' + WrapTextInColor(LocalizedText('Items.Satellite.WorkEnd'), RedColorTag);
        Text := Text + '- ' + Satellite.GetDisplayName;
        Text :=
            Text
                + '<td='
                + IntToStr(ProbeSummaryColumns[GiResourceVariant].Size)
                + '><align=right>'
                + SizeText
                + '</align>';
        Text :=
            Text
                + '<td='
                + IntToStr(ProbeSummaryColumns[GiResourceVariant].Exploration)
                + '><align=right>'
                + ExplorationText
                + '</align>';
        Text :=
            Text
                + '<td='
                + IntToStr(ProbeSummaryColumns[GiResourceVariant].Condition)
                + '><align=right>'
                + ConditionText
                + '</align>';
        Text :=
            Text
                + '<td='
                + IntToStr(ProbeSummaryColumns[GiResourceVariant].Status)
                + '>'
                + StatusText
                + #13#10;
        Inc(LineCount);
      end;
    end;
  end;
  Result := Text;
end;

function TPlayer.GetSatelliteExplorationTurns(Satellite: TSatellite): Integer;
var
  I, Water, Land, Hill: Integer;
  Probe: TSatellite;
  Planet: TPlanet;
begin
  Result := 0;
  if Satellite.TargetPlanet = nil then
    Exit;
  if Satellite.BrokenFlag <> 0 then
    Exit;
  Planet := TObject(Satellite.TargetPlanet) as TPlanet;
  Water := 0;
  Land := 0;
  Hill := 0;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
  begin
    Probe := TSatellite(GetPlayer.Satellites[I]);
    if (Satellite.TargetPlanet = Probe.TargetPlanet) and (Probe.BrokenFlag = 0) then
    begin
      Water := Min(Planet.WaterTiles - Planet.WaterExplored, Water + Probe.WaterExplorationRate);
      Land := Min(Planet.LandTiles - Planet.LandExplored, Land + Probe.LandExplorationRate);
      Hill := Min(Planet.HillTiles - Planet.HillExplored, Hill + Probe.HillExplorationRate);
    end;
  end;
  if Water > 0 then
    Water := Min(999, Ceil((Planet.WaterTiles - Planet.WaterExplored) / Water));
  if Land > 0 then
    Land := Min(999, Ceil((Planet.LandTiles - Planet.LandExplored) / Land));
  if Hill > 0 then
    Hill := Min(999, Ceil((Planet.HillTiles - Planet.HillExplored) / Hill));
  if (Satellite.WaterExplorationRate > 0) and (Water > 0) then
    Result := Water;
  if (Satellite.LandExplorationRate > 0) and (Land > 0) then
    Result := Max(Result, Land);
  if (Satellite.HillExplorationRate > 0) and (Hill > 0) then
    Result := Max(Result, Hill);
end;

function TPlayer.CanAccessSurfaceLootItem(Item: TItem): Boolean;
begin
  Result := True;
end;

procedure TPlayer.ReportIdleSatellites(Star: TStar);
var
  I, J, Remaining: Integer;
  Satellite: TSatellite;
  Text: WideString;
  Found: Boolean;
  Planets: array[1..3] of TPlanet;
begin
  Found := False;
  Text := '';
  Planets[1] := nil;
  Planets[2] := nil;
  Planets[3] := nil;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
  begin
    Satellite := TSatellite(GetPlayer.Satellites[I]);
    if (Satellite.TargetPlanet <> nil)
        and ((TObject(Satellite.TargetPlanet) as TPlanet).CurrentStar = Star) then
    begin
      Remaining := GetSatelliteExplorationTurns(Satellite);
      if Remaining <= 0 then
      begin
        for J := 1 to 3 do
        begin
          if Planets[J] = Satellite.TargetPlanet then
            Break;
          if Planets[J] = nil then
          begin
            Planets[J] := TPlanet(Satellite.TargetPlanet);
            Break;
          end;
        end;
        Text := Text + #13#10 + Satellite.GetIdleInfoText;
        Found := True;
      end;
    end;
  end;
  if Found then
    with AddOrUpdatePlayerBubble(pmGalaxyNews, Galaxy.CurrentTurn, Text, '') do
    begin
      if Planets[1] <> nil then
        Targets[0].PlanetId := Planets[1].Id;
      if Planets[2] <> nil then
        Targets[1].PlanetId := Planets[2].Id;
      if Planets[3] <> nil then
        Targets[2].PlanetId := Planets[3].Id;
    end;
end;

function TPlayer.CanAccessHoldGoods(Good: Byte): Boolean;
begin
  Result := True;
end;

function TPlayer.CanAccessStoredItem(Item: TItem): Boolean;
begin
  Result := True;
end;

function TPlayer.CountStoredItemUnits(Location: TObject; ItemType: TItemType): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  Result := 0;
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if CanAccessStoredItem(Entry.Item)
        and ((Location = nil) or (Entry.LocationOwner = Location)) then
    begin
      if (ItemType in [t_Food..t_Narcotics])
          or (ItemType in [t_Protoplasm, t_UselessCountableItem]) then
      begin
        if Entry.Item.ItemType = ItemType then
          Inc(Result, Entry.Item.Weight);
      end
      else if Entry.Item.ItemType = ItemType then
        Inc(Result);
    end;
  end;
end;

procedure TPlayer.RepairDuplicateStorageSlots(Location: TObject);
var
  I, J, Count: Integer;
  Entry, Other: PStorageEntry;
begin
  Count := StorageEntries.Count;
  for I := 0 to Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location) and CanAccessStoredItem(Entry.Item) then
      for J := I + 1 to Count - 1 do
      begin
        Other := StorageEntries[J];
        if (Other.LocationOwner = Location) and CanAccessStoredItem(Other.Item) then
          if Entry.SlotIndex = Other.SlotIndex then
            Other.SlotIndex := FindNextStorageSlot(Location);
      end;
  end;
end;

function TPlayer.FindNextStorageSlot(Location: TObject): Integer;
var
  I, Count: Integer;
  Entry: PStorageEntry;
begin
  Result := 0;
  Count := StorageEntries.Count;
  while True do
  begin
    I := 0;
    while I < Count do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = Location)
          and CanAccessStoredItem(Entry.Item)
          and (Entry.SlotIndex = Result) then
        Break;
      Inc(I);
    end;
    if I >= Count then
      Break;
    Inc(Result);
  end;
end;

function TPlayer.GetStorageSlotExtent(Location: TObject): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  Result := 0;
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if not ((Entry.LocationOwner = Location) and CanAccessStoredItem(Entry.Item)) then
      Continue;
    Result := Max(Result, Entry.SlotIndex + 1);
  end;
end;

function TPlayer.FindStorageIndexByLocationAndSlot(Location: TObject; Slot: Integer): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location)
        and CanAccessStoredItem(Entry.Item)
        and (Entry.SlotIndex = Slot) then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function TPlayer.FindStorageGoodsByLocationAndType(Location: TObject; Good: Byte): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location) and (Byte(Entry.Item.ItemType) = Good) then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function TPlayer.FindMergeableStorageItemByLocation(
    Location: TObject;
    Item: TCountableItem
): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location) and Item.CanMerge(Entry.Item) then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

procedure TPlayer.ShiftStorageSlotsAtOrAfter(Location: TObject; Slot: Integer);
var
  I: Integer;
  Entry: PStorageEntry;
begin
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location)
        and CanAccessStoredItem(Entry.Item)
        and (Entry.SlotIndex >= Slot) then
      Inc(Entry.SlotIndex);
  end;
end;

procedure TPlayer.CloseVacantStorageSlot(Location: TObject; Slot: Integer);
var
  I: Integer;
  Entry: PStorageEntry;
begin
  if FindStorageIndexByLocationAndSlot(Location, Slot) < 0 then
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = Location) and CanAccessStoredItem(Entry.Item) then
        if Entry.SlotIndex >= Slot then
          Dec(Entry.SlotIndex);
    end;
end;

function TPlayer.HasAccessibleStorageAt(Location: TObject): Boolean;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  if Location = nil then
  begin
    Result := StorageEntries.Count <= 0;
    Exit;
  end;
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Entry.LocationOwner = Location) and CanAccessStoredItem(Entry.Item) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TPlayer.CountPartnersInNormalSpace: Byte;
var
  I: Integer;
  Ship: TShip;
begin
  Result := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := CurrentStar.Ships[I];
    if (Ship.PartnerShip = Self) and Ship.InNormalSpace then
      Inc(Result);
  end;
end;

function TPlayer.GetShipRatingComparison(Ship: TShip): Byte;
var
  Ranger: TRanger;
begin
  Result := 0;
  if Ship.TypeId = stRanger then
  begin
    Galaxy.RefreshRangerRatingPlaces;
    Ranger := Ship as TRanger;
    case Round(
        RemapClamped(
            Ranger.TotalExperience,
            GetPlayer.PlaceInRating / 3,
            3 * GetPlayer.PlaceInRating,
            0,
            100
        )) of
      0..20: Result := 1;
      21..40: Result := 2;
      41..60: Result := 3;
      61..80: Result := 4;
      81..100: Result := 5;
    else
      RaiseWideMessage(
          'Ошибк?? в рейтинге корабля в сравнении с игроком'
      );
    end;
  end;
end;

function TPlayer.GetShipRankComparison(Ship: TShip): Byte;
var
  Normal: TNormalShip;
begin
  Result := 0;
  if Ship is TNormalShip then
  begin
    Normal := Ship as TNormalShip;
    case Normal.Rank - GetPlayer.Rank of
      -7..-2: Result := 1;
      -1: Result := 2;
      0: Result := 3;
      1: Result := 4;
      2..7: Result := 5;
    else
      RaiseWideMessage('Error in ранк корабля в сравнении с игроком');
    end;
  end;
end;

function TPlayer.GetShipPirateRankComparison(Ship: TShip): Byte;
var
  Normal: TNormalShip;
begin
  Result := 0;
  if Ship is TNormalShip then
  begin
    Normal := Ship as TNormalShip;
    case Normal.PirateRank - GetPlayer.PirateRank of
      -8..-2: Result := 1;
      -1: Result := 2;
      0: Result := 3;
      1: Result := 4;
      2..8: Result := 5;
    else
      RaiseWideMessage('Error in ранк корабля в сравнении с игроком');
    end;
  end;
end;

function TPlayer.GetShipStrengthComparison(Ship: TShip): Byte;
begin
  Result := 0;
  case Round(RemapClamped(Ship.Strength, GetPlayer.Strength / 3, GetPlayer.Strength * 3, 0, 100)) of
    0..20: Result := 1;
    21..40: Result := 2;
    41..60: Result := 3;
    61..80: Result := 4;
    81..100: Result := 5;
  else
    RaiseWideMessage('Error in сила корабля в сравнении с игроком');
  end;
end;

function TPlayer.BuildTranclucatorStorageSummary(var LineCount: Integer): WideString;
var
  I, J, HeaderCount: Integer;
  Ship: TShip;
  Text, Heading, Divider: WideString;
  Star: TStar;
begin
  Divider := GetStorageDividerText;
  Text := '';
  LineCount := 0;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    HeaderCount := 0;
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if Ship.TypeId = stTranclucator then
        if ((Ship as TTranclucator).OwnerShip = GetPlayer) and not Ship.IsHullDestroyed then
        begin
          if HeaderCount = 0 then
          begin
            Heading :=
                WrapTextInColor(
                    FormatText1(
                        LocalizedText('FormShip.StorageInfo.Star'),
                        '',
                        '<Star>',
                        Star.Name
                    ),
                    TextHighlightColorTag
                );
            Text :=
                Text
                    + #13#10
                    + Divider
                    + #13#10
                    + '<td='
                    + IntToStr(TranclucatorSummaryWidths[GiResourceVariant])
                    + '><align=center>'
                    + Heading
                    + '</align>'
                    + #13#10
                    + Divider
                    + #13#10;
            Inc(HeaderCount);
            Inc(LineCount);
          end;
          Text := Text + '- ' + Ship.GetName + #13#10;
          Inc(LineCount);
        end;
    end;
  end;
  Result := Text;
end;

function TPlayer.CompareStorageEntries(Left, Right: PStorageEntry): Integer;
var
  LeftStarId, RightStarId: Cardinal;
  LeftPriority, RightPriority: Integer;
begin
  if Left.LocationOwner is TPlanet then
    LeftStarId := (Left.LocationOwner as TPlanet).CurrentStar.Id
  else
    LeftStarId := (Left.LocationOwner as TShip).CurrentStar.Id;
  if Right.LocationOwner is TPlanet then
    RightStarId := (Right.LocationOwner as TPlanet).CurrentStar.Id
  else
    RightStarId := (Right.LocationOwner as TShip).CurrentStar.Id;
  if LeftStarId < RightStarId then
  begin
    Result := -1;
    Exit
  end;
  if LeftStarId > RightStarId then
  begin
    Result := 1;
    Exit
  end;
  if (Left.LocationOwner is TPlanet) and (Right.LocationOwner is TShip) then
  begin
    Result := -1;
    Exit
  end;
  if (Left.LocationOwner is TShip) and (Right.LocationOwner is TPlanet) then
  begin
    Result := 1;
    Exit
  end;
  if Left.LocationOwner is TPlanet then
  begin
    if Cardinal((Left.LocationOwner as TPlanet).Id)
        < Cardinal((Right.LocationOwner as TPlanet).Id) then
    begin
      Result := -1;
      Exit
    end;
    if Cardinal((Left.LocationOwner as TPlanet).Id)
        > Cardinal((Right.LocationOwner as TPlanet).Id) then
    begin
      Result := 1;
      Exit
    end;
  end
  else
  begin
    if Cardinal((Left.LocationOwner as TShip).Id) < Cardinal((Right.LocationOwner as TShip).Id) then
    begin
      Result := -1;
      Exit
    end;
    if Cardinal((Left.LocationOwner as TShip).Id) > Cardinal((Right.LocationOwner as TShip).Id) then
    begin
      Result := 1;
      Exit
    end;
  end;
  if Integer(Left.Item.ItemType) < Integer(Right.Item.ItemType) then
  begin
    Result := -1;
    Exit
  end;
  if Integer(Left.Item.ItemType) > Integer(Right.Item.ItemType) then
  begin
    Result := 1;
    Exit
  end;
  if (Left.Item.ItemType = t_MicroModule) and (Right.Item.ItemType = t_MicroModule) then
  begin
    LeftPriority :=
        GetMicroModulePriorityColorTier((Left.Item as TMicroModule).MicroModuleIndex - 1);
    RightPriority :=
        GetMicroModulePriorityColorTier((Right.Item as TMicroModule).MicroModuleIndex - 1);
    if LeftPriority > RightPriority then
    begin
      Result := -1;
      Exit
    end;
    if LeftPriority < RightPriority then
    begin
      Result := 1;
      Exit
    end;
    if (Left.Item as TMicroModule).MicroModuleIndex
        < (Right.Item as TMicroModule).MicroModuleIndex then
    begin
      Result := -1;
      Exit
    end;
    if (Left.Item as TMicroModule).MicroModuleIndex
        > (Right.Item as TMicroModule).MicroModuleIndex then
    begin
      Result := 1;
      Exit
    end;
  end;
  if Left.Item.Weight < Right.Item.Weight then
  begin
    Result := -1;
    Exit
  end;
  if Left.Item.Weight > Right.Item.Weight then
  begin
    Result := 1;
    Exit
  end;
  if Left.Item.Cost < Right.Item.Cost then
  begin
    Result := -1;
    Exit
  end;
  if Left.Item.Cost > Right.Item.Cost then
  begin
    Result := 1;
    Exit
  end;
  Result := 0;
end;

procedure TPlayer.SortStorageEntries;
var
  I, J: Integer;
  Temp: PStorageEntry;
begin
  for I := 0 to StorageEntries.Count - 2 do
    for J := I + 1 to StorageEntries.Count - 1 do
      if CompareStorageEntries(StorageEntries[I], StorageEntries[J]) > 0 then
      begin
        Temp := StorageEntries[I];
        StorageEntries[I] := StorageEntries[J];
        StorageEntries[J] := Temp;
      end;
end;

procedure TPlayer.RefreshStorageBubbles;
begin
  BuildStorageBubbles;
end;

procedure TPlayer.BuildStorageBubbles;
var
  I, LineCount, AddedLines, Page: Integer;
  Text, Heading, ConditionText, Divider: WideString;
  Entry: PStorageEntry;
  PreviousLocation: TObject;
begin
  SortStorageEntries;
  Divider := GetStorageDividerText;
  Page := 1;
  if StorageEntries.Count <= 0 then
  begin
    Heading := BuildTranclucatorStorageSummary(AddedLines);
    if HasDeployedSatellites or (Length(Heading) > 0) then
    begin
      Text := WrapTextInColor(LocalizedText('FormShip.StorageInfo.Main'), GreenColorTag) + #13#10;
      Text := Text + BuildDeployedSatelliteSummary(AddedLines);
      Text := Text + Heading;
      AddOrUpdatePlayerBubble(pmStorage, Galaxy.CurrentTurn, Text, 'sys_storage1');
    end
    else
      RemovePlayerBubblePages('sys_storage', 0);
  end
  else
  begin
    PreviousLocation := nil;
    LineCount := 0;
    Text :=
        WrapTextInColor(
                LocalizedText('FormShip.StorageInfo.Main') + 'onepage' + GetStorageColumnHeaderText,
                GreenColorTag)
            + #13#10;
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if (PreviousLocation <> Entry.LocationOwner) or (LineCount > 40) then
      begin
        if LineCount > 40 then
        begin
          if Page = 1 then
            ReplaceTextToken(
                Text,
                'onepage',
                ' ('
                    + LocalizedText('FormShip.StorageInfo.Page')
                    + ' '
                    + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                    + ')',
                ''
            );
          AddOrUpdatePlayerBubble(
              pmStorage,
              Galaxy.CurrentTurn,
              Text,
              'sys_storage' + IntToStr(Page)
          );
          Inc(Page);
          Text :=
              WrapTextInColor(
                      LocalizedText('FormShip.StorageInfo.Main')
                          + ' ('
                          + LocalizedText('FormShip.StorageInfo.Page')
                          + ' '
                          + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                          + ')',
                      GreenColorTag)
                  + GetStorageColumnHeaderText
                  + #13#10;
          LineCount := 0;
        end;
        if Entry.LocationOwner is TPlanet then
        begin
          Heading :=
              FormatText1(
                  LocalizedText('FormShip.StorageInfo.Star'),
                  '',
                  '<Star>',
                  (Entry.LocationOwner as TPlanet).CurrentStar.Name
              );
          Heading :=
              WrapTextInColor(Heading + '. ', TextHighlightColorTag)
                  + WrapTextInColor(
                      (Entry.LocationOwner as TPlanet).GetFullName(' ') + '.',
                      TextHighlightColorTag);
          Text :=
              Text
                  + Divider
                  + #13#10
                  + '<td='
                  + IntToStr(StorageItemColumns[GiResourceVariant].Heading)
                  + '><align=center>'
                  + Heading
                  + '</align>'
                  + #13#10
                  + Divider
                  + #13#10;
          Inc(LineCount, 3);
        end
        else if Entry.LocationOwner is TShip then
        begin
          Heading :=
              FormatText1(
                  LocalizedText('FormShip.StorageInfo.Star'),
                  '',
                  '<Star>',
                  (Entry.LocationOwner as TShip).CurrentStar.Name
              );
          Heading :=
              WrapTextInColor(Heading + '. ', TextHighlightColorTag)
                  + WrapTextInColor(
                      (Entry.LocationOwner as TShip).GetFullName(' ') + '.',
                      TextHighlightColorTag);
          Text :=
              Text
                  + Divider
                  + #13#10
                  + '<td='
                  + IntToStr(StorageItemColumns[GiResourceVariant].Heading)
                  + '><align=center>'
                  + Heading
                  + '</align>'
                  + #13#10
                  + Divider
                  + #13#10;
          Inc(LineCount, 3);
        end;
      end;
      PreviousLocation := Entry.LocationOwner;
      if Entry.Item is TEquipment then
        ConditionText := ' ' + (Entry.Item as TEquipment).GetConditionText(False)
      else
        ConditionText := '';
      Text := Text + '- ' + Entry.Item.GetDisplayName + ConditionText;
      Text :=
          Text
              + '<td='
              + IntToStr(StorageItemColumns[GiResourceVariant].Size)
              + '><align=right>'
              + WrapTextInColor(IntToStr(Entry.Item.Weight), GreenColorTag)
              + '</align>';
      Text :=
          Text
              + '<td='
              + IntToStr(StorageItemColumns[GiResourceVariant].Cost)
              + '><align=right>'
              + WrapTextInColor(IntToStr(Entry.Item.Cost), CyanColorTag)
              + '</align>';
      Text := Text + #13#10;
      Inc(LineCount);
    end;
    if HasDeployedSatellites then
    begin
      // Native computes the probe text once for its line count, then again below.
      BuildDeployedSatelliteSummary(AddedLines);
      if AddedLines + LineCount > 45 then
      begin
        if Page = 1 then
          ReplaceTextToken(
              Text,
              'onepage',
              ' ('
                  + LocalizedText('FormShip.StorageInfo.Page')
                  + ' '
                  + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                  + ')',
              ''
          );
        AddOrUpdatePlayerBubble(
            pmStorage,
            Galaxy.CurrentTurn,
            Text,
            'sys_storage' + IntToStr(Page)
        );
        Inc(Page);
        Text :=
            WrapTextInColor(
                    LocalizedText('FormShip.StorageInfo.Main')
                        + ' ('
                        + LocalizedText('FormShip.StorageInfo.Page')
                        + ' '
                        + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                        + ')',
                    GreenColorTag)
                + #13#10;
      end;
      if HasDeployedSatellites then
        Text := Text + BuildDeployedSatelliteSummary(AddedLines);
    end;
    Heading := BuildTranclucatorStorageSummary(AddedLines);
    if Length(Heading) > 0 then
    begin
      if AddedLines + LineCount > 45 then
      begin
        if Page = 1 then
          ReplaceTextToken(
              Text,
              'onepage',
              ' ('
                  + LocalizedText('FormShip.StorageInfo.Page')
                  + ' '
                  + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                  + ')',
              ''
          );
        AddOrUpdatePlayerBubble(
            pmStorage,
            Galaxy.CurrentTurn,
            Text,
            'sys_storage' + IntToStr(Page)
        );
        Inc(Page);
        Text :=
            WrapTextInColor(
                    LocalizedText('FormShip.StorageInfo.Main')
                        + ' ('
                        + LocalizedText('FormShip.StorageInfo.Page')
                        + ' '
                        + WrapTextInColor(IntToStr(Page), MagentaColorTag)
                        + ')',
                    GreenColorTag)
                + #13#10;
      end;
      Text := Text + Heading;
    end;
    if Page = 1 then
      ReplaceTextToken(Text, 'onepage', '', '');
    AddOrUpdatePlayerBubble(pmStorage, Galaxy.CurrentTurn, Text, 'sys_storage' + IntToStr(Page));
  end;
  RemovePlayerBubblePages('sys_storage', Page + 1);
  RemovePlayerBubbleByKey('sys_storage');
end;

function TPlayer.SelectPlanetBattleMap: Integer;
var
  I, MapIndex, Count: Integer;
  Candidates: array of Integer;
begin
  Result := -1;
  if IsInstallFeatureEnabled('Robot') then
    if GetPlayer.IsOnPlanet
        and ((Galaxy.BlazerSeriesResolvedTurn <= 0)
            or (Galaxy.KellerSeriesResolvedTurn <= 0)
            or (Galaxy.TerronSeriesResolvedTurn <= 0)) then
      if LastPlanetBattleTurn
          <= Galaxy.CurrentTurn
              - RemapClamped(High(PlanetBattleHistory), 0, High(RobotMapDefinitions), 130, 360) then
      begin
        for I := 0 to High(RobotMapDefinitions) do
          RobotMapDefinitions[I].PlayerPlayCount := 0;
        for I := 0 to High(PlanetBattleHistory) do
        begin
          MapIndex := FindRobotMapById(PlanetBattleHistory[I].MapId);
          if MapIndex >= 0 then
            Inc(RobotMapDefinitions[MapIndex].PlayerPlayCount);
        end;
        SetLength(Candidates, High(RobotMapDefinitions) + 1);
        Count := 0;
        for I := 0 to High(RobotMapDefinitions) do
        begin
          if (RobotMapDefinitions[I].PlanetRace <> [])
              and not (CurrentPlanet.RaceId in RobotMapDefinitions[I].PlanetRace) then
            Continue;
          if (RobotMapDefinitions[I].PlayerRace <> [])
              and not (PilotRace in RobotMapDefinitions[I].PlayerRace) then
            Continue;
          if (RobotMapDefinitions[I].PlayerStatus <> [])
              and not (GetDominantCareer in RobotMapDefinitions[I].PlayerStatus) then
            Continue;
          if High(PlanetBattleHistory) = -1 then
          begin
            if (RobotMapDefinitions[I].MinWins <> 0) or (RobotMapDefinitions[I].MaxWins <> 0) then
              Continue;
          end
          else
          begin
            MapIndex := High(PlanetBattleHistory) + 1;
            if not (((RobotMapDefinitions[I].MinWins <= MapIndex)
                    or (RobotMapDefinitions[I].MinWins = 0))
                and ((RobotMapDefinitions[I].MaxWins >= MapIndex)
                    or (RobotMapDefinitions[I].MaxWins = 0))) then
              Continue;
            if RobotMapDefinitions[I].AfterLiberation then
            begin
              if not ((Galaxy.CurrentTurn - GetPlayer.CurrentStar.LastLiberationRewardsTurn <= 40)
                  and (GetPlayer.CurrentStar.LastLiberationRewardsTurn
                      <= GetPlayer.CurrentStar.LastDominatorPresenceTurn)) then
                Continue;
            end
            else if not (Galaxy.CurrentTurn - GetPlayer.CurrentStar.LastDominatorPresenceTurn
                in [30..120]) then
              Continue;
          end;
          if (RobotMapDefinitions[I].PlayerPlayCount < RobotMapDefinitions[I].Reiteration)
              and not RobotMapDefinitions[I].Terron
              and not RobotMapDefinitions[I].Demo
              and ((Count <= 0)
                  or (RobotMapDefinitions[I].PlayerPlayCount
                      <= RobotMapDefinitions[Candidates[0]].PlayerPlayCount)) then
          begin
            if (Count > 0)
                and (RobotMapDefinitions[I].PlayerPlayCount
                    < RobotMapDefinitions[Candidates[0]].PlayerPlayCount) then
              Count := 0;
            Candidates[Count] := I;
            Inc(Count);
          end;
        end;
        if Count <= 0 then
        begin
          Candidates := nil;
          Exit;
        end;
        Result :=
            RobotMapDefinitions[
                    Candidates[SeededRandomIntRange(0, Count - 1, CurrentPlanet.GenerationSeed)]]
                .Id;
        Candidates := nil;
      end;
end;

procedure TPlayer.SaveEquipmentConfiguration(Index: Integer);
var
  I, NextSlot, Slot: Integer;
  Weapon: TWeapon;
  Item: TEquipment;
  Artefact: TArtefact;
begin
  with EquipmentConfigurations[Index] do
  begin
    for I := 0 to 11 do
      EquipmentIds[I] := 0;
    for I := 0 to 31 do
      ArtefactIds[I] := 0;
    for I := 1 to 5 do
    begin
      Weapon := Weapons[I];
      if (Weapon = nil) or (Weapon.EquippedFlag = 0) then
        Continue;
      Slot := Weapon.AssignedSlotData and EquipmentSlotIndexMask;
      if (Slot >= 0) and (Slot <= 4) then
        EquipmentIds[Slot] := Weapon.Id;
    end;
    NextSlot := 5;
    for I := 1 to Inventory.Count - 1 do
    begin
      Item := Inventory[I];
      if not (Item is TWeapon)
          and (Item.EquippedFlag <> 0)
          and (ItemTypeToSlotKind(Item.ItemType) <> sskUnsupported) then
      begin
        EquipmentIds[NextSlot] := Item.Id;
        Inc(NextSlot);
        if NextSlot > 11 then
          Break;
      end;
    end;
    for I := 0 to Artefacts.Count - 1 do
    begin
      Artefact := Artefacts[I];
      if Artefact.EquippedFlag = 0 then
        Continue;
      Slot := Artefact.AssignedSlotData and EquipmentSlotIndexMask;
      if (Slot >= 0) and (DefaultHullSlotCounts[sskArtefact] > Slot) then
        ArtefactIds[Slot] := Artefact.Id;
    end;
  end;
end;

procedure TPlayer.ApplyEquipmentConfiguration(Index: Integer);

  function IsEmpty: Boolean; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    I: Integer;
  begin
    Result := True;
    with EquipmentConfigurations[Index] do
    begin
      for I := 0 to 11 do
        if EquipmentIds[I] <> 0 then
        begin
          Result := False;
          Exit;
        end;
      for I := 0 to 31 do
        if ArtefactIds[I] <> 0 then
        begin
          Result := False;
          Exit;
        end;
    end;
  end;

  function SupportsItem(
      Item: TItem
  ): Boolean; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  begin
    Result := True;
    if Item is TArtefact then
      Exit;
    if Item is TWeapon then
      Exit;
    if Item is TFuelTanks then
      Exit;
    if Item is TEngine then
      Exit;
    if Item is TRadar then
      Exit;
    if Item is TScaner then
      Exit;
    if Item is TRepairRobot then
      Exit;
    if Item is TCargoHook then
      Exit;
    if Item is TDefGenerator then
      Exit;
    Result := False;
  end;

  function FindSlot(
      Item: TItem
  ): Integer; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    I: Integer;
  begin
    Result := -1;
    if SupportsItem(Item) then
      with EquipmentConfigurations[Index] do
      begin
        if Item is TArtefact then
        begin
          for I := 0 to 31 do
            if (Item as TArtefact).Id = ArtefactIds[I] then
            begin
              Result := I;
              Exit;
            end;
        end
        else if Item is TEquipment then
          for I := 0 to 11 do
            if (Item as TEquipment).Id = EquipmentIds[I] then
            begin
              Result := I;
              Exit;
            end;
      end;
  end;

  procedure UnequipAll; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    I: Integer;
    Item: TEquipment;
    Artefact: TArtefact;
  begin
    for I := 0 to Inventory.Count - 1 do
    begin
      Item := Inventory[I];
      if Item.ItemType in [t_Hull..t_CustomWeapon] then
        Item.Unequip;
    end;
    for I := 0 to Artefacts.Count - 1 do
    begin
      Artefact := Artefacts[I];
      Artefact.Unequip;
    end;
    WeaponCount := 0;
    for I := 1 to 5 do
      Weapons[I] := nil;
  end;

  procedure ReleaseStorageEntry(
      Entry: PStorageEntry
  ); { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  begin
    Entry.Item := nil;
    GetPlayer.StorageEntries.Delete(GetPlayer.StorageEntries.IndexOf(Entry));
    Dispose(Entry);
  end;

  procedure TakeStoredItem(
      Entry: PStorageEntry;
      Slot: Integer
  ); { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    Item: TItem;
    Artefact: TArtefact;
    Equipment: TEquipment;
  begin
    Item := Entry.Item;
    if Item is TArtefact then
    begin
      Artefacts.Add(Item);
      ReleaseStorageEntry(Entry);
      Artefact := Item as TArtefact;
      Artefact.Equip;
      Artefact.AssignedSlotData :=
          (Artefact.AssignedSlotData and EquipmentSecondaryFireFlag) or Cardinal(Slot);
    end
    else if Item is TEquipment then
    begin
      Inventory.Add(Item);
      ReleaseStorageEntry(Entry);
      Equipment := Item as TEquipment;
      Equipment.Equip;
      if Item is TWeapon then
        Equipment.AssignedSlotData :=
            (Equipment.AssignedSlotData and EquipmentSecondaryFireFlag) or Cardinal(Slot);
    end;
  end;

  procedure EquipCarriedItems; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    I, Slot: Integer;
    Equipment: TEquipment;
    Artefact: TArtefact;
  begin
    for I := 1 to Inventory.Count - 1 do
    begin
      Equipment := Inventory[I];
      Slot := FindSlot(Equipment);
      if Slot >= 0 then
      begin
        Equipment.Equip;
        Equipment.AssignedSlotData :=
            (Equipment.AssignedSlotData and EquipmentSecondaryFireFlag) or Cardinal(Slot);
      end;
    end;
    for I := 0 to Artefacts.Count - 1 do
    begin
      Artefact := Artefacts[I];
      Slot := FindSlot(Artefact);
      if Slot >= 0 then
      begin
        Artefact.Equip;
        Artefact.AssignedSlotData :=
            (Artefact.AssignedSlotData and EquipmentSecondaryFireFlag) or Cardinal(Slot);
      end;
    end;
  end;

  procedure EquipStoredItems; { Nested in ApplyEquipmentConfiguration; caller-popped static link, player -4 and preset index -8. }
  var
    I, Slot: Integer;
    Entry: PStorageEntry;
  begin
    if (StorageEntries <> nil) and (IsDockedToShip or IsOnPlanet) then
      for I := StorageEntries.Count - 1 downto 0 do
      begin
        Entry := StorageEntries[I];
        if (Entry <> nil)
            and (Entry.Item <> nil)
            and ((DockedTo = Entry.LocationOwner) or (CurrentPlanet = Entry.LocationOwner)) then
        begin
          Slot := FindSlot(Entry.Item);
          if Slot >= 0 then
            TakeStoredItem(Entry, Slot);
        end;
      end;
  end;
begin
  if not IsEmpty then
  begin
    UnequipAll;
    EquipCarriedItems;
    EquipStoredItems;
    RebuildEquipmentCache;
  end;
end;

function TPlayer.HasEquipmentConfiguration(Index: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  with EquipmentConfigurations[Index] do
  begin
    for I := 0 to 11 do
      if EquipmentIds[I] <> 0 then
      begin
        Result := True;
        Exit;
      end;
    for I := 0 to 31 do
      if ArtefactIds[I] <> 0 then
      begin
        Result := True;
        Exit;
      end;
  end;
end;

function TPlayer.GetAvailableNodeCount(Carrier: TShip): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
begin
  if Carrier <> nil then
    Result := Carrier.GetCarriedNodeCount
  else
    Result := GetCarriedNodeCount;
  if IsOnPlanet then
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = CurrentPlanet) and (Entry.Item.ItemType = t_Protoplasm) then
        Inc(Result, Entry.Item.Weight);
    end;
  if IsDockedToShip then
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = DockedTo) and (Entry.Item.ItemType = t_Protoplasm) then
        Inc(Result, Entry.Item.Weight);
    end;
end;

procedure TPlayer.ConsumeAvailableNodes(Count: Integer; Carrier: TShip);
var
  I, Remaining: Integer;
  Item: TItem;
  Entry: PStorageEntry;
begin
  if Count <= 0 then
    Exit;
  if Carrier = nil then
    Carrier := Self;
  for I := Carrier.Inventory.Count - 1 downto 1 do
  begin
    Item := Carrier.Inventory[I];
    if Item.ItemType = t_Protoplasm then
    begin
      if Item.Weight > Count then
      begin
        Remaining := Item.Weight - Count;
        Dec((Item as TProtoplasm).StackCount, Count);
        Item.Cost := Round(Item.Cost / Item.Weight * Remaining);
        Item.Weight := Remaining;
        Count := 0;
      end
      else
      begin
        Dec(Count, Item.Weight);
        Carrier.Inventory.Delete(I);
        Item.Free;
      end;
    end;
    if Count = 0 then
      Break;
  end;
  if IsOnPlanet and (Count > 0) then
    for I := StorageEntries.Count - 1 downto 0 do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = CurrentPlanet) and (Entry.Item.ItemType = t_Protoplasm) then
      begin
        if Entry.Item.Weight > Count then
        begin
          Remaining := Entry.Item.Weight - Count;
          Dec((Entry.Item as TProtoplasm).StackCount, Count);
          Entry.Item.Cost := Round(Entry.Item.Cost / Entry.Item.Weight * Remaining);
          Entry.Item.Weight := Remaining;
          Count := 0;
        end
        else
        begin
          Dec(Count, Entry.Item.Weight);
          StorageEntries.Delete(I);
          Entry.Item.Free;
          Dispose(Entry);
        end;
      end;
      if Count = 0 then
        Break;
    end;
  if IsDockedToShip and (Count > 0) then
    for I := StorageEntries.Count - 1 downto 0 do
    begin
      Entry := StorageEntries[I];
      if (Entry.LocationOwner = DockedTo) and (Entry.Item.ItemType = t_Protoplasm) then
      begin
        if Entry.Item.Weight > Count then
        begin
          Remaining := Entry.Item.Weight - Count;
          Dec((Entry.Item as TProtoplasm).StackCount, Count);
          Entry.Item.Cost := Round(Entry.Item.Cost / Entry.Item.Weight * Remaining);
          Entry.Item.Weight := Remaining;
          Count := 0;
        end
        else
        begin
          Dec(Count, Entry.Item.Weight);
          StorageEntries.Delete(I);
          Entry.Item.Free;
          Dispose(Entry);
        end;
      end;
      if Count = 0 then
        Break;
    end;
  RefreshDerivedStats(True);
end;

function TPlayer.GetMaxPiratePartners: Integer;
begin
  Result := 0;
  if CareerStatus[rcPirate] > 60 then
    Inc(Result);
  if CareerStatus[rcPirate] > 75 then
    Inc(Result);
  if Galaxy.EminentCareerShips[rcPirate] = Self then
    Inc(Result);
  if PirateLicenseTicks > 0 then
    Inc(Result);
end;

function TPlayer.GetMaxDominionShips: Integer;
begin
  Result := 0;
  if CareerStatus[rcPirate] > 50 then
    Inc(Result);
  if CareerStatus[rcPirate] > 60 then
    Inc(Result);
  if CareerStatus[rcPirate] > 75 then
    Inc(Result);
  if Galaxy.EminentCareerShips[rcPirate] = Self then
    Inc(Result);
  if PirateLicenseTicks > 0 then
    Inc(Result);
end;

procedure TPlayer.AddJournalRecord(Text: WideString);
var
  Entry: TJournalRecord;
begin
  Entry := TJournalRecord.Create;
  JournalRecords.Add(Entry);
  Entry.Text := Text;
  Entry.DateTurn := Galaxy.CurrentTurn;
end;

procedure TPlayer.DeleteJournalRecord(Index: Integer);
begin
  if (Index >= 0) and (JournalRecords.Count >= Index) then
  begin
    TJournalRecord(JournalRecords[Index]).Free;
    JournalRecords.Delete(Index);
  end;
end;

procedure TPlayer.ClearJournal;
begin
  while JournalRecords.Count > 0 do
    DeleteJournalRecord(JournalRecords.Count - 1);
end;

function TPlayer.ExportJournal: WideString;
var
  I: Integer;
  Contents, FileName: AnsiString;
  Entry: TJournalRecord;
  Year, Month, Day: Word;
begin
  Contents := '';
  for I := 0 to JournalRecords.Count - 1 do
  begin
    Entry := JournalRecords[I];
    Contents := Contents + Galaxy.FormatTurnDate(Entry.DateTurn) + #13#10;
    Contents := Contents + RemoveTextTagsW(Entry.Text) + #13#10;
    Contents := Contents + #13#10;
  end;
  DecodeDate(Galaxy.TurnToDateTime(-1), Year, Month, Day);
  FileName :=
      GetGameUserDirectory + 'Save\Journal_' + Format('%d_%.2d_%.2d', [Year, Month, Day]) + '.txt';
  WriteTextFileThreadSafe(FileName, Contents);
  Result := FileName;
end;

procedure TPlayer.SortNewsEntries;
var
  I, J: Integer;
  First, Second: PPlanetNewsEntry;
  Temp: Pointer;
begin
  for I := 0 to NewsEntries.Count - 1 do
    for J := I + 1 to NewsEntries.Count - 1 do
    begin
      First := PPlanetNewsEntry(NewsEntries[I]);
      Second := PPlanetNewsEntry(NewsEntries[J]);
      if First.Id > Second.Id then
      begin
        Temp := NewsEntries[I];
        NewsEntries[I] := NewsEntries[J];
        NewsEntries[J] := Temp;
      end;
    end;
end;

procedure TPlayer.TrimNewsEntries(KeepCount: Integer);
var
  I: Integer;
  Entry: PPlanetNewsEntry;
begin
  for I := NewsEntries.Count - KeepCount - 1 downto 0 do
  begin
    Entry := PPlanetNewsEntry(NewsEntries[I]);
    NewsEntries.Delete(I);
    Dispose(Entry);
  end;
end;

function TPlayer.ExportNews: WideString;
var
  I: Integer;
  Contents, FileName: AnsiString;
  Entry: PPlanetNewsEntry;
  Year, Month, Day: Word;
begin
  Contents := '';
  for I := 0 to NewsEntries.Count - 1 do
  begin
    Entry := NewsEntries[I];
    Contents := Contents + Galaxy.FormatTurnDate(Entry.Turn) + #13#10;
    Contents := Contents + RemoveTextTagsW(Entry.Text) + #13#10;
    Contents := Contents + #13#10;
  end;
  DecodeDate(Galaxy.TurnToDateTime(-1), Year, Month, Day);
  FileName := 'Save\News_' + Format('%d_%.2d_%.2d', [Year, Month, Day]) + '.txt';
  WriteTextFileThreadSafe(FileName, Contents);
  Result := FileName;
end;

procedure TPlayer.MergeGalaxyNews;
var
  I, J: Integer;
  Found: Boolean;
  Source, Entry: PPlanetNewsEntry;
begin
  for I := 0 to Galaxy.PlanetNews.Count - 1 do
  begin
    Source := PPlanetNewsEntry(Galaxy.PlanetNews[I]);
    Found := False;
    for J := 0 to NewsEntries.Count - 1 do
    begin
      Entry := PPlanetNewsEntry(NewsEntries[J]);
      if Source.Id = Entry.Id then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      New(Entry);
      Entry.Id := Source.Id;
      Entry.Turn := Source.Turn;
      Entry.NewsType := Source.NewsType;
      Entry.Text := Source.Text;
      NewsEntries.Add(Entry);
    end;
  end;
end;

procedure TPlayer.RefreshNewsAtLocation;
begin
  if (Galaxy.CurrentTurn > GalaxyWarmupTurns) and (IsOnPlanet or IsDockedToShip) then
    if (CurrentPlanet = nil)
        or ((CurrentPlanet.OwnerId in [oiMaloc..oiGaal, oiPirate])
            and (CurrentPlanet.GetRelationLevelToShip(Self) > rlBad)) then
    begin
      MergeGalaxyNews;
      SortNewsEntries;
      TrimNewsEntries(100);
    end;
end;

function TPlayer.CalculateSpeed: Integer;
begin
  Result := inherited CalculateSpeed;
end;

procedure TPlayer.CreateRuinsProxy;
begin
  RuinsProxy := TRuins.Create;
  (RuinsProxy as TRuins).Init(rstMilitaryBase, GetPlayer.CurrentStar, '');
  CurrentStar.Ships.Delete(CurrentStar.Ships.IndexOf(RuinsProxy));
end;

procedure TPlayer.EnterRuinsMode(Mode: Integer);
var
  SelectedMode: Integer;
begin
  if InHyperspace then
    Exit;
  if Mode > 0 then
    SelectedMode := Mode
  else
    SelectedMode := GetHull.CapitalShip;
  if SelectedMode = 0 then
    Exit;
  if RuinsMode = 0 then
  begin
    if TemporaryShopSlots <> nil then
      RestoreTemporaryShopStock;
    RuinsSavedPlanet := CurrentPlanet;
    RuinsSavedDockedTo := DockedTo;
    if RuinsProxy = nil then
      CreateRuinsProxy;
    DockedTo := RuinsProxy;
    CurrentPlanet := nil;
    RuinsProxy.CurrentStar := CurrentStar;
    BuildTemporaryShopSlotGrid;
  end;
  RuinsMode := SelectedMode;
  RequestedScreenId := screenRuinsTalk;
  TMessageLoopGI(RegisteredScreens[CurrentScreenId]).RequestClose(1);
end;

procedure TPlayer.CloseRuinsModeScreen;
begin
  RuinsStatusText := '';
  if (RuinsSavedPlanet = nil) and (RuinsSavedDockedTo = nil) then
  begin
    RequestedScreenId := screenStarMap;
    if TemporaryShopSlots <> nil then
    begin
      Galaxy.CheckIntegrityChecksum(403);
      CurrentPlanet := nil;
      DockedTo := RuinsProxy;
      RestoreTemporaryShopStock;
      Galaxy.PrimeIntegrityChecksum(404);
    end;
  end
  else
  begin
    if RuinsSavedDockedTo <> nil then
      RequestedScreenId := screenRuinsTalk
    else if RuinsSavedPlanet.OwnerId <> oiUninhabited then
      RequestedScreenId := screenPlanet
    else
      RequestedScreenId := screenPlanetNO;
    ExitRuinsMode;
  end;
  TMessageLoopGI(RegisteredScreens[CurrentScreenId]).RequestClose(1);
end;

procedure TPlayer.ExitRuinsMode;
begin
  Galaxy.CheckIntegrityChecksum(403);
  if TemporaryShopSlots <> nil then
  begin
    CurrentPlanet := nil;
    DockedTo := RuinsProxy;
    RestoreTemporaryShopStock;
  end;
  CurrentPlanet := RuinsSavedPlanet;
  RuinsSavedPlanet := nil;
  DockedTo := RuinsSavedDockedTo;
  RuinsSavedDockedTo := nil;
  RuinsMode := 0;
  BuildTemporaryShopSlotGrid;
  Galaxy.PrimeIntegrityChecksum(404);
end;

procedure TPlayer.RefreshCurrentStanding;
begin
  if IsInPrison then
    CurrentStanding := ssNeutral
  else if OwnerId <> oiPirate then
  begin
    if (CurrentSystemKills.Pirate > 0) or (CurrentStar.ControlFaction = sfCoalition) then
      CurrentStanding := ssCoalitionActive
    else
      CurrentStanding := ssCoalitionPassive;
  end
  else
  begin
    if (CurrentSystemKills.Normal > 0) or (CurrentStar.ControlFaction = sfPirates) then
      CurrentStanding := ssPirateActive
    else
      CurrentStanding := ssPiratePassive;
  end;
  if (CurrentStanding = ssCoalitionActive)
      and (MainPiratePlanet <> nil)
      and (MainPiratePlanet.CurrentStar = CurrentStar) then
    CurrentStanding := ssCoalitionMilitary;
end;

function TPlayer.CanSelectShipTarget(Ship: TShip): Boolean;
type
  TOwnerMasks = array[TStarFaction] of TOwnerMask;

var
  Faction: TStarFaction;
begin
  Result := False;
  if (Ship.TargetingRestriction = 1) and (Ship.EnemyShip <> Self) and (EnemyShip <> Ship) then
    Exit;
  if (Ship is TKling)
      and (ChameleonLogic[TKling(Ship).DominatorSeries] >= 2)
      and (Ship.EnemyShip <> Self)
      and (EnemyShip <> Ship) then
    Exit;
  if Ship.TypeId in [rstRangerCenter..rstCustomStation] then
  begin
    for Faction := Low(TStarFaction) to High(TStarFaction) do
      if (OwnerId in TOwnerMasks(PlanetOwnerMasks)[Faction])
          and (Ship.CurrentStanding in NonTargetableStationStandingMasks[Faction])
          and ((Ship.ScriptShip = nil)
              or (Ship.OwnerId in TOwnerMasks(PlanetOwnerMasks)[Faction])) then
        Exit;
  end;
  Result := True;
end;

function TPlayer.CanScanShip(Ship: TShip): Boolean;
begin
  Result := True;
  if Galaxy.UltraScanModEnabled = 0 then
  begin
    if Ship is TRuins then
      Result := False
    else if (Ship is TKling) and not Ship.HasIndependentScriptFaction then
    begin
      if (GetPlayer.GetScanner = nil)
          or (GetPlayer.GetScanner.OwnerId <> oiDominator)
          or (GetPlayer.GetScanner.DominatorSeries <> TKling(Ship).DominatorSeries) then
        Result := False;
    end;
    Result := GetPlayer.ScriptItemsAct(satOnScanPossibility, Ship, nil, Ord(Result)) <> 0;
  end;
end;

end.
