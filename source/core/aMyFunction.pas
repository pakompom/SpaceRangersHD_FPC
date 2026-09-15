{$EXCESSPRECISION OFF}
unit aMyFunction;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  Classes,
  Types;
type
  TPolarPoint = record
    AngleDegrees: Double;
    Radius: Double;
  end;
  TPolarRadiansPoint = packed record
    AngleRadians: Double;
    Radius: Double;
  end;
var
  InfoNameColorTag: WideString = '<color=57,239,255>';
  InfoHullSeriesColorTag: WideString = '<color=82,166,255>';
type
  TObjectList = class;
  TObjectList = class(TList)
    destructor Destroy; override;
    procedure FreeItems;
  end;
const
  PolarDegreesToRadians: Single = 0.01745329238474369049;
function RandomIntRange(BoundA: Integer; BoundB: Integer): Integer;
function SeededRandomIntRange(BoundA: Integer; BoundB: Integer; Seed: Cardinal): Integer;
function RandomUnitFloat: Single;
function SeededRandomUnitFloat(Seed: Cardinal): Single;
function RandomFloatRange(BoundA: Double; BoundB: Double): Double;
function SeededRandomFloatRange(Seed: Cardinal; BoundA: Double; BoundB: Double): Double;
function StepRandomSeed(Seed: Cardinal): Cardinal;
function AdvanceRandomSeed(var Seed: Cardinal): Cardinal;
function NextRandomIntRange(BoundA: Integer; BoundB: Integer; var Seed: Cardinal): Integer;
function NextRandomFloatRange(BoundA: Double; BoundB: Double; var Seed: Cardinal): Double;
function NextRandomUnitFloat(var Seed: Cardinal): Double;
function FractionalQuotient(Numerator: Integer; Denominator: Integer): Double;
function RoundAndTruncateToFives(Value: Double): Integer;
function RoundAndTruncateToTens(Value: Double): Integer;
function RoundAndTruncateToHundreds(Value: Double): Integer;
function PointFromRadiusAngle(Radius: Single; Angle: Single): TPointF;
function OffsetPointByRadiusAngle(Origin: TPointF; Radius: Single; Angle: Single): TPointF;
function RotateAndTranslatePoint(Point: TPointF; Translation: TPointF; Angle: Single): TPointF;
function PolarToPoint(Polar: TPolarPoint): TPointF;
function IntegerPointToPolar(Point: TPoint): TPolarRadiansPoint;
function HeadingDegreesToByte(Angle: Double): Byte;
function ByteToHeadingDegrees(Angle: Byte): Double;
function RadiansToHeadingDegrees(Angle: Double): Double;
function HeadingDegreesToRadians(Angle: Double): Double;
function PointBearingDegrees(PointA: TPointF; PointB: TPointF): Double;
function HeadingDifferenceDegrees(FromHeading: Double; ToHeading: Double): Double;
function WrapHeadingDegrees(Angle: Single): Single;
function WrapSignedHeadingDegrees(Angle: Single): Single;
function HeadingWithinArc(ArcStart: Single; Heading: Single; ArcEnd: Single): Boolean;
function PushPointOutsideCircleBand(Point: TPointF; Radius: Single; Margin: Single): TPointF;
function RotatePointQuarterTurn(Center: TPointF; Point: TPointF): TPointF;
function IntersectLines(
    A1: TPointF;
    A2: TPointF;
    B1: TPointF;
    B2: TPointF;
    out Intersection: TPointF
): Boolean;
function SegmentIntersectsRectEdges(
    StartPoint: TPointF;
    EndPoint: TPointF;
    TopLeft: TPointF;
    BottomRight: TPointF;
    out Intersection: TPointF
): Boolean;
function SegmentIntersectsCircle(
    StartPoint: TPointF;
    EndPoint: TPointF;
    Center: TPointF;
    Radius: Single
): Boolean;
function SegmentCrossesOriginCircle(
    StartPoint: TPointF;
    EndPoint: TPointF;
    Radius: Single
): Boolean;
function RayIntersectsOriginCircle(
    StartPoint: TPointF;
    ThroughPoint: TPointF;
    out Intersection: TPointF;
    Radius: Single
): Boolean;
function CalculateTangentArcOffset(
    StartPoint: TPointF;
    EndPoint: TPointF;
    Heading: Double;
    Angle: Double
): Double;
procedure CircleTangentPoints(
    Point: TPointF;
    Radius: Single;
    out LeftPoint: TPointF;
    out RightPoint: TPointF
);
function PointBehindHeading(
    Origin: TPointF;
    Heading: Double;
    Distance: Double;
    Seed: Cardinal
): TPointF;
function PointDistanceSquared(PointA: TPointF; PointB: TPointF): Single;
function PointDistance(PointA: TPointF; PointB: TPointF): Double;
function IntegerPointDistancePlusOne(PointA: TPoint; PointB: TPoint): Integer;
function RemapClamped(
    Value: Double;
    InMin: Double;
    InMax: Double;
    OutMin: Double;
    OutMax: Double
): Double;
function MakeFloatPoint(X: Integer; Y: Integer): TPointF;
procedure ReplaceTextToken(
    var Text: WideString;
    Token: WideString;
    Replacement: WideString;
    ColorTag: WideString
);
function ReplaceColoredToken(
    Text: WideString;
    Token: WideString;
    Replacement: WideString;
    ColorTag: WideString
): WideString;
function FormatText1(
    Text: WideString;
    ColorTag: WideString;
    Token: WideString;
    Replacement: WideString
): WideString;
function FormatText2(
    Text: WideString;
    ColorTag: WideString;
    Token1: WideString;
    Replacement1: WideString;
    Token2: WideString;
    Replacement2: WideString
): WideString;
function FormatText3(
    Text: WideString;
    ColorTag: WideString;
    Token1: WideString;
    Replacement1: WideString;
    Token2: WideString;
    Replacement2: WideString;
    Token3: WideString;
    Replacement3: WideString
): WideString;
function WrapTextInColor(Text: WideString; ColorTag: WideString): WideString;
function NormalizeTextHighlightColors(Text: WideString): WideString;
function IncrementWrapped(var Value: Integer; Minimum: Integer; Maximum: Integer): Integer;
function DecrementWrappedValue(Value: Integer; Minimum: Integer; Maximum: Integer): Integer;
implementation
uses
  ObserverHooks,
  EC_Str,
  aGalaxy,
  Math;
// @unit-initialization $877AA8
// @unit-finalization $8741A0

destructor TObjectList.Destroy;
begin
  FreeItems;
  inherited Destroy;
end;

procedure TObjectList.FreeItems;
var
  i: Integer;
  Item: TObject;
begin
  for i := Count - 1 downto 0 do
    if List^[i] <> nil then
    begin
      Item := TObject(List^[i]);
      Delete(i);
      Item.Free;
    end;
  Clear;
end;

function RandomIntRange(BoundA, BoundB: Integer): Integer;
begin
  if BoundA <= BoundB then
    Result := PresentationRandom(BoundB - BoundA + 1) + BoundA
  else
    Result := PresentationRandom(BoundA - BoundB + 1) + BoundB;
end;

function SeededRandomIntRange(BoundA, BoundB: Integer; Seed: Cardinal): Integer;
begin
  if (Galaxy <> nil) and Galaxy.IsChaoticRandomEnabled then
  begin
    if BoundA <= BoundB then
      Result := PresentationRandom(BoundB - BoundA + 1) + BoundA
    else
      Result := PresentationRandom(BoundA - BoundB + 1) + BoundB;
  end
  else if BoundA < BoundB then
    Result := Seed mod Cardinal(BoundB - BoundA + 1) + BoundA
  else
    Result := Seed mod Cardinal(BoundA - BoundB + 1) + BoundB;
end;

function RandomUnitFloat: Single;
begin
  Result := RandomIntRange(1, 1000) / 1000;
end;

function SeededRandomUnitFloat(Seed: Cardinal): Single;
begin
  Result := SeededRandomIntRange(1, 1000, Seed) / 1000;
end;

function RandomFloatRange(BoundA, BoundB: Double): Double;
begin
  Result := RandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1)) / 1000;
end;

function SeededRandomFloatRange(Seed: Cardinal; BoundA, BoundB: Double): Double;
begin
  Result := SeededRandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1), Seed) / 1000;
end;

function StepRandomSeed(Seed: Cardinal): Cardinal;
begin
  Result := Seed * 7981 + 567;
end;

function AdvanceRandomSeed(var Seed: Cardinal): Cardinal;
var
  OldSeed: Cardinal;
begin
  OldSeed := Seed;
  Seed := Seed * 7981 + 567 + Seed div 7981;
  if Seed = OldSeed then
    Seed := Seed * 7281 + 517 + Seed div 7181;
  Result := Seed;
end;

function NextRandomIntRange(BoundA, BoundB: Integer; var Seed: Cardinal): Integer;
var
  OldSeed: Cardinal;
begin
  if (Galaxy <> nil) and Galaxy.IsChaoticRandomEnabled then
    Result := RandomIntRange(BoundA, BoundB)
  else
  begin
    OldSeed := Seed;
    Seed := Seed * 7981 + 567 + Seed div 7981;
    if Seed = OldSeed then
      Seed := Seed * 7281 + 517 + Seed div 7181;
    if BoundA < BoundB then
      Result := Seed mod Cardinal(BoundB - BoundA + 1) + BoundA
    else
      Result := Seed mod Cardinal(BoundA - BoundB + 1) + BoundB;
  end;
end;

function NextRandomFloatRange(BoundA, BoundB: Double; var Seed: Cardinal): Double;
var
  OldSeed: Cardinal;
begin
  if (Galaxy <> nil) and Galaxy.IsChaoticRandomEnabled then
    Result := RandomFloatRange(BoundA, BoundB)
  else
  begin
    OldSeed := Seed;
    Seed := Seed * 7981 + 567 + Seed div 7931;
    if Seed = OldSeed then
      Seed := Seed * 6281 + 317 + Seed div 7311;
    Result := SeededRandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1), Seed) / 1000;
  end;
end;

function NextRandomUnitFloat(var Seed: Cardinal): Double;
var
  OldSeed: Cardinal;
begin
  if (Galaxy <> nil) and Galaxy.IsChaoticRandomEnabled then
    Result := RandomFloatRange(0, 1)
  else
  begin
    OldSeed := Seed;
    Seed := Seed * 7981 + 5671;
    if Seed = OldSeed then
      Seed := Seed * 5331 + 3417;
    Result := Frac(Seed / 10011001);
  end;
end;

function FractionalQuotient(Numerator, Denominator: Integer): Double;
begin
  Result := Frac(Numerator / Denominator);
end;

function RoundAndTruncateToFives(Value: Double): Integer;
begin
  Result := (Round(Value) div 5) * 5;
end;

function RoundAndTruncateToTens(Value: Double): Integer;
begin
  Result := (Round(Value) div 10) * 10;
end;

function RoundAndTruncateToHundreds(Value: Double): Integer;
begin
  Result := (Round(Value) div 100) * 100;
end;

function PointFromRadiusAngle(Radius, Angle: Single): TPointF;
begin
  Result.X := Radius * Cos(Angle);
  Result.Y := Radius * Sin(Angle)
end;

function OffsetPointByRadiusAngle(Origin: TPointF; Radius, Angle: Single): TPointF;
begin
  Result.X := Origin.X + Radius * Cos(Angle);
  Result.Y := Origin.Y + Radius * Sin(Angle)
end;

function RotateAndTranslatePoint(Point, Translation: TPointF; Angle: Single): TPointF;
begin
  Result.X := Point.X * Cos(Angle) - Point.Y * Sin(Angle) + Translation.X;
  Result.Y := Point.X * Sin(Angle) + Point.Y * Cos(Angle) + Translation.Y
end;

function PolarToPoint(Polar: TPolarPoint): TPointF;
begin
  Result.X := Polar.Radius * Sin(Polar.AngleDegrees * PolarDegreesToRadians);
  Result.Y := -Polar.Radius * Cos(Polar.AngleDegrees * PolarDegreesToRadians)
end;

function IntegerPointToPolar(Point: TPoint): TPolarRadiansPoint;
begin
  Result.Radius := Sqrt(Point.X * Point.X + Point.Y * Point.Y);
  Result.AngleRadians := ArcTan2(Point.X, Point.Y);
end;

function HeadingDegreesToByte(Angle: Double): Byte;
begin
  Result := Round(Angle * 256 / 360);
end;

function ByteToHeadingDegrees(Angle: Byte): Double;
begin
  Result := Angle * (360 / 256);
end;

function RadiansToHeadingDegrees(Angle: Double): Double;
begin
  Result := Angle * (180 / 3.1415926);
  if Result < 0 then
    Result := 360 + Result;
end;

function HeadingDegreesToRadians(Angle: Double): Double;
begin
  if Angle > 180 then
    Angle := Angle - 360;
  Result := Angle * (3.1415926 / 180);
end;

function PointBearingDegrees(PointA, PointB: TPointF): Double;
begin
  Result := RadiansToHeadingDegrees(ArcTan2(PointB.X - PointA.X, -(PointB.Y - PointA.Y)));
end;

function HeadingDifferenceDegrees(FromHeading, ToHeading: Double): Double;
begin
  Result := ToHeading - FromHeading;
  if FromHeading < 180 then
  begin
    if Result > 180 then
      Result := Result - 360;
  end
  else if Result < -180 then
    Result := 360 + Result;
end;

function WrapHeadingDegrees(Angle: Single): Single;
begin
  while Angle >= 360 do
    Angle := Angle - 360;
  while Angle < 0 do
    Angle := 360 + Angle;
  Result := Angle;
end;

function WrapSignedHeadingDegrees(Angle: Single): Single;
begin
  while Angle >= 180 do
    Angle := Angle - 360;
  while Angle < -180 do
    Angle := 360 + Angle;
  Result := Angle;
end;

function HeadingWithinArc(ArcStart, Heading, ArcEnd: Single): Boolean;
var
  A, B: Single;
begin
  A := HeadingDifferenceDegrees(ArcStart, Heading);
  B := HeadingDifferenceDegrees(ArcStart, ArcEnd);
  if ((A < 0) and (B > 0)) or ((A > 0) and (B < 0)) then
  begin
    Result := False;
    Exit;
  end;
  A := HeadingDifferenceDegrees(ArcEnd, Heading);
  B := HeadingDifferenceDegrees(ArcEnd, ArcStart);
  if ((A < 0) and (B > 0)) or ((A > 0) and (B < 0)) then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;

function PushPointOutsideCircleBand(Point: TPointF; Radius, Margin: Single): TPointF;
var
  Distance: Single;
begin
  Distance := Sqrt(Point.X * Point.X + Point.Y * Point.Y);
  if Abs(Radius - Distance) <= Margin then
  begin
    Result.X := (Point.X / Distance) * (Radius + Margin);
    Result.Y := (Point.Y / Distance) * (Radius + Margin);
  end
  else
    Result := Point;
end;

function RotatePointQuarterTurn(Center, Point: TPointF): TPointF;
begin
  Result.X := Center.X - (Point.Y - Center.Y);
  Result.Y := Point.X - Center.X + Center.Y;
end;

function IntersectLines(A1, A2, B1, B2: TPointF; out Intersection: TPointF): Boolean;
var
  AX, AY, BX, BY, Divisor: Double;
begin
  AX := A2.X - A1.X;
  AY := A2.Y - A1.Y;
  BX := B2.X - B1.X;
  BY := B2.Y - B1.Y;
  Divisor := AY * BX - BY * AX;
  if Divisor = 0 then
  begin
    Result := False;
    Exit;
  end;
  Intersection.X := ((B1.Y - A1.Y) * AX * BX + AY * BX * A1.X - BY * AX * B1.X) / Divisor;
  if AX <> 0 then
    Intersection.Y := (Intersection.X - A1.X) * AY / AX + A1.Y
  else
    Intersection.Y := (Intersection.X - B1.X) * BY / BX + B1.Y;
  Result := True;
end;

function SegmentIntersectsRectEdges(
    StartPoint, EndPoint, TopLeft, BottomRight: TPointF;
    out Intersection: TPointF
): Boolean;
var
  A, B: TPointF;
begin
  A.X := TopLeft.X;
  A.Y := TopLeft.Y;
  B.X := BottomRight.X;
  B.Y := TopLeft.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.X >= A.X)
        and (Intersection.X <= B.X)
        and (Intersection.Y >= Min(StartPoint.Y, EndPoint.Y))
        and (Intersection.Y <= Max(StartPoint.Y, EndPoint.Y)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := TopLeft.X;
  A.Y := BottomRight.Y;
  B.X := BottomRight.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.X >= A.X)
        and (Intersection.X <= B.X)
        and (Intersection.Y >= Min(StartPoint.Y, EndPoint.Y))
        and (Intersection.Y <= Max(StartPoint.Y, EndPoint.Y)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := TopLeft.X;
  A.Y := TopLeft.Y;
  B.X := TopLeft.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.Y >= A.Y)
        and (Intersection.Y <= B.Y)
        and (Intersection.X >= Min(StartPoint.X, EndPoint.X))
        and (Intersection.X <= Max(StartPoint.X, EndPoint.X)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := BottomRight.X;
  A.Y := TopLeft.Y;
  B.X := BottomRight.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.Y >= A.Y)
        and (Intersection.Y <= B.Y)
        and (Intersection.X >= Min(StartPoint.X, EndPoint.X))
        and (Intersection.X <= Max(StartPoint.X, EndPoint.X)) then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

function SegmentIntersectsCircle(StartPoint, EndPoint, Center: TPointF; Radius: Single): Boolean;
var
  DX, DY, T1, T2, CX, CY, Projection, Discriminant, CenterDistanceSquared, SegmentLength: Single;
begin
  if Sqr(StartPoint.X - Center.X) + Sqr(StartPoint.Y - Center.Y) < Radius * Radius then
  begin
    Result := True;
    Exit;
  end;
  DX := EndPoint.X - StartPoint.X;
  DY := EndPoint.Y - StartPoint.Y;
  T1 := Sqrt(DX * DX + DY * DY);
  if T1 = 0 then
  begin
    Result := False;
    Exit;
  end;
  T1 := 1 / T1;
  DX := DX * T1;
  DY := DY * T1;
  CX := Center.X - StartPoint.X;
  CY := Center.Y - StartPoint.Y;
  CenterDistanceSquared := CX * CX + CY * CY;
  Projection := CX * DX + CY * DY;
  Discriminant := Sqr(Radius) - CenterDistanceSquared + Projection * Projection;
  if Discriminant <= 0 then
  begin
    Result := False;
    Exit;
  end;
  Discriminant := Sqrt(Discriminant);
  if Projection < Discriminant then
  begin
    T1 := Projection + Discriminant;
    T2 := Projection - Discriminant;
  end
  else
  begin
    T1 := Projection - Discriminant;
    T2 := Projection + Discriminant;
  end;
  SegmentLength := Sqrt(Sqr(StartPoint.X - EndPoint.X) + Sqr(StartPoint.Y - EndPoint.Y));
  Result := ((T1 >= 0) and (T1 <= SegmentLength)) or ((T2 >= 0) and (T2 <= SegmentLength));
end;

function SegmentCrossesOriginCircle(StartPoint, EndPoint: TPointF; Radius: Single): Boolean;
var
  Delta: TPointF;
  StartDistanceSquared, Projection, LengthSquared, RadiusSquared: Single;
begin
  Result := False;
  RadiusSquared := Radius * Radius;
  StartDistanceSquared := StartPoint.X * StartPoint.X + StartPoint.Y * StartPoint.Y;
  if StartDistanceSquared < RadiusSquared then
    Exit;
  if EndPoint.X * EndPoint.X + EndPoint.Y * EndPoint.Y < RadiusSquared then
    Exit;
  Delta.X := EndPoint.X - StartPoint.X;
  Delta.Y := EndPoint.Y - StartPoint.Y;
  LengthSquared := Delta.X * Delta.X + Delta.Y * Delta.Y;
  if LengthSquared < StartDistanceSquared then
    Exit;
  Projection := (-StartPoint.X * Delta.X - StartPoint.Y * Delta.Y) / Sqrt(LengthSquared);
  if Projection < 0 then
    Result := False
  else
    Result := StartDistanceSquared - Projection * Projection < Radius * Radius;
end;

function RayIntersectsOriginCircle(
    StartPoint, ThroughPoint: TPointF;
    out Intersection: TPointF;
    Radius: Single
): Boolean;
var
  DX, DY, T1, T2, CX, CY, Projection, Discriminant, CenterDistanceSquared: Single;
begin
  DX := ThroughPoint.X - StartPoint.X;
  DY := ThroughPoint.Y - StartPoint.Y;
  T1 := 1 / Sqrt(DX * DX + DY * DY);
  DX := DX * T1;
  DY := DY * T1;
  CX := -StartPoint.X;
  CY := -StartPoint.Y;
  CenterDistanceSquared := CX * CX + CY * CY;
  Projection := CX * DX + CY * DY;
  Discriminant := Sqr(Radius) - CenterDistanceSquared + Projection * Projection;
  if Discriminant <= 0 then
  begin
    Result := False;
    Exit;
  end;
  Discriminant := Sqrt(Discriminant);
  if Projection < Discriminant then
  begin
    T1 := Projection + Discriminant;
    T2 := Projection - Discriminant;
  end
  else
  begin
    T1 := Projection - Discriminant;
    T2 := Projection + Discriminant;
  end;
  if Abs(T1) < 0.001 then
    T1 := T2;
  Intersection.X := DX * T1 + StartPoint.X;
  Intersection.Y := DY * T1 + StartPoint.Y;
  Result := T1 > 0.001;
end;

function CalculateTangentArcOffset(StartPoint, EndPoint: TPointF; Heading, Angle: Double): Double;
var
  Center, Normal, Midpoint: TPointF;
  Radians, Radius, CentralAngle: Double;
begin
  Radians := HeadingDegreesToRadians(Heading);
  Normal.X := Sin(Radians) * 100 + StartPoint.X;
  Normal.Y := StartPoint.Y - Cos(Radians) * 100;
  Normal := RotatePointQuarterTurn(StartPoint, Normal);
  Midpoint.X := (StartPoint.X + EndPoint.X) / 2;
  Midpoint.Y := (StartPoint.Y + EndPoint.Y) / 2;
  if not IntersectLines(
      StartPoint,
      Normal,
      Midpoint,
      RotatePointQuarterTurn(Midpoint, StartPoint),
      Center) then
  begin
    Result := 0;
    Exit;
  end;
  Radius := PointDistance(StartPoint, Center);
  CentralAngle := 180 - (90 - Angle) * 2;
  Result := Sin(HeadingDegreesToRadians(CentralAngle / 2)) * Radius;
end;

procedure CircleTangentPoints(Point: TPointF; Radius: Single; out LeftPoint, RightPoint: TPointF);
var
  Angle, Spread, Distance: Single;
begin
  Distance := Sqrt(Point.X * Point.X + Point.Y * Point.Y);
  Spread := ArcCos(Radius / Distance);
  Angle := ArcTan2(Point.X, -Point.Y);
  LeftPoint.X := Sin(Angle + Spread) * Radius;
  LeftPoint.Y := -Cos(Angle + Spread) * Radius;
  RightPoint.X := Sin(Angle - Spread) * Radius;
  RightPoint.Y := -Cos(Angle - Spread) * Radius;
end;

function PointBehindHeading(Origin: TPointF; Heading, Distance: Double; Seed: Cardinal): TPointF;
begin
  Heading :=
      HeadingDegreesToRadians(WrapHeadingDegrees(Heading + 180 + (Integer(Seed mod 180) - 90)));
  Result.X := Sin(Heading) * Distance + Origin.X;
  Result.Y := Origin.Y - Cos(Heading) * Distance;
end;

function PointDistanceSquared(PointA, PointB: TPointF): Single;
var
  X, Y: Single;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := X * X + Y * Y;
end;

function PointDistance(PointA, PointB: TPointF): Double;
var
  X, Y: Single;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := Sqrt(X * X + Y * Y);
end;

function IntegerPointDistancePlusOne(PointA, PointB: TPoint): Integer;
var
  X, Y: Integer;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := Trunc(Sqrt(X * X + Y * Y) + 1);
end;

function RemapClamped(
    Value: Double;
    InMin: Double;
    InMax: Double;
    OutMin: Double;
    OutMax: Double
): Double;
begin
  if not ((Value > InMin)) then
  begin
    Result := OutMin;
    Exit;
  end
  else if not ((Value < InMax)) then
  begin
    Result := OutMax;
    Exit;
  end
  else
  begin
    Result := ((((Value - InMin) / (InMax - InMin)) * (OutMax - OutMin)) + OutMin);
    Exit;
  end;
end;

function MakeFloatPoint(X, Y: Integer): TPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;

procedure ReplaceTextToken(var Text: WideString; Token, Replacement, ColorTag: WideString);
begin
  if ColorTag <> '' then
    Replacement := ColorTag + Replacement + '</color>';
  Text := ReplaceAllWideString(Text, Token, Replacement);
end;

function ReplaceColoredToken(Text, Token, Replacement, ColorTag: WideString): WideString;
begin
  if ColorTag <> '' then
    Replacement := ColorTag + Replacement + '</color>';
  Result := ReplaceAllWideString(Text, Token, Replacement);
end;

function FormatText1(Text, ColorTag, Token, Replacement: WideString): WideString;
begin
  if ColorTag <> '' then
    Replacement := ColorTag + Replacement + '</color>';
  Result := ReplaceAllWideString(Text, Token, Replacement);
end;

function FormatText2(
    Text,
    ColorTag,
    Token1,
    Replacement1,
    Token2,
    Replacement2: WideString
): WideString;
begin
  if ColorTag <> '' then
  begin
    Replacement1 := ColorTag + Replacement1 + '</color>';
    Replacement2 := ColorTag + Replacement2 + '</color>';
  end;
  Result :=
      ReplaceAllWideString(ReplaceAllWideString(Text, Token1, Replacement1), Token2, Replacement2);
end;

function FormatText3(
    Text,
    ColorTag,
    Token1,
    Replacement1,
    Token2,
    Replacement2,
    Token3,
    Replacement3: WideString
): WideString;
begin
  if ColorTag <> '' then
  begin
    Replacement1 := ColorTag + Replacement1 + '</color>';
    Replacement2 := ColorTag + Replacement2 + '</color>';
    Replacement3 := ColorTag + Replacement3 + '</color>';
  end;
  Result :=
      ReplaceAllWideString(
          ReplaceAllWideString(
              ReplaceAllWideString(Text, Token1, Replacement1),
              Token2,
              Replacement2
          ),
          Token3,
          Replacement3
      );
end;

function WrapTextInColor(Text, ColorTag: WideString): WideString;
begin
  if (ColorTag <> '') and (Text <> '') then
    Result := ColorTag + Text + '</color>'
  else
    Result := Text;
end;

function NormalizeTextHighlightColors(Text: WideString): WideString;
begin
  Result := FormatText1(Text, '', '<color=17,139,255>', '<color=255,240,100>');
  Result := FormatText1(Result, '', '<color=127,127,127>', '<color=255,240,100>');
  Result := FormatText1(Result, '', '<color=191,185,128>', '<color=255,240,100>');
  Result := FormatText1(Result, '', InfoNameColorTag, '<color=255,240,100>');
  Result := FormatText1(Result, '', '<color=39,172,177>', '<color=255,240,100>');
  Result := FormatText1(Result, '', InfoHullSeriesColorTag, '<color=255,240,100>');
end;

function IncrementWrapped(var Value: Integer; Minimum, Maximum: Integer): Integer;
begin
  if Value + 1 > Maximum then
    Value := Minimum
  else
    Inc(Value);
  Result := Value;
end;

function DecrementWrappedValue(Value, Minimum, Maximum: Integer): Integer;
begin
  if Value - 1 < Minimum then
    Value := Maximum
  else
    Dec(Value);
  Result := Value;
end;

end.
