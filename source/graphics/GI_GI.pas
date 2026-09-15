{$EXCESSPRECISION OFF}
unit GI_GI;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheGI,
  GI_Main,
  GI_MessageLoop,
  GR_GraphBuf,
  Types;
type
  TgiGI = class;
  TgiGI = class(TObjectGI)
    ImageCache: TCGiControlEC;
    ImageKindX: TImageKindXGI;
    ImageKindY: TImageKindYGI;
    Alpha: Byte;
    HardwareMirrorHorizontal: Boolean;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(const ImagePath: WideString);
    function GetImagePath: WideString;
    function GetContentSize: TPoint;
    function GetContentOrigin: TPoint;
    procedure SetImageKindX(Value: TImageKindXGI);
    procedure SetImageKindY(Value: TImageKindYGI);
    procedure SetAlpha(Value: Byte);
    function HitTestPixel(Point: TPoint): Boolean;
    function GetVisualCenter: TPoint;
    procedure LoadImageProperties(Block: TBlockParEC);
    procedure SetHardwareMirrorHorizontal(Value: Boolean);
  end;
procedure LoadGiByPathIntoGraphBuf(const GiPath: WideString; Destination: TGraphBufGR);
implementation
uses
  Math,
  EC_Cache,
  EC_Mem,
  GR_Main,
  GR_DX,
  GlobalsV;

constructor TgiGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCGiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  Alpha := 255;
end;

destructor TgiGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TgiGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  inherited Clear;
end;

procedure TgiGI.SetImagePath(const ImagePath: WideString);
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
  end;
end;

function TgiGI.GetImagePath: WideString;
begin
  Result := ImageCache.CacheKey;
end;

function TgiGI.GetContentSize: TPoint;
var
  Image: TCGiEC;
begin
  Image := AcquireCachedGi(ImageCache);
  try
    Result := Image.Image.GetContentSize;
  finally
    ImageCache.Release;
  end;
end;

function TgiGI.GetContentOrigin: TPoint;
var
  Image: TCGiEC;
  Bounds: TRect;
begin
  Image := AcquireCachedGi(ImageCache);
  try
    Bounds := Image.Image.GetBoundsRect;
    Result := Bounds.TopLeft;
  finally
    ImageCache.Release;
  end;
end;

procedure TgiGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;

procedure TgiGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;

procedure TgiGI.SetAlpha(Value: Byte);
begin
  if Alpha <> Value then
  begin
    Alpha := Value;
    Invalidate;
  end;
end;

function TgiGI.HitTestPixel(Point: TPoint): Boolean;
var
  Image: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
  Pixel: Cardinal;
  Pixels: Pointer;
  Buffer: TGraphBufGR;
  Clip: TRect;
begin
  Result := False;
  Pixel := 0;
  Clip.Left := Point.X;
  Clip.Top := Point.Y;
  Clip.Right := Point.X + 1;
  Clip.Bottom := Point.Y + 1;
  Image := AcquireCachedGi(ImageCache);
  try
    Width := Image.Image.GetContentSize.X;
    Height := Image.Image.GetContentSize.Y;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > Clip.Left do
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
      while Top > Clip.Top do
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
    Pixels :=
        AddPointerOffset(
            @Pixel,
            -(ScreenRenderBuffer.PitchBytes * Point.Y + Point.X * SizeOf(Word))
        );
    Buffer := TGraphBufGR.Create(False);
    Buffer.AttachPixels(1, 1, ScreenRenderBuffer.PitchBytes, Pixels);
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Image.Image.DrawToGraphBuf(Buffer, X, Y, Clip, 0, 255);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
    Buffer.Free;
  finally
    ImageCache.Release;
  end;
  Result := Pixel <> 0;
end;

function TgiGI.GetVisualCenter: TPoint;
var
  Buffer: TGraphBufGR;
  Image: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y, Count: Integer;
  SavedBounds, Clip: TRect;
begin
  SavedBounds := HitTestBounds;
  Dec(HitTestBounds.Right, HitTestBounds.Left);
  Dec(HitTestBounds.Bottom, HitTestBounds.Top);
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  Clip := HitTestBounds;
  Buffer := TGraphBufGR.Create(False);
  Buffer.AllocateNative(HitTestBounds.Right, HitTestBounds.Bottom);
  Image := AcquireCachedGi(ImageCache);
  try
    Width := Image.Image.GetContentSize.X;
    Height := Image.Image.GetContentSize.Y;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > Clip.Left do
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
      while Top > Clip.Top do
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
    Buffer.ClearPixels;
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Image.Image.DrawToGraphBuf(Buffer, X, Y, Clip, 0, 255);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  finally
    ImageCache.Release;
  end;
  Result.X := 0;
  Result.Y := 0;
  Count := 0;
  for Y := 0 to Buffer.Height - 1 do
    for X := 0 to Buffer.Width - 1 do
      if Buffer.GetPixel16(X, Y) <> 0 then
      begin
        Inc(Result.X, X);
        Inc(Result.Y, Y);
        Inc(Count);
      end;
  Buffer.Free;
  HitTestBounds := SavedBounds;
  if Count < 1 then
    Result := Classes.Point(0, 0)
  else
    Result := Classes.Point(Result.X div Count, Result.Y div Count);
end;

procedure TgiGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TgiGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;

procedure TgiGI.LoadImageProperties(Block: TBlockParEC);
begin
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('KindX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then
    SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then
    SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
end;

procedure TgiGI.SetHardwareMirrorHorizontal(Value: Boolean);
begin
  HardwareMirrorHorizontal := Value;
end;

procedure TgiGI.Draw(ClipRect: TRect);
var
  Image: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y, TileIndex: Integer;
  TileOrigin: TPoint;
begin
  Image := AcquireCachedGi(ImageCache);
  try
    Width := Image.Image.GetContentSize.X;
    Height := Image.Image.GetContentSize.Y;
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
      if Image.UsesTiledSurfaces then
      begin
        while Y < Bottom do
        begin
          X := Left;
          while X < Right do
          begin
            TileIndex := 0;
            while TileIndex < Image.TileCount do
            begin
              TileOrigin := Image.GetTileOrigin(TileIndex);
              DrawTexture(
                  Image.GetOrCreateSurface(TileIndex),
                  X + TileOrigin.X,
                  Y + TileOrigin.Y,
                  Alpha,
                  $FFFFFF,
                  @ClipRect,
                  False,
                  HardwareMirrorHorizontal
              );
              Inc(TileIndex);
            end;
            Inc(X, Width);
          end;
          Inc(Y, Height);
        end;
      end
      else
      begin
        while Y < Bottom do
        begin
          X := Left;
          while X < Right do
          begin
            DrawTexture(
                Image.GetOrCreateSurface(0),
                X,
                Y,
                Alpha,
                $FFFFFF,
                @ClipRect,
                False,
                HardwareMirrorHorizontal
            );
            Inc(X, Width);
          end;
          Inc(Y, Height);
        end;
      end;
    end
    else
    begin
      Y := Top;
      while Y < Bottom do
      begin
        X := Left;
        while X < Right do
        begin
          Image.Image.DrawToGraphBuf(ScreenRenderBuffer, X, Y, ClipRect, 0, Alpha);
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end;
  finally
    ImageCache.Release;
  end;
end;

procedure TgiGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;

procedure LoadGiByPathIntoGraphBuf(const GiPath: WideString; Destination: TGraphBufGR);
var
  Control: TCacheControlEC;
  Image: TCGiEC;
begin
  Control := TCGiControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(GiPath);
  Image := AcquireCachedGi(Control);
  try
    Image.Image.DecodeToGraphBuf(Destination, False);
  finally
    Control.Release;
  end;
  Control.Free;
end;

end.
