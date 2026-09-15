{$EXCESSPRECISION OFF}
unit SE_BGObj;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_MessageLoop,
  GI_Image,
  SE_Space,
  Types;
type
  TBGObjSE = class;
  TBGObjSE = class(TObjectSE)
    ImagePath: WideString;
    Radius: Single;
    Image: TImageGI;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
  end;
implementation
uses
  Math,
  EC_Str,
  GI_Main;

procedure TBGObjSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  inherited AttachToSpace(ASpace);
  Image := TImageGI.Create(Space.MapPanel);
  Image.SetPositionModeW(True);
  Image.SetDepthByName(DepthExpression);
  Image.SetPosition(TruncatePointF(Position));
  Image.SetImagePath(ImagePath);
  Image.SetSize(Image.GetContentSize);
end;

procedure TBGObjSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  Space.MapPanel.FreeOwnedChild(Image);
  Image := nil;
  inherited DetachFromSpace;
end;

procedure TBGObjSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
    Image.SetPosition(TruncatePointF(APosition));
end;

procedure TBGObjSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  Radius := ExtractDigitsToIntW(Block.GetParam('Radius'));
end;

procedure TBGObjSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  with TImageGI.Create(Owner) do
  begin
    SetImagePath(Self.ImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;

end.
