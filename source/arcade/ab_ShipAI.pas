{$EXCESSPRECISION OFF}
unit ab_ShipAI;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_Tail,
  ab_Global,
  ab_Object,
  ab_Ship,
  ab_Zone,
  ab_Item,
  aItem;
const
  amUnselected = -1;
  amApproach = 0;
  amCloseEvasion = 1;
  amFlank = 2;
  amReverseTurn = 3;
  amFollowReverse = 4;
type
  TabShipAI = class;
  TabShipAI = class(TabShip)
    CurrentZone: PabZone;
    InsideCurrentZone: Boolean;
    Gap2E5: array[0..2] of Byte;
    CurrentZoneBearing: Double;
    CurrentZoneAngularRadius: Double;
    HeadingInsideCurrentZone: Boolean;
    Gap2F9: array[0..2] of Byte;
    TargetShip: TabShip;
    TargetBearing: TSphericalBearingDistance;
    ReverseTargetBearing: TSphericalBearingDistance;
    TargetPathClear: Boolean;
    Gap321: array[0..2] of Byte;
    RouteZone: PabZone;
    RouteBearing: Double;
    RouteAngularRadius: Double;
    HeadingInsideRoute: Boolean;
    DirectPathClear: Boolean;
    Gap33A: array[0..5] of Byte;
    DirectBearing: TSphericalBearingDistance;
    DirectTargetLongitude: Double;
    DirectTargetPolarAngle: Double;
    Intent: Integer;
    CombatManeuver: Integer;
    ManeuverUntilTick: Integer;
    TargetBonus: TabItem;
    BonusRouteZone: PabZone;
    AvoidanceZone: PabZone;
    DamagingZone: PabZone;
    LastDamageTick: Integer;
    RecentHitCount: Integer;
    IncomingThreat: Boolean;
    RetreatRequested: Boolean;
    AIEnabled: Boolean;
    Gap387: array[0..0] of Byte;
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override;
    procedure UpdateState; override;
    procedure Advance; override;
    constructor Create;
    destructor Destroy; override;
    function GetRewardItem(Preview: Boolean): TItem;
    procedure NoticeCollision;
    procedure NoticeDamagingZone(Zone: PabZone);
    procedure ResetIntent;
    procedure DecideActions;
    procedure SetDirectDestination(Longitude: Single; PolarAngle: Single);
    procedure FollowDirectDestination;
    procedure AvoidImmediateObstacle;
    procedure ClearRoute;
    procedure SetRoute(Target: PabZone);
    procedure FollowRoute;
    procedure ApproachTarget;
    function ScoreApproach: Integer;
    procedure EvadeCloseTarget;
    function ScoreCloseEvasion: Integer;
    procedure FlankTarget;
    function ScoreFlanking: Integer;
    procedure ReverseTowardTarget;
    function ScoreReverseTurn: Integer;
    procedure MatchReversingTarget;
    function ScoreReverseFollowing: Integer;
    function TryMoveToDestination(Zone: PabZone; Longitude: Double; PolarAngle: Double): Boolean;
    procedure SetAndFollowRoute(Target: PabZone);
    procedure FollowDestinationRoute;
  end;
procedure LinkRecoveredTypes;
implementation
uses
  aCalc,
  Math,
  aMyFunction,
  ab_StopLine,
  GlobalsV,
  Globals,
  aGalaxy,
  aGalaxyEvent,
  aGalaxyStruct,
  aPlayer,
  aShip,
  aConst,
  aTranclucator,
  ab_Space,
  fShip2,
  Achievements,
  aNormalShip;
// Source helper: preserve the native full-width load before a Byte stack argument.
// Passing the local directly lets DCC32 narrow MOV EAX to MOV AL. This identity
// inlines without a call, extra assignment or temporary in ApplyDamage.
function RewardTechArgument(const Value: Integer): Integer; inline;
begin
  Result := Value;
end;
// Source helper: keep the seed evaluation before both clamps, with their
// temporaries preceding the seed slot in the native frame.
procedure SelectArcadeRewardWeapon(
    const Ship: TabShipAI;
    const Tech: Integer;
    var Info: PWeaponInfo
); inline;
var
  MaximumTech, MinimumTech: Integer;
  Seed: Cardinal;
begin
  Seed := Ship.RandomRange(1, 100000);
  if Tech + 1 < 8 then
    MaximumTech := Tech + 1
  else
    MaximumTech := 8;
  if Tech - 1 < 1 then
    MinimumTech := 1
  else
    MinimumTech := Tech - 1;
  Info :=
      Galaxy.SelectWeaponInfo(
          Seed,
          [0],
          RewardTechArgument(MaximumTech),
          RewardTechArgument(MinimumTech)
      );
end;

constructor TabShipAI.Create;
begin
  inherited Create;
  CombatManeuver := amUnselected;
  AIEnabled := True;
end;

destructor TabShipAI.Destroy;
begin
  if RewardObject <> nil then
  begin
    RewardObject.Free;
    RewardObject := nil;
  end;
  inherited Destroy;
end;

function TabShipAI.GetRewardItem(Preview: Boolean): TItem;
var
  Reward: TItem;
  LivingEnemies, Index, RepeatPenalty: Integer;
  SavedRandomState, SavedNextItemId: Cardinal;
  KellerPresent, UsedSubportal: Boolean;
  Event: TGalaxyEvent;
  Hole: THole;
  SavedChaoticRandom: Boolean;
begin
  Result := nil;
  if (GetPlayer <> nil) and (PlayerArcadeShip <> nil) then
    if RewardObject <> nil then
    begin
      if (RewardObject is TArtefact) and not Preview then
      begin
        Result := TItem(RewardObject);
        RewardObject := nil;
      end;
    end
    else if not RandomRewardsDisabled then
    begin
      UsedSubportal := False;
      RepeatPenalty := 0;
      if (GetPlayer.Order = soJumpHole)
          and (GetPlayer.OrderTarget <> nil)
          and (GetPlayer.OrderTarget is THole) then
      begin
        Hole := GetPlayer.OrderTarget as THole;
        for Index := Galaxy.GalaxyEvents.Count - 1 downto 0 do
        begin
          Event := TGalaxyEvent(Galaxy.GalaxyEvents[Index]);
          if (Event.EventType = 'PlayerUsesSubportal')
              and (Event.GetData(0) = Integer(Hole.Id))
              and (Event.GetData(1) = Hole.CreatedTurn) then
          begin
            UsedSubportal := True;
            Break;
          end;
        end;
      end;
      if UsedSubportal then
        for Index := Galaxy.GalaxyEvents.Count - 1 downto 0 do
        begin
          Event := TGalaxyEvent(Galaxy.GalaxyEvents[Index]);
          if Event.Turn + SubportalRewardPenaltyTurns < Galaxy.CurrentTurn then
            Break;
          if Event.EventType = 'PlayerJumpsThroughSubportal' then
            Inc(RepeatPenalty, SubportalRewardPenalty);
        end;
      Reward := nil;
      LivingEnemies := 0;
      KellerPresent := False;
      for Index := 0 to PlayerArcadeShip.Enemies.Count - 1 do
      begin
        if (KellerArcadeShip <> nil)
            and (PlayerArcadeShip.Enemies[Index] = KellerArcadeShip)
            and (KellerArcadeShip <> Self) then
          KellerPresent := True;
        if (TObject(PlayerArcadeShip.Enemies[Index]) is TabShip)
            and (TabShip(PlayerArcadeShip.Enemies[Index]).Health > 0) then
          Inc(LivingEnemies);
      end;
      Index := 0;
      SavedRandomState := RandomState;
      RandomState := InitialRandomSeed;
      SavedChaoticRandom := False;
      SavedNextItemId := 0;
      if Galaxy <> nil then
      begin
        SavedChaoticRandom := Galaxy.CustomRules.ChaoticRandom;
        Galaxy.CustomRules.ChaoticRandom := False;
        SavedNextItemId := Galaxy.NextItemId;
      end;
      if (ArcadeKellerDefeats = 0)
          and not KellerPresent
          and (GetPlayer.Order = soJumpHole)
          and ((LivingEnemies = 0) or Preview)
          and ((LivingEnemies + GetPlayer.BlackHoleKillCount < 20)
              or (RandomRange(0, 100) > RepeatPenalty + 30)) then
      begin
        while Reward = nil do
        begin
          Inc(Index);
          Reward := CreateRandomLootItem(ilpArcadeBattle, 6, AdvanceRandomSeed(RandomState));
          if GetPlayer.HasMatchingArtefactOrCustomItem(Reward) and (Index < 5) then
          begin
            Reward.Free;
            Reward := nil;
            Galaxy.NextItemId := SavedNextItemId;
          end
          else if (GetPlayer.GetBaseCargoHookPower > 0)
              and (GetPlayer.GetBaseCargoHookPower < Reward.Weight)
              and (LivingEnemies + GetPlayer.BlackHoleKillCount < 5)
              and (Index < 5) then
          begin
            Reward.Free;
            Reward := nil;
            Galaxy.NextItemId := SavedNextItemId;
          end
          else
            Break;
        end;
        if Reward is TArtefactTranclucator then
          (TObject((Reward as TArtefactTranclucator).Ship) as TTranclucator).OwnerShip := GetPlayer;
      end;
      RandomState := SavedRandomState;
      if Galaxy <> nil then
      begin
        Galaxy.CustomRules.ChaoticRandom := SavedChaoticRandom;
        if Preview then
          Galaxy.NextItemId := SavedNextItemId;
      end;
      if UsedSubportal and not Preview and (LivingEnemies = 0) then
        AddGalaxyEvent('PlayerJumpsThroughSubportal');
      Result := Reward;
    end;
end;

procedure TabShipAI.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
type
  TUnusedCompilerLocal = record
  end;
var
  Index, Attempts: Integer;
  Item: TEquipment;
  Reward: TItem;
  // Native has 16 unreferenced bytes between Reward and LivingEnemies,
  // and another 16 between RewardScale and SavedNextItemId. Original
  // local types and allocation remain unresolved.
  // These zero-sized source-only locals preserve DCC32's local-slot ordering;
  // they do not represent additional native storage or recovered source types.
  UnusedCompilerA, UnusedCompilerB, UnusedCompilerC, UnusedCompilerD: TUnusedCompilerLocal;
  Unused20, Unused24, Unused28, Unused2C: Integer;
  LivingEnemies: Integer;
  RewardScale: Single;
  Unused38, Unused3C, Unused40, Unused44: Integer;
  SavedNextItemId: Cardinal;
  Event: TGalaxyEvent;
  ItemType: Byte;
  Weight, Level: Integer;
  Info: PWeaponInfo;
  MinSize, MaxSize: Single;
  MinLevel, MaxLevel, WeaponTech: Integer;
  procedure AddArcadeRewardToList(
      Item: TObject
  ); // @addr $4FE88C @ida "void __usercall $name(TObject *Item@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4febc2,0x4fec53,0x4ff186,0x4ff35c"
  begin
    ArcadeBattleScreen.ListedObjects.Add(Item);
  end;
begin
  if Health > 0 then
  begin
    if (Galaxy <> nil) and (Galaxy.KellerLeaveTurn > 0) and (KellerArcadeShip = Self) then
      Exit;
    inherited ApplyDamage(Amount, Source, Disrupt);
    LastDamageTick := ArcadeTickCount;
    Inc(RecentHitCount);
    if (GetPlayer <> nil)
        and (Health <= 0)
        and (PlayerArcadeShip <> nil)
        and (Enemies.IndexOf(PlayerArcadeShip) < 0) then
    begin
      if Galaxy <> nil then
        if ScriptLabel <> '' then
        begin
          Event := AddGalaxyEvent('LabeledShipKilledInAB');
          Event.AddTextData(ScriptLabel);
        end;
    end
    else if (GetPlayer <> nil)
        and (Health <= 0)
        and (PlayerArcadeShip <> nil)
        and (Enemies.IndexOf(PlayerArcadeShip) >= 0) then
    begin
      aCalc.WaitForTurnCalculationUI;
      LivingEnemies := 0;
      for Index := 0 to PlayerArcadeShip.Enemies.Count - 1 do
        if (TObject(PlayerArcadeShip.Enemies[Index]) is TabShip)
            and (TabShip(PlayerArcadeShip.Enemies[Index]).Health > 0) then
          Inc(LivingEnemies);
      RandomState := InitialRandomSeed;
      if GetPlayer.Order = soJumpHole then
      begin
        Inc(GetPlayer.BlackHoleKillCount);
        TryAddAchievementProgress('HOLEMAN', 1);
      end
      else
      begin
        Inc(GetPlayer.HyperspaceKillCount);
        TryAddAchievementProgress('HOLEMAN', 1);
        if GetPlayer.InHyperspace and (GetPlayer.OwnerId <> Byte(oiPirate)) then
          GetPlayer.AddRankPoints(2);
      end;
      if (Galaxy <> nil) and (ScriptLabel <> '') then
      begin
        Event := AddGalaxyEvent('LabeledShipKilledInAB');
        Event.AddTextData(ScriptLabel);
      end;
      Reward := GetRewardItem(False);
      if Reward <> nil then
      begin
        if KellerArcadeShip = Self then
        begin
          GetPlayer.ScriptItemsAct(satOnABItemDrop, Reward, nil, 0);
          ArcadeKellerReward := Reward;
        end
        else
        begin
          ClearPlayerHoldEntries;
          GetPlayer.ScriptItemsAct(satOnABItemDrop, Reward, nil, 0);
          if Reward is TArtefact then
            GetPlayer.Artefacts.Insert(0, Reward)
          else
            GetPlayer.Inventory.Add(Reward);
        end;
        AddArcadeRewardToList(Reward);
      end
      else if RewardObject <> nil then
      begin
        ClearPlayerHoldEntries;
        GetPlayer.ScriptItemsAct(satOnABItemDrop, RewardObject, nil, 0);
        if RewardObject is TArtefact then
          GetPlayer.Artefacts.Insert(0, RewardObject)
        else
          GetPlayer.Inventory.Add(RewardObject);
        AddArcadeRewardToList(RewardObject);
        RewardObject := nil;
        GetPlayer.RefreshDerivedStats(True);
      end
      else if ((LivingEnemies = 0)
              or ((LivingEnemies = 1) and (RandomRange(0, 100) * LuckScale > 50))
              or ((LivingEnemies >= 2) and (RandomRange(0, 100) * LuckScale > 60)))
          and not RandomRewardsDisabled then
      begin
        Attempts := 0;
        RewardScale :=
            Galaxy.GetArcadeDropValueModifier
                * RemapClamped(LivingEnemies, 0, 5, 1.56, 0.26)
                * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[7]].ArcadeRewardScale;
        if GetPlayer.Order = soJumpHole then
        begin
          if LivingEnemies = 0 then
            RewardScale := RewardScale * 3
          else
            RewardScale := 1.2 * RewardScale;
        end
        else
          RewardScale :=
              RemapClamped(
                      CurrentArcadeSpace.Danger + CurrentArcadeSpace.ApproachDanger,
                      50,
                      250,
                      0.3,
                      2)
                  * RewardScale;
        MinSize :=
            RemapClamped(Galaxy.TechLevel, 3, 8, EquipmentSizeFactors[4], EquipmentSizeFactors[5]);
        MaxSize :=
            RemapClamped(Galaxy.TechLevel, 3, 8, EquipmentSizeFactors[2], EquipmentSizeFactors[4]);
        MinLevel := Round(RemapClamped(Galaxy.TechLevel, 3, 8, 0, 0.75) * 7 + 1);
        MaxLevel := Round(RemapClamped(Galaxy.TechLevel, 1, 7, 0.5, 1) * 7 + 1);
        SavedNextItemId := Galaxy.NextItemId;
        while True do
        begin
          if RandomRange(1, 110) > 70 then
          begin
            WeaponTech := RandomRange(Max(1, Galaxy.TechLevel - 1), Min(8, Galaxy.TechLevel + 1));
            SelectArcadeRewardWeapon(Self, WeaponTech, Info);
            Weight :=
                RandomRange(Round(Info.AverageSize * MinSize), Round(Info.AverageSize * MaxSize));
            Level := RandomRange(MinLevel, MaxLevel);
            Item := CreateGeneratedWeapon(Info, Weight, Level, 6);
          end
          else
          begin
            ItemType := PickRandomItemType([Ord(t_FuelTanks)..Ord(t_DefGenerator)]);
            Weight :=
                RandomRange(
                    Round(GetAverageItemSize(ItemType) * MinSize),
                    Round(GetAverageItemSize(ItemType) * MaxSize)
                );
            Level := RandomRange(MinLevel, MaxLevel);
            Item := CreateGeneratedEquipment(TItemType(ItemType), Weight, Level, 6);
          end;
          Item.ConditionPercent := SeededRandomFloatRange(Item.Id * (Attempts + 11) * 123, 10, 100);
          Inc(Attempts);
          if Attempts > 10000 then
          begin
            ClearPlayerHoldEntries;
            GetPlayer.ScriptItemsAct(satOnABItemDrop, Item, nil, 0);
            GetPlayer.Inventory.Insert(1, Item);
            GetPlayer.RefreshDerivedStats(True);
            AddArcadeRewardToList(Item);
            Break;
          end;
          if (GetPlayer.GetBaseCargoHookPower > 0)
              and (GetPlayer.GetBaseCargoHookPower < Item.Weight)
              and (GetPlayer.BlackHoleKillCount + GetPlayer.HyperspaceKillCount < 17) then
          begin
            Item.Free;
            Galaxy.NextItemId := SavedNextItemId;
            Continue;
          end;
          if ((Item.GetConditionAdjustedCost
                      < Max(
                          800,
                          GetPlayer.Wealth
                              * RemapClamped(
                                  Attempts,
                                  0,
                                  500,
                                  0.01 * RewardScale,
                                  0.03 * RewardScale)))
                  and ((Item.GetConditionAdjustedCost > GetPlayer.Wealth * 0.008 * RewardScale)
                      or (Attempts > 500)))
              <> False then
          begin
            ClearPlayerHoldEntries;
            GetPlayer.ScriptItemsAct(satOnABItemDrop, Item, nil, 0);
            GetPlayer.Inventory.Insert(1, Item);
            GetPlayer.RefreshDerivedStats(True);
            AddArcadeRewardToList(Item);
            Break;
          end;
          Item.Free;
          Galaxy.NextItemId := SavedNextItemId;
        end;
      end;
      if KellerArcadeShip = Self then
        Inc(ArcadeKellerDefeats);
      aCalc.WaitForTurnCalculationUI;
    end
    else if Source <> nil then
      if (TargetShip <> Source) and (Source is TabShip) and (Enemies.IndexOf(Source) >= 0) then
        if (TargetShip = nil) or (DistanceTo(TargetShip) > MaximumWeaponRange) then
          TargetShip := Source as TabShip;
  end;
end;

procedure TabShipAI.UpdateState;
begin
  inherited UpdateState;
  InsideCurrentZone :=
      ab_Zone_FindContainingOrNearest(State.LongitudeDegrees, State.PolarAngleDegrees, CurrentZone);
  HeadingInsideCurrentZone := False;
  CurrentZoneBearing := 0;
  if CurrentZone <> nil then
    if not InsideCurrentZone then
      HeadingInsideCurrentZone :=
          ab_Zone_IsHeadingInside(State, CurrentZone, CurrentZoneBearing, CurrentZoneAngularRadius);
end;

procedure TabShipAI.Advance;
var
  ForwardDistance, BackwardDistance: Double;
  Attempt, Index: Integer;
begin
  inherited Advance;
  if AIEnabled and (Health > 0) then
  begin
    if (ArcadeTickCount and 31) = 0 then
      RecentHitCount := 0;
    if (PlayerArcadeShip <> Self) or ArcadeAutopilotEnabled then
    begin
      if (WeaponCount > 1)
          and ((ArcadeTickCount and 31) = 0)
          and (Weapons[PrimaryWeapon].Ammo < Weapons[PrimaryWeapon].MaxAmmo / 4) then
        for Attempt := 0 to WeaponCount - 2 do
        begin
          Index := RandomRange(0, WeaponCount - 1);
          if (Weapons[Index].Ammo > Weapons[Index].MaxAmmo * 0.9)
              or (((Weapons[Index].Kind = 13) or (Weapons[Index].Kind = 14))
                  and (Weapons[Index].Ammo > Weapons[Index].MaxAmmo * 0.7)) then
          begin
            SelectWeapon(Index);
            Break;
          end;
        end;
      if (TargetShip <> nil) and (Enemies.IndexOf(TargetShip) < 0) then
        TargetShip := nil;
      if (TargetShip <> nil) and (TargetShip.Health <= 0) then
        TargetShip := nil;
      if (TargetShip <> nil)
          and (TargetShip.BonusTicks[abkInvisibility] > 0)
          and (TargetShip.RevealTicks <= 0) then
        TargetShip := nil;
      if TargetShip = nil then
        TargetShip := FindNearestEnemy(Self);
      if TargetShip <> nil then
      begin
        TargetBearing := BearingAndDistanceTo(TargetShip);
        ReverseTargetBearing := TargetShip.BearingAndDistanceTo(Self);
      end;
      TargetPathClear := False;
      if TargetShip <> nil then
      begin
        ab_StopLine_GetDistances(
            MakeSphericalBearingState(
                State.LongitudeDegrees,
                State.PolarAngleDegrees,
                WrapHeadingDegrees(State.BearingDegrees + TargetBearing.BearingDeltaDegrees)
            ),
            ForwardDistance,
            BackwardDistance
        );
        TargetPathClear := TargetBearing.Distance < ForwardDistance;
      end;
      DecideActions;
    end;
  end;
end;

procedure TabShipAI.NoticeCollision;
begin
  if (PlayerArcadeShip = Self) or (CurrentZone = nil) then
  begin
    AvoidanceZone := nil;
    Exit;
  end;
  AvoidanceZone := ab_Zone_RandomRoute(CurrentZone, 2);
end;

procedure TabShipAI.NoticeDamagingZone(Zone: PabZone);
begin
  if RandomIntRange(0, 10) = 0 then
    DamagingZone := Zone;
end;

procedure TabShipAI.ResetIntent;
begin
  Intent := 0;
  TargetShip := nil;
  TargetBonus := nil;
  BonusRouteZone := nil;
  AvoidanceZone := nil;
  DamagingZone := nil;
  LastDamageTick := 0;
  RetreatRequested := False;
end;

procedure TabShipAI.DecideActions;
var
  Index, Score, BestScore: Integer;
  Enemy: TabObject;
  Bonus: TabItem;
  Zone: PabZone;
  Obj: TabObject;
  NearestDistance: Double;
  Info, ZoneInfo: TSphericalBearingDistance;
begin
  DirectPathClear := False;
  IncomingThreat := False;
  if PlayerArcadeShip = Self then
  begin
    NearestDistance := 1E30;
    for Index := 0 to Enemies.Count - 1 do
    begin
      Enemy := TabObject(Enemies[Index]);
      Info := Enemy.BearingAndDistanceTo(Self);
      with Info do
      begin
        NearestDistance := Min(NearestDistance, Distance);
        if (Enemy <> TargetShip) and (Abs(BearingDeltaDegrees) < 5) and (Distance < 400) then
          IncomingThreat := True;
      end;
    end;
  end;
  ClearRoute;
  if TargetShip <> nil then
    SetRoute((TargetShip as TabShipAI).CurrentZone);
  FollowDirectDestination;
  if TargetPathClear then
  begin
    if ArcadeTickCount > ManeuverUntilTick then
      CombatManeuver := amUnselected;
    if (CombatManeuver = amApproach) and (ScoreApproach < 0) then
      CombatManeuver := amUnselected;
    if (CombatManeuver = amCloseEvasion) and (ScoreCloseEvasion < 0) then
      CombatManeuver := amUnselected;
    if (CombatManeuver = amFlank) and (ScoreFlanking < 0) then
      CombatManeuver := amUnselected;
    if (CombatManeuver = amReverseTurn) and (ScoreReverseTurn < 0) then
      CombatManeuver := amUnselected;
    if (CombatManeuver = amFollowReverse) and (ScoreReverseFollowing < 0) then
      CombatManeuver := amUnselected;
    if CombatManeuver < 0 then
    begin
      BestScore := 0;
      Score := ScoreApproach;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amApproach;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreCloseEvasion;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amCloseEvasion;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreFlanking;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amFlank;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreReverseTurn;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amReverseTurn;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreReverseFollowing;
      if Score > BestScore then
      begin
        CombatManeuver := amFollowReverse;
        ManeuverUntilTick := ArcadeTickCount + 500;
      end;
    end;
    if CombatManeuver = amApproach then
      ApproachTarget
    else if CombatManeuver = amCloseEvasion then
      EvadeCloseTarget
    else if CombatManeuver = amFlank then
      FlankTarget
    else if CombatManeuver = amReverseTurn then
      ReverseTowardTarget
    else if CombatManeuver = amFollowReverse then
      MatchReversingTarget;
  end
  else
  begin
    CombatManeuver := amUnselected;
    ManeuverUntilTick := 0;
    FollowRoute;
  end;
  if (AvoidanceZone = nil)
      and (ArcadeTickCount - LastDamageTick < 100)
      and ((RandomIntRange(0, 120) = 0)
          or ((BonusTicks[abkWeaponLock] > 0) and (RandomIntRange(0, 20) = 0))
          or ((TargetShip = nil) and (RandomIntRange(0, 20) = 0))
          or ((PlayerArcadeShip = Self)
              and (Health < MaxHealth * 0.3)
              and (RandomIntRange(0, 20) = 0))) then
    AvoidanceZone := ab_Zone_RandomRoute(CurrentZone, 2);
  if (AvoidanceZone <> nil)
      and ((AvoidanceZone = CurrentZone)
          or IncomingThreat
          or (RandomIntRange(0, 100) = 0)
          or (RecentHitCount >= 3)
          or not TryMoveToDestination(
              AvoidanceZone,
              AvoidanceZone.Longitude,
              AvoidanceZone.PolarAngle)) then
    AvoidanceZone := nil;
  if RetreatRequested and (RandomIntRange(0, 50) = 0) then
  begin
    repeat
      Zone := ab_Zone_RandomRoute(CurrentZone, RandomIntRange(3, 4));
    until Zone <> AvoidanceZone;
    AvoidanceZone := Zone;
  end;
  if (TargetBonus = nil)
      and not RetreatRequested
      and (((TargetShip = nil) and (RandomIntRange(0, 20) = 0))
          or ((BonusTicks[abkWeaponLock] > 0) and (RandomIntRange(0, 20) = 0))
          or ((PlayerArcadeShip <> Self) and (RandomIntRange(0, 500) = 0))
          or ((Health < MaxHealth * 0.4) and (RandomIntRange(0, 80) = 0))) then
  begin
    if PlayerArcadeShip = Self then
    begin
      TargetBonus := ab_Item_FindRepairRoute(CurrentZone, BonusRouteZone);
      if TargetBonus = nil then
        TargetBonus := ab_Item_FindBonusRoute(CurrentZone, BonusRouteZone);
    end
    else
    begin
      TargetBonus := ab_Item_FindBonusRoute(CurrentZone, BonusRouteZone);
      if TargetBonus <> nil then
      begin
        Obj := FirstArcadeObject;
        while Obj <> nil do
        begin
          if (Obj <> Self)
              and (Obj is TabShipAI)
              and (TabShipAI(Obj).TargetBonus = TargetBonus) then
          begin
            TargetBonus := nil;
            Break;
          end;
          Obj := Obj.Next;
        end;
      end;
    end;
  end;
  if (TargetBonus <> nil)
      and ((RecentHitCount >= 3)
          or (IncomingThreat and (RandomIntRange(0, 50) = 0))
          or not TryMoveToDestination(
              BonusRouteZone,
              TargetBonus.State.LongitudeDegrees,
              TargetBonus.State.PolarAngleDegrees)) then
    TargetBonus := nil;
  if RouteZone <> nil then
  begin
    Bonus := ab_Item_FindNearestBonus(RouteZone);
    if Bonus <> nil then
      with BearingAndDistanceTo(Bonus) do
        if Abs(BearingDeltaDegrees) < 75 then
        begin
          SetDirectDestination(Bonus.State.LongitudeDegrees, Bonus.State.PolarAngleDegrees);
          FollowDirectDestination;
        end;
  end;
  if (Enemies.Count <= 1) and (KellerArcadeShip <> nil) and (KellerArcadeShip.Health = 0) then
  begin
    SetDirectDestination(
        KellerArcadeShip.State.LongitudeDegrees,
        KellerArcadeShip.State.PolarAngleDegrees
    );
    FollowDirectDestination;
  end;
  if DamagingZone <> nil then
  begin
    ComputeSphericalBearingAndDistance(
        ZoneInfo.BearingDeltaDegrees,
        ZoneInfo.Distance,
        State.LongitudeDegrees,
        State.PolarAngleDegrees,
        State.BearingDegrees,
        DamagingZone.Longitude,
        DamagingZone.PolarAngle,
        SphereRadius
    );
    if Abs(ZoneInfo.BearingDeltaDegrees) < 90 then
      StopThrust
    else
      StartThrust;
    if ZoneInfo.Distance > (DamagingZone.Radius + ZoneRadius) * 1.4 then
      DamagingZone := nil
    else
      SetTurnInput(-ZoneInfo.BearingDeltaDegrees);
  end;
  AvoidImmediateObstacle;
  for Index := 0 to Enemies.Count - 1 do
  begin
    Enemy := TabObject(Enemies[Index]);
    Info := BearingAndDistanceTo(Enemy);
    with Info do
    begin
      if PrimaryWeapon >= 0 then
      begin
        if Weapons[PrimaryWeapon].Kind = 13 then
          FirePrimary
        else if Weapons[PrimaryWeapon].Kind = 14 then
          FirePrimaryAt(Enemy)
        else if Weapons[PrimaryWeapon].Kind = 12 then
          FirePrimaryAt(Enemy)
        else if Weapons[PrimaryWeapon].Kind = 17 then
          FirePrimary
        else if Abs(BearingDeltaDegrees) < 5 then
          if not (Weapons[PrimaryWeapon].Kind in [1, 2, 6, 8])
              or (Thrust <= 1.25)
              or (Abs(TurnInput) >= 0.01) then
            FirePrimaryAt(Enemy);
      end;
      if SecondaryWeapon >= 0 then
      begin
        if Weapons[SecondaryWeapon].Kind = 13 then
          FireSecondary
        else if Weapons[SecondaryWeapon].Kind = 14 then
          FireSecondaryAt(Enemy)
        else if Weapons[SecondaryWeapon].Kind = 12 then
          FireSecondaryAt(Enemy)
        else if Abs(BearingDeltaDegrees) < 5 then
          if not (Weapons[SecondaryWeapon].Kind in [1, 2, 6, 8])
              or (Thrust <= 1.25)
              or (Abs(TurnInput) >= 0.01) then
            FireSecondaryAt(Enemy);
      end;
    end;
  end;
end;

procedure TabShipAI.SetDirectDestination(Longitude, PolarAngle: Single);
var
  ForwardDistance, BackwardDistance: Double;
begin
  DirectTargetLongitude := Longitude;
  DirectTargetPolarAngle := PolarAngle;
  DirectPathClear := False;
  ComputeSphericalBearingAndDistance(
      DirectBearing.BearingDeltaDegrees,
      DirectBearing.Distance,
      State.LongitudeDegrees,
      State.PolarAngleDegrees,
      State.BearingDegrees,
      DirectTargetLongitude,
      DirectTargetPolarAngle,
      SphereRadius
  );
  ab_StopLine_GetDistances(
      MakeSphericalBearingState(
          State.LongitudeDegrees,
          State.PolarAngleDegrees,
          WrapHeadingDegrees(State.BearingDegrees + DirectBearing.BearingDeltaDegrees)
      ),
      ForwardDistance,
      BackwardDistance
  );
  DirectPathClear := DirectBearing.Distance < ForwardDistance;
end;

procedure TabShipAI.FollowDirectDestination;
begin
  if DirectPathClear then
  begin
    SetTurnInput(DirectBearing.BearingDeltaDegrees);
    if Abs(DirectBearing.BearingDeltaDegrees) < 45 then
      Thrust := RemapClamped(Abs(DirectBearing.BearingDeltaDegrees), 0, 45, 2.5, 0)
    else
      StopThrust;
  end;
end;

procedure TabShipAI.AvoidImmediateObstacle;
begin
  if (Thrust > 0)
      and ((ObstacleLevels[0] >= 3) or (ObstacleLevels[1] >= 3) or (ObstacleLevels[7] >= 3)) then
  begin
    if ObstacleLevels[1] < ObstacleLevels[7] then
      SetTurnInput(100)
    else if ObstacleLevels[7] < ObstacleLevels[1] then
      SetTurnInput(-100);
  end;
end;

procedure TabShipAI.ClearRoute;
begin
  RouteZone := nil;
  HeadingInsideRoute := False;
end;

procedure TabShipAI.SetRoute(Target: PabZone);
begin
  RouteZone := ab_Zone_GetRoute(CurrentZone, Target);
  HeadingInsideRoute := False;
  if RouteZone <> nil then
    HeadingInsideRoute :=
        ab_Zone_IsHeadingInside(State, RouteZone, RouteBearing, RouteAngularRadius);
end;

procedure TabShipAI.FollowRoute;
begin
  if RouteZone <> nil then
  begin
    if HeadingInsideRoute and (RouteZone <> nil) then
    begin
      StartThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then
        SetTurnInput(0)
      else if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if (RouteZone <> nil)
        and not ab_StopLine_IsBlocked(
            State.LongitudeDegrees,
            State.PolarAngleDegrees,
            RouteZone.Longitude,
            RouteZone.PolarAngle) then
    begin
      if RouteBearing < 45 then
        StartThrust
      else
        StopThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then
        SetTurnInput(0)
      else if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if not InsideCurrentZone then
    begin
      if HeadingInsideCurrentZone then
      begin
        StartThrust;
        if Abs(CurrentZoneBearing) < CurrentZoneAngularRadius / 2 then
          SetTurnInput(0)
        else if CurrentZoneBearing < 0 then
          SetTurnInput(-100)
        else if CurrentZoneBearing > 0 then
          SetTurnInput(100);
        Exit;
      end;
      if CurrentZoneBearing < 0 then
        SetTurnInput(-100)
      else if CurrentZoneBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if RouteZone <> nil then
    begin
      if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
    end;
  end;
end;

procedure TabShipAI.ApproachTarget;
begin
  CombatManeuver := amApproach;
  SetTurnInput(TargetBearing.BearingDeltaDegrees);
  if MinimumWeaponRange * 0.8 < TargetBearing.Distance then
  begin
    Thrust := RemapClamped(Abs(TargetBearing.BearingDeltaDegrees), 0, 180, 2.5, 0);
    Thrust := RemapClamped(TargetBearing.Distance, 100, 1000, 0.5, 1) * Thrust;
    Exit;
  end;
  StartReverseThrust;
end;

function TabShipAI.ScoreApproach: Integer;
begin
  Result := 1;
  Inc(Result, RandomRange(-1, 1));
end;

procedure TabShipAI.EvadeCloseTarget;
begin
  CombatManeuver := amCloseEvasion;
  if Abs(ReverseTargetBearing.BearingDeltaDegrees) < 20 then
    SetTurnInput(-TargetBearing.BearingDeltaDegrees)
  else
    SetTurnInput(TargetBearing.BearingDeltaDegrees);
  StartReverseThrust;
end;

function TabShipAI.ScoreCloseEvasion: Integer;
begin
  Result := 0;
  if (TargetBearing.Distance < 200) and (Abs(TargetBearing.BearingDeltaDegrees) < 40) then
  begin
    Inc(Result);
    Inc(Result);
  end
  else if Abs(TargetBearing.BearingDeltaDegrees) > 90 then
    Result := -1;
end;

procedure TabShipAI.FlankTarget;
begin
  CombatManeuver := amFlank;
  if TargetBearing.BearingDeltaDegrees > 0 then
    SetTurnInput(TargetBearing.BearingDeltaDegrees - 65)
  else
    SetTurnInput(TargetBearing.BearingDeltaDegrees + 65);
  StartThrust;
  Thrust := RemapClamped(TargetBearing.Distance, 100, 1000, 0.5, 1) * Thrust;
end;

function TabShipAI.ScoreFlanking: Integer;
begin
  Result := RandomRange(0, 2);
  if (Abs(ReverseTargetBearing.BearingDeltaDegrees) < 30) and (TargetBearing.Distance < 500) then
  begin
    Inc(Result);
    if Abs(TargetBearing.BearingDeltaDegrees) > Abs(ReverseTargetBearing.BearingDeltaDegrees) then
      Inc(Result);
    if (PlayerArcadeShip = Self) and (Health < Round(MaxHealth * 0.4)) then
      Inc(Result);
    if IncomingThreat then
      Inc(Result);
    Inc(Result, RandomRange(-1, 1));
  end;
  if TargetBearing.Distance > 500 then
    Dec(Result);
  if Health > MaxHealth * 0.7 then
    Dec(Result, 2);
end;

procedure TabShipAI.ReverseTowardTarget;
begin
  CombatManeuver := amReverseTurn;
  SetTurnInput(TargetBearing.BearingDeltaDegrees);
  StartReverseThrust;
end;

function TabShipAI.ScoreReverseTurn: Integer;
begin
  Result := 0;
  if (Abs(TargetBearing.BearingDeltaDegrees) > 120)
      and ((ObstacleLevels[3] = 0) or (ObstacleLevels[4] = 0) or (ObstacleLevels[5] = 0)) then
  begin
    Inc(Result, 3);
    if (PlayerArcadeShip = Self) and (Health < Round(MaxHealth * 0.4)) then
      Inc(Result);
    Inc(Result, RandomRange(-2, 2));
  end
  else
    Result := -1;
end;

procedure TabShipAI.MatchReversingTarget;
begin
  StartReverseThrust;
end;

function TabShipAI.ScoreReverseFollowing: Integer;
begin
  Result := 0;
  if (Abs(TargetBearing.BearingDeltaDegrees) < 20)
      and (Abs(ReverseTargetBearing.BearingDeltaDegrees) < 30)
      and (ObstacleLevels[4] <= 1)
      and (TargetShip.Thrust < 0) then
  begin
    Inc(Result, 2);
    if MaximumWeaponRange * 0.7 < TargetBearing.Distance then
      Inc(Result, 2);
    Inc(Result, RandomRange(-1, 1));
  end
  else
    Result := -1;
end;

function TabShipAI.TryMoveToDestination(Zone: PabZone; Longitude, PolarAngle: Double): Boolean;
var
  ForwardDistance, BackwardDistance, Distance, Bearing: Double;
begin
  SetAndFollowRoute(Zone);
  ComputeSphericalBearingAndDistance(
      Bearing,
      Distance,
      State.LongitudeDegrees,
      State.PolarAngleDegrees,
      State.BearingDegrees,
      Longitude,
      PolarAngle,
      SphereRadius
  );
  ab_StopLine_GetDistances(
      MakeSphericalBearingState(
          State.LongitudeDegrees,
          State.PolarAngleDegrees,
          WrapHeadingDegrees(State.BearingDegrees + Bearing)
      ),
      ForwardDistance,
      BackwardDistance
  );
  if Distance >= ForwardDistance then
    Result := RouteZone <> nil
  else
  begin
    SetTurnInput(Bearing);
    if Abs(Bearing) < 45 then
      Thrust := RemapClamped(Abs(Bearing), 0, 45, 2.5, 0)
    else
      StopThrust;
    Result := True;
  end;
end;

procedure TabShipAI.SetAndFollowRoute(Target: PabZone);
begin
  if Target = nil then
    RouteZone := nil
  else
    RouteZone := ab_Zone_GetRoute(CurrentZone, Target);
  HeadingInsideRoute := False;
  if RouteZone <> nil then
    HeadingInsideRoute :=
        ab_Zone_IsHeadingInside(State, RouteZone, RouteBearing, RouteAngularRadius);
  FollowDestinationRoute;
end;

procedure TabShipAI.FollowDestinationRoute;
begin
  if RouteZone <> nil then
  begin
    if HeadingInsideRoute and (RouteZone <> nil) then
    begin
      StartThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then
        SetTurnInput(0)
      else if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if (RouteZone <> nil)
        and not ab_StopLine_IsBlocked(
            State.LongitudeDegrees,
            State.PolarAngleDegrees,
            RouteZone.Longitude,
            RouteZone.PolarAngle) then
    begin
      if RouteBearing < 45 then
        StartThrust
      else
        StopThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then
        SetTurnInput(0)
      else if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if not InsideCurrentZone then
    begin
      if HeadingInsideCurrentZone then
      begin
        StartThrust;
        if Abs(CurrentZoneBearing) < CurrentZoneAngularRadius / 2 then
          SetTurnInput(0)
        else if CurrentZoneBearing < 0 then
          SetTurnInput(-100)
        else if CurrentZoneBearing > 0 then
          SetTurnInput(100);
        Exit;
      end;
      if CurrentZoneBearing < 0 then
        SetTurnInput(-100)
      else if CurrentZoneBearing > 0 then
        SetTurnInput(100);
      Exit;
    end;
    if RouteZone <> nil then
    begin
      if RouteBearing < 0 then
        SetTurnInput(-100)
      else if RouteBearing > 0 then
        SetTurnInput(100);
    end;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TArtefactTranclucator.ClassName;
  THole.ClassName;
  TTranclucator.ClassName;
  TabShip.ClassName;
  TabShipAI.ClassName;
end;
end.
