unit GI_LayoutMetrics;

{$I GameOptions.inc}

interface

uses
  Types;

type
  TMobileCharacterMetrics = record
    Width, Height: Integer;
    Scale: Single;
  end;

  TDialogueExpansion = record
    Text, Choices: Integer;
  end;

  TShopExpansion = record
    Width, Columns: Integer;
  end;

// These measurements are shared by the controls and their generated artwork.
function MeasureDialogueExpansion(ContentHeight: Integer): TDialogueExpansion;
function MeasureShopExpansion(LayoutWidth: Integer): TShopExpansion;
function MeasureMobileCharacter(ScreenWidth, ScreenHeight: Integer): TMobileCharacterMetrics;
// Index of the target nearest to Point, within Reach of its edges. Returns -1
// when none qualifies or a different target is not at least Margin farther.
function ChooseNearbyTouchTarget(const Point: TPoint; const Targets: array of TRect; Reach, Margin: Single): Integer;

implementation

uses
  Math;

function MeasureMobileCharacter(ScreenWidth, ScreenHeight: Integer): TMobileCharacterMetrics;
begin
  // Fill the screen down to the 720 x 356 design minimum. A tablet's dp is
  // physically large, so a dp-based scale left most of its screen empty.
  Result.Scale := Min((ScreenWidth - 16) / 720, (ScreenHeight - 16) / 356);
  Result.Width := Floor((ScreenWidth - 16) / Result.Scale + 0.0001);
  Result.Height := Floor((ScreenHeight - 16) / Result.Scale + 0.0001);
end;

function ChooseNearbyTouchTarget(const Point: TPoint; const Targets: array of TRect; Reach, Margin: Single): Integer;
var
  I: Integer;
  Distance, Best, Second: Single;
begin
  Result := -1;
  Best := MaxSingle;
  Second := MaxSingle;
  for I := 0 to High(Targets) do
    with Targets[I] do
    begin
      if (Right <= Left) or (Bottom <= Top) then
        Continue;
      Distance := Hypot(Max(Max(Left - Point.X, Point.X - (Right - 1)), 0), Max(Max(Top - Point.Y, Point.Y - (Bottom - 1)), 0));
      if Distance < Best then
      begin
        Second := Best;
        Best := Distance;
        Result := I;
      end
      else if Distance < Second then
        Second := Distance;
    end;
  if (Result >= 0) and ((Best > Reach) or (Second - Best < Margin)) then
    Result := -1;
end;

function MeasureDialogueExpansion(ContentHeight: Integer): TDialogueExpansion;
var
  Rows: Integer;
begin
  // The original desktop skin can repeat its middle strips, but its fixed
  // corners and separators cannot shrink. Mobile uses a separate composition.
  Rows := EnsureRange(ContentHeight - 768, 0, 250) div 3;
  Result.Choices := Rows div 4 * 3;
  Result.Text := Rows * 3 - Result.Choices;
end;

function MeasureShopExpansion(LayoutWidth: Integer): TShopExpansion;
begin
  Result.Width := Min(Max(0, LayoutWidth - 1024) div 198 * 198, 198);
  Result.Columns := 6 + Result.Width div 99;
end;

end.
