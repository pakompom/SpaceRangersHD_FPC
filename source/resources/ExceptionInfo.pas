unit ExceptionInfo;

{$I GameOptions.inc}

interface

const

  ExportHexDigits: array[0..15] of WideChar =
      ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

function HexDigit(Value: Byte): WideChar;

function ByteToHexText(Value: Byte): WideString;

implementation

function HexDigit(Value: Byte): WideChar;
begin
  Result := ExportHexDigits[Value and $F];
end;

function HexDigitAt(Value: Byte; Index: Integer): WideChar; inline;
begin
  Result := HexDigit(Value shr (Index * 4));
end;

function ByteToHexText(Value: Byte): WideString;
begin
  SetLength(Result, 2);
  Result[1] := HexDigitAt(Value, 1);
  Result[2] := HexDigitAt(Value, 0);
end;

end.
