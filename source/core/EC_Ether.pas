{$EXCESSPRECISION OFF}
unit EC_Ether;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  EC_Buf,
  SyncObjs;
type
  TEther = class;
  TEtherUnit = class;
  PointerToTEtherIndex = ^TEtherIndex;
  TEtherUnit = class(TObject)
    Prev: TEtherUnit;
    Next: TEtherUnit;
    Value: Integer;
    Name: WideString;
  end;
  PEtherIndex = PointerToTEtherIndex;
  TEtherIndex = array[0..536870910] of TEtherUnit;
  TEther = class(TObjectEx)
    First: TEtherUnit;
    Last: TEtherUnit;
    Count: Integer;
    SortedItems: PEtherIndex;
    Lock: TCriticalSection;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AppendEntry: TEtherUnit;
    procedure RemoveEntry(Item: TEtherUnit);
    function GetIndexedEntry(Index: Integer): TEtherUnit;
    procedure SetIndexedEntry(Index: Integer; Item: TEtherUnit);
    function FindInsertionIndex(const Name: WideString): Integer;
    procedure Add(const Name: WideString; Value: Integer);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure Enter;
    procedure Leave;
  end;
implementation
uses
  Math,
  EC_Mem,
  EC_Str;

constructor TEther.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
end;

destructor TEther.Destroy;
begin
  // The Win32 destructor unlocks an unowned critical section. POSIX rejects
  // that operation; dispose this instance's entries and owned lock instead.
  Clear;
  Lock.Free;
  Lock := nil;
  inherited Destroy;
end;

procedure TEther.Clear;
begin
  while First <> nil do
    RemoveEntry(Last);
  if SortedItems <> nil then
  begin
    FreeEC(SortedItems);
    SortedItems := nil;
  end;
  Count := 0;
end;

function TEther.AppendEntry: TEtherUnit;
var
  Item: TEtherUnit;
begin
  Item := TEtherUnit.Create;
  if Last <> nil then
    Last.Next := Item;
  Item.Prev := Last;
  Item.Next := nil;
  Last := Item;
  if First = nil then
    First := Item;
  Result := Item;
end;

procedure TEther.RemoveEntry(Item: TEtherUnit);
begin
  if Item.Prev <> nil then
    Item.Prev.Next := Item.Next;
  if Item.Next <> nil then
    Item.Next.Prev := Item.Prev;
  if Last = Item then
    Last := Item.Prev;
  if First = Item then
    First := Item.Next;
  Item.Free;
end;

function TEther.GetIndexedEntry(Index: Integer): TEtherUnit;
begin
  Result := SortedItems^[Index];
end;

procedure TEther.SetIndexedEntry(Index: Integer; Item: TEtherUnit);
begin
  SortedItems^[Index] := Item;
end;

function TEther.FindInsertionIndex(const Name: WideString): Integer;
var
  Left, Right, Middle, Comparison: Integer;
  Item: TEtherUnit;
begin
  if Count <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  Left := 0;
  Right := Count - 1;
  repeat
    Middle := ((Right - Left) shr 1) + Left;
    Item := GetIndexedEntry(Middle);
    Comparison := CompareWideChars(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := Middle;
      Exit;
    end;
    if Comparison < 0 then
      Right := Middle - 1
    else
      Left := Middle + 1;
  until Right < Left;
  if Comparison < 0 then
    Result := Middle
  else
    Result := Middle + 1;
end;

procedure TEther.Add(const Name: WideString; Value: Integer);
var
  MoveCount: Integer;
  Item: TEtherUnit;
  Index: Integer;
begin
  Enter;
  Item := AppendEntry;
  Item.Name := Name;
  Item.Value := Value;
  Index := FindInsertionIndex(Name);
  Inc(Count);
  SortedItems := ReAllocREC(SortedItems, Count * SizeOf(TEtherUnit));
  MoveCount := Count - 1 - Index;
  if MoveCount > 0 then
    Move(SortedItems^[Index], SortedItems^[Index + 1], MoveCount * SizeOf(TEtherUnit));
  SetIndexedEntry(Index, Item);
  Leave;
end;

procedure TEther.SaveToBuffer(Buffer: TBufEC);
var
  Item: TEtherUnit;
begin
  Buffer.AddIntegerValue(Count);
  Item := First;
  while Item <> nil do
  begin
    Buffer.AddWideStringZ(Item.Name);
    Buffer.AddIntegerValue(Item.Value);
    Item := Item.Next;
  end;
end;

procedure TEther.LoadFromBuffer(Buffer: TBufEC);
var
  Name: WideString;
  Index, ItemCount, Value: Integer;
begin
  Clear;
  ItemCount := Buffer.GetInt32;
  for Index := 0 to ItemCount - 1 do
  begin
    Name := Buffer.ReadWideString;
    Value := Buffer.GetInt32;
    Add(Name, Value);
  end;
end;

procedure TEther.Enter;
begin
  Lock.Enter;
end;

procedure TEther.Leave;
begin
  Lock.Leave;
end;

end.
