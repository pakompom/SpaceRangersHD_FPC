unit EmscriptenThreads;

{$MODE objfpc}
{$H+}
{$IF not defined(CPUWASM32) or not defined(FPC_WASM_THREADS) or not defined(FPC_SECTION_THREADVARS)}
  {$FATAL EmscriptenThreads requires the LLVM wasm32 threaded RTL with native TLS}
{$ENDIF}

interface

{ Use this unit before all other units. Call EnsureEmscriptenThread before any
  foreign pthread callback enters the Pascal RTL. SDL drains queued audio in
  its native backend and does not call Pascal from the browser thread. }
procedure EnsureEmscriptenThread;

implementation

type
  TCThreadEntry = function(Argument: Pointer): Pointer; cdecl;
  PThreadStart = ^TThreadStart;
  TThreadStart = record
    Func: TThreadFunc;
    Argument: Pointer;
  end;

function NativeBegin(
    Entry: TCThreadEntry;
    Argument: Pointer;
    StackSize: PtrUInt
): TThreadID; cdecl; external name 'sr_fpc_thread_begin';
function NativeSelf: TThreadID; cdecl; external name 'sr_fpc_thread_self';
procedure NativeExit(Code: DWord); cdecl; external name 'sr_fpc_thread_exit';
function NativeWait(
    Handle: TThreadID;
    Milliseconds: LongInt
): DWord; cdecl; external name 'sr_fpc_thread_wait';
function NativeClose(Handle: TThreadID): DWord; cdecl; external name 'sr_fpc_thread_close';
procedure NativeYield; cdecl; external name 'sr_fpc_thread_yield';
procedure NativeName(Handle: TThreadID; Name: PAnsiChar); cdecl; external name 'sr_fpc_thread_name';
procedure NativeMark(Cleanup: LongInt); cdecl; external name 'sr_fpc_thread_mark';
procedure NativeUnmark; cdecl; external name 'sr_fpc_thread_unmark';
function NativeStackLow: PtrUInt; cdecl; external name 'sr_fpc_stack_low';
function NativeStackHigh: PtrUInt; cdecl; external name 'sr_fpc_stack_high';
procedure NativeMutexInit(var CS); cdecl; external name 'sr_fpc_mutex_init';
procedure NativeMutexDestroy(var CS); cdecl; external name 'sr_fpc_mutex_destroy';
procedure NativeMutexLock(var CS); cdecl; external name 'sr_fpc_mutex_lock';
procedure NativeMutexUnlock(var CS); cdecl; external name 'sr_fpc_mutex_unlock';
function NativeMutexTryLock(var CS): LongInt; cdecl; external name 'sr_fpc_mutex_trylock';
function NativeEventCreate(
    ManualReset,
    Signaled: LongInt
): Pointer; cdecl; external name 'sr_fpc_event_create';
procedure NativeEventDestroy(Event: Pointer); cdecl; external name 'sr_fpc_event_destroy';
procedure NativeEventSet(Event: Pointer); cdecl; external name 'sr_fpc_event_set';
procedure NativeEventReset(Event: Pointer); cdecl; external name 'sr_fpc_event_reset';
function NativeEventWait(
    Event: Pointer;
    Milliseconds: Cardinal
): LongInt; cdecl; external name 'sr_fpc_event_wait';

threadvar
  Attached: Boolean;

procedure SetStackBounds;
begin
  StackBottom := Pointer(NativeStackLow);
  StackLength := NativeStackHigh - PtrUInt(StackBottom);
end;

procedure EnsureEmscriptenThread;
begin
  if Attached then
    Exit;
  Attached := True;
  InitThread(NativeStackHigh - NativeStackLow);
  SetStackBounds;
  NativeMark(1);
end;

procedure CleanupThread; cdecl;
  public name 'sr_fpc_cleanup_thread';
begin
  if not Attached then
    Exit;
  NativeUnmark;
  DoneThread;
  Attached := False;
end;

function RunThread(Argument: Pointer): Pointer; cdecl;
var
  Start: TThreadStart;
begin
  EnsureEmscriptenThread;
  Start := PThreadStart(Argument)^;
  Dispose(PThreadStart(Argument));
  try
    Result := Pointer(Start.Func(Start.Argument));
  finally
    CleanupThread;
  end;
end;

function StartThread(
    SA: Pointer;
    StackSize: PtrUInt;
    Func: TThreadFunc;
    Argument: Pointer;
    Flags: DWord;
    var ID: TThreadID
): TThreadID;
var
  Start: PThreadStart;
begin
  ID := nil;
  { TThread implements its initial suspension with an RTL event. Arbitrary
    pthread suspension is not supported, including CREATE_SUSPENDED here. }
  if Flags <> 0 then
    Exit(nil);
  New(Start);
  Start^.Func := Func;
  Start^.Argument := Argument;
  ID := NativeBegin(@RunThread, Start, StackSize);
  if ID = nil then
    Dispose(Start);
  Result := ID;
end;

procedure FinishThread(Code: DWord);
begin
  CleanupThread;
  NativeExit(Code);
end;

function UnsupportedThread(Handle: TThreadID): DWord;
begin
  Result := DWord(-1);
end;
function CloseThreadHandle(Handle: TThreadID): DWord;
begin
  Result := NativeClose(Handle);
end;
function WaitThread(Handle: TThreadID; Milliseconds: LongInt): DWord;
begin
  Result := NativeWait(Handle, Milliseconds);
end;
procedure YieldThread;
begin
  NativeYield;
end;
function CurrentThreadID: TThreadID;
begin
  Result := NativeSelf;
end;
function SetPriority(Handle: TThreadID; Priority: LongInt): Boolean;
begin
  Result := Priority = 0;
end;
function GetPriority(Handle: TThreadID): LongInt;
begin
  Result := 0;
end;
procedure SetNameA(Handle: TThreadID; const Name: AnsiString);
begin
  NativeName(Handle, PAnsiChar(Name));
end;
procedure SetNameU(Handle: TThreadID; const Name: UnicodeString);
var
  UTF8Name: UTF8String;
begin
  UTF8Name := UTF8Encode(Name);
  NativeName(Handle, PAnsiChar(UTF8Name));
end;
procedure MutexInit(var CS);
begin
  NativeMutexInit(CS);
end;
procedure MutexDone(var CS);
begin
  NativeMutexDestroy(CS);
end;
procedure MutexEnter(var CS);
begin
  NativeMutexLock(CS);
end;
procedure MutexLeave(var CS);
begin
  NativeMutexUnlock(CS);
end;
function MutexTry(var CS): LongInt;
begin
  Result := NativeMutexTryLock(CS);
end;
procedure NoThreadVars;
begin
end;
procedure InitThreadVar(var Offset: DWord; Size: DWord);
begin
end;
function RelocateThreadVar(Offset: DWord): Pointer;
begin
  Result := nil;
end;
function BasicCreate(
    Attributes: Pointer;
    ManualReset, InitialState: Boolean;
    const Name: AnsiString
): PEventState;
begin
  Result := NativeEventCreate(Ord(ManualReset), Ord(InitialState));
end;
procedure BasicDestroy(Event: PEventState);
begin
  NativeEventDestroy(Event);
end;
procedure BasicSet(Event: PEventState);
begin
  NativeEventSet(Event);
end;
procedure BasicReset(Event: PEventState);
begin
  NativeEventReset(Event);
end;
function BasicWait(Timeout: Cardinal; Event: PEventState; UseComWait: Boolean = False): LongInt;
begin
  Result := NativeEventWait(Event, Timeout);
end;
function RTLCreate: PRTLEvent;
begin
  Result := NativeEventCreate(0, 0);
end;
procedure RTLDestroy(Event: PRTLEvent);
begin
  NativeEventDestroy(Event);
end;
procedure RTLSet(Event: PRTLEvent);
begin
  NativeEventSet(Event);
end;
procedure RTLReset(Event: PRTLEvent);
begin
  NativeEventReset(Event);
end;
procedure RTLWait(Event: PRTLEvent);
begin
  NativeEventWait(Event, High(Cardinal));
end;
procedure RTLWaitTimeout(Event: PRTLEvent; Timeout: LongInt);
begin
  if Timeout < 0 then
    NativeEventWait(Event, High(Cardinal))
  else
    NativeEventWait(Event, Cardinal(Timeout));
end;

function InitializeManager: Boolean;
begin
  Attached := True;
  NativeMark(0); // System finalization owns cleanup of the program thread.
  ThreadID := NativeSelf;
  SetStackBounds;
  InitThreadVars(nil); // native TLS is already present; migrate heap locking.
  LazyInitThreading;
  IsMultiThread := True;
  Result := True;
end;
function FinalizeManager: Boolean;
begin
  Result := True;
end;

var
  Manager: TThreadManager;
initialization
  FillChar(Manager, SizeOf(Manager), 0);
  Manager.InitManager := @InitializeManager;
  Manager.DoneManager := @FinalizeManager;
  Manager.BeginThread := @StartThread;
  Manager.EndThread := @FinishThread;
  Manager.SuspendThread := @UnsupportedThread;
  Manager.ResumeThread := @UnsupportedThread;
  Manager.KillThread := @UnsupportedThread;
  Manager.CloseThread := @CloseThreadHandle;
  Manager.ThreadSwitch := @YieldThread;
  Manager.WaitForThreadTerminate := @WaitThread;
  Manager.ThreadSetPriority := @SetPriority;
  Manager.ThreadGetPriority := @GetPriority;
  Manager.GetCurrentThreadId := @CurrentThreadID;
  Manager.SetThreadDebugNameA := @SetNameA;
  Manager.SetThreadDebugNameU := @SetNameU;
  Manager.InitCriticalSection := @MutexInit;
  Manager.DoneCriticalSection := @MutexDone;
  Manager.EnterCriticalSection := @MutexEnter;
  Manager.TryEnterCriticalSection := @MutexTry;
  Manager.LeaveCriticalSection := @MutexLeave;
  Manager.InitThreadVar := @InitThreadVar;
  Manager.RelocateThreadVar := @RelocateThreadVar;
  Manager.AllocateThreadVars := @NoThreadVars;
  Manager.ReleaseThreadVars := @NoThreadVars;
  Manager.BasicEventCreate := @BasicCreate;
  Manager.BasicEventDestroy := @BasicDestroy;
  Manager.BasicEventResetEvent := @BasicReset;
  Manager.BasicEventSetEvent := @BasicSet;
  Manager.BasicEventWaitFor := @BasicWait;
  Manager.RTLEventCreate := @RTLCreate;
  Manager.RTLEventDestroy := @RTLDestroy;
  Manager.RTLEventSetEvent := @RTLSet;
  Manager.RTLEventResetEvent := @RTLReset;
  Manager.RTLEventWaitFor := @RTLWait;
  Manager.RTLEventWaitForTimeout := @RTLWaitTimeout;
  if not SetThreadManager(Manager) then
    Halt(232);
end.
