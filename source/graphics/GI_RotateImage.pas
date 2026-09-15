{$EXCESSPRECISION OFF}
unit GI_RotateImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheBitmap,
  EC_CacheRotateBuf,
  GI_MessageLoop,
  Types;
type
  TRotateImageGI = class;
  TRotateImageGI = class(TObjectGI)
    ImageCache: TCBitmapControlEC;
    RotationCache: TCRotateBufControlEC;
    Angle: Byte;
    Gap129: array[0..2] of Byte;
    procedure Clear; override;
    procedure UpdateHitTestBounds; override;
    function GetLocalBounds: TRect; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetAngle(Value: Byte);
    procedure SetImage(Path: WideString; ImageSize: TPoint);
  end;
implementation
uses
  Math,
  SysUtils,
  GR_Main,
  GI_Main,
  GlobalsV;

constructor TRotateImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
end;

destructor TRotateImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  inherited Destroy;
end;

procedure TRotateImageGI.Clear;
begin
  Angle := 0;
  inherited Clear;
end;

procedure TRotateImageGI.SetAngle(Value: Byte);
begin
  if Value = Angle then
    Exit;
  if not Active then
    Angle := Value
  else
  begin
    Invalidate;
    Angle := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;

procedure TRotateImageGI.UpdateHitTestBounds;
var
  Rotation: TCRotateBufEC;
begin
  if RotationCache.HasEmptyCacheKey then
    Exit;
  Rotation := AcquireOrCreateRotateBuf(RotationCache);
  try
    Ex_OKGR_RotateBuf_Size(
        AbsolutePosition.X,
        AbsolutePosition.Y,
        Angle,
        Rotation.Buffer,
        HitTestBounds
    );
    Inc(HitTestBounds.Right);
    Inc(HitTestBounds.Bottom);
  finally
    RotationCache.Release;
  end;
end;

function TRotateImageGI.GetLocalBounds: TRect;
var
  Rotation: TCRotateBufEC;
begin
  if RotationCache.HasEmptyCacheKey then
    Exit;
  Rotation := AcquireOrCreateRotateBuf(RotationCache);
  try
    Ex_OKGR_RotateBuf_Size(LocalPosition.X, LocalPosition.Y, Angle, Rotation.Buffer, Result);
    Inc(Result.Right);
    Inc(Result.Bottom);
  finally
    RotationCache.Release;
  end;
end;

procedure TRotateImageGI.SetImage(Path: WideString; ImageSize: TPoint);
var
  Bitmap: TCBitmapEC;
begin
  ImageCache.SetCacheKey(Path);
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    RotationCache.SetCacheKey(
        IntToStr(ImageSize.X)
            + ','
            + IntToStr(ImageSize.Y)
            + ','
            + IntToStr(Cardinal(Bitmap.Bitmap.Width))
            + ','
            + IntToStr(Cardinal(Bitmap.Bitmap.Height))
            + ','
            + IntToStr(OriginPoint.X)
            + ','
            + IntToStr(OriginPoint.Y)
    );
    SetSize(ImageSize);
  finally
    ImageCache.Release;
  end;
end;

procedure TRotateImageGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if (Block.CountParams('Image') > 0) and (Block.CountParams('Size') > 0) then
    SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Angle') > 0 then
    Angle := StrToInt(Block.GetParam('Angle'));
end;

procedure TRotateImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  Angle := 1;
  SetAngle(0);
  SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Angle') > 0 then
    Angle := StrToInt(Block.GetParam('Angle'));
end;

procedure TRotateImageGI.Draw(ClipRect: TRect);
var
  Bitmap: TCBitmapEC;
  Rotation: TCRotateBufEC;
  Rect: TRect;
begin
  if HitTestBounds.Left + ClientSize.X < 0 then
    Exit;
  if HitTestBounds.Left - ClientSize.X div 2 > GameScreenWidth then
    Exit;
  if HitTestBounds.Top + ClientSize.Y < 0 then
    Exit;
  if HitTestBounds.Top - ClientSize.Y div 2 > GameScreenHeight then
    Exit;
  Bitmap := nil;
  Rotation := nil;
  try
    Bitmap := AcquireOrCreateBitmap(ImageCache);
    Rotation := AcquireOrCreateRotateBuf(RotationCache);
    Rect.Left := ClipRect.Left;
    Rect.Top := ClipRect.Top;
    Rect.Right := ClipRect.Right - 1;
    Rect.Bottom := ClipRect.Bottom - 1;
    Ex_OKGR_RotateBuf_DrawTransClip_WORD(
        ScreenRenderBuffer.GetPixels,
        ScreenRenderBuffer.PitchBytes,
        Bitmap.Bitmap.GetPixels,
        Bitmap.Bitmap.PitchBytes,
        AbsolutePosition.X,
        AbsolutePosition.Y,
        Angle,
        Rotation.Buffer,
        Rect
    );
  finally
    if Bitmap <> nil then
      ImageCache.Release;
    if Rotation <> nil then
      RotationCache.Release;
  end;
end;

procedure TRotateImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
  RotationCache.QueueLoadIfMissing(PendingLoads);
end;

end.
