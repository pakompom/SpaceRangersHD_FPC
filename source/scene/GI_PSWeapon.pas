{$EXCESSPRECISION OFF}
unit GI_PSWeapon;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  Types;
type
  TPSWeaponGI = class;
  TPSWeaponGI = class(TObjectGI)
    TargetPoint: TPoint;
    RemainingTicks: Integer;
    LifetimeTicks: Integer;
    procedure SetTargetPoint(Point: TPoint); virtual; abstract;
    procedure Advance(Timer: PCallbackTimerGI; UserData: PtrInt); virtual; abstract;
    function GetElapsedTicks: Integer; virtual;
    constructor Create(Owner: TObjectGI);
    function IsFinished: Boolean;
    function SampleGradientColor(const ColorValues: array of Single; Phase: Single): Cardinal;
  end;
implementation
uses
  Math,
  GR_Main;

constructor TPSWeaponGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  LifetimeTicks := 65;
  RemainingTicks := LifetimeTicks;
end;

function TPSWeaponGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;

function TPSWeaponGI.GetElapsedTicks: Integer;
begin
  Result := LifetimeTicks - RemainingTicks;
end;

function TPSWeaponGI.SampleGradientColor(
    const ColorValues: array of Single;
    Phase: Single
): Cardinal;
var
  Count, Index, NextIndex: Integer;
  Fraction: Single;
begin
  Count := Length(ColorValues) div 3;
  Index := Trunc(Phase);
  Fraction := Phase - Index;
  Index := Index mod Count;
  NextIndex := Index + 1;
  if NextIndex >= Count then
    NextIndex := 0;
  Result :=
      CurrentPixelFormat.PackNormalizedRgb(
          (ColorValues[3 * NextIndex] - ColorValues[3 * Index]) * Fraction + ColorValues[3 * Index],
          (ColorValues[3 * NextIndex + 1] - ColorValues[3 * Index + 1]) * Fraction
              + ColorValues[3 * Index + 1],
          (ColorValues[3 * NextIndex + 2] - ColorValues[3 * Index + 2]) * Fraction
              + ColorValues[3 * Index + 2]
      );
end;

end.
