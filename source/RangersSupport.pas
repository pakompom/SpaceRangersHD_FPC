{$EXCESSPRECISION OFF}
unit RangersSupport;
interface
procedure MissingImplementation(Address: Cardinal; const Captures: array of Pointer);
implementation
uses
  SysUtils;
procedure MissingImplementation(Address: Cardinal; const Captures: array of Pointer);
begin
  raise Exception.Create('Unrecovered native routine: ' + IntToHex(Address, 8));
end;
end.
