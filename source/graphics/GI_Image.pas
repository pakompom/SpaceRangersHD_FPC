{$EXCESSPRECISION OFF}
unit GI_Image;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_GAI,
  GI_MessageLoop,
  GI_Main,
  GI_AImage,
  GI_AlphaImage,
  GI_GI,
  GI_TransImage,
  GI_SimpleImage,
  GI_GraphBuf,
  Classes,
  Types;
type
  TImageGI = class;
  TImageGI = class(TObjectGI)
    SimpleImageControl: TSimpleImageGI;
    TransImageControl: TTransImageGI;
    AlphaImageControl: TAlphaImageGI;
    GiImageControl: TgiGI;
    AnimImageControl: TAImageGI;
    GaiImageControl: TgaiGI;
    GraphBufControl: TGraphBufGI;
    ImagePath: WideString;
    AutoUpdateFlags: Cardinal;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure SetOrigin(Origin: TPoint); override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(Path: WideString);
    function GetImagePath: WideString;
    function GetContentSize: TPoint;
    function GetContentOrigin: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetHalfAlpha(Value: Boolean);
    function GetAlpha: Byte;
    procedure SetAlpha(Value: Byte);
    function HitTestPixel(Point: TPoint): Boolean;
    function GetVisualCenter: TPoint;
    procedure RestartPlayback;
    procedure StopPlayback;
    procedure LoadImageProperties(Block: TBlockParEC);
    procedure SetHardwareMirrorHorizontal(Value: Boolean);
  end;
implementation
uses
  Math,
  SysUtils,
  GlobalsV,
  EC_Str,
  GR_Main;

constructor TImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;

destructor TImageGI.Destroy;
begin
  inherited Destroy;
end;

procedure TImageGI.Clear;
begin
  inherited Clear;
end;

procedure TImageGI.SetImagePath(Path: WideString);
var
  Mode: WideString;
begin
  if ImagePath <> Path then
  begin
    if SimpleImageControl <> nil then
    begin
      FreeOwnedChild(SimpleImageControl);
      SimpleImageControl := nil;
    end;
    if TransImageControl <> nil then
    begin
      FreeOwnedChild(TransImageControl);
      TransImageControl := nil;
    end;
    if AlphaImageControl <> nil then
    begin
      FreeOwnedChild(AlphaImageControl);
      AlphaImageControl := nil;
    end;
    if GiImageControl <> nil then
    begin
      FreeOwnedChild(GiImageControl);
      GiImageControl := nil;
    end;
    if AnimImageControl <> nil then
    begin
      FreeOwnedChild(AnimImageControl);
      AnimImageControl := nil;
    end;
    if GaiImageControl <> nil then
    begin
      FreeOwnedChild(GaiImageControl);
      GaiImageControl := nil;
    end;
    if GraphBufControl <> nil then
    begin
      FreeOwnedChild(GraphBufControl);
      GraphBufControl := nil;
    end;
    if Path = '' then
    begin
      ImagePath := '';
      Invalidate;
    end
    else
    begin
      ImagePath := Path;
      Mode := ExtractNextDelimitedPartW(Path, ',');
      if Mode = 'GraphBuf' then
      begin
        GraphBufControl := TGraphBufGI.Create(Self, False);
        GraphBufControl.SetSize(ClientSize);
        GraphBufControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Path = '' then
      begin
        SimpleImageControl := TSimpleImageGI.Create(Self);
        SimpleImageControl.SetImagePath(Mode);
        SimpleImageControl.SetSize(ClientSize);
        SimpleImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Simple' then
      begin
        SimpleImageControl := TSimpleImageGI.Create(Self);
        SimpleImageControl.SetImagePath(Path);
        SimpleImageControl.SetSize(ClientSize);
        SimpleImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Trans' then
      begin
        TransImageControl := TTransImageGI.Create(Self);
        TransImageControl.SetImagePath(Path);
        TransImageControl.SetSize(ClientSize);
        TransImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Alpha' then
      begin
        AlphaImageControl := TAlphaImageGI.Create(Self);
        AlphaImageControl.SetImagePath(Path);
        AlphaImageControl.SetSize(ClientSize);
        AlphaImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'GI' then
      begin
        GiImageControl := TgiGI.Create(Self);
        GiImageControl.SetImagePath(Path);
        GiImageControl.SetSize(ClientSize);
        GiImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Anim' then
      begin
        AnimImageControl := TAImageGI.Create(Self);
        AnimImageControl.SetConfigPath(Path);
        AnimImageControl.SetSize(ClientSize);
        AnimImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'GAI' then
      begin
        GaiImageControl := TgaiGI.Create(Self);
        GaiImageControl.SetImagePath(Path);
        GaiImageControl.SetSize(ClientSize);
        GaiImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
        if GaiImageControl.GetSequenceCount > 0 then
        begin
          GaiImageControl.SequenceIndex := 0;
          GaiImageControl.UpdateAutoGeometry;
          GaiImageControl.RestartPlayback;
        end;
      end
      else
        raise Exception.Create('TImageGI.SetImage. Path=' + Path);
    end;
  end;
end;

function TImageGI.GetImagePath: WideString;
begin
  Result := ImagePath;
end;

function TImageGI.GetContentSize: TPoint;
begin
  if SimpleImageControl <> nil then
    Result := SimpleImageControl.GetContentSize
  else if TransImageControl <> nil then
    Result := TransImageControl.GetContentSize
  else if AlphaImageControl <> nil then
    Result := AlphaImageControl.GetContentSize
  else if GiImageControl <> nil then
    Result := GiImageControl.GetContentSize
  else if AnimImageControl <> nil then
    Result := AnimImageControl.GetContentSize
  else if GaiImageControl <> nil then
    Result := GaiImageControl.GetContentSize
  else if GraphBufControl <> nil then
    Result := Classes.Point(GraphBufControl.GraphBuf.Width, GraphBufControl.GraphBuf.Height)
  else
    Result := Classes.Point(0, 0);
end;

function TImageGI.GetContentOrigin: TPoint;
begin
  if GiImageControl <> nil then
    Result := GiImageControl.GetContentOrigin
  else
    Result := Classes.Point(0, 0);
end;

procedure TImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if SimpleImageControl <> nil then
    SimpleImageControl.SetImageKindX(Value)
  else if TransImageControl <> nil then
    TransImageControl.SetImageKindX(Value)
  else if AlphaImageControl <> nil then
    AlphaImageControl.SetImageKindX(Value)
  else if GiImageControl <> nil then
    GiImageControl.SetImageKindX(Value)
  else if AnimImageControl <> nil then
    AnimImageControl.SetImageKindX(Value)
  else if GaiImageControl <> nil then
    GaiImageControl.SetImageKindX(Value)
  else if GraphBufControl <> nil then
    GraphBufControl.SetImageKindX(Value);
end;

procedure TImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if SimpleImageControl <> nil then
    SimpleImageControl.SetImageKindY(Value)
  else if TransImageControl <> nil then
    TransImageControl.SetImageKindY(Value)
  else if AlphaImageControl <> nil then
    AlphaImageControl.SetImageKindY(Value)
  else if GiImageControl <> nil then
    GiImageControl.SetImageKindY(Value)
  else if AnimImageControl <> nil then
    AnimImageControl.SetImageKindY(Value)
  else if GaiImageControl <> nil then
    GaiImageControl.SetImageKindY(Value)
  else if GraphBufControl <> nil then
    GraphBufControl.SetImageKindY(Value);
end;

procedure TImageGI.SetHalfAlpha(Value: Boolean);
begin
  if SimpleImageControl <> nil then
    SimpleImageControl.SetHalfAlpha(Value)
  else if TransImageControl <> nil then
    TransImageControl.SetHalfAlpha(Value)
  else if AnimImageControl <> nil then
    AnimImageControl.SetHalfAlpha(Value);
end;

function TImageGI.GetAlpha: Byte;
begin
  if GiImageControl <> nil then
    Result := GiImageControl.Alpha
  else if GaiImageControl <> nil then
    Result := GaiImageControl.Alpha
  else
    Result := 255;
end;

procedure TImageGI.SetAlpha(Value: Byte);
begin
  if GiImageControl <> nil then
    GiImageControl.SetAlpha(Value)
  else if GaiImageControl <> nil then
    GaiImageControl.SetAlpha(Value);
end;

procedure TImageGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if SimpleImageControl <> nil then
    SimpleImageControl.SetSize(Size)
  else if TransImageControl <> nil then
    TransImageControl.SetSize(Size)
  else if AlphaImageControl <> nil then
    AlphaImageControl.SetSize(Size)
  else if GiImageControl <> nil then
    GiImageControl.SetSize(Size)
  else if AnimImageControl <> nil then
    AnimImageControl.SetSize(Size)
  else if GaiImageControl <> nil then
    GaiImageControl.SetSize(Size)
  else if GraphBufControl <> nil then
    GraphBufControl.SetSize(Size);
end;

procedure TImageGI.SetOrigin(Origin: TPoint);
var
  Position: TPoint;
begin
  inherited SetOrigin(Origin);
  Position.X := -Origin.X;
  Position.Y := -Origin.Y;
  if SimpleImageControl <> nil then
    SimpleImageControl.SetPosition(Position)
  else if TransImageControl <> nil then
    TransImageControl.SetPosition(Position)
  else if AlphaImageControl <> nil then
    AlphaImageControl.SetPosition(Position)
  else if GiImageControl <> nil then
    GiImageControl.SetPosition(Position)
  else if AnimImageControl <> nil then
    AnimImageControl.SetPosition(Position)
  else if GaiImageControl <> nil then
    GaiImageControl.SetPosition(Position)
  else if GraphBufControl <> nil then
    GraphBufControl.SetPosition(Position);
end;

function TImageGI.HitTestPixel(Point: TPoint): Boolean;
begin
  if AlphaImageControl <> nil then
    Result := AlphaImageControl.HitTestPixel(Point)
  else if AnimImageControl <> nil then
    Result := AnimImageControl.HitTest(Point)
  else if GiImageControl <> nil then
    Result := GiImageControl.HitTestPixel(Point)
  else if GaiImageControl <> nil then
    Result := GaiImageControl.HitTestPixel(Point)
  else
    Result := False;
end;

function TImageGI.GetVisualCenter: TPoint;
begin
  if GiImageControl <> nil then
    Result := GiImageControl.GetVisualCenter
  else if GraphBufControl <> nil then
    Result := GraphBufControl.GetVisualCenter;
end;

procedure TImageGI.RestartPlayback;
begin
  if GaiImageControl <> nil then
    GaiImageControl.RestartPlayback;
end;

procedure TImageGI.StopPlayback;
begin
  if GaiImageControl <> nil then
    GaiImageControl.StopAutoPlayback;
end;

procedure TImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;

procedure TImageGI.LoadImageProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then
    SetImagePath(Block.GetParam('Image'));
  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('HalfAlpha') > 0 then
    SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
  if Block.CountParams('Auto') > 0 then
    AutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
end;

procedure TImageGI.UpdateAutoGeometry;
begin
  inherited UpdateAutoGeometry;
  if (AutoUpdateFlags and agfPosition) = agfPosition then
    SetPosition(Parent.ToLocalPoint(GetContentOrigin));
  if (AutoUpdateFlags and agfSize) = agfSize then
    SetSize(GetContentSize);
end;

procedure TImageGI.QueueImageLoad(PendingLoads: TList);
begin
  if SimpleImageControl <> nil then
    SimpleImageControl.QueueImageLoad(PendingLoads)
  else if TransImageControl <> nil then
    TransImageControl.QueueImageLoad(PendingLoads)
  else if AlphaImageControl <> nil then
    AlphaImageControl.QueueImageLoad(PendingLoads)
  else if AnimImageControl <> nil then
    AnimImageControl.QueueImageLoad(PendingLoads)
  else if GaiImageControl <> nil then
    GaiImageControl.QueueImageLoad(PendingLoads);
end;

procedure TImageGI.SetHardwareMirrorHorizontal(Value: Boolean);
begin
  if GaiImageControl <> nil then
    GaiImageControl.SetHardwareMirrorHorizontal(Value)
  else if GiImageControl <> nil then
    GiImageControl.SetHardwareMirrorHorizontal(Value);
end;

end.
