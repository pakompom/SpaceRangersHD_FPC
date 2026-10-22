unit GI_IntroductionLayout;

{$I GameOptions.inc}
{$codepage utf8}

interface

uses GI_MessageLoop, GI_Panel, GI_PanelScrollBar, GI_Label;

type
  { The generation thread and Continue action remain owned by fIntroduction. }
  TMobileIntroductionLayout = class(TPanelGI)
  private
    StoryScroll: TPanelScrollBarGI;
    Story, Status, ContinueHint: TLabelGI;
    LastStage: Integer;
  public
    constructor CreateForScreen(Screen: TMessageLoopGI);
    procedure SetStory(const Text: WideString);
    procedure SetStage(Stage: Integer);
    procedure SetReady;
  end;

implementation

uses Classes, Types, Math, SysUtils, EC_Str, GI_Main, GI_GraphBuf, GI_GraphButton,
  GI_Artwork, GI_LayoutMetrics, GR_GraphBuf, GR_Main, GameWindow, Globals,
  GlobalsV, aConst;

function Caption(const English, Russian: WideString): WideString;
begin
  if LowerCaseWideString(SelectedLanguage) = 'russian' then Result := Russian else Result := English;
end;

function ReaderLabel(Owner: TObjectGI; X, Y, W, H: Integer; const Font: WideString): TLabelGI;
begin
  Result := TLabelGI.Create(Owner);
  Result.SetPosition(Point(X, Y));
  Result.SetSize(Point(W, H));
  Result.SetFontName(Font);
  Result.SetTextAlignX(taxLeft);
  Result.SetTextAlignY(tayCenterEx);
  Result.SetWordWrapEnabled(True);
  Result.SetTextColor(CurrentPixelFormat.PackRgbBytes(224, 235, 228));
  Result.SetHitTestDisabled(True);
end;

constructor TMobileIntroductionLayout.CreateForScreen(Screen: TMessageLoopGI);
var
  M: TMobileCharacterMetrics;
  Left, W, H, I: Integer;
  Frame, Fill, Scratch: TGraphBufGR;
  Artwork: TGraphBufGI;
  B: TGraphButtonGI;
begin
  inherited Create(Screen.GetByName('MainPanel'));
  SetName('MobileIntroduction');
  SetDepth(-100);
  M := MeasureMobileCharacter(GameScreenWidth, GameScreenHeight);
  SetSize(Point(M.Width, M.Height));
  Left := M.Width div 4;
  W := M.Width - Left - 8;
  H := M.Height - 4;
  Screen.GetByName('PanelText').SetActive(False);
  for I := 1 to 8 do
    Screen.GetByName('MCW' + IntToStr(I)).SetActive(False);
  { Old progress lights still receive updates, but remain behind the new reader. }
  Artwork := TGraphBufGI.Create(Self, True);
  Artwork.SetPosition(Point(Left, 0));
  Artwork.SetSize(Point(W, H));
  Artwork.SetDepth(100);
  Artwork.SetHitTestDisabled(True);
  Artwork.SourceHasPerPixelAlpha := True;
  Frame := TGraphBufGR.Create(False);
  Fill := TGraphBufGR.Create(False);
  Scratch := TGraphBufGR.Create(False);
  try
    LoadOriginalGiArtwork('Bm.FormGov2.' + GiResourceSuffix + 'TWin', Frame);
    LoadOriginalGiArtwork('Bm.FormGov2.' + GiResourceSuffix + 'TWinB', Fill);
    Artwork.GraphBuf.AllocateRgbaTight(W, H);
    Artwork.GraphBuf.FillPixels(0);
    Artwork.GraphBuf.DrawNinePatch(10, H - 122, W - 43, 88, Fill,
        Rect(0, 0, Fill.Width, Fill.Height), Rect(172, 12, 172, 26));
    Scratch.AllocateRgbaTight(W, H);
    Scratch.FillPixels(0);
    { Recompose the game's rounded bezel; stretch only its plain middle strips. }
    Scratch.DrawNinePatch(0, 0, W, H - 116, Frame, Rect(0, 0, Frame.Width, 430), Rect(190, 54, 190, 42));
    Scratch.DrawNinePatch(0, H - 116, W, 116, Frame, Rect(0, 430, Frame.Width, Frame.Height), Rect(190, 32, 190, 52));
    Artwork.GraphBuf.BlendRect32(Point(0, 0), Scratch, Rect(0, 0, W, H));
  finally
    Scratch.Free;
    Fill.Free;
    Frame.Free;
  end;
  StoryScroll := TPanelScrollBarGI.Create(Self);
  StoryScroll.SetPosition(Point(Left + 27, 54));
  StoryScroll.SetSize(Point(W - 64, H - 190));
  StoryScroll.SetDragScrollingEnabled(True);
  StoryScroll.ScrollAxis := psaVertical;
  StoryScroll.AutoVerticalPlacement := True;
  StoryScroll.VerticalScrollBar.SetIndicatorThickness(3);
  StoryScroll.UpdateScrollbarPlacement;
  Story := ReaderLabel(StoryScroll, 0, 0, StoryScroll.ClientSize.X - 10, 1, SmoothIntroFontName);
  Story.SetPositionModeW(True);
  Story.SetTextAlignY(tayAuto);
  Story.SetTextColor(CurrentPixelFormat.PackRgbBytes(12, 29, 35));
  ReaderLabel(Self, Left + 32, 11, W - 80, 34, SmoothHugeFontName).SetText(Caption('THE BEGINNING', 'НАЧАЛО ИСТОРИИ'));
  Status := ReaderLabel(Self, Left + 30, H - 94, W - 268, 30, SmoothHugeFontName);
  Status.SetTextColor(CurrentPixelFormat.PackRgbBytes(12, 29, 35));
  ContinueHint := ReaderLabel(Self, M.Width - 246, H - 94, 145, 30, SmoothHugeFontName);
  ContinueHint.SetTextColor(CurrentPixelFormat.PackRgbBytes(12, 29, 35));
  ContinueHint.SetText(Caption('Preparing...', 'Подготовка...'));
  LastStage := -1;
  SetStage(0);
  PlaceControlAtScreen(Self, Point(8, 8), M.Scale);
  B := Screen.GetByName('Ok') as TGraphButtonGI;
  B.Reparent(Self);
  B.HitKind := gbhRect;
  PlaceControlAtScreen(B, Point(8 + Round((M.Width - 90) * M.Scale), 8 + Round((H - 101) * M.Scale)),
      M.Scale * 48 / B.ClientSize.Y);
end;

procedure TMobileIntroductionLayout.SetStory(const Text: WideString);
begin
  StoryScroll.SetScrollOffset(Point(0, 0));
  ContinueHint.SetText(Caption('Preparing...', 'Подготовка...'));
  LastStage := -1;
  SetStage(0);
  Story.SetText(Text);
  StoryScroll.UpdateScrollRanges;
  StoryScroll.VerticalScrollBar.SetLargeChange(StoryScroll.ClientSize.Y);
end;

procedure TMobileIntroductionLayout.SetStage(Stage: Integer);
begin
  Stage := EnsureRange(Stage, 0, 7);
  if Stage = LastStage then Exit;
  LastStage := Stage;
  Status.SetText(LocalizedText('FormIntroduction.MCW' + IntToStr(Stage + 1)));
end;

procedure TMobileIntroductionLayout.SetReady;
begin
  Status.SetText(Caption('Galaxy ready', 'Галактика готова'));
  ContinueHint.SetText(Caption('Continue', 'Продолжить'));
end;

end.
