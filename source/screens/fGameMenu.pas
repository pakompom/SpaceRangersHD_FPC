{$EXCESSPRECISION OFF}
unit fGameMenu;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  Types;
type
  TfGameMenu = class;
  TfGameMenu = class(TMessageLoopGI)
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure InitializeLayout; override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
    procedure ResumeClicked(Sender: TObjectGI);
    procedure SaveClicked(Sender: TObjectGI);
    procedure LoadClicked(Sender: TObjectGI);
    procedure SettingsClicked(Sender: TObjectGI);
    procedure HelpClicked(Sender: TObjectGI);
    procedure ExitClicked(Sender: TObjectGI);
    procedure AchievementsClicked(Sender: TObjectGI);
    procedure BackgroundMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  aCalc,
  Math,
  EC_Cache,
  GI_MessageBox,
  GR_DX,
  aSaveLoad,
  aScript,
  aGalaxyStruct,
  Classes,
  Windows,
  ShellAPI,
  GR_Main,
  GR_Music,
  Globals,
  GlobalsV,
  GI_Main,
  GI_GraphBuf,
  GI_GraphButton,
  GI_Image,
  aConst,
  aMyFunction,
  aPlayer,
  aGalaxy,
  fLoad,
  fSaveManager,
  fStarMap;

procedure TfGameMenu.InitializeLayout;
begin
  inherited;
  AppendLogTextThreadSafe('fGameMenu... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('Resume').Parent do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
  end;
  AppendLogLineThreadSafe('ok');
  GetByName('MainPanel').LeftButtonUpCallback := BackgroundMouseUp;
  with GetByName('Resume') as TGraphButtonGI do
    UpCallback := ResumeClicked;
  with GetByName('Save') as TGraphButtonGI do
    UpCallback := SaveClicked;
  with GetByName('Load') as TGraphButtonGI do
    UpCallback := LoadClicked;
  with GetByName('Settings') as TGraphButtonGI do
    UpCallback := SettingsClicked;
  with GetByName('Help') as TGraphButtonGI do
    UpCallback := HelpClicked;
  with GetByName('Exit') as TGraphButtonGI do
    UpCallback := ExitClicked;
  with GetByName('Close') as TGraphButtonGI do
    UpCallback := ResumeClicked;
  with GetByName('Achievements') as TGraphButtonGI do
    UpCallback := AchievementsClicked;
end;

procedure TfGameMenu.OnOpen;
begin
  (GetByName('Save') as TGraphButtonGI).SetDisabled(False);
  (GetByName('Load') as TGraphButtonGI).SetDisabled(False);
  if AuxRenderBuffer.GetPixels = nil then
    CaptureScreenBackground(True, 0);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  ContentPanel.KeyDownCallback := MainPanelKeyDown;
end;

procedure TfGameMenu.OnClose;
begin
  if AuxRenderBuffer <> nil then
    AuxRenderBuffer.Clear;
end;

procedure TfGameMenu.ResumeClicked(Sender: TObjectGI);
begin
  RequestedScreenId := GameMenuReturnScreenId;
  RequestClose(1);
end;

procedure TfGameMenu.SaveClicked(Sender: TObjectGI);
begin
  if Galaxy.IronWill then
    ShowMessageBoxGI(
        Self,
        LocalizedColorText('FormGameSet2.IronWillText'),
        mbgCancel or mbgUnused04
    )
  else if Galaxy.SpecialSimulationMode = 0 then
  begin
    SaveManagerReturnScreenId := GameMenuReturnScreenId;
    SaveManagerMode := smmSave;
    RequestedScreenId := screenSaveManager;
    RequestClose(1);
  end;
end;

procedure TfGameMenu.LoadClicked(Sender: TObjectGI);
begin
  SaveManagerReturnScreenId := GameMenuReturnScreenId;
  SaveManagerMode := smmLoad;
  RequestedScreenId := screenSaveManager;
  RequestClose(1);
end;

procedure TfGameMenu.SettingsClicked(Sender: TObjectGI);
begin
  SettingsReturnScreenId := GameMenuReturnScreenId;
  RequestedScreenId := screenSettings;
  RequestClose(1);
end;

procedure TfGameMenu.HelpClicked(Sender: TObjectGI);
begin
  ShowWindow(MainWindowHandle, SW_MINIMIZE);
  // Native $602EEC and $602F20 are the empty and 'open' PAnsiChar literals.
  ShellExecuteA(
      0,
      'open',
      PAnsiChar(AnsiString(LocalizedText('FormGameMenu.HelpFile'))),
      '',
      '',
      SW_SHOWNORMAL
  );
end;

procedure TfGameMenu.ExitClicked(Sender: TObjectGI);
begin
  if ShowMessageBoxGI(
          Self,
          LanguageDataConfig.GetParamByPathOrMarker('FormGameMenu.QExit'),
          mbgOK or mbgCancel or mbgQuestion)
      = mbgResultOK then
  begin
    if MemorySnapshotBuffer <> nil then
      MemorySnapshotBuffer.Free;
    MemorySnapshotBuffer := nil;
    MemorySnapshotActive := False;
    if (Galaxy <> nil) and not Galaxy.Destroying then
      Galaxy.Free;
    Galaxy := nil;
    EvictRuinsAndGovernmentCaches;
    EvictStarAndBackgroundCaches;
    ReleaseAllTextureSurfaces;
    ScreenLoadMode := 4;
    PostLoadScreenId := screenMainMenu;
    RequestedScreenId := screenLoad;
    RequestClose(1);
  end;
end;

procedure TfGameMenu.AchievementsClicked(Sender: TObjectGI);
begin
  AchievementsReturnScreenId := GameMenuReturnScreenId;
  RequestedScreenId := screenAchievements;
  RequestClose(1);
end;

procedure TfGameMenu.BackgroundMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not (GetByName('ImageBG') as TImageGI).HitTestPixel(Point) then
    if not (GetByName('Resume') as TGraphButtonGI).ContainsPoint(Point) then
      if not (GetByName('Save') as TGraphButtonGI).ContainsPoint(Point) then
        if not (GetByName('Load') as TGraphButtonGI).ContainsPoint(Point) then
          if not (GetByName('Settings') as TGraphButtonGI).ContainsPoint(Point) then
            if not (GetByName('Help') as TGraphButtonGI).ContainsPoint(Point) then
              if not (GetByName('Exit') as TGraphButtonGI).ContainsPoint(Point) then
                if not (GetByName('Close') as TGraphButtonGI).ContainsPoint(Point) then
                  if not (GetByName('Achievements') as TGraphButtonGI).ContainsPoint(Point) then
                    ResumeClicked(nil);
end;

procedure TfGameMenu.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL)
      and not IsVirtualKeyDown(VK_SHIFT)
      and not IsVirtualKeyDown(VK_MENU) then
    if Key = VK_ESCAPE then
      ResumeClicked(nil)
    else if (Key = Ord('S')) or (Key = VK_F2) then
      SaveClicked(nil)
    else if (Key = Ord('L')) or (Key = VK_F3) then
      LoadClicked(nil)
    else if Key = Ord('C') then
      SettingsClicked(nil)
    else if Key = Ord('E') then
      ExitClicked(nil)
    else if Key = Ord('H') then
      HelpClicked(nil);
end;

procedure TfGameMenu.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
  if not ExitScreenLoop then
  begin
    aCalc.WaitForTurnCalculationUI;
    ExecuteGameplayUiCode(Block, Key);
    aCalc.WaitForTurnCalculationUI;
  end;
end;

procedure TfGameMenu.SelectMusic;
begin
  if GetPlayer = nil then
    MusicManager.PlayCategory('Base')
  else if GetPlayer.RuinsMode <> 0 then
    MusicManager.PlayCategory('Base')
  else if GetPlayer.IsOnPlanet then
  begin
    if not MusicInPlanetEnabled then
      MusicManager.RequestFadeOut
    else
    begin
      if GetPlayer.CurrentPlanet.OwnerId = Byte(oiPirate) then
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
    end;
  end
  else if GetPlayer.IsDockedToShip then
  begin
    if not MusicInPlanetEnabled then
      MusicManager.RequestFadeOut
    else
    begin
      if GetPlayer.DockedTo.TypeId in [Ord(rstPirateBase), Ord(rstDominion)] then
        MusicManager.PlayCategory(
            'Nation.'
                + OwnerInfo[Integer(RaceToOwner(GetPlayer.DockedTo.PilotRace)) and $7F].InternalName
                + 'Pirate'
        )
      else
        MusicManager.PlayCategory(
            'Nation.'
                + OwnerInfo[Integer(RaceToOwner(GetPlayer.DockedTo.PilotRace)) and $7F].InternalName
        );
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
end;

procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
end;
end.
