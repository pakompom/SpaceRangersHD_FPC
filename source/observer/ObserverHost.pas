{$EXCESSPRECISION OFF}
unit ObserverHost;

// One continuous world canvas, using the recovered system sprites and HUD.
interface
procedure RunObserver(const SavePath: AnsiString);
implementation
uses
  SysUtils,
  Classes,
  Math,
  Contnrs,
  Windows,
  Messages,
  Types,
  EC_Struct,
  ObserverCapture,
  ObserverSimulation,
  ObserverHooks,
  GI_MessageLoop,
  GI_Panel,
  GI_Label,
  GI_GraphBuf,
  GI_Main,
  GR_Main,
  GR_DX,
  GR_GraphBuf,
  Globals,
  GlobalsV,
  aGalaxy,
  aShip,
  aPlayer,
  aSaveLoad,
  aScript,
  SE_Space,
  SE_Process,
  SE_Planet,
  SE_Ship2,
  GameNative,
  ThreadCalc,
  fStarMap,
  EC_BlockPar,
  ObserverEffects,
  ObserverDrawing,
  ObserverInfo;
const
  ObserverDetailZoom = 0.06;
type
  TObserverTransitGlow = record
    A, B, C: TPointF;
    Colour: Cardinal;
    StartedMs: Double;
    Active: Boolean;
  end;
  TObserverVisual = class
    Graphic: TObjectSE;
    Track: TObserverTrack;
    destructor Destroy; override;
  end;
  TObserverScene = class
    Screen: TMessageLoopGI;
    Panel: TPanelGI;
    Space: TSpaceSE;
    Visuals: TFPHashObjectList;
    Data: TObserverSystem;
    Centre: TPointF;
    LabelControl: TLabelGI;
    Effects: TObserverEffectPlayer;
    constructor Create(Owner: TMessageLoopGI; AData: TObserverSystem);
    destructor Destroy; override;
    procedure Bind(AData: TObserverSystem);
    procedure Update(Progress: Double; Still: Boolean; Detail: Boolean; Scale: Double = 1);
    procedure Draw(Zoom, X, Y: Double; Clip: TRect);
  end;
  TObserverScreen = class(TfStarMap)
    Recording: TObserverRecording;
    Worker: TObserverWorker;
    Scenes: TObjectList;
    Caption: TLabelGI;
    RadarTitle: TLabelGI;
    Inspector: TObserverInspector;
    Radar: TGraphBufGI;
    RadarOrigin: TPointF;
    RadarScale: Double;
    SelectedKey, HoverKey: AnsiString;
    SelectedStar, HoverStar: Integer;
    Camera, TargetCamera, MouseAnchor: TPointF;
    Zoom, TargetZoom, MinimumZoom, DurationMs, PlaybackMs: Double;
    TransitClockMs: Double;
    TransitArrivalShown: array of Boolean;
    TransitGlows: array[0..127] of TObserverTransitGlow;
    NextTransitGlow: Integer;
    LastTick: QWord;
    Playing, SingleStep, Dragging, Still, ZoomAnchored, ShowHelp: Boolean;
    RadarDragging, FollowSelection, ShowOrbits, DragMoved, ShowAllIcons: Boolean;
    LastDrag, AnchorPixel: TPoint;
    DragStart: TPoint;
    FocusedSystem, CompletedTurns, DetailSystems: Integer;
    Failure: WideString;
    Canvas: TRect;
    destructor Destroy; override;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure DrawFrame; override;
    procedure ProcessWindowMessage(Message, WParam: Cardinal; LParam: Integer); override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
    procedure Tick(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure StartTurn;
    procedure AcceptTurn;
    procedure BuildLayout;
    procedure Overview;
    procedure FocusSystem(Index: Integer; Close: Boolean);
    procedure Click(Point: TPoint; DoubleClick: Boolean);
    procedure KeyDown(Key: Cardinal);
    procedure SetPlaybackDuration(Milliseconds: Double);
    procedure UpdateRadar;
    procedure DrawRadar;
    procedure RadarPan(Point: TPoint);
    procedure DrawInspection(Progress: Double);
    function PickObject(Point: TPoint; out Scene: TObserverScene): TObserverTrack;
    function SelectedTrack(out Scene: TObserverScene): TObserverTrack;
    procedure DrawBlip(X, Y, Radius: Double; Color: Cardinal; Alpha: Integer);
    procedure DrawTransits(Progress: Double);
    function ScreenToWorld(Point: TPoint): TPointF;
  end;
  TObserverRadarGI = class(TGraphBufGI)
    Observer: TObserverScreen;
    procedure Draw(ClipRect: TRect); override;
  end;

procedure TObserverRadarGI.Draw(ClipRect: TRect);
begin
  // Participate in the native UI draw order, below the software cursor.
  Observer.DrawRadar;
  sr_gpu_clip(ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom);
end;

function TrackDiameter(Track: TObserverTrack): Double;
begin
  if (Track.Kind <= 1) and (Track.Radius > 0) then
    Result := Track.Radius * 2
  else
    Result := Max(24, Max(Track.Size.X, Track.Size.Y));
end;

function SpriteAlpha(Track: TObserverTrack; Scale: Double): Integer;
var
  Pixels: Double;
begin
  Pixels := TrackDiameter(Track) * Scale;
  if Track.Kind = 1 then
    Result := EnsureRange(Round((Pixels - 16) / 12 * 255), 0, 255)
  else if Track.Kind = 0 then
    Result := EnsureRange(Round((Pixels - 4) / 8 * 255), 0, 255)
  else
    Result := EnsureRange(Round((Pixels - 5) / 7 * 255), 0, 255);
end;

function NewLabel(Owner: TObjectGI; X, Y, W, H: Integer): TLabelGI;
begin
  Result := TLabelGI.Create(Owner);
  Result.SetFontName(NormalFontName);
  Result.SetPosition(Classes.Point(X, Y));
  Result.SetSize(Classes.Point(W, H));
  Result.SetTextAlignX(taxLeft);
  Result.SetTextAlignY(tayCenterEx);
  Result.SetTextColor($DDEDF8);
  Result.SetDepth(-100);
end;

destructor TObserverVisual.Destroy;
begin
  if Graphic <> nil then
  begin
    Graphic.DetachFromSpace;
    Graphic.Free
  end;
  inherited Destroy;
end;
constructor TObserverScene.Create(Owner: TMessageLoopGI; AData: TObserverSystem);
begin
  inherited Create;
  Screen := TMessageLoopGI.Create;
  Screen.InitializeDefaults;
  // Local coordinates are genuine system coordinates, including negative ones.
  // The GPU camera applies scale/translation only when submitting primitives.
  Screen.RootUiObject.SetPosition(Classes.Point(-100000, -100000));
  Screen.RootUiObject.SetSize(Classes.Point(200000, 200000));
  Screen.ViewportRect := Classes.Rect(-100000, -100000, 100000, 100000);
  Screen.ContentPanel.SetPosition(Classes.Point(0, 0));
  Screen.ContentPanel.SetSize(Classes.Point(200000, 200000));
  Panel := TPanelGI.Create(Screen.ContentPanel);
  Panel.SetPosition(Classes.Point(0, 0));
  Panel.SetSize(Classes.Point(200000, 200000));
  Panel.SetScrollOffset(Classes.Point(-100000, -100000));
  Space := TSpaceSE.Create(Panel, Screen);
  Effects := TObserverEffectPlayer.Create(Space);
  Visuals := TFPHashObjectList.Create(True);
  LabelControl := NewLabel(Owner.OverlayPanel, 0, 0, 240, 22);
  Bind(AData);
end;
destructor TObserverScene.Destroy;
begin
  Effects.Free;
  Visuals.Free;
  Space.Free;
  Screen.Free;
  LabelControl.Free;
  inherited Destroy
end;
procedure TObserverScene.Bind(AData: TObserverSystem);
var
  I: Integer;
  V: TObserverVisual;
begin
  Data := AData;
  Effects.Bind(AData);
  for I := Visuals.Count - 1 downto 0 do
  begin
    V := TObserverVisual(Visuals[I]);
    V.Track := TObserverTrack(Data.Tracks.Find(Visuals.NameOfIndex(I)));
    if (V.Track = nil) or (V.Track.GraphKey <> V.Graphic.GraphKey) then
      Visuals.Delete(I);
  end;
end;
procedure TObserverScene.Update(Progress: Double; Still: Boolean; Detail: Boolean; Scale: Double);
var
  I: Integer;
  Track: TObserverTrack;
  V: TObserverVisual;
  P: TObserverPose;
  Planet: TPlanetSE;
begin
  // Hidden scenes retain their clones, but do no sampling, hash lookups or
  // native animation work. Update their poses when detail is requested again.
  if not Detail then
    Exit;
  for I := 0 to Data.Tracks.Count - 1 do
  begin
    Track := TObserverTrack(Data.Tracks[I]);
    P := SampleObserverPose(Track, Progress, Data.Steps, Still);
    V := TObserverVisual(Visuals.Find(Track.Key));
    if (V = nil) and Detail and P.Visible and (SpriteAlpha(Track, Scale) > 0) then
    begin
      V := TObserverVisual.Create;
      Visuals.Add(Track.Key, V);
      V.Track := Track;
      V.Graphic := CreateSpaceObjectByName(Track.SceneClass, Track.GraphKey, Classes.Point(0, 0));
      if (Track.Size.X > 0) and (Track.Size.Y > 0) then
        V.Graphic.SetSize(Track.Size);
      V.Graphic.SetAlpha(255);
      if V.Graphic is TShip2SE then
      begin
        TShip2SE(V.Graphic).AlphaLimit := 255;
        TShip2SE(V.Graphic).SetTailMode(1)
      end;
      if V.Graphic is TPlanetSE then
      begin
        Planet := TPlanetSE(V.Graphic);
        Planet.Radius := Track.Radius;
        Planet.RingKind := Track.RingKind;
        Planet.SurfaceMapStep := Track.SurfaceStep;
        Planet.SurfaceMapOffset := Track.SurfaceOffset;
        Planet.RotationTimerInterval := Track.RotationInterval;
        Planet.MinimapOwner := Track.Owner;
      end;
    end;
    if V = nil then
      Continue;
    if not P.Visible or not Detail or (SpriteAlpha(Track, Scale) = 0) then
    begin
      if V.Graphic.IsAttachedToSpace then
        V.Graphic.DetachFromSpace;
      Continue
    end;
    V.Graphic.SetAlpha(SpriteAlpha(Track, Scale));
    V.Graphic.SetPosition(P.Position);
    V.Graphic.SetAngle(P.Angle);
    if not V.Graphic.IsAttachedToSpace then
      V.Graphic.AttachToSpace(Space);
  end;
  if Detail then
  begin
    Effects.Update(Progress, Still, Scale);
    Screen.TimerTick := GetTickCount64;
    Screen.ProcessCallbackTimers;
    Space.AdvanceTimers;
    Screen.RootUiObject.UpdateAbsolutePosition;
    Screen.RootUiObject.UpdateSubtreeHitBounds;
  end;
end;
procedure TObserverScene.Draw(Zoom, X, Y: Double; Clip: TRect);
var
  LocalClip: TRect;
begin
  LocalClip :=
      Classes.Rect(
          Floor((Clip.Left - X) / Zoom),
          Floor((Clip.Top - Y) / Zoom),
          Ceil((Clip.Right - X) / Zoom),
          Ceil((Clip.Bottom - Y) / Zoom)
      );
  if sr_gpu_view(Zoom, X, Y, Clip.Left, Clip.Top, Clip.Right, Clip.Bottom) = 0 then
    raise Exception.Create(sr_error);
  try
    Panel.Draw(LocalClip);
  finally
    sr_gpu_view(1, 0, 0, 0, 0, GameScreenWidth, GameScreenHeight);
    sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  end;
end;

procedure TObserverScreen.BuildLayout;
var
  I, J, K, Pass: Integer;
  A, B: TObserverScene;
  Distance, Scale, Required, DX, DY, Push, V: Double;
  Nearest, Diameters: array of Double;
begin
  // Typical spacing avoids letting a single close pair spread out the entire
  // galaxy. Relax overlaps locally while retaining its original arrangement.
  SetLength(Nearest, Scenes.Count);
  SetLength(Diameters, Scenes.Count);
  for I := 0 to Scenes.Count - 1 do
  begin
    A := TObserverScene(Scenes[I]);
    Nearest[I] := 1e30;
    Diameters[I] := A.Data.Diameter;
    for J := 0 to Scenes.Count - 1 do
      if I <> J then
      begin
        B := TObserverScene(Scenes[J]);
        Distance :=
            Hypot(
                A.Data.MapPosition.X - B.Data.MapPosition.X,
                A.Data.MapPosition.Y - B.Data.MapPosition.Y
            );
        if Distance > 0.01 then
          Nearest[I] := Min(Nearest[I], Distance);
      end;
  end;
  for I := 1 to Scenes.Count - 1 do
  begin
    V := Nearest[I];
    K := I;
    while (K > 0) and (Nearest[K - 1] > V) do
    begin
      Nearest[K] := Nearest[K - 1];
      Dec(K)
    end;
    Nearest[K] := V;
    V := Diameters[I];
    K := I;
    while (K > 0) and (Diameters[K - 1] > V) do
    begin
      Diameters[K] := Diameters[K - 1];
      Dec(K)
    end;
    Diameters[K] := V;
  end;
  Scale := Diameters[Scenes.Count div 2] * 1.15 / Max(1, Nearest[Scenes.Count div 2]);
  for I := 0 to Scenes.Count - 1 do
  begin
    A := TObserverScene(Scenes[I]);
    A.Centre := MakePointF(A.Data.MapPosition.X * Scale, A.Data.MapPosition.Y * Scale)
  end;
  for Pass := 1 to 100 do
    for I := 0 to Scenes.Count - 1 do
      for J := 0 to I - 1 do
      begin
        A := TObserverScene(Scenes[I]);
        B := TObserverScene(Scenes[J]);
        DX := A.Centre.X - B.Centre.X;
        DY := A.Centre.Y - B.Centre.Y;
        Distance := Hypot(DX, DY);
        Required := (A.Data.Diameter + B.Data.Diameter) * 0.52 + 200;
        if Distance >= Required then
          Continue;
        if Distance < 0.01 then
        begin
          DX := 1;
          DY := 0;
          Distance := 1
        end;
        Push := (Required - Distance) * 0.51 / Distance;
        A.Centre.X := A.Centre.X + DX * Push;
        A.Centre.Y := A.Centre.Y + DY * Push;
        B.Centre.X := B.Centre.X - DX * Push;
        B.Centre.Y := B.Centre.Y - DY * Push;
      end;
end;
procedure TObserverScreen.Overview;
var
  I: Integer;
  S: TObserverScene;
  L, T, R, B, Radius: Double;
begin
  L := 1e30;
  T := 1e30;
  R := -1e30;
  B := -1e30;
  for I := 0 to Scenes.Count - 1 do
  begin
    S := TObserverScene(Scenes[I]);
    Radius := S.Data.Diameter / 2;
    L := Min(L, S.Centre.X - Radius);
    R := Max(R, S.Centre.X + Radius);
    T := Min(T, S.Centre.Y - Radius);
    B := Max(B, S.Centre.Y + Radius);
  end;
  TargetCamera := MakePointF((L + R) / 2, (T + B) / 2);
  TargetZoom :=
      Min(
          (Canvas.Right - Canvas.Left - 60) / Max(1, R - L),
          (Canvas.Bottom - Canvas.Top - 60) / Max(1, B - T)
      );
  MinimumZoom := TargetZoom * 0.7;
  ZoomAnchored := False;
end;
procedure TObserverScreen.FocusSystem(Index: Integer; Close: Boolean);
var
  S: TObserverScene;
begin
  FocusedSystem := (Index + Scenes.Count) mod Scenes.Count;
  S := TObserverScene(Scenes[FocusedSystem]);
  TargetCamera := S.Centre;
  if Close then
    TargetZoom := 1
  else
    TargetZoom := Min(1, (Canvas.Bottom - Canvas.Top) * 0.9 / S.Data.Diameter);
  ZoomAnchored := False;
  StarField.SetBackgroundImage(UTF8Decode(Format('Bm.BGO.bg%.2d', [S.Data.Background])));
end;
function TObserverScreen.ScreenToWorld(Point: TPoint): TPointF;
begin
  Result :=
      MakePointF(
          Camera.X + (Point.X - (Canvas.Left + Canvas.Right) / 2) / Zoom,
          Camera.Y + (Point.Y - (Canvas.Top + Canvas.Bottom) / 2) / Zoom
      );
end;
procedure TObserverScreen.OnOpen;
var
  I: Integer;
  S: TObserverScene;
  Obj: TObjectGI;
const
  HideNames: array[0..14] of WideString = (
      'Info',
      'InfoItem',
      'InfoShip',
      'InfoPlanet',
      'InfoStar',
      'InfoStd',
      'PanelLoad',
      'PS_Up',
      'MapPartner',
      'MapPartner2',
      'CircleActionShr',
      'CircleActionColor',
      'CircleActionWeaponColor',
      'LargeHelp',
      'FPS'
  );
begin
  if not HardwareRenderingEnabled then
    raise Exception.Create('The zoomable observer requires --renderer=sdl.');
  Mode := smmInactive;
  Playing := True;
  Still := True;
  DurationMs := 800;
  ShowOrbits := True;
  ShowAllIcons := True;
  SelectedStar := -1;
  HoverStar := -1;
  Canvas := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight - 80);
  for I := 0 to High(HideNames) do
  begin
    Obj := FindControlByPath(HideNames[I]);
    if Obj <> nil then
      Obj.SetActive(False)
  end;
  MainPanel.Show;
  MainPanel.RefreshMoneyAndCargo;
  MainPanel.SetDateRange(Galaxy.CurrentTurn, Galaxy.CurrentTurn);
  MainPanel.RefreshDate;
  Caption := NewLabel(OverlayPanel, 16, 16, GameScreenWidth - 250, 26);
  Caption.SetShadowOffset(1);
  Caption.SetActive(False);
  Inspector := TObserverInspector.Create(Self);
  Recording := TObserverRecording.Create;
  Recording.CaptureAll;
  Scenes := TObjectList.Create(True);
  for I := 0 to Recording.Systems.Count - 1 do
  begin
    S := TObserverScene.Create(Self, TObserverSystem(Recording.Systems[I]));
    Scenes.Add(S);
    if S.Data.Id = PlayerStar.Id then
      FocusedSystem := I;
  end;
  BuildLayout;
  Overview;
  FocusSystem(FocusedSystem, True);
  Camera := TargetCamera;
  Zoom := TargetZoom;
  StarField.BackgroundScale := 5;
  Radar := TObserverRadarGI.Create(OverlayPanel, False);
  TObserverRadarGI(Radar).Observer := Self;
  Radar.GraphBuf.AllocateRgbaTight(190, 190);
  Radar.SourceHasPerPixelAlpha := True;
  Radar.GraphBuf.FillRect32(Classes.Rect(0, 0, 190, 190), $EB020B15);
  Radar.SetSize(Classes.Point(190, 190));
  Obj := GetByName('MapPanel');
  Radar.SetPosition(Classes.Point(GameScreenWidth - 206, 16));
  Obj.SetActive(False);
  Radar.SetDepth(-90);
  RadarTitle := NewLabel(OverlayPanel, GameScreenWidth - 200, 209, 185, 20);
  LastTick := GetTickCount64;
  ScheduleCallbackTimer(20, 20, Tick, 0);
  StartTurn;
end;
procedure TObserverScreen.StartTurn;
begin
  if (Worker <> nil) or (Failure <> '') then
    Exit;
  if HasPendingScriptRequests then
  begin
    Failure := 'A campaign script requires player interaction';
    Playing := False;
    Exit
  end;
  Worker := TObserverWorker.Create(True);
  Worker.CaptureEnabled := True;
  Worker.Start;
end;
procedure TObserverScreen.AcceptTurn;
var
  I, J, OldCount: Integer;
  S: TObserverScene;
  D: TObserverSystem;
  Old: TObserverRecording;
  Found: Boolean;
begin
  Worker.WaitFor;
  if Worker.Failure <> '' then
  begin
    Failure := UTF8Decode(Worker.Failure);
    Playing := False;
    Worker.Recording.Free;
    FreeAndNil(Worker);
    Exit;
  end;
  Old := Recording;
  Recording := Worker.Recording;
  Worker.Recording := nil;
  FreeAndNil(Worker);
  OldCount := Scenes.Count;
  for I := Scenes.Count - 1 downto 0 do
  begin
    S := TObserverScene(Scenes[I]);
    D := TObserverSystem(Recording.Systems.Find(IntToStr(S.Data.Id)));
    if D <> nil then
      S.Bind(D)
    else
      Scenes.Delete(I);
  end;
  for I := 0 to Recording.Systems.Count - 1 do
  begin
    D := TObserverSystem(Recording.Systems[I]);
    Found := False;
    for J := 0 to Scenes.Count - 1 do
      if TObserverScene(Scenes[J]).Data.Id = D.Id then
      begin
        Found := True;
        Break
      end;
    if not Found then
      Scenes.Add(TObserverScene.Create(Self, D));
  end;
  if Scenes.Count <> OldCount then
  begin
    BuildLayout;
    FocusedSystem := Min(FocusedSystem, Scenes.Count - 1)
  end;
  Old.Free;
  PlaybackMs := 0;
  Still := False;
  Inc(CompletedTurns);
  SetLength(TransitArrivalShown, 0);
  MainPanel.SetDateRange(Recording.Turn, Recording.Turn + 1);
  if Playing then
    StartTurn;
end;
procedure TObserverScreen.UpdateRadar;
var
  I: Integer;
  L, T, R, B, Radius: Double;
  S: TObserverScene;
begin
  L := 1e30;
  T := 1e30;
  R := -1e30;
  B := -1e30;
  for I := 0 to Scenes.Count - 1 do
  begin
    S := TObserverScene(Scenes[I]);
    Radius := S.Data.Diameter * 0.5;
    L := Min(L, S.Centre.X - Radius);
    T := Min(T, S.Centre.Y - Radius);
    R := Max(R, S.Centre.X + Radius);
    B := Max(B, S.Centre.Y + Radius);
  end;
  RadarScale := 170 / Max(1, Max(R - L, B - T));
  RadarOrigin := MakePointF((L + R) / 2 - 95 / RadarScale, (T + B) / 2 - 95 / RadarScale);
  RadarTitle.SetText(TObserverScene(Scenes[FocusedSystem]).Data.Name);
end;
procedure TObserverScreen.DrawRadar;
var
  I, J: Integer;
  S, A, B: TObserverScene;
  T: TObserverTransit;
  R, SourceRect: TRect;
  P, Q: TPointF;
  L, Top, Right, Bottom, Scale: Double;
  function Project(Pos: TPointF): TPointF;
  begin
    Result :=
        MakePointF(
            R.Left + (Pos.X - RadarOrigin.X) * RadarScale,
            R.Top + (Pos.Y - RadarOrigin.Y) * RadarScale
        )
  end;
begin
  R := Radar.HitTestBounds;
  // Reuse the native nebula image on the GPU, cropped to a square. No readback.
  Scale := 190 / GameScreenHeight;
  SourceRect :=
      Classes.Rect(
          (GameScreenWidth - GameScreenHeight) div 2,
          0,
          (GameScreenWidth + GameScreenHeight) div 2,
          GameScreenHeight
      );
  sr_gpu_view(Scale, R.Left - SourceRect.Left * Scale, R.Top, R.Left, R.Top, R.Right, R.Bottom);
  try
    StarField.DrawBackground(SourceRect)
  finally
    sr_gpu_view(1, 0, 0, 0, 0, GameScreenWidth, GameScreenHeight)
  end;
  sr_gpu_clip(R.Left, R.Top, R.Right, R.Bottom);
  ObserverBox(R.Left, R.Top, R.Right, R.Bottom, $020A16, 125);
  for I := 1 to 3 do
  begin
    ObserverLine(R.Left + I * 47.5, R.Top, R.Left + I * 47.5, R.Bottom, 0.5, $5E8DAA, 22);
    ObserverLine(R.Left, R.Top + I * 47.5, R.Right, R.Top + I * 47.5, 0.5, $5E8DAA, 22);
  end;
  for I := 0 to Recording.Transits.Count - 1 do
  begin
    T := TObserverTransit(Recording.Transits[I]);
    A := nil;
    B := nil;
    if (not Still)
        and ((PlaybackMs / DurationMs < T.BeginAt)
            or ((T.RemainingDays = 0) and (PlaybackMs / DurationMs >= T.EndAt))) then
      Continue;
    for J := 0 to Scenes.Count - 1 do
    begin
      S := TObserverScene(Scenes[J]);
      if S.Data.Id = Integer(T.OriginId) then
        A := S;
      if S.Data.Id = Integer(T.DestinationId) then
        B := S
    end;
    if (A = nil) or (B = nil) then
      Continue;
    P := Project(A.Centre);
    Q := Project(B.Centre);
    ObserverLine(P.X, P.Y, Q.X, Q.Y, 0.5, ObserverOwnerColor(T.Owner), 23);
  end;
  for I := 0 to Scenes.Count - 1 do
  begin
    S := TObserverScene(Scenes[I]);
    P := Project(S.Centre);
    DrawBlip(P.X, P.Y, 1.65, ObserverFactionColor(S.Data.Faction), 220);
    if I = FocusedSystem then
      ObserverRing(P.X, P.Y, 4.5, $F6D995, 200);
    if S.Data.Effects.Count > 0 then
      ObserverRing(P.X, P.Y, 3.3, $F29676, 75);
  end;
  P := Project(ScreenToWorld(Classes.Point(Canvas.Left, Canvas.Top)));
  Q := Project(ScreenToWorld(Classes.Point(Canvas.Right, Canvas.Bottom)));
  L := Max(R.Left + 1, P.X);
  Top := Max(R.Top + 1, P.Y);
  Right := Min(R.Right - 1, Q.X);
  Bottom := Min(R.Bottom - 1, Q.Y);
  if (L < Right) and (Top < Bottom) then
  begin
    ObserverBox(L, Top, Right, Bottom, $86CFE3, 18);
    ObserverLine(L, Top, Right, Top, 0.8, $C5E9F1, 210);
    ObserverLine(Right, Top, Right, Bottom, 0.8, $C5E9F1, 210);
    ObserverLine(Right, Bottom, L, Bottom, 0.8, $C5E9F1, 210);
    ObserverLine(L, Bottom, L, Top, 0.8, $C5E9F1, 210);
  end;
  sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  ObserverLine(R.Left, R.Top, R.Right, R.Top, 0.8, $76B7C9, 170);
  ObserverLine(R.Right, R.Top, R.Right, R.Bottom, 0.8, $76B7C9, 170);
  ObserverLine(R.Right, R.Bottom, R.Left, R.Bottom, 0.8, $76B7C9, 170);
  ObserverLine(R.Left, R.Bottom, R.Left, R.Top, 0.8, $76B7C9, 170);
end;
procedure TObserverScreen.RadarPan(Point: TPoint);
begin
  TargetCamera :=
      MakePointF(
          RadarOrigin.X + (Point.X - Radar.HitTestBounds.Left) / RadarScale,
          RadarOrigin.Y + (Point.Y - Radar.HitTestBounds.Top) / RadarScale
      );
  ZoomAnchored := False;
  FollowSelection := False;
end;
procedure TObserverScreen.Tick(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  NowTick: QWord;
  Elapsed, Blend: Double;
  Text: WideString;
  S: TObserverScene;
  Track: TObserverTrack;
  P: TObserverPose;
begin
  NowTick := GetTickCount64;
  Elapsed := NowTick - LastTick;
  LastTick := NowTick;
  if Playing or SingleStep then
    TransitClockMs := TransitClockMs + Elapsed;
  // Fast playback must not wait for the ordinary 20 ms UI polling interval.
  if Playing or SingleStep then
    Timer.RepeatMs := EnsureRange(Round(DurationMs / 4), 1, 20)
  else
    Timer.RepeatMs := 20;
  if (Worker <> nil)
      and Worker.Finished
      and (Still or (PlaybackMs >= DurationMs))
      and (Playing or SingleStep or Still) then
    AcceptTurn;
  if Playing or SingleStep then
    PlaybackMs := Min(DurationMs, PlaybackMs + Elapsed);
  if (PlaybackMs >= DurationMs) and not Still then
  begin
    if SingleStep then
    begin
      SingleStep := False;
      Playing := False
    end;
    if Playing then
      StartTurn;
  end;
  if FollowSelection then
  begin
    Track := SelectedTrack(S);
    if Track <> nil then
    begin
      P := SampleObserverPose(Track, Min(1, PlaybackMs / DurationMs), S.Data.Steps, Still);
      if P.Visible then
        TargetCamera := MakePointF(S.Centre.X + P.Position.X, S.Centre.Y + P.Position.Y)
    end;
  end;
  Blend := 1 - Exp(-Min(200, Elapsed) / 100);
  Zoom := Zoom + (TargetZoom - Zoom) * Blend;
  if ZoomAnchored then
  begin
    Camera :=
        MakePointF(
            MouseAnchor.X - (AnchorPixel.X - (Canvas.Left + Canvas.Right) / 2) / Zoom,
            MouseAnchor.Y - (AnchorPixel.Y - (Canvas.Top + Canvas.Bottom) / 2) / Zoom
        );
    TargetCamera := Camera;
  end
  else
  begin
    Camera.X := Camera.X + (TargetCamera.X - Camera.X) * Blend;
    Camera.Y := Camera.Y + (TargetCamera.Y - Camera.Y) * Blend
  end;
  MainPanel.DateSlideProgress := Min(1, PlaybackMs / DurationMs);
  MainPanel.RefreshDate;
  Caption.SetActive(ShowHelp or (Failure <> ''));
  if Failure <> '' then
    Text := 'Paused: ' + Failure
  else
    Text :=
        'Wheel: zoom   Drag: pan   Click: inspect   F: follow   O: orbits   I: icons   G: galaxy   Space: pause   N: turn   +/-: speed';
  Caption.SetText(Text);
  UpdateRadar;

end;
procedure TObserverScreen.DrawBlip(X, Y, Radius: Double; Color: Cardinal; Alpha: Integer);
const
  Segments = 20;
var
  V: array[0..Segments + 1] of TScreenVertexGR;
  procedure Disc(R: Double; CentreAlpha, EdgeAlpha: Integer);
  var
    I: Integer;
    A: Double;
  begin
    FillChar(V, SizeOf(V), 0);
    V[0].X := X - 0.5;
    V[0].Y := Y - 0.5;
    V[0].Z := 1;
    V[0].RHW := 1;
    V[0].Color := (Color and $FFFFFF) or (Cardinal(CentreAlpha) shl 24);
    for I := 0 to Segments do
    begin
      A := I * 2 * Pi / Segments;
      V[I + 1].X := X + Cos(A) * R - 0.5;
      V[I + 1].Y := Y + Sin(A) * R - 0.5;
      V[I + 1].Z := 1;
      V[I + 1].RHW := 1;
      V[I + 1].Color := (Color and $FFFFFF) or (Cardinal(EdgeAlpha) shl 24);
    end;
    sr_gpu_draw(nil, 6, Segments, @V, SizeOf(TScreenVertexGR), 0, 0);
  end;
begin
  FlushObserverIconBatch;
  Disc(Radius * 2, Alpha div 2, 0);
  Disc(Radius, Alpha, 0);
  Disc(Radius * 0.4, Alpha, Alpha);
end;
procedure TObserverScreen.DrawTransits(Progress: Double);
const
  Segments = 32;
var
  I, J: Integer;
  T: TObserverTransit;
  Origin, Destination, S: TObserverScene;
  A, B, C, WorldA, WorldB, WorldC, Head: TPointF;
  DX, DY, CurveLength, F, TimeFraction, Start, Finish, Age, Fade: Double;
  Glow: ^TObserverTransitGlow;
  Colour: Cardinal;
  function Curve(U: Double): TPointF;
  begin
    Result :=
        MakePointF(
            Sqr(1 - U) * A.X + 2 * (1 - U) * U * C.X + U * U * B.X,
            Sqr(1 - U) * A.Y + 2 * (1 - U) * U * C.Y + U * U * B.Y
        )
  end;
  procedure Ribbon(First, Last, Width: Double; FirstAlpha, LastAlpha: Integer);
  var
    V: array[0..Segments * 6 - 1] of TScreenVertexGR;
    K, N, Alpha1, Alpha2: Integer;
    P, Q: TPointF;
    NX, NY, L: Double;
    procedure Vertex(Index: Integer; X, Y: Double; Alpha: Integer);
    begin
      V[Index].X := X - 0.5;
      V[Index].Y := Y - 0.5;
      V[Index].Z := 1;
      V[Index].RHW := 1;
      V[Index].Color := Colour or (Cardinal(Alpha) shl 24)
    end;
  begin
    FillChar(V, SizeOf(V), 0);
    for K := 0 to Segments - 1 do
    begin
      P := Curve(First + (Last - First) * K / Segments);
      Q := Curve(First + (Last - First) * (K + 1) / Segments);
      L := Max(0.001, Hypot(Q.X - P.X, Q.Y - P.Y));
      NX := -(Q.Y - P.Y) / L * Width / 2;
      NY := (Q.X - P.X) / L * Width / 2;
      Alpha1 := Round(FirstAlpha + (LastAlpha - FirstAlpha) * K / Segments);
      Alpha2 := Round(FirstAlpha + (LastAlpha - FirstAlpha) * (K + 1) / Segments);
      N := K * 6;
      Vertex(N, P.X + NX, P.Y + NY, Alpha1);
      Vertex(N + 1, P.X - NX, P.Y - NY, Alpha1);
      Vertex(N + 2, Q.X - NX, Q.Y - NY, Alpha2);
      V[N + 3] := V[N];
      V[N + 4] := V[N + 2];
      Vertex(N + 5, Q.X + NX, Q.Y + NY, Alpha2);
    end;
    sr_gpu_draw(nil, 4, Segments * 2, @V, SizeOf(TScreenVertexGR), 0, 0);
  end;
  function Project(P: TPointF): TPointF;
  begin
    Result :=
        MakePointF(
            (Canvas.Left + Canvas.Right) / 2 + (P.X - Camera.X) * Zoom,
            (Canvas.Top + Canvas.Bottom) / 2 + (P.Y - Camera.Y) * Zoom
        )
  end;
  function ProjectCurve(const WA, WB, WC: TPointF): Boolean;
  begin
    A := Project(WA);
    B := Project(WB);
    C := Project(WC);
    Result :=
        (Max(Max(A.X, B.X), C.X) >= Canvas.Left - 24)
            and (Min(Min(A.X, B.X), C.X) <= Canvas.Right + 24)
            and (Max(Max(A.Y, B.Y), C.Y) >= Canvas.Top - 24)
            and (Min(Min(A.Y, B.Y), C.Y) <= Canvas.Bottom + 24);
  end;
begin
  sr_gpu_clip(Canvas.Left, Canvas.Top, Canvas.Right, Canvas.Bottom);
  SetLength(TransitArrivalShown, Recording.Transits.Count);
  for I := 0 to Recording.Transits.Count - 1 do
  begin
    T := TObserverTransit(Recording.Transits[I]);
    if Still then
      TimeFraction := 0
    else
      TimeFraction := Progress;
    if TimeFraction < T.BeginAt then
      Continue;
    Origin := nil;
    Destination := nil;
    for J := 0 to Scenes.Count - 1 do
    begin
      S := TObserverScene(Scenes[J]);
      if S.Data.Id = Integer(T.OriginId) then
        Origin := S;
      if S.Data.Id = Integer(T.DestinationId) then
        Destination := S
    end;
    if (Origin = nil) or (Destination = nil) then
      Continue;
    WorldA :=
        MakePointF(
            Origin.Centre.X + T.DeparturePosition.X,
            Origin.Centre.Y + T.DeparturePosition.Y
        );
    WorldB :=
        MakePointF(
            Destination.Centre.X + T.ArrivalPosition.X,
            Destination.Centre.Y + T.ArrivalPosition.Y
        );
    DX := WorldB.X - WorldA.X;
    DY := WorldB.Y - WorldA.Y;
    F := 0.10;
    if T.OriginId > T.DestinationId then
      F := -F;
    WorldC := MakePointF((WorldA.X + WorldB.X) / 2 - DY * F, (WorldA.Y + WorldB.Y) / 2 + DX * F);
    Colour := $73BFDA;
    if T.Owner = 5 then
      Colour := $ED8E78
    else if T.Owner = 7 then
      Colour := $D5AE73;
    if (T.RemainingDays = 0) and (TimeFraction >= T.EndAt) then
    begin
      if not Still and not TransitArrivalShown[I] then
      begin
        // Own only geometry: recordings are freed every turn. Keep a short
        // real-time afterglow even when turns are playing very quickly.
        Glow := @TransitGlows[NextTransitGlow];
        Glow.A := WorldA;
        Glow.B := WorldB;
        Glow.C := WorldC;
        Glow.Colour := Colour;
        Glow.StartedMs := TransitClockMs;
        Glow.Active := True;
        NextTransitGlow := (NextTransitGlow + 1) mod Length(TransitGlows);
        TransitArrivalShown[I] := True;
      end;
      Continue;
    end;
    if not ProjectCurve(WorldA, WorldB, WorldC) then
      Continue;
    // Each flight has its own entry/exit points; a shared centre-to-centre
    // route would visibly detach the trail from most ships.
    Ribbon(0, 1, 3.2, 10, 10);
    Ribbon(0, 1, 1.2, 44, 44);
    F := EnsureRange((TimeFraction - T.BeginAt) / Max(0.0001, T.EndAt - T.BeginAt), 0.0, 1.0);
    Finish := T.BeginProgress + (T.EndProgress - T.BeginProgress) * F;
    CurveLength := Max(1, Hypot(C.X - A.X, C.Y - A.Y) + Hypot(B.X - C.X, B.Y - C.Y));
    Start := Max(0, Finish - Min(0.18, 48 / CurveLength));
    Ribbon(Start, Finish, 7, 0, 42);
    Ribbon(Start, Finish, 3, 0, 90);
    Ribbon(Start, Finish, 1.3, 0, 230);
    Head := Curve(Finish);
    DrawBlip(Head.X, Head.Y, 2.6, Colour, 245);
  end;
  for I := 0 to High(TransitGlows) do
  begin
    Glow := @TransitGlows[I];
    if not Glow.Active then
      Continue;
    Age := (TransitClockMs - Glow.StartedMs) / 650;
    if Age >= 1 then
    begin
      Glow.Active := False;
      Continue
    end;
    if not ProjectCurve(Glow.A, Glow.B, Glow.C) then
      Continue;
    Colour := Glow.Colour;
    Fade := Sqr(1 - Age);
    Ribbon(0, 1, 1.2, Round(36 * Fade), Round(36 * Fade));
    CurveLength := Max(1, Hypot(C.X - A.X, C.Y - A.Y) + Hypot(B.X - C.X, B.Y - C.Y));
    Start := Max(0, 1 - Min(0.18, 48 / CurveLength) * (1 - Age));
    Ribbon(Start, 1, 7, 0, Round(42 * Fade));
    Ribbon(Start, 1, 1.5, 0, Round(210 * Fade));
    DrawBlip(B.X, B.Y, 2.6 + Age * 3, Colour, Round(210 * Fade));
    ObserverRing(B.X, B.Y, 4 + Age * 14, Colour, Round(100 * Fade));
  end;
  sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
end;

procedure TObserverScreen.DrawFrame;
var
  I, J, Alpha: Integer;
  S: TObserverScene;
  SX, SY, Radius, Progress, X, Y, Size: Double;
  Track: TObserverTrack;
  Pose: TObserverPose;
  Detail, Visible: Boolean;
  Color: Cardinal;
begin
  sr_gpu_view(1, 0, 0, 0, 0, GameScreenWidth, GameScreenHeight);
  sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  sr_gpu_clear($FF000000);
  StarField.SetViewPosition(MakePointF(0, 0));
  StarField.UpdateBackgroundBounds;
  StarField.DrawBackground(ViewportRect);
  Progress := Min(1, PlaybackMs / DurationMs);
  DetailSystems := 0;
  DrawTransits(Progress);
  for I := 0 to Scenes.Count - 1 do
  begin
    S := TObserverScene(Scenes[I]);
    SX := (Canvas.Left + Canvas.Right) / 2 + (S.Centre.X - Camera.X) * Zoom;
    SY := (Canvas.Top + Canvas.Bottom) / 2 + (S.Centre.Y - Camera.Y) * Zoom;
    Radius := S.Data.Diameter * Zoom * 0.65;
    Visible :=
        (SX + Radius >= Canvas.Left)
            and (SX - Radius < Canvas.Right)
            and (SY + Radius >= Canvas.Top)
            and (SY - Radius < Canvas.Bottom);
    Detail := Visible and (Zoom >= ObserverDetailZoom);
    S.LabelControl.SetActive(Visible and (Zoom < 0.5));
    if not Visible then
      Continue;
    sr_gpu_clip(Canvas.Left, Canvas.Top, Canvas.Right, Canvas.Bottom);
    if ShowOrbits and (Zoom > 0.025) then
      for J := 0 to S.Data.Tracks.Count - 1 do
      begin
        Track := TObserverTrack(S.Data.Tracks[J]);
        Radius := Track.OrbitRadius * Zoom;
        if (Track.Kind <> 1) or (Radius < 10) or (Radius > GameScreenWidth * 2) then
          Continue;
        Alpha := EnsureRange(Round((Zoom - 0.025) * 900), 0, 38);
        if (S.Data.Id = SelectedStar) and (Track.Key = SelectedKey) then
          Alpha := 120;
        ObserverRing(SX, SY, Radius, $87B3C9, Alpha);
      end;
    if Detail then
    begin
      S.Update(Progress, Still, True, Zoom);
      S.Draw(Zoom, SX, SY, Canvas);
      Inc(DetailSystems)
    end;
    sr_gpu_clip(Canvas.Left, Canvas.Top, Canvas.Right, Canvas.Bottom);
    BeginObserverIconBatch;
    try
      for J := 0 to S.Data.Tracks.Count - 1 do
      begin
        Track := TObserverTrack(S.Data.Tracks[J]);
        // CHANGE: ENHANCEMENT - Apply the optional zoom cutoffs to drawing and picking alike.
        if not ShowAllIcons
            and (((Zoom < 0.01) and (Track.Kind <> 0))
                or ((Zoom < 0.02) and (Track.Kind >= 3))) then
          Continue;
        Alpha := 255 - SpriteAlpha(Track, Zoom);
        if not Detail then
          Alpha := 255;
        if Alpha <= 0 then
          Continue;
        Pose := SampleObserverPose(Track, Progress, S.Data.Steps, Still);
        if not Pose.Visible then
          Continue;
        X := SX + Pose.Position.X * Zoom;
        Y := SY + Pose.Position.Y * Zoom;
        if (X < Canvas.Left - 10)
            or (X > Canvas.Right + 10)
            or (Y < Canvas.Top - 10)
            or (Y > Canvas.Bottom + 10) then
          Continue;
        Color := ObserverOwnerColor(Track.Owner);
        Size := 3.4;
        case Track.Kind of
          0:
          begin
            DrawBlip(X, Y, 3.4, $FFD36A, Alpha);
            Continue
          end;
          1:
          begin
            DrawBlip(X, Y, 1.8, Color, Alpha);
            ObserverRing(X, Y, 3.0, Color, Alpha div 2);
            Continue
          end;
          3:
          begin
            Color := $9AAFB6;
            Size := 2.2;
            Alpha := Alpha * 2 div 3
          end;
          4:
          begin
            Color := $F7B480;
            Size := 2.5
          end;
          5:
          begin
            Color := $E6C380;
            Size := 3;
            if Track.Mineral then
              Color := $A0C9D5
          end;
        end;
        ObserverIcon(X, Y, Size, Pose.Angle * 2 * Pi / 256, Track.Kind, Color, Alpha);
      end;
    finally
      EndObserverIconBatch;
    end;
    S.LabelControl.SetPosition(Classes.Point(Round(SX) + 9, Round(SY) - 24));
    S.LabelControl.SetText(S.Data.Name);
    S.LabelControl.SetShadowOffset(1);
  end;
  sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  DrawInspection(Progress);
  UpdateRects.Clear;
  RootUiObject.Draw(ViewportRect);
  if not BeginFramePresentation then
  begin
    RequestClose(1);
    Exit
  end;
  FinishQueuedDraw;
  CommitFrameDraw;
  ResetSavedLineCount;
  ResetSecondaryPixelCount;
  EndFramePresentation;
end;
function TObserverScreen.PickObject(Point: TPoint; out Scene: TObserverScene): TObserverTrack;
var
  I, J: Integer;
  S: TObserverScene;
  T: TObserverTrack;
  P: TObserverPose;
  World: TPointF;
  D, Best, Radius, Progress: Double;
begin
  Result := nil;
  Scene := nil;
  if not PtInRect(Canvas, Point) or PtInRect(Radar.HitTestBounds, Point) then
    Exit;
  World := ScreenToWorld(Point);
  Best := 1e30;
  Progress := Min(1, PlaybackMs / DurationMs);
  for I := 0 to Scenes.Count - 1 do
  begin
    S := TObserverScene(Scenes[I]);
    if Hypot(World.X - S.Centre.X, World.Y - S.Centre.Y) > S.Data.Diameter then
      Continue;
    for J := 0 to S.Data.Tracks.Count - 1 do
    begin
      T := TObserverTrack(S.Data.Tracks[J]);
      // CHANGE: ENHANCEMENT - Apply the optional zoom cutoffs to drawing and picking alike.
      if not ShowAllIcons
          and (((Zoom < 0.01) and (T.Kind <> 0)) or ((Zoom < 0.02) and (T.Kind >= 3))) then
        Continue;
      P := SampleObserverPose(T, Progress, S.Data.Steps, Still);
      if not P.Visible then
        Continue;
      Radius := Max(7, TrackDiameter(T) * Zoom * 0.42);
      D := Hypot(World.X - S.Centre.X - P.Position.X, World.Y - S.Centre.Y - P.Position.Y) * Zoom;
      if (D <= Radius) and (D / Radius < Best) then
      begin
        Best := D / Radius;
        Result := T;
        Scene := S
      end;
    end;
  end;
end;
function TObserverScreen.SelectedTrack(out Scene: TObserverScene): TObserverTrack;
var
  I: Integer;
begin
  Result := nil;
  Scene := nil;
  for I := 0 to Scenes.Count - 1 do
    if TObserverScene(Scenes[I]).Data.Id = SelectedStar then
    begin
      Scene := TObserverScene(Scenes[I]);
      Result := TObserverTrack(Scene.Data.Tracks.Find(SelectedKey));
      Exit
    end;
end;
procedure TObserverScreen.DrawInspection(Progress: Double);
var
  Track: TObserverTrack;
  S: TObserverScene;
  P: TObserverPose;
  Mouse: TPoint;
  X, Y, Radius, Fraction: Double;
  V: TObserverVisual;
  I: Integer;
begin
  Mouse := GetCursorPoint;
  Track := nil;
  S := nil;
  if Inspector.Contains(Mouse) and (Inspector.LastTrack <> nil) then
  begin
    // Keep a pinned panel under the cursor so its extra pages can be scrolled.
    Track := SelectedTrack(S);
    if Track = nil then
      for I := 0 to Scenes.Count - 1 do
        if TObserverScene(Scenes[I]).Data.Id = HoverStar then
        begin
          S := TObserverScene(Scenes[I]);
          Track := TObserverTrack(S.Data.Tracks.Find(HoverKey));
          Break
        end;
  end;
  if (Track = nil) and not Dragging and not RadarDragging then
    Track := PickObject(Mouse, S);
  HoverKey := '';
  HoverStar := -1;
  if Track <> nil then
  begin
    HoverKey := Track.Key;
    HoverStar := S.Data.Id
  end
  else
    Track := SelectedTrack(S);
  if Track = nil then
  begin
    Inspector.Hide;
    Exit
  end;
  P := SampleObserverPose(Track, Progress, S.Data.Steps, Still);
  X := (Canvas.Left + Canvas.Right) / 2 + (S.Centre.X + P.Position.X - Camera.X) * Zoom;
  Y := (Canvas.Top + Canvas.Bottom) / 2 + (S.Centre.Y + P.Position.Y - Camera.Y) * Zoom;
  Radius := Max(8, TrackDiameter(Track) * Zoom * 0.5 + 5);
  if P.Visible then
  begin
    sr_gpu_clip(Canvas.Left, Canvas.Top, Canvas.Right, Canvas.Bottom);
    ObserverRing(X, Y, Radius, $E9D6A1, 140);
    if Track.Kind = 2 then
    begin
      Fraction := EnsureRange(P.Hull / Max(1, P.HullMax), 0.0, 1.0);
      ObserverLine(X - 18, Y + Radius + 5, X + 18, Y + Radius + 5, 2, $19313D, 230);
      ObserverLine(
          X - 18,
          Y + Radius + 5,
          X - 18 + 36 * Fraction,
          Y + Radius + 5,
          2,
          ObserverOwnerColor(Track.Owner),
          240
      );
    end;
    sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  end;
  V := TObserverVisual(S.Visuals.Find(Track.Key));
  if V <> nil then
    Inspector.Show(Track, S.Data, P, V.Graphic, Mouse, SelectedKey <> '', Canvas)
  else
    Inspector.Show(Track, S.Data, P, nil, Mouse, SelectedKey <> '', Canvas);
end;
procedure TObserverScreen.Click(Point: TPoint; DoubleClick: Boolean);
var
  I: Integer;
  S: TObserverScene;
  Track: TObserverTrack;
begin
  if PtInRect(MainPanel.EndTurnButton.HitTestBounds, Point) then
  begin
    Playing := not Playing;
    if Playing then
      StartTurn;
    Exit
  end;
  if PtInRect(MainPanel.GalaxyButton.HitTestBounds, Point) then
  begin
    Overview;
    Exit
  end;
  if PtInRect(MainPanel.MenuButton.HitTestBounds, Point) then
  begin
    RequestClose(1);
    Exit
  end;
  if PtInRect(Radar.HitTestBounds, Point) then
  begin
    RadarPan(Point);
    Exit
  end;
  Track := PickObject(Point, S);
  FollowSelection := False;
  if Track = nil then
  begin
    SelectedKey := '';
    SelectedStar := -1;
    Exit
  end;
  SelectedKey := Track.Key;
  SelectedStar := S.Data.Id;
  for I := 0 to Scenes.Count - 1 do
    if Scenes[I] = S then
    begin
      FocusedSystem := I;
      Break
    end;
  if Track.Kind = 0 then
    FocusSystem(FocusedSystem, DoubleClick)
  else if DoubleClick then
  begin
    FollowSelection := True;
    TargetZoom := 1;
    ZoomAnchored := False
  end;
end;
procedure TObserverScreen.SetPlaybackDuration(Milliseconds: Double);
var
  Progress: Double;
begin
  Progress := PlaybackMs / DurationMs;
  DurationMs := EnsureRange(Milliseconds, 6.25, 25600.0);
  PlaybackMs := Progress * DurationMs;
end;

procedure TObserverScreen.KeyDown(Key: Cardinal);
var
  Distance: Double;
begin
  Distance := 150 / Zoom;
  ZoomAnchored := False;
  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN] then
    FollowSelection := False;
  case Key of
    VK_ESCAPE:
      if SelectedKey <> '' then
      begin
        SelectedKey := '';
        FollowSelection := False
      end
      else
        RequestClose(1);
    VK_SPACE:
    begin
      Playing := not Playing;
      if Playing then
        StartTurn
    end;
    Ord('N'):
    begin
      Playing := False;
      SingleStep := True;
      if (Worker = nil) and (PlaybackMs >= DurationMs) then
        StartTurn
    end;
    VK_F1: ShowHelp := not ShowHelp;
    Ord('O'): ShowOrbits := not ShowOrbits;
    // CHANGE: ENHANCEMENT - I toggles zoom-based icon hiding; all icons are shown by default.
    Ord('I'): ShowAllIcons := not ShowAllIcons;
    Ord('F'):
    begin
      FollowSelection := not FollowSelection;
      ZoomAnchored := False
    end;
    Ord('G'):
    begin
      FollowSelection := False;
      Overview
    end;
    Ord('C'): FocusSystem(FocusedSystem, True);
    VK_TAB: FocusSystem(FocusedSystem + 1, False);
    VK_LEFT: TargetCamera.X := TargetCamera.X - Distance;
    VK_RIGHT: TargetCamera.X := TargetCamera.X + Distance;
    VK_UP: TargetCamera.Y := TargetCamera.Y - Distance;
    VK_DOWN: TargetCamera.Y := TargetCamera.Y + Distance;
    VK_ADD, 187: SetPlaybackDuration(DurationMs * 0.5);
    VK_SUBTRACT, 189: SetPlaybackDuration(DurationMs * 2);
  end;
end;
procedure TObserverScreen.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Inspector.Contains(Point) then
  begin
    Inspector.Scroll(Sign(Delta));
    Exit
  end;
  if not PtInRect(Canvas, Point) then
    Exit;
  MouseAnchor := ScreenToWorld(Point);
  AnchorPixel := Point;
  ZoomAnchored := True;
  TargetZoom := EnsureRange(TargetZoom * Power(1.25, Delta / 120), MinimumZoom, 2.0);
end;
procedure TObserverScreen.ProcessWindowMessage(Message, WParam: Cardinal; LParam: Integer);
var
  Point: TPoint;
begin
  // sr_poll already converts SDL window coordinates into game coordinates.
  // GetCursorPoint reads the software cursor; it is not a fresh OS mouse poll.
  // Synchronize it before any observer hit tests, including button-only events.
  case Message of
    WM_MOUSEMOVE,
    WM_LBUTTONDOWN,
    WM_LBUTTONUP,
    WM_LBUTTONDBLCLK,
    WM_RBUTTONDOWN,
    WM_RBUTTONUP,
    WM_RBUTTONDBLCLK,
    WM_MOUSEWHEEL:
    begin
      Point := Classes.Point(SmallInt(LParam), SmallInt(LParam shr 16));
      LastMousePosition := Point;
      CursorControl.SetPosition(Point);
    end;
  end;
  Point := GetCursorPoint;
  case Message of
    WM_KEYDOWN:
    begin
      KeyDown(WParam);
      Exit
    end;
    WM_KEYUP, WM_CHAR: Exit;
    WM_ACTIVATEAPP:
      if WParam = 0 then
      begin
        Dragging := False;
        RadarDragging := False
      end;
    WM_LBUTTONDOWN, WM_RBUTTONDOWN:
    begin
      if Inspector.Contains(Point) then
        Exit;
      RadarDragging := PtInRect(Radar.HitTestBounds, Point);
      Dragging := PtInRect(Canvas, Point) and not RadarDragging;
      DragMoved := False;
      LastDrag := Point;
      DragStart := Point;
      if RadarDragging then
        RadarPan(Point);
      Exit;
    end;
    WM_LBUTTONDBLCLK:
    begin
      Click(Point, True);
      Dragging := False;
      Exit
    end;
    WM_LBUTTONUP, WM_RBUTTONUP:
    begin
      if not Inspector.Contains(Point)
          and not DragMoved
          and not RadarDragging
          and (Message = WM_LBUTTONUP) then
        Click(Point, False);
      Dragging := False;
      RadarDragging := False;
      Exit;
    end;
    WM_MOUSEMOVE:
    begin
      if RadarDragging then
      begin
        RadarPan(Point);
        Exit
      end;
      if Dragging then
      begin
        if Hypot(Point.X - DragStart.X, Point.Y - DragStart.Y) > 3 then
          DragMoved := True;
        if DragMoved then
        begin
          ZoomAnchored := False;
          FollowSelection := False;
          Camera.X := Camera.X + (LastDrag.X - Point.X) / Zoom;
          Camera.Y := Camera.Y + (LastDrag.Y - Point.Y) / Zoom;
          TargetCamera := Camera;
          LastDrag := Point;
        end;
      end;
      Exit;
    end;
  end;
  inherited ProcessWindowMessage(Message, WParam, LParam);
end;
procedure TObserverScreen.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
end;
destructor TObserverScreen.Destroy;
begin
  OnClose;
  inherited Destroy;
end;
procedure TObserverScreen.OnClose;
begin
  if Worker <> nil then
  begin
    SetEvent(ScriptUiAbortEvent);
    SetEvent(TalkCompletedEvent);
    Worker.WaitFor;
    Worker.Recording.Free;
    FreeAndNil(Worker)
  end;
  FreeAndNil(Inspector);
  FreeAndNil(Scenes);
  FreeAndNil(Recording);
  sr_gpu_view(1, 0, 0, 0, 0, GameScreenWidth, GameScreenHeight);
  sr_gpu_clip(0, 0, GameScreenWidth, GameScreenHeight);
  RequestedScreenId := screenNone;
end;
// CHANGE: ENHANCEMENT - Run the galaxy observer with inspection and playback controls.
procedure RunObserver(const SavePath: AnsiString);
var
  Screen: TObserverScreen;
begin
  if SavePath <> '' then
    if not LoadGameFromFile(UTF8Decode(SavePath)) then
      raise Exception.Create('Observer load failed: ' + UTF8Encode(LastSaveLoadError));
  WaitForTurnCalculation;
  ParkObserverPlayer;
  ObserverSimulatedTurns := 0;
  CurrentScreenId := screenPlanet;
  RequestedScreenId := screenNone;
  ShowFrameRate := False;
  ObserverVisualRandom := True;
  Screen := TObserverScreen.Create;
  try
    Screen.InitializeFromConfig(UiStyleConfig, 'StarMap', True);
    Screen.InitializeLayout;
    Screen.RegisteredLoopName := 'Observer';
    Screen.RunContinuous;
  finally
    Screen.Free;
    ObserverVisualRandom := False
  end;
end;
end.
