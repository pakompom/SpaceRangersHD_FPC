{$EXCESSPRECISION OFF}
unit SE_Asteroid;
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
  SE_Space;
type
  TAsteroidSE = class;
  TAsteroidSE = class(TObjectSE)
    ImagePath: WideString;
    MapImagePath: WideString;
    Animation: TgaiGI;
    MapImage: TImageGI;
    SavedSequenceFrameIndex: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    function GetSequenceFrameIndex: Integer;
    procedure SetSequenceFrameIndex(FrameIndex: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  Globals,
  GR_Main,
  GI_Main,
  SE_Process;

procedure TAsteroidSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  ConfigureLoopSound('Comet');
  ConfigureRandomSound('Comet');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  Animation.SetImagePath(ImagePath);
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPosition(TruncatePointF(Position));
  Animation.SetPositionModeW(True);
  Animation.SequenceIndex := 0;
  Animation.UpdateAutoGeometry;
  Animation.SetSequenceFrame(SavedSequenceFrameIndex);
  Animation.RestartPlayback;
  Size := Animation.ClientSize;
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

procedure TAsteroidSE.DetachFromSpace;
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

procedure TAsteroidSE.SetPosition(APosition: TPointF);
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

function TAsteroidSE.GetSequenceFrameIndex: Integer;
begin
  if Animation = nil then
    Result := SavedSequenceFrameIndex
  else
    Result := Animation.SequenceFrame;
end;

procedure TAsteroidSE.SetSequenceFrameIndex(FrameIndex: Integer);
begin
  SavedSequenceFrameIndex := FrameIndex;
  if Animation <> nil then
    Animation.SetSequenceFrame(FrameIndex);
end;

procedure TAsteroidSE.DrawMap;
begin
  with Space.Process as TProcessSE do
    if PointDistanceSquared(Self.Position, RadarCenter) < Sqr(RadarRange) then
      MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

function TAsteroidSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Animation.HitTestCursor;
end;

procedure TAsteroidSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  MapImagePath := Block.GetParam('ImageMap');
end;

procedure TAsteroidSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure TAsteroidSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
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
