{$EXCESSPRECISION OFF}
unit fCount1;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  Types,
  GI_MessageLoop;
type
  TfCount1 = class;
  TfCount1 = class(TMessageLoopGI)
    ImagePath: WideString;
    KindImagePath: WideString;
    Caption: WideString;
    Minimum: Integer;
    Maximum: Integer;
    Limit: Integer;
    Value: Integer;
    Items: TList;
    Dragging: Boolean;
    GapF1: array[0..2] of Byte;
    RepeatTimer: PCallbackTimerGI;
    RepeatCount: Cardinal;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure ProcessCallbackTimers; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    procedure RefreshValue;
    procedure AddPressed(Sender: TObjectGI);
    procedure SubPressed(Sender: TObjectGI);
    procedure AddReleased(Sender: TObjectGI);
    procedure SubReleased(Sender: TObjectGI);
    procedure RepeatChange(Timer: PCallbackTimerGI; Data: PtrInt);
    procedure MaxClicked(Sender: TObjectGI);
    procedure AcceptClicked(Sender: TObjectGI);
    procedure CancelClicked(Sender: TObjectGI);
    procedure BarMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
function ShowNumberDialog(
    Parent: TMessageLoopGI;
    const ImagePath: WideString;
    const KindImagePath: WideString;
    const Caption: WideString;
    Minimum: Integer;
    Maximum: Integer;
    Limit: Integer;
    Items: TList;
    var Value: Integer
): Cardinal;
procedure LinkRecoveredTypes;
implementation
uses
  GI_Main,
  Math,
  SysUtils,
  Windows,
  GR_Main,
  Globals,
  GlobalsV,
  GI_GraphBuf,
  GI_Image,
  GI_Label,
  GI_GraphButton;

constructor TfCount1.Create;
begin
  inherited;
end;

destructor TfCount1.Destroy;
begin
  inherited;
end;

procedure TfCount1.InitializeLayout;
begin
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('Ok').Parent do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
  end;
end;

procedure TfCount1.OnOpen;
begin
  Dragging := False;
  with GetByName('ItemImage') as TImageGI do
  begin
    SetImagePath(Self.ImagePath);
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetActive(True);
  end;
  (GetByName('Caption') as TLabelGI).SetText(Caption);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  with GetByName('Add') as TGraphButtonGI do
  begin
    DownCallback := AddPressed;
    UpCallback := AddReleased;
  end;
  with GetByName('Sub') as TGraphButtonGI do
  begin
    DownCallback := SubPressed;
    UpCallback := SubReleased;
  end;
  (GetByName('Max') as TGraphButtonGI).UpCallback := MaxClicked;
  (GetByName('Ok') as TGraphButtonGI).UpCallback := AcceptClicked;
  (GetByName('Close') as TGraphButtonGI).UpCallback := CancelClicked;
  GetByName('PanelBar').LeftButtonDownCallback := BarMouseDown;
  with GetByName('MainPanel') do
  begin
    MouseMoveCallback := MainMouseMove;
    LeftButtonUpCallback := MainMouseUp;
    KeyDownCallback := MainKeyDown;
  end;
  if KindImagePath <> '' then
  begin
    with GetByName('Kind0') as TImageGI do
    begin
      SetImagePath(KindImagePath);
      SetActive(True);
    end;
    GetByName('Count').SetActive(True);
    GetByName('Kind1').SetActive(False);
    GetByName('Count2').SetActive(False);
  end
  else
  begin
    GetByName('Kind1').SetActive(True);
    GetByName('Count2').SetActive(True);
    GetByName('Count').SetActive(False);
    GetByName('Kind0').SetActive(False);
  end;
  RefreshValue;
end;

procedure TfCount1.OnClose;
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount1.RefreshValue;
var
  Width, Position: Integer;
begin
  Width := GetByName('BarRange').ClientSize.X + 2;
  if Maximum - Minimum <= 0 then
    Position := Width - 1
  else
    Position := Round((Value - Minimum) / (Maximum - Minimum) * (Width - 1));
  with GetByName('Bar') do
    SetPosition(Classes.Point(Position - 1 - ClientSize.X div 2, 0));
  with GetByName('BarArrow') do
    SetPosition(Classes.Point(Position + 3, 0));
  (GetByName('Ok') as TGraphButtonGI).SetDisabled(Value > Limit);
  if Value <= Limit then
  begin
    (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
    (GetByName('Count2') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
  end
  else
  begin
    (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
    (GetByName('Count2') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
  end;
  if Items <> nil then
  begin
    (GetByName('Count') as TLabelGI).SetText(PWideString(Items[Value - Minimum])^);
    (GetByName('Count2') as TLabelGI).SetText(PWideString(Items[Value - Minimum])^);
  end
  else
  begin
    (GetByName('Count') as TLabelGI).SetText(IntToStr(Value));
    (GetByName('Count2') as TLabelGI).SetText(IntToStr(Value));
  end;
  (GetByName('Add') as TGraphButtonGI).SetDisabled(Value = Maximum);
  (GetByName('Sub') as TGraphButtonGI).SetDisabled(Value = Minimum);
  (GetByName('Max') as TGraphButtonGI).SetDisabled(Value = Min(Limit, Maximum));
end;

procedure TfCount1.AddPressed(Sender: TObjectGI);
begin
  if not Dragging then
  begin
    if Value < Maximum then
      Inc(Value);
    RefreshValue;
    if RepeatTimer <> nil then
    begin
      CancelCallbackTimer(RepeatTimer);
      RepeatTimer := nil;
    end;
    RepeatTimer := ScheduleCallbackTimer(300, 50, RepeatChange, 1);
    RepeatCount := 0;
  end;
end;

procedure TfCount1.SubPressed(Sender: TObjectGI);
begin
  if not Dragging then
  begin
    if Value > Minimum then
      Dec(Value);
    RefreshValue;
    if RepeatTimer <> nil then
    begin
      CancelCallbackTimer(RepeatTimer);
      RepeatTimer := nil;
    end;
    RepeatTimer := ScheduleCallbackTimer(300, 50, RepeatChange);
    RepeatCount := 0;
  end;
end;

procedure TfCount1.AddReleased(Sender: TObjectGI);
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount1.SubReleased(Sender: TObjectGI);
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount1.RepeatChange(Timer: PCallbackTimerGI; Data: PtrInt);
var
  Step: Cardinal;
begin
  Step := Round(Exp(RepeatCount * 0.1));
  if Cardinal(Maximum - Minimum) div 10 < Step then
    Step := (Maximum - Minimum) div 10
  else
    Inc(RepeatCount);
  Step := Max(1, Step);
  if Cardinal(Data) > 0 then
    Inc(Value, Min(Maximum - Value, Step))
  else
    Dec(Value, Min(Value - Minimum, Step));
  RefreshValue;
end;

procedure TfCount1.MaxClicked(Sender: TObjectGI);
begin
  Value := Min(Limit, Maximum);
  RefreshValue;
end;

procedure TfCount1.AcceptClicked(Sender: TObjectGI);
begin
  if ExitCode = 0 then
    RequestClose(1)
  else
    RequestClose(ExitCode);
end;

procedure TfCount1.CancelClicked(Sender: TObjectGI);
begin
  if ExitCode = 0 then
    RequestClose(2)
  else
    RequestClose(ExitCode);
end;

procedure TfCount1.BarMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  Dragging := True;
  MainMouseMove(Sender, KeyState, Point);
end;

procedure TfCount1.MainMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  Dragging := False;
end;

procedure TfCount1.MainMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  X, Width: Integer;
begin
  if Dragging then
  begin
    X := GetByName('BarRange').ToLocalPoint(GetCursorPoint).X;
    Width := GetByName('BarRange').ClientSize.X + 2;
    Value := Round(Min(1.0, Max(0.0, (X - 1) / (Width - 1))) * (Maximum - Minimum) + Minimum);
    if Value < Minimum then
      Value := Minimum
    else if Value > Maximum then
      Value := Maximum;
    RefreshValue;
  end;
end;

procedure TfCount1.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = -WHEEL_DELTA then
  begin
    if Value < Maximum then
      Inc(Value);
    RefreshValue;
  end
  else if Delta = WHEEL_DELTA then
  begin
    if Value > Minimum then
      Dec(Value);
    RefreshValue;
  end;
end;

procedure TfCount1.ProcessCallbackTimers;
begin
  inherited;
  if ParentLoop.ExitCode <> 0 then
    if ExitCode = 0 then
      RequestClose(255);
end;

procedure TfCount1.MainKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_LEFT then
  begin
    if Value > Minimum then
      Dec(Value);
    RefreshValue;
  end
  else if Key = VK_RIGHT then
  begin
    if Value < Maximum then
      Inc(Value);
    RefreshValue;
  end
  else if Key = VK_HOME then
  begin
    Value := Minimum;
    RefreshValue;
  end
  else if Key = VK_END then
  begin
    Value := Maximum;
    RefreshValue;
  end
  else if Key = VK_ESCAPE then
    CancelClicked(nil)
  else if (Key = VK_RETURN) and (Value <= Limit) then
    AcceptClicked(nil);
end;

function ShowNumberDialog(
    Parent: TMessageLoopGI;
    const ImagePath, KindImagePath, Caption: WideString;
    Minimum, Maximum, Limit: Integer;
    Items: TList;
    var Value: Integer
): Cardinal;
var
  Dialog: TfCount1;
  State: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  CaptureScreenBackground(False, 0);
  Dialog := TfCount1.Create;
  Dialog.ParentLoop := Parent;
  Parent.ChildLoop := Dialog;
  Dialog.InitializeFromConfig(UiStyleConfig, 'Number', True);
  Dialog.InitializeLayout;
  try
    Dialog.ImagePath := ImagePath;
    Dialog.KindImagePath := KindImagePath;
    Dialog.Caption := Caption;
    Dialog.Minimum := Minimum;
    Dialog.Maximum := Maximum;
    Dialog.Limit := Limit;
    Dialog.Value := Value;
    Dialog.Items := Items;
    Result := Dialog.Run;
    Value := Dialog.Value;
    Parent.InvalidateViewport;
  finally
    Parent.ChildLoop := nil;
    Dialog.Free;
  end;
  Parent.RestoreCursorState(@State);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
end;

procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
end;
end.
