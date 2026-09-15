unit CrashSymbols;
{$MODE delphi}
{$EXCESSPRECISION OFF}

interface

function DescribeCodeAddress(Address: Pointer): AnsiString;

implementation

uses
  SysUtils,
  Classes,
  Process,
  DL;

function DescribeCodeAddress(Address: Pointer): AnsiString;
var
  Info: dl_info;
  Symbolizer: TProcess;
  Output: TStringList;
  Raw, Resolved: AnsiString;
begin
  Raw := '$' + IntToHex(PtrUInt(Address), SizeOf(Pointer) * 2);
  Result := BackTraceStrFunc(Address);
  // FPC 3.2.2's Mach-O reader can fail even with matching packaged DWARF.
  if Trim(Result) <> Raw then
    Exit;
  FillChar(Info, SizeOf(Info), 0);
  if dladdr(Address, @Info) = 0 then
    Exit;
  if (Info.dli_fname = nil) or (Info.dli_fbase = nil) then
    Exit;
  Symbolizer := TProcess.Create(nil);
  Output := TStringList.Create;
  try
    try
      Symbolizer.Executable := '/usr/bin/atos';
      Symbolizer.Parameters.Add('-o');
      Symbolizer.Parameters.Add(AnsiString(Info.dli_fname));
      Symbolizer.Parameters.Add('-l');
      Symbolizer.Parameters.Add('0x' + IntToHex(PtrUInt(Info.dli_fbase), 1));
      Symbolizer.Parameters.Add('0x' + IntToHex(PtrUInt(Address), 1));
      Symbolizer.Options := [poUsePipes, poStderrToOutPut];
      Symbolizer.Execute;
      Output.LoadFromStream(Symbolizer.Output);
      Symbolizer.WaitOnExit;
      if (Symbolizer.ExitStatus = 0) and (Output.Count > 0) then
      begin
        Resolved := Trim(Output[0]);
        if Resolved <> '' then
          Result := Raw + '  ' + Resolved;
      end;
    except
      // Reporting must never replace the original exception.
    end;
  finally
    Output.Free;
    Symbolizer.Free;
  end;
end;

end.
