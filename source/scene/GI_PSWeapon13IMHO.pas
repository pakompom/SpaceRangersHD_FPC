{$EXCESSPRECISION OFF}
unit GI_PSWeapon13IMHO;
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
  PointerToTIMHOParticle = ^TIMHOParticle;
  PIMHOParticle = PointerToTIMHOParticle;
  TIMHOParticle = record
    Kind: Integer;
    Position: TPointF;
    Color: Word;
    Alpha: Byte;
    GapF: array[0..0] of Byte;
    Velocity: TPointF;
    Gap18: array[0..1] of Byte;
    Unknown1A: Byte;
    Gap1B: array[0..0] of Byte;
  end;
  TIMHOPalette = array[0..7] of Word;
var
  IMHOPalettes: array of TIMHOPalette;
type
  TPSWeapon13IMHO = class;
  TPSWeapon13IMHO = class(TPSWeaponGI)
    Particles: PIMHOParticle;
    ParticleCount: Integer;
    ParticleCapacity: Integer;
    OriginalLength: Single;
    Colors: TIMHOPalette;
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
    function AddParticle: PIMHOParticle;
  end;
procedure LoadIMHOPalettes;
implementation
uses
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
// @unit-initialization $877944
// @unit-finalization $695C40

constructor TPSWeapon13IMHO.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  RemainingTicks := 55;
  LifetimeTicks := 55;
  Colors[0] := IMHOPalettes[APaletteIndex][0];
  Colors[1] := IMHOPalettes[APaletteIndex][1];
  Colors[2] := IMHOPalettes[APaletteIndex][2];
  Colors[3] := IMHOPalettes[APaletteIndex][3];
  Colors[4] := IMHOPalettes[APaletteIndex][4];
  Colors[5] := IMHOPalettes[APaletteIndex][5];
  Colors[6] := IMHOPalettes[APaletteIndex][6];
  Colors[7] := IMHOPalettes[APaletteIndex][7];
end;

destructor TPSWeapon13IMHO.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon13IMHO.Invalidate;
begin
end;

procedure TPSWeapon13IMHO.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
    inherited SetPosition(Position);
end;

procedure TPSWeapon13IMHO.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
    TargetPoint := Point;
end;

procedure TPSWeapon13IMHO.UpdateHitTestBounds;
begin
  if MessageLoop <> nil then
    HitTestBounds := MessageLoop.ViewportRect
  else
    HitTestBounds := Types.Rect(0, 0, GameScreenWidth, GameScreenHeight);
end;

procedure TPSWeapon13IMHO.ClearParticles;
begin
  if Particles <> nil then
  begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;

procedure TPSWeapon13IMHO.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TIMHOParticle));
end;

function TPSWeapon13IMHO.AddParticle: PIMHOParticle;
begin
  if ParticleCount >= ParticleCapacity then
    GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TIMHOParticle));
  Inc(ParticleCount);
end;

procedure TPSWeapon13IMHO.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Particle: PIMHOParticle;
  J, I, K, L, M: Integer;
  Speed, PX, PY: Single;
begin
  if RemainingTicks = 55 then
  begin
    OriginalLength :=
        Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    Speed := (OriginalLength + 40.0) / 55.0;
    for I := 0 to 1 do
      for J := 0 to 3 do
      begin
        K := -10;
        while K < 10 do
        begin
          PX := (J * 6 * 10 / OriginalLength + 4.0) * (K / 10.0);
          PY := Sqrt(256 - Sqr(K)) + J * 10 - 40.0 + I + Sin(K * 3 / 10.0 * Pi) * 1.5;
          for L := -1 to 1 do
            for M := -1 to 1 do
            begin
              Particle := AddParticle;
              Particle.Kind := 2;
              Particle.Position.X := L + PX;
              Particle.Position.Y := M + PY;
              Particle.Color := Colors[(Abs(K) * 8) div 11];
              Particle.Alpha := 0;
              Particle.Velocity.X := 6.0 * Particle.Position.X / 4.0 / 55.0;
              Particle.Velocity.Y := Speed;
              Particle.Unknown1A := 0;
            end;
          Inc(K, 10);
        end;
      end;
  end;
  UpdateHitTestBounds;
  I := 0;
  Particle := Particles;
  J := ParticleCount;
  while J > 0 do
  begin
    if Particle.Kind = 2 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y >= OriginalLength then
        Particle.Kind := 0;
      if Particle.Position.Y > 0 then
      begin
        if Particle.Alpha < 231 then
          Inc(Particle.Alpha, 24)
        else
          Particle.Alpha := 255;
      end;
    end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TIMHOParticle));
    Dec(J);
  end;
  if RemainingTicks > 0 then
    Dec(RemainingTicks);
end;

procedure TPSWeapon13IMHO.Draw(ClipRect: TRect);
var
  X, Y: Integer;
  PX, PY, Sine, Cosine, Angle, Scale: Single;
  Particle: PIMHOParticle;
  Count: Integer;
begin
  if OriginalLength = 0 then
    Advance(nil, 0);
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
      if Particle.Kind >= 2 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Trunc(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Trunc(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TIMHOParticle));
      Dec(Count);
    end;
    FlushDrawPoints(nil);
  end
  else
  begin
    while Count > 0 do
    begin
      if Particle.Kind >= 2 then
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * Scale;
        X := Trunc(PX * Cosine + PY * Sine) + AbsolutePosition.X;
        Y := Trunc(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
        if (X >= ClipRect.Left)
            and (X < ClipRect.Right)
            and (Y >= ClipRect.Top)
            and (Y < ClipRect.Bottom) then
          ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TIMHOParticle));
      Dec(Count);
    end;
  end;
end;

procedure LoadIMHOPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.12.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(IMHOPalettes, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      for ColorIndex := 0 to 7 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex));
          IMHOPalettes[Index][ColorIndex] :=
              CurrentPixelFormat.PackNormalizedRgb(
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 1, ',')),
                  ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 2, ','))
              );
        end;
    end;
  end;
end;

end.
