{$EXCESSPRECISION OFF}
unit GI_GAI;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types,
  GR_GraphBuf,
  GI_Main,
  EC_CacheGI,
  EC_CacheGAI,
  EC_BlockPar,
  Classes,
  GI_MessageLoop;
type
  PointerToInteger = ^Integer;
type
  TgaiGI = class;
  TgaiGI = class(TObjectGI)

    MainImageCache: TCGaiControlEC;
    FirstFrameImageCache: TCGiControlEC;
    AutoFrameTimer: PCallbackTimerGI;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    Alpha: Byte;
    Gap12F: array[0..0] of Byte;
    SequenceFrame: Integer;
    SequenceFrameCount: Integer;
    SequenceFrameIndexTable: PointerToInteger;
    SequenceFrameDelayTable: PointerToInteger;
    SequenceIndex: Integer;
    UsesPlaybackBuffer: Boolean;
    Gap145: array[0..2] of Byte;
    CachedPlaybackGraphBuf: TGraphBufGR;
    LastCachedFrameIndex: Integer;
    TransparentColor: Cardinal;
    Gap154: array[0..3] of Byte;
    CycleCompleteCallback: TObjectNotifyEventGI;
    FrameAdvancedCallback: TObjectNotifyEventGI;
    SkipImageUpdateRect: Boolean;
    StopPlaybackRequested: Boolean;
    StopAfterOneCycle: Boolean;
    Gap16B: array[0..0] of Byte;
    StartSoundName: WideString;
    FirstFrameOnly: Boolean;
    Gap171: array[0..2] of Byte;
    AutoUpdateFlags: Cardinal;
    HardwareMirrorHorizontal: Boolean;
    Gap179: array[0..2] of Byte;

    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure SetActive(Value: Boolean); override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnDeactivate; override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(const ImagePath: WideString);
    function GetImagePath: WideString;
    procedure SetFirstFrameImagePath(const ImagePath: WideString);
    function GetFirstFrameImagePath: WideString;
    procedure SetSequenceFrame(FrameInSequence: Integer);
    procedure SetFramePosition(FrameInSequence: Integer; ForwardOnly: Boolean);
    function GetMainImageFrameCount: Integer;
    procedure StopAutoPlayback;
    procedure RestartPlayback;
    function GetContentSize: TPoint;
    function GetContentOrigin: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetAlpha(Value: Byte);
    procedure ClearFrameSequence;
    procedure LoadFrameSequenceFromText(const FrameSpec: WideString);
    function GetSequenceCount: Integer;
    function GetSequenceFrameSourceIndex(FrameInSequence: Integer): Integer;
    procedure SetFrameDelay(FrameInSequence: Integer; DelayMs: Integer);
    function GetFrameDelay(FrameInSequence: Integer): Integer;
    function HitTestPixel(Point: TPoint): Boolean;
    procedure LoadAnimationProperties(Block: TBlockParEC);
    procedure SetOneCycleDuration(DurationMs: Integer);
    procedure AdvanceAutoFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure SetHardwareMirrorHorizontal(Value: Boolean);
    procedure PrimeImageCaches;
  end;
var
  GaiFrameHeap: Cardinal = 0;
procedure LoadGaiFrameToGraphBuf(const Path: WideString; GraphBuf: TGraphBufGR; Seed: Cardinal);
implementation

uses
  Math,
  GR_Sound,
  EC_Struct,
  Direct3D9,
  GR_DX,
  GR_gi,
  GR_Main,
  EC_Cache,
  EC_Str,
  EC_Mem,
  SysUtils,
  Windows,
  aMyFunction,
  GlobalsV;

constructor TgaiGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  if GaiFrameHeap = 0 then
  begin
    GaiFrameHeap := HeapCreate(0, $8000, 0);
    if GaiFrameHeap = 0 then
      raise Exception.Create('TgaiGI.HeapCreate');
  end;
  Alpha := 255;
  MainImageCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(MainImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  StopPlaybackRequested := False;
  StopAfterOneCycle := False;
  SequenceIndex := -1;
  TransparentColor := 0;
  SkipImageUpdateRect := False;
end;
destructor TgaiGI.Destroy;
begin

  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if AutoFrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := nil;
  end;
  MainImageCache.Free;
  MainImageCache := nil;
  if FirstFrameImageCache <> nil then
  begin
    FirstFrameImageCache.Free;
    FirstFrameImageCache := nil;
  end;
  ClearFrameSequence;
  inherited Destroy;
end;
procedure TgaiGI.Clear;
begin
  inherited Clear;
end;
procedure TgaiGI.SetImagePath(const ImagePath: WideString);
begin
  SequenceFrame := 0;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if MainImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;

    MainImageCache.SetCacheKey(ImagePath);
  end;
end;
function TgaiGI.GetImagePath: WideString;
begin
  Result := MainImageCache.CacheKey;
end;
procedure TgaiGI.SetFirstFrameImagePath(const ImagePath: WideString);
begin
  SequenceFrame := 0;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if FirstFrameImageCache = nil then
  begin
    FirstFrameImageCache := TCGiControlEC.Create;
    GlobalCache.ResetControl(FirstFrameImageCache);
  end;
  if FirstFrameImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    FirstFrameImageCache.SetCacheKey(ImagePath);
  end;
end;
function TgaiGI.GetFirstFrameImagePath: WideString;
begin
  if FirstFrameImageCache = nil then
    Result := ''
  else
    Result := FirstFrameImageCache.CacheKey;
end;
procedure TgaiGI.SetSequenceFrame(FrameInSequence: Integer);
begin
  SequenceFrame := FrameInSequence;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  Invalidate;
end;
procedure TgaiGI.SetFramePosition(FrameInSequence: Integer; ForwardOnly: Boolean);
begin
  if SequenceFrame = FrameInSequence then
    Exit;
  if (FrameInSequence <= SequenceFrame) and ForwardOnly then
    Exit;
  SequenceFrame := FrameInSequence;
  if (SequenceFrame < 0) or (SequenceFrame >= SequenceFrameCount) then
    SequenceFrame := 0;
  Invalidate;
end;
function TgaiGI.GetMainImageFrameCount: Integer;
var
  Image: TCGaiEC;
begin
  if FirstFrameOnly then
  begin
    Result := 0;
    Exit;
  end;
  Image := AcquireCachedGai(MainImageCache);
  try
    Result := Image.GetFrameCount;
  finally
    MainImageCache.Release;
  end;
end;
procedure TgaiGI.StopAutoPlayback;
begin
  StopPlaybackRequested := True;
  if AutoFrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := nil;
  end;
end;
procedure TgaiGI.RestartPlayback;
var
  Delay: Integer;
begin
  StopPlaybackRequested := False;
  if AutoFrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := nil;
  end;
  if SequenceFrameCount > 1 then
  begin
    Delay := GetFrameDelay(SequenceFrame);
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(Delay, Delay, AdvanceAutoFrame);
  end;
  if (StartSoundName <> '') and (SequenceFrame = 0) then
    SoundManager.PlaySound(StartSoundName);
end;
function TgaiGI.GetContentSize: TPoint;
var
  Image: TCGaiEC;
  First: TCGiEC;
begin
  if MainImageCache.CacheKey = '' then
  begin
    Result := Classes.Point(0, 0);
    Exit;
  end;
  if not FirstFrameOnly then
  begin
    Image := AcquireCachedGai(MainImageCache);
    try
      Result := Image.GetCanvasSize;
    finally
      MainImageCache.Release;
    end;
  end
  else if FirstFrameImageCache <> nil then
  begin
    First := AcquireCachedGi(FirstFrameImageCache);
    try
      Result := First.Image.GetContentSize;
    finally
      FirstFrameImageCache.Release;
    end;
  end
  else
    Result := Classes.Point(0, 0);
end;
function TgaiGI.GetContentOrigin: TPoint;
var
  Image: TCGaiEC;
  First: TCGiEC;
begin
  if MainImageCache.CacheKey = '' then
  begin
    Result := Classes.Point(0, 0);
    Exit;
  end;
  if not FirstFrameOnly then
  begin
    Image := AcquireCachedGai(MainImageCache);
    try
      Result := Image.GetBoundsRect.TopLeft;
    finally
      MainImageCache.Release;
    end;
  end
  else if FirstFrameImageCache <> nil then
  begin
    First := AcquireCachedGi(FirstFrameImageCache);
    try
      Result := First.Image.GetBoundsRect.TopLeft;
    finally
      FirstFrameImageCache.Release;
    end;
  end
  else
    Result := Classes.Point(0, 0);
end;
procedure TgaiGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
procedure TgaiGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
procedure TgaiGI.SetAlpha(Value: Byte);
begin
  if Alpha <> Value then
  begin
    Alpha := Value;
    Invalidate;
  end;
end;
procedure TgaiGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
end;
procedure TgaiGI.ClearFrameSequence;
begin
  if SequenceFrameIndexTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameIndexTable);
    SequenceFrameIndexTable := nil;
  end;
  if SequenceFrameDelayTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameDelayTable);
    SequenceFrameDelayTable := nil;
  end;
  SequenceFrame := 0;
  SequenceFrameCount := 0;
end;
procedure TgaiGI.LoadFrameSequenceFromText(const FrameSpec: WideString);
var
  Part: WideString;
  Index, Count, Offset, RangeCount, Delay, First, Last, TimerDelay: Integer;
begin
  ClearFrameSequence;
  Count := (CountDelimitedPartsW(FrameSpec, '[]') - 1) div 2;
  for Index := 0 to Count - 1 do
  begin
    Part := ExtractDelimitedPartW(FrameSpec, Index * 2 + 1, '[]');
    Delay := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 0, ',-'));
    First := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 1, ',-'));
    Last := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 2, ',-'));
    RangeCount := Abs(First - Last) + 1;
    Inc(SequenceFrameCount, RangeCount);
    SequenceFrameIndexTable :=
        ReAllocFromHeapREC(
            GaiFrameHeap,
            SequenceFrameIndexTable,
            SequenceFrameCount * SizeOf(Integer)
        );
    SequenceFrameDelayTable :=
        ReAllocFromHeapREC(
            GaiFrameHeap,
            SequenceFrameDelayTable,
            SequenceFrameCount * SizeOf(Integer)
        );
    for Offset := 0 to RangeCount - 1 do
    begin
      WriteInt32EC(
          AddPointerOffset(
              SequenceFrameIndexTable,
              (SequenceFrameCount - RangeCount + Offset) * SizeOf(Integer)
          ),
          First
      );
      WriteInt32EC(
          AddPointerOffset(
              SequenceFrameDelayTable,
              (SequenceFrameCount - RangeCount + Offset) * SizeOf(Integer)
          ),
          Delay
      );
      if First < Last then
        Inc(First)
      else
        Dec(First);
    end;
  end;
  if not StopPlaybackRequested then
  begin
    TimerDelay := GetFrameDelay(SequenceFrame);
    if AutoFrameTimer <> nil then
    begin
      MessageLoop.CancelCallbackTimer(AutoFrameTimer);
      AutoFrameTimer := nil;
    end;
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(TimerDelay, TimerDelay, AdvanceAutoFrame);
  end;
end;
function TgaiGI.GetSequenceCount: Integer;
var
  Image: TCGaiEC;
begin
  if FirstFrameOnly then
  begin
    Result := 0;
    Exit;
  end;
  Image := AcquireCachedGai(MainImageCache);
  try
    Result := Image.GetSequenceCount;
  finally
    MainImageCache.Release;
  end;
end;
function TgaiGI.GetSequenceFrameSourceIndex(FrameInSequence: Integer): Integer;
begin
  Result :=
      ReadIntegerEC(AddPointerOffset(SequenceFrameIndexTable, FrameInSequence * SizeOf(Integer)));
end;
procedure TgaiGI.SetFrameDelay(FrameInSequence, DelayMs: Integer);
begin
  WriteInt32EC(
      AddPointerOffset(SequenceFrameDelayTable, FrameInSequence * SizeOf(Integer)),
      DelayMs
  );
end;
function TgaiGI.GetFrameDelay(FrameInSequence: Integer): Integer;
begin
  Result :=
      ReadIntegerEC(AddPointerOffset(SequenceFrameDelayTable, FrameInSequence * SizeOf(Integer)));
end;
function TgaiGI.HitTestPixel(Point: TPoint): Boolean;
var
  Image: TCGaiEC;
  First: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
  Pixel: Cardinal;
  Pixels: Pointer;
  Buffer: TGraphBufGR;
  Frame: TgiGR;
  Clip, Bounds, FirstBounds: TRect;
begin
  Result := False;
  Pixel := 0;
  Clip.TopLeft := Point;
  Clip.Right := Point.X + 1;
  Clip.Bottom := Point.Y + 1;
  Image := nil;
  First := nil;
  try
    if not FirstFrameOnly then
      Image := AcquireCachedGai(MainImageCache);
    if FirstFrameImageCache <> nil then
      First := AcquireCachedGi(FirstFrameImageCache);
    if Image <> nil then
    begin
      Width := Image.GetCanvasSize.X;
      Height := Image.GetCanvasSize.Y;
      if First <> nil then
      begin
        FirstBounds := First.Image.GetBoundsRect;
        UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
        if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then
          RaiseWideMessage('TgaiGI.Draw Pos-Size');
        Width := FirstBounds.Right - FirstBounds.Left;
        Height := FirstBounds.Bottom - FirstBounds.Top;
        if First.Image.GetFormat <> 0 then
          RaiseWideMessage('TgaiGI.Draw Format gi not 0');
      end;
    end
    else if First <> nil then
    begin
      FirstBounds := First.Image.GetBoundsRect;
      Width := FirstBounds.Right - FirstBounds.Left;
      Height := FirstBounds.Bottom - FirstBounds.Top;
      if First.Image.GetFormat <> 0 then
        RaiseWideMessage('TgaiGI.Draw Format gi not 0');
    end
    else
    begin
      Width := 0;
      Height := 0;
    end;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > Clip.Left do
        Dec(Left, Width);
    end
    else if ImageKindX = ikxLeft then
    begin
      Left := HitTestBounds.Left;
      Right := Left + Width;
    end
    else if ImageKindX = ikxRight then
    begin
      Right := HitTestBounds.Right;
      Left := Right - Width;
    end
    else if ImageKindX = ikxCenter then
    begin
      Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
      Right := Left + Width;
    end
    else
    begin
      Exit;
    end;
    if ImageKindY = ikyTopFill then
    begin
      Top := HitTestBounds.Top;
      Bottom := HitTestBounds.Bottom;
    end
    else if ImageKindY = ikyBottomFill then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom;
      while Top > Clip.Top do
        Dec(Top, Height);
    end
    else if ImageKindY = ikyTop then
    begin
      Top := HitTestBounds.Top;
      Bottom := Top + Height;
    end
    else if ImageKindY = ikyBottom then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom - Height;
    end
    else if ImageKindY = ikyCenter then
    begin
      Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
      Bottom := Top + Height;
    end
    else
    begin
      Exit;
    end;
    Pixels :=
        AddPointerOffset(
            @Pixel,
            -(ScreenRenderBuffer.PitchBytes * Point.Y + Point.X * SizeOf(Word))
        );
    Buffer := TGraphBufGR.Create(False);
    Buffer.AttachPixels(1, 1, ScreenRenderBuffer.PitchBytes, Pixels);
    if Image <> nil then
      Bounds := Image.GetBoundsRect;
    if (Image <> nil) and (not Image.HasPlaybackFlags) then
    begin
      Y := Top;
      while Y < Bottom do
      begin
        X := Left;
        while X < Right do
        begin
          Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(SequenceFrame));
          Frame.DrawToGraphBuf(
              Buffer,
              X + Frame.GetBoundsRect.Left - Bounds.Left,
              Y + Frame.GetBoundsRect.Top - Bounds.Top,
              Clip,
              0,
              255
          );
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end
    else if FirstFrameImageCache <> nil then
    begin
      if CachedPlaybackGraphBuf <> nil then
      begin
        if (CachedPlaybackGraphBuf.Width = Width) and (CachedPlaybackGraphBuf.Height = Height) then
        begin
          Y := Top;
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              DrawAlphaGraphBuffer16Clipped(
                  Buffer.GetPixels,
                  Buffer.PitchBytes,
                  X,
                  Y,
                  CachedPlaybackGraphBuf,
                  Clip
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end;
      end;
    end;
    Buffer.Free;
  finally
    if Image <> nil then
      MainImageCache.Release;
    if First <> nil then
      FirstFrameImageCache.Release;
  end;
  Result := Pixel <> 0;
end;
procedure TgaiGI.SetActive(Value: Boolean);
begin
  if Active <> Value then
  begin
    inherited SetActive(Value);
    if not Value then
    begin

      if AutoFrameTimer <> nil then
      begin
        MessageLoop.CancelCallbackTimer(AutoFrameTimer);
        AutoFrameTimer := nil;
      end;
      if CachedPlaybackGraphBuf <> nil then
      begin
        CachedPlaybackGraphBuf.Free;
        CachedPlaybackGraphBuf := nil;
      end;
      Active := True;
      inherited Invalidate;
      Active := False;
    end
    else
    begin
      if not StopPlaybackRequested then
        RestartPlayback;
      inherited Invalidate;
    end;
  end;
end;
procedure TgaiGI.OnDeactivate;
begin

  if AutoFrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := nil;
  end;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  inherited OnDeactivate;
end;
procedure TgaiGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadAnimationProperties(UiStyleConfig.GetBlockByPath(Path));
end;
procedure TgaiGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadAnimationProperties(Block);
end;
procedure TgaiGI.LoadAnimationProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then
    MainImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('ImageFirst') > 0 then
    SetFirstFrameImagePath(Block.GetParam('ImageFirst'));

  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
  if Block.CountParams('PBuf') > 0 then
    UsesPlaybackBuffer := ParseEnabledNameGI(Block.GetParam('PBuf'));
  if Block.CountParams('Stop') > 0 then
    StopPlaybackRequested := ParseEnabledNameGI(Block.GetParam('Stop'));
  if Block.CountParams('Frame') > 0 then
    LoadFrameSequenceFromText(Block.GetParam('Frame'));
  if Block.CountParams('FrameLoad') > 0 then
    SequenceIndex := StrToInt(Block.GetParam('FrameLoad'));
  if Block.CountParams('Auto') > 0 then
    AutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
  if Block.CountParams('TransColor') > 0 then
    TransparentColor := GetColorGI(Block.GetParam('TransColor'));
  if Block.CountParams('SkipImageUpdateRect') > 0 then
    SkipImageUpdateRect := ParseEnabledNameGI(Block.GetParam('SkipImageUpdateRect'));
  if Block.CountParams('StopAfterOneCycle') > 0 then
    StopAfterOneCycle := ParseEnabledNameGI(Block.GetParam('StopAfterOneCycle'));
  if Block.CountParams('SoundStart') > 0 then
  begin
    StartSoundName := Block.GetParam('SoundStart');
    if AutoFrameTimer <> nil then
    begin
      MessageLoop.CancelCallbackTimer(AutoFrameTimer);
      AutoFrameTimer := nil;
    end;
  end;
end;
procedure TgaiGI.UpdateAutoGeometry;
var
  Image: TCGaiEC;
begin
  inherited UpdateAutoGeometry;
  if (AutoUpdateFlags and agfPosition) = agfPosition then
    SetPosition(Parent.ToLocalPoint(GetContentOrigin));
  if (AutoUpdateFlags and agfSize) = agfSize then
    SetSize(GetContentSize);
  if SequenceIndex >= 0 then
  begin
    ClearFrameSequence;
    if (not FirstFrameOnly) and (MainImageCache <> nil) and (MainImageCache.CacheKey <> '') then
    begin
      Image := AcquireCachedGai(MainImageCache);
      try
        if (SequenceIndex < 0) or (SequenceIndex >= Image.GetSequenceCount) then
        begin
          MainImageCache.Release;
          SequenceFrameCount := 0;
          AppendLogLineThreadSafe('TgaiGI.AfterLoad. Anim not found.');
          Exit;
        end;
        SequenceFrameCount := Image.GetSequenceFrameCount(SequenceIndex);
        SequenceFrameIndexTable :=
            ReAllocFromHeapREC(
                GaiFrameHeap,
                SequenceFrameIndexTable,
                SequenceFrameCount * SizeOf(Integer)
            );
        SequenceFrameDelayTable :=
            ReAllocFromHeapREC(
                GaiFrameHeap,
                SequenceFrameDelayTable,
                SequenceFrameCount * SizeOf(Integer)
            );
        Image.FillSequenceFrameIndexTable(SequenceIndex, SequenceFrameIndexTable, SizeOf(Integer));
        Image.FillSequenceFrameDelayTable(SequenceIndex, SequenceFrameDelayTable, SizeOf(Integer));
      finally
        MainImageCache.Release;
      end;
    end;
  end;
end;
procedure TgaiGI.SetOneCycleDuration(DurationMs: Integer);
var
  Index, Delay: Integer;
begin
  StopAfterOneCycle := True;
  if SequenceFrameDelayTable <> nil then
  begin
    Delay := Round(DurationMs / SequenceFrameCount);
    if Delay < 1 then
      Delay := 1;
    for Index := 0 to SequenceFrameCount - 1 do
      WriteInt32EC(AddPointerOffset(SequenceFrameDelayTable, Index * SizeOf(Integer)), Delay);
  end;
end;
procedure TgaiGI.AdvanceAutoFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Wrapped: Boolean;
  Delay: Integer;
begin
  Wrapped := False;
  Inc(SequenceFrame);
  if Assigned(FrameAdvancedCallback) then
    FrameAdvancedCallback(Self);
  if SequenceFrame >= SequenceFrameCount then
  begin
    SequenceFrame := 0;
    if StartSoundName <> '' then
      SoundManager.PlaySound(StartSoundName);
    Wrapped := True;
  end;
  if StopPlaybackRequested then
  begin
    if AutoFrameTimer <> nil then
    begin
      MessageLoop.CancelCallbackTimer(AutoFrameTimer);
      AutoFrameTimer := nil;
    end;
  end
  else if AutoFrameTimer = nil then
  begin
    Delay := GetFrameDelay(SequenceFrame);
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(Delay, Delay, AdvanceAutoFrame);
  end
  else
  begin
    Delay := GetFrameDelay(SequenceFrame);
    MessageLoop.UpdateCallbackTimer(AutoFrameTimer, Delay, Delay);
  end;
  Invalidate;
  if Wrapped then
  begin
    if StopAfterOneCycle then
    begin
      StopAutoPlayback;
      SetActive(False);
    end;
    if Assigned(CycleCompleteCallback) then
      CycleCompleteCallback(Self);
  end;
end;
procedure TgaiGI.Invalidate;
var
  Image: TCGaiEC;
  First: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y, FrameIndex, RectIndex, RectCount: Integer;
  Frame: TgiGR;
  Bounds, FirstBounds, Rect, Clip, FrameBounds: TRect;
begin
  if (not Active) or HardwareRenderingEnabled then
    Exit;
  if (not SkipImageUpdateRect)
      and (FirstFrameImageCache <> nil)
      and (not FirstFrameOnly)
      and UsesPlaybackBuffer then
  begin
    if (CachedPlaybackGraphBuf = nil)
        or (LastCachedFrameIndex < 0)
        or (SequenceFrame < LastCachedFrameIndex) then
    begin
      inherited Invalidate;
      Exit;
    end;
    if SequenceFrame <= LastCachedFrameIndex then
      Exit;
    Image := nil;
    First := nil;
    Clip := HitTestBounds;
    try
      Image := AcquireCachedGai(MainImageCache);
      First := AcquireCachedGi(FirstFrameImageCache);
      FirstBounds := First.Image.GetBoundsRect;
      UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
      if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then
        RaiseWideMessage('TgaiGI.Update Pos-Size');
      Width := FirstBounds.Right - FirstBounds.Left;
      Height := FirstBounds.Bottom - FirstBounds.Top;
      if First.Image.GetFormat <> 0 then
        RaiseWideMessage('TgaiGI.Update Format gi not 0');
      if ImageKindX = ikxLeftFill then
      begin
        Left := HitTestBounds.Left;
        Right := HitTestBounds.Right;
      end
      else if ImageKindX = ikxRightFill then
      begin
        Right := HitTestBounds.Right;
        Left := Right;
        while Left > Clip.Left do
          Dec(Left, Width);
      end
      else if ImageKindX = ikxLeft then
      begin
        Left := HitTestBounds.Left;
        Right := Left + Width;
      end
      else if ImageKindX = ikxRight then
      begin
        Right := HitTestBounds.Right;
        Left := Right - Width;
      end
      else if ImageKindX = ikxCenter then
      begin
        Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
        Right := Left + Width;
      end
      else
      begin
        Exit;
      end;
      if ImageKindY = ikyTopFill then
      begin
        Top := HitTestBounds.Top;
        Bottom := HitTestBounds.Bottom;
      end
      else if ImageKindY = ikyBottomFill then
      begin
        Bottom := HitTestBounds.Bottom;
        Top := Bottom;
        while Top > Clip.Top do
          Dec(Top, Height);
      end
      else if ImageKindY = ikyTop then
      begin
        Top := HitTestBounds.Top;
        Bottom := Top + Height;
      end
      else if ImageKindY = ikyBottom then
      begin
        Bottom := HitTestBounds.Bottom;
        Top := Bottom - Height;
      end
      else if ImageKindY = ikyCenter then
      begin
        Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
        Bottom := Top + Height;
      end
      else
      begin
        Exit;
      end;
      Bounds := Image.GetBoundsRect;
      Y := Top;
      while Y < Bottom do
      begin
        X := Left;
        while X < Right do
        begin
          FrameIndex := LastCachedFrameIndex + 1;
          if FrameIndex > SequenceFrame then
            FrameIndex := 0;
          while FrameIndex <= SequenceFrame do
          begin
            Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
            if Frame <> nil then
            begin
              FrameBounds := Frame.GetBoundsRect;
              RectCount := Frame.GetClipRectCount;
              if RectCount < 1 then
              begin
                inherited Invalidate;
                Exit;
              end;
              for RectIndex := 0 to RectCount - 1 do
              begin
                Rect := Frame.GetClipRect(RectIndex);
                Rect.Left := X + Rect.Left + (FrameBounds.Left - Bounds.Left);
                Rect.Top := Y + Rect.Top + (FrameBounds.Top - Bounds.Top);
                Rect.Right := X + Rect.Right + (FrameBounds.Left - Bounds.Left);
                Rect.Bottom := Y + Rect.Bottom + (FrameBounds.Top - Bounds.Top);
                MessageLoop.QueueUpdateRect(Rect);
              end;
            end;
            Inc(FrameIndex);
          end;
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    finally
      if Image <> nil then
        MainImageCache.Release;
      if First <> nil then
        FirstFrameImageCache.Release;
    end;
  end
  else
    inherited Invalidate;
end;
procedure TgaiGI.SetHardwareMirrorHorizontal(Value: Boolean);
begin
  HardwareMirrorHorizontal := Value;
end;
procedure TgaiGI.Draw(ClipRect: TRect);
var
  Image: TCGaiEC;
  First: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y, FrameIndex, FrameCount: Integer;
  Frame: TgiGR;
  Texture: IDirect3DTexture9;
  FrameOrigin: TPoint;
  Bounds, FirstBounds: TRect;
begin
  if SequenceFrame < 0 then
    Exit;
  if (SequenceFrame >= SequenceFrameCount) and (not FirstFrameOnly) then
    Exit;
  if (AutoFrameTimer = nil) and (not StopPlaybackRequested) then
    RestartPlayback;
  if (MainImageCache.CacheKey = '')
      and ((FirstFrameImageCache = nil)
          or (FirstFrameImageCache.CacheKey = '')
          or (not FirstFrameOnly)) then
    Exit;
  Image := nil;
  First := nil;
  try
    if not FirstFrameOnly then
      Image := AcquireCachedGai(MainImageCache);
    if FirstFrameImageCache <> nil then
      First := AcquireCachedGi(FirstFrameImageCache);
    if Image <> nil then
    begin
      Width := Image.GetCanvasSize.X;
      Height := Image.GetCanvasSize.Y;
      if First <> nil then
      begin
        FirstBounds := First.Image.GetBoundsRect;
        UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
        if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then
          RaiseWideMessage('TgaiGI.Draw Pos-Size');
        Width := FirstBounds.Right - FirstBounds.Left;
        Height := FirstBounds.Bottom - FirstBounds.Top;
        if First.Image.GetFormat <> 0 then
          RaiseWideMessage('TgaiGI.Draw Format gi not 0');
      end;
    end
    else if First <> nil then
    begin
      FirstBounds := First.Image.GetBoundsRect;
      Width := FirstBounds.Right - FirstBounds.Left;
      Height := FirstBounds.Bottom - FirstBounds.Top;
      if First.Image.GetFormat <> 0 then
        RaiseWideMessage('TgaiGI.Draw Format gi not 0');
    end
    else
    begin
      Width := 0;
      Height := 0;
    end;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > ClipRect.Left do
        Dec(Left, Width);
    end
    else if ImageKindX = ikxLeft then
    begin
      Left := HitTestBounds.Left;
      Right := Left + Width;
    end
    else if ImageKindX = ikxRight then
    begin
      Right := HitTestBounds.Right;
      Left := Right - Width;
    end
    else if ImageKindX = ikxCenter then
    begin
      Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
      Right := Left + Width;
    end
    else
    begin
      Exit;
    end;
    if ImageKindY = ikyTopFill then
    begin
      Top := HitTestBounds.Top;
      Bottom := HitTestBounds.Bottom;
    end
    else if ImageKindY = ikyBottomFill then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom;
      while Top > ClipRect.Top do
        Dec(Top, Height);
    end
    else if ImageKindY = ikyTop then
    begin
      Top := HitTestBounds.Top;
      Bottom := Top + Height;
    end
    else if ImageKindY = ikyBottom then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom - Height;
    end
    else if ImageKindY = ikyCenter then
    begin
      Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
      Bottom := Top + Height;
    end
    else
    begin
      Exit;
    end;
    if Image <> nil then
      Bounds := Image.GetBoundsRect
    else if First <> nil then
      Bounds := First.Image.GetBoundsRect;

    if (Image <> nil) and (not Image.HasPlaybackFlags) then
    begin
      if HardwareRenderingEnabled then
      begin
        Texture := Image.GetOrCreateFrameSurface(GetSequenceFrameSourceIndex(SequenceFrame));
        FrameOrigin := Image.GetFrameOrigin(GetSequenceFrameSourceIndex(SequenceFrame));
        if Texture <> nil then
        begin
          Y := Top;
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              DrawTexture(
                  Texture,
                  FrameOrigin.X + X,
                  FrameOrigin.Y + Y,
                  Alpha,
                  $FFFFFF,
                  @ClipRect,
                  False,
                  HardwareMirrorHorizontal
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end;
      end
      else
      begin
        Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(SequenceFrame));
        Y := Top;
        while Y < Bottom do
        begin
          X := Left;
          while X < Right do
          begin
            if Frame <> nil then
              Frame.DrawToGraphBuf(
                  ScreenRenderBuffer,
                  X + Frame.GetBoundsRect.Left - Bounds.Left,
                  Y + Frame.GetBoundsRect.Top - Bounds.Top,
                  ClipRect,
                  0,
                  Alpha
              );
            Inc(X, Width);
          end;
          Inc(Y, Height);
        end;
      end;
    end
    else if (Image <> nil) and (not UsesPlaybackBuffer) then
    begin
      Y := Top;
      if HardwareRenderingEnabled then
      begin
        while Y < Bottom do
        begin
          X := Left;
          while X < Right do
          begin
            FrameCount := GetSequenceFrameSourceIndex(SequenceFrame);
            for FrameIndex := 0 to FrameCount - 1 do
            begin
              Texture := Image.GetOrCreateFrameSurface(GetSequenceFrameSourceIndex(SequenceFrame));
              FrameOrigin := Image.GetFrameOrigin(GetSequenceFrameSourceIndex(SequenceFrame));
              DrawTexture(
                  Texture,
                  FrameOrigin.X + X,
                  FrameOrigin.Y + Y,
                  Alpha,
                  $FFFFFF,
                  @ClipRect,
                  False,
                  HardwareMirrorHorizontal
              );
            end;
            Inc(X, Width);
          end;
          Inc(Y, Height);
        end;
      end
      else
      begin
        while Y < Bottom do
        begin
          X := Left;
          while X < Right do
          begin
            FrameCount := GetSequenceFrameSourceIndex(SequenceFrame);
            for FrameIndex := 0 to FrameCount - 1 do
            begin
              Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
              if Frame <> nil then
                Frame.DrawToGraphBuf(
                    ScreenRenderBuffer,
                    X + Frame.GetBoundsRect.Left - Bounds.Left,
                    Y + Frame.GetBoundsRect.Top - Bounds.Top,
                    ClipRect,
                    0,
                    Alpha
                );
            end;
            Inc(X, Width);
          end;
          Inc(Y, Height);
        end;
      end;
    end
    else
    begin
      if FirstFrameImageCache <> nil then
      begin
        if (CachedPlaybackGraphBuf = nil)
            or (CachedPlaybackGraphBuf.Width <> Width)
            or (CachedPlaybackGraphBuf.Height <> Height) then
        begin
          LastCachedFrameIndex := -1;
          if CachedPlaybackGraphBuf = nil then
            CachedPlaybackGraphBuf := TGraphBufGR.Create(True);
          CachedPlaybackGraphBuf.AllocateRgba(Width, Height, Width * 4);
        end;
        if LastCachedFrameIndex <> SequenceFrame then
        begin
          FrameIndex := LastCachedFrameIndex + 1;
          if FrameIndex > SequenceFrame then
            FrameIndex := 0;
          if FrameIndex = 0 then
            CopyMemory(
                CachedPlaybackGraphBuf.GetPixels,
                AddPointerOffset(First.Image.Data, First.Image.GetPlane(0).DataOffset),
                CachedPlaybackGraphBuf.PitchBytes * CachedPlaybackGraphBuf.Height
            );
          if Image <> nil then
          begin
            while FrameIndex <= SequenceFrame do
            begin
              Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
              if (Frame <> nil)
                  and (Frame.GetContentSize.X > 0)
                  and (Frame.GetContentSize.Y > 0) then
                Frame.DrawToGraphBuf(
                    CachedPlaybackGraphBuf,
                    Frame.GetBoundsRect.Left - Bounds.Left,
                    Frame.GetBoundsRect.Top - Bounds.Top,
                    Classes.Rect(0, 0, CachedPlaybackGraphBuf.Width, CachedPlaybackGraphBuf.Height),
                    0,
                    Alpha
                );
              Inc(FrameIndex);
            end;
          end;
          LastCachedFrameIndex := SequenceFrame;
        end;
        Y := Top;
        if HardwareRenderingEnabled then
        begin
          Texture := CachedPlaybackGraphBuf.GetTexture;
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              DrawTexture(
                  Texture,
                  X,
                  Y,
                  Alpha,
                  $FFFFFF,
                  @ClipRect,
                  False,
                  HardwareMirrorHorizontal
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end
        else
        begin
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              DrawAlphaGraphBuffer16Clipped(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  X,
                  Y,
                  CachedPlaybackGraphBuf,
                  ClipRect
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end;
      end
      else if Image <> nil then
      begin
        if (CachedPlaybackGraphBuf = nil)
            or (CachedPlaybackGraphBuf.Width <> Width)
            or (CachedPlaybackGraphBuf.Height <> Height) then
        begin
          LastCachedFrameIndex := -1;
          if CachedPlaybackGraphBuf = nil then
            CachedPlaybackGraphBuf := TGraphBufGR.Create(True);
          if HardwareRenderingEnabled then
            CachedPlaybackGraphBuf.AllocateRgba(Width, Height, Width * 4)
          else
            CachedPlaybackGraphBuf.AllocateNative(Width, Height);
        end;
        if LastCachedFrameIndex <> SequenceFrame then
        begin
          FrameIndex := LastCachedFrameIndex + 1;
          if FrameIndex > SequenceFrame then
            FrameIndex := 0;
          if (FrameIndex = 0) and (not HardwareRenderingEnabled) then
            CachedPlaybackGraphBuf.FillPixels16(TransparentColor);
          while FrameIndex <= SequenceFrame do
          begin
            Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
            if Frame <> nil then
            begin
              if HardwareRenderingEnabled then
                Frame.DecodeToPixels(
                    AddPointerOffset(
                        CachedPlaybackGraphBuf.GetPixels,
                        (Frame.GetBoundsRect.Top - Bounds.Top) * CachedPlaybackGraphBuf.PitchBytes
                            + (Frame.GetBoundsRect.Left - Bounds.Left) * 4
                    ),
                    CachedPlaybackGraphBuf.PitchBytes,
                    CachedPlaybackGraphBuf.Width,
                    CachedPlaybackGraphBuf.Height,
                    False
                )
              else
                Frame.DrawToGraphBuf(
                    CachedPlaybackGraphBuf,
                    Frame.GetBoundsRect.Left - Bounds.Left,
                    Frame.GetBoundsRect.Top - Bounds.Top,
                    Classes.Rect(0, 0, CachedPlaybackGraphBuf.Width, CachedPlaybackGraphBuf.Height),
                    0,
                    Alpha
                );
            end;
            Inc(FrameIndex);
          end;
          LastCachedFrameIndex := SequenceFrame;
        end;
        Y := Top;
        if HardwareRenderingEnabled then
        begin
          Texture := CachedPlaybackGraphBuf.GetTexture;
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              DrawTexture(
                  Texture,
                  X,
                  Y,
                  Alpha,
                  $FFFFFF,
                  @ClipRect,
                  False,
                  HardwareMirrorHorizontal
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end
        else
        begin
          while Y < Bottom do
          begin
            X := Left;
            while X < Right do
            begin
              CopyTransparentGraphBuffer16Clipped(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  X,
                  Y,
                  CachedPlaybackGraphBuf,
                  ClipRect,
                  TransparentColor
              );
              Inc(X, Width);
            end;
            Inc(Y, Height);
          end;
        end;
      end;
    end;
  finally
    if Image <> nil then
      MainImageCache.Release;
    if First <> nil then
      FirstFrameImageCache.Release;
  end;
end;
procedure TgaiGI.PrimeImageCaches;
begin
  if (MainImageCache <> nil) and (not FirstFrameOnly) and (MainImageCache.CacheKey <> '') then
  begin
    AcquireCachedGai(MainImageCache);
    MainImageCache.Release;
  end;
  if (FirstFrameImageCache <> nil) and (FirstFrameImageCache.CacheKey <> '') then
  begin
    AcquireCachedGi(FirstFrameImageCache);
    FirstFrameImageCache.Release;
  end;
end;
procedure TgaiGI.QueueImageLoad(PendingLoads: TList);
begin

  MainImageCache.QueueLoadIfMissing(PendingLoads);

end;
procedure LoadGaiFrameToGraphBuf(const Path: WideString; GraphBuf: TGraphBufGR; Seed: Cardinal);
var
  Control: TCacheControlEC;
  Gai: TCGaiEC;
  FrameIndex: Integer;
begin
  Control := TCGaiControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(Path);
  Gai := AcquireCachedGai(Control);
  try
    FrameIndex := 0;
    if Seed <> 0 then
      FrameIndex := SeededRandomIntRange(0, Gai.GetFrameCount - 1, Seed);
    Gai.LoadFrameGi(FrameIndex).DecodeToGraphBuf(GraphBuf, False);
  finally
    Control.Release;
  end;
  Control.Free;
end;
end.
