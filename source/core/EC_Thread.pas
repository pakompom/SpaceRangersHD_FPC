unit EC_Thread;

{$I GameOptions.inc}

interface

uses
  EC_Struct,
  Classes,
  GameEvents,
  SysUtils,
  SyncObjs;

type

  EWorkerFailure = class(Exception)
    WorkerBacktrace: string;
  end;

  TThreadEC = class;

  TThreadEC = class(TObjectEx)
  private
    Worker: TThread;
    Failure: string;
    FailureBacktrace: string;
  public
    Lock: TCriticalSection;
    ThreadHandle: TThreadID;
    ThreadId: TThreadID;
    Priority: Byte;
    StopRequested: Boolean;
    StopEvent: TGameEventHandle;
    Flag18: Boolean;
    ShutdownEvent: TGameEventHandle;
    StartEvent: TGameEventHandle;
    RunningEvent: TGameEventHandle;
    IdleEvent: TGameEventHandle;
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
    procedure CheckFailure;
  end;

const

  ThreadPriorityLowest = 1;

  ThreadPriorityAboveNormal = 4;

implementation

type
  TGameWorker = class(TThread)
    Owner: TThreadEC;
    procedure Execute; override;
  end;

procedure TGameWorker.Execute;
begin
  Owner.ProcessRequests;
end;

constructor TThreadEC.Create;
var
  NewWorker: TGameWorker;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  StopEvent := CreateGameEvent(True, False);
  ShutdownEvent := CreateGameEvent(False, False);
  StartEvent := CreateGameEvent(False, False);
  RunningEvent := CreateGameEvent(True, False);
  IdleEvent := CreateGameEvent(True, True);
  NewWorker := TGameWorker.Create(True);
  Worker := NewWorker;
  NewWorker.Owner := Self;
  ThreadHandle := Worker.Handle;
  ThreadId := Worker.ThreadID;
  Worker.Start;
end;

destructor TThreadEC.Destroy;
begin
  if Worker <> nil then
  begin
    RequestStop;
    SetGameEvent(ShutdownEvent);
    Worker.WaitFor;
    FreeAndNil(Worker);
  end;
  CloseGameEvent(IdleEvent);
  CloseGameEvent(StartEvent);
  CloseGameEvent(RunningEvent);
  CloseGameEvent(ShutdownEvent);
  CloseGameEvent(StopEvent);
  Lock.Free;
  inherited Destroy;
end;

procedure TThreadEC.CheckFailure;
var
  Message, Backtrace: string;
  Error: EWorkerFailure;
begin
  Lock.Enter;
  try
    Message := Failure;
    Backtrace := FailureBacktrace;
  finally
    Lock.Leave;
  end;
  if Message <> '' then
  begin
    Error := EWorkerFailure.Create(ClassName + ': ' + Message);
    Error.WorkerBacktrace := Backtrace;
    raise Error;
  end;
end;

procedure TThreadEC.ProcessRequests;
var
  Events: array[0..1] of TGameEventHandle;
  Failed: Boolean;
  Frame: Integer;
begin
  Events[0] := ShutdownEvent;
  Events[1] := StartEvent;
  while WaitGameEvents(Length(Events), @Events, False, INFINITE) = WAIT_OBJECT_0 + 1 do
  begin
    Failed := False;
    try
      Execute;
    except
      Lock.Enter;
      try
        Failure := ExceptObject.ClassName;
        if ExceptObject is Exception then
          Failure := Failure + ': ' + Exception(ExceptObject).Message;
        // Copy diagnostics; generation and the UI may both observe this failure.
        if ExceptObject is EWorkerFailure then
          FailureBacktrace := EWorkerFailure(ExceptObject).WorkerBacktrace
        else if Assigned(BackTraceStrFunc) then
        begin
          FailureBacktrace := BackTraceStrFunc(ExceptAddr);
          for Frame := 0 to ExceptFrameCount - 1 do
            FailureBacktrace :=
                FailureBacktrace + LineEnding + BackTraceStrFunc(ExceptFrames[Frame]);
        end;
      finally
        Lock.Leave;
      end;
      Failed := True;
    end;
    Lock.Enter;
    try
      ResetGameEvent(RunningEvent);
      SetGameEvent(IdleEvent);
    finally
      Lock.Leave;
    end;
    // Publish completion even after failure so a waiting UI can report it.
    if Failed then
      Exit;
  end;
end;

procedure TThreadEC.Execute;
begin
  while not IsStopRequested do
    SysUtils.Sleep(100);
end;

procedure TThreadEC.SetPriority(Value: Byte);
begin
  Priority := Value;
  if Worker <> nil then
    Worker.Priority := TThreadPriority(Value);
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
  SetGameEvent(StopEvent);
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
    ResetGameEvent(StopEvent);
    Lock.Leave;
  end;
end;

procedure TThreadEC.Start;
begin
  CheckFailure;
  Lock.Enter;
  try
    if IsRunning then
      Exit;
    ResetGameEvent(StopEvent);
    StopRequested := False;
    ResetGameEvent(IdleEvent);
    SetGameEvent(RunningEvent);
    SetGameEvent(StartEvent);
  finally
    Lock.Leave;
  end;
end;

function TThreadEC.IsRunning: Boolean;
begin
  CheckFailure;
  Result := WaitGameEvent(IdleEvent, 0) = WAIT_TIMEOUT;
end;

function TThreadEC.WaitForIdle(TimeoutMs: Cardinal): Boolean;
begin
  Result := WaitGameEvent(IdleEvent, TimeoutMs) = WAIT_OBJECT_0;
  CheckFailure;
end;

end.
