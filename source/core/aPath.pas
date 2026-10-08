unit aPath;

{$I GameOptions.inc}

interface

uses
  Types,
  GameHeap,
  EC_Struct,
  SyncObjs;

type

  TSPath = class;

  PointerToTSPathNode = ^TSPathNode;

  PSPathNode = PointerToTSPathNode;

  TSPathNode = packed record
    Prev: PSPathNode;
    Next: PSPathNode;
    Position: TPointF;
    Heading: Single;
  end;

  TSPath = class(TObject)
    ActiveHead: PSPathNode;
    ActiveTail: PSPathNode;
    FreeHead: PSPathNode;
    FreeTail: PSPathNode;
    NodeCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure AllocateNodeUnit;
    function PopFreeNode: PSPathNode;
    procedure RemoveNode(Node: PSPathNode);
    procedure RemoveNodeRange(FirstNode: PSPathNode; LastNode: PSPathNode);
    procedure Clear;
    procedure AppendNode;
    procedure AppendWaypoint(Position: TPointF; Heading: Single);
    function InsertNodeBefore(Node: PSPathNode): PSPathNode;
    function GetFollowingNode(Node: PSPathNode; SkipCount: Integer): PSPathNode;
    function FindNearestFollowingNode(Node: PSPathNode; Position: TPointF): PSPathNode;
    function GetLength: Single;
    function CountNodeRangeInclusive(FirstNode: PSPathNode; LastNode: PSPathNode): Integer;
    procedure ResampleBezierRange(
        FirstNode: PSPathNode;
        LastNode: PSPathNode;
        SampleCount: Integer
    );
  end;

var

  PathNodeHeap: TGameHeapHandle = 0;

  PathPoolHead: PSPathNode = nil;

  PathPoolTail: PSPathNode = nil;

  PathPoolLock: TCriticalSection = nil;

  PathGrowthBlockCount: Integer = -1;

procedure InitializePathNodePool;

procedure EnsurePathGrowthBlockSlot;

procedure FreePathGrowthBlocks;

function ReservePathGrowthBlock: Boolean;

function GrowPathNodePool: Boolean;

procedure FinalizePathNodePool;

implementation

uses
  aBezierPC24,
  aMyFunction,
  EC_Mem,
  GR_Main,
  SysUtils;

var
  PathInitialBlock: Pointer;
  PathPoolFreeCount: Integer;
  PathGrowthBlocks: array of Pointer;

procedure InitializePathNodePool;
var
  Index: Integer;
  Node, Prev: PSPathNode;
begin
  PathPoolLock := TCriticalSection.Create;
  PathPoolFreeCount := 200000;
  PathNodeHeap := GameHeap.HeapCreate(0, 16, 0);
  PathInitialBlock := GameHeap.HeapAlloc(PathNodeHeap, 0, PathPoolFreeCount * SizeOf(TSPathNode));
  if PathInitialBlock = nil then
    raise Exception.Create('Error: HeapAlloc');
  System.FillChar(Pointer(PathInitialBlock)^, PathPoolFreeCount * SizeOf(TSPathNode), 0);
  Node := PathInitialBlock;
  PathPoolHead := Node;
  Prev := nil;
  for Index := 0 to PathPoolFreeCount - 1 do
  begin
    Node.Prev := Prev;
    Node.Next := AddPointerOffset(Node, SizeOf(TSPathNode));
    Prev := Node;
    Node := AddPointerOffset(Node, SizeOf(TSPathNode));
  end;
  PathPoolTail := Prev;
  PathPoolTail.Next := nil;
end;

procedure EnsurePathGrowthBlockSlot;
var
  Count: Integer;
begin
  Count := Length(PathGrowthBlocks);
  if PathGrowthBlockCount >= Count then
  begin
    SetLength(PathGrowthBlocks, Count + 1);
    PathGrowthBlocks[Count] := nil;
  end;
end;

procedure FreePathGrowthBlocks;
var
  Index: Integer;
begin
  for Index := 0 to High(PathGrowthBlocks) do
    if PathGrowthBlocks[Index] <> nil then
    begin
      GameHeap.HeapFree(PathNodeHeap, 0, PathGrowthBlocks[Index]);
      PathGrowthBlocks[Index] := nil;
    end;
  SetLength(PathGrowthBlocks, 0);
  PathGrowthBlockCount := 0;
end;

function ReservePathGrowthBlock: Boolean;
begin
  Result := False;
  if PathGrowEnabled then
  begin
    Inc(PathGrowthBlockCount);
    EnsurePathGrowthBlockSlot;
    Result := True;
  end;
end;

function GrowPathNodePool: Boolean;
var
  Index, Count, ByteCount: Integer;
  Node, Prev: PSPathNode;
  Block: Pointer;
begin
  Result := False;
  if PathPoolTail = nil then
    Exit;
  if not ReservePathGrowthBlock then
    Exit;
  Count := 100000;
  Inc(PathPoolFreeCount, Count);
  ByteCount := Count * SizeOf(TSPathNode);
  Block := GameHeap.HeapAlloc(PathNodeHeap, GameHeap.HEAP_ZERO_MEMORY, ByteCount);
  if Block = nil then
    Exit;
  Node := Block;
  PathPoolTail.Next := Node;
  Prev := PathPoolTail;
  for Index := 0 to Count - 1 do
  begin
    Node.Prev := Prev;
    Node.Next := AddPointerOffset(Node, SizeOf(TSPathNode));
    Prev := Node;
    Node := AddPointerOffset(Node, SizeOf(TSPathNode));
  end;
  PathPoolTail := Prev;
  PathPoolTail.Next := nil;
  Result := True;
end;

procedure FinalizePathNodePool;
begin
  FreePathGrowthBlocks;
  if PathInitialBlock <> nil then
  begin
    GameHeap.HeapFree(PathNodeHeap, 0, PathInitialBlock);
    PathInitialBlock := nil;
  end;
  if PathNodeHeap <> 0 then
  begin
    GameHeap.HeapDestroy(PathNodeHeap);
    PathNodeHeap := 0;
  end;
  if PathPoolLock <> nil then
  begin
    PathPoolLock.Free;
    PathPoolLock := nil;
  end;
end;

constructor TSPath.Create;
begin
  inherited Create;
  AllocateNodeUnit;
end;

destructor TSPath.Destroy;
begin
  Clear;
  PathPoolLock.Enter;
  Inc(PathPoolFreeCount, CountNodeRangeInclusive(FreeHead, FreeTail));
  if PathPoolTail <> nil then
    PathPoolTail.Next := FreeHead;
  FreeHead.Prev := PathPoolTail;
  FreeTail.Next := nil;
  PathPoolTail := FreeTail;
  if PathPoolHead = nil then
    PathPoolHead := FreeHead;
  PathPoolLock.Leave;
  FreeHead := nil;
  FreeTail := nil;
  NodeCount := 0;
  inherited Destroy;
end;

procedure TSPath.AllocateNodeUnit;
var
  Index: Integer;
  First, Last: PSPathNode;
  Count: Integer;
begin
  Count := 24;
  PathPoolLock.Enter;
  if Count >= PathPoolFreeCount then
    if not GrowPathNodePool then
    begin
      PathPoolLock.Leave;
      raise Exception.Create('Error: Path.AllocUnit  UnitCount=' + IntToStr(Count));
    end;
  First := PathPoolHead;
  Last := PathPoolHead;
  for Index := 1 to Count - 1 do
    Last := Last.Next;
  PathPoolHead := Last.Next;
  PathPoolHead.Prev := nil;
  Dec(PathPoolFreeCount, Count);
  PathPoolLock.Leave;
  if FreeTail <> nil then
    FreeTail.Next := First;
  First.Prev := FreeTail;
  Last.Next := nil;
  FreeTail := Last;
  if FreeHead = nil then
    FreeHead := First;
end;

function TSPath.PopFreeNode: PSPathNode;
var
  Node: PSPathNode;
begin
  if (FreeHead = FreeTail) or (FreeHead = nil) then
    AllocateNodeUnit;
  Node := FreeHead;
  Node.Next.Prev := nil;
  FreeHead := Node.Next;
  Inc(NodeCount);
  Result := Node;
end;

procedure TSPath.RemoveNode(Node: PSPathNode);
begin
  if Node.Prev <> nil then
    Node.Prev.Next := Node.Next;
  if Node.Next <> nil then
    Node.Next.Prev := Node.Prev;
  if ActiveTail = Node then
    ActiveTail := Node.Prev;
  if ActiveHead = Node then
    ActiveHead := Node.Next;
  if FreeTail <> nil then
    FreeTail.Next := Node;
  Node.Prev := FreeTail;
  Node.Next := nil;
  FreeTail := Node;
  if FreeHead = nil then
    FreeHead := Node;
  Dec(NodeCount);
end;

procedure TSPath.RemoveNodeRange(FirstNode, LastNode: PSPathNode);
begin
  Dec(NodeCount, CountNodeRangeInclusive(FirstNode, LastNode));
  if FirstNode.Prev <> nil then
    FirstNode.Prev.Next := LastNode.Next;
  if LastNode.Next <> nil then
    LastNode.Next.Prev := FirstNode.Prev;
  if LastNode = ActiveTail then
    ActiveTail := FirstNode.Prev;
  if FirstNode = ActiveHead then
    ActiveHead := LastNode.Next;
  if FreeTail <> nil then
    FreeTail.Next := FirstNode;
  FirstNode.Prev := FreeTail;
  LastNode.Next := nil;
  FreeTail := LastNode;
  if FreeHead = nil then
    FreeHead := FirstNode;
end;

procedure TSPath.Clear;
begin
  if ActiveHead <> nil then
    RemoveNodeRange(ActiveHead, ActiveTail);
end;

procedure TSPath.AppendNode;
var
  Node: PSPathNode;
begin
  Node := PopFreeNode;
  if ActiveTail <> nil then
    ActiveTail.Next := Node;
  Node.Prev := ActiveTail;
  Node.Next := nil;
  ActiveTail := Node;
  if ActiveHead = nil then
    ActiveHead := Node;
end;

procedure TSPath.AppendWaypoint(Position: TPointF; Heading: Single);
var
  Node: PSPathNode;
begin
  Node := PopFreeNode;
  if ActiveTail <> nil then
    ActiveTail.Next := Node;
  Node.Prev := ActiveTail;
  Node.Next := nil;
  ActiveTail := Node;
  if ActiveHead = nil then
    ActiveHead := Node;
  Node.Position := Position;
  Node.Heading := Heading;
end;

function TSPath.InsertNodeBefore(Node: PSPathNode): PSPathNode;
var
  NewNode: PSPathNode;
begin
  if Node = nil then
  begin
    AppendNode;
    Result := ActiveTail;
  end
  else
  begin
    NewNode := PopFreeNode;
    NewNode.Prev := Node.Prev;
    NewNode.Next := Node;
    if Node.Prev <> nil then
      Node.Prev.Next := NewNode;
    Node.Prev := NewNode;
    if Node = ActiveHead then
      ActiveHead := NewNode;
    Result := NewNode;
  end;
end;

function TSPath.GetFollowingNode(Node: PSPathNode; SkipCount: Integer): PSPathNode;
begin
  Node := Node.Next;
  while Node <> nil do
  begin
    if SkipCount <= 0 then
    begin
      Result := Node;
      Exit;
    end;
    Dec(SkipCount);
    Node := Node.Next;
  end;
  Result := nil;
end;

function TSPath.FindNearestFollowingNode(Node: PSPathNode; Position: TPointF): PSPathNode;
var
  BestDistance, Distance: Single;
begin
  Result := nil;
  BestDistance := 1.0e20;
  Node := Node.Next;
  while Node <> nil do
  begin
    Distance := PointDistanceSquared(Node.Position, Position);
    if Distance < BestDistance then
    begin
      Result := Node;
      BestDistance := Distance;
    end;
    Node := Node.Next;
  end;
end;

function TSPath.GetLength: Single;
var
  Node: PSPathNode;
begin
  Result := 0;
  if ActiveHead = nil then
    Exit;
  Node := ActiveHead.Next;
  while Node <> nil do
  begin
    Result := Result + PointDistance(Node.Position, Node.Prev.Position);
    Node := Node.Next;
  end;
end;

function TSPath.CountNodeRangeInclusive(FirstNode, LastNode: PSPathNode): Integer;
var
  Count: Integer;
  Node: PSPathNode;
begin
  if (FirstNode = nil) or (LastNode = nil) then
  begin
    Result := 0;
    Exit;
  end;
  Count := 1;
  Node := FirstNode;
  while (Node <> nil) and (Node <> LastNode) do
  begin
    Inc(Count);
    Node := Node.Next;
  end;
  if Node = nil then
    Result := 0
  else
    Result := Count;
end;

procedure TSPath.ResampleBezierRange(FirstNode, LastNode: PSPathNode; SampleCount: Integer);
var
  Coefficients: array of TBezierPC24Wide;
  TPower, InvRemaining, RemainingPower, Weight, TWide: TBezierPC24Wide;
  T, Step, Heading: Single;
  X, Y, Angle: Double;
  Count: Integer;
  Node, NewNode, AfterNode: PSPathNode;
  Index, Sample: Integer;
begin
  Count := CountNodeRangeInclusive(FirstNode, LastNode);
  if Count < 2 then
    Exit;
  if SampleCount < 2 then
    Exit;
  AfterNode := LastNode.Next;
  SetLength(Coefficients, Count);
  Coefficients[0] := BezierWide(1);
  Coefficients[Count - 1] := BezierWide(1);
  for Index := 1 to (Count - 1) div 2 do
  begin
    Coefficients[Index] :=
        BezierDiv(BezierMul(BezierWide(Count - Index), Coefficients[Index - 1]), BezierWide(Index));
    Coefficients[Count - 1 - Index] := Coefficients[Index];
  end;
  Heading := FirstNode.Heading;
  Node := LastNode;
  while Node <> FirstNode do
  begin
    Node.Heading := HeadingDifferenceDegrees(Node.Prev.Heading, Node.Heading);
    Node := Node.Prev;
  end;
  FirstNode.Heading := 0;
  Node := FirstNode;
  while Node <> LastNode do
  begin
    Heading := Heading + Node.Heading;
    Node.Heading := Heading;
    Node := Node.Next;
  end;
  Heading := Heading + LastNode.Heading;
  LastNode.Heading := Heading;
  T := 0;
  Step := 1 / (SampleCount - 1);
  for Sample := 0 to SampleCount - 1 do
  begin
    X := 0;
    Y := 0;
    Angle := 0;
    { Preserve the original forward accumulation. The normalized factors
      retain the x87 exponent range even when the initial tail is < 2^-1074. }
    Node := FirstNode;
    Index := 0;
    TPower := BezierWide(1);
    InvRemaining := BezierDiv(BezierWide(1), BezierWide(1 - T));
    RemainingPower := BezierPower(BezierWide(1 - T), Count - 1);
    TWide := BezierWide(T);
    while Node <> LastNode do
    begin
      Weight := BezierMul(BezierMul(TPower, Coefficients[Index]), RemainingPower);
      X := BezierAddProduct(X, Weight, Node.Position.X);
      Y := BezierAddProduct(Y, Weight, Node.Position.Y);
      Angle := BezierAddProduct(Angle, Weight, Node.Heading);
      Inc(Index);
      TPower := BezierMul(TPower, TWide);
      RemainingPower := BezierMul(RemainingPower, InvRemaining);
      Node := Node.Next;
    end;
    Weight := BezierMul(TPower, Coefficients[Index]);
    X := BezierAddProduct(X, Weight, Node.Position.X);
    Y := BezierAddProduct(Y, Weight, Node.Position.Y);
    Angle := BezierAddProduct(Angle, Weight, Node.Heading);
    NewNode := InsertNodeBefore(AfterNode);
    NewNode.Position.X := X;
    NewNode.Position.Y := Y;
    NewNode.Heading := WrapHeadingDegrees(Angle);
    T := T + Step;
  end;
  if AfterNode = nil then
    NewNode := ActiveTail
  else
    NewNode := AfterNode.Prev;
  NewNode.Position := LastNode.Position;
  NewNode.Heading := LastNode.Heading;
  RemoveNodeRange(FirstNode, LastNode);
  Coefficients := nil;
end;

end.
