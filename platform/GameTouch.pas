unit GameTouch;

{$MODE DELPHI}

interface

uses
  Types,
  GameInput;

type
  TTouchPhase = (tpDown, tpMove, tpUp);
  TTouchGesture = (tgIdle, tgPending, tgDrag, tgPan, tgIgnore);
  TGameTouch = class
  private
    Fingers: array of record
      Device, ID: Int64;
      X, Y: Double;
    end;
    Queue: array of TGameMessage;
    Gesture: TTouchGesture;
    Start, Anchor: TPoint;
    LastX, LastY: Double;
    PinchDistance: Double;
    Pinching: Boolean;
    Button: Cardinal;
    Hover: Boolean;
    LastTap: TPoint;
    LastTapTick: Cardinal;
    LastTapButton: Cardinal;
    procedure Emit(Kind, Keys: Cardinal; X, Y: Integer);
    procedure EmitPan(Kind: Cardinal; DX, DY: Double; Point: TPoint);
    function Center: TPoint;
  public
    procedure Feed(
        Phase: TTouchPhase;
        Device, ID: Int64;
        X, Y, Slop: Double;
        Mode: Integer;
        Tick: Cardinal;
        DoubleClickTime: Cardinal
    );
    procedure Cancel;
    function Poll(out Message: TGameMessage): Boolean;
    function Pending: Boolean;
  end;

implementation

uses
  Math;

procedure TGameTouch.Emit(Kind, Keys: Cardinal; X, Y: Integer);
var
  N: Integer;
begin
  N := Length(Queue);
  SetLength(Queue, N + 1);
  Queue[N].Message := Kind;
  Queue[N].WParam := Keys;
  Queue[N].LParam := PackGamePoint(X, Y);
  Queue[N].Source := gisTouch;
  if Hover then
    Queue[N].Source := gisTouchHover;
end;

procedure TGameTouch.EmitPan(Kind: Cardinal; DX, DY: Double; Point: TPoint);
begin
  Emit(Kind, PackGamePan(DX, DY), Point.X, Point.Y);
end;

function TGameTouch.Center: TPoint;
begin
  Result :=
      Types.Point(
          Round((Fingers[0].X + Fingers[1].X) / 2),
          Round((Fingers[0].Y + Fingers[1].Y) / 2)
      );
end;

procedure TGameTouch.Feed(
    Phase: TTouchPhase;
    Device, ID: Int64;
    X, Y, Slop: Double;
    Mode: Integer;
    Tick: Cardinal;
    DoubleClickTime: Cardinal
);
var
  I, N: Integer;
  Point: TPoint;
  CenterX, CenterY, Distance: Double;
  DownMessage, UpMessage: Cardinal;
begin
  if IsNan(X) or IsNan(Y) or IsInfinite(X) or IsInfinite(Y) then
    Exit;
  I := 0;
  while (I < Length(Fingers)) and ((Fingers[I].ID <> ID) or (Fingers[I].Device <> Device)) do
    Inc(I);
  N := Length(Fingers);
  if Phase = tpDown then
  begin
    if I < N then
      Exit;
    SetLength(Fingers, N + 1);
    Fingers[N].Device := Device;
    Fingers[N].ID := ID;
  end
  else if I = N then
    Exit; // Includes releases following cancellation.
  Fingers[I].X := X;
  Fingers[I].Y := Y;
  Point := Types.Point(Round(X), Round(Y));
  if Phase = tpDown then
  begin
    if N = 0 then
    begin
      Gesture := tgPending;
      Start := Point;
      LastX := X;
      LastY := Y;
      Button := MK_LBUTTON;
      if Mode and 1 <> 0 then
        Button := MK_RBUTTON;
      Hover := Mode and 2 <> 0;
      Emit(WM_MOUSEMOVE, 0, Point.X, Point.Y);
      if not Hover then
        Emit(WM_GAME_TOUCH_BEGIN, Button, Point.X, Point.Y);
    end
    else if (N = 1) and (Gesture in [tgPending, tgDrag]) then
    begin
      Gesture := tgPan;
      LastTapTick := 0;
      Anchor := Center;
      LastX := (Fingers[0].X + Fingers[1].X) / 2;
      LastY := (Fingers[0].Y + Fingers[1].Y) / 2;
      PinchDistance := Hypot(Fingers[0].X - Fingers[1].X, Fingers[0].Y - Fingers[1].Y);
      Pinching := False;
      Emit(WM_GAME_PAN_BEGIN, 0, Anchor.X, Anchor.Y);
    end;
    Exit;
  end;
  if (Gesture = tgPan) and (I < 2) then
  begin
    CenterX := (Fingers[0].X + Fingers[1].X) / 2;
    CenterY := (Fingers[0].Y + Fingers[1].Y) / 2;
    EmitPan(WM_GAME_PAN, LastX - CenterX, LastY - CenterY, Anchor);
    LastX := CenterX;
    LastY := CenterY;
    if Phase = tpMove then
    begin
      Distance := Hypot(Fingers[0].X - Fingers[1].X, Fingers[0].Y - Fingers[1].Y);
      // Ignore contact jitter until the span changes deliberately. Contacts
      // starting together need a usable baseline before any division.
      if (PinchDistance < 2 * Slop) or (Distance < 2 * Slop) then
      begin
        PinchDistance := Distance;
        Pinching := False;
      end
      else if Pinching or (Abs(Distance - PinchDistance) > Slop) then
      begin
        Emit(
            WM_GAME_PINCH,
            Round(EnsureRange(Distance / PinchDistance, 0.01, 100.0) * 65536),
            Round(CenterX),
            Round(CenterY)
        );
        PinchDistance := Distance;
        Pinching := True;
      end;
    end;
  end
  else if I = 0 then
  begin
    if not Hover then
      Emit(WM_GAME_TOUCH_MOVE, Button, Point.X, Point.Y);
    if (Gesture = tgPending) and (Sqr(X - Start.X) + Sqr(Y - Start.Y) > Sqr(Slop)) then
    begin
      Gesture := tgDrag;
      LastTapTick := 0;
      if not Hover then
        Emit(WM_GAME_TOUCH_DRAG_BEGIN, Button, Start.X, Start.Y);
    end;
    if Gesture = tgDrag then
    begin
      if Hover then
        Emit(WM_MOUSEMOVE, 0, Point.X, Point.Y)
      else
        EmitPan(WM_GAME_TOUCH_DRAG_MOVE, LastX - X, LastY - Y, Point);
      LastX := X;
      LastY := Y;
    end
    else if Gesture = tgPending then
      Emit(WM_MOUSEMOVE, 0, Point.X, Point.Y);
  end;
  if Phase <> tpUp then
    Exit;
  if (Gesture = tgPan) and (I < 2) then
    Emit(WM_GAME_PAN_END, 0, Center.X, Center.Y);
  if (I = 0) and not Hover then
    Emit(WM_GAME_TOUCH_END, Button, Point.X, Point.Y);
  if (I = 0) and (Gesture = tgPending) and not Hover then
  begin
    DownMessage := WM_LBUTTONDOWN;
    UpMessage := WM_LBUTTONUP;
    if Button = MK_RBUTTON then
    begin
      DownMessage := WM_RBUTTONDOWN;
      UpMessage := WM_RBUTTONUP;
    end;
    if (LastTapTick <> 0)
        // SDL timestamps are milliseconds modulo 2^32; processing may be delayed.
        and (Cardinal(Tick - LastTapTick) <= DoubleClickTime)
        and (LastTapButton = Button)
        and (Sqr(Point.X - LastTap.X) + Sqr(Point.Y - LastTap.Y) <= Sqr(Slop)) then
    begin
      Inc(DownMessage, 2);
      LastTapTick := 0;
    end
    else
    begin
      LastTap := Point;
      LastTapTick := Tick;
      LastTapButton := Button;
    end;
    Emit(DownMessage, Button, Point.X, Point.Y);
    Emit(UpMessage, 0, Point.X, Point.Y);
  end
  else if (I = 0) and (Gesture = tgDrag) and not Hover then
    Emit(WM_GAME_TOUCH_DRAG_END, Button, Point.X, Point.Y);
  // Never turn the remaining finger of a pan into a click or a fresh drag.
  if (I = 0) or ((Gesture = tgPan) and (I < 2)) then
    Gesture := tgIgnore;
  for N := I to High(Fingers) - 1 do
    Fingers[N] := Fingers[N + 1];
  SetLength(Fingers, Length(Fingers) - 1);
  if Length(Fingers) = 0 then
    Gesture := tgIdle;
end;

procedure TGameTouch.Cancel;
begin
  SetLength(Fingers, 0);
  SetLength(Queue, 0);
  Gesture := tgIdle;
  LastTapTick := 0;
  Pinching := False;
end;

function TGameTouch.Poll(out Message: TGameMessage): Boolean;
var
  I: Integer;
begin
  Result := Length(Queue) <> 0;
  if not Result then
    Exit;
  Message := Queue[0];
  for I := 0 to High(Queue) - 1 do
    Queue[I] := Queue[I + 1];
  SetLength(Queue, Length(Queue) - 1);
end;

function TGameTouch.Pending: Boolean;
begin
  Result := Length(Queue) <> 0;
end;

end.
