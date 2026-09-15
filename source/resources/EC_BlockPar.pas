{$EXCESSPRECISION OFF}
unit EC_BlockPar;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct;
type
  TBlockParEC = class;
  TBlockParElEC = class;
  {$Z4}
  TBlockParKind = (bpkText = 0, bpkString = 1, bpkBlock = 2);
  TBlockParElEC = class(TObjectEx)
    Prev: TBlockParElEC;
    Next: TBlockParElEC;
    OwnerBlock: TBlockParEC;
    ItemType: TBlockParKind;
    Name: WideString;
    StringValue: WideString;
    Comment: WideString;
    ChildBlock: TBlockParEC;
    GroupIndex: Integer;
    GroupCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure MakeChildBlock;
    procedure CopyFrom(Source: TBlockParElEC);
  end;
  TBlockParEC = class(TObjectEx)
    FirstEntry: TBlockParElEC;
    LastEntry: TBlockParElEC;
    EntryCount: Integer;
    StringParamCount: Integer;
    ChildBlockCount: Integer;
    UseSortedIndex: Boolean;
    Gap19: array[0..2] of Byte;
    SortedEntries: array of TBlockParElEC;
    SortedEntryCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure CopyFrom(Source: TBlockParEC);
    function AddEntry: TBlockParElEC;
    procedure DeleteEntry(Entry: TBlockParElEC);
    function FindEntryByPath(const Path: WideString; RaiseIfMissing: Boolean): TBlockParElEC;
    function FindSortedNameRangeStartIndex(const EntryName: WideString): Integer;
    function PrepareSortedInsertion(Entry: TBlockParElEC): Integer;
    procedure InsertIntoSortedIndex(Entry: TBlockParElEC);
    procedure RemoveFromSortedIndex(Entry: TBlockParElEC);
    function GetParamByPath(const Path: WideString): WideString;
    function GetParamByPathOrMarker(const Path: WideString): WideString;
    function CountParamsByPath(const Path: WideString): Integer;
    function AddParam(const ParamName: WideString; const ParamValue: WideString): TBlockParElEC;
    procedure SetParam(const ParamName: WideString; const ParamValue: WideString);
    procedure SetOrAddParam(const ParamName: WideString; const ParamValue: WideString);
    procedure DeleteParam(const ParamName: WideString);
    procedure DeleteChildBlock(const BlockName: WideString);
    function GetParam(const ParamName: WideString): WideString;
    function GetParamOrMarker(const ParamName: WideString): WideString;
    function GetParamCount: Integer;
    function CountParams(const ParamName: WideString): Integer;
    function GetParamValue(Index: Integer): WideString;
    function GetParamName(Index: Integer): WideString;
    function AddBlockByPath(const Path: WideString): TBlockParEC;
    function GetBlockByPath(const Path: WideString): TBlockParEC;
    function FindBlockByPath(const Path: WideString): TBlockParEC;
    function GetOrAddBlockByPath(const Path: WideString): TBlockParEC;
    function AddChildBlock(const BlockName: WideString): TBlockParEC;
    function GetBlock(const BlockName: WideString): TBlockParEC;
    function FindBlock(const BlockName: WideString): TBlockParEC;
    function GetBlockCount: Integer;
    function CountBlocks(const BlockName: WideString): Integer;
    function GetBlockByIndex(Index: Integer): TBlockParEC;
    function GetBlockNameByIndex(Index: Integer): WideString;
    function GetEntryCount: Integer;
    function GetEntryKindByIndex(Index: Integer): TBlockParKind;
    function GetEntryBlockByIndex(Index: Integer): TBlockParEC;
    function GetEntryStringByIndex(Index: Integer): WideString;
    function GetEntryNameByIndex(Index: Integer): WideString;
    procedure WriteWideText(Dest: TBufEC; Indent: Integer; Sorted: Boolean);
    procedure WriteAnsiText(Dest: TBufEC; Indent: Integer; Sorted: Boolean);
    procedure WriteTextBuffer(Dest: TBufEC; AnsiText: Boolean; Sorted: Boolean);
    procedure SaveTextFile(FileName: PWideChar; AnsiText: Boolean; Sorted: Boolean);
    procedure ParseTextBuffer(
        Buf: TBufEC;
        const InitialText: WideString;
        AnsiText: Boolean;
        PreserveComments: Boolean
    );
    procedure LoadFromTextBufferWithEncodingProbe(Buf: TBufEC; PreserveComments: Boolean);
    procedure LoadFromTextFileWithEncodingProbe(FileName: PWideChar; PreserveComments: Boolean);
    procedure MergeFrom(Source: TBlockParEC);
    function ConcatenateValues: WideString;
    procedure LoadFromDecodedBuffer(Buf: TBufEC);
    procedure LoadFromEncryptedDatFile(const FileName: WideString);
  end;
const
  BlockDatSeedKey: Cardinal = $B1E8C689;
  BlockDatCrcKey1: Cardinal = $7DB6C99D;
  BlockDatCrcKey2: Cardinal = $C83FCBF3;
implementation
uses
  Math,
  EC_File,
  aMyFunction,
  BlockParException,
  GR_Main,
  EC_Str,
  GlobalsV,
  SysUtils,
  Windows;

constructor TBlockParElEC.Create;
begin
  inherited Create
end;

destructor TBlockParElEC.Destroy;
begin
  Clear;
  inherited Destroy
end;

procedure TBlockParElEC.Clear;
begin
  if ChildBlock <> nil then
  begin
    ChildBlock.Free;
    ChildBlock := nil
  end;
  ItemType := bpkText;
  Name := '';
  StringValue := '';
  Comment := '';
end;

procedure TBlockParElEC.MakeChildBlock;
begin
  if ChildBlock <> nil then
  begin
    ChildBlock.Free;
    ChildBlock := nil
  end;
  ChildBlock := TBlockParEC.Create;
  ItemType := bpkBlock;
  StringValue := '';
end;

procedure TBlockParElEC.CopyFrom(Source: TBlockParElEC);
begin
  Clear;
  ItemType := Source.ItemType;
  Name := Source.Name;
  StringValue := Source.StringValue;
  Comment := Source.Comment;
  ChildBlock := nil;
  if Source.ChildBlock <> nil then
  begin
    ChildBlock := TBlockParEC.Create;
    ChildBlock.CopyFrom(Source.ChildBlock);
  end;
end;

constructor TBlockParEC.Create;
begin
  inherited Create;
  UseSortedIndex := True
end;

destructor TBlockParEC.Destroy;
begin
  Clear;
  inherited Destroy
end;

procedure TBlockParEC.Clear;
var
  Entry, Removed: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    Removed := Entry;
    Entry := Entry.Next;
    Removed.Free;
  end;
  FirstEntry := nil;
  LastEntry := nil;
  EntryCount := 0;
  StringParamCount := 0;
  ChildBlockCount := 0;
  SortedEntries := nil;
  SortedEntryCount := 0;
end;

procedure TBlockParEC.CopyFrom(Source: TBlockParEC);
var
  Entry, Added: TBlockParElEC;
begin
  Clear;
  UseSortedIndex := Source.UseSortedIndex;
  Entry := Source.FirstEntry;
  while Entry <> nil do
  begin
    Added := AddEntry;
    Added.CopyFrom(Entry);
    if UseSortedIndex then
      InsertIntoSortedIndex(Added);
    if Entry.ItemType = bpkString then
      Inc(StringParamCount)
    else if Entry.ItemType = bpkBlock then
      Inc(ChildBlockCount);
    Entry := Entry.Next;
  end;
end;

function TBlockParEC.AddEntry: TBlockParElEC;
var
  Entry: TBlockParElEC;
begin
  Entry := TBlockParElEC.Create;
  Entry.OwnerBlock := Self;
  if LastEntry <> nil then
    LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then
    FirstEntry := Entry;
  Inc(EntryCount);
  Result := Entry;
end;

procedure TBlockParEC.DeleteEntry(Entry: TBlockParElEC);
begin
  if Entry.Prev <> nil then
    Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then
    LastEntry := Entry.Prev;
  if FirstEntry = Entry then
    FirstEntry := Entry.Next;
  Dec(EntryCount);
  if Entry.ItemType = bpkString then
    Dec(StringParamCount)
  else if Entry.ItemType = bpkBlock then
    Dec(ChildBlockCount);
  Entry.Free;
end;

function TBlockParEC.FindEntryByPath(
    const Path: WideString;
    RaiseIfMissing: Boolean
): TBlockParElEC;
var
  Cursor, PathLength, Start, PartLength, Occurrence: Integer;
  Index, Seen: Integer;
  Entry: TBlockParElEC;
  Block: TBlockParEC;
  function NextBlockPathComponent: Boolean; // @addr 0x846BE0 @ida "bool __cdecl $name(void *ParentFrame);" @note "Nested helper of TBlockParEC.FindEntryByPath."
  var
    Ch: WideChar;
    i: Integer;
  begin
    if Cursor >= PathLength then
    begin
      Result := False;
      Exit
    end;
    Start := Cursor;
    i := Start;
    while PathLength > i do
    begin
      Ch := Path[i + 1];
      if (Ch = '.') or (Ch = '/') or (Ch = '\') then
        Break;
      Inc(i);
    end;
    PartLength := i - Start;
    Cursor := i + 1;
    Result := True;
  end;
  procedure ParseBlockPathOccurrence; // @addr 0x846C74 @ida "void __cdecl $name(void *ParentFrame);" @note "Nested helper of TBlockParEC.FindEntryByPath."
  var
    i, Limit: Integer;
    Ch: WideChar;
  begin
    Occurrence := 0;
    i := Start;
    Limit := Start + PartLength;
    while i < Limit do
    begin
      if Path[i + 1] = ':' then
      begin
        PartLength := i - Start;
        Inc(i);
        while i < Limit do
        begin
          Ch := Path[i + 1];
          if (Ch >= '0') and (Ch <= '9') then
            Occurrence := Occurrence * 10 + (Ord(Ch) - Ord('0'));
          Inc(i);
        end;
        Break;
      end;
      Inc(i);
    end;
  end;
  function MatchBlockPathComponent(
      Name: WideString
  ): Boolean; // @addr 0x846D24 @ida "bool __usercall $name@<al>(unsigned __int16 *Name@<eax>, void *ParentFrame);" @note "Nested helper of TBlockParEC.FindEntryByPath; native clones its value parameter."
  begin
    if Length(Name) <> PartLength then
      Result := False
    else
      Result :=
          SysUtils.CompareMem(
              Pointer(PtrUInt(PWideChar(Path)) + Start * 2),
              PWideChar(Name),
              PartLength * 2
          );
  end;
begin
  PathLength := Length(Path);
  Cursor := 0;
  Block := Self;
  Entry := nil;
  while NextBlockPathComponent do
  begin
    ParseBlockPathOccurrence;
    if Block.UseSortedIndex then
    begin
      Entry := nil;
      Index := Block.FindSortedNameRangeStartIndex(Copy(Path, Start + 1, PartLength));
      if Index >= 0 then
      begin
        Entry := Block.SortedEntries[Index];
        if Occurrence <> 0 then
        begin
          if Occurrence < Entry.GroupCount then
            Entry := Block.SortedEntries[Index + Occurrence]
          else
            Entry := nil;
        end;
      end;
    end
    else
    begin
      Entry := Block.FirstEntry;
      Seen := 0;
      while (Seen <= Occurrence) and (Entry <> nil) do
      begin
        while Entry <> nil do
        begin
          if MatchBlockPathComponent(Entry.Name) then
          begin
            if Seen < Occurrence then
              Entry := Entry.Next;
            Break;
          end;
          Entry := Entry.Next;
        end;
        Inc(Seen);
      end;
    end;
    if Entry = nil then
    begin
      if RaiseIfMissing then
        raise EBlockPar.Create('GetEl. Path=' + Path, False);
      Result := nil;
      Exit;
    end;
    if Cursor >= PathLength then
      Break;
    if Entry.ItemType <> bpkBlock then
    begin
      if RaiseIfMissing then
        raise EBlockPar.Create('GetEl. Path=' + Path, False);
      Result := nil;
      Exit;
    end;
    Block := Entry.ChildBlock;
  end;
  if Entry = nil then
  begin
    if RaiseIfMissing then
      raise EBlockPar.Create('GetEl. Path=' + Path, False);
    Result := nil;
    Exit;
  end;
  Result := Entry;
end;

function TBlockParEC.FindSortedNameRangeStartIndex(const EntryName: WideString): Integer;
var
  Low, High, Middle, Order: Integer;
  Entry: TBlockParElEC;
begin
  if SortedEntryCount < 1 then
  begin
    Result := -1;
    Exit
  end;
  Low := 0;
  High := SortedEntryCount - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Entry := SortedEntries[Middle];
    Order := CompareWideChars(PWideChar(EntryName), PWideChar(Entry.Name));
    if Order = 0 then
    begin
      Result := Middle - Entry.GroupIndex;
      Exit
    end;
    if Order < 0 then
      High := Middle - 1
    else
      Low := Middle + 1;
  until High < Low;
  Result := -1;
end;

function TBlockParEC.PrepareSortedInsertion(Entry: TBlockParElEC): Integer;
var
  Low, High, Middle, Order: Integer;
  Existing: TBlockParElEC;
begin
  if SortedEntryCount <= 0 then
  begin
    Result := 0;
    Entry.GroupIndex := 0;
    Entry.GroupCount := 1;
    Exit;
  end;
  Low := 0;
  High := SortedEntryCount - 1;
  repeat
    Middle := (High - Low) shr 1 + Low;
    Existing := SortedEntries[Middle];
    Order := CompareWideChars(PWideChar(Entry.Name), PWideChar(Existing.Name));
    if Order = 0 then
      Order := Integer(Entry.ItemType) - Integer(Existing.ItemType);
    if Order = 0 then
    begin
      if Existing.GroupIndex <> 0 then
      begin
        Result := Middle - Existing.GroupIndex;
        Existing := SortedEntries[Result];
      end
      else
        Result := Middle;
      Entry.GroupIndex := Existing.GroupCount;
      Result := Result + Existing.GroupCount;
      Inc(Existing.GroupCount);
      Exit;
    end;
    if Order < 0 then
      High := Middle - 1
    else
      Low := Middle + 1;
  until High < Low;
  if Order < 0 then
    Result := Middle
  else
    Result := Middle + 1;
  Entry.GroupIndex := 0;
  Entry.GroupCount := 1;
end;

procedure TBlockParEC.InsertIntoSortedIndex(Entry: TBlockParElEC);
var
  Index: Integer;
begin
  SetLength(SortedEntries, SortedEntryCount + 1);
  Index := PrepareSortedInsertion(Entry);
  if Index >= SortedEntryCount then
  begin
    SortedEntries[SortedEntryCount] := Entry;
    Inc(SortedEntryCount);
    Exit;
  end;
  Windows.MoveMemory(
      @SortedEntries[Index + 1],
      @SortedEntries[Index],
      (SortedEntryCount - Index) * SizeOf(SortedEntries[0])
  );
  SortedEntries[Index] := Entry;
  Inc(SortedEntryCount);
end;

procedure TBlockParEC.RemoveFromSortedIndex(Entry: TBlockParElEC);
var
  i, Index: Integer;
  Head: TBlockParElEC;
begin
  Index := 0;
  while Index < SortedEntryCount do
  begin
    if SortedEntries[Index] = Entry then
    begin
      Head := SortedEntries[Index - Entry.GroupIndex];
      for i := Index + 1 to Index - Entry.GroupIndex + Head.GroupCount - 1 do
        Dec(SortedEntries[i].GroupIndex);
      Dec(Head.GroupCount);
      if Entry.GroupIndex = 0 then
        if Head.GroupCount > 0 then
          SortedEntries[Index + 1].GroupCount := Entry.GroupCount;
      if Index < SortedEntryCount - 1 then
        Windows.MoveMemory(
            @SortedEntries[Index],
            @SortedEntries[Index + 1],
            (SortedEntryCount - Index - 1) * SizeOf(SortedEntries[0])
        );
      Dec(SortedEntryCount);
      SetLength(SortedEntries, SortedEntryCount);
      Exit;
    end;
    Inc(Index);
  end;
end;

function TBlockParEC.GetParamByPath(const Path: WideString): WideString;
var
  Entry: TBlockParElEC;
begin
  Entry := FindEntryByPath(Path, True);
  if Entry.ItemType <> bpkString then
    raise Exception.Create('Par_Get. Path=' + Path);
  Result := Entry.StringValue;
end;

function TBlockParEC.GetParamByPathOrMarker(const Path: WideString): WideString;
var
  Entry: TBlockParElEC;
begin
  try
    Entry := FindEntryByPath(Path, True);
  except
    Result := '[' + Path + ']';
    Exit;
  end;
  if (Entry <> nil) and (Entry.ItemType = bpkString) then
    Result := Entry.StringValue
  else
    Result := '[' + Path + ']';
end;

function TBlockParEC.CountParamsByPath(const Path: WideString): Integer;
var
  Count: Integer;
  Part: WideString;
  Block: TBlockParEC;
begin
  Count := CountDelimitedPartsW(Path, './\');
  if Count > 1 then
  begin
    Block := GetOrAddBlockByPath(ExtractDelimitedRangeW(Path, 0, Count - 2, './\'));
    Part := ExtractDelimitedPartW(Path, Count - 1, './\');
  end
  else
  begin
    Part := Path;
    Block := Self;
  end;
  Result := Block.CountParams(Part);
end;

function TBlockParEC.AddParam(const ParamName, ParamValue: WideString): TBlockParElEC;
var
  Entry: TBlockParElEC;
begin
  Entry := AddEntry;
  Entry.ItemType := bpkString;
  Entry.Name := ParamName;
  Entry.StringValue := ParamValue;
  if UseSortedIndex then
    InsertIntoSortedIndex(Entry);
  Inc(StringParamCount);
  Result := Entry;
end;

procedure TBlockParEC.SetParam(const ParamName, ParamValue: WideString);
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Entry.StringValue := ParamValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Par_Set. name=' + ParamName);
end;

procedure TBlockParEC.SetOrAddParam(const ParamName, ParamValue: WideString);
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Entry.StringValue := ParamValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  AddParam(ParamName, ParamValue);
end;

procedure TBlockParEC.DeleteParam(const ParamName: WideString);
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      if UseSortedIndex then
        RemoveFromSortedIndex(Entry);
      DeleteEntry(Entry);
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Par_Delete. name=' + ParamName);
end;

procedure TBlockParEC.DeleteChildBlock(const BlockName: WideString);
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      if UseSortedIndex then
        RemoveFromSortedIndex(Entry);
      DeleteEntry(Entry);
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Block_Delete. name=' + BlockName);
end;

function TBlockParEC.GetParam(const ParamName: WideString): WideString;
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Result := Entry.StringValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Par_Get. name=' + ParamName);
end;

function TBlockParEC.GetParamOrMarker(const ParamName: WideString): WideString;
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Result := Entry.StringValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := '[' + ParamName + ']';
end;

function TBlockParEC.GetParamCount: Integer;
begin
  Result := StringParamCount
end;

function TBlockParEC.CountParams(const ParamName: WideString): Integer;
var
  Entry: TBlockParElEC;
  Count, Index, Limit: Integer;
begin
  if UseSortedIndex then
  begin
    Index := FindSortedNameRangeStartIndex(ParamName);
    Result := 0;
    if Index >= 0 then
    begin
      Limit := SortedEntries[Index].GroupCount + Index;
      while Index < Limit do
      begin
        Entry := SortedEntries[Index];
        if Entry.ItemType = bpkString then
          Inc(Result);
        Inc(Index);
      end;
    end;
  end
  else
  begin
    Entry := FirstEntry;
    Count := 0;
    while Entry <> nil do
    begin
      if (Entry.ItemType = bpkString) and (Entry.Name = ParamName) then
        Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  end;
end;

function TBlockParEC.GetParamValue(Index: Integer): WideString;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = StringParamCount) then
    Result := SortedEntries[Index].StringValue
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkString then
      begin
        if Index = 0 then
        begin
          Result := Entry.StringValue;
          Exit
        end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Par_Get. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetParamName(Index: Integer): WideString;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = StringParamCount) then
    Result := SortedEntries[Index].Name
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkString then
      begin
        if Index = 0 then
        begin
          Result := Entry.Name;
          Exit
        end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Par_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.AddBlockByPath(const Path: WideString): TBlockParEC;
var
  Count: Integer;
  Part: WideString;
  Entry: TBlockParElEC;
  Block: TBlockParEC;
begin
  Count := CountDelimitedPartsW(Path, './\');
  if Count > 1 then
  begin
    Block := GetOrAddBlockByPath(ExtractDelimitedRangeW(Path, 0, Count - 2, './\'));
    Part := ExtractDelimitedPartW(Path, Count - 1, './\');
  end
  else
  begin
    Part := Path;
    Block := Self;
  end;
  Entry := Block.AddEntry;
  Entry.MakeChildBlock;
  Entry.Name := Part;
  if UseSortedIndex then
    InsertIntoSortedIndex(Entry);
  Inc(ChildBlockCount);
  Result := Entry.ChildBlock;
end;

function TBlockParEC.GetBlockByPath(const Path: WideString): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  Entry := FindEntryByPath(Path, True);
  if Entry.ItemType <> bpkBlock then
    raise Exception.Create('TBlockParEC.BlockPath_Get. Path=' + Path);
  Result := Entry.ChildBlock;
end;

function TBlockParEC.FindBlockByPath(const Path: WideString): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  Entry := FindEntryByPath(Path, False);
  if (Entry = nil) or (Entry.ItemType <> bpkBlock) then
  begin
    Result := nil;
    Exit
  end;
  Result := Entry.ChildBlock;
end;

function TBlockParEC.GetOrAddBlockByPath(const Path: WideString): TBlockParEC;
begin
  Result := FindBlockByPath(Path);
  if Result = nil then
    Result := AddBlockByPath(Path);
end;

function TBlockParEC.AddChildBlock(const BlockName: WideString): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  Entry := AddEntry;
  Entry.MakeChildBlock;
  Entry.Name := BlockName;
  if UseSortedIndex then
    InsertIntoSortedIndex(Entry);
  Inc(ChildBlockCount);
  Result := Entry.ChildBlock;
end;

function TBlockParEC.GetBlock(const BlockName: WideString): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      Result := Entry.ChildBlock;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Block_Get. name=' + BlockName);
end;

function TBlockParEC.FindBlock(const BlockName: WideString): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      Result := Entry.ChildBlock;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;

function TBlockParEC.GetBlockCount: Integer;
begin
  Result := ChildBlockCount
end;

function TBlockParEC.CountBlocks(const BlockName: WideString): Integer;
var
  Entry: TBlockParElEC;
  Count, Index, Limit: Integer;
begin
  if UseSortedIndex then
  begin
    Index := FindSortedNameRangeStartIndex(BlockName);
    Result := 0;
    if Index >= 0 then
    begin
      Limit := SortedEntries[Index].GroupCount + Index;
      while Index < Limit do
      begin
        Entry := SortedEntries[Index];
        if Entry.ItemType = bpkBlock then
          Inc(Result);
        Inc(Index);
      end;
    end;
  end
  else
  begin
    Entry := FirstEntry;
    Count := 0;
    while Entry <> nil do
    begin
      if (Entry.ItemType = bpkBlock) and (Entry.Name = BlockName) then
        Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  end;
end;

function TBlockParEC.GetBlockByIndex(Index: Integer): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = ChildBlockCount) then
    Result := SortedEntries[Index].ChildBlock
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkBlock then
      begin
        if Index = 0 then
        begin
          Result := Entry.ChildBlock;
          Exit
        end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Block_Get. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetBlockNameByIndex(Index: Integer): WideString;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = ChildBlockCount) then
    Result := SortedEntries[Index].Name
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkBlock then
      begin
        if Index = 0 then
        begin
          Result := Entry.Name;
          Exit
        end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Block_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetEntryCount: Integer;
begin
  Result := EntryCount
end;

function TBlockParEC.GetEntryKindByIndex(Index: Integer): TBlockParKind;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Result := SortedEntries[Index].ItemType;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        Result := Entry.ItemType;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetTip. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetEntryBlockByIndex(Index: Integer): TBlockParEC;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if Entry.ItemType <> bpkBlock then
      raise Exception.Create('TBlockParEC.All_GetBlock. Error tip.');
    Result := Entry.ChildBlock;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if Entry.ItemType <> bpkBlock then
          raise Exception.Create('TBlockParEC.All_GetBlock. Error tip.');
        Result := Entry.ChildBlock;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetBlock. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetEntryStringByIndex(Index: Integer): WideString;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if Entry.ItemType <> bpkString then
      raise Exception.Create('TBlockParEC.All_GetPar. Error tip.');
    Result := Entry.StringValue;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if Entry.ItemType <> bpkString then
          raise Exception.Create('TBlockParEC.All_GetPar. Error tip.');
        Result := Entry.StringValue;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetPar. no=' + SysUtils.IntToStr(Index));
  end;
end;

function TBlockParEC.GetEntryNameByIndex(Index: Integer): WideString;
var
  Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if (Entry.ItemType <> bpkString) and (Entry.ItemType <> bpkBlock) then
      raise Exception.Create('TBlockParEC.All_GetName. Error tip.');
    Result := Entry.Name;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if (Entry.ItemType <> bpkString) and (Entry.ItemType <> bpkBlock) then
          raise Exception.Create('TBlockParEC.All_GetName. Error tip.');
        Result := Entry.Name;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;

procedure TBlockParEC.WriteWideText(Dest: TBufEC; Indent: Integer; Sorted: Boolean);
var
  Entry: TBlockParElEC;
  i: Integer;
  procedure WriteWideBlockEntry; // @addr 0x848B8C @ida "void __cdecl $name(void *ParentFrame);" @note "Nested helper of TBlockParEC.WriteWideText."
  var
    j: Integer;
  begin
    if Entry.ItemType = bpkText then
    begin
      if Entry.Comment <> '' then
        Dest.AddWideStringRaw(Entry.Comment);
      Dest.AddWord(13);
      Dest.AddWord(10);
    end
    else if Entry.ItemType = bpkString then
    begin
      for j := 1 to Indent * 4 do
        Dest.AddWord(Ord(' '));
      Dest.AddWideStringRaw(Entry.Name);
      Dest.AddWord(Ord('='));
      Dest.AddWideStringRaw(Entry.StringValue);
      if Entry.Comment <> '' then
        Dest.AddWideStringRaw(Entry.Comment);
      Dest.AddWord(13);
      Dest.AddWord(10);
    end
    else
    begin
      for j := 1 to Indent * 4 do
        Dest.AddWord(Ord(' '));
      Dest.AddWideStringRaw(Entry.Name);
      Dest.AddWord(Ord(' '));
      if UseSortedIndex then
        Dest.AddWord(Ord('^'))
      else
        Dest.AddWord(Ord('~'));
      Dest.AddWord(Ord('{'));
      Dest.AddWord(13);
      Dest.AddWord(10);
      Entry.ChildBlock.WriteWideText(Dest, Indent + 1, Sorted);
      for j := 1 to Indent * 4 do
        Dest.AddWord(Ord(' '));
      Dest.AddWord(Ord('}'));
      if Entry.Comment <> '' then
        Dest.AddWideStringRaw(Entry.Comment);
      Dest.AddWord(13);
      Dest.AddWord(10);
    end;
  end;
begin
  if UseSortedIndex and Sorted then
    for i := 1 to SortedEntryCount do
    begin
      Entry := SortedEntries[i - 1];
      WriteWideBlockEntry;
    end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      WriteWideBlockEntry;
      Entry := Entry.Next;
    end;
  end;
end;

procedure TBlockParEC.WriteAnsiText(Dest: TBufEC; Indent: Integer; Sorted: Boolean);
var
  Entry: TBlockParElEC;
  i: Integer;
  procedure WriteAnsiBlockEntry; // @addr 0x848E74 @ida "void __cdecl $name(void *ParentFrame);" @note "Nested helper of TBlockParEC.WriteAnsiText."
  var
    j: Integer;
  begin
    if Entry.ItemType = bpkText then
    begin
      if Entry.Comment <> '' then
        Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.Comment)));
      Dest.AddByte(13);
      Dest.AddByte(10);
    end
    else if Entry.ItemType = bpkString then
    begin
      for j := 1 to Indent do
        Dest.AddByte(9);
      Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.Name)));
      Dest.AddByte(Ord('='));
      Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.StringValue)));
      if Entry.Comment <> '' then
        Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.Comment)));
      Dest.AddByte(13);
      Dest.AddByte(10);
    end
    else
    begin
      for j := 1 to Indent do
        Dest.AddByte(9);
      Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.Name)));
      Dest.AddByte(Ord(' '));
      if UseSortedIndex then
        Dest.AddByte(Ord('^'))
      else
        Dest.AddByte(Ord('~'));
      Dest.AddByte(Ord('{'));
      Dest.AddByte(13);
      Dest.AddByte(10);
      Entry.ChildBlock.WriteAnsiText(Dest, Indent + 1, Sorted);
      for j := 1 to Indent do
        Dest.AddByte(9);
      Dest.AddByte(Ord('}'));
      if Entry.Comment <> '' then
        Dest.AddAnsiStringRaw(WideCharToString(PWideChar(Entry.Comment)));
      Dest.AddByte(13);
      Dest.AddByte(10);
    end;
  end;
begin
  if UseSortedIndex and Sorted then
    for i := 1 to SortedEntryCount do
    begin
      Entry := SortedEntries[i - 1];
      WriteAnsiBlockEntry;
    end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      WriteAnsiBlockEntry;
      Entry := Entry.Next;
    end;
  end;
end;

procedure TBlockParEC.WriteTextBuffer(Dest: TBufEC; AnsiText, Sorted: Boolean);
begin
  if not AnsiText then
  begin
    Dest.AddWord($FEFF);
    WriteWideText(Dest, 0, Sorted);
  end
  else
    WriteAnsiText(Dest, 0, Sorted);
end;

procedure TBlockParEC.SaveTextFile(FileName: PWideChar; AnsiText, Sorted: Boolean);
var
  FileObj: TFileEC;
  Buf: TBufEC;
begin
  FileObj := TFileEC.Create;
  Buf := TBufEC.Create;
  try
    WriteTextBuffer(Buf, AnsiText, Sorted);
    FileObj.SetFileName(WideString(FileName));
    FileObj.CreateNew;
    FileObj.WriteBuffer(Buf.Data, Buf.DataSize);
    FileObj.ReleaseHandle;
  finally
    FileObj.Free;
    Buf.Free;
  end;
end;

procedure TBlockParEC.ParseTextBuffer(
    Buf: TBufEC;
    const InitialText: WideString;
    AnsiText, PreserveComments: Boolean
);
var
  Text, Name, IncludeFile, Comment: WideString;
  Child: TBlockParEC;
  PartCount: Integer;
  Entry: TBlockParElEC;
  ChildSorted: Boolean;
begin
  Text := TrimWideString(InitialText);
  while not Buf.IsAtEnd do
  begin
    if Text = '' then
      if AnsiText then
        Text := TrimWideString(WideString(Buf.ReadAnsiTextLine))
      else
        Text := TrimWideString(Buf.ReadWideTextLine);
    Comment := ExtractLineCommentW(Text);
    Text := TrimWideString(RemoveLineCommentW(Text));
    PartCount := CountDelimitedPartsW(Text, '{');
    if PartCount > 1 then
    begin
      Name := TrimWideString(ExtractDelimitedPartW(Text, 0, '{'));
      if Name = '' then
        raise Exception.Create('TBlockParEC.LoadFromBuf_r. tstr=' + Text);
      ChildSorted := Name[Length(Name)] = '^';
      if ChildSorted then
      begin
        SetLength(Name, Length(Name) - 1);
        Name := TrimWideString(Name);
      end
      else
      begin
        ChildSorted := Name[Length(Name)] <> '~';
        if not ChildSorted then
        begin
          SetLength(Name, Length(Name) - 1);
          Name := TrimWideString(Name);
        end;
      end;
      IncludeFile := '';
      if CountDelimitedPartsW(Name, '=') = 2 then
      begin
        IncludeFile := TrimWideString(ExtractDelimitedPartW(Name, 1, '='));
        Name := TrimWideString(ExtractDelimitedPartW(Name, 0, '='));
      end;
      Child := AddChildBlock(Name);
      Child.UseSortedIndex := ChildSorted;
      Name := TrimWideString(ExtractDelimitedRangeW(Text, 1, PartCount - 1, '{'));
      Child.ParseTextBuffer(Buf, Name, AnsiText, PreserveComments);
      if IncludeFile <> '' then
        Child.LoadFromTextFileWithEncodingProbe(PWideChar(IncludeFile), False);
    end
    else
    begin
      if CountDelimitedPartsW(Text, '}') > 1 then
        Break;
      PartCount := CountDelimitedPartsW(Text, '=');
      if PartCount > 1 then
      begin
        Name := TrimWideString(ExtractDelimitedPartW(Text, 0, '='));
        IncludeFile := ExtractDelimitedRangeW(Text, 1, PartCount - 1, '=');
        if PreserveComments then
          AddParam(Name, IncludeFile).Comment := Comment
        else
          AddParam(Name, IncludeFile);
      end
      else if PreserveComments then
      begin
        Entry := AddEntry;
        Entry.ItemType := bpkText;
        Entry.Comment := Comment;
      end;
    end;
    Text := '';
  end;
end;

procedure TBlockParEC.LoadFromTextBufferWithEncodingProbe(Buf: TBufEC; PreserveComments: Boolean);
begin
  if Buf.DataSize - Buf.Position <= 2 then
    Exit;
  if Buf.GetWord <> $FEFF then
  begin
    Buf.SetPosition(Buf.Position - 2);
    ParseTextBuffer(Buf, '', True, PreserveComments);
  end
  else
    ParseTextBuffer(Buf, '', False, PreserveComments);
end;

procedure TBlockParEC.LoadFromTextFileWithEncodingProbe(
    FileName: PWideChar;
    PreserveComments: Boolean
);
var
  Buf: TBufEC;
begin
  Buf := TBufEC.Create;
  try
    Buf.LoadFromWideFilePath(FileName);
    LoadFromTextBufferWithEncodingProbe(Buf, PreserveComments);
  finally
    Buf.Free;
  end;
end;

procedure TBlockParEC.MergeFrom(Source: TBlockParEC);
var
  Incoming, Removed, Cursor, Existing: TBlockParElEC;
  Child: TBlockParEC;
  Occurrence, Seen: Integer;
begin
  Incoming := Source.FirstEntry;
  while Incoming <> nil do
  begin
    if Incoming.ItemType <> bpkText then
      if Incoming.ItemType = bpkString then
      begin
        Cursor := FirstEntry;
        while Cursor <> nil do
        begin
          Removed := Cursor;
          Cursor := Cursor.Next;
          if (Removed.ItemType = Incoming.ItemType) and (Removed.Name = Incoming.Name) then
          begin
            if UseSortedIndex then
              RemoveFromSortedIndex(Removed);
            DeleteEntry(Removed);
          end;
        end;
      end
      else if Incoming.ItemType = bpkBlock then
      begin
        Occurrence := 0;
        Cursor := Source.FirstEntry;
        while Cursor <> Incoming do
        begin
          if (Cursor.ItemType = bpkBlock) and (Cursor.Name = Incoming.Name) then
            Inc(Occurrence);
          Cursor := Cursor.Next;
        end;
        Inc(Occurrence);
        Seen := 0;
        Existing := FirstEntry;
        while Existing <> nil do
        begin
          if (Existing.ItemType = bpkBlock) and (Existing.Name = Incoming.Name) then
            Inc(Seen);
          if Seen = Occurrence then
            Break;
          Existing := Existing.Next;
        end;
        if Seen = Occurrence then
        begin
          Child := Existing.ChildBlock;
          Child.MergeFrom(Incoming.ChildBlock);
        end
        else
        begin
          Child := AddChildBlock(Incoming.Name);
          Child.CopyFrom(Incoming.ChildBlock);
        end;
      end;
    Incoming := Incoming.Next;
  end;
  Incoming := Source.FirstEntry;
  while Incoming <> nil do
  begin
    if Incoming.ItemType = bpkString then
      AddParam(Incoming.Name, Incoming.StringValue);
    Incoming := Incoming.Next;
  end;
end;

function TBlockParEC.ConcatenateValues: WideString;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to GetEntryCount - 1 do
    if GetEntryKindByIndex(i) = bpkBlock then
      Result := Result + '{' + GetEntryBlockByIndex(i).ConcatenateValues + '}'
    else
      Result := Result + GetEntryStringByIndex(i);
end;

procedure TBlockParEC.LoadFromDecodedBuffer(Buf: TBufEC);
var
  i, Count: Integer;
  Entry: TBlockParElEC;
begin
  Clear;
  UseSortedIndex := Buf.GetBoolean;
  Count := Buf.GetInt32;
  if UseSortedIndex then
  begin
    SortedEntryCount := Count;
    SetLength(SortedEntries, Count);
  end;
  for i := 0 to Count - 1 do
  begin
    Entry := AddEntry;
    if UseSortedIndex then
    begin
      Entry.GroupIndex := Buf.GetInt32;
      Entry.GroupCount := Buf.GetInt32;
    end;
    Entry.ItemType := TBlockParKind(Buf.GetByte);
    Entry.Name := Buf.ReadWideString;
    if Entry.ItemType = bpkString then
    begin
      Entry.StringValue := Buf.ReadWideString;
      Inc(StringParamCount);
      if UseSortedIndex then
        SortedEntries[i] := Entry;
    end
    else if Entry.ItemType = bpkBlock then
    begin
      Entry.MakeChildBlock;
      if UseSortedIndex then
        SortedEntries[i] := Entry;
      Inc(ChildBlockCount);
      Entry.ChildBlock.LoadFromDecodedBuffer(Buf);
    end;
  end;
end;

procedure TBlockParEC.LoadFromEncryptedDatFile(const FileName: WideString);
var
  Buf: TBufEC;
  FileObj: TFileEC;
  Crc: Cardinal;
  Seed, ByteCount: Integer;
  Position: Cardinal;
begin
  FileObj := TFileEC.Create;
  try
    FileObj.SetFileName(FileName);
    FileObj.AcquireReadHandle(False);
    Position := FileObj.GetPointer;
    FileObj.ReadBuffer(@ByteCount, SizeOf(ByteCount));
    FileObj.ReadBuffer(@Crc, SizeOf(Crc)); // Legacy envelope checksum.
    ByteCount := ByteCount xor (BlockDatCrcKey1 xor BlockDatCrcKey2);
    if FileObj.GetSize - FileObj.GetPointer = Cardinal(ByteCount) then
      Position := FileObj.GetPointer;
    FileObj.SetPointer(Position, FILE_BEGIN);
    ByteCount := FileObj.GetSize - FileObj.GetPointer;
    FileObj.ReadBuffer(@Crc, SizeOf(Crc));
    FileObj.ReadBuffer(@Seed, SizeOf(Seed));
    Seed := Seed xor BlockDatSeedKey;
    Buf := TBufEC.Create;
    try
      Buf.SetSize(ByteCount - SizeOf(Crc) - SizeOf(Seed));
      FileObj.ReadBuffer(Buf.Data, Buf.DataSize);
      Buf.ApplyDatXorCipher(Seed);
      if Buf.ComputeCrc32 = Crc then
      begin
        Buf.ExpandZlibPayloadInPlace;
        Buf.SetPosition(0);
        LoadFromDecodedBuffer(Buf);
      end;
    finally
      Buf.Free;
    end;
  finally
    FileObj.Free;
  end;
end;

end.
