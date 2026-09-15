{$EXCESSPRECISION OFF}
unit GI_SimpleImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheBitmap,
  GI_Main,
  GI_MessageLoop,
  Types;
type
  TSimpleImageGI = class;
  TSimpleImageGI = class(TObjectGI)
    ImageCache: TCBitmapControlEC;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    HalfAlpha: Boolean;
    SourceRGBA: Boolean;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(const ImagePath: WideString);
    function GetContentSize: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetHalfAlpha(Value: Boolean);
  end;
implementation
uses
  Math,
  EC_Str,
  EC_Mem,
  GlobalsV,
  GR_Main,
  GR_DX,
  SysUtils;

constructor TSimpleImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
end;

destructor TSimpleImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TSimpleImageGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
  SourceRGBA := False;
  inherited Clear;
end;

procedure TSimpleImageGI.SetImagePath(const ImagePath: WideString);
begin
  Invalidate;
  ImageCache.SetCacheKey(ImagePath);
  if Length(ImagePath) >= 4 then
    SourceRGBA := Copy(ImagePath, Length(ImagePath) - 4 + 1, 4) = 'RGBA';
end;

function TSimpleImageGI.GetContentSize: TPoint;
var
  Bitmap: TCBitmapEC;
begin
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    Result := Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height);
  finally
    ImageCache.Release;
  end;
end;

procedure TSimpleImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;

procedure TSimpleImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;

procedure TSimpleImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    Invalidate;
  end;
end;

procedure TSimpleImageGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Bitmap: TCBitmapEC;
  Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
    ImageCache.SetCacheKey(Block.GetParam('Image'));
    Bitmap := AcquireOrCreateBitmap(ImageCache);
    try
      SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
    finally
      ImageCache.Release;
    end;
  end;
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    SetSize(
        Classes.Point(
            StrToInt(ExtractDelimitedPartW(Text, 0, ',')),
            StrToInt(ExtractDelimitedPartW(Text, 1, ','))
        )
    );
  end;
  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('HalfAlpha') > 0 then
    SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;

procedure TSimpleImageGI.LoadFromBlock(Block: TBlockParEC);
var
  Bitmap: TCBitmapEC;
  Text: WideString;
begin
  inherited LoadFromBlock(Block);
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
  finally
    ImageCache.Release;
  end;
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    SetSize(
        Classes.Point(
            StrToInt(ExtractDelimitedPartW(Text, 0, ',')),
            StrToInt(ExtractDelimitedPartW(Text, 1, ','))
        )
    );
  end;
  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('HalfAlpha') > 0 then
    SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;

procedure TSimpleImageGI.Draw(ClipRect: TRect);
var
  Bitmap: TCBitmapEC;
  Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    Width := Bitmap.Bitmap.Width;
    Height := Bitmap.Bitmap.Height;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > ClipRect.Left do
        Dec(Left, Width);
    end
    else if ImageKindX = ikxLeft then
    begin
      Left := HitTestBounds.Left;
      Right := Left + Width;
    end
    else if ImageKindX = ikxRight then
    begin
      Right := HitTestBounds.Right;
      Left := Right - Width;
    end
    else if ImageKindX = ikxCenter then
    begin
      Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
      Right := Left + Width;
    end
    else
    begin
      Exit;
    end;
    if ImageKindY = ikyTopFill then
    begin
      Top := HitTestBounds.Top;
      Bottom := HitTestBounds.Bottom;
    end
    else if ImageKindY = ikyBottomFill then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom;
      while Top > ClipRect.Top do
        Dec(Top, Height);
    end
    else if ImageKindY = ikyTop then
    begin
      Top := HitTestBounds.Top;
      Bottom := Top + Height;
    end
    else if ImageKindY = ikyBottom then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom - Height;
    end
    else if ImageKindY = ikyCenter then
    begin
      Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
      Bottom := Top + Height;
    end
    else
    begin
      Exit;
    end;
    if HardwareRenderingEnabled then
    begin
      Y := Top;
      while (Y < Bottom) do
      begin
        X := Left;
        while (X < Right) do
        begin
          DrawTexture(Bitmap.Bitmap.GetTexture, X, Y, 255, $FFFFFF, @ClipRect, False, False);
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end
    else if SourceRGBA then
    begin
      Y := Top;
      while (Y < Bottom) do
      begin
        X := Left;
        while (X < Right) do
        begin
          DrawAlphaGraphBuffer16Clipped(
              ScreenRenderBuffer.GetPixels,
              ScreenRenderBuffer.PitchBytes,
              X,
              Y,
              Bitmap.Bitmap,
              ClipRect
          );
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end
    else
    begin
      Y := Top;
      while (Y < Bottom) do
      begin
        X := Left;
        while (X < Right) do
        begin
          CopyGraphBuffer16Clipped(
              ScreenRenderBuffer.GetPixels,
              ScreenRenderBuffer.PitchBytes,
              X,
              Y,
              Bitmap.Bitmap,
              ClipRect,
              HalfAlpha,
              False
          );
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end;
  finally
    ImageCache.Release;
  end;
end;

procedure TSimpleImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;

end.
