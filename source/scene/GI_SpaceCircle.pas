{$EXCESSPRECISION OFF}
unit GI_SpaceCircle;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  EC_Struct,
  EC_BlockPar,
  Types;
type
  TSpaceCircleGI = class;
  PointerToTSpaceCircleSavedLineGI = ^TSpaceCircleSavedLineGI;
  PointerToTSpaceCircleSegmentGI = ^TSpaceCircleSegmentGI;
  TSpaceCircleSegmentGI = record
    First: TPointF;
    Last: TPointF;
    ClipResult: Integer;
    PixelFirst: TPoint;
    PixelLast: TPoint;
  end;
  PSpaceCircleSegmentGI = PointerToTSpaceCircleSegmentGI;
  TSpaceCircleSavedLineGI = record
    First: TPoint;
    Last: TPoint;
  end;
  PSpaceCircleSavedLineGI = PointerToTSpaceCircleSavedLineGI;
  TSpaceCircleGI = class(TObjectGI)
    SegmentCount: Integer;
    Segments: PSpaceCircleSegmentGI;
    PreviousLineCount: Integer;
    PreviousLines: PSpaceCircleSavedLineGI;
    Center: TPoint;
    Radius: Integer;
    Color: Cardinal;
    GeometryDirty: Boolean;
    Gap141: array[0..2] of Byte;
    DrawnSegmentCount: Integer;
    DeactivateAfterFrame: Boolean;
    Gap149: array[0..2] of Byte;
    AnimationTimer: PCallbackTimerGI;
    SavedPixels: Pointer;
    procedure SetActive(Enabled: Boolean); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure DrawUpdateRects(ClipRect: TRect); override;
    procedure CommitFrameDraw; override;
    procedure ErasePreviousFrame; override;
    procedure PrepareFrameDraw; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetRadius(Value: Integer);
    procedure SetCenter(Value: TPoint);
    procedure ClearSegments;
    procedure ClearPreviousLines;
    procedure RebuildSegments;
    procedure ProjectAndClipSegments;
    procedure RotateSegments(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure LoadSpaceCircleProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  EC_Mem,
  GR_Main,
  GR_GraphBuf,
  GR_DX,
  GlobalsV,
  Classes;

constructor TSpaceCircleGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  Radius := 100;
end;

destructor TSpaceCircleGI.Destroy;
begin
  ClearSegments;
  ClearPreviousLines;
  if SavedPixels <> nil then
  begin
    FreeEC(SavedPixels);
    SavedPixels := nil;
  end;
  inherited Destroy;
end;

procedure TSpaceCircleGI.SetRadius(Value: Integer);
begin
  if Radius <> Value then
  begin
    Radius := Value;
    if Active then
    begin
      RebuildSegments;
      GeometryDirty := True;
    end;
  end;
end;

procedure TSpaceCircleGI.SetCenter(Value: TPoint);
begin
  if (Center.X <> Value.X) or (Center.Y <> Value.Y) then
  begin
    Center := Value;
    if Active then
    begin
      RebuildSegments;
      GeometryDirty := True;
    end;
  end;
end;

procedure TSpaceCircleGI.ClearSegments;
begin
  if Segments <> nil then
  begin
    FreeEC(Segments);
    Segments := nil;
  end;
  SegmentCount := 0;
end;

procedure TSpaceCircleGI.ClearPreviousLines;
begin
  if PreviousLines <> nil then
  begin
    FreeEC(PreviousLines);
    PreviousLines := nil;
  end;
  PreviousLineCount := 0;
end;

procedure TSpaceCircleGI.RebuildSegments;
var
  Spacing, Circumference, Angle, Step, Length: Single;
  I, Count: Integer;
  Segment: PSpaceCircleSegmentGI;
  Point, Delta: TPointF;
begin
  ClearSegments;
  if Radius > 0 then
  begin
    Spacing := 20;
    Circumference := Radius * (2 * 3.1415926);
    Count := Round(Circumference / Spacing);
    if Count < 10 then
      Count := 10;
    Segments := AllocEC(Count * SizeOf(TSpaceCircleSegmentGI));
    Angle := 0;
    Step := (2 * 3.1415926) / Count;
    Point := MakePointF(Sin(Angle) * Radius, Cos(Angle) * (-Radius));
    Segment := Segments;
    for I := 0 to Count - 1 do
    begin
      Segment.First := AddPointsF(Point, PointToPointF(Center));
      Angle := Angle + Step;
      Point := MakePointF(Sin(Angle) * Radius, Cos(Angle) * (-Radius));
      Segment.Last := AddPointsF(Point, PointToPointF(Center));
      Delta := SubtractPointsF(Segment.Last, Segment.First);
      Length := Sqrt(Delta.X * Delta.X + Delta.Y * Delta.Y);
      Delta.X := Delta.X / Length;
      Delta.Y := Delta.Y / Length;
      Segment.Last.X := Delta.X * Length * 0.75 + Segment.First.X;
      Segment.Last.Y := Delta.Y * Length * 0.75 + Segment.First.Y;
      Segment.First.X := Delta.X * Length * 0.25 + Segment.First.X;
      Segment.First.Y := Delta.Y * Length * 0.25 + Segment.First.Y;
      Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
    end;
    SegmentCount := Count;
  end;
end;

procedure TSpaceCircleGI.ProjectAndClipSegments;
var
  Segment: PSpaceCircleSegmentGI;
  I: Integer;
  Clip: TRect;
begin
  Clip.TopLeft := HitTestBounds.TopLeft;
  Clip.Right := HitTestBounds.Right - 1;
  Clip.Bottom := HitTestBounds.Bottom - 1;
  Segment := Segments;
  for I := 0 to SegmentCount - 1 do
  begin
    Segment.PixelFirst := AddPoints(RoundPointF(Segment.First), AbsolutePosition);
    Segment.PixelLast := AddPoints(RoundPointF(Segment.Last), AbsolutePosition);
    Segment.ClipResult :=
        Ex_OKGR_Line_Clip(
            Segment.PixelFirst.X,
            Segment.PixelFirst.Y,
            Segment.PixelLast.X,
            Segment.PixelLast.Y,
            Clip
        );
    Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
  end;
end;

procedure TSpaceCircleGI.RotateSegments(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Segment: PSpaceCircleSegmentGI;
  I: Integer;
  Sine, Cosine, X, Y, Angle: Single;
begin
  if Radius > 0 then
  begin
    Angle := -2 / (Radius * (2 * 3.1415926)) * 3.1415926 * 2;
    Sine := Sin(Angle);
    Cosine := Cos(Angle);
    Segment := Segments;
    for I := 0 to SegmentCount - 1 do
    begin
      X := Segment.First.X - Center.X;
      Y := Segment.First.Y - Center.Y;
      Segment.First.X := Cosine * X + Sine * Y + Center.X;
      Segment.First.Y := -Sine * X + Cosine * Y + Center.Y;
      X := Segment.Last.X - Center.X;
      Y := Segment.Last.Y - Center.Y;
      Segment.Last.X := Cosine * X + Sine * Y + Center.X;
      Segment.Last.Y := -Sine * X + Cosine * Y + Center.Y;
      Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
    end;
    GeometryDirty := True;
  end;
end;

procedure TSpaceCircleGI.SetActive(Enabled: Boolean);
begin
  if Active <> Enabled then
    if Enabled then
    begin
      inherited SetActive(Enabled);
      RebuildSegments;
      GeometryDirty := True;
    end
    else
    begin
      if AnimationTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(AnimationTimer);
        AnimationTimer := nil;
      end;
      DeactivateAfterFrame := True;
      ClearSegments;
    end;
end;

procedure TSpaceCircleGI.OnActivate;
begin
  inherited OnActivate;
  if Active then
  begin
    RebuildSegments;
    GeometryDirty := True;
  end;
end;

procedure TSpaceCircleGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  ClearSegments;
  ClearPreviousLines;
  if SavedPixels <> nil then
  begin
    FreeEC(SavedPixels);
    SavedPixels := nil;
  end;
end;

procedure TSpaceCircleGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadSpaceCircleProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TSpaceCircleGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadSpaceCircleProperties(Block);
end;

procedure TSpaceCircleGI.LoadSpaceCircleProperties(Block: TBlockParEC);
begin
end;

procedure TSpaceCircleGI.Invalidate;
begin
end;

procedure TSpaceCircleGI.ErasePreviousFrame;
var
  Line: PSpaceCircleSavedLineGI;
  I: Integer;
  Buffer: Pointer;
  Count: Integer;
begin
  if GeometryDirty then
  begin
    ProjectAndClipSegments;
    GeometryDirty := False;
    if AnimationTimer = nil then
      AnimationTimer := MessageLoop.ScheduleCallbackTimer(50, 50, RotateSegments);
  end;
  if (not HardwareRenderingEnabled) and (not SkipSavedPixelRestore) then
    if not BGImage then
    begin
      Line := PreviousLines;
      for I := 0 to PreviousLineCount - 1 do
      begin
        ScreenRenderBuffer.DrawLine16Clipped(Line.First, Line.Last, 0, HitTestBounds);
        Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
      end;
    end
    else
    begin
      if SavedPixels <> nil then
      begin
        Buffer := SavedPixels;
        Line := PreviousLines;
        for I := 0 to PreviousLineCount - 1 do
        begin
          Count :=
              Ex_OKGR_Line_CopyFromBuf_WORD(
                  Buffer,
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  Line.First.X,
                  Line.First.Y,
                  Line.Last.X,
                  Line.Last.Y
              );
          Buffer := AddPointerOffset(Buffer, Count * 2);
          Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
        end;
      end;
    end;
end;

procedure TSpaceCircleGI.PrepareFrameDraw;
var
  Segment: PSpaceCircleSegmentGI;
  Copied: Integer;
  Count, Capacity, I: Integer;
begin
  if not HardwareRenderingEnabled then
    if BGImage and (not DeactivateAfterFrame) then
    begin
      Count := 0;
      Capacity := 100;
      SavedPixels := ReAllocREC(SavedPixels, Capacity * 2);
      Segment := Segments;
      for I := 0 to SegmentCount - 1 do
      begin
        if Segment.ClipResult > 0 then
        begin
          Copied :=
              Ex_OKGR_Line_CopyToBuf_WORD(
                  AddPointerOffset(SavedPixels, Count * 2),
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  Segment.PixelFirst.X,
                  Segment.PixelFirst.Y,
                  Segment.PixelLast.X,
                  Segment.PixelLast.Y
              );
          Inc(Count, Copied);
          if Count + 30 > Capacity then
          begin
            Capacity := Count + 100;
            SavedPixels := ReAllocREC(SavedPixels, Capacity * 2);
          end;
        end;
        Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
      end;
    end
    else
    begin
      if SavedPixels <> nil then
      begin
        FreeEC(SavedPixels);
        SavedPixels := nil;
      end;
    end;
end;

procedure TSpaceCircleGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;

procedure TSpaceCircleGI.Draw(ClipRect: TRect);
var
  Segment: PSpaceCircleSegmentGI;
  I: Integer;
begin
  DrawnSegmentCount := 0;
  if not DeactivateAfterFrame then
  begin
    Segment := Segments;
    if HardwareRenderingEnabled then
    begin
      for I := 0 to SegmentCount - 1 do
      begin
        if Segment.ClipResult > 0 then
        begin
          DrawAntialiasedLineDX(
              Segment.PixelFirst.X,
              Segment.PixelFirst.Y,
              Segment.PixelLast.X,
              Segment.PixelLast.Y,
              Color565ToArgb(Color),
              255,
              nil
          );
          Inc(DrawnSegmentCount);
        end;
        Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
      end;
    end
    else
    begin
      for I := 0 to SegmentCount - 1 do
      begin
        if Segment.ClipResult > 0 then
        begin
          ScreenRenderBuffer.DrawLine16(Segment.PixelFirst, Segment.PixelLast, Color);
          Inc(DrawnSegmentCount);
        end;
        Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
      end;
    end;
  end;
end;

procedure TSpaceCircleGI.CommitFrameDraw;
begin
  if DeactivateAfterFrame then
  begin
    inherited SetActive(False);
    DeactivateAfterFrame := False;
  end;
end;

end.
