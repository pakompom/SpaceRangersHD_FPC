{$EXCESSPRECISION OFF}
unit fGameLoad;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Thread,
  GI_MessageLoop,
  fPanelLoad;
type
  TThreadGameLoad = class;
  TfGameLoad = class;
  TThreadGameLoad = class(TThreadEC)
    Succeeded: Boolean;
    Gap2D: array[0..2] of Byte;
    procedure Execute; override;
  end;
  TfGameLoad = class(TMessageLoopGI)
    LoadThread: TThreadGameLoad;
    ProgressTimer: PCallbackTimerGI;
    AssetPreloadStarted: Boolean;
    GapD9: array[0..2] of Byte;
    TargetProgress: Single;
    DisplayedProgress: Single;
    LoadingComplete: Boolean;
    GapE5: array[0..2] of Byte;
    LoadPanel: TfPanelLoad;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    function IsLoading: Boolean;
    procedure UpdateLoadingProgress(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  aCalc,
  GI_MessageBox,
  aGalaxyStruct,
  SysUtils,
  Classes,
  Windows,
  Math,
  GR_Main,
  GR_Music,
  Globals,
  GlobalsV,
  GI_Main,
  EC_BlockPar,
  aConst,
  aMyFunction,
  aPlayer,
  aGalaxy,
  aSaveLoad,
  fLoad,
  fStarMap;

procedure TThreadGameLoad.Execute;
begin
  Succeeded := False;
  Succeeded := LoadGameFromFile(PendingLoadFileName);
end;

constructor TfGameLoad.Create;
begin
  inherited Create;
  LoadPanel := TfPanelLoad.Create;
end;

destructor TfGameLoad.Destroy;
begin
  FreeAndNil(LoadThread);
  if LoadPanel <> nil then
  begin
    LoadPanel.Free;
    LoadPanel := nil;
  end;
  inherited Destroy;
end;

procedure TfGameLoad.InitializeLayout;
begin
  inherited;
  AppendLogTextThreadSafe('fGameLoad... ');
  ViewportRect :=
      Classes.Rect(
          ExtraScreenWidth div 2,
          ExtraScreenHeight div 2,
          ViewportRect.Left + ExtraScreenWidth div 2,
          ViewportRect.Top + ExtraScreenHeight div 2
      );
  GetByName('PanelLoad').Parent.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  AppendLogLineThreadSafe('ok');
  LoadPanel.InitializeLayout(Self);
end;

procedure TfGameLoad.OnOpen;
begin

  LoadPanel.OnOpen;
  LoadPanel.Show;
  if MusicManager.CategoryOverride = '' then
    MusicManager.RequestFadeOut;
  TargetProgress := 0;
  DisplayedProgress := 0;
  LoadingComplete := False;
  if MemorySnapshotBuffer <> nil then
    MemorySnapshotBuffer.Free;
  MemorySnapshotBuffer := nil;
  MemorySnapshotActive := False;
  if (Galaxy <> nil) and not Galaxy.Destroying then
    Galaxy.Free;
  Galaxy := nil;
  AssetPreloadStarted := False;
  // Reuse the worker. FPC's main-thread WaitFor/CheckSynchronize added about
  // 100 ms to each load when this screen destroyed its already idle worker.
  if LoadThread = nil then
    LoadThread := TThreadGameLoad.Create;
  LoadThread.SetPriority(2);
  LoadThread.Start;
  ProgressTimer := ScheduleCallbackTimer(20, 20, UpdateLoadingProgress);
  LoadPanel.SetProgress(0);
end;

procedure TfGameLoad.OnClose;
var
  Category: WideString;
begin
  LoadPanel.OnClose;
  if LoadThread <> nil then
  begin
    LoadThread.WaitForIdle(INFINITE);
  end;
  if ProgressTimer <> nil then
  begin
    CancelCallbackTimer(ProgressTimer);
    ProgressTimer := nil;
  end;
  if MusicManager.CategoryOverride = '' then
  begin
    if GetPlayer = nil then
      MusicManager.PlayCategory('Base')
    else if GetPlayer.IsOnPlanet then
    begin
      if GetPlayer.CurrentPlanet.OwnerId = 7 then
      begin
        if not GetPlayer.CurrentPlanet.IsMainPiratePlanet then
          MusicManager.PlayCategory(
              'Nation.'
                  + OwnerInfo[Integer(RaceToOwner(GetPlayer.CurrentPlanet.RaceId)) and $7F]
                      .InternalName
                  + 'Pirate'
          )
        else
          MusicManager.PlayCategory('Nation.PiratePlanetMain');
      end
      else
        MusicManager
            .PlayCategory('Nation.' + OwnerInfo[GetPlayer.CurrentPlanet.OwnerId].InternalName);
    end
    else if GetPlayer.IsDockedToShip then
    begin
      if GetPlayer.DockedTo.TypeId in [6..13] then
      begin
        Category := GetPlayer.DockedTo.TypeNameOverrideKey;
        if (Category <> '') and (MainDataConfig.GetBlock('Music').CountBlocks(Category) > 0) then
          MusicManager.PlayCategory(GetPlayer.DockedTo.TypeNameOverrideKey)
        else
          MusicManager.PlayCategory(GetPlayer.DockedTo.GetTypeNameKey);
      end
      else
      begin
        // Retain the native CurrentPlanet lookup in this non-station docking branch.
        if GetPlayer.CurrentPlanet.OwnerId = 7 then
          MusicManager.PlayCategory(
              'Nation.'
                  + OwnerInfo[Integer(RaceToOwner(GetPlayer.CurrentPlanet.RaceId)) and $7F]
                      .InternalName
                  + 'Pirate'
          )
        else
          MusicManager
              .PlayCategory('Nation.' + OwnerInfo[GetPlayer.CurrentPlanet.OwnerId].InternalName);
      end;
    end
    else if GetPlayer.InNormalSpace then
    begin
      if MusicInSpaceEnabled then
      begin
        if (GetPlayer.GetHull.CapitalShip = 1) and (RandomIntRange(0, 100) < 20) then
        begin
          StarMapScreen.BattleMusicSelected := True;
          MusicManager.PlayCategory('Destroyer');
        end
        else
        begin
          StarMapScreen.BattleMusicSelected := False;
          MusicManager.PlayCategory('StarMap');
        end;
      end
      else
        MusicManager.RequestFadeOut;
    end;
    // The host music controller advances in the event loop; queueing/fading
    // does not require blocking the screen transition for the native 100 ms.
    MusicManager.RequestFadeOut;
  end;
  if Galaxy <> nil then
    aCalc.WaitForTurnCalculationUI;
end;

function TfGameLoad.IsLoading: Boolean;
begin
  if (LoadThread <> nil) and LoadThread.IsRunning then
    Result := True
  else
    Result := False;
end;

procedure TfGameLoad.UpdateLoadingProgress(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Loads: TList;
  Block: TBlockParEC;
begin
  if LoadThread.IsRunning then
  begin
    if (LoadingFilmCount < 0) and (ActiveLoadBuffer <> nil) then
      TargetProgress := ActiveLoadBuffer.Position / ActiveLoadBuffer.DataSize * 0.5;
  end
  else if not LoadingComplete then
  begin
    if not LoadThread.Succeeded then
    begin
      if SelectedMods <> LoadedSaveModSet then
      begin
        if ShowMessageBoxGI(
                GetInnermostScreenLoop,
                LanguageDataConfig.GetParamByPathOrMarker('FormSaveManager.QueryReloadMods'),
                35,
                0,
                0,
                0)
            = 1 then
        begin
          Block := TBlockParEC.Create;
          Block.AddParam('CurrentMod', LoadedSaveModSet);
          Block.SaveTextFile('Mods\ModCFG.txt', True, False);
          Block.Free;
          RequestedScreenId := screenNone;
          PostLoadScreenId := screenGameLoad;
          ReloadModsRequested := True;
          RequestClose(1);
          Exit;
        end;
      end
      else
        ShowMessageBoxGI(
            Self,
            LanguageDataConfig.GetParamByPathOrMarker('FormSaveManager.LoadError')
                + #13#10
                + LastSaveLoadError,
            33,
            0,
            0,
            0
        );
      RequestedScreenId := screenMainMenu;
      ApplyEditableSaveOnLoad := False;
      RequestClose(1);
      Exit;
    end;
    if not AssetPreloadStarted then
    begin

      Loads := TList.Create;
      StarMapScreen.ResumeMode := smrOrders;
      if ScreenUsesCompositeLoadAssets(RequestedScreenId) then
        QueueSpaceLoadingAssets(Loads, RootUiObject);
      if Loads.Count < 1 then
      begin
        Loads.Free;
        TargetProgress := 1;
        LoadingComplete := True;
        AssetPreloadStarted := True;
      end
      else
      begin
        CacheLoader.SetPendingLoads(Loads, True);
        AssetPreloadStarted := True;
      end;
    end
    else if not CacheLoader.IsRunning then
    begin
      LoadingComplete := True;
      TargetProgress := 1;
    end
    else
      TargetProgress := CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount * 0.5 + 0.5;
  end;
  if DisplayedProgress < TargetProgress then
  begin
    DisplayedProgress := Min(0.005 + DisplayedProgress, TargetProgress);
    LoadPanel.SetProgress(DisplayedProgress);
  end;
  // The progress animation must not delay a fully loaded save.
  if LoadingComplete then
  begin
    DisplayedProgress := 1;
    LoadPanel.SetProgress(1);
    RequestClose(1);
  end;
end;

procedure TfGameLoad.SelectMusic;
begin
end;

end.
