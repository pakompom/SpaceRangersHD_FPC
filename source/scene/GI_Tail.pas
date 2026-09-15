{$EXCESSPRECISION OFF}
unit GI_Tail;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_CacheGAI,
  EC_Struct,
  GI_MessageLoop,
  SE_Process,
  Types;
type
  TTailGI = class;
  PointerToTTailSegmentGI = ^TTailSegmentGI;
  TTailSegmentGI = record
    Active: Boolean;
    Gap1: array[0..2] of Byte;
    FrameIndex: Integer;
    Position: TPointF;
    Velocity: TPointF;
    PixelPosition: TPoint;
  end;
  PTailSegmentGI = PointerToTTailSegmentGI;
  TTailGI = class(TObjectGI)
    ImageCache: TCGaiControlEC;
    FrameCount: Integer;
    SegmentCapacity: Integer;
    Segments: array of TTailSegmentGI;
    ImageSize: TPoint;
    LastSegmentIndex: Integer;
    EmitterPosition: TPointF;
    SegmentVelocity: TPointF;
    FrameTimer: PCallbackTimerGI;
    MoveTimer: PCallbackTimerGI;
    EmitTimer: PCallbackTimerGI;
    EmitIntervalMs: PtrInt;
    Emitting: Boolean;
    Gap15D: array[0..2] of Byte;
    procedure SetActive(Enabled: Boolean); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure DrawUpdateRects(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure ClearSegments;
    procedure SetImagePath(const ImagePath: WideString);
    function GetImagePath: WideString;
    function AllocateSegment: PTailSegmentGI;
    procedure AdvanceSegmentFrames(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure MoveSegments(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure EmitSegment(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure OffsetSegments(Delta: TPointF);
    procedure SetEmitting(Enabled: Boolean);
    procedure LoadTailProperties(Block: TBlockParEC);
  end;
implementation
uses
  GlobalsV,
  Math,
  aMyFunction,
  GR_Main,
  EC_Cache,
  GR_gi,
  GR_DX,
  GR_Rect,
  Direct3D9;

constructor TTailGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  EmitIntervalMs := 20;
  Emitting := True;
  LastSegmentIndex := -1;
end;

destructor TTailGI.Destroy;
begin
  if FrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := nil;
  end;
  if MoveTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(MoveTimer);
    MoveTimer := nil;
  end;
  if EmitTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(EmitTimer);
    EmitTimer := nil;
  end;
  ClearSegments;
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TTailGI.ClearSegments;
begin
  LastSegmentIndex := -1;
  SegmentCapacity := 0;
  Segments := nil;
end;

procedure TTailGI.SetImagePath(const ImagePath: WideString);
var
  Data: TCGaiEC;
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
    Data := nil;
    try
      Data := AcquireCachedGai(ImageCache);
      if Data.GetSequenceCount < 1 then
        RaiseWideMessage('TTailGI.SetImage.AnimCount Path=' + ImagePath);
      FrameCount := Data.GetSequenceFrameCount(0);
      ImageSize := Data.GetCanvasSize;
    finally
      if Data <> nil then
        ImageCache.Release;
    end;
  end;
end;

function TTailGI.GetImagePath: WideString;
begin
  Result := ImageCache.CacheKey;
end;

function TTailGI.AllocateSegment: PTailSegmentGI;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to SegmentCapacity - 1 do
    if not Segments[I].Active then
    begin
      Result := @Segments[I];
      LastSegmentIndex := I;
    end;
  if Result = nil then
  begin
    SetLength(Segments, SegmentCapacity + 16);
    Result := @Segments[SegmentCapacity];
    LastSegmentIndex := SegmentCapacity;
    Inc(SegmentCapacity, 16);
  end;
  Result.Active := True;
end;

procedure TTailGI.AdvanceSegmentFrames(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Segment: PTailSegmentGI;
  I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Inc(Segment.FrameIndex);
      // The neutral additions preserve native operand materialization order.
      if Segment.FrameIndex + 0 >= FrameCount then
      begin
        Segment.Active := False;
        if I + 0 = LastSegmentIndex then
          LastSegmentIndex := -1;
      end;
    end;
  end;
end;

procedure TTailGI.MoveSegments(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Segment: PTailSegmentGI;
  I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Segment.Position.X := Segment.Position.X + Segment.Velocity.X;
      Segment.Position.Y := Segment.Position.Y + Segment.Velocity.Y;
      Segment.PixelPosition.X := Round(Segment.Position.X);
      Segment.PixelPosition.Y := Round(Segment.Position.Y);
    end;
  end;
end;

procedure TTailGI.EmitSegment(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Segment: PTailSegmentGI;
  Position: TPointF;
begin
  Position.X := SegmentVelocity.X * 1.0 + EmitterPosition.X;
  Position.Y := SegmentVelocity.Y * 1.0 + EmitterPosition.Y;
  if LastSegmentIndex >= 0 then
    if PointDistanceSquared(Position, Segments[LastSegmentIndex].Position) < 0.001 then
      Exit;
  Segment := AllocateSegment;
  Segment.FrameIndex := 0;
  Segment.Position := Position;
  Segment.Velocity := SegmentVelocity;
  Segment.PixelPosition.X := Round(Segment.Position.X);
  Segment.PixelPosition.Y := Round(Segment.Position.Y);
end;

procedure TTailGI.OffsetSegments(Delta: TPointF);
var
  Segment: PTailSegmentGI;
  I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Segment.Position.X := Segment.Position.X + Delta.X;
      Segment.Position.Y := Segment.Position.Y + Delta.Y;
      Segment.PixelPosition.X := Round(Segment.Position.X);
      Segment.PixelPosition.Y := Round(Segment.Position.Y);
    end;
  end;
end;

procedure TTailGI.SetActive(Enabled: Boolean);
begin
  if Active <> Enabled then
  begin
    inherited SetActive(Enabled);
    if not Active then
    begin
      if FrameTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(FrameTimer);
        FrameTimer := nil;
      end;
      if MoveTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(MoveTimer);
        MoveTimer := nil;
      end;
      if EmitTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := nil;
      end;
    end;
  end;
end;

procedure TTailGI.SetEmitting(Enabled: Boolean);
begin
  if Emitting <> Enabled then
  begin
    Emitting := Enabled;
    if not Emitting then
    begin
      if EmitTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := nil;
      end;
    end
    else
    begin
      if FrameTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(FrameTimer);
        FrameTimer := nil;
      end;
      if MoveTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(MoveTimer);
        MoveTimer := nil;
      end;
      if EmitTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := nil;
      end;
      FrameTimer := MessageLoop.ScheduleCallbackTimer(20, 20, AdvanceSegmentFrames);
      MoveTimer := MessageLoop.ScheduleCallbackTimer(20, 20, MoveSegments);
      EmitTimer := MessageLoop.ScheduleCallbackTimer(EmitIntervalMs, EmitIntervalMs, EmitSegment);
    end;
  end;
end;

procedure TTailGI.Invalidate;
var
  Segment: PTailSegmentGI;
  I: Integer;
  Bounds: TRect;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
      Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
      Bounds.Right := Bounds.Left + ImageSize.X;
      Bounds.Bottom := Bounds.Top + ImageSize.Y;
      MessageLoop.QueueUpdateRect(Bounds);
    end;
  end;
end;

procedure TTailGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadTailProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TTailGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadTailProperties(Block);
end;

procedure TTailGI.LoadTailProperties(Block: TBlockParEC);
begin
end;

procedure TTailGI.UpdateAutoGeometry;
begin
end;

procedure TTailGI.Draw(ClipRect: TRect);
var
  Data: TCGaiEC;
  Segment: PTailSegmentGI;
  I: Integer;
  Gi: TgiGR;
  Origin: TPoint;
  Bounds, Intersection: TRect;
begin
  if Emitting then
    if FrameTimer = nil then
    begin
      Emitting := False;
      SetEmitting(True);
    end;
  Data := nil;
  try
    Data := AcquireCachedGai(ImageCache);
    for I := 0 to SegmentCapacity - 1 do
    begin
      Segment := @Segments[I];
      if Segment.Active then
      begin
        Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
        Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
        Bounds.Right := ImageSize.X + Bounds.Left;
        Bounds.Bottom := ImageSize.Y + Bounds.Top;
        if IntersectRects(Intersection, Bounds, ClipRect) then
        begin
          if HardwareRenderingEnabled then
          begin
            Origin := Data.GetFrameOrigin(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
            DrawTexture(
                Data.GetOrCreateFrameSurface(Data.GetSequenceFrameIndex(0, Segment.FrameIndex)),
                Origin.X + Bounds.Left,
                Origin.Y + Bounds.Top,
                255,
                $FFFFFF,
                @ClipRect,
                False,
                False
            );
          end
          else
          begin
            Gi := Data.LoadFrameGi(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
            Gi.DrawToGraphBuf(
                ScreenRenderBuffer,
                Gi.GetBoundsRect.Left + Bounds.Left - Data.GetBoundsRect.Left,
                Gi.GetBoundsRect.Top + Bounds.Top - Data.GetBoundsRect.Top,
                ClipRect,
                0,
                255
            );
          end;
        end;
      end;
    end;
  finally
    if Data <> nil then
      ImageCache.Release;
  end;
end;

procedure TTailGI.DrawUpdateRects(ClipRect: TRect);
var
  Data: TCGaiEC;
  Segment: PTailSegmentGI;
  I: Integer;
  Gi: TgiGR;
  RectNode: TRectGR;
  Origin: TPoint;
  Bounds, Intersection: TRect;
begin
  if Emitting then
    if FrameTimer = nil then
    begin
      Emitting := False;
      SetEmitting(True);
    end;
  Data := nil;
  try
    Data := AcquireCachedGai(ImageCache);
    for I := 0 to SegmentCapacity - 1 do
    begin
      Segment := @Segments[I];
      if Segment.Active then
      begin
        Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
        Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
        Bounds.Right := ImageSize.X + Bounds.Left;
        Bounds.Bottom := ImageSize.Y + Bounds.Top;
        RectNode := MessageLoop.UpdateRects.FirstRect;
        while RectNode <> nil do
        begin
          if IntersectRects(Intersection, RectNode.Bounds, Bounds) then
          begin
            if HardwareRenderingEnabled then
            begin
              Origin := Data.GetFrameOrigin(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
              DrawTexture(
                  Data.GetOrCreateFrameSurface(Data.GetSequenceFrameIndex(0, Segment.FrameIndex)),
                  Origin.X + Bounds.Left,
                  Origin.Y + Bounds.Top,
                  255,
                  $FFFFFF,
                  @Intersection,
                  False,
                  False
              );
            end
            else
            begin
              Gi := Data.LoadFrameGi(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
              Gi.DrawToGraphBuf(
                  ScreenRenderBuffer,
                  Gi.GetBoundsRect.Left + Bounds.Left - Data.GetBoundsRect.Left,
                  Gi.GetBoundsRect.Top + Bounds.Top - Data.GetBoundsRect.Top,
                  Intersection,
                  0,
                  255
              );
            end;
          end;
          RectNode := RectNode.Next;
        end;
      end;
    end;
  finally
    if Data <> nil then
      ImageCache.Release;
  end;
end;

end.
