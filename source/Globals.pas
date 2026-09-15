{$EXCESSPRECISION OFF}
unit Globals;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  fMainForm,
  fCfgSettings,
  fGameEnd,
  fAbout,
  fIntroduction,
  fGameSettings,
  fGameSettings2,
  fLoadAB,
  fAchievements,
  fFilm,
  fRating2,
  fGameMenu,
  fGameLoad,
  fPlanet,
  fGov,
  fInfo,
  fScaner,
  fRewards,
  fGalaxy2,
  fGoodsShop2,
  EC_Expression,
  fTalk,
  ab_MainForm,
  fLoad,
  fJump,
  ThreadCalc,
  fJournal,
  fSelectFace,
  fLoadQuest,
  fPlanetQuest,
  fPlanetNO,
  aItem,
  aGalaxyStruct,
  aShip,
  fScore,
  fLoadRobot,
  fStarMap,
  aEFilm,
  aEFilmEnd,
  SE_Space,
  SE_Process,
  aPlanet,
  fShip2,
  fHangar,
  fRuinsTalk,
  fEquipmentShop,
  fSaveManager,
  GI_GraphButton,
  GI_MessageLoop,
  EC_Buf,
  EC_Struct,
  fFilmFile,
  SyncObjs,
  Classes,
  Types;
type
  TPlanetTempl = class;
  TScriptTemplUnit = class;
  TSputnikTempl = class;
  TGreetingMask = set of 0..7;
  TRobotMapPlayerStatuses = set of 0..2;
  TScriptTemplUnit = class(TObjectEx)
    ConfigValue: Integer;
    Name: WideString;
    FileName: WideString;
    UseCount: Integer;
    LastTurn: Integer;
    ActiveScriptIndex: Integer;
    ConditionCode: TCodeEC;
    constructor Create;
    destructor Destroy; override;
  end;
  TPlanetTempl = class(TObject)
    Radius: Integer;
    SmallMaskName: WideString;
    SmallLightName: WideString;
    MaskName: WideString;
    LightName: WideString;
  end;
  TPlanetSpaceTemplate = record
    Style: Integer;
    StyleVariant: Integer;
    Radius: Integer;
    SpaceObject: TObjectSE;
  end;
  TSputnikTempl = class(TObject)
    Radius: Integer;
    MaskName: WideString;
  end;
  TPlayerMessageKindSet = set of 0..15;
  TPlayerMessageTarget = packed record
    ShipId: Cardinal;
    PlanetId: Cardinal;
  end;
  TMessagePlayerTypeGraph = record
    NormalImage: WideString;
    ActiveImage: WideString;
    PressedImage: WideString;
    LifetimeTurns: Integer;
  end;
var
  PlayerMessagePresentations: array[0..10] of TMessagePlayerTypeGraph = (
      (NormalImage: 'GalaxyN'; ActiveImage: 'GalaxyA'; PressedImage: 'GalaxyD'; LifetimeTurns: 10),
      (NormalImage: 'EtherN'; ActiveImage: 'EtherA'; PressedImage: 'EtherD'; LifetimeTurns: 0),
      (
          NormalImage: 'ShipPlusN';
          ActiveImage: 'ShipPlusA';
          PressedImage: 'ShipPlusD';
          LifetimeTurns: 5
      ),
      (
          NormalImage: 'QuestNormalN';
          ActiveImage: 'QuestNormalA';
          PressedImage: 'QuestNormalD';
          LifetimeTurns: 1000000
      ),
      (
          NormalImage: 'QuestOkN';
          ActiveImage: 'QuestOkA';
          PressedImage: 'QuestOkD';
          LifetimeTurns: 1000000
      ),
      (
          NormalImage: 'QuestCancelN';
          ActiveImage: 'QuestCancelA';
          PressedImage: 'QuestCancelD';
          LifetimeTurns: 1000000
      ),
      (NormalImage: 'TipsN'; ActiveImage: 'TipsA'; PressedImage: 'TipsD'; LifetimeTurns: 182),
      (NormalImage: 'UserN'; ActiveImage: 'UserA'; PressedImage: 'UserD'; LifetimeTurns: 1000000),
      (
          NormalImage: 'ShipMinusN';
          ActiveImage: 'ShipMinusA';
          PressedImage: 'ShipMinusD';
          LifetimeTurns: 5
      ),
      (
          NormalImage: 'StorageN';
          ActiveImage: 'StorageA';
          PressedImage: 'StorageD';
          LifetimeTurns: 1000000
      ),
      (NormalImage: 'Ether2N'; ActiveImage: 'Ether2A'; PressedImage: 'Ether2D'; LifetimeTurns: 0)
  );
type
  TMessagePlayer = class;
  TMessagePlayer = class(TObjectEx)
    Prev: TMessagePlayer;
    Next: TMessagePlayer;
    Key: WideString;
    Kind: Byte;
    Gap11: array[0..2] of Byte;
    ImageNameOverride: WideString;
    NotificationSoundKind: Integer;
    Turn: Integer;
    Text: WideString;
    Targets: array[0..2] of TPlayerMessageTarget;
    Button: TGraphButtonGI;
    WasRead: Boolean;
    NotificationSoundPlayed: Boolean;
    Gap42: array[0..1] of Byte;
    constructor Create;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    function GetNormalImageName: WideString;
    function GetActiveImageName: WideString;
    function GetPressedImageName: WideString;
  end;
var
  MainMenuScreen: TfMainForm;
  NewGameScreen: TfGameSettings2;
  IntroductionScreen: TfIntroduction;
  HangarScreen: TfHangar;
  PlanetScreen: TfPlanet;
  UninhabitedPlanetScreen: TfPlanetNO;
  PlanetQuestScreen: TfPlanetQuest;
  RuinsTalkScreen: TfRuinsTalk;
  ArcadeBattleScreen: TfAB;
  EquipmentShopScreen: TfEquipmentShop;
  GoodsShopScreen: TfGoodsShop2;
  GovernmentScreen: TfGov;
  InfoScreen: TfInfo;
  RangerRatingScreen: TfRating2;
  RewardsScreen: TfRewards;
  ShipScreen: TfShip2;
  TalkScreen: TfTalk;
  ScannerScreen: TfScaner;
  StarMapScreen: TfStarMap;
  FilmScreen: TfFilm;
  GalaxyScreen: TfGalaxy2;
  JumpScreen: TfJump;
  LoadScreen: TfLoad;
  SaveManagerScreen: TfSaveManager;
  GameLoadScreen: TfGameLoad;
  GameMenuScreen: TfGameMenu;
  SettingsScreen: TfCfgSettings;
  GameEndScreen: TfGameEnd;
  AboutScreen: TfAbout;
  ScoreScreen: TfScore;
  SelectFaceScreen: TfSelectFace;
  SpaceObjectUiLoop: TMessageLoopGI;
  JournalScreen: TfJournal;
  LoadRobotScreen: TfLoadRobot;
  LoadQuestScreen: TfLoadQuest;
  LoadArcadeScreen: TfLoadAB;
  AchievementsScreen: TfAchievements;
  SpaceViewPosition: TPointF;
  FilmCameraFollow: Boolean;
  TalkShip: TShip;
  TalkPlanet: TPlanet;
  TalkScripted: Boolean;
  TalkType: Byte;
  TalkAmount: Integer;
  TalkResponse: Byte;
  TalkText: WideString;
  ScriptUseItem: TItem;
  ScriptItemContextStack: TList;
  ScriptItemInfoContextStack: TList;
  ScriptActionShipStack: TList;
  ScriptActionObject1Stack: TList;
  ScriptActionObject2Stack: TList;
  ScriptActionParamStack: TList;
  ScriptActionTypeStack: TList;
  ScreenLoadMode: Byte;
  ScriptTemplates: TList;
  SharedScriptVariables: TVarArrayEC;
  GlobalScriptVariables: TVarArrayEC;
  ScriptTemplateStartRequested: Boolean;
  LastLoadedPlayerName: WideString;
  ReloadScriptTemplates: Boolean = True;
  ReloadModsRequested: Boolean = False;
  StandaloneQuestMode: Boolean = False;
  ScannerTarget: TObject = nil;
  ScriptDialogIndex: Integer = -1;
  AwardSubject: TObject = nil;
  PlayerStarDayPrepared: Boolean = False;
  PreviousFilmActivity: Cardinal = 0;
  FilmSoundEffectsEnabled: Boolean = True;
  TurnCalculationThread: TThreadCalc = nil;
  DefaultArcadeLaserEffect: WideString = 'Laser.W1';
  DefaultArcadeHitEffect: WideString = 'Anim.H1';
  DefaultArcadeExplosionEffect: WideString = 'Anim.E1';
  FilmHistory: TFilmFile = nil;
  CacheLoader: TCacheLoader = nil;
  SaveManagerMode: TSaveManagerMode = smmLoad;
  TalkRequestEvent: Cardinal = 0;
  TalkCompletedEvent: Cardinal = 0;
  ScriptUiRequestEvent: Cardinal = 0;
  ScriptUiAbortEvent: Cardinal = 0;
  PlanetRenderTemplates: TList = nil;
  MinimapFrameCounter: Integer = 0;
  Skip1C: Boolean = False;
  SkipVideo: Boolean = False;
  SkipIntro: Boolean = False;
  NewGameGenerationThread: TThreadCreateNewGame;
  ShownPlayerTips: Cardinal;
  StarMapWeaponPanelOpen: Boolean;
  PrimaryFilm: TEFilm;
  SecondaryFilm: TEFilm;
  TrailingFilmEffects: TEFilmEnd;
  SpaceProcess: TProcessSE;
  ActiveLoadBuffer: TBufEC;
  PersistentPlayerMessageLock: TCriticalSection;
  FirstPersistentPlayerMessage: TMessagePlayer;
  LastPersistentPlayerMessage: TMessagePlayer;
  ArcadeExplosionSounds: array of WideString;
  ArcadeItemSounds: array of WideString;
  ArcadeHitSounds: array of WideString;
  ArcadeWeaponFirstSounds: array[0..17] of WideString;
  ArcadeWeaponLoopSounds: array[0..17] of WideString;
  ArcadeWeaponLoopTicks: array[0..17] of Integer;
  RaceShipTemplates: array[0..7] of array[0..5] of TObjectSE;
  BlazerShipTemplates: array[0..7] of TObjectSE;
  KellerShipTemplates: array[0..7] of TObjectSE;
  TerronShipTemplates: array[0..7] of TObjectSE;
  PirateClanShipTemplates: array[0..7] of TObjectSE;
  PlanetSpaceTemplates: array of TPlanetSpaceTemplate;
type
  TRobotMap = record
    Id: Integer;
    Name: WideString;
    Group: Integer;
    Access: Integer;
    Side: Integer;
    Length: Integer;
    Map: WideString;
    PlanetRace: TOwnerMask;
    PlayerRace: TOwnerMask;
    PlayerStatus: TRobotMapPlayerStatuses;
    Gap1F: array[0..0] of Byte;
    MinWins: Integer;
    MaxWins: Integer;
    Reiteration: Integer;
    ReinforcementsDisabled: Boolean;
    Terron: Boolean;
    Demo: Boolean;
    AfterLiberation: Boolean;
    GovTextStart: WideString;
    GovTextWin: WideString;
    GovTextLoss: WideString;
    RobotsStart: WideString;
    RobotsWin: WideString;
    RobotsLoss: WideString;
    FromAuthor: WideString;
    PlayerPlayCount: Integer;
  end;
var
  UselessItemRemainsCount: Integer;
  RobotMapDefinitions: array of TRobotMap;
type
  PointerToTPlanetAdvtGroup = ^TPlanetAdvtGroup;
  TShipGreetingsInfo = record
    Name: WideString;
    Priority: Integer;
    AutoTalk: Byte;
    FlyType: Byte;
    ShipType: TGreetingMask;
    Relations: TGreetingMask;
    ShipRace: TOwnerMask;
    PlayerRace: TOwnerMask;
    ShipRaceIsPlayerRace: Byte;
    PlayerAttackGoodShip: Byte;
    InFear: Byte;
    ShipBadFlyToShip: Byte;
    ShipBadType: TGreetingMask;
    ShipBadRace: TOwnerMask;
    ShipFlyToPlayer: Byte;
    PlayerFlyToShip: Byte;
    PlayerIsShipBad: Byte;
    ShipTurnBeforeEndOrder: TGreetingCountMask;
    PlayerTurnBeforeEndOrder: TGreetingCountMask;
    ShipBadTurnBeforeEndOrder: TGreetingCountMask;
    ShipStatus: TGreetingMask;
    PlayerStatus: TGreetingMask;
    ShipStrength: TGreetingMask;
    PlayerStrength: TGreetingMask;
    ShipStructure: TGreetingMask;
    PlayerStructure: TGreetingMask;
    ShipRating: TGreetingMask;
    PlayerRating: TGreetingMask;
    ShipRank: TGreetingMask;
    PlayerRank: TGreetingMask;
    RatingShipWithPlayer: TGreetingMask;
    RankShipWithPlayer: TGreetingMask;
    StrengthShipWithPlayer: TGreetingMask;
    Goods: Byte;
    ShipGoodsCnt: TGreetingMask;
    PlayerGoodsCnt: TGreetingMask;
    ShipHaveGoods: Byte;
    PlayerHaveGoods: Byte;
    ShipGoodsTypeCnt: TGreetingCountMask;
    PlayerGoodsTypeCnt: TGreetingCountMask;
    ShipMayScanPlayer: Byte;
    RangerInCurStar: TGreetingCountMask;
    PirateInCurStar: TGreetingCountMask;
    KlingInCurStar: TGreetingCountMask;
    WarriorInCurStar: TGreetingCountMask;
    TransportInCurStar: TGreetingCountMask;
    LastPlanetRace: TOwnerMask;
    LastPlanetRelations: TGreetingMask;
    LastPlanetGoodsCnt: TGreetingMask;
    LastPlanetGoodsSale: TGreetingMask;
    LastPlanetGoodsBuy: TGreetingMask;
    LastPlanetIsHomePlanet: Byte;
    LastPlanetRaceIsShipRace: Byte;
    LastPlanetRaceIsPlayerRace: Byte;
    LastPlanetEconomy: TGreetingMask;
    LastPlanetGovernment: TGreetingMask;
    LastPlanetInCurStar: Byte;
    LastPlanetDistToShipInTurn: TGreetingCountMask;
    RangerInLastPlanetStar: TGreetingCountMask;
    PirateInLastPlanetStar: TGreetingCountMask;
    KlingInLastPlanetStar: TGreetingCountMask;
    WarriorInLastPlanetStar: TGreetingCountMask;
    TransportInLastPlanetStar: TGreetingCountMask;
    ToPlanetRace: TOwnerMask;
    ToPlanetRelations: TGreetingMask;
    ToPlanetGoodsCnt: TGreetingMask;
    ToPlanetGoodsSale: TGreetingMask;
    ToPlanetGoodsBuy: TGreetingMask;
    ToPlanetIsHomePlanet: Byte;
    ToPlanetRaceIsShipRace: Byte;
    ToPlanetRaceIsPlayerRace: Byte;
    ToPlanetEconomy: TGreetingMask;
    ToPlanetGovernment: TGreetingMask;
    ToPlanetIsLastPlanet: Byte;
    ToPlanetRaceIsLastPlanetRace: Byte;
    HomePlanetInToStar: Byte;
    HomePlanetInCurStar: Byte;
    ToStarControlByKling: Byte;
    ToStarInBattle: Byte;
    RangerInToStar: TGreetingCountMask;
    PirateInToStar: TGreetingCountMask;
    KlingInToStar: TGreetingCountMask;
    WarriorInToStar: TGreetingCountMask;
    TransportInToStar: TGreetingCountMask;
    Gap6F: array[0..0] of Byte;
    ItemType: WideString;
    ShipNeedInItem: Byte;
    ToShipType: TGreetingMask;
    ToShipRace: TOwnerMask;
    ToShipInPlanet: Byte;
    ToShipBad: Byte;
    ToShipRelations: TGreetingMask;
    RankShipWithPlayerExtra: TGreetingMask;
    PlayerPirateRank: TGreetingMask;
    Female: Byte;
    ToStarControlByPirates: Byte;
    PirateClanInCurStar: TGreetingCountMask;
    PirateClanInToStar: TGreetingCountMask;
    CoalitionAlreadyDefeated: Byte;
    DominatorsAlreadyDefeated: Byte;
  end;
  TGovGreetingsInfo = record
    Name: WideString;
    Priority: Integer;
    PlayerRace: TOwnerMask;
    PlayerStatus: TGreetingMask;
    PlayerRating: TGreetingMask;
    PlayerRank: TGreetingMask;
    Goods: Byte;
    CurPlanetRace: TOwnerMask;
    CurPlanetRaceIsPlayerRace: Byte;
    CurPlanetRelations: TGreetingMask;
    CurPlanetGoodsPermit: Byte;
    CurPlanetGoodsCnt: TGreetingMask;
    CurPlanetGoodsSale: TGreetingMask;
    CurPlanetGoodsBuy: TGreetingMask;
    CurPlanetEconomy: TGreetingMask;
    CurPlanetGovernment: TGreetingMask;
    RangerInCurStar: TGreetingCountMask;
    PirateInCurStar: TGreetingCountMask;
    KlingInCurStar: TGreetingCountMask;
    WarriorInCurStar: TGreetingCountMask;
    TransportInCurStar: TGreetingCountMask;
    CurStarInBattle: Byte;
    ToPlanetRace: TOwnerMask;
    ToPlanetRaceIsPlayerRace: Byte;
    ToPlanetRaceIsCurPlanetRace: Byte;
    ToPlanetRelations: TGreetingMask;
    ToPlanetGoodsPermit: Byte;
    ToPlanetGoodsCnt: TGreetingMask;
    ToPlanetGoodsSale: TGreetingMask;
    ToPlanetGoodsBuy: TGreetingMask;
    ToPlanetEconomy: TGreetingMask;
    ToPlanetGovernment: TGreetingMask;
    ToPlanetInCurStar: Byte;
    RangerInToStar: TGreetingCountMask;
    PirateInToStar: TGreetingCountMask;
    KlingInToStar: TGreetingCountMask;
    WarriorInToStar: TGreetingCountMask;
    TransportInToStar: TGreetingCountMask;
    ToStarControlByKling: Byte;
    ToStarInBattle: Byte;
    CurPlanetPirateClan: Byte;
    CurStarInBattlePirates: Byte;
    PirateClanInCurStar: TGreetingCountMask;
    PirateClanInToStar: TGreetingCountMask;
    ToStarControlByPirates: Byte;
    CoalitionAlreadyDefeated: Byte;
    DominatorsAlreadyDefeated: Byte;
    PlayerPirateRank: TGreetingMask;
    Gap42: array[0..1] of Byte;
  end;
  TPlanetAdvtUnit = record
    Name: WideString;
    Image1: WideString;
    Image2: WideString;
    War: Integer;
    Goods: Byte;
    Owner: TOwnerMask;
    Gap12: array[0..1] of Byte;
  end;
  TPlanetAdvtList = record
    Key: Integer;
    Indices: array of Integer;
  end;
  TPlanetAdvtGroup = record
    Image1: WideString;
    Image2: WideString;
    Position: TPoint;
    Adverts: array of TPlanetAdvtUnit;
    Lists: array of TPlanetAdvtList;
  end;
  PPlanetAdvertDefinition = PointerToTPlanetAdvtGroup;
var
  ShipGreetingDefinitions: array of TShipGreetingsInfo;
  ShipGreetingCount: Integer;
  GovernmentGreetingDefinitions: array of TGovGreetingsInfo;
  GovernmentGreetingCount: Integer;
  PlanetAdvertDefinitions: array of TPlanetAdvtGroup;
procedure InitializeScriptHostRuntime;
procedure FinalizeScriptHostRuntime;
procedure InitializeGlobalUiRuntime;
function FindMessageLoop(Name: WideString): TMessageLoopGI;
procedure FinalizeGlobalUiRuntime;
procedure ResetScriptHostRuntimeState;
procedure RecreateSpaceProcess(const ConfigName: WideString);
procedure RunMainScreenStateLoop;
procedure SwapTurnFilms;
procedure ClearPersistentPlayerMessages;
function CountPersistentPlayerMessages: Integer;
function IsPersistentPlayerMessageQueued(MessageEntry: TMessagePlayer; SkipLock: Boolean): Boolean;
procedure RemovePersistentPlayerMessage(MessageEntry: TMessagePlayer; SkipLock: Boolean);
function RemovePlayerMessagesExceptKinds(
    Key: WideString;
    ExcludedKinds: TPlayerMessageKindSet;
    SkipLock: Boolean
): Boolean;
function FindPlayerBubbleByText(const Text: WideString; SkipLock: Boolean): TMessagePlayer;
function FindPlayerBubbleByKey(const Key: WideString; SkipLock: Boolean): TMessagePlayer;
procedure RemovePlayerBubbleByKey(const Key: WideString);
procedure RemovePlayerBubblePages(const Prefix: WideString; FirstPage: Integer);
function FindPlayerMessageExceptKinds(
    const Key: WideString;
    ExcludedKinds: TPlayerMessageKindSet;
    SkipLock: Boolean
): TMessagePlayer;
function CreatePersistentPlayerMessage: TMessagePlayer;
function AddOrUpdatePlayerBubble(
    Kind: Byte;
    Turn: Integer;
    const Text: WideString;
    const Key: WideString
): TMessagePlayer;
procedure PruneExpiredPersistentPlayerMessages;
function FindScriptTemplateIndex(const Name: WideString): Integer;
procedure CollectInactiveScriptTemplates(Dest: TList);
function ShowPlayerTipOnce(Index: Integer): Boolean;
function HasShownPlayerTip(Index: Integer): Boolean;
function SelectSpaceImageTemplateFromSeed(Kind: Integer; Seed: Cardinal): Integer;
function SelectSpaceImageTemplate(Kind: Integer): Integer;
procedure HandleRuntimeExitCheck1;
procedure HandleRuntimeExitCheck2;
function ParseRobotMapRaceMask(Text: WideString): TOwnerMask;
procedure InitializeRobotMapDefinitions;
function FindRobotMapById(MapId: Integer): Integer;
function FindPlanetSpaceTemplateIndex(Style: Integer; StyleVariant: Integer): Integer;
procedure InitializeShipGreetingDefinitions;
procedure InitializeGovernmentGreetingDefinitions;
procedure InitializePlanetAdvertDefinitions;
function GetInnermostScreenLoop: TMessageLoopGI;
procedure LinkRecoveredTypes;
implementation
uses
  aPacket,
  aSaveLoad,
  aScript,
  aPath,
  Robot,
  aConst,
  aPlayer,
  GI_Main,
  PopUp,
  EC_CacheGAI,
  EC_Thread,
  EC_Cache,
  aGalaxy,
  aMyFunction,
  EC_BlockPar,
  GR_Main,
  EC_Str,
  GlobalsV,
  Math,
  SysUtils,
  Windows;
// @unit-initialization $87784C
// @unit-finalization $538C4C
procedure InitializeScriptHostRuntime;
begin
  PersistentPlayerMessageLock := TCriticalSection.Create;
  SaveLoadLock := TCriticalSection.Create;
  GetLastError;
  InitializePathNodePool;
  FilmHistory := TFilmFile.Create;
  TalkRequestEvent := CreateEvent(nil, False, False, nil);
  TalkCompletedEvent := CreateEvent(nil, False, False, nil);
  ScriptUiRequestEvent := CreateEvent(nil, True, False, nil);
  ScriptUiAbortEvent := CreateEvent(nil, True, False, nil);
  TurnCalculationThread := TThreadCalc.Create;
  TurnCalculationThread.SetPriority(2);
  ScriptTemplates := TList.Create;
  GlobalScriptVariables := TVarArrayEC.Create;
  SharedScriptVariables := TVarArrayEC.Create;
  GlobalScriptVariables.Add('GRunFrom', vkInt).SetInt(0);
  GlobalScriptVariables.Add('GRunStar', vkDword).SetInt(0);
  InitializeScriptEngine;
end;
procedure FinalizeScriptHostRuntime;
var
  Race, Kind, Series: Byte;
  Item: TObject;
  Index: Integer;
begin
  FinalizeScriptEngine;
  if GlobalScriptVariables <> nil then
  begin
    GlobalScriptVariables.Free;
    GlobalScriptVariables := nil;
  end;
  if SharedScriptVariables <> nil then
  begin
    SharedScriptVariables.Free;
    SharedScriptVariables := nil;
  end;
  if ScriptTemplates <> nil then
  begin
    for Index := 0 to ScriptTemplates.Count - 1 do
    begin
      Item := ScriptTemplates[Index];
      Item.Free;
    end;
    ScriptTemplates.Free;
    ScriptTemplates := nil;
  end;
  if TurnCalculationThread <> nil then
  begin
    TurnCalculationThread.Free;
    TurnCalculationThread := nil;
  end;
  if TalkRequestEvent <> 0 then
  begin
    CloseHandle(TalkRequestEvent);
    TalkRequestEvent := 0;
  end;
  if TalkCompletedEvent <> 0 then
  begin
    CloseHandle(TalkCompletedEvent);
    TalkCompletedEvent := 0;
  end;
  if ScriptUiRequestEvent <> 0 then
  begin
    CloseHandle(ScriptUiRequestEvent);
    ScriptUiRequestEvent := 0;
  end;
  if ScriptUiAbortEvent <> 0 then
  begin
    CloseHandle(ScriptUiAbortEvent);
    ScriptUiAbortEvent := 0;
  end;
  for Race := 0 to 7 do
  begin
    for Kind := 0 to 5 do
      if RaceShipTemplates[Race, Kind] <> nil then
        ReleaseSpaceObject(RaceShipTemplates[Race, Kind]);
    if PirateClanShipTemplates[Race] <> nil then
      ReleaseSpaceObject(PirateClanShipTemplates[Race]);
  end;
  for Series := 0 to 7 do
    if Series <> 0 then
    begin
      if BlazerShipTemplates[Series] <> nil then
        ReleaseSpaceObject(BlazerShipTemplates[Series]);
      if KellerShipTemplates[Series] <> nil then
        ReleaseSpaceObject(KellerShipTemplates[Series]);
      if TerronShipTemplates[Series] <> nil then
        ReleaseSpaceObject(TerronShipTemplates[Series]);
    end;
  if FilmHistory <> nil then
  begin
    FilmHistory.Free;
    FilmHistory := nil;
  end;
  FinalizePathNodePool;
  if SaveLoadLock <> nil then
  begin
    SaveLoadLock.Free;
    SaveLoadLock := nil;
  end;
  if PersistentPlayerMessageLock <> nil then
  begin
    PersistentPlayerMessageLock.Free;
    PersistentPlayerMessageLock := nil;
  end;
end;
var
  ScriptVariableTypeNames: array[0..10] of WideString = (
      'Unknown',
      'Int',
      'DW',
      'Float',
      'Str',
      'ExternFun',
      'LibraryFun',
      'Fun',
      'Class',
      'Array',
      'Ref'
  ); // @addr $87AEA8 Native initialization descriptors at $538D8C..$538DDC.
procedure InitializeGlobalUiRuntime;
var
  Race: Byte;
  Index, TemplateIndex, Count: Integer;
  SatelliteTemplate: TSputnikTempl;
  PlanetTemplate: TPlanetTempl;
  Section: TBlockParEC;
  Series, Kind: Byte;
  ScriptTemplate: TScriptTemplUnit;
  Text, WarningText: WideString;
  ShipBlock: TBlockParEC;
  Variable, Other: TVarEC;
begin
  CacheLoader := TCacheLoader.Create;
  InitializeSaveWriter;
  RangerFontName := 'Font.2Ranger';
  MiniFontName := 'Font.2Mini';
  SmallFontName := 'Font.2Small';
  SmallBoldFontName := 'Font.2SmallBold';
  NormalFontName := 'Font.2Normal';
  NormalBoldFontName := 'Font.2NormalBold';
  BigFontName := 'Font.2Big';
  HugeFontName := 'Font.2Huge';
  IntroFontName := 'Font.2Intro';
  AuthorsFontName := 'Font.2Authors';
  SmoothSmallFontName := 'Font.Verdana8';
  SmoothSmallBoldFontName := 'Font.Verdana8bold';
  SmoothNormalFontName := 'Font.Verdana9';
  SmoothNormalBoldFontName := 'Font.Verdana9bold';
  SmoothBigFontName := 'Font.Verdana11';
  SmoothHugeFontName := 'Font.Verdana12';
  SmoothIntroFontName := 'Font.Verdana13';
  if UserSettingsConfig.CountParamsByPath('ChangeAutoPilot') > 0 then
    ChangeAutoPilot :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('ChangeAutoPilot'));
  if UserSettingsConfig.CountParams('AltResolutionSwitch') > 0 then
    AltResolutionSwitch :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AltResolutionSwitch'));
  if UserSettingsConfig.CountParamsByPath('DisableAutoPilot') > 0 then
    DisableAutoPilot :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('DisableAutoPilot'));
  UiRuntimeFlag := True;
  if UserSettingsConfig.CountParamsByPath('PQuestStyle') > 0 then
    QuestStyleIndex :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('PQuestStyle'));
  if UserSettingsConfig.CountParamsByPath('PQuestAnim') > 0 then
    QuestPageAnimationEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('PQuestAnim'));
  if UserSettingsConfig.CountParamsByPath('DefaultOrder') > 0 then
    DefaultOrder := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('DefaultOrder'));
  if UserSettingsConfig.CountParamsByPath('RightClickOnShip') > 0 then
    RightClickOnShip :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RightClickOnShip'));
  if UserSettingsConfig.CountParamsByPath('DoNotChangeMusicInBattle') > 0 then
    DoNotChangeMusicInBattle :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('DoNotChangeMusicInBattle'));
  if UserSettingsConfig.CountParamsByPath('ViewFollowShip') > 0 then
    ViewFollowShip :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('ViewFollowShip'));
  if UserSettingsConfig.CountParamsByPath('ViewPathLength') > 0 then
    ViewPathLength :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('ViewPathLength'));
  if UserSettingsConfig.CountParamsByPath('TurnSaveStep') > 0 then
    TurnSaveStep :=
        Min(365, ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('TurnSaveStep')));
  if UserSettingsConfig.CountParamsByPath('QuickSaveExtraSlots') > 0 then
    QuickSaveExtraSlots :=
        Min(
            9,
            ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('QuickSaveExtraSlots'))
        );
  if UserSettingsConfig.CountParamsByPath('MaxPlayerNews') > 0 then
    MaxPlayerNews :=
        Min(100, ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('MaxPlayerNews')));
  if UserSettingsConfig.CountParamsByPath('ForsageDeactivatePercent') > 0 then
    AfterburnerStopCondition :=
        Min(
            100,
            ExtractDigitsToIntW(
                UserSettingsConfig.GetParamByPathOrMarker('ForsageDeactivatePercent')
            )
        );
  if UserSettingsConfig.CountParamsByPath('MaxSearchResult') > 0 then
    MaxSearchResult :=
        Min(100, ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('MaxSearchResult')));
  if UserSettingsConfig.CountParamsByPath('ClickAutoCloseForm') > 0 then
    ClickAutoCloseForm :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('ClickAutoCloseForm'));
  if UserSettingsConfig.CountParamsByPath('ActionDoubleClick') > 0 then
    ActionDoubleClick :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('ActionDoubleClick'));
  if UserSettingsConfig.CountParamsByPath('SkipGiper') > 0 then
    SkipGiper := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SkipGiper'));
  Text := 'est';
  if UserSettingsConfig.CountParamsByPath(Text) > 0 then
    EstOptionEnabled := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker(Text));
  if UserSettingsConfig.CountParamsByPath('SendRecordOff') > 0 then
    SendRecordOff := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SendRecordOff'));
  if UserSettingsConfig.CountParamsByPath('Wind') > 0 then
    Wind := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('Wind'));
  if UserSettingsConfig.CountParamsByPath('Skip1C') > 0 then
    Skip1C := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('Skip1C'));
  if UserSettingsConfig.CountParamsByPath('SkipVideo') > 0 then
    SkipVideo := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SkipVideo'));
  if UserSettingsConfig.CountParamsByPath('SkipIntro') > 0 then
    SkipIntro := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SkipIntro'));
  if UserSettingsConfig.CountParamsByPath('ShipTail') > 0 then
    ShipTail := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('ShipTail'));
  if UserSettingsConfig.CountParamsByPath('AnimCaptain') > 0 then
    AnimCaptain := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimCaptain'));
  if UserSettingsConfig.CountParamsByPath('AnimItem') > 0 then
    AnimItem := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimItem'));
  if UserSettingsConfig.CountParamsByPath('BGImage') > 0 then
    BGImage := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('BGImage'));
  if UserSettingsConfig.CountParamsByPath('Comet') > 0 then
    Comet := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('Comet'));
  if UserSettingsConfig.CountParamsByPath('AnimShipFull') > 0 then
    AnimShipFull := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimShipFull'));
  if UserSettingsConfig.CountParamsByPath('AnimCity') > 0 then
    AnimCity := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimCity'));
  if UserSettingsConfig.CountParamsByPath('AnimGov') > 0 then
    AnimGov := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('AnimGov'));
  if UserSettingsConfig.CountParamsByPath('AnimMenuShip') > 0 then
    AnimMenuShip := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimMenuShip'));
  if UserSettingsConfig.CountParamsByPath('AnimStar') > 0 then
    AnimStar := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimStar'));
  if UserSettingsConfig.CountParamsByPath('AnimHangar') > 0 then
    AnimHangar := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimHangar'));
  if UserSettingsConfig.CountParamsByPath('CircleAction') > 0 then
    CircleAction := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('CircleAction'));
  if UserSettingsConfig.CountParamsByPath('StaticBackground') > 0 then
    StaticBackground :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('StaticBackground'));
  if UserSettingsConfig.CountParamsByPath('ScrollTime') > 0 then
    ScrollTime := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('ScrollTime')));
  if UserSettingsConfig.CountParamsByPath('ScrollStep') > 0 then
    ScrollStep := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('ScrollStep')));
  if UserSettingsConfig.CountParamsByPath('ScrollSense') > 0 then
    ScrollSense := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('ScrollSense')));
  if UserSettingsConfig.CountParamsByPath('FilmSpeed') > 0 then
    FilmSpeed := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('FilmSpeed')));
  ScrollInteriorRect :=
      Classes.Rect(
          ScrollSense,
          ScrollSense,
          GameScreenWidth - ScrollSense,
          GameScreenHeight - ScrollSense
      );
  if not IsInstallFeatureEnabled('AnimGov') then
    AnimGov := 0;
  if not IsInstallFeatureEnabled('AnimCaptain') then
    AnimCaptain := False;
  if not IsInstallFeatureEnabled('Video') then
  begin
    SkipVideo := True;
    SkipIntro := True;
  end;
  if UserSettingsConfig.CountParamsByPath('BGOCount') > 0 then
    BGOCount := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('BGOCount')));
  if UserSettingsConfig.CountParamsByPath('BGOTime') > 0 then
    BGOTime := StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('BGOTime')));
  if UserSettingsConfig.CountParamsByPath('MaxFilmStepSkip') > 0 then
    MaxFilmStepSkip :=
        StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('MaxFilmStepSkip')));
  if UserSettingsConfig.CountParamsByPath('CountFilmSave') > 0 then
    FilmHistoryLimit :=
        Max(1, StrToInt(AnsiString(UserSettingsConfig.GetParamByPathOrMarker('CountFilmSave'))));
  if UserSettingsConfig.CountParamsByPath('SputnikShow') > 0 then
    SputnikShow := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('SputnikShow'));
  if UserSettingsConfig.CountParamsByPath('SpaceImage') > 0 then
    SpaceImage := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('SpaceImage'));
  if UserSettingsConfig.CountParamsByPath('ShowFPS') > 0 then
    ShowFrameRate := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('ShowFPS'));
  if UserSettingsConfig.CountParamsByPath('FontGalaxy') > 0 then
    GalaxyMapFontChoice :=
        TGalaxyMapFontChoice(
            ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('FontGalaxy'))
        );
  if UserSettingsConfig.CountParamsByPath('FontDialog') > 0 then
    FontDialog := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('FontDialog'));
  if UserSettingsConfig.CountParamsByPath('FontQuest') > 0 then
    FontQuest := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('FontQuest'));
  if UserSettingsConfig.CountParamsByPath('FontSmooth') > 0 then
    FontSmoothingEnabled :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('FontSmooth'));
  if UserSettingsConfig.CountParamsByPath('ScreenShotType') > 0 then
    ScreenshotFormat :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('ScreenShotType'));
  if UserSettingsConfig.CountParamsByPath('ScreenShotQuality') > 0 then
    ScreenshotJpegQuality :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('ScreenShotQuality'));
  if UserSettingsConfig.CountParamsByPath('DynamicTipsPos') > 0 then
    DynamicTipsPos :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('DynamicTipsPos'));
  if UserSettingsConfig.CountParamsByPath('BackgroundShade') > 0 then
    BackgroundShade :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('BackgroundShade'));
  if UserSettingsConfig.CountParamsByPath('BackgroundBlur') > 0 then
    BackgroundBlur :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('BackgroundBlur'));
  if UserSettingsConfig.CountParamsByPath('BackgroundGrayscale') > 0 then
    BackgroundGrayscale :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('BackgroundGrayscale'));
  if UserSettingsConfig.CountParamsByPath('PlanetClouds') > 0 then
    PlanetClouds := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('PlanetClouds'));
  if UserSettingsConfig.CountParamsByPath('PlanetAtm') > 0 then
    PlanetAtm := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('PlanetAtm'));
  if UserSettingsConfig.CountParamsByPath('AnimChangeForm') > 0 then
    AnimChangeForm :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimChangeForm'));
  if UserSettingsConfig.CountParamsByPath('AnimMainFon') > 0 then
    AnimMainFon := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('AnimMainFon'));
  if UserSettingsConfig.CountParamsByPath('BeginCalcNextTurn') > 0 then
    BeginCalcNextTurn :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('BeginCalcNextTurn')) / 100;
  if BeginCalcNextTurn < 0 then
    BeginCalcNextTurn := 0
  else if BeginCalcNextTurn > 1 then
    BeginCalcNextTurn := 1;
  if UserSettingsConfig.CountParamsByPath('HalfGovAnim') > 0 then
    HalfGovAnim := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('HalfGovAnim'));
  if UserSettingsConfig.CountParamsByPath('UseTablesForGov') > 0 then
    UseTablesForGov :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('UseTablesForGov'));
  if UserSettingsConfig.CountParamsByPath('RobotShowStencilShadows') > 0 then
    RobotSettings.ShowStencilShadows :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotShowStencilShadows'));
  if UserSettingsConfig.CountParamsByPath('RobotShowProjShadows') > 0 then
    RobotSettings.ShowProjShadows :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotShowProjShadows'));
  if UserSettingsConfig.CountParamsByPath('RobotSelectEx') > 0 then
    RobotSettings.SelectEx :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotSelectEx'));
  if UserSettingsConfig.CountParamsByPath('RobotLandTexturesGloss') > 0 then
    RobotSettings.LandTexturesGloss :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotLandTexturesGloss'));
  if UserSettingsConfig.CountParamsByPath('RobotObjTexturesGloss') > 0 then
    RobotSettings.ObjTexturesGloss :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotObjTexturesGloss'));
  if UserSettingsConfig.CountParamsByPath('RobotSoftwareCursor') > 0 then
    RobotSettings.SoftwareCursor :=
        ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotSoftwareCursor'));
  if UserSettingsConfig.CountParamsByPath('RobotSky') > 0 then
    RobotSettings.Sky := ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RobotSky'));
  if UserSettingsConfig.CountParamsByPath('RobotRobotShadow') > 0 then
    RobotSettings.RobotShadow :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RobotRobotShadow'));
  if UserSettingsConfig.CountParamsByPath('RobotSound') > 0 then
    RobotSound := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotSound'));
  if UserSettingsConfig.CountParamsByPath('RobotMusic') > 0 then
    RobotMusic := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotMusic'));
  if UserSettingsConfig.CountParamsByPath('RobotVSync') > 0 then
    RobotVSync := ParseEnabledNameGI(UserSettingsConfig.GetParamByPathOrMarker('RobotVSync'));
  if UserSettingsConfig.CountParamsByPath('RobotFSAASamples') > 0 then
    RobotFSAASamples :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RobotFSAASamples'));
  if UserSettingsConfig.CountParamsByPath('RobotAnisotropy') > 0 then
    RobotAnisotropy :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RobotAnisotropy'));
  if UserSettingsConfig.CountParamsByPath('RobotMaxDistance') > 0 then
    RobotMaxDistance :=
        ExtractDigitsToIntW(UserSettingsConfig.GetParamByPathOrMarker('RobotMaxDistance'));
  if ReloadScriptTemplates then
  begin
    Section := GameDataConfig.GetBlockByPath('Script');
    Count := Section.GetParamCount;
    for Index := 0 to Count - 1 do
    begin
      if FindScriptTemplateIndex(Section.GetParamName(Index)) >= 0 then
        raise Exception.Create('Script name not unique');
      ScriptTemplate := TScriptTemplUnit.Create;
      ScriptTemplate.Name := Section.GetParamName(Index);
      Text := Section.GetParamValue(Index);
      ScriptTemplate.ConfigValue := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
      ScriptTemplate.FileName := ExtractDelimitedPartW(Text, 1, ',');
      ScriptTemplates.Add(ScriptTemplate);
      CompileScriptTemplateCondition(ScriptTemplates.Count - 1);
    end;
    for Index := GlobalScriptVariables.Count - 2 downto 0 do
    begin
      Variable := GlobalScriptVariables.GetItemByNameOrder(Index);
      Other := GlobalScriptVariables.GetItemByNameOrder(Index + 1);
      if Variable.Name = Other.Name then
      begin
        if Variable.RealVType <> Other.RealVType then
        begin
          WarningText :=
              'Warning! Mismatching global variables with same name <'
                  + Variable.Name
                  + '> found! Types are '
                  + ScriptVariableTypeNames[Integer(Variable.RealVType) and $7F]
                  + ' and '
                  + ScriptVariableTypeNames[Integer(Other.RealVType) and $7F];
          if Variable.RealVType = vkEmpty then
          begin
            WarningText :=
                WarningText
                    + ', '
                    + ScriptVariableTypeNames[Integer(Variable.RealVType) and $7F]
                    + ' will be discarded';
            GlobalScriptVariables.Remove(Variable);
          end
          else
          begin
            WarningText :=
                WarningText
                    + ', '
                    + ScriptVariableTypeNames[Integer(Other.RealVType) and $7F]
                    + ' will be discarded';
            GlobalScriptVariables.Remove(Other);
          end;
          AppendLogLineThreadSafe(AnsiString(WarningText));
        end
        else
        begin
          if Variable.EqualsValue(Other)
              or not (Variable.RealVType in [vkInt, vkDword, vkFloat, vkString]) then
            GlobalScriptVariables.Remove(Other)
          else
          begin
            WarningText :=
                'Warning! Mismatching global variables with same name <'
                    + Variable.Name
                    + '> found! Initial values are '
                    + Variable.GetString
                    + ' and '
                    + Other.GetString
                    + '. Value '
                    + Variable.GetString
                    + ' will be used';
            GlobalScriptVariables.Remove(Other);
          end;
        end;
      end;
    end;
  end;
  if ReloadScriptTemplates then
  begin
    for Race := 0 to 7 do
    begin
      ShipBlock := GameDataConfig.GetBlockByPath('SE.Ship').FindBlock(OwnerInfo[Race].InternalName);
      for Kind := 0 to 5 do
        RaceShipTemplates[Race, Kind] := nil;
      PirateClanShipTemplates[Race] := nil;
      if ShipBlock <> nil then
      begin
        if ShipBlock.CountBlocks('Ranger') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 0],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Ranger',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('Warrior') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 1],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Warrior',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('Pirate') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 2],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Pirate',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('Transport') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 3],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Transport',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('Liner') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 4],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Liner',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('Diplomat') > 0 then
          RetainSpaceObject(
              RaceShipTemplates[Race, 5],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.Diplomat',
                  Classes.Point(0, 0)
              )
          );
        if ShipBlock.CountBlocks('PirateClan') > 0 then
          RetainSpaceObject(
              PirateClanShipTemplates[Race],
              CreateSpaceObjectByName(
                  'Ship2',
                  'Ship.' + OwnerInfo[Race].InternalName + '.PirateClan',
                  Classes.Point(0, 0)
              )
          );
      end;
    end;
    Index := 1;
    for Series := 0 to 7 do
      if Series <> 0 then
      begin
        RetainSpaceObject(
            BlazerShipTemplates[Series],
            CreateSpaceObjectByName(
                'Ship2',
                WideString('Ship.Blazer.B' + IntToStr(Index)),
                Classes.Point(0, 0)
            )
        );
        RetainSpaceObject(
            KellerShipTemplates[Series],
            CreateSpaceObjectByName(
                'Ship2',
                WideString('Ship.Keller.K' + IntToStr(Index)),
                Classes.Point(0, 0)
            )
        );
        RetainSpaceObject(
            TerronShipTemplates[Series],
            CreateSpaceObjectByName(
                'Ship2',
                WideString('Ship.Terron.T' + IntToStr(Index)),
                Classes.Point(0, 0)
            )
        );
        Inc(Index);
      end;
  end;
  Count := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    Section := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockByIndex(Index);
    if Section.CountParams('Image') <= 0 then
      Dec(Count);
  end;
  SetLength(PlanetSpaceTemplates, Count);
  Count := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockCount;
  TemplateIndex := 0;
  for Index := 0 to Count - 1 do
  begin
    Section := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockByIndex(Index);
    if Section.CountParams('Image') > 0 then
    begin
      RetainSpaceObject(
          PlanetSpaceTemplates[TemplateIndex].SpaceObject,
          CreateSpaceObjectByName(
              'Planet',
              'Planet.' + GameDataConfig.GetBlockByPath('SE.Planet').GetBlockNameByIndex(Index),
              Classes.Point(0, 0)
          )
      );
      PlanetSpaceTemplates[TemplateIndex].Radius :=
          StrToInt(AnsiString(Section.GetParam('Radius')));
      PlanetSpaceTemplates[TemplateIndex].Style := 0;
      PlanetSpaceTemplates[TemplateIndex].StyleVariant := 0;
      if Section.CountParams('Style') > 0 then
      begin
        Text := Section.GetParam('Style');
        PlanetSpaceTemplates[TemplateIndex].Style :=
            ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
        if CountDelimitedPartsW(Text, ',') >= 2 then
          PlanetSpaceTemplates[TemplateIndex].StyleVariant :=
              ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
      end;
      Inc(TemplateIndex);
    end;
  end;
  PopupController := TfPopUpController.Create;
  LoadScreen := TfLoad.Create;
  RegisteredScreens[Ord(screenLoad)] := LoadScreen;
  LoadScreen.InitializeFromConfig(UiStyleConfig, 'Load', True);

  LoadScreen.InitializeLayout;

  MainMenuScreen := TfMainForm.Create;
  RegisteredScreens[Ord(screenMainMenu)] := MainMenuScreen;
  MainMenuScreen.InitializeFromConfig(UiStyleConfig, 'MainForm', True);
  PlanetQuestScreen := TfPlanetQuest.Create;
  RegisteredScreens[Ord(screenPlanetQuest)] := PlanetQuestScreen;
  PlanetQuestScreen.InitializeFromConfig(UiStyleConfig, 'PlanetQuest', True);
  GameLoadScreen := TfGameLoad.Create;
  RegisteredScreens[Ord(screenGameLoad)] := GameLoadScreen;
  GameLoadScreen.InitializeFromConfig(UiStyleConfig, 'GameLoad', True);
  NewGameScreen := TfGameSettings2.Create;
  RegisteredScreens[Ord(screenNewGame)] := NewGameScreen;
  NewGameScreen.InitializeFromConfig(UiStyleConfig, 'GameSettings', True);
  IntroductionScreen := TfIntroduction.Create;
  RegisteredScreens[Ord(screenIntroduction)] := IntroductionScreen;
  IntroductionScreen.InitializeFromConfig(UiStyleConfig, 'Introduction', True);
  HangarScreen := TfHangar.Create;
  RegisteredScreens[Ord(screenHangar)] := HangarScreen;
  HangarScreen.InitializeFromConfig(UiStyleConfig, 'Hangar', True);
  PlanetScreen := TfPlanet.Create;
  RegisteredScreens[Ord(screenPlanet)] := PlanetScreen;
  PlanetScreen.InitializeFromConfig(UiStyleConfig, 'Planet', True);
  UninhabitedPlanetScreen := TfPlanetNO.Create;
  RegisteredScreens[Ord(screenPlanetNO)] := UninhabitedPlanetScreen;
  UninhabitedPlanetScreen.InitializeFromConfig(UiStyleConfig, 'PlanetNO', True);
  RuinsTalkScreen := TfRuinsTalk.Create;
  RegisteredScreens[Ord(screenRuinsTalk)] := RuinsTalkScreen;
  RuinsTalkScreen.InitializeFromConfig(UiStyleConfig, 'RuinsTalk', True);
  ArcadeBattleScreen := TfAB.Create;
  RegisteredScreens[Ord(screenArcadeBattle)] := ArcadeBattleScreen;
  ArcadeBattleScreen.InitializeFromConfig(UiStyleConfig, 'AB', True);
  GovernmentScreen := TfGov.Create;
  RegisteredScreens[Ord(screenGovernment)] := GovernmentScreen;
  GovernmentScreen.InitializeFromConfig(UiStyleConfig, 'Gov', True);
  InfoScreen := TfInfo.Create;
  RegisteredScreens[Ord(screenInfo)] := InfoScreen;
  InfoScreen.InitializeFromConfig(UiStyleConfig, 'Info', True);
  RangerRatingScreen := TfRating2.Create;
  RegisteredScreens[Ord(screenRating)] := RangerRatingScreen;
  RangerRatingScreen.InitializeFromConfig(UiStyleConfig, 'Rating', True);
  RewardsScreen := TfRewards.Create;
  RegisteredScreens[Ord(screenRewards)] := RewardsScreen;
  RewardsScreen.InitializeFromConfig(UiStyleConfig, 'Rewards', True);
  ShipScreen := TfShip2.Create;
  RegisteredScreens[Ord(screenShip)] := ShipScreen;
  ShipScreen.InitializeFromConfig(UiStyleConfig, 'Ship', True);
  TalkScreen := TfTalk.Create;
  RegisteredScreens[Ord(screenTalk)] := TalkScreen;
  TalkScreen.InitializeFromConfig(UiStyleConfig, 'Talk', True);
  ScannerScreen := TfScaner.Create;
  RegisteredScreens[Ord(screenScanner)] := ScannerScreen;
  ScannerScreen.InitializeFromConfig(UiStyleConfig, 'Scaner', True);
  StarMapScreen := TfStarMap.Create;
  RegisteredScreens[Ord(screenStarMap)] := StarMapScreen;
  StarMapScreen.InitializeFromConfig(UiStyleConfig, 'StarMap', True);
  FilmScreen := TfFilm.Create;
  RegisteredScreens[Ord(screenFilm)] := FilmScreen;
  FilmScreen.InitializeFromConfig(UiStyleConfig, 'Film', True);
  GalaxyScreen := TfGalaxy2.Create;
  RegisteredScreens[Ord(screenGalaxy)] := GalaxyScreen;
  GalaxyScreen.InitializeFromConfig(UiStyleConfig, 'Galaxy', True);
  JumpScreen := TfJump.Create;
  RegisteredScreens[Ord(screenJump)] := JumpScreen;
  JumpScreen.InitializeFromConfig(UiStyleConfig, 'Jump', True);
  EquipmentShopScreen := TfEquipmentShop.Create;
  RegisteredScreens[Ord(screenEquipmentShop)] := EquipmentShopScreen;
  EquipmentShopScreen.InitializeFromConfig(UiStyleConfig, 'EquipmentShop', True);
  GoodsShopScreen := TfGoodsShop2.Create;
  RegisteredScreens[Ord(screenGoodsShop)] := GoodsShopScreen;
  GoodsShopScreen.InitializeFromConfig(UiStyleConfig, 'GoodsShop', True);
  SaveManagerScreen := TfSaveManager.Create;
  RegisteredScreens[Ord(screenSaveManager)] := SaveManagerScreen;
  SaveManagerScreen.InitializeFromConfig(UiStyleConfig, 'SaveManager', True);
  GameMenuScreen := TfGameMenu.Create;
  RegisteredScreens[Ord(screenGameMenu)] := GameMenuScreen;
  GameMenuScreen.InitializeFromConfig(UiStyleConfig, 'GameMenu', True);
  SettingsScreen := TfCfgSettings.Create;
  RegisteredScreens[Ord(screenSettings)] := SettingsScreen;
  SettingsScreen.InitializeFromConfig(UiStyleConfig, 'CfgSettings', True);
  GameEndScreen := TfGameEnd.Create;
  RegisteredScreens[Ord(screenGameEnd)] := GameEndScreen;
  GameEndScreen.InitializeFromConfig(UiStyleConfig, 'GameEnd', True);
  AboutScreen := TfAbout.Create;
  RegisteredScreens[Ord(screenAbout)] := AboutScreen;
  AboutScreen.InitializeFromConfig(UiStyleConfig, 'About', True);
  ScoreScreen := TfScore.Create;
  RegisteredScreens[Ord(screenScores)] := ScoreScreen;
  ScoreScreen.InitializeFromConfig(UiStyleConfig, 'Score', True);
  SelectFaceScreen := TfSelectFace.Create;
  RegisteredScreens[Ord(screenSelectFace)] := SelectFaceScreen;
  SelectFaceScreen.InitializeFromConfig(UiStyleConfig, 'SelectFace', True);
  JournalScreen := TfJournal.Create;
  RegisteredScreens[Ord(screenJournal)] := JournalScreen;
  JournalScreen.InitializeFromConfig(UiStyleConfig, 'Journal', True);
  LoadRobotScreen := TfLoadRobot.Create;
  RegisteredScreens[Ord(screenLoadRobot)] := LoadRobotScreen;
  LoadRobotScreen.InitializeFromConfig(UiStyleConfig, 'LoadRobot', True);
  LoadQuestScreen := TfLoadQuest.Create;
  RegisteredScreens[Ord(screenLoadQuest)] := LoadQuestScreen;
  LoadQuestScreen.InitializeFromConfig(UiStyleConfig, 'LoadQuest', True);
  LoadArcadeScreen := TfLoadAB.Create;
  RegisteredScreens[Ord(screenLoadArcade)] := LoadArcadeScreen;
  LoadArcadeScreen.InitializeFromConfig(UiStyleConfig, 'LoadAB', True);
  AchievementsScreen := TfAchievements.Create;
  RegisteredScreens[Ord(screenAchievements)] := AchievementsScreen;
  AchievementsScreen.InitializeFromConfig(UiStyleConfig, 'Achievements', True);
  SpaceObjectUiLoop := TMessageLoopGI.Create;
  SpaceObjectUiLoop.InitializeDefaults;
  SpaceObjectUiLoop.ViewportRect :=
      Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
  SpaceObjectUiLoop.UpdateRectsEnabled := False;
  SpaceObjectUiLoop.ContentPanel.SetOrigin(
      Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1)
  );
  SpaceObjectUiLoop.ContentPanel.SetPosition(
      Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1)
  );
  PrimaryFilm := TEFilm.Create;
  SecondaryFilm := TEFilm.Create;
  RecreateSpaceProcess('Process.Normal');
  PlanetRenderTemplates := TList.Create;
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 33;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask052';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light052';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask066';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light066';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 60;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask094';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light094';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask120';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light120';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 70;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask108';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light108';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask140';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light140';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 80;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask124';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light124';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask160';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light160';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 90;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask142';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light142';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask180';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light180';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 100;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask156';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light156';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask200';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light200';
  SatelliteRenderTemplates := TList.Create;
  Index := MinimumSatelliteTemplateRadius;
  while not (Index > MaximumSatelliteTemplateRadius) do
  begin
    SatelliteTemplate := TSputnikTempl.Create;
    SatelliteRenderTemplates.Add(SatelliteTemplate);
    SatelliteTemplate.MaskName :=
        WideString(
            'Bm.Planet.S.Mask0'
                + IntToStr(Index)
                + '?'
                + IntToStr(SatelliteTemplateParameter1)
                + ','
                + IntToStr(SatelliteTemplateParameter2)
        );
    SatelliteTemplate.Radius := Index;
    Inc(Index);
  end;
  Section := GameDataConfig.GetBlock('SpaceImg');
  Count := Section.GetParamCount;
  SetLength(SpaceImageTemplates, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := Section.GetParamValue(Index);
    if CountDelimitedPartsW(Text, ',') < 2 then
      raise Exception.Create('Error in GlobalsInit');
    SpaceImageTemplates[Index].Kind := ExtractDigitsToIntW(Section.GetParamName(Index));
    SpaceImageTemplates[Index].Weight := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
    SpaceImageTemplates[Index].CacheControl := TCGaiControlEC.Create;
    SpaceImageTemplates[Index].CachedData := nil;
    GlobalCache.ResetControl(TCGaiControlEC(SpaceImageTemplates[Index].CacheControl));
    TCGaiControlEC(SpaceImageTemplates[Index].CacheControl)
        .SetCacheKey(ExtractDelimitedPartW(Text, 1, ','));
  end;
  Section := GameDataConfig.GetBlock('StarFieldImg');
  Count := Section.GetParamCount;
  SetLength(StarFieldImageTemplates, Count);
  for Index := 0 to Count - 1 do
  begin
    StarFieldImageTemplates[Index].Weight := ExtractDigitsToIntW(Section.GetParamName(Index));
    StarFieldImageTemplates[Index].CacheControl := TCGaiControlEC.Create;
    StarFieldImageTemplates[Index].CachedData := nil;
    GlobalCache.ResetControl(TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl));
    TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl)
        .SetCacheKey(Section.GetParamValue(Index));
  end;
  ReloadScriptTemplates := False;
  InitializeGameplayConfig;
  InitializeShipGreetingDefinitions;
  InitializeGovernmentGreetingDefinitions;
  InitializePlanetAdvertDefinitions;
  InitializeRobotMapDefinitions;
  UselessItemRemainsCount :=
      StrToInt(AnsiString(LookupLocalizedTextByKey('UselessItems.CntRemains')));
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Explosion');
  Count := Section.GetParamCount;
  SetLength(ArcadeExplosionSounds, Count);
  for Index := 0 to Count - 1 do
    ArcadeExplosionSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Hit');
  Count := Section.GetParamCount;
  SetLength(ArcadeHitSounds, Count);
  for Index := 0 to Count - 1 do
    ArcadeHitSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Item');
  Count := Section.GetParamCount;
  SetLength(ArcadeItemSounds, Count);
  for Index := 0 to Count - 1 do
    ArcadeItemSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('WeaponFirst');
  for Index := 0 to 17 do
    if Section.CountParams(WideString(IntToStr(Index))) <= 0 then
      ArcadeWeaponFirstSounds[Index] := ''
    else
      ArcadeWeaponFirstSounds[Index] := Section.GetParam(WideString(IntToStr(Index)));
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('WeaponLoop');
  for Index := 0 to 17 do
    if Section.CountParams(WideString(IntToStr(Index))) <= 0 then
    begin
      ArcadeWeaponLoopSounds[Index] := '';
      ArcadeWeaponLoopTicks[Index] := -1;
    end
    else
    begin
      Text := Section.GetParam(WideString(IntToStr(Index)));
      ArcadeWeaponLoopTicks[Index] :=
          ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ',')) div 20;
      ArcadeWeaponLoopSounds[Index] := ExtractDelimitedPartW(Text, 1, ',');
    end;
end;
function FindMessageLoop(Name: WideString): TMessageLoopGI;
var
  Index: Byte;
begin
  Result := nil;
  for Index := 0 to 41 do
    if (TMessageLoopGI(RegisteredScreens[Index]) <> nil)
        and (TObject(RegisteredScreens[Index]) is TMessageLoopGI)
        and ((TObject(RegisteredScreens[Index]) as TMessageLoopGI).RegisteredLoopName = Name) then
    begin
      Result := TMessageLoopGI(RegisteredScreens[Index]);
      Break;
    end;
end;
procedure FinalizeGlobalUiRuntime;
var
  Index, Count: Integer;
  SatelliteTemplate: TSputnikTempl;
  PlanetTemplate: TPlanetTempl;
  ScreenIndex: Byte;
  Slot: TShopSlot;
begin
  ArcadeHitSounds := nil;
  ArcadeExplosionSounds := nil;
  ArcadeItemSounds := nil;
  Count := High(SpaceImageTemplates) + 1;
  for Index := 0 to Count - 1 do
    if TCGaiControlEC(SpaceImageTemplates[Index].CacheControl) <> nil then
    begin
      TCGaiControlEC(SpaceImageTemplates[Index].CacheControl).Free;
      SpaceImageTemplates[Index].CacheControl := nil;
    end;
  SpaceImageTemplates := nil;
  Count := High(StarFieldImageTemplates) + 1;
  for Index := 0 to Count - 1 do
    if TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl) <> nil then
    begin
      TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl).Free;
      StarFieldImageTemplates[Index].CacheControl := nil;
    end;
  StarFieldImageTemplates := nil;
  if PlanetRenderTemplates <> nil then
  begin
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      PlanetTemplate := PlanetRenderTemplates[Index];
      PlanetTemplate.Free;
    end;
    PlanetRenderTemplates.Free;
    PlanetRenderTemplates := nil;
  end;
  if SatelliteRenderTemplates <> nil then
  begin
    Count := SatelliteRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      SatelliteTemplate := SatelliteRenderTemplates[Index];
      SatelliteTemplate.Free;
    end;
    SatelliteRenderTemplates.Free;
    SatelliteRenderTemplates := nil;
  end;
  if SpaceProcess <> nil then
  begin
    SpaceProcess.Free;
    SpaceProcess := nil;
  end;
  if GameplayUiScriptCache <> nil then
  begin
    GameplayUiScriptCache.Free;
    GameplayUiScriptCache := nil;
  end;
  if TemporaryShopSlots <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for Index := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[Index];
      if Slot.SlotImage <> nil then
      begin
        Slot.SlotImage.Free;
        Slot.SlotImage := nil;
      end;
      if Slot.BorderImage <> nil then
      begin
        Slot.BorderImage.Free;
        Slot.BorderImage := nil;
      end;
      if Slot.TypeOverlayImage <> nil then
      begin
        Slot.TypeOverlayImage.Free;
        Slot.TypeOverlayImage := nil;
      end;
      if Slot.ItemIconImage <> nil then
      begin
        Slot.ItemIconImage.Free;
        Slot.ItemIconImage := nil;
      end;
      if Slot.ItemAnimation <> nil then
      begin
        Slot.ItemAnimation.Free;
        Slot.ItemAnimation := nil;
      end;
      if Slot.MicroModuleImage <> nil then
      begin
        Slot.MicroModuleImage.Free;
        Slot.MicroModuleImage := nil;
      end;
    end;
  end;
  if MainMenuScreen <> nil then
  begin
    MainMenuScreen.Free;
    MainMenuScreen := nil;
  end;
  if NewGameScreen <> nil then
  begin
    NewGameScreen.Free;
    NewGameScreen := nil;
  end;
  if IntroductionScreen <> nil then
  begin
    IntroductionScreen.Free;
    IntroductionScreen := nil;
  end;
  if HangarScreen <> nil then
  begin
    HangarScreen.Free;
    HangarScreen := nil;
  end;
  if PlanetScreen <> nil then
  begin
    PlanetScreen.Free;
    PlanetScreen := nil;
  end;
  if UninhabitedPlanetScreen <> nil then
  begin
    UninhabitedPlanetScreen.Free;
    UninhabitedPlanetScreen := nil;
  end;
  if PlanetQuestScreen <> nil then
  begin
    PlanetQuestScreen.Free;
    PlanetQuestScreen := nil;
  end;
  if RuinsTalkScreen <> nil then
  begin
    RuinsTalkScreen.Free;
    RuinsTalkScreen := nil;
  end;
  if ArcadeBattleScreen <> nil then
  begin
    ArcadeBattleScreen.Free;
    ArcadeBattleScreen := nil;
  end;
  if EquipmentShopScreen <> nil then
  begin
    EquipmentShopScreen.Free;
    EquipmentShopScreen := nil;
  end;
  if GoodsShopScreen <> nil then
  begin
    GoodsShopScreen.Free;
    GoodsShopScreen := nil;
  end;
  if GovernmentScreen <> nil then
  begin
    GovernmentScreen.Free;
    GovernmentScreen := nil;
  end;
  if InfoScreen <> nil then
  begin
    InfoScreen.Free;
    InfoScreen := nil;
  end;
  if RangerRatingScreen <> nil then
  begin
    RangerRatingScreen.Free;
    RangerRatingScreen := nil;
  end;
  if RewardsScreen <> nil then
  begin
    RewardsScreen.Free;
    RewardsScreen := nil;
  end;
  if ShipScreen <> nil then
  begin
    ShipScreen.Free;
    ShipScreen := nil;
  end;
  if TalkScreen <> nil then
  begin
    TalkScreen.Free;
    TalkScreen := nil;
  end;
  if ScannerScreen <> nil then
  begin
    ScannerScreen.Free;
    ScannerScreen := nil;
  end;
  if StarMapScreen <> nil then
  begin
    StarMapScreen.Free;
    StarMapScreen := nil;
  end;
  if FilmScreen <> nil then
  begin
    FilmScreen.Free;
    FilmScreen := nil;
  end;
  if GalaxyScreen <> nil then
  begin
    GalaxyScreen.Free;
    GalaxyScreen := nil;
  end;
  if JumpScreen <> nil then
  begin
    JumpScreen.Free;
    JumpScreen := nil;
  end;
  if LoadScreen <> nil then
  begin
    LoadScreen.Free;
    LoadScreen := nil;
  end;
  if SaveManagerScreen <> nil then
  begin
    SaveManagerScreen.Free;
    SaveManagerScreen := nil;
  end;
  if GameLoadScreen <> nil then
  begin
    GameLoadScreen.Free;
    GameLoadScreen := nil;
  end;
  if GameMenuScreen <> nil then
  begin
    GameMenuScreen.Free;
    GameMenuScreen := nil;
  end;
  if SettingsScreen <> nil then
  begin
    SettingsScreen.Free;
    SettingsScreen := nil;
  end;
  if GameEndScreen <> nil then
  begin
    GameEndScreen.Free;
    GameEndScreen := nil;
  end;
  if AboutScreen <> nil then
  begin
    AboutScreen.Free;
    AboutScreen := nil;
  end;
  if ScoreScreen <> nil then
  begin
    ScoreScreen.Free;
    ScoreScreen := nil;
  end;
  if SelectFaceScreen <> nil then
  begin
    SelectFaceScreen.Free;
    SelectFaceScreen := nil;
  end;
  if JournalScreen <> nil then
  begin
    JournalScreen.Free;
    JournalScreen := nil;
  end;
  if SpaceObjectUiLoop <> nil then
  begin
    SpaceObjectUiLoop.Free;
    SpaceObjectUiLoop := nil;
  end;
  if LoadRobotScreen <> nil then
  begin
    LoadRobotScreen.Free;
    LoadRobotScreen := nil;
  end;
  if LoadQuestScreen <> nil then
  begin
    LoadQuestScreen.Free;
    LoadQuestScreen := nil;
  end;
  if LoadArcadeScreen <> nil then
  begin
    LoadArcadeScreen.Free;
    LoadArcadeScreen := nil;
  end;
  // Native code omits AchievementsScreen from this cleanup list.
  for ScreenIndex := 0 to 41 do
    RegisteredScreens[ScreenIndex] := nil;
  if PopupController <> nil then
  begin
    PopupController.Free;
    PopupController := nil;
  end;
  if SecondaryFilm <> nil then
  begin
    SecondaryFilm.Free;
    SecondaryFilm := nil;
  end;
  if PrimaryFilm <> nil then
  begin
    PrimaryFilm.Free;
    PrimaryFilm := nil;
  end;
  if PlanetSpaceTemplates <> nil then
  begin
    Count := High(PlanetSpaceTemplates);
    for Index := 0 to Count do
      if PlanetSpaceTemplates[Index].SpaceObject <> nil then
        ReleaseSpaceObject(PlanetSpaceTemplates[Index].SpaceObject);
  end;
  PlanetSpaceTemplates := nil;
  FinalizeSaveWriter;
  if CacheLoader <> nil then
  begin
    CacheLoader.Free;
    CacheLoader := nil;
  end;
end;
procedure ResetScriptHostRuntimeState;
var
  Race, Kind, Series: Byte;
  Index: Integer;
begin
  if ScriptTemplates <> nil then
    for Index := ScriptTemplates.Count - 1 downto 0 do
    begin
      TObject(ScriptTemplates[Index]).Free;
      ScriptTemplates.Delete(Index);
    end;
  if GlobalScriptVariables <> nil then
  begin
    GlobalScriptVariables.Clear;
    GlobalScriptVariables.Add('GRunFrom', vkInt).SetInt(0);
    GlobalScriptVariables.Add('GRunStar', vkDword).SetInt(0);
  end;
  if ArtefactScriptCache <> nil then
  begin
    ArtefactScriptCache.Free;
    ArtefactScriptCache := nil;
  end;
  if ArtefactKindScriptCache <> nil then
  begin
    ArtefactKindScriptCache.Free;
    ArtefactKindScriptCache := nil;
  end;
  if UselessItemScriptCache <> nil then
  begin
    UselessItemScriptCache.Free;
    UselessItemScriptCache := nil;
  end;
  if CustomShipInfoScriptCache <> nil then
  begin
    CustomShipInfoScriptCache.Free;
    CustomShipInfoScriptCache := nil;
  end;
  if ScriptLibraryCache <> nil then
  begin
    ScriptLibraryCache.Free;
    ScriptLibraryCache := nil;
  end;
  for Race := 0 to 7 do
  begin
    for Kind := 0 to 5 do
      if RaceShipTemplates[Race, Kind] <> nil then
        ReleaseSpaceObject(RaceShipTemplates[Race, Kind]);
    if PirateClanShipTemplates[Race] <> nil then
      ReleaseSpaceObject(PirateClanShipTemplates[Race]);
  end;
  for Series := 0 to 7 do
    if Series <> 0 then
    begin
      if BlazerShipTemplates[Series] <> nil then
        ReleaseSpaceObject(BlazerShipTemplates[Series]);
      if KellerShipTemplates[Series] <> nil then
        ReleaseSpaceObject(KellerShipTemplates[Series]);
      if TerronShipTemplates[Series] <> nil then
        ReleaseSpaceObject(TerronShipTemplates[Series]);
    end;
  ReloadScriptTemplates := True;
end;
procedure RecreateSpaceProcess(const ConfigName: WideString);
begin
  if SpaceProcess <> nil then
  begin
    SpaceProcess.Free;
    SpaceProcess := nil;
  end;
  SpaceProcess := TProcessSE.Create(ConfigName);
end;
procedure RunMainScreenStateLoop;
begin
  while True do
  begin
    if ExitScreenLoop then
      Break;
    if (RequestedScreenId = screenStarMap)
        or (RequestedScreenId = screenFilm)
        or (RequestedScreenId = screenArcadeBattle) then
    begin
      CurrentScreenId := RequestedScreenId;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).RunContinuous;
      PreviousScreenId := CurrentScreenId;
      CurrentScreenId := screenNone;
    end
    else
    begin
      if RequestedScreenId = screenNone then
        Exit;
      CurrentScreenId := RequestedScreenId;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).Run;
      PreviousScreenId := CurrentScreenId;
      CurrentScreenId := screenNone;
    end;
  end;
end;
procedure SwapTurnFilms;
var
  Film: TEFilm;
begin
  Film := PrimaryFilm;
  PrimaryFilm := SecondaryFilm;
  SecondaryFilm := Film;
end;
constructor TMessagePlayer.Create;
begin
  inherited Create;
  Button := nil;
  ImageNameOverride := '';
end;
procedure TMessagePlayer.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(Key);
  Buffer.AddAnsiChar(AnsiChar(Kind));
  Buffer.AddIntegerValue(NotificationSoundKind);
  Buffer.AddIntegerValue(Turn);
  Buffer.AddWideStringZ(Text);
  Buffer.AddBoolean(False);
  Buffer.AddDWord(Targets[0].ShipId);
  Buffer.AddDWord(Targets[1].ShipId);
  Buffer.AddDWord(Targets[2].ShipId);
  Buffer.AddDWord(Targets[0].PlanetId);
  Buffer.AddDWord(Targets[1].PlanetId);
  Buffer.AddDWord(Targets[2].PlanetId);
  Buffer.AddBoolean(WasRead);
  Buffer.AddBoolean(NotificationSoundPlayed);
  Buffer.AddWideStringZ(ImageNameOverride);
end;
procedure TMessagePlayer.LoadFromBuffer(Buffer: TBufEC);
begin
  Key := Buffer.ReadWideString;
  Kind := Buffer.GetByte;
  NotificationSoundKind := Buffer.GetInt32;
  Turn := Buffer.GetInt32;
  Text := Buffer.ReadWideString;
  Buffer.GetBoolean;
  Targets[0].ShipId := Buffer.GetUInt32;
  Targets[1].ShipId := Buffer.GetUInt32;
  Targets[2].ShipId := Buffer.GetUInt32;
  Targets[0].PlanetId := Buffer.GetUInt32;
  Targets[1].PlanetId := Buffer.GetUInt32;
  Targets[2].PlanetId := Buffer.GetUInt32;
  WasRead := Buffer.GetBoolean;
  NotificationSoundPlayed := Buffer.GetBoolean;
  if LoadedSaveVersion >= 109 then
    ImageNameOverride := Buffer.ReadWideString;
end;
function TMessagePlayer.GetNormalImageName: WideString;
begin
  if ImageNameOverride = '' then
    Result := PlayerMessagePresentations[Kind].NormalImage
  else
    Result := ImageNameOverride + 'N';
end;
function TMessagePlayer.GetActiveImageName: WideString;
begin
  if ImageNameOverride = '' then
    Result := PlayerMessagePresentations[Kind].ActiveImage
  else
    Result := ImageNameOverride + 'A';
end;
function TMessagePlayer.GetPressedImageName: WideString;
begin
  if ImageNameOverride = '' then
    Result := PlayerMessagePresentations[Kind].PressedImage
  else
    Result := ImageNameOverride + 'D';
end;
procedure ClearPersistentPlayerMessages;
var
  Next, Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Next := FirstPersistentPlayerMessage;
    while Next <> nil do
    begin
      Entry := Next;
      Next := Next.Next;
      Entry.Free;
    end;
    FirstPersistentPlayerMessage := nil;
    LastPersistentPlayerMessage := nil;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
function CountPersistentPlayerMessages: Integer;
var
  Entry: TMessagePlayer;
  Count: Integer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Count := 0;
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
function IsPersistentPlayerMessageQueued(MessageEntry: TMessagePlayer; SkipLock: Boolean): Boolean;
var
  Entry: TMessagePlayer;
begin
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry = MessageEntry then
      begin
        Result := True;
        Exit;
      end;
      Entry := Entry.Next;
    end;
    Result := False;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
procedure RemovePersistentPlayerMessage(MessageEntry: TMessagePlayer; SkipLock: Boolean);
begin
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    if MessageEntry.Prev <> nil then
      MessageEntry.Prev.Next := MessageEntry.Next;
    if MessageEntry.Next <> nil then
      MessageEntry.Next.Prev := MessageEntry.Prev;
    if LastPersistentPlayerMessage = MessageEntry then
      LastPersistentPlayerMessage := MessageEntry.Prev;
    if FirstPersistentPlayerMessage = MessageEntry then
      FirstPersistentPlayerMessage := MessageEntry.Next;
    MessageEntry.Free;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
function RemovePlayerMessagesExceptKinds(
    Key: WideString;
    ExcludedKinds: TPlayerMessageKindSet;
    SkipLock: Boolean
): Boolean;
var
  MessageEntry: TMessagePlayer;
begin
  Result := False;
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    repeat
      MessageEntry := FindPlayerMessageExceptKinds(Key, ExcludedKinds, True);
      if MessageEntry <> nil then
      begin
        RemovePersistentPlayerMessage(MessageEntry, True);
        Result := True;
      end;
    until MessageEntry = nil;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
function FindPlayerBubbleByText(const Text: WideString; SkipLock: Boolean): TMessagePlayer;
var
  Entry: TMessagePlayer;
begin
  Result := nil;
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry.Text = Text then
      begin
        Result := Entry;
        Exit;
      end;
      Entry := Entry.Next;
    end;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
function FindPlayerBubbleByKey(const Key: WideString; SkipLock: Boolean): TMessagePlayer;
var
  Entry: TMessagePlayer;
begin
  Result := nil;
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry.Key = Key then
      begin
        Result := Entry;
        Exit;
      end;
      Entry := Entry.Next;
    end;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
procedure RemovePlayerBubbleByKey(const Key: WideString);
var
  Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry.Key = Key then
      begin
        if Entry.Prev <> nil then
          Entry.Prev.Next := Entry.Next;
        if Entry.Next <> nil then
          Entry.Next.Prev := Entry.Prev;
        if LastPersistentPlayerMessage = Entry then
          LastPersistentPlayerMessage := Entry.Prev;
        if FirstPersistentPlayerMessage = Entry then
          FirstPersistentPlayerMessage := Entry.Next;
        Entry.Free;
        Exit;
      end;
      Entry := Entry.Next;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
procedure RemovePlayerBubblePages(const Prefix: WideString; FirstPage: Integer);
var
  Entry, Next: TMessagePlayer;
  PrefixLength: Integer;
  Suffix: WideString;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      Next := Entry.Next;
      PrefixLength := Pos(Prefix, Entry.Key);
      if PrefixLength = 1 then
      begin
        PrefixLength := Length(Prefix);
        Suffix :=
            CopyWideStringUnchecked(Entry.Key, PrefixLength + 1, Length(Entry.Key) - PrefixLength);
        if IsIntegerTextW(Suffix) and (ExtractDigitsToIntW(Suffix) >= FirstPage) then
        begin
          if Entry.Prev <> nil then
            Entry.Prev.Next := Entry.Next;
          if Entry.Next <> nil then
            Entry.Next.Prev := Entry.Prev;
          if LastPersistentPlayerMessage = Entry then
            LastPersistentPlayerMessage := Entry.Prev;
          if FirstPersistentPlayerMessage = Entry then
            FirstPersistentPlayerMessage := Entry.Next;
          Entry.Free;
        end;
      end;
      Entry := Next;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
function FindPlayerMessageExceptKinds(
    const Key: WideString;
    ExcludedKinds: TPlayerMessageKindSet;
    SkipLock: Boolean
): TMessagePlayer;
var
  MessageEntry: TMessagePlayer;
begin
  Result := nil;
  if not SkipLock then
    PersistentPlayerMessageLock.Enter;
  try
    MessageEntry := FirstPersistentPlayerMessage;
    while MessageEntry <> nil do
    begin
      if not (MessageEntry.Kind in ExcludedKinds)
          and ((Length(Key) = 0) or (Pos(Key, MessageEntry.Key) > 0)) then
      begin
        Result := MessageEntry;
        Exit;
      end;
      MessageEntry := MessageEntry.Next;
    end;
  finally
    if not SkipLock then
      PersistentPlayerMessageLock.Leave;
  end;
end;
function CreatePersistentPlayerMessage: TMessagePlayer;
var
  Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := TMessagePlayer.Create;
    if LastPersistentPlayerMessage <> nil then
      LastPersistentPlayerMessage.Next := Entry;
    Entry.Prev := LastPersistentPlayerMessage;
    Entry.Next := nil;
    LastPersistentPlayerMessage := Entry;
    if FirstPersistentPlayerMessage = nil then
      FirstPersistentPlayerMessage := Entry;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  Result := Entry;
end;
function AddOrUpdatePlayerBubble(
    Kind: Byte;
    Turn: Integer;
    const Text, Key: WideString
): TMessagePlayer;
var
  Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    if Key <> '' then
    begin
      Entry := FindPlayerBubbleByKey(Key, True);
      if Entry <> nil then
      begin
        if Entry.Kind <> Kind then
        begin
          Entry.WasRead := False;
          Entry.NotificationSoundPlayed := False;
        end;
        Entry.Kind := Kind;
        Entry.Turn := Turn;
        if Text <> '' then
          Entry.Text := Text;
        Result := Entry;
        Exit;
      end;
    end;
    Entry := FindPlayerBubbleByText(Text, True);
    if Entry <> nil then
    begin
      Result := Entry;
      Exit;
    end;
    Entry := TMessagePlayer.Create;
    if LastPersistentPlayerMessage <> nil then
      LastPersistentPlayerMessage.Next := Entry;
    Entry.Prev := LastPersistentPlayerMessage;
    Entry.Next := nil;
    LastPersistentPlayerMessage := Entry;
    if FirstPersistentPlayerMessage = nil then
      FirstPersistentPlayerMessage := Entry;
    Entry.Key := Key;
    Entry.Kind := Kind;
    Entry.Turn := Turn;
    Entry.Text := Text;
    Entry.WasRead := False;
    Entry.NotificationSoundPlayed := False;
    Result := Entry;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
procedure PruneExpiredPersistentPlayerMessages;
var
  Next, Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Next := FirstPersistentPlayerMessage;
    while Next <> nil do
    begin
      Entry := Next;
      Next := Next.Next;
      if Entry.WasRead and (Entry.Kind in [6]) and (Galaxy.CurrentTurn - Entry.Turn >= 7) then
        RemovePersistentPlayerMessage(Entry, True)
      else if Galaxy.CurrentTurn - Entry.Turn
          >= PlayerMessagePresentations[Entry.Kind].LifetimeTurns then
        RemovePersistentPlayerMessage(Entry, True)
      else if Entry.WasRead and (Entry.Kind in [0..2, 4, 5, 8]) then
        RemovePersistentPlayerMessage(Entry, True)
      else if not GetPlayer.InNormalSpace and (Entry.Kind = 1) then
        RemovePersistentPlayerMessage(Entry, True);
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
constructor TScriptTemplUnit.Create;
begin
  inherited Create;
  ConditionCode := TCodeEC.Create;
  ActiveScriptIndex := -1;
end;
destructor TScriptTemplUnit.Destroy;
begin
  ConditionCode.Free;
  ConditionCode := nil;
  inherited Destroy;
end;
function FindScriptTemplateIndex(const Name: WideString): Integer;
var
  Item: TScriptTemplUnit;
  Count, Index: Integer;
begin
  Count := ScriptTemplates.Count;
  for Index := 0 to Count - 1 do
  begin
    Item := ScriptTemplates[Index];
    if Item.Name = Name then
    begin
      Result := Index;
      Exit;
    end;
  end;
  Result := -1;
end;
procedure CollectInactiveScriptTemplates(Dest: TList);
var
  Item: TScriptTemplUnit;
  Count, Index, First, Second: Integer;
begin
  Dest.Clear;
  Count := ScriptTemplates.Count;
  for Index := 0 to Count - 1 do
  begin
    Item := ScriptTemplates[Index];
    if Item.ActiveScriptIndex < 0 then
      Dest.Add(Item);
  end;
  if Dest.Count >= 2 then
  begin
    Count := Dest.Count * 2;
    for Index := 0 to Count - 1 do
    begin
      First :=
          SeededRandomIntRange(
              0,
              Dest.Count - 1,
              Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Cardinal(Index)
          );
      Second :=
          SeededRandomIntRange(
              0,
              Dest.Count - 1,
              Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn + Index)
          );
      if First <> Second then
      begin
        Item := Dest[First];
        Dest[First] := Dest[Second];
        Dest[Second] := Item;
      end;
    end;
  end;
end;
function ShowPlayerTipOnce(Index: Integer): Boolean;
begin
  Result := False;
  if ShownPlayerTips shr Index and 1 = 0 then
  begin
    ShownPlayerTips := ShownPlayerTips or (1 shl Index);
    if Index < 10 then
      AddOrUpdatePlayerBubble(
          6,
          Galaxy.CurrentTurn,
          LocalizedColorText('Tips.0' + SysUtils.IntToStr(Index)),
          ''
      )
    else
      AddOrUpdatePlayerBubble(
          6,
          Galaxy.CurrentTurn,
          LocalizedColorText('Tips.' + SysUtils.IntToStr(Index)),
          ''
      );
    Result := True;
  end;
end;
function HasShownPlayerTip(Index: Integer): Boolean;
begin
  Result := ShownPlayerTips shr Index and 1 <> 0;
end;
function SelectSpaceImageTemplateFromSeed(Kind: Integer; Seed: Cardinal): Integer;
var
  Index, Weight: Integer;
begin
  Weight := 0;
  for Index := 0 to High(SpaceImageTemplates) do
    if SpaceImageTemplates[Index].Kind = Kind then
      Inc(Weight, SpaceImageTemplates[Index].Weight);
  if Weight = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Weight := SeededRandomIntRange(0, Weight - 1, Seed);
  for Index := 0 to High(SpaceImageTemplates) do
    if SpaceImageTemplates[Index].Kind = Kind then
    begin
      Dec(Weight, SpaceImageTemplates[Index].Weight);
      if Weight < 0 then
      begin
        Result := Index;
        Exit;
      end;
    end;
  Result := 0;
end;
function SelectSpaceImageTemplate(Kind: Integer): Integer;
begin
  Result := SelectSpaceImageTemplateFromSeed(Kind, RandomIntRange(0, 2000000000));
end;
procedure HandleRuntimeExitCheck1;
begin
  if ExitScreenLoop then
    ;
end;
procedure HandleRuntimeExitCheck2;
begin
  if ExitScreenLoop then
    ;
end;
function ParseRobotMapRaceMask(Text: WideString): TOwnerMask;
var
  Names: AnsiString;
begin
  Result := [];
  if (Text <> '') and (Text <> 'Any') then
  begin
    Names := AnsiString(Text);
    if Pos('Maloc', Names) > 0 then
      Include(Result, 0);
    if Pos('Peleng', Names) > 0 then
      Include(Result, 1);
    if Pos('People', Names) > 0 then
      Include(Result, 2);
    if Pos('Fei', Names) > 0 then
      Include(Result, 3);
    if Pos('Gaal', Names) > 0 then
      Include(Result, 4);
  end;
end;
procedure InitializeRobotMapDefinitions;
var
  Block, Root: TBlockParEC;
  Previous, Index, Count: Integer;
  Text: WideString;
  function ReadMapText(
      const Path: WideString
  ): WideString; // @addr $52DDC8 @ida "void __usercall $name(unsigned __int16 *Path@<eax>, unsigned __int16 **Result@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x52DFCB,0x52dff4,0x52e01d,0x52e043,0x52e084,0x52e0ad,0x52e168,0x52e191,0x52e1c5,0x52e1f9,0x52e2db,0x52e304,0x52e32d,0x52e356,0x52e37f,0x52e3a8,0x52e3d1,0x52e3fd,0x52e42c,0x52e45b,0x52e48a,0x52e4b9,0x52e4e8,0x52e517" @note "Nested in InitializeRobotMapDefinitions; joins repeated fields with CRLF."
  var
    Part, PartCount: Integer;
  begin
    Result := '';
    PartCount := Block.CountParamsByPath(Path);
    for Part := 0 to PartCount - 1 do
    begin
      if Result <> '' then
        Result := Result + #13#10;
      Result := Result + Block.GetParamByPath(Path + ':' + WideString(IntToStr(Part)));
    end;
  end;
begin
  Root := LanguageDataConfig.GetBlock('RobotsMap');
  Count := Root.GetBlockCount;
  SetLength(RobotMapDefinitions, Count);
  for Index := 0 to Count - 1 do
  begin
    RobotMapDefinitions[Index].Id := ExtractDigitsToIntW(Root.GetBlockNameByIndex(Index));
    for Previous := 0 to Index - 1 do
      if RobotMapDefinitions[Index].Id = RobotMapDefinitions[Previous].Id then
        RaiseWideMessage('RobotMap.Id');
    Block := Root.GetBlockByIndex(Index);
    RobotMapDefinitions[Index].Name := ReadMapText('Name');
    RobotMapDefinitions[Index].Map := ReadMapText('Map');
    Text := ReadMapText('Group');
    if Text <> '' then
      RobotMapDefinitions[Index].Group := ExtractSignedDigitsToIntW(ReadMapText('Group'))
    else
      RobotMapDefinitions[Index].Group := -1;
    RobotMapDefinitions[Index].Access := ExtractSignedDigitsToIntW(ReadMapText('Access'));
    Text := ReadMapText('Side');
    RobotMapDefinitions[Index].Side := 0;
    if Pos('Red', AnsiString(Text)) > 0 then
      RobotMapDefinitions[Index].Side := RobotMapDefinitions[Index].Side or 1;
    if Pos('Green', AnsiString(Text)) > 0 then
      RobotMapDefinitions[Index].Side := RobotMapDefinitions[Index].Side or 2;
    if Pos('Blue', AnsiString(Text)) > 0 then
      RobotMapDefinitions[Index].Side := RobotMapDefinitions[Index].Side or 4;
    RobotMapDefinitions[Index].Length := ExtractSignedDigitsToIntW(ReadMapText('Length'));
    Text := ReadMapText('PlanetRace');
    RobotMapDefinitions[Index].PlanetRace := ParseRobotMapRaceMask(Text);
    Text := ReadMapText('PlayerRace');
    RobotMapDefinitions[Index].PlayerRace := ParseRobotMapRaceMask(Text);
    Text := ReadMapText('PlayerStatus');
    RobotMapDefinitions[Index].PlayerStatus := [];
    if (Text <> '') and (Text <> 'Any') then
    begin
      if Pos('Trader', AnsiString(Text)) > 0 then
        Include(RobotMapDefinitions[Index].PlayerStatus, 0);
      if Pos('Pirate', AnsiString(Text)) > 0 then
        Include(RobotMapDefinitions[Index].PlayerStatus, 1);
      if Pos('Warrior', AnsiString(Text)) > 0 then
        Include(RobotMapDefinitions[Index].PlayerStatus, 2);
    end;
    RobotMapDefinitions[Index].MinWins := ExtractSignedDigitsToIntW(ReadMapText('MinWins'));
    RobotMapDefinitions[Index].MaxWins := ExtractSignedDigitsToIntW(ReadMapText('MaxWins'));
    RobotMapDefinitions[Index].Reiteration := ExtractDigitsToIntW(ReadMapText('Reiteration'));
    RobotMapDefinitions[Index].ReinforcementsDisabled :=
        ParseEnabledNameGI(ReadMapText('ReinforcementsDisabled'));
    RobotMapDefinitions[Index].Terron := ParseEnabledNameGI(ReadMapText('Terron'));
    RobotMapDefinitions[Index].Demo := ParseEnabledNameGI(ReadMapText('Demo'));
    RobotMapDefinitions[Index].AfterLiberation :=
        ParseEnabledNameGI(ReadMapText('AfterLiberation'));
    RobotMapDefinitions[Index].GovTextStart := ReadMapText('GovTextStart');
    RobotMapDefinitions[Index].GovTextWin := ReadMapText('GovTextWin');
    RobotMapDefinitions[Index].GovTextLoss := ReadMapText('GovTextLoss');
    RobotMapDefinitions[Index].RobotsStart := ReadMapText('RobotsStart');
    RobotMapDefinitions[Index].RobotsWin := ReadMapText('RobotsWin');
    RobotMapDefinitions[Index].RobotsLoss := ReadMapText('RobotsLoss');
    RobotMapDefinitions[Index].FromAuthor := ReadMapText('FromAuthor');
  end;
end;
function FindRobotMapById(MapId: Integer): Integer;
var
  Index: Integer;
begin
  for Index := 0 to High(RobotMapDefinitions) do
    if RobotMapDefinitions[Index].Id = MapId then
    begin
      Result := Index;
      Exit;
    end;
  Result := -1;
end;
function FindPlanetSpaceTemplateIndex(Style, StyleVariant: Integer): Integer;
var
  Index: Integer;
begin
  for Index := 0 to High(PlanetSpaceTemplates) do
    if (PlanetSpaceTemplates[Index].Style = Style)
        and (PlanetSpaceTemplates[Index].StyleVariant = StyleVariant) then
    begin
      Result := Index;
      Exit;
    end;
  Result := -1;
  RaiseWideMessage('find planet');
end;
procedure InitializeShipGreetingDefinitions;
var
  Block: TBlockParEC;
  Index, EntryIndex, Item, Count: Integer;
  Text: WideString;
  function ReadShipGreetingField(const FieldName: WideString):
      WideString
          {
    @addr $52E974
    @ida "void __usercall $name(unsigned __int16 *FieldName@<eax>, unsigned __int16 **Result@<edx>, void *ParentFrame@<^0>);"
    @stackpop 0
    @calls "0x52eb43,0x52eb8e,0x52EBEB,0x52ec91,0x52edf2,0x52ef0b,0x52ef39,0x52EF67,0x52efbe,0x52f015,0x52f06c,0x52f0c3,0x52f25a,0x52f288,0x52f2df,0x52f336,0x52f38d,0x52f455,0x52f51d,0x52f5e5,0x52f6ab,0x52f771,0x52f88d,0x52f9a9,0x52fac5,0x52fbe1,0x52fcfd,0x52fe19,0x52ffb0,0x530147,0x530263,0x53037f,0x53049b,0x5305a0,0x5306e5,0x53082a,0x530881,0x5308d8,0x530971,0x530a0a,0x530a61,0x530b29,0x530bf1,0x530cb9,0x530d81,0x530e49,0x530e94,0x530fb0,0x5310f5,0x531211,0x53132d,0x531384,0x5313db,0x531432,0x5314f8,0x531614,0x53166b,0x531735,0x5317fd,0x5318c5,0x53198d,0x531a55,0x531b1d,0x531b4b,0x531c67,0x531dac,0x531ec8,0x531fe4,0x53203b,0x532092,0x5320e9,0x5321af,0x5322cb,0x532322,0x532379,0x5323d0,0x532427,0x53247e,0x5324d5,0x53259d,0x532665,0x53272d,0x5327f5,0x5328bd,0x5328e0,0x5329fc,0x532a53,0x532bc1,0x532bef,0x532c46,0x532c9d,0x532db9,0x532f50,0x53306c,0x5330ab,0x533180,0x5331d7,0x53329f,0x533367,0x5333c7"
  }
      ;
  begin
    if Block.CountParams(FieldName) > 0 then
      Result := Block.GetParam(FieldName)
    else
      Result := '';
  end;
begin
  ShipGreetingCount := 0;
  Count := StrToInt(AnsiString(LookupLocalizedTextByKey('ShipGreetings.CountShipGreetings')));
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('ShipGreetings').CountBlocks(WideString(IntToStr(Index)))
        > 0 then
      Inc(ShipGreetingCount);
  SetLength(ShipGreetingDefinitions, ShipGreetingCount);
  ShipGreetingCount := 0;
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('ShipGreetings').CountBlocks(WideString(IntToStr(Index)))
        <> 0 then
    begin
      Inc(ShipGreetingCount);
      EntryIndex := ShipGreetingCount - 1;
      Block := LanguageDataConfig.GetBlockByPath(WideString('ShipGreetings.' + IntToStr(Index)));
      with ShipGreetingDefinitions[EntryIndex] do
      begin
        Name := WideString(IntToStr(Index));
        Text := ReadShipGreetingField('Priority');
        if Text = '' then
          Priority := 10
        else
          Priority := StrToInt(AnsiString(Text));
        Text := ReadShipGreetingField('AutoTalk');
        if (Text = '') or (Text = 'No') then
          AutoTalk := 1
        else if Text = 'Any' then
          AutoTalk := 2
        else
          AutoTalk := 0;
        Text := ReadShipGreetingField('FlyType');
        if (Text = 'Any') or (Text = '') then
          FlyType := 0
        else if Text = 'ToPlanet' then
          FlyType := 1
        else if Text = 'ToStar' then
          FlyType := 2
        else if Text = 'ToItem' then
          FlyType := 3
        else if Text = 'ToShip' then
          FlyType := 4
        else
          RaiseWideMessage(Text);
        Text := ReadShipGreetingField('ShipType');
        ShipType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', AnsiString(Text)) > 0 then
            Include(ShipType, gscTransport);
          if Pos('Liner', AnsiString(Text)) > 0 then
            Include(ShipType, gscLiner);
          if Pos('Diplomat', AnsiString(Text)) > 0 then
            Include(ShipType, gscDiplomat);
          if Pos('Ranger', AnsiString(Text)) > 0 then
            Include(ShipType, gscRanger);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(ShipType, gscPirate);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(ShipType, gscWarrior);
          if Pos('Kling', AnsiString(Text)) > 0 then
            Include(ShipType, gscKling);
          if Pos('Pirat', AnsiString(Text)) > 0 then
            Include(ShipType, gscPirateClan);
        end;
        Text := ReadShipGreetingField('Relations');
        Relations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(Relations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(Relations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(Relations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(Relations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(Relations, 4);
        end;
        Text := ReadShipGreetingField('ShipRace');
        ShipRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('PlayerRace');
        PlayerRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('ShipRaceIsPlayerRace');
        if Text = 'Yes' then
          ShipRaceIsPlayerRace := 0
        else if Text = 'No' then
          ShipRaceIsPlayerRace := 1
        else
          ShipRaceIsPlayerRace := 2;
        Text := ReadShipGreetingField('PlayerAttackGoodShip');
        if Text = 'Yes' then
          PlayerAttackGoodShip := 0
        else if Text = 'No' then
          PlayerAttackGoodShip := 1
        else
          PlayerAttackGoodShip := 2;
        Text := ReadShipGreetingField('InFear');
        if Text = 'Yes' then
          InFear := 0
        else if Text = 'Any' then
          InFear := 2
        else
          InFear := 1;
        Text := ReadShipGreetingField('ShipBadFlyToShip');
        if Text = 'Yes' then
          ShipBadFlyToShip := 0
        else if Text = 'Any' then
          ShipBadFlyToShip := 2
        else
          ShipBadFlyToShip := 1;
        Text := ReadShipGreetingField('ShipBadType');
        ShipBadType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscTransport);
          if Pos('Liner', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscLiner);
          if Pos('Diplomat', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscDiplomat);
          if Pos('Ranger', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscRanger);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscPirate);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscWarrior);
          if Pos('Kling', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscKling);
          if Pos('PirateClan', AnsiString(Text)) > 0 then
            Include(ShipBadType, gscPirateClan);
        end;
        Text := ReadShipGreetingField('ShipBadRace');
        ShipBadRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('ShipFlyToPlayer');
        if Text = 'Yes' then
          ShipFlyToPlayer := 0
        else if Text = 'No' then
          ShipFlyToPlayer := 1
        else
          ShipFlyToPlayer := 2;
        Text := ReadShipGreetingField('PlayerFlyToShip');
        if Text = 'Yes' then
          PlayerFlyToShip := 0
        else if Text = 'No' then
          PlayerFlyToShip := 1
        else
          PlayerFlyToShip := 2;
        Text := ReadShipGreetingField('PlayerIsShipBad');
        if Text = 'Yes' then
          PlayerIsShipBad := 0
        else if Text = 'No' then
          PlayerIsShipBad := 1
        else
          PlayerIsShipBad := 2;
        Text := ReadShipGreetingField('ShipTurnBeforeEndOrder');
        ShipTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(ShipTurnBeforeEndOrder, Item);
          if Pos('Far', AnsiString(Text)) > 0 then
            Include(ShipTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('PlayerTurnBeforeEndOrder');
        PlayerTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PlayerTurnBeforeEndOrder, Item);
          if Pos('Far', AnsiString(Text)) > 0 then
            Include(PlayerTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('ShipBadTurnBeforeEndOrder');
        ShipBadTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(ShipBadTurnBeforeEndOrder, Item);
          if Pos('Far', AnsiString(Text)) > 0 then
            Include(ShipBadTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('ShipStatus');
        ShipStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', AnsiString(Text)) > 0 then
            Include(ShipStatus, 0);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(ShipStatus, 1);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(ShipStatus, 2);
        end;
        Text := ReadShipGreetingField('PlayerStatus');
        PlayerStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 0);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 1);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 2);
        end;
        Text := ReadShipGreetingField('ShipStrength');
        ShipStrength := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ShipStrength, 1);
          // Native uses Pirate here, unlike the other strength/size filters.
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(ShipStrength, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ShipStrength, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ShipStrength, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ShipStrength, 5);
        end;
        Text := ReadShipGreetingField('PlayerStrength');
        PlayerStrength := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(PlayerStrength, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(PlayerStrength, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(PlayerStrength, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(PlayerStrength, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(PlayerStrength, 5);
        end;
        Text := ReadShipGreetingField('ShipStructure');
        ShipStructure := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ShipStructure, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ShipStructure, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ShipStructure, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ShipStructure, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ShipStructure, 5);
        end;
        Text := ReadShipGreetingField('PlayerStructure');
        PlayerStructure := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(PlayerStructure, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(PlayerStructure, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(PlayerStructure, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(PlayerStructure, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(PlayerStructure, 5);
        end;
        Text := ReadShipGreetingField('ShipRating');
        ShipRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ShipRating, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ShipRating, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ShipRating, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ShipRating, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ShipRating, 5);
        end;
        Text := ReadShipGreetingField('PlayerRating');
        PlayerRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(PlayerRating, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(PlayerRating, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(PlayerRating, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(PlayerRating, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(PlayerRating, 5);
        end;
        Text := ReadShipGreetingField('ShipRank');
        ShipRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', AnsiString(Text)) > 0 then
            Include(ShipRank, 0);
          if Pos('Cadet', AnsiString(Text)) > 0 then
            Include(ShipRank, 1);
          if Pos('Pilot', AnsiString(Text)) > 0 then
            Include(ShipRank, 2);
          if Pos('Wingman', AnsiString(Text)) > 0 then
            Include(ShipRank, 3);
          if Pos('Leader', AnsiString(Text)) > 0 then
            Include(ShipRank, 4);
          if Pos('Ace', AnsiString(Text)) > 0 then
            Include(ShipRank, 5);
          if Pos('Commander', AnsiString(Text)) > 0 then
            Include(ShipRank, 6);
          if Pos('Admiral', AnsiString(Text)) > 0 then
            Include(ShipRank, 7);
        end;
        Text := ReadShipGreetingField('PlayerRank');
        PlayerRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', AnsiString(Text)) > 0 then
            Include(PlayerRank, 0);
          if Pos('Cadet', AnsiString(Text)) > 0 then
            Include(PlayerRank, 1);
          if Pos('Pilot', AnsiString(Text)) > 0 then
            Include(PlayerRank, 2);
          if Pos('Wingman', AnsiString(Text)) > 0 then
            Include(PlayerRank, 3);
          if Pos('Leader', AnsiString(Text)) > 0 then
            Include(PlayerRank, 4);
          if Pos('Ace', AnsiString(Text)) > 0 then
            Include(PlayerRank, 5);
          if Pos('Commander', AnsiString(Text)) > 0 then
            Include(PlayerRank, 6);
          if Pos('Admiral', AnsiString(Text)) > 0 then
            Include(PlayerRank, 7);
        end;
        Text := ReadShipGreetingField('RatingShipWithPlayer');
        RatingShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(RatingShipWithPlayer, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(RatingShipWithPlayer, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(RatingShipWithPlayer, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(RatingShipWithPlayer, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(RatingShipWithPlayer, 5);
        end;
        Text := ReadShipGreetingField('RankShipWithPlayer');
        RankShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayer, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayer, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayer, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayer, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayer, 5);
        end;
        Text := ReadShipGreetingField('StrengthShipWithPlayer');
        StrengthShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(StrengthShipWithPlayer, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(StrengthShipWithPlayer, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(StrengthShipWithPlayer, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(StrengthShipWithPlayer, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(StrengthShipWithPlayer, 5);
        end;
        Text := ReadShipGreetingField('Goods');
        if Text = '' then
          Goods := 42
        else if Text = 'Food' then
          Goods := 0
        else if Text = 'Medicine' then
          Goods := 1
        else if Text = 'Technics' then
          Goods := 2
        else if Text = 'Luxury' then
          Goods := 3
        else if Text = 'Minerals' then
          Goods := 4
        else if Text = 'Alcohol' then
          Goods := 5
        else if Text = 'Arms' then
          Goods := 6
        else if Text = 'Narcotics' then
          Goods := 7
        else
          Goods := 42;
        Text := ReadShipGreetingField('ShipGoodsCnt');
        ShipGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ShipGoodsCnt, 5);
        end;
        Text := ReadShipGreetingField('PlayerGoodsCnt');
        PlayerGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(PlayerGoodsCnt, 5);
        end;
        Text := ReadShipGreetingField('ShipHaveGoods');
        if Text = 'Yes' then
          ShipHaveGoods := 0
        else if Text = 'No' then
          ShipHaveGoods := 1
        else
          ShipHaveGoods := 2;
        Text := ReadShipGreetingField('PlayerHaveGoods');
        if Text = 'Yes' then
          PlayerHaveGoods := 0
        else if Text = 'No' then
          PlayerHaveGoods := 1
        else
          PlayerHaveGoods := 2;
        Text := ReadShipGreetingField('ShipGoodsTypeCnt');
        ShipGoodsTypeCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 8 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(ShipGoodsTypeCnt, Item);
        end;
        Text := ReadShipGreetingField('PlayerGoodsTypeCnt');
        PlayerGoodsTypeCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 8 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PlayerGoodsTypeCnt, Item);
        end;
        Text := ReadShipGreetingField('ShipMayScanPlayer');
        if Text = 'Yes' then
          ShipMayScanPlayer := 0
        else if Text = 'No' then
          ShipMayScanPlayer := 1
        else
          ShipMayScanPlayer := 2;
        Text := ReadShipGreetingField('RangerInCurStar');
        RangerInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(RangerInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(RangerInCurStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInCurStar');
        PirateInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInCurStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInCurStar');
        KlingInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(KlingInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(KlingInCurStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInCurStar');
        WarriorInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(WarriorInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(WarriorInCurStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInCurStar');
        TransportInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(TransportInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(TransportInCurStar, 10);
        end;
        Text := ReadShipGreetingField('LastPlanetRace');
        if Text = 'Any' then
          LastPlanetRace := [0..4]
        else
          LastPlanetRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('LastPlanetRelations');
        LastPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(LastPlanetRelations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(LastPlanetRelations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(LastPlanetRelations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(LastPlanetRelations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(LastPlanetRelations, 4);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsCnt');
        LastPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsCnt, 5);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsSale');
        LastPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsSale, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsSale, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsSale, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsSale, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsSale, 5);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsBuy');
        LastPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsBuy, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsBuy, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsBuy, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsBuy, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(LastPlanetGoodsBuy, 5);
        end;
        Text := ReadShipGreetingField('LastPlanetIsHomePlanet');
        if Text = 'Yes' then
          LastPlanetIsHomePlanet := 0
        else if Text = 'No' then
          LastPlanetIsHomePlanet := 1
        else
          LastPlanetIsHomePlanet := 2;
        Text := ReadShipGreetingField('LastPlanetRaceIsShipRace');
        if Text = 'Yes' then
          LastPlanetRaceIsShipRace := 0
        else if Text = 'No' then
          LastPlanetRaceIsShipRace := 1
        else
          LastPlanetRaceIsShipRace := 2;
        Text := ReadShipGreetingField('LastPlanetRaceIsPlayerRace');
        if Text = 'Yes' then
          LastPlanetRaceIsPlayerRace := 0
        else if Text = 'No' then
          LastPlanetRaceIsPlayerRace := 1
        else
          LastPlanetRaceIsPlayerRace := 2;
        Text := ReadShipGreetingField('LastPlanetEconomy');
        LastPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', AnsiString(Text)) > 0 then
            Include(LastPlanetEconomy, 0);
          if Pos('Mixed', AnsiString(Text)) > 0 then
            Include(LastPlanetEconomy, 1);
          if Pos('Industrial', AnsiString(Text)) > 0 then
            Include(LastPlanetEconomy, 2);
        end;
        Text := ReadShipGreetingField('LastPlanetGoverment');
        LastPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', AnsiString(Text)) > 0 then
            Include(LastPlanetGovernment, 0);
          if Pos('Dictatorship', AnsiString(Text)) > 0 then
            Include(LastPlanetGovernment, 1);
          if Pos('Monarchy', AnsiString(Text)) > 0 then
            Include(LastPlanetGovernment, 2);
          if Pos('Republic', AnsiString(Text)) > 0 then
            Include(LastPlanetGovernment, 3);
          if Pos('Democracy', AnsiString(Text)) > 0 then
            Include(LastPlanetGovernment, 4);
        end;
        Text := ReadShipGreetingField('LastPlanetInCurStar');
        if Text = 'Yes' then
          LastPlanetInCurStar := 0
        else if Text = 'No' then
          LastPlanetInCurStar := 1
        else
          LastPlanetInCurStar := 2;
        Text := ReadShipGreetingField('LastPlanetDistToShipInTurn');
        LastPlanetDistToShipInTurn := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 1 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(LastPlanetDistToShipInTurn, Item);
          if Pos('Far', AnsiString(Text)) > 0 then
            Include(LastPlanetDistToShipInTurn, 10);
        end;
        Text := ReadShipGreetingField('RangerInLastPlanetStar');
        RangerInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(RangerInLastPlanetStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(RangerInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInLastPlanetStar');
        PirateInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInLastPlanetStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInLastPlanetStar');
        KlingInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(KlingInLastPlanetStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(KlingInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInLastPlanetStar');
        WarriorInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(WarriorInLastPlanetStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(WarriorInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInLastPlanetStar');
        TransportInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(TransportInLastPlanetStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(TransportInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('ToPlanetRace');
        ToPlanetRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('ToPlanetRelations');
        ToPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 4);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsCnt');
        ToPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 5);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsSale');
        ToPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 5);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsBuy');
        ToPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 5);
        end;
        Text := ReadShipGreetingField('ToPlanetIsHomePlanet');
        if Text = 'Yes' then
          ToPlanetIsHomePlanet := 0
        else if Text = 'No' then
          ToPlanetIsHomePlanet := 1
        else
          ToPlanetIsHomePlanet := 2;
        Text := ReadShipGreetingField('ToPlanetRaceIsShipRace');
        if Text = 'Yes' then
          ToPlanetRaceIsShipRace := 0
        else if Text = 'No' then
          ToPlanetRaceIsShipRace := 1
        else
          ToPlanetRaceIsShipRace := 2;
        Text := ReadShipGreetingField('ToPlanetRaceIsPlayerRace');
        if Text = 'Yes' then
          ToPlanetRaceIsPlayerRace := 0
        else if Text = 'No' then
          ToPlanetRaceIsPlayerRace := 1
        else
          ToPlanetRaceIsPlayerRace := 2;
        Text := ReadShipGreetingField('ToPlanetEconomy');
        ToPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 0);
          if Pos('Mixed', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 1);
          if Pos('Industrial', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 2);
        end;
        Text := ReadShipGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 0);
          if Pos('Dictatorship', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 1);
          if Pos('Monarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 2);
          if Pos('Republic', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 3);
          if Pos('Democracy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 4);
        end;
        Text := ReadShipGreetingField('ToPlanetIsLastPlanet');
        if Text = 'Yes' then
          ToPlanetIsLastPlanet := 0
        else if Text = 'Any' then
          ToPlanetIsLastPlanet := 2
        else
          ToPlanetIsLastPlanet := 1;
        Text := ReadShipGreetingField('ToPlanetRaceIsLastPlanetRace');
        if Text = 'Yes' then
          ToPlanetRaceIsLastPlanetRace := 0
        else if Text = 'No' then
          ToPlanetRaceIsLastPlanetRace := 1
        else
          ToPlanetRaceIsLastPlanetRace := 2;
        Text := ReadShipGreetingField('HomePlanetInToStar');
        if Text = 'Yes' then
          HomePlanetInToStar := 0
        else if Text = 'No' then
          HomePlanetInToStar := 1
        else
          HomePlanetInToStar := 2;
        Text := ReadShipGreetingField('HomePlanetInCurStar');
        if Text = 'Yes' then
          HomePlanetInCurStar := 0
        else if Text = 'No' then
          HomePlanetInCurStar := 1
        else
          HomePlanetInCurStar := 2;
        Text := ReadShipGreetingField('ToStarControlByKling');
        if Text = 'Yes' then
          ToStarControlByKling := 0
        else if Text = 'Any' then
          ToStarControlByKling := 2
        else
          ToStarControlByKling := 1;
        Text := ReadShipGreetingField('ToStarInBattle');
        if Text = 'Yes' then
          ToStarInBattle := 0
        else if Text = 'Any' then
          ToStarInBattle := 2
        else
          ToStarInBattle := 1;
        Text := ReadShipGreetingField('RangerInToStar');
        RangerInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(RangerInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(RangerInToStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInToStar');
        PirateInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInToStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInToStar');
        KlingInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(KlingInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(KlingInToStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInToStar');
        WarriorInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(WarriorInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(WarriorInToStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInToStar');
        TransportInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(TransportInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(TransportInToStar, 10);
        end;
        ItemType := ReadShipGreetingField('ItemType');
        // Native repeats this assignment; preserve both reads.
        Text := ReadShipGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 0);
          if Pos('Dictatorship', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 1);
          if Pos('Monarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 2);
          if Pos('Republic', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 3);
          if Pos('Democracy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 4);
        end;
        Text := ReadShipGreetingField('ShipNeedInItem');
        if Text = 'Yes' then
          ShipNeedInItem := 0
        else if Text = 'No' then
          ShipNeedInItem := 1
        else
          ShipNeedInItem := 2;
        Text := ReadShipGreetingField('ToShipType');
        ToShipType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', AnsiString(Text)) > 0 then
            Include(ToShipType, gscTransport);
          if Pos('Liner', AnsiString(Text)) > 0 then
            Include(ToShipType, gscLiner);
          if Pos('Diplomat', AnsiString(Text)) > 0 then
            Include(ToShipType, gscDiplomat);
          if Pos('Ranger', AnsiString(Text)) > 0 then
            Include(ToShipType, gscRanger);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(ToShipType, gscPirate);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(ToShipType, gscWarrior);
          if Pos('Kling', AnsiString(Text)) > 0 then
            Include(ToShipType, gscKling);
        end;
        Text := ReadShipGreetingField('ToShipRace');
        ToShipRace := ParseRobotMapRaceMask(Text);
        Text := ReadShipGreetingField('ToShipInPlanet');
        if Text = 'Yes' then
          ToShipInPlanet := 0
        else if Text = 'No' then
          ToShipInPlanet := 1
        else
          ToShipInPlanet := 2;
        Text := ReadShipGreetingField('ToShipBad');
        if Text = 'Yes' then
          ToShipBad := 0
        else if Text = 'No' then
          ToShipBad := 1
        else
          ToShipBad := 2;
        Text := ReadShipGreetingField('ToShipRelations');
        ToShipRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(ToShipRelations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(ToShipRelations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(ToShipRelations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(ToShipRelations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(ToShipRelations, 4);
        end;
        Text := ReadShipGreetingField('PlayerPirateRank');
        PlayerPirateRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Noobie', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 0);
          if Pos('Kid', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 1);
          if Pos('Rader', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 2);
          if Pos('Skipper', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 3);
          if Pos('Rough', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 4);
          if Pos('Ataman', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 5);
          if Pos('Khan', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 6);
          if Pos('Baron', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 7);
        end;
        Text := ReadShipGreetingField('RankShipWithPlayer');
        RankShipWithPlayerExtra := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayerExtra, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayerExtra, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayerExtra, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayerExtra, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(RankShipWithPlayerExtra, 5);
        end;
        Text := ReadShipGreetingField('Female');
        if Text = 'Yes' then
          Female := 0
        else
          Female := 1;
        Text := ReadShipGreetingField('PirateClanInToStar');
        PirateClanInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateClanInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateClanInToStar, 10);
        end;
        Text := ReadShipGreetingField('ToStarControlByPirates');
        if Text = 'Yes' then
          ToStarControlByPirates := 0
        else if Text = 'Any' then
          ToStarControlByPirates := 2
        else
          ToStarControlByPirates := 1;
        Text := ReadShipGreetingField('PirateClanInCurStar');
        PirateClanInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateClanInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateClanInCurStar, 10);
        end;
        // Native repeats this assignment; preserve both reads.
        Text := ReadShipGreetingField('PirateInToStar');
        PirateInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInToStar, 10);
        end;
        Text := ReadShipGreetingField('CoalitionAlreadyDefeated');
        if Text = 'Yes' then
          CoalitionAlreadyDefeated := 0
        else if Text = 'No' then
          CoalitionAlreadyDefeated := 1
        else
          CoalitionAlreadyDefeated := 2;
        Text := ReadShipGreetingField('DominatorsAlreadyDefeated');
        if Text = 'Yes' then
          DominatorsAlreadyDefeated := 0
        else if Text = 'No' then
          DominatorsAlreadyDefeated := 1
        else
          DominatorsAlreadyDefeated := 2;
      end;
    end;
end;
procedure InitializeGovernmentGreetingDefinitions;
var
  Block: TBlockParEC;
  Index, EntryIndex, Item, Count: Integer;
  Text: WideString;
  function ReadGovernmentGreetingField(
      FieldName: WideString
  ): WideString; // @addr $534EC4 @ida "void __usercall $name(unsigned __int16 *FieldName@<eax>, unsigned __int16 **Result@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x5350c2,0x53510d,0x535135,0x5351df,0x5352d7,0x53546b,0x535570,0x53559e,0x5355f5,0x535711,0x535768,0x5358AD,0x5359C9,0x535ae5,0x535BAB,0x535cc7,0x535D8F,0x535e57,0x535f1f,0x535fe7,0x5360af,0x536106,0x536151,0x5361a8,0x5361ff,0x53631b,0x536372,0x5364b7,0x5365d3,0x5366ef,0x5367b5,0x5368D1,0x536928,0x5369f0,0x536AB8,0x536B80,0x536C48,0x536d10,0x536d67,0x536DBE,0x536e15,0x536E6C,0x536f34,0x536ffc,0x537053,0x5370aa,0x537101"
  begin
    if Block.CountParams(FieldName) > 0 then
      Result := Block.GetParam(FieldName)
    else
      Result := '';
  end;
begin
  GovernmentGreetingCount := 0;
  Count := StrToInt(AnsiString(LookupLocalizedTextByKey('GovGreetings.CountGovGreetings')));
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('GovGreetings').CountBlocks(WideString(IntToStr(Index))) > 0 then
      Inc(GovernmentGreetingCount);
  SetLength(GovernmentGreetingDefinitions, GovernmentGreetingCount);
  GovernmentGreetingCount := 0;
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('GovGreetings').CountBlocks(WideString(IntToStr(Index)))
        <> 0 then
    begin
      Inc(GovernmentGreetingCount);
      EntryIndex := GovernmentGreetingCount - 1;
      Block := LanguageDataConfig.GetBlockByPath(WideString('GovGreetings.' + IntToStr(Index)));
      with GovernmentGreetingDefinitions[EntryIndex] do
      begin
        Name := WideString(IntToStr(Index));
        Text := ReadGovernmentGreetingField('Priority');
        if Text = '' then
          Priority := 10
        else
          Priority := StrToInt(AnsiString(Text));
        Text := ReadGovernmentGreetingField('PlayerRace');
        PlayerRace := ParseRobotMapRaceMask(Text);
        Text := ReadGovernmentGreetingField('PlayerStatus');
        PlayerStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 0);
          if Pos('Pirate', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 1);
          if Pos('Warrior', AnsiString(Text)) > 0 then
            Include(PlayerStatus, 2);
        end;
        Text := ReadGovernmentGreetingField('PlayerRating');
        PlayerRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(PlayerRating, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(PlayerRating, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(PlayerRating, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(PlayerRating, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(PlayerRating, 5);
        end;
        Text := ReadGovernmentGreetingField('PlayerRank');
        PlayerRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', AnsiString(Text)) > 0 then
            Include(PlayerRank, 0);
          if Pos('Cadet', AnsiString(Text)) > 0 then
            Include(PlayerRank, 1);
          if Pos('Pilot', AnsiString(Text)) > 0 then
            Include(PlayerRank, 2);
          if Pos('Wingman', AnsiString(Text)) > 0 then
            Include(PlayerRank, 3);
          if Pos('Leader', AnsiString(Text)) > 0 then
            Include(PlayerRank, 4);
          if Pos('Ace', AnsiString(Text)) > 0 then
            Include(PlayerRank, 5);
          if Pos('Commander', AnsiString(Text)) > 0 then
            Include(PlayerRank, 6);
          if Pos('Admiral', AnsiString(Text)) > 0 then
            Include(PlayerRank, 7);
        end;
        Text := ReadGovernmentGreetingField('Goods');
        if Text = '' then
          Goods := 42
        else if Text = 'Food' then
          Goods := 0
        else if Text = 'Medicine' then
          Goods := 1
        else if Text = 'Technics' then
          Goods := 2
        else if Text = 'Luxury' then
          Goods := 3
        else if Text = 'Minerals' then
          Goods := 4
        else if Text = 'Alcohol' then
          Goods := 5
        else if Text = 'Arms' then
          Goods := 6
        else if Text = 'Narcotics' then
          Goods := 7
        else
          Goods := 42;
        Text := ReadGovernmentGreetingField('CurPlanetRace');
        CurPlanetRace := ParseRobotMapRaceMask(Text);
        Text := ReadGovernmentGreetingField('CurPlanetRaceIsPlayerRace');
        if Text = 'Yes' then
          CurPlanetRaceIsPlayerRace := 0
        else if Text = 'No' then
          CurPlanetRaceIsPlayerRace := 1
        else
          CurPlanetRaceIsPlayerRace := 2;
        Text := ReadGovernmentGreetingField('CurPlanetRelations');
        CurPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(CurPlanetRelations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(CurPlanetRelations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(CurPlanetRelations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(CurPlanetRelations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(CurPlanetRelations, 4);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsPermit');
        if Text = 'Yes' then
          CurPlanetGoodsPermit := 0
        else if Text = 'No' then
          CurPlanetGoodsPermit := 1
        else
          CurPlanetGoodsPermit := 2;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsCnt');
        CurPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsCnt, 5);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsSale');
        CurPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsSale, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsSale, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsSale, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsSale, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsSale, 5);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsBuy');
        CurPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsBuy, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsBuy, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsBuy, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsBuy, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(CurPlanetGoodsBuy, 5);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetEconomy');
        CurPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', AnsiString(Text)) > 0 then
            Include(CurPlanetEconomy, 0);
          if Pos('Mixed', AnsiString(Text)) > 0 then
            Include(CurPlanetEconomy, 1);
          if Pos('Industrial', AnsiString(Text)) > 0 then
            Include(CurPlanetEconomy, 2);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoverment');
        CurPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', AnsiString(Text)) > 0 then
            Include(CurPlanetGovernment, 0);
          if Pos('Dictatorship', AnsiString(Text)) > 0 then
            Include(CurPlanetGovernment, 1);
          if Pos('Monarchy', AnsiString(Text)) > 0 then
            Include(CurPlanetGovernment, 2);
          if Pos('Republic', AnsiString(Text)) > 0 then
            Include(CurPlanetGovernment, 3);
          if Pos('Democracy', AnsiString(Text)) > 0 then
            Include(CurPlanetGovernment, 4);
        end;
        Text := ReadGovernmentGreetingField('RangerInCurStar');
        RangerInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(RangerInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(RangerInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('PirateInCurStar');
        PirateInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('KlingInCurStar');
        KlingInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(KlingInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(KlingInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('WarriorInCurStar');
        WarriorInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(WarriorInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(WarriorInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('TransportInCurStar');
        TransportInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(TransportInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(TransportInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('CurStarInBattle');
        if Text = 'Yes' then
          CurStarInBattle := 0
        else if Text = 'Any' then
          CurStarInBattle := 2
        else
          CurStarInBattle := 1;
        Text := ReadGovernmentGreetingField('ToPlanetRace');
        if Text = 'Any' then
          ToPlanetRace := [0..4]
        else
          ToPlanetRace := ParseRobotMapRaceMask(Text);
        Text := ReadGovernmentGreetingField('ToPlanetRaceIsPlayerRace');
        if Text = 'Yes' then
          ToPlanetRaceIsPlayerRace := 0
        else if Text = 'No' then
          ToPlanetRaceIsPlayerRace := 1
        else
          ToPlanetRaceIsPlayerRace := 2;
        Text := ReadGovernmentGreetingField('ToPlanetRaceIsCurPlanetRace');
        if Text = 'Yes' then
          ToPlanetRaceIsCurPlanetRace := 0
        else if Text = 'No' then
          ToPlanetRaceIsCurPlanetRace := 1
        else
          ToPlanetRaceIsCurPlanetRace := 2;
        Text := ReadGovernmentGreetingField('ToPlanetRelations');
        ToPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 0);
          if Pos('Bad', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 1);
          if Pos('Normal', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 2);
          if Pos('Good', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 3);
          if Pos('Best', AnsiString(Text)) > 0 then
            Include(ToPlanetRelations, 4);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsPermit');
        if Text = 'Yes' then
          ToPlanetGoodsPermit := 0
        else if Text = 'No' then
          ToPlanetGoodsPermit := 1
        else
          ToPlanetGoodsPermit := 2;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsCnt');
        ToPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 0);
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsCnt, 5);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsSale');
        ToPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsSale, 5);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsBuy');
        ToPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 1);
          if Pos('Small', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 2);
          if Pos('Average', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 3);
          if Pos('Big', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 4);
          if Pos('Huge', AnsiString(Text)) > 0 then
            Include(ToPlanetGoodsBuy, 5);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetEconomy');
        ToPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 0);
          if Pos('Mixed', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 1);
          if Pos('Industrial', AnsiString(Text)) > 0 then
            Include(ToPlanetEconomy, 2);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 0);
          if Pos('Dictatorship', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 1);
          if Pos('Monarchy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 2);
          if Pos('Republic', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 3);
          if Pos('Democracy', AnsiString(Text)) > 0 then
            Include(ToPlanetGovernment, 4);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetInCurStar');
        if Text = 'Any' then
          ToPlanetInCurStar := 2
        else if Text = 'No' then
          ToPlanetInCurStar := 1
        else
          ToPlanetInCurStar := 0;
        Text := ReadGovernmentGreetingField('RangerInToStar');
        RangerInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(RangerInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(RangerInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('PirateInToStar');
        PirateInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('KlingInToStar');
        KlingInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(KlingInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(KlingInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('WarriorInToStar');
        WarriorInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(WarriorInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(WarriorInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('TransportInToStar');
        TransportInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(TransportInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(TransportInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('ToStarControlByKling');
        if Text = 'Yes' then
          ToStarControlByKling := 0
        else if Text = 'Any' then
          ToStarControlByKling := 2
        else
          ToStarControlByKling := 1;
        Text := ReadGovernmentGreetingField('ToStarInBattle');
        if Text = 'Yes' then
          ToStarInBattle := 0
        else if Text = 'Any' then
          ToStarInBattle := 2
        else
          ToStarInBattle := 1;
        Text := ReadGovernmentGreetingField('CurPlanetPirateClan');
        if Text = 'Yes' then
          CurPlanetPirateClan := 0
        else if Text = 'No' then
          CurPlanetPirateClan := 1
        else
          CurPlanetPirateClan := 2;
        Text := ReadGovernmentGreetingField('CurStarInBattlePirates');
        if Text = 'Yes' then
          CurStarInBattlePirates := 0
        else if Text = 'Any' then
          CurStarInBattlePirates := 2
        else
          CurStarInBattlePirates := 1;
        Text := ReadGovernmentGreetingField('PirateClanInCurStar');
        PirateClanInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateClanInCurStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateClanInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('PirateClanInToStar');
        PirateClanInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), AnsiString(Text)) > 0 then
              Include(PirateClanInToStar, Item);
          if Pos('Many', AnsiString(Text)) > 0 then
            Include(PirateClanInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('ToStarControlByPirates');
        if Text = 'Yes' then
          ToStarControlByPirates := 0
        else if Text = 'Any' then
          ToStarControlByPirates := 2
        else
          ToStarControlByPirates := 1;
        Text := ReadGovernmentGreetingField('CoalitionAlreadyDefeated');
        if Text = 'Yes' then
          CoalitionAlreadyDefeated := 0
        else if Text = 'No' then
          CoalitionAlreadyDefeated := 1
        else
          CoalitionAlreadyDefeated := 2;
        Text := ReadGovernmentGreetingField('DominatorsAlreadyDefeated');
        if Text = 'Yes' then
          DominatorsAlreadyDefeated := 0
        else if Text = 'No' then
          DominatorsAlreadyDefeated := 1
        else
          DominatorsAlreadyDefeated := 2;
        Text := ReadGovernmentGreetingField('PlayerPirateRank');
        PlayerPirateRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Noobie', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 0);
          if Pos('Kid', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 1);
          if Pos('Rader', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 2);
          if Pos('Skipper', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 3);
          if Pos('Rough', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 4);
          if Pos('Ataman', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 5);
          if Pos('Khan', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 6);
          if Pos('Baron', AnsiString(Text)) > 0 then
            Include(PlayerPirateRank, 7);
        end;
      end;
    end;
end;
procedure InitializePlanetAdvertDefinitions;
var
  Root, GroupBlock, Block: TBlockParEC;
  GroupIndex, BlockIndex, AdvertIndex, FoundIndex, Count: Integer;
  Text, Name: WideString;
begin
  Root := MainDataConfig.GetBlockByPath('Data\PlanetAdvt');
  SetLength(PlanetAdvertDefinitions, Root.GetBlockCount);
  for GroupIndex := 0 to High(PlanetAdvertDefinitions) do
  begin
    GroupBlock := Root.GetBlockByIndex(GroupIndex);
    PlanetAdvertDefinitions[GroupIndex].Position :=
        GetPointGI(GroupBlock.GetParamByPathOrMarker('Info.Pos'));
    if GroupBlock.GetBlock('Info').CountParams('Image1') > 0 then
      PlanetAdvertDefinitions[GroupIndex].Image1 :=
          GroupBlock.GetParamByPathOrMarker('Info.Image1');
    if GroupBlock.GetBlock('Info').CountParams('Image2') > 0 then
      PlanetAdvertDefinitions[GroupIndex].Image2 :=
          GroupBlock.GetParamByPathOrMarker('Info.Image2');
    Count := GroupBlock.GetBlockCount;
    SetLength(PlanetAdvertDefinitions[GroupIndex].Adverts, Count - 2);
    AdvertIndex := 0;
    for BlockIndex := 0 to Count - 1 do
    begin
      Text := GroupBlock.GetBlockNameByIndex(BlockIndex);
      if (Text <> 'List') and (Text <> 'Info') then
      begin
        Block := GroupBlock.GetBlockByIndex(BlockIndex);
        PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Name := Text;
        if Block.CountParams('Image1') > 0 then
          PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Image1 :=
              Block.GetParam('Image1');
        if Block.CountParams('Image2') > 0 then
          PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Image2 :=
              Block.GetParam('Image2');
        PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War := 0;
        if Block.CountParams('War') > 0 then
        begin
          PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War :=
              ExtractSignedDigitsToIntW(Block.GetParam('War'));
          if PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War < -1 then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War := -1
          else if PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War > 1 then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].War := 1;
        end;
        PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 42;
        if Block.CountParams('Goods') > 0 then
        begin
          Text := Block.GetParam('Goods');
          if Text = 'Food' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 0
          else if Text = 'Medicine' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 1
          else if Text = 'Technics' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 2
          else if Text = 'Luxury' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 3
          else if Text = 'Minerals' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 4
          else if Text = 'Alcohol' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 5
          else if Text = 'Arms' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 6
          else if Text = 'Narcotics' then
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 7
          else
            PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Goods := 42;
        end;
        PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner := [];
        if Block.CountParams('Owner') > 0 then
        begin
          Text := Block.GetParam('Owner');
          if Pos('Maloc', AnsiString(Text)) > 0 then
            Include(PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner, 0);
          if Pos('Peleng', AnsiString(Text)) > 0 then
            Include(PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner, 1);
          if Pos('People', AnsiString(Text)) > 0 then
            Include(PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner, 2);
          if Pos('Fei', AnsiString(Text)) > 0 then
            Include(PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner, 3);
          if Pos('Gaal', AnsiString(Text)) > 0 then
            Include(PlanetAdvertDefinitions[GroupIndex].Adverts[AdvertIndex].Owner, 4);
        end;
        Inc(AdvertIndex);
        if AdvertIndex >= Count - 1 then
          Break;
      end;
    end;
    Block := GroupBlock.GetBlock('List');
    SetLength(PlanetAdvertDefinitions[GroupIndex].Lists, Block.GetParamCount);
    for BlockIndex := 0 to High(PlanetAdvertDefinitions[GroupIndex].Lists) do
    begin
      PlanetAdvertDefinitions[GroupIndex].Lists[BlockIndex].Key :=
          ExtractDigitsToIntW(Block.GetParamName(BlockIndex));
      Text := Block.GetParamValue(BlockIndex);
      Count := CountDelimitedPartsW(Text, ',');
      SetLength(PlanetAdvertDefinitions[GroupIndex].Lists[BlockIndex].Indices, Count);
      for AdvertIndex := 0 to Count - 1 do
      begin
        Name := TrimWideString(ExtractDelimitedPartW(Text, AdvertIndex, ','));
        FoundIndex := 0;
        // Native stops before comparing the last entry, and retains it as fallback.
        while FoundIndex < High(PlanetAdvertDefinitions[GroupIndex].Adverts) do
        begin
          if PlanetAdvertDefinitions[GroupIndex].Adverts[FoundIndex].Name = Name then
            Break;
          Inc(FoundIndex);
        end;
        if FoundIndex > High(PlanetAdvertDefinitions[GroupIndex].Adverts) then
          RaiseWideMessage('PlanetAdvtInit. Not found: ' + Name);
        PlanetAdvertDefinitions[GroupIndex].Lists[BlockIndex].Indices[AdvertIndex] := FoundIndex;
      end;
    end;
  end;
end;
function GetInnermostScreenLoop: TMessageLoopGI;
begin
  Result := TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]);
  while Result.ChildLoop <> nil do
    Result := Result.ChildLoop;
end;
procedure LinkRecoveredTypes;
begin
  TMessageLoopGI.ClassName;
end;
end.
