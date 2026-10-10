unit GI_ShipLayout;

{$I GameOptions.inc}

interface

uses
  Types,
  GI_MessageLoop;

// Called once after each fresh ship control tree has been loaded. This prepares
// replacement artwork and reparents controls; it is not a repeatable relayout.
procedure PrepareMobileShipInventory(
    Screen: TMessageLoopGI;
    const Bounds: TRect;
    StorageCount, HoldColumns, HoldRows: Integer
);

implementation

uses
  Classes,
  Math,
  SysUtils,
  GameWindow,
  GlobalsV,
  GI_Main,
  GI_Image,
  GI_GraphButton,
  GI_Label,
  GI_Panel,
  GI_Artwork,
  GR_GraphBuf;

type
  // Scaling an icon subtree normally also scales its absolute origin. Anchor
  // these icons to the grid each time their sliding parent moves instead.
  TScaledContentsPanelGI = class(TPanelGI)
    ContentScale: Single;
    function GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint; override;
  end;

function TScaledContentsPanelGI.GetChildAbsolutePosition(
    LocalPosition: TPoint;
    ModeW: Boolean
): TPoint;
begin
  Result := ScaledChildPosition(AbsolutePosition, LocalPosition, ContentScale);
end;

procedure PrepareMobileShipInventory(
    Screen: TMessageLoopGI;
    const Bounds: TRect;
    StorageCount, HoldColumns, HoldRows: Integer
);
var
  Service, Storage, StorageClip, Body, Grid, Child, Next: TObjectGI;
  StorageImage, HoldImage: TImageGI;
  Source: TGraphBufGR;
  ScaleService, ScaleStorage, ScaleBody, Fit, CellScale: Single;
  Gap, Top, Height, RemovedHeight, Width, Left, I, X, Y, CellWidth, CellHeight: Integer;
  GridPosition, GridSize, OriginalGridSize, BodyPosition: TPoint;
  ScaledGrid: TScaledContentsPanelGI;
  Cell: TRect;

  // The wrapper keeps a larger button anchored while its original sliding
  // parent moves. Its normal/pressed images and callbacks stay on the button.
  procedure EnlargeButton(const Name: WideString; Factor: Single; KeepBottom: Boolean = False);
  var
    Button: TGraphButtonGI;
    Wrapper: TScaledContentsPanelGI;
    Position, Size: TPoint;
  begin
    Button := Screen.GetByName(Name) as TGraphButtonGI;
    Position := Button.LocalPosition;
    Size := Button.ClientSize;
    if KeepBottom then
      Dec(Position.Y, Round(Size.Y * (Factor - 1) / 2));
    Wrapper := TScaledContentsPanelGI.Create(Button.Parent);
    Wrapper.ContentScale := Factor;
    Wrapper.SetName(Name + 'TouchFrame');
    Wrapper.SetPosition(
        Point(
            Position.X - Round(Size.X * (Factor - 1) / 2),
            Position.Y - Round(Size.Y * (Factor - 1) / 2)
        )
    );
    Wrapper.SetSize(Point(Ceil(Size.X * Factor), Ceil(Size.Y * Factor)));
    Wrapper.SetDepth(Button.Depth);
    Button.Reparent(Wrapper);
    Button.DisplayScale := Factor;
    Button.SetPosition(Point(0, 0));
    Button.HitKind := gbhRect;
  end;

  procedure PrepareCargoActions;
  const
    Names: array[0..4] of WideString =
        ('LoadRocketsInHold', 'SellAllFromHold', 'SortTypeRH', 'SortSizeRH', 'SortMoneyRH');
  var
    Actions: TScaledContentsPanelGI;
    Button: TGraphButtonGI;
    Index, ColumnWidth, RowHeight, ActionTop, ActionBottom: Integer;
    Scale: Single;
  begin
    // Keep the enlarged cells at their previous size. Their two removed rows
    // become a separate action bay, rather than a row of tiny desktop buttons.
    ActionTop := GridPosition.Y + GridSize.Y + 7;
    ActionBottom := Screen.GetByName('FromRH').LocalPosition.Y - 13;
    ColumnWidth := OriginalGridSize.X div 2;
    RowHeight := (ActionBottom - ActionTop) div 3;
    Button := Screen.GetByName(Names[0]) as TGraphButtonGI;
    Scale := Min((ColumnWidth - 8) / Button.ClientSize.X, (RowHeight - 5) / Button.ClientSize.Y);
    Actions := TScaledContentsPanelGI.Create(Grid.Parent);
    Actions.SetName('MobileHoldActions');
    Actions.ContentScale := Scale;
    Actions.SetPosition(Point(GridPosition.X, ActionTop));
    Actions.SetSize(Point(OriginalGridSize.X, ActionBottom - ActionTop));
    Actions.SetDepth(Button.Depth);
    for Index := 0 to High(Names) do
    begin
      Button := Screen.GetByName(Names[Index]) as TGraphButtonGI;
      Button.Reparent(Actions);
      Button.DisplayScale := Scale;
      Button.SetPosition(
          Point(
              Round(
                  ((Index mod 2) * ColumnWidth + (ColumnWidth - Button.ClientSize.X * Scale) / 2)
                      / Scale
              ),
              Round(
                  ((Index div 2) * RowHeight + (RowHeight - Button.ClientSize.Y * Scale) / 2)
                      / Scale
              )
          )
      );
      Button.HitKind := gbhRect;
    end;
    EnlargeButton('UpRH', 1.5);
    EnlargeButton('DownRH', 1.5);
    // Separate the arrows as they grow; their original centers are only 24 px apart.
    with Screen.GetByName('UpRH').Parent do
      SetPosition(Point(LocalPosition.X, LocalPosition.Y - 8));
    with Screen.GetByName('DownRH').Parent do
      SetPosition(Point(LocalPosition.X, LocalPosition.Y + 8));
    EnlargeButton('FromRH', 1.2, True);
    EnlargeButton('ExitRH', 1.2, True);
  end;

  procedure PrepareImage(Image: TImageGI);
  var
    Path: WideString;
  begin
    Path := Image.GetImagePath;
    Delete(Path, 1, Pos(',', Path));
    LoadOriginalGiArtwork(Path, Source);
    Image.SetImagePath('GraphBuf');
    Image.AutoUpdateFlags := 0;
    Image.GraphBufControl.SourceHasPerPixelAlpha := True;
    Image.SetImageKindX(ikxLeft);
    Image.SetImageKindY(ikyTop);
  end;

begin
  if not GameMobileUiEnabled then
    Exit;
  Service := Screen.GetByName('SC_Panel');
  Storage := Screen.GetByName('SC_Storage_Panel');
  StorageClip := Storage.Parent;
  Body := Screen.GetByName('UsePanel').Parent;
  BodyPosition := Body.LocalPosition;
  // Put storage beside the service controls. Their former vertical stack was
  // already taller than the usable screen before any mobile enlargement.
  StorageClip.Reparent(Service.Parent);
  StorageClip.SetDepth(Service.Depth);
  StorageClip.SetName('MobileStorage');
  RemovedHeight := (7 - StorageCount div 3) * 43;
  StorageImage := Storage.FirstChild as TImageGI;
  Source := TGraphBufGR.Create(False);
  try
    PrepareImage(StorageImage);
    // The last 29 source rows are the cable behind the original stacked drawer.
    Height := 399 - RemovedHeight;
    StorageImage.GraphBufControl.GraphBuf.AllocateRgbaTight(Source.Width, Height);
    StorageImage
        .GraphBufControl
        .GraphBuf
        .CopyRect32(Point(0, 0), Source, Rect(0, 0, Source.Width, 361 - RemovedHeight));
    StorageImage
        .GraphBufControl
        .GraphBuf
        .CopyRect32(Point(0, 361 - RemovedHeight), Source, Rect(0, 361, Source.Width, 399));
    StorageImage.SetSize(Point(Source.Width, Height));
    Storage.SetSize(Point(Source.Width, Height));
    Storage.SetPosition(Point(0, 0));
    StorageClip.SetSize(Storage.ClientSize);
    Child := Storage.FirstChild;
    while Child <> nil do
    begin
      if (Child <> StorageImage) and (Child.LocalPosition.Y >= 340) then
        Child.SetPosition(Point(Child.LocalPosition.X, Child.LocalPosition.Y - RemovedHeight));
      Child := Child.NextSibling;
    end;
    // The grid remains visible; mobile no longer needs the sliding drawer tab.
    Screen.GetByName('SC_Up').SetActive(False);
    Screen.GetByName('SC_Down').SetActive(False);
    Service.SetSize(Point(Service.ClientSize.X, 318));
    Child := Service.FirstChild;
    while Child <> nil do
    begin
      Next := Child.NextSibling;
      if (Child is TLabelGI) and (Child.ClientSize.X > Service.ClientSize.X) then
      begin
        if Child.LocalPosition.Y > 250 then
        begin
          Child.Reparent(Storage);
          Child.SetPosition(Point(0, Storage.ClientSize.Y - 31));
          Child.SetSize(Point(Storage.ClientSize.X, 20));
          Child.SetDepth(StorageImage.Depth - 1);
          TLabelGI(Child).SetTextAlignY(tayCenter);
          TLabelGI(Child).SetFontName(SmoothBigFontName);
        end
        else
        begin
          Child.SetPosition(Point(0, Child.LocalPosition.Y));
          Child.SetSize(Point(Service.ClientSize.X, Child.ClientSize.Y));
        end;
      end;
      Child := Next;
    end;

    Gap := 12;
    Top := Bounds.Top + Ceil(GetGameMobileUiScale(56));
    Height := Bounds.Bottom - Bounds.Top - Gap * 2;
    ScaleService := Min(GetGameMobileUiScale(0.9), (Bounds.Bottom - Top - Gap) / 318);
    ScaleStorage := Min(GetGameMobileUiScale(1.15), Height / Storage.ClientSize.Y);
    ScaleBody := Min(1, Height / Body.ClientSize.Y);
    // The body's first 100 source pixels are the hidden edge of its sliding
    // panels. Its visible equipment begins there and stays beside storage.
    Width :=
        Round(
            Service.ClientSize.X * ScaleService
                + Storage.ClientSize.X * ScaleStorage
                + (Body.ClientSize.X - 100) * ScaleBody
        );
    Fit := Min(1, (Bounds.Right - Bounds.Left - 4 * Gap) / Width);
    ScaleService := ScaleService * Fit;
    ScaleStorage := ScaleStorage * Fit;
    ScaleBody := ScaleBody * Fit;
    Left := Bounds.Left + Gap;
    PlaceControlAtScreen(Service, Point(Left, Top), ScaleService);
    Inc(Left, Round(Service.ClientSize.X * ScaleService) + Gap);
    PlaceControlAtScreen(StorageClip, Point(Left, Bounds.Top + Gap), ScaleStorage);
    Inc(Left, Round(Storage.ClientSize.X * ScaleStorage) + Gap);
    PlaceControlAtScreen(Body, Point(Left - Round(100 * ScaleBody), Bounds.Top + Gap), ScaleBody);
    // The capital-ship bridge button is a sibling of the equipment panel.
    Child := Screen.GetByName('CustomBridgeInto');
    Child.DisplayScale := ScaleBody;
    Child.SetPosition(
        Point(
            Child.LocalPosition.X - BodyPosition.X + Body.LocalPosition.X,
            Child.LocalPosition.Y - BodyPosition.Y + Body.LocalPosition.Y
        )
    );
    Screen.RootUiObject.UpdateAbsolutePosition;

    Grid := Screen.GetByName('PanelItemRH');
    GridPosition := Grid.LocalPosition;
    OriginalGridSize := Grid.ClientSize;
    GridSize := Point(OriginalGridSize.X, OriginalGridSize.Y * HoldRows div 7);
    Grid.SetSize(GridSize);
    HoldImage := Screen.GetByName('RHOpen') as TImageGI;
    PrepareImage(HoldImage);
    HoldImage.GraphBufControl.GraphBuf.AllocateRgbaTight(Source.Width, Source.Height);
    HoldImage
        .GraphBufControl
        .GraphBuf
        .CopyRect32(Point(0, 0), Source, Rect(0, 0, Source.Width, Source.Height));
    // Clear the former lower cells and tiny action strip with the same inset
    // background. The frame, heading and bottom navigation retain their skin.
    HoldImage.GraphBufControl.GraphBuf.DrawNinePatch(
        GridPosition.X,
        GridPosition.Y + GridSize.Y,
        OriginalGridSize.X,
        OriginalGridSize.Y - GridSize.Y + 28,
        Source,
        Rect(GridPosition.X, GridPosition.Y, GridPosition.X + 42, GridPosition.Y + 42),
        Rect(20, 20, 20, 20)
    );
    // Rebuild only the cell area; keep the original frame, heading and footer.
    // Each cell uses the old bevels, with larger flat interiors.
    for Y := 0 to HoldRows - 1 do
      for X := 0 to HoldColumns - 1 do
      begin
        Cell :=
            Rect(
                GridPosition.X + X * GridSize.X div HoldColumns,
                GridPosition.Y + Y * GridSize.Y div HoldRows,
                GridPosition.X + (X + 1) * GridSize.X div HoldColumns,
                GridPosition.Y + (Y + 1) * GridSize.Y div HoldRows
            );
        HoldImage.GraphBufControl.GraphBuf.DrawNinePatch(
            Cell.Left,
            Cell.Top,
            Cell.Right - Cell.Left,
            Cell.Bottom - Cell.Top,
            Source,
            Rect(GridPosition.X, GridPosition.Y, GridPosition.X + 42, GridPosition.Y + 42),
            Rect(20, 20, 20, 20)
        );
      end;
    CellScale := Min(GridSize.X / HoldColumns, GridSize.Y / HoldRows) / 42;
    ScaledGrid := TScaledContentsPanelGI.Create(Grid.Parent);
    ScaledGrid.ContentScale := CellScale;
    ScaledGrid.SetName(Grid.ControlName);
    ScaledGrid.SetDepth(Grid.Depth);
    ScaledGrid.SetPosition(GridPosition);
    ScaledGrid.SetSize(GridSize);
    while Grid.FirstChild <> nil do
      Grid.FirstChild.Reparent(ScaledGrid);
    Grid.Parent.FreeOwnedChild(Grid);
    Grid := ScaledGrid;
    for I := 0 to HoldColumns * HoldRows - 1 do
    begin
      X := I mod HoldColumns;
      Y := I div HoldColumns;
      CellWidth := Round(GridSize.X / HoldColumns / CellScale);
      CellHeight := Round(GridSize.Y / HoldRows / CellScale);
      Child := Screen.GetByName('RHItem' + IntToStr(I));
      Child.DisplayScale := CellScale;
      Child.SetPosition(
          Point(
              Round(X * GridSize.X / HoldColumns / CellScale),
              Round(Y * GridSize.Y / HoldRows / CellScale)
          )
      );
      Child.SetSize(Point(CellWidth - 2, CellHeight - 2));
    end;
    PrepareCargoActions;
    EnlargeButton('S_Left', 1.6);
    EnlargeButton('S_Right', 1.6);
    EnlargeButton('ToRH', 1.2, True);
    EnlargeButton('Exit', 1.2, True);
    EnlargeButton('Storage_Up', 1.6);
    EnlargeButton('Storage_Down', 1.6);
    Screen.RootUiObject.UpdateAbsolutePosition;
    Screen.RootUiObject.UpdateSubtreeHitBounds;
  finally
    Source.Free;
  end;
end;

end.
