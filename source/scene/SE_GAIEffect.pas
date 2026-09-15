{$EXCESSPRECISION OFF}
unit SE_GAIEffect;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_GAI,
  SE_Space,
  Types;
type
  TGAIEffectSE = class;
  TGAIEffectSE = class(TObjectSE)
    SoundPath: WideString;
    ImagePosition: TPoint;
    DurationScale: Single;
    ImagePath: WideString;
    Animation: TgaiGI;
    StepsPerFrame: Integer;
    StepIndex: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure Advance; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    constructor Create(const GraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    procedure SetImagePosition(Value: TPoint);
    procedure SetDurationScale(Value: Single);
  end;
implementation
uses
  GR_Main,
  Globals,
  Math,
  EC_Struct,
  GlobalsV,
  GR_Sound;

constructor TGAIEffectSE.Create(const GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
  DurationScale := 1;
end;

destructor TGAIEffectSE.Destroy;
begin
  inherited Destroy;
end;

procedure TGAIEffectSE.AttachToSpace(ASpace: TSpaceSE);
var
  StepDuration, Duration: Integer;
begin
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  Animation.SetImagePath(ImagePath);
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPositionModeW(True);
  Animation.SetPosition(ImagePosition);
  Animation.SequenceIndex := 0;
  Animation.UpdateAutoGeometry;
  Animation.StopAutoPlayback;
  StepsPerFrame := Math.Max(1, Round(DurationScale * 200 / Animation.SequenceFrameCount));
  if FilmSpeed = 0 then
    StepDuration := 18
  else if FilmSpeed = 1 then
    StepDuration := 14
  else
    StepDuration := 10;
  Duration := Animation.SequenceFrameCount * StepDuration * StepsPerFrame;
  Animation.SetOneCycleDuration(Duration);
  if FilmSoundEffectsEnabled then
    if SoundInSpaceEnabled then
      if Space.ContainsMapPoint(PointToPointF(Animation.LocalPosition)) then
        SoundManager.PlaySound(SoundPath);
  StepIndex := 0;
end;

procedure TGAIEffectSE.DetachFromSpace;
begin
  if Animation <> nil then
  begin
    Animation.Free;
    Animation := nil;
  end;
  inherited DetachFromSpace;
end;

procedure TGAIEffectSE.SetImagePosition(Value: TPoint);
begin
  ImagePosition := Value;
end;

procedure TGAIEffectSE.SetDurationScale(Value: Single);
begin
  DurationScale := Value;
end;

procedure TGAIEffectSE.Advance;
begin
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
    begin
      if Animation.SequenceFrame = Animation.SequenceFrameCount - 1 then
      begin
        Animation.Free;
        Animation := nil;
        DetachFromSpace;
      end
      else if StepIndex mod StepsPerFrame = 0 then
        Animation.SetSequenceFrame(Animation.SequenceFrame + 1);
    end;
    Inc(StepIndex);
  end;
end;

procedure TGAIEffectSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('GAI');
  if Block.CountParams('Sound') > 0 then
    SoundPath := Block.GetParam('Sound');
end;

end.
