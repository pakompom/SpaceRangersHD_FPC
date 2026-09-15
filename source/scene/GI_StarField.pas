{$EXCESSPRECISION OFF}
unit GI_StarField;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_Panel,
  GI_MessageLoop,
  EC_CacheGAI,
  EC_BlockPar,
  Types;
type
  TStarFieldGI = class;
  TStarFieldList = class;
  PointerToTStarFieldPoint = ^TStarFieldPoint;
  PointerToTStarFieldPixel = ^TStarFieldPixel;
  TStarFieldPoint = record
    X: Single;
    Y: Single;
    Depth: Single;
    InverseDepth: Single;
    Color: Word;
    Gap12: array[0..1] of Byte;
  end;
  PStarFieldPoint = PointerToTStarFieldPoint;
  TStarFieldPixel = record
    ByteOffset: Integer;
    Position: TPoint;
    Color: Word;
    SavedPixel: Word;
  end;
  PStarFieldPixel = PointerToTStarFieldPixel;
  TStarFieldList = class(TObject)
    Points: PStarFieldPoint;
    Count: Integer;
    Capacity: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AllocatePoint: PStarFieldPoint;
    procedure AddPoint(X: Single; Y: Single; Depth: Single; Color: Integer);
  end;
  TStarFieldGI = class(TPanelGI)
    BackgroundCache: TCGaiControlEC;
    Stars: TStarFieldList;
    ViewPosition: TPointF;
    Unknown150: Integer;
    ViewDirty: Boolean;
    Gap155: array[0..2] of Byte;
    Pixels: PStarFieldPixel;
    PixelCapacity: Integer;
    PixelCount: Integer;
    PreviousPixels: PStarFieldPixel;
    PreviousPixelCount: Integer;
    BackgroundScale: Single;
    PreviousBackgroundBounds: TRect;
    BackgroundBounds: TRect;
    procedure SetSize(Size: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure DrawUpdateRects(ClipRect: TRect); override;
    procedure CommitFrameDraw; override;
    procedure ErasePreviousFrame; override;
    procedure PrepareFrameDraw; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetBackgroundImage(const Path: WideString);
    procedure ClearProjectedPixels;
    procedure GrowPixelBuffers;
    procedure RebuildProjectedPixels;
    procedure SetViewPosition(Position: TPointF);
    procedure MarkViewDirty;
    procedure LoadStarFieldProperties(Block: TBlockParEC);
    procedure UpdateBackgroundBounds;
    procedure DrawBackground(ClipRect: TRect);
  end;
implementation
uses
  Math,
  EC_Mem,
  EC_Cache,
  GR_Main,
  GR_DX,
  GR_gi,
  GR_GraphBuf,
  GlobalsV,
  Classes,
  SysUtils,
  Windows;

constructor TStarFieldList.Create;
begin
  inherited Create;
end;

destructor TStarFieldList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TStarFieldList.Clear;
begin
  if Points <> nil then
  begin
    FreeEC(Points);
    Points := nil;
  end;
  Capacity := 0;
  Count := 0;
end;

function TStarFieldList.AllocatePoint: PStarFieldPoint;
begin
  Inc(Count);
  if Count >= Capacity then
  begin
    Inc(Capacity, 100);
    Points := ReAllocREC(Points, Capacity * SizeOf(TStarFieldPoint));
  end;
  Result := AddPointerOffset(Points, (Count - 1) * SizeOf(TStarFieldPoint));
end;

procedure TStarFieldList.AddPoint(X, Y, Depth: Single; Color: Integer);
var
  Point: PStarFieldPoint;
begin
  Point := AllocatePoint;
  Point.X := X;
  Point.Y := Y;
  Point.Depth := Depth;
  Point.InverseDepth := 1.0 / Depth;
  Point.Color := Color;
end;

constructor TStarFieldGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  BackgroundCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(BackgroundCache);
  Stars := TStarFieldList.Create;
  ViewDirty := True;
  MessageLoop.RegionDrawControl := Self;
  Unknown150 := 0;
  BackgroundScale := 8.0;
end;

destructor TStarFieldGI.Destroy;
begin
  MessageLoop.RegionDrawControl := nil;
  Stars.Free;
  if Pixels <> nil then
  begin
    FreeEC(Pixels);
    Pixels := nil;
  end;
  PixelCount := 0;
  PixelCapacity := 0;
  if PreviousPixels <> nil then
  begin
    FreeEC(PreviousPixels);
    PreviousPixels := nil;
  end;
  PreviousPixelCount := 0;
  BackgroundCache.Free;
  BackgroundCache := nil;
  inherited Destroy;
end;

procedure TStarFieldGI.SetBackgroundImage(const Path: WideString);
begin
  inherited Invalidate;
  BackgroundCache.SetCacheKey(Path);
end;

procedure TStarFieldGI.ClearProjectedPixels;
begin
  PixelCount := 0;
end;

procedure TStarFieldGI.GrowPixelBuffers;
begin
  Inc(PixelCapacity, 64);
  Pixels := ReAllocREC(Pixels, PixelCapacity * SizeOf(TStarFieldPixel));
  PreviousPixels := ReAllocREC(PreviousPixels, PixelCapacity * SizeOf(TStarFieldPixel));
end;

procedure TStarFieldGI.RebuildProjectedPixels;
var
  Point: PStarFieldPoint;
  Pixel: PStarFieldPixel;
  Position: TPoint;
  Left, Top, Right, Bottom, I, Pitch: Integer;
begin
  ClearProjectedPixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Left := HitTestBounds.Left;
  Top := HitTestBounds.Top;
  Right := HitTestBounds.Right;
  Bottom := HitTestBounds.Bottom;
  Point := Stars.Points;
  for I := 0 to Stars.Count - 1 do
  begin
    Position.X :=
        Integer(Round((Point.X - ViewPosition.X) * Point.InverseDepth)) + AbsolutePosition.X;
    Position.Y :=
        Integer(Round((Point.Y - ViewPosition.Y) * Point.InverseDepth)) + AbsolutePosition.Y;
    if (Position.X >= Left)
        and (Position.X < Right)
        and (Position.Y >= Top)
        and (Position.Y < Bottom) then
    begin
      Inc(PixelCount);
      if PixelCount > PixelCapacity then
        GrowPixelBuffers;
      Pixel := AddPointerOffset(Pixels, (PixelCount - 1) * SizeOf(TStarFieldPixel));
      Pixel.ByteOffset := Position.X * 2 + Position.Y * Pitch;
      Pixel.Position := Position;
      Pixel.Color := Point.Color;
    end;
    Point := AddPointerOffset(Point, SizeOf(TStarFieldPoint));
  end;
end;

procedure TStarFieldGI.SetViewPosition(Position: TPointF);
begin
  if (ViewPosition.X <> Position.X) or (ViewPosition.Y <> Position.Y) then
  begin
    Invalidate;
    ViewPosition := Position;
    ViewDirty := True;
    Invalidate;
  end;
end;

procedure TStarFieldGI.SetSize(Size: TPoint);
begin
  if (ClientSize.X <> Size.X) or (ClientSize.Y <> Size.Y) then
  begin
    inherited SetSize(Size);
    ViewDirty := True;
  end;
end;

procedure TStarFieldGI.MarkViewDirty;
begin
  ViewDirty := True;
end;

procedure TStarFieldGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadStarFieldProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TStarFieldGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadStarFieldProperties(Block);
end;

procedure TStarFieldGI.LoadStarFieldProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then
    SetBackgroundImage(Block.GetParam('Image'));
end;

procedure TStarFieldGI.Invalidate;
begin
end;

procedure TStarFieldGI.UpdateBackgroundBounds;
var
  Data: TCGaiEC;
  X, Y, Width, Height: Integer;
  Bounds: TRect;
begin
  SkipSavedPixelRestore := False;
  if BGImage then
    if BackgroundCache.CacheKey <> '' then
    begin
      SkipSavedPixelRestore := True;
      Data := AcquireCachedGai(BackgroundCache);
      try
        Bounds := Data.GetBoundsRect;
      finally
        BackgroundCache.Release;
      end;
      Width := Bounds.Right - Bounds.Left;
      Height := Bounds.Bottom - Bounds.Top;
      X :=
          Integer(Round((0.0 - ViewPosition.X) / BackgroundScale))
              + AbsolutePosition.X
              - Width div 2;
      Y :=
          Integer(Round((0.0 - ViewPosition.Y) / BackgroundScale))
              + AbsolutePosition.Y
              - Height div 2;
      Bounds.Left := X;
      Bounds.Top := Y;
      Bounds.Right := X + Width;
      Bounds.Bottom := Y + Height;
      BackgroundBounds := Bounds;
      SkipSavedPixelRestore :=
          not CompareMem(@BackgroundBounds, @PreviousBackgroundBounds, SizeOf(TRect));
    end;
  if HardwareRenderingEnabled then
    SkipSavedPixelRestore := True;
end;

procedure TStarFieldGI.ErasePreviousFrame;
var
  Pixel: PStarFieldPixel;
  Buffer: Pointer;
  I: Integer;
begin
  if ViewDirty then
  begin
    RebuildProjectedPixels;
    ViewDirty := False;
  end;
  if not HardwareRenderingEnabled then
  begin
    Buffer := ScreenRenderBuffer.GetPixels;
    if not SkipSavedPixelRestore then
    begin
      if (not BGImage) or (BackgroundCache.CacheKey = '') then
      begin
        Pixel := PreviousPixels;
        for I := 0 to PreviousPixelCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), 0);
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end
      else
      begin
        Pixel := PreviousPixels;
        for I := 0 to PreviousPixelCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), Pixel.SavedPixel);
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end;
    end;
  end;
end;

procedure TStarFieldGI.DrawBackground(ClipRect: TRect);
var
  I, X, Y, Width, Height: Integer;
  Data: TCGaiEC;
  Frame: TgiGR;
  Intersection, Bounds: TRect;
begin
  if (not BGImage)
      or (BackgroundCache.CacheKey = '')
      or (BackgroundBounds.Top >= ClipRect.Bottom)
      or (BackgroundBounds.Bottom <= ClipRect.Top)
      or (BackgroundBounds.Left >= ClipRect.Right)
      or (BackgroundBounds.Right <= ClipRect.Left) then
  begin
    X := ClipRect.Left;
    Y := ClipRect.Top;
    Width := ClipRect.Right - X;
    Height := ClipRect.Bottom - Y;
    if HardwareRenderingEnabled then
      DrawColoredRect(X, Y, Width, Height, 0, 255, True, @ClipRect)
    else
      Ex_OKGR_Fill_WORD(
          AddPointerOffset(ScreenRenderBuffer.GetPixels, ScreenRenderBuffer.PitchBytes * Y + X * 2),
          ScreenRenderBuffer.PitchBytes,
          Width,
          Height,
          0
      );
  end
  else
  begin
    if BackgroundBounds.Top > ClipRect.Top then
    begin
      X := ClipRect.Left;
      Y := ClipRect.Top;
      Width := ClipRect.Right - ClipRect.Left;
      Height := BackgroundBounds.Top - ClipRect.Top;
      if HardwareRenderingEnabled then
        DrawColoredRect(X, Y, Width, Height, 0, 255, True, @ClipRect)
      else
        Ex_OKGR_Fill_WORD(
            AddPointerOffset(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes * Y + X * 2
            ),
            ScreenRenderBuffer.PitchBytes,
            Width,
            Height,
            0
        );
    end;
    if BackgroundBounds.Bottom < ClipRect.Bottom then
    begin
      X := ClipRect.Left;
      Y := BackgroundBounds.Bottom;
      Width := ClipRect.Right - ClipRect.Left;
      Height := ClipRect.Bottom - BackgroundBounds.Bottom;
      if HardwareRenderingEnabled then
        DrawColoredRect(X, Y, Width, Height, 0, 255, True, @ClipRect)
      else
        Ex_OKGR_Fill_WORD(
            AddPointerOffset(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes * Y + X * 2
            ),
            ScreenRenderBuffer.PitchBytes,
            Width,
            Height,
            0
        );
    end;
    if BackgroundBounds.Left > ClipRect.Left then
    begin
      X := ClipRect.Left;
      Y := BackgroundBounds.Top;
      if Y < ClipRect.Top then
        Y := ClipRect.Top;
      Width := BackgroundBounds.Left - ClipRect.Left;
      Height := BackgroundBounds.Bottom;
      if Height > ClipRect.Bottom then
        Height := ClipRect.Bottom;
      Height := Height - Y;
      if HardwareRenderingEnabled then
        DrawColoredRect(X, Y, Width, Height, 0, 255, True, @ClipRect)
      else
        Ex_OKGR_Fill_WORD(
            AddPointerOffset(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes * Y + X * 2
            ),
            ScreenRenderBuffer.PitchBytes,
            Width,
            Height,
            0
        );
    end;
    if BackgroundBounds.Right < ClipRect.Right then
    begin
      X := BackgroundBounds.Right;
      Y := BackgroundBounds.Top;
      if Y < ClipRect.Top then
        Y := ClipRect.Top;
      Width := ClipRect.Right - BackgroundBounds.Right;
      Height := BackgroundBounds.Bottom;
      if Height > ClipRect.Bottom then
        Height := ClipRect.Bottom;
      Height := Height - Y;
      if HardwareRenderingEnabled then
        DrawColoredRect(X, Y, Width, Height, 0, 255, True, @ClipRect)
      else
        Ex_OKGR_Fill_WORD(
            AddPointerOffset(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes * Y + X * 2
            ),
            ScreenRenderBuffer.PitchBytes,
            Width,
            Height,
            0
        );
    end;
    Data := AcquireCachedGai(BackgroundCache);
    try
      for I := 0 to Data.GetFrameCount - 1 do
      begin
        Frame := Data.LoadFrameGi(I);
        Bounds := Frame.GetBoundsRect;
        Inc(Bounds.Left, BackgroundBounds.Left);
        Inc(Bounds.Top, BackgroundBounds.Top);
        Inc(Bounds.Right, BackgroundBounds.Left);
        Inc(Bounds.Bottom, BackgroundBounds.Top);
        if IntersectRects(Intersection, ClipRect, Bounds) then
        begin
          if HardwareRenderingEnabled then
            DrawTexture(
                Data.GetOrCreateFrameSurface(I),
                Bounds.Left,
                Bounds.Top,
                255,
                $FFFFFF,
                @Intersection,
                False,
                False
            )
          else
            Frame.DrawToGraphBuf(ScreenRenderBuffer, Bounds.Left, Bounds.Top, Intersection, 0, 255);
        end;
      end;
    finally
      BackgroundCache.Release;
    end;
  end;
end;

procedure TStarFieldGI.PrepareFrameDraw;
var
  Pixel: PStarFieldPixel;
  I: Integer;
  Buffer: Pointer;
begin
  if not HardwareRenderingEnabled then
    if BGImage then
      if BackgroundCache.CacheKey <> '' then
      begin
        Buffer := ScreenRenderBuffer.GetPixels;
        Pixel := Pixels;
        for I := 0 to PixelCount - 1 do
        begin
          Pixel.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset));
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end;
end;

procedure TStarFieldGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;

procedure TStarFieldGI.Draw(ClipRect: TRect);
var
  Pixel: PStarFieldPixel;
  Buffer: Pointer;
  Count: Integer;
begin
  Pixel := Pixels;
  Count := PixelCount;
  if HardwareRenderingEnabled then
  begin
    while Count > 0 do
    begin
      QueueDrawPoint(Pixel.Position.X, Pixel.Position.Y, Color565ToArgb(Pixel.Color), 255);
      Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
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
      Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
      Dec(Count);
    end;
  end;
end;

procedure TStarFieldGI.CommitFrameDraw;
begin
  if not HardwareRenderingEnabled then
  begin
    PreviousPixelCount := PixelCount;
    CopyMemory(PreviousPixels, Pixels, PreviousPixelCount * SizeOf(TStarFieldPixel));
    PreviousBackgroundBounds := BackgroundBounds;
  end;
end;

end.
