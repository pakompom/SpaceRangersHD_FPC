{$EXCESSPRECISION OFF}
unit aGalaxyStruct;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Windows;
const
  stKling = 0;
  stRanger = 1;
  stTransport = 2;
  stPirate = 3;
  stWarrior = 4;
  stTranclucator = 5;
  ssDominator = 0;
  ssUnaligned = 1;
  ssCoalitionMilitary = 2;
  ssCoalitionActive = 3;
  ssCoalitionPassive = 4;
  ssNeutral = 5;
  ssPiratePassive = 6;
  ssPirateActive = 7;
  ssPirateMilitary = 8;
  ssCustom = 9;
  ssmNormal = 0;
  ssmCustomFaction = 1;
  ssmFixed = 2;
  gscTransport = 0;
  gscLiner = 1;
  gscDiplomat = 2;
  gscRanger = 3;
  gscPirate = 4;
  gscWarrior = 5;
  gscKling = 6;
  gscPirateClan = 7;
  htRanger = 0;
  htWarrior = 1;
  htPirate = 2;
  htTransport = 3;
  htLiner = 4;
  htDiplomat = 5;
  htKling = 6;
  htTranclucator = 7;
  htStation = 8;
  htSpecial = 9;
  htFlagship = 10;
  prgKellerCall = 0;
  prgLogicalNegation = 1;
  prgDematerial = 2;
  prgEnergotron = 3;
  prgSabCrack = 4;
  prgIntercom = 5;
  prgShipwreck = 6;
  prgWeaponBlocking = 7;
  prgInsanity = 8;
  prgShock = 9;
  prgSelfDestruction = 10;
  prgDisconnection = 11;
  cpCreateRangerCenter = 0;
  cpCreatePirateBase = 1;
  cpCreateMilitaryBase = 2;
  cpCreateScienceBase = 3;
  cpCreateBusinessCenter = 4;
  cpCreateMedicalBase = 5;
  cpRangersSubsidy = 6;
  cpPiratesSubsidy = 7;
  cpTransportSubsidy = 8;
  cpLostSubsidy = 9;
  cpWarSubsidy = 10;
  cpWarOperation = 11;
  tkMoneyDemand = 0;
  tkGoodsDemand = 1;
  tkTruceOffer = 2;
  tkAttack = 3;
  tkPartnerBreak = 4;
  tkPartnerEnd = 5;
  tkPartnerRiot = 6;
  atLiberation = 0;
  atAccomplishment = 1;
  atSecretMission = 2;
  atCowardice = 3;
  atPerfidy = 4;
  atPlanetBattle = 5;
  AwardNotFound = $FF;
type
  PointerToTGoodsTradePriceEntry = ^TGoodsTradePriceEntry;
  TGreetingCountMask = set of 0..15;
  {$Z1}
  TWeaponShotType = (
      wstNormal = 0,
      wstChain = 1,
      wstSplash = 2,
      wstExploder = 3,
      wstAreaDamage = 4,
      wstTorpedo = 5,
      wstMissile = 6,
      wstRocket = 7
  );
  TShipTypeMask = set of 0..15;
  TWeaponAvailabilityMask = set of 0..15;
  {$Z1}
  TWeaponAvailability = (
      waFree = 0,
      waCoalitionOnly = 1,
      waPirateOnly = 2,
      waNotSold = 3,
      waNotSoldAndNodeRepair = 4,
      waMalocOnly = 5,
      waPelengOnly = 6,
      waPeopleOnly = 7,
      waFeiOnly = 8,
      waGaalOnly = 9,
      waSystemOnly = 10
  );
  {$Z1}
  TStationType = (
      rstRangerCenter = 6,
      rstPirateBase = 7,
      rstMilitaryBase = 8,
      rstScienceBase = 9,
      rstBusinessCenter = 10,
      rstMedicalBase = 11,
      rstDominion = 12,
      rstCustomStation = 13
  );
  {$Z1}
  TKlingType = (
      ktBoss = 0,
      ktEquentor = 1,
      ktUrgant = 2,
      ktSmersh = 3,
      ktMenok = 4,
      ktShtip = 5,
      ktBertor = 6,
      ktKlig = 7
  );
  {$Z1}
  TRangerCareer = (rcTrader = 0, rcPirate = 1, rcWarrior = 2);
  TRangerCareerSet = set of TRangerCareer;
  TGalaxyDifficultyLevels = array[0..7] of Byte;
  {$Z1}
  TPlanetEconomy = (peAgricultural = 0, peMixed = 1, peIndustrial = 2);
  {$Z1}
  TPlanetGovernment =
      (pgAnarchy = 0, pgDictatorship = 1, pgMonarchy = 2, pgRepublic = 3, pgDemocracy = 4);
  {$Z1}
  TShopUpdateMode = (sumNormal = 0, sumDisabled = 1, sumEquipmentOnly = 2, sumGoodsOnly = 3);
  {$Z1}
  TStarFaction = (sfCoalition = 0, sfDominators = 1, sfPirates = 2);
  TGalaxyCustomRules = packed record
    Enabled: Boolean;
    DominatorStrength: Byte;
    DominatorAggression: Byte;
    DominatorSpawn: Byte;
    PirateAggression: Byte;
    CoalitionAggression: Byte;
    AsteroidModifier: Byte;
    SunDamageModifier: Byte;
    ExtraInventions: Byte;
    AcrynModifier: Byte;
    NodeDropModifier: Byte;
    ArcadeDropValueModifier: Byte;
    DropValueModifier: Byte;
    AgriculturalPlanetWeight: Byte;
    MixedPlanetWeight: Byte;
    IndustrialPlanetWeight: Byte;
    ExtraRangers: Byte;
    ArcadeHitpointsModifier: Byte;
    ArcadeDamageModifier: Byte;
    AIJunkTolerance: Byte;
    ChaoticRandom: Boolean;
    UnrestrictedEquipmentKnowledge: Boolean;
    StationsNearStars: Boolean;
    FullStationTargeting: Boolean;
    SpecialShips: Boolean;
    ZeroStartingExperience: Boolean;
    ArcadeBattleRoyale: Boolean;
    DominatorRacialWeapons: Boolean;
    StartInCenter: Boolean;
    MaxRangeMissiles: Boolean;
    OldHyperspace: Boolean;
    PirateNodes: Boolean;
    AIUseShops: Boolean;
    StationsUseShop: Boolean;
    DuplicateArtefacts: Boolean;
    HullGrowth: Byte;
    ArcadeEquipmentChange: Boolean;
    OldSpeedCalculation: Boolean;
    OldMissileBonuses: Boolean;
  end;
  TGoodsTradePriceEntry = packed record
    Count: Integer;
    PriceState: Single;
    PurchasePrice: Integer;
    BaseSalePrice: Integer;
  end;
  PGoodsTradePriceEntry = PointerToTGoodsTradePriceEntry;
  TGoodsTextOrder = array[0..7] of Byte;
  TEngineLevelStats = record
    Speed: Word;
    JumpRange: ShortInt;
    Gap3: array[0..0] of Byte;
  end;
  TEngineLevelStatsTable = array[1..8] of TEngineLevelStats;
  TCargoHookLevelStats = record
    PickupPower: Integer;
    Range: Integer;
    MinPullSpeed: Single;
    MaxPullSpeed: Single;
  end;
  TCargoHookLevelStatsTable = array[1..8] of TCargoHookLevelStats;
  {$Z1}
  TDamageKind = (dkEnergy = 0, dkSplinter = 1, dkMissile = 2, dkDroidBlock = 19);
  TDamageFlagSet = set of TDamageKind;
const
  dkDecelerate = TDamageKind(3);
  dkDestruct = TDamageKind(4);
  dkDrain = TDamageKind(5);
  dkShock = TDamageKind(6);
  dkAcid = TDamageKind(7);
  dkMagnetic = TDamageKind(8);
  dkDecelerateA = TDamageKind(9);
  dkDecelerateAEx = TDamageKind(10);
  dkUndefendable = TDamageKind(11);
  dkNonLethal = TDamageKind(12);
  dkScanBonus = TDamageKind(13);
  dkBonusToDamaged = TDamageKind(14);
  dkMoreDrop = TDamageKind(15);
  dkDropCargo = TDamageKind(16);
  dkReduceEngine = TDamageKind(17);
  dkBlockWeapon = TDamageKind(18);
  DamageNoDeltaMask = 1 shl 20;
  EmptyDamageFlags = [dkEnergy..dkDroidBlock] - [dkEnergy..dkDroidBlock];
type
  TItemTypeMask = set of 0..79;
  {$Z1}
  TOwnerId = (
      oiMaloc = 0,
      oiPeleng = 1,
      oiHuman = 2,
      oiFeyan = 3,
      oiGaal = 4,
      oiDominator = 5,
      oiUninhabited = 6,
      oiPirate = 7
  );
  TPlanetGoodsFactors = packed record
    PriceFactor: Double;
    StockFactor: Double;
  end;
  TPlanetRaceMarketInfo = packed record
    InventionProgressScale: Single;
    InitialInventionBoostCount: Integer;
    GoodsFactors: array[0..7] of TPlanetGoodsFactors;
    GovernmentRollThresholds: array[0..4] of Byte;
    Gap8D: array[0..2] of Byte;
    RevolutionChance: Single;
    FriendlyRelationScale: Single;
    PirateRelationFactor: Single;
    UnknownFactor9C: Single;
    PirateRelationCeiling: Byte;
    GapA1: array[0..6] of Byte;
  end;
  TPlanetRaceMarketTable = array[0..4] of TPlanetRaceMarketInfo;
  TPlanetEquipmentOfferQuotaRow = array[0..8] of Integer;
  TPlanetEquipmentOfferQuotaTable = array[0..4] of TPlanetEquipmentOfferQuotaRow;
  TPlanetOwnerMasks = packed record
    Coalition: Byte;
    Dominators: Byte;
    PirateClan: Byte;
  end;
  TOwnerMask = set of 0..7;
  TOwnerRelationRow = array[0..7] of Byte;
  TOwnerRelationTable = array[0..7] of TOwnerRelationRow;
  TFactionStandingMasks = array[0..2] of Word;
  {$Z1}
  TQuestType =
      (qtSendLetter = 0, qtKillShip = 1, qtPlanetQuest = 2, qtDefendSystem = 3, qtDefendShip = 4);
  TQuestTypes = set of TQuestType;
  TQuestTuning = packed record
    RewardCapitalPercent: Byte;
    Gap1: array[0..2] of Byte;
    BaseDuration: Integer;
    BaseRewardMoney: Integer;
  end;
  TQuestTuningTable = array[0..4] of TQuestTuning;
  TQuestExperienceTable = array[0..4] of Integer;
  {$Z1}
  TRelationLevel = (rlHostile = 0, rlBad = 1, rlNormal = 2, rlGood = 3, rlExcellent = 4);
  TGalaxyDifficultyTuning = packed record
    GoodsEventDurationFactor: Single;
    QuestTimeAndExperienceFactor: Single;
    EquipmentWearFactor: Single;
    InventionProgressScale: Single;
    ArcadeRewardScale: Single;
    QuestMoneyFactor: Single;
    DifficultyValue18: Integer;
    DifficultyValue1C: Byte;
    Gap1D: array[0..2] of Byte;
    MarketPriceBandSqueeze: Single;
    RandomHoleSpawnRollMaximum: Integer;
    MaximumDominatorResearchRate: Single;
    MaximumResearchMaterialConsumption: Byte;
    MaximumQuestProgramRewardCount: Byte;
    Gap2E: array[0..1] of Byte;
    ArcadeDamageTakenScale: Single;
    DifficultyFactor34: Single;
  end;
  TGalaxyDifficultyTuningTable = array[0..9] of TGalaxyDifficultyTuning;
  {$Z1}
  TDominatorSeries = (dsBlazer = 0, dsKeller = 1, dsTerron = 2);
  TFactionStrengthValues = array[0..2] of Single;
  TStarStatus = record
    ThreatLevel: Byte;
    TrafficLevel: Byte;
    ControlFaction: TStarFaction;
    Gap3: array[0..0] of Byte;
    CustomFaction: WideString;
    Battle: Byte;
    DominatorSeries: TDominatorSeries;
    PreviousControlFaction: TStarFaction;
    GapB: array[0..0] of Byte;
    CachedFactionStrength: TFactionStrengthValues;
    FactionStrengthCacheTurn: Integer;
  end;
  TPlanetNews = packed record
    Id: Cardinal;
    Turn: Integer;
    NewsType: Byte;
    Gap9: array[0..2] of Byte;
    Text: WideString;
  end;
implementation
end.
