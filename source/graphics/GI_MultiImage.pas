{$EXCESSPRECISION OFF}
unit GI_MultiImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  EC_CacheGI,
  EC_BlockPar,
  Classes,
  Types;
type
  TMultiImageColGI = class;
  TMultiImageGI = class;
  TMultiImageImageGI = class;
  TMultiImageRowGI = class;
  TMultiImageUnitGI = class;
  TMultiImageUnitGI = class(TObject)
    Prev: TMultiImageUnitGI;
    Next: TMultiImageUnitGI;
    PrevInColumn: TMultiImageUnitGI;
    NextInColumn: TMultiImageUnitGI;
    Column: TMultiImageColGI;
    ImageIndex: Integer;
    Position: TPoint;
    UserData: Pointer;
  end;
  TMultiImageColGI = class(TObject)
    Prev: TMultiImageColGI;
    Next: TMultiImageColGI;
    First: TMultiImageUnitGI;
    Last: TMultiImageUnitGI;
    Row: TMultiImageRowGI;
    Index: Integer;
  end;
  TMultiImageRowGI = class(TObject)
    Prev: TMultiImageRowGI;
    Next: TMultiImageRowGI;
    First: TMultiImageColGI;
    Last: TMultiImageColGI;
    Index: Integer;
  end;
  TMultiImageImageGI = class(TObject)
    ImageCache: TCGiControlEC;
    Bounds: TRect;
    constructor Create;
    destructor Destroy; override;
    procedure SetImage(Path: WideString);
  end;
  TMultiImageGI = class(TObjectGI)
    FirstUnit: TMultiImageUnitGI;
    LastUnit: TMultiImageUnitGI;
    FirstRow: TMultiImageRowGI;
    LastRow: TMultiImageRowGI;
    CellSize: Integer;
    Images: TList;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    function AddUnit: TMultiImageUnitGI;
    procedure RemoveUnit(Item: TMultiImageUnitGI);
    procedure ClearUnits;
    procedure UnlinkUnitFromColumn(Item: TMultiImageUnitGI);
    procedure ClearSpatialIndex;
    function GetOrCreateRow(Index: Integer): TMultiImageRowGI;
    function GetOrCreateColumn(Row: TMultiImageRowGI; Index: Integer): TMultiImageColGI;
    procedure SetUnitPosition(Item: TMultiImageUnitGI; Position: TPoint);
    procedure ClearImages;
    function AddImage(Path: WideString): Integer;
    procedure LoadImageProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GlobalsV,
  EC_Cache,
  EC_Struct,
  GR_Main,
  GR_DX;
// Neutral integer expressions retain DCC32 operand materialization order.
// These expressions emit no extra arithmetic.

constructor TMultiImageImageGI.Create;
begin
  inherited Create;
  ImageCache := TCGiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
end;

destructor TMultiImageImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TMultiImageImageGI.SetImage(Path: WideString);
var
  Data: TCGiEC;
  Size: TPoint;
begin
  if ImageCache.CacheKey <> Path then
  begin
    ImageCache.SetCacheKey(Path);
    Data := AcquireCachedGi(ImageCache);
    try
      Size := Data.Image.GetContentSize;
    finally
      ImageCache.Release;
    end;
    Bounds.Left := -Size.X div 2;
    Bounds.Top := -Size.Y div 2;
    Bounds.Right := Bounds.Left + Size.X;
    Bounds.Bottom := Bounds.Top + Size.Y;
  end;
end;

constructor TMultiImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Images := TList.Create;
  CellSize := 128;
end;

destructor TMultiImageGI.Destroy;
begin
  ClearImages;
  ClearUnits;
  Images.Free;
  Images := nil;
  inherited Destroy;
end;

procedure TMultiImageGI.Clear;
begin
  ClearImages;
  ClearUnits;
  inherited Clear;
end;

function TMultiImageGI.AddUnit: TMultiImageUnitGI;
var
  Item: TMultiImageUnitGI;
begin
  Item := TMultiImageUnitGI.Create;
  if LastUnit <> nil then
    LastUnit.Next := Item;
  Item.Prev := LastUnit;
  Item.Next := nil;
  LastUnit := Item;
  if FirstUnit = nil then
    FirstUnit := Item;
  Result := Item;
end;

procedure TMultiImageGI.RemoveUnit(Item: TMultiImageUnitGI);
begin
  UnlinkUnitFromColumn(Item);
  if Item.Prev <> nil then
    Item.Prev.Next := Item.Next;
  if Item.Next <> nil then
    Item.Next.Prev := Item.Prev;
  if LastUnit = Item then
    LastUnit := Item.Prev;
  if FirstUnit = Item then
    FirstUnit := Item.Next;
  Item.Free;
end;

procedure TMultiImageGI.ClearUnits;
begin
  ClearSpatialIndex;
  while FirstUnit <> nil do
    RemoveUnit(LastUnit);
end;

procedure TMultiImageGI.UnlinkUnitFromColumn(Item: TMultiImageUnitGI);
var
  Column: TMultiImageColGI;
  Row: TMultiImageRowGI;
begin
  if Item.Column <> nil then
  begin
    Column := Item.Column;
    if Item.PrevInColumn <> nil then
      Item.PrevInColumn.NextInColumn := Item.NextInColumn;
    if Item.NextInColumn <> nil then
      Item.NextInColumn.PrevInColumn := Item.PrevInColumn;
    if Column.Last = Item then
      Column.Last := Item.PrevInColumn;
    if Column.First = Item then
      Column.First := Item.NextInColumn;
    Item.PrevInColumn := nil;
    Item.NextInColumn := nil;
    if Column.Last <> nil then
      Item.Column := nil
    else
    begin
      Row := Item.Column.Row;
      Item.Column := nil;
      if Column.Prev <> nil then
        Column.Prev.Next := Column.Next;
      if Column.Next <> nil then
        Column.Next.Prev := Column.Prev;
      if Row.Last = Column then
        Row.Last := Column.Prev;
      if Row.First = Column then
        Row.First := Column.Next;
      Column.Free;
      if Row.Last = nil then
      begin
        if Row.Prev <> nil then
          Row.Prev.Next := Row.Next;
        if Row.Next <> nil then
          Row.Next.Prev := Row.Prev;
        if LastRow = Row then
          LastRow := Row.Prev;
        if FirstRow = Row then
          FirstRow := Row.Next;
        Row.Free;
      end;
    end;
  end;
end;

procedure TMultiImageGI.ClearSpatialIndex;
var
  Row, OldRow: TMultiImageRowGI;
  Column, OldColumn: TMultiImageColGI;
  Item: TMultiImageUnitGI;
begin
  Row := FirstRow;
  while Row <> nil do
  begin
    OldRow := Row;
    Row := Row.Next;
    Column := OldRow.First;
    while Column <> nil do
    begin
      OldColumn := Column;
      Column := Column.Next;
      OldColumn.Free;
    end;
    OldRow.Free;
  end;
  FirstRow := nil;
  LastRow := nil;
  Item := FirstUnit;
  while Item <> nil do
  begin
    Item.Column := nil;
    Item.PrevInColumn := nil;
    Item.NextInColumn := nil;
    Item := Item.Next;
  end;
end;

function TMultiImageGI.GetOrCreateRow(Index: Integer): TMultiImageRowGI;
var
  Row: TMultiImageRowGI;
begin
  Row := FirstRow;
  while Row <> nil do
  begin
    if Row.Index = Index then
    begin
      Result := Row;
      Exit;
    end;
    if Row.Index > Index then
      Break;
    Row := Row.Next;
  end;
  Result := TMultiImageRowGI.Create;
  Result.Index := Index;
  if Row = nil then
  begin
    if LastRow <> nil then
      LastRow.Next := Result;
    Result.Prev := LastRow;
    Result.Next := nil;
    LastRow := Result;
    if FirstRow = nil then
      FirstRow := Result;
  end
  else
  begin
    Result.Prev := Row.Prev;
    Result.Next := Row;
    if Row.Prev <> nil then
      Row.Prev.Next := Result;
    Row.Prev := Result;
    if FirstRow = Row then
      FirstRow := Result;
  end;
end;

function TMultiImageGI.GetOrCreateColumn(Row: TMultiImageRowGI; Index: Integer): TMultiImageColGI;
var
  Column: TMultiImageColGI;
begin
  Column := Row.First;
  while Column <> nil do
  begin
    if Column.Index = Index then
    begin
      Result := Column;
      Exit;
    end;
    if Column.Index > Index then
      Break;
    Column := Column.Next;
  end;
  Result := TMultiImageColGI.Create;
  Result.Row := Row;
  Result.Index := Index;
  if Column = nil then
  begin
    if Row.Last <> nil then
      Row.Last.Next := Result;
    Result.Prev := Row.Last;
    Result.Next := nil;
    Row.Last := Result;
    if Row.First = nil then
      Row.First := Result;
  end
  else
  begin
    Result.Prev := Column.Prev;
    Result.Next := Column;
    if Column.Prev <> nil then
      Column.Prev.Next := Result;
    Column.Prev := Result;
    if Row.First = Column then
      Row.First := Result;
  end;
end;

procedure TMultiImageGI.SetUnitPosition(Item: TMultiImageUnitGI; Position: TPoint);
var
  Column: TMultiImageColGI;
begin
  // Preserve the native comparison against the control's position.
  if (Item.Column = nil)
      or (Self.LocalPosition.X <> Position.X)
      or (Self.LocalPosition.Y <> Position.Y) then
  begin
    Item.Position := Position;
    Column :=
        GetOrCreateColumn(
            GetOrCreateRow(Position.Y div TMultiImageGI(Self).CellSize),
            Position.X div TMultiImageGI(Self).CellSize
        );
    if Item.Column <> Column then
    begin
      UnlinkUnitFromColumn(Item);
      Item.Column := Column;
      if Column.Last <> nil then
        Column.Last.NextInColumn := Item;
      Item.PrevInColumn := Column.Last;
      Item.NextInColumn := nil;
      Column.Last := TMultiImageUnitGI(Item);
      if Column.First = nil then
        Column.First := TMultiImageUnitGI(Item);
    end;
  end;
end;

procedure TMultiImageGI.ClearImages;
var
  Image: TMultiImageImageGI;
  I: Integer;
begin
  if Images <> nil then
  begin
    for I := 0 to Images.Count - 1 do
    begin
      Image := TMultiImageImageGI(Images[I]);
      Image.Free;
    end;
    Images.Clear;
  end;
end;

function TMultiImageGI.AddImage(Path: WideString): Integer;
var
  Image: TMultiImageImageGI;
begin
  Image := TMultiImageImageGI.Create;
  Image.SetImage(Path);
  Images.Add(Image);
  Result := Images.Count - 1;
end;

procedure TMultiImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TMultiImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;

procedure TMultiImageGI.LoadImageProperties(Block: TBlockParEC);
begin
end;

procedure TMultiImageGI.Invalidate;
var
  MinColumn, MaxColumn, MinRow, MaxRow: Integer;
  Row: TMultiImageRowGI;
  Column: TMultiImageColGI;
  Item: TMultiImageUnitGI;
  Position: TPoint;
  Image: TMultiImageImageGI;
  Bounds: TRect;
begin
  if not MessageLoop.UpdateRectsEnabled then
    Exit;
  if not Active then
    Exit;
  if IntersectRects(Bounds, HitTestBounds, GameScreenRect) then
  begin
    Dec(Bounds.Left, AbsolutePosition.X);
    Dec(Bounds.Top, AbsolutePosition.Y);
    Dec(Bounds.Right, AbsolutePosition.X);
    Dec(Bounds.Bottom, AbsolutePosition.Y);
    MinColumn := Bounds.Left div TMultiImageGI(Self).CellSize - 1;
    MaxColumn := (Bounds.Right - 1) div CellSize + 1;
    MinRow := Bounds.Top div TMultiImageGI(Self).CellSize - 1;
    MaxRow := (Bounds.Bottom - 1) div CellSize + 1;
    Row := FirstRow;
    while Row <> nil do
    begin
      if (Row.Index >= MinRow) and (Row.Index <= MaxRow) then
      begin
        Column := Row.First;
        while Column <> nil do
        begin
          if (Column.Index >= MinColumn) and (Column.Index <= MaxColumn) then
          begin
            Item := Column.First;
            while Item <> nil do
            begin
              Position.X := AbsolutePosition.X + Item.Position.X;
              Position.Y := AbsolutePosition.Y + Item.Position.Y;
              Image := TMultiImageImageGI(TList(Images)[Item.ImageIndex]);
              Bounds.Left := Position.X + 0 + Image.Bounds.Left;
              Bounds.Top := Position.Y + 0 + Image.Bounds.Top;
              Bounds.Right := Position.X + 0 + Image.Bounds.Right;
              Bounds.Bottom := Position.Y + 0 + Image.Bounds.Bottom;
              TMessageLoopGI(MessageLoop).QueueUpdateRect(Bounds);
              Item := Item.NextInColumn;
            end;
          end
          else if Column.Index > MaxColumn then
            Break;
          Column := Column.Next;
        end;
      end
      else if Row.Index > MaxRow then
        Break;
      Row := Row.Next;
    end;
  end;
end;

procedure TMultiImageGI.Draw(ClipRect: TRect);
var
  Row: TMultiImageRowGI;
  Column: TMultiImageColGI;
  Item: TMultiImageUnitGI;
  MinColumn, MaxColumn, MinRow, MaxRow: Integer;
  Position: TPoint;
  Image: TMultiImageImageGI;
  Data: TCGiEC;
  Bounds, Intersection: TRect;
begin
  Bounds.Left := ClipRect.Left - AbsolutePosition.X;
  Bounds.Top := ClipRect.Top - AbsolutePosition.Y;
  Bounds.Right := ClipRect.Right - AbsolutePosition.X;
  Bounds.Bottom := ClipRect.Bottom - AbsolutePosition.Y;
  MinColumn := Bounds.Left div CellSize - 1;
  MaxColumn := (Bounds.Right - 1) div CellSize + 1;
  MinRow := Bounds.Top div CellSize - 1;
  MaxRow := (Bounds.Bottom - 1) div CellSize + 1;
  Row := FirstRow;
  while Row <> nil do
  begin
    if (Row.Index >= MinRow) and (Row.Index <= MaxRow) then
    begin
      Column := Row.First;
      while Column <> nil do
      begin
        if (Column.Index >= MinColumn) and (Column.Index <= MaxColumn) then
        begin
          Item := Column.First;
          while Item <> nil do
          begin
            Position.X := AbsolutePosition.X + Item.Position.X;
            Position.Y := AbsolutePosition.Y + Item.Position.Y;
            Image := TMultiImageImageGI(Images[Item.ImageIndex]);
            Bounds.Left := Image.Bounds.Left + Position.X;
            Bounds.Top := Image.Bounds.Top + Position.Y;
            Bounds.Right := Image.Bounds.Right + Position.X;
            Bounds.Bottom := Image.Bounds.Bottom + Position.Y;
            if IntersectRects(Intersection, Bounds, ClipRect) then
            begin
              Data := AcquireCachedGi(Image.ImageCache);
              try
                if HardwareRenderingEnabled then
                  DrawTexture(
                      Data.GetOrCreateSurface(0),
                      Bounds.Left,
                      Bounds.Top,
                      255,
                      $FFFFFF,
                      @ClipRect,
                      False,
                      False
                  )
                else
                  Data.Image.DrawToGraphBuf(
                      ScreenRenderBuffer,
                      Bounds.Left,
                      Bounds.Top,
                      ClipRect,
                      0,
                      255
                  );
              finally
                Image.ImageCache.Release;
              end;
            end;
            Item := Item.NextInColumn;
          end;
        end
        else if Column.Index > MaxColumn then
          Break;
        Column := Column.Next;
      end;
    end
    else if Row.Index > MaxRow then
      Break;
    Row := Row.Next;
  end;
end;

procedure TMultiImageGI.QueueImageLoad(PendingLoads: TList);
var
  Image: TMultiImageImageGI;
  I: Integer;
begin
  for I := 0 to Images.Count - 1 do
  begin
    Image := TMultiImageImageGI(Images[I]);
    Image.ImageCache.QueueLoadIfMissing(PendingLoads);
  end;
end;

end.
