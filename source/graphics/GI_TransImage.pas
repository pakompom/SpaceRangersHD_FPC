{$EXCESSPRECISION OFF}
unit GI_TransImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheTBitmap,
  GI_Main,
  GI_MessageLoop,
  Types;
type
  TTransImageGI = class;
  TTransImageGI = class(TObjectGI)
    ImageCache: TCTBitmapControlEC;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    HalfAlpha: Boolean;
    Gap127: array[0..0] of Byte;
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
constructor TTransImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCTBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
end;
destructor TTransImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
procedure TTransImageGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  inherited Clear;
end;
procedure TTransImageGI.SetImagePath(const ImagePath: WideString);
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
  end;
end;
function TTransImageGI.GetContentSize: TPoint;
var
  Bitmap: TCTBitmapEC;
begin
  Bitmap := AcquireCachedTransBitmap(ImageCache);
  try
    Result := Bitmap.PixelSize;
  finally
    ImageCache.Release;
  end;
end;
procedure TTransImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
procedure TTransImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
procedure TTransImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    Invalidate;
  end;
end;
procedure TTransImageGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Bitmap: TCTBitmapEC;
  Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
    ImageCache.SetCacheKey(Block.GetParam('Image'));
    Bitmap := AcquireCachedTransBitmap(ImageCache);
    try
      SetSize(Bitmap.PixelSize);
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
procedure TTransImageGI.LoadFromBlock(Block: TBlockParEC);
var
  Bitmap: TCTBitmapEC;
  Text: WideString;
begin
  inherited LoadFromBlock(Block);
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  Bitmap := AcquireCachedTransBitmap(ImageCache);
  try
    SetSize(Bitmap.PixelSize);
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
procedure TTransImageGI.Draw(ClipRect: TRect);
var
  Bitmap: TCTBitmapEC;
  Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Bitmap := AcquireCachedTransBitmap(ImageCache);
  try
    Width := Bitmap.PixelSize.X;
    Height := Bitmap.PixelSize.Y;
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

    AppendLogLineThreadSafe('Test');

    Y := Top;
    while (Y < Bottom) do
    begin
      X := Left;
      while (X < Right) do
      begin
        DrawTransparentBuffer16(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            X,
            Y,
            Bitmap.TransBuffer,
            ClipRect,
            HalfAlpha
        );
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  finally
    ImageCache.Release;
  end;
end;
procedure TTransImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
end.
