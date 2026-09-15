{$EXCESSPRECISION OFF}
unit EC_Buf;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_File,
  EC_Struct;
type
  TBufEC = class;
  TBufEC = class(TObjectEx)
    DataSize: Integer;
    Capacity: Integer;
    Position: Integer;
    Data: Pointer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetSize(NewSize: Integer);
    function IsAtEnd: Boolean;
    procedure SetPosition(NewPosition: Integer);
    procedure EnsureWriteCapacity(AddedBytes: Integer);
    procedure EnsureWriteCapacityAtOffset(Offset: Integer; AddedBytes: Integer);
    procedure EnsureReadable(Bytes: Integer);
    procedure EnsureReadableAtOffset(Offset: Integer; Bytes: Integer);
    procedure SetByteAt(Offset: Integer; Value: Byte);
    procedure SetInt32At(Offset: Integer; Value: Integer);
    procedure AddBytes(Source: Pointer; ByteCount: Integer);
    procedure AddAnsiStringZ(const Value: AnsiString);
    procedure AddWideStringZ(const Value: WideString);
    procedure AddAnsiStringRaw(const Value: AnsiString);
    procedure AddWideStringRaw(const Value: WideString);
    procedure AddByte(Value: Byte);
    procedure AddWord(Value: Word);
    procedure AddInt32(Value: Integer);
    procedure AddInteger(Value: Integer);
    procedure AddAnsiChar(Value: AnsiChar);
    procedure AddWideChar(Value: WideChar);
    procedure AddDWord(Value: Cardinal);
    procedure AddIntegerValue(Value: Integer);
    procedure AddSingle(Value: Single);
    procedure AddDouble(Value: Double);
    procedure AddBoolean(Value: Boolean);
    procedure AddBuffer(Value: TBufEC);
    function GetByteAt(Offset: Integer): Byte;
    function GetUInt32At(Offset: Integer): Cardinal;
    function GetInt32At(Offset: Integer): Integer;
    function ReadBytes(Dest: Pointer; ByteCount: Integer): Pointer;
    function ReadWideStringToBuffer(Dest: PWideChar): PWideChar;
    function GetByte: Byte;
    function GetWideChar: WideChar;
    function GetWord: Word;
    function GetUInt32: Cardinal;
    function GetInt32: Integer;
    function GetSingle: Single;
    function GetDouble: Double;
    function GetBoolean: Boolean;
    procedure ReadLengthPrefixedBuffer(Dest: TBufEC);
    function GetWideStringLength: Integer;
    function GetWideStringLengthAt(Offset: Integer): Integer;
    function GetAnsiTextLineLength: Integer;
    function GetAnsiTextLineLengthAt(Offset: Integer): Integer;
    function GetWideTextLineLength: Integer;
    function GetWideTextLineLengthAt(Offset: Integer): Integer;
    function ReadAnsiTextLineToBuffer(Dest: PAnsiChar): PAnsiChar;
    function ReadAnsiTextLine: AnsiString;
    function ReadWideTextLineToBuffer(Dest: PWideChar): PWideChar;
    function ReadWideTextLine: WideString;
    function ReadWideString: WideString;
    function CompressZlibPayloadInPlace(FastMode: Boolean): Boolean;
    function ExpandZlibPayloadInPlace: Boolean;
    procedure ApplyDatXorCipher(Seed: Integer);
    function ComputeCrc32: Cardinal;
    function ComputeCrc32Range(StartOffset: Integer; EndOffset: Integer): Cardinal;
    procedure UpdateEmbeddedCrc32(StartOffset: Integer; EndOffset: Integer; CrcOffset: Integer);
    procedure LoadFromFileChunk(SourceFile: TFileEC; ByteCount: Integer);
    procedure LoadFromFile(SourceFile: TFileEC);
    procedure LoadFromWideFilePath(FileName: PWideChar);
    procedure SaveToFile(DestFile: TFileEC);
  end;
implementation
uses
  ZLib,
  CrcUnit,
  EC_Mem,
  GR_Main,
  Math,
  SysUtils,
  Windows;
const
  BufferGrowthSlack = 256;
  CarriageReturnCode = 13;
  LineFeedCode = 10;

constructor TBufEC.Create;
begin
  inherited Create
end;

destructor TBufEC.Destroy;
begin
  Clear;
  inherited Destroy
end;

procedure TBufEC.Clear;
begin
  if Data <> nil then
  begin
    FreeEC(Data);
    Data := nil;
  end;
  DataSize := 0;
  Capacity := 0;
  Position := 0;
end;

procedure TBufEC.SetSize(NewSize: Integer);
begin
  if NewSize < 1 then
    Clear
  else
  begin
    DataSize := NewSize;
    Capacity := NewSize + BufferGrowthSlack;
    Data := ReAllocREC(Data, Capacity);
    if Position > DataSize then
      Position := DataSize;
  end;
end;

function TBufEC.IsAtEnd: Boolean;
begin
  if Position >= DataSize then
    Result := True
  else
    Result := False;
end;

procedure TBufEC.SetPosition(NewPosition: Integer);
begin
  if (NewPosition < 0) or (NewPosition > DataSize) then
    raise Exception.Create('TBufEC.PointerSet. zn=' + SysUtils.IntToStr(NewPosition));
  Position := NewPosition;
end;

procedure TBufEC.EnsureWriteCapacity(AddedBytes: Integer);
begin
  if AddedBytes < 1 then
    raise Exception.Create('TBufEC.TestAddLenBuf. addlen=' + SysUtils.IntToStr(AddedBytes));
  if Position + AddedBytes > DataSize then
  begin
    DataSize := Position + AddedBytes;
    if DataSize > Capacity then
    begin
      Capacity := Max(Capacity * 2, DataSize + BufferGrowthSlack);
      Data := ReAllocREC(Data, Capacity);
    end;
  end;
end;

procedure TBufEC.EnsureWriteCapacityAtOffset(Offset, AddedBytes: Integer);
begin
  if (AddedBytes < 1) or (Offset < 0) or (Offset > DataSize) then
    raise Exception.Create(
        'TBufEC.TestAddLenBuf. sme='
            + SysUtils.IntToStr(Offset)
            + ' addlen='
            + SysUtils.IntToStr(AddedBytes));
  if Offset + AddedBytes > DataSize then
  begin
    DataSize := Offset + AddedBytes;
    if DataSize > Capacity then
    begin
      Capacity := Max(Capacity * 2, DataSize + BufferGrowthSlack);
      Data := ReAllocREC(Data, Capacity);
    end;
  end;
end;

procedure TBufEC.EnsureReadable(Bytes: Integer);
begin
  if (Bytes < 1) or (Position + Bytes > DataSize) then
    raise Exception.Create('TBufEC.TestGet. len=' + SysUtils.IntToStr(Bytes));
end;

procedure TBufEC.EnsureReadableAtOffset(Offset, Bytes: Integer);
begin
  if (Bytes < 1) or (Offset + Bytes > DataSize) then
    raise Exception.Create(
        'TBufEC.TestGet. sme=' + SysUtils.IntToStr(Offset) + ' len=' + SysUtils.IntToStr(Bytes));
end;

procedure TBufEC.SetByteAt(Offset: Integer; Value: Byte);
begin
  EnsureWriteCapacityAtOffset(Offset, 1);
  WriteByteEC(Pointer(PtrUInt(Data) + Offset), Value);
end;

procedure TBufEC.SetInt32At(Offset: Integer; Value: Integer);
begin
  EnsureWriteCapacityAtOffset(Offset, 4);
  WriteIntegerEC(Pointer(PtrUInt(Data) + Offset), Value);
end;

procedure TBufEC.AddBytes(Source: Pointer; ByteCount: Integer);
begin
  EnsureWriteCapacity(ByteCount);
  Windows.CopyMemory(AddPointerOffset(Data, Position), Source, ByteCount);
  Inc(Position, ByteCount);
end;

procedure TBufEC.AddAnsiStringZ(const Value: AnsiString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value);
  EnsureWriteCapacity(ByteCount + 1);
  Windows.CopyMemory(AddPointerOffset(Data, Position), PAnsiChar(Value), ByteCount + 1);
  Position := Position + ByteCount + 1;
end;

procedure TBufEC.AddWideStringZ(const Value: WideString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value) * SizeOf(WideChar);
  EnsureWriteCapacity(ByteCount + SizeOf(WideChar));
  Windows
      .CopyMemory(AddPointerOffset(Data, Position), PWideChar(Value), ByteCount + SizeOf(WideChar));
  Position := Position + ByteCount + SizeOf(WideChar);
end;

procedure TBufEC.AddAnsiStringRaw(const Value: AnsiString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value);
  if ByteCount > 0 then
  begin
    EnsureWriteCapacity(ByteCount);
    Windows.CopyMemory(AddPointerOffset(Data, Position), PAnsiChar(Value), ByteCount);
    Inc(Position, ByteCount);
  end;
end;

procedure TBufEC.AddWideStringRaw(const Value: WideString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value) * SizeOf(WideChar);
  if ByteCount > 0 then
  begin
    EnsureWriteCapacity(ByteCount);
    Windows.CopyMemory(AddPointerOffset(Data, Position), PWideChar(Value), ByteCount);
    Inc(Position, ByteCount);
  end;
end;

procedure TBufEC.AddByte(Value: Byte);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddWord(Value: Word);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteWordEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddInt32(Value: Integer);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteIntegerEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddInteger(Value: Integer);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteInt32EC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddAnsiChar(Value: AnsiChar);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Byte(Value));
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddWideChar(Value: WideChar);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteWordEC(AddPointerOffset(Data, Position), Word(Value));
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddDWord(Value: Cardinal);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteIntegerEC(AddPointerOffset(Data, Position), Integer(Value));
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddIntegerValue(Value: Integer);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteInt32EC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddSingle(Value: Single);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteSingleEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddDouble(Value: Double);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteDoubleEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddBoolean(Value: Boolean);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Byte(Value));
  Inc(Position, SizeOf(Value));
end;

procedure TBufEC.AddBuffer(Value: TBufEC);
begin
  AddDWord(Value.DataSize);
  if Value.DataSize > 0 then
    AddBytes(Value.Data, Value.DataSize);
end;

function TBufEC.GetByteAt(Offset: Integer): Byte;
begin
  EnsureReadableAtOffset(Offset, 1);
  Result := ReadByteEC(Pointer(PtrUInt(Data) + Offset));
end;

function TBufEC.GetUInt32At(Offset: Integer): Cardinal;
begin
  EnsureReadableAtOffset(Offset, 4);
  Result := ReadDWordEC(Pointer(PtrUInt(Data) + Offset));
end;

function TBufEC.GetInt32At(Offset: Integer): Integer;
begin
  EnsureReadableAtOffset(Offset, 4);
  Result := ReadIntegerEC(Pointer(PtrUInt(Data) + Offset));
end;

function TBufEC.ReadBytes(Dest: Pointer; ByteCount: Integer): Pointer;
begin
  EnsureReadable(ByteCount);
  Windows.CopyMemory(Dest, AddPointerOffset(Data, Position), ByteCount);
  Inc(Position, ByteCount);
  Result := Dest;
end;

function TBufEC.ReadWideStringToBuffer(Dest: PWideChar): PWideChar;
var
  Count: Integer;
begin
  Count := GetWideStringLengthAt(Position);
  if Count > 0 then
  begin
    EnsureReadable(Count * 2 + 2);
    Windows.CopyMemory(Dest, Pointer(PtrUInt(Data) + Position), Count * 2 + 2);
    Position := Position + Count * 2 + 2;
  end
  else
  begin
    Inc(Position, 2);
    Dest^ := #0;
  end;
  Result := Dest;
end;

function TBufEC.GetByte: Byte;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
end;

function TBufEC.GetWideChar: WideChar;
begin
  EnsureReadable(2);
  Result := ReadWideCharEC(Pointer(PtrUInt(Data) + Position));
  Inc(Position, 2);
end;

function TBufEC.GetWord: Word;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
end;

function TBufEC.GetUInt32: Cardinal;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
end;

function TBufEC.GetInt32: Integer;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
end;

function TBufEC.GetSingle: Single;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
  if IsNan(Result) then
  begin
    Result := 0;
    AppendLogLineThreadSafe('Warning! NaN encountered, replaced with zero.')
  end;
end;

function TBufEC.GetDouble: Double;
begin
  EnsureReadable(8);
  Result := ReadDoubleEC(Pointer(PtrUInt(Data) + Position));
  if IsNan(Result) then
  begin
    Result := 0;
    AppendLogLineThreadSafe('Warning! NaN encountered, replaced with zero.');
  end;
  Inc(Position, 8);
end;

function TBufEC.GetBoolean: Boolean;
begin
  EnsureReadable(SizeOf(Result));
  Move((PByte(Data) + Position)^, Result, SizeOf(Result));
  Inc(Position, SizeOf(Result));
end;

procedure TBufEC.ReadLengthPrefixedBuffer(Dest: TBufEC);
var
  ByteCount: Integer;
begin
  ByteCount := GetUInt32;
  Dest.SetSize(ByteCount);
  if ByteCount > 0 then
    ReadBytes(Dest.Data, ByteCount);
end;

function TBufEC.GetWideStringLength: Integer;
begin
  Result := GetWideStringLengthAt(Position)
end;

function TBufEC.GetWideStringLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;
begin
  Cursor := Offset;
  Count := 0;
  while Cursor + 1 < DataSize do
  begin
    if ReadWordEC(AddPointerOffset(Data, Cursor)) = 0 then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, SizeOf(WideChar));
  end;
  Result := Count;
end;

function TBufEC.GetAnsiTextLineLength: Integer;
begin
  Result := GetAnsiTextLineLengthAt(Position)
end;

function TBufEC.GetAnsiTextLineLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;
  Ch: Byte;
begin
  Cursor := Offset;
  Count := 0;
  while Cursor < DataSize do
  begin
    Ch := ReadByteEC(AddPointerOffset(Data, Cursor));
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, 1);
  end;
  Result := Count;
end;

function TBufEC.GetWideTextLineLength: Integer;
begin
  Result := GetWideTextLineLengthAt(Position)
end;

function TBufEC.GetWideTextLineLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;
  Ch: Word;
begin
  Cursor := Offset;
  Count := 0;
  while Cursor + 1 < DataSize do
  begin
    Ch := ReadWordEC(AddPointerOffset(Data, Cursor));
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, SizeOf(WideChar));
  end;
  Result := Count;
end;

function TBufEC.ReadAnsiTextLineToBuffer(Dest: PAnsiChar): PAnsiChar;
var
  Count: Integer;
  Ch: Byte;
begin
  Count := GetAnsiTextLineLength;
  if Count > 0 then
  begin
    Windows.CopyMemory(Dest, Pointer(PtrUInt(Data) + Position), Count);
    Dest[Count] := #0;
    Inc(Position, Count);
  end
  else
    Dest^ := #0;
  if Position < DataSize then
  begin
    Ch := ReadByteEC(Pointer(PtrUInt(Data) + Position));
    if (Ch = 0) or (Ch = 13) or (Ch = 10) then
      Inc(Position, 1);
    if Position < DataSize then
    begin
      Ch := ReadByteEC(Pointer(PtrUInt(Data) + Position));
      if (Ch = 0) or (Ch = 13) or (Ch = 10) then
        Inc(Position, 1);
    end;
  end;
  Result := Dest;
end;

function TBufEC.ReadAnsiTextLine: AnsiString;
var
  Count: Integer;
begin
  Count := GetAnsiTextLineLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadAnsiTextLineToBuffer(PAnsiChar(Result));
  end
  else
  begin
    SetLength(Result, 2);
    ReadAnsiTextLineToBuffer(PAnsiChar(Result));
    Result := '';
  end;
end;

function TBufEC.ReadWideTextLineToBuffer(Dest: PWideChar): PWideChar;
var
  Count: Integer;
  Ch: Word;
begin
  Count := GetWideTextLineLength;
  if Count > 0 then
  begin
    Windows.CopyMemory(Dest, Pointer(PtrUInt(Data) + Position), Count * 2);
    Dest[Count] := #0;
    Inc(Position, Count * 2);
  end
  else
    Dest^ := #0;
  if Position + 1 < DataSize then
  begin
    Ch := ReadWordEC(Pointer(PtrUInt(Data) + Position));
    if (Ch = 0) or (Ch = 13) or (Ch = 10) then
      Inc(Position, 2);
    if Position + 1 < DataSize then
    begin
      Ch := ReadWordEC(Pointer(PtrUInt(Data) + Position));
      if (Ch = 0) or (Ch = 13) or (Ch = 10) then
        Inc(Position, 2);
    end;
  end;
  Result := Dest;
end;

function TBufEC.ReadWideTextLine: WideString;
var
  Count: Integer;
begin
  Count := GetWideTextLineLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadWideTextLineToBuffer(PWideChar(Result));
  end
  else
  begin
    SetLength(Result, 2);
    ReadWideTextLineToBuffer(PWideChar(Result));
    Result := '';
  end;
end;

function TBufEC.ReadWideString: WideString;
var
  Count: Integer;
begin
  Count := GetWideStringLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadWideStringToBuffer(PWideChar(Result));
    SetLength(Result, Count);
  end
  else
  begin
    SetLength(Result, 1);
    ReadWideStringToBuffer(@Count);
    SetLength(Result, 0);
    Result := '';
  end;
end;

function TBufEC.CompressZlibPayloadInPlace(FastMode: Boolean): Boolean;
var
  N: Integer;
  Buffer: Pointer;
begin
  Result := False;
  if DataSize < 8 then
    Exit;
  Buffer := AllocEC(DataSize);
  N := OKGF_ZLib_Compress(Buffer, Data, DataSize, Ord(FastMode));
  if N = 0 then
  begin
    FreeEC(Buffer);
    Exit
  end;
  FreeEC(Data);
  Data := Buffer;
  DataSize := N;
  Capacity := N;
  Position := 0;
  Result := True
end;

function TBufEC.ExpandZlibPayloadInPlace: Boolean;
var
  ByteCount: Integer;
  Buffer: Pointer;
begin
  if DataSize < 8 then
  begin
    Result := False;
    Exit;
  end;
  ByteCount := OKGF_ZLib_UnCompress(nil, 0, Data, DataSize);
  if ByteCount = 0 then
  begin
    Result := False;
    Exit;
  end;
  Buffer := AllocEC(ByteCount);
  ByteCount := OKGF_ZLib_UnCompress(Buffer, ByteCount, Data, DataSize);
  if ByteCount = 0 then
  begin
    FreeEC(Buffer);
    Result := False;
    Exit;
  end;
  FreeEC(Data);
  Data := Buffer;
  DataSize := ByteCount;
  Capacity := ByteCount;
  Position := 0;
  Result := True;
end;

procedure TBufEC.ApplyDatXorCipher(Seed: Integer);
var
  State, i: Integer;
  Cursor: PByte;
  function StepDatXorSeedState: Integer; // @addr 0x86D108 @ida "int __cdecl $name(void *ParentFrame);" @note "Nested helper of TBufEC.ApplyDatXorCipher; requires its parent stack frame."
  begin
    State := 16807 * (State mod 127773) - 2836 * (State div 127773);
    if State <= 0 then
      State := State + $7FFFFFFF;
    Result := State - 1;
  end;
begin
  State := Seed;
  Cursor := Data;
  for i := 0 to DataSize - 1 do
  begin
    Cursor^ := Cursor^ xor Byte(StepDatXorSeedState);
    Cursor := PByte(PtrUInt(Cursor) + 1);
  end;
end;

function TBufEC.ComputeCrc32: Cardinal;
begin
  Result := CrcUnit.ComputeCrc32(Data, DataSize)
end;

function TBufEC.ComputeCrc32Range(StartOffset, EndOffset: Integer): Cardinal;
begin
  Result := CrcUnit.ComputeCrc32(Pointer(PtrUInt(Data) + StartOffset), EndOffset - StartOffset)
end;

procedure TBufEC.UpdateEmbeddedCrc32(StartOffset, EndOffset, CrcOffset: Integer);
var
  WholeCrc, PreviousPrefixCrc, NewPrefixCrc: Cardinal;
begin
  if CrcOffset < StartOffset then
    raise Exception.Create('CRC update error');
  if CrcOffset + 8 > EndOffset then
    raise Exception.Create('CRC update error');
  WholeCrc := ExtendCrc32(0, Pointer(PtrUInt(Data) + StartOffset), EndOffset - StartOffset);
  PreviousPrefixCrc :=
      ExtendCrc32(0, Pointer(PtrUInt(Data) + StartOffset), CrcOffset - StartOffset + 8);
  PCardinal(PtrUInt(Data) + CrcOffset)^ := WholeCrc;
  NewPrefixCrc := ExtendCrc32(0, Pointer(PtrUInt(Data) + StartOffset), CrcOffset - StartOffset + 4);
  WriteCrc32Correction(NewPrefixCrc, PreviousPrefixCrc, Pointer(CrcOffset + 4 + PtrUInt(Data)));
end;

procedure TBufEC.LoadFromFileChunk(SourceFile: TFileEC; ByteCount: Integer);
var
  ChunkSize: Integer;
  Cursor: Pointer;
  NextChunkSize: Integer;
begin
  Self.Clear;
  SourceFile.AcquireReadWriteHandle;
  try
    Self.SetSize(ByteCount);
    Cursor := Self.Data;
    if (ByteCount > 0) then
    begin
      repeat
        if (ByteCount > 262144) then
        begin
          NextChunkSize := 262144;
        end
        else
        begin
          NextChunkSize := ByteCount;
        end;
        ChunkSize := NextChunkSize;
        SourceFile.ReadBuffer(Cursor, ChunkSize);
        Cursor := AddPointerOffset(Cursor, ChunkSize);
        ByteCount := (ByteCount - ChunkSize);
        // Native yields for 1 ms after every 256 KiB. The host uses preemptive
        // worker threads; sleeping here only stalls loading while FileLock is
        // held, including other threads waiting to read unrelated resources.
      until ByteCount <= 0;
    end;
  except
    Self.Clear;
  end;
  SourceFile.ReleaseHandle;
  Exit;
end;

procedure TBufEC.LoadFromFile(SourceFile: TFileEC);
var
  ByteCount: Integer;
begin
  Clear;
  SourceFile.AcquireReadWriteHandle;
  try
    ByteCount := SourceFile.GetSize - SourceFile.GetPointer;
    SetSize(ByteCount);
    SourceFile.ReadBuffer(Data, ByteCount);
  except
    Clear;
  end;
  SourceFile.ReleaseHandle;
end;

procedure TBufEC.LoadFromWideFilePath(FileName: PWideChar);
var
  SourceFile: TFileEC;
begin
  SourceFile := TFileEC.Create;
  try
    SourceFile.SetFileName(WideString(FileName));
    SourceFile.AcquireReadHandle(False);
    LoadFromFile(SourceFile);
  finally
    SourceFile.Free;
  end;
end;

procedure TBufEC.SaveToFile(DestFile: TFileEC);
begin
  DestFile.WriteBuffer(Data, DataSize)
end;

end.
