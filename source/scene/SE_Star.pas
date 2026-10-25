unit SE_Star;

{$I GameOptions.inc}

interface

uses
  Types,
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  GI_Image,
  GI_GI,
  GI_MessageLoop,
  SE_Space;

type
  TStarSE = class;
  
  TStarGaiGI = class(TgaiGI)
  public
    procedure Draw(ClipRect: TRect); override;
  end;

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
  GlobalsV,
  Globals,
  GR_Main,
  GI_Main,
  EC_Str,
  GameDiagnostics,
  SysUtils,
  GR_DX,
  Direct3D9,
  EC_CacheGAI;
  
procedure TStarGaiGI.Draw(ClipRect: TRect);
var
  Image: TCGaiEC;
  Texture: IDirect3DTexture9;
  Desc: TD3DSurfaceDesc;
  FrameOrigin: TPoint;
  BaseSize, DrawSize: TPoint;
  Left, Top, X, Y: Integer;
  ScaleFactor: Integer;
begin
  if not HardwareRenderingEnabled then
  begin
    inherited Draw(ClipRect);
    Exit;
  end;

  if (SequenceFrame < 0) or (SequenceFrame >= SequenceFrameCount) then
    Exit;

  Image := AcquireCachedGai(MainImageCache);
  if Image = nil then
  begin
    inherited Draw(ClipRect);
    Exit;
  end;

  try
    Texture := Image.GetOrCreateFrameSurface(GetSequenceFrameSourceIndex(SequenceFrame));
    if Texture = nil then
    begin
      inherited Draw(ClipRect);
      Exit;
    end;

    FrameOrigin := Image.GetFrameOrigin(GetSequenceFrameSourceIndex(SequenceFrame));
    
    BaseSize := Image.GetCanvasSize;
    ScaleFactor := 3;
    DrawSize.X := BaseSize.X * ScaleFactor;
    DrawSize.Y := BaseSize.Y * ScaleFactor;

    // Центрируем (ikxCenter / ikyCenter)
    Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - DrawSize.X div 2;
    Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - DrawSize.Y div 2;

    // Учитываем FrameOrigin, умноженный на масштаб
    X := Left + FrameOrigin.X * ScaleFactor;
    Y := Top + FrameOrigin.Y * ScaleFactor;

    Texture.GetLevelDesc(0, Desc);
    
    DrawTextureSized(
      Texture,
      X,
      Y,
      Desc.Width * ScaleFactor,
      Desc.Height * ScaleFactor,
      Alpha,
      RgbWhite,
      @ClipRect,
      False,
      HardwareMirrorHorizontal
    );
  finally
    MainImageCache.Release;
  end;
end;

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
    StaticImage.SetSize(Classes.Point(StaticImage.GetContentSize.X * 3, StaticImage.GetContentSize.Y * 3));
    StaticImage.AutoUpdateFlags := StaticImage.AutoUpdateFlags and (not $02);
	StaticImage.SetOrigin(Classes.Point(StaticImage.ClientSize.X div 2, StaticImage.ClientSize.Y div 2));
    StaticImage.SetOrigin(HalfPoint(StaticImage.ClientSize));
  end
  else
  begin
    Animation := TStarGaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(AnimationPath);
    Animation.LoadFrameSequenceFromText('[65,0-' + IntToWideString(Animation.GetMainImageFrameCount - 1) + ']');
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetSize(Classes.Point(Animation.GetContentSize.X * 3, Animation.GetContentSize.Y * 3));
    Animation.AutoUpdateFlags := Animation.AutoUpdateFlags and (not $02);
	Animation.SetOrigin(Classes.Point(Animation.ClientSize.X div 2, Animation.ClientSize.Y div 2));
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetSequenceFrame(SavedSequenceFrameIndex);
    Animation.RestartPlayback;
  end;
  MapImage := TgiGI.Create(SpaceObjectUiLoop.ContentPanel);
  MapImage.SetPositionModeW(True);
  MapImage.SetDepthByName(DepthExpression);
  MapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
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
    MapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
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
