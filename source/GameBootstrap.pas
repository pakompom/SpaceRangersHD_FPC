{$EXCESSPRECISION OFF}
unit GameBootstrap;

// Shared FPC game startup and application lifecycle.
interface

procedure RunRangers;

implementation

uses
  RTLFileSystem,
  fIntroduction,
  fGameSettings2,
  CrashSymbols,
  WorkerErrors,
  BaseUnix,
  GameNative,
  Windows,
  SysUtils,
  Classes,
  Forms,
  MMSystem,
  ActiveX,
  GameApplication,
  GR_Main,
  Globals,
  GlobalsV,
  EC_BlockPar,
  EC_Str,
  EC_Expression,
  EC_HsFile,
  aPacket,
  aPlayer,
  aGalaxy,
  aScript,
  aMyFunction,
  GI_Main,
  GI_MessageLoop,
  GI_GraphButton,
  fMainForm,
  fLoadQuest,
  fPlanetQuest,
  fLoad,
  fLoadRobot,
  fLoadAB,
  fSaveManager,
  fPanelLoad,
  MessageText,
  fCfgSettings,
  fAbout,
  fAchievements,
  fScore,
  Achievements,
  NoSteamAchievemens,
  aConst,
  ThreadCalc,
  aSaveLoad,
  ObserverHost;

var
  ApplicationEvents: TAD;
  StartupStage: AnsiString;
  LogReady, PlatformReady, TimerPeriodStarted, CampaignRuntimeStarted, ScriptRuntimeStarted:
      Boolean;
  GameDirectory, UserDirectory, ExecutablePath: AnsiString;
  RestartRequested: Boolean;
  GpuRendererRequested: Boolean;
  ObserverMode: Boolean;
  ObserverSave: AnsiString;

procedure Log(const Text: AnsiString);
begin
  if LogReady then
    try
      AppendLogLineThreadSafe(Text);
    except
      // Do not replace a startup/cleanup exception with a failed log write.
    end;
end;

procedure Stage(const Text: AnsiString);
begin
  StartupStage := Text;

  Log('Rangers: ' + Text);
end;

procedure LogExceptionTrace;
var
  I: Integer;
begin
  Log('  ' + DescribeCodeAddress(ExceptAddr));
  for I := 0 to ExceptFrameCount - 1 do
    Log('  ' + DescribeCodeAddress(ExceptFrames[I]));
  DumpExceptionBackTrace(StdErr);
end;

procedure ReadOptions;
var
  I: Integer;
  Argument, Candidate: AnsiString;
  ExplicitLanguage: Boolean;
  LanguageFile: TStringList;
begin
  ExplicitLanguage := False;
  ExecutablePath := ExpandFileName(ParamStr(0));
  GameDirectory := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Candidate := GameDirectory;
  for I := 0 to 7 do
  begin
    if RTLFileSystem.FileExists(Candidate + '/INSTALL.TXT') then
    begin
      GameDirectory := Candidate;
      Break
    end;
    if RTLFileSystem.FileExists(Candidate + '/game/INSTALL.TXT') then
    begin
      GameDirectory := Candidate + '/game';
      Break
    end;
    Candidate := ExcludeTrailingPathDelimiter(ExtractFileDir(Candidate));
  end;
  UserDirectory :=
      SysUtils.GetEnvironmentVariable('HOME') + '/Library/Application Support/SpaceRangersHD';
  SelectedLanguage := 'russian';
  for I := 1 to ParamCount do
  begin
    Argument := ParamStr(I);
    if Argument = '--no-thumbnail-cache' then
      CacheInfoThumbnails := False
    else if Argument = '--renderer=software' then
    begin
      GpuRendererRequested := False;
      sr_renderer_select(0)
    end
    else if Argument = '--renderer=sdl' then
    begin
      GpuRendererRequested := True;
      sr_renderer_select(1)
    end
    else if Argument = '--transitions=fast' then
      FastTravelTransitions := True
    else if Argument = '--transitions=original' then
      FastTravelTransitions := False
    else if Argument = '--observer' then
      ObserverMode := True
    else if Pos('--observer-save=', Argument) = 1 then
    begin
      ObserverMode := True;
      ObserverSave := ExpandFileName(Copy(Argument, 17, MaxInt))
    end
    else if Pos('--game-dir=', Argument) = 1 then
      GameDirectory := Copy(Argument, 12, MaxInt)
    else if Pos('--user-dir=', Argument) = 1 then
      UserDirectory := Copy(Argument, 12, MaxInt)
    else if Pos('--language=', Argument) = 1 then
    begin
      SelectedLanguage := WideString(Copy(Argument, 12, MaxInt));
      ExplicitLanguage := True
    end
    else
      raise Exception.Create('Unknown argument: ' + Argument);
  end;
  GameDirectory := ExpandFileName(GameDirectory);
  UserDirectory := ExcludeTrailingPathDelimiter(ExpandFileName(UserDirectory));
  if ObserverMode then
  begin
    GpuRendererRequested := True;
    sr_renderer_select(1)
  end;
  if not RTLFileSystem.FileExists(IncludeTrailingPathDelimiter(GameDirectory) + 'INSTALL.TXT') then
    raise Exception.Create('Game assets not found; use --game-dir=/path/to/game');
  if not SetCurrentDir(GameDirectory) then
    RaiseLastOSError;
  if not ForceDirectories(UserDirectory) then
    raise Exception.Create('Cannot create user directory: ' + UserDirectory);
  if not ExplicitLanguage and RTLFileSystem.FileExists(UserDirectory + '/Lang.txt') then
  begin
    LanguageFile := TStringList.Create;
    try
      LanguageFile.LoadFromFile(UserDirectory + '/Lang.txt');
      if LanguageFile.Values['Lang'] <> '' then
        SelectedLanguage := WideString(LanguageFile.Values['Lang']);
    finally
      LanguageFile.Free
    end;
  end;
  ForceDirectories(UserDirectory + '/Cache');
  ForceDirectories(UserDirectory + '/Save');
  OverrideGameUserDirectory := WideString(UserDirectory);
  CachedGameUserDirectory := '';
end;

procedure PrepareUserSettings;
var
  Settings: TBlockParEC;
  FileName: WideString;
{$IFDEF ANDROID}
  DisplayWidth, DisplayHeight, SwapSize: Integer;
{$ENDIF}
begin
  FileName := GetGameUserDirectory + 'CFG.TXT';
  Settings := TBlockParEC.Create;
  try
    if RTLFileSystem.FileExists(AnsiString(FileName)) then
      Settings.LoadFromTextFileWithEncodingProbe(PWideChar(FileName), True)
    else
    begin
      Settings.LoadFromTextFileWithEncodingProbe('CFG.TXT', True);
      Settings.SetOrAddParam('Window', 'True');
      Settings.SetOrAddParam('VideoMode', '1024,768');
    end;
{$IFDEF ANDROID}
    // Resolve the physical display before allocating the game render buffers.
    if sr_display_size(DisplayWidth, DisplayHeight) <> 0 then
    begin
      if DisplayWidth < DisplayHeight then
      begin
        SwapSize := DisplayWidth;
        DisplayWidth := DisplayHeight;
        DisplayHeight := SwapSize;
      end;
      // The recovered layouts require at least 1024x768.
      if DisplayWidth < 1024 then
        DisplayWidth := 1024;
      if DisplayHeight < 768 then
        DisplayHeight := 768;
      Settings.SetOrAddParam('VideoMode', IntToStr(DisplayWidth) + ',' + IntToStr(DisplayHeight));
      Log('Android render resolution: ' + IntToStr(DisplayWidth) + 'x' + IntToStr(DisplayHeight));
    end;
{$ENDIF}
    // Movie playback and recording are unavailable in the native runtime.
    Settings.SetOrAddParam('HardwareRender', 'False');
    Settings.SetOrAddParam('ShowSystemMouse', 'False');
    Settings.SetOrAddParam('SkipIntro', 'True');
    Settings.SetOrAddParam('SkipVideo', 'True');
    Settings.SetOrAddParam('FilmBufSize', '0');
    Settings.SetOrAddParam('FilmFPS', '20');
    Settings.SaveTextFile(PWideChar(FileName), True, False);
  finally
    Settings.Free;
  end;
end;

procedure InitializeScreens;
begin
  CampaignRuntimeStarted := True;
  InitializeGlobalUiRuntime;
end;

procedure RunScreens;
var
  NextScreen: TGameScreenId;
  Screen: TMessageLoopGI;
begin
  ScreenLoadMode := 0;
  PostLoadScreenId := screenMainMenu;
  RequestedScreenId := screenLoad;
  while not ExitScreenLoop and (RequestedScreenId <> screenNone) do
  begin
    NextScreen := RequestedScreenId;
    if NextScreen = screenLoadRobot then
      raise Exception.Create('This port has robot battles disabled');

    if ObserverMode
        and (Galaxy <> nil)
        and (GetPlayer <> nil)
        and (NextScreen
            in [
                screenStarMap,
                screenPlanet,
                screenPlanetNO,
                screenRuinsTalk,
                screenIntroduction]) then
    begin
      RunObserver('');
      Break
    end;

    Screen := TMessageLoopGI(RegisteredScreens[Ord(NextScreen)]);
    if Screen = nil then
      raise Exception.Create('Missing registered campaign screen');
    CurrentScreenId := NextScreen;
    RequestedScreenId := screenNone;
    Stage('run ' + AnsiString(Screen.RegisteredLoopName));
    if NextScreen in [screenArcadeBattle, screenStarMap, screenFilm] then
      Screen.RunContinuous
    else
      Screen.Run;
    if (NextScreen = screenSettings) and SettingsScreen.RestartRequested then
      RestartRequested := True;
    if ReloadModsRequested then
      RestartRequested := True;
    PreviousScreenId := NextScreen;
    CurrentScreenId := screenNone;
  end;
end;

procedure ReleaseObject(var Slot; const Name: AnsiString);
var
  Instance: TObject;
begin
  Instance := TObject(PPointer(@Slot)^);
  try
    try
      // Native child destructors still consult their owning global (Galaxy).
      Instance.Free;
    except
      on E: Exception do
      begin
        Log('Cleanup ' + Name + ': ' + E.ClassName + ': ' + E.Message);
        LogExceptionTrace;
        System.ExitCode := 1;
      end;
    end;
  finally
    PPointer(@Slot)^ := nil;
  end;
end;

procedure Shutdown;
begin
  Stage('shutdown');
  ExitScreenLoop := True;
  if TurnCalculationThread <> nil then
  begin
    WaitForTurnCalculation;
    // Join the worker while the galaxy and script/UI owners are still alive.
    FreeAndNil(TurnCalculationThread);
  end;
  if CampaignRuntimeStarted then
    try
      FinalizeGlobalUiRuntime
    except
      on E: Exception do
      begin
        Log('Campaign UI cleanup: ' + E.Message);
        System.ExitCode := 1
      end;
    end;
  ReleaseObject(Galaxy, 'galaxy');
  if ScriptRuntimeStarted then
    try
      FinalizeScriptHostRuntime
    except
      on E: Exception do
      begin
        Log('Script cleanup: ' + E.Message);
        System.ExitCode := 1
      end;
    end;
  ReleaseObject(AchievementDefinitions, 'achievement definitions');
  try
    FinalizeRuntimeAndSettings
  except
    on E: Exception do
    begin
      Log('Runtime cleanup: ' + E.Message);
      System.ExitCode := 1
    end;
  end;
  Direct3DDevice := nil;
  Direct3D := nil;
  ReleaseObject(EditableSaveBlock, 'save configuration');
  ReleaseObject(NewGameSettingsConfig, 'new-game configuration');
  UiStyleConfig := nil;
  UiDepthConfig := nil;
  try
    FreeDatConfigRoots
  except
    on E: Exception do
    begin
      Log('Config cleanup: ' + E.Message);
      System.ExitCode := 1
    end;
  end;
  ReleaseObject(ModInstallConfigs, 'mod install list');
  ReleaseObject(ModLanguageInstallConfigs, 'mod language list');
  ReleaseObject(QuestMessages, 'quest messages');
  ReleaseObject(InstallConfig, 'install configuration');
  ReleaseObject(LanguageInstallConfig, 'language configuration');
  if PackageCollection <> nil then
    try
      FinalizePackageCollection
    except
      on E: Exception do
      begin
        Log('Package cleanup: ' + E.Message);
        System.ExitCode := 1
      end;
    end;
  ClipCursor(nil);
  ShowCursor(True);
  if MainWindowHandle <> 0 then
  begin
    KillTimer(MainWindowHandle, 1);
    DestroyWindow(MainWindowHandle);
    MainWindowHandle := 0;
  end;
  if PlatformReady then
    CoUninitialize;
  if TimerPeriodStarted then
    timeEndPeriod(1);
  Application.OnActivate := nil;
  Application.OnDeactivate := nil;
  ReleaseObject(ApplicationEvents, 'application events');
  Log('Rangers: shutdown complete');
  LogReady := False;
  ReleaseObject(SessionLogLock, 'log lock');
end;

procedure RunRangers;
var
  ErrorText: AnsiString;
  RestartText: array[0..4] of AnsiString;
  RestartArgs: array[0..5] of PAnsiChar;
  I: Integer;
begin
  StartupStage := 'options and user directory';
  DecimalSeparator := '.';
  Randomize;
  MainRuntimeThreadId := GetCurrentThreadId;
  RuntimeStartupTick := timeGetTime;
  RuntimeActive := True;
  try
    try
      ReadOptions;
      CreateStartupLogFile;
      LogReady := True;
      Log('Game directory: ' + GameDirectory);
      Log('User directory: ' + UserDirectory);
      Application.Initialize;
      ApplicationEvents := TAD.Create;
      Application.OnActivate := ApplicationEvents.ApplicationActivated;
      Application.OnDeactivate := ApplicationEvents.ApplicationDeactivated;
      DebugKeyCallback := nil;
      RunningUnderWine := False;
      Stage('platform and window');
      InitializePlatformRuntimeAndMainWindow;
      PlatformReady := True;
      SetWindowTextA(MainWindowHandle, 'Rangers');
      Stage('language and packages');
      LoadLanguageAndPackages;
      Stage('stock DAT configuration');
      LoadDatConfigAndModOverrides;
      Stage('user settings');
      PrepareUserSettings;
      Stage('renderer, resources and audio');
      InitializeRuntimeAndSettings;
      if CacheInfoThumbnails then
        Log('Star info thumbnails: cached per turn')
      else
        Log('Star info thumbnails: cache disabled');
      if BuildVersionMismatch then
        raise Exception.Create('This build requires 2.1.2500 game data');
      GR_DXReset;
      ApplyGammaRamp(DisplayBrightness, DisplayContrast);
      Stage('campaign script runtime');
      ScriptRuntimeStarted := True;
      InitializeScriptHostRuntime;
      InitializeAchievementDefinitions;
      LoadLocalAchievements;
      AvailableLanguageCodes := CollectInstallLanguageCodes;
      if AvailableLanguageCodes = '' then
        AvailableLanguageCodes := SelectedLanguage;
      InitializeScreens;
      TimerPeriodStarted := timeBeginPeriod(1) = 0;
      if ObserverSave <> '' then
      begin
        Stage('galaxy observer');
        RunObserver(ObserverSave);
      end
      else
        RunScreens;
      // Workers stop the screen loop; show their error on the main thread while
      // the window and SDL are still alive, before shutdown destroys them.
      RaisePendingWorkerError;
    except
      on E: Exception do
      begin
        System.ExitCode := 1;
        ErrorText := 'Stage: ' + StartupStage + #13#10 + E.ClassName + ': ' + E.Message;
        Log(ErrorText);
        // The original worker backtrace is already in the log.
        if not (E is EWorkerFailure) then
          LogExceptionTrace;
        if LogReady then
          ErrorText :=
              ErrorText + #13#10#13#10 + 'Log: ' + UserDirectory + '/' + RuntimeLogFileName;
        MessageBoxA(
            0,
            PAnsiChar(ErrorText),
            'Rangers startup/runtime error',
            MB_OK or MB_ICONERROR
        );
      end;
    end;
  finally
    Shutdown;
  end;
  if RestartRequested and (System.ExitCode = 0) then
  begin

{$IFNDEF ANDROID}
    RestartText[0] := ExecutablePath;
    RestartText[1] := '--game-dir=' + GameDirectory;
    RestartText[2] := '--user-dir=' + UserDirectory;
    RestartText[3] := '--language=' + UTF8Encode(SelectedLanguage);
    if GpuRendererRequested then
      RestartText[4] := '--renderer=sdl'
    else
      RestartText[4] := '--renderer=software';
    for I := 0 to 4 do
      RestartArgs[I] := PAnsiChar(RestartText[I]);
    RestartArgs[5] := nil;
    fpExecV(PAnsiChar(ExecutablePath), @RestartArgs[0]);
    raise Exception.Create('Cannot restart game: ' + SysErrorMessage(fpGetErrNo));
{$ENDIF}

  end;
end;

end.
