{$EXCESSPRECISION OFF}
unit SE_Weapon;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  GI_Label,
  GI_MessageLoop,
  GI_PSWeapon,
  SE_Space,
  Types;
type
  TWeaponEffect = class;
  TWeaponSE = class;
  PointerToTWeaponEffectItem = ^TWeaponEffectItem;
  PWeaponEffectItem = PointerToTWeaponEffectItem;
  TWeaponEffectItem = record
    Next: PWeaponEffectItem;
    Prev: PWeaponEffectItem;
    Image: TgaiGI;
    Position: TPointF;
    Angle: Single;
    Lifetime: Integer;
    Speed: Single;
    Acceleration: Single;
    AtTarget: Boolean;
    AutoAnimation: Boolean;
    LoopAnimation: Boolean;
    Gap27: array[0..0] of Byte;
    SkipTime: Integer;
  end;
  TWeaponEffect = class(TObject)
    Owner: TObjectGI;
    FirstItem: PWeaponEffectItem;
    LastItem: PWeaponEffectItem;
    EffectIndex: Integer;
    DepthExpression: WideString;
    SourcePoint: TPointF;
    TargetPoint: TPointF;
    Started: Boolean;
    Gap29: array[0..2] of Byte;
    LeftTime: Integer;
    Direction: Single;
    AnimationInterval: Integer;
    AnimationCountdown: Integer;
    BeforeEnd: Boolean;
    Gap3D: array[0..2] of Byte;
    constructor Create(AEffectIndex: Integer; AOwner: TObjectGI);
    destructor Destroy; override;
    procedure Clear;
    function AddItem: PWeaponEffectItem;
    procedure RemoveItem(Item: PWeaponEffectItem);
    procedure AddTargetEffect(Index: Integer);
    procedure AddSourceEffect(Index: Integer);
    procedure Start;
    procedure Advance;
    procedure AnimationComplete(Sender: TObjectGI);
    function IsFinished: Boolean;
    procedure SetSourcePoint(Point: TPointF);
    procedure SetTargetPoint(Point: TPointF);
  end;
  TWeaponSE = class(TObjectSE)
    ShotSoundPath: WideString;
    HitSoundPath: WideString;
    PlayShotSound: Boolean;
    Gap55: array[0..2] of Byte;
    SourceObject: TObjectSE;
    TargetObject: TObjectSE;
    HitDamage: Integer;
    TargetDestroyed: Boolean;
    Gap65: array[0..2] of Byte;
    DestructionEffect: Integer;
    DestructionFrameInterval: Integer;
    DestructionDetachStep: Integer;
    HitColor: Integer;
    SourceAnimation: TgaiGI;
    SourceAnimationInterval: Integer;
    TargetAnimation: TgaiGI;
    TargetAnimationInterval: Integer;
    HitEffect: TWeaponEffect;
    HitVariant: Integer;
    Projectile: TPSWeaponGI;
    DestructionAnimation: TgaiGI;
    ExtraDestructionAnimations: array[0..5] of TgaiGI;
    DamageLabel: TLabelGI;
    ImmediateDestruction: Boolean;
    GapB5: array[0..2] of Byte;
    DestructionAlpha: Single;
    DestructionAlphaStep: Single;
    DamageLabelPoint: TPointF;
    GapC8: array[0..0] of Byte;
    ProjectileFinished: Boolean;
    GapCA: array[0..1] of Byte;
    StepIndex: Integer;
    ShotVisual: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure Advance; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    constructor Create(
        const GraphKey: WideString;
        UnusedPosition: TPoint;
        ShotVisual: Integer;
        Variant: Integer
    );
    destructor Destroy; override;
    procedure SetHit(Color: Integer; Damage: Integer; Destroyed: Boolean; PlaySound: Boolean);
    procedure SetEndpoints(Source: TObjectSE; Target: TObjectSE);
    function GetTargetPoint: TPointF;
    function GetSourcePoint: TPointF;
  end;
procedure InitializeWeaponVisualResources;
procedure LinkRecoveredTypes;
implementation
uses
  ObserverHooks,
  Classes,
  Math,
  SysUtils,
  EC_Str,
  aMyFunction,
  GI_Main,
  GR_Main,
  Globals,
  GlobalsV,
  GR_Sound,
  SE_Ship2,
  SE_Ruins,
  GI_PSWeapon01Laser,
  GI_PSWeapon02FragCannon,
  GI_PSWeapon03Lezka,
  GI_PSWeapon05Treton,
  GI_PSWeapon06Phaser,
  GI_PSWeapon07Blaster,
  GI_PSWeapon08ECutter,
  GI_PSWeapon09MResonator,
  GI_PSWeapon10AVision,
  GI_PSWeapon11Desintegrator,
  GI_PSWeapon12Turbogravir,
  GI_PSWeapon13IMHO,
  GI_PSWeapon14Vertix,
  GI_PSWeapon16Esodafer,
  GI_PSWeapon17Kafacitor,
  GI_PSMissileHit,
  GI_RadialEffect,
  GI_PDTurretWeapon,
  GI_PSEyes;

constructor TWeaponSE.Create(
    const GraphKey: WideString;
    UnusedPosition: TPoint;
    ShotVisual, Variant: Integer
);
begin
  Self.ShotVisual := ShotVisual;
  HitVariant := Variant;
  inherited Create(GraphKey, UnusedPosition);
  if Variant >= 0 then
    Self.GraphKey := Self.GraphKey + ',' + IntToStr(ShotVisual) + ',' + IntToStr(Variant)
  else if ShotVisual > 0 then
    Self.GraphKey := Self.GraphKey + ',' + IntToStr(ShotVisual);
end;

destructor TWeaponSE.Destroy;
begin
  if SourceObject <> nil then
    ReleaseSpaceObject(SourceObject);
  if TargetObject <> nil then
    ReleaseSpaceObject(TargetObject);
  inherited Destroy;
end;

procedure TWeaponSE.AttachToSpace(ASpace: TSpaceSE);
var
  Distance, Angle: Single;
  I: Integer;
  WeaponConfig, VisualConfig: TBlockParEC;
  HasDestruction, UseRandomHit: Boolean;
  Key: WideString;
begin
  inherited AttachToSpace(ASpace);
  HasDestruction := False;
  ImmediateDestruction := False;
  ProjectileFinished := False;
  WeaponConfig := GameDataConfig.GetBlock('Weapon');
  Key := ExtractDelimitedPartW(GraphKey, 0, ',');
  I := ExtractDigitsToIntW(Key);
  if ((ShotVisual = 0) and (CountDelimitedPartsW(GraphKey, ',') > 1)) or (I in [3, 14, 17]) then
  begin
    if CountDelimitedPartsW(GraphKey, ',') > 1 then
      ShotVisual := StrToInt(ExtractDelimitedPartW(GraphKey, 1, ','));
    VisualConfig := nil;
    if I in [3, 14, 17] then
      VisualConfig := GameDataConfig.FindBlockByPath('SE.Weapon.Eyes');
    if VisualConfig = nil then
      VisualConfig := GameDataConfig.GetBlockByPath('SE.' + Key);
    LoadTemplate(VisualConfig);
  end;
  UseRandomHit := True;
  if Key = 'Weapon.Star' then
  begin
    // Native allocates this child and then clears the retained projectile reference.
    Projectile := TPSBlueWhirlGI.Create(Space.MapPanel);
    Projectile := nil;
    UseRandomHit := False;
  end
  else if Key = 'Weapon.NoGraph' then
  begin
    Projectile := nil;
    UseRandomHit := False;
  end
  else if Key = 'Weapon.Kamikaze' then
  begin
    Projectile := nil;
    UseRandomHit := False;
  end
  else if Key = 'Weapon.Asteroid' then
  begin
    Projectile := nil;
    UseRandomHit := False;
    SourceAnimation := TgaiGI.Create(Space.MapPanel);
    SourceAnimation.SetImagePath('Bm.Asteroid.Des');
    SourceAnimation.SetSize(SourceAnimation.GetContentSize);
    SourceAnimation.SetOrigin(HalfPoint(SourceAnimation.ClientSize));
    SourceAnimation.SetDepthByName('Weapon');
    SourceAnimation.SetPositionModeW(True);
    SourceAnimation.LoadFrameSequenceFromText(
        '[50,0-' + IntToStr(SourceAnimation.GetMainImageFrameCount - 1) + ']'
    );
    SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
    SourceAnimation.StopAutoPlayback;
    SourceAnimationInterval := 3;
    ImmediateDestruction := True;
    HasDestruction := True;
  end
  else if Key = 'Weapon.MissileHit' then
  begin
    Projectile := nil;
    UseRandomHit := False;
    SourceAnimation := TgaiGI.Create(Space.MapPanel);
    SourceAnimation.SetImagePath(MissileHitAnimationPaths[ShotVisual][0]);
    SourceAnimation.SetSize(SourceAnimation.GetContentSize);
    SourceAnimation.SetOrigin(HalfPoint(SourceAnimation.ClientSize));
    SourceAnimation.SetDepthByName('Weapon');
    SourceAnimation.SetPositionModeW(True);
    SourceAnimation.LoadFrameSequenceFromText(
        '[50,0-' + IntToStr(SourceAnimation.GetMainImageFrameCount - 1) + ']'
    );
    SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
    SourceAnimation.StopAutoPlayback;
    SourceAnimationInterval := 3;
    ImmediateDestruction := True;
    HasDestruction := True;
  end
  else if Key = 'Weapon.Shock' then
  begin
    Projectile := nil;
    UseRandomHit := False;
    TargetAnimation := TgaiGI.Create(Space.MapPanel);
    TargetAnimation.SetImagePath('Bm.Weapon.W17');
    TargetAnimation.SetSize(TargetAnimation.GetContentSize);
    TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
    TargetAnimation.SetDepthByName('Weapon');
    TargetAnimation.SetPositionModeW(True);
    TargetAnimation.LoadFrameSequenceFromText(
        '[40,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']'
    );
    TargetAnimation.StopAutoPlayback;
    TargetAnimationInterval := 2;
  end
  else if Key = 'Weapon.Nine' then
    Projectile := TPSWeapon09BranchGI.Create(Space.MapPanel, ShotVisual)
  else if Key = 'Weapon.PDTurret' then
    Projectile := TPSPDWeaponGI.Create(Space.MapPanel)
  else if Key = 'Weapon.RadialEffect' then
  begin
    Projectile := TPSRadEffectGI.Create(Space.MapPanel, ShotVisual);
    UseRandomHit := False;
  end
  else if Key = 'Weapon.AuraEffect' then
  begin
    Projectile := nil;
    UseRandomHit := False;
    TargetAnimation := TgaiGI.Create(Space.MapPanel);
    TargetAnimation.SetImagePath(AuraAnimationPaths[ShotVisual]);
    TargetAnimation.SetSize(TargetAnimation.GetContentSize);
    TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
    TargetAnimation.SetDepthByName('Weapon');
    TargetAnimation.SetPositionModeW(True);
    TargetAnimation.LoadFrameSequenceFromText(
        '[40,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']'
    );
    TargetAnimation.StopAutoPlayback;
    TargetAnimationInterval := 2;
  end
  else if I = 0 then
    Projectile := TPSWeapon01Laser.Create(Space.MapPanel, ShotVisual)
  else if I = 1 then
    Projectile := TPSWeapon02FragCannon.Create(Space.MapPanel, ShotVisual)
  else if I = 2 then
    Projectile := TPSWeapon03Lezka.Create(Space.MapPanel, ShotVisual)
  else if I = 4 then
    Projectile := TPSWeapon05Treton.Create(Space.MapPanel, ShotVisual)
  else if I = 5 then
    Projectile := TPSWeapon06Phaser.Create(Space.MapPanel, ShotVisual)
  else if I = 6 then
    Projectile := TPSWeapon07Blaster.Create(Space.MapPanel, ShotVisual)
  else if I = 7 then
    Projectile := TPSWeapon08ECutter.Create(Space.MapPanel, ShotVisual)
  else if I = 8 then
  begin
    Projectile := TPSWeapon09MResonator.Create(Space.MapPanel, ShotVisual);
    UseRandomHit := False;
  end
  else if I = 9 then
  begin
    Projectile := TPSWeapon10AVision.Create(Space.MapPanel, ShotVisual);
    UseRandomHit := False;
    TargetAnimation := TgaiGI.Create(Space.MapPanel);
    TargetAnimation.SetImagePath(AVisionAnimationPaths[ShotVisual][0]);
    TargetAnimation.SetSize(TargetAnimation.GetContentSize);
    TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
    TargetAnimation.SetDepthByName('Weapon');
    TargetAnimation.SetPositionModeW(True);
    TargetAnimation.LoadFrameSequenceFromText(
        '[50,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']'
    );
    TargetAnimation.StopAutoPlayback;
    TargetAnimationInterval := 2;
  end
  else if I = 10 then
    Projectile := TPSWeapon11Desintegrator.Create(Space.MapPanel, ShotVisual)
  else if I = 11 then
    Projectile := TPSWeapon12Turbogravir.Create(Space.MapPanel, ShotVisual)
  else if I = 12 then
    Projectile := TPSWeapon13IMHO.Create(Space.MapPanel, ShotVisual)
  else if I = 13 then
  begin
    Projectile := nil;
    UseRandomHit := False;
    SourceAnimation := TgaiGI.Create(Space.MapPanel);
    SourceAnimation.SetImagePath(Weapon14AnimationPaths[ShotVisual][0]);
    SourceAnimation.SetSize(SourceAnimation.GetContentSize);
    SourceAnimation.SetOrigin(HalfPoint(SourceAnimation.ClientSize));
    SourceAnimation.SetDepthByName('Weapon');
    SourceAnimation.SetPositionModeW(True);
    SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
    SourceAnimation.SequenceIndex := 0;
    SourceAnimation.UpdateAutoGeometry;
    SourceAnimation.StopAutoPlayback;
    SourceAnimationInterval := 1;
  end
  else if I = 15 then
    Projectile := TPSWeapon16Esodafer.Create(Space.MapPanel, ShotVisual)
  else if I = 16 then
  begin
    Projectile := TPSWeapon17Kafacitor.Create(Space.MapPanel, ShotVisual);
    TargetAnimation := TgaiGI.Create(Space.MapPanel);
    TargetAnimation.SetImagePath(KafacitorAnimationPaths[ShotVisual][0]);
    TargetAnimation.SetSize(TargetAnimation.GetContentSize);
    TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
    TargetAnimation.SetDepthByName('Weapon');
    TargetAnimation.SetPositionModeW(True);
    TargetAnimation.LoadFrameSequenceFromText(
        '[40,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']'
    );
    TargetAnimation.StopAutoPlayback;
    TargetAnimationInterval := 2;
  end
  else
    Projectile := TPSEyesGI.Create(Space.MapPanel, ShotVisual);
  if HitVariant < 0 then
  begin
    if CountDelimitedPartsW(GraphKey, ',') > 2 then
      HitVariant := StrToInt(ExtractDelimitedPartW(GraphKey, 2, ','))
    else if UseRandomHit then
      HitVariant := PresentationRandom(ExtractDigitsToIntW(WeaponConfig.GetParam('HitCount'))) + 1;
  end;
  if HitVariant > 0 then
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  if DepthExpression <> '' then
  begin
    if TargetAnimation <> nil then
      TargetAnimation.SetDepthByName(DepthExpression);
    if SourceAnimation <> nil then
      SourceAnimation.SetDepthByName(DepthExpression);
  end;
  if Projectile <> nil then
  begin
    if DepthExpression <> '' then
      Projectile.SetDepthByName(DepthExpression)
    else
      Projectile.SetDepthByName('Weapon');
    Projectile.SetPosition(TruncatePointF(GetSourcePoint));
    Projectile.SetTargetPoint(TruncatePointF(GetTargetPoint));
    Projectile.SetPositionModeW(True);
  end;
  DamageLabelPoint := GetTargetPoint;
  DamageLabelPoint.X := DamageLabelPoint.X - 30.0;
  DamageLabelPoint.Y := DamageLabelPoint.Y - 30.0;
  if HitColor <> 0 then
  begin
    DamageLabel := TLabelGI.Create(Space.MapPanel);
    DamageLabel.SetFontName(NormalFontName);
    DamageLabel.SetDepthByName('HitPoint');
    DamageLabel.SetPosition(TruncatePointF(DamageLabelPoint));
    if HitDamage >= 0 then
      DamageLabel.SetText(IntToStr(HitDamage))
    else
      DamageLabel.SetText('+' + IntToStr(-HitDamage));
    DamageLabel.SetWordWrapEnabled(False);
    DamageLabel.SetTextAlignX(taxAuto);
    DamageLabel.SetTextAlignY(tayAuto);
    DamageLabel.SetPositionModeW(True);
    DamageLabel.SetMouseViewUpdates(True);
    DamageLabel.SetTextColor(HitColor);
  end;
  if TargetDestroyed then
  begin
    if DestructionEffect = 0 then
      if (TargetObject is TRuinsSE)
          or (TargetObject.Size.X > 128)
          or (TargetObject.Size.Y > 128) then
        DestructionEffect := 4;
    if DestructionEffect = 7 then
    begin
      if TargetObject <> nil then
        TargetObject.DetachFromSpace;
    end
    else if DestructionEffect = 6 then
    begin
      DestructionDetachStep := 10;
      if TargetObject <> nil then
      begin
        DestructionAlpha := TargetObject.GetAlpha;
        DestructionAlphaStep := (0.0 - DestructionAlpha) / 11.0;
      end
      else
      begin
        DestructionAlpha := 255;
        DestructionAlphaStep := 0;
      end;
    end
    else if DestructionEffect = 0 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Weapon.Expl' + IntToStr(RandomIntRange(0, 1)));
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText(
          '[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']'
      );
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 2;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
      if TargetObject <> nil then
      begin
        DestructionAlpha := TargetObject.GetAlpha;
        DestructionAlphaStep :=
            (0.0 - DestructionAlpha) / (DestructionAnimation.GetMainImageFrameCount div 2 - 1);
      end
      else
      begin
        DestructionAlpha := 255;
        DestructionAlphaStep := 0;
      end;
    end
    else if DestructionEffect = 1 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Weapon.Bomb');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText(
          '[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']'
      );
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 1;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
    end
    else if DestructionEffect = 4 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Weapon.Expl0');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText(
          '[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']'
      );
      DestructionAnimation.StopAutoPlayback;
      for I := 0 to 3 do
      begin
        ExtraDestructionAnimations[I] := TgaiGI.Create(Space.MapPanel);
        ExtraDestructionAnimations[I].SetActive(False);
        ExtraDestructionAnimations[I].SetImagePath('Bm.Weapon.Expl0');
        ExtraDestructionAnimations[I].SetSize(ExtraDestructionAnimations[I].GetContentSize);
        ExtraDestructionAnimations[I]
            .SetOrigin(HalfPoint(ExtraDestructionAnimations[I].ClientSize));
        ExtraDestructionAnimations[I].SetDepthByName('Weapon');
        ExtraDestructionAnimations[I].SetPositionModeW(True);
        ExtraDestructionAnimations[I]
            .LoadFrameSequenceFromText(
                '[50,0-'
                    + IntToStr(ExtraDestructionAnimations[I].GetMainImageFrameCount - 1)
                    + ']');
        ExtraDestructionAnimations[I].StopAutoPlayback;
        Distance := RandomIntRange(50, 100);
        Angle := HeadingDegreesToRadians(RandomIntRange(0, 360));
        ExtraDestructionAnimations[I].UserValue := Round(Sin(Angle) * Distance);
        ExtraDestructionAnimations[I].UserIndex := Round(Cos(Angle) * -Distance);
      end;
      DestructionFrameInterval := 2;
      if TargetObject <> nil then
      begin
        DestructionAlpha := TargetObject.GetAlpha;
        DestructionAlphaStep :=
            (0.0 - DestructionAlpha) / (DestructionAnimation.GetMainImageFrameCount div 2 - 1);
      end
      else
      begin
        DestructionAlpha := 255;
        DestructionAlphaStep := 0;
      end;
    end
    else if DestructionEffect = 5 then
    begin
      TargetAnimation := TgaiGI.Create(Space.MapPanel);
      TargetAnimation.SetImagePath('Bm.Weapon.Kamikaze');
      TargetAnimation.SetSize(TargetAnimation.GetContentSize);
      TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
      TargetAnimation.SetDepthByName('Weapon');
      TargetAnimation.SetPositionModeW(True);
      TargetAnimation.LoadFrameSequenceFromText(
          '[1,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']'
      );
      TargetAnimation.StopAutoPlayback;
      TargetAnimationInterval := 3;
      if FilmSoundEffectsEnabled and not ObserverVisualRandom then
        if SoundInSpaceEnabled then
          if Space.ContainsMapPoint(GetTargetPoint) then
            SoundManager.PlaySound(HitSoundPath);
    end
    else if DestructionEffect = 2 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Asteroid.Des');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText(
          '[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']'
      );
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 4;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
    end
    else if DestructionEffect = 3 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Asteroid.Des');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText(
          '[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']'
      );
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 4;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 5;
    end;
    HasDestruction := True;
    if ImmediateDestruction then
    begin
      DestructionAnimation.SetActive(True);
      for I := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
        if ExtraDestructionAnimations[I] <> nil then
          ExtraDestructionAnimations[I].SetActive(True);
    end;
  end;
  if HasDestruction then
    if ImmediateDestruction then
      if FilmSoundEffectsEnabled and not ObserverVisualRandom then
        if SoundInSpaceEnabled then
          if Space.ContainsMapPoint(GetTargetPoint) then
            SoundManager.PlaySound(HitSoundPath);
  if PlayShotSound and FilmSoundEffectsEnabled and SoundInSpaceEnabled then
  begin
    if Projectile <> nil then
    begin
      if Space.ContainsMapPoint(PointToPointF(Projectile.LocalPosition)) then
        SoundManager.PlaySound(ShotSoundPath);
    end
    else if SourceAnimation <> nil then
      if Space.ContainsMapPoint(PointToPointF(SourceAnimation.LocalPosition)) then
        SoundManager.PlaySound(ShotSoundPath);
  end;
  if HitEffect <> nil then
  begin
    HitEffect.Owner := Space.MapPanel;
    HitEffect.SetSourcePoint(GetSourcePoint);
    HitEffect.SetTargetPoint(GetTargetPoint);
    HitEffect.DepthExpression := 'Weapon';
    HitEffect.Started := False;
  end;
  StepIndex := 0;
end;

procedure TWeaponSE.DetachFromSpace;
var
  Index: Integer;
begin
  if HitEffect <> nil then
  begin
    HitEffect.Free;
    HitEffect := nil;
  end;
  if SourceAnimation <> nil then
  begin
    SourceAnimation.Free;
    SourceAnimation := nil;
  end;
  if TargetAnimation <> nil then
  begin
    TargetAnimation.Free;
    TargetAnimation := nil;
  end;
  if Projectile <> nil then
  begin
    Projectile.Invalidate;
    Projectile.Free;
    Projectile := nil;
  end;
  if DamageLabel <> nil then
  begin
    DamageLabel.Invalidate;
    DamageLabel.Free;
    DamageLabel := nil;
  end;
  if DestructionAnimation <> nil then
  begin
    DestructionAnimation.Free;
    DestructionAnimation := nil;
  end;
  for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
    if ExtraDestructionAnimations[Index] <> nil then
    begin
      ExtraDestructionAnimations[Index].Free;
      ExtraDestructionAnimations[Index] := nil;
    end;
  inherited DetachFromSpace;
end;

procedure TWeaponSE.SetHit(Color, Damage: Integer; Destroyed, PlaySound: Boolean);
begin
  HitColor := Color;
  HitDamage := Damage;
  TargetDestroyed := Destroyed;
  PlayShotSound := PlaySound;
end;

procedure TWeaponSE.SetEndpoints(Source, Target: TObjectSE);
begin
  RetainSpaceObject(SourceObject, Source);
  RetainSpaceObject(TargetObject, Target);
end;

function TWeaponSE.GetTargetPoint: TPointF;
begin
  if TargetObject = nil then
    Result := Position
  else if TargetObject is TShip2SE then
    Result :=
        (TargetObject as TShip2SE)
            .GetTargetPoint(
                (TargetObject as TShip2SE).GetAngle,
                (Cardinal(TargetObject) + Cardinal(SourceObject) + Cardinal(Self)) shr 2)
  else
    Result := TargetObject.Position;
end;

function TWeaponSE.GetSourcePoint: TPointF;
begin
  if SourceObject = nil then
    Result := Position
  else if SourceObject is TShip2SE then
    Result :=
        TShip2SE(SourceObject)
            .GetWeaponPortPoint(
                SourceObject.GetAngle,
                (Cardinal(TargetObject) + Cardinal(SourceObject) + Cardinal(Self)) shr 2)
  else if SourceObject is TRuinsSE then
    Result :=
        TRuinsSE(SourceObject)
            .GetWeaponPortPoint(
                (Cardinal(TargetObject) + Cardinal(SourceObject) + Cardinal(Self)) shr 2)
  else
    Result := SourceObject.Position;
end;

procedure TWeaponSE.Advance;
var
  Index: Integer;
begin
  if not IsAttachedToSpace then
    Exit;
  if (HitEffect <> nil) and (Projectile <> nil) then
  begin
    if not HitEffect.Started then
    begin
      if not ProjectileFinished
          and (HitEffect.LeftTime >= Projectile.RemainingTicks)
          and HitEffect.BeforeEnd then
      begin
        HitEffect.Started := True;
        HitEffect.Start;
      end
      else if not ProjectileFinished
          and not HitEffect.BeforeEnd
          and (Projectile.GetElapsedTicks >= HitEffect.LeftTime) then
      begin
        HitEffect.Started := True;
        HitEffect.Start;
      end;
    end
    else
    begin
      HitEffect.SetSourcePoint(GetSourcePoint);
      HitEffect.SetTargetPoint(GetTargetPoint);
      if HitEffect.IsFinished then
      begin
        if DestructionAnimation = nil then
        begin
          DetachFromSpace;
          Exit;
        end;
      end
      else
        HitEffect.Advance;
    end;
  end;
  if Projectile <> nil then
  begin
    if not ProjectileFinished then
      Projectile.Advance(nil, 0);
    if not ProjectileFinished and Projectile.IsFinished then
    begin
      ProjectileFinished := True;
      if Projectile <> nil then
        Projectile.SetActive(False);
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
            if ExtraDestructionAnimations[Index] <> nil then
              ExtraDestructionAnimations[Index].SetActive(True);
          if FilmSoundEffectsEnabled and not ObserverVisualRandom then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then
                SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if (HitEffect = nil) and (TargetAnimation = nil) then
        DetachFromSpace;
    end;
  end
  else if SourceAnimation = nil then
  begin
    if (StepIndex >= 50) and not ProjectileFinished then
    begin
      ProjectileFinished := True;
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
            if ExtraDestructionAnimations[Index] <> nil then
              ExtraDestructionAnimations[Index].SetActive(True);
          if FilmSoundEffectsEnabled and not ObserverVisualRandom then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then
                SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if (HitEffect = nil) and (TargetAnimation = nil) then
        DetachFromSpace;
    end;
  end
  // The native branch checks nonnil again after the preceding nil branch.
  else if SourceAnimation <> nil then
  begin
    if SourceAnimation.SequenceFrame = SourceAnimation.SequenceFrameCount - 1 then
    begin
      SourceAnimation.Free;
      SourceAnimation := nil;
      ProjectileFinished := True;
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
            if ExtraDestructionAnimations[Index] <> nil then
              ExtraDestructionAnimations[Index].SetActive(True);
          if FilmSoundEffectsEnabled and not ObserverVisualRandom then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then
                SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if (HitEffect = nil) and (TargetAnimation = nil) then
        DetachFromSpace;
    end
    else
    begin
      if StepIndex mod SourceAnimationInterval = 0 then
      begin
        SourceAnimation.SetSequenceFrame(SourceAnimation.SequenceFrame + 1);
        SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
      end;
    end;
  end;
  if TargetAnimation <> nil then
  begin
    if TargetAnimation.SequenceFrame = TargetAnimation.SequenceFrameCount - 1 then
    begin
      TargetAnimation.Free;
      TargetAnimation := nil;
      if DestructionAnimation = nil then
        DetachFromSpace;
    end
    else
    begin
      if StepIndex mod TargetAnimationInterval = 0 then
        TargetAnimation.SetSequenceFrame(TargetAnimation.SequenceFrame + 1);
      TargetAnimation.SetPosition(TruncatePointF(GetTargetPoint));
    end;
  end;
  if DestructionEffect = 6 then
  begin
    if DestructionDetachStep > 0 then
    begin
      Dec(DestructionDetachStep);
      if DestructionDetachStep = 0 then
        if TargetObject <> nil then
          TargetObject.DetachFromSpace;
    end;
  end;
  if (DestructionAnimation <> nil) and (DestructionAnimation.Active = True) then
  begin
    if DestructionAnimation.SequenceFrame = DestructionAnimation.SequenceFrameCount - 1 then
    begin
      DestructionAnimation.Free;
      DestructionAnimation := nil;
      for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
        if ExtraDestructionAnimations[Index] <> nil then
        begin
          ExtraDestructionAnimations[Index].Free;
          ExtraDestructionAnimations[Index] := nil;
        end;
      if (TargetAnimation = nil) and ProjectileFinished then
        DetachFromSpace;
    end
    else
    begin
      if StepIndex mod DestructionFrameInterval = 0 then
      begin
        DestructionAnimation.SetSequenceFrame(DestructionAnimation.SequenceFrame + 1);
        for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
          if ExtraDestructionAnimations[Index] <> nil then
            ExtraDestructionAnimations[Index]
                .SetSequenceFrame(ExtraDestructionAnimations[Index].SequenceFrame + 1);
        if (DestructionAnimation.SequenceFrame = DestructionDetachStep)
            and (TargetObject <> nil) then
          TargetObject.DetachFromSpace;
      end;
      DestructionAnimation.SetPosition(TruncatePointF(GetTargetPoint));
      for Index := Low(ExtraDestructionAnimations) to High(ExtraDestructionAnimations) do
        if ExtraDestructionAnimations[Index] <> nil then
          ExtraDestructionAnimations[Index]
              .SetPosition(
                  Classes.Point(
                      DestructionAnimation.LocalPosition.X
                          + ExtraDestructionAnimations[Index].UserValue,
                      DestructionAnimation.LocalPosition.Y
                          + ExtraDestructionAnimations[Index].UserIndex
                  ));
      if DestructionAlphaStep <> 0 then
      begin
        DestructionAlpha := DestructionAlpha + DestructionAlphaStep;
        if DestructionAlpha < 0 then
          DestructionAlpha := 0
        else if DestructionAlpha > 255 then
          DestructionAlpha := 255;
        TargetObject.SetAlpha(Round(DestructionAlpha));
      end;
    end;
  end;
  if Projectile <> nil then
  begin
    Projectile.SetPosition(TruncatePointF(GetSourcePoint));
    Projectile.SetTargetPoint(TruncatePointF(GetTargetPoint));
  end;
  if DamageLabel <> nil then
  begin
    DamageLabelPoint.X := DamageLabelPoint.X - 1.0;
    DamageLabelPoint.Y := DamageLabelPoint.Y - 1.0;
    DamageLabel.SetPosition(RoundPointF(DamageLabelPoint));
  end;
  Inc(StepIndex);
end;

procedure TWeaponSE.LoadTemplate(Block: TBlockParEC);
var
  PaletteBlock, Palettes: TBlockParEC;
  function GetWeaponTemplateParam(
      Name: WideString
  ): WideString; // @addr $6A0150 @ida "void __usercall $name(unsigned __int16 *Name@<eax>, unsigned __int16 **Result@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x6A02A2, 0x6A02BF"
  begin
    if (PaletteBlock <> nil) and (PaletteBlock.CountParams(Name) > 0) then
      Result := PaletteBlock.GetParam(Name)
    else if Block.CountParams(Name) > 0 then
      Result := Block.GetParam(Name)
    else
      Result := '';
  end;
begin
  inherited LoadTemplate(Block);
  PaletteBlock := nil;
  if Block.CountBlocks('Palettes') > 0 then
  begin
    Palettes := Block.GetBlock('Palettes');
    if Palettes.CountBlocks(IntToStr(ShotVisual)) > 0 then
      PaletteBlock := Palettes.GetBlock(IntToStr(ShotVisual));
  end;
  ShotSoundPath := GetWeaponTemplateParam('SoundShot');
  HitSoundPath := GetWeaponTemplateParam('SoundExpl');
  if (PaletteBlock <> nil) and (PaletteBlock.CountParams('PosZ') > 0) then
    DepthExpression := PaletteBlock.GetParam('PosZ')
  else if Block.CountParams('PosZ') > 0 then
    DepthExpression := Block.GetParam('PosZ');
end;

constructor TWeaponEffect.Create(AEffectIndex: Integer; AOwner: TObjectGI);
var
  Block: TBlockParEC;
begin
  Started := True;
  EffectIndex := AEffectIndex;
  Owner := AOwner;
  Direction := 0;
  AnimationInterval := 1;
  AnimationCountdown := 0;
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex));
  if Block.CountParams('LeftTime') > 0 then
    LeftTime := ExtractDigitsToIntW(Block.GetParam('LeftTime'))
  else
    LeftTime := 10;
  if Block.CountParams('BeforeEnd') > 0 then
    BeforeEnd := ParseEnabledNameGI(Block.GetParam('BeforeEnd'))
  else
    BeforeEnd := True;
end;

destructor TWeaponEffect.Destroy;
begin
  Clear;
end;

procedure TWeaponEffect.Clear;
begin
  while FirstItem <> nil do
    RemoveItem(FirstItem);
end;

function TWeaponEffect.AddItem: PWeaponEffectItem;
var
  Item: PWeaponEffectItem;
begin
  New(Item);
  Item.Next := nil;
  Item.Prev := LastItem;
  if FirstItem = nil then
    FirstItem := Item
  else
    LastItem.Next := Item;
  LastItem := Item;
  Item.Image := nil;
  Item.Position := MakePointF(0, 0);
  Item.Angle := 0;
  Item.Lifetime := 1;
  Item.Speed := 0;
  Item.Acceleration := 0;
  Result := Item;
end;

procedure TWeaponEffect.RemoveItem(Item: PWeaponEffectItem);
begin
  if Item = nil then
    Exit;
  if Item.Image <> nil then
  begin
    Item.Image.Free;
    Item.Image := nil;
  end;
  if Item.Next <> nil then
    Item.Next.Prev := Item.Prev;
  if Item.Prev <> nil then
    Item.Prev.Next := Item.Next;
  if LastItem = Item then
    LastItem := Item.Prev;
  if FirstItem = Item then
    FirstItem := Item.Next;
  Dispose(Item);
end;

procedure TWeaponEffect.AddTargetEffect(Index: Integer);
var
  Block: TBlockParEC;
  Item: PWeaponEffectItem;
begin
  Block :=
      GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex) + '.D:' + IntToStr(Index));
  Item := AddItem;
  Item.AtTarget := True;
  Item.Position := MakePointF(0, ExtractDecimalToSingleW(Block.GetParam('StartPos')));
  Item.Angle := ExtractDigitsToIntW(Block.GetParam('Angle')) / 180.0 * Pi;
  Item.Speed := ExtractDecimalToSingleW(Block.GetParam('Speed'));
  Item.Acceleration := ExtractDecimalToSingleW(Block.GetParam('Accel'));
  if Block.CountParams('AutoAnim') > 0 then
    Item.AutoAnimation := ParseEnabledNameGI(Block.GetParam('AutoAnim'))
  else
    Item.AutoAnimation := True;
  if Block.CountParams('LoopAnim') > 0 then
    Item.LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'))
  else
    Item.LoopAnimation := True;
  if Block.CountParams('SkipTime') > 0 then
    Item.SkipTime := ExtractDigitsToIntW(Block.GetParam('SkipTime'))
  else
    Item.SkipTime := 0;
  Item.Image := TgaiGI.Create(Owner);
  Item.Image.SetImagePath(Block.GetParam('Image'));
  Item.Image.SequenceIndex := 0;
  Item.Image.UpdateAutoGeometry;
  Item.Image.SetSize(Item.Image.GetContentSize);
  Item.Image.SetOrigin(HalfPoint(Item.Image.ClientSize));
  Item.Image.SetDepthByName(DepthExpression);
  Item.Image.SetPosition(
      TruncatePointF(OffsetPointByRadiusAngle(TargetPoint, Item.Position.Y, Item.Angle))
  );
  Item.Image.SetPositionModeW(True);
  Item.Image.SetSequenceFrame(0);
  if Item.SkipTime = 0 then
    Item.Image.RestartPlayback
  else
    Item.Image.SetActive(False);
  if Block.CountParams('LifeTime') > 0 then
    Item.Lifetime := ExtractDigitsToIntW(Block.GetParam('LifeTime'))
  else
    Item.Lifetime := Item.Image.SequenceFrameCount * AnimationInterval;
  Item.Image.UserValue := PtrInt(Item);
  if Item.AutoAnimation and not Item.LoopAnimation then
    Item.Image.CycleCompleteCallback := AnimationComplete;
end;

procedure TWeaponEffect.AddSourceEffect(Index: Integer);
var
  Block: TBlockParEC;
  Item: PWeaponEffectItem;
begin
  Block :=
      GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex) + '.S:' + IntToStr(Index));
  Item := AddItem;
  Item.AtTarget := False;
  Item.Position := MakePointF(0, ExtractDecimalToSingleW(Block.GetParam('StartPos')));
  Item.Angle := ExtractDigitsToIntW(Block.GetParam('Angle')) / 180.0 * Pi;
  Item.Speed := ExtractDecimalToSingleW(Block.GetParam('Speed'));
  Item.Acceleration := ExtractDecimalToSingleW(Block.GetParam('Accel'));
  if Block.CountParams('AutoAnim') > 0 then
    Item.AutoAnimation := ParseEnabledNameGI(Block.GetParam('AutoAnim'))
  else
    Item.AutoAnimation := True;
  if Block.CountParams('LoopAnim') > 0 then
    Item.LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'))
  else
    Item.LoopAnimation := True;
  if Block.CountParams('SkipTime') > 0 then
    Item.SkipTime := ExtractDigitsToIntW(Block.GetParam('SkipTime'))
  else
    Item.SkipTime := 0;
  Item.Image := TgaiGI.Create(Owner);
  Item.Image.SetImagePath(Block.GetParam('Image'));
  Item.Image.SequenceIndex := 0;
  Item.Image.UpdateAutoGeometry;
  Item.Image.SetSize(Item.Image.GetContentSize);
  Item.Image.SetOrigin(HalfPoint(Item.Image.ClientSize));
  Item.Image.SetDepthByName(DepthExpression);
  Item.Image.SetPosition(
      TruncatePointF(OffsetPointByRadiusAngle(SourcePoint, Item.Position.Y, Item.Angle))
  );
  Item.Image.SetPositionModeW(True);
  Item.Image.SetSequenceFrame(0);
  if Item.SkipTime = 0 then
    Item.Image.RestartPlayback
  else
    Item.Image.SetActive(False);
  if Block.CountParams('LifeTime') > 0 then
    Item.Lifetime := ExtractDigitsToIntW(Block.GetParam('LifeTime'))
  else
    Item.Lifetime := Item.Image.SequenceFrameCount * AnimationInterval;
  Item.Image.UserValue := PtrInt(Item);
  if Item.AutoAnimation and not Item.LoopAnimation then
    Item.Image.CycleCompleteCallback := AnimationComplete;
end;

procedure TWeaponEffect.Start;
var
  Index, Count: Integer;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex));
  if Block.CountParams('AnimTakt') > 0 then
    AnimationInterval := ExtractDigitsToIntW(Block.GetParam('AnimTakt'))
  else
    AnimationInterval := 1;
  AnimationCountdown := AnimationInterval;
  Count := Block.CountBlocks('D');
  for Index := 0 to Count - 1 do
    AddTargetEffect(Index);
  Count := Block.CountBlocks('S');
  for Index := 0 to Count - 1 do
    AddSourceEffect(Index);
end;

procedure TWeaponEffect.Advance;
var
  Item, Previous: PWeaponEffectItem;
begin
  // Preserve the native shared animation countdown and the per-item angle - 90 update.
  Item := FirstItem;
  while Item <> nil do
  begin
    if Item.SkipTime = 0 then
    begin
      Dec(Item.Lifetime);
      Item.Position.Y := Item.Position.Y + Item.Speed;
      Item.Speed := Item.Speed + Item.Acceleration;
    end;
    if Item.Image <> nil then
    begin
      if Item.AtTarget then
        Item.Image.SetPosition(
            TruncatePointF(
                OffsetPointByRadiusAngle(TargetPoint, Item.Position.Y, Item.Angle - 90.0)
            )
        )
      else
        Item.Image.SetPosition(
            TruncatePointF(
                OffsetPointByRadiusAngle(SourcePoint, Item.Position.Y, Item.Angle - 90.0)
            )
        );
      if Item.SkipTime = 0 then
      begin
        Dec(AnimationCountdown);
        if AnimationCountdown = 0 then
        begin
          if not Item.AutoAnimation then
          begin
            if Item.Image.SequenceFrame = Item.Image.SequenceFrameCount - 1 then
            begin
              if Item.LoopAnimation then
                Item.Image.SetSequenceFrame(0)
              else
                Item.Lifetime := 0;
            end
            else
              Item.Image.SetSequenceFrame(Item.Image.SequenceFrame + 1);
          end;
          AnimationCountdown := AnimationInterval;
        end;
      end
      else
      begin
        Dec(Item.SkipTime);
        if Item.SkipTime = 0 then
        begin
          Item.Image.SetActive(True);
          Item.Image.RestartPlayback;
        end;
      end;
    end;
    Previous := Item;
    Item := Item.Next;
    if Previous.Lifetime = 0 then
      RemoveItem(Previous);
  end;
end;

procedure TWeaponEffect.AnimationComplete(Sender: TObjectGI);
var
  Item: PWeaponEffectItem;
begin
  Item := PWeaponEffectItem(Sender.UserValue);
  RemoveItem(Item);
end;

function TWeaponEffect.IsFinished: Boolean;
begin
  if FirstItem = nil then
    Result := True
  else
    Result := False;
end;

procedure TWeaponEffect.SetSourcePoint(Point: TPointF);
var
  X, Y: Single;
begin
  SourcePoint := Point;
  X := TargetPoint.X - SourcePoint.X;
  Y := TargetPoint.Y - SourcePoint.Y;
  if Abs(X) < 1.0 then
    Direction := ArcTan2(Y, 1.0) + 2 * Pi
  else
    Direction := ArcTan2(Y, X) + 2 * Pi;
end;

procedure TWeaponEffect.SetTargetPoint(Point: TPointF);
var
  X, Y: Single;
begin
  TargetPoint := Point;
  X := TargetPoint.X - SourcePoint.X;
  Y := TargetPoint.Y - SourcePoint.Y;
  if Abs(X) < 1.0 then
    Direction := ArcTan2(Y, 1.0) + 2 * Pi
  else
    Direction := ArcTan2(Y, X) + 2 * Pi;
end;

procedure InitializeWeaponVisualResources;
begin
  LoadBeamLaserPalettes;
  LoadFragCannonPalettes;
  LoadLezkaPalettes;
  LoadTretonPalettes;
  LoadPhaserPalettes;
  LoadBlasterPalettes;
  LoadECutterPalettes;
  LoadMResonatorPalettes;
  LoadAVisionPalettes;
  LoadDesintegratorPalettes;
  LoadTurbogravirPalettes;
  LoadIMHOPalettes;
  LoadWeapon14AnimationPaths;
  LoadEsodaferPalettes;
  LoadKafacitorPalettes;
  LoadEyesPalettes;
  LoadMissileHitAnimationPaths;
  LoadRadiationPalettes;
end;

procedure LinkRecoveredTypes;
begin
  TRuinsSE.ClassName;
  TShip2SE.ClassName;
end;
end.
