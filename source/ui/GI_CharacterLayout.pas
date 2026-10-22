unit GI_CharacterLayout;

{$I GameOptions.inc}
{$codepage utf8}

interface

uses Types, GI_MessageLoop, GI_Panel, GI_PanelScrollBar, GI_GraphButton, GI_Label, GI_CountBar;

type
  { Presentation only: original controls retain their names, values and callbacks. }
  TMobileCharacterLayout = class(TPanelGI)
  private
    Screen: TMessageLoopGI;
    Pages: array[0..3] of TObjectGI;
    Tabs: array[0..2] of TGraphButtonGI;
    Description, Help: TPanelScrollBarGI;
    HelpPopup: TPanelGI;
    NameError: TLabelGI;
    BodyHeight: Integer;
    procedure TabClicked(Sender: TObjectGI);
    procedure DetailsClicked(Sender: TObjectGI);
    procedure HelpClicked(Sender: TObjectGI);
    procedure MakeCharacter;
    procedure MakeBonuses;
    procedure MakeDifficulty;
    procedure MakeExtended;
    function Control(const Name: WideString): TObjectGI;
    procedure Button(const Name, Caption: WideString; Owner: TObjectGI; X, Y, W, H: Integer);
    function LabelAt(Owner: TObjectGI; const Text: WideString; X, Y, W, H: Integer): TLabelGI;
    function ScrollAt(Owner: TObjectGI; X, Y, W, H: Integer): TPanelScrollBarGI;
  public
    CurrentPage: Integer;
    constructor CreateForScreen(AScreen: TMessageLoopGI);
    procedure Open(IronImage, IronLabel: TObjectGI);
    procedure ShowPage(Index: Integer);
    procedure UpdateDescription;
    procedure UpdateCursor(const CursorName, ButtonName: WideString);
    procedure ShowHelp(Sender: TObjectGI);
    procedure NameValidityChanged(Valid: Boolean);
    function CloseHelp: Boolean;
  end;

procedure PrepareMobileCharacterSlider(Slider: TCountBarGI);

implementation

uses Classes, SysUtils, Math, EC_Str, GI_Main, GI_Image, GI_Edit, GI_LayoutMetrics, GI_Artwork, GI_MobileSkin,
  GameWindow, Globals, GlobalsV, GR_Main, GR_GraphBuf, aConst;

const
  // Frame buffer pixels per layout unit: about one per screen pixel on a phone,
  // so the original bezel keeps its native detail.
  FrameDetail = 3;
  // Original window frame: glass and bezel edges, and the plain bezel strips
  // between the crest, corner lights and corners (source pixels).
  FrameArt = 'Bm.FormGameSet2.PanelExt';
  FrameGlass: TRect = (Left: 14; Top: 38; Right: 15; Bottom: 33);
  FrameHalf = 451;
  FrameLeftBorders: TRect = (Left: 210; Top: 200; Right: 121; Bottom: 189);
  FrameRightBorders: TRect = (Left: 121; Top: 200; Right: 213; Bottom: 189);
  FrameGlassColor = $F0081720;
  // Layout units kept clear of the bezel by the tab row and the footer.
  TabTop = 10;
  RowHeight = 40;

  // Bonuses page: skill buttons fit «Манёвренность» on one line.
  SkillWidth = 142;
  ItemsLeft = 2 * SkillWidth + 16;
  BonusHelpLeft = ItemsLeft + 4 * 60;

function MobileText(const English, Russian: WideString): WideString;
begin
  if LowerCaseWideString(SelectedLanguage) = 'russian' then Result := Russian else Result := English;
end;

procedure HideChildren(Owner: TObjectGI);
var Child: TObjectGI;
begin
  Child := Owner.FirstChild;
  while Child <> nil do
  begin
    Child.SetActive(False);
    Child := Child.NextSibling;
  end;
end;

// Keeps the bright rim of a pressed face and darkens its middle, so coloured
// captions stay readable while the selection still glows.
procedure DimFaceMiddle(Image: TImageGI; Inset: Integer);
var
  X, Y: Integer;
  Pixel: PByte;
begin
  with Image.GraphBufControl.GraphBuf do
    for Y := Inset to Height - 1 - Inset do
    begin
      Pixel := PByte(GetPixels) + Y * PitchBytes + Inset * 4;
      for X := Inset to Width - 1 - Inset do
      begin
        Pixel[0] := Pixel[0] * 3 div 10;
        Pixel[1] := Pixel[1] * 3 div 10;
        Pixel[2] := Pixel[2] * 3 div 10;
        Inc(Pixel, 4);
      end;
    end;
end;

// Turns a face into an outline of the same shape: the middle becomes clear and
// the rim takes Color (RGB). Used for the gold "move this bonus" cursor.
procedure OutlineFace(Image: TImageGI; Inset: Integer; Color: Cardinal);
var
  X, Y: Integer;
  Pixel: PByte;
begin
  with Image.GraphBufControl.GraphBuf do
    for Y := 0 to Height - 1 do
    begin
      Pixel := PByte(GetPixels) + Y * PitchBytes;
      for X := 0 to Width - 1 do
      begin
        if (X >= Inset) and (X < Width - Inset) and (Y >= Inset) and (Y < Height - Inset) then
          Pixel[3] := 0
        else
        begin
          Pixel[0] := Color and $FF;
          Pixel[1] := (Color shr 8) and $FF;
          Pixel[2] := (Color shr 16) and $FF;
        end;
        Inc(Pixel, 4);
      end;
    end;
end;

// The original window frame around the whole layout (W x H units).
procedure PaintFrame(Image: TImageGI; W, H: Integer);
var
  Source: TGraphBufGR;
  FrameWidth, FrameHeight, Half: Integer;
begin
  FrameWidth := W * FrameDetail;
  FrameHeight := H * FrameDetail;
  Source := TGraphBufGR.Create(False);
  try
    LoadOriginalGiArtwork(FrameArt, Source);
    Image.AutoUpdateFlags := 0;
    Image.SetImagePath('GraphBuf');
    Image.GraphBufControl.SourceHasPerPixelAlpha := True;
    Image.SetOrigin(Point(0, 0));
    Image.DisplayScale := 1 / FrameDetail;
    Image.SetSize(Point(FrameWidth, FrameHeight));
    with Image.GraphBufControl.GraphBuf do
    begin
      AllocateRgbaTight(FrameWidth, FrameHeight);
      FillPixels(0);
      // Two halves keep the crest at the top centre; corners and corner lights
      // are copied, only plain bezel strips repeat.
      Half := FrameWidth div 2;
      DrawNinePatch(0, 0, Half, FrameHeight, Source, Rect(0, 0, FrameHalf, Source.Height), FrameLeftBorders);
      DrawNinePatch(Half, 0, FrameWidth - Half, FrameHeight, Source, Rect(FrameHalf, 0, Source.Width, Source.Height), FrameRightBorders);
      // The original glass carries guide lines for the desktop controls.
      FillRect32(Rect(FrameGlass.Left, FrameGlass.Top, FrameWidth - FrameGlass.Right, FrameHeight - FrameGlass.Bottom), FrameGlassColor);
    end;
    Image.SetHitTestDisabled(True);
  finally
    Source.Free;
  end;
end;

procedure StyleButton(B: TGraphButtonGI; const Caption: WideString; W, H: Integer);
begin
  B.ImageAutoUpdateFlags := 0;
  B.AutoOffsetEnabled := False;
  B.SetOrigin(Point(0, 0));
  B.HitKind := gbhRect;
  B.NormalOffset := Point(0, 0);
  B.DownOffset := Point(0, 0);
  B.DisabledOffset := Point(0, 0);
  B.CaptionOffsets := Rect(0, 0, 0, 0);
  FreeAndNil(B.ImageNormalActive);
  FreeAndNil(B.ImageDownActive);
  FreeAndNil(B.ImageDisabledActive);
  FreeAndNil(B.ImageHit);
  B.SetImageNormalPath('GraphBuf');
  B.SetImageDownPath('GraphBuf');
  B.SetImageDisabledPath('GraphBuf');
  // Faces of the original settings tabs: normal, pressed (bright) and disabled.
  PaintMobileButtonArt(B.ImageNormal, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageA', W, H, 10);
  PaintMobileButtonArt(B.ImageDown, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageD', W, H, 10);
  PaintMobileButtonArt(B.ImageDisabled, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageN', W, H, 10);
  B.SetSize(Point(W, H));
  B.SetCaptionFontName(SmoothHugeFontName);
  B.SetCaption(Caption);
  B.SetCaptionColor(CurrentPixelFormat.PackRgbBytes(230, 241, 244));
  // Dark text on the bright pressed face.
  B.CaptionColors[2] := CurrentPixelFormat.PackRgbBytes(6, 34, 48);
  B.CaptionColors[3] := B.CaptionColors[2];
  B.CaptionColors[4] := CurrentPixelFormat.PackRgbBytes(110, 125, 135);
  B.CaptionLabel.SetWordWrapEnabled(True);
  B.CaptionLabel.SetHitTestDisabled(True);
  B.SetDepth(0);
  B.SetActive(True);
  B.UpdateStateVisuals(False);
end;

procedure PrepareMobileCharacterSlider(Slider: TCountBarGI);
begin
  Slider.SetSize(Point(300, 44));
  Slider.FullHeightEndButtons := True;
  StyleButton(Slider.DecreaseButton, '-', 44, 44);
  StyleButton(Slider.IncreaseButton, '+', 44, 44);
  StyleButton(Slider.ThumbButton, '', 44, 44);
  Slider.MarkerImage.SetActive(False);
  Slider.UpdateLayout;
end;

function TMobileCharacterLayout.Control(const Name: WideString): TObjectGI;
begin
  Result := Screen.GetByName(Name);
end;

function TMobileCharacterLayout.LabelAt(Owner: TObjectGI; const Text: WideString; X, Y, W, H: Integer): TLabelGI;
begin
  Result := TLabelGI.Create(Owner);
  Result.SetPosition(Point(X, Y));
  Result.SetSize(Point(W, H));
  Result.SetFontName(SmoothHugeFontName);
  Result.SetTextColor(CurrentPixelFormat.PackRgbBytes(221, 235, 240));
  Result.SetTextAlignX(taxLeft);
  Result.SetTextAlignY(tayTop);
  Result.SetWordWrapEnabled(True);
  Result.SetText(Text);
  Result.SetHitTestDisabled(True);
end;

function TMobileCharacterLayout.ScrollAt(Owner: TObjectGI; X, Y, W, H: Integer): TPanelScrollBarGI;
begin
  Result := TPanelScrollBarGI.Create(Owner);
  Result.SetPosition(Point(X, Y));
  Result.SetSize(Point(W, H));
  Result.SetDragScrollingEnabled(True);
  Result.ScrollAxis := psaVertical;
  Result.AutoVerticalPlacement := True;
  Result.VerticalScrollBar.SetIndicatorThickness(3);
  Result.UpdateScrollbarPlacement;
end;

procedure TMobileCharacterLayout.Button(const Name, Caption: WideString; Owner: TObjectGI; X, Y, W, H: Integer);
var B: TGraphButtonGI;
begin
  B := Control(Name) as TGraphButtonGI;
  B.Reparent(Owner);
  B.SetPositionModeW(False);
  B.SetPosition(Point(X, Y));
  StyleButton(B, Caption, W, H);
end;

constructor TMobileCharacterLayout.CreateForScreen(AScreen: TMessageLoopGI);
var M: TMobileCharacterMetrics; I: Integer; Background: TImageGI; B: TGraphButtonGI;
const Names: array[0..3] of string = ('PanelChar', 'PanelSkills', 'PanelLevels', 'PanelExtended');
begin
  Screen := AScreen;
  inherited Create(Control('MainPanel'));
  SetName('MobileCharacterLayout');
  SetDepth(-100);
  M := MeasureMobileCharacter(GameScreenWidth, GameScreenHeight);
  SetSize(Point(M.Width, M.Height));
  BodyHeight := M.Height - 104;
  Background := TImageGI.Create(Self);
  Background.SetDepth(1000);
  PaintFrame(Background, M.Width, M.Height);
  Control('ImageFooter').SetActive(False);
  Control('ImageHelp').SetActive(False);
  for I := 0 to 3 do
  begin
    Pages[I] := Control(Names[I]);
    Pages[I].Reparent(Self);
    Pages[I].SetPosition(Point(8, 52));
    Pages[I].SetOrigin(Point(0, 0));
    Pages[I].SetSize(Point(M.Width - 16, BodyHeight));
    HideChildren(Pages[I]);
  end;
  for I := 0 to 2 do
  begin
    Tabs[I] := TGraphButtonGI.Create(Self);
    Tabs[I].UserValue := I;
    Tabs[I].SetKind(gbkFix);
    Tabs[I].SetPosition(Point(120 + I * 164, TabTop));
    Tabs[I].DownCallback := TabClicked;
    Tabs[I].UpCallback := TabClicked;
  end;
  StyleButton(Tabs[0], MobileText('Character', 'Персонаж'), 156, RowHeight);
  StyleButton(Tabs[1], MobileText('Starting bonuses', 'Стартовые бонусы'), 156, RowHeight);
  StyleButton(Tabs[2], MobileText('Difficulty', 'Сложность'), 156, RowHeight);
  MakeCharacter;
  MakeBonuses;
  MakeDifficulty;
  MakeExtended;
  // The footer row ends where the frame's lower bezel begins.
  Button('Cancel', MobileText('Back', 'Назад'), Self, 8, M.Height - 51, 136, RowHeight);
  Button('Ok', MobileText('Start game', 'Начать игру'), Self, M.Width - 184, M.Height - 51, 176, RowHeight);
  B := TGraphButtonGI.Create(Self);
  B.SetPosition(Point(156, M.Height - 51));
  StyleButton(B, MobileText('Selection help', 'О выбранном'), 160, RowHeight);
  B.UpCallback := HelpClicked;
  NameError := LabelAt(Self, MobileText('Enter a valid name', 'Введи имя персонажа'), 328, M.Height - 49, M.Width - 528, 36);
  NameError.SetActive(False);
  HelpPopup := TPanelGI.Create(Self);
  HelpPopup.SetPosition(Point(8, 52));
  HelpPopup.SetSize(Point(M.Width - 16, BodyHeight));
  HelpPopup.SetDepth(-1000);
  HelpPopup.MouseBlocking := True;
  Background := TImageGI.Create(HelpPopup);
  Background.SetDepth(1000);
  // Help replaces the page inside the main frame: the same glass, no second bezel.
  Background.AutoUpdateFlags := 0;
  Background.SetImagePath('GraphBuf');
  Background.SetOrigin(Point(0, 0));
  Background.SetSize(Point(HelpPopup.ClientSize.X, BodyHeight));
  with Background.GraphBufControl.GraphBuf do
  begin
    AllocateRgbaTight(HelpPopup.ClientSize.X, BodyHeight);
    FillRect32(Rect(0, 0, HelpPopup.ClientSize.X, BodyHeight), FrameGlassColor or $FF000000);
  end;
  Background.SetHitTestDisabled(True);
  B := TGraphButtonGI.Create(HelpPopup);
  B.SetPosition(Point(12, BodyHeight - 52));
  StyleButton(B, MobileText('Close help', 'Закрыть подсказку'), 240, 44);
  B.UpCallback := HelpClicked;
  HelpPopup.SetActive(False);
  PlaceControlAtScreen(Self, Point(8, 8), M.Scale);
end;

procedure TMobileCharacterLayout.MakeCharacter;
var I, W: Integer; C: TObjectGI; L: TLabelGI;
const Races: array[0..4] of string = ('Maloc', 'Peleng', 'People', 'Fei', 'Gaal');
begin
  W := Pages[0].ClientSize.X;
  LabelAt(Pages[0], LocalizedText('FormGameSet2.Common.Race'), 0, 0, 112, 22);
  LabelAt(Pages[0], LocalizedText('FormGameSet2.Common.Char'), 120, 0, 112, 22);
  for I := 0 to 4 do
  begin
    Button('Race' + Races[I], LocalizedText('FormGameSet2.Common.' + Races[I]), Pages[0], 0, 24 + I * 46, 112, 44);
    Button('Char' + IntToStr(I + 1), LocalizedText('FormGameSet2.Common.Char' + IntToStr(I + 1)), Pages[0], 120, 24 + I * 46, 112, 44);
  end;
  for I := 0 to 1 do
  begin
    if I = 0 then C := Control('CaptainI') else C := Control('CaptainA');
    C.SetPosition(Point(258, 24));
    C.SetActive(True);
  end;
  Button('FaceLeft', '<', Pages[0], 244, 152, 56, 44);
  Button('FaceRight', '>', Pages[0], 308, 152, 56, 44);
  LabelAt(Pages[0], MobileText('Portrait', 'Портрет'), 244, 204, 128, 40);
  LabelAt(Pages[0], LocalizedText('FormGameSet2.Common.Name'), 388, 0, W - 396, 22);
  with Control('PlayerName') as TEditGI do
  begin
    SetPosition(Point(388, 24));
    SetSize(Point(W - 396, 44));
    SetFontName(SmoothHugeFontName);
    SetBorderEnabled(True);
    SetActive(True);
  end;
  Description := ScrollAt(Pages[0], 388, 80, W - 396, BodyHeight - 132);
  L := Control('Info') as TLabelGI;
  L.Reparent(Description);
  L.SetPositionModeW(True);
  L.SetPosition(Point(0, 0));
  L.SetSize(Point(Description.ClientSize.X - 10, 1));
  L.SetFontName(SmoothHugeFontName);
  L.SetTextAlignX(taxLeft);
  L.SetTextAlignY(tayAuto);
  L.SetWordWrapEnabled(True);
  L.SetActive(True);
  L.SetHitTestDisabled(True);
end;

procedure TMobileCharacterLayout.MakeBonuses;
var I, X, Y: Integer; L: TLabelGI; C: TObjectGI;
const Skills: array[1..6] of string = ('sAccuracy', 'sMobility', 'sTechnical', 'sTrader', 'sCharm', 'sLeadership');
  RussianSkills: array[1..6] of WideString = ('Точность', 'Манёвренность', 'Техника', 'Торговля', 'Обаяние', 'Лидерство');
begin
  LabelAt(Pages[1], LocalizedText('FormGameSet2.Common.Skill'), 0, 0, 260, 24);
  for I := 1 to 6 do
  begin
    X := ((I - 1) mod 2) * (SkillWidth + 8);
    Y := 28 + ((I - 1) div 2) * 52;
    Button(
        'Skill' + IntToStr(I),
        MobileText(LocalizedText('Skills.' + Skills[I] + '.Name'), RussianSkills[I]),
        Pages[1],
        X,
        Y,
        SkillWidth,
        44
    );
  end;
  LabelAt(
      Pages[1],
      MobileText('Tap a selected bonus, then its replacement.', 'Нажми выбранный бонус, затем его замену.'),
      0,
      192,
      2 * SkillWidth + 8,
      60
  );
  LabelAt(Pages[1], LocalizedText('FormGameSet2.Common.Item'), ItemsLeft, 0, 258, 24);
  for I := 1 to 12 do
  begin
    X := ItemsLeft + ((I - 1) mod 4) * 60;
    Y := 28 + ((I - 1) div 4) * 68;
    Button('Item' + IntToStr(I), '', Pages[1], X, Y, 52, 60);
    // Equipment cells use the original slot faces of this screen.
    with Control('Item' + IntToStr(I)) as TGraphButtonGI do
    begin
      PaintMobileButtonArt(ImageNormal, 'Bm.FormGameSet2.' + GiResourceSuffix + 'ItemA', 52, 60, 8);
      PaintMobileButtonArt(ImageDown, 'Bm.FormGameSet2.' + GiResourceSuffix + 'ItemD', 52, 60, 8);
      UpdateStateVisuals(False);
    end;
    C := Control('ItemI' + IntToStr(I));
    C.SetPosition(Point(X + 8, Y + 12));
    C.SetDepth(-2);
    C.SetHitTestDisabled(True);
    C.SetActive(True);
  end;
  Help := ScrollAt(Pages[1], BonusHelpLeft, 0, Pages[1].ClientSize.X - BonusHelpLeft - 8, BodyHeight);
  L := Control('LabelHelp') as TLabelGI;
  L.Reparent(Help);
  L.SetPositionModeW(True);
  L.SetPosition(Point(0, 0));
  L.SetSize(Point(Help.ClientSize.X - 10, 1));
  L.SetFontName(SmoothHugeFontName);
  L.SetTextAlignX(taxLeft);
  L.SetTextAlignY(tayAuto);
  L.SetWordWrapEnabled(True);
  L.SetHitTestDisabled(True);
  L.SetActive(True);
  PaintMobileButtonArt(Control('SkillCur') as TImageGI, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageD', SkillWidth, 44, 10);
  OutlineFace(Control('SkillCur') as TImageGI, 3, $FFC467);
  PaintMobileButtonArt(Control('ItemCur') as TImageGI, 'Bm.FormGameSet2.' + GiResourceSuffix + 'ItemD', 52, 60, 8);
  OutlineFace(Control('ItemCur') as TImageGI, 3, $FFC467);
  Control('SkillCur').SetDepth(-5);
  Control('ItemCur').SetDepth(-5);
  Control('SkillCur').SetActive(True);
  Control('ItemCur').SetActive(True);
end;

procedure TMobileCharacterLayout.MakeDifficulty;
var I, J, W: Integer; List: TPanelScrollBarGI; Row: TPanelGI; L: TLabelGI; B: TGraphButtonGI;
begin
  W := Pages[2].ClientSize.X;
  for I := 1 to 4 do
    Button('Level' + IntToStr(I), LocalizedText('FormGameSet2.Common.Level' + IntToStr(I)), Pages[2], (I - 1) * 138, 0, 130, 44);
  with Control('LevelProc') as TLabelGI do
  begin
    Reparent(Pages[2]); SetPosition(Point(560, 8)); SetSize(Point(W - 568, 28));
    SetFontName(SmoothHugeFontName); SetActive(True);
  end;
  List := ScrollAt(Pages[2], 0, 54, W, BodyHeight - 106);
  for I := 0 to 7 do
  begin
    Row := TPanelGI.Create(List);
    Row.SetPositionModeW(True);
    Row.SetPosition(Point(0, I * 74));
    Row.SetSize(Point(W - 12, 68));
    LabelAt(Row, LocalizedText('FormGameSet2.Common.LevelGroup' + IntToStr(I + 1)), 0, 0, W - 12, 22);
    for J := 1 to 4 do
    begin
      B := Control('Level' + IntToStr(J) + '_' + IntToStr(I)) as TGraphButtonGI;
      Button(B.ControlName, '', Row, (J - 1) * ((W - 16) div 4), 24, (W - 40) div 4, 44);
      // Their coloured labels need darker faces than the bright pressed tab.
      PaintMobileButtonArt(B.ImageNormal, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageN', (W - 40) div 4, 44, 10);
      PaintMobileButtonArt(B.ImageDown, 'Bm.FormOptions2.' + GiResourceSuffix + 'PageD', (W - 40) div 4, 44, 10);
      DimFaceMiddle(B.ImageDown, 4);
      B.UpdateStateVisuals(False);
      L :=Control('NameGroup' + IntToStr(I + 1) + 'Level' + IntToStr(J - 1)) as TLabelGI;
      L.Reparent(B); L.SetDepth(-10); L.SetPosition(Point(0, 0)); L.SetSize(B.ClientSize);
      L.SetFontName(SmoothHugeFontName); L.SetTextAlignY(tayCenterEx); L.SetActive(True); L.SetHitTestDisabled(True);
    end;
  end;
  List.UpdateScrollRanges;
  Button('ButExtended', MobileText('Use custom rules', 'Особые правила'), Pages[2], 0, BodyHeight - 44, 240, 44);
  B := TGraphButtonGI.Create(Pages[2]);
  B.SetPosition(Point(250, BodyHeight - 44));
  StyleButton(B, MobileText('Edit rules', 'Настроить правила'), 240, 44);
  B.UpCallback := DetailsClicked;
end;

procedure TMobileCharacterLayout.MakeExtended;
var I: Integer; Panel: TPanelScrollBarGI; B: TGraphButtonGI;
begin
  for I := 0 to 2 do
  begin
    B := Control('ButGroup' + IntToStr(I)) as TGraphButtonGI;
    Button(B.ControlName, B.CaptionLabel.GetText, Pages[3], 0, I * 52, 160, 44);
  end;
  B := Control('ButReset') as TGraphButtonGI;
  Button('ButReset', B.CaptionLabel.GetText, Pages[3], 0, BodyHeight - 96, 160, 44);
  Button('ButCloseExt', MobileText('Back to difficulty', 'К сложности'), Pages[3], 0, BodyHeight - 44, 160, 44);
  Panel := Control('PanelSet') as TPanelScrollBarGI;
  Panel.SetPosition(Point(176, 0));
  Panel.SetSize(Point(Pages[3].ClientSize.X - 192, BodyHeight));
  Panel.AutoVerticalPlacement := True;
  { OnOpen clears the scroll contents. Keep its scrollbars owned by the page. }
  Panel.SetScrollbarsOutside(True);
  Panel.SetDragScrollingEnabled(True);
  Panel.VerticalScrollBar.SetIndicatorThickness(3);
  Panel.UpdateScrollbarPlacement;
  Panel.SetActive(True);
end;

procedure TMobileCharacterLayout.TabClicked(Sender: TObjectGI);
begin
  ShowPage(Sender.UserValue);
end;

procedure TMobileCharacterLayout.DetailsClicked(Sender: TObjectGI);
begin
  (Control('ButExtended') as TGraphButtonGI).SetDown(True);
  ShowPage(3);
end;

procedure TMobileCharacterLayout.ShowPage(Index: Integer);
var I: Integer;
begin
  CloseHelp;
  CurrentPage := Index;
  for I := 0 to 3 do Pages[I].SetActive(I = Index);
  for I := 0 to 2 do Tabs[I].SetDown((I = Index) or ((I = 2) and (Index = 3)));
  Screen.SetFocusedControl(nil);
  if Index = 0 then UpdateDescription;
end;

procedure TMobileCharacterLayout.Open(IronImage, IronLabel: TObjectGI);
begin
  IronImage.SetPosition(Point(388, BodyHeight - 44));
  IronImage.SetSize(Point(44, 44));
  IronImage.SetActive(True);
  with IronLabel as TLabelGI do
  begin
    SetPosition(Point(436, BodyHeight - 44));
    SetSize(Point(Pages[0].ClientSize.X - 444, 44));
    SetFontName(SmoothHugeFontName);
    SetTextAlignY(tayCenterEx);
    SetActive(True);
  end;
  Control('LevelOpen').SetActive(False);
  Control('LevelClose').SetActive(False);
  ShowPage(0);
end;

procedure TMobileCharacterLayout.UpdateDescription;
begin
  Description.UpdateScrollRanges;
  Description.SetScrollOffset(Point(0, 0));
end;

procedure TMobileCharacterLayout.UpdateCursor(const CursorName, ButtonName: WideString);
begin
  Control(CursorName).SetPosition(Control(ButtonName).LocalPosition);
end;

procedure TMobileCharacterLayout.ShowHelp(Sender: TObjectGI);
begin
  if (Sender = nil) or (Sender.HelpText = '') then Exit;
  with Control('LabelHelp') as TLabelGI do
  begin
    SetText(Sender.HelpText);
    SetActive(True);
  end;
  Help.UpdateScrollRanges;
  Help.SetScrollOffset(Point(0, 0));
end;

procedure TMobileCharacterLayout.NameValidityChanged(Valid: Boolean);
begin
  NameError.SetActive(not Valid);
end;

procedure TMobileCharacterLayout.HelpClicked(Sender: TObjectGI);
begin
  if CloseHelp then Exit;
  Help.Reparent(HelpPopup);
  Help.SetPosition(Point(12, 12));
  Help.SetSize(Point(HelpPopup.ClientSize.X - 24, BodyHeight - 76));
  Control('LabelHelp').SetSize(Point(Help.ClientSize.X - 10, 1));
  (Control('LabelHelp') as TLabelGI).SetFontName(SmoothHugeFontName);
  Control('LabelHelp').SetActive(True);
  HelpPopup.SetActive(True);
  Help.UpdateScrollRanges;
  Help.SetScrollOffset(Point(0, 0));
end;

function TMobileCharacterLayout.CloseHelp: Boolean;
begin
  Result := (HelpPopup <> nil) and HelpPopup.Active;
  if not Result then Exit;
  HelpPopup.SetActive(False);
  Help.Reparent(Pages[1]);
  Help.SetPosition(Point(BonusHelpLeft, 0));
  Help.SetSize(Point(Pages[1].ClientSize.X - BonusHelpLeft - 8, BodyHeight));
  Control('LabelHelp').SetSize(Point(Help.ClientSize.X - 10, 1));
  (Control('LabelHelp') as TLabelGI).SetFontName(SmoothHugeFontName);
  Help.UpdateScrollRanges;
  Help.SetScrollOffset(Point(0, 0));
end;

end.
