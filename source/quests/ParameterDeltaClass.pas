{$EXCESSPRECISION OFF}
unit ParameterDeltaClass;
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
  TextFieldClass,
  ValueListClass;
type
  TParameterDelta = class;
  {$Z4}
  TParameterVisibilityChange = (pvcUnchanged = 0, pvcShow = 1, pvcHide = 2);
  TParameterDelta = class(TObjectEx)
    ParameterIndex: Integer;
    ValueConstraint: TValuesList;
    MultipleConstraint: TValuesList;
    MinValue: Integer;
    MaxValue: Integer;
    ChangeValue: Integer;
    ChangeByPercent: Boolean;
    SetValue: Boolean;
    UseExpression: Boolean;
    Gap1F: array[0..0] of Byte;
    ExpressionText: TTextField;
    CriticalEvent: TEvent;
    VisibilityChange: TParameterVisibilityChange;
    LegacyFlag: Boolean;
    Gap2D: array[0..2] of Byte;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure ClearValueConstraints;
    procedure ClearChange;
    function HasNoValueConstraint(Parameters: TList): Boolean;
    function HasNoChange(Parameters: TList): Boolean;
    procedure EvaluateChangeExpression(var Parameters: TList);
    procedure ApplyChange(var Parameters: TList);
    function AcceptsParameter(Parameters: TList): Boolean;
    procedure LoadLegacyV0FromReader(Reader: TBufEC);
    procedure LoadLegacyV1FromReader(Reader: TBufEC);
    procedure LoadLegacyV2FromReader(Reader: TBufEC);
    procedure LoadLegacyV3FromReader(Reader: TBufEC);
    procedure LoadValueConstraintsFromReader(Reader: TBufEC);
    procedure LoadChangeFromReader(Reader: TBufEC);
  end;
implementation
uses
  Math,
  CalcParseClass,
  EC_Str,
  ParameterClass,
  TextQuestInterface;

constructor TParameterDelta.Create;
begin
  inherited Create;
  CriticalEvent := TEvent.Create;
  ValueConstraint := TValuesList.Create;
  MultipleConstraint := TValuesList.Create;
  ExpressionText := TTextField.Create;
  Reset;
end;

destructor TParameterDelta.Destroy;
begin
  Reset;
  CriticalEvent.Free;
  CriticalEvent := nil;
  ValueConstraint.Free;
  ValueConstraint := nil;
  MultipleConstraint.Free;
  MultipleConstraint := nil;
  ExpressionText.Free;
  ExpressionText := nil;
  inherited Destroy;
end;

procedure TParameterDelta.Reset;
begin
  ParameterIndex := 0;
  ClearValueConstraints;
  ClearChange;
end;

procedure TParameterDelta.ClearValueConstraints;
begin
  MinValue := 0;
  MaxValue := 1;
  ValueConstraint.Clear;
  MultipleConstraint.Clear;
end;

procedure TParameterDelta.ClearChange;
begin
  ChangeValue := 0;
  VisibilityChange := pvcUnchanged;
  CriticalEvent.ClearTextFields;
  LegacyFlag := False;
  ChangeByPercent := False;
  SetValue := False;
  UseExpression := False;
  ExpressionText.Text := '';
end;

function TParameterDelta.HasNoValueConstraint(Parameters: TList): Boolean;
var
  Parameter: TParameter;
begin
  Result := True;
  if (ParameterIndex <= 0) or (Parameters.Count < ParameterIndex) then
    Exit;
  Parameter := TParameter(Parameters[ParameterIndex - 1]);
  Result := False;
  if (Parameter.GetNonCriticalMinimum >= MinValue)
      and (Parameter.GetNonCriticalMaximum <= MaxValue)
      and (ValueConstraint.Count <= 0)
      and (MultipleConstraint.Count <= 0) then
    Result := True;
end;

function TParameterDelta.HasNoChange(Parameters: TList): Boolean;
// The native branches share one assignment before managed-string cleanup.
begin
  if (ParameterIndex <= 0) or (Parameters.Count < ParameterIndex) then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
  if VisibilityChange <> pvcUnchanged then
    Exit;
  if UseExpression then
  begin
    if TrimWideString(ExpressionText.Text) <> '' then
      Exit;
  end
  else if not (not SetValue and (ChangeValue = 0)) then
    Exit;
  Result := True;
end;

procedure TParameterDelta.EvaluateChangeExpression(var Parameters: TList);
var
  Text: WideString;
  Calc: TCalcParse;
  Parameter: TParameter;
begin
  if (ParameterIndex > 0) and (Parameters.Count >= ParameterIndex) then
  begin
    Parameter := TParameter(Parameters[ParameterIndex - 1]);
    if Parameter.Enabled and UseExpression then
    begin
      ChangeValue := Parameter.Value;
      Text := TrimWideString(ExpressionText.Text);
      if Text <> '' then
      begin
        Calc := TCalcParse.Create;
        Calc.Expression := Calc.NormalizeTokens(Text);
        Calc.Evaluate(Parameters);
        if not Calc.HasError then
          ChangeValue := Calc.ResultValue;
        Calc.Destroy;
      end;
    end;
  end;
end;

procedure TParameterDelta.ApplyChange(var Parameters: TList);
var
  Parameter: TParameter;
  NewValue: Integer;
begin
  if (ParameterIndex > 0) and (Parameters.Count >= ParameterIndex) then
  begin
    Parameter := TParameter(Parameters[ParameterIndex - 1]);
    if Parameter.Enabled then
    begin
      if UseExpression then
        NewValue := ChangeValue
      else if SetValue then
        NewValue := ChangeValue
      else if ChangeByPercent then
        NewValue := System.Round(Parameter.Value * 0.01 * ChangeValue) + Parameter.Value
      else
        NewValue := Parameter.Value + ChangeValue;
      Parameter.SetValue(NewValue);
      if Parameter.CriticalOutcome <> qoNone then
      begin
        if TrimWideString(CriticalEvent.Text.Text) <> '' then
          Parameter.CriticalEventOverride := CriticalEvent
        else
          Parameter.CriticalEventOverride := nil;
      end;
      if VisibilityChange = pvcShow then
        Parameter.Hidden := False
      else if VisibilityChange = pvcHide then
        Parameter.Hidden := True;
    end;
  end;
end;

function TParameterDelta.AcceptsParameter(Parameters: TList): Boolean;
var
  Parameter: TParameter;
begin
  Result := True;
  if (ParameterIndex <= 0) or (Parameters.Count < ParameterIndex) then
    Exit;
  Parameter := TParameter(Parameters[ParameterIndex - 1]);
  if Parameter.Enabled then
  begin
    Result := False;
    if (Parameter.GetNonCriticalMaximum > MaxValue) and (Parameter.Value > MaxValue) then
      Exit;
    if (Parameter.GetNonCriticalMinimum < MinValue) and (Parameter.Value < MinValue) then
      Exit;
    if not ValueConstraint.AcceptsValue(Parameter.Value) then
      Exit;
    if not MultipleConstraint.AcceptsMultiple(Parameter.Value) then
      Exit;
    Result := True;
  end;
end;

procedure TParameterDelta.LoadLegacyV0FromReader(Reader: TBufEC);
begin
  Reset;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
end;

procedure TParameterDelta.LoadLegacyV1FromReader(Reader: TBufEC);
begin
  Reset;
  Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
end;

procedure TParameterDelta.LoadLegacyV2FromReader(Reader: TBufEC);
begin
  Reset;
  Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  SetValue := Reader.GetBoolean;
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
end;

procedure TParameterDelta.LoadLegacyV3FromReader(Reader: TBufEC);
begin
  Reset;
  Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  SetValue := Reader.GetBoolean;
  UseExpression := Reader.GetBoolean;
  ExpressionText.LoadTextLinesFromReader(Reader);
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalEvent.ClearTextFields;
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
end;

procedure TParameterDelta.LoadValueConstraintsFromReader(Reader: TBufEC);
begin
  ClearValueConstraints;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
end;

procedure TParameterDelta.LoadChangeFromReader(Reader: TBufEC);
var
  ChangeKind: Byte;
begin
  ClearChange;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetByte);
  ChangeKind := Reader.GetByte;
  SetValue := (ChangeKind = 0);
  ChangeByPercent := (ChangeKind = 2);
  UseExpression := (ChangeKind = 3);
  ExpressionText.LoadTextLinesFromReader(Reader);
  CriticalEvent.Text.LoadTextLinesFromReader(Reader);
  CriticalEvent.Picture.LoadTextLinesFromReader(Reader);
  CriticalEvent.Sound.LoadTextLinesFromReader(Reader);
  CriticalEvent.Music.LoadTextLinesFromReader(Reader);
end;

end.
