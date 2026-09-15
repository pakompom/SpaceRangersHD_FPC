{$EXCESSPRECISION OFF}
unit EC_Str;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
type
  TStringsEC = class;
  TStringsElEC = class;
  THexDigits = array[0..15] of WideChar;
  TWideCasePair = packed record
    LowerChar: WideChar;
    UpperChar: WideChar;
  end;
  TStringsElEC = class(TObject)
    Prev: TStringsElEC;
    Next: TStringsElEC;
    Text: WideString;
    Data: Pointer;
  end;
  TStringsEC = class(TObject)
    FirstElement: TStringsElEC;
    LastElement: TStringsElEC;
    CurrentElement: TStringsElEC;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddEmptyElement: TStringsElEC;
    procedure AppendElement(Item: TStringsElEC);
    procedure RemoveAndFreeElement(Item: TStringsElEC);
    function GetElement(Index: Integer): TStringsElEC;
    function EnsureElement(Index: Integer): TStringsElEC;
    function GetCount: Integer;
    function GetTextAt(Index: Integer): WideString;
    function GetDataAt(Index: Integer): Pointer;
    procedure SetDataAt(Index: Integer; Data: Pointer);
    function IndexOf(const Text: WideString): Integer;
    procedure Add(const Text: WideString);
    procedure AddSlice(Text: PWideChar; CharCount: Integer);
    procedure Delete(Index: Integer);
    function GetCurrentText: WideString;
    function GetCurrentData: Pointer;
    function IsAtEnd: Boolean;
    function IsAtLast: Boolean;
    procedure First;
    procedure Next;
    function IsEmpty: Boolean;
    procedure SetText(const Text: WideString);
    function GetText: WideString;
  end;
const
  HexDigits: THexDigits =
      ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
function CountDelimitedPartsW(const Text: WideString; const Delimiters: WideString): Integer;
function GetDelimitedPartStartIndexW(
    const Text: WideString;
    PartIndex: Integer;
    const Delimiters: WideString
): Integer;
function GetCharDelimitedPartStartIndexW(
    const Text: WideString;
    PartIndex: Integer;
    Delimiter: WideChar
): Integer;
function GetDelimitedPartLengthW(
    const Text: WideString;
    StartIndex: Integer;
    const Delimiters: WideString
): Integer;
function ExtractDelimitedPartW(
    const Text: WideString;
    PartIndex: Integer;
    const Delimiters: WideString
): WideString;
function ExtractDelimitedRangeW(
    const Text: WideString;
    FirstPart: Integer;
    LastPart: Integer;
    const Delimiters: WideString
): WideString;
function ExtractNextDelimitedPartW(var Text: WideString; Delimiter: WideChar): WideString;
function ExtractLineCommentW(const Text: WideString): WideString;
function RemoveLineCommentW(const Text: WideString): WideString;
function IsIntegerTextW(const Text: WideString): Boolean;
function ExtractDigitsToIntW(const Text: WideString): Integer;
function ExtractSignedDigitsToIntW(const Text: WideString): Integer;
function ExtractDecimalToSingleW(const Text: WideString): Single;
function ParseDecimalToSingleW(const Text: WideString): Single;
function FloatToWideString(Value: Double): WideString;
function ReplaceAllWideString(
    const Text: WideString;
    const Search: WideString;
    const Replacement: WideString
): WideString;
function CardinalToHexWideString(Value: Cardinal): WideString;
function IntToFixedWidthWideString(Value: Integer; Width: Integer): WideString;
function IntToWideString(Value: Integer): WideString;
function BoolToWideString(Value: Boolean): WideString;
function TrimWideString(const Text: WideString): WideString;
function UpperCaseWideString(const Text: WideString): WideString;
function LowerCaseWideString(const Text: WideString): WideString;
function RemoveWideStringChars(const Text: WideString; Chars: WideString): WideString;
function GetTextTagLengthW(Text: PWideChar; CharCount: Integer): Integer;
function MatchTextTagPrefixW(
    Text: PWideChar;
    CharCount: Integer;
    const Pattern: WideString;
    const AlternatePattern: WideString
): Boolean;
function RemoveTextTagsW(const Text: WideString): WideString;
function RemoveMatchingTextTagsW(
    Text: WideString;
    const Pattern: WideString;
    const AlternatePattern: WideString
): WideString;
function CompareWideChars(Left: PWideChar; Right: PWideChar): Integer; cdecl;
function FindTextOffsetW(
    const Text: WideString;
    const Search: WideString;
    StartIndex: Integer = 0
): Integer;
function FindTextPosW(const Search: WideString; const Text: WideString): Integer;
function ExtractFileNameNoExtW(const Path: WideString): WideString;
function ExtractFileExtNoDotW(const Path: WideString): WideString;
function ExtractFileDirW(const Path: WideString): WideString;
procedure WriteRegistryStringLegacy(
    RootKey: Cardinal;
    KeyPath: WideString;
    ValueName: WideString;
    Value: WideString
);
function DecodeLegacySaveLabel(Text: WideString): WideString;
function EncodeLegacySaveLabel(Text: WideString): WideString;
function TransliterateCyrillicToLatin(Text: WideString): WideString;
function CopyWideStringUnchecked(Text: WideString; Index: Integer; Count: Integer): WideString;
implementation
uses
  Math,
  EC_Mem,
  GR_Main,
  SysUtils,
  Windows;

constructor TStringsEC.Create;
begin
  inherited Create;
end;

destructor TStringsEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TStringsEC.Clear;
begin
  while FirstElement <> nil do
    RemoveAndFreeElement(LastElement);
  CurrentElement := nil;
end;

function TStringsEC.AddEmptyElement: TStringsElEC;
var
  Item: TStringsElEC;
begin
  Item := TStringsElEC.Create;
  AppendElement(Item);
  Result := Item;
end;

procedure TStringsEC.AppendElement(Item: TStringsElEC);
begin
  if LastElement <> nil then
    LastElement.Next := Item;
  Item.Prev := LastElement;
  Item.Next := nil;
  LastElement := Item;
  if FirstElement = nil then
    FirstElement := Item;
end;

procedure TStringsEC.RemoveAndFreeElement(Item: TStringsElEC);
begin
  if Item.Prev <> nil then
    Item.Prev.Next := Item.Next;
  if Item.Next <> nil then
    Item.Next.Prev := Item.Prev;
  if LastElement = Item then
    LastElement := Item.Prev;
  if FirstElement = Item then
    FirstElement := Item.Next;
  Item.Free;
end;

function TStringsEC.GetElement(Index: Integer): TStringsElEC;
var
  Item: TStringsElEC;
begin
  Item := FirstElement;
  while Item <> nil do
  begin
    if Index = 0 then
    begin
      Result := Item;
      Exit;
    end;
    Dec(Index);
    Item := Item.Next;
  end;
  raise Exception.Create('TStringsEC.El_Get. i=' + SysUtils.IntToStr(Index));
end;

function TStringsEC.EnsureElement(Index: Integer): TStringsElEC;
var
  Item: TStringsElEC;
begin
  if Index < 0 then
    raise Exception.Create('TStringsEC.El_GetEx. i=' + SysUtils.IntToStr(Index));
  Item := FirstElement;
  while Item <> nil do
  begin
    if Index = 0 then
    begin
      Result := Item;
      Exit;
    end;
    Dec(Index);
    Item := Item.Next;
  end;
  while Index >= 0 do
  begin
    AddEmptyElement;
    Dec(Index);
  end;
  Result := LastElement;
end;

function TStringsEC.GetCount: Integer;
var
  Item: TStringsElEC;
begin
  Item := FirstElement;
  Result := 0;
  while Item <> nil do
  begin
    Inc(Result);
    Item := Item.Next;
  end;
end;

function TStringsEC.GetTextAt(Index: Integer): WideString;
begin
  Result := EnsureElement(Index).Text;
end;

function TStringsEC.GetDataAt(Index: Integer): Pointer;
begin
  Result := EnsureElement(Index).Data;
end;

procedure TStringsEC.SetDataAt(Index: Integer; Data: Pointer);
begin
  EnsureElement(Index).Data := Data;
end;

function TStringsEC.IndexOf(const Text: WideString): Integer;
var
  Item: TStringsElEC;
  i: Integer;
begin
  Item := FirstElement;
  i := 0;
  while Item <> nil do
  begin
    if Item.Text = Text then
    begin
      Result := i;
      Exit;
    end;
    Inc(i);
    Item := Item.Next;
  end;
  Result := -1;
end;

procedure TStringsEC.Add(const Text: WideString);
begin
  AddEmptyElement.Text := Text;
end;

procedure TStringsEC.AddSlice(Text: PWideChar; CharCount: Integer);
var
  Item: TStringsElEC;
begin
  Item := AddEmptyElement;
  if CharCount > 0 then
  begin
    SetLength(Item.Text, CharCount);
    CopyMemory(PWideChar(Item.Text), Text, CharCount * 2);
  end;
end;

procedure TStringsEC.Delete(Index: Integer);
var
  Item: TStringsElEC;
begin
  Item := GetElement(Index);
  if Item = CurrentElement then
  begin
    CurrentElement := Item.Next;
    if CurrentElement = nil then
      CurrentElement := Item.Prev;
  end;
  RemoveAndFreeElement(Item);
end;

function TStringsEC.GetCurrentText: WideString;
begin
  if CurrentElement = nil then
    raise Exception.Create('TStringsEC.Get.');
  Result := CurrentElement.Text;
end;

function TStringsEC.GetCurrentData: Pointer;
begin
  if CurrentElement = nil then
    raise Exception.Create('TStringsEC.GetData.');
  Result := CurrentElement.Data;
end;

function TStringsEC.IsAtEnd: Boolean;
begin
  if CurrentElement <> nil then
    Result := False
  else
    Result := True;
end;

function TStringsEC.IsAtLast: Boolean;
begin
  if CurrentElement.Next <> nil then
    Result := False
  else
    Result := True;
end;

procedure TStringsEC.First;
begin
  CurrentElement := FirstElement;
end;

procedure TStringsEC.Next;
begin
  CurrentElement := CurrentElement.Next;
end;

function TStringsEC.IsEmpty: Boolean;
begin
  Result := FirstElement = nil;
end;

procedure TStringsEC.SetText(const Text: WideString);
var
  Cursor, Start: PWideChar;
begin
  Clear;
  Cursor := PWideChar(Text);
  if Cursor <> nil then
    while Cursor^ <> #0 do
    begin
      Start := Cursor;
      while (Cursor^ <> #0) and (Cursor^ <> #10) and (Cursor^ <> #13) do
        Inc(Cursor);
      AddSlice(Start, (PtrUInt(Cursor) - PtrUInt(Start)) div 2);
      if Cursor^ = #13 then
        Inc(Cursor);
      if Cursor^ = #10 then
        Inc(Cursor);
    end;
end;

function TStringsEC.GetText: WideString;
var
  Item: TStringsElEC;
begin
  Item := FirstElement;
  Result := '';
  while Item <> nil do
  begin
    if Item.Next = nil then
      Result := Result + Item.Text
    else
      Result := Result + Item.Text + #13 + #10;
    Item := Item.Next;
  end;
end;

function CountDelimitedPartsW(const Text: WideString; const Delimiters: WideString): Integer;
var
  TextLength, DelimiterCount, i, j, Count: Integer;
begin
  Count := 1;
  TextLength := Length(Text);
  DelimiterCount := Length(Delimiters);
  if Cardinal(TextLength) < 1 then
  begin
    Result := 0;
    Exit
  end;
  for i := 1 to TextLength do
    for j := 1 to DelimiterCount do
      if Text[i] = Delimiters[j] then
      begin
        Inc(Count);
        Break;
      end;
  Result := Count;
end;

function GetDelimitedPartStartIndexW(
    const Text: WideString;
    PartIndex: Integer;
    const Delimiters: WideString
): Integer;
var
  TextLength, DelimiterCount, i, j: Integer;
begin
  if PartIndex > 0 then
  begin
    TextLength := Length(Text);
    DelimiterCount := Length(Delimiters);
    for i := 1 to TextLength do
      for j := 1 to DelimiterCount do
        if Text[i] = Delimiters[j] then
        begin
          Dec(PartIndex);
          if PartIndex = 0 then
          begin
            Result := i + 1;
            Exit
          end;
          Break;
        end;
    raise Exception.Create(
        'GetSmeParEC. Str=' + Text + ' np=' + SysUtils.IntToStr(PartIndex) + ' raz=' + Delimiters);
  end;
  Result := 1;
end;

function GetCharDelimitedPartStartIndexW(
    const Text: WideString;
    PartIndex: Integer;
    Delimiter: WideChar
): Integer;
var
  TextLength, i: Integer;
begin
  if PartIndex > 0 then
  begin
    TextLength := Length(Text);
    for i := 1 to TextLength do
      if Text[i] = Delimiter then
      begin
        Dec(PartIndex);
        if PartIndex = 0 then
        begin
          Result := i + 1;
          Exit
        end;
        Break;
      end;
    Result := -1;
    Exit;
  end;
  Result := 1;
end;

function GetDelimitedPartLengthW(
    const Text: WideString;
    StartIndex: Integer;
    const Delimiters: WideString
): Integer;
var
  TextLength, DelimiterCount, i, j: Integer;
begin
  TextLength := Length(Text);
  DelimiterCount := Length(Delimiters);
  for i := StartIndex to TextLength do
    for j := 1 to DelimiterCount do
      if Text[i] = Delimiters[j] then
      begin
        Result := i - StartIndex;
        Exit;
      end;
  Result := TextLength - StartIndex + 1;
end;

function ExtractDelimitedPartW(
    const Text: WideString;
    PartIndex: Integer;
    const Delimiters: WideString
): WideString;
var
  StartIndex: Integer;
begin
  StartIndex := GetDelimitedPartStartIndexW(Text, PartIndex, Delimiters);
  Result := Copy(Text, StartIndex, GetDelimitedPartLengthW(Text, StartIndex, Delimiters));
end;

function ExtractDelimitedRangeW(
    const Text: WideString;
    FirstPart: Integer;
    LastPart: Integer;
    const Delimiters: WideString
): WideString;
var
  StartIndex, EndIndex: Integer;
begin
  StartIndex := GetDelimitedPartStartIndexW(Text, FirstPart, Delimiters);
  EndIndex := GetDelimitedPartStartIndexW(Text, LastPart, Delimiters);
  EndIndex := EndIndex + GetDelimitedPartLengthW(Text, EndIndex, Delimiters);
  Result := Copy(Text, StartIndex, EndIndex - StartIndex);
end;

function ExtractNextDelimitedPartW(var Text: WideString; Delimiter: WideChar): WideString;
var
  StartIndex, i, TextLength: Integer;
begin
  StartIndex := GetCharDelimitedPartStartIndexW(Text, 1, Delimiter);
  if StartIndex < 0 then
  begin
    Result := Text;
    Text := '';
    Exit;
  end;
  if StartIndex >= 3 then
    Result := Copy(Text, 1, StartIndex - 2)
  else
    Result := '';
  TextLength := Length(Text);
  for i := StartIndex to TextLength do
    Text[i - (StartIndex - 1)] := Text[i];
  SetLength(Text, TextLength - (StartIndex - 1));
end;

function ExtractLineCommentW(const Text: WideString): WideString;
var
  Position, i: Integer;
begin
  Position := Pos('//', Text);
  if Position < 1 then
  begin
    Result := '';
    Exit
  end;
  i := Position - 1;
  while i >= 1 do
  begin
    if (Text[i] <> ' ') and (Text[i] <> #9) and (Text[i] <> #13) and (Text[i] <> #10) then
      Break;
    Dec(i);
  end;
  Result := Copy(Text, i + 1, Length(Text) - i);
end;

function RemoveLineCommentW(const Text: WideString): WideString;
var
  Position: Integer;
begin
  Position := Pos('//', Text);
  if Position < 1 then
  begin
    Result := Text;
    Exit
  end;
  if Position = 1 then
  begin
    Result := '';
    Exit
  end;
  Result := SysUtils.TrimRight(Copy(Text, 1, Position - 1));
end;

function IsIntegerTextW(const Text: WideString): Boolean;
var
  TextLength, i: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then
  begin
    Result := False;
    Exit
  end;
  for i := 1 to TextLength do
    if ((Text[i] < '0') or (Text[i] > '9')) and (Text[i] <> '-') then
    begin
      Result := False;
      Exit
    end;
  Result := True;
end;

function ExtractDigitsToIntW(const Text: WideString): Integer;
var
  TextLength, i: Integer;
begin
  Result := 0;
  TextLength := Length(Text);
  for i := 1 to TextLength do
    if (Integer(Text[i]) >= Ord('0')) and (Integer(Text[i]) <= Ord('9')) then
      Result := SysUtils.StrToInt(Text[i]) + Result * 10;
end;

function ExtractSignedDigitsToIntW(const Text: WideString): Integer;
var
  TextLength, i: Integer;
  Negative: Boolean;
begin
  Result := 0;
  TextLength := Length(Text);
  Negative := False;
  for i := 1 to TextLength do
    if (Integer(Text[i]) >= Ord('0')) and (Integer(Text[i]) <= Ord('9')) then
      Result := SysUtils.StrToInt(Text[i]) + Result * 10
    else if (Integer(Text[i]) = Ord('-')) and (Result = 0) then
      Negative := True;
  if Negative then
    Result := -Result;
end;

function ExtractDecimalToSingleW(const Text: WideString): Single;
var
  i, TextLength: Integer;
  Value, Divisor: Single;
  Code: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then
  begin
    Result := 0;
    Exit
  end;
  Value := 0;
  for i := 0 to TextLength - 1 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
      Value := Value * 10 + (Code - Ord('0'))
    else if (Code = Ord('.')) or (Code = Ord(',')) then
      Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
    begin
      Value := (Code - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to TextLength - 1 do
    if Integer(PWideChar(Pointer(Text))[i]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;

function ParseDecimalToSingleW(const Text: WideString): Single;
var
  i, TextLength: Integer;
  Value, Divisor: Single;
  Code: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then
  begin
    Result := 0;
    Exit
  end;
  Value := 0;
  for i := 0 to TextLength - 1 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
      Value := Value * 10 + (Code - Ord('0'))
    else if (Code = Ord('.')) or (Code = Ord(',')) then
      Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
    begin
      Value := (Code - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to TextLength - 1 do
    if Integer(PWideChar(Pointer(Text))[i]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;

function FloatToWideString(Value: Double): WideString;
var
  SavedSeparator: AnsiChar;
begin
  SavedSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  Result := SysUtils.FloatToStr(Value);
  DecimalSeparator := SavedSeparator;
end;

function ReplaceAllWideString(const Text, Search, Replacement: WideString): WideString;
var
  TextLength, SearchLength, i, j: Integer;
begin
  Result := '';
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if (TextLength < SearchLength) or (TextLength < 1) or (SearchLength < 1) then
  begin
    Result := Text;
    Exit
  end;
  i := 0;
  while i <= TextLength - SearchLength do
  begin
    j := 0;
    while j < SearchLength do
    begin
      if PWideChar(Pointer(Text))[i + j] <> PWideChar(Pointer(Search))[j] then
        Break;
      Inc(j);
    end;
    if j >= SearchLength then
    begin
      Result := Result + Replacement;
      Inc(i, SearchLength);
    end
    else
    begin
      Result := Result + PWideChar(Pointer(Text))[i];
      Inc(i);
    end;
  end;
  if i < TextLength then
    Result := Result + Copy(Text, i + 1, TextLength - i);
end;

function CardinalToHexWideString(Value: Cardinal): WideString;
begin
  Result := '';
  while Value <> 0 do
  begin
    Result := HexDigits[Value - (Value div 16) * 16] + Result;
    Value := Value div 16;
  end;
  if Result = '' then
    Result := '0';
end;

function IntToFixedWidthWideString(Value, Width: Integer): WideString;
var
  Digit, i, TextLength: Integer;
begin
  Result := '';
  while Value > 0 do
  begin
    Digit := Value;
    Value := Value div 10;
    Digit := Digit - Value * 10;
    Result := Chr(Digit + Ord('0')) + Result;
  end;
  TextLength := Length(Result);
  if TextLength < Width then
    for i := 0 to Width - TextLength - 1 do
      Result := '0' + Result
  else
    Result := Copy(Result, 0, Width);
end;

// CHANGE: PERFORMANCE - Write UTF-16 digits directly instead of allocating and
// converting one ANSI character for every digit. Preserve the legacy Abs edge case.
function IntToWideString(Value: Integer): WideString;
var
  Magnitude, Index: Integer;
  Digits: array[0..11] of WideChar;
begin
  Magnitude := Abs(Value);
  Index := High(Digits);
  if Magnitude <= 0 then
  begin
    Digits[Index] := '0';
    Dec(Index);
  end;
  while Magnitude > 0 do
  begin
    Digits[Index] := WideChar(Magnitude mod 10 + Ord('0'));
    Dec(Index);
    Magnitude := Magnitude div 10;
  end;
  if Value < 0 then
  begin
    Digits[Index] := '-';
    Dec(Index);
  end;
  SetString(Result, PWideChar(@Digits[Index + 1]), High(Digits) - Index);
end;

function BoolToWideString(Value: Boolean): WideString;
begin
  if not Value then
    Result := 'False'
  else
    Result := 'True';
end;

function TrimWideString(const Text: WideString): WideString;
var
  Code, TextLength, FirstIndex, LastIndex: Integer;
begin
  TextLength := Length(Text);
  FirstIndex := 0;
  while FirstIndex < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[FirstIndex]);
    if (Code <> Ord(' ')) and (Code <> 9) and (Code <> 13) and (Code <> 10) and (Code <> 0) then
      Break;
    Inc(FirstIndex);
  end;
  if FirstIndex >= TextLength then
  begin
    Result := '';
    Exit
  end;
  LastIndex := TextLength - 1;
  while LastIndex >= 0 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[LastIndex]);
    if (Code <> Ord(' ')) and (Code <> 9) and (Code <> 13) and (Code <> 10) and (Code <> 0) then
      Break;
    Dec(LastIndex);
  end;
  if LastIndex < FirstIndex then
  begin
    Result := '';
    Exit
  end;
  SetLength(Result, LastIndex - FirstIndex + 1);
  CopyMemory(
      PWideChar(Result),
      AddPointerOffset(PWideChar(Text), FirstIndex * 2),
      (LastIndex - FirstIndex + 1) * 2
  );
end;

function UpperCaseWideString(const Text: WideString): WideString;
var
  TextLength, PairCount, i, j: Integer;
begin
  Result := Text;
  // FPC/macOS shares WideString storage; pointer writes bypass copy-on-write.
  UniqueString(Result);
  TextLength := Length(Result);
  PairCount := High(WideCaseTable) + 1;
  for i := 0 to TextLength - 1 do
    for j := 0 to PairCount - 1 do
      if PWideChar(Pointer(Result))[i] = WideCaseTable[j].LowerChar then
      begin
        PWideChar(Pointer(Result))[i] := WideCaseTable[j].UpperChar;
        Break;
      end;
end;

function LowerCaseWideString(const Text: WideString): WideString;
var
  TextLength, PairCount, i, j: Integer;
begin
  Result := Text;
  // Tag searches must not lowercase the original quest text or its aliases.
  UniqueString(Result);
  TextLength := Length(Result);
  PairCount := High(WideCaseTable) + 1;
  for i := 0 to TextLength - 1 do
    for j := 0 to PairCount - 1 do
      if PWideChar(Pointer(Result))[i] = WideCaseTable[j].UpperChar then
      begin
        PWideChar(Pointer(Result))[i] := WideCaseTable[j].LowerChar;
        Break;
      end;
end;

function RemoveWideStringChars(const Text: WideString; Chars: WideString): WideString;
var
  TextLength, CharsLength, i, j, Count: Integer;
  Changed, Found: Boolean;
  Current: WideChar;
begin
  Changed := False;
  Result := Text;
  TextLength := Length(Result);
  CharsLength := Length(Chars);
  Count := 0;
  for i := 1 to TextLength do
  begin
    Current := Result[i];
    Found := False;
    for j := 1 to CharsLength do
      if Chars[j] = Current then
      begin
        Found := True;
        Break
      end;
    if Found then
      Changed := True
    else
    begin
      Inc(Count);
      if Changed then
        Result[Count] := Current;
    end;
  end;
  if Changed then
    if Count > 0 then
      Result := CopyWideStringUnchecked(Result, 1, Count)
    else
      Result := '';
end;

function GetTextTagLengthW(Text: PWideChar; CharCount: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  if CharCount < 2 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] = '<' then
  begin
    Result := 1;
    Exit
  end;
  i := 1;
  while i < CharCount do
  begin
    if Text[i] = '>' then
      Break;
    Inc(i);
  end;
  if i < CharCount then
    Result := i + 1;
end;

function MatchTextTagPrefixW(
    Text: PWideChar;
    CharCount: Integer;
    const Pattern, AlternatePattern: WideString
): Boolean;
var
  i, PatternLength: Integer;
begin
  Result := False;
  PatternLength := Length(Pattern);
  if Length(AlternatePattern) <> PatternLength then
    Exit;
  if PatternLength + 1 > CharCount then
    Exit;
  if Text[0] <> '<' then
    Exit;
  for i := 0 to PatternLength - 1 do
    if (Text[1 + i] <> Pattern[1 + i]) and (Text[1 + i] <> AlternatePattern[1 + i]) then
      Exit;
  Result := True;
end;

function RemoveTextTagsW(const Text: WideString): WideString;
var
  i, TagLength: Integer;
begin
  Result := '';
  i := 0;
  while i < Length(Text) do
  begin
    TagLength := GetTextTagLengthW(PWideChar(Text) + i, Length(Text) - i);
    if TagLength > 0 then
      Inc(i, TagLength)
    else
    begin
      Result := Result + Text[Succ(i)];
      Inc(i);
    end;
  end;
end;

function RemoveMatchingTextTagsW(
    Text: WideString;
    const Pattern, AlternatePattern: WideString
): WideString;
var
  i, TagLength: Integer;
begin
  Result := '';
  i := 0;
  while i < Length(Text) do
  begin
    TagLength := GetTextTagLengthW(PWideChar(Text) + i, Length(Text) - i);
    if TagLength > 0 then
    begin
      if MatchTextTagPrefixW(PWideChar(Text) + i, Length(Text) - i, Pattern, AlternatePattern) then
        Inc(i, TagLength)
      else
      begin
        Result := Result + Copy(Text, i + 1, TagLength);
        Inc(i, TagLength);
      end;
    end
    else
    begin
      Result := Result + PWideChar(Pointer(Text))[i];
      Inc(i);
    end;
  end;
end;

function CompareWideChars(Left, Right: PWideChar): Integer; cdecl;
begin
  if Left = nil then
  begin
    if Right = nil then
      Result := 0
    else
      Result := -1;
    Exit
  end;
  if Right = nil then
  begin
    Result := 1;
    Exit
  end;
  while (Left^ <> #0) and (Left^ = Right^) do
  begin
    Inc(Left);
    Inc(Right)
  end;
  Result := Ord(Left^) - Ord(Right^);
end;

function FindTextOffsetW(const Text, Search: WideString; StartIndex: Integer): Integer;
var
  TextLength, SearchLength: Integer;
  TextPtr, SearchPtr: PWideChar;
begin
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if TextLength - StartIndex < SearchLength then
  begin
    Result := -1;
    Exit
  end;
  if (TextLength < 1) and (SearchLength < 1) then
  begin
    Result := -1;
    Exit
  end;
  TextPtr := PWideChar(Text);
  SearchPtr := PWideChar(Search);
  if SearchLength = 1 then
  begin
    while StartIndex <= TextLength - SearchLength do
    begin
      if PWideChar(StartIndex * 2 + PtrUInt(TextPtr))^ = SearchPtr^ then
      begin
        Result := StartIndex;
        Exit
      end;
      Inc(StartIndex);
    end;
  end
  else
    while StartIndex <= TextLength - SearchLength do
    begin
      if SysUtils
          .CompareMem(Pointer(StartIndex * 2 + PtrUInt(TextPtr)), SearchPtr, SearchLength * 2) then
      begin
        Result := StartIndex;
        Exit
      end;
      Inc(StartIndex);
    end;
  Result := -1;
end;

function FindTextPosW(const Search, Text: WideString): Integer;
begin
  Result := FindTextOffsetW(Text, Search) + 1;
end;

function ExtractFileNameNoExtW(const Path: WideString): WideString;
var
  Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  Result := ExtractDelimitedPartW(Path, Count - 1, '\/');
  Count := CountDelimitedPartsW(Result, '.');
  if Count > 1 then
    Result := ExtractDelimitedRangeW(Result, 0, Count - 2, '.');
end;

function ExtractFileExtNoDotW(const Path: WideString): WideString;
var
  Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  Result := ExtractDelimitedPartW(Path, Count - 1, '\/');
  Count := CountDelimitedPartsW(Result, '.');
  if Count > 1 then
    Result := ExtractDelimitedPartW(Result, Count - 1, '.')
  else
    Result := '';
end;

function ExtractFileDirW(const Path: WideString): WideString;
var
  Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  if Count <= 1 then
  begin
    Result := '';
    Exit
  end;
  Result := ExtractDelimitedRangeW(Path, 0, Count - 2, '\/');
end;

procedure WriteRegistryStringLegacy(RootKey: Cardinal; KeyPath, ValueName, Value: WideString);
begin
  raise Exception.Create('Windows registry writes are unavailable in the native host')
end;

function DecodeLegacySaveLabel(Text: WideString): WideString;
var
  i, TextLength: Integer;
begin
  TextLength := Length(Text);
  Result := '';
  i := 0;
  while i < TextLength do
  begin
    Result := Result + PWideChar(Pointer(Text))[i];
    Inc(i, 2);
  end;
end;

// CHANGE: CLEANUP - Retain legacy label padding without consuming gameplay randomness.
function EncodeLegacySaveLabel(Text: WideString): WideString;
var
  I: Integer;
begin
  SetLength(Result, Length(Text) * 2);
  for I := 1 to Length(Text) do
  begin
    Result[I * 2 - 1] := Text[I];
    Result[I * 2] := ' ';
  end;
end;

function TransliterateCyrillicToLatin(Text: WideString): WideString;
begin
  Result := Text;
  Result := ReplaceAllWideString(Result, 'А', 'A');
  Result := ReplaceAllWideString(Result, 'а', 'a');
  Result := ReplaceAllWideString(Result, 'Б', 'B');
  Result := ReplaceAllWideString(Result, 'б', 'b');
  Result := ReplaceAllWideString(Result, 'В', 'V');
  Result := ReplaceAllWideString(Result, 'в', 'v');
  Result := ReplaceAllWideString(Result, 'Г', 'G');
  Result := ReplaceAllWideString(Result, 'г', 'g');
  Result := ReplaceAllWideString(Result, 'Д', 'D');
  Result := ReplaceAllWideString(Result, 'д', 'd');
  Result := ReplaceAllWideString(Result, 'Е', 'E');
  Result := ReplaceAllWideString(Result, 'е', 'e');
  Result := ReplaceAllWideString(Result, 'Ё', 'Yo');
  Result := ReplaceAllWideString(Result, 'ё', 'yo');
  Result := ReplaceAllWideString(Result, 'Ж', 'Zh');
  Result := ReplaceAllWideString(Result, 'ж', 'zh');
  Result := ReplaceAllWideString(Result, 'З', 'Z');
  Result := ReplaceAllWideString(Result, 'з', 'z');
  Result := ReplaceAllWideString(Result, 'И', 'I');
  Result := ReplaceAllWideString(Result, 'и', 'i');
  Result := ReplaceAllWideString(Result, 'Й', 'J');
  Result := ReplaceAllWideString(Result, 'й', 'j');
  Result := ReplaceAllWideString(Result, 'К', 'K');
  Result := ReplaceAllWideString(Result, 'к', 'k');
  Result := ReplaceAllWideString(Result, 'Л', 'L');
  Result := ReplaceAllWideString(Result, 'л', 'l');
  Result := ReplaceAllWideString(Result, 'М', 'M');
  Result := ReplaceAllWideString(Result, 'м', 'm');
  Result := ReplaceAllWideString(Result, 'Н', 'N');
  Result := ReplaceAllWideString(Result, 'н', 'n');
  Result := ReplaceAllWideString(Result, 'О', 'O');
  Result := ReplaceAllWideString(Result, 'о', 'o');
  Result := ReplaceAllWideString(Result, 'П', 'P');
  Result := ReplaceAllWideString(Result, 'п', 'p');
  Result := ReplaceAllWideString(Result, 'Р', 'R');
  Result := ReplaceAllWideString(Result, 'р', 'r');
  Result := ReplaceAllWideString(Result, 'С', 'S');
  Result := ReplaceAllWideString(Result, 'с', 's');
  Result := ReplaceAllWideString(Result, 'Т', 'T');
  Result := ReplaceAllWideString(Result, 'т', 't');
  Result := ReplaceAllWideString(Result, 'У', 'U');
  Result := ReplaceAllWideString(Result, 'у', 'u');
  Result := ReplaceAllWideString(Result, 'Ф', 'F');
  Result := ReplaceAllWideString(Result, 'ф', 'f');
  Result := ReplaceAllWideString(Result, 'Х', 'Kh');
  Result := ReplaceAllWideString(Result, 'х', 'kh');
  Result := ReplaceAllWideString(Result, 'Ц', 'Ts');
  Result := ReplaceAllWideString(Result, 'ц', 'ts');
  Result := ReplaceAllWideString(Result, 'Ч', 'Ch');
  Result := ReplaceAllWideString(Result, 'ч', 'ch');
  Result := ReplaceAllWideString(Result, 'Ш', 'Sh');
  Result := ReplaceAllWideString(Result, 'ш', 'sh');
  Result := ReplaceAllWideString(Result, 'Щ', 'Shh');
  Result := ReplaceAllWideString(Result, 'щ', 'shh');
  Result := ReplaceAllWideString(Result, 'Ъ', '"');
  Result := ReplaceAllWideString(Result, 'ъ', '"');
  Result := ReplaceAllWideString(Result, 'Ы', 'Y');
  Result := ReplaceAllWideString(Result, 'ы', 'y');
  Result := ReplaceAllWideString(Result, 'Ь', '`');
  Result := ReplaceAllWideString(Result, 'ь', '`');
  Result := ReplaceAllWideString(Result, 'Э', 'E');
  Result := ReplaceAllWideString(Result, 'э', 'e');
  Result := ReplaceAllWideString(Result, 'Ю', 'Yu');
  Result := ReplaceAllWideString(Result, 'ю', 'yu');
  Result := ReplaceAllWideString(Result, 'Я', 'Ya');
  Result := ReplaceAllWideString(Result, 'я', 'ya');
end;

function CopyWideStringUnchecked(Text: WideString; Index, Count: Integer): WideString;
begin
  SetLength(Result, Count);
  CopyMemory(PWideChar(Result), AddPointerOffset(PWideChar(Text), Index * 2 - 2), Count * 2);
end;

end.
