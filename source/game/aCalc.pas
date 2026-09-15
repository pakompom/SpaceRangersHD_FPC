{$EXCESSPRECISION OFF}
unit aCalc;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  ThreadCalc;
var
  TurnCalculationPhase: TTurnCalculationPhase;
procedure WaitForTurnCalculationUI;
function IsTurnCalculationRunningUI: Boolean;
procedure CalculateGalaxyTurnAndWait;
procedure QueueGalaxyTurnCalculation;
procedure CalculatePlayerStarTurnAndWait;
procedure QueuePlayerStarTurnCalculation;
procedure QueuePlayerStarPreparation;
implementation
procedure WaitForTurnCalculationUI;
begin
  WaitForTurnCalculation;
end;
function IsTurnCalculationRunningUI: Boolean;
begin
  Result := IsTurnCalculationRunning;
end;
procedure CalculateGalaxyTurnAndWait;
begin
  StartGalaxyTurnCalculation;
  WaitForTurnCalculation;
end;
procedure QueueGalaxyTurnCalculation;
begin
  StartGalaxyTurnCalculation;
end;
procedure CalculatePlayerStarTurnAndWait;
begin
  StartPlayerStarTurnCalculation;
  WaitForTurnCalculation;
end;
procedure QueuePlayerStarTurnCalculation;
begin
  StartPlayerStarTurnCalculation;
end;
procedure QueuePlayerStarPreparation;
begin
  StartPlayerStarPreparation;
end;
end.
