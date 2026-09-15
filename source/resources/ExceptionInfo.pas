{$EXCESSPRECISION OFF}
unit ExceptionInfo;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SysUtils;
type
  TRaiseExceptionCallback =
      procedure(Code: Cardinal; Flags: Cardinal; ArgumentCount: Cardinal; Arguments: Pointer);
      stdcall;
const
  ExportHexDigits: array[0..15] of WideChar =
      ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  ReportingException: Boolean = False;
  PreviousRaiseException: TRaiseExceptionCallback = nil;
function HexDigit(Value: Byte): WideChar;
function ByteToHexText(Value: Byte): WideString;
function ExceptionLogTimestamp: AnsiString;
procedure ReportUnhandledException(E: Exception; var Handled: Boolean);
procedure RaiseExceptionWithLogging(
    Code: Cardinal;
    Flags: Cardinal;
    ArgumentCount: Cardinal;
    Arguments: Pointer
); stdcall;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Windows,
  GR_Main,
  BlockParException,
  BreakMessageGIException;
// @unit-initialization $877884
// @unit-finalization $57AFBC

function HexDigit(Value: Byte): WideChar;
begin
  Result := ExportHexDigits[Value and $F];
end;

function ByteToHexText(Value: Byte): WideString;
begin
  SetLength(Result, 2);
  Result[1] := HexDigit(Value shr 4);
  Result[2] := HexDigit(Value shr 0);
end;

function ExceptionLogTimestamp: AnsiString;
var
  Time: TDateTime;
  Text: AnsiString;
begin
  Time := Now;
  DateTimeToString(Text, 'yyyy.mm.dd hh.nn.ss.zzz', Time);
  Result := Text;
end;

procedure ReportUnhandledException(E: Exception; var Handled: Boolean);
var
  TargetName, SourceName: WideString;
begin
  if E is EBreakMessageGI then
    Handled := False
  else
  begin
    if E is EBlockPar then
      if not (E as EBlockPar).IsReportable then
        Handled := False;
    AppendLogLineThreadSafe('Exception ' + E.ClassName + ' with message ' + E.Message);
    Handled := False;
    if SuppressExceptionLogCopy then
      SuppressExceptionLogCopy := False
    else
    begin
      CreateDir(AnsiString(GetGameUserDirectory + 'Errors'));
      TargetName := GetGameUserDirectory + 'Errors\' + WideString(ExceptionLogTimestamp) + '.log';
      SourceName := GetGameUserDirectory + RuntimeLogFileName;
      CopyFileW(PWideChar(SourceName), PWideChar(TargetName), False);
    end;
  end;
end;

procedure RaiseExceptionWithLogging(
    Code, Flags, ArgumentCount: Cardinal;
    Arguments: Pointer
); stdcall;
var
  Handled: Boolean;
begin
  if Assigned(PreviousRaiseException) then
  begin
    if ReportingException then
      PreviousRaiseException(Code, Flags, ArgumentCount, Arguments)
    else
    begin
      ReportingException := True;
      try
        try
          PreviousRaiseException(Code, Flags, ArgumentCount, Arguments);
        except
          on E: Exception do
          begin
            Handled := False;
            ReportUnhandledException(E, Handled);
            if not Handled then
              raise;
          end;
        end;
      finally
        ReportingException := False;
      end;
    end;
  end;
end;

// Native initializer $877884 saves and replaces the RTL raise hook.
procedure LinkRecoveredTypes;
begin
  EBlockPar.ClassName;
  EBreakMessageGI.ClassName;
end;
// FPC unwinds through its own runtime. GameBootstrap and TThreadEC log
// uncaught exceptions without replacing Delphi's Windows raise hook.
end.
