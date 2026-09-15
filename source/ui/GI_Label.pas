{$EXCESSPRECISION OFF}
unit GI_Label;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheFont,
  EC_Str,
  GI_Image,
  GI_Main,
  GI_MessageLoop,
  GR_DX,
  GR_GraphBuf,
  Types;
type
  TLabelGI = class;
  TCreateLabelControlEventGI = function(Sender: TLabelGI; Item: PFontObjectEC): TObjectGI of object;
  TLabelGI = class(TObjectGI)
    FontCache: TCFontControlEC;
    EmbeddedImage: TImageGI;
    TextLines: TStringsEC;
    TextColor: Cardinal;
    TextBorderWidth: Integer;
    TextBorderColor: Cardinal;
    TextShadowOffset: Integer;
    TextShadowColor: Cardinal;
    BorderEnabled: Boolean;
    Gap141: array[0..2] of Byte;
    BorderLightColor: Cardinal;
    BorderDarkColor: Cardinal;
    TextAlignX: TTextAlignXGI;
    TextAlignY: TTextAlignYGI;
    Gap14E: array[0..1] of Byte;
    TextLeft: Integer;
    TextTop: Integer;
    WordWrapEnabled: Boolean;
    Gap159: array[0..2] of Byte;
    AutoHeightPadding: Integer;
    CreateEmbeddedControl: TCreateLabelControlEventGI;
    TextTexture: TTextureGR;
    procedure Clear; override;
    procedure UpdateHitTestBounds; override;
    procedure SetSize(Size: TPoint); override;
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
    procedure SetFontName(const FontName: WideString);
    procedure SetTextBorderWidth(Value: Integer);
    procedure SetTextBorderColor(Value: Cardinal);
    procedure SetShadowOffset(Value: Integer);
    procedure SetShadowColor(Value: Cardinal);
    procedure SetText(const Text: WideString);
    procedure LoadTextLinesFromBlockParam(Block: TBlockParEC; const ParamName: WideString);
    function GetText: WideString;
    procedure SetTextAlignX(Value: TTextAlignXGI);
    procedure SetTextAlignY(Value: TTextAlignYGI);
    procedure SetWordWrapEnabled(Value: Boolean);
    procedure SetAutoHeightPadding(Value: Integer);
    procedure SetEmbeddedImagePath(const ImagePath: WideString);
    procedure SetEmbeddedImageKindX(Value: TImageKindXGI);
    procedure SetEmbeddedImageKindY(Value: TImageKindYGI);
    procedure SetEmbeddedImageHalfAlpha(Value: Boolean);
    procedure SetTextColor(Value: Cardinal);
    procedure SetBorderLightColor(Value: Cardinal);
    procedure SetBorderDarkColor(Value: Cardinal);
    function MeasureContentSize(TopAdjustment: PInteger): TPoint;
    function GetLineHeight: Integer;
    function GetRenderedLineCount: Integer;
    procedure UpdateEmbeddedControls(Font: TCFontEC);
    procedure RemoveUnusedEmbeddedControls(Font: TCFontEC);
  end;
function MeasureLabelTextBounds(const Text: WideString; const FontName: WideString): TRect;
function MeasureWrappedLabelBounds(Width: Integer; TextLines: TStringsEC; Font: TCFontEC): TRect;
procedure DrawWrappedLabelLines(
    Buffer: TGraphBufGR;
    Width: Integer;
    X: Integer;
    Y: Integer;
    TextLines: TStringsEC;
    Font: TCFontEC
);
procedure RenderLabelTextToBuffer(
    Buffer: TGraphBufGR;
    Width: Integer;
    BorderWidth: Integer;
    ShadowOffset: Integer;
    const Text: WideString;
    const FontName: WideString;
    TextColor: Cardinal;
    BorderColor: Cardinal;
    ShadowColor: Cardinal
);
implementation
uses
  EC_Cache,
  GR_Main,
  Math,
  Windows,
  SysUtils,
  GlobalsV,
  Direct3D9;

constructor TLabelGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  EmbeddedImage := nil;
  TextLines := TStringsEC.Create;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  TextBorderWidth := 0;
  TextBorderColor := 0;
  BorderEnabled := False;
  TextAlignX := taxCenter;
  TextAlignY := tayCenter;
  AutoHeightPadding := 4;
  TextTexture := nil;
end;

destructor TLabelGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  TextLines.Free;
  TextLines := nil;
  if TextTexture <> nil then
  begin
    FreeTextureCache(TextTexture);
    TextTexture := nil;
  end;
  inherited Destroy;
end;

procedure TLabelGI.Clear;
begin
  inherited Clear;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  BorderEnabled := False;
  TextAlignX := taxCenter;
  TextAlignY := tayCenter;
  if TextLines <> nil then
    TextLines.Clear;
  if EmbeddedImage <> nil then
  begin
    FreeOwnedChild(EmbeddedImage);
    EmbeddedImage := nil;
  end;
  if TextTexture <> nil then
  begin
    FreeTextureCache(TextTexture);
    TextTexture := nil;
  end;
end;

procedure TLabelGI.SetFontName(const FontName: WideString);
begin
  Invalidate;
  FontCache.SetCacheKey(FontName);
  Invalidate;
  if TextTexture <> nil then
    TextTexture.ReleaseSurfaces;
end;

procedure TLabelGI.SetTextBorderWidth(Value: Integer);
begin
  if Value <> TextBorderWidth then
  begin
    TextBorderWidth := Value;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetTextBorderColor(Value: Cardinal);
begin
  if Value <> TextBorderColor then
  begin
    TextBorderColor := Value;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetShadowOffset(Value: Integer);
begin
  if Value <> TextShadowOffset then
  begin
    TextShadowOffset := Value;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.SetSurface(nil, 1);
  end;
end;

procedure TLabelGI.SetShadowColor(Value: Cardinal);
begin
  if Value <> TextShadowColor then
  begin
    TextShadowColor := Value;
    Invalidate;
  end;
end;

procedure TLabelGI.SetText(const Text: WideString);
begin
  if TextLines.GetText <> Text then
  begin
    Invalidate;
    TextLines.SetText(Text);
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.LoadTextLinesFromBlockParam(Block: TBlockParEC; const ParamName: WideString);
var
  Index, Count: Integer;
  Key: WideString;
begin
  TextLines.Clear;
  Count := Block.CountParams(ParamName);
  for Index := 0 to Count - 1 do
    TextLines.Add(Block.GetParamByPath(ParamName + ':' + IntToStr(Index)));
  if Count > 0 then
  begin
    Key := TrimWideString(TextLines.GetText);
    Count := LanguageDataConfig.CountParamsByPath(Key);
    if Count > 0 then
    begin
      TextLines.Clear;
      for Index := 0 to Count - 1 do
        TextLines.Add(LanguageDataConfig.GetParamByPathOrMarker(Key + ':' + IntToStr(Index)));
    end;
  end;
  UpdateAbsolutePosition;
  UpdateSubtreeHitBounds;
  Invalidate;
  if TextTexture <> nil then
    TextTexture.ReleaseSurfaces;
end;

function TLabelGI.GetText: WideString;
begin
  Result := TextLines.GetText;
end;

procedure TLabelGI.SetTextAlignX(Value: TTextAlignXGI);
begin
  if TextAlignX <> Value then
  begin
    TextAlignX := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetTextAlignY(Value: TTextAlignYGI);
begin
  if TextAlignY <> Value then
  begin
    TextAlignY := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetWordWrapEnabled(Value: Boolean);
begin
  if WordWrapEnabled <> Value then
  begin
    WordWrapEnabled := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetAutoHeightPadding(Value: Integer);
begin
  if AutoHeightPadding <> Value then
  begin
    AutoHeightPadding := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
end;

procedure TLabelGI.SetEmbeddedImagePath(const ImagePath: WideString);
begin
  Invalidate;
  if ImagePath = '' then
  begin
    if EmbeddedImage <> nil then
    begin
      FreeOwnedChild(EmbeddedImage);
      EmbeddedImage := nil;
    end;
  end
  else
  begin
    if EmbeddedImage = nil then
      EmbeddedImage := TImageGI.Create(Self);
    EmbeddedImage.SetImagePath(ImagePath);
    EmbeddedImage.SetImageKindX(ikxLeftFill);
    EmbeddedImage.SetImageKindY(ikyTopFill);
    EmbeddedImage.SetSize(ClientSize);
  end;
end;

procedure TLabelGI.SetEmbeddedImageKindX(Value: TImageKindXGI);
begin
  if EmbeddedImage <> nil then
    EmbeddedImage.SetImageKindX(Value);
end;

procedure TLabelGI.SetEmbeddedImageKindY(Value: TImageKindYGI);
begin
  if EmbeddedImage <> nil then
    EmbeddedImage.SetImageKindY(Value);
end;

procedure TLabelGI.SetEmbeddedImageHalfAlpha(Value: Boolean);
begin
  if EmbeddedImage <> nil then
    EmbeddedImage.SetHalfAlpha(Value);
end;

procedure TLabelGI.SetTextColor(Value: Cardinal);
begin
  if TextColor <> Value then
  begin
    TextColor := Value;
    Invalidate;
    if TextTexture <> nil then
      TextTexture.SetSurface(nil, 0);
  end;
end;

procedure TLabelGI.SetBorderLightColor(Value: Cardinal);
begin
  if BorderLightColor <> Value then
  begin
    BorderLightColor := Value;
    Invalidate;
  end;
end;

procedure TLabelGI.SetBorderDarkColor(Value: Cardinal);
begin
  if BorderDarkColor <> Value then
  begin
    BorderDarkColor := Value;
    Invalidate;
  end;
end;

function TLabelGI.MeasureContentSize(TopAdjustment: PInteger): TPoint;
var
  Font: TCFontEC;
  Y: Integer;
  Lines: TStringsEC;
  FirstLine: Boolean;
  Padding: Integer;
  Bounds, LineBounds: TRect;
begin
  if TopAdjustment <> nil then
    TopAdjustment^ := 0;
  Bounds.Left := 0;
  Bounds.Right := 0;
  Bounds.Top := 0;
  Bounds.Bottom := 0;
  Padding := 0;
  if not FontCache.HasEmptyCacheKey then
  begin
    Font := AcquireCachedFont(FontCache);
    try
      Font.ResetTextMeasureState;
      Y := 0;
      TextLines.First;
      if not WordWrapEnabled then
      begin
        if not TextLines.IsAtEnd then
        begin
          Bounds := Font.MeasureTaggedTextBounds(TextLines.GetCurrentText, 0, Y, TopAdjustment);
          Inc(Y, Font.GetLineHeight);
          TextLines.Next;
        end;
        while not TextLines.IsAtEnd do
        begin
          LineBounds := Font.MeasureTaggedTextBounds(TextLines.GetCurrentText, 0, Y, nil);
          UnionRect(Bounds, Bounds, LineBounds);
          Inc(Y, Font.GetLineHeight);
          TextLines.Next;
        end;
      end
      else
      begin
        Lines := TStringsEC.Create;
        FirstLine := True;
        while not TextLines.IsAtEnd do
        begin
          Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, ClientSize.X - 4);
          if not Lines.IsEmpty then
          begin
            Lines.First;
            if FirstLine then
            begin
              Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, TopAdjustment);
              FirstLine := False;
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
            while not Lines.IsAtEnd do
            begin
              LineBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, nil);
              UnionRect(Bounds, Bounds, LineBounds);
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
          end;
          TextLines.Next;
        end;
        Lines.Free;
      end;
      Inc(Result.Y, 2);
      Padding := 2;
    finally
      FontCache.Release;
    end;
  end;
  Result :=
      Classes.Point(
          Bounds.Right - Bounds.Left + TextBorderWidth + Max(TextBorderWidth, TextShadowOffset),
          Padding
              + Bounds.Bottom
              - Bounds.Top
              + TextBorderWidth
              + Max(TextBorderWidth, TextShadowOffset)
      );
end;

function TLabelGI.GetLineHeight: Integer;
var
  Font: TCFontEC;
begin
  Font := AcquireCachedFont(FontCache);
  try
    Font.ResetTextMeasureState;
    Result := Font.GetLineHeight;
  finally
    FontCache.Release;
  end;
end;

function TLabelGI.GetRenderedLineCount: Integer;
var
  Font: TCFontEC;
  Lines: TStringsEC;
begin
  Result := 0;
  Font := nil;
  if FontCache <> nil then
  begin
    try
      Font := AcquireCachedFont(FontCache);
      if not WordWrapEnabled then
        Result := TextLines.GetCount
      else
      begin
        Lines := TStringsEC.Create;
        TextLines.First;
        while not TextLines.IsAtEnd do
        begin
          Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, ClientSize.X - 4);
          Inc(Result, Lines.GetCount);
          TextLines.Next;
        end;
        Lines.Free;
      end;
    finally
      if Font <> nil then
        FontCache.Release;
    end;
  end;
end;

procedure TLabelGI.UpdateHitTestBounds;
var
  Size: TPoint;
  TopAdjustment: Integer;
begin
  Size := MeasureContentSize(@TopAdjustment);
  if (TextAlignX = taxLeft) or (WordWrapEnabled = True) then
    TextLeft := AbsolutePosition.X + 2
  else if TextAlignX = taxRight then
    TextLeft := AbsolutePosition.X + ClientSize.X - Size.X - 2
  else if TextAlignX = taxCenter then
    TextLeft := ClientSize.X div 2 + AbsolutePosition.X - Size.X div 2
  else if TextAlignX = taxAuto then
  begin
    TextLeft := AbsolutePosition.X + 2;
    ClientSize.X := Size.X + 4;
  end;
  if TextAlignY = tayTop then
    TextTop := AbsolutePosition.Y + 2 + TopAdjustment
  else if TextAlignY = tayBottom then
    TextTop := AbsolutePosition.Y + ClientSize.Y - Size.Y - 2 + TopAdjustment
  else if TextAlignY = tayCenter then
    TextTop := ClientSize.Y div 2 + AbsolutePosition.Y - Size.Y div 2 + TopAdjustment
  else if TextAlignY = tayCenterEx then
    TextTop := ClientSize.Y div 2 + AbsolutePosition.Y - Size.Y div 2 + TopAdjustment
  else if TextAlignY = tayAuto then
  begin
    TextTop := AbsolutePosition.Y + 2 + TopAdjustment;
    ClientSize.Y := Size.Y + AutoHeightPadding;
  end;
  inherited UpdateHitTestBounds;
end;

procedure TLabelGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if EmbeddedImage <> nil then
    EmbeddedImage.SetSize(Size);
end;

procedure TLabelGI.UpdateEmbeddedControls(Font: TCFontEC);
var
  Index: Integer;
  Child: TObjectGI;
  Item: PFontObjectEC;
  Position: TPoint;
begin
  for Index := 0 to Font.ObjectCount - 1 do
  begin
    Item := Font.GetEmbeddedObject(Index);
    if HardwareRenderingEnabled then
      Position := Classes.Point(Item.X, Item.Y)
    else
      Position := ToLocalPoint(Classes.Point(Item.X, Item.Y));
    Child := FirstChild;
    while Child <> nil do
    begin
      if (Child.UserValue = Item.ObjectId) and (Child.UserIndex = Index) then
      begin
        Child.SetPosition(Position);
        Child.SetSize(Classes.Point(Item.Width, Item.Height));
        Break;
      end;
      Child := Child.NextSibling;
    end;
    if (Child = nil) and Assigned(CreateEmbeddedControl) then
    begin
      Child := CreateEmbeddedControl(Self, Item);
      if Child <> nil then
      begin
        Child.UserValue := Item.ObjectId;
        Child.UserIndex := Index;
        Child.SetPosition(Position);
        Child.SetSize(Classes.Point(Item.Width, Item.Height));
      end;
    end;
  end;
end;

procedure TLabelGI.RemoveUnusedEmbeddedControls(Font: TCFontEC);
var
  Index: Integer;
  Child, Previous: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    Index := 0;
    while Index < Font.ObjectCount do
    begin
      if (Child.UserIndex = Index)
          and (Child.UserValue = Font.GetEmbeddedObject(Index).ObjectId) then
        Break;
      Inc(Index);
    end;
    Previous := Child;
    Child := Child.NextSibling;
    if Index >= Font.ObjectCount then
      Previous.Free;
  end;
end;

procedure TLabelGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if (HelpText <> '') and (MessageLoop.HoveredControl <> Self) then
  begin
    MessageLoop.SetHoveredControl(Self);
    if Assigned(HelpCallback) then
      HelpCallback(Self, True);
  end;
end;

procedure TLabelGI.OnMouseLeave;
begin
  if MessageLoop.HoveredControl = Self then
  begin
    MessageLoop.SetHoveredControl(nil);
    if Assigned(HelpCallback) then
      HelpCallback(Self, False);
  end;
  inherited OnMouseLeave;
end;

procedure TLabelGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
end;

procedure TLabelGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
end;

procedure TLabelGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Alignment: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then
    FontCache.SetCacheKey(Block.GetParam('Font'));
  LoadTextLinesFromBlockParam(Block, 'Text');
  if Block.CountParams('Image') > 0 then
    SetEmbeddedImagePath(Block.GetParam('Image'));
  if Block.CountParams('ImageKindX') > 0 then
    SetEmbeddedImageKindX(ParseImageKindXName(Block.GetParam('ImageKindX')));
  if Block.CountParams('ImageKindY') > 0 then
    SetEmbeddedImageKindY(ParseImageKindYName(Block.GetParam('ImageKindY')));
  if Block.CountParams('TextColor') > 0 then
    SetTextColor(GetColorGI(Block.GetParam('TextColor')));
  if Block.CountParams('Border') > 0 then
  begin
    if Block.GetParam('Border') = 'True' then
      BorderEnabled := True
    else
      BorderEnabled := False;
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    SetBorderLightColor(GetColorGI(Block.GetParam('BorderLightColor')));
    SetBorderDarkColor(BorderLightColor);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
    SetBorderDarkColor(GetColorGI(Block.GetParam('BorderDarkColor')));
  if Block.CountParams('WordWrap') > 0 then
    SetWordWrapEnabled(ParseEnabledNameGI(TrimWideString(Block.GetParam('WordWrap'))));
  if Block.CountParams('AlignY') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignY'));
    SetTextAlignY(ParseTextAlignYName(Alignment));
  end;
  if Block.CountParams('AlignX') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignX'));
    SetTextAlignX(ParseTextAlignXName(Alignment));
  end;
end;

procedure TLabelGI.LoadFromBlock(Block: TBlockParEC);
var
  Alignment: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Font') > 0 then
    FontCache.SetCacheKey(Block.GetParam('Font'));
  LoadTextLinesFromBlockParam(Block, 'Text');
  if Block.CountParams('Image') > 0 then
    SetEmbeddedImagePath(Block.GetParam('Image'));
  if Block.CountParams('ImageKindX') > 0 then
    SetEmbeddedImageKindX(ParseImageKindXName(Block.GetParam('ImageKindX')));
  if Block.CountParams('ImageKindY') > 0 then
    SetEmbeddedImageKindY(ParseImageKindYName(Block.GetParam('ImageKindY')));
  if Block.CountParams('TextColor') > 0 then
    SetTextColor(GetColorGI(Block.GetParam('TextColor')));
  if Block.CountParams('Border') > 0 then
  begin
    if Block.GetParam('Border') = 'True' then
      BorderEnabled := True
    else
      BorderEnabled := False;
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    SetBorderLightColor(GetColorGI(Block.GetParam('BorderLightColor')));
    SetBorderDarkColor(BorderLightColor);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
    SetBorderDarkColor(GetColorGI(Block.GetParam('BorderDarkColor')));
  if Block.CountParams('WordWrap') > 0 then
    SetWordWrapEnabled(ParseEnabledNameGI(TrimWideString(Block.GetParam('WordWrap'))));
  if Block.CountParams('AlignY') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignY'));
    SetTextAlignY(ParseTextAlignYName(Alignment));
  end;
  if Block.CountParams('AlignX') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignX'));
    SetTextAlignX(ParseTextAlignXName(Alignment));
  end;
  if Block.CountParams('TextBorderColor') > 0 then
    SetTextBorderColor(GetColorGI(Block.GetParam('TextBorderColor')));
  if Block.CountParams('TextShadowColor') > 0 then
    SetShadowColor(GetColorGI(Block.GetParam('TextShadowColor')));
  if Block.CountParams('TextBorder') > 0 then
    SetTextBorderWidth(ExtractDigitsToIntW(Block.GetParam('TextBorder')));
  if Block.CountParams('TextShadow') > 0 then
    SetShadowOffset(ExtractDigitsToIntW(Block.GetParam('TextShadow')));
end;

procedure TLabelGI.Draw(ClipRect: TRect);
var
  Font: TCFontEC;
  Y: Integer;
  Lines: TStringsEC;
  Color: Cardinal;
  Texture: IDirect3DTexture9;
  Bounds: TRect;
  procedure SwitchLabelDrawFont(
      FontName: WideString
  ); // @addr 0x48A85C @ida "void __usercall $name(unsigned __int16 *FontName@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x48A943,0x48A971,0x48A99F,0x48A9D1,0x48A9FF,0x48AA2A,0x48AA55,0x48AA80" @note "Nested Draw helper; caller removes the parent-frame argument."
  begin
    FontCache.SetCacheKey(FontName);
    if TextTexture <> nil then
      TextTexture.ReleaseSurfaces;
  end;
begin
  Font := nil;
  if FontCache <> nil then
  begin
    if FontSmoothingEnabled then
    begin
      if FontCache.CacheKey = SmallFontName then
        SwitchLabelDrawFont(SmoothSmallFontName)
      else if FontCache.CacheKey = SmallBoldFontName then
        SwitchLabelDrawFont(SmoothSmallBoldFontName)
      else if FontCache.CacheKey = NormalFontName then
        SwitchLabelDrawFont(SmoothNormalFontName)
      else if FontCache.CacheKey = NormalBoldFontName then
        SwitchLabelDrawFont(SmoothNormalBoldFontName);
    end
    else
    begin
      if FontCache.CacheKey = SmoothSmallFontName then
        SwitchLabelDrawFont(SmallFontName)
      else if FontCache.CacheKey = SmoothSmallBoldFontName then
        SwitchLabelDrawFont(SmallBoldFontName)
      else if FontCache.CacheKey = SmoothNormalFontName then
        SwitchLabelDrawFont(NormalFontName)
      else if FontCache.CacheKey = SmoothNormalBoldFontName then
        SwitchLabelDrawFont(NormalBoldFontName);
    end;
    try
      Font := AcquireCachedFont(FontCache);
      Font.ResetTextMeasureState;
      if HardwareRenderingEnabled then
      begin
        if TextTexture = nil then
          TextTexture := CreateTextureCache;
        Texture := TextTexture.GetSurface(1);
        if (Texture = nil) and ((TextShadowOffset > 0) or (TextBorderWidth > 0)) then
        begin
          Font.ColorTagsEnabled := False;
          Font.DefaultColor := $FFFFFFFF;
          Font.RenderTaggedTextToTexture(
              TextLines.GetText,
              ClientSize.X,
              ClientSize.Y,
              Ord(TextAlignX),
              Ord(TextAlignY),
              WordWrapEnabled,
              nil,
              Texture
          );
          TextTexture.SetSurface(Texture, 1);
        end;
        if TextShadowOffset > 0 then
          DrawTexture(
              Texture,
              AbsolutePosition.X + TextShadowOffset,
              AbsolutePosition.Y + TextShadowOffset,
              255,
              Color565ToArgb(TextShadowColor),
              @ClipRect,
              False,
              False
          );
        if TextBorderWidth > 0 then
        begin
          Color := Color565ToArgb(TextBorderColor);
          DrawTexture(
              Texture,
              AbsolutePosition.X - TextBorderWidth,
              AbsolutePosition.Y - TextBorderWidth,
              255,
              Color,
              @ClipRect,
              False,
              False
          );
          DrawTexture(
              Texture,
              AbsolutePosition.X + TextBorderWidth,
              AbsolutePosition.Y - TextBorderWidth,
              255,
              Color,
              @ClipRect,
              False,
              False
          );
          DrawTexture(
              Texture,
              AbsolutePosition.X - TextBorderWidth,
              AbsolutePosition.Y + TextBorderWidth,
              255,
              Color,
              @ClipRect,
              False,
              False
          );
          DrawTexture(
              Texture,
              AbsolutePosition.X + TextBorderWidth,
              AbsolutePosition.Y + TextBorderWidth,
              255,
              Color,
              @ClipRect,
              False,
              False
          );
        end;
        Texture := TextTexture.GetSurface(0);
        if Texture = nil then
        begin
          Font.ColorTagsEnabled := True;
          Font.DefaultColor := Color565ToArgb(TextColor);
          Font.RenderTaggedTextToTexture(
              TextLines.GetText,
              ClientSize.X,
              ClientSize.Y,
              Ord(TextAlignX),
              Ord(TextAlignY),
              WordWrapEnabled,
              nil,
              Texture
          );
          UpdateEmbeddedControls(Font);
          RemoveUnusedEmbeddedControls(Font);
          TextTexture.SetSurface(Texture, 0);
        end;
        DrawTexture(
            Texture,
            AbsolutePosition.X,
            AbsolutePosition.Y,
            255,
            $FFFFFF,
            @ClipRect,
            False,
            False
        );
        if BorderEnabled then
        begin
          Color := Color565ToArgb(BorderLightColor);
          DrawAlphaLine(
              HitTestBounds.Left,
              HitTestBounds.Top,
              HitTestBounds.Right - 1,
              HitTestBounds.Top,
              Color,
              255,
              @ClipRect
          );
          DrawAlphaLine(
              HitTestBounds.Left,
              HitTestBounds.Top,
              HitTestBounds.Left,
              HitTestBounds.Bottom - 1,
              Color,
              255,
              @ClipRect
          );
          Color := Color565ToArgb(BorderDarkColor);
          DrawAlphaLine(
              HitTestBounds.Left,
              HitTestBounds.Bottom - 1,
              HitTestBounds.Right - 1,
              HitTestBounds.Bottom - 1,
              Color,
              255,
              @ClipRect
          );
          DrawAlphaLine(
              HitTestBounds.Right - 1,
              HitTestBounds.Top,
              HitTestBounds.Right - 1,
              HitTestBounds.Bottom - 1,
              Color,
              255,
              @ClipRect
          );
        end;
      end
      else
      begin
        if not WordWrapEnabled then
        begin
          if TextAlignY = tayCenterEx then
            Y :=
                HitTestBounds.Top
                    + ClientSize.Y div 2
                    - (Font.GetLineHeight * (TextLines.GetCount - 1) + Font.GetCenteringHeight)
                        div 2
                    + Font.GetCenteringHeight
          else
            Y := TextTop + Font.AboveBaseline - 2;
          TextLines.First;
          while not TextLines.IsAtEnd do
          begin
            Font.ColorTagsEnabled := False;
            if TextShadowOffset > 0 then
            begin
              Font.DefaultColor := TextShadowColor;
              Font.DrawTaggedText16(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  TextLeft + TextShadowOffset,
                  Y + TextShadowOffset,
                  TextLines.GetCurrentText,
                  ClipRect
              );
            end;
            if TextBorderWidth > 0 then
            begin
              Font.DefaultColor := TextBorderColor;
              Font.DrawTaggedText16(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  TextLeft - TextBorderWidth,
                  Y - TextBorderWidth,
                  TextLines.GetCurrentText,
                  ClipRect
              );
              Font.DrawTaggedText16(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  TextLeft + TextBorderWidth,
                  Y - TextBorderWidth,
                  TextLines.GetCurrentText,
                  ClipRect
              );
              Font.DrawTaggedText16(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  TextLeft - TextBorderWidth,
                  Y + TextBorderWidth,
                  TextLines.GetCurrentText,
                  ClipRect
              );
              Font.DrawTaggedText16(
                  ScreenRenderBuffer.GetPixels,
                  ScreenRenderBuffer.PitchBytes,
                  TextLeft + TextBorderWidth,
                  Y + TextBorderWidth,
                  TextLines.GetCurrentText,
                  ClipRect
              );
            end;
            Font.ColorTagsEnabled := True;
            Font.DefaultColor := TextColor;
            Font.DrawTaggedText16(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes,
                TextLeft,
                Y,
                TextLines.GetCurrentText,
                ClipRect
            );
            Inc(Y, Font.GetLineHeight);
            TextLines.Next;
          end;
        end
        else
        begin
          Lines := TStringsEC.Create;
          Y := TextTop + Font.AboveBaseline - 2;
          TextLines.First;
          while not TextLines.IsAtEnd do
          begin
            Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, ClientSize.X - 4);
            Lines.First;
            while not Lines.IsAtEnd do
            begin
              if TextAlignX = taxLeft then
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextShadowOffset,
                      Y + TextShadowOffset,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(
                    ScreenRenderBuffer.GetPixels,
                    ScreenRenderBuffer.PitchBytes,
                    TextLeft,
                    Y,
                    Lines.GetCurrentText,
                    ClipRect
                );
              end
              else if TextAlignX = taxRight then
              begin
                Font.ColorTagsEnabled := False;
                Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, 0, nil);
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextShadowOffset,
                      Y + TextShadowOffset,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 - TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 - TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(
                    ScreenRenderBuffer.GetPixels,
                    ScreenRenderBuffer.PitchBytes,
                    HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2,
                    Y,
                    Lines.GetCurrentText,
                    ClipRect
                );
              end
              else if TextAlignX = taxCenter then
              begin
                Font.ColorTagsEnabled := False;
                Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, 0, nil);
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      (HitTestBounds.Right - HitTestBounds.Left) div 2
                          + HitTestBounds.Left
                          - (Bounds.Right - Bounds.Left) div 2
                          + TextShadowOffset,
                      Y + TextShadowOffset,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      (HitTestBounds.Right - HitTestBounds.Left) div 2
                          + HitTestBounds.Left
                          - (Bounds.Right - Bounds.Left) div 2
                          - TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      (HitTestBounds.Right - HitTestBounds.Left) div 2
                          + HitTestBounds.Left
                          - (Bounds.Right - Bounds.Left) div 2
                          + TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      (HitTestBounds.Right - HitTestBounds.Left) div 2
                          + HitTestBounds.Left
                          - (Bounds.Right - Bounds.Left) div 2
                          - TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      (HitTestBounds.Right - HitTestBounds.Left) div 2
                          + HitTestBounds.Left
                          - (Bounds.Right - Bounds.Left) div 2
                          + TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(
                    ScreenRenderBuffer.GetPixels,
                    ScreenRenderBuffer.PitchBytes,
                    (HitTestBounds.Right - HitTestBounds.Left) div 2
                        + HitTestBounds.Left
                        - (Bounds.Right - Bounds.Left) div 2,
                    Y,
                    Lines.GetCurrentText,
                    ClipRect
                );
              end
              else if (TextAlignX = taxAuto) and (not Lines.IsAtLast) then
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawJustifiedTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextShadowOffset,
                      Y + TextShadowOffset,
                      Lines.GetCurrentText,
                      ClientSize.X - 4,
                      ClipRect
                  );
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawJustifiedTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClientSize.X - 4,
                      ClipRect
                  );
                  Font.DrawJustifiedTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClientSize.X - 4,
                      ClipRect
                  );
                  Font.DrawJustifiedTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClientSize.X - 4,
                      ClipRect
                  );
                  Font.DrawJustifiedTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClientSize.X - 4,
                      ClipRect
                  );
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawJustifiedTaggedText16(
                    ScreenRenderBuffer.GetPixels,
                    ScreenRenderBuffer.PitchBytes,
                    TextLeft,
                    Y,
                    Lines.GetCurrentText,
                    ClientSize.X - 4,
                    ClipRect
                );
              end
              else
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextShadowOffset,
                      Y + TextShadowOffset,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y - TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft - TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                  Font.DrawTaggedText16(
                      ScreenRenderBuffer.GetPixels,
                      ScreenRenderBuffer.PitchBytes,
                      TextLeft + TextBorderWidth,
                      Y + TextBorderWidth,
                      Lines.GetCurrentText,
                      ClipRect
                  );
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(
                    ScreenRenderBuffer.GetPixels,
                    ScreenRenderBuffer.PitchBytes,
                    TextLeft,
                    Y,
                    Lines.GetCurrentText,
                    ClipRect
                );
              end;
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
            TextLines.Next;
          end;
          Lines.Free;
        end;
        if BorderEnabled then
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
        UpdateEmbeddedControls(Font);
        RemoveUnusedEmbeddedControls(Font);
      end;
    finally
      if Font <> nil then
        FontCache.Release;
    end;
  end;
  inherited Draw(ClipRect);
end;

procedure TLabelGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
end;

function MeasureLabelTextBounds(const Text, FontName: WideString): TRect;
var
  Control: TCFontControlEC;
  Font: TCFontEC;
begin
  Control := nil;
  Font := nil;
  try
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(FontName);
    Font := AcquireCachedFont(Control);
    Font.ResetTextMeasureState;
    Font.UseARGBColors := True;
    Font.ColorTagsEnabled := False;
    Result := Font.MeasureTaggedTextBounds(Text, 0, 0, nil);
  finally
    if Font <> nil then
      Control.Release;
    if Control <> nil then
      Control.Free;
  end;
  Inc(Result.Bottom, 2);
  Inc(Result.Right, 4);
end;

function MeasureWrappedLabelBounds(Width: Integer; TextLines: TStringsEC; Font: TCFontEC): TRect;
var
  Lines: TStringsEC;
  FirstLine: Boolean;
  Y: Integer;
  Bounds, LineBounds: TRect;
begin
  TextLines.First;
  Bounds.Left := 0;
  Bounds.Right := 0;
  Bounds.Top := 0;
  Bounds.Bottom := 0;
  Y := 0;
  Lines := TStringsEC.Create;
  FirstLine := True;
  while not TextLines.IsAtEnd do
  begin
    Font.ResetTextMeasureState;
    Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, Width - 4);
    if not Lines.IsEmpty then
    begin
      Lines.First;
      if FirstLine then
      begin
        Font.ResetTextMeasureState;
        Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, nil);
        FirstLine := False;
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
      while not Lines.IsAtEnd do
      begin
        Font.ResetTextMeasureState;
        LineBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, nil);
        UnionRect(Bounds, Bounds, LineBounds);
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
    end;
    TextLines.Next;
  end;
  Lines.Free;
  Inc(Bounds.Bottom, 2);
  Inc(Bounds.Right, 4);
  Result := Bounds;
end;

procedure DrawWrappedLabelLines(
    Buffer: TGraphBufGR;
    Width, X, Y: Integer;
    TextLines: TStringsEC;
    Font: TCFontEC
);
var
  Lines: TStringsEC;
  CurrentY: Integer;
  ClipRect: TRect;
begin
  Lines := TStringsEC.Create;
  ClipRect := Classes.Rect(0, 0, Buffer.Width, Buffer.Height);
  CurrentY := Y + 2 + Font.AboveBaseline - 2;
  TextLines.First;
  while not TextLines.IsAtEnd do
  begin
    Font.ResetTextMeasureState;
    Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, Width - 4);
    Lines.First;
    while not Lines.IsAtEnd do
    begin
      Font.ResetTextMeasureState;
      if not Lines.IsAtLast then
        Font.DrawJustifiedTaggedText32(
            Buffer.GetPixels,
            Buffer.PitchBytes,
            X,
            CurrentY,
            Lines.GetCurrentText,
            Width - 4,
            ClipRect
        )
      else
        Font.DrawTaggedText32(
            Buffer.GetPixels,
            Buffer.PitchBytes,
            X,
            CurrentY,
            Lines.GetCurrentText,
            ClipRect
        );
      Inc(CurrentY, Font.GetLineHeight);
      Lines.Next;
    end;
    TextLines.Next;
  end;
  Lines.Free;
end;

procedure RenderLabelTextToBuffer(
    Buffer: TGraphBufGR;
    Width, BorderWidth, ShadowOffset: Integer;
    const Text, FontName: WideString;
    TextColor, BorderColor, ShadowColor: Cardinal
);
var
  Control: TCFontControlEC;
  Font: TCFontEC;
  Lines: TStringsEC;
  InnerWidth, X, Y: Integer;
begin
  Control := nil;
  Font := nil;
  Lines := nil;
  try
    Lines := TStringsEC.Create;
    Lines.SetText(Text);
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(FontName);
    Font := AcquireCachedFont(Control);
    Font.ResetTextMeasureState;
    Font.UseARGBColors := True;
    Font.ColorTagsEnabled := False;
    InnerWidth := Width - BorderWidth - Max(BorderWidth, ShadowOffset);
    with MeasureWrappedLabelBounds(InnerWidth, Lines, Font) do
    begin
      Dec(Left, BorderWidth);
      Dec(Top, BorderWidth);
      Inc(Right, Max(BorderWidth, ShadowOffset));
      Bottom := Bottom + Max(BorderWidth, ShadowOffset) + 4;
      Buffer.AllocateRgbaTight(InnerWidth, Bottom - Top);
    end;
    Buffer.ClearPixels;
    X := BorderWidth;
    Y := BorderWidth;
    if ShadowOffset <> 0 then
    begin
      Font.DefaultColor := ShadowColor;
      DrawWrappedLabelLines(Buffer, InnerWidth, X + ShadowOffset, Y + ShadowOffset, Lines, Font);
    end;
    if BorderWidth > 0 then
    begin
      Font.DefaultColor := BorderColor;
      DrawWrappedLabelLines(Buffer, InnerWidth, X - BorderWidth, Y - BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X + BorderWidth, Y - BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X - BorderWidth, Y + BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X + BorderWidth, Y + BorderWidth, Lines, Font);
    end;
    Font.ColorTagsEnabled := True;
    Font.DefaultColor := TextColor;
    DrawWrappedLabelLines(Buffer, InnerWidth, X, Y, Lines, Font);
  finally
    if Font <> nil then
      Control.Release;
    if Control <> nil then
      Control.Free;
    if Lines <> nil then
      Lines.Free;
  end;
end;

end.
