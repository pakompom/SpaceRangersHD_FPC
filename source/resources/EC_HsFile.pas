{$EXCESSPRECISION OFF}
unit EC_HsFile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  RTLFileSystem,
  SyncObjs;
type
  THashEC = class;
  THsFolderEC = class;
  TPackCollectionEC = class;
  TPackFileEC = class;
  PointerToTPackEntryEC = ^TPackEntryEC;
  TPackEntryEC = packed record
    StoredSize: Cardinal;
    DataSize: Cardinal;
    UpperName: array[0..62] of AnsiChar;
    OriginalName: array[0..62] of AnsiChar;
    Kind: Integer;
    KindCopy: Integer;
    Flags: Cardinal;
    Gap92: array[0..3] of Byte;
    TargetOffset: Cardinal;
    ChildFolder: THsFolderEC;
  end;
  PPackEntryEC = PointerToTPackEntryEC;
  THsFolderEC = class(TObject)
    UpperName: AnsiString;
    OriginalName: AnsiString;
    HeaderSize: Cardinal;
    EntryCount: Cardinal;
    EntryRecordSize: Cardinal;
    Parent: THsFolderEC;
    EntryBuffer: PPackEntryEC;
    ChangedFlag: Boolean;
    InitializedEmptyFlag: Boolean;
    Gap22: array[0..1] of Byte;
    constructor Create(FolderName: AnsiString);
    constructor CreateChild(FolderName: AnsiString; Parent: THsFolderEC);
    destructor Destroy; override;
    function GetEntry(Index: Cardinal): PPackEntryEC;
    function FindEntry(EntryName: AnsiString): PPackEntryEC;
    procedure InitializeEmpty;
    function Load(FileHandle: Cardinal; SubtreeOffset: Cardinal): Boolean;
    procedure Unload;
    function ResolveEntryByPath(EntryPath: AnsiString): PPackEntryEC;
    procedure UpdateParentEntry;
  end;
  THashSlotEC = packed record
    FullHash: Cardinal;
    MappedValue: Integer;
    HitCount: Cardinal;
    Unknown0C: Integer;
    KeySuffix: array[0..31] of AnsiChar;
    Gap30: array[0..3] of Byte;
  end;
  THashSlotArray = array[0..1023] of THashSlotEC;
  TPackOpenSlotEC = packed record
    FileHandle: Cardinal;
    IsAvailable: Boolean;
    DataStartOffset: Cardinal;
    CurrentDataOffset: Cardinal;
    DataSize: Cardinal;
    CompressedBlockBuffer: Pointer;
    DecompressedBlockBuffer: Pointer;
    UsesChainedBlocks: Boolean;
    CurrentBlockIndex: Integer;
    // CHANGE: PERFORMANCE - Retain the sequential compressed-block position across reads.
    // Host-only physical cursor; independent of the decoded-block cache and seeks.
    NextChainedBlockIndex: Cardinal;
    NextChainedBlockOffset: Cardinal;
  end;
  TPackOpenSlotArray = array[0..15] of TPackOpenSlotEC;
  TPackFileEC = class(TObject)
    NextPack: TPackFileEC;
    PrevPack: TPackFileEC;
    UseLooseFiles: Boolean;
    GapD: array[0..2] of Byte;
    PackageHandle: Cardinal;
    PackagePath: AnsiString;
    RootFolder: THsFolderEC;
    OpenSlots: TPackOpenSlotArray;
    RootSubtreeOffset: Cardinal;
    Gap200: array[0..11] of Byte;
    CollectionIndex: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure SetPackagePath(NewPackagePath: AnsiString);
    procedure CloseAllOpenEntrySlots;
    function Open: Boolean;
    function Close: Boolean;
    function CloseForDestroy: Boolean;
    function FindFreeOpenSlotIndex: Integer;
    function OpenEntryByPath(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer;
    function CreateLooseFile(FilePath: WideString): Integer;
    function CloseEntrySlot(SlotIndex: Cardinal): Boolean;
    function GetChainedBlockStoredSizeAtIndex(
        FirstBlockOffset: Cardinal;
        BlockIndex: Cardinal
    ): Cardinal;
    function ReadEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean;
    function WriteEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean;
    function SeekEntrySlot(SlotIndex: Cardinal; Offset: Cardinal; Origin: Integer): Boolean;
    function GetEntrySlotPosition(SlotIndex: Cardinal): Cardinal;
    function GetEntrySlotSize(SlotIndex: Cardinal): Cardinal;
  end;
  TPackFileArray = array[0..127] of TPackFileEC;
  THashEC = class(TObject)
    OperationCount: Cardinal;
    HitCount: Cardinal;
    HitCountCopy: Cardinal;
    StaleValueCount: Cardinal;
    MissCount: Cardinal;
    ReservedText: AnsiString;
    Slots: THashSlotArray;
    constructor Create;
    destructor Destroy; override;
    function ComputeLookupBucketAndFullHash(var Key: AnsiString; out FullHash: Cardinal): Integer;
    function FindOrInsertKeySlot(Key: AnsiString): Integer;
    procedure SetSlotMappedValue(SlotIndex: Integer; Value: Integer);
    function InitializeEmptyTable(BucketCount: Integer): Boolean;
    function ReleaseTable: Boolean;
    function GetSlotMappedValue(SlotIndex: Integer): Integer;
    procedure MaybeResetStatistics;
    procedure NoteStaleMappedValue;
  end;
  TPackCollectionEC = class(TObject)
    FirstPack: TPackFileEC;
    LastPack: TPackFileEC;
    NameToPackIndexHash: THashEC;
    UseFastNameIndex: Boolean;
    Gap11: array[0..2] of Byte;
    PackByIndex: TPackFileArray;
    constructor Create;
    destructor Destroy; override;
    procedure Clear(FreePacks: Boolean);
    procedure AddPackToFront(Pack: TPackFileEC);
    procedure AddPackToBack(Pack: TPackFileEC);
    procedure RemovePack(Pack: TPackFileEC; FreePack: Boolean);
    function OpenAllPackages: Boolean;
    function CloseAllPackages: Boolean;
    function GetPackByIndex(PackIndex: Integer): TPackFileEC;
    function OpenEntryByPathAcrossPackages(
        EntryPath: AnsiString;
        DesiredAccess: Cardinal;
        FirstPackageOnly: Boolean
    ): Integer;
    function CreateLooseFile(FilePath: WideString): Integer;
    function CloseEntryHandle(Handle: Integer): Boolean;
    function ReadEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean;
    function WriteEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean;
    function SeekEntryHandle(Handle: Integer; Offset: Cardinal; Origin: Integer): Boolean;
    function GetEntryHandlePosition(Handle: Integer): Cardinal;
    function GetEntryHandleSize(Handle: Integer): Cardinal;
  end;
var
  PackageCollection: TPackCollectionEC;
  PackageFileLock: TCriticalSection;
  LooseFileRoot: AnsiString;
function OffsetPackPointer(Data: Pointer; ByteOffset: Cardinal): Pointer;
function AnsiBeforeFirstDelimiter(Text: AnsiString; Delimiters: AnsiString): AnsiString;
function AnsiAfterFirstDelimiter(Text: AnsiString; Delimiters: AnsiString): AnsiString;
function MatchLookupKeySuffix(
    var Key: AnsiString;
    SuffixBytes: Pointer;
    SuffixLength: Integer
): Boolean;
procedure CopyLookupKeySuffix(DestSuffixBytes: Pointer; SuffixLength: Integer; var Key: AnsiString);
implementation
uses
  ZLib,
  Math,
  EC_OKGF,
  SysUtils,
  Windows;
const
  // A collection handle combines the package index and its four-bit open slot.
  PackOpenSlotShift = 4;
  PackOpenSlotCount = 1 shl PackOpenSlotShift;
  PackCompressionBlockShift = 16;
  PackCompressionBlockSize = 1 shl PackCompressionBlockShift;
  PackCompressedBufferSize = 72112;
  PackSlotRangeError = 'Номер файла не может быть более ';
function OffsetPackPointer(Data: Pointer; ByteOffset: Cardinal): Pointer;
begin
  Result := Pointer(PtrUInt(Data) + ByteOffset);
end;
function AnsiBeforeFirstDelimiter(Text, Delimiters: AnsiString): AnsiString;
var
  i, j: Integer;
begin
  i := 1;
  while i <= Length(Text) do
  begin
    for j := 1 to Length(Delimiters) do
      if Delimiters[j] = Text[i] then
      begin
        Result := Copy(Text, 1, i - 1);
        Exit;
      end;
    Inc(i);
  end;
  Result := Text;
end;
function AnsiAfterFirstDelimiter(Text, Delimiters: AnsiString): AnsiString;
var
  i, j: Integer;
begin
  i := 1;
  while i <= Length(Text) do
  begin
    for j := 1 to Length(Delimiters) do
      if Delimiters[j] = Text[i] then
      begin
        Result := Copy(Text, i + 1, Length(Text) - i);
        Exit;
      end;
    Inc(i);
  end;
  Result := '';
end;
constructor TPackFileEC.Create;
var
  i: Integer;
begin
  PackageHandle := INVALID_HANDLE_VALUE;
  UseLooseFiles := False;
  PackagePath := '';
  RootFolder := nil;
  RootSubtreeOffset := 0;
  NextPack := nil;
  PrevPack := nil;
  CollectionIndex := -1;
  for i := Low(OpenSlots) to High(OpenSlots) do
    OpenSlots[i].IsAvailable := True;
end;
destructor TPackFileEC.Destroy;
begin
  CloseAllOpenEntrySlots;
  CloseForDestroy;
end;
procedure TPackFileEC.SetPackagePath(NewPackagePath: AnsiString);
begin
  PackagePath := NewPackagePath;
end;
procedure TPackFileEC.CloseAllOpenEntrySlots;
var
  i: Integer;
begin
  for i := Low(OpenSlots) to High(OpenSlots) do
    if not OpenSlots[i].IsAvailable then
    begin
      CloseEntrySlot(i);
      OpenSlots[i].IsAvailable := True;
    end;
end;
function TPackFileEC.Open: Boolean;
var
  BytesRead: Cardinal;
begin
  if (PackageHandle <> INVALID_HANDLE_VALUE) or (RootFolder <> nil) then
    Close;

  if UseLooseFiles then
  begin
    RootSubtreeOffset := 0;
    RootFolder := THsFolderEC.Create('');
    RootFolder.InitializeEmpty;
    Result := True;
    Exit;
  end;

  PackageHandle :=
      Windows.CreateFileA(
          PAnsiChar(PackagePath),
          GENERIC_READ or GENERIC_WRITE,
          FILE_SHARE_READ or FILE_SHARE_WRITE,
          nil,
          OPEN_EXISTING,
          FILE_ATTRIBUTE_NORMAL,
          0
      );
  if PackageHandle = INVALID_HANDLE_VALUE then
  begin
    raise Exception.Create('Error openning package file [READ]:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;
  if not Windows
      .ReadFile(PackageHandle, RootSubtreeOffset, SizeOf(RootSubtreeOffset), BytesRead, nil) then
  begin
    Windows.CloseHandle(PackageHandle);
    raise Exception.Create('Error reading package file:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;
  RootFolder := THsFolderEC.Create('');
  if not RootFolder.Load(PackageHandle, RootSubtreeOffset) then
  begin
    RootFolder.Free;
    RootFolder := nil;
    Close;
    raise Exception.Create('Error reading file system of the package file:' + PackagePath);
    Exit;
  end;
  Result := True;
end;
function TPackFileEC.Close: Boolean;
var
  Success: Boolean;
begin
  Result := False;
  if (PackageHandle = INVALID_HANDLE_VALUE) and (RootFolder = nil) then
    Exit;
  CloseAllOpenEntrySlots;
  if RootFolder <> nil then
  begin
    RootFolder.Free;
    RootFolder := nil;
  end;
  if PackageHandle <> INVALID_HANDLE_VALUE then
    Success := Windows.CloseHandle(PackageHandle)
  else
    Success := True;
  PackageHandle := INVALID_HANDLE_VALUE;
  if Success then
    Result := True;
end;
function TPackFileEC.CloseForDestroy: Boolean;
var
  Success: Boolean;
begin
  Result := False;
  if (PackageHandle = INVALID_HANDLE_VALUE) and (RootFolder = nil) then
    Exit;
  CloseAllOpenEntrySlots;
  if RootFolder <> nil then
  begin
    RootFolder.Free;
    RootFolder := nil;
  end;
  if PackageHandle <> INVALID_HANDLE_VALUE then
    Success := Windows.CloseHandle(PackageHandle)
  else
    Success := True;
  PackageHandle := INVALID_HANDLE_VALUE;
  if Success then
    Result := True;
end;
function TPackFileEC.FindFreeOpenSlotIndex: Integer;
var
  i: Integer;
begin
  for i := Low(OpenSlots) to High(OpenSlots) do
    if OpenSlots[i].IsAvailable then
    begin
      Result := i;
      Exit
    end;
  Result := -1;
end;
function TPackFileEC.OpenEntryByPath(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer;
var
  Slot: Integer;
  Entry: PPackEntryEC;
  Position: Cardinal;
begin
  Result := -1;
  Slot := FindFreeOpenSlotIndex;
  if Slot = -1 then
    Exit;
  if RootFolder = nil then
    raise Exception.Create('Package not opened :' + EntryPath);
  if not UseLooseFiles then
  begin
    Entry := RootFolder.ResolveEntryByPath(EntryPath);
    if Entry = nil then
      Exit;
  end
  else
  begin

    if not RTLFileSystem.FileExists(LooseFileRoot + EntryPath) then
      Exit;
    OpenSlots[Slot].FileHandle :=
        Windows.CreateFileA(
            PAnsiChar(LooseFileRoot + EntryPath),
            DesiredAccess,
            FILE_SHARE_READ,
            nil,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            0
        );
    if OpenSlots[Slot].FileHandle = INVALID_HANDLE_VALUE then
      Exit;
    OpenSlots[Slot].DataStartOffset := 0;
    OpenSlots[Slot].CurrentDataOffset := 0;
    OpenSlots[Slot].DataSize :=
        Windows.SetFilePointer(OpenSlots[Slot].FileHandle, 0, nil, FILE_END);
    OpenSlots[Slot].CompressedBlockBuffer := nil;
    OpenSlots[Slot].DecompressedBlockBuffer := nil;
    OpenSlots[Slot].UsesChainedBlocks := False;
    OpenSlots[Slot].CurrentBlockIndex := -1;
    if OpenSlots[Slot].DataSize = $FFFFFFFF then
      raise Exception.Create('Сбой в файловой системе :' + EntryPath);
    Position := Windows.SetFilePointer(OpenSlots[Slot].FileHandle, 0, nil, FILE_BEGIN);
    if Position = $FFFFFFFF then
      raise Exception.Create('Сбой в файловой системе:' + EntryPath);
    OpenSlots[Slot].IsAvailable := False;
    Result := Slot;
    Exit;
  end;
  if PackageHandle = INVALID_HANDLE_VALUE then
    Exit;
  OpenSlots[Slot].FileHandle := PackageHandle;
  OpenSlots[Slot].DataStartOffset := Entry.TargetOffset + 4;
  OpenSlots[Slot].CurrentDataOffset := Entry.TargetOffset + 4;
  OpenSlots[Slot].DataSize := Entry.DataSize;
  OpenSlots[Slot].IsAvailable := False;
  OpenSlots[Slot].UsesChainedBlocks := Entry.Kind = 2;
  OpenSlots[Slot].CurrentBlockIndex := -1;
  OpenSlots[Slot].NextChainedBlockIndex := 0;
  OpenSlots[Slot].NextChainedBlockOffset := OpenSlots[Slot].DataStartOffset;
  if OpenSlots[Slot].UsesChainedBlocks then
  begin
    OpenSlots[Slot].CompressedBlockBuffer := AllocMem(PackCompressedBufferSize);
    OpenSlots[Slot].DecompressedBlockBuffer := AllocMem(PackCompressionBlockSize);
  end
  else
  begin
    OpenSlots[Slot].CompressedBlockBuffer := nil;
    OpenSlots[Slot].DecompressedBlockBuffer := nil;
  end;
  Position :=
      Windows.SetFilePointer(
          OpenSlots[Slot].FileHandle,
          OpenSlots[Slot].CurrentDataOffset,
          nil,
          FILE_BEGIN
      );
  if Position = $FFFFFFFF then
    raise Exception.Create(
        'Сбой в пакетном файле :' + PackagePath + ':' + EntryPath);
  Result := Slot;
end;
function TPackFileEC.CreateLooseFile(FilePath: WideString): Integer;
var
  Slot: Integer;
begin
  Result := -1;
  Slot := FindFreeOpenSlotIndex;
  if Slot = -1 then
    Exit;

  OpenSlots[Slot].FileHandle :=
      Windows.CreateFileW(
          PWideChar(FilePath),
          GENERIC_READ or GENERIC_WRITE,
          FILE_SHARE_READ,
          nil,
          CREATE_ALWAYS,
          FILE_ATTRIBUTE_NORMAL,
          0
      );
  if OpenSlots[Slot].FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  OpenSlots[Slot].DataStartOffset := 0;
  OpenSlots[Slot].CurrentDataOffset := 0;
  OpenSlots[Slot].DataSize := 0;
  OpenSlots[Slot].CompressedBlockBuffer := nil;
  OpenSlots[Slot].DecompressedBlockBuffer := nil;
  OpenSlots[Slot].UsesChainedBlocks := False;
  OpenSlots[Slot].CurrentBlockIndex := -1;
  OpenSlots[Slot].IsAvailable := False;
  Result := Slot;
end;
function TPackFileEC.CloseEntrySlot(SlotIndex: Cardinal): Boolean;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  Result := True;
  if OpenSlots[SlotIndex].FileHandle = PackageHandle then
  begin
    if OpenSlots[SlotIndex].UsesChainedBlocks then
    begin
      FreeMem(OpenSlots[SlotIndex].CompressedBlockBuffer);
      OpenSlots[SlotIndex].CompressedBlockBuffer := nil;
      FreeMem(OpenSlots[SlotIndex].DecompressedBlockBuffer);
      OpenSlots[SlotIndex].DecompressedBlockBuffer := nil;
    end;
    OpenSlots[SlotIndex].IsAvailable := True;
  end
  else
  begin
    if not Boolean(Windows.CloseHandle(OpenSlots[SlotIndex].FileHandle)) then
      raise Exception.Create(
          'Ошибка закрытия файла : ' + SysUtils.IntToStr(SlotIndex));
    if OpenSlots[SlotIndex].UsesChainedBlocks then
    begin
      FreeMem(OpenSlots[SlotIndex].CompressedBlockBuffer);
      OpenSlots[SlotIndex].CompressedBlockBuffer := nil;
      FreeMem(OpenSlots[SlotIndex].DecompressedBlockBuffer);
      OpenSlots[SlotIndex].DecompressedBlockBuffer := nil;
    end;
    OpenSlots[SlotIndex].IsAvailable := True;
  end;
end;
function TPackFileEC.GetChainedBlockStoredSizeAtIndex(
    FirstBlockOffset,
    BlockIndex: Cardinal
): Cardinal;
var
  BytesRead, StoredSize, Offset: Cardinal;
begin
  Offset := FirstBlockOffset;
  while True do
  begin
    Windows.SetFilePointer(PackageHandle, Offset, nil, FILE_BEGIN);
    Windows.ReadFile(PackageHandle, StoredSize, SizeOf(StoredSize), BytesRead, nil);
    if BlockIndex = 0 then
      Break;
    Dec(BlockIndex);
    Offset := Offset + StoredSize + SizeOf(StoredSize);
  end;
  Result := StoredSize;
end;
function TPackFileEC.ReadEntrySlot(
    SlotIndex: Cardinal;
    Buffer: Pointer;
    ByteCount: Cardinal
): Boolean;
var
  BytesRead, BlockIndex, BlockOffset, ChunkSize, StoredSize, RelativeOffset: Cardinal;
  Decoded, Dest: Pointer;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  if OpenSlots[SlotIndex].UsesChainedBlocks then
  begin
    Decoded := OpenSlots[SlotIndex].DecompressedBlockBuffer;
    Dest := Buffer;
    while ByteCount <> 0 do
    begin
      RelativeOffset :=
          OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
      BlockIndex := RelativeOffset shr PackCompressionBlockShift;
      BlockOffset := RelativeOffset - BlockIndex * PackCompressionBlockSize;
      ChunkSize := ByteCount;
      if PackCompressionBlockSize - BlockOffset < ChunkSize then
        ChunkSize := PackCompressionBlockSize - BlockOffset;
      if OpenSlots[SlotIndex].CurrentBlockIndex <> Integer(BlockIndex) then
      begin
        // The original scans from the first header for every block (O(n^2)
        // seeks for a sequential read). Keep the next physical header per slot.
        // Nonsequential access retains the original traversal and seeds the cursor.
        if BlockIndex = OpenSlots[SlotIndex].NextChainedBlockIndex then
        begin
          Windows.SetFilePointer(
              PackageHandle,
              OpenSlots[SlotIndex].NextChainedBlockOffset,
              nil,
              FILE_BEGIN
          );
          if not Windows.ReadFile(PackageHandle, StoredSize, 4, BytesRead, nil)
              or (BytesRead <> 4) then
          begin
            Result := False;
            Exit
          end;
          Inc(OpenSlots[SlotIndex].NextChainedBlockOffset, StoredSize + 4);
        end
        else
        begin
          StoredSize :=
              GetChainedBlockStoredSizeAtIndex(OpenSlots[SlotIndex].DataStartOffset, BlockIndex);
          OpenSlots[SlotIndex].NextChainedBlockOffset :=
              Windows.SetFilePointer(PackageHandle, 0, nil, FILE_CURRENT) + StoredSize;
        end;
        OpenSlots[SlotIndex].NextChainedBlockIndex := BlockIndex + 1;
        Result :=
            Windows.ReadFile(
                PackageHandle,
                OpenSlots[SlotIndex].CompressedBlockBuffer^,
                StoredSize,
                BytesRead,
                nil
            );
        if not Result then
          Exit;
        OKGF_ZLib_UnCompress2(
            OpenSlots[SlotIndex].DecompressedBlockBuffer,
            PackCompressionBlockSize,
            OpenSlots[SlotIndex].CompressedBlockBuffer,
            StoredSize
        );
        OpenSlots[SlotIndex].CurrentBlockIndex := BlockIndex;
      end;
      Move(OffsetPackPointer(Decoded, BlockOffset)^, Dest^, ChunkSize);
      Dest := OffsetPackPointer(Dest, ChunkSize);
      Dec(ByteCount, ChunkSize);
      Inc(OpenSlots[SlotIndex].CurrentDataOffset, ChunkSize);
    end;
    Result := True;
  end
  else
  begin
    Windows.SetFilePointer(
        OpenSlots[SlotIndex].FileHandle,
        OpenSlots[SlotIndex].CurrentDataOffset,
        nil,
        FILE_BEGIN
    );
    Result := Windows.ReadFile(OpenSlots[SlotIndex].FileHandle, Buffer^, ByteCount, BytesRead, nil);
    Result := Result and (ByteCount = BytesRead);
    Inc(OpenSlots[SlotIndex].CurrentDataOffset, BytesRead);
  end;
end;
function TPackFileEC.WriteEntrySlot(
    SlotIndex: Cardinal;
    Buffer: Pointer;
    ByteCount: Cardinal
): Boolean;
var
  BytesWritten, Size: Cardinal;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  if OpenSlots[SlotIndex].UsesChainedBlocks then
    raise Exception.Create(
        'Ошибочная операция записи в сжатый файл');
  Windows.SetFilePointer(
      OpenSlots[SlotIndex].FileHandle,
      OpenSlots[SlotIndex].CurrentDataOffset,
      nil,
      FILE_BEGIN
  );
  Result :=
      Windows.WriteFile(OpenSlots[SlotIndex].FileHandle, Buffer^, ByteCount, BytesWritten, nil);
  Result := Result and (ByteCount = BytesWritten);
  Inc(OpenSlots[SlotIndex].CurrentDataOffset, BytesWritten);
  Size := OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
  if Size > OpenSlots[SlotIndex].DataSize then
    OpenSlots[SlotIndex].DataSize := Size;
end;
function TPackFileEC.SeekEntrySlot(SlotIndex, Offset: Cardinal; Origin: Integer): Boolean;
var
  Position, BlockIndex: Cardinal;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  if Origin = FILE_CURRENT then
    Offset := OpenSlots[SlotIndex].CurrentDataOffset + Offset - OpenSlots[SlotIndex].DataStartOffset
  else if Origin = FILE_END then
    Offset := OpenSlots[SlotIndex].DataSize - Offset;
  if OpenSlots[SlotIndex].UsesChainedBlocks then
  begin
    if Offset > OpenSlots[SlotIndex].DataSize then
      Exit;
    BlockIndex := Offset shr PackCompressionBlockShift;
    if OpenSlots[SlotIndex].CurrentBlockIndex <> Integer(BlockIndex) then
      OpenSlots[SlotIndex].CurrentBlockIndex := -1;
    OpenSlots[SlotIndex].CurrentDataOffset := OpenSlots[SlotIndex].DataStartOffset + Offset;
  end
  else
  begin
    Position :=
        Windows.SetFilePointer(
            OpenSlots[SlotIndex].FileHandle,
            OpenSlots[SlotIndex].DataStartOffset + Offset,
            nil,
            FILE_BEGIN
        );
    if Position = $FFFFFFFF then
      raise Exception.Create(
          'Ошибка установки указателя в пакетном файле :'
              + PackagePath);
    OpenSlots[SlotIndex].CurrentDataOffset := Position;
  end;
  Result := True;
end;
function TPackFileEC.GetEntrySlotPosition(SlotIndex: Cardinal): Cardinal;
begin
  Result := $FFFFFFFF;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  Result := OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
end;
function TPackFileEC.GetEntrySlotSize(SlotIndex: Cardinal): Cardinal;
begin
  Result := $FFFFFFFF;
  if SlotIndex = $FFFFFFFF then
    Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(
        PackSlotRangeError
            + SysUtils.IntToStr(High(OpenSlots))
            + ': '
            + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then
    Exit;
  Result := OpenSlots[SlotIndex].DataSize;
end;
constructor THsFolderEC.Create(FolderName: AnsiString);
begin
  EntryBuffer := nil;
  HeaderSize := 12;
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  Parent := nil;
  OriginalName := FolderName;
  UpperName := SysUtils.UpperCase(FolderName);
  ChangedFlag := False;
  InitializedEmptyFlag := False;
end;
constructor THsFolderEC.CreateChild(FolderName: AnsiString; Parent: THsFolderEC);
begin
  EntryBuffer := nil;
  HeaderSize := 12;
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  Self.Parent := Parent;
  OriginalName := FolderName;
  UpperName := SysUtils.UpperCase(FolderName);
  ChangedFlag := False;
  InitializedEmptyFlag := False;
end;
destructor THsFolderEC.Destroy;
begin
  Unload;
end;
function THsFolderEC.GetEntry(Index: Cardinal): PPackEntryEC;
begin
  if Index < EntryCount then
    Result := PPackEntryEC(PByte(EntryBuffer) + SizeOf(TPackEntryEC) * Index)
  else
    Result := nil
end;
function THsFolderEC.FindEntry(EntryName: AnsiString): PPackEntryEC;
var
  i: Integer;
  Entry: PPackEntryEC;
begin
  EntryName := SysUtils.UpperCase(EntryName);
  Result := nil;
  for i := 0 to EntryCount - 1 do
  begin
    Entry := GetEntry(i);
    if Entry.Flags = 0 then
      if SysUtils.StrComp(Entry.UpperName, PAnsiChar(EntryName)) = 0 then
      begin
        Result := Entry;
        Break;
      end;
  end;
end;
procedure THsFolderEC.InitializeEmpty;
begin
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  HeaderSize := EntryRecordSize * EntryCount + 12;
  EntryBuffer := nil;
  InitializedEmptyFlag := True;
  UpdateParentEntry;
end;
function THsFolderEC.Load(FileHandle, SubtreeOffset: Cardinal): Boolean;
// The last four disk bytes are a saved PE32 pointer, never a native pointer.
const
  DiskEntrySize = 158;
var
  BytesRead: Cardinal;
  I: Integer;
  Entry: PPackEntryEC;
  Folder: THsFolderEC;
  Disk: array[0..DiskEntrySize - 1] of Byte;
begin
  Result := False;
  if EntryBuffer <> nil then
    Exit;
  InitializedEmptyFlag := False;
  ChangedFlag := False;
  if Windows.SetFilePointer(FileHandle, SubtreeOffset, nil, FILE_BEGIN) <> SubtreeOffset then
    Exit;
  if not Windows.ReadFile(FileHandle, HeaderSize, 12, BytesRead, nil) or (BytesRead <> 12) then
    Exit;
  if (EntryRecordSize <> DiskEntrySize) or (EntryCount > 1000000) then
    Exit;
  EntryBuffer := AllocMem(EntryCount * SizeOf(TPackEntryEC));
  for I := 0 to Integer(EntryCount) - 1 do
  begin
    if not Windows.ReadFile(FileHandle, Disk, DiskEntrySize, BytesRead, nil)
        or (BytesRead <> DiskEntrySize) then
    begin
      Unload;
      Exit
    end;
    Entry := GetEntry(I);
    Move(Disk, Entry^, DiskEntrySize - 4);
    Entry.ChildFolder := nil;
    Entry.KindCopy := Entry.Kind;
  end;
  for I := 0 to Integer(EntryCount) - 1 do
  begin
    Entry := GetEntry(I);
    if (Entry.Kind = 3) and (Entry.Flags = 0) then
    begin
      Folder := THsFolderEC.CreateChild(Entry.OriginalName + '', Self);
      Entry.ChildFolder := Folder;
      if not Folder.Load(FileHandle, Entry.TargetOffset) then
      begin
        Unload;
        Exit
      end;
    end;
  end;
  Result := True;
end;
procedure THsFolderEC.Unload;
var
  i: Integer;
  Entry: PPackEntryEC;
  Folder: THsFolderEC;
begin
  if EntryBuffer <> nil then
  begin
    for i := 0 to EntryCount - 1 do
    begin
      Entry := GetEntry(i);
      if (Entry.Kind = 3) and (Entry.Flags = 0) then
      begin
        Folder := Entry.ChildFolder;
        if Folder <> nil then
          Folder.Free;
        Entry.ChildFolder := nil;
      end;
    end;
    FreeMem(EntryBuffer);
    EntryBuffer := nil;
    EntryCount := 0;
    HeaderSize := EntryCount * EntryRecordSize + 12;
    ChangedFlag := True;
    UpdateParentEntry;
  end;
end;
function THsFolderEC.ResolveEntryByPath(EntryPath: AnsiString): PPackEntryEC;
var
  Head, Tail: AnsiString;
  Entry: PPackEntryEC;
  Folder: THsFolderEC;
begin
  Result := nil;
  Head := AnsiBeforeFirstDelimiter(EntryPath, '/\');
  Tail := AnsiAfterFirstDelimiter(EntryPath, '/\');
  Entry := FindEntry(Head);
  if Entry <> nil then
  begin
    if Entry.Kind = 3 then
    begin
      if Tail = '' then
        Result := Entry
      else
      begin
        Folder := Entry.ChildFolder;
        Result := Folder.ResolveEntryByPath(Tail);
      end;
    end
    else if Tail = '' then
      Result := Entry;
  end;
end;
procedure THsFolderEC.UpdateParentEntry;
var
  Entry: PPackEntryEC;
begin
  if Parent <> nil then
  begin
    Entry := Parent.FindEntry(OriginalName);
    if Entry = nil then
      raise Exception.Create(
          'Сбой в файловой системе пакетного файла - Folder: '
              + UpperName);
    if Entry.Kind <> 3 then
      raise Exception.Create(
          'Конфликт имен файл/директория: ' + UpperName);
    Entry.StoredSize := HeaderSize;
    Entry.TargetOffset := 0;
    Parent.ChangedFlag := True;
  end;
end;
constructor TPackCollectionEC.Create;
var
  i: Integer;
begin
  NameToPackIndexHash := nil;
  UseFastNameIndex := False;
  LastPack := nil;
  FirstPack := nil;
  for i := Low(PackByIndex) to High(PackByIndex) do
    PackByIndex[i] := nil;
end;
destructor TPackCollectionEC.Destroy;
begin
  Clear(False);
end;
procedure TPackCollectionEC.Clear(FreePacks: Boolean);
var
  i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do
    PackByIndex[i] := nil;
  if NameToPackIndexHash <> nil then
  begin
    NameToPackIndexHash.Free;
    NameToPackIndexHash := nil;
  end;
  while FirstPack <> nil do
    RemovePack(FirstPack, FreePacks);
end;
procedure TPackCollectionEC.AddPackToFront(Pack: TPackFileEC);
var
  Item: TPackFileEC;
  Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do
    PackByIndex[i] := nil;
  if FirstPack = nil then
  begin
    FirstPack := Pack;
    LastPack := Pack;
    Pack.NextPack := nil;
    Pack.PrevPack := nil;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end
  else
  begin
    Pack.PrevPack := nil;
    Pack.NextPack := FirstPack;
    FirstPack.PrevPack := Pack;
    FirstPack := Pack;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end;
end;
procedure TPackCollectionEC.AddPackToBack(Pack: TPackFileEC);
var
  Item: TPackFileEC;
  Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do
    PackByIndex[i] := nil;
  if FirstPack = nil then
  begin
    FirstPack := Pack;
    LastPack := Pack;
    Pack.NextPack := nil;
    Pack.PrevPack := nil;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end
  else
  begin
    Pack.PrevPack := LastPack;
    Pack.NextPack := nil;
    LastPack.NextPack := Pack;
    LastPack := Pack;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end;
end;
procedure TPackCollectionEC.RemovePack(Pack: TPackFileEC; FreePack: Boolean);
var
  Item: TPackFileEC;
  Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do
    PackByIndex[i] := nil;
  if Pack.PrevPack <> nil then
    Pack.PrevPack.NextPack := Pack.NextPack;
  if Pack.NextPack <> nil then
    Pack.NextPack.PrevPack := Pack.PrevPack;
  if FirstPack = Pack then
    FirstPack := Pack.NextPack;
  if LastPack = Pack then
    LastPack := Pack.PrevPack;
  if FreePack then
    Pack.Free;
  Item := FirstPack;
  Count := 0;
  while Item <> nil do
  begin
    Item.CollectionIndex := Count;
    PackByIndex[Count] := Item;
    Inc(Count);
    Item := Item.NextPack;
  end;
end;
function TPackCollectionEC.OpenAllPackages: Boolean;
var
  Pack: TPackFileEC;
begin
  Result := False;
  if UseFastNameIndex then
  begin
    if NameToPackIndexHash <> nil then
      NameToPackIndexHash.Free;
    NameToPackIndexHash := THashEC.Create;
    NameToPackIndexHash.InitializeEmptyTable(Length(NameToPackIndexHash.Slots));
  end;
  Pack := FirstPack;
  while Pack <> nil do
  begin
    if not Pack.Open then
      Break;
    Pack := Pack.NextPack;
  end;
  if Pack <> nil then
  begin
    Pack := Pack.PrevPack;
    while Pack <> nil do
    begin
      Pack.Close;
      Pack := Pack.PrevPack;
    end;
    Exit;
  end;
  Result := True;
end;
function TPackCollectionEC.CloseAllPackages: Boolean;
var
  Pack: TPackFileEC;
begin
  Pack := FirstPack;
  while Pack <> nil do
  begin
    Pack.Close;
    Pack := Pack.NextPack;
  end;
  if NameToPackIndexHash <> nil then
  begin
    NameToPackIndexHash.Free;
    NameToPackIndexHash := nil;
  end;
  Result := True;
end;
function TPackCollectionEC.GetPackByIndex(PackIndex: Integer): TPackFileEC;
var
  Pack: TPackFileEC;
begin
  Pack := FirstPack;
  while Pack <> nil do
  begin
    if PackIndex = 0 then
      Break;
    Pack := Pack.NextPack;
    Dec(PackIndex);
  end;
  Result := Pack;
end;
function TPackCollectionEC.OpenEntryByPathAcrossPackages(
    EntryPath: AnsiString;
    DesiredAccess: Cardinal;
    FirstPackageOnly: Boolean
): Integer;
var
  Pack: TPackFileEC;
  Slot, Index, HashSlot, MappedIndex: Integer;
begin
  Result := -1;
  Index := 0;
  Slot := -1;
  if UseFastNameIndex and not FirstPackageOnly then
  begin
    HashSlot := NameToPackIndexHash.FindOrInsertKeySlot(EntryPath);
    if HashSlot <> -1 then
    begin
      MappedIndex := NameToPackIndexHash.GetSlotMappedValue(HashSlot);
      if MappedIndex = -1 then
      begin
        Pack := FirstPack;
        while Pack <> nil do
        begin
          Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
          if Slot <> -1 then
            Break;
          Pack := Pack.NextPack;
        end;
        if Slot = -1 then
          Exit;
        MappedIndex := Pack.CollectionIndex;
        NameToPackIndexHash.SetSlotMappedValue(HashSlot, MappedIndex);
      end
      else
      begin
        Pack := PackByIndex[MappedIndex];
        Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
        if Slot = -1 then
          NameToPackIndexHash.NoteStaleMappedValue;
      end;
      if Slot <> -1 then
      begin
        Result := MappedIndex * PackOpenSlotCount + Slot;
        Exit;
      end;
    end;
  end;
  Pack := FirstPack;
  while Pack <> nil do
  begin
    Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
    if Slot <> -1 then
      Break;
    if FirstPackageOnly then
      Exit;
    Pack := Pack.NextPack;
    Inc(Index);
  end;
  if Slot <> -1 then
    Result := Index * PackOpenSlotCount + Slot;
end;
function TPackCollectionEC.CreateLooseFile(FilePath: WideString): Integer;
var
  Slot: Integer;
begin
  Result := -1;
  if FirstPack <> nil then
  begin
    Slot := FirstPack.CreateLooseFile(FilePath);
    if Slot <> -1 then
      Result := Slot;
  end;
end;
function TPackCollectionEC.CloseEntryHandle(Handle: Integer): Boolean;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.CloseEntrySlot(Handle - Index * PackOpenSlotCount);
end;
function TPackCollectionEC.ReadEntryHandle(
    Handle: Integer;
    var Buffer;
    ByteCount: Cardinal
): Boolean;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.ReadEntrySlot(Handle - Index * PackOpenSlotCount, @Buffer, ByteCount);
end;
function TPackCollectionEC.WriteEntryHandle(
    Handle: Integer;
    var Buffer;
    ByteCount: Cardinal
): Boolean;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.WriteEntrySlot(Handle - Index * PackOpenSlotCount, @Buffer, ByteCount);
end;
function TPackCollectionEC.SeekEntryHandle(
    Handle: Integer;
    Offset: Cardinal;
    Origin: Integer
): Boolean;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.SeekEntrySlot(Handle - Index * PackOpenSlotCount, Offset, Origin);
end;
function TPackCollectionEC.GetEntryHandlePosition(Handle: Integer): Cardinal;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := $FFFFFFFF;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.GetEntrySlotPosition(Handle - Index * PackOpenSlotCount);
end;
function TPackCollectionEC.GetEntryHandleSize(Handle: Integer): Cardinal;
var
  Pack: TPackFileEC;
  Index: Integer;
begin
  Result := $FFFFFFFF;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then
    Result := Pack.GetEntrySlotSize(Handle - Index * PackOpenSlotCount);
end;
function MatchLookupKeySuffix(
    var Key: AnsiString;
    SuffixBytes: Pointer;
    SuffixLength: Integer
): Boolean;
var
  i, j, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then
    First := KeyLength - 31
  else
    First := 1;
  j := 0;
  Result := True;
  for i := First to KeyLength do
  begin
    if Key[i] <> PAnsiChar(SuffixBytes)[j] then
    begin
      Result := False;
      Break
    end;
    Inc(j);
  end;
end;
procedure CopyLookupKeySuffix(DestSuffixBytes: Pointer; SuffixLength: Integer; var Key: AnsiString);
var
  i, j, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then
    First := KeyLength - 31
  else
    First := 1;
  j := 0;
  for i := First to KeyLength do
  begin
    PAnsiChar(DestSuffixBytes)[j] := Key[i];
    Inc(j);
  end;
end;
constructor THashEC.Create;
begin
  InitializeEmptyTable(Length(Slots));
end;
destructor THashEC.Destroy;
begin
  ReleaseTable;
end;
function THashEC.ComputeLookupBucketAndFullHash(
    var Key: AnsiString;
    out FullHash: Cardinal
): Integer;
var
  Hash: Cardinal;
  i, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then
    First := KeyLength - 31
  else
    First := 1;
  Hash := 0;
  for i := First to KeyLength do
    Hash := Ord(Key[i]) + Hash * 2;
  FullHash := Hash;
  Result := Hash and High(Slots);
end;
function THashEC.FindOrInsertKeySlot(Key: AnsiString): Integer;
var
  Bucket, Hash, i: Cardinal;
  Found: Integer;
  Temp: THashSlotEC;
begin
  Bucket := ComputeLookupBucketAndFullHash(Key, Hash);
  Found := -1;
  for i := Bucket to Bucket + 5 do
  begin
    if Slots[i].MappedValue <> -1 then
    begin
      if (Slots[i].FullHash = Hash) and MatchLookupKeySuffix(Key, @Slots[i].KeySuffix, 32) then
      begin
        Found := i;
        Inc(Slots[i].HitCount);
        Inc(OperationCount);
        Inc(HitCount);
        Inc(HitCountCopy);
        MaybeResetStatistics;
        if (i > Bucket) and (i < Cardinal(Length(Slots))) then
          if Slots[i].HitCount > Slots[i - 1].HitCount then
          begin
            Temp := Slots[i];
            Slots[i] := Slots[i - 1];
            Slots[i - 1] := Temp;
          end;
        Break;
      end;
    end
    else
    begin
      Slots[i].FullHash := Hash;
      Slots[i].HitCount := 1;
      Slots[i].Unknown0C := 1;
      CopyLookupKeySuffix(@Slots[i].KeySuffix, 32, Key);
      Found := i;
      Inc(OperationCount);
      Inc(MissCount);
      MaybeResetStatistics;
      Break;
    end;
    if i > High(Slots) then
      Break;
  end;
  if Found = -1 then
  begin
    Inc(OperationCount);
    Inc(MissCount);
    MaybeResetStatistics;
  end;
  Result := Found;
end;
procedure THashEC.SetSlotMappedValue(SlotIndex, Value: Integer);
begin
  Slots[SlotIndex].MappedValue := Value;
end;
function THashEC.InitializeEmptyTable(BucketCount: Integer): Boolean;
var
  i: Integer;
begin
  OperationCount := 0;
  HitCount := 0;
  HitCountCopy := 0;
  StaleValueCount := 0;
  MissCount := 0;
  for i := Low(Slots) to High(Slots) do
    Slots[i].MappedValue := -1;
  Result := True;
end;
function THashEC.ReleaseTable: Boolean;
begin
  Result := True;
end;
function THashEC.GetSlotMappedValue(SlotIndex: Integer): Integer;
begin
  Result := Slots[SlotIndex].MappedValue;
end;
procedure THashEC.MaybeResetStatistics;
begin
  if (OperationCount mod 100 = 0) and (OperationCount <> 0) then
  begin
    OperationCount := 0;
    HitCount := 0;
    HitCountCopy := 0;
    StaleValueCount := 0;
    MissCount := 0;
  end;
end;
procedure THashEC.NoteStaleMappedValue;
begin
  Inc(StaleValueCount);
end;
end.
