{$EXCESSPRECISION OFF}
unit ObserverSimulation;
interface
uses
  Classes,
  ObserverCapture;
type
  TObserverWorker = class(TThread)
    Recording: TObserverRecording;
    Failure: string;
    CaptureEnabled: Boolean;
    procedure Execute; override;
  end;
var
  ObserverSimulatedTurns: Integer;
procedure ParkObserverPlayer;
implementation
uses
  SysUtils,
  Math,
  Globals,
  GlobalsV,
  aGalaxy,
  aShip,
  aPlayer,
  aPlanet,
  aRanger,
  ThreadCalc,
  ObserverHooks,
  WorkerErrors;
// CHANGE: ENHANCEMENT - Park the player while the observer advances the simulation.
procedure ParkObserverPlayer;
var
  P: TPlayer;
  I: Integer;
begin
  P := GetPlayer;
  if (P = nil) or (PlayerStar = nil) then
    raise Exception.Create('Observer requires a campaign save with a player.');
  if Galaxy.StasisModEnabled = 1 then
    raise Exception.Create('Disable stasis before starting observer mode.');
  if P.InHyperspace then
    raise Exception.Create('Load a save made in a system or on a planet for observer mode.');
  // This is deliberately a sandbox policy: the player stays docked and the
  // observer never writes a save. No landing/travel actions or quests are run.
  if P.InNormalSpace then
  begin
    if PlayerStar.Planets.Count = 0 then
      raise Exception.Create('Observer needs a planet in the starting system to park the player.');
    P.CurrentPlanet := TPlanet(PlayerStar.Planets[0]);
    P.DockedTo := nil;
  end;
  P.OrderNone(False);
  for I := 1 to P.WeaponCount do
    P.Weapons[I].Target := nil;
  PlayerAutomaticControl := False;
  PendingPlayerFollowTarget := nil;
  PlayerStarDayPrepared := False;
  TurnSaveStep := 0;
end;

procedure TObserverWorker.Execute;
begin
  try
    SetExceptionMask(
        [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
    );
    SetRoundMode(rmNearest);
    if CaptureEnabled then
    begin
      Recording := TObserverRecording.Create;
      ObserverWriting := Recording;
      ObserverStep := CaptureObserverStep;
      ObserverHit := CaptureObserverHit;
    end;
    try
      PruneExpiredPersistentPlayerMessages;
      // Parked player: same two ordinary jobs as the docked turn controller.
      GetPlayer.OrderNone(False);
      StartPlayerStarTurnCalculation;
      WaitForTurnCalculation;
      RaisePendingWorkerError;
      if GetPlayer = nil then
        raise Exception.Create('The player no longer exists.');
      StartGalaxyTurnCalculation;
      WaitForTurnCalculation;
      RaisePendingWorkerError;
      if Recording <> nil then
        Recording.CaptureTransits(False);
      Inc(ObserverSimulatedTurns);
    finally
      ObserverStep := nil;
      ObserverHit := nil;
      ObserverWriting := nil;
    end;
  except
    on E: Exception do
      Failure := E.ClassName + ': ' + E.Message
  end;
end;

end.
