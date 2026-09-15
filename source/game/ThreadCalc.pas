{$EXCESSPRECISION OFF}
unit ThreadCalc;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Thread;
type
  TThreadCalc = class;
  {$Z4}
  TTurnCalculationJob = (tcjGalaxy = 1, tcjPlayerStar = 2, tcjPreparePlayerStar = 3);
  {$Z4}
  TTurnCalculationPhase = (
      tcpIdle = 0,
      tcpGalaxyRunning = 1,
      tcpGalaxyFinished = 2,
      tcpPlayerStarRunning = 3,
      tcpPlayerStarFinished = 4,
      tcpPlayerStarPreparationRunning = 5,
      tcpPlayerStarPrepared = 6,
      tcpNotStarted = 4294967295
  );
  TThreadCalc = class(TThreadEC)
    Job: TTurnCalculationJob;
    procedure Execute; override;
  end;
var
  AdaptiveBeginCalcNextTurn: Single = 0.5;
  LastGalaxyTurnDuration: Integer;
procedure StartGalaxyTurnCalculation;
procedure StartPlayerStarTurnCalculation;
procedure StartPlayerStarPreparation;
function IsTurnCalculationRunning: Boolean;
procedure WaitForTurnCalculation;
procedure ProcessPlayerStarTurn;
implementation
uses
  GI_MessageLoop,
  aCalc,
  Windows,
  MMSystem,
  SysUtils,
  Math,
  Globals,
  GlobalsV,
  GR_Main,
  aGalaxy,
  aPlayer,
  aShip;
procedure StartGalaxyTurnCalculation;
begin
  TurnCalculationThread.Job := tcjGalaxy;
  TurnCalculationThread.Start;
end;
procedure StartPlayerStarTurnCalculation;
begin
  TurnCalculationThread.Job := tcjPlayerStar;
  TurnCalculationThread.Start;
end;
procedure StartPlayerStarPreparation;
begin
  TurnCalculationThread.Job := tcjPreparePlayerStar;
  TurnCalculationThread.Start;
end;
function IsTurnCalculationRunning: Boolean;
begin
  if TurnCalculationThread = nil then
    Result := False
  else
    Result := TurnCalculationThread.IsRunning;
end;
procedure WaitForTurnCalculation;
begin
  if (TurnCalculationThread <> nil) and TurnCalculationThread.IsRunning then
    TurnCalculationThread.WaitForIdle(INFINITE);
end;
procedure ProcessPlayerStarTurn;
var
  RecordFilm: Boolean;
  Stage: Integer;
begin
  Stage := 0;
  try
    if not PlayerStarDayPrepared then
      PrimaryFilm.Clear;
    Stage := 1;
    RecordFilm :=
        GetPlayer.InNormalSpace
            or ((GetPlayer.Order = soTakeoff)
                and ((GetPlayer.CurrentPlanet <> nil) or (GetPlayer.DockedTo <> nil)))
            or (GetPlayer.InHyperspace and (Cardinal(GetPlayer.OrderStateData and $FFFF) <= 1));
    PlayerStar.NextDay(RecordFilm);
    Stage := 2;
    if Galaxy.StasisModEnabled <> 1 then
      Galaxy.CompleteDay(RecordFilm);
    Stage := 3;
    Galaxy.TransferShipsInTransit;
    Stage := 4;
    PlayerStarDayPrepared := False;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[Ord(CurrentScreenId)]).RequestClose(1);
      ExitScreenLoop := True;
      raise Exception.Create('Error in procedure ThCa label = ' + IntToStr(Stage));
    end;
  end;
end;
procedure TThreadCalc.Execute;
var
  ControlWord: Word;

  StartTick, EndTick: Cardinal;

  FrameMs: Integer;
begin

  // ARM64 threads use the same nontrapping round-to-nearest policy.
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  SetRoundMode(rmNearest);
  if Job = tcjGalaxy then
  begin
    TurnCalculationPhase := tcpGalaxyRunning;
    if Galaxy.StasisModEnabled <> 1 then
      try
        if (GetPlayer <> nil) and GetPlayer.InNormalSpace then
        begin
          StartTick := timeGetTime;
          Galaxy.NextDay;
          EndTick := timeGetTime;
          LastGalaxyTurnDuration := EndTick - StartTick;
          if FilmSpeed = 0 then
            FrameMs := 16
          else if FilmSpeed = 1 then
            FrameMs := 12
          else
            FrameMs := 8;
          AdaptiveBeginCalcNextTurn :=
              Math.Min(
                  0.9,
                  (AdaptiveBeginCalcNextTurn
                          + 1
                          - Math.Min(1, (LastGalaxyTurnDuration + 100) / (200 * FrameMs)))
                      / 2
              );
        end
        else
          Galaxy.NextDay;
        Galaxy.TransferShipsInTransit;
      except
        on E: Exception do
        begin
          AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
          LogExceptionBackTrace;
          AppendLogLineThreadSafe('ThreadCalc exception 1');
          if Galaxy.CurrentTurn < 300 then
            AppendLogLineThreadSafe(
                'Galaxy create exception, seed = ' + IntToStr(Integer(Galaxy.GenerationSeed))
            );
          SetEvent(IdleEvent);
          raise;
        end;
      end;
    TurnCalculationPhase := tcpGalaxyFinished;
  end
  else if Job = tcjPlayerStar then
  begin
    TurnCalculationPhase := tcpPlayerStarRunning;
    try
      ProcessPlayerStarTurn;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
        LogExceptionBackTrace;
        AppendLogLineThreadSafe('ThreadCalc exception 2');
        if Galaxy.CurrentTurn < 300 then
          AppendLogLineThreadSafe(
              'Galaxy create exception, seed = ' + IntToStr(Integer(Galaxy.GenerationSeed))
          );
        SetEvent(IdleEvent);
        raise;
      end;
    end;
    TurnCalculationPhase := tcpPlayerStarFinished;
  end
  else
  begin
    TurnCalculationPhase := tcpPlayerStarPreparationRunning;
    PlayerStarDayPrepared := True;
    try
      PrimaryFilm.Clear;
      if Galaxy.StasisModEnabled <> 1 then
        PlayerStar.PrepareNextDay;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
        LogExceptionBackTrace;
        AppendLogLineThreadSafe('ThreadCalc exception 3');
        if Galaxy.CurrentTurn < 300 then
          AppendLogLineThreadSafe(
              'Galaxy create exception, seed = ' + IntToStr(Integer(Galaxy.GenerationSeed))
          );
        SetEvent(IdleEvent);
        raise;
      end;
    end;
    TurnCalculationPhase := tcpPlayerStarPrepared;
  end;

end;
end.
