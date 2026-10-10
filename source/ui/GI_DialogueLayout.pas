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
procedure RefreshDialogueText(
    Panel: TPanelScrollBarGI;
    LabelControl: TLabelGI;
    const Text: WideString
);
procedure ShowDialogueChoices(
    Panel: TPanelScrollBarGI;
    ContentHeight, LineHeight: Integer;
    var SavedScroll: Integer
);

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
  GR_GraphBuf;

type
  // Owned by TalkPanel. Source artwork is decoded once; changing the answer
  // area only recomposes the retained buffers.
  TDialogueArtworkGI = class(TGraphBufGI)
  private
    Frame, Fill, Scratch: TGraphBufGR;
    LastWidth, LastHeight, LastTextBottom: Integer;
  public
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
  TalkPanel.SetPosition(
      Classes.Point(TalkPanel.LocalPosition.X + ExtraScreenWidth div 2, TalkPanel.LocalPosition.Y)
  );
  TalkPanel.SetSize(
      Classes.Point(TalkPanel.ClientSize.X, TalkPanel.ClientSize.Y + TextExtra + ChoiceExtra)
  );
  Child := TalkPanel.FirstChild;
  TImageGI(Child)
      .SetImagePath(
          'GI,Bm.FormGov2.' + GiResourceSuffix + 'TWinB?content-height=' + IntToStr(ContentHeight));
  Child.SetPosition(Classes.Point(Child.LocalPosition.X, Child.LocalPosition.Y + TextExtra));
  Child.SetSize(Classes.Point(Child.ClientSize.X, Child.ClientSize.Y + ChoiceExtra));
  AddButton := TalkPanel.FindByNameRecursive('UserMsgAdd');
  AddButton
      .SetPosition(Classes.Point(AddButton.LocalPosition.X, AddButton.LocalPosition.Y + TextExtra));
  CloseButton := TalkPanel.FindByNameRecursive('ButFormClose');
  CloseButton.SetPosition(
      Classes
          .Point(CloseButton.LocalPosition.X, CloseButton.LocalPosition.Y + TextExtra + ChoiceExtra)
  );
  TextPanel := TalkPanel.FindByNameRecursive('TextScroll') as TPanelScrollBarGI;
  TextPanel.SetSize(Classes.Point(TextPanel.ClientSize.X, TextPanel.ClientSize.Y + TextExtra));
  TextPanel.VerticalScrollBar.SetSize(
      Classes.Point(
          TextPanel.VerticalScrollBar.ClientSize.X,
          TextPanel.VerticalScrollBar.ClientSize.Y + TextExtra
      )
  );
  TextLabel := TextPanel.FindByNameRecursive('TalkText');
  TextLabel.SetSize(Classes.Point(TextLabel.ClientSize.X, TextLabel.ClientSize.Y + TextExtra));
  ChoicePanel := TalkPanel.FindByNameRecursive('TalkPA') as TPanelScrollBarGI;
  ChoicePanel.SetPosition(
      Classes.Point(ChoicePanel.LocalPosition.X, ChoicePanel.LocalPosition.Y + TextExtra)
  );
  ChoicePanel
      .SetSize(Classes.Point(ChoicePanel.ClientSize.X, ChoicePanel.ClientSize.Y + ChoiceExtra));
  TObjectGI(ChoicePanel.VerticalScrollBar)
      .SetPosition(
          Classes.Point(
              ChoicePanel.VerticalScrollBar.LocalPosition.X,
              ChoicePanel.VerticalScrollBar.LocalPosition.Y + TextExtra
          ));
  ChoicePanel.VerticalScrollBar.SetSize(
      Classes.Point(
          ChoicePanel.VerticalScrollBar.ClientSize.X,
          ChoicePanel.VerticalScrollBar.ClientSize.Y + ChoiceExtra
      )
  );
  Border := ChoicePanel.NextSibling;
  TImageGI(Border)
      .SetImagePath(
          'GI,Bm.FormGov2.' + GiResourceSuffix + 'TWin?content-height=' + IntToStr(ContentHeight));
  Border.SetSize(Classes.Point(Border.ClientSize.X, Border.ClientSize.Y + TextExtra + ChoiceExtra));
  BottomBorder := Border.NextSibling;
  BottomBorder.SetPosition(
      Classes.Point(
          BottomBorder.LocalPosition.X,
          BottomBorder.LocalPosition.Y + TextExtra + ChoiceExtra
      )
  );
  Separator := BottomBorder.NextSibling;
  Separator
      .SetPosition(Classes.Point(Separator.LocalPosition.X, Separator.LocalPosition.Y + TextExtra));
  Decoration := Separator.NextSibling;
  Decoration.SetPosition(
      Classes.Point(Decoration.LocalPosition.X, Decoration.LocalPosition.Y + TextExtra)
  );
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
  Scratch.DrawNinePatch(
      0,
      0,
      Width,
      TextBottom,
      Frame,
      Rect(0, 0, Frame.Width, 430),
      Rect(190, 54, 190, 42)
  );
  Scratch.DrawNinePatch(
      0,
      TextBottom,
      Width,
      Height - TextBottom,
      Frame,
      Rect(0, 430, Frame.Width, Frame.Height),
      Rect(190, 32, 190, 52)
  );
  GraphBuf.BlendRect32(Point(0, 0), Scratch, Rect(0, 0, Width, Height));
  SetSize(Point(Width, Height));
  LastWidth := Width;
  LastHeight := Height;
  LastTextBottom := TextBottom;
end;

procedure FitDialogueChoices(TalkPanel: TObjectGI; ChoicesHeight: Integer);
var
  Artwork: TDialogueArtworkGI;
  TextPanel, ChoicePanel: TPanelScrollBarGI;
  TextBottom, Width, Height: Integer;
begin
  Artwork := TalkPanel.FindByNameRecursive('MobileDialogueArtwork') as TDialogueArtworkGI;
  if Artwork = nil then
    Exit;
  Width := TalkPanel.ClientSize.X;
  Height := TalkPanel.ClientSize.Y;
  // A short reply must not reserve a third of the screen. Longer menus keep
  // a bounded, scrollable answer area and reserve space for the story.
  TextBottom := Height - EnsureRange(ChoicesHeight + 68, 88, 168);
  if not Artwork.UpdateFrame(Width, Height, TextBottom) then
    Exit;
  TextPanel := TalkPanel.FindByNameRecursive('TextScroll') as TPanelScrollBarGI;
  TextPanel.SetSize(Point(TextPanel.ClientSize.X, TextBottom - 16 - TextPanel.LocalPosition.Y));
  TextPanel.UpdateScrollRanges;
  TextPanel.VerticalScrollBar.SetLargeChange(TextPanel.ClientSize.Y);
  TextPanel.VerticalScrollBar.SetActive(
      TextPanel.FindByNameRecursive('TalkText').ClientSize.Y > TextPanel.ClientSize.Y
  );
  ChoicePanel := TalkPanel.FindByNameRecursive('TalkPA') as TPanelScrollBarGI;
  ChoicePanel.SetPosition(Point(12, TextBottom + 10));
  ChoicePanel.SetSize(Point(Width - 46, Height - 54 - ChoicePanel.LocalPosition.Y));
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
  // Keep the original width and rounded artwork. Adapt only the vertical
  // middle strips, then enlarge the whole panel to fit above the common HUD.
  Width := 411;
  PanelTop := Bounds.Top + 12;
  Scale := Min(GetGameMobileUiScale(1.05), (Bounds.Bottom - PanelTop - 8) / 460);
  Scale := Min(Scale, (Bounds.Right - Bounds.Left - 24) / (2 * Width));
  Height := Min(620, Floor((Bounds.Bottom - PanelTop - 8) / Scale));
  PanelLeft :=
      Max(Bounds.Left + 12, (Bounds.Left + Bounds.Right) div 2 - Round(Width * Scale) - 42);
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
  TextPanel.SetPosition(Point(25, Max(55, Ceil((56 * GetGameMobileUiScale - PanelTop) / Scale))));
  TextPanel.SetSize(Point(Width - 66, 1));
  PrepareScroll(TextPanel);
  PrepareScroll(ChoicePanel);
  with TextPanel.FindByNameRecursive('TalkText') do
  begin
    SetPosition(Point(0, 0));
    SetSize(Point(TextPanel.ClientSize.X, 1));
  end;
  FitDialogueChoices(TalkPanel, 100);
end;

procedure PrepareDialoguePanel(TalkPanel: TObjectGI; ContentHeight: Integer; const Bounds: TRect);
begin
  if GameMobileUiEnabled and HardwareRenderingEnabled then
    LayoutMobileDialogue(TalkPanel, Bounds)
  else
    LayoutDesktopDialogue(TalkPanel, ContentHeight);
end;

procedure RefreshDialogueText(
    Panel: TPanelScrollBarGI;
    LabelControl: TLabelGI;
    const Text: WideString
);
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

procedure ShowDialogueChoices(
    Panel: TPanelScrollBarGI;
    ContentHeight, LineHeight: Integer;
    var SavedScroll: Integer
);
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
