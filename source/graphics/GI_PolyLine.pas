{$EXCESSPRECISION OFF}
unit GI_PolyLine;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  GI_Circle,
  EC_BlockPar,
  Types,
  Windows;
type
  TPolyLineGI = class;
  PointerToTPolyLineSegmentGI = ^TPolyLineSegmentGI;
  PPolyLineSegmentGI = PointerToTPolyLineSegmentGI;
  TPolyLineSegmentGI = packed record
    Next: PPolyLineSegmentGI;
    Prev: PPolyLineSegmentGI;
    First: TPoint;
    Last: TPoint;
    UserData: Integer;
    Animated: Boolean;
    Gap1D: array[0..2] of Byte;
    PixelCount: Integer;
    PixelCapacity: Integer;
    PixelFirst: TPoint;
    PixelLast: TPoint;
    SavedPixels: Pointer;
    Visible: Boolean;
    PreviousFirst: TPoint;
    PreviousLast: TPoint;
    Gap4D: array[0..2] of Byte;
    PreviousPixels: Pointer;
    PreviouslyVisible: Boolean;
    Gap55: array[0..2] of Byte;
    ClippedColor: Cardinal;
    ClippedEndColor: Cardinal;
    Color: Cardinal;
    EndColor: Cardinal;
    Kind: Integer;
  end;
  TPolyLineGI = class(TObjectGI)
    FirstSegment: PPolyLineSegmentGI;
    LastSegment: PPolyLineSegmentGI;
    AnimationPhase: Cardinal;
    AnimationTimer: PCallbackTimerGI;
    FrameDrawing: Boolean;
    Gap131: array[0..2] of Byte;
    ShadowCircle: TCircleGI;
    AutoRebuildBounds: Boolean;
    NormalizeBounds: Boolean;
    Gap13A: array[0..1] of Byte;
    SegmentHeap: Cardinal;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure DrawUpdateRects(ClipRect: TRect); override;
    procedure CommitFrameDraw; override;
    procedure ErasePreviousFrame; override;
    procedure PrepareFrameDraw; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure DrawSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect); virtual;
    procedure DrawFrameSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect); virtual;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    function AllocateSegment: PPolyLineSegmentGI;
    procedure ClearSegments;
    procedure RemoveSegment(Segment: PPolyLineSegmentGI);
    procedure AllocatePixelBuffers(Segment: PPolyLineSegmentGI);
    procedure LoadPolyLineProperties(Block: TBlockParEC);
    procedure RebuildBounds;
    function AddParentLine(
        First: TPoint;
        Last: TPoint;
        Color: Cardinal;
        UserData: Integer
    ): PPolyLineSegmentGI;
    function AddLine(First: TPoint; Last: TPoint; Color: Cardinal): PPolyLineSegmentGI;
    function AddLocalLine(
        First: TPoint;
        Last: TPoint;
        Color: Cardinal;
        UserData: Integer
    ): PPolyLineSegmentGI;
    procedure UpdateSegmentLength(Segment: PPolyLineSegmentGI);
    procedure RetireSegment(Segment: PPolyLineSegmentGI);
    procedure StartAnimation;
    procedure StopAnimation;
    procedure AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  Math,
  EC_Mem,
  EC_Struct,
  GR_Main,
  GR_GraphBuf,
  GR_DX,
  GR_Rect,
  GlobalsV,
  Classes,
  SysUtils,
  aMyFunction;

constructor TPolyLineGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  SegmentHeap := HeapCreate(1, $8000, 0);
  if SegmentHeap = 0 then
    raise Exception.Create('TPolyLineGI.HeapCreate');
  ClientSize := Classes.Point(1, 1);
  AnimationTimer := nil;
  AnimationPhase := 0;
  FrameDrawing := False;
  ShadowCircle := nil;
  AutoRebuildBounds := True;
  NormalizeBounds := True;
  StartAnimation;
end;

destructor TPolyLineGI.Destroy;
begin
  ShadowCircle := nil;
  StopAnimation;
  Clear;
  if SegmentHeap <> 0 then
  begin
    HeapDestroy(SegmentHeap);
    SegmentHeap := 0;
  end;
  inherited Destroy;
end;

procedure TPolyLineGI.Clear;
begin
  ShadowCircle := nil;
  ClientSize := Classes.Point(1, 1);
  ClearSegments;
  inherited Clear;
end;

function TPolyLineGI.AllocateSegment: PPolyLineSegmentGI;
var
  Segment: PPolyLineSegmentGI;
begin
  Segment := AllocFromHeapEC(SegmentHeap, SizeOf(TPolyLineSegmentGI));
  Segment.Next := nil;
  Segment.Prev := LastSegment;
  Segment.SavedPixels := nil;
  Segment.PreviousPixels := nil;
  Segment.Visible := False;
  Segment.PreviouslyVisible := False;
  if LastSegment <> nil then
    LastSegment.Next := Segment;
  if FirstSegment = nil then
    FirstSegment := Segment;
  LastSegment := Segment;
  Segment.Kind := 0;
  Result := Segment;
end;

procedure TPolyLineGI.ClearSegments;
begin
  while FirstSegment <> nil do
    RemoveSegment(FirstSegment);
end;

procedure TPolyLineGI.RemoveSegment(Segment: PPolyLineSegmentGI);
begin
  if Segment.Next <> nil then
    Segment.Next.Prev := Segment.Prev;
  if Segment.Prev <> nil then
    Segment.Prev.Next := Segment.Next;
  if LastSegment = Segment then
    LastSegment := Segment.Prev;
  if FirstSegment = Segment then
    FirstSegment := Segment.Next;
  if SegmentHeap <> 0 then
  begin
    if Segment.SavedPixels <> nil then
    begin
      FreeFromHeapEC(SegmentHeap, Segment.SavedPixels);
      Segment.SavedPixels := nil;
    end;
    if Segment.PreviousPixels <> nil then
    begin
      FreeFromHeapEC(SegmentHeap, Segment.PreviousPixels);
      Segment.PreviousPixels := nil;
    end;
    FreeFromHeapEC(SegmentHeap, Segment);
  end;
end;

procedure TPolyLineGI.AllocatePixelBuffers(Segment: PPolyLineSegmentGI);
begin
  if Segment.SavedPixels = nil then
    Segment.SavedPixels := AllocFromHeapEC(SegmentHeap, Segment.PixelCount * 2 + 10);
  if Segment.PreviousPixels = nil then
    Segment.PreviousPixels := AllocFromHeapEC(SegmentHeap, Segment.PixelCount * 2 + 10);
end;

procedure TPolyLineGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadPolyLineProperties(Block);
end;

procedure TPolyLineGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadPolyLineProperties(Block);
end;

procedure TPolyLineGI.LoadPolyLineProperties(Block: TBlockParEC);
begin
end;

procedure TPolyLineGI.RebuildBounds;
var
  Segment: PPolyLineSegmentGI;
  Minimum, Size: TPoint;
begin
  if NormalizeBounds then
  begin
    Segment := FirstSegment;
    if Segment = nil then
      SetSize(Classes.Point(1, 1))
    else
    begin
      Minimum := Segment.First;
      while Segment <> nil do
      begin
        if Minimum.X > Segment.First.X then
          Minimum.X := Segment.First.X;
        if Minimum.Y > Segment.First.Y then
          Minimum.Y := Segment.First.Y;
        if Minimum.X > Segment.Last.X then
          Minimum.X := Segment.Last.X;
        if Minimum.Y > Segment.Last.Y then
          Minimum.Y := Segment.Last.Y;
        Segment := Segment.Next;
      end;
      SetPosition(Classes.Point(LocalPosition.X + Minimum.X, LocalPosition.Y + Minimum.Y));
      Size := Classes.Point(1, 1);
      Segment := FirstSegment;
      while Segment <> nil do
      begin
        Segment.First := Classes.Point(Segment.First.X - Minimum.X, Segment.First.Y - Minimum.Y);
        Segment.Last := Classes.Point(Segment.Last.X - Minimum.X, Segment.Last.Y - Minimum.Y);
        if Size.X <= Segment.First.X then
          Size.X := Segment.First.X + 1;
        if Size.Y <= Segment.First.Y then
          Size.Y := Segment.First.Y + 1;
        if Size.X <= Segment.Last.X then
          Size.X := Segment.Last.X + 1;
        if Size.Y <= Segment.Last.Y then
          Size.Y := Segment.Last.Y + 1;
        Segment := Segment.Next;
      end;
      SetSize(Size);
    end;
  end;
end;

function TPolyLineGI.AddParentLine(
    First, Last: TPoint;
    Color: Cardinal;
    UserData: Integer
): PPolyLineSegmentGI;
var
  Segment: PPolyLineSegmentGI;
begin
  Segment := AllocateSegment;
  Segment.First := Classes.Point(First.X - LocalPosition.X, First.Y - LocalPosition.Y);
  Segment.Last := Classes.Point(Last.X - LocalPosition.X, Last.Y - LocalPosition.Y);
  Segment.Color := Color;
  Segment.PixelCount := IntegerPointDistancePlusOne(First, Last);
  Segment.PixelCapacity := Segment.PixelCount;
  Segment.UserData := UserData;
  Segment.Animated := True;
  if AutoRebuildBounds then
    RebuildBounds;
  Result := Segment;
end;

function TPolyLineGI.AddLine(First, Last: TPoint; Color: Cardinal): PPolyLineSegmentGI;
begin
  Result := AddLocalLine(First, Last, Color, 0);
end;

function TPolyLineGI.AddLocalLine(
    First, Last: TPoint;
    Color: Cardinal;
    UserData: Integer
): PPolyLineSegmentGI;
var
  Segment: PPolyLineSegmentGI;
begin
  Segment := AllocateSegment;
  Segment.First := First;
  Segment.Last := Last;
  Segment.Color := Color;
  Segment.PixelCount := IntegerPointDistancePlusOne(First, Last);
  Segment.PixelCapacity := Segment.PixelCount;
  Segment.UserData := UserData;
  Segment.Animated := True;
  if AutoRebuildBounds then
    RebuildBounds;
  Result := Segment;
end;

procedure TPolyLineGI.UpdateSegmentLength(Segment: PPolyLineSegmentGI);
var
  Count: Integer;
begin
  Count := IntegerPointDistancePlusOne(Segment.First, Segment.Last);
  if Count > Segment.PixelCapacity then
  begin
    Segment.PixelCount := Count;
    Segment.PixelCapacity := Segment.PixelCount;
    Segment.SavedPixels :=
        ReAllocFromHeapREC(SegmentHeap, Segment.SavedPixels, Segment.PixelCount * 2 + 10);
    Segment.PreviousPixels :=
        ReAllocFromHeapREC(SegmentHeap, Segment.PreviousPixels, Segment.PixelCount * 2 + 10);
  end
  else
    Segment.PixelCount := Count;
end;

procedure TPolyLineGI.RetireSegment(Segment: PPolyLineSegmentGI);
var
  Buffer: Pointer;
begin
  if Segment.PreviouslyVisible and (Segment.PreviousPixels <> nil) then
  begin
    Buffer := AllocEC(Segment.PixelCount * 2 + 10);
    CopyMemory(Buffer, Segment.PreviousPixels, Segment.PixelCount * 2 + 10);
    MessageLoop.AddSavedLine(Segment.PreviousFirst, Segment.PreviousLast, Buffer);
  end;
  RemoveSegment(Segment);
end;

procedure TPolyLineGI.StartAnimation;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  AnimationTimer := MessageLoop.ScheduleCallbackTimer(100, 100, AdvanceAnimation);
end;

procedure TPolyLineGI.StopAnimation;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
end;

procedure TPolyLineGI.AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  Inc(AnimationPhase, 30);
  if AnimationPhase >= 360 then
    Dec(AnimationPhase, 360);
  Invalidate;
end;

procedure TPolyLineGI.Invalidate;
begin
  if not FrameDrawing then
  begin
    inherited Invalidate;
    Exit;
  end;
  if ShadowCircle = nil then
  begin
    MessageLoop.UpdateRects.Clear;
    MessageLoop.UpdateRectsEnabled := True;
    MessageLoop.InvalidateViewport;
    MessageLoop.UpdateRectsEnabled := False;
  end;
end;

procedure TPolyLineGI.ErasePreviousFrame;
var
  Segment: PPolyLineSegmentGI;
begin
  FrameDrawing := True;
  if not SkipSavedPixelRestore then
  begin
    Segment := FirstSegment;
    while Segment <> nil do
    begin
      AllocatePixelBuffers(Segment);
      if Segment.PreviouslyVisible then
        Ex_OKGR_Line_CopyFromBuf_WORD(
            Segment.PreviousPixels,
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            Segment.PreviousFirst.X,
            Segment.PreviousFirst.Y,
            Segment.PreviousLast.X,
            Segment.PreviousLast.Y
        );
      Segment := Segment.Next;
    end;
  end;
end;

procedure TPolyLineGI.PrepareFrameDraw;
var
  Segment: PPolyLineSegmentGI;
  Clip: TRect;
begin
  FrameDrawing := True;
  if ShadowCircle <> nil then
    Clip := ShadowCircle.HitTestBounds
  else
    Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    AllocatePixelBuffers(Segment);
    Segment.PixelFirst :=
        Classes.Point(Segment.First.X + AbsolutePosition.X, Segment.First.Y + AbsolutePosition.Y);
    Segment.PixelLast :=
        Classes.Point(Segment.Last.X + AbsolutePosition.X, Segment.Last.Y + AbsolutePosition.Y);
    if Segment.Kind <> 2 then
    begin
      if Ex_OKGR_Line_Clip(
              Segment.PixelFirst.X,
              Segment.PixelFirst.Y,
              Segment.PixelLast.X,
              Segment.PixelLast.Y,
              Clip)
          = 0 then
        Segment.Visible := False
      else
        Segment.Visible := True;
    end
    else
    begin
      Segment.ClippedColor := Segment.Color;
      Segment.ClippedEndColor := Segment.EndColor;
      if Ex_OKGR_LineColor_Clip(
              Segment.PixelFirst.X,
              Segment.PixelFirst.Y,
              Segment.ClippedColor,
              Segment.PixelLast.X,
              Segment.PixelLast.Y,
              Segment.ClippedEndColor,
              Clip)
          = 0 then
        Segment.Visible := False
      else
        Segment.Visible := True;
    end;
    Segment := Segment.Next;
  end;

end;

procedure TPolyLineGI.DrawUpdateRects(ClipRect: TRect);
var
  Segment: PPolyLineSegmentGI;
  Clip: TRect;
begin
  FrameDrawing := True;
  Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    if Segment.Visible then
      DrawFrameSegment(Segment, Clip);
    Segment := Segment.Next;
  end;
end;

procedure TPolyLineGI.Draw(ClipRect: TRect);
var
  Segment: PPolyLineSegmentGI;
begin
  FrameDrawing := False;
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    Segment.PixelFirst :=
        Classes.Point(Segment.First.X + AbsolutePosition.X, Segment.First.Y + AbsolutePosition.Y);
    Segment.PixelLast :=
        Classes.Point(Segment.Last.X + AbsolutePosition.X, Segment.Last.Y + AbsolutePosition.Y);
    DrawSegment(Segment, ClipRect);
    Segment := Segment.Next;
  end;
end;

procedure TPolyLineGI.DrawSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect);
begin
  if HardwareRenderingEnabled then
  begin
    if Segment.Animated then
      DrawAnimatedLineDX(
          Segment.PixelFirst.X,
          Segment.PixelFirst.Y,
          Segment.PixelLast.X,
          Segment.PixelLast.Y,
          Color565ToArgb(Segment.Color),
          AnimationPhase,
          @ClipRect
      )
    else
      DrawAnimatedLineDX(
          Segment.PixelFirst.X,
          Segment.PixelFirst.Y,
          Segment.PixelLast.X,
          Segment.PixelLast.Y,
          Color565ToArgb(Segment.Color),
          0,
          @ClipRect
      );
  end
  else
  begin
    if Segment.Animated then
      ScreenRenderBuffer.DrawAnimatedLine16(
          Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
          Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
          Segment.Color,
          AnimationPhase,
          ClipRect
      )
    else
      ScreenRenderBuffer.DrawAnimatedLine16(
          Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
          Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
          Segment.Color,
          0,
          ClipRect
      );
  end;
end;

procedure TPolyLineGI.DrawFrameSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect);
var
  X, Y: Integer;
begin
  X := 0;
  Y := 0;
  if ShadowCircle = nil then
  begin
    if Segment.Kind = 0 then
    begin
      if HardwareRenderingEnabled then
      begin
        if Segment.Animated then
          DrawAnimatedLineDX(
              Segment.PixelFirst.X,
              Segment.PixelFirst.Y,
              Segment.PixelLast.X,
              Segment.PixelLast.Y,
              Color565ToArgb(Segment.Color),
              AnimationPhase,
              @ClipRect
          )
        else
          DrawAnimatedLineDX(
              Segment.PixelFirst.X,
              Segment.PixelFirst.Y,
              Segment.PixelLast.X,
              Segment.PixelLast.Y,
              Color565ToArgb(Segment.Color),
              0,
              @ClipRect
          );
      end
      else
      begin
        if Segment.Animated then
          ScreenRenderBuffer.DrawAnimatedLine16(
              Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
              Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
              Segment.Color,
              AnimationPhase,
              ClipRect
          )
        else
          ScreenRenderBuffer.DrawAnimatedLine16(
              Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
              Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
              Segment.Color,
              0,
              ClipRect
          );
      end;
    end
    else if Segment.Kind = 1 then
    begin
      if HardwareRenderingEnabled then
        DrawAlphaLine(
            Segment.PixelFirst.X,
            Segment.PixelFirst.Y,
            Segment.PixelLast.X,
            Segment.PixelLast.Y,
            Segment.Color,
            (Segment.Color shr 24) and $FF,
            @ClipRect
        )
      else
        ScreenRenderBuffer.DrawLine16Clipped(
            Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
            Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
            Segment.Color,
            ClipRect
        );
    end
    else
    begin
      if HardwareRenderingEnabled then
        DrawGradientLine(
            Segment.PixelFirst.X,
            Segment.PixelFirst.Y,
            Segment.ClippedColor,
            Segment.PixelLast.X,
            Segment.PixelLast.Y,
            Segment.ClippedEndColor,
            @ClipRect
        )
      else
        LineRasterizer16(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            Segment.PixelFirst.X,
            Segment.PixelFirst.Y,
            Segment.ClippedColor,
            Segment.PixelLast.X,
            Segment.PixelLast.Y,
            Segment.ClippedEndColor
        );
    end;
  end
  else if (ShadowCircle.LightBuffer <> nil)
      and (ShadowCircle.LightBuffer.GetPixels <> nil)
      and Segment.Visible then
  begin
    if not SkipSavedPixelRestore then
    begin
      Ex_OKGR_Line_CopyFromBuf_WORD(
          Segment.SavedPixels,
          ScreenRenderBuffer.GetPixels,
          ScreenRenderBuffer.PitchBytes,
          Segment.PixelFirst.X,
          Segment.PixelFirst.Y,
          Segment.PixelLast.X,
          Segment.PixelLast.Y
      );
      if Segment.Animated then
        ScreenRenderBuffer.DrawShadowLine16(
            Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
            Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
            Segment.Color,
            AnimationPhase,
            ClipRect,
            AddPointerOffset(
                ShadowCircle.LightBuffer.GetPixels,
                ShadowCircle.LightBuffer.PitchBytes * Y + X
            ),
            ShadowCircle.LightBuffer.PitchBytes
        )
      else
        ScreenRenderBuffer.DrawShadowLine16(
            Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
            Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
            Segment.Color,
            0,
            ClipRect,
            AddPointerOffset(
                ShadowCircle.LightBuffer.GetPixels,
                ShadowCircle.LightBuffer.PitchBytes * Y + X
            ),
            ShadowCircle.LightBuffer.PitchBytes
        );
    end
    else
    begin
      if Segment.Animated then
        ScreenRenderBuffer.DrawAnimatedLine16(
            Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
            Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
            Segment.Color,
            AnimationPhase,
            ClipRect
        )
      else
        ScreenRenderBuffer.DrawAnimatedLine16(
            Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
            Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y),
            Segment.Color,
            0,
            ClipRect
        );
    end;
  end;
end;

procedure TPolyLineGI.CommitFrameDraw;
begin
end;

end.
