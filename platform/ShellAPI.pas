unit ShellAPI;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
uses
  Windows;
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
implementation
uses
  SysUtils;
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
begin
  if ExecuteProcess('/usr/bin/open', [AnsiString(FileName)]) = 0 then
    Result := 33
  else
    Result := 2;
end;
end.
