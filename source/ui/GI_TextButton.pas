{$EXCESSPRECISION OFF}
unit GI_TextButton;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheBitmap,
  EC_CacheFont,
  GI_MessageLoop,
  Types;
type
  TTextButtonGI = class;
  TTextButtonGI = class(TObjectGI)
    FontCache: TCFontControlEC;
    ImageCache: TCBitmapControlEC;
    Kind: Integer;
    Caption: WideString;
    CaptionColor: Cardinal;
    CaptionActiveColor: Cardinal;
    BorderLightColor: Cardinal;
    BorderDarkColor: Cardinal;
    Hover: Boolean;
    Down: Boolean;
    Gap142: array[0..5] of Byte;
    DownCallback: TObjectNotifyEventGI;
    UpCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
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
  SysUtils,
  EC_Str,
  GR_Main,
  GI_Main;

constructor TTextButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  CaptionColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  Kind := 0;
end;

destructor TTextButtonGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;

procedure TTextButtonGI.Clear;
begin
  inherited Clear;
  CaptionColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  Caption := '';
  MouseBlocking := True;
end;

procedure TTextButtonGI.OnActivate;
begin
  inherited OnActivate;
  if HitTestCursor then
    Hover := True
  else
    Hover := False;
  if Kind = 0 then
    Down := False;
  Invalidate;
end;

procedure TTextButtonGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Hover := False;
  Down := False;
  Invalidate;
end;

procedure TTextButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if not IsOccludedAtPoint(AbsolutePosition) then
  begin
    Hover := True;
    Invalidate;
  end;
end;

procedure TTextButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if Kind = 0 then
  begin
    if Down then
    begin
      Down := False;
      DispatchNamedEvent(2, 0, 0);
      if Assigned(UpCallback) then
        UpCallback(Self);
    end;
  end;
  Hover := False;
  Invalidate;
end;

procedure TTextButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if IsOccludedAtPoint(Point) then
    Exit;
  if Kind = 0 then
  begin
    Down := True;
    DispatchNamedEvent(1, Point.X, Point.Y);
    if Assigned(DownCallback) then
      DownCallback(Self);
  end
  else
  begin
    if Down then
    begin
      Down := False;
      DispatchNamedEvent(2, Point.X, Point.Y);
      if Assigned(UpCallback) then
        UpCallback(Self);
    end
    else
    begin
      Down := True;
      DispatchNamedEvent(1, Point.X, Point.Y);
      if Assigned(DownCallback) then
        DownCallback(Self);
    end;
  end;
  Invalidate;
end;

procedure TTextButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if IsOccludedAtPoint(Point) then
    Exit;
  if Kind = 0 then
  begin
    Down := False;
    Invalidate;
    DispatchNamedEvent(2, Point.X, Point.Y);
    if Assigned(UpCallback) then
      if MessageLoop.ConsumeTimerTickChange then
        UpCallback(Self);
  end;
end;

procedure TTextButtonGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Text: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then
    FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Caption := Block.GetParam('Caption');
    if LanguageDataConfig.CountParamsByPath(Caption) > 0 then
      Caption := LanguageDataConfig.GetParamByPathOrMarker(Caption);
  end;
  if Block.CountParams('Image') > 0 then
    ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('CaptionColor') > 0 then
  begin
    Text := Block.GetParam('CaptionColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CaptionActiveColor') > 0 then
  begin
    Text := Block.GetParam('CaptionActiveColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    Text := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    Text := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Normal' then
      Kind := 0
    else
      Kind := 1;
  end;
end;

procedure TTextButtonGI.LoadFromBlock(Block: TBlockParEC);
var
  Text: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Font') > 0 then
    FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Caption := Block.GetParam('Caption');
    if LanguageDataConfig.CountParamsByPath(Caption) > 0 then
      Caption := LanguageDataConfig.GetParamByPathOrMarker(Caption);
  end;
  if Block.CountParams('Image') > 0 then
    ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('CaptionColor') > 0 then
  begin
    Text := Block.GetParam('CaptionColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CaptionActiveColor') > 0 then
  begin
    Text := Block.GetParam('CaptionActiveColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    Text := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    Text := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Normal' then
      Kind := 0
    else
      Kind := 1;
  end;
end;

procedure TTextButtonGI.Draw(ClipRect: TRect);
var
  Font: TCFontEC;
  Bitmap: TCBitmapEC;
  Bounds: TRect;
begin
  Font := nil;
  Bitmap := nil;
  if FontCache <> nil then
  begin
    try
      Font := AcquireCachedFont(FontCache);
      Font.ResetTextMeasureState;
      if (ImageCache <> nil) and (ImageCache.CacheKey <> '') then
        Bitmap := AcquireOrCreateBitmap(ImageCache);
      Bounds := Font.MeasureTaggedTextBounds(Caption, 0, 0, nil);
      if Bitmap <> nil then
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
      if Hover = True then
        Font.DefaultColor := CaptionActiveColor
      else
        Font.DefaultColor := CaptionColor;
      Font.DrawTaggedText16(
          ScreenRenderBuffer.GetPixels,
          ScreenRenderBuffer.PitchBytes,
          (HitTestBounds.Left + HitTestBounds.Right) div 2 - (Bounds.Right - Bounds.Left) div 2,
          (HitTestBounds.Top + HitTestBounds.Bottom) div 2
              - (Bounds.Bottom - Bounds.Top) div 2
              - Bounds.Top,
          Caption,
          ClipRect
      );
      if not Down then
      begin
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Right - HitTestBounds.Left,
            BorderLightColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawVerticalLine16Clipped(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Bottom - HitTestBounds.Top,
            BorderLightColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            -(HitTestBounds.Right - HitTestBounds.Left - 1),
            BorderDarkColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawVerticalLine16Clipped(
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            -(HitTestBounds.Bottom - HitTestBounds.Top - 1),
            BorderDarkColor,
            ClipRect
        );
      end
      else
      begin
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Right - HitTestBounds.Left - 1,
            BorderDarkColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawVerticalLine16Clipped(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Bottom - HitTestBounds.Top - 1,
            BorderDarkColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            -(HitTestBounds.Right - HitTestBounds.Left),
            BorderLightColor,
            ClipRect
        );
        ScreenRenderBuffer.DrawVerticalLine16Clipped(
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            -(HitTestBounds.Bottom - HitTestBounds.Top),
            BorderLightColor,
            ClipRect
        );
      end;
    finally
      if Font <> nil then
        FontCache.Release;
      if Bitmap <> nil then
        ImageCache.Release;
    end;
  end;
  inherited Draw(ClipRect);
end;

procedure TTextButtonGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
  if ImageCache <> nil then
    ImageCache.QueueLoadIfMissing(PendingLoads);
end;

end.
