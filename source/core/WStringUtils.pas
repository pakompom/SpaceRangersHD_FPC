{$EXCESSPRECISION OFF}
unit WStringUtils;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
type
  PointerToWideString = ^WideString;
type
  PStartupWideString = PointerToWideString;
function AllocateStartupWideString(Length: Integer): PStartupWideString;
function TruncateStartupWideString(var Text: PStartupWideString): PStartupWideString;
function FreeStartupWideString(var Text: PStartupWideString): Boolean;
implementation
uses
  Math;

function AllocateStartupWideString(Length: Integer): PStartupWideString;
begin
  New(Result);
  SetLength(Result^, Length);
end;

function TruncateStartupWideString(var Text: PStartupWideString): PStartupWideString;
var
  Count: Integer;
begin
  Count := 0;
  while Text^[Count + 1] <> #0 do
    Inc(Count);
  SetLength(Text^, Count);
  Result := Text;
end;

function FreeStartupWideString(var Text: PStartupWideString): Boolean;
begin
  Result := False;
  if Text <> nil then
  begin
    Dispose(Text);
    Result := True;
  end;
end;

end.
