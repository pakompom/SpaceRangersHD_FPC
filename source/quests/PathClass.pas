{$EXCESSPRECISION OFF}
unit PathClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Struct,
  EventClass,
  ParameterDeltaClass,
  SequenceClass,
  TextFieldClass;
type
  TPath = class;
  TPath = class(TObjectEx)
    ParameterChanges: TList;
    Priority: Double;
    IsAutomatic: Boolean;
    UnknownFlag: Byte;
    AlwaysShow: Boolean;
    Available: Boolean;
    Days: Integer;
    DisplayOrder: Integer;
    Id: Integer;
    TraversalLimit: Integer;
    TraversalCount: Integer;
    FromLocationId: Integer;
    ToLocationId: Integer;
    Caption: TTextField;
    Event: TEvent;
    ConditionExpression: TTextField;
    Gap3C: array[0..167] of Byte;
    Sequence: TSequence;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function GetParameterChangeCount: Integer;
    function GetParameterChange(Index: Integer): TParameterDelta;
    procedure AddParameterChange(Change: TParameterDelta);
    procedure ApplyParameterChanges(var Parameters: TList);
    procedure PruneParameterChanges(Parameters: TList);
    function CheckAvailable(Parameters: TList): Boolean;
    function FindParameterChange(ParameterIndex: Integer): TParameterDelta;
    procedure LoadFromReader(Reader: TBufEC; Parameters: TList);
    procedure LoadLegacyV9FromReader(Reader: TBufEC);
    procedure LoadLegacyV8FromReader(Reader: TBufEC);
    procedure LoadLegacyV7FromReader(Reader: TBufEC);
    procedure LoadLegacyV6FromReader(Reader: TBufEC);
    procedure LoadLegacyV5FromReader(Reader: TBufEC);
    procedure LoadLegacyV4FromReader(Reader: TBufEC);
    procedure LoadLegacyV3FromReader(Reader: TBufEC);
    procedure LoadLegacyV2FromReader(Reader: TBufEC);
    procedure LoadLegacyV1FromReader(Reader: TBufEC);
    procedure LoadLegacyV0FromReader(Reader: TBufEC);
  end;
implementation
uses
  Math,
  CalcParseClass,
  EC_Str,
  ParameterClass;

constructor TPath.Create;
begin
  inherited Create;
  Caption := TTextField.Create;
  Event := TEvent.Create;
  ConditionExpression := TTextField.Create;
  ParameterChanges := TList.Create;
  Sequence := nil;
  Reset;
  Id := 0;
  ToLocationId := 0;
  FromLocationId := 0;
end;

destructor TPath.Destroy;
begin
  if Sequence <> nil then
    Sequence.Free;
  Caption.Free;
  Caption := nil;
  Event.Free;
  Event := nil;
  ConditionExpression.Free;
  ConditionExpression := nil;
  // Native destruction frees the list without resetting its owned entries.
  ParameterChanges.Free;
  ParameterChanges := nil;
  inherited Destroy;
end;

procedure TPath.Reset;
var
  i: Integer;
begin
  Days := 0;
  DisplayOrder := 5;
  Priority := 1;
  TraversalLimit := 0;
  TraversalCount := 0;
  Id := 0;
  FromLocationId := 0;
  ToLocationId := 0;
  Caption.Text := '';
  Event.Text.Text := '';
  Event.Picture.Text := '';
  Event.Sound.Text := '';
  Event.Music.Text := '';
  ConditionExpression.Text := '';
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).Free;
  ParameterChanges.Clear;
  IsAutomatic := True;
  UnknownFlag := 0;
  AlwaysShow := False;
end;

function TPath.GetParameterChangeCount: Integer;
begin
  Result := ParameterChanges.Count;
end;

function TPath.GetParameterChange(Index: Integer): TParameterDelta;
begin
  Result := TParameterDelta(ParameterChanges[Index - 1]);
end;

procedure TPath.AddParameterChange(Change: TParameterDelta);
begin
  ParameterChanges.Add(Change);
end;

procedure TPath.ApplyParameterChanges(var Parameters: TList);
var
  i: Integer;
begin
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).EvaluateChangeExpression(Parameters);
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).ApplyChange(Parameters);
end;

procedure TPath.PruneParameterChanges(Parameters: TList);
var
  i: Integer;
begin
  for i := GetParameterChangeCount downto 1 do
    if (GetParameterChange(i).ParameterIndex < 1)
        or (GetParameterChange(i).ParameterIndex > Parameters.Count) then
      ParameterChanges.Delete(i - 1)
    else if GetParameterChange(i).HasNoChange(Parameters) then
      if GetParameterChange(i).HasNoValueConstraint(Parameters) then
        ParameterChanges.Delete(i - 1);
end;

function TPath.CheckAvailable(Parameters: TList): Boolean;
var
  Calc: TCalcParse;
  i: Integer;
begin
  Available := False;
  Result := False;
  if TrimWideString(ConditionExpression.Text) <> '' then
  begin
    Calc := TCalcParse.Create;
    Calc.Reset;
    Calc.Prepare(TrimWideString(ConditionExpression.Text), 0);
    // Native cleanup occurs only after a successfully prepared expression.
    if not Calc.HasError and not Calc.UsesDefaultParameter then
    begin
      Calc.Evaluate(Parameters);
      if not Calc.HasError and (Calc.ResultValue = 0) then
      begin
        Calc.Destroy;
        Exit;
      end
      else
        Calc.Destroy;
    end;
  end;
  for i := 1 to GetParameterChangeCount do
    if not GetParameterChange(i).AcceptsParameter(Parameters) then
      Exit;
  Available := True;
  Result := True;
end;

function TPath.FindParameterChange(ParameterIndex: Integer): TParameterDelta;
var
  i: Integer;
begin
  for i := 1 to GetParameterChangeCount do
    if GetParameterChange(i).ParameterIndex = ParameterIndex then
    begin
      Result := GetParameterChange(i);
      Exit;
    end;
  Result := nil;
end;

procedure TPath.LoadFromReader(Reader: TBufEC; Parameters: TList);
var
  i, ParameterIndex, Count: Integer;
  Change: TParameterDelta;
  Parameter: TParameter;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  Count := Reader.GetInt32;
  for i := 1 to Count do
  begin
    ParameterIndex := Reader.GetInt32;
    Change := FindParameterChange(ParameterIndex);
    if Change = nil then
    begin
      Change := TParameterDelta.Create;
      Change.ParameterIndex := ParameterIndex;
      Parameter := TParameter(Parameters[ParameterIndex - 1]);
      Change.MinValue := Parameter.MinValue;
      Change.MaxValue := Parameter.MaxValue;
      AddParameterChange(Change);
    end;
    Change.LoadValueConstraintsFromReader(Reader);
  end;
  Count := Reader.GetInt32;
  for i := 1 to Count do
  begin
    ParameterIndex := Reader.GetInt32;
    Change := FindParameterChange(ParameterIndex);
    if Change = nil then
    begin
      Change := TParameterDelta.Create;
      Change.ParameterIndex := ParameterIndex;
      Parameter := TParameter(Parameters[ParameterIndex - 1]);
      Change.MinValue := Parameter.MinValue;
      Change.MaxValue := Parameter.MaxValue;
      AddParameterChange(Change);
    end;
    Change.LoadChangeFromReader(Reader);
  end;
  ConditionExpression.LoadTextLinesFromReader(Reader);
  Caption.LoadTextLinesFromReader(Reader);
  Event.Text.LoadTextLinesFromReader(Reader);
  Event.Picture.LoadTextLinesFromReader(Reader);
  Event.Sound.LoadTextLinesFromReader(Reader);
  Event.Music.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV9FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  for i := 1 to 96 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  ConditionExpression.LoadTextLinesFromReader(Reader);
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV8FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  for i := 1 to 48 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  ConditionExpression.LoadTextLinesFromReader(Reader);
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV7FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  for i := 1 to 24 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  ConditionExpression.LoadTextLinesFromReader(Reader);
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV6FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for i := 1 to 24 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  ConditionExpression.LoadTextLinesFromReader(Reader);
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV5FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV2FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV4FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  Days := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV1FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV3FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV2FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for i := 1 to 9 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV1FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  for i := 1 to 9 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

procedure TPath.LoadLegacyV0FromReader(Reader: TBufEC);
var
  i: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  for i := 1 to 9 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  Caption.LoadTextLinesFromReader(Reader);
  Event.ClearTextFields;
  Event.Text.LoadTextLinesFromReader(Reader);
  IsAutomatic := TrimWideString(Caption.Text) = '';
end;

end.
