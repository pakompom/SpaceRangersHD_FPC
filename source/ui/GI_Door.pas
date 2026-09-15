{$EXCESSPRECISION OFF}
unit GI_Door;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_GAI,
  GI_MessageLoop,
  Types;
type
  TDoorGI = class;
  TDoorGI = class(TObjectGI)
    Image: TgaiGI;
    FrameStep: Integer;
    StepTimer: PCallbackTimerGI;
    StepTime: PtrInt;
    ClickCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetStepTime(Value: Integer);
    procedure StartStepTimer;
    procedure StopStepTimer;
    procedure StepFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure LoadDoorProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GR_Main,
  SysUtils,
  GI_Main;

constructor TDoorGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Image := TgaiGI.Create(Self);
end;

destructor TDoorGI.Destroy;
begin
  StopStepTimer;
  Image.Free;
  Image := nil;
  inherited Destroy;
end;

procedure TDoorGI.Clear;
begin
end;

procedure TDoorGI.SetStepTime(Value: Integer);
begin
  if StepTime <> Value then
  begin
    StepTime := Value;
    if FrameStep <> 0 then
      StartStepTimer;
  end;
end;

procedure TDoorGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  Image.SetSize(Size);
end;

procedure TDoorGI.StartStepTimer;
begin
  if FrameStep <> 0 then
  begin
    StopStepTimer;
    StepTimer := MessageLoop.ScheduleCallbackTimer(StepTime, StepTime, StepFrame);
  end;
end;

procedure TDoorGI.StopStepTimer;
begin
  if StepTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(StepTimer);
    StepTimer := nil;
  end;
end;

procedure TDoorGI.StepFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Frame: Integer;
begin
  Frame := Image.SequenceFrame + FrameStep;
  if Frame <= 0 then
  begin
    Image.SetSequenceFrame(0);
    StopStepTimer;
    FrameStep := 0;
  end
  else if Frame >= Image.SequenceFrameCount - 1 then
  begin
    Image.SetSequenceFrame(Image.SequenceFrameCount - 1);
    StopStepTimer;
    FrameStep := 0;
  end
  else
    Image.SetSequenceFrame(Frame);
end;

procedure TDoorGI.OnActivate;
begin
  inherited OnActivate;
  Image.SetSequenceFrame(0);
  StopStepTimer;
end;

procedure TDoorGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Image.SetSequenceFrame(0);
  StopStepTimer;
end;

procedure TDoorGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
  begin
    FrameStep := 1;
    StartStepTimer;
  end;
end;

procedure TDoorGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
  begin
    FrameStep := -1;
    StartStepTimer;
  end;
end;

procedure TDoorGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessMouseMove(KeyState, Point);
  if IsOccludedAtPoint(Point) then
  begin
    FrameStep := -1;
    if StepTimer = nil then
      StartStepTimer;
  end
  else
  begin
    FrameStep := 1;
    if StepTimer = nil then
      StartStepTimer;
  end;
end;

procedure TDoorGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
    if Assigned(ClickCallback) then
      ClickCallback(Self);
end;

procedure TDoorGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadDoorProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TDoorGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadDoorProperties(Block);
end;

procedure TDoorGI.LoadDoorProperties(Block: TBlockParEC);
begin
  FrameStep := 0;
  if Block.CountParams('StepTime') > 0 then
    SetStepTime(StrToInt(Block.GetParam('StepTime')));
  if Block.CountParams('Image') > 0 then
  begin
    Image.SetImagePath(Block.GetParam('Image'));
    Image.SequenceIndex := 0;
    Image.UpdateAutoGeometry;
  end;
end;

end.
