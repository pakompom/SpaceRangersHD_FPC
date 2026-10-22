unit GI_MobileSkin;

{$I GameOptions.inc}

interface

uses Types, GI_MessageLoop, GI_Main, GI_GraphButton, GI_Image, GI_Label, GI_PanelScrollBar;

function MobileScreenRect(Control: TObjectGI): TRect;
procedure ScaleMobileViewport(Scroll: TPanelScrollBarGI; PreferredScale: Single = 1);
procedure ResizeMobileSkinButton(Button: TGraphButtonGI; const Bounds: TRect);
procedure FitMobileNumber(LabelControl: TLabelGI; const Bounds: TRect);
// Lets the scene show through a window's artwork. Buttons and Keep (the text
// viewport) stay opaque, so captions and reading text keep their contrast.
procedure FadeMobileWindowArt(Window, Keep: TObjectGI; Alpha: Byte);
// Rearranges small buttons of one parent into a grid of finger-sized cells
// inside Area (parent coordinates). Each cell gets a nine-patch of the original
// artwork at ArtPath; the caption is enlarged to fit the cell.
procedure LayoutMobileChoiceGrid(const Buttons: array of TGraphButtonGI; const Area: TRect; Columns, Gap: Integer;
    const ArtPath: WideString; const Margins: TRect);
// Fills Image (W x H) with an original button face. The face is scaled to the
// height; its ends (Cap source pixels) keep their shape and only the plain
// middle repeats, so a short tab becomes any wider button without stripes.
procedure PaintMobileButtonArt(Image: TImageGI; const ArtPath: WideString; W, H, Cap: Integer);
// Side-by-side phone arrangements (ship window, hangar) need a wide screen.
// On 4:3 and 16:10 tablets the original stacked layout fits and is larger.
function MobileSideBySideFits: Boolean;

const
  // Reading windows let the planet or space scene show partly through their frame.
  MobileReadingWindowAlpha = 190;

implementation

uses Math, SysUtils, GameWindow, GlobalsV, GI_Artwork, GR_GraphBuf, GR_Main;

function MobileSideBySideFits: Boolean;
begin
  Result := GameScreenWidth >= 1.7 * GameScreenHeight;
end;

procedure PaintMobileButtonArt(Image: TImageGI; const ArtPath: WideString; W, H, Cap: Integer);
var
  Source: TGraphBufGR;
  ScaledWidth, ScaledCap, X, Y: Integer;
  Pixel: PByte;
begin
  Source := TGraphBufGR.Create(False);
  try
    LoadOriginalGiArtwork(ArtPath, Source);
    // Some faces were cut out on black: their cut corners are opaque black.
    // The faces themselves have no pure black, so make that backing clear.
    for Y := 0 to Source.Height - 1 do
    begin
      Pixel := PByte(Source.GetPixels) + Y * Source.PitchBytes;
      for X := 0 to Source.Width - 1 do
      begin
        if (Pixel[0] <= 8) and (Pixel[1] <= 8) and (Pixel[2] <= 8) then
          Pixel[3] := 0;
        Inc(Pixel, 4);
      end;
    end;
    ScaledWidth := Max(1, Round(Source.Width * H / Source.Height));
    ScaledCap := Max(0, Min(Round(Cap * H / Source.Height), Min(W div 2, ScaledWidth div 2) - 1));
    Source.RescaleBilinearRgba(ScaledWidth, H);
    Image.AutoUpdateFlags := 0;
    Image.SetImagePath('GraphBuf');
    Image.GraphBufControl.SourceHasPerPixelAlpha := True;
    Image.SetOrigin(Point(0, 0));
    Image.SetSize(Point(W, H));
    with Image.GraphBufControl.GraphBuf do
    begin
      AllocateRgbaTight(W, H);
      FillPixels(0);
      // Top and bottom borders are empty: the face already has the full height.
      DrawNinePatch(0, 0, W, H, Source, Rect(0, 0, ScaledWidth, H), Rect(ScaledCap, 0, ScaledCap, 0));
    end;
    Image.SetHitTestDisabled(True);
  finally
    Source.Free;
  end;
end;

function MobileScreenRect(Control: TObjectGI): TRect;
var S: Single;
begin
  Control.UpdateAbsolutePosition;
  S := Control.GetDisplayScale;
  Result := Rect(Round(Control.AbsolutePosition.X * S), Round(Control.AbsolutePosition.Y * S),
      Round((Control.AbsolutePosition.X + Control.ClientSize.X) * S),
      Round((Control.AbsolutePosition.Y + Control.ClientSize.Y) * S));
end;

procedure ScaleMobileViewport(Scroll: TPanelScrollBarGI; PreferredScale: Single);
var R: TRect; S: Single;
begin
  R := MobileScreenRect(Scroll);
  S := GetGameMobileUiScale(PreferredScale);
  Scroll.SetSize(Point(Floor((R.Right - R.Left) / S), Floor((R.Bottom - R.Top) / S)));
  PlaceControlAtScreen(Scroll, Point(R.Left, R.Top), S);
  Scroll.SetDragScrollingEnabled(True);
  Scroll.SetScrollbarsOutside(False);
  Scroll.AutoVerticalPlacement := True;
  Scroll.VerticalScrollBar.SetIndicatorThickness(3);
  Scroll.UpdateScrollbarPlacement;
end;

procedure ResizeMobileSkinButton(Button: TGraphButtonGI; const Bounds: TRect);
var Size: TPoint; S: Single;
  procedure ResizeImage(Image: TImageGI);
  var Source: TGraphBufGR; Path: WideString;
  begin
    if Image = nil then Exit;
    Path := Image.GetImagePath;
    if Copy(Path, 1, 3) <> 'GI,' then Exit;
    Source := TGraphBufGR.Create(False);
    try
      LoadOriginalGiArtwork(Copy(Path, 4, MaxInt), Source);
      Image.AutoUpdateFlags := 0;
      Image.SetImagePath('GraphBuf');
      Image.SetPosition(Point(0, 0));
      Image.SetSize(Size);
      Image.GraphBufControl.SourceHasPerPixelAlpha := True;
      Image.GraphBufControl.GraphBuf.AllocateRgbaTight(Size.X, Size.Y);
      Image.GraphBufControl.GraphBuf.FillPixels(0);
      { These button faces have a continuous gradient. Nine-patch tiles would
        repeat it into stripes; resample the complete original face instead. }
      Source.RescaleBilinearRgba(Size.X, Size.Y);
      Image.GraphBufControl.GraphBuf.CopyRect32(Point(0, 0), Source, Rect(0, 0, Size.X, Size.Y));
    finally
      Source.Free;
    end;
  end;
begin
  S := GetGameMobileUiScale;
  Size := Point(Floor((Bounds.Right - Bounds.Left) / S), Floor((Bounds.Bottom - Bounds.Top) / S));
  Button.ImageAutoUpdateFlags := 0;
  Button.AutoOffsetEnabled := False;
  Button.SetOrigin(Point(0, 0));
  Button.NormalOffset := Point(0, 0);
  Button.NormalActiveOffset := Point(0, 0);
  Button.DownOffset := Point(0, 0);
  Button.DownActiveOffset := Point(0, 0);
  Button.DisabledOffset := Point(0, 0);
  Button.DisabledActiveOffset := Point(0, 0);
  Button.HitKind := gbhRect;
  FreeAndNil(Button.ImageHit);
  ResizeImage(Button.ImageNormal);
  ResizeImage(Button.ImageNormalActive);
  ResizeImage(Button.ImageDown);
  ResizeImage(Button.ImageDownActive);
  ResizeImage(Button.ImageDisabled);
  ResizeImage(Button.ImageDisabledActive);
  Button.CaptionOffsets := Rect(3, 1, 3, 1);
  Button.SetSize(Size);
  Button.SetCaptionFontName(SmoothHugeFontName);
  Button.CaptionLabel.SetWordWrapEnabled(True);
  Button.CaptionLabel.SetHitTestDisabled(True);
  PlaceControlAtScreen(Button, Point(Bounds.Left, Bounds.Top), S);
  Button.UpdateStateVisuals(False);
  FitMobileNumber(Button.CaptionLabel, Rect(Bounds.Left + 6, Bounds.Top + 2, Bounds.Right - 6, Bounds.Bottom - 2));
  { Button state changes restore these offsets. Retain the compensated origin
    used by the independently fitted caption instead of resetting it to (3,1). }
  with Button.CaptionLabel.LocalPosition do
    Button.CaptionOffsets := Rect(X, Y, X, Y);
end;

procedure FitMobileNumber(LabelControl: TLabelGI; const Bounds: TRect);
var TextBounds: TRect; S: Single; W, H: Integer;
begin
  W := Bounds.Right - Bounds.Left;
  H := Bounds.Bottom - Bounds.Top;
  LabelControl.SetFontName(SmoothIntroFontName);
  LabelControl.SetWordWrapEnabled(False);
  TextBounds := MeasureLabelTextBounds(LabelControl.GetText, SmoothIntroFontName);
  S := Min(GetGameMobileUiScale, Min((W - 2) / Max(1, TextBounds.Right - TextBounds.Left),
      (H - 2) / Max(1, TextBounds.Bottom - TextBounds.Top)));
  LabelControl.SetSize(Point(Floor(W / S), Floor(H / S)));
  PlaceControlAtScreen(LabelControl, Point(Bounds.Left, Bounds.Top), S);
end;

procedure FadeMobileWindowArt(Window, Keep: TObjectGI; Alpha: Byte);
var
  Child: TObjectGI;
begin
  if (Window = nil) or (Window = Keep) or (Window is TGraphButtonGI) then
    Exit;
  if Window is TImageGI then
    TImageGI(Window).SetAlpha(Alpha);
  Child := Window.FirstChild;
  while Child <> nil do
  begin
    FadeMobileWindowArt(Child, Keep, Alpha);
    Child := Child.NextSibling;
  end;
end;

procedure LayoutMobileChoiceGrid(const Buttons: array of TGraphButtonGI; const Area: TRect; Columns, Gap: Integer;
    const ArtPath: WideString; const Margins: TRect);
var
  I, Rows, CellWidth, CellHeight, Split: Integer;
  Button: TGraphButtonGI;
  Backing: TImageGI;
  Cell: TRect;
  Cells: array of TRect;
  Source: TGraphBufGR;
  Text: WideString;
  Whole, First, Second: TRect;
  W, H, Scale, OneLine, TwoLines: Single;

  function Extent(const R: TRect): TPoint;
  begin
    Result := Point(Max(1, R.Right - R.Left), Max(1, R.Bottom - R.Top));
  end;

begin
  if Length(Buttons) = 0 then
    Exit;
  Rows := (Length(Buttons) + Columns - 1) div Columns;
  CellWidth := (Area.Right - Area.Left - Gap * (Columns - 1)) div Columns;
  CellHeight := (Area.Bottom - Area.Top - Gap * (Rows - 1)) div Rows;
  SetLength(Cells, Length(Buttons));
  Source := TGraphBufGR.Create(False);
  try
    LoadOriginalGiArtwork(ArtPath, Source);
    for I := 0 to High(Buttons) do
    begin
      Button := Buttons[I];
      Cell := Rect(Area.Left + (I mod Columns) * (CellWidth + Gap), Area.Top + (I div Columns) * (CellHeight + Gap), 0, 0);
      Cell.Right := Cell.Left + CellWidth;
      Cell.Bottom := Cell.Top + CellHeight;
      Backing := TImageGI.Create(Button.Parent);
      Backing.SetName(Button.ControlName + 'MobileCell');
      Backing.AutoUpdateFlags := 0;
      Backing.SetImagePath('GraphBuf');
      Backing.SetPosition(Cell.TopLeft);
      Backing.SetSize(Point(CellWidth, CellHeight));
      Backing.SetDepth(Button.Depth + 1);
      Backing.SetHitTestDisabled(True);
      Backing.GraphBufControl.SourceHasPerPixelAlpha := True;
      Backing.GraphBufControl.GraphBuf.AllocateRgbaTight(CellWidth, CellHeight);
      Backing.GraphBufControl.GraphBuf.FillPixels(0);
      Backing.GraphBufControl.GraphBuf.DrawNinePatch(0, 0, CellWidth, CellHeight, Source, Rect(0, 0, Source.Width, Source.Height), Margins);
      Cells[I] := MobileScreenRect(Backing);
      // The original faces are highlights drawn for the old positions.
      FreeAndNil(Button.ImageNormal);
      FreeAndNil(Button.ImageNormalActive);
      FreeAndNil(Button.ImageDown);
      FreeAndNil(Button.ImageDownActive);
      FreeAndNil(Button.ImageDisabled);
      FreeAndNil(Button.ImageDisabledActive);
      FreeAndNil(Button.ImageHit);
      Button.ImageAutoUpdateFlags := 0;
      Button.AutoOffsetEnabled := False;
      Button.SetOrigin(Point(0, 0));
      Button.NormalOffset := Point(0, 0);
      Button.NormalActiveOffset := Point(0, 0);
      Button.DownOffset := Point(0, 0);
      Button.DownActiveOffset := Point(0, 0);
      Button.DisabledOffset := Point(0, 0);
      Button.DisabledActiveOffset := Point(0, 0);
      Button.HitKind := gbhRect;
      Button.SetPosition(Cell.TopLeft);
      Button.SetSize(Point(CellWidth, CellHeight));
      Button.SetCaptionFontName(SmoothIntroFontName);
      // The cells are dark; use the light caption colour of this artwork's buttons.
      Button.SetCaptionColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
      Button.UpdateStateVisuals(False);
    end;
  finally
    Source.Free;
  end;
  // One text size for the whole grid: the largest that fits every caption on
  // one line, or on two lines split at its middle space.
  Scale := GetGameMobileUiScale;
  for I := 0 to High(Buttons) do
  begin
    W := (Cells[I].Right - Cells[I].Left) * 0.9;
    H := (Cells[I].Bottom - Cells[I].Top) * 0.86;
    Text := Buttons[I].CaptionLabel.GetText;
    Whole := MeasureLabelTextBounds(Text, SmoothIntroFontName);
    OneLine := Min(W / Extent(Whole).X, H / Extent(Whole).Y);
    TwoLines := 0;
    Split := Pos(' ', Copy(Text, Length(Text) div 2 + 1, MaxInt));
    if Split > 0 then
      Split := Length(Text) div 2 + Split
    else
    begin
      Split := Length(Text) div 2;
      while (Split > 0) and (Text[Split] <> ' ') do
        Dec(Split);
    end;
    if Split > 0 then
    begin
      First := MeasureLabelTextBounds(Copy(Text, 1, Split - 1), SmoothIntroFontName);
      Second := MeasureLabelTextBounds(Copy(Text, Split + 1, MaxInt), SmoothIntroFontName);
      TwoLines := Min(W / Max(Extent(First).X, Extent(Second).X), H / (Extent(First).Y + Extent(Second).Y));
    end;
    Scale := Min(Scale, Max(OneLine, TwoLines));
  end;
  for I := 0 to High(Buttons) do
  begin
    Button := Buttons[I];
    W := (Cells[I].Right - Cells[I].Left) * 0.94;
    H := Cells[I].Bottom - Cells[I].Top;
    with Button.CaptionLabel do
    begin
      SetFontName(SmoothIntroFontName);
      SetWordWrapEnabled(True);
      SetTextAlignX(taxCenter);
      SetTextAlignY(tayCenter);
      SetHitTestDisabled(True);
      SetSize(Point(Floor(W / Scale), Floor(H / Scale)));
    end;
    PlaceControlAtScreen(Button.CaptionLabel, Point(Cells[I].Left + Round((Cells[I].Right - Cells[I].Left - W) / 2), Cells[I].Top), Scale);
    // State changes restore CaptionOffsets; keep the fitted position.
    with Button.CaptionLabel.LocalPosition do
      Button.CaptionOffsets := Rect(X, Y, X, Y);
  end;
end;

end.
