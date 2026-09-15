{$EXCESSPRECISION OFF}
unit GI_PSWeapon10AVision;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_MessageLoop,
  GI_PSWeapon,
  Types;
type
  PointerToTAVisionParticle = ^TAVisionParticle;
  PAVisionParticle = PointerToTAVisionParticle;
  TAVisionParticle = record
    Kind: Integer;
    Position: TPointF;
    Color: Word;
    Alpha: Byte;
    GapF: array[0..0] of Byte;
    Velocity: TPointF;
    FadeInTicks: Byte;
    InitialFadeInTicks: Byte;
    FadeOutThreshold: Byte;
    Gap1B: array[0..0] of Byte;
  end;
  TAVisionPalette = array[0..3] of Word;
  TGAISet = array[0..0] of WideString;
var
  AVisionPalettes: array of TAVisionPalette;
  AVisionAnimationPaths: array of TGAISet;
type
  TPSWeapon10AVision = class;
  TPSWeapon10AVision = class(TPSWeaponGI)
    Unknown130: Integer;
    Particles: PAVisionParticle;
    ParticleCount: Integer;
    ParticleCapacity: Integer;
    OriginalLength: Single;
    Colors: TAVisionPalette;
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
    function AddParticle: PAVisionParticle;
  end;
procedure LoadAVisionPalettes;
implementation
uses
  ObserverHooks,
  GlobalsV,
  SysUtils,
  Math,
  EC_BlockPar,
  EC_Str,
  EC_Mem,
  GR_Main,
  GR_DX,
  aMyFunction,
  Globals;
// @unit-initialization $87792C
// @unit-finalization $691CE4

constructor TPSWeapon10AVision.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  RemainingTicks := 40;
  LifetimeTicks := 40;
  Unknown130 := 0;
  Colors[0] := AVisionPalettes[APaletteIndex][0];
  Colors[1] := AVisionPalettes[APaletteIndex][1];
  Colors[2] := AVisionPalettes[APaletteIndex][2];
  Colors[3] := AVisionPalettes[APaletteIndex][3];
end;

destructor TPSWeapon10AVision.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon10AVision.Invalidate;
begin
end;

procedure TPSWeapon10AVision.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
    inherited SetPosition(Position);
end;

procedure TPSWeapon10AVision.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
    TargetPoint := Point;
end;

procedure TPSWeapon10AVision.UpdateHitTestBounds;
begin
  if MessageLoop <> nil then
    HitTestBounds := MessageLoop.ViewportRect
  else
    HitTestBounds := Types.Rect(0, 0, GameScreenWidth, GameScreenHeight);
end;

procedure TPSWeapon10AVision.ClearParticles;
begin
  if Particles <> nil then
  begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;

procedure TPSWeapon10AVision.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TAVisionParticle));
end;

function TPSWeapon10AVision.AddParticle: PAVisionParticle;
begin
  if ParticleCount >= ParticleCapacity then
    GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TAVisionParticle));
  Inc(ParticleCount);
end;

procedure TPSWeapon10AVision.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Particle: PAVisionParticle;
  Count, I: Integer;
  Y: Single;
begin
  if RemainingTicks = 40 then
  begin
    OriginalLength :=
        Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    for I := 0 to 3 do
    begin
      Y := 0;
      while Y < OriginalLength do
      begin
        Particle := AddParticle;
        if PresentationRandom(2) = 0 then
          Particle.Position.X := -I
        else
          Particle.Position.X := I;
        Particle.Position.Y := Y;
        Particle.Kind := 1;
        Particle.Alpha := 0;
        Particle.InitialFadeInTicks := 11 - I;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := 7.0 - I * 2;
        Particle.FadeOutThreshold := Trunc(Sin(Pi * Y / 40.0) * 8.0 + 20.0);
        Particle.Color := Colors[I];
        Y := Y + 1.5 + I;
      end;
    end;
  end;
  Particle := Particles;
  Count := ParticleCount;
  I := 0;
  UpdateHitTestBounds;
  while Count > 0 do
  begin
    if Particle.Kind = 1 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
      end
      else
      begin
        Inc(Particle.Alpha, 20);
        Dec(Particle.FadeInTicks);
        if Particle.FadeInTicks = 0 then
        begin
          Particle.FadeInTicks := 100;
          Particle.Kind := 2;
        end;
      end;
      if RemainingTicks < Particle.FadeOutThreshold then
        Particle.Kind := 3;
    end
    else if Particle.Kind = 2 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if OriginalLength - 32.0 < Particle.Position.Y then
      begin
        if Particle.Alpha < 245 then
          Inc(Particle.Alpha, 10)
        else
          Particle.Alpha := 255;
      end;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
        Particle.Kind := 1;
      end;
      if RemainingTicks < Particle.FadeOutThreshold then
        Particle.Kind := 3;
    end
    else if Particle.Kind = 3 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
      end;
      if Particle.Alpha > 12 then
        Dec(Particle.Alpha, 12)
      else
        Particle.Alpha := 0;
    end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TAVisionParticle));
    Dec(Count);
  end;
  Dec(RemainingTicks);
end;

procedure TPSWeapon10AVision.Draw(ClipRect: TRect);
var
  X, Y: Integer;
  PX, PY, Sine, Cosine, Angle, Scale: Single;
  Particle: PAVisionParticle;
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
      Particle := AddPointerOffset(Particle, SizeOf(TAVisionParticle));
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
      Particle := AddPointerOffset(Particle, SizeOf(TAVisionParticle));
      Dec(Count);
    end;
  end;
end;

procedure LoadAVisionPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.9.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(AVisionPalettes, Count);
  SetLength(AVisionAnimationPaths, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      for ColorIndex := 0 to 3 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex));
          AVisionPalettes[Index][ColorIndex] :=
              CurrentPixelFormat.PackNormalizedRgb(
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 1, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 2, ','))
              );
        end;
      if PaletteBlock.CountParams('GAI') > 0 then
        AVisionAnimationPaths[Index][0] := PaletteBlock.GetParam('GAI');
    end;
  end;
end;

end.
