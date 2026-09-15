{$EXCESSPRECISION OFF}
unit fLoad;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types,
  Classes,
  EC_Thread,
  EC_BlockPar,
  GI_MessageLoop,
  fPanelLoad;
type
  TCacheLoader = class;
  TfLoad = class;
  TCacheLoader = class(TThreadEC)
    PendingLoads: TList;
    TotalLoadCount: Integer;
    CompletedLoadCount: Integer;
    procedure Execute; override;
    procedure SetPendingLoads(Loads: TList; StartImmediately: Boolean);
  end;
  TfLoad = class(TMessageLoopGI)
    ProgressTimer: PCallbackTimerGI;
    LoadProgress: Single;
    DisplayedProgress: Single;
    LoadingFinished: Boolean;
    GapDD: array[0..2] of Byte;
    IntroSkipRequest: Integer;
    IntroTimer: PCallbackTimerGI;
    IntroStartedAt: Cardinal;
    IntroConfig: TBlockParEC;
    IntroItemIndex: Integer;
    IntroVideoFrameCount: Integer;
    IntroDurationMs: Integer;
    IntroImageKind: Integer;
    LoadPanel: TfPanelLoad;
    BackgroundStyle: Integer;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    procedure UpdateLoadingProgress(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure IntroMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure IntroKeyDown(Sender: TObjectGI; Key: Cardinal);
    procedure StartIntroItem(Index: Integer);
    procedure UpdateIntro(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
var
  IntroFinished: Boolean = False;
  IntroPlaying: Boolean;
procedure QueueCommonLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
procedure QueueSpaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
procedure QueueHyperspaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
procedure QueueArcadeLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
procedure RemoveDuplicateCacheLoads(PendingLoads: TList);
procedure QueueConfiguredLoadingAssets(PendingLoads: TList; Path: WideString);
procedure LoadPendingAssets(PendingLoads: TList);
procedure LinkRecoveredTypes;
implementation

uses
  EC_CacheGAI,
  Windows,
  SysUtils,
  Math,
  MMSystem,
  EC_Cache,
  EC_Str,
  GR_Main,
  Globals,
  GlobalsV,
  GI_GAI,
  GI_XviD,
  ab_Object,
  aGalaxy,
  SE_Gate;

procedure QueueCommonLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  if ScreenLoadMode <> 4 then
  begin
    QueueConfiguredLoadingAssets(PendingLoads, 'LoadGame');
    RemoveDuplicateCacheLoads(PendingLoads);
  end;

  if AnimMenuShip then
  begin
    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.2ShipA1');
    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.2ShipA2');
    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.2ShipA3');
  end;

  if Cardinal(GameScreenWidth) >= 1600 then

  begin
    if AnimMenuShip then
    begin
      GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.AnimGaalShip01A');
      GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.AnimGaalShip02A');
      GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', 'Bm.FormMain3.AnimGaalShip03A');
    end;

    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.AnimGaalShip01');

    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.AnimGaalShip02');
    GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.AnimGaalShip03');
  end;

  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.2Ship1');

  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.2Ship2');
  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.2Ship3');

  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain2.2AnimCaption');
  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GI', 'Bm.FormMain3.2BG');
end;
procedure QueueSpaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TSputnikTempl;
  I, Count: Integer;
  Gate: TGateSE;
begin
  PlayerStar.QueueSpaceImageLoads(PendingLoads, Owner);
  if SputnikShow then
  begin
    Count := SatelliteRenderTemplates.Count;
    for I := 0 to Count - 1 do
    begin
      Template := SatelliteRenderTemplates[I];
      GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'PlanetTempl', Template.MaskName);
    end;
  end;
  Gate := TGateSE.Create('Gate', Classes.Point(0, 0));
  Gate.QueueImageLoad(PendingLoads, Owner);
  Gate.Free;

  for I := 0 to High(SpaceImageTemplates) do
    if TCGaiControlEC(SpaceImageTemplates[I].CacheControl) <> nil then
      TCGaiControlEC(SpaceImageTemplates[I].CacheControl).QueueLoadIfMissing(PendingLoads);

  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', PlayerStar.GetBackgroundImagePath(I));
  QueueConfiguredLoadingAssets(PendingLoads, 'Space');
  if SoundEnabled then
    QueueConfiguredLoadingAssets(PendingLoads, 'SpaceSound');
  RemoveDuplicateCacheLoads(PendingLoads);

end;
procedure QueueHyperspaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  PlayerStar.QueueHyperspaceShipImageLoads(PendingLoads, Owner);
  RemoveDuplicateCacheLoads(PendingLoads);
end;
procedure QueueArcadeLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  ab_Object_QueueImageLoads(PendingLoads, Owner);
  QueueConfiguredLoadingAssets(PendingLoads, 'AB');
  RemoveDuplicateCacheLoads(PendingLoads);
end;
procedure RemoveDuplicateCacheLoads(PendingLoads: TList);
var
  I, J: Integer;
  First, Second: TCacheControlEC;
begin
  I := 0;
  while PendingLoads.Count - 1 > I do
  begin
    First := TCacheControlEC(PendingLoads[I]);
    J := I + 1;
    while PendingLoads.Count > J do
    begin
      Second := TCacheControlEC(PendingLoads[J]);
      if (First.ClassName = Second.ClassName) and (First.CacheKey = Second.CacheKey) then
      begin
        Second.Free;
        PendingLoads.Delete(J);
      end
      else
        Inc(J);
    end;
    Inc(I);
  end;
end;
procedure QueueConfiguredLoadingAssets(PendingLoads: TList; Path: WideString);
var
  I, Count: Integer;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Load.' + Path);
  Count := Block.GetBlockCount;
  for I := 0 to Count - 1 do
    QueueConfiguredLoadingAssets(PendingLoads, Path + '.' + Block.GetBlockNameByIndex(I));
  Count := Block.GetParamCount;
  for I := 0 to Count - 1 do
    GlobalCache
        .QueueNamedLoadIfMissing(PendingLoads, Block.GetParamName(I), Block.GetParamValue(I));
end;
procedure LoadPendingAssets(PendingLoads: TList);
var
  I, Count: Integer;
  Control: TCacheControlEC;
begin
  Count := PendingLoads.Count;
  for I := 0 to Count - 1 do
  begin
    Control := TCacheControlEC(PendingLoads[I]);

    Control.AcquireData;
    Control.Release;
    Control.Free;
  end;
  PendingLoads.Clear;
end;
procedure TCacheLoader.Execute;
var
  I, Count: Integer;
  Control: TCacheControlEC;
begin
  if PendingLoads <> nil then
  begin
    Count := PendingLoads.Count;

    for I := 0 to Count - 1 do
    begin
      while (Flag18 or ((Galaxy <> nil) and Galaxy.Destroying))
          and not ExitScreenLoop
          and not IsStopRequested do
        SysUtils.Sleep(100);
      Control := TCacheControlEC(PendingLoads[I]);
      if not ExitScreenLoop and not IsStopRequested then
      begin

        Control.AcquireData;
        Control.Release;

      end;
      Control.Free;
      Inc(CompletedLoadCount);
    end;
    PendingLoads.Free;
    PendingLoads := nil;
  end;

end;
procedure TCacheLoader.SetPendingLoads(Loads: TList; StartImmediately: Boolean);
begin
  if IsRunning then
    WaitForIdle(INFINITE);
  PendingLoads := Loads;
  CompletedLoadCount := 0;
  TotalLoadCount := PendingLoads.Count;
  SetPriority(1);
  if StartImmediately then
    Start;
end;
constructor TfLoad.Create;
begin
  inherited Create;
  LoadPanel := TfPanelLoad.Create;
end;
destructor TfLoad.Destroy;
begin
  if LoadPanel <> nil then
  begin
    LoadPanel.Free;
    LoadPanel := nil;
  end;
  inherited Destroy;
end;
procedure TfLoad.InitializeLayout;
var
  Root: TObjectGI;
begin
  inherited InitializeLayout;
  AppendLogTextThreadSafe('fLoad... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Root := GetByName('');
  Root.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  Root.FindByNameRecursive('IntroRect').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  with Root.FindByNameRecursive('Intro') as TgaiGI do
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  Root.FindByNameRecursive('Film').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  AppendLogLineThreadSafe('ok');
  LoadPanel.InitializeLayout(Self);
end;
procedure TfLoad.OnOpen;
var
  Loads: TList;
  PollMs: Integer;
begin
  // CHANGE: PERFORMANCE - Skip travel waits/presentation when fast transitions are enabled.
  DeferScreenPresentation := FastTravelTransitions and (ScreenLoadMode = 2);
  if DeferScreenPresentation then
    PollMs := 1
  else
    PollMs := 20;
  IntroSkipRequest := 0;
  LoadPanel.OnOpen;
  ContentPanel.KeyDownCallback := IntroKeyDown;
  ContentPanel.LeftButtonDownCallback := IntroMouseDown;
  ContentPanel.RightButtonDownCallback := IntroMouseDown;
  if SkipIntro then
    IntroFinished := True;
  if IntroFinished and (MusicManager.CategoryOverride = '') then
    MusicManager.RequestFadeOut;
  LoadProgress := 0;
  DisplayedProgress := 0;
  LoadingFinished := False;
  SetCursorActive(False);
  Loads := TList.Create;
  if (ScreenLoadMode = 0) or (ScreenLoadMode = 4) then
    QueueCommonLoadingAssets(Loads, RootUiObject)
  else if ScreenLoadMode = 2 then
    QueueSpaceLoadingAssets(Loads, RootUiObject)
  else if ScreenLoadMode = 3 then
  begin
    QueueCommonLoadingAssets(Loads, RootUiObject);
    QueueSpaceLoadingAssets(Loads, RootUiObject);
  end;
  if Loads.Count > 0 then
  begin
    CacheLoader.SetPendingLoads(Loads, False);
    ProgressTimer := ScheduleCallbackTimer(PollMs, PollMs, UpdateLoadingProgress);
  end
  else
  begin
    Loads.Free;
    RequestClose(1);
  end;
  if IntroFinished then
  begin
    CacheLoader.Start;
    LoadPanel.SetProgress(0);
    if not DeferScreenPresentation then
      LoadPanel.Show;
  end
  else
  begin
    IntroPlaying := True;
    CacheLoader.Start;
    IntroSkipRequest := 0;
    IntroTimer := nil;
    IntroConfig := MainDataConfig.GetBlock('Intro');
    StartIntroItem(1);
  end;
end;
procedure TfLoad.OnClose;
begin
  with GetByName('Film') as TxvidGI do
    ImageClose;
  LoadPanel.OnClose;
  if CacheLoader.IsRunning then
    CacheLoader.WaitForIdle(INFINITE);
  if ProgressTimer <> nil then
  begin
    CancelCallbackTimer(ProgressTimer);
    ProgressTimer := nil;
  end;
  if IntroTimer <> nil then
  begin
    CancelCallbackTimer(IntroTimer);
    IntroTimer := nil;
  end;
  if (ScreenLoadMode = 0) or (ScreenLoadMode = 3) then
  begin

    MainMenuScreen.InitializeLayout;
    PlanetQuestScreen.InitializeLayout;
    LoadScreen.InitializeLayout;
    NewGameScreen.InitializeLayout;
    IntroductionScreen.InitializeLayout;
    HangarScreen.InitializeLayout;
    PlanetScreen.InitializeLayout;
    UninhabitedPlanetScreen.InitializeLayout;
    RuinsTalkScreen.InitializeLayout;
    ArcadeBattleScreen.InitializeLayout;
    EquipmentShopScreen.InitializeLayout;
    GoodsShopScreen.InitializeLayout;
    GovernmentScreen.InitializeLayout;
    InfoScreen.InitializeLayout;
    RangerRatingScreen.InitializeLayout;
    RewardsScreen.InitializeLayout;
    ShipScreen.InitializeLayout;
    ScannerScreen.InitializeLayout;
    StarMapScreen.InitializeLayout;
    FilmScreen.InitializeLayout;
    GalaxyScreen.InitializeLayout;
    JumpScreen.InitializeLayout;
    SaveManagerScreen.InitializeLayout;
    GameLoadScreen.InitializeLayout;
    GameMenuScreen.InitializeLayout;
    SettingsScreen.InitializeLayout;
    GameEndScreen.InitializeLayout;
    AboutScreen.InitializeLayout;
    ScoreScreen.InitializeLayout;
    SpaceObjectUiLoop.InitializeLayout;
    TalkScreen.InitializeLayout;
    SelectFaceScreen.InitializeLayout;
    JournalScreen.InitializeLayout;
    LoadRobotScreen.InitializeLayout;
    LoadQuestScreen.InitializeLayout;
    LoadArcadeScreen.InitializeLayout;
    AchievementsScreen.InitializeLayout;

  end;
  IntroFinished := True;
  RequestedScreenId := PostLoadScreenId;
  PostLoadScreenId := screenNone;
end;
procedure TfLoad.UpdateLoadingProgress(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  if not LoadingFinished then
  begin
    if CacheLoader.IsRunning then
      LoadProgress := CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount
    else
    begin
      LoadingFinished := True;
      LoadProgress := 1;
    end;
  end;
  if DisplayedProgress < LoadProgress then
  begin
    DisplayedProgress := Min(0.05 + DisplayedProgress, LoadProgress);
    LoadPanel.SetProgress(DisplayedProgress);
  end;
  if not LoadingFinished then
    Exit;
  // Keep intro playback, but do not wait for a cosmetic progress ramp.
  if not IntroPlaying then
  begin
    DisplayedProgress := 1;
    LoadPanel.SetProgress(1);
    Present;
    RequestClose(1);
  end;
end;
procedure TfLoad.IntroMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  IntroSkipRequest := 1;
end;
procedure TfLoad.IntroKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key <> 0 then
  begin
    IntroSkipRequest := 1;
    if Key = VK_ESCAPE then
      Inc(IntroSkipRequest);
  end;
end;
procedure TfLoad.StartIntroItem(Index: Integer);
var
  Block: TBlockParEC;
  ImagePath: WideString;
begin
  Block := IntroConfig.FindBlock(IntToStr(Index));
  if (Block = nil) or (IntroSkipRequest > 1) then
  begin
    InvalidateViewport;
    IntroPlaying := False;
    Exit;
  end;
  IntroItemIndex := Index;
  if Block.CountParams('Image') = 0 then
  begin
    StartIntroItem(Index + 1);
    Exit;
  end;
  ImagePath := Block.GetParam('Image');
  if LowerCaseWideString(TrimWideString(ExtractFileExtNoDotW(ImagePath))) = 'vdo' then
  begin
    IntroImageKind := 0;
    with GetByName('Film') as TxvidGI do
      if not ImageOpen(ImagePath, False) then
      begin
        StartIntroItem(Index + 1);
        Exit;
      end;
    if Block.CountParams('Frames') > 0 then
      IntroVideoFrameCount := ExtractDigitsToIntW(Block.GetParam('Frames'));
  end
  else
  begin
    IntroImageKind := 1;
    with GetByName('Intro') as TgaiGI do
    begin
      SetImagePath(ImagePath);
      SetPosition(Classes.Point(0, 0));
      SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
      if Block.CountParams('Size') > 0 then
      begin
        ImagePath := Block.GetParam('Size');
        if CountDelimitedPartsW(ImagePath, ',') > 1 then
        begin
          SetSize(
              Classes.Point(
                  ExtractDigitsToIntW(ExtractDelimitedPartW(ImagePath, 0, ',')),
                  ExtractDigitsToIntW(ExtractDelimitedPartW(ImagePath, 1, ','))
              )
          );
          SetPosition(
              Classes.Point(
                  (GameScreenWidth - ClientSize.X) div 2,
                  (GameScreenHeight - ClientSize.Y) div 2
              )
          );
          if Block.CountParams('Sme') > 0 then
          begin
            ImagePath := Block.GetParam('Sme');
            if CountDelimitedPartsW(ImagePath, ',') > 1 then
              SetPosition(
                  Classes.Point(
                      LocalPosition.X
                          + ExtractSignedDigitsToIntW(ExtractDelimitedPartW(ImagePath, 0, ',')),
                      LocalPosition.Y
                          + ExtractSignedDigitsToIntW(ExtractDelimitedPartW(ImagePath, 1, ','))
                  )
              );
          end;
        end;
      end;
      if Block.CountParams('Frames') > 0 then
        LoadFrameSequenceFromText('[80,0-' + Block.GetParam('Frames') + ']');
      PrimeImageCaches;
      SetActive(True);
      StopAutoPlayback;
      SetSequenceFrame(0);
    end;
  end;
  if Block.CountParams('Time') > 0 then
    IntroDurationMs := ExtractDigitsToIntW(Block.GetParam('Time'));
  if MusicEnabled then
    if Block.CountParams('Sound') > 0 then
    begin
      MusicManager.PlayCategory(Block.GetParam('Sound'));
      while not MusicManager.IsPlaying do
        SysUtils.Sleep(1);
    end;
  IntroStartedAt := timeGetTime;
  if IntroTimer <> nil then
  begin
    CancelCallbackTimer(IntroTimer);
    IntroTimer := nil;
  end;
  IntroSkipRequest := 0;
  IntroTimer := ScheduleCallbackTimer(5, 5, UpdateIntro);
end;
procedure TfLoad.UpdateIntro(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Fraction: Double;
begin
  Fraction := (timeGetTime - IntroStartedAt) / IntroDurationMs;
  if Fraction > 1 then
    Fraction := 1;
  if (Fraction >= 1) or (IntroSkipRequest > 0) then
  begin
    if IntroTimer <> nil then
    begin
      CancelCallbackTimer(IntroTimer);
      IntroTimer := nil;
    end;
    if MusicEnabled then
    begin
      MusicManager.StopImmediately;
      while MusicManager.IsPlaying do
        SysUtils.Sleep(1);
    end;
    with GetByName('Film') as TxvidGI do
      ImageClose;
    with GetByName('Intro') as TgaiGI do
      SetImagePath('');
    StartIntroItem(IntroItemIndex + 1);
    Exit;
  end;
  if IntroImageKind = 0 then
  begin
    with GetByName('Film') as TxvidGI do
      SetFramePosition(Round((IntroVideoFrameCount - 1) * Fraction));
  end
  else
  begin
    with GetByName('Intro') as TgaiGI do
      SetFramePosition(Round((SequenceFrameCount - 1) * Fraction), True);
  end;
end;
procedure LinkRecoveredTypes;
begin
  TgaiGI.ClassName;
  TxvidGI.ClassName;
end;
end.
