{$EXCESSPRECISION OFF}
unit CPDiapClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  ValueListClass;
type
  TCPDiapazone = class;
  TCPDiapazone = class(TObjectEx)
    RangeStarts: array of Int64;
    RangeEnds: array of Int64;
    RangeCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromReader(Reader: TBufEC);
    function GetMinimum: Int64;
    function GetMaximum: Int64;
    function GetRandomValue: Integer;
    function Contains(Value: Extended): Boolean;
    function ToText: WideString;
    procedure LoadFromValues(var Source: TValuesList);
    procedure Assign(var Source: TCPDiapazone);
    procedure Append(var Source: TCPDiapazone);
    procedure AddRange(MinValue: Int64; MaxValue: Int64);
    procedure AddValue(Value: Extended);
    procedure LoadFromText(Text: WideString);
  end;
implementation
uses
  Math,
  EC_Str,
  SysUtils,
  TextFieldClass;

constructor TCPDiapazone.Create;
begin
  inherited Create;
  Clear;
end;

destructor TCPDiapazone.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TCPDiapazone.Clear;
begin
  RangeCount := 0;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
end;

procedure TCPDiapazone.LoadFromReader(Reader: TBufEC);
var
  Text: TTextField;
begin
  Text := TTextField.Create;
  Text.LoadTextLinesFromReader(Reader);
  LoadFromText(Text.Text);
  Text.Destroy;
end;

function TCPDiapazone.GetMinimum: Int64;
var
  i: Integer;
begin
  Result := RangeStarts[0];
  for i := 0 to RangeCount - 1 do
    if RangeStarts[i] <= Result then
      Result := RangeStarts[i];
end;

function TCPDiapazone.GetMaximum: Int64;
var
  i: Integer;
begin
  Result := RangeEnds[0];
  for i := 0 to RangeCount - 1 do
    if RangeEnds[i] >= Result then
      Result := RangeEnds[i];
end;

function TCPDiapazone.GetRandomValue: Integer;
var
  i, RandomValue: Integer;
  Ends, Starts: array of Int64;
begin
  Result := 0;
  if RangeCount > 0 then
  begin
    SetLength(Ends, RangeCount);
    SetLength(Starts, RangeCount);
    RandomValue := 0;
    for i := 0 to RangeCount - 1 do
    begin
      Starts[i] := RandomValue;
      Ends[i] := RangeEnds[i] - RangeStarts[i] + Starts[i];
      RandomValue := RandomValue + RangeEnds[i] - RangeStarts[i] + 1;
    end;
    RandomValue := System.Random(RandomValue);
    // Native scan includes RangeCount and draws again within the selected range.
    for i := 0 to RangeCount do
      if (RandomValue >= Starts[i]) and (RandomValue <= Ends[i]) then
      begin
        Result := System.Random(RangeEnds[i] - RangeStarts[i] + 1) + RangeStarts[i];
        Break;
      end;
  end;
end;

function TCPDiapazone.Contains(Value: Extended): Boolean;
var
  i: Integer;
  Rounded: Int64;
begin
  Rounded := System.Round(Value);
  Result := True;
  for i := 0 to RangeCount - 1 do
    if (RangeStarts[i] <= Rounded) and (RangeEnds[i] >= Rounded) then
      Exit;
  Result := False;
end;

function TCPDiapazone.ToText: WideString;
var
  i: Integer;
begin
  Result := '[';
  for i := 0 to RangeCount - 1 do
  begin
    if RangeStarts[i] = RangeEnds[i] then
      Result := Result + IntToWideString(RangeStarts[i])
    else
      Result := Result + IntToWideString(RangeStarts[i]) + 'h' + IntToWideString(RangeEnds[i]);
    if i < RangeCount - 1 then
      Result := Result + ';'
    else
      Result := Result + ']';
  end;
end;

procedure TCPDiapazone.LoadFromValues(var Source: TValuesList);
var
  i: Integer;
begin
  RangeCount := Source.Count;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  for i := 0 to RangeCount - 1 do
  begin
    RangeStarts[i] := Source.Values[i + 1];
    RangeEnds[i] := Source.Values[i + 1];
  end;
end;

procedure TCPDiapazone.Assign(var Source: TCPDiapazone);
var
  i: Integer;
begin
  RangeCount := Source.RangeCount;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  for i := 0 to RangeCount - 1 do
  begin
    RangeStarts[i] := Source.RangeStarts[i];
    RangeEnds[i] := Source.RangeEnds[i];
  end;
end;

procedure TCPDiapazone.Append(var Source: TCPDiapazone);
var
  i: Integer;
begin
  if Source.RangeCount > 0 then
  begin
    SetLength(RangeStarts, RangeCount + Source.RangeCount);
    SetLength(RangeEnds, RangeCount + Source.RangeCount);
    for i := 0 to Source.RangeCount - 1 do
    begin
      RangeStarts[RangeCount + i] := Source.RangeStarts[i];
      RangeEnds[RangeCount + i] := Source.RangeEnds[i];
    end;
    RangeCount := RangeCount + Source.RangeCount;
  end;
end;

procedure TCPDiapazone.AddRange(MinValue, MaxValue: Int64);
var
  Temporary: Int64;
begin
  Inc(RangeCount);
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  if MinValue > MaxValue then
  begin
    Temporary := MinValue;
    MinValue := MaxValue;
    MaxValue := Temporary;
  end;
  RangeStarts[RangeCount - 1] := MinValue;
  RangeEnds[RangeCount - 1] := MaxValue;
end;

procedure TCPDiapazone.AddValue(Value: Extended);
var
  IntegerValue: Int64;
  Failed: Boolean;
begin
  IntegerValue := 0;
  Failed := False;
  try
    IntegerValue := Trunc(Value);
  except
    on EMathError do
      Failed := True;
  end;
  if not Failed then
  begin
    Inc(RangeCount);
    SetLength(RangeStarts, RangeCount);
    SetLength(RangeEnds, RangeCount);
    RangeStarts[RangeCount - 1] := IntegerValue;
    RangeEnds[RangeCount - 1] := IntegerValue;
  end;
end;

procedure TCPDiapazone.LoadFromText(Text: WideString);
var
  i, Count: Integer;
  Value, Minimum, Maximum: Int64;
  NumberText, Normalized: WideString;
  Failed: Boolean;
begin
  Clear;
  Count := Length(Text);
  if Text <> ';' then
  begin
    // Native parsing retains the original Count after this shortening replacement.
    Normalized := ReplaceAllWideString(Text, '..', 'h');
    i := 1;
    NumberText := '';
    Minimum := 200000000;
    Maximum := -200000000;
    Failed := False;
    while i <= Count do
    begin
      if ((Normalized[i] >= '0') and (Normalized[i] <= '9')) or (Normalized[i] = '-') then
      begin
        NumberText := NumberText + Normalized[i];
        Inc(i);
      end
      else if (Normalized[i] = 'h') or (Normalized[i] = ';') or (Normalized[i] = ']') then
      begin
        Value := 0;
        try
          Value := ExtractSignedDigitsToIntW(NumberText);
        except
          on EMathError do
            Failed := True;
          on EConvertError do
            Failed := True;
        end;
        if not Failed then
        begin
          if Minimum > Value then
            Minimum := Value;
          if Maximum < Value then
            Maximum := Value;
        end;
        Failed := False;
        NumberText := '';
        if (Normalized[i] = ';') or (Normalized[i] = ']') then
        begin
          AddRange(Minimum, Maximum);
          Minimum := 200000000;
          Maximum := -200000000;
          NumberText := '';
        end;
        Inc(i);
      end
      else
        Inc(i);
    end;
  end;
end;

end.
