{$EXCESSPRECISION OFF}
unit GI_PSWeapon12Turbogravir;
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
  PointerToTTurbogravirParticle = ^TTurbogravirParticle;
  PTurbogravirParticle = PointerToTTurbogravirParticle;
  TTurbogravirParticle = record
    Prev: PTurbogravirParticle;
    Next: PTurbogravirParticle;
    Position: TPoint;
    FloatPosition: TPointF;
    Color: Word;
    Alpha: Byte;
    Gap1B: array[0..0] of Byte;
    Velocity: TPoint;
    FloatVelocity: TPointF;
    State: Byte;
    Gap2D: array[0..0] of Byte;
    Unknown2E: Word;
    Radius: Integer;
  end;
  TTurbogravirPalette = array[0..8] of Single;
var
  TurbogravirPrimaryPalettes: array of TTurbogravirPalette;
  TurbogravirSecondaryPalettes: array of TTurbogravirPalette;
type
  TPSBlueWhirlGI = class;
  TPSWeapon12Turbogravir = class;
  TPSWeapon12Turbogravir = class(TPSWeaponGI)
    OffsetTable: array[0..63] of Integer;
    AlphaTable: array[0..63] of Byte;
    HalfWidth: Integer;
    Wavelength: Integer;
    HalfWavelength: Integer;
    EnabledStrands: Integer;
    PhaseMask: Integer;
    FirstParticle: PTurbogravirParticle;
    LastParticle: PTurbogravirParticle;
    ProjectionBounds: TRect;
    Gap29C: array[0..3] of Byte;
    LengthScale: Double;
    OriginalLength: Double;
    PaletteIndex: Integer;
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
    procedure BuildWaveTables;
    procedure UpdateProjectionBounds;
    function AddParticle: PTurbogravirParticle;
    procedure ClearParticles;
  end;
  TPSBlueWhirlGI = class(TPSWeapon12Turbogravir)
    constructor Create(Owner: TObjectGI);
  end;
procedure LoadTurbogravirPalettes;
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
// @unit-initialization $87793C
// @unit-finalization $694EFC

constructor TPSWeapon12Turbogravir.Create(Owner: TObjectGI; APaletteIndex: Integer);
begin
  inherited Create(Owner);
  HalfWidth := 3;
  Wavelength := 64;
  HalfWavelength := Wavelength shr 1;
  OriginalLength := 1;
  LengthScale := 1;
  PhaseMask := Wavelength - 1;
  BuildWaveTables;
  UpdateProjectionBounds;
  EnabledStrands := 3;
  PaletteIndex := APaletteIndex;
end;

destructor TPSWeapon12Turbogravir.Destroy;
begin
  ClearParticles;
  inherited Destroy;
end;

procedure TPSWeapon12Turbogravir.BuildWaveTables;
var
  I: Integer;
  Angle: Single;
begin
  for I := 0 to PhaseMask do
  begin
    Angle := I / Wavelength * 2.0 * Pi;
    OffsetTable[I] := Trunc(Sin(Angle) * HalfWidth);
    AlphaTable[I] := Trunc((Cos(Angle) + 1.5) * 100.0);
  end;
end;

procedure TPSWeapon12Turbogravir.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
  begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon12Turbogravir.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
  begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;

procedure TPSWeapon12Turbogravir.UpdateProjectionBounds;
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

procedure TPSWeapon12Turbogravir.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;

function TPSWeapon12Turbogravir.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;

function TPSWeapon12Turbogravir.AddParticle: PTurbogravirParticle;
var
  Particle: PTurbogravirParticle;
begin
  Particle := AllocEC(SizeOf(TTurbogravirParticle));
  if LastParticle <> nil then
    LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then
    FirstParticle := Particle;
  Result := Particle;
end;

procedure TPSWeapon12Turbogravir.ClearParticles;
var
  Particle, Current: PTurbogravirParticle;
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

procedure TPSWeapon12Turbogravir.Invalidate;
begin
end;

procedure TPSWeapon12Turbogravir.InvalidateRect(Rect: TRect);
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

procedure TPSWeapon12Turbogravir.Advance(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  I, Distance: Integer;
  Current, Particle: PTurbogravirParticle;
  X: Integer;
begin
  if (FirstParticle = nil) and (RemainingTicks > 24) then
  begin
    I := 0;
    Distance :=
        Trunc(Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)));
    OriginalLength := Distance;
    if OriginalLength = 0 then
      OriginalLength := 1;
    LengthScale := 1;
    while I < Distance do
    begin
      if (I shr 4) mod 2 = 0 then
      begin
        if EnabledStrands and 1 <> 0 then
        begin
          X := OffsetTable[I and PhaseMask];
          Particle := AddParticle;
          Particle.Position.X := X;
          Particle.Position.Y := I;
          Particle.Color :=
              SampleGradientColor(TurbogravirPrimaryPalettes[PaletteIndex], I / Distance * 5.0);
          if I < 64 then
            Particle.Alpha := (I * AlphaTable[I and PhaseMask]) shr 6;
          Particle.Velocity.X := 0;
          Particle.Velocity.Y := 2;
          Particle.State := 1;
          Particle.Unknown2E := 30000;
          Particle := AddParticle;
          Particle.Position.X := X;
          Particle.Position.Y := I + 1;
          Particle.Color :=
              SampleGradientColor(TurbogravirPrimaryPalettes[PaletteIndex], I / Distance * 5.0);
          if I < 64 then
            Particle.Alpha := (I * AlphaTable[I and PhaseMask]) shr 6;
          Particle.Velocity.X := 0;
          Particle.Velocity.Y := 2;
          Particle.State := 1;
          Particle.Unknown2E := 30000;
        end;
        if EnabledStrands and 2 <> 0 then
        begin
          X := OffsetTable[(I + HalfWavelength) and PhaseMask];
          Particle := AddParticle;
          Particle.Position.X := X;
          Particle.Position.Y := I;
          Particle.Color :=
              SampleGradientColor(TurbogravirSecondaryPalettes[PaletteIndex], I / Distance * 5.0);
          Particle.Alpha := AlphaTable[(I + HalfWavelength) and PhaseMask];
          if I < 64 then
            Particle.Alpha := (I * AlphaTable[(I + HalfWavelength) and PhaseMask]) shr 6;
          Particle.Velocity.X := 0;
          Particle.Velocity.Y := 2;
          Particle.State := 2;
          Particle.Unknown2E := 30000;
          Particle := AddParticle;
          Particle.Position.X := X;
          Particle.Position.Y := I + 1;
          Particle.Color :=
              SampleGradientColor(TurbogravirSecondaryPalettes[PaletteIndex], I / Distance * 5.0);
          Particle.Alpha := AlphaTable[(I + HalfWavelength) and PhaseMask];
          if I < 64 then
            Particle.Alpha := (I * AlphaTable[(I + HalfWavelength) and PhaseMask]) shr 6;
          Particle.Velocity.X := 0;
          Particle.Velocity.Y := 2;
          Particle.State := 2;
          Particle.Unknown2E := 30000;
        end;
      end;
      Inc(I, 2);
    end;
  end
  else
  begin
    Distance := Round(OriginalLength);
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
          Inc(Current.Position.Y, Current.Velocity.Y);
          if Current.Position.Y > Distance then
          begin
            Dec(Current.Position.Y, Distance);
            Current.Alpha := 0;
          end;
          Current.Position.X := OffsetTable[Current.Position.Y and PhaseMask];
          if Current.Position.Y < 64 then
            Current.Alpha :=
                (Current.Position.Y * AlphaTable[Current.Position.Y and PhaseMask]) shr 6
          else
            Current.Alpha := AlphaTable[Current.Position.Y and PhaseMask];
        end;
        2:
        begin
          Inc(Current.Position.Y, Current.Velocity.Y);
          if Current.Position.Y > Distance then
          begin
            Dec(Current.Position.Y, Distance);
            Current.Alpha := 0;
          end;
          Current.Position.X := OffsetTable[(Current.Position.Y + HalfWavelength) and PhaseMask];
          if Current.Position.Y < 64 then
            Current.Alpha :=
                (Current.Position.Y
                        * AlphaTable[(Current.Position.Y + HalfWavelength) and PhaseMask])
                    shr 6
          else
            Current.Alpha := AlphaTable[(Current.Position.Y + HalfWavelength) and PhaseMask];
        end;
        3:
        begin
          Inc(Current.Position.Y, Current.Velocity.Y);
          I := OffsetTable[(Current.Position.Y + HalfWavelength) and PhaseMask];
          if I < 0 then
            Current.Position.X := -((Current.Radius * -I) shr 5)
          else
            Current.Position.X := (Current.Radius * I) shr 5;
          if Current.Alpha > 1 then
            Dec(Current.Alpha);
          Inc(Current.Radius, 2);
          if Current.Radius > 63 then
            Current.State := 255;
        end;
        4:
        begin
          Inc(Current.Position.Y, Current.Velocity.Y);
          I := OffsetTable[Current.Position.Y and PhaseMask];
          if I < 0 then
            Current.Position.X := -((Current.Radius * -I) shr 5)
          else
            Current.Position.X := (Current.Radius * I) shr 5;
          if Current.Alpha > 1 then
            Dec(Current.Alpha);
          Inc(Current.Radius, 2);
          if Current.Radius > 63 then
            Current.State := 255;
        end;
        5:
        begin
          Current.FloatPosition.Y := Current.FloatPosition.Y + Current.FloatVelocity.Y;
          Current.FloatPosition.X := Current.FloatPosition.X + Current.FloatVelocity.X;
          Current.Position.X := Trunc(Current.FloatPosition.X);
          Current.Position.Y := Trunc(Current.FloatPosition.Y);
          Current.FloatVelocity.Y := 0.95 * Current.FloatVelocity.Y;
          Current.FloatVelocity.X := 0.95 * Current.FloatVelocity.X;
          if Current.Alpha < 246 then
            Inc(Current.Alpha, 16);
          if Current.Alpha > 245 then
            Current.State := 6;
        end;
        6:
        begin
          Current.FloatPosition.Y := Current.FloatPosition.Y + Current.FloatVelocity.Y;
          Current.FloatPosition.X := Current.FloatPosition.X + Current.FloatVelocity.X;
          Current.Position.X := Trunc(Current.FloatPosition.X);
          Current.Position.Y := Trunc(Current.FloatPosition.Y);
          Current.FloatVelocity.Y := 0.95 * Current.FloatVelocity.Y;
          Current.FloatVelocity.X := 0.95 * Current.FloatVelocity.X;
          if Current.Alpha > 25 then
            Dec(Current.Alpha, 20);
          if Current.Alpha < 26 then
            Current.State := 255;
        end;
      end;
    end;
  end;
  Dec(RemainingTicks);
end;

procedure TPSWeapon12Turbogravir.Draw(ClipRect: TRect);
var
  Angle, Sine, Cosine, PX, PY: Double;
  X, Y: Integer;
  Particle: PTurbogravirParticle;
begin
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then
    Inc(Y);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  if HardwareRenderingEnabled then
  begin
    while Particle <> nil do
    begin
      if Particle.State <> 255 then
      begin
        PX := Particle.Position.X * LengthScale;
        PY := -Particle.Position.Y * LengthScale;
        X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
        Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
        QueueDrawPoint(X, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
        QueueDrawPoint(X - 1, Y, Color565ToArgb(Particle.Color), Particle.Alpha);
      end;
      Particle := Particle.Next;
    end;
    FlushDrawPoints(nil);
  end
  else
  begin
    while Particle <> nil do
    begin
      if Particle.State <> 255 then
      begin
        PX := Particle.Position.X * LengthScale;
        PY := -Particle.Position.Y * LengthScale;
        X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
        Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
        if (X >= ClipRect.Left)
            and (X < ClipRect.Right)
            and (Y >= ClipRect.Top)
            and (Y < ClipRect.Bottom) then
          ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
        Dec(X);
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

constructor TPSBlueWhirlGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner, 0);
  EnabledStrands := 1;
end;

procedure LoadTurbogravirPalettes;
var
  Block, PaletteBlock: TBlockParEC;
  Index, ColorIndex, PartIndex, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.11.Palettes');
  ColorIndex := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to ColorIndex - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(TurbogravirPrimaryPalettes, Count);
  SetLength(TurbogravirSecondaryPalettes, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      for ColorIndex := 0 to 2 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex));
          for PartIndex := 0 to 2 do
            TurbogravirPrimaryPalettes[Index][3 * ColorIndex + PartIndex] :=
                ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, PartIndex, ','));
        end;
      for ColorIndex := 0 to 2 do
        if PaletteBlock.CountParams('Color' + IntToStr(ColorIndex + 3)) > 0 then
        begin
          Text := PaletteBlock.GetParam('Color' + IntToStr(ColorIndex + 3));
          for PartIndex := 0 to 2 do
            TurbogravirSecondaryPalettes[Index][3 * ColorIndex + PartIndex] :=
                ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, PartIndex, ','));
        end;
    end;
  end;
end;

end.
