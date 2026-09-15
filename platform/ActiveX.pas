unit ActiveX;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
function CoInitialize(Reserved: Pointer): LongInt;
procedure CoUninitialize;
implementation
function CoInitialize(Reserved: Pointer): LongInt;
begin
  Result := 0
end;
procedure CoUninitialize;
begin
end;
end.
