unit aBezierPC24;

{$MODE delphi}
{$INLINE on}
{$R-}
{$Q-}
{$OPTIMIZATION nofastmath}
{ This kernel controls its own significand rounding and exponent scaling. }
{$LEGACYPC24 OFF}

interface

type
  { The original Bezier recurrence needs more exponent range than Double.
    Only the significand participates in hardware Single arithmetic. }
  TBezierPC24Wide = record
    Mantissa: Single;
    Exponent: Integer;
  end;

function BezierWide(Value: Double): TBezierPC24Wide; inline;
function BezierMul(const A, B: TBezierPC24Wide): TBezierPC24Wide; inline;
function BezierDiv(const A, B: TBezierPC24Wide): TBezierPC24Wide; inline;
function BezierPower(Base: TBezierPC24Wide; Exponent: Integer): TBezierPC24Wide;
function BezierValue(const Value: TBezierPC24Wide): Double; inline;
function BezierAddProduct(
    Accumulator: Double;
    const Weight: TBezierPC24Wide;
    Coordinate: Single
): Double; inline;

implementation

function BezierWide(Value: Double): TBezierPC24Wide;
var
  Bits, Fraction: QWord;
  EncodedExponent, Shift: Integer;
begin
  Bits := PQWord(@Value)^;
  EncodedExponent := (Bits shr 52) and 2047;
  if (EncodedExponent <> 0) and (EncodedExponent <> 2047) then
  begin
    Bits := (Bits and QWord($800FFFFFFFFFFFFF)) or (QWord(1023) shl 52);
    Result.Mantissa := PDouble(@Bits)^;
    Result.Exponent := EncodedExponent - 1023;
  end
  else
  begin
    Fraction := Bits and QWord($000FFFFFFFFFFFFF);
    if (EncodedExponent = 0) and (Fraction <> 0) then
    begin
      Shift := 0;
      while (Fraction and (QWord(1) shl 52)) = 0 do
      begin
        Fraction := Fraction shl 1;
        Inc(Shift);
      end;
      { frexp's [0.5, 1) representation for a subnormal input. }
      Bits :=
          (Bits and QWord($8000000000000000))
              or (QWord(1022) shl 52)
              or (Fraction and QWord($000FFFFFFFFFFFFF));
      Result.Mantissa := PDouble(@Bits)^;
      Result.Exponent := -1021 - Shift;
    end
    else
    begin
      Result.Mantissa := Value;
      Result.Exponent := 0;
    end;
  end;
end;

function Normalize(Mantissa: Single; Exponent: Integer): TBezierPC24Wide; inline;
var
  Bits: Cardinal;
  EncodedExponent: Integer;
begin
  Bits := PCardinal(@Mantissa)^;
  EncodedExponent := (Bits shr 23) and 255;
  if (EncodedExponent <> 0) and (EncodedExponent <> 255) then
  begin
    Bits := (Bits and $807FFFFF) or (127 shl 23);
    Result.Mantissa := PSingle(@Bits)^;
    Result.Exponent := Exponent + EncodedExponent - 127;
  end
  else
  begin
    Result.Mantissa := Mantissa;
    Result.Exponent := 0;
  end;
end;

function BezierMul(const A, B: TBezierPC24Wide): TBezierPC24Wide;
begin
  Result := Normalize(A.Mantissa * B.Mantissa, A.Exponent + B.Exponent);
end;

function BezierDiv(const A, B: TBezierPC24Wide): TBezierPC24Wide;
begin
  Result := Normalize(A.Mantissa / B.Mantissa, A.Exponent - B.Exponent);
end;

function BezierPower(Base: TBezierPC24Wide; Exponent: Integer): TBezierPC24Wide;
var
  Remaining: Cardinal;
begin
  if Exponent < 0 then
    Remaining := Cardinal(0) - Cardinal(Exponent)
  else
    Remaining := Cardinal(Exponent);
  Result := BezierWide(1);
  while Remaining <> 0 do
  begin
    if (Remaining and 1) <> 0 then
      Result := BezierMul(Result, Base);
    Remaining := Remaining shr 1;
    if Remaining <> 0 then
      Base := BezierMul(Base, Base);
  end;
  if Exponent < 0 then
    Result := BezierDiv(BezierWide(1), Result);
end;

function BezierValue(const Value: TBezierPC24Wide): Double;
var
  Bits, Sign, Significand, Tail, Half: QWord;
  EncodedExponent, Target, Shift: Integer;
begin
  Result := Value.Mantissa;
  Bits := PQWord(@Result)^;
  EncodedExponent := (Bits shr 52) and 2047;
  if (EncodedExponent = 0) or (EncodedExponent = 2047) then
    Exit;
  Target := EncodedExponent + Value.Exponent;
  Sign := Bits and QWord($8000000000000000);
  if (Target > 0) and (Target < 2047) then
    Bits := (Bits and QWord($800FFFFFFFFFFFFF)) or (QWord(Target) shl 52)
  else if Target >= 2047 then
    Bits := Sign or QWord($7FF0000000000000)
  else if Target < -52 then
    Bits := Sign
  else
  begin
    { Round a possible binary64 subnormal once, with ties to even. }
    Significand := (Bits and QWord($000FFFFFFFFFFFFF)) or (QWord(1) shl 52);
    Shift := 1 - Target;
    Half := QWord(1) shl (Shift - 1);
    Tail := Significand and ((QWord(1) shl Shift) - 1);
    Significand := Significand shr Shift;
    if (Tail > Half) or ((Tail = Half) and ((Significand and 1) <> 0)) then
      Inc(Significand);
    Bits := Sign or Significand;
  end;
  Result := PDouble(@Bits)^;
end;

function Round24(Value: Double): Double; inline;
var
  Bits, Tail: QWord;
  EncodedExponent: Integer;
  Rounded: Single;
begin
  Bits := PQWord(@Value)^;
  EncodedExponent := (Bits shr 52) and 2047;
  if (EncodedExponent >= 897) and (EncodedExponent <= 1150) then
  begin
    Rounded := Value;
    Exit(Rounded);
  end;
  if ((Bits and QWord($7FFFFFFFFFFFFFFF)) = 0) or (EncodedExponent = 2047) then
    Exit(Value);
  Tail := Bits and QWord($1FFFFFFF);
  Bits := Bits and not QWord($1FFFFFFF);
  if (Tail > QWord($10000000))
      or ((Tail = QWord($10000000)) and ((Bits and QWord($20000000)) <> 0)) then
    Inc(Bits, QWord($20000000));
  Result := PDouble(@Bits)^;
end;

function BezierAddProduct(
    Accumulator: Double;
    const Weight: TBezierPC24Wide;
    Coordinate: Single
): Double;
var
  Product: TBezierPC24Wide;
  Bits: QWord;
  A, P, Sum: Single;
begin
  Product := BezierMul(Weight, BezierWide(Coordinate));
  Bits := PQWord(@Accumulator)^ and QWord($7FFFFFFFFFFFFFFF);
  if ((Product.Mantissa = 0) or ((Product.Exponent >= -126) and (Product.Exponent <= 127)))
      and ((Bits = 0) or (((Bits shr 52) >= 897) and ((Bits shr 52) <= 1150))) then
  begin
    A := Accumulator;
    P := BezierValue(Product);
    Sum := A + P;
    Result := Sum;
  end
  else
    Result := Round24(Accumulator + BezierValue(Product));
end;

end.
