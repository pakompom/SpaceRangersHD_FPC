{$EXCESSPRECISION OFF}
unit fEquipmentShop;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  aGalaxy,
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  GI_Image,
  GI_MessageLoop,
  GI_Window,
  Types,
  aItem,
  aPlanet,
  aRuins,
  fPanelLoad,
  fPanelMain,
  fPanelPlanet,
  fPanelRuins;
type
  TShopSlot = class;
  TfEquipmentShop = class;
  TShopSlot = class(TObjectEx)
    GridPoint: TPoint;
    Item: TItem;
    SlotImage: TImageGI;
    BorderImage: TImageGI;
    TypeOverlayImage: TImageGI;
    ItemIconImage: TImageGI;
    ItemAnimation: TgaiGI;
    MicroModuleImage: TImageGI;
    constructor Create;
    destructor Destroy; override;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
  end;
  TfEquipmentShop = class(TMessageLoopGIWithMainPanel)
    PlanetPanel: TfPanelPlanet;
    StationPanel: TfPanelRuins;
    LoadPanel: TfPanelLoad;
    ItemInfoAnchor: TPoint;
    ItemInfoWindow: TWindowGI;
    UnknownEC: Integer;
    ContentColumnCount: Integer;
    TargetScrollX: Integer;
    ScrollTimer: PCallbackTimerGI;
    ItemInfoTimer: PCallbackTimerGI;
    OpenPreviewTimer: PCallbackTimerGI;
    PreviewSlot: TShopSlot;
    HullSizeOffset: TPoint;
    HullPriceOffset: TPoint;
    HullRaceOffset: TPoint;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
    constructor Create;
    destructor Destroy; override;
    procedure BuildGoodsControls;
    procedure ClearGoodsControls;
    procedure EndTurnClicked(Sender: TObjectGI);
    procedure ShipClicked(Sender: TObjectGI);
    procedure UpdateScrollButtons;
    procedure StartSlotAnimatedPreview(Slot: TShopSlot);
    procedure ScheduleSlotPreviewStop(Slot: TShopSlot);
    procedure ItemMouseEnter(Sender: TObjectGI);
    procedure ItemMouseLeave(Sender: TObjectGI);
    procedure ScrollLeft(Sender: TObjectGI);
    procedure ScrollRight(Sender: TObjectGI);
    procedure ScrollTick(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure PanelScrollChanged(Sender: TObjectGI);
    procedure ItemMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure ChooseAnimatedPreview(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure PreviewCycleComplete(Sender: TObjectGI);
    procedure HideItemInfo(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure RefreshItemInfo(Item: TItem);
    procedure BuildHullSlotOverlays(
        Parent: TObjectGI;
        Hull: THull;
        OffsetX: Integer;
        OffsetY: Integer
    );
    procedure RefreshHullInfo(
        Target: TMessageLoopGI;
        Hull: THull;
        Text: WideString;
        SuppressImage: Boolean
    );
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
var
  ShopGridRowCount: Integer = 4;
  ShopVisibleColumnCount: Integer = 6;
  TemporaryShopSlots: TList = nil;
  TemporaryShopPlanet: TPlanet = nil;
  TemporaryShopStation: TRuins = nil;
procedure TemporaryShopStockHook(Argument: Pointer);
procedure BuildTemporaryShopSlotGrid;
procedure RestoreTemporaryShopStock;
procedure ClearTemporaryShopSlotGrid;
function FindShopSlotByGridPoint(Point: TPoint): TShopSlot;
function FindShopSlotByItem(Item: TItem): TShopSlot;
function GetShopItemIconName(Item: TItem): WideString;
procedure LinkRecoveredTypes;
implementation
uses
  GI_Main,
  ThreadCalc,
  aCalc,
  aGalaxyEvent,
  GI_MessageBox,
  SE_Space,
  aKling,
  aScript,
  GI_GraphBuf,
  GI_GI,
  fShip2,
  fRuinsTalk,
  aPlayer,
  aGalaxyStruct,
  aConst,
  aShip,
  aMyFunction,
  EC_Str,
  Math,
  Windows,
  SysUtils,
  GI_Panel,
  GI_PanelScrollBar,
  GI_GraphButton,
  GI_Label,
  GR_Main,
  GR_Music,
  Globals,
  GlobalsV;

procedure TemporaryShopStockHook(Argument: Pointer);
begin
end;

procedure BuildTemporaryShopSlotGrid;
var
  X, Y, EmptyCount, I, J: Integer;
  Slot, Other: TShopSlot;
  Item: TItem;
  ItemOrder, OtherOrder: Integer;
  Station: TRuins;
begin
  TemporaryShopStockHook(nil);
  ClearTemporaryShopSlotGrid;
  TemporaryShopSlots := TList.Create;
  if GetPlayer.CurrentPlanet <> nil then
  begin
    for I := 0 to GetPlayer.CurrentPlanet.EquipmentShop.Count - 1 do
    begin
      Item := TItem(GetPlayer.CurrentPlanet.EquipmentShop[I]);
      Slot := TShopSlot.Create;
      TemporaryShopSlots.Add(Slot);
      Slot.Item := Item;
    end;
    GetPlayer.CurrentPlanet.EquipmentShop.Clear;
    TemporaryShopPlanet := GetPlayer.CurrentPlanet;
  end
  else
  begin
    if GetPlayer.DockedTo = nil then
      Exit;
    if not (GetPlayer.DockedTo is TRuins) then
      Exit;
    Station := GetPlayer.DockedTo as TRuins;
    for I := 0 to Station.EquipmentShop.Count - 1 do
    begin
      Item := TItem(Station.EquipmentShop[I]);
      Slot := TShopSlot.Create;
      TemporaryShopSlots.Add(Slot);
      Slot.Item := Item;
    end;
    Station.EquipmentShop.Clear;
    TemporaryShopStation := Station;
  end;
  for I := 0 to TemporaryShopSlots.Count - 2 do
  begin
    Slot := TemporaryShopSlots[I];
    if Slot.Item = nil then
      Continue;
    for J := I + 1 to TemporaryShopSlots.Count - 1 do
    begin
      Other := TemporaryShopSlots[J];
      if Other.Item = nil then
        Continue;
      if Slot.Item.ItemType in [t_Hull..t_CustomWeapon] then
        ItemOrder := Ord(Slot.Item.ItemType) - 75
      else
        ItemOrder := Ord(Slot.Item.ItemType);
      if Other.Item.ItemType in [t_Hull..t_CustomWeapon] then
        OtherOrder := Ord(Other.Item.ItemType) - 75
      else
        OtherOrder := Ord(Other.Item.ItemType);
      if (ItemOrder > OtherOrder)
          or ((ItemOrder = OtherOrder) and (Slot.Item.Cost > Other.Item.Cost)) then
      begin
        Item := Slot.Item;
        Slot.Item := Other.Item;
        Other.Item := Item;
      end;
    end;
  end;
  EmptyCount := 0;
  if TemporaryShopSlots.Count < ShopVisibleColumnCount * ShopGridRowCount then
    EmptyCount := ShopVisibleColumnCount * ShopGridRowCount - TemporaryShopSlots.Count
  else if TemporaryShopSlots.Count mod ShopGridRowCount <> 0 then
    EmptyCount := ShopGridRowCount - TemporaryShopSlots.Count mod ShopGridRowCount;
  for I := 1 to EmptyCount do
  begin
    Slot := TShopSlot.Create;
    Slot.Item := nil;
    TemporaryShopSlots.Add(Slot);
  end;
  EmptyCount := 0;
  for Y := 0 to ShopGridRowCount - 1 do
    for X := 0 to TemporaryShopSlots.Count div ShopGridRowCount - 1 do
    begin
      Slot := TemporaryShopSlots[EmptyCount];
      Slot.GridPoint := Classes.Point(X, Y);
      Inc(EmptyCount);
    end;
end;

procedure RestoreTemporaryShopStock;
var
  I, Count: Integer;
  Slot: TShopSlot;
begin
  if TemporaryShopSlots = nil then
    Exit;
  if TemporaryShopPlanet <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[I];
      if Slot.Item <> nil then
        TemporaryShopPlanet.EquipmentShop.Add(Slot.Item);
      Slot.Item := nil;
    end;
  end
  else if TemporaryShopStation <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[I];
      if Slot.Item <> nil then
        TemporaryShopStation.EquipmentShop.Add(Slot.Item);
      Slot.Item := nil;
    end;
  end;
  ClearTemporaryShopSlotGrid;
end;

procedure ClearTemporaryShopSlotGrid;
var
  I, Count: Integer;
  Slot: TShopSlot;
begin
  if TemporaryShopSlots <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[I];
      Slot.Free;
    end;
    TemporaryShopSlots.Clear;
    TemporaryShopSlots.Free;
    TemporaryShopSlots := nil;
    TemporaryShopPlanet := nil;
    TemporaryShopStation := nil;
  end;
end;

function FindShopSlotByGridPoint(Point: TPoint): TShopSlot;
var
  Count, I: Integer;
  Slot: TShopSlot;
begin
  Count := TemporaryShopSlots.Count;
  for I := 0 to Count - 1 do
  begin
    Slot := TemporaryShopSlots[I];
    if (Slot.GridPoint.X = Point.X) and (Slot.GridPoint.Y = Point.Y) then
    begin
      Result := Slot;
      Exit;
    end;
  end;
  Result := nil;
end;

function FindShopSlotByItem(Item: TItem): TShopSlot;
var
  I: Integer;
begin
  for I := 0 to TemporaryShopSlots.Count - 1 do
    if TShopSlot(TemporaryShopSlots[I]).Item = Item then
    begin
      Result := TemporaryShopSlots[I];
      Exit;
    end;
  Result := nil;
end;

function GetShopItemIconName(Item: TItem): WideString;
var
  Owner: Byte;
begin
  if (Item is TEquipment)
      and (Item.ItemType in [t_FuelTanks..t_DefGenerator])
      and (GetPlayer <> nil)
      and GetPlayer.IsHealthEffectActive(3) then
  begin
    Owner := Item.OwnerId;
    Item.OwnerId := Byte(oiDominator);
    Result := Item.GetBitmapResourceName;
    Item.OwnerId := Owner;
  end
  else
    Result := Item.GetBitmapResourceName;
end;

constructor TShopSlot.Create;
begin
  inherited Create;
end;

destructor TShopSlot.Destroy;
begin
  if Item <> nil then
  begin
    Item.Free;
    Item := nil;
  end;
  if SlotImage <> nil then
  begin
    SlotImage.Free;
    SlotImage := nil;
  end;
  if BorderImage <> nil then
  begin
    BorderImage.Free;
    BorderImage := nil;
  end;
  if TypeOverlayImage <> nil then
  begin
    TypeOverlayImage.Free;
    TypeOverlayImage := nil;
  end;
  if ItemIconImage <> nil then
  begin
    ItemIconImage.Free;
    ItemIconImage := nil;
  end;
  if ItemAnimation <> nil then
  begin
    ItemAnimation.Free;
    ItemAnimation := nil;
  end;
  if MicroModuleImage <> nil then
  begin
    MicroModuleImage.Free;
    MicroModuleImage := nil;
  end;
  inherited Destroy;
end;

procedure TShopSlot.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddAnsiChar(AnsiChar(GridPoint.X));
  Buffer.AddAnsiChar(AnsiChar(GridPoint.Y));
  if Item = nil then
    Buffer.AddAnsiChar(#0)
  else
  begin
    Buffer.AddAnsiChar(#1);
    Buffer.AddAnsiChar(AnsiChar(Item.ItemType));
    if Item is TWeapon then
      (Item as TWeapon).Target := nil;
    Item.SaveToBuffer(Buffer);
  end;
end;

procedure TShopSlot.LoadFromBuffer(Buffer: TBufEC; Galaxy: TGalaxy);
begin
  GridPoint.X := Buffer.GetByte;
  GridPoint.Y := Buffer.GetByte;
  if Buffer.GetByte = 1 then
  begin
    Item := TObject(CreateItemByType(MigrateSavedItemType(Buffer.GetByte))) as TEquipment;
    Item.LoadFromBuffer(Buffer, Galaxy);
  end;
end;

constructor TfEquipmentShop.Create;
begin
  inherited Create;
  PlanetPanel := TfPanelPlanet.Create;
  StationPanel := TfPanelRuins.Create;
  LoadPanel := TfPanelLoad.Create;
end;

destructor TfEquipmentShop.Destroy;
begin
  if PlanetPanel <> nil then
  begin
    PlanetPanel.Free;
    PlanetPanel := nil;
  end;
  if StationPanel <> nil then
  begin
    StationPanel.Free;
    StationPanel := nil;
  end;
  if LoadPanel <> nil then
  begin
    LoadPanel.Free;
    LoadPanel := nil;
  end;
  inherited Destroy;
end;

procedure TfEquipmentShop.InitializeLayout;
var
  ExtraWidth: Integer;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self);
  StationPanel.InitializeLayout(Self);
  LoadPanel.InitializeLayout(Self);
  ExtraWidth := ExtraScreenWidth div 198 * 198;
  if ExtraWidth > 198 then
    ExtraWidth := 198;
  ShopVisibleColumnCount := 6 + ExtraWidth div 99;
  AppendLogTextThreadSafe('fEquipmentShop... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGCity').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGCity2').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('PanelShop') do
    begin
      SetSize(Classes.Point(ClientSize.X + ExtraWidth, ClientSize.Y));
      SetPosition(
          Classes.Point(
              (GameScreenWidth - ClientSize.X) div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
      if ExtraWidth > 0 then
      begin
        with FindByNameRecursive('Right') do
          SetPosition(Classes.Point(LocalPosition.X + ExtraWidth, LocalPosition.Y));
        with FindByNameRecursive('ButFormClose') do
          SetPosition(Classes.Point(LocalPosition.X + ExtraWidth, LocalPosition.Y));
        with FindByNameRecursive('PanelImage') do
          SetSize(Classes.Point(ClientSize.X + ExtraWidth, ClientSize.Y));
        with FindByNameRecursive('BGImageRace') do
          SetSize(Classes.Point(ClientSize.X + ExtraWidth, ClientSize.Y));
        with FindByNameRecursive('PanelGoods') do
          SetSize(Classes.Point(ClientSize.X + ExtraWidth, ClientSize.Y));
      end;
    end;
  end;
  AppendLogLineThreadSafe('ok');
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  ItemInfoWindow := GetByName('PII') as TWindowGI;
  with GetByName('InfoHullSize') do
    HullSizeOffset := Classes.Point(LocalPosition.X, LocalPosition.Y - Parent.ClientSize.Y);
  with GetByName('InfoHullPrice') do
    HullPriceOffset := Classes.Point(LocalPosition.X, LocalPosition.Y - Parent.ClientSize.Y);
  with GetByName('InfoHullEmRace') do
    HullRaceOffset :=
        Classes.Point(LocalPosition.X - Parent.ClientSize.X, LocalPosition.Y - Parent.ClientSize.Y);
end;

procedure TfEquipmentShop.OnOpen;
var
  Owner: Byte;
  Size: Integer;
  BackgroundPath: WideString;
  SavedSlots: TList;
begin
  if not MusicInPlanetEnabled then
    MusicManager.RequestFadeOut;
  MainPanel.OnOpen;
  LoadPanel.OnOpen;
  if GetPlayer.IsOnPlanet then
  begin
    PlanetPanel.OnOpen;
    PlanetPanel.Show;
    StationPanel.Hide;
  end
  else
  begin
    PlanetPanel.Hide;
    StationPanel.OnOpen;
    StationPanel.Show;
  end;
  with GetByName('ButFormClose') as TGraphButtonGI do
    if GetPlayer.IsOnPlanet then
      UpCallback := PlanetPanel.PlanetClicked
    else if GetPlayer.IsDockedToShip then
      UpCallback := StationPanel.ServicesClicked;
  with GetByName('BGCity2') as TImageGI do
  begin
    SetActive(GetPlayer.IsDockedToShip and (GetPlayer.DockedTo.TypeId = Byte(rstMilitaryBase)));
    if Active then
    begin
      SetImagePath('GAI,' + GetPlayer.CurrentStar.GetBackgroundImagePath(Size));
      GaiImageControl.LoadFrameSequenceFromText('[50,0-0]');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end;
  with GetByName('BGCity') as TImageGI do
    if GetPlayer.IsOnPlanet then
    begin
      SetActive(True);
      (FindByNameRecursive('BGCity') as TImageGI)
          .SetImagePath(GetPlayer.CurrentPlanet.GetGovernmentBackgroundGraph);
    end
    else if GetPlayer.IsDockedToShip then
    begin
      SetActive(True);
      if GetPlayer.DockedTo.TypeNameOverrideKey <> '' then
      begin
        BackgroundPath :=
            'Bm.FormRuins.' + GiResourceSuffix + GetPlayer.DockedTo.TypeNameOverrideKey + 'bg';
        if CacheDataRoot.FileExistsByPath(BackgroundPath) then
          SetImagePath('GI,' + BackgroundPath)
        else
          SetImagePath(
              'GI,Bm.FormRuins.'
                  + GiResourceSuffix
                  + ShipTypeNames[GetPlayer.DockedTo.TypeId].Name
                  + 'bg'
          );
      end
      else
        SetImagePath(
            'GI,Bm.FormRuins.'
                + GiResourceSuffix
                + ShipTypeNames[GetPlayer.DockedTo.TypeId].Name
                + 'bg'
        );
    end
    else
      SetActive(False);
  with GetByName('BGImageRace') as TImageGI do
  begin
    if GetPlayer.IsOnPlanet then
      Owner := RaceToOwner(GetPlayer.CurrentPlanet.RaceId)
    else if GetPlayer.IsDockedToShip then
      Owner := GetPlayer.DockedTo.OwnerId
    else
      Owner := 0;
    SetActive(True);
    if Owner = 1 then
      SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'Peleng')
    else if Owner = 2 then
      SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'People')
    else if Owner = 3 then
      SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'Fei')
    else if Owner = 4 then
      SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'Gaal')
    else
      SetActive(False);
  end;
  with GetByName('Left') as TGraphButtonGI do
    DownCallback := ScrollLeft;
  with GetByName('Right') as TGraphButtonGI do
    DownCallback := ScrollRight;
  GetByName('PII').SetActive(False);
  ClearGoodsControls;
  RestoreTemporaryShopStock;
  if GetPlayer <> nil then
  begin
    SavedSlots := TemporaryShopSlots;
    TemporaryShopSlots := nil;
    GetPlayer.ScriptItemsAct(satOnEnteringForm, nil, nil, 0);
    TemporaryShopSlots := SavedSlots;
  end;
  BuildTemporaryShopSlotGrid;
  BuildGoodsControls;
  UpdateScrollButtons;
  PreviewSlot := nil;
  if OpenPreviewTimer <> nil then
  begin
    CancelCallbackTimer(OpenPreviewTimer);
    OpenPreviewTimer := nil;
  end;
  if AnimItem then
    OpenPreviewTimer := ScheduleCallbackTimer(100, 99999, ChooseAnimatedPreview);
  MainPanel.RebuildMessageButtons(False);
  aCalc.WaitForTurnCalculationUI;
end;

procedure TfEquipmentShop.OnClose;
var
  Slot: TShopSlot;
  I, Count: Integer;
begin
  aCalc.WaitForTurnCalculationUI;
  if GetPlayer <> nil then
    GetPlayer.ScriptItemsAct(satOnLeavingForm, nil, nil, 0);
  if TemporaryShopSlots <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[I];
      if Slot.SlotImage <> nil then
      begin
        Slot.SlotImage.Free;
        Slot.SlotImage := nil;
      end;
      if Slot.BorderImage <> nil then
      begin
        Slot.BorderImage.Free;
        Slot.BorderImage := nil;
      end;
      if Slot.TypeOverlayImage <> nil then
      begin
        Slot.TypeOverlayImage.Free;
        Slot.TypeOverlayImage := nil;
      end;
      if Slot.ItemIconImage <> nil then
      begin
        Slot.ItemIconImage.Free;
        Slot.ItemIconImage := nil;
      end;
      if Slot.ItemAnimation <> nil then
      begin
        Slot.ItemAnimation.Free;
        Slot.ItemAnimation := nil;
      end;
      if Slot.MicroModuleImage <> nil then
      begin
        Slot.MicroModuleImage.Free;
        Slot.MicroModuleImage := nil;
      end;
    end;
  end;
  if OpenPreviewTimer <> nil then
  begin
    CancelCallbackTimer(OpenPreviewTimer);
    OpenPreviewTimer := nil;
  end;
  if ScrollTimer <> nil then
  begin
    CancelCallbackTimer(ScrollTimer);
    ScrollTimer := nil;
  end;
  if ItemInfoTimer <> nil then
  begin
    CancelCallbackTimer(ItemInfoTimer);
    ItemInfoTimer := nil;
  end;
  RestoreTemporaryShopStock;
  MainPanel.OnClose;
  LoadPanel.OnClose;
  if (GetPlayer <> nil) and GetPlayer.IsOnPlanet then
    PlanetPanel.OnClose
  else
    StationPanel.OnClose;
end;

procedure TfEquipmentShop.BuildGoodsControls;
var
  Slot: TShopSlot;
  I, Count: Integer;
  Panel: TPanelGI;
  X, Y, Cost: Integer;
  CellWidth, CellHeight: Single;
  LevelSuffix: WideString;
begin
  UnknownEC := 0;
  ContentColumnCount := 0;
  Count := TemporaryShopSlots.Count;
  for I := 0 to Count - 1 do
  begin
    Slot := TemporaryShopSlots[I];
    if ContentColumnCount <= Slot.GridPoint.X then
      ContentColumnCount := Slot.GridPoint.X + 1;
  end;
  Panel := GetByName('PanelGoods') as TPanelGI;
  CellWidth := Panel.ClientSize.X / ShopVisibleColumnCount;
  CellHeight := Panel.ClientSize.Y / ShopGridRowCount;
  for I := 1 to ContentColumnCount - 1 do
    with TImageGI.Create(Panel) do
    begin
      SetPositionModeW(True);
      SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'Line');
      SetSize(GetContentSize);
      SetOrigin(Classes.Point(ClientSize.X div 2, 0));
      SetPosition(
          Classes.Point(Round(I * CellWidth), Panel.ClientSize.Y div 2 - ClientSize.Y div 2)
      );
      SetDepth(4);
      UserData := 1;
    end;
  for Y := 0 to ShopGridRowCount - 1 do
    for X := 0 to ContentColumnCount - 1 do
    begin
      Slot := FindShopSlotByGridPoint(Classes.Point(X, Y));
      Slot.SlotImage := TImageGI.Create(Panel);
      with Slot.SlotImage do
      begin
        SetPositionModeW(True);
        SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
        SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
        SetDepth(3);
        UserValue := PtrInt(Slot);
        if Slot.Item = nil then
          SetActive(False)
        else
        begin
          if Slot.Item is TWeapon then
            (Slot.Item as TWeapon).Target := nil;
          SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotN');
          MouseEnterCallback := ItemMouseEnter;
          MouseLeaveCallback := ItemMouseLeave;
          LeftButtonUpCallback := ItemMouseUp;
        end;
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      Slot.BorderImage := TImageGI.Create(Panel);
      with Slot.BorderImage do
      begin
        SetPositionModeW(True);
        SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
        SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
        SetDepth(3);
        if Slot.Item = nil then
          SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderN')
        else
        begin
          Cost := Slot.Item.GetConditionAdjustedCost;
          if Slot.Item is THull then
            Cost :=
                Max(
                    1,
                    Cost
                        - GetPlayer.GetHull.CalculateResaleValue(
                            GetPlayer.GetEffectiveSkillLevel(psTrading))
                );
          if (GetPlayer.Money < Cost)
              or ((Slot.Item.ItemType <> t_Hull)
                  and (GetPlayer.GetCargoFreeSpace < Slot.Item.Weight)) then
            SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderH')
          else
            SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderN');
        end;
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      if Slot.Item <> nil then
      begin
        Slot.TypeOverlayImage := TImageGI.Create(Panel);
        with Slot.TypeOverlayImage do
        begin
          SetPositionModeW(True);
          SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
          SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
          SetDepth(3);
          if TEquipment(Slot.Item).GetLevel <> 0 then
            LevelSuffix := '_' + IntToWideString(TEquipment(Slot.Item).GetLevel)
          else if Slot.Item is TMicroModule then
            LevelSuffix :=
                '_'
                    + IntToWideString(
                        GetMicroModulePriorityColorTier(TEquipment(Slot.Item).MicroModuleIndex - 1))
          else
            LevelSuffix := '';
          if (TEquipment(Slot.Item).ConfigBlockName <> '')
              and CacheDataRoot.FileExistsByPath(
                  'Bm.FormShop2.'
                      + GiResourceSuffix
                      + 'Slot'
                      + TEquipment(Slot.Item).ConfigBlockName
                      + LevelSuffix) then
            SetImagePath(
                'GI,Bm.FormShop2.'
                    + GiResourceSuffix
                    + 'Slot'
                    + TEquipment(Slot.Item).ConfigBlockName
                    + LevelSuffix
            )
          else if (Slot.Item is TMicroModule)
              and (MicroModuleTemplates[TEquipment(Slot.Item).MicroModuleIndex - 1].KindGraph <> '')
              and CacheDataRoot.FileExistsByPath(
                  'Bm.FormShop2.'
                      + GiResourceSuffix
                      + 'Slot'
                      + MicroModuleTemplates[TEquipment(Slot.Item).MicroModuleIndex - 1].KindGraph
                      + LevelSuffix) then
            SetImagePath(
                'GI,Bm.FormShop2.'
                    + GiResourceSuffix
                    + 'Slot'
                    + MicroModuleTemplates[TEquipment(Slot.Item).MicroModuleIndex - 1].KindGraph
                    + LevelSuffix
            )
          else if CacheDataRoot.FileExistsByPath(
              'Bm.FormShop2.'
                  + GiResourceSuffix
                  + 'Slot'
                  + ItemTypeNames[Ord(Slot.Item.ItemType)]
                  + LevelSuffix) then
            SetImagePath(
                'GI,Bm.FormShop2.'
                    + GiResourceSuffix
                    + 'Slot'
                    + ItemTypeNames[Ord(Slot.Item.ItemType)]
                    + LevelSuffix
            )
          else if (Slot.Item is TArtefact)
              and CacheDataRoot.FileExistsByPath(
                  'Bm.FormShop2.' + GiResourceSuffix + 'SlotArtefact') then
            SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotArtefact')
          else if (Slot.Item is TWeapon)
              and CacheDataRoot.FileExistsByPath(
                  'Bm.FormShop2.' + GiResourceSuffix + 'SlotWeapon' + LevelSuffix) then
            SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotWeapon' + LevelSuffix)
          else
            SetImagePath(
                'GI,Bm.FormShop2.'
                    + GiResourceSuffix
                    + 'SlotLevel'
                    + IntToWideString(TEquipment(Slot.Item).GetLevel)
            );
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
      end;
      if Slot.Item <> nil then
      begin
        Slot.ItemIconImage := TImageGI.Create(Panel);
        with Slot.ItemIconImage do
        begin
          SetPositionModeW(True);
          SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
          SetSize(Classes.Point(Trunc(CellWidth) - GiScalePixels(10), Trunc(CellHeight)));
          SetDepth(2);
          SetActive(True);
          SetImagePath('GI,' + GetShopItemIconName(Slot.Item) + 'i');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetActive(True);
        end;
        if AnimItem then
        begin
          Slot.ItemAnimation := TgaiGI.Create(Panel);
          with Slot.ItemAnimation do
          begin
            SetPositionModeW(True);
            SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
            SetSize(Classes.Point(Trunc(CellWidth) - GiScalePixels(10), Trunc(CellHeight)));
            SetDepth(1);
            SetImagePath(GetShopItemIconName(Slot.Item) + 'a');
            SequenceIndex := 0;
            SetActive(False);
          end;
        end;
      end;
      if (Slot.Item <> nil)
          and TEquipment(Slot.Item).HasMicroModule
          and (Slot.Item.ItemType in [t_Hull..t_CustomWeapon]) then
      begin
        Slot.MicroModuleImage := TImageGI.Create(Panel);
        with Slot.MicroModuleImage do
        begin
          SetImagePath(
              'GI,'
                  + GetMicroModuleBitmapResourceName(TEquipment(Slot.Item).MicroModuleIndex - 1)
                  + 'Set'
          );
          SetPositionModeW(True);
          SetPosition(
              Classes.Point(
                  Round(X * CellWidth) + GiScalePixels(5),
                  Round(Y * CellHeight) + GiScalePixels(45)
              )
          );
          SetSize(GetContentSize);
          SetDepth(0);
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetActive(True);
        end;
      end;
    end;
  (Panel as TPanelScrollBarGI).UpdateScrollRanges;
  Panel.ScrollChangedCallback := PanelScrollChanged;
  TargetScrollX := 0;
  Panel.SetScrollOffset(Classes.Point(0, 0));
end;

procedure TfEquipmentShop.ClearGoodsControls;
var
  Slot: TShopSlot;
  I, Count: Integer;
  Panel: TPanelGI;
  Child, Current: TObjectGI;
begin
  if TemporaryShopSlots <> nil then
  begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do
    begin
      Slot := TemporaryShopSlots[I];
      if Slot.SlotImage <> nil then
      begin
        Slot.SlotImage.Free;
        Slot.SlotImage := nil;
      end;
      if Slot.BorderImage <> nil then
      begin
        Slot.BorderImage.Free;
        Slot.BorderImage := nil;
      end;
      if Slot.TypeOverlayImage <> nil then
      begin
        Slot.TypeOverlayImage.Free;
        Slot.TypeOverlayImage := nil;
      end;
      if Slot.ItemIconImage <> nil then
      begin
        Slot.ItemIconImage.Free;
        Slot.ItemIconImage := nil;
      end;
      if Slot.ItemAnimation <> nil then
      begin
        Slot.ItemAnimation.Free;
        Slot.ItemAnimation := nil;
      end;
      if Slot.MicroModuleImage <> nil then
      begin
        Slot.MicroModuleImage.Free;
        Slot.MicroModuleImage := nil;
      end;
    end;
  end;
  Panel := GetByName('PanelGoods') as TPanelGI;
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    Current := Child;
    Child := Child.NextSibling;
    if Current.UserData = 1 then
      Current.Free;
  end;
end;

procedure TfEquipmentShop.EndTurnClicked(Sender: TObjectGI);
begin
  if GetPlayer = nil then
    Exit;
  if GetPlayer.QueuedTravelTarget <> nil then
    Exit;
  if GetPlayer.IsDockedToShip
      and (GetPlayer.DockedTo.TypeId = Byte(rstDominion))
      and (GetPlayer.DockedTo.Order = soTeleport)
      and (Cardinal(GetPlayer.DockedTo.OrderStateData) > 0)
      and not GetPlayer.DockedTo.InHyperspace then
  begin
    RuinsTalkScreen.DepartWithStation(1);
    Exit;
  end;
  if GetPlayer.IsDockedToShip
      and (GetPlayer.DockedTo.TypeId = Byte(rstDominion))
      and ((GetPlayer.DockedTo as TRuins).FlyToStar <> nil)
      and ((GetPlayer.DockedTo as TRuins).FlyToStar <> GetPlayer.CurrentStar)
      and ((GetPlayer.DockedTo as TRuins).FlyDate <= Galaxy.CurrentTurn) then
  begin
    RuinsTalkScreen.DepartWithStation(1);
    Exit;
  end;
  if GetPlayer.IsDockedToShip
      and (GetPlayer.DockedTo.TypeId = Byte(rstMilitaryBase))
      and ((GetPlayer.DockedTo as TRuins).FlyToStar <> nil)
      and ((GetPlayer.DockedTo as TRuins).FlyToStar <> GetPlayer.CurrentStar)
      and ((GetPlayer.DockedTo as TRuins).FlyDate <= Galaxy.CurrentTurn) then
  begin
    if GetPlayer.Speed <= 0 then
    begin
      RuinsTalkScreen.DepartWithStation(1);
      Exit;
    end;
    StationPanel.TakeOffForStationTravel;
  end
  else
  begin
    RefreshItemInfo(nil);
    aCalc.WaitForTurnCalculationUI;
    RestoreTemporaryShopStock;
    MainPanel.EndTurnClicked(Sender);
    MainPanel.RebuildMessageButtons(False);
    if ExitCode = 0 then
    begin
      BuildTemporaryShopSlotGrid;
      aCalc.WaitForTurnCalculationUI;
      ClearGoodsControls;
      BuildGoodsControls;
      UpdateScrollButtons;
      if OpenPreviewTimer <> nil then
      begin
        CancelCallbackTimer(OpenPreviewTimer);
        OpenPreviewTimer := nil;
      end;
      if AnimItem then
        OpenPreviewTimer :=
            ScheduleCallbackTimer(RandomIntRange(3000, 6000), 99999, ChooseAnimatedPreview);
    end;
  end;
end;

procedure TfEquipmentShop.ShipClicked(Sender: TObjectGI);
begin
  if ExitCode <> 0 then
    Exit;
  HideItemInfo(nil, 0);
  SetCursorActive(False);
  Present;
  CaptureScreenBackground(True, 0);
  SetCursorActive(True);
  ShipScreen.PlayTransitionSounds := True;
  aCalc.WaitForTurnCalculationUI;
  while True do
  begin
    RunShipEquipment(Self);
    MainPanel.RefreshMoneyAndCargo;
    MainPanel.RebuildMessageButtons(False);
    ClearGoodsControls;
    BuildGoodsControls;
    UpdateScrollButtons;
    if not ShipScreen.FlagD4 then
      Break;
    SetCursorActive(False);
    DrawQueuedUpdateRects;
    CaptureScreenBackground(True, 0);
    SetCursorActive(True);
  end;
  aCalc.WaitForTurnCalculationUI;
  if GetPlayer.IsOnPlanet then
    if GetPlayer.CurrentPlanet.GetRelationLevelToShip(GetPlayer) = rlHostile then
    begin
      RequestedScreenId := screenGovernment;
      RequestClose(1);
    end;
end;

procedure TfEquipmentShop.UpdateScrollButtons;
var
  Panel: TPanelGI;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  with GetByName('Left') as TGraphButtonGI do
    SetDisabled(Panel.ScrollOffset.X <= 0);
  with GetByName('Right') as TGraphButtonGI do
    SetDisabled(
        Panel.ScrollOffset.X
            >= Round(
                    Panel.ClientSize.X / ShopVisibleColumnCount * ContentColumnCount
                        - Panel.ClientSize.X / ShopVisibleColumnCount * ShopVisibleColumnCount)
                - 1
    );
end;

procedure TfEquipmentShop.StartSlotAnimatedPreview(Slot: TShopSlot);
begin
  if Slot.ItemAnimation <> nil then
  begin
    if not Slot.ItemAnimation.Active then
    begin
      Slot.ItemAnimation.UpdateAutoGeometry;
      Slot.ItemAnimation.SetImageKindX(ikxCenter);
      Slot.ItemAnimation.SetImageKindY(ikyCenter);
      Slot.ItemAnimation.SetActive(True);
    end;
    Slot.ItemAnimation.RestartPlayback;
    if Slot.ItemIconImage <> nil then
    begin
      Slot.ItemIconImage.Free;
      Slot.ItemIconImage := nil;
    end;
  end;
end;

procedure TfEquipmentShop.ScheduleSlotPreviewStop(Slot: TShopSlot);
begin
  if Slot.ItemAnimation <> nil then
    Slot.ItemAnimation.CycleCompleteCallback := PreviewCycleComplete;
end;

procedure TfEquipmentShop.ItemMouseEnter(Sender: TObjectGI);
var
  Slot: TShopSlot;
  Panel: TObjectGI;
begin
  Slot := TShopSlot(Sender.UserValue);
  Slot.SlotImage.SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotA');
  Slot.SlotImage.SetImageKindX(ikxCenter);
  Slot.SlotImage.SetImageKindY(ikyCenter);
  StartSlotAnimatedPreview(Slot);
  Panel := GetByName('PanelShop');
  ItemInfoAnchor :=
      Classes.Point(
          Sender.HitTestBounds.Left + Sender.ClientSize.X div 2,
          Min(Sender.HitTestBounds.Bottom, Panel.HitTestBounds.Bottom - Sender.ClientSize.Y - 24)
      );
  RefreshItemInfo(Slot.Item);
  if not IsCursorImageSelected('Take') then
    SetCursorByName('Take');
end;

procedure TfEquipmentShop.ItemMouseLeave(Sender: TObjectGI);
var
  Slot: TShopSlot;
begin
  Slot := TShopSlot(Sender.UserValue);
  Slot.SlotImage.SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotN');
  Slot.SlotImage.SetImageKindX(ikxCenter);
  Slot.SlotImage.SetImageKindY(ikyCenter);
  ScheduleSlotPreviewStop(Slot);
  RefreshItemInfo(nil);
  if not IsCursorImageSelected('Main') then
    SetCursorByName('Main');
end;

procedure TfEquipmentShop.ScrollLeft(Sender: TObjectGI);
var
  Panel: TPanelGI;
  Column: Integer;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  Column :=
      Round(
          (Panel.ScrollOffset.X - Panel.ClientSize.X / ShopVisibleColumnCount)
              / (Panel.ClientSize.X / ShopVisibleColumnCount)
      );
  if Column < 0 then
    Column := 0;
  TargetScrollX := Round(Panel.ClientSize.X / ShopVisibleColumnCount * Column);
  if (ScrollTimer = nil) and (TargetScrollX <> Panel.ScrollOffset.X) then
    ScrollTimer := ScheduleCallbackTimer(0, 20, ScrollTick);
  UpdateScrollButtons;
end;

procedure TfEquipmentShop.ScrollRight(Sender: TObjectGI);
var
  Panel: TPanelGI;
  Column: Integer;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  Column :=
      Round(
          (Panel.ScrollOffset.X + Panel.ClientSize.X / ShopVisibleColumnCount)
              / (Panel.ClientSize.X / ShopVisibleColumnCount)
      );
  if Column > ContentColumnCount - ShopVisibleColumnCount then
    Column := Max(ContentColumnCount - ShopVisibleColumnCount, 0);
  TargetScrollX := Round(Panel.ClientSize.X / ShopVisibleColumnCount * Column);
  if (ScrollTimer = nil) and (TargetScrollX <> Panel.ScrollOffset.X) then
    ScrollTimer := ScheduleCallbackTimer(0, 20, ScrollTick);
  UpdateScrollButtons;
end;

procedure TfEquipmentShop.ScrollTick(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Panel: TPanelGI;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  if Panel.ScrollOffset.X = TargetScrollX then
  begin
    if ScrollTimer <> nil then
    begin
      CancelCallbackTimer(ScrollTimer);
      ScrollTimer := nil;
    end;
  end
  else if TargetScrollX < Panel.ScrollOffset.X then
    Panel.SetScrollOffset(Classes.Point(Max(TargetScrollX, Panel.ScrollOffset.X - 12), 0))
  else
    Panel.SetScrollOffset(Classes.Point(Min(TargetScrollX, Panel.ScrollOffset.X + 12), 0));
  UpdateScrollButtons;
end;

procedure TfEquipmentShop.PanelScrollChanged(Sender: TObjectGI);
begin
  (GetByName('PanelGoods') as TPanelScrollBarGI).PanelScrollChanged(Sender);
  UpdateScrollButtons;
end;

procedure TfEquipmentShop.ItemMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Slot: TShopSlot;
  Y, X, Cost: Integer;
  Event: TGalaxyEvent;
  PurchasedItem: TItem;
  Destination: PtrInt;
begin
  Slot := TShopSlot(Sender.UserValue);
  if (Slot <> nil) and (Slot.Item <> nil) then
  begin
    aCalc.WaitForTurnCalculationUI;
    Galaxy.PendingEquipmentPurchasePrice := Slot.Item.GetConditionAdjustedCost;
    GetPlayer.GetCargoFreeSpace;
    if (Slot.Item is THull)
        and (GetPlayer.Money < Galaxy.PendingEquipmentPurchasePrice)
        and (GetPlayer.GetHull.ScriptItem = nil)
        and (GetPlayer.GetHull.NoDropFlag = 0) then
      Galaxy.PendingEquipmentPurchasePrice :=
          Max(
              1,
              Galaxy.PendingEquipmentPurchasePrice
                  - GetPlayer.GetHull.CalculateResaleValue(
                      GetPlayer.GetEffectiveSkillLevel(psTrading))
          );
    aCalc.WaitForTurnCalculationUI;
    if GetPlayer.Money < Galaxy.PendingEquipmentPurchasePrice then
    begin
      SoundManager.PlaySound('Sound.NoMoney');
      if Slot.Item is THull then
        ShowMessageBoxGI(
            Self,
            FormatText1(
                LanguageDataConfig.GetParamByPathOrMarker('FormShop.NoMoney'),
                '<color=255,240,100>',
                '<Money>',
                IntToWideString(Galaxy.PendingEquipmentPurchasePrice - GetPlayer.Money)
            ),
            mbgCancel or mbgError
        );
      aCalc.WaitForTurnCalculationUI;
      MainPanel.FlashMoneyWarning;
      if not (Slot.Item is THull) and (GetPlayer.CargoFreeSpace < Slot.Item.Weight) then
        MainPanel.FlashCargoWarning;
      aCalc.WaitForTurnCalculationUI;
    end
    else if not (Slot.Item is THull) and (GetPlayer.CargoFreeSpace < Slot.Item.Weight) then
    begin
      SoundManager.PlaySound('Sound.NoSize');
      MainPanel.FlashCargoWarning;
      aCalc.WaitForTurnCalculationUI;
    end
    else
    begin
      if Slot.Item is THull then
      begin
        if Slot.Item.GetConditionAdjustedCost <= GetPlayer.Money then
        begin
          if ShowMessageBoxGI(
                  Self,
                  FormatText1(
                      LanguageDataConfig.GetParamByPathOrMarker('FormShop.BuyHull'),
                      '<color=255,240,100>',
                      '<Money>',
                      IntToWideString(Galaxy.PendingEquipmentPurchasePrice)
                  ),
                  mbgOK or mbgCancel or mbgQuestion)
              <> mbgResultOK then
            Exit;
        end
        else
        begin
          if ShowMessageBoxGI(
                  Self,
                  FormatText1(
                      LanguageDataConfig.GetParamByPathOrMarker('FormShop.UpgradeHull'),
                      '<color=255,240,100>',
                      '<Money>',
                      IntToWideString(Galaxy.PendingEquipmentPurchasePrice)
                  ),
                  mbgOK or mbgCancel or mbgQuestion)
              <> mbgResultOK then
            Exit;
        end;
      end
      else
      begin
        if ShowMessageBoxGI(
                Self,
                FormatText2(
                    LanguageDataConfig.GetParamByPathOrMarker('FormShop.Buy'),
                    '<color=255,240,100>',
                    '<Item>',
                    RemoveTextTagsW(Slot.Item.GetDisplayName),
                    '<Money>',
                    IntToWideString(Galaxy.PendingEquipmentPurchasePrice)
                ),
                mbgOK or mbgCancel or mbgQuestion)
            <> mbgResultOK then
          Exit;
      end;
      SoundManager.PlaySound('Sound.Buy');
      aCalc.WaitForTurnCalculationUI;
      PurchasedItem := Slot.Item;
      Event := AddGalaxyEvent('PlayerBuysEquipment');
      Event.AddData(Ord(Slot.Item.ItemType));
      Event.AddData(Slot.Item.GetConditionAdjustedCost);
      Event.AddData(Slot.Item.Weight);
      Event.AddData(Slot.Item.Id);
      if GetPlayer.CurrentPlanet <> nil then
      begin
        Event.AddData(0);
        Event.AddData(GetPlayer.CurrentPlanet.Id);
      end
      else if GetPlayer.DockedTo <> nil then
      begin
        Event.AddData(1);
        Event.AddData(GetPlayer.DockedTo.Id);
      end
      else
      begin
        Event.AddData(2);
        Event.AddData(0);
      end;
      Event.AddTextData(Slot.Item.GetDisplayName);
      Event.AddTextData(Slot.Item.GetCategoryConfigName);
      if Slot.Item is THull then
      begin
        if Slot.Item.GetConditionAdjustedCost > GetPlayer.Money then
        begin
          Event := AddGalaxyEvent('PlayerSellsEquipment');
          Event.AddData(Ord(GetPlayer.GetHull.ItemType));
          Event.AddData(
              GetPlayer.GetHull.CalculateResaleValue(GetPlayer.GetEffectiveSkillLevel(psTrading))
          );
          Event.AddData(GetPlayer.GetHull.Weight);
          Event.AddData(GetPlayer.GetHull.Id);
          if GetPlayer.CurrentPlanet <> nil then
          begin
            Event.AddData(0);
            Event.AddData(GetPlayer.CurrentPlanet.Id);
          end
          else if GetPlayer.DockedTo <> nil then
          begin
            Event.AddData(1);
            Event.AddData(GetPlayer.DockedTo.Id);
          end
          else
          begin
            Event.AddData(2);
            Event.AddData(0);
          end;
          Event.AddTextData(GetPlayer.GetHull.GetDisplayName);
          Event.AddTextData(GetPlayer.GetHull.GetCategoryConfigName);
          GetPlayer.SetMoney(GetPlayer.Money - Galaxy.PendingEquipmentPurchasePrice);
          GetPlayer.ScriptItemsAct(satOnPlayerChangeHull, Slot.Item, GetPlayer.GetHull, 0);
          GetPlayer.Inventory.Delete(GetPlayer.Inventory.IndexOf(GetPlayer.GetHull));
          GetPlayer.GetHull.Free;
          GetPlayer.Inventory.Insert(0, Slot.Item);
          GetPlayer.Hull := Slot.Item as THull;
          GetPlayer.GetHull.OwnerShip := GetPlayer;
          GetPlayer.GetHull.AssignedSlotData := 0;
          if Slot.Item.ScriptItem <> nil then
            TScriptItem(Slot.Item.ScriptItem)
                .RunActionCode(satOnPlayerChangeHull, GetPlayer, Slot.Item, nil, 0);
          Slot.Item := nil;
          GetPlayer.RefreshAssignedItemSlots;
          GetPlayer.RebuildEquipmentCache;
          GetPlayer.RefreshDerivedStats(True);
          if not GetPlayer.ScriptChameleon then
          begin
            ReleaseSpaceObject(GetPlayer.Graphic);
            GetPlayer.RefreshGraphic;
          end;
          Destination := PtrInt(GetPlayer);
        end
        else
        begin
          GetPlayer.SetMoney(GetPlayer.Money - Slot.Item.GetConditionAdjustedCost);
          if GetPlayer.IsOnPlanet then
            GetPlayer.AddItemToPlayerStorage(Slot.Item, GetPlayer.CurrentPlanet, -1)
          else
            GetPlayer.AddItemToPlayerStorage(Slot.Item, GetPlayer.DockedTo, -1);
          Slot.Item := nil;
          ShowMessageBoxGI(
              Self,
              LanguageDataConfig.GetParamByPathOrMarker('FormShop.AfterBuyHull'),
              mbgOK
          );
          if GetPlayer.CurrentPlanet <> nil then
            Destination := PtrInt(GetPlayer.CurrentPlanet)
          else
            Destination := PtrInt(GetPlayer.DockedTo);
        end;
      end
      else
      begin
        GetPlayer.SetMoney(GetPlayer.Money - Galaxy.PendingEquipmentPurchasePrice);
        TEquipment(Slot.Item).EquippedFlag := 0;
        if Slot.Item is TArtefact then
          GetPlayer.Artefacts.Add(Slot.Item)
        else
          GetPlayer.Inventory.Add(Slot.Item);
        Slot.Item := nil;
        Destination := PtrInt(GetPlayer);
      end;
      GetPlayer.ScriptItemsAct(satOnPlayerBuyEq, PurchasedItem, nil, Destination);
      GetPlayer.RefreshDerivedStats(True);
      aCalc.WaitForTurnCalculationUI;
      with Slot.SlotImage do
      begin
        SetActive(False);
        MouseEnterCallback := nil;
        MouseLeaveCallback := nil;
        LeftButtonUpCallback := nil;
      end;
      with Slot.BorderImage do
      begin
        SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderN');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      if Slot.TypeOverlayImage <> nil then
      begin
        Slot.TypeOverlayImage.Free;
        Slot.TypeOverlayImage := nil;
      end;
      if Slot.ItemIconImage <> nil then
      begin
        Slot.ItemIconImage.Free;
        Slot.ItemIconImage := nil;
      end;
      if Slot.ItemAnimation <> nil then
      begin
        Slot.ItemAnimation.Free;
        Slot.ItemAnimation := nil;
      end;
      if Slot.MicroModuleImage <> nil then
      begin
        Slot.MicroModuleImage.Free;
        Slot.MicroModuleImage := nil;
      end;
      RefreshItemInfo(nil);
      if not IsCursorImageSelected('Main') then
        SetCursorByName('Main');
      for Y := 0 to ShopGridRowCount - 1 do
        for X := 0 to ContentColumnCount - 1 do
        begin
          Slot := FindShopSlotByGridPoint(Classes.Point(X, Y));
          with Slot.BorderImage do
          begin
            if Slot.Item = nil then
              SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderN')
            else
            begin
              Cost := Slot.Item.GetConditionAdjustedCost;
              if Slot.Item is THull then
                Cost :=
                    Max(
                        1,
                        Cost
                            - GetPlayer.GetHull.CalculateResaleValue(
                                GetPlayer.GetEffectiveSkillLevel(psTrading))
                    );
              if (GetPlayer.Money < Cost)
                  or ((Slot.Item.ItemType <> t_Hull)
                      and (GetPlayer.CargoFreeSpace < Slot.Item.Weight)) then
                SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderH')
              else
                SetImagePath('GI,Bm.FormShop2.' + GiResourceSuffix + 'SlotBorderN');
            end;
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
          end;
        end;
    end;
  end;
end;

procedure TfEquipmentShop.ChooseAnimatedPreview(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  I: Integer;
  Slot: TShopSlot;
  Attempts: Integer;
begin
  if TemporaryShopSlots.IndexOf(PreviewSlot) >= 0 then
    ScheduleSlotPreviewStop(PreviewSlot);
  PreviewSlot := nil;
  Attempts := 20;
  while Attempts > 0 do
  begin
    I := RandomIntRange(0, TemporaryShopSlots.Count - 1);
    Slot := TemporaryShopSlots[I];
    if Slot.Item <> nil then
    begin
      StartSlotAnimatedPreview(Slot);
      PreviewSlot := Slot;
      Break;
    end;
    Dec(Attempts);
  end;
  if OpenPreviewTimer <> nil then
  begin
    CancelCallbackTimer(OpenPreviewTimer);
    OpenPreviewTimer := nil;
  end;
  if AnimItem then
    OpenPreviewTimer :=
        ScheduleCallbackTimer(RandomIntRange(3000, 6000), 99999, ChooseAnimatedPreview);
end;

procedure TfEquipmentShop.PreviewCycleComplete(Sender: TObjectGI);
begin
  (Sender as TgaiGI).StopAutoPlayback;
end;

procedure TfEquipmentShop.HideItemInfo(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  if ItemInfoTimer <> nil then
  begin
    CancelCallbackTimer(ItemInfoTimer);
    ItemInfoTimer := nil;
  end;
  GetByName('PII').SetActive(False);
  GetByName('InfoHull').SetActive(False);
  (GetByName('InfoText') as TLabelGI).SetText('');
  (GetByName('InfoSize') as TLabelGI).SetText('');
  (GetByName('InfoPrice') as TLabelGI).SetText('');
end;

procedure TfEquipmentShop.RefreshItemInfo(Item: TItem);
const
  DurableTypes = [0..79] - [0..7, 9, 23..25, 35..38, 42, 69..72, 74..79];
var
  Equipment: TEquipment;
  Price: WideString;
  BarWidth, CapWidth, MinimumWidth: Integer;
begin
  Equipment := Item as TEquipment;
  if Equipment = nil then
  begin
    if ItemInfoTimer <> nil then
    begin
      CancelCallbackTimer(ItemInfoTimer);
      ItemInfoTimer := nil;
    end;
    ItemInfoTimer := ScheduleCallbackTimer(100, 99999, HideItemInfo);
    MainPanel.HelpLabel.SetActive(False);
    MainPanel.SlideMessagesIn;
    if AnimItem then
      OpenPreviewTimer := ScheduleCallbackTimer(1000, 99999, ChooseAnimatedPreview);
  end
  else
  begin
    if OpenPreviewTimer <> nil then
    begin
      CancelCallbackTimer(OpenPreviewTimer);
      OpenPreviewTimer := nil;
    end;
    if TemporaryShopSlots.IndexOf(PreviewSlot) >= 0 then
      ScheduleSlotPreviewStop(PreviewSlot);
    PreviewSlot := nil;
    if ItemInfoTimer <> nil then
    begin
      CancelCallbackTimer(ItemInfoTimer);
      ItemInfoTimer := nil;
    end;
    with MainPanel.HelpLabel do
    begin
      SetActive(True);
      SetText(
          FormatText1(
              LookupLocalizedTextByKey('FormShop.BuyHelp'),
              InfoNameColorTag,
              '<Item>',
              Equipment.GetDisplayName
          )
      );
    end;
    MainPanel.SlideMessagesOut;
    if (Galaxy <> nil) and not Galaxy.Destroying and (GetPlayer <> nil) then
    begin
      if GetPlayer.CurrentPlanet <> nil then
      begin
        if Item.ScriptItem <> nil then
          TScriptItem(Item.ScriptItem)
              .RunActionCode(satOnShowingItemInfo, nil, GetPlayer.CurrentPlanet, nil, 0);
        if Item is TEquipmentWithActCode then
          RunItemConfigActionCode(Item, satOnShowingItemInfo, nil, GetPlayer.CurrentPlanet, nil, 0);
      end
      else
      begin
        if Item.ScriptItem <> nil then
          TScriptItem(Item.ScriptItem)
              .RunActionCode(satOnShowingItemInfo, nil, GetPlayer.DockedTo, nil, 0);
        if Item is TEquipmentWithActCode then
          RunItemConfigActionCode(Item, satOnShowingItemInfo, nil, GetPlayer.DockedTo, nil, 0);
      end;
    end;
    if Item.ItemType = t_Hull then
    begin
      RefreshHullInfo(
          Self,
          Item as THull,
          Equipment.GetInfoText('<color=255,240,100>', nil),
          False
      );
      ItemInfoWindow.SetActive(False);
    end
    else
    begin
      ItemInfoWindow.SetActive(True);
      GetByName('InfoHull').SetActive(False);
      with GetByName('InfoImage') as TImageGI do
      begin
        SetImagePath('GI,' + GetShopItemIconName(Equipment) + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
      end;
      (GetByName('InfoName') as TLabelGI).SetText('');
      (GetByName('InfoName') as TLabelGI)
          .SetText(WrapTextInColor(Equipment.GetDisplayName, InfoNameColorTag));
      (GetByName('InfoText') as TLabelGI)
          .SetText(Equipment.GetInfoText('<color=255,240,100>', nil));
      (GetByName('InfoSize') as TLabelGI).SetText(IntToWideString(Equipment.Weight));
      Price := IntToWideString(Equipment.GetConditionAdjustedCost);
      if Equipment.GetConditionAdjustedCost < Equipment.Cost then
        Price := WrapTextInColor(Price, '<color=255,0,0>');
      (GetByName('InfoPrice') as TLabelGI).SetText(Price);
      with GetByName('EmRace') as TImageGI do
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
        BarWidth := Min(192, Max(32, Round(64 / Max(0.1, Equipment.GetFragilityFactor([])))));
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
          Parent.Parent.SetSize(Classes.Point(2 * CapWidth + BarWidth, Parent.Parent.ClientSize.Y));
          Parent.SetSize(Classes.Point(BarWidth + 2, Parent.Parent.ClientSize.Y));
          if Equipment.ItemType = t_Hull then
            SetPosition(
                Classes.Point(
                    Round((Equipment as THull).HullPoints / (Equipment as THull).Weight * BarWidth)
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
          GetByName('InfoName') as TLabelGI,
          GetByName('InfoText') as TLabelGI,
          True,
          True,
          MinimumWidth
      );
      GetByName('InfoSize')
          .SetPosition(
              Classes.Point(
                  ShipScreen.ItemSizeLabelPosition.X,
                  ItemInfoWindow.ClientSize.Y + ShipScreen.ItemSizeLabelPosition.Y
              ));
      GetByName('InfoPrice')
          .SetPosition(
              Classes.Point(
                  ShipScreen.ItemPriceLabelPosition.X,
                  ItemInfoWindow.ClientSize.Y + ShipScreen.ItemPriceLabelPosition.Y
              ));
      GetByName('EmRace')
          .SetPosition(
              Classes.Point(
                  ItemInfoWindow.ClientSize.X + ShipScreen.ItemRaceImagePosition.X,
                  ItemInfoWindow.ClientSize.Y + ShipScreen.ItemRaceImagePosition.Y
              ));
      if DynamicTipsPos then
        ItemInfoWindow.SetPosition(
            Classes.Point(ItemInfoAnchor.X - ItemInfoWindow.ClientSize.X div 2, ItemInfoAnchor.Y)
        )
      else
        ItemInfoWindow.SetPosition(Classes.Point(10, 10));
    end;
  end;
end;

procedure TfEquipmentShop.BuildHullSlotOverlays(
    Parent: TObjectGI;
    Hull: THull;
    OffsetX, OffsetY: Integer
);
var
  Root: TObjectGI;
  I: Integer;
  procedure AddOverlay(
      Name: WideString
  ); // @addr $7E1EF0 @ida "void __usercall $name(unsigned __int16 *Name@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x7e2075,0x7e208e,0x7e20a9,0x7e20c4,0x7e20df,0x7e20fa,0x7e2144,0x7e2165,0x7e217e,0x7e2197,0x7e21b0,0x7e21c9,0x7e21e2,0x7e21fb" @note "Nested in BuildHullSlotOverlays; captures root, parent and offsets."
  var
    Control: TObjectGI;
    Path: WideString;
    Graph: TGraphBufGI;
  begin
    Control := Root.FindByNameRecursive(Name);
    if Control <> nil then
    begin
      Graph := TGraphBufGI.Create(Parent, False);
      Graph.SetPositionModeW(True);
      Graph.SetPosition(
          Classes.Point(Control.LocalPosition.X + OffsetX, Control.LocalPosition.Y + OffsetY)
      );
      Graph.SetSize(Control.ClientSize);
      Graph.SourceHasPerPixelAlpha := True;
      Path := (Control as TImageGI).GetImagePath;
      if CountDelimitedPartsW(Path, ',') = 2 then
        Path := ExtractDelimitedPartW(Path, 1, ',');
      LoadGiByPathIntoGraphBuf(Path, Graph.GraphBuf);
    end;
  end;
begin
  Root := GetByName('InfoHull');
  if Hull.GetSlotCount(sskAfterburner) >= 1 then
    AddOverlay('InfoHull_Forsage');
  if Hull.GetSlotCount(sskWeapon) < 1 then
    AddOverlay('InfoHull_W1');
  if Hull.GetSlotCount(sskWeapon) < 2 then
    AddOverlay('InfoHull_W2');
  if Hull.GetSlotCount(sskWeapon) < 3 then
    AddOverlay('InfoHull_W3');
  if Hull.GetSlotCount(sskWeapon) < 4 then
    AddOverlay('InfoHull_W4');
  if Hull.GetSlotCount(sskWeapon) < 5 then
    AddOverlay('InfoHull_W5');
  for I := 1 to DefaultHullSlotCounts[Ord(sskArtefact)] do
    if Hull.GetSlotCount(sskArtefact) < I then
      AddOverlay('InfoHull_A' + IntToWideString(I));
  if Hull.GetSlotCount(sskEngine) < 1 then
    AddOverlay('InfoHull_Engine');
  if Hull.GetSlotCount(sskFuelTanks) < 1 then
    AddOverlay('InfoHull_FuelTanks');
  if Hull.GetSlotCount(sskScanner) < 1 then
    AddOverlay('InfoHull_Scaner');
  if Hull.GetSlotCount(sskRadar) < 1 then
    AddOverlay('InfoHull_Radar');
  if Hull.GetSlotCount(sskRepairRobot) < 1 then
    AddOverlay('InfoHull_RepairRobot');
  if Hull.GetSlotCount(sskCargoHook) < 1 then
    AddOverlay('InfoHull_CargoHook');
  if Hull.GetSlotCount(sskDefGenerator) < 1 then
    AddOverlay('InfoHull_DefGenerator');
end;

var
  // Native managed-string initialization pairs at $7E3C0C, $7E3C04 and $7E3BFC.
  ShopDominatorImagePrefixes: array[0..2] of WideString = ('B', 'K', 'T'); // @addr $87CD18
procedure TfEquipmentShop.RefreshHullInfo(
    Target: TMessageLoopGI;
    Hull: THull;
    Text: WideString;
    SuppressImage: Boolean
);
var
  Window: TWindowGI;
  TextLabel: TLabelGI;
  Control: TObjectGI;
  I: Integer;
  PreviewPath, SeriesName: WideString;
  HullKind, DisplayKind: Byte;
  Series: TDominatorSeries;
  BarWidth, CapWidth, MinimumWidth: Integer;
  UnusedNativeLocal:
      array[0..7] of
          Byte; { Eight unreferenced frame bytes precede the managed temporaries; original local type is unknown. }
begin
  Window := Target.GetByName('InfoHull') as TWindowGI;
  TextLabel := Target.GetByName('InfoHullText') as TLabelGI;
  Window.SetActive(True);
  (Target.GetByName('InfoHullName') as TLabelGI)
      .SetText(WrapTextInColor(Hull.GetDisplayName, InfoNameColorTag));
  SeriesName := Hull.GetSeriesName;
  if SeriesName <> '' then
    SeriesName := #13#10 + WrapTextInColor(SeriesName, InfoHullSeriesColorTag);
  (Target.GetByName('InfoHullName') as TLabelGI)
      .SetText((Target.GetByName('InfoHullName') as TLabelGI).GetText + SeriesName);
  TextLabel.SetText(Text);
  Target.GetByName('InfoHull_Forsage').SetActive(Hull.GetSlotCount(sskAfterburner) >= 1);
  Target.GetByName('InfoHull_W1').SetActive(not (Hull.GetSlotCount(sskWeapon) >= 1));
  Target.GetByName('InfoHull_W2').SetActive(not (Hull.GetSlotCount(sskWeapon) >= 2));
  Target.GetByName('InfoHull_W3').SetActive(not (Hull.GetSlotCount(sskWeapon) >= 3));
  Target.GetByName('InfoHull_W4').SetActive(not (Hull.GetSlotCount(sskWeapon) >= 4));
  Target.GetByName('InfoHull_W5').SetActive(not (Hull.GetSlotCount(sskWeapon) >= 5));
  for I := 1 to DefaultHullSlotCounts[Ord(sskArtefact)] do
  begin
    Control := Target.FindControlByPath('InfoHull_A' + IntToWideString(I));
    if Control <> nil then
      Control.SetActive(not (Hull.GetSlotCount(sskArtefact) >= I));
  end;
  Target.GetByName('InfoHull_Engine').SetActive(not (Hull.GetSlotCount(sskEngine) >= 1));
  Target.GetByName('InfoHull_FuelTanks').SetActive(not (Hull.GetSlotCount(sskFuelTanks) >= 1));
  Target.GetByName('InfoHull_Scaner').SetActive(not (Hull.GetSlotCount(sskScanner) >= 1));
  Target.GetByName('InfoHull_Radar').SetActive(not (Hull.GetSlotCount(sskRadar) >= 1));
  Target.GetByName('InfoHull_RepairRobot').SetActive(not (Hull.GetSlotCount(sskRepairRobot) >= 1));
  Target.GetByName('InfoHull_CargoHook').SetActive(not (Hull.GetSlotCount(sskCargoHook) >= 1));
  Target
      .GetByName('InfoHull_DefGenerator')
      .SetActive(not (Hull.GetSlotCount(sskDefGenerator) >= 1));
  DisplayKind := 0;
  Series := dsBlazer;
  HullKind := Hull.HullType;
  if (Hull.OwnerShip <> nil)
      and (GetPlayer = Hull.OwnerShip)
      and GetPlayer.ChameleonActive
      and (GetPlayer.ChameleonVisualType in [0..7])
      and (GetPlayer.ChameleonVisualType <> 0) then
  begin
    HullKind := 6;
    DisplayKind := GetPlayer.ChameleonVisualType;
    Series := GetPlayer.ChameleonSeries;
  end;
  if (Hull.OwnerShip <> nil) and (TObject(Hull.OwnerShip) is TKling) then
  begin
    HullKind := 6;
    DisplayKind := Byte((TObject(Hull.OwnerShip) as TKling).KlingType);
    Series := (TObject(Hull.OwnerShip) as TKling).DominatorSeries;
  end;
  if not SuppressImage then
    with Target.GetByName('InfoHullImage') as TImageGI do
    begin
      if HullKind = 6 then
      begin
        SetImagePath('GraphBuf');
        PreviewPath := '';
        if DisplayKind <> 0 then
          PreviewPath :=
              GameDataConfig.GetParamByPathOrMarker(
                  'SE.Ship.'
                      + DominatorSeriesNames[Ord(Series)]
                      + '.'
                      + ShopDominatorImagePrefixes[Ord(Series)]
                      + IntToWideString(DisplayKind)
                      + '.'
                      + GiResourceSuffix
                      + 'ImageP'
              );
        if PreviewPath <> '' then
          with GraphBufControl do
          begin
            SourceHasPerPixelAlpha := True;
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(PreviewPath, 1, ','), GraphBuf);
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
          end
        else
          with GraphBufControl do
          begin
            SourceHasPerPixelAlpha := True;
            if DisplayKind = 0 then
              case Series of
                dsTerron: LoadGiByPathIntoGraphBuf('Bm.Ruins.Terroni', GraphBuf);
                dsKeller: LoadGiByPathIntoGraphBuf('Bm.Ruins.Kelleri', GraphBuf);
                dsBlazer: LoadGiByPathIntoGraphBuf('Bm.Ruins.Blazeri', GraphBuf);
              end;
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
          end;
      end
      else
        SetImagePath('GI,' + GetShopItemIconName(Hull) + 's');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
    end;
  (Target.GetByName('InfoHullSize') as TLabelGI).SetText(IntToWideString(Hull.Weight));
  (Target.GetByName('InfoHullPrice') as TLabelGI)
      .SetText(IntToWideString(Hull.GetConditionAdjustedCost));
  with Target.GetByName('InfoHullEmRace') as TImageGI do
  begin
    SetImagePath(GetFactionEmblemPath(Hull.GetOwnerConfigName));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  BarWidth := Round(Sqrt(Hull.Weight / HullBaseSize / Max(0.1, Hull.GetFragilityFactor([]))) * 64);
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
  with Target.GetByName('InfoHullDurable') as TImageGI do
  begin
    Parent.Parent.SetSize(Classes.Point(2 * CapWidth + BarWidth, Parent.Parent.ClientSize.Y));
    Parent.SetSize(Classes.Point(BarWidth + 2, Parent.Parent.ClientSize.Y));
    SetPosition(
        Classes.Point(
            Round(Hull.HullPoints / Hull.Weight * BarWidth) - (GetContentSize.X - 5),
            LocalPosition.Y
        )
    );
  end;
  with Target.GetByName('InfoHullDurableRight') as TImageGI do
  begin
    SetPosition(Classes.Point(BarWidth + CapWidth - GetContentSize.X, LocalPosition.Y));
    Parent.SetPosition(Classes.Point(CapWidth, Parent.LocalPosition.Y));
    Parent.SetSize(Classes.Point(BarWidth + CapWidth, Parent.ClientSize.Y));
  end;
  with Target.GetByName('InfoHullDurableBack') as TImageGI do
  begin
    SetPosition(Classes.Point(BarWidth + 1 - GetContentSize.X, LocalPosition.Y));
    Parent.SetSize(Classes.Point(BarWidth + CapWidth, Parent.ClientSize.Y));
  end;
  ShipScreen.LayoutItemInfo(
      Window,
      Target.GetByName('InfoHullName') as TLabelGI,
      TextLabel,
      False,
      True,
      MinimumWidth
  );
  Target
      .GetByName('InfoHullSize')
      .SetPosition(Classes.Point(HullSizeOffset.X, Window.ClientSize.Y + HullSizeOffset.Y));
  Target
      .GetByName('InfoHullPrice')
      .SetPosition(Classes.Point(HullPriceOffset.X, Window.ClientSize.Y + HullPriceOffset.Y));
  Target
      .GetByName('InfoHullEmRace')
      .SetPosition(
          Classes.Point(
              Window.ClientSize.X + HullRaceOffset.X,
              Window.ClientSize.Y + HullRaceOffset.Y
          ));
  if DynamicTipsPos then
    Window
        .SetPosition(Classes.Point(ItemInfoAnchor.X - Window.ClientSize.X div 2, ItemInfoAnchor.Y))
  else
    Window.SetPosition(Classes.Point(10, 10));
end;

procedure TfEquipmentShop.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if (Delta = WHEEL_DELTA) and not (GetByName('Left') as TGraphButtonGI).Disabled then
  begin
    ScrollLeft(nil);
    RefreshItemInfo(nil);
  end
  else if (Delta = -WHEEL_DELTA) and not (GetByName('Right') as TGraphButtonGI).Disabled then
  begin
    ScrollRight(nil);
    RefreshItemInfo(nil);
  end;
end;

procedure TfEquipmentShop.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL)
      and not IsVirtualKeyDown(VK_SHIFT)
      and not IsVirtualKeyDown(VK_MENU)
      and (ExitCode = 0) then
  begin
    if Key = Ord('S') then
      ShipClicked(nil)
    else if ((Key = VK_LEFT) or (Key = VK_UP))
        and not (GetByName('Left') as TGraphButtonGI).Disabled then
    begin
      ScrollLeft(nil);
      RefreshItemInfo(nil);
    end
    else if ((Key = VK_RIGHT) or (Key = VK_DOWN))
        and not (GetByName('Right') as TGraphButtonGI).Disabled then
    begin
      ScrollRight(nil);
      RefreshItemInfo(nil);
    end
    else if Key = VK_SPACE then
    begin
      if GetByName('PM_EndTurn').Active then
        EndTurnClicked(nil);
    end
    else
    begin
      MainPanel.ProcessKeyDown(Key);
      PlanetPanel.ProcessKeyDown(Key);
      StationPanel.ProcessKeyDown(Key);
    end;
  end;
end;

procedure TfEquipmentShop.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
  if MainPanel.NavigationLocked then
    Exit;
  if ExitScreenLoop then
    Exit;
  if TurnCalculationPhase
      in [tcpIdle, tcpGalaxyFinished, tcpPlayerStarFinished, tcpPlayerStarPrepared] then
  begin
    aCalc.WaitForTurnCalculationUI;
    ExecuteGameplayUiCode(Block, Key);
    aCalc.WaitForTurnCalculationUI;
  end;
end;

procedure TfEquipmentShop.SelectMusic;
begin
  if (ActiveLoadPanel <> nil) and (ActiveLoadPanel.GetShutterDirection = -1) then
    Exit;
  if not MusicInPlanetEnabled then
  begin
    MusicManager.RequestFadeOut;
    Exit;
  end;
  if GetPlayer.IsOnPlanet then
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
  end;
end;

procedure LinkRecoveredTypes;
begin
  TArtefact.ClassName;
  TEquipment.ClassName;
  TEquipmentWithActCode.ClassName;
  TGraphButtonGI.ClassName;
  THull.ClassName;
  TImageGI.ClassName;
  TKling.ClassName;
  TLabelGI.ClassName;
  TMicroModule.ClassName;
  TPanelGI.ClassName;
  TPanelScrollBarGI.ClassName;
  TRuins.ClassName;
  TWeapon.ClassName;
  TWindowGI.ClassName;
  TgaiGI.ClassName;
end;
end.
