{$EXCESSPRECISION OFF}
unit SE_Star;
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
  GI_GI,
  GI_MessageLoop,
  SE_Space,
  Types;
type
  TStarSE = class;
  TStarSE = class(TObjectSE)
    AnimationPath: WideString;
    StaticImagePath: WideString;
    ImageOrigin: TPoint;
    MapImagePath: WideString;
    MapImageOrigin: TPoint;
    StaticImage: TImageGI;
    Animation: TgaiGI;
    MapImage: TgiGI;
    SavedSequenceFrameIndex: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    function GetSequenceFrameIndex: Integer;
    procedure SetSequenceFrameIndex(FrameIndex: Integer);
  end;
implementation
uses
  Math,
  GlobalsV,
  Globals,
  GR_Main,
  GI_Main,
  EC_Str;

procedure TStarSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  ConfigureLoopSound('Star');
  ConfigureRandomSound('Star');
  inherited AttachToSpace(ASpace);
  if not AnimStar then
  begin
    StaticImage := TImageGI.Create(Space.MapPanel);
    StaticImage.SetImagePath(StaticImagePath);
    StaticImage.SetPositionModeW(True);
    StaticImage.SetDepthByName(DepthExpression);
    StaticImage.SetPosition(TruncatePointF(Position));
    StaticImage.SetSize(StaticImage.GetContentSize);
    StaticImage.SetOrigin(HalfPoint(StaticImage.ClientSize));
  end
  else
  begin
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(AnimationPath);
    Animation.LoadFrameSequenceFromText(
        '[65,0-' + IntToWideString(Animation.GetMainImageFrameCount - 1) + ']'
    );
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetSequenceFrame(SavedSequenceFrameIndex);
    Animation.RestartPlayback;
  end;
  MapImage := TgiGI.Create(SpaceObjectUiLoop.ContentPanel);
  MapImage.SetPositionModeW(True);
  MapImage.SetDepthByName(DepthExpression);
  MapImage.SetPosition(
      TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
  );
  MapImage.SetOrigin(MapImageOrigin);
  MapImage.SetImagePath(MapImagePath);
  MapImage.SetSize(MapImage.GetContentSize);
end;

procedure TStarSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if Animation <> nil then
  begin
    SavedSequenceFrameIndex := Animation.SequenceFrame;
    Animation.Free;
    Animation := nil;
  end;
  if StaticImage <> nil then
  begin
    StaticImage.Free;
    StaticImage := nil;
  end;
  if MapImage <> nil then
  begin
    MapImage.Free;
    MapImage := nil;
  end;
  inherited DetachFromSpace;
end;

procedure TStarSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    if StaticImage <> nil then
      StaticImage.SetPosition(TruncatePointF(APosition));
    if Animation <> nil then
      Animation.SetPosition(TruncatePointF(APosition));
    MapImage.SetPosition(
        TruncatePointF(
            MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
        )
    );
  end;
end;

function TStarSE.GetSequenceFrameIndex: Integer;
begin
  if Animation = nil then
    Result := SavedSequenceFrameIndex
  else
    Result := Animation.SequenceFrame;
end;

procedure TStarSE.SetSequenceFrameIndex(FrameIndex: Integer);
begin
  SavedSequenceFrameIndex := FrameIndex;
  if Animation <> nil then
    Animation.SetSequenceFrame(FrameIndex);
end;

function TStarSE.HitTestCursor: Boolean;
begin
  Result := False;
  if not IsAttachedToSpace then
  begin
    Result := False;
    Exit;
  end;
  if StaticImage <> nil then
    Result := StaticImage.HitTestCursor;
  if Animation <> nil then
    Result := Animation.HitTestCursor;
end;

procedure TStarSE.DrawMap;
begin
  MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

procedure TStarSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  StaticImagePath := Block.GetParam('Image');
  AnimationPath := Block.GetParam('Anim');
  MapImagePath := Block.GetParam('ImageMap');
  ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
  MapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
end;

procedure TStarSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  if not AnimStar then
    with TImageGI.Create(Owner) do
    begin
      SetImagePath(StaticImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end
  else
    with TgaiGI.Create(Owner) do
    begin
      SetImagePath(AnimationPath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
  with TgiGI.Create(Owner) do
  begin
    SetImagePath(MapImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;

end.
