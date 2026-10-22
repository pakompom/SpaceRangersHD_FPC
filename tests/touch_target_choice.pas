program touch_target_choice;
{$mode objfpc}
uses Types, GI_LayoutMetrics;

procedure Expect(const Name: String; Actual, Expected: Integer);
begin
  if Actual <> Expected then
  begin
    WriteLn(Name, ': expected ', Expected, ', got ', Actual);
    Halt(1);
  end;
end;

begin
  { A miss beside a single small button reaches it; a farther one does not. }
  Expect('beside', ChooseNearbyTouchTarget(Point(95, 15), [Rect(100, 0, 120, 30)], 12, 6), 0);
  Expect('too far', ChooseNearbyTouchTarget(Point(80, 15), [Rect(100, 0, 120, 30)], 12, 6), -1);
  { Diagonal distance counts, not the larger axis alone. }
  Expect('corner', ChooseNearbyTouchTarget(Point(91, 39), [Rect(100, 0, 120, 30)], 12, 6), -1);
  { Between two neighbours, an almost equal choice is refused. }
  Expect('ambiguous', ChooseNearbyTouchTarget(Point(125, 15), [Rect(100, 0, 120, 30), Rect(130, 0, 150, 30)], 12, 6), -1);
  Expect('clearly nearer', ChooseNearbyTouchTarget(Point(121, 15), [Rect(100, 0, 120, 30), Rect(135, 0, 155, 30)], 12, 6), 0);
  { Empty rectangles never win. }
  Expect('empty', ChooseNearbyTouchTarget(Point(100, 15), [Rect(100, 0, 100, 30)], 12, 6), -1);
  Expect('none', ChooseNearbyTouchTarget(Point(100, 15), [], 12, 6), -1);
  WriteLn('Touch target choice handles reach, ambiguity and empty targets.');
end.
