{$EXCESSPRECISION OFF}
unit GI_Edit;
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
  GI_Main,
  GI_MessageLoop,
  Types;
type
  TEditGI = class;
  TEditAcceptCharEventGI = function(Sender: TObjectGI; Character: WideChar): Boolean of object;
  TEditGI = class(TObjectGI)
    FontCache: TCFontControlEC;
    BackgroundCache: TCBitmapControlEC;
    Text: WideString;
    TextColor: Cardinal;
    CaretColor: Cardinal;
    BorderEnabled: Boolean;
    Gap135: array[0..2] of Byte;
    BorderLightColor: Cardinal;
    BorderDarkColor: Cardinal;
    MaxLength: Integer;
    HasFocus: Boolean;
    Gap145: array[0..2] of Byte;
    CaretPosition: Integer;
    AutoScrollText: Boolean;
    TextAlignX: TTextAlignXGI;
    Gap14E: array[0..1] of Byte;
    ChangedCallback: TObjectNotifyEventGI;
    FocusLostCallback: TObjectNotifyEventGI;
    AcceptCharCallback: TEditAcceptCharEventGI;
    ClearFocusOnEnter: Boolean;
    Gap169: array[0..2] of Byte;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure OnFocusGained; override;
    procedure OnFocusLost; override;
    procedure ProcessKeyDown(Key: Integer); override;
    procedure ProcessCharacter(Character: WideChar); override;
    procedure OnCaretBlink; override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetFontName(FontName: WideString);
    procedure SetBorderEnabled(Value: Boolean);
    procedure SetText(Value: WideString);
    function HasGlyph(Character: WideChar): Boolean;
    procedure SetTextColor(Value: Cardinal);
    procedure SetBorderLightColor(Value: Cardinal);
    procedure SetBorderDarkColor(Value: Cardinal);
    procedure SetTextAlignX(Value: TTextAlignXGI);
    procedure SetCaretPosition(Value: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GlobalsV,
  SysUtils,
  Windows,
  EC_Cache,
  GR_Main,
  GR_GraphBuf,
  GR_DX,
  EC_Str;

constructor TEditGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  BackgroundCache := nil;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  CaretColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderEnabled := False;
  TextAlignX := taxLeft;
  MaxLength := 256;
  ClearFocusOnEnter := True;
end;

destructor TEditGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  BackgroundCache.Free;
  BackgroundCache := nil;
  inherited Destroy;
end;

procedure TEditGI.Clear;
begin
  inherited Clear;
  HasFocus := False;
  MaxLength := 256;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  CaretColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  AutoScrollText := False;
  Text := '';
end;

procedure TEditGI.SetFontName(FontName: WideString);
begin
  FontCache.SetCacheKey(FontName);
  Invalidate;
end;

procedure TEditGI.SetBorderEnabled(Value: Boolean);
begin
  if Value <> BorderEnabled then
  begin
    BorderEnabled := Value;
    Invalidate;
  end;
end;

procedure TEditGI.SetText(Value: WideString);
begin
  if Text <> Value then
  begin
    Text := Value;
    CaretPosition := 0;
    Invalidate;
  end;
end;

function TEditGI.HasGlyph(Character: WideChar): Boolean;
var
  Font: TCFontEC;
begin
  try
    Font := AcquireCachedFont(FontCache);
    Font.ResetTextMeasureState;
    Result := Font.HasGlyph(Character);
  finally
    FontCache.Release;
  end;
end;

procedure TEditGI.SetTextColor(Value: Cardinal);
begin
  if TextColor <> Value then
  begin
    TextColor := Value;
    Invalidate;
  end;
end;

procedure TEditGI.SetBorderLightColor(Value: Cardinal);
begin
  if BorderLightColor <> Value then
  begin
    BorderLightColor := Value;
    Invalidate;
  end;
end;

procedure TEditGI.SetBorderDarkColor(Value: Cardinal);
begin
  if BorderDarkColor <> Value then
  begin
    BorderDarkColor := Value;
    Invalidate;
  end;
end;

procedure TEditGI.SetTextAlignX(Value: TTextAlignXGI);
begin
  if (Value <> taxLeft) and (Value <> taxCenter) then
    raise Exception.Create('Error TEditGI. This align not support.');
  if TextAlignX <> Value then
  begin
    TextAlignX := Value;
    Invalidate;
  end;
end;

procedure TEditGI.SetCaretPosition(Value: Integer);
begin
  if Value > Length(Text) then
    CaretPosition := Length(Text)
  else if Value < 0 then
    CaretPosition := 0
  else
    CaretPosition := Value;
  Invalidate;
end;

procedure TEditGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Active = True then
    MessageLoop.SetFocusedControl(Self);
end;

procedure TEditGI.OnFocusGained;
begin
  inherited OnFocusGained;
  HasFocus := True;
  CaretPosition := Length(Text);
  Invalidate;
end;

procedure TEditGI.OnFocusLost;
begin
  inherited OnFocusLost;
  HasFocus := False;
  if Assigned(FocusLostCallback) then
    FocusLostCallback(Self);
  Invalidate;
end;

procedure TEditGI.ProcessKeyDown(Key: Integer);
var
  I, N: Integer;
  Control: TObjectGI;
begin
  if (Key = VK_BACK) and not IsVirtualKeyDown(VK_SHIFT) then
  begin
    if CaretPosition > 0 then
    begin
      N := Length(Text);
      I := CaretPosition;
      while I < N do
      begin
        Text[I] := Text[I + 1];
        Inc(I);
      end;
      SetLength(Text, N - 1);
      Dec(CaretPosition);
      Invalidate;
      DispatchNamedEvent(4, 0, 0);
      if Assigned(ChangedCallback) then
        ChangedCallback(Self);
    end;
  end
  else if (Key = VK_BACK) and IsVirtualKeyDown(VK_SHIFT) then
  begin
    Text := '';
    CaretPosition := 0;
    Invalidate;
    DispatchNamedEvent(4, 0, 0);
    if Assigned(ChangedCallback) then
      ChangedCallback(Self);
  end
  else if Key = VK_DELETE then
  begin
    N := Length(Text);
    if CaretPosition < N then
    begin
      I := CaretPosition + 1;
      while I < N do
      begin
        Text[I] := Text[I + 1];
        Inc(I);
      end;
      SetLength(Text, N - 1);
      Invalidate;
      DispatchNamedEvent(4, 0, 0);
      if Assigned(ChangedCallback) then
        ChangedCallback(Self);
    end;
  end
  else if Key = VK_LEFT then
  begin
    if CaretPosition > 0 then
    begin
      Dec(CaretPosition);
      Invalidate;
    end;
  end
  else if Key = VK_RIGHT then
  begin
    if CaretPosition < Length(Text) then
    begin
      Inc(CaretPosition);
      Invalidate;
    end;
  end
  else if Key = VK_HOME then
  begin
    CaretPosition := 0;
    Invalidate;
  end
  else if Key = VK_END then
  begin
    CaretPosition := Length(Text);
    Invalidate;
  end
  else if (Key = VK_RETURN) and ClearFocusOnEnter then
    MessageLoop.SetFocusedControl(nil)
  else if (Key = VK_TAB) and IsVirtualKeyDown(VK_SHIFT) then
  begin
    Control := NextSibling;
    while Control <> nil do
    begin
      if (Control is TEditGI) and Control.Active then
      begin
        MessageLoop.SetFocusedControl(Control);
        Break;
      end;
      Control := Control.NextSibling;
    end;
  end
  else if Key = VK_TAB then
  begin
    Control := PrevSibling;
    while Control <> nil do
    begin
      if (Control is TEditGI) and Control.Active then
      begin
        MessageLoop.SetFocusedControl(Control);
        Break;
      end;
      Control := Control.PrevSibling;
    end;
  end;
end;

procedure TEditGI.ProcessCharacter(Character: WideChar);
var
  I, N: Integer;
begin
  inherited ProcessCharacter(Character);
  if HasGlyph(Character) then
    if not Assigned(AcceptCharCallback) or AcceptCharCallback(Self, Character) then
    begin
      N := Length(Text);
      if N < MaxLength then
      begin
        SetLength(Text, N + 1);
        I := N;
        while I >= CaretPosition do
        begin
          Text[I + 1] := Text[I];
          Dec(I);
        end;
        Text[CaretPosition + 1] := Character;
        Inc(CaretPosition);
        Invalidate;
        DispatchNamedEvent(4, 0, 0);
        if Assigned(ChangedCallback) then
          ChangedCallback(Self);
      end;
    end;
end;

procedure TEditGI.OnCaretBlink;
begin
  Invalidate;
end;

procedure TEditGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  ColorText: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then
    FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Text') > 0 then
  begin
    Text := Block.GetParam('Text');
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then
      Text := LanguageDataConfig.GetParamByPathOrMarker(Text);
  end;
  if Block.CountParams('Image') > 0 then
  begin
    BackgroundCache := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(BackgroundCache);
    BackgroundCache.SetCacheKey(Block.GetParam('Image'));
  end;
  if Block.CountParams('TextColor') > 0 then
  begin
    ColorText := Block.GetParam('TextColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    TextColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Border') > 0 then
    if Block.GetParam('Border') = 'True' then
      BorderEnabled := True
    else
      BorderEnabled := False;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
    BorderDarkColor := BorderLightColor;
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CursorColor') > 0 then
  begin
    ColorText := Block.GetParam('CursorColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    CaretColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('MaxLen') > 0 then
    MaxLength := StrToInt(Block.GetParam('MaxLen'));
  if Block.CountParams('AlignX') > 0 then
    SetTextAlignX(ParseTextAlignXName(TrimWideString(Block.GetParam('AlignX'))));
end;

procedure TEditGI.LoadFromBlock(Block: TBlockParEC);
var
  ColorText: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromBlock(Block);
  FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('ReturnFocusLeave') > 0 then
    ClearFocusOnEnter := ParseEnabledNameGI(TrimWideString(Block.GetParam('ReturnFocusLeave')));
  if Block.CountParams('Text') > 0 then
  begin
    Text := Block.GetParam('Text');
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then
      Text := LanguageDataConfig.GetParamByPathOrMarker(Text);
  end;
  if Block.CountParams('Image') > 0 then
  begin
    BackgroundCache := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(BackgroundCache);
    BackgroundCache.SetCacheKey(Block.GetParam('Image'));
  end;
  if Block.CountParams('TextColor') > 0 then
  begin
    ColorText := Block.GetParam('TextColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    TextColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Border') > 0 then
    if Block.GetParam('Border') = 'True' then
      BorderEnabled := True
    else
      BorderEnabled := False;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
    BorderDarkColor := BorderLightColor;
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CursorColor') > 0 then
  begin
    ColorText := Block.GetParam('CursorColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    CaretColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('MaxLen') > 0 then
    MaxLength := StrToInt(Block.GetParam('MaxLen'));
  if Block.CountParams('AlignX') > 0 then
    SetTextAlignX(ParseTextAlignXName(TrimWideString(Block.GetParam('AlignX'))));
end;

procedure TEditGI.Draw(ClipRect: TRect);
var
  Font: TCFontEC;
  Bitmap: TCBitmapEC;
  X, Y, N, I, Advance, FirstCharacter, Width: Integer;
  Fits: Boolean;
  CharacterText: WideString;
  Buffer: TGraphBufGR;
begin
  Font := nil;
  Bitmap := nil;
  if FontCache = nil then
    Exit;
  if FontSmoothingEnabled then
  begin
    if FontCache.CacheKey = SmallFontName then
      FontCache.SetCacheKey(SmoothSmallFontName)
    else if FontCache.CacheKey = SmallBoldFontName then
      FontCache.SetCacheKey(SmoothSmallBoldFontName)
    else if FontCache.CacheKey = NormalFontName then
      FontCache.SetCacheKey(SmoothNormalFontName)
    else if FontCache.CacheKey = NormalBoldFontName then
      FontCache.SetCacheKey(SmoothNormalBoldFontName);
  end
  else
  begin
    if FontCache.CacheKey = SmoothSmallFontName then
      FontCache.SetCacheKey(SmallFontName)
    else if FontCache.CacheKey = SmoothSmallBoldFontName then
      FontCache.SetCacheKey(SmallBoldFontName)
    else if FontCache.CacheKey = SmoothNormalFontName then
      FontCache.SetCacheKey(NormalFontName)
    else if FontCache.CacheKey = SmoothNormalBoldFontName then
      FontCache.SetCacheKey(NormalBoldFontName);
  end;
  try
    Font := AcquireCachedFont(FontCache);
    Font.ResetTextMeasureState;
    Font.DefaultColor := TextColor;
    if BackgroundCache <> nil then
    begin
      Bitmap := AcquireOrCreateBitmap(BackgroundCache);
      if HardwareRenderingEnabled then
        DrawTexture(
            Bitmap.Bitmap.GetTexture,
            HitTestBounds.Left,
            HitTestBounds.Top,
            255,
            $FFFFFF,
            @ClipRect,
            False,
            False
        )
      else
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
    end;
    X := HitTestBounds.Left + 2;
    with Font.MeasureTaggedTextBounds(Text, 0, 0, nil) do
      if TextAlignX = taxCenter then
        X :=
            HitTestBounds.Left
                + (HitTestBounds.Right - HitTestBounds.Left) div 2
                - (Right - Left) div 2;
    Y :=
        (HitTestBounds.Top + HitTestBounds.Bottom) div 2
            - (Font.AboveBaseline + Font.BelowBaseline) div 2
            + Font.AboveBaseline;
    N := Length(Text);
    FirstCharacter := 0;
    if AutoScrollText then
      repeat
        Fits := True;
        Width := 0;
        for I := FirstCharacter to N - 1 do
        begin
          Inc(Width, Font.GetGlyphAdvance(Text[I + 1]));
          if (CaretPosition >= I) and (Width >= ClientSize.X - 2) then
          begin
            Inc(FirstCharacter);
            Fits := False;
            Break;
          end;
        end;
      until Fits;
    if FirstCharacter > N then
      FirstCharacter := N;
    Buffer := TGraphBufGR.Create(True);
    if HardwareRenderingEnabled then
    begin
      Buffer.AllocateRgbaTight(
          HitTestBounds.Right - HitTestBounds.Left,
          HitTestBounds.Bottom - HitTestBounds.Top
      );
      Font.UseARGBColors := True;
      Font.DefaultColor := ColorWithAlpha(Color565ToArgb(TextColor), 255);
    end;
    SetLength(CharacterText, 1);
    for I := FirstCharacter to N do
    begin
      Advance := 0;
      if I < N then
      begin
        Advance := Font.GetGlyphAdvance(Text[I + 1]);
        CharacterText[1] := Text[I + 1];
        if HardwareRenderingEnabled then
        begin
          Buffer.ClearPixels;
          Font.DrawTaggedText32(
              Buffer.GetPixels,
              Buffer.PitchBytes,
              X - HitTestBounds.Left,
              Y - HitTestBounds.Top,
              CharacterText,
              Classes.Rect(0, 0, Buffer.Width, Buffer.Height)
          );
          DrawTexture(
              Buffer.GetTexture,
              HitTestBounds.Left,
              HitTestBounds.Top,
              255,
              $FFFFFF,
              @ClipRect,
              False,
              False
          );
        end
        else
          Font.DrawTaggedText16(
              ScreenRenderBuffer.GetPixels,
              ScreenRenderBuffer.PitchBytes,
              X,
              Y,
              CharacterText,
              ClipRect
          );
      end;
      if (HasFocus = True) and (CaretPosition = I) and (MessageLoop.CaretBlinkOn = True) then
      begin
        if HardwareRenderingEnabled then
        begin
          DrawAlphaLine(
              X,
              Y - (Font.AboveBaseline - 1),
              X,
              Y - (Font.AboveBaseline - 1) + Font.AboveBaseline + Font.BelowBaseline,
              Color565ToArgb(CaretColor),
              255,
              @ClipRect
          );
          DrawAlphaLine(
              X + 1,
              Y - (Font.AboveBaseline - 1),
              X + 1,
              Y - (Font.AboveBaseline - 1) + Font.AboveBaseline + Font.BelowBaseline,
              Color565ToArgb(CaretColor),
              255,
              @ClipRect
          );
        end
        else
        begin
          ScreenRenderBuffer.DrawVerticalLine16Clipped(
              X,
              Y - (Font.AboveBaseline - 1),
              Font.AboveBaseline + Font.BelowBaseline,
              CaretColor,
              ClipRect
          );
          ScreenRenderBuffer.DrawVerticalLine16Clipped(
              X + 1,
              Y - (Font.AboveBaseline - 1),
              Font.AboveBaseline + Font.BelowBaseline,
              CaretColor,
              ClipRect
          );
        end;
      end;
      Inc(X, Advance);
    end;
    if Buffer <> nil then
      Buffer.Free;
    if BorderEnabled then
    begin
      if HardwareRenderingEnabled then
      begin
        DrawAlphaLine(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Right - 1,
            HitTestBounds.Top,
            Color565ToArgb(BorderLightColor),
            255,
            @ClipRect
        );
        DrawAlphaLine(
            HitTestBounds.Left,
            HitTestBounds.Top,
            HitTestBounds.Left,
            HitTestBounds.Bottom - 1,
            Color565ToArgb(BorderLightColor),
            255,
            @ClipRect
        );
        DrawAlphaLine(
            HitTestBounds.Left,
            HitTestBounds.Bottom - 1,
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            Color565ToArgb(BorderDarkColor),
            255,
            @ClipRect
        );
        DrawAlphaLine(
            HitTestBounds.Right - 1,
            HitTestBounds.Top,
            HitTestBounds.Right - 1,
            HitTestBounds.Bottom - 1,
            Color565ToArgb(BorderDarkColor),
            255,
            @ClipRect
        );
      end
      else
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
      end;
    end;
  finally
    if Font <> nil then
      FontCache.Release;
    if Bitmap <> nil then
      BackgroundCache.Release;
  end;
end;

procedure TEditGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
  if BackgroundCache <> nil then
    BackgroundCache.QueueLoadIfMissing(PendingLoads);
end;

procedure LinkRecoveredTypes;
begin
  TEditGI.ClassName;
end;
end.
