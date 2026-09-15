{$EXCESSPRECISION OFF}
unit GI_GAIFile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_File,
  EC_Thread,
  GI_Main,
  GI_MessageLoop,
  GR_gi,
  GR_GraphBuf,
  SyncObjs,
  Types;
type
  TGAIFileGI = class;
  TGAIFileThreadGI = class;
  TGAIFileThreadGI = class(TThreadEC)
    Owner: TGAIFileGI;
    procedure Execute; override;
  end;
  TGAIFileGI = class(TObjectGI)
    ImageFile: TFileEC;
    Header: TGaiHeader;
    FrameDirectory: Pointer;
    FrameBuffers: Pointer;
    LoaderThread: TGAIFileThreadGI;
    FrameLock: TCriticalSection;
    PreloadCount: Integer;
    FrameImage: TgiGR;
    FrameTimer: PCallbackTimerGI;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    Gap172: array[0..1] of Byte;
    CurrentFrame: Integer;
    SequenceFrameCount: Integer;
    SequenceFrames: Pointer;
    FrameDelays: Pointer;
    UsePlaybackBuffer: Boolean;
    Gap185: array[0..2] of Byte;
    PlaybackBuffer: TGraphBufGR;
    LastBufferedFrame: Integer;
    TransparentColor: Cardinal;
    Gap194: array[0..3] of Byte;
    CycleCompleteCallback: TObjectNotifyEventGI;
    Stopped: Boolean;
    Gap1A1: array[0..2] of Byte;
    AutoUpdateFlags: Cardinal;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnDeactivate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure OpenImage;
    procedure CloseImage;
    function GetFrameData(FrameIndex: Integer): Pointer;
    procedure TrimFrameCache;
    function GetFrameCount: Integer;
    function GetContentSize: TPoint;
    function GetContentOrigin: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetFrameSequence(Sequence: WideString);
    function GetSequenceFrame(Index: Integer): Integer;
    function GetFrameDelay(Index: Integer): Integer;
    procedure LoadImageProperties(Block: TBlockParEC);
    procedure AdvanceFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  Math,
  Windows,
  Classes,
  EC_Mem,
  EC_Str,
  GR_Main,
  EC_Struct;

procedure TGAIFileThreadGI.Execute;
var
  Index, Count, SourceFrame: Integer;
  Data: Pointer;
begin
  while not IsStopRequested do
  begin
    Count := 0;
    for Index := 0 to Owner.Header.FrameCount - 1 do
      if PPointer(AddPointerOffset(Owner.FrameBuffers, Index * SizeOf(Pointer)))^ <> nil then
        Inc(Count);
    if Count >= Owner.PreloadCount then
      Break;
    Owner.FrameLock.Enter;
    Index := Owner.CurrentFrame;
    Owner.FrameLock.Leave;
    Count := 0;
    while Count < Owner.GetFrameCount do
    begin
      if PPointer(
              AddPointerOffset(
                  Owner.FrameBuffers,
                  Owner.GetSequenceFrame(Index) * SizeOf(Pointer)
              ))^
          = nil then
        Break;
      Inc(Index);
      if Index >= Owner.GetFrameCount then
        Index := 0;
      Inc(Count);
    end;
    if Count >= Owner.GetFrameCount then
      Break;
    SourceFrame := Owner.GetSequenceFrame(Index);
    if IsStopRequested then
      Break;
    Data := AllocEC(ReadDWordEC(AddPointerOffset(Owner.FrameDirectory, SourceFrame * 8 + 4)));
    Owner
        .ImageFile
        .SetPointer(ReadDWordEC(AddPointerOffset(Owner.FrameDirectory, SourceFrame * 8)), 0);
    Owner
        .ImageFile
        .ReadBuffer(Data, ReadDWordEC(AddPointerOffset(Owner.FrameDirectory, SourceFrame * 8 + 4)));
    PrepareRawGiColorCache(Data);
    if IsStopRequested then
    begin
      FreeEC(Data);
      Exit;
    end;
    Owner.FrameLock.Enter;
    PPointer(AddPointerOffset(Owner.FrameBuffers, SourceFrame * SizeOf(Pointer)))^ := Data;
    Owner.FrameLock.Leave;
  end;
end;

constructor TGAIFileGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FrameLock := TCriticalSection.Create;
  FrameImage := TgiGR.Create;
  ImageFile := TFileEC.Create;
  LoaderThread := TGAIFileThreadGI.Create;
  LoaderThread.Owner := Self;
  LoaderThread.SetPriority(1);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  Stopped := False;
  PreloadCount := 10;
  TransparentColor := 0;
end;

destructor TGAIFileGI.Destroy;
begin
  CloseImage;
  if LoaderThread <> nil then
  begin
    LoaderThread.Free;
    LoaderThread := nil;
  end;
  if FrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := nil;
  end;
  if SequenceFrames <> nil then
  begin
    FreeEC(SequenceFrames);
    SequenceFrames := nil;
  end;
  if FrameDelays <> nil then
  begin
    FreeEC(FrameDelays);
    FrameDelays := nil;
  end;
  if ImageFile <> nil then
  begin
    ImageFile.Free;
    ImageFile := nil;
  end;
  if FrameImage <> nil then
  begin
    FrameImage.Free;
    FrameImage := nil;
  end;
  if FrameLock <> nil then
  begin
    FrameLock.Free;
    FrameLock := nil;
  end;
  if PlaybackBuffer <> nil then
  begin
    PlaybackBuffer.Free;
    PlaybackBuffer := nil;
  end;
  inherited Destroy;
end;

procedure TGAIFileGI.Clear;
begin
  CloseImage;
  inherited Clear;
end;

procedure TGAIFileGI.OpenImage;
begin
  CloseImage;
  ImageFile.AcquireReadHandle(False);
  ImageFile.ReadBuffer(@Header, $30);
  FrameDirectory := ReAllocREC(FrameDirectory, Header.FrameCount * 8);
  ImageFile.ReadBuffer(FrameDirectory, Header.FrameCount * 8);
  FrameBuffers := AllocClearEC(Header.FrameCount * SizeOf(Pointer));
  LoaderThread.Start;
end;

procedure TGAIFileGI.CloseImage;
var
  Data: Pointer;
  I: Integer;
begin
  if (LoaderThread <> nil) and LoaderThread.IsRunning then
  begin
    LoaderThread.RequestStop;
    LoaderThread.WaitForIdle($FFFFFFFF);
  end;
  if (ImageFile <> nil) and (ImageFile.OpenDepth > 0) then
    ImageFile.ReleaseHandle;
  if FrameDirectory <> nil then
  begin
    FreeEC(FrameDirectory);
    FrameDirectory := nil;
  end;
  if FrameBuffers <> nil then
  begin
    for I := 0 to Header.FrameCount - 1 do
    begin
      Data := PPointer(AddPointerOffset(FrameBuffers, I * SizeOf(Pointer)))^;
      if Data <> nil then
        FreeEC(Data);
    end;
    FreeEC(FrameBuffers);
    FrameBuffers := nil;
  end;
end;

function TGAIFileGI.GetFrameData(FrameIndex: Integer): Pointer;
var
  Data: Pointer;
begin
  FrameLock.Enter;
  Data := PPointer(AddPointerOffset(FrameBuffers, FrameIndex * SizeOf(Pointer)))^;
  FrameLock.Leave;
  if Data <> nil then
  begin
    Result := Data;
    Exit;
  end;
  if LoaderThread.IsRunning then
  begin
    LoaderThread.RequestStop;
    LoaderThread.WaitForIdle($FFFFFFFF);
  end;
  Data := PPointer(AddPointerOffset(FrameBuffers, FrameIndex * SizeOf(Pointer)))^;
  if Data <> nil then
  begin
    Result := Data;
    Exit;
  end;
  begin
    Data := AllocEC(ReadDWordEC(AddPointerOffset(FrameDirectory, FrameIndex * 8 + 4)));
    ImageFile.SetPointer(ReadDWordEC(AddPointerOffset(FrameDirectory, FrameIndex * 8)), 0);
    ImageFile.ReadBuffer(Data, ReadDWordEC(AddPointerOffset(FrameDirectory, FrameIndex * 8 + 4)));
    PrepareRawGiColorCache(Data);
    PPointer(AddPointerOffset(FrameBuffers, FrameIndex * SizeOf(Pointer)))^ := Data;
    LoaderThread.Start;
  end;
  Result := Data;
end;

procedure TGAIFileGI.TrimFrameCache;
var
  I, J, Index: Integer;
  Data: Pointer;
begin
  if LoaderThread.IsRunning then
  begin
    LoaderThread.RequestStop;
    LoaderThread.WaitForIdle($FFFFFFFF);
  end;
  if SequenceFrameCount > PreloadCount then
  begin
    for I := 0 to Header.FrameCount - 1 do
    begin
      Data := PPointer(AddPointerOffset(FrameBuffers, I * SizeOf(Pointer)))^;
      if Data <> nil then
      begin
        Index := CurrentFrame;
        J := 0;
        while J < PreloadCount do
        begin
          if GetSequenceFrame(Index) = I then
            Break;
          Inc(Index);
          if Index >= SequenceFrameCount then
            Index := 0;
          Inc(J);
        end;
        if J >= PreloadCount then
        begin
          FreeEC(Data);
          PPointer(AddPointerOffset(FrameBuffers, I * SizeOf(Pointer)))^ := nil;
        end;
      end;
    end;
    LoaderThread.Start;
  end;
end;

function TGAIFileGI.GetFrameCount: Integer;
begin
  if ImageFile.GetFileName = '' then
    Result := 0
  else
  begin
    if ImageFile.OpenDepth < 1 then
      OpenImage;
    Result := Header.FrameCount;
  end;
end;

function TGAIFileGI.GetContentSize: TPoint;
begin
  if ImageFile.GetFileName = '' then
    Result := Classes.Point(0, 0)
  else
  begin
    if ImageFile.OpenDepth < 1 then
      OpenImage;
    Result := SubtractPoints(Header.Bounds.BottomRight, Header.Bounds.TopLeft);
  end;
end;

function TGAIFileGI.GetContentOrigin: TPoint;
begin
  if ImageFile.GetFileName = '' then
    Result := Classes.Point(0, 0)
  else
  begin
    if ImageFile.OpenDepth < 1 then
      OpenImage;
    Result := Header.Bounds.TopLeft;
  end;
end;

procedure TGAIFileGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;

procedure TGAIFileGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;

procedure TGAIFileGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
end;

procedure TGAIFileGI.SetFrameSequence(Sequence: WideString);
var
  Text: WideString;
  I, Count, J, FrameCount, Delay, First, Last: Integer;
begin
  if LoaderThread.IsRunning then
  begin
    LoaderThread.RequestStop;
    LoaderThread.WaitForIdle($FFFFFFFF);
  end;
  if SequenceFrames <> nil then
  begin
    FreeEC(SequenceFrames);
    SequenceFrames := nil;
  end;
  if FrameDelays <> nil then
  begin
    FreeEC(FrameDelays);
    FrameDelays := nil;
  end;
  CurrentFrame := 0;
  SequenceFrameCount := 0;
  Count := (CountDelimitedPartsW(Sequence, '[]') - 1) div 2;
  for I := 0 to Count - 1 do
  begin
    Text := ExtractDelimitedPartW(Sequence, I * 2 + 1, '[]');
    Delay := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ',-'));
    First := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ',-'));
    Last := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ',-'));
    FrameCount := Abs(First - Last) + 1;
    SequenceFrameCount := SequenceFrameCount + FrameCount;
    SequenceFrames := ReAllocREC(SequenceFrames, SequenceFrameCount * SizeOf(Integer));
    FrameDelays := ReAllocREC(FrameDelays, SequenceFrameCount * SizeOf(Integer));
    for J := 0 to FrameCount - 1 do
    begin
      WriteInt32EC(
          AddPointerOffset(SequenceFrames, (SequenceFrameCount - FrameCount + J) * SizeOf(Integer)),
          First
      );
      WriteInt32EC(
          AddPointerOffset(FrameDelays, (SequenceFrameCount - FrameCount + J) * SizeOf(Integer)),
          Delay
      );
      if First < Last then
        Inc(First)
      else
        Dec(First);
    end;
  end;
  if not Stopped then
    FrameTimer :=
        MessageLoop.ScheduleCallbackTimer(GetFrameDelay(CurrentFrame), $FFFFFF, AdvanceFrame);
end;

function TGAIFileGI.GetSequenceFrame(Index: Integer): Integer;
begin
  Result := ReadIntegerEC(AddPointerOffset(SequenceFrames, Index * SizeOf(Integer)));
end;

function TGAIFileGI.GetFrameDelay(Index: Integer): Integer;
begin
  Result := ReadIntegerEC(AddPointerOffset(FrameDelays, Index * SizeOf(Integer)));
end;

procedure TGAIFileGI.OnDeactivate;
begin
  inherited OnDeactivate;
  CloseImage;
  if PlaybackBuffer <> nil then
  begin
    PlaybackBuffer.Free;
    PlaybackBuffer := nil;
  end;
end;

procedure TGAIFileGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TGAIFileGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;

procedure TGAIFileGI.LoadImageProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then
    ImageFile.SetFileName(Block.GetParam('Image'));
  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
  if Block.CountParams('PBuf') > 0 then
    UsePlaybackBuffer := ParseEnabledNameGI(Block.GetParam('PBuf'));
  if Block.CountParams('Stop') > 0 then
    Stopped := ParseEnabledNameGI(Block.GetParam('Stop'));
  if Block.CountParams('Frame') > 0 then
    SetFrameSequence(Block.GetParam('Frame'));
  if Block.CountParams('Auto') > 0 then
    AutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
  if Block.CountParams('TransColor') > 0 then
    TransparentColor := GetColorGI(Block.GetParam('TransColor'));
end;

procedure TGAIFileGI.UpdateAutoGeometry;
begin
  if AutoUpdateFlags and agfPosition = agfPosition then
    SetPosition(Parent.ToLocalPoint(GetContentOrigin));
  if AutoUpdateFlags and agfSize = agfSize then
    SetSize(GetContentSize);
end;

procedure TGAIFileGI.AdvanceFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  FrameLock.Enter;
  Inc(CurrentFrame);
  if CurrentFrame >= SequenceFrameCount then
  begin
    CurrentFrame := 0;
    FrameLock.Leave;
    if Assigned(CycleCompleteCallback) then
      CycleCompleteCallback(Self);
  end
  else
    FrameLock.Leave;
  if FrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := nil;
  end;
  if not Stopped then
    FrameTimer :=
        MessageLoop.ScheduleCallbackTimer(GetFrameDelay(CurrentFrame), $FFFFFF, AdvanceFrame);
  Invalidate;
end;

procedure TGAIFileGI.Draw(ClipRect: TRect);
var
  Data: Pointer;
  Width, Height, StartX, EndX, X, StartY, EndY, Y, Frame, SourceFrame: Integer;
  Bounds: TRect;
begin
  if (CurrentFrame < 0) or (CurrentFrame >= SequenceFrameCount) then
    Exit;
  if ImageFile.GetFileName = '' then
    Exit;
  if ImageFile.OpenDepth < 1 then
    OpenImage;
  Width := GetContentSize.X;
  Height := GetContentSize.Y;
  if ImageKindX = ikxLeftFill then
  begin
    StartX := HitTestBounds.Left;
    EndX := HitTestBounds.Right;
  end
  else if ImageKindX = ikxRightFill then
  begin
    EndX := HitTestBounds.Right;
    StartX := EndX;
    while StartX > ClipRect.Left do
      StartX := StartX - Width;
  end
  else if ImageKindX = ikxLeft then
  begin
    StartX := HitTestBounds.Left;
    EndX := StartX + Width;
  end
  else if ImageKindX = ikxRight then
  begin
    EndX := HitTestBounds.Right;
    StartX := EndX - Width;
  end
  else if ImageKindX = ikxCenter then
  begin
    StartX := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
    EndX := StartX + Width;
  end
  else
    Exit;
  if ImageKindY = ikyTopFill then
  begin
    StartY := HitTestBounds.Top;
    EndY := HitTestBounds.Bottom;
  end
  else if ImageKindY = ikyBottomFill then
  begin
    EndY := HitTestBounds.Bottom;
    StartY := EndY;
    while StartY > ClipRect.Top do
      StartY := StartY - Height;
  end
  else if ImageKindY = ikyTop then
  begin
    StartY := HitTestBounds.Top;
    EndY := StartY + Height;
  end
  else if ImageKindY = ikyBottom then
  begin
    EndY := HitTestBounds.Bottom;
    StartY := EndY - Height;
  end
  else if ImageKindY = ikyCenter then
  begin
    StartY := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
    EndY := StartY + Height;
  end
  else
    Exit;
  Bounds := Header.Bounds;
  if Header.Flags = 0 then
  begin
    SourceFrame := GetSequenceFrame(CurrentFrame);
    Data := GetFrameData(SourceFrame);
    FrameImage.LoadRawGiBytes(
        Data,
        ReadDWordEC(AddPointerOffset(FrameDirectory, SourceFrame * SizeOf(TGaiFrameEntry) + 4))
    );
    TrimFrameCache;
    Y := StartY;
    while Y < EndY do
    begin
      X := StartX;
      while X < EndX do
      begin
        FrameImage.DrawToGraphBuf(
            ScreenRenderBuffer,
            X + FrameImage.GetBoundsRect.Left - Bounds.Left,
            Y + FrameImage.GetBoundsRect.Top - Bounds.Top,
            ClipRect,
            0,
            255
        );
        X := X + Width;
      end;
      Y := Y + Height;
    end;
  end
  else if UsePlaybackBuffer then
  begin
    if (PlaybackBuffer = nil)
        or (PlaybackBuffer.Width <> Width)
        or (PlaybackBuffer.Height <> Height) then
    begin
      LastBufferedFrame := -1;
      if PlaybackBuffer = nil then
        PlaybackBuffer := TGraphBufGR.Create(False);
      PlaybackBuffer.AllocateNative(Width, Height);
    end;
    if LastBufferedFrame <> CurrentFrame then
    begin
      Frame := LastBufferedFrame + 1;
      if Frame > CurrentFrame then
        Frame := 0;
      if Frame = 0 then
        PlaybackBuffer.FillPixels16(TransparentColor);
      while Frame <= CurrentFrame do
      begin
        SourceFrame := GetSequenceFrame(Frame);
        Data := GetFrameData(SourceFrame);
        FrameImage.LoadRawGiBytes(
            Data,
            ReadDWordEC(AddPointerOffset(FrameDirectory, SourceFrame * SizeOf(TGaiFrameEntry) + 4))
        );
        FrameImage.DrawToGraphBuf(
            PlaybackBuffer,
            FrameImage.GetBoundsRect.Left - Bounds.Left,
            FrameImage.GetBoundsRect.Top - Bounds.Top,
            Classes.Rect(0, 0, PlaybackBuffer.Width, PlaybackBuffer.Height),
            0,
            255
        );
        Inc(Frame);
      end;
      TrimFrameCache;
      LastBufferedFrame := CurrentFrame;
    end;
    Y := StartY;
    while Y < EndY do
    begin
      X := StartX;
      while X < EndX do
      begin
        CopyTransparentGraphBuffer16Clipped(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            X,
            Y,
            PlaybackBuffer,
            ClipRect,
            TransparentColor
        );
        X := X + Width;
      end;
      Y := Y + Height;
    end;
  end;
end;

end.
