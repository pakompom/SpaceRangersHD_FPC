{$EXCESSPRECISION OFF}
unit EC_Data;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_Buf,
  EC_File,
  EC_Struct,
  SyncObjs;
type
  TDataEC = class;
  TDataElEC = class;
  TDataFileEC = class;
  PointerToTDataFileEC = ^TDataFileEC;
  {$Z4}
  TDataEntryKind = (dekFile = 1, dekSubtree = 2);
  TDataFileEC = class(TObjectEx)
    Prev: TDataFileEC;
    Next: TDataFileEC;
    FileRef: TFileEC;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;
  PDataFileEC = PointerToTDataFileEC;
  TDataElEC = class(TObjectEx)
    Prev: TDataElEC;
    Next: TDataElEC;
    Name: WideString;
    Kind: TDataEntryKind;
    ChildData: TDataEC;
    SharedFileRef: TDataFileEC;
    FileOffset: Cardinal;
    ByteCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure ClearChildData;
  end;
  TDataEC = class(TObjectEx)
    FileLock: TCriticalSection;
    SharesInternedFileList: Boolean;
    Gap9: array[0..2] of Byte;
    InternedFileListHeadRef: PDataFileEC;
    InternedFileListTailRef: PDataFileEC;
    OwnedInternedFileListHead: TDataFileEC;
    OwnedInternedFileListTail: TDataFileEC;
    FirstEntry: TDataElEC;
    LastEntry: TDataElEC;
    IndexedEntries: array of TDataElEC;
    IndexedEntryCount: Integer;
    constructor Create;
    destructor Destroy; override;
    function IsEmpty: Boolean;
    procedure Clear;
    function AddEntry(EntryKind: TDataEntryKind): TDataElEC;
    function FindIndexedEntry(const Name: WideString): TDataElEC;
    function FindInsertionIndex(Entry: TDataElEC): Integer;
    procedure InsertIntoIndex(Entry: TDataElEC);
    procedure RebuildIndex;
    function InternFileName(const FileName: WideString): TDataFileEC;
    function FindEntry(const Name: WideString): TDataElEC;
    function FindEntryByPath(const Path: WideString): TDataElEC;
    procedure ReadEntryBuffer(Entry: TDataElEC; Dest: TBufEC);
    function GetData(const Name: WideString): TDataEC;
    procedure ReadBufferByPath(const Path: WideString; Dest: TBufEC);
    function FileExistsByPath(const Path: WideString): Boolean;
    procedure AddMissingFromBlock(Block: TBlockParEC);
    procedure WriteToBlock(Block: TBlockParEC);
    procedure MergeFrom(Source: TDataEC);
    procedure LoadFromDecodedBuffer(Buf: TBufEC);
    procedure LoadFromEncryptedDatFile(const FileName: WideString);
  end;
const
  ResourceDatSeedKey: Cardinal = $EA8F3F37;
  ResourceDatCrcKey1: Cardinal = $7DB6C99D;
  ResourceDatCrcKey2: Cardinal = $C83FCBF3;
implementation
uses
  Math,
  EC_Str,
  Windows,
  SysUtils,
  GlobalsV,
  GR_Main;
// @unit-initialization $8779DC
// @unit-finalization $845BD8

constructor TDataFileEC.Create;
begin
  inherited Create;
  FileRef := TFileEC.Create;
end;

destructor TDataFileEC.Destroy;
begin
  Clear;
  FileRef.Free;
  inherited Destroy;
end;

procedure TDataFileEC.Clear;
begin
end;

constructor TDataElEC.Create;
begin
  inherited Create;
end;

destructor TDataElEC.Destroy;
begin
  ClearChildData;
  inherited Destroy;
end;

procedure TDataElEC.ClearChildData;
begin
  if ChildData <> nil then
  begin
    ChildData.Free;
    ChildData := nil;
  end;
end;

constructor TDataEC.Create;
begin
  inherited Create;
  FileLock := TCriticalSection.Create;
  InternedFileListHeadRef := @OwnedInternedFileListHead;
  InternedFileListTailRef := @OwnedInternedFileListTail;
end;

destructor TDataEC.Destroy;
begin
  Clear;
  FileLock.Free;
  inherited Destroy;
end;

function TDataEC.IsEmpty: Boolean;
begin
  Result := FirstEntry = nil;
end;

procedure TDataEC.Clear;
var
  FileEntry, RemovedFile: TDataFileEC;
  Entry, RemovedEntry: TDataElEC;
begin
  if not SharesInternedFileList then
  begin
    FileEntry := InternedFileListHeadRef^;
    while FileEntry <> nil do
    begin
      RemovedFile := FileEntry;
      FileEntry := FileEntry.Next;
      RemovedFile.Free;
    end;
  end;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    RemovedEntry := Entry;
    Entry := Entry.Next;
    RemovedEntry.Free;
  end;
  SharesInternedFileList := False;
  InternedFileListHeadRef := @OwnedInternedFileListHead;
  InternedFileListTailRef := @OwnedInternedFileListTail;
  IndexedEntries := nil;
  IndexedEntryCount := 0;
end;

function TDataEC.AddEntry(EntryKind: TDataEntryKind): TDataElEC;
var
  Entry: TDataElEC;
begin
  Entry := TDataElEC.Create;
  if LastEntry <> nil then
    LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then
    FirstEntry := Entry;
  Entry.Kind := EntryKind;
  if EntryKind <> dekFile then
  begin
    Entry.ChildData := TDataEC.Create;
    Entry.ChildData.SharesInternedFileList := True;
    Entry.ChildData.InternedFileListHeadRef := InternedFileListHeadRef;
    Entry.ChildData.InternedFileListTailRef := InternedFileListTailRef;
  end;
  Result := Entry;
end;

function TDataEC.FindIndexedEntry(const Name: WideString): TDataElEC;
var
  Lo, Hi, Mid, Order: Integer;
  Entry: TDataElEC;
begin
  if IndexedEntryCount < 1 then
  begin
    Result := nil;
    Exit
  end;
  Lo := 0;
  Hi := IndexedEntryCount - 1;
  repeat
    Mid := (Hi - Lo) div 2 + Lo;
    Entry := IndexedEntries[Mid];
    Order := CompareWideChars(PWideChar(Name), PWideChar(Entry.Name));
    if Order = 0 then
    begin
      Result := Entry;
      Exit
    end;
    if Order < 0 then
      Hi := Mid - 1
    else
      Lo := Mid + 1;
  until Hi < Lo;
  Result := nil;
end;

function TDataEC.FindInsertionIndex(Entry: TDataElEC): Integer;
var
  Lo, Hi, Mid, Order: Integer;
  Existing: TDataElEC;
begin
  if IndexedEntryCount <= 0 then
  begin
    Result := 0;
    Exit
  end;
  Lo := 0;
  Hi := IndexedEntryCount - 1;
  repeat
    Mid := ((Hi - Lo) shr 1) + Lo;
    Existing := IndexedEntries[Mid];
    Order := CompareWideChars(PWideChar(Entry.Name), PWideChar(Existing.Name));
    if Order = 0 then
    begin
      Result := Mid;
      Exit
    end;
    if Order < 0 then
      Hi := Mid - 1
    else
      Lo := Mid + 1;
  until Hi < Lo;
  if Order < 0 then
    Result := Mid
  else
    Result := Mid + 1;
end;

procedure TDataEC.InsertIntoIndex(Entry: TDataElEC);
var
  Index: Integer;
begin
  SetLength(IndexedEntries, IndexedEntryCount + 1);
  Index := FindInsertionIndex(Entry);
  if Index >= IndexedEntryCount then
  begin
    IndexedEntries[IndexedEntryCount] := Entry;
    Inc(IndexedEntryCount);
  end
  else
  begin
    Windows.MoveMemory(
        @IndexedEntries[Index + 1],
        @IndexedEntries[Index],
        (IndexedEntryCount - Index) * SizeOf(IndexedEntries[0])
    );
    IndexedEntries[Index] := Entry;
    Inc(IndexedEntryCount);
  end;
end;

procedure TDataEC.RebuildIndex;
var
  Entry: TDataElEC;
begin
  SetLength(IndexedEntries, 0);
  IndexedEntryCount := 0;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    InsertIntoIndex(Entry);
    Entry := Entry.Next;
  end;
end;

function TDataEC.InternFileName(const FileName: WideString): TDataFileEC;
var
  Entry: TDataFileEC;
begin
  Entry := InternedFileListHeadRef^;
  while Entry <> nil do
  begin
    if Entry.FileRef.GetFileName = FileName then
    begin
      Result := Entry;
      Exit
    end;
    Entry := Entry.Next;
  end;
  Entry := TDataFileEC.Create;
  if InternedFileListTailRef^ <> nil then
    InternedFileListTailRef^.Next := Entry;
  Entry.Prev := InternedFileListTailRef^;
  Entry.Next := nil;
  InternedFileListTailRef^ := Entry;
  if InternedFileListHeadRef^ = nil then
    InternedFileListHeadRef^ := Entry;
  Entry.FileRef.SetFileName(FileName);
  Result := Entry;
end;

function TDataEC.FindEntry(const Name: WideString): TDataElEC;
begin
  Result := FindIndexedEntry(Name);
end;

function TDataEC.FindEntryByPath(const Path: WideString): TDataElEC;
var
  Position, PathLength, PartStart, PartLength: Integer;
  Entry: TDataElEC;
  Data: TDataEC;
  function NextDataPathComponent: Boolean; // @addr 0x844F38 @ida "bool __cdecl $name(void *ParentFrame);" @note "Nested helper of TDataEC.FindEntryByPath; requires its parent stack frame."
  var
    Ch: WideChar;
    i: Integer;
  begin
    if Position >= PathLength then
    begin
      Result := False;
      Exit
    end;
    PartStart := Position;
    i := PartStart;
    while PathLength > i do
    begin
      Ch := Path[i + 1];
      if (Ch = '.') or (Ch = '/') or (Ch = '\') then
        Break;
      Inc(i);
    end;
    PartLength := i - PartStart;
    Position := i + 1;
    Result := True;
  end;
begin
  PathLength := Length(Path);
  Position := 0;
  Data := Self;
  while NextDataPathComponent do
  begin
    Entry := Data.FindEntry(Copy(Path, PartStart + 1, PartLength));
    if Entry = nil then
      Break;
    if Position >= PathLength then
    begin
      Result := Entry;
      Exit
    end;
    if Entry.Kind <> dekSubtree then
      Break;
    Data := Entry.ChildData;
  end;
  Result := nil;
end;

procedure TDataEC.ReadEntryBuffer(Entry: TDataElEC; Dest: TBufEC);
var
  Size: Integer;
begin
  FileLock.Enter;
  Entry.SharedFileRef.FileRef.AcquireReadWriteHandle;
  try
    if Entry.FileOffset <> 0 then
      Entry.SharedFileRef.FileRef.SetPointer(Entry.FileOffset, FILE_BEGIN);
    Size := Entry.ByteCount;
    if Size < 0 then
      Size := Entry.SharedFileRef.FileRef.GetSize - Entry.FileOffset;
    Dest.LoadFromFileChunk(Entry.SharedFileRef.FileRef, Size);
  finally
    Entry.SharedFileRef.FileRef.ReleaseHandle;
    FileLock.Leave;
  end;
end;

function TDataEC.GetData(const Name: WideString): TDataEC;
var
  Entry: TDataElEC;
begin
  Entry := FindEntry(Name);
  if (Entry = nil) or (Entry.Kind <> dekSubtree) then
    raise Exception.Create('TDataEC.GetData. name=' + Name);
  Result := Entry.ChildData;
end;

procedure TDataEC.ReadBufferByPath(const Path: WideString; Dest: TBufEC);
var
  Entry: TDataElEC;
begin
  Entry := FindEntryByPath(Path);
  if (Entry = nil) or (Entry.Kind <> dekFile) then
    raise Exception.Create('TDataEC.PathGetBuf. path=' + Path);
  ReadEntryBuffer(Entry, Dest);
end;

function TDataEC.FileExistsByPath(const Path: WideString): Boolean;
var
  Entry: TDataElEC;
begin
  Entry := FindEntryByPath(Path);
  if (Entry = nil) or (Entry.Kind <> dekFile) then
  begin
    Result := False;
    Exit
  end;
  if (Entry.SharedFileRef <> nil)
      and (Entry.SharedFileRef.FileRef <> nil)
      and Entry.SharedFileRef.FileRef.TryAcquireReadHandle(False) then
    Entry.SharedFileRef.FileRef.ReleaseHandle
  else
  begin
    Result := False;
    Exit
  end;
  Result := True;
end;

procedure TDataEC.AddMissingFromBlock(Block: TBlockParEC);
var
  Count, i: Integer;
  Kind: TBlockParKind;
  Entry: TDataElEC;
begin
  Count := Block.GetEntryCount;
  for i := 0 to Count - 1 do
  begin
    Kind := Block.GetEntryKindByIndex(i);
    if (Kind = bpkString) or (Kind = bpkBlock) then
      if FindEntry(Block.GetEntryNameByIndex(i)) <> nil then
        Continue;
    if Kind = bpkString then
    begin
      Entry := AddEntry(dekFile);
      Entry.Name := Block.GetEntryNameByIndex(i);
      Entry.SharedFileRef := InternFileName(Block.GetEntryStringByIndex(i));
      Entry.FileOffset := 0;
      Entry.ByteCount := -1;
      InsertIntoIndex(Entry);
    end
    else if Kind = bpkBlock then
    begin
      Entry := AddEntry(dekSubtree);
      Entry.Name := Block.GetEntryNameByIndex(i);
      InsertIntoIndex(Entry);
      Entry.ChildData.AddMissingFromBlock(Block.GetEntryBlockByIndex(i));
    end;
  end;
end;

procedure TDataEC.WriteToBlock(Block: TBlockParEC);
var
  i: Integer;
  Entry: TDataElEC;
begin
  for i := 0 to IndexedEntryCount - 1 do
  begin
    Entry := IndexedEntries[i];
    if Entry.Kind = dekFile then
      Block.AddParam(Entry.Name, Entry.SharedFileRef.FileRef.GetFileName)
    else
      Entry.ChildData.WriteToBlock(Block.AddChildBlock(Entry.Name));
  end;
end;

procedure TDataEC.MergeFrom(Source: TDataEC);
var
  Entry, Existing: TDataElEC;
begin
  Entry := Source.FirstEntry;
  while Entry <> nil do
  begin
    Existing := FindIndexedEntry(Entry.Name);
    if Existing = nil then
    begin
      Existing := AddEntry(Entry.Kind);
      Existing.Name := Entry.Name;
    end
    else if Entry.Kind <> Existing.Kind then
    begin
      Entry := Entry.Next;
      Continue;
    end;
    if Integer(Entry.Kind) <> 0 then
      if Entry.Kind = dekFile then
      begin
        Existing.FileOffset := 0;
        Existing.ByteCount := -1;
        Existing.SharedFileRef := InternFileName(Entry.SharedFileRef.FileRef.FileName);
      end
      else if Entry.Kind = dekSubtree then
        Existing.ChildData.MergeFrom(Entry.ChildData);
    Entry := Entry.Next;
  end;
  RebuildIndex;
end;

procedure TDataEC.LoadFromDecodedBuffer(Buf: TBufEC);
var
  Entry: TDataElEC;
  i: Integer;
  Kind: TDataEntryKind;
begin
  Clear;
  IndexedEntryCount := Buf.GetInt32;
  SetLength(IndexedEntries, IndexedEntryCount);
  for i := 0 to IndexedEntryCount - 1 do
  begin
    Kind := TDataEntryKind(Buf.GetByte);
    Entry := AddEntry(Kind);
    Entry.Name := Buf.ReadWideString;
    Entry.FileOffset := 0;
    Entry.ByteCount := -1;
    if Kind = dekFile then
      Entry.SharedFileRef := InternFileName(Buf.ReadWideString)
    else
      Entry.ChildData.LoadFromDecodedBuffer(Buf);
    IndexedEntries[i] := Entry;
  end;
end;

procedure TDataEC.LoadFromEncryptedDatFile(const FileName: WideString);
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
    ByteCount := ByteCount xor (ResourceDatCrcKey1 xor ResourceDatCrcKey2);
    if FileObj.GetSize - FileObj.GetPointer = Cardinal(ByteCount) then
      Position := FileObj.GetPointer;
    FileObj.SetPointer(Position, FILE_BEGIN);
    ByteCount := FileObj.GetSize - FileObj.GetPointer;
    FileObj.ReadBuffer(@Crc, SizeOf(Crc));
    FileObj.ReadBuffer(@Seed, SizeOf(Seed));
    Seed := Seed xor ResourceDatSeedKey;
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
