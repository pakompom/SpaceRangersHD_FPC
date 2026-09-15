{$EXCESSPRECISION OFF}
unit fCount2;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  Types;
type
  TfCount2 = class;
  TfCount2 = class(TMessageLoopGI)
    ImagePath: WideString;
    PreviewImagePath: WideString;
    Description: WideString;
    Minimum: Integer;
    Maximum: Integer;
    Limit: Integer;
    Value: Integer;
    UnitValue: Single;
    Available: Integer;
    TotalLimit: Integer;
    Dragging: Boolean;
    GapF9: array[0..2] of Byte;
    RepeatTimer: PCallbackTimerGI;
    FontName: WideString;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure ProcessCallbackTimers; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    procedure RefreshValue;
    procedure IncreaseMouseDown(Sender: TObjectGI);
    procedure DecreaseMouseDown(Sender: TObjectGI);
    procedure IncreaseMouseUp(Sender: TObjectGI);
    procedure DecreaseMouseUp(Sender: TObjectGI);
    procedure RepeatChange(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure MaximumClicked(Sender: TObjectGI);
    procedure AcceptClicked(Sender: TObjectGI);
    procedure CancelClicked(Sender: TObjectGI);
    procedure SliderMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SliderMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SliderMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
function ShowCountDialogWithFont(
    Parent: TMessageLoopGI;
    const ImagePath: WideString;
    const Description: WideString;
    Minimum: Integer;
    Maximum: Integer;
    Limit: Integer;
    UnitValue: Single;
    Available: Integer;
    TotalLimit: Integer;
    var Value: Integer;
    PreviewImagePath: WideString;
    FontName: WideString
): Cardinal;
function ShowCountDialog(
    Parent: TMessageLoopGI;
    const ImagePath: WideString;
    const Description: WideString;
    Minimum: Integer;
    Maximum: Integer;
    Limit: Integer;
    UnitValue: Single;
    Available: Integer;
    TotalLimit: Integer;
    var Value: Integer
): Cardinal;
procedure LinkRecoveredTypes;
implementation
uses
  GI_GI,
  Classes,
  SysUtils,
  Math,
  Windows,
  GlobalsV,
  GR_Main,
  GR_GraphBuf,
  GI_Main,
  GI_Image,
  GI_GraphBuf,
  GI_Label,
  GI_GraphButton;

constructor TfCount2.Create;
begin
  inherited Create;
end;

destructor TfCount2.Destroy;
begin
  inherited Destroy;
end;

procedure TfCount2.InitializeLayout;
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

procedure TfCount2.OnOpen;
begin
  Dragging := False;
  if ImagePath <> '' then
    with GetByName('ItemImage') as TImageGI do
    begin
      SetImagePath(Self.ImagePath);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
  else
    with GetByName('ItemImage') as TImageGI do
      SetActive(False);
  if PreviewImagePath <> '' then
    with GetByName('ItemBuf') as TGraphBufGI do
    begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf(PreviewImagePath, GraphBuf);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
        GraphBuf.RescaleRgba(
            ClientSize.X,
            Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)),
            5
        )
      else
        GraphBuf.RescaleRgba(
            Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)),
            ClientSize.Y,
            5
        );
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
  else
    with GetByName('ItemBuf') as TGraphBufGI do
      SetActive(False);
  with GetByName('Caption') as TLabelGI do
  begin
    SetText(Description);
    SetFontName(Self.FontName);
  end;
  with GetByName('BGBuf') as TGraphBufGI do
    BindExternalGraphBuf(AuxRenderBuffer);
  with GetByName('Add') as TGraphButtonGI do
  begin
    DownCallback := IncreaseMouseDown;
    UpCallback := IncreaseMouseUp;
  end;
  with GetByName('Sub') as TGraphButtonGI do
  begin
    DownCallback := DecreaseMouseDown;
    UpCallback := DecreaseMouseUp;
  end;
  (GetByName('Max') as TGraphButtonGI).UpCallback := MaximumClicked;
  (GetByName('Ok') as TGraphButtonGI).UpCallback := AcceptClicked;
  (GetByName('Close') as TGraphButtonGI).UpCallback := CancelClicked;
  GetByName('PanelBar').LeftButtonDownCallback := SliderMouseDown;
  with GetByName('MainPanel') do
  begin
    MouseMoveCallback := SliderMouseMove;
    LeftButtonUpCallback := SliderMouseUp;
    KeyDownCallback := MainPanelKeyDown;
  end;
  GetByName('Kind0').SetActive(UnitValue > 0);
  GetByName('Count').SetActive(UnitValue > 0);
  GetByName('Sum').SetActive(UnitValue > 0);
  GetByName('Kind1').SetActive(UnitValue <= 0);
  GetByName('Count2').SetActive(UnitValue <= 0);
  RefreshValue;
end;

procedure TfCount2.OnClose;
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount2.RefreshValue;
var
  Width, Position: Integer;
begin
  Width := GetByName('BarRange').ClientSize.X + 2;
  if Maximum - Minimum <= 0 then
    Position := Width - 1
  else
    Position := Round(Value / Maximum * (Width - 1));
  with GetByName('Bar') do
    SetPosition(Classes.Point(Position - 1 - ClientSize.X div 2, 0));
  with GetByName('BarArrow') do
    SetPosition(Classes.Point(Position + 3, 0));
  (GetByName('Ok') as TGraphButtonGI).SetDisabled(Value > Limit);
  if Value <= Available then
  begin
    (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
    (GetByName('Count2') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
  end
  else
  begin
    (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
    (GetByName('Count2') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
  end;
  if Value * UnitValue <= TotalLimit then
    (GetByName('Sum') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0))
  else
    (GetByName('Sum') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
  (GetByName('Count') as TLabelGI).SetText(IntToStr(Value));
  (GetByName('Count2') as TLabelGI).SetText(IntToStr(Value));
  (GetByName('Sum') as TLabelGI).SetText(IntToStr(Round(Value * UnitValue)));
  (GetByName('Add') as TGraphButtonGI).SetDisabled(Value = Maximum);
  (GetByName('Sub') as TGraphButtonGI).SetDisabled(Value = Minimum);
  (GetByName('Max') as TGraphButtonGI).SetDisabled(Value = Min(Available, Min(Limit, Maximum)));
end;

procedure TfCount2.IncreaseMouseDown(Sender: TObjectGI);
begin
  if not Dragging then
  begin
    Inc(Value);
    if Value > Maximum then
      Value := Maximum;
    RefreshValue;
    if RepeatTimer <> nil then
    begin
      CancelCallbackTimer(RepeatTimer);
      RepeatTimer := nil;
    end;
    RepeatTimer := ScheduleCallbackTimer(300, 50, RepeatChange, 2);
  end;
end;

procedure TfCount2.DecreaseMouseDown(Sender: TObjectGI);
begin
  if not Dragging then
  begin
    Dec(Value);
    if Value < Minimum then
      Value := Minimum;
    RefreshValue;
    if RepeatTimer <> nil then
    begin
      CancelCallbackTimer(RepeatTimer);
      RepeatTimer := nil;
    end;
    RepeatTimer := ScheduleCallbackTimer(300, 50, RepeatChange);
  end;
end;

procedure TfCount2.IncreaseMouseUp(Sender: TObjectGI);
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount2.DecreaseMouseUp(Sender: TObjectGI);
begin
  if RepeatTimer <> nil then
  begin
    CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TfCount2.RepeatChange(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  Value := Value + UserData - 1;
  if Value < Minimum then
    Value := Minimum
  else if Value > Maximum then
    Value := Maximum;
  RefreshValue;
end;

procedure TfCount2.MaximumClicked(Sender: TObjectGI);
begin
  Value := Min(Available, Min(Limit, Maximum));
  RefreshValue;
end;

procedure TfCount2.AcceptClicked(Sender: TObjectGI);
begin
  if ExitCode = 0 then
    RequestClose(1)
  else
    RequestClose(ExitCode);
end;

procedure TfCount2.CancelClicked(Sender: TObjectGI);
begin
  if ExitCode = 0 then
    RequestClose(2)
  else
    RequestClose(ExitCode);
end;

procedure TfCount2.SliderMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  Dragging := True;
  SliderMouseMove(Sender, KeyState, Point);
end;

procedure TfCount2.SliderMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  Dragging := False;
end;

procedure TfCount2.SliderMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  X, Width: Integer;
begin
  if Dragging then
  begin
    X := GetByName('BarRange').ToLocalPoint(GetCursorPoint).X;
    Width := GetByName('BarRange').ClientSize.X + 2;
    Value := Round(Maximum * Min(1.0, Max(0.0, (X - 1) / (Width - 1))));
    if Value < Minimum then
      Value := Minimum
    else if Value > Maximum then
      Value := Maximum;
    RefreshValue;
  end;
end;

procedure TfCount2.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = -WHEEL_DELTA then
  begin
    Inc(Value);
    if Value > Maximum then
      Value := Maximum;
    RefreshValue;
  end
  else if Delta = WHEEL_DELTA then
  begin
    Dec(Value);
    if Value < Minimum then
      Value := Minimum;
    RefreshValue;
  end;
end;

procedure TfCount2.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then
    RequestClose(255);
end;

procedure TfCount2.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_LEFT then
  begin
    Dec(Value);
    if Value < Minimum then
      Value := Minimum;
    RefreshValue;
  end
  else if Key = VK_RIGHT then
  begin
    Inc(Value);
    if Value > Maximum then
      Value := Maximum;
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

function ShowCountDialogWithFont(
    Parent: TMessageLoopGI;
    const ImagePath, Description: WideString;
    Minimum, Maximum, Limit: Integer;
    UnitValue: Single;
    Available, TotalLimit: Integer;
    var Value: Integer;
    PreviewImagePath, FontName: WideString
): Cardinal;
var
  Dialog: TfCount2;
  State: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  CaptureScreenBackground(False, 0);
  Dialog := TfCount2.Create;
  Dialog.ParentLoop := Parent;
  Parent.ChildLoop := Dialog;
  Dialog.InitializeFromConfig(UiStyleConfig, 'Count', True);
  Dialog.InitializeLayout;
  try
    Dialog.ImagePath := ImagePath;
    Dialog.PreviewImagePath := PreviewImagePath;
    Dialog.Description := Description;
    Dialog.Minimum := Minimum;
    Dialog.Maximum := Maximum;
    Dialog.Limit := Limit;
    Dialog.Value := Value;
    Dialog.UnitValue := UnitValue;
    Dialog.TotalLimit := TotalLimit;
    Dialog.Available := Available;
    Dialog.FontName := FontName;
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

function ShowCountDialog(
    Parent: TMessageLoopGI;
    const ImagePath, Description: WideString;
    Minimum, Maximum, Limit: Integer;
    UnitValue: Single;
    Available, TotalLimit: Integer;
    var Value: Integer
): Cardinal;
begin
  Result :=
      ShowCountDialogWithFont(
          Parent,
          ImagePath,
          Description,
          Minimum,
          Maximum,
          Limit,
          UnitValue,
          Available,
          TotalLimit,
          Value,
          '',
          NormalFontName
      );
end;

procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
end;
end.
