unit ThreadCalc;

{$I GameOptions.inc}

interface

uses
  GameEvents,
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
  aCalc,
  Types,
  GameSystem,
  SysUtils,
  Math,
  Globals,
  GlobalsV,
  GR_Main,
  aGalaxy,
  aPlayer,
  aShip,
  aGalaxyStruct;

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
  // Screen close handlers can wait before the top-level shutdown runs. Once
  // the UI loop is exiting, release any conversation the worker is waiting on.
  if ExitScreenLoop then
    TurnCalculationThread.RequestStop;
  if TurnCalculationThread.IsRunning then
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
      E.Message := 'Player-star turn failed, stage = ' + IntToStr(Stage) + ': ' + E.Message;
      raise;
    end;
  end;
end;

procedure TThreadCalc.Execute;
var
  StartTick, EndTick: Cardinal;
  FrameMs: Integer;
  FailureContext: string;
begin
  try
    if IsStopRequested then
      Exit;
    // $133F and $FCFF selects nearest rounding, single x87 precision and masked exceptions.
    // Fixed-precision CPUs retain their native precision through FPC.
    ClearExceptions(False);
    SetExceptionMask(
        [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
    );
    SetRoundMode(rmNearest);
    SetPrecisionMode(pmSingle);
    if Job = tcjGalaxy then
    begin
      TurnCalculationPhase := tcpGalaxyRunning;
      if Galaxy.StasisModEnabled <> 1 then
      begin
        if (GetPlayer <> nil) and GetPlayer.InNormalSpace then
        begin
          StartTick := GameTickCount;
          Galaxy.NextDay;
          EndTick := GameTickCount;
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
                          - Math.Min(
                              1,
                              (LastGalaxyTurnDuration + 100)
                                  / (BaseMovementStepsPerTurn * FrameMs)))
                      / 2
              );
        end
        else
          Galaxy.NextDay;
        Galaxy.TransferShipsInTransit;
      end;
      TurnCalculationPhase := tcpGalaxyFinished;
    end
    else if Job = tcjPlayerStar then
    begin
      TurnCalculationPhase := tcpPlayerStarRunning;
      ProcessPlayerStarTurn;
      TurnCalculationPhase := tcpPlayerStarFinished;
    end
    else
    begin
      TurnCalculationPhase := tcpPlayerStarPreparationRunning;
      PlayerStarDayPrepared := True;
      PrimaryFilm.Clear;
      if Galaxy.StasisModEnabled <> 1 then
        PlayerStar.PrepareNextDay;
      TurnCalculationPhase := tcpPlayerStarPrepared;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      FailureContext := 'Turn calculation failed, job = ' + IntToStr(Ord(Job));
      if Galaxy <> nil then
        FailureContext :=
            FailureContext
                + ', seed = '
                + IntToStr(Integer(Galaxy.GenerationSeed))
                + ', turn = '
                + IntToStr(Galaxy.CurrentTurn);
      E.Message := FailureContext + ': ' + E.Message;
      raise;
    end;
  end;
end;

end.
