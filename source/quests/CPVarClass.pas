{$EXCESSPRECISION OFF}
unit CPVarClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  CPDiapClass,
  EC_Struct;
type
  TCPVariant = class;
  {$Z1}
  TCPValueKind = (cpvkRange = 0, cpvkFloat = 1, cpvkInteger = 2);
  TCPVariant = class(TObjectEx)
    Range: TCPDiapazone;
    FloatValue: Extended;
    Gap12: array[0..1] of Byte;
    IntValue: Integer;
    ValueKind: TCPValueKind;
    Gap19: array[0..2] of Byte;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure Assign(Source: TCPVariant; FreeSource: Boolean);
    function TryLoadFromText(Text: WideString): Boolean;
    function HasNumericChars(var Text: WideString; TextLength: Integer): Boolean;
    function HasIntegerChars(var Text: WideString; TextLength: Integer): Boolean;
    function AsExtended: Extended;
    function AsInteger: Integer;
  end;
implementation
uses
  Math,
  EC_Str;

constructor TCPVariant.Create;
begin
  inherited Create;
  Range := TCPDiapazone.Create;
  Reset;
end;

destructor TCPVariant.Destroy;
begin
  Reset;
  Range.Free;
  Range := nil;
  inherited Destroy;
end;

procedure TCPVariant.Reset;
begin
  FloatValue := 0;
  IntValue := 0;
  Range.Clear;
  ValueKind := cpvkInteger;
end;

procedure TCPVariant.Assign(Source: TCPVariant; FreeSource: Boolean);
begin
  Range.Assign(Source.Range);
  FloatValue := Source.FloatValue;
  IntValue := Source.IntValue;
  ValueKind := Source.ValueKind;
  if FreeSource then
    Source.Free;
end;

function TCPVariant.TryLoadFromText(Text: WideString): Boolean;
var
  i, Count: Integer;
begin
  Result := False;
  Count := Length(Text);
  if Count = 0 then
    Text := '0';
  if HasNumericChars(Text, Count) then
  begin
    if HasIntegerChars(Text, Count) then
    begin
      ValueKind := cpvkInteger;
      Range.Clear;
      IntValue := ExtractDigitsToIntW(Text);
      FloatValue := 0;
      Result := True;
    end
    else
    begin
      ValueKind := cpvkFloat;
      Range.Clear;
      FloatValue := ExtractDecimalToSingleW(Text);
      IntValue := 0;
      Result := True;
    end;
  end
  else if (Count > 1) and (Text[1] = '[') and (Text[Count] = ']') then
  begin
    for i := 1 to Count do
      case Text[i] of
        '0'..'9', '[', ']', 'h', ';', '-':;
      else
        Exit;
      end;
    ValueKind := cpvkRange;
    Range.LoadFromText(Text);
    FloatValue := 0;
    IntValue := 0;
    Result := True;
  end;
end;

function TCPVariant.HasNumericChars(var Text: WideString; TextLength: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to TextLength do
    if ((Text[i] < '0') or (Text[i] > '9')) and (Text[i] <> ',') and (Text[i] <> 'E') then
      Exit;
  Result := True;
end;

function TCPVariant.HasIntegerChars(var Text: WideString; TextLength: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to TextLength do
    if ((Text[i] < '0') or (Text[i] > '9')) and (Text[i] <> 'E') then
      Exit;
  Result := True;
end;

function TCPVariant.AsExtended: Extended;
begin
  Result := 0;
  if ValueKind = cpvkRange then
    Result := Range.GetRandomValue
  else if ValueKind = cpvkFloat then
    Result := FloatValue
  else if ValueKind = cpvkInteger then
    Result := IntValue;
end;

function TCPVariant.AsInteger: Integer;
begin
  Result := 0;
  if ValueKind = cpvkRange then
    Result := Range.GetRandomValue
  else if ValueKind = cpvkFloat then
  begin
    if FloatValue < -2000000000 then
      Result := -2000000000
    else if FloatValue > 2000000000 then
      Result := 2000000000
    else
      Result := System.Round(FloatValue + 1E-11);
  end
  else if ValueKind = cpvkInteger then
    Result := IntValue;
end;

end.
