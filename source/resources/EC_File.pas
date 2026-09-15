{$EXCESSPRECISION OFF}
unit EC_File;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct;
type
  TFileEC = class;
  TFileEC = class(TObjectEx)
    Handle: Integer;
    OpenDepth: Integer;
    FileName: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure SetFileName(NewFileName: WideString);
    procedure AcquireReadWriteHandle;
    procedure AcquireReadHandle(FirstPackageOnly: Boolean);
    function TryAcquireReadHandle(FirstPackageOnly: Boolean): Boolean;
    procedure CreateNew;
    procedure ReleaseHandle;
    function GetSize: Cardinal;
    function GetFileName: WideString;
    function SetPointer(Offset: Cardinal; Origin: Integer): Cardinal;
    function GetPointer: Cardinal;
    procedure ReadBuffer(Dest: Pointer; ByteCount: Cardinal);
    procedure WriteBuffer(Source: Pointer; ByteCount: Cardinal);
    function ReadWideString: WideString;
  end;
implementation
uses
  Math,
  EC_HsFile,
  SyncObjs,
  SysUtils,
  Windows;

constructor TFileEC.Create;
begin
  inherited Create;
  Handle := -1;
end;

destructor TFileEC.Destroy;
begin
  Reset;
  inherited Destroy;
end;

procedure TFileEC.Reset;
begin
  if Handle <> -1 then
  begin
    PackageFileLock.Enter;
    PackageCollection.CloseEntryHandle(Handle);
    PackageFileLock.Leave;
  end;
  OpenDepth := 0;
  Handle := -1;
  FileName := '';
end;

procedure TFileEC.SetFileName(NewFileName: WideString);
begin
  Reset;
  FileName := NewFileName;
end;

procedure TFileEC.AcquireReadWriteHandle;
begin
  if OpenDepth = 0 then
  begin
    PackageFileLock.Enter;
    Handle :=
        PackageCollection.OpenEntryByPathAcrossPackages(
            AnsiString(FileName),
            GENERIC_READ or GENERIC_WRITE,
            False
        );
    PackageFileLock.Leave;
    if Handle = -1 then
      raise Exception.Create('TFileEC.Open. FileName=' + FileName);
  end;
  Inc(OpenDepth);
end;

procedure TFileEC.AcquireReadHandle(FirstPackageOnly: Boolean);
begin
  if OpenDepth = 0 then
  begin
    PackageFileLock.Enter;
    Handle :=
        PackageCollection
            .OpenEntryByPathAcrossPackages(AnsiString(FileName), GENERIC_READ, FirstPackageOnly);
    PackageFileLock.Leave;
    if Handle = -1 then
      raise Exception.Create('TFileEC.Open. FileName=' + FileName);
  end;
  Inc(OpenDepth);
end;

function TFileEC.TryAcquireReadHandle(FirstPackageOnly: Boolean): Boolean;
begin
  if OpenDepth = 0 then
  begin
    PackageFileLock.Enter;
    Handle :=
        PackageCollection
            .OpenEntryByPathAcrossPackages(AnsiString(FileName), GENERIC_READ, FirstPackageOnly);
    PackageFileLock.Leave;
    if Handle = -1 then
    begin
      Result := False;
      Exit
    end;
  end;
  Inc(OpenDepth);
  Result := True;
end;

procedure TFileEC.CreateNew;
begin
  OpenDepth := 1;
  ReleaseHandle;
  PackageFileLock.Enter;
  Handle := PackageCollection.CreateLooseFile(FileName);
  PackageFileLock.Leave;
  if Handle = -1 then
  begin
    Handle := -1;
    raise Exception.Create('TFileEC.CreateNew. FileName=' + FileName);
  end;
  OpenDepth := 1;
end;

procedure TFileEC.ReleaseHandle;
begin
  Dec(OpenDepth);
  if OpenDepth <= 0 then
  begin
    if Handle <> -1 then
    begin
      PackageFileLock.Enter;
      PackageCollection.CloseEntryHandle(Handle);
      PackageFileLock.Leave;
    end;
    Handle := -1;
    OpenDepth := 0;
  end;
end;

function TFileEC.GetSize: Cardinal;
var
  Size: Cardinal;
begin
  AcquireReadWriteHandle;
  PackageFileLock.Enter;
  Size := PackageCollection.GetEntryHandleSize(Handle);
  PackageFileLock.Leave;
  if Size = $FFFFFFFF then
    raise Exception.Create('TFileEC.GetSize. FileName=' + FileName);
  ReleaseHandle;
  Result := Size;
end;

function TFileEC.GetFileName: WideString;
begin
  Result := FileName;
end;

function TFileEC.SetPointer(Offset: Cardinal; Origin: Integer): Cardinal;
var
  Success: Boolean;
begin
  PackageFileLock.Enter;
  Success := PackageCollection.SeekEntryHandle(Handle, Offset, Origin);
  PackageFileLock.Leave;
  if not Success then
    raise Exception.Create('TFileEC.SetPointer. FileName=' + FileName);
  PackageFileLock.Enter;
  Result := PackageCollection.GetEntryHandlePosition(Handle);
  PackageFileLock.Leave;
end;

function TFileEC.GetPointer: Cardinal;
begin
  PackageFileLock.Enter;
  Result := PackageCollection.GetEntryHandlePosition(Handle);
  PackageFileLock.Leave;
end;

procedure TFileEC.ReadBuffer(Dest: Pointer; ByteCount: Cardinal);
var
  Success: Boolean;
begin
  PackageFileLock.Enter;
  Success := PackageCollection.ReadEntryHandle(Handle, Dest^, ByteCount);
  PackageFileLock.Leave;
  if not Success then
    raise Exception.Create(
        'TFileEC.Read. FileName='
            + FileName
            + ' kolbyte='
            + SysUtils.IntToStr(ByteCount)
            + ' GetLastError='
            + SysUtils.IntToStr(Windows.GetLastError));
end;

procedure TFileEC.WriteBuffer(Source: Pointer; ByteCount: Cardinal);
var
  Success: Boolean;
begin
  if ByteCount > 0 then
  begin
    PackageFileLock.Enter;
    Success := PackageCollection.WriteEntryHandle(Handle, Source^, ByteCount);
    PackageFileLock.Leave;
    if not Success then
      raise Exception.Create(
          'TFileEC.Write. FileName=' + FileName + ' kolbyte=' + SysUtils.IntToStr(ByteCount));
  end;
end;

function TFileEC.ReadWideString: WideString;
var
  Ch: WideChar;
begin
  Result := '';
  while True do
  begin
    ReadBuffer(@Ch, SizeOf(Ch));
    if Ch = #0 then
      Break;
    Result := Result + Ch;
  end;
end;

end.
