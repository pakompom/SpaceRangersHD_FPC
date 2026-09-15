{$EXCESSPRECISION OFF}
unit GI_StarFieldM;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_MessageLoop,
  GI_Panel,
  Types;
type
  TStarFieldMGI = class;
  PointerToTMovingStarPixel = ^TMovingStarPixel;
  PointerToTMovingStarColorTable = ^TMovingStarColorTable;
  TMovingStarPalette = array[0..31] of Word;
  TMovingStarColorTable = array[0..15] of TMovingStarPalette;
  PMovingStarColorTable = PointerToTMovingStarColorTable;
  TMovingStarPixel = record
    ByteOffset: Integer;
    PreviousByteOffset: Integer;
    Gap8: array[0..7] of Byte;
    SavedPixel: Word;
    Gap12: array[0..1] of Byte;
    Position: TPointF;
    Velocity: TPointF;
    Acceleration: TPointF;
    Direction: TPointF;
    PixelPosition: TPoint;
    PaletteIndex: Integer;
    Color: Word;
    Gap42: array[0..1] of Byte;
    ColorPosition: Single;
    ColorStep: Single;
  end;
  PMovingStarPixel = PointerToTMovingStarPixel;
  TStarFieldMGI = class(TPanelGI)
    Stars: PMovingStarPixel;
    StarCount: Integer;
    Capacity: Integer;
    FocusPoint: TPointF;
    ViewPosition: TPointF;
    TargetHeading: Single;
    CurrentHeading: Single;
    TargetFocusDistance: Single;
    CurrentFocusDistance: Single;
    MotionTicks: Integer;
    AnimationTimer: PCallbackTimerGI;
    ColorTable: PMovingStarColorTable;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure DrawUpdateRects(ClipRect: TRect); override;
    procedure CommitFrameDraw; override;
    procedure ErasePreviousFrame; override;
    procedure PrepareFrameDraw; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure ClearStars;
    procedure GrowStars;
    function AllocateStar: PMovingStarPixel;
    procedure InitializeStar(Star: PMovingStarPixel);
    procedure SeedStars;
    procedure AdvanceStars;
    procedure RedirectStars;
    procedure AnimateStars(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure SetViewPosition(Position: TPointF);
  end;
implementation
uses
  Classes,
  EC_Mem,
  aMyFunction,
  Math,
  GR_Main,
  GlobalsV,
  GR_DX;

constructor TStarFieldMGI.Create(Owner: TObjectGI);
var
  I, J: Integer;
begin
  inherited Create(Owner);
  FocusPoint := MakePointF(Cardinal(GameScreenWidth) / 2, Cardinal(GameScreenHeight) / 2);
  ColorTable := AllocEC(SizeOf(ColorTable^));
  for I := Low(ColorTable^) to High(ColorTable^) do
    for J := Low(TMovingStarPalette) to High(TMovingStarPalette) do
      WriteWordEC(
          AddPointerOffset(
              ColorTable,
              I * Length(ColorTable^[I]) * SizeOf(Word) + J * SizeOf(Word)
          ),
          CurrentPixelFormat
              .PackNormalizedRgb(Random * 0.5 + 0.5, Random * 0.5 + 0.5, Random * 0.5 + 0.5)
      );
  SeedStars;
end;

destructor TStarFieldMGI.Destroy;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  if ColorTable <> nil then
  begin
    FreeEC(ColorTable);
    ColorTable := nil;
  end;
  ClearStars;
  inherited Destroy;
end;

procedure TStarFieldMGI.OnActivate;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  AnimationTimer := MessageLoop.ScheduleCallbackTimer(50, 50, AnimateStars);
end;

procedure TStarFieldMGI.OnDeactivate;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
end;

procedure TStarFieldMGI.ClearStars;
begin
  if Stars <> nil then
  begin
    FreeEC(Stars);
    Stars := nil;
  end;
  StarCount := 0;
  Capacity := 0;
end;

procedure TStarFieldMGI.GrowStars;
var
  Tail: Pointer;
begin
  Inc(Capacity, 64);
  Stars := ReAllocREC(Stars, SizeOf(TMovingStarPixel) * Capacity);
  Tail := AddPointerOffset(Stars, SizeOf(TMovingStarPixel) * (Capacity - 64));
  FillChar(Tail^, SizeOf(TMovingStarPixel) * 64, 0);
end;

function TStarFieldMGI.AllocateStar: PMovingStarPixel;
begin
  Inc(StarCount);
  if StarCount > Capacity then
    GrowStars;
  Result := AddPointerOffset(Stars, SizeOf(TMovingStarPixel) * (StarCount - 1));
end;

procedure TStarFieldMGI.InitializeStar(Star: PMovingStarPixel);
var
  Angle, DX, DY, Speed, Factor: Single;
begin
  Star.Position.X := Random * (Cardinal(GameScreenWidth) - 1);
  Star.Position.Y := Random * (Cardinal(GameScreenHeight) - 1);
  Star.PixelPosition.X := Round(Star.Position.X);
  Star.PixelPosition.Y := Round(Star.Position.Y);
  Factor := Random;
  Angle := ArcTan2(Star.Position.X - FocusPoint.X, -(Star.Position.Y - FocusPoint.Y));
  DX := Sin(Angle);
  DY := -Cos(Angle);
  Star.Direction.X := DX;
  Star.Direction.Y := DY;
  Speed := 0.5 * Factor + 0.1;
  Star.Velocity.X := DX * Speed;
  Star.Velocity.Y := DY * Speed;
  Speed := 0.3 * Factor + 0.1;
  Star.Acceleration.X := DX * Speed;
  Star.Acceleration.Y := DY * Speed;
  Star.ColorPosition := 0;
  Star.ColorStep := 4 * Factor + 2;
  Star.PaletteIndex := 0;
  Star.Color :=
      ReadWordEC(
          AddPointerOffset(
              ColorTable,
              Star.PaletteIndex * Length(ColorTable^[0]) * SizeOf(Word)
                  + Round(Star.ColorPosition) * SizeOf(Word)
          )
      );
end;

procedure TStarFieldMGI.SeedStars;
var
  I, Count: Integer;
  Star: PMovingStarPixel;
begin
  Count := 50;
  if Cardinal(GameScreenHeight) < 768 then
    Count := Round(Count * 0.6103515625);
  for I := 0 to Count - 1 do
  begin
    Star := AllocateStar;
    InitializeStar(Star);
  end;
end;

procedure TStarFieldMGI.AdvanceStars;
var
  Star: PMovingStarPixel;
  I, X, Y: Integer;
begin
  Star := Stars;
  for I := 0 to StarCount - 1 do
  begin
    Star.Velocity.X := Star.Velocity.X + Star.Acceleration.X;
    Star.Velocity.Y := Star.Velocity.Y + Star.Acceleration.Y;
    Star.Position.X := Star.Position.X + Star.Velocity.X;
    Star.Position.Y := Star.Position.Y + Star.Velocity.Y;
    X := Round(Star.Position.X);
    Y := Round(Star.Position.Y);
    Star.PixelPosition.X := X;
    Star.PixelPosition.Y := Y;
    if (X < HitTestBounds.Left)
        or (X >= HitTestBounds.Right)
        or (Y < HitTestBounds.Top)
        or (Y >= HitTestBounds.Bottom) then
      InitializeStar(Star);
    if Star.ColorPosition < High(TMovingStarPalette) then
    begin
      Star.ColorPosition := Star.ColorPosition + Star.ColorStep;
      if Star.ColorPosition > High(TMovingStarPalette) then
      begin
        Star.ColorPosition := High(TMovingStarPalette);
        Star.ColorStep := 0;
      end;
      Star.Color :=
          ReadWordEC(
              AddPointerOffset(
                  ColorTable,
                  Star.PaletteIndex * Length(ColorTable^[0]) * SizeOf(Word)
                      + Round(Star.ColorPosition) * SizeOf(Word)
              )
          );
    end;
    Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
  end;
end;

procedure TStarFieldMGI.RedirectStars;
var
  Star: PMovingStarPixel;
  I: Integer;
  Distance, Speed, DY, DX: Single;
begin
  Star := Stars;
  for I := 0 to StarCount - 1 do
  begin
    DX := Star.Position.X - FocusPoint.X;
    DY := Star.Position.Y - FocusPoint.Y;
    Distance := Sqrt(DX * DX + DY * DY);
    DX := DX / Distance;
    DY := DY / Distance;
    Star.Direction.X := DX;
    Star.Direction.Y := DY;
    Speed := Sqrt(Star.Velocity.X * Star.Velocity.X + Star.Velocity.Y * Star.Velocity.Y);
    Star.Velocity.X := Speed * DX;
    Star.Velocity.Y := Speed * DY;
    Speed :=
        Sqrt(Star.Acceleration.X * Star.Acceleration.X + Star.Acceleration.Y * Star.Acceleration.Y);
    Star.Acceleration.X := Speed * DX;
    Star.Acceleration.Y := Speed * DY;
    Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
  end;
end;

procedure TStarFieldMGI.AnimateStars(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Delta: Single;
begin
  if StarCount > 0 then
  begin
    Dec(MotionTicks);
    if MotionTicks < 0 then
    begin
      TargetFocusDistance := 0;
      MotionTicks := 0;
    end;
    if (TargetHeading <> CurrentHeading) or (TargetFocusDistance <> CurrentFocusDistance) then
    begin
      Delta := HeadingDifferenceDegrees(CurrentHeading, TargetHeading);
      if Abs(Delta) <= 15 then
        CurrentHeading := TargetHeading
      else
      begin
        if Delta < 0 then
          CurrentHeading := WrapHeadingDegrees(CurrentHeading - 15)
        else if Delta > 0 then
          CurrentHeading := WrapHeadingDegrees(CurrentHeading + 15);
      end;
      if TargetFocusDistance < CurrentFocusDistance then
        CurrentFocusDistance := Max(TargetFocusDistance, CurrentFocusDistance - 90)
      else if TargetFocusDistance > CurrentFocusDistance then
        CurrentFocusDistance := Min(TargetFocusDistance, CurrentFocusDistance + 60);
      FocusPoint.X :=
          Sin(HeadingDegreesToRadians(CurrentHeading)) * CurrentFocusDistance
              + Cardinal(GameScreenWidth) / 2;
      FocusPoint.Y :=
          Cardinal(GameScreenHeight) / 2
              - Cos(HeadingDegreesToRadians(CurrentHeading)) * CurrentFocusDistance;
      RedirectStars;
    end;
    AdvanceStars;
    Invalidate;
  end;
end;

procedure TStarFieldMGI.SetViewPosition(Position: TPointF);
var
  DY, DX: Single;
begin
  DX := Position.X - ViewPosition.X;
  DY := Position.Y - ViewPosition.Y;
  if DY * DY + DX * DX >= 25 then
  begin
    if (DX <> 0) or (DY <> 0) then
    begin
      TargetHeading := RadiansToHeadingDegrees(ArcTan2(DX, -DY));
      if CurrentFocusDistance = 0 then
        CurrentFocusDistance := TargetFocusDistance;
      if Cardinal(GameScreenHeight) >= 768 then
        TargetFocusDistance := 1800
      else
        TargetFocusDistance := 1230;
      MotionTicks := 5;
      RedirectStars;
    end;
    ViewPosition := Position;
  end;
end;

procedure TStarFieldMGI.Invalidate;
begin
end;

procedure TStarFieldMGI.ErasePreviousFrame;
var
  Star: PMovingStarPixel;
  Buffer: Pointer;
  I: Integer;
begin
  if not HardwareRenderingEnabled then
  begin
    Buffer := ScreenRenderBuffer.GetPixels;
    if not SkipSavedPixelRestore then
    begin
      if not BGImage then
      begin
        Star := Stars;
        for I := 0 to StarCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Star.PreviousByteOffset), 0);
          Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
        end;
      end
      else
      begin
        Star := Stars;
        for I := 0 to StarCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Star.PreviousByteOffset), Star.SavedPixel);
          Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
        end;
      end;
    end;
  end;
end;

procedure TStarFieldMGI.PrepareFrameDraw;
var
  Star: PMovingStarPixel;
  I: Integer;
  Buffer: Pointer;
begin
  if not HardwareRenderingEnabled then
  begin
    Buffer := ScreenRenderBuffer.GetPixels;
    Star := Stars;
    I := StarCount;
    while I > 0 do
    begin
      Star.ByteOffset :=
          Star.PixelPosition.X * 2 + Star.PixelPosition.Y * ScreenRenderBuffer.PitchBytes;
      if BGImage then
        Star.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Star.ByteOffset));
      Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
      Dec(I);
    end;
  end;
end;

procedure TStarFieldMGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;

procedure TStarFieldMGI.Draw(ClipRect: TRect);
var
  Pixel: PMovingStarPixel;
  Count: Integer;
  Buffer: Pointer;
begin
  Pixel := Stars;
  Count := StarCount;
  if HardwareRenderingEnabled then
  begin
    while Count > 0 do
    begin
      QueueDrawPoint(
          Pixel.PixelPosition.X,
          Pixel.PixelPosition.Y,
          Color565ToArgb(Pixel.Color),
          255
      );
      Pixel := AddPointerOffset(Pixel, SizeOf(TMovingStarPixel));
      Dec(Count);
    end;
    FlushDrawPoints(nil);
  end
  else
  begin
    Buffer := ScreenRenderBuffer.GetPixels;
    while Count > 0 do
    begin
      WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), Pixel.Color);
      Pixel := AddPointerOffset(Pixel, SizeOf(TMovingStarPixel));
      Dec(Count);
    end;
  end;
end;

procedure TStarFieldMGI.CommitFrameDraw;
var
  Star: PMovingStarPixel;
  I: Integer;
begin
  if not HardwareRenderingEnabled then
  begin
    Star := Stars;
    I := StarCount;
    while I > 0 do
    begin
      Star.PreviousByteOffset := Star.ByteOffset;
      Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
      Dec(I);
    end;
  end;
end;

end.
