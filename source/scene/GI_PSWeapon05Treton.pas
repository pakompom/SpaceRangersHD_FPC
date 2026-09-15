{$EXCESSPRECISION OFF}
unit GI_PSWeapon05Treton;
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
  PointerToTTretonParticle = ^TTretonParticle;
  PTretonParticle = PointerToTTretonParticle;
  TTretonParticle = record
    Prev: PTretonParticle;
    Next: PTretonParticle;
    Position: TPointF;
    Color: Word;
    Alpha: Byte;
    MaximumAlpha: Byte;
    Velocity: TPointF;
    Countdown: Byte;
    State: Byte;
    Gap1E: array[0..1] of Byte;
  end;
  TTretonPalette = array[0..1] of Word;
var
  TretonPalettes: array of TTretonPalette;
type
  TPSWeapon05Treton = class;
  TPSWeapon05Treton = class(TPSWeaponGI)
    HalfWidth: Integer;
    FirstParticle: PTretonParticle;
    LastParticle: PTretonParticle;
    PrimaryColor: Word;
    SecondaryColor: Word;
    ProjectionBounds: TRect;
    LengthScale: Double;
    OriginalLength: Double;
    procedure UpdateHitTestBounds; override;
    procedure SetPosition(Position: TPoint); override;
    function GetLocalBounds: TRect; override;
    procedure InvalidateRect(Rect: TRect); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure SetTargetPoint(Point: TPoint); override;
    procedure Advance(Timer: PCallbackTimerGI; UserData: PtrInt); override;
    constructor Create(Owner: TObjectGI; APaletteIndex: Integer);
    destructor Destroy; override;
    procedure SetColors(FirstColor: Word; SecondColor: Word);
    procedure UpdateProjectionBounds;
    function AddParticle: PTretonParticle;
    procedure ClearParticles;
  end;
procedure LoadTretonPalettes;
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
// @unit-initialization $877904
// @unit-finalization $68C194

constructor TPSWeapon05Treton.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  HalfWidth := 3;
  RemainingTicks := 60;
  LifetimeTicks := 60;
  LengthScale := 1;
  OriginalLength := 1;
  UpdateProjectionBounds;
  SetColors(TretonPalettes[APaletteIndex][0], TretonPalettes[APaletteIndex][1]);
end;

destructor TPSWeapon05Treton.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon05Treton.SetColors(FirstColor, SecondColor: Word);
begin
  PrimaryColor := FirstColor;
  SecondaryColor := SecondColor;
end;

procedure TPSWeapon05Treton.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
  begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon05Treton.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
  begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon05Treton.UpdateProjectionBounds;
var
  Angle, Sine, Cosine, Distance, A, B, C, D: Single;
  DY: Integer;
begin
  DY := -(TargetPoint.Y - LocalPosition.Y);
  if DY = 0 then
    Inc(DY);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, DY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
  A := (-HalfWidth - 12) * Cosine - -Distance * Sine;
  B := (HalfWidth + 12) * Cosine - -Distance * Sine;
  C := (-HalfWidth - 12) * Cosine;
  D := (HalfWidth + 12) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth - 12) * Sine + -Distance * Cosine;
  B := (HalfWidth + 12) * Sine + -Distance * Cosine;
  C := (-HalfWidth - 12) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth + 12) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;

procedure TPSWeapon05Treton.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;

function TPSWeapon05Treton.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;

function TPSWeapon05Treton.AddParticle: PTretonParticle;
var
  Particle: PTretonParticle;
begin
  Particle := AllocEC(SizeOf(TTretonParticle));
  if LastParticle <> nil then
    LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then
    FirstParticle := Particle;
  Result := Particle;
end;

procedure TPSWeapon05Treton.ClearParticles;
var
  Particle, Current: PTretonParticle;
begin
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    Current := Particle;
    Particle := Particle.Next;
    FreeEC(Current);
  end;
  FirstParticle := nil;
  LastParticle := nil;
end;

procedure TPSWeapon05Treton.Invalidate;
begin
end;

procedure TPSWeapon05Treton.InvalidateRect(Rect: TRect);
var
  Target: TPoint;
  Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(
      HitTestBounds,
      Parent.ToAbsolutePoint(LocalPosition),
      Parent.ToAbsolutePoint(TargetPoint)
  );
  Target := Parent.ToAbsolutePoint(TargetPoint);
  Rect.Left := Target.X - 24;
  Rect.Right := Target.X + 24;
  Rect.Top := Target.Y - 24;
  Rect.Bottom := Target.Y + 24;
  if IntersectRects(Intersection, Rect, GameScreenRect) then
    MessageLoop.QueueUpdateRect(Intersection);
end;

procedure TPSWeapon05Treton.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Y, I: Integer;
  Distance: Single;
  Particle, Current: PTretonParticle;
  DelayScale: Single;
begin
  if (FirstParticle = nil) and (RemainingTicks = 60) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then
      OriginalLength := 1;
    LengthScale := 1;
    if Distance > 300.0 then
      DelayScale := 20.0
    else
      DelayScale := 20.0 * Distance / 300.0;
    while Y < Distance do
    begin
      for I := -HalfWidth to HalfWidth do
      begin
        Particle := AddParticle;
        Particle.Position := MakePointF(I, Y + 2 - I);
        Particle.Color := PrimaryColor;
        Particle.MaximumAlpha := 255 - (212 * Abs(I)) div HalfWidth;
        if Y < 64 then
          Particle.Alpha := (Particle.MaximumAlpha * Trunc(Y)) shr 6
        else
          Particle.Alpha := Particle.MaximumAlpha;
        Particle.Velocity := MakePointF(0, -2);
        Particle.State := 0;
        Particle.Countdown := Trunc(Particle.Position.Y / Distance * DelayScale);
      end;
      for I := 0 to 7 do
      begin
        Particle := AddParticle;
        Particle.Position := MakePointF(0, Y + I);
        Particle.Color := SecondaryColor;
        Particle.MaximumAlpha := 255 - Trunc(Sin(I / 8.0 * Pi) * 192.0);
        if Y < 64 then
          Particle.Alpha := (Particle.MaximumAlpha * Trunc(Y)) shr 6
        else
          Particle.Alpha := Particle.MaximumAlpha;
        Particle.Velocity := MakePointF(0, -2);
        Particle.State := 0;
        Particle.Countdown := Trunc(Particle.Position.Y / Distance * DelayScale);
      end;
      Inc(Y, 12);
    end;
  end
  else
  begin
    Distance := OriginalLength;
    LengthScale :=
        Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y))
            / OriginalLength;
    UpdateHitTestBounds;
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
        0:
          if Current.Countdown = 0 then
          begin
            Current.Countdown := RemainingTicks + 21 - 60;
            if Current.Position.Y < 64.0 then
              Current.Alpha := (Current.MaximumAlpha * Trunc(Current.Position.Y)) shr 6
            else
              Current.Alpha := Current.MaximumAlpha;
            Current.State := 2;
          end
          else
            Dec(Current.Countdown);
        1:
        begin
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          if Current.Position.Y > Distance then
            Current.Position.Y := Current.Position.Y - Distance;
          if Current.Position.Y < 0 then
            Current.Position.Y := Current.Position.Y + Distance;
          if Current.Position.Y < 64.0 then
            Current.Alpha := (Current.MaximumAlpha * Trunc(Current.Position.Y)) shr 6
          else
            Current.Alpha := Current.MaximumAlpha;
        end;
        2:
          if Current.Countdown = 0 then
            Current.State := 1
          else
            Dec(Current.Countdown);
      end;
    end;
  end;
  Dec(RemainingTicks);
end;

procedure TPSWeapon05Treton.Draw(ClipRect: TRect);
var
  Angle, Sine, Cosine, PX, PY: Single;
  X, Y: Integer;
  Particle: PTretonParticle;
begin
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then
    Y := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  if HardwareRenderingEnabled then
  begin
    while Particle <> nil do
    begin
      if Particle.State >= 1 then
      begin
        PX := Particle.Position.X;
        PY := -Particle.Position.Y * LengthScale;
        X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
        Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
        QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      end;
      Particle := Particle.Next;
    end;
    FlushDrawPoints(@ClipRect);
  end
  else
  begin
    while Particle <> nil do
    begin
      if Particle.State >= 1 then
      begin
        PX := Particle.Position.X;
        PY := -Particle.Position.Y * LengthScale;
        X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
        Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
        if (X >= ClipRect.Left)
            and (X < ClipRect.Right)
            and (Y >= ClipRect.Top)
            and (Y < ClipRect.Bottom) then
          ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      end;
      Particle := Particle.Next;
    end;
  end;
end;

procedure LoadTretonPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.4.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(TretonPalettes, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      for ColorIndex := 0 to 1 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex));
          TretonPalettes[Index][ColorIndex] :=
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
