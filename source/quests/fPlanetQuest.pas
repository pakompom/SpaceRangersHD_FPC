unit fPlanetQuest;

{$I GameOptions.inc}

interface

uses
  EC_BlockPar,
  EC_CacheFont,
  GI_Label,
  GI_GraphButton,
  GI_MessageLoop,
  QuestArtwork,
  TextQuest,
  TextQuestInterface,
  Types,
  aRanger,
  aScript;

type

  TTextQuestPlayerInterface = class;

  TfPlanetQuest = class;

  TfQuestA = class;

  TQuestChoiceEvent = procedure(Value: Integer) of object;

  TfQuestA = class(TObject)
    Callback: TQuestChoiceEvent;
    Value: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TfPlanetQuest = class(TMessageLoopGI)
    QuestName: WideString;
    Quest: TTextQuest;
    CurrentDate: WideString;
    DaysElapsed: Integer;
    CurrentPicture: WideString;
    MoneyLimitComplement: Cardinal;
    CurrentText: WideString;
    NextChoiceTop: Integer;
    ParameterPanelWidth: Integer;
    ParameterPanelHeight: Integer;
    PageAnimationTimer: PCallbackTimerGI;
    PreviousStyleIndex: Integer;
    ChoiceCount: Integer;
    Gap104: array[0..1] of Byte;
    ParameterPanelOrigin: TPoint;
    MobileArtwork: TQuestArtworkGI;
    MobileTextScale: Single;
    MobileTextBounds, MobileSidebarBounds: TRect;
    MobileStylePositions: array[0..5] of TPoint;
    MobileStatsToggle: TGraphButtonGI;
    MobileStatsExpanded: Boolean;
    ChoicePadding: Integer;
    ChoicesFinalized: Boolean;
    QuestId: Integer;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
    function GetQuestFontName: WideString;
    procedure InitializeMobileLayout;
    procedure LayoutMobileControls;
    procedure LayoutMobilePage;
    procedure ReflowMobileText;
    procedure ReflowMobileChoices;
    procedure StatsButtonClick(Sender: TObjectGI);
    function GetTextBeforeDelimiter(const Text: WideString; Delimiter: WideChar): WideString;
    function GetTextAfterComma(const Text: WideString; IgnoredDelimiter: WideChar): WideString;
    function GetQuestContentHash(QuestId: Integer): WideString;
    procedure LoadQuestById(QuestId: Integer);
    procedure LoadQuestByName(const Name: WideString);
    procedure StartLoadedQuest;
    procedure ClearChoices;
    procedure AddChoice(Text: WideString; Value: Integer; Callback: TQuestChoiceEvent);
    procedure AddDisabledChoice(Text: WideString; Value: Integer; Callback: TQuestChoiceEvent);
    function CreateChoiceInlineObject(Sender: TLabelGI; Item: PFontObjectEC): TObjectGI;
    procedure ChoiceMouseEnter(Sender: TObjectGI);
    procedure ChoiceMouseLeave(Sender: TObjectGI);
    procedure ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure ChoiceMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure DisabledChoiceMouseEnter(Sender: TObjectGI);
    procedure DisabledChoiceMouseLeave(Sender: TObjectGI);
    procedure DisabledChoiceMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure FinishChoiceLayout;
    procedure AnimateTextPage(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure ClearParameterPanel;
    procedure AppendParameterText(Text: WideString);
    procedure LayoutParameterPanel;
    procedure SetQuestText(const Text: WideString);
    function GetTextColorTag(StyleIndex: Integer): WideString;
    function GetTextColor(StyleIndex: Integer): Cardinal;
    function GetDisabledTextColor(StyleIndex: Integer): Cardinal;
    procedure ApplyStyle;
    procedure SelectPageMode(Sender: TObjectGI);
    procedure SelectStyle(Sender: TObjectGI);
    procedure ShowControlHelp(Sender: TObjectGI; Visible: Boolean);
    procedure SetQuestPicture(Name: WideString);
    procedure RequestLoadGame(Sender: TObjectGI);
    procedure QuestKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
    function ExpandTemplateText(Text: WideString): WideString;
    procedure IgnoreChoice(Value: Integer);
    procedure ContinueToLocation(LocationId: Integer);
    procedure ContinueAlongPath(PathId: Integer);
    procedure ContinueToOutcome(Value: Integer);
    procedure CompleteQuestSuccess(Value: Integer);
    procedure CompleteQuestFailure(Value: Integer);
    procedure CompleteQuestDeath(Value: Integer);
    procedure ApplyLegacyPictureOverrides;
    procedure ExportMoneyToPlayer;
    procedure ImportMoneyFromPlayer;
    procedure ExportExternalParameters;
    procedure ImportExternalParameters;
    function ExpandExternalText(Text: WideString): WideString;
  end;

  TTextQuestPlayerInterface = class(TTextQuestInterface)
    procedure ShowText(Text: WideString); override;
    procedure ShowPicture(Name: WideString); override;
    procedure PlayMusic(Name: WideString); override;
    procedure PlaySound(Name: WideString); override;
    procedure ShowParameters(Text: WideString); override;
    procedure AddContinueAction; override;
    procedure AddSuccessAction; override;
    procedure AddDeathAction; override;
    procedure AddFailureAction; override;
    procedure AddPathAction(Text: WideString; PathId: Integer); override;
    procedure AddDisabledPath(Text: WideString); override;
    procedure AddPathContinueAction(PathId: Integer); override;
    procedure AddLocationContinueAction(LocationId: Integer); override;
    procedure AdvanceDays(Days: Integer); override;
  end;

var

  QuestStyleCount: Integer = 0;

  ActiveGovernmentQuest: PQuest = nil;

  QuestPlayerInterface: TTextQuestPlayerInterface = nil;

  ActiveQueuedTextQuest: PQueuedTextQuest = nil;

implementation

uses
  aSaveLoad,
  GameInput,
  GameWindow,
  Classes,
  Math,
  GI_GraphBuf,
  GI_ScrollBar,
  GI_Window,
  EC_Cache,
  EC_CacheBuf,
  EC_Expression,
  EC_Str,
  GI_Image,
  GI_Main,
  GI_Panel,
  GI_PanelScrollBar,
  Globals,
  GlobalsV,
  GR_Main,
  SysUtils,
  ThreadCalc,
  aCalc,
  ParameterClass,
  aConst,
  aGalaxy,
  aPlayer,
  GI_MessageBox,
  fSaveManager,
  fScore,
  fLoadQuest,
  fHangar,
  aShip,
  aPlanet,
  aItem,
  Achievements,
  aGalaxyStruct,
  ValueListClass,
  EventClass,
  aMyFunction;

type
  TQuestStatsActionGI = class(TGraphButtonGI)
  private
    Frame: TGraphBufGI; // Owned child; its buffer holds the button's composed skin.
    Artwork: TQuestArtworkGI; // Borrowed from this screen's control tree.
  public
    constructor Create(Owner: TObjectGI; SourceArtwork: TQuestArtworkGI);
    procedure SetSize(Size: TPoint); override;
  end;

  // A fixed-width quest diagram is one indivisible block. Its rows share one
  // scale, while its position and scroll extent remain in the page's coordinates.
  TQuestTextGI = class(TLabelGI)
    FixedBlock: Boolean;
    procedure FitWidth(Width: Integer);
    function LayoutHeight: Integer;
    function GetLocalBounds: TRect; override;
    procedure UpdateHitTestBounds; override;
  end;

constructor TQuestStatsActionGI.Create(Owner: TObjectGI; SourceArtwork: TQuestArtworkGI);
begin
  inherited Create(Owner);
  Artwork := SourceArtwork;
  Frame := TGraphBufGI.Create(Self, True);
  Frame.SetDepth(1);
  Frame.SourceHasPerPixelAlpha := True;
  UpOnlyDown := True;
  CaptionOffsets := Rect(0, 0, 0, 1);
end;

procedure TQuestStatsActionGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if (Frame = nil) or ((Frame.ClientSize.X = Size.X) and (Frame.ClientSize.Y = Size.Y)) then
    Exit;
  Frame.SetSize(Size);
  Artwork.BuildControlPlate(Frame.GraphBuf, Size.X, Size.Y);
end;

procedure TQuestTextGI.FitWidth(Width: Integer);
var
  OldSize: TPoint;
begin
  OldSize := ClientSize;
  DisplayScale := 1;
  if FixedBlock then
  begin
    SetWordWrapEnabled(False);
    SetTextAlignX(taxAuto);
    SetSize(Point(1, 1));
    // Measure without justification, then keep the measured width fixed.
    SetTextAlignX(taxLeft);
    if HardwareRenderingEnabled then
      DisplayScale := Min(1, Width / Max(1, ClientSize.X + 1));
  end
  else
    SetSize(Point(Width, 1));
  SetSize(Point(ClientSize.X, Max(1, GetRenderedLineCount) * GetLineHeight + 4));
  if (TextTexture <> nil) and ((OldSize.X <> ClientSize.X) or (OldSize.Y <> ClientSize.Y)) then
    TextTexture.ReleaseSurfaces;
  UpdateAbsolutePosition;
  UpdateSubtreeHitBounds;
end;

function TQuestTextGI.LayoutHeight: Integer;
begin
  Result := Ceil(ClientSize.Y * DisplayScale);
end;

function TQuestTextGI.GetLocalBounds: TRect;
begin
  Result :=
      Rect(
          LocalPosition.X,
          LocalPosition.Y,
          LocalPosition.X + Ceil(ClientSize.X * DisplayScale),
          LocalPosition.Y + LayoutHeight
      );
end;

procedure TQuestTextGI.UpdateHitTestBounds;
begin
  if FixedBlock and (DisplayScale <> 1) and (Parent <> nil) then
    AbsolutePosition :=
        ScaledChildPosition(
            Parent.GetChildAbsolutePosition(LocalPosition, PositionModeW),
            Point(0, 0),
            DisplayScale
        );
  inherited UpdateHitTestBounds;
end;

constructor TfQuestA.Create;
begin
  inherited Create;
end;

destructor TfQuestA.Destroy;
begin
  inherited Destroy;
end;

function TfPlanetQuest.GetTextBeforeDelimiter(
    const Text: WideString;
    Delimiter: WideChar
): WideString;
var
  I, N: Integer;
  S: WideString;
begin
  S := '';
  N := Length(Text);
  for I := 1 to N do
  begin
    if Text[I] = Delimiter then
      Break;
    S := S + Text[I];
  end;
  Result := S;
end;

function TfPlanetQuest.GetTextAfterComma(
    const Text: WideString;
    IgnoredDelimiter: WideChar
): WideString;
var
  I, N: Integer;
  S: WideString;
begin
  S := '';
  N := Length(Text);
  if N <> 0 then
  begin
    I := 1;
    while Text[I] <> ',' do
      Inc(I);
    Inc(I);
    while I <= N do
    begin
      S := S + Text[I];
      Inc(I);
    end;
  end;
  Result := S;
end;

function TfPlanetQuest.GetQuestContentHash(QuestId: Integer): WideString;
var
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  Control := nil;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + IntToStr(QuestId));
    Data := AcquireOrCreateBuffer(Control);
    Result := ScriptDwordToHex(Data.Buffer.ComputeCrc32 xor $FFFFFFFF);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;

procedure TfPlanetQuest.LoadQuestById(QuestId: Integer);
var
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  Self.QuestId := QuestId;
  Control := nil;
  QuestName := IntToStr(QuestId);
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + IntToStr(QuestId));
    Data := AcquireOrCreateBuffer(Control);
    Quest.LoadFromReader(Data.Buffer, False);
    if not StandaloneQuestMode then
      if QuestId >= FirstLicensedQuestId then
        if (LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') <= 0)
            or (LanguageDataConfig
                    .GetBlock('PlanetQuest')
                    .GetBlock('PlanetQuestLic')
                    .GetParamOrMarker(IntToStr(QuestId))
                <> ScriptDwordToHex(Data.Buffer.ComputeCrc32 xor $FFFFFFFF)) then
          GR_Main.CCInterface.SetTamperDetected(True);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;

procedure TfPlanetQuest.LoadQuestByName(const Name: WideString);
var
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  QuestId := -1;
  Control := nil;
  QuestName := Name;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + Name);
    Data := AcquireOrCreateBuffer(Control);
    Quest.LoadFromReader(Data.Buffer, False);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;

procedure TfPlanetQuest.StartLoadedQuest;
begin
  ClearChoices;
  DaysElapsed := 0;
  if Quest.FormatVersion <= 1111111124 then
    ApplyLegacyPictureOverrides;
  if GetPlayer = nil then
    CurrentDate := TrimWideString(Galaxy.FormatTurnDate(GalaxyWarmupTurns))
  else
    CurrentDate := TrimWideString(Galaxy.FormatTurnDate(Galaxy.CurrentTurn));
  Quest.PlayerInterface := QuestPlayerInterface;
  ImportExternalParameters;
  if GetPlayer = nil then
    Quest.Start(-1, False)
  else
    Quest.Start(GetPlayer.Money, True);
  FinishChoiceLayout;
end;

procedure TfPlanetQuest.ClearChoices;
var
  Panel: TPanelScrollBarGI;
  Spacer: TPanelGI;
begin
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  Panel.FreeOwnedChildren;
  Panel.Invalidate;
  NextChoiceTop := ChoicePadding;
  ParameterPanelWidth := 0;
  ParameterPanelHeight := 0;
  ChoiceCount := 0;
  ChoicesFinalized := False;
  Spacer := TPanelGI.Create(GetByName('ActionListWindow'));
  Spacer.SetPosition(Classes.Point(0, 0));
  Spacer.SetSize(Classes.Point(ChoicePadding, ChoicePadding));
  Spacer.SetPositionModeW(True);
end;

procedure TfPlanetQuest.AddChoice(Text: WideString; Value: Integer; Callback: TQuestChoiceEvent);
var
  Owner: TPanelScrollBarGI;
  Skip: Integer;
  Panel: TPanelGI;
  Highlight: TImageGI;
  Choice: TfQuestA;
  Path: WideString;
  TextLabel: TLabelGI;
begin
  Skip := 0;
  while Skip < Length(Text) do
  begin
    if (Text[Skip + 1] <> '-') and (Text[Skip + 1] <> ' ') then
      Break;
    Inc(Skip);
  end;
  if Skip > 0 then
    Text := Copy(Text, Skip + 1, Length(Text) - Skip);
  Owner := GetByName('ActionListWindow') as TPanelScrollBarGI;
  Choice := TfQuestA.Create;
  Choice.Callback := Callback;
  Choice.Value := Value;
  Panel := TPanelGI.Create(Owner);
  Panel.UserValue := PtrInt(Choice);
  Panel.SetName(IntToStr(ChoiceCount));
  Panel.SetPosition(Classes.Point(0, NextChoiceTop));
  Panel.SetSize(Classes.Point(Owner.ClientSize.X, 20));
  Panel.SetPositionModeW(True);
  Panel.MouseEnterCallback := ChoiceMouseEnter;
  Panel.MouseLeaveCallback := ChoiceMouseLeave;
  Panel.LeftButtonDownCallback := ChoiceMouseDown;
  Panel.LeftButtonUpCallback := ChoiceMouseUp;
  Panel.TouchInteraction := tiTap;
  Highlight := TImageGI.Create(Panel);
  Highlight.SetDepth(3);
  Highlight.SetPosition(Classes.Point(0, 0));
  Highlight.SetSize(Classes.Point(Owner.ClientSize.X, 20));
  Path :=
      'Bm.FormPQuest2.' + GiResourceSuffix + 'S' + IntToWideString(QuestStyleIndex + 1) + 'Line';
  if CacheDataRoot.FileExistsByPath(Path) then
    Highlight.SetImagePath('GI,' + Path)
  else
    Highlight.SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1Line');
  Highlight.SetImageKindX(ikxLeftFill);
  Highlight.SetImageKindY(ikyTopFill);
  Highlight.SetActive(False);
  TextLabel := TLabelGI.Create(Panel);
  TextLabel.SetName(IntToStr(ChoiceCount));
  TextLabel.SetFontName(GetQuestFontName);
  TextLabel.SetSize(Classes.Point(Owner.ClientSize.X - 20, 20));
  TextLabel.SetPosition(Classes.Point(10, 0));
  TextLabel.SetDepth(2);
  TextLabel.SetWordWrapEnabled(True);
  TextLabel.SetTextAlignX(taxLeft);
  TextLabel.SetTextAlignY(tayAuto);
  TextLabel.SetText('<Object=0,20,14,0>' + Text);
  TextLabel.SetPositionModeW(True);
  TextLabel.SetActive(True);
  TextLabel.CreateEmbeddedControl := CreateChoiceInlineObject;
  TextLabel.SetTextAlignY(tayCenterEx);
  TextLabel.SetTextColor(GetTextColor(QuestStyleIndex));
  Panel.SetSize(
      Classes.Point(Panel.ClientSize.X, GiScalePixelsEx(2, 1) * 2 + TextLabel.ClientSize.Y)
  );
  TextLabel.SetSize(Classes.Point(TextLabel.ClientSize.X, Panel.ClientSize.Y));
  Highlight.SetSize(Panel.ClientSize);
  Inc(NextChoiceTop, Panel.ClientSize.Y);
  Owner.VerticalScrollBar.SetSmallChange(TextLabel.GetLineHeight);
  Owner.UpdateScrollRanges;
  Inc(ChoiceCount);
end;

procedure TfPlanetQuest.AddDisabledChoice(
    Text: WideString;
    Value: Integer;
    Callback: TQuestChoiceEvent
);
var
  Owner: TPanelScrollBarGI;
  Skip: Integer;
  Panel: TPanelGI;
  Highlight: TImageGI;
  Path: WideString;
  TextLabel: TLabelGI;
begin
  Skip := 0;
  while Skip < Length(Text) do
  begin
    if (Text[Skip + 1] <> '-') and (Text[Skip + 1] <> ' ') then
      Break;
    Inc(Skip);
  end;
  if Skip > 0 then
    Text := Copy(Text, Skip + 1, Length(Text) - Skip);
  Text := RemoveMatchingTextTagsW(Text, 'color', 'COLOR');
  Text := RemoveMatchingTextTagsW(Text, '/color', '/COLOR');
  Owner := GetByName('ActionListWindow') as TPanelScrollBarGI;
  Panel := TPanelGI.Create(Owner);
  Panel.SetName(IntToStr(ChoiceCount));
  Panel.SetPosition(Classes.Point(0, NextChoiceTop));
  Panel.SetSize(Classes.Point(Owner.ClientSize.X, 20));
  Panel.SetPositionModeW(True);
  Panel.MouseEnterCallback := DisabledChoiceMouseEnter;
  Panel.MouseLeaveCallback := DisabledChoiceMouseLeave;
  Panel.LeftButtonDownCallback := ChoiceMouseDown;
  Panel.LeftButtonUpCallback := DisabledChoiceMouseUp;
  Panel.TouchInteraction := tiTap;
  Highlight := TImageGI.Create(Panel);
  Highlight.SetDepth(3);
  Highlight.SetPosition(Classes.Point(0, 0));
  Highlight.SetSize(Classes.Point(Owner.ClientSize.X, 20));
  Path :=
      'Bm.FormPQuest2.' + GiResourceSuffix + 'S' + IntToWideString(QuestStyleIndex + 1) + 'Line';
  if CacheDataRoot.FileExistsByPath(Path) then
    Highlight.SetImagePath('GI,' + Path)
  else
    Highlight.SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1Line');
  Highlight.SetImageKindX(ikxLeftFill);
  Highlight.SetImageKindY(ikyTopFill);
  Highlight.SetActive(False);
  TextLabel := TLabelGI.Create(Panel);
  TextLabel.SetName(IntToStr(ChoiceCount));
  TextLabel.SetFontName(GetQuestFontName);
  TextLabel.SetSize(Classes.Point(Owner.ClientSize.X - 20, 20));
  TextLabel.SetPosition(Classes.Point(10, 0));
  TextLabel.SetDepth(2);
  TextLabel.SetWordWrapEnabled(True);
  TextLabel.SetTextAlignX(taxLeft);
  TextLabel.SetTextAlignY(tayAuto);
  TextLabel.SetText('<Object=0,20,14,0>' + Text);
  TextLabel.SetPositionModeW(False);
  TextLabel.SetActive(True);
  TextLabel.UserState := 1;
  TextLabel.CreateEmbeddedControl := CreateChoiceInlineObject;
  TextLabel.SetTextAlignY(tayCenterEx);
  TextLabel.SetTextColor(GetDisabledTextColor(QuestStyleIndex));
  Panel.SetSize(
      Classes.Point(Panel.ClientSize.X, GiScalePixelsEx(2, 1) * 2 + TextLabel.ClientSize.Y)
  );
  TextLabel.SetSize(Panel.ClientSize);
  Highlight.SetSize(Panel.ClientSize);
  Inc(NextChoiceTop, Panel.ClientSize.Y);
  Owner.UpdateScrollRanges;
  Inc(ChoiceCount);
end;

function TfPlanetQuest.CreateChoiceInlineObject(Sender: TLabelGI; Item: PFontObjectEC): TObjectGI;
var
  Path: WideString;
  Image: TImageGI;
begin
  Result := TPanelGI.Create(Sender);
  Image := TImageGI.Create(Result);
  Path :=
      'Bm.FormPQuest2.' + GiResourceSuffix + 'S' + IntToWideString(QuestStyleIndex + 1) + 'Answer';
  if Sender.UserState = 1 then
  begin
    if CacheDataRoot.FileExistsByPath(Path + 'H') then
      Image.SetImagePath('GI,' + Path + 'H')
    else
      Image.SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1AnswerH');
  end
  else
  begin
    if CacheDataRoot.FileExistsByPath(Path) then
      Image.SetImagePath('GI,' + Path)
    else
      Image.SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1Answer');
  end;
  Image.SetImageKindX(ikxLeft);
  Image.SetSize(Image.GetContentSize);
end;

procedure TfPlanetQuest.ChoiceMouseEnter(Sender: TObjectGI);
begin
  Sender.FirstChild.SetActive(True);
end;

procedure TfPlanetQuest.ChoiceMouseLeave(Sender: TObjectGI);
begin
  Sender.FirstChild.SetActive(False);
end;

procedure TfPlanetQuest.ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if (Sender.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild.FirstChild <> nil) then
    Sender.FirstChild.NextSibling.FirstChild.FirstChild.SetPosition(Classes.Point(2, 0));
end;

procedure TfPlanetQuest.ChoiceMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Choice: TfQuestA;
begin
  if Galaxy <> nil then
    Galaxy.CheckIntegrityChecksum(163);
  Choice := TfQuestA(Sender.UserValue);
  Sender.UserValue := 0;
  ClearChoices;
  if Choice <> nil then
  begin
    if Assigned(Choice.Callback) then
      Choice.Callback(Choice.Value);
    Choice.Free;
  end;
  FinishChoiceLayout;
  if Galaxy <> nil then
    Galaxy.PrimeIntegrityChecksum(164);
  PostMouseMoveMessage;
  BreakUiMessage;
end;

procedure TfPlanetQuest.DisabledChoiceMouseEnter(Sender: TObjectGI);
begin
  Sender.FirstChild.SetActive(True);
end;

procedure TfPlanetQuest.DisabledChoiceMouseLeave(Sender: TObjectGI);
begin
  if (Sender <> nil)
      and (Sender.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild.FirstChild <> nil) then
  begin
    Sender.FirstChild.NextSibling.FirstChild.FirstChild.SetPosition(Classes.Point(0, 0));
    Sender.FirstChild.SetActive(False);
  end;
end;

procedure TfPlanetQuest.DisabledChoiceMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if (Sender.FirstChild <> nil)
      and (Sender.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild <> nil)
      and (Sender.FirstChild.NextSibling.FirstChild.FirstChild <> nil) then
    Sender.FirstChild.NextSibling.FirstChild.FirstChild.SetPosition(Classes.Point(0, 0));
end;

procedure TfPlanetQuest.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
var
  Panel1, Panel2, Panel3, Panel4: TPanelScrollBarGI;
begin
  if Delta = WHEEL_DELTA then
  begin
    if GetByName('ActionListWindow').ContainsPoint(Point) then
    begin
      Panel1 := GetByName('ActionListWindow') as TPanelScrollBarGI;
      Panel1.SetScrollOffset(
          Classes.Point(0, Panel1.ScrollOffset.Y - Panel1.VerticalScrollBar.SmallChange)
      );
      Panel1.PanelScrollChanged(nil);
    end
    else
    begin
      Panel2 := GetByName('MessageWindow') as TPanelScrollBarGI;
      Panel2.SetScrollOffset(
          Classes.Point(0, Panel2.ScrollOffset.Y - Panel2.VerticalScrollBar.SmallChange)
      );
      Panel2.PanelScrollChanged(nil);
    end;
  end
  else if Delta = -WHEEL_DELTA then
  begin
    if GetByName('ActionListWindow').ContainsPoint(Point) then
    begin
      Panel3 := GetByName('ActionListWindow') as TPanelScrollBarGI;
      Panel3.SetScrollOffset(
          Classes.Point(0, Panel3.ScrollOffset.Y + Panel3.VerticalScrollBar.SmallChange)
      );
      Panel3.PanelScrollChanged(nil);
    end
    else
    begin
      Panel4 := GetByName('MessageWindow') as TPanelScrollBarGI;
      Panel4.SetScrollOffset(
          Classes.Point(0, Panel4.ScrollOffset.Y + Panel4.VerticalScrollBar.SmallChange)
      );
      Panel4.PanelScrollChanged(nil);
    end;
  end;
end;

procedure TfPlanetQuest.FinishChoiceLayout;
var
  Panel: TPanelScrollBarGI;
  Control: TObjectGI;
  LineCount, Page, ExtraOffset: Integer;
  Spacer: TPanelGI;
begin
  ChoicesFinalized := True;
  Inc(NextChoiceTop, ChoicePadding);
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  Spacer := TPanelGI.Create(Panel);
  Spacer.SetPosition(Classes.Point(0, NextChoiceTop - ChoicePadding));
  Spacer.SetSize(Classes.Point(ChoicePadding, ChoicePadding));
  Spacer.SetPositionModeW(True);
  LayoutMobilePage;
  Panel.SetActive(True);
  Panel.SetVerticalScrollbarEnabled(NextChoiceTop > Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  Panel.SetScrollOffset(Classes.Point(0, 0));
  Panel.SetDragScrollingEnabled(Panel.IsVerticalScrollbarEnabled);
  Panel.UpdateScrollRanges;
  if QuestPageAnimationEnabled then
  begin
    GetByName('ActionListWindow').SetActive(False);
    Panel := GetByName('MessageWindow') as TPanelScrollBarGI;
    Panel.SetUnlimitedWorldEnabled(True);
    Panel.SetDragScrollingEnabled(False);
    Control := Panel.FirstChild;
    LineCount := 0;
    Page := 1;
    ExtraOffset := 0;
    while Control <> nil do
    begin
      Control.UserIndex := Control.LocalPosition.Y;
      if Control is TLabelGI then
        if Control.LocalPosition.Y < Panel.ClientSize.Y then
        begin
          Control.UserValue := Page;
          if Page > 1 then
            Control.SetPosition(
                Classes.Point(
                    Control.LocalPosition.X,
                    -Control.LocalPosition.Y - Control.ClientSize.Y - ExtraOffset
                )
            );
          Inc(LineCount, (Control as TLabelGI).GetRenderedLineCount);
          if LineCount > 5 then
          begin
            LineCount := 0;
            Inc(Page);
          end;
        end;
      Control := Control.NextSibling;
    end;
    if PageAnimationTimer <> nil then
    begin
      CancelCallbackTimer(PageAnimationTimer);
      PageAnimationTimer := nil;
    end;
    PageAnimationTimer := ScheduleCallbackTimer(20, 20, AnimateTextPage);
  end;
end;

procedure TfPlanetQuest.AnimateTextPage(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Panel: TPanelScrollBarGI;
  Control: TObjectGI;
  Moving: Boolean;
  Step: Integer;
begin
  Moving := False;
  Panel := GetByName('MessageWindow') as TPanelScrollBarGI;
  Control := Panel.FirstChild;
  while Control <> nil do
  begin
    if Control is TLabelGI then
      if Control.LocalPosition.Y < Control.UserIndex then
      begin
        Moving := True;
        Step := Round(Min(1.0, (Control.UserIndex - Control.LocalPosition.Y) / 100) * 30);
        if Step < 1 then
          Step := 1;
        Control.SetPosition(
            Classes.Point(
                Control.LocalPosition.X,
                Min(Control.UserIndex, Control.LocalPosition.Y + Step)
            )
        );
      end;
    Control := Control.NextSibling;
  end;
  if not Moving then
  begin
    Panel.SetUnlimitedWorldEnabled(False);
    Panel.SetDragScrollingEnabled(True);
    if PageAnimationTimer <> nil then
    begin
      CancelCallbackTimer(PageAnimationTimer);
      PageAnimationTimer := nil;
    end;
    LayoutMobilePage;
    GetByName('ActionListWindow').SetActive(True);
    PostMouseMoveMessage;
  end;
end;

function TfPlanetQuest.GetQuestFontName: WideString;
var
  Size: Integer;
begin
  Size := FontQuest;
  case Size of
    0: Result := NormalFontName;
    1: Result := SmoothBigFontName;
    2: Result := SmoothHugeFontName;
  else
    Result := SmoothIntroFontName;
  end;
end;

procedure TfPlanetQuest.ClearParameterPanel;
var
  Panel: TPanelGI;
begin
  Panel := GetByName('ParamsShowWindow') as TPanelGI;
  Panel.FreeOwnedChildren;
  ParameterPanelWidth := 0;
  ParameterPanelHeight := 0;
end;

procedure TfPlanetQuest.AppendParameterText(Text: WideString);
var
  Panel: TPanelGI;
  FixedWidth: Boolean;
  Lines: TStringsEC;
  TextLabel: TLabelGI;
begin
  Panel := GetByName('ParamsShowWindow') as TPanelGI;
  FixedWidth := FindTextOffsetW(LowerCaseWideString(Text), '<fix>') >= 0;
  Text := RemoveMatchingTextTagsW(Text, 'fix', 'FIX');
  Text := RemoveMatchingTextTagsW(Text, '/fix', '/FIX');
  Text := ReplaceAllWideString(Text, GetTextColorTag(QuestStyleIndex), TextHighlightColorTag);
  Lines := TStringsEC.Create;
  Lines.SetText(Text);
  Lines.First;
  while not Lines.IsAtEnd do
  begin
    TextLabel := TLabelGI.Create(Panel);
    if FixedWidth then
      TextLabel.SetFontName('Font.' + GiResourceSuffix + 'Fix')
    else
      TextLabel.SetFontName(NormalFontName);
    TextLabel.SetSize(Classes.Point(1, 1));
    TextLabel.SetTextAlignX(taxAuto);
    TextLabel.SetTextAlignY(tayAuto);
    TextLabel.SetWordWrapEnabled(False);
    TextLabel.SetText(Lines.GetCurrentText);
    TextLabel.SetTextColor(GetTextColor(0));
    TextLabel.SetPosition(Classes.Point(0, ParameterPanelHeight));
    TextLabel.SetTextAlignY(tayCenterEx);
    if TextLabel.ClientSize.Y < 10 then
      TextLabel.SetSize(Classes.Point(TextLabel.ClientSize.X, TextLabel.ClientSize.Y + 10));
    Inc(ParameterPanelHeight, TextLabel.ClientSize.Y);
    TextLabel.UserData := PtrInt(FixedWidth);
    if FixedWidth then
      Inc(ParameterPanelHeight, 2);
    ParameterPanelWidth := Max(ParameterPanelWidth, TextLabel.ClientSize.X);
    Lines.Next;
  end;
  Lines.Free;
end;

procedure TfPlanetQuest.LayoutParameterPanel;
var
  Window: TWindowGI;
  Panel: TPanelGI;
  Control: TObjectGI;
  Y: Integer;
begin
  Window := GetByName('ParamsShowWindowParent') as TWindowGI;
  Panel := GetByName('ParamsShowWindow') as TPanelGI;
  Window.SetPosition(ParameterPanelOrigin);
  Window.SetSize(
      Classes.Point(
          ParameterPanelWidth + Window.WorkSubRect.Left + Window.WorkSubRect.Right,
          ParameterPanelHeight + Window.WorkSubRect.Top + Window.WorkSubRect.Bottom
      )
  );
  Window.UpdateAutoGeometry;
  Panel.SetSize(Window.ClientSize);
  Y := 0;
  Control := Panel.FirstChild;
  while Control <> nil do
  begin
    Control.SetPosition(
        Classes.Point(
            Window.WorkSubRect.Left,
            (Window.ClientSize.Y
                        - Window.WorkSubRect.Top
                        - Window.WorkSubRect.Bottom
                        - ParameterPanelHeight)
                    div 2
                + (Window.WorkSubRect.Top + Y)
        )
    );
    Inc(Y, Control.ClientSize.Y);
    if Control.UserData <> 0 then
      Inc(Y, 2);
    Control := Control.NextSibling;
  end;
  if GameScreenHeight - GiScalePixels(30) < Window.LocalPosition.Y + Window.ClientSize.Y then
    Window.SetPosition(
        Classes.Point(
            Window.LocalPosition.X,
            GameScreenHeight - GiScalePixels(30) - Window.ClientSize.Y
        )
    );
  if GameScreenWidth - GiScalePixels(10) < Window.LocalPosition.X + Window.ClientSize.X then
    Window.SetPosition(
        Classes.Point(
            GameScreenWidth - GiScalePixels(10) - Window.ClientSize.X,
            Window.LocalPosition.Y
        )
    );
  LayoutMobilePage;
end;

procedure TfPlanetQuest.SetQuestText(const Text: WideString);
var
  Panel: TPanelScrollBarGI;
  NextTop: Integer;
  LowerText: WideString;
  StartIndex, TagIndex, TextLength: Integer;

  procedure AddQuestTextParagraph(const Text: WideString; FontMode: Integer);
  var
    Indent: Boolean;
    I: Integer;
    TextLabel: TQuestTextGI;
  begin
    if Text <> '' then
    begin
      Indent := False;
      if FontMode = 0 then
      begin
        Indent := True;
        I := 0;
        while I < Length(Text) do
        begin
          if PWideChar(Pointer(Text))[I] = '-' then
          begin
            Indent := False;
            Break;
          end
          else
          begin
            if (PWideChar(Pointer(Text))[I] <> ' ') and (PWideChar(Pointer(Text))[I] <> #9) then
              Break;
            Inc(I);
          end;
        end;
      end;
      TextLabel := TQuestTextGI.Create(Panel);
      TextLabel.FixedBlock := FontMode <> 0;
      if FontMode = 0 then
        TextLabel.SetFontName(GetQuestFontName)
      else
        TextLabel.SetFontName('Font.' + GiResourceSuffix + 'Fix');
      TextLabel.SetPosition(Point(0, NextTop));
      TextLabel.SetSize(Point(Panel.ClientSize.X, 1));
      TextLabel.SetWordWrapEnabled(FontMode = 0);
      if (MobileArtwork <> nil) or (FontMode <> 0) then
        TextLabel.SetTextAlignX(taxLeft)
      else
        TextLabel.SetTextAlignX(taxAuto);
      TextLabel.SetTextAlignY(tayAuto);
      if Indent then
        TextLabel.SetText('     ' + Text)
      else
        TextLabel.SetText(Text);
      TextLabel.SetPositionModeW(True);
      TextLabel.SetTextColor(GetTextColor(QuestStyleIndex));
      TextLabel.SetTextAlignY(tayTop);
      TextLabel.FitWidth(Panel.ClientSize.X);
      NextTop := TextLabel.LocalPosition.Y + TextLabel.LayoutHeight - 2;
    end;
  end;

  procedure AddQuestTextLines(const Text: WideString; FontMode: Integer);
  var
    N, StartIndex, EndIndex: Integer;
  begin
    if FontMode <> 0 then
    begin
      AddQuestTextParagraph(Text, FontMode);
      Exit;
    end;
    N := Length(Text);
    StartIndex := 0;
    while StartIndex < N do
    begin
      EndIndex := FindTextOffsetW(Text, #10, StartIndex);
      if EndIndex < 0 then
      begin
        AddQuestTextParagraph(Copy(Text, StartIndex + 1, N - StartIndex), FontMode);
        Break;
      end;
      AddQuestTextParagraph(Copy(Text, StartIndex + 1, EndIndex - StartIndex + 1), FontMode);
      StartIndex := EndIndex + 1;
    end;
  end;

begin
  CurrentText := Text;
  Panel := GetByName('MessageWindow') as TPanelScrollBarGI;
  Panel.FreeOwnedChildren;
  if Text <> '' then
  begin
    NextTop := 0;
    TextLength := Length(Text);
    LowerText := LowerCaseWideString(Text);
    StartIndex := 0;
    while StartIndex < TextLength do
    begin
      TagIndex := FindTextOffsetW(LowerText, '<fix>', StartIndex);
      if StartIndex < TagIndex then
        AddQuestTextLines(Copy(Text, StartIndex + 1, TagIndex - StartIndex), 0);
      if TagIndex >= 0 then
      begin
        Inc(TagIndex, 5);
        if (TagIndex < TextLength) and (Text[TagIndex + 1] = #13) then
          Inc(TagIndex);
        if (TagIndex < TextLength) and (Text[TagIndex + 1] = #10) then
          Inc(TagIndex);
        StartIndex := TagIndex;
        TagIndex := FindTextOffsetW(LowerText, '</fix>', StartIndex);
        if StartIndex < TagIndex then
          AddQuestTextLines(Copy(Text, StartIndex + 1, TagIndex - StartIndex), 1);
        if TagIndex >= 0 then
        begin
          Inc(TagIndex, 6);
          while (TagIndex < TextLength)
              and ((Text[TagIndex + 1] = ' ')
                  or (Text[TagIndex + 1] = #9)
                  or (Text[TagIndex + 1] = #13)) do
            Inc(TagIndex);
          if TagIndex < TextLength then
            if Text[TagIndex + 1] = #10 then
              Inc(TagIndex);
          StartIndex := TagIndex;
        end
        else
        begin
          AddQuestTextLines(Copy(Text, StartIndex + 1, TextLength - StartIndex), 1);
          Break;
        end;
      end
      else
      begin
        AddQuestTextLines(Copy(Text, StartIndex + 1, TextLength - StartIndex), 0);
        Break;
      end;
    end;
    Panel.SetScrollOffset(Point(0, 0));
    Panel.SetVerticalScrollbarEnabled(Panel.ClientSize.Y < NextTop);
    if Panel.FirstChild <> nil then
      Panel.VerticalScrollbar.SetSmallChange((Panel.FirstChild as TLabelGI).GetLineHeight);
    Panel.VerticalScrollbar.SetLargeChange(Panel.ClientSize.Y);
    Panel.VerticalScrollbar.SetPageSize(Panel.ClientSize.Y);
    Panel.UpdateScrollRanges;
    Panel.Invalidate;
  end;
end;

procedure TfPlanetQuest.InitializeLayout;
var
  I, Shift: Integer;
  Control: TObjectGI;
begin
  MobileArtwork := nil;
  MobileStatsToggle := nil;
  MobileStatsExpanded := False;
  ChoicePadding := 10;
  inherited InitializeLayout;
  AppendLogTextThreadSafe('fPlanetQuest... ');
  ViewportRect := Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('ImageFrame') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y));
    with FindByNameRecursive('PQI') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y));
    with FindByNameRecursive('AnimTextOn') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight));
    with FindByNameRecursive('AnimTextOff') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight));
    for I := 1 to 4 do
      with FindByNameRecursive('Style' + IntToStr(I)) do
        SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight));
    with FindByNameRecursive('ButtonExit') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight));
    I := 0;
    Shift := 39;
    if ExtraScreenWidth < Shift then
      I := Shift - ExtraScreenWidth;
    Shift := Shift - I;
    with FindByNameRecursive('BGStyle') do
    begin
      SetPosition(Point(LocalPosition.X + Shift, LocalPosition.Y));
      SetSize(Point(ClientSize.X + (ExtraScreenWidth - Shift), ClientSize.Y + ExtraScreenHeight));
    end;
    with FindByNameRecursive('BGImage') do
      SetPosition(Point(GameScreenWidth - ClientSize.X, LocalPosition.Y));
    with FindByNameRecursive('PanelImage') do
      if (ExtraScreenWidth > 0) or (ExtraScreenHeight > 0) then
      begin
        SetPosition(Point(0, LocalPosition.Y));
        SetSize(Point(GameScreenWidth, GameScreenHeight));
      end
      else
        SetSize(Point(ClientSize.X, GameScreenHeight));
    with FindByNameRecursive('QuestPanel') do
    begin
      SetSize(Point(GameScreenWidth, GameScreenHeight));
      with FindByNameRecursive('MessageWindow') as TPanelScrollBarGI do
      begin
        SetPosition(Point(LocalPosition.X + Shift, LocalPosition.Y));
        SetSize(
            Point(ClientSize.X + (ExtraScreenWidth - Shift), ClientSize.Y + ExtraScreenHeight div 2)
        );
        TObjectGI(VerticalScrollbar)
            .SetPosition(
                Point(
                    VerticalScrollbar.LocalPosition.X + ExtraScreenWidth,
                    VerticalScrollbar.LocalPosition.Y
                ));
        VerticalScrollbar.SetSize(
            Point(
                VerticalScrollbar.ClientSize.X,
                VerticalScrollbar.ClientSize.Y + ExtraScreenHeight div 2
            )
        );
      end;
      with FindByNameRecursive('ActionListWindow') as TPanelScrollBarGI do
      begin
        SetPosition(Point(LocalPosition.X + Shift, LocalPosition.Y + ExtraScreenHeight div 2));
        SetSize(
            Point(ClientSize.X + (ExtraScreenWidth - Shift), ClientSize.Y + ExtraScreenHeight div 2)
        );
        TObjectGI(VerticalScrollbar)
            .SetPosition(
                Point(
                    VerticalScrollbar.LocalPosition.X + ExtraScreenWidth,
                    VerticalScrollbar.LocalPosition.Y
                ));
        VerticalScrollbar.SetSize(
            Point(
                VerticalScrollbar.ClientSize.X,
                VerticalScrollbar.ClientSize.Y + ExtraScreenHeight div 2
            )
        );
      end;
    end;
    with FindByNameRecursive('LabelHelp') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y + ExtraScreenHeight));
    with FindByNameRecursive('ParamsShowWindowParent') do
      SetPosition(Point(LocalPosition.X + ExtraScreenWidth, LocalPosition.Y));
  end;
  AppendLogLineThreadSafe('ok');
  ParameterPanelOrigin := GetByName('ParamsShowWindowParent').LocalPosition;
  InitializeMobileLayout;
  SetHelpCallback(ShowControlHelp);
  with GetByName('AnimTextOn') as TGraphButtonGI do
  begin
    UserValue := 0;
    UpCallback := SelectPageMode;
  end;
  with GetByName('AnimTextOff') as TGraphButtonGI do
  begin
    UserValue := 1;
    UpCallback := SelectPageMode;
  end;
  I := 1;
  while True do
  begin
    Control := FindControlByPath('Style' + IntToWideString(I));
    if Control = nil then
      Break;
    with Control as TGraphButtonGI do
    begin
      UserValue := I - 1;
      UpCallback := SelectStyle;
      DownCallback := SelectStyle;
    end;
    Inc(I);
  end;
  QuestStyleCount := I - 1;
  GetByName('MainPanel').KeyDownCallback := QuestKeyDown;
  (GetByName('ButtonExit') as TGraphButtonGI).UpCallback := RequestLoadGame;
  QuestPlayerInterface := TTextQuestPlayerInterface.Create;
end;

procedure TfPlanetQuest.InitializeMobileLayout;
var
  I: Integer;
  Root: TObjectGI;
begin
  if not GameMobileUiEnabled or not HardwareRenderingEnabled then
    Exit;
  Root := GetByName('MainPanel');
  MobileTextScale := GetGameMobileUiScale(1.15);
  ChoicePadding := 4;
  MobileTextBounds := Rect(12, 12, GameScreenWidth - 12, GameScreenHeight);
  MobileSidebarBounds := Rect(GameScreenWidth - 12, 12, GameScreenWidth - 12, GameScreenHeight);
  MobileStylePositions[0] := GetByName('AnimTextOn').LocalPosition;
  MobileStylePositions[1] := GetByName('AnimTextOff').LocalPosition;
  for I := 1 to 4 do
    MobileStylePositions[I + 1] := GetByName('Style' + IntToStr(I)).LocalPosition;
  MobileArtwork := TQuestArtworkGI.Create(Root);
  MobileArtwork.SetDepth(8.5);
  MobileStatsToggle := TQuestStatsActionGI.Create(Root, MobileArtwork);
  MobileStatsToggle.SetName('ParamsExpand');
  MobileStatsToggle.SetCaptionFontName(SmoothBigFontName);
  MobileStatsToggle.SetSize(Point(152, 32));
  MobileStatsToggle.SetCaptionColor(CurrentPixelFormat.PackRgbBytes(9, 26, 31));
  MobileStatsToggle.MouseBlocking := True;
  MobileStatsToggle.UpCallback := StatsButtonClick;
  LayoutMobileControls;
  GetByName('BGImage').SetActive(False);
  GetByName('PanelImage').SetActive(False);
  GetByName('BGStyle').SetActive(False);
  GetByName('ImageFrame').SetActive(False);
  (GetByName('MessageWindow') as TPanelScrollBarGI).VerticalScrollBar.SetIndicatorThickness(2);
  (GetByName('ActionListWindow') as TPanelScrollBarGI).VerticalScrollBar.SetIndicatorThickness(2);
  // Both scroll panels and their external scrollbars share this transform.
  // Their text, row positions and scrolling stay in the same source coordinates.
  with GetByName('QuestPanel') do
  begin
    DisplayScale := MobileTextScale;
    SetSize(
        Point(Ceil(GameScreenWidth / MobileTextScale), Ceil(GameScreenHeight / MobileTextScale))
    );
  end;
  LayoutMobilePage;
end;

procedure TfPlanetQuest.LayoutMobileControls;
var
  Scale, ExitScale: Single;
  Origin: TPoint;
  StyleBounds, ExitBounds: TRect;
  Control: TGraphButtonGI;
  I, Width, Height, ExitHeight, FooterGap: Integer;

  procedure PlaceStyleButton(const Name: WideString; Index: Integer);
  var
    Button: TGraphButtonGI;
  begin
    Button := GetByName(Name) as TGraphButtonGI;
    PlaceControlAtScreen(
        Button,
        Point(
            StyleBounds.Left + Round((MobileStylePositions[Index].X - Origin.X) * Scale),
            StyleBounds.Top + Round((MobileStylePositions[Index].Y - Origin.Y) * Scale)
        ),
        Scale
    );
    Button.HitKind := gbhRect;
  end;

begin
  // Keep the native icons and spacing, with a separate scale from quest text.
  Scale :=
      Min(
          GetGameMobileUiScale(30) / GetByName('AnimTextOn').ClientSize.Y,
          Min(
              (MobileTextBounds.Right - MobileTextBounds.Left - 24) / 116,
              (GameScreenHeight div 6 - 20) / GetByName('AnimTextOn').ClientSize.Y
          )
      );
  Origin := MobileStylePositions[0];
  Control := GetByName('Style4') as TGraphButtonGI;
  Width := Round((MobileStylePositions[5].X + Control.ClientSize.X - Origin.X) * Scale);
  Height := Round(GetByName('AnimTextOn').ClientSize.Y * Scale);
  // The original backing extends left of the first icon by seven source pixels.
  StyleBounds.Left := Ceil(8 * GetGameMobileUiScale + 8 * Scale);
  StyleBounds.Top := GameScreenHeight - 12 - Height;
  StyleBounds.Right := StyleBounds.Left + Width;
  StyleBounds.Bottom := StyleBounds.Top + Height;
  FooterGap := Ceil(6 * GetGameMobileUiScale);
  // Appearance controls are infrequent actions; the story can use the height
  // returned by their smaller plate. Exit keeps its independent touch size.
  MobileTextBounds.Bottom := StyleBounds.Top - FooterGap;
  PlaceStyleButton('AnimTextOn', 0);
  PlaceStyleButton('AnimTextOff', 1);
  for I := 1 to 4 do
    PlaceStyleButton('Style' + IntToStr(I), I + 1);
  Control := GetByName('ButtonExit') as TGraphButtonGI;
  ExitHeight := Min(Ceil(GetGameMobileUiScale(44)), GameScreenHeight div 6 - 20);
  ExitScale := ExitHeight / Max(1, Control.ClientSize.Y);
  Width := Round(Control.ClientSize.X * ExitScale);
  ExitBounds :=
      Rect(
          GameScreenWidth - 12 - Width,
          GameScreenHeight - 12 - ExitHeight,
          GameScreenWidth - 12,
          GameScreenHeight - 12
      );
  MobileSidebarBounds.Bottom := ExitBounds.Top - FooterGap;
  PlaceControlAtScreen(Control, ExitBounds.TopLeft, ExitScale);
  Control.HitKind := gbhRect;
  MobileArtwork.SetControlLayout(StyleBounds);
end;

procedure TfPlanetQuest.ReflowMobileText;
var
  Panel: TPanelScrollBarGI;
  Child: TObjectGI;
  Text: TQuestTextGI;
  NextTop, AnimationOffset: Integer;
begin
  Panel := GetByName('MessageWindow') as TPanelScrollBarGI;
  NextTop := 0;
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    if Child is TQuestTextGI then
    begin
      Text := TQuestTextGI(Child);
      AnimationOffset := 0;
      if PageAnimationTimer <> nil then
        AnimationOffset := Min(0, Text.LocalPosition.Y - Text.UserIndex);
      Text.FitWidth(Panel.ClientSize.X);
      Text.UserIndex := NextTop;
      Text.SetPosition(Point(0, NextTop + AnimationOffset));
      Inc(NextTop, Text.LayoutHeight - 2);
    end;
    Child := Child.NextSibling;
  end;
end;

procedure TfPlanetQuest.ReflowMobileChoices;
var
  Panel: TPanelScrollBarGI;
  Child: TObjectGI;
  Text: TLabelGI;
begin
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  NextChoiceTop := ChoicePadding;
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    // Choice rows own a highlight image followed by their text label. Spacers
    // and external scrollbars are not rows and must not affect text measurement.
    if (Child.FirstChild is TImageGI) and (Child.FirstChild.NextSibling is TLabelGI) then
    begin
      Text := Child.FirstChild.NextSibling as TLabelGI;
      Text.SetTextAlignY(tayAuto);
      Text.SetSize(Point(Panel.ClientSize.X - 20, 1));
      Child.SetPosition(Point(0, NextChoiceTop));
      Child.SetSize(Point(Panel.ClientSize.X, Text.ClientSize.Y + GiScalePixelsEx(2, 1) * 2));
      Text.SetTextAlignY(tayCenterEx);
      Text.SetSize(Point(Text.ClientSize.X, Child.ClientSize.Y));
      Child.FirstChild.SetSize(Child.ClientSize);
      Inc(NextChoiceTop, Child.ClientSize.Y);
    end;
    Child := Child.NextSibling;
  end;
  if ChoicesFinalized then
    Inc(NextChoiceTop, ChoicePadding);
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    if (Child is TPanelGI) and (Child.FirstChild = nil) and (Child.LocalPosition.Y > 0) then
      Child.SetPosition(Point(0, NextChoiceTop - ChoicePadding));
    Child := Child.NextSibling;
  end;
end;

procedure TfPlanetQuest.StatsButtonClick(Sender: TObjectGI);
begin
  if (MobileArtwork = nil) or not MobileStatsToggle.Active then
    Exit;
  MobileStatsExpanded := not MobileStatsExpanded;
  LayoutMobilePage;
end;

procedure TfPlanetQuest.LayoutMobilePage;
const
  Gap = 12;
  Padding = 6;
  ScrollbarWidth = 2;
var
  Window: TWindowGI;
  Picture: TGraphBufGI;
  MessagePanel, ChoicesPanel: TPanelScrollBarGI;
  TextFrame, ChoicesFrame, PictureFrame, Inner, StatsBounds, ExpandedStatsBounds: TRect;
  Scale, PictureScale, CompactScale, ExpandedScale, ActionScale: Single;
  StatsPosition: TPoint;
  ChoiceHeight,
  MinChoiceHeight,
  ChoiceBottom,
  StatsTop,
  PictureHeight,
  PictureWidth,
  ContentHeight,
  SidebarWidth,
  ActionHeight,
  OldTextWidth,
  OldChoiceWidth: Integer;
  HasStats, HasPicture, CanEnlarge: Boolean;
  Child: TObjectGI;

  procedure PlaceScrollPanel(
      Panel: TPanelScrollBarGI;
      Frame, Insets: TRect;
      Story: Boolean;
      MeasureWidthOnly: Boolean = False
  );
  var
    Left, Top, Right, Bottom: Integer;
  begin
    // Frame and insets are game-screen units; the text subtree uses source units.
    Left := Ceil((Frame.Left + Insets.Left) / Double(MobileTextScale)) + Padding;
    Top := Ceil((Frame.Top + Insets.Top) / Double(MobileTextScale)) + Padding;
    // Leave room for the Android Controls toggle above the first story line.
    if Story then
      Top := Max(Top, Ceil(56 * GetGameMobileUiScale / MobileTextScale));
    Right := Floor((Frame.Right - Insets.Right) / Double(MobileTextScale)) - Padding;
    Bottom := Floor((Frame.Bottom - Insets.Bottom) / Double(MobileTextScale)) - Padding;
    if MeasureWidthOnly then
    begin
      // Measuring a different width must not temporarily enlarge the viewport:
      // scrollbar page-size clamping would discard the reader's scroll position.
      Panel.SetSize(Point(Max(1, Right - Left - Padding - ScrollbarWidth), Panel.ClientSize.Y));
      Exit;
    end;
    Panel.AutoVerticalPlacement := False;
    Panel.VerticalScrollBarRect := Rect(Right - ScrollbarWidth, Top, Right, Bottom);
    Panel.SetPosition(Point(Left, Top));
    Panel.SetSize(Point(Max(1, Right - Left - Padding - ScrollbarWidth), Max(1, Bottom - Top)));
    Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
    Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
    if not Story or (PageAnimationTimer = nil) then
      Panel.UpdateScrollRanges;
  end;

begin
  if MobileArtwork = nil then
    Exit;
  Window := GetByName('ParamsShowWindowParent') as TWindowGI;
  Picture := GetByName('PQI') as TGraphBufGI;
  HasStats := GetByName('ParamsShowWindow').FirstChild <> nil;
  HasPicture :=
      (CurrentPicture <> '') and (Picture.GraphBuf.Width > 0) and (Picture.GraphBuf.Height > 0);
  // Reserve only the width the current state needs. Illustrations can use a
  // modest thumbnail; short statistics must not permanently take a third of a page.
  SidebarWidth := 0;
  if HasStats then
    SidebarWidth := Ceil(Window.ClientSize.X * MobileTextScale);
  if HasPicture then
    SidebarWidth := Max(SidebarWidth, Round(GameScreenWidth * 0.25));
  SidebarWidth := Min(SidebarWidth, Round(GameScreenWidth * 0.36));
  MobileTextBounds.Right := GameScreenWidth - 12;
  if SidebarWidth > 0 then
    Dec(MobileTextBounds.Right, SidebarWidth + Gap);
  MobileSidebarBounds.Left := MobileTextBounds.Right + Gap;
  LayoutMobileControls;
  if not HasStats then
    MobileStatsExpanded := False;
  Window.SetActive(HasStats);
  MobileStatsToggle.SetActive(False);
  (GetByName('QuestPanel') as TPanelGI).SetActive(not MobileStatsExpanded);
  ExpandedStatsBounds :=
      Rect(
          12,
          Max(12, Ceil(56 * GetGameMobileUiScale)),
          GameScreenWidth - 12,
          MobileSidebarBounds.Bottom
      );
  StatsBounds := MobileSidebarBounds;
  if MobileStatsExpanded then
    StatsBounds := ExpandedStatsBounds;
  StatsTop := MobileSidebarBounds.Bottom + Gap;
  if HasStats then
  begin
    ActionScale := GetGameMobileUiScale;
    ActionHeight := Ceil((MobileStatsToggle.ClientSize.Y + 4) * ActionScale);
    CompactScale :=
        Min(
            MobileTextScale,
            Min(
                (MobileSidebarBounds.Right - MobileSidebarBounds.Left) / Window.ClientSize.X,
                (MobileSidebarBounds.Bottom - MobileSidebarBounds.Top) / Window.ClientSize.Y
            )
        );
    ExpandedScale :=
        Min(
            MobileTextScale,
            Min(
                (ExpandedStatsBounds.Right - ExpandedStatsBounds.Left) / Window.ClientSize.X,
                (ExpandedStatsBounds.Bottom - ExpandedStatsBounds.Top - ActionHeight)
                    / Window.ClientSize.Y
            )
        );
    // The whole state is already visible. Offer magnification only when its
    // text is small and the larger view materially improves readability.
    CanEnlarge :=
        (CompactScale < GetGameMobileUiScale(0.9)) and (ExpandedScale >= CompactScale * 1.25);
    MobileStatsToggle.SetActive(CanEnlarge or MobileStatsExpanded);
    if LowerCaseWideString(SelectedLanguage) = 'russian' then
    begin
      if MobileStatsExpanded then
        MobileStatsToggle.SetCaption('К тексту')
      else
        MobileStatsToggle.SetCaption('Увеличить');
    end
    else if MobileStatsExpanded then
      MobileStatsToggle.SetCaption('Back to text')
    else
      MobileStatsToggle.SetCaption('Enlarge');
    // Keep every row/column at the previous compact scale. The useful-gain check
    // also ensures that this frame and its action fit without shrinking text.
    if MobileStatsExpanded then
      Scale := ExpandedScale
    else
      Scale := CompactScale;
    if not MobileStatsToggle.Active then
      ActionHeight := 0;
    StatsTop := StatsBounds.Bottom - Ceil(Window.ClientSize.Y * Scale) - ActionHeight;
    if MobileStatsExpanded then
      StatsTop :=
          (StatsBounds.Top + StatsBounds.Bottom - Ceil(Window.ClientSize.Y * Scale) - ActionHeight)
              div 2;
    StatsPosition :=
        Point(
            (StatsBounds.Left + StatsBounds.Right - Ceil(Window.ClientSize.X * Scale)) div 2,
            StatsTop
        );
    PlaceControlAtScreen(Window, StatsPosition, Scale);
    if MobileStatsToggle.Active then
    begin
      MobileStatsToggle
          .SetSize(Point(Min(152, Floor(Window.ClientSize.X * Scale / ActionScale)), 32));
      PlaceControlAtScreen(
          MobileStatsToggle,
          Point(
              StatsPosition.X,
              StatsTop + Ceil(Window.ClientSize.Y * Scale) + Ceil(4 * ActionScale)
          ),
          ActionScale
      );
    end;
  end;
  if MobileStatsExpanded then
  begin
    Picture.SetActive(False);
    MobileArtwork.SetLayout(Rect(0, 0, 0, 0), Rect(0, 0, 0, 0), Rect(0, 0, 0, 0), QuestStyleIndex);
    InvalidateViewport;
    Exit;
  end;
  // The illustration uses only the room left above statistics, preserving aspect.
  PictureFrame := Rect(0, 0, 0, 0);
  PictureHeight := StatsTop - Gap - MobileSidebarBounds.Top;
  if HasPicture and (PictureHeight >= 102) then
  begin
    PictureWidth :=
        Min(
            MobileSidebarBounds.Right - MobileSidebarBounds.Left,
            Floor((PictureHeight - 20) * Picture.GraphBuf.Width / Picture.GraphBuf.Height) + 20
        );
    PictureHeight :=
        Min(
            PictureHeight,
            Floor((PictureWidth - 20) * Picture.GraphBuf.Height / Picture.GraphBuf.Width) + 20
        );
    // Preserve the original gold corner shapes; omit a thumbnail too small for them.
    if (PictureWidth >= 100) and (PictureHeight >= 102) then
    begin
      PictureFrame.Left :=
          (MobileSidebarBounds.Left + MobileSidebarBounds.Right - PictureWidth) div 2;
      PictureFrame.Top := MobileSidebarBounds.Top;
      PictureFrame.Right := PictureFrame.Left + PictureWidth;
      PictureFrame.Bottom := PictureFrame.Top + PictureHeight;
    end;
  end;
  MessagePanel := GetByName('MessageWindow') as TPanelScrollBarGI;
  ChoicesPanel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  TextFrame := MobileTextBounds;
  ChoicesFrame := MobileTextBounds;
  OldTextWidth := MessagePanel.ClientSize.X;
  OldChoiceWidth := ChoicesPanel.ClientSize.X;
  PlaceScrollPanel(MessagePanel, TextFrame, MobileArtwork.TextInsets, True, True);
  PlaceScrollPanel(ChoicesPanel, ChoicesFrame, MobileArtwork.ChoiceInsets, False, True);
  if MessagePanel.ClientSize.X <> OldTextWidth then
    ReflowMobileText;
  if ChoicesPanel.ClientSize.X <> OldChoiceWidth then
    ReflowMobileChoices;
  // Match PlaceScrollPanel's rounded endpoints, not just their distance.
  // A height rounded independently can lose one source pixel and enable scrolling.
  ChoiceBottom :=
      Floor((ChoicesFrame.Bottom - MobileArtwork.ChoiceInsets.Bottom) / Double(MobileTextScale));
  MinChoiceHeight :=
      ChoicesFrame.Bottom
          - Floor((ChoiceBottom - NextChoiceTop - Padding * 2) * Double(MobileTextScale))
          + MobileArtwork.ChoiceInsets.Top;
  ChoiceHeight :=
      Min(Max(80, MinChoiceHeight), (MobileTextBounds.Bottom - MobileTextBounds.Top) * 2 div 5);
  ChoicesFrame.Top := ChoicesFrame.Bottom - ChoiceHeight;
  TextFrame.Bottom := ChoicesFrame.Top - Gap;
  MobileArtwork.SetLayout(TextFrame, ChoicesFrame, PictureFrame, QuestStyleIndex);
  PlaceScrollPanel(MessagePanel, TextFrame, MobileArtwork.TextInsets, True);
  PlaceScrollPanel(ChoicesPanel, ChoicesFrame, MobileArtwork.ChoiceInsets, False);
  ContentHeight := 0;
  Child := MessagePanel.FirstChild;
  while Child <> nil do
  begin
    if Child is TQuestTextGI then
    begin
      if PageAnimationTimer <> nil then
        ContentHeight :=
            Max(
                ContentHeight,
                Max(Child.LocalPosition.Y, Child.UserIndex) + TQuestTextGI(Child).LayoutHeight
            )
      else
        ContentHeight :=
            Max(ContentHeight, Child.LocalPosition.Y + TQuestTextGI(Child).LayoutHeight);
    end
    else
      ContentHeight := Max(ContentHeight, Child.LocalPosition.Y + Child.ClientSize.Y);
    Child := Child.NextSibling;
  end;
  if not MessagePanel.UnlimitedWorld then
    MessagePanel.SetScrollOffset(
        Point(
            0,
            EnsureRange(
                MessagePanel.ScrollOffset.Y,
                0,
                Max(0, ContentHeight - MessagePanel.ClientSize.Y)
            )
        )
    );
  MessagePanel.SetVerticalScrollbarEnabled(ContentHeight > MessagePanel.ClientSize.Y);
  ChoicesPanel.SetVerticalScrollbarEnabled(NextChoiceTop > ChoicesPanel.ClientSize.Y);
  Inner := MobileArtwork.PictureInnerBounds;
  Picture.SetActive(HasPicture and (Inner.Right > Inner.Left) and (Inner.Bottom > Inner.Top));
  if Picture.Active then
  begin
    PictureScale :=
        Min(
            (Inner.Right - Inner.Left) / Picture.GraphBuf.Width,
            (Inner.Bottom - Inner.Top) / Picture.GraphBuf.Height
        );
    Picture.SetSize(Point(Picture.GraphBuf.Width, Picture.GraphBuf.Height));
    PlaceControlAtScreen(
        Picture,
        Point(
            (Inner.Left + Inner.Right - Round(Picture.GraphBuf.Width * PictureScale)) div 2,
            (Inner.Top + Inner.Bottom - Round(Picture.GraphBuf.Height * PictureScale)) div 2
        ),
        PictureScale
    );
  end;
  InvalidateViewport;
end;

procedure TfPlanetQuest.OnOpen;
var
  I, J: Integer;
  GovernmentQuest: PQuest;
  Found: Boolean;
  Stage: Integer;
begin
  Stage := 0;
  try
    SelectMusic;
    ActiveQueuedTextQuest := nil;
    if Galaxy <> nil then
      EvictMainMenuShipCachesWhenAddressSpaceHigh;
    Stage := 1;
    if GetPlayer <> nil then
      GetPlayer.ScriptItemsAct(satOnEnteringForm, nil, nil, 0);
    Stage := 2;
    if (QuestStyleIndex < 0) or (QuestStyleIndex >= QuestStyleCount) then
      QuestStyleIndex := 0;
    GetByName('PQI').SetActive(False);
    CurrentPicture := '';
    (GetByName('QuestPanel') as TPanelGI).SetActive(True);
    Stage := 3;
    ClearChoices;
    SetQuestText('');
    ClearParameterPanel;
    LayoutParameterPanel;
    Stage := 4;
    if (QueuedTextQuests.Count = 0)
        and (GetPlayer <> nil)
        and (GetPlayer.CurrentPlanet <> nil)
        and (GetPlayer.CurrentPlanet.TextQuestId >= FirstLicensedQuestId)
        and ((LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') <= 0)
            or (LanguageDataConfig
                    .GetBlock('PlanetQuest')
                    .GetBlock('PlanetQuestLic')
                    .GetParamOrMarker(IntToStr(GetPlayer.CurrentPlanet.TextQuestId))
                = PlanetQuestScreen.GetQuestContentHash(GetPlayer.CurrentPlanet.TextQuestId))) then
      MoneyLimitComplement :=
          (Galaxy.ComputeScaledBigMoney(oiHuman) + GetPlayer.Money) xor $FFFFFFFF
    else if (GetPlayer <> nil) and (QueuedTextQuests.Count = 0) then
      MoneyLimitComplement := (GetPlayer.Money + 50000) xor $FFFFFFFF
    else
      MoneyLimitComplement := 1000000000 xor $FFFFFFFF;
    Stage := 5;
    if (GetPlayer <> nil) and (GetPlayer.CurrentPlanet <> nil) and GetPlayer.InPrison then
    begin
      Stage := 6;
      Quest := TTextQuest.Create;
      if GetPlayer.CurrentPlanet.OwnerId <> oiPirate then
        LoadQuestByName('Prison')
      else
        LoadQuestByName('PirateClanPrison');
      Stage := 7;
      Quest.ToStarText.Text := GetPlayer.CurrentStar.Name;
      Quest.ToPlanetText.Text := GetPlayer.CurrentPlanet.Name;
      Quest.DateText.Text := '';
      Quest.MoneyText.Text := '';
      Quest.FromPlanetText.Text := GetPlayer.CurrentPlanet.Name;
      Quest.FromStarText.Text := GetPlayer.CurrentStar.Name;
      Quest.RangerText.Text := GetPlayer.Name;
      Stage := 8;
      StartLoadedQuest;
      Stage := 9;
    end
    else if QueuedTextQuests.Count > 0 then
    begin
      Stage := 10;
      ActiveQueuedTextQuest := QueuedTextQuests[0];
      Quest := TTextQuest.Create;
      if IsIntegerTextW(ActiveQueuedTextQuest.Name) then
        LoadQuestById(StrToInt(ActiveQueuedTextQuest.Name))
      else
        LoadQuestByName(ActiveQueuedTextQuest.Name);
      Stage := 11;
      if GetPlayer.CurrentStar <> nil then
      begin
        Quest.ToStarText.Text := GetPlayer.CurrentStar.Name;
        Quest.FromStarText.Text := GetPlayer.CurrentStar.Name;
      end
      else
      begin
        Quest.ToStarText.Text := '';
        Quest.FromStarText.Text := '';
      end;
      if GetPlayer.CurrentPlanet <> nil then
      begin
        Quest.ToPlanetText.Text := GetPlayer.CurrentPlanet.Name;
        Quest.FromPlanetText.Text := GetPlayer.CurrentPlanet.Name;
      end
      else
      begin
        Quest.ToPlanetText.Text := '';
        Quest.FromPlanetText.Text := '';
      end;
      Quest.DateText.Text := '';
      Quest.MoneyText.Text := '';
      Quest.RangerText.Text := GetPlayer.Name;
      Stage := 12;
      StartLoadedQuest;
      Stage := 13;
    end
    else if (GetPlayer <> nil) and not StandaloneQuestMode then
    begin
      Stage := 14;
      Found := False;
      if GetPlayer.CurrentPlanet.TextQuestId > -1 then
        if GetPlayer.Quests.Count > 0 then
          for I := 0 to GetPlayer.Quests.Count - 1 do
          begin
            GovernmentQuest := GetPlayer.Quests[I];
            if (GovernmentQuest.QuestType = qtPlanetQuest)
                and (GovernmentQuest.ObjectiveTarget is TPlanet)
                and ((GovernmentQuest.ObjectiveTarget as TPlanet) = GetPlayer.CurrentPlanet) then
            begin
              Stage := 15;
              ActiveGovernmentQuest := GovernmentQuest;
              Quest := TTextQuest.Create;
              LoadQuestById(GetPlayer.CurrentPlanet.TextQuestId);
              Stage := 16;
              Quest.ToStarText.Text := GetPlayer.CurrentStar.Name;
              Quest.ToPlanetText.Text := GetPlayer.CurrentPlanet.Name;
              Quest.DateText.Text := Galaxy.FormatTurnDate(GovernmentQuest.DeadlineTurn);
              Quest.MoneyText.Text := IntToStr(GovernmentQuest.RewardMoney);
              Quest.FromPlanetText.Text := GovernmentQuest.Planet.Name;
              Quest.FromStarText.Text := GovernmentQuest.Planet.CurrentStar.Name;
              Quest.RangerText.Text := GetPlayer.Name;
              for J := 1 to Quest.GetParameterCount do
                if Quest.GetParameter(J).Enabled
                    and (Quest.GetParameter(J).NameText.Text = 'GRewardMoney') then
                begin
                  Quest.GetParameter(J).Value := GovernmentQuest.RewardMoney;
                  Break;
                end;
              Stage := 17;
              StartLoadedQuest;
              Stage := 18;
              Found := True;
              Break;
            end;
          end;
      if not Found then
      begin
        RequestedScreenId := QuestReturnScreenId;
        RequestClose(1);
      end;
    end
    else
    begin
      Stage := 19;
      Quest := TTextQuest.Create;
      if IsIntegerTextW(PendingQuestName) then
        LoadQuestById(StrToInt(PendingQuestName))
      else
        LoadQuestByName(PendingQuestName);
      Stage := 20;
      Quest.ToStarText.Text := LocalizedText('FormLoadQuest.PToStar');
      Quest.ToPlanetText.Text := LocalizedText('FormLoadQuest.PToPlanet');
      Quest.DateText.Text := FormatGameTurnDate(1500);
      Quest.MoneyText.Text := '10000';
      Quest.FromPlanetText.Text := LocalizedText('FormLoadQuest.PFromPlanet');
      Quest.FromStarText.Text := LocalizedText('FormLoadQuest.PFromStar');
      Quest.RangerText.Text := LocalizedText('FormLoadQuest.PRanger');
      Stage := 21;
      StartLoadedQuest;
      Stage := 22;
    end;
    Stage := 23;
    ApplyStyle;
    Stage := 24;
    TGraphButtonGI(GetByName('Style' + IntToWideString(QuestStyleIndex + 1))).ExecuteOnPressCode;
    Stage := 25;
    if Galaxy <> nil then
      Galaxy.PrimeIntegrityChecksum(150);
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      raise Exception.Create(
          'Error in procedure TfPlanetQuest.BeforeRun, label = ' + IntToStr(Stage));
    end;
  end;
end;

procedure TfPlanetQuest.OnClose;
var
  Money, CappedMoney: Int64;
  Player: TPlayer;
begin
  if Galaxy <> nil then
    Galaxy.CheckIntegrityChecksum(151);
  if GetPlayer <> nil then
    GetPlayer.ScriptItemsAct(satOnLeavingForm, nil, nil, 0);
  QuestId := -1;
  if PageAnimationTimer <> nil then
  begin
    CancelCallbackTimer(PageAnimationTimer);
    PageAnimationTimer := nil;
  end;
  ClearParameterPanel;
  ClearChoices;
  if GetPlayer <> nil then
  begin
    Player := GetPlayer;
    Money := GetPlayer.Money;
    // The native inlined Int64 minimum compares an unsigned limit with signed money.
    if Int64(MoneyLimitComplement xor $FFFFFFFF) < Money then
      CappedMoney := MoneyLimitComplement xor $FFFFFFFF
    else
      CappedMoney := Money;
    Player.SetMoney(Integer(CappedMoney));
  end;
  if Quest <> nil then
  begin
    Quest.Free;
    Quest := nil;
  end;
  if GetPlayer <> nil then
    GetPlayer.ProcessQuestTimersAndOutcomes;
  if (RequestedScreenId = screenMainMenu) or (RequestedScreenId = screenLoad) then
    ClearPendingScriptRequests;
end;

function TfPlanetQuest.GetTextColorTag(StyleIndex: Integer): WideString;
var
  Block: TBlockParEC;
begin
  Block := UiStyleConfig.GetBlockByPath('Style');
  if Block.CountBlocks('QTextColor') > 0 then
  begin
    Block := Block.GetBlock('QTextColor');
    if Block.CountParams('Sel' + IntToWideString(StyleIndex + 1)) > 0 then
    begin
      Result := '<color=' + Block.GetParam('Sel' + IntToWideString(StyleIndex + 1)) + '>';
      Exit;
    end;
  end;
  if StyleIndex = 0 then
    Result := '<color=' + IntToStr(255) + ',' + IntToStr(240) + ',' + IntToStr(100) + '>'
  else if StyleIndex = 1 then
    Result := '<color=' + IntToStr(255) + ',' + IntToStr(240) + ',' + IntToStr(100) + '>'
  else if StyleIndex = 2 then
    Result := '<color=' + IntToStr(0) + ',' + IntToStr(4) + ',' + IntToStr(173) + '>'
  else if StyleIndex = 3 then
    Result := '<color=' + IntToStr(0) + ',' + IntToStr(4) + ',' + IntToStr(173) + '>'
  else
    Result := GetTextColorTag(0);
end;

function TfPlanetQuest.GetTextColor(StyleIndex: Integer): Cardinal;
var
  Block: TBlockParEC;
  S: WideString;
begin
  Block := UiStyleConfig.GetBlockByPath('Style');
  if Block.CountBlocks('QTextColor') > 0 then
  begin
    Block := Block.GetBlock('QTextColor');
    if Block.CountParams('Text' + IntToWideString(StyleIndex + 1)) > 0 then
    begin
      S := Block.GetParam('Text' + IntToWideString(StyleIndex + 1));
      Result :=
          CurrentPixelFormat.PackRgb(
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 0, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 1, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 2, ','))
          );
      Exit;
    end;
  end;
  if StyleIndex = 0 then
    Result := CurrentPixelFormat.PackRgbBytes(212, 208, 180)
  else if StyleIndex = 1 then
    Result := CurrentPixelFormat.PackRgbBytes(212, 208, 180)
  else if StyleIndex = 2 then
    Result := CurrentPixelFormat.PackRgbBytes(0, 0, 0)
  else if StyleIndex = 3 then
    Result := CurrentPixelFormat.PackRgbBytes(0, 0, 0)
  else
    Result := GetTextColor(0);
end;

function TfPlanetQuest.GetDisabledTextColor(StyleIndex: Integer): Cardinal;
var
  Block: TBlockParEC;
  S: WideString;
begin
  Block := UiStyleConfig.GetBlockByPath('Style');
  if Block.CountBlocks('QTextColor') > 0 then
  begin
    Block := Block.GetBlock('QTextColor');
    if Block.CountParams('Grey' + IntToWideString(StyleIndex + 1)) > 0 then
    begin
      S := Block.GetParam('Grey' + IntToWideString(StyleIndex + 1));
      Result :=
          CurrentPixelFormat.PackRgb(
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 0, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 1, ',')),
              ExtractDigitsToIntW(ExtractDelimitedPartW(S, 2, ','))
          );
      Exit;
    end;
  end;
  if StyleIndex = 0 then
    Result := CurrentPixelFormat.PackRgbBytes(120, 120, 120)
  else if StyleIndex = 1 then
    Result := CurrentPixelFormat.PackRgbBytes(120, 120, 120)
  else if StyleIndex = 2 then
    Result := CurrentPixelFormat.PackRgbBytes(120, 120, 120)
  else if StyleIndex = 3 then
    Result := CurrentPixelFormat.PackRgbBytes(120, 120, 120)
  else
    Result := GetDisabledTextColor(0);
end;

procedure TfPlanetQuest.ApplyStyle;
var
  I: Integer;
  Control: TObjectGI;
  Path: WideString;
begin
  (GetByName('AnimTextOn') as TGraphButtonGI).SetActive(QuestPageAnimationEnabled);
  (GetByName('AnimTextOff') as TGraphButtonGI).SetActive(not QuestPageAnimationEnabled);
  for I := 1 to QuestStyleCount do
    (GetByName('Style' + IntToStr(I)) as TGraphButtonGI).SetDisabled(QuestStyleIndex = I - 1);
  (GetByName('BGStyle') as TImageGI)
      .SetImagePath(
          'GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S' + IntToWideString(QuestStyleIndex + 1));
  (GetByName('MessageWindow') as TPanelScrollBarGI)
      .VerticalScrollbar
      .SetConfigPath(
          'Style.ScrollBar.' + GiResourceSuffix + 'PQS' + IntToWideString(QuestStyleIndex + 1));
  (GetByName('ActionListWindow') as TPanelScrollBarGI)
      .VerticalScrollbar
      .SetConfigPath(
          'Style.ScrollBar.' + GiResourceSuffix + 'PQS' + IntToWideString(QuestStyleIndex + 1));
  Control := GetByName('MessageWindow').FirstChild;
  while Control <> nil do
  begin
    if Control is TLabelGI then
      with Control as TLabelGI do
      begin
        SetTextColor(GetTextColor(QuestStyleIndex));
        SetText(
            ReplaceAllWideString(
                GetText,
                GetTextColorTag(PreviousStyleIndex),
                GetTextColorTag(QuestStyleIndex)
            )
        );
      end;
    Control := Control.NextSibling;
  end;
  Control := GetByName('ActionListWindow').FirstChild;
  while Control <> nil do
  begin
    if Control.FirstChild <> nil then
    begin
      with Control.FirstChild as TImageGI do
      begin
        Path :=
            'Bm.FormPQuest2.'
                + GiResourceSuffix
                + 'S'
                + IntToWideString(QuestStyleIndex + 1)
                + 'Line';
        if CacheDataRoot.FileExistsByPath(Path) then
          SetImagePath('GI,' + Path)
        else
          SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1Line');
        SetImageKindX(ikxLeftFill);
        SetImageKindY(ikyTopFill);
      end;
      with Control.FirstChild.NextSibling as TLabelGI do
      begin
        if UserState = 1 then
          SetTextColor(GetDisabledTextColor(QuestStyleIndex))
        else
          SetTextColor(GetTextColor(QuestStyleIndex));
        SetText(
            ReplaceAllWideString(
                GetText,
                GetTextColorTag(PreviousStyleIndex),
                GetTextColorTag(QuestStyleIndex)
            )
        );
      end;
      if Control.FirstChild.NextSibling.FirstChild <> nil then
        with Control.FirstChild.NextSibling.FirstChild.FirstChild as TImageGI do
        begin
          Path :=
              'Bm.FormPQuest2.'
                  + GiResourceSuffix
                  + 'S'
                  + IntToWideString(QuestStyleIndex + 1)
                  + 'Answer';
          if Control.FirstChild.NextSibling.UserState = 1 then
          begin
            if CacheDataRoot.FileExistsByPath(Path + 'H') then
              SetImagePath('GI,' + Path + 'H')
            else
              SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1AnswerH');
          end
          else if CacheDataRoot.FileExistsByPath(Path) then
            SetImagePath('GI,' + Path)
          else
            SetImagePath('GI,Bm.FormPQuest2.' + GiResourceSuffix + 'S1Answer');
        end;
    end;
    Control := Control.NextSibling;
  end;
  LayoutMobilePage;
end;

procedure TfPlanetQuest.SelectPageMode(Sender: TObjectGI);
var
  Filename: WideString;
begin
  if Boolean(Sender.UserValue) <> QuestPageAnimationEnabled then
  begin
    QuestPageAnimationEnabled := Boolean(Sender.UserValue);
    UserSettingsConfig.SetOrAddParam('PQuestAnim', BoolToWideString(QuestPageAnimationEnabled));
    Filename := GetGameUserDirectory + 'cfg.txt';
    UserSettingsConfig.SaveTextFile(PWideChar(Filename), True, False);
    if QuestPageAnimationEnabled then
      ShowControlHelp(GetByName('AnimTextOn'), True)
    else
      ShowControlHelp(GetByName('AnimTextOff'), True);
    ApplyStyle;
  end;
end;

procedure TfPlanetQuest.SelectStyle(Sender: TObjectGI);
begin
  if QuestStyleIndex <> Sender.UserValue then
  begin
    PreviousStyleIndex := QuestStyleIndex;
    QuestStyleIndex := Sender.UserValue;
    UserSettingsConfig.SetOrAddParam('PQuestStyle', IntToStr(QuestStyleIndex));
    UserSettingsConfig.SaveTextFile(PWideChar(GetGameUserDirectory + 'cfg.txt'), True, False);
    ApplyStyle;
  end;
end;

procedure TfPlanetQuest.ShowControlHelp(Sender: TObjectGI; Visible: Boolean);
var
  TextLabel: TLabelGI;
begin
  TextLabel := GetByName('LabelHelp') as TLabelGI;
  if Sender.HelpText = '' then
    Visible := False;
  TextLabel.SetActive(Visible);
  if (Sender.ControlName = 'ButtonExit') and (ActiveQueuedTextQuest <> nil) then
    TextLabel.SetText(LocalizedText('FormPQuest.HelpExitAlt'))
  else
    TextLabel.SetText(Sender.HelpText);
end;

procedure TfPlanetQuest.SetQuestPicture(Name: WideString);
var
  Image: TGraphBufGI;
begin
  if CurrentPicture <> Name then
  begin
    CurrentPicture := Name;
    Image := GetByName('PQI') as TGraphBufGI;
    Image.SetActive(True);
    Image.LoadBitmapPathAsRgb('Bm.PQI.' + Name + '?RGB');
    if GiResourceVariant = 1 then
      Image.GraphBuf.RescaleRgb(
          Round(Cardinal(Image.GraphBuf.Width) * 800 / 1024),
          Round(Cardinal(Image.GraphBuf.Height) * 800 / 1024)
      );
    Image.GraphBuf.ConvertRgbTo565;
    Image.Invalidate;
  end;
  LayoutMobilePage;
end;

procedure TfPlanetQuest.RequestLoadGame(Sender: TObjectGI);
var
  Standalone: Boolean;
begin
  if MobileStatsExpanded then
  begin
    MobileStatsExpanded := False;
    LayoutMobilePage;
    Exit;
  end;
  if ShowMessageBoxGI(
          Self,
          LanguageDataConfig.GetParamByPathOrMarker('FormGameMenu.QExit'),
          mbgOK or mbgCancel)
      = mbgResultOK then
  begin
    Standalone := Galaxy = nil;
    ClearPendingScriptRequests;
    if MemorySnapshotBuffer <> nil then
      MemorySnapshotBuffer.Free;
    MemorySnapshotBuffer := nil;
    MemorySnapshotActive := False;
    if Galaxy <> nil then
      if not Galaxy.Destroying then
        Galaxy.Free;
    Galaxy := nil;
    ScreenLoadMode := 4;
    if Standalone then
      PostLoadScreenId := QuestReturnScreenId
    else
      PostLoadScreenId := screenMainMenu;
    RequestedScreenId := screenLoad;
    RequestClose(1);
  end;
end;

procedure TfPlanetQuest.QuestKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
var
  Index: Integer;
  Panel: TPanelScrollBarGI;
  Choice, Control: TObjectGI;
begin
  if MobileStatsExpanded then
  begin
    if VirtualKey = VK_ESCAPE then
      RequestLoadGame(nil);
    Exit;
  end;
  if not IsVirtualKeyDown(VK_CONTROL)
      and not IsVirtualKeyDown(VK_SHIFT)
      and not IsVirtualKeyDown(VK_MENU) then
  begin
    if VirtualKey = VK_ESCAPE then
      RequestLoadGame(nil);
    if (VirtualKey >= Ord('1')) and (VirtualKey <= Ord('9')) then
    begin
      Index := VirtualKey - Ord('1');
      Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
      Control := Panel.FirstChild;
      while (Control <> nil)
          and (not (Control is TPanelGI)
              or ((@Control.LeftButtonUpCallback <> @TfPlanetQuest.ChoiceMouseUp)
                  and (@Control.LeftButtonUpCallback <> @TfPlanetQuest.DisabledChoiceMouseUp))) do
        Control := Control.NextSibling;
      Choice := Control;
      while (Choice <> nil) and (Index >= 0) do
      begin
        if Index = 0 then
        begin
          Choice.LeftButtonUpCallback(Choice, 0, Point(0, 0));
          Exit;
        end
        else
        begin
          Dec(Index);
          Control := Choice.NextSibling;
          while (Control <> nil)
              and (not (Control is TPanelGI)
                  or ((@Control.LeftButtonUpCallback <> @TfPlanetQuest.ChoiceMouseUp)
                      and (@Control.LeftButtonUpCallback
                          <> @TfPlanetQuest.DisabledChoiceMouseUp))) do
            Control := Control.NextSibling;
          Choice := Control;
        end;
      end;
    end;
    if VirtualKey = Ord('R') then
      if ActiveQueuedTextQuest = nil then
        if SaveManagerScreen.AutoSaveExists then
          if ShowMessageBoxGI(
                  Self,
                  LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'),
                  mbgOK or mbgCancel)
              = mbgResultOK then
            if GetPlayer <> nil then
            begin
              PendingLoadFileName := SaveManagerScreen.GetAutoSavePath;
              RequestedScreenId := screenGameLoad;
              RequestClose(1);
            end
            else
            begin
              StandaloneQuestMode := True;
              RequestedScreenId := screenPlanetQuest;
              CurrentScreenId := screenNone;
              RequestClose(1);
            end;
  end;
end;

procedure TfPlanetQuest.SelectMusic;
begin
  if not MusicInPlanetEnabled then
    MusicManager.RequestFadeOut
  else
    MusicManager.PlayCategory('Quest');
end;

function RemoveQuestProseIndent(const Text: WideString): WideString;
var
  Lower: WideString;
  Cursor, First, Last: Integer;
begin
  Result := '';
  Lower := LowerCaseWideString(Text);
  Cursor := 0;
  repeat
    First := FindTextOffsetW(Lower, '<fix>', Cursor);
    if First < 0 then
      First := Length(Text);
    Result :=
        Result
            + ReplaceAllWideString(
                Copy(Text, Cursor + 1, First - Cursor),
                #13#10'          ',
                #13#10);
    if First = Length(Text) then
      Exit;
    Last := FindTextOffsetW(Lower, '</fix>', First + 5);
    if Last < 0 then
      Last := Length(Text)
    else
      Inc(Last, 6);
    // Leading spaces in a fixed block are grid columns, not paragraph indent.
    Result := Result + Copy(Text, First + 1, Last - First);
    Cursor := Last;
  until Cursor >= Length(Text);
end;

function TfPlanetQuest.ExpandTemplateText(Text: WideString): WideString;
var
  Expanded: WideString;
begin
  if GetPlayer = nil then
    CurrentDate := TrimWideString(Galaxy.FormatTurnDate(DaysElapsed + GalaxyWarmupTurns))
  else
    CurrentDate := TrimWideString(Galaxy.FormatTurnDate(Galaxy.CurrentTurn));
  Expanded := ExpandExternalText(Text);
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<ToStar>',
          WrapTextInColor(TrimWideString(Quest.ToStarText.Text), GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<ToPlanet>',
          WrapTextInColor(TrimWideString(Quest.ToPlanetText.Text), GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<Date>',
          WrapTextInColor(Quest.DateText.Text, GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<Money>',
          WrapTextInColor(Quest.MoneyText.Text, GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<FromPlanet>',
          WrapTextInColor(
              TrimWideString(Quest.FromPlanetText.Text),
              GetTextColorTag(QuestStyleIndex)
          )
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<FromStar>',
          WrapTextInColor(TrimWideString(Quest.FromStarText.Text), GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<Ranger>',
          WrapTextInColor(TrimWideString(Quest.RangerText.Text), GetTextColorTag(QuestStyleIndex))
      );
  Expanded :=
      ReplaceAllWideString(
          Expanded,
          '<CurDate>',
          WrapTextInColor(CurrentDate, GetTextColorTag(QuestStyleIndex))
      );
  Expanded := RemoveQuestProseIndent(Expanded);
  if Pos('<', Expanded) > 0 then
  begin
    Expanded := ReplaceAllWideString(Expanded, '<br>', #13#10);
    Expanded := ReplaceAllWideString(Expanded, '<ll>', #13#10' '#13#10);
    // Native quirk: <Player> is expanded into Result, then overwritten below.
    if GetPlayer <> nil then
      Result :=
          ReplaceAllWideString(
              Result,
              '<Player>',
              WrapTextInColor(GetPlayer.Name, GetTextColorTag(QuestStyleIndex))
          );
    Expanded := ReplaceAllWideString(Expanded, '<clr>', GetTextColorTag(QuestStyleIndex));
    Expanded := ReplaceAllWideString(Expanded, '<clrEnd>', EndColorTag);
  end;
  Result := Expanded;
end;

procedure TfPlanetQuest.IgnoreChoice(Value: Integer);
begin

end;

procedure TfPlanetQuest.ContinueToLocation(LocationId: Integer);
begin
  ClearChoices;
  Quest.EnterLocation(LocationId);
end;

procedure TfPlanetQuest.ContinueAlongPath(PathId: Integer);
begin
  ClearChoices;
  Quest.FollowPath(PathId);
end;

procedure TfPlanetQuest.ContinueToOutcome(Value: Integer);
begin
  ClearChoices;
  Quest.ShowOutcome;
end;

procedure TfPlanetQuest.CompleteQuestSuccess(Value: Integer);
var
  News, ItemName: WideString;
  GovernmentQuest: PQuest;
  I: Integer;
  Item: TUselessItem;
begin
  ClearChoices;
  if ActiveQueuedTextQuest = nil then
    if GetPlayer <> nil then
      if not GetPlayer.InPrison then
        if GetPlayer.Quests.Count > 0 then
          for I := 0 to GetPlayer.Quests.Count - 1 do
          begin
            GovernmentQuest := GetPlayer.Quests[I];
            if (GovernmentQuest.QuestType = qtPlanetQuest)
                and (GovernmentQuest.ObjectiveTarget is TPlanet)
                and (GetPlayer.CurrentPlanet = (GovernmentQuest.ObjectiveTarget as TPlanet)) then
            begin
              if Quest.CompleteOnFinish then
              begin
                GovernmentQuest.Successful := True;
                News :=
                    PickLocalizedTextVariant(
                        'GalaxyNews.Quest.Successful.PlanetaryQuest',
                        (Galaxy.CurrentTurn div 10) * Integer(Galaxy.GenerationSeed)
                    );
                ReplaceTextToken(
                    News,
                    '<FromPlanet>',
                    GovernmentQuest.Planet.Name,
                    TextHighlightColorTag
                );
                ReplaceTextToken(
                    News,
                    '<ToPlanet>',
                    GetPlayer.CurrentPlanet.Name,
                    TextHighlightColorTag
                );
                AddOrUpdatePlayerBubble(pmGalaxyNews, Galaxy.CurrentTurn, News, '');
              end;
              ItemName :=
                  LookupLocalizedTextByKey(
                      'PlanetQuest.ItemForPlanetQuest.' + IntToStr(GovernmentQuest.QuestNumber)
                  );
              if ItemName <> 'none' then
              begin
                Item := TUselessItem.Create;
                Item.Init(ItemName, dsBlazer, 0, False);
                GetPlayer.Inventory.Add(Item);
              end;
              GetPlayer.CurrentPlanet.TextQuestId := -1;
              (GetByName('QuestPanel') as TPanelGI).SetActive(False);
              if GetPlayer.CurrentPlanet.IsCoalitionOwned
                  or (GetPlayer.CurrentPlanet.OwnerId = oiPirate) then
              begin
                GetPlayer
                    .CurrentPlanet
                    .ChangeRelationToRanger(GetPlayer, Quest.SuccessRelationDelta);
                if GetPlayer.CurrentPlanet.RelationToShip(GetPlayer) < 20 then
                  GetPlayer.CurrentPlanet.SetRelationLevelToRanger(GetPlayer, rlBad);
              end;
              Break;
            end;
          end;
  if QuestId >= 0 then
    if (ActiveQueuedTextQuest = nil)
        or (GetPlayer = nil)
        or not (GetPlayer.PirateRank in [4, 6]) then
    begin
      if GetPlayer <> nil then
        TryAddAchievementProgress('QUEST', 1);
      LoadQuestScreen.LoadCompletionData;
      LoadQuestScreen.RecordCompletion(QuestId, 0, 1);
      LoadQuestScreen.SaveCompletionData;
    end;
  RequestedScreenId := QuestReturnScreenId;
  RequestClose(1);
  if ActiveQueuedTextQuest <> nil then
  begin
    ActiveQueuedTextQuest := nil;
    CompleteQueuedTextQuest(sqsSuccess);
  end;
end;

procedure TfPlanetQuest.CompleteQuestFailure(Value: Integer);
var
  News: WideString;
  GovernmentQuest: PQuest;
  I: Integer;
begin
  if GetPlayer = nil then
    RequestedScreenId := QuestReturnScreenId
  else if GetPlayer.InPrison then
  begin
    GetPlayer.InPrison := False;
    if GetPlayer.CurrentPlanet <> nil then
      if (GetPlayer.CurrentPlanet.OwnerId = oiPirate) and (MainPiratePlanet <> nil) then
        MainPiratePlanet.SetRelationLevelToRanger(GetPlayer, rlHostile)
      else
        GetPlayer.CurrentPlanet.SetRelationLevelToRanger(GetPlayer, rlHostile);
    if not HangarScreen.TryTakeOff then
      RequestedScreenId := screenHangar;
  end
  else
  begin
    if ActiveQueuedTextQuest = nil then
      if GetPlayer <> nil then
        if GetPlayer.Quests.Count > 0 then
          for I := GetPlayer.Quests.Count - 1 downto 0 do
          begin
            GovernmentQuest := GetPlayer.Quests[I];
            if (GovernmentQuest.QuestType = qtPlanetQuest)
                and (GovernmentQuest.ObjectiveTarget is TPlanet)
                and (GetPlayer.CurrentPlanet = (GovernmentQuest.ObjectiveTarget as TPlanet)) then
            begin
              GovernmentQuest.Successful := False;
              GetPlayer.PublishQuestStatus(GovernmentQuest, -1);
              News :=
                  PickLocalizedTextVariant(
                      'GalaxyNews.Quest.Failure.PlanetaryQuest',
                      Integer(GetPlayer.Seed) * (Galaxy.CurrentTurn div 10)
                  );
              ReplaceTextToken(
                  News,
                  '<ToPlanet>',
                  GetPlayer.CurrentPlanet.Name,
                  TextHighlightColorTag
              );
              ReplaceTextToken(
                  News,
                  '<FromPlanet>',
                  GovernmentQuest.Planet.Name,
                  TextHighlightColorTag
              );
              ReplaceTextToken(
                  News,
                  '<Relation>',
                  GovernmentQuest.Planet.GetRelationLevelTextToShip(GetPlayer),
                  TextHighlightColorTag
              );
              AddOrUpdatePlayerBubble(pmGalaxyNews, Galaxy.CurrentTurn, News, '');
              GetPlayer.CurrentPlanet.TextQuestId := -1;
              GetPlayer.ArchiveQuest(I);
              Break;
            end;
          end;
    if (ActiveQueuedTextQuest = nil)
        and SaveManagerScreen.AutoSaveExists
        and (ShowMessageBoxGI(
                Self,
                LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'),
                mbgOK or mbgCancel)
            = mbgResultOK) then
    begin
      PendingLoadFileName := SaveManagerScreen.GetAutoSavePath;
      RequestedScreenId := screenGameLoad;
    end
    else
      RequestedScreenId := QuestReturnScreenId;
  end;
  RequestClose(1);
  if ActiveQueuedTextQuest <> nil then
  begin
    ActiveQueuedTextQuest := nil;
    CompleteQueuedTextQuest(sqsFailure);
  end;
end;

procedure TfPlanetQuest.CompleteQuestDeath(Value: Integer);
begin
  if GetPlayer = nil then
    RequestedScreenId := QuestReturnScreenId
  else
  begin
    if SaveManagerScreen.AutoSaveExists
        and (ShowMessageBoxGI(
                Self,
                LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'),
                mbgOK or mbgCancel)
            = mbgResultOK) then
    begin
      PendingLoadFileName := SaveManagerScreen.GetAutoSavePath;
      RequestedScreenId := screenGameLoad;
    end
    else
    begin
      ScoreScreen.RecordPlayerResult(False);
      GetPlayer.Free;
      GameEndReason := 1;
      RequestedScreenId := screenGameEnd;
    end;
  end;
  ClearPendingScriptRequests;
  RequestClose(1);
end;

procedure TfPlanetQuest.ApplyLegacyPictureOverrides;
var
  Found, Count, I, J, K: Integer;
  Kind, Indices, Name, Picture: WideString;
  Values: TValuesList;
  Config: TBlockParEC;
begin
  Values := TValuesList.Create;
  Config := GameDataConfig.GetBlock('PQI');
  Count := Config.GetParamCount;
  for I := 0 to Count - 1 do
  begin
    Name := Config.GetParamName(I);
    if GetTextBeforeDelimiter(Name, ',') = QuestName then
    begin
      Kind := GetTextAfterComma(Name, ',');
      Indices := GetTextAfterComma(Kind, ',');
      Kind := GetTextBeforeDelimiter(Kind, ',');
      Values.LoadFromSemicolonText(Indices);
      Picture := Config.GetParamValue(I);
      Picture := ReplaceAllWideString(Picture, 'Bm.PQI.', '');
      if Kind = 'L' then
        for J := 1 to Values.Count do
        begin
          Found := -1;
          for K := 1 to Quest.GetLocationCount do
            if Quest.GetLocation(K).Id = Values.Values[J] then
            begin
              Found := K;
              Break;
            end;
          if Found > 0 then
            for K := 1 to Quest.GetLocation(Found).EventCount do
              Quest.GetLocation(Found).Events[K].Picture.Text := Picture;
        end;
      if Kind = 'P' then
        for J := 1 to Values.Count do
        begin
          Found := -1;
          for K := 1 to Quest.GetPathCount do
            if Quest.GetPath(K).Id = Values.Values[J] then
            begin
              Found := K;
              Break;
            end;
          if Found > 0 then
            Quest.GetPath(Found).Event.Picture.Text := Picture;
        end;
      if Kind = 'PAR' then
        for J := 1 to Values.Count do
          if Quest.GetParameterCount >= Values.Values[J] then
            if Quest.GetParameter(Values.Values[J]).Enabled then
              if Quest.GetParameter(Values.Values[J]).CriticalOutcome <> qoNone then
                Quest.GetParameter(Values.Values[J]).CriticalEvent.Picture.Text := Picture;
    end;
  end;
  Values.Destroy;
end;

procedure TfPlanetQuest.ExportMoneyToPlayer;
var
  I: Integer;
begin
  if GetPlayer <> nil then
    for I := 1 to Quest.GetParameterCount do
      if Quest.GetParameter(I).Enabled then
        if Quest.GetParameter(I).IsMoney then
        begin
          GetPlayer.SetMoney(Quest.GetParameter(I).Value);
          Quest.GetParameter(I).Value := GetPlayer.Money;
          Break;
        end;
end;

procedure TfPlanetQuest.ImportMoneyFromPlayer;
var
  I: Integer;
begin
  if GetPlayer <> nil then
    for I := 1 to Quest.GetParameterCount do
      if Quest.GetParameter(I).Enabled then
        if Quest.GetParameter(I).IsMoney then
        begin
          Quest.GetParameter(I).Value := GetPlayer.Money;
          Break;
        end;
end;

procedure TfPlanetQuest.ExportExternalParameters;
var
  I: Integer;
  Name: WideString;
  Variable: TVarEC;
begin
  for I := 1 to Quest.GetParameterCount do
    if FindTextPosW('ext_', Quest.GetParameter(I).NameText.Text) = 1 then
    begin
      Name := Quest.GetParameter(I).NameText.Text;
      Name[1] := 'E';
      Name := 'GQuestVar' + Name;
      Variable := nil;
      if ActiveQueuedTextQuest <> nil then
        if ActiveQueuedTextQuest.Script <> nil then
          Variable := ActiveQueuedTextQuest.Script.InitCode.LocalVar.GetVarNE(Name);
      if Variable = nil then
        Variable := SharedScriptVariables.GetVarNE(Name);
      if Variable <> nil then
        if Variable.RealVType = vkInt then
        begin
          Variable.SetInt(Quest.GetParameter(I).Value);
        end;
    end;
end;

procedure TfPlanetQuest.ImportExternalParameters;
var
  I: Integer;
  Name: WideString;
  Variable: TVarEC;
begin
  for I := 1 to Quest.GetParameterCount do
    if FindTextPosW('ext_', Quest.GetParameter(I).NameText.Text) = 1 then
    begin
      Name := Quest.GetParameter(I).NameText.Text;
      Name[1] := 'E';
      Name := 'GQuestVar' + Name;
      Variable := nil;
      if ActiveQueuedTextQuest <> nil then
        if ActiveQueuedTextQuest.Script <> nil then
          Variable := ActiveQueuedTextQuest.Script.InitCode.LocalVar.GetVarNE(Name);
      if Variable = nil then
        Variable := SharedScriptVariables.GetVarNE(Name);
      if Variable <> nil then
        if Variable.RealVType = vkInt then
        begin
          Quest.GetParameter(I).SetValue(Variable.GetInt);
          Variable.SetInt(Quest.GetParameter(I).Value);
        end;
    end;
end;

function TfPlanetQuest.ExpandExternalText(Text: WideString): WideString;
var
  I: Integer;
  Name, Token, Expanded: WideString;
  Variable: TVarEC;
begin
  Expanded := Text;
  for I := 1 to Quest.GetParameterCount do
  begin
    if FindTextPosW('ext_', Quest.GetParameter(I).NameText.Text) <> 1 then
      Continue;
    Name := Quest.GetParameter(I).NameText.Text;
    Token := Name;
    Name[1] := 'E';
    Token[1] := 't';
    Token := '<' + Token + '>';
    Name := 'GQuestVar' + Name;
    Variable := SharedScriptVariables.GetVarNE(Name);
    if Variable <> nil then
      Expanded :=
          ReplaceAllWideString(
              Expanded,
              Token,
              WrapTextInColor(TrimWideString(Variable.GetString), GetTextColorTag(QuestStyleIndex))
          );
  end;
  Result := Expanded;
end;

procedure TTextQuestPlayerInterface.ShowText(Text: WideString);
var
  ExpandedText: WideString;
begin
  ExpandedText := PlanetQuestScreen.ExpandTemplateText(Text);
  if ExpandedText <> TrimWideString(PlanetQuestScreen.CurrentText) then
    PlanetQuestScreen.SetQuestText(PlanetQuestScreen.ExpandTemplateText(Text));
end;

procedure TTextQuestPlayerInterface.ShowPicture(Name: WideString);
begin
  PlanetQuestScreen.SetQuestPicture(Name);
end;

procedure TTextQuestPlayerInterface.PlayMusic(Name: WideString);
begin
  MusicManager.RequestFadeOut;
  if MusicInPlanetEnabled then
    MusicManager.PlayCategory(Name);
end;

procedure TTextQuestPlayerInterface.PlaySound(Name: WideString);
begin
  SoundManager.PlaySound('Sound.' + Name);
end;

procedure TTextQuestPlayerInterface.ShowParameters(Text: WideString);
begin
  PlanetQuestScreen.ClearParameterPanel;
  PlanetQuestScreen.AppendParameterText(TrimWideString(PlanetQuestScreen.ExpandTemplateText(Text)));
  PlanetQuestScreen.LayoutParameterPanel;
  PlanetQuestScreen.ExportMoneyToPlayer;
  PlanetQuestScreen.ExportExternalParameters;
end;

procedure TTextQuestPlayerInterface.AddContinueAction;
begin
  PlanetQuestScreen.AddChoice(
      '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgContinue'),
      0,
      PlanetQuestScreen.ContinueToOutcome
  );
end;

procedure TTextQuestPlayerInterface.AddSuccessAction;
begin
  if (GetPlayer <> nil) and GetPlayer.InPrison then
    PlanetQuestScreen.AddChoice(
        '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgSuccessPrison'),
        0,
        PlanetQuestScreen.CompleteQuestSuccess
    )
  else if (ActiveQueuedTextQuest <> nil) and (ActiveQueuedTextQuest.SuccessCaption <> '') then
    PlanetQuestScreen.AddChoice(
        ' - ' + ActiveQueuedTextQuest.SuccessCaption,
        0,
        PlanetQuestScreen.CompleteQuestSuccess
    )
  else
    PlanetQuestScreen.AddChoice(
        ' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgSuccess'),
        0,
        PlanetQuestScreen.CompleteQuestSuccess
    );
end;

procedure TTextQuestPlayerInterface.AddDeathAction;
begin
  PlanetQuestScreen.AddChoice(
      '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgDeath'),
      0,
      PlanetQuestScreen.CompleteQuestDeath
  );
end;

procedure TTextQuestPlayerInterface.AddFailureAction;
begin
  if (GetPlayer <> nil) and GetPlayer.InPrison then
    PlanetQuestScreen.AddChoice(
        '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgFailPrison'),
        0,
        PlanetQuestScreen.CompleteQuestFailure
    )
  else if (ActiveQueuedTextQuest <> nil) and (ActiveQueuedTextQuest.FailureCaption <> '') then
    PlanetQuestScreen.AddChoice(
        ' - ' + ActiveQueuedTextQuest.FailureCaption,
        0,
        PlanetQuestScreen.CompleteQuestFailure
    )
  else
    PlanetQuestScreen.AddChoice(
        '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgFail'),
        0,
        PlanetQuestScreen.CompleteQuestFailure
    );
end;

procedure TTextQuestPlayerInterface.AddPathAction(Text: WideString; PathId: Integer);
begin
  PlanetQuestScreen.AddChoice(
      '  - ' + PlanetQuestScreen.ExpandTemplateText(Text),
      PathId,
      PlanetQuestScreen.ContinueAlongPath
  );
end;

procedure TTextQuestPlayerInterface.AddDisabledPath(Text: WideString);
begin
  PlanetQuestScreen.AddDisabledChoice(
      '  - ' + PlanetQuestScreen.ExpandTemplateText(Text),
      0,
      PlanetQuestScreen.IgnoreChoice
  );
end;

procedure TTextQuestPlayerInterface.AddPathContinueAction(PathId: Integer);
begin
  PlanetQuestScreen.AddChoice(
      '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgContinue'),
      PathId,
      PlanetQuestScreen.ContinueAlongPath
  );
end;

procedure TTextQuestPlayerInterface.AddLocationContinueAction(LocationId: Integer);
begin
  PlanetQuestScreen.AddChoice(
      '  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgContinue'),
      LocationId,
      PlanetQuestScreen.ContinueToLocation
  );
end;

procedure TTextQuestPlayerInterface.AdvanceDays(Days: Integer);
var
  I: Integer;
begin
  PlanetQuestScreen.ExportMoneyToPlayer;
  PlanetQuestScreen.ExportExternalParameters;
  for I := 1 to Days do
  begin
    Inc(PlanetQuestScreen.DaysElapsed);
    // The native standalone path stops after one increment, even when Days is greater than one.
    if StandaloneQuestMode then
      Break;
    WaitForTurnCalculation;
    PruneExpiredPersistentPlayerMessages;
    CalculatePlayerStarTurnAndWait;
    if ExitScreenLoop then
      Break;
    QueueGalaxyTurnCalculation;
    PlanetQuestScreen.ImportMoneyFromPlayer;
    PlanetQuestScreen.ImportExternalParameters;
  end;
end;

procedure TfPlanetQuest.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
  if ExitScreenLoop then
    Exit;
  if Integer(TurnCalculationPhase) in [0, 2, 4, 6] then
  begin
    if Galaxy <> nil then
      Galaxy.CheckIntegrityChecksum(10109);
    ExecuteGameplayUiCode(Block, Key);
    if Galaxy <> nil then
      Galaxy.PrimeIntegrityChecksum(20109);
  end;
end;

end.
