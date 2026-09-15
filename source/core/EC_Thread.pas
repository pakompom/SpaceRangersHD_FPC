{$EXCESSPRECISION OFF}
unit EC_Thread;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Struct,
  SyncObjs;
type
  TThreadEC = class;
  TThreadEC = class(TObjectEx)
    NativeThread: TThread;
    Lock: TCriticalSection;
    ThreadHandle: Cardinal;
    ThreadId: Cardinal;
    Priority: Byte;
    StopRequested: Boolean;
    Gap12: array[0..1] of Byte;
    StopEvent: Cardinal;
    Flag18: Boolean;
    Gap19: array[0..2] of Byte;
    ShutdownEvent: Cardinal;
    StartEvent: Cardinal;
    RunningEvent: Cardinal;
    IdleEvent: Cardinal;
    procedure Execute; virtual;
    constructor Create;
    destructor Destroy; override;
    procedure ProcessRequests;
    procedure SetPriority(Value: Byte);
    procedure SetFlag18;
    procedure ClearFlag18;
    procedure RequestStop;
    function IsStopRequested: Boolean;
    procedure SetStopRequested(Value: Boolean);
    procedure Start;
    function IsRunning: Boolean;
    function WaitForIdle(TimeoutMs: Cardinal): Boolean;
  end;
const
  ThreadPriorityLowest = 1;
  ThreadPriorityAboveNormal = 4;
  ThreadPriorityValues: array[0..6] of Integer = (-15, -2, -1, 0, 1, 2, 15);
function ThreadEntryEC(Thread: Pointer): Integer;
implementation

uses
  Math,
  WorkerErrors,
  Windows,
  SysUtils,
  GR_Main;
type
  TRequestThread = class(TThread)
    Owner: TThreadEC;
    procedure Execute; override;
  end;
procedure TRequestThread.Execute;
begin
  // FPC initializes each Pascal thread with floating-point traps enabled.
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  Owner.ProcessRequests;
end;

function ThreadEntryEC(Thread: Pointer): Integer;
begin
  TThreadEC(Thread).ProcessRequests;
  Result := 0
end;
constructor TThreadEC.Create;

var
  Worker: TRequestThread;

begin
  inherited Create;
  Lock := TCriticalSection.Create;
  StopEvent := CreateEvent(nil, True, False, nil);
  ShutdownEvent := CreateEvent(nil, False, False, nil);
  StartEvent := CreateEvent(nil, False, False, nil);
  RunningEvent := CreateEvent(nil, True, False, nil);
  IdleEvent := CreateEvent(nil, True, True, nil);

  Worker := TRequestThread.Create(True);
  Worker.Owner := Self;
  NativeThread := Worker;
  Worker.Start;

end;
destructor TThreadEC.Destroy;
begin
  RequestStop;
  SetEvent(ShutdownEvent);
  SetEvent(StartEvent);
  if NativeThread <> nil then
  begin
    NativeThread.WaitFor;
    NativeThread.Free
  end;
  CloseHandle(IdleEvent);
  CloseHandle(StartEvent);
  CloseHandle(RunningEvent);
  CloseHandle(ShutdownEvent);
  CloseHandle(StopEvent);
  Lock.Free;
  inherited Destroy;
end;
procedure TThreadEC.ProcessRequests;
var
  Events: array[0..1] of Windows.THandle;
  WaitResult: Cardinal;
begin
  Events[0] := ShutdownEvent;
  Events[1] := StartEvent;
  while True do
  begin
    WaitResult := WaitForMultipleObjects(Length(Events), @Events, False, INFINITE);
    if WaitResult <> WAIT_OBJECT_0 + 1 then
      Break;
    Lock.Enter;
    try
      // The portable multi-event wait polls its handles in order. Shutdown can
      // arrive between its shutdown probe and start probe; the destructor's
      // wake-up must never dispatch one last job against released game state.
      if WaitForSingleObject(ShutdownEvent, 0) = WAIT_OBJECT_0 then
        Break;
      if not IsRunning then
      begin
        ResetEvent(StopEvent);
        StopRequested := False;
        ResetEvent(IdleEvent);
        SetEvent(RunningEvent);
      end;
    finally
      Lock.Leave;
    end;
    try
      Execute;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.Message);
        AppendLogLineThreadSafe('Thread exception');
        LogExceptionBackTrace;
        ReportWorkerError(ClassName, E.ClassName, E.Message);
        ResetEvent(RunningEvent);
        SetEvent(IdleEvent);
        System.ExitCode := 1;
        GR_Main.ExitScreenLoop := True;
        raise;
      end;
    end;
    Lock.Enter;
    try
      ResetEvent(RunningEvent);
      SetEvent(IdleEvent);
    finally
      Lock.Leave;
    end;
  end;
end;
procedure TThreadEC.Execute;
begin
  while not IsStopRequested do
    SysUtils.Sleep(100);
end;
procedure TThreadEC.SetPriority(Value: Byte);
begin
  Priority := Value
end;
procedure TThreadEC.SetFlag18;
begin
  Flag18 := True;
end;
procedure TThreadEC.ClearFlag18;
begin
  Flag18 := False;
end;
procedure TThreadEC.RequestStop;
begin
  Lock.Enter;
  StopRequested := True;
  SetEvent(StopEvent);
  Lock.Leave;
end;
function TThreadEC.IsStopRequested: Boolean;
begin
  Lock.Enter;
  Result := StopRequested;
  Lock.Leave;
end;
procedure TThreadEC.SetStopRequested(Value: Boolean);
begin
  if Value then
    RequestStop
  else
  begin
    Lock.Enter;
    StopRequested := False;
    ResetEvent(StopEvent);
    Lock.Leave;
  end;
end;
procedure TThreadEC.Start;
begin

  Lock.Enter;
  try
    if IsRunning then
      Exit;
    ResetEvent(StopEvent);
    StopRequested := False;
    ResetEvent(IdleEvent);
    SetEvent(RunningEvent);
    SetEvent(StartEvent);
  finally
    Lock.Leave;
  end;

end;
function TThreadEC.IsRunning: Boolean;
begin
  Lock.Enter;
  Result := WaitForSingleObject(IdleEvent, 0) = WAIT_TIMEOUT;
  Lock.Leave;
end;
function TThreadEC.WaitForIdle(TimeoutMs: Cardinal): Boolean;
begin
  if WaitForSingleObject(IdleEvent, TimeoutMs) = WAIT_TIMEOUT then
    Result := False
  else
    Result := True;
end;
end.
