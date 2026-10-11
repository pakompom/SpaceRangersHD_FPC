unit aConst;

{$I GameOptions.inc}

interface

uses
  Types,
  aGalaxyStruct;

type

  TOwnerWeaponAvailabilityTable = array[TOwnerId] of TWeaponAvailability;

  {$Z1}
  TEquipmentBonusKind = (
      bonHull = 0,
      bonFuel = 1,
      bonSpeed = 2,
      bonJump = 3,
      bonRadar = 4,
      bonScan = 5,
      bonDroid = 6,
      bonHook = 7,
      bonDef = 8,
      bonWEnergy = 9,
      bonWSplinter = 10,
      bonWMissile = 11,
      bonWRadius = 12,
      bonSlotRadar = 13,
      bonSlotScaner = 14,
      bonSlotDroid = 15,
      bonSlotHook = 16,
      bonSlotDef = 17,
      bonSlotWeapon = 18,
      bonSlotArt = 19,
      bonSlotForsage = 20,
      bonHookRadius = 21,
      bonSkill1 = 22,
      bonSkill2 = 23,
      bonSkill3 = 24,
      bonSkill4 = 25,
      bonSkill5 = 26,
      bonSkill6 = 27,
      bonMass = 28,
      bonExtraAkrinEff = 29,
      bonExtraAkrinPenalty = 30,
      bonAmmo = 31,
      bonShots = 32,
      bonMissileSpeed = 33,
      bonShotSpeed = 34,
      bonHookMaxSpeed = 35,
      bonHookMinSpeed = 36,
      bonStimCapacity = 37,
      bonZonds = 38,
      bonAttacks = 39,
      bonResistAsteroid = 40,
      bonAIValue = 41,
      bonNull = 42
  );

  TEquipmentBonuses = array[TEquipmentBonusKind] of Integer;

  {$Z1}
  TShipSlotKind = (
      sskFuelTanks = 0,
      sskEngine = 1,
      sskRadar = 2,
      sskScanner = 3,
      sskRepairRobot = 4,
      sskCargoHook = 5,
      sskDefGenerator = 6,
      sskWeapon = 7,
      sskArtefact = 8,
      sskAfterburner = 9,
      sskUnsupported = 10
  );

  TEquipmentSizeFactorTable = array[1..5] of Single;

  TStationEquipmentOfferQuota = packed record
    Hulls: Integer;
    FuelTanks: Integer;
    Engines: Integer;
    Radars: Integer;
    Scanners: Integer;
    RepairRobots: Integer;
    CargoHooks: Integer;
    DefGenerators: Integer;
    Weapons: Integer;
  end;

  TStationEquipmentOfferQuotaTable = array[TStationType] of TStationEquipmentOfferQuota;

  TWeaponRangeLevelFactors = array[1..8] of Single;

  TItemTypeSelection = set of 0..79;

  TGoodsLegalityTable =
      array[TGoodsIndex] of array[oiMaloc..oiGaal] of array[TPlanetGovernment] of Boolean;

  TProgramDurationTable = array[TProgramIndex] of Integer;

  {$Z1}
  TWeaponDamageClass = (wdcEnergy = 0, wdcSplinter = 1, wdcMissile = 2);

  THullLevelStats = record
    Armor: Byte;
    Fragility: array[TWeaponDamageClass] of Single;
  end;

  THullLevelStatsTable = array[1..8] of THullLevelStats;

  THullShipTypeMask = set of THullType;

var

  IntegrityDataBegin: Cardinal = 0;

  CurrentSaveVersion: Integer = 167;

  MinimumLoadableSaveVersion: Integer = 44;

  LocalizedTextLinePrefix: WideString = '    ';

type

  // Internal tables use native pointer alignment; they are not serialized as records.
  TEconomyInfo = record
    InternalName: WideString;
    DisplayName: WideString;
    ShortDisplayName: WideString;
    InventionProgressScale: Single;
  end;

  TRelationTypeInfo = record
    InternalName: WideString;
    DisplayName: WideString;
    MinimumValue: Integer;
  end;

var

  GalaxyStarCount: Integer = 73;

  GalaxySizeY: Integer = 100;

  GalaxySizeX: Integer = 145;

const

  MaximumNewGameDifficulty: Byte = 9;

var

  GalaxyDifficultyTuning: TGalaxyDifficultyTuningTable = (
      (
          GoodsEventDurationFactor: 0.7;
          QuestTimeAndExperienceFactor: 0.85;
          EquipmentWearFactor: 0.75;
          InventionProgressScale: 1.1;
          ArcadeRewardScale: 1.3;
          QuestMoneyFactor: 1.2;
          StartingPlayerMoney: 4000;
          InitialPirateControlPercent: 8;
          MarketPriceBandSqueeze: -0.2;
          RandomHoleSpawnRollMaximum: 80;
          MaximumDominatorResearchRate: 0.05;
          MaximumResearchMaterialConsumption: 2;
          MaximumQuestProgramRewardCount: 4;
          ArcadeDamageTakenScale: 0.9;
          CoalitionToPirateBalanceRatio: 10.0
      ),
      (
          GoodsEventDurationFactor: 1.0;
          QuestTimeAndExperienceFactor: 1.0;
          EquipmentWearFactor: 1.0;
          InventionProgressScale: 1.0;
          ArcadeRewardScale: 1.0;
          QuestMoneyFactor: 1.0;
          StartingPlayerMoney: 1300;
          InitialPirateControlPercent: 12;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 100;
          MaximumDominatorResearchRate: 0.04;
          MaximumResearchMaterialConsumption: 4;
          MaximumQuestProgramRewardCount: 3;
          ArcadeDamageTakenScale: 1.0;
          CoalitionToPirateBalanceRatio: 5.0
      ),
      (
          GoodsEventDurationFactor: 1.2;
          QuestTimeAndExperienceFactor: 1.15;
          EquipmentWearFactor: 1.3;
          InventionProgressScale: 0.9;
          ArcadeRewardScale: 0.6;
          QuestMoneyFactor: 0.7;
          StartingPlayerMoney: 800;
          InitialPirateControlPercent: 16;
          MarketPriceBandSqueeze: 0.1;
          RandomHoleSpawnRollMaximum: 130;
          MaximumDominatorResearchRate: 0.03;
          MaximumResearchMaterialConsumption: 5;
          MaximumQuestProgramRewardCount: 2;
          ArcadeDamageTakenScale: 1.7;
          CoalitionToPirateBalanceRatio: 2.5
      ),
      (
          GoodsEventDurationFactor: 1.5;
          QuestTimeAndExperienceFactor: 1.3;
          EquipmentWearFactor: 1.6;
          InventionProgressScale: 0.8;
          ArcadeRewardScale: 0.3;
          QuestMoneyFactor: 0.5;
          StartingPlayerMoney: 400;
          InitialPirateControlPercent: 20;
          MarketPriceBandSqueeze: 0.15;
          RandomHoleSpawnRollMaximum: 170;
          MaximumDominatorResearchRate: 0.02;
          MaximumResearchMaterialConsumption: 6;
          MaximumQuestProgramRewardCount: 2;
          ArcadeDamageTakenScale: 2.3;
          CoalitionToPirateBalanceRatio: 1.8
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      ),
      (
          GoodsEventDurationFactor: 0.0;
          QuestTimeAndExperienceFactor: 0.0;
          EquipmentWearFactor: 0.0;
          InventionProgressScale: 0.0;
          ArcadeRewardScale: 0.0;
          QuestMoneyFactor: 0.0;
          StartingPlayerMoney: 0;
          InitialPirateControlPercent: 0;
          MarketPriceBandSqueeze: 0.0;
          RandomHoleSpawnRollMaximum: 0;
          MaximumDominatorResearchRate: 0.0;
          MaximumResearchMaterialConsumption: 0;
          MaximumQuestProgramRewardCount: 0;
          ArcadeDamageTakenScale: 0.0;
          CoalitionToPirateBalanceRatio: 0.0
      )
  );

  RelationInfo: array[TRelationLevel] of TRelationTypeInfo = (
      (InternalName: 'War'; DisplayName: ''; MinimumValue: 0),
      (InternalName: 'Bad'; DisplayName: ''; MinimumValue: 10),
      (InternalName: 'Normal'; DisplayName: ''; MinimumValue: 30),
      (InternalName: 'Good'; DisplayName: ''; MinimumValue: 60),
      (InternalName: 'Best'; DisplayName: ''; MinimumValue: 80)
  );

  PlanetEconomyInfo: array[TPlanetEconomy] of TEconomyInfo = (
      (
          InternalName: 'Agriculture';
          DisplayName: '';
          ShortDisplayName: '';
          InventionProgressScale: 0.7
      ),
      (InternalName: 'Mixed'; DisplayName: ''; ShortDisplayName: ''; InventionProgressScale: 1.0),
      (
          InternalName: 'Industrial';
          DisplayName: '';
          ShortDisplayName: '';
          InventionProgressScale: 1.4
      )
  );

type

  TShipTypeInfo = record
    Name: WideString;
  end;

var

  ShipTypeNames: array[TShipType] of TShipTypeInfo = (
      (Name: 'Kling'),
      (Name: 'Ranger'),
      (Name: 'Transport'),
      (Name: 'Pirate'),
      (Name: 'Warrior'),
      (Name: 'Tranclucator'),
      (Name: 'RC'),
      (Name: 'PB'),
      (Name: 'WB'),
      (Name: 'SB'),
      (Name: 'BK'),
      (Name: 'MC'),
      (Name: 'CB'),
      (Name: 'UB')
  );

type

  TStatusInfo = record
    Name: WideString;
    MinimumWealthToAverageRatio: Double;
    MinimumWealthToBestRatio: Double;
    MinimumStrengthToAverageRatio: Double;
    MinimumStrengthToBestRatio: Double;
  end;

var

  StationDefaultStandings: array[TStationType] of TShipStanding = (
      ssCoalitionMilitary,
      ssPiratePassive,
      ssCoalitionMilitary,
      ssCoalitionActive,
      ssCoalitionActive,
      ssNeutral,
      ssPirateMilitary,
      ssUnaligned
  );

  NonTargetableStationStandingMasks: TFactionStandingMasks =
      ([ssCoalitionMilitary..ssNeutral], [ssDominator], [ssPiratePassive..ssPirateMilitary]);

  FactionStandingMasks: TFactionStandingMasks = (
      [ssCoalitionMilitary..ssPiratePassive],
      [ssDominator],
      [ssCoalitionPassive..ssPirateMilitary]
  );

  CareerTuning: array[TRangerCareer] of TStatusInfo = (
      (
          Name: 'Trader';
          MinimumWealthToAverageRatio: 1.5;
          MinimumWealthToBestRatio: 0.4;
          MinimumStrengthToAverageRatio: 0.9;
          MinimumStrengthToBestRatio: 0.3
      ),
      (
          Name: 'Pirate';
          MinimumWealthToAverageRatio: 0.9;
          MinimumWealthToBestRatio: 0.35;
          MinimumStrengthToAverageRatio: 1.1;
          MinimumStrengthToBestRatio: 0.5
      ),
      (
          Name: 'Warrior';
          MinimumWealthToAverageRatio: 0.8;
          MinimumWealthToBestRatio: 0.25;
          MinimumStrengthToAverageRatio: 1.2;
          MinimumStrengthToBestRatio: 0.6
      )
  );

  TransportTypeNames: array[0..2] of WideString = ('Transport', 'Liner', 'Diplomat');

type

  TKlingTypeInfo = record
    DisplayNames: array[TDominatorSeries] of WideString;
    MinimumHullSize: Integer;
    MaximumHullSize: Integer;
    InitialWealthScale: Double;
    BaseNodeReserve: Word;
    KillExperience: Word;
    RankPoints: Word;
    PirateRankPoints: Word;
    RankImageIndex: Integer;
    FactionStrengthWeight: Double;
  end;

  TDominatorDisplayIndex = 0..7;

const

  DominatorDisplayOrder: array[TDominatorDisplayIndex] of TKlingType =
      (ktBoss, ktBertor, ktEquantor, ktUrgant, ktSmersh, ktMenoc, ktShtip, ktKlig);

var

  DominatorShipTypeKeys: array[TKlingType] of WideString =
      ('K0', 'K1', 'K2', 'K3', 'K4', 'K5', 'K6', 'K7');

  DominatorShipDefinitions: array[TKlingType] of TKlingTypeInfo = (
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 0;
          MaximumHullSize: 0;
          InitialWealthScale: 10;
          BaseNodeReserve: 500;
          KillExperience: 5000;
          RankPoints: 250;
          PirateRankPoints: 0;
          RankImageIndex: 7;
          FactionStrengthWeight: 10
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 900;
          MaximumHullSize: 1400;
          InitialWealthScale: 0.7;
          BaseNodeReserve: 100;
          KillExperience: 1000;
          RankPoints: 48;
          PirateRankPoints: 16;
          RankImageIndex: 5;
          FactionStrengthWeight: 5
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 700;
          MaximumHullSize: 900;
          InitialWealthScale: 0.6;
          BaseNodeReserve: 50;
          KillExperience: 500;
          RankPoints: 24;
          PirateRankPoints: 8;
          RankImageIndex: 4;
          FactionStrengthWeight: 3.5
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 500;
          MaximumHullSize: 700;
          InitialWealthScale: 0.5;
          BaseNodeReserve: 30;
          KillExperience: 300;
          RankPoints: 12;
          PirateRankPoints: 4;
          RankImageIndex: 3;
          FactionStrengthWeight: 2
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 350;
          MaximumHullSize: 500;
          InitialWealthScale: 0.3;
          BaseNodeReserve: 15;
          KillExperience: 150;
          RankPoints: 6;
          PirateRankPoints: 2;
          RankImageIndex: 2;
          FactionStrengthWeight: 1
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 250;
          MaximumHullSize: 350;
          InitialWealthScale: 0.2;
          BaseNodeReserve: 10;
          KillExperience: 100;
          RankPoints: 3;
          PirateRankPoints: 1;
          RankImageIndex: 1;
          FactionStrengthWeight: 1
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 1250;
          MaximumHullSize: 2000;
          InitialWealthScale: 2;
          BaseNodeReserve: 200;
          KillExperience: 2000;
          RankPoints: 60;
          PirateRankPoints: 24;
          RankImageIndex: 7;
          FactionStrengthWeight: 7.5
      ),
      (
          DisplayNames: ('Blazer', 'Keller', 'Terron');
          MinimumHullSize: 150;
          MaximumHullSize: 250;
          InitialWealthScale: 0.15;
          BaseNodeReserve: 5;
          KillExperience: 50;
          RankPoints: 1;
          PirateRankPoints: 1;
          RankImageIndex: 1;
          FactionStrengthWeight: 0
      )
  );

  DominatorRetreatStrengthByTier: array[0..3] of Double = (2, 2.2, 2.6, 3);

  DominatorSeriesNames: array[TDominatorSeries] of WideString = ('Blazer', 'Keller', 'Terron');

  DominatorResearchRateMultipliers: array[TDominatorSeries] of Double = (1.0, 1.2, 0.8);

  ResearchProgramCostFactors: array[TDominatorSeries] of Double = (1, 1.4, 1.8);

  ScriptActionTypeNames: array[TScriptActionType] of WideString = (
      't_OnStep',
      't_OnWeaponShot',
      't_OnMissileShot',
      't_OnDealingDamage',
      't_OnDealingFatalDamage',
      't_OnDealingKamikazeDamage',
      't_OnTakingDamage',
      't_OnTakingDamageEn',
      't_OnTakingDamageSp',
      't_OnTakingDamageMi',
      't_OnWeaponShot2',
      't_OnMissileShot2',
      't_OnGettingWeaponHit',
      't_OnGettingMissileHit',
      't_OnDroidRepair',
      't_OnItemPickUp',
      't_OnScan',
      't_OnChameleonConfusion',
      't_OnScanPossibility',
      't_OnAnotherItem',
      't_OnAnotherItem2',
      't_OnAnotherGoods',
      't_OnItemHit',
      't_OnMissileHittingObject',
      't_OnEnteringForm',
      't_OnLeavingForm',
      't_OnReEnteringForm',
      't_OnEnteringOtherShip',
      't_OnLeavingOtherShip',
      't_OnReEnteringOtherShip',
      't_OnPlayerSkillIncrease',
      't_OnPlayerTalkedWithShip',
      't_OnShipTalkedWithPlayer',
      't_OnDropItem',
      't_OnDropItemFixed',
      't_OnMovingItemToStorage',
      't_OnReduceEqBattle',
      't_OnReduceEqUse',
      't_OnReduceEqForce',
      't_OnReduceEqForsage',
      't_OnItemDestroy',
      't_OnPlayerChangeHull',
      't_OnPlayerUseMM',
      't_OnPlayerBuyEq',
      't_OnItemEquip',
      't_OnItemDeEquip',
      't_OnTrancPacking',
      't_OnShipBuysGoods',
      't_OnShipSellsGoods',
      't_OnShowingItemInfo',
      't_OnShowingShipInfo',
      't_OnShowingStarInfo',
      't_OnNonStandartEqChange',
      't_OnCustomTargetting',
      't_OnCustomTargettingCheck',
      't_OnStartAB',
      't_OnABItemDrop',
      't_OnGovItemReward',
      't_OnCheckingUsability',
      't_OnCheckingUsability2',
      't_OnCheckingUsabilityGoods',
      't_OnDeath'
  );

type

  {$Z1}
  TItemType = (
      t_Food = 0,
      t_Medicine = 1,
      t_Technics = 2,
      t_Luxury = 3,
      t_Minerals = 4,
      t_Alcohol = 5,
      t_Arms = 6,
      t_Narcotics = 7,
      t_Artefact = 8,
      t_Artefact2 = 9,
      t_ArtefactHull = 10,
      t_ArtefactFuel = 11,
      t_ArtefactSpeed = 12,
      t_ArtefactPower = 13,
      t_ArtefactRadar = 14,
      t_ArtefactScaner = 15,
      t_ArtefactDroid = 16,
      t_ArtefactNano = 17,
      t_ArtefactHook = 18,
      t_ArtefactDef = 19,
      t_ArtefactAnalyzer = 20,
      t_ArtefactMiniExpl = 21,
      t_ArtefactAntigrav = 22,
      t_ArtefactTransmitter = 23,
      t_ArtefactBomb = 24,
      t_ArtefactTranclucator = 25,
      t_ArtDefToEnergy = 26,
      t_ArtEnergyPulse = 27,
      t_ArtEnergyDef = 28,
      t_ArtSplinter = 29,
      t_ArtDecelerate = 30,
      t_ArtMissileDef = 31,
      t_ArtForsage = 32,
      t_ArtWeaponToSpeed = 33,
      t_ArtGiperJump = 34,
      t_ArtBlackHole = 35,
      t_ArtDefToArms1 = 36,
      t_ArtDefToArms2 = 37,
      t_ArtArtefactor = 38,
      t_ArtBio = 39,
      t_ArtPDTurret = 40,
      t_ArtFastRacks = 41,
      t_Hull = 42,
      t_FuelTanks = 43,
      t_Engine = 44,
      t_Radar = 45,
      t_Scaner = 46,
      t_RepairRobot = 47,
      t_CargoHook = 48,
      t_DefGenerator = 49,
      t_Weapon1 = 50,
      t_Weapon2 = 51,
      t_Weapon3 = 52,
      t_Weapon4 = 53,
      t_Weapon5 = 54,
      t_Weapon6 = 55,
      t_Weapon7 = 56,
      t_Weapon8 = 57,
      t_Weapon9 = 58,
      t_Weapon10 = 59,
      t_Weapon11 = 60,
      t_Weapon12 = 61,
      t_Weapon13 = 62,
      t_Weapon14 = 63,
      t_Weapon15 = 64,
      t_Weapon16 = 65,
      t_Weapon17 = 66,
      t_Weapon18 = 67,
      t_CustomWeapon = 68,
      t_Protoplasm = 69,
      t_UselessItem = 70,
      t_MicroModule = 71,
      t_Cistern = 72,
      t_Satellite = 73,
      t_TreasureMap = 74,
      t_UselessCountableItem = 75
  );

const

  t_IndustrialLaser = t_Weapon1;

  t_FragmentationCannon = t_Weapon2;

  t_Flux = t_Weapon3;

  t_MissileLauncher = t_Weapon4;

  t_Treton = t_Weapon5;

  t_WavePhaser = t_Weapon6;

  t_FlowBlaster = t_Weapon7;

  t_ElectronicCutter = t_Weapon8;

  t_Multiresonator = t_Weapon9;

  t_AtomicVision = t_Weapon10;

  t_Disintegrator = t_Weapon11;

  t_Turbogravitron = t_Weapon12;

  t_IMHO9000 = t_Weapon13;

  t_Vertix = t_Weapon14;

  t_TorpedoTube = t_Weapon15;

  t_Esodapher = t_Weapon16;

  t_Caphasitor = t_Weapon17;

  t_Lirecron = t_Weapon18;

  WeaponCategoryItemType = t_IndustrialLaser;

type

  TEquipmentInventionIndexTable = array[t_Hull..t_DefGenerator] of TPlanetInvention;

  SEquipment = record
    ItemType: TItemType;
    Name: WideString;
  end;

  TPlanetEquipmentOfferQuotaRow = array[t_Hull..WeaponCategoryItemType] of Integer;

  TPlanetEquipmentOfferQuotaTable = array[oiMaloc..oiGaal] of TPlanetEquipmentOfferQuotaRow;

var

  NonNegotiatingShipTypes: TShipTypeMask = [stKling, stTranclucator..rstCustomStation];

const

  EquipmentSlotLayouts: array[0..7] of SEquipment = (
      (ItemType: t_FuelTanks; Name: 'FuelTanks'),
      (ItemType: t_Engine; Name: 'Engine'),
      (ItemType: t_Radar; Name: 'Radar'),
      (ItemType: t_Scaner; Name: 'Scaner'),
      (ItemType: t_RepairRobot; Name: 'RepairRobot'),
      (ItemType: t_CargoHook; Name: 'CargoHook'),
      (ItemType: t_DefGenerator; Name: 'DefGenerator'),
      (ItemType: WeaponCategoryItemType; Name: 'Weapon')
  );

var

  ItemTypeNames: array[TItemType] of WideString = (
      'Food',
      'Medicine',
      'Technics',
      'Luxury',
      'Minerals',
      'Alcohol',
      'Arms',
      'Narcotics',
      'Artefact',
      'Artefact2',
      'ArtHull',
      'ArtFuel',
      'ArtSpeed',
      'ArtPower',
      'ArtRadar',
      'ArtScaner',
      'ArtDroid',
      'ArtNano',
      'ArtHook',
      'ArtDef',
      'ArtAnalyzer',
      'ArtMiniExpl',
      'ArtAntigrav',
      'ArtTransmitter',
      'ArtBomb',
      'ArtTranclucator',
      'ArtDefToEnergy',
      'ArtEnergyPulse',
      'ArtEnergyDef',
      'ArtSplinter',
      'ArtDecelerate',
      'ArtMissileDef',
      'ArtForsage',
      'ArtWeaponToSpeed',
      'ArtGiperJump',
      'ArtBlackHole',
      'ArtDefToArms1',
      'ArtDefToArms2',
      'ArtArtefactor',
      'ArtBio',
      'ArtPDTurret',
      'ArtFastRacks',
      'Hull',
      'FuelTanks',
      'Engine',
      'Radar',
      'Scaner',
      'RepairRobot',
      'CargoHook',
      'DefGenerator',
      'W01',
      'W02',
      'W03',
      'W04',
      'W05',
      'W06',
      'W07',
      'W08',
      'W09',
      'W10',
      'W11',
      'W12',
      'W13',
      'W14',
      'W15',
      'W16',
      'W17',
      'W18',
      'CustomWeapon',
      'Protoplasm',
      'UselessItem',
      'Nod',
      'Cistern',
      'Satellite',
      'TreasureMap',
      'UselessCountableItem'
  );

  ArtefactLootPools: array[0..3] of array of TItemType;

  CustomArtefactLootPools: array[0..3] of array of WideString;

  UselessItemLootPools: array[0..3] of array of WideString;

type

  TGoodsInfo = record
    InternalName: WideString;
    DisplayName: WideString;
    TradeName: WideString;
    BaseStock: Integer;
    MinPrice: Integer;
    AveragePrice: Integer;
    MaxPrice: Integer;
    TradeExperienceFactor: Single;
    EconomyFactors: array[TPlanetEconomy] of Single;
    PirateEconomyFactor: Single;
  end;

var

  GoodsMarket: array[TGoodsIndex] of TGoodsInfo = (
      (
          InternalName: 'Food';
          DisplayName: '';
          TradeName: '';
          BaseStock: 300;
          MinPrice: 17;
          AveragePrice: 30;
          MaxPrice: 43;
          TradeExperienceFactor: 1.654;
          EconomyFactors: (1.15, 1.0, 0.85);
          PirateEconomyFactor: 0.9
      ),
      (
          InternalName: 'Medicine';
          DisplayName: '';
          TradeName: '';
          BaseStock: 160;
          MinPrice: 27;
          AveragePrice: 40;
          MaxPrice: 53;
          TradeExperienceFactor: 2.038;
          EconomyFactors: (1.1, 1.0, 0.9);
          PirateEconomyFactor: 0.7
      ),
      (
          InternalName: 'Technics';
          DisplayName: '';
          TradeName: '';
          BaseStock: 100;
          MinPrice: 62;
          AveragePrice: 80;
          MaxPrice: 98;
          TradeExperienceFactor: 2.722;
          EconomyFactors: (0.85, 1.0, 1.15);
          PirateEconomyFactor: 0.8
      ),
      (
          InternalName: 'Luxury';
          DisplayName: '';
          TradeName: '';
          BaseStock: 60;
          MinPrice: 160;
          AveragePrice: 200;
          MaxPrice: 240;
          TradeExperienceFactor: 3.0;
          EconomyFactors: (1.0, 1.1, 1.05);
          PirateEconomyFactor: 0.8
      ),
      (
          InternalName: 'Minerals';
          DisplayName: '';
          TradeName: '';
          BaseStock: 250;
          MinPrice: 8;
          AveragePrice: 12;
          MaxPrice: 16;
          TradeExperienceFactor: 2.0;
          EconomyFactors: (1.15, 1.0, 0.85);
          PirateEconomyFactor: 2.5
      ),
      (
          InternalName: 'Alcohol';
          DisplayName: '';
          TradeName: '';
          BaseStock: 120;
          MinPrice: 25;
          AveragePrice: 40;
          MaxPrice: 55;
          TradeExperienceFactor: 1.833;
          EconomyFactors: (1.2, 1.0, 0.8);
          PirateEconomyFactor: 1.3
      ),
      (
          InternalName: 'Arms';
          DisplayName: '';
          TradeName: '';
          BaseStock: 70;
          MinPrice: 75;
          AveragePrice: 100;
          MaxPrice: 125;
          TradeExperienceFactor: 2.5;
          EconomyFactors: (0.85, 1.0, 1.15);
          PirateEconomyFactor: 1.5
      ),
      (
          InternalName: 'Narcotics';
          DisplayName: '';
          TradeName: '';
          BaseStock: 30;
          MinPrice: 250;
          AveragePrice: 400;
          MaxPrice: 550;
          TradeExperienceFactor: 1.833;
          EconomyFactors: (1.1, 1.0, 0.9);
          PirateEconomyFactor: 2.0
      )
  );

  GoodsTextOrder: TGoodsTextOrder = (0, 1, 5, 4, 3, 2, 6, 7);

  MissionTypeNames: array[0..4] of WideString =
      ('SendLetter', 'KillShip', 'PlanetQuest', 'DefSystem', 'DefShip');

type

  TOwnerInfo = record
    InternalName: WideString;
    DisplayName: WideString;
    FuelPriceFactor: Single;
    EquipmentDurabilityFactor: Single;
    MinimumAfterburnerWear: Integer;
    MaximumAfterburnerWear: Integer;
    FearThresholdScale: Single;
    ColorTag: WideString;
  end;

  TGovermentInfo = record
    InternalName: WideString;
    DisplayName: WideString;
    RevolutionRelationDelta: array[TRangerCareer] of ShortInt;
    QuestOfferProbabilities: array[TQuestType] of Single;
    GoodsFactors: array[TGoodsIndex] of TPlanetGoodsFactors;
  end;

var

  OwnerInfo: array[TOwnerId] of TOwnerInfo = (
      (
          InternalName: 'Maloc';
          DisplayName: '';
          FuelPriceFactor: 0.7;
          EquipmentDurabilityFactor: 0.7;
          MinimumAfterburnerWear: 18;
          MaximumAfterburnerWear: 22;
          FearThresholdScale: 0.8;
          ColorTag: '<color=255,000,000>'
      ),
      (
          InternalName: 'Peleng';
          DisplayName: '';
          FuelPriceFactor: 0.9;
          EquipmentDurabilityFactor: 0.9;
          MinimumAfterburnerWear: 17;
          MaximumAfterburnerWear: 21;
          FearThresholdScale: 0.9;
          ColorTag: '<color=000,255,000>'
      ),
      (
          InternalName: 'People';
          DisplayName: '';
          FuelPriceFactor: 1.0;
          EquipmentDurabilityFactor: 1.0;
          MinimumAfterburnerWear: 16;
          MaximumAfterburnerWear: 20;
          FearThresholdScale: 1.0;
          ColorTag: '<color=000,148,255>'
      ),
      (
          InternalName: 'Fei';
          DisplayName: '';
          FuelPriceFactor: 1.15;
          EquipmentDurabilityFactor: 1.15;
          MinimumAfterburnerWear: 14;
          MaximumAfterburnerWear: 17;
          FearThresholdScale: 1.3;
          ColorTag: '<color=255,147,241>'
      ),
      (
          InternalName: 'Gaal';
          DisplayName: '';
          FuelPriceFactor: 1.3;
          EquipmentDurabilityFactor: 1.3;
          MinimumAfterburnerWear: 14;
          MaximumAfterburnerWear: 16;
          FearThresholdScale: 1.2;
          ColorTag: '<color=237,247,062>'
      ),
      (
          InternalName: 'Kling';
          DisplayName: '';
          FuelPriceFactor: 1.0;
          EquipmentDurabilityFactor: 1.0;
          MinimumAfterburnerWear: 10;
          MaximumAfterburnerWear: 20;
          FearThresholdScale: 1.0;
          ColorTag: '<color=097,167,190>'
      ),
      (
          InternalName: 'None';
          DisplayName: '';
          FuelPriceFactor: 1.0;
          EquipmentDurabilityFactor: 1.0;
          MinimumAfterburnerWear: 14;
          MaximumAfterburnerWear: 20;
          FearThresholdScale: 1.0;
          ColorTag: '<color=255,000,255>'
      ),
      (
          InternalName: 'PirateClan';
          DisplayName: '';
          FuelPriceFactor: 0.8;
          EquipmentDurabilityFactor: 1.0;
          MinimumAfterburnerWear: 16;
          MaximumAfterburnerWear: 20;
          FearThresholdScale: 0.5;
          ColorTag: '<color=255,255,255>'
      )
  );

  PlanetOwnerMasks: TPlanetOwnerMasks =
      (Coalition: [oiMaloc..oiGaal]; Dominators: [oiDominator]; PirateClan: [oiPirate]);

  OwnerRelations: TOwnerRelationTable = (
      (100, 80, 70, 40, 60, 0, 0, 30),
      (70, 100, 70, 30, 40, 0, 0, 30),
      (50, 40, 100, 70, 90, 0, 0, 30),
      (40, 30, 80, 100, 70, 0, 0, 30),
      (70, 70, 80, 90, 100, 0, 0, 30),
      (0, 0, 0, 0, 0, 100, 0, 0),
      (0, 0, 0, 0, 0, 0, 100, 0),
      (50, 50, 50, 50, 50, 0, 0, 100)
  );

  PlanetRaceMarket: TPlanetRaceMarketTable = (
      (
          InventionProgressScale: 0.85;
          InitialInventionBoostCount: 5;
          GoodsFactors: (
              (PriceFactor: 0.85; StockFactor: 1.1),
              (PriceFactor: 1.1; StockFactor: 1.1),
              (PriceFactor: 1.15; StockFactor: 0.5),
              (PriceFactor: 0.85; StockFactor: 0.4),
              (PriceFactor: 0.87; StockFactor: 0.7),
              (PriceFactor: 1.1; StockFactor: 0.1),
              (PriceFactor: 1.2; StockFactor: 0.5),
              (PriceFactor: 0.8; StockFactor: 0.2)
          );
          GovernmentRollThresholds: (10, 30, 50, 90, 95);
          RevolutionChance: 0.002;
          FriendlyRelationScale: 0.7;
          PirateRelationFactor: 1.1;
          UnknownFactor9C: 1.5;
          PirateRelationCeiling: 60
      ),
      (
          InventionProgressScale: 0.95;
          InitialInventionBoostCount: 6;
          GoodsFactors: (
              (PriceFactor: 0.95; StockFactor: 1.2),
              (PriceFactor: 1.05; StockFactor: 1.0),
              (PriceFactor: 1.07; StockFactor: 0.9),
              (PriceFactor: 1.15; StockFactor: 1.2),
              (PriceFactor: 0.95; StockFactor: 0.8),
              (PriceFactor: 1.05; StockFactor: 1.1),
              (PriceFactor: 1.1; StockFactor: 0.8),
              (PriceFactor: 0.95; StockFactor: 0.6)
          );
          GovernmentRollThresholds: (20, 40, 70, 85, 90);
          RevolutionChance: 0.006;
          FriendlyRelationScale: 1.1;
          PirateRelationFactor: 1.5;
          UnknownFactor9C: 0.8;
          PirateRelationCeiling: 80
      ),
      (
          InventionProgressScale: 1.0;
          InitialInventionBoostCount: 7;
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.5),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0)
          );
          GovernmentRollThresholds: (10, 30, 40, 60, 80);
          RevolutionChance: 0.004;
          FriendlyRelationScale: 1.0;
          PirateRelationFactor: 0.9;
          UnknownFactor9C: 1.2;
          PirateRelationCeiling: 45
      ),
      (
          InventionProgressScale: 1.1;
          InitialInventionBoostCount: 8;
          GoodsFactors: (
              (PriceFactor: 1.05; StockFactor: 0.7),
              (PriceFactor: 0.85; StockFactor: 0.9),
              (PriceFactor: 0.87; StockFactor: 1.4),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.15; StockFactor: 0.5),
              (PriceFactor: 1.15; StockFactor: 0.4),
              (PriceFactor: 0.9; StockFactor: 0.4),
              (PriceFactor: 1.1; StockFactor: 0.5)
          );
          GovernmentRollThresholds: (5, 10, 15, 30, 70);
          RevolutionChance: 0.003;
          FriendlyRelationScale: 1.1;
          PirateRelationFactor: 0.7;
          UnknownFactor9C: 1.0;
          PirateRelationCeiling: 35
      ),
      (
          InventionProgressScale: 1.15;
          InitialInventionBoostCount: 9;
          GoodsFactors: (
              (PriceFactor: 1.1; StockFactor: 0.5),
              (PriceFactor: 0.8; StockFactor: 0.5),
              (PriceFactor: 0.8; StockFactor: 0.8),
              (PriceFactor: 0.85; StockFactor: 0.5),
              (PriceFactor: 1.1; StockFactor: 0.3),
              (PriceFactor: 0.9; StockFactor: 0.3),
              (PriceFactor: 0.84; StockFactor: 0.1),
              (PriceFactor: 1.15; StockFactor: 0.4)
          );
          GovernmentRollThresholds: (5, 8, 10, 30, 60);
          RevolutionChance: 0.002;
          FriendlyRelationScale: 1.3;
          PirateRelationFactor: 0.6;
          UnknownFactor9C: 0.9;
          PirateRelationCeiling: 35
      )
  );

  PlanetEquipmentOfferQuotas: TPlanetEquipmentOfferQuotaTable = (
      (3, 2, 2, 2, 1, 2, 2, 2, 6),
      (4, 2, 2, 2, 1, 2, 2, 2, 5),
      (4, 2, 2, 2, 2, 1, 2, 2, 5),
      (3, 2, 2, 1, 1, 2, 2, 1, 4),
      (3, 2, 2, 2, 2, 1, 2, 2, 4)
  );

  StationEquipmentOfferQuotas: TStationEquipmentOfferQuotaTable = (
      (
          Hulls: 4;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 2;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 4
      ),
      (
          Hulls: 3;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 3;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 4
      ),
      (
          Hulls: 4;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 2;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 6
      ),
      (
          Hulls: 3;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 2;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 2
      ),
      (
          Hulls: 5;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 2;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 2
      ),
      (
          Hulls: 2;
          FuelTanks: 1;
          Engines: 2;
          Radars: 1;
          Scanners: 2;
          RepairRobots: 1;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 1
      ),
      (
          Hulls: 3;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 3;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 4
      ),
      (
          Hulls: 4;
          FuelTanks: 2;
          Engines: 2;
          Radars: 2;
          Scanners: 2;
          RepairRobots: 2;
          CargoHooks: 2;
          DefGenerators: 2;
          Weapons: 4
      )
  );

  StationGoodsFactors: array[TStationType] of array[TGoodsIndex] of TPlanetGoodsFactors = (
      (
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.15),
          (PriceFactor: 0.8; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 0.5; StockFactor: 0.01)
      ),
      (
          (PriceFactor: 0.9; StockFactor: 0.15),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.2),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 0.8; StockFactor: 0.15),
          (PriceFactor: 0.9; StockFactor: 0.2),
          (PriceFactor: 0.9; StockFactor: 0.3),
          (PriceFactor: 0.9; StockFactor: 0.2)
      ),
      (
          (PriceFactor: 1.1; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 0.4; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 0.8; StockFactor: 0.3),
          (PriceFactor: 0.5; StockFactor: 0.01)
      ),
      (
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 0.8; StockFactor: 0.3),
          (PriceFactor: 0.8; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 1.1; StockFactor: 0.05),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 0.5; StockFactor: 0.01)
      ),
      (
          (PriceFactor: 0.9; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 0.9; StockFactor: 0.3),
          (PriceFactor: 1.1; StockFactor: 0.1),
          (PriceFactor: 0.8; StockFactor: 0.1),
          (PriceFactor: 0.9; StockFactor: 0.1),
          (PriceFactor: 1.0; StockFactor: 0.2),
          (PriceFactor: 1.1; StockFactor: 0.1)
      ),
      (
          (PriceFactor: 0.8; StockFactor: 0.2),
          (PriceFactor: 0.8; StockFactor: 0.3),
          (PriceFactor: 1.0; StockFactor: 0.2),
          (PriceFactor: 1.0; StockFactor: 0.05),
          (PriceFactor: 0.8; StockFactor: 0.05),
          (PriceFactor: 0.9; StockFactor: 0.15),
          (PriceFactor: 0.9; StockFactor: 0.1),
          (PriceFactor: 0.7; StockFactor: 0.2)
      ),
      (
          (PriceFactor: 1.1; StockFactor: 0.05),
          (PriceFactor: 1.1; StockFactor: 0.05),
          (PriceFactor: 0.9; StockFactor: 0.25),
          (PriceFactor: 1.0; StockFactor: 0.1),
          (PriceFactor: 0.8; StockFactor: 0.3),
          (PriceFactor: 0.9; StockFactor: 0.3),
          (PriceFactor: 0.8; StockFactor: 0.3),
          (PriceFactor: 0.8; StockFactor: 0.25)
      ),
      (
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01),
          (PriceFactor: 1.0; StockFactor: 0.01)
      )
  );

  PlanetGovernmentMarket: array[TPlanetGovernment] of TGovermentInfo = (
      (
          InternalName: 'Anarchy';
          DisplayName: '';
          RevolutionRelationDelta: (-30, 30, 0);
          QuestOfferProbabilities: (0.2, 0.6, 0.8, 0.1, 0.3);
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.1; StockFactor: 1.0),
              (PriceFactor: 0.8; StockFactor: 0.8),
              (PriceFactor: 0.8; StockFactor: 1.0),
              (PriceFactor: 1.1; StockFactor: 1.0),
              (PriceFactor: 0.9; StockFactor: 1.0)
          )
      ),
      (
          InternalName: 'Dictatorship';
          DisplayName: '';
          RevolutionRelationDelta: (-40, 20, 20);
          QuestOfferProbabilities: (0.2, 0.7, 0.8, 0.2, 0.5);
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 0.9; StockFactor: 1.0),
              (PriceFactor: 0.9; StockFactor: 0.9),
              (PriceFactor: 1.0; StockFactor: 0.9),
              (PriceFactor: 0.9; StockFactor: 0.9)
          )
      ),
      (
          InternalName: 'Monarchy';
          DisplayName: '';
          RevolutionRelationDelta: (-10, 0, 10);
          QuestOfferProbabilities: (0.2, 0.5, 0.8, 0.5, 0.8);
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 0.9),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.0; StockFactor: 0.8)
          )
      ),
      (
          InternalName: 'Republic';
          DisplayName: '';
          RevolutionRelationDelta: (10, -20, 0);
          QuestOfferProbabilities: (0.2, 0.3, 0.8, 0.7, 0.9);
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.1; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.0; StockFactor: 0.7),
              (PriceFactor: 1.1; StockFactor: 0.7)
          )
      ),
      (
          InternalName: 'Democracy';
          DisplayName: '';
          RevolutionRelationDelta: (15, -30, 0);
          QuestOfferProbabilities: (0.2, 0.3, 0.8, 0.7, 0.9);
          GoodsFactors: (
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 1.0),
              (PriceFactor: 1.1; StockFactor: 1.0),
              (PriceFactor: 1.0; StockFactor: 0.8),
              (PriceFactor: 1.0; StockFactor: 0.5),
              (PriceFactor: 1.1; StockFactor: 0.6)
          )
      )
  );

type

  TRewardInfo = record
    AwardId: Byte;
    Name: WideString;
    Text: WideString;
  end;

var

  GoodsLegalOnPlanet: TGoodsLegalityTable = (
      (
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True)
      ),
      (
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True)
      ),
      (
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True)
      ),
      (
          (True, False, True, False, False),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True)
      ),
      (
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True)
      ),
      (
          (True, False, False, True, True),
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, False, False),
          (True, False, False, True, True)
      ),
      (
          (True, True, True, True, True),
          (True, True, True, True, True),
          (True, True, True, True, False),
          (True, True, False, False, False),
          (True, True, False, False, False)
      ),
      (
          (True, False, False, False, False),
          (True, True, True, True, True),
          (True, False, True, False, False),
          (True, True, False, False, False),
          (True, False, False, False, False)
      )
  );

  MedalNames: array[0..5] of WideString = (
      'ForLiberationSystem',
      'ForAccomplishment',
      'ForSecretMission',
      'ForCowardice',
      'ForPerfidy',
      'ForPlanetBattle'
  );

  CoalitionRankNames: array[TShipRank] of WideString =
      ('Rookie', 'Cadet', 'Pilot', 'Wingman', 'Leader', 'Ace', 'Commander', 'Admiral');

  CoalitionRankPointThresholds: array[TShipRank] of Word =
      (100, 250, 450, 700, 1000, 1500, 2000, 0);

  PirateRankNames: array[TShipRank] of WideString =
      ('Noobie', 'Kid', 'Rader', 'Skipper', 'Rough', 'Ataman', 'Khan', 'Baron');

  PirateRankPointThresholds: array[TShipRank] of Word = (100, 250, 450, 700, 1000, 1500, 3000, 0);

  SkillConfigNames: array[TPilotSkill] of WideString =
      ('sAccuracy', 'sMobility', 'sTechnical', 'sTrader', 'sCharm', 'sLeadership');

  RaceSkillEvaluationFactors: array[oiMaloc..oiGaal] of array[TPilotSkill] of Single = (
      (1.2, 1.1, 0.9, 0.8, 1.0, 1.0),
      (1.0, 1.2, 0.8, 1.1, 1.0, 0.9),
      (0.9, 0.8, 1.0, 1.2, 1.0, 1.1),
      (1.1, 1.0, 1.2, 0.8, 0.9, 1.0),
      (0.8, 0.9, 1.1, 1.0, 1.2, 1.0)
  );

  PilotSkillEffects: array[0..6] of array[TPilotSkill] of Word = (
      (0, 0, 0, 30, 0, 0),
      (17, 17, 8, 38, 17, 1),
      (33, 33, 17, 47, 33, 2),
      (50, 50, 25, 55, 50, 3),
      (67, 67, 33, 63, 67, 4),
      (83, 83, 42, 72, 83, 5),
      (100, 100, 50, 80, 100, 6)
  );

  TechnicalSkillSatelliteLimits: array[0..6] of Word = (2, 3, 4, 5, 6, 7, 8);

  TradingSkillSalePercent: array[0..6] of Word = (0, 8, 16, 25, 33, 41, 50);

  LeadershipExperiencePercent: array[0..6] of Word = (0, 5, 10, 15, 20, 25, 30);

  MaxPlanetNews: Integer = 9;

  SizeTagNames: array[0..5] of WideString = ('Zero', 'Mini', 'Small', 'Average', 'Big', 'Huge');

type

  TPrimaryDamageTypeInfo = record
    Kind: TWeaponDamageClass;
    BonusKind: TEquipmentBonusKind;
    Name: WideString;
  end;

var

  WealthDemandScales: array[0..5] of Single = (0.0, 0.01, 0.0125, 0.016666667, 0.02, 0.025);

  MinimumHullSlotCounts: array[TShipSlotKind] of Integer = (1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0);

  DefaultHullSlotCounts: array[TShipSlotKind] of Integer = (1, 1, 1, 1, 1, 1, 1, 5, 4, 1, 0);

  RangerHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 1, 1, 1, 4, 2, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 2, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 3, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  WarriorHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 0, 0, 1, 5, 1, 0, 0),
      (1, 1, 1, 1, 0, 1, 1, 4, 0, 1, 0),
      (1, 1, 1, 1, 1, 0, 1, 4, 1, 1, 0),
      (1, 1, 1, 1, 1, 0, 1, 4, 0, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  PirateHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 0, 1, 1, 4, 2, 1, 0),
      (1, 1, 1, 1, 1, 1, 0, 5, 3, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 0),
      (1, 1, 1, 1, 1, 1, 0, 3, 2, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  TransportHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 0, 0, 1, 0, 3, 0, 0, 0),
      (1, 1, 1, 0, 1, 1, 1, 2, 1, 0, 0),
      (1, 1, 1, 0, 1, 1, 0, 2, 0, 0, 0),
      (1, 1, 1, 0, 1, 1, 1, 2, 0, 0, 0),
      (1, 1, 1, 0, 1, 1, 1, 2, 0, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  LinerHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 0, 1, 0, 1, 4, 0, 0, 0),
      (1, 1, 1, 0, 1, 0, 1, 4, 0, 0, 0),
      (1, 1, 1, 0, 1, 0, 0, 4, 0, 0, 0),
      (1, 1, 1, 1, 1, 0, 0, 3, 2, 0, 0),
      (1, 1, 1, 1, 0, 0, 0, 3, 2, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  DiplomatHullSlots: array[TOwnerId] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 1, 1, 1, 4, 1, 0, 0),
      (1, 1, 1, 1, 1, 1, 0, 3, 1, 1, 0),
      (1, 1, 1, 1, 1, 0, 1, 2, 1, 1, 0),
      (1, 1, 1, 1, 1, 0, 1, 3, 1, 1, 0),
      (1, 1, 1, 1, 1, 0, 1, 2, 3, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0),
      (1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 0)
  );

  TranclucatorHullSlots: array[TShipSlotKind] of Integer = (1, 1, 0, 0, 1, 1, 1, 5, 4, 0, 0);

  StationHullSlots: array[TStationType] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0)
  );

  DominatorHullSlots: array[TKlingType] of array[TShipSlotKind] of Integer = (
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 5, 4, 1, 0)
  );

  SpecialHullSlots: array[TShipSlotKind] of Integer = (1, 1, 1, 1, 1, 1, 1, 5, 4, 1, 0);

  FlagshipHullSlots: array[TShipSlotKind] of Integer = (1, 1, 1, 1, 1, 1, 1, 5, 4, 0, 0);

  HullSlotBonusKinds: array[TShipSlotKind] of TEquipmentBonusKind = (
      bonNull,
      bonNull,
      bonSlotRadar,
      bonSlotScaner,
      bonSlotDroid,
      bonSlotHook,
      bonSlotDef,
      bonSlotWeapon,
      bonSlotArt,
      bonSlotForsage,
      bonNull
  );

  OwnerWeaponAvailability: TOwnerWeaponAvailabilityTable = (
      waMalocOnly,
      waPelengOnly,
      waPeopleOnly,
      waFeiOnly,
      waGaalOnly,
      waNotSoldAndNodeRepair,
      waNotSold,
      waPirateOnly
  );

  WeaponDamageFlagNames: array[0..20] of WideString = (
      'Energy',
      'Splinter',
      'Missile',
      'Decelerate',
      'Destruct',
      'Drain',
      'Shock',
      'Acid',
      'Magnetic',
      'DecelerateA',
      'DecelerateAEx',
      'Undefendable',
      'NonLethal',
      'ScanBonus',
      'BonusToDamaged',
      'MoreDrop',
      'DropCargo',
      'ReduceEngine',
      'BlockWeapon',
      'BlockDroid',
      'NoDelta'
  );

  WeaponDamageClasses: array[TWeaponDamageClass] of TPrimaryDamageTypeInfo = (
      (Kind: wdcEnergy; BonusKind: bonWEnergy; Name: 'Energy'),
      (Kind: wdcSplinter; BonusKind: bonWSplinter; Name: 'Splinter'),
      (Kind: wdcMissile; BonusKind: bonWMissile; Name: 'Missile')
  );

type

  PointerToTMicroModuleInfo = ^TMicroModuleInfo;

  THullTypeInfo = record
    Name: WideString;
    Text: WideString;
    AllowedOwners: TOwnerMask;
    AllowedShipTypes: THullShipTypeMask;
    SlotBonuses: array[TShipSlotKind] of Integer;
    SizePercent: Integer;
    CostPercent: Integer;
    FragilityFactor: Single;
    FragilityByDamageClass: array[TWeaponDamageClass] of Single;
    Year: Byte;
    ProbabilityWeight: Integer;
    SortKey: Integer;
    SystemName: WideString;
    SystemNameCRC: Cardinal;
  end;

  TMicroModuleInfo = record
    SpecialOnly: Boolean;
    BlocksMicroModuleSlot: Boolean;
    BlocksSpecialSlot: Boolean;
    Name: WideString;
    NamePrefix: WideString;
    Color: WideString;
    TextReplace: WideString;
    StatBonuses: TEquipmentBonuses;
    CostPercent: Integer;
    SizePercent: Integer;
    FragilityFactor: Single;
    FragilityFactorByDamageClass: array[TWeaponDamageClass] of Single;
    Priority: Byte;
    AllowedHullOwnerMask: TOwnerMask;
    AllowedCustomHullFactions: WideString;
    CustomFaction: WideString;
    AllowedDominatorSeriesMask: TDominatorSeriesMask;
    AllowedItemTypes: TItemTypeSelection;
    AllowedCustomWeaponTypes: WideString;
    OfferStationTypes: TShipTypeMask;
    OfferStationNames: WideString;
    OnPlanets: Boolean;
    RacialRestriction: Boolean;
    SeparatedNumbers: Boolean;
    ConfigNumber: Integer;
    ConfigName: WideString;
    ConfigNameHash: Cardinal;
    KindGraph: WideString;
    MissileGraph: WideString;
    ShotVisual: Integer;
    HullGraphSizePercent: Integer;
    CustomTag: WideString;
    WeaponDamageFlags: TDamageFlagSet;
  end;

  PMicroModuleTemplate = PointerToTMicroModuleInfo;

var

  CombatStatusHullFactors: array[0..6] of Single = (1, 1, 1, 0.3, 0.3, 0, 0);

  CombatStatusAccumulationFactors: array[0..6] of Single = (0, 0, 0.1, 0, 0, 0.025, 0);

  EquipmentBonusNames: array[TEquipmentBonusKind] of WideString = (
      'bonHull',
      'bonFuel',
      'bonSpeed',
      'bonJump',
      'bonRadar',
      'bonScan',
      'bonDroid',
      'bonHook',
      'bonDef',
      'bonWEnergy',
      'bonWSplinter',
      'bonWMissile',
      'bonWRadius',
      'bonSlotRadar',
      'bonSlotScaner',
      'bonSlotDroid',
      'bonSlotHook',
      'bonSlotDef',
      'bonSlotWeapon',
      'bonSlotArt',
      'bonSlotForsage',
      'bonHookRadius',
      'bonSkill1',
      'bonSkill2',
      'bonSkill3',
      'bonSkill4',
      'bonSkill5',
      'bonSkill6',
      'bonMass',
      'bonExtraAkrinEff',
      'bonExtraAkrinPenalty',
      'bonAmmo',
      'bonShots',
      'bonMissileSpeed',
      'bonShotSpeed',
      'bonHookMaxSpeed',
      'bonHookMinSpeed',
      'bonStimCapacity',
      'bonZonds',
      'bonAttacks',
      'bonResistAsteroid',
      'bonAIValue',
      'bonNull'
  );

type

  tInventionInfo = record
    Name: WideString;
    InitialLevel: Byte;
    RequiredMainTechLevel: Byte;
  end;

var

  EquipmentBonusSkills: array[0..5] of TPilotSkill =
      (psAccuracy, psManeuverability, psTechnical, psTrading, psCharisma, psLeadership);

  EquipmentSizeFactors: TEquipmentSizeFactorTable = (2.0, 1.5, 1.0, 0.7, 0.5);

  WeaponRangeLevelFactors: TWeaponRangeLevelFactors = (0.9, 0.95, 0.95, 1.0, 1.0, 1.05, 1.05, 1.1);

  PlanetInventionInfo: array[TPlanetInvention] of tInventionInfo = (
      (Name: 'Hull level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'FuelTanks level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Engine level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Radar level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Scaner level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'RepairRobot level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'CargoHook level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Tech level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Weapon1 level'; InitialLevel: 1; RequiredMainTechLevel: 1),
      (Name: 'Weapon2 level'; InitialLevel: 1; RequiredMainTechLevel: 2),
      (Name: 'Weapon3 level'; InitialLevel: 1; RequiredMainTechLevel: 3),
      (Name: 'Weapon4 level'; InitialLevel: 1; RequiredMainTechLevel: 4),
      (Name: 'Weapon5 level'; InitialLevel: 1; RequiredMainTechLevel: 4),
      (Name: 'Weapon6 level'; InitialLevel: 1; RequiredMainTechLevel: 5),
      (Name: 'Weapon7 level'; InitialLevel: 1; RequiredMainTechLevel: 5),
      (Name: 'Weapon8 level'; InitialLevel: 1; RequiredMainTechLevel: 6),
      (Name: 'Weapon9 level'; InitialLevel: 1; RequiredMainTechLevel: 6),
      (Name: 'Weapon10 level'; InitialLevel: 1; RequiredMainTechLevel: 7),
      (Name: 'Weapon11 level'; InitialLevel: 1; RequiredMainTechLevel: 7),
      (Name: 'Weapon12 level'; InitialLevel: 1; RequiredMainTechLevel: 8)
  );

type

  PointerToTWeaponInfo = ^TWeaponInfo;

  TWeaponInfo = record
    ItemType: TItemType;
    ConfigName: WideString;
    TechLevel: Byte;
    InventionIndex: TPlanetInvention;
    CostFactor: Single;
    MinDamage: Integer;
    MaxDamage: Integer;
    AverageSize: Integer;
    AverageRange: Integer;
    ShotSpeedPercent: Integer;
    MissileRange: Integer;
    MissileMaxSpeed: Integer;
    MissileMinSpeed: Integer;
    MissileChanceToBeHit: Byte;
    DamageFlags: TDamageFlagSet;
    ShotType: TWeaponShotType;
    ShotCount: Byte;
    AttackCount: Byte;
    SecondaryDamageRadius: Single;
    MiningFactor: Single;
    DamageScaleByLevel: array[1..8] of Single;
    PrimarySE: WideString;
    SecondarySE: WideString;
    AreaSE: WideString;
    DefaultPalette: Integer;
    Availability: TWeaponAvailability;
    ArcadeWeaponType: Byte;
    TypeHash: Cardinal;
  end;

  PWeaponInfo = PointerToTWeaponInfo;

var

  GoodsInflationMin: Single;

  GoodsInflationMax: Single;

  GoodsStockMin: Single;

  GoodsStockMax: Single;

  GoodsInflationStartTurn: Integer;

  GoodsInflationEndTurn: Integer;

  QuestTuning: TQuestTuningTable;

  SkillTrainingCosts: array[0..6] of array[TPilotSkill] of Word;

  TotalSkillTrainingCost: Integer;

  QuestExperience: TQuestExperienceTable;

  HullArtefactArmor: Integer;

  HullArtefactStatusDecayFactor: Single;

  FuelArtefactBase: Integer;

  SpeedArtefactFactor: Single;

  EngineArtefactBase: Integer;

  RadarArtefactRange: Integer;

  ScannerArtefactPower: Integer;

  DroidArtefactRepair: Integer;

  DroidArtefactWear: Single;

  DroidArtefactStatusDecayFactor: Single;

  NanoArtefactRepair: Integer;

  DefenseArtefactBonus: Single;

  AntigravityArtefactMassFactor: Single;

  CargoHookArtefactPower: Integer;

  CargoHookArtefactRange: Integer;

  CargoHookArtefactSpeed: Integer;

  WeaponToSpeedArtefactBonus: Integer;

  DefenseToEnergyUpperFactor: Single;

  DefenseToEnergyMinimumFactor: Single;

  DefenseToEnergyPenalty: Single;

  DefenseToWeaponPenalty: Single;

  EnergyPulseArtefactFactor: Single;

  EnergyPulseArtefactChance: Single;

  SplinterArtefactFactor: Single;

  HyperJumpArtefactRange: Integer;

  StarHeatArtefactReduction: Single;

  ExtraMissileChance: Single;

  AfterburnerArtefactWearFactor: Single;

  HullArtefactBoostArmor: Integer;

  HullArtefactBoostStatusDecay: Single;

  FuelArtefactBoost: Integer;

  SpeedArtefactBoostFactor: Single;

  EngineArtefactBoost: Integer;

  RadarArtefactBoostRange: Integer;

  ScannerArtefactBoostPower: Integer;

  DroidArtefactBoostRepair: Integer;

  DroidArtefactBoostWear: Single;

  DroidArtefactBoostStatusDecay: Single;

  NanoArtefactBoostRepair: Integer;

  DefenseArtefactBoost: Single;

  AntigravityArtefactBoostFactor: Single;

  CargoHookArtefactBoostPower: Integer;

  CargoHookArtefactBoostRange: Integer;

  CargoHookArtefactBoostSpeed: Integer;

  WeaponToSpeedArtefactBoost: Integer;

  DefenseToEnergyUpperBoost: Single;

  DefenseToEnergyMinimumBoost: Single;

  DefenseToEnergyBoostPenalty: Single;

  EnergyPulseArtefactBoostFactor: Single;

  SplinterArtefactBoostFactor: Single;

  HyperJumpArtefactBoostRange: Integer;

  StarHeatArtefactBoostReduction: Single;

  ExtraMissileBoostChance: Single;

  AfterburnerArtefactBoostWearFactor: Single;

  MinTransmitterPower: Integer;

  AverageTransmitterPower: Integer;

  MaxTransmitterPower: Integer;

  TransmitterSameSystemPenalty: Integer;

  TransmitterAnySystemPenalty: Integer;

  TransmitterSameSystemPenaltyTurns: Integer;

  TransmitterAnySystemPenaltyTurns: Integer;

  SubportalRewardPenalty: Integer;

  SubportalRewardPenaltyTurns: Integer;

  ItemExplosionBonusDamage: Integer;

  BombMinimumDamage: Integer;

  BombMaximumDamage: Integer;

  BombDamageRadius: Integer;

  ItemExplosionRadiusSquared: Integer;

  PointDefensePassCount: Integer;

  PointDefenseBaseRange: Integer;

  PointDefenseBonusRange: Integer;

  AsteroidMinDamageFactor: Single;

  AsteroidMaxDamageFactor: Single;

  AsteroidMinDamageFactorWithDefGenerator: Single;

  AsteroidMaxDamageFactorWithDefGenerator: Single;

  HullCapacityScale: Single;

  HullBaseSize: Integer;

  FuelTanksBaseSize: Integer;

  EngineBaseSize: Integer;

  RadarBaseSize: Integer;

  ScannerBaseSize: Integer;

  RepairRobotBaseSize: Integer;

  CargoHookBaseSize: Integer;

  DefGeneratorBaseSize: Integer;

  AfterburnerSpeedFactor: Single;

  FuelCapacityByLevel: array[1..8] of Byte;

  EngineLevelStats: TEngineLevelStatsTable;

  HullLevelStats: THullLevelStatsTable;

  RepairRobotLevelPoints: array[1..8] of Byte;

  DefGeneratorLevelFactors: array[1..8] of Single;

  RadarLevelRanges: array[1..8] of Word;

  CargoHookLevelStats: TCargoHookLevelStatsTable;

  HullFragilityByOwner: array[TWeaponDamageClass] of array[TOwnerId] of Single;

  HullFragilityByType: array[THullType] of Single;

  WeaponInfos: array[t_IndustrialLaser..t_Lirecron] of TWeaponInfo;

  EquipmentInventionIndices: TEquipmentInventionIndexTable =
      (piHull, piFuelTanks, piEngine, piRadar, piScanner, piRepairRobot, piCargoHook, piMainTech);

  CoalitionProjectNames: array[TCoalitionProject] of WideString = (
      'CreateRC',
      'CreatePB',
      'CreateWB',
      'CreateSB',
      'CreateBK',
      'CreateMC',
      'RangersSubsidy',
      'PiratesSubsidy',
      'TransportSubsidy',
      'LostSubsidy',
      'WarSubsidy',
      'WarOperation'
  );

type

  {$Z1}
  THealthLocation = (hlPlanet = 0, hlDocked = 1, hlNormalSpace = 2, hlCombat = 3);

  THealthLocations = set of THealthLocation;

  TIllnessInfo = record
    Name: WideString;
    Text: WideString;
    AllowedLocationOwners: TOwnerMask;
    AllowedOwners: TOwnerMask;
    AllowedRatingBands: TByteMask;
    AllowedRanks: TByteMask;
    AllowedCareers: TRangerCareerSet;
    MedicalPriceSizeLevel: Byte;
    DevelopmentRate: Double;
    InfectionChance: Double;
    Locations: THealthLocations;
    Disabled: Boolean;
    Duration: Integer;
  end;

  TRadiationHealthDefinitions = array[1..1] of TIllnessInfo;

var

  StationServiceRepeatPeriods: array[TCoalitionProject] of Integer =
      (100, 400, 300, 200, 350, 250, 150, 220, 40, 50, 70, 80);

  ProgramNames: array[TProgramIndex] of WideString = (
      'KellerCall',
      'LogicalNegation',
      'Dematerial',
      'Energotron',
      'SabCrack',
      'Intercom',
      'Shipwreck',
      'WeaponBlocking',
      'Insanity',
      'Shock',
      'SelfDestruction',
      'Disconnection'
  );

  ProgramDuration: TProgramDurationTable = (0, 0, 0, 0, 0, 0, 0, 10, 23, 7, 0, 0);

  PirateProgramBatchSizes: array[TProgramIndex] of Integer = (0, 0, 0, 0, 0, 5, 3, 3, 3, 3, 1, 1);

  PirateProgramBaseCosts: array[TProgramIndex] of Integer =
      (0, 0, 0, 0, 0, 500, 1000, 800, 300, 200, 1200, 900);

  GoodsMarketBaseCaptured: Boolean = False;

  IntegrityDataEnd: Cardinal = 0;

  LastMedicalPolicyTicks: Integer = 0;

  HullMassEvaluationStart: Integer;

  HullMassEvaluationEnd: Integer;

  WearMassMin: Integer;

  WearMassMax: Integer;

  GoodsMarketBase: array[TGoodsIndex] of TGoodsInfo;

  MicroModuleTemplates: array of TMicroModuleInfo;

  MicroModuleTemplateCount: Integer;

  HullSeriesDefinitions: array of THullTypeInfo;

  HullSeriesCount: Integer;

  CaptainHealthDefinitions: array[TCaptainHealthEffect] of TIllnessInfo;

  RadiationHealthDefinitions: TRadiationHealthDefinitions;

  MicroModuleCandidateIndices: array of Integer;

procedure InitializeGameplayConfig;

function OwnerToRace(OwnerId: TOwnerId): TOwnerId;

function RaceToOwner(RaceId: TOwnerId): TOwnerId;

function RaceToSys(RaceId: TOwnerId): WideString;

function OwnerToFilmColor(OwnerId: TOwnerId): Cardinal;

function CustomFactionToFilmColor(Faction: WideString): Cardinal;

function LookupNamedColorTag(Name: WideString): WideString;

function GetCustomFactionPlanetIconNumber(Faction: WideString): Integer;

function GetFactionEmblemPath(Faction: WideString): WideString;

function OwnerToSys(OwnerId: TOwnerId): WideString;

function OwnerFromInternalName(const Name: WideString): TOwnerId;

function IsKnownOwnerName(const Name: WideString): Boolean;

function NumberToRace(Value: Integer): TOwnerId;

function MatchesOwnerName(OwnerId: TOwnerId; const Name: WideString): Boolean;

function PickRandomEquipmentOwner(RandomValue: Dword): TOwnerId;

function MatchesCareerName(Career: TRangerCareer; const Names: WideString): Boolean;

function SysToReward(const Name: WideString): TAwardKind;

function SysToShipType(const Name: WideString): TShipType;

function GetAverageItemSize(ItemType: TItemType): Integer;

function GenerateValueForSizeLevel(
    Level: Byte;
    Minimum: Integer;
    Maximum: Integer;
    VariationPercent: Byte;
    Seed: Cardinal
): Integer;

function SizeTagToLevel(const Tag: WideString): Byte;

function ShipToHullType(Ship: TObject): THullType;

function RelationValueToLevel(Value: Byte): TRelationLevel;

function ItemTypeToSlotKind(ItemType: TItemType): TShipSlotKind;

function LocalizedText(const Path: WideString): WideString;

function LocalizedColorText(const Path: WideString): WideString;

procedure ExpandLocalizedTextMarkup(var Text: WideString);

procedure ExpandLocalizedTextMarkupAndPrefixLines(var Text: WideString);

function PickLocalizedTextVariant(const Path: WideString; SeedOffset: Integer): WideString;

function FindMicroModuleTemplateByCustomTag(CustomTag: WideString): Integer;

procedure LoadArtefactConfiguration;

procedure LoadDamageSkillQuestMarketConfiguration;

procedure LoadEquipmentConfiguration;

procedure LoadWeaponConfiguration;

procedure LoadMicroModuleConfiguration;

procedure InitializeCaptainHealthDefinitions;

procedure LoadHullSeriesConfiguration;

procedure IncrementWordSaturating(var Value: Word);

function PickRandomItemType(Mask: TItemTypeSelection): Byte;

function PickRandomItemTypeFromSeed(Mask: TItemTypeSelection; var Seed: Cardinal): Byte;

function CountItemTypesInMask(Mask: TItemTypeSelection): Integer;

function GetItemTypeFromMask(Mask: TItemTypeSelection; Index: Integer): Byte;

function ClassifyWeaponDamageFlags(Flags: TDamageFlagSet): TWeaponDamageClass;

implementation

uses
  SE_Weapon,
  aItem,
  aShip,
  Math,
  CrcUnit,
  EC_BlockPar,
  Globals,
  GlobalsV,
  EC_Str,
  GR_Main,
  SysUtils,
  aGalaxy,
  aPlayer,
  aMyFunction,
  aRanger,
  aWarrior,
  aPirate,
  aTransport,
  aKling,
  aTranclucator,
  aRuins;

procedure InitializeGameplayConfig;
var
  Level, GoodsIndex: Byte;
  Government: TPlanetGovernment;
  Relation: TRelationLevel;
  KlingKind: TKlingType;
  Series: TDominatorSeries;
  Owner: TOwnerId;
  Economy: TPlanetEconomy;
  Difficulty: ^TGalaxyDifficultyTuning;

  function ExtrapolateLinearDifficulty(
      Level: Byte;
      Level2, Level3: Single
  ): Single; { Nested in InitializeGameplayConfig; unused caller-popped static link. }
  var
    Delta: Integer;
  begin
    Delta := Level - 3;
    Result := Level3 + (Level3 - Level2) * Delta;
  end;

  function ExtrapolateGeometricDifficulty(
      Level: Byte;
      Level2, Level3: Single
  ): Single; { Nested in InitializeGameplayConfig; unused caller-popped static link. }
  var
    Delta: Integer;
  begin
    Delta := Level - 3;
    Result := Level3 * Exp(Ln(Level3 / Level2) * Delta);
  end;

begin
  if LanguageDataConfig.CountParamsByPath('Constellations.GalaxyCountStars') > 0 then
    GalaxyStarCount :=
        ExtractDigitsToIntW(LanguageDataConfig.GetParamByPath('Constellations.GalaxyCountStars'))
  else
    GalaxyStarCount := 73;
  if LanguageDataConfig.CountParamsByPath('Constellations.GalaxySizeY') > 0 then
    GalaxySizeY :=
        ExtractDigitsToIntW(LanguageDataConfig.GetParamByPath('Constellations.GalaxySizeY'))
  else
    GalaxySizeY := 100;
  if LanguageDataConfig.CountParamsByPath('Constellations.GalaxySizeX') > 0 then
    GalaxySizeX :=
        ExtractDigitsToIntW(LanguageDataConfig.GetParamByPath('Constellations.GalaxySizeX'))
  else
    GalaxySizeX := 145;
  if LanguageDataConfig.CountParamsByPath('GalaxyNews.MaxCntPlanetNews') > 0 then
    MaxPlanetNews :=
        ExtractDigitsToIntW(LanguageDataConfig.GetParamByPath('GalaxyNews.MaxCntPlanetNews'))
  else
    MaxPlanetNews := 9;
  for Level := 4 to 9 do
  begin
    Difficulty := @GalaxyDifficultyTuning[Level];
    Difficulty.MaximumQuestProgramRewardCount := 1;
    Difficulty.GoodsEventDurationFactor :=
        ExtrapolateLinearDifficulty(
            Level,
            GalaxyDifficultyTuning[2].GoodsEventDurationFactor,
            GalaxyDifficultyTuning[3].GoodsEventDurationFactor
        );
    Difficulty.QuestTimeAndExperienceFactor :=
        ExtrapolateLinearDifficulty(
            Level,
            GalaxyDifficultyTuning[2].QuestTimeAndExperienceFactor,
            GalaxyDifficultyTuning[3].QuestTimeAndExperienceFactor
        );
    Difficulty.EquipmentWearFactor :=
        ExtrapolateLinearDifficulty(
            Level,
            GalaxyDifficultyTuning[2].EquipmentWearFactor,
            GalaxyDifficultyTuning[3].EquipmentWearFactor
        );
    Difficulty.InitialPirateControlPercent :=
        Round(
            ExtrapolateLinearDifficulty(
                Level,
                GalaxyDifficultyTuning[2].InitialPirateControlPercent,
                GalaxyDifficultyTuning[3].InitialPirateControlPercent
            )
        );
    Difficulty.MarketPriceBandSqueeze :=
        ExtrapolateLinearDifficulty(
            Level,
            GalaxyDifficultyTuning[2].MarketPriceBandSqueeze,
            GalaxyDifficultyTuning[3].MarketPriceBandSqueeze
        );
    Difficulty.RandomHoleSpawnRollMaximum :=
        Round(
            ExtrapolateLinearDifficulty(
                Level,
                GalaxyDifficultyTuning[2].RandomHoleSpawnRollMaximum,
                GalaxyDifficultyTuning[3].RandomHoleSpawnRollMaximum
            )
        );
    Difficulty.MaximumResearchMaterialConsumption :=
        Round(
            ExtrapolateLinearDifficulty(
                Level,
                GalaxyDifficultyTuning[2].MaximumResearchMaterialConsumption,
                GalaxyDifficultyTuning[3].MaximumResearchMaterialConsumption
            )
        );
    Difficulty.ArcadeDamageTakenScale :=
        ExtrapolateLinearDifficulty(
            Level,
            GalaxyDifficultyTuning[2].ArcadeDamageTakenScale,
            GalaxyDifficultyTuning[3].ArcadeDamageTakenScale
        );
    Difficulty.InventionProgressScale :=
        ExtrapolateGeometricDifficulty(
            Level,
            GalaxyDifficultyTuning[2].InventionProgressScale,
            GalaxyDifficultyTuning[3].InventionProgressScale
        );
    Difficulty.ArcadeRewardScale :=
        ExtrapolateGeometricDifficulty(
            Level,
            GalaxyDifficultyTuning[2].ArcadeRewardScale,
            GalaxyDifficultyTuning[3].ArcadeRewardScale
        );
    Difficulty.QuestMoneyFactor :=
        ExtrapolateGeometricDifficulty(
            Level,
            GalaxyDifficultyTuning[2].QuestMoneyFactor,
            GalaxyDifficultyTuning[3].QuestMoneyFactor
        );
    Difficulty.StartingPlayerMoney :=
        Round(
            ExtrapolateGeometricDifficulty(
                Level,
                GalaxyDifficultyTuning[2].StartingPlayerMoney,
                GalaxyDifficultyTuning[3].StartingPlayerMoney
            )
        );
    Difficulty.MaximumDominatorResearchRate :=
        ExtrapolateGeometricDifficulty(
            Level,
            GalaxyDifficultyTuning[2].MaximumDominatorResearchRate,
            GalaxyDifficultyTuning[3].MaximumDominatorResearchRate
        );
    Difficulty.CoalitionToPirateBalanceRatio :=
        ExtrapolateGeometricDifficulty(
            Level,
            GalaxyDifficultyTuning[2].CoalitionToPirateBalanceRatio,
            GalaxyDifficultyTuning[3].CoalitionToPirateBalanceRatio
        );
  end;
  for GoodsIndex := Low(TGoodsIndex) to High(TGoodsIndex) do
    GoodsMarket[GoodsIndex].DisplayName :=
        LocalizedText('Items.Goods.Name.' + IntToStr(GoodsIndex + 1));
  for GoodsIndex := Low(TGoodsIndex) to High(TGoodsIndex) do
    GoodsMarket[GoodsIndex].TradeName :=
        LocalizedText('Items.Goods.NameBuy.' + IntToStr(GoodsIndex + 1));
  for Government := Low(TPlanetGovernment) to High(TPlanetGovernment) do
    PlanetGovernmentMarket[Government].DisplayName :=
        LocalizedText('Goverment.Type.' + IntToStr(Ord(Government)));
  for Relation := Low(TRelationLevel) to High(TRelationLevel) do
    RelationInfo[Relation].DisplayName :=
        LocalizedText('Relations.Type.' + IntToStr(Ord(Relation)));
  for KlingKind := Low(TKlingType) to High(TKlingType) do
    for Series := Low(TDominatorSeries) to High(TDominatorSeries) do
      DominatorShipDefinitions[KlingKind].DisplayNames[Series] :=
          LookupLocalizedTextByKey(
              'ShipType.Dominator.' + DominatorSeriesNames[Series] + '.' + IntToStr(Ord(KlingKind))
          );
  for Owner := oiMaloc to oiPirate do
    OwnerInfo[Owner].DisplayName :=
        LookupLocalizedTextByKey('Race.Name.' + OwnerInfo[Owner].InternalName);
  // Both identical localization passes are present in the native initializer.
  for Owner := oiMaloc to oiPirate do
    OwnerInfo[Owner].DisplayName :=
        LookupLocalizedTextByKey('Race.Name.' + OwnerInfo[Owner].InternalName);
  for Economy := Low(TPlanetEconomy) to High(TPlanetEconomy) do
  begin
    PlanetEconomyInfo[Economy].DisplayName :=
        LookupLocalizedTextByKey('Economy.Name.' + IntToStr(Ord(Economy)));
    PlanetEconomyInfo[Economy].ShortDisplayName :=
        LookupLocalizedTextByKey('Economy.ShortName.' + IntToStr(Ord(Economy)));
  end;
  if not GoodsMarketBaseCaptured then
  begin
    for GoodsIndex := Low(TGoodsIndex) to High(TGoodsIndex) do
      GoodsMarketBase[GoodsIndex] := GoodsMarket[GoodsIndex];
    GoodsMarketBaseCaptured := True;
  end;
  InitializeWeaponVisualResources;
  LoadEquipmentConfiguration;
  LoadWeaponConfiguration;
  LoadArtefactConfiguration;
  LoadDamageSkillQuestMarketConfiguration;
  LoadMicroModuleConfiguration;
  InitializeCaptainHealthDefinitions;
  LoadHullSeriesConfiguration;
  if LanguageDataConfig.CountParamsByPath('Artefacts.NumericValues.MaxSlots') > 0 then
    DefaultHullSlotCounts[sskArtefact] :=
        Max(
            4,
            Min(
                32,
                ExtractDigitsToIntW(
                    LanguageDataConfig.GetParamByPath('Artefacts.NumericValues.MaxSlots')
                )
            )
        )
  else
    DefaultHullSlotCounts[sskArtefact] := 4;
  HullMassEvaluationStart := Round(HullBaseSize * EquipmentSizeFactors[5] * 2);
  HullMassEvaluationEnd := Round(HullBaseSize * EquipmentSizeFactors[1] * 2);
  WearMassMin := Round(HullBaseSize * EquipmentSizeFactors[1] * 5);
  WearMassMax := Round(HullBaseSize * EquipmentSizeFactors[1] * 50);
end;

function OwnerToRace(OwnerId: TOwnerId): TOwnerId;
begin
  case OwnerId of
    oiMaloc: Result := oiMaloc;
    oiPeleng: Result := oiPeleng;
    oiHuman: Result := oiHuman;
    oiFeyan: Result := oiFeyan;
    oiGaal: Result := oiGaal;
  else
    begin
      raise Exception.Create('Error in OwnerToRace');
      Result := oiMaloc;
    end;
  end;
end;

function RaceToOwner(RaceId: TOwnerId): TOwnerId;
begin
  case RaceId of
    oiMaloc: Result := oiMaloc;
    oiPeleng: Result := oiPeleng;
    oiHuman: Result := oiHuman;
    oiFeyan: Result := oiFeyan;
    oiGaal: Result := oiGaal;
  else
    begin
      raise Exception.Create('Error in RaceToOwner ' + IntToWideString(Ord(RaceId)));
      Result := oiMaloc;
    end;
  end;
end;

function RaceToSys(RaceId: TOwnerId): WideString;
begin
  case RaceId of
    oiMaloc: Result := 'Maloc';
    oiPeleng: Result := 'Peleng';
    oiHuman: Result := 'People';
    oiFeyan: Result := 'Fei';
    oiGaal: Result := 'Gaal';
  else
    begin
      raise Exception.Create('Error in RaceToSys');
      Result := '';
    end;
  end;
end;

function OwnerToFilmColor(OwnerId: TOwnerId): Cardinal;
begin
  case OwnerId of
    oiMaloc: Result := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
    oiPeleng: Result := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
    oiHuman: Result := CurrentPixelFormat.PackRgbBytes(0, $47, $EA);
    oiFeyan: Result := CurrentPixelFormat.PackRgbBytes(255, $93, $F1);
    oiGaal: Result := CurrentPixelFormat.PackRgbBytes($ED, $F7, $3E);
    oiDominator: Result := CurrentPixelFormat.PackRgbBytes($61, $A7, $BE);
    oiPirate: Result := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  else
    Result := CurrentPixelFormat.PackRgbBytes(255, 0, 255);
  end;
end;

function CustomFactionToFilmColor(Faction: WideString): Cardinal;
var
  Block: TBlockParEC;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlock('Race').FindBlock('Color');
  if Block <> nil then
    if Block.CountParamsByPath(Faction) > 0 then
    begin
      Text := Block.GetParamByPathOrMarker(Faction);
      if CountDelimitedPartsW(Text, ',') >= 3 then
      begin
        Result :=
            CurrentPixelFormat.PackRgb(
                ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ',')),
                ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ',')),
                ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','))
            );
        Exit;
      end;
    end;
  Result := OwnerToFilmColor(oiUninhabited);
end;

function LookupNamedColorTag(Name: WideString): WideString;
var
  Block: TBlockParEC;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlock('Race').FindBlock('Color');
  if Block <> nil then
    if Block.CountParamsByPath(Name) > 0 then
    begin
      Text := Block.GetParam(Name);
      if CountDelimitedPartsW(Text, ',') >= 3 then
      begin
        Result := '<color=' + Text + '>';
        Exit;
      end;
    end;
  Result := '<color=255,000,255>';
end;

function GetCustomFactionPlanetIconNumber(Faction: WideString): Integer;
var
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlock('Race').FindBlock('PlanetIconNum');
  if (Block <> nil) and (Block.CountParamsByPath(Faction) > 0) then
    Result := ExtractDigitsToIntW(Block.GetParamByPathOrMarker(Faction))
  else
    Result := -1;
end;

function GetFactionEmblemPath(Faction: WideString): WideString;
begin
  Result := GameDataConfig.GetParamByPathOrMarker('Race.Emblem.2' + Faction);
end;

function OwnerToSys(OwnerId: TOwnerId): WideString;
begin
  case OwnerId of
    oiMaloc: Result := 'Maloc';
    oiPeleng: Result := 'Peleng';
    oiHuman: Result := 'People';
    oiFeyan: Result := 'Fei';
    oiGaal: Result := 'Gaal';
    oiDominator: Result := 'Kling';
    oiPirate: Result := 'PirateClan';
  else
    Result := 'None';
  end;
end;

function OwnerFromInternalName(const Name: WideString): TOwnerId;
begin
  if Name = 'Maloc' then
  begin
    Result := oiMaloc;
    Exit;
  end;
  if Name = 'Peleng' then
  begin
    Result := oiPeleng;
    Exit;
  end;
  if Name = 'People' then
  begin
    Result := oiHuman;
    Exit;
  end;
  if Name = 'Fei' then
  begin
    Result := oiFeyan;
    Exit;
  end;
  if Name = 'Gaal' then
  begin
    Result := oiGaal;
    Exit;
  end;
  if Name = 'Kling' then
  begin
    Result := oiDominator;
    Exit;
  end;
  if Name = 'PirateClan' then
  begin
    Result := oiPirate;
    Exit;
  end;
  Result := oiUninhabited;
end;

function IsKnownOwnerName(const Name: WideString): Boolean;
begin
  Result := False;
  if not Result then
    Result := Name = 'Maloc';
  if not Result then
    Result := Name = 'Peleng';
  if not Result then
    Result := Name = 'People';
  if not Result then
    Result := Name = 'Fei';
  if not Result then
    Result := Name = 'Gaal';
  if not Result then
    Result := Name = 'Kling';
  if not Result then
    Result := Name = 'None';
  if not Result then
    Result := Name = 'PirateClan';
end;

function NumberToRace(Value: Integer): TOwnerId;
begin
  case Value of
    0: Result := oiMaloc;
    1: Result := oiPeleng;
    2: Result := oiHuman;
    3: Result := oiFeyan;
    4: Result := oiGaal;
  else
    begin
      raise Exception.Create('Error in NumberToRace');
      Result := oiMaloc;
    end;
  end;
end;

function MatchesOwnerName(OwnerId: TOwnerId; const Name: WideString): Boolean;
begin
  Result := not IsKnownOwnerName(Name) or (Name = OwnerToSys(OwnerId));
end;

function PickRandomEquipmentOwner(RandomValue: Dword): TOwnerId;
begin
  Result := TOwnerId(SeededRandomIntRange(0, 4, RandomValue));
end;

function MatchesCareerName(Career: TRangerCareer; const Names: WideString): Boolean;
begin
  if (Pos(CareerTuning[Career].Name, Names) > 0) or (Names = 'Any') or (Names = '') then
    Result := True
  else
    Result := False;
end;

function SysToReward(const Name: WideString): TAwardKind;
begin
  if Name = 'ForLiberationSystem' then
    Result := atLiberation
  else if Name = 'ForAccomplishment' then
    Result := atAccomplishment
  else if Name = 'ForSecretMission' then
    Result := atSecretMission
  else if Name = 'ForCowardice' then
    Result := atCowardice
  else if Name = 'ForPerfidy' then
    Result := atPerfidy
  else if Name = 'ForPlanetBattle' then
    Result := atPlanetBattle
  else
  begin
    RaiseWideMessage('Error in SysToReward');
    Result := atPerfidy;
  end;
end;

function SysToShipType(const Name: WideString): TShipType;
var
  Kind: TShipType;
begin
  for Kind := Low(TShipType) to High(TShipType) do
    if ShipTypeNames[Kind].Name = Name then
    begin
      Result := Kind;
      Exit;
    end;
  RaiseWideMessage('Error in SysToShipType');
  Result := stKling;
end;

function GetAverageItemSize(ItemType: TItemType): Integer;
begin
  case ItemType of
    t_ArtefactHull: Result := 12;
    t_ArtefactFuel: Result := 4;
    t_ArtefactSpeed: Result := 12;
    t_ArtefactPower: Result := 7;
    t_ArtefactRadar: Result := 10;
    t_ArtefactScaner: Result := 8;
    t_ArtefactDroid: Result := 10;
    t_ArtefactNano: Result := 3;
    t_ArtefactHook: Result := 3;
    t_ArtefactDef: Result := 12;
    t_ArtefactAnalyzer: Result := 5;
    t_ArtefactMiniExpl: Result := 10;
    t_ArtefactAntigrav: Result := 20;
    t_ArtefactTransmitter: Result := 3;
    t_ArtefactBomb: Result := 5;
    t_ArtefactTranclucator: Result := 50;
    t_ArtDefToEnergy: Result := 5;
    t_ArtEnergyPulse: Result := 8;
    t_ArtEnergyDef: Result := 5;
    t_ArtSplinter: Result := 10;
    t_ArtDecelerate: Result := 5;
    t_ArtMissileDef: Result := 6;
    t_ArtForsage: Result := 6;
    t_ArtWeaponToSpeed: Result := 7;
    t_ArtGiperJump: Result := 5;
    t_ArtBlackHole: Result := 3;
    t_ArtDefToArms1: Result := 9;
    t_ArtDefToArms2: Result := 7;
    t_ArtArtefactor: Result := 3;
    t_ArtBio: Result := 2;
    t_ArtPDTurret: Result := 15;
    t_ArtFastRacks: Result := 10;
    t_Hull: Result := HullBaseSize;
    t_FuelTanks: Result := FuelTanksBaseSize;
    t_Engine: Result := EngineBaseSize;
    t_Radar: Result := RadarBaseSize;
    t_Scaner: Result := ScannerBaseSize;
    t_RepairRobot: Result := RepairRobotBaseSize;
    t_CargoHook: Result := CargoHookBaseSize;
    t_DefGenerator: Result := DefGeneratorBaseSize;
    t_CustomWeapon:
    begin
      // Preserve the original x86 lookup's adjacent-field behavior explicitly.
      // GetAverageItemSize: October 2025 $7DDFA4 (load at $7DE24A),
      //                     August 2026 $82EC68 (load at $82EF0E).
      // WeaponInfos has 18 records of $78 bytes, but type 68 reads a nineteenth
      // record's AverageSize at offset $18: $88A9E8 / $88BDD0 respectively.
      // This is 24 bytes beyond the table: four hull/wear integers, followed
      // by GoodsMarketBase[Food].InternalName, DisplayName, then TradeName.
      // The value read is therefore the TradeName WideString POINTER, not a
      // weapon size or a character from the string. InitializeGameplayConfig
      // copies this cached goods table once, after localizing the goods names.
      // Before that copy (or with an empty trade name), the pointer is zero.
      //
      // Retain its signed 32-bit interpretation, taking the low 32 pointer
      // bits on wider targets. The original result is address-dependent;
      // there is no fixed numeric value shared by different processes.
      // BuildNonCivilTreasureHintText also retains its original wrapping
      // 32-bit cost multiplication. Using the custom weapon's actual size
      // here would change that historical treasure-hint behavior.
      Result := LongInt(Cardinal(PtrUInt(Pointer(GoodsMarketBase[Ord(t_Food)].TradeName))));
    end;
  else
    if ItemType in [t_IndustrialLaser..t_Lirecron] then
      Result := WeaponInfos[ItemType].AverageSize
    else
    begin
      Exception
          .Create('Error ItemAverageSize'); // Native allocates the exception without raising it.
      Result := 0;
    end;
  end;
end;

function GenerateValueForSizeLevel(
    Level: Byte;
    Minimum, Maximum: Integer;
    VariationPercent: Byte;
    Seed: Cardinal
): Integer;
var
  Center, Bound: Integer;
begin
  case Level of
    0:
    begin
      Result := 0;
      Exit
    end;
    1: Center := Minimum;
    2: Center := ((Minimum + Maximum) div 2 + Minimum) div 2;
    3: Center := (Minimum + Maximum) div 2;
    4: Center := ((Minimum + Maximum) div 2 + Maximum) div 2;
    5: Center := Maximum;
  else
    Center := (Minimum + Maximum) div 2;
  end;
  if SeededRandomUnitFloat(Seed + Cardinal(Center)) < 0.5 then
  begin
    Bound := Min(Maximum, Round(Center / 100 * VariationPercent + Center));
    Result := SeededRandomIntRange(Center, Bound, Seed);
  end
  else
  begin
    Bound := Max(Minimum, Round(Center - Center / 100 * VariationPercent));
    Result := SeededRandomIntRange(Bound, Center, Seed);
  end;
end;

function SizeTagToLevel(const Tag: WideString): Byte;
begin
  if Tag = 'Zero' then
    Result := 0
  else if Tag = 'Mini' then
    Result := 1
  else if Tag = 'Small' then
    Result := 2
  else if Tag = 'Average' then
    Result := 3
  else if Tag = 'Big' then
    Result := 4
  else if Tag = 'Huge' then
    Result := 5
  else
    Result := 0;
end;

function ShipToHullType(Ship: TObject): THullType;
begin
  Result := htRanger;
  if Ship is TRanger then
    Result := htRanger
  else if Ship is TWarrior then
    Result := htWarrior
  else if Ship is TPirate then
    Result := htPirate
  else if Ship is TTransport then
  begin
    if TTransport(Ship).TransportType = ttTransport then
      Result := htTransport
    else if TTransport(Ship).TransportType = ttLiner then
      Result := htLiner
    else
      Result := htDiplomat;
  end
  else if Ship is TKling then
    Result := htKling
  else if Ship is TTranclucator then
    Result := htTranclucator
  else if Ship is TRuins then
    Result := htStation
  else
    RaiseWideMessage('ShipToSShipType');
end;

function RelationValueToLevel(Value: Byte): TRelationLevel;
begin
  case Value of
    0..RelationBadMin - 1: Result := rlHostile;
    RelationBadMin..RelationNormalMin - 1: Result := rlBad;
    RelationNormalMin..RelationGoodMin - 1: Result := rlNormal;
    RelationGoodMin..RelationExcellentMin - 1: Result := rlGood;
    RelationExcellentMin..100: Result := rlExcellent;
  else
    Result := rlNormal;
  end;
end;

function ItemTypeToSlotKind(ItemType: TItemType): TShipSlotKind;
begin
  case ItemType of
    t_FuelTanks: Result := sskFuelTanks;
    t_Engine: Result := sskEngine;
    t_Radar: Result := sskRadar;
    t_Scaner: Result := sskScanner;
    t_RepairRobot: Result := sskRepairRobot;
    t_CargoHook: Result := sskCargoHook;
    t_DefGenerator: Result := sskDefGenerator;
  else
    if ItemType in [t_IndustrialLaser..t_CustomWeapon] then
      Result := sskWeapon
    else if ItemType in [t_Artefact..t_ArtFastRacks] then
      Result := sskArtefact
    else
      Result := sskUnsupported;
  end;
end;

function LocalizedText(const Path: WideString): WideString;
var
  I, Count: Integer;
begin
  Result := '';
  Count := LanguageDataConfig.CountParamsByPath(Path);
  for I := 0 to Count - 1 do
  begin
    if Result <> '' then
      Result := Result + #13#10;
    Result := Result + LanguageDataConfig.GetParamByPath(Path + ':' + IntToStr(I));
  end;
  if FindTextPosW('<', Result) > 0 then
  begin
    Result := ReplaceAllWideString(Result, '<br>', #13#10);
    Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    if GetPlayer <> nil then
      Result :=
          ReplaceAllWideString(
              Result,
              '<Player>',
              TextHighlightColorTag + GetPlayer.Name + EndColorTag
          );
  end;
end;

function LocalizedColorText(const Path: WideString): WideString;
var
  I, Count: Integer;
begin
  Result := '';
  Count := LanguageDataConfig.CountParamsByPath(Path);
  for I := 0 to Count - 1 do
  begin
    if Result <> '' then
      Result := Result + #13#10;
    Result := Result + LanguageDataConfig.GetParamByPath(Path + ':' + IntToStr(I));
  end;
  if FindTextPosW('<', Result) > 0 then
  begin
    Result := ReplaceAllWideString(Result, '<br>', #13#10);
    Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    if GetPlayer <> nil then
      Result :=
          ReplaceAllWideString(
              Result,
              '<Player>',
              TextHighlightColorTag + GetPlayer.Name + EndColorTag
          );
    Result := ReplaceAllWideString(Result, '<clr>', TextHighlightColorTag);
    Result := ReplaceAllWideString(Result, '<clrEnd>', EndColorTag);
  end;
end;

procedure ExpandLocalizedTextMarkup(var Text: WideString);
begin
  if FindTextPosW('<', Text) > 0 then
  begin
    Text := ReplaceAllWideString(Text, '<br>', #13#10);
    Text := ReplaceAllWideString(Text, '<ll>', #13#10' '#13#10);
    if GetPlayer <> nil then
      Text :=
          ReplaceAllWideString(
              Text,
              '<Player>',
              TextHighlightColorTag + GetPlayer.Name + EndColorTag
          );
    Text := ReplaceAllWideString(Text, '<clr>', TextHighlightColorTag);
    Text := ReplaceAllWideString(Text, '<clrEnd>', EndColorTag);
  end;
end;

procedure ExpandLocalizedTextMarkupAndPrefixLines(var Text: WideString);
begin
  if FindTextPosW('<', Text) > 0 then
  begin
    Text := ReplaceAllWideString(Text, '<br>', #13#10);
    Text := ReplaceAllWideString(Text, '<ll>', #13#10' '#13#10);
    if GetPlayer <> nil then
      Text :=
          ReplaceAllWideString(
              Text,
              '<Player>',
              TextHighlightColorTag + GetPlayer.Name + EndColorTag
          );
    Text := ReplaceAllWideString(Text, '<clr>', TextHighlightColorTag);
    Text := ReplaceAllWideString(Text, '<clrEnd>', EndColorTag);
  end;
  Text := LocalizedTextLinePrefix + TrimWideString(Text);
  Text := ReplaceAllWideString(Text, #13#10, #13#10 + LocalizedTextLinePrefix);
end;

function PickLocalizedTextVariant(const Path: WideString; SeedOffset: Integer): WideString;
var
  Count, I: Integer;
  Variants: array[0..9] of WideString;
begin
  Count := 0;
  Variants[Count] := LocalizedColorText(Path);
  if Variants[Count] <> '' then
    Inc(Count);
  I := 1;
  repeat
    Variants[Count] := LocalizedColorText(Path + IntToStr(Count));
    if Variants[Count] <> '' then
      Inc(Count);
    Inc(I);
  until I > 9;
  if Count = 0 then
    Result := 'String: ' + WrapTextInColor(Path, TextHighlightColorTag) + ' is unavailable'
  else if Count = 1 then
    Result := Variants[0]
  else
  begin
    Count := SeededRandomIntRange(0, Count - 1, (Galaxy.CurrentTurn + SeedOffset) div 10);
    Result := Variants[Count];
  end;
end;

function FindMicroModuleTemplateByCustomTag(CustomTag: WideString): Integer;
var
  I: Integer;
begin
  for I := 0 to High(MicroModuleTemplates) do
    if MicroModuleTemplates[I].CustomTag = CustomTag then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

procedure LoadArtefactConfiguration;
const
  ArtefactTypes = [0..79] - [0..9] - [42..79];
var
  Index: Integer;
  Config, Block: TBlockParEC;
  ItemName: WideString;
  Kind: TItemType;
  CanBeABDrop, CanBeTreasure, CanBeReward: Boolean;
  ABDropCount, TreasureCount, RewardCount, AnyCount: Integer;
begin
  Config := LanguageDataConfig.GetBlockByPath('Artefacts.NumericValues');
  HullArtefactArmor := StrToInt(AnsiString(Config.GetParam('kArtefactHull')));
  HullArtefactStatusDecayFactor := 1.5;
  FuelArtefactBase := StrToInt(AnsiString(Config.GetParam('kArtefactFuel')));
  SpeedArtefactFactor := ExtractDecimalToSingleW(Config.GetParam('kArtefactSpeed'));
  EngineArtefactBase := StrToInt(AnsiString(Config.GetParam('kArtefactPower')));
  RadarArtefactRange := StrToInt(AnsiString(Config.GetParam('kArtefactRadar')));
  ScannerArtefactPower := StrToInt(AnsiString(Config.GetParam('kArtefactScaner')));
  DroidArtefactRepair := StrToInt(AnsiString(Config.GetParam('kArtefactDroid')));
  DroidArtefactWear := ExtractDecimalToSingleW(Config.GetParam('kArtefactDroidWear'));
  DroidArtefactStatusDecayFactor := 1.5;
  NanoArtefactRepair := StrToInt(AnsiString(Config.GetParam('kArtefactNano')));
  DefenseArtefactBonus := ExtractDecimalToSingleW(Config.GetParam('kArtefactDef'));
  AntigravityArtefactMassFactor := ExtractDecimalToSingleW(Config.GetParam('kArtefactAntigrav'));
  CargoHookArtefactPower := StrToInt(AnsiString(Config.GetParam('kArtefactHook')));
  CargoHookArtefactRange := StrToInt(AnsiString(Config.GetParam('kArtefactHookRaduis')));
  CargoHookArtefactSpeed := StrToInt(AnsiString(Config.GetParam('kArtefactHookSpeed')));
  WeaponToSpeedArtefactBonus := StrToInt(AnsiString(Config.GetParam('kArtWeaponToSpeed')));
  DefenseToEnergyUpperFactor := ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyUp'));
  DefenseToEnergyMinimumFactor := ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyMin'));
  DefenseToEnergyPenalty := ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyPenalty'));
  DefenseToWeaponPenalty := ExtractDecimalToSingleW(Config.GetParam('kArtDefToArms1Penalty'));
  EnergyPulseArtefactFactor := ExtractDecimalToSingleW(Config.GetParam('kArtEnergyPulse'));
  EnergyPulseArtefactChance := ExtractDecimalToSingleW(Config.GetParam('kArtEnergyPulseChance'));
  SplinterArtefactFactor := ExtractDecimalToSingleW(Config.GetParam('kArtSplinter'));
  HyperJumpArtefactRange := StrToInt(AnsiString(Config.GetParam('kArtGiperJump')));
  StarHeatArtefactReduction := ExtractDecimalToSingleW(Config.GetParam('kArtPowerSunProtection'));
  ExtraMissileChance := ExtractDecimalToSingleW(Config.GetParam('kArtFastRacksChance'));
  AfterburnerArtefactWearFactor := ExtractDecimalToSingleW(Config.GetParam('kArtForsage'));
  PointDefensePassCount := StrToInt(AnsiString(Config.GetParam('kPDTurretCountShots')));
  PointDefenseBaseRange := StrToInt(AnsiString(Config.GetParam('kPDTurretRange')));
  HullArtefactBoostArmor := StrToInt(AnsiString(Config.GetParam('kArtefactHullEx')));
  HullArtefactBoostStatusDecay := 0.5;
  FuelArtefactBoost := StrToInt(AnsiString(Config.GetParam('kArtefactFuelEx')));
  SpeedArtefactBoostFactor := ExtractDecimalToSingleW(Config.GetParam('kArtefactSpeedEx'));
  EngineArtefactBoost := StrToInt(AnsiString(Config.GetParam('kArtefactPowerEx')));
  RadarArtefactBoostRange := StrToInt(AnsiString(Config.GetParam('kArtefactRadarEx')));
  ScannerArtefactBoostPower := StrToInt(AnsiString(Config.GetParam('kArtefactScanerEx')));
  DroidArtefactBoostRepair := StrToInt(AnsiString(Config.GetParam('kArtefactDroidEx')));
  DroidArtefactBoostWear := ExtractDecimalToSingleW(Config.GetParam('kArtefactDroidWearEx'));
  DroidArtefactBoostStatusDecay := 0.5;
  NanoArtefactBoostRepair := StrToInt(AnsiString(Config.GetParam('kArtefactNanoEx')));
  DefenseArtefactBoost := ExtractDecimalToSingleW(Config.GetParam('kArtefactDefEx'));
  AntigravityArtefactBoostFactor := ExtractDecimalToSingleW(Config.GetParam('kArtefactAntigravEx'));
  CargoHookArtefactBoostPower := StrToInt(AnsiString(Config.GetParam('kArtefactHookEx')));
  CargoHookArtefactBoostRange := StrToInt(AnsiString(Config.GetParam('kArtefactHookRaduisEx')));
  CargoHookArtefactBoostSpeed := StrToInt(AnsiString(Config.GetParam('kArtefactHookSpeedEx')));
  WeaponToSpeedArtefactBoost := StrToInt(AnsiString(Config.GetParam('kArtWeaponToSpeedEx')));
  DefenseToEnergyUpperBoost := ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyUpEx'));
  DefenseToEnergyMinimumBoost := ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyMinEx'));
  DefenseToEnergyBoostPenalty :=
      ExtractDecimalToSingleW(Config.GetParam('kArtDefToEnergyPenaltyEx'));
  EnergyPulseArtefactBoostFactor := ExtractDecimalToSingleW(Config.GetParam('kArtEnergyPulseEx'));
  SplinterArtefactBoostFactor := ExtractDecimalToSingleW(Config.GetParam('kArtSplinterEx'));
  HyperJumpArtefactBoostRange := StrToInt(AnsiString(Config.GetParam('kArtGiperJumpEx')));
  StarHeatArtefactBoostReduction :=
      ExtractDecimalToSingleW(Config.GetParam('kArtPowerSunProtectionEx'));
  ExtraMissileBoostChance := ExtractDecimalToSingleW(Config.GetParam('kArtFastRacksChanceEx'));
  AfterburnerArtefactBoostWearFactor := ExtractDecimalToSingleW(Config.GetParam('kArtForsageEx'));
  PointDefenseBonusRange := StrToInt(AnsiString(Config.GetParam('kPDTurretRangeEx')));
  MinTransmitterPower := StrToInt(AnsiString(Config.GetParam('MinTransmitterPower')));
  AverageTransmitterPower := StrToInt(AnsiString(Config.GetParam('AverageTransmitterPower')));
  MaxTransmitterPower := StrToInt(AnsiString(Config.GetParam('MaxTransmitterPower')));
  TransmitterSameSystemPenalty :=
      StrToInt(AnsiString(Config.GetParam('kTransmitterPenaltySameSystem')));
  TransmitterAnySystemPenalty :=
      StrToInt(AnsiString(Config.GetParam('kTransmitterPenaltyAnySystem')));
  TransmitterSameSystemPenaltyTurns :=
      StrToInt(AnsiString(Config.GetParam('kTransmitterPenaltySameSystemDuration')));
  TransmitterAnySystemPenaltyTurns :=
      StrToInt(AnsiString(Config.GetParam('kTransmitterPenaltyAnySystemDuration')));
  SubportalRewardPenalty := StrToInt(AnsiString(Config.GetParam('kSubportalPenalty')));
  SubportalRewardPenaltyTurns := StrToInt(AnsiString(Config.GetParam('kSubportalPenaltyDuration')));
  ItemExplosionBonusDamage := StrToInt(AnsiString(Config.GetParam('BombPower')));
  BombMinimumDamage := StrToInt(AnsiString(Config.GetParam('BombPowerMin')));
  BombMaximumDamage := StrToInt(AnsiString(Config.GetParam('BombPowerMax')));
  BombDamageRadius := StrToInt(AnsiString(Config.GetParam('BombRadius')));
  ItemExplosionRadiusSquared := (BombDamageRadius * BombDamageRadius);
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  Config := LanguageDataConfig.GetBlockByPath('Artefacts');
  for Index := 1 to CountItemTypesInMask(ArtefactTypes) do
  begin
    Kind := TItemType(GetItemTypeFromMask([0..79] - [0..9] - [42..79], Index));
    Block := Config.GetBlock(ItemTypeNames[Kind]);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      if CanBeABDrop then
        Inc(ABDropCount);
      if CanBeTreasure then
        Inc(TreasureCount);
      if CanBeReward then
        Inc(RewardCount);
      Inc(AnyCount);
    end;
  end;
  SetLength(ArtefactLootPools[0], ABDropCount);
  SetLength(ArtefactLootPools[1], TreasureCount);
  SetLength(ArtefactLootPools[2], RewardCount);
  SetLength(ArtefactLootPools[3], AnyCount);
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  for Index := 1 to CountItemTypesInMask(ArtefactTypes) do
  begin
    Kind := TItemType(GetItemTypeFromMask([0..79] - [0..9] - [42..79], Index));
    Block := Config.GetBlock(ItemTypeNames[Kind]);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') <= 0)
            or (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      if CanBeABDrop then
      begin
        ArtefactLootPools[0][ABDropCount] := Kind;
        Inc(ABDropCount);
      end;
      if CanBeTreasure then
      begin
        ArtefactLootPools[1][TreasureCount] := Kind;
        Inc(TreasureCount);
      end;
      if CanBeReward then
      begin
        ArtefactLootPools[2][RewardCount] := Kind;
        Inc(RewardCount);
      end;
      ArtefactLootPools[3][AnyCount] := Kind;
      Inc(AnyCount);
    end;
  end;
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  Config := LanguageDataConfig.GetBlockByPath('Artefacts.CustomArtefacts');
  for Index := 0 to Config.GetBlockCount - 1 do
  begin
    Block := Config.GetBlockByIndex(Index);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      if CanBeABDrop then
        Inc(ABDropCount);
      if CanBeTreasure then
        Inc(TreasureCount);
      if CanBeReward then
        Inc(RewardCount);
      Inc(AnyCount);
    end;
  end;
  SetLength(CustomArtefactLootPools[0], ABDropCount);
  SetLength(CustomArtefactLootPools[1], TreasureCount);
  SetLength(CustomArtefactLootPools[2], RewardCount);
  SetLength(CustomArtefactLootPools[3], AnyCount);
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  for Index := 0 to Config.GetBlockCount - 1 do
  begin
    Block := Config.GetBlockByIndex(Index);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      ItemName := Config.GetBlockNameByIndex(Index);
      if CanBeABDrop then
      begin
        CustomArtefactLootPools[0][ABDropCount] := ItemName;
        Inc(ABDropCount);
      end;
      if CanBeTreasure then
      begin
        CustomArtefactLootPools[1][TreasureCount] := ItemName;
        Inc(TreasureCount);
      end;
      if CanBeReward then
      begin
        CustomArtefactLootPools[2][RewardCount] := ItemName;
        Inc(RewardCount);
      end;
      CustomArtefactLootPools[3][AnyCount] := ItemName;
      Inc(AnyCount);
    end;
  end;
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  Config := LanguageDataConfig.GetBlockByPath('UselessItems');
  for Index := 0 to Config.GetBlockCount - 1 do
  begin
    Block := Config.GetBlockByIndex(Index);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      if CanBeABDrop then
        Inc(ABDropCount);
      if CanBeTreasure then
        Inc(TreasureCount);
      if CanBeReward then
        Inc(RewardCount);
      Inc(AnyCount);
    end;
  end;
  SetLength(UselessItemLootPools[0], ABDropCount);
  SetLength(UselessItemLootPools[1], TreasureCount);
  SetLength(UselessItemLootPools[2], RewardCount);
  SetLength(UselessItemLootPools[3], AnyCount);
  ABDropCount := 0;
  TreasureCount := 0;
  RewardCount := 0;
  AnyCount := 0;
  for Index := 0 to Config.GetBlockCount - 1 do
  begin
    Block := Config.GetBlockByIndex(Index);
    CanBeABDrop :=
        (Block.CountParams('CanBeABDrop') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeABDrop')) > 0);
    CanBeTreasure :=
        (Block.CountParams('CanBeTreasure') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeTreasure')) > 0);
    CanBeReward :=
        (Block.CountParams('CanBeReward') > 0)
            and (ExtractDigitsToIntW(Block.GetParam('CanBeReward')) > 0);
    if CanBeABDrop or CanBeTreasure or CanBeReward then
    begin
      ItemName := Config.GetBlockNameByIndex(Index);
      if CanBeABDrop then
      begin
        UselessItemLootPools[0][ABDropCount] := ItemName;
        Inc(ABDropCount);
      end;
      if CanBeTreasure then
      begin
        UselessItemLootPools[1][TreasureCount] := ItemName;
        Inc(TreasureCount);
      end;
      if CanBeReward then
      begin
        UselessItemLootPools[2][RewardCount] := ItemName;
        Inc(RewardCount);
      end;
      UselessItemLootPools[3][AnyCount] := ItemName;
      Inc(AnyCount);
    end;
  end;
end;

procedure LoadDamageSkillQuestMarketConfiguration;
var
  Level, Cost: Integer;
  Block: TBlockParEC;
  Values: WideString;
  QuestKind: TQuestType;
  Skill: TPilotSkill;
begin
  Block := LanguageDataConfig.GetBlockByPath('Asteroid');
  AsteroidMinDamageFactor :=
      StrToInt(AnsiString(Block.GetParam('kAsteroidMinDamagePercent'))) * 0.01;
  AsteroidMaxDamageFactor :=
      StrToInt(AnsiString(Block.GetParam('kAsteroidMaxDamagePercent'))) * 0.01;
  AsteroidMinDamageFactorWithDefGenerator :=
      StrToInt(AnsiString(Block.GetParam('kAsteroidMinDamagePercentDef'))) * 0.01;
  AsteroidMaxDamageFactorWithDefGenerator :=
      StrToInt(AnsiString(Block.GetParam('kAsteroidMaxDamagePercentDef'))) * 0.01;
  TotalSkillTrainingCost := 0;
  for Skill := Low(TPilotSkill) to High(TPilotSkill) do
  begin
    SkillTrainingCosts[0, Skill] := 0;
    Values :=
        LanguageDataConfig.GetBlockByPath('Skills.' + SkillConfigNames[Skill]).GetParam('Points');
    for Level := 1 to 6 do
    begin
      Cost := StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - 1, ',')));
      SkillTrainingCosts[Level, Skill] := Cost;
      Inc(TotalSkillTrainingCost, Cost);
    end;
  end;
  Values := LanguageDataConfig.GetBlockByPath('Quest').GetParam('QuestPoints');
  for QuestKind := Low(TQuestType) to High(TQuestType) do
    QuestExperience[QuestKind] :=
        StrToInt(
            AnsiString(ExtractDelimitedPartW(Values, Ord(QuestKind) - Ord(Low(TQuestType)), ','))
        );
  Values := LanguageDataConfig.GetBlockByPath('Quest').GetParam('QuestTurns');
  for QuestKind := Low(TQuestType) to High(TQuestType) do
    QuestTuning[QuestKind].BaseDuration :=
        StrToInt(
            AnsiString(ExtractDelimitedPartW(Values, Ord(QuestKind) - Ord(Low(TQuestType)), ','))
        );
  Values := LanguageDataConfig.GetBlockByPath('Quest').GetParam('QuestMoneyBase');
  for QuestKind := Low(TQuestType) to High(TQuestType) do
    QuestTuning[QuestKind].BaseRewardMoney :=
        StrToInt(
            AnsiString(ExtractDelimitedPartW(Values, Ord(QuestKind) - Ord(Low(TQuestType)), ','))
        );
  Values := LanguageDataConfig.GetBlockByPath('Quest').GetParam('QuestMoneyPerc');
  for QuestKind := Low(TQuestType) to High(TQuestType) do
    QuestTuning[QuestKind].RewardCapitalPercent :=
        StrToInt(
            AnsiString(ExtractDelimitedPartW(Values, Ord(QuestKind) - Ord(Low(TQuestType)), ','))
        );
  Block := LanguageDataConfig.GetBlockByPath('Items.Goods');
  GoodsInflationMin := ExtractDecimalToSingleW(Block.GetParam('kInflationMin'));
  GoodsInflationMax := ExtractDecimalToSingleW(Block.GetParam('kInflationMax'));
  GoodsStockMin := ExtractDecimalToSingleW(Block.GetParam('kStockMin'));
  GoodsStockMax := ExtractDecimalToSingleW(Block.GetParam('kStockMax'));
  if Block.CountParams('InflationStartTurn') > 0 then
    GoodsInflationStartTurn := ExtractDigitsToIntW(Block.GetParam('InflationStartTurn'))
  else
    GoodsInflationStartTurn := 1000;
  if Block.CountParams('InflationEndTurn') > 0 then
    GoodsInflationEndTurn := ExtractDigitsToIntW(Block.GetParam('InflationEndTurn'))
  else
    GoodsInflationEndTurn := 10000;
end;

procedure LoadEquipmentConfiguration;
var
  Level: Byte;
  Block: TBlockParEC;
  Values: WideString;
  DamageKind: TWeaponDamageClass;
  Owner: TOwnerId;
  HullKind: THullType;
begin
  Block := LanguageDataConfig.GetBlockByPath('Items.Hull');
  HullBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  HullCapacityScale := HullBaseSize / 500;
  Values := Block.GetParam('mAlloy');
  for Level := Low(HullLevelStats) to High(HullLevelStats) do
    HullLevelStats[Level].Armor :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(HullLevelStats), ',')));
  for DamageKind := Low(TWeaponDamageClass) to High(TWeaponDamageClass) do
  begin
    Values := Block.GetParam('mFragilityByLevel' + WeaponDamageClasses[DamageKind].Name);
    for Level := Low(HullLevelStats) to High(HullLevelStats) do
      HullLevelStats[Level].Fragility[DamageKind] :=
          ExtractDecimalToSingleW(ExtractDelimitedPartW(Values, Level - Low(HullLevelStats), ','));
    Values := Block.GetParam('mFragilityByOwner' + WeaponDamageClasses[DamageKind].Name);
    for Owner := Low(TOwnerId) to High(TOwnerId) do
      HullFragilityByOwner[DamageKind, Owner] :=
          ExtractDecimalToSingleW(
              ExtractDelimitedPartW(Values, Ord(Owner) - Ord(Low(TOwnerId)), ',')
          );
  end;
  Values := Block.GetParam('mFragilityByShipType');
  for HullKind := Low(HullFragilityByType) to High(HullFragilityByType) do
    HullFragilityByType[HullKind] :=
        ExtractDecimalToSingleW(
            ExtractDelimitedPartW(Values, Ord(HullKind) - Ord(Low(HullFragilityByType)), ',')
        );
  Block := LanguageDataConfig.GetBlockByPath('Items.FuelTanks');
  FuelTanksBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mCapacity');
  for Level := Low(FuelCapacityByLevel) to High(FuelCapacityByLevel) do
    FuelCapacityByLevel[Level] :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(FuelCapacityByLevel), ',')));
  Block := LanguageDataConfig.GetBlockByPath('Items.Engine');
  EngineBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mSpeed');
  for Level := Low(EngineLevelStats) to High(EngineLevelStats) do
    EngineLevelStats[Level].Speed :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(EngineLevelStats), ',')));
  Values := Block.GetParam('mJump');
  for Level := Low(EngineLevelStats) to High(EngineLevelStats) do
    EngineLevelStats[Level].JumpRange :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(EngineLevelStats), ',')));
  AfterburnerSpeedFactor := ExtractDecimalToSingleW(Block.GetParam('ForsageCoef'));
  Block := LanguageDataConfig.GetBlockByPath('Items.RepairRobot');
  RepairRobotBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mRepair');
  for Level := Low(RepairRobotLevelPoints) to High(RepairRobotLevelPoints) do
    RepairRobotLevelPoints[Level] :=
        StrToInt(
            AnsiString(ExtractDelimitedPartW(Values, Level - Low(RepairRobotLevelPoints), ','))
        );
  Block := LanguageDataConfig.GetBlockByPath('Items.DefGenerator');
  DefGeneratorBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mDef');
  for Level := Low(DefGeneratorLevelFactors) to High(DefGeneratorLevelFactors) do
    DefGeneratorLevelFactors[Level] :=
        1
            - ExtractDecimalToSingleW(
                ExtractDelimitedPartW(Values, Level - Low(DefGeneratorLevelFactors), ','));
  Block := LanguageDataConfig.GetBlockByPath('Items.Radar');
  RadarBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mRadius');
  for Level := Low(RadarLevelRanges) to High(RadarLevelRanges) do
    RadarLevelRanges[Level] :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(RadarLevelRanges), ',')));
  Block := LanguageDataConfig.GetBlockByPath('Items.Scaner');
  ScannerBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Block := LanguageDataConfig.GetBlockByPath('Items.CargoHook');
  CargoHookBaseSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
  Values := Block.GetParam('mMass');
  for Level := Low(CargoHookLevelStats) to High(CargoHookLevelStats) do
    CargoHookLevelStats[Level].PickupPower :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(CargoHookLevelStats), ',')));
  Values := Block.GetParam('mRadius');
  for Level := Low(CargoHookLevelStats) to High(CargoHookLevelStats) do
    CargoHookLevelStats[Level].Range :=
        StrToInt(AnsiString(ExtractDelimitedPartW(Values, Level - Low(CargoHookLevelStats), ',')));
  Values := Block.GetParam('mSpeedFar');
  for Level := Low(CargoHookLevelStats) to High(CargoHookLevelStats) do
    CargoHookLevelStats[Level].MinPullSpeed :=
        ExtractDecimalToSingleW(
            ExtractDelimitedPartW(Values, Level - Low(CargoHookLevelStats), ',')
        );
  Values := Block.GetParam('mSpeedClose');
  for Level := Low(CargoHookLevelStats) to High(CargoHookLevelStats) do
    CargoHookLevelStats[Level].MaxPullSpeed :=
        ExtractDecimalToSingleW(
            ExtractDelimitedPartW(Values, Level - Low(CargoHookLevelStats), ',')
        );
end;

procedure LoadWeaponConfiguration;
const
  WeaponTypes = [0..79] - [0..49, 68..79];
var
  Level, Index: Integer;
  Block: TBlockParEC;
  Values: WideString;
  Kind, DamageKind: Byte;
begin
  for Index := 1 to CountItemTypesInMask(WeaponTypes) do
  begin
    Kind := GetItemTypeFromMask(WeaponTypes, Index);
    Block := LanguageDataConfig.GetBlockByPath('Items.Weapon.Stats.' + IntToStr(Kind + 1 - 50));
    with WeaponInfos[TItemType(Kind)] do
    begin
      ItemType := TItemType(Kind);
      ConfigName := ItemTypeNames[TItemType(Kind)];
      TechLevel := StrToInt(AnsiString(Block.GetParam('TechLevel')));
      CostFactor := ExtractDecimalToSingleW(Block.GetParam('kCost'));
      MinDamage := StrToInt(AnsiString(Block.GetParam('MinDamage')));
      MaxDamage := StrToInt(AnsiString(Block.GetParam('MaxDamage')));
      AverageSize := StrToInt(AnsiString(Block.GetParam('AverageSize')));
      AverageRange := StrToInt(AnsiString(Block.GetParam('AverageRadius')));
      ShotSpeedPercent := StrToInt(AnsiString(Block.GetParam('Speed')));
      if Block.CountParams('SecondaryDamageRadius') > 0 then
        SecondaryDamageRadius := StrToInt(AnsiString(Block.GetParam('SecondaryDamageRadius')))
      else
        SecondaryDamageRadius := 0;
      MiningFactor := StrToFloat(AnsiString(Block.GetParam('MiningFactor')));
      ArcadeWeaponType := Kind;
      Availability := waFree;
      DamageFlags := [];
      Values := Block.GetParam('DamageSet');
      for DamageKind := Low(WeaponDamageFlagNames) to High(WeaponDamageFlagNames) do
        if not (DamageKind in [Ord(dkDecelerateA), Ord(dkDecelerateAEx), Ord(dkNonLethal)])
            and (Pos(WeaponDamageFlagNames[DamageKind], Values) > 0) then
          Include(DamageFlags, TDamageKind(DamageKind));
      ShotType := wstNormal;
      ShotCount := 1;
      Values := Block.GetParam('ShotType');
      if Pos('Normal', Values) > 0 then
      begin
      end
      else if Pos('Splash', Values) > 0 then
        ShotType := wstSplash
      else if Pos('Exploder', Values) > 0 then
        ShotType := wstExploder
      else if Pos('AreaDamage', Values) > 0 then
        ShotType := wstAreaDamage
      else if Pos('Torpedo', Values) > 0 then
        ShotType := wstTorpedo
      else if Pos('Missile', Values) > 0 then
        ShotType := wstMissile
      else if Pos('Rocket', Values) > 0 then
        ShotType := wstRocket
      else if Pos('Chain', Values) > 0 then
        ShotType := wstChain;
      if ShotType in [wstChain, wstMissile, wstRocket] then
        ShotCount := ExtractDigitsToIntW(Values);
      AttackCount := 1;
      if Block.CountParams('AttackCount') > 0 then
        AttackCount := StrToInt(AnsiString(Block.GetParam('AttackCount')));
      MissileRange := 0;
      MissileMaxSpeed := 0;
      MissileMinSpeed := 0;
      MissileChanceToBeHit := 0;
      if Block.CountParams('MissileRadius') > 0 then
        MissileRange := StrToInt(AnsiString(Block.GetParam('MissileRadius')));
      if Block.CountParams('MissileMaxSpeed') > 0 then
        MissileMaxSpeed := StrToInt(AnsiString(Block.GetParam('MissileMaxSpeed')));
      if Block.CountParams('MissileMinSpeed') > 0 then
        MissileMinSpeed := StrToInt(AnsiString(Block.GetParam('MissileMinSpeed')));
      if Block.CountParams('MissileChanceToBeHit') > 0 then
        MissileChanceToBeHit := StrToInt(AnsiString(Block.GetParam('MissileChanceToBeHit')));
      Values := Block.GetParam('mWeaponDamage');
      for Level := 1 to 8 do
        DamageScaleByLevel[Level] :=
            ExtractDecimalToSingleW(ExtractDelimitedPartW(Values, Level - 1, ','));
    end;
  end;
  for Level := 1 to CountItemTypesInMask(WeaponTypes) do
  begin
    Kind := GetItemTypeFromMask(WeaponTypes, Level);
    WeaponInfos[TItemType(Kind)].PrimarySE := 'Weapon.' + IntToStr(Kind - 50);
    WeaponInfos[TItemType(Kind)].SecondarySE := 'Weapon.NoGraph';
    if WeaponInfos[TItemType(Kind)].ShotType in [wstTorpedo, wstMissile, wstRocket] then
      WeaponInfos[TItemType(Kind)].AreaSE := 'Weapon.MissileHit'
    else
      WeaponInfos[TItemType(Kind)].AreaSE := '';
    WeaponInfos[TItemType(Kind)].DefaultPalette := 0;
    WeaponInfos[TItemType(Kind)].TypeHash := Kind * 171;
  end;
  WeaponInfos[t_Multiresonator].SecondarySE := 'Weapon.Nine';
  WeaponInfos[t_IMHO9000].SecondarySE := 'Weapon.12';
  WeaponInfos[t_Vertix].AreaSE := 'Weapon.13';
  WeaponInfos[t_IndustrialLaser].InventionIndex := piIndustrialLaser;
  WeaponInfos[t_FragmentationCannon].InventionIndex := piFragmentationCannon;
  WeaponInfos[t_Flux].InventionIndex := piFlux;
  WeaponInfos[t_MissileLauncher].InventionIndex := piMissileLauncher;
  WeaponInfos[t_Treton].InventionIndex := piTreton;
  WeaponInfos[t_WavePhaser].InventionIndex := piWavePhaser;
  WeaponInfos[t_FlowBlaster].InventionIndex := piFlowBlaster;
  WeaponInfos[t_ElectronicCutter].InventionIndex := piElectronicCutter;
  WeaponInfos[t_Multiresonator].InventionIndex := piMultiresonator;
  WeaponInfos[t_AtomicVision].InventionIndex := piAtomicVision;
  WeaponInfos[t_Disintegrator].InventionIndex := piDisintegrator;
  WeaponInfos[t_Turbogravitron].InventionIndex := piTurbogravitron;
  WeaponInfos[t_IMHO9000].InventionIndex := piTurbogravitron;
  WeaponInfos[t_Vertix].InventionIndex := piTurbogravitron;
  WeaponInfos[t_TorpedoTube].InventionIndex := piTurbogravitron;
  WeaponInfos[t_Esodapher].InventionIndex := piMultiresonator;
  WeaponInfos[t_Caphasitor].InventionIndex := piFlux;
  WeaponInfos[t_Lirecron].InventionIndex := piMissileLauncher;
  WeaponInfos[t_IMHO9000].Availability := waNotSoldAndNodeRepair;
  WeaponInfos[t_Vertix].Availability := waNotSoldAndNodeRepair;
  WeaponInfos[t_TorpedoTube].Availability := waNotSoldAndNodeRepair;
  WeaponInfos[t_Esodapher].Availability := waPirateOnly;
  WeaponInfos[t_Caphasitor].Availability := waPirateOnly;
  WeaponInfos[t_Lirecron].Availability := waPirateOnly;
end;

procedure LoadMicroModuleConfiguration;
const
  WeaponTypes = [0..79] - [0..49] - [68..79];
var
  Block: TBlockParEC;
  Tokens: WideString;
  Index, Position, Part: Integer;
  Value, CustomName: WideString;
  Kind, DamageKind: Byte;
  BonusKind: TEquipmentBonusKind;
  DamageClass: TWeaponDamageClass;
  StationKind: TStationType;
  BlockIndices: array of Integer;
  SortKeys: array of Integer;

  function ReadMicroModuleParam(
      ParamName: WideString
  ): WideString; { Nested in LoadMicroModuleConfiguration; reads its current Block through the caller-popped static link. }
  var
    I, Count: Integer;
  begin
    Result := '';
    Count := Block.CountParams(ParamName);
    for I := 0 to Count - 1 do
    begin
      if Result <> '' then
        Result := Result + #13#10;
      Result := Result + Block.GetParamByPath(ParamName + ':' + WideString(IntToStr(I)));
    end;
    if FindTextPosW('<', Result) > 0 then
    begin
      Result := ReplaceAllWideString(Result, '<br>', #13#10);
      Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    end;
  end;

  function ConsumeMicroModuleToken(
      Token: WideString
  ): Boolean; { Nested in LoadMicroModuleConfiguration; removes every occurrence of Token from its remaining-token string. }
  begin
    if Pos(Token, Tokens) > 0 then
    begin
      Result := True;
      Tokens := ReplaceAllWideString(Tokens, Token, '');
    end
    else
      Result := False;
  end;

begin
  Block := LanguageDataConfig.GetBlock('MicroModuls');
  MicroModuleTemplateCount := Block.GetBlockCount;
  SetLength(MicroModuleTemplates, MicroModuleTemplateCount);
  SetLength(MicroModuleCandidateIndices, MicroModuleTemplateCount);
  SetLength(BlockIndices, MicroModuleTemplateCount);
  SetLength(SortKeys, MicroModuleTemplateCount);
  for Index := 0 to MicroModuleTemplateCount - 1 do
  begin
    BlockIndices[Index] := Index;
    SortKeys[Index] := ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index));
  end;
  for Index := 0 to MicroModuleTemplateCount - 2 do
    for Position := MicroModuleTemplateCount - 1 downto Index + 1 do
      if SortKeys[Position - 1] > SortKeys[Position] then
      begin
        Part := SortKeys[Position - 1];
        SortKeys[Position - 1] := SortKeys[Position];
        SortKeys[Position] := Part;
        Part := BlockIndices[Position - 1];
        BlockIndices[Position - 1] := BlockIndices[Position];
        BlockIndices[Position] := Part;
      end;
  for Index := 0 to MicroModuleTemplateCount - 1 do
  begin
    Block := LanguageDataConfig.GetBlock('MicroModuls');
    with MicroModuleTemplates[Index] do
    begin
      ConfigNumber := SortKeys[Index];
      ConfigName := Block.GetBlockNameByIndex(BlockIndices[Index]);
      ConfigNameHash := InitCrc32;
      ConfigNameHash := UpdateCrc32(ConfigNameHash, PWideChar(ConfigName), Length(ConfigName) * 2);
      ConfigNameHash := FinishCrc32(ConfigNameHash);
      Block := Block.GetBlockByIndex(BlockIndices[Index]);
      SpecialOnly := ExtractDigitsToIntW(ReadMicroModuleParam('Special')) <> 0;
      BlocksMicroModuleSlot := ExtractDigitsToIntW(ReadMicroModuleParam('BlockMM')) <> 0;
      BlocksSpecialSlot := ExtractDigitsToIntW(ReadMicroModuleParam('BlockImp')) <> 0;
      RacialRestriction := ExtractDigitsToIntW(ReadMicroModuleParam('RacialRestriction')) <> 0;
      SeparatedNumbers := ExtractDigitsToIntW(ReadMicroModuleParam('SeparatedNumbers')) <> 0;
      Name := ReadMicroModuleParam('Name');
      NamePrefix := ReadMicroModuleParam('NamePrefix');
      Color := ReadMicroModuleParam('Color');
      TextReplace := ReadMicroModuleParam('TextReplace');
      for BonusKind := Low(StatBonuses) to High(StatBonuses) do
      begin
        Value := ReadMicroModuleParam(EquipmentBonusNames[BonusKind]);
        if Value = '' then
          StatBonuses[BonusKind] := 0
        else if BonusKind in [bonExtraAkrinEff, bonExtraAkrinPenalty] then
          StatBonuses[BonusKind] := Round(ExtractDecimalToSingleW(Value) * 100)
        else
          StatBonuses[BonusKind] := StrToInt(AnsiString(Value));
      end;
      Value := ReadMicroModuleParam('Cost');
      if Value = '' then
        CostPercent := 100
      else
        CostPercent := StrToInt(AnsiString(Value));
      Value := ReadMicroModuleParam('Size');
      if Value = '' then
        SizePercent := 100
      else
        SizePercent := StrToInt(AnsiString(Value));
      Value := ReadMicroModuleParam('Fragility');
      if Value = '' then
        FragilityFactor := 1
      else
        FragilityFactor := StrToInt(AnsiString(Value)) * 0.01;
      for DamageClass := Low(TWeaponDamageClass) to High(TWeaponDamageClass) do
      begin
        Value := ReadMicroModuleParam('Fragility' + WeaponDamageClasses[DamageClass].Name);
        if Value = '' then
          FragilityFactorByDamageClass[DamageClass] := FragilityFactor
        else
          FragilityFactorByDamageClass[DamageClass] := StrToInt(AnsiString(Value)) * 0.01;
      end;
      Value := ReadMicroModuleParam('Owner');
      if (Value = '') or (Value = 'Any') then
      begin
        if SpecialOnly then
          AllowedHullOwnerMask := [oiMaloc..oiGaal, oiPirate]
        else
          AllowedHullOwnerMask := [oiMaloc..oiDominator, oiPirate];
        AllowedDominatorSeriesMask := [dsBlazer..dsTerron];
        AllowedCustomHullFactions := '';
      end
      else
      begin
        AllowedHullOwnerMask := [];
        AllowedDominatorSeriesMask := [];
        Tokens := ReplaceAllWideString(Value, ' ', '');
        Tokens := '<' + ReplaceAllWideString(Tokens, ',', '>,<') + '>';
        if ConsumeMicroModuleToken('<Maloc>') then
          Include(AllowedHullOwnerMask, oiMaloc);
        if ConsumeMicroModuleToken('<Peleng>') then
          Include(AllowedHullOwnerMask, oiPeleng);
        if ConsumeMicroModuleToken('<People>') then
          Include(AllowedHullOwnerMask, oiHuman);
        if ConsumeMicroModuleToken('<Fei>') then
          Include(AllowedHullOwnerMask, oiFeyan);
        if ConsumeMicroModuleToken('<Gaal>') then
          Include(AllowedHullOwnerMask, oiGaal);
        if ConsumeMicroModuleToken('<PirateClan>') then
          Include(AllowedHullOwnerMask, oiPirate);
        if ConsumeMicroModuleToken('<None>') then
          Include(AllowedHullOwnerMask, oiUninhabited);
        if SpecialOnly then
        begin
          if ConsumeMicroModuleToken('<Kling>') then
            Include(AllowedHullOwnerMask, oiDominator);
          ConsumeMicroModuleToken('<NonKling>');
        end
        else
        begin
          if not ConsumeMicroModuleToken('<NonKling>') then
            Include(AllowedHullOwnerMask, oiDominator);
          ConsumeMicroModuleToken('<Kling>');
        end;
        if ConsumeMicroModuleToken('<Blazer>') then
        begin
          Include(AllowedDominatorSeriesMask, dsBlazer);
          if SpecialOnly then
            Include(AllowedHullOwnerMask, oiDominator);
        end;
        if ConsumeMicroModuleToken('<Terron>') then
        begin
          Include(AllowedDominatorSeriesMask, dsTerron);
          if SpecialOnly then
            Include(AllowedHullOwnerMask, oiDominator);
        end;
        if ConsumeMicroModuleToken('<Keller>') then
        begin
          Include(AllowedDominatorSeriesMask, dsKeller);
          if SpecialOnly then
            Include(AllowedHullOwnerMask, oiDominator);
        end;
        if AllowedDominatorSeriesMask = [] then
          AllowedDominatorSeriesMask := [dsBlazer..dsTerron];
        AllowedCustomHullFactions := '';
        for Part := 0 to CountDelimitedPartsW(Tokens, ',') - 1 do
        begin
          CustomName := TrimWideString(ExtractDelimitedPartW(Tokens, Part, ','));
          if CustomName <> '' then
            if AllowedCustomHullFactions <> '' then
              AllowedCustomHullFactions := AllowedCustomHullFactions + ',' + CustomName
            else
              AllowedCustomHullFactions := CustomName;
        end;
      end;
      CustomFaction := ReadMicroModuleParam('CustomFaction');
      Value := ReadMicroModuleParam('Priority');
      if Value = '' then
        Priority := 100
      else
        Priority := StrToInt(AnsiString(Value));
      Value := ReadMicroModuleParam('Equipments');
      if (Value = '') or (Value = 'Any') then
      begin
        AllowedItemTypes := [Ord(t_Hull)..Ord(t_CustomWeapon)];
        AllowedCustomWeaponTypes := 'Any';
      end
      else
      begin
        AllowedItemTypes := [];
        AllowedCustomWeaponTypes := '';
        Tokens := ReplaceAllWideString(Value, ' ', '');
        Tokens := '<' + ReplaceAllWideString(Tokens, ',', '>,<') + '>';
        if ConsumeMicroModuleToken('<Hull>') then
          Include(AllowedItemTypes, Ord(t_Hull));
        if ConsumeMicroModuleToken('<FuelTank>') then
          Include(AllowedItemTypes, Ord(t_FuelTanks));
        if ConsumeMicroModuleToken('<Engine>') then
          Include(AllowedItemTypes, Ord(t_Engine));
        if ConsumeMicroModuleToken('<Radar>') then
          Include(AllowedItemTypes, Ord(t_Radar));
        if ConsumeMicroModuleToken('<Scaner>') then
          Include(AllowedItemTypes, Ord(t_Scaner));
        if ConsumeMicroModuleToken('<Droid>') then
          Include(AllowedItemTypes, Ord(t_RepairRobot));
        if ConsumeMicroModuleToken('<Hook>') then
          Include(AllowedItemTypes, Ord(t_CargoHook));
        if ConsumeMicroModuleToken('<DefGenerator>') then
          Include(AllowedItemTypes, Ord(t_DefGenerator));
        for Part := 1 to CountItemTypesInMask(WeaponTypes) do
        begin
          Kind :=
              GetItemTypeFromMask(
                  [Ord(t_Food)..79]
                      - [Ord(t_Food)..Ord(t_DefGenerator)]
                      - [Ord(t_CustomWeapon)..79],
                  Part
              );
          if ConsumeMicroModuleToken('<' + ItemTypeNames[TItemType(Kind)] + '>') then
            Include(AllowedItemTypes, Kind)
          else if (Pos('<WMissile>', Tokens) > 0)
              and (dkMissile in WeaponInfos[TItemType(Kind)].DamageFlags) then
            Include(AllowedItemTypes, Kind)
          else if (Pos('<WSplinter>', Tokens) > 0)
              and (dkSplinter in WeaponInfos[TItemType(Kind)].DamageFlags) then
            Include(AllowedItemTypes, Kind)
          else if (Pos('<WEnergy>', Tokens) > 0)
              and (dkEnergy in WeaponInfos[TItemType(Kind)].DamageFlags) then
            Include(AllowedItemTypes, Kind);
        end;
        for Part := 0 to CountDelimitedPartsW(Tokens, ',') - 1 do
        begin
          CustomName := TrimWideString(ExtractDelimitedPartW(Tokens, Part, ','));
          if CustomName <> '' then
            if AllowedCustomWeaponTypes <> '' then
              AllowedCustomWeaponTypes := AllowedCustomWeaponTypes + ',' + CustomName
            else
              AllowedCustomWeaponTypes := CustomName;
        end;
      end;
      Value := ReadMicroModuleParam('Ruins');
      OfferStationTypes := [];
      OfferStationNames := ReplaceAllWideString(Value, ' ', '');
      OfferStationNames := '<' + ReplaceAllWideString(OfferStationNames, ',', '>,<') + '>';
      if Value = 'Any' then
        OfferStationTypes := [rstRangerCenter..rstDominion]
      else if Value <> '' then
        for StationKind := rstRangerCenter to rstDominion do
          if Pos(ShipTypeNames[StationKind].Name, Value) > 0 then
            Include(OfferStationTypes, StationKind);
      OnPlanets := ExtractDigitsToIntW(ReadMicroModuleParam('OnPlanets')) <> 0;
      Value := ReadMicroModuleParam('WeaponMods');
      WeaponDamageFlags := [];
      if Value <> '' then
        for DamageKind := Low(WeaponDamageFlagNames) to High(WeaponDamageFlagNames) do
          if not (DamageKind in [Ord(dkEnergy)..Ord(dkMissile)])
              and not (DamageKind in [Ord(dkDecelerateA), Ord(dkDecelerateAEx), Ord(dkNonLethal)])
              and (Pos(WeaponDamageFlagNames[DamageKind], Value) > 0) then
            Include(WeaponDamageFlags, TDamageKind(DamageKind));
      KindGraph := ReadMicroModuleParam('KindGraph');
      MissileGraph := ReadMicroModuleParam('MissileGraph');
      Value := ReadMicroModuleParam('ShotVisual');
      if Value = '' then
        ShotVisual := -1
      else
        ShotVisual := StrToInt(AnsiString(Value));
      Value := ReadMicroModuleParam('HullGraphSize');
      if Value = '' then
        HullGraphSizePercent := 100
      else
        HullGraphSizePercent := StrToInt(AnsiString(Value));
      CustomTag := ReadMicroModuleParam('CustomTag');
    end;
  end;
  BlockIndices := nil;
  SortKeys := nil;
end;

procedure InitializeCaptainHealthDefinitions;
var
  I: Integer;
  Path, Value: WideString;
begin
  CaptainHealthDefinitions[heBlindness].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBlindness].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBlindness].AllowedRatingBands := [2, 3, 4, 5];
  CaptainHealthDefinitions[heBlindness].AllowedRanks := [2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heBlindness].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heBlindness].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heBlindness].DevelopmentRate := 100.0;
  CaptainHealthDefinitions[heBlindness].InfectionChance := 1.0;
  CaptainHealthDefinitions[heBlindness].Locations := [hlCombat];
  CaptainHealthDefinitions[heBlindness].Duration := 150;

  CaptainHealthDefinitions[heChekumash].AllowedLocationOwners := [oiPeleng];
  CaptainHealthDefinitions[heChekumash].AllowedOwners := [oiPeleng, oiHuman, oiFeyan, oiGaal];
  CaptainHealthDefinitions[heChekumash].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heChekumash].AllowedRanks := [3, 4, 5];
  CaptainHealthDefinitions[heChekumash].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heChekumash].MedicalPriceSizeLevel := 4;
  CaptainHealthDefinitions[heChekumash].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heChekumash].InfectionChance := 1.0;
  CaptainHealthDefinitions[heChekumash].Locations := [hlPlanet];
  CaptainHealthDefinitions[heChekumash].Duration := 555;

  CaptainHealthDefinitions[heHolyFanaticism].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heHolyFanaticism].AllowedOwners := [oiMaloc, oiPeleng, oiHuman];
  CaptainHealthDefinitions[heHolyFanaticism].AllowedRatingBands := [3, 4, 5];
  CaptainHealthDefinitions[heHolyFanaticism].AllowedRanks := [3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heHolyFanaticism].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heHolyFanaticism].MedicalPriceSizeLevel := 3;
  CaptainHealthDefinitions[heHolyFanaticism].DevelopmentRate := 100.0;
  CaptainHealthDefinitions[heHolyFanaticism].InfectionChance := 1.0;
  CaptainHealthDefinitions[heHolyFanaticism].Locations := [hlCombat];
  CaptainHealthDefinitions[heHolyFanaticism].Duration := 200;

  CaptainHealthDefinitions[heComplexImmunocide].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heComplexImmunocide].AllowedOwners :=
      [oiPeleng, oiHuman, oiFeyan, oiGaal];
  CaptainHealthDefinitions[heComplexImmunocide].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heComplexImmunocide].AllowedRanks := [1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heComplexImmunocide].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heComplexImmunocide].MedicalPriceSizeLevel := 5;
  CaptainHealthDefinitions[heComplexImmunocide].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heComplexImmunocide].InfectionChance := 1.0;
  CaptainHealthDefinitions[heComplexImmunocide].Locations := [hlNormalSpace];
  CaptainHealthDefinitions[heComplexImmunocide].Duration := 1000;

  CaptainHealthDefinitions[heMysteriousLuatanza].AllowedLocationOwners := [oiGaal];
  CaptainHealthDefinitions[heMysteriousLuatanza].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heMysteriousLuatanza].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heMysteriousLuatanza].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heMysteriousLuatanza].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heMysteriousLuatanza].MedicalPriceSizeLevel := 1;
  CaptainHealthDefinitions[heMysteriousLuatanza].DevelopmentRate := 10.0;
  CaptainHealthDefinitions[heMysteriousLuatanza].InfectionChance := 1.0;
  CaptainHealthDefinitions[heMysteriousLuatanza].Locations := [hlPlanet, hlDocked];
  CaptainHealthDefinitions[heMysteriousLuatanza].Duration := 170;

  CaptainHealthDefinitions[heDrugAddiction].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heDrugAddiction].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heDrugAddiction].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heDrugAddiction].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heDrugAddiction].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heDrugAddiction].MedicalPriceSizeLevel := 4;
  CaptainHealthDefinitions[heDrugAddiction].DevelopmentRate := 100.0;
  CaptainHealthDefinitions[heDrugAddiction].InfectionChance := 1.0;
  CaptainHealthDefinitions[heDrugAddiction].Locations := [];
  CaptainHealthDefinitions[heDrugAddiction].Duration := 1000;

  CaptainHealthDefinitions[heWhirlwindConcussion].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heWhirlwindConcussion].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heWhirlwindConcussion].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heWhirlwindConcussion].AllowedRanks := [1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heWhirlwindConcussion].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heWhirlwindConcussion].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heWhirlwindConcussion].DevelopmentRate := 100.0;
  CaptainHealthDefinitions[heWhirlwindConcussion].InfectionChance := 1.0;
  CaptainHealthDefinitions[heWhirlwindConcussion].Locations := [hlCombat];
  CaptainHealthDefinitions[heWhirlwindConcussion].Duration := 130;

  CaptainHealthDefinitions[hePulledMuscle].AllowedLocationOwners :=
      [oiPeleng, oiHuman, oiFeyan, oiGaal];
  CaptainHealthDefinitions[hePulledMuscle].AllowedOwners := [oiPeleng, oiHuman, oiFeyan, oiGaal];
  CaptainHealthDefinitions[hePulledMuscle].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[hePulledMuscle].AllowedRanks := [1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[hePulledMuscle].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[hePulledMuscle].MedicalPriceSizeLevel := 1;
  CaptainHealthDefinitions[hePulledMuscle].DevelopmentRate := 100.0;
  CaptainHealthDefinitions[hePulledMuscle].InfectionChance := 1.0;
  CaptainHealthDefinitions[hePulledMuscle].Locations := [hlCombat];
  CaptainHealthDefinitions[hePulledMuscle].Duration := 100;

  CaptainHealthDefinitions[heGrandMalosausus].AllowedLocationOwners := [oiMaloc];
  CaptainHealthDefinitions[heGrandMalosausus].AllowedOwners := [oiMaloc];
  CaptainHealthDefinitions[heGrandMalosausus].AllowedRatingBands := [2, 3, 4, 5];
  CaptainHealthDefinitions[heGrandMalosausus].AllowedRanks := [2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heGrandMalosausus].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heGrandMalosausus].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heGrandMalosausus].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heGrandMalosausus].InfectionChance := 1.0;
  CaptainHealthDefinitions[heGrandMalosausus].Locations := [hlPlanet, hlDocked, hlNormalSpace];
  CaptainHealthDefinitions[heGrandMalosausus].Duration := 180;

  CaptainHealthDefinitions[heBitterPelenosia].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBitterPelenosia].AllowedOwners := [oiPeleng];
  CaptainHealthDefinitions[heBitterPelenosia].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heBitterPelenosia].AllowedRanks := [1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heBitterPelenosia].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heBitterPelenosia].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heBitterPelenosia].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heBitterPelenosia].InfectionChance := 1.0;
  CaptainHealthDefinitions[heBitterPelenosia].Locations := [hlPlanet, hlDocked, hlNormalSpace];
  CaptainHealthDefinitions[heBitterPelenosia].Duration := 122;

  CaptainHealthDefinitions[heAkaSezyanka].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heAkaSezyanka].AllowedOwners := [oiFeyan];
  CaptainHealthDefinitions[heAkaSezyanka].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heAkaSezyanka].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heAkaSezyanka].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heAkaSezyanka].MedicalPriceSizeLevel := 4;
  CaptainHealthDefinitions[heAkaSezyanka].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heAkaSezyanka].InfectionChance := 1.0;
  CaptainHealthDefinitions[heAkaSezyanka].Locations := [hlPlanet, hlDocked];
  CaptainHealthDefinitions[heAkaSezyanka].Duration := 164;

  CaptainHealthDefinitions[heNewMolizone].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heNewMolizone].AllowedOwners := [oiGaal];
  CaptainHealthDefinitions[heNewMolizone].AllowedRatingBands := [2, 3, 4, 5];
  CaptainHealthDefinitions[heNewMolizone].AllowedRanks := [2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heNewMolizone].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heNewMolizone].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heNewMolizone].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heNewMolizone].InfectionChance := 0.5;
  CaptainHealthDefinitions[heNewMolizone].Locations := [hlPlanet, hlDocked, hlNormalSpace];
  CaptainHealthDefinitions[heNewMolizone].Duration := 88;

  RadiationHealthDefinitions[1].AllowedLocationOwners := [oiMaloc..oiGaal];
  RadiationHealthDefinitions[1].AllowedOwners := [oiMaloc..oiGaal];
  RadiationHealthDefinitions[1].AllowedRatingBands := [1, 2, 3, 4, 5];
  RadiationHealthDefinitions[1].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  RadiationHealthDefinitions[1].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  RadiationHealthDefinitions[1].MedicalPriceSizeLevel := 4;
  RadiationHealthDefinitions[1].DevelopmentRate := 100.0;
  RadiationHealthDefinitions[1].InfectionChance := 0.0;
  RadiationHealthDefinitions[1].Locations := [];
  RadiationHealthDefinitions[1].Duration := 30;

  CaptainHealthDefinitions[heMaloqSizha].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heMaloqSizha].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heMaloqSizha].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heMaloqSizha].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heMaloqSizha].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heMaloqSizha].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heMaloqSizha].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heMaloqSizha].InfectionChance := 0.9;
  CaptainHealthDefinitions[heMaloqSizha].Duration := 140;

  CaptainHealthDefinitions[heOneEyedKhamas].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heOneEyedKhamas].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heOneEyedKhamas].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heOneEyedKhamas].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heOneEyedKhamas].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heOneEyedKhamas].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heOneEyedKhamas].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heOneEyedKhamas].InfectionChance := 0.9;
  CaptainHealthDefinitions[heOneEyedKhamas].Duration := 130;

  CaptainHealthDefinitions[heStardust].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heStardust].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heStardust].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heStardust].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heStardust].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heStardust].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heStardust].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heStardust].InfectionChance := 0.8;
  CaptainHealthDefinitions[heStardust].Duration := 140;

  CaptainHealthDefinitions[heSuperTechnician].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heSuperTechnician].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heSuperTechnician].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heSuperTechnician].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heSuperTechnician].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heSuperTechnician].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heSuperTechnician].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heSuperTechnician].InfectionChance := 0.4;
  CaptainHealthDefinitions[heSuperTechnician].Duration := 120;

  CaptainHealthDefinitions[heGaalianAlacrity].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heGaalianAlacrity].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heGaalianAlacrity].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heGaalianAlacrity].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heGaalianAlacrity].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heGaalianAlacrity].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heGaalianAlacrity].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heGaalianAlacrity].InfectionChance := 0.9;
  CaptainHealthDefinitions[heGaalianAlacrity].Duration := 90;

  CaptainHealthDefinitions[heBloodDjogar].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBloodDjogar].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBloodDjogar].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heBloodDjogar].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heBloodDjogar].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heBloodDjogar].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heBloodDjogar].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heBloodDjogar].InfectionChance := 0.8;
  CaptainHealthDefinitions[heBloodDjogar].Duration := 300;

  CaptainHealthDefinitions[heRagobamWhisper].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heRagobamWhisper].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heRagobamWhisper].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heRagobamWhisper].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heRagobamWhisper].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heRagobamWhisper].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heRagobamWhisper].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heRagobamWhisper].InfectionChance := 0.9;
  CaptainHealthDefinitions[heRagobamWhisper].Duration := 140;

  CaptainHealthDefinitions[heShakhmandooLeader].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heShakhmandooLeader].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heShakhmandooLeader].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heShakhmandooLeader].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heShakhmandooLeader].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heShakhmandooLeader].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heShakhmandooLeader].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heShakhmandooLeader].InfectionChance := 0.9;
  CaptainHealthDefinitions[heShakhmandooLeader].Duration := 200;

  CaptainHealthDefinitions[hePsychotropicCache].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[hePsychotropicCache].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[hePsychotropicCache].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[hePsychotropicCache].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[hePsychotropicCache].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[hePsychotropicCache].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[hePsychotropicCache].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[hePsychotropicCache].InfectionChance := 0.9;
  CaptainHealthDefinitions[hePsychotropicCache].Duration := 200;

  CaptainHealthDefinitions[heBusinessMark].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBusinessMark].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heBusinessMark].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heBusinessMark].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heBusinessMark].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heBusinessMark].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heBusinessMark].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heBusinessMark].InfectionChance := 0.25;
  CaptainHealthDefinitions[heBusinessMark].Duration := 150;

  CaptainHealthDefinitions[heDoubleplex].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heDoubleplex].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heDoubleplex].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heDoubleplex].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heDoubleplex].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heDoubleplex].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heDoubleplex].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heDoubleplex].InfectionChance := 0.15;
  CaptainHealthDefinitions[heDoubleplex].Duration := 90;

  CaptainHealthDefinitions[heAbsoluteStatus].AllowedLocationOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heAbsoluteStatus].AllowedOwners := [oiMaloc..oiGaal];
  CaptainHealthDefinitions[heAbsoluteStatus].AllowedRatingBands := [1, 2, 3, 4, 5];
  CaptainHealthDefinitions[heAbsoluteStatus].AllowedRanks := [0, 1, 2, 3, 4, 5, 6, 7];
  CaptainHealthDefinitions[heAbsoluteStatus].AllowedCareers := [rcTrader, rcPirate, rcWarrior];
  CaptainHealthDefinitions[heAbsoluteStatus].MedicalPriceSizeLevel := 2;
  CaptainHealthDefinitions[heAbsoluteStatus].DevelopmentRate := 1.0;
  CaptainHealthDefinitions[heAbsoluteStatus].InfectionChance := 0.2;
  CaptainHealthDefinitions[heAbsoluteStatus].Duration := 120;

  for I := 1 to 12 do
    with CaptainHealthDefinitions[TCaptainHealthEffect(I)] do
    begin
      Path := 'Illness.Illness.' + IntToStr(I - 1);
      Name := LocalizedText(Path + '.Name');
      Text := LocalizedText(Path + '.Text');
      Disabled := False;
      Value := LocalizedText(Path + '.Time');
      if Value <> '' then
        Duration := StrToInt(AnsiString(Value));
    end;

  for I := 1 to 1 do
    with RadiationHealthDefinitions[I] do
    begin
      Path := 'Illness.ExtraIllness.' + IntToStr(I);
      Name := LocalizedText(Path + '.Name');
      Text := LocalizedText(Path + '.Text');
      Disabled := False;
      Value := LocalizedText(Path + '.Time');
      if Value <> '' then
        Duration := StrToInt(AnsiString(Value));
    end;

  for I := 1 to 12 do
    with CaptainHealthDefinitions[TCaptainHealthEffect(12 + I)] do
    begin
      Path := 'Illness.Stimulant.' + IntToStr(I - 1);
      Name := LocalizedText(Path + '.Name');
      Text := LocalizedText(Path + '.Text');
      Disabled := False;
      Value := LocalizedText(Path + '.Time');
      if Value <> '' then
        Duration := StrToInt(AnsiString(Value));
    end;
end;

procedure LoadHullSeriesConfiguration;
var
  Block: TBlockParEC;
  Index, Position, Temp: Integer;
  Value: WideString;
  DamageKind: TWeaponDamageClass;
  BlockIndices: array of Integer;
  SortKeys: array of Integer;

  function ReadHullSeriesParam(
      ParamName: WideString
  ): WideString; { Nested in LoadHullSeriesConfiguration; reads its current Block through the caller-popped static link. }
  var
    I, Count: Integer;
  begin
    Result := '';
    Count := Block.CountParams(ParamName);
    for I := 0 to Count - 1 do
    begin
      if Result <> '' then
        Result := Result + #13#10;
      Result := Result + Block.GetParamByPath(ParamName + ':' + WideString(IntToStr(I)));
    end;
    if FindTextPosW('<', Result) > 0 then
    begin
      Result := ReplaceAllWideString(Result, '<br>', #13#10);
      Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    end;
  end;

begin
  Block := LanguageDataConfig.GetBlock('HullType');
  HullSeriesCount := Block.GetBlockCount;
  SetLength(BlockIndices, HullSeriesCount);
  SetLength(SortKeys, HullSeriesCount);
  Position := 0;
  for Index := 0 to HullSeriesCount - 1 do
    if Block.GetBlockNameByIndex(Index) <> 'HullOldfag' then
    begin
      BlockIndices[Position] := Index;
      SortKeys[Position] := ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index));
      Inc(Position);
    end;
  HullSeriesCount := Position;
  SetLength(BlockIndices, HullSeriesCount);
  SetLength(SortKeys, HullSeriesCount);
  SetLength(HullSeriesDefinitions, HullSeriesCount);
  for Index := 0 to HullSeriesCount - 2 do
    for Position := HullSeriesCount - 1 downto Index + 1 do
      if SortKeys[Position - 1] > SortKeys[Position] then
      begin
        Temp := SortKeys[Position - 1];
        SortKeys[Position - 1] := SortKeys[Position];
        SortKeys[Position] := Temp;
        Temp := BlockIndices[Position - 1];
        BlockIndices[Position - 1] := BlockIndices[Position];
        BlockIndices[Position] := Temp;
      end;
  for Index := 0 to HullSeriesCount - 1 do
  begin
    Block := LanguageDataConfig.GetBlock('HullType');
    with HullSeriesDefinitions[Index] do
    begin
      SortKey := SortKeys[Index];
      SystemName := Block.GetBlockNameByIndex(BlockIndices[Index]);
      SystemNameCRC := InitCrc32;
      SystemNameCRC := UpdateCrc32(SystemNameCRC, PWideChar(SystemName), Length(SystemName) * 2);
      SystemNameCRC := FinishCrc32(SystemNameCRC);
      Block := Block.GetBlockByIndex(BlockIndices[Index]);
      Name := ReadHullSeriesParam('Name');
      Text := ReadHullSeriesParam('Text');
      Value := ReadHullSeriesParam('Race');
      AllowedOwners := [];
      if (Value = '') or (Value = 'Any') then
        AllowedOwners := [oiMaloc..oiGaal]
      else
      begin
        if Pos('Maloc', Value) > 0 then
          Include(AllowedOwners, oiMaloc);
        if Pos('Peleng', Value) > 0 then
          Include(AllowedOwners, oiPeleng);
        if Pos('People', Value) > 0 then
          Include(AllowedOwners, oiHuman);
        if Pos('Fei', Value) > 0 then
          Include(AllowedOwners, oiFeyan);
        if Pos('Gaal', Value) > 0 then
          Include(AllowedOwners, oiGaal);
      end;
      Value := ReadHullSeriesParam('ShipType');
      AllowedShipTypes := [];
      if (Value = '') or (Value = 'Any') then
        AllowedShipTypes := [htRanger..htDiplomat]
      else
      begin
        if Pos('Transport', Value) > 0 then
          Include(AllowedShipTypes, htTransport);
        if Pos('Liner', Value) > 0 then
          Include(AllowedShipTypes, htLiner);
        if Pos('Diplomat', Value) > 0 then
          Include(AllowedShipTypes, htDiplomat);
        if Pos('Ranger', Value) > 0 then
          Include(AllowedShipTypes, htRanger);
        if Pos('Pirate', Value) > 0 then
          Include(AllowedShipTypes, htPirate);
        if Pos('Warrior', Value) > 0 then
          Include(AllowedShipTypes, htWarrior);
        if Pos('Flagman', Value) > 0 then
          Include(AllowedShipTypes, htFlagship);
      end;
      SlotBonuses[sskFuelTanks] := 0;
      SlotBonuses[sskEngine] := 0;
      SlotBonuses[sskUnsupported] := 0;
      Value := ReadHullSeriesParam('Radar');
      if Value = '' then
        SlotBonuses[sskRadar] := 0
      else
        SlotBonuses[sskRadar] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Scaner');
      if Value = '' then
        SlotBonuses[sskScanner] := 0
      else
        SlotBonuses[sskScanner] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Droid');
      if Value = '' then
        SlotBonuses[sskRepairRobot] := 0
      else
        SlotBonuses[sskRepairRobot] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Hook');
      if Value = '' then
        SlotBonuses[sskCargoHook] := 0
      else
        SlotBonuses[sskCargoHook] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Def');
      if Value = '' then
        SlotBonuses[sskDefGenerator] := 0
      else
        SlotBonuses[sskDefGenerator] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Weapon');
      if Value = '' then
        SlotBonuses[sskWeapon] := 0
      else
        SlotBonuses[sskWeapon] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Artefact');
      if Value = '' then
        SlotBonuses[sskArtefact] := 0
      else
        SlotBonuses[sskArtefact] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Forsage');
      if Value = '' then
        SlotBonuses[sskAfterburner] := 0
      else
        SlotBonuses[sskAfterburner] := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Size');
      if Value = '' then
        SizePercent := 100
      else
        SizePercent := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Cost');
      if Value = '' then
        CostPercent := 100
      else
        CostPercent := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Fragility');
      if Value = '' then
        FragilityFactor := 1
      else
        FragilityFactor := StrToInt(AnsiString(Value)) * 0.01;
      for DamageKind := Low(TWeaponDamageClass) to High(TWeaponDamageClass) do
      begin
        Value := ReadHullSeriesParam('Fragility' + WeaponDamageClasses[DamageKind].Name);
        if Value = '' then
          FragilityByDamageClass[DamageKind] := FragilityFactor
        else
          FragilityByDamageClass[DamageKind] := StrToInt(AnsiString(Value)) * 0.01;
      end;
      Value := ReadHullSeriesParam('Year');
      if Value = '' then
        Year := 0
      else
        Year := StrToInt(AnsiString(Value));
      Value := ReadHullSeriesParam('Probability');
      if Value = '' then
        ProbabilityWeight := 1
      else
        ProbabilityWeight := StrToInt(AnsiString(Value));
    end;
  end;
end;

procedure IncrementWordSaturating(var Value: Word);
begin
  if Value < High(Word) then
    Inc(Value);
end;

function PickRandomItemType(Mask: TItemTypeSelection): Byte;
var
  ItemType: Byte;
  Count: Integer;
begin
  Count := 0;
  for ItemType := Ord(Low(TItemType)) to Ord(High(TItemType)) do
    if ItemType in Mask then
      Inc(Count);
  Count := RandomIntRange(1, Count);
  // Native $837BB3 advances past type 75 to 76 on exhaustion, even for an empty mask.
  // A selected type breaks before that increment; keep the preceding RNG call.
  ItemType := Ord(Low(TItemType));
  while ItemType <= Ord(High(TItemType)) do
  begin
    if ItemType in Mask then
    begin
      Dec(Count);
      if Count = 0 then
        Break;
    end;
    Inc(ItemType);
  end;
  Result := ItemType;
end;

function PickRandomItemTypeFromSeed(Mask: TItemTypeSelection; var Seed: Cardinal): Byte;
var
  ItemType: Byte;
  Count: Integer;
begin
  Count := 0;
  for ItemType := Ord(Low(TItemType)) to Ord(High(TItemType)) do
    if ItemType in Mask then
      Inc(Count);
  Count := NextRandomIntRange(1, Count, Seed);
  // Native $837C35 advances past type 75 to 76 on exhaustion, even for an empty mask.
  // A selected type breaks before that increment; keep the preceding seeded RNG call.
  ItemType := Ord(Low(TItemType));
  while ItemType <= Ord(High(TItemType)) do
  begin
    if ItemType in Mask then
    begin
      Dec(Count);
      if Count = 0 then
        Break;
    end;
    Inc(ItemType);
  end;
  Result := ItemType;
end;

function CountItemTypesInMask(Mask: TItemTypeSelection): Integer;
var
  ItemType: Byte;
  Count: Integer;
begin
  Count := 0;
  for ItemType := Ord(Low(TItemType)) to Ord(High(TItemType)) do
    if ItemType in Mask then
      Inc(Count);
  Result := Count;
end;

function GetItemTypeFromMask(Mask: TItemTypeSelection; Index: Integer): Byte;
var
  ItemType: Byte;
  Count: Integer;
begin
  Count := 0;
  Result := 0;
  for ItemType := Ord(Low(TItemType)) to Ord(High(TItemType)) do
  begin
    if ItemType in Mask then
      Inc(Count);
    if Count = Index then
    begin
      Result := ItemType;
      Exit;
    end;
  end;
end;

function ClassifyWeaponDamageFlags(Flags: TDamageFlagSet): TWeaponDamageClass;
begin
  if dkMissile in Flags then
    Result := wdcMissile
  else if dkSplinter in Flags then
    Result := wdcSplinter
  else
    Result := wdcEnergy;
end;

end.
