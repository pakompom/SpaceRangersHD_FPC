unit CrashSymbols;
{$MODE delphi}
interface
function DescribeCodeAddress(Address: Pointer): AnsiString;
implementation
uses
  SysUtils,
  DL;
function DescribeCodeAddress(Address: Pointer): AnsiString;
var
  Info: dl_info;
begin
  Result := BackTraceStrFunc(Address);
  FillChar(Info, SizeOf(Info), 0);
  if (dladdr(Address, @Info) <> 0) and (Info.dli_fbase <> nil) and (Info.dli_fname <> nil) then
    Result :=
        ExtractFileName(AnsiString(Info.dli_fname))
            + '+$'
            + IntToHex(PtrUInt(Address) - PtrUInt(Info.dli_fbase), 1)
            + '  '
            + Result;
end;
end.
