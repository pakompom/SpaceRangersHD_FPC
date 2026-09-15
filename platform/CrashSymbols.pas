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

var
  RuntimeBackTrace: TBackTraceStrFunc;

threadvar
  ResolvingAddress: Boolean;

function DescribeCodeAddress(Address: Pointer): AnsiString;
var
  Info: dl_info;
  Symbolizer: TProcess;
  Output: TStringList;
  Raw, Resolved: AnsiString;
begin
  Raw := '$' + IntToHex(PtrUInt(Address), SizeOf(Pointer) * 2);
  Result := Raw;
  if ResolvingAddress then
    Exit;
  ResolvingAddress := True;
  try
    try
      Result := RuntimeBackTrace(Address);
      // CHANGE: BUGFIX - Fall back when FPC cannot read the Mach-O/DWARF symbols.
      if Trim(Result) <> Raw then
        Exit;
      FillChar(Info, SizeOf(Info), 0);
      if dladdr(Address, @Info) = 0 then
        Exit;
      if (Info.dli_fname = nil) or (Info.dli_fbase = nil) then
        Exit;
      Symbolizer := TProcess.Create(nil);
      try
        Output := TStringList.Create;
        try
          Symbolizer.Executable := '/usr/bin/atos';
          Symbolizer.Parameters.Add('-fullPath');
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
            if (Resolved <> '') and (Copy(Resolved, 1, 2) <> '0x') then
              Result := Raw + '  ' + Resolved;
          end;
        finally
          Output.Free;
        end;
      finally
        Symbolizer.Free;
      end;
    except
      // Reporting must never replace the original exception.
      Result := Raw;
    end;
  finally
    ResolvingAddress := False;
  end;
end;

function SymbolizedBackTrace(Address: CodePointer): ShortString;
begin
  Result := DescribeCodeAddress(Address);
end;

initialization
  // CHANGE: BUGFIX - Also symbolize RTL dumps and unhandled exceptions.
  RuntimeBackTrace := BackTraceStrFunc;
  BackTraceStrFunc := @SymbolizedBackTrace;

end.
