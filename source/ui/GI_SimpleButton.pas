{$EXCESSPRECISION OFF}
unit GI_SimpleButton;
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
  TSimpleButtonGI = class;
  TSimpleButtonGI = class(TObjectGI)
    CurrentImage: TCBitmapControlEC;
    NormalImage: TCBitmapControlEC;
    ActiveImage: TCBitmapControlEC;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
  end;
implementation
uses
  Math,
  GR_Main,
  GI_Main;

constructor TSimpleButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  NormalImage := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(NormalImage);
  ActiveImage := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ActiveImage);
end;

destructor TSimpleButtonGI.Destroy;
begin
  NormalImage.Free;
  NormalImage := nil;
  ActiveImage.Free;
  ActiveImage := nil;
  inherited Destroy;
end;

procedure TSimpleButtonGI.Clear;
begin
  inherited Clear;
end;

procedure TSimpleButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  CurrentImage := ActiveImage;
  Invalidate;
end;

procedure TSimpleButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  CurrentImage := NormalImage;
  Invalidate;
end;

procedure TSimpleButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  DispatchNamedEvent(1, Point.X, Point.Y);
end;

procedure TSimpleButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  DispatchNamedEvent(2, Point.X, Point.Y);
end;

procedure TSimpleButtonGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Bitmap: TCBitmapEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
    NormalImage.SetCacheKey(Block.GetParam('Image'));
    Bitmap := AcquireOrCreateBitmap(NormalImage);
    try
      SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
    finally
      NormalImage.Release;
    end;
  end;
  if Block.CountParams('ImageActive') > 0 then
    ActiveImage.SetCacheKey(Block.GetParam('ImageActive'));
end;

procedure TSimpleButtonGI.LoadFromBlock(Block: TBlockParEC);
var
  Bitmap: TCBitmapEC;
begin
  inherited LoadFromBlock(Block);
  NormalImage.SetCacheKey(Block.GetParam('Image'));
  Bitmap := AcquireOrCreateBitmap(NormalImage);
  try
    SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
  finally
    NormalImage.Release;
  end;
  ActiveImage.SetCacheKey(Block.GetParam('ImageActive'));
  CurrentImage := NormalImage;
end;

procedure TSimpleButtonGI.Draw(ClipRect: TRect);
var
  Bitmap: TCBitmapEC;
begin
  if CurrentImage <> nil then
  begin
    Bitmap := AcquireOrCreateBitmap(CurrentImage);
    try
      Ex_OKGR_Copy_XY_XY_WORD(
          ScreenRenderBuffer.GetPixels,
          ScreenRenderBuffer.PitchBytes,
          ClipRect.Left,
          ClipRect.Top,
          Bitmap.Bitmap.GetPixels,
          Bitmap.Bitmap.PitchBytes,
          ClipRect.Left - HitTestBounds.Left,
          ClipRect.Top - HitTestBounds.Top,
          ClipRect.Right - ClipRect.Left,
          ClipRect.Bottom - ClipRect.Top
      );
    finally
      CurrentImage.Release;
    end;
  end;
end;

procedure TSimpleButtonGI.QueueImageLoad(PendingLoads: TList);
begin
  NormalImage.QueueLoadIfMissing(PendingLoads);
  ActiveImage.QueueLoadIfMissing(PendingLoads);
end;

end.
