{$EXCESSPRECISION OFF}
unit GI_CountBar;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_GraphButton,
  GI_Image,
  GI_MessageLoop,
  Types;
type
  TCountBarGI = class;
  TCountBarGI = class(TObjectGI)
    Minimum: Integer;
    Maximum: Integer;
    Position: Integer;
    Orientation: Integer;
    Step: Integer;
    DecreaseButton: TGraphButtonGI;
    IncreaseButton: TGraphButtonGI;
    AfterThumbImage: TImageGI;
    BeforeThumbImage: TImageGI;
    ThumbButton: TGraphButtonGI;
    MarkerImage: TImageGI;
    Gap14C: array[0..3] of Byte;
    PositionChangedCallback: TObjectNotifyEventGI;
    RepeatTimer: PCallbackTimerGI;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetRange(MinValue: Integer; MaxValue: Integer);
    procedure SetPositionInternal(Value: Integer);
    procedure SetPosition(Value: Integer);
    procedure UpdateLayout;
    procedure AutoRepeat(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure DecreasePressed(Sender: TObjectGI);
    procedure IncreasePressed(Sender: TObjectGI);
    procedure LoadCountBarProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GR_Main,
  Classes,
  EC_Struct,
  GI_Main;

constructor TCountBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Orientation := 1;
  Minimum := 0;
  Maximum := 100;
  Position := 0;
  Step := 1;
  DecreaseButton := TGraphButtonGI.Create(Self);
  IncreaseButton := TGraphButtonGI.Create(Self);
  AfterThumbImage := TImageGI.Create(Self);
  BeforeThumbImage := TImageGI.Create(Self);
  ThumbButton := TGraphButtonGI.Create(Self);
  MarkerImage := TImageGI.Create(Self);
  DecreaseButton.DownCallback := DecreasePressed;
  IncreaseButton.DownCallback := IncreasePressed;
  AfterThumbImage.SetImageKindX(ikxLeftFill);
  AfterThumbImage.SetImageKindY(ikyTopFill);
  BeforeThumbImage.SetImageKindX(ikxLeftFill);
  BeforeThumbImage.SetImageKindY(ikyTopFill);
  ThumbButton.SetKind(gbkFix);
end;

destructor TCountBarGI.Destroy;
begin
  if DecreaseButton <> nil then
  begin
    DecreaseButton.Free;
    DecreaseButton := nil;
  end;
  if IncreaseButton <> nil then
  begin
    IncreaseButton.Free;
    IncreaseButton := nil;
  end;
  if AfterThumbImage <> nil then
  begin
    AfterThumbImage.Free;
    AfterThumbImage := nil;
  end;
  if BeforeThumbImage <> nil then
  begin
    BeforeThumbImage.Free;
    BeforeThumbImage := nil;
  end;
  if ThumbButton <> nil then
  begin
    ThumbButton.Free;
    ThumbButton := nil;
  end;
  if MarkerImage <> nil then
  begin
    MarkerImage.Free;
    MarkerImage := nil;
  end;
  if RepeatTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
  inherited Destroy;
end;

procedure TCountBarGI.SetRange(MinValue, MaxValue: Integer);
begin
  if (Maximum <> MaxValue) or (Minimum <> MinValue) then
  begin
    if MinValue > MaxValue then
      MinValue := MaxValue;
    Minimum := MinValue;
    Maximum := MaxValue;
    if Position < Minimum then
      SetPositionInternal(Minimum);
    if Position > Maximum then
      SetPositionInternal(Maximum);
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
    end;
  end;
end;

procedure TCountBarGI.SetPositionInternal(Value: Integer);
begin
  if Position <> Value then
  begin
    Position := Value;
    if Position < Minimum then
      Position := Minimum;
    if Position > Maximum then
      Position := Maximum;
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
    end;
  end;
end;

procedure TCountBarGI.SetPosition(Value: Integer);
begin
  if Position <> Value then
  begin
    Position := Value;
    if Position < Minimum then
      Position := Minimum;
    if Position > Maximum then
      Position := Maximum;
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
      if Assigned(PositionChangedCallback) then
        PositionChangedCallback(Self);
    end;
  end;
end;

procedure TCountBarGI.UpdateLayout;
var
  TrackWidth, ThumbLeft, ThumbRight: Integer;
  ThumbSize, IncreaseSize, DecreaseSize: TPoint;
begin
  if Orientation = 1 then
  begin
    ThumbSize := ThumbButton.GetMaxStateImageSize;
    DecreaseSize := DecreaseButton.GetMaxStateImageSize;
    IncreaseSize := IncreaseButton.GetMaxStateImageSize;
    TrackWidth := ClientSize.X - ThumbSize.X - IncreaseSize.X - DecreaseSize.X;
    if Maximum - Minimum = 0 then
      ThumbLeft := IncreaseSize.X
    else
      ThumbLeft :=
          Integer(Round(TrackWidth * (Position - Minimum) / (Maximum - Minimum)))
              - ThumbSize.X div 2
              + IncreaseSize.X
              + ThumbSize.X div 2;
    ThumbRight := ThumbLeft + ThumbSize.X;
    DecreaseButton.SetPosition(Classes.Point(0, 0));
    DecreaseButton.SetSize(DecreaseSize);
    IncreaseButton.SetPosition(Classes.Point(ClientSize.X - IncreaseSize.X, 0));
    IncreaseButton.SetSize(IncreaseSize);
    BeforeThumbImage.SetPosition(Classes.Point(DecreaseSize.X, 0));
    BeforeThumbImage
        .SetSize(Classes.Point(ThumbLeft - DecreaseSize.X, AfterThumbImage.GetContentSize.Y));
    AfterThumbImage.SetPosition(Classes.Point(ThumbRight, 0));
    AfterThumbImage.SetSize(
        Classes.Point(ClientSize.X - ThumbRight - IncreaseSize.X, BeforeThumbImage.GetContentSize.Y)
    );
    ThumbButton.SetPosition(Classes.Point(ThumbLeft, 0));
    ThumbButton.SetSize(Classes.Point(ThumbRight - ThumbLeft, ThumbSize.Y));
    AfterThumbImage.SetImageKindX(ikxRightFill);
    BeforeThumbImage.SetImageKindX(ikxLeftFill);
    MarkerImage
        .SetPosition(AddPoints(ThumbButton.LocalPosition, HalfPoint(ThumbButton.ClientSize)));
    if DecreaseButton.Kind = gbkDisable then
      DecreaseButton.SetDisabled(Position <= Minimum);
    if IncreaseButton.Kind = gbkDisable then
      IncreaseButton.SetDisabled(Position >= Maximum);
  end;
end;

procedure TCountBarGI.AutoRepeat(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  if DecreaseButton.Down then
    SetPosition(Position - Step)
  else if IncreaseButton.Down then
    SetPosition(Position + Step)
  else if RepeatTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
end;

procedure TCountBarGI.DecreasePressed(Sender: TObjectGI);
begin
  SetPosition(Position - Step);
  if RepeatTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
  RepeatTimer := MessageLoop.ScheduleCallbackTimer(300, 50, AutoRepeat);
end;

procedure TCountBarGI.IncreasePressed(Sender: TObjectGI);
begin
  SetPosition(Position + Step);
  if RepeatTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := nil;
  end;
  RepeatTimer := MessageLoop.ScheduleCallbackTimer(300, 50, AutoRepeat);
end;

procedure TCountBarGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var
  TrackStart, TrackEnd: Integer;
begin
  inherited ProcessMouseMove(KeyState, Point);
  Point := ToLocalPoint(Point);
  if ThumbButton.Down and (Orientation = 1) then
  begin
    TrackStart := DecreaseButton.GetMaxStateImageSize.X + ThumbButton.GetMaxStateImageSize.X div 2;
    TrackEnd :=
        ClientSize.X
            - IncreaseButton.GetMaxStateImageSize.X
            - (ThumbButton.GetMaxStateImageSize.X - ThumbButton.GetMaxStateImageSize.X div 2);
    if Maximum - Minimum = 0 then
      SetPosition(Minimum)
    else
      SetPosition(
          Integer(Round((Point.X - TrackStart) / (TrackEnd - TrackStart) * (Maximum - Minimum)))
              + Minimum
      );
  end;
end;

procedure TCountBarGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;

procedure TCountBarGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
end;

procedure TCountBarGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var
  TrackStart, TrackEnd: Integer;
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Active then
    MessageLoop.SetFocusedControl(Self);
  Point := ToLocalPoint(Point);
  if Orientation = 1 then
  begin
    TrackStart := DecreaseButton.GetMaxStateImageSize.X + ThumbButton.GetMaxStateImageSize.X div 2;
    TrackEnd :=
        ClientSize.X
            - IncreaseButton.GetMaxStateImageSize.X
            - (ThumbButton.GetMaxStateImageSize.X - ThumbButton.GetMaxStateImageSize.X div 2);
    if (Point.X >= DecreaseButton.GetMaxStateImageSize.X)
        and (Point.X <= ClientSize.X - IncreaseButton.GetMaxStateImageSize.X) then
    begin
      if Maximum - Minimum = 0 then
        SetPosition(Minimum)
      else
        SetPosition(
            Integer(Round((Point.X - TrackStart) / (TrackEnd - TrackStart) * (Maximum - Minimum)))
                + Minimum
        );
      ThumbButton.SetDown(True);
    end;
  end;
end;

procedure TCountBarGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  ThumbButton.SetDown(False);
  if MessageLoop.FocusedControl = Self then
    MessageLoop.SetFocusedControl(nil);
end;

procedure TCountBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadCountBarProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TCountBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadCountBarProperties(Block);
end;

procedure TCountBarGI.LoadCountBarProperties(Block: TBlockParEC);
begin
  if Block.CountParams('ImageDecNormal') > 0 then
    DecreaseButton.SetImageNormalPath(Block.GetParam('ImageDecNormal'));
  if Block.CountParams('ImageDecNormalA') > 0 then
    DecreaseButton.SetImageNormalActivePath(Block.GetParam('ImageDecNormalA'));
  if Block.CountParams('ImageDecDown') > 0 then
    DecreaseButton.SetImageDownPath(Block.GetParam('ImageDecDown'));
  if Block.CountParams('ImageIncNormal') > 0 then
    IncreaseButton.SetImageNormalPath(Block.GetParam('ImageIncNormal'));
  if Block.CountParams('ImageIncNormalA') > 0 then
    IncreaseButton.SetImageNormalActivePath(Block.GetParam('ImageIncNormalA'));
  if Block.CountParams('ImageIncDown') > 0 then
    IncreaseButton.SetImageDownPath(Block.GetParam('ImageIncDown'));
  if Block.CountParams('ImageTrackMin') > 0 then
    AfterThumbImage.SetImagePath(Block.GetParam('ImageTrackMin'));
  if Block.CountParams('ImageTrackMax') > 0 then
    BeforeThumbImage.SetImagePath(Block.GetParam('ImageTrackMax'));
  if Block.CountParams('ImageTrackPolNormal') > 0 then
    ThumbButton.SetImageNormalPath(Block.GetParam('ImageTrackPolNormal'));
  if Block.CountParams('ImageTrackPolNormalA') > 0 then
    ThumbButton.SetImageNormalActivePath(Block.GetParam('ImageTrackPolNormalA'));
  if Block.CountParams('ImageTrackPolDown') > 0 then
    ThumbButton.SetImageDownPath(Block.GetParam('ImageTrackPolDown'));
  if Block.CountParams('ImageTrackUp') > 0 then
    MarkerImage.SetImagePath(Block.GetParam('ImageTrackUp'));
  UpdateLayout;
end;

end.
