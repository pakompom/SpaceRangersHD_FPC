unit QuestArtwork;

{$I GameOptions.inc}

interface

uses
  Types,
  GI_MessageLoop,
  GI_GraphBuf,
  GR_GraphBuf;

type
  TQuestArtworkGI = class(TGraphBufGI)
  private
    PanelSource, BackgroundSource, PictureSource, ChoiceSource, StyleSource: TGraphBufGR;
    ControlBacking: TGraphBufGR;
    ControlBounds: TRect;
    TextBounds, ChoiceBounds, PictureBounds: TRect;
    CurrentStyle: Integer;
    LayoutDirty: Boolean;
    procedure Rebuild;
  public
    TextInsets, ChoiceInsets, PictureInnerBounds: TRect;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure Draw(ClipRect: TRect); override;
    procedure SetControlLayout(const StyleBounds: TRect);
    procedure BuildControlPlate(Buffer: TGraphBufGR; Width, Height: Integer);
    procedure SetLayout(const TextFrame, ChoicesFrame, PictureFrame: TRect; StyleIndex: Integer);
  end;

implementation

uses
  Classes,
  Math,
  SysUtils,
  GI_Artwork,
  GlobalsV,
  GR_DX,
  GR_Main,
  GI_Main;

function SameBounds(const First, Second: TRect): Boolean;
begin
  Result :=
      (First.Left = Second.Left)
          and (First.Top = Second.Top)
          and (First.Right = Second.Right)
          and (First.Bottom = Second.Bottom);
end;

constructor TQuestArtworkGI.Create(Owner: TObjectGI);
var
  X, Y: Integer;
  Edge, Coverage: Double;
begin
  inherited Create(Owner, True);
  PanelSource := TGraphBufGR.Create(False);
  BackgroundSource := TGraphBufGR.Create(False);
  PictureSource := TGraphBufGR.Create(False);
  ChoiceSource := TGraphBufGR.Create(False);
  StyleSource := TGraphBufGR.Create(False);
  ControlBacking := TGraphBufGR.Create(True);
  CurrentStyle := -1;
  LoadOriginalGiArtwork('Bm.FormPQuest2.2Panel', PanelSource);
  LoadOriginalGiArtwork('Bm.FormPQuest2.2BG', BackgroundSource);

  // Enlarge this small plate independently from the full-width metal footer.
  ControlBacking.AllocateRgbaTight(116, 23);
  ControlBacking.CopyRect32(Point(0, 0), PanelSource, Rect(529, 738, 645, 761));
  // The rounded plate was painted onto the opaque footer. Remove the footer
  // outside its elliptical end caps, retaining the bevel's original RGB and
  // a one-source-pixel alpha transition along the contour.
  for Y := 0 to ControlBacking.Height - 1 do
  begin
    Edge := 8 * (1 - Sqrt(Max(0, 1 - Sqr((Y + 0.5 - 11.5) / 11.5))));
    for X := 0 to Ceil(Edge) do
    begin
      Coverage := EnsureRange(X + 1 - Edge, 0.0, 1.0);
      ControlBacking.ScaleAlpha(Rect(X, Y, X + 1, Y + 1), Round(255 * Coverage));
      ControlBacking.ScaleAlpha(
          Rect(ControlBacking.Width - X - 1, Y, ControlBacking.Width - X, Y + 1),
          Round(255 * Coverage)
      );
    end;
  end;
  for X := 527 to 649 do
    PanelSource.CopyRect32(Point(X, 736), PanelSource, Rect(660, 736, 661, 768));
  // The exit button supplies its own bezel at its new size and position.
  PanelSource.CopyRect32(Point(972, 713), PanelSource, Rect(881, 713, 972, 768));

  // The gold frame is part of the background. Preserve it separately, then
  // replace its old position with a matching, phase-aligned background sample.
  PictureSource.AllocateRgbaTight(366, 412);
  PictureSource.CopyRect32(Point(0, 0), BackgroundSource, Rect(1541, 22, 1907, 434));
  BackgroundSource.CopyRect32(Point(1541, 22), BackgroundSource, Rect(1029, 22, 1395, 434));

  // The original choices frame ends underneath the controls bar. Give it the
  // matching silver lower corners so its height can follow the choice list.
  ChoiceSource.AllocateRgbaTight(597, 291);
  ChoiceSource.CopyRect32(Point(0, 0), PanelSource, Rect(68, 459, 665, 715));
  ChoiceSource.CopyRect32(Point(0, 256), PanelSource, Rect(68, 410, 665, 445));
  TextInsets := Rect(12, 34, 12, 12);
  ChoiceInsets := Rect(12, 12, 12, 12);
  SourceHasPerPixelAlpha := True;
  SetImageKindX(ikxLeft);
  SetImageKindY(ikyTop);
  SetDepth(8.5);
end;

destructor TQuestArtworkGI.Destroy;
begin
  PanelSource.Free;
  BackgroundSource.Free;
  PictureSource.Free;
  ChoiceSource.Free;
  StyleSource.Free;
  ControlBacking.Free;
  inherited Destroy;
end;

procedure TQuestArtworkGI.SetControlLayout(const StyleBounds: TRect);
var
  Bounds: TRect;
  Scale: Single;
  Padding: Integer;
begin
  Scale := (StyleBounds.Right - StyleBounds.Left) / 101;
  Padding := Min(8, Round(3 * Scale));
  Bounds :=
      Rect(
          StyleBounds.Left - Round(7 * Scale),
          StyleBounds.Top - Padding,
          StyleBounds.Right + Round(8 * Scale),
          StyleBounds.Bottom + Padding
      );
  if SameBounds(ControlBounds, Bounds) then
    Exit;
  ControlBounds := Bounds;
  Invalidate;
end;

procedure TQuestArtworkGI.BuildControlPlate(Buffer: TGraphBufGR; Width, Height: Integer);
begin
  Buffer.AllocateRgbaTight(Width, Height);
  Buffer.DrawNinePatch(
      0,
      0,
      Width,
      Height,
      ControlBacking,
      Rect(0, 0, ControlBacking.Width, ControlBacking.Height),
      Rect(10, 12, 10, 10)
  );
end;

procedure TQuestArtworkGI.Draw(ClipRect: TRect);
begin
  // A quest page updates its text, statistics, picture and choices separately.
  // Compose the full-screen artwork once after those layout changes settle.
  if LayoutDirty then
  begin
    Rebuild;
    LayoutDirty := False;
  end;
  inherited Draw(ClipRect);
  if HardwareRenderingEnabled and (ControlBounds.Right > ControlBounds.Left) then
    DrawTextureSized(
        ControlBacking.GetTexture,
        ControlBounds.Left,
        ControlBounds.Top,
        ControlBounds.Right - ControlBounds.Left,
        ControlBounds.Bottom - ControlBounds.Top,
        255,
        RgbWhite,
        @ClipRect,
        False,
        False
    );
end;

procedure TQuestArtworkGI.SetLayout(
    const TextFrame, ChoicesFrame, PictureFrame: TRect;
    StyleIndex: Integer
);
var
  X: Integer;
begin
  StyleIndex := EnsureRange(StyleIndex, 0, 3);
  if (CurrentStyle = StyleIndex)
      and (GraphBuf.Width = GameScreenWidth)
      and (GraphBuf.Height = GameScreenHeight)
      and SameBounds(TextBounds, TextFrame)
      and SameBounds(ChoiceBounds, ChoicesFrame)
      and SameBounds(PictureBounds, PictureFrame) then
    Exit;
  if CurrentStyle <> StyleIndex then
  begin
    LoadOriginalGiArtwork('Bm.FormPQuest2.2S' + IntToStr(StyleIndex + 1), StyleSource);
    // These fills include the old scrollbar track and arrow recesses. Mirror
    // the plain left edge to retain the skin's rounded shading without them.
    for X := 0 to 27 do
      StyleSource.CopyRect32(
          Point(StyleSource.Width - 28 + X, 0),
          StyleSource,
          Rect(27 - X, 0, 28 - X, StyleSource.Height)
      );
    CurrentStyle := StyleIndex;
  end;
  TextBounds := TextFrame;
  ChoiceBounds := ChoicesFrame;
  PictureBounds := PictureFrame;
  PictureInnerBounds := Rect(0, 0, 0, 0);
  if (PictureBounds.Right - PictureBounds.Left > 20)
      and (PictureBounds.Bottom - PictureBounds.Top > 20) then
    PictureInnerBounds :=
        Rect(
            PictureBounds.Left + 9,
            PictureBounds.Top + 9,
            PictureBounds.Right - 11,
            PictureBounds.Bottom - 11
        );
  SetSize(Point(GameScreenWidth, GameScreenHeight));
  LayoutDirty := True;
  Invalidate;
end;

procedure TQuestArtworkGI.Rebuild;
var
  Scratch: TGraphBufGR;
  Bounds, SourceBounds: TRect;
  Delta: Integer;

  procedure Patch(
      const Dest: TRect;
      Source: TGraphBufGR;
      const SourceRect: TRect;
      Borders: TRect;
      Blend: Boolean = True
  );
  var
    Width, Height: Integer;
  begin
    Width := Dest.Right - Dest.Left;
    Height := Dest.Bottom - Dest.Top;
    if (Width <= 0) or (Height <= 0) then
      Exit;
    if (Dest.Left < 0)
        or (Dest.Top < 0)
        or (Dest.Right > GameScreenWidth)
        or (Dest.Bottom > GameScreenHeight) then
      raise Exception.Create('Quest artwork bounds exceed the screen');
    // Very short choice lists still need bounded corner copies.
    if Borders.Left + Borders.Right > Width then
    begin
      Borders.Left := Min(Borders.Left, Width div 2);
      Borders.Right := Width - Borders.Left;
    end;
    if Borders.Top + Borders.Bottom > Height then
    begin
      Borders.Top := Min(Borders.Top, Height div 2);
      Borders.Bottom := Height - Borders.Top;
    end;
    Scratch.DrawNinePatch(0, 0, Width, Height, Source, SourceRect, Borders);
    if Blend then
      GraphBuf.BlendRect32(Dest.TopLeft, Scratch, Rect(0, 0, Width, Height))
    else
      GraphBuf.CopyRect32(Dest.TopLeft, Scratch, Rect(0, 0, Width, Height));
  end;

begin
  GraphBuf.AllocateRgbaTight(GameScreenWidth, GameScreenHeight);
  Scratch := TGraphBufGR.Create(False);
  try
    Scratch.AllocateRgbaTight(GameScreenWidth, GameScreenHeight);
    // Preserve the original right-aligned artwork at its native size. Extra
    // space repeats the background texture instead of stretching the machinery.
    SourceBounds :=
        Rect(
            Max(0, BackgroundSource.Width - GameScreenWidth),
            0,
            BackgroundSource.Width,
            Min(GameScreenHeight, BackgroundSource.Height)
        );
    GraphBuf.DrawNinePatch(
        0,
        0,
        GameScreenWidth,
        GameScreenHeight,
        BackgroundSource,
        SourceBounds,
        Rect(0, 0, Min(512, GameScreenWidth), 0)
    );

    Bounds := TextBounds;
    InflateRect(Bounds, -6, -7);
    // Keep all edge shading outside the repeated center, avoiding visible seams
    // when either text panel grows beyond the original artwork's height.
    Patch(Bounds, StyleSource, Rect(0, 0, StyleSource.Width, 430), Rect(32, 40, 32, 32));
    Patch(TextBounds, PanelSource, Rect(68, 0, 665, 445), Rect(185, 30, 190, 35));
    Bounds := ChoiceBounds;
    InflateRect(Bounds, -6, -7);
    Patch(
        Bounds,
        StyleSource,
        Rect(0, 453, StyleSource.Width, StyleSource.Height),
        Rect(32, 32, 32, 16)
    );
    Patch(ChoiceBounds, ChoiceSource, Rect(0, 0, 597, 291), Rect(34, 34, 35, 35));

    if (PictureInnerBounds.Right > PictureInnerBounds.Left)
        and (PictureInnerBounds.Bottom > PictureInnerBounds.Top) then
    begin
      // Copy the transparent center too: PQI is drawn behind this layer, so
      // the original gold chamfers mask the rectangular illustration correctly.
      Patch(PictureBounds, PictureSource, Rect(0, 0, 366, 412), Rect(52, 42, 48, 60), False);
    end;
    Bounds := Rect(0, Max(0, GameScreenHeight - 55), GameScreenWidth, GameScreenHeight);
    Delta := Min(301, Max(0, 1063 - GameScreenWidth));
    Patch(Bounds, PanelSource, Rect(Delta, 713, 1063, 768), Rect(302 - Delta, 0, 760, 0));
  finally
    Scratch.Free;
  end;
end;

end.
