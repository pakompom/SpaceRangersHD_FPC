{$EXCESSPRECISION OFF}
unit aGalaxy;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aGalaxyStruct,
  aPath,
  SE_Space,
  aConst,
  GI_Panel,
  GI_MessageLoop,
  EC_Buf,
  EC_Struct,
  aMyFunction,
  EC_BlockPar,
  Classes,
  Types,
  aVector;
type
  PointerToTPlanetNews = ^TPlanetNews;
type
  TConstellation = class;
  TCustomSystemInfo = class;
  TGalaxy = class;
  THole = class;
  TInterfaceImageOverride = class;
  TInterfacePosOverride = class;
  TInterfaceSizeOverride = class;
  TInterfaceStateOverride = class;
  TInterfaceTextOverride = class;
  TStar = class;
  TStoredItem = class;
  PointerToTConstellationBoundaryRaySample = ^TConstellationBoundaryRaySample;
  PointerToTConstellationStarLink = ^TConstellationStarLink;
  PointerToTJumpGateEntry = ^TJumpGateEntry;
  PointerToTMapLineSegment = ^TMapLineSegment;
  PointerToTMovingDropItemEntry = ^TMovingDropItemEntry;
  PointerToTStarCombatEvent = ^TStarCombatEvent;
  TControlPercent = 0..100;
  TShipPopulationCounts = array[0..13] of Integer;
  TDominatorSeriesMask = set of 0..7;
  TInterfaceStateOverride = class(TObjectEx)
    FormName: WideString;
    ControlPath: WideString;
    State: Byte;
    OriginalState: Byte;
    GapE: array[0..1] of Byte;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(FormName: WideString; ControlPath: WideString; State: Byte);
    procedure SetState(State: Byte);
    function GetState: Byte;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Reapply;
  end;
  TInterfaceTextOverride = class(TObjectEx)
    FormName: WideString;
    ControlPath: WideString;
    Text: WideString;
    OriginalText: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(FormName: WideString; ControlPath: WideString; Text: WideString);
    procedure SetText(Text: WideString);
    function GetText: WideString;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Reapply;
  end;
  TInterfaceImageOverride = class(TObjectEx)
    FormName: WideString;
    ControlPath: WideString;
    ImagePath: WideString;
    OriginalImagePath: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(FormName: WideString; ControlPath: WideString; ImagePath: WideString);
    procedure SetImagePath(ImagePath: WideString);
    function GetImagePath: WideString;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Reapply;
  end;
  TInterfacePosOverride = class(TObjectEx)
    FormName: WideString;
    ControlPath: WideString;
    Position: TPoint;
    Gap14: array[0..3] of Byte;
    Depth: Double;
    OriginalPosition: TPoint;
    OriginalDepth: Double;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(
        FormName: WideString;
        ControlPath: WideString;
        DeltaX: Integer;
        DeltaY: Integer;
        DeltaDepth: Integer
    );
    procedure SetPosition(DeltaX: Integer; DeltaY: Integer; DeltaDepth: Integer);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Reapply;
  end;
  TInterfaceSizeOverride = class(TObjectEx)
    FormName: WideString;
    ControlPath: WideString;
    Size: TPoint;
    OriginalSize: TPoint;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(
        FormName: WideString;
        ControlPath: WideString;
        Width: Integer;
        Height: Integer
    );
    procedure SetSize(Width: Integer; Height: Integer);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Reapply;
  end;
  TMovingDropItemEntry = packed record
    Payload: TObject;
    Destination: TPointF;
    SourceShipId: Integer;
    InsertedIntoStar: Boolean;
    UseFlag: Byte;
    Gap12: array[0..1] of Byte;
  end;
  PMovingDropItemEntry = PointerToTMovingDropItemEntry;
  TStarCombatEvent = packed record
    StepIndex: Integer;
    CombatGroup: Integer;
    Attacker: TObject;
    Target: TObject;
    Weapon: TObject;
  end;
  PStarCombatEvent = PointerToTStarCombatEvent;
  TStarDistanceEntry = packed record
    Distance: Integer;
    Star: TStar;
  end;
  TJumpGateEntry = packed record
    Gate: TObjectSE;
    UsedThisTurn: Boolean;
    Gap5: array[0..2] of Byte;
    GateFilmId: PtrUInt;
    Effect: TObjectSE;
    EffectFilmId: PtrUInt;
  end;
  PJumpGateEntry = PointerToTJumpGateEntry;
  TSpaceBackgroundEntry = record
    ImageIndex: Integer;
    Gap4: array[0..3] of Byte;
    OrbitCenter: TVector3D;
    Position: TVector3D;
    Unknown38: TVector3D;
    OrbitStepDegrees: Double;
    FrameIndex: Integer;
    Gap5C: array[0..3] of Byte;
  end;
  TConstellationBoundaryRaySample = packed record
    Position: TPointF;
    Direction: TPointF;
    Angle: Single;
    GrowthStopped: Boolean;
    Gap15: array[0..2] of Byte;
  end;
  PConstellationBoundaryRaySample = PointerToTConstellationBoundaryRaySample;
  TMapLineSegment = packed record
    StartPoint: TPointF;
    EndPoint: TPointF;
    Gap10: array[0..11] of Byte;
  end;
  PMapLineSegment = PointerToTMapLineSegment;
  TConstellationStarLink = packed record
    StartPoint: TPointF;
    EndPoint: TPointF;
    StartStarIndex: Integer;
    EndStarIndex: Integer;
    TraversalMark: Boolean;
    Gap19: array[0..2] of Byte;
  end;
  PConstellationStarLink = PointerToTConstellationStarLink;
  TStoredItem = class(TObjectEx)
    Name: WideString;
    Item: TObject;
    constructor CreateEmpty;
    constructor Create(Name: WideString; Item: TObject);
    destructor Destroy; override;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
  end;
  TDominatorResearchEntry = packed record
    Progress: Single;
    Material: Integer;
  end;
  TDominatorSeriesSet = set of TDominatorSeries;
  TGalaxy = class(TObjectEx)
    NextConstellationId: Cardinal;
    NextStarId: Cardinal;
    NextHoleId: Cardinal;
    NextPlanetId: Cardinal;
    NextSputnikId: Cardinal;
    NextAsteroidId: Cardinal;
    NextShipId: Cardinal;
    NextItemId: Cardinal;
    NextMissileId: Cardinal;
    // CHANGE: CLEANUP - Keep campaign metadata directly in the galaxy.
    CheatPoints: Integer;
    EditableStateApplied: Boolean;
    PlayerRangerIndex: Integer;
    Stars: TObjectList;
    Holes: TObjectList;
    StoredItems: TObjectList;
    Planets: TList;
    Rangers: TList;
    PirateCount: Integer;
    PirateClanCount: Integer;
    TransportCount: Integer;
    CurrentTurn: Integer;
    DifficultyLevels: TGalaxyDifficultyLevels;
    GenerationSeed: Cardinal;
    RandomState: Cardinal;
    AverageRangerCapital: Integer;
    MaxRangerWealth: Integer;
    AverageRangerStrength: Single;
    BestRangerStrength: Single;
    StrongestRanger: TObject;
    WealthiestRanger: TObject;
    EminentCareerShips: array[0..2] of TObject;
    ShipTypeCounts: TShipPopulationCounts;
    NextPlanetNewsId: Cardinal;
    PlanetNews: TList;
    CustomWeaponTypes: TList;
    KellerTargetStar: TStar;
    KellerMissionState: Integer;
    DominatorResearch: array[0..2] of TDominatorResearchEntry;
    TechLevel: Byte;
    GapF1: array[0..2] of Byte;
    WarDeltaWin: array[0..2] of Integer;
    RangerSpawnQuotas: array[0..4] of Integer;
    TerronWeaponLockTurn: Integer;
    TerronGrowLockTurn: Integer;
    TerronLandingLockTurn: Integer;
    TerronToStarTurn: Integer;
    KellerLeaveTurn: Integer;
    KellerResearchTargetStarId: Cardinal;
    BlazerLandingPlanetId: Cardinal;
    BlazerSelfDestructTurn: Integer;
    TerronSeriesResolvedTurn: Integer;
    KellerSeriesResolvedTurn: Integer;
    BlazerSeriesResolvedTurn: Integer;
    PirateWinTurn: Integer;
    PirateWinType: Integer;
    CoalitionDefeatedTurn: Integer;
    GraphDominatorSurfacesEnabled: Boolean;
    SpaceEffectKind: Byte;
    Gap14E: array[0..1] of Byte;
    Scripts: TList;
    LiberationGroups: TList;
    JumpGates: TList;
    ShipsInTransit: TList;
    ConstellationCount: Integer;
    Constellations: TObjectList;
    ConstellationOutlineJunctions: TList;
    SpaceBackgroundEntries: array of TSpaceBackgroundEntry;
    SaveCount: Integer;
    LoadCount: Integer;
    PendingEquipmentPurchasePrice: Integer;
    IronWill: Boolean;
    DominatorModLevel: Byte;
    TechnicModEnabled: Byte;
    AmmoModEnabled: Byte;
    GodModEnabled: Byte;
    UltraScanModEnabled: Byte;
    StasisModEnabled: Byte;
    CampaignFlag183: Byte;
    FinalizationName: WideString;
    CustomRules: TGalaxyCustomRules;
    Gap1AF: array[0..0] of Byte;
    NextSpecialStationServiceTurn: Integer;
    GalaxyEvents: TObjectList;
    InterfaceStateOverrides: TObjectList;
    InterfaceTextOverrides: TObjectList;
    InterfaceImageOverrides: TObjectList;
    InterfacePositionOverrides: TObjectList;
    InterfaceSizeOverrides: TObjectList;
    LoadedShips: TList;
    ScoreScreenDismissed: Byte;
    Destroying: Boolean;
    Gap1D2: array[0..1] of Byte;
    SpecialSimulationMode: Byte;
    CheatsDisabled: Boolean;
    Gap1DA: array[0..1] of Byte;
    // CHANGE: PORTABILITY - UtilityFunctions' capital freeze is applied at the
    // recalculation site instead of racing the simulation with a 1 ms thread.
    // These are process-local mod state, deliberately absent from the save format.
    UtilityCapitalOverrideActive: Boolean;
    UtilityCapitalOverrideValue: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeCampaignState;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SaveEditableState;
    procedure ApplyEditableState;
    procedure RunConfigOnStartHandlers;
    procedure RunConfigOnLoadHandlers;
    procedure RunConfigOnSaveHandlers;
    procedure ReapplyInterfaceOverrides;
    procedure BindScriptImports;
    procedure NextDay;
    procedure CompleteDay(UnusedRecordFilm: Boolean);
    procedure TransferShipsInTransit;
    procedure RebuildStarDistances;
    procedure RefreshAllShipDerivedState;
    function IdToConstellation(Id: Cardinal): TConstellation;
    function IdToStar(Id: Cardinal): TStar;
    function IdToHole(Id: Cardinal): THole;
    function IdToPlanet(Id: Cardinal; RaiseIfMissing: Boolean = True): Pointer;
    function IdToShip(Id: Cardinal; RaiseIfMissing: Boolean): Pointer;
    function IdToItem(Id: Cardinal; RaiseIfMissing: Boolean): Pointer;
    function IdToAsteroid(Id: Cardinal): Pointer;
    function IdToMissile(Id: Cardinal): Pointer;
    function ContainsShipReference(Ship: Pointer): Boolean;
    function ContainsPlanetReference(Planet: Pointer): Boolean;
    procedure ClearJumpGates;
    function CreateJumpGate(WithEffect: Boolean): PJumpGateEntry;
    function FindHoleInStarByKind(Star: TStar; HoleKind: Integer): THole;
    procedure ReleaseItemGraphics;
    procedure GenerateSpaceBackground(BackgroundIndex: Integer);
    procedure EnableDominatorSurfaces;
    procedure DisableDominatorSurfaces;
    function HasVisibleScoreModFlags: Boolean;
    function GetCheatPoints: Integer;
    procedure SetCheatPoints(Value: Integer);
    function FindConstellationIndexForStar(Star: TStar): Integer;
    procedure InitializeConstellationDistanceTiers;
    procedure BuildConstellationOutlineJunctions;
    function ShouldKeepConstellationOutlineVertex(Point: TPointF): Boolean;
    procedure SimplifyConstellationOutline(ConstellationIndex: Integer);
    function BuildConstellationStarGraphs: Boolean;
    procedure BuildConstellationPolygonsAndAdjacency(WorkingPolygon: TPolygon2D);
    procedure GenerateGalaxyLayout(PlayerRace: Byte);
    procedure HideSpecialConstellation;
    function CountVisibleConstellationsWithBoundaryPoints(
        FirstPoint: TPointF;
        SecondPoint: TPointF
    ): Integer;
    function CountEligibleRangers: Integer;
    procedure RefreshRangerWealthStats;
    procedure RefreshRangerStrengthStats;
    procedure RefreshRangerRatingPlaces;
    function FindStrongestRanger: Pointer;
    function FindWealthiestRanger: Pointer;
    function CountFactionStars(Faction: Byte): Integer;
    function GetFactionControlPercent(Faction: Byte): TControlPercent;
    function GetDominatorSeriesControlShare(Series: TDominatorSeries): Single;
    function CountStarsInBattle: Integer;
    procedure AssignTextQuestsToPlanets;
    function HasPlayerQuestHistory(QuestType: TQuestType; QuestNumber: Word): Boolean;
    function TurnToDateTime(Turn: Integer): Double;
    function FormatTurnDate(Turn: Integer): WideString;
    procedure AddPlanetNewsWithPlayerBubble(NewsType: Byte; Text: WideString);
    procedure AddPlanetNews(NewsType: Byte; Text: WideString);
    function CountPlanetNewsByType(NewsType: Byte): Integer;
    procedure PrunePlanetNews;
    procedure CreateDominatorSpawnProxy(Star: TStar);
    procedure UpdateConstellationMilitaryStats;
    function RefreshTechLevel: Byte;
    procedure CancelEnemyJumpsToStar(Star: TStar);
    function SelectStarForLiberationAttack(Origin: TStar; FriendlyFaction: TStarFaction): TStar;
    procedure ComputeGlobalGoodsPriceBands;
    function GetGoodsPricePercent(GoodsType: Byte; Price: Integer): Byte;
    function ScaleGoodsPriceByGalaxyAge(BaseValue: Integer): Integer;
    function ScaleGoodsStockByGalaxyAge(BaseValue: Integer): Integer;
    function ScaleIntByTechLevel(AtLevelTwo: Integer; AtLevelSeven: Integer): Integer;
    function InterpolateSingleByTechLevel(AtLevelTwo: Single; AtLevelSeven: Single): Single;
    function SelectWeaponInfo(
        Seed: Cardinal;
        AvailabilityMask: TWeaponAvailabilityMask;
        MaximumTechLevel: Byte;
        MinimumTechLevel: Byte
    ): PWeaponInfo;
    function SelectMicroModule(
        MinimumPriority: Byte;
        MaximumPriority: Byte;
        Seed: Cardinal;
        Context: TObject
    ): Integer;
    function SelectMicroModuleForEquipment(
        MinimumPriority: Byte;
        MaximumPriority: Byte;
        Seed: Cardinal;
        Context: TObject;
        Item: Pointer
    ): Integer;
    function SelectHullSeries(
        OwnerId: Byte;
        HullType: Byte;
        MinimumRarity: Byte;
        MaximumRarity: Byte
    ): Integer;
    function IsDominatorSeriesUnresolved(Series: TDominatorSeries): Boolean;
    function HasUnresolvedDominatorSeries(Series: TDominatorSeriesSet): Boolean;
    procedure ProcessPlayerSatelliteExploration;
    function CountExistingSatellites: Integer;
    function ComputeScaledMiniMoney(ScaleIndex: Byte): Integer;
    function ComputeScaledSmallMoney(ScaleIndex: Byte): Integer;
    function ComputeScaledAverageMoney(ScaleIndex: Byte): Integer;
    function ComputeScaledBigMoney(ScaleIndex: Byte): Integer;
    function ComputeScaledHugeMoney(ScaleIndex: Byte): Integer;
    function ResolveMoneySizeTag(Tag: WideString; ScaleIndex: Byte): Integer;
    function GetMiniGoodsQuantity(GoodsType: Byte): Integer;
    function GetSmallGoodsQuantity(GoodsType: Byte): Integer;
    function GetAverageGoodsQuantity(GoodsType: Byte): Integer;
    function GetBigGoodsQuantity(GoodsType: Byte): Integer;
    function GetHugeGoodsQuantity(GoodsType: Byte): Integer;
    function GetGoodsQuantityBySize(Size: Byte; GoodsType: Byte): Integer;
    function ClassifyGoodsQuantity(Quantity: Integer; GoodsType: Byte): Byte;
    function GetMinimumGoodsPrice(GoodsType: Byte): Integer;
    function GetLowGoodsPrice(GoodsType: Byte): Integer;
    function GetAverageGoodsPrice(GoodsType: Byte): Integer;
    function GetHighGoodsPrice(GoodsType: Byte): Integer;
    function GetMaximumGoodsPrice(GoodsType: Byte): Integer;
    function GetGoodsPriceByLevel(Level: Byte; GoodsType: Byte): Integer;
    function ClassifyGoodsPrice(Price: Integer; GoodsType: Byte): Byte;
    procedure ProcessStationSpawning;
    procedure ReplenishStationType(StationType: TStationType);
    procedure ProcessDominatorResearchProgress;
    function IsDominatorResearchComplete(Series: TDominatorSeriesSet): Boolean;
    function GetDominatorResearchRate(Series: TDominatorSeries): Single;
    function GetDominatorResearchEfficiency(Series: TDominatorSeries): Byte;
    function FindStationByTypeAndIndex(Index: Integer; StationType: TStationType): Pointer;
    procedure TryAwardDepositPrize;
    procedure ProcessBankDebtAndDeposits;
    procedure ProcessRangerCenterNewYearEvent;
    function TryCreateLiberationGroup: Boolean;
    function TryDispatchMilitaryBaseToEnemyStar: Boolean;
    function FindMilitaryBaseInTransit: Pointer;
    function HasMilitaryBaseAssignedToStar(Star: TStar): Boolean;
    function HasLiberationGroupTargetingStar(Star: TStar): Boolean;
    procedure AssignSpecialStationService;
    procedure ApplyWingmanLeadershipPenalty;
    procedure ProcessCoalitionDefeat;
    procedure ComputeRangerSpawnQuotas;
    procedure PruneExpiredGalaxyEvents;
    function GetCoalitionToPirateSystemRatio: Single;
    function GetEffectiveDifficultyLevel: Integer;
    function GetDifficultyTierIndex: Byte;
    function InterpolateDifficulty(
        Level: Integer;
        AtZero: Single;
        AtEight: Single;
        AtSixteen: Single;
        AtTwentyFour: Single
    ): Single;
    function ScaleDifficultyExponentially(
        Level: Integer;
        BaseValue: Single;
        FactorPerEightLevels: Single
    ): Single;
    function GetDominatorBossHullScale: Single;
    function GetDominatorKillExperienceScale: Single;
    function GetTurnsBetweenLiberationGroups: Integer;
    function GetInitialDominatorControlPercent: Integer;
    function GetDominatorAggressionLevel: Integer;
    function GetDominatorSpawnLevel: Integer;
    function GetPirateAggressionLevel: Integer;
    function IsChaoticRandomEnabled: Boolean;
    function AreStationsNearStarsEnabled: Boolean;
    function IsFullStationTargetingEnabled: Boolean;
    function IsEquipmentKnowledgeUnrestricted: Boolean;
    function GetAsteroidModifier: Single;
    function GetStarDamageDifficultyScale: Single;
    function AreSpecialShipsEnabled: Boolean;
    function GetMicroModuleOfferRollThresholdPercent: Single;
    function GetNodeDropModifier: Single;
    function GetArcadeDropValueModifier: Single;
    function GetDropValueModifier: Single;
    function GetAgriculturalPlanetWeight: Integer;
    function GetMixedPlanetWeight: Integer;
    function GetIndustrialPlanetWeight: Integer;
    function IsZeroStartingExperienceEnabled: Boolean;
    function GetExtraRangerCount: Integer;
    function IsArcadeBattleRoyaleEnabled: Boolean;
    function GetArcadeHitpointsModifier: Single;
    function GetArcadeDamageModifier: Single;
    function AreDominatorRacialWeaponsEnabled: Boolean;
    function GetAIJunkToleranceLevel: Integer;
    function AreMaxRangeMissilesEnabled: Boolean;
    function IsOldHyperspaceEnabled: Boolean;
    function ArePirateNodesEnabled: Boolean;
    function IsAIShoppingEnabled: Boolean;
    function IsStationShopUpdateEnabled: Boolean;
    function AreDuplicateArtefactsEnabled: Boolean;
    function GetHullGrowthMod: Byte;
    function IsArcadeEquipmentChangeEnabled: Boolean;
    function IsOldSpeedCalculationEnabled: Boolean;
    function AreOldMissileBonusesEnabled: Boolean;
    procedure ShowLocalizedWarning(TextKey: WideString);
    procedure StoreItem(Name: WideString; Item: TObject);
    function GetStoredItem(Name: WideString; Remove: Boolean): TObject;
    function GetOrCreateCustomWeaponInfo(Name: WideString): PWeaponInfo;
    function RequireCustomWeaponInfo(Name: WideString): PWeaponInfo;
    function CanRecordAchievements: Boolean;
  end;
  TConstellation = class(TObjectEx)
    Id: Cardinal;
    HomeDistanceTier: Byte;
    Visible: Boolean;
    GapA: array[0..1] of Byte;
    MapCenter: TPointF;
    OutlineGrowthStepsRemaining: Integer;
    Stars: TList;
    AdjacentConstellations: TList;
    OutlineSegments: TList;
    HiddenOutlineSegmentsBackup: TList;
    BoundaryRaySamples: TList;
    OutlineBounds: TRect;
    OutlineBoundsSize: TPoint;
    StarLinks: TList;
    ShipTypeCounts: array[0..13] of Integer;
    OutlinePolygons: TPolygon2D;
    HiddenOutlinePolygonsBackup: TPolygon2D;
    SerializedValue88: Word;
    Gap8A: array[0..1] of Byte;
    procedure RestoreHiddenForm;
    constructor Create;
    destructor Destroy; override;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
    procedure ResolveLoadedReferences(Galaxy: TGalaxy);
    procedure ClearStarLinks;
    procedure ClearBoundaryRaySamples;
    procedure GenerateBoundaryRaySamples(Count: Integer);
    procedure SetOutlinePolygon(Polygon: TPolygon2D);
    procedure RebuildOutlineSegments;
    procedure ClearOutlineSegmentsAndBounds;
    procedure AddStar(Star: TStar);
    procedure AddAdjacentConstellation(Constellation: TConstellation);
    function SharesOutlineSegment(Constellation: TConstellation): Boolean;
    procedure ResetGeneratedMapShape;
    procedure ClearStars;
    procedure ClearAdjacentConstellations;
    function GetOutlineArea: Single;
    function FindNextClosestStarPair(
        var FirstStar: TStar;
        var SecondStar: TStar;
        MinimumDistance: Integer
    ): Integer;
    function HasStarGraphCycle: Boolean;
    function IsStarGraphConnected: Boolean;
    function BuildStarGraph: Boolean;
    procedure ExpandOutlineBounds(Point: TPointF);
    procedure RefreshOutlineBounds;
    function ContainsPoint(Point: TPointF): Boolean;
    function HasAdjacentConstellation(Constellation: TConstellation): Boolean;
    function HasOutlineSegment(FirstPoint: TPointF; SecondPoint: TPointF): Boolean;
    function AreBothPointsOnOutline(FirstPoint: TPointF; SecondPoint: TPointF): Boolean;
    function CalculateLabelPosition: TPointF;
    function HasOutlineVertex(Point: TPointF): Boolean;
    function IsPointNearOutline(Point: TPointF): Boolean;
    procedure NormalizeOutlineSegmentOrder;
    function GetName: WideString;
    function HasDominatorPresence: Boolean;
    function HasPirateClanPresence: Boolean;
    function HasBertorOfSeries(Series: TDominatorSeries): Boolean;
    function CountShipsByTypeMask(ShipTypeMask: TShipTypeMask): Integer;
  end;
  THole = class(TObjectEx)
    Id: Cardinal;
    Star1: TStar;
    Position1: TPointF;
    Star2: TStar;
    Position2: TPointF;
    CreatedTurn: Integer;
    HoleType: Integer;
    Graphic: TObjectSE;
    FilmObjectId: PtrUInt;
    ArcadeMapName: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeGraphic(GraphKey: WideString);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
    procedure ResolveLoadedReferences(Galaxy: TGalaxy);
    procedure SaveToBlock(Block: TBlockParEC);
    procedure LoadFromBlock(Block: TBlockParEC);
  end;
  PPlanetNewsEntry = PointerToTPlanetNews;
  TCustomSystemInfo = class(TObjectEx)
    Name: WideString;
    Icon: WideString;
    Info: WideString;
    TypeTag: WideString;
    Distance: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SaveToBuffer(Buffer: TBufEC);
  end;
  TStar = class(TObject)
    Id: Cardinal;
    GenerationSeed: Cardinal;
    RandomState: Cardinal;
    Name: WideString;
    Position: TPointF;
    SystemRadius: Word;
    Gap1E: array[0..1] of Byte;
    MapDiameter: Integer;
    Planets: TObjectList;
    Asteroids: TObjectList;
    Ships: TObjectList;
    Items: TObjectList;
    MovingDropItems: TList;
    Missiles: TObjectList;
    SystemProcessName: WideString;
    Status: TStarStatus;
    SafeRadius: Single;
    DamageRadius: Single;
    Reserved64: Integer;
    Radius: Integer;
    Graphic: TObjectSE;
    DaysSincePlayerVisit: Integer;
    DaysSinceLastNpcShipSpawn: Integer;
    PlayerPresenceLevel: Integer;
    BackgroundImage: Integer;
    Flag80: Byte;
    Gap81: array[0..2] of Byte;
    LastDominatorPresenceTurn: Integer;
    LastPiratePresenceTurn: Integer;
    LastLiberationRewardsTurn: Integer;
    LiberationRewardsPending: Boolean;
    Gap91: array[0..2] of Byte;
    StarDistances: array of TStarDistanceEntry;
    ShipTypeCounts: array[0..13] of Integer;
    Constellation: TConstellation;
    ConstellationGraphIndex: Word;
    GapD6: array[0..1] of Byte;
    NoComeKling: Boolean;
    GapD9: array[0..2] of Byte;
    Dominion: TObject;
    MapLabel: WideString;
    CustomSystemInfos: TObjectList;
    CurrentStepIndex: Integer;
    SimulationStepCount: Integer;
    RecordingTurnFilm: Boolean;
    PlayerCombatOccurred: Boolean;
    InterruptLongTravel: Boolean;
    KeepFilmRunning: Boolean;
    CombatEvents: TList;
    PendingFilmObjectRemovals: TList;
    ReferencedItems: TList;
    PlayerFilmPath: TSPath;
    MovementStepCount: Integer;
    MovementStepScale: Extended;
    Gap112: array[0..1] of Byte;
    constructor Create;
    destructor Destroy; override;
    procedure GenerateSystemContents(TerronSystem: Boolean);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
    procedure ResolveLoadedReferences(Galaxy: TGalaxy);
    procedure SaveToBlock(Block: TBlockParEC);
    procedure LoadFromBlock(Block: TBlockParEC);
    procedure PruneWeaponTargetsAfterTurn;
    procedure MarkConnectedCombatEvents(Events: TList; Target: TObject; Group: Integer);
    function DropMinerals(Quantity: Integer; Position: TPointF; Seed: Cardinal): Integer;
    procedure ProcessPlayerAsteroidKill(
        MineralValue: Integer;
        Position: TPointF;
        AsteroidId: Cardinal
    );
    procedure ClearTargetReferences(Target: TObject);
    procedure ClearShipReferences(Ship: Pointer);
    procedure ClearItemReferences(Item: Pointer);
    procedure ClearCombatEventWeaponReferences(Weapon: Pointer);
    procedure PrepareNextDay;
    procedure HandleObjectLeavingStar(Obj: TObject);
    procedure AvoidShipPathCollisions;
    procedure RebuildShipMovementPaths;
    procedure OpenSpaceScene(MapPanel: TPanelGI; Minimap: TObjectGI; Screen: TMessageLoopGI);
    procedure RefreshSpaceObjectPositions;
    procedure QueueSpaceImageLoads(PendingLoads: TList; Owner: TObjectGI);
    procedure QueueHyperspaceShipImageLoads(PendingLoads: TList; Owner: TObjectGI);
    function GetBackgroundImagePath(out Size: Integer): WideString;
    procedure ProcessItemScripts(TurnPhase: Integer);
    procedure RefreshDominatorSeries;
    procedure RefreshDerivedStats;
    procedure GetControlPresence(
        out PlayerPartyPresent: Boolean;
        out CoalitionPresent: Boolean;
        out DominatorsPresent: Boolean;
        out PiratesPresent: Boolean;
        out CustomPresent: Boolean
    );
    procedure UpdateControlFaction;
    procedure ResetControlFaction;
    procedure RefreshMapDiameterAndStats;
    procedure RefreshMovementStepParameters;
    function ComputeMapDiameter: Integer;
    function CountPlanetsByOwner(OwnerId: Byte): Integer;
    function CountDistinctInhabitedPlanetOwners: Integer;
    function FindFirstInhabitedPlanet: Pointer;
    function SelectRandomInhabitedPlanet: Pointer;
    function FindFastestResearchPlanet: Pointer;
    procedure RefreshShipTypeCounts;
    function CountEligibleRangersInSpace: Integer;
    function CountShipsByTypeMask(ShipTypeMask: TShipTypeMask): Integer;
    function CountDominatorForces(
        Series: TDominatorSeries;
        ExcludeAbsoluteOrders: Boolean;
        OtherSeries: Boolean;
        out Strength: Extended
    ): Integer;
    function CountStandardDominatorsOfLocalSeries: Integer;
    function CountPirateForces(
        ExcludeAbsoluteOrders: Boolean;
        out Strength: Extended;
        IncludeClanVariants: Boolean;
        IncludeIndependent: Boolean
    ): Integer;
    function CountCustomFactionForces(
        ExcludeAbsoluteOrders: Boolean;
        out Faction: WideString;
        out Strength: Extended
    ): Integer;
    function CountOtherCustomFactionForces(
        ExcludeAbsoluteOrders: Boolean;
        out Faction: WideString;
        out Strength: Extended
    ): Integer;
    function CountPirateShips(IncludeOutsideStarSpace: Boolean): Integer;
    function CountForcesByOwnerGroups(
        out Strength: Extended;
        IncludeCoalition: Boolean;
        IncludeDominators: Boolean;
        IncludePirates: Boolean;
        IncludeCustom: Boolean
    ): Integer;
    function CountRatedRangersByCareerMask(CareerMask: TRangerCareerSet): Byte;
    function GetRangerNamesByCareerMask(CareerMask: TRangerCareerSet): WideString;
    function IsConstellationVisible: Boolean;
    function GetCachedFactionStrength(FactionGroup: Byte): Single;
    function SumBestRangerRelativeStrength(ShipTypeMask: TShipTypeMask): Single;
    procedure RebuildStarDistances(Galaxy: TGalaxy);
    function HasHostilePresenceForScriptBinding: Boolean;
    function FindNearestStarByFaction(Faction: TStarFaction; InBattle: Boolean): TStar;
    function GetBoundaryPointTowardStar(Star: TStar): TPointF;
    function HasLiberationGroupOrder: Boolean;
    procedure TryGenerateSystemNews;
    procedure NextDay(RecordFilm: Boolean);
    property ThreatLevel: Byte read Status.ThreatLevel write Status.ThreatLevel;

    property TrafficLevel: Byte read Status.TrafficLevel write Status.TrafficLevel;
    property ControlFaction: TStarFaction read Status.ControlFaction write Status.ControlFaction;
    property Battle: Byte read Status.Battle write Status.Battle;
    property DominatorSeries: TDominatorSeries
        read Status.DominatorSeries write Status.DominatorSeries;
    property PreviousControlFaction: TStarFaction
        read Status.PreviousControlFaction write Status.PreviousControlFaction;
    property FactionStrengthCacheTurn: Integer
        read Status.FactionStrengthCacheTurn write Status.FactionStrengthCacheTurn;
  end;
var
  ReservedMessageCounter: Integer = 0;
  TurnsSinceLastShipMessage: Cardinal = 0;
  Galaxy: TGalaxy;
  PlayerStar: TStar;
  PlayerDialogueRequestCount: Byte;
  WingmenPendingLeadershipPenalty: TList;
  CameraSpeed: Integer = 10;
  FastCameraSpeed: Integer = 20;
function GameTurnToDateTime(Turn: Integer): Double;
function FormatGameTurnDate(Turn: Integer): WideString;
function ShouldContinuePlayerTravel: Boolean;
function EstimatePlayerTravelTurns: Single;
function GetLocalObjectLink(Obj: TObject; Suppress: Boolean): WideString;
procedure LinkRecoveredTypes;
procedure UpdateTurnFilmActivity(
    CombatOccurred: Boolean;
    out InitialActivity, FinalActivity: Integer
);
implementation

uses
  ObserverHooks,
  SE_Garbage,
  SE_Sputnik,
  aEObjInfo,
  fGov,
  fGoodsShop2,
  EC_Expression,
  ab_Ship,
  SE_Planet,
  SE_Gate,
  ThreadCalc,
  aCalc,
  SE_Ruins,
  aNormalShip,
  aGroup,
  aWarrior,
  aTranclucator,
  aRuins,
  aGalaxyEvent,
  PathClass,
  ParameterDeltaClass,
  ParameterClass,
  LocationClass,
  TextQuest,
  SE_Asteroid,
  aAsteroid,
  aRanger,
  EC_CacheBuf,
  fPlanetQuest,
  aScript,
  aItem,
  aKling,
  aMissile,
  aShip,
  fScore,
  aPirate,
  aEFilm,
  SE_Hole,
  SE_Process,
  SE_Ship2,
  SE_Weapon,
  Achievements,
  aPlanet,
  fShip2,
  fHangar,
  fEquipmentShop,
  aPlayer,
  GI_GI,
  GI_GAI,
  GI_GraphButton,
  GI_Label,
  GI_Image,
  GR_Sound,
  CrcUnit,
  EC_Mem,
  EC_Cache,
  Globals,
  fFilmFile,
  GR_Main,
  EC_Str,
  GlobalsV,
  GR_GraphBuf,
  Math,
  SysUtils,
  Windows;

function SingleToPointer(Value: Single): Pointer; inline;
var
  Bits: Cardinal;
begin
  Move(Value, Bits, SizeOf(Bits));
  Result := Pointer(PtrUInt(Bits))
end;
function PointerToSingle(Value: Pointer): Single; inline;
var
  Bits: Cardinal;
begin
  Bits := PtrUInt(Value);
  Move(Bits, Result, SizeOf(Result))
end;
constructor TGalaxy.Create;
var
  Template: TScriptTemplUnit;
  TemplateCount, I: Integer;
  Block: TBlockParEC;
  function ParseCheatsDisabledFlag(
      Value: WideString
  ): Boolean; // @addr 0x79C7D4 @ida "bool __usercall $name@<al>(unsigned __int16 *Value@<eax>, void *ParentFrame@<^0>);" @note "Nested in TGalaxy.Create; unused caller-popped static link. Accepts exactly Yes, yes, True, true, TRUE or 1; no trimming."
  begin
    if (Value = 'Yes')
        or (Value = 'yes')
        or (Value = 'True')
        or (Value = 'true')
        or (Value = 'TRUE')
        or (Value = '1') then
      Result := True
    else
      Result := False;
  end;
begin
  inherited Create;
  CheatsDisabled := False;
  Block := MainDataConfig.GetBlock('BV');
  if Block.CountParams('CheatsDisabled') > 0 then
    if ParseCheatsDisabledFlag(TrimWideString(Block.GetParamByPathOrMarker('CheatsDisabled'))) then
      CheatsDisabled := True;
  GameEndReason := 0;
  PlayerRangerIndex := -1;
  for I := 0 to 8 do
    HangarScreen.ShipSlots[I].ShipId := 0;
  SaveCount := 0;
  LoadCount := 0;
  Randomize;
  GenerationSeed := RandomIntRange(100000, MaxInt);
  SetCheatPoints(0);
  RandomState := GenerationSeed;
  AverageRangerCapital := 3000;
  MaxRangerWealth := 3000;
  AverageRangerStrength := 1;
  BestRangerStrength := 1;
  ConstellationCount := 20;
  Constellations := TObjectList.Create;
  Stars := TObjectList.Create;
  Holes := TObjectList.Create;
  StoredItems := TObjectList.Create;
  Planets := TList.Create;
  Rangers := TList.Create;
  ShipsInTransit := TList.Create;
  Scripts := TList.Create;
  LiberationGroups := TList.Create;
  PlanetNews := TList.Create;
  CustomWeaponTypes := TList.Create;
  if PrimaryFilm <> nil then
    PrimaryFilm.Clear;
  if SecondaryFilm <> nil then
    SecondaryFilm.Clear;
  ClearPersistentPlayerMessages;
  JumpGates := TList.Create;
  NextConstellationId := 1;
  NextStarId := 1;
  NextHoleId := 1;
  NextPlanetId := 1;
  NextSputnikId := 1;
  NextAsteroidId := 1;
  NextShipId := 1;
  NextItemId := 1;
  NextMissileId := 1;
  SharedScriptVariables.CopyFrom(GlobalScriptVariables, True);
  TemplateCount := ScriptTemplates.Count;
  for I := 0 to TemplateCount - 1 do
  begin
    Template := ScriptTemplates[I];
    Template.UseCount := 0;
    Template.LastTurn := 0;
    Template.ConditionCode.LinkAll(SharedScriptVariables, False);
    Template.ConditionCode.LinkAll(ScriptFunctionScope, False);
    Template.ConditionCode.ScriptFunLinked := True;
    Template.ActiveScriptIndex := -1;
  end;
  PreviousFilmActivity := 0;
  ShownPlayerTips := 0;
  EminentCareerShips[Ord(rcTrader)] := nil;
  EminentCareerShips[Ord(rcPirate)] := nil;
  EminentCareerShips[Ord(rcWarrior)] := nil;
  ReservedMessageCounter := 0;
  TurnsSinceLastShipMessage := 0;
  IronWill := False;
  DominatorModLevel := 0;
  TechnicModEnabled := 0;
  AmmoModEnabled := 0;
  GodModEnabled := 0;
  UltraScanModEnabled := 0;
  StasisModEnabled := 0;
  NextSpecialStationServiceTurn := 0;
  GalaxyEvents := TObjectList.Create;
  ScoreScreenDismissed := 0;
  Destroying := False;
  InterfaceStateOverrides := TObjectList.Create;
  InterfaceTextOverrides := TObjectList.Create;
  InterfaceImageOverrides := TObjectList.Create;
  InterfacePositionOverrides := TObjectList.Create;
  InterfaceSizeOverrides := TObjectList.Create;
  LoadedShips := TList.Create;
  SpecialSimulationMode := 0;
end;
destructor TGalaxy.Destroy;
var
  Point: PPointF;
  I, J: Integer;
  Star: TStar;
  Planet: TPlanet;
  News: PPlanetNewsEntry;
  WeaponInfo: PWeaponInfo;
  Stored: TStoredItem;
begin
  Destroying := True;
  if ConstellationOutlineJunctions <> nil then
  begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do
    begin
      Point := ConstellationOutlineJunctions[I];
      Dispose(Point);
    end;
    ConstellationOutlineJunctions.Clear;
    ConstellationOutlineJunctions.Free;
    ConstellationOutlineJunctions := nil;
  end;
  for I := 0 to StoredItems.Count - 1 do
  begin
    Stored := TStoredItem(StoredItems[I]);
    if Stored.Item <> nil then
      Stored.Item.Free;
    Stored.Item := nil;
  end;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    while Star.Ships.Count > 0 do
      TObject(Star.Ships[0]).Free;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      while Planet.Warriors.Count > 0 do
        TObject(Planet.Warriors[0]).Free;
    end;
  end;
  if Scripts <> nil then
  begin
    for I := 0 to Scripts.Count - 1 do
      TObject(Scripts[I]).Free;
    Scripts.Free;
    Scripts := nil;
  end;
  if LiberationGroups <> nil then
  begin
    for I := 0 to LiberationGroups.Count - 1 do
      TObject(LiberationGroups[I]).Free;
    LiberationGroups.Free;
    LiberationGroups := nil;
  end;
  ClearTemporaryShopSlotGrid;
  Stars.Free;
  Stars := nil;
  Holes.Free;
  Holes := nil;
  StoredItems.Free;
  StoredItems := nil;
  Planets.Clear;
  Planets.Free;
  Planets := nil;
  Rangers.Clear;
  Rangers.Free;
  Rangers := nil;
  ShipsInTransit.Clear;
  ShipsInTransit.Free;
  ShipsInTransit := nil;
  Constellations.Free;
  Constellations := nil;
  for I := PlanetNews.Count - 1 downto 0 do
  begin
    News := PlanetNews[I];
    PlanetNews.Delete(I);
    Dispose(News);
  end;
  PlanetNews.Clear;
  PlanetNews.Free;
  PlanetNews := nil;
  ClearJumpGates;
  JumpGates.Free;
  JumpGates := nil;
  SetPlayer(nil, Self);
  PlayerStar := nil;
  if DominatorSpawnPlanet <> nil then
  begin
    DominatorSpawnPlanet.Free;
    DominatorSpawnPlanet := nil;
  end;
  ClearPersistentPlayerMessages;
  if PrimaryFilm <> nil then
    PrimaryFilm.Clear;
  if SecondaryFilm <> nil then
    SecondaryFilm.Clear;
  SpaceBackgroundEntries := nil;
  GalaxyEvents.Free;
  GalaxyEvents := nil;
  InterfaceStateOverrides.Free;
  InterfaceStateOverrides := nil;
  InterfaceTextOverrides.Free;
  InterfaceTextOverrides := nil;
  InterfaceImageOverrides.Free;
  InterfaceImageOverrides := nil;
  InterfacePositionOverrides.Free;
  InterfacePositionOverrides := nil;
  InterfaceSizeOverrides.Free;
  InterfaceSizeOverrides := nil;
  LoadedShips.Free;
  LoadedShips := nil;
  Destroying := False;
  ClearPendingScriptRequests;
  if CustomWeaponTypes <> nil then
  begin
    for I := 0 to CustomWeaponTypes.Count - 1 do
    begin
      WeaponInfo := CustomWeaponTypes[I];
      Dispose(WeaponInfo);
    end;
    CustomWeaponTypes.Clear;
    CustomWeaponTypes.Free;
    CustomWeaponTypes := nil;
  end;
  inherited Destroy;
end;
procedure TGalaxy.InitializeCampaignState;
var
  I: Byte;
begin
  CurrentTurn := 0;
  PirateCount := 0;
  TransportCount := 0;
  StarMapWeaponPanelOpen := True;
  for I := 0 to 2 do
  begin
    DominatorResearch[I].Progress := 0;
    case DifficultyLevels[2] of
      0: DominatorResearch[I].Material := 200;
      1: DominatorResearch[I].Material := 100;
      2: DominatorResearch[I].Material := 70;
      3: DominatorResearch[I].Material := 30;
    else
      DominatorResearch[I].Material := 0;
    end;
  end;
  WarDeltaWin[1] := 0;
  WarDeltaWin[2] := 0;
  WarDeltaWin[0] := 0;
  RangerSpawnQuotas[0] := 0;
  RangerSpawnQuotas[1] := 0;
  RangerSpawnQuotas[2] := 0;
  RangerSpawnQuotas[3] := 0;
  RangerSpawnQuotas[4] := 0;
  ComputeGlobalGoodsPriceBands;
  CampaignFlag183 := 0;
  EditableStateApplied := False;
  FinalizationName := '';
  SpecialSimulationMode := 0;
end;
procedure TGalaxy.SaveToBuffer(Buffer: TBufEC);
var
  I, J, Count: Integer;
  Star: TStar;
  Planet: TPlanet;
  Ranger: TRanger;
  OldQuest: PPlayerOldQuest;
  Gate: PJumpGateEntry;
  Constellation: TConstellation;
  Template: TScriptTemplUnit;
  Script: TScript;
  Group: TGroup;
  ShopSlot: TShopSlot;
  Hole: THole;
  Career: Byte;
  News: PPlanetNewsEntry;
  Series, Difficulty: Byte;
  Stored: TStoredItem;
  WeaponInfo: PWeaponInfo;
  Race: Byte;
begin
  if (TemporaryShopSlots <> nil)
      and (GetPlayer.CurrentPlanet <> TemporaryShopPlanet)
      and (GetPlayer.DockedTo <> TemporaryShopStation) then
    RestoreTemporaryShopStock;
  RunConfigOnSaveHandlers;
  Buffer.AddWideStringZ(SelectedMods);
  Buffer.AddIntegerValue(GenerationSeed);
  Buffer.AddDWord(RandomState);
  Buffer.AddIntegerValue(AverageRangerCapital);
  Buffer.AddIntegerValue(MaxRangerWealth);
  Buffer.AddSingle(AverageRangerStrength);
  Buffer.AddSingle(BestRangerStrength);
  // CHANGE: CLEANUP - Preserve legacy save slots without retaining tamper state.
  Buffer.AddBoolean(False);
  Buffer.AddBoolean(False);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(GetCheatPoints);
  Inc(SaveCount);
  Buffer.AddIntegerValue(SaveCount);
  Buffer.AddIntegerValue(LoadCount);
  Count := CustomWeaponTypes.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    WeaponInfo := CustomWeaponTypes[I];
    Buffer.AddWideStringZ(WeaponInfo.ConfigName);
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.TechLevel));
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.InventionIndex));
    Buffer.AddSingle(WeaponInfo.CostFactor);
    Buffer.AddIntegerValue(WeaponInfo.MinDamage);
    Buffer.AddIntegerValue(WeaponInfo.MaxDamage);
    Buffer.AddIntegerValue(WeaponInfo.AverageSize);
    Buffer.AddIntegerValue(WeaponInfo.AverageRange);
    Buffer.AddIntegerValue(WeaponInfo.ShotSpeedPercent);
    Buffer.AddIntegerValue(WeaponInfo.MissileRange);
    Buffer.AddIntegerValue(WeaponInfo.MissileMaxSpeed);
    Buffer.AddIntegerValue(WeaponInfo.MissileMinSpeed);
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.MissileChanceToBeHit));
    Buffer.AddDWord(WeaponInfo.DamageFlags);
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.ShotType));
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.ShotCount));
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.AttackCount));
    Buffer.AddSingle(WeaponInfo.SecondaryDamageRadius);
    Buffer.AddSingle(WeaponInfo.MiningFactor);
    for J := 1 to 8 do
      Buffer.AddSingle(WeaponInfo.DamageScaleByLevel[J]);
    if WeaponInfo.PrimarySE = '' then
      Buffer.AddBoolean(False)
    else
    begin
      Buffer.AddBoolean(True);
      Buffer.AddWideStringZ(WeaponInfo.PrimarySE);
    end;
    if WeaponInfo.SecondarySE = '' then
      Buffer.AddBoolean(False)
    else
    begin
      Buffer.AddBoolean(True);
      Buffer.AddWideStringZ(WeaponInfo.SecondarySE);
    end;
    if WeaponInfo.AreaSE = '' then
      Buffer.AddBoolean(False)
    else
    begin
      Buffer.AddBoolean(True);
      Buffer.AddWideStringZ(WeaponInfo.AreaSE);
    end;
    Buffer.AddIntegerValue(WeaponInfo.DefaultPalette);
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.Availability));
    Buffer.AddAnsiChar(AnsiChar(WeaponInfo.ArcadeWeaponType));
  end;
  Count := Constellations.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.SaveToBuffer(Buffer);
  end;
  Count := Stars.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Star := TStar(Stars[I]);
    Star.SaveToBuffer(Buffer);
  end;
  Count := Holes.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Hole := THole(Holes[I]);
    Hole.SaveToBuffer(Buffer);
  end;
  Count := StoredItems.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Stored := TStoredItem(StoredItems[I]);
    Stored.SaveToBuffer(Buffer);
  end;
  Count := JumpGates.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Gate := JumpGates[I];
    Buffer.AddSingle(Gate.Gate.Position.X);
    Buffer.AddSingle(Gate.Gate.Position.Y);
    Buffer.AddAnsiChar(AnsiChar(Gate.Gate.GetAngle));
    Buffer.AddWideChar(WideChar(Gate.Gate.Size.X));
    Buffer.AddWideStringZ(Gate.Gate.GetText);
  end;
  Count := Planets.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Planet := Planets[I];
    Buffer.AddDWord(Planet.Id);
  end;
  Count := Rangers.Count;
  Buffer.AddWord(Word(Count));
  for I := 0 to Count - 1 do
  begin
    Ranger := Rangers[I];
    Buffer.AddDWord(Ranger.Id);
  end;
  for Race := 0 to 4 do
    Buffer.AddIntegerValue(RangerSpawnQuotas[Race]);
  if KellerTargetStar = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(KellerTargetStar.Id);
  Buffer.AddIntegerValue(KellerMissionState);
  Count := 0;
  if TemporaryShopSlots <> nil then
    Count := TemporaryShopSlots.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    ShopSlot := TemporaryShopSlots[I];
    ShopSlot.SaveToBuffer(Buffer);
  end;
  SharedScriptVariables.SaveToBuffer(Buffer);
  Count := ScriptTemplates.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Template := ScriptTemplates[I];
    Buffer.AddWideStringZ(Template.Name);
    Buffer.AddWideChar(WideChar(Template.UseCount));
    Buffer.AddIntegerValue(Template.LastTurn);
    Buffer.AddIntegerValue(Template.ActiveScriptIndex);
  end;
  Count := Scripts.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Script := Scripts[I];
    Script.SaveState(Buffer);
  end;
  Count := LiberationGroups.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Group := LiberationGroups[I];
    Group.Save(Buffer);
  end;
  Buffer.AddAnsiChar(#0);
  Buffer.AddIntegerValue(0);
  Buffer.AddWideChar(WideChar(PirateCount));
  Buffer.AddWideChar(WideChar(PirateClanCount));
  Buffer.AddWideChar(WideChar(TransportCount));
  Buffer.AddDWord(CurrentTurn);
  for Difficulty := 0 to 7 do
    Buffer.AddAnsiChar(AnsiChar(DifficultyLevels[Difficulty]));
  Buffer.AddDWord(GetPlayer.Id);
  if PendingPlayerFollowTarget = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(PendingPlayerFollowTarget.Id);
  if BlazerShip = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(BlazerShip.Id);
  if KellerShip = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(KellerShip.Id);
  if TerronShip = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(TerronShip.Id);
  Buffer.AddDWord(PlayerStar.Id);
  Buffer.AddDWord(PieceCreatorTargetStarId);
  for Career := 0 to 2 do
  begin
    if EminentCareerShips[Career] = nil then
      Buffer.AddDWord(0)
    else
      Buffer.AddDWord((EminentCareerShips[Career] as TShip).Id);
  end;
  Count := PlayerOldQuests.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    OldQuest := PlayerOldQuests[I];
    if OldQuest.Planet = nil then
      Buffer.AddDWord(0)
    else
      Buffer.AddDWord(OldQuest.Planet.Id);
    Buffer.AddAnsiChar(AnsiChar(OldQuest.QuestType));
    Buffer.AddWideChar(WideChar(OldQuest.QuestNumber));
    Buffer.AddWideStringZ(OldQuest.Description);
    Buffer.AddBoolean(OldQuest.Successful);
    Buffer.AddBoolean(OldQuest.Declined);
  end;
  Count := PlanetNews.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    News := PlanetNews[I];
    Buffer.AddDWord(News.Id);
    Buffer.AddDWord(News.Turn);
    Buffer.AddAnsiChar(AnsiChar(News.NewsType));
    Buffer.AddWideStringZ(News.Text);
  end;
  Buffer.AddDWord(ReservedMessageCounter);
  Buffer.AddDWord(TurnsSinceLastShipMessage);
  Buffer.AddSingle(0);
  for Series := 0 to 2 do
  begin
    Buffer.AddSingle(DominatorResearch[Series].Progress);
    Buffer.AddDWord(DominatorResearch[Series].Material);
  end;
  Buffer.AddSingle(0);
  Buffer.AddIntegerValue(WarDeltaWin[1]);
  Buffer.AddIntegerValue(WarDeltaWin[2]);
  Buffer.AddIntegerValue(WarDeltaWin[0]);
  Buffer.AddIntegerValue(0); // Empty legacy integrity-snapshot buffer.
  Buffer.AddIntegerValue(High(SpaceBackgroundEntries) + 1);
  for I := 0 to High(SpaceBackgroundEntries) do
  begin
    Buffer.AddIntegerValue(SpaceBackgroundEntries[I].ImageIndex);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitStepDegrees);
    Buffer.AddIntegerValue(SpaceBackgroundEntries[I].FrameIndex);
  end;
  for I := 0 to 8 do
    Buffer.AddDWord(HangarScreen.ShipSlots[I].ShipId);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.AddWideChar(WideChar(ShipsInTransit.Count));
  for I := 0 to ShipsInTransit.Count - 1 do
    Buffer.AddDWord(TShip(ShipsInTransit[I]).Id);
  Buffer.AddIntegerValue(TerronWeaponLockTurn);
  Buffer.AddIntegerValue(TerronGrowLockTurn);
  Buffer.AddIntegerValue(TerronLandingLockTurn);
  Buffer.AddIntegerValue(TerronToStarTurn);
  Buffer.AddIntegerValue(KellerLeaveTurn);
  Buffer.AddDWord(KellerResearchTargetStarId);
  Buffer.AddDWord(BlazerLandingPlanetId);
  Buffer.AddIntegerValue(BlazerSelfDestructTurn);
  Buffer.AddIntegerValue(TerronSeriesResolvedTurn);
  Buffer.AddIntegerValue(KellerSeriesResolvedTurn);
  Buffer.AddIntegerValue(BlazerSeriesResolvedTurn);
  Buffer.AddIntegerValue(PirateWinTurn);
  Buffer.AddIntegerValue(PirateWinType);
  Buffer.AddIntegerValue(CoalitionDefeatedTurn);
  Buffer.AddBoolean(GraphDominatorSurfacesEnabled);
  Buffer.AddAnsiChar(AnsiChar(SpaceEffectKind));
  Buffer.AddBoolean(IronWill);
  Buffer.AddAnsiChar(AnsiChar(DominatorModLevel));
  Buffer.AddAnsiChar(AnsiChar(TechnicModEnabled));
  Buffer.AddAnsiChar(AnsiChar(AmmoModEnabled));
  Buffer.AddAnsiChar(AnsiChar(GodModEnabled));
  Buffer.AddAnsiChar(AnsiChar(UltraScanModEnabled));
  Buffer.AddAnsiChar(AnsiChar(StasisModEnabled));
  Buffer.AddDWord(NextPlanetNewsId);
  Buffer.AddIntegerValue(NextSpecialStationServiceTurn);
  Count := GalaxyEvents.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TGalaxyEvent(GalaxyEvents[I]).SaveToBuffer(Buffer);
  Count := InterfaceStateOverrides.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TInterfaceStateOverride(InterfaceStateOverrides[I]).SaveToBuffer(Buffer);
  Count := InterfaceTextOverrides.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TInterfaceTextOverride(InterfaceTextOverrides[I]).SaveToBuffer(Buffer);
  Count := InterfaceImageOverrides.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TInterfaceImageOverride(InterfaceImageOverrides[I]).SaveToBuffer(Buffer);
  Count := InterfacePositionOverrides.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TInterfacePosOverride(InterfacePositionOverrides[I]).SaveToBuffer(Buffer);
  Count := InterfaceSizeOverrides.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    TInterfaceSizeOverride(InterfaceSizeOverrides[I]).SaveToBuffer(Buffer);
  Buffer.AddDWord(NextShipId);
  Buffer.AddDWord(NextItemId);
  Buffer.AddDWord(0); // Legacy machine-fingerprint slot.
  Buffer.AddBoolean(EditableStateApplied);
  Buffer.AddWideStringZ(EncodeLegacySaveLabel(FinalizationName));
  Buffer.AddBoolean(CustomRules.Enabled);
  Buffer.AddAnsiChar(AnsiChar(CustomRules.DominatorStrength));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.DominatorAggression));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.DominatorSpawn));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.PirateAggression));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.CoalitionAggression));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.AsteroidModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.SunDamageModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.ExtraInventions));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.AcrynModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.NodeDropModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.ArcadeDropValueModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.DropValueModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.AgriculturalPlanetWeight));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.MixedPlanetWeight));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.IndustrialPlanetWeight));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.ExtraRangers));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.ArcadeHitpointsModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.ArcadeDamageModifier));
  Buffer.AddAnsiChar(AnsiChar(CustomRules.AIJunkTolerance));
  Buffer.AddBoolean(CustomRules.ChaoticRandom);
  Buffer.AddBoolean(CustomRules.UnrestrictedEquipmentKnowledge);
  Buffer.AddBoolean(CustomRules.StationsNearStars);
  Buffer.AddBoolean(CustomRules.FullStationTargeting);
  Buffer.AddBoolean(CustomRules.SpecialShips);
  Buffer.AddBoolean(CustomRules.ZeroStartingExperience);
  Buffer.AddBoolean(CustomRules.ArcadeBattleRoyale);
  Buffer.AddBoolean(CustomRules.DominatorRacialWeapons);
  Buffer.AddBoolean(CustomRules.StartInCenter);
  Buffer.AddBoolean(CustomRules.MaxRangeMissiles);
  Buffer.AddBoolean(CustomRules.OldHyperspace);
  Buffer.AddBoolean(CustomRules.PirateNodes);
  Buffer.AddBoolean(CustomRules.AIUseShops);
  Buffer.AddBoolean(CustomRules.StationsUseShop);
  Buffer.AddBoolean(CustomRules.DuplicateArtefacts);
  Buffer.AddAnsiChar(AnsiChar(CustomRules.HullGrowth));
  Buffer.AddBoolean(CustomRules.ArcadeEquipmentChange);
  Buffer.AddBoolean(CustomRules.OldSpeedCalculation);
  Buffer.AddBoolean(CustomRules.OldMissileBonuses);
  Buffer.AddBoolean(False);
  Buffer.AddBoolean(False);
  Buffer.AddBoolean(False);
  Buffer.AddBoolean(False);
  Buffer.AddBoolean(False);
  if CampaignFlag183 <> 0 then
    SaveEditableState;
end;
procedure TGalaxy.LoadFromBuffer(Buffer: TBufEC);
var
  I, J, K, Count, TemplateIndex, ShipCount: Integer;
  X, Y: Single;
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
  OldQuest: PPlayerOldQuest;
  Gate: PJumpGateEntry;
  Constellation: TConstellation;
  Template: TScriptTemplUnit;
  Script: TScript;
  Group: TGroup;
  ShopSlot: TShopSlot;
  Hole: THole;
  Career: Byte;
  News: PPlanetNewsEntry;
  Variables: TVarArrayEC;
  Variable, Existing: TVarEC;
  Series, Difficulty: Byte;
  LoadedPlanet: TPlanet;
  SavedRandomState: Cardinal;
  Event: TGalaxyEvent;
  StateOverride: TInterfaceStateOverride;
  TextOverride: TInterfaceTextOverride;
  ImageOverride: TInterfaceImageOverride;
  PositionOverride: TInterfacePosOverride;
  SizeOverride: TInterfaceSizeOverride;
  Stage: Integer;
  TemplateName, SavedMods: WideString;
  Stored: TStoredItem;
  WeaponInfo: PWeaponInfo;
  Crc: Cardinal;
  Race: Byte;
begin
  Stage := 0;
  try
    if LoadedSaveVersion >= 101 then
    begin
      SavedMods := Buffer.ReadWideString;
      if SavedMods <> SelectedMods then
      begin
        LoadedSaveModSet := SavedMods;
        AppendLogLineThreadSafe('Warning! Mod sets mismatch:');
        if SavedMods <> '' then
          AppendLogLineThreadSafe(
              AnsiString(' - when this save was made you were using: ' + SavedMods)
          )
        else
          AppendLogLineThreadSafe(' - when this save was made you were not using mods');
        if SelectedMods <> '' then
          AppendLogLineThreadSafe(AnsiString(' - and now you are using: ' + SelectedMods))
        else
          AppendLogLineThreadSafe(' - and now you are not using any mods');
      end;
    end;
    GenerationSeed := Buffer.GetInt32;
    RandomState := Buffer.GetUInt32;
    SavedRandomState := RandomState;
    AverageRangerCapital := Buffer.GetInt32;
    MaxRangerWealth := Buffer.GetInt32;
    AverageRangerStrength := Buffer.GetSingle;
    BestRangerStrength := Buffer.GetSingle;
    // CHANGE: CLEANUP - Consume the legacy protection flags for save compatibility.
    Buffer.GetBoolean;
    Buffer.GetBoolean;
    Buffer.GetInt32;
    SetCheatPoints(Buffer.GetInt32);
    SaveCount := Buffer.GetInt32;
    LoadCount := Buffer.GetInt32 + 1;
    if LoadedSaveVersion >= 127 then
      Count := Buffer.GetWord
    else
      Count := 0;
    for I := 0 to Count - 1 do
    begin
      New(WeaponInfo);
      CustomWeaponTypes.Add(WeaponInfo);
      WeaponInfo.ItemType := t_CustomWeapon;
      WeaponInfo.ConfigName := Buffer.ReadWideString;
      Crc := InitCrc32;
      Crc := UpdateCrc32(Crc, PWideChar(WeaponInfo.ConfigName), Length(WeaponInfo.ConfigName) * 2);
      WeaponInfo.TypeHash := FinishCrc32(Crc);
      WeaponInfo.TechLevel := Buffer.GetByte;
      WeaponInfo.InventionIndex := Buffer.GetByte;
      WeaponInfo.CostFactor := Buffer.GetSingle;
      WeaponInfo.MinDamage := Buffer.GetInt32;
      WeaponInfo.MaxDamage := Buffer.GetInt32;
      WeaponInfo.AverageSize := Buffer.GetInt32;
      WeaponInfo.AverageRange := Buffer.GetInt32;
      WeaponInfo.ShotSpeedPercent := Buffer.GetInt32;
      WeaponInfo.MissileRange := Buffer.GetInt32;
      WeaponInfo.MissileMaxSpeed := Buffer.GetInt32;
      WeaponInfo.MissileMinSpeed := Buffer.GetInt32;
      WeaponInfo.MissileChanceToBeHit := Buffer.GetByte;
      WeaponInfo.DamageFlags := Buffer.GetUInt32;
      WeaponInfo.ShotType := TWeaponShotType(Buffer.GetByte);
      WeaponInfo.ShotCount := Buffer.GetByte;
      if LoadedSaveVersion >= 132 then
        WeaponInfo.AttackCount := Buffer.GetByte
      else
        WeaponInfo.AttackCount := 1;
      WeaponInfo.SecondaryDamageRadius := Buffer.GetSingle;
      WeaponInfo.MiningFactor := Buffer.GetSingle;
      for J := 1 to 8 do
        WeaponInfo.DamageScaleByLevel[J] := Buffer.GetSingle;
      if Buffer.GetBoolean then
        WeaponInfo.PrimarySE := Buffer.ReadWideString
      else
        WeaponInfo.PrimarySE := '';
      if Buffer.GetBoolean then
        WeaponInfo.SecondarySE := Buffer.ReadWideString
      else
        WeaponInfo.SecondarySE := '';
      if Buffer.GetBoolean then
        WeaponInfo.AreaSE := Buffer.ReadWideString
      else
        WeaponInfo.AreaSE := '';
      WeaponInfo.DefaultPalette := Buffer.GetInt32;
      WeaponInfo.Availability := TWeaponAvailability(Buffer.GetByte);
      WeaponInfo.ArcadeWeaponType := Byte(MigrateSavedItemType(Buffer.GetByte));
    end;
    Stage := 1;
    Count := Buffer.GetWord;
    if (Count < 1) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      Constellation := TConstellation.Create;
      Constellations.Add(Constellation);
      Constellation.LoadFromBuffer(Buffer, Self);
    end;
    CanRecordAchievements;
    MainPiratePlanet := nil;
    Stage := 2;
    Count := Buffer.GetWord;
    if (Count < 1) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      Star := TStar.Create;
      Stars.Add(Star);
      Star.LoadFromBuffer(Buffer, Self);
    end;
    Stage := 3;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      Hole := THole.Create;
      Holes.Add(Hole);
      Hole.LoadFromBuffer(Buffer, Self);
    end;
    if LoadedSaveVersion >= 122 then
    begin
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        Stored := TStoredItem.CreateEmpty;
        StoredItems.Add(Stored);
        Stored.LoadFromBuffer(Buffer, Self);
      end;
    end;
    Stage := 4;
    ClearJumpGates;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      Gate := CreateJumpGate(False);
      X := Buffer.GetSingle;
      Y := Buffer.GetSingle;
      Gate.Gate.SetPosition(MakePointF(X, Y));
      Gate.Gate.SetAngle(Buffer.GetByte);
      TemplateIndex := Buffer.GetWord;
      Gate.Gate.SetSize(Classes.Point(TemplateIndex, TemplateIndex));
      Gate.Gate.SetText(Buffer.ReadWideString);
    end;
    Stage := 5;
    Count := Buffer.GetWord;
    if (Count < 1) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
      Planets.Add(Pointer(Buffer.GetUInt32));
    for I := 0 to Stars.Count - 1 do
    begin
      Star := TStar(Stars[I]);
      for J := 0 to Star.Planets.Count - 1 do
      begin
        LoadedPlanet := TPlanet(Star.Planets[J]);
        if (LoadedPlanet.Id <= Cardinal(Count))
            and (Cardinal(Planets[LoadedPlanet.Id - 1]) = LoadedPlanet.Id) then
          Planets[LoadedPlanet.Id - 1] := LoadedPlanet
        else
          for K := 0 to Planets.Count - 1 do
            if Cardinal(Planets[K]) = LoadedPlanet.Id then
            begin
              Planets[K] := LoadedPlanet;
              Break;
            end;
      end;
    end;
    Stage := 6;
    Count := Buffer.GetWord;
    if (Count < 1) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
      Rangers.Add(Pointer(Buffer.GetUInt32));
    if LoadedSaveVersion >= 133 then
      for Race := 0 to 4 do
        RangerSpawnQuotas[Race] := Buffer.GetInt32;
    if LoadedSaveVersion < 102 then
    begin
      Stage := 7;
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
        Buffer.GetUInt32;
    end;
    KellerTargetStar := TStar(Buffer.GetUInt32);
    KellerMissionState := Buffer.GetInt32;
    Stage := 8;
    ClearTemporaryShopSlotGrid;
    Count := Buffer.GetWord;
    if Count > 0 then
    begin
      TemporaryShopSlots := TList.Create;
      for I := 0 to Count - 1 do
      begin
        ShopSlot := TShopSlot.Create;
        TemporaryShopSlots.Add(ShopSlot);
        ShopSlot.LoadFromBuffer(Buffer, Self);
      end;
    end;
    Stage := 9;
    Variables := TVarArrayEC.Create;
    Variables.LoadFromBuffer(Buffer);
    for I := 0 to Variables.Count - 1 do
    begin
      Variable := Variables.GetItem(I);
      Existing := SharedScriptVariables.GetVarNE(Variable.Name);
      if Existing <> nil then
        Existing.AssignFrom(Variable, True);
    end;
    Variables.Free;
    Stage := 10;
    Count := ScriptTemplates.Count;
    for I := 0 to Count - 1 do
    begin
      Template := ScriptTemplates[I];
      Template.UseCount := 0;
      Template.LastTurn := 0;
    end;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
    begin
      TemplateName := Buffer.ReadWideString;
      TemplateIndex := FindScriptTemplateIndex(TemplateName);
      if TemplateIndex < 0 then
      begin
        AppendLogLineThreadSafe(AnsiString('Warning: Script not found - ' + TemplateName));
        Buffer.GetWord;
        Buffer.GetInt32;
        Buffer.GetInt32;
      end
      else
      begin
        Template := ScriptTemplates[TemplateIndex];
        Template.UseCount := Buffer.GetWord;
        Template.LastTurn := Buffer.GetInt32;
        Template.ActiveScriptIndex := Buffer.GetInt32;
      end;
    end;
    Stage := 11;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
    begin
      Script := TScript.Create;
      Scripts.Add(Script);
      Script.LoadState(Buffer, Self);
      if (LoadedSaveVersion = 146) and (Script.ScriptFileName = 'Script.PC_part7') then
        if Script.InitCode.LocalVar.GetVar('player_traitor').GetInt = 1 then
          Script.InitCode.LocalVar.GetVar('pirates_killed_init').SetInt(1);
    end;
    Stage := 12;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
    begin
      Group := TGroup.Create;
      LiberationGroups.Add(Group);
      Group.Load(Buffer, Self);
    end;
    Stage := 13;
    Buffer.GetByte;
    Buffer.GetInt32;
    PirateCount := Buffer.GetWord;
    PirateClanCount := Buffer.GetWord;
    TransportCount := Buffer.GetWord;
    CurrentTurn := Buffer.GetUInt32;
    for Difficulty := 0 to 7 do
      DifficultyLevels[Difficulty] := Buffer.GetByte;
    PlayerRangerIndex := Buffer.GetUInt32;
    PendingPlayerFollowTarget := TShip(Buffer.GetUInt32);
    BlazerShip := TKling(Buffer.GetUInt32);
    KellerShip := TKling(Buffer.GetUInt32);
    TerronShip := TKling(Buffer.GetUInt32);
    PlayerStar := TStar(Buffer.GetUInt32);
    PieceCreatorTargetStarId := Buffer.GetUInt32;
    Stage := 14;
    for Career := 0 to 2 do
      EminentCareerShips[Career] := TObject(Buffer.GetUInt32);
    Stage := 15;
    Count := Rangers.Count;
    for I := 0 to Count - 1 do
      Rangers[I] := TObject(IdToShip(Cardinal(Rangers[I]), True)) as TShip;
    Stage := 16;
    SetPlayer(TObject(IdToShip(PlayerRangerIndex, True)) as TPlayer, Self);
    Stage := 17;
    Count := Constellations.Count;
    for I := 0 to Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.ResolveLoadedReferences(Self);
    end;
    Stage := 18;
    J := 4;
    Count := Stars.Count;
    for I := 0 to Count - 1 do
    begin
      Star := TStar(Stars[I]);
      Star.ResolveLoadedReferences(Self);
    end;
    if TemporaryShopSlots <> nil then
    begin
      if GetPlayer.CurrentPlanet <> nil then
        TemporaryShopPlanet := GetPlayer.CurrentPlanet
      else if (GetPlayer.DockedTo <> nil) and (GetPlayer.DockedTo is TRuins) then
        TemporaryShopStation := TRuins(GetPlayer.DockedTo)
      else
        ClearTemporaryShopSlotGrid;
    end;
    Count := StoredItems.Count;
    for I := 0 to Count - 1 do
    begin
      Stored := TStoredItem(StoredItems[I]);
      TItem(Stored.Item).ResolveLoadedReferences(Self);
    end;
    Stage := 19;
    Count := Holes.Count;
    for I := 0 to Count - 1 do
    begin
      Hole := THole(Holes[I]);
      Hole.ResolveLoadedReferences(Self);
    end;
    Stage := 22;
    if KellerTargetStar <> nil then
      KellerTargetStar := TObject(IdToStar(Cardinal(KellerTargetStar))) as TStar;
    Stage := 23;
    PendingPlayerFollowTarget :=
        TObject(IdToShip(Cardinal(PendingPlayerFollowTarget), True)) as TShip;
    BlazerShip := TObject(IdToShip(Cardinal(BlazerShip), True)) as TKling;
    KellerShip := TObject(IdToShip(Cardinal(KellerShip), True)) as TKling;
    TerronShip := TObject(IdToShip(Cardinal(TerronShip), True)) as TKling;
    PlayerStar := TObject(IdToStar(Cardinal(PlayerStar))) as TStar;
    Stage := 24;
    for Career := 0 to 2 do
      EminentCareerShips[Career] :=
          TObject(IdToShip(Cardinal(EminentCareerShips[Career]), True)) as TRanger;
    Stage := 25;
    if PlayerOldQuests <> nil then
    begin
      PlayerOldQuests.Free;
      PlayerOldQuests := nil;
    end;
    PlayerOldQuests := TList.Create;
    Count := Buffer.GetWord;
    Stage := 26;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err in PlayerQuests load');
    for I := 0 to Count - 1 do
    begin
      New(OldQuest);
      PlayerOldQuests.Add(OldQuest);
      OldQuest.Planet := TPlanet(Buffer.GetUInt32);
      OldQuest.Planet := TObject(IdToPlanet(Cardinal(OldQuest.Planet))) as TPlanet;
      OldQuest.QuestType := TQuestType(Buffer.GetByte);
      OldQuest.QuestNumber := Buffer.GetWord;
      OldQuest.Description := Buffer.ReadWideString;
      OldQuest.Successful := Buffer.GetBoolean;
      OldQuest.Declined := Buffer.GetBoolean;
    end;
    Stage := 27;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      New(News);
      PlanetNews.Add(News);
      News.Id := Buffer.GetUInt32;
      News.Turn := Buffer.GetUInt32;
      News.NewsType := Buffer.GetByte;
      News.Text := Buffer.ReadWideString;
    end;
    Stage := 28;
    ReservedMessageCounter := Buffer.GetUInt32;
    TurnsSinceLastShipMessage := Buffer.GetUInt32;
    Buffer.GetSingle;
    for Series := 0 to 2 do
    begin
      DominatorResearch[Series].Progress := Buffer.GetSingle;
      DominatorResearch[Series].Material := Buffer.GetUInt32;
    end;
    Buffer.GetSingle;
    Stage := 29;
    if LoadedSaveVersion >= 62 then
    begin
      WarDeltaWin[1] := Buffer.GetInt32;
      WarDeltaWin[2] := Buffer.GetInt32;
      WarDeltaWin[0] := Buffer.GetInt32;
    end
    else
    begin
      WarDeltaWin[1] := Buffer.GetInt32 * -1;
      WarDeltaWin[2] := 0;
      WarDeltaWin[0] := 0;
    end;
    Stage := 30;
    Count := Buffer.GetInt32;
    if (Count < 0) or (Count > Buffer.DataSize - Buffer.Position) then
      raise EAbort.Create('Invalid legacy snapshot length');
    Buffer.SetPosition(Buffer.Position + Count);
    Stage := 31;
    Count := Buffer.GetInt32;
    if (Count < 0) or (Count > 1000000) then
      raise EAbort.Create('Err');
    SetLength(SpaceBackgroundEntries, Count);
    for I := 0 to High(SpaceBackgroundEntries) do
    begin
      SpaceBackgroundEntries[I].ImageIndex := Buffer.GetInt32;
      SpaceBackgroundEntries[I].OrbitCenter.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitCenter.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitCenter.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitStepDegrees := Buffer.GetSingle;
      SpaceBackgroundEntries[I].FrameIndex := Buffer.GetInt32;
    end;
    Stage := 32;
    for I := 0 to 8 do
      HangarScreen.ShipSlots[I].ShipId := Buffer.GetUInt32;
    Stage := 33;
    Buffer.GetInt32;
    Buffer.GetInt32;
    Buffer.GetInt32;
    Buffer.GetInt32;
    Stage := 34;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
      ShipsInTransit.Add(IdToShip(Buffer.GetUInt32, True));
    Stage := 35;
    TerronWeaponLockTurn := Buffer.GetInt32;
    TerronGrowLockTurn := Buffer.GetInt32;
    TerronLandingLockTurn := Buffer.GetInt32;
    TerronToStarTurn := Buffer.GetInt32;
    KellerLeaveTurn := Buffer.GetInt32;
    if LoadedSaveVersion >= 47 then
      KellerResearchTargetStarId := Buffer.GetUInt32;
    BlazerLandingPlanetId := Buffer.GetUInt32;
    BlazerSelfDestructTurn := Buffer.GetInt32;
    TerronSeriesResolvedTurn := Buffer.GetInt32;
    KellerSeriesResolvedTurn := Buffer.GetInt32;
    BlazerSeriesResolvedTurn := Buffer.GetInt32;
    PirateWinTurn := Buffer.GetInt32;
    PirateWinType := Buffer.GetInt32;
    if LoadedSaveVersion >= 46 then
      CoalitionDefeatedTurn := Buffer.GetInt32;
    GraphDominatorSurfacesEnabled := Buffer.GetBoolean;
    SpaceEffectKind := Buffer.GetByte;
    IronWill := Buffer.GetBoolean;
    Stage := 36;
    if LoadedSaveVersion >= 71 then
    begin
      DominatorModLevel := Buffer.GetByte;
      TechnicModEnabled := Buffer.GetByte;
      AmmoModEnabled := Buffer.GetByte;
      GodModEnabled := Buffer.GetByte;
      UltraScanModEnabled := Buffer.GetByte;
      StasisModEnabled := Buffer.GetByte;
    end
    else
    begin
      DominatorModLevel := Buffer.GetInt32;
      TechnicModEnabled := Buffer.GetInt32;
      AmmoModEnabled := Buffer.GetInt32;
      GodModEnabled := Buffer.GetInt32;
      if LoadedSaveVersion >= 65 then
        UltraScanModEnabled := Buffer.GetInt32
      else
        UltraScanModEnabled := 0;
      StasisModEnabled := 0;
    end;
    Stage := 37;
    NextPlanetNewsId := Buffer.GetUInt32;
    NextSpecialStationServiceTurn := Buffer.GetInt32;
    Stage := 38;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
    begin
      Event := TGalaxyEvent.Create('');
      GalaxyEvents.Add(Event);
      Event.LoadFromBuffer(Buffer);
    end;
    if LoadedSaveVersion >= 112 then
    begin
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        StateOverride := TInterfaceStateOverride.Create;
        InterfaceStateOverrides.Add(StateOverride);
        StateOverride.LoadFromBuffer(Buffer);
      end;
    end;
    if LoadedSaveVersion >= 117 then
    begin
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        TextOverride := TInterfaceTextOverride.Create;
        InterfaceTextOverrides.Add(TextOverride);
        TextOverride.LoadFromBuffer(Buffer);
      end;
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        ImageOverride := TInterfaceImageOverride.Create;
        InterfaceImageOverrides.Add(ImageOverride);
        ImageOverride.LoadFromBuffer(Buffer);
      end;
    end;
    if LoadedSaveVersion >= 119 then
    begin
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        PositionOverride := TInterfacePosOverride.Create;
        InterfacePositionOverrides.Add(PositionOverride);
        PositionOverride.LoadFromBuffer(Buffer);
      end;
    end;
    if LoadedSaveVersion >= 134 then
    begin
      Count := Buffer.GetWord;
      if (Count < 0) or (Count > 10000) then
        raise EAbort.Create('Err');
      for I := 0 to Count - 1 do
      begin
        SizeOverride := TInterfaceSizeOverride.Create;
        InterfaceSizeOverrides.Add(SizeOverride);
        SizeOverride.LoadFromBuffer(Buffer);
      end;
    end;
    Stage := 39;
    if LoadedSaveVersion >= 70 then
    begin
      NextShipId := Buffer.GetUInt32;
      NextItemId := Buffer.GetUInt32;
    end;
    Stage := 40;
    if LoadedSaveVersion >= 56 then
      Buffer.GetUInt32;
    Stage := 41;
    Count := Scripts.Count;
    for I := 0 to Count - 1 do
    begin
      Script := TScript(Scripts[I]);
      Script.ResolveLoadedReferences(Self);
    end;
    Stage := 42;
    Count := LiberationGroups.Count;
    for I := 0 to Count - 1 do
    begin
      Group := TGroup(LiberationGroups[I]);
      Group.ResolveLoadedReferences(Self);
    end;
    Stage := 43;
    Count := Stars.Count;
    for I := 0 to Count - 1 do
    begin
      Star := TStar(Stars[I]);
      ShipCount := Star.Ships.Count;
      for TemplateIndex := 0 to ShipCount - 1 do
      begin
        Ship := TShip(Star.Ships[TemplateIndex]);
        if (Ship.CurrentPlanet <> nil) and (Ship.CurrentPlanet.CurrentStar <> Star) then
        begin
          AppendLogLineThreadSafe(
              AnsiString(
                  'Warning! '
                      + Ship.GetFullName(' ')
                      + ' is in system '
                      + Star.Name
                      + ' while landed on planet '
                      + Ship.CurrentPlanet.Name
              )
          );
          AppendLogLineThreadSafe('clearing landing state');
          Ship.CurrentPlanet := nil;
        end;
        if Ship.TypeId = stWarrior then
          Ship.HomePlanet.Warriors.Add(Ship);
        if (Ship.TypeId = stRanger) and (Rangers.IndexOf(Ship) < 0) then
          (Ship as TRanger).RegisterInGalaxyRelations;
      end;
    end;
    if (LoadedSaveVersion < 121) and (MainPiratePlanet <> nil) then
      for I := 0 to Stars.Count - 1 do
      begin
        Star := TStar(Stars[I]);
        for J := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(Star.Ships[J]);
          if (Ship is TPirate)
              and (Ship.OwnerId = Byte(oiPirate))
              and ((Ship as TPirate).PirateType <> 0) then
            for K := 0 to Rangers.Count - 1 do
              Ship.RangerRelations[K] := MainPiratePlanet.RangerRelations[K];
        end;
      end;
    Stage := 44;
    ComputeGlobalGoodsPriceBands;
    InitializeConstellationDistanceTiers;
    RebuildStarDistances;
    UpdateConstellationMilitaryStats;
    RefreshRangerWealthStats;
    RefreshRangerRatingPlaces;
    RefreshTechLevel;
    Stage := 45;
    if BlazerShip <> nil then
      CreateDominatorSpawnProxy(BlazerShip.CurrentStar)
    else if TerronShip <> nil then
      CreateDominatorSpawnProxy(TerronShip.CurrentStar)
    else if KellerShip <> nil then
      CreateDominatorSpawnProxy(KellerShip.CurrentStar)
    else
      CreateDominatorSpawnProxy(nil);
    Stage := 46;
    for I := 0 to Stars.Count - 1 do
    begin
      Star := TStar(Stars[I]);
      Star.MapDiameter := Star.ComputeMapDiameter;
    end;
    Stage := 47;
    if (TerronToStarTurn and $40000000 <> 0) and (TerronShip <> nil) then
    begin
      ReleaseSpaceObject(TerronShip.CurrentStar.Graphic);
      RetainSpaceObject(
          TerronShip.CurrentStar.Graphic,
          CreateSpaceObjectByName('Star', 'Star.TerronAfter', Classes.Point(0, 0))
      );
    end;
    Stage := 48;
    GetPlayer.CurrentStar.RefreshMovementStepParameters;
    RandomState := SavedRandomState;
    Stage := 49;
    if LoadedSaveVersion >= 61 then
    begin
      EditableStateApplied := Buffer.GetBoolean;
      FinalizationName := DecodeLegacySaveLabel(Buffer.ReadWideString);
    end
    else
    begin
      EditableStateApplied := False;
      FinalizationName := '';
    end;
    Stage := 50;
    if LoadedSaveVersion >= 63 then
    begin
      CustomRules.Enabled := Buffer.GetBoolean;
      CustomRules.DominatorStrength := Buffer.GetByte;
      CustomRules.DominatorAggression := Buffer.GetByte;
      CustomRules.DominatorSpawn := Buffer.GetByte;
      CustomRules.PirateAggression := Buffer.GetByte;
      CustomRules.CoalitionAggression := Buffer.GetByte;
      CustomRules.AsteroidModifier := Buffer.GetByte;
      CustomRules.SunDamageModifier := Buffer.GetByte;
      if LoadedSaveVersion >= 64 then
      begin
        CustomRules.ExtraInventions := Buffer.GetByte;
      end
      else
      begin
        CustomRules.ExtraInventions := 0;
      end;
      if LoadedSaveVersion >= 64 then
      begin
        CustomRules.AcrynModifier := Buffer.GetByte;
      end
      else
      begin
        CustomRules.AcrynModifier := 16;
      end;
      if LoadedSaveVersion >= 66 then
      begin
        CustomRules.NodeDropModifier := Buffer.GetByte;
        CustomRules.ArcadeDropValueModifier := Buffer.GetByte;
        CustomRules.DropValueModifier := Buffer.GetByte;
        CustomRules.AgriculturalPlanetWeight := Buffer.GetByte;
        CustomRules.MixedPlanetWeight := Buffer.GetByte;
        CustomRules.IndustrialPlanetWeight := Buffer.GetByte;
        CustomRules.ExtraRangers := Buffer.GetByte;
        CustomRules.ArcadeHitpointsModifier := Buffer.GetByte;
        CustomRules.ArcadeDamageModifier := Buffer.GetByte;
        CustomRules.AIJunkTolerance := Buffer.GetByte;
      end
      else
      begin
        CustomRules.NodeDropModifier := 8;
        CustomRules.ArcadeDropValueModifier := 8;
        CustomRules.DropValueModifier := 8;
        CustomRules.AgriculturalPlanetWeight := 1;
        CustomRules.MixedPlanetWeight := 1;
        CustomRules.IndustrialPlanetWeight := 1;
        CustomRules.ExtraRangers := 0;
        CustomRules.ArcadeHitpointsModifier := 8;
        CustomRules.ArcadeDamageModifier := 8;
        CustomRules.AIJunkTolerance := 7;
      end;
      CustomRules.ChaoticRandom := Buffer.GetBoolean;
      CustomRules.UnrestrictedEquipmentKnowledge := Buffer.GetBoolean;
      CustomRules.StationsNearStars := Buffer.GetBoolean;
      CustomRules.FullStationTargeting := Buffer.GetBoolean;
      if LoadedSaveVersion >= 64 then
      begin
        CustomRules.SpecialShips := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.SpecialShips := False;
      end;
      if LoadedSaveVersion >= 66 then
      begin
        CustomRules.ZeroStartingExperience := Buffer.GetBoolean;
        if LoadedSaveVersion < 92 then
          Buffer.GetBoolean;
        CustomRules.ArcadeBattleRoyale := Buffer.GetBoolean;
        CustomRules.DominatorRacialWeapons := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.ZeroStartingExperience := False;
        CustomRules.ArcadeBattleRoyale := False;
        CustomRules.DominatorRacialWeapons := False;
      end;
      if LoadedSaveVersion >= 72 then
      begin
        CustomRules.StartInCenter := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.StartInCenter := False;
      end;
      if LoadedSaveVersion >= 73 then
      begin
        CustomRules.MaxRangeMissiles := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.MaxRangeMissiles := False;
      end;
      if LoadedSaveVersion >= 75 then
      begin
        CustomRules.OldHyperspace := Buffer.GetBoolean;
        CustomRules.PirateNodes := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.OldHyperspace := False;
        CustomRules.PirateNodes := False;
      end;
      if LoadedSaveVersion >= 84 then
      begin
        CustomRules.AIUseShops := Buffer.GetBoolean;
        CustomRules.StationsUseShop := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.AIUseShops := False;
        CustomRules.StationsUseShop := False;
      end;
      if LoadedSaveVersion >= 136 then
      begin
        CustomRules.DuplicateArtefacts := Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.DuplicateArtefacts := False;
      end;
      if LoadedSaveVersion >= 156 then
      begin
        CustomRules.HullGrowth := Buffer.GetByte;
      end
      else
      begin
        CustomRules.HullGrowth := 0;
      end;
      if LoadedSaveVersion >= 166 then
      begin
        CustomRules.ArcadeEquipmentChange := Buffer.GetBoolean;
        CustomRules.OldSpeedCalculation := Buffer.GetBoolean;
        CustomRules.OldMissileBonuses := Buffer.GetBoolean;
        Buffer.GetBoolean;
        Buffer.GetBoolean;
        Buffer.GetBoolean;
        Buffer.GetBoolean;
        Buffer.GetBoolean;
      end
      else
      begin
        CustomRules.ArcadeEquipmentChange := False;
        CustomRules.OldSpeedCalculation := False;
        CustomRules.OldMissileBonuses := False;
      end;
    end
    else
    begin
      CustomRules.Enabled := True;
      case DifficultyLevels[0] of
        0: CustomRules.DominatorStrength := 0;
        1: CustomRules.DominatorStrength := 8;
        2: CustomRules.DominatorStrength := 16;
        3: CustomRules.DominatorStrength := 24;
      end;
      CustomRules.DominatorAggression := CustomRules.DominatorStrength;
      CustomRules.DominatorSpawn := CustomRules.DominatorStrength;
      CustomRules.PirateAggression := CustomRules.DominatorStrength;
      CustomRules.CoalitionAggression := 8;
      CustomRules.AsteroidModifier := 8;
      CustomRules.SunDamageModifier := 8;
      CustomRules.ExtraInventions := 0;
      CustomRules.AcrynModifier := 16;
      CustomRules.NodeDropModifier := 8;
      CustomRules.ArcadeDropValueModifier := 8;
      CustomRules.DropValueModifier := 8;
      CustomRules.AgriculturalPlanetWeight := 1;
      CustomRules.MixedPlanetWeight := 1;
      CustomRules.IndustrialPlanetWeight := 1;
      CustomRules.ExtraRangers := 0;
      CustomRules.ArcadeHitpointsModifier := 8;
      CustomRules.ArcadeDamageModifier := 8;
      CustomRules.AIJunkTolerance := 7;
      CustomRules.ChaoticRandom := False;
      CustomRules.UnrestrictedEquipmentKnowledge := False;
      CustomRules.StationsNearStars := False;
      CustomRules.FullStationTargeting := False;
      CustomRules.SpecialShips := False;
      CustomRules.ZeroStartingExperience := False;
      CustomRules.ArcadeBattleRoyale := False;
      CustomRules.DominatorRacialWeapons := False;
      CustomRules.StartInCenter := False;
      CustomRules.MaxRangeMissiles := False;
      CustomRules.OldHyperspace := False;
      CustomRules.PirateNodes := False;
      CustomRules.AIUseShops := False;
      CustomRules.StationsUseShop := False;
      CustomRules.DuplicateArtefacts := False;
      CustomRules.HullGrowth := 0;
      CustomRules.ArcadeEquipmentChange := False;
      CustomRules.OldSpeedCalculation := False;
      CustomRules.OldMissileBonuses := False;
    end;
    Stage := 51;
    Event := AddGalaxyEvent('SaveLoaded', Self);
    ShipCount := CountDelimitedPartsW(SelectedMods, ',');
    for I := 0 to ShipCount - 1 do
      Event.AddTextData(ExtractDelimitedPartW(SelectedMods, I, ','));
    Event.AddData(Ord(ApplyEditableSaveOnLoad));
    Stage := 52;
    aGalaxy.Galaxy := Self;
    for I := 0 to LoadedShips.Count - 1 do
    begin
      Ship := TShip(LoadedShips[I]);
      Ship.RefreshDerivedStats(False);
      Ship.RefreshGraphicSize;
      Ship.DerivedStateCompatibilityHook;
    end;
    RefreshRangerStrengthStats;
    for I := 0 to LoadedShips.Count - 1 do
    begin
      Ship := TShip(LoadedShips[I]);
      Ship.UpdateBestRangerRelativeRatings;
      Ship.UpdateAverageRangerRelativeStrength;
    end;
    LoadedShips.Clear;
    GetPlayer.RefreshStorageBubbles;
    WaitForTurnCalculationUI;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create(
          AnsiString('Error in procedure TGalaxy.Load, label = ' + IntToStr(Stage)));
    end;
  end;
end;
procedure TGalaxy.SaveEditableState;
var
  i: Integer;
  Name: WideString;
  Star: TStar;
  Hole: THole;
  HoleBlock: TBlockParEC;
begin
  GR_Main.EditableSaveBlock.Clear;
  GR_Main.EditableSaveBlock.AddParam('FinalizationName', Self.FinalizationName);
  GR_Main.EditableSaveBlock.AddParam('IDay', WideString(SysUtils.IntToStr(Self.CurrentTurn)));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifPirate', WideString(SysUtils.IntToStr(Self.DifficultyLevels[0])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifTrade', WideString(SysUtils.IntToStr(Self.DifficultyLevels[1])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifScn', WideString(SysUtils.IntToStr(Self.DifficultyLevels[2])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifRepair', WideString(SysUtils.IntToStr(Self.DifficultyLevels[3])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifTech', WideString(SysUtils.IntToStr(Self.DifficultyLevels[4])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifQuest', WideString(SysUtils.IntToStr(Self.DifficultyLevels[5])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifHole', WideString(SysUtils.IntToStr(Self.DifficultyLevels[6])));
  GR_Main
      .EditableSaveBlock
      .AddParam('DifBalance', WideString(SysUtils.IntToStr(Self.DifficultyLevels[7])));
  GR_Main
      .EditableSaveBlock
      .AddParam('KlingsDeltaWin', WideString(SysUtils.IntToStr(Self.WarDeltaWin[1])));
  GR_Main
      .EditableSaveBlock
      .AddParam('PiratesDeltaWin', WideString(SysUtils.IntToStr(Self.WarDeltaWin[2])));
  GR_Main
      .EditableSaveBlock
      .AddParam('NormalsDeltaWin', WideString(SysUtils.IntToStr(Self.WarDeltaWin[0])));
  GR_Main
      .EditableSaveBlock
      .AddParam('RejectPB', BoolToWideString(GetPlayer.DeclinePlanetBattleOffers));
  GetPlayer.SaveToBlock(GR_Main.EditableSaveBlock.AddBlockByPath('Player'));
  HoleBlock := GR_Main.EditableSaveBlock.AddBlockByPath('HoleList');
  for i := 0 to Self.Holes.Count - 1 do
  begin
    Hole := THole(Self.Holes[i]);
    Name := 'HoleId' + WideString(SysUtils.IntToStr(Int64(Hole.Id)));
    Hole.SaveToBlock(HoleBlock.AddBlockByPath(Name));
  end;
  HoleBlock.AddParam('CreateNewHoles', WideString(SysUtils.IntToStr(0)));
  with GR_Main.EditableSaveBlock.AddBlockByPath('StarList') do
    for i := 0 to Self.Stars.Count - 1 do
    begin
      Star := TStar(Self.Stars[i]);
      Name := 'StarId' + WideString(SysUtils.IntToStr(Int64(Star.Id)));
      Star.SaveToBlock(AddBlockByPath(Name));
    end;
end;
procedure TGalaxy.ApplyEditableState;
var
  I: Integer;
  Key: WideString;
  Star: TStar;
  Hole: THole;
  Angle, Radius: Single;
  HoleBlock: TBlockParEC;
begin
  if FinalizationName = '' then
  begin
    EditableStateApplied := True;
    FinalizationName := EditableSaveBlock.GetParam('FinalizationName');
    if FinalizationName <> '' then
      SetCheatPoints(0);
    DifficultyLevels[0] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifPirate')))));
    DifficultyLevels[1] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifTrade')))));
    DifficultyLevels[2] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifScn')))));
    DifficultyLevels[3] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifRepair')))));
    DifficultyLevels[4] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifTech')))));
    DifficultyLevels[5] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifQuest')))));
    DifficultyLevels[6] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifHole')))));
    DifficultyLevels[7] :=
        Max(0, Min(9, StrToInt(AnsiString(EditableSaveBlock.GetParam('DifBalance')))));
    WarDeltaWin[1] := StrToInt(AnsiString(EditableSaveBlock.GetParam('KlingsDeltaWin')));
    WarDeltaWin[2] := StrToInt(AnsiString(EditableSaveBlock.GetParam('PiratesDeltaWin')));
    WarDeltaWin[0] := StrToInt(AnsiString(EditableSaveBlock.GetParam('NormalsDeltaWin')));
    GetPlayer.DeclinePlanetBattleOffers :=
        LowerCase(AnsiString(EditableSaveBlock.GetParam('RejectPB'))) = 'true';
    GetPlayer.LoadFromBlock(EditableSaveBlock.GetBlockByPath('Player'));
    HoleBlock := EditableSaveBlock.GetBlockByPath('HoleList');
    for I := 0 to Holes.Count - 1 do
    begin
      Hole := THole(Holes[I]);
      Key := 'HoleId' + IntToStr(Int64(Hole.Id));
      Hole.LoadFromBlock(HoleBlock.GetBlockByPath(Key));
    end;
    for I := 0 to StrToInt(AnsiString(HoleBlock.GetParam('CreateNewHoles'))) - 1 do
    begin
      Hole := THole.Create;
      Hole.InitializeGraphic('');
      THoleSE(Hole.Graphic).SetState(1);
      Hole.Star1 := GetPlayer.CurrentStar;
      Hole.Star2 := GetPlayer.CurrentStar;
      Hole.ArcadeMapName := '';
      Angle := HeadingDegreesToRadians(RandomIntRange(0, 359));
      Radius := RandomIntRange(1000, 2000);
      Hole.Position1 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
      Hole.Position2 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
      Hole.CreatedTurn := CurrentTurn;
      Hole.HoleType := 1;
      Holes.Add(Hole);
    end;
    with EditableSaveBlock.GetBlockByPath('StarList') do
      for I := 0 to Stars.Count - 1 do
      begin
        Star := TStar(Stars[I]);
        Key := 'StarId' + IntToStr(Int64(Star.Id));
        Star.LoadFromBlock(GetBlockByPath(Key));
      end;
    EditableSaveBlock.Clear;
  end;
end;
procedure TGalaxy.RunConfigOnStartHandlers;
var
  Block, Handler: TBlockParEC;
  I, Count: Integer;
  Text: WideString;
begin
  Block := MainDataConfig.GetBlock('BV').FindBlockByPath('OnStart');
  if Block <> nil then
  begin
    Count := Block.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Handler := Block.GetBlockByIndex(I);
      Text := Handler.ConcatenateValues;
      ExecuteScriptText(Text, nil);
    end;
  end;
end;
procedure TGalaxy.RunConfigOnLoadHandlers;
var
  Block, Handler: TBlockParEC;
  I, Count: Integer;
  Text: WideString;
begin
  Block := MainDataConfig.GetBlock('BV').FindBlockByPath('OnLoad');
  if Block <> nil then
  begin
    Count := Block.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Handler := Block.GetBlockByIndex(I);
      Text := Handler.ConcatenateValues;
      ExecuteScriptText(Text, nil);
    end;
  end;
end;
procedure TGalaxy.RunConfigOnSaveHandlers;
var
  Block, Handler: TBlockParEC;
  I, Count: Integer;
  Text: WideString;
begin
  Block := MainDataConfig.GetBlock('BV').FindBlockByPath('OnSave');
  if Block <> nil then
  begin
    Count := Block.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Handler := Block.GetBlockByIndex(I);
      Text := Handler.ConcatenateValues;
      ExecuteScriptText(Text, nil);
    end;
  end;
end;
procedure TGalaxy.ReapplyInterfaceOverrides;
var
  I: Integer;
begin
  for I := 0 to InterfaceStateOverrides.Count - 1 do
    TInterfaceStateOverride(InterfaceStateOverrides[I]).Reapply;
  for I := 0 to InterfaceTextOverrides.Count - 1 do
    TInterfaceTextOverride(InterfaceTextOverrides[I]).Reapply;
  for I := 0 to InterfaceImageOverrides.Count - 1 do
    TInterfaceImageOverride(InterfaceImageOverrides[I]).Reapply;
  for I := 0 to InterfacePositionOverrides.Count - 1 do
    TInterfacePosOverride(InterfacePositionOverrides[I]).Reapply;
  for I := 0 to InterfaceSizeOverrides.Count - 1 do
    TInterfaceSizeOverride(InterfaceSizeOverrides[I]).Reapply;
end;
procedure TGalaxy.BindScriptImports;
var
  I: Integer;
begin
  for I := 0 to Scripts.Count - 1 do
    TScript(Scripts[I]).BindImportedFunctions;
end;
procedure TGalaxy.NextDay;
var
  I, J: Integer;
  Ratio: Single;
  Star: TStar;
  Ship: TShip;
  Group: TGroup;
  Script: TScript;
  Bubble: TMessagePlayer;
  PreviousTechLevel: Integer;
  Text: WideString;
  Stage: Integer;
begin
  Stage := 0;
  if GetPlayer <> nil then
    try
      Ratio :=
          GetCoalitionToPirateSystemRatio
              / GalaxyDifficultyTuning[DifficultyLevels[0]].DifficultyFactor34;
      // Native applies bitwise NOT before comparison, rather than inequality.
      if ((not PirateWinType) = 3)
          and (((Ratio > 1.25) and (NextRandomIntRange(1, 1000, RandomState) <= 3))
              or ((Ratio > 1.5) and (NextRandomIntRange(1, 1000, RandomState) <= 10))
              or ((Ratio > 2) and (NextRandomIntRange(1, 1000, RandomState) <= 30))) then
        Dec(WarDeltaWin[2]);
      if ((Galaxy.CoalitionDefeatedTurn = 0)
              and (Ratio < 0.8)
              and (NextRandomIntRange(1, 1000, RandomState) <= 3))
          or ((Ratio < 0.66) and (NextRandomIntRange(1, 1000, RandomState) <= 10))
          or ((Ratio < 0.5) and (NextRandomIntRange(1, 1000, RandomState) <= 30)) then
      begin
        Inc(WarDeltaWin[2]);
        Dec(WarDeltaWin[0]);
      end;
      Stage := 13;
      if ((((CurrentTurn + Integer(GenerationSeed)) mod GetTurnsBetweenLiberationGroups) = 0)
              and (CurrentTurn >= 300))
          or (WarDeltaWin[0] < -5)
          or ((CountFactionStars(Ord(sfCoalition)) < 5) and (LiberationGroups.Count = 0))
          or (CountFactionStars(Ord(sfCoalition)) = 1) then
      begin
        Stage := 14;
        if LiberationGroups.Count < 2 then
          TryCreateLiberationGroup;
      end;
      Stage := 15;
      for I := LiberationGroups.Count - 1 downto 0 do
      begin
        Group := TGroup(LiberationGroups[I]);
        Group.NextDay;
      end;
      Stage := 16;
      if WingmenPendingLeadershipPenalty = nil then
        WingmenPendingLeadershipPenalty := TList.Create
      else
        WingmenPendingLeadershipPenalty.Clear;
      for I := 0 to Stars.Count - 1 do
      begin

        Star := TStar(Stars[I]);
        if (GetPlayer = nil) or (GetPlayer.CurrentStar <> Star) then
          Star.NextDay(False);
      end;
      if (GetPlayer = nil) or (GetPlayer.GetHull.HullPoints <= 0) then
        Exit;
      Stage := 2;
      I := 0;
      while I < Scripts.Count do
      begin
        Stage := 3;
        Script := TScript(Scripts[I]);
        Script.RunTurnCode;
        Stage := 4;
        if Script.Ships.Count < 1 then
        begin
          for J := 0 to Script.EtherIds.GetCount - 1 do
          begin
            Stage := 5;
            Bubble := FindPlayerBubbleByKey(Script.EtherIds.GetTextAt(J), False);
            if (Bubble <> nil) and (Bubble.Kind = 3) then
            begin
              Bubble.Kind := 5;
              Bubble.WasRead := False;
            end;
          end;
          Stage := 6;
          Scripts.Delete(I);
          try
            Script.Free;
          except
            AppendLogLineThreadSafe('Error Galaxy.Script.Free');
          end;
          Stage := 7;
          for J := 0 to ScriptTemplates.Count - 1 do
            if TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex = I then
              TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex := -1
            else if TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex > I then
              Dec(TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex);
        end
        else
          Inc(I);
      end;
      Inc(CurrentTurn);
      Stage := 8;
      ProcessStationSpawning;
      Stage := 9;
      UpdateConstellationMilitaryStats;
      Stage := 10;
      PlayerDialogueRequestCount := 0;
      Inc(ReservedMessageCounter);
      Inc(TurnsSinceLastShipMessage);
      if CurrentTurn mod 365 = 0 then
        ComputeGlobalGoodsPriceBands;
      Stage := 11;
      if GetPlayer <> nil then
        GetPlayer.RebuildEquipmentCache;
      Stage := 12;
      if (CurrentTurn + Integer(GenerationSeed)) mod 7 = 0 then
        ComputeRangerSpawnQuotas;
      Stage := 17;
      if GetPlayer <> nil then
        if GetPlayer.CurrentStar <> nil then
          for I := GetPlayer.CurrentStar.Ships.Count - 1 downto 0 do
          begin
            Ship := TShip(GetPlayer.CurrentStar.Ships[I]);
            if (Ship.PartnerShip <> nil)
                and (Ship.PartnershipDaysRemaining > 0)
                and (WingmenPendingLeadershipPenalty.IndexOf(Ship) < 0) then
              WingmenPendingLeadershipPenalty.Add(Ship);
          end;
      Stage := 18;
      ApplyWingmanLeadershipPenalty;
      Stage := 19;
      PruneExpiredGalaxyEvents;
      Stage := 20;
      PreviousTechLevel := TechLevel;
      RefreshTechLevel;
      if GetPlayer <> nil then
        if GetPlayer.CountActiveArtefacts(Ord(t_ArtefactAnalyzer)) > 0 then
        begin
          Text := '';
          if TechLevel > PreviousTechLevel then
            Text := LocalizedText('Artefacts.ArtAnalyzer.TechLevelUp');
          if TechLevel < PreviousTechLevel then
            Text := LocalizedText('Artefacts.ArtAnalyzer.TechLevelDown');
          if Text <> '' then
            AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '');
        end;
      Stage := 21;
      TryDispatchMilitaryBaseToEnemyStar;
      Stage := 22;
      RefreshRangerWealthStats;
      Stage := 23;
      RefreshRangerStrengthStats;
      Stage := 24;
      RefreshRangerRatingPlaces;
      Stage := 25;
      PrunePlanetNews;
      Stage := 26;
      CheckMemoryUsage;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
        LogExceptionBackTrace;
        raise Exception.Create('Error in procedure TGalaxy.NextDay label = ' + IntToStr(Stage));
      end;
    end;
end;
procedure TGalaxy.CompleteDay(UnusedRecordFilm: Boolean);
var
  Hole: THole;
  Ship: TShip;
  i, j, Count: Integer;
  Angle, Radius: Single;
  Star: TStar;
  Missile: TMissile;
begin
  if Self.SpecialSimulationMode <> 0 then
    Exit;
  if Self.AreSpecialShipsEnabled then
    AssignSpecialStationService;
  Self.ProcessDominatorResearchProgress;
  ProcessBankDebtAndDeposits;
  Self.ProcessRangerCenterNewYearEvent;
  if (GetPlayer <> nil)
      and GetPlayer.AfterburnerActive
      and (GetPlayer.GetEngine <> nil)
      and (GetPlayer.GetEngine.ConditionPercent <= GlobalsV.AfterburnerStopCondition)
      and (Self.TechnicModEnabled = 0) then
  begin
    GetPlayer.AfterburnerActive := False;
    GetPlayer.RefreshDerivedStats(True);
    PlayerStar.InterruptLongTravel := True;
  end;
  if GetPlayer <> nil then
  begin
    i := 0;
    while i < Self.Holes.Count do
    begin
      Hole := THole(Self.Holes[i]);
      if (Hole.HoleType = 3)
          or ((Hole.HoleType = 4)
              and (Self.KellerMissionState = 5)
              and (Self.ScaleIntByTechLevel(1, 10) < Self.CurrentTurn - Hole.CreatedTurn))
          or ((Hole.HoleType = 1) and (Self.CurrentTurn - Hole.CreatedTurn > 200))
          or ((Hole.HoleType = 4) and (aKling.KellerShip = nil)) then
      begin
        j := 0;
        Count := Hole.Star1.Ships.Count;
        while j < Count do
        begin
          Ship := TShip(Hole.Star1.Ships[j]);
          if (Ship.Order = soJumpHole) and (Ship.OrderTarget = Hole) then
            Break;
          Inc(j);
        end;
        if j >= Count then
        begin
          j := 0;
          Count := Hole.Star2.Ships.Count;
          while j < Count do
          begin
            Ship := TShip(Hole.Star2.Ships[j]);
            if (Ship.Order = soJumpHole) and (Ship.OrderTarget = Hole) then
              Break;
            Inc(j);
          end;
          if j >= Count then
          begin
            if Hole.HoleType = 4 then
              Self.KellerMissionState := 0;
            Self.Holes.Delete(i);
            Hole.Free;
            Dec(i);
          end;
        end;
      end;
      Inc(i);
    end;
  end;
  if (GetPlayer <> nil)
      and (NextRandomIntRange(
              0,
              aConst.GalaxyDifficultyTuning[Self.DifficultyLevels[6]].RandomHoleSpawnRollMaximum,
              Self.RandomState)
          = 0)
      and (Self.Holes.Count <= 2)
      and (Self.CurrentTurn > 300) then
  begin
    Hole := THole.Create;
    Hole.InitializeGraphic('');
    Hole.HoleType := 1;
    Hole.CreatedTurn := Self.CurrentTurn;
    j := 0;
    while True do
    begin
      Inc(j);
      if j > 100 then
        Break;
      Hole.Star1 :=
          TStar(Self.Stars[NextRandomIntRange(0, Self.Stars.Count - 1, Self.RandomState)]);
      if (Hole.Star1.Constellation.Id <> 20)
          and (GetPlayer.CurrentStar <> Hole.Star1)
          and TStar(Hole.Star1).IsConstellationVisible
          and (Hole.Star1.DaysSincePlayerVisit >= 30)
          and (Hole.Star1.ControlFaction <> sfDominators)
          and (Hole.Star1.Status.CustomFaction = '') then
        Break;
    end;
    if j > 100 then
      Hole.Free
    else
    begin
      j := 0;
      while True do
      begin
        Inc(j);
        if j > 100 then
          Break;
        Hole.Star2 :=
            TStar(Self.Stars[NextRandomIntRange(0, Self.Stars.Count - 1, Self.RandomState)]);
        if (Hole.Star1 <> Hole.Star2)
            and (Hole.Star2.Constellation.Id <> 20)
            and (GetPlayer.CurrentStar <> Hole.Star2)
            and TStar(Hole.Star2).IsConstellationVisible
            and (Hole.Star2.DaysSincePlayerVisit >= 30) then
          Break;
      end;
      if j > 100 then
        Hole.Free
      else
      begin
        Self.Holes.Add(Hole);
        Angle :=
            HeadingDegreesToRadians(
                SeededRandomIntRange(
                    0,
                    360,
                    (Hole.Star1.GenerationSeed + Self.CurrentTurn) * Self.GenerationSeed
                )
            );
        Radius :=
            SeededRandomIntRange(
                System.Round(Hole.Star1.MapDiameter * 0.5 * 0.7),
                System.Round(Hole.Star1.MapDiameter * 0.5 * 0.9),
                (Hole.Star1.GenerationSeed + Self.CurrentTurn + j) * Self.GenerationSeed
            );
        Hole.Position1 := MakePointF(System.Sin(Angle) * Radius, -System.Cos(Angle) * Radius);
        Angle :=
            HeadingDegreesToRadians(
                SeededRandomIntRange(
                    0,
                    360,
                    (Hole.Star2.GenerationSeed + Self.CurrentTurn) * Self.GenerationSeed
                )
            );
        Radius :=
            SeededRandomIntRange(
                System.Round(Hole.Star2.MapDiameter * 0.5 * 0.7),
                System.Round(Hole.Star2.MapDiameter * 0.5 * 0.9),
                (Hole.Star2.GenerationSeed + Self.CurrentTurn + j) * Self.GenerationSeed
            );
        Hole.Position2 := MakePointF(System.Sin(Angle) * Radius, -System.Cos(Angle) * Radius);
        if Self.CoalitionDefeatedTurn = 0 then
          Self.AddPlanetNews(
              36,
              FormatText2(
                  PickLocalizedTextVariant(
                      'GalaxyNews.BlackHole.Create',
                      (Hole.Star1.GenerationSeed + Self.CurrentTurn) * Self.GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Star1>',
                  Hole.Star1.Name,
                  '<Star2>',
                  Hole.Star2.Name
              )
          );
      end;
    end;
  end;
  Self.ProcessPlayerSatelliteExploration;
  if Self.TerronSeriesResolvedTurn = 0 then
  begin
    if aKling.TerronShip = nil then
    begin
      Self.TerronSeriesResolvedTurn := Self.CurrentTurn;
      if (GetPlayer <> nil) and (Self.TerronLandingLockTurn <> 0) then
        TryUnlockAchievement('TERRONBATTLE');
    end
    else if Self.TerronToStarTurn <> 0 then
    begin
      Self.TerronSeriesResolvedTurn := Self.CurrentTurn;
      if GetPlayer <> nil then
        TryUnlockAchievement('TERRONSTAR');
    end;
    if Self.TerronSeriesResolvedTurn <> 0 then
    begin
      Self.DominatorResearch[2].Progress := 100;
      if Self.CoalitionDefeatedTurn = 0 then
        AddOrUpdatePlayerBubble(
            3,
            Self.TerronSeriesResolvedTurn,
            ReplaceColoredToken(
                LocalizedColorText('FormRuinsRC.Win.AddNews'),
                '<Date>',
                FormatGameTurnDate(Self.TerronSeriesResolvedTurn),
                '<color=255,240,100>'
            ),
            'TerronWin'
        );
    end;
  end;
  if Self.KellerSeriesResolvedTurn = 0 then
  begin
    if aKling.KellerShip = nil then
    begin
      Self.KellerSeriesResolvedTurn := Self.CurrentTurn;
      if GetPlayer <> nil then
        TryUnlockAchievement('KELLERDESTROY');
    end
    else if Self.KellerLeaveTurn <> 0 then
    begin
      Self.KellerSeriesResolvedTurn := Self.CurrentTurn;
      if GetPlayer <> nil then
        TryUnlockAchievement('KELLERRESEARCH');
    end;
    if Self.KellerResearchTargetStarId <> 0 then
      Self.KellerSeriesResolvedTurn := Self.CurrentTurn;
    if Self.KellerSeriesResolvedTurn <> 0 then
    begin
      Self.DominatorResearch[1].Progress := 100;
      if Self.CoalitionDefeatedTurn = 0 then
        AddOrUpdatePlayerBubble(
            3,
            Self.KellerSeriesResolvedTurn,
            ReplaceColoredToken(
                LocalizedColorText('FormRuinsRC.Win.AddNews'),
                '<Date>',
                FormatGameTurnDate(Self.KellerSeriesResolvedTurn),
                '<color=255,240,100>'
            ),
            'KellerWin'
        );
    end;
  end;
  if Self.BlazerSeriesResolvedTurn = 0 then
  begin
    if aKling.BlazerShip = nil then
    begin
      Self.BlazerSeriesResolvedTurn := Self.CurrentTurn;
      if GetPlayer <> nil then
      begin
        if Self.BlazerSelfDestructTurn = 0 then
          TryUnlockAchievement('TERMINATOR')
        else
          TryUnlockAchievement('BLAZERPROGRAM');
      end;
    end
    else if Self.BlazerLandingPlanetId <> 0 then
    begin
      Self.BlazerSeriesResolvedTurn := Self.CurrentTurn;
      if GetPlayer <> nil then
        TryUnlockAchievement('BLAZERPIECE');
    end;
    if Self.BlazerSeriesResolvedTurn <> 0 then
    begin
      Self.DominatorResearch[0].Progress := 100;
      if Self.CoalitionDefeatedTurn = 0 then
        AddOrUpdatePlayerBubble(
            3,
            Self.BlazerSeriesResolvedTurn,
            ReplaceColoredToken(
                LocalizedColorText('FormRuinsRC.Win.AddNews'),
                '<Date>',
                FormatGameTurnDate(Self.BlazerSeriesResolvedTurn),
                '<color=255,240,100>'
            ),
            'BlazerWin'
        );
      if (Self.BlazerLandingPlanetId <> 0)
          and (aKling.BlazerShip <> nil)
          and TShip(aKling.BlazerShip).InNormalSpace then
      begin
        aKling.BlazerShip.EnemyShip := nil;
        Star := aKling.BlazerShip.CurrentStar;
        for j := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(Star.Ships[j]);
          if Ship.EnemyShip = aKling.BlazerShip then
            Ship.EnemyShip := nil;
          if Ship.TruceShip = aKling.BlazerShip then
            Ship.TruceShip := nil;
          { Native code compares the order target with the galaxy instance. }
          if Ship.OrderTarget = Self then
            Ship.OrderNone(False);
        end;
        for j := 0 to Star.Missiles.Count - 1 do
        begin
          Missile := TMissile(Star.Missiles[j]);
          Missile.ClearReferencesTo(Self);
        end;
      end;
    end;
  end;
  Self.ProcessCoalitionDefeat;
end;
procedure TGalaxy.TransferShipsInTransit;
var
  I, J, Effect: Integer;
  Ship: TShip;
  Hole: THole;
begin
  J := ShipsInTransit.Count;
  for I := 0 to J - 1 do
  begin
    Ship := ShipsInTransit[I];
    if Ship.OrderTarget <> nil then
    begin
      if Ship = GetPlayer then
      begin
        repeat
          Effect := NextRandomIntRange(0, 2, RandomState)
        until SpaceEffectKind <> Effect;
        SpaceEffectKind := Effect;
      end;
      if Ship.OrderTarget is TStar then
        Ship.TransferToStar(Ship.OrderTarget as TStar)
      else
      begin
        Hole := Ship.OrderTarget as THole;
        if Ship.OrderStateData shr 16 = 0 then
          Ship.TransferToStar(Hole.Star2)
        else
          Ship.TransferToStar(Hole.Star1);
      end;
    end;
  end;
  ShipsInTransit.Clear;
  if (KellerMissionState = 1) and (KellerShip <> nil) and (KellerTargetStar <> nil) then
  begin
    if KellerShip.CurrentStar <> KellerTargetStar then
    begin
      KellerShip.CurrentStar.HandleObjectLeavingStar(KellerShip);
      KellerShip.TransferToStar(KellerTargetStar);
    end;
    KellerMissionState := 2;
  end;
end;
procedure TGalaxy.RebuildStarDistances;
var
  I, J: Integer;
  Star: TStar;
begin
  J := Stars.Count;
  for I := 0 to J - 1 do
  begin
    Star := TStar(Stars[I]);
    Star.RebuildStarDistances(Self);
  end;
end;
procedure TGalaxy.RefreshAllShipDerivedState;
var
  I, J, K, L: Integer;
  Star: TStar;
  Ship: TShip;
begin
  J := Stars.Count;
  for I := 0 to J - 1 do
  begin
    Star := TStar(Stars[I]);
    L := Star.Ships.Count;
    for K := 0 to L - 1 do
    begin
      Ship := TShip(Star.Ships[K]);
      Ship.RefreshDerivedStats(True);
      Ship.RefreshGraphicSize;
    end;
  end;
end;
function TGalaxy.IdToConstellation(Id: Cardinal): TConstellation;
var
  Item: TConstellation;
  I: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  for I := 0 to Constellations.Count - 1 do
  begin
    Item := TConstellation(Constellations[I]);
    if Item.Id = Id then
    begin
      Result := Item;
      Exit;
    end;
  end;
  raise Exception.Create('function TGalaxy.IdToConstellation (id: Cardinal): TObject;');
end;
function TGalaxy.IdToStar(Id: Cardinal): TStar;
var
  Item: TStar;
  I, Count: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  if (Cardinal(Stars.Count) >= Id) and (TStar(Stars[Id - 1]).Id = Id) then
  begin
    Result := TStar(Stars[Id - 1]);
    Exit;
  end;
  Count := Stars.Count;
  for I := 0 to Count - 1 do
  begin
    Item := TStar(Stars[I]);
    if Item.Id = Id then
    begin
      Result := Item;
      Exit;
    end;
  end;
  raise Exception.Create('function TGalaxy.IdToStar (id: Cardinal): TObject;');
end;
function TGalaxy.IdToHole(Id: Cardinal): THole;
var
  Item: THole;
  I, Count: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  Count := Holes.Count;
  for I := 0 to Count - 1 do
  begin
    Item := THole(Holes[I]);
    if Item.Id = Id then
    begin
      Result := Item;
      Exit;
    end;
  end;
  raise Exception.Create('function TGalaxy.IdToHole (id: Cardinal): TObject;');
end;
function TGalaxy.IdToPlanet(Id: Cardinal; RaiseIfMissing: Boolean): Pointer;
var
  Star: TStar;
  Planet: TPlanet;
  I, StarCount, J, PlanetCount: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  if (Cardinal(Planets.Count) >= Id) and (Cardinal(TPlanet(Planets[Id - 1]).Id) = Id) then
  begin
    Result := Planets[Id - 1];
    Exit;
  end;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    PlanetCount := Star.Planets.Count;
    for J := 0 to PlanetCount - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Cardinal(Planet.Id) = Id then
      begin
        Result := Planet;
        Exit;
      end;
    end;
  end;
  if RaiseIfMissing then
    raise Exception.Create(
        'function TGalaxy.IdToPlanet (id: Cardinal; exc: boolean = True): TObject;')
  else
    Result := nil;
end;
function TGalaxy.IdToShip(Id: Cardinal; RaiseIfMissing: Boolean): Pointer;
var
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
  I, StarCount, J, Count, K, ArtefactCount: Integer;
  Item: TItem;
  Artefact: TArtefact;
  Storage: PStorageEntry;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Ships.Count;
    for J := 0 to Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if Cardinal(Ship.Id) = Id then
      begin
        Result := Ship;
        Exit;
      end;
      ArtefactCount := Ship.Artefacts.Count;
      for K := 0 to ArtefactCount - 1 do
      begin
        Artefact := TArtefact(Ship.Artefacts[K]);
        if (Artefact is TArtefactTranclucator)
            and (Cardinal((TObject((Artefact as TArtefactTranclucator).Ship) as TTranclucator).Id)
                = Id) then
        begin
          Result := (Artefact as TArtefactTranclucator).Ship;
          Exit;
        end;
      end;
    end;
    Count := Star.Planets.Count;
    for J := 0 to Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      ArtefactCount := Planet.Warriors.Count;
      for K := 0 to ArtefactCount - 1 do
      begin
        Ship := TShip(Planet.Warriors[K]);
        if Cardinal(Ship.Id) = Id then
        begin
          Result := Ship;
          Exit;
        end;
      end;
    end;
    Count := Star.Items.Count;
    for J := 0 to Count - 1 do
    begin
      Item := TItem(Star.Items[J]);
      if (Item is TArtefactTranclucator)
          and (TArtefactTranclucator(Item).Ship <> nil)
          and (Cardinal((TObject(TArtefactTranclucator(Item).Ship) as TTranclucator).Id) = Id) then
      begin
        Result := TArtefactTranclucator(Item).Ship;
        Exit;
      end;
    end;
    Count := Star.MovingDropItems.Count;
    for J := 0 to Count - 1 do
    begin
      Item := TItem(PMovingDropItemEntry(Star.MovingDropItems[J]).Payload);
      if (Item <> nil)
          and (Item is TArtefactTranclucator)
          and (TArtefactTranclucator(Item).Ship <> nil)
          and (Cardinal((TObject(TArtefactTranclucator(Item).Ship) as TTranclucator).Id) = Id) then
      begin
        Result := TArtefactTranclucator(Item).Ship;
        Exit;
      end;
    end;
  end;
  for I := 0 to GetPlayer.StorageEntries.Count - 1 do
  begin
    Storage := GetPlayer.StorageEntries[I];
    Item := Storage.Item;
    if (Item is TArtefactTranclucator)
        and (TArtefactTranclucator(Item).Ship <> nil)
        and (Cardinal((TObject(TArtefactTranclucator(Item).Ship) as TTranclucator).Id) = Id) then
    begin
      Result := TArtefactTranclucator(Item).Ship;
      Exit;
    end;
  end;
  if RaiseIfMissing then
    raise Exception.Create('function TGalaxy.IdToShip, id = ' + IntToStr(Id))
  else
    Result := nil;
end;
function TGalaxy.IdToItem(Id: Cardinal; RaiseIfMissing: Boolean): Pointer;
var
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
  Item: TItem;
  Storage: PStorageEntry;
  Stored: TStoredItem;
  Drop: PMovingDropItemEntry;
  i, StarCount, j, ListCount, k, SubCount: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  StarCount := Self.Stars.Count;
  for i := 0 to StarCount - 1 do
  begin
    Star := TStar(Self.Stars[i]);
    ListCount := Star.Items.Count;
    for j := 0 to ListCount - 1 do
    begin
      Item := TItem(Star.Items[j]);
      if Cardinal(Item.Id) = Id then
      begin
        Result := Item;
        Exit;
      end;
      if Item is TArtefactTranclucator then
      begin
        Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
        if Result <> nil then
          Exit;
      end;
    end;
    ListCount := Star.MovingDropItems.Count;
    for j := 0 to ListCount - 1 do
    begin
      Drop := PMovingDropItemEntry(Star.MovingDropItems[j]);
      Item := Drop^.Payload as TItem;
      if Item = nil then
        Continue;
      if Cardinal(Item.Id) = Id then
      begin
        Result := Item;
        Exit;
      end;
      if Item is TArtefactTranclucator then
      begin
        Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
        if Result <> nil then
          Exit;
      end;
    end;
    ListCount := Star.Ships.Count;
    for j := 0 to ListCount - 1 do
    begin
      Ship := TShip(Star.Ships[j]);
      Item := Ship.FindCarriedItemById(Id);
      if Item <> nil then
      begin
        Result := Item;
        Exit;
      end;
      if (Ship.TypeId = stRanger) and (Ship is TPlayer) then
        for k := 0 to TPlayer(Ship).StorageEntries.Count - 1 do
        begin
          Storage := PStorageEntry(TPlayer(Ship).StorageEntries[k]);
          Item := Storage^.Item;
          if Cardinal(Item.Id) = Id then
          begin
            Result := Item;
            Exit;
          end;
          if Item is TArtefactTranclucator then
          begin
            Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
            if Result <> nil then
              Exit;
          end;
        end;
    end;
    ListCount := Star.Planets.Count;
    for j := 0 to ListCount - 1 do
    begin
      Planet := TPlanet(Star.Planets[j]);
      SubCount := Planet.Warriors.Count;
      for k := 0 to SubCount - 1 do
      begin
        Ship := TShip(Planet.Warriors[k]);
        Item := Ship.FindCarriedItemById(Id);
        if Item <> nil then
        begin
          Result := Item;
          Exit;
        end;
      end;
      SubCount := Planet.EquipmentShop.Count;
      for k := 0 to SubCount - 1 do
      begin
        Item := TItem(Planet.EquipmentShop[k]);
        if Cardinal(Item.Id) = Id then
        begin
          Result := Item;
          Exit;
        end;
        if Item is TArtefactTranclucator then
        begin
          Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
          if Result <> nil then
            Exit;
        end;
      end;
      if Planet.SurfaceLootEntries <> nil then
      begin
        SubCount := Planet.SurfaceLootEntries.Count;
        for k := 0 to SubCount - 1 do
        begin
          if Planet.SurfaceLootEntries[k] = nil then
            Continue;
          Item := PPlanetSurfaceLootEntry(Planet.SurfaceLootEntries[k])^.Item;
          if Cardinal(Item.Id) = Id then
          begin
            Result := Item;
            Exit;
          end;
          if Item is TArtefactTranclucator then
          begin
            Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
            if Result <> nil then
              Exit;
          end;
        end;
      end;
    end;
  end;
  if fEquipmentShop.TemporaryShopSlots <> nil then
    for i := 0 to fEquipmentShop.TemporaryShopSlots.Count - 1 do
      if TShopSlot(fEquipmentShop.TemporaryShopSlots[i]).Item <> nil then
        if Cardinal(TShopSlot(fEquipmentShop.TemporaryShopSlots[i]).Item.Id) = Id then
        begin
          Result := TShopSlot(fEquipmentShop.TemporaryShopSlots[i]).Item;
          Exit;
        end;
  for k := 0 to Self.StoredItems.Count - 1 do
  begin
    Stored := TStoredItem(Self.StoredItems[k]);
    if Stored.Item = nil then
      Continue;
    Item := TObject(Stored.Item) as TItem;
    if Cardinal(Item.Id) = Id then
    begin
      Result := Stored.Item;
      Exit;
    end;
    if Item is TArtefactTranclucator then
    begin
      Result := TShip((Item as TArtefactTranclucator).Ship).FindCarriedItemById(Id);
      if Result <> nil then
        Exit;
    end;
  end;
  if RaiseIfMissing then
  begin
    raise SysUtils.Exception.Create(
        'function TGalaxy.IdToItem, id = ' + SysUtils.IntToStr(Int64(Id)));
    Exit;
  end;
  Result := nil;
end;
function TGalaxy.IdToAsteroid(Id: Cardinal): Pointer;
var
  Star: TStar;
  Item: TAsteroid;
  I, StarCount, J, Count: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Asteroids.Count;
    for J := 0 to Count - 1 do
    begin
      Item := TAsteroid(Star.Asteroids[J]);
      if Cardinal(Item.Id) = Id then
      begin
        Result := Item;
        Exit;
      end;
    end;
  end;
end;
function TGalaxy.IdToMissile(Id: Cardinal): Pointer;
var
  Star: TStar;
  Item: TMissile;
  I, StarCount, J, Count: Integer;
begin
  Result := nil;
  if Id = 0 then
    Exit;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Missiles.Count;
    for J := 0 to Count - 1 do
    begin
      Item := TMissile(Star.Missiles[J]);
      if Cardinal(Item.Id) = Id then
      begin
        Result := Item;
        Exit;
      end;
    end;
  end;
end;
function TGalaxy.ContainsShipReference(Ship: Pointer): Boolean;
var
  Star: TStar;
  Planet: TPlanet;
  OtherShip: TShip;
  I, StarCount, J, ItemCount, K, ChildCount: Integer;
  Item: TItem;
begin
  Result := True;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    ItemCount := Star.Ships.Count;
    for J := 0 to ItemCount - 1 do
    begin
      OtherShip := TShip(Star.Ships[J]);
      if OtherShip = Ship then
        Exit;
      ChildCount := OtherShip.Artefacts.Count;
      for K := 0 to ChildCount - 1 do
      begin
        Item := TItem(OtherShip.Artefacts[K]);
        if (Item is TArtefactTranclucator)
            and ((TObject((Item as TArtefactTranclucator).Ship) as TTranclucator) = Ship) then
          Exit;
      end;
    end;
    ItemCount := Star.Planets.Count;
    for J := 0 to ItemCount - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      ChildCount := Planet.Warriors.Count;
      for K := 0 to ChildCount - 1 do
      begin
        OtherShip := TShip(Planet.Warriors[K]);
        if OtherShip = Ship then
          Exit;
      end;
    end;
  end;
  Result := False;
end;
function TGalaxy.ContainsPlanetReference(Planet: Pointer): Boolean;
var
  Star: TStar;
  UnusedPlanet: TPlanet;
  I, StarCount, J, PlanetCount: Integer;
begin
  Result := True;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    PlanetCount := Star.Planets.Count;
    for J := 0 to PlanetCount - 1 do
    begin
      UnusedPlanet := TPlanet(Star.Planets[J]);
      if UnusedPlanet = Planet then
        Exit;
    end;
  end;
  Result := False;
end;
procedure TGalaxy.ClearJumpGates;
var
  I: Integer;
  Entry: PJumpGateEntry;
begin
  for I := 0 to JumpGates.Count - 1 do
  begin
    Entry := JumpGates[I];
    if Entry.Gate <> nil then
    begin
      Entry.Gate.DetachFromSpace;
      ReleaseSpaceObject(Entry.Gate);
    end;
    if Entry.Effect <> nil then
    begin
      Entry.Effect.DetachFromSpace;
      ReleaseSpaceObject(Entry.Effect);
    end;
    FreeEC(Entry);
  end;
  JumpGates.Clear;
end;
function TGalaxy.CreateJumpGate(WithEffect: Boolean): PJumpGateEntry;
var
  Entry: PJumpGateEntry;
begin
  Entry := AllocClearEC(SizeOf(TJumpGateEntry));
  JumpGates.Add(Entry);
  Entry.UsedThisTurn := False;
  RetainSpaceObject(Entry.Gate, TGateSE.Create('Gate', Classes.Point(0, 0)));
  if WithEffect then
    RetainSpaceObject(Entry.Effect, TGateEffectSE.Create('Effect.GateEffect', Classes.Point(0, 0)))
  else
    Entry.Effect := nil;
  Result := Entry;
end;
function TGalaxy.FindHoleInStarByKind(Star: TStar; HoleKind: Integer): THole;
var
  I: Integer;
  Hole: THole;
begin
  for I := 0 to Holes.Count - 1 do
  begin
    Hole := THole(Holes[I]);
    if (Hole.HoleType = HoleKind) and ((Hole.Star1 = Star) or (Hole.Star2 = Star)) then
    begin
      Result := Hole;
      Exit;
    end;
  end;
  Result := nil;
end;
procedure TGalaxy.ReleaseItemGraphics;
var
  Star: TStar;
  Ship: TShip;
  Item: TItem;
  StarCount, ShipCount, ItemCount, I, J, K: Integer;
begin
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    ItemCount := Star.Items.Count;
    for K := 0 to ItemCount - 1 do
    begin
      Item := TItem(Star.Items[K]);
      if Item.GraphObject <> nil then
        ReleaseSpaceObject(Item.GraphObject);
    end;
    ShipCount := Star.Ships.Count;
    for J := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      ItemCount := Ship.Inventory.Count;
      for K := 0 to ItemCount - 1 do
      begin
        Item := TItem(Ship.Inventory[K]);
        if Item.GraphObject <> nil then
          ReleaseSpaceObject(Item.GraphObject);
      end;
      ItemCount := Ship.Artefacts.Count;
      for K := 0 to ItemCount - 1 do
      begin
        Item := TItem(Ship.Artefacts[K]);
        if Item.GraphObject <> nil then
          ReleaseSpaceObject(Item.GraphObject);
      end;
    end;
  end;
end;
procedure TGalaxy.GenerateSpaceBackground(BackgroundIndex: Integer);
var
  EntryIndex, Capacity: Integer;
  I, GroupCount, GroupSize, J, K, ImageKind: Integer;
  OrbitStep, Angle1, Angle2, Radius, Angle, DepthRange: Double;
  MinRadius, MaxRadius, StarRadius: Integer;
  RadiusFraction, Density: Single;
  LayerIndex, OffsetX, OffsetY, Quadrant: Integer;
  NearDepth, FarDepth, DepthScale: Single;
  ImageKindCount: Integer;
  Style: WideString;
  Center: TVector3D;
  ImageKinds: array[0..10] of Integer;
  procedure AdvanceEntry; // @addr 0x7A6A94 @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; entry index -4, capacity -8, galaxy -12."
  begin
    Inc(EntryIndex);
    if EntryIndex + 1 > Capacity then
    begin
      Capacity := EntryIndex + 100;
      SetLength(SpaceBackgroundEntries, Capacity);
    end;
  end;
begin
  MinRadius := TStar(Stars[0]).MapDiameter;
  MaxRadius := MinRadius;
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    StarRadius := TStar(Stars[I]).MapDiameter;
    MinRadius := Min(MinRadius, StarRadius);
    MaxRadius := Max(MaxRadius, StarRadius);
  end;
  MinRadius := MinRadius div 2;
  MaxRadius := MaxRadius div 2;
  StarRadius := PlayerStar.MapDiameter div 2;
  // The native formula requires differing extrema; retain that assumption.
  RadiusFraction := (PlayerStar.MapDiameter div 2 - MinRadius) / (MaxRadius - MinRadius);
  if SpaceImage <= 1 then
    Density := 0.5
  else
    Density := 1;
  EntryIndex := 0;
  Capacity := 500;
  NearDepth := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 5.1, 7.1);
  FarDepth := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 7, 10);
  DepthScale := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 1, 1.5);
  SetLength(SpaceBackgroundEntries, Capacity);
  if BackgroundIndex < 10 then
    Style := GameDataConfig.GetBlockByPath('StyleGarbage').GetParam('0' + IntToStr(BackgroundIndex))
  else
    Style := GameDataConfig.GetBlockByPath('StyleGarbage').GetParam(IntToStr(BackgroundIndex));
  ImageKindCount := CountDelimitedPartsW(Style, ',');
  for I := 0 to ImageKindCount - 1 do
    ImageKinds[I] := ExtractDigitsToIntW(ExtractDelimitedPartW(Style, I, ','));
  GroupCount := Round((RadiusFraction * 1 + 4) * Density);
  Quadrant := 0;
  for I := 0 to GroupCount - 1 do
  begin
    J := Round(RandomFloatRange(0, 1) * (StarRadius * 0.6));
    case Quadrant of
      0:
      begin
        Center.X := RandomFloatRange(0.1, 0.2) * StarRadius * (RandomIntRange(0, 1) * 2 - 1);
        Center.Y := RandomFloatRange(0.1, 0.2) * StarRadius * (RandomIntRange(0, 1) * 2 - 1);
        Quadrant := RandomIntRange(1, 4);
      end;
      1:
      begin
        Center.X := RandomFloatRange(0.6, 1.5) * StarRadius;
        Center.Y := -RandomFloatRange(0.6, 1.5) * StarRadius + J;
      end;
      2:
      begin
        Center.X := RandomFloatRange(0.6, 1.5) * StarRadius - J;
        Center.Y := RandomFloatRange(0.6, 1.5) * StarRadius;
      end;
      3:
      begin
        Center.X := -RandomFloatRange(0.6, 1.5) * StarRadius;
        Center.Y := RandomFloatRange(0.6, 1.5) * StarRadius - J;
      end;
      4:
      begin
        Center.X := -RandomFloatRange(0.6, 1.5) * StarRadius + J;
        Center.Y := -RandomFloatRange(0.6, 1.5) * StarRadius;
      end;
    end;
    IncrementWrapped(Quadrant, 1, 4);
    Center.Z := RandomFloatRange(0.9, 1.9);
    ImageKind := ImageKinds[RandomIntRange(0, ImageKindCount - 1)];
    LayerIndex := 0;
    for J := 0 to 5 do
    begin
      OffsetX := Round(RandomIntRange(-100, 100));
      OffsetY := Round(RandomIntRange(-100, 100));
      for K := 0 to 1 do
      begin
        Inc(LayerIndex);
        SpaceBackgroundEntries[EntryIndex].ImageIndex :=
            SelectSpaceImageTemplate(ImageKind + 5 - J);
        SpaceBackgroundEntries[EntryIndex].OrbitCenter := Center;
        SpaceBackgroundEntries[EntryIndex].Position.X :=
            RemapClamped(LayerIndex, 1, 8, 1, 5) * OffsetX * DepthScale
                + (Center.X + RandomIntRange(-100, 100));
        SpaceBackgroundEntries[EntryIndex].Position.Y :=
            RemapClamped(LayerIndex, 1, 10, 1, 5) * OffsetY * DepthScale
                + (Center.Y + RandomIntRange(-100, 100));
        SpaceBackgroundEntries[EntryIndex].Position.Z :=
            RemapClamped(LayerIndex, 1, 12, NearDepth, FarDepth);
        SpaceBackgroundEntries[EntryIndex].Unknown38 := MakeVector3D(0, 0, 0);
        SpaceBackgroundEntries[EntryIndex].OrbitStepDegrees := 0;
        SpaceBackgroundEntries[EntryIndex].FrameIndex := RandomIntRange(0, 2000000000);
        AdvanceEntry;
      end;
    end;
  end;
  GroupCount := Round((RadiusFraction * 2 + 4) * Density);
  for I := 0 to GroupCount - 1 do
  begin
    repeat
      J := Round(PlayerStar.MapDiameter * 0.8);
      Center.X := RandomIntRange(-J, J);
      Center.Y := RandomIntRange(-J, J);
      Center.Z := FarDepth + RandomFloatRange(2.05, 3) * DepthScale;
    until Center.X * Center.X + Center.Y * Center.Y > 25;
    DepthRange := RandomFloatRange(4, 10);
    OrbitStep := RandomFloatRange(0.05, 0.1) * (RandomIntRange(0, 1) * 2 - 1);
    Angle1 := HeadingDegreesToRadians(RandomIntRange(0, 360));
    Angle2 := HeadingDegreesToRadians(RandomIntRange(0, 360));
    GroupSize := RandomIntRange(1, 2);
    for J := 0 to GroupSize - 1 do
    begin
      SpaceBackgroundEntries[EntryIndex].Position.Z := Center.Z + RandomFloatRange(0, DepthRange);
      SpaceBackgroundEntries[EntryIndex].ImageIndex :=
          SelectSpaceImageTemplate(
              1000
                  + 5
                  - Round(
                      (SpaceBackgroundEntries[EntryIndex].Position.Z - Center.Z) / DepthRange * 5)
          );
      SpaceBackgroundEntries[EntryIndex].OrbitCenter := Center;
      if RandomIntRange(0, 2) = 0 then
      begin
        Radius := RandomIntRange(100, 250);
        Angle := Angle1 + RandomIntRange(-1, 1) * 3.1415926 / 180;
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + Sin(Angle) * Radius;
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y - Cos(Angle) * Radius;
      end
      else if RandomIntRange(0, 2) <> 0 then
      begin
        Radius := RandomIntRange(100, 250);
        Angle := Angle2 + RandomIntRange(-3, 3) * 3.1415926 / 180;
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + Sin(Angle) * Radius;
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y - Cos(Angle) * Radius;
      end
      else
      begin
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + RandomIntRange(-100, 100);
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y + RandomIntRange(-100, 100);
      end;
      SpaceBackgroundEntries[EntryIndex].Unknown38 := MakeVector3D(0, 0, 0);
      SpaceBackgroundEntries[EntryIndex].OrbitStepDegrees :=
          OrbitStep + RandomFloatRange(0.07, 0.1);
      SpaceBackgroundEntries[EntryIndex].FrameIndex := RandomIntRange(0, 2000000000);
      AdvanceEntry;
    end;
  end;
  SetLength(SpaceBackgroundEntries, EntryIndex);
end;
procedure TGalaxy.EnableDominatorSurfaces;
var
  I, J, K: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  if GraphDominatorSurfacesEnabled then
    Exit;
  GraphDominatorSurfacesEnabled := True;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
      TShip(Star.Ships[J]).RefreshGraphic;
    for K := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[K]);
      for J := 0 to Planet.Warriors.Count - 1 do
        TShip(Planet.Warriors[J]).RefreshGraphic;
    end;
  end;
end;
procedure TGalaxy.DisableDominatorSurfaces;
var
  I, J, K: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  if not GraphDominatorSurfacesEnabled then
    Exit;
  GraphDominatorSurfacesEnabled := False;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
      TShip(Star.Ships[J]).RefreshGraphic;
    for K := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[K]);
      for J := 0 to Planet.Warriors.Count - 1 do
        TShip(Planet.Warriors[J]).RefreshGraphic;
    end;
  end;
end;
function TGalaxy.HasVisibleScoreModFlags: Boolean;
begin
  Result := True;
  if (DominatorModLevel = 0)
      and (TechnicModEnabled = 0)
      and (AmmoModEnabled = 0)
      and (GodModEnabled = 0)
      and (UltraScanModEnabled = 0)
      and (StasisModEnabled = 0)
      and not EditableStateApplied then
    Result := False;
end;
function TGalaxy.GetCheatPoints: Integer;
begin
  Result := CheatPoints;
end;
procedure TGalaxy.SetCheatPoints(Value: Integer);
begin
  CheatPoints := Value;
end;
constructor THole.Create;
begin
  inherited Create;
  if Galaxy <> nil then
  begin
    Id := Galaxy.NextHoleId;
    Inc(Galaxy.NextHoleId);
  end;
end;
destructor THole.Destroy;
begin
  if Graphic <> nil then
    ReleaseSpaceObject(Graphic);
  inherited Destroy;
end;
procedure THole.InitializeGraphic(GraphKey: WideString);
var
  Block: TBlockParEC;
  Key: WideString;
begin
  Key := GraphKey;
  if Key = '' then
  begin
    Block := GameDataConfig.GetBlockByPath('SE.Hole');
    Key :=
        'Hole.'
            + Block.GetBlockNameByIndex(
                SeededRandomIntRange(0, Block.GetBlockCount - 1, Id + Galaxy.CurrentTurn));
  end;
  RetainSpaceObject(Graphic, CreateSpaceObjectByName('Hole', Key, Classes.Point(0, 0)));
  Graphic.SetPosition(MakePointF(0, 0));
  ArcadeMapName := '';
end;
procedure THole.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddDWord(Star1.Id);
  Buffer.AddSingle(Position1.X);
  Buffer.AddSingle(Position1.Y);
  Buffer.AddDWord(Star2.Id);
  Buffer.AddSingle(Position2.X);
  Buffer.AddSingle(Position2.Y);
  Buffer.AddIntegerValue(CreatedTurn);
  Buffer.AddIntegerValue(HoleType);
  Buffer.AddWideStringZ(Graphic.GraphKey);
  Buffer.AddWideStringZ(ArcadeMapName);
end;
procedure THole.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextHoleId <= Id then
    Galaxy.NextHoleId := Id + 1;
  Star1 := TStar(Buffer.GetUInt32);
  Position1.X := Buffer.GetSingle;
  Position1.Y := Buffer.GetSingle;
  Star2 := TStar(Buffer.GetUInt32);
  Position2.X := Buffer.GetSingle;
  Position2.Y := Buffer.GetSingle;
  CreatedTurn := Buffer.GetInt32;
  HoleType := Buffer.GetInt32;
  RetainSpaceObject(
      Graphic,
      CreateSpaceObjectByName('Hole', Buffer.ReadWideString, Classes.Point(0, 0))
  );
  Graphic.SetPosition(MakePointF(0, 0));
  ArcadeMapName := Buffer.ReadWideString;
end;
procedure THole.ResolveLoadedReferences(Galaxy: TGalaxy);
begin
  Star1 := TObject(Galaxy.IdToStar(Cardinal(Star1))) as TStar;
  Star2 := TObject(Galaxy.IdToStar(Cardinal(Star2))) as TStar;
end;
procedure THole.SaveToBlock(Block: TBlockParEC);
begin
  Block.AddParam('Star1Id', IntToStr(Star1.Id));
  Block.AddParam('Star1CoordX', FloatToStr(Position1.X));
  Block.AddParam('Star1CoordY', FloatToStr(Position1.Y));
  Block.AddParam('Star2Id', IntToStr(Star2.Id));
  Block.AddParam('Star2CoordX', FloatToStr(Position2.X));
  Block.AddParam('Star2CoordY', FloatToStr(Position2.Y));
  Block.AddParam('TurnsToClose', IntToStr(CreatedTurn + 200 - Galaxy.CurrentTurn));
  Block.AddParam('MapName', ArcadeMapName);
end;
procedure THole.LoadFromBlock(Block: TBlockParEC);
begin
  Star1 := Galaxy.IdToStar(StrToInt(AnsiString(Block.GetParam('Star1Id'))));
  Position1.X := ExtractDecimalToSingleW(Block.GetParam('Star1CoordX'));
  Position1.Y := ExtractDecimalToSingleW(Block.GetParam('Star1CoordY'));
  Star2 := Galaxy.IdToStar(StrToInt(AnsiString(Block.GetParam('Star2Id'))));
  Position2.X := ExtractDecimalToSingleW(Block.GetParam('Star2CoordX'));
  Position2.Y := ExtractDecimalToSingleW(Block.GetParam('Star2CoordY'));
  CreatedTurn := Galaxy.CurrentTurn - 200 + StrToInt(AnsiString(Block.GetParam('TurnsToClose')));
  ArcadeMapName := Block.GetParam('MapName');
end;
constructor TCustomSystemInfo.Create;
begin
  inherited Create;
end;
destructor TCustomSystemInfo.Destroy;
begin
  inherited Destroy;
end;
procedure TCustomSystemInfo.LoadFromBuffer(Buffer: TBufEC);
begin
  Name := Buffer.ReadWideString;
  Icon := Buffer.ReadWideString;
  Info := Buffer.ReadWideString;
  TypeTag := Buffer.ReadWideString;
  Distance := Buffer.GetInt32;
end;
procedure TCustomSystemInfo.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(Name);
  Buffer.AddWideStringZ(Icon);
  Buffer.AddWideStringZ(Info);
  Buffer.AddWideStringZ(TypeTag);
  Buffer.AddIntegerValue(Distance);
end;
constructor TStar.Create;
begin
  inherited Create;
  if Galaxy <> nil then
  begin
    Id := Galaxy.NextStarId;
    Inc(Galaxy.NextStarId);
    GenerationSeed := NextRandomIntRange(100000, MaxInt, Galaxy.RandomState);
  end;
  RandomState := GenerationSeed;
  Planets := TObjectList.Create;
  Asteroids := TObjectList.Create;
  Ships := TObjectList.Create;
  Items := TObjectList.Create;
  MovingDropItems := TList.Create;
  Missiles := TObjectList.Create;
  PlayerCombatOccurred := False;
  InterruptLongTravel := False;
  KeepFilmRunning := False;
  Reserved64 := 0;
  Dominion := nil;
  FactionStrengthCacheTurn := 0;
  CustomSystemInfos := TObjectList.Create;
  CombatEvents := TList.Create;
  PendingFilmObjectRemovals := TList.Create;
  ReferencedItems := TList.Create;
  PlayerFilmPath := nil;
  RecordingTurnFilm := False;
end;
destructor TStar.Destroy;
var
  I: Integer;
  Entry: PMovingDropItemEntry;
begin
  if Graphic <> nil then
    ReleaseSpaceObject(Graphic);
  for I := 0 to MovingDropItems.Count - 1 do
  begin
    Entry := MovingDropItems[I];
    if Entry.Payload <> nil then
      Entry.Payload.Free;
    Entry.Payload := nil;
    FreeEC(Entry);
  end;
  MovingDropItems.Free;
  MovingDropItems := nil;
  Items.Free;
  Items := nil;
  Missiles.Free;
  Missiles := nil;
  Ships.Free;
  Ships := nil;
  Planets.Free;
  Planets := nil;
  Asteroids.Free;
  Asteroids := nil;
  CustomSystemInfos.Free;
  CustomSystemInfos := nil;
  CombatEvents.Free;
  CombatEvents := nil;
  PendingFilmObjectRemovals.Free;
  PendingFilmObjectRemovals := nil;
  ReferencedItems.Free;
  ReferencedItems := nil;
  inherited Destroy;
end;
procedure TStar.GenerateSystemContents(TerronSystem: Boolean);
var
  I, NameIndex, AsteroidCount, Variant, Variants, Tries, J: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  TotalPlanets, Inhabited: Integer;
  Text: WideString;
  Definition: TBlockParEC;
begin
  NameIndex := Galaxy.Stars.IndexOf(Self) mod LanguageDataConfig.GetBlock('Star').GetParamCount;
  Text := LanguageDataConfig.GetBlock('Star').GetParamValue(NameIndex);
  Name := ExtractDelimitedPartW(Text, 0, ',');
  if TerronSystem then
    Definition := GameDataConfig.GetBlockByPath('Star.Terron')
  else if Galaxy.Stars.IndexOf(Self) = 2 then
    Definition := GameDataConfig.GetBlockByPath('Star.04')
  else
  begin
    if BackgroundImage < 10 then
      Text := GameDataConfig.GetBlockByPath('StyleStar').GetParam('0' + IntToStr(BackgroundImage))
    else
      Text := GameDataConfig.GetBlockByPath('StyleStar').GetParam(IntToStr(BackgroundImage));
    Definition := GameDataConfig.GetBlockByPath('Star');
    Variant := 0;
    for I := 0 to Definition.GetBlockCount - 1 do
      if FindTextPosW(Definition.GetBlockNameByIndex(I), Text) > 0 then
        Inc(Variant, ExtractDigitsToIntW(Definition.GetBlockByIndex(I).GetParam('Priority')));
    Variant := RandomIntRange(0, Variant - 1);
    I := 0;
    while I < Definition.GetBlockCount do
    begin
      if FindTextPosW(Definition.GetBlockNameByIndex(I), Text) > 0 then
      begin
        Dec(Variant, ExtractDigitsToIntW(Definition.GetBlockByIndex(I).GetParam('Priority')));
        if Variant < 0 then
          Break;
      end;
      Inc(I);
    end;
    if I >= Definition.GetBlockCount then
      RaiseWideMessage('Star.Init');
    Definition := GameDataConfig.GetBlockByPath('Star.' + Definition.GetBlockNameByIndex(I));
  end;
  Radius := StrToInt(AnsiString(Definition.GetParam('Radius')));
  SafeRadius := ExtractDecimalToSingleW(Definition.GetParam('SafeRadius'));
  DamageRadius := ExtractDecimalToSingleW(Definition.GetParam('DamageRadius'));
  SystemRadius := Radius;
  RetainSpaceObject(
      Graphic,
      CreateSpaceObjectByName('Star', Definition.GetParam('SEGraph'), Classes.Point(0, 0))
  );
  SystemProcessName := Definition.GetParam('SEProcess');
  Graphic.SetPosition(MakePointF(0, 0));
  if Galaxy.Stars.IndexOf(Self) = 2 then
  begin
    TotalPlanets := 7;
    Inhabited := 0;
  end
  else if Galaxy.Stars.IndexOf(Self) < 5 then
  begin
    TotalPlanets := 6;
    Inhabited := 3;
  end
  else if Galaxy.Stars.IndexOf(Self) = 70 then
  begin
    TotalPlanets := 3;
    Inhabited := 10;
  end
  else if Galaxy.Stars.IndexOf(Self) = 71 then
  begin
    TotalPlanets := 5;
    Inhabited := 11;
  end
  else
  begin
    TotalPlanets := NextRandomIntRange(3, 6, RandomState);
    Inhabited := Round(TotalPlanets div 2 + NextRandomIntRange(0, 1, RandomState));
    if Inhabited > 2 * TotalPlanets / 3 then
      Inhabited := Round(2 * TotalPlanets / 3);
    if Inhabited > 3 then
      Inhabited := 3;
  end;
  for I := 1 to TotalPlanets do
  begin
    Planet := TPlanet.Create;
    Planet.InitGenerated(Self, TotalPlanets, Inhabited);
    Planets.Add(Planet);
    Galaxy.Planets.Add(Planet);
  end;
  ControlFaction := sfCoalition;
  PreviousControlFaction := ControlFaction;
  Battle := 0;
  DominatorSeries := TDominatorSeries(NextRandomIntRange(0, 2, RandomState));
  Flag80 := 0;
  LastDominatorPresenceTurn := 0;
  LastPiratePresenceTurn := 0;
  LastLiberationRewardsTurn := 0;
  LiberationRewardsPending := False;
  if BackgroundImage < 10 then
    Text := GameDataConfig.GetBlockByPath('StyleAsteroid').GetParam('0' + IntToStr(BackgroundImage))
  else
    Text := GameDataConfig.GetBlockByPath('StyleAsteroid').GetParam(IntToStr(BackgroundImage));
  I := 2 * NextRandomIntRange(0, CountDelimitedPartsW(Text, ',') div 2 - 1, RandomState);
  Variants := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, I + 1, ','));
  Text := ExtractDelimitedPartW(Text, I, ',');
  AsteroidCount := Round(NextRandomIntRange(8, 10, RandomState) * Galaxy.GetAsteroidModifier);
  if Constellation.Id = 20 then
    Inc(AsteroidCount, 30);
  for I := 0 to AsteroidCount - 1 do
  begin
    Asteroid := TAsteroid.Create;
    Tries := 10;
    Variant := 0;
    while Tries > 0 do
    begin
      Variant := NextRandomIntRange(0, Variants - 1, RandomState);
      J := 0;
      while J < Asteroids.Count do
      begin
        if ExtractDigitsToIntW(TAsteroid(Asteroids[J]).GraphObject.GraphKey) = Variant then
          Break;
        Inc(J);
      end;
      if J >= Asteroids.Count then
        Break;
      Dec(Tries);
    end;
    if Variant < 10 then
      Asteroid.Init(Self, 'Asteroid.' + Text + '0' + IntToStr(Variant))
    else
      Asteroid.Init(Self, 'Asteroid.' + Text + IntToStr(Variant));
    Asteroids.Add(Asteroid);
    for Variant := 0 to 300 do
      Asteroid.IntegrateMotion(20);
  end;
  PlayerPresenceLevel := 0;
  DaysSincePlayerVisit := 100;
  DaysSinceLastNpcShipSpawn := 100;
  RefreshMapDiameterAndStats;
end;
// CHANGE: CLEANUP - Serialize star state without checking installed DLL signatures.
procedure TStar.SaveToBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Ship: TShip;
  Item: TItem;
  Drop: PMovingDropItemEntry;
  Missile: TMissile;
begin
  Buffer.AddDWord(Id);
  Buffer.AddIntegerValue(GenerationSeed);
  Buffer.AddDWord(RandomState);
  Buffer.AddWideStringZ(Name);
  Buffer.AddSingle(Position.X);
  Buffer.AddSingle(Position.Y);
  Buffer.AddWideChar(WideChar(SystemRadius));
  Buffer.AddAnsiChar(AnsiChar(BackgroundImage));
  Count := Planets.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.SaveToBuffer(Buffer);
  end;
  Count := Asteroids.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.SaveToBuffer(Buffer);
  end;
  Count := Ships.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship is TPlayer then
      Buffer.AddAnsiChar(AnsiChar(255))
    else
      Buffer.AddAnsiChar(AnsiChar(Ship.TypeId));
    Ship.SaveToBuffer(Buffer);
  end;
  Count := Items.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Item := TItem(Items[I]);
    Buffer.AddAnsiChar(AnsiChar(Item.ItemType));
    Item.SaveToBuffer(Buffer);
  end;
  for I := MovingDropItems.Count - 1 downto 0 do
  begin
    Drop := MovingDropItems[I];
    if Drop.Payload = nil then
    begin
      MovingDropItems.Delete(I);
      FreeEC(Drop);
    end;
  end;
  Count := MovingDropItems.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Drop := MovingDropItems[I];
    Buffer.AddSingle(Drop.Destination.X);
    Buffer.AddSingle(Drop.Destination.Y);
    Buffer.AddDWord(Drop.SourceShipId);
    Buffer.AddBoolean(Boolean(Drop.UseFlag));
    Item := Drop.Payload as TItem;
    Buffer.AddAnsiChar(AnsiChar(Item.ItemType));
    Item.SaveToBuffer(Buffer);
  end;
  Count := Missiles.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Missile := TMissile(Missiles[I]);
    Buffer.AddAnsiChar(AnsiChar(Missile.ItemType));
    Missile.SaveToBuffer(Buffer);
  end;
  Buffer.AddDWord(Constellation.Id);
  Buffer.AddWideStringZ(SystemProcessName);
  Buffer.AddBoolean(Boolean(Battle));
  Buffer.AddAnsiChar(AnsiChar(ThreatLevel));

  Buffer.AddAnsiChar(AnsiChar(TrafficLevel));
  Buffer.AddAnsiChar(AnsiChar(ControlFaction));
  Buffer.AddAnsiChar(AnsiChar(PreviousControlFaction));
  Buffer.AddAnsiChar(AnsiChar(DominatorSeries));
  Buffer.AddWideStringZ(Status.CustomFaction);
  Buffer.AddSingle(SafeRadius);
  Buffer.AddSingle(DamageRadius);
  Buffer.AddWideChar(WideChar(Radius));
  Buffer.AddWideStringZ(Graphic.GraphKey);
  Buffer.AddBoolean(PlayerCombatOccurred);
  Buffer.AddAnsiChar(AnsiChar(Flag80));
  Buffer.AddIntegerValue(DaysSincePlayerVisit);
  Buffer.AddIntegerValue(DaysSinceLastNpcShipSpawn);
  Buffer.AddIntegerValue(LastDominatorPresenceTurn);
  Buffer.AddIntegerValue(LastPiratePresenceTurn);
  Buffer.AddIntegerValue(LastLiberationRewardsTurn);
  Buffer.AddIntegerValue(PlayerPresenceLevel);
  Buffer.AddBoolean(NoComeKling);
  if Dominion = nil then
    Buffer.AddDWord(0)
  else
    Buffer.AddDWord(TShip(Dominion).Id);
  Buffer.AddWideStringZ(MapLabel);
  Buffer.AddWideChar(WideChar(CustomSystemInfos.Count));
  for I := 0 to CustomSystemInfos.Count - 1 do
    TCustomSystemInfo(CustomSystemInfos[I]).SaveToBuffer(Buffer);
end;
procedure TStar.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
var
  I, Count: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Ship: TShip;
  Item: TItem;
  ShipType: Byte;
  Drop: PMovingDropItemEntry;
  Definition: TBlockParEC;
  Tag: Byte;
  Missile: TMissile;
  Info: TCustomSystemInfo;
  Stage: Integer;
begin
  Stage := 0;
  try
    Id := Buffer.GetUInt32;
    if Galaxy.NextStarId <= Id then
      Galaxy.NextStarId := Id + 1;
    GenerationSeed := Buffer.GetInt32;
    RandomState := Buffer.GetUInt32;
    if LoadedSaveVersion < 158 then
      Buffer.GetBoolean;
    Name := Buffer.ReadWideString;
    Position.X := Buffer.GetSingle;
    Position.Y := Buffer.GetSingle;
    SystemRadius := Buffer.GetWord;
    BackgroundImage := Buffer.GetByte;
    Stage := 1;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    Stage := 2;
    for I := 0 to Count - 1 do
    begin
      Planet := TPlanet.Create;
      Planet.CurrentStar := Self;
      Planets.Add(Planet);
      Planet.LoadFromBuffer(Buffer, Galaxy);
    end;
    Stage := 3;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    Stage := 4;
    for I := 0 to Count - 1 do
    begin
      Asteroid := TAsteroid.Create;
      Asteroid.CurrentStar := Self;
      Asteroids.Add(Asteroid);
      Asteroid.LoadFromBuffer(Buffer, Galaxy);
    end;
    Stage := 5;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    Stage := 6;
    for I := 0 to Count - 1 do
    begin
      Tag := Buffer.GetByte;
      if Tag = 255 then
        Ship := TPlayer.Create
      else
      begin
        ShipType := Tag;
        Ship := CreateShipByType(ShipType);
      end;
      Ships.Add(Ship);
      Ship.CurrentStar := Self;
      Ship.LoadFromBuffer(Buffer, Galaxy);
    end;
    Stage := 7;
    // CHANGE: FIX - Long campaigns can exceed 10,000 loose items; the save count is a Word.
    Count := Buffer.GetWord;
    Stage := 8;
    for I := 0 to Count - 1 do
    begin
      Item := CreateItemByType(MigrateSavedItemType(Buffer.GetByte));
      Items.Add(Item);
      Item.LoadFromBuffer(Buffer, Galaxy);
    end;
    Stage := 9;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then
      raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      Drop := AllocEC(SizeOf(TMovingDropItemEntry));
      Drop.Destination.X := Buffer.GetSingle;
      Drop.Destination.Y := Buffer.GetSingle;
      Drop.SourceShipId := Buffer.GetUInt32;
      Drop.InsertedIntoStar := False;
      Drop.UseFlag := Byte(Buffer.GetBoolean);
      Item := CreateItemByType(MigrateSavedItemType(Buffer.GetByte));
      Drop.Payload := Item;
      Item.LoadFromBuffer(Buffer, Galaxy);
      MovingDropItems.Add(Drop);
    end;
    Stage := 10;
    Count := Buffer.GetWord;
    if LoadedSaveVersion <= 127 then
    begin
      for I := 0 to Count - 1 do
      begin
        Missile := TMissile.Create;
        Missiles.Add(Missile);
        Missile.LoadFromBuffer(Buffer, Galaxy);
      end;
    end
    else
      for I := 0 to Count - 1 do
      begin
        if MigrateSavedItemType(Buffer.GetByte) = t_CustomWeapon then
          Missile := TCustomMissile.Create
        else
          Missile := TMissile.Create;
        Missiles.Add(Missile);
        Missile.LoadFromBuffer(Buffer, Galaxy);
      end;
    Stage := 11;
    Constellation := TConstellation(Buffer.GetUInt32);
    SystemProcessName := Buffer.ReadWideString;
    if LoadedSaveVersion >= 141 then
      Battle := Byte(Buffer.GetBoolean);
    ThreatLevel := Buffer.GetByte;

    TrafficLevel := Buffer.GetByte;
    ControlFaction := TStarFaction(Buffer.GetByte);
    if LoadedSaveVersion >= 53 then
      PreviousControlFaction := TStarFaction(Buffer.GetByte)
    else
      PreviousControlFaction := ControlFaction;
    DominatorSeries := TDominatorSeries(Buffer.GetByte);
    Stage := 12;
    if LoadedSaveVersion >= 149 then
      Status.CustomFaction := Buffer.ReadWideString
    else
      Status.CustomFaction := '';
    if LoadedSaveVersion = 149 then
      Buffer.GetByte;
    Stage := 13;
    SafeRadius := Buffer.GetSingle;
    DamageRadius := Buffer.GetSingle;
    Radius := Buffer.GetWord;
    Stage := 14;
    if LoadedSaveVersion >= 154 then
      RetainSpaceObject(
          Graphic,
          CreateSpaceObjectByName('Star', Buffer.ReadWideString, Classes.Point(0, 0))
      )
    else
    begin
      Definition := GameDataConfig.GetBlockByPath(Buffer.ReadWideString);
      RetainSpaceObject(
          Graphic,
          CreateSpaceObjectByName('Star', Definition.GetParam('SEGraph'), Classes.Point(0, 0))
      );
    end;
    Graphic.SetPosition(MakePointF(0, 0));
    Stage := 15;
    if LoadedSaveVersion <= 123 then
      Buffer.GetBoolean;
    PlayerCombatOccurred := Buffer.GetBoolean;
    Flag80 := Buffer.GetByte;
    DaysSincePlayerVisit := Buffer.GetInt32;
    DaysSinceLastNpcShipSpawn := Buffer.GetInt32;
    LastDominatorPresenceTurn := Buffer.GetInt32;
    LastPiratePresenceTurn := Buffer.GetInt32;
    LastLiberationRewardsTurn := Buffer.GetInt32;
    PlayerPresenceLevel := Buffer.GetInt32;
    NoComeKling := Buffer.GetBoolean;
    if LoadedSaveVersion >= 105 then
      Dominion := TObject(Buffer.GetUInt32);
    if LoadedSaveVersion >= 111 then
    begin
      MapLabel := Buffer.ReadWideString;
      Count := Buffer.GetWord;
      for I := 0 to Count - 1 do
      begin
        Info := TCustomSystemInfo.Create;
        Info.LoadFromBuffer(Buffer);
        CustomSystemInfos.Add(Info);
      end;
    end;
    RefreshMovementStepParameters;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create('Error in procedure TStar.Load, label = ' + IntToStr(Stage));
    end;
  end;
end;
procedure TStar.ResolveLoadedReferences(Galaxy: TGalaxy);
var
  Planet: TPlanet;
  Ship: TShip;
  Item: TItem;
  I, Count: Integer;
  Drop: PMovingDropItemEntry;
  Missile: TMissile;
begin
  Count := Planets.Count;
  for I := 0 to Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.ResolveLoadedReferences(Galaxy);
  end;
  Count := Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    Ship.ResolveLoadedReferences(Galaxy);
  end;
  Count := Items.Count;
  for I := 0 to Count - 1 do
  begin
    Item := TItem(Items[I]);
    Item.ResolveLoadedReferences(Galaxy);
  end;
  Count := MovingDropItems.Count;
  for I := 0 to Count - 1 do
  begin
    Drop := MovingDropItems[I];
    (Drop.Payload as TItem).ResolveLoadedReferences(Galaxy);
  end;
  Count := Missiles.Count;
  for I := 0 to Count - 1 do
  begin
    Missile := TMissile(Missiles[I]);
    Missile.ResolveLoadedReferences(Galaxy);
  end;
  if Dominion <> nil then
    Dominion := TObject(Galaxy.IdToShip(Cardinal(Dominion), True));
  Constellation := TObject(Galaxy.IdToConstellation(Cardinal(Constellation))) as TConstellation;
end;
procedure TStar.SaveToBlock(Block: TBlockParEC);
var
  I: Integer;
  Key: WideString;
  Planet: TPlanet;
  Ship: TShip;
  Item: TItem;
  ShipBlock: TBlockParEC;
begin
  Block.AddParam('StarName', Name);
  Block.AddParam('ISysDiam', IntToStr(ComputeMapDiameter));
  Block.AddParam('X', SysUtils.FloatToStr(Position.X));
  Block.AddParam('Y', SysUtils.FloatToStr(Position.Y));
  Key := 'Owners';
  case ControlFaction of
    sfCoalition: Block.AddParam(Key, 'Normals');
    sfPirates: Block.AddParam(Key, 'Pirates');
    sfDominators: Block.AddParam(Key, 'Klings');
  end;
  Block.AddParam('DomSeries', DominatorSeriesNames[Ord(DominatorSeries)]);
  ShipBlock := Block.AddBlockByPath('ShipList');
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    Key := 'ShipId' + IntToStr(Cardinal(Ship.Id));
    if GetPlayer <> Ship then
      Ship.SaveToBlock(ShipBlock.AddBlockByPath(Key));
  end;
  ShipBlock.AddParam('CreateNewRuins', '');
  with Block.AddBlockByPath('PlanetList') do
  begin
    for I := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[I]);
      Key := 'PlanetId' + IntToStr(Int64(Planet.Id));
      Planet.SaveToBlock(AddBlockByPath(Key));
    end;
    AddParam('CreateNewPlanet', '0');
  end;
  with Block.AddBlockByPath('Junk') do
  begin
    if Items <> nil then
      for I := 0 to Items.Count - 1 do
      begin
        Item := TItem(Items[I]);
        Key := 'ItemId' + IntToStr(Cardinal(Item.Id));
        with AddBlockByPath(Key) do
        begin
          AddParam('X', SysUtils.FloatToStr(Item.Position.X));
          AddParam('Y', SysUtils.FloatToStr(Item.Position.Y));
        end;
        Item.SaveToBlock(GetBlockByPath(Key));
      end;
    AddParam('CreateNewJunk', '');
  end;
  Block.AddParam('CreateNewAsteroids', '0');
end;
procedure TStar.LoadFromBlock(Block: TBlockParEC);
var
  I: Integer;
  Key, Value: WideString;
  Planet: TPlanet;
  Ship: TShip;
  StationType: Byte;
  X, Y: Single;
  Link: PConstellationStarLink;
  Asteroid: TAsteroid;
  Style: WideString;
  Part, Variants, Variant: Integer;
  Item: TItem;
  ItemType: Byte;
  Angle: Double;
begin
  Name := Block.GetParam('StarName');
  X := ExtractDecimalToSingleW(Block.GetParam('X'));
  Y := ExtractDecimalToSingleW(Block.GetParam('Y'));
  for I := 0 to Constellation.StarLinks.Count - 1 do
  begin
    Link := Constellation.StarLinks[I];
    if (Link.StartPoint.X = Position.X) and (Link.StartPoint.Y = Position.Y) then
    begin
      Link.StartPoint.X := X;
      Link.StartPoint.Y := Y;
    end;
    if (Link.EndPoint.X = Position.X) and (Link.EndPoint.Y = Position.Y) then
    begin
      Link.EndPoint.X := X;
      Link.EndPoint.Y := Y;
    end;
  end;
  Position.X := X;
  Position.Y := Y;
  Key := Block.GetParam('Owners');
  if Key = 'Normals' then
    ControlFaction := sfCoalition
  else if Key = 'Pirates' then
    ControlFaction := sfPirates
  else if Key = 'Klings' then
    ControlFaction := sfDominators;
  Key := Block.GetParam('DomSeries');
  for I := 0 to 2 do
    if Key = DominatorSeriesNames[Byte(I)] then
      DominatorSeries := TDominatorSeries(I);
  with Block.GetBlockByPath('ShipList') do
  begin
    for I := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[I]);
      Key := 'ShipId' + IntToStr(Cardinal(Ship.Id));
      if GetPlayer <> Ship then
        Ship.LoadFromBlock(GetBlockByPath(Key));
    end;
    Key := GetParam('CreateNewRuins');
    for I := 0 to CountDelimitedPartsW(Key, ',') - 1 do
    begin
      Value := ExtractDelimitedPartW(Key, I, ',');
      for StationType := 0 to 13 do
        if ShipTypeNames[StationType].Name = Value then
        begin
          TRuins.Create.Init(TStationType(StationType), Self, '');
          Break;
        end;
    end;
  end;
  with Block.GetBlockByPath('PlanetList') do
  begin
    for I := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[I]);
      Key := 'PlanetId' + IntToStr(Cardinal(Planet.Id));
      Planet.LoadFromBlock(GetBlockByPath(Key));
    end;
    for I := 0 to StrToInt(AnsiString(GetParam('CreateNewPlanet'))) - 1 do
    begin
      Planet := TPlanet.Create;
      Planet.InitGeneratedUninhabited(Self);
      Planets.Add(Planet);
      Galaxy.Planets.Add(Planet);
    end;
  end;
  with Block.GetBlockByPath('Junk') do
  begin
    if Items <> nil then
      for I := 0 to Items.Count - 1 do
      begin
        Item := TItem(Items[I]);
        Key := 'ItemId' + IntToStr(Cardinal(Item.Id));
        with GetBlockByPath(Key) do
        begin
          Item.Position.X := ExtractDecimalToSingleW(GetParam('X'));
          Item.Position.Y := ExtractDecimalToSingleW(GetParam('Y'));
        end;
        Item.LoadFromBlock(GetBlockByPath(Key));
      end;
    Key := GetParam('CreateNewJunk');
    for I := 0 to CountDelimitedPartsW(Key, ',') - 1 do
    begin
      Value := ExtractDelimitedPartW(Key, I, ',');
      for ItemType := Byte(Low(TItemType)) to Byte(High(TItemType)) do
        if ItemTypeNames[ItemType] = Value then
        begin
          if (ItemType in [Ord(t_Food)..Ord(t_Narcotics), Ord(t_ArtefactHull)..Ord(t_Satellite)])
              and (ItemType <> Byte(t_Hull)) then
          begin
            Item := CreateDefaultItemByType(TItemType(ItemType));
            if ItemType = Byte(t_Minerals) then
              TGoods(Item).NaturalFlag := True;
            if Item is TCountableItem then
              TCountableItem(Item).DropFlag := 1;
            if Item <> nil then
              Items.Add(Item);
            Angle := HeadingDegreesToRadians(RandomIntRange(0, 359));
            Item.Position.X := Sin(Angle) * (3 * DamageRadius);
            Item.Position.Y := Cos(Angle) * (3 * DamageRadius);
          end;
          Break;
        end;
    end;
  end;
  Key := 'Asteroid';
  for I := 0 to StrToInt(AnsiString(Block.GetParam('CreateNewAsteroids'))) - 1 do
  begin
    if BackgroundImage < 10 then
      Style :=
          GameDataConfig.GetBlockByPath('Style' + Key).GetParam('0' + IntToStr(BackgroundImage))
    else
      Style := GameDataConfig.GetBlockByPath('Style' + Key).GetParam(IntToStr(BackgroundImage));
    Part := NextRandomIntRange(0, CountDelimitedPartsW(Style, ',') div 2 - 1, RandomState) * 2;
    Variants := ExtractDigitsToIntW(ExtractDelimitedPartW(Style, Part + 1, ','));
    Style := ExtractDelimitedPartW(Style, Part, ',');
    Variant := NextRandomIntRange(0, Variants - 1, RandomState);
    Asteroid := TAsteroid.Create;
    if Variant < 10 then
      Asteroid.Init(Self, Key + '.' + Style + '0' + IntToStr(Variant))
    else
      Asteroid.Init(Self, Key + '.' + Style + IntToStr(Variant));
    Asteroids.Add(Asteroid);
  end;
end;
procedure TStar.PruneWeaponTargetsAfterTurn;
var
  Ship: TShip;
  Weapon: TWeapon;
  I, J, Count: Integer;
begin
  Count := Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Ship := Ships[I];
    for J := 1 to Ship.WeaponCount do
    begin
      Weapon := Ship.Weapons[J];
      if Weapon.Target <> nil then
      begin
        if not Ship.InNormalSpace then
          Weapon.Target := nil
        else if (Weapon.GetWeaponInfo.ShotType in [wstTorpedo..wstRocket])
            and (Weapon.Ammo <= 0) then
          Weapon.Target := nil
        else if Weapon.Target is TItem then
          Weapon.Target := nil
        else if Weapon.Target is TAsteroid then
          Weapon.Target := nil
        else if (Weapon.Target is TMissile)
            and (PointDistanceSquared(Ship.Position, (Weapon.Target as TMissile).Position)
                > Sqr(Ship.GetWeaponActionRange(Weapon))) then
          Weapon.Target := nil
        else if Weapon.Target is TShip then
          if not (Weapon.Target as TShip).InNormalSpace
              or (PointDistanceSquared(Ship.Position, (Weapon.Target as TShip).Position)
                  > Sqr(Ship.GetWeaponActionRange(Weapon))) then
            Weapon.Target := nil;
      end;
    end;
  end;
end;
procedure TStar.MarkConnectedCombatEvents(Events: TList; Target: TObject; Group: Integer);
var
  I, Count: Integer;
  Event: PStarCombatEvent;
begin
  Count := Events.Count;
  for I := 0 to Count - 1 do
  begin
    Event := Events[I];
    if Event.CombatGroup = 0 then
    begin
      if Event.Attacker = Target then
      begin
        Event.CombatGroup := Group;
        MarkConnectedCombatEvents(Events, Event.Target, Group);
      end
      else if Event.Target = Target then
      begin
        Event.CombatGroup := Group;
        MarkConnectedCombatEvents(Events, Event.Attacker, Group);
      end;
    end;
  end;
end;
function TStar.DropMinerals(Quantity: Integer; Position: TPointF; Seed: Cardinal): Integer;
var
  Angle, AngleStep, Radius, Jitter: Single;
  DropCount, DropQuantity, I, MaximumDrops: Integer;
  Goods: TGoods;
  Entry: PMovingDropItemEntry;
begin
  MaximumDrops := 4; { Written but not read in the native body. }
  try
    Result := 0;
    Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, Seed));
    Seed := StepRandomSeed(Seed);
    DropCount := 0;
    while Quantity > 0 do
    begin
      if (Quantity < 10) or (DropCount >= 3) then
        DropQuantity := Quantity
      else
        DropQuantity := Round((SeededRandomUnitFloat(Seed) * 0.2 + 0.55) * Quantity);
      Seed := StepRandomSeed(Seed);
      Dec(Quantity, DropQuantity);
      Goods := TGoods.Create;
      Goods.Init(t_Minerals, DropQuantity);
      Goods.NaturalFlag := True;
      Goods.Position := Position;
      Entry := AllocEC(SizeOf(TMovingDropItemEntry));
      Entry.Payload := Goods;
      Entry.SourceShipId := 0;
      Entry.InsertedIntoStar := False;
      Entry.UseFlag := 0;
      MovingDropItems.Add(Entry);
      Inc(DropCount);
      Inc(Result, Goods.Cost);
    end;
    AngleStep := 3.1415926;
    if DropCount > 1 then
      AngleStep := 6.2831852 / DropCount;
    for I := 0 to DropCount - 1 do
    begin
      Entry := MovingDropItems[MovingDropItems.Count - 1 - I];
      Radius := SeededRandomIntRange(50, 150, Seed);
      if (PlayerStar = Self) and (CurrentStepIndex > SimulationStepCount - 20) then
        Radius := 5;
      Seed := StepRandomSeed(Seed);
      Jitter := SeededRandomUnitFloat(Seed) * 0.3 - 0.15;
      Seed := StepRandomSeed(Seed);
      Entry.Destination.X :=
          (Entry.Payload as TItem).Position.X
              + Sin(SeededRandomUnitFloat(Seed) * (Angle + Jitter)) * Radius;
      Seed := StepRandomSeed(Seed);
      Entry.Destination.Y :=
          (Entry.Payload as TItem).Position.Y
              - Cos(SeededRandomUnitFloat(Seed) * (Angle + Jitter)) * Radius;
      Seed := StepRandomSeed(Seed);
      Angle := Angle + AngleStep;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create('Error in procedure TStar.DropMineral ' + Name);
    end;
  end;
end;
procedure TStar.ProcessPlayerAsteroidKill(
    MineralValue: Integer;
    Position: TPointF;
    AsteroidId: Cardinal
);
var
  I, MessageVariant, Roll: Integer;
  Planet, NearestPlanet: TPlanet;
  BestDistance, Distance: Extended;
  Text: WideString;
begin
  Inc(GetPlayer.AchievementStats.AsteroidsDestroyed);
  TrySetAchievementProgress('ASTEROID', GetPlayer.AchievementStats.AsteroidsDestroyed);
  if ControlFaction <> sfCoalition then
    Exit;
  if Status.CustomFaction <> '' then
    Exit;
  if Battle <> 0 then
    Exit;
  BestDistance := 1e20;
  NearestPlanet := nil;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := Planets[I];
    Distance := PointDistanceSquared(Position, Planet.GetPosition);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      NearestPlanet := Planet;
    end;
  end;
  if NearestPlanet = nil then
    Exit;
  if not (NearestPlanet.OwnerId in TOwnerMask(PlanetOwnerMasks.Coalition)) then
    Exit;
  if NearestPlanet.IsMainPiratePlanet then
    Exit;
  Roll :=
      SeededRandomIntRange(
          1,
          100,
          (Galaxy.GenerationSeed + NearestPlanet.GenerationSeed) * AsteroidId
      );
  if Roll <= 70 then
  begin
    MessageVariant :=
        SeededRandomIntRange(
            1,
            3,
            Galaxy.GenerationSeed + NearestPlanet.GenerationSeed + Cardinal(Galaxy.CurrentTurn)
        );
    SoundManager.PlaySound('Sound.Sell');
    GetPlayer.SetMoney(GetPlayer.Money + MineralValue);
    Text := LocalizedColorText('GalaxyNews.Star.Asteroid.Kill.' + IntToStr(MessageVariant));
    ReplaceTextToken(Text, '<Money>', IntToStr(MineralValue), '<color=255,240,100>');
    NearestPlanet.ChangeRelationToRanger(GetPlayer, 5);
  end
  else
  begin
    Text :=
        LocalizedColorText(
            'GalaxyNews.Star.Asteroid.Kill.' + OwnerInfo[NearestPlanet.OwnerId].InternalName
        );
    NearestPlanet.ChangeRelationToRanger(GetPlayer, -10);
  end;
  ReplaceTextToken(Text, '<Planet>', NearestPlanet.GetFullName(' '), '<color=255,240,100>');
  AddOrUpdatePlayerBubble(0, Galaxy.CurrentTurn, Text, 'AsteroidKill');
end;
procedure TStar.ClearTargetReferences(Target: TObject);
var
  Missile: TMissile;
  Ship: TShip;
  Weapon: TWeapon;
  I, J, Count: Integer;
  Event: PStarCombatEvent;
begin
  try
    if Target = nil then
      Exit;
    Count := Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Ship := Ships[I];
      for J := 1 to Ship.WeaponCount do
      begin
        Weapon := Ship.Weapons[J];
        if (Weapon <> nil) and (Weapon.Target = Target) then
          Weapon.Target := nil;
      end;
    end;
    Count := Missiles.Count;
    for I := 0 to Count - 1 do
    begin
      Missile := Missiles[I];
      Missile.ClearReferencesTo(Target);
    end;
    Count := CombatEvents.Count;
    for I := 0 to Count - 1 do
    begin
      Event := CombatEvents[I];
      if Event.Target = Target then
        Event.Target := nil;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create('Error in procedure TStar.NextDay.DelTarget ' + Name);
    end;
  end;
end;
procedure TStar.ClearShipReferences(Ship: Pointer);
var
  TargetShip, OtherShip: TShip;
  Weapon: TWeapon;
  I, J, Count: Integer;
  Event: PStarCombatEvent;
begin
  try
    if Ship = nil then
      Exit;
    ClearTargetReferences(Ship);
    TargetShip := Ship;
    TargetShip.InterceptorPassesRemaining := 0;
    Count := Ships.Count;
    for I := 0 to Count - 1 do
    begin
      OtherShip := Ships[I];
      if (OtherShip.Order = soLand) and (OtherShip.OrderTarget = TargetShip) then
      begin
        OtherShip.OrderNone(True);
        if RecordingTurnFilm then
          if OtherShip.FilmObject <> nil then
          begin
            OtherShip.FilmAlpha := 255;
            OtherShip.FilmAlphaStep := 0;
          end;
      end;
    end;
    for J := 1 to TargetShip.WeaponCount do
    begin
      Weapon := TargetShip.Weapons[J];
      if Weapon <> nil then
        Weapon.Target := nil;
    end;
    Count := CombatEvents.Count;
    for I := 0 to Count - 1 do
    begin
      Event := CombatEvents[I];
      if Event.Attacker = TargetShip then
        Event.Attacker := nil;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create('Error in procedure TStar.NextDay.DelTargetShip ' + Name);
    end;
  end;
end;
procedure TStar.ClearItemReferences(Item: Pointer);
var
  Ship: TShip;
  I, Count: Integer;
begin
  try
    if Item = nil then
      Exit;
    ClearTargetReferences(Item);
    Count := Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Ship := Ships[I];
      Ship.RemovePickupTarget(Item);
    end;
    for I := ReferencedItems.Count - 1 downto 0 do
      if ReferencedItems[I] = Item then
        ReferencedItems.Delete(I);
    for I := 0 to MovingDropItems.Count - 1 do
      if PMovingDropItemEntry(MovingDropItems[I]).Payload = Item then
        PMovingDropItemEntry(MovingDropItems[I]).Payload := nil;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create('Error in procedure TStar.NextDay.DelTargetItem ' + Name);
    end;
  end;
end;
procedure TStar.ClearCombatEventWeaponReferences(Weapon: Pointer);
var
  I: Integer;
  Entry: PStarCombatEvent;
begin
  for I := 0 to CombatEvents.Count - 1 do
  begin
    Entry := CombatEvents[I];
    if Entry.Weapon = Weapon then
      Entry.Weapon := nil;
  end;
end;
procedure TStar.PrepareNextDay;
var
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Ship: TShip;
  I: Integer;
begin
  if (GetPlayer <> nil) and (GetPlayer.CurrentStar = Self) then
  begin
    DaysSincePlayerVisit := 0;
    if PlayerPresenceLevel < 90 then
      Inc(PlayerPresenceLevel);
  end
  else
  begin
    Inc(DaysSincePlayerVisit);
    if PlayerPresenceLevel > 0 then
      Dec(PlayerPresenceLevel);
  end;
  Inc(DaysSinceLastNpcShipSpawn);
  TryGenerateSystemNews;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.NextDay;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.RespawnIfOutsideSystem;
  end;
  for I := Ships.Count - 1 downto 0 do
  begin
    Ship := TShip(Ships[I]);
    Ship.NextDay;
  end;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Ship.Order = soLand)
        and (Ship.OrderTarget is TShip)
        and ((Ship.OrderTarget as TShip).Order <> soNone) then
    begin
      if (Ship.OrderTarget as TShip).Order <> soTeleport then
        (Ship.OrderTarget as TShip).OrderNone(False)
      else
        Ship.OrderNone(False);
    end
    else if (Ship.Order = soTakeoff)
        and (Ship.DockedTo <> nil)
        and (Ship.DockedTo.Order <> soNone)
        and (Ship.DockedTo.Order <> soTeleport) then
      Ship.DockedTo.OrderNone(False);
  end;
end;
procedure TStar.HandleObjectLeavingStar(Obj: TObject);
var
  I, J, Count: Integer;
  Ship, Target: TShip;
begin
  if Obj is TShip then
    for J := 1 to TShip(Obj).WeaponCount do
      TShip(Obj).Weapons[J].Target := nil;
  Count := Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Ship := Ships[I];
    if not Ship.IsHullDestroyed then
    begin
      if (Ship.Order = soFollowShip) and (Ship.OrderTarget = Obj) then
      begin
        if (Obj is TShip) and (TShip(Obj).Order = soJump) then
        begin
          Target := Obj as TShip;
          if (Ship.TypeId = stKling)
              and (Target.OwnerId in TOwnerMask(PlanetOwnerMasks.Coalition))
              and (Ship.GetHullIntegrityPercent > 30)
              and (Target.GetHullIntegrityPercent > 10)
              and (I > Max(4, Count div 2))
              and (ShipTypeCounts[stKling] > 7)
              and (((Ship as TKling).KlingType in [ktSmersh..ktShtip])
                  or (((Ship as TKling).KlingType in [ktEquentor..ktUrgant])
                      and (I in [5, 6])
                      and (ShipTypeCounts[stKling] > 9)))
              and (GetPlayer <> nil)
              and Target.InHyperspace
              and (Target.OrderTarget is TStar)
              and ((Target.OrderTarget as TStar).ControlFaction = sfCoalition)
              and not IsStarProtectedByScript(Target.OrderTarget as TStar)
              and ((Galaxy.CurrentTurn > 300) or (GetPlayer.CurrentStar <> Target.OrderTarget))
              and (Galaxy.CurrentTurn mod 15 = 0) then
            Ship.OrderJump(Target.OrderTarget as TStar, True)
          else if (Ship.TypeId = stPirate)
              and ((Ship as TPirate).PirateType = 0)
              and (Target.OwnerId in TOwnerMask(PlanetOwnerMasks.Coalition))
              and (Ship.GetHullIntegrityPercent > 90)
              and (Target.GetHullIntegrityPercent > 10)
              and (Ship.ChanceToWin(Target) > 1)
              and (GetPlayer <> nil)
              and Target.InHyperspace
              and (Target.OrderTarget is TStar)
              and ((Target.OrderTarget as TStar).ControlFaction = sfCoalition)
              and ((Target.OrderTarget as TStar).Status.CustomFaction = '')
              and not IsStarProtectedByScript(Target.OrderTarget as TStar)
              and ((Galaxy.CurrentTurn > 300) or (GetPlayer.CurrentStar <> Target.OrderTarget))
              and (Galaxy.CurrentTurn mod 7 = 0) then
            Ship.OrderJump(Target.OrderTarget as TStar, True)
          else
            Ship.OrderNone(False);
        end
        else
          Ship.OrderNone(False);
      end;
      if (Ship.Order = soLand) and (Ship.OrderTarget = Obj) then
        Ship.OrderNone(False);
      if (Ship is TTranclucator) and ((Ship as TTranclucator).OwnerShip = Obj) then
        (Ship as TTranclucator).FollowOwner := False;
      for J := 1 to Ship.WeaponCount do
        if Ship.Weapons[J].Target = Obj then
          Ship.Weapons[J].Target := nil;
      if Ship.DockedTo = Obj then
        HandleObjectLeavingStar(Ship);
    end;
  end;
  if Obj is TShip then
    (Obj as TShip).ClearPickupTargets;
end;
procedure TStar.AvoidShipPathCollisions;
type
  TCollisionEntry = record
    Ship: TShip;
    Position: TPointF;
    DistanceSquared: Single;
  end;
  PCollisionEntry = ^TCollisionEntry;
var
  Ship: TShip;
  Entries: TList;
  Entry, Other: PCollisionEntry;
  I, J, ShipCount, StationaryCount, Count: Integer;
  Node: PSPathNode;
  Collides: Boolean;
  PreviousPosition: TPointF;
begin
  ShipCount := Ships.Count;
  if ShipCount < 1 then
    Exit;
  Entries := TList.Create;
  StationaryCount := 0;
  for I := 0 to ShipCount - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (not (Ship is TKling)
            or ((Ship as TKling).KlingType <> ktBoss)
            or ((Ship as TKling).DominatorSeries <> dsTerron))
        and not Ship.InHyperspace
        and (Ship.Order <> soTakeoff)
        and not Ship.IsTravelCompletionPathReady
        and (Ship.CurrentPlanet = nil)
        and (Ship.DockedTo = nil) then
    begin
      if (not (Ship is TTranclucator)
              or not (Ship as TTranclucator).CanFollowOwnerInCurrentStar
              or (Sqr(Ship.Speed)
                  <= PointDistanceSquared(
                      Ship.Position,
                      (Ship as TTranclucator).OwnerShip.Position)))
          and not (Ship is TRuins)
          and not Ship.OrderAbsolute then
      begin
        Entry := AllocEC(SizeOf(TCollisionEntry));
        Entry.Ship := Ship;
        Entry.DistanceSquared := 0;
        Entry.Position := Ship.Position;
        if Ship.MovementPath.ActiveTail <> nil then
        begin
          Entry.DistanceSquared :=
              PointDistanceSquared(Entry.Position, Ship.MovementPath.ActiveTail.Position);
          Entry.Position := Ship.MovementPath.ActiveTail.Position;
        end
        else
          Inc(StationaryCount);
        J := 0;
        while J < Entries.Count do
        begin
          Other := Entries[J];
          if Other.DistanceSquared > Entry.DistanceSquared then
            Break;
          Inc(J);
        end;
        if J >= Entries.Count then
          Entries.Add(Entry)
        else
          Entries.Insert(J, Entry);
      end;
    end;
  end;
  Count := Entries.Count;
  for I := StationaryCount to Count - 1 do
  begin
    Entry := Entries[I];
    Node := Entry.Ship.MovementPath.ActiveTail;
    while Node <> nil do
    begin
      Collides := False;
      for J := 0 to I - 1 do
      begin
        Other := Entries[J];
        if Node.Prev = nil then
          PreviousPosition := Entry.Ship.Position
        else
          PreviousPosition := Node.Prev.Position;
        if (PointDistanceSquared(Node.Position, Other.Position)
                < Sqr(Entry.Ship.CollisionRadius + Other.Ship.CollisionRadius))
            and (PointDistanceSquared(Node.Position, Other.Position)
                < PointDistanceSquared(PreviousPosition, Other.Position)) then
        begin
          Collides := True;
          Break;
        end;
      end;
      if not Collides then
        Break;
      Node := Node.Prev;
    end;
    if Node = nil then
    begin
      Entry.Position := Entry.Ship.Position;
      Entry.Ship.ClearMovementPath;
    end
    else
    begin
      Entry.Position := Node.Position;
      if Node.Next <> nil then
      begin
        Entry.Ship.MovementPath.RemoveNodeRange(Node.Next, Entry.Ship.MovementPath.ActiveTail);
        Entry.Ship.MovementPath.ResampleBezierRange(
            Entry.Ship.MovementPath.ActiveHead,
            Entry.Ship.MovementPath.ActiveTail,
            200
        );
      end;
    end;
  end;
  Count := Entries.Count;
  for I := 0 to Count - 1 do
    FreeEC(Entries[I]);
  Entries.Free;
end;
procedure TStar.RebuildShipMovementPaths;
var
  I: Integer;
  Ship: TShip;
begin
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship.InNormalSpace then
      Ship.BuildOrderMovementPath(MovementStepCount);
  end;
end;
procedure TStar.OpenSpaceScene(MapPanel: TPanelGI; Minimap: TObjectGI; Screen: TMessageLoopGI);
var
  I, J: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Hole: THole;
  Satellite: TSputnik;
  Ship: TShip;
  Item: TItem;
  Gate: PJumpGateEntry;
  Missile: TMissile;
begin
  if GetPlayer <> nil then
  begin
    SpaceProcess.RadarCenter := GetPlayer.Position;
    SpaceProcess.RadarRange := GetPlayer.GetRadarRange;
    SpaceProcess.ActionRange := GetPlayer.GetRadarRange;
    SpaceProcess.ActionColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
  end
  else
  begin
    SpaceProcess.RadarCenter := MakePointF(0, 0);
    SpaceProcess.RadarRange := 0;
    SpaceProcess.ActionRange := 0;
    SpaceProcess.ActionColor := 0;
  end;
  SpaceProcess.SystemRadius := ComputeMapDiameter div 2;
  SpaceProcess.PopulateAmbientObjects(ComputeMapDiameter div 2, BackgroundImage, GenerationSeed);
  SpaceProcess.OpenSpace(MapPanel, Screen);
  SpaceProcess.Space.MinimapScale := Minimap.ClientSize.X / ComputeMapDiameter;
  SpaceProcess.Space.AlphaShift := 0;
  if GetPlayer <> nil then
    if GetPlayer.IsHealthEffectActive(1) then
      SpaceProcess.Space.AlphaShift := 2;
  SpaceProcess.BindMinimap(Minimap);
  Graphic.AttachToSpace(SpaceProcess.Space);
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.Graphic.Civilized := Planet.OwnerId <> Byte(oiUninhabited);
    Planet.Graphic.SetMinimapOwner(Planet.OwnerId);
    if Planet.CustomFaction <> '' then
    begin
      J := GetCustomFactionPlanetIconNumber(Planet.CustomFaction);
      if J >= 0 then
        Planet.Graphic.SetMinimapOwner(J + 1 + 7);
    end;
    Planet.Graphic.SetSurfaceAnimationMask(Planet.GetSurfaceAnimationMask);
    Planet.Graphic.AttachToSpace(SpaceProcess.Space);
    if SputnikShow then
      for J := 0 to Planet.Satellites.Count - 1 do
      begin
        Satellite := TSputnik(Planet.Satellites[J]);
        Satellite.Graphic.OrbitCenter := Planet.GetPosition;
        Satellite.Graphic.AttachToSpace(SpaceProcess.Space);
      end;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship.InNormalSpace then
    begin
      Ship.Graphic.SetAlpha(255);
      if Ship.Graphic is TShip2SE then
      begin
        with TShip2SE(Ship.Graphic) do
          if (ShipTail = 2) or ((ShipTail = 1) and (GetPlayer = Ship)) then
            SetTailMode(1)
          else
            SetTailMode(0);
      end
      else if (Ship.Graphic is TRuinsSE) and (Ship.Graphic as TRuinsSE).HasTransitionImages then
        (Ship.Graphic as TRuinsSE).SetState(1);
      Ship.Graphic.AttachToSpace(SpaceProcess.Space);
      if Ship.InterceptorGraphic <> nil then
      begin
        Ship.InterceptorGraphic.SetAlpha(255);
        Ship.InterceptorGraphic.AttachToSpace(SpaceProcess.Space);
      end;
    end;
  end;
  for I := 0 to Items.Count - 1 do
  begin
    Item := TItem(Items[I]);
    Item.GetGraphObject.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Galaxy.JumpGates.Count - 1 do
  begin
    Gate := Galaxy.JumpGates[I];
    TGateSE(Gate.Gate).SetState(2);
    Gate.Gate.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Galaxy.Holes.Count - 1 do
  begin
    Hole := THole(Galaxy.Holes[I]);
    if Hole.Star1 = Self then
    begin
      Hole.Graphic.SetPosition(Hole.Position1);
      THoleSE(Hole.Graphic).SetState(0);
      Hole.Graphic.AttachToSpace(SpaceProcess.Space);
    end
    else if Hole.Star2 = Self then
    begin
      Hole.Graphic.SetPosition(Hole.Position2);
      THoleSE(Hole.Graphic).SetState(0);
      Hole.Graphic.AttachToSpace(SpaceProcess.Space);
    end;
  end;
  for I := 0 to Missiles.Count - 1 do
  begin
    Missile := TMissile(Missiles[I]);
    Missile.GetGraphObject.AttachToSpace(SpaceProcess.Space);
  end;
end;
procedure TStar.RefreshSpaceObjectPositions;
var
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Ship: TShip;
  Item: TItem;
  I, J: Integer;
  Satellite: TSputnik;
  Missile: TMissile;
begin
  for I := 1 to Planets.Count do
  begin
    Planet := TPlanet(Planets[I - 1]);
    Planet.Graphic.SetPosition(PolarToPoint(Planet.Orbit));
    for J := 0 to Planet.Satellites.Count - 1 do
    begin
      Satellite := TSputnik(Planet.Satellites[J]);
      Satellite.Graphic.OrbitCenter := Planet.GetPosition;
      Satellite.Graphic.UpdateOrbitDisplay;
    end;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.SetPosition(Asteroid.Position);
  end;
  for I := 1 to Ships.Count do
  begin
    Ship := TShip(Ships[I - 1]);
    Ship.Graphic.SetPosition(Ship.Position);
    Ship.Graphic.SetAngle(HeadingDegreesToByte(Ship.MovementDirection));
  end;
  for I := 1 to Items.Count do
  begin
    Item := TItem(Items[I - 1]);
    Item.GetGraphObject.SetPosition(Item.Position);
  end;
  for I := 0 to Missiles.Count - 1 do
  begin
    Missile := TMissile(Missiles[I]);
    Missile.GetGraphObject.SetPosition(Missile.Position);
    Missile.GetGraphObject.SetAngle(HeadingDegreesToByte(Missile.Direction));
  end;
end;
procedure TStar.QueueSpaceImageLoads(PendingLoads: TList; Owner: TObjectGI);
var
  Planet: TPlanet;
  Ship: TShip;
  Hole: THole;
  Item: TItem;
  I, J: Integer;
  Satellite: TSputnik;
  Asteroid: TAsteroid;
begin
  Graphic.QueueImageLoad(PendingLoads, Owner);
  if (TerronShip <> nil) and (TerronShip.CurrentStar = Self) and AnimStar then
  begin
    with TgaiGI.Create(Owner) do
    begin
      SetImagePath('Bm.Star.Terron_Transform_a');
      QueueImageLoad(PendingLoads);
      Free;
    end;
    with TgaiGI.Create(Owner) do
    begin
      SetImagePath('Bm.Star.TerronAfter_a');
      QueueImageLoad(PendingLoads);
      Free;
    end;
  end;
  for I := 1 to Planets.Count do
  begin
    Planet := TPlanet(Planets[I - 1]);
    Planet.Graphic.QueueImageLoad(PendingLoads, Owner);
    if SputnikShow then
      for J := 0 to Planet.Satellites.Count - 1 do
      begin
        Satellite := TSputnik(Planet.Satellites[J]);
        Satellite.Graphic.QueueImageLoad(PendingLoads, Owner);
      end;
  end;
  for I := 1 to Ships.Count do
  begin
    Ship := TShip(Ships[I - 1]);
    Ship.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 1 to Items.Count do
  begin
    Item := TItem(Items[I - 1]);
    Item.GetGraphObject.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 0 to Galaxy.Holes.Count - 1 do
  begin
    Hole := THole(Galaxy.Holes[I]);
    if (Hole.Star1 = Self) or (Hole.Star2 = Self) then
      Hole.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
end;
procedure TStar.QueueHyperspaceShipImageLoads(PendingLoads: TList; Owner: TObjectGI);
var
  Ship: TShip;
  I: Integer;
begin
  for I := 1 to Ships.Count do
  begin
    Ship := TShip(Ships[I - 1]);
    if Ship.InHyperspace then
      Ship.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
end;
function TStar.GetBackgroundImagePath(out Size: Integer): WideString;
begin
  Size := 2000;
  if BackgroundImage < 10 then
    Result := 'Bm.BGO.bg0' + IntToStr(BackgroundImage)
  else
    Result := 'Bm.BGO.bg' + IntToStr(BackgroundImage);
end;
procedure TStar.ProcessItemScripts(TurnPhase: Integer);
var
  I: Integer;
  Item: TItem;
  Ship: TShip;
  Stage: Integer;
begin
  Stage := 0;
  try
    for I := Ships.Count - 1 downto 0 do
      if Ships.Count > I then
      begin
        Ship := Ships[I];
        Stage := 1;
        if not Ship.IsHullDestroyed and ((GetPlayer = Ship) or (Galaxy.StasisModEnabled <> 1)) then
          Ship.ScriptItemsAct(satOnStep, nil, nil, TurnPhase);
        Stage := 2;
      end;
    Stage := 3;
    if Galaxy.StasisModEnabled = 1 then
      Exit;
    for I := Items.Count - 1 downto 0 do
    begin
      Stage := 4;
      if Items.Count <= I then
        Continue;
      Item := Items[I];
      if Item.DestroyFlag > 0 then
        Continue;
      Stage := 5;
      if Item is TEquipmentWithActCode then
      begin
        RunItemConfigActionCode(Item, satOnStep, nil, Self, nil, TurnPhase);
        if (Items.Count <= I) or (Items[I] <> Item) then
          Continue;
      end;
      Stage := 6;
      if Item.ScriptItem <> nil then
        TScriptItem(Item.ScriptItem).RunActionCode(satOnStep, nil, Self, nil, TurnPhase);
      Stage := 7;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      AppendLogLineThreadSafe(
          'Error in procedure TStar.ScriptShipsAndItemsAct label = ' + IntToStr(Stage)
      );
      raise;
    end;
  end;
end;
function GameTurnToDateTime(Turn: Integer): Double;
begin
  Result := Turn + 511341.5;
end;
function FormatGameTurnDate(Turn: Integer): WideString;
var
  MonthNumber, MonthName: WideString;
begin
  MonthNumber := FormatDateTime('mm', GameTurnToDateTime(Turn - 300));
  MonthName := LocalizedText('Month.' + MonthNumber);
  Result :=
      FormatDateTime('d', GameTurnToDateTime(Turn - 300))
          + ' '
          + MonthName
          + ' '
          + FormatDateTime('yyyy', GameTurnToDateTime(Turn - 300));
end;
function ShouldContinuePlayerTravel: Boolean;
begin
  if GetPlayer = nil then
  begin
    Result := False;
    Exit;
  end;
  if PlayerStar.KeepFilmRunning then
  begin
    Result := True;
    Exit;
  end;
  if not HasShownPlayerTip(18) and (GetPlayer.Order = soJumpHole) then
  begin
    ShowPlayerTipOnce(18);
    Result := False;
    Exit;
  end;
  if PlayerEquipmentBrokenThisTurn then
  begin
    Result := False;
    Exit;
  end;
  if (PendingPlayerFollowTarget <> nil) and (GetPlayer.GetHullIntegrityPercent < 25) then
  begin
    Result := False;
    Exit;
  end;
  if PlayerAutomaticControl
      or ((PendingPlayerFollowTarget <> nil) and not PlayerStar.InterruptLongTravel) then
    Result := True
  else
  begin
    GetPlayer.BuildOrderMovementPath(200);
    if not PlayerStar.PlayerCombatOccurred
        and not PlayerStar.InterruptLongTravel
        and (GetPlayer.GetMovementPathTurnCount > 0)
        and ((GetPlayer.Order <> soMove)
            or (PointDistanceSquared(GetPlayer.Position, GetPlayer.OrderDestination) > 19600)) then
    begin
      if (GetPlayer.Order = soFollowShip)
          and (PointDistanceSquared(GetPlayer.Position, (GetPlayer.OrderTarget as TShip).Position)
              < Sqr(GetPlayer.Speed)) then
      begin
        Result := False;
        Exit;
      end;
      Result := True;
    end
    else
      Result := False;
  end;
end;
function EstimatePlayerTravelTurns: Single;
var
  Destination: TPointF;
begin
  Result := 0;
  if GetPlayer = nil then
    Exit;
  if PlayerStar.PlayerCombatOccurred or PlayerStar.InterruptLongTravel then
    Exit;
  if GetPlayer.PickupTargets <> nil then
    Exit;
  if PendingPlayerFollowTarget <> nil then
    Destination := PendingPlayerFollowTarget.Position
  else if GetPlayer.Order = soMove then
    Destination := GetPlayer.OrderDestination
  else if GetPlayer.Order = soJump then
    Destination := GetPlayer.OrderDestination
  else if (GetPlayer.Order = soJumpHole) and (GetPlayer.OrderStateData <> -65536) then
    Destination := GetPlayer.OrderDestination
  else if GetPlayer.Order = soLand then
  begin
    if GetPlayer.OrderTarget is TShip then
      Destination := TShip(GetPlayer.OrderTarget).Position
    else
      Destination := TPlanet(GetPlayer.OrderTarget).GetPosition;
  end
  else if GetPlayer.Order = soTakeoff then
    Exit
  else if GetPlayer.Order = soFollowShip then
    Destination := TShip(GetPlayer.OrderTarget).Position
  else
    Exit;
  Result := PointDistance(Destination, GetPlayer.Position) / (GetPlayer.Speed + 1);
end;
function GetLocalObjectLink(Obj: TObject; Suppress: Boolean): WideString;
var
  Local: Boolean;
begin
  if Suppress then
  begin
    Result := '';
    Exit;
  end;
  Local := False;
  if not Local and (Obj is TShip) then
    if (Obj as TShip).CurrentStar = GetPlayer.CurrentStar then
      Local := True;
  if not Local and (Obj is TPlanet) then
    if (Obj as TPlanet).CurrentStar = GetPlayer.CurrentStar then
      Local := True;
  if not Local and (Obj is TItem) then
    if GetPlayer.CurrentStar.Items.IndexOf(Obj) >= 0 then
      Local := True;
  if Local then
    // Native $7B28C9 formats the object address as an unsigned decimal value.
    // The dialog's focus button casts it back to TObject, so retain every bit.
    Result := '<Object=' + UIntToStr(PtrUInt(Obj)) + ',23,17,0>'
  else
    Result := '';
end;
function TGalaxy.FindConstellationIndexForStar(Star: TStar): Integer;
var
  I: Integer;
  Constellation: TConstellation;
begin
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.ContainsPoint(Star.Position) then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;
procedure TGalaxy.InitializeConstellationDistanceTiers;
var
  I, J, Pass: Integer;
  Constellation, Other: TConstellation;
  Tier: Byte;
begin
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.SharesOutlineSegment(GetPlayer.HomePlanet.CurrentStar.Constellation) then
      Constellation.HomeDistanceTier := 0
    else
      Constellation.HomeDistanceTier := 3;
  end;
  Tier := 0;
  for Pass := 1 to 2 do
  begin
    for I := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      for J := 0 to Constellations.Count - 1 do
      begin
        Other := TConstellation(Constellations[J]);
        if Other.SharesOutlineSegment(Constellation)
            and (Other.HomeDistanceTier = 3)
            and (Constellation.HomeDistanceTier = Tier) then
          Other.HomeDistanceTier := Tier + 1;
      end;
    end;
    Inc(Tier);
  end;
  if BlazerShip <> nil then
    BlazerShip.CurrentStar.Constellation.HomeDistanceTier := 3;
  if KellerShip <> nil then
    KellerShip.CurrentStar.Constellation.HomeDistanceTier := 3;
  if TerronShip <> nil then
    TerronShip.CurrentStar.Constellation.HomeDistanceTier := 3;
end;
procedure TGalaxy.BuildConstellationOutlineJunctions;
var
  I, J, K: Integer;
  Segment, First, Next: PMapLineSegment;
  Temp: Pointer;
  Point: PPointF;
  Constellation, Other: TConstellation;
  Edges: TList;
  Outer: Boolean;
  TempPoint: TPointF;
  Distance: Single;
begin
  if ConstellationOutlineJunctions <> nil then
  begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do
    begin
      Point := ConstellationOutlineJunctions[I];
      Dispose(Point);
    end;
    ConstellationOutlineJunctions.Clear;
  end
  else
    ConstellationOutlineJunctions := TList.Create;
  Edges := TList.Create;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    for J := 0 to Constellation.OutlineSegments.Count - 1 do
    begin
      Segment := Constellation.OutlineSegments[J];
      Outer := True;
      for K := 0 to Constellations.Count - 1 do
        if K <> I then
        begin
          Other := TConstellation(Constellations[K]);
          if Other.HasOutlineSegment(Segment.StartPoint, Segment.EndPoint) then
          begin
            Outer := False;
            Break;
          end;
        end;
      if Outer then
      begin
        GetMem(Next, SizeOf(TMapLineSegment));
        Next.StartPoint := Segment.StartPoint;
        Next.EndPoint := Segment.EndPoint;
        Edges.Add(Next);
      end;
    end;
  end;
  for I := 0 to Edges.Count - 2 do
  begin
    First := Edges[I];
    J := I + 1;
    while J < Edges.Count do
    begin
      Next := Edges[J];
      if PointsNearlyEqualF(First.EndPoint, Next.StartPoint) then
        Break;
      if PointsNearlyEqualF(First.EndPoint, Next.EndPoint) then
      begin
        TempPoint := Next.StartPoint;
        Next.StartPoint := Next.EndPoint;
        Next.EndPoint := TempPoint;
        Break;
      end;
      Inc(J);
    end;
    if J < Edges.Count then
    begin
      Temp := Edges[I + 1];
      Edges[I + 1] := Edges[J];
      Edges[J] := Temp;
    end;
  end;
  Distance := 0;
  for I := 0 to Edges.Count - 1 do
  begin
    Segment := Edges[I];
    Outer := False;
    K := 0;
    for J := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[J]);
      if Constellation.HasOutlineVertex(Segment.StartPoint) then
      begin
        Inc(K);
        if K > 1 then
        begin
          Outer := True;
          Break;
        end;
      end;
    end;
    if (Distance > 0) or (Outer <> False) then
    begin
      GetMem(Point, SizeOf(TPointF));
      Point^ := Segment.StartPoint;
      ConstellationOutlineJunctions.Add(Point);
      Distance := 0;
    end;
    Distance := PointDistanceF(Segment.StartPoint, Segment.EndPoint) + Distance;
  end;
  for I := 0 to Edges.Count - 1 do
  begin
    Segment := Edges[I];
    Dispose(Segment);
  end;
  Edges.Clear;
  Edges.Free;
end;
function TGalaxy.ShouldKeepConstellationOutlineVertex(Point: TPointF): Boolean;
var
  I, Count: Integer;
  Constellation: TConstellation;
  Vertex: PPointF;
begin
  Count := 0;
  if ConstellationOutlineJunctions = nil then
  begin
    if ScalarsNearlyEqualF(Point.X, 0) then
      Inc(Count);
    if ScalarsNearlyEqualF(Point.Y, 0) then
      Inc(Count);
    if ScalarsNearlyEqualF(Point.X, GalaxySizeY) then
      Inc(Count);
    if ScalarsNearlyEqualF(Point.Y, GalaxySizeY) then
      Inc(Count);
  end
  else
  begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do
    begin
      Vertex := ConstellationOutlineJunctions[I];
      if PointsNearlyEqualF(Vertex^, Point) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.HasOutlineVertex(Point) then
    begin
      Inc(Count);
      if Count > 2 then
        Break;
    end;
  end;
  if Count > 2 then
    Result := True
  else
    Result := False;
end;
procedure TGalaxy.SimplifyConstellationOutline(ConstellationIndex: Integer);
var
  Constellation: TConstellation;
  I: Integer;
  Points: TList;
  Segment: PMapLineSegment;
  First, Last: PPointF;
  Polygon: TPolygon2D;
begin
  Constellation := TConstellation(Constellations[ConstellationIndex]);
  if Constellation <> nil then
  begin
    Points := TList.Create;
    for I := 0 to Constellation.OutlineSegments.Count - 1 do
    begin
      Segment := Constellation.OutlineSegments[I];
      if ShouldKeepConstellationOutlineVertex(Segment.StartPoint) then
      begin
        GetMem(First, SizeOf(TPointF));
        First^ := Segment.StartPoint;
        Points.Add(First);
      end;
    end;
    Constellation.ClearOutlineSegmentsAndBounds;
    for I := 0 to Points.Count - 1 do
    begin
      First := Points[I];
      if I = Points.Count - 1 then
        Last := Points[0]
      else
        Last := Points[I + 1];
      GetMem(Segment, SizeOf(TMapLineSegment));
      Segment.StartPoint := First^;
      Segment.EndPoint := Last^;
      Constellation.OutlineSegments.Add(Segment);
    end;
    Constellation.RefreshOutlineBounds;
    Polygon := nil;
    for I := 0 to Points.Count - 1 do
    begin
      First := Points[I];
      if I = Points.Count - 1 then
        Last := Points[0]
      else
        Last := Points[I + 1];
      if Polygon = nil then
        Polygon := TPolygon2D.CreateTriangle(First^, Last^, Constellation.MapCenter)
      else
        Polygon.Append(TPolygon2D.CreateTriangle(First^, Last^, Constellation.MapCenter));
    end;
    Constellation.SetOutlinePolygon(Polygon);
    for I := 0 to Points.Count - 1 do
      Dispose(PPointF(Points[I]));
    Points.Free;
  end;
end;
function TGalaxy.BuildConstellationStarGraphs: Boolean;
var
  I: Integer;
  Constellation: TConstellation;
begin
  Result := True;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if not Constellation.BuildStarGraph then
      Result := False;
  end;
end;
procedure TGalaxy.BuildConstellationPolygonsAndAdjacency(WorkingPolygon: TPolygon2D);
var
  I, J: Integer;
  Constellation, Other: TConstellation;
  Pass, Steps: Integer;
  Sample: PConstellationBoundaryRaySample;
  PreviousPoint, Point: TPointF;
  Step: Single;
begin
  Step := 3;
  WorkingPolygon.ResetChainGroups;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    WorkingPolygon.AssignGroupAtPoint(Constellation.MapCenter, I);
    Constellation.GenerateBoundaryRaySamples(128);
  end;
  Steps := Trunc(GalaxySizeY / Sqrt(Cardinal(ConstellationCount)) / Step * 0.5) + 1;
  for I := 0 to 7 do
  begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.OutlineGrowthStepsRemaining := Steps + 20;
  end;
  Inc(Steps, 20);
  for I := 8 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.OutlineGrowthStepsRemaining := Steps;
  end;
  Pass := -1;
  repeat
    for I := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      if Cardinal(Constellation.OutlineGrowthStepsRemaining) > 0 then
      begin
        for J := 0 to Constellation.BoundaryRaySamples.Count - 1 do
        begin
          Sample := Constellation.BoundaryRaySamples[J];
          if not Sample.GrowthStopped then
          begin
            PreviousPoint := Sample.Position;
            Point :=
                MakePointF(
                    Step * Sample.Direction.X + PreviousPoint.X,
                    Step * Sample.Direction.Y + PreviousPoint.Y
                );
            if (Point.X < 0)
                or (GalaxySizeX * 1 <= Point.X)
                or (Point.Y < 0)
                or (GalaxySizeY * 1 <= Point.Y) then
              Point := PreviousPoint;
            Sample.Position := Point;
            Sample.GrowthStopped := not WorkingPolygon.AssignGroupAtPoint(Point, I);
          end;
        end;
        Dec(Constellation.OutlineGrowthStepsRemaining);
      end;
    end;
    Inc(Pass);
  until Pass >= Steps;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.SetOutlinePolygon(WorkingPolygon.ExtractFollowingGroup(I));
  end;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    for J := I + 1 to Constellations.Count - 1 do
    begin
      Other := TConstellation(Constellations[J]);
      if Constellation.SharesOutlineSegment(Other) then
      begin
        Constellation.AddAdjacentConstellation(Other);
        Other.AddAdjacentConstellation(Constellation);
      end;
    end;
  end;
end;
procedure TGalaxy.GenerateGalaxyLayout(PlayerRace: Byte);
var
  I, J, UnusedIndex, K, FirstIndex, SecondIndex, N, Attempts: Integer;
  Star, OtherStar, SecondStar: TStar;
  InvalidLayout: Boolean;
  FuelRange, NearestDistance, Distance: Integer;
  Reached: array of Boolean;
  Constellation, OtherConstellation: TConstellation;
  Reserved1, Reserved2: Integer;
  MinimumConstellationDistance, MinimumStarDistance, ConstellationIndex: Integer;
  BoundsSize: TPoint;
  BestAreaPerStar, AreaPerStar: Double;
  WorkingPolygon, Polygon: TPolygon2D;
  Reserved3: Integer;
  Occupied: Boolean;
  MinimumArea, MaximumArea: Single;
  PlacementAttempts, TotalLinks, AxisLinks: Integer;
  Link: PConstellationStarLink;
  Coordinate: Single;
  GenerationAttempts, HumanPosition: Integer;
  // Native unused scalar locals remain explicit; their original purposes are unknown.
  Reserved4A, Reserved4B, Reserved4C: Integer;
  RaceOrder: array[0..7] of Byte;
  CoalitionPositions: array[0..4] of Byte;
  Reserved5_0, Reserved5_1, Reserved5_2, Reserved5_3, Reserved5_4, Reserved5_5: Integer;
  Reserved5_6, Reserved5_7, Reserved5_8, Reserved5_9, Reserved5_10, Reserved5_11: Integer;
  Reserved5_12, Reserved5_13, Reserved5_14, Reserved5_15, Reserved5_16, Reserved5_17: Integer;
  Reserved5_18, Reserved5_19, Reserved5_20, Reserved5_21, Reserved5_22, Reserved5_23: Integer;
  Reserved5_24, Reserved5_25, Reserved5_26, Reserved5_27, Reserved5_28, Reserved5_29: Integer;
  Bounds: TRect;
begin
  System.RandSeed := aGalaxy.Galaxy.GenerationSeed;
  Constellations.Clear;
  for I := 1 to ConstellationCount do
  begin
    Constellation := TConstellation.Create;
    Constellations.Add(Constellation);
  end;
  MinimumConstellationDistance :=
      Round(Sqrt(GalaxySizeY * GalaxySizeY / Cardinal(ConstellationCount)) * 0.75);
  MinimumArea := GalaxySizeX * 0.52 * GalaxySizeY / Cardinal(ConstellationCount);
  MaximumArea := (GalaxySizeX * 1) * 1.5 * (GalaxySizeY * 1) / Cardinal(ConstellationCount);
  GenerationAttempts := 0;
  repeat
    WorkingPolygon := TPolygon2D.Create;
    Polygon := TPolygon2D.Create;
    Polygon.SetRectangle(Classes.Rect(0, 0, GalaxySizeX, GalaxySizeY));
    WorkingPolygon.Append(Polygon);
    Coordinate := 5;
    while Coordinate < GalaxySizeX * 1 do
    begin
      WorkingPolygon
          .SplitChainByPoints(MakePointF(Coordinate, 0), MakePointF(Coordinate, GalaxySizeY));
      Coordinate := Coordinate + 5;
    end;
    Coordinate := 5;
    while Coordinate < GalaxySizeY * 1 do
    begin
      WorkingPolygon
          .SplitChainByPoints(MakePointF(0, Coordinate), MakePointF(GalaxySizeX, Coordinate));
      Coordinate := Coordinate + 5;
    end;
    for I := 0 to 7 do
      RaceOrder[I] := I;
    for K := 1 to NextRandomIntRange(0, 3, aGalaxy.Galaxy.RandomState) do
      for I := 0 to 7 do
      begin
        RaceOrder[I] := DecrementWrappedValue(RaceOrder[I], 0, 7);
        RaceOrder[I] := DecrementWrappedValue(RaceOrder[I], 0, 7);
      end;
    N := 0;
    for I := 0 to 7 do
      if RaceOrder[I] in [0..4] then
      begin
        CoalitionPositions[N] := I;
        Inc(N);
        if RaceOrder[I] = 2 then
          HumanPosition := I;
      end;
    N := 0;
    repeat
      repeat
        I := CoalitionPositions[NextRandomIntRange(0, 4, aGalaxy.Galaxy.RandomState)];
        K := CoalitionPositions[NextRandomIntRange(0, 4, aGalaxy.Galaxy.RandomState)];
      until I <> K;
      Attempts := RaceOrder[I];
      RaceOrder[I] := RaceOrder[K];
      RaceOrder[K] := Attempts;
      Inc(N);
    until (N > 3) and (Byte(PlayerRace + Byte(0)) = RaceOrder[HumanPosition]);
    Constellation := TConstellation(Constellations[RaceOrder[0]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[1]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := RandomIntRange(0, 2) + (GalaxySizeX / 2 - 1);
    Constellation.MapCenter.Y := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[2]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X :=
        RandomIntRange(0, 2) + (GalaxySizeX - MinimumConstellationDistance * 0.6 - 2);
    Constellation.MapCenter.Y := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[3]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X :=
        RandomIntRange(0, 2) + (GalaxySizeX - MinimumConstellationDistance * 0.4 - 2);
    Constellation.MapCenter.Y := RandomIntRange(0, 2) + (GalaxySizeY / 2 - 1);
    Constellation := TConstellation(Constellations[RaceOrder[4]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X :=
        RandomIntRange(0, 2) + (GalaxySizeX - MinimumConstellationDistance * 0.6 - 2);
    Constellation.MapCenter.Y :=
        RandomIntRange(0, 2) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[5]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := RandomIntRange(0, 2) + (GalaxySizeX / 2 - 1);
    Constellation.MapCenter.Y :=
        RandomIntRange(0, 2) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[6]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y :=
        RandomIntRange(0, 2) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[7]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := RandomIntRange(0, 2) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y := RandomIntRange(0, 2) + (GalaxySizeY / 2 - 1);
    for I := 0 to 7 do
      if Integer(RaceOrder[I]) = Integer(PlayerRace) then
        Break;
    OtherConstellation := TConstellation(Constellations[RaceOrder[I]]);
    if OtherConstellation.MapCenter.X < GalaxySizeX * 0.15 then
      K := 1
    else
      K := -1;
    if OtherConstellation.MapCenter.Y < GalaxySizeY * 0.2 then
      Attempts := 1
    else
      Attempts := -1;
    if Attempts = 1 then
      OtherConstellation := TConstellation(Constellations[RaceOrder[1]])
    else
      OtherConstellation := TConstellation(Constellations[RaceOrder[5]]);
    Constellation := TConstellation(Constellations[Constellations.Count - 1]);
    Constellation.MapCenter := OtherConstellation.MapCenter;
    Constellation.MapCenter.X := Constellation.MapCenter.X + 6 * K;
    Constellation.MapCenter.Y := Constellation.MapCenter.Y - 4 * Attempts;
    OtherConstellation.MapCenter.X := OtherConstellation.MapCenter.X - 4 * K;
    for I := 8 to Constellations.Count - 2 do
    begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.ResetGeneratedMapShape;
      Constellation.MapCenter.X := 0;
      Constellation.MapCenter.Y := 0;
      PlacementAttempts := 0;
      while True do
      begin
        Inc(PlacementAttempts);
        if PlacementAttempts > 100 then
          Break;
        Constellation.MapCenter.X := RandomIntRange(0, GalaxySizeX - 1) + 1;
        Constellation.MapCenter.Y := RandomIntRange(0, GalaxySizeY - 1) + 1;
        if (Constellation.MapCenter.X < MinimumConstellationDistance * 0.4)
            or (Constellation.MapCenter.X > GalaxySizeX - MinimumConstellationDistance * 0.4)
            or (Constellation.MapCenter.Y < MinimumConstellationDistance * 0.4)
            or (Constellation.MapCenter.Y > GalaxySizeY - MinimumConstellationDistance * 0.4) then
          Continue;
        Occupied := False;
        for K := 0 to I do
        begin
          if K = I then
            OtherConstellation := TConstellation(Constellations[Constellations.Count - 1])
          else
            OtherConstellation := TConstellation(Constellations[K]);
          if WorkingPolygon.FindContainingPolygon(Constellation.MapCenter)
              = WorkingPolygon.FindContainingPolygon(OtherConstellation.MapCenter) then
          begin
            Occupied := True;
            Break;
          end;
        end;
        if Occupied then
          Continue;
        NearestDistance := Max(GalaxySizeX, GalaxySizeY);
        for K := 0 to I do
        begin
          if K = I then
            OtherConstellation := TConstellation(Constellations[Constellations.Count - 1])
          else
            OtherConstellation := TConstellation(Constellations[K]);
          Distance := Round(PointDistance(Constellation.MapCenter, OtherConstellation.MapCenter));
          if Distance < NearestDistance then
            NearestDistance := Distance;
        end;
        if (NearestDistance >= MinimumConstellationDistance) and (NearestDistance >= 7.0) then
          Break;
      end;
    end;
    BuildConstellationPolygonsAndAdjacency(WorkingPolygon);
    WorkingPolygon.Free;
    InvalidLayout := False;
    for I := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.NormalizeOutlineSegmentOrder;
    end;
    BuildConstellationOutlineJunctions;
    for I := 0 to Constellations.Count - 1 do
      SimplifyConstellationOutline(I);
    TotalLinks := 0;
    AxisLinks := 0;
    for I := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      if (Constellation.OutlinePolygons.GetChainArea < MinimumArea)
          or (Constellation.OutlinePolygons.GetChainArea > MaximumArea) then
      begin
        InvalidLayout := True;
        Break;
      end;
      if Constellation.OutlinePolygons.ChainSelfIntersects then
      begin
        InvalidLayout := True;
        Break;
      end;
      Inc(TotalLinks, Constellation.StarLinks.Count);
      for K := 0 to Constellation.StarLinks.Count - 1 do
      begin
        Link := Constellation.StarLinks[K];
        if (Link.StartPoint.Y = Link.EndPoint.Y) or (Link.StartPoint.X = Link.EndPoint.X) then
          Inc(AxisLinks);
      end;
      for J := I + 1 to Constellations.Count - 1 do
        if Constellation.OutlinePolygons.IntersectsChain(
            TConstellation(Constellations[J]).OutlinePolygons) then
        begin
          InvalidLayout := True;
          Break;
        end;
      if InvalidLayout then
        Break;
    end;
    if AxisLinks * 7 > TotalLinks then
      InvalidLayout := True;
    Inc(GenerationAttempts);
  until (GenerationAttempts > 1000) or not InvalidLayout;
  GenerationAttempts := 0;
  repeat
    for I := 0 to Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.ClearStars;
    end;
    for I := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(aGalaxy.Galaxy.Stars[I]);
      Star.Position.X := 0;
      Star.Position.Y := 0;
    end;
    for I := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(aGalaxy.Galaxy.Stars[I]);
      if (I = 70) or (I = 71) then
        ConstellationIndex := Constellations.Count - 1
      else
      begin
        if I < 65 then
          ConstellationIndex := I mod 18
        else
        begin
          ConstellationIndex := 18;
          if I > 68 then
            ConstellationIndex := I mod (Constellations.Count - 1);
        end;
        if (I > aGalaxy.Galaxy.Stars.Count / 1.46) and (System.Random < 0.6) then
        begin
          BestAreaPerStar := 0;
          for K := 0 to Constellations.Count - 2 do
            if (I < 65) or (K >= 8) then
            begin
              Constellation := TConstellation(Constellations[K]);
              if Constellation.Stars.Count = 0 then
                AreaPerStar := Constellation.GetOutlineArea * 2
              else
                AreaPerStar := Constellation.GetOutlineArea / Constellation.Stars.Count;
              if AreaPerStar > BestAreaPerStar then
              begin
                ConstellationIndex := K;
                BestAreaPerStar := AreaPerStar;
              end;
            end;
        end;
      end;
      Constellation := TConstellation(Constellations[ConstellationIndex]);
      Constellation.AddStar(Star);
      Bounds := Constellation.OutlineBounds;
      BoundsSize := Constellation.OutlineBoundsSize;
      MinimumStarDistance :=
          Round(Sqrt(Constellation.GetOutlineArea / (Stars.Count div Constellations.Count)) * 0.5);
      FuelRange :=
          CalculateGeneratedFuelCapacity(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1);
      Attempts := 0;
      while True do
      begin
        // Separate tests release the conversion temporary between the X/Y bounds.
        while True do
        begin
          Star.Position.X :=
              Bounds.Left + RandomIntRange(0, Round(BoundsSize.X * 1.0) - 1) + BoundsSize.X * 0.0;
          Star.Position.Y :=
              Bounds.Top + RandomIntRange(0, Round(BoundsSize.Y * 1.0) - 1) + BoundsSize.Y * 0.0;
          if Star.Position.X + 0.5 >= 8.0 then
            if Star.Position.X + 0.5 <= GalaxySizeX - 8 then
              if Star.Position.Y + 0.5 >= 5.0 then
                if Star.Position.Y + 0.5 <= GalaxySizeY - 8 then
                  if Constellation.ContainsPoint(Star.Position) then
                    Break;
        end;
        Inc(Attempts);
        if Attempts > 100 then
          Break;
        if Constellation.IsPointNearOutline(Star.Position) then
          Continue;
        NearestDistance := MaxInt;
        for K := 0 to I - 1 do
        begin
          OtherStar := TStar(aGalaxy.Galaxy.Stars[K]);
          Distance := Round(PointDistance(Star.Position, OtherStar.Position));
          if NearestDistance > Distance then
            NearestDistance := Distance;
        end;
        if (NearestDistance >= 4)
            and ((NearestDistance <= FuelRange)
                or (PlayerRace <> ConstellationIndex)
                or (ConstellationCount >= I))
            and ((NearestDistance >= MinimumStarDistance) or (Attempts >= 20)) then
          Break;
      end;
    end;
    InvalidLayout := False;
    SetLength(Reached, aGalaxy.Galaxy.Stars.Count + 1);
    for K := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
      Reached[K] := False;
    Reached[PlayerRace] := True;
    FuelRange :=
        CalculateGeneratedFuelCapacity(Round(FuelTanksBaseSize * EquipmentSizeFactors[5]), 1);
    N := 0;
    for FirstIndex := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
    begin
      OtherStar := TStar(aGalaxy.Galaxy.Stars[FirstIndex]);
      for SecondIndex := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
      begin
        SecondStar := TStar(aGalaxy.Galaxy.Stars[SecondIndex]);
        if (FirstIndex <> SecondIndex)
            and (Abs(OtherStar.Position.X - SecondStar.Position.X) < 7.0)
            and (Abs(OtherStar.Position.Y - SecondStar.Position.Y) < 2.0) then
        begin
          InvalidLayout := True;
          Break;
        end;
        Distance := Round(PointDistance(OtherStar.Position, SecondStar.Position));
        if (Distance <= FuelRange)
            and ((Reached[FirstIndex] and not Reached[SecondIndex])
                or (Reached[SecondIndex] and not Reached[FirstIndex])) then
        begin
          Reached[FirstIndex] := True;
          Reached[SecondIndex] := True;
          Inc(N);
          if N > 2 then
            Break;
        end;
      end;
      if InvalidLayout then
        Break;
    end;
    if N < 3 then
      InvalidLayout := True;
    if not InvalidLayout then
      if not BuildConstellationStarGraphs then
        InvalidLayout := True;
    Inc(GenerationAttempts);
  until (GenerationAttempts > 50) or not InvalidLayout;
  SetLength(Reached, 0);
end;
procedure TGalaxy.HideSpecialConstellation;
var
  I, J, K, SegmentIndex, EarIndex, LastIndex, Reserved20, MiddleIndex: Integer;
  Star: TStar;
  Reserved2C, Reserved30: Integer;
  ReservedFlag, ContainsStar: Boolean;
  Reserved38: Integer;
  Current, Candidate, Hidden: TConstellation;
  Reserved48, Reserved4C, Reserved50, Reserved54, Reserved58, Reserved5C, Reserved60, Reserved64:
      Integer;
  Polygon, SourcePolygon: TPolygon2D;
  Reserved70, Reserved74, Reserved78, Reserved7C, Reserved80, Reserved84: Integer;
  Segment: PMapLineSegment;
  Reserved8C, Reserved90, Reserved94, Reserved98, Reserved9C, ReservedA0: Integer;
  Neighbors, XList, YList, BestX, BestY, WorkX, WorkY: TList;
  AreaAfterUnrestrictedTrim, AreaAfterStarSafeTrim, FullArea: Single;
  BestScore, Score, CrossEar, CrossMid: Double;
  MidX, MidY: Single;
  ReservedF4: Integer;
  AX, BX, CX, AY, BY, CY: Single;
  MaxX, MinX, MaxY, MinY, NewX, NewY, IntersectionX, Determinant: Single;
  Reserved130: Integer;
  Point: PPointF;
  SwapList: Pointer;
  Flag: Byte;
  UnusedLocalBytes: array[0..15] of Byte; // Native gap before backend temporaries.
  function PointInsideTriangle(
      PointX,
      PointY,
      AX,
      AY,
      BX,
      BY,
      CX,
      CY: Single
  ): Boolean; // @addr 0x7B4D48 @ida "bool __usercall $name@<al>(float PointX@<^28>, float PointY@<^24>, float AX@<^20>, float AY@<^16>, float BX@<^12>, float BY@<^8>, float CX@<^4>, float CY@<^0>, void *ParentFrame@<^32>);" @stackpop 0x20 @calls "0x7B5DBF 0x7B6159 0x7B6379 0x7B6717 0x7B6787 0x7B69BD" @note "Strict interior only; excludes edges and degenerate triangles. The caller-popped static link is unused."
  begin
    Result := False;
    if (((BX - AX) * (BY - CY) - (BY - AY) * (BX - CX))
                * ((BX - AX) * (BY - PointY) - (BY - AY) * (BX - PointX))
            > 0)
        and (((CX - BX) * (CY - AY) - (CY - BY) * (CX - AX))
                * ((CX - BX) * (CY - PointY) - (CY - BY) * (CX - PointX))
            > 0)
        and (((AX - CX) * (AY - BY) - (AY - CY) * (AX - BX))
                * ((AX - CX) * (AY - PointY) - (AY - CY) * (AX - PointX))
            > 0) then
      Result := True;
  end;
begin
  // Delphi's Pointer/Single hard casts preserve bits, including signed zero.
  // The temporary coordinate lists intentionally store those bits in pointer slots.
  Neighbors := TList.Create;
  XList := TList.Create;
  YList := TList.Create;
  BestX := nil;
  BestY := nil;
  Hidden := aGalaxy.Galaxy.IdToConstellation(20);
  for I := 0 to Constellations.Count - 1 do
  begin
    Current := TConstellation(Constellations[I]);
    if Current <> Hidden then
      for SegmentIndex := 0 to Hidden.OutlineSegments.Count - 1 do
        if Current.HasOutlineSegment(
            PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint,
            PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint) then
        begin
          Neighbors.Add(Current);
          Break;
        end;
  end;
  BestScore := -1;
  Candidate := nil;
  for I := 0 to Neighbors.Count - 1 do
  begin
    Current := Neighbors[I];
    XList.Clear;
    YList.Clear;
    for SegmentIndex := 0 to Hidden.OutlineSegments.Count - 1 do
      if Current.HasOutlineSegment(
          PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint,
          PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint) then
      begin
        XList.Add(
            SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.X)
        );
        YList.Add(
            SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.Y)
        );
        XList
            .Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.X));
        YList
            .Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.Y));
      end;
    MaxX := PointerToSingle(XList[0]);
    MinX := PointerToSingle(XList[0]);
    MaxY := PointerToSingle(YList[0]);
    MinY := PointerToSingle(YList[0]);
    for SegmentIndex := 1 to XList.Count - 1 do
    begin
      MaxX := Max(MaxX, PointerToSingle(XList[SegmentIndex]));
      MinX := Min(MinX, PointerToSingle(XList[SegmentIndex]));
      MaxY := Max(MaxY, PointerToSingle(YList[SegmentIndex]));
      MinY := Min(MinY, PointerToSingle(YList[SegmentIndex]));
    end;
    MidX := (MaxX + MinX) * 0.5;
    MidY := (MaxY + MinY) * 0.5;
    XList.Clear;
    YList.Clear;
    SegmentIndex := 0;
    while Current.HasOutlineSegment(
        PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint,
        PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint) do
      Inc(SegmentIndex);
    XList.Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.X));
    YList.Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.Y));
    XList.Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.X));
    YList.Add(SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.Y));
    while True do
    begin
      MiddleIndex := XList.Count;
      for SegmentIndex := 0 to Hidden.OutlineSegments.Count - 1 do
        if not Current.HasOutlineSegment(
            PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint,
            PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint) then
        begin
          if ((PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.X
                      = PointerToSingle(XList[XList.Count - 1]))
                  and (PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.Y
                      = PointerToSingle(YList[XList.Count - 1])))
              and not ((PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.X
                      = PointerToSingle(XList[XList.Count - 2]))
                  and (PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.Y
                      = PointerToSingle(YList[XList.Count - 2]))) then
          begin
            XList.Add(
                SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.X)
            );
            YList.Add(
                SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.Y)
            );
          end
          else if ((PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.X
                      = PointerToSingle(XList[XList.Count - 1]))
                  and (PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).EndPoint.Y
                      = PointerToSingle(YList[XList.Count - 1])))
              and not ((PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.X
                      = PointerToSingle(XList[XList.Count - 2]))
                  and (PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.Y
                      = PointerToSingle(YList[XList.Count - 2]))) then
          begin
            XList.Add(
                SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.X)
            );
            YList.Add(
                SingleToPointer(PMapLineSegment(Hidden.OutlineSegments[SegmentIndex]).StartPoint.Y)
            );
          end;
          if (XList[XList.Count - 1] = XList[0]) and (YList[YList.Count - 1] = YList[0]) then
            Break;
        end;
      if (XList[XList.Count - 1] = XList[0]) and (YList[YList.Count - 1] = YList[0]) then
      begin
        XList.Delete(XList.Count - 1);
        YList.Delete(YList.Count - 1);
        Break;
      end;
      for SegmentIndex := 0 to Current.OutlineSegments.Count - 1 do
        if not Hidden.HasOutlineSegment(
            PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint,
            PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint) then
        begin
          if ((PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.X
                      = PointerToSingle(XList[XList.Count - 1]))
                  and (PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.Y
                      = PointerToSingle(YList[XList.Count - 1])))
              and not ((PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.X
                      = PointerToSingle(XList[XList.Count - 2]))
                  and (PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.Y
                      = PointerToSingle(YList[XList.Count - 2]))) then
          begin
            XList.Add(
                SingleToPointer(PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.X)
            );
            YList.Add(
                SingleToPointer(PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.Y)
            );
          end
          else if ((PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.X
                      = PointerToSingle(XList[XList.Count - 1]))
                  and (PMapLineSegment(Current.OutlineSegments[SegmentIndex]).EndPoint.Y
                      = PointerToSingle(YList[XList.Count - 1])))
              and not ((PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.X
                      = PointerToSingle(XList[XList.Count - 2]))
                  and (PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.Y
                      = PointerToSingle(YList[XList.Count - 2]))) then
          begin
            XList.Add(
                SingleToPointer(PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.X)
            );
            YList.Add(
                SingleToPointer(PMapLineSegment(Current.OutlineSegments[SegmentIndex]).StartPoint.Y)
            );
          end;
          if (XList[XList.Count - 1] = XList[0]) and (YList[YList.Count - 1] = YList[0]) then
            Break;
        end;
      if (XList[XList.Count - 1] = XList[0]) and (YList[YList.Count - 1] = YList[0]) then
      begin
        XList.Delete(XList.Count - 1);
        YList.Delete(YList.Count - 1);
        Break;
      end;
      if XList.Count = MiddleIndex then
        Break;
    end;
    Score := 0;
    WorkX := TList.Create;
    WorkY := TList.Create;
    for EarIndex := 0 to XList.Count - 1 do
    begin
      WorkX.Add(XList[EarIndex]);
      WorkY.Add(YList[EarIndex]);
    end;
    FullArea := 0;
    while WorkX.Count > 2 do
      for EarIndex := 0 to WorkX.Count - 1 do
      begin
        LastIndex := EarIndex + 2;
        MiddleIndex := EarIndex + 1;
        if LastIndex >= WorkX.Count then
          Dec(LastIndex, WorkX.Count);
        if MiddleIndex >= WorkX.Count then
          Dec(MiddleIndex, WorkX.Count);
        AX := PointerToSingle(WorkX[EarIndex]);
        BX := PointerToSingle(WorkX[LastIndex]);
        CX := PointerToSingle(WorkX[MiddleIndex]);
        AY := PointerToSingle(WorkY[EarIndex]);
        BY := PointerToSingle(WorkY[LastIndex]);
        CY := PointerToSingle(WorkY[MiddleIndex]);
        Flag := 0;
        for J := 0 to WorkX.Count - 1 do
          if (J <> EarIndex) and (J <> LastIndex) and (J <> MiddleIndex) then
          begin
            if PointInsideTriangle(
                PointerToSingle(WorkX[J]),
                PointerToSingle(WorkY[J]),
                AX,
                AY,
                BX,
                BY,
                CX,
                CY) then
              Flag := 1;
            if Flag = 1 then
              Break;
          end;
        if Flag = 1 then
          Continue;
        CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
        CrossMid := (BX - AX) * (BY - MidY) - (BY - AY) * (BX - MidX);
        if (CrossEar * CrossMid <= 0) or (WorkX.Count = 3) then
        begin
          FullArea := FullArea + Abs(CrossEar * 0.5);
          WorkX.Delete(MiddleIndex);
          WorkY.Delete(MiddleIndex);
          Break;
        end;
      end;
    WorkX.Clear;
    WorkY.Clear;
    for EarIndex := 0 to XList.Count - 1 do
    begin
      WorkX.Add(XList[EarIndex]);
      WorkY.Add(YList[EarIndex]);
    end;
    AreaAfterUnrestrictedTrim := 0;
    while WorkX.Count > 2 do
    begin
      Flag := 0;
      for EarIndex := 0 to WorkX.Count - 1 do
      begin
        LastIndex := EarIndex + 2;
        MiddleIndex := EarIndex + 1;
        if LastIndex >= WorkX.Count then
          Dec(LastIndex, WorkX.Count);
        if MiddleIndex >= WorkX.Count then
          Dec(MiddleIndex, WorkX.Count);
        AX := PointerToSingle(WorkX[EarIndex]);
        BX := PointerToSingle(WorkX[LastIndex]);
        CX := PointerToSingle(WorkX[MiddleIndex]);
        AY := PointerToSingle(WorkY[EarIndex]);
        BY := PointerToSingle(WorkY[LastIndex]);
        CY := PointerToSingle(WorkY[MiddleIndex]);
        CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
        CrossMid := (BX - AX) * (BY - MidY) - (BY - AY) * (BX - MidX);
        if (CrossEar * CrossMid >= 0)
            and not PointInsideTriangle(MidX, MidY, AX, AY, BX, BY, CX, CY) then
        begin
          WorkX.Delete(MiddleIndex);
          WorkY.Delete(MiddleIndex);
          Flag := 1;
          Break;
        end;
      end;
      if Flag <> 0 then
        Break;
    end;
    while WorkX.Count > 2 do
      for EarIndex := 0 to WorkX.Count - 1 do
      begin
        LastIndex := EarIndex + 2;
        MiddleIndex := EarIndex + 1;
        if LastIndex >= WorkX.Count then
          Dec(LastIndex, WorkX.Count);
        if MiddleIndex >= WorkX.Count then
          Dec(MiddleIndex, WorkX.Count);
        AX := PointerToSingle(WorkX[EarIndex]);
        BX := PointerToSingle(WorkX[LastIndex]);
        CX := PointerToSingle(WorkX[MiddleIndex]);
        AY := PointerToSingle(WorkY[EarIndex]);
        BY := PointerToSingle(WorkY[LastIndex]);
        CY := PointerToSingle(WorkY[MiddleIndex]);
        Flag := 0;
        for J := 0 to WorkX.Count - 1 do
          if (J <> EarIndex) and (J <> LastIndex) and (J <> MiddleIndex) then
          begin
            if PointInsideTriangle(
                PointerToSingle(WorkX[J]),
                PointerToSingle(WorkY[J]),
                AX,
                AY,
                BX,
                BY,
                CX,
                CY) then
              Flag := 1;
            if Flag = 1 then
              Break;
          end;
        if Flag = 1 then
          Continue;
        CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
        CrossMid := (BX - AX) * (BY - MidY) - (BY - AY) * (BX - MidX);
        if (CrossEar * CrossMid <= 0) or (WorkX.Count = 3) then
        begin
          AreaAfterUnrestrictedTrim := AreaAfterUnrestrictedTrim + Abs(CrossEar * 0.5);
          WorkX.Delete(MiddleIndex);
          WorkY.Delete(MiddleIndex);
          Break;
        end;
      end;
    WorkX.Clear;
    WorkY.Clear;
    for EarIndex := 0 to XList.Count - 1 do
    begin
      WorkX.Add(XList[EarIndex]);
      WorkY.Add(YList[EarIndex]);
    end;
    AreaAfterStarSafeTrim := 0;
    while WorkX.Count > 2 do
    begin
      Flag := 0;
      for EarIndex := 0 to WorkX.Count - 1 do
      begin
        LastIndex := EarIndex + 2;
        MiddleIndex := EarIndex + 1;
        if LastIndex >= WorkX.Count then
          Dec(LastIndex, WorkX.Count);
        if MiddleIndex >= WorkX.Count then
          Dec(MiddleIndex, WorkX.Count);
        AX := PointerToSingle(WorkX[EarIndex]);
        BX := PointerToSingle(WorkX[LastIndex]);
        CX := PointerToSingle(WorkX[MiddleIndex]);
        AY := PointerToSingle(WorkY[EarIndex]);
        BY := PointerToSingle(WorkY[LastIndex]);
        CY := PointerToSingle(WorkY[MiddleIndex]);
        CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
        CrossMid := (BX - AX) * (BY - MidY) - (BY - AY) * (BX - MidX);
        if (CrossEar * CrossMid >= 0)
            and not PointInsideTriangle(MidX, MidY, AX, AY, BX, BY, CX, CY) then
        begin
          ContainsStar := False;
          for J := 0 to Stars.Count - 1 do
          begin
            Star := TStar(Stars[J]);
            ContainsStar :=
                PointInsideTriangle(Star.Position.X, Star.Position.Y, AX, AY, BX, BY, CX, CY);
            if ContainsStar then
              Break;
          end;
          if ContainsStar then
            Continue;
          WorkX.Delete(MiddleIndex);
          WorkY.Delete(MiddleIndex);
          Flag := 1;
          Break;
        end;
      end;
      if Flag <> 0 then
        Break;
    end;
    while WorkX.Count > 2 do
      for EarIndex := 0 to WorkX.Count - 1 do
      begin
        LastIndex := EarIndex + 2;
        MiddleIndex := EarIndex + 1;
        if LastIndex >= WorkX.Count then
          Dec(LastIndex, WorkX.Count);
        if MiddleIndex >= WorkX.Count then
          Dec(MiddleIndex, WorkX.Count);
        AX := PointerToSingle(WorkX[EarIndex]);
        BX := PointerToSingle(WorkX[LastIndex]);
        CX := PointerToSingle(WorkX[MiddleIndex]);
        AY := PointerToSingle(WorkY[EarIndex]);
        BY := PointerToSingle(WorkY[LastIndex]);
        CY := PointerToSingle(WorkY[MiddleIndex]);
        Flag := 0;
        for J := 0 to WorkX.Count - 1 do
          if (J <> EarIndex) and (J <> LastIndex) and (J <> MiddleIndex) then
          begin
            if PointInsideTriangle(
                PointerToSingle(WorkX[J]),
                PointerToSingle(WorkY[J]),
                AX,
                AY,
                BX,
                BY,
                CX,
                CY) then
              Flag := 1;
            if Flag = 1 then
              Break;
          end;
        if Flag = 1 then
          Continue;
        CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
        CrossMid := (BX - AX) * (BY - MidY) - (BY - AY) * (BX - MidX);
        if (CrossEar * CrossMid <= 0) or (WorkX.Count = 3) then
        begin
          AreaAfterStarSafeTrim := AreaAfterStarSafeTrim + Abs(CrossEar * 0.5);
          WorkX.Delete(MiddleIndex);
          WorkY.Delete(MiddleIndex);
          Break;
        end;
      end;
    WorkX.Clear;
    WorkY.Clear;
    WorkX.Free;
    WorkY.Free;
    Score :=
        ((AreaAfterUnrestrictedTrim - AreaAfterStarSafeTrim) * 0.5
                + (AreaAfterStarSafeTrim - FullArea))
            / FullArea;
    if (Score < BestScore) or (BestScore < 0) then
    begin
      BestScore := Score;
      Candidate := Current;
      if BestX <> nil then
        BestX.Free;
      if BestY <> nil then
        BestY.Free;
      BestX := XList;
      BestY := YList;
      XList := TList.Create;
      YList := TList.Create;
    end;
  end;
  Current := Candidate;
  for EarIndex := 0 to BestX.Count - 1 do
  begin
    LastIndex := EarIndex + 2;
    MiddleIndex := EarIndex + 1;
    if LastIndex >= BestX.Count then
      Dec(LastIndex, BestX.Count);
    if MiddleIndex >= BestX.Count then
      Dec(MiddleIndex, BestX.Count);
    AX := PointerToSingle(BestX[EarIndex]);
    BX := PointerToSingle(BestX[LastIndex]);
    CX := PointerToSingle(BestX[MiddleIndex]);
    AY := PointerToSingle(BestY[EarIndex]);
    BY := PointerToSingle(BestY[LastIndex]);
    CY := PointerToSingle(BestY[MiddleIndex]);
    CrossEar := (BX - AX) * (BY - CY) - (BY - AY) * (BX - CX);
    if CrossEar <> 0 then
      for I := 0 to Constellations.Count - 1 do
      begin
        ContainsStar := False;
        Candidate := TConstellation(Constellations[I]);
        if (Candidate <> Current)
            and (Candidate <> Hidden)
            and Candidate.HasOutlineVertex(MakePointF(AX, AY))
            and Candidate.HasOutlineVertex(MakePointF(BX, BY))
            and Candidate.HasOutlineVertex(MakePointF(CX, CY)) then
        begin
          for J := 0 to Stars.Count - 1 do
          begin
            Star := TStar(Stars[J]);
            if (((BX - AX) * (BY - CY) - (BY - AY) * (BX - CX))
                        * ((BX - AX) * (BY - Star.Position.Y) - (BY - AY) * (BX - Star.Position.X))
                    >= 0)
                and (((CX - BX) * (CY - AY) - (CY - BY) * (CX - AX))
                        * ((CX - BX) * (CY - Star.Position.Y) - (CY - BY) * (CX - Star.Position.X))
                    >= 0)
                and (((AX - CX) * (AY - BY) - (AY - CY) * (AX - BX))
                        * ((AX - CX) * (AY - Star.Position.Y) - (AY - CY) * (AX - Star.Position.X))
                    >= 0) then
              ContainsStar := True;
          end;
          if ContainsStar then
            Continue;
          NewX := AX - (BY - CY);
          NewY := AY + (BX - CX);
          for J := 0 to Hidden.OutlineSegments.Count - 1 do
          begin
            if (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.X = AX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.Y = AY) then
              Continue;
            if (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.X = BX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.Y = BY) then
              Continue;
            if (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.X = AX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.Y = AY) then
              Continue;
            if (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.X = BX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.Y = BY) then
              Continue;
            if (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.X = CX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.Y = CY) then
            begin
              NewX := PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.X;
              NewY := PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.Y;
              Break;
            end;
            if (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.X = CX)
                and (PMapLineSegment(Hidden.OutlineSegments[J]).EndPoint.Y = CY) then
            begin
              NewX := PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.X;
              NewY := PMapLineSegment(Hidden.OutlineSegments[J]).StartPoint.Y;
              Break;
            end;
          end;
          Determinant := (BY - AY) * (CX - NewX) - (CY - NewY) * (BX - AX);
          if Determinant * Determinant > 0.01 then
          begin
            IntersectionX :=
                (-BX * AY * CX
                        + BX * AY * NewX
                        - AX * BY * NewX
                        - AX * CX * NewY
                        + AX * NewX * CY
                        + BX * CX * NewY
                        - BX * NewX * CY
                        + AX * BY * CX)
                    / Determinant;
            NewY :=
                (NewY * BX * AY
                        - CY * BX * AY
                        - AY * CX * NewY
                        + AY * NewX * CY
                        + CY * AX * BY
                        + BY * CX * NewY
                        - BY * NewX * CY
                        - NewY * AX * BY)
                    / Determinant;
            NewX := IntersectionX;
          end
          else
          begin
            NewX := (AX + BX) * 0.5;
            NewY := (AY + BY) * 0.5;
          end;
          repeat
            for J := 0 to Candidate.OutlineSegments.Count - 1 do
            begin
              if (PMapLineSegment(Candidate.OutlineSegments[J]).StartPoint.X = CX)
                  and (PMapLineSegment(Candidate.OutlineSegments[J]).StartPoint.Y = CY) then
              begin
                PMapLineSegment(Candidate.OutlineSegments[J]).StartPoint.X := NewX;
                PMapLineSegment(Candidate.OutlineSegments[J]).StartPoint.Y := NewY;
              end;
              if (PMapLineSegment(Candidate.OutlineSegments[J]).EndPoint.X = CX)
                  and (PMapLineSegment(Candidate.OutlineSegments[J]).EndPoint.Y = CY) then
              begin
                PMapLineSegment(Candidate.OutlineSegments[J]).EndPoint.X := NewX;
                PMapLineSegment(Candidate.OutlineSegments[J]).EndPoint.Y := NewY;
              end;
            end;
            Polygon := nil;
            for J := 0 to Candidate.OutlinePolygons.CountChain - 1 do
            begin
              if J = 0 then
                Polygon := Candidate.OutlinePolygons
              else
                Polygon := Polygon.Next;
              for K := 0 to Polygon.Points.Count - 1 do
                if (PPointF(Polygon.Points[K]).X = CX) and (PPointF(Polygon.Points[K]).Y = CY) then
                begin
                  PPointF(Polygon.Points[K]).X := NewX;
                  PPointF(Polygon.Points[K]).Y := NewY;
                end;
            end;
            if Candidate = Hidden then
              Candidate := nil
            else if Candidate = Current then
              Candidate := Hidden
            else
              Candidate := Current;
          until Candidate = nil;
          CX := NewX;
          CY := NewY;
          BestX[MiddleIndex] := SingleToPointer(CX);
          BestY[MiddleIndex] := SingleToPointer(CY);
        end;
      end;
  end;
  Neighbors.Clear;
  XList.Clear;
  YList.Clear;
  BestX.Clear;
  BestY.Clear;
  for I := Hidden.OutlineSegments.Count - 1 downto 0 do
  begin
    GetMem(Segment, SizeOf(TMapLineSegment));
    Segment.StartPoint.X := PMapLineSegment(Hidden.OutlineSegments[I]).StartPoint.X;
    Segment.StartPoint.Y := PMapLineSegment(Hidden.OutlineSegments[I]).StartPoint.Y;
    Segment.EndPoint.X := PMapLineSegment(Hidden.OutlineSegments[I]).EndPoint.X;
    Segment.EndPoint.Y := PMapLineSegment(Hidden.OutlineSegments[I]).EndPoint.Y;
    Hidden.HiddenOutlineSegmentsBackup.Add(Segment);
  end;
  for I := Current.OutlineSegments.Count - 1 downto 0 do
  begin
    GetMem(Segment, SizeOf(TMapLineSegment));
    Segment.StartPoint.X := PMapLineSegment(Current.OutlineSegments[I]).StartPoint.X;
    Segment.StartPoint.Y := PMapLineSegment(Current.OutlineSegments[I]).StartPoint.Y;
    Segment.EndPoint.X := PMapLineSegment(Current.OutlineSegments[I]).EndPoint.X;
    Segment.EndPoint.Y := PMapLineSegment(Current.OutlineSegments[I]).EndPoint.Y;
    Current.HiddenOutlineSegmentsBackup.Add(Segment);
  end;
  for I := Hidden.OutlineSegments.Count - 1 downto 0 do
    if Current.HasOutlineSegment(
        PMapLineSegment(Hidden.OutlineSegments[I]).StartPoint,
        PMapLineSegment(Hidden.OutlineSegments[I]).EndPoint) then
    begin
      EarIndex := I;
      Dispose(PMapLineSegment(Hidden.OutlineSegments[EarIndex]));
      Hidden.OutlineSegments.Delete(EarIndex);
    end;
  SwapList := Hidden.HiddenOutlineSegmentsBackup;
  Hidden.HiddenOutlineSegmentsBackup := Hidden.OutlineSegments;
  Hidden.OutlineSegments := SwapList;
  for I := Current.OutlineSegments.Count - 1 downto 0 do
    if Hidden.HasOutlineSegment(
        PMapLineSegment(Current.OutlineSegments[I]).StartPoint,
        PMapLineSegment(Current.OutlineSegments[I]).EndPoint) then
    begin
      LastIndex := I;
      Dispose(PMapLineSegment(Current.OutlineSegments[LastIndex]));
      Current.OutlineSegments.Delete(LastIndex);
    end;
  SwapList := Hidden.HiddenOutlineSegmentsBackup;
  Hidden.HiddenOutlineSegmentsBackup := Hidden.OutlineSegments;
  Hidden.OutlineSegments := SwapList;
  SwapList := nil;
  while Current.OutlineSegments.Count > 0 do
  begin
    XList.Add(Current.OutlineSegments[0]);
    Current.OutlineSegments.Delete(0);
  end;
  while Hidden.OutlineSegments.Count > 0 do
  begin
    XList.Add(Hidden.OutlineSegments[0]);
    Hidden.OutlineSegments.Delete(0);
  end;
  Current.OutlineSegments.Add(XList[0]);
  XList.Delete(0);
  MiddleIndex := 0;
  for SegmentIndex := XList.Count - 1 downto 0 do
    if (PMapLineSegment(XList[SegmentIndex]).StartPoint.X
            = PMapLineSegment(XList[SegmentIndex]).EndPoint.X)
        and (PMapLineSegment(XList[SegmentIndex]).StartPoint.Y
            = PMapLineSegment(XList[SegmentIndex]).EndPoint.Y) then
    begin
      Dispose(PMapLineSegment(XList[SegmentIndex]));
      XList.Delete(SegmentIndex);
    end;
  while XList.Count > 0 do
    for SegmentIndex := XList.Count - 1 downto 0 do
    begin
      if ((PMapLineSegment(XList[SegmentIndex]).StartPoint.X
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).StartPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).StartPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).StartPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).StartPoint.X
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).EndPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).StartPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).EndPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).EndPoint.X
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).StartPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).EndPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).StartPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).EndPoint.X
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).EndPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).EndPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[MiddleIndex]).EndPoint.Y)) then
      begin
        Current.OutlineSegments.Add(XList[SegmentIndex]);
        XList.Delete(SegmentIndex);
        Inc(MiddleIndex);
      end
      else if ((PMapLineSegment(XList[SegmentIndex]).StartPoint.X
                  = PMapLineSegment(Current.OutlineSegments[0]).StartPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).StartPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[0]).StartPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).StartPoint.X
                  = PMapLineSegment(Current.OutlineSegments[0]).EndPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).StartPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[0]).EndPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).EndPoint.X
                  = PMapLineSegment(Current.OutlineSegments[0]).StartPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).EndPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[0]).StartPoint.Y))
          or ((PMapLineSegment(XList[SegmentIndex]).EndPoint.X
                  = PMapLineSegment(Current.OutlineSegments[0]).EndPoint.X)
              and (PMapLineSegment(XList[SegmentIndex]).EndPoint.Y
                  = PMapLineSegment(Current.OutlineSegments[0]).EndPoint.Y)) then
      begin
        Current.OutlineSegments.Insert(0, XList[SegmentIndex]);
        XList.Delete(SegmentIndex);
        Inc(MiddleIndex);
      end;
    end;
  SourcePolygon := nil;
  for I := 0 to Hidden.OutlinePolygons.CountChain - 1 do
  begin
    Polygon := TPolygon2D.Create;
    if I = 0 then
    begin
      Hidden.HiddenOutlinePolygonsBackup := Polygon;
      SourcePolygon := Hidden.OutlinePolygons;
    end
    else
    begin
      Hidden.HiddenOutlinePolygonsBackup.Append(Polygon);
      SourcePolygon := SourcePolygon.Next;
    end;
    for J := 0 to SourcePolygon.Points.Count - 1 do
    begin
      GetMem(Point, SizeOf(TPointF));
      Point.X := PPointF(SourcePolygon.Points[J]).X;
      Point.Y := PPointF(SourcePolygon.Points[J]).Y;
      Polygon.Points.Add(Point);
    end;
    Polygon.Extent.X := SourcePolygon.Extent.X;
    Polygon.Extent.Y := SourcePolygon.Extent.Y;
    Polygon.Bounds.Left := SourcePolygon.Bounds.Left;
    Polygon.Bounds.Top := SourcePolygon.Bounds.Top;
    Polygon.Bounds.Right := SourcePolygon.Bounds.Right;
    Polygon.Bounds.Bottom := SourcePolygon.Bounds.Bottom;
  end;
  for I := 0 to Current.OutlinePolygons.CountChain - 1 do
  begin
    Polygon := TPolygon2D.Create;
    if I = 0 then
    begin
      Current.HiddenOutlinePolygonsBackup := Polygon;
      SourcePolygon := Current.OutlinePolygons;
    end
    else
    begin
      Current.HiddenOutlinePolygonsBackup.Append(Polygon);
      SourcePolygon := SourcePolygon.Next;
    end;
    for J := 0 to SourcePolygon.Points.Count - 1 do
    begin
      GetMem(Point, SizeOf(TPointF));
      Point.X := PPointF(SourcePolygon.Points[J]).X;
      Point.Y := PPointF(SourcePolygon.Points[J]).Y;
      Polygon.Points.Add(Point);
    end;
    Polygon.Extent.X := SourcePolygon.Extent.X;
    Polygon.Extent.Y := SourcePolygon.Extent.Y;
    Polygon.Bounds.Left := SourcePolygon.Bounds.Left;
    Polygon.Bounds.Top := SourcePolygon.Bounds.Top;
    Polygon.Bounds.Right := SourcePolygon.Bounds.Right;
    Polygon.Bounds.Bottom := SourcePolygon.Bounds.Bottom;
  end;
  Current.OutlinePolygons.Append(Hidden.OutlinePolygons);
  Hidden.OutlinePolygons := nil;
  Neighbors.Free;
  XList.Free;
  YList.Free;
  BestX.Free;
  BestY.Free;
end;
procedure TConstellation.RestoreHiddenForm;
begin
  if HiddenOutlinePolygonsBackup <> nil then
  begin
    OutlinePolygons.Free;
    OutlinePolygons := HiddenOutlinePolygonsBackup;
    HiddenOutlinePolygonsBackup := nil;
  end;
  if HiddenOutlineSegmentsBackup.Count <> 0 then
  begin
    OutlineSegments.Free;
    OutlineSegments := HiddenOutlineSegmentsBackup;
    HiddenOutlineSegmentsBackup := TList.Create;
  end;
end;
function TGalaxy.CountVisibleConstellationsWithBoundaryPoints(
    FirstPoint,
    SecondPoint: TPointF
): Integer;
var
  I, Count: Integer;
  Constellation: TConstellation;
begin
  Result := 0;
  Count := Constellations.Count;
  for I := 0 to Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.Visible and Constellation.AreBothPointsOnOutline(FirstPoint, SecondPoint) then
      Inc(Result);
  end;
end;
constructor TConstellation.Create;
begin
  inherited Create;
  if Galaxy <> nil then
  begin
    Id := Galaxy.NextConstellationId;
    Inc(Galaxy.NextConstellationId);
  end;
  MapCenter := MakePointF(0, 0);
  Stars := TList.Create;
  AdjacentConstellations := TList.Create;
  OutlineBounds := Classes.Rect(0, 0, 0, 0);
  OutlineBoundsSize := Classes.Point(0, 0);
  StarLinks := TList.Create;
  OutlinePolygons := TPolygon2D.Create;
  BoundaryRaySamples := TList.Create;
  OutlineSegments := TList.Create;
  HiddenOutlineSegmentsBackup := TList.Create;
end;
destructor TConstellation.Destroy;
var
  I: Integer;
begin
  ClearStarLinks;
  ClearOutlineSegmentsAndBounds;
  ClearBoundaryRaySamples;
  StarLinks.Free;
  OutlineSegments.Free;
  for I := 0 to HiddenOutlineSegmentsBackup.Count - 1 do
    Dispose(PMapLineSegment(HiddenOutlineSegmentsBackup[I]));
  HiddenOutlineSegmentsBackup.Clear;
  HiddenOutlineSegmentsBackup.Free;
  AdjacentConstellations.Free;
  Stars.Free;
  OutlinePolygons.Free;
  HiddenOutlinePolygonsBackup.Free;
  BoundaryRaySamples.Free;
  inherited Destroy;
end;
procedure TConstellation.SaveToBuffer(Buffer: TBufEC);
var
  i, j: Integer;
  Star: TStar;
  Constellation: TConstellation;
  Segment: PMapLineSegment;
  Polygon: TPolygon2D;
  Point: PPointF;
begin
  Buffer.AddDWord(Self.Id);
  Buffer.AddBoolean(Self.Visible);
  Buffer.AddWideChar(WideChar(Self.SerializedValue88));
  Buffer.AddSingle(Self.MapCenter.X);
  Buffer.AddSingle(Self.MapCenter.Y);
  Buffer.AddWideChar(WideChar(Self.Stars.Count));
  for i := 0 to Self.Stars.Count - 1 do
  begin
    Star := TStar(Self.Stars[i]);
    Buffer.AddDWord(Star.Id);
  end;
  Buffer.AddWideChar(WideChar(Self.AdjacentConstellations.Count));
  for i := 0 to Self.AdjacentConstellations.Count - 1 do
  begin
    Constellation := TConstellation(Self.AdjacentConstellations[i]);
    Buffer.AddDWord(Constellation.Id);
  end;
  Buffer.AddWideChar(WideChar(Self.OutlineSegments.Count));
  for i := 0 to Self.OutlineSegments.Count - 1 do
  begin
    Segment := PMapLineSegment(Self.OutlineSegments[i]);
    Buffer.AddSingle(Segment^.StartPoint.X);
    Buffer.AddSingle(Segment^.StartPoint.Y);
    Buffer.AddSingle(Segment^.EndPoint.X);
    Buffer.AddSingle(Segment^.EndPoint.Y);
  end;
  Buffer.AddWideChar(WideChar(Self.HiddenOutlineSegmentsBackup.Count));
  for i := 0 to Self.HiddenOutlineSegmentsBackup.Count - 1 do
  begin
    Segment := PMapLineSegment(Self.HiddenOutlineSegmentsBackup[i]);
    Buffer.AddSingle(Segment^.StartPoint.X);
    Buffer.AddSingle(Segment^.StartPoint.Y);
    Buffer.AddSingle(Segment^.EndPoint.X);
    Buffer.AddSingle(Segment^.EndPoint.Y);
  end;
  Buffer.AddIntegerValue(Self.OutlineBounds.Left);
  Buffer.AddIntegerValue(Self.OutlineBounds.Top);
  Buffer.AddIntegerValue(Self.OutlineBounds.Right);
  Buffer.AddIntegerValue(Self.OutlineBounds.Bottom);
  Buffer.AddIntegerValue(Self.OutlineBoundsSize.X);
  Buffer.AddIntegerValue(Self.OutlineBoundsSize.Y);
  Buffer.AddWideChar(WideChar(Self.StarLinks.Count));
  for i := 0 to Self.StarLinks.Count - 1 do
  begin
    Segment := PMapLineSegment(Self.StarLinks[i]);
    Buffer.AddSingle(Segment^.StartPoint.X);
    Buffer.AddSingle(Segment^.StartPoint.Y);
    Buffer.AddSingle(Segment^.EndPoint.X);
    Buffer.AddSingle(Segment^.EndPoint.Y);
  end;
  Buffer.AddWideChar(WideChar(TPolygon2D(Self.OutlinePolygons).CountChain));
  Polygon := Self.OutlinePolygons;
  while Polygon <> nil do
  begin
    Buffer.AddWideChar(WideChar(Polygon.Points.Count));
    for j := 0 to Polygon.Points.Count - 1 do
    begin
      Point := PPointF(Polygon.Points[j]);
      Buffer.AddSingle(Point^.X);
      Buffer.AddSingle(Point^.Y);
    end;
    Buffer.AddSingle(Polygon.Extent.X);
    Buffer.AddSingle(Polygon.Extent.Y);
    Buffer.AddSingle(Polygon.Bounds.Left);
    Buffer.AddSingle(Polygon.Bounds.Top);
    Buffer.AddSingle(Polygon.Bounds.Right);
    Buffer.AddSingle(Polygon.Bounds.Bottom);
    Polygon := Polygon.Next;
  end;
  Buffer.AddWideChar(WideChar(TPolygon2D(Self.HiddenOutlinePolygonsBackup).CountChain));
  Polygon := Self.HiddenOutlinePolygonsBackup;
  while Polygon <> nil do
  begin
    Buffer.AddWideChar(WideChar(Polygon.Points.Count));
    for j := 0 to Polygon.Points.Count - 1 do
    begin
      Point := PPointF(Polygon.Points[j]);
      Buffer.AddSingle(Point^.X);
      Buffer.AddSingle(Point^.Y);
    end;
    Buffer.AddSingle(Polygon.Extent.X);
    Buffer.AddSingle(Polygon.Extent.Y);
    Buffer.AddSingle(Polygon.Bounds.Left);
    Buffer.AddSingle(Polygon.Bounds.Top);
    Buffer.AddSingle(Polygon.Bounds.Right);
    Buffer.AddSingle(Polygon.Bounds.Bottom);
    Polygon := Polygon.Next;
  end;
end;
procedure TConstellation.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
var
  i, j, Count, PointCount: Integer;
  Segment: PMapLineSegment;
  Polygon: TPolygon2D;
  Point: PPointF;
begin
  Self.Id := Buffer.GetUInt32;
  if Galaxy.NextConstellationId <= Self.Id then
    Galaxy.NextConstellationId := Self.Id + 1;
  Self.Visible := Buffer.GetBoolean;
  Self.SerializedValue88 := Buffer.GetWord;
  Self.MapCenter.X := Buffer.GetSingle;
  Self.MapCenter.Y := Buffer.GetSingle;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
    Self.Stars.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
    Self.AdjacentConstellations.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    System.GetMem(Segment, SizeOf(TMapLineSegment));
    Segment^.StartPoint.X := Buffer.GetSingle;
    Segment^.StartPoint.Y := Buffer.GetSingle;
    Segment^.EndPoint.X := Buffer.GetSingle;
    Segment^.EndPoint.Y := Buffer.GetSingle;
    Self.OutlineSegments.Add(Segment);
  end;
  if GlobalsV.LoadedSaveVersion >= 45 then
  begin
    Count := Buffer.GetWord;
    for i := 0 to Count - 1 do
    begin
      System.GetMem(Segment, SizeOf(TMapLineSegment));
      Segment^.StartPoint.X := Buffer.GetSingle;
      Segment^.StartPoint.Y := Buffer.GetSingle;
      Segment^.EndPoint.X := Buffer.GetSingle;
      Segment^.EndPoint.Y := Buffer.GetSingle;
      Self.HiddenOutlineSegmentsBackup.Add(Segment);
    end;
  end;
  Self.OutlineBounds.Left := Buffer.GetInt32;
  Self.OutlineBounds.Top := Buffer.GetInt32;
  Self.OutlineBounds.Right := Buffer.GetInt32;
  Self.OutlineBounds.Bottom := Buffer.GetInt32;
  Self.OutlineBoundsSize.X := Buffer.GetInt32;
  Self.OutlineBoundsSize.Y := Buffer.GetInt32;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    System.GetMem(Segment, SizeOf(TMapLineSegment));
    Segment^.StartPoint.X := Buffer.GetSingle;
    Segment^.StartPoint.Y := Buffer.GetSingle;
    Segment^.EndPoint.X := Buffer.GetSingle;
    Segment^.EndPoint.Y := Buffer.GetSingle;
    Self.StarLinks.Add(Segment);
  end;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    Polygon := TPolygon2D.Create;
    if i = 0 then
      Self.OutlinePolygons := Polygon
    else
      TPolygon2D(Self.OutlinePolygons).Append(Polygon);
    PointCount := Buffer.GetWord;
    for j := 0 to PointCount - 1 do
    begin
      System.GetMem(Point, SizeOf(TPointF));
      Point^.X := Buffer.GetSingle;
      Point^.Y := Buffer.GetSingle;
      Polygon.Points.Add(Point);
    end;
    Polygon.Extent.X := Buffer.GetSingle;
    Polygon.Extent.Y := Buffer.GetSingle;
    Polygon.Bounds.Left := Buffer.GetSingle;
    Polygon.Bounds.Top := Buffer.GetSingle;
    Polygon.Bounds.Right := Buffer.GetSingle;
    Polygon.Bounds.Bottom := Buffer.GetSingle;
  end;
  if GlobalsV.LoadedSaveVersion >= 45 then
  begin
    Count := Buffer.GetWord;
    for i := 0 to Count - 1 do
    begin
      Polygon := TPolygon2D.Create;
      if i = 0 then
        Self.HiddenOutlinePolygonsBackup := Polygon
      else
        TPolygon2D(Self.HiddenOutlinePolygonsBackup).Append(Polygon);
      PointCount := Buffer.GetWord;
      for j := 0 to PointCount - 1 do
      begin
        System.GetMem(Point, SizeOf(TPointF));
        Point^.X := Buffer.GetSingle;
        Point^.Y := Buffer.GetSingle;
        Polygon.Points.Add(Point);
      end;
      Polygon.Extent.X := Buffer.GetSingle;
      Polygon.Extent.Y := Buffer.GetSingle;
      Polygon.Bounds.Left := Buffer.GetSingle;
      Polygon.Bounds.Top := Buffer.GetSingle;
      Polygon.Bounds.Right := Buffer.GetSingle;
      Polygon.Bounds.Bottom := Buffer.GetSingle;
    end;
  end;
end;
procedure TConstellation.ResolveLoadedReferences(Galaxy: TGalaxy);
var
  I: Integer;
begin
  for I := 0 to Stars.Count - 1 do
    Stars[I] := Galaxy.IdToStar(Cardinal(Stars[I]));
  for I := 0 to AdjacentConstellations.Count - 1 do
    AdjacentConstellations[I] := Galaxy.IdToConstellation(Cardinal(AdjacentConstellations[I]));
end;
procedure TConstellation.ClearStarLinks;
var
  I: Integer;
begin
  for I := 0 to StarLinks.Count - 1 do
    Dispose(PConstellationStarLink(StarLinks[I]));
  StarLinks.Clear;
end;
procedure TConstellation.ClearBoundaryRaySamples;
var
  I: Integer;
begin
  for I := 0 to BoundaryRaySamples.Count - 1 do
    Dispose(PConstellationBoundaryRaySample(BoundaryRaySamples[I]));
  BoundaryRaySamples.Clear;
end;
procedure TConstellation.GenerateBoundaryRaySamples(Count: Integer);
var
  Angle, Step: Single;
  I: Integer;
  Sample: PConstellationBoundaryRaySample;
begin
  ClearBoundaryRaySamples;
  Step := 2 * Pi / Count;
  Angle := 0;
  for I := 0 to Count - 1 do
  begin
    GetMem(Sample, SizeOf(TConstellationBoundaryRaySample));
    Sample.Position := MakePointF(Cos(Angle) + MapCenter.X, Sin(Angle) + MapCenter.Y);
    Sample.Direction := MakePointF(Cos(Angle), Sin(Angle));
    Sample.Angle := Angle;
    Sample.GrowthStopped := False;
    BoundaryRaySamples.Add(Sample);
    Angle := Angle + Step;
  end;
end;
procedure TConstellation.SetOutlinePolygon(Polygon: TPolygon2D);
begin
  if OutlinePolygons <> nil then
    OutlinePolygons.Free;
  OutlinePolygons := Polygon;
  RebuildOutlineSegments;
end;
procedure TConstellation.RebuildOutlineSegments;
begin
  if OutlineSegments <> nil then
    OutlineSegments.Free;
  OutlineSegments := OutlinePolygons.ExtractBoundaryEdges;
  RefreshOutlineBounds;
end;
procedure TConstellation.ClearOutlineSegmentsAndBounds;
var
  I: Integer;
begin
  for I := 0 to OutlineSegments.Count - 1 do
    Dispose(PMapLineSegment(OutlineSegments[I]));
  OutlineSegments.Clear;
  OutlineBounds := Classes.Rect(0, 0, 0, 0);
  OutlineBoundsSize := Classes.Point(0, 0);
end;
procedure TConstellation.AddStar(Star: TStar);
begin
  Stars.Add(Star);
  Star.Constellation := Self;
end;
procedure TConstellation.AddAdjacentConstellation(Constellation: TConstellation);
begin
  if not HasAdjacentConstellation(Constellation) then
    AdjacentConstellations.Add(Constellation);
end;
function TConstellation.SharesOutlineSegment(Constellation: TConstellation): Boolean;
var
  I: Integer;
  Segment: PMapLineSegment;
begin
  if Self = Constellation then
  begin
    Result := True;
    Exit;
  end;
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    if Constellation.HasOutlineSegment(Segment.StartPoint, Segment.EndPoint) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
procedure TConstellation.ResetGeneratedMapShape;
begin
  ClearBoundaryRaySamples;
  ClearStarLinks;
  ClearOutlineSegmentsAndBounds;
  ClearStars;
  ClearAdjacentConstellations;
  OutlinePolygons.Free;
  OutlinePolygons := TPolygon2D.Create;
end;
procedure TConstellation.ClearStars;
begin
  if Stars <> nil then
    Stars.Clear;
end;
procedure TConstellation.ClearAdjacentConstellations;
begin
  if AdjacentConstellations <> nil then
    AdjacentConstellations.Clear;
end;
function TConstellation.GetOutlineArea: Single;
begin
  Result := OutlinePolygons.GetChainArea;
end;
function TConstellation.FindNextClosestStarPair(
    var FirstStar, SecondStar: TStar;
    MinimumDistance: Integer
): Integer;
var
  I, J, Distance, BestDistance: Integer;
  A, B: TStar;
  StartI, StartJ: Integer;
begin
  BestDistance := MinimumDistance + 1;
  StartI := 0;
  StartJ := -1;
  if FirstStar <> nil then
    StartI := FirstStar.ConstellationGraphIndex - 1;
  if SecondStar <> nil then
    StartJ := SecondStar.ConstellationGraphIndex - 1;
  FirstStar := nil;
  SecondStar := nil;
  for I := StartI to Stars.Count - 1 do
    for J := I + 1 to Stars.Count - 1 do
      if (I <> StartI) or ((I = StartI) and (J > StartJ)) then
      begin
        A := Stars[I];
        B := Stars[J];
        Distance := Round(PointDistance(A.Position, B.Position));
        if (Distance < BestDistance) and (Distance >= MinimumDistance) then
        begin
          BestDistance := Distance;
          FirstStar := A;
          SecondStar := B;
        end;
      end;
  if FirstStar = nil then
  begin
    BestDistance := Round(GalaxySizeY * Sqrt(2));
    for I := 0 to Stars.Count - 1 do
      for J := I + 1 to Stars.Count - 1 do
      begin
        A := Stars[I];
        B := Stars[J];
        Distance := Round(PointDistance(A.Position, B.Position));
        if (Distance < BestDistance) and (Distance > MinimumDistance) then
        begin
          BestDistance := Distance;
          FirstStar := A;
          SecondStar := B;
        end;
      end;
  end;
  if FirstStar = nil then
    Result := 0
  else
    Result := BestDistance;
end;
function TConstellation.HasStarGraphCycle: Boolean;
var
  I: Integer;
  Link: PConstellationStarLink;
  Changed: Boolean;
  Parents: array[1..100] of Integer;
begin
  Result := False;
  if Stars.Count > 100 then
    Exit;
  for I := 0 to StarLinks.Count - 1 do
  begin
    Link := StarLinks[I];
    Link.TraversalMark := False;
  end;
  while True do
  begin
    for I := 1 to Stars.Count do
      Parents[I] := -1;
    I := 0;
    Link := nil;
    while I < StarLinks.Count do
    begin
      Link := StarLinks[I];
      if not Link.TraversalMark then
        Break;
      Inc(I);
    end;
    if I = StarLinks.Count then
      Break;
    Parents[Link.StartStarIndex] := Link.EndStarIndex;
    Changed := True;
    while Changed do
    begin
      Changed := False;
      for I := 0 to StarLinks.Count - 1 do
      begin
        Link := StarLinks[I];
        if Parents[Link.StartStarIndex] <> -1 then
        begin
          Link.TraversalMark := True;
          if Parents[Link.EndStarIndex] = -1 then
          begin
            Changed := True;
            Parents[Link.EndStarIndex] := Link.StartStarIndex;
          end
          else if (Parents[Link.EndStarIndex] <> Link.StartStarIndex)
              and (Parents[Link.StartStarIndex] <> Link.EndStarIndex) then
          begin
            Result := True;
            Exit;
          end;
        end
        else if Parents[Link.EndStarIndex] <> -1 then
        begin
          Link.TraversalMark := True;
          if Parents[Link.StartStarIndex] = -1 then
          begin
            Changed := True;
            Parents[Link.StartStarIndex] := Link.EndStarIndex;
          end
          else if (Parents[Link.StartStarIndex] <> Link.EndStarIndex)
              and (Parents[Link.EndStarIndex] <> Link.StartStarIndex) then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;
function TConstellation.IsStarGraphConnected: Boolean;
var
  I, J: Integer;
  Link: PConstellationStarLink;
  Stable: Boolean;
  Parents: array[1..100] of Integer;
begin
  Result := False;
  if Stars.Count > 100 then
    Exit;
  for I := 0 to StarLinks.Count - 1 do
  begin
    Link := StarLinks[I];
    Link.TraversalMark := False;
  end;
  for I := 1 to Stars.Count do
    Parents[I] := -1;
  Parents[1] := 0;
  for I := 0 to StarLinks.Count - 1 do
  begin
    Stable := True;
    for J := 0 to StarLinks.Count - 1 do
    begin
      Link := StarLinks[J];
      if (Parents[Link.StartStarIndex] <> -1) and (Parents[Link.EndStarIndex] = -1) then
      begin
        Parents[Link.EndStarIndex] := 0;
        Stable := False;
      end
      else if (Parents[Link.EndStarIndex] <> -1) and (Parents[Link.StartStarIndex] = -1) then
      begin
        Parents[Link.StartStarIndex] := 0;
        Stable := False;
      end;
    end;
    if Stable then
      Break;
  end;
  Result := True;
  for I := 1 to Stars.Count do
    if Parents[I] = -1 then
      Result := False;
end;
function TConstellation.BuildStarGraph: Boolean;
var
  I: Integer;
  Star, FirstStar, SecondStar: TStar;
  MinimumDistance: Integer;
  Link: PConstellationStarLink;
  Segment: PMapLineSegment;
  Intersection: TPointF;
begin
  ClearStarLinks;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := Stars[I];
    Star.ConstellationGraphIndex := I + 1;
  end;
  MinimumDistance := 0;
  FirstStar := nil;
  SecondStar := nil;
  while True do
  begin
    MinimumDistance := FindNextClosestStarPair(FirstStar, SecondStar, MinimumDistance);
    if MinimumDistance = 0 then
      Break;
    GetMem(Link, SizeOf(TConstellationStarLink));
    Link.StartPoint := FirstStar.Position;
    Link.EndPoint := SecondStar.Position;
    Link.StartStarIndex := FirstStar.ConstellationGraphIndex;
    Link.EndStarIndex := SecondStar.ConstellationGraphIndex;
    StarLinks.Add(Link);
    if HasStarGraphCycle then
    begin
      StarLinks.Delete(StarLinks.Count - 1);
      Dispose(Link);
      Continue;
    end;
    for I := 0 to OutlineSegments.Count - 1 do
    begin
      Segment := OutlineSegments[I];
      if IntersectSegmentsF(
          Link.StartPoint,
          Link.EndPoint,
          Segment.StartPoint,
          Segment.EndPoint,
          Intersection) then
      begin
        StarLinks.Delete(StarLinks.Count - 1);
        Dispose(Link);
        Break;
      end;
    end;
  end;
  Result := IsStarGraphConnected;
end;
procedure TConstellation.ExpandOutlineBounds(Point: TPointF);
begin
  if OutlineBounds.Left > Point.X then
    OutlineBounds.Left := Round(Point.X);
  if OutlineBounds.Top > Point.Y then
    OutlineBounds.Top := Round(Point.Y);
  if OutlineBounds.Right < Point.X then
    OutlineBounds.Right := Round(Point.X);
  if OutlineBounds.Bottom < Point.Y then
    OutlineBounds.Bottom := Round(Point.Y);
end;
procedure TConstellation.RefreshOutlineBounds;
var
  I: Integer;
  Segment: PMapLineSegment;
begin
  OutlineBounds.TopLeft := Classes.Point(0, 0);
  OutlineBounds.BottomRight := Classes.Point(0, 0);
  if OutlineSegments.Count <> 0 then
  begin
    Segment := OutlineSegments[0];
    OutlineBounds.Top := Round(Segment.StartPoint.Y);
    OutlineBounds.Left := Round(Segment.StartPoint.X);
    OutlineBounds.Bottom := Round(Segment.StartPoint.Y);
    OutlineBounds.Right := Round(Segment.StartPoint.X);
    for I := 0 to OutlineSegments.Count - 1 do
    begin
      Segment := OutlineSegments[I];
      ExpandOutlineBounds(Segment.StartPoint);
      ExpandOutlineBounds(Segment.EndPoint);
    end;
    OutlineBoundsSize :=
        Classes.Point(
            OutlineBounds.Right - OutlineBounds.Left,
            OutlineBounds.Bottom - OutlineBounds.Top
        );
  end;
end;
function TConstellation.ContainsPoint(Point: TPointF): Boolean;
begin
  Result := False;
  if OutlinePolygons <> nil then
    if OutlinePolygons.ChainContainsPoint(Point) then
      Result := True
    else
      Result := False;
end;
function TConstellation.HasAdjacentConstellation(Constellation: TConstellation): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to AdjacentConstellations.Count - 1 do
    if AdjacentConstellations[I] = Constellation then
      Exit;
  Result := False;
end;
function TConstellation.HasOutlineSegment(FirstPoint, SecondPoint: TPointF): Boolean;
var
  I: Integer;
  Segment: PMapLineSegment;
begin
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    if SegmentsNearlyEqualF(FirstPoint, SecondPoint, Segment.StartPoint, Segment.EndPoint) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
function TConstellation.AreBothPointsOnOutline(FirstPoint, SecondPoint: TPointF): Boolean;
var
  I: Integer;
  Segment: PMapLineSegment;
  Classification: Integer;
  FoundFirst, FoundSecond: Boolean;
begin
  FoundFirst := False;
  FoundSecond := False;
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    Classification := ClassifyPointToSegment(Segment.StartPoint, Segment.EndPoint, FirstPoint);
    if Classification >= 5 then
      FoundFirst := True;
    Classification := ClassifyPointToSegment(Segment.StartPoint, Segment.EndPoint, SecondPoint);
    if Classification >= 5 then
      FoundSecond := True;
  end;
  Result := FoundFirst and FoundSecond;
end;
function TConstellation.CalculateLabelPosition: TPointF;
var
  I: Integer;
  Segment: PMapLineSegment;
  MinPoint, MaxPoint: TPointF;
  X, Y, StepX, StepY, SumX, SumY: Single;
  Count: Integer;
begin
  MinPoint := MakePointF(1.0e20, 1.0e20);
  MaxPoint := MakePointF(-1.0e20, -1.0e20);
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    MinPoint.X := Min(MinPoint.X, Segment.StartPoint.X);
    MinPoint.Y := Min(MinPoint.Y, Segment.StartPoint.Y);
    MaxPoint.X := Max(MaxPoint.X, Segment.StartPoint.X);
    MaxPoint.Y := Max(MaxPoint.Y, Segment.StartPoint.Y);
  end;
  StepX := (MaxPoint.X - MinPoint.X) / 10;
  StepY := (MaxPoint.Y - MinPoint.Y) / 10;
  SumX := 0;
  SumY := 0;
  Count := 0;
  Y := MinPoint.Y;
  while Y < MaxPoint.Y do
  begin
    X := MinPoint.X;
    while X < MaxPoint.X do
    begin
      if ContainsPoint(MakePointF(X, Y)) then
      begin
        SumX := SumX + X;
        SumY := SumY + Y;
        Inc(Count);
      end;
      X := X + StepX;
    end;
    Y := Y + StepY;
  end;
  Result := MakePointF(SumX / Count, SumY / Count);
end;
function TConstellation.HasOutlineVertex(Point: TPointF): Boolean;
var
  I: Integer;
  Segment: PMapLineSegment;
begin
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    if PointsNearlyEqualF(Segment.StartPoint, Point)
        or PointsNearlyEqualF(Segment.EndPoint, Point) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
function TConstellation.IsPointNearOutline(Point: TPointF): Boolean;
var
  I: Integer;
  Segment: PMapLineSegment;
  Minimum, Distance: Single;
begin
  Minimum := GalaxySizeX;
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    Distance := PointSegmentDistanceF(Segment.StartPoint, Segment.EndPoint, Point);
    if Distance < Minimum then
      Minimum := Distance;
  end;
  if Minimum <= 2 then
    Result := True
  else
    Result := False;
end;
procedure TConstellation.NormalizeOutlineSegmentOrder;
var
  I, J: Integer;
  First, Next: PMapLineSegment;
  Temp: Pointer;
  Point: TPointF;
begin
  for I := 0 to OutlineSegments.Count - 2 do
  begin
    First := OutlineSegments[I];
    J := I + 1;
    while J < OutlineSegments.Count do
    begin
      Next := OutlineSegments[J];
      if PointsNearlyEqualF(First.EndPoint, Next.StartPoint) then
        Break;
      if PointsNearlyEqualF(First.EndPoint, Next.EndPoint) then
      begin
        Point := Next.StartPoint;
        Next.StartPoint := Next.EndPoint;
        Next.EndPoint := Point;
        Break;
      end;
      Inc(J);
    end;
    if J < OutlineSegments.Count then
    begin
      Temp := OutlineSegments[I + 1];
      OutlineSegments[I + 1] := OutlineSegments[J];
      OutlineSegments[J] := Temp;
    end;
  end;
end;
function TConstellation.GetName: WideString;
var
  Index: Integer;
begin
  Index := Galaxy.Constellations.IndexOf(Self);
  Result := LocalizedText('Constellations.Name.' + IntToStr(Index + 1));
end;
function TConstellation.HasDominatorPresence: Boolean;
var
  I: Integer;
  Star: TStar;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Star := Stars[I];
    if Star.ShipTypeCounts[stKling] > 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
function TConstellation.HasPirateClanPresence: Boolean;
var
  I, J: Integer;
  Star: TStar;
  Ship: TShip;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Star := Stars[I];
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if (Ship is TPirate)
          and (Ship.OwnerId = Byte(oiPirate))
          and (TPirate(Ship).PirateType <> 0) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;
function TConstellation.HasBertorOfSeries(Series: TDominatorSeries): Boolean;
var
  I, J: Integer;
  Star: TStar;
  Ship: TShip;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Star := Stars[I];
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if (Ship is TKling)
          and ((Ship as TKling).DominatorSeries = Series)
          and ((Ship as TKling).KlingType = ktBertor) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;
function TConstellation.CountShipsByTypeMask(ShipTypeMask: TShipTypeMask): Integer;
var
  Count: Integer;
  I: Byte;
begin
  Count := 0;
  for I := 0 to 13 do
    if I in ShipTypeMask then
      Inc(Count, ShipTypeCounts[I]);
  Result := Count;
end;
function TGalaxy.CountEligibleRangers: Integer;
var
  Index: Integer;
  Ranger: TRanger;
begin
  Result := 0;
  for Index := 0 to Rangers.Count - 1 do
  begin
    Ranger := Rangers[Index];
    if not Ranger.ExcludedFromRating then
      Inc(Result);
  end;
end;
procedure TGalaxy.RefreshRangerWealthStats;
var
  I, J, Count: Integer;
  Total: Int64;
  Ranger: TRanger;
  Ship: TShip;
  Star: TStar;
// The +0 expressions preserve DCC32 O- receiver/value scheduling without
// emitted arithmetic; original source spelling is unknown.
begin
  if SpecialSimulationMode <> 0 then
    AverageRangerCapital := 100000000
  else
  begin
    WealthiestRanger := nil;
    MaxRangerWealth := 0;
    if Rangers.Count <> 0 then
    begin
      Total := 0;
      Count := 0;
      for I := 0 to Rangers.Count - 1 do
      begin
        Ranger := TRanger(Rangers[I]);
        if not Ranger.ExcludedFromRating then
        begin
          Total := Total + Ranger.CalculateWealth;
          Inc(Count);
          if (MaxRangerWealth + 0 < Ranger.Wealth) or (WealthiestRanger = nil) then
          begin
            MaxRangerWealth := Ranger.Wealth;
            WealthiestRanger := Ranger;
          end;
        end;
      end;
      if CoalitionDefeatedTurn <> 0 then
        for I := 0 to Stars.Count - 1 do
        begin
          Star := TStar(Stars[I]);
          for J := 0 to Star.Ships.Count - 1 do
          begin
            Ship := Star.Ships[J];
            if (Ship is TPirate)
                and ((Ship as TPirate).PirateType = 0)
                and (Ship.OwnerId = Byte(oiPirate)) then
            begin
              Total := Total + Ship.CalculateWealth;
              Inc(Count);
            end;
          end;
        end;
      Total := Round(Total / Count); // Native has no guard when all roster entries are excluded.
      if Total > MaxInt then
        AverageRangerCapital := MaxInt
      else
        AverageRangerCapital := Total;
    end;
  end;
  // Keep wealthiest-ranger and maximum-wealth statistics current while frozen.
  if UtilityCapitalOverrideActive then
    AverageRangerCapital := UtilityCapitalOverrideValue;
end;
procedure TGalaxy.RefreshRangerStrengthStats;
var
  I, J, Count: Integer;
  Ranger: TRanger;
  Total: Single;
  Ship: TShip;
  Star: TStar;
begin
  BestRangerStrength := 0;
  StrongestRanger := nil;
  if Rangers.Count <> 0 then
  begin
    Total := 0;
    Count := 0;
    for I := 0 to Rangers.Count - 1 do
    begin
      Ranger := Rangers[I];
      if not Ranger.ExcludedFromRating then
      begin
        Total := Total + Ranger.Strength;
        if (BestRangerStrength < Ranger.Strength) or (StrongestRanger = nil) then
        begin
          BestRangerStrength := Ranger.Strength;
          StrongestRanger := Ranger;
        end;
        Inc(Count);
      end;
    end;
    if CoalitionDefeatedTurn <> 0 then
      for I := 0 to Stars.Count - 1 do
      begin
        Star := TStar(Stars[I]);
        for J := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(Star.Ships[J]);
          if (Ship is TPirate)
              and ((Ship as TPirate).PirateType = 0)
              and (Ship.OwnerId = Byte(oiPirate)) then
          begin
            Total := Total + Ship.Strength;
            if BestRangerStrength < Ship.Strength then
              BestRangerStrength := Ship.Strength;
            Inc(Count);
          end;
        end;
      end;
    AverageRangerStrength :=
        Total / Count; // Native has no guard when all roster entries are excluded.
  end;
end;
procedure TGalaxy.RefreshRangerRatingPlaces;
var
  I, J: Integer;
  First, Second: TRanger;
  Sorted: array of PtrUInt;
  SwapFirst, SwapSecond: PtrUInt; // Native RTTI: dynamic Cardinal array storing object addresses.
begin
  SetLength(Sorted, Rangers.Count);
  for I := 0 to Rangers.Count - 1 do
  begin
    First := Rangers[I];
    Sorted[I] := PtrUInt(First);
  end;
  for I := 0 to Rangers.Count - 1 do
    for J := I to Rangers.Count - 1 do
    begin
      First := TRanger(Sorted[I]);
      Second := TRanger(Sorted[J]);
      if First.TotalExperience < Second.TotalExperience then
      begin
        SwapFirst := Sorted[I];
        SwapSecond := Sorted[J];
        Sorted[J] := SwapFirst;
        Sorted[I] := SwapSecond;
      end;
    end;
  for I := 0 to Rangers.Count - 1 do
  begin
    First := TRanger(Sorted[I]);
    First.PlaceInRating := I + 1;
  end;
  if (GetPlayer <> nil) and (not Destroying) then
    GetPlayer.AchievementStats.CheckFirstPlaceRatingAchievement;
end;
function TGalaxy.FindStrongestRanger: Pointer;
var
  I: Integer;
  Ranger: TRanger;
  Best: Single;
begin
  Best := 0;
  Result := nil;
  for I := 0 to Rangers.Count - 1 do
  begin
    Ranger := Rangers[I];
    if not Ranger.ExcludedFromRating and (Ranger.Strength > Best) then
    begin
      Result := Ranger;
      Best := Ranger.Strength;
    end;
  end;
end;
function TGalaxy.FindWealthiestRanger: Pointer;
var
  I: Integer;
  Ranger: TRanger;
  Best: Single;
begin
  Best := 0;
  Result := nil;
  for I := 0 to Rangers.Count - 1 do
  begin
    Ranger := Rangers[I];
    if not Ranger.ExcludedFromRating and (Ranger.Wealth > Best) then
    begin
      Result := Ranger;
      Best := Ranger.Wealth;
    end;
  end;
end;
function TGalaxy.CountFactionStars(Faction: Byte): Integer;
var
  Index: Integer;
  Star: TStar;
begin
  Result := 0;
  for Index := 0 to Stars.Count - 1 do
  begin
    Star := Stars[Index];
    if (Star.Status.CustomFaction = '') and (Byte(Star.ControlFaction) = Faction) then
      Inc(Result);
  end;
end;
function TGalaxy.GetFactionControlPercent(Faction: Byte): TControlPercent;
begin
  Result := Round(CountFactionStars(Faction) / Stars.Count * 100);
end;
function TGalaxy.GetDominatorSeriesControlShare(Series: TDominatorSeries): Single;
var
  I, SeriesStars, DominatorStars, Unresolved: Integer;
  Star: TStar;
begin
  DominatorStars := 0;
  SeriesStars := 0;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := Galaxy.Stars[I];
    if (Star.ControlFaction = sfDominators) and (Star.Status.CustomFaction = '') then
    begin
      Inc(DominatorStars);
      if Star.DominatorSeries = Series then
        Inc(SeriesStars);
    end;
  end;
  if DominatorStars = 0 then
    DominatorStars := 1;
  Unresolved := 0;
  if Galaxy.KellerSeriesResolvedTurn = 0 then
    Inc(Unresolved);
  if Galaxy.TerronSeriesResolvedTurn = 0 then
    Inc(Unresolved);
  if Galaxy.BlazerSeriesResolvedTurn = 0 then
    Inc(Unresolved);
  Result := (Unresolved * SeriesStars) / DominatorStars;
end;
function TGalaxy.CountStarsInBattle: Integer;
var
  I: Integer;
  Star: TStar;
begin
  Result := 0;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := Stars[I];
    if Star.Battle <> 0 then
      Inc(Result);
  end;
end;
procedure TGalaxy.AssignTextQuestsToPlanets;
var
  I, J, Index, Count, QuestId: Integer;
  Planet: TPlanet;
  Quest: TTextQuest;
  Control: TCBufControlEC;
  Buffer: TCBufEC;
begin
  Count := LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamCount;
  for I := 0 to Count - 1 do
    if IsIntegerTextW(
        LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamName(I)) then
    begin
      QuestId :=
          StrToInt(
              AnsiString(
                  LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamName(I)
              )
          );
      Quest := TTextQuest.Create;

      Control := nil;
      try
        Control := TCBufControlEC.Create;
        GlobalCache.ResetControl(Control);
        Control.SetCacheKey('PlanetQuest.' + IntToStr(QuestId));
        Buffer := AcquireOrCreateBuffer(Control);
        Quest.LoadFromReader(Buffer.Buffer, True);
      finally
        if Control <> nil then
        begin
          Control.Release;
          Control.Free;
        end;
      end;

      Index := NextRandomIntRange(0, Planets.Count - 1, RandomState);
      for J := 0 to Planets.Count - 1 do
      begin
        IncrementWrapped(Index, 0, Planets.Count - 1);
        Planet := Planets[Index];
        if (Planet.CurrentStar.Constellation.Id <> 20)
            and (Planet.TextQuestId <= -1)
            and Planet.Graphic.QuestEnabled
            and ((Planet.OwnerId <> Byte(oiDominator))
                or (PointDistance(Planet.CurrentStar.Position, GetPlayer.CurrentStar.Position)
                    <= 80))
            and ((Planet.LandTiles >= Planet.GetTotalSurfaceTileCount * 0.2)
                or ((Planet.LandTiles >= Planet.GetTotalSurfaceTileCount * 0.1)
                    and (J >= Planets.Count * 0.7)))
            and (((Planet.OwnerId = Byte(oiUninhabited))
                    and (6 in TOwnerMask(Quest.TargetOwnerMask)))
                or ((0 in TOwnerMask(Quest.TargetOwnerMask))
                    and (Planet.RaceId = Byte(oiMaloc))
                    and (Planet.OwnerId <> Byte(oiUninhabited)))
                or ((1 in TOwnerMask(Quest.TargetOwnerMask))
                    and (Planet.RaceId = Byte(oiPeleng))
                    and (Planet.OwnerId <> Byte(oiUninhabited)))
                or ((2 in TOwnerMask(Quest.TargetOwnerMask))
                    and (Planet.RaceId = Byte(oiHuman))
                    and (Planet.OwnerId <> Byte(oiUninhabited)))
                or ((3 in TOwnerMask(Quest.TargetOwnerMask))
                    and (Planet.RaceId = Byte(oiFeyan))
                    and (Planet.OwnerId <> Byte(oiUninhabited)))
                or ((4 in TOwnerMask(Quest.TargetOwnerMask))
                    and (Planet.RaceId = Byte(oiGaal))
                    and (Planet.OwnerId <> Byte(oiUninhabited)))
                or ((TOwnerMask(Quest.TargetOwnerMask) = [])
                    and (((0 in TOwnerMask(Quest.IssuerRaceMask))
                            and (Planet.RaceId = Byte(oiMaloc))
                            and (Planet.OwnerId <> Byte(oiUninhabited)))
                        or ((1 in TOwnerMask(Quest.IssuerRaceMask))
                            and (Planet.RaceId = Byte(oiPeleng))
                            and (Planet.OwnerId <> Byte(oiUninhabited)))
                        or ((2 in TOwnerMask(Quest.IssuerRaceMask))
                            and (Planet.RaceId = Byte(oiHuman))
                            and (Planet.OwnerId <> Byte(oiUninhabited)))
                        or ((3 in TOwnerMask(Quest.IssuerRaceMask))
                            and (Planet.RaceId = Byte(oiFeyan))
                            and (Planet.OwnerId <> Byte(oiUninhabited)))
                        or ((4 in TOwnerMask(Quest.IssuerRaceMask))
                            and (Planet.RaceId = Byte(oiGaal))
                            and (Planet.OwnerId <> Byte(oiUninhabited)))))) then
        begin
          Planet.TextQuestId := QuestId;
          Break;
        end;
      end;
      Quest.Free;
    end;
end;
function TGalaxy.HasPlayerQuestHistory(QuestType: TQuestType; QuestNumber: Word): Boolean;
var
  I: Integer;
  Quest: PPlayerOldQuest;
begin
  for I := PlayerOldQuests.Count - 1 downto 0 do
  begin
    Quest := PlayerOldQuests[I];
    if (QuestType = Quest.QuestType) and (QuestNumber = Quest.QuestNumber) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
function TGalaxy.TurnToDateTime(Turn: Integer): Double;
begin
  if Turn = -1 then
    Turn := CurrentTurn;
  Result := Turn + 511341.5 - 300.0;
end;
function TGalaxy.FormatTurnDate(Turn: Integer): WideString;
var
  MonthNumber, MonthName: WideString;
begin
  MonthNumber := FormatDateTime('mm', TurnToDateTime(Turn));
  MonthName := LocalizedText('Month.' + MonthNumber);
  Result :=
      FormatDateTime('d', TurnToDateTime(Turn))
          + ' '
          + MonthName
          + ' '
          + FormatDateTime('yyyy', TurnToDateTime(Turn));
end;
procedure TGalaxy.AddPlanetNewsWithPlayerBubble(NewsType: Byte; Text: WideString);
begin
  if CurrentTurn > 300 then
    AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '');
  AddPlanetNews(NewsType, Text);
end;
procedure TGalaxy.AddPlanetNews(NewsType: Byte; Text: WideString);
var
  Entry: PPlanetNewsEntry;
  Index: Integer;
begin
  if Text = '' then
    raise Exception.Create(
        'Error! Получена пустая планетарная новость');
  if PlanetNews <> nil then
    for Index := 0 to PlanetNews.Count - 1 do
    begin
      Entry := PlanetNews[Index];
      if Entry.Text = Text then
        Exit;
    end;
  Inc(NextPlanetNewsId);
  New(Entry);
  Entry.Id := NextPlanetNewsId;
  Entry.Turn := CurrentTurn;
  Entry.NewsType := NewsType;
  Entry.Text := Text;
  PlanetNews.Add(Entry);
end;
function TGalaxy.CountPlanetNewsByType(NewsType: Byte): Integer;
var
  Entry: PPlanetNewsEntry;
  Index: Integer;
begin
  Result := 0;
  for Index := 0 to PlanetNews.Count - 1 do
  begin
    Entry := PlanetNews[Index];
    if Entry.NewsType = NewsType then
      Inc(Result);
  end;
end;
procedure TGalaxy.PrunePlanetNews;
var
  I: Integer;
  News: PPlanetNewsEntry;
begin
  for I := PlanetNews.Count - 1 downto 0 do
  begin
    News := PlanetNews[I];
    if News.Turn < CurrentTurn - 30 then
    begin
      PlanetNews.Delete(I);
      Dispose(News);
    end;
  end;
end;
procedure TGalaxy.CreateDominatorSpawnProxy(Star: TStar);
begin
  DominatorSpawnPlanet := TPlanet.Create;
  DominatorSpawnPlanet.InitDominatorSpawnProxy(TObject(Star) as TStar);
end;
procedure TGalaxy.UpdateConstellationMilitaryStats;
var
  I, J: Integer;
  Constellation: TConstellation;
  Star: TStar;
  Kind: Byte;
begin
  // The native cache indexes all fourteen ship types at $84..$B8.
  for Kind := 0 to 13 do
    ShipTypeCounts[Kind] := 0;
  for I := 0 to Constellations.Count - 1 do
  begin
    Constellation := Constellations[I];
    for Kind := 0 to 13 do
      Constellation.ShipTypeCounts[Kind] := 0;
    for J := 0 to Constellation.Stars.Count - 1 do
    begin
      Star := Constellation.Stars[J];
      Star.RefreshShipTypeCounts;
      for Kind := 0 to 13 do
      begin
        Inc(Constellation.ShipTypeCounts[Kind], Star.ShipTypeCounts[Kind]);
        Inc(ShipTypeCounts[Kind], Star.ShipTypeCounts[Kind]);
      end;
    end;
  end;
end;
function TGalaxy.RefreshTechLevel: Byte;
var
  I, HighestLevel, HighestCount, PreviousCount: Integer;
  Planet: TPlanet;
begin
  if SpecialSimulationMode <> 0 then
  begin
    Result := 8;
    Exit;
  end;
  Result := 0;
  HighestCount := 0;
  PreviousCount := 0;
  HighestLevel := 0;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := Planets[I];
    if Planet.IsCoalitionOwned or (Planet.OwnerId = Byte(oiPirate)) then
    begin
      if Planet.InventionLevels[7] > HighestLevel then
      begin
        if Planet.InventionLevels[7] = HighestLevel + 1 then
          PreviousCount := HighestCount
        else
          PreviousCount := 0;
        HighestCount := 1;
        HighestLevel := Planet.InventionLevels[7];
      end
      else if Planet.InventionLevels[7] = HighestLevel then
        Inc(HighestCount)
      else if Planet.InventionLevels[7] = HighestLevel - 1 then
        Inc(PreviousCount);
    end;
  end;
  if HighestCount >= 5 then
    TechLevel := Max(1, HighestLevel)
  else if (HighestCount >= 2) or (HighestCount + PreviousCount >= 5) then
    TechLevel := Max(1, HighestLevel - 1)
  else
    TechLevel := Max(1, HighestLevel - 2);
end;
procedure TGalaxy.CancelEnemyJumpsToStar(Star: TStar);
var
  I, J: Integer;
  Other: TStar;
  Ship: TShip;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Other := TStar(Stars[I]);
    if Other <> Star then
      for J := 0 to Other.Ships.Count - 1 do
      begin
        Ship := TShip(Other.Ships[J]);
        if Ship.InNormalSpace then
        begin
          if ((Ship is TKling) or (Ship.CurrentStanding = ssPirateMilitary))
              and (Ship.Order = soJump)
              and (Ship.OrderTarget = Star) then
            Ship.OrderNone(False);
          if (Ship is TRuins)
              and (Ship.TypeId = Byte(rstDominion))
              and ((Ship as TRuins).FlyToStar = Star) then
          begin
            (Ship as TRuins).FlyToStar := nil;
            (Ship as TRuins).FlyDate := 0;
            Ship.OrderNone(False);
          end;
        end;
      end;
  end;
end;
function TGalaxy.SelectStarForLiberationAttack(Origin: TStar; FriendlyFaction: TStarFaction): TStar;
var
  I, J, Weight, BestWeight: Integer;
  Star, Other: TStar;
begin
  BestWeight := MaxInt;
  Result := nil;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if (Star.ControlFaction <> FriendlyFaction)
        and (Star.Battle = 0)
        and (Star.Constellation.Id <> 20) then
    begin
      Weight := 0;
      for J := 1 to Galaxy.Stars.Count - 1 do
      begin
        Other := TObject(Star.StarDistances[J].Star) as TStar;
        if (Other.ControlFaction = FriendlyFaction) and (Other.Status.CustomFaction = '') then
          Inc(Weight, Star.StarDistances[J].Distance);
      end;
      if Origin <> nil then
        Weight :=
            Round(
                RemapClamped(
                    PointDistance(Origin.Position, Star.Position),
                    10,
                    100,
                    Weight,
                    100 * Weight
                )
            );
      Weight := Round(NextRandomFloatRange(Weight, 2 * Weight, RandomState));
      if Weight < BestWeight then
      begin
        BestWeight := Weight;
        Result := Star;
      end;
    end;
  end;
end;
procedure TGalaxy.ComputeGlobalGoodsPriceBands;
var
  Good: Byte;
  PriceSpread: Single;
begin
  for Good := 0 to 7 do
  begin
    aConst.GoodsMarket[Good].MinPrice :=
        Self.ScaleGoodsPriceByGalaxyAge(aConst.GoodsMarketBase[Good].MinPrice);
    aConst.GoodsMarket[Good].AveragePrice :=
        Self.ScaleGoodsPriceByGalaxyAge(aConst.GoodsMarketBase[Good].AveragePrice);
    aConst.GoodsMarket[Good].MaxPrice :=
        Self.ScaleGoodsPriceByGalaxyAge(aConst.GoodsMarketBase[Good].MaxPrice);
    aConst.GoodsMarket[Good].BaseStock :=
        Self.ScaleGoodsStockByGalaxyAge(aConst.GoodsMarketBase[Good].BaseStock);
    PriceSpread := aConst.GoodsMarket[Good].AveragePrice - aConst.GoodsMarket[Good].MinPrice;
    Inc(
        aConst.GoodsMarket[Good].MinPrice,
        System.Round(
            PriceSpread
                * aConst.GalaxyDifficultyTuning[Self.DifficultyLevels[1]].MarketPriceBandSqueeze
        )
    );
    if aConst.GoodsMarket[Good].MinPrice >= aConst.GoodsMarket[Good].AveragePrice - 1 then
      aConst.GoodsMarket[Good].MinPrice := aConst.GoodsMarket[Good].AveragePrice - 2;
    Dec(
        aConst.GoodsMarket[Good].MaxPrice,
        System.Round(
            PriceSpread
                * aConst.GalaxyDifficultyTuning[Self.DifficultyLevels[1]].MarketPriceBandSqueeze
        )
    );
    if aConst.GoodsMarket[Good].MaxPrice <= aConst.GoodsMarket[Good].AveragePrice + 1 then
      aConst.GoodsMarket[Good].MaxPrice := aConst.GoodsMarket[Good].AveragePrice + 2;
  end;
end;
function TGalaxy.GetGoodsPricePercent(GoodsType: Byte; Price: Integer): Byte;
begin
  Result :=
      Round(
          RemapClamped(
              Price,
              GoodsMarket[GoodsType].MinPrice,
              GoodsMarket[GoodsType].MaxPrice,
              0,
              100
          )
      );
end;
function TGalaxy.ScaleGoodsPriceByGalaxyAge(BaseValue: Integer): Integer;
begin
  Result :=
      Round(
          RemapClamped(
              CurrentTurn,
              GoodsInflationStartTurn,
              GoodsInflationEndTurn,
              BaseValue * GoodsInflationMin,
              BaseValue * GoodsInflationMax
          )
      );
end;
function TGalaxy.ScaleGoodsStockByGalaxyAge(BaseValue: Integer): Integer;
begin
  Result :=
      Round(
          RemapClamped(
              CurrentTurn,
              GoodsInflationStartTurn,
              GoodsInflationEndTurn,
              BaseValue * GoodsStockMin,
              BaseValue * GoodsStockMax
          )
      );
end;
function TGalaxy.ScaleIntByTechLevel(AtLevelTwo, AtLevelSeven: Integer): Integer;
begin
  Result := Round(RemapClamped(TechLevel, 2, 7, AtLevelTwo, AtLevelSeven));
end;
function TGalaxy.InterpolateSingleByTechLevel(AtLevelTwo, AtLevelSeven: Single): Single;
begin
  Result := RemapClamped(TechLevel, 2, 7, AtLevelTwo, AtLevelSeven);
end;
function TGalaxy.SelectWeaponInfo(
    Seed: Cardinal;
    AvailabilityMask: TWeaponAvailabilityMask;
    MaximumTechLevel, MinimumTechLevel: Byte
): PWeaponInfo;
var
  I: Integer;
  Candidates: TList;
  Info, Nearest: PWeaponInfo;
  Distance, NearestDistance: Integer;
  function TechDistance(
      TechLevel: Integer
  ): Integer; // @addr 0x7BC170 @ida "int __usercall $name@<eax>(int TechLevel@<eax>, void *ParentFrame@<^0>);" @note "Nested helper with caller-popped static link. Minimum/maximum bytes are at ParentFrame+8/+12."
  begin
    Result := 0;
    if TechLevel > MaximumTechLevel then
      Result := TechLevel - MaximumTechLevel;
    if TechLevel < MinimumTechLevel then
      Result := Max(Result, MinimumTechLevel - TechLevel);
  end;
begin
  Candidates := TList.Create;
  NearestDistance := 0;
  Nearest := nil;
  for I := 1 to CountItemTypesInMask([Ord(t_Weapon1)..Ord(t_Weapon18)]) do
  begin
    Info := @WeaponInfos[Ord(TItemType(GetItemTypeFromMask([Ord(t_Weapon1)..Ord(t_Weapon18)], I)))];
    if Byte(Info.Availability) in AvailabilityMask then
    begin
      Distance := TechDistance(Info.TechLevel);
      if Distance > 0 then
      begin
        if (Candidates.Count <= 0) and ((Nearest = nil) or (Distance < NearestDistance)) then
        begin
          Nearest := Info;
          NearestDistance := Distance;
        end;
      end
      else
        Candidates.Add(Info);
    end;
  end;
  for I := 0 to CustomWeaponTypes.Count - 1 do
  begin
    Info := PWeaponInfo(CustomWeaponTypes[I]);
    if Byte(Info.Availability) in AvailabilityMask then
    begin
      Distance := TechDistance(Info.TechLevel);
      if Distance > 0 then
      begin
        if (Candidates.Count <= 0) and ((Nearest = nil) or (Distance < NearestDistance)) then
        begin
          Nearest := Info;
          NearestDistance := Distance;
        end;
      end
      else
        Candidates.Add(CustomWeaponTypes[I]);
    end;
  end;
  if Candidates.Count > 0 then
    Result := PWeaponInfo(Candidates[SeededRandomIntRange(0, Candidates.Count - 1, Seed)])
  else
    Result := Nearest;
  Candidates.Free;
  if Result = nil then
    Result := @WeaponInfos;
end;
function TGalaxy.SelectMicroModule(
    MinimumPriority, MaximumPriority: Byte;
    Seed: Cardinal;
    Context: TObject
): Integer;
type
  TModuleOwnerMasks = array[0..2] of TOwnerMask;
var
  Attempts, ModuleIndex, BestIndex, BestPriority: Integer;
begin
  Attempts := 0;
  BestIndex := -1;
  BestPriority := 100;
  repeat
    Inc(Attempts);
    ModuleIndex := NextRandomIntRange(0, MicroModuleTemplateCount - 1, Seed);
    if aConst.MicroModuleTemplates[ModuleIndex].SpecialOnly then
      Continue;
    if Context <> nil then
    begin
      if (Context is TKling) and not TShip(Context).HasScriptStateText then
      begin
        if not (Byte((Context as TKling).DominatorSeries)
            in TDominatorSeriesMask(
                aConst.MicroModuleTemplates[ModuleIndex].AllowedDominatorSeriesMask)) then
          Continue;
        if not (Ord(oiDominator)
            in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
          Continue;
        if not aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction
            and (TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                <> [Ord(oiDominator)])
            and (TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                    * [Ord(oiMaloc)..Ord(oiDominator), Ord(oiPirate)]
                <> [Ord(oiMaloc)..Ord(oiDominator), Ord(oiPirate)]) then
          Continue;
      end;
      if aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction then
      begin
        if Context is TPlanet then
        begin
          if not (Ord(TPlanet(Context).OwnerId)
              in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
            Continue;
        end
        else if Context is TRuins then
        begin
          if TRuins(Context).CurrentStanding
              in TStationStandingMask(
                  aConst.FactionStandingMasks[Ord(TRuins(Context).CurrentStar.ControlFaction)]) then
          begin
            if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                    * TModuleOwnerMasks(aConst.PlanetOwnerMasks)[
                        Ord(TRuins(Context).CurrentStar.ControlFaction)]
                = [] then
              Continue;
          end
          else
          begin
            if TRuins(Context).CurrentStanding in [ssCoalitionMilitary..ssNeutral] then
              if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                      * TOwnerMask(aConst.PlanetOwnerMasks.Coalition)
                  = [] then
                Continue;
            if TRuins(Context).CurrentStanding in [ssPiratePassive..ssPirateMilitary] then
              if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                      * TOwnerMask(aConst.PlanetOwnerMasks.PirateClan)
                  = [] then
                Continue;
          end;
        end
        else if Context is TNormalShip then
        begin
          if not (RaceToOwner(TNormalShip(Context).PilotRace)
              in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
            Continue;
        end;
      end;
    end;
    if (Context = nil) and aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction then
      Continue;
    if (aConst.MicroModuleTemplates[ModuleIndex].Priority
        in [MinimumPriority..MaximumPriority]) then
    begin
      Result := ModuleIndex;
      Exit;
    end;
    if Attempts > 1000 then
    begin
      if BestIndex >= 0 then
        Result := BestIndex
      else
        Result := ModuleIndex;
      Exit;
    end;
    if (aConst.MicroModuleTemplates[ModuleIndex].Priority > MaximumPriority)
        and ((BestIndex < 0)
            or (aConst.MicroModuleTemplates[ModuleIndex].Priority < BestPriority)) then
    begin
      BestIndex := ModuleIndex;
      BestPriority := aConst.MicroModuleTemplates[ModuleIndex].Priority;
    end;
    if Attempts mod 99 = 0 then
    begin
      MinimumPriority := Max(0, MinimumPriority - 10);
      MaximumPriority := Min(100, MaximumPriority + 10);
      if (BestIndex >= 0) and (MaximumPriority >= BestPriority) then
      begin
        Result := BestIndex;
        Exit;
      end;
    end;
  until False;
end;
function TGalaxy.SelectMicroModuleForEquipment(
    MinimumPriority, MaximumPriority: Byte;
    Seed: Cardinal;
    Context: TObject;
    Item: Pointer
): Integer;
type
  TModuleOwnerMasks = array[0..2] of TOwnerMask;
var
  Attempts, ModuleIndex, BestIndex, BestPriority: Integer;
  Equipment: TEquipment;
begin
  Attempts := 0;
  Equipment := Item;
  BestIndex := -1;
  BestPriority := 100;
  repeat
    Inc(Attempts);
    ModuleIndex := NextRandomIntRange(0, MicroModuleTemplateCount - 1, Seed);
    if aConst.MicroModuleTemplates[ModuleIndex].SpecialOnly then
      Continue;
    if Context <> nil then
    begin
      if (Context is TKling) and not TShip(Context).HasScriptStateText then
      begin
        if not (Byte((Context as TKling).DominatorSeries)
            in TDominatorSeriesMask(
                aConst.MicroModuleTemplates[ModuleIndex].AllowedDominatorSeriesMask)) then
          Continue;
        if not (Ord(oiDominator)
            in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
          Continue;
        if not aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction
            and (TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                <> [Ord(oiDominator)])
            and (TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                    * [Ord(oiMaloc)..Ord(oiDominator), Ord(oiPirate)]
                <> [Ord(oiMaloc)..Ord(oiDominator), Ord(oiPirate)]) then
          Continue;
      end;
      if aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction then
      begin
        if Context is TPlanet then
        begin
          if not (Ord(TPlanet(Context).OwnerId)
              in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
            Continue;
        end
        else if Context is TRuins then
        begin
          if TRuins(Context).CurrentStanding
              in TStationStandingMask(
                  aConst.FactionStandingMasks[Ord(TRuins(Context).CurrentStar.ControlFaction)]) then
          begin
            if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                    * TModuleOwnerMasks(aConst.PlanetOwnerMasks)[
                        Ord(TRuins(Context).CurrentStar.ControlFaction)]
                = [] then
              Continue;
          end
          else
          begin
            if TRuins(Context).CurrentStanding in [ssCoalitionMilitary..ssNeutral] then
              if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                      * TOwnerMask(aConst.PlanetOwnerMasks.Coalition)
                  = [] then
                Continue;
            if TRuins(Context).CurrentStanding in [ssPiratePassive..ssPirateMilitary] then
              if TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)
                      * TOwnerMask(aConst.PlanetOwnerMasks.PirateClan)
                  = [] then
                Continue;
          end;
        end
        else if Context is TNormalShip then
        begin
          if not (RaceToOwner(TNormalShip(Context).PilotRace)
              in TOwnerMask(aConst.MicroModuleTemplates[ModuleIndex].AllowedHullOwnerMask)) then
            Continue;
        end;
      end;
    end;
    if (Context = nil) and aConst.MicroModuleTemplates[ModuleIndex].RacialRestriction then
      Continue;
    if (aConst.MicroModuleTemplates[ModuleIndex].Priority in [MinimumPriority..MaximumPriority])
        and ((Equipment = nil) or CanInstallMicroModule(ModuleIndex, Equipment)) then
    begin
      Result := ModuleIndex;
      Exit;
    end;
    if (Attempts > 1000)
        and (BestIndex >= 0)
        and ((Equipment = nil) or CanInstallMicroModule(BestIndex, Equipment)) then
    begin
      Result := BestIndex;
      Exit;
    end;
    if Attempts > 2000 then
    begin
      Result := ModuleIndex;
      Exit;
    end;
    if (aConst.MicroModuleTemplates[ModuleIndex].Priority > MaximumPriority)
        and ((BestIndex < 0) or (aConst.MicroModuleTemplates[ModuleIndex].Priority < BestPriority))
        and ((Equipment = nil) or CanInstallMicroModule(ModuleIndex, Equipment)) then
    begin
      BestIndex := ModuleIndex;
      BestPriority := aConst.MicroModuleTemplates[ModuleIndex].Priority;
    end;
    if Attempts mod 99 = 0 then
    begin
      MinimumPriority := Max(0, MinimumPriority - 10);
      MaximumPriority := Min(100, MaximumPriority + 10);
      if (BestIndex >= 0) and (MaximumPriority >= BestPriority) then
      begin
        Result := BestIndex;
        Exit;
      end;
    end;
  until False;
end;
function TGalaxy.SelectHullSeries(OwnerId, HullType, MinimumRarity, MaximumRarity: Byte): Integer;
var
  I, J, Temp: Integer;
  Indices: array of Integer;
begin
  SetLength(Indices, HullSeriesCount);
  for I := 0 to HullSeriesCount - 1 do
  begin
    Indices[I] := I;
    J := NextRandomIntRange(0, HullSeriesCount - 1, RandomState);
    if J < I then
    begin
      Temp := Indices[J];
      Indices[J] := I;
      Indices[I] := Temp;
    end;
  end;
  for I := 0 to HullSeriesCount - 1 do
    if (OwnerId in HullSeriesDefinitions[Indices[I]].AllowedOwners)
        and (HullType in HullSeriesDefinitions[Indices[I]].AllowedShipTypes) then
      if (HullSeriesDefinitions[Indices[I]].Year
              <= RemapClamped(TechLevel, 2, 8, 0, 80) + NextRandomIntRange(0, 20, RandomState))
          and (HullSeriesDefinitions[Indices[I]].ProbabilityWeight >= MinimumRarity)
          and (HullSeriesDefinitions[Indices[I]].ProbabilityWeight <= MaximumRarity) then
        if NextRandomUnitFloat(RandomState)
            <= 1 / HullSeriesDefinitions[Indices[I]].ProbabilityWeight then
        begin
          Result := Indices[I];
          Exit;
        end;
  Result := -1;
end;
function TGalaxy.IsDominatorSeriesUnresolved(Series: TDominatorSeries): Boolean;
begin
  case Series of
    dsBlazer: Result := BlazerSeriesResolvedTurn = 0;
    dsKeller: Result := KellerSeriesResolvedTurn = 0;
    dsTerron: Result := TerronSeriesResolvedTurn = 0;
  else
    Result := False;
  end;
end;
function TGalaxy.HasUnresolvedDominatorSeries(Series: TDominatorSeriesSet): Boolean;
var
  I: Byte;
begin
  Result := False;
  for I := 0 to 2 do
  begin
    if TDominatorSeries(I) in Series then
      case I of
        0: Result := BlazerSeriesResolvedTurn = 0;
        1: Result := KellerSeriesResolvedTurn = 0;
        2: Result := TerronSeriesResolvedTurn = 0;
      end;
    if Result then
      Break;
  end;
end;
procedure TGalaxy.ProcessPlayerSatelliteExploration;
var
  I, Water, Land, Hill: Integer;
  Satellite: TSatellite;
  Wear: Double;
  Changed: Boolean;
  Amount: Integer;
begin
  if GetPlayer <> nil then
  begin
    Changed := False;
    for I := 0 to GetPlayer.Satellites.Count - 1 do
    begin
      Satellite := TSatellite(GetPlayer.Satellites[I]);
      if (Satellite.BrokenFlag = 0) and (Satellite.TargetPlanet <> nil) then
      begin
        with TObject(Satellite.TargetPlanet) as TPlanet do
        begin
          Water := WaterExplored;
          Land := LandExplored;
          Hill := HillExplored;
          WaterExplored := Min(WaterTiles, WaterExplored + Satellite.WaterExplorationRate);
          LandExplored := Min(LandTiles, LandExplored + Satellite.LandExplorationRate);
          HillExplored := Min(HillTiles, HillExplored + Satellite.HillExplorationRate);
          Amount := (WaterExplored - Water) + (LandExplored - Land) + (HillExplored - Hill);
          Inc(GetPlayer.SatelliteTilesExplored, Amount);
          TryAddAchievementProgress('ARCHEOLOGY', Amount);
          if (Water < WaterExplored) or (Land < LandExplored) or (Hill < HillExplored) then
          begin
            Wear := 1;
            if GetPlayer.Satellites.Count > GetPlayer.GetSatelliteLimit then
              Wear := Wear + (GetPlayer.Satellites.Count - GetPlayer.GetSatelliteLimit) * 1.0;
            Changed := True;
          end
          else
            Wear := 0.1;
          GetPlayer.ApplyItemDegradation(
              Satellite,
              idkUse,
              NextRandomUnitFloat(RandomState) * Satellite.WearPerTurn * Wear
          );
        end;
      end;
    end;
    if Changed then
      GetPlayer.RefreshStorageBubbles;
  end;
end;
function TGalaxy.CountExistingSatellites: Integer;
var
  I, J, K: Integer;
  Star: TStar;
  Ship: TShip;
  Item: TItem;
  Stored: TStoredItem;
begin
  Result := GetPlayer.CountStoredItemUnits(nil, 73) + GetPlayer.Satellites.Count;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Items.Count - 1 do
    begin
      Item := TItem(Star.Items[J]);
      if Item is TSatellite then
        Inc(Result);
    end;
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      for K := 0 to Ship.Inventory.Count - 1 do
      begin
        Item := TItem(Ship.Inventory[K]);
        if Item is TSatellite then
          Inc(Result);
      end;
    end;
  end;
  for I := 0 to StoredItems.Count - 1 do
  begin
    Stored := TStoredItem(StoredItems[I]);
    if (Stored.Item <> nil) and (Stored.Item is TSatellite) then
      Inc(Result);
  end;
end;
function TGalaxy.ComputeScaledMiniMoney(ScaleIndex: Byte): Integer;
begin
  Result := Round(AverageRangerCapital * 0.01 * OwnerInfo[ScaleIndex].FuelPriceFactor);
  if Result > 250 then
    Result := Round((Result - 250) * 0.3) + 250;
end;
function TGalaxy.ComputeScaledSmallMoney(ScaleIndex: Byte): Integer;
begin
  Result := Round(AverageRangerCapital * (1 / 65) * OwnerInfo[ScaleIndex].FuelPriceFactor);
  if Result > 1000 then
    Result := Round((Result - 1000) * 0.3) + 1000;
end;
function TGalaxy.ComputeScaledAverageMoney(ScaleIndex: Byte): Integer;
begin
  Result := Round(AverageRangerCapital * 0.025 * OwnerInfo[ScaleIndex].FuelPriceFactor);
  if Result > 5000 then
    Result := Round((Result - 5000) * 0.3) + 5000;
end;
function TGalaxy.ComputeScaledBigMoney(ScaleIndex: Byte): Integer;
begin
  Result := Round(AverageRangerCapital * 0.04 * OwnerInfo[ScaleIndex].FuelPriceFactor);
  if Result > 10000 then
    Result := Round((Result - 10000) * 0.3) + 10000;
end;
function TGalaxy.ComputeScaledHugeMoney(ScaleIndex: Byte): Integer;
begin
  Result := Round(AverageRangerCapital * (1 / 15) * OwnerInfo[ScaleIndex].FuelPriceFactor);
  if Result > 25000 then
    Result := Round((Result - 25000) * 0.3) + 25000;
end;
function TGalaxy.ResolveMoneySizeTag(Tag: WideString; ScaleIndex: Byte): Integer;
begin
  if Tag = 'Zero' then
    Result := 0
  else if Tag = 'Mini' then
    Result := Galaxy.ComputeScaledMiniMoney(ScaleIndex)
  else if Tag = 'Small' then
    Result := Galaxy.ComputeScaledSmallMoney(ScaleIndex)
  else if Tag = 'Average' then
    Result := Galaxy.ComputeScaledAverageMoney(ScaleIndex)
  else if Tag = 'Big' then
    Result := Galaxy.ComputeScaledBigMoney(ScaleIndex)
  else if Tag = 'Huge' then
    Result := Galaxy.ComputeScaledHugeMoney(ScaleIndex)
  else
  begin
    RaiseWideMessage(
        'Error! Указан неправильный формат размера у вещи '
            + Tag
    );
    Result := -1;
  end;
end;
function TGalaxy.GetMiniGoodsQuantity(GoodsType: Byte): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 0.1);
end;
function TGalaxy.GetSmallGoodsQuantity(GoodsType: Byte): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 0.5);
end;
function TGalaxy.GetAverageGoodsQuantity(GoodsType: Byte): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 1);
end;
function TGalaxy.GetBigGoodsQuantity(GoodsType: Byte): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 1.5);
end;
function TGalaxy.GetHugeGoodsQuantity(GoodsType: Byte): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 2.0);
end;
function TGalaxy.GetGoodsQuantityBySize(Size: Byte; GoodsType: Byte): Integer;
begin
  if Size = 0 then
    Result := 0
  else if Size = 1 then
    Result := Galaxy.GetMiniGoodsQuantity(GoodsType)
  else if Size = 2 then
    Result := Galaxy.GetSmallGoodsQuantity(GoodsType)
  else if Size = 3 then
    Result := Galaxy.GetAverageGoodsQuantity(GoodsType)
  else if Size = 4 then
    Result := Galaxy.GetBigGoodsQuantity(GoodsType)
  else if Size = 5 then
    Result := Galaxy.GetHugeGoodsQuantity(GoodsType)
  else
  begin
    RaiseWideMessage(
        'Error! Указан неправильный формат количества товара '
    );
    Result := -1;
  end;
end;
function TGalaxy.ClassifyGoodsQuantity(Quantity: Integer; GoodsType: Byte): Byte;
var
  Distance1, Distance2, Distance3, Distance4, Distance5: Integer;
begin
  if Quantity = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Distance1 := Abs(GetGoodsQuantityBySize(1, GoodsType) - Quantity);
  Distance2 := Abs(GetGoodsQuantityBySize(2, GoodsType) - Quantity);
  Distance3 := Abs(GetGoodsQuantityBySize(3, GoodsType) - Quantity);
  Distance4 := Abs(GetGoodsQuantityBySize(4, GoodsType) - Quantity);
  Distance5 := Abs(GetGoodsQuantityBySize(5, GoodsType) - Quantity);
  if Distance1 < Distance2 then
    Result := 1
  else if Distance2 < Distance3 then
    Result := 2
  else if Distance3 < Distance4 then
    Result := 3
  else if Distance4 < Distance5 then
    Result := 4
  else
    Result := 5;
end;
function TGalaxy.GetMinimumGoodsPrice(GoodsType: Byte): Integer;
begin
  Result := GoodsMarket[GoodsType].MinPrice;
end;
function TGalaxy.GetLowGoodsPrice(GoodsType: Byte): Integer;
begin
  Result := (GoodsMarket[GoodsType].MinPrice + GoodsMarket[GoodsType].AveragePrice) div 2;
end;
function TGalaxy.GetAverageGoodsPrice(GoodsType: Byte): Integer;
begin
  Result := GoodsMarket[GoodsType].AveragePrice;
end;
function TGalaxy.GetHighGoodsPrice(GoodsType: Byte): Integer;
begin
  Result := (GoodsMarket[GoodsType].AveragePrice + GoodsMarket[GoodsType].MaxPrice) div 2;
end;
function TGalaxy.GetMaximumGoodsPrice(GoodsType: Byte): Integer;
begin
  Result := GoodsMarket[GoodsType].MaxPrice;
end;
function TGalaxy.GetGoodsPriceByLevel(Level: Byte; GoodsType: Byte): Integer;
begin
  if Level = 1 then
    Result := Galaxy.GetMinimumGoodsPrice(GoodsType)
  else if Level = 2 then
    Result := Galaxy.GetLowGoodsPrice(GoodsType)
  else if Level = 3 then
    Result := Galaxy.GetAverageGoodsPrice(GoodsType)
  else if Level = 4 then
    Result := Galaxy.GetHighGoodsPrice(GoodsType)
  else if Level = 5 then
    Result := Galaxy.GetMaximumGoodsPrice(GoodsType)
  else
  begin
    RaiseWideMessage(
        'Error! Указан неправильный формат стоимости товара '
    );
    Result := -1;
  end;
end;
function TGalaxy.ClassifyGoodsPrice(Price: Integer; GoodsType: Byte): Byte;
var
  Distance1, Distance2, Distance3, Distance4, Distance5: Integer;
begin
  if Price = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Distance1 := Abs(GetGoodsPriceByLevel(1, GoodsType) - Price);
  Distance2 := Abs(GetGoodsPriceByLevel(2, GoodsType) - Price);
  Distance3 := Abs(GetGoodsPriceByLevel(3, GoodsType) - Price);
  Distance4 := Abs(GetGoodsPriceByLevel(4, GoodsType) - Price);
  Distance5 := Abs(GetGoodsPriceByLevel(5, GoodsType) - Price);
  if Distance1 < Distance2 then
    Result := 1
  else if Distance2 < Distance3 then
    Result := 2
  else if Distance3 < Distance4 then
    Result := 3
  else if Distance4 < Distance5 then
    Result := 4
  else
    Result := 5;
end;
procedure TGalaxy.ProcessStationSpawning;
var
  I, Count: Integer;
  Constellation: TConstellation;
  Kind: TStationType;
begin
  if NextRandomUnitFloat(RandomState) < 0.3 then
    Exit;
  for Kind := rstRangerCenter to rstDominion do
  begin
    Count := 0;
    for I := 0 to Galaxy.Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Galaxy.Constellations[I]);
      if Constellation.Visible and (Constellation.ShipTypeCounts[Ord(Kind)] > 0) then
        Inc(Count);
    end;
    if (Count = 0) and (NextRandomUnitFloat(RandomState) < 0.3) then
    begin
      ReplenishStationType(Kind);
      Exit;
    end;
  end;
  ReplenishStationType(TStationType((CurrentTurn + 100) mod 7 + 6));
end;
procedure TGalaxy.ReplenishStationType(StationType: TStationType);
const
  StationMask = [Ord(rstRangerCenter)..Ord(rstDominion)];
  MilitaryBaseMask = [Ord(rstMilitaryBase)];
  PirateBaseMask = [Ord(rstPirateBase)];
var
  I, J: Integer;
  Hostile, Assigned: Boolean;
  Constellation: TConstellation;
  Star: TStar;
  Station: TRuins;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if (Constellation.Id <> 20)
        and (Constellation.ShipTypeCounts[Ord(StationType)] <= 0)
        and (Constellation.CountShipsByTypeMask(StationMask) < Constellation.Stars.Count)
        and (Constellation.ShipTypeCounts[stKling] <= 0) then
    begin
      Hostile := False;
      for J := 0 to Constellation.Stars.Count - 1 do
      begin
        Star := Constellation.Stars[J];
        if (Star.ControlFaction = sfDominators) or (Star.Status.CustomFaction <> '') then
          Hostile := True;
      end;
      if not Hostile then
      begin
        Star :=
            Constellation.Stars[NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState)];
        if (Star.Battle = 0)
            and (StationDefaultStandings[Ord(StationType)]
                in TShipTypeMask(FactionStandingMasks[Ord(Star.ControlFaction)]))
            and (GetPlayer.CurrentStar <> Star)
            and (Star.DaysSincePlayerVisit >= 70)
            and (Star.CountShipsByTypeMask(StationMask) <= 1)
            and ((StationType <> rstPirateBase)
                or (Star.CountShipsByTypeMask(MilitaryBaseMask) <= 0))
            and ((StationType <> rstMilitaryBase)
                or (Star.CountShipsByTypeMask(PirateBaseMask) <= 0)) then
        begin
          if StationType = rstMilitaryBase then
          begin
            Assigned := False;
            for J := 0 to Constellation.Stars.Count - 1 do
              if HasMilitaryBaseAssignedToStar(TStar(Constellation.Stars[J])) then
              begin
                Assigned := True;
                Break;
              end;
            if Assigned then
              Continue;
          end;
          if StationType = rstDominion then
          begin
            Assigned := False;
            for J := 0 to Constellation.Stars.Count - 1 do
              if TStar(Constellation.Stars[J]).Dominion <> nil then
              begin
                Assigned := True;
                Break;
              end;
            if Assigned then
              Continue;
          end;
          Station := TRuins.Create;
          Station.Init(StationType, Star, '');
          if CoalitionDefeatedTurn = 0 then
            Galaxy.AddPlanetNewsWithPlayerBubble(
                41,
                FormatText3(
                    PickLocalizedTextVariant(
                        'GalaxyNews.CreateNewObject.' + ShipTypeNames[Ord(StationType)].Name,
                        GenerationSeed * (Galaxy.CurrentTurn div 10)
                    ),
                    '<color=255,240,100>',
                    '<Name>',
                    Station.GetName,
                    '<Star>',
                    Star.Name,
                    '<Sector>',
                    Star.Constellation.GetName
                )
            );
          Exit;
        end;
      end;
    end;
  end;
end;
procedure TGalaxy.ProcessDominatorResearchProgress;
var
  Series: TDominatorSeries;
  Progress: Single;
  News: WideString;
begin
  if ((DominatorResearch[0].Progress < 100)
          or (DominatorResearch[1].Progress < 100)
          or (DominatorResearch[2].Progress < 100))
      and (ShipTypeCounts[Ord(rstScienceBase)] > 0) then
    for Series := dsBlazer to dsTerron do
      if DominatorResearch[Ord(Series)].Progress < 100 then
      begin
        Progress := DominatorResearch[Ord(Series)].Progress + GetDominatorResearchRate(Series);
        if CurrentTurn mod NextRandomIntRange(2, 5, RandomState) = 0 then
          DominatorResearch[Ord(Series)].Material :=
              Max(
                  0,
                  DominatorResearch[Ord(Series)].Material
                      - NextRandomIntRange(
                          1,
                          GalaxyDifficultyTuning[DifficultyLevels[2]]
                              .MaximumResearchMaterialConsumption,
                          RandomState)
              );
        if Progress >= 100 then
        begin
          case Series of
            dsBlazer: News := 'Programms.LogicalNegation.GalaxyNews';
            dsKeller: News := 'Programms.Dematerial.GalaxyNews';
            dsTerron: News := 'Programms.Energotron.GalaxyNews';
          end;
          Galaxy.AddPlanetNewsWithPlayerBubble(
              43,
              PickLocalizedTextVariant(News, GenerationSeed * (Galaxy.CurrentTurn div 10))
          );
          Inc(GetPlayer.AchievementStats.CompletedResearchPrograms);
          GetPlayer.AchievementStats.CheckScienceAchievement;
        end;
        DominatorResearch[Ord(Series)].Progress := Min(100, Progress);
      end;
end;
function TGalaxy.IsDominatorResearchComplete(Series: TDominatorSeriesSet): Boolean;
var
  I: Byte;
begin
  Result := True;
  for I := 0 to 2 do
    if (TDominatorSeries(I) in Series) and (DominatorResearch[I].Progress < 100) then
    begin
      Result := False;
      Break;
    end;
end;
function TGalaxy.GetDominatorResearchRate(Series: TDominatorSeries): Single;
var
  Efficiency: Integer;
begin
  Efficiency := Integer(GetDominatorResearchEfficiency(Series)) and $7F;
  Result :=
      RemapClamped(
              Efficiency,
              0,
              100,
              0.00001,
              GalaxyDifficultyTuning[DifficultyLevels[2]].MaximumDominatorResearchRate)
          * DominatorResearchRateMultipliers[Ord(Series)];
end;
function TGalaxy.GetDominatorResearchEfficiency(Series: TDominatorSeries): Byte;
begin
  Result := Trunc(RemapClamped(DominatorResearch[Ord(Series)].Material, 0, 300, 20, 100));
end;
function TGalaxy.FindStationByTypeAndIndex(Index: Integer; StationType: TStationType): Pointer;
var
  Star: TStar;
  Ship: TShip;
  I, J, Number: Integer;
begin
  Result := nil;
  Number := 1;
  if ShipTypeCounts[Ord(StationType)] > 0 then
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[I]);
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J]);
        if Ship.TypeId = Byte(StationType) then
        begin
          if Number = Index then
          begin
            Result := Ship;
            Exit;
          end;
          Inc(Number);
        end;
      end;
    end;
end;
procedure TGalaxy.TryAwardDepositPrize;
var
  Deposit, Chance, Roll: Integer;
  Station: TRuins;
  Item: TItem;
  Text: WideString;
begin
  if (GetPlayer.DepositAmount <> 0)
      and (GetPlayer.DepositDayCount <> 0)
      and (GetPlayer.DepositDayCount mod 365 = 0) then
  begin
    Station :=
        TObject(
                FindStationByTypeAndIndex(
                    SeededRandomIntRange(
                        1,
                        ShipTypeCounts[Ord(rstBusinessCenter)],
                        Galaxy.GenerationSeed + Galaxy.CurrentTurn div 33
                    ),
                    rstBusinessCenter
                ))
            as TRuins;
    if Station <> nil then
    begin
      Text :=
          PickLocalizedTextVariant(
              'GalaxyNews.BK.DepositPrizeLose',
              Station.Seed * (Galaxy.CurrentTurn div 10)
          );
      Chance := 30 + (GetPlayer.DepositDayCount div 365) * 10;
      Roll := SeededRandomIntRange(1, 100, Station.Seed + Galaxy.CurrentTurn div 7);
      if Roll < Chance then
      begin
        Deposit := GetPlayer.ComputeDepositAccruedValue;
        Item := Station.FindMostExpensiveShopItem(Round(Deposit * 0.1), Round(Deposit * 1.0));
        if Item <> nil then
        begin
          Station.EquipmentShop.Delete(Station.EquipmentShop.IndexOf(Item));
          GetPlayer.AddItemToPlayerStorage(Item, Station, -1);
          GetPlayer.RefreshStorageBubbles;
          Text :=
              PickLocalizedTextVariant(
                  'GalaxyNews.BK.DepositPrizeWin',
                  Station.Seed * (Galaxy.CurrentTurn div 10)
              );
          ReplaceTextToken(Text, '<Item>', Item.GetDisplayName, '<color=255,240,100>');
        end;
      end;
      ReplaceTextToken(Text, '<BKName>', Station.GetFullName(' '), '<color=255,240,100>');
      ReplaceTextToken(Text, '<Star>', Station.CurrentStar.Name, '<color=255,240,100>');
      AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '');
    end;
  end;
end;
procedure TGalaxy.ProcessBankDebtAndDeposits;
const
  AffectedShipTypes = [htPirate];
  AffectedOwners = [0..7];
var
  News: WideString;
  OldDebt, Penalty: Integer;
  Event: TGalaxyEvent;
begin
  if GetPlayer = nil then
    Exit;
  if Self.ShipTypeCounts[Ord(rstBusinessCenter)] > 0 then
  begin
    if (GetPlayer.DepositAmount > 0) and (GetPlayer.DebtAmount = 0) then
    begin
      Inc(GetPlayer.DepositDayCount);
      Self.TryAwardDepositPrize;
    end;
    if (GetPlayer.DebtAmount > 0) and (GetPlayer.DebtDueTurn <= Galaxy.CurrentTurn) then
    begin
      Inc(GetPlayer.DebtDefaultCount);
      if GetPlayer.DebtDefaultCount = 1 then
        TryAddAchievementProgress('CREDITOR', 1);
      OldDebt := GetPlayer.DebtAmount;
      Penalty :=
          RoundAndTruncateToTens(
              Min(GetPlayer.DebtAmount * 0.5 * GetPlayer.DebtDefaultCount, GetPlayer.Wealth div 8)
          );
      GetPlayer.DebtAmount := Min(100000000, GetPlayer.DebtAmount + Penalty);
      GetPlayer.DebtDueTurn :=
          Galaxy.CurrentTurn
              + System.Round(
                  RemapClamped(SeededRandomUnitFloat(Galaxy.CurrentTurn div 80), 0, 1, 0.7, 1.5)
                      * 300);
      if GetPlayer.DebtDefaultCount < 3 then
        News :=
            PickLocalizedTextVariant(
                'GalaxyNews.BK.DebtInfo',
                (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
            )
      else
      begin
        News :=
            PickLocalizedTextVariant(
                'GalaxyNews.BK.DebtInfoContinue',
                (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
            );
        GetPlayer.ChangeGlobalRelations(nil, rcmDecrease, 50, AffectedShipTypes, AffectedOwners);
      end;
      ReplaceTextToken(
          News,
          '<OldMoney>',
          WideString(SysUtils.IntToStr(OldDebt)),
          '<color=255,240,100>'
      );
      ReplaceTextToken(
          News,
          '<Penalty>',
          WideString(SysUtils.IntToStr(Penalty)),
          '<color=255,240,100>'
      );
      ReplaceTextToken(
          News,
          '<NewMoney>',
          WideString(SysUtils.IntToStr(GetPlayer.DebtAmount)),
          '<color=255,240,100>'
      );
      ReplaceTextToken(
          News,
          '<NewDate>',
          Galaxy.FormatTurnDate(GetPlayer.DebtDueTurn),
          '<color=255,240,100>'
      );
      AddOrUpdatePlayerBubble(0, Self.CurrentTurn, News, '');
    end;
  end
  else if (GetPlayer.DebtAmount > 0) or (GetPlayer.DepositAmount > 0) then
  begin
    News :=
        PickLocalizedTextVariant(
            'GalaxyNews.BK.DeadAllBKStart',
            (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
        );
    if GetPlayer.DebtAmount > 0 then
    begin
      News :=
          News
              + #13#10
              + FormatText1(
                  PickLocalizedTextVariant(
                      'GalaxyNews.BK.DeadAllBKDebt',
                      (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Money>',
                  WideString(SysUtils.IntToStr(GetPlayer.DebtAmount)));
      Event := AddGalaxyEvent('PlayerDebtNullified');
      Event.AddData(GetPlayer.DebtAmount);
    end;
    GetPlayer.DebtAmount := 0;
    GetPlayer.DebtDueTurn := 0;
    GetPlayer.DebtDefaultCount := 0;
    if GetPlayer.DepositAmount > 0 then
      News :=
          News
              + #13#10
              + FormatText1(
                  PickLocalizedTextVariant(
                      'GalaxyNews.BK.DeadAllBKDeposit',
                      (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Money>',
                  WideString(SysUtils.IntToStr(GetPlayer.DepositAmount)));
    GetPlayer.DepositAmount := 0;
    GetPlayer.DepositStartTurn := 0;
    GetPlayer.DepositDayCount := 0;
    GetPlayer.DepositInterestRate := 0;
    AddOrUpdatePlayerBubble(0, Self.CurrentTurn, News, '');
  end;
end;
procedure TGalaxy.ProcessRangerCenterNewYearEvent;
var
  Year, Month, Day: Word;
  Text: WideString;
  Station: TRuins;
  Item: TMicroModule;
  Minimum, Maximum: Integer;
  Event: TGalaxyEvent;
begin
  if GetPlayer <> nil then
    if ShipTypeCounts[Ord(rstRangerCenter)] > 0 then
    begin
      if Galaxy.CurrentTurn > 300 then
      begin
        DecodeDate(GameTurnToDateTime(Galaxy.CurrentTurn - 300), Year, Month, Day);
        if (Day = 31) and (Month = 12) then
        begin
          Station :=
              TObject(
                      FindStationByTypeAndIndex(
                          SeededRandomIntRange(
                              1,
                              ShipTypeCounts[Ord(rstRangerCenter)],
                              Galaxy.GenerationSeed + Galaxy.CurrentTurn
                          ),
                          rstRangerCenter
                      ))
                  as TRuins;
          if Station <> nil then
          begin
            Item := TMicroModule.Create;
            Minimum := 70;
            Dec(Minimum, Round(RemapClamped(Year, 3301, 3311, 0, 10)));
            Dec(
                Minimum,
                Round(RemapClamped(GetPlayer.PlaceInRating, 1, Galaxy.Rangers.Count, 10, 0))
            );
            Dec(Minimum, Round(RemapClamped(ShortInt(Ord(GetPlayer.Rank)), 0, 7, 0, 10)));
            Dec(Minimum, Galaxy.ScaleIntByTechLevel(0, 20));
            Inc(Minimum, SeededRandomIntRange(-10, 10, Galaxy.GenerationSeed + Station.Seed));
            Minimum := Max(1, Min(Minimum, 100));
            Maximum := 100;
            Item.Init(
                SelectMicroModule(
                    Minimum,
                    Maximum,
                    Galaxy.GenerationSeed + Station.Seed + Galaxy.CurrentTurn,
                    Station
                )
            );
            Item.OwnerId := RaceToOwner(GetPlayer.PilotRace);
            Event := AddGalaxyEvent('PlayerReceivesMMOnNewYear');
            Event.AddData(Item.Id);
            Event.AddData(Item.MicroModuleIndex - 1);
            GetPlayer.AddItemToPlayerStorage(Item, Station, -1);
            GetPlayer.RefreshStorageBubbles;
            Text :=
                PickLocalizedTextVariant(
                    'GalaxyNews.RC.NewYear',
                    GenerationSeed * (Galaxy.CurrentTurn div 10)
                );
            ReplaceTextToken(Text, '<RCName>', Station.GetFullName(' '), '<color=255,240,100>');
            ReplaceTextToken(Text, '<Star>', Station.CurrentStar.Name, '<color=255,240,100>');
            ReplaceTextToken(Text, '<Year>', IntToStr(Year + 1), '<color=255,240,100>');
            ReplaceTextToken(Text, '<Item>', Item.GetDisplayName, '<color=255,240,100>');
            AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '');
          end;
        end;
      end;
    end
    else if GetPlayer.BaseNodes > 0 then
    begin
      Text :=
          FormatText1(
              PickLocalizedTextVariant(
                  'GalaxyNews.RC.DeadBaseNod',
                  GenerationSeed * (Galaxy.CurrentTurn div 10)
              ),
              '<color=255,240,100>',
              '<Nod>',
              IntToStr(GetPlayer.BaseNodes)
          );
      Event := AddGalaxyEvent('PlayerNodesNullified');
      Event.AddData(GetPlayer.BaseNodes);
      GetPlayer.BaseNodes := 0;
      AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '');
    end;
end;
function TGalaxy.TryCreateLiberationGroup: Boolean;
var
  i, Index, j, k, ShipCount: Integer;
  Star: TStar;
  Ship: TShip;
  Planet: TPlanet;
  Group: TGroup;
  Constellation: TConstellation;
  GroupStrength, EnemyStrength: Double;
  HasSubtypeOne: Boolean;
  EmergencyControlPercent: Byte;
begin
  Result := False;
  EmergencyControlPercent := 5;
  if (Galaxy.GetFactionControlPercent(Ord(sfCoalition)) > 90)
      and (NextRandomUnitFloat(Self.RandomState) < 0.5)
      and (Galaxy.WarDeltaWin[0] > 3) then
    Exit;
  if (Galaxy.WarDeltaWin[0] > 5) and (NextRandomUnitFloat(Self.RandomState) < 0.8) then
    Exit;
  Constellation := nil;
  Index := NextRandomIntRange(0, Self.Constellations.Count - 1, Self.RandomState);
  for i := 0 to Self.Constellations.Count - 1 do
  begin
    IncrementWrapped(Index, 0, Self.Constellations.Count - 1);
    Constellation := TConstellation(Self.Constellations[Index]);
    if not Constellation.HasDominatorPresence and not Constellation.HasPirateClanPresence then
      Break;
  end;
  Group := TGroup.Create;
  Self.LiberationGroups.Add(Group);
  if Group.SelectLiberationTarget then
  begin
    EnemyStrength := 0;
    for i := 0 to Group.TargetStar.Ships.Count - 1 do
    begin
      Ship := TShip(Group.TargetStar.Ships[i]);
      if Ship.IsOutsideStarSpace then
        Continue;
      if Group.TargetStar.Status.CustomFaction <> '' then
      begin
        if Ship.CurrentStanding <> ssCustom then
          Continue;
      end
      else if Group.TargetStar.ControlFaction = sfDominators then
      begin
        if Ship.CurrentStanding <> ssDominator then
          Continue;
      end
      else if Group.TargetStar.ControlFaction = sfPirates then
      begin
        if not (Ship.CurrentStanding in [ssPirateActive..ssPirateMilitary]) then
          Continue;
      end;
      EnemyStrength := EnemyStrength + Ship.Strength;
    end;
    ShipCount := 0;
    GroupStrength := 0;
    HasSubtypeOne := False;
    Index := NextRandomIntRange(0, Constellation.Stars.Count - 1, Self.RandomState);
    for i := 0 to Constellation.Stars.Count - 1 do
    begin
      IncrementWrapped(Index, 0, Constellation.Stars.Count - 1);
      Star := TStar(Constellation.Stars[Index]);
      if (Star.ControlFaction = sfCoalition)
          and (Star.Battle = 0)
          and (Star.Status.CustomFaction = '')
          and (not Star.HasLiberationGroupOrder
              or (Galaxy.GetFactionControlPercent(Ord(sfCoalition))
                  <= EmergencyControlPercent)) then
      begin
        for j := 0 to Star.Planets.Count - 1 do
        begin
          Planet := TPlanet(Star.Planets[j]);
          if Planet.IsCoalitionOwned then
            for k := NextRandomIntRange(0, 1, Planet.RandomState) to Planet.Warriors.Count - 1 do
            begin
              Ship := TShip(Planet.Warriors[k]);
              if (Ship.ScriptShip = nil)
                  and (Ship.CurrentPlanet = Planet)
                  and (Star.Ships.IndexOf(Ship) < 0)
                  and (Ship.LiberationGroup = nil) then
              begin
                Ship.LiberationGroup := Group;
                Star.Ships.Add(Ship);
                Group.AddShip(Ship);
                Inc(ShipCount);
                if TWarrior(Ship).WarriorType = wtFlagship then
                begin
                  GroupStrength := 0.5 * Ship.Strength + GroupStrength;
                  if not HasSubtypeOne then
                    EnemyStrength := 1.2 * EnemyStrength;
                  HasSubtypeOne := True;
                end
                else
                  GroupStrength := GroupStrength + Ship.Strength;
                if (ShipCount >= 5) and ((GroupStrength >= EnemyStrength) or (ShipCount >= 30)) then
                begin
                  Result := Group.BuildLiberationOrders;
                  Exit;
                end;
              end;
            end;
        end;
      end;
    end;
    if (GroupStrength <= EnemyStrength) and (ShipCount < 30) then
      for i := 0 to Constellation.Stars.Count - 1 do
      begin
        IncrementWrapped(Index, 0, Constellation.Stars.Count - 1);
        Star := TStar(Constellation.Stars[Index]);
        if (Star.ControlFaction = sfCoalition)
            and (Star.Battle = 0)
            and (Star.Status.CustomFaction = '')
            and (not Star.HasLiberationGroupOrder
                or (Galaxy.GetFactionControlPercent(Ord(sfCoalition))
                    <= EmergencyControlPercent)) then
        begin
          for j := 0 to Star.Ships.Count - 1 do
          begin
            Ship := TShip(Star.Ships[j]);
            if (Ship.TypeId = stWarrior)
                and (Ship.HomePlanet.CurrentStar = Star)
                and not Ship.IsOutsideStarSpace
                and (Ship.ScriptShip = nil)
                and (Ship.Order in [soNone, soMove])
                and (Ship.AbsoluteScriptOrder = 0)
                and (Ship.LiberationGroup = nil) then
            begin
              Ship.LiberationGroup := Group;
              Group.AddShip(Ship);
              Inc(ShipCount);
              if TWarrior(Ship).WarriorType = wtFlagship then
              begin
                GroupStrength := 0.5 * Ship.Strength + GroupStrength;
                if not HasSubtypeOne then
                  EnemyStrength := 1.2 * EnemyStrength;
                HasSubtypeOne := True;
              end
              else
                GroupStrength := GroupStrength + Ship.Strength;
            end;
          end;
        end;
      end;
    if (ShipCount >= 1)
        and (Galaxy.GetFactionControlPercent(Ord(sfCoalition)) <= EmergencyControlPercent) then
    begin
      if GetPlayer <> nil then
        GroupStrength := GetPlayer.Strength * 2 + GroupStrength;
      if (10 * GroupStrength >= NextRandomIntRange(3, 10, Self.RandomState) * EnemyStrength)
          or (NextRandomIntRange(0, 700, Self.RandomState) = 0) then
      begin
        Result := Group.BuildLiberationOrders;
        Exit;
      end;
      Group.Disband;
    end
    else
    begin
      if ShipCount >= 5 then
      begin
        Result := Group.BuildLiberationOrders;
        Exit;
      end;
      Group.Disband;
    end;
  end;
  Result := False;
end;
function TGalaxy.TryDispatchMilitaryBaseToEnemyStar: Boolean;
var
  I, J, Count: Integer;
  Star, Target: TStar;
  Ship: TShip;
  Station: TRuins;
  Planet: TPlanet;
  Warrior: TWarrior;
  Text: WideString;
  Turn: Integer;
begin
  Result := False;
  if (FindMilitaryBaseInTransit <> nil) or (CurrentTurn < 300) or (CurrentTurn mod 133 <> 0) then
    Exit;
  if SeededRandomUnitFloat(GenerationSeed * CurrentTurn + CountStarsInBattle) < 0.5 then
    Exit;
  Station := nil;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if (Star.ShipTypeCounts[Ord(rstMilitaryBase)] <> 0)
        and (not Star.Constellation.HasDominatorPresence)
        and (SeededRandomUnitFloat((GenerationSeed + I) * CurrentTurn * Star.GenerationSeed)
            >= 0.2) then
    begin
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J]);
        if Ship.TypeId = Byte(rstMilitaryBase) then
        begin
          Station := Ship as TRuins;
          if Station.FlyToStar <> nil then
            Station := nil
          else if Station.HasScriptControl then
            Station := nil;
        end;
        if Station <> nil then
          Break;
      end;
      if Station <> nil then
        Break;
    end;
  end;
  if Station = nil then
    Exit;
  Count := 0;
  for I := 0 to Galaxy.Stars.Count - 1 do
    Inc(Count, TStar(Galaxy.Stars[I]).ShipTypeCounts[Ord(rstMilitaryBase)]);
  if Count < 2 then
    Exit;
  Target := nil;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if Star.IsConstellationVisible
        and (Star.Constellation.Id <> 20)
        and (Star.Constellation.ShipTypeCounts[Ord(rstMilitaryBase)] <= 0)
        and (Star.ControlFaction = sfDominators)
        and (Star.Ships.Count <= Star.ShipTypeCounts[stKling])
        and (Star.ShipTypeCounts[stKling] >= 5)
        and (not HasMilitaryBaseAssignedToStar(Star))
        and (not HasLiberationGroupTargetingStar(Star))
        and (SeededRandomUnitFloat((GenerationSeed + I) * CurrentTurn * Star.GenerationSeed) >= 0.7)
        and (PointDistance(Station.CurrentStar.Position, Star.Position)
            >= ScaleIntByTechLevel(30, 60)) then
    begin
      Target := Star;
      Break;
    end;
  end;
  if Target = nil then
    Exit;
  Planet := TObject(Station.CurrentStar.FindFastestResearchPlanet) as TPlanet;
  if not Planet.IsCoalitionOwned then
    Exit;
  for I := 1 to SeededRandomIntRange(4, 6, (CurrentTurn + 0) * Planet.GenerationSeed) do
  begin
    if (I = 1) and (Galaxy.RangerSpawnQuotas[Planet.RaceId] > 0) then
      Warrior := TObject(Planet.BuyFlagship(200)) as TWarrior
    else
      Warrior := TObject(Planet.BuyWarrior(200)) as TWarrior;
    Warrior.Position := Station.Position;
    Warrior.CurrentPlanet := nil;
    Warrior.DockedTo := Station;
    Planet.CurrentStar.Ships.Add(Warrior);
  end;
  Turn := CurrentTurn + SeededRandomIntRange(30, 40, (CurrentTurn + 0) + Planet.GenerationSeed);
  // The original + 0 is an evaluation-order artifact; this is a star pointer.
  Station.FlyToStar := Target;
  Station.FlyDate := Turn + 0;
  Text :=
      PickLocalizedTextVariant(
          'GalaxyNews.WBGoToEnemyStar.Create',
          GenerationSeed * (Galaxy.CurrentTurn div 10)
      );
  ReplaceTextToken(Text, '<WB>', Station.Name, '<color=255,240,100>');
  ReplaceTextToken(Text, '<WBStar>', Station.CurrentStar.Name, '<color=255,240,100>');
  ReplaceTextToken(Text, '<StarEnemy>', Target.Name, '<color=255,240,100>');
  ReplaceTextToken(
      Text,
      '<WBSector>',
      Station.CurrentStar.Constellation.GetName,
      '<color=255,240,100>'
  );
  ReplaceTextToken(Text, '<SectorEnemy>', Target.Constellation.GetName, '<color=255,240,100>');
  ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Turn), '<color=255,240,100>');
  Galaxy.AddPlanetNewsWithPlayerBubble(45, Text);
  Result := True;
end;
function TGalaxy.FindMilitaryBaseInTransit: Pointer;
var
  I, J: Integer;
  Star: TStar;
  Ship: TShip;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if (Ship.TypeId = Byte(rstMilitaryBase))
          and ((Ship as TRuins).FlyToStar <> nil)
          and (not Ship.InNormalSpace or ((Ship as TRuins).FlyToStar <> Ship.CurrentStar)) then
      begin
        Result := Ship;
        Exit;
      end;
    end;
  end;
  Result := nil;
end;
function TGalaxy.HasMilitaryBaseAssignedToStar(Star: TStar): Boolean;
var
  I, J: Integer;
  SystemStar: TStar;
  Ship: TShip;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    SystemStar := TStar(Galaxy.Stars[I]);
    for J := 0 to SystemStar.Ships.Count - 1 do
    begin
      Ship := TShip(SystemStar.Ships[J]);
      if (Ship.TypeId = Byte(rstMilitaryBase))
          and ((Ship as TRuins).FlyToStar = (TObject(Star) as TStar)) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;
function TGalaxy.HasLiberationGroupTargetingStar(Star: TStar): Boolean;
var
  I: Integer;
  Group: TGroup;
begin
  for I := LiberationGroups.Count - 1 downto 0 do
  begin
    Group := LiberationGroups[I];
    if (Group.Route[3].Target as TStar) = Star then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
procedure TGalaxy.AssignSpecialStationService;
var
  i, StarCount, j, ShipCount: Integer;
  Star: TStar;
  Ship: TShip;
  Station: TRuins;
  PirateActive, PirateCandidate: TRuins;
  ScienceActive, ScienceCandidate: TRuins;
  MilitaryActive, MilitaryCandidate: TRuins;
  Count: Integer;
  Seed: Cardinal;
  Candidates: array[0..2] of TRuins;
begin
  if Self.CurrentTurn and 15 <> 0 then
    Exit;
  if Self.NextSpecialStationServiceTurn = 0 then
    Self.NextSpecialStationServiceTurn :=
        SeededRandomIntRange(0, 365, GetPlayer.Id xor Self.GenerationSeed) + 2125;
  if Self.CurrentTurn < Self.NextSpecialStationServiceTurn then
    Exit;
  Seed := GetPlayer.Id xor Self.GenerationSeed xor Galaxy.CurrentTurn;
  Self.NextSpecialStationServiceTurn :=
      NextRandomIntRange(0, 365, Seed) + (Self.NextSpecialStationServiceTurn + 365);
  PirateActive := nil;
  PirateCandidate := nil;
  ScienceActive := nil;
  ScienceCandidate := nil;
  MilitaryActive := nil;
  MilitaryCandidate := nil;
  StarCount := Self.Stars.Count;
  for i := 0 to StarCount - 1 do
  begin
    Star := TStar(Self.Stars[i]);
    ShipCount := Star.Ships.Count;
    for j := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Star.Ships[j]);
      if Ship.TypeId = Byte(rstPirateBase) then
      begin
        Station := Ship as TRuins;
        if Station.SpecialServiceActive then
          PirateActive := Station
        else if (Station.TypeNameOverrideKey = '')
            and (Station.ScriptShip = nil)
            and TShip(Station).InNormalSpace
            and ((PirateCandidate = nil) or (NextRandomIntRange(0, 100, Seed) < 50)) then
          PirateCandidate := Station;
      end
      else if Ship.TypeId = Byte(rstScienceBase) then
      begin
        Station := Ship as TRuins;
        if Station.SpecialServiceActive then
          ScienceActive := Station
        else if (Station.TypeNameOverrideKey = '')
            and (Station.ScriptShip = nil)
            and TShip(Station).InNormalSpace
            and ((ScienceCandidate = nil) or (NextRandomIntRange(0, 100, Seed) < 50)) then
          ScienceCandidate := Station;
      end
      else if Ship.TypeId = Byte(rstMilitaryBase) then
      begin
        Station := Ship as TRuins;
        if Station.SpecialServiceActive then
          MilitaryActive := Station
        else if (Station.TypeNameOverrideKey = '')
            and (Station.ScriptShip = nil)
            and TShip(Station).InNormalSpace
            and ((MilitaryCandidate = nil) or (NextRandomIntRange(0, 100, Seed) < 50)) then
          MilitaryCandidate := Station;
      end;
    end;
  end;
  Count := 0;
  if (PirateActive = nil) and (PirateCandidate <> nil) then
  begin
    Candidates[Count] := PirateCandidate;
    Inc(Count);
  end;
  if (ScienceActive = nil) and (ScienceCandidate <> nil) then
  begin
    Candidates[Count] := ScienceCandidate;
    Inc(Count);
  end;
  if (MilitaryActive = nil) and (MilitaryCandidate <> nil) then
  begin
    Candidates[Count] := MilitaryCandidate;
    Inc(Count);
  end;
  if Count > 0 then
  begin
    Station := Candidates[NextRandomIntRange(0, Count * 100 - 1, Seed) div 100];
    Station.SpecialServiceActive := True;
    Self.AddPlanetNewsWithPlayerBubble(
        44,
        FormatText3(
            PickLocalizedTextVariant(
                'FormRuins.' + Station.GetTypeNameKey + '.SpecialShip.News',
                (Galaxy.CurrentTurn div 10) * Self.GenerationSeed
            ),
            '<color=255,240,100>',
            '<Name>',
            Station.GetName,
            '<Star>',
            Station.CurrentStar.Name,
            '<Sector>',
            TConstellation(Station.CurrentStar.Constellation).GetName
        )
    );
  end;
end;
procedure TGalaxy.ApplyWingmanLeadershipPenalty;
var
  I, Excess: Integer;
  Leader, Ship: TShip;
begin
  if WingmenPendingLeadershipPenalty <> nil then
    while WingmenPendingLeadershipPenalty.Count > 0 do
    begin
      Leader :=
          TShip(WingmenPendingLeadershipPenalty[WingmenPendingLeadershipPenalty.Count - 1])
              .PartnerShip;
      if Leader = nil then
        WingmenPendingLeadershipPenalty.Delete(WingmenPendingLeadershipPenalty.Count - 1)
      else
      begin
        Excess := 0;
        for I := WingmenPendingLeadershipPenalty.Count - 1 downto 0 do
          if TShip(WingmenPendingLeadershipPenalty[I]).PartnerShip = Leader then
            Inc(Excess);
        Excess := Excess - (Integer(Leader.GetEffectiveSkillLevel(psLeadership)) and 127);
        for I := WingmenPendingLeadershipPenalty.Count - 1 downto 0 do
          if TShip(WingmenPendingLeadershipPenalty[I]).PartnerShip = Leader then
          begin
            if Excess > 0 then
            begin
              Ship := WingmenPendingLeadershipPenalty[I];
              if Ship.PartnershipDaysRemaining > 0 then
                Ship.PartnershipDaysRemaining :=
                    Max(1, Ship.PartnershipDaysRemaining - (Excess + 1) div 2);
            end;
            WingmenPendingLeadershipPenalty.Delete(I);
          end;
      end;
    end;
end;
procedure TGalaxy.ProcessCoalitionDefeat;
var
  I, J: Integer;
  Ship: TShip;
  Star: TStar;
  Text: WideString;
  Bubble: TMessagePlayer;
  Contested: Boolean;
  CoalitionStrength, PirateStrength: Single;
begin
  if (GetPlayer <> nil)
      and (CountFactionStars(Ord(sfCoalition)) <= 0)
      and (GetPlayer.OwnerId = Byte(oiPirate))
      and (PirateWinType <> 3)
      and (CoalitionDefeatedTurn = 0)
      and ((MainPiratePlanet = nil) or (GetPlayer.CurrentStar <> MainPiratePlanet.CurrentStar)) then
  begin
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := TStar(Galaxy.Stars[I]);
      Contested := False;
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J + 0]);
        if Ship.CurrentStanding = ssCoalitionMilitary then
          Exit;
        if (Ship.OwnerId in TOwnerMask(PlanetOwnerMasks.Coalition))
            and (Ship is TNormalShip)
            and (Ship.OwnerId <> Byte(oiPirate)) then
        begin
          if (Star.ControlFaction = sfDominators) or (Star.Status.CustomFaction <> '') then
            Exit;
          if Ship.CurrentStanding in [ssCoalitionMilitary, ssCoalitionActive] then
          begin
            Contested := True;
            Break;
          end;
        end;
      end;
      if Contested then
      begin
        CoalitionStrength := 0;
        PirateStrength := 0;
        for J := 0 to Star.Ships.Count - 1 do
        begin
          Ship := TShip(Star.Ships[J + 0]);
          if Ship.CurrentStanding in [ssCoalitionMilitary, ssCoalitionActive] then
            CoalitionStrength := CoalitionStrength + Ship.Strength;
          if Ship.CurrentStanding in [ssPirateActive, ssPirateMilitary] then
            PirateStrength := PirateStrength + Ship.Strength;
        end;
        if 3 * CoalitionStrength > PirateStrength then
          Exit;
      end;
    end;
    Bubble := FindPlayerBubbleByKey('BlazerWin', False);
    if (Bubble <> nil) and (Bubble.Kind = 3) then
    begin
      Bubble.Kind := 4;
      Bubble.WasRead := False;
    end;
    Bubble := FindPlayerBubbleByKey('TerronWin', False);
    if (Bubble <> nil) and (Bubble.Kind = 3) then
    begin
      Bubble.Kind := 4;
      Bubble.WasRead := False;
    end;
    Bubble := FindPlayerBubbleByKey('KellerWin', False);
    if (Bubble <> nil) and (Bubble.Kind = 3) then
    begin
      Bubble.Kind := 4;
      Bubble.WasRead := False;
    end;
    EminentCareerShips[Ord(rcTrader)] := nil;
    EminentCareerShips[Ord(rcPirate)] := nil;
    EminentCareerShips[Ord(rcWarrior)] := nil;
    CoalitionDefeatedTurn := CurrentTurn;
    Galaxy.PirateWinTurn := Galaxy.CurrentTurn;
    Galaxy.PirateWinType := 5;
    TryUnlockAchievement('PIRATEWIN');
    Text :=
        PickLocalizedTextVariant('GalaxyNews.Globals.CoalitionDefeated', Galaxy.CurrentTurn div 23);
    AddOrUpdatePlayerBubble(0, CurrentTurn, Text, '').NotificationSoundKind := 1;
    AddPlanetNews(35, Text);
  end;
end;
procedure TGalaxy.ComputeRangerSpawnQuotas;
var
  Race: Byte;
  Ratio, I, J, K: Integer;
  Star: TStar;
  Planet: TPlanet;
  Warrior: TWarrior;
  Total, Extra: Integer;
  Order: array[0..4] of Byte;
  Counts, Recruits: array[0..4] of Integer;
  Reserved: Integer;
  Sorted: array[0..4] of Integer;
begin
  for Race := 0 to 4 do
  begin
    Counts[Race] := 0;
    Recruits[Race] := 0;
    RangerSpawnQuotas[Race] := 0;
    Order[Race] := Race;
  end;
  Ratio := Round(18 / (CustomRules.CoalitionAggression * 0.0625 + 0.5));
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      for K := 0 to Planet.Warriors.Count - 1 do
      begin
        Warrior := TWarrior(Planet.Warriors[K]);
        if Warrior.TypeNameOverrideKey = '' then
          if Warrior.WarriorType = wtFlagship then
            Inc(Recruits[Warrior.PilotRace])
          else
            Inc(Counts[Warrior.PilotRace]);
      end;
    end;
  end;
  Total := 0;
  for Race := 0 to 4 do
    Inc(Total, Counts[Race]);
  if Total < 3 then
    Exit;
  for Race := 0 to 4 do
  begin
    I := Counts[Race] div Ratio;
    RangerSpawnQuotas[Race] := I - Recruits[Race];
    Dec(Counts[Race], I * Ratio);
    Dec(Total, I * Ratio);
  end;
  Extra := Total div Ratio;
  if Total - Extra * Ratio >= 3 then
    Inc(Extra);
  for Race := 0 to 4 do
    Sorted[Race] := Counts[Race];
  for I := 0 to 3 do
    for J := I + 1 to 4 do
      if Sorted[I] < Sorted[J] then
      begin
        Race := Order[I];
        K := Sorted[I];
        Order[I] := Order[J];
        Sorted[I] := Sorted[J];
        Order[J] := Race;
        Sorted[J] := K;
      end;
  for I := 0 to Min(Extra - 0 - 1, 4) do
    Inc(RangerSpawnQuotas[Order[I]]);
end;
procedure TGalaxy.PruneExpiredGalaxyEvents;
begin
  while (GalaxyEvents.Count > 0) and (CurrentTurn - TGalaxyEvent(GalaxyEvents[0]).Turn > 1825) do
  begin
    TObject(GalaxyEvents[0]).Free;
    GalaxyEvents.Delete(0);
  end;
end;
function TGalaxy.GetCoalitionToPirateSystemRatio: Single;
begin
  Result :=
      Galaxy.CountFactionStars(Ord(sfCoalition))
          / Max(1, Galaxy.CountFactionStars(Ord(sfPirates)) - 1);
end;
function TGalaxy.GetEffectiveDifficultyLevel: Integer;
var
  I: Byte;
begin
  Result := 0;
  if CustomRules.Enabled then
    Result := CustomRules.DominatorStrength
  else
    for I := 0 to 7 do
      Inc(Result, Galaxy.DifficultyLevels[I]);
end;
function TGalaxy.GetDifficultyTierIndex: Byte;
var
  Level, Bound, Tier, Step: Integer;
begin
  Level := GetEffectiveDifficultyLevel;
  Bound := 6;
  Tier := 0;
  Step := 8;
  while Level >= Bound do
  begin
    Inc(Bound, Step);
    Inc(Tier);
  end;
  Result := Min(Tier, 9);
end;
function TGalaxy.InterpolateDifficulty(
    Level: Integer;
    AtZero, AtEight, AtSixteen, AtTwentyFour: Single
): Single;
var
  EffectiveLevel: Integer;
begin
  if Level < 0 then
    EffectiveLevel := GetEffectiveDifficultyLevel
  else
    EffectiveLevel := Level;
  if EffectiveLevel <= 0 then
    Result := AtZero
  else if EffectiveLevel <= 8 then
    Result := RemapClamped(EffectiveLevel, 0, 8, AtZero, AtEight)
  else if EffectiveLevel <= 16 then
    Result := RemapClamped(EffectiveLevel, 8, 16, AtEight, AtSixteen)
  else if EffectiveLevel <= 24 then
    Result := RemapClamped(EffectiveLevel, 16, 24, AtSixteen, AtTwentyFour)
  else
    Result := AtTwentyFour + (AtTwentyFour - AtSixteen) * (EffectiveLevel - 24) / 8;
end;
function TGalaxy.ScaleDifficultyExponentially(
    Level: Integer;
    BaseValue, FactorPerEightLevels: Single
): Single;
var
  EffectiveLevel: Integer;
begin
  if Level < 0 then
    EffectiveLevel := GetEffectiveDifficultyLevel
  else
    EffectiveLevel := Level;
  Result := BaseValue * Exp(Ln(FactorPerEightLevels) * EffectiveLevel * 0.125);
end;
function TGalaxy.GetDominatorBossHullScale: Single;
begin
  Result := InterpolateDifficulty(-1, 0.8, 1, 1.2, 1.5);
end;
function TGalaxy.GetDominatorKillExperienceScale: Single;
begin
  Result := GetEffectiveDifficultyLevel * 0.3 / 24 + 0.9;
end;
function TGalaxy.GetTurnsBetweenLiberationGroups: Integer;
begin
  if CustomRules.Enabled then
    Result :=
        Round(
            InterpolateDifficulty(-1, 25, 30, 50, 80)
                / (0.5 + CustomRules.CoalitionAggression * 0.0625)
        )
  else
    Result := Round(InterpolateDifficulty(-1, 25, 30, 50, 80));
end;
function TGalaxy.GetInitialDominatorControlPercent: Integer;
var
  Level: Integer;
begin
  Level := GetEffectiveDifficultyLevel;
  Result := 45 + Round(Level * 1.25);
end;
function TGalaxy.GetDominatorAggressionLevel: Integer;
begin
  if CustomRules.Enabled then
    Result := CustomRules.DominatorAggression
  else
    Result := GetEffectiveDifficultyLevel;
end;
function TGalaxy.GetDominatorSpawnLevel: Integer;
begin
  if CustomRules.Enabled then
    Result := CustomRules.DominatorSpawn
  else
    Result := GetEffectiveDifficultyLevel;
end;
function TGalaxy.GetPirateAggressionLevel: Integer;
begin
  if CustomRules.Enabled then
    Result := CustomRules.PirateAggression
  else
    Result := 8 * Galaxy.DifficultyLevels[0];
end;
function TGalaxy.IsChaoticRandomEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.ChaoticRandom;
end;
function TGalaxy.AreStationsNearStarsEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.StationsNearStars;
end;
function TGalaxy.IsFullStationTargetingEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.FullStationTargeting;
end;
function TGalaxy.IsEquipmentKnowledgeUnrestricted: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.UnrestrictedEquipmentKnowledge;
end;
function TGalaxy.GetAsteroidModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := 0.5 + CustomRules.AsteroidModifier * 0.0625;
end;
function TGalaxy.GetStarDamageDifficultyScale: Single;
begin
  Result := 1;
  if Galaxy.CustomRules.Enabled then
    Result := CustomRules.SunDamageModifier * 0.0625 + 0.5;
end;
function TGalaxy.AreSpecialShipsEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.SpecialShips;
end;
function TGalaxy.GetMicroModuleOfferRollThresholdPercent: Single;
begin
  Result := 30;
  if CustomRules.Enabled then
    Result := CustomRules.AcrynModifier;
end;
function TGalaxy.GetNodeDropModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := 0.5 + CustomRules.NodeDropModifier * 0.0625;
end;
function TGalaxy.GetArcadeDropValueModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := 0.5 + CustomRules.ArcadeDropValueModifier * 0.0625;
end;
function TGalaxy.GetDropValueModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := CustomRules.DropValueModifier * 0.0625 + 0.5;
end;
function TGalaxy.GetAgriculturalPlanetWeight: Integer;
begin
  Result := 1;
  if CustomRules.Enabled then
    if Integer(CustomRules.AgriculturalPlanetWeight)
            + CustomRules.MixedPlanetWeight
            + CustomRules.IndustrialPlanetWeight
        = 0 then
      Result := 1
    else
      Result := CustomRules.AgriculturalPlanetWeight;
end;
function TGalaxy.GetMixedPlanetWeight: Integer;
begin
  Result := 1;
  if CustomRules.Enabled then
    if Integer(CustomRules.AgriculturalPlanetWeight)
            + CustomRules.MixedPlanetWeight
            + CustomRules.IndustrialPlanetWeight
        = 0 then
      Result := 1
    else
      Result := CustomRules.MixedPlanetWeight;
end;
function TGalaxy.GetIndustrialPlanetWeight: Integer;
begin
  Result := 1;
  if CustomRules.Enabled then
    if Integer(CustomRules.AgriculturalPlanetWeight)
            + CustomRules.MixedPlanetWeight
            + CustomRules.IndustrialPlanetWeight
        = 0 then
      Result := 1
    else
      Result := CustomRules.IndustrialPlanetWeight;
end;
function TGalaxy.IsZeroStartingExperienceEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.ZeroStartingExperience;
end;
function TGalaxy.GetExtraRangerCount: Integer;
begin
  Result := 0;
  if CustomRules.Enabled then
    Result := CustomRules.ExtraRangers;
end;
function TGalaxy.IsArcadeBattleRoyaleEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.ArcadeBattleRoyale;
end;
function TGalaxy.GetArcadeHitpointsModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := CustomRules.ArcadeHitpointsModifier * 0.0625 + 0.5;
end;
function TGalaxy.GetArcadeDamageModifier: Single;
begin
  Result := 1;
  if CustomRules.Enabled then
    Result := CustomRules.ArcadeDamageModifier * 0.0625 + 0.5;
end;
function TGalaxy.AreDominatorRacialWeaponsEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.DominatorRacialWeapons;
end;
function TGalaxy.GetAIJunkToleranceLevel: Integer;
begin
  Result := 7;
  if CustomRules.Enabled then
    Result := CustomRules.AIJunkTolerance;
end;
function TGalaxy.AreMaxRangeMissilesEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.MaxRangeMissiles;
end;
function TGalaxy.IsOldHyperspaceEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.OldHyperspace;
end;
function TGalaxy.ArePirateNodesEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.PirateNodes;
end;
function TGalaxy.IsAIShoppingEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.AIUseShops;
end;
function TGalaxy.IsStationShopUpdateEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.StationsUseShop;
end;
function TGalaxy.AreDuplicateArtefactsEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.DuplicateArtefacts;
end;
function TGalaxy.GetHullGrowthMod: Byte;
begin
  if CustomRules.Enabled then
    Result := CustomRules.HullGrowth
  else
    Result := 0;
end;
function TGalaxy.IsArcadeEquipmentChangeEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.ArcadeEquipmentChange;
end;
function TGalaxy.IsOldSpeedCalculationEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.OldSpeedCalculation;
end;
function TGalaxy.AreOldMissileBonusesEnabled: Boolean;
begin
  Result := CustomRules.Enabled and CustomRules.OldMissileBonuses;
end;
procedure TStar.RefreshDominatorSeries;
var
  Blazers, Kellers, Terrons: Integer;
  Strength: Extended;
begin
  Blazers := CountDominatorForces(dsBlazer, False, False, Strength);
  Kellers := CountDominatorForces(dsKeller, False, False, Strength);
  Terrons := CountDominatorForces(dsTerron, False, False, Strength);
  if (BlazerShip <> nil) and BlazerShip.InNormalSpace and (BlazerShip.CurrentStar = Self) then
    Inc(Blazers);
  if (KellerShip <> nil) and KellerShip.InNormalSpace and (KellerShip.CurrentStar = Self) then
    Inc(Kellers);
  if (TerronShip <> nil) and TerronShip.InNormalSpace and (TerronShip.CurrentStar = Self) then
    Inc(Terrons);
  if (Blazers > 0) and (Kellers = 0) and (Terrons = 0) then
    DominatorSeries := dsBlazer;
  if (Blazers = 0) and (Kellers > 0) and (Terrons = 0) then
    DominatorSeries := dsKeller;
  if (Blazers = 0) and (Kellers = 0) and (Terrons > 0) then
    DominatorSeries := dsTerron;
end;
procedure TStar.RefreshDerivedStats;
var
  I, Strength: Integer;
  Ship: TShip;
begin
  TrafficLevel := Round(RemapClamped(Ships.Count, 3, 13, 0, 100));
  if Ships.Count > 0 then
  begin
    Strength := 0;
    for I := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[I]);
      Inc(Strength, Integer(Ship.GetStrengthScaledPirateStatus) and $7F);
    end;
    ThreatLevel := Round(RemapClamped(Strength, 0, 500, 0, 100));

  end
  else
    ThreatLevel := 0;

  UpdateControlFaction;
  RefreshShipTypeCounts;
  RefreshDominatorSeries;
end;
procedure TStar.GetControlPresence(
    out PlayerPartyPresent,
    CoalitionPresent,
    DominatorsPresent,
    PiratesPresent,
    CustomPresent: Boolean
);
var
  Ship: TShip;
  CoalitionLeaning, NeutralPresent, PirateLeaning: Boolean;
  Index, DefenderIndex: Integer;
  Planet: TPlanet;
  CoalitionMilitaryPresent, PirateMilitaryPresent, PirateActivePresent, CoalitionActivePresent:
      Boolean;
  PirateKills, CoalitionKills, PirateLeaningKills, CoalitionLeaningKills: Integer;
  procedure AccumulateControlPresence; // @addr 0x7C2538 @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; ship -4, Coalition output -8, faction flags -9..-11, other outputs +8..+16."
  begin
    case Ship.CurrentStanding of
      ssDominator: DominatorsPresent := True;
      ssCoalitionMilitary, ssCoalitionActive: CoalitionPresent := True;
      ssCoalitionPassive: CoalitionLeaning := True;
      ssNeutral: NeutralPresent := True;
      ssPiratePassive: PirateLeaning := True;
      ssPirateActive, ssPirateMilitary: PiratesPresent := True;
      ssCustom: CustomPresent := True;
    end;
  end;
begin
  CoalitionPresent := False;
  DominatorsPresent := False;
  PiratesPresent := False;
  CustomPresent := False;
  PlayerPartyPresent := False;
  PirateLeaning := False;
  NeutralPresent := False;
  CoalitionLeaning := False;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[Index];
    if not Ship.InHyperspace
        and ((Ship.CurrentPlanet = nil) or (Ship.CurrentPlanet.OwnerId <> Byte(oiUninhabited)))
        and ((Ship.DockedTo = nil) or (GetPlayer = Ship))
        and ((GetPlayer <> Ship)
            or ((Ship.CurrentPlanet = nil) and (Ship.DockedTo = nil))
            or (Ship.ConsecutiveDockedDays <= 2)
            or (CurrentScreenId = screenPlanetQuest)) then
    begin
      AccumulateControlPresence;
      if (GetPlayer = Ship) or (GetPlayer = Ship.PartnerShip) then
        PlayerPartyPresent := True;
    end;
  end;
  if not CoalitionPresent and (ControlFaction = sfCoalition) then
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := Planets[Index];
      if Planet.IsCoalitionOwned and (Planet.Warriors.Count > 0) then
        for DefenderIndex := 0 to Planet.Warriors.Count - 1 do
        begin
          Ship := Planet.Warriors[DefenderIndex];
          if (Ship.CurrentStar = Self) and not Ship.InHyperspace then
            AccumulateControlPresence;
        end;
    end;
  if (ControlFaction = sfCoalition) and not CoalitionPresent and not PiratesPresent then
    if NeutralPresent or CoalitionLeaning then
      CoalitionPresent := True
    else if DominatorsPresent and PirateLeaning then
      CoalitionPresent := True
    else if PirateLeaning then
      PiratesPresent := True;
  if (ControlFaction = sfPirates) and not CoalitionPresent and not PiratesPresent then
    if NeutralPresent or PirateLeaning then
      PiratesPresent := True
    else if DominatorsPresent and CoalitionLeaning then
      PiratesPresent := True
    else if CoalitionLeaning then
      CoalitionPresent := True;
  if (ControlFaction = sfDominators) or (Status.CustomFaction <> '') then
  begin
    if NeutralPresent then
      CoalitionPresent := True;
    if PirateLeaning then
      PiratesPresent := True;
    if CoalitionLeaning then
      CoalitionPresent := True;
  end;
  if (Galaxy.CoalitionDefeatedTurn <> 0) and (ControlFaction <> sfCoalition) then
  begin
    PiratesPresent := PiratesPresent or CoalitionPresent;
    CoalitionPresent := False;
  end;
  if (Galaxy.PirateWinType = 3) and (ControlFaction <> sfPirates) then
  begin
    CoalitionPresent := PiratesPresent or CoalitionPresent;
    PiratesPresent := False;
  end;
  if not DominatorsPresent
      and not CoalitionPresent
      and not PiratesPresent
      and (ControlFaction = sfDominators)
      and (Status.CustomFaction = '')
      and (((DominatorSeries = dsBlazer) and (Galaxy.BlazerSeriesResolvedTurn <> 0))
          or ((DominatorSeries = dsTerron) and (Galaxy.TerronSeriesResolvedTurn <> 0))) then
    if Galaxy.CoalitionDefeatedTurn = 0 then
      CoalitionPresent := True
    else
      PiratesPresent := True;
  if (ControlFaction = sfDominators)
      and CoalitionPresent
      and PiratesPresent
      and not DominatorsPresent then
  begin
    CoalitionMilitaryPresent := False;
    PirateMilitaryPresent := False;
    PirateActivePresent := False;
    CoalitionActivePresent := False;
    PirateKills := 0;
    CoalitionKills := 0;
    PirateLeaningKills := 0;
    CoalitionLeaningKills := 0;
    for Index := 0 to Ships.Count - 1 do
    begin
      Ship := Ships[Index];
      if not Ship.InHyperspace
          and (Ship is TNormalShip)
          and ((GetPlayer <> Ship)
              or ((Ship.CurrentPlanet = nil) and (Ship.DockedTo = nil))
              or (Ship.ConsecutiveDockedDays <= 2)) then
        if Ship.CurrentStanding = ssCoalitionMilitary then
        begin
          CoalitionMilitaryPresent := True;
          Inc(CoalitionKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
        end
        else if Ship.CurrentStanding = ssPirateMilitary then
        begin
          PirateMilitaryPresent := True;
          Inc(PirateKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
        end
        else if Ship.CurrentStanding <> ssNeutral then
          if Ship.CurrentStanding in [ssPiratePassive, ssPirateActive] then
          begin
            Inc(PirateKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
            if Ship.CurrentStanding = ssPirateActive then
              PirateActivePresent := True
            else
              Inc(PirateLeaningKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
          end
          else if Ship.CurrentStanding in [ssCoalitionActive, ssCoalitionPassive] then
          begin
            Inc(CoalitionKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
            if Ship.CurrentStanding = ssCoalitionActive then
              CoalitionActivePresent := True
            else
              Inc(CoalitionLeaningKills, TNormalShip(Ship).CurrentSystemKills.Dominator);
          end;
    end;
    if CoalitionKills < PirateLeaningKills then
      CoalitionPresent := False
    else if PirateKills < CoalitionLeaningKills then
      PiratesPresent := False
    else if PirateMilitaryPresent and CoalitionMilitaryPresent then
      Exit
    else if PirateMilitaryPresent and CoalitionActivePresent then
      Exit
    else if CoalitionMilitaryPresent and PirateActivePresent then
      Exit
    else if CoalitionKills > PirateKills then
      PiratesPresent := False
    else if CoalitionKills < PirateKills then
      CoalitionPresent := False
    else if PlayerPartyPresent then
      if GetPlayer.OwnerId = Byte(oiPirate) then
        CoalitionPresent := False
      else
        PiratesPresent := False
    else
      PiratesPresent := False;
  end;
end;
procedure TStar.UpdateControlFaction;
var
  Index: Integer;
  Planet: TPlanet;
  CoalitionPresent,
  CoalitionCaptured,
  DominatorsPresent,
  DominatorsCaptured,
  PiratesPresent,
  PiratesCaptured,
  CustomPresent,
  PlayerPartyPresent: Boolean;
  procedure RecordFactionVictory(
      Faction: TStarFaction
  ); // @addr 0x7C2B70 @ida "void __usercall $name(unsigned __int8 Faction@<al>, void *ParentFrame@<^0>);" @note "Nested in UpdateControlFaction with unused caller-popped static link. Updates active Galaxy.WarDeltaWin; a losing streak below -1 is halved rather than incremented."
  begin
    if Galaxy.WarDeltaWin[Ord(Faction)] >= -1 then
      Inc(Galaxy.WarDeltaWin[Ord(Faction)])
    else
      Galaxy.WarDeltaWin[Ord(Faction)] := Galaxy.WarDeltaWin[Ord(Faction)] div 2;
  end;
  procedure RecordFactionDefeat(
      Faction: TStarFaction
  ); // @addr 0x7C2BC4 @ida "void __usercall $name(unsigned __int8 Faction@<al>, void *ParentFrame@<^0>);" @note "Nested in UpdateControlFaction with unused caller-popped static link. Updates active Galaxy.WarDeltaWin; a winning streak above 1 is halved rather than decremented."
  begin
    if Galaxy.WarDeltaWin[Ord(Faction)] <= 1 then
      Dec(Galaxy.WarDeltaWin[Ord(Faction)])
    else
      Galaxy.WarDeltaWin[Ord(Faction)] := Galaxy.WarDeltaWin[Ord(Faction)] div 2;
  end;
begin
  if GetPlayer = nil then
    Exit;
  PlayerPartyPresent := False;
  DominatorsPresent := False;
  DominatorsCaptured := False;
  CoalitionPresent := False;
  CoalitionCaptured := False;
  PiratesPresent := False;
  PiratesCaptured := False;
  if ((Constellation.Id = 20) and (Galaxy.PirateWinType <> 3))
      or (Galaxy.KellerResearchTargetStarId = Id)
      or NoComeKling
      or IsStarProtectedByScript(Self) then
  begin
    Battle := 0;
    Exit;
  end;
  GetControlPresence(
      PlayerPartyPresent,
      CoalitionPresent,
      DominatorsPresent,
      PiratesPresent,
      CustomPresent
  );
  if Boolean(Battle)
      and CoalitionPresent
      and not DominatorsPresent
      and (ControlFaction = sfCoalition)
      and (Status.CustomFaction = '')
      and (Galaxy.CurrentTurn - 1 <= LastDominatorPresenceTurn)
      and IsConstellationVisible
      and (Galaxy.CountPlanetNewsByType(25) < 2)
      and (Galaxy.CoalitionDefeatedTurn = 0) then
    Galaxy.AddPlanetNews(
        25,
        FormatText1(
            PickLocalizedTextVariant(
                'GalaxyNews.Star.Kling.Lost',
                (Galaxy.CurrentTurn div 10) * GenerationSeed
            ),
            '<color=255,240,100>',
            '<Star>',
            Name
        )
    );
  if Boolean(Battle)
      and CoalitionPresent
      and not PiratesPresent
      and (ControlFaction = sfCoalition)
      and (Status.CustomFaction = '')
      and (Galaxy.CurrentTurn - 1 <= LastPiratePresenceTurn)
      and IsConstellationVisible
      and (Galaxy.CountPlanetNewsByType(28) < 2)
      and (Galaxy.CoalitionDefeatedTurn = 0) then
    Galaxy.AddPlanetNews(
        28,
        FormatText1(
            PickLocalizedTextVariant(
                'GalaxyNews.Star.Pirates.Lost',
                (Galaxy.CurrentTurn div 10) * GenerationSeed
            ),
            '<color=255,240,100>',
            '<Star>',
            Name
        )
    );
  if DominatorsPresent then
    LastDominatorPresenceTurn := Galaxy.CurrentTurn;
  if PiratesPresent then
    LastPiratePresenceTurn := Galaxy.CurrentTurn;
  if DominatorsPresent and CoalitionPresent then
  begin
    if IsConstellationVisible
        and (Galaxy.CountPlanetNewsByType(24) < 2)
        and (Battle = 0)
        and (ControlFaction = sfCoalition)
        and (Status.CustomFaction = '')
        and (Galaxy.CoalitionDefeatedTurn = 0) then
      Galaxy.AddPlanetNews(
          24,
          FormatText1(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Kling.Attack',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name
          )
      );
    Battle := 1;
    Exit;
  end;
  if PiratesPresent and CoalitionPresent then
  begin
    if IsConstellationVisible
        and (Galaxy.CountPlanetNewsByType(27) < 2)
        and (Battle = 0)
        and (ControlFaction = sfCoalition)
        and (Status.CustomFaction = '')
        and (Galaxy.CoalitionDefeatedTurn = 0) then
      Galaxy.AddPlanetNews(
          27,
          FormatText1(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Pirates.Attack',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name
          )
      );
    Battle := 1;
    Exit;
  end;
  if DominatorsPresent and PiratesPresent then
  begin
    Battle := 1;
    Exit;
  end;
  if CustomPresent and (Status.CustomFaction = '') then
  begin
    Battle := 1;
    Exit;
  end;
  if Status.CustomFaction <> '' then
  begin
    Battle := Byte(CoalitionPresent or PiratesPresent or DominatorsPresent);
    Exit;
  end;
  if not DominatorsPresent
      and not PiratesPresent
      and (ControlFaction = sfCoalition)
      and (Battle <> 0) then
  begin
    if PlayerPartyPresent and (GetPlayer.OwnerId <> Byte(oiPirate)) then
    begin
      Inc(GetPlayer.AchievementStats.SystemsDefended);
      TrySetAchievementProgress('DEFENDER', GetPlayer.AchievementStats.SystemsDefended);
    end;
    Battle := 0;
    Exit;
  end;
  if not CoalitionPresent
      and not PiratesPresent
      and (ControlFaction = sfDominators)
      and (Battle <> 0) then
  begin
    Battle := 0;
    Exit;
  end;
  if not CoalitionPresent
      and not DominatorsPresent
      and (ControlFaction = sfPirates)
      and (Battle <> 0) then
  begin
    if PlayerPartyPresent and (GetPlayer.OwnerId = Byte(oiPirate)) then
    begin
      Inc(GetPlayer.AchievementStats.SystemsDefended);
      TrySetAchievementProgress('DEFENDER', GetPlayer.AchievementStats.SystemsDefended);
    end;
    Battle := 0;
    Exit;
  end;
  if (DominatorsPresent or PiratesPresent) and (ControlFaction = sfCoalition) then
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := Planets[Index];
      if Planet.IsCoalitionOwned
          and (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * Planet.GenerationSeed * 2311)
              < 20) then
      begin
        // Native tests the quotient, not the remainder: preserve the early-turn behavior.
        if Galaxy.CurrentTurn div 5 = 0 then
          Planet.ForceGoodsScarcity(True, [6]);
        if Galaxy.CurrentTurn div 7 = 0 then
          Planet.ForceGoodsScarcity(True, [1]);
        if Galaxy.CurrentTurn div 3 = 0 then
          Planet.ForceGoodsScarcity(True, [0]);
        if Galaxy.CurrentTurn div 5 = 0 then
          Planet.ForceGoodsSurplus(True, [3]);
        if Galaxy.CurrentTurn div 3 = 0 then
          Planet.ForceGoodsSurplus(True, [5]);
        if Galaxy.CurrentTurn div 11 = 0 then
          Planet.ForceGoodsSurplus(True, [7]);
      end;
    end;
  if DominatorsPresent and (ControlFaction <> sfDominators) then
  begin
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := Planets[Index];
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        Planet.OwnerId := Byte(oiDominator);
        Planet.UpdateOwnerFlags;
        DominatorsCaptured := True;
      end;
    end;
    if DominatorsCaptured then
    begin
      if Galaxy.CoalitionDefeatedTurn = 0 then
        if ControlFaction = sfCoalition then
          Galaxy.AddPlanetNewsWithPlayerBubble(
              33,
              FormatText2(
                  PickLocalizedTextVariant(
                      'GalaxyNews.Globals.KlingTakeSystemFromNormals',
                      (Galaxy.CurrentTurn div 10) * GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Star>',
                  Name,
                  '<Sector>',
                  Constellation.GetName
              )
          )
        else if Galaxy.CoalitionDefeatedTurn = 0 then
          Galaxy.AddPlanetNewsWithPlayerBubble(
              34,
              FormatText2(
                  PickLocalizedTextVariant(
                      'GalaxyNews.Globals.KlingTakeSystemFromPirateClan',
                      (Galaxy.CurrentTurn div 10) * GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Star>',
                  Name,
                  '<Sector>',
                  Constellation.GetName
              )
          )
        else
          // Retained native branch, despite the outer zero test.
          AddOrUpdatePlayerBubble(
              0,
              Galaxy.CurrentTurn,
              FormatText2(
                  PickLocalizedTextVariant(
                      'GalaxyNews.Globals.KlingTakeSystemFromPirateClanAlt',
                      (Galaxy.CurrentTurn div 10) * GenerationSeed
                  ),
                  '<color=255,240,100>',
                  '<Star>',
                  Name,
                  '<Sector>',
                  Constellation.GetName
              ),
              ''
          );
      RecordFactionDefeat(ControlFaction);
      PreviousControlFaction := ControlFaction;
      ControlFaction := sfDominators;
      Battle := 0;
      RecordFactionVictory(sfDominators);
    end;
  end
  else if PiratesPresent and (Galaxy.PirateWinType <> 3) and (ControlFaction <> sfPirates) then
  begin
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := Planets[Index];
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        Planet.Warriors.Clear;
        Planet.OwnerId := Byte(oiPirate);
        Planet.Government := pgAnarchy;
        Planet.UpdateOwnerFlags;
        PiratesCaptured := True;
      end;
    end;
    if PiratesCaptured then
    begin
      RecordFactionDefeat(ControlFaction);
      PreviousControlFaction := ControlFaction;
      ControlFaction := sfPirates;
      Battle := 0;
      if (MainPiratePlanet = nil) or (MainPiratePlanet.CurrentStar <> Self) then
        LiberationRewardsPending := True;
      RecordFactionVictory(sfPirates);
      for Index := 0 to Ships.Count - 1 do
        if (TObject(Ships[Index]) is TPirate) and not TShip(Ships[Index]).HasScriptControl then
          TPirate(Ships[Index]).PrisonTermRemaining := 0;
      if GetPlayer <> nil then
        GetPlayer.AchievementStats.CheckAllPirateSystemsAchievement;
      if (PieceCreatorTargetStarId = Id) and (GetPlayer <> nil) then
        TryUnlockAchievement('PIECECREATOR');
    end;
  end
  else if CoalitionPresent
      and (Galaxy.CoalitionDefeatedTurn = 0)
      and (ControlFaction <> sfCoalition) then
  begin
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := Planets[Index];
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        if Planet.OwnerId = Byte(oiPirate) then
          Planet.Government := TPlanetGovernment(SeededRandomIntRange(0, 4, Planet.RandomState));
        Planet.OwnerId := RaceToOwner(Planet.RaceId);
        Planet.UpdateOwnerFlags;
        Planet.InventionLevels[7] := Max(Integer(Planet.InventionLevels[7]), Galaxy.TechLevel - 2);
        CoalitionCaptured := True;
      end;
    end;
    if CoalitionCaptured then
    begin
      RecordFactionDefeat(ControlFaction);
      PreviousControlFaction := ControlFaction;
      ControlFaction := sfCoalition;
      Battle := 0;
      if (MainPiratePlanet = nil) or (MainPiratePlanet.CurrentStar <> Self) then
        LiberationRewardsPending := True;
      RecordFactionVictory(sfCoalition);
      for Index := 0 to Ships.Count - 1 do
        if (TObject(Ships[Index]) is TRanger)
            and not TShip(Ships[Index]).HasScriptControl
            and (TShip(Ships[Index]) <> GetPlayer) then
          TRanger(Ships[Index]).PrisonTermRemaining := 0;
      if (PieceCreatorTargetStarId = Id) and (GetPlayer <> nil) then
        TryUnlockAchievement('PIECECREATOR');
    end;
  end;
end;
procedure TStar.ResetControlFaction;
var
  Ship: TShip;
  DominatorCount,
  CoalitionCount,
  CoalitionPassiveCount,
  NeutralCount,
  PiratePassiveCount,
  PirateCount: Integer;
  Planet: TPlanet;
  I: Integer;
  SeriesCounts: array[0..2] of Integer;
  procedure CountShipStanding; // @addr 0x7C3B8C @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; ship -4, standing counters -8..-28."
  begin
    case Ship.CurrentStanding of
      ssDominator: Inc(DominatorCount);
      ssCoalitionMilitary, ssCoalitionActive: Inc(CoalitionCount);
      ssCoalitionPassive: Inc(CoalitionPassiveCount);
      ssNeutral: Inc(NeutralCount);
      ssPiratePassive: Inc(PiratePassiveCount);
      ssPirateActive, ssPirateMilitary: Inc(PirateCount);
    end;
  end;
  procedure SetCoalition; // @addr 0x7C3BFC @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; star -32. Also transfers planets and clears eligible NPC ranger prison terms."
  var
    J: Integer;
  begin
    ControlFaction := sfCoalition;
    PreviousControlFaction := sfCoalition;
    Battle := Byte(PirateCount + DominatorCount > 0);
    for J := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[J]);
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        Planet.OwnerId := RaceToOwner(Planet.RaceId);
        Planet.UpdateOwnerFlags;
      end;
    end;
    for J := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[J]);
      if (Ship is TRanger) and not Ship.HasScriptControl and (GetPlayer <> Ship) then
        TRanger(Ship).PrisonTermRemaining := 0;
    end;
  end;
  procedure SetPirates; // @addr 0x7C3D18 @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; star -32. Also transfers planets and clears eligible NPC pirate prison terms."
  var
    J: Integer;
  begin
    ControlFaction := sfPirates;
    PreviousControlFaction := sfPirates;
    Battle := Byte(CoalitionCount + DominatorCount > 0);
    for J := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[J]);
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        Planet.OwnerId := Byte(oiPirate);
        Planet.UpdateOwnerFlags;
      end;
    end;
    for J := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[J]);
      if (Ship is TPirate) and not Ship.HasScriptControl then
        TPirate(Ship).PrisonTermRemaining := 0;
    end;
  end;
begin
  if GetPlayer = nil then
    Exit;
  DominatorCount := 0;
  CoalitionCount := 0;
  PirateCount := 0;
  CoalitionPassiveCount := 0;
  PiratePassiveCount := 0;
  NeutralCount := 0;
  SeriesCounts[Ord(dsBlazer)] := 0;
  SeriesCounts[Ord(dsTerron)] := 0;
  SeriesCounts[Ord(dsKeller)] := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if not Ship.InHyperspace
        and ((Ship.CurrentPlanet = nil) or (Ship.CurrentPlanet.OwnerId <> Byte(oiUninhabited)))
        and ((Ship.DockedTo = nil) or (GetPlayer = Ship))
        and ((GetPlayer <> Ship)
            or ((Ship.CurrentPlanet = nil) and (Ship.DockedTo = nil))
            or (Ship.ConsecutiveDockedDays <= 2)
            or (CurrentScreenId = screenPlanetQuest)) then
    begin
      CountShipStanding;
      if (Ship is TKling) and (Ship.CurrentStanding = ssDominator) then
      begin
        with Ship as TKling do
        begin
          Inc(SeriesCounts[Ord(DominatorSeries)]);
          if KlingType = ktBertor then
            Inc(SeriesCounts[Ord(DominatorSeries)], 3);
          if KlingType = ktBoss then
            Inc(SeriesCounts[Ord(DominatorSeries)], 10);
        end;
      end;
    end;
  end;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship is TNormalShip then
    begin
      with Ship as TNormalShip do
      begin
        CurrentSystemKills.Normal := 0;
        CurrentSystemKills.Pirate := 0;
        CurrentSystemKills.Dominator := 0;
        CurrentSystemKills.Custom := 0;
        PendingLiberationCeremonyPlanet := nil;
        PendingLiberationContribution := 0;
      end;
    end;
  end;
  if DominatorCount
      > CoalitionCount
          + PirateCount
          + CoalitionPassiveCount
          + PiratePassiveCount
          + NeutralCount then
  begin
    ControlFaction := sfDominators;
    PreviousControlFaction := sfDominators;
    for I := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[I]);
      if Planet.OwnerId <> Byte(oiUninhabited) then
      begin
        Planet.OwnerId := Byte(oiDominator);
        Planet.UpdateOwnerFlags;
      end;
    end;
    if SeriesCounts[Ord(dsBlazer)]
        >= Max(SeriesCounts[Ord(dsTerron)], SeriesCounts[Ord(dsKeller)]) then
      DominatorSeries := dsBlazer
    else if SeriesCounts[Ord(dsTerron)]
        >= Max(SeriesCounts[Ord(dsBlazer)], SeriesCounts[Ord(dsKeller)]) then
      DominatorSeries := dsTerron
    else
      DominatorSeries := dsKeller;
    Battle :=
        Byte(
            CoalitionCount + PirateCount + CoalitionPassiveCount + PiratePassiveCount + NeutralCount
                > 0
        );
  end
  else if Galaxy.CoalitionDefeatedTurn > 0 then
    SetPirates
  else if Galaxy.PirateWinType = 3 then
    SetCoalition
  else if CoalitionCount > PirateCount then
    SetCoalition
  else if PirateCount > CoalitionCount then
    SetPirates
  else if CoalitionPassiveCount > PiratePassiveCount then
    SetCoalition
  else if PiratePassiveCount > CoalitionPassiveCount then
    SetPirates
  else
    SetCoalition;
end;
procedure TStar.RefreshMapDiameterAndStats;
begin
  MapDiameter := ComputeMapDiameter;
  RefreshDerivedStats;
end;
procedure TStar.RefreshMovementStepParameters;
begin
  if (GetPlayer <> nil) and (GetPlayer.CurrentStar = Self) then
  begin
    MovementStepCount := 200;
    MovementStepScale := 1 / 200;
  end
  else
  begin
    MovementStepCount := 50;
    MovementStepScale := 1 / 50;
  end;
end;
function TStar.ComputeMapDiameter: Integer;
var
  Planet: TPlanet;
begin
  if Planets.Count > 0 then
  begin
    Planet := TPlanet(Planets[Planets.Count - 1]);
    Result := Round(Planet.Orbit.Radius + Planet.Radius + 800) * 2;
  end
  else
    Result := (SystemRadius + 800) * 2;
end;
function TStar.CountPlanetsByOwner(OwnerId: Byte): Integer;
var
  I: Integer;
  Planet: TPlanet;
begin
  Result := 0;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := Planets[I];
    if Planet.OwnerId = OwnerId then
      Inc(Result);
  end;
end;
function TStar.CountDistinctInhabitedPlanetOwners: Integer;
var
  OwnerId: Byte;
begin
  Result := 0;
  for OwnerId := Byte(oiMaloc) to 5 do
    if CountPlanetsByOwner(OwnerId) > 0 then
      Inc(Result);
  if CountPlanetsByOwner(Ord(oiPirate)) > 0 then
    Inc(Result);
end;
function TStar.FindFirstInhabitedPlanet: Pointer;
var
  Index: Integer;
begin
  Result := nil;
  for Index := 0 to Planets.Count - 1 do
  begin
    Result := Planets[Index];
    if (TObject(Result) as TPlanet).OwnerId <> Byte(oiUninhabited) then
      Break;
  end;
end;
function TStar.SelectRandomInhabitedPlanet: Pointer;
var
  I, Remaining: Integer;
begin
  Result := nil;
  Remaining := 0;
  for I := 0 to Planets.Count - 1 do
    if TPlanet(Planets[I]).OwnerId <> Byte(oiUninhabited) then
      Inc(Remaining);
  Remaining := NextRandomIntRange(1, Remaining, RandomState);
  for I := 0 to Planets.Count - 1 do
    if TPlanet(Planets[I]).OwnerId <> Byte(oiUninhabited) then
    begin
      Dec(Remaining);
      if Remaining = 0 then
      begin
        Result := Planets[I];
        Exit;
      end;
    end;
end;
function TStar.FindFastestResearchPlanet: Pointer;
var
  I: Integer;
  Rate, BestRate: Single;
  Planet, Best: TPlanet;
begin
  Best := nil;
  BestRate := 0;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    if Planet.OwnerId <> Byte(oiUninhabited) then
    begin
      Rate := Planet.CalculateInventionProgressRate;
      if (Rate > BestRate) or (Best = nil) then
      begin
        BestRate := Rate;
        Best := Planet;
      end;
    end;
  end;
  Result := Best;
end;
procedure TStar.RefreshShipTypeCounts;
var
  I: Integer;
  Ship: TShip;
  Kind: Byte;
begin
  for Kind := 0 to 13 do
    ShipTypeCounts[Kind] := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Dominion = Ship)
        or Ship.InNormalSpace
        or ((Ship.TypeId in [Ord(rstRangerCenter)..Ord(rstCustomStation)])
            and Ship.InHyperspace) then
      Inc(ShipTypeCounts[Ship.TypeId]);
  end;
end;
function TStar.CountEligibleRangersInSpace: Integer;
var
  Index: Integer;
  Ship: TShip;
begin
  Result := 0;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[Index];
    if not Ship.IsOutsideStarSpace
        and (Ship is TRanger)
        and not TRanger(Ship).ExcludedFromRating then
      Inc(Result);
  end;
end;
function TStar.CountShipsByTypeMask(ShipTypeMask: TShipTypeMask): Integer;
var
  Count: Integer;
  I: Byte;
begin
  Count := 0;
  for I := 0 to 13 do
    if I in ShipTypeMask then
      Inc(Count, ShipTypeCounts[I]);
  Result := Count;
end;
function TStar.CountDominatorForces(
    Series: TDominatorSeries;
    ExcludeAbsoluteOrders, OtherSeries: Boolean;
    out Strength: Extended
): Integer;
var
  I, OtherCount, MatchCount: Integer;
  OtherStrength, MatchStrength: Single;
  Ship: TShip;
begin
  OtherCount := 0;
  MatchCount := 0;
  OtherStrength := 0;
  MatchStrength := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[I];
    if Ship.IsOutsideStarSpace then
      Continue;
    if ExcludeAbsoluteOrders and Ship.OrderAbsolute then
      Continue;
    if (BlazerShip = Ship) or (KellerShip = Ship) or (TerronShip = Ship) then
      Continue;
    if not (Ship is TKling) then
      Continue;
    if (Ship as TKling).ActiveProgramAppliedTurn > 0 then
      Continue;
    if Ship.CurrentStanding = ssCustom then
      Continue;
    if (Ship as TKling).DominatorSeries = Series then
    begin
      Inc(MatchCount);
      MatchStrength := MatchStrength + Ship.Strength;
    end
    else
    begin
      Inc(OtherCount);
      OtherStrength := OtherStrength + Ship.Strength;
    end;
  end;
  if OtherSeries then
  begin
    Result := OtherCount;
    Strength := OtherStrength;
  end
  else
  begin
    Result := MatchCount;
    Strength := MatchStrength;
  end;
end;
function TStar.CountStandardDominatorsOfLocalSeries: Integer;
var
  I: Integer;
  Ship: TShip;
begin
  Result := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if not Ship.IsOutsideStarSpace
        and (Ship.CurrentStanding <> ssCustom)
        and (Ship <> BlazerShip)
        and (Ship <> KellerShip)
        and (Ship <> TerronShip)
        and (Ship is TKling)
        and ((Ship as TKling).DominatorSeries = DominatorSeries)
        and ((Ship as TKling).KlingType in [ktEquentor..ktShtip]) then
      Inc(Result);
  end;
end;
function TStar.CountPirateForces(
    ExcludeAbsoluteOrders: Boolean;
    out Strength: Extended;
    IncludeClanVariants, IncludeIndependent: Boolean
): Integer;
var
  Index, Count: Integer;
  Ship: TShip;
begin
  Count := 0;
  Strength := 0;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[Index];
    if Ship.IsOutsideStarSpace
        or (Ship.CurrentStanding = ssCustom)
        or (ExcludeAbsoluteOrders and Ship.OrderAbsolute) then
      Continue;
    if (Ship is TPirate) and (Ship.OwnerId = Byte(oiPirate)) then
    begin
      if (not IncludeClanVariants and ((Ship as TPirate).PirateType <> 0))
          or (not IncludeIndependent and ((Ship as TPirate).PirateType = 0)) then
        Continue;
      Inc(Count);
      Strength := Strength + Ship.Strength;
    end;
    if (GetPlayer = Ship) and (GetPlayer.OwnerId = Byte(oiPirate)) and IncludeIndependent then
    begin
      Inc(Count);
      Strength := Strength + Ship.Strength;
    end;
  end;
  Result := Count;
end;
function TStar.CountCustomFactionForces(
    ExcludeAbsoluteOrders: Boolean;
    out Faction: WideString;
    out Strength: Extended
): Integer;
var
  I: Integer;
  Ship: TShip;
begin
  Faction := Status.CustomFaction;
  Result := 0;
  Strength := 0;
  if Faction <> '' then
    for I := 0 to Ships.Count - 1 do
    begin
      Ship := Ships[I];
      if Ship.IsOutsideStarSpace then
        Continue;
      if Ship.CurrentStanding <> ssCustom then
        Continue;
      if Ship.ScriptShip = nil then
        Continue;
      if TScriptShip(Ship.ScriptShip).StateText <> Faction then
        Continue;
      if ExcludeAbsoluteOrders and Ship.OrderAbsolute then
        Continue;
      Inc(Result);
      Strength := Strength + Ship.Strength;
    end;
end;
function TStar.CountOtherCustomFactionForces(
    ExcludeAbsoluteOrders: Boolean;
    out Faction: WideString;
    out Strength: Extended
): Integer;
var
  I, Count: Integer;
  Ship: TShip;
  ShipFaction, OwnFaction: WideString;
begin
  Count := 0;
  Strength := 0;
  OwnFaction := Status.CustomFaction;
  Faction := '';
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[I];
    if Ship.IsOutsideStarSpace then
      Continue;
    if Ship.CurrentStanding <> ssCustom then
      Continue;
    if ExcludeAbsoluteOrders and Ship.OrderAbsolute then
      Continue;
    if (Ship.ScriptShip = nil) or (TScriptShip(Ship.ScriptShip).StateText = '') then
      Faction := ''
    else
    begin
      ShipFaction := TScriptShip(Ship.ScriptShip).StateText;
      if ShipFaction = OwnFaction then
        Continue;
      if Count = 0 then
        Faction := ShipFaction
      else if Faction <> ShipFaction then
        Faction := '';
    end;
    Inc(Count);
    Strength := Strength + Ship.Strength;
  end;
  Result := Count;
end;
function TStar.CountPirateShips(IncludeOutsideStarSpace: Boolean): Integer;
var
  I, Count: Integer;
  Ship: TShip;
begin
  Count := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (not Ship.IsOutsideStarSpace or (IncludeOutsideStarSpace <> False))
        and (Ship.CurrentStanding <> ssCustom) then
    begin
      if (Ship is TPirate) and (Ship.OwnerId = Byte(oiPirate)) then
        Inc(Count);
      if (Ship = GetPlayer) and (GetPlayer.OwnerId = Byte(oiPirate)) then
        Inc(Count);
    end;
  end;
  Result := Count;
end;
function TStar.CountForcesByOwnerGroups(
    out Strength: Extended;
    IncludeCoalition, IncludeDominators, IncludePirates, IncludeCustom: Boolean
): Integer;
var
  Ship: TShip;
  Count, I, J: Integer;
  Planet: TPlanet;
  procedure AccumulateFactionForces;
      cdecl; // @addr 0x7C4CC4 @ida "void __cdecl $name(void *ParentFrame);"
  begin
    if Ship.InHyperspace then
      Exit;
    if (Ship.CurrentPlanet <> nil) and (Ship.CurrentPlanet.OwnerId = Byte(oiUninhabited)) then
      Exit;
    if Ship.CurrentStanding = ssCustom then
    begin
      if IncludeCustom then
      begin
        Strength := Strength + Ship.Strength;
        Inc(Count);
      end;
      Exit;
    end;
    begin
      if not IncludeCoalition and (Ship.OwnerId in TOwnerMask(PlanetOwnerMasks.Coalition)) then
        Exit;
      if not IncludeDominators and (Ship.OwnerId in TOwnerMask(PlanetOwnerMasks.Dominators)) then
        Exit;
      if not IncludePirates and (Ship.OwnerId in TOwnerMask(PlanetOwnerMasks.PirateClan)) then
        Exit;
      if (GetPlayer = Ship) and GetPlayer.IsOutsideStarSpace then
        Exit;
      Strength := Strength + Ship.Strength;
      Inc(Count);
    end;
  end;
begin
  Count := 0;
  Strength := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := Ships[I];
    AccumulateFactionForces;
  end;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := Planets[I];
    if Planet.Warriors <> nil then
      for J := 0 to Planet.Warriors.Count - 1 do
      begin
        Ship := TShip(Planet.Warriors[J]);
        if (Ship.CurrentStar = Self) and (Ships.IndexOf(Ship) < 0) then
          AccumulateFactionForces;
      end;
  end;
  Result := Count;
end;
function TStar.CountRatedRangersByCareerMask(CareerMask: TRangerCareerSet): Byte;
var
  Index: Integer;
  Ship: TObject;
  Ranger: TRanger;
begin
  Result := 0;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TObject(Ships[Index]);
    if Ship is TRanger then
    begin
      Ranger := Ship as TRanger;
      if not Ranger.ExcludedFromRating and (Ranger.GetDominantCareer in CareerMask) then
        Inc(Result);
    end;
  end;
end;
function TStar.GetRangerNamesByCareerMask(CareerMask: TRangerCareerSet): WideString;
var
  Index: Integer;
  Ship: TObject;
  Ranger: TRanger;
begin
  Result := '';
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TObject(Ships[Index]);
    if Ship is TRanger then
    begin
      Ranger := Ship as TRanger;
      if Ranger.GetDominantCareer in CareerMask then
      begin
        if Result <> '' then
          Result := Result + ',' + ' ' + Ranger.Name
        else
          Result := Ranger.Name;
      end;
    end;
  end;
end;
function TStar.IsConstellationVisible: Boolean;
begin
  Result := Constellation.Visible;
end;
function TStar.GetCachedFactionStrength(FactionGroup: Byte): Single;
var
  I: Integer;
  Ship: TShip;
  RelativeScale,
  Weight,
  Strength,
  DominatorAndCustomStrength,
  CoalitionStrength,
  PirateStrength,
  Extra: Single;
begin
  if Galaxy.CurrentTurn = FactionStrengthCacheTurn then
    Result := Status.CachedFactionStrength[FactionGroup]
  else
  begin
    FactionStrengthCacheTurn := Galaxy.CurrentTurn;
    DominatorAndCustomStrength := 0;
    CoalitionStrength := 0;
    PirateStrength := 0;
    RelativeScale := 1 / Max(1, Galaxy.AverageRangerStrength);
    for I := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[I]);
      Weight := 1;
      if Ship.InHyperspace and (Ship.OrderTarget = Self) then
        Weight := Weight - 0.25;
      if Ship.InNormalSpace and (Ship.Order = soJump) then
        Weight := Weight - 0.5;
      if (Ship.DockedTo = nil)
          or (Ship.Order <> soNone)
          or not (Ship.DockedTo is TRuins)
          or (TRuins(Ship.DockedTo).FlyToStar = nil)
          or (TRuins(Ship.DockedTo).FlyToStar = Self) then
      begin
        if Ship.GetHull.HullPoints < Ship.GetHull.Weight * 0.25 then
          Weight := Weight - 0.5;
        Strength := Min(10, Max(0.1, Ship.Strength * RelativeScale)) * Weight;
        if Ship is TKling then
          Strength :=
              DominatorShipDefinitions[Ord((Ship as TKling).KlingType)].FactionStrengthWeight
                  * Strength;
        if Ship.CurrentStanding in [ssCoalitionMilitary, ssCoalitionActive] then
          CoalitionStrength := CoalitionStrength + Strength
        else if Ship.CurrentStanding in [ssPirateActive, ssPirateMilitary] then
          PirateStrength := PirateStrength + Strength
        else if Ship.CurrentStanding in [ssDominator, ssCustom] then
          DominatorAndCustomStrength := DominatorAndCustomStrength + Strength;
        if Ship is TNormalShip then
        begin
          Extra := Sqr((Ship as TNormalShip).CurrentSystemKills.Pirate) * Strength * 0.04;
          CoalitionStrength := CoalitionStrength + Extra;
          Extra := Sqr((Ship as TNormalShip).CurrentSystemKills.Normal) * Strength * 0.04;
          PirateStrength := PirateStrength + Extra;
          Extra := Sqr((Ship as TNormalShip).CurrentSystemKills.Dominator) * Strength * 0.04;
          if Ship.CurrentStanding in [ssCoalitionMilitary, ssCoalitionActive] then
            CoalitionStrength := CoalitionStrength + Extra
          else if Ship.CurrentStanding in [ssPirateActive, ssPirateMilitary] then
            PirateStrength := PirateStrength + Extra;
        end;
      end;
    end;
    // Native $7C5420/$7C5429/$7C5432 store these in TStar+$4C/$50/$54.
    Status.CachedFactionStrength[Ord(sfCoalition)] := CoalitionStrength;
    Status.CachedFactionStrength[Ord(sfDominators)] := DominatorAndCustomStrength;
    Status.CachedFactionStrength[Ord(sfPirates)] := PirateStrength;
    Result := Status.CachedFactionStrength[FactionGroup];
  end;
end;
function TStar.SumBestRangerRelativeStrength(ShipTypeMask: TShipTypeMask): Single;
var
  I: Integer;
  Ship: TShip;
begin
  Result := 0;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Ship <> BlazerShip)
        and (Ship <> KellerShip)
        and (Ship <> TerronShip)
        and (Ship.TypeId in ShipTypeMask) then
      Result := Result + Ship.StrengthInBestRanger;
  end;
end;
procedure TStar.RebuildStarDistances(Galaxy: TGalaxy);
var
  Count, I, J, Distance: Integer;
  Star: TStar;
begin
  Count := Galaxy.Stars.Count;
  StarDistances := nil;
  SetLength(StarDistances, Count);
  for I := 0 to Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    StarDistances[I].Star := Star;
    StarDistances[I].Distance := Round(PointDistance(Position, Star.Position));
  end;
  for I := 0 to Count - 2 do
    for J := I to Count - 1 do
      if StarDistances[J].Distance < StarDistances[I].Distance then
      begin
        Distance := StarDistances[J].Distance;
        StarDistances[J].Distance := StarDistances[I].Distance;
        StarDistances[I].Distance := Distance;
        Star := TObject(StarDistances[J].Star) as TStar;
        StarDistances[J].Star := StarDistances[I].Star;
        StarDistances[I].Star := Star;
      end;
end;
function TStar.HasHostilePresenceForScriptBinding: Boolean;
var
  I: Integer;
  Ship: TShip;
begin
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Ship is TKling)
        or (Ship.CurrentStanding = ssPirateMilitary)
        or Ship.HasIndependentScriptFaction then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
function TStar.FindNearestStarByFaction(Faction: TStarFaction; InBattle: Boolean): TStar;
var
  I: Integer;
  Star: TStar;
begin
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    Star := TObject(StarDistances[I].Star) as TStar;
    if (Star.ControlFaction = Faction)
        and (Star.Battle = Byte(InBattle))
        and (Star.Status.CustomFaction = '') then
    begin
      Result := Star;
      Exit;
    end;
  end;
  Result := nil;
end;
function TStar.GetBoundaryPointTowardStar(Star: TStar): TPointF;
var
  Angle, Radius: Double;
begin
  Angle := HeadingDegreesToRadians(PointBearingDegrees(Position, Star.Position));
  Radius := ComputeMapDiameter * 0.4;
  Result.X := Trunc(Sin(Angle) * Radius);
  Result.Y := Trunc(-Cos(Angle) * Radius);
end;
function TStar.HasLiberationGroupOrder: Boolean;
var
  I, J: Integer;
  Group: TGroup;
  Order: TGroupRouteOrder;
begin
  for I := 0 to Galaxy.LiberationGroups.Count - 1 do
  begin
    Group := Galaxy.LiberationGroups[I];
    for J := 0 to Length(Group.Route) - 1 do
    begin
      Order := Group.Route[J];
      if (Order.Target is TStar) and (Order.Target = Self) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;
procedure TStar.TryGenerateSystemNews;
var
  Chance: Integer;
  Names: WideString;
begin
  if IsConstellationVisible
      and (Galaxy.PlanetNews.Count < MaxPlanetNews)
      and (ControlFaction <> sfDominators)
      and (Battle = 0)
      and (Status.CustomFaction = '')
      and (Galaxy.CoalitionDefeatedTurn <= 0)
      and (Constellation.Id <> 20) then
  begin
    Chance := Round(RemapClamped(Galaxy.PlanetNews.Count, 0, MaxPlanetNews, 95, 5));
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2111) < Chance)
        and (Galaxy.CountPlanetNewsByType(18) = 0)
        and (ShipTypeCounts[stTransport] > 9) then
    begin
      Galaxy.AddPlanetNews(
          18,
          FormatText1(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Transport.Many',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2211) < Chance)
        and (Galaxy.CountPlanetNewsByType(18) = 0)
        and (ShipTypeCounts[stTransport] > 9) then
    begin
      Galaxy.AddPlanetNews(
          18,
          FormatText1(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Transport.Many1',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2311) < Chance)
        and (Galaxy.CountPlanetNewsByType(19) < 1)
        and (DaysSincePlayerVisit > 30)
        and (ShipTypeCounts[stKling] = 0)
        and (ShipTypeCounts[stPirate] > 4)
        and (ControlFaction <> sfPirates) then
    begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[stPirate]);
      Galaxy.AddPlanetNews(
          19,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Pirates.Many',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<AttackCount>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2411) < Chance)
        and (Galaxy.CountPlanetNewsByType(20) < 1)
        and (DaysSincePlayerVisit > 30)
        and (ShipTypeCounts[stKling] = 0)
        and (ShipTypeCounts[stPirate] > 2)
        and (ControlFaction <> sfPirates) then
    begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[stPirate]);
      Galaxy.AddPlanetNews(
          20,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Pirates.Some',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<AttackCount>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(50, 100, Galaxy.CurrentTurn * GenerationSeed * 2511) < Chance)
        and (Galaxy.CountPlanetNewsByType(21) < 1)
        and (DaysSincePlayerVisit > 30)
        and (ShipTypeCounts[stKling] = 0)
        and (ShipTypeCounts[stPirate] = 0)
        and (ControlFaction <> sfPirates) then
    begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[stPirate]);
      Galaxy.AddPlanetNews(
          21,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Pirates.None',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<AttackCount>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2611) < 90)
        and (Galaxy.CountPlanetNewsByType(22) = 0)
        and (ShipTypeCounts[stRanger] >= 4)
        and (CountRatedRangersByCareerMask([rcTrader]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcTrader]);
      Galaxy.AddPlanetNews(
          22,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.ManyTrader',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Names>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2711) < 90)
        and (Galaxy.CountPlanetNewsByType(22) = 0)
        and (ShipTypeCounts[stRanger] >= 4)
        and (CountRatedRangersByCareerMask([rcPirate]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcPirate]);
      Galaxy.AddPlanetNews(
          22,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.ManyPirate',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Names>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2811) < 90)
        and (Galaxy.CountPlanetNewsByType(22) = 0)
        and (ShipTypeCounts[stKling] = 0)
        and (ShipTypeCounts[stRanger] >= 4)
        and (CountRatedRangersByCareerMask([rcWarrior]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcWarrior]);
      Galaxy.AddPlanetNews(
          22,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.ManyWarrior',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Names>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3011) < 100)
        and (Galaxy.CountPlanetNewsByType(23) = 0)
        and (Galaxy.EminentCareerShips[Ord(rcTrader)] <> nil)
        and (Galaxy.EminentCareerShips[Ord(rcTrader)] as TRanger).InHyperspace
        and ((Galaxy.EminentCareerShips[Ord(rcTrader)] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[Ord(rcTrader)] as TRanger).Name;
      Galaxy.AddPlanetNews(
          23,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.BestTrader',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Name>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3111) < 100)
        and (Galaxy.CountPlanetNewsByType(23) = 0)
        and (Galaxy.EminentCareerShips[Ord(rcPirate)] <> nil)
        and (Galaxy.EminentCareerShips[Ord(rcPirate)] as TRanger).InHyperspace
        and ((Galaxy.EminentCareerShips[Ord(rcPirate)] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[Ord(rcPirate)] as TRanger).Name;
      Galaxy.AddPlanetNews(
          23,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.BestPirate',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Name>',
              Names
          )
      );
    end
    else if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3211) < 100)
        and (Galaxy.CountPlanetNewsByType(23) = 0)
        and (Galaxy.EminentCareerShips[Ord(rcWarrior)] <> nil)
        and (Galaxy.EminentCareerShips[Ord(rcWarrior)] as TRanger).InHyperspace
        and ((Galaxy.EminentCareerShips[Ord(rcWarrior)] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[Ord(rcWarrior)] as TRanger).Name;
      Galaxy.AddPlanetNews(
          23,
          FormatText2(
              PickLocalizedTextVariant(
                  'GalaxyNews.Star.Rangers.BestWarrior',
                  (Galaxy.CurrentTurn div 10) * GenerationSeed
              ),
              '<color=255,240,100>',
              '<Star>',
              Name,
              '<Name>',
              Names
          )
      );
    end;
  end;
end;
procedure UpdateTurnFilmActivity(
    CombatOccurred: Boolean;
    out InitialActivity, FinalActivity: Integer
);
var
  TravelTurns: Single;
begin
  if CombatOccurred then
  begin
    InitialActivity := 0;
    FinalActivity := 0;
  end
  else
  begin
    InitialActivity := Integer(Globals.PreviousFilmActivity);
    FinalActivity := InitialActivity;
    TravelTurns := EstimatePlayerTravelTurns;
    if Globals.PreviousFilmActivity = 0 then
    begin
      if TravelTurns >= 1.0 then
        FinalActivity := 1;
    end
    else if Globals.PreviousFilmActivity = 1 then
    begin
      if TravelTurns >= 2.0 then
        FinalActivity := 2;
    end
    else if (Globals.PreviousFilmActivity = 2) and (TravelTurns <= 2.0) then
      FinalActivity := 1;
    Globals.PreviousFilmActivity := Cardinal(FinalActivity);
  end;
end;
{ Source helpers; both inline away without changing the native instructions. }
function CurrentFilm: TEFilm; inline;
begin
  Result := TEFilm(PrimaryFilm);
end;
{ Constant arguments preserve evaluation order; computed arguments stay at their call sites. }
procedure CreateFilmEffect(
    const GraphKey: WideString;
    ShotVisual: Integer;
    out Effect: TObjectSE;
    out EffectFilm: TEFilmObj
); inline;
begin
  Effect := TWeaponSE.Create(GraphKey, Classes.Point(0, 0), ShotVisual, -1);
  EffectFilm := CurrentFilm.AddObject(0, Effect);
end;
procedure TStar.NextDay(RecordFilm: Boolean);
var
  { Local order and unused Reserved slots preserve the native DCC32 frame. }
  Item: TItem;
  Ship: TShip;
  Quantity: Integer;
  i: Integer;
  StepIndex: Integer;
  PathStep: Integer;
  Index: Integer;
  AttackRound: Integer;
  ArtefactIndex: Integer;
  Count: Integer;
  EntryIndex: Integer;
  EntryCount: Integer;
  DestinationShipCount: Integer;
  CandidateIndex: Integer;
  CandidateCount: Integer;
  CombatGroup: Integer;
  WorkCount: Integer;
  NodeIndex: Integer;
  ClosestNodeIndex: Integer;
  PulledItemCount: Integer;
  MineralValue: Integer;
  AttackCount: Integer;
  ShotEndMargin: Integer;
  WorkValue: Single;
  WorkScale: Single;
  WearMultiplier: Single;
  Reserved113,
  Reserved114,
  Reserved115,
  Reserved116,
  Reserved117,
  Reserved118,
  Reserved119,
  Reserved120,
  Reserved121,
  Reserved122,
  Reserved123,
  Reserved124,
  Reserved125: Byte;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  OwnerShip: TShip;
  GroupLeader: TShip;
  HitShip: TShip;
  NearestShip: TShip;
  OtherItem: TItem;
  NearestItem: TItem;
  Weapon: TWeapon;
  MovingDrop: PMovingDropItemEntry;
  CombatEvent: PStarCombatEvent;
  ExtraAttack: PStarCombatEvent;
  QueuedAttack: PStarCombatEvent;
  DamageColor: Cardinal;
  Damage: Cardinal;
  Reserved189: Byte;
  DrainedDamage: Integer;
  ObjectFilm: TEFilmObj;
  Distance: Single;
  Angle: Single;
  WorkX: Single;
  WorkY: Single;
  ImpactX: Single;
  ImpactY: Single;
  ClosestDistance: Single;
  Point: TPointF;
  Delta: TPointF;
  Node: PSPathNode;
  Effect: TObjectSE;
  EffectFilm: TEFilmObj;
  GateEntry: PJumpGateEntry;
  Target: Pointer;
  StoredTranclucator: Pointer;
  Tranclucator: TTranclucator;
  Reserved273: Byte;
  Hole: THole;
  CanPull: ShortInt;
  Reserved282, Reserved283: Byte;
  StationDestroyed: ShortInt;
  Missile: TMissile;
  InterceptedMissile: TMissile;
  Reserved293, Reserved294, Reserved295, Reserved296, Reserved297: Byte;
  BertorBoost: Boolean;
  RemainingAmmo: Integer;
  PickupIndex: Integer;
  PickupWeight: Integer;
  DeathEvent: Pointer;
  FilmText: WideString;
  NearestMissileDistance: Integer;
  MissileDistance: Integer;
  PointDefenseRangeSquared: Integer;
  BestMissilePriority: Integer;
  MissilePriority: Integer;
  Reserved341, Reserved342, Reserved343, Reserved344, Reserved345: Byte;
  ActionResult: Integer;
  HitFlags: array[0..3] of ShortInt;
  Reserved357: Byte;
  Stage: Integer;
  procedure CompleteItemPickup; // @addr 0x7C67E4 @ida "void __cdecl $name(void *ParentFrame);" @note "Caller-popped static link; item -4, ship -8, star -12, film flag -13. Transfers, merges or consumes the completed pickup; may free the item."
  var
    Series: TDominatorSeries;
    ResearchCount, Index, PickupResult: Integer;
  begin
    if Item.DestroyFlag > 0 then
      Exit;
    Ship.ApplyItemDegradation(Ship.GetCargoHook, idkUse, 3);
    Items.Delete(Items.IndexOf(Item));
    ClearItemReferences(Item);
    if Item is TArtefact then
    begin
      (Item as TEquipment).EquippedFlag := 0;
      Ship.Artefacts.Add(Item);
      if Item is TArtefactTranclucator then
        (TObject((Item as TArtefactTranclucator).Ship) as TTranclucator).OwnerShip := Ship;
    end
    else if Item is TCountableItem then
    begin
      TCountableItem(Item).DropFlag := 0;
      if not RecordFilm then
        Item.ReleaseGraphObject
      else
      begin
        PendingFilmObjectRemovals.Add(Item.FilmObject);
        ReleaseSpaceObject(Item.GraphObject);
      end;
      (Item as TEquipment).EquippedFlag := 0;
      Quantity := Ship.Inventory.Count;
      i := 0;
      while i < Quantity do
      begin
        if (Item as TCountableItem).CanMerge(Ship.Inventory[i]) then
          Break;
        Inc(i);
      end;
      if i < Quantity then
      begin
        TCountableItem(Ship.Inventory[i]).Merge(Item);
        Item.DestroyFlag := 1;
      end
      else
      begin
        Item.DestroyFlag := 0;
        Ship.Inventory.Add(Item);
      end;
    end
    else if Item is TEquipment then
    begin
      (Item as TEquipment).EquippedFlag := 0;
      if (Ship is TRuins) and (Item.ItemType in [t_Hull..t_CustomWeapon]) then
        (Ship as TRuins).EquipmentShop.Add(Item)
      else if (Ship is TWarrior)
          and ((Ship as TWarrior).WarriorType = wtFlagship)
          and (Item is TUselessItem)
          and (Item as TUselessItem).IsDominatorRemains then
      begin
        Series := TDominatorSeries(TEquipment(Item).DominatorSeries);
        if (Galaxy.DominatorResearch[Ord(Series)].Progress < 100)
            and Galaxy.IsDominatorSeriesUnresolved(Series) then
          Ship.SetMoney(Round(Item.Cost * 3.0) + Ship.Money)
        else
          Ship.SetMoney(Round(Item.Cost * 2.0) + Ship.Money);
        if (Galaxy.DominatorResearch[Ord(Series)].Progress < 100)
            and Galaxy.IsDominatorSeriesUnresolved(Series) then
          Inc(Galaxy.DominatorResearch[Ord(Series)].Material, Item.Weight)
        else
        begin
          ResearchCount := 0;
          for Series := dsBlazer to dsTerron do
            if (Galaxy.DominatorResearch[Ord(Series)].Progress < 100)
                and Galaxy.IsDominatorSeriesUnresolved(Series) then
              Inc(ResearchCount);
          if ResearchCount > 0 then
            for Series := dsBlazer to dsTerron do
              if (Galaxy.DominatorResearch[Ord(Series)].Progress < 100)
                  and Galaxy.IsDominatorSeriesUnresolved(Series) then
                Inc(Galaxy.DominatorResearch[Ord(Series)].Material, Item.Weight div ResearchCount);
        end;
      end
      else
        Ship.Inventory.Add(Item);
    end
    else if Item is TGoods then
    begin
      if Ship is TRuins then
        Inc(
            (Ship as TRuins).ShopGoods[Ord((Item as TGoods).ItemType)].Count,
            (Item as TGoods).Quantity
        )
      else
      begin
        Inc(Ship.CargoGoods[Ord((Item as TGoods).ItemType)].Count, (Item as TGoods).Quantity);
        Inc(Ship.CargoGoods[Ord((Item as TGoods).ItemType)].TotalCost, (Item as TGoods).Cost);
      end;
    end;
    Ship.RefreshDerivedStats(True);
    PickupResult := Ship.ScriptItemsAct(satOnItemPickUp, Item, nil, 0);
    if PickupResult <> 0 then
    begin
      if Item is TArtefact then
      begin
        Index := Ship.Artefacts.IndexOf(Item);
        if Index >= 0 then
          Ship.Artefacts.Delete(Index);
      end
      else
      begin
        Index := Ship.Inventory.IndexOf(Item);
        if Index >= 0 then
          Ship.Inventory.Delete(Index);
      end;
    end;
    if (Ship.CargoFreeSpace < 0) and (GetPlayer <> Ship) then
    begin
      Ship.AutoEquipInventory;
      Ship.ClearUnequippedWeaponTargets;
      Ship.DropCargoUntilNotOverloaded;
      Ship.AutoEquipInventory;
      Ship.ClearUnequippedWeaponTargets;
      if Ship.CargoFreeSpace <= 0 then
        Ship.ClearPickupTargets;
      Ship.RefreshDerivedStats(True);
    end
    else if (Item.ItemType in [t_FuelTanks..t_CustomWeapon])
        and (PlayerAutomaticControl
            or ((GetPlayer <> Ship) and (Ship.TypeId <> stTranclucator))) then
    begin
      Ship.AutoEquipInventory;
      Ship.ClearUnequippedWeaponTargets;
      Ship.RefreshDerivedStats(True);
    end;
    if GetPlayer = Ship then
      InterruptLongTravel := True;
    if RecordFilm then
    begin
      PrimaryFilm.PlayPickupSound(StepIndex, Item.FilmObject);
      PrimaryFilm.DetachObject(StepIndex, Item.FilmObject);
    end;
    if (PickupResult < 0)
        or (Item is TGoods)
        or ((Ship is TWarrior)
            and ((Ship as TWarrior).WarriorType = wtFlagship)
            and (Item is TUselessItem)
            and (Item as TUselessItem).IsDominatorRemains) then
    begin
      if RecordFilm then
        PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
      Item.Free;
    end
    else if (Item is TCountableItem) and (Item.DestroyFlag > 0) then
      Item.Free
    else if RecordFilm and (Item.GraphObject <> nil) then
    begin
      ReleaseSpaceObject(Item.GraphObject);
      PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
    end;
    if Ship.Speed <= 0 then
      Ship.MovementPath.Clear;
  end;
begin
  Stage := 0;
  try
    Self.RefreshMovementStepParameters;
    // CHANGE: ENHANCEMENT - Capture simulation steps for observer playback.
    if Assigned(ObserverStep) then
      ObserverStep(Self, 0, Self.MovementStepCount);
    if (GetPlayer <> nil) and (GetPlayer.CurrentStar = Self) then
    begin
      Self.DaysSincePlayerVisit := 0;
      GetPlayer.BombKillsThisTurn := 0;
      if Self.PlayerPresenceLevel < 90 then
        Inc(Self.PlayerPresenceLevel);
    end
    else
    begin
      Inc(Self.DaysSincePlayerVisit);
      if Self.PlayerPresenceLevel > 0 then
        Dec(Self.PlayerPresenceLevel);
    end;
    if not Globals.PlayerStarDayPrepared then
      Inc(Self.DaysSinceLastNpcShipSpawn);
    Self.RecordingTurnFilm := RecordFilm;
    Self.PlayerCombatOccurred := False;
    Self.InterruptLongTravel := False;
    Self.KeepFilmRunning := False;
    StepIndex := 0;
    Self.CurrentStepIndex := 0;
    Stage := 1;
    if not Globals.PlayerStarDayPrepared then
      Self.TryGenerateSystemNews;
    Stage := 2;
    if not Globals.PlayerStarDayPrepared and (Galaxy.StasisModEnabled <> 1) then
      for Index := 0 to (Self.Asteroids.Count - 1) do
      begin
        Asteroid := Self.Asteroids[Index];
        Asteroid.RespawnIfOutsideSystem;
      end;
    Stage := 3;
    if WingmenPendingLeadershipPenalty = nil then
      WingmenPendingLeadershipPenalty := TList.Create;
    if not Globals.PlayerStarDayPrepared then
    begin
      for Index := (Self.Ships.Count - 1) downto 0 do
      begin
        Ship := Self.Ships[Index];
        Ship.RefreshCurrentStanding;
      end;
      for Index := (Self.Ships.Count - 1) downto 0 do
      begin
        Ship := Self.Ships[Index];
        if (Galaxy.StasisModEnabled <> 1) or (GetPlayer = Ship) then
          Ship.NextDay;
        if (Ship.PartnerShip <> nil)
            and ((Ship.PartnershipDaysRemaining > 0)
                and (WingmenPendingLeadershipPenalty.IndexOf(Ship) < 0)) then
          WingmenPendingLeadershipPenalty.Add(Ship);
      end;
    end;
    Stage := 4;
    Self.ProcessItemScripts(0);
    Stage := 5;
    for Index := 0 to (Self.Ships.Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if (Ship.Order = soLand)
          and ((TObject(Ship.OrderTarget) is TShip)
              and ((TObject(Ship.OrderTarget) as TShip).Order <> soNone)) then
      begin
        if (TObject(Ship.OrderTarget) as TShip).Order <> soTeleport then
          (TObject(Ship.OrderTarget) as TShip).OrderNone(False)
        else
          Ship.OrderNone(False);
      end
      else
      begin
        if (Ship.Order = soTakeoff)
            and ((Ship.DockedTo <> nil)
                and ((Ship.DockedTo.Order <> soNone) and (Ship.DockedTo.Order <> soTeleport))) then
          Ship.DockedTo.OrderNone(False);
      end;
    end;
    Stage := 6;
    if RecordFilm then
    begin
      CurrentFilm.SystemProcessName := WideString(Self.SystemProcessName);
      CurrentFilm.MapDiameter := Self.ComputeMapDiameter;
      CurrentFilm.StarGenerationSeed := Self.GenerationSeed;
      CurrentFilm.BackgroundImage := Cardinal(Self.BackgroundImage);
      CurrentFilm.Turn := Galaxy.CurrentTurn;
      CurrentFilm.RadarRange := 0;
      Stage := 60;
      if GetPlayer.IsEquipmentUsable(GetPlayer.GetRadar) then
        CurrentFilm.RadarRange := GetPlayer.GetRadarRange;
      Stage := 61;
      ObjectFilm := CurrentFilm.AddObject(Integer(Self.Id), Self.Graphic);
      CurrentFilm.SetObjectPosition(StepIndex, ObjectFilm, MakePointF(0.0, 0.0));
      CurrentFilm.AttachObject(StepIndex, ObjectFilm);
      Stage := 62;
      (TObject(CurrentFilm.ObjectInfo) as TEObjInfo).LoadFromStar(Self);
    end;
    Stage := 7;
    if (Galaxy.KellerMissionState = 2)
        and ((Galaxy.KellerTargetStar = Self)
            and ((aKling.KellerShip <> nil)
                and ((aKling.KellerShip.CurrentStar = Self)
                    and (Galaxy.StasisModEnabled <> 1)))) then
      aKling.KellerShip.OpenKellerMissionHole;
    if (Galaxy.KellerMissionState = 4)
        and ((aKling.KellerShip <> nil)
            and ((aKling.KellerShip.CurrentStar = Self)
                and ((Ord(aKling.KellerShip.InHyperspace) <> 0)
                    and (Galaxy.StasisModEnabled <> 1)))) then
    begin
      Hole := Galaxy.FindHoleInStarByKind(Self, 4);
      if Hole = nil then
        raise Exception.Create('Hole not found');
      aKling.KellerShip.Order := soJump;
      aKling.KellerShip.OrderTarget := aKling.KellerShip.CurrentStar;
      aKling.KellerShip.OrderAbsolute := False;
      aKling.KellerShip.OrderDestination := MakePointF(0.0, 0.0);
      aKling.KellerShip.OrderStateData := 2;
      Galaxy.KellerMissionState := 5;
    end;
    Stage := 8;
    Count := Self.Ships.Count;
    for Index := 0 to (Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if not Ship.IsOutsideStarSpace
          and ((Galaxy.StasisModEnabled <> 1) or (GetPlayer = Ship))
          and ((Ship.TypeId <> stKling)
              or (((Ship as TKling).ActiveProgramAppliedTurn <= 0)
                  or not (Byte((Ship as TKling).ActiveProgramId) in [7, 11]))) then
      begin
        for AttackRound := 1 to Ship.GetAttackMultiplier do
        begin
          for EntryIndex := 1 to Ship.WeaponCount do
          begin
            Weapon := Ship.Weapons[EntryIndex];
            if Weapon.Target <> nil then
            begin
              if (TObject(Weapon.Target) is TItem)
                  or ((TObject(Weapon.Target) is TAsteroid)
                      or ((TObject(Weapon.Target) is TMissile)
                          or (TObject(Weapon.Target) is TShip)
                              and (TObject(Weapon.Target) as TShip).InNormalSpace)) then
              begin
                CombatEvent := AllocEC(SizeOf(CombatEvent^));
                CombatEvent^.Attacker := Ship;
                CombatEvent^.Target := Weapon.Target;
                CombatEvent^.Weapon := Weapon;
                CombatEvent^.CombatGroup := 0;
                if Self.MovementStepCount = 200 then
                  ShotEndMargin := 30
                else
                  ShotEndMargin := 1;
                CombatEvent^.StepIndex :=
                    Integer(
                        System.Round(
                            Weapon.GetShotDelayFactor * (Self.MovementStepCount - ShotEndMargin)
                        )
                    );
                if (GetPlayer = Ship) or (GetPlayer = CombatEvent^.Target) then
                  Self.PlayerCombatOccurred := True;
                Quantity := Self.CombatEvents.Count;
                i := 0;
                while i < Quantity do
                begin
                  QueuedAttack := Self.CombatEvents[i];
                  if CombatEvent^.StepIndex < QueuedAttack^.StepIndex then
                    Break;
                  Inc(i);
                end;
                if i >= Quantity then
                begin
                  Self.CombatEvents.Add(CombatEvent);
                  if (Weapon.GetAttackCount > 1)
                      and not (Byte(Weapon.GetWeaponInfo^.ShotType)
                          in [Ord(wstTorpedo)..Ord(wstRocket)]) then
                  begin
                    for CandidateIndex := 2 to Weapon.GetAttackCount do
                    begin
                      ExtraAttack := AllocEC(SizeOf(ExtraAttack^));
                      ExtraAttack^.Attacker := Ship;
                      ExtraAttack^.Target := Weapon.Target;
                      ExtraAttack^.Weapon := Weapon;
                      ExtraAttack^.CombatGroup := 0;
                      ExtraAttack^.StepIndex := CombatEvent^.StepIndex;
                      Self.CombatEvents.Add(ExtraAttack);
                    end;
                  end;
                end
                else
                begin
                  Self.CombatEvents.Insert(i, CombatEvent);
                  if (Weapon.GetAttackCount > 1)
                      and not (Byte(Weapon.GetWeaponInfo^.ShotType)
                          in [Ord(wstTorpedo)..Ord(wstRocket)]) then
                  begin
                    for CandidateIndex := 2 to Weapon.GetAttackCount do
                    begin
                      ExtraAttack := AllocEC(SizeOf(ExtraAttack^));
                      ExtraAttack^.Attacker := Ship;
                      ExtraAttack^.Target := Weapon.Target;
                      ExtraAttack^.Weapon := Weapon;
                      ExtraAttack^.CombatGroup := 0;
                      ExtraAttack^.StepIndex := CombatEvent^.StepIndex;
                      Self.CombatEvents.Insert(i, ExtraAttack);
                    end;
                  end;
                end;
                if Ship.TypeId <> stKling then
                begin
                  if (GetPlayer = Ship) and Ship.IsHealthEffectActive(10) then
                    WearMultiplier := 3.0
                  else
                    WearMultiplier := 1.0;
                  Ship.ApplyItemDegradation(
                      Weapon,
                      idkUse,
                      NextRandomUnitFloat(Ship.RandomState) * 2.0 * WearMultiplier
                  );
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    Stage := 9;
    if RecordFilm then
    begin
      CombatGroup := 0;
      Count := Self.CombatEvents.Count;
      for Index := 0 to (Count - 1) do
      begin
        CombatEvent := Self.CombatEvents[Index];
        if CombatEvent^.CombatGroup = 0 then
        begin
          Inc(CombatGroup);
          CombatEvent^.CombatGroup := CombatGroup;
          Self.MarkConnectedCombatEvents(
              Self.CombatEvents,
              TShip(CombatEvent^.Attacker),
              CombatGroup
          );
          Self.MarkConnectedCombatEvents(Self.CombatEvents, CombatEvent^.Target, CombatGroup);
        end;
      end;
      for Index := 1 to CombatGroup do
      begin
        Quantity := 0;
        for EntryIndex := 0 to (Count - 1) do
        begin
          CombatEvent := Self.CombatEvents[EntryIndex];
          if CombatEvent^.CombatGroup = Index then
            Inc(Quantity);
        end;
        WorkValue := 5.0;
        WorkScale := 170.0 / Quantity;
        for EntryIndex := 0 to (Count - 1) do
        begin
          CombatEvent := Self.CombatEvents[EntryIndex];
          if CombatEvent^.CombatGroup = Index then
          begin
            CombatEvent^.StepIndex := Integer(System.Round(WorkValue));
            WorkValue := WorkValue + WorkScale;
          end;
        end;
      end;
    end;
    Stage := 10;
    Count := Self.Ships.Count;
    for Index := 0 to (Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if not Ship.InHyperspace then
      begin
        if Ship.Order <> soFollowShip then
          Ship.BuildOrderMovementPath(Self.MovementStepCount)
        else
        begin
          Ship.ClearMovementPath;
          Ship.OrderDestination := Ship.Position;
          if Ship.GetEffectiveFollowMode = 0 then
          begin
            Angle :=
                HeadingDegreesToRadians(
                    Abs(
                            Integer(
                                Cardinal(Galaxy.CurrentTurn)
                                    * (Ship.Seed
                                        * Cardinal((TObject(Ship.OrderTarget) as TShip).Seed))
                            ))
                        mod 360
                );
            WorkCount := Ship.CalculateFollowRadius;
            Ship.RepulsionPosition.X := System.Sin(Angle) * WorkCount;
            Ship.RepulsionPosition.Y := System.Cos(Angle) * -WorkCount;
          end;
        end;
      end;
    end;
    Stage := 11;
    Count := Self.MovementStepCount;
    Self.SimulationStepCount := Cardinal(Count);
    EntryCount := Self.Ships.Count;
    for PathStep := 0 to (Count - 1) do
    begin
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        Ship := Self.Ships[EntryIndex];
        if Ship.Order = soFollowShip then
        begin
          OwnerShip := TObject(Ship.OrderTarget) as TShip;
          PickupWeight := 0;
          if (GetPlayer = OwnerShip)
              and ((OwnerShip.PickupTargets <> nil) and OwnerShip.InNormalSpace) then
            for PickupIndex := 0 to (OwnerShip.PickupTargets.Count - 1) do
            begin
              if OwnerShip.IsItemInPickupRange(OwnerShip.PickupTargets[PickupIndex]) then
                PickupWeight := PickupWeight + TItem(OwnerShip.PickupTargets[PickupIndex]).Weight;
            end;
          if (OwnerShip.Order <> soFollowShip) or (OwnerShip.CargoFreeSpace < PickupWeight) then
          begin
            if OwnerShip.IsOnPlanet and (OwnerShip.Order = soNone) then
            begin
              if (Ship is TTranclucator)
                  and (TTranclucator(Ship).CanFollowOwnerInCurrentStar
                      and (TTranclucator(Ship).OwnerShip = OwnerShip)) then
                Point := TPlanet(OwnerShip.CurrentPlanet).PredictPosition(Self.MovementStepCount)
              else
                Point := TPlanet(OwnerShip.CurrentPlanet).GetPosition;
            end
            else
            begin
              if OwnerShip.IsDockedToShip and (OwnerShip.Order = soNone) then
                Point := OwnerShip.DockedTo.Position
              else
              begin
                if (OwnerShip.MovementPath.ActiveTail = nil)
                    or (OwnerShip.CargoFreeSpace < PickupWeight) then
                  Point := OwnerShip.Position
                else
                  Point := OwnerShip.MovementPath.ActiveTail^.Position;
              end;
            end;
          end
          else
            Point := OwnerShip.OrderDestination;
          if (Galaxy.StasisModEnabled = 1) and (GetPlayer = Ship) then
            Point := OwnerShip.Position;
          if (Ship.GetEffectiveFollowMode = 0)
              and ((Ship is TTranclucator)
                  and (Ship as TTranclucator).CanFollowOwnerInCurrentStar) then
          begin
            Ship.OrderDestination := Point;
            WorkValue := 0.0;
          end
          else
          begin
            WorkCount := Ship.CalculateFollowRadius;
            WorkScale := Ship.MovementSpeed * 200.0 * Self.MovementStepScale;
            if Ship.GetEffectiveFollowMode = 0 then
            begin
              Point.X := Point.X + Ship.RepulsionPosition.X;
              Point.Y := Point.Y + Ship.RepulsionPosition.Y;
              Distance := PointDistance(Ship.OrderDestination, Point);
              WorkValue := 0.0 - Distance;
            end
            else
            begin
              Distance := PointDistance(Ship.OrderDestination, Point);
              WorkValue := WorkCount - Distance;
            end;
            if Distance <> 0.0 then
            begin
              if WorkValue <= 0.0 then
              begin
                WorkValue := Min(-WorkValue, WorkScale) / Distance;
                Delta.X := (Point.X - Ship.OrderDestination.X) * WorkValue;
                Delta.Y := (Point.Y - Ship.OrderDestination.Y) * WorkValue;
              end
              else
              begin
                WorkValue := Min(WorkValue, WorkScale) / Distance;
                Delta.X := (Ship.OrderDestination.X - Point.X) * WorkValue;
                Delta.Y := (Ship.OrderDestination.Y - Point.Y) * WorkValue;
              end;
              Distance := Self.MapDiameter / 2.0;
              WorkScale :=
                  Ship.OrderDestination.X * Ship.OrderDestination.X
                      + Ship.OrderDestination.Y * Ship.OrderDestination.Y;
              if (Sqr(0.7 * Distance) < WorkScale)
                  and ((Delta.X * Ship.OrderDestination.X + Delta.Y * Ship.OrderDestination.Y > 0.0)
                      and ((TShip(Ship.OrderTarget).Order = soFollowShip)
                          and (TShip(Ship.OrderTarget).OrderDestination.X
                                      * TShip(Ship.OrderTarget).OrderDestination.X
                                  + TShip(Ship.OrderTarget).OrderDestination.Y
                                      * TShip(Ship.OrderTarget).OrderDestination.Y
                              <= WorkScale))) then
              begin
                Angle :=
                    HeadingDegreesToRadians(
                        RemapClamped(
                            System.Sqrt(WorkScale) - 0.7 * Distance,
                            0.0,
                            0.5 * Distance,
                            0.0,
                            45.0
                        )
                    );
                if Delta.X * Ship.OrderDestination.Y - Delta.Y * Ship.OrderDestination.X > 0.0 then
                  Angle := -Angle;
                Point := Delta;
                WorkX := System.Sin(Angle);
                WorkY := System.Cos(Angle);
                Delta.X := Point.X * WorkY - Point.Y * WorkX;
                Delta.Y := Point.X * WorkX + Point.Y * WorkY;
              end;
              Ship.OrderDestination.X := Ship.OrderDestination.X + Delta.X;
              Ship.OrderDestination.Y := Ship.OrderDestination.Y + Delta.Y;
            end;
          end;
        end;
      end;
    end;
    Stage := 12;
    Stage := 13;
    if RecordFilm then
    begin
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        Ship := Self.Ships[EntryIndex];
        if Ship.Order = soFollowShip then
          Ship.RepulsionPosition := Ship.Position;
      end;
      for PathStep := 1 to (Count - 1) do
      begin
        for EntryIndex := 0 to (EntryCount - 1) do
        begin
          Ship := Self.Ships[EntryIndex];
          if (Ship.Order in [soMove, soFollowShip])
              and ((not (Ship is TTranclucator) or (Ord(TTranclucator(Ship).FollowOwner) = 0))
                  and (not (Ship is TKling)
                      or (((Ship as TKling).KlingType <> ktBoss)
                          or ((Ship as TKling).DominatorSeries <> dsTerron)))) then
          begin
            WorkScale := Ship.MovementSpeed;
            if (Galaxy.StasisModEnabled = 1) and (GetPlayer <> Ship) then
              WorkScale := 0.0;
            Distance := PointDistanceSquared(Ship.RepulsionPosition, Ship.OrderDestination);
            if Distance <> 0.0 then
            begin
              if Sqr(WorkScale) >= Distance then
                Ship.RepulsionPosition := Ship.OrderDestination
              else
              begin
                Distance := 1.0 / System.Sqrt(Distance) * WorkScale;
                Ship.RepulsionPosition.X :=
                    (Ship.OrderDestination.X - Ship.RepulsionPosition.X) * Distance
                        + Ship.RepulsionPosition.X;
                Ship.RepulsionPosition.Y :=
                    (Ship.OrderDestination.Y - Ship.RepulsionPosition.Y) * Distance
                        + Ship.RepulsionPosition.Y;
              end;
              if Galaxy.StasisModEnabled <> 1 then
                Ship.RepelFollowingShips;
            end;
          end;
        end;
      end;
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        Ship := Self.Ships[EntryIndex];
        if (Ship.Order = soFollowShip)
            and (not (Ship is TTranclucator) or (Ord(TTranclucator(Ship).FollowOwner) = 0))
            and (not (Ship is TKling)
                or (((Ship as TKling).KlingType <> ktBoss)
                    or ((Ship as TKling).DominatorSeries <> dsTerron))) then
          Ship.OrderDestination := Ship.RepulsionPosition;
      end;
    end;
    Stage := 14;
    Count := Self.Ships.Count;
    for Index := 0 to (Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if Ship.Order = soFollowShip then
      begin
        if (Sqr(Ship.Position.X) + Sqr(Ship.Position.Y) > Sqr(Self.SafeRadius))
            and (Sqr(Ship.OrderDestination.X) + Sqr(Ship.OrderDestination.Y)
                < Sqr(Self.SafeRadius)) then
        begin
          RayIntersectsOriginCircle(Ship.Position, Ship.OrderDestination, Point, Self.SafeRadius);
          WorkValue := PointDistance(Point, Ship.OrderDestination);
          WorkScale := HeadingDegreesToRadians(WorkValue * 360.0 / (2 * Pi * Self.SafeRadius));
          WorkValue := Math.ArcTan2(Point.X, -Point.Y);
          if HeadingDifferenceDegrees(
                  RadiansToHeadingDegrees(WorkValue),
                  RadiansToHeadingDegrees(
                      Math.ArcTan2(Ship.Position.X - Point.X, -(Ship.Position.Y - Point.Y))
                  ))
              < 0.0 then
            WorkValue := WorkValue + WorkScale
          else
            WorkValue := WorkValue - WorkScale;
          Ship.OrderDestination.X := System.Sin(WorkValue) * (Self.SafeRadius + 0.1);
          Ship.OrderDestination.Y := -System.Cos(WorkValue) * (Self.SafeRadius + 0.1);
        end;
        Ship.RebuildMovePath;
      end;
    end;
    Stage := 15;
    Count := Self.Ships.Count;
    for Index := 0 to (Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if (Ship.Order = soJump) and (Ship.TypeId = stRanger) then
      begin
        if Ship.MovementPath.ActiveHead <> nil then
        begin
          if Sqr(Ship.Speed + 100)
              < PointDistanceSquared(
                  Ship.MovementPath.ActiveHead^.Position,
                  Ship.MovementPath.ActiveTail^.Position) then
          begin
            GroupLeader := (Ship as TRanger).PartnerShip;
            if GroupLeader = nil then
              GroupLeader := Ship;
            for EntryIndex := 0 to (Count - 1) do
            begin
              OwnerShip := Self.Ships[EntryIndex];
              if (OwnerShip.Order = soJump)
                  and (OwnerShip.OrderTarget = Ship.OrderTarget)
                  and (OwnerShip.TypeId = stRanger)
                  and (Ship <> OwnerShip) then
              begin
                if ((OwnerShip as TRanger).PartnerShip = GroupLeader)
                    or (OwnerShip = GroupLeader) then
                begin
                  if (OwnerShip.MovementPath.ActiveHead = nil)
                      or (Sqr(OwnerShip.Speed + 100)
                          >= PointDistanceSquared(
                              OwnerShip.MovementPath.ActiveHead^.Position,
                              OwnerShip.MovementPath.ActiveTail^.Position)) then
                  begin
                    if ((OwnerShip.PickupTargets = nil) or (OwnerShip.PickupTargets.Count <= 0))
                        and (PointDistanceSquared(Ship.Position, OwnerShip.Position)
                            <= 640000.0) then
                    begin
                      Angle :=
                          Abs(
                              HeadingDifferenceDegrees(
                                  OwnerShip.MovementDirection,
                                  RadiansToHeadingDegrees(
                                      Math.ArcTan2(-Ship.Position.X, Ship.Position.Y)
                                  )
                              )
                          );
                      if (Angle >= 90.0) and (OwnerShip.Speed >= 200) or (Angle >= 175.0) then
                      begin
                        OwnerShip.ClearMovementPath;
                        if (Angle < 175.0)
                            and ((OwnerShip.Speed >= 200)
                                and (OwnerShip.CurrentStar = PlayerStar)) then
                        begin
                          Distance :=
                              1.0
                                  / System.Sqrt(
                                      Ship.Position.X * Ship.Position.X
                                          + Ship.Position.Y * Ship.Position.Y);
                          Point.X := Ship.Position.X * Distance * 10000.0 + OwnerShip.Position.X;
                          Point.Y := Ship.Position.Y * Distance * 10000.0 + OwnerShip.Position.Y;
                          OwnerShip.AppendTurningPath(Point, False, 200);
                        end;
                        OwnerShip.AppendHyperspaceTransitionPath(1.0);
                        if OwnerShip.MovementPath.ActiveTail <> nil then
                          OwnerShip.OrderDestination := OwnerShip.MovementPath.ActiveTail^.Position
                        else
                          OwnerShip.OrderDestination := OwnerShip.Position;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    Stage := 16;
    if PlayerStar = Self then
      Self.AvoidShipPathCollisions;
    Stage := 17;
    if RecordFilm then
    begin
      EntryCount := Galaxy.JumpGates.Count;
      for Index := 0 to (EntryCount - 1) do
      begin
        GateEntry := Galaxy.JumpGates[Index];
        GateEntry^.UsedThisTurn := True;
        ObjectFilm := CurrentFilm.AddObject(0, GateEntry^.Gate);
        GateEntry^.GateFilmId := PtrUInt(ObjectFilm);
        CurrentFilm.SetObjectPosition(StepIndex, ObjectFilm, GateEntry^.Gate.Position);
        CurrentFilm.SetObjectAngle(StepIndex, ObjectFilm, GateEntry^.Gate.GetAngle);
        CurrentFilm.SetGateSize(StepIndex, ObjectFilm, GateEntry^.Gate.Size.X);
        CurrentFilm.SetGateState(StepIndex, ObjectFilm, 2);
        CurrentFilm.CloseGate(StepIndex, ObjectFilm);
        CurrentFilm.SetObjectText(StepIndex, ObjectFilm, GateEntry^.Gate.GetText);
        CurrentFilm.AttachObject(StepIndex, ObjectFilm);
        if (GateEntry^.Effect <> nil) and TObjectSE(GateEntry^.Effect).IsAttachedToSpace then
        begin
          ObjectFilm := CurrentFilm.AddObject(0, GateEntry^.Effect);
          GateEntry^.EffectFilmId := PtrUInt(ObjectFilm);
          CurrentFilm.SetObjectPosition(StepIndex, ObjectFilm, GateEntry^.Effect.Position);
          CurrentFilm.SetObjectAngle(StepIndex, ObjectFilm, GateEntry^.Effect.GetAngle);
          CurrentFilm.SetGateSize(StepIndex, ObjectFilm, GateEntry^.Effect.Size.X);
          CurrentFilm.AttachObject(StepIndex, ObjectFilm);
        end;
      end;
    end;
    Stage := 18;
    if RecordFilm then
    begin
      for Index := 0 to Galaxy.Holes.Count - 1 do
      begin
        Hole := Galaxy.Holes[Index];
        if Hole.Star1 = Self then
        begin
          EffectFilm := CurrentFilm.AddObject(Hole.Id, Hole.Graphic);
          Hole.FilmObjectId := PtrUInt(EffectFilm);
          CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Hole.Position1);
          if Galaxy.CurrentTurn = Hole.CreatedTurn then
            CurrentFilm.SetHoleState(StepIndex, EffectFilm, 1)
          else
            CurrentFilm.SetHoleState(StepIndex, EffectFilm, 0);
          CurrentFilm.AttachObject(StepIndex, EffectFilm);
        end
        else if Hole.Star2 = Self then
        begin
          EffectFilm := CurrentFilm.AddObject(Hole.Id, Hole.Graphic);
          Hole.FilmObjectId := PtrUInt(EffectFilm);
          CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Hole.Position2);
          if Galaxy.CurrentTurn = Hole.CreatedTurn then
            CurrentFilm.SetHoleState(StepIndex, EffectFilm, 1)
          else
            CurrentFilm.SetHoleState(StepIndex, EffectFilm, 0);
          CurrentFilm.AttachObject(StepIndex, EffectFilm);
        end;
      end;
    end;
    Stage := 19;
    for Index := 0 to (Self.Planets.Count - 1) do
    begin
      Planet := Self.Planets[Index];
      Planet.InitializeFilmState(StepIndex, RecordFilm);
    end;
    Stage := 20;
    for Index := 0 to (Self.Asteroids.Count - 1) do
    begin
      Asteroid := Self.Asteroids[Index];
      Asteroid.PrepareTurnMovement(StepIndex, RecordFilm);
    end;
    Stage := 21;
    for Index := 0 to (Self.Ships.Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if (Galaxy.StasisModEnabled <> 1) or (GetPlayer = Ship) then
      begin
        if Ship.GetHull.InterceptorsEnabled then
          Ship.LaunchInterceptors;
        Ship.GetHull.InterceptorTarget := nil;
        if Ship.AfterburnerActive then
        begin
          if Ship.IsEquipmentUsable(Ship.GetEngine) and (Ship.GetSlotCount(sskAfterburner) > 0) then
            Ship.ApplyAfterburnerItemDegradation;
        end;
      end;
    end;
    Stage := 22;
    for Index := 0 to (Self.Ships.Count - 1) do
      TShip(Self.Ships[Index]).PrepareTurnMovement(StepIndex, RecordFilm);
    // Arrivals and takeoffs are positioned during preparation, before step 1.
    // CHANGE: ENHANCEMENT - Capture simulation steps for observer playback.
    if Assigned(ObserverStep) then
      ObserverStep(Self, 0, Self.MovementStepCount);
    Stage := 23;
    for Index := 0 to (Self.Missiles.Count - 1) do
    begin
      Missile := TMissile(Self.Missiles.List^[Index]);
      Missile.PrepareTurnMovement(StepIndex, RecordFilm, False);
    end;
    Stage := 24;
    if RecordFilm then
    begin
      Count := Self.Items.Count;
      for Index := 0 to (Count - 1) do
      begin
        Item := Self.Items[Index];
        Item.FilmObject := CurrentFilm.AddObject(Item.Id, Item.GetGraphObject);
        CurrentFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
        CurrentFilm.AttachObject(StepIndex, Item.FilmObject);
      end;
    end;
    Stage := 25;
    Count := Self.MovementStepCount;
    CurrentFilm.AdvanceObjects(StepIndex);
    Inc(StepIndex);
    Self.CurrentStepIndex := StepIndex;
    Stage := 26;
    if RecordFilm then
    begin
      if not Self.PlayerCombatOccurred
          or (GetPlayer.MovementPath.ActiveTail <> nil)
              and not (GetPlayer.Speed * GetPlayer.Speed + 100
                  >= PointDistanceSquared(
                      GetPlayer.Position,
                      GetPlayer.MovementPath.ActiveTail^.Position))
          or (GetPlayer.Order = soLand) and (GetPlayer.FilmAlphaStep <> 0.0) then
        Self.PlayerFilmPath := nil
      else
      begin
        Self.PlayerFilmPath := TSPath.Create;
        TSPath(Self.PlayerFilmPath).AppendWaypoint(GetPlayer.Position, StepIndex);
      end;
    end;
    Stage := 27;
    EntryIndex := 0;
    while Self.Items.Count > EntryIndex do
    begin
      Item := Self.Items[EntryIndex];
      if Self.DamageRadius * Self.DamageRadius > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then
      begin
        Self.ClearItemReferences(Item);
        if RecordFilm then
        begin
          CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
          CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, nil, Item.FilmObject);
          CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, True, True);
          CurrentFilm.AttachObject(StepIndex, EffectFilm);
          ReleaseSpaceObject(Item.GraphObject);
          Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
        end;
        Self.Items.Delete(EntryIndex);
        Item.Free;
      end
      else
        Inc(EntryIndex);
    end;
    Stage := 28;
    NearestShip := nil;
    NearestItem := nil;
    WorkValue := 1.0e20;
    for Index := 0 to (Self.Ships.Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if Ship.PickupTargets <> nil then
      begin
        if Ship.GetCargoHook = nil then
          Ship.ClearPickupTargets
        else
        begin
          Item := Ship.PickupTargets[0];
          WorkScale := PointDistanceSquared(Ship.Position, Item.Position);
          if WorkScale < WorkValue then
          begin
            WorkValue := WorkScale;
            NearestShip := Ship;
            NearestItem := Item;
          end;
        end;
      end;
    end;
    Stage := 29;
    Self.PlayerCombatOccurred := False;
    for PathStep := 0 to (Count - 1) do
    begin
      EntryIndex := 0;
      Stage := 2900;
      if Galaxy.StasisModEnabled <> 1 then
      begin
        while Self.Missiles.Count > EntryIndex do
        begin
          Missile := TMissile(Self.Missiles.List^[EntryIndex]);
          if Missile.DestroyQueued then
          begin
            Inc(EntryIndex);
            Continue;
          end;
          Stage := 2901;
          Target := Missile.StepDay(StepIndex, RecordFilm);
          if Target = nil then
          begin
            Inc(EntryIndex);
            Continue;
          end;
          HitShip := nil;
          Stage := 2902;
          if (GetPlayer = Missile.OwnerShip)
              and ((TObject(Target) is TGoods)
                  and (Ord((TObject(Target) as TGoods).NaturalFlag) <> 0)) then
          begin
            Item := TObject(Target) as TItem;
            if GetPlayer.ScriptItemsAct(satOnMissileHittingObject, Item, Missile, 1) = 0 then
            begin
              Inc(EntryIndex);
              Continue;
            end;
            if RecordFilm then
            begin
              Effect :=
                  TWeaponSE.Create(
                      Missile.GetWeaponInfo^.AreaSE,
                      Classes.Point(0, 0),
                      Missile.GetShotVisual,
                      -1
                  );
              EffectFilm := CurrentFilm.AddObject(0, Effect);
              CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Item.Position);
              CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
              CurrentFilm.AttachObject(StepIndex, EffectFilm);
              CurrentFilm.DetachObject(StepIndex, Missile.FilmObject);
              Self.PendingFilmObjectRemovals.Add(Missile.FilmObject);
              ReleaseSpaceObject(Missile.Graphic);
              CurrentFilm.DetachObject(StepIndex, Item.FilmObject);
            end;
            Self.ClearItemReferences(Item);
            Quantity := (Item as TGoods).Quantity;
            if Quantity >= 5 then
              Self.DropMinerals(
                  Integer(Trunc(Quantity * 0.8 / Missile.GetWeaponInfo^.MiningFactor)),
                  Item.Position,
                  Self.GenerationSeed * Cardinal(Item.Id)
              );
            Point := Item.Position;
            if RecordFilm then
            begin
              Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
              ReleaseSpaceObject(Item.GraphObject);
              Self.Items.Delete(Self.Items.IndexOf(Item));
              Item.Free;
            end
            else
            begin
              Self.Items.Delete(Self.Items.IndexOf(Item));
              Item.Free;
            end;
          end
          else if TObject(Target) is TItem then
          begin
            Stage := 2903;
            Item := TObject(Target) as TItem;
            if (Missile.OwnerShip <> nil)
                and (Missile.OwnerShip.ScriptItemsAct(satOnMissileHittingObject, Item, Missile, 1)
                    = 0) then
            begin
              Inc(EntryIndex);
              Continue;
            end
            else
            begin
              ActionResult := 0;
              if Item.DestroyFlag = 0 then
                Item.DestroyFlag := 1;
              if Item.ScriptItem <> nil then
                ActionResult :=
                    TScriptItem(Item.ScriptItem)
                        .RunActionCode(
                            satOnItemHit,
                            Missile.OwnerShip,
                            Missile,
                            Self,
                            ActionResult);
              if Item is TEquipmentWithActCode then
                ActionResult :=
                    RunItemConfigActionCode(
                        Item,
                        satOnItemHit,
                        Missile.OwnerShip,
                        Missile,
                        Self,
                        ActionResult
                    );
              if (Item.DestroyFlag < 0) and (Missile.Target <> Item) then
              begin
                Inc(EntryIndex);
                Inc(Item.DestroyFlag);
                Continue;
              end
              else
              begin
                if RecordFilm then
                begin
                  Effect :=
                      TWeaponSE.Create(
                          Missile.GetWeaponInfo^.AreaSE,
                          Classes.Point(0, 0),
                          Missile.GetShotVisual,
                          -1
                      );
                  EffectFilm := CurrentFilm.AddObject(0, Effect);
                  CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Item.Position);
                  CurrentFilm.SetWeaponHit(
                      StepIndex,
                      EffectFilm,
                      0,
                      0,
                      (Item.ItemType = t_ArtefactBomb) and (Item.DestroyFlag >= 0),
                      True
                  );
                  if ((Item.ItemType = t_ArtefactBomb)
                          or (Item is TCistern) and ((Item as TCistern).Fuel > 0))
                      and (Item.DestroyFlag > 0) then
                    CurrentFilm.SetDestructionEffect(StepIndex, EffectFilm, 1);
                  CurrentFilm.AttachObject(StepIndex, EffectFilm);
                  CurrentFilm.DetachObject(StepIndex, Missile.FilmObject);
                  Self.PendingFilmObjectRemovals.Add(Missile.FilmObject);
                  ReleaseSpaceObject(Missile.Graphic);
                end;
                Stage := 2904;
                if Item.DestroyFlag >= 0 then
                begin
                  if RecordFilm then
                    CurrentFilm.DetachObject(StepIndex, Item.FilmObject);
                  for i := 0 to (Self.MovingDropItems.Count - 1) do
                  begin
                    MovingDrop := Self.MovingDropItems[i];
                    if MovingDrop^.Payload = Item then
                      MovingDrop^.Payload := nil;
                  end;
                  Self.ClearItemReferences(Item);
                end;
                Stage := 2905;
                if (Item.ItemType = t_ArtefactBomb)
                    or (Item is TCistern) and ((Item as TCistern).Fuel > 0)
                    or (ActionResult <> 0) then
                begin
                  CandidateCount := Self.Ships.Count;
                  for CandidateIndex := 0 to (CandidateCount - 1) do
                  begin
                    Ship := Self.Ships[CandidateIndex];
                    if Ship.InNormalSpace
                        and (not Ship.IsHullDestroyed
                            and ((GetPlayer <> Ship)
                                or (Galaxy.GodModEnabled <> 1)
                                    and (Galaxy.SpecialSimulationMode = 0))) then
                    begin
                      Distance := PointDistanceSquared(Ship.Position, Item.Position);
                      if aConst.ItemExplosionRadiusSquared >= Distance then
                      begin
                        Damage :=
                            Cardinal(
                                Ship.ApplyExplosionDamage(
                                    Missile.OwnerShip,
                                    Item,
                                    ActionResult,
                                    Missile
                                )
                            );
                        if Ship.IsHullDestroyed
                            and ((GetPlayer <> nil)
                                and ((Item.ItemType = t_ArtefactBomb)
                                    and (GetPlayer = Missile.OwnerShip))) then
                          Inc(GetPlayer.BombKillsThisTurn);
                        DamageColor := GR_Main.CurrentPixelFormat.PackRgbBytes(255, 0, 0);
                        if RecordFilm then
                        begin
                          CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                          CurrentFilm.SetWeaponEndpoints(
                              StepIndex,
                              EffectFilm,
                              Ship.FilmObject,
                              Ship.FilmObject
                          );
                          CurrentFilm.SetWeaponHit(
                              StepIndex,
                              EffectFilm,
                              Word(DamageColor),
                              Integer(Damage),
                              Ship.IsHullDestroyed,
                              True
                          );
                          CurrentFilm.AttachObject(StepIndex, EffectFilm);
                        end;
                      end;
                    end;
                  end;
                  CandidateCount := Self.Items.Count;
                  for CandidateIndex := 0 to (CandidateCount - 1) do
                  begin
                    OtherItem := Self.Items[CandidateIndex];
                    if OtherItem <> Item then
                    begin
                      Distance := PointDistanceSquared(OtherItem.Position, Item.Position);
                      if aConst.ItemExplosionRadiusSquared >= Distance then
                      begin
                        if 20.0 - 20.0 * Distance / aConst.ItemExplosionRadiusSquared
                            >= NextRandomIntRange(1, 100, Self.RandomState) then
                        begin
                          if OtherItem.DestroyFlag < 0 then
                            Inc(OtherItem.DestroyFlag)
                          else
                            Self.ReferencedItems.Add(OtherItem);
                        end;
                      end;
                    end;
                  end;
                end
                else
                begin
                  if (Item is TUselessItem)
                      and (WideString(TEquipment(Item).ConfigBlockName)
                          = WideString('ExampleAsteroid')) then
                    Self.DropMinerals(
                        SeededRandomIntRange(20, 30, Self.GenerationSeed * Cardinal(Item.Id)),
                        Item.Position,
                        Self.GenerationSeed * Cardinal(Item.Id)
                    );
                end;
                Point := Item.Position;
                Stage := 2906;
                if Item.DestroyFlag >= 0 then
                begin
                  if RecordFilm then
                  begin
                    Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
                    ReleaseSpaceObject(Item.GraphObject);
                  end;
                  begin
                    Self.Items.Delete(Self.Items.IndexOf(Item));
                    Item.Free;
                  end;
                end
                else
                  Inc(Item.DestroyFlag);
              end;
            end;
          end
          else if TObject(Target) is TAsteroid then
          begin
            Stage := 2907;
            Asteroid := TObject(Target) as TAsteroid;
            if (Missile.OwnerShip <> nil)
                and (Missile
                        .OwnerShip
                        .ScriptItemsAct(satOnMissileHittingObject, Asteroid, Missile, 1)
                    = 0) then
            begin
              Inc(EntryIndex);
              Continue;
            end
            else
            begin
              if RecordFilm then
              begin
                Effect :=
                    TWeaponSE.Create(
                        Missile.GetWeaponInfo^.AreaSE,
                        Classes.Point(0, 0),
                        Missile.GetShotVisual,
                        -1
                    );
                EffectFilm := CurrentFilm.AddObject(0, Effect);
                CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Asteroid.Position);
                CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
                CurrentFilm.AttachObject(StepIndex, EffectFilm);
                CurrentFilm.DetachObject(StepIndex, Missile.FilmObject);
                Self.PendingFilmObjectRemovals.Add(Missile.FilmObject);
                ReleaseSpaceObject(Missile.Graphic);
              end;
              Self.ClearTargetReferences(Asteroid);
              Stage := 2908;
              MineralValue :=
                  Self.DropMinerals(
                      Integer(Trunc(Asteroid.MineralCount / Missile.GetWeaponInfo^.MiningFactor)),
                      Asteroid.Position,
                      Self.GenerationSeed * Asteroid.Id
                  );
              if GetPlayer = Missile.OwnerShip then
                Self.ProcessPlayerAsteroidKill(MineralValue, Asteroid.Position, Asteroid.Id);
              Asteroid.Respawn;
              Point := Asteroid.Position;
            end;
          end
          else
          begin
            if TObject(Target) is TShip then
            begin
              if not (TObject(Target) as TShip).IsHullDestroyed then
              begin
                Stage := 29090;
                HitShip := TObject(Target) as TShip;
                if GetPlayer = HitShip then
                  Self.PlayerCombatOccurred := True;
                Stage := 29091;
                DrainedDamage := 0;
                Damage :=
                    Cardinal(
                        HitShip.ApplyMissileHit(Missile, DamageColor, PCardinal(@HitFlags[0])^)
                    );
                Stage := 29092;
                if (HitFlags[0] and 32 <> 0) and (Integer(Damage) > 0) then
                  DrainedDamage := DrainedDamage + Integer(Damage);
                if RecordFilm then
                begin
                  Effect :=
                      TWeaponSE.Create(
                          Missile.GetWeaponInfo^.AreaSE,
                          Classes.Point(0, 0),
                          Missile.GetShotVisual,
                          -1
                      );
                  EffectFilm := CurrentFilm.AddObject(0, Effect);
                  CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, HitShip.Position);
                  CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, nil, HitShip.FilmObject);
                  CurrentFilm.SetWeaponHit(
                      StepIndex,
                      EffectFilm,
                      Word(DamageColor),
                      Integer(Damage),
                      HitShip.IsHullDestroyed,
                      True
                  );
                  CurrentFilm.AttachObject(StepIndex, EffectFilm);
                  CurrentFilm.DetachObject(StepIndex, Missile.FilmObject);
                  Self.PendingFilmObjectRemovals.Add(Missile.FilmObject);
                  ReleaseSpaceObject(Missile.Graphic);
                end;
                Stage := 29093;
                Point := HitShip.Position;
                if Byte(Missile.GetWeaponInfo^.ShotType) in [Ord(wstTorpedo)..Ord(wstMissile)] then
                begin
                  Stage := 29094;
                  CandidateCount := Self.Ships.Count;
                  for CandidateIndex := 0 to (CandidateCount - 1) do
                  begin
                    Ship := Self.Ships[CandidateIndex];
                    if Ship.InNormalSpace and not Ship.IsHullDestroyed and (Ship <> Target) then
                    begin
                      if PointDistanceSquared(Point, Ship.Position)
                          < Math.Power(Missile.GetWeaponInfo^.SecondaryDamageRadius, 2) then
                      begin
                        Stage := 29095;
                        Damage :=
                            Cardinal(
                                Ship.ApplyMissileHit(Missile, DamageColor, PCardinal(@HitFlags[0])^)
                            );
                        if (HitFlags[0] and 32 <> 0) and (Integer(Damage) > 0) then
                          DrainedDamage := DrainedDamage + Integer(Damage);
                        Stage := 29096;
                        Ship.RefreshDerivedStats(True);
                        if RecordFilm then
                        begin
                          CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                          CurrentFilm.SetWeaponEndpoints(
                              StepIndex,
                              EffectFilm,
                              Ship.FilmObject,
                              Ship.FilmObject
                          );
                          CurrentFilm.SetWeaponHit(
                              StepIndex,
                              EffectFilm,
                              Word(DamageColor),
                              Integer(Damage),
                              Ship.IsHullDestroyed,
                              True
                          );
                          CurrentFilm.AttachObject(StepIndex, EffectFilm);
                        end;
                      end;
                    end;
                  end;
                end;
                Stage := 29097;
                if (DrainedDamage > 0)
                    and ((Missile.OwnerShip <> nil)
                        and (Missile.OwnerShip.InNormalSpace
                            and (Missile.OwnerShip.CurrentStar = Self))) then
                begin
                  CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                  CurrentFilm.SetWeaponEndpoints(
                      StepIndex,
                      EffectFilm,
                      Missile.OwnerShip.FilmObject,
                      Missile.OwnerShip.FilmObject
                  );
                  if GetPlayer <> Missile.OwnerShip then
                    CurrentFilm.SetWeaponHit(
                        StepIndex,
                        EffectFilm,
                        Word(OwnerToFilmColor(ShortInt(Missile.OwnerShip.OwnerId))),
                        -DrainedDamage,
                        False,
                        True
                    )
                  else
                    CurrentFilm.SetWeaponHit(
                        StepIndex,
                        EffectFilm,
                        Word(OwnerToFilmColor(ShortInt(RaceToOwner(Missile.OwnerShip.PilotRace)))),
                        -DrainedDamage,
                        False,
                        True
                    );
                  CurrentFilm.AttachObject(StepIndex, EffectFilm);
                end;
              end;
            end;
          end;
          Stage := 29098;
          Missile.Free;
        end;
      end;
      EntryIndex := 0;
      Stage := 2910;
      while Self.Missiles.Count > EntryIndex do
      begin
        Missile := TMissile(Self.Missiles.List^[EntryIndex]);
        if Missile.DestroyQueued then
        begin
          if RecordFilm then
          begin
            ReleaseSpaceObject(Missile.Graphic);
            Self.PendingFilmObjectRemovals.Add(Missile.FilmObject);
          end;
          Missile.Free;
        end
        else
          Inc(EntryIndex);
      end;
      if (Galaxy.StasisModEnabled <> 1) and (PathStep and 3 = 0) then
      begin
        EntryCount := Self.Asteroids.Count;
        for EntryIndex := 0 to (EntryCount - 1) do
        begin
          Asteroid := Self.Asteroids[EntryIndex];
          if Asteroid.Position.X * Asteroid.Position.X + Asteroid.Position.Y * Asteroid.Position.Y
              < Sqr(Self.Radius * 0.7) then
          begin
            if RecordFilm then
            begin
              CreateFilmEffect('Weapon.Asteroid', 0, Effect, EffectFilm);
              CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Asteroid.Position);
              CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
              CurrentFilm.AttachObject(StepIndex, EffectFilm);
            end;
            Self.ClearTargetReferences(Asteroid);
            Asteroid.Respawn;
          end
          else
          begin
            Planet := nil;
            Quantity := Self.Planets.Count;
            // Keep the native one-past-end sentinel after an unsuccessful search.
            i := 0;
            while i < Quantity do
            begin
              Planet := Self.Planets[i];
              Point := Planet.GetPosition;
              WorkX := Point.X;
              WorkY := Point.Y;
              ImpactX := Asteroid.Position.X;
              ImpactY := Asteroid.Position.Y;
              if Planet.GraphicRadius * Planet.GraphicRadius
                  >= (WorkX - ImpactX) * (WorkX - ImpactX)
                      + (WorkY - ImpactY) * (WorkY - ImpactY) then
                Break;
              Inc(i);
            end;
            if Self.Planets.Count > i then
            begin
              Planet.HandleAsteroidImpact(Asteroid);
              if RecordFilm then
              begin
                CreateFilmEffect('Weapon.Asteroid', 0, Effect, EffectFilm);
                CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Asteroid.Position);
                CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
                CurrentFilm.AttachObject(StepIndex, EffectFilm);
              end;
              if Self.Items.Count < 8 then
              begin
                Quantity := Integer(Trunc(Asteroid.MineralCount / 5.0));
                Item := TGoods.Create;
                (Item as TGoods).Init(t_Minerals, Quantity);
                (Item as TGoods).NaturalFlag := True;
                Item.Position := Asteroid.Position;
                MovingDrop := AllocEC(SizeOf(MovingDrop^));
                MovingDrop^.Payload := Item;
                MovingDrop^.SourceShipId := 0;
                MovingDrop^.InsertedIntoStar := False;
                MovingDrop^.UseFlag := 0;
                Distance :=
                    SeededRandomIntRange(
                        50,
                        150,
                        Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Cardinal(Item.Id)
                    );
                if (PlayerStar = Self) and (Count - 20 < PathStep) then
                  Distance := 5.0;
                Angle :=
                    SeededRandomUnitFloat(
                                Self.GenerationSeed
                                    * Cardinal(Galaxy.CurrentTurn)
                                    * Cardinal(Item.Id))
                            * 1.2
                        - 0.6
                        + Math.ArcTan2(
                            Asteroid.Position.X - Planet.GetPosition().X,
                            -(Asteroid.Position.Y - Planet.GetPosition().Y));
                MovingDrop^.Destination.X := System.Sin(Angle) * Distance + Item.Position.X;
                MovingDrop^.Destination.Y := Item.Position.Y - System.Cos(Angle) * Distance;
                Self.MovingDropItems.Add(MovingDrop);
              end;
              Self.ClearTargetReferences(Asteroid);
              Asteroid.Respawn;
            end
            else
            begin
              Ship := nil;
              Quantity := Self.Ships.Count;
              i := 0;
              while i < Quantity do
              begin
                Ship := Self.Ships[i];
                if Ship.InNormalSpace
                    and (not Ship.IsHullDestroyed
                        and ((PointDistanceSquared(Asteroid.Position, Ship.Position) <= 2500.0)
                            and ((GetPlayer = Ship)
                                or ((Ship.ScriptShip = nil) or Ship.HasScriptStateText)))) then
                  Break;
                Inc(i);
              end;
              if Self.Ships.Count <= i then
                Continue;
              Damage := Cardinal(Ship.ApplyAsteroidImpactDamage(Asteroid, DamageColor));
              if RecordFilm then
              begin
                CreateFilmEffect('Weapon.Asteroid', 0, Effect, EffectFilm);
                CurrentFilm.SetObjectPosition(StepIndex, EffectFilm, Asteroid.Position);
                CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, nil, Ship.FilmObject);
                CurrentFilm.SetWeaponHit(
                    StepIndex,
                    EffectFilm,
                    Word(DamageColor),
                    Integer(Damage),
                    Ship.IsHullDestroyed,
                    True
                );
                CurrentFilm.AttachObject(StepIndex, EffectFilm);
              end;
              Quantity := Integer(Trunc(Asteroid.MineralCount / 4.0));
              Angle :=
                  HeadingDegreesToRadians(
                      SeededRandomIntRange(
                          0,
                          360,
                          Asteroid.Id * Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn)
                      )
                  );
              CandidateCount := 0;
              while Quantity > 0 do
              begin
                if (Quantity < 10) or (CandidateCount >= 3) then
                  WorkCount := Quantity
                else
                  WorkCount :=
                      Integer(
                          System.Round(
                              (SeededRandomUnitFloat(
                                              Self.GenerationSeed
                                                  * Cardinal(Galaxy.CurrentTurn)
                                                  * Asteroid.Id)
                                          * 0.2
                                      + 0.55)
                                  * Quantity
                          )
                      );
                Quantity := Quantity - WorkCount;
                Item := TGoods.Create;
                (Item as TGoods).Init(t_Minerals, WorkCount);
                (Item as TGoods).NaturalFlag := True;
                Item.Position := Asteroid.Position;
                MovingDrop := AllocEC(SizeOf(MovingDrop^));
                MovingDrop^.Payload := Item;
                MovingDrop^.SourceShipId := 0;
                MovingDrop^.InsertedIntoStar := False;
                MovingDrop^.UseFlag := 0;
                Self.MovingDropItems.Add(MovingDrop);
                Inc(CandidateCount);
              end;
              WorkValue := 3.1415925;
              if CandidateCount > 1 then
                WorkValue := 6.2831852 / CandidateCount;
              for CandidateIndex := 0 to (CandidateCount - 1) do
              begin
                MovingDrop := Self.MovingDropItems[Self.MovingDropItems.Count - 1 - CandidateIndex];
                Distance :=
                    SeededRandomIntRange(
                        50,
                        150,
                        Cardinal((TObject(MovingDrop^.Payload) as TItem).Id)
                            * (Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn))
                    );
                if (PlayerStar = Self) and (Count - 20 < PathStep) then
                  Distance := 5.0;
                WorkScale :=
                    SeededRandomUnitFloat(
                                Cardinal((TObject(MovingDrop^.Payload) as TItem).Id)
                                    * (Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn)))
                            * 0.3
                        - 0.15;
                MovingDrop^.Destination.X :=
                    (TObject(MovingDrop^.Payload) as TItem).Position.X
                        + System.Sin(
                                SeededRandomUnitFloat(
                                        Cardinal((TObject(MovingDrop^.Payload) as TItem).Id)
                                            * (Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn)))
                                    * (Angle + WorkScale)
                                    * 113.0)
                            * Distance;
                MovingDrop^.Destination.Y :=
                    (TObject(MovingDrop^.Payload) as TItem).Position.Y
                        - System.Cos(
                                SeededRandomUnitFloat(
                                        Cardinal((TObject(MovingDrop^.Payload) as TItem).Id)
                                            * (Self.GenerationSeed * Cardinal(Galaxy.CurrentTurn)))
                                    * (Angle + WorkScale)
                                    * 517.0)
                            * Distance;
                Angle := Angle + WorkValue;
              end;
              Self.ClearTargetReferences(Asteroid);
              Asteroid.Respawn;
            end;
          end;
        end;
      end;
      Stage := 29300;
      EntryCount := Self.CombatEvents.Count;
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        Stage := 2930;
        CombatEvent := Self.CombatEvents[EntryIndex];
        if (CombatEvent^.StepIndex = PathStep)
            and ((CombatEvent^.Attacker <> nil)
                and ((CombatEvent^.Target <> nil)
                    and (not TShip(CombatEvent^.Attacker).IsHullDestroyed
                        and (not TShip(CombatEvent^.Attacker).DestroyQueued
                            and ((CombatEvent^.Weapon <> nil)
                                and (TWeapon(CombatEvent^.Weapon).EquippedFlag <> 0)))))) then
        begin
          if not (TShip(CombatEvent^.Attacker).GetCombatStatusStrength(cseWeaponBlock) <= 0.01) then
          begin
            if NextRandomUnitFloat(TShip(CombatEvent^.Attacker).RandomState)
                < TShip(CombatEvent^.Attacker).GetCombatStatusStrength(cseWeaponBlock) then
            begin
              TShip(CombatEvent^.Attacker).ReduceCombatStatusStrength(cseWeaponBlock, 1.0);
              Continue;
            end;
            TShip(CombatEvent^.Attacker).ReduceCombatStatusStrength(cseWeaponBlock, 1.0);
          end;
          if Byte(TWeapon(CombatEvent^.Weapon).GetWeaponInfo^.ShotType)
              in [Ord(wstTorpedo)..Ord(wstRocket)] then
          begin
            Stage := 2931;
            if TWeapon(CombatEvent^.Weapon).Ammo > 0 then
            begin
              if TObject(CombatEvent^.Target) is TShip then
                Point := (TObject(CombatEvent^.Target) as TShip).Position
              else
              begin
                if TObject(CombatEvent^.Target) is TAsteroid then
                  Point := (TObject(CombatEvent^.Target) as TAsteroid).Position
                else
                begin
                  if TObject(CombatEvent^.Target) is TItem then
                    Point := (TObject(CombatEvent^.Target) as TItem).Position
                  else
                  begin
                    if TObject(CombatEvent^.Target) is TMissile then
                      Point := (TObject(CombatEvent^.Target) as TMissile).Position
                    else
                      Point := MakePointF(1000000.0, 1000000.0);
                  end;
                end;
              end;
              if Sqr(
                      TShip(CombatEvent^.Attacker)
                              .GetWeaponActionRange(TWeapon(CombatEvent^.Weapon))
                          + 200)
                  > PointDistanceSquared(TShip(CombatEvent^.Attacker).Position, Point) then
              begin
                Quantity := 1;
                AttackCount := TWeapon(CombatEvent^.Weapon).GetAttackCount;
                if Byte(TWeapon(CombatEvent^.Weapon).GetWeaponInfo^.ShotType)
                    in [Ord(wstMissile)..Ord(wstRocket)] then
                  Quantity := TWeapon(CombatEvent^.Weapon).GetShotCount;
                BertorBoost :=
                    (CombatEvent^.Attacker is TKling)
                        and ((CombatEvent^.Attacker as TKling).DominatorSeries = dsBlazer)
                        and (CombatEvent^.Attacker as TKling).HasNearbyBertorAura;
                for ArtefactIndex := 1
                    to ((TWeapon(CombatEvent^.Weapon).GetAttackCount
                            * TShip(CombatEvent^.Attacker)
                                .CountActiveArtefacts(Ord(t_ArtFastRacks)))
                        * (Integer(
                                TShip(CombatEvent^.Attacker)
                                    .CanBoostArtefact(
                                        Ord(t_ArtFastRacks),
                                        TWeapon(CombatEvent^.Weapon),
                                        False))
                            + 1)) do
                begin
                  if (NextRandomUnitFloat(TShip(CombatEvent^.Attacker).RandomState)
                          <= aConst.ExtraMissileChance)
                      and (TObject(CombatEvent^.Target) is TShip) then
                    Inc(AttackCount);
                end;
                if TWeapon(CombatEvent^.Weapon).Ammo < AttackCount then
                  AttackCount := Max(1, TWeapon(CombatEvent^.Weapon).Ammo);
                Quantity := Quantity * AttackCount;
                if (TShip(CombatEvent^.Attacker).TypeId <> stKling)
                    and ((GetPlayer <> CombatEvent^.Attacker) or (Galaxy.AmmoModEnabled <> 1)) then
                begin
                  RemainingAmmo := TWeapon(CombatEvent^.Weapon).Ammo - AttackCount;
                  TWeapon(CombatEvent^.Weapon).Ammo := RemainingAmmo;
                end;
                for i := 0 to (Quantity - 1) do
                begin
                  if CombatEvent^.Weapon is TCustomWeapon then
                  begin
                    Missile := TCustomMissile.Create;
                    TCustomMissile(Missile)
                        .InitializeShot(
                            Self,
                            TShip(CombatEvent^.Attacker),
                            TWeapon(CombatEvent^.Weapon),
                            CombatEvent^.Target,
                            i + Ord(Quantity mod 2 = 0));
                  end
                  else
                  begin
                    Missile := TMissile.Create;
                    Missile.InitializeShot(
                        Self,
                        TShip(CombatEvent^.Attacker),
                        TWeapon(CombatEvent^.Weapon),
                        CombatEvent^.Target,
                        i + Ord(Quantity mod 2 = 0)
                    );
                  end;
                  if BertorBoost then
                  begin
                    if Self.RecordingTurnFilm
                        and (Ord((CombatEvent^.Attacker as TKling).AuraEffectShownThisTurn)
                            = 0) then
                    begin
                      CreateFilmEffect('Weapon.AuraEffect', 0, Effect, EffectFilm);
                      CurrentFilm.SetWeaponEndpoints(
                          Self.CurrentStepIndex,
                          EffectFilm,
                          TShip(CombatEvent^.Attacker).FilmObject,
                          TShip(CombatEvent^.Attacker).FilmObject
                      );
                      CurrentFilm
                          .SetWeaponHit(Self.CurrentStepIndex, EffectFilm, 0, 0, False, True);
                      CurrentFilm.AttachObject(Self.CurrentStepIndex, EffectFilm);
                      (CombatEvent^.Attacker as TKling).AuraEffectShownThisTurn := True;
                    end;
                    Missile.MinDamage := Cardinal(System.Round(Missile.MinDamage * 1.25));
                    Missile.MaxDamage := Cardinal(System.Round(Missile.MaxDamage * 1.25));
                  end;
                  TShip(CombatEvent^.Attacker)
                      .ScriptItemsAct(satOnMissileShot, Missile, TWeapon(CombatEvent^.Weapon), 0);
                  Missile.PrepareTurnMovement(StepIndex, RecordFilm, True);
                  if RecordFilm then
                    CurrentFilm.DetachObject(0, Missile.FilmObject);
                end;
              end;
            end;
          end
          else
          begin
            if TObject(CombatEvent^.Target) is TMissile then
            begin
              Stage := 2932;
              if PointDistanceSquared(
                      TShip(CombatEvent^.Attacker).Position,
                      (TObject(CombatEvent^.Target) as TMissile).Position)
                  < 1.3
                      * Sqr(
                          TShip(CombatEvent^.Attacker)
                              .GetWeaponRange(TWeapon(CombatEvent^.Weapon))) then
                TShip(CombatEvent^.Attacker)
                    .FireWeaponAtMissile(
                        TWeapon(CombatEvent^.Weapon),
                        CombatEvent^.Target,
                        RecordFilm);
            end
            else
            begin
              if TObject(CombatEvent^.Target) is TShip then
              begin
                Stage := 2933;
                if PointDistanceSquared(
                        TShip(CombatEvent^.Attacker).Position,
                        (TObject(CombatEvent^.Target) as TShip).Position)
                    < 1.3
                        * Sqr(
                            TShip(CombatEvent^.Attacker)
                                .GetWeaponRange(TWeapon(CombatEvent^.Weapon))) then
                  TShip(CombatEvent^.Attacker)
                      .FireWeaponAtShip(
                          TWeapon(CombatEvent^.Weapon),
                          TShip(CombatEvent^.Target),
                          RecordFilm);
              end
              else
              begin
                if TObject(CombatEvent^.Target) is TItem then
                begin
                  Stage := 2934;
                  if PointDistanceSquared(
                          TShip(CombatEvent^.Attacker).Position,
                          (TObject(CombatEvent^.Target) as TItem).Position)
                      < 1.3
                          * Sqr(
                              TShip(CombatEvent^.Attacker)
                                  .GetWeaponRange(TWeapon(CombatEvent^.Weapon))) then
                    TShip(CombatEvent^.Attacker)
                        .FireWeaponAtItem(
                            TWeapon(CombatEvent^.Weapon),
                            TItem(CombatEvent^.Target),
                            RecordFilm);
                end
                else
                begin
                  if TObject(CombatEvent^.Target) is TAsteroid then
                  begin
                    Stage := 2935;
                    if PointDistanceSquared(
                            TShip(CombatEvent^.Attacker).Position,
                            (TObject(CombatEvent^.Target) as TAsteroid).Position)
                        < 1.3
                            * Sqr(
                                TShip(CombatEvent^.Attacker)
                                    .GetWeaponRange(TWeapon(CombatEvent^.Weapon))) then
                      TShip(CombatEvent^.Attacker)
                          .FireWeaponAtAsteroid(
                              TWeapon(CombatEvent^.Weapon),
                              CombatEvent^.Target,
                              RecordFilm);
                  end;
                end;
              end;
            end;
          end;
          Continue;
        end;
      end;
      Stage := 2940;
      EntryCount := Self.MovingDropItems.Count;
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        MovingDrop := Self.MovingDropItems[EntryIndex];
        if MovingDrop^.Payload <> nil then
        begin
          if TObject(MovingDrop^.Payload) is TItem then
          begin
            Item := TObject(MovingDrop^.Payload) as TItem;
            if not MovingDrop^.InsertedIntoStar then
            begin
              if (Item is TArtefactTranclucator) and (MovingDrop^.UseFlag <> 0) then
              begin
                Tranclucator := TObject((Item as TArtefactTranclucator).Ship) as TTranclucator;
                (Item as TArtefactTranclucator).Ship := nil;
                Tranclucator.CurrentStar := Self;
                Self.Ships.Add(Tranclucator);
                Tranclucator.Position := Item.Position;
                Tranclucator.MovementDirection := 0.0;
                Item.Free;
                MovingDrop^.Payload := Tranclucator;
                MovingDrop^.InsertedIntoStar := True;
                if RecordFilm then
                begin
                  Tranclucator.FilmObject :=
                      CurrentFilm.AddObject(Tranclucator.Id, Tranclucator.Graphic);
                  CurrentFilm.DetachObject(0, Tranclucator.FilmObject);
                  CurrentFilm.SetObjectPosition(StepIndex, Tranclucator.FilmObject, Self.Position);
                  CurrentFilm.SetObjectAngle(StepIndex, Tranclucator.FilmObject, 0);
                  CurrentFilm.SetObjectAlpha(StepIndex, Tranclucator.FilmObject, 255);
                  CurrentFilm.AttachObject(StepIndex, Tranclucator.FilmObject);
                end;
              end
              else
              begin
                Self.Items.Add(Item);
                MovingDrop^.InsertedIntoStar := True;
                if RecordFilm then
                begin
                  Item.FilmObject := CurrentFilm.AddObject(Item.Id, Item.GetGraphObject);
                  CurrentFilm.DetachObject(0, Item.FilmObject);
                  CurrentFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
                  CurrentFilm.AttachObject(StepIndex, Item.FilmObject);
                end;
              end;
            end
            else
            begin
              Item.Position.X :=
                  (MovingDrop^.Destination.X - Item.Position.X) / (Count - PathStep)
                      + Item.Position.X;
              Item.Position.Y :=
                  (MovingDrop^.Destination.Y - Item.Position.Y) / (Count - PathStep)
                      + Item.Position.Y;
              if RecordFilm then
                CurrentFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
              if Self.DamageRadius * Self.DamageRadius
                  > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then
              begin
                if RecordFilm then
                begin
                  CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                  CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, nil, Item.FilmObject);
                  CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, True, True);
                  CurrentFilm.AttachObject(StepIndex, EffectFilm);
                  ReleaseSpaceObject(Item.GraphObject);
                  Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
                end;
                Self.Items.Delete(Self.Items.IndexOf(Item));
                Item.Free;
                MovingDrop^.Payload := nil;
              end;
            end;
          end
          else
          begin
            HitShip := TObject(MovingDrop^.Payload) as TShip;
            HitShip.Position.X :=
                (MovingDrop^.Destination.X - HitShip.Position.X) / (Count - PathStep)
                    + HitShip.Position.X;
            HitShip.Position.Y :=
                (MovingDrop^.Destination.Y - HitShip.Position.Y) / (Count - PathStep)
                    + HitShip.Position.Y;
            if RecordFilm then
              CurrentFilm.SetObjectPosition(StepIndex, HitShip.FilmObject, HitShip.Position);
          end;
        end;
      end;
      Stage := 2950;
      if Galaxy.StasisModEnabled <> 1 then
        for Index := 0 to (Self.Planets.Count - 1) do
        begin
          Planet := Self.Planets[Index];
          Planet.AdvanceOrbitStep(StepIndex, RecordFilm);
        end;
      Stage := 2951;
      if Galaxy.StasisModEnabled <> 1 then
        for Index := 0 to (Self.Asteroids.Count - 1) do
        begin
          Asteroid := Self.Asteroids[Index];
          Asteroid.AdvanceOrbitStep(StepIndex, RecordFilm);
        end;
      Stage := 2952;
      if StepIndex mod (Count div 11) = 0 then
      begin
        if StepIndex div (Count div 11) >= 1 then
        begin
          if StepIndex div (Count div 11) <= 10 then
            Self.ProcessItemScripts(StepIndex div (Count div 11));
        end;
      end;
      Stage := 2960;
      if (PathStep + 1) mod Integer(Cardinal(Count) shr 3) = 0 then
        for Index := 0 to (Self.Ships.Count - 1) do
        begin
          Ship := Self.Ships[Index];
          if Ship.InNormalSpace
              and ((GetPlayer <> Ship) or (Byte(GlobalsV.CurrentScreenId) = 16)) then
            for i := 0 to (Ship.Inventory.Count - 1) do
            begin
              Item := Ship.Inventory[i];
              if Item.DestroyFlag > 0 then
              begin
                while Ship.DockedTo <> nil do
                  Ship := Ship.DockedTo;
                Ship.DestroyQueued := True;
                Break;
              end;
            end;;
        end;
      Stage := 2961;
      Index := 0;
      while Self.Items.Count > Index do
      begin
        Item := Self.Items[Index];
        if Item.DestroyFlag > 0 then
        begin
          Self.Items.Delete(Index);
          Dec(Index);
          if RecordFilm then
          begin
            CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
            CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, Item.FilmObject, Item.FilmObject);
            CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, True, True);
            if Item.DestroyFlag = 1 then
              CurrentFilm.SetDestructionEffect(StepIndex, EffectFilm, 3)
            else
              CurrentFilm.SetDestructionEffect(StepIndex, EffectFilm, 1);
            CurrentFilm.AttachObject(StepIndex, EffectFilm);
          end;
          Self.ClearItemReferences(Item);
          if (Item.DestroyFlag > 1)
              or ((Item.ItemType = t_ArtefactBomb)
                  or (Item is TCistern) and ((Item as TCistern).Fuel > 0)) then
          begin
            CandidateCount := Self.Ships.Count;
            for CandidateIndex := 0 to (CandidateCount - 1) do
            begin
              Ship := Self.Ships[CandidateIndex];
              if Ship.InNormalSpace and not Ship.IsHullDestroyed then
              begin
                Distance := PointDistanceSquared(Ship.Position, Item.Position);
                if (Sqr(aConst.BombDamageRadius) >= Distance)
                    and ((GetPlayer <> Ship)
                        or (Galaxy.GodModEnabled <> 1) and (Galaxy.SpecialSimulationMode = 0)) then
                begin
                  Damage := Cardinal(Ship.ApplyExplosionDamage(nil, Item, 0, nil));
                  DamageColor := GR_Main.CurrentPixelFormat.PackRgbBytes(255, 0, 0);
                  if RecordFilm then
                  begin
                    CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                    CurrentFilm.SetWeaponEndpoints(
                        StepIndex,
                        EffectFilm,
                        Ship.FilmObject,
                        Ship.FilmObject
                    );
                    if Item.DestroyFlag > 0 then
                      CurrentFilm.SetWeaponHit(
                          StepIndex,
                          EffectFilm,
                          Word(DamageColor),
                          Integer(Damage),
                          Ship.IsHullDestroyed,
                          True
                      )
                    else
                      CurrentFilm
                          .SetWeaponHit(StepIndex, EffectFilm, 0, 0, Ship.IsHullDestroyed, True);
                    CurrentFilm.AttachObject(StepIndex, EffectFilm);
                  end;
                end;
              end;
            end;
            CandidateCount := Self.Items.Count;
            for CandidateIndex := 0 to (CandidateCount - 1) do
            begin
              OtherItem := Self.Items[CandidateIndex];
              Distance := PointDistanceSquared(OtherItem.Position, Item.Position);
              if aConst.ItemExplosionRadiusSquared >= Distance then
              begin
                if 20.0 - 20.0 * Distance / aConst.ItemExplosionRadiusSquared
                    >= NextRandomIntRange(1, 100, Self.RandomState) then
                begin
                  if OtherItem.DestroyFlag < 0 then
                    Inc(OtherItem.DestroyFlag)
                  else
                    Self.ReferencedItems.Add(OtherItem);
                end;
              end;
            end;
          end;
          if RecordFilm then
          begin
            Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
            ReleaseSpaceObject(Item.GraphObject);
          end;
          Item.Free;
        end;
        Inc(Index);
      end;
      Index := 0;
      Stage := 2970;
      while Self.Ships.Count > Index do
      begin
        Ship := Self.Ships[Index];
        if Ship.IsHullDestroyed then
        begin
          Inc(Index);
          Continue;
        end;
        Stage := 2971;
        if Ship.DestroyQueued
            and ((Cardinal(Cardinal(Count) shr 2) = Cardinal(PathStep))
                and ((GetPlayer <> Ship) or (Byte(GlobalsV.CurrentScreenId) = 16))) then
        begin
          Ship.ScriptItemsAct(satOnDeath, nil, nil, 0);
          Ship.GetHull.HullPoints := 0;
          if GetPlayer <> nil then
            GetPlayer.ProcessShipDestructionQuests(Ship);
          Ship.RefreshDerivedStats(True);
          if RecordFilm and (Ship.FilmObject <> nil) then
          begin
            if Ship.InNormalSpace then
            begin
              CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
              CurrentFilm
                  .SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
              CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, Ship.IsHullDestroyed, True);
              CurrentFilm.AttachObject(StepIndex, EffectFilm);
            end
            else
              CurrentFilm.DetachObject(StepIndex, Ship.FilmObject);
          end;
          Self.ClearShipReferences(Ship);
          Inc(Index);
          Continue;
        end;
        Stage := 2972;
        if (StepIndex mod (Count div 5) = 0) and (StepIndex div (Count div 5) >= 1) then
        begin
          if (StepIndex div (Count div 5) <= 3)
              and (not Ship.IsHullDestroyed
                  and (Ship.InNormalSpace
                      and ((GetPlayer <> Ship)
                          or (Galaxy.GodModEnabled <> 1) and (Galaxy.SpecialSimulationMode = 0)))
                  and ((GetPlayer = Ship) or (Galaxy.StasisModEnabled <> 1))) then
          begin
            Distance := Sqr(Ship.Position.X) + Sqr(Ship.Position.Y);
            if Self.DamageRadius * Self.DamageRadius > Distance then
            begin
              if GetPlayer = Ship then
                Self.PlayerCombatOccurred := True;
              Damage := Cardinal(Ship.ApplyStarHeatDamage);
              if RecordFilm and (Integer(Damage) > 0) then
              begin
                CreateFilmEffect('Weapon.Star', 0, Effect, EffectFilm);
                CurrentFilm
                    .SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
                CurrentFilm.SetWeaponHit(
                    StepIndex,
                    EffectFilm,
                    Word(GR_Main.CurrentPixelFormat.PackRgbBytes(255, 255, 255)),
                    Integer(Damage),
                    Ship.IsHullDestroyed,
                    True
                );
                CurrentFilm.AttachObject(StepIndex, EffectFilm);
              end;
              Ship.InterceptorPassesRemaining := 0;
              if Ship.IsHullDestroyed then
              begin
                Inc(Index);
                Continue;
              end;
            end;
          end;
        end;
        Stage := 29731;
        if (StepIndex mod (Count div 5) = 0) and (StepIndex div (Count div 5) >= 1) then
        begin
          if (StepIndex div (Count div 5) <= 3)
              and (not Ship.IsHullDestroyed
                  and (Ship.InNormalSpace
                      and ((GetPlayer <> Ship)
                          or (Galaxy.GodModEnabled <> 1) and (Galaxy.SpecialSimulationMode = 0)))
                  and (((GetPlayer = Ship) or (Galaxy.StasisModEnabled <> 1))
                      and (Ship.InterceptorPassesRemaining > 0))) then
          begin
            if (GetPlayer = Ship) or (GetPlayer = Ship.InterceptorSourceShip) then
            begin
              Self.PlayerCombatOccurred := True;
              if GetPlayer = Ship.InterceptorSourceShip then
                CurrentFilm.AddCameraEvent(StepIndex, GetPlayer.Position, Ship.Position, 1);
              if (GetPlayer = Ship) and (Ship.InterceptorSourceShip <> nil) then
                CurrentFilm.AddCameraEvent(
                    StepIndex,
                    GetPlayer.Position,
                    Ship.InterceptorSourceShip.Position,
                    1
                );
            end;
            Damage := Cardinal(Ship.ApplyInterceptorDamage(DamageColor));
            if RecordFilm then
            begin
              CreateFilmEffect('Weapon.Star', 0, Effect, EffectFilm);
              CurrentFilm
                  .SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
              CurrentFilm.SetWeaponHit(
                  StepIndex,
                  EffectFilm,
                  Word(DamageColor),
                  Integer(Damage),
                  Ship.IsHullDestroyed,
                  True
              );
              CurrentFilm.AttachObject(StepIndex, EffectFilm);
            end;
            if Ship.IsHullDestroyed then
            begin
              Inc(Index);
              Continue;
            end;
          end;
        end;
        Stage := 29732;
        if (Galaxy.StasisModEnabled <> 1)
            and ((4 * (Count div 5) = StepIndex)
                and (not Ship.IsHullDestroyed
                    and (Ship.InNormalSpace and (Ship.InterceptorSourceShip <> nil)))) then
        begin
          if Ship.InterceptorSourceShip.GetHull.Energy >= 3 then
          begin
            Ship.InterceptorSourceShip.GetHull.Energy :=
                Ship.InterceptorSourceShip.GetHull.Energy - 3;
            Dec(Ship.InterceptorPassesRemaining);
          end
          else
          begin
            Ship.InterceptorSourceShip.GetHull.Energy := 0;
            Ship.InterceptorPassesRemaining := 0;
          end;
          if Ship.InterceptorPassesRemaining <= 0 then
            Ship.InterceptorSourceShip := nil;
        end;
        Stage := 29733;
        if 4 * (Count div 5) = StepIndex then
        begin
          if (System.Round(Ship.GetCombatStatusStrength(cseShock)) >= 1)
              and (not Ship.IsHullDestroyed
                  and (Ship.InNormalSpace
                      and ((GetPlayer <> Ship)
                          or (Galaxy.GodModEnabled <> 1) and (Galaxy.SpecialSimulationMode = 0)))
                  and ((GetPlayer = Ship) or (Galaxy.StasisModEnabled <> 1))) then
          begin
            Damage := Cardinal(Ship.ApplyShockStatusDamage(DamageColor));
            if RecordFilm then
            begin
              CreateFilmEffect('Weapon.Shock', 0, Effect, EffectFilm);
              CurrentFilm
                  .SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
              CurrentFilm.SetWeaponHit(
                  StepIndex,
                  EffectFilm,
                  Word(DamageColor),
                  Integer(Damage),
                  Ship.IsHullDestroyed,
                  True
              );
              CurrentFilm.AttachObject(StepIndex, EffectFilm);
            end;
          end;
        end;
        if Ship is TKling then
        begin
          if (Ship as TKling).ShouldKamikaze
              and not Ship.IsHullDestroyed
              and Ship.InNormalSpace then
          begin
            if Ship.OrderTarget <> nil then
            begin
              if TObject(Ship.OrderTarget) is TShip then
              begin
                if not (TObject(Ship.OrderTarget) as TShip).IsHullDestroyed then
                begin
                  if (TObject(Ship.OrderTarget) as TShip).InNormalSpace then
                  begin
                    if PointDistance(Ship.Position, (TObject(Ship.OrderTarget) as TShip).Position)
                        <= 100.0 then
                    begin
                      Ship.GetHull.HullPoints := 0;
                      Self.ClearShipReferences(Ship);
                      Ship.ScriptItemsAct(satOnDeath, Ship, Ship, 0);
                      if GetPlayer <> nil then
                        GetPlayer.ProcessShipDestructionQuests(Ship);
                      for CandidateIndex := 0 to (Self.Ships.Count - 1) do
                      begin
                        OwnerShip := Self.Ships[CandidateIndex];
                        if not OwnerShip.IsHullDestroyed
                            and (OwnerShip.InNormalSpace
                                and ((PointDistanceSquared(Ship.Position, OwnerShip.Position)
                                        <= 22500.0)
                                    and ((GetPlayer <> OwnerShip)
                                        or (Galaxy.GodModEnabled <> 1)
                                            and (Galaxy.SpecialSimulationMode = 0)))) then
                        begin
                          if not (OwnerShip is TKling)
                              or ((OwnerShip as TKling).DominatorSeries
                                  <> (Ship as TKling).DominatorSeries) then
                          begin
                            Damage := Cardinal(OwnerShip.ApplyExplosionDamage(nil, Ship, 0, nil));
                            DamageColor := GR_Main.CurrentPixelFormat.PackRgbBytes(255, 0, 0);
                            if RecordFilm then
                            begin
                              CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
                              CurrentFilm.SetWeaponEndpoints(
                                  StepIndex,
                                  EffectFilm,
                                  OwnerShip.FilmObject,
                                  OwnerShip.FilmObject
                              );
                              CurrentFilm.SetWeaponHit(
                                  StepIndex,
                                  EffectFilm,
                                  Word(DamageColor),
                                  Integer(Damage),
                                  OwnerShip.IsHullDestroyed,
                                  True
                              );
                              CurrentFilm.AttachObject(StepIndex, EffectFilm);
                            end;
                          end;
                        end;
                      end;
                      if RecordFilm then
                      begin
                        CurrentFilm.SetObjectAlpha(StepIndex, Ship.FilmObject, 0);
                        CreateFilmEffect('Weapon.Kamikaze', 0, Effect, EffectFilm);
                        CurrentFilm.SetWeaponEndpoints(
                            StepIndex,
                            EffectFilm,
                            Ship.FilmObject,
                            Ship.FilmObject
                        );
                        CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, True, True);
                        CurrentFilm.SetDestructionEffect(StepIndex, EffectFilm, 5);
                        CurrentFilm.AttachObject(StepIndex, EffectFilm);
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
        Stage := 29734;
        if (StepIndex mod (Count div 9) = 0)
            and ((Ship is TKling)
                and (not Ship.IsHullDestroyed
                    and (Ship.InNormalSpace and (Galaxy.StasisModEnabled <> 1)))) then
        begin
          if RecordFilm
              and (((Ship as TKling).KlingType = ktBertor)
                  and (StepIndex div (Count div 9) in [1, 3])) then
          begin
            Effect :=
                TWeaponSE.Create(
                    'Weapon.RadialEffect',
                    Classes.Point(0, 0),
                    Integer((Ship as TKling).DominatorSeries),
                    -1
                );
            EffectFilm := CurrentFilm.AddObject(0, Effect);
            CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
            CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
            CurrentFilm.AttachObject(StepIndex, EffectFilm);
          end;
          if (StepIndex div (Count div 9) = 3)
              and ((Ship as TKling).DominatorSeries = dsTerron) then
          begin
            if (Ship as TKling).HasNearbyBertorAura then
            begin
              Damage := Cardinal(Max(1, System.Round(Ship.GetHull.Weight * 0.05)));
              Ship.GetHull.HullPoints :=
                  Min(Ship.GetHull.Weight, Integer(Damage) + Ship.GetHull.HullPoints);
              if RecordFilm then
              begin
                CreateFilmEffect('Weapon.AuraEffect', 2, Effect, EffectFilm);
                CurrentFilm
                    .SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
                CurrentFilm.SetWeaponHit(
                    StepIndex,
                    EffectFilm,
                    Word(OwnerToFilmColor(ShortInt(Ship.OwnerId))),
                    -Damage,
                    False,
                    True
                );
                CurrentFilm.AttachObject(StepIndex, EffectFilm);
              end;
            end;
          end;
          if (StepIndex div (Count div 9) = 3)
              and (((Ship as TKling).KlingType = ktBertor)
                  and (not Ship.IsHullDestroyed and Ship.InNormalSpace)) then
            for CandidateIndex := 0 to (Self.Ships.Count - 1) do
            begin
              OwnerShip := Self.Ships[CandidateIndex];
              if not OwnerShip.IsHullDestroyed
                  and OwnerShip.InNormalSpace
                  and (Ship <> OwnerShip)
                  and (not (OwnerShip is TKling)
                      or not (Byte((OwnerShip as TKling).KlingType) in [0, 6]))
                  and (PointDistance(Ship.Position, OwnerShip.Position) <= 500.0) then
                for EntryIndex := 0 to (OwnerShip.Inventory.Count - 1) do
                begin
                  Item := OwnerShip.Inventory[EntryIndex];
                  if Item.OwnerId = Byte(oiDominator) then
                  begin
                    if (Byte((Item as TEquipment).DominatorSeries)
                            <> Byte((Ship as TKling).DominatorSeries))
                        and ((Byte(Item.ItemType)
                                in [Ord(t_FuelTanks)..Ord(t_CustomWeapon), Ord(t_Satellite)])
                            and (Item is TEquipment)) then
                    begin
                      if (Item as TEquipment).EquippedFlag <> 0 then
                      begin
                        if (Item as TEquipment).BrokenFlag = 0 then
                        begin
                          if WideString((Item as TEquipment).CustomFaction) = '' then
                            OwnerShip.ApplyItemDegradation(
                                TEquipment(Item),
                                idkForce,
                                NextRandomIntRange(5, 10, Ship.RandomState)
                            );
                        end;
                      end;
                    end;
                  end;
                end;
            end;
        end;
        Stage := 29735;
        if StepIndex mod (Count div (aConst.PointDefensePassCount + 2)) = 0 then
        begin
          if StepIndex div (Count div (aConst.PointDefensePassCount + 2)) >= 1 then
          begin
            if (StepIndex div (Count div (aConst.PointDefensePassCount + 2))
                    <= aConst.PointDefensePassCount)
                and (not Ship.IsHullDestroyed
                    and (Ship.InNormalSpace
                        and ((Ship.CountActiveArtefacts(Ord(t_ArtPDTurret)) > 0)
                            and ((GetPlayer = Ship) or (Galaxy.StasisModEnabled <> 1))))) then
            begin
              for ArtefactIndex := 1 to Ship.CountActiveArtefacts(Ord(t_ArtPDTurret)) do
              begin
                CandidateIndex := 0;
                InterceptedMissile := nil;
                NearestMissileDistance := 0;
                BestMissilePriority := -1;
                MissilePriority := 0;
                PointDefenseRangeSquared :=
                    (aConst.PointDefenseBaseRange + aConst.PointDefenseBonusRange)
                        * (aConst.PointDefenseBaseRange
                            + aConst.PointDefenseBonusRange
                                * (Integer(Ship.CanBoostArtefact(Ord(t_ArtPDTurret), nil, False))
                                    and 127));
                while Self.Missiles.Count > CandidateIndex do
                begin
                  Missile := Self.Missiles[CandidateIndex];
                  Inc(CandidateIndex);
                  if (Missile.OwnerShip <> Ship)
                      and (not (Ship is TTranclucator)
                          or ((TTranclucator(Ship).OwnerShip = nil)
                              or ((Missile.OwnerShip = nil)
                                  or (TTranclucator(Ship).OwnerShip <> Missile.OwnerShip)
                                      and (not (TObject(Missile.OwnerShip) is TTranclucator)
                                          or (TTranclucator(Ship).OwnerShip
                                              <> TTranclucator(Missile.OwnerShip)
                                                  .OwnerShip))))) then
                  begin
                    MissileDistance :=
                        Integer(
                            System.Round(PointDistanceSquared(Ship.Position, Missile.Position))
                        );
                    if MissileDistance <= PointDefenseRangeSquared then
                    begin
                      if Missile.Target = Ship then
                        MissilePriority := 3
                      else if (Missile.Target <> nil)
                          and (TObject(Missile.Target) is TShip)
                          and (Cardinal(Missile.Target) <> Cardinal(Missile.OwnerShip))
                          and ((TObject(Missile.Target) as TShip).GetRelationLevelToShip(Ship)
                              > rlHostile)
                          and (Ship.GetRelationLevelToShip(TObject(Missile.Target) as TShip)
                              > rlHostile) then
                        MissilePriority := 2
                      else if (Missile.OwnerShip <> nil)
                          and ((Missile.OwnerShip.GetRelationLevelToShip(Ship) <= rlHostile)
                              or (Ship.GetRelationLevelToShip(Missile.OwnerShip) <= rlHostile)) then
                        MissilePriority := 1
                      else
                        Continue;
                      if (MissilePriority >= BestMissilePriority)
                          and ((MissilePriority <> BestMissilePriority)
                              or (MissileDistance <= NearestMissileDistance)) then
                      begin
                        NearestMissileDistance := MissileDistance;
                        BestMissilePriority := MissilePriority;
                        InterceptedMissile := Missile;
                      end;
                    end;
                  end;
                end;
                if InterceptedMissile <> nil then
                begin
                  if RecordFilm then
                  begin
                    CreateFilmEffect('Weapon.PDTurret', 0, Effect, EffectFilm);
                    CurrentFilm.SetWeaponEndpoints(
                        StepIndex,
                        EffectFilm,
                        Ship.FilmObject,
                        InterceptedMissile.FilmObject
                    );
                    CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
                    CurrentFilm.AttachObject(StepIndex, EffectFilm);
                    CreateFilmEffect('Weapon.Asteroid', 0, Effect, EffectFilm);
                    CurrentFilm
                        .SetObjectPosition(StepIndex, EffectFilm, InterceptedMissile.Position);
                    CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, False, True);
                    CurrentFilm.AttachObject(StepIndex, EffectFilm);
                    CurrentFilm.DetachObject(StepIndex, InterceptedMissile.FilmObject);
                    Self.PendingFilmObjectRemovals.Add(InterceptedMissile.FilmObject);
                    ReleaseSpaceObject(InterceptedMissile.Graphic);
                  end;
                  InterceptedMissile.Free;
                end;
              end;
            end;
          end;
        end;
        Stage := 2974;
        CanPull := 1;
        if (GetPlayer = Ship)
            and (Ship.PickupTargets <> nil)
            and (Ship.GetCargoHook <> nil)
            and (Ship.MovementPath.NodeCount <> 0) then
        begin
          CanPull := 0;
          for CandidateIndex := 0 to (Ship.PickupTargets.Count - 1) do
          begin
            Target := Ship.PickupTargets[CandidateIndex];
            ClosestNodeIndex := 0;
            if Self.Items.IndexOf(Target) >= 0 then
            begin
              Item := TObject(Target) as TItem;
              Node := Ship.MovementPath.ActiveHead;
              ClosestDistance := PointDistance(Item.Position, Node^.Position);
              if Ship.GetCargoHookRange < ClosestDistance then
                Continue;
              ClosestNodeIndex := 0;
              Node := Node^.Next;
              for NodeIndex := 1 to (Ship.MovementPath.NodeCount - 1) do
              begin
                Distance := PointDistance(Item.Position, Node^.Position);
                if Ship.GetCargoHookRange >= Distance then
                begin
                  if Distance >= ClosestDistance then
                    Break;
                  if Distance < ClosestDistance then
                  begin
                    ClosestDistance := Distance;
                    ClosestNodeIndex := NodeIndex;
                    Break;
                  end;
                  Node := Node^.Next;
                end;
              end;
            end;
            if ClosestNodeIndex = 0 then
            begin
              CanPull := 1;
              Break;
            end;
          end;
        end;
        Stage := 2975;
        if not ((Galaxy.StasisModEnabled = 1) and (GetPlayer <> Ship)
            or ((Ship.PickupTargets = nil) or ((Ship.GetCargoHook = nil) or (CanPull = 0)))) then
        begin
          CanPull := 0;
          PulledItemCount := 0;
          for CandidateIndex := (Ship.PickupTargets.Count - 1) downto 0 do
          begin
            Target := Ship.PickupTargets[CandidateIndex];
            if Self.Items.IndexOf(Target) >= 0 then
            begin
              Item := TObject(Target) as TItem;
              Distance := PointDistance(Item.Position, Ship.Position);
              if Ship.GetCargoHookRange < Distance then
                Continue;
              if not Ship.PickupPathUpdatesAllowed then
                Continue;
              if Distance < 5.0 then
                CompleteItemPickup
              else
              begin
                if (Ship <> NearestShip) and (Item = NearestItem) then
                  Distance :=
                      Distance
                          - (2.5 - RemapClamped(Distance, 0.0, Ship.GetCargoHookRange, 1.0, 2.0))
                          - SeededRandomFloatRange(
                              Cardinal(Ship.Id + Integer(Trunc(Galaxy.CurrentTurn))),
                              0.1,
                              0.3)
                else
                  Distance :=
                      Distance
                          - RemapClamped(
                              Distance,
                              0.0,
                              Ship.GetCargoHookRange,
                              Ship.GetCargoHookMaxPullSpeed,
                              Ship.GetCargoHookMinPullSpeed)
                          - SeededRandomFloatRange(
                              Cardinal(Ship.Id + Integer(Trunc(Galaxy.CurrentTurn))),
                              0.1,
                              0.3);
                if Item.DestroyFlag > 0 then
                  Distance := Max(PointDistance(Item.Position, Ship.Position) * 0.99, Distance);
                if Distance < 1.0 then
                  Distance := 1.0;
                Angle :=
                    Math.ArcTan2(
                        Item.Position.X - Ship.Position.X,
                        -(Item.Position.Y - Ship.Position.Y)
                    );
                Item.Position :=
                    MakePointF(
                        System.Sin(Angle) * Distance + Ship.Position.X,
                        Ship.Position.Y - System.Cos(Angle) * Distance
                    );
                if not (Ship is TRuins) then
                  Ship.Position :=
                      MakePointF(
                          System.Sin(Angle) * 0.01 + Ship.Position.X,
                          Ship.Position.Y - System.Cos(Angle) * 0.01
                      );
                if RecordFilm then
                begin
                  CurrentFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
                  CurrentFilm.SetObjectPosition(StepIndex, Ship.FilmObject, Ship.Position);
                end;
                Inc(PulledItemCount);
                if Distance < 5.0 then
                  CompleteItemPickup;
              end;
            end
            else
              Ship.RemovePickupTarget(Target);
            CanPull := 1;
            Break;
          end;
          if CanPull <> 0 then
          begin
            Inc(Index);
            Continue;
          end;
        end;
        Stage := 2976;
        if (Galaxy.StasisModEnabled <> 1) and (Ship.CargoFreeSpace < 0) and (GetPlayer <> Ship) then
        begin
          Ship.AutoEquipInventory;
          Ship.DropCargoUntilNotOverloaded;
          Ship.AutoEquipInventory;
          if Ship.CargoFreeSpace <= 0 then
            Ship.ClearPickupTargets;
        end;
        Stage := 2977;
        if (Galaxy.StasisModEnabled <> 1) or (GetPlayer = Ship) then
        begin
          if not Ship.ProcessMovementStep(StepIndex, RecordFilm) then
            Inc(Index);
        end
        else
          Inc(Index);
        Stage := 2978;
        Continue;
      end;
      Stage := 2980;
      if RecordFilm and (Cardinal(Cardinal(Count) shr 2) = Cardinal(StepIndex)) then
      begin
        EntryIndex := 0;
        while Galaxy.Holes.Count > EntryIndex do
        begin
          Hole := Galaxy.Holes[EntryIndex];
          if (Hole.Star1 <> Self) and (Hole.Star2 <> Self) then
            Inc(EntryIndex)
          else
          begin
            if (Hole.HoleType = 1) and (Galaxy.CurrentTurn - Hole.CreatedTurn > 200)
                or ((Hole.HoleType = 3)
                    or (Hole.HoleType = 4)
                        and ((Galaxy.KellerMissionState = 5)
                            and (Galaxy.ScaleIntByTechLevel(1, 10)
                                < Galaxy.CurrentTurn - Hole.CreatedTurn))
                    or (Hole.HoleType = 4) and (aKling.KellerShip = nil)) then
            begin
              Index := 0;
              DestinationShipCount := Hole.Star1.Ships.Count;
              while Index < DestinationShipCount do
              begin
                Ship := Hole.Star1.Ships[Index];
                if (Ship.Order = soJumpHole) and (Ship.OrderTarget = Hole) then
                  Break;
                Inc(Index);
              end;
              if Index >= DestinationShipCount then
              begin
                Index := 0;
                DestinationShipCount := Hole.Star2.Ships.Count;
                while Index < DestinationShipCount do
                begin
                  Ship := Hole.Star2.Ships[Index];
                  if (Ship.Order = soJumpHole) and (Ship.OrderTarget = Hole) then
                    Break;
                  Inc(Index);
                end;
                if Index >= DestinationShipCount then
                begin
                  if Hole.FilmObjectId <> 0 then
                  begin
                    ReleaseSpaceObject(Hole.Graphic);
                    Self.PendingFilmObjectRemovals.Add(Pointer(Hole.FilmObjectId));
                    CurrentFilm.SetHoleState(StepIndex, Pointer(Hole.FilmObjectId), 2);
                  end;
                  if Hole.HoleType = 4 then
                    Galaxy.KellerMissionState := 0;
                  Galaxy.Holes.Delete(EntryIndex);
                  Hole.Free;
                  Dec(EntryIndex);
                end;
              end;
            end;
            Inc(EntryIndex);
          end;
        end;
      end;
      // CHANGE: ENHANCEMENT - Capture simulation steps for observer playback.
      if Assigned(ObserverStep) then
        ObserverStep(Self, PathStep + 1, Count);
      Stage := 2990;
      if RecordFilm then
        CurrentFilm.AdvanceObjects(StepIndex);
      Inc(StepIndex);
      Self.CurrentStepIndex := StepIndex;
      Stage := 2999;
      for Index := 0 to (Self.ReferencedItems.Count - 1) do
      begin
        Item := Self.ReferencedItems[Index];
        if Self.Items.IndexOf(Item) >= 0 then
          Item.DestroyFlag := Max(1, Item.DestroyFlag);
      end;
      Self.ReferencedItems.Clear;
    end;
    Stage := 29999;
    Self.ProcessItemScripts(11);
    EntryIndex := 0;
    while Self.Items.Count > EntryIndex do
    begin
      Item := Self.Items[EntryIndex];
      if Self.DamageRadius * Self.DamageRadius > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then
      begin
        Self.ClearItemReferences(Item);
        if RecordFilm then
        begin
          ReleaseSpaceObject(Item.GraphObject);
          Self.PendingFilmObjectRemovals.Add(Item.FilmObject);
        end;
        Self.Items.Delete(EntryIndex);
        Item.Free;
      end
      else
        Inc(EntryIndex);
    end;
    for Index := 0 to (Self.Ships.Count - 1) do
    begin
      Ship := Self.Ships[Index];
      if Ship.DestroyQueued
          and (not Ship.IsHullDestroyed
              and ((GetPlayer <> Ship) or (Byte(GlobalsV.CurrentScreenId) = 16))) then
      begin
        Ship.ScriptItemsAct(satOnDeath, nil, nil, 0);
        Ship.GetHull.HullPoints := 0;
        if Ship.IsHullDestroyed and (GetPlayer <> nil) then
          GetPlayer.ProcessShipDestructionQuests(Ship);
        Ship.RefreshDerivedStats(True);
        if RecordFilm
            and ((Ship.FilmObject <> nil)
                and ((Ship.CurrentPlanet = nil) and (Ship.DockedTo = nil))) then
        begin
          CreateFilmEffect('Weapon.NoGraph', 0, Effect, EffectFilm);
          CurrentFilm.SetWeaponEndpoints(StepIndex, EffectFilm, Ship.FilmObject, Ship.FilmObject);
          CurrentFilm.SetWeaponHit(StepIndex, EffectFilm, 0, 0, Ship.IsHullDestroyed, True);
          CurrentFilm.AttachObject(StepIndex, EffectFilm);
        end;
        Self.ClearShipReferences(Ship);
      end;
    end;
    Stage := 30;
    if RecordFilm and (Self.PlayerFilmPath <> nil) then
    begin
      WorkCount := 0;
      TSPath(Self.PlayerFilmPath).AppendWaypoint(GetPlayer.Position, StepIndex);
      Node := Self.PlayerFilmPath.ActiveHead;
      Point := Node^.Position;
      PathStep := Integer(System.Round(Node^.Heading));
      Node := Node^.Next;
      while (Node <> nil) and not (PathStep < System.Round(Node^.Heading)) do
        Node := Node^.Next;
      while Node <> nil do
      begin
        EntryCount := Integer(System.Round(Node^.Heading)) - PathStep + 1;
        WorkValue := PointDistance(Point, Node^.Position);
        if (WorkValue > 200.0) or (WorkValue > 0.0) and (Self.PlayerFilmPath.ActiveTail = Node) then
        begin
          Delta.X := (Node^.Position.X - Point.X) / WorkValue;
          Delta.Y := (Node^.Position.Y - Point.Y) / WorkValue;
          WorkValue := WorkValue / EntryCount;
          if (WorkCount = 0) or (Self.PlayerFilmPath.ActiveTail = Node) then
          begin
            if FastCameraSpeed < WorkValue then
              WorkValue := FastCameraSpeed;
            if CameraSpeed < WorkValue then
              WorkCount := 1;
          end
          else
          begin
            if CameraSpeed < WorkValue then
              WorkValue := CameraSpeed;
          end;
          Delta.X := Delta.X * WorkValue;
          Delta.Y := Delta.Y * WorkValue;
          for EntryIndex := 0 to (EntryCount - 1) do
          begin
            Point.X := Point.X + Delta.X;
            Point.Y := Point.Y + Delta.Y;
            Inc(PathStep);
          end;
        end;
        Node := Node^.Next;
        while (Node <> nil) and not (PathStep < System.Round(Node^.Heading)) do
          Node := Node^.Next;
      end;
      Self.PlayerFilmPath.Free;
      Self.PlayerFilmPath := nil;
    end;
    Stage := 31;
    for Index := 0 to (Self.Ships.Count - 1) do
    begin
      Ship := Self.Ships[Index];
      Ship.ClearCompletedTakeoffOrHoleOrder(StepIndex, RecordFilm);
      if (Ship.InterceptorGraphic <> nil) and (Ship.InterceptorPassesRemaining = 0)
          or not Ship.InNormalSpace and (Ship.InterceptorPassesRemaining > 0) then
      begin
        if Ship.AuxiliaryFilmObject <> nil then
          CurrentFilm.DetachObject(StepIndex, Ship.AuxiliaryFilmObject);
        Ship.InterceptorSourceShip := nil;
        Ship.InterceptorPassesRemaining := 0;
      end;
    end;
    if GetPlayer <> nil then
      GetPlayer.AchievementStats.CheckTranclucatorFleetAchievement;
    Stage := 32;
    EntryCount := Self.MovingDropItems.Count;
    for EntryIndex := 0 to (EntryCount - 1) do
    begin
      MovingDrop := Self.MovingDropItems[EntryIndex];
      if not MovingDrop^.InsertedIntoStar and (MovingDrop^.Payload <> nil) then
      begin
        Item := TObject(MovingDrop^.Payload) as TItem;
        if (Item is TArtefactTranclucator) and (MovingDrop^.UseFlag <> 0) then
        begin
          Tranclucator := TObject((Item as TArtefactTranclucator).Ship) as TTranclucator;
          (Item as TArtefactTranclucator).Ship := nil;
          Tranclucator.CurrentStar := Self;
          Self.Ships.Add(Tranclucator);
          Tranclucator.Position := MovingDrop^.Destination;
          Tranclucator.MovementDirection := 0.0;
          Item.Free;
          if RecordFilm then
          begin
            Tranclucator.FilmObject := CurrentFilm.AddObject(Tranclucator.Id, Tranclucator.Graphic);
            CurrentFilm.DetachObject(0, Tranclucator.FilmObject);
            CurrentFilm.SetObjectPosition(StepIndex, Tranclucator.FilmObject, Self.Position);
            CurrentFilm.SetObjectAngle(StepIndex, Tranclucator.FilmObject, 0);
            CurrentFilm.SetObjectAlpha(StepIndex, Tranclucator.FilmObject, 255);
            CurrentFilm.AttachObject(StepIndex, Tranclucator.FilmObject);
          end;
        end
        else
        begin
          Item.Position := MovingDrop^.Destination;
          Self.Items.Add(Item);
          MovingDrop^.InsertedIntoStar := True;
          if RecordFilm then
          begin
            Item.FilmObject := CurrentFilm.AddObject(Item.Id, Item.GetGraphObject);
            CurrentFilm.DetachObject(0, Item.FilmObject);
            CurrentFilm.SetObjectPosition(StepIndex, Item.FilmObject, Self.Position);
            CurrentFilm.AttachObject(StepIndex, Item.FilmObject);
          end;
        end;
      end;
      FreeEC(MovingDrop);
    end;
    Self.MovingDropItems.Clear;
    Stage := 33;
    if RecordFilm then
    begin
      Inc(StepIndex);
      Self.CurrentStepIndex := StepIndex;
      CurrentFilm.BeginTrailingEffects(StepIndex);
      Inc(StepIndex);
      Self.CurrentStepIndex := StepIndex;
    end;
    if RecordFilm then
      CurrentFilm.ReleaseWeaponEffects(StepIndex);
    Stage := 34;
    Count := Self.CombatEvents.Count;
    for Index := 0 to (Count - 1) do
    begin
      CombatEvent := Self.CombatEvents[Index];
      FreeEC(CombatEvent);
    end;
    Self.CombatEvents.Clear;
    Stage := 35;
    if not RecordFilm and ((GetPlayer <> nil) and (GetPlayer.CurrentStar <> Self)) then
    begin
      Index := 0;
      while Self.Ships.Count > Index do
      begin
        Ship := Self.Ships[Index];
        if Ship.IsHullDestroyed and (Ship is TRanger) then
          Ship.TryRelocateUnseenShip;
        Inc(Index);
      end;
    end;
    Stage := 36;
    Index := 0;
    while Self.Ships.Count > Index do
    begin
      Ship := Self.Ships[Index];
      if (Ship.DockedTo <> nil) and Ship.DockedTo.IsHullDestroyed then
      begin
        Ship.ScriptItemsAct(satOnDeath, nil, nil, 0);
        Self.ClearShipReferences(Ship);
        Ship.DockedTo := nil;
        Ship.GetHull.HullPoints := 0;
        if Ship.IsHullDestroyed then
        begin
          if GetPlayer <> nil then
          begin
            GetPlayer.ProcessShipDestructionQuests(Ship);
            if GetPlayer = Ship then
            begin
              Globals.ScoreScreen.RecordPlayerResult(False);
              DeathEvent := AddGalaxyEvent('PlayerDeath');
              TGalaxyEvent(DeathEvent).AddTextData('StationDestroyed');
            end;
          end;
        end;
        Index := 0;
        if RecordFilm and (Ship.FilmObject = nil) then
        begin
          Ship.FilmObject := CurrentFilm.AddObject(Ship.Id, Ship.Graphic);
          CurrentFilm.DetachObject(0, Ship.FilmObject);
        end;
      end
      else
        Inc(Index);
    end;
    Stage := 37;
    Index := 0;
    StationDestroyed := 0;
    while Self.Ships.Count > Index do
    begin
      Ship := Self.Ships[Index];
      if Ship.IsHullDestroyed then
      begin
        if RecordFilm then
        begin
          EntryCount := Ship.Inventory.Count;
          for EntryIndex := 0 to (EntryCount - 1) do
          begin
            Item := Ship.Inventory[EntryIndex];
            if CurrentFilm.ContainsObject(Item.FilmObject) then
            begin
              CurrentFilm.ReleaseObject(StepIndex, Item.FilmObject);
              ReleaseSpaceObject(Item.GraphObject);
            end;
          end;
          EntryCount := Ship.Artefacts.Count;
          for EntryIndex := 0 to (EntryCount - 1) do
          begin
            Item := Ship.Artefacts[EntryIndex];
            if CurrentFilm.ContainsObject(Item.FilmObject) then
            begin
              CurrentFilm.ReleaseObject(StepIndex, Item.FilmObject);
              ReleaseSpaceObject(Item.GraphObject);
            end;
          end;
          if Ship.FilmObject = nil then
          begin
            Ship.FilmObject := CurrentFilm.AddObject(Ship.Id, Ship.Graphic);
            CurrentFilm.DetachObject(0, Ship.FilmObject);
          end;
          if Ship.FilmObject <> nil then
          begin
            CurrentFilm.ReleaseObject(StepIndex, Ship.FilmObject);
            ReleaseSpaceObject(Ship.Graphic);
          end;
          if Ship.AuxiliaryFilmObject <> nil then
          begin
            CurrentFilm.ReleaseObject(StepIndex, Ship.AuxiliaryFilmObject);
            ReleaseSpaceObject(Ship.InterceptorGraphic);
          end;
        end;
        if Ship is TRuins then
          StationDestroyed := 1;
        if GetPlayer = Ship then
        begin
          Globals.ScoreScreen.RecordPlayerResult(False);
          while ((Byte(GlobalsV.CurrentScreenId) = 19) or (Byte(GlobalsV.CurrentScreenId) = 21))
              and (Galaxy.ScoreScreenDismissed = 0) do
            SysUtils.Sleep(1);
          Galaxy.ScoreScreenDismissed := 0;
        end;
        Self.Ships.Delete(Index);
        Ship.Free;
      end
      else
      begin
        if not Ship.InNormalSpace then
          Ship.InterceptorPassesRemaining := 0;
        if (Ship.InterceptorPassesRemaining <= 0) and (Ship.InterceptorGraphic <> nil) then
        begin
          if RecordFilm and (Ship.AuxiliaryFilmObject <> nil) then
          begin
            CurrentFilm.ReleaseObject(StepIndex, Ship.AuxiliaryFilmObject);
            ReleaseSpaceObject(Ship.InterceptorGraphic);
          end;
          Ship.ClearIncomingInterceptors;
        end;
        Inc(Index);
      end;
    end;
    if (StationDestroyed <> 0) and (GetPlayer <> nil) then
      GetPlayer.RefreshStorageBubbles;
    Stage := 38;
    Index := 0;
    while Self.Ships.Count > Index do
    begin
      Ship := Self.Ships[Index];
      if (Ship is TTranclucator)
          and ((Ord(TTranclucator(Ship).FollowOwner) <> 0)
              and (TTranclucator(Ship).OwnerShip <> nil)) then
      begin
        OwnerShip := TTranclucator(Ship).OwnerShip;
        if (OwnerShip.CurrentPlanet <> nil)
                and (PointDistanceSquared(
                        Ship.Position,
                        TPlanet(OwnerShip.CurrentPlanet).GetPosition)
                    < 25.0)
            or ((OwnerShip.DockedTo <> nil)
                    and (PointDistanceSquared(Ship.Position, OwnerShip.DockedTo.Position) < 25.0)
                or OwnerShip.InNormalSpace
                    and (PointDistanceSquared(Ship.Position, OwnerShip.Position) < 25.0)) then
        begin
          Self.HandleObjectLeavingStar(Ship);
          Ship.EnemyShip := nil;
          Ship.TruceShip := nil;
          Ship.PartnerShip := nil;
          Ship.OrderNone(False);
          Ship.AfterburnerActive := False;
          for EntryIndex := 1 to Ship.WeaponCount do
            Ship.Weapons[EntryIndex].Target := nil;
          if RecordFilm then
            CurrentFilm.DetachObject(StepIndex, Ship.FilmObject);
          Self.Ships.Delete(Index);
          Ship.CurrentStar := nil;
          if Ship.ScriptShip <> nil then
            TScript((TObject(Ship.ScriptShip) as TScriptShip).Script).UnbindShip(Ship);
          StoredTranclucator := TArtefactTranclucator.Create;
          TArtefactTranclucator(StoredTranclucator)
              .InitTranclucator(Ship.GetHull.OwnerId, OwnerShip, TTranclucator(Ship));
          if Ship.GetEngine <> nil then
            Ship.GetEngine.OutputPercent := 100;
          TTranclucator(Ship).TransferUnequippedCargo(OwnerShip);
          OwnerShip.Artefacts.Add(StoredTranclucator);
          OwnerShip.RefreshDerivedStats(True);
          TTranclucator(Ship).FollowOwner := False;
          Ship.ScriptItemsAct(satOnTrancPacking, StoredTranclucator, OwnerShip, 0);
          OwnerShip.ScriptItemsAct(satOnTrancPacking, StoredTranclucator, OwnerShip, 0);
        end
        else
          Inc(Index);
      end
      else
        Inc(Index);
    end;
    Stage := 39;
    if RecordFilm then
    begin
      Index := 0;
      while Galaxy.JumpGates.Count > Index do
      begin
        GateEntry := Galaxy.JumpGates[Index];
        if GateEntry^.UsedThisTurn then
        begin
          CurrentFilm.ReleaseObject(StepIndex, Pointer(GateEntry^.GateFilmId));
          if GateEntry^.EffectFilmId <> 0 then
            CurrentFilm.ReleaseObject(StepIndex, Pointer(GateEntry^.EffectFilmId));
          Galaxy.JumpGates.Delete(Index);
          if GateEntry^.Gate <> nil then
            ReleaseSpaceObject(GateEntry^.Gate);
          if GateEntry^.Effect <> nil then
            ReleaseSpaceObject(GateEntry^.Effect);
          FreeEC(GateEntry);
        end
        else
          Inc(Index);
      end;
    end;
    Self.PruneWeaponTargetsAfterTurn;
    Stage := 40;
    if RecordFilm then
    begin
      EntryCount := Self.PendingFilmObjectRemovals.Count;
      for EntryIndex := 0 to (EntryCount - 1) do
      begin
        EffectFilm := Self.PendingFilmObjectRemovals[EntryIndex];
        CurrentFilm.ReleaseObject(StepIndex, EffectFilm);
      end;
      Self.PendingFilmObjectRemovals.Clear;
    end;
    Self.ReferencedItems.Clear;
    CurrentFilm.PlayerCombatRecorded := RecordFilm and Self.PlayerCombatOccurred;
    for Index := (Self.Ships.Count - 1) downto 0 do
    begin
      Ship := Self.Ships[Index];
      Ship.RefreshCurrentStanding;
    end;
    Self.RefreshDerivedStats;
    Stage := 41;
    if not Globals.PlayerStarDayPrepared and (Galaxy.StasisModEnabled <> 1) then
      for Index := 0 to (Self.Planets.Count - 1) do
      begin
        Planet := Self.Planets[Index];
        TPlanet(Planet).NextDay;
      end;
    for Index := (Self.Ships.Count - 1) downto 0 do
    begin
      Ship := Self.Ships[Index];
      Ship.RefreshCurrentStanding;
    end;
    if (Self.LiberationRewardsPending) and (GetPlayer <> nil) then
    begin
      ProcessSystemLiberationRewards(GetPlayer, Self);
      Self.LastLiberationRewardsTurn := Cardinal(Galaxy.CurrentTurn);
      Self.LiberationRewardsPending := False;
    end;
    Stage := 42;
    if RecordFilm then
    begin
      if Self.PlayerCombatOccurred then
      begin
        CurrentFilm.InitialActivity := 0;
        CurrentFilm.FinalActivity := 0;
      end
      else
      begin
        CurrentFilm.InitialActivity := Integer(Globals.PreviousFilmActivity);
        CurrentFilm.FinalActivity := CurrentFilm.InitialActivity;
        WorkValue := EstimatePlayerTravelTurns;
        if Globals.PreviousFilmActivity = 0 then
        begin
          if WorkValue >= 1.0 then
            CurrentFilm.FinalActivity := 1;
        end
        else
        begin
          if Globals.PreviousFilmActivity = 1 then
          begin
            if WorkValue >= 2.0 then
              CurrentFilm.FinalActivity := 2;
          end
          else
          begin
            if (Globals.PreviousFilmActivity = 2) and (WorkValue <= 2.0) then
              CurrentFilm.FinalActivity := 1;
          end;
        end;
        Globals.PreviousFilmActivity := Cardinal(CurrentFilm.FinalActivity);
      end;
      TFilmFile(FilmHistory).AddFilm(TEFilm(PrimaryFilm));
    end;
    Stage := 43;
    if (Galaxy.TerronToStarTurn > 0) and (Galaxy.TerronToStarTurn < 1073741824) then
    begin
      if aKling.TerronShip <> nil then
      begin
        if aKling.TerronShip.CurrentStar = Self then
        begin
          if PointDistanceSquared(MakePointF(-100.0, -100.0), aKling.TerronShip.Position)
              < 25.0 then
          begin
            Galaxy.TerronToStarTurn := Galaxy.CurrentTurn or 1073741824;
            PWideString(@Self.Graphic.GraphKey)^ := WideString('Star.TerronAfter');
            Self.Graphic.LoadTemplate(
                GR_Main.GameDataConfig.GetBlockByPath('SE.' + WideString(Self.Graphic.GraphKey))
            );
            if GetPlayer <> nil then
            begin
              if GetPlayer.CurrentStar <> Self then
              begin
                aKling.TerronShip.Order := soJump;
                aKling.TerronShip.OrderTarget := Self;
                aKling.TerronShip.InHyperspace := True;
                aKling.TerronShip.OrderStateData := 2;
                aKling.TerronShip.Position := MakePointF(0.0, 0.0);
              end;
            end;
          end;
        end;
      end;
    end;
    Stage := 44;
    if (GetPlayer <> nil)
        and ((GetPlayer.CurrentStar = Self)
            and ((aRanger.PendingPlayerFollowTarget <> nil)
                and ((aRanger.PendingPlayerFollowTarget.CurrentStar <> Self)
                    or not aRanger.PendingPlayerFollowTarget.InNormalSpace))) then
    begin
      aRanger.PendingPlayerFollowTarget := nil;
      GetPlayer.OrderNone(False);
    end;
    Self.RecordingTurnFilm := False;
    if (GetPlayer <> nil) and (GetPlayer.CurrentStar = Self) then
      GetPlayer.AchievementStats.CheckBomberAchievement(GetPlayer.BombKillsThisTurn);
    aShip.SimulationContext := 0;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(AnsiString(E.ClassName + ' ' + E.Message));
      LogExceptionBackTrace;
      raise Exception.Create(
          'Error in procedure TStar.NextDay '
              + WideString(Self.Name)
              + ' label = '
              + SysUtils.IntToStr(Stage));
    end;
  end;
end;
procedure TGalaxy.ShowLocalizedWarning(TextKey: WideString);
begin
  AddOrUpdatePlayerBubble(5, 0, LocalizedColorText(TextKey), '');
end;
constructor TInterfaceStateOverride.Create;
begin
  inherited Create;
end;
destructor TInterfaceStateOverride.Destroy;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(FormName);
  if Form <> nil then
  begin
    Control := Form.FindControlByPath(ControlPath);
    if Control <> nil then
    begin
      Control.SetActive(OriginalState > 0);
      if (OriginalState > 1) and (Control is TGraphButtonGI) then
        TGraphButtonGI(Control).SetDisabled(OriginalState = 2);
    end;
  end;
  inherited Destroy;
end;
procedure TInterfaceStateOverride.Initialize(FormName, ControlPath: WideString; State: Byte);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.FormName := FormName;
  Self.ControlPath := ControlPath;
  Self.State := State;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceStateOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    OriginalState := Ord(Control.Active);
    Control.SetActive(Self.State > 0);
    if (OriginalState > 0) and (Control is TGraphButtonGI) then
      OriginalState := 3 - Ord(TGraphButtonGI(Control).Disabled);
    if (Self.State > 1) and (Control is TGraphButtonGI) then
      TGraphButtonGI(Control).SetDisabled(Self.State = 2);
  end;
end;
procedure TInterfaceStateOverride.SetState(State: Byte);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.State := State;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceStateOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    Control.SetActive(Self.State > 0);
    if (Self.State > 1) and (Control is TGraphButtonGI) then
      TGraphButtonGI(Control).SetDisabled(Self.State = 2);
  end;
end;
function TInterfaceStateOverride.GetState: Byte;
begin
  Result := State;
end;
procedure TInterfaceStateOverride.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(FormName);
  Buffer.AddWideStringZ(ControlPath);
  Buffer.AddAnsiChar(AnsiChar(State));
  Buffer.AddAnsiChar(AnsiChar(OriginalState));
end;
procedure TInterfaceStateOverride.LoadFromBuffer(Buffer: TBufEC);
begin
  FormName := Buffer.ReadWideString;
  ControlPath := Buffer.ReadWideString;
  if LoadedSaveVersion >= 160 then
  begin
    State := Buffer.GetByte;
    OriginalState := Buffer.GetByte;
  end
  else
  begin
    State := Ord(Buffer.GetBoolean);
    OriginalState := Ord(Buffer.GetBoolean);
  end;
  Reapply;
end;
procedure TInterfaceStateOverride.Reapply;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceStateOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    Control.SetActive(Self.State > 0);
    if (Self.State > 1) and (Control is TGraphButtonGI) then
      TGraphButtonGI(Control).SetDisabled(Self.State = 2);
  end;
end;
constructor TInterfaceTextOverride.Create;
begin
  inherited Create;
end;
destructor TInterfaceTextOverride.Destroy;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(FormName);
  if Form <> nil then
  begin
    Control := Form.FindControlByPath(ControlPath);
    if Control <> nil then
    begin
      if not (Control is TLabelGI) then
        AppendLogLineThreadSafe(AnsiString('Object is not a label - ' + ControlPath))
      else
        (Control as TLabelGI).SetText(OriginalText);
    end;
  end;
  inherited Destroy;
end;
procedure TInterfaceTextOverride.Initialize(FormName, ControlPath: WideString; Text: WideString);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.FormName := FormName;
  Self.ControlPath := ControlPath;
  Self.Text := Text;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceTextOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    if not (Control is TLabelGI) then
      raise Exception.Create(AnsiString('Object is not a label - ' + Self.ControlPath));
    OriginalText := (Control as TLabelGI).GetText;
    (Control as TLabelGI).SetText(Self.Text);
  end;
end;
procedure TInterfaceTextOverride.SetText(Text: WideString);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.Text := Text;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceTextOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    if not (Control is TLabelGI) then
      raise Exception.Create(AnsiString('Object is not a label - ' + Self.ControlPath));
    (Control as TLabelGI).SetText(Self.Text);
  end;
end;
function TInterfaceTextOverride.GetText: WideString;
begin
  Result := Text;
end;
procedure TInterfaceTextOverride.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(FormName);
  Buffer.AddWideStringZ(ControlPath);
  Buffer.AddWideStringZ(Text);
  Buffer.AddWideStringZ(OriginalText);
end;
procedure TInterfaceTextOverride.LoadFromBuffer(Buffer: TBufEC);
begin
  FormName := Buffer.ReadWideString;
  ControlPath := Buffer.ReadWideString;
  Text := Buffer.ReadWideString;
  OriginalText := Buffer.ReadWideString;
  Reapply;
end;
procedure TInterfaceTextOverride.Reapply;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceTextOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    if not (Control is TLabelGI) then
      raise Exception.Create(AnsiString('Object is not a label - ' + Self.ControlPath));
    (Control as TLabelGI).SetText(Self.Text);
  end;
end;
constructor TInterfaceImageOverride.Create;
begin
  inherited Create;
end;
destructor TInterfaceImageOverride.Destroy;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(FormName);
  if Form <> nil then
  begin
    Control := Form.FindControlByPath(ControlPath);
    if Control <> nil then
    begin
      if (CountDelimitedPartsW(ImagePath, ':') > 1)
          and (ExtractDelimitedPartW(ImagePath, 0, ':') = 'Style') then
      begin
        if OriginalImagePath <> '' then
          Control.SetConfigPath(OriginalImagePath);
      end
      else if Control is TgaiGI then
      begin
        // Native tests the replacement path before restoring the original.
        if CountDelimitedPartsW(ImagePath, '|') < 2 then
          TgaiGI(Control).SetImagePath(OriginalImagePath)
        else
        begin
          TgaiGI(Control).SetFirstFrameImagePath(ExtractDelimitedPartW(OriginalImagePath, 1, '|'));
          TgaiGI(Control).SetImagePath(ExtractDelimitedPartW(OriginalImagePath, 0, '|'));
        end;
        TgaiGI(Control).PrimeImageCaches;
        TgaiGI(Control).SequenceIndex := 0;
        TgaiGI(Control).UpdateAutoGeometry;
        TgaiGI(Control).RestartPlayback;
      end
      else if Control is TgiGI then
        (Control as TgiGI).SetImagePath(OriginalImagePath)
      else if Control is TImageGI then
        (Control as TImageGI).SetImagePath(OriginalImagePath)
      else
        AppendLogLineThreadSafe(AnsiString('Object is not an image - ' + ControlPath));
    end;
  end;
  inherited Destroy;
end;
procedure TInterfaceImageOverride.Initialize(
    FormName, ControlPath: WideString;
    ImagePath: WideString
);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.FormName := FormName;
  Self.ControlPath := ControlPath;
  Self.ImagePath := ImagePath;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceImageOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
                + ' ('
                + Self.ImagePath
                + ')'
        )
    )
  else
  begin
    if (CountDelimitedPartsW(Self.ImagePath, ':') > 1)
        and (ExtractDelimitedPartW(Self.ImagePath, 0, ':') = 'Style') then
    begin
      OriginalImagePath := Control.ConfigPath;
      Control.SetConfigPath(ExtractDelimitedPartW(Self.ImagePath, 1, ':'));
    end
    else if Control is TgaiGI then
    begin
      OriginalImagePath := TgaiGI(Control).GetImagePath;
      if TgaiGI(Control).GetFirstFrameImagePath <> '' then
        OriginalImagePath := OriginalImagePath + '|' + TgaiGI(Control).GetFirstFrameImagePath;
      if CountDelimitedPartsW(Self.ImagePath, '|') < 2 then
        TgaiGI(Control).SetImagePath(Self.ImagePath)
      else
      begin
        TgaiGI(Control).SetFirstFrameImagePath(ExtractDelimitedPartW(Self.ImagePath, 1, '|'));
        TgaiGI(Control).SetImagePath(ExtractDelimitedPartW(Self.ImagePath, 0, '|'));
      end;
      TgaiGI(Control).PrimeImageCaches;
      TgaiGI(Control).SequenceIndex := 0;
      TgaiGI(Control).UpdateAutoGeometry;
      TgaiGI(Control).RestartPlayback;
    end
    else if Control is TgiGI then
    begin
      OriginalImagePath := (Control as TgiGI).GetImagePath;
      (Control as TgiGI).SetImagePath(Self.ImagePath);
    end
    else if Control is TImageGI then
    begin
      OriginalImagePath := (Control as TImageGI).GetImagePath;
      (Control as TImageGI).SetImagePath(Self.ImagePath);
    end
    else
      raise Exception.Create(AnsiString('Object is not an image - ' + Self.ControlPath));
  end;
end;
procedure TInterfaceImageOverride.SetImagePath(ImagePath: WideString);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.ImagePath := ImagePath;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceImageOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
                + ' ('
                + Self.ImagePath
                + ')'
        )
    )
  else
  begin
    if (CountDelimitedPartsW(Self.ImagePath, ':') > 1)
        and (ExtractDelimitedPartW(Self.ImagePath, 0, ':') = 'Style') then
    begin
      Control.SetConfigPath(ExtractDelimitedPartW(Self.ImagePath, 1, ':'));
    end
    else if Control is TgaiGI then
    begin
      if CountDelimitedPartsW(Self.ImagePath, '|') < 2 then
        TgaiGI(Control).SetImagePath(Self.ImagePath)
      else
      begin
        TgaiGI(Control).SetFirstFrameImagePath(ExtractDelimitedPartW(OriginalImagePath, 1, '|'));
        TgaiGI(Control).SetImagePath(ExtractDelimitedPartW(OriginalImagePath, 0, '|'));
      end;
      TgaiGI(Control).PrimeImageCaches;
      TgaiGI(Control).SequenceIndex := 0;
      TgaiGI(Control).UpdateAutoGeometry;
      TgaiGI(Control).RestartPlayback;
    end
    else if Control is TgiGI then
    begin
      (Control as TgiGI).SetImagePath(Self.ImagePath);
    end
    else if Control is TImageGI then
    begin
      (Control as TImageGI).SetImagePath(Self.ImagePath);
    end
    else
      raise Exception.Create(AnsiString('Object is not an image - ' + Self.ControlPath));
  end;
end;
function TInterfaceImageOverride.GetImagePath: WideString;
begin
  Result := ImagePath;
end;
procedure TInterfaceImageOverride.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(FormName);
  Buffer.AddWideStringZ(ControlPath);
  Buffer.AddWideStringZ(ImagePath);
  Buffer.AddWideStringZ(OriginalImagePath);
end;
procedure TInterfaceImageOverride.LoadFromBuffer(Buffer: TBufEC);
begin
  FormName := Buffer.ReadWideString;
  ControlPath := Buffer.ReadWideString;
  ImagePath := Buffer.ReadWideString;
  OriginalImagePath := Buffer.ReadWideString;
  Reapply;
end;
procedure TInterfaceImageOverride.Reapply;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceImageOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
                + ' ('
                + Self.ImagePath
                + ')'
        )
    )
  else
  begin
    if (CountDelimitedPartsW(Self.ImagePath, ':') > 1)
        and (ExtractDelimitedPartW(Self.ImagePath, 0, ':') = 'Style') then
    begin
      Control.SetConfigPath(ExtractDelimitedPartW(Self.ImagePath, 1, ':'));
    end
    else if Control is TgaiGI then
    begin
      if CountDelimitedPartsW(Self.ImagePath, '|') < 2 then
        TgaiGI(Control).SetImagePath(Self.ImagePath)
      else
      begin
        TgaiGI(Control).SetFirstFrameImagePath(ExtractDelimitedPartW(Self.ImagePath, 1, '|'));
        TgaiGI(Control).SetImagePath(ExtractDelimitedPartW(Self.ImagePath, 0, '|'));
      end;
      TgaiGI(Control).PrimeImageCaches;
      TgaiGI(Control).SequenceIndex := 0;
      TgaiGI(Control).UpdateAutoGeometry;
      TgaiGI(Control).RestartPlayback;
    end
    else if Control is TgiGI then
    begin
      (Control as TgiGI).SetImagePath(Self.ImagePath);
    end
    else if Control is TImageGI then
    begin
      (Control as TImageGI).SetImagePath(Self.ImagePath);
    end
    else
      raise Exception.Create(AnsiString('Object is not an image - ' + Self.ControlPath));
  end;
end;
constructor TInterfacePosOverride.Create;
begin
  inherited Create;
end;
destructor TInterfacePosOverride.Destroy;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(FormName);
  if Form <> nil then
  begin
    Control := Form.FindControlByPath(ControlPath);
    if Control <> nil then
    begin
      Control.SetPosition(Classes.Point(OriginalPosition.X, OriginalPosition.Y));
      Control.SetDepth(OriginalDepth);
    end;
  end;
  inherited Destroy;
end;
procedure TInterfacePosOverride.Initialize(
    FormName, ControlPath: WideString;
    DeltaX, DeltaY, DeltaDepth: Integer
);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.FormName := FormName;
  Self.ControlPath := ControlPath;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfacePosOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    OriginalPosition.X := Control.LocalPosition.X;
    OriginalPosition.Y := Control.LocalPosition.Y;
    OriginalDepth := Control.Depth;
    Position.X := DeltaX + OriginalPosition.X;
    Position.Y := DeltaY + OriginalPosition.Y;
    Depth := OriginalDepth + DeltaDepth;
    Control.SetPosition(Classes.Point(Position.X, Position.Y));
    Control.SetDepth(Depth);
  end;
end;
procedure TInterfacePosOverride.SetPosition(DeltaX, DeltaY, DeltaDepth: Integer);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfacePosOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    Position.X := DeltaX + OriginalPosition.X;
    Position.Y := DeltaY + OriginalPosition.Y;
    Depth := OriginalDepth + DeltaDepth;
    Control.SetPosition(Classes.Point(Position.X, Position.Y));
    Control.SetDepth(Depth);
  end;
end;
procedure TInterfacePosOverride.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(FormName);
  Buffer.AddWideStringZ(ControlPath);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDouble(Depth);
  Buffer.AddIntegerValue(OriginalPosition.X);
  Buffer.AddIntegerValue(OriginalPosition.Y);
  Buffer.AddDouble(OriginalDepth);
end;
procedure TInterfacePosOverride.LoadFromBuffer(Buffer: TBufEC);
begin
  FormName := Buffer.ReadWideString;
  ControlPath := Buffer.ReadWideString;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  Depth := Buffer.GetDouble;
  OriginalPosition.X := Buffer.GetInt32;
  OriginalPosition.Y := Buffer.GetInt32;
  OriginalDepth := Buffer.GetDouble;
  Reapply;
end;
procedure TInterfacePosOverride.Reapply;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfacePosOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    Control.SetPosition(Classes.Point(Position.X, Position.Y));
    Control.SetDepth(Depth);
  end;
end;
constructor TInterfaceSizeOverride.Create;
begin
  inherited Create;
end;
destructor TInterfaceSizeOverride.Destroy;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(FormName);
  if Form <> nil then
  begin
    Control := Form.FindControlByPath(ControlPath);
    if Control <> nil then
    begin
      Control.SetSize(Classes.Point(OriginalSize.X, OriginalSize.Y));
    end;
  end;
  inherited Destroy;
end;
procedure TInterfaceSizeOverride.Initialize(
    FormName, ControlPath: WideString;
    Width, Height: Integer
);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Self.FormName := FormName;
  Self.ControlPath := ControlPath;
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceSizeOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    OriginalSize.X := Control.ClientSize.X;
    OriginalSize.Y := Control.ClientSize.Y;
    if Width > 0 then
      Size.X := Width
    else
      Size.X := OriginalSize.X;
    if Height > 0 then
      Size.Y := Height
    else
      Size.Y := OriginalSize.Y;
    Control.SetSize(Classes.Point(Size.X, Size.Y));
  end;
end;
procedure TInterfaceSizeOverride.SetSize(Width, Height: Integer);
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceSizeOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    if Width > 0 then
      Size.X := Width
    else
      Size.X := OriginalSize.X;
    if Height > 0 then
      Size.Y := Height
    else
      Size.Y := OriginalSize.Y;
    Control.SetSize(Classes.Point(Size.X, Size.Y));
  end;
end;
procedure TInterfaceSizeOverride.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(FormName);
  Buffer.AddWideStringZ(ControlPath);
  Buffer.AddIntegerValue(Size.X);
  Buffer.AddIntegerValue(Size.Y);
  Buffer.AddIntegerValue(OriginalSize.X);
  Buffer.AddIntegerValue(OriginalSize.Y);
end;
procedure TInterfaceSizeOverride.LoadFromBuffer(Buffer: TBufEC);
begin
  FormName := Buffer.ReadWideString;
  ControlPath := Buffer.ReadWideString;
  Size.X := Buffer.GetInt32;
  Size.Y := Buffer.GetInt32;
  OriginalSize.X := Buffer.GetInt32;
  OriginalSize.Y := Buffer.GetInt32;
  Reapply;
end;
procedure TInterfaceSizeOverride.Reapply;
var
  Form: TMessageLoopGI;
  Control: TObjectGI;
begin
  Form := FindMessageLoop(Self.FormName);
  if Form = nil then
    raise Exception.Create(AnsiString('ML not found - ' + Self.FormName));
  Control := Form.FindControlByPath(Self.ControlPath);
  if Control = nil then
    AppendLogLineThreadSafe(
        AnsiString(
            'TInterfaceSizeOverride: object not found - '
                + Self.ControlPath
                + ' on form '
                + Self.FormName
        )
    )
  else
  begin
    Control.SetSize(Classes.Point(Size.X, Size.Y));
  end;
end;
constructor TStoredItem.CreateEmpty;
begin
  inherited Create;
  Name := '';
  Item := nil;
end;
constructor TStoredItem.Create(Name: WideString; Item: TObject);
begin
  inherited Create;
  Self.Name := Name;
  Self.Item := Item;
end;
destructor TStoredItem.Destroy;
begin
  if Item <> nil then
    Item.Free;
  Item := nil;
  inherited Destroy;
end;
procedure TStoredItem.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(Name);
  Buffer.AddAnsiChar(AnsiChar(TItem(Item).ItemType));
  TItem(Item).SaveToBuffer(Buffer);
end;
procedure TStoredItem.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
begin
  Name := Buffer.ReadWideString;
  Item := CreateItemByType(MigrateSavedItemType(Buffer.GetByte));
  TItem(Item).LoadFromBuffer(Buffer, Galaxy);
end;
procedure TGalaxy.StoreItem(Name: WideString; Item: TObject);
var
  Entry: TStoredItem;
  LowIndex, HighIndex, Middle, Comparison: Integer;
begin
  if Item is THull then
  begin
    THull(Item).OwnerShip := nil;
    THull(Item).InterceptorTarget := nil;
  end;
  if Item is TWeapon then
  begin
    TWeapon(Item).Target := nil;
    TWeapon(Item).LoadedTargetKind := wtkNone;
  end;
  if Item is TArtefactTranclucator then
    TTranclucator(TArtefactTranclucator(Item).Ship).OwnerShip := nil;
  if Item is TSatellite then
    TSatellite(Item).TargetPlanet := nil;
  if StoredItems.Count < 1 then
  begin
    Entry := TStoredItem.Create(Name, Item);
    StoredItems.Add(Entry);
    Exit;
  end;
  LowIndex := 0;
  Entry := TStoredItem(StoredItems[0]);
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Entry.Name));
  if Comparison = 0 then
  begin
    Entry.Item.Free;
    Entry.Item := Item;
    Exit;
  end;
  if Comparison < 0 then
  begin
    Entry := TStoredItem.Create(Name, Item);
    StoredItems.Insert(0, Entry);
    Exit;
  end;
  HighIndex := StoredItems.Count - 1;
  Entry := TStoredItem(StoredItems[HighIndex]);
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Entry.Name));
  if Comparison = 0 then
  begin
    Entry.Item.Free;
    Entry.Item := Item;
    Exit;
  end;
  if Comparison > 0 then
  begin
    Entry := TStoredItem.Create(Name, Item);
    StoredItems.Add(Entry);
  end
  else
  begin
    while True do
    begin
      if HighIndex - LowIndex < 2 then
      begin
        Entry := TStoredItem.Create(Name, Item);
        StoredItems.Insert(HighIndex, Entry);
        Exit;
      end;
      Middle := (LowIndex + HighIndex) div 2;
      Entry := TStoredItem(StoredItems[Middle]);
      Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Entry.Name));
      if Comparison = 0 then
      begin
        Entry.Item.Free;
        Entry.Item := Item;
        Exit;
      end;
      if Comparison < 0 then
        HighIndex := Middle
      else
        LowIndex := Middle;
    end;
  end;
end;
function TGalaxy.GetStoredItem(Name: WideString; Remove: Boolean): TObject;
var
  Entry: TStoredItem;
  Index, LowIndex, HighIndex, Comparison: Integer;
  function TakeEntry: TObject; // @addr 0x7D4318 @ida "TObject *__cdecl $name(void *ParentFrame);" @note "Nested in GetStoredItem; caller-popped static link. Entry -4, Remove -5, Self -12, Index -16."
  begin
    Result := Entry.Item;
    if Remove then
    begin
      Entry.Item := nil;
      Entry.Free;
      StoredItems.Delete(Index);
    end;
  end;
begin
  Result := nil;
  if StoredItems.Count < 1 then
    Exit;
  Index := 0;
  Entry := TStoredItem(StoredItems[Index]);
  if Entry.Name = Name then
  begin
    Result := TakeEntry;
    Exit;
  end;
  Index := StoredItems.Count - 1;
  Entry := TStoredItem(StoredItems[Index]);
  if Entry.Name = Name then
  begin
    Result := TakeEntry;
    Exit;
  end;
  LowIndex := 0;
  HighIndex := StoredItems.Count - 1;
  while True do
  begin
    if HighIndex - LowIndex < 2 then
    begin
      Result := nil;
      Break;
    end;
    Index := (LowIndex + HighIndex) div 2;
    Entry := TStoredItem(StoredItems[Index]);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Entry.Name));
    if Comparison = 0 then
    begin
      Result := TakeEntry;
      Break;
    end;
    if Comparison < 0 then
      HighIndex := Index
    else
      LowIndex := Index;
  end;
end;
function TGalaxy.GetOrCreateCustomWeaponInfo(Name: WideString): PWeaponInfo;
var
  Info: PWeaponInfo;
  LowIndex, HighIndex, Middle, Comparison: Integer;
  procedure Allocate; // @addr $7D44C4 @ida "void __cdecl $name(void *ParentFrame);"
  var
    State: Cardinal;
  begin
    New(Result);
    Result.ConfigName := Name;
    Result.ItemType := t_CustomWeapon;
    State := InitCrc32;
    State := UpdateCrc32(State, PWideChar(Result.ConfigName), Length(Result.ConfigName) * 2);
    Result.TypeHash := FinishCrc32(State);
  end;
begin
  if CustomWeaponTypes.Count < 1 then
  begin
    Allocate;
    CustomWeaponTypes.Add(Result);
    Exit;
  end;
  LowIndex := 0;
  Info := CustomWeaponTypes[0];
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
  if Comparison = 0 then
  begin
    Result := Info;
    Exit;
  end;
  if Comparison < 0 then
  begin
    Allocate;
    CustomWeaponTypes.Insert(0, Result);
    Exit;
  end;
  HighIndex := CustomWeaponTypes.Count - 1;
  Info := CustomWeaponTypes[HighIndex];
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
  if Comparison = 0 then
  begin
    Result := Info;
    Exit;
  end;
  if Comparison > 0 then
  begin
    Allocate;
    CustomWeaponTypes.Add(Result);
    Exit;
  end;
  while True do
  begin
    if HighIndex - LowIndex < 2 then
    begin
      Allocate;
      CustomWeaponTypes.Insert(HighIndex, Result);
      Exit;
    end;
    Middle := (LowIndex + HighIndex) div 2;
    Info := CustomWeaponTypes[Middle];
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
    if Comparison = 0 then
    begin
      Result := Info;
      Exit;
    end;
    if Comparison < 0 then
      HighIndex := Middle
    else
      LowIndex := Middle;
  end;
end;
function TGalaxy.RequireCustomWeaponInfo(Name: WideString): PWeaponInfo;
var
  Info: PWeaponInfo;
  LowIndex, HighIndex, Middle, Comparison: Integer;
begin
  if CustomWeaponTypes.Count < 1 then
    raise Exception.Create('Cant find custom weapon info = ' + Name);
  LowIndex := 0;
  Info := CustomWeaponTypes[0];
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
  if Comparison = 0 then
  begin
    Result := Info;
    Exit;
  end;
  if Comparison < 0 then
    raise Exception.Create('Cant find custom weapon info = ' + Name);
  HighIndex := CustomWeaponTypes.Count - 1;
  Info := CustomWeaponTypes[HighIndex];
  Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
  if Comparison = 0 then
  begin
    Result := Info;
    Exit;
  end;
  if Comparison > 0 then
    raise Exception.Create('Cant find custom weapon info = ' + Name);
  while True do
  begin
    if HighIndex - LowIndex < 2 then
      raise Exception.Create('Cant find custom weapon info = ' + Name);
    Middle := (LowIndex + HighIndex) div 2;
    Info := CustomWeaponTypes[Middle];
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Info.ConfigName));
    if Comparison = 0 then
    begin
      Result := Info;
      Break;
    end;
    if Comparison < 0 then
      HighIndex := Middle
    else
      LowIndex := Middle;
  end;
end;
function TGalaxy.CanRecordAchievements: Boolean;
begin
  Result := (SpecialSimulationMode = 0) and (GetCheatPoints = 0) and not EditableStateApplied;
end;

procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TArtefactTranclucator.ClassName;
  TAsteroid.ClassName;
  TCistern.ClassName;
  TConstellation.ClassName;
  TCountableItem.ClassName;
  TCustomWeapon.ClassName;
  TEObjInfo.ClassName;
  TEquipment.ClassName;
  TEquipmentWithActCode.ClassName;
  TGoods.ClassName;
  TGraphButtonGI.ClassName;
  THole.ClassName;
  THull.ClassName;
  TImageGI.ClassName;
  TItem.ClassName;
  TKling.ClassName;
  TLabelGI.ClassName;
  TMissile.ClassName;
  TNormalShip.ClassName;
  TPirate.ClassName;
  TPlanet.ClassName;
  TPlayer.ClassName;
  TRanger.ClassName;
  TRuins.ClassName;
  TRuinsSE.ClassName;
  TSatellite.ClassName;
  TScriptShip.ClassName;
  TShip.ClassName;
  TShip2SE.ClassName;
  TStar.ClassName;
  TTranclucator.ClassName;
  TUselessItem.ClassName;
  TWarrior.ClassName;
  TWeapon.ClassName;
  TgaiGI.ClassName;
  TgiGI.ClassName;
end;
end.
