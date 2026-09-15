{$EXCESSPRECISION OFF}
unit fLoadQuest;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  RTLFileSystem,
  GI_Image,
  GI_MessageLoop,
  Types,
  fPanelLoad;
type
  TfLoadQuest = class;
  TfLoadQuestSlot = packed record
    Name: WideString;
    Title: WideString;
    Description: WideString;
    Image: WideString;
    Genre: WideString;
    Length: Integer;
    QuestId: Integer;
    BackgroundImage: TImageGI;
    RequiredAccess: Integer;
    AlternateGroup: Boolean;
    Gap25: array[0..2] of Byte;
    Difficulty: Integer;
  end;
  TfLoadQuest = class(TMessageLoopGI)
    LoadPanel: TfPanelLoad;
    Entries: array of TfLoadQuestSlot;
    SelectedIndex: Integer;
    HoveredIndex: Integer;
    CompletionData: array of Integer;
    Category: Integer;
    AccessLevel: Integer;
    KeyHistory: WideString;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    procedure ReturnToMenu(Sender: TObjectGI);
    procedure QuestListKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
    function InsertEntryByAccess(RequiredAccess: Integer): Integer;
    procedure RebuildQuestList;
    procedure InitializeQuestRow(Row: TObjectGI);
    procedure SelectQuest(Index: Integer);
    procedure UpdateQuestRow(Index: Integer);
    procedure QuestRowMouseEnter(Sender: TObjectGI);
    procedure QuestRowMouseLeave(Sender: TObjectGI);
    procedure QuestRowMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure QuestRowDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SelectCategory(Sender: TObjectGI);
    procedure StartSelectedQuest(Sender: TObjectGI);
    procedure ShowSelectedQuestDetails;
    procedure LoadCompletionData;
    procedure SaveCompletionData;
    procedure RecordCompletion(QuestId: Integer; Value: Integer; Status: Integer);
    function CalculateAccessLevel: Integer;
    function GetCompletionCounts: TPoint;
    function GetCompletionSummary: WideString;
  end;
var
  QuestNameColor: Cardinal;
procedure LinkRecoveredTypes;
implementation
uses
  Classes,
  EC_BlockPar,
  EC_Buf,
  EC_Cache,
  EC_CacheBuf,
  EC_File,
  EC_Str,
  GI_GraphBuf,
  GI_GraphButton,
  GI_Label,
  GI_Main,
  GI_Panel,
  GI_PanelScrollBar,
  GI_ScrollBar,
  GR_GraphBuf,
  GR_Main,
  Globals,
  GlobalsV,
  Math,
  SysUtils,
  TextQuest,
  Windows,
  aConst,
  aGalaxy,
  aMyFunction;
constructor TfLoadQuest.Create;
begin
  inherited Create;
  SelectedIndex := -1;
  Category := 0;
  LoadPanel := TfPanelLoad.Create;
end;
destructor TfLoadQuest.Destroy;
begin
  if LoadPanel <> nil then
  begin
    LoadPanel.Free;
    LoadPanel := nil;
  end;
  inherited Destroy;
end;
procedure TfLoadQuest.InitializeLayout;
var
  Root, Panel: TObjectGI;
begin
  inherited InitializeLayout;
  LoadPanel.InitializeLayout(Self);
  AppendLogTextThreadSafe('fLoadQuest... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Root := GetByName('');
  Root.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  Root.FindByNameRecursive('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  Panel := Root.FindByNameRecursive('MainPanel');
  if ExtraScreenHeight < 0 then
    Panel.SetPosition(
        Classes.Point(
            ExtraScreenWidth div 2 + Panel.LocalPosition.X,
            (GameScreenHeight - Panel.ClientSize.Y) div 2
        )
    )
  else
    Panel.SetPosition(
        Classes.Point(
            ExtraScreenWidth div 2 + Panel.LocalPosition.X,
            ExtraScreenHeight div 2 + Panel.LocalPosition.Y
        )
    );
  AppendLogLineThreadSafe('ok');
  GetByName('MainPanel').KeyDownCallback := QuestListKeyDown;
  (GetByName('ButClose') as TGraphButtonGI).UpCallback := ReturnToMenu;
  (GetByName('ButCancel') as TGraphButtonGI).UpCallback := ReturnToMenu;
  (GetByName('ButStart') as TGraphButtonGI).UpCallback := StartSelectedQuest;
  with GetByName('ButGroup0') as TGraphButtonGI do
  begin
    UpCallback := SelectCategory;
    DownCallback := SelectCategory;
  end;
  with GetByName('ButGroup1') as TGraphButtonGI do
  begin
    UpCallback := SelectCategory;
    DownCallback := SelectCategory;
  end;
  with GetByName('ButGroup2') as TGraphButtonGI do
  begin
    UpCallback := SelectCategory;
    DownCallback := SelectCategory;
  end;
  QuestNameColor := GetStyleColorGI('LoadQuest.QuestsNameColor', 165, 183, 143);
end;
procedure TfLoadQuest.OnOpen;
begin
  inherited OnOpen;
  LoadPanel.OnOpen;
  KeyHistory := '';
  if PreviousScreenId <> screenPlanetQuest then
    if AuxRenderBuffer.GetPixels = nil then
      CaptureScreenBackground(True, 0);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  with GetByName('ButGroup0') as TGraphButtonGI do
    SetDown(Category = 0);
  with GetByName('ButGroup1') as TGraphButtonGI do
    SetDown(Category = 1);
  with GetByName('ButGroup2') as TGraphButtonGI do
    SetDown(Category = 2);
  RebuildQuestList;
  SelectQuest(0);
end;
procedure TfLoadQuest.OnClose;
begin
  Entries := nil;
  if RequestedScreenId <> screenPlanetQuest then
    AuxRenderBuffer.Clear;
  LoadPanel.OnClose;
  inherited OnClose;
end;
procedure TfLoadQuest.ReturnToMenu(Sender: TObjectGI);
begin
  RequestedScreenId := screenMainMenu;
  RequestClose(1);
end;
procedure TfLoadQuest.QuestListKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
var
  CaptureKey: Boolean;
  I, QuestId: Integer;
begin
  CaptureKey := False;
  if IsVirtualKeyDown(VK_CONTROL) then
    if IsVirtualKeyDown(VK_SHIFT) then
    begin
      KeyHistory := KeyHistory + WideChar(VirtualKey);
      CaptureKey := True;
    end;
  if CaptureKey then
    if FindTextOffsetW(KeyHistory, 'WIN') >= 0 then
    begin
      KeyHistory := '';
      if (SelectedIndex >= 0) and (High(Entries) >= SelectedIndex) then
        if Entries[SelectedIndex].QuestId >= 0 then
        begin
          LoadCompletionData;
          if (Entries[SelectedIndex].QuestId >= 0) and (Entries[SelectedIndex].QuestId < 10000) then
          begin
            QuestId := Entries[SelectedIndex].QuestId;
            if (QuestId < 0)
                or ((High(CompletionData) + 1) div 2 <= QuestId)
                or (CompletionData[QuestId * 2 + 1] = 0) then
            begin
              RecordCompletion(QuestId, 0, 1);
              SaveCompletionData;
              RebuildQuestList;
            end;
          end;
        end;
    end;
  if VirtualKey = VK_ESCAPE then
    ReturnToMenu(Sender)
  else if VirtualKey = Ord('Q') then
    ReturnToMenu(Sender)
  else if VirtualKey = VK_PRIOR then
  begin
    with GetByName('PanelSlot') as TPanelScrollBarGI do
      if VerticalScrollBar.Active then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.LargeChange);
  end
  else if VirtualKey = VK_NEXT then
  begin
    with GetByName('PanelSlot') as TPanelScrollBarGI do
      if VerticalScrollBar.Active then
        VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.LargeChange);
  end
  else if VirtualKey = VK_HOME then
  begin
    if High(Entries) + 1 > 0 then
      if Entries[0].RequiredAccess <= AccessLevel then
        SelectQuest(0);
  end
  else if VirtualKey = VK_END then
  begin
    for I := High(Entries) downto 0 do
      if Entries[I].RequiredAccess <= AccessLevel then
      begin
        SelectQuest(I);
        Break;
      end;
  end
  else if VirtualKey = VK_UP then
  begin
    QuestRowMouseLeave(nil);
    if SelectedIndex > 0 then
      SelectQuest(SelectedIndex - 1)
    else if High(Entries) + 1 > 0 then
      if Entries[0].RequiredAccess <= AccessLevel then
        SelectQuest(0);
  end
  else if VirtualKey = VK_DOWN then
  begin
    QuestRowMouseLeave(nil);
    if SelectedIndex >= 0 then
    begin
      if High(Entries) > SelectedIndex then
        if Entries[SelectedIndex + 1].RequiredAccess <= AccessLevel then
          SelectQuest(SelectedIndex + 1);
    end
    else if High(Entries) + 1 > 0 then
      if Entries[0].RequiredAccess <= AccessLevel then
        SelectQuest(0);
  end
  else if VirtualKey = VK_RETURN then
    StartSelectedQuest(nil)
  else if VirtualKey = VK_TAB then
  begin
    QuestRowMouseLeave(nil);
    if Category = 0 then
      SelectCategory(GetByName('ButGroup1'))
    else if Category = 1 then
      SelectCategory(GetByName('ButGroup2'))
    else if Category = 2 then
      SelectCategory(GetByName('ButGroup0'));
  end;
end;
procedure TfLoadQuest.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
var
  Panel: TPanelScrollBarGI;
  Bounds: TRect;
begin
  Bounds := GetByName('MessageWindow').HitTestBounds;
  with Bounds do
    if (Point.X >= Left) and (Point.X < Right) and (Point.Y >= Top) and (Point.Y < Bottom) then
      Panel := GetByName('MessageWindow') as TPanelScrollBarGI
    else
      Panel := GetByName('PanelSlot') as TPanelScrollBarGI;
  if Delta = WHEEL_DELTA then
  begin
    if Panel.VerticalScrollBar.Active then
      Panel.VerticalScrollBar.SetPosition(
          Panel.VerticalScrollBar.Position - Panel.VerticalScrollBar.SmallChange
      );
    PostMouseMoveMessage;
  end
  else if Delta = -WHEEL_DELTA then
  begin
    if Panel.VerticalScrollBar.Active then
      Panel.VerticalScrollBar.SetPosition(
          Panel.VerticalScrollBar.Position + Panel.VerticalScrollBar.SmallChange
      );
    PostMouseMoveMessage;
  end;
end;
function TfLoadQuest.InsertEntryByAccess(RequiredAccess: Integer): Integer;
var
  Index, I: Integer;
begin
  Index := 0;
  while (High(Entries) >= Index) and (Entries[Index].RequiredAccess <= RequiredAccess) do
    Inc(Index);
  SetLength(Entries, High(Entries) + 1 + 1);
  for I := High(Entries) downto Index + 1 do
    Entries[I] := Entries[I - 1];
  Entries[Index].RequiredAccess := RequiredAccess;
  Result := Index;
end;
procedure TfLoadQuest.RebuildQuestList;
var
  I, Index, QuestIdAndTop, Count: Integer;
  Panel: TPanelScrollBarGI;
  Row: TPanelGI;
  Alternate: Boolean;
  List, Entry: TBlockParEC;
  Name: WideString;
begin
  Panel := GetByName('PanelSlot') as TPanelScrollBarGI;
  Panel.FreeOwnedChildren;
  LoadCompletionData;
  QuestIdAndTop := 0;
  Entries := nil;
  if (Category = 0) or (Category = 1) then
  begin
    List := LanguageDataConfig.GetBlockByPath('PlanetQuest.List');
    Count := List.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Name := List.GetBlockNameByIndex(I);
      Entry := List.GetBlockByIndex(I);
      QuestIdAndTop := -1;
      if IsIntegerTextW(Name) then
        QuestIdAndTop := StrToInt(AnsiString(Name));
      if Entry.CountParams('Group') > 0 then
        if ExtractSignedDigitsToIntW(Entry.GetParam('Group')) = Category then
        begin
          Index := InsertEntryByAccess(ExtractDigitsToIntW(Entry.GetParam('Access')));
          Entries[Index].Name := Name;
          Entries[Index].Title := Entry.GetParam('Name');
          Entries[Index].Description :=
              LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuest').GetParam(Name);
          Entries[Index].QuestId := QuestIdAndTop;
          Entries[Index].Image := Entry.GetParamOrMarker('Image');
          Entries[Index].Genre := Entry.GetParamOrMarker('Genre');
          Entries[Index].Length := ExtractDigitsToIntW(Entry.GetParamOrMarker('Length'));
          Entries[Index].Difficulty := ExtractDigitsToIntW(Entry.GetParamOrMarker('Dif'));
        end;
    end;
  end
  else
  begin
    List := LanguageDataConfig.GetBlockByPath('PlanetQuest.List');
    Count := List.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Name := List.GetBlockNameByIndex(I);
      Entry := List.GetBlockByIndex(I);
      QuestIdAndTop := -1;
      if IsIntegerTextW(Name) then
        QuestIdAndTop := StrToInt(AnsiString(Name));
      if Entry.CountParams('Group') > 0 then
        if ExtractSignedDigitsToIntW(Entry.GetParam('Group')) = Category then
        begin
          Index := InsertEntryByAccess(0);
          Entries[Index].Name := Name;
          Entries[Index].Title := Entry.GetParam('Name');
          Entries[Index].Description :=
              LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuest').GetParam(Name);
          Entries[Index].QuestId := QuestIdAndTop;
          Entries[Index].Image := Entry.GetParamOrMarker('Image');
          Entries[Index].Genre := Entry.GetParamOrMarker('Genre');
          Entries[Index].Length := ExtractDigitsToIntW(Entry.GetParamOrMarker('Length'));
          Entries[Index].Difficulty := ExtractDigitsToIntW(Entry.GetParamOrMarker('Dif'));
        end;
    end;
  end;

  AccessLevel := CalculateAccessLevel;

  Alternate := True;
  Index := -100;
  // Native code reuses the final parsed quest ID as the first row's top.
  for I := 0 to High(Entries) do
  begin
    if I <> 0 then
      Inc(QuestIdAndTop, GiScalePixels(5));
    if Entries[I].RequiredAccess <> Index then
    begin
      Alternate := not Alternate;
      Index := Entries[I].RequiredAccess;
    end;
    Entries[I].AlternateGroup := Alternate;
    Row := TPanelGI.Create(Panel);
    Row.UserValue := I;
    Row.SetPosition(Classes.Point(0, QuestIdAndTop));
    InitializeQuestRow(Row);
    Inc(QuestIdAndTop, Row.ClientSize.Y);
    Row.SetPositionModeW(True);
    Panel.VerticalScrollBar.SetSmallChange(GiScalePixels(5) + Row.ClientSize.Y);
    UpdateQuestRow(I);
  end;
  Panel.UpdateScrollRanges;
  Panel.VerticalScrollBar.SetActive(Panel.ClientSize.Y < QuestIdAndTop);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  I := Panel.VerticalScrollBar.Position;
  Panel.VerticalScrollBar.SetPosition(I - 1);
  Panel.VerticalScrollBar.SetPosition(I);
  if (SelectedIndex < 0) or (High(Entries) + 1 <= SelectedIndex) then
    SelectedIndex := -1;
  SelectQuest(SelectedIndex);
  Panel.Invalidate;
end;
procedure TfLoadQuest.InitializeQuestRow(Row: TObjectGI);
var
  Index, Status, TitleRight, CompletionIndex, GenreRight: Integer;
  Background, LengthImage, CompletionImage: TImageGI;
  TitleLabel, GenreLabel: TLabelGI;
begin
  Index := Row.UserValue;
  Row.MouseEnterCallback := QuestRowMouseEnter;
  Row.MouseLeaveCallback := QuestRowMouseLeave;
  Row.LeftButtonDownCallback := QuestRowMouseDown;
  Row.LeftButtonDoubleClickCallback := QuestRowDoubleClick;
  Entries[Index].BackgroundImage := TImageGI.Create(Row);
  Background := Entries[Index].BackgroundImage;
  Background.SetPosition(Classes.Point(0, 0));
  Background.SetDepth(10);
  if Entries[Index].RequiredAccess <= AccessLevel then
  begin
    if not Entries[Index].AlternateGroup then
      Background.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotNormal')
    else
      Background.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotNormal2');
  end
  else
    Background.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotDisabled');
  Background.SetSize(Background.GetContentSize);
  Row.SetSize(Background.ClientSize);
  Background.SetActive(True);
  TitleRight := GiScalePixels(262);
  if (Entries[Index].QuestId >= 0) and (Entries[Index].QuestId < 10000) then
  begin
    LengthImage := TImageGI.Create(Row);
    LengthImage.SetDepth(9);
    if Entries[Index].RequiredAccess <= AccessLevel then
      LengthImage.SetImagePath(
          'GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'D' + IntToStr(Entries[Index].Length + 1)
      )
    else
      LengthImage.SetImagePath(
          'GI,Bm.FormLoadQuest.'
              + GiResourceSuffix
              + 'D'
              + IntToStr(Entries[Index].Length + 1)
              + 'D'
      );
    LengthImage.SetSize(LengthImage.GetContentSize);
    LengthImage.SetPosition(
        Classes.Point(
            TitleRight - LengthImage.ClientSize.X,
            Row.ClientSize.Y div 2 - LengthImage.ClientSize.Y div 2
        )
    );
    LengthImage.SetActive(True);
    TitleRight := TitleRight - LengthImage.ClientSize.X - 1;
  end;
  Status := Entries[Index].QuestId;
  CompletionIndex := Status;
  GenreRight := Row.ClientSize.X;
  if CompletionIndex >= 0 then
    if (High(CompletionData) + 1) div 2 > CompletionIndex then
    begin
      Status := CompletionData[CompletionIndex * 2 + 1];
      if Status <> 0 then
      begin
        CompletionImage := TImageGI.Create(Row);
        CompletionImage.SetPosition(Classes.Point(0, 0));
        CompletionImage.SetDepth(9);
        CompletionImage.SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + '_33');
        CompletionImage.SetSize(CompletionImage.GetContentSize);
        CompletionImage.SetPosition(
            Classes.Point(
                Row.ClientSize.X - CompletionImage.ClientSize.X - GiScalePixels(10),
                Row.ClientSize.Y div 2 - CompletionImage.ClientSize.Y div 2
            )
        );
        GenreRight := CompletionImage.LocalPosition.X;
        CompletionImage.SetActive(True);
      end;
    end;
  TitleLabel := TLabelGI.Create(Row);
  if GiResourceVariant = 1 then
  begin
    TitleLabel.SetPosition(Classes.Point(11, 0));
    TitleLabel.SetSize(Classes.Point(TitleRight - TitleLabel.LocalPosition.X, Row.ClientSize.Y));
  end
  else
  begin
    TitleLabel.SetPosition(Classes.Point(14, 0));
    TitleLabel.SetSize(Classes.Point(TitleRight - TitleLabel.LocalPosition.X, Row.ClientSize.Y));
  end;
  TitleLabel.SetDepth(7);
  TitleLabel.SetFontName(NormalFontName);
  TitleLabel.SetTextAlignX(taxLeft);
  TitleLabel.SetTextAlignY(tayCenterEx);
  TitleLabel.SetText(Entries[Index].Title);
  if Entries[Index].RequiredAccess <= AccessLevel then
    TitleLabel.SetTextColor(QuestNameColor)
  else
    TitleLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes(112, 112, 112));
  GenreLabel := TLabelGI.Create(Row);
  if GiResourceVariant = 1 then
  begin
    GenreLabel.SetPosition(Classes.Point(209, 0));
    GenreLabel.SetSize(Classes.Point(GenreRight - 209, Row.ClientSize.Y - 2));
  end
  else
  begin
    GenreLabel.SetPosition(Classes.Point(267, 0));
    GenreLabel.SetSize(Classes.Point(GenreRight - 267, Row.ClientSize.Y - 2));
  end;
  GenreLabel.SetDepth(7);
  GenreLabel.SetFontName(SmallFontName);
  GenreLabel.SetTextAlignX(taxLeft);
  GenreLabel.SetTextAlignY(tayCenter);
  GenreLabel.SetWordWrapEnabled(True);
  GenreLabel.SetText(TrimWideString(Entries[Index].Genre));
  if Entries[Index].RequiredAccess <= AccessLevel then
    GenreLabel.SetTextColor(QuestNameColor)
  else
    GenreLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes(112, 112, 112));
end;
procedure TfLoadQuest.SelectQuest(Index: Integer);
var
  Previous: Integer;
begin
  Previous := SelectedIndex;
  SelectedIndex := Index;
  if High(Entries) + 1 <= SelectedIndex then
    SelectedIndex := -1;
  if SelectedIndex >= 0 then
    if Entries[SelectedIndex].RequiredAccess > AccessLevel then
      SelectedIndex := -1;
  UpdateQuestRow(Previous);
  UpdateQuestRow(SelectedIndex);
  if (Index < 0) or (High(Entries) < Index) then
  begin
    ShowSelectedQuestDetails;
    Exit;
  end;
  if SelectedIndex >= 0 then
    with GetByName('PanelSlot') as TPanelScrollBarGI do
      with Entries[SelectedIndex].BackgroundImage.Parent do
        ScrollRectIntoView(GetLocalBounds);
  ShowSelectedQuestDetails;
end;
procedure TfLoadQuest.UpdateQuestRow(Index: Integer);
var
  Image: TImageGI;
begin
  if (Index < 0) or (High(Entries) < Index) then
    Exit;
  Image := Entries[Index].BackgroundImage;
  if Entries[Index].RequiredAccess > AccessLevel then
    Exit;
  if SelectedIndex = Index then
    Image.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotActive')
  else if HoveredIndex = Index then
    Image.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotOnMouse')
  else if not Entries[Index].AlternateGroup then
    Image.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotNormal')
  else
    Image.SetImagePath('GI,Bm.FormLoadQuest.' + GiResourceSuffix + 'SlotNormal2');
end;
procedure TfLoadQuest.QuestRowMouseEnter(Sender: TObjectGI);
var
  Previous: Integer;
begin
  if HoveredIndex <> Sender.UserValue then
  begin
    Previous := HoveredIndex;
    HoveredIndex := Sender.UserValue;
    UpdateQuestRow(Previous);
    UpdateQuestRow(HoveredIndex);
  end;
end;
procedure TfLoadQuest.QuestRowMouseLeave(Sender: TObjectGI);
var
  Previous: Integer;
begin
  if HoveredIndex <> -1 then
  begin
    Previous := HoveredIndex;
    HoveredIndex := -1;
    UpdateQuestRow(Previous);
    UpdateQuestRow(HoveredIndex);
  end;
end;
procedure TfLoadQuest.QuestRowMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  SoundManager.PlaySound('Sound.ButtonClick');
  SelectQuest(Sender.UserValue);
  BreakUiMessage;
end;
procedure TfLoadQuest.QuestRowDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  StartSelectedQuest(nil);
end;
procedure TfLoadQuest.SelectCategory(Sender: TObjectGI);
var
  NewCategory: Integer;
begin
  NewCategory := ExtractDigitsToIntW(Sender.ControlName);
  (GetByName('ButGroup0') as TGraphButtonGI).SetDown(NewCategory = 0);
  (GetByName('ButGroup1') as TGraphButtonGI).SetDown(NewCategory = 1);
  (GetByName('ButGroup2') as TGraphButtonGI).SetDown(NewCategory = 2);
  if Category <> NewCategory then
  begin
    with GetByName('PanelSlot') as TPanelScrollBarGI do
      ScrollRectIntoView(Classes.Rect(0, 0, 1, 1));
    Category := NewCategory;
    SelectedIndex := -1;
    RebuildQuestList;
    SelectQuest(0);
  end;
end;
procedure TfLoadQuest.StartSelectedQuest(Sender: TObjectGI);
begin
  if SelectedIndex < 0 then
    Exit;
  if High(Entries) < SelectedIndex then
    Exit;
  PendingQuestName := Entries[SelectedIndex].Name;
  StandaloneQuestMode := True;
  QuestReturnScreenId := FormToId(Self);
  RequestedScreenId := screenPlanetQuest;
  RequestClose(1);
  BreakUiMessage;
end;
procedure TfLoadQuest.ShowSelectedQuestDetails;
var
  Quest: TTextQuest;
  Text: WideString;
  X, Y, RowSkip: Integer;
  Pixel: Pointer;
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  with GetByName('ButStart') as TGraphButtonGI do
    SetDisabled((SelectedIndex < 0) or (High(Entries) < SelectedIndex));

  with GetByName('ImageMap') as TGraphBufGI do
  begin
    SetActive(False);
    if (SelectedIndex >= 0) and (High(Entries) >= SelectedIndex) then
      if Entries[SelectedIndex].Image <> '' then
      begin
        SetActive(True);
        LoadBitmapPathAsRgba(Entries[SelectedIndex].Image + '?RGBA');
        if (ClientSize.X <> GraphBuf.Width) or (ClientSize.Y <> GraphBuf.Height) then
          GraphBuf.RescaleRgba(ClientSize.X, ClientSize.Y, 5);
        RowSkip := GraphBuf.PitchBytes - GraphBuf.Width * SizeOf(TColorRGBA);
        Pixel := GraphBuf.GetPixels;
        for Y := 0 to GraphBuf.Height - 1 do
        begin
          for X := 0 to GraphBuf.Width - 1 do
          begin
            if (Y < 23) and (GraphBuf.Width - 23 + Y < X) then
              PByte(@PColorRGBA(Pixel).A)^ := 0
            else
              PByte(@PColorRGBA(Pixel).A)^ := 255;
            Pixel := Pointer(PtrUInt(Pixel) + SizeOf(TColorRGBA));
          end;
          Pixel := Pointer(PtrUInt(Pixel) + RowSkip);
        end;
        Invalidate;
      end;
  end;

  with GetByName('MessageText') as TLabelGI do
  begin
    SetActive(False);
    if (SelectedIndex >= 0) and (High(Entries) >= SelectedIndex) then
    begin
      Quest := TTextQuest.Create;
      if Entries[SelectedIndex].QuestId >= 0 then
      begin

        Control := nil;
        try
          Control := TCBufControlEC.Create;
          GlobalCache.ResetControl(Control);
          Control.SetCacheKey('PlanetQuest.' + IntToStr(Entries[SelectedIndex].QuestId));
          Data := AcquireOrCreateBuffer(Control);
          Quest.LoadFromReader(Data.Buffer, True);
        finally
          if Control <> nil then
          begin
            Control.Release;
            Control.Free;
          end;
        end;

      end
      else
      begin

        Control := nil;
        try
          Control := TCBufControlEC.Create;
          GlobalCache.ResetControl(Control);
          Control.SetCacheKey('PlanetQuest.' + Entries[SelectedIndex].Name);
          Data := AcquireOrCreateBuffer(Control);
          Quest.LoadFromReader(Data.Buffer, True);
        finally
          if Control <> nil then
          begin
            Control.Release;
            Control.Free;
          end;
        end;

      end;
      Text := Quest.QuestDescriptionText.Text;
      ReplaceTextToken(
          Text,
          '<Ranger>',
          LocalizedText('FormLoadQuest.PRanger'),
          '<color=0,71,234>'
      );
      ReplaceTextToken(
          Text,
          '<ToPlanet>',
          LocalizedText('FormLoadQuest.PToPlanet'),
          '<color=0,71,234>'
      );
      ReplaceTextToken(
          Text,
          '<ToStar>',
          LocalizedText('FormLoadQuest.PToStar'),
          '<color=0,71,234>'
      );
      ReplaceTextToken(Text, '<Parsec>', IntToStr(10), '<color=0,71,234>');
      ReplaceTextToken(Text, '<Date>', FormatGameTurnDate(1000), '<color=0,71,234>');
      ReplaceTextToken(Text, '<Day>', IntToStr(30), '<color=0,71,234>');
      ReplaceTextToken(Text, '<Money>', IntToStr(10000), '<color=0,71,234>');
      ReplaceTextToken(
          Text,
          '<FromPlanet>',
          LocalizedText('FormLoadQuest.PFromPlanet'),
          '<color=0,71,234>'
      );
      ReplaceTextToken(
          Text,
          '<FromStar>',
          LocalizedText('FormLoadQuest.PFromStar'),
          '<color=0,71,234>'
      );
      Text := ReplaceAllWideString(Text, '<clr>', '<color=0,71,234>');
      ExpandLocalizedTextMarkup(Text);
      Quest.Free;
      SetActive(True);
      SetText(Text);
    end;

  end;
  with GetByName('MessageWindow') as TPanelScrollBarGI do
  begin
    SetScrollOffset(Classes.Point(0, 0));
    UpdateScrollRanges;
    VerticalScrollBar.SetActive(
        FindByNameRecursive('MessageText').Active
            and ((FindByNameRecursive('MessageText') as TLabelGI).ClientSize.Y > ClientSize.Y)
    );
    VerticalScrollBar
        .SetSmallChange((FindByNameRecursive('MessageText') as TLabelGI).GetLineHeight);
    VerticalScrollBar.SetLargeChange(ClientSize.Y);
    VerticalScrollBar.SetPageSize(ClientSize.Y);
  end;
end;
procedure TfLoadQuest.LoadCompletionData;
var
  Buffer: TBufEC;
  I, Count: Integer;
begin
  CompletionData := nil;
  if RTLFileSystem.FileExists(AnsiString(GetGameUserDirectory + 'QuestComplate.dat')) then
  begin
    try
      Buffer := TBufEC.Create;
      Buffer.LoadFromWideFilePath(PWideChar(GetGameUserDirectory + 'QuestComplate.dat'));
      if Buffer.ComputeCrc32Range(4, Buffer.DataSize) <> Buffer.GetUInt32 then
        Abort;
      Count := Buffer.GetInt32;
      SetLength(CompletionData, Count);
      for I := 0 to Count - 1 do
        CompletionData[I] := Buffer.GetInt32;
      Buffer.Free;
    except
      CompletionData := nil;
    end;
  end;
end;
procedure TfLoadQuest.SaveCompletionData;
var
  Buffer: TBufEC;
  FileHandle: TFileEC;
  I: Integer;
begin
  Buffer := TBufEC.Create;
  Buffer.AddDword(0);
  Buffer.AddInteger(High(CompletionData) + 1);
  for I := 0 to High(CompletionData) do
    Buffer.AddIntegerValue(CompletionData[I]);
  PCardinal(Buffer.Data)^ := Buffer.ComputeCrc32Range(4, Buffer.DataSize);
  FileHandle := TFileEC.Create;
  FileHandle.SetFileName(GetGameUserDirectory + 'QuestComplate.dat');
  FileHandle.CreateNew;
  FileHandle.WriteBuffer(Buffer.Data, Buffer.DataSize);
  FileHandle.Free;
  Buffer.Free;
end;
procedure TfLoadQuest.RecordCompletion(QuestId, Value, Status: Integer);
var
  Count, I: Integer;
begin
  if (QuestId < 0) or (QuestId >= 10000) then
    Exit;
  Count := (High(CompletionData) + 1) div 2;
  if QuestId >= Count then
  begin
    SetLength(CompletionData, (QuestId + 1) * 2);
    for I := Count * 2 to High(CompletionData) do
      CompletionData[I] := 0;
  end;
  if CompletionData[QuestId * 2 + 1] > Status then
    Exit;
  if (CompletionData[QuestId * 2] = 0) or (CompletionData[QuestId * 2 + 1] < Status) then
    CompletionData[QuestId * 2] := Value
  else
    CompletionData[QuestId * 2] := Min(CompletionData[QuestId * 2], Value);
  CompletionData[QuestId * 2 + 1] := Status;
end;
function TfLoadQuest.CalculateAccessLevel: Integer;
var
  I, QuestId, Access, GroupCount, CompletedCount, CompletionIndex: Integer;
begin
  Result := 0;
  I := 0;
  while High(Entries) >= I do
  begin
    Access := Entries[I].RequiredAccess;
    GroupCount := 0;
    CompletedCount := 0;
    while High(Entries) >= I + GroupCount do
    begin
      if Entries[I + GroupCount].RequiredAccess <> Access then
        Break;
      QuestId := Entries[I + GroupCount].QuestId;
      if (QuestId >= 0) and (QuestId < 10000) then
      begin
        CompletionIndex := QuestId;
        if CompletionIndex >= 0 then
          if (High(CompletionData) + 1) div 2 > CompletionIndex then
            // The native inlined completion check repeats this upper bound.
            if (High(CompletionData) + 1) div 2 > CompletionIndex then
              if CompletionData[CompletionIndex * 2 + 1] <> 0 then
                Inc(CompletedCount);
      end;
      Inc(GroupCount);
    end;
    Result := Access;
    if (Access > 0) and (GroupCount - 1 > CompletedCount) then
      Break;
    Inc(I, GroupCount);
  end;
  if Result = 0 then
    Result := 1;
end;
function TfLoadQuest.GetCompletionCounts: TPoint;
var
  I, CompletionIndex, Count, QuestId: Integer;
  List, Entry: TBlockParEC;
  Name: WideString;
begin
  Result.X := 0;
  Result.Y := 0;
  LoadCompletionData;
  List := LanguageDataConfig.GetBlockByPath('PlanetQuest.List');
  Count := List.GetBlockCount;
  for I := 0 to Count - 1 do
  begin
    Entry := List.GetBlockByIndex(I);
    Name := List.GetBlockNameByIndex(I);
    QuestId := -1;
    if IsIntegerTextW(Name) then
      QuestId := StrToInt(AnsiString(Name));
    if (QuestId >= 0) and (ExtractDigitsToIntW(Entry.GetParam('Access')) > 0) then
    begin
      Inc(Result.Y);
      CompletionIndex := QuestId;
      if CompletionIndex >= 0 then
        if (High(CompletionData) + 1) div 2 > CompletionIndex then
          if CompletionData[CompletionIndex * 2 + 1] <> 0 then
            Inc(Result.X);
    end;
  end;
end;
function TfLoadQuest.GetCompletionSummary: WideString;
var
  Counts: TPoint;
  List, Entry: TBlockParEC;
  Count, I, Total: Integer;
begin
  List := LanguageDataConfig.GetBlockByPath('PlanetQuest.List');
  Count := List.GetBlockCount;
  Total := 0;
  for I := 0 to Count - 1 do
  begin
    Entry := List.GetBlockByIndex(I);
    if Entry.CountParams('Group') > 0 then
      if ExtractSignedDigitsToIntW(Entry.GetParam('Group')) in [0, 1, 2] then
        Inc(Total);
  end;
  Counts := GetCompletionCounts;
  Result := IntToStr(Counts.X) + '/' + IntToStr(Total);
end;
procedure TfLoadQuest.SelectMusic;
begin
end;
procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TLabelGI.ClassName;
  TPanelScrollBarGI.ClassName;
end;
end.
