{$EXCESSPRECISION OFF}
unit SE_Space;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Buf,
  EC_Struct,
  GI_Circle,
  GI_GI,
  GI_MessageLoop,
  GI_Panel,
  GR_Sound,
  SE_SoundRnd,
  GI_Frame,
  GI_StarField,
  GI_StarFieldM,
  GI_StarFieldImg,
  GI_SpaceImg,
  Types;
type
  TObjectSE = class;
  TSpaceSE = class;
  PointerToTSpaceTimerSE = ^TSpaceTimerSE;
  TSpaceScrollEventSE = procedure of object;
  TObjectSE = class(TObjectEx)
    Prev: TObjectSE;
    Next: TObjectSE;
    ProcessPrev: TObjectSE;
    ProcessNext: TObjectSE;
    Space: TSpaceSE;
    GraphKey: WideString;
    Size: TPoint;
    Position: TPointF;
    DepthExpression: WideString;
    SoundLoopPath: WideString;
    SoundGroup: Integer;
    LoopSound: TSoundBufferControl;
    RandomSound: TSoundRndSE;
    RandomSoundGroup: Integer;
    NextSoundTime: Cardinal;
    RefCount: Integer;
    procedure CopyTo(Destination: TObjectSE); virtual;
    procedure AttachToSpace(ASpace: TSpaceSE); virtual;
    procedure DetachFromSpace; virtual;
    procedure SetPosition(APosition: TPointF); virtual;
    procedure SetDepth(Value: Single); virtual;
    function GetDepth: Single; virtual;
    procedure SetOrbitCenter(Center: TPointF); virtual;
    function GetOrbitCenter: TPointF; virtual;
    function GetAlpha: Byte; virtual;
    procedure SetAlpha(Value: Byte); virtual;
    function GetAngle: Byte; virtual;
    procedure SetAngle(Value: Byte); virtual;
    function GetText: WideString; virtual;
    procedure SetText(const Value: WideString); virtual;
    function BuildStateBuffer: TBufEC; virtual;
    procedure LoadStateBuffer(Buffer: TBufEC); virtual;
    procedure Advance; virtual;
    procedure SetSize(Value: TPoint); virtual;
    function HitTestCursor: Boolean; virtual;
    procedure DrawMap; virtual;
    procedure LoadTemplate(Block: TBlockParEC); virtual;
    procedure ApplyConfig(Block: TBlockParEC); virtual;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); virtual;
    constructor CreateEmpty;
    constructor Create(const AGraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    function IsAttachedToSpace: Boolean;
    procedure ConfigureLoopSound(const Name: WideString);
    procedure ConfigureRandomSound(const Name: WideString);
  end;
  PSpaceTimerSE = PointerToTSpaceTimerSE;
  TSpaceTimerEventSE = procedure(Timer: PSpaceTimerSE; UserData: Integer) of object;
  TSpaceTimerSE = packed record
    Prev: PSpaceTimerSE;
    Next: PSpaceTimerSE;
    TicksRemaining: Integer;
    RepeatTicks: Integer;
    Callback: TSpaceTimerEventSE;
    UserData: Integer;
    Gap1C: array[0..3] of Byte;
  end;
  TSpaceSE = class(TObject)
    FirstObject: TObjectSE;
    LastObject: TObjectSE;
    FirstTimer: PSpaceTimerSE;
    LastTimer: PSpaceTimerSE;
    NextTimerToProcess: PSpaceTimerSE;
    MinimapScale: Double;
    MapPanel: TPanelGI;
    MinimapControl: TObjectGI;
    MinimapViewportFrame: TFrameGI;
    Screen: TMessageLoopGI;
    MinimapBackground: TgiGI;
    MinimapRangeShade: TCircleGI;
    MinimapRangeCircle: TCircleGI;
    StarField: TStarFieldGI;
    StarFieldM: TStarFieldMGI;
    SpaceImages: TSpaceImgGI;
    StarFieldImages: TStarFieldImgGI;
    MinimapDragging: Boolean;
    Gap4D: array[0..2] of Byte;
    Process: TObject;
    Gap54: array[0..3] of Byte;
    ScrollChangedCallback: TSpaceScrollEventSE;
    PathPoints: PPointF;
    PathPointCount: Integer;
    AlphaShift: Integer;
    constructor Create(AMapPanel: TPanelGI; AScreen: TMessageLoopGI);
    destructor Destroy; override;
    procedure LinkObject(Obj: TObjectSE);
    procedure UnlinkObject(Obj: TObjectSE);
    function CreateTimer(
        DelayMs: Integer;
        RepeatMs: Integer;
        Callback: TSpaceTimerEventSE;
        UserData: Integer
    ): PSpaceTimerSE;
    procedure DeleteTimer(Timer: PSpaceTimerSE);
    procedure AdvanceTimers;
    procedure AdvanceObjects;
    procedure ClearPath;
    procedure SetPath(Points: PPointF; Count: Integer);
    procedure DrawMinimap;
    procedure CreateMinimapViewport;
    procedure FreeMinimapViewport;
    procedure MapScrollChanged(Sender: TObjectGI);
    procedure MinimapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MinimapMouseEnter(Sender: TObjectGI);
    procedure MinimapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    function ContainsMapPoint(Point: TPointF): Boolean;
  end;
procedure RetainSpaceObject(var Dest: TObjectSE; Source: TObjectSE);
procedure ReleaseSpaceObject(var Obj: TObjectSE);
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Windows,
  SysUtils,
  MMSystem,
  EC_Str,
  GR_Main,
  Globals,
  GlobalsV,
  aMyFunction,
  SE_Process,
  SE_Weapon,
  aEFilm,
  aEFilmEnd,
  EC_Mem,
  GI_Main,
  GR_GraphBuf,
  SE_Star,
  SE_Planet,
  GI_GraphButton,
  fStarMap,
  fFilm;

constructor TObjectSE.CreateEmpty;
begin
  inherited Create;
end;

constructor TObjectSE.Create(const AGraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create;
  GraphKey := AGraphKey;
  LoadTemplate(GameDataConfig.GetBlockByPath('SE.' + ExtractDelimitedPartW(AGraphKey, 0, ',')));
end;

destructor TObjectSE.Destroy;
var
  Obj: TObjectSE;
begin
  DetachFromSpace;
  if GetCurrentThreadId = MainRuntimeThreadId then
    if SpaceProcess <> nil then
      if SpaceProcess.Space <> nil then
      begin
        Obj := TSpaceSE(SpaceProcess.Space).FirstObject;
        while Obj <> nil do
        begin
          if Obj is TWeaponSE then
            if Obj.IsAttachedToSpace then
              if (TWeaponSE(Obj).SourceObject = Self) or (TWeaponSE(Obj).TargetObject = Self) then
                Obj.DetachFromSpace;
          Obj := Obj.Next;
        end;
      end;
  if PrimaryFilm <> nil then
    PrimaryFilm.ReleaseObjectReferences(Self);
  if SecondaryFilm <> nil then
    SecondaryFilm.ReleaseObjectReferences(Self);
  if TrailingFilmEffects <> nil then
    TrailingFilmEffects.ReleaseObjectReferences(Self);
  inherited Destroy;
end;

procedure RetainSpaceObject(var Dest: TObjectSE; Source: TObjectSE);
begin
  Dest := Source;
  if Source <> nil then
    Inc(Source.RefCount);
end;

procedure ReleaseSpaceObject(var Obj: TObjectSE);
var
  Previous: TObjectSE;
begin
  Previous := Obj;
  Obj := nil;
  if Previous <> nil then
  begin
    Dec(Previous.RefCount);
    if Previous.RefCount <= 0 then
      Previous.Free;
  end;
end;

procedure TObjectSE.CopyTo(Destination: TObjectSE);
begin
  Destination.GraphKey := GraphKey;
  Destination.Size := Size;
  Destination.Position := Position;
  Destination.DepthExpression := DepthExpression;
end;

procedure TObjectSE.AttachToSpace(ASpace: TSpaceSE);
begin
  ASpace.LinkObject(Self);
  Space := ASpace;
  if SoundLoopPath <> '' then
  begin
    LoopSound := TSoundBufferControl.Create;
    LoopSound.Configure(SoundLoopPath, SoundGroup, True);
  end;
end;

procedure TObjectSE.DetachFromSpace;
begin
  if LoopSound <> nil then
  begin
    LoopSound.Free;
    LoopSound := nil;
  end;
  if IsAttachedToSpace then
  begin
    Space.UnlinkObject(Self);
    Space := nil;
  end;
end;

function TObjectSE.IsAttachedToSpace: Boolean;
begin
  if Space = nil then
    Result := False
  else
    Result := True;
end;

procedure TObjectSE.SetPosition(APosition: TPointF);
begin
  Position := APosition;
end;

procedure TObjectSE.SetDepth(Value: Single);
begin
end;

function TObjectSE.GetDepth: Single;
begin
  Result := 0;
end;

procedure TObjectSE.SetOrbitCenter(Center: TPointF);
begin
end;

function TObjectSE.GetOrbitCenter: TPointF;
begin
  Result := MakePointF(0, 0);
end;

function TObjectSE.GetAlpha: Byte;
begin
  Result := 0;
end;

procedure TObjectSE.SetAlpha(Value: Byte);
begin
end;

function TObjectSE.GetAngle: Byte;
begin
  Result := 0;
end;

procedure TObjectSE.SetAngle(Value: Byte);
begin
end;

function TObjectSE.GetText: WideString;
begin
  Result := '';
end;

procedure TObjectSE.SetText(const Value: WideString);
begin
end;

function TObjectSE.BuildStateBuffer: TBufEC;
begin
  Result := nil;
end;

procedure TObjectSE.LoadStateBuffer(Buffer: TBufEC);
begin
end;

procedure TObjectSE.Advance;
var
  Distance: Single;
  Now: Cardinal;
  Delay: Integer;
begin
  if IsAttachedToSpace then
  begin
    if LoopSound <> nil then
    begin
      Distance := PointDistance(Position, SpaceViewPosition) / (Cardinal(GameScreenHeight) / 2);
      if Distance > 1 then
        LoopSound.SetVolume(0)
      else
        LoopSound.SetVolume((1 - Distance) * 0.5 + 0.5);
    end;
    try
      if RandomSound <> nil then
        if RandomSoundGroup >= 0 then
        begin
          Now := timeGetTime;
          if NextSoundTime < Now then
          begin
            Delay :=
                RandomIntRange(
                    RandomSound.Groups[RandomSoundGroup].NextTimeMin,
                    RandomSound.Groups[RandomSoundGroup].NextTimeMax
                );
            NextSoundTime := Now + Delay;
            if Space.ContainsMapPoint(Position) then
              SoundManager.PlayEffect(
                  RandomSound.SelectSound(RandomSoundGroup),
                  RandomSound.Groups[RandomSoundGroup].Group,
                  1,
                  0
              );
          end;
        end;
    except
      on E: Exception do
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
    end;
  end;
end;

procedure TObjectSE.SetSize(Value: TPoint);
begin
  Size := Value;
end;

function TObjectSE.HitTestCursor: Boolean;
begin
  Result := False;
end;

procedure TObjectSE.DrawMap;
begin
end;

procedure TObjectSE.ConfigureLoopSound(const Name: WideString);
var
  Block: TBlockParEC;
  Count, Index, Weight: Integer;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Sound.Loop.' + Name);
  Weight := 0;
  Count := Block.GetParamCount;
  if Count >= 1 then
  begin
    for Index := 0 to Count - 1 do
      Inc(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
    Weight := RandomIntRange(0, Weight - 1);
    for Index := 0 to Count - 1 do
    begin
      Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
      if Weight < 0 then
      begin
        SoundLoopPath := Block.GetParamValue(Index);
        SoundGroup := ExtractDigitsToIntW(ExtractDelimitedPartW(SoundLoopPath, 0, ','));
        SoundLoopPath := ExtractDelimitedPartW(SoundLoopPath, 1, ',');
        Exit;
      end;
    end;
  end;
  SoundLoopPath := '';
  SoundGroup := 0;
end;

procedure TObjectSE.ConfigureRandomSound(const Name: WideString);
begin
  RandomSound := FindRandomSound(Name, RandomSoundGroup);
  if RandomSoundGroup >= 0 then
    NextSoundTime :=
        timeGetTime
            + RandomIntRange(
                RandomSound.Groups[RandomSoundGroup].NextTimeMin,
                RandomSound.Groups[RandomSoundGroup].NextTimeMax);
end;

procedure TObjectSE.LoadTemplate(Block: TBlockParEC);
begin
  if Block.CountParams('PosZ') > 0 then
    DepthExpression := Block.GetParam('PosZ');
  if Block.CountParams('SoundLoop') > 0 then
    SoundLoopPath := Block.GetParam('SoundLoop');
  if Block.CountParams('SoundGroup') > 0 then
    SoundGroup := ExtractDigitsToIntW(Block.GetParam('SoundGroup'));
end;

procedure TObjectSE.ApplyConfig(Block: TBlockParEC);
var
  Text: WideString;
begin
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    SetPosition(
        MakePointF(
            ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ',')),
            ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 1, ','))
        )
    );
  end;
end;

procedure TObjectSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;

constructor TSpaceSE.Create(AMapPanel: TPanelGI; AScreen: TMessageLoopGI);
begin
  inherited Create;
  MapPanel := AMapPanel;
  Screen := AScreen;
  MinimapScale := 0.125;
  MinimapViewportFrame := nil;
  MinimapRangeShade := TCircleGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapRangeShade do
  begin
    SetKind(ckShrLight);
    SetPosition(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetOrigin(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
    SetShrLightInner(0);
    SetShrLightOuter(1);
  end;
  MinimapRangeCircle := TCircleGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapRangeCircle do
  begin
    SetKind(ckCircle);
    SetPosition(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetOrigin(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  MinimapBackground := TgiGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapBackground do
  begin
    SetImagePath('Bm.PanelSpace2.' + GiResourceSuffix + 'RadarT');
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  StarField := TStarFieldGI(Screen.FindControlByPath('StarField'));
  StarFieldM := TStarFieldMGI(Screen.FindControlByPath('StarFieldM'));
  SpaceImages := TSpaceImgGI(Screen.FindControlByPath('SpaceImg'));
  StarFieldImages := TStarFieldImgGI(Screen.FindControlByPath('StarFieldImg'));
  AlphaShift := 0;
end;

destructor TSpaceSE.Destroy;
begin
  ClearPath;
  MinimapRangeShade.Free;
  MinimapRangeShade := nil;
  MinimapRangeCircle.Free;
  MinimapRangeCircle := nil;
  MinimapBackground.Free;
  MinimapBackground := nil;
  StarField := nil;
  StarFieldM := nil;
  SpaceImages := nil;
  StarFieldImages := nil;
  while FirstObject <> nil do
    LastObject.DetachFromSpace;
  MapPanel := nil;
  if FirstTimer <> nil then
    raise Exception.Create('destructor TSpaceSE.Destroy;');
  inherited Destroy;
end;

procedure TSpaceSE.LinkObject(Obj: TObjectSE);
begin
  if LastObject <> nil then
    LastObject.Next := Obj;
  Obj.Prev := LastObject;
  Obj.Next := nil;
  LastObject := Obj;
  if FirstObject = nil then
    FirstObject := Obj;
end;

procedure TSpaceSE.UnlinkObject(Obj: TObjectSE);
begin
  if Obj.Prev <> nil then
    Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then
    Obj.Next.Prev := Obj.Prev;
  if LastObject = Obj then
    LastObject := Obj.Prev;
  if FirstObject = Obj then
    FirstObject := Obj.Next;
end;

function TSpaceSE.CreateTimer(
    DelayMs, RepeatMs: Integer;
    Callback: TSpaceTimerEventSE;
    UserData: Integer
): PSpaceTimerSE;
var
  Timer: PSpaceTimerSE;
begin
  Timer := AllocEC(SizeOf(TSpaceTimerSE));
  if LastTimer <> nil then
    LastTimer.Next := Timer;
  Timer.Prev := LastTimer;
  Timer.Next := nil;
  LastTimer := Timer;
  if FirstTimer = nil then
    FirstTimer := Timer;
  Timer.TicksRemaining := Round(DelayMs / 18);
  Timer.RepeatTicks := Round(RepeatMs / 18);
  Timer.Callback := Callback;
  Timer.UserData := UserData;
  Result := Timer;
end;

procedure TSpaceSE.DeleteTimer(Timer: PSpaceTimerSE);
var
  Entry: PSpaceTimerSE;
begin
  Entry := Timer;
  if NextTimerToProcess = Entry then
    raise Exception.Create('procedure TSpaceSE.ST_Delete(id:DWORD);');
  if Entry.Prev <> nil then
    Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry.Prev;
  if LastTimer = Entry then
    LastTimer := Entry.Prev;
  if FirstTimer = Entry then
    FirstTimer := Entry.Next;
  FreeEC(Entry);
end;

procedure TSpaceSE.AdvanceTimers;
var
  Timer: PSpaceTimerSE;
begin
  NextTimerToProcess := FirstTimer;
  while NextTimerToProcess <> nil do
  begin
    Timer := NextTimerToProcess;
    NextTimerToProcess := NextTimerToProcess.Next;
    Dec(Timer.TicksRemaining);
    if Timer.TicksRemaining <= 0 then
    begin
      Timer.TicksRemaining := Timer.RepeatTicks;
      Timer.Callback(Timer, Timer.UserData);
    end;
  end;
  NextTimerToProcess := nil;
end;

procedure TSpaceSE.AdvanceObjects;
var
  Obj: TObjectSE;
begin
  Obj := FirstObject;
  while Obj <> nil do
  begin
    Obj.Advance;
    Obj := Obj.Next;
  end;
end;

procedure TSpaceSE.ClearPath;
begin
  if PathPoints <> nil then
  begin
    FreeEC(PathPoints);
    PathPoints := nil;
  end;
  PathPointCount := 0;
end;

procedure TSpaceSE.SetPath(Points: PPointF; Count: Integer);
begin
  ClearPath;
  if Count < 1 then
    Exit;
  PathPointCount := Count;
  PathPoints := AllocEC(Count * SizeOf(TPointF));
  CopyMemory(PathPoints, Points, Count * SizeOf(TPointF));
end;

procedure TSpaceSE.DrawMinimap;
var
  Obj: TObjectSE;
  SavedBuffer: TGraphBufGR;
  CurrentProcess: TProcessSE;
  Coordinate: PSingle;
  Index, X1, Y1, X2, Y2, CenterX, CenterY: Integer;
  Color: Cardinal;
  SavedHardware: Boolean;
  Clip: TRect;
begin
  SavedBuffer := ScreenRenderBuffer;
  ScreenRenderBuffer := RenderScratchBuffer;
  SavedHardware := HardwareRenderingEnabled;
  HardwareRenderingEnabled := False;
  CurrentProcess := Process as TProcessSE;
  Clip := Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
  MinimapBackground.HitTestBounds := Clip;
  MinimapBackground.Draw(Clip);
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if Obj is TStarSE then
      Obj.DrawMap;
    Obj := Obj.Next;
  end;
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if Obj is TPlanetSE then
      Obj.DrawMap;
    Obj := Obj.Next;
  end;
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if not (Obj is TStarSE) then
      if not (Obj is TPlanetSE) then
        Obj.DrawMap;
    Obj := Obj.Next;
  end;
  if PathPoints <> nil then
  begin
    CenterX := RenderScratchBuffer.Width shr 1;
    CenterY := RenderScratchBuffer.Height shr 1;
    Coordinate := Pointer(PathPoints);
    X1 := CenterX + Round(Coordinate^ * MinimapScale);
    Coordinate := Pointer(PtrUInt(Coordinate) + SizeOf(Single));
    Y1 := CenterY + Round(Coordinate^ * MinimapScale);
    Coordinate := Pointer(PtrUInt(Coordinate) + SizeOf(Single));
    for Index := 1 to PathPointCount - 1 do
    begin
      X2 := CenterX + Round(Coordinate^ * MinimapScale);
      Coordinate := Pointer(PtrUInt(Coordinate) + SizeOf(Single));
      Y2 := CenterY + Round(Coordinate^ * MinimapScale);
      Coordinate := Pointer(PtrUInt(Coordinate) + SizeOf(Single));
      if not Odd(Index div 199) then
        Color := CurrentPixelFormat.PackRgbBytes($C3, $31, 0)
      else
        Color := CurrentPixelFormat.PackRgbBytes($8F, $C1, 0);
      Ex_OKGR_Line_DrawClip_WORD(
          RenderScratchBuffer.GetPixels,
          RenderScratchBuffer.PitchBytes,
          X1,
          Y1,
          X2,
          Y2,
          Color,
          Clip
      );
      X1 := X2;
      Y1 := Y2;
    end;
  end;
  if CurrentProcess.RadarRange > 0 then
  begin
    MinimapRangeShade.SetCenter(
        Classes.Point(
            (RenderScratchBuffer.Width shr 1) + Round(CurrentProcess.RadarCenter.X * MinimapScale),
            (RenderScratchBuffer.Height shr 1) + Round(CurrentProcess.RadarCenter.Y * MinimapScale)
        )
    );
    MinimapRangeShade.SetRadius(Round(CurrentProcess.ActionRange * MinimapScale));
    MinimapRangeShade.HitTestBounds :=
        Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
    MinimapRangeShade
        .Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
    MinimapRangeCircle.SetCenter(
        Classes.Point(
            (RenderScratchBuffer.Width shr 1) + Round(CurrentProcess.RadarCenter.X * MinimapScale),
            (RenderScratchBuffer.Height shr 1) + Round(CurrentProcess.RadarCenter.Y * MinimapScale)
        )
    );
    MinimapRangeCircle.SetRadius(Round(CurrentProcess.ActionRange * MinimapScale));
    MinimapRangeCircle.SetColor(CurrentProcess.ActionColor);
    MinimapRangeCircle.HitTestBounds :=
        Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
    MinimapRangeCircle
        .Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  MinimapViewportFrame
      .Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  HardwareRenderingEnabled := SavedHardware;
  ScreenRenderBuffer := SavedBuffer;
end;

procedure TSpaceSE.CreateMinimapViewport;
var
  Width, Height: Integer;
begin
  FreeMinimapViewport;
  MinimapViewportFrame := TFrameGI.Create(SpaceObjectUiLoop.ContentPanel);
  MinimapViewportFrame.SetDepth(-99999);
  MinimapViewportFrame.SetKind(fkRect);
  MinimapViewportFrame.SetColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
  Width := Round(MapPanel.ClientSize.X * MinimapScale);
  Height := Round(MapPanel.ClientSize.Y * MinimapScale);
  MinimapViewportFrame.SetSize(Classes.Point(Width, Height));
  MinimapViewportFrame.SetOrigin(Classes.Point(Width div 2, Height div 2));
  MapPanel.ScrollChangedCallback := MapScrollChanged;
  MapScrollChanged(nil);
end;

procedure TSpaceSE.FreeMinimapViewport;
begin
  if MinimapViewportFrame <> nil then
  begin
    MinimapViewportFrame.Free;
    MinimapViewportFrame := nil;
  end;
end;

procedure TSpaceSE.MapScrollChanged(Sender: TObjectGI);
begin
  if Sender = MapPanel then
    FilmCameraFollow := False;
  if MinimapViewportFrame <> nil then
    MinimapViewportFrame.SetPosition(
        Classes.Point(
            Round(MapPanel.ScrollOffset.X * MinimapScale),
            Round(MapPanel.ScrollOffset.Y * MinimapScale)
        )
    );
  if StarField <> nil then
    StarField.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if Wind >= 1 then
    if StarFieldM <> nil then
      StarFieldM.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if SpaceImages <> nil then
    SpaceImages.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if Wind >= 2 then
    if StarFieldImages <> nil then
      StarFieldImages.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if Assigned(ScrollChangedCallback) then
    ScrollChangedCallback;
  (Process as TProcessSE).UpdateViewRect;
  SpaceViewPosition := PointToPointF(MapPanel.ScrollOffset);
end;

procedure TSpaceSE.MinimapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Local: TPoint;
  Child: TObjectGI;
begin
  MinimapDragging := False;
  if Sender.IsOccludedAtPoint(Point) then
    Exit;
  if Screen = StarMapScreen then
  begin
    if StarMapScreen.CenterShipButton.HitTest(Point) then
      Exit;
    Child := StarMapScreen.SecondaryPartnerPanel.FirstChild;
    while Child <> nil do
    begin
      if (Child as TGraphButtonGI).HitTest(Point) then
        Exit;
      Child := Child.NextSibling;
    end;
  end;
  if Screen = FilmScreen then
    if FilmScreen.CenterShipButton.HitTest(Point) then
      Exit;
  MinimapDragging := True;
  FilmCameraFollow := False;
  Local := Sender.ToLocalPoint(Point);
  MapPanel
      .SetScrollOffset(Classes.Point(Round(Local.X / MinimapScale), Round(Local.Y / MinimapScale)));
  MapScrollChanged(nil);
  MinimapFrameCounter := 0;
end;

procedure TSpaceSE.MinimapMouseEnter(Sender: TObjectGI);
begin
  MinimapDragging := False;
end;

procedure TSpaceSE.MinimapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Local: TPoint;
begin
  if MinimapDragging then
    if (Integer(KeyState and MK_LBUTTON) = MK_LBUTTON)
        or ((KeyState and MK_RBUTTON) = MK_RBUTTON) then
    begin
      if Sender.IsOccludedAtPoint(Point) then
        Exit;
      if Screen = StarMapScreen then
        if StarMapScreen.CenterShipButton.HitTest(Point) then
          Exit;
      if Screen = FilmScreen then
        if FilmScreen.CenterShipButton.HitTest(Point) then
          Exit;
      Local := Sender.ToLocalPoint(Point);
      MapPanel.SetScrollOffset(
          Classes.Point(Round(Local.X / MinimapScale), Round(Local.Y / MinimapScale))
      );
      MapScrollChanged(nil);
      MinimapFrameCounter := 0;
    end;
end;

function TSpaceSE.ContainsMapPoint(Point: TPointF): Boolean;
begin
  if MapPanel = nil then
    Result := False
  else
    Result := MapPanel.ContainsPoint(MapPanel.ToAbsolutePoint(TruncatePointF(Point)));
end;

procedure LinkRecoveredTypes;
begin
  TGraphButtonGI.ClassName;
  TPlanetSE.ClassName;
  TProcessSE.ClassName;
  TStarSE.ClassName;
  TWeaponSE.ClassName;
end;
end.
