{$EXCESSPRECISION OFF}
unit ab_Polygon;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  ab_StopLine;
type
  PointerToTabPolygon = ^TabPolygon;
  PointerToTabOptGroup = ^TabOptGroup;
  PointerToTabOptUnit = ^TabOptUnit;
  TabPolygonVertex = record
    Point: PabStopPoint;
    Color: PCardinal;
  end;
  PabPolygon = PointerToTabPolygon;
  TabPolygon = record
    Prev: PabPolygon;
    Next: PabPolygon;
    Vertices: array[0..2] of TabPolygonVertex;
    Gap20: array[0..15] of Byte;
    MapValue30: Integer;
  end;
  PabPolygonGroup = PointerToTabOptGroup;
  TabOptGroup = record
    Polygons: array of PabPolygon;
    Gap4: array[0..3] of Byte;
    Corners: array[0..3] of TVector3D;
  end;
  PabPolygonCell = PointerToTabOptUnit;
  TabOptUnit = record
    Points: array of PabStopPoint;
    Groups: array of PabPolygonGroup;
  end;
var
  FirstPolygon: PabPolygon = nil;
  LastPolygon: PabPolygon = nil;
  PolygonStorage: PabPolygon;
  PolygonGroups: array of TabOptGroup;
  PolygonCells: array of TabOptUnit;
  LongitudeCellCount: Integer;
  PolarCellCount: Integer;
  CurrentPolygonCell: PabPolygonCell;
procedure ab_Polygon_Clear;
function ab_Polygon_Count: Integer;
procedure ab_Polygon_ClearVisibility;
procedure ab_Polygon_LoadVisibility(Buffer: TBufEC);
procedure ab_Polygon_SelectVisibilityCell;
procedure ab_Polygon_ProjectVisiblePoints;
procedure ab_Polygon_QueueUpdateRects;
procedure ab_Polygon_Draw;
procedure ab_Polygon_Load(Buffer: TBufEC);
implementation
uses
  Math,
  Classes,
  EC_Mem,
  GI_Tail,
  ab_Global,
  GR_Main,
  GR_DX,
  Globals,
  GlobalsV;
// @unit-initialization $877860
// @unit-finalization $53B500

procedure ab_Polygon_Clear;
begin
  ab_Polygon_ClearVisibility;
  if PolygonStorage <> nil then
  begin
    FreeEC(PolygonStorage);
    PolygonStorage := nil;
  end;
  FirstPolygon := nil;
  LastPolygon := nil;
end;

function ab_Polygon_Count: Integer;
var
  Polygon: PabPolygon;
begin
  Result := 0;
  Polygon := FirstPolygon;
  while Polygon <> nil do
  begin
    Inc(Result);
    Polygon := Polygon.Next;
  end;
end;

procedure ab_Polygon_ClearVisibility;
var
  Index: Integer;
begin
  for Index := 0 to High(PolygonCells) do
  begin
    PolygonCells[Index].Points := nil;
    PolygonCells[Index].Groups := nil;
  end;
  for Index := 0 to High(PolygonGroups) do
    PolygonGroups[Index].Polygons := nil;
  PolygonGroups := nil;
  PolygonCells := nil;
  CurrentPolygonCell := nil;
end;

procedure ab_Polygon_LoadVisibility(Buffer: TBufEC);
var
  Index, ItemIndex, Count: Integer;
  Polygons: array of PabPolygon;
  Polygon: PabPolygon;
  Cursor: Pointer;
  PointIndex: Integer;
  Group: PabPolygonGroup;
begin
  ab_Polygon_ClearVisibility;
  Count := ab_Polygon_Count;
  SetLength(Polygons, Count);
  Index := 0;
  Polygon := FirstPolygon;
  while Polygon <> nil do
  begin
    Polygons[Index] := Polygon;
    Inc(Index);
    Polygon := Polygon.Next;
  end;
  LongitudeCellCount := Buffer.GetInt32;
  PolarCellCount := Buffer.GetInt32;
  SetLength(PolygonCells, LongitudeCellCount * PolarCellCount);
  SetLength(PolygonGroups, Buffer.GetInt32);
  for Index := 0 to High(PolygonGroups) do
  begin
    Group := @PolygonGroups[Index];
    Count := Buffer.GetWord;
    SetLength(Group.Polygons, Count);
    Cursor := Pointer(PtrInt(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to High(Group.Polygons) do
    begin
      Group.Polygons[ItemIndex] := Polygons[PWord(Cursor)^];
      Cursor := Pointer(PtrInt(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
    Cursor := Pointer(PtrInt(Buffer.Data) + Buffer.Position);
    Group.Corners[0].X := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[0].Y := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[0].Z := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[1].X := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[1].Y := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[1].Z := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[2].X := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[2].Y := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[2].Z := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[3].X := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[3].Y := PSingle(Cursor)^;
    Cursor := Pointer(PtrInt(Cursor) + 4);
    Group.Corners[3].Z := PSingle(Cursor)^;
    Buffer.SetPosition(Buffer.Position + 48);
  end;
  for Index := 0 to LongitudeCellCount * PolarCellCount - 1 do
  begin
    CurrentPolygonCell := @PolygonCells[Index];
    Count := Buffer.GetWord;
    SetLength(CurrentPolygonCell.Points, Count);
    Cursor := Pointer(PtrInt(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to Count - 1 do
    begin
      PointIndex := PWord(Cursor)^;
      CurrentPolygonCell.Points[ItemIndex] := StopPointIndex[PointIndex];
      Cursor := Pointer(PtrInt(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
    Count := Buffer.GetWord;
    SetLength(CurrentPolygonCell.Groups, Count);
    Cursor := Pointer(PtrInt(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to Count - 1 do
    begin
      CurrentPolygonCell.Groups[ItemIndex] := @PolygonGroups[PWord(Cursor)^];
      Cursor := Pointer(PtrInt(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
  end;
  Polygons := nil;
  CurrentPolygonCell := nil;
end;

procedure ab_Polygon_SelectVisibilityCell;
var
  LongitudeIndex, PolarIndex: Integer;
begin
  LongitudeIndex := Round(SphereViewState.LongitudeDegrees / 360 * LongitudeCellCount);
  if LongitudeIndex >= LongitudeCellCount then
    LongitudeIndex := 0;
  PolarIndex := Round(SphereViewState.PolarAngleDegrees / 180 * (PolarCellCount - 1));
  if PolarIndex >= PolarCellCount then
    RaiseWideMessage('ab_OptCur');
  CurrentPolygonCell := @PolygonCells[LongitudeIndex * PolarCellCount + PolarIndex];
end;

procedure ab_Polygon_ProjectVisiblePoints;
var
  Index, Count: Integer;
  Point: PabStopPoint;
  Projected: TVector3D;
begin
  if CurrentPolygonCell = nil then
    Exit;
  if CurrentPolygonCell.Points = nil then
    Exit;
  Count := High(CurrentPolygonCell.Points) + 1;
  for Index := 0 to Count - 1 do
  begin
    Point := CurrentPolygonCell.Points[Index];
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Point.Position);
    Point.Projected := True;
    Point.ScreenX := ArcadeBattleScreen.WorldCenterX + Round(Projected.X);
    Point.ScreenY := ArcadeBattleScreen.WorldCenterY + Round(Projected.Y);
  end;
end;

procedure ab_Polygon_QueueUpdateRects;
var
  Index, Count: Integer;
  Group: PabPolygonGroup;
  MinX, MaxX, MinY, MaxY: Double;
  CenterX, CenterY: Integer;
  Projected: TVector3D;
begin
  if CurrentPolygonCell = nil then
    Exit;
  if CurrentPolygonCell.Groups = nil then
    Exit;
  CenterX := ArcadeBattleScreen.WorldCenterX;
  CenterY := ArcadeBattleScreen.WorldCenterY;
  Count := High(CurrentPolygonCell.Groups) + 1;
  for Index := 0 to Count - 1 do
  begin
    Group := CurrentPolygonCell.Groups[Index];
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[0]);
    MinX := Projected.X;
    MaxX := Projected.X;
    MinY := Projected.Y;
    MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[1]);
    if Projected.X < MinX then
      MinX := Projected.X
    else if Projected.X > MaxX then
      MaxX := Projected.X;
    if Projected.Y < MinY then
      MinY := Projected.Y
    else if Projected.Y > MaxY then
      MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[2]);
    if Projected.X < MinX then
      MinX := Projected.X
    else if Projected.X > MaxX then
      MaxX := Projected.X;
    if Projected.Y < MinY then
      MinY := Projected.Y
    else if Projected.Y > MaxY then
      MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[3]);
    if Projected.X < MinX then
      MinX := Projected.X
    else if Projected.X > MaxX then
      MaxX := Projected.X;
    if Projected.Y < MinY then
      MinY := Projected.Y
    else if Projected.Y > MaxY then
      MaxY := Projected.Y;
    ArcadeBattleScreen.QueueUpdateRect(
        Classes.Rect(
            CenterX + Round(MinX),
            CenterY + Round(MinY),
            CenterX + Round(MaxX) + 1,
            CenterY + Round(MaxY) + 1
        )
    );
  end;
end;

procedure ab_Polygon_Draw;
var
  GroupIndex, GroupCount, PolygonIndex, PolygonCount: Integer;
  Group: PabPolygonGroup;
  Polygon: PabPolygon;
begin
  if CurrentPolygonCell = nil then
    Exit;
  if CurrentPolygonCell.Groups = nil then
    Exit;
  GroupCount := High(CurrentPolygonCell.Groups) + 1;
  for GroupIndex := 0 to GroupCount - 1 do
  begin
    Group := CurrentPolygonCell.Groups[GroupIndex];
    PolygonCount := High(Group.Polygons) + 1;
    for PolygonIndex := 0 to PolygonCount - 1 do
    begin
      Polygon := Group.Polygons[PolygonIndex];
      if HardwareRenderingEnabled then
        DrawColoredTriangle(
            Polygon.Vertices[0].Point.ScreenX,
            Polygon.Vertices[0].Point.ScreenY,
            Polygon.Vertices[0].Color^,
            Polygon.Vertices[1].Point.ScreenX,
            Polygon.Vertices[1].Point.ScreenY,
            Polygon.Vertices[1].Color^,
            Polygon.Vertices[2].Point.ScreenX,
            Polygon.Vertices[2].Point.ScreenY,
            Polygon.Vertices[2].Color^,
            True,
            @GameScreenRect
        )
      else
        TriangleRasterizer16(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            Polygon.Vertices[0].Point.ScreenX,
            Polygon.Vertices[0].Point.ScreenY,
            Polygon.Vertices[0].Color^,
            Polygon.Vertices[1].Point.ScreenX,
            Polygon.Vertices[1].Point.ScreenY,
            Polygon.Vertices[1].Color^,
            Polygon.Vertices[2].Point.ScreenX,
            Polygon.Vertices[2].Point.ScreenY,
            Polygon.Vertices[2].Color^,
            @GameScreenRect
        );
    end;
  end;
end;

procedure ab_Polygon_Load(Buffer: TBufEC);
var
  Index, Count, Vertex: Integer;
  Polygon: PabPolygon;
begin
  ab_Polygon_Clear;
  Count := Buffer.GetInt32;
  if Count < 1 then
    Exit;
  PolygonStorage := AllocClearEC(Count * SizeOf(TabPolygon));
  Polygon := PolygonStorage;
  for Index := 0 to Count - 1 do
  begin
    if LastPolygon <> nil then
      LastPolygon.Next := Polygon;
    Polygon.Prev := LastPolygon;
    Polygon.Next := nil;
    LastPolygon := Polygon;
    if FirstPolygon = nil then
      FirstPolygon := Polygon;
    Polygon.MapValue30 := Buffer.GetInt32;
    for Vertex := 0 to 2 do
    begin
      Polygon.Vertices[Vertex].Point := StopPointIndex[Buffer.GetInt32];
      Polygon.Vertices[Vertex].Color :=
          Pointer(PtrInt(ArcadeMapColorBuffer.Data) + Buffer.GetInt32);
    end;
    Polygon := Pointer(PtrInt(Polygon) + SizeOf(TabPolygon));
  end;
end;

end.
