{$EXCESSPRECISION OFF}
unit SE_Container;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_AlphaImage,
  GI_GAI,
  GI_MessageLoop,
  SE_Space,
  Types;
type
  TContainerSE = class;
  TContainerSE = class(TObjectSE)
    ImagePath: WideString;
    MinimapImagePath: WideString;
    Animation: TgaiGI;
    MinimapImage: TAlphaImageGI;
    procedure CopyTo(Destination: TObjectSE); override;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure SetDepth(Value: Single); override;
    function GetDepth: Single; override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  Globals,
  GR_Main,
  SE_Process;

procedure TContainerSE.CopyTo(Destination: TObjectSE);
begin
  inherited CopyTo(Destination);
  (Destination as TContainerSE).ImagePath := ImagePath;
  (Destination as TContainerSE).MinimapImagePath := MinimapImagePath;
end;

procedure TContainerSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    ConfigureLoopSound('Container');
    ConfigureRandomSound('Container');
    inherited AttachToSpace(ASpace);
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(ImagePath);
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetSequenceFrame(RandomIntRange(0, Animation.SequenceFrameCount - 1));
    Animation.RestartPlayback;
    MinimapImage := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(
        TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
    );
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.ClientSize));
  end;
end;

procedure TContainerSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
    begin
      Animation.Free;
      Animation := nil;
    end;
    if MinimapImage <> nil then
    begin
      MinimapImage.Free;
      MinimapImage := nil;
    end;
    inherited DetachFromSpace;
  end;
end;

procedure TContainerSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    Animation.SetPosition(TruncatePointF(APosition));
    MinimapImage.SetPosition(
        TruncatePointF(
            MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
        )
    );
  end;
end;

procedure TContainerSE.SetDepth(Value: Single);
begin
  Animation.SetDepth(Value);
end;

function TContainerSE.GetDepth: Single;
begin
  Result := Animation.Depth;
end;

function TContainerSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Animation.HitTestCursor;
end;

procedure TContainerSE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if PointDistanceSquared(Position, CurrentProcess.RadarCenter)
      < Sqr(CurrentProcess.RadarRange) then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

procedure TContainerSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam(GiResourceSuffix + 'Image');
  MinimapImagePath := Block.GetParam('ImageMap');
end;

procedure TContainerSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Image: TgaiGI;
  MapImage: TAlphaImageGI;
begin
  Image := TgaiGI.Create(Owner);
  Image.SetImagePath(ImagePath);
  Image.QueueImageLoad(PendingLoads);
  Image.Free;
  MapImage := TAlphaImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;

procedure LinkRecoveredTypes;
begin
  TContainerSE.ClassName;
  TProcessSE.ClassName;
end;
end.
