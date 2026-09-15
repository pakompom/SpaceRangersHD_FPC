{$EXCESSPRECISION OFF}
unit GI_PSWeapon09MResonator;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_MessageLoop,
  GI_PSWeapon,
  GI_GAI,
  Types;
type
  PointerToTMResonatorParticle = ^TMResonatorParticle;
  PMResonatorParticle = PointerToTMResonatorParticle;
  TMResonatorParticle = record
    Kind: Integer;
    Position: TPointF;
    Color: Word;
    Alpha: Byte;
    GapF: array[0..0] of Byte;
    Velocity: TPointF;
    DelayTicks: Byte;
    MovementDelay: Byte;
    Unknown1A: Byte;
    Unknown1B: Byte;
  end;
  TMResonatorPalette = array[0..0] of Word;
  TGAISet = array[0..0] of WideString;
var
  MResonatorPalettes: array of TMResonatorPalette;
  MResonatorAnimationPaths: array of TGAISet;
type
  TPSWeapon09BranchGI = class;
  TPSWeapon09MResonator = class;
  TPSWeapon09MResonator = class(TPSWeaponGI)
    Unknown130: Integer;
    Particles: PMResonatorParticle;
    ParticleCount: Integer;
    ParticleCapacity: Integer;
    OriginalLength: Single;
    Animation: TgaiGI;
    AnimationPosition: TPointF;
    AnimationVelocity: TPointF;
    Unknown158: Byte;
    Gap159: array[0..2] of Byte;
    AnimationPath: WideString;
    procedure UpdateHitTestBounds; override;
    procedure SetPosition(Position: TPoint); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure SetTargetPoint(Point: TPoint); override;
    procedure Advance(Timer: PCallbackTimerGI; UserData: PtrInt); override;
    constructor Create(Owner: TObjectGI; APaletteIndex: Integer);
    destructor Destroy; override;
    procedure ClearParticles;
  end;
  TPSWeapon09BranchGI = class(TPSWeaponGI)
    Unknown130: Integer;
    Particles: PMResonatorParticle;
    ParticleCount: Integer;
    ParticleCapacity: Integer;
    OriginalLength: Single;
    Unknown144: Byte;
    Gap145: array[0..0] of Byte;
    ParticleColor: Word;
    procedure UpdateHitTestBounds; override;
    procedure SetPosition(Position: TPoint); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure SetTargetPoint(Point: TPoint); override;
    procedure Advance(Timer: PCallbackTimerGI; UserData: PtrInt); override;
    constructor Create(Owner: TObjectGI; APaletteIndex: Integer);
    destructor Destroy; override;
    procedure ClearParticles;
    procedure GrowParticles;
    function AddParticle: PMResonatorParticle;
  end;
procedure LoadMResonatorPalettes;
implementation
uses
  GlobalsV,
  SysUtils,
  Classes,
  Math,
  EC_BlockPar,
  EC_Str,
  EC_Mem,
  GR_Main,
  GR_DX,
  aMyFunction,
  Globals;
// @unit-initialization $877924
// @unit-finalization $690E78

constructor TPSWeapon09BranchGI.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  RemainingTicks := 90;
  Unknown130 := 0;
  Unknown144 := 20;
  ParticleColor := MResonatorPalettes[APaletteIndex][0];
end;

destructor TPSWeapon09BranchGI.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon09BranchGI.Invalidate;
begin
end;

procedure TPSWeapon09BranchGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
    inherited SetPosition(Position);
end;

procedure TPSWeapon09BranchGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
    TargetPoint := Point;
end;

procedure TPSWeapon09BranchGI.UpdateHitTestBounds;
begin
  if MessageLoop <> nil then
    HitTestBounds := MessageLoop.ViewportRect
  else
    HitTestBounds := Types.Rect(0, 0, GameScreenWidth, GameScreenHeight);
end;

procedure TPSWeapon09BranchGI.ClearParticles;
begin
  if Particles <> nil then
  begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;

procedure TPSWeapon09BranchGI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TMResonatorParticle));
end;

function TPSWeapon09BranchGI.AddParticle: PMResonatorParticle;
begin
  if ParticleCount >= ParticleCapacity then
    GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TMResonatorParticle));
  Inc(ParticleCount);
end;

procedure TPSWeapon09BranchGI.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Particle: PMResonatorParticle;
  J, I, K: Integer;
  Delay: Integer;
  PY, PX, Speed, Angle: Single;
begin
  if RemainingTicks = 60 then
  begin
    OriginalLength :=
        Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    if OriginalLength < 1.0 then
      OriginalLength := 1;
    for I := 1 to 5 do
    begin
      PX := RandomIntRange(-16, 16);
      PY := RandomIntRange(-16, 16);
      Delay := RandomIntRange(5, 6);
      for J := 0 to 2 do
        for K := 0 to 7 do
        begin
          Particle := AddParticle;
          Particle.Kind := 1;
          case K of
            0:
            begin
              Particle.Position.X := J + PX;
              Particle.Position.Y := J + PY;
            end;
            1:
            begin
              Particle.Position.X := J + PX;
              Particle.Position.Y := PY - J;
            end;
            2:
            begin
              Particle.Position.X := PX - J;
              Particle.Position.Y := J + PY;
            end;
            3:
            begin
              Particle.Position.X := PX - J;
              Particle.Position.Y := PY - J;
            end;
            4:
            begin
              Particle.Position.X := J + PX + 1.0;
              Particle.Position.Y := J + PY;
            end;
            5:
            begin
              Particle.Position.X := J + PX + 1.0;
              Particle.Position.Y := PY - J;
            end;
            6:
            begin
              Particle.Position.X := PX - J + 1.0;
              Particle.Position.Y := J + PY;
            end;
            7:
            begin
              Particle.Position.X := PX - J + 1.0;
              Particle.Position.Y := PY - J;
            end;
          end;
          Particle.Color := ParticleColor;
          Particle.Alpha := 0;
          Particle.MovementDelay := 6;
          Particle.DelayTicks := Delay;
          Particle.Unknown1A := 0;
          Particle.Unknown1B := 1;
        end;
    end;
  end;
  Particle := Particles;
  J := ParticleCount;
  I := 0;
  UpdateHitTestBounds;
  if 90 - RemainingTicks > 30 then
    while J > 0 do
    begin
      if Particle.Kind = 1 then
      begin
        Dec(Particle.DelayTicks);
        if Particle.DelayTicks < 5 then
          Inc(Particle.Alpha, 50);
        Dec(Particle.MovementDelay);
        if Particle.MovementDelay = 0 then
        begin
          Particle.Kind := 2;
          Particle.Velocity.X := -Particle.Position.X / 50.0;
          Particle.Velocity.Y := (OriginalLength - 24.0) / 30.0;
        end;
      end
      else if Particle.Kind = 2 then
      begin
        Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
        Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
        if OriginalLength - 12.0 < Particle.Position.Y then
        begin
          Speed := RandomIntRange(6, 24) / 10.0;
          Angle := RandomIntRange(0, 360) / 180.0 * Pi;
          Particle.Velocity.X := Cos(Angle) * Speed;
          Particle.Velocity.Y := Sin(Angle) * Speed;
          Particle.Kind := 3;
          Particle.DelayTicks := 6;
        end;
      end
      else if Particle.Kind = 3 then
      begin
        Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
        Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
        Particle.Velocity.X := 0.99 * Particle.Velocity.X;
        Particle.Velocity.Y := 0.99 * Particle.Velocity.Y;
        if Particle.DelayTicks > 0 then
          Dec(Particle.DelayTicks)
        else if Particle.Alpha > 11 then
          Dec(Particle.Alpha, 10);
      end;
      Inc(I);
      Particle := AddPointerOffset(Particles, I * SizeOf(TMResonatorParticle));
      Dec(J);
    end;
  Dec(RemainingTicks);
end;

procedure TPSWeapon09BranchGI.Draw(ClipRect: TRect);
var
  X, Y: Integer;
  PX, PY, Sine, Cosine, Angle, Scale: Single;
  Particle: PMResonatorParticle;
  Count: Integer;
begin
  if OriginalLength = 0 then
    OriginalLength := 1;
  Scale :=
      Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y))
          / OriginalLength;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then
    PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := Particles;
  Count := ParticleCount;
  if HardwareRenderingEnabled then
  begin
    while Count > 0 do
    begin
      if Particle.Kind >= 1 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TMResonatorParticle));
      Dec(Count);
    end;
    FlushDrawPoints(@ClipRect);
  end
  else
  begin
    while Count > 0 do
    begin
      if Particle.Kind >= 1 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        if (X >= ClipRect.Left)
            and (X < ClipRect.Right)
            and (Y >= ClipRect.Top)
            and (Y < ClipRect.Bottom) then
          ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TMResonatorParticle));
      Dec(Count);
    end;
  end;
end;

constructor TPSWeapon09MResonator.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  RemainingTicks := 90;
  Unknown130 := 0;
  Animation := nil;
  AnimationPosition := MakePointF(LocalPosition.X, LocalPosition.Y);
  AnimationVelocity := MakePointF(0, 0);
  Unknown158 := 20;
  AnimationPath := MResonatorAnimationPaths[APaletteIndex][0];
end;

destructor TPSWeapon09MResonator.Destroy;
begin
  if Animation <> nil then
  begin
    Animation.Free;
    Animation := nil;
  end;
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon09MResonator.Invalidate;
begin
end;

procedure TPSWeapon09MResonator.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
    inherited SetPosition(Position);
end;

procedure TPSWeapon09MResonator.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
    TargetPoint := Point;
end;

procedure TPSWeapon09MResonator.UpdateHitTestBounds;
begin
  if MessageLoop <> nil then
    HitTestBounds := MessageLoop.ViewportRect
  else
    HitTestBounds := Types.Rect(0, 0, GameScreenWidth, GameScreenHeight);
end;

procedure TPSWeapon09MResonator.ClearParticles;
begin
  if Particles <> nil then
  begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;

procedure TPSWeapon09MResonator.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Angle, PX, PY, Sine, Cosine, Scale: Single;
begin
  if RemainingTicks = 90 then
  begin
    OriginalLength :=
        Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    if OriginalLength < 1.0 then
      OriginalLength := 1;
    if Animation <> nil then
      Animation.Free;
    Animation := TgaiGI.Create(Parent);
    Animation.SetImagePath(AnimationPath);
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetDepthByName('Weapon');
    Animation.SetPosition(TargetPoint);
    Animation.SetPositionModeW(True);
    Animation
        .LoadFrameSequenceFromText('[50,0-' + IntToStr(Animation.GetMainImageFrameCount - 1) + ']');
    Animation.SetSequenceFrame(0);
    Animation.StopAutoPlayback;
    AnimationVelocity := MakePointF(0, (OriginalLength - 24.0) / 30.0);
    AnimationPosition := MakePointF(0, 24.0 - AnimationVelocity.Y);
  end;
  if Animation <> nil then
  begin
    if AnimationPosition.Y < OriginalLength then
    begin
      AnimationPosition.Y := AnimationPosition.Y + AnimationVelocity.Y;
      AnimationPosition.X := AnimationPosition.X + AnimationVelocity.X;
      Scale :=
          Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y))
              / OriginalLength;
      PY := -(TargetPoint.Y - LocalPosition.Y);
      if PY = 0 then
        PY := 1;
      Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
      Sine := Sin(Angle);
      Cosine := Cos(Angle);
      PX := AnimationPosition.X;
      PY := AnimationPosition.Y * Scale;
      Animation.SetPosition(
          Classes.Point(
              Round(PX * Cosine + PY * Sine) + LocalPosition.X,
              Round(PX * Sine - PY * Cosine) + LocalPosition.Y
          )
      );
    end
    else
    begin
      if Animation.SequenceFrame = Animation.SequenceFrameCount - 1 then
      begin
        Animation.Free;
        Animation := nil;
      end
      else
      begin
        Animation.SetSequenceFrame(Animation.SequenceFrame + 1);
        Animation.SetPosition(TargetPoint);
      end;
    end;
  end;
  if RemainingTicks > 0 then
    Dec(RemainingTicks);
  if (RemainingTicks = 0) and (Animation <> nil) then
  begin
    Animation.Free;
    Animation := nil;
  end;
end;

procedure TPSWeapon09MResonator.Draw(ClipRect: TRect);
var
  X, Y: Integer;
  PX, PY, Sine, Cosine, Angle, Scale: Single;
  Particle: PMResonatorParticle;
  Count: Integer;
begin
  if OriginalLength = 0 then
    OriginalLength := 1;
  Scale :=
      Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y))
          / OriginalLength;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then
    PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := Particles;
  Count := ParticleCount;
  if HardwareRenderingEnabled then
  begin
    while Count > 0 do
    begin
      if Particle.Kind >= 1 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TMResonatorParticle));
      Dec(Count);
    end;
    FlushDrawPoints(@ClipRect);
  end
  else
  begin
    while Count > 0 do
    begin
      if Particle.Kind >= 1 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        if (X >= ClipRect.Left)
            and (X < ClipRect.Right)
            and (Y >= ClipRect.Top)
            and (Y < ClipRect.Bottom) then
          ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TMResonatorParticle));
      Dec(Count);
    end;
  end;
end;

procedure LoadMResonatorPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.8.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(MResonatorPalettes, Count);
  SetLength(MResonatorAnimationPaths, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      for ColorIndex := 0 to 0 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex));
          MResonatorPalettes[Index][ColorIndex] :=
              CurrentPixelFormat.PackNormalizedRgb(
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 1, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 2, ','))
              );
        end;
      if PaletteBlock.CountParams('GAI') > 0 then
        MResonatorAnimationPaths[Index][0] := PaletteBlock.GetParam('GAI');
    end;
  end;
end;

end.
