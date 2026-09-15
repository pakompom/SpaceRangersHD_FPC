unit Windows;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
uses
  SysUtils,
  Types;
const
  WHEEL_DELTA = 120;
  WM_MOUSELEAVE = $02A3;
  MK_LBUTTON = 1;
  MK_RBUTTON = 2;
  MK_SHIFT = 4;
  MK_CONTROL = 8;
  MK_MBUTTON = 16;
  VK_OEM_3 = $C0;
  VK_OEM_PLUS = $BB;

type
  DWORD = Cardinal;
  UINT = Cardinal;
  BOOL = LongBool;
  THandle = Cardinal;
  HWND = THandle;
  HDC = THandle;
  HBITMAP = THandle;
  HICON = THandle;
  HCURSOR = THandle;
  HGDIOBJ = THandle;
  HBRUSH = THandle;
  HFONT = THandle;
  HMODULE = THandle;
  HKEY = THandle;
  WPARAM = PtrUInt;
  LPARAM = PtrInt;
  LRESULT = PtrInt;
  PDWORD = ^DWORD;
  TPoint = Types.TPoint;
  TRect = Types.TRect;
  PRect = Types.PRect;
  TSize = Types.TSize;
  TFileTime = packed record
  dwLowDateTime, dwHighDateTime: DWORD
  end;
  TWin32FindDataA = record
    dwFileAttributes: DWORD;
    ftCreationTime, ftLastAccessTime, ftLastWriteTime: TFileTime;
    nFileSizeHigh, nFileSizeLow: DWORD;
    dwReserved0, dwReserved1: DWORD;
    cFileName: array[0..259] of AnsiChar;
  cAlternateFileName: array[0..13] of AnsiChar
  end;
  TWin32FindDataW = record
    dwFileAttributes: DWORD;
    ftCreationTime, ftLastAccessTime, ftLastWriteTime: TFileTime;
    nFileSizeHigh, nFileSizeLow: DWORD;
    dwReserved0, dwReserved1: DWORD;
    cFileName: array[0..259] of WideChar;
  cAlternateFileName: array[0..13] of WideChar
  end;
  TWin32FindData = TWin32FindDataA;
  TSystemTime = SysUtils.TSystemTime;
  TOSVersionInfo = record
    dwOSVersionInfoSize, dwMajorVersion, dwMinorVersion, dwBuildNumber, dwPlatformId: DWORD;
  szCSDVersion: array[0..127] of AnsiChar
  end;
  TSystemInfo = record
    wProcessorArchitecture, wReserved: Word;
    dwPageSize: DWORD;
    lpMinimumApplicationAddress, lpMaximumApplicationAddress: Pointer;
    dwActiveProcessorMask: PtrUInt;
    dwNumberOfProcessors, dwProcessorType, dwAllocationGranularity: DWORD;
  wProcessorLevel, wProcessorRevision: Word
  end;
  TWndClassW = record
    style: UINT;
    lpfnWndProc: Pointer;
    cbClsExtra, cbWndExtra: Integer;
    hInstance, hIcon, hCursor, hbrBackground: THandle;
  lpszMenuName, lpszClassName: PWideChar
  end;
  TMsg = record
    hwnd: THandle;
    message: UINT;
    wParam: WPARAM;
    lParam: LPARAM;
    time: DWORD;
  pt: TPoint
  end;
  TMessage = TMsg;
  TSecurityAttributes = record
    nLength: DWORD;
    lpSecurityDescriptor: Pointer;
  bInheritHandle: BOOL
  end;
const
  LOCALE_USER_DEFAULT = $400;
  NORM_IGNORECASE = 1;
  SW_MINIMIZE = 6;
  SW_SHOWNORMAL = 1;
  MAX_PATH = 260;
  INVALID_HANDLE_VALUE = THandle(-1);
  INVALID_FILE_ATTRIBUTES = DWORD(-1);
  GENERIC_READ = $80000000;
  GENERIC_WRITE = $40000000;
  FILE_SHARE_READ = 1;
  FILE_SHARE_WRITE = 2;
  CREATE_NEW = 1;
  CREATE_ALWAYS = 2;
  OPEN_EXISTING = 3;
  OPEN_ALWAYS = 4;
  FILE_ATTRIBUTE_NORMAL = $80;
  FILE_ATTRIBUTE_DIRECTORY = $10;
  FILE_BEGIN = 0;
  FILE_CURRENT = 1;
  FILE_END = 2;
  HEAP_ZERO_MEMORY = 8;
  MB_OK = 0;
  MB_ICONERROR = $10;
  MB_YESNO = 4;
  MB_ICONQUESTION = $20;
  IDYES = 6;
  IDNO = 7;
  IDOK = 1;
  VK_ESCAPE = 27;
  VK_RETURN = 13;
  VK_SPACE = 32;
  VK_SHIFT = 16;
  VK_CONTROL = 17;
  VK_MENU = 18;
  VK_TAB = 9;
  VK_LEFT = 37;
  VK_UP = 38;
  VK_RIGHT = 39;
  VK_DOWN = 40;
  VK_HOME = 36;
  VK_END = 35;
  VK_PRIOR = 33;
  VK_NEXT = 34;
  VK_DELETE = 46;
  VK_BACK = 8;
  WM_QUIT = $12;
  WM_CLOSE = $10;
  WM_ACTIVATE = $6;
  WM_ACTIVATEAPP = $1C;
  WM_PAINT = $F;
  WM_SIZE = 5;
  WM_TIMER = $113;
  WM_KEYDOWN = $100;
  WM_KEYUP = $101;
  WM_CHAR = $102;
  WM_SYSKEYDOWN = $104;
  WM_SYSKEYUP = $105;
  WM_MOUSEMOVE = $200;
  WM_LBUTTONDOWN = $201;
  WM_LBUTTONUP = $202;
  WM_LBUTTONDBLCLK = $203;
  WM_RBUTTONDOWN = $204;
  WM_RBUTTONUP = $205;
  WM_RBUTTONDBLCLK = $206;
  WM_MBUTTONDOWN = $207;
  WM_MBUTTONUP = $208;
  WM_MOUSEWHEEL = $20A;
  PM_REMOVE = 1;
  INFINITE = DWORD(-1);
  WAIT_OBJECT_0 = 0;
  WAIT_TIMEOUT = 258;
  CP_ACP = 0;
  CP_UTF8 = 65001;
function NativePath(const Path: string): string;
function GetForegroundWindow: THandle;
function GetDoubleClickTime: Cardinal;
function GetTickCount: Cardinal;
function GetCurrentThreadId: Cardinal;
function MessageBoxA(Wnd: THandle; Text, Caption: PAnsiChar; Flags: Cardinal): Integer;
function MessageBoxW(Wnd: THandle; Text, Caption: PWideChar; Flags: Cardinal): Integer;
function GetProcessHeap: THandle;
function HeapAlloc(Heap: THandle; Flags: Cardinal; Size: PtrUInt): Pointer;
function HeapReAlloc(Heap: THandle; Flags: Cardinal; Data: Pointer; Size: PtrUInt): Pointer;
function HeapFree(Heap: THandle; Flags: Cardinal; Data: Pointer): BOOL;
function CreateFileA(
    Name: PAnsiChar;
    Access, Share: DWORD;
    Security: Pointer;
    Creation, Attrs: DWORD;
    Template: THandle
): THandle;
function CreateFileW(
    Name: PWideChar;
    Access, Share: DWORD;
    Security: Pointer;
    Creation, Attrs: DWORD;
    Template: THandle
): THandle;
function ReadFile(
    Handle: THandle;
    var Buffer;
    Count: DWORD;
    var Done: DWORD;
    Overlapped: Pointer
): BOOL;
function WriteFile(
    Handle: THandle;
    const Buffer;
    Count: DWORD;
    var Done: DWORD;
    Overlapped: Pointer
): BOOL;
function CloseHandle(Handle: THandle): BOOL;
function SetFilePointer(Handle: THandle; Distance: LongInt; High: Pointer; Origin: DWORD): DWORD;
function GetFileSize(Handle: THandle; High: Pointer): DWORD;
function GetLastError: DWORD;
procedure Sleep(Ms: Cardinal);
procedure CopyMemory(Dest, Source: Pointer; Size: PtrUInt);
procedure ZeroMemory(Dest: Pointer; Size: PtrUInt);
procedure MoveMemory(Dest, Source: Pointer; Size: PtrUInt);
function GetModuleHandleW(Name: PWideChar): THandle;
function GetModuleHandle(Name: PAnsiChar): THandle;
function LoadLibrary(Name: PAnsiChar): THandle;
function LoadLibraryW(Name: PWideChar): THandle;
function GetProcAddress(Module: THandle; Name: PAnsiChar): Pointer;
function FreeLibrary(Module: THandle): BOOL;

function UnionRect(out Dest: TRect; const A, B: TRect): BOOL;
function IntersectRect(out Dest: TRect; const A, B: TRect): BOOL;
function IsRectEmpty(const R: TRect): BOOL;
function EqualRect(const A, B: TRect): BOOL;
function PtInRect(const R: TRect; const P: TPoint): BOOL;
function OffsetRect(var R: TRect; X, Y: Integer): BOOL;
function InflateRect(var R: TRect; X, Y: Integer): BOOL;
function SetRect(var R: TRect; L, T, Right, Bottom: Integer): BOOL;
function SetRectEmpty(var R: TRect): BOOL;

function HeapCreate(Options: DWORD; InitialSize, MaximumSize: PtrUInt): THandle;
function HeapDestroy(Heap: THandle): BOOL;

procedure FillMemory(Dest: Pointer; Size: PtrUInt; Value: Byte);
const
  WAIT_FAILED = DWORD(-1);
  WAIT_ABANDONED_0 = 128;
function GetVersion: DWORD;
function CharLowerBuffW(Text: PWideChar; Count: DWORD): DWORD;
function CharUpperBuffW(Text: PWideChar; Count: DWORD): DWORD;
function CharLowerBuffA(Text: PAnsiChar; Count: DWORD): DWORD;
function CharUpperBuffA(Text: PAnsiChar; Count: DWORD): DWORD;
function CreateEvent(Security: Pointer; ManualReset, InitialState: BOOL; Name: PAnsiChar): THandle;
function SetEvent(Event: THandle): BOOL;
function ResetEvent(Event: THandle): BOOL;
function WaitForSingleObject(Handle: THandle; Timeout: DWORD): DWORD;
function WaitForMultipleObjects(
    Count: DWORD;
    Handles: Pointer;
    WaitAll: BOOL;
    Timeout: DWORD
): DWORD;

const
  VK_F1 = 112;
  VK_F2 = 113;
  VK_F3 = 114;
  VK_F4 = 115;
  VK_F5 = 116;
  VK_F6 = 117;
  VK_F7 = 118;
  VK_F8 = 119;
  VK_F9 = 120;
  VK_F10 = 121;
  VK_F11 = 122;
  VK_F12 = 123;
  VK_F13 = 124;
  VK_F14 = 125;
  VK_F15 = 126;
  VK_F16 = 127;
  VK_F17 = 128;
  VK_F18 = 129;
  VK_F19 = 130;
  VK_F20 = 131;
  VK_F21 = 132;
  VK_F22 = 133;
  VK_F23 = 134;
  VK_F24 = 135;
  VK_CAPITAL = 20;
  VK_NUMLOCK = 144;
  VK_SCROLL = 145;
  VK_INSERT = 45;
  VK_SNAPSHOT = 44;
  VK_PAUSE = 19;
  VK_LWIN = 91;
  VK_RWIN = 92;
  VK_LBUTTON = 1;
  VK_RBUTTON = 2;
  VK_MBUTTON = 4;
  VK_CLEAR = 12;
  VK_MULTIPLY = 106;
  VK_ADD = 107;
  VK_SUBTRACT = 109;
  VK_DECIMAL = 110;
  VK_DIVIDE = 111;
  VK_NUMPAD0 = 96;
  VK_NUMPAD1 = 97;
  VK_NUMPAD2 = 98;
  VK_NUMPAD3 = 99;
  VK_NUMPAD4 = 100;
  VK_NUMPAD5 = 101;
  VK_NUMPAD6 = 102;
  VK_NUMPAD7 = 103;
  VK_NUMPAD8 = 104;
  VK_NUMPAD9 = 105;
type
  TBitmapInfoHeader = packed record
    biSize: DWORD;
    biWidth, biHeight: LongInt;
    biPlanes, biBitCount: Word;
    biCompression, biSizeImage: DWORD;
    biXPelsPerMeter, biYPelsPerMeter: LongInt;
  biClrUsed, biClrImportant: DWORD
  end;
  TRGBQuad = packed record
  rgbBlue, rgbGreen, rgbRed, rgbReserved: Byte
  end;
  TBitmapInfo = packed record
    bmiHeader: TBitmapInfoHeader;
  bmiColors: array[0..0] of TRGBQuad
  end;
  PBitmapInfo = ^TBitmapInfo;

function GetCursorPos(out P: TPoint): BOOL;
function SetCursorPos(X, Y: Integer): BOOL;
function ScreenToClient(Wnd: THandle; var P: TPoint): BOOL;
function ClientToScreen(Wnd: THandle; var P: TPoint): BOOL;
function ShowCursor(Show: BOOL): Integer;
function ClipCursor(Rect: PRect): BOOL;
function GetAsyncKeyState(Key: Integer): SmallInt;
function GetKeyState(Key: Integer): SmallInt;
function PostMessage(Wnd: THandle; Message: UINT; W: WPARAM; L: LPARAM): BOOL;
function DestroyWindow(Wnd: THandle): BOOL;
function CopyFileW(Source, Dest: PWideChar; FailIfExists: BOOL): BOOL;
function CopyFile(Source, Dest: PAnsiChar; FailIfExists: BOOL): BOOL;
function KillTimer(Wnd, Id: THandle): BOOL;
function SetWindowTextA(Wnd: THandle; Text: PAnsiChar): BOOL;

function MsgWaitForMultipleObjects(
    Count: DWORD;
    const Handles;
    WaitAll: BOOL;
    Timeout, Mask: DWORD
): DWORD;
function LoadLibraryA(Name: PAnsiChar): THandle;
function GetModuleHandleA(Name: PAnsiChar): THandle;
function FindFirstFileA(Pattern: PAnsiChar; var Data: TWin32FindDataA): THandle;
function FindNextFileA(Handle: THandle; var Data: TWin32FindDataA): BOOL;
function FindClose(Handle: THandle): BOOL;
function ShowWindow(Window: THandle; Command: Integer): BOOL;
function PeekMessage(var Msg: TMsg; Window: THandle; First, Last, Remove: Cardinal): BOOL;
function CompareFileTime(const A, B: TFileTime): LongInt;
function FileTimeToLocalFileTime(const A: TFileTime; out B: TFileTime): BOOL;
function FileTimeToSystemTime(const A: TFileTime; out B: TSystemTime): BOOL;
function CompareString(
    Locale, Flags: Cardinal;
    A: PAnsiChar;
    ALength: Integer;
    B: PAnsiChar;
    BLength: Integer
): Integer;
function DeleteFileA(Name: PAnsiChar): BOOL;
function MoveFileW(OldName, NewName: PWideChar): BOOL;
function FindFirstFileW(Pattern: PWideChar; var Data: TWin32FindDataW): THandle;
function FindNextFileW(Handle: THandle; var Data: TWin32FindDataW): BOOL;
function FindFirstFile(Pattern: PAnsiChar; var Data: TWin32FindDataA): THandle;
function FindNextFile(Handle: THandle; var Data: TWin32FindDataA): BOOL;
function DeleteFile(Name: PAnsiChar): BOOL;
implementation
uses
  DateUtils,
  BaseUnix,
  Unix,
  SyncObjs,
  Classes,
  GameNative,
  Math;
const
  EventBase = $100000;
var
  Events: array of TEvent;
  EventLock: TCriticalSection;
  CursorDisplayCount: Integer;
function ShowWindow(Window: THandle; Command: Integer): BOOL;
begin
  if Command = SW_MINIMIZE then
    sr_window_minimize;
  Result := True
end;
function PeekMessage(var Msg: TMsg; Window: THandle; First, Last, Remove: Cardinal): BOOL;
begin
  // SDL dispatch consumes translated text events directly; no separate WM_CHAR queue.
  Result := False;
end;
function NativePath(const Path: string): string;
{$IFDEF ANDROID}
var
  Parts: TStringList;
  Search: TSearchRec;
  Part, Base, Candidate: string;
  I: Integer;
{$ENDIF}
begin
  Result := StringReplace(Path, '\', '/', [rfReplaceAll]);
{$IFDEF ANDROID}
  // Original loose-file references assume a case-insensitive Windows volume.
  // Resolve existing components, retaining the spelling of new output files.
  if SysUtils.FileExists(Result) or SysUtils.DirectoryExists(Result) then
    Exit;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '/';
    Parts.DelimitedText := Result;
    if (Result <> '') and (Result[1] = '/') then
      Base := '/'
    else
      Base := '';
    for I := 0 to Parts.Count - 1 do
    begin
      Part := Parts[I];
      if Part = '' then
        Continue;
      Candidate := Base + Part;
      if not (SysUtils.FileExists(Candidate) or SysUtils.DirectoryExists(Candidate)) then
        if SysUtils.FindFirst(Base + '*', faAnyFile, Search) = 0 then
        begin
          repeat
            if SameText(Search.Name, Part) then
            begin
              Part := Search.Name;
              Break
            end;
          until SysUtils.FindNext(Search) <> 0;
          SysUtils.FindClose(Search);
        end;
      Base := Base + Part + '/';
    end;
    Result := ExcludeTrailingPathDelimiter(Base);
  finally
    Parts.Free
  end;
{$ENDIF}
end;
function GetForegroundWindow: THandle;
begin
  if sr_window_focused <> 0 then
    Result := 1
  else
    Result := 0
end;
function GetDoubleClickTime: Cardinal;
begin
  Result := sr_double_click_ms
end;
function GetTickCount: Cardinal;
begin
  Result := Cardinal(GetTickCount64)
end;
function GetCurrentThreadId: Cardinal;
begin
  Result := Cardinal(System.GetCurrentThreadID)
end;
function MessageBoxA(Wnd: THandle; Text, Caption: PAnsiChar; Flags: Cardinal): Integer;
begin
  WriteLn(StdErr, string(Caption), ': ', string(Text));
  Result := sr_message_box(Text, Caption, Flags);
  if Result = 0 then
    WriteLn(StdErr, 'Cannot show error dialog: ', string(sr_error));
end;
function MessageBoxW(Wnd: THandle; Text, Caption: PWideChar; Flags: Cardinal): Integer;
begin
  Result :=
      MessageBoxA(
          Wnd,
          PAnsiChar(UTF8Encode(WideString(Text))),
          PAnsiChar(UTF8Encode(WideString(Caption))),
          Flags
      )
end;
function GetProcessHeap: THandle;
begin
  Result := 1
end;
function HeapAlloc(Heap: THandle; Flags: Cardinal; Size: PtrUInt): Pointer;
begin
  GetMem(Result, Size);
  if Flags and HEAP_ZERO_MEMORY <> 0 then
    FillChar(Result^, Size, 0)
end;
function HeapReAlloc(Heap: THandle; Flags: Cardinal; Data: Pointer; Size: PtrUInt): Pointer;
begin
  Result := Data;
  ReAllocMem(Result, Size)
end;
function HeapFree(Heap: THandle; Flags: Cardinal; Data: Pointer): BOOL;
begin
  if Data <> nil then
    FreeMem(Data);
  Result := True
end;
function CreateFileA(
    Name: PAnsiChar;
    Access, Share: DWORD;
    Security: Pointer;
    Creation, Attrs: DWORD;
    Template: THandle
): THandle;
var
  F: Integer;
begin
  F := O_RDONLY;
  if Access and GENERIC_WRITE <> 0 then
    F := O_RDWR;
  case Creation of
    CREATE_NEW: F := F or O_CREAT or O_EXCL;
    CREATE_ALWAYS: F := F or O_CREAT or O_TRUNC;
    OPEN_ALWAYS: F := F or O_CREAT
  end;
  Result := THandle(fpOpen(NativePath(Name), F, &644))
end;
function CreateFileW(
    Name: PWideChar;
    Access, Share: DWORD;
    Security: Pointer;
    Creation, Attrs: DWORD;
    Template: THandle
): THandle;
begin
  Result :=
      CreateFileA(
          PAnsiChar(UTF8Encode(WideString(Name))),
          Access,
          Share,
          Security,
          Creation,
          Attrs,
          Template
      )
end;
function ReadFile(
    Handle: THandle;
    var Buffer;
    Count: DWORD;
    var Done: DWORD;
    Overlapped: Pointer
): BOOL;
var
  N: Int64;
begin
  N := fpRead(Integer(Handle), Buffer, Count);
  Result := N >= 0;
  if Result then
    Done := N
  else
    Done := 0
end;
function WriteFile(
    Handle: THandle;
    const Buffer;
    Count: DWORD;
    var Done: DWORD;
    Overlapped: Pointer
): BOOL;
var
  N: Int64;
begin
  N := fpWrite(Integer(Handle), Buffer, Count);
  Result := N >= 0;
  if Result then
    Done := N
  else
    Done := 0
end;
function CloseHandle(Handle: THandle): BOOL;
begin
  Result := False;
  if Handle = INVALID_HANDLE_VALUE then
    Exit;
  if Handle >= EventBase then
  begin
    EventLock.Enter;
    try
      if Handle - EventBase >= Cardinal(Length(Events)) then
        Exit;
      if Events[Handle - EventBase] = nil then
        Exit;
      Events[Handle - EventBase].Free;
      Events[Handle - EventBase] := nil;
      Result := True;
    finally
      EventLock.Leave
    end;
  end
  else
    Result := fpClose(Integer(Handle)) = 0;
end;
function SetFilePointer(Handle: THandle; Distance: LongInt; High: Pointer; Origin: DWORD): DWORD;
begin
  Result := fpLseek(Integer(Handle), Distance, Origin)
end;
function GetFileSize(Handle: THandle; High: Pointer): DWORD;
var
  S: Stat;
begin
  if fpFstat(Integer(Handle), S) = 0 then
    Result := S.st_size
  else
    Result := DWORD(-1)
end;
function GetLastError: DWORD;
begin
  Result := fpGetErrNo
end;
procedure Sleep(Ms: Cardinal);
begin
  SysUtils.Sleep(Ms)
end;
procedure CopyMemory(Dest, Source: Pointer; Size: PtrUInt);
begin
  if Size > 0 then
    Move(Source^, Dest^, Size)
end;
procedure ZeroMemory(Dest: Pointer; Size: PtrUInt);
begin
  if Size > 0 then
    FillChar(Dest^, Size, 0)
end;
procedure MoveMemory(Dest, Source: Pointer; Size: PtrUInt);
begin
  CopyMemory(Dest, Source, Size)
end;
function GetModuleHandleW(Name: PWideChar): THandle;
begin
  Result := GetModuleHandle(PAnsiChar(UTF8Encode(WideString(Name))))
end;
function GetModuleHandle(Name: PAnsiChar): THandle;
begin
  Result := 0
end;
function LoadLibrary(Name: PAnsiChar): THandle;
begin
  Result := 0
end;
function LoadLibraryW(Name: PWideChar): THandle;
begin
  Result := 0
end;
function GetProcAddress(Module: THandle; Name: PAnsiChar): Pointer;
begin
  Result := nil
end;
function FreeLibrary(Module: THandle): BOOL;
begin
  Result := True
end;
function UnionRect(out Dest: TRect; const A, B: TRect): BOOL;
begin
  Result := Types.UnionRect(Dest, A, B)
end;
function IntersectRect(out Dest: TRect; const A, B: TRect): BOOL;
begin
  Result := Types.IntersectRect(Dest, A, B)
end;
function IsRectEmpty(const R: TRect): BOOL;
begin
  Result := (R.Right <= R.Left) or (R.Bottom <= R.Top)
end;
function EqualRect(const A, B: TRect): BOOL;
begin
  Result := CompareMem(@A, @B, SizeOf(A))
end;
function PtInRect(const R: TRect; const P: TPoint): BOOL;
begin
  Result := Types.PtInRect(R, P)
end;
function OffsetRect(var R: TRect; X, Y: Integer): BOOL;
begin
  Inc(R.Left, X);
  Inc(R.Right, X);
  Inc(R.Top, Y);
  Inc(R.Bottom, Y);
  Result := True
end;
function InflateRect(var R: TRect; X, Y: Integer): BOOL;
begin
  Dec(R.Left, X);
  Inc(R.Right, X);
  Dec(R.Top, Y);
  Inc(R.Bottom, Y);
  Result := True
end;
function SetRect(var R: TRect; L, T, Right, Bottom: Integer): BOOL;
begin
  R := Types.Rect(L, T, Right, Bottom);
  Result := True
end;
function SetRectEmpty(var R: TRect): BOOL;
begin
  FillChar(R, SizeOf(R), 0);
  Result := True
end;
function HeapCreate(Options: DWORD; InitialSize, MaximumSize: PtrUInt): THandle;
begin
  Result := GetProcessHeap
end;
function HeapDestroy(Heap: THandle): BOOL;
begin
  Result := True
end;
procedure FillMemory(Dest: Pointer; Size: PtrUInt; Value: Byte);
begin
  FillChar(Dest^, Size, Value)
end;
function GetVersion: DWORD;
begin
  Result := 10
end;
function CharLowerBuffW(Text: PWideChar; Count: DWORD): DWORD;
var
  S: UnicodeString;
begin
  SetString(S, Text, Count);
  S := UnicodeLowerCase(S);
  if Count > 0 then
    Move(S[1], Text^, Count * 2);
  Result := Count
end;
function CharUpperBuffW(Text: PWideChar; Count: DWORD): DWORD;
var
  S: UnicodeString;
begin
  SetString(S, Text, Count);
  S := UnicodeUpperCase(S);
  if Count > 0 then
    Move(S[1], Text^, Count * 2);
  Result := Count
end;
function CharLowerBuffA(Text: PAnsiChar; Count: DWORD): DWORD;
var
  S: AnsiString;
begin
  SetString(S, Text, Count);
  S := LowerCase(S);
  if Count > 0 then
    Move(S[1], Text^, Count);
  Result := Count
end;
function CharUpperBuffA(Text: PAnsiChar; Count: DWORD): DWORD;
var
  S: AnsiString;
begin
  SetString(S, Text, Count);
  S := UpperCase(S);
  if Count > 0 then
    Move(S[1], Text^, Count);
  Result := Count
end;
function CreateEvent(Security: Pointer; ManualReset, InitialState: BOOL; Name: PAnsiChar): THandle;
var
  I: Integer;
begin
  EventLock.Enter;
  try
    I := 0;
    while (I < Length(Events)) and (Events[I] <> nil) do
      Inc(I);
    if I = Length(Events) then
      SetLength(Events, I + 1);
    Events[I] := TEvent.Create(nil, ManualReset, InitialState, '');
    Result := EventBase + I;
  finally
    EventLock.Leave
  end
end;
function SetEvent(Event: THandle): BOOL;
begin
  Events[Event - EventBase].SetEvent;
  Result := True
end;
function ResetEvent(Event: THandle): BOOL;
begin
  Events[Event - EventBase].ResetEvent;
  Result := True
end;
function WaitForSingleObject(Handle: THandle; Timeout: DWORD): DWORD;
begin
  if (Handle < EventBase)
      or (Handle - EventBase >= PtrUInt(Length(Events)))
      or (Events[Handle - EventBase] = nil) then
    Exit(WAIT_FAILED);
  case Events[Handle - EventBase].WaitFor(Timeout) of
    wrSignaled: Result := WAIT_OBJECT_0;
    wrTimeout: Result := WAIT_TIMEOUT;
  else
    Result := WAIT_FAILED
  end
end;
function WaitForMultipleObjects(
    Count: DWORD;
    Handles: Pointer;
    WaitAll: BOOL;
    Timeout: DWORD
): DWORD;
var
  I: Integer;
  Started: QWord;
  Ready: Boolean;
  H: ^THandle;
begin
  Started := GetTickCount64;
  repeat
    Ready := True;
    H := Handles;
    for I := 0 to Integer(Count) - 1 do
    begin
      Result := WaitForSingleObject(H^, 0);
      if Result = WAIT_FAILED then
        Exit;
      if Result = WAIT_OBJECT_0 then
      begin
        if not WaitAll then
          Exit(WAIT_OBJECT_0 + DWORD(I))
      end
      else
        Ready := False;
      Inc(H)
    end;
    if WaitAll and Ready then
      Exit(WAIT_OBJECT_0);
    if (Timeout <> INFINITE) and (GetTickCount64 - Started >= Timeout) then
      Exit(WAIT_TIMEOUT);
    Sleep(1)
  until False
end;

function GetCursorPos(out P: TPoint): BOOL;
begin
  sr_mouse(P.X, P.Y);
  Result := True
end;
function SetCursorPos(X, Y: Integer): BOOL;
begin
  sr_warp(X, Y);
  Result := True
end;
function ScreenToClient(Wnd: THandle; var P: TPoint): BOOL;
begin
  Result := True
end;
function ClientToScreen(Wnd: THandle; var P: TPoint): BOOL;
begin
  Result := True
end;
function ShowCursor(Show: BOOL): Integer;
begin
  if Show then
    Inc(CursorDisplayCount)
  else
    Dec(CursorDisplayCount);
  sr_cursor(Ord(CursorDisplayCount >= 0));
  Result := CursorDisplayCount
end;
function ClipCursor(Rect: PRect): BOOL;
begin
  Result := True
end;
function GetAsyncKeyState(Key: Integer): SmallInt;
begin
  Result := SmallInt(sr_key(Key))
end;
function GetKeyState(Key: Integer): SmallInt;
begin
  Result := GetAsyncKeyState(Key)
end;
function PostMessage(Wnd: THandle; Message: UINT; W: WPARAM; L: LPARAM): BOOL;
begin
  Result := sr_post(Message, Cardinal(W), Integer(L)) <> 0
end;
function DestroyWindow(Wnd: THandle): BOOL;
begin
  sr_window_close;
  Result := True
end;
function CopyFileW(Source, Dest: PWideChar; FailIfExists: BOOL): BOOL;
begin
  Result :=
      CopyFile(
          PAnsiChar(UTF8Encode(WideString(Source))),
          PAnsiChar(UTF8Encode(WideString(Dest))),
          FailIfExists
      )
end;
function CopyFile(Source, Dest: PAnsiChar; FailIfExists: BOOL): BOOL;
var
  S, D: TFileStream;
begin
  Result := False;
  if FailIfExists and SysUtils.FileExists(NativePath(Dest)) then
    Exit;
  try
    S := TFileStream.Create(NativePath(Source), fmOpenRead or fmShareDenyNone);
    try
      D := TFileStream.Create(NativePath(Dest), fmCreate);
      try
        D.CopyFrom(S, 0);
      finally
        D.Free
      end;
    finally
      S.Free
    end;
    Result := True;
  except
    Result := False
  end
end;
function KillTimer(Wnd, Id: THandle): BOOL;
begin
  Result := True
end;
function SetWindowTextA(Wnd: THandle; Text: PAnsiChar): BOOL;
begin
  Result := True
end;

function MsgWaitForMultipleObjects(
    Count: DWORD;
    const Handles;
    WaitAll: BOOL;
    Timeout, Mask: DWORD
): DWORD;
begin
  if Count = 0 then
  begin
    Sleep(Min(Timeout, 10));
    Result := WAIT_TIMEOUT
  end
  else
    Result := WaitForMultipleObjects(Count, @Handles, WaitAll, Timeout)
end;
function LoadLibraryA(Name: PAnsiChar): THandle;
begin
  Result := LoadLibrary(Name)
end;
function GetModuleHandleA(Name: PAnsiChar): THandle;
begin
  Result := GetModuleHandle(Name)
end;
var
  SearchRecords: array of^TSearchRec;
procedure CopySearchData(const Search: TSearchRec; var Data: TWin32FindDataA);
var
  Stamp: QWord;
begin
  FillChar(Data, SizeOf(Data), 0);
  Data.dwFileAttributes := Search.Attr;
  Data.nFileSizeLow := QWord(Search.Size);
  Data.nFileSizeHigh := QWord(Search.Size) shr 32;
  Stamp := (DateTimeToUnix(FileDateToDateTime(Search.Time)) + 11644473600) * 10000000;
  Data.ftLastWriteTime.dwLowDateTime := Stamp;
  Data.ftLastWriteTime.dwHighDateTime := Stamp shr 32;
  StrPLCopy(Data.cFileName, Search.Name, High(Data.cFileName));
end;
function FindFirstFileA(Pattern: PAnsiChar; var Data: TWin32FindDataA): THandle;
var
  I: Integer;
  Search: ^TSearchRec;
  Path: AnsiString;
begin
  Path := ExpandFileName(NativePath(AnsiString(Pattern)));
  if ExtractFileName(Path) = '*.*' then
    Path := ExtractFilePath(Path) + '*';
  New(Search);
  if SysUtils.FindFirst(Path, faAnyFile, Search^) <> 0 then
  begin
    Dispose(Search);
    Exit(INVALID_HANDLE_VALUE)
  end;
  I := 0;
  while (I < Length(SearchRecords)) and (SearchRecords[I] <> nil) do
    Inc(I);
  if I = Length(SearchRecords) then
    SetLength(SearchRecords, I + 1);
  SearchRecords[I] := Search;
  CopySearchData(Search^, Data);
  Result := $30000000 + Cardinal(I);
end;
function FindNextFileA(Handle: THandle; var Data: TWin32FindDataA): BOOL;
var
  I: Integer;
begin
  I := Handle - $30000000;
  Result := False;
  if (I < 0) or (I >= Length(SearchRecords)) then
    Exit;
  if SearchRecords[I] = nil then
    Exit;
  Result := SysUtils.FindNext(SearchRecords[I]^) = 0;
  if Result then
    CopySearchData(SearchRecords[I]^, Data);
end;
function FindClose(Handle: THandle): BOOL;
var
  I: Integer;
begin
  I := Handle - $30000000;
  Result := False;
  if (I < 0) or (I >= Length(SearchRecords)) then
    Exit;
  if SearchRecords[I] = nil then
    Exit;
  SysUtils.FindClose(SearchRecords[I]^);
  Dispose(SearchRecords[I]);
  SearchRecords[I] := nil;
  Result := True;
end;
function CompareFileTime(const A, B: TFileTime): LongInt;
var
  X, Y: QWord;
begin
  X := (QWord(A.dwHighDateTime) shl 32) or A.dwLowDateTime;
  Y := (QWord(B.dwHighDateTime) shl 32) or B.dwLowDateTime;
  if X < Y then
    Result := -1
  else if X > Y then
    Result := 1
  else
    Result := 0
end;
function FileTimeToLocalFileTime(const A: TFileTime; out B: TFileTime): BOOL;
var
  X: Int64;
begin
  X :=
      Int64((QWord(A.dwHighDateTime) shl 32) or A.dwLowDateTime)
          - Int64(GetLocalTimeOffset) * 60 * 10000000;
  B.dwLowDateTime := X;
  B.dwHighDateTime := QWord(X) shr 32;
  Result := True
end;
function FileTimeToSystemTime(const A: TFileTime; out B: TSystemTime): BOOL;
var
  X: QWord;
  D: TDateTime;
begin
  X := (QWord(A.dwHighDateTime) shl 32) or A.dwLowDateTime;
  D := UnixToDateTime(Int64(X div 10000000) - 11644473600);
  DecodeDate(D, B.Year, B.Month, B.Day);
  DecodeTime(D, B.Hour, B.Minute, B.Second, B.MilliSecond);
  B.DayOfWeek := DayOfWeek(D) - 1;
  Result := True
end;
function CompareString(
    Locale, Flags: Cardinal;
    A: PAnsiChar;
    ALength: Integer;
    B: PAnsiChar;
    BLength: Integer
): Integer;
var
  X, Y: AnsiString;
  C: Integer;
begin
  if ALength < 0 then
    X := A
  else
    SetString(X, A, ALength);
  if BLength < 0 then
    Y := B
  else
    SetString(Y, B, BLength);
  if Flags and NORM_IGNORECASE <> 0 then
    C := AnsiCompareText(X, Y)
  else
    C := AnsiCompareStr(X, Y);
  if C < 0 then
    Result := 1
  else if C > 0 then
    Result := 3
  else
    Result := 2;
end;
function DeleteFileA(Name: PAnsiChar): BOOL;
begin
  Result := SysUtils.DeleteFile(NativePath(AnsiString(Name)))
end;
function MoveFileW(OldName, NewName: PWideChar): BOOL;
begin
  Result :=
      SysUtils.RenameFile(
          NativePath(UTF8Encode(WideString(OldName))),
          NativePath(UTF8Encode(WideString(NewName)))
      )
end;
procedure WideFindData(const A: TWin32FindDataA; out W: TWin32FindDataW);
begin
  FillChar(W, SizeOf(W), 0);
  W.dwFileAttributes := A.dwFileAttributes;
  W.ftCreationTime := A.ftCreationTime;
  W.ftLastAccessTime := A.ftLastAccessTime;
  W.ftLastWriteTime := A.ftLastWriteTime;
  W.nFileSizeHigh := A.nFileSizeHigh;
  W.nFileSizeLow := A.nFileSizeLow;
  StringToWideChar(
      UTF8Decode(AnsiString(PAnsiChar(@A.cFileName[0]))),
      @W.cFileName[0],
      Length(W.cFileName)
  )
end;
function FindFirstFileW(Pattern: PWideChar; var Data: TWin32FindDataW): THandle;
var
  A: TWin32FindDataA;
begin
  Result := FindFirstFileA(PAnsiChar(UTF8Encode(WideString(Pattern))), A);
  if Result <> INVALID_HANDLE_VALUE then
    WideFindData(A, Data)
end;
function FindNextFileW(Handle: THandle; var Data: TWin32FindDataW): BOOL;
var
  A: TWin32FindDataA;
begin
  Result := FindNextFileA(Handle, A);
  if Result then
    WideFindData(A, Data)
end;
function FindFirstFile(Pattern: PAnsiChar; var Data: TWin32FindDataA): THandle;
begin
  Result := FindFirstFileA(Pattern, Data)
end;
function FindNextFile(Handle: THandle; var Data: TWin32FindDataA): BOOL;
begin
  Result := FindNextFileA(Handle, Data)
end;
function DeleteFile(Name: PAnsiChar): BOOL;
begin
  Result := DeleteFileA(Name)
end;
initialization
  EventLock := TCriticalSection.Create;
finalization
  EventLock.Free;

end.
