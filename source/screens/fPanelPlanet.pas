{$EXCESSPRECISION OFF}
unit fPanelPlanet;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_MessageLoop;
type
  TfPanelPlanet = class;
  TfPanelPlanet = class(TObjectEx)
    Screen: TMessageLoopGI;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeLayout(Screen: TMessageLoopGI);
    procedure OnOpen;
    procedure OnClose;
    procedure Show;
    procedure Hide;
    procedure HangarClicked(Sender: TObjectGI);
    procedure EquipmentShopClicked(Sender: TObjectGI);
    procedure GoodsShopClicked(Sender: TObjectGI);
    procedure GovernmentClicked(Sender: TObjectGI);
    procedure InformationClicked(Sender: TObjectGI);
    procedure PlanetClicked(Sender: TObjectGI);
    procedure ProcessKeyDown(Key: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GlobalsV,
  Classes,
  Windows,
  GR_Main,
  Globals,
  GI_GraphButton,
  GI_MessageBox,
  aConst,
  aGalaxyStruct,
  aMyFunction,
  aPlanet,
  aPlayer,
  aScript,
  fGov,
  fPanelLoad;

constructor TfPanelPlanet.Create;
begin
  inherited Create;
end;

destructor TfPanelPlanet.Destroy;
begin
  inherited Destroy;
end;

procedure TfPanelPlanet.InitializeLayout(Screen: TMessageLoopGI);
var
  Panel: TObjectGI;
begin
  Self.Screen := Screen;
  AppendLogTextThreadSafe('fPanelPlanet... ');
  Panel := Self.Screen.GetByName('PanelPlanet');
  Panel.SetPosition(
      Classes.Point(
          Panel.LocalPosition.X + ExtraScreenWidth,
          Panel.LocalPosition.Y + ExtraScreenHeight
      )
  );
  AppendLogLineThreadSafe('ok');
  (Self.Screen.GetByName('PP_Hangar') as TGraphButtonGI).UpCallback := HangarClicked;
  (Self.Screen.GetByName('PP_Shop') as TGraphButtonGI).UpCallback := EquipmentShopClicked;
  (Self.Screen.GetByName('PP_Goods') as TGraphButtonGI).UpCallback := GoodsShopClicked;
  (Self.Screen.GetByName('PP_Gov') as TGraphButtonGI).UpCallback := GovernmentClicked;
  (Self.Screen.GetByName('PP_Info') as TGraphButtonGI).UpCallback := InformationClicked;
end;

procedure TfPanelPlanet.OnOpen;
begin
end;

procedure TfPanelPlanet.OnClose;
begin
end;

procedure TfPanelPlanet.Show;
begin
  Screen.GetByName('PanelPlanet').SetActive(True);
end;

procedure TfPanelPlanet.Hide;
begin
  Screen.GetByName('PanelPlanet').SetActive(False);
end;

procedure TfPanelPlanet.HangarClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  RequestedScreenId := screenHangar;
  Screen.RequestClose(1);
end;

procedure TfPanelPlanet.EquipmentShopClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) <= rlBad)
      and not GetPlayer.CurrentPlanet.IsMainPiratePlanet then
  begin
    if GetPlayer.CurrentPlanet.OwnerId = Byte(oiPirate) then
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPiratePlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      )
    else
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      );
  end
  else
  begin
    RequestedScreenId := screenEquipmentShop;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelPlanet.GoodsShopClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) <= rlBad)
      and not GetPlayer.CurrentPlanet.IsMainPiratePlanet then
  begin
    if GetPlayer.CurrentPlanet.OwnerId = Byte(oiPirate) then
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPiratePlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      )
    else
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      );
  end
  else
  begin
    RequestedScreenId := screenGoodsShop;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelPlanet.GovernmentClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  RequestedScreenId := screenGovernment;
  Screen.RequestClose(1);
end;

procedure TfPanelPlanet.InformationClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) <= rlBad)
      and not GetPlayer.CurrentPlanet.IsMainPiratePlanet then
  begin
    if GetPlayer.CurrentPlanet.OwnerId = Byte(oiPirate) then
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPiratePlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      )
    else
      ShowMessageBoxGI(
          Screen,
          ReplaceColoredToken(
              LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
              '<Planet>',
              GetPlayer.CurrentPlanet.Name,
              '<color=255,240,100>'
          ),
          mbgCancel or mbgWarning
      );
  end
  else
  begin
    RequestedScreenId := screenInfo;
    Screen.RequestClose(1);
  end;
end;

procedure TfPanelPlanet.PlanetClicked(Sender: TObjectGI);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if (GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile)
      and (GovernmentScreen = Screen) then
    Exit;
  if (GetPlayer.PendingDockDialogue > 1) and (GovernmentScreen = Screen) then
    Exit;
  if HasPendingScriptRequests then
    Exit;
  RequestedScreenId := screenPlanet;
  Screen.RequestClose(1);
end;

procedure TfPanelPlanet.ProcessKeyDown(Key: Integer);
begin
  if Screen.ExitCode <> 0 then
    Exit;
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then
    Exit;
  if not GetPlayer.IsOnPlanet then
    Exit;
  if (ActiveLoadPanel <> nil) and ActiveLoadPanel.IsAnimatingShutters then
    Exit;
  if Key = Ord('H') then
    HangarClicked(nil)
  else if Key = Ord('E') then
    EquipmentShopClicked(nil)
  else if Key = Ord('T') then
    GoodsShopClicked(nil)
  else if Key = Ord('G') then
    GovernmentClicked(nil)
  else if Key = Ord('I') then
    InformationClicked(nil)
  else if Key = Ord('P') then
    PlanetClicked(nil);
end;

procedure LinkRecoveredTypes;
begin
  TGraphButtonGI.ClassName;
end;
end.
