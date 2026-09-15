{$EXCESSPRECISION OFF}
unit SE_StarsField;
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
  GI_SimpleImage,
  GI_InfiniteImage,
  SE_Space,
  Types;
type
  TStarsFieldSE = class;
  TStarsFieldSE = class(TObjectSE)
    ImagePath: WideString;
    InfiniteImage: TInfiniteImageGI;
    StaticImage: TSimpleImageGI;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
  end;
implementation
uses
  Math,
  GI_Main,
  GlobalsV,
  GI_Image;

procedure TStarsFieldSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then
    Exit;
  inherited AttachToSpace(ASpace);
  if StaticBackground then
  begin
    StaticImage := TSimpleImageGI.Create(Space.MapPanel);
    StaticImage.SetDepthByName(DepthExpression);
    StaticImage.SetPositionModeW(False);
    StaticImage.SetImageKindX(ikxLeftFill);
    StaticImage.SetImageKindY(ikyTopFill);
    StaticImage
        .SetPosition(Classes.Point(-Space.MapPanel.OriginPoint.X, -Space.MapPanel.OriginPoint.Y));
    StaticImage.SetSize(Classes.Point(Space.MapPanel.ClientSize.X, Space.MapPanel.ClientSize.Y));
    StaticImage.SetImagePath(ImagePath);
  end
  else
  begin
    InfiniteImage := TInfiniteImageGI.Create(Space.MapPanel);
    InfiniteImage.SetDepthByName(DepthExpression);
    InfiniteImage.SetPositionModeW(True);
    InfiniteImage.SetImagePath(ImagePath);
  end;
end;

procedure TStarsFieldSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if InfiniteImage <> nil then
  begin
    Space.MapPanel.FreeOwnedChild(InfiniteImage);
    InfiniteImage := nil;
  end;
  if StaticImage <> nil then
  begin
    Space.MapPanel.FreeOwnedChild(StaticImage);
    StaticImage := nil;
  end;
  inherited DetachFromSpace;
end;

procedure TStarsFieldSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
end;

procedure TStarsFieldSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  if StaticBackground then
    with TSimpleImageGI.Create(Owner) do
    begin
      SetImagePath(Self.ImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end
  else
    with TInfiniteImageGI.Create(Owner) do
    begin
      SetImagePath(Self.ImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
end;

end.
