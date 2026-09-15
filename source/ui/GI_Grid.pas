{$EXCESSPRECISION OFF}
unit GI_Grid;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_Frame,
  GI_Image,
  GI_Label,
  GI_MessageLoop,
  GI_PanelScrollBar,
  Types;
type
  PointerToInteger = ^Integer;
type
  TGridGI = class;
  {$Z1}
  TGridTypeGI = (gtHide = 0, gtCell = 1, gtRow = 2, gtCol = 3);
  TGridRowGI = packed record
    Height: Integer;
    AutoHeightMinimum: Integer;
    AutoHeight: Boolean;
    Gap9: array[0..2] of Byte;
  end;
  TGridCanSelectCellEventGI = function(Sender: TObjectGI; Cell: TPoint): Boolean of object;
  TGridGI = class(TPanelScrollBarGI)
    ColumnCount: Integer;
    RowCount: Integer;
    ColumnWidths: PointerToInteger;
    Rows: array of TGridRowGI;
    FontName: WideString;
    TextColor: Cardinal;
    GridType: TGridTypeGI;
    Gap189: array[0..2] of Byte;
    GridColor: Cardinal;
    BackgroundImage: TImageGI;
    ActiveCellImage: TImageGI;
    ActiveCellFrame: TFrameGI;
    ActiveCell: TPoint;
    RowSelect: Boolean;
    ColSelect: Boolean;
    Gap1A6: array[0..1] of Byte;
    SelectionChangedCallback: TObjectNotifyEventGI;
    CanSelectCellCallback: TGridCanSelectCellEventGI;
    RepeatedCellClickCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure OnFocusGained; override;
    procedure OnFocusLost; override;
    procedure ProcessKeyDown(Key: Integer); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure LayoutCell(Child: TObjectGI);
    procedure LayoutCells;
    procedure UpdateGridExtent;
    procedure RebuildGridLines;
    procedure UpdateRowAutoHeight(RowIndex: Integer);
    procedure UpdateActiveCellVisibility;
    procedure SetColumnCount(Value: Integer);
    procedure SetRowCount(Value: Integer);
    procedure SetGridType(Value: TGridTypeGI);
    function GetColumnWidth(ColumnIndex: Integer): Integer;
    procedure SetColumnWidth(ColumnIndex: Integer; Width: Integer);
    function GetRowHeight(RowIndex: Integer): Integer;
    procedure SetRowHeight(RowIndex: Integer; Height: Integer);
    procedure SetRowAutoHeightEnabled(RowIndex: Integer; Enabled: Boolean);
    function GetCell(CellX: Integer; CellY: Integer): TLabelGI;
    procedure SetRowSelectEnabled(Value: Boolean);
    procedure SetColSelectEnabled(Value: Boolean);
    procedure SetBackgroundImagePath(Path: WideString);
    procedure SetActiveCellImagePath(Path: WideString);
    procedure SetActiveCellImageHalfAlpha(Value: Boolean);
    procedure SetActiveCell(Cell: TPoint);
    procedure SelectCell(Cell: TPoint);
    procedure CellClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint);
    procedure LoadGridProperties(Block: TBlockParEC);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Classes,
  SysUtils,
  Windows,
  EC_Mem,
  EC_Str,
  GI_Main,
  GI_Line,
  GR_Main;
const
  // Cell UserValue packs the column below the row; decorations use -1.
  GridCellCoordinateMask = $FFFF;
  GridCellRowShift = 16;
  GridDecorationTag = -1;

constructor TGridGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  GridType := gtCell;
  GridColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  ActiveCellFrame := TFrameGI.Create(Self);
  ActiveCellFrame.SetPositionModeW(True);
  ActiveCellFrame.SetKind(fkRect);
  ActiveCellFrame.SetDepth(-3);
  ActiveCellFrame.SetColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
  ActiveCellFrame.UserValue := GridDecorationTag;
  SetDragScrollingEnabled(True);
  SetScrollbarsOutside(True);
  SetUnlimitedWorldEnabled(False);
end;

destructor TGridGI.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TGridGI.Clear;
begin
  if ControlName = 'DebugGrid' then
    SetColumnCount(0);
  SetColumnCount(0);
  SetRowCount(0);
  if ColumnWidths <> nil then
    FreeEC(ColumnWidths);
  ColumnWidths := nil;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  GridType := gtCell;
  GridColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BackgroundImage := nil;
  ActiveCellImage := nil;
  ActiveCell.X := -1;
  ActiveCell.Y := -1;
end;

procedure TGridGI.LayoutCell(Child: TObjectGI);
var
  X, Y, I: Integer;
begin
  if Child is TLabelGI then
  begin
    Child.SetSize(
        Classes.Point(
            GetColumnWidth(Child.UserValue and GridCellCoordinateMask) + 1,
            GetRowHeight(Child.UserValue shr GridCellRowShift) + 1
        )
    );
    X := 0;
    Y := 0;
    for I := 0 to (Child.UserValue and GridCellCoordinateMask) - 1 do
      X := X + GetColumnWidth(I);
    for I := 0 to (Child.UserValue shr GridCellRowShift) - 1 do
      Y := Y + GetRowHeight(I);
    Child.SetPosition(Classes.Point(X, Y));
    if not Child.PositionModeW then
    begin
      Child.SetPositionModeW(True);
      Child.SetDepth(-1);
      with Child as TLabelGI do
      begin
        SetFontName(Self.FontName);
        SetTextAlignX(taxLeft);
        SetTextAlignY(tayTop);
        LeftButtonDownCallback := CellClick;
        SetTextColor(Self.TextColor);
      end;
    end;
  end;
end;

procedure TGridGI.LayoutCells;
var
  Child, Current: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    Current := Child;
    Child := Child.NextSibling;
    LayoutCell(Current);
  end;
end;

procedure TGridGI.UpdateGridExtent;
var
  X, Y, I: Integer;
begin
  X := 0;
  Y := 0;
  for I := 0 to ColumnCount - 1 do
    X := X + GetColumnWidth(I);
  for I := 0 to RowCount - 1 do
    Y := Y + GetRowHeight(I);
  if BackgroundImage <> nil then
    BackgroundImage.SetSize(Classes.Point(X, Y));
  if (ActiveCell.X < 0)
      or (ActiveCell.X >= ColumnCount)
      or (ActiveCell.Y < 0)
      or (ActiveCell.Y >= RowCount) then
    ActiveCell := Classes.Point(-1, -1);
  RebuildGridLines;
  UpdateScrollRanges;
end;

procedure TGridGI.RebuildGridLines;
var
  Child, Current: TObjectGI;
  X, Y, I, Position: Integer;
  Line: TLineGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    Current := Child;
    Child := Child.NextSibling;
    if Current is TLineGI then
      FreeOwnedChild(Current);
  end;
  if (GridType = gtHide) or (ColumnCount < 1) or (RowCount < 1) then
    Exit;
  X := 0;
  Y := 0;
  for I := 0 to ColumnCount - 1 do
    X := X + GetColumnWidth(I);
  for I := 0 to RowCount - 1 do
    Y := Y + GetRowHeight(I);
  if ((GridType = gtCell) or (GridType = gtRow)) and (RowCount >= 2) then
  begin
    Position := GetRowHeight(0);
    for I := 1 to RowCount - 1 do
    begin
      Line := TLineGI.Create(Self);
      Line.SetPosition(Classes.Point(0, Position));
      Line.SetSize(Classes.Point(X + 1, 1));
      Line.SetPositionModeW(True);
      Line.SetColor(GridColor);
      Line.SetDepth(-2);
      Line.UserValue := GridDecorationTag;
      Position := Position + GetRowHeight(I);
    end;
  end;
  if ((GridType = gtCell) or (GridType = gtCol)) and (ColumnCount >= 2) then
  begin
    Position := GetColumnWidth(0);
    for I := 1 to ColumnCount - 1 do
    begin
      Line := TLineGI.Create(Self);
      Line.SetPosition(Classes.Point(Position, 0));
      Line.SetSize(Classes.Point(1, Y + 1));
      Line.SetPositionModeW(True);
      Line.SetColor(GridColor);
      Line.SetDepth(-2);
      Line.UserValue := GridDecorationTag;
      Position := Position + GetColumnWidth(I);
    end;
  end;
  Line := TLineGI.Create(Self);
  Line.SetPosition(Classes.Point(0, 0));
  Line.SetSize(Classes.Point(X + 1, 1));
  Line.SetPositionModeW(True);
  Line.SetColor(GridColor);
  Line.SetDepth(-2);
  Line.UserValue := GridDecorationTag;
  Line := TLineGI.Create(Self);
  Line.SetPosition(Classes.Point(0, Y));
  Line.SetSize(Classes.Point(X + 1, 1));
  Line.SetPositionModeW(True);
  Line.SetColor(GridColor);
  Line.SetDepth(-2);
  Line.UserValue := GridDecorationTag;
  Line := TLineGI.Create(Self);
  Line.SetPosition(Classes.Point(0, 0));
  Line.SetSize(Classes.Point(1, Y + 1));
  Line.SetPositionModeW(True);
  Line.SetColor(GridColor);
  Line.SetDepth(-2);
  Line.UserValue := GridDecorationTag;
  Line := TLineGI.Create(Self);
  Line.SetPosition(Classes.Point(X, 0));
  Line.SetSize(Classes.Point(1, Y + 1));
  Line.SetPositionModeW(True);
  Line.SetColor(GridColor);
  Line.SetDepth(-2);
  Line.UserValue := GridDecorationTag;
end;

procedure TGridGI.UpdateRowAutoHeight(RowIndex: Integer);
var
  Child: TObjectGI;
  Height, CellHeight: Integer;
begin
  Height := Rows[RowIndex].AutoHeightMinimum;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child is TLabelGI) and (Child.UserValue shr GridCellRowShift = RowIndex) then
    begin
      CellHeight := (Child as TLabelGI).MeasureContentSize(nil).Y + 2;
      if CellHeight > Height then
        Height := CellHeight;
    end;
    Child := Child.NextSibling;
  end;
  SetRowHeight(RowIndex, Height);
end;

procedure TGridGI.UpdateActiveCellVisibility;
var
  Rect: TRect;
begin
  if (ActiveCell.X >= ColumnCount) or (ActiveCell.Y >= RowCount) then
    ActiveCell := Classes.Point(-1, -1);
  Rect.Left := ActiveCellFrame.LocalPosition.X;
  Rect.Top := ActiveCellFrame.LocalPosition.Y;
  Rect.Right := ActiveCellFrame.LocalPosition.X + ActiveCellFrame.ClientSize.X;
  Rect.Bottom := ActiveCellFrame.LocalPosition.Y + ActiveCellFrame.ClientSize.Y;
  ScrollRectIntoView(Rect);
  if (ActiveCell.X < 0) or (ActiveCell.Y < 0) then
  begin
    if ActiveCellFrame <> nil then
      ActiveCellFrame.SetActive(False);
    if ActiveCellImage <> nil then
      ActiveCellImage.SetActive(False);
  end
  else
  begin
    if ActiveCellFrame <> nil then
      ActiveCellFrame.SetActive(True);
    if ActiveCellImage <> nil then
      ActiveCellImage.SetActive(True);
  end;
end;

procedure TGridGI.SetColumnCount(Value: Integer);
var
  Child, Current: TObjectGI;
  X, Y, OldCount: Integer;
begin
  if Value = ColumnCount then
    Exit;
  OldCount := ColumnCount;
  ColumnCount := Value;
  ColumnWidths := ReAllocREC(ColumnWidths, Value * SizeOf(Integer));
  if Value < OldCount then
  begin
    Child := FirstChild;
    while Child <> nil do
    begin
      Current := Child;
      Child := Child.NextSibling;
      if (Current is TLabelGI)
          and (Current.UserValue and GridCellCoordinateMask >= Value)
          and (Current.UserValue <> GridDecorationTag) then
        FreeOwnedChild(Current);
    end;
  end
  else
  begin
    for X := OldCount to Value - 1 do
    begin
      WriteIntegerEC(AddPointerOffset(ColumnWidths, X * SizeOf(Integer)), 100);
      for Y := 0 to RowCount - 1 do
      begin
        Child := TLabelGI.Create(Self);
        Child.UserValue := X or (Y shl GridCellRowShift);
        LayoutCell(Child);
      end;
    end;
  end;
  UpdateGridExtent;
  Invalidate;
end;

procedure TGridGI.SetRowCount(Value: Integer);
var
  Child, Current: TObjectGI;
  X, Y, OldCount: Integer;
begin
  if Value = RowCount then
    Exit;
  OldCount := RowCount;
  RowCount := Value;
  SetLength(Rows, RowCount);
  if Value < OldCount then
  begin
    Child := FirstChild;
    while Child <> nil do
    begin
      Current := Child;
      Child := Child.NextSibling;
      if (Current is TLabelGI)
          and (Current.UserValue shr GridCellRowShift and GridCellCoordinateMask >= Value)
          and (Current.UserValue <> GridDecorationTag) then
        FreeOwnedChild(Current);
    end;
  end
  else
  begin
    for Y := OldCount to Value - 1 do
    begin
      Rows[Y].Height := 15;
      Rows[Y].AutoHeightMinimum := 15;
      Rows[Y].AutoHeight := False;
      for X := 0 to ColumnCount - 1 do
      begin
        Child := TLabelGI.Create(Self);
        Child.UserValue := X or (Y shl GridCellRowShift);
        LayoutCell(Child);
      end;
    end;
  end;
  UpdateActiveCellVisibility;
  UpdateGridExtent;
  Invalidate;
end;

procedure TGridGI.SetGridType(Value: TGridTypeGI);
begin
  if Value <> GridType then
  begin
    GridType := Value;
    LayoutCells;
    UpdateGridExtent;
    Invalidate;
  end;
end;

function TGridGI.GetColumnWidth(ColumnIndex: Integer): Integer;
begin
  if (ColumnIndex < 0) or (ColumnIndex >= ColumnCount) then
    raise Exception.Create(
        'TGridGI.GetSizeX. ('
            + IntToStr(ColumnIndex)
            + '<0) or ('
            + IntToStr(ColumnIndex)
            + '>0'
            + IntToStr(ColumnCount)
            + ')');
  Result := ReadIntegerEC(AddPointerOffset(ColumnWidths, ColumnIndex * SizeOf(Integer)));
end;

procedure TGridGI.SetColumnWidth(ColumnIndex, Width: Integer);
begin
  if GetColumnWidth(ColumnIndex) <> Width then
  begin
    WriteInt32EC(AddPointerOffset(ColumnWidths, ColumnIndex * SizeOf(Integer)), Width);
    LayoutCells;
    UpdateGridExtent;
    Invalidate;
  end;
end;

function TGridGI.GetRowHeight(RowIndex: Integer): Integer;
begin
  if (RowIndex < 0) or (RowIndex >= RowCount) then
    raise Exception.Create(
        'TGridGI.GetSizeX. ('
            + IntToStr(RowIndex)
            + '<0) or ('
            + IntToStr(RowIndex)
            + '>='
            + IntToStr(RowCount)
            + ')');
  Result := Rows[RowIndex].Height;
end;

procedure TGridGI.SetRowHeight(RowIndex, Height: Integer);
var
  Cell: TPoint;
begin
  if GetRowHeight(RowIndex) <> Height then
  begin
    Rows[RowIndex].Height := Height;
    if Rows[RowIndex].AutoHeight then
      Rows[RowIndex].AutoHeightMinimum := Rows[RowIndex].Height;
    LayoutCells;
    UpdateGridExtent;
    Cell := ActiveCell;
    ActiveCell.X := -2;
    SetActiveCell(Cell);
    Invalidate;
  end;
end;

procedure TGridGI.SetRowAutoHeightEnabled(RowIndex: Integer; Enabled: Boolean);
begin
  if Rows[RowIndex].AutoHeight <> Enabled then
  begin
    Rows[RowIndex].AutoHeight := Enabled;
    UpdateRowAutoHeight(RowIndex);
  end;
end;

function TGridGI.GetCell(CellX, CellY: Integer): TLabelGI;
var
  Child: TObjectGI;
begin
  if (CellX < 0) or (ColumnCount <= CellX) or (CellY < 0) or (RowCount <= CellY) then
    raise Exception.Create(
        'TGridGI.GetCell. Cell='
            + IntToStr(CellX)
            + ','
            + IntToStr(CellY)
            + '  Count='
            + IntToStr(ColumnCount)
            + ','
            + IntToStr(RowCount));
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child is TLabelGI)
        and (Child.UserValue and GridCellCoordinateMask = CellX)
        and (Child.UserValue shr GridCellRowShift = CellY) then
    begin
      Result := Child as TLabelGI;
      Exit;
    end;
    Child := Child.NextSibling;
  end;
  raise Exception.Create(
      'TGridGI.GetCell. Cell='
          + IntToStr(CellX)
          + ','
          + IntToStr(CellY)
          + '  Count='
          + IntToStr(ColumnCount)
          + ','
          + IntToStr(RowCount));
end;

procedure TGridGI.SetRowSelectEnabled(Value: Boolean);
begin
  if RowSelect <> Value then
  begin
    RowSelect := Value;
    Invalidate;
  end;
end;

procedure TGridGI.SetColSelectEnabled(Value: Boolean);
begin
  if ColSelect <> Value then
  begin
    ColSelect := Value;
    Invalidate;
  end;
end;

procedure TGridGI.SetBackgroundImagePath(Path: WideString);
var
  Image: TImageGI;
begin
  if BackgroundImage <> nil then
  begin
    FreeOwnedChild(BackgroundImage);
    BackgroundImage := nil;
  end;
  Image := TImageGI.Create(Self);
  Image.UserValue := GridDecorationTag;
  Image.SetDepth(2);
  Image.SetImagePath(Path);
  Image.SetImageKindX(ikxLeftFill);
  Image.SetImageKindY(ikyTopFill);
  Image.SetPositionModeW(True);
  BackgroundImage := Image;
  UpdateGridExtent;
end;

procedure TGridGI.SetActiveCellImagePath(Path: WideString);
begin
  if Path = '' then
  begin
    if ActiveCellImage <> nil then
    begin
      FreeOwnedChild(ActiveCellImage);
      ActiveCellImage := nil;
    end;
  end
  else
  begin
    if ActiveCellImage = nil then
      ActiveCellImage := TImageGI.Create(Self);
    ActiveCellImage.SetImagePath(Path);
    ActiveCellImage.SetImageKindX(ikxLeftFill);
    ActiveCellImage.SetImageKindY(ikyTopFill);
    ActiveCellImage.UserValue := GridDecorationTag;
    ActiveCellImage.SetDepth(1);
    ActiveCellImage.SetPositionModeW(True);
  end;
  UpdateGridExtent;
  Invalidate;
end;

procedure TGridGI.SetActiveCellImageHalfAlpha(Value: Boolean);
begin
  if ActiveCellImage <> nil then
    ActiveCellImage.SetHalfAlpha(Value);
end;

procedure TGridGI.SetActiveCell(Cell: TPoint);
var
  LabelControl: TLabelGI;
begin
  if (ActiveCell.X = Cell.X) and (ActiveCell.Y = Cell.Y) then
    Exit;
  ActiveCell := Cell;
  if (ActiveCell.X >= 0)
      and (ActiveCell.X < ColumnCount)
      and (ActiveCell.Y >= 0)
      and (ActiveCell.Y < RowCount) then
  begin
    if ActiveCellImage <> nil then
    begin
      if not RowSelect and not ColSelect then
      begin
        LabelControl := GetCell(ActiveCell.X, ActiveCell.Y);
        ActiveCellImage.SetPosition(LabelControl.LocalPosition);
        ActiveCellImage.SetSize(LabelControl.ClientSize);
      end
      else if RowSelect then
      begin
        LabelControl := GetCell(0, ActiveCell.Y);
        ActiveCellImage.SetPosition(LabelControl.LocalPosition);
        LabelControl := GetCell(ColumnCount - 1, ActiveCell.Y);
        ActiveCellImage.SetSize(
            Classes.Point(
                LabelControl.LocalPosition.X + LabelControl.ClientSize.X,
                LabelControl.ClientSize.Y
            )
        );
      end
      else if ColSelect then
      begin
        LabelControl := GetCell(ActiveCell.X, 0);
        ActiveCellImage.SetPosition(LabelControl.LocalPosition);
        LabelControl := GetCell(ActiveCell.X, RowCount - 1);
        ActiveCellImage.SetSize(
            Classes.Point(
                LabelControl.ClientSize.X,
                LabelControl.LocalPosition.Y + LabelControl.ClientSize.Y
            )
        );
      end;
    end;
    if not RowSelect and not ColSelect then
    begin
      LabelControl := GetCell(ActiveCell.X, ActiveCell.Y);
      ActiveCellFrame.SetPosition(LabelControl.LocalPosition);
      ActiveCellFrame.SetSize(LabelControl.ClientSize);
    end
    else if RowSelect then
    begin
      LabelControl := GetCell(0, ActiveCell.Y);
      ActiveCellFrame.SetPosition(LabelControl.LocalPosition);
      LabelControl := GetCell(ColumnCount - 1, ActiveCell.Y);
      ActiveCellFrame.SetSize(
          Classes.Point(
              LabelControl.LocalPosition.X + LabelControl.ClientSize.X,
              LabelControl.ClientSize.Y
          )
      );
    end
    else if ColSelect then
    begin
      LabelControl := GetCell(ActiveCell.X, 0);
      ActiveCellFrame.SetPosition(LabelControl.LocalPosition);
      LabelControl := GetCell(ActiveCell.X, RowCount - 1);
      ActiveCellFrame.SetSize(
          Classes.Point(
              LabelControl.ClientSize.X,
              LabelControl.LocalPosition.Y + LabelControl.ClientSize.Y
          )
      );
    end;
  end
  else
    ActiveCell := Classes.Point(-1, -1);
  UpdateActiveCellVisibility;
  Invalidate;
end;

procedure TGridGI.SelectCell(Cell: TPoint);
begin
  if (Cell.X < 0) or (Cell.X >= ColumnCount) or (Cell.Y < 0) or (Cell.Y >= RowCount) then
    Exit;
  if Assigned(CanSelectCellCallback) then
    if not CanSelectCellCallback(Self, Cell) then
      Exit;
  SetActiveCell(Cell);
  if Assigned(SelectionChangedCallback) then
    SelectionChangedCallback(Self);
end;

procedure TGridGI.CellClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint);
var
  Cell: TPoint;
  Repeated: Boolean;
begin
  Cell :=
      Classes.Point(
          Sender.UserValue and GridCellCoordinateMask,
          Sender.UserValue shr GridCellRowShift
      );
  if Assigned(CanSelectCellCallback) then
    if not CanSelectCellCallback(Self, Cell) then
      Exit;
  if ((ActiveCell.Y = Cell.Y) and RowSelect)
      or ((ActiveCell.X = Cell.X) and ColSelect)
      or ((ActiveCell.X = Cell.X) and (ActiveCell.Y = Cell.Y)) then
    Repeated := True
  else
    Repeated := False;
  SetActiveCell(Cell);
  if Repeated then
  begin
    if Assigned(RepeatedCellClickCallback) then
      RepeatedCellClickCallback(Self);
  end
  else if Assigned(SelectionChangedCallback) then
    SelectionChangedCallback(Self);
end;

procedure TGridGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  if IsOccludedAtPoint(Point) then
    Exit;
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Active = True then
    MessageLoop.SetFocusedControl(Self);
end;

procedure TGridGI.OnFocusGained;
begin
  inherited OnFocusGained;
end;

procedure TGridGI.OnFocusLost;
begin
  inherited OnFocusLost;
end;

procedure TGridGI.ProcessKeyDown(Key: Integer);
begin
  if Key = VK_LEFT then
    SelectCell(Classes.Point(ActiveCell.X - 1, ActiveCell.Y))
  else if Key = VK_RIGHT then
    SelectCell(Classes.Point(ActiveCell.X + 1, ActiveCell.Y))
  else if Key = VK_UP then
    SelectCell(Classes.Point(ActiveCell.X, ActiveCell.Y - 1))
  else if Key = VK_DOWN then
    SelectCell(Classes.Point(ActiveCell.X, ActiveCell.Y + 1));
end;

procedure TGridGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadGridProperties(Block);
end;

procedure TGridGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadGridProperties(Block);
end;

procedure TGridGI.LoadGridProperties(Block: TBlockParEC);
var
  Text: WideString;
  Red, Green, Blue: Byte;
  Properties, CellProperties: TBlockParEC;
  LabelControl: TLabelGI;
  I, RowIndex, Count, CellX, CellY: Integer;
begin
  if Block.CountParams('Font') > 0 then
    FontName := TrimWideString(Block.GetParam('Font'));
  if Block.CountParams('TextColor') > 0 then
  begin
    Text := Block.GetParam('TextColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    TextColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('GridType') > 0 then
  begin
    Text := TrimWideString(Block.GetParam('GridType'));
    if Text = 'Hide' then
      SetGridType(gtHide)
    else if Text = 'Cell' then
      SetGridType(gtCell)
    else if Text = 'Row' then
      SetGridType(gtRow)
    else if Text = 'Col' then
      SetGridType(gtCol);
  end;
  if Block.CountParams('GridColor') > 0 then
  begin
    Text := Block.GetParam('GridColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    GridColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CountX') > 0 then
    SetColumnCount(StrToInt(Block.GetParam('CountX')));
  if Block.CountParams('CountY') > 0 then
    SetRowCount(StrToInt(Block.GetParam('CountY')));
  if Block.CountBlocks('GridX') > 0 then
  begin
    Properties := Block.GetBlock('GridX');
    Count := Properties.GetParamCount;
    for I := 0 to Count - 1 do
      SetColumnWidth(StrToInt(Properties.GetParamName(I)), StrToInt(Properties.GetParamValue(I)));
  end;
  if Block.CountBlocks('GridY') > 0 then
  begin
    Properties := Block.GetBlock('GridY');
    Count := Properties.GetParamCount;
    for I := 0 to Count - 1 do
    begin
      Text := TrimWideString(Properties.GetParamValue(I));
      RowIndex := StrToInt(Properties.GetParamName(I));
      if CountDelimitedPartsW(Text, ',') < 2 then
      begin
        Rows[RowIndex].AutoHeightMinimum := StrToInt(Text);
        SetRowHeight(RowIndex, StrToInt(Text));
        Rows[RowIndex].AutoHeight := False;
      end
      else
      begin
        if ExtractDelimitedPartW(Text, 1, ',') = 'Auto' then
          SetRowAutoHeightEnabled(RowIndex, True)
        else
          SetRowAutoHeightEnabled(RowIndex, False);
        SetRowHeight(RowIndex, StrToInt(ExtractDelimitedPartW(Text, 0, ',')));
      end;
    end;
  end;
  if Block.CountBlocks('GridCells') > 0 then
  begin
    Properties := Block.GetBlock('GridCells');
    Count := Properties.GetParamCount;
    for I := 0 to Count - 1 do
    begin
      Text := Properties.GetParamName(I);
      RowIndex := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
      GetCell(StrToInt(ExtractDelimitedPartW(Text, 0, ',')), RowIndex)
          .LoadTextLinesFromBlockParam(Properties, Text);
      if Rows[RowIndex].AutoHeight then
        UpdateRowAutoHeight(RowIndex);
    end;
    Count := Properties.GetBlockCount;
    for I := 0 to Count - 1 do
    begin
      Text := Properties.GetBlockNameByIndex(I);
      CellX := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
      CellY := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
      LabelControl := GetCell(CellX, CellY);
      CellProperties := Properties.GetBlockByIndex(I);
      if CellProperties.CountParams('WordWrap') > 0 then
        LabelControl.SetWordWrapEnabled(
            ParseEnabledNameGI(TrimWideString(CellProperties.GetParam('WordWrap')))
        );
      if CellProperties.CountParams('AlignY') > 0 then
        LabelControl
            .SetTextAlignY(ParseTextAlignYName(TrimWideString(CellProperties.GetParam('AlignY'))));
      if CellProperties.CountParams('AlignX') > 0 then
        LabelControl
            .SetTextAlignX(ParseTextAlignXName(TrimWideString(CellProperties.GetParam('AlignX'))));
      if CellProperties.CountParams('TextColor') > 0 then
        LabelControl.SetTextColor(GetColorGI(Block.GetParam('TextColor')));
      if CellProperties.CountParams('Image') > 0 then
        LabelControl.SetEmbeddedImagePath(CellProperties.GetParam('Image'));
      if CellProperties.CountParams('ImageKindX') > 0 then
        LabelControl
            .SetEmbeddedImageKindX(ParseImageKindXName(CellProperties.GetParam('ImageKindX')));
      if CellProperties.CountParams('ImageKindY') > 0 then
        LabelControl
            .SetEmbeddedImageKindY(ParseImageKindYName(CellProperties.GetParam('ImageKindY')));
      if CellProperties.CountParams('ImageHalfAlpha') > 0 then
        LabelControl.SetEmbeddedImageHalfAlpha(
            ParseEnabledNameGI(CellProperties.GetParam('ImageHalfAlpha'))
        );
      UpdateRowAutoHeight(CellY);
    end;
  end;
  if Block.CountParams('BackgroundImage') > 0 then
    SetBackgroundImagePath(Block.GetParam('BackgroundImage'));
  if Block.CountParams('RowSelect') > 0 then
  begin
    if TrimWideString(Block.GetParam('RowSelect')) = 'True' then
      SetRowSelectEnabled(True)
    else
      SetRowSelectEnabled(False);
  end;
  if Block.CountParams('ColSelect') > 0 then
  begin
    if TrimWideString(Block.GetParam('ColSelect')) = 'True' then
      SetColSelectEnabled(True)
    else
      SetColSelectEnabled(False);
  end;
  if Block.CountParams('ActiveCellImage') > 0 then
    SetActiveCellImagePath(Block.GetParam('ActiveCellImage'));
  if Block.CountParams('ActiveCell') > 0 then
  begin
    Text := Block.GetParam('ActiveCell');
    SetActiveCell(
        Classes.Point(
            StrToInt(ExtractDelimitedPartW(Text, 0, ',')),
            StrToInt(ExtractDelimitedPartW(Text, 1, ','))
        )
    );
  end;
  if Block.CountParams('ActiveCellImageHalfAlpha') > 0 then
    SetActiveCellImageHalfAlpha(ParseEnabledNameGI(Block.GetParam('ActiveCellImageHalfAlpha')));
end;

procedure TGridGI.Draw(ClipRect: TRect);
begin
  inherited Draw(ClipRect);
end;

procedure LinkRecoveredTypes;
begin
  TLabelGI.ClassName;
  TLineGI.ClassName;
end;
end.
