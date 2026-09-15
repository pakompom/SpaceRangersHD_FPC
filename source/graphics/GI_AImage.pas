{$EXCESSPRECISION OFF}
unit GI_AImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  GI_Main,
  GI_MessageLoop,
  Types;
type
  TAImageGI = class;
  TAImageGI = class(TObjectGI)
    FrameTimer: PCallbackTimerGI;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    HalfAlpha: Boolean;
    Gap127: array[0..0] of Byte;
    CurrentFrame: TObjectGI;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnActivate; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    function GetContentSize: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetHalfAlpha(Value: Boolean);
    procedure AdvanceFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
    function HitTest(Point: TPoint): Boolean;
    procedure LoadAnimationProperties(Block: TBlockParEC);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GR_Main,
  GI_Image,
  EC_Str,
  SysUtils,
  GlobalsV;

constructor TAImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfAlpha := False;
end;

destructor TAImageGI.Destroy;
begin
  inherited Destroy;
end;

procedure TAImageGI.Clear;
begin
  HalfAlpha := False;
  if FrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := nil;
  end;
  CurrentFrame := nil;
end;

function TAImageGI.GetContentSize: TPoint;
var
  Frame: TImageGI;
  Size: TPoint;
begin
  Result := Classes.Point(0, 0);
  Frame := FirstChild as TImageGI;
  if Frame <> nil then
  begin
    Result := Frame.GetContentSize;
    Frame := Frame.NextSibling as TImageGI;
  end;
  while Frame <> nil do
  begin
    Size := Frame.GetContentSize;
    if Result.X < Size.X then
      Result.X := Size.X;
    if Result.Y < Size.Y then
      Result.Y := Size.Y;
    Frame := Frame.NextSibling as TImageGI;
  end;
end;

procedure TAImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    if CurrentFrame <> nil then
      (CurrentFrame as TImageGI).SetImageKindX(Value);
  end;
end;

procedure TAImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    if CurrentFrame <> nil then
      (CurrentFrame as TImageGI).SetImageKindY(Value);
  end;
end;

procedure TAImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    if CurrentFrame <> nil then
      (CurrentFrame as TImageGI).SetHalfAlpha(Value);
  end;
end;

procedure TAImageGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if CurrentFrame <> nil then
    (CurrentFrame as TImageGI).SetSize(Size);
end;

procedure TAImageGI.AdvanceFrame(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Previous: TObjectGI;
  Next: TImageGI;
begin
  Previous := TObjectGI(UserData);
  Next := Previous.NextSibling as TImageGI;
  if Next = nil then
    Next := FirstChild as TImageGI;
  MessageLoop.CancelCallbackTimer(FrameTimer);
  FrameTimer :=
      MessageLoop.ScheduleCallbackTimer(Next.UserValue, $FFFFFF, AdvanceFrame, PtrInt(Next));
  Previous.SetActive(False);
  Next.SetActive(True);
  Next.SetOrigin(OriginPoint);
  Next.SetSize(ClientSize);
  Next.SetImageKindX(ImageKindX);
  Next.SetImageKindY(ImageKindY);
  Next.SetHalfAlpha(HalfAlpha);
  CurrentFrame := Next;
end;

function TAImageGI.HitTest(Point: TPoint): Boolean;
begin
  if CurrentFrame = nil then
    Result := False
  else
    Result := CurrentFrame.ContainsPoint(Point);
end;

procedure TAImageGI.OnActivate;
begin
  inherited OnActivate;
  AdvanceFrame(nil, PtrInt(FirstChild));
end;

procedure TAImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadAnimationProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TAImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadAnimationProperties(Block);
end;

procedure TAImageGI.LoadAnimationProperties(Block: TBlockParEC);
var
  Count, Index: Integer;
  HaveFrame: Boolean;
  Frame, First: TImageGI;
begin
  HaveFrame := False;
  Count := Block.GetParamCount;
  for Index := 0 to Count - 1 do
    if IsIntegerTextW(Block.GetParamName(Index)) then
    begin
      if not HaveFrame then
        FreeOwnedChildren;
      Frame := TImageGI.Create(Self);
      Frame.UserValue := StrToInt(Block.GetParamName(Index));
      Frame.SetDepth(Count + 1 - Index);
      Frame.SetImagePath(Block.GetParamValue(Index));
      if HaveFrame then
        Frame.SetActive(False);
      HaveFrame := True;
    end;
  CurrentFrame := nil;
  if FrameTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := nil;
  end;
  First := FirstChild as TImageGI;
  if First <> nil then
  begin
    FrameTimer :=
        MessageLoop.ScheduleCallbackTimer(First.UserValue, $FFFFFF, AdvanceFrame, PtrInt(First));
    First.SetSize(ClientSize);
    First.SetImageKindX(ImageKindX);
    First.SetImageKindY(ImageKindY);
    CurrentFrame := First;
  end;
  if Block.CountParams('HalfAlpha') > 0 then
    SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;

procedure TAImageGI.QueueImageLoad(PendingLoads: TList);
var
  Frame: TImageGI;
begin
  Frame := FirstChild as TImageGI;
  while Frame <> nil do
  begin
    Frame.QueueImageLoad(PendingLoads);
    Frame := Frame.NextSibling as TImageGI;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TImageGI.ClassName;
end;
end.
