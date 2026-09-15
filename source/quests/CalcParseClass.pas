{$EXCESSPRECISION OFF}
unit CalcParseClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  CPVarClass,
  Classes,
  EC_Struct;
type
  TCalcParse = class;
  TCalcParse = class(TObjectEx)
    SourceText: WideString;
    Expression: WideString;
    ResultValue: Integer;
    ResetValue10: Integer;
    UsesDefaultParameter: Boolean;
    SourceWasChanged: Boolean;
    UnbalancedParentheses: Boolean;
    InvalidNumericLiteral: Boolean;
    InvalidParameterReference: Boolean;
    InvalidRangeLiteral: Boolean;
    EvaluationError: Boolean;
    HasError: Boolean;
    procedure ApplyPower(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyAdd(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplySubtract(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyMultiply(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyPercentChange(
        var Left: TCPVariant;
        var Right: TCPVariant;
        var OutValue: TCPVariant
    );
    procedure ApplyDivide(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyIntDivide(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyModulo(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyRange(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyMembership(
        var Left: TCPVariant;
        var Right: TCPVariant;
        var OutValue: TCPVariant
    );
    procedure ApplyLessThan(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyGreaterThan(
        var Left: TCPVariant;
        var Right: TCPVariant;
        var OutValue: TCPVariant
    );
    procedure ApplyLessOrEqual(
        var Left: TCPVariant;
        var Right: TCPVariant;
        var OutValue: TCPVariant
    );
    procedure ApplyGreaterOrEqual(
        var Left: TCPVariant;
        var Right: TCPVariant;
        var OutValue: TCPVariant
    );
    procedure ApplyEqual(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyNotEqual(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyAnd(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    procedure ApplyOr(var Left: TCPVariant; var Right: TCPVariant; var OutValue: TCPVariant);
    function NormalizeTokens(var Text: WideString): WideString;
    function FormatTokens(var Text: WideString): WideString;
    function GetOperatorRank(Token: WideChar): Integer;
    function CollapseOperatorRun(const Text: WideString): WideString;
    function NormalizeFragments(const Text: WideString): WideString;
    function NormalizeScalarFragment(Text: WideString): WideString;
    function NormalizeBracketFragment(Text: WideString): WideString;
    function NormalizeParameterReference(Text: WideString): WideString;
    function NormalizeRangeLiteral(Text: WideString): WideString;
    function InsertImplicitMultiplication(Text: WideString): WideString;
    function FindTopLevelOperator(const Text: WideString; TextLength: Integer): Integer;
    function EvaluateExpression(Text: WideString): TCPVariant;
    procedure Evaluate(Parameters: TList);
    procedure Prepare(Text: WideString; DefaultParameterIndex: Integer);
    constructor Create;
    procedure Reset;
    function HasBalancedParenthesesInSlice(
        const Text: WideString;
        FirstIndex: Integer;
        LastIndex: Integer
    ): Boolean;
    function SubstituteParameters(Parameters: TList): WideString;
    function HasBalancedParentheses(const Text: WideString): Boolean;
    function ClampNumericLiterals(Text: WideString): WideString;
  end;
implementation
uses
  CPDiapClass,
  EC_Str,
  Math,
  ParameterClass,
  SysUtils;

procedure TCalcParse.ApplyPower(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkFloat;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
    OutValue.FloatValue :=
        Math.Sign(Left.AsExtended) * Math.Power(Abs(Left.AsExtended), Right.AsExtended)
  else if Left.ValueKind = cpvkFloat then
    OutValue.FloatValue :=
        Math.Sign(Left.AsExtended) * Math.IntPower(Abs(Left.AsExtended), Right.AsInteger)
  else if Right.ValueKind = cpvkFloat then
  begin
    A := Left.AsInteger;
    OutValue.FloatValue := Math.Power(Abs(A), Right.AsExtended) * Math.Sign(A);
  end
  else
  begin
    OutValue.ValueKind := cpvkInteger;
    A := Left.AsInteger;
    B := Right.AsInteger;
    X := A;
    Y := B;
    if Math.Power(Abs(X), Y) > 2000000000 then
      OutValue.IntValue := Math.Sign(A) * 2000000000
    else
      OutValue.IntValue := Integer(System.Round(Math.IntPower(Abs(A), B))) * Math.Sign(A);
  end;
end;

procedure TCalcParse.ApplyAdd(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkFloat;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
    OutValue.FloatValue := Left.AsExtended + Right.AsExtended
  else if Left.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsExtended + Right.AsInteger
  else if Right.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsInteger + Right.AsExtended
  else
  begin
    OutValue.ValueKind := cpvkInteger;
    A := Left.AsInteger;
    B := Right.AsInteger;
    X := A;
    Y := B;
    if X + Y > 2000000000 then
      OutValue.IntValue := 2000000000
    else if X + Y < -2000000000 then
      OutValue.IntValue := -2000000000
    else
      OutValue.IntValue := A + B;
  end;
end;

procedure TCalcParse.ApplySubtract(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkFloat;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
    OutValue.FloatValue := Left.AsExtended - Right.AsExtended
  else if Left.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsExtended - Right.AsInteger
  else if Right.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsInteger - Right.AsExtended
  else
  begin
    OutValue.ValueKind := cpvkInteger;
    A := Left.AsInteger;
    B := Right.AsInteger;
    X := A;
    Y := B;
    if X - Y > 2000000000 then
      OutValue.IntValue := 2000000000
    else if X - Y < -2000000000 then
      OutValue.IntValue := -2000000000
    else
      OutValue.IntValue := A - B;
  end;
end;

procedure TCalcParse.ApplyMultiply(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkFloat;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
    OutValue.FloatValue := Left.AsExtended * Right.AsExtended
  else if Left.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsExtended * Right.AsInteger
  else if Right.ValueKind = cpvkFloat then
    OutValue.FloatValue := Left.AsInteger * Right.AsExtended
  else
  begin
    OutValue.ValueKind := cpvkInteger;
    A := Left.AsInteger;
    B := Right.AsInteger;
    X := A;
    Y := B;
    if X * Y > 2000000000 then
      OutValue.IntValue := 2000000000
    else if X * Y < -2000000000 then
      OutValue.IntValue := -2000000000
    else
      OutValue.IntValue := A * B;
  end;
end;

procedure TCalcParse.ApplyPercentChange(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkFloat;
  OutValue.FloatValue := Left.AsExtended * (1 + Right.AsExtended * 0.01);
end;

procedure TCalcParse.ApplyDivide(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  if (Left.ValueKind <> cpvkFloat) and (Right.ValueKind <> cpvkFloat) then
  begin
    A := Left.AsInteger;
    B := Right.AsInteger;
    if B = 0 then
    begin
      OutValue.ValueKind := cpvkInteger;
      if A < 0 then
        OutValue.IntValue := -2000000000
      else
        OutValue.IntValue := 2000000000;
    end
    else if A mod B = 0 then
    begin
      OutValue.ValueKind := cpvkInteger;
      OutValue.IntValue := A div B;
    end
    else
      try
        OutValue.ValueKind := cpvkFloat;
        OutValue.FloatValue := A / B;
      except
        on EDivByZero do
        begin
        end;
      end;
  end
  else
  begin
    X := Left.AsExtended;
    Y := Right.AsExtended;
    if Y = 0 then
    begin
      if X < 0 then
        OutValue.FloatValue := -2000000000
      else
        OutValue.FloatValue := 2000000000;
    end
    else
      try
        OutValue.ValueKind := cpvkFloat;
        OutValue.FloatValue := X / Y;
      except
        on EDivByZero do
        begin
        end;
      end;
  end;
end;

procedure TCalcParse.ApplyIntDivide(var Left, Right, OutValue: TCPVariant);
var
  A, B: Integer;
  X, Y: Extended;
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if (Left.ValueKind <> cpvkFloat) and (Right.ValueKind <> cpvkFloat) then
  begin
    A := Left.AsInteger;
    B := Right.AsInteger;
    if B = 0 then
    begin
      if A < 0 then
        OutValue.IntValue := -2000000000
      else
        OutValue.IntValue := 2000000000;
    end
    else
      OutValue.IntValue := A div B;
  end
  else
  begin
    X := Left.AsExtended;
    Y := Right.AsExtended;
    if Y = 0 then
    begin
      if X < 0 then
        OutValue.FloatValue := -2000000000
      else
        OutValue.FloatValue := 2000000000;
    end
    else
      try
        OutValue.IntValue := Trunc(X / Y);
      except
        on EDivByZero do
        begin
        end;
      end;
  end;
end;

procedure TCalcParse.ApplyModulo(var Left, Right, OutValue: TCPVariant);
var
  X, Y: Extended;
  A, B: Integer;
  Negative: Boolean;
begin
  OutValue.Reset;
  Negative := False;
  if (Left.ValueKind <> cpvkFloat) and (Right.ValueKind <> cpvkFloat) then
  begin
    A := Left.AsInteger;
    B := Right.AsInteger;
    OutValue.ValueKind := cpvkInteger;
    Negative := A < 0;
    if B = 0 then
    begin
      if Negative then
        OutValue.IntValue := -2000000000
      else
        OutValue.IntValue := 2000000000;
    end
    else
    begin
      OutValue.IntValue := Abs(A) mod Abs(B);
      if Negative then
        OutValue.IntValue := OutValue.IntValue * -1;
    end;
  end
  else
  begin
    X := Left.AsExtended;
    Y := Trunc(Right.AsExtended);
    if Y = 0 then
    begin
      if X < 0 then
        OutValue.FloatValue := -2000000000
      else
        OutValue.FloatValue := 2000000000;
    end
    else
      try
        if Y < 0 then
          Y := Y * -1;
        if X < 0 then
        begin
          X := X * -1;
          Negative := True;
        end;
        OutValue.ValueKind := cpvkFloat;
        OutValue.FloatValue := Trunc(X - Trunc(X / Y) * Y);
        if Negative then
          OutValue.FloatValue := OutValue.FloatValue * -1;
      except
        on EDivByZero do
        begin
        end;
      end;
  end;
end;

procedure TCalcParse.ApplyRange(var Left, Right, OutValue: TCPVariant);
var
  Minimum, Maximum: Int64;
begin
  OutValue.Reset;
  Maximum := 0;
  Minimum := 0;
  if Left.ValueKind = cpvkFloat then
    Minimum := System.Round(Left.FloatValue)
  else if Left.ValueKind = cpvkInteger then
    Minimum := Left.IntValue
  else if Left.ValueKind = cpvkRange then
    Minimum := TCPDiapazone(Left.Range).GetMinimum;
  if Right.ValueKind = cpvkFloat then
    Maximum := System.Round(Right.FloatValue)
  else if Right.ValueKind = cpvkInteger then
    Maximum := Right.IntValue
  else if Right.ValueKind = cpvkRange then
    Maximum := TCPDiapazone(Right.Range).GetMaximum;
  OutValue.ValueKind := cpvkRange;
  TCPDiapazone(OutValue.Range).AddRange(Minimum, Maximum);
end;

procedure TCalcParse.ApplyMembership(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if (Left.ValueKind <> cpvkRange) and (Right.ValueKind <> cpvkRange) then
  begin
    if Left.AsExtended = Right.AsExtended then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind <> cpvkRange) then
  begin
    if TCPDiapazone(Left.Range).Contains(Right.AsExtended) then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end
  else if (Left.ValueKind <> cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    if TCPDiapazone(Right.Range).Contains(Left.AsExtended) then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    if TCPDiapazone(Right.Range).Contains(Left.AsInteger) then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end;
end;

procedure TCalcParse.ApplyLessThan(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended < Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyGreaterThan(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended > Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyLessOrEqual(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended <= Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyGreaterOrEqual(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended >= Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyEqual(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended = Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyNotEqual(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  OutValue.ValueKind := cpvkInteger;
  if Left.AsExtended <> Right.AsExtended then
    OutValue.IntValue := 1
  else
    OutValue.IntValue := 0;
end;

procedure TCalcParse.ApplyAnd(var Left, Right, OutValue: TCPVariant);
begin
  OutValue.Reset;
  if (Left.ValueKind <> cpvkRange) and (Right.ValueKind > cpvkRange) then
  begin
    OutValue.ValueKind := cpvkInteger;
    if (Left.AsExtended <> 0) and (Right.AsExtended <> 0) then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Left, False);
    TCPDiapazone(OutValue.Range).Append(Right.Range);
  end
  else if (Left.ValueKind <> cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Right, False);
    if Left.ValueKind = cpvkInteger then
      TCPDiapazone(OutValue.Range).AddRange(Left.IntValue, Left.IntValue)
    else
      TCPDiapazone(OutValue.Range).AddValue(Left.FloatValue);
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind <> cpvkRange) then
  begin
    OutValue.Assign(Left, False);
    if Right.ValueKind = cpvkInteger then
      TCPDiapazone(OutValue.Range).AddRange(Right.IntValue, Right.IntValue)
    else
      TCPDiapazone(OutValue.Range).AddValue(Right.FloatValue);
  end;
end;

procedure TCalcParse.ApplyOr(var Left, Right, OutValue: TCPVariant);
begin
  if (Left.ValueKind <> cpvkRange) and (Right.ValueKind > cpvkRange) then
  begin
    OutValue.ValueKind := cpvkInteger;
    if (Left.AsExtended <> 0) or (Right.AsExtended <> 0) then
      OutValue.IntValue := 1
    else
      OutValue.IntValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Left, False);
    TCPDiapazone(OutValue.Range).Append(Right.Range);
  end
  else if (Left.ValueKind <> cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Right, False);
    if Left.ValueKind = cpvkInteger then
      TCPDiapazone(OutValue.Range).AddRange(Left.IntValue, Left.IntValue)
    else
      TCPDiapazone(OutValue.Range).AddValue(Left.FloatValue);
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind <> cpvkRange) then
  begin
    OutValue.Assign(Left, False);
    if Right.ValueKind = cpvkInteger then
      TCPDiapazone(OutValue.Range).AddRange(Right.IntValue, Right.IntValue)
    else
      TCPDiapazone(OutValue.Range).AddValue(Right.FloatValue);
  end;
end;

function TCalcParse.NormalizeTokens(var Text: WideString): WideString;
var
  Previous, Current: WideString;
  Index: Integer;
begin
  Current := WideString(SysUtils.LowerCase(AnsiString(TrimWideString(Text))));
  repeat
    Previous := Current;
    Current := ReplaceAllWideString(Current, 'pct', '%');
    Current := ReplaceAllWideString(Current, 'div', 'f');
    Current := ReplaceAllWideString(Current, 'mod', 'g');
    Current := ReplaceAllWideString(Current, 'in', '#');
    Current := ReplaceAllWideString(Current, 'to', '$');
    Current := ReplaceAllWideString(Current, 'or', '|');
    Current := ReplaceAllWideString(Current, 'and', '&');
    Current := ReplaceAllWideString(Current, '<>', 'e');
    Current := ReplaceAllWideString(Current, '>=', 'c');
    Current := ReplaceAllWideString(Current, '<=', 'b');
    Current := ReplaceAllWideString(Current, '..', 'h');
    Current := ReplaceAllWideString(Current, '.', ',');
    Current := ReplaceAllWideString(Current, '  ', ' ');
    Current := ReplaceAllWideString(Current, 'd', '');
    Current := ReplaceAllWideString(Current, 'm', '');
    Current := ReplaceAllWideString(Current, 'o', '');
    Current := ReplaceAllWideString(Current, 't', '');
    Current := ReplaceAllWideString(Current, 'i', '');
    Current := ReplaceAllWideString(Current, 'a', '');
    Current := ReplaceAllWideString(Current, 'n', '');
  until Current = Previous;
  repeat
    Previous := Current;
    Index := FindTextOffsetW(Current, ' ');
    while Index > 0 do
    begin
      if (FindTextOffsetW('%fg#$|&ecbh*+/-()><=[]{}', WideString(Current[Index])) < 0)
          and (FindTextOffsetW('%fg#$|&ecbh*+/-()><=[]{}', WideString(Current[Index + 2])) < 0) then
        Index := FindTextOffsetW(Current, ' ', Index + 1)
      else
      begin
        Current :=
            CopyWideStringUnchecked(Current, 1, Index)
                + CopyWideStringUnchecked(Current, Index + 2, Length(Current) - Index - 1);
        Index := FindTextOffsetW(Current, ' ', Index);
      end;
    end;
  until Current = Previous;
  Result := '(' + Previous + ')';
end;

function TCalcParse.FormatTokens(var Text: WideString): WideString;
var
  Previous, Current, Inner: WideString;
  Count, i: Integer;
begin
  Current := WideString(SysUtils.LowerCase(AnsiString(Text)));
  Current := ReplaceAllWideString(Current, '$', ' to ');
  Current := ReplaceAllWideString(Current, '#', ' in ');
  Current := ReplaceAllWideString(Current, '|', ' or ');
  Current := ReplaceAllWideString(Current, '&', ' and ');
  Current := ReplaceAllWideString(Current, 'e', '<>');
  Current := ReplaceAllWideString(Current, 'c', '>=');
  Current := ReplaceAllWideString(Current, 'b', '<=');
  Current := ReplaceAllWideString(Current, 'f', ' div ');
  Current := ReplaceAllWideString(Current, 'g', ' mod ');
  Current := ReplaceAllWideString(Current, 'h', '..');
  Current := ReplaceAllWideString(Current, '%', ' pct ');
  repeat
    Previous := Current;
    Current := ReplaceAllWideString(Current, '  ', ' ');
    Current := ReplaceAllWideString(Current, '(0-', '(-');
  until Current = Previous;
  Count := Length(Current);
  Inner := '';
  if (Count >= 2) and (Current[1] = '(') and (Current[Count] = ')') then
  begin
    for i := 2 to Count - 1 do
      Inner := Inner + Current[i];
    if HasBalancedParenthesesInSlice(Current, 2, Count - 1) then
      Previous := Inner;
  end;
  Result := Previous;
end;

function TCalcParse.GetOperatorRank(Token: WideChar): Integer;
var
  Rank: Integer;
begin
  Rank := -1;
  case Token of
    '^': Rank := 1;
    '/': Rank := 1;
    'f': Rank := 1;
    'g': Rank := 1;
    '*': Rank := 2;
    '%': Rank := 2;
    '-': Rank := 3;
    '+': Rank := 4;
    '$': Rank := 5;
    '#': Rank := 6;
    'c': Rank := 7;
    'b': Rank := 7;
    'e': Rank := 7;
    '>': Rank := 7;
    '<': Rank := 7;
    '=': Rank := 7;
    '&': Rank := 8;
    '|': Rank := 9;
  end;
  Result := Rank;
end;

function TCalcParse.CollapseOperatorRun(const Text: WideString): WideString;
var
  i, MinusCount, PlusCount, Count: Integer;
  Operators: WideString;
begin
  Count := Length(Text);
  MinusCount := 0;
  PlusCount := 0;
  for i := 1 to Count do
  begin
    if Text[i] = '-' then
      Inc(MinusCount);
    if Text[i] = '+' then
      Inc(PlusCount);
  end;
  Operators := ReplaceAllWideString(Text, '-', '');
  Operators := ReplaceAllWideString(Operators, '+', '');
  if MinusCount mod 2 = 1 then
    Operators := Operators + '-'
  else if (PlusCount > 0) or (MinusCount > 0) then
    Operators := Operators + '+';
  Count := Length(Operators);
  MinusCount := 0;
  PlusCount := 0;
  for i := Count downto 1 do
    if GetOperatorRank(Operators[i]) >= MinusCount then
    begin
      PlusCount := i;
      MinusCount := GetOperatorRank(Operators[i]);
    end;
  Result := Operators[PlusCount];
end;

function TCalcParse.NormalizeFragments(const Text: WideString): WideString;
var
  Index, Count: Integer;
  Fragment, Output: WideString;
  Outside: Boolean;
begin
  Output := '';
  Index := 1;
  Count := Length(Text);
  Fragment := '';
  Outside := True;
  while Index <= Count do
  begin
    if Outside then
    begin
      if Text[Index] = '[' then
      begin
        Output := Output + NormalizeScalarFragment(Fragment);
        Fragment := '[';
        Outside := False;
        Inc(Index);
        Continue;
      end
      else if Text[Index] <> '[' then
      begin
        Fragment := Fragment + Text[Index];
        Inc(Index);
        if Index > Count then
          Output := Output + NormalizeScalarFragment(Fragment);
        Continue;
      end;
    end;
    if not Outside then
    begin
      if (Index > Count) or (Text[Index] = ']') then
      begin
        Output := Output + NormalizeBracketFragment(Fragment + ']');
        Fragment := '';
        Outside := True;
      end
      else
        Fragment := Fragment + Text[Index];
      Inc(Index);
    end;
  end;
  Result := Output;
end;

function TCalcParse.NormalizeScalarFragment(Text: WideString): WideString;
var
  Previous, Working, Output: WideString;
  i, Count: Integer;
begin
  Previous := '';
  Count := Length(Text);
  for i := 1 to Count do
  begin
    case Text[i] of
      '^':;
      '+':;
      '-':;
      '*':;
      '/':;
      '#':;
      '%':;
      '$':;
      'c':;
      'b':;
      'e':;
      'f':;
      'g':;
      '=':;
      '>':;
      '<':;
      '&':;
      '|':;
      '0'..'9':;
      ',':;
      '(':;
      ')':;
      ' ':;
    else
      Continue;
    end;
    Previous := Previous + Text[i];
  end;
  Text := Previous;
  repeat
    Previous := Text;
    Working := Text;
    repeat
      Text := Working;
      Working := ReplaceAllWideString(Working, ')(', ')*(');
      Working := ReplaceAllWideString(Working, '.', ',');
      Working := ReplaceAllWideString(Working, ',,', ',');
      Working := ReplaceAllWideString(Working, '(,', '(0,');
      Working := ReplaceAllWideString(Working, '),', ')*0,');
      Working := ReplaceAllWideString(Working, ')0', ')*0');
      Working := ReplaceAllWideString(Working, ')1', ')*1');
      Working := ReplaceAllWideString(Working, ')2', ')*2');
      Working := ReplaceAllWideString(Working, ')3', ')*3');
      Working := ReplaceAllWideString(Working, ')4', ')*4');
      Working := ReplaceAllWideString(Working, ')5', ')*5');
      Working := ReplaceAllWideString(Working, ')6', ')*6');
      Working := ReplaceAllWideString(Working, ')7', ')*7');
      Working := ReplaceAllWideString(Working, ')8', ')*8');
      Working := ReplaceAllWideString(Working, ')9', ')*9');
      Working := ReplaceAllWideString(Working, ',(', ',*(');
      Working := ReplaceAllWideString(Working, '0(', '0*(');
      Working := ReplaceAllWideString(Working, '1(', '1*(');
      Working := ReplaceAllWideString(Working, '2(', '2*(');
      Working := ReplaceAllWideString(Working, '3(', '3*(');
      Working := ReplaceAllWideString(Working, '4(', '4*(');
      Working := ReplaceAllWideString(Working, '5(', '5*(');
      Working := ReplaceAllWideString(Working, '6(', '6*(');
      Working := ReplaceAllWideString(Working, '7(', '7*(');
      Working := ReplaceAllWideString(Working, '8(', '8*(');
      Working := ReplaceAllWideString(Working, '9(', '9*(');
    until Text = Working;
    Count := Length(Text);
    Working := '';
    Output := '';
    i := 1;
    while i <= Count do
    begin
      if (GetOperatorRank(Text[i]) > 0) and (i <= Count) then
      begin
        Working := '';
        while (GetOperatorRank(Text[i]) > 0) and (i <= Count) do
        begin
          Working := Working + Text[i];
          Inc(i);
        end;
        Output := Output + CollapseOperatorRun(Working);
      end;
      if GetOperatorRank(Text[i]) < 0 then
      begin
        Working := '';
        while (GetOperatorRank(Text[i]) < 0) and (i <= Count) do
        begin
          Working := Working + Text[i];
          Inc(i);
        end;
        Output := Output + Working;
      end;
    end;
    Text := Output;
    Working := Text;
    repeat
      Text := Working;
      Working := ReplaceAllWideString(Working, '(+', '(');
      Working := ReplaceAllWideString(Working, '(*', '(');
      Working := ReplaceAllWideString(Working, '(/', '(');
      Working := ReplaceAllWideString(Working, '(&', '(');
      Working := ReplaceAllWideString(Working, '(|', '(');
      Working := ReplaceAllWideString(Working, '(#', '(');
      Working := ReplaceAllWideString(Working, '($', '(');
      Working := ReplaceAllWideString(Working, '(%', '(');
      Working := ReplaceAllWideString(Working, '(c', '(');
      Working := ReplaceAllWideString(Working, '(b', '(');
      Working := ReplaceAllWideString(Working, '(e', '(');
      Working := ReplaceAllWideString(Working, '(f', '(');
      Working := ReplaceAllWideString(Working, '(g', '(');
      Working := ReplaceAllWideString(Working, '(<', '(');
      Working := ReplaceAllWideString(Working, '(>', '(');
      Working := ReplaceAllWideString(Working, '(=', '(');
      Working := ReplaceAllWideString(Working, '-)', ')');
      Working := ReplaceAllWideString(Working, '+)', ')');
      Working := ReplaceAllWideString(Working, '*)', ')');
      Working := ReplaceAllWideString(Working, '/)', ')');
      Working := ReplaceAllWideString(Working, '&)', ')');
      Working := ReplaceAllWideString(Working, '%)', ')');
      Working := ReplaceAllWideString(Working, '|)', ')');
      Working := ReplaceAllWideString(Working, '$)', ')');
      Working := ReplaceAllWideString(Working, '#)', ')');
      Working := ReplaceAllWideString(Working, 'c)', ')');
      Working := ReplaceAllWideString(Working, 'b)', ')');
      Working := ReplaceAllWideString(Working, 'e)', ')');
      Working := ReplaceAllWideString(Working, 'f)', ')');
      Working := ReplaceAllWideString(Working, 'g)', ')');
      Working := ReplaceAllWideString(Working, '>)', ')');
      Working := ReplaceAllWideString(Working, '<)', ')');
      Working := ReplaceAllWideString(Working, '=)', ')');
      Working := ReplaceAllWideString(Working, ')(', ')*(');
    until Text = Working;
  until Previous = Text;
  Result := Text;
end;

function TCalcParse.NormalizeBracketFragment(Text: WideString): WideString;
begin
  if ReplaceAllWideString(Text, 'p', '') <> Text then
    Result := NormalizeParameterReference(Text)
  else
    Result := NormalizeRangeLiteral(Text);
end;

function TCalcParse.NormalizeParameterReference(Text: WideString): WideString;
var
  Count, i: Integer;
  Digits: WideString;
begin
  Count := Length(Text);
  Digits := '';
  for i := 1 to Count do
  begin
    if Length(Digits) > 2 then
      Break;
    if (Text[i] >= '0') and (Text[i] <= '9') then
      Digits := Digits + Text[i];
  end;
  i := ExtractDigitsToIntW('0' + Digits);
  if i > 0 then
    Result := '[p' + IntToWideString(i) + ']'
  else
  begin
    Result := '[err]';
    InvalidParameterReference := True;
    HasError := True;
  end;
end;

function TCalcParse.NormalizeRangeLiteral(Text: WideString): WideString;
var
  i, Count: Integer;
  Clean: WideString;
  Range: TCPDiapazone;
begin
  Clean := '';
  Count := Length(Text);
  for i := 1 to Count do
  begin
    case Text[i] of
      '[', ']': Continue;
      '0'..'9', '-', 'h', ';':;
    else
      Result := '[err]';
      InvalidRangeLiteral := True;
      HasError := True;
      Exit;
    end;
    Clean := Clean + Text[i];
  end;
  Text := ';' + Clean + ';';
  Clean := Text;
  repeat
    Text := Clean;
    Clean := ReplaceAllWideString(Clean, '--', '');
    Clean := ReplaceAllWideString(Clean, ';;', ';');
    Clean := ReplaceAllWideString(Clean, 'h;', ';');
    Clean := ReplaceAllWideString(Clean, ';h', ';');
    Clean := ReplaceAllWideString(Clean, '-;', ';');
    Clean := ReplaceAllWideString(Clean, '-h', 'h');
    Clean := ReplaceAllWideString(Clean, 'hh', 'h');
  until Text = Clean;
  if (Clean <> ';') and (Length(Text) > 0) then
  begin
    Text[1] := '[';
    Text[Length(Text)] := ']';
    Range := TCPDiapazone.Create;
    Range.LoadFromText(Text);
    Text := Range.ToText;
    Range.Destroy;
    Result := Text;
  end
  else
  begin
    Result := '[err]';
    InvalidRangeLiteral := True;
    HasError := True;
  end;
end;

function TCalcParse.InsertImplicitMultiplication(Text: WideString): WideString;
var
  Current: WideString;
begin
  Current := Text;
  repeat
    Text := Current;
    Current := ReplaceAllWideString(Current, '-,', '-0,');
    Current := ReplaceAllWideString(Current, ')[', ')*[');
    Current := ReplaceAllWideString(Current, '](', ']*(');
    Current := ReplaceAllWideString(Current, ')(', ')*(');
    Current := ReplaceAllWideString(Current, '][', ']*[');
    Current := ReplaceAllWideString(Current, '],', ']*0,');
    Current := ReplaceAllWideString(Current, ']0', ']*0');
    Current := ReplaceAllWideString(Current, ']1', ']*1');
    Current := ReplaceAllWideString(Current, ']2', ']*2');
    Current := ReplaceAllWideString(Current, ']3', ']*3');
    Current := ReplaceAllWideString(Current, ']4', ']*4');
    Current := ReplaceAllWideString(Current, ']5', ']*5');
    Current := ReplaceAllWideString(Current, ']6', ']*6');
    Current := ReplaceAllWideString(Current, ']7', ']*7');
    Current := ReplaceAllWideString(Current, ']8', ']*8');
    Current := ReplaceAllWideString(Current, ']9', ']*9');
    Current := ReplaceAllWideString(Current, ',[', ',*[');
    Current := ReplaceAllWideString(Current, '0[', '0*[');
    Current := ReplaceAllWideString(Current, '1[', '1*[');
    Current := ReplaceAllWideString(Current, '2[', '2*[');
    Current := ReplaceAllWideString(Current, '3[', '3*[');
    Current := ReplaceAllWideString(Current, '4[', '4*[');
    Current := ReplaceAllWideString(Current, '5[', '5*[');
    Current := ReplaceAllWideString(Current, '6[', '6*[');
    Current := ReplaceAllWideString(Current, '7[', '7*[');
    Current := ReplaceAllWideString(Current, '8[', '8*[');
    Current := ReplaceAllWideString(Current, '9[', '9*[');
  until Text = Current;
  Result := Text;
end;

function TCalcParse.FindTopLevelOperator(const Text: WideString; TextLength: Integer): Integer;
var
  Rank, BestRank, BestIndex, i, BracketDepth, ParenthesisDepth: Integer;
begin
  BestRank := 0;
  BestIndex := 0;
  BracketDepth := 0;
  ParenthesisDepth := 0;
  for i := 1 to TextLength do
  begin
    if Text[i] = '(' then
      Inc(ParenthesisDepth);
    if Text[i] = '[' then
      Inc(BracketDepth);
    if Text[i] = ')' then
      Dec(ParenthesisDepth);
    if Text[i] = ']' then
      Dec(BracketDepth);
    if (ParenthesisDepth = 0) and (BracketDepth = 0) then
    begin
      Rank := GetOperatorRank(Text[i]);
      if BestRank <= Rank then
      begin
        BestRank := Rank;
        BestIndex := i;
      end;
    end;
  end;
  Result := BestIndex;
end;

function TCalcParse.EvaluateExpression(Text: WideString): TCPVariant;
var
  Count: Integer;
  Inner, LeftText, RightText: WideString;
  i, Index: Integer;
  Left, Right, Value: TCPVariant;
begin
  Value := TCPVariant.Create;
  Left := TCPVariant.Create;
  Right := TCPVariant.Create;
  if not EvaluationError then
  begin
    Count := Length(Text);
    if not Value.TryLoadFromText(Text) then
    begin
      if (Text[1] = '(')
          and (Text[Count] = ')')
          and HasBalancedParenthesesInSlice(Text, 2, Count - 1) then
      begin
        Inner := '';
        for i := 2 to Count - 1 do
          Inner := Inner + Text[i];
        if Length(Inner) = 0 then
          HasError := True
        else
          Value.Assign(EvaluateExpression(Inner), False);
      end
      else
      begin
        Index := FindTopLevelOperator(Text, Count);
        if Index < 1 then
          EvaluationError := True
        else
        begin
          LeftText := '';
          for i := 1 to Index - 1 do
            LeftText := LeftText + Text[i];
          RightText := '';
          for i := Index + 1 to Count do
            RightText := RightText + Text[i];
          Right.Assign(EvaluateExpression(RightText), False);
          if not EvaluationError then
          begin
            Left.Assign(EvaluateExpression(LeftText), False);
            if not EvaluationError then
              try
                if Text[Index] = '^' then
                  ApplyPower(Left, Right, Value)
                else if Text[Index] = '+' then
                  ApplyAdd(Left, Right, Value)
                else if Text[Index] = '-' then
                  ApplySubtract(Left, Right, Value)
                else if Text[Index] = '*' then
                  ApplyMultiply(Left, Right, Value)
                else if Text[Index] = '/' then
                  ApplyDivide(Left, Right, Value)
                else if Text[Index] = 'f' then
                  ApplyIntDivide(Left, Right, Value)
                else if Text[Index] = 'g' then
                  ApplyModulo(Left, Right, Value)
                else if Text[Index] = '%' then
                  ApplyPercentChange(Left, Right, Value)
                else if Text[Index] = '$' then
                  ApplyRange(Left, Right, Value)
                else if Text[Index] = '#' then
                  ApplyMembership(Left, Right, Value)
                else if Text[Index] = '>' then
                  ApplyGreaterThan(Left, Right, Value)
                else if Text[Index] = '<' then
                  ApplyLessThan(Left, Right, Value)
                else if Text[Index] = 'c' then
                  ApplyGreaterOrEqual(Left, Right, Value)
                else if Text[Index] = 'b' then
                  ApplyLessOrEqual(Left, Right, Value)
                else if Text[Index] = 'e' then
                  ApplyNotEqual(Left, Right, Value)
                else if Text[Index] = '=' then
                  ApplyEqual(Left, Right, Value)
                else if Text[Index] = '&' then
                  ApplyAnd(Left, Right, Value)
                else if Text[Index] = '|' then
                  ApplyOr(Left, Right, Value);
              except
                on EMathError do
                begin
                  EvaluationError := True;
                  HasError := True;
                end;
                on EInvalidOp do
                begin
                  EvaluationError := True;
                  HasError := True;
                end;
                on EOverflow do
                begin
                  EvaluationError := True;
                  HasError := True;
                end;
                on EZeroDivide do
                begin
                  EvaluationError := True;
                  HasError := True;
                end;
              end;
          end;
        end;
      end;
    end;
  end;
  Result := TCPVariant.Create;
  Result.Assign(Value, False);
  Value.Destroy;
  Right.Destroy;
  Left.Destroy;
end;

procedure TCalcParse.Evaluate(Parameters: TList);
var
  Value: TCPVariant;
begin
  Value := TCPVariant.Create;
  if not HasError then
  begin
    Value.Assign(EvaluateExpression('(' + SubstituteParameters(Parameters) + ')'), False);
    try
      ResultValue := Value.AsInteger;
    except
      on EInvalidOp do
      begin
        EvaluationError := True;
        HasError := True;
        ResultValue := 0;
      end;
    end;
    if EvaluationError then
      HasError := True;
  end;
end;

procedure TCalcParse.Prepare(Text: WideString; DefaultParameterIndex: Integer);
var
  Count, i: Integer;
  Readable: WideString;
begin
  Reset;
  SourceText := Text;
  Text := NormalizeTokens(Text);
  Text := NormalizeFragments(Text);
  Text := InsertImplicitMultiplication(Text);
  Text := ClampNumericLiterals(Text);
  UnbalancedParentheses := not HasBalancedParentheses(Text);
  if UnbalancedParentheses then
    HasError := True;
  Readable := Text;
  if not HasError then
  begin
    Count := Length(Text);
    if (Count >= 2)
        and (Text[1] = '(')
        and (Text[Count] = ')')
        and HasBalancedParenthesesInSlice(Text, 2, Count - 1) then
    begin
      Readable := '';
      for i := 2 to Count - 1 do
        Readable := Readable + Text[i];
    end;
  end;
  if SourceText <> FormatTokens(Readable) then
    SourceWasChanged := True;
  if (Text = '') or (Text = '[p' + IntToWideString(DefaultParameterIndex) + ']') then
  begin
    UsesDefaultParameter := True;
    Text := '[p' + IntToWideString(DefaultParameterIndex) + ']';
  end;
  Expression := Text;
end;

constructor TCalcParse.Create;
begin
  Reset;
end;

procedure TCalcParse.Reset;
begin
  SourceText := '';
  Expression := '';
  ResultValue := 0;
  ResetValue10 := 0;
  SourceWasChanged := False;
  UnbalancedParentheses := False;
  InvalidNumericLiteral := False;
  InvalidParameterReference := False;
  InvalidRangeLiteral := False;
  EvaluationError := False;
  UsesDefaultParameter := False;
  HasError := False;
end;

function TCalcParse.HasBalancedParenthesesInSlice(
    const Text: WideString;
    FirstIndex, LastIndex: Integer
): Boolean;
var
  Depth, i: Integer;
  Balanced: Boolean;
begin
  Depth := 0;
  Balanced := True;
  for i := FirstIndex to LastIndex do
  begin
    if Text[i] = '(' then
      Inc(Depth);
    if Text[i] = ')' then
      Dec(Depth);
    if Depth < 0 then
    begin
      Balanced := False;
      Break;
    end;
  end;
  if Depth <> 0 then
    Balanced := False;
  Result := Balanced;
end;

function TCalcParse.SubstituteParameters(Parameters: TList): WideString;
var
  i: Integer;
  Text: WideString;
  Parameter: TParameter;
begin
  Text := Expression;
  for i := 1 to Parameters.Count do
  begin
    Parameter := TParameter(Parameters[i - 1]);
    if Parameter.Value < 0 then
      Text :=
          ReplaceAllWideString(
              Text,
              '[p' + IntToWideString(i) + ']',
              '(0' + IntToWideString(Parameter.Value) + ')'
          )
    else
      Text :=
          ReplaceAllWideString(
              Text,
              '[p' + IntToWideString(i) + ']',
              IntToWideString(Parameter.Value)
          );
  end;
  Result := Text;
end;

function TCalcParse.HasBalancedParentheses(const Text: WideString): Boolean;
var
  Balanced: Boolean;
begin
  Balanced := HasBalancedParenthesesInSlice(Text, 1, Length(Text));
  Result := Balanced;
end;

function TCalcParse.ClampNumericLiterals(Text: WideString): WideString;
var
  Index, Count: Integer;
  Value: Extended;
  Output: WideString;
  Digits, Replacement: AnsiString;
  SavedSeparator: AnsiChar;
begin
  Index := 1;
  Count := Length(Text);
  Digits := '';
  Output := '';
  Value := 0;
  while Index <= Count do
  begin
    if ((Text[Index] >= '0') and (Text[Index] <= '9')) or (Text[Index] = ',') then
      Digits := AnsiString(WideString(Digits) + Text[Index])
    else if Digits <> '' then
    begin
      SavedSeparator := SysUtils.DecimalSeparator;
      try
        SysUtils.DecimalSeparator := ',';
        Value := SysUtils.StrToFloat(Digits);
        SysUtils.DecimalSeparator := SavedSeparator;
      except
        on EConvertError do
        begin
          HasError := True;
          InvalidNumericLiteral := True;
          SysUtils.DecimalSeparator := SavedSeparator;
          Exit;
        end;
      end;
      if Value > 999999999 then
        Replacement := '999999999'
      else if (Value < 0.0001) and (Value <> 0) then
        Replacement := '0.0001'
      else
        Replacement := Digits;
      Output := Output + WideString(Replacement) + Text[Index];
      Digits := '';
    end
    else
      Output := Output + Text[Index];
    Inc(Index);
  end;
  Result := Output;
end;

end.
