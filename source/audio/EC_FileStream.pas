{$EXCESSPRECISION OFF}
unit EC_FileStream;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Thread,
  EC_File,
  SyncObjs;
type
  TFileStreamEC = class;
  TFileStreamEC = class(TThreadEC)
    BlockSize: Integer;
    BufferCapacity: Integer;
    ReadBuffer: Pointer;
    ReadAvailable: Integer;
    ReadPosition: Integer;
    FillBuffer: Pointer;
    FillAvailable: Integer;
    SourceFile: TFileEC;
    FileSize: Integer;
    EndOfFile: Boolean;
    Gap51: array[0..2] of Byte;
    BufferLock: TCriticalSection;
    procedure Execute; override;
    constructor Create(BufferBytes: Integer; const FileName: WideString);
    destructor Destroy; override;
    procedure SwapBuffers;
    function Read(Destination: Pointer; ByteCount: Integer): Integer;
  end;
implementation
uses
  Math,
  SysUtils,
  EC_Mem,
  Windows;

constructor TFileStreamEC.Create(BufferBytes: Integer; const FileName: WideString);
begin
  inherited Create;
  BufferLock := TCriticalSection.Create;
  SourceFile := TFileEC.Create;
  SourceFile.SetFileName(FileName);
  SourceFile.AcquireReadHandle(False);
  EndOfFile := False;
  FileSize := SourceFile.GetSize;
  BlockSize := 4096;
  BufferCapacity := (BufferBytes div BlockSize) * BlockSize + BlockSize;
  ReadBuffer := AllocEC(BufferCapacity);
  FillBuffer := AllocEC(BufferCapacity);
  SetPriority(ThreadPriorityLowest);
  Start;
end;

destructor TFileStreamEC.Destroy;
begin
  RequestStop;
  if IsRunning then
    WaitForIdle(INFINITE);
  if SourceFile <> nil then
  begin
    SourceFile.Free;
    SourceFile := nil;
  end;
  if ReadBuffer <> nil then
  begin
    FreeEC(ReadBuffer);
    ReadBuffer := nil;
  end;
  if FillBuffer <> nil then
  begin
    FreeEC(FillBuffer);
    FillBuffer := nil;
  end;
  BlockSize := 0;
  BufferCapacity := 0;
  if BufferLock <> nil then
  begin
    BufferLock.Free;
    BufferLock := nil;
  end;
  inherited Destroy;
end;

procedure TFileStreamEC.SwapBuffers;
var
  Buffer: Pointer;
  Available: Integer;
begin
  Buffer := ReadBuffer;
  ReadBuffer := FillBuffer;
  FillBuffer := Buffer;
  Available := ReadAvailable;
  ReadAvailable := FillAvailable;
  FillAvailable := Available;
  ReadPosition := 0;
end;

procedure TFileStreamEC.Execute;
var
  ByteCount: Integer;
begin
  while not IsStopRequested and not EndOfFile do
  begin
    if FillAvailable >= BufferCapacity then
    begin
      BufferLock.Enter;
      if ReadAvailable > 0 then
      begin
        BufferLock.Leave;
        Exit;
      end;
      SwapBuffers;
      BufferLock.Leave;
    end;
    ByteCount := BlockSize;
    if FileSize - Integer(SourceFile.GetPointer) < ByteCount then
      ByteCount := FileSize - Integer(SourceFile.GetPointer);
    if ByteCount <= 0 then
    begin
      EndOfFile := True;
      Exit;
    end;
    SourceFile.ReadBuffer(AddPointerOffset(FillBuffer, FillAvailable), ByteCount);
    Inc(FillAvailable, ByteCount);
    if Integer(SourceFile.GetPointer) > FileSize then
      EndOfFile := True;
    SysUtils.Sleep(0);
  end;
end;

function TFileStreamEC.Read(Destination: Pointer; ByteCount: Integer): Integer;
var
  Chunk, Total: Integer;
begin
  Total := 0;
  BufferLock.Enter;
  Chunk := ByteCount;
  if Chunk > ReadAvailable then
    Chunk := ReadAvailable;
  if Chunk > 0 then
  begin
    CopyMemory(Destination, AddPointerOffset(ReadBuffer, ReadPosition), Chunk);
    Inc(ReadPosition, Chunk);
    Dec(ReadAvailable, Chunk);
    Destination := AddPointerOffset(Destination, Chunk);
    Dec(ByteCount, Chunk);
    Inc(Total, Chunk);
  end;
  BufferLock.Leave;
  if ByteCount <= 0 then
  begin
    Result := Total;
    Exit;
  end;
  if IsRunning then
  begin
    RequestStop;
    WaitForIdle(INFINITE);
  end;
  while True do
  begin
    Chunk := ByteCount;
    if Chunk > ReadAvailable then
      Chunk := ReadAvailable;
    if Chunk > 0 then
    begin
      CopyMemory(Destination, AddPointerOffset(ReadBuffer, ReadPosition), Chunk);
      Inc(ReadPosition, Chunk);
      Dec(ReadAvailable, Chunk);
      Destination := AddPointerOffset(Destination, Chunk);
      Dec(ByteCount, Chunk);
      Inc(Total, Chunk);
    end;
    if ByteCount <= 0 then
      Break;
    SwapBuffers;
    Chunk := ByteCount;
    if Chunk > ReadAvailable then
      Chunk := ReadAvailable;
    if Chunk > 0 then
    begin
      CopyMemory(Destination, AddPointerOffset(ReadBuffer, ReadPosition), Chunk);
      Inc(ReadPosition, Chunk);
      Dec(ReadAvailable, Chunk);
      Destination := AddPointerOffset(Destination, Chunk);
      Dec(ByteCount, Chunk);
      Inc(Total, Chunk);
    end;
    if (ByteCount <= 0) or EndOfFile then
      Break;
    Chunk := BufferCapacity;
    if FileSize - Integer(SourceFile.GetPointer) < Chunk then
      Chunk := FileSize - Integer(SourceFile.GetPointer);
    if Chunk <= 0 then
    begin
      EndOfFile := True;
      Break;
    end;
    SourceFile.ReadBuffer(AddPointerOffset(FillBuffer, FillAvailable), Chunk);
    Inc(FillAvailable, Chunk);
    if Integer(SourceFile.GetPointer) > FileSize then
      EndOfFile := True;
  end;
  if not EndOfFile then
    Start;
  Result := Total;
end;

end.
