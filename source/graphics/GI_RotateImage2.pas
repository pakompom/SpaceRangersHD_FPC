{$EXCESSPRECISION OFF}
unit GI_RotateImage2;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  EC_CacheBitmap,
  EC_CacheRotateBuf,
  GI_MessageLoop,
  GR_GraphBuf,
  Types;
type
  TRotateImage2GI = class;
  TRotateImage2GI = class(TObjectGI)
    ImageCache: TCBitmapControlEC;
    RotationCache: TCRotateBufControlEC;
    RotatedImage: TGraphBufGR;
    RenderedAngle: Byte;
    Angle: Byte;
    Alpha: Byte;
    ImageDirty: Boolean;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetAngle(Value: Byte);
    procedure SetAlpha(Value: Byte);
    procedure SetImage(Path: WideString; ImageSize: TPoint; Pivot: TPoint);
    procedure LoadImageProperties(Block: TBlockParEC);
  end;
implementation
uses
  Classes,
  SysUtils,
  Math,
  EC_Cache,
  EC_Mem,
  GR_Main,
  GI_Main;

constructor TRotateImage2GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageDirty := True;
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
  RotatedImage := TGraphBufGR.Create(False);
  RenderedAngle := 0;
  Angle := 0;
  Alpha := 255;
  ImageDirty := True;
end;

destructor TRotateImage2GI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  RotatedImage.Free;
  RotatedImage := nil;
  inherited Destroy;
end;

procedure TRotateImage2GI.Clear;
begin
  ImageDirty := True;
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited Clear;
end;

procedure TRotateImage2GI.SetAngle(Value: Byte);
begin
  if Value <> Angle then
  begin
    Angle := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;

procedure TRotateImage2GI.SetAlpha(Value: Byte);
begin
  if Value <> Alpha then
  begin
    Alpha := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;

procedure TRotateImage2GI.SetImage(Path: WideString; ImageSize, Pivot: TPoint);
var
  Image: TCBitmapEC;
  Radius: Double;
begin
  ImageCache.SetCacheKey(Path + '?RGBA');
  Image := AcquireOrCreateBitmap(ImageCache);
  try
    RotationCache.SetCacheKey(
        IntToStr(ImageSize.X)
            + ','
            + IntToStr(ImageSize.Y)
            + ','
            + IntToStr(Cardinal(Image.Bitmap.Width))
            + ','
            + IntToStr(Cardinal(Image.Bitmap.Height))
            + ','
            + IntToStr(Pivot.X)
            + ','
            + IntToStr(Pivot.Y)
    );
    Radius := Sqr(Pivot.X - 0) + Sqr(Pivot.Y - 0);
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - 0));
    Radius := Max(Radius, Sqr(Pivot.X - 0) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Floor(Sqrt(Radius) * 2.0 + 2.0);
    SetSize(Classes.Point(Trunc(Radius), Trunc(Radius)));
    SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
    if (RotatedImage.Width <> ClientSize.X) or (RotatedImage.Height <> ClientSize.Y) then
      RotatedImage.AllocateRgbaTight(ClientSize.X, ClientSize.Y);
    ImageDirty := True;
  finally
    ImageCache.Release;
  end;
  Invalidate;
end;

procedure TRotateImage2GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TRotateImage2GI.LoadFromBlock(Block: TBlockParEC);
begin
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
  ImageDirty := True;
end;

procedure TRotateImage2GI.LoadImageProperties(Block: TBlockParEC);
begin
  if (Block.CountParams('Image') > 0)
      and (Block.CountParams('Size') > 0)
      and (Block.CountParams('Sme') > 0) then
    SetImage(
        Block.GetParam('Image'),
        GetPointGI(Block.GetParam('Size')),
        GetPointGI(Block.GetParam('Sme'))
    );
  if Block.CountParams('Angle') > 0 then
    SetAngle(StrToInt(Block.GetParam('Angle')));
  if Block.CountParams('Trans') > 0 then
    SetAlpha(StrToInt(Block.GetParam('Trans')));
end;

procedure TRotateImage2GI.Draw(ClipRect: TRect);
var
  Image: TCBitmapEC;
  Rotation: TCRotateBufEC;
begin
  if (HitTestBounds.Left + ClientSize.X < 0)
      or (HitTestBounds.Left - ClientSize.X div 2 > GameScreenWidth)
      or (HitTestBounds.Top + ClientSize.Y < 0)
      or (HitTestBounds.Top - ClientSize.Y div 2 > GameScreenHeight) then
    Exit;
  if (RenderedAngle <> Angle) or (ImageDirty = True) then
  begin
    ImageDirty := False;
    RenderedAngle := Angle;
    Image := nil;
    Rotation := nil;
    try
      Image := AcquireOrCreateBitmap(ImageCache);
      Rotation := AcquireOrCreateRotateBuf(RotationCache);
      RotatedImage.ClearPixels;
      Ex_OKGR_RotateBuf_Draw_DWORD(
          RotatedImage.GetPixels,
          RotatedImage.PitchBytes,
          Image.Bitmap.GetPixels,
          Image.Bitmap.PitchBytes,
          OriginPoint.X,
          OriginPoint.Y,
          Angle,
          Rotation.Buffer
      );
      if Alpha <> 255 then
        Ex_OKGR_Light_BYTE(
            AddPointerOffset(RotatedImage.GetPixels, 3),
            4,
            RotatedImage.PitchBytes - 4 * RotatedImage.Width,
            RotatedImage.Width,
            RotatedImage.Height,
            Alpha
        );
    finally
      if Image <> nil then
        ImageCache.Release;
      if Rotation <> nil then
        RotationCache.Release;
    end;
  end;
  DrawAlphaGraphBuffer16Clipped(
      ScreenRenderBuffer.GetPixels,
      ScreenRenderBuffer.PitchBytes,
      HitTestBounds.Left,
      HitTestBounds.Top,
      RotatedImage,
      ClipRect
  );
end;

end.
