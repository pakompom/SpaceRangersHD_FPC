unit GameSystem;

{$MODE OBJFPC}
{$H+}

interface

type
  TGameMemoryStatus = packed record
    Length, MemoryLoad: Cardinal;
    TotalPhys, AvailPhys, TotalPageFile, AvailPageFile: QWord;
    TotalVirtual, AvailVirtual, AvailExtendedVirtual: QWord;
  end;

function CopyGameFile(const Source, Dest: UnicodeString): Boolean;
function QueryGameMemory(out Status: TGameMemoryStatus): Boolean;
function LockGameInstance: Boolean;

function GameTickCount: Cardinal;
function GameCpuClockMHz: Double;
function GameUserDirectory: UnicodeString;
function NativeGamePath(const Path: UnicodeString): UnicodeString;
procedure SetGameDirectory(const Path: UnicodeString);

implementation

uses
  SysUtils,
  Classes,
  Math,
  SDL2
{$IFDEF UNIX}
  ,
  BaseUnix,
  Unix
{$ENDIF}
{$IFDEF DARWIN}
  ,
  SysCtl,
  UnixType
{$ENDIF}
{$IFDEF MSWINDOWS}
  ,
  Registry,
  Windows,
  WinDirs
{$ENDIF}
      ;

var
  InstanceFile: THandle = THandle(-1);

{$IFDEF FPC_WASM_EMSCRIPTEN}
procedure NativeWasmMemoryStatus(
    out Capacity,
    Available: QWord
); cdecl; external name 'sr_fpc_memory_status';
{$ENDIF}

{$IFDEF MSWINDOWS}
// The FPC Windows unit does not declare the extended memory query.
function NativeGlobalMemoryStatusEx(
    var Status: TGameMemoryStatus
): LongBool; stdcall; external 'kernel32.dll' name 'GlobalMemoryStatusEx';
{$ENDIF}

{$IFDEF DARWIN}
function mach_host_self: Cardinal; cdecl; external 'c';
function host_page_size(Host: Cardinal; out Size: PtrUInt): Integer; cdecl; external 'c';
function host_statistics64(
    Host: Cardinal;
    Flavor: Integer;
    Info: Pointer;
    var Count: Cardinal
): Integer; cdecl; external 'c';
function mach_port_deallocate(Task, Name: Cardinal): Integer; cdecl; external 'c';
var
  mach_task_self_: Cardinal;
  cvar;
  external 'c';
{$ENDIF}

function CopyGameFile(const Source, Dest: UnicodeString): Boolean;
var
  Input, Output: TFileStream;
begin
  Result := False;
  try
    Input := TFileStream.Create(UTF8Encode(NativeGamePath(Source)), fmOpenRead or fmShareDenyNone);
    try
      Output := TFileStream.Create(UTF8Encode(NativeGamePath(Dest)), fmCreate);
      try
        Output.CopyFrom(Input, 0);
        Result := True;
      finally
        Output.Free;
      end;
    finally
      Input.Free;
    end;
  except
    on E: EStreamError do
      Result := False;
  end;
end;

function LockGameInstance: Boolean;
var
  Path: UnicodeString;
begin
  if InstanceFile <> THandle(-1) then
    Exit(True);
  ForceDirectories(GameUserDirectory);
  Path := GameUserDirectory + 'instance.lock';
{$IFDEF UNIX}
  InstanceFile := FpOpen(UTF8Encode(Path), O_CREAT or O_RDWR, &600);
  Result := (InstanceFile <> THandle(-1)) and (FpFlock(InstanceFile, LOCK_EX or LOCK_NB) = 0);
{$ELSE}
  if FileExists(Path) then
    InstanceFile := FileOpen(Path, fmOpenReadWrite or fmShareExclusive)
  else
    InstanceFile := FileCreate(Path, fmShareExclusive, 0);
  Result := InstanceFile <> THandle(-1);
{$ENDIF}
  if not Result and (InstanceFile <> THandle(-1)) then
  begin
    FileClose(InstanceFile);
    InstanceFile := THandle(-1);
  end;
end;

{$IFDEF LINUX}
function LoadProcFile(Lines: TStringList; const Path: string): Boolean;
begin
  // Android devices can restrict individual /proc files. Diagnostic queries
  // must retain their defaults rather than prevent the game from starting.
  Result := False;
  try
    Lines.LoadFromFile(Path);
    Result := True;
  except
    on E: EStreamError do
      ;
    on E: EInOutError do
      ;
  end;
end;
{$ENDIF}

function QueryGameMemory(out Status: TGameMemoryStatus): Boolean;
{$IFNDEF MSWINDOWS}
var
  Heap: TFPCHeapStatus;
  {$IFDEF DARWIN}
  Host, Count: Cardinal;
  Pages: PtrUInt;
  Stats: array[0..63] of Cardinal;
  {$ENDIF}
  {$IFDEF LINUX}
  Lines: TStringList;
  Line, Key, Value: string;
  Split: Integer;
  Bytes: QWord;
  {$ENDIF}
{$ENDIF}
begin
  Status := Default(TGameMemoryStatus);
  Status.Length := SizeOf(Status);
{$IF defined(FPC_WASM_EMSCRIPTEN)}
  Heap := GetFPCHeapStatus;
  NativeWasmMemoryStatus(Status.TotalPhys, Status.AvailPhys);
  // FPC keeps free blocks inside arenas owned by malloc. Those bytes are not
  // in malloc's free list, so add the current Pascal thread's reusable space.
  // Other threads' private arenas remain reserved and are counted conservatively.
  Inc(Status.AvailPhys, Min(Status.TotalPhys - Status.AvailPhys, QWord(Heap.CurrHeapFree)));
  Status.TotalVirtual := Status.TotalPhys;
  Status.AvailVirtual := Status.AvailPhys;
  if Status.TotalPhys <> 0 then
    Status.MemoryLoad := ((Status.TotalPhys - Status.AvailPhys) * 100) div Status.TotalPhys;
  Result := Status.TotalPhys <> 0;
{$ELSEIF defined(MSWINDOWS)}
  Result := NativeGlobalMemoryStatusEx(Status);
{$ELSE}
  Status.TotalPhys := QWord(SDL_GetSystemRAM) * 1024 * 1024;
  Status.AvailPhys := Status.TotalPhys;
  {$IFDEF DARWIN}
  Host := mach_host_self;
  try
    Count := Length(Stats);
    if (host_page_size(Host, Pages) = 0) and (host_statistics64(Host, 4, @Stats, Count) = 0) then
      // Free and inactive pages are the memory the OS can make available.
      Status.AvailPhys := Min(Status.TotalPhys, (QWord(Stats[0]) + Stats[2]) * Pages);
  finally
    mach_port_deallocate(mach_task_self_, Host);
  end;
  {$ENDIF}
  {$IFDEF LINUX}
  Lines := TStringList.Create;
  try
    if LoadProcFile(Lines, '/proc/meminfo') then
      for Line in Lines do
      begin
        Split := Pos(':', Line);
        if Split = 0 then
          Continue;
        Key := Copy(Line, 1, Split - 1);
        Value := Trim(Copy(Line, Split + 1, MaxInt));
        Split := Pos(' ', Value);
        if Split > 0 then
          SetLength(Value, Split - 1);
        Bytes := StrToQWordDef(Value, 0) * 1024;
        if Key = 'MemTotal' then
          Status.TotalPhys := Bytes
        else if Key = 'MemAvailable' then
          Status.AvailPhys := Bytes
        else if Key = 'SwapTotal' then
          Status.TotalPageFile := Bytes
        else if Key = 'SwapFree' then
          Status.AvailPageFile := Bytes;
      end;
  finally
    Lines.Free;
  end;
  {$ENDIF}
  // The Unix address space includes large shared mappings unrelated to game
  // allocations. Use FPC's reserved heap for the game's allocation-pressure
  // checks, while retaining native-width address headroom.
  Heap := GetFPCHeapStatus;
  Status.TotalVirtual := QWord(High(PtrInt));
  Status.AvailVirtual := Status.TotalVirtual - Min(Status.TotalVirtual, QWord(Heap.CurrHeapSize));
  if Status.TotalPhys <> 0 then
    Status.MemoryLoad := ((Status.TotalPhys - Status.AvailPhys) * 100) div Status.TotalPhys;
  Result := Status.TotalPhys <> 0;
{$ENDIF}
end;

function GameTickCount: Cardinal;
begin
  // Game deadlines deliberately retain their original 32-bit wraparound arithmetic.
  Result := Cardinal(GetTickCount64);
end;

{$IF defined(UNIX) or defined(WASI)}
function ResolveGamePathCase(const Path: UnicodeString): UnicodeString;
var
  Directory, Name: UnicodeString;
  Entry: TUnicodeSearchRec;
begin
  Result := Path;
  if (Path = '') or (FileGetAttr(Path) <> -1) then
    Exit;
  // Keep exact matches cheap. Resolve each missing component so loose mods
  // retain Windows filename matching on case-sensitive volumes too. Resolving
  // the parent also lets new saves/screenshots use an existing mixed-case folder.
  Directory := ExtractFileDir(Path);
  Name := ExtractFileName(Path);
  if Directory <> '' then
    Directory := IncludeTrailingPathDelimiter(ResolveGamePathCase(Directory));
  Result := Directory + Name;
  if (Name = '') or (FileGetAttr(Result) <> -1) then
    Exit;
  if FindFirst(Directory + '*', faAnyFile, Entry) = 0 then
    try
      repeat
        if UnicodeSameText(Entry.Name, Name) then
          Exit(Directory + Entry.Name);
      until FindNext(Entry) <> 0;
    finally
      FindClose(Entry);
    end;
end;
{$ENDIF}

function NativeGamePath(const Path: UnicodeString): UnicodeString;
var
  Index: Integer;
begin
  // Package entry names keep their original separators. Only OS paths pass here.
  Result := Path;
  for Index := 1 to Length(Result) do
    if (Result[Index] = '\') or (Result[Index] = '/') then
      Result[Index] := DirectorySeparator;
{$IF defined(UNIX) or defined(WASI)}
  Result := ResolveGamePathCase(Result);
{$ENDIF}
end;

function GameUserDirectory: UnicodeString;
begin
{$IFDEF ANDROID}
  // Set by the SDL launcher before it loads the Pascal library. Android does
  // not provide a useful HOME, and shared/external storage is not a save path.
  Result := UTF8Decode(GetEnvironmentVariable('SR_USER_DIR'));
  if (Result = '') or (Result[1] <> '/') then
    raise EInOutError.Create('Android launcher did not provide the private user directory');
  Exit(IncludeTrailingPathDelimiter(Result));
{$ENDIF}
{$IFDEF FPC_WASM_EMSCRIPTEN}
  // OPFS is mounted here before the Pascal runtime starts.
  Exit('/user/');
{$ENDIF}
{$IFDEF DARWIN}
  Result := GetUserDir + 'Library/Application Support/SpaceRangersHD/';
{$ELSE}
  {$IFDEF MSWINDOWS}
  // FPC resolves redirected Documents folders through the Unicode shell API.
  Result := GetWindowsSpecialDirUnicode(CSIDL_PERSONAL);
  if Result = '' then
    raise EInOutError.Create('Cannot locate the Documents folder');
  Result := IncludeTrailingPathDelimiter(Result) + 'SpaceRangersHD\';
  {$ELSE}
  Result := UTF8Decode(GetEnvironmentVariable('XDG_DATA_HOME'));
  // XDG paths must be absolute; relative values must not follow the asset CWD.
  if (Result = '') or (Result[1] <> '/') then
    Result := UTF8Decode(GetUserDir) + '.local/share';
  Result := IncludeTrailingPathDelimiter(Result) + 'SpaceRangersHD/';
  {$ENDIF}
{$ENDIF}
end;

procedure SetGameDirectory(const Path: UnicodeString);
begin
  if (Path = '') or not SetCurrentDir(UTF8Encode(NativeGamePath(Path))) then
    raise EInOutError.Create('Cannot open game directory: ' + UTF8Encode(Path));
end;

function GameCpuClockMHz: Double;
{$IFDEF DARWIN}
var
  Frequency: QWord;
  Size: size_t;
{$ENDIF}
{$IFDEF MSWINDOWS}
var
  Key: TRegistry;
{$ENDIF}
{$IFDEF LINUX}
var
  Lines: TStringList;
  Line: string;
  Split: Integer;
  Format: TFormatSettings;
  Value: Double;
{$ENDIF}
begin
  // Used by logging and the graphics auto-preset, not by simulation timing.
  // ARM's timer frequency is not its CPU clock. Keep the game's 1500 MHz
  // fallback when the OS does not report a processor frequency.
  Result := 1500;
{$IFDEF DARWIN}
  Size := SizeOf(Frequency);
  if (FPsysctlbyname('hw.cpufrequency', @Frequency, @Size, nil, 0) = 0)
      and (Size = SizeOf(Frequency))
      and (Frequency > 0) then
    Result := Frequency / 1000000;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Key := TRegistry.Create(KEY_READ);
  try
    Key.RootKey := HKEY_LOCAL_MACHINE;
    if Key.OpenKeyReadOnly('HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
      if Key.ValueExists('~MHz') then
        Result := Key.ReadInteger('~MHz');
  finally
    Key.Free;
  end;
{$ENDIF}
{$IFDEF LINUX}
  if not FileExists('/proc/cpuinfo') then
    Exit;
  Lines := TStringList.Create;
  try
    if not LoadProcFile(Lines, '/proc/cpuinfo') then
      Exit;
    Format := DefaultFormatSettings;
    Format.DecimalSeparator := '.';
    for Line in Lines do
    begin
      Split := Pos(':', Line);
      if (Split > 0) and (Trim(Copy(Line, 1, Split - 1)) = 'cpu MHz') then
        if TryStrToFloat(Trim(Copy(Line, Split + 1, MaxInt)), Value, Format) and (Value > 0) then
          Exit(Value);
    end;
  finally
    Lines.Free;
  end;
{$ENDIF}
end;

finalization
  if InstanceFile <> THandle(-1) then
    FileClose(InstanceFile);
end.
