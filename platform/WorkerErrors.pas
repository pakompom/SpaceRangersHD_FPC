{$EXCESSPRECISION OFF}
unit WorkerErrors;

// Host-only transfer of worker failures to the main thread's error dialog.
interface

uses
  SysUtils;

type
  EWorkerFailure = class(Exception);

procedure ReportWorkerError(const WorkerName, ErrorClass, ErrorMessage: AnsiString);
procedure RaisePendingWorkerError;

implementation

uses
  SyncObjs;

var
  ErrorLock: TCriticalSection;
  PendingError: AnsiString;

procedure ReportWorkerError(const WorkerName, ErrorClass, ErrorMessage: AnsiString);
begin
  ErrorLock.Enter;
  try
    if PendingError = '' then
      PendingError := WorkerName + ': ' + ErrorClass + ': ' + ErrorMessage;
  finally
    ErrorLock.Leave;
  end;
end;

procedure RaisePendingWorkerError;
var
  ErrorText: AnsiString;
begin
  ErrorLock.Enter;
  try
    ErrorText := PendingError;
    PendingError := '';
  finally
    ErrorLock.Leave;
  end;
  if ErrorText <> '' then
    raise EWorkerFailure.Create(ErrorText);
end;

initialization
  ErrorLock := TCriticalSection.Create;
finalization
  ErrorLock.Free;
end.
