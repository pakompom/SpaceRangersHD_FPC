{$EXCESSPRECISION OFF}
unit GI_InfiniteImage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheBitmap,
  GI_MessageLoop,
  Types;
type
  TInfiniteImageGI = class;
  TInfiniteImageGI = class(TObjectGI)
    ImageCache: TCBitmapControlEC;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(Path: WideString);
    procedure LoadImageProperties(Block: TBlockParEC);
  end;
implementation
uses
  GlobalsV,
  Math,
  GR_Main,
  GI_Main,
  EC_Cache;

constructor TInfiniteImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
end;

destructor TInfiniteImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TInfiniteImageGI.SetImagePath(Path: WideString);
begin
  SetSize(Classes.Point(2000000000, 2000000000));
  SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
  ImageCache.SetCacheKey(Path);
end;

procedure TInfiniteImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TInfiniteImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;

procedure TInfiniteImageGI.LoadImageProperties(Block: TBlockParEC);
begin
  SetSize(Classes.Point(2000000000, 2000000000));
  SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
  if Block.CountParams('Image') > 0 then
    SetImagePath(Block.GetParam('Image'));
end;

procedure TInfiniteImageGI.Draw(ClipRect: TRect);
var
  StartY, StartX: Integer;
  Image: TCBitmapEC;
  Width, Height, X, Y: Integer;
begin
  Image := AcquireOrCreateBitmap(ImageCache);
  try
    Width := Image.Bitmap.Width;
    Height := Image.Bitmap.Height;
    StartX := Floor((ClipRect.Left - AbsolutePosition.X) / Width) * Width + AbsolutePosition.X;
    StartY := Floor((ClipRect.Top - AbsolutePosition.Y) / Height) * Height + AbsolutePosition.Y;
    if HardwareRenderingEnabled then
    begin
      Y := StartY;
      while Y < ClipRect.Bottom do
      begin
        X := StartX;
        while X < ClipRect.Right do
        begin
          { This native path only logs; it does not draw a hardware tile. }
          AppendLogLineThreadSafe('InfiniteImageDraw');
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end
    else
    begin
      Y := StartY;
      while Y < ClipRect.Bottom do
      begin
        X := StartX;
        while X < ClipRect.Right do
        begin
          CopyGraphBuffer16Clipped(
              ScreenRenderBuffer.GetPixels,
              ScreenRenderBuffer.PitchBytes,
              X,
              Y,
              Image.Bitmap,
              ClipRect,
              False,
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

procedure TInfiniteImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;

end.
