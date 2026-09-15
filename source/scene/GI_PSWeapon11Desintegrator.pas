{$EXCESSPRECISION OFF}
unit GI_PSWeapon11Desintegrator;
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
  PointerToTDesintegratorParticle = ^TDesintegratorParticle;
  PDesintegratorParticle = PointerToTDesintegratorParticle;
  TDesintegratorParticle = record
    Prev: PDesintegratorParticle;
    Next: PDesintegratorParticle;
    Position: TPointF;
    Color: Word;
    Alpha: Byte;
    Gap13: array[0..0] of Byte;
    Velocity: TPointF;
    State: Byte;
    Gap1D: array[0..0] of Byte;
    RemainingTicks: Word;
    BaseAlpha: Integer;
  end;
  TDesintegratorPalette = array[0..0] of Word;
var
  DesintegratorPalettes: array of TDesintegratorPalette;
type
  TPSWeapon11Desintegrator = class;
  TPSWeapon11Desintegrator = class(TPSWeaponGI)
    HalfWidth: Integer;
    Wavelength: Integer;
    PhaseMask: Integer;
    FirstParticle: PDesintegratorParticle;
    LastParticle: PDesintegratorParticle;
    PendingSparkSteps: Integer;
    Color: Word;
    ProjectionBounds: TRect;
    Gap15A: array[0..5] of Byte;
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
    procedure UpdateProjectionBounds;
    function AddParticle: PDesintegratorParticle;
    procedure RemoveParticle(Particle: PDesintegratorParticle);
    procedure ClearParticles;
    procedure AdvanceImpactSparks(ClipRect: TRect);
  end;
procedure LoadDesintegratorPalettes;
implementation
uses
  ObserverHooks,
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
// @unit-initialization $877934
// @unit-finalization $693468

constructor TPSWeapon11Desintegrator.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  HalfWidth := 4;
  Wavelength := 32;
  LengthScale := 1;
  OriginalLength := 1;
  PhaseMask := Wavelength - 1;
  UpdateProjectionBounds;
  PendingSparkSteps := 0;
  Color := DesintegratorPalettes[APaletteIndex][0];
  RemainingTicks := 50;
  LifetimeTicks := RemainingTicks;
end;

destructor TPSWeapon11Desintegrator.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon11Desintegrator.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
  begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon11Desintegrator.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
  begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon11Desintegrator.UpdateProjectionBounds;
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
  A := (-HalfWidth * 2) * Cosine - -Distance * Sine;
  B := (HalfWidth * 2) * Cosine - -Distance * Sine;
  C := (-HalfWidth * 2) * Cosine;
  D := (HalfWidth * 2) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth * 2) * Sine + -Distance * Cosine;
  B := (HalfWidth * 2) * Sine + -Distance * Cosine;
  C := (-HalfWidth * 2) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth * 2) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;

procedure TPSWeapon11Desintegrator.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X - 32;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y - 32;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X + 32;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y + 32;
end;

function TPSWeapon11Desintegrator.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;

function TPSWeapon11Desintegrator.AddParticle: PDesintegratorParticle;
var
  Particle: PDesintegratorParticle;
begin
  Particle := AllocEC(SizeOf(TDesintegratorParticle));
  if LastParticle <> nil then
    LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then
    FirstParticle := Particle;
  Result := Particle;
end;

procedure TPSWeapon11Desintegrator.RemoveParticle(Particle: PDesintegratorParticle);
begin
  if Particle <> nil then
  begin
    if Particle.Prev <> nil then
      Particle.Prev.Next := Particle.Next;
    if Particle.Next <> nil then
      Particle.Next.Prev := Particle.Prev;
    if LastParticle = Particle then
      LastParticle := Particle.Prev;
    if FirstParticle = Particle then
      FirstParticle := Particle.Next;
    FreeEC(Particle);
  end;
end;

procedure TPSWeapon11Desintegrator.ClearParticles;
var
  Particle, Current: PDesintegratorParticle;
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

procedure TPSWeapon11Desintegrator.Invalidate;
begin
end;

procedure TPSWeapon11Desintegrator.InvalidateRect(Rect: TRect);
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
  Rect.Left := Target.X - 32;
  Rect.Right := Target.X + 32;
  Rect.Top := Target.Y - 32;
  Rect.Bottom := Target.Y + 32;
  if IntersectRects(Intersection, Rect, GameScreenRect) then
    MessageLoop.QueueUpdateRect(Intersection);
end;

procedure TPSWeapon11Desintegrator.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Y, Distance, Angle: Single;
  Current, Spark, Particle: PDesintegratorParticle;
begin
  if (FirstParticle = nil) and (RemainingTicks > 18) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    // Native comparison is strictly negative, including its zero-length behavior.
    if OriginalLength < 0 then
      OriginalLength := 1;
    LengthScale := 1;
    while Y < Distance do
    begin
      Particle := AddParticle;
      Angle := Y / Wavelength * 2.0 * Pi;
      Particle.Position.X := 1;
      Particle.Position.Y := Y;
      Particle.Color := Color;
      Particle.BaseAlpha := Trunc(Sin(Angle) * 95.0 + 160.0);
      if Y < 64.0 then
        Particle.Alpha := Trunc(Particle.BaseAlpha * Y) shr 6
      else
        Particle.Alpha := Particle.BaseAlpha;
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Particle := AddParticle;
      Particle.Position.X := 0;
      Particle.Position.Y := Y;
      Particle.Color := Color;
      Particle.BaseAlpha := Trunc(Sin(Angle) * 95.0 + 160.0);
      if Y < 64.0 then
        Particle.Alpha := Trunc(Particle.BaseAlpha * Y) shr 6
      else
        Particle.Alpha := Particle.BaseAlpha;
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Y := Y + 1.0;
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
        1:
        begin
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          if Current.Position.Y > Distance then
          begin
            Spark := AddParticle;
            Spark.Position := MakePointF(0, 0);
            Spark.Color := Current.Color;
            Spark.Alpha := Current.BaseAlpha;
            Angle := PresentationRandom(12) * Pi / 6.0;
            Spark.Velocity := MakePointF(Sin(Angle) * 1.0, Cos(Angle) * 1.0);
            Spark.State := 2;
            Spark.RemainingTicks := 18;
            Current.Position.Y := Current.Position.Y - Distance;
          end;
          if Current.Position.Y < 64.0 then
            Current.Alpha := Trunc(Current.BaseAlpha * Current.Position.Y) shr 6
          else
            Current.Alpha := Current.BaseAlpha;
          if RemainingTicks < 18 then
            RemoveParticle(Current);
        end;
      end;
    end;
  end;
  Inc(PendingSparkSteps);
  Dec(RemainingTicks);
end;

procedure TPSWeapon11Desintegrator.AdvanceImpactSparks(ClipRect: TRect);
var
  TargetX, TargetY, X, Y: Integer;
  Particle, Current: PDesintegratorParticle;
  DX, DY: Double;
  Minimum, Brightness: Integer;
  Uniform: Boolean;
begin
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    Current := Particle;
    Particle := Particle.Next;
    if Current.State = 2 then
    begin
      if Current.Alpha > 96 then
        Dec(Current.Alpha, 4);
      Current.Position.X := Current.Position.X + Current.Velocity.X;
      Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
      X := Round(TargetX + Current.Position.X);
      Y := Round(TargetY + Current.Position.Y);
      DX := 0;
      DY := 0;
      Minimum := 94;
      Uniform := True;
      if HardwareRenderingEnabled then
      begin
        DX := -0.25;
        DY := 0;
      end
      else
      begin
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y);
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := -0.25;
          DY := 0;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := -0.25;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y - 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := 0;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y + 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := 0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X, Y + 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0;
          DY := 0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y + 1);
        if Brightness <> Minimum then
          Uniform := False;
        if Brightness < Minimum then
        begin
          DX := -0.25;
          DY := 0.25;
        end;
      end;
      if Uniform then
      begin
        DX := 0;
        DY := 0;
      end;
      Current.Velocity.X := Current.Velocity.X + DX;
      Current.Velocity.Y := Current.Velocity.Y + DY;
      Dec(Current.RemainingTicks);
      if Current.RemainingTicks = 0 then
        RemoveParticle(Current);
    end;
  end;
end;

procedure TPSWeapon11Desintegrator.Draw(ClipRect: TRect);
var
  PX, PY, Sine, Cosine, Angle: Single;
  TargetX, X, Y, TargetY: Integer;
  Particle: PDesintegratorParticle;
  I: Integer;
begin
  for I := 1 to PendingSparkSteps do
    AdvanceImpactSparks(ClipRect);
  PendingSparkSteps := 0;
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then
    PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  if HardwareRenderingEnabled then
  begin
    while Particle <> nil do
    begin
      if Particle.State = 2 then
      begin
        X := TargetX + Trunc(Particle.Position.X);
        Y := TargetY + Trunc(Particle.Position.Y);
      end
      else
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * LengthScale;
        X := AbsolutePosition.X + Trunc(PX * Cosine + PY * Sine);
        Y := AbsolutePosition.Y + Trunc(PX * Sine - PY * Cosine);
      end;
      QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      Particle := Particle.Next;
    end;
    FlushDrawPoints(@ClipRect);
  end
  else
  begin
    while Particle <> nil do
    begin
      if Particle.State = 2 then
      begin
        X := TargetX + Trunc(Particle.Position.X);
        Y := TargetY + Trunc(Particle.Position.Y);
      end
      else
      begin
        PX := Particle.Position.X;
        PY := Particle.Position.Y * LengthScale;
        X := AbsolutePosition.X + Trunc(PX * Cosine + PY * Sine);
        Y := AbsolutePosition.Y + Trunc(PX * Sine - PY * Cosine);
      end;
      if (X >= ClipRect.Left)
          and (X < ClipRect.Right)
          and (Y >= ClipRect.Top)
          and (Y < ClipRect.Bottom) then
        ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      Particle := Particle.Next;
    end;
  end;
end;

procedure LoadDesintegratorPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.10.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(DesintegratorPalettes, Count);
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
          DesintegratorPalettes[Index][ColorIndex] :=
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
