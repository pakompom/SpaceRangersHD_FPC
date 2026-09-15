{$EXCESSPRECISION OFF}
unit fRewards;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  GI_PanelScrollBar,
  aShip,
  Types;
type
  TfRewards = class;
  TfRewards = class(TMessageLoopGI)
    AwardsPanel: TPanelScrollBarGI;
    Ship: TShip;
    DraggedAward: TObjectGI;
    HoveredAwardId: Integer;
    ReadOnly: Boolean;
    GapE1: array[0..2] of Byte;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure ProcessCallbackTimers; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    procedure UpdateActionCursor(CanTake: Boolean); override;
    procedure CloseClicked(Sender: TObjectGI);
    function CanEditAwards: Boolean;
    function GetAwardImagePath(AwardId: Integer): WideString;
    procedure PlatformMouseEnter(Sender: TObjectGI);
    procedure AwardMouseEnter(Sender: TObjectGI);
    procedure AwardMouseLeave(Sender: TObjectGI);
    procedure ClearHighlight(Sender: TObjectGI);
    procedure AwardMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure IncreaseVisibleCount(Sender: TObjectGI);
    procedure DecreaseVisibleCount(Sender: TObjectGI);
    procedure RefreshVisibleCount;
    procedure BuildAwardControls;
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
function RunRewards(ParentLoop: TMessageLoopGI; ReadOnly: Boolean): Boolean;
procedure LinkRecoveredTypes;
implementation
uses
  aGalaxyStruct,
  Classes,
  SysUtils,
  Math,
  Windows,
  EC_Struct,
  GI_Panel,
  GI_ScrollBar,
  GI_GraphBuf,
  GI_GraphButton,
  GI_Image,
  GI_Label,
  GR_Main,
  GR_Sound,
  GR_Music,
  Globals,
  GlobalsV,
  aPlayer,
  aNormalShip,
  aConst,
  aPlanet,
  aMyFunction,
  fStarMap;

procedure TfRewards.InitializeLayout;
begin
  inherited InitializeLayout;
  AppendLogTextThreadSafe('fRewards... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('RewardPanel') do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
  end;
  AppendLogLineThreadSafe('ok');
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('ButExit') as TGraphButtonGI).UpCallback := CloseClicked;
  AwardsPanel := GetByName('PTable') as TPanelScrollBarGI;
end;

procedure TfRewards.OnOpen;
begin
  inherited OnOpen;
  Ship := AwardSubject as TShip;
  if Ship.AwardVisibleCount = 0 then
    Ship.AwardVisibleCount := Ship.AwardIds.Count;
  CaptureScreenBackground(False, 0);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  with GetByName('PTable') as TPanelScrollBarGI do
  begin
    ScrollAxis := psaVertical;
    VerticalScrollBar.SetSmallChange(Round(ClientSize.Y / 50));
    VerticalScrollBar.SetLargeChange(ClientSize.Y);
    VerticalScrollBar.SetPageSize(ClientSize.Y);
  end;
  with GetByName('RewardCount') as TLabelGI do
    SetActive(CanEditAwards);
  with GetByName('Add') as TGraphButtonGI do
  begin
    DownCallback := IncreaseVisibleCount;
    SetActive(CanEditAwards);
  end;
  with GetByName('Sub') as TGraphButtonGI do
  begin
    DownCallback := DecreaseVisibleCount;
    SetActive(CanEditAwards);
  end;
  AwardsPanel.SetScrollOffset(Classes.Point(0, 0));
  BuildAwardControls;
  ClearHighlight(nil);
  DraggedAward := nil;
  HoveredAwardId := -1;
  UpdateActionCursor(False);
  RefreshVisibleCount;
end;

procedure TfRewards.OnClose;
begin
  AwardsPanel.FreeOwnedChildren;
  inherited OnClose;
end;

procedure TfRewards.CloseClicked(Sender: TObjectGI);
begin
  if GetPlayer = Ship then
    RequestedScreenId := screenShip
  else
    RequestedScreenId := screenScanner;
  RequestClose(1);
end;

function TfRewards.CanEditAwards: Boolean;
begin
  Result := not ReadOnly and (GetPlayer = Ship);
end;

function TfRewards.GetAwardImagePath(AwardId: Integer): WideString;
begin
  if AwardId < 10 then
    Result := 'GI,Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(AwardId)
  else
    Result := 'GI,Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(AwardId);
end;

procedure TfRewards.PlatformMouseEnter(Sender: TObjectGI);
var
  Obj: TObjectGI;
  Platform: TImageGI;
  AwardId: Integer;
begin
  Platform := TImageGI(Sender.UserValue);
  AwardId := Sender.UserIndex;
  with GetByName('InfoZag') as TLabelGI do
    if AwardId <> 255 then
      SetText((Ship as TNormalShip).GetAwardInfo(AwardId).Name)
    else
      SetText('');
  with GetByName('Info') as TLabelGI do
    if AwardId <> 255 then
      SetText((Ship as TNormalShip).GetAwardInfo(AwardId).Text)
    else
      SetText('');
  Obj := AwardsPanel.FirstChild;
  while Obj <> nil do
  begin
    if (Obj is TImageGI)
        and (TImageGI(Obj).GetImagePath
            = 'GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA') then
      TImageGI(Obj).SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Obj := Obj.NextSibling;
  end;
  Platform.SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA');
  UpdateActionCursor(False);
end;

procedure TfRewards.AwardMouseEnter(Sender: TObjectGI);
begin
  HoveredAwardId := Sender.UserIndex;
  PlatformMouseEnter(Sender);
end;

procedure TfRewards.AwardMouseLeave(Sender: TObjectGI);
begin
  HoveredAwardId := -1;
  UpdateActionCursor(False);
end;

procedure TfRewards.ClearHighlight(Sender: TObjectGI);
var
  Obj: TObjectGI;
begin
  HoveredAwardId := -1;
  with GetByName('InfoZag') as TLabelGI do
    SetText('');
  with GetByName('Info') as TLabelGI do
    SetText('');
  Obj := AwardsPanel.FirstChild;
  while Obj <> nil do
  begin
    if (Obj is TImageGI)
        and (TImageGI(Obj).GetImagePath
            = 'GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA') then
      TImageGI(Obj).SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Obj := Obj.NextSibling;
  end;
  UpdateActionCursor(False);
end;

procedure TfRewards.AwardMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Temp: Integer;
begin
  if DraggedAward = nil then
  begin
    DraggedAward := Sender;
    (Sender as TImageGI).SetImagePath('');
    SoundManager.PlaySound('Sound.SlotGet');
  end
  else
  begin
    Ship.AwardIds.Exchange(Sender.UserData, DraggedAward.UserData);
    Temp := Sender.UserIndex;
    Sender.UserIndex := DraggedAward.UserIndex;
    DraggedAward.UserIndex := Temp;
    Temp := TObjectGI(Sender.UserValue).UserIndex;
    TObjectGI(Sender.UserValue).UserIndex := TObjectGI(DraggedAward.UserValue).UserIndex;
    TObjectGI(DraggedAward.UserValue).UserIndex := Temp;
    with Sender as TImageGI do
    begin
      SetImagePath(GetAwardImagePath(Sender.UserIndex));
      SetSize(GetContentSize);
    end;
    with DraggedAward as TImageGI do
    begin
      SetImagePath(GetAwardImagePath(DraggedAward.UserIndex));
      SetSize(GetContentSize);
    end;
    DraggedAward := nil;
    SoundManager.PlaySound('Sound.SlotPut');
    PlatformMouseEnter(Sender);
  end;
  UpdateActionCursor(False);
end;

procedure TfRewards.IncreaseVisibleCount(Sender: TObjectGI);
begin
  if Ship.AwardVisibleCount < Ship.AwardIds.Count then
    Inc(Ship.AwardVisibleCount);
  RefreshVisibleCount;
end;

procedure TfRewards.DecreaseVisibleCount(Sender: TObjectGI);
begin
  if Ship.AwardVisibleCount > 0 then
    Dec(Ship.AwardVisibleCount);
  RefreshVisibleCount;
end;

procedure TfRewards.RefreshVisibleCount;
begin
  (GetByName('RewardCount') as TLabelGI).SetText(IntToStr(Ship.AwardVisibleCount));
  (GetByName('Sub') as TGraphButtonGI).SetDisabled(Ship.AwardVisibleCount <= 1);
  (GetByName('Add') as TGraphButtonGI).SetDisabled(Ship.AwardVisibleCount >= Ship.AwardIds.Count);
end;

procedure TfRewards.BuildAwardControls;
var
  I, Count, X, Y: Integer;
  Platform: TImageGI;
  AwardId: Byte;
begin
  AwardsPanel.FreeOwnedChildren;
  if Ship.AwardIds <> nil then
    Count := Max(10, Ship.AwardIds.Count)
  else
    Count := 10;
  if Count > 10 then
    Count := ((Count + 2) div 3) * 3;
  with TObjectGI.Create(AwardsPanel) do
  begin
    SetPosition(Classes.Point(0, 0));
    SetSize(Classes.Point(1, 1));
    SetPositionModeW(True);
  end;
  for I := 0 to Count - 1 do
  begin
    Platform := TImageGI.Create(AwardsPanel);
    Platform.SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Platform.SetSize(Platform.GetContentSize);
    Platform.SetOrigin(HalfPoint(Platform.ClientSize));
    X := AwardsPanel.ClientSize.X div 3;
    X := X * (I mod 3) + (X - Platform.ClientSize.X div 2);
    Y := AwardsPanel.ClientSize.Y div 4;
    Y := Y * (I div 3) + (Y - Platform.ClientSize.Y div 2);
    Platform.SetPosition(Classes.Point(X, Y));
    Platform.SetPositionModeW(True);
    if (Ship.AwardIds <> nil) and (I < Ship.AwardIds.Count) then
    begin
      AwardId := Byte(Ship.AwardIds[I]);
      Platform.UserValue := PtrInt(Platform);
      Platform.UserIndex := AwardId;
      Platform.MouseEnterCallback := PlatformMouseEnter;
      Platform.MouseLeaveCallback := AwardMouseLeave;
    end
    else
    begin
      Platform.UserValue := 0;
      Platform.UserIndex := 255;
    end;
    if (Ship.AwardIds <> nil) and (I < Ship.AwardIds.Count) then
    begin
      AwardId := Byte(Ship.AwardIds[I]);
      with TImageGI.Create(AwardsPanel) do
      begin
        SetImagePath(GetAwardImagePath(AwardId));
        SetSize(GetContentSize);
        SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y));
        SetPositionModeW(True);
        SetPosition(Classes.Point(X, Y));
        UserValue := PtrInt(Platform);
        UserIndex := AwardId;
        UserData := I;
        MouseEnterCallback := AwardMouseEnter;
        MouseLeaveCallback := AwardMouseLeave;
        if CanEditAwards then
          LeftButtonDownCallback := AwardMouseDown
        else
          LeftButtonDownCallback := nil;
      end;
    end;
  end;
  AwardsPanel.MouseLeaveCallback := ClearHighlight;
  AwardsPanel.UpdateScrollRanges;
  AwardsPanel.SetVerticalScrollbarEnabled(Count > 10);
end;

procedure TfRewards.UpdateActionCursor(CanTake: Boolean);
begin
  if DraggedAward = nil then
  begin
    if (HoveredAwardId >= 0) and CanEditAwards then
      SetCursorByName('Take')
    else
      SetCursorByName('Main');
  end
  else
    SetCursorImage(GetAwardImagePath(DraggedAward.UserIndex), Classes.Point(16, 16));
end;

procedure TfRewards.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then
    RequestClose(2);
end;

procedure TfRewards.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL)
      and not IsVirtualKeyDown(VK_SHIFT)
      and not IsVirtualKeyDown(VK_MENU) then
  begin
    if (Key = VK_ESCAPE) or (Key = VK_RETURN) or (Key = Ord('R')) then
      CloseClicked(nil);
    with GetByName('PTable') as TPanelScrollBarGI do
    begin
      if Key = VK_UP then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.SmallChange)
      else if Key = VK_DOWN then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.SmallChange)
      else if Key = VK_PRIOR then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.LargeChange)
      else if Key = VK_NEXT then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.LargeChange);
    end;
  end;
end;

procedure TfRewards.SelectMusic;
begin
  if GetPlayer = nil then
    MusicManager.PlayCategory('Base')
  else if GetPlayer.IsOnPlanet then
  begin
    if not MusicInPlanetEnabled then
      MusicManager.RequestFadeOut
    else if GetPlayer.CurrentPlanet.OwnerId = Byte(oiPirate) then
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
    if not MusicInPlanetEnabled then
      MusicManager.RequestFadeOut
    else if GetPlayer.DockedTo.TypeId in [Ord(rstPirateBase), Ord(rstDominion)] then
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

function RunRewards(ParentLoop: TMessageLoopGI; ReadOnly: Boolean): Boolean;
var
  CursorAlignment:
      array[0..1] of
          Byte; // Native cursor record starts at EBP-$20; the shared packed layout otherwise lands two bytes higher.
  State: TCursorStateGI;
begin
  ParentLoop.RootUiObject.NativeHook50;
  ParentLoop.CaptureCursorState(@State);
  ParentLoop.SetCursorActive(False);
  ParentLoop.DrawQueuedUpdateRects;
  RewardsScreen.ParentLoop := ParentLoop;
  ParentLoop.ChildLoop := RewardsScreen;
  RewardsScreen.ReadOnly := ReadOnly;
  if RewardsScreen.Run = 1 then
    Result := True
  else
    Result := False;
  RewardsScreen.ParentLoop := nil;
  ParentLoop.ChildLoop := nil;
  ParentLoop.InvalidateViewport;
  ParentLoop.RestoreCursorState(@State);
  ParentLoop.UpdateCursorPosition;
  ParentLoop.RootUiObject.NativeHook48;
  ParentLoop.Present;
end;

procedure TfRewards.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then
    with GetByName('PTable') as TPanelScrollBarGI do
      VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.SmallChange * 5)
  else if Delta = -WHEEL_DELTA then
    with GetByName('PTable') as TPanelScrollBarGI do
      VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.SmallChange * 5);
end;

procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
  TNormalShip.ClassName;
  TPanelScrollBarGI.ClassName;
  TShip.ClassName;
end;
end.
