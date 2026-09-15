{$EXCESSPRECISION OFF}
unit fPanelRuins;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_MessageLoop;
type
  TfPanelRuins = class;
  TfPanelRuins = class(TObjectEx)
    Screen: TMessageLoopGI;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeLayout(Screen: TMessageLoopGI);
    procedure OnOpen;
    procedure OnClose;
    procedure Show;
    procedure Hide;
    procedure ServicesClicked(Sender: TObjectGI);
    procedure EquipmentShopClicked(Sender: TObjectGI);
    procedure GoodsShopClicked(Sender: TObjectGI);
    procedure InformationClicked(Sender: TObjectGI);
    procedure HangarClicked(Sender: TObjectGI);
    procedure TakeOffForStationTravel;
    procedure ProcessKeyDown(Key: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aRanger,
  fEquipmentShop,
  fGalaxy2,
  Classes,
  Windows,
  GR_Main,
  GR_Music,
  Globals,
  GlobalsV,
  GI_GraphButton,
  GI_MessageBox,
  aConst,
  aGalaxy,
  aGalaxyStruct,
  aMyFunction,
  aPlayer,
  aSaveLoad,
  aScript,
  fRuinsTalk,
  fPanelLoad,
  fSaveManager,
  fStarMap,
  ThreadCalc,
  aCalc;

constructor TfPanelRuins.Create;
begin
  inherited Create;
end;

destructor TfPanelRuins.Destroy;
begin
  inherited Destroy;
end;

procedure TfPanelRuins.InitializeLayout(Screen: TMessageLoopGI);
begin
  Self.Screen := Screen;
  AppendLogTextThreadSafe('fPanelRuins... ');
  with Self.Screen.GetByName('PanelRuins') do
    SetPosition(
        Classes.Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight)
    );
  AppendLogLineThreadSafe('ok');
  (Self.Screen.GetByName('PR_Gov') as TGraphButtonGI).UpCallback := ServicesClicked;
  (Self.Screen.GetByName('PR_Shop') as TGraphButtonGI).UpCallback := EquipmentShopClicked;
  (Self.Screen.GetByName('PR_Goods') as TGraphButtonGI).UpCallback := GoodsShopClicked;
  (Self.Screen.GetByName('PR_Info') as TGraphButtonGI).UpCallback := InformationClicked;
  (Self.Screen.GetByName('PR_Hangar') as TGraphButtonGI).UpCallback := HangarClicked;
end;

procedure TfPanelRuins.OnOpen;
begin
  with Screen.GetByName('PanelRuins') do
    SetActive(GetPlayer.RuinsMode = 0);
end;

procedure TfPanelRuins.OnClose;
begin
end;

procedure TfPanelRuins.Show;
begin
  Screen.GetByName('PanelRuins').SetActive(True);
end;

procedure TfPanelRuins.Hide;
begin
  Screen.GetByName('PanelRuins').SetActive(False);
end;

procedure TfPanelRuins.ServicesClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (RuinsTalkScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  RequestedScreenId := screenRuinsTalk;
  Screen.RequestClose(1);
end;

procedure TfPanelRuins.EquipmentShopClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (RuinsTalkScreen = Screen) then
    Exit;
  if (GetPlayer.RuinsMode > 0) and (RuinsTalkScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.DockedTo.TypeId = Byte(rstBusinessCenter)) and (GetPlayer.DebtDefaultCount > 1) then
    ShowMessageBoxGI(
        Screen,
        LocalizedColorText('FormRuins.BK.DebtNoAccess'),
        mbgCancel or mbgWarning
    )
  else
  begin
    RequestedScreenId := screenEquipmentShop;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelRuins.GoodsShopClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (RuinsTalkScreen = Screen) then
    Exit;
  if (GetPlayer.RuinsMode > 0) and (RuinsTalkScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.DockedTo.TypeId = Byte(rstBusinessCenter)) and (GetPlayer.DebtDefaultCount > 1) then
    ShowMessageBoxGI(
        Screen,
        LocalizedColorText('FormRuins.BK.DebtNoAccess'),
        mbgCancel or mbgWarning
    )
  else
  begin
    RequestedScreenId := screenGoodsShop;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelRuins.InformationClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (RuinsTalkScreen = Screen) then
    Exit;
  if (GetPlayer.RuinsMode > 0) and (RuinsTalkScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.DockedTo.TypeId = Byte(rstBusinessCenter)) and (GetPlayer.DebtDefaultCount > 1) then
    ShowMessageBoxGI(
        Screen,
        LocalizedColorText('FormRuins.BK.DebtNoAccess'),
        mbgCancel or mbgWarning
    )
  else
  begin
    RequestedScreenId := screenInfo;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelRuins.HangarClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (RuinsTalkScreen = Screen) then
    Exit;
  if (GetPlayer.RuinsMode > 0) and (RuinsTalkScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  RequestedScreenId := screenHangar;
  Screen.RequestClose(1);
end;

procedure TfPanelRuins.TakeOffForStationTravel;
var
  Index: Integer;
begin

  aCalc.WaitForTurnCalculationUI;
  CaptureSavePreview;
  CaptureGalaxyPreview(Screen);
  SaveManagerReturnScreenId := FormToId(Screen);
  SaveGameToFile(SaveManagerScreen.GetAutoSavePath, 'as');
  if MusicManager.CategoryOverride = '' then
    MusicManager.RequestFadeOut;
  PlayerAutomaticControl := False;
  PruneExpiredPersistentPlayerMessages;
  GetPlayer.OrderTakeoff;
  for Index := 0 to Galaxy.Scripts.Count - 1 do
    TScript(Galaxy.Scripts[Index]).RunTurnCode;
  StarMapWeaponPanelOpen := False;
  FilmCameraFollow := True;
  PlayerStar.RefreshSpaceObjectPositions;
  RestoreTemporaryShopStock;
  RunGlobalScriptsForContext(GetPlayer.CurrentStar, 1);
  if (GetPlayer <> nil) and GetPlayer.IsHealthEffectActive(3) then
    Galaxy.EnableDominatorSurfaces
  else
    Galaxy.DisableDominatorSurfaces;
  CalculatePlayerStarTurnAndWait;
  if ExitScreenLoop then
    Exit;
  QueueGalaxyTurnCalculation;
  StarMapWeaponPanelOpen := False;
  StarMapScreen.ResumeMode := smrTurnFilm;
  ScreenLoadMode := 2;
  PostLoadScreenId := screenStarMap;
  RequestedScreenId := screenLoad;
  if ActiveLoadPanel <> nil then
  begin
    ActiveLoadPanel.SelectBackgroundStyle(0);
    ActiveLoadPanel.RefreshBackgroundImages;
    ActiveLoadPanel.StartClosingShutters;
  end
  else
    Screen.RequestClose(1);
end;

procedure TfPanelRuins.ProcessKeyDown(Key: Integer);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then
    Exit;
  if not GetPlayer.IsDockedToShip then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (Key = Ord('G')) and Screen.GetByName('PR_Gov').Active then
    ServicesClicked(nil)
  else if (Key = Ord('E')) and Screen.GetByName('PR_Shop').Active then
    EquipmentShopClicked(nil)
  else if (Key = Ord('T')) and Screen.GetByName('PR_Goods').Active then
    GoodsShopClicked(nil)
  else if (Key = Ord('I')) and Screen.GetByName('PR_Info').Active then
    InformationClicked(nil)
  else if (Key = Ord('H')) and Screen.GetByName('PR_Hangar').Active then
    HangarClicked(nil);
end;

procedure LinkRecoveredTypes;
begin
  TGraphButtonGI.ClassName;
end;
end.
