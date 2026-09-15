{$EXCESSPRECISION OFF}
unit SE_Hole;
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
  GI_Image,
  GI_MessageLoop,
  SE_Space,
  Types;
type
  THoleSE = class;
  THoleSE = class(TObjectSE)
    ImagePath: WideString;
    MapImagePath: WideString;
    Animation: TgaiGI;
    MapImage: TImageGI;
    SavedSequenceFrameIndex: Integer;
    State: Integer;
    HitRadius: Integer;
    GalaxyImagePath: WideString;
    GalaxyPriority: Integer;
    NameTextPath: WideString;
    InfoTextPath: WideString;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    procedure SetState(Value: Integer);
    procedure AnimationCycleComplete(Sender: TObjectGI);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  Globals,
  GR_Main,
  GI_Main,
  EC_Str,
  SE_Process;

procedure THoleSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  ConfigureLoopSound('Hole');
  ConfigureRandomSound('Hole');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  { Both native state branches load the same resource. }
  if State = 1 then
    Animation.SetImagePath(ImagePath)
  else
    Animation.SetImagePath(ImagePath);
  Animation.CycleCompleteCallback := AnimationCycleComplete;
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPosition(TruncatePointF(Position));
  Animation.SetPositionModeW(True);
  if State = 1 then
    Animation.SequenceIndex := 0
  else
    Animation.SequenceIndex := 1;
  Animation.UpdateAutoGeometry;
  if State = 1 then
    SavedSequenceFrameIndex := 0;
  Animation.SetSequenceFrame(SavedSequenceFrameIndex);
  Animation.RestartPlayback;
  MapImage := TImageGI.Create(SpaceObjectUiLoop.ContentPanel);
  MapImage.SetPositionModeW(True);
  MapImage.SetDepthByName(DepthExpression);
  MapImage.SetPosition(
      TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
  );
  MapImage.SetImagePath(MapImagePath);
  MapImage.SetSize(MapImage.GetContentSize);
  MapImage.SetOrigin(HalfPoint(MapImage.GetContentSize));
end;

procedure THoleSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if Animation <> nil then
  begin
    SavedSequenceFrameIndex := Animation.SequenceFrame;
    Animation.Free;
    Animation := nil;
  end;
  if MapImage <> nil then
  begin
    MapImage.Free;
    MapImage := nil;
  end;
  inherited DetachFromSpace;
end;

procedure THoleSE.SetState(Value: Integer);
begin
  if (State = 1) and (Value = 0) and IsAttachedToSpace then
    Exit;
  State := Value;
end;

procedure THoleSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    Animation.SetPosition(TruncatePointF(APosition));
    MapImage.SetPosition(
        TruncatePointF(
            MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
        )
    );
  end;
end;

procedure THoleSE.DrawMap;
begin
  with Space.Process as TProcessSE do
    if PointDistanceSquared(Self.Position, RadarCenter) < Sqr(RadarRange) then
      MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

function THoleSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Animation.HitTestCursor;
end;

procedure THoleSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  MapImagePath := Block.GetParam('ImageMap');
  if Block.CountParams('Radius') > 0 then
    HitRadius := ExtractDigitsToIntW(Block.GetParam('Radius'))
  else
    HitRadius := 80;
  if Block.CountParams('GalaxyImage') > 0 then
    GalaxyImagePath := Block.GetParam('GalaxyImage')
  else
    GalaxyImagePath := 'GI,Bm.FormGalaxy.BlackHole';
  if Block.CountParams('GalaxyPriority') > 0 then
    GalaxyPriority := ExtractDigitsToIntW(Block.GetParam('GalaxyPriority'))
  else
    GalaxyPriority := 80;
  if Block.CountParams('NamePath') > 0 then
    NameTextPath := Block.GetParam('NamePath')
  else
    NameTextPath := 'FormInfo.HoleName';
  if Block.CountParams('TextPath') > 0 then
    InfoTextPath := Block.GetParam('TextPath')
  else
    InfoTextPath := 'FormInfo.HoleText';
end;

procedure THoleSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure THoleSE.AnimationCycleComplete(Sender: TObjectGI);
begin
  if State = 1 then
  begin
    Animation.SetImagePath(ImagePath);
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SequenceIndex := 1;
    Animation.UpdateAutoGeometry;
    Animation.SetSequenceFrame(0);
    Animation.RestartPlayback;
  end
  else if State = 2 then
  begin
    if Animation.SequenceIndex = 2 then
      DetachFromSpace
    else
    begin
      Animation.SetImagePath(ImagePath);
      Animation.SetSize(Animation.GetContentSize);
      Animation.SetOrigin(HalfPoint(Animation.ClientSize));
      Animation.SequenceIndex := 2;
      Animation.UpdateAutoGeometry;
      Animation.SetSequenceFrame(0);
      Animation.RestartPlayback;
    end;
  end;
end;

procedure THoleSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  with TgaiGI.Create(Owner) do
  begin
    SetImagePath(Self.ImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
  with TImageGI.Create(Owner) do
  begin
    SetImagePath(MapImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;

procedure LinkRecoveredTypes;
begin
  TProcessSE.ClassName;
end;
end.
