{$EXCESSPRECISION OFF}
unit Achievements;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_Buf,
  SimpleSteamApi;
type
  TAchievementInfo = record
    Key: AnsiString;
    MaxValue: Integer;
  end;
  TAchievementDefinitionTable = array[0..82] of TAchievementInfo;
const
  AchievementDefinitionTable: TAchievementDefinitionTable = (
      (Key: 'NONE'; MaxValue: 0),
      (Key: 'AGENT'; MaxValue: 50),
      (Key: 'ARCHEOLOGY'; MaxValue: 30000),
      (Key: 'BLACKHEAD'; MaxValue: 200),
      (Key: 'BREZHNEV'; MaxValue: 0),
      (Key: 'BUMMER'; MaxValue: 0),
      (Key: 'CHAMPION'; MaxValue: 0),
      (Key: 'DOLGOZHID'; MaxValue: 0),
      (Key: 'HOLEMAN'; MaxValue: 500),
      (Key: 'ILL'; MaxValue: 0),
      (Key: 'KIBERMAN'; MaxValue: 0),
      (Key: 'MANYFACES'; MaxValue: 30),
      (Key: 'MONEY'; MaxValue: 0),
      (Key: 'NARKOMAN'; MaxValue: 0),
      (Key: 'OLDFAG'; MaxValue: 5000000),
      (Key: 'PEACELOVER'; MaxValue: 0),
      (Key: 'PIECECREATOR'; MaxValue: 0),
      (Key: 'PRISON'; MaxValue: 10),
      (Key: 'SHIELD'; MaxValue: 500),
      (Key: 'SPEED'; MaxValue: 0),
      (Key: 'SPRINTER'; MaxValue: 0),
      (Key: 'TERMINATOR'; MaxValue: 0),
      (Key: 'MASTER'; MaxValue: 0),
      (Key: 'POSTMAN'; MaxValue: 10),
      (Key: 'HULL'; MaxValue: 0),
      (Key: 'PIRATE'; MaxValue: 10),
      (Key: 'FRY'; MaxValue: 10),
      (Key: 'COALLITION'; MaxValue: 0),
      (Key: 'DEALER'; MaxValue: 5000000),
      (Key: 'JUMPER'; MaxValue: 500),
      (Key: 'DEFENDER'; MaxValue: 20),
      (Key: 'NEGOCIANT'; MaxValue: 15),
      (Key: 'HATER'; MaxValue: 0),
      (Key: 'CREDITOR'; MaxValue: 3),
      (Key: 'HOLEPEACE'; MaxValue: 0),
      (Key: 'SKILL'; MaxValue: 0),
      (Key: 'GUARD'; MaxValue: 30),
      (Key: 'SCIENCE'; MaxValue: 0),
      (Key: 'IRONMAN'; MaxValue: 40),
      (Key: 'BOMBER'; MaxValue: 0),
      (Key: 'ROCKET'; MaxValue: 150),
      (Key: 'CONTRABAND'; MaxValue: 200),
      (Key: 'ASTEROID'; MaxValue: 100),
      (Key: 'QUEST'; MaxValue: 30),
      (Key: 'KELLERRESEARCH'; MaxValue: 0),
      (Key: 'KELLERDESTROY'; MaxValue: 0),
      (Key: 'BLAZERPROGRAM'; MaxValue: 0),
      (Key: 'BLAZERPIECE'; MaxValue: 0),
      (Key: 'TERRONSTAR'; MaxValue: 0),
      (Key: 'TERRONBATTLE'; MaxValue: 0),
      (Key: 'PIRATESYSTEMS'; MaxValue: 0),
      (Key: 'NODES'; MaxValue: 0),
      (Key: 'RATING'; MaxValue: 0),
      (Key: 'RUINS'; MaxValue: 20),
      (Key: 'PIRATEWIN'; MaxValue: 0),
      (Key: 'BEST'; MaxValue: 0),
      (Key: 'COMMANDOR'; MaxValue: 0),
      (Key: 'BARON'; MaxValue: 0),
      (Key: 'GIRLSQUEST'; MaxValue: 0),
      (Key: 'GIRLSHIRE'; MaxValue: 0),
      (Key: 'SHU'; MaxValue: 0),
      (Key: 'SIDECHANGER'; MaxValue: 15),
      (Key: 'ENERGY'; MaxValue: 250),
      (Key: 'SCRATCHDAMAGE'; MaxValue: 0),
      (Key: 'SPLINTER'; MaxValue: 200),
      (Key: 'EXPLORER'; MaxValue: 100),
      (Key: 'TRANCLUCATORS'; MaxValue: 0),
      (Key: 'SUNFUEL'; MaxValue: 0),
      (Key: 'TERRORIST'; MaxValue: 30),
      (Key: 'COUNTERTERRORIST'; MaxValue: 30),
      (Key: 'BLUEKILLS'; MaxValue: 500),
      (Key: 'GREENKILLS'; MaxValue: 500),
      (Key: 'REDKILLS'; MaxValue: 500),
      (Key: 'BERTORSLAYER'; MaxValue: 50),
      (Key: 'MAPBUILDER'; MaxValue: 0),
      (Key: 'HACKER'; MaxValue: 100),
      (Key: 'DELIVERY'; MaxValue: 50),
      (Key: 'INVESTOR'; MaxValue: 0),
      (Key: 'INSURANCE'; MaxValue: 0),
      (Key: 'PRISONBAIL'; MaxValue: 30),
      (Key: 'ROBBER'; MaxValue: 100),
      (Key: 'WARRIORKILLS'; MaxValue: 100),
      (Key: 'DRAIN'; MaxValue: 10000)
  );
type
  TAchievementStats = class;
  TAchievementStats = class(TObject)
    AsteroidsDestroyed: Integer;
    EnemiesDestroyedByStarHeat: Integer;
    SystemsDefended: Integer;
    SystemsCapturedForPirates: Integer;
    CompletedResearchPrograms: Byte;
    Gap15: array[0..2] of Byte;
    SuccessfulDominatorHacks: Integer;
    PrisonersBailedOut: Integer;
    DrainedHullPoints: Integer;
    StarFuelCollected: Cardinal;
    StarFuelTankId: Integer;
    UninhabitedPlanetsVisited: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure CheckBomberAchievement(KillsThisTurn: Integer);
    procedure CheckAllAwardsAchievement;
    procedure CheckNoQuestVictoryAchievement;
    procedure CheckChampionVictoryAchievement(Score: Integer);
    procedure CheckNoLoadVictoryAchievement;
    procedure CheckNoShotsArcadeVictoryAchievement;
    procedure CheckMoneyAchievement;
    procedure CheckMasterAchievement;
    procedure CheckNodesAchievement;
    procedure CheckLongGameVictoryAchievement(Score: Integer; FinishedTurn: Integer);
    procedure CheckPacifistVictoryAchievement;
    procedure CheckAllPirateSystemsAchievement;
    procedure CheckFirstPlaceRatingAchievement;
    procedure CheckAllSkillsAchievement;
    procedure CheckSpeedAchievement;
    procedure CheckFastVictoryAchievement;
    procedure CheckScienceAchievement;
    procedure CheckBaronAchievement;
    procedure CheckCommanderAchievement;
    procedure CheckHaterAchievement;
    procedure CheckBestEquipmentAchievement;
    procedure CheckAllDiseasesAchievement;
    procedure CheckAllDrugsAchievement;
    procedure CheckScratchDamageAchievement(HitsReceived: Integer);
    procedure CheckStarFuelAchievement;
    procedure CheckMapBuilderAchievement;
    procedure CheckInvestorAchievement(Amount: Integer);
    procedure CheckTranclucatorFleetAchievement;
  end;
var
  AchievementDefinitions: TBlockParEC = nil;
function GetCurrentAchievementProgress(Key: WideString; StoredValue: Integer): Integer;
procedure InitializeAchievementDefinitions;
function GetAchievementBackend: Byte;
function GetAvailableAchievementCount: Integer;
function TryUnlockAchievement(Key: WideString): Boolean;
function TryAddAchievementProgress(Key: WideString; Amount: Integer): Boolean;
function TrySetAchievementProgress(Key: WideString; Value: Integer): Boolean;
function GetAchievementData(Key: WideString): PAchievementData;
function CreateAchievementData: PAchievementData;
procedure FreeAchievementData(Data: PAchievementData);
procedure LinkRecoveredTypes;
implementation
uses
  aRanger,
  aShip,
  aTranclucator,
  SysUtils,
  Math,
  WStringUtils,
  NoSteamAchievemens,
  GlobalsV,
  aPlayer,
  aGalaxy,
  aPlanet,
  aGalaxyStruct,
  GR_Main;
// @unit-initialization $8778A8
// @unit-finalization $594CA8

function GetCurrentAchievementProgress(Key: WideString; StoredValue: Integer): Integer;
var
  Stats: TAchievementStats;
begin
  Result := 0;
  if (Galaxy <> nil) and not Galaxy.Destroying and (GetPlayer <> nil) then
  begin
    Stats := GetPlayer.AchievementStats;
    if Key = 'ASTEROID' then
      Result := Stats.AsteroidsDestroyed
    else if Key = 'FRY' then
      Result := Stats.EnemiesDestroyedByStarHeat
    else if Key = 'DEFENDER' then
      Result := Stats.SystemsDefended
    else if Key = 'PIRATE' then
      Result := Stats.SystemsCapturedForPirates
    else if Key = 'SCIENCE' then
      Result := Integer(Stats.CompletedResearchPrograms)
    else if Key = 'HACKER' then
      Result := Stats.SuccessfulDominatorHacks
    else if Key = 'PRISONBAIL' then
      Result := Stats.PrisonersBailedOut
    else if Key = 'DRAIN' then
      Result := Stats.DrainedHullPoints
    else if Key = 'BERTORSLAYER' then
      Result := GetPlayer.DominatorKillsByType[Ord(ktBertor)]
    else if Key = 'SIDECHANGER' then
      Result := GetPlayer.SideChangeCount;
    if Result = StoredValue then
      Result := 0;
  end;
end;

constructor TAchievementStats.Create;
begin
  inherited Create;
  AsteroidsDestroyed := 0;
  EnemiesDestroyedByStarHeat := 0;
  SystemsDefended := 0;
  SystemsCapturedForPirates := 0;
  CompletedResearchPrograms := 0;
  SuccessfulDominatorHacks := 0;
  PrisonersBailedOut := 0;
  DrainedHullPoints := 0;
  StarFuelCollected := 0;
  StarFuelTankId := 0;
  UninhabitedPlanetsVisited := 0;
end;

destructor TAchievementStats.Destroy;
begin
  inherited Destroy;
end;

procedure TAchievementStats.LoadFromBuffer(Buffer: TBufEC);
begin
  if LoadedSaveVersion >= 99 then
  begin
    AsteroidsDestroyed := Buffer.GetUInt32;
    EnemiesDestroyedByStarHeat := Buffer.GetUInt32;
    SystemsDefended := Buffer.GetUInt32;
    SystemsCapturedForPirates := Buffer.GetUInt32;
    CompletedResearchPrograms := Buffer.GetByte;
    SuccessfulDominatorHacks := Buffer.GetUInt32;
    PrisonersBailedOut := Buffer.GetUInt32;
    DrainedHullPoints := Buffer.GetUInt32;
    StarFuelCollected := Buffer.GetUInt32;
    StarFuelTankId := Buffer.GetUInt32;
    UninhabitedPlanetsVisited := Buffer.GetUInt32;
  end
  else
  begin
    AsteroidsDestroyed := Buffer.GetUInt32;
    Buffer.GetUInt32;
    Buffer.GetUInt32;
    Buffer.GetUInt32;
    EnemiesDestroyedByStarHeat := Buffer.GetUInt32;
    Buffer.GetUInt32;
    Buffer.GetUInt32;
    SystemsDefended := Buffer.GetUInt32;
    SystemsCapturedForPirates := Buffer.GetUInt32;
    CompletedResearchPrograms := Buffer.GetByte;
    Buffer.GetUInt32;
    Buffer.GetUInt32;
    Buffer.GetUInt32;
    SuccessfulDominatorHacks := 0;
    PrisonersBailedOut := 0;
    DrainedHullPoints := 0;
    StarFuelCollected := 0;
    StarFuelTankId := 0;
    UninhabitedPlanetsVisited := 0;
  end;
end;

procedure TAchievementStats.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(AsteroidsDestroyed);
  Buffer.AddDWord(EnemiesDestroyedByStarHeat);
  Buffer.AddDWord(SystemsDefended);
  Buffer.AddDWord(SystemsCapturedForPirates);
  Buffer.AddAnsiChar(AnsiChar(CompletedResearchPrograms));
  Buffer.AddDWord(SuccessfulDominatorHacks);
  Buffer.AddDWord(PrisonersBailedOut);
  Buffer.AddDWord(DrainedHullPoints);
  Buffer.AddDWord(StarFuelCollected);
  Buffer.AddDWord(StarFuelTankId);
  Buffer.AddDWord(UninhabitedPlanetsVisited);
end;

procedure TAchievementStats.CheckBomberAchievement(KillsThisTurn: Integer);
begin
  if GetPlayer = nil then
    Exit;
  if Galaxy = nil then
    Exit;
  if KillsThisTurn >= 5 then
    TryUnlockAchievement('BOMBER');
end;

procedure TAchievementStats.CheckAllAwardsAchievement;
var
  I, LastAward: Integer;
  AllPresent: Boolean;
  AwardId: Byte;
  Present: array[0..255] of Boolean;
begin
  { Native argument order is reversed: count zero leaves this buffer uninitialized. }
  FillChar(Present, 0, SizeOf(Present));
  LastAward := StrToInt(LookupLocalizedTextByKey('Reward.Count')) - 1;
  AllPresent := True;
  if (GetPlayer <> nil) and (GetPlayer.AwardIds <> nil) then
  begin
    for I := 0 to GetPlayer.AwardIds.Count - 1 do
    begin
      AwardId := Byte(GetPlayer.AwardIds[I]);
      Present[AwardId] := True;
    end;
    for I := 0 to LastAward do
      AllPresent := AllPresent and Present[I];
    if AllPresent then
      TryUnlockAchievement('BREZHNEV');
  end;
end;

procedure TAchievementStats.CheckNoQuestVictoryAchievement;
var
  I: Integer;
  Quest: PPlayerOldQuest;
begin
  if GetPlayer <> nil then
    if PlayerOldQuests <> nil then
      for I := 0 to PlayerOldQuests.Count - 1 do
      begin
        Quest := PlayerOldQuests[I];
        if Quest.Successful then
          Exit;
      end;
  TryUnlockAchievement('BUMMER');
end;

procedure TAchievementStats.CheckChampionVictoryAchievement(Score: Integer);
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (Score >= 50000) then
    TryUnlockAchievement('CHAMPION');
end;

procedure TAchievementStats.CheckNoLoadVictoryAchievement;
begin
  if (Galaxy <> nil) and (Galaxy.LoadCount = 0) then
    TryUnlockAchievement('KIBERMAN');
end;

procedure TAchievementStats.CheckNoShotsArcadeVictoryAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) then
    TryUnlockAchievement('HOLEPEACE');
end;

procedure TAchievementStats.CheckMoneyAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.Money >= 10000000) then
    TryUnlockAchievement('MONEY');
end;

procedure TAchievementStats.CheckMasterAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.CountWingmen >= 6) then
    TryUnlockAchievement('MASTER');
end;

procedure TAchievementStats.CheckNodesAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.BaseNodes >= 25000) then
    TryUnlockAchievement('NODES');
end;

procedure TAchievementStats.CheckLongGameVictoryAchievement(Score, FinishedTurn: Integer);
begin
  if (GetPlayer <> nil) and (Score >= 20000) and (FinishedTurn >= 36800) then
    TryUnlockAchievement('DOLGOZHID');
end;

procedure TAchievementStats.CheckPacifistVictoryAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.TotalShipKillCount = 0) then
    TryUnlockAchievement('PEACELOVER');
end;

procedure TAchievementStats.CheckAllPirateSystemsAchievement;
var
  Index: Integer;
  Star: TStar;
  AllPirateSystems: Boolean;
begin
  AllPirateSystems := True;
  for Index := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := Galaxy.Stars[Index];
    if Star.ControlFaction <> sfPirates then
    begin
      AllPirateSystems := False;
      Break;
    end;
  end;
  if AllPirateSystems then
    TryUnlockAchievement('PIRATESYSTEMS');
end;

procedure TAchievementStats.CheckFirstPlaceRatingAchievement;
begin
  if (GetPlayer <> nil)
      and (Galaxy <> nil)
      and (Galaxy.CurrentTurn >= 300)
      and (GetPlayer.PlaceInRating = 1) then
    TryUnlockAchievement('RATING');
end;

procedure TAchievementStats.CheckAllSkillsAchievement;
var
  Skill: TPilotSkill;
  Complete: Boolean;
begin
  Complete := True;
  if (GetPlayer <> nil) and (Galaxy <> nil) then
  begin
    for Skill := Low(TPilotSkill) to High(TPilotSkill) do
      if GetPlayer.GetBaseSkillLevel(Skill) < 6 then
        Complete := False;
    if Complete then
      TryUnlockAchievement('SKILL');
  end;
end;

procedure TAchievementStats.CheckSpeedAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.CalculateSpeed >= 2300) then
    TryUnlockAchievement('SPEED');
end;

procedure TAchievementStats.CheckFastVictoryAchievement;
var
  Elapsed: Integer;
begin
  if Galaxy <> nil then
  begin
    Elapsed := Galaxy.CurrentTurn - 300;
    if Elapsed / 365.0 < 7.0 then
      TryUnlockAchievement('SPRINTER');
  end;
end;

procedure TAchievementStats.CheckScienceAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (CompletedResearchPrograms >= 3) then
    TryUnlockAchievement('SCIENCE');
end;

procedure TAchievementStats.CheckBaronAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.PirateRank = 7) then
    TryUnlockAchievement('BARON');
end;

procedure TAchievementStats.CheckCommanderAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (GetPlayer.Rank = 7) then
    TryUnlockAchievement('COMMANDOR');
end;

procedure TAchievementStats.CheckHaterAchievement;
var
  I, J, Count: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  Count := 0;
  if (GetPlayer = nil) or (Galaxy = nil) then
    Exit;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := Galaxy.Stars[I];
    if Star.ControlFaction = sfCoalition then
      for J := 0 to Star.Planets.Count - 1 do
      begin
        Planet := Star.Planets[J];
        if Planet.OwnerId <> Byte(oiUninhabited) then
        begin
          Inc(Count);
          if Planet.GetRelationLevelToShip(GetPlayer) > rlHostile then
            Exit;
        end;
      end;
  end;
  if Count > 0 then
    TryUnlockAchievement('HATER');
end;

procedure TAchievementStats.CheckBestEquipmentAchievement;
var
  I: Integer;
begin
  if (GetPlayer = nil) or (Galaxy = nil) then
    Exit;
  if GetPlayer.GetHull.HasStandardStats then
    Exit;
  if (GetPlayer.GetFuelTanks = nil) or GetPlayer.GetFuelTanks.HasStandardStats then
    Exit;
  if (GetPlayer.GetEngine = nil) or GetPlayer.GetEngine.HasStandardStats then
    Exit;
  if (GetPlayer.GetRadar = nil) or GetPlayer.GetRadar.HasStandardStats then
    Exit;
  if (GetPlayer.GetScanner = nil) or GetPlayer.GetScanner.HasStandardStats then
    Exit;
  if (GetPlayer.GetRepairRobot = nil) or GetPlayer.GetRepairRobot.HasStandardStats then
    Exit;
  if (GetPlayer.GetCargoHook = nil) or GetPlayer.GetCargoHook.HasStandardStats then
    Exit;
  if (GetPlayer.GetDefGenerator = nil) or GetPlayer.GetDefGenerator.HasStandardStats then
    Exit;
  if GetPlayer.CountEquippedWeapons < 5 then
    Exit;
  for I := 1 to 5 do
    if GetPlayer.Weapons[I].HasStandardStats then
      Exit;
  TryUnlockAchievement('BEST');
end;

procedure TAchievementStats.CheckAllDiseasesAchievement;
var
  I: Integer;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) then
  begin
    for I := 1 to 12 do
      if GetPlayer.CaptainHealth[I].ApplicationCount = 0 then
        Exit;
    TryUnlockAchievement('ILL');
  end;
end;

procedure TAchievementStats.CheckAllDrugsAchievement;
var
  I: Integer;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) then
  begin
    for I := 13 to 24 do
      if GetPlayer.CaptainHealth[I].ApplicationCount = 0 then
        Exit;
    TryUnlockAchievement('NARKOMAN');
  end;
end;

procedure TAchievementStats.CheckScratchDamageAchievement(HitsReceived: Integer);
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (HitsReceived >= 20) then
    TryUnlockAchievement('SCRATCHDAMAGE');
end;

procedure TAchievementStats.CheckStarFuelAchievement;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (StarFuelCollected >= 40) then
    TryUnlockAchievement('SUNFUEL');
end;

procedure TAchievementStats.CheckMapBuilderAchievement;
var
  I: Integer;
  Constellation: TConstellation;
  Year, Month, Day: Word;
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) then
  begin
    DecodeDate(GameTurnToDateTime(Galaxy.CurrentTurn - 300), Year, Month, Day);
    if Year > 3304 then
      Exit;
    if (Year = 3304) and ((Month > 1) or (Day > 1)) then
      Exit;
    for I := 0 to Galaxy.Constellations.Count - 1 do
    begin
      Constellation := TConstellation(Galaxy.Constellations[I]);
      if (not Constellation.Visible) and (Constellation.Id <> 20) then
        Exit;
    end;
    TryUnlockAchievement('MAPBUILDER');
  end;
end;

procedure TAchievementStats.CheckInvestorAchievement(Amount: Integer);
begin
  if (GetPlayer <> nil) and (Galaxy <> nil) and (Amount >= 300000) then
    TryUnlockAchievement('INVESTOR');
end;

procedure TAchievementStats.CheckTranclucatorFleetAchievement;
var
  I, Count: Integer;
  Ship: TShip;
  Star: TStar;
begin
  if GetPlayer = nil then
    Exit;
  if Galaxy = nil then
    Exit;
  Count := 0;
  Star := GetPlayer.CurrentStar;
  for I := 0 to Star.Ships.Count - 1 do
  begin
    Ship := Star.Ships[I];
    if Ship.InNormalSpace
        and not Ship.IsHullDestroyed
        and (Ship is TTranclucator)
        and ((Ship as TTranclucator).OwnerShip = GetPlayer) then
      Inc(Count);
  end;
  if Count >= 10 then
    TryUnlockAchievement('TRANCLUCATORS');
end;

procedure InitializeAchievementDefinitions;
var
  Index: Integer;
  Block: TBlockParEC;
begin
  AchievementDefinitions := TBlockParEC.Create;
  // Entry zero is the native NONE sentinel and is not registered.
  for Index := 1 to 82 do
  begin
    Block :=
        AchievementDefinitions.AddChildBlock(WideString(AchievementDefinitionTable[Index].Key));
    Block.AddParam('Id', WideString(AchievementDefinitionTable[Index].Key));
    Block.AddParam('Num', WideString(IntToStr(Index - 1)));
    Block.AddParam('MaxValue', WideString(IntToStr(AchievementDefinitionTable[Index].MaxValue)));
    Block.AddParam('Value', '0');
    Block.AddParam('Achieved', 'No');
    Block.AddParam('Date', '0');
  end;
end;

function GetAchievementBackend: Byte;
begin
  if SteamInitialized then
  begin
    if SteamAchievementsCount > 0 then
      Result := 1
    else
      Result := 2;
  end
  else
    Result := 3;
end;

function GetAvailableAchievementCount: Integer;
begin
  case GetAchievementBackend of
    1: Result := Min(82, SteamAchievementsCount);
    3: Result := 82;
    2: Result := 0;
  else
    Result := 0;
  end;
end;

function TryUnlockAchievement(Key: WideString): Boolean;
var
  Block: TBlockParEC;
begin
  Result := False;
  if Galaxy = nil then
    Exit;
  if not Galaxy.CanRecordAchievements then
    Exit;
  if (GetPlayer <> nil) and (GetPlayer.AwardedAchievementKeys.CountBlocks(Key) > 0) then
    Exit;
  if GetAvailableAchievementCount <= 0 then
    Exit;
  Block := AchievementDefinitions.FindBlock(Key);
  if Block = nil then
    Exit;
  case GetAchievementBackend of
    1: Result := SteamUnlockAchievement(StrToInt(AnsiString(Block.GetParam('Num'))));
    3: Result := UnlockLocalAchievement(Block);
    2: Result := False;
  else
    Result := False;
  end;
  if Result and (GetPlayer <> nil) then
    GetPlayer.AwardedAchievementKeys.AddChildBlock(Key);
end;

function TryAddAchievementProgress(Key: WideString; Amount: Integer): Boolean;
var
  Data: PAchievementData;
  Increment: Integer;
  Block: TBlockParEC;
begin
  Result := False;
  if Galaxy = nil then
    Exit;
  if not Galaxy.CanRecordAchievements then
    Exit;
  if (GetPlayer <> nil) and (GetPlayer.AwardedAchievementKeys.CountBlocks(Key) > 0) then
    Exit;
  if GetAvailableAchievementCount <= 0 then
    Exit;
  Block := AchievementDefinitions.FindBlock(Key);
  if Block = nil then
    Exit;
  Data := GetAchievementData(Key);
  if Amount + Data.Value <= Data.MaxValue then
    Increment := Amount
  else
    Increment := Data.MaxValue - Data.Value;
  case GetAchievementBackend of
    1: Result := SteamIncreaseStat(StrToInt(AnsiString(Block.GetParam('Num'))), Increment);
    3: Result := IncreaseLocalAchievementProgress(Block, Increment);
    2: Result := False;
  else
    Result := False;
  end;
  FreeAchievementData(Data);
  Data := GetAchievementData(Key);
  if (GetPlayer <> nil) and Data.Achieved then
    GetPlayer.AwardedAchievementKeys.AddChildBlock(Key);
  FreeAchievementData(Data);
end;

function TrySetAchievementProgress(Key: WideString; Value: Integer): Boolean;
var
  Data: PAchievementData;
  Increment: Integer;
  Block: TBlockParEC;
begin
  Result := False;
  if Galaxy = nil then
    Exit;
  if not Galaxy.CanRecordAchievements then
    Exit;
  if (GetPlayer <> nil) and (GetPlayer.AwardedAchievementKeys.CountBlocks(Key) > 0) then
    Exit;
  if GetAvailableAchievementCount <= 0 then
    Exit;
  Block := AchievementDefinitions.FindBlock(Key);
  if Block = nil then
    Exit;
  Data := GetAchievementData(Key);
  if (Value > Data.Value) and (Value <= Data.MaxValue) then
    Increment := Value - Data.Value
  else if Value > Data.MaxValue then
    Increment := Data.MaxValue - Data.Value
  else
  begin
    FreeAchievementData(Data);
    Exit;
  end;
  case GetAchievementBackend of
    1: Result := SteamIncreaseStat(StrToInt(AnsiString(Block.GetParam('Num'))), Increment);
    3: Result := IncreaseLocalAchievementProgress(Block, Increment);
    2: Result := False;
  else
    Result := False;
  end;
  FreeAchievementData(Data);
  Data := GetAchievementData(Key);
  if (GetPlayer <> nil) and Data.Achieved then
    GetPlayer.AwardedAchievementKeys.AddChildBlock(Key);
  FreeAchievementData(Data);
end;

function GetAchievementData(Key: WideString): PAchievementData;
var
  Block: TBlockParEC;
begin
  Result := nil;
  Block := AchievementDefinitions.FindBlock(Key);
  if Block <> nil then
  begin
    Result := CreateAchievementData;
    case GetAchievementBackend of
      1: SteamAchievementData(StrToInt(AnsiString(Block.GetParam('Num'))), Result);
      3: GetLocalAchievementData(Key, Result);
    end;
    TruncateStartupWideString(Result.Name);
    TruncateStartupWideString(Result.Description);
    TruncateStartupWideString(Result.IconPath);
  end;
end;

function CreateAchievementData: PAchievementData;
begin
  New(Result);
  Result.Name := AllocateStartupWideString(255);
  Result.Description := AllocateStartupWideString(255);
  Result.Achieved := False;
  Result.HasProgress := False;
  Result.Reserved0C := 0;
  Result.MaxValue := 0;
  Result.Value := 0;
  Result.IconPath := AllocateStartupWideString(255);
  Result.Date := 0;
end;

procedure FreeAchievementData(Data: PAchievementData);
begin
  if Data <> nil then
  begin
    FreeStartupWideString(Data.Name);
    FreeStartupWideString(Data.Description);
    FreeStartupWideString(Data.IconPath);
    Dispose(Data);
  end;
end;

procedure LinkRecoveredTypes;
begin
  TTranclucator.ClassName;
end;
end.
