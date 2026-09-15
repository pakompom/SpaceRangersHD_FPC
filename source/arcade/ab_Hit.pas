{$EXCESSPRECISION OFF}
unit ab_Hit;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  GI_MessageLoop,
  ab_Object;
type
  TabHit = class;
  TabHit = class(TabObject)
    Health: Integer;
    MaxHealth: Integer;
    DisruptUntilTick: Integer;
    EffectOriginSpread: Integer;
    TurnSpeedScale: Double;
    Effects: TList;
    StateCC: Boolean;
    GapCD: array[0..2] of Byte;
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override;
    procedure UpdateState; override;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure ExplosionComplete(Sender: TObjectGI);
    procedure KellerBreakupComplete(Sender: TObjectGI);
    procedure KellerDeathComplete(Sender: TObjectGI);
    procedure HitEffectComplete(Sender: TObjectGI);
  end;
var
  KellerFragments: array[0..3] of TabHit;
  KellerFragmentDistances: array[0..3] of Double;
  KellerFragmentValuesAC: array[0..3] of Double;
  KellerBreakupTicks: Integer;
  KellerSplitActive: Boolean;
  KellerFinishRequested: Boolean;
  KellerDeathPending: Boolean;
procedure LinkRecoveredTypes;
implementation
uses
  aCalc,
  Types,
  aKling,
  Math,
  SysUtils,
  Globals,
  GR_Main,
  aConst,
  abWall,
  aMyFunction,
  ab_MainForm,
  EC_Struct,
  GI_Tail,
  ab_Global,
  GI_GAI,
  GlobalsV,
  ab_Ship,
  ab_ShipAI,
  SE_Ruins,
  aGalaxy,
  aPlayer;

constructor TabHit.Create;
begin
  inherited Create;
  DisruptUntilTick := 0;
  Health := 200;
  MaxHealth := 200;
  Effects := TList.Create;
  StateCC := True;
end;

destructor TabHit.Destroy;
var
  Index: Integer;
  Effect: TObject;
begin
  if Effects <> nil then
  begin
    for Index := 0 to Effects.Count - 1 do
    begin
      Effect := Effects[Index];
      Effect.Free;
    end;
    Effects.Free;
    Effects := nil;
  end;
  inherited Destroy;
end;

procedure TabHit.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
var
  Frame: Integer;
  Effect: TObjectGI;
  Invulnerable: Boolean;
  Animation: TgaiGI;
begin
  if Health > 0 then
  begin
    Invulnerable := (Galaxy <> nil) and (Galaxy.GodModEnabled = 1) and (PlayerArcadeShip = Self);
    if (Self <> KellerFragments[0])
        and (Self <> KellerFragments[1])
        and (Self <> KellerFragments[2])
        and (Self <> KellerFragments[3]) then
      if Source <> nil then
        if (Self is TabShip) and (Source is TabShip) then
          if (Source as TabShip).Enemies.IndexOf(Self) < 0 then
            Amount := Amount div 4;
    if (PlayerArcadeShip = Self) and (GetPlayer <> nil) then
    begin
      if ArcadeAutopilotEnabled then
        Amount := Round(Amount * 0.7);
      if KellerArcadeShip <> nil then
        Amount :=
            Round(
                RemapClamped(
                        GetPlayer.BlackHoleKillCount + GetPlayer.HyperspaceKillCount,
                        5,
                        70,
                        0.1,
                        1)
                    * Amount
            );
      Amount :=
          Round(Amount * GalaxyDifficultyTuning[Galaxy.DifficultyLevels[6]].ArcadeDamageTakenScale);
    end;
    if (KellerArcadeShip = Self)
        and ((PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0)) then
      Amount := 0;
    if Disrupt then
    begin
      if ArcadeTickCount < DisruptUntilTick then
      begin
        Inc(DisruptUntilTick, Amount);
        if (PlayerArcadeShip = Self) and (DisruptUntilTick - ArcadeTickCount > 350) then
          DisruptUntilTick := ArcadeTickCount + 350;
      end
      else
        DisruptUntilTick := ArcadeTickCount + Amount;
      if not Invulnerable then
        Health := Max(0, Health - 2);
    end
    else if not Invulnerable then
      Health := Max(0, Health - Amount);
    if (KellerAuxiliaryShip <> nil) and (KellerArcadeShip = Self) and (Health <= 0) then
      Health := 100;
    if (KellerArcadeShip = Self) and (Health = 0) then
    begin
      Animation := ((Self as TabShip).Visual as TRuinsSE).Animation;
      Frame := Animation.SequenceFrame;
      Animation.LoadFrameSequenceFromText(
          '[20,0-'
              + IntToStr(Animation.GetMainImageFrameCount - 1)
              + '][20,0-'
              + IntToStr(Animation.GetMainImageFrameCount - 1)
              + ']'
      );
      Animation.SetSequenceFrame(Frame);
      Animation.CycleCompleteCallback := KellerBreakupComplete;
      StateCC := False;
    end;
    if (Health > 0) or (KellerArcadeShip <> Self) then
    begin
      if Health <= 0 then
      begin
        if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
        begin
          Effect := TgaiGI.Create(ArcadeBattleScreen.WorldPanel);
          Effects.Add(Effect);
          if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
          begin
            if (KellerArcadeShip = Self) or (KellerAuxiliaryShip = Self) then
              TgaiGI(Effect).SetImagePath('Bm.Weapon.ExplM')
            else
              TgaiGI(Effect).SetImagePath('Bm.Weapon.Expl' + IntToStr(RandomIntRange(0, 1)));
            Effect.SetDepth(ExplosionFrontDepth);
          end
          else
          begin
            TgaiGI(Effect).SetImagePath('Bm.AB.expl0_s');
            Effect.SetDepth(ExplosionBackDepth);
          end;
          TgaiGI(Effect).SequenceIndex := 0;
          Effect.UpdateAutoGeometry;
          Effect.SetSize(TgaiGI(Effect).GetContentSize);
          Effect.SetOrigin(HalfPoint(Effect.ClientSize));
          TgaiGI(Effect).CycleCompleteCallback := ExplosionComplete;
          TgaiGI(Effect).RestartPlayback;
          Effect.SetActive(True);
          if Self is TabWall then
          begin
            if RandomIntRange(0, 1) = 0 then
              SoundManager.PlaySound('Sound.ab_Expl0')
            else
              SoundManager.PlaySound('Sound.ab_Expl1');
          end
          else
            SoundManager
                .PlaySound(ArcadeExplosionSounds[RandomIntRange(0, High(ArcadeExplosionSounds))]);
        end
        else
          DeletionPending := True;
      end
      else
      begin
        if ((Source <> nil) and (Effects.Count < 5)) or (Effects.Count < 1) then
        begin
          Effect := TgaiGI.Create(ArcadeBattleScreen.WorldPanel);
          Effects.Add(Effect);
          if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
          begin
            TgaiGI(Effect).SetImagePath('Bm.AB.hit00_f');
            Effect.SetDepth(HitFrontDepth);
          end
          else
          begin
            TgaiGI(Effect).SetImagePath('Bm.AB.hit00_s');
            Effect.SetDepth(HitBackDepth);
          end;
          TgaiGI(Effect).SequenceIndex := 0;
          Effect.UpdateAutoGeometry;
          Effect.SetSize(TgaiGI(Effect).GetContentSize);
          Effect.SetOrigin(
              Classes.Point(
                  Effect.ClientSize.X div 2
                      + RandomIntRange(-EffectOriginSpread div 4, EffectOriginSpread div 4),
                  Effect.ClientSize.Y div 2
                      + RandomIntRange(-EffectOriginSpread div 4, EffectOriginSpread div 4)
              )
          );
          TgaiGI(Effect).CycleCompleteCallback := HitEffectComplete;
          TgaiGI(Effect).RestartPlayback;
          Effect.SetActive(True);
          if PlayerArcadeShip = Self then
            SoundManager.PlaySound(ArcadeHitSounds[RandomIntRange(0, High(ArcadeHitSounds))]);
        end;
      end;
    end;
  end;
end;

procedure TabHit.UpdateState;
begin
  if ArcadeTickCount < DisruptUntilTick then
  begin
    if PlayerArcadeShip = Self then
    begin
      SpeedScale := 0.7;
      TurnSpeedScale := 0.6;
    end
    else
    begin
      SpeedScale := 0.5;
      TurnSpeedScale := 0.4;
    end;
  end
  else
  begin
    SpeedScale := 1;
    TurnSpeedScale := 1;
  end;
  inherited UpdateState;
end;

procedure TabHit.Advance;
var
  Index: Integer;
  ArcDistance: Double;
  OutwardAnimation, InwardAnimation, DeathAnimation: TgaiGI;
  Ship: TabShipAI;
  Source: TSphericalBearingState;
  Bearing: TSphericalBearingDistance;
begin
  inherited Advance;
  if Health = 0 then
  begin
    Velocity := MakePointF(0, 0);
    Thrust := 0;
  end;
  if (KellerArcadeShip = Self) and (KellerFragments[0] <> nil) then
  begin
    Inc(KellerBreakupTicks);
    if (KellerBreakupTicks > 150)
        and (GetPlayer <> nil)
        and (KellerShip <> nil)
        and (PlayerArcadeShip <> nil)
        and (PlayerArcadeShip.Health > 0)
        and KellerFinishRequested then
    begin
      for Index := 0 to 3 do
      begin
        KellerFragments[Index].ApplyDamage(KellerFragments[Index].Health, Self, False);
        KellerFragments[Index] := nil;
      end;
      DeletionPending := True;
      aCalc.WaitForTurnCalculationUI;
      Inc(GetPlayer.DominatorKillsByType[0]);
      KellerShip.ScriptItemsAct(61, nil, nil, 0);
      KellerShip.Free;
      aCalc.WaitForTurnCalculationUI;
    end
    else
    begin
      for Index := 0 to 3 do
      begin
        Source := State;
        Source.BearingDegrees := 0;
        Bearing := GetSphericalBearingAndDistance(Source, KellerFragments[Index].State);
        if KellerBreakupTicks < 150 then
        begin
          KellerFragmentDistances[Index] := Max(KellerFragmentDistances[Index], Bearing.Distance);
          OutwardAnimation := (TabShip(KellerFragments[Index]).Visual as TRuinsSE).Animation;
          OutwardAnimation.SetSequenceFrame(
              Round((OutwardAnimation.SequenceFrameCount div 2) * (KellerBreakupTicks / 150))
          );
        end
        else
        begin
          InwardAnimation := (TabShip(KellerFragments[Index]).Visual as TRuinsSE).Animation;
          InwardAnimation.SetSequenceFrame(
              Min(
                  InwardAnimation.SequenceFrameCount - 1,
                  Round((InwardAnimation.SequenceFrameCount div 2) * (KellerBreakupTicks / 150))
              )
          );
          KellerFragments[Index].Velocity.X := 0;
          KellerFragments[Index].Velocity.Y := 0;
          KellerFragments[Index].State := State;
          KellerFragments[Index].State.BearingDegrees :=
              WrapHeadingDegrees(Bearing.BearingDeltaDegrees);
          ArcDistance := (1 - (KellerBreakupTicks - 150) / 150) * KellerFragmentDistances[Index];
          AdvanceSphericalBearingState(
              KellerFragments[Index].State.LongitudeDegrees,
              KellerFragments[Index].State.PolarAngleDegrees,
              KellerFragments[Index].State.BearingDegrees,
              SphereRadius,
              ArcDistance
          );
          if KellerBreakupTicks >= 300 then
          begin
            KellerFragments[Index].DeletionPending := True;
            KellerFragments[Index] := nil;
          end;
        end;
      end;
      if KellerFragments[0] = nil then
      begin
        KellerSplitActive := False;
        StateCC := True;
        Health := MaxHealth;
        (Self as TabShip).AttachVisual;
        if KellerDeathPending then
        begin
          DeathAnimation := (KellerArcadeShip.Visual as TRuinsSE).Animation;
          DeathAnimation.SetImagePath('Bm.Ruins.Keller_Out');
          DeathAnimation.SequenceIndex := 0;
          DeathAnimation.UpdateAutoGeometry;
          DeathAnimation.SetSize(DeathAnimation.GetContentSize);
          DeathAnimation.SetOrigin(HalfPoint(DeathAnimation.ClientSize));
          DeathAnimation.CycleCompleteCallback := KellerDeathComplete;
          Ship := KellerArcadeShip as TabShipAI;
          Ship.WallCollisionEnabled := False;
          Ship.GravityEnabled := False;
          Ship.ZoneDamageEnabled := False;
          Ship.Collidable := False;
          Ship.Active := False;
          Ship.StateCC := False;
          Ship.Velocity.X := 0;
          Ship.Velocity.Y := 0;
          Ship.MaxSpeed := 0;
          Ship.Thrust := 0;
          Ship.AIEnabled := False;
        end;
      end;
    end;
  end;
end;

procedure TabHit.UpdateVisuals;
var
  Effect: TObjectGI;
  Index: Integer;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  Position := GetWorldPosition;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
  for Index := 0 to Effects.Count - 1 do
  begin
    Effect := Effects[Index];
    Effect.SetPosition(Classes.Point(Round(Position.X), Round(Position.Y)));
  end;
end;

procedure TabHit.ExplosionComplete(Sender: TObjectGI);
begin
  Effects.Delete(Effects.IndexOf(Sender));
  Sender.Free;
  if Effects.Count <= 0 then
    if Health <= 0 then
      DeletionPending := True;
end;

procedure TabHit.KellerBreakupComplete(Sender: TObjectGI);
var
  Index: Integer;
  Ship: TabShip;
  Angle, SourceLongitude, SourcePolarAngle, TargetLongitude, TargetPolarAngle, Bearing, Distance:
      Double;
  TargetPoint, SourcePoint: TPoint;
  Animation, FragmentAnimation: TgaiGI;
begin
  for Index := 0 to 3 do
  begin
    KellerFragments[Index] := nil;
    KellerFragmentDistances[Index] := 0;
    KellerFragmentValuesAC[Index] := 0;
  end;
  KellerBreakupTicks := 0;
  KellerFinishRequested := False;
  SourcePoint :=
      ArcadeBattleScreen.WorldPanel.ToAbsolutePoint(
          ((Self as TabShip).Visual as TRuinsSE).Animation.LocalPosition
      );
  if not ArcadeBattleScreen.ScreenPointToSphere(SourcePoint, SourceLongitude, SourcePolarAngle) then
  begin
    SourceLongitude := -1e20;
    SourcePolarAngle := -1e20;
  end;
  Animation := ((Self as TabShip).Visual as TRuinsSE).Animation;
  Animation.CycleCompleteCallback := nil;
  (Self as TabShip).DetachVisual;
  for Index := 0 to 3 do
  begin
    Ship := TabShip.Create;
    ab_Object_Add(Ship);
    Ship.CreateRuinsVisual('Ruins.Keller_P' + IntToStr(Index + 1), 128);
    Ship.MaxSpeed := 8;
    Ship.TurnSpeed := 1.8;
    Ship.Thrust := 0;
    Ship.Health := 1000000000;
    Ship.MaxHealth := 1000000000;
    Ship.WeaponCount := 0;
    Ship.PrimaryWeapon := 0;
    Ship.State := State;
    Ship.State.BearingDegrees := RandomIntRange(0, 359);
    Ship.CollisionRadius := 0;
    Ship.WallCollisionEnabled := False;
    Ship.GravityEnabled := False;
    Ship.ZoneDamageEnabled := False;
    Ship.Collidable := False;
    Ship.Active := False;
    Ship.StateCC := False;
    Ship.MaxSpeed := 10; // Native overwrites the earlier value.
    KellerFragments[Index] := Ship;
    if Index = 0 then
      Angle := HeadingDegreesToRadians(0)
    else if Index = 1 then
      Angle := HeadingDegreesToRadians(240)
    else if Index = 2 then
      Angle := HeadingDegreesToRadians(120)
    else
      Angle := HeadingDegreesToRadians(270);
    Ship.Velocity.X := Sin(Angle) * 10;
    Ship.Velocity.Y := Cos(Angle) * -10;
    if SourceLongitude > -1e10 then
    begin
      TargetPoint.X := SourcePoint.X + Round(Sin(Angle) * 100);
      TargetPoint.Y := SourcePoint.Y - Round(Cos(Angle) * 100);
      if ArcadeBattleScreen.ScreenPointToSphere(TargetPoint, TargetLongitude, TargetPolarAngle) then
      begin
        ComputeSphericalBearingAndDistance(
            Bearing,
            Distance,
            SourceLongitude,
            SourcePolarAngle,
            0,
            TargetLongitude,
            TargetPolarAngle,
            SphereRadius
        );
        Bearing := HeadingDegreesToRadians(WrapHeadingDegrees(Bearing));
        Ship.Velocity.X := Sin(Bearing) * 10;
        Ship.Velocity.Y := -Cos(Bearing) * 10;
        Ship.State.BearingDegrees := Bearing; // Native stores the converted radians here.
      end;
    end;
    Ship.AttachVisual;
    Ship.UpdateState;
    Ship.Advance;
    Ship.UpdateVisuals;
    FragmentAnimation := (Ship.Visual as TRuinsSE).Animation;
    FragmentAnimation.StopAutoPlayback;
  end;
end;

procedure TabHit.KellerDeathComplete(Sender: TObjectGI);
begin
  DeletionPending := True;
  (Self as TabShip).DetachVisual;
end;

procedure TabHit.HitEffectComplete(Sender: TObjectGI);
begin
  Effects.Delete(Effects.IndexOf(Sender));
  Sender.Free;
end;

procedure LinkRecoveredTypes;
begin
  TRuinsSE.ClassName;
  TabShip.ClassName;
  TabShipAI.ClassName;
  TabWall.ClassName;
end;
end.
