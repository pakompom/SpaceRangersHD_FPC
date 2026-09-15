{$EXCESSPRECISION OFF}
unit ObserverDrawing;

// Small screen-space shapes with a transparent fringe, independent of zoom.
interface
uses
  EC_Struct;
procedure ObserverLine(X1, Y1, X2, Y2, Width: Double; Color: Cardinal; Alpha: Integer);
procedure ObserverRing(X, Y, Radius: Double; Color: Cardinal; Alpha: Integer);
procedure ObserverBox(L, T, R, B: Double; Color: Cardinal; Alpha: Integer);
procedure ObserverIcon(X, Y, Size, Heading: Double; Kind: Integer; Color: Cardinal; Alpha: Integer);
function ObserverOwnerColor(Owner: Integer): Cardinal;
function ObserverFactionColor(Faction: Integer): Cardinal;
implementation
uses
  Math,
  GR_DX,
  GameNative;
function ObserverOwnerColor(Owner: Integer): Cardinal;
begin
  case Owner and $7F of
    0: Result := $8AC7EB;
    1: Result := $B9DAB6;
    2: Result := $EBC687;
    3: Result := $E7DA84;
    4: Result := $C7B3EF;
    5: Result := $F18B77;
    6: Result := $7BDCC8;
    7: Result := $E5AB6C;
  else
    Result := $B2CFDC
  end;
end;
function ObserverFactionColor(Faction: Integer): Cardinal;
begin
  case Faction of
    1: Result := $F18B77;
    2: Result := $E5AB6C;
  else
    Result := $8AC7EB
  end;
end;
procedure ObserverBox(L, T, R, B: Double; Color: Cardinal; Alpha: Integer);
var
  V: array[0..3] of TScreenVertexGR;
  I: Integer;
begin
  FillChar(V, SizeOf(V), 0);
  V[0].X := L;
  V[0].Y := T;
  V[1].X := R;
  V[1].Y := T;
  V[2].X := R;
  V[2].Y := B;
  V[3].X := L;
  V[3].Y := B;
  for I := 0 to 3 do
  begin
    V[I].X := V[I].X - 0.5;
    V[I].Y := V[I].Y - 0.5;
    V[I].Z := 1;
    V[I].RHW := 1;
    V[I].Color := Color or (Cardinal(Alpha) shl 24)
  end;
  sr_gpu_draw(nil, 6, 2, @V, SizeOf(TScreenVertexGR), 0, 0);
end;
procedure ObserverLine(X1, Y1, X2, Y2, Width: Double; Color: Cardinal; Alpha: Integer);
var
  V: array[0..17] of TScreenVertexGR;
  NX, NY, D: Double;
  N: Integer;
  procedure Vertex(I: Integer; X, Y: Double; A: Integer);
  begin
    V[I].X := X - 0.5;
    V[I].Y := Y - 0.5;
    V[I].Z := 1;
    V[I].RHW := 1;
    V[I].Color := Color or (Cardinal(A) shl 24)
  end;
  procedure Strip(L, R: Double; A, B: Integer);
  begin
    Vertex(N, X1 + NX * L, Y1 + NY * L, A);
    Vertex(N + 1, X2 + NX * L, Y2 + NY * L, A);
    Vertex(N + 2, X2 + NX * R, Y2 + NY * R, B);
    V[N + 3] := V[N];
    V[N + 4] := V[N + 2];
    Vertex(N + 5, X1 + NX * R, Y1 + NY * R, B);
    Inc(N, 6);
  end;
begin
  D := Hypot(X2 - X1, Y2 - Y1);
  if D < 0.001 then
    Exit;
  NX := -(Y2 - Y1) / D;
  NY := (X2 - X1) / D;
  N := 0;
  FillChar(V, SizeOf(V), 0);
  Strip(-Width / 2 - 0.8, -Width / 2, 0, Alpha);
  Strip(-Width / 2, Width / 2, Alpha, Alpha);
  Strip(Width / 2, Width / 2 + 0.8, Alpha, 0);
  sr_gpu_draw(nil, 4, 6, @V, SizeOf(TScreenVertexGR), 0, 0);
end;
procedure ObserverRing(X, Y, Radius: Double; Color: Cardinal; Alpha: Integer);
var
  V: array[0..4607] of TScreenVertexGR;
  I, N, K: Integer;
  A, B, CA, SA, CB, SB: Double;
  procedure Vertex(Index: Integer; R, C, S: Double; Opacity: Integer);
  begin
    V[Index].X := X + C * R - 0.5;
    V[Index].Y := Y + S * R - 0.5;
    V[Index].Z := 1;
    V[Index].RHW := 1;
    V[Index].Color := Color or (Cardinal(Opacity) shl 24)
  end;
  procedure Strip(R1, R2: Double; Alpha1, Alpha2: Integer);
  begin
    Vertex(K, R1, CA, SA, Alpha1);
    Vertex(K + 1, R1, CB, SB, Alpha1);
    Vertex(K + 2, R2, CB, SB, Alpha2);
    V[K + 3] := V[K];
    V[K + 4] := V[K + 2];
    Vertex(K + 5, R2, CA, SA, Alpha2);
    Inc(K, 6);
  end;
begin
  if (Radius < 1) or (Alpha <= 0) then
    Exit;
  N := EnsureRange(Ceil(Radius * 0.45), 24, 256);
  K := 0;
  FillChar(V, N * 18 * SizeOf(TScreenVertexGR), 0);
  for I := 0 to N - 1 do
  begin
    A := I * 2 * Pi / N;
    B := (I + 1) * 2 * Pi / N;
    CA := Cos(A);
    SA := Sin(A);
    CB := Cos(B);
    SB := Sin(B);
    Strip(Radius - 1.0, Radius - 0.2, 0, Alpha);
    Strip(Radius - 0.2, Radius + 0.2, Alpha, Alpha);
    Strip(Radius + 0.2, Radius + 1.0, Alpha, 0);
  end;
  sr_gpu_draw(nil, 4, N * 6, @V, SizeOf(TScreenVertexGR), 0, 0);
end;
procedure ObserverIcon(X, Y, Size, Heading: Double; Kind: Integer; Color: Cardinal; Alpha: Integer);
var
  C, S: Double;
  procedure Edge(X1, Y1, X2, Y2: Double);
  begin
    ObserverLine(
        X + (X1 * C - Y1 * S) * Size,
        Y + (X1 * S + Y1 * C) * Size,
        X + (X2 * C - Y2 * S) * Size,
        Y + (X2 * S + Y2 * C) * Size,
        0.8,
        Color,
        Alpha
    )
  end;
begin
  C := Cos(Heading);
  S := Sin(Heading);
  case Kind of
    2, 4:
    begin
      Edge(0, -1, -0.65, 0.65);
      Edge(-0.65, 0.65, 0, 0.3);
      Edge(0, 0.3, 0.65, 0.65);
      Edge(0.65, 0.65, 0, -1)
    end;
    3:
    begin
      Edge(-0.8, -0.3, -0.3, -0.8);
      Edge(-0.3, -0.8, 0.65, -0.4);
      Edge(0.65, -0.4, 0.7, 0.5);
      Edge(0.7, 0.5, -0.3, 0.75);
      Edge(-0.3, 0.75, -0.8, -0.3)
    end;
    5:
    begin
      Edge(0, -1, 0.8, 0);
      Edge(0.8, 0, 0, 1);
      Edge(0, 1, -0.8, 0);
      Edge(-0.8, 0, 0, -1)
    end;
  else
    ObserverRing(X, Y, Size, Color, Alpha)
  end;
end;
end.
