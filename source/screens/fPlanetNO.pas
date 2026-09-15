{$EXCESSPRECISION OFF}
unit fPlanetNO;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_Struct,
  GI_Image,
  GI_Label,
  GI_MessageLoop,
  GI_Window,
  GR_Sound,
  Types,
  aItem,
  fPanelLoad,
  fPanelMain;
type
  TfPlanetNO = class;
  TProbeTrajectoryPoint = packed record
    Position: TPointF;
    Direction: TPointF;
    Gap10: array[0..3] of Byte;
  end;
  TProbeTrajectory = array[0..255] of TProbeTrajectoryPoint;
  TfPlanetNO = class(TMessageLoopGIWithMainPanel)
    LoadPanel: TfPanelLoad;
    TrajectoryPointCounts: array[0..5] of Integer;
    Trajectories: array[0..5] of TProbeTrajectory;
    SelectedTrajectoryIndex: Integer;
    SatelliteInventoryPageStart: Integer;
    SatelliteInventorySlots: array[0..5] of TImageGI;
    ResearchPanelVisible: Boolean;
    Gap7911: array[0..2] of Byte;
    ItemInfoWindow: TWindowGI;
    ItemInfoImage: TImageGI;
    ItemInfoNameLabel: TLabelGI;
    ItemInfoTextLabel: TLabelGI;
    ItemInfoSizeLabel: TLabelGI;
    ItemInfoCostLabel: TLabelGI;
    ItemInfoRaceIcon: TImageGI;
    ItemInfoHideTimer: PCallbackTimerGI;
    HoveredItem: TItem;
    SatellitePanelNeedsLayout: Boolean;
    Gap7939: array[0..2] of Byte;
    SatelliteMovementTimer: PCallbackTimerGI;
    ProbeSignalTimer: PCallbackTimerGI;
    ProbeSignalSound: TSoundBufferControl;
    ProbeSignalCount: Integer;
    HeldSatellite: TSatellite;
    HeldSatelliteOrigin: Integer;
    HoveringSurfaceLoot: Boolean;
    NewSurfaceLootDiscovered: Boolean;
    Gap7956: array[0..1] of Byte;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    procedure UpdateActionCursor(ForceHand: Boolean); override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
    constructor Create;
    destructor Destroy; override;
    procedure TakeoffClicked(Sender: TObjectGI);
    procedure StartTextQuest(Sender: TObjectGI);
    procedure RefreshPlanetInfo;
    procedure RefreshTextQuestPrompt;
    procedure EndTurnClicked(Sender: TObjectGI);
    procedure ShipClicked(Sender: TObjectGI);
    procedure GalaxyClicked(Sender: TObjectGI);
    procedure QuestClicked(Sender: TObjectGI);
    procedure ToggleResearchPanel(Sender: TObjectGI);
    procedure OpenResearchPanel;
    procedure CloseResearchPanel;
    procedure BuildTrajectory(TrajectoryIndex: Integer);
    function GetRandomTrajectoryPoint(TrajectoryIndex: Integer): TPoint;
    function ProjectPointOntoTrajectory(TrajectoryIndex: Integer; Point: TPoint): TPoint;
    function AdvanceTrajectoryPoint(TrajectoryIndex: Integer; Point: TPoint): TPoint;
    function FindTrajectoryAtCursor: Integer;
    function IsCursorOverTrajectory(TrajectoryIndex: Integer): Boolean;
    procedure ResearchMapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure ResearchMapMouseLeave(Sender: TObjectGI);
    procedure RefreshResearchPanel;
    procedure ScrollSatellitePageLeft(Sender: TObjectGI);
    procedure ScrollSatellitePageRight(Sender: TObjectGI);
    procedure MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SatelliteInventoryMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure ResearchMapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainPanelRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure ReturnHeldSatellite;
    function FindDeployedSatellite(TrajectoryIndex: Integer): TSatellite;
    function CountDeployedSatellites: Integer;
    procedure AdvanceSatelliteMarkers(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure UpdateProbeSignalSound(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure UpdateItemInfoPopup(Item: TItem);
    procedure ShowGoodsInfoPopup(Item: TGoods);
    procedure HideItemInfoPopup(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
const
  ProbeTrajectoryHitRadiusSquared: Single = 400.0;
procedure LinkRecoveredTypes;
implementation
uses
  fGalaxy2,
  Windows,
  aTranclucator,
  aRanger,
  fPlanetQuest,
  fShip2,
  fStarMap,
  fSaveManager,
  aSaveLoad,
  GI_MessageBox,
  GR_Main,
  Classes,
  GI_GraphBuf,
  GI_GAI,
  GI_GraphButton,
  EC_Str,
  GR_GraphBuf,
  GI_GI,
  EC_Mem,
  SysUtils,
  Math,
  aGalaxy,
  aGalaxyStruct,
  aPlayer,
  aPlanet,
  aShip,
  aConst,
  aScript,
  aMyFunction,
  GI_Main,
  GI_Panel,
  Globals,
  GlobalsV,
  GR_Music,
  SE_Planet,
  ThreadCalc,
  aCalc;
type
  PProbeMarkerPixel = ^TProbeMarkerPixel;
  TProbeMarkerPixel = record
    X, Y: Integer;
    Pixel: PCardinal;
    Visited: PByte;
  end;

constructor TfPlanetNO.Create;
begin
  inherited Create;
  LoadPanel := TfPanelLoad.Create;
end;

destructor TfPlanetNO.Destroy;
begin
  if LoadPanel <> nil then
  begin
    LoadPanel.Free;
    LoadPanel := nil;
  end;
  inherited Destroy;
end;

procedure TfPlanetNO.InitializeLayout;
var
  I: Integer;
  LargeBackground: Boolean;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  LoadPanel.InitializeLayout(Self);
  AppendLogTextThreadSafe('fPlanetNO... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('PlanetBG') do
    begin
      LargeBackground := (ClientSize.X > 1024) or (ClientSize.Y > 768);
      if LargeBackground then
      begin
        SetPosition(Classes.Point(0, 0));
        SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
      end
      else
        SetPosition(
            Classes.Point(
                LocalPosition.X + ExtraScreenWidth div 2,
                LocalPosition.Y + ExtraScreenHeight div 2
            )
        );
    end;
    with FindByNameRecursive('CockpitImage') as TImageGI do
    begin
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
      SetImagePath(GetImagePath);
      SetActive(not LargeBackground);
    end;
    with FindByNameRecursive('PanelResearch') do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
    with FindByNameRecursive('ButResearch').Parent do
      SetPosition(
          Classes.Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight)
      );
    with FindByNameRecursive('PanelInfo') do
      SetPosition(Classes.Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y));
    with FindByNameRecursive('QuestInfo') do
      SetPosition(
          Classes.Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenWidth)
      );
  end;
  AppendLogLineThreadSafe('ok');
  with GetByName('MainPanel') do
  begin
    MouseMoveCallback := MainPanelMouseMove;
    RightButtonDownCallback := MainPanelRightButtonDown;
  end;
  (GetByName('ButTakeoff') as TGraphButtonGI).UpCallback := TakeoffClicked;
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  (GetByName('PM_Gal') as TGraphButtonGI).UpCallback := GalaxyClicked;
  (GetByName('PM_Quest') as TGraphButtonGI).UpCallback := QuestClicked;
  (GetByName('ButResearch') as TGraphButtonGI).UpCallback := ToggleResearchPanel;
  (GetByName('ButClose') as TGraphButtonGI).UpCallback := ToggleResearchPanel;
  with GetByName('PanelPath') do
  begin
    MouseMoveCallback := ResearchMapMouseMove;
    MouseLeaveCallback := ResearchMapMouseLeave;
    LeftButtonDownCallback := ResearchMapMouseDown;
  end;
  (GetByName('ButLeft') as TGraphButtonGI).UpCallback := ScrollSatellitePageLeft;
  (GetByName('ButRight') as TGraphButtonGI).UpCallback := ScrollSatellitePageRight;
  for I := 0 to 5 do
  begin
    SatelliteInventorySlots[I] := GetByName('Slot_' + IntToStr(I) + 'i') as TImageGI;
    SatelliteInventorySlots[I].UserValue := I;
    SatelliteInventorySlots[I].LeftButtonDownCallback := SatelliteInventoryMouseDown;
  end;
  ItemInfoWindow := GetByName('PII') as TWindowGI;
  ItemInfoImage := GetByName('InfoImage') as TImageGI;
  ItemInfoNameLabel := GetByName('InfoName') as TLabelGI;
  ItemInfoTextLabel := GetByName('InfoText') as TLabelGI;
  ItemInfoSizeLabel := GetByName('InfoSize') as TLabelGI;
  ItemInfoCostLabel := GetByName('InfoPrice') as TLabelGI;
  ItemInfoRaceIcon := GetByName('EmRace') as TImageGI;
end;

procedure TfPlanetNO.OnOpen;
begin
  SelectMusic;
  MainPanel.OnOpen;
  LoadPanel.OnOpen;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  with GetByName('PlanetBG') as TImageGI do
    SetImagePath('GI,Bm.PlanetBG.' + GetPlayer.CurrentPlanet.Graphic.BackgroundGraph);
  SelectedTrajectoryIndex := -1;
  MainPanel.RebuildMessageButtons(False);
  RefreshPlanetInfo;
  RefreshTextQuestPrompt;
  CloseResearchPanel;
  DispatchPendingScriptRequests;
  if GetPlayer <> nil then
    GetPlayer.ScriptItemsAct(satOnEnteringForm, nil, nil, 0);
  aCalc.WaitForTurnCalculationUI;
end;

procedure TfPlanetNO.OnClose;
begin
  if RequestedScreenId <> screenLoad then
    aCalc.WaitForTurnCalculationUI;
  if GetPlayer <> nil then
    GetPlayer.ScriptItemsAct(satOnLeavingForm, nil, nil, 0);
  CloseResearchPanel;
  MainPanel.OnClose;
  LoadPanel.OnClose;
  if GetPlayer <> nil then
    GetPlayer.RefreshStorageBubbles;
  MainPanel.RefreshMoneyAndCargo;
  MainPanel.RebuildMessageButtons(False);
end;

procedure TfPlanetNO.TakeoffClicked(Sender: TObjectGI);
var
  I: Integer;
begin
  if (TurnCalculationPhase = tcpGalaxyRunning)
      or (TurnCalculationPhase = tcpPlayerStarRunning)
      or HasPendingScriptRequests then
    Exit;
  aCalc.WaitForTurnCalculationUI;
  GetPlayer.RefreshDerivedStats(True);
  aCalc.WaitForTurnCalculationUI;
  if (HeldSatellite <> nil)
      and (HeldSatelliteOrigin = 0)
      and (GetPlayer.GetCargoFreeSpace < HeldSatellite.Weight) then
  begin
    ShowMessageBoxGI(Self, LocalizedText('FormRuins.ShipOvercharging'), mbgCancel or mbgError);
    Exit;
  end;
  if not GetPlayer.HasPositiveSpeed then
  begin
    if GetPlayer.GetCargoFreeSpace < 0 then
      ShowMessageBoxGI(Self, LocalizedText('FormRuins.ShipOvercharging'), mbgCancel or mbgError)
    else if GetPlayer.GetEngine = nil then
      ShowMessageBoxGI(Self, LocalizedText('FormRuins.NotEngine'), mbgCancel or mbgError)
    else if GetPlayer.GetFuelTanks = nil then
      ShowMessageBoxGI(Self, LocalizedText('FormRuins.NotFuelTank'), mbgCancel or mbgError);
    Exit;
  end;
  if GetPlayer.HasSatelliteOnPlanet(GetPlayer.CurrentPlanet)
      and (ShowMessageBoxGI(
              Self,
              FormatText1(
                  LanguageDataConfig.GetParamByPathOrMarker('FormPlanetNO.SatelliteInPlanet'),
                  '<color=255,240,100>',
                  '<Name>',
                  GetPlayer.CurrentPlanet.Name
              ),
              mbgOK or mbgCancel)
          <> mbgResultOK) then
    Exit;

  aCalc.WaitForTurnCalculationUI;
  CloseResearchPanel;
  ReturnHeldSatellite;
  CaptureSavePreview;
  CaptureGalaxyPreview(Self);
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetAutoSavePath, 'as');
  PruneExpiredPersistentPlayerMessages;
  GetPlayer.OrderTakeoff;
  for I := 0 to Galaxy.Scripts.Count - 1 do
    TScript(Galaxy.Scripts[I]).RunTurnCode;
  StarMapScreen.SetMapCenterManually(TruncatePointF(GetPlayer.Position));
  PlayerStar.RefreshSpaceObjectPositions;
  RunGlobalScriptsForContext(GetPlayer.CurrentStar, 1);
  if (GetPlayer <> nil) and GetPlayer.IsHealthEffectActive(3) then
    Galaxy.EnableDominatorSurfaces
  else
    Galaxy.DisableDominatorSurfaces;
  CalculatePlayerStarTurnAndWait;
  if not ExitScreenLoop then
    if GetPlayer = nil then
    begin
      RequestedScreenId := screenGameEnd;
      RequestClose(1);
    end
    else
    begin
      CalculateGalaxyTurnAndWait;
      StarMapWeaponPanelOpen := False;
      StarMapScreen.ResumeMode := smrTurnFilm;
      ScreenLoadMode := 2;
      PostLoadScreenId := screenStarMap;
      RequestedScreenId := screenLoad;
      LoadPanel.SelectBackgroundStyle(0);
      LoadPanel.RefreshBackgroundImages;
      LoadPanel.StartClosingShutters;
    end;
end;

procedure TfPlanetNO.StartTextQuest(Sender: TObjectGI);
begin
  if LoadPanel.IsAnimatingShutters then
    Exit;
  if (Sender.UserValue <> 0)
      and (ShowMessageBoxGI(
              Self,
              LocalizedText('FormGov.QuestCertificate.NotCertificateAttention'),
              mbgOK or mbgCancel or mbgQuestion)
          <> mbgResultOK) then
    Exit;
  aCalc.WaitForTurnCalculationUI;
  CaptureSavePreview;
  CaptureGalaxyPreview(Self);
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetAutoSavePath, 'as');
  StandaloneQuestMode := False;
  QuestReturnScreenId := FormToId(Self);
  RequestedScreenId := screenPlanetQuest;
  RequestClose(1);
end;

procedure TfPlanetNO.RefreshPlanetInfo;
var
  Window: TWindowGI;
begin
  Window := GetByName('PanelInfo') as TWindowGI;
  with GetByName('PanelInfo_Name') as TLabelGI do
    SetText(
        ReplaceColoredToken(
            LocalizedText('Planet.Civil.Info.TextNamePlanet'),
            '<Planet>',
            GetPlayer.CurrentPlanet.Name,
            InfoNameColorTag
        )
    );
  with GetByName('PanelInfo_Text') as TLabelGI do
  begin
    SetText(GetPlayer.CurrentPlanet.GetInfoText(False));
    Window.SetSize(
        Classes.Point(
            ClientSize.X + Window.WorkSubRect.Left + Window.WorkSubRect.Right,
            ClientSize.Y + Window.WorkSubRect.Top + Window.WorkSubRect.Bottom
        )
    );
    Window.UpdateAutoGeometry;
    Window.SetActive(True);
    SetPosition(Window.WorkSubRect.TopLeft);
  end;
  with GetByName('PanelInfo_Image') as TGraphBufGI do
  begin
    SourceHasPerPixelAlpha := True;
    GetPlayer.CurrentPlanet.Graphic.RenderToBuffer(Self, GraphBuf, False);
    if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
      GraphBuf.RescaleRgba(
          ClientSize.X,
          Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)),
          5
      )
    else
      GraphBuf.RescaleRgba(
          Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)),
          ClientSize.Y,
          5
      );
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  ShipScreen.LayoutItemInfo(
      Window,
      GetByName('PanelInfo_Name') as TLabelGI,
      GetByName('PanelInfo_Text') as TLabelGI,
      True,
      True,
      0
  );
  with GetByName('PanelInfo_Name') as TLabelGI do
    SetSize(
        Classes
            .Point(Window.ClientSize.X - LocalPosition.X - Window.WorkSubRect.Right, ClientSize.Y)
    );
  Window.SetPosition(Classes.Point(GameScreenWidth - 10 - Window.ClientSize.X, 10));
end;

procedure TfPlanetNO.RefreshTextQuestPrompt;
var
  Window: TWindowGI;
  QuestId, I: Integer;
  Quest: PQuest;
  Text: WideString;
begin
  QuestId := -1;
  Window := GetByName('QuestInfo') as TWindowGI;
  Quest := nil;
  Window.SetActive(False);
  if (GetPlayer.CurrentPlanet.TextQuestId > -1) and (GetPlayer.Quests.Count > 0) then
    for I := 0 to GetPlayer.Quests.Count - 1 do
    begin
      Quest := PQuest(GetPlayer.Quests[I]);
      if (Quest.QuestType = qtPlanetQuest)
          and (Quest.ObjectiveTarget is TPlanet)
          and (GetPlayer.CurrentPlanet = (Quest.ObjectiveTarget as TPlanet))
          and (LanguageDataConfig
                  .GetBlockByPath('PlanetQuest.PlanetQuest')
                  .CountParams(IntToStr(Quest.QuestNumber))
              > 0) then
      begin
        QuestId := Quest.QuestNumber;
        if (Quest.QuestNumber < 10000)
            or ((LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') > 0)
                and (LanguageDataConfig
                        .GetBlock('PlanetQuest')
                        .GetBlock('PlanetQuestLic')
                        .GetParamOrMarker(IntToStr(Quest.QuestNumber))
                    = PlanetQuestScreen.GetQuestContentHash(Quest.QuestNumber))) then
          Window.FindByNameRecursive('QuestInfo_Run').UserValue := 0
        else
          Window.FindByNameRecursive('QuestInfo_Run').UserValue := 1;
        Window.SetActive(True);
        Break;
      end;
    end;
  if Window.Active then
  begin
    with GetByName('QuestInfo_Name') as TLabelGI do
      SetText(LocalizedText('PlanetQuest.StartText.QuestCaption'));
    with GetByName('QuestInfo_Text') as TLabelGI do
    begin
      Text := LocalizedColorText('PlanetQuest.StartText.' + IntToStr(QuestId));
      if Text = WideString('') then
        Text := LocalizedColorText('PlanetQuest.StartText.QuestExtern');
      if Quest <> nil then
      begin
        ReplaceTextToken(
            Text,
            '<CurPlanet>',
            (Quest.ObjectiveTarget as TPlanet).Name,
            '<color=255,240,100>'
        );
        ReplaceTextToken(
            Text,
            '<CurStar>',
            (Quest.ObjectiveTarget as TPlanet).CurrentStar.Name,
            '<color=255,240,100>'
        );
        ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, '<color=255,240,100>');
        ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, '<color=255,240,100>');
      end;
      SetText(Text);
      Window.SetSize(
          Classes.Point(
              ClientSize.X + Window.WorkSubRect.Left + Window.WorkSubRect.Right,
              ClientSize.Y + Window.WorkSubRect.Top + Window.WorkSubRect.Bottom
          )
      );
      Window.UpdateAutoGeometry;
      Window.SetActive(True);
      SetPosition(Window.WorkSubRect.TopLeft);
    end;
    ShipScreen.LayoutItemInfo(
        Window,
        GetByName('QuestInfo_Name') as TLabelGI,
        GetByName('QuestInfo_Text') as TLabelGI,
        True,
        True,
        0
    );
    with GetByName('QuestInfo_Run') as TGraphButtonGI do
    begin
      UpCallback := StartTextQuest;
      Window.SetSize(
          Classes
              .Point(Window.ClientSize.X, GiScalePixels(5) + (ClientSize.Y + Window.ClientSize.Y))
      );
      Window.UpdateAutoGeometry;
      SetPosition(
          Classes.Point(
              Window.ClientSize.X div 2 - ClientSize.X div 2,
              Window.ClientSize.Y - GiScalePixels(10) - ClientSize.Y
          )
      );
    end;
    with GetByName('QuestInfo_Name') as TLabelGI do
      SetSize(
          Classes
              .Point(Window.ClientSize.X - LocalPosition.X - Window.WorkSubRect.Right, ClientSize.Y)
      );
    Window.SetPosition(
        Classes.Point(
            GameScreenWidth - 10 - Window.ClientSize.X,
            GameScreenHeight - GiScalePixels(90) - Window.ClientSize.Y
        )
    );
  end;
end;

procedure TfPlanetNO.EndTurnClicked(Sender: TObjectGI);
begin
  if LoadPanel.IsAnimatingShutters then
    Exit;
  aCalc.WaitForTurnCalculationUI;
  if ResearchPanelVisible then
  begin
    ReturnHeldSatellite;
    HideItemInfoPopup(nil, 0);
  end;
  MainPanel.EndTurnClicked(Sender);
  RefreshPlanetInfo;
  RefreshTextQuestPrompt;
  aCalc.WaitForTurnCalculationUI;
  MainPanel.RebuildMessageButtons(False);
  if ResearchPanelVisible then
  begin
    RefreshResearchPanel;
    if NewSurfaceLootDiscovered then
      SoundManager.PlaySound('Sound.ProbeExplore');
  end;
end;

procedure TfPlanetNO.ShipClicked(Sender: TObjectGI);
begin
  if ResearchPanelVisible then
  begin
    ReturnHeldSatellite;
    HideItemInfoPopup(nil, 0);
  end;
  MainPanel.ShipClicked(Sender);
  if (ExitCode = 0) and ResearchPanelVisible then
  begin
    aCalc.WaitForTurnCalculationUI;
    GetPlayer.AssignSatelliteIndicesFromHoldOrder;
    aCalc.WaitForTurnCalculationUI;
    RefreshResearchPanel;
  end;
end;

procedure TfPlanetNO.GalaxyClicked(Sender: TObjectGI);
begin
  if ResearchPanelVisible then
  begin
    ReturnHeldSatellite;
    HideItemInfoPopup(nil, 0);
  end;
  MainPanel.GalaxyClicked(Sender);
  if ResearchPanelVisible then
    RefreshResearchPanel;
end;

procedure TfPlanetNO.QuestClicked(Sender: TObjectGI);
begin
  if ResearchPanelVisible then
  begin
    ReturnHeldSatellite;
    HideItemInfoPopup(nil, 0);
  end;
  MainPanel.QuestClicked(Sender);
  if ResearchPanelVisible then
    RefreshResearchPanel;
end;

procedure TfPlanetNO.ToggleResearchPanel(Sender: TObjectGI);
begin
  if GetByName('PanelResearch').Active then
    CloseResearchPanel
  else
    OpenResearchPanel;
end;

procedure TfPlanetNO.OpenResearchPanel;
var
  I, Parts: Integer;
begin
  SatelliteInventoryPageStart := 0;
  SatellitePanelNeedsLayout := True;
  aCalc.WaitForTurnCalculationUI;
  GetPlayer.RepairDuplicateSatelliteTrajectoryIndices;
  GetPlayer.CompactSatelliteTrajectoryIndices;
  GetPlayer.AssignSatelliteIndicesFromHoldOrder;
  aCalc.WaitForTurnCalculationUI;
  ResearchPanelVisible := True;
  for I := 0 to 5 do
    if TrajectoryPointCounts[I] = 0 then
      BuildTrajectory(I);
  GetByName('PanelResearch').SetActive(True);
  RefreshResearchPanel;
  HoveredItem := nil;
  HoveringSurfaceLoot := False;
  with GetByName('PlanetImage') as TGraphBufGI do
  begin
    Parts := CountDelimitedPartsW(GetPlayer.CurrentPlanet.Graphic.ImagePath, '.');
    LoadBitmapPathAsRgb(
        'Bm.PUMaps.'
            + ExtractDelimitedPartW(GetPlayer.CurrentPlanet.Graphic.ImagePath, Parts - 1, '.')
            + '?RGB'
    );
    if GiResourceVariant = 1 then
      GraphBuf.RescaleRgb(
          Round(Cardinal(GraphBuf.Width) * 800 / 1024),
          Round(Cardinal(GraphBuf.Height) * 800 / 1024)
      );
    GraphBuf.ConvertRgbTo565;
  end;
  if SatelliteMovementTimer <> nil then
  begin
    CancelCallbackTimer(SatelliteMovementTimer);
    SatelliteMovementTimer := nil;
  end;
  SatelliteMovementTimer := ScheduleCallbackTimer(30, 30, AdvanceSatelliteMarkers);
  ProbeSignalCount := 0;
  if ProbeSignalTimer <> nil then
  begin
    CancelCallbackTimer(ProbeSignalTimer);
    ProbeSignalTimer := nil;
  end;
  ProbeSignalTimer := ScheduleCallbackTimer(20, 20, UpdateProbeSignalSound);
  with GetByName('Scan') as TgaiGI do
  begin
    SetSize(GetContentSize);
    SequenceIndex := 0;
    UpdateAutoGeometry;
  end;
end;

procedure TfPlanetNO.CloseResearchPanel;
begin
  if ProbeSignalSound <> nil then
  begin
    ProbeSignalSound.Free;
    ProbeSignalSound := nil;
  end;
  if SatelliteMovementTimer <> nil then
  begin
    CancelCallbackTimer(SatelliteMovementTimer);
    SatelliteMovementTimer := nil;
  end;
  if ProbeSignalTimer <> nil then
  begin
    CancelCallbackTimer(ProbeSignalTimer);
    ProbeSignalTimer := nil;
  end;
  ReturnHeldSatellite;
  GetByName('PanelResearch').SetActive(False);
  ResearchMapMouseLeave(nil);
  GetByName('PanelSatellite').FreeOwnedChildren;
  GetByName('PanelItems').FreeOwnedChildren;
  HoveredItem := nil;
  HoveringSurfaceLoot := False;
  HideItemInfoPopup(nil, 0);
  ResearchPanelVisible := False;
end;

procedure TfPlanetNO.BuildTrajectory(TrajectoryIndex: Integer);
var
  Buffer: TGraphBufGR;
  I, J, X, Y, NeighborX, NeighborY, SumX, SumY, OffsetX, OffsetY: Integer;
  Pixel, NeighborPixel: PCardinal;
  Visited, CursorVisited, NeighborVisited: PByte;
  Queue, ReadNode, WriteNode: PProbeMarkerPixel;
  Count, ReadCount: Integer;
  InverseLength: Single;
  Swap: TProbeTrajectoryPoint;
begin
  Buffer := TGraphBufGR.Create(False);
  LoadGiByPathIntoGraphBuf(
      'Bm.FormUnknown2.' + GiResourceSuffix + 'W' + IntToStr(TrajectoryIndex + 1),
      Buffer
  );
  Visited := AllocClearEC(Buffer.Width * Buffer.Height);
  Queue := AllocClearEC(256 * SizeOf(TProbeMarkerPixel));
  OffsetX := GetByName('W' + IntToStr(TrajectoryIndex)).LocalPosition.X;
  OffsetY := GetByName('W' + IntToStr(TrajectoryIndex)).LocalPosition.Y;
  CursorVisited := Visited;
  Pixel := Buffer.GetPixels;
  for Y := 0 to Buffer.Height - 1 do
  begin
    for X := 0 to Buffer.Width - 1 do
    begin
      if (Pixel^ shr 24 > 32) and (CursorVisited^ = 0) then
      begin
        if TrajectoryPointCounts[TrajectoryIndex] >= 256 then
          RaiseWideMessage('BuildPath.1');
        SumX := X;
        SumY := Y;
        ReadNode := Queue;
        ReadNode.X := X;
        ReadNode.Y := Y;
        ReadNode.Pixel := Pixel;
        ReadNode.Visited := CursorVisited;
        CursorVisited^ := 1;
        ReadCount := 0;
        Count := 1;
        WriteNode := PProbeMarkerPixel(PtrUInt(ReadNode) + SizeOf(TProbeMarkerPixel));
        Pixel^ := $FFFFFFFF;
        while ReadCount < Count do
        begin
          for I := 0 to 3 do
          begin
            NeighborX := ReadNode.X;
            NeighborY := ReadNode.Y;
            NeighborVisited := ReadNode.Visited;
            NeighborPixel := ReadNode.Pixel;
            case I of
              0:
              begin
                Inc(NeighborX);
                if Buffer.Width <= NeighborX then
                  Continue;
                NeighborVisited := PByte(PtrUInt(NeighborVisited) + 1);
                NeighborPixel := PCardinal(PtrUInt(NeighborPixel) + 4);
              end;
              1:
              begin
                Dec(NeighborX);
                if NeighborX < 0 then
                  Continue;
                NeighborVisited := PByte(PtrUInt(NeighborVisited) - 1);
                NeighborPixel := PCardinal(PtrUInt(NeighborPixel) - 4);
              end;
              2:
              begin
                Inc(NeighborY);
                if Buffer.Height <= NeighborY then
                  Continue;
                NeighborVisited := PByte(PtrUInt(NeighborVisited) + Cardinal(Buffer.Width));
                NeighborPixel := PCardinal(PtrUInt(NeighborPixel) + Cardinal(Buffer.PitchBytes));
              end;
              3:
              begin
                Dec(NeighborY);
                if NeighborY < 0 then
                  Continue;
                NeighborVisited := PByte(PtrUInt(NeighborVisited) - Cardinal(Buffer.Width));
                NeighborPixel := PCardinal(PtrUInt(NeighborPixel) - Cardinal(Buffer.PitchBytes));
              end;
            end;
            if (NeighborPixel^ shr 24 > 32) and (NeighborVisited^ = 0) then
            begin
              if Count >= 256 then
                RaiseWideMessage('BuildPath.2');
              Inc(SumX, NeighborX);
              Inc(SumY, NeighborY);
              WriteNode.X := NeighborX;
              WriteNode.Y := NeighborY;
              WriteNode.Visited := NeighborVisited;
              WriteNode.Pixel := NeighborPixel;
              WriteNode := PProbeMarkerPixel(PtrUInt(WriteNode) + SizeOf(TProbeMarkerPixel));
              NeighborVisited^ := 1;
              Inc(Count);
              NeighborPixel^ := $FF800000;
            end;
          end;
          ReadNode := PProbeMarkerPixel(PtrUInt(ReadNode) + SizeOf(TProbeMarkerPixel));
          Inc(ReadCount);
        end;
        Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex]].Position.X :=
            SumX / Count + OffsetX;
        Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex]].Position.Y :=
            SumY / Count + OffsetY;
        Inc(TrajectoryPointCounts[TrajectoryIndex]);
      end;
      Pixel := PCardinal(PtrUInt(Pixel) + 4);
      CursorVisited := PByte(PtrUInt(CursorVisited) + 1);
    end;
    Pixel := PCardinal(PtrUInt(Pixel) + Cardinal(Buffer.PitchBytes - 4 * Buffer.Width));
  end;
  for I := 0 to TrajectoryPointCounts[TrajectoryIndex] - 2 do
    for J := I + 1 to TrajectoryPointCounts[TrajectoryIndex] - 1 do
      if Trajectories[TrajectoryIndex][J].Position.X
          < Trajectories[TrajectoryIndex][I].Position.X then
      begin
        Swap := Trajectories[TrajectoryIndex][J];
        Trajectories[TrajectoryIndex][J] := Trajectories[TrajectoryIndex][I];
        Trajectories[TrajectoryIndex][I] := Swap;
      end;
  for I := 0 to TrajectoryPointCounts[TrajectoryIndex] - 2 do
  begin
    Trajectories[TrajectoryIndex][I].Direction.X :=
        Trajectories[TrajectoryIndex][I + 1].Position.X
            - Trajectories[TrajectoryIndex][I].Position.X;
    Trajectories[TrajectoryIndex][I].Direction.Y :=
        Trajectories[TrajectoryIndex][I + 1].Position.Y
            - Trajectories[TrajectoryIndex][I].Position.Y;
    InverseLength :=
        1
            / Sqrt(
                Sqr(Trajectories[TrajectoryIndex][I].Direction.X)
                    + Sqr(Trajectories[TrajectoryIndex][I].Direction.Y));
    Trajectories[TrajectoryIndex][I].Direction.X :=
        Trajectories[TrajectoryIndex][I].Direction.X * InverseLength;
    Trajectories[TrajectoryIndex][I].Direction.Y :=
        Trajectories[TrajectoryIndex][I].Direction.Y * InverseLength;
  end;
  FreeEC(Queue);
  FreeEC(Visited);
  Buffer.Free;
end;

function TfPlanetNO.GetRandomTrajectoryPoint(TrajectoryIndex: Integer): TPoint;
var
  I: Integer;
begin
  I := RandomIntRange(0, TrajectoryPointCounts[TrajectoryIndex] - 1);
  Result.X := Round(Trajectories[TrajectoryIndex][I].Position.X);
  Result.Y := Round(Trajectories[TrajectoryIndex][I].Position.Y);
end;

function TfPlanetNO.ProjectPointOntoTrajectory(TrajectoryIndex: Integer; Point: TPoint): TPoint;
var
  I: Integer;
  X, Distance, DeltaX, DeltaY: Single;
begin
  X := Point.X;
  while X >= Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex] - 1].Position.X do
    X :=
        X
            - (Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex] - 1].Position.X
                - Trajectories[TrajectoryIndex][0].Position.X);
  if X < Trajectories[TrajectoryIndex][0].Position.X then
    X := Trajectories[TrajectoryIndex][0].Position.X;
  for I := 0 to TrajectoryPointCounts[TrajectoryIndex] - 1 do
    if (X >= Trajectories[TrajectoryIndex][I].Position.X)
        and (X < Trajectories[TrajectoryIndex][I + 1].Position.X) then
    begin
      DeltaX := X - Trajectories[TrajectoryIndex][I].Position.X;
      DeltaY := Point.Y - Trajectories[TrajectoryIndex][I].Position.Y;
      Distance :=
          Trajectories[TrajectoryIndex][I].Direction.X * DeltaX
              + Trajectories[TrajectoryIndex][I].Direction.Y * DeltaY;
      if Distance < 0 then
        Distance := 0;
      Result.X :=
          Round(
              Trajectories[TrajectoryIndex][I].Position.X
                  + Trajectories[TrajectoryIndex][I].Direction.X * Distance
          );
      Result.Y :=
          Round(
              Trajectories[TrajectoryIndex][I].Position.Y
                  + Trajectories[TrajectoryIndex][I].Direction.Y * Distance
          );
      Exit;
    end;
end;

function TfPlanetNO.AdvanceTrajectoryPoint(TrajectoryIndex: Integer; Point: TPoint): TPoint;
var
  I: Integer;
  X, Distance, DeltaX, DeltaY: Single;
begin
  X := Point.X;
  while X > Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex] - 1].Position.X do
    X :=
        X
            - (Trajectories[TrajectoryIndex][TrajectoryPointCounts[TrajectoryIndex] - 1].Position.X
                - Trajectories[TrajectoryIndex][0].Position.X);
  if X < Trajectories[TrajectoryIndex][0].Position.X then
    X := Trajectories[TrajectoryIndex][0].Position.X;
  for I := 0 to TrajectoryPointCounts[TrajectoryIndex] - 1 do
    if (X >= Trajectories[TrajectoryIndex][I].Position.X)
        and (X < Trajectories[TrajectoryIndex][I + 1].Position.X) then
    begin
      DeltaX := X - Trajectories[TrajectoryIndex][I].Position.X;
      DeltaY := Point.Y - Trajectories[TrajectoryIndex][I].Position.Y;
      Distance :=
          Trajectories[TrajectoryIndex][I].Direction.X * DeltaX
              + Trajectories[TrajectoryIndex][I].Direction.Y * DeltaY;
      if Distance < 0 then
        Distance := 0;
      Distance := Distance + 4;
      Result.X :=
          Round(
              Trajectories[TrajectoryIndex][I].Position.X
                  + Trajectories[TrajectoryIndex][I].Direction.X * Distance
          );
      Result.Y :=
          Round(
              Trajectories[TrajectoryIndex][I].Position.Y
                  + Trajectories[TrajectoryIndex][I].Direction.Y * Distance
          );
      Result := ProjectPointOntoTrajectory(TrajectoryIndex, Result);
      Exit;
    end;
end;

function TfPlanetNO.FindTrajectoryAtCursor: Integer;
var
  I: Integer;
begin
  for I := 0 to GetPlayer.CurrentPlanet.ProbeOrbitCount - 1 do
    if IsCursorOverTrajectory(I) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

function TfPlanetNO.IsCursorOverTrajectory(TrajectoryIndex: Integer): Boolean;
var
  I: Integer;
  Point: TPoint;
  X, Y: Single;
begin
  Point := GetByName('PanelPath').ToLocalPoint(GetCursorPoint);
  X := Point.X;
  Y := Point.Y;
  for I := 0 to TrajectoryPointCounts[TrajectoryIndex] - 2 do
    if Sqr(Trajectories[TrajectoryIndex][I].Position.X - X)
            + Sqr(Trajectories[TrajectoryIndex][I].Position.Y - Y)
        < ProbeTrajectoryHitRadiusSquared then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

procedure TfPlanetNO.ResearchMapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  I: Integer;
  Entry: PPlanetSurfaceLootEntry;
  Cell: TPoint;
begin
  if GetPlayer.CurrentPlanet.SurfaceLootEntries <> nil then
  begin
    Cell := GetByName('PanelItems').ToLocalPoint(Point);
    Cell.X := Cell.X div GiScalePixelsEx(36, 28);
    Cell.Y := Cell.Y div GiScalePixelsEx(36, 28);
    for I := 0 to GetPlayer.CurrentPlanet.SurfaceLootEntries.Count - 1 do
    begin
      Entry := GetPlayer.CurrentPlanet.SurfaceLootEntries[I];
      if (Entry.GridX = Cell.X)
          and (Entry.GridY = Cell.Y)
          and (((Entry.TerrainKind = ptWater)
                  and (GetPlayer.CurrentPlanet.WaterExplored >= Entry.SurfaceTileIndex))
              or ((Entry.TerrainKind = ptLand)
                  and (GetPlayer.CurrentPlanet.LandExplored >= Entry.SurfaceTileIndex))
              or ((Entry.TerrainKind = ptHill)
                  and (GetPlayer.CurrentPlanet.HillExplored >= Entry.SurfaceTileIndex)))
          and not Entry.Unavailable then
      begin
        UpdateItemInfoPopup(Entry.Item);
        HoveringSurfaceLoot := True;
        if (HeldSatellite = nil) and not IsCursorImageSelected('Take') then
          SetCursorByName('Take');
        if SelectedTrajectoryIndex >= 0 then
        begin
          with GetByName('W' + IntToStr(SelectedTrajectoryIndex)) as TImageGI do
            if (FindDeployedSatellite(SelectedTrajectoryIndex) <> nil)
                and ((FindDeployedSatellite(SelectedTrajectoryIndex).BrokenFlag <> 0)
                    or (GetPlayer.GetSatelliteExplorationTurns(
                            FindDeployedSatellite(SelectedTrajectoryIndex))
                        = 0)) then
              SetImagePath(
                  'GI,Bm.FormUnknown2.'
                      + GiResourceSuffix
                      + 'W'
                      + IntToStr(SelectedTrajectoryIndex + 1)
                      + 'B'
              )
            else
              SetImagePath(
                  'GI,Bm.FormUnknown2.'
                      + GiResourceSuffix
                      + 'W'
                      + IntToStr(SelectedTrajectoryIndex + 1)
              );
          SelectedTrajectoryIndex := -1;
        end;
        Exit;
      end;
    end;
  end;
  HoveringSurfaceLoot := False;
  if SelectedTrajectoryIndex < 0 then
    UpdateItemInfoPopup(nil);
  if (SelectedTrajectoryIndex < 0) or not IsCursorOverTrajectory(SelectedTrajectoryIndex) then
  begin
    I := FindTrajectoryAtCursor;
    if I <> SelectedTrajectoryIndex then
    begin
      ResearchMapMouseLeave(Sender);
      SelectedTrajectoryIndex := I;
      if SelectedTrajectoryIndex >= 0 then
        with GetByName('W' + IntToStr(SelectedTrajectoryIndex)) as TImageGI do
          SetImagePath(
              'GI,Bm.FormUnknown2.'
                  + GiResourceSuffix
                  + 'W'
                  + IntToStr(SelectedTrajectoryIndex + 1)
                  + 'A'
          );
      UpdateItemInfoPopup(FindDeployedSatellite(SelectedTrajectoryIndex));
      UpdateActionCursor(False);
    end;
  end;
end;

procedure TfPlanetNO.ResearchMapMouseLeave(Sender: TObjectGI);
begin
  if SelectedTrajectoryIndex >= 0 then
  begin
    with GetByName('W' + IntToStr(SelectedTrajectoryIndex)) as TImageGI do
      if (FindDeployedSatellite(SelectedTrajectoryIndex) <> nil)
          and ((FindDeployedSatellite(SelectedTrajectoryIndex).BrokenFlag <> 0)
              or (GetPlayer.GetSatelliteExplorationTurns(
                      FindDeployedSatellite(SelectedTrajectoryIndex))
                  = 0)) then
        SetImagePath(
            'GI,Bm.FormUnknown2.'
                + GiResourceSuffix
                + 'W'
                + IntToStr(SelectedTrajectoryIndex + 1)
                + 'B'
        )
      else
        SetImagePath(
            'GI,Bm.FormUnknown2.' + GiResourceSuffix + 'W' + IntToStr(SelectedTrajectoryIndex + 1)
        );
    SelectedTrajectoryIndex := -1;
  end;
  UpdateItemInfoPopup(nil);
  UpdateActionCursor(False);
end;

procedure TfPlanetNO.RefreshResearchPanel;
var
  I: Integer;
  InventorySatellite, Satellite: TSatellite;
  WaterRate, LandRate, HillRate: Integer;
  Child: TImageGI;
  OldChild: TObjectGI;
  Panel: TPanelGI;
  Entry: PPlanetSurfaceLootEntry;
  Undiscovered: Boolean;
begin
  NewSurfaceLootDiscovered := False;
  with GetByName('Scan') as TgaiGI do
  begin
    SetActive(CountDeployedSatellites > 0);
    if Active then
      RestartPlayback;
  end;
  (GetByName('Caption') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Caption'),
              '<Name>',
              GetPlayer.CurrentPlanet.Name,
              ''
          ));
  for I := 0 to 5 do
    with GetByName('W' + IntToStr(I)) as TImageGI do
    begin
      SetActive(GetPlayer.CurrentPlanet.ProbeOrbitCount > I);
      if Active then
        if SelectedTrajectoryIndex = I then
          SetImagePath('GI,Bm.FormUnknown2.' + GiResourceSuffix + 'W' + IntToStr(I + 1) + 'A')
        else if (FindDeployedSatellite(I) <> nil)
            and ((FindDeployedSatellite(I).BrokenFlag <> 0)
                or (GetPlayer.GetSatelliteExplorationTurns(FindDeployedSatellite(I)) = 0)) then
          SetImagePath('GI,Bm.FormUnknown2.' + GiResourceSuffix + 'W' + IntToStr(I + 1) + 'B')
        else
          SetImagePath('GI,Bm.FormUnknown2.' + GiResourceSuffix + 'W' + IntToStr(I + 1));
    end;
  aCalc.WaitForTurnCalculationUI;
  Panel := GetByName('PanelItems') as TPanelGI;
  Child := TImageGI(Panel.FirstChild);
  while Child <> nil do
  begin
    OldChild := Child;
    Child := TImageGI(Child.NextSibling);
    Entry := PPlanetSurfaceLootEntry(OldChild.UserValue);
    if (GetPlayer.CurrentPlanet.SurfaceLootEntries = nil)
        or (GetPlayer.CurrentPlanet.SurfaceLootEntries.IndexOf(Entry) < 0) then
    begin
      OldChild.Invalidate;
      OldChild.Free;
    end;
  end;
  if GetPlayer.CurrentPlanet.SurfaceLootEntries <> nil then
    for I := 0 to GetPlayer.CurrentPlanet.SurfaceLootEntries.Count - 1 do
    begin
      Entry := GetPlayer.CurrentPlanet.SurfaceLootEntries[I];
      Undiscovered := False;
      if ((((Entry.TerrainKind = ptWater)
                      and (GetPlayer.CurrentPlanet.WaterExplored >= Entry.SurfaceTileIndex))
                  or ((Entry.TerrainKind = ptLand)
                      and (GetPlayer.CurrentPlanet.LandExplored >= Entry.SurfaceTileIndex))
                  or ((Entry.TerrainKind = ptHill)
                      and (GetPlayer.CurrentPlanet.HillExplored >= Entry.SurfaceTileIndex)))
              and not Entry.Unavailable)
          or ((GetPlayer.CountActiveArtefacts(Ord(t_ArtefactAnalyzer)) > 0)
              and (Entry.Item is TEquipmentWithActCode)
              and TEquipmentWithActCode(Entry.Item).DisplayAsArtefact) then
      begin
        if not (((Entry.TerrainKind = ptWater)
                and (GetPlayer.CurrentPlanet.WaterExplored >= Entry.SurfaceTileIndex))
            or ((Entry.TerrainKind = ptLand)
                and (GetPlayer.CurrentPlanet.LandExplored >= Entry.SurfaceTileIndex))
            or ((Entry.TerrainKind = ptHill)
                and (GetPlayer.CurrentPlanet.HillExplored >= Entry.SurfaceTileIndex))) then
          Undiscovered := True;
        Child := TImageGI(Panel.FirstChild);
        while Child <> nil do
        begin
          if Pointer(Child.UserValue) = Entry then
            Break;
          Child := TImageGI(Child.NextSibling);
        end;
        if Child = nil then
        begin
          with TImageGI.Create(Panel) do
          begin
            UserValue := PtrInt(Entry);
            if not Undiscovered then
            begin
              if Entry.Item is TGoods then
                SetImagePath('GI,' + Entry.Item.GetBitmapResourceName)
              else
                SetImagePath('GI,' + Entry.Item.GetBitmapResourceName + 's');
            end
            else
              SetImagePath('GI,' + Entry.Item.GetBitmapResourceName + 'ab');
            SetSize(GetContentSize);
            SetOrigin(HalfPoint(ClientSize));
            SetPosition(
                Classes.Point(
                    Entry.GridX * GiScalePixelsEx(36, 28) + GiScalePixelsEx(36, 28) div 2,
                    Entry.GridY * GiScalePixelsEx(36, 28) + GiScalePixelsEx(36, 28) div 2
                )
            );
          end;
        end
        else if not (Entry.Item is TGoods) then
          if (Child.GetImagePath <> 'GI,' + Entry.Item.GetBitmapResourceName + 's')
              and not Undiscovered then
          begin
            Child.SetImagePath('GI,' + Entry.Item.GetBitmapResourceName + 's');
            Child.SetSize(Child.GetContentSize);
            Child.SetOrigin(HalfPoint(Child.ClientSize));
            Child.SetPosition(
                Classes.Point(
                    Entry.GridX * GiScalePixelsEx(36, 28) + GiScalePixelsEx(36, 28) div 2,
                    Entry.GridY * GiScalePixelsEx(36, 28) + GiScalePixelsEx(36, 28) div 2
                )
            );
            NewSurfaceLootDiscovered := True;
          end;
      end;
    end;
  aCalc.WaitForTurnCalculationUI;
  Panel := GetByName('PanelSatellite') as TPanelGI;
  Child := TImageGI(Panel.FirstChild);
  while Child <> nil do
  begin
    OldChild := Child;
    Child := TImageGI(Child.NextSibling);
    Satellite := TSatellite(OldChild.UserValue);
    if (GetPlayer.Satellites.IndexOf(Satellite) < 0)
        or (GetPlayer.CurrentPlanet <> Satellite.TargetPlanet) then
    begin
      OldChild.Invalidate;
      OldChild.Free;
    end;
  end;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
  begin
    Satellite := TSatellite(GetPlayer.Satellites[I]);
    if GetPlayer.CurrentPlanet = Satellite.TargetPlanet then
    begin
      Child := TImageGI(Panel.FirstChild);
      while Child <> nil do
      begin
        if Pointer(Child.UserValue) = Satellite then
          Break;
        Child := TImageGI(Child.NextSibling);
      end;
      if Child = nil then
      begin
        if not AnimItem then
        begin
          with TImageGI.Create(Panel) do
          begin
            UserValue := PtrInt(Satellite);
            SetImagePath('GI,' + Satellite.GetBitmapResourceName + 's');
            SetSize(GetContentSize);
            SetOrigin(HalfPoint(ClientSize));
            if SatellitePanelNeedsLayout then
              SetPosition(GetRandomTrajectoryPoint(Satellite.TrajectoryIndex))
            else
              SetPosition(
                  ProjectPointOntoTrajectory(
                      Satellite.TrajectoryIndex,
                      Panel.ToLocalPoint(GetCursorPoint)
                  )
              );
          end;
        end
        else
        begin
          with TgaiGI.Create(Panel) do
          begin
            UserValue := PtrInt(Satellite);
            SetImagePath(Satellite.GetBitmapResourceName + 'a');
            SequenceIndex := 0;
            UpdateAutoGeometry;
            SetSize(GetContentSize);
            SetOrigin(HalfPoint(ClientSize));
            RestartPlayback;
            if SatellitePanelNeedsLayout then
              SetPosition(GetRandomTrajectoryPoint(Satellite.TrajectoryIndex))
            else
              SetPosition(
                  ProjectPointOntoTrajectory(
                      Satellite.TrajectoryIndex,
                      Panel.ToLocalPoint(GetCursorPoint)
                  )
              );
          end;
        end;
      end;
    end;
  end;
  SatellitePanelNeedsLayout := False;
  aCalc.WaitForTurnCalculationUI;
  GetPlayer.RepairDuplicateSatelliteTrajectoryIndices;
  aCalc.WaitForTurnCalculationUI;
  for I := 0 to 5 do
  begin
    InventorySatellite := GetPlayer.FindSatelliteByTrajectoryIndex(SatelliteInventoryPageStart + I);
    with GetByName('Slot_' + IntToStr(I) + 'i') as TImageGI do
      if InventorySatellite = nil then
        SetImagePath('')
      else
      begin
        SetImagePath('GI,' + InventorySatellite.GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
  end;
  (GetByName('ButLeft') as TGraphButtonGI).SetDisabled(SatelliteInventoryPageStart <= 0);
  (GetByName('ButRight') as TGraphButtonGI)
      .SetDisabled(GetPlayer.GetSatelliteTrajectoryIndexLimit < SatelliteInventoryPageStart + 6);
  (GetByName('WaterSpace') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Space'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.WaterTiles),
              '<color=0,50,200>'
          ));
  (GetByName('LandSpace') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Space'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.LandTiles),
              '<color=0,50,200>'
          ));
  (GetByName('HillSpace') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Space'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.HillTiles),
              '<color=0,50,200>'
          ));
  (GetByName('WaterComplate') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Complate'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.WaterExplored),
              '<color=0,50,200>'
          ));
  (GetByName('LandComplate') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Complate'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.LandExplored),
              '<color=0,50,200>'
          ));
  (GetByName('HillComplate') as TLabelGI)
      .SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.Complate'),
              '<val>',
              IntToStr(GetPlayer.CurrentPlanet.HillExplored),
              '<color=0,50,200>'
          ));
  WaterRate := 0;
  LandRate := 0;
  HillRate := 0;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
  begin
    Satellite := TSatellite(GetPlayer.Satellites[I]);
    if (GetPlayer.CurrentPlanet = Satellite.TargetPlanet) and (Satellite.BrokenFlag = 0) then
    begin
      WaterRate :=
          Min(
              GetPlayer.CurrentPlanet.WaterTiles - GetPlayer.CurrentPlanet.WaterExplored,
              WaterRate + Satellite.WaterExplorationRate
          );
      LandRate :=
          Min(
              GetPlayer.CurrentPlanet.LandTiles - GetPlayer.CurrentPlanet.LandExplored,
              LandRate + Satellite.LandExplorationRate
          );
      HillRate :=
          Min(
              GetPlayer.CurrentPlanet.HillTiles - GetPlayer.CurrentPlanet.HillExplored,
              HillRate + Satellite.HillExplorationRate
          );
    end;
  end;
  with GetByName('WaterTimeLeft') as TLabelGI do
  begin
    SetActive(WaterRate > 0);
    if Active then
    begin
      WaterRate :=
          Min(
              999,
              Ceil(
                  (GetPlayer.CurrentPlanet.WaterTiles - GetPlayer.CurrentPlanet.WaterExplored)
                      / WaterRate
              )
          );
      SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.TimeLeft'),
              '<val>',
              IntToStr(WaterRate),
              '<color=0,50,200>'
          )
      );
    end;
  end;
  with GetByName('LandTimeLeft') as TLabelGI do
  begin
    SetActive(LandRate > 0);
    if Active then
    begin
      LandRate :=
          Min(
              999,
              Ceil(
                  (GetPlayer.CurrentPlanet.LandTiles - GetPlayer.CurrentPlanet.LandExplored)
                      / LandRate
              )
          );
      SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.TimeLeft'),
              '<val>',
              IntToStr(LandRate),
              '<color=0,50,200>'
          )
      );
    end;
  end;
  with GetByName('HillTimeLeft') as TLabelGI do
  begin
    SetActive(HillRate > 0);
    if Active then
    begin
      HillRate :=
          Min(
              999,
              Ceil(
                  (GetPlayer.CurrentPlanet.HillTiles - GetPlayer.CurrentPlanet.HillExplored)
                      / HillRate
              )
          );
      SetText(
          ReplaceColoredToken(
              LocalizedColorText('FormPlanetNO.TimeLeft'),
              '<val>',
              IntToStr(HillRate),
              '<color=0,50,200>'
          )
      );
    end;
  end;
  GetByName('Light1')
      .SetActive(GetPlayer.CurrentPlanet.WaterExplored >= GetPlayer.CurrentPlanet.WaterTiles);
  GetByName('Light2')
      .SetActive(GetPlayer.CurrentPlanet.LandExplored >= GetPlayer.CurrentPlanet.LandTiles);
  GetByName('Light3')
      .SetActive(GetPlayer.CurrentPlanet.HillExplored >= GetPlayer.CurrentPlanet.HillTiles);
end;

procedure TfPlanetNO.ScrollSatellitePageLeft(Sender: TObjectGI);
begin
  if SatelliteInventoryPageStart > 0 then
  begin
    Dec(SatelliteInventoryPageStart);
    RefreshResearchPanel;
    PostMouseMoveMessage;
  end;
end;

procedure TfPlanetNO.ScrollSatellitePageRight(Sender: TObjectGI);
begin
  if SatelliteInventoryPageStart + 6 <= GetPlayer.GetSatelliteTrajectoryIndexLimit then
  begin
    Inc(SatelliteInventoryPageStart);
    RefreshResearchPanel;
    PostMouseMoveMessage;
  end;
end;

procedure TfPlanetNO.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then
    ScrollSatellitePageLeft(nil)
  else if Delta = -WHEEL_DELTA then
    ScrollSatellitePageRight(nil);
end;

procedure TfPlanetNO.MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  I: Integer;
  Item: TItem;
  HideInfo, ForceHand: Boolean;
begin
  if ResearchPanelVisible and (SelectedTrajectoryIndex < 0) and not HoveringSurfaceLoot then
  begin
    HideInfo := True;
    ForceHand := False;
    for I := 0 to 5 do
      if SatelliteInventorySlots[I].ContainsPoint(Point) then
      begin
        Item := GetPlayer.FindSatelliteByTrajectoryIndex(SatelliteInventoryPageStart + I);
        if Item <> nil then
        begin
          HideInfo := False;
          ForceHand := True;
          UpdateItemInfoPopup(Item);
        end;
        Break;
      end;
    if HideInfo then
      UpdateItemInfoPopup(nil);
    UpdateActionCursor(ForceHand);
  end;
end;

procedure TfPlanetNO.SatelliteInventoryMouseDown(
    Sender: TObjectGI;
    KeyState: Cardinal;
    Point: TPoint
);
var
  Item: TSatellite;
begin
  aCalc.WaitForTurnCalculationUI;
  Item := GetPlayer.FindSatelliteByTrajectoryIndex(SatelliteInventoryPageStart + Sender.UserValue);
  if (HeldSatellite = nil) and (Item <> nil) then
  begin
    HeldSatellite := Item;
    HeldSatelliteOrigin := 0;
    GetPlayer.Inventory.Delete(GetPlayer.Inventory.IndexOf(Item));
    GetPlayer.RefreshDerivedStats(True);
    UpdateActionCursor(False);
    RefreshResearchPanel;
    SoundManager.PlaySound('Sound.SlotGet');
    PostMouseMoveMessage;
  end
  else if HeldSatellite <> nil then
  begin
    if Item <> nil then
      GetPlayer.InsertSatelliteTrajectoryIndex(SatelliteInventoryPageStart + Sender.UserValue);
    SoundManager.PlaySound('Sound.SlotPut');
    GetPlayer.Inventory.Add(HeldSatellite);
    (TObject(HeldSatellite) as TSatellite).TrajectoryIndex :=
        SatelliteInventoryPageStart + Sender.UserValue;
    (TObject(HeldSatellite) as TSatellite).TargetPlanet := nil;
    HeldSatellite := nil;
    GetPlayer.RefreshDerivedStats(True);
    GetPlayer
        .RemoveEmptySatelliteTrajectoryIndex(SatelliteInventoryPageStart + Sender.UserValue + 1);
    GetPlayer.ArrangeHoldSatellitesByTrajectoryIndex;
    UpdateActionCursor(False);
    RefreshResearchPanel;
    PostMouseMoveMessage;
  end;
  aCalc.WaitForTurnCalculationUI;
  GetPlayer.RefreshStorageBubbles;
  MainPanel.RefreshMoneyAndCargo;
  MainPanel.RebuildMessageButtons(False);
end;

procedure TfPlanetNO.ResearchMapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  I: Integer;
  Entry: PPlanetSurfaceLootEntry;
  Cell: TPoint;
  Item: TSatellite;
begin
  if GetPlayer.CurrentPlanet.SurfaceLootEntries <> nil then
    for I := 0 to GetPlayer.CurrentPlanet.SurfaceLootEntries.Count - 1 do
    begin
      Entry := GetPlayer.CurrentPlanet.SurfaceLootEntries[I];
      if ((Entry.TerrainKind = ptWater)
              and (GetPlayer.CurrentPlanet.WaterExplored >= Entry.SurfaceTileIndex))
          or ((Entry.TerrainKind = ptLand)
              and (GetPlayer.CurrentPlanet.LandExplored >= Entry.SurfaceTileIndex))
          or ((Entry.TerrainKind = ptHill)
              and (GetPlayer.CurrentPlanet.HillExplored >= Entry.SurfaceTileIndex)) then
        if not Entry.Unavailable then
        begin
          Cell := GetByName('PanelItems').ToLocalPoint(Point);
          Cell.X := Cell.X div GiScalePixelsEx(36, 28);
          Cell.Y := Cell.Y div GiScalePixelsEx(36, 28);
          if (Entry.GridX = Cell.X) and (Entry.GridY = Cell.Y) then
          begin
            if GetPlayer.GetCargoFreeSpace < Entry.Item.Weight then
            begin
              MainPanel.FlashCargoWarning;
              Exit;
            end;
            SoundManager.PlaySound('Sound.PlanetGet');
            aCalc.WaitForTurnCalculationUI;
            if Entry.Item is TArtefactTranclucator then
              (TObject((Entry.Item as TArtefactTranclucator).Ship) as TTranclucator).OwnerShip :=
                  GetPlayer;
            if Entry.Item is TGoods then
            begin
              Inc(
                  GetPlayer.CargoGoods[Ord(Entry.Item.ItemType)].Count,
                  (Entry.Item as TGoods).Quantity
              );
              Entry.Item.Free;
            end
            else if Entry.Item is TArtefact then
              GetPlayer.Artefacts.Add(Entry.Item)
            else
              GetPlayer.Inventory.Add(Entry.Item);
            GetPlayer.RefreshDerivedStats(True);
            GetPlayer.CurrentPlanet.SurfaceLootEntries.Delete(I);
            if GetPlayer.CurrentPlanet.SurfaceLootEntries.Count <= 0 then
            begin
              GetPlayer.CurrentPlanet.SurfaceLootEntries.Free;
              GetPlayer.CurrentPlanet.SurfaceLootEntries := nil;
            end;
            Entry.Item := nil;
            Dispose(Entry);
            aCalc.WaitForTurnCalculationUI;
            UpdateActionCursor(False);
            RefreshResearchPanel;
            PostMouseMoveMessage;
            Break;
          end;
        end;
    end;
  if (SelectedTrajectoryIndex >= 0)
      and ((HeldSatellite <> nil) or (FindDeployedSatellite(SelectedTrajectoryIndex) <> nil)) then
  begin
    HeldSatelliteOrigin := 1;
    aCalc.WaitForTurnCalculationUI;
    Item := FindDeployedSatellite(SelectedTrajectoryIndex);
    if Item <> nil then
      GetPlayer.Satellites.Delete(GetPlayer.Satellites.IndexOf(Item));
    if HeldSatellite <> nil then
    begin
      SoundManager.PlaySound('Sound.SlotPut');
      GetPlayer.Satellites.Add(HeldSatellite);
      if Item <> nil then
      begin
        Item.TrajectoryIndex := (TObject(HeldSatellite) as TSatellite).TrajectoryIndex;
        HeldSatelliteOrigin := 0;
      end;
      (TObject(HeldSatellite) as TSatellite).TrajectoryIndex := SelectedTrajectoryIndex;
      (TObject(HeldSatellite) as TSatellite).TargetPlanet := GetPlayer.CurrentPlanet;
      HeldSatellite := nil;
    end
    else if Item <> nil then
      SoundManager.PlaySound('Sound.SlotGet');
    aCalc.WaitForTurnCalculationUI;
    if Item <> nil then
      HeldSatellite := Item;
    SelectedTrajectoryIndex := -1;
    UpdateActionCursor(False);
    RefreshResearchPanel;
    PostMouseMoveMessage;
    GetPlayer.RefreshStorageBubbles;
    MainPanel.RefreshMoneyAndCargo;
    MainPanel.RebuildMessageButtons(False);
  end;
end;

procedure TfPlanetNO.MainPanelRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if ResearchPanelVisible then
    ReturnHeldSatellite;
end;

procedure TfPlanetNO.UpdateActionCursor(ForceHand: Boolean);
begin
  if HeldSatellite <> nil then
    SetCursorImage('GI,' + HeldSatellite.GetBitmapResourceName + 's', Classes.Point(16, 16))
  else if (SelectedTrajectoryIndex >= 0)
      and (FindDeployedSatellite(SelectedTrajectoryIndex) <> nil) then
  begin
    if not IsCursorImageSelected('Take') then
    begin
      SoundManager.PlaySound('Sound.ProbeEnter');
      SetCursorByName('Take');
    end;
  end
  else if ForceHand or (HoveredItem <> nil) then
  begin
    if not IsCursorImageSelected('Take') then
      SetCursorByName('Take');
  end
  else if not IsCursorImageSelected('Main') then
    SetCursorByName('Main');
  GetByName('Glow').SetActive(HeldSatellite <> nil);
end;

procedure TfPlanetNO.ReturnHeldSatellite;
begin
  if HeldSatellite = nil then
    Exit;
  aCalc.WaitForTurnCalculationUI;
  if HeldSatelliteOrigin = 0 then
  begin
    GetPlayer.Inventory.Add(HeldSatellite);
    HeldSatellite := nil;
    GetPlayer.RefreshDerivedStats(True);
    UpdateActionCursor(False);
    RefreshResearchPanel;
    PostMouseMoveMessage;
  end
  else
  begin
    GetPlayer.Satellites.Add(HeldSatellite);
    HeldSatellite := nil;
    SatellitePanelNeedsLayout := True;
    SelectedTrajectoryIndex := -1;
    UpdateActionCursor(False);
    RefreshResearchPanel;
    PostMouseMoveMessage;
  end;
  aCalc.WaitForTurnCalculationUI;
end;

function TfPlanetNO.FindDeployedSatellite(TrajectoryIndex: Integer): TSatellite;
var
  I: Integer;
begin
  if TrajectoryIndex = -1 then
  begin
    Result := nil;
    Exit;
  end;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
  begin
    Result := TSatellite(GetPlayer.Satellites[I]);
    if (GetPlayer.CurrentPlanet = Result.TargetPlanet)
        and (Result.TrajectoryIndex = TrajectoryIndex) then
      Exit;
  end;
  Result := nil;
end;

function TfPlanetNO.CountDeployedSatellites: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to GetPlayer.Satellites.Count - 1 do
    if TSatellite(GetPlayer.Satellites[I]).TargetPlanet = GetPlayer.CurrentPlanet then
      Inc(Result);
end;

procedure TfPlanetNO.AdvanceSatelliteMarkers(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Panel: TPanelGI;
  Control: TObjectGI;
  Satellite: TSatellite;
begin
  Panel := GetByName('PanelSatellite') as TPanelGI;
  Control := Panel.FirstChild;
  while Control <> nil do
  begin
    Satellite := TSatellite(Control.UserValue);
    if GetPlayer.Satellites.IndexOf(Satellite) >= 0 then
      Control.SetPosition(AdvanceTrajectoryPoint(Satellite.TrajectoryIndex, Control.LocalPosition));
    Control := Control.NextSibling;
  end;
end;

procedure TfPlanetNO.UpdateProbeSignalSound(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Count: Integer;
begin
  Count := CountDeployedSatellites;
  if (ProbeSignalCount <> Count) and (ProbeSignalSound <> nil) then
  begin
    ProbeSignalSound.SetVolume(Max(0, ProbeSignalSound.Volume - 0.02));
    if ProbeSignalSound.Volume <= 0 then
    begin
      ProbeSignalSound.Free;
      ProbeSignalSound := nil;
    end;
  end;
  if ProbeSignalSound = nil then
    ProbeSignalCount := Count;
  if (ProbeSignalSound = nil) and (ProbeSignalCount > 0) then
  begin
    ProbeSignalSound := TSoundBufferControl.Create;
    ProbeSignalSound.Configure('Sound.ProbeSignal' + IntToStr(ProbeSignalCount), 0, True);
    ProbeSignalSound.SetVolume(0.01);
  end;
  if (ProbeSignalCount > 0)
      and (ProbeSignalCount = Count)
      and (ProbeSignalSound <> nil)
      and (ProbeSignalSound.Volume < 1) then
    ProbeSignalSound.SetVolume(Min(1, ProbeSignalSound.Volume + 0.02));
end;

// The explicit script receiver value preserves native argument evaluation order.
procedure TfPlanetNO.UpdateItemInfoPopup(Item: TItem);
const
  DurableTypes = [0..79] - [0..7, 9, 23..25, 35..38, 42, 69..72, 74..79];
var
  Equipment: TEquipment;
  BarWidth, CapWidth, MinimumWidth: Integer;
  Reserved7C, Reserved80, Reserved84: Integer; // Unused native stack locals.
begin
  if Item <> HoveredItem then
  begin
    HoveredItem := Item;
    if Item = nil then
    begin
      if ItemInfoHideTimer <> nil then
      begin
        CancelCallbackTimer(ItemInfoHideTimer);
        ItemInfoHideTimer := nil;
      end;
      ItemInfoHideTimer := ScheduleCallbackTimer(300, 99999, HideItemInfoPopup);
    end
    else
    begin
      if ItemInfoHideTimer <> nil then
      begin
        CancelCallbackTimer(ItemInfoHideTimer);
        ItemInfoHideTimer := nil;
      end;
      if Item is TGoods then
        ShowGoodsInfoPopup(Item as TGoods)
      else
      begin
        if (Galaxy <> nil) and not Galaxy.Destroying and (GetPlayer <> nil) then
        begin
          if Item.ScriptItem <> nil then
            TScriptItem(Item.ScriptItem)
                .RunActionCode(satOnShowingItemInfo, nil, GetPlayer.CurrentPlanet, nil, 0);
          if Item is TEquipmentWithActCode then
            RunItemConfigActionCode(
                Item,
                satOnShowingItemInfo,
                nil,
                GetPlayer.CurrentPlanet,
                nil,
                0
            );
        end;
        Equipment := Item as TEquipment;
        ItemInfoWindow.SetActive(True);
        with ItemInfoImage do
        begin
          SetImagePath('GI,' + Equipment.GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        ItemInfoNameLabel.SetText(WrapTextInColor(Equipment.GetDisplayName, InfoNameColorTag));
        ItemInfoTextLabel.SetText(Equipment.GetInfoText('<color=255,240,100>', GetPlayer));
        ItemInfoSizeLabel.SetText(IntToStr(Equipment.Weight));
        ItemInfoCostLabel.SetText(IntToStr(Equipment.Cost));
        with ItemInfoRaceIcon do
        begin
          SetImagePath(GetFactionEmblemPath(Equipment.GetOwnerConfigName));
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
        if not (Byte(Equipment.ItemType) in DurableTypes) and (Equipment.ItemType <> t_Hull) then
        begin
          with GetByName('InfoDurable') as TImageGI do
            Parent.Parent.SetActive(False);
          MinimumWidth := 0;
        end
        else
        begin
          if Equipment is THull then
            BarWidth :=
                Round(
                    Sqrt(
                            Equipment.Weight
                                / HullBaseSize
                                / Max(0.1, Equipment.GetFragilityFactor([])))
                        * 64
                )
          else
            BarWidth := Round(64 / Max(0.1, Equipment.GetFragilityFactor([])));
          BarWidth := Min(192, Max(32, BarWidth));
          with GetByName('InfoDurableLeft') as TImageGI do
          begin
            CapWidth := GetContentSize.X;
            MinimumWidth :=
                2 * CapWidth
                    + BarWidth
                    + LocalPosition.X
                    + Parent.LocalPosition.X
                    + 2 * Parent.Parent.LocalPosition.X;
          end;
          with GetByName('InfoDurable') as TImageGI do
          begin
            Parent.Parent.SetActive(True);
            Parent.Parent.SetSize(
                Classes.Point(2 * CapWidth + BarWidth, Parent.Parent.ClientSize.Y)
            );
            Parent.SetSize(Classes.Point(BarWidth + 2, Parent.Parent.ClientSize.Y));
            if Equipment.ItemType = t_Hull then
              SetPosition(
                  Classes.Point(
                      Round(
                              (Equipment as THull).HullPoints
                                  / (Equipment as THull).Weight
                                  * BarWidth)
                          - (GetContentSize.X - 5),
                      LocalPosition.Y
                  )
              )
            else
              SetPosition(
                  Classes.Point(
                      Round(BarWidth * (Equipment.ConditionPercent / 100)) - (GetContentSize.X - 5),
                      LocalPosition.Y
                  )
              );
          end;
          with GetByName('InfoDurableRight') as TImageGI do
          begin
            SetPosition(Classes.Point(BarWidth + CapWidth - GetContentSize.X, LocalPosition.Y));
            Parent.SetPosition(Classes.Point(CapWidth, Parent.LocalPosition.Y));
            Parent.SetSize(Classes.Point(BarWidth + CapWidth, Parent.ClientSize.Y));
          end;
          with GetByName('InfoDurableBack') as TImageGI do
          begin
            SetPosition(Classes.Point(BarWidth + 1 - GetContentSize.X, LocalPosition.Y));
            Parent.SetSize(Classes.Point(BarWidth + CapWidth, Parent.ClientSize.Y));
          end;
        end;
        ShipScreen.LayoutItemInfo(
            ItemInfoWindow,
            ItemInfoNameLabel,
            ItemInfoTextLabel,
            True,
            True,
            MinimumWidth
        );
        ItemInfoSizeLabel.SetPosition(
            Classes.Point(
                ShipScreen.ItemSizeLabelPosition.X,
                ItemInfoWindow.ClientSize.Y + ShipScreen.ItemSizeLabelPosition.Y
            )
        );
        ItemInfoCostLabel.SetPosition(
            Classes.Point(
                ShipScreen.ItemPriceLabelPosition.X,
                ItemInfoWindow.ClientSize.Y + ShipScreen.ItemPriceLabelPosition.Y
            )
        );
        ItemInfoRaceIcon.SetPosition(
            Classes.Point(
                ItemInfoWindow.ClientSize.X + ShipScreen.ItemRaceImagePosition.X,
                ItemInfoWindow.ClientSize.Y + ShipScreen.ItemRaceImagePosition.Y
            )
        );
      end;
    end;
  end;
end;

procedure TfPlanetNO.ShowGoodsInfoPopup(Item: TGoods);
begin
  GetByName('PII').SetActive(True);
  with GetByName('InfoImage') as TImageGI do
  begin
    SetImagePath('GI,' + GetItemTypeBitmapPath(Item.ItemType));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
  end;
  (GetByName('InfoName') as TLabelGI)
      .SetText(WrapTextInColor(GoodsMarket[Ord(Item.ItemType)].DisplayName, InfoNameColorTag));
  (GetByName('InfoText') as TLabelGI)
      .SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(Item.ItemType) + 1)));
  (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(Item.Quantity));
  (GetByName('InfoPrice') as TLabelGI).SetText(IntToStr(Item.Cost));
  with GetByName('EmRace') as TImageGI do
  begin
    SetImagePath(
        GetFactionEmblemPath(
            OwnerInfo[Integer(RaceToOwner(GetPlayer.PilotRace)) and $7F].InternalName
        )
    );
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  GetByName('InfoDurable').Parent.Parent.SetActive(False);
  ShipScreen.LayoutItemInfo(ItemInfoWindow, ItemInfoNameLabel, ItemInfoTextLabel, True, True, 0);
  ItemInfoSizeLabel.SetPosition(
      Classes.Point(
          ShipScreen.ItemSizeLabelPosition.X,
          ItemInfoWindow.ClientSize.Y + ShipScreen.ItemSizeLabelPosition.Y
      )
  );
  ItemInfoCostLabel.SetPosition(
      Classes.Point(
          ShipScreen.ItemPriceLabelPosition.X,
          ItemInfoWindow.ClientSize.Y + ShipScreen.ItemPriceLabelPosition.Y
      )
  );
  ItemInfoRaceIcon.SetPosition(
      Classes.Point(
          ItemInfoWindow.ClientSize.X + ShipScreen.ItemRaceImagePosition.X,
          ItemInfoWindow.ClientSize.Y + ShipScreen.ItemRaceImagePosition.Y
      )
  );
end;

procedure TfPlanetNO.HideItemInfoPopup(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  HoveredItem := nil;
  if ItemInfoHideTimer <> nil then
  begin
    CancelCallbackTimer(ItemInfoHideTimer);
    ItemInfoHideTimer := nil;
  end;
  GetByName('PII').SetActive(False);
end;

procedure TfPlanetNO.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
var
  QuestButton: TObjectGI;
begin
  if LoadPanel.IsAnimatingShutters
      or IsVirtualKeyDown(VK_CONTROL)
      or IsVirtualKeyDown(VK_SHIFT)
      or IsVirtualKeyDown(VK_MENU) then
    Exit;
  if Key = VK_SPACE then
  begin
    if GetByName('PM_EndTurn').Active then
      EndTurnClicked(nil);
  end
  else if Key = Ord('F') then
    TakeoffClicked(nil)
  else if Key = Ord('E') then
    ToggleResearchPanel(nil)
  else if Key = VK_LEFT then
  begin
    if ResearchPanelVisible then
      ScrollSatellitePageLeft(nil);
  end
  else if Key = VK_RIGHT then
  begin
    if ResearchPanelVisible then
      ScrollSatellitePageRight(nil);
  end
  else if Key = VK_ESCAPE then
  begin
    if ResearchPanelVisible then
    begin
      if HeldSatellite <> nil then
        ReturnHeldSatellite
      else
        CloseResearchPanel;
    end
    else
      MainPanel.MenuClicked(nil);
  end
  else if Key = Ord('M') then
    GalaxyClicked(nil)
  else if Key = Ord('S') then
    ShipClicked(nil)
  else if Key = Ord('R') then
    QuestClicked(nil)
  else if Key = Ord('Q') then
  begin
    QuestButton := GetByName('QuestInfo_Run');
    if QuestButton.Active then
      StartTextQuest(QuestButton);
  end
  else
    MainPanel.ProcessKeyDown(Key);
end;

procedure TfPlanetNO.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
  if not MainPanel.NavigationLocked
      and not ExitScreenLoop
      and (TurnCalculationPhase
          in [tcpIdle, tcpGalaxyFinished, tcpPlayerStarFinished, tcpPlayerStarPrepared]) then
  begin
    aCalc.WaitForTurnCalculationUI;
    ExecuteGameplayUiCode(Block, Key);
    aCalc.WaitForTurnCalculationUI;
  end;
end;

procedure TfPlanetNO.SelectMusic;
begin
  if (ActiveLoadPanel <> nil) and (ActiveLoadPanel.GetShutterDirection = -1) then
    Exit;
  if not MusicInPlanetEnabled then
  begin
    MusicManager.RequestFadeOut;
    Exit;
  end;
  if GetPlayer.CurrentPlanet <> nil then
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

procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TArtefactTranclucator.ClassName;
  TEquipment.ClassName;
  TEquipmentWithActCode.ClassName;
  TGoods.ClassName;
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  THull.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
  TPanelGI.ClassName;
  TPlanet.ClassName;
  TSatellite.ClassName;
  TTranclucator.ClassName;
  TWindowGI.ClassName;
  TgaiGI.ClassName;
end;
end.
