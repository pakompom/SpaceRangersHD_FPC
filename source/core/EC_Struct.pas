{$EXCESSPRECISION OFF}
unit EC_Struct;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types;
type
  TObjectEx = class;
  PointerToTPointF = ^TPointF;
  TPointF = Types.TPointF;
  PPointF = PointerToTPointF;
  TVector3D = record
    X: Double;
    Y: Double;
    Z: Double;
  end;
  TObjectEx = class(TObject)
    constructor Create;
    destructor Destroy; override;
  end;
var
  StartupCleanupObject: TObject;
function MakePointF(X: Single; Y: Single): TPointF;
function MakeVector3D(X: Double; Y: Double; Z: Double): TVector3D;
function TruncatePointF(Point: TPointF): TPoint;
function RoundPointF(Point: TPointF): TPoint;
function PointToPointF(Point: TPoint): TPointF;
function HalfPoint(Point: TPoint): TPoint;
function AddPoints(Left: TPoint; Right: TPoint): TPoint;
function SubtractPoints(Left: TPoint; Right: TPoint): TPoint;
function HalfPointF(Point: TPointF): TPointF;
function AddPointsF(Left: TPointF; Right: TPointF): TPointF;
function SubtractPointsF(Left: TPointF; Right: TPointF): TPointF;
function IntersectRects(
    out Intersection: TRect;
    constref First: TRect;
    constref Second: TRect
): Boolean;
implementation
uses
  Math;

function MakePointF(X, Y: Single): TPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;

function MakeVector3D(X, Y, Z: Double): TVector3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function TruncatePointF(Point: TPointF): TPoint;
begin
  Result.X := Trunc(Point.X);
  Result.Y := Trunc(Point.Y);
end;

function RoundPointF(Point: TPointF): TPoint;
begin
  Result.X := Round(Point.X);
  Result.Y := Round(Point.Y);
end;

function PointToPointF(Point: TPoint): TPointF;
begin
  Result.X := Point.X;
  Result.Y := Point.Y;
end;

function HalfPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X div 2;
  Result.Y := Point.Y div 2;
end;

function AddPoints(Left, Right: TPoint): TPoint;
begin
  Result.X := Left.X + Right.X;
  Result.Y := Left.Y + Right.Y;
end;

function SubtractPoints(Left, Right: TPoint): TPoint;
begin
  Result.X := Left.X - Right.X;
  Result.Y := Left.Y - Right.Y;
end;

function HalfPointF(Point: TPointF): TPointF;
begin
  Result.X := Point.X / 2;
  Result.Y := Point.Y / 2;
end;

function AddPointsF(Left, Right: TPointF): TPointF;
begin
  Result.X := Left.X + Right.X;
  Result.Y := Left.Y + Right.Y;
end;

function SubtractPointsF(Left, Right: TPointF): TPointF;
begin
  Result.X := Left.X - Right.X;
  Result.Y := Left.Y - Right.Y;
end;

function IntersectRects(out Intersection: TRect; constref First, Second: TRect): Boolean;
var
  R: TRect;
begin
  R.Left := Max(First.Left, Second.Left);
  R.Top := Max(First.Top, Second.Top);
  R.Right := Min(First.Right, Second.Right);
  R.Bottom := Min(First.Bottom, Second.Bottom);
  Result := (R.Left < R.Right) and (R.Top < R.Bottom);
  if Result then
    Intersection := R;
end;

constructor TObjectEx.Create;
begin
  inherited Create;
end;

destructor TObjectEx.Destroy;
begin
  inherited Destroy;
end;

end.
