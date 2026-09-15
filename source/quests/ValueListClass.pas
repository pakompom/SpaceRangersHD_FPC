{$EXCESSPRECISION OFF}
unit ValueListClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct;
type
  TValuesList = class;
  TValuesList = class(TObjectEx)
    AcceptListed: Boolean;
    Gap5: array[0..2] of Byte;
    Values: array of Integer;
    Count: Integer;
    function NormalizeSemicolonText(Text: WideString): WideString;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromReader(Reader: TBufEC);
    procedure Clear;
    procedure LoadFromSemicolonText(Text: WideString);
    function AcceptsValue(Value: Integer): Boolean;
    function AcceptsMultiple(Value: Integer): Boolean;
  end;
implementation
uses
  Math,
  EC_Str;

function TValuesList.NormalizeSemicolonText(Text: WideString): WideString;
var
  i: Integer;
  Normalized: WideString;
begin
  Normalized := '';
  for i := 1 to Length(Text) do
    if ((Text[i] >= '0') and (Text[i] <= '9'))
        or (Text[i] = ';')
        or (Text[i] = ',')
        or (Text[i] = '-') then
      Normalized := Normalized + Text[i];
  Result := Normalized;
  // The native routine discards the character-filtered string here.
  Normalized := '(' + Text + ')';
  repeat
    Result := Normalized;
    Normalized := ReplaceAllWideString(Normalized, ',', ';');
    Normalized := ReplaceAllWideString(Normalized, ';;', ';');
    Normalized := ReplaceAllWideString(Normalized, '-;', ';');
    Normalized := ReplaceAllWideString(Normalized, '--', '');
    Normalized := ReplaceAllWideString(Normalized, '(-;', '(');
    Normalized := ReplaceAllWideString(Normalized, '(-)', '(');
    Normalized := ReplaceAllWideString(Normalized, '(;', '(');
    Normalized := ReplaceAllWideString(Normalized, ';-)', ')');
    Normalized := ReplaceAllWideString(Normalized, ';)', ')');
  until Result = Normalized;
  Result := ReplaceAllWideString(Result, '(', '');
  Result := ReplaceAllWideString(Result, ')', '');
end;

constructor TValuesList.Create;
begin
  inherited Create;
  Clear;
end;

destructor TValuesList.Destroy;
begin
  Values := nil;
  inherited Destroy;
end;

procedure TValuesList.LoadFromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Count := Reader.GetInt32;
  AcceptListed := Reader.GetBoolean;
  SetLength(Values, Count + 2);
  for i := 1 to Count do
    Values[i] := Reader.GetInt32;
end;

procedure TValuesList.Clear;
begin
  SetLength(Values, 1);
  Count := 0;
  AcceptListed := True;
end;

procedure TValuesList.LoadFromSemicolonText(Text: WideString);
var
  i: Integer;
  NumberText: WideString;
begin
  Clear;
  i := 1;
  Count := 0;
  NumberText := '';
  Text := TrimWideString(NormalizeSemicolonText(Text));
  if Length(Text) <> 0 then
  begin
    while i <= Length(Text) do
    begin
      if (i = Length(Text)) or (Text[i + 1] = ';') then
        Inc(Count);
      Inc(i);
    end;
    SetLength(Values, Count + 2);
    Count := 0;
    // Native parsing starts at zero, including Text[0].
    i := 0;
    while i <= Length(Text) do
    begin
      if Text[i] <> ';' then
        NumberText := NumberText + Text[i];
      if (i = Length(Text)) or (Text[i + 1] = ';') then
      begin
        Inc(Count);
        Values[Count] := ExtractSignedDigitsToIntW(NumberText);
        NumberText := '';
      end;
      Inc(i);
    end;
  end;
end;

function TValuesList.AcceptsValue(Value: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  if Count <> 0 then
  begin
    Result := AcceptListed;
    for i := 1 to Count do
      if Values[i] = Value then
        Exit;
    Result := not Result;
  end;
end;

function TValuesList.AcceptsMultiple(Value: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  if Count <> 0 then
  begin
    Result := AcceptListed;
    for i := 1 to Count do
      if Value mod Values[i] = 0 then
        Exit;
    Result := not Result;
  end;
end;

end.
