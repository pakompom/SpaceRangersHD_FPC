{$EXCESSPRECISION OFF}
unit ParameterClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  CPDiapClass,
  EC_Buf,
  EC_Struct,
  EventClass,
  ParViewStringClass,
  TextFieldClass,
  TextQuestInterface;
type
  TParameter = class;
  TParameter = class(TObjectEx)
    MinValue: Integer;
    MaxValue: Integer;
    Value: Integer;
    NameText: TTextField;
    CriticalEvent: TEvent;
    CriticalEventOverride: TEvent;
    CriticalOutcome: TQuestOutcome;
    Hidden: Boolean;
    ShowWhenZero: Boolean;
    CriticalAtMinimum: Boolean;
    Enabled: Boolean;
    IsMoney: Boolean;
    Gap25: array[0..2] of Byte;
    ValueText: TTextField;
    ViewStrings: array of TParViewString;
    ViewStringCount: Integer;
    ViewStringCapacity: Integer;
    InitialRange: TCPDiapazone;
    constructor Create(Index: Integer);
    destructor Destroy; override;
    procedure Reset(Index: Integer);
    procedure EnsureViewStringCapacity(RequiredCapacity: Integer; ParameterIndex: Integer);
    function GetValueText(Value: Integer): WideString;
    function GetNonCriticalMinimum: Integer;
    function GetNonCriticalMaximum: Integer;
    procedure SetValue(NewValue: Integer);
    procedure LoadFromReader(Reader: TBufEC);
    procedure LoadLegacyV4FromReader(Reader: TBufEC);
    procedure LoadLegacyV3FromReader(Reader: TBufEC);
    procedure LoadLegacyV2FromReader(Reader: TBufEC);
    procedure LoadLegacyV1FromReader(Reader: TBufEC);
    procedure LoadLegacyV0FromReader(Reader: TBufEC);
  end;
implementation
uses
  Math,
  EC_Str,
  ValueListClass,
  MessageText;

constructor TParameter.Create(Index: Integer);
begin
  inherited Create;
  ViewStringCount := 0;
  ViewStringCapacity := 0;
  SetLength(ViewStrings, 0);
  NameText := TTextField.Create;
  ValueText := TTextField.Create;
  CriticalEvent := TEvent.Create;
  CriticalEventOverride := nil;
  InitialRange := TCPDiapazone.Create;
  Reset(Index);
end;

destructor TParameter.Destroy;
var
  i: Integer;
begin
  for i := 1 to ViewStringCapacity do
  begin
    ViewStrings[i].Free;
    ViewStrings[i] := nil;
  end;
  SetLength(ViewStrings, 0);
  NameText.Free;
  NameText := nil;
  ValueText.Free;
  ValueText := nil;
  CriticalEvent.Free;
  CriticalEvent := nil;
  InitialRange.Free;
  InitialRange := nil;
  inherited Destroy;
end;

procedure TParameter.Reset(Index: Integer);
begin
  IsMoney := False;
  Enabled := False;
  Hidden := False;
  ShowWhenZero := True;
  CriticalAtMinimum := True;
  MinValue := 0;
  MaxValue := 1;
  InitialRange.Clear;
  ViewStringCount := 1;
  EnsureViewStringCapacity(1, Index);
  ViewStrings[1].MinValue := MinValue;
  ViewStrings[1].MaxValue := MaxValue;
  Value := 0;
  CriticalOutcome := qoNone;
  NameText.Text :=
      QuestMessages.GetTextOrKey('ParameterDefaultName') + ' ' + IntToWideString(Index);
  ValueText.Text :=
      QuestMessages.GetTextOrKey('ParameterDefaultName') + ' ' + IntToWideString(Index) + ': <>';
  ViewStrings[1].Text.Text := ValueText.Text;
  CriticalEvent.ClearTextFields;
  CriticalEventOverride := nil;
  CriticalEvent.Text.Text :=
      QuestMessages.GetTextOrKey('ParameterDefaultCriticalMessage') + ' ' + IntToWideString(Index);
end;

procedure TParameter.EnsureViewStringCapacity(RequiredCapacity: Integer; ParameterIndex: Integer);
begin
  while RequiredCapacity > ViewStringCapacity do
  begin
    Inc(ViewStringCapacity);
    SetLength(ViewStrings, ViewStringCapacity + 1);
    ViewStrings[ViewStringCapacity] :=
        TParViewString.Create(
            QuestMessages.GetTextOrKey('ParameterDefaultName')
                + ' '
                + IntToWideString(ParameterIndex)
                + ': <>'
        );
  end;
end;

function TParameter.GetValueText(Value: Integer): WideString;
var
  i: Integer;
begin
  for i := 1 to ViewStringCount do
    if (ViewStrings[i].MinValue <= Value) and (ViewStrings[i].MaxValue >= Value) then
    begin
      Result := TrimWideString(ViewStrings[i].Text.Text);
      Exit;
    end;
  if ViewStrings[ViewStringCount].MaxValue < Value then
    Result := ViewStrings[ViewStringCount].Text.Text
  else
    Result := ViewStrings[1].Text.Text;
end;

function TParameter.GetNonCriticalMinimum: Integer;
begin
  Result := MinValue;
  if (CriticalOutcome <> qoNone) and (CriticalOutcome <> qoSuccess) and CriticalAtMinimum then
    Inc(Result);
end;

function TParameter.GetNonCriticalMaximum: Integer;
begin
  Result := MaxValue;
  if (CriticalOutcome <> qoNone) and (CriticalOutcome <> qoSuccess) and not CriticalAtMinimum then
    Dec(Result);
end;

procedure TParameter.SetValue(NewValue: Integer);
begin
  if IsMoney then
  begin
    if NewValue < 0 then
      Value := 0
    else
      Value := NewValue;
  end
  else
  begin
    if NewValue > MaxValue then
      Value := MaxValue
    else if NewValue < MinValue then
      Value := MinValue
    else
      Value := NewValue;
  end;
end;

procedure TParameter.LoadFromReader(Reader: TBufEC);
var
  i: Integer;
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := False;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  for i := 1 to ViewStringCount do
    TParViewString(ViewStrings[i]).LoadFromReader(Reader);
  if ViewStringCount <= 0 then
  begin
    ViewStringCount := 1;
    EnsureViewStringCapacity(1, 0);
    ViewStrings[1].MinValue := MinValue;
    ViewStrings[1].MaxValue := MaxValue;
  end;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  CriticalEvent.Picture.LoadTextLinesFromReader(Reader);
  CriticalEvent.Sound.LoadTextLinesFromReader(Reader);
  CriticalEvent.Music.LoadTextLinesFromReader(Reader);
  InitialRange.LoadFromReader(Reader);
end;

procedure TParameter.LoadLegacyV4FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  for i := 1 to ViewStringCount do
    TParViewString(ViewStrings[i]).LoadFromReader(Reader);
  if ViewStringCount <= 0 then
  begin
    ViewStringCount := 1;
    EnsureViewStringCapacity(1, 0);
    ViewStrings[1].MinValue := MinValue;
    ViewStrings[1].MaxValue := MaxValue;
  end;
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  InitialRange.LoadFromReader(Reader);
end;

procedure TParameter.LoadLegacyV3FromReader(Reader: TBufEC);
var
  i: Integer;
  Values: TValuesList;
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  for i := 1 to ViewStringCount do
    TParViewString(ViewStrings[i]).LoadFromReader(Reader);
  if ViewStringCount <= 0 then
  begin
    ViewStringCount := 1;
    EnsureViewStringCapacity(1, 0);
    ViewStrings[1].MinValue := MinValue;
    ViewStrings[1].MaxValue := MaxValue;
  end;
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  Values := TValuesList.Create;
  Values.LoadFromReader(Reader);
  InitialRange.LoadFromValues(Values);
  Values.Clear;
  Values.Free;
end;

procedure TParameter.LoadLegacyV2FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  for i := 1 to ViewStringCount do
    TParViewString(ViewStrings[i]).LoadFromReader(Reader);
  if ViewStringCount <= 0 then
  begin
    ViewStringCount := 1;
    EnsureViewStringCapacity(1, 0);
    ViewStrings[1].MinValue := MinValue;
    ViewStrings[1].MaxValue := MaxValue;
  end;
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;

procedure TParameter.LoadLegacyV1FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := False;
  NameText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  for i := 1 to ViewStringCount do
    TParViewString(ViewStrings[i]).LoadFromReader(Reader);
  if ViewStringCount <= 0 then
  begin
    ViewStringCount := 1;
    EnsureViewStringCapacity(1, 0);
    ViewStrings[1].MinValue := MinValue;
    ViewStrings[1].MaxValue := MaxValue;
  end;
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;

procedure TParameter.LoadLegacyV0FromReader(Reader: TBufEC);
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := 1;
  IsMoney := False;
  NameText.LoadTextLinesFromReader(Reader);
  ValueText.LoadTextLinesFromReader(Reader);
  EnsureViewStringCapacity(ViewStringCount, 0);
  ViewStrings[1].MaxValue := MaxValue;
  ViewStrings[1].MinValue := MinValue;
  ViewStrings[1].Text.Text := TrimWideString(ValueText.Text);
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;

end.
