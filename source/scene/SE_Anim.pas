{$EXCESSPRECISION OFF}
unit SE_Anim;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  GI_MessageLoop,
  SE_Space,
  Types;
type
  TAnimSE = class;
  TAnimSE = class(TObjectSE)
    ImagePath: WideString;
    ImageOrigin: TPoint;
    LoopAnimation: Boolean;
    Gap59: array[0..2] of Byte;
    Animation: TgaiGI;
    FinishedCallback: TNotifyEvent;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function HitTestCursor: Boolean; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    destructor Destroy; override;
    procedure AnimationCycleComplete(Sender: TObjectGI);
  end;
implementation
uses
  Math,
  GI_Main;

destructor TAnimSE.Destroy;
begin
  inherited Destroy;
end;

procedure TAnimSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    inherited AttachToSpace(ASpace);
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(ImagePath);
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetOrigin(ImageOrigin);
    Animation.SetSize(Animation.GetContentSize);
    Animation.CycleCompleteCallback := AnimationCycleComplete;
    Animation.RestartPlayback;
  end;
end;

procedure TAnimSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    Animation.SetActive(False);
    Animation.Free;
    Animation := nil;
    inherited DetachFromSpace;
  end;
end;

procedure TAnimSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
    Animation.SetPosition(TruncatePointF(Position));
end;

procedure TAnimSE.AnimationCycleComplete(Sender: TObjectGI);
begin
  if not LoopAnimation then
  begin
    DetachFromSpace;
    if Assigned(FinishedCallback) then
      FinishedCallback(Self);
  end;
end;

function TAnimSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Animation.HitTestCursor;
end;

procedure TAnimSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  if Block.CountParams('LoopAnim') > 0 then
    LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'));
  if Block.CountParams('SmeImage') > 0 then
    ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
end;

procedure TAnimSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('LoopAnim') > 0 then
    LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'));
  if Block.CountParams('SmeImage') > 0 then
    ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
end;

procedure TAnimSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Image: TgaiGI;
begin
  Image := TgaiGI.Create(Owner);
  Image.SetImagePath(ImagePath);
  Image.QueueImageLoad(PendingLoads);
  Image.Free;
end;

end.
