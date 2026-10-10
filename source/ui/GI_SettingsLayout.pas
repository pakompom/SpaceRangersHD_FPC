unit GI_SettingsLayout;

{$I GameOptions.inc}

interface

uses
  GI_MessageLoop,
  GI_CountBar;

// Called once, after binding the original control tree and before adding rows.
// Returns effective dp per source pixel, or zero when no adaptation is needed.
function PrepareMobileSettings(MainPanel: TObjectGI): Single;
// Called once after setting the row height; origin and state-image offsets accumulate.
procedure PrepareMobileSettingsSlider(Slider: TCountBarGI);

implementation

uses
  Classes,
  Math,
  SysUtils,
  GameWindow,
  GlobalsV,
  GR_Main,
  GR_GraphBuf,
  GI_Main,
  GI_Artwork,
  GI_Image,
  GI_Panel,
  GI_PanelScrollBar,
  GI_GraphButton;

const
  FrameTopHeight = 40;
  FrameBottomHeight = 40;
  FrameChromeHeight = 48;

procedure OffsetButtonArtwork(Button: TGraphButtonGI; Padding: Integer);
begin
  Inc(Button.NormalOffset.Y, Padding);
  Inc(Button.NormalActiveOffset.Y, Padding);
  Inc(Button.DownOffset.Y, Padding);
  Inc(Button.DownActiveOffset.Y, Padding);
  Inc(Button.DisabledOffset.Y, Padding);
  Inc(Button.DisabledActiveOffset.Y, Padding);
  Inc(Button.HitOffset.Y, Padding);
end;

procedure PrepareMobileSettingsSlider(Slider: TCountBarGI);
var
  Child: TObjectGI;
  Padding: Integer;
begin
  Padding := (Slider.ClientSize.Y - 20) div 2;
  Slider.FullHeightEndButtons := True;
  Child := Slider.FirstChild;
  while Child <> nil do
  begin
    // Graph buttons place their state images from stored offsets, independently
    // of their origin. Keep both aligned when the slider updates its children.
    if Child is TGraphButtonGI then
      OffsetButtonArtwork(TGraphButtonGI(Child), Padding);
    // End buttons cover the full row; only their artwork needs the padding.
    // Other children retain artwork-sized bounds centered inside the row.
    if (Child <> Slider.DecreaseButton) and (Child <> Slider.IncreaseButton) then
      Child.SetOrigin(Point(Child.OriginPoint.X, Child.OriginPoint.Y - Padding));
    Child := Child.NextSibling;
  end;
  Slider.UpdateLayout;
end;

procedure ResizeFrame(Image: TImageGI; Height: Integer);
var
  Source: TGraphBufGR;
  Path: WideString;
  Y: Integer;
begin
  Path := Image.GetImagePath;
  Delete(Path, 1, Pos(',', Path));
  Source := TGraphBufGR.Create(False);
  try
    LoadOriginalGiArtwork(Path, Source);
    Image.SetImagePath('GraphBuf');
    Image.SetSize(Point(Source.Width, Height));
    Image.GraphBufControl.GraphBuf.AllocateRgbaTight(Source.Width, Height);
    // Reuse the original lower rim above and below the compact body. The
    // mirrored upper rim closes the frame without retaining its desktop tabs.
    for Y := 0 to FrameTopHeight - 1 do
      Image.GraphBufControl.GraphBuf.CopyRect32(
          Point(0, Y),
          Source,
          Rect(0, Source.Height - 1 - Y, Source.Width, Source.Height - Y)
      );
    for Y := FrameTopHeight to Height - FrameBottomHeight - 1 do
      Image
          .GraphBufControl
          .GraphBuf
          .CopyRect32(Point(0, Y), Source, Rect(0, 200, Source.Width, 201));
    // The original side strip also contains a fixed-position inner bracket.
    // Its old text inset no longer matches the wider mobile content area.
    Image.GraphBufControl.GraphBuf.FillRect32(
        Rect(32, FrameTopHeight, Source.Width - 32, Height - FrameBottomHeight),
        $FF000000
    );
    Image.GraphBufControl.GraphBuf.CopyRect32(
        Point(0, Height - FrameBottomHeight),
        Source,
        Rect(0, Source.Height - FrameBottomHeight, Source.Width, Source.Height)
    );
  finally
    Source.Free;
  end;
end;

function PrepareMobileSettings(MainPanel: TObjectGI): Single;
var
  Body, Header, Footer, Title, Wrapper, Control: TObjectGI;
  Panel: TPanelScrollBarGI;
  Scale: Single;
  Left, Height, BodyHeight, I, ButtonHeight, Padding, PresetTop, Gap: Integer;
  CategoryArtworkHeight, PresetHeight, ConfirmHeight, MinimumFrameHeight: Integer;
  Categories, Presets: array[0..3] of TGraphButtonGI;
  Confirms: array[0..1] of TGraphButtonGI;
const
  PresetNames: array[0..3] of string = ('ButAAuto', 'ButAUp', 'ButAMiddle', 'ButADown');
  ConfirmNames: array[0..1] of string = ('Ok', 'Cancel');
begin
  Result := 0;
  if not GameMobileUiEnabled or not HardwareRenderingEnabled then
    Exit;
  Panel := MainPanel.FindByNameRecursive('PanelSet') as TPanelScrollBarGI;
  Body := Panel.Parent;
  Footer := MainPanel.FindByNameRecursive('Cancel').Parent;
  Header := MainPanel.FirstChild.NextSibling;
  Title := Body.NextSibling;
  Left := Header.LocalPosition.X;
  CategoryArtworkHeight := 0;
  PresetHeight := 0;
  ConfirmHeight := 0;
  for I := 0 to 3 do
  begin
    Categories[I] := MainPanel.FindByNameRecursive('ButGroup' + IntToStr(I)) as TGraphButtonGI;
    Presets[I] := MainPanel.FindByNameRecursive(PresetNames[I]) as TGraphButtonGI;
    CategoryArtworkHeight := Max(CategoryArtworkHeight, Categories[I].GetMaxStateImageSize.Y);
    PresetHeight := Max(PresetHeight, Presets[I].GetMaxStateImageSize.Y);
  end;
  for I := 0 to 1 do
  begin
    Confirms[I] := MainPanel.FindByNameRecursive(ConfirmNames[I]) as TGraphButtonGI;
    ConfirmHeight := Max(ConfirmHeight, Confirms[I].GetMaxStateImageSize.Y);
  end;
  // Three categories, two preset rows and one confirmation row share the same
  // height budget. Group gaps count twice; even the compact form keeps 2px gaps.
  MinimumFrameHeight :=
      FrameChromeHeight
          + FrameTopHeight
          + 6
          + FrameBottomHeight
          + 3 * CategoryArtworkHeight
          + 2 * PresetHeight
          + ConfirmHeight
          + 7 * 2;
  // Width is the original skin's width. Height is the available physical
  // space, so small windows show fewer rows instead of shrinking all rows.
  Scale := Min(GetGameMobileUiScale(0.8), (GameScreenWidth - 16) / Header.ClientSize.X);
  // The frame must fit both its artwork caps and all six sidebar rows.
  Scale := Min(Scale, (GameScreenHeight - 8) / MinimumFrameHeight);
  Result := Scale / GetGameMobileUiScale;
  Height := Max(MinimumFrameHeight, Floor((GameScreenHeight - 8) / Scale));
  BodyHeight := Height - FrameChromeHeight;
  Wrapper := TPanelGI.Create(MainPanel);
  Wrapper.SetName('MobileSettings');
  Wrapper.SetSize(Point(Header.ClientSize.X, Height));
  for I := 0 to 3 do
  begin
    case I of
      0: Control := Header;
      1: Control := Body;
      2: Control := Title;
    else
      Control := Footer;
    end;
    Control.Reparent(Wrapper);
    Control.SetPosition(Point(Control.LocalPosition.X - Left, Control.LocalPosition.Y));
  end;
  Header.SetDepth(-10);
  Title.SetDepth(-11);
  Body.SetPosition(Point(Body.LocalPosition.X, FrameChromeHeight));
  Body.SetSize(Point(Body.ClientSize.X, BodyHeight));
  ResizeFrame(MainPanel.FindByNameRecursive('ModeLeft') as TImageGI, BodyHeight);
  ResizeFrame(MainPanel.FindByNameRecursive('ModeRight') as TImageGI, BodyHeight);
  Panel.SetPosition(Point(205, FrameTopHeight + 6));
  Panel.SetSize(
      Point(Body.ClientSize.X - 247, BodyHeight - Panel.LocalPosition.Y - FrameBottomHeight)
  );
  Panel.SetDragScrollingEnabled(True);
  Panel.AutoVerticalPlacement := True;
  Panel.VerticalScrollBar.SetIndicatorThickness(2);
  Panel.UpdateScrollbarPlacement;
  // Spend spare height on padding, never by letting top- and bottom-anchored
  // action groups overlap. Compact windows retain all original button artwork.
  ButtonHeight :=
      Max(
          CategoryArtworkHeight,
          Min(
              Ceil(30 / Result),
              (Panel.ClientSize.Y - 2 * PresetHeight - ConfirmHeight - 7 * 2) div 3
          )
      );
  Gap := Min(6, (Panel.ClientSize.Y - 3 * ButtonHeight - 2 * PresetHeight - ConfirmHeight) div 7);
  for I := 0 to 3 do
  begin
    Control := Categories[I];
    Control.SetPosition(Point(48, Panel.LocalPosition.Y + I * (ButtonHeight + Gap)));
    Padding := (ButtonHeight - Control.ClientSize.Y) div 2;
    OffsetButtonArtwork(Categories[I], Padding);
    Control.SetSize(Point(Control.ClientSize.X, ButtonHeight));
    Categories[I].HitKind := gbhRect;
    Categories[I].SetCaptionFontName(SmoothBigFontName);
  end;
  PresetTop := Panel.LocalPosition.Y + 3 * ButtonHeight + 4 * Gap;
  for I := 0 to 3 do
  begin
    Control := Presets[I];
    Control.Reparent(Body);
    Control.SetPosition(Point(45 + (I mod 2) * 72, PresetTop + (I div 2) * (PresetHeight + Gap)));
    Padding := (PresetHeight - Control.ClientSize.Y) div 2;
    OffsetButtonArtwork(Presets[I], Padding);
    Control.SetSize(Point(Control.ClientSize.X, PresetHeight));
    Presets[I].HitKind := gbhRect;
  end;
  for I := 0 to 1 do
  begin
    Control := Confirms[I];
    Control.Reparent(Body);
    Control.SetDepth(-10);
    Control.SetPosition(Point(43 + I * 70, BodyHeight - FrameBottomHeight - ConfirmHeight));
    Padding := (ConfirmHeight - Control.ClientSize.Y) div 2;
    OffsetButtonArtwork(Confirms[I], Padding);
    Control.SetSize(Point(Control.ClientSize.X, ConfirmHeight));
  end;
  Footer.SetActive(False);
  PlaceControlAtScreen(
      Wrapper,
      Point((GameScreenWidth - Round(Wrapper.ClientSize.X * Scale)) div 2, 4),
      Scale
  );
end;

end.
