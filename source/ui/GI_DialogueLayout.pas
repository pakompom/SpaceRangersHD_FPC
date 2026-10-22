unit GI_DialogueLayout;

{$I GameOptions.inc}

interface

uses
  Types,
  GI_MessageLoop,
  GI_Label,
  GI_PanelScrollBar;

// Called once after the original control tree has been loaded.
procedure PrepareDialoguePanel(TalkPanel: TObjectGI; ContentHeight: Integer; const Bounds: TRect);
procedure FitDialogueChoices(TalkPanel: TObjectGI; ChoicesHeight: Integer);
procedure RefreshDialogueText(Panel: TPanelScrollBarGI; LabelControl: TLabelGI; const Text: WideString);
procedure ShowDialogueChoices(Panel: TPanelScrollBarGI; ContentHeight, LineHeight: Integer; var SavedScroll: Integer);
function DialogueChoiceHeight(Row: TObjectGI; NaturalHeight: Integer): Integer;

implementation

uses
  Classes,
  Math,
  SysUtils,
  GameWindow,
  GlobalsV,
  GR_Main,
  GI_Main,
  GI_Image,
  GI_Artwork,
  GI_LayoutMetrics,
  GI_GraphBuf,
  GI_MobileSkin,
  EC_Struct,
  GR_GraphBuf;

const
  // Story and replies read at about the journal's type size. Only they use it:
  // the original bezel at this scale would take the height they gain.
  MobileDialogueTextDp = 1.0;
  // The separator's upper bezel covers this much of the story glass.
  StoryBottomMargin = 30;

type
  // Owned by TalkPanel. Source artwork is decoded once; changing the answer
  // area only recomposes the retained buffers.
  TDialogueArtworkGI = class(TGraphBufGI)
  private
    Frame, Fill, Scratch: TGraphBufGR;
    LastWidth, LastHeight, LastTextBottom: Integer;
  public
    // Story top in TalkPanel units and the story/reply scale relative to TalkPanel.
    TextTop: Integer;
    TextScale: Single;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    function UpdateFrame(Width, Height, TextBottom: Integer): Boolean;
  end;

procedure LayoutDesktopDialogue(TalkPanel: TObjectGI; ContentHeight: Integer);
var
  ChoiceExtra, TextExtra: Integer;
  Expansion: TDialogueExpansion;
  Child, AddButton, CloseButton, TextLabel: TObjectGI;
  TextPanel, ChoicePanel: TPanelScrollBarGI;
  Border, BottomBorder, Separator, Decoration: TObjectGI;
begin
  Expansion := MeasureDialogueExpansion(ContentHeight);
  TextExtra := Expansion.Text;
  ChoiceExtra := Expansion.Choices;
  TalkPanel.SetPosition(Classes.Point(TalkPanel.LocalPosition.X + ExtraScreenWidth div 2, TalkPanel.LocalPosition.Y));
  TalkPanel.SetSize(Classes.Point(TalkPanel.ClientSize.X, TalkPanel.ClientSize.Y + TextExtra + ChoiceExtra));
  Child := TalkPanel.FirstChild;
  TImageGI(Child).SetImagePath('GI,Bm.FormGov2.' + GiResourceSuffix + 'TWinB?content-height=' + IntToStr(ContentHeight));
  Child.SetPosition(Classes.Point(Child.LocalPosition.X, Child.LocalPosition.Y + TextExtra));
  Child.SetSize(Classes.Point(Child.ClientSize.X, Child.ClientSize.Y + ChoiceExtra));
  AddButton := TalkPanel.FindByNameRecursive('UserMsgAdd');
  AddButton.SetPosition(Classes.Point(AddButton.LocalPosition.X, AddButton.LocalPosition.Y + TextExtra));
  CloseButton := TalkPanel.FindByNameRecursive('ButFormClose');
  CloseButton.SetPosition(Classes.Point(CloseButton.LocalPosition.X, CloseButton.LocalPosition.Y + TextExtra + ChoiceExtra));
  TextPanel := TalkPanel.FindByNameRecursive('TextScroll') as TPanelScrollBarGI;
  TextPanel.SetSize(Classes.Point(TextPanel.ClientSize.X, TextPanel.ClientSize.Y + TextExtra));
  TextPanel.VerticalScrollBar.SetSize(
      Classes.Point(TextPanel.VerticalScrollBar.ClientSize.X, TextPanel.VerticalScrollBar.ClientSize.Y + TextExtra)
  );
  TextLabel := TextPanel.FindByNameRecursive('TalkText');
  TextLabel.SetSize(Classes.Point(TextLabel.ClientSize.X, TextLabel.ClientSize.Y + TextExtra));
  ChoicePanel := TalkPanel.FindByNameRecursive('TalkPA') as TPanelScrollBarGI;
  ChoicePanel.SetPosition(Classes.Point(ChoicePanel.LocalPosition.X, ChoicePanel.LocalPosition.Y + TextExtra));
  ChoicePanel.SetSize(Classes.Point(ChoicePanel.ClientSize.X, ChoicePanel.ClientSize.Y + ChoiceExtra));
  TObjectGI(ChoicePanel.VerticalScrollBar)
      .SetPosition(Classes.Point(ChoicePanel.VerticalScrollBar.LocalPosition.X, ChoicePanel.VerticalScrollBar.LocalPosition.Y + TextExtra));
  ChoicePanel.VerticalScrollBar.SetSize(
      Classes.Point(ChoicePanel.VerticalScrollBar.ClientSize.X, ChoicePanel.VerticalScrollBar.ClientSize.Y + ChoiceExtra)
  );
  Border := ChoicePanel.NextSibling;
  TImageGI(Border).SetImagePath('GI,Bm.FormGov2.' + GiResourceSuffix + 'TWin?content-height=' + IntToStr(ContentHeight));
  Border.SetSize(Classes.Point(Border.ClientSize.X, Border.ClientSize.Y + TextExtra + ChoiceExtra));
  BottomBorder := Border.NextSibling;
  BottomBorder.SetPosition(Classes.Point(BottomBorder.LocalPosition.X, BottomBorder.LocalPosition.Y + TextExtra + ChoiceExtra));
  Separator := BottomBorder.NextSibling;
  Separator.SetPosition(Classes.Point(Separator.LocalPosition.X, Separator.LocalPosition.Y + TextExtra));
  Decoration := Separator.NextSibling;
  Decoration.SetPosition(Classes.Point(Decoration.LocalPosition.X, Decoration.LocalPosition.Y + TextExtra));
end;

constructor TDialogueArtworkGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner, True);
  Frame := TGraphBufGR.Create(False);
  Fill := TGraphBufGR.Create(False);
  Scratch := TGraphBufGR.Create(False);
  LoadOriginalGiArtwork('Bm.FormGov2.' + GiResourceSuffix + 'TWin', Frame);
  LoadOriginalGiArtwork('Bm.FormGov2.' + GiResourceSuffix + 'TWinB', Fill);
  SourceHasPerPixelAlpha := True;
  SetImageKindX(ikxLeft);
  SetImageKindY(ikyTop);
end;

destructor TDialogueArtworkGI.Destroy;
begin
  Scratch.Free;
  Fill.Free;
  Frame.Free;
  inherited Destroy;
end;

function TDialogueArtworkGI.UpdateFrame(Width, Height, TextBottom: Integer): Boolean;
begin
  Result := (LastWidth <> Width) or (LastHeight <> Height) or (LastTextBottom <> TextBottom);
  if not Result then
    Exit;
  GraphBuf.AllocateRgbaTight(Width, Height);
  GraphBuf.FillPixels(0);
  GraphBuf.DrawNinePatch(
      10,
      TextBottom - 6,
      Width - 43,
      Height - TextBottom - 34,
      Fill,
      Rect(0, 0, Fill.Width, Fill.Height),
      Rect(172, 12, 172, 26)
  );
  Scratch.AllocateRgbaTight(Width, Height);
  Scratch.FillPixels(0);
  // Keep the rounded header, the centre separator and the lower bezel.
  // Only plain strips repeat; the original corners are never stretched.
  Scratch.DrawNinePatch(0, 0, Width, TextBottom, Frame, Rect(0, 0, Frame.Width, 430), Rect(190, 54, 190, 42));
  Scratch.DrawNinePatch(0, TextBottom, Width, Height - TextBottom, Frame, Rect(0, 430, Frame.Width, Frame.Height), Rect(190, 32, 190, 52));
  GraphBuf.BlendRect32(Point(0, 0), Scratch, Rect(0, 0, Width, Height));
  // Like the journal, the bezel lets the scene show through; the glass behind
  // the story and the replies stays opaque for contrast.
  GraphBuf.ScaleAlpha(Rect(0, 0, Width, TextTop), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(0, TextTop, 25, TextBottom - 16), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(Width - 41, TextTop, Width, TextBottom - 16), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(0, TextBottom - 16, Width, TextBottom + 10), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(0, TextBottom + 10, 12, Height - 54), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(Width - 34, TextBottom + 10, Width, Height - 54), MobileReadingWindowAlpha);
  GraphBuf.ScaleAlpha(Rect(0, Height - 54, Width, Height), MobileReadingWindowAlpha);
  SetSize(Point(Width, Height));
  LastWidth := Width;
  LastHeight := Height;
  LastTextBottom := TextBottom;
end;

// Places a panel with its own larger scale over Area, given in TalkPanel units.
procedure PlaceInFrame(TalkPanel: TObjectGI; Panel: TPanelScrollBarGI; const Area: TRect; RelativeScale: Single);
var
  Scale: Single;
begin
  TalkPanel.UpdateAbsolutePosition;
  Scale := TalkPanel.GetDisplayScale;
  PlaceControlAtScreen(
      Panel,
      MakePointF((TalkPanel.AbsolutePosition.X + Area.Left) * Scale, (TalkPanel.AbsolutePosition.Y + Area.Top) * Scale),
      Scale * RelativeScale
  );
  Panel.SetSize(Point(Floor((Area.Right - Area.Left) / RelativeScale), Floor((Area.Bottom - Area.Top) / RelativeScale)));
  // The bars stay outside, owned by TalkPanel: choice clearing frees every
  // child of the panel. Automatic placement would mix the panel's units with
  // TalkPanel's, so place them in TalkPanel units here.
  if Panel.ScrollbarsOutside then
  begin
    Panel.AutoVerticalPlacement := False;
    Panel.AutoHorizontalPlacement := False;
    Panel.VerticalScrollBarRect := Rect(Area.Right, Area.Top, Area.Right + Panel.VerticalScrollBar.ClientSize.X, Area.Bottom);
    Panel.HorizontalScrollBarRect := Rect(Area.Left, Area.Bottom, Area.Right, Area.Bottom + Panel.HorizontalScrollBar.ClientSize.Y);
    Panel.UpdateScrollbarPlacement;
  end;
end;

procedure FitDialogueChoices(TalkPanel: TObjectGI; ChoicesHeight: Integer);
var
  Artwork: TDialogueArtworkGI;
  TextPanel, ChoicePanel: TPanelScrollBarGI;
  TextBottom, Width, Height: Integer;
  LineHeight: Single;
begin
  Artwork := TalkPanel.FindByNameRecursive('MobileDialogueArtwork') as TDialogueArtworkGI;
  if Artwork = nil then
    Exit;
  Width := TalkPanel.ClientSize.X;
  Height := TalkPanel.ClientSize.Y;
  // A short reply must not reserve a third of the screen. Longer menus keep
  // a bounded, scrollable answer area and reserve space for the story.
  // ChoicesHeight is in reply-panel units, which are larger than the frame's.
  TextBottom := Height - EnsureRange(Ceil(ChoicesHeight * Artwork.TextScale) + 68, 88, 168);
  TextPanel := TalkPanel.FindByNameRecursive('TextScroll') as TPanelScrollBarGI;
  // Show whole story lines: a line cut through the middle reads as a glitch.
  // The spare height goes to the replies.
  LineHeight := (TextPanel.FindByNameRecursive('TalkText') as TLabelGI).GetLineHeight * Artwork.TextScale;
  if LineHeight > 0 then
    // Glyph descenders reach past the last line box: keep a third of a line spare.
    TextBottom := Artwork.TextTop + StoryBottomMargin + Ceil(
        Max(1, Floor((TextBottom - StoryBottomMargin - Artwork.TextTop - LineHeight / 3) / LineHeight)) * LineHeight + LineHeight / 3);
  if not Artwork.UpdateFrame(Width, Height, TextBottom) then
    Exit;
  PlaceInFrame(TalkPanel, TextPanel, Rect(25, Artwork.TextTop, Width - 41, TextBottom - StoryBottomMargin), Artwork.TextScale);
  TextPanel.UpdateScrollRanges;
  TextPanel.VerticalScrollBar.SetLargeChange(TextPanel.ClientSize.Y);
  TextPanel.VerticalScrollBar.SetActive(TextPanel.FindByNameRecursive('TalkText').ClientSize.Y > TextPanel.ClientSize.Y);
  ChoicePanel := TalkPanel.FindByNameRecursive('TalkPA') as TPanelScrollBarGI;
  PlaceInFrame(TalkPanel, ChoicePanel, Rect(12, TextBottom + 10, Width - 34, Height - 54), Artwork.TextScale);
  ChoicePanel.UpdateScrollbarPlacement;
  TalkPanel.FindByNameRecursive('ButFormClose').SetPosition(Point(Width - 116, Height - 50));
  TalkPanel.FindByNameRecursive('UserMsgAdd').SetPosition(Point(Width - 41, TextBottom - 34));
  TalkPanel.UpdateAbsolutePosition;
  TalkPanel.UpdateSubtreeHitBounds;
  TalkPanel.MessageLoop.InvalidateViewport;
end;

procedure LayoutMobileDialogue(TalkPanel: TObjectGI; const Bounds: TRect);
var
  Scale: Single;
  Width, Height, PanelLeft, PanelTop: Integer;
  Child: TObjectGI;
  TextPanel, ChoicePanel: TPanelScrollBarGI;
  Artwork: TDialogueArtworkGI;
  FrameDepth: Double;

  procedure PrepareScroll(Panel: TPanelScrollBarGI);
  begin
    Panel.SetDragScrollingEnabled(True);
    Panel.AutoVerticalPlacement := True;
    Panel.VerticalScrollBar.SetIndicatorThickness(2);
    Panel.UpdateScrollbarPlacement;
  end;

begin
  // A phone needs a wider, shorter reading surface. Keep the original bezel
  // and portrait, while allowing large type and separately scrolling replies.
  PanelTop := Bounds.Top + 12;
  Scale := Min(GetGameMobileUiScale(1.05), (Bounds.Bottom - PanelTop - 8) / 340);
  Scale := Min(Scale, (Bounds.Right - Bounds.Left - 24) * 0.62 / 470);
  // Wider than the original 470 where the screen allows, so the larger type
  // keeps its words per line. The portrait side stays free.
  Width := EnsureRange(Floor((Bounds.Right - Bounds.Left - 24) * 0.62 / Scale), 470, 600);
  Height := Min(620, Floor((Bounds.Bottom - PanelTop - 8) / Scale));
  PanelLeft := Max(Bounds.Left + 12, (Bounds.Left + Bounds.Right) div 2 - Round(Width * Scale) - 42);
  PlaceControlAtScreen(TalkPanel, Point(PanelLeft, PanelTop), Scale);
  TalkPanel.SetSize(Point(Width, Height));
  TextPanel := TalkPanel.FindByNameRecursive('TextScroll') as TPanelScrollBarGI;
  ChoicePanel := TalkPanel.FindByNameRecursive('TalkPA') as TPanelScrollBarGI;
  FrameDepth := TalkPanel.FirstChild.Depth;
  Child := TalkPanel.FirstChild;
  while Child <> nil do
  begin
    if Child is TImageGI then
      Child.SetActive(False);
    Child := Child.NextSibling;
  end;
  Artwork := TDialogueArtworkGI.Create(TalkPanel);
  Artwork.SetName('MobileDialogueArtwork');
  Artwork.SetDepth(FrameDepth);
  // Leave the first story line below Android's Controls toggle.
  Artwork.TextTop := Max(55, Ceil((56 * GetGameMobileUiScale - PanelTop) / Scale));
  Artwork.TextScale := Max(1, GetGameMobileUiScale(MobileDialogueTextDp) / Scale);

  PrepareScroll(TextPanel);
  PrepareScroll(ChoicePanel);
  FitDialogueChoices(TalkPanel, 100);
  with TextPanel.FindByNameRecursive('TalkText') do
  begin
    SetPosition(Point(0, 0));
    SetSize(Point(TextPanel.ClientSize.X, 1));
  end;
end;

procedure PrepareDialoguePanel(TalkPanel: TObjectGI; ContentHeight: Integer; const Bounds: TRect);
begin
  if GameMobileUiEnabled and HardwareRenderingEnabled then
    LayoutMobileDialogue(TalkPanel, Bounds)
  else
    LayoutDesktopDialogue(TalkPanel, ContentHeight);
end;

procedure RefreshDialogueText(Panel: TPanelScrollBarGI; LabelControl: TLabelGI; const Text: WideString);
begin
  if GameMobileUiEnabled then
    LabelControl.SetTextAlignX(taxLeft);
  LabelControl.SetText(Text);
  Panel.SetScrollOffset(Point(0, 0));
  Panel.UpdateScrollRanges;
  Panel.VerticalScrollBar.SetActive(LabelControl.ClientSize.Y > Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetSmallChange(LabelControl.GetLineHeight);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
end;

function DialogueChoiceHeight(Row: TObjectGI; NaturalHeight: Integer): Integer;
begin
  Result := NaturalHeight;
  if GameMobileUiEnabled and HardwareRenderingEnabled then
    Result := Max(Result, Ceil(44 * GetGameMobileUiScale / Row.GetDisplayScale));
end;

procedure ShowDialogueChoices(Panel: TPanelScrollBarGI; ContentHeight, LineHeight: Integer; var SavedScroll: Integer);
begin
  Panel.SetActive(True);
  Panel.VerticalScrollBar.SetSmallChange(LineHeight);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  Panel.SetScrollOffset(Point(0, 0));
  Panel.SetVerticalScrollbarEnabled(ContentHeight > Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetDepth(4);
  Panel.SetDragScrollingEnabled(Panel.IsVerticalScrollbarEnabled);
  Panel.UpdateScrollRanges;
  if SavedScroll >= 0 then
    Panel.VerticalScrollBar.SetPosition(SavedScroll);
  SavedScroll := -1;
end;

end.
