{$EXCESSPRECISION OFF}
unit GR_Rect;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  Types;
type
  TArrayRectGR = class;
  TRectGR = class;
  TRectGR = class(TObject)
    Prev: TRectGR;
    Next: TRectGR;
    Bounds: TRect;
    constructor Create;
    destructor Destroy; override;
  end;
  TArrayRectGR = class(TObjectEx)
    FirstRect: TRectGR;
    LastRect: TRectGR;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AllocateRectNode: TRectGR;
    procedure RemoveRectNode(RectNode: TRectGR);
    procedure AddRect(Rect: TRect);
    procedure InsertRectFragment(Left: Integer; Top: Integer; Right: Integer; Bottom: Integer);
    procedure AddScreenClippedRect(Rect: TRect; UnusedPoint1: TPoint; UnusedPoint2: TPoint);
  end;
implementation
uses
  Math,
  GR_Main;

constructor TRectGR.Create;
begin
  inherited Create;
end;

destructor TRectGR.Destroy;
begin
  inherited Destroy;
end;

constructor TArrayRectGR.Create;
begin
  inherited Create;
end;

destructor TArrayRectGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TArrayRectGR.Clear;
var
  Node, Removed: TRectGR;
begin
  Node := FirstRect;
  while Node <> nil do
  begin
    Removed := Node;
    Node := Node.Next;
    Removed.Free;
  end;
  FirstRect := nil;
  LastRect := nil;
end;

function TArrayRectGR.AllocateRectNode: TRectGR;
var
  Node: TRectGR;
begin
  Node := TRectGR.Create;
  if LastRect <> nil then
    LastRect.Next := Node;
  Node.Prev := LastRect;
  Node.Next := nil;
  LastRect := Node;
  if FirstRect = nil then
    FirstRect := Node;
  Result := Node;
end;

procedure TArrayRectGR.RemoveRectNode(RectNode: TRectGR);
begin
  if RectNode.Prev <> nil then
    RectNode.Prev.Next := RectNode.Next;
  if RectNode.Next <> nil then
    RectNode.Next.Prev := RectNode.Prev;
  if LastRect = RectNode then
    LastRect := RectNode.Prev;
  if FirstRect = RectNode then
    FirstRect := RectNode.Next;
  RectNode.Free;
end;

procedure TArrayRectGR.AddRect(Rect: TRect);
var
  Node, Removed: TRectGR;
begin
  Node := LastRect;
  while Node <> nil do
  begin
    with Node.Bounds do
      if (Rect.Left >= Left)
          and (Rect.Right <= Right)
          and (Rect.Top >= Top)
          and (Rect.Bottom <= Bottom) then
        Exit;
    Node := Node.Prev;
  end;
  Node := LastRect;
  while Node <> nil do
  begin
    with Node.Bounds do
      if (Left >= Rect.Left)
          and (Right <= Rect.Right)
          and (Top >= Rect.Top)
          and (Bottom <= Rect.Bottom) then
      begin
        Removed := Node;
        Node := Node.Prev;
        RemoveRectNode(Removed);
      end
      else
        Node := Node.Prev;
  end;
  InsertRectFragment(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
end;

procedure TArrayRectGR.InsertRectFragment(Left, Top, Right, Bottom: Integer);
var
  Node: TRectGR;
  OutsideEdges: Integer;
  ExistingLeft, ExistingTop, ExistingRight, ExistingBottom: Integer;
begin
  Node := LastRect;
  while Node <> nil do
  begin
    ExistingLeft := Node.Bounds.Left;
    ExistingRight := Node.Bounds.Right;
    ExistingTop := Node.Bounds.Top;
    ExistingBottom := Node.Bounds.Bottom;
    if (Left >= ExistingLeft)
        and (Right <= ExistingRight)
        and (Top >= ExistingTop)
        and (Bottom <= ExistingBottom) then
      Exit;
    if (Left < ExistingRight)
        and (Right > ExistingLeft)
        and (Top < ExistingBottom)
        and (Bottom > ExistingTop) then
      Break;
    Node := Node.Prev;
  end;
  if Node = nil then
  begin
    Node := AllocateRectNode;
    Node.Bounds.Left := Left;
    Node.Bounds.Top := Top;
    Node.Bounds.Right := Right;
    Node.Bounds.Bottom := Bottom;
    Exit;
  end;
  OutsideEdges := 0;
  if Left < ExistingLeft then
    OutsideEdges := OutsideEdges or 1;
  if Right > ExistingRight then
    OutsideEdges := OutsideEdges or 8;
  if Top < ExistingTop then
    OutsideEdges := OutsideEdges or 16;
  if Bottom > ExistingBottom then
    OutsideEdges := OutsideEdges or 128;
  if (OutsideEdges = 1) then
  begin
    InsertRectFragment(Left, Top, ExistingLeft, Bottom);
  end
  else if (OutsideEdges = 8) then
  begin
    InsertRectFragment(ExistingRight, Top, Right, Bottom);
  end
  else if (OutsideEdges = 16) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
  end
  else if (OutsideEdges = 128) then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if (OutsideEdges = 9) then
  begin
    InsertRectFragment(Left, Top, ExistingLeft, Bottom);
    InsertRectFragment(ExistingRight, Top, Right, Bottom);
  end
  else if (OutsideEdges = 144) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if (OutsideEdges = 17) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, Bottom);
  end
  else if (OutsideEdges = 24) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(ExistingRight, ExistingTop, Right, Bottom);
  end
  else if (OutsideEdges = 129) then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(Left, Top, ExistingLeft, ExistingBottom);
  end
  else if (OutsideEdges = 136) then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(ExistingRight, Top, Right, ExistingBottom);
  end
  else if (OutsideEdges = 145) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, ExistingBottom);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if (OutsideEdges = 152) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(ExistingRight, ExistingTop, Right, ExistingBottom);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if (OutsideEdges = 25) then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, Bottom);
    InsertRectFragment(ExistingRight, ExistingTop, Right, Bottom);
  end
  else if (OutsideEdges = 137) then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(Left, Top, ExistingLeft, ExistingBottom);
    InsertRectFragment(ExistingRight, Top, Right, ExistingBottom);
  end;
end;

procedure TArrayRectGR.AddScreenClippedRect(Rect: TRect; UnusedPoint1, UnusedPoint2: TPoint);
var
  Clipped: TRect;
begin
  if IntersectRects(Clipped, Rect, GameScreenRect) then
    AddRect(Clipped);
end;

end.
