{$EXCESSPRECISION OFF}
unit LocationClass;
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
  TLocation = class;
  TLocation = class(TObjectEx)
    ParameterChanges: TList;
    EditorX: Integer;
    EditorY: Integer;
    Days: Integer;
    Id: Integer;
    EventCount: Integer;
    Events: array of TEvent;
    UseEventExpression: Boolean;
    Gap21: array[0..2] of Byte;
    NextEventIndex: Integer;
    EventExpression: TTextField;
    IsDeath: Boolean;
    IsEmpty: Boolean;
    IsStart: Boolean;
    IsSuccess: Boolean;
    IsFailure: Boolean;
    Gap31: array[0..2] of Byte;
    VisitLimit: Integer;
    VisitCount: Integer;
    Sequence: TSequence;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function GetParameterChangeCount: Integer;
    function GetParameterChange(Index: Integer): TParameterDelta;
    procedure AddParameterChange(Change: TParameterDelta);
    procedure ApplyParameterChanges(var Parameters: TList);
    procedure PruneParameterChanges(Parameters: TList);
    function FindParameterChange(ParameterIndex: Integer): TParameterDelta;
    procedure AddEvent;
    procedure RemoveLastEvent;
    procedure LoadFromReader(Reader: TBufEC);
    procedure LoadLegacyV8FromReader(Reader: TBufEC);
    procedure LoadLegacyV7FromReader(Reader: TBufEC);
    procedure LoadLegacyV6FromReader(Reader: TBufEC);
    procedure LoadLegacyV5FromReader(Reader: TBufEC);
    procedure LoadLegacyV4FromReader(Reader: TBufEC);
    procedure LoadLegacyV3FromReader(Reader: TBufEC);
    procedure LoadLegacyV2FromReader(Reader: TBufEC);
    procedure LoadLegacyV1FromReader(Reader: TBufEC);
    procedure LoadLegacyV0FromReader(Reader: TBufEC);
    function SelectEvent(var Parameters: TList): TEvent;
  end;
implementation
uses
  CalcParseClass,
  EC_Str,
  Math;

constructor TLocation.Create;
begin
  inherited Create;
  EventCount := 1;
  SetLength(Events, 2);
  Events[1] := TEvent.Create;
  Sequence := nil;
  EventExpression := TTextField.Create;
  ParameterChanges := TList.Create;
  Reset;
end;

destructor TLocation.Destroy;
var
  i: Integer;
begin
  Reset;
  // Reset retains only the first event; the native loop indexes that slot.
  for i := 1 to EventCount do
  begin
    Events[1].Free;
    Events[1] := nil;
  end;
  Events := nil;
  EventExpression.Free;
  EventExpression := nil;
  ParameterChanges.Free;
  ParameterChanges := nil;
  inherited Destroy;
end;

procedure TLocation.Reset;
var
  i: Integer;
begin
  EditorX := 100;
  EditorY := 100;
  Days := 0;
  VisitLimit := 0;
  VisitCount := 0;
  if Sequence <> nil then
    Sequence.Free;
  Sequence := nil;
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).Free;
  ParameterChanges.Clear;
  for i := 2 to EventCount do
    Events[i].Free;
  SetLength(Events, 2);
  EventCount := 1;
  Events[1].ClearTextFields;
  UseEventExpression := False;
  NextEventIndex := 1;
  EventExpression.ClearText;
  Id := 0;
  IsStart := False;
  IsSuccess := False;
  IsFailure := False;
  IsDeath := False;
  IsEmpty := False;
end;

function TLocation.GetParameterChangeCount: Integer;
begin
  Result := ParameterChanges.Count;
end;

function TLocation.GetParameterChange(Index: Integer): TParameterDelta;
begin
  Result := TParameterDelta(ParameterChanges[Index - 1]);
end;

procedure TLocation.AddParameterChange(Change: TParameterDelta);
begin
  ParameterChanges.Add(Change);
end;

procedure TLocation.ApplyParameterChanges(var Parameters: TList);
var
  i: Integer;
begin
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).EvaluateChangeExpression(Parameters);
  for i := 1 to GetParameterChangeCount do
    GetParameterChange(i).ApplyChange(Parameters);
end;

procedure TLocation.PruneParameterChanges(Parameters: TList);
var
  i: Integer;
begin
  for i := GetParameterChangeCount downto 1 do
    if (GetParameterChange(i).ParameterIndex < 1)
        or (GetParameterChange(i).ParameterIndex > Parameters.Count) then
      ParameterChanges.Delete(i - 1)
    else if GetParameterChange(i).HasNoChange(Parameters) then
      ParameterChanges.Delete(i - 1);
end;

function TLocation.FindParameterChange(ParameterIndex: Integer): TParameterDelta;
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

procedure TLocation.AddEvent;
var
  Text: WideString;
  Different: Boolean;
  i: Integer;
begin
  Inc(EventCount);
  SetLength(Events, EventCount + 1);
  Events[EventCount] := TEvent.Create;
  if EventCount <> 1 then
  begin
    Text := TrimWideString(Events[1].Picture.Text);
    Different := False;
    for i := 2 to EventCount - 1 do
      if TrimWideString(Events[i].Picture.Text) <> Text then
      begin
        Different := True;
        Break;
      end;
    if not Different then
      Events[EventCount].Picture.Text := Text;
    Text := TrimWideString(Events[1].Sound.Text);
    Different := False;
    for i := 2 to EventCount - 1 do
      if TrimWideString(Events[i].Sound.Text) <> Text then
      begin
        Different := True;
        Break;
      end;
    if not Different then
      Events[EventCount].Sound.Text := Text;
    Text := TrimWideString(Events[1].Music.Text);
    Different := False;
    for i := 2 to EventCount - 1 do
      if TrimWideString(Events[i].Music.Text) <> Text then
      begin
        Different := True;
        Break;
      end;
    if not Different then
      Events[EventCount].Music.Text := Text;
  end;
end;

procedure TLocation.RemoveLastEvent;
begin
  if EventCount >= 2 then
  begin
    Events[EventCount].Free;
    Dec(EventCount);
    SetLength(Events, EventCount + 1);
  end;
end;

procedure TLocation.LoadFromReader(Reader: TBufEC);
var
  i, ParameterIndex, Count: Integer;
  Change: TParameterDelta;
  LocationType: Byte;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := Reader.GetInt32;
  LocationType := Reader.GetByte;
  IsStart := LocationType = 1;
  IsEmpty := LocationType = 2;
  IsSuccess := LocationType = 3;
  IsFailure := (LocationType = 4) or (LocationType = 5);
  IsDeath := LocationType = 5;
  Count := Reader.GetInt32;
  for i := 1 to Count do
  begin
    ParameterIndex := Reader.GetInt32;
    Change := FindParameterChange(ParameterIndex);
    if Change = nil then
    begin
      Change := TParameterDelta.Create;
      Change.ParameterIndex := ParameterIndex;
      AddParameterChange(Change);
    end;
    Change.LoadChangeFromReader(Reader);
  end;
  Count := Reader.GetInt32;
  while Count > EventCount do
    AddEvent;
  while (Count < EventCount) and (EventCount > 1) do
    RemoveLastEvent;
  for i := 1 to Count do
  begin
    Events[i].Text.LoadTextLinesFromReader(Reader);
    Events[i].Picture.LoadTextLinesFromReader(Reader);
    Events[i].Sound.LoadTextLinesFromReader(Reader);
    Events[i].Music.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  EventExpression.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV8FromReader(Reader: TBufEC);
var
  i, ParameterIndex, Count: Integer;
  Change: TParameterDelta;
  LocationType: Byte;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  LocationType := Reader.GetByte;
  IsStart := LocationType = 1;
  IsEmpty := LocationType = 2;
  IsSuccess := LocationType = 3;
  IsFailure := (LocationType = 4) or (LocationType = 5);
  IsDeath := LocationType = 5;
  Count := Reader.GetInt32;
  for i := 1 to Count do
  begin
    ParameterIndex := Reader.GetInt32;
    Change := FindParameterChange(ParameterIndex);
    if Change = nil then
    begin
      Change := TParameterDelta.Create;
      Change.ParameterIndex := ParameterIndex;
      AddParameterChange(Change);
    end;
    Change.LoadChangeFromReader(Reader);
  end;
  Count := Reader.GetInt32;
  while Count > EventCount do
    AddEvent;
  while (Count < EventCount) and (EventCount > 1) do
    RemoveLastEvent;
  for i := 1 to Count do
  begin
    Events[i].Text.LoadTextLinesFromReader(Reader);
    Events[i].Picture.LoadTextLinesFromReader(Reader);
    Events[i].Sound.LoadTextLinesFromReader(Reader);
    Events[i].Music.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  EventExpression.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV7FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for i := 1 to 96 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
  EventExpression.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV6FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for i := 1 to 48 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
  EventExpression.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV5FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for i := 1 to 24 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
  EventExpression.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV4FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for i := 1 to 24 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV3FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
end;

procedure TLocation.LoadLegacyV3FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV2FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
end;

procedure TLocation.LoadLegacyV2FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV1FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount < 10 do
    AddEvent;
  while EventCount > 10 do
    RemoveLastEvent;
  for i := 1 to 10 do
  begin
    Events[i].ClearTextFields;
    Events[i].Text.LoadTextLinesFromReader(Reader);
  end;
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.ClearText;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
end;

procedure TLocation.LoadLegacyV1FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for i := 1 to 12 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount > 1 do
    RemoveLastEvent;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
  Events[1].ClearTextFields;
  Events[1].Text.LoadTextLinesFromReader(Reader);
end;

procedure TLocation.LoadLegacyV0FromReader(Reader: TBufEC);
var
  i: Integer;
  DiscardedText: TTextField;
begin
  Reset;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  VisitLimit := 0;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for i := 1 to 9 do
  begin
    AddParameterChange(TParameterDelta.Create);
    GetParameterChange(GetParameterChangeCount).LoadLegacyV0FromReader(Reader);
    GetParameterChange(GetParameterChangeCount).ParameterIndex := i;
  end;
  while EventCount > 1 do
    RemoveLastEvent;
  DiscardedText := TTextField.Create;
  DiscardedText.LoadTextLinesFromReader(Reader);
  DiscardedText.Free;
  Events[1].ClearTextFields;
  Events[1].Text.LoadTextLinesFromReader(Reader);
end;

function TLocation.SelectEvent(var Parameters: TList): TEvent;
var
  i, j, Attempts: Integer;
  Found: Boolean;
  Text: WideString;
  Calc: TCalcParse;
  Valid: Boolean;
begin
  Result := nil;
  Found := False;
  if UseEventExpression then
  begin
    Valid := True;
    Calc := TCalcParse.Create;
    if TrimWideString(EventExpression.Text) <> '' then
    begin
      Calc.Prepare(EventExpression.Text, 1);
      if Calc.HasError or Calc.UsesDefaultParameter then
        Valid := False;
    end
    else
      Valid := False;
    if Valid then
    begin
      Calc.Evaluate(Parameters);
      if Calc.EvaluationError then
        Valid := False;
    end;
    if Valid then
    begin
      if (Calc.ResultValue <= EventCount) and (Calc.ResultValue >= 1) then
        Result := Events[Calc.ResultValue];
    end
    else
    begin
      Attempts := 0;
      while not Found do
      begin
        i := System.Random(EventCount) + 1;
        Text := TrimWideString(Events[i].Text.Text);
        if Text <> '' then
        begin
          Found := True;
          Result := Events[i];
        end
        else if Attempts > Max(20, EventCount * 2) then
        begin
          j := i + 1;
          while j <= i + EventCount do
          begin
            Text := TrimWideString(Events[1 + j mod EventCount].Text.Text);
            if Text <> '' then
              Break;
            Inc(j);
          end;
          Found := True;
          Result := Events[1 + j mod EventCount];
        end
        else
          Inc(Attempts);
      end;
    end;
    Calc.Destroy;
  end
  else
  begin
    i := NextEventIndex;
    Attempts := 0;
    while not Found do
    begin
      Text := TrimWideString(Events[i].Text.Text);
      if (Text <> '') or (Attempts > EventCount) then
      begin
        Found := True;
        Result := Events[i];
        NextEventIndex := i + 1;
        if NextEventIndex > EventCount then
          NextEventIndex := 1;
      end
      else
        Inc(Attempts);
      Inc(i);
      if i > EventCount then
        i := 1;
    end;
  end;
end;

end.
