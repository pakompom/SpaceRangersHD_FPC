{$EXCESSPRECISION OFF}
unit EC_CacheFont;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  Direct3D9,
  EC_Buf,
  EC_Cache,
  EC_Str,
  Types;
type
  TCFontControlEC = class;
  TCFontEC = class;
  PointerToTAftGlyphEC = ^TAftGlyphEC;
  PointerToTFontGlyphLookupEC = ^TFontGlyphLookupEC;
  PointerToTFontObjectEC = ^TFontObjectEC;
  PointerToTAftHeaderEC = ^TAftHeaderEC;
  TAftHeaderEC = packed record
    Magic: array[0..3] of AnsiChar;
    Version: Integer;
    GlyphCount: Integer;
    CenteringHeight: Integer;
    Gap10: array[0..3] of Byte;
    LineHeight: Integer;
    Gap18: array[0..7] of Byte;
  end;
  PAftHeaderEC = PointerToTAftHeaderEC;
  TAftGlyphPlaneEC = packed record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    DataOffset: Integer;
    DataSize: Integer;
  end;
  TAftGlyphEC = packed record
    CharCode: Cardinal;
    AdvanceA: Integer;
    AdvanceB: Integer;
    AdvanceC: Integer;
    OpaqueMaskPlane: TAftGlyphPlaneEC;
    AlphaMaskPlane: TAftGlyphPlaneEC;
  end;
  PAftGlyphEC = PointerToTAftGlyphEC;
  TFontObjectEC = packed record
    // Runtime markup data: dialog links use an address here, while other labels
    // use icon numbers. Match TObjectGI.UserValue so ParseObjectTag preserves
    // the address through the focus callback (native $6D2F87).
    ObjectId: PtrInt;
    Width: Integer;
    Height: Integer;
    VerticalMode: Integer;
    X: Integer;
    Y: Integer;
  end;
  PFontObjectEC = PointerToTFontObjectEC;
  TFontGlyphLookupEC = array[0..65535] of Word;
  PFontGlyphLookupEC = PointerToTFontGlyphLookupEC;
  TCFontControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCFontEC = class(TCacheDataEC)
    FontData: PAftHeaderEC;
    GlyphCount: Integer;
    Glyphs: PAftGlyphEC;
    AboveBaseline: Integer;
    BelowBaseline: Integer;
    MaxGlyphAdvance: Integer;
    GlyphLookup: PFontGlyphLookupEC;
    DefaultColor: Cardinal;
    UseARGBColors: Boolean;
    ColorTagsEnabled: Boolean;
    Gap42: array[0..1] of Byte;
    ObjectCount: Integer;
    ObjectCapacity: Integer;
    Objects: array of TFontObjectEC;
    ColorStackCount: Integer;
    ColorStack: PCardinal;
    FixedWidthDepth: Integer;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
    procedure ClearLoadedFontData;
    function GetCenteringHeight: Integer;
    function GetLineHeight: Integer;
    procedure ResetTextMeasureState;
    function GetEmbeddedObject(Index: Integer): PFontObjectEC;
    function MeasureTaggedTextBounds(
        const Text: WideString;
        X: Integer;
        Y: Integer;
        TopAdjustment: PInteger
    ): TRect;
    function GetGlyphAdvance(CharCode: WideChar): Integer; cdecl;
    function HasGlyph(CharCode: WideChar): Boolean;
    procedure WrapTaggedTextIntoLines(Lines: TStringsEC; const Text: WideString; MaxWidth: Integer);
    procedure DrawTaggedText16(
        Destination: Pointer;
        PitchBytes: Integer;
        X: Integer;
        Y: Integer;
        const Text: WideString;
        ClipRect: TRect
    );
    procedure DrawTaggedText32(
        Destination: Pointer;
        PitchBytes: Integer;
        X: Integer;
        Y: Integer;
        const Text: WideString;
        ClipRect: TRect
    );
    procedure DrawJustifiedTaggedText16(
        Destination: Pointer;
        PitchBytes: Integer;
        X: Integer;
        Y: Integer;
        const Text: WideString;
        Width: Integer;
        ClipRect: TRect
    );
    procedure DrawJustifiedTaggedText32(
        Destination: Pointer;
        PitchBytes: Integer;
        X: Integer;
        Y: Integer;
        const Text: WideString;
        Width: Integer;
        ClipRect: TRect
    );
    function GetTaggedTextTokenLength(Text: PWideChar; CharCount: Integer): Integer;
    function ParseTabTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer;
    function ParseAlignTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer;
    function MatchAlignEndTag(Text: PWideChar; CharCount: Integer): Integer;
    function MatchFixTag(Text: PWideChar; CharCount: Integer): Integer;
    function MatchFixEndTag(Text: PWideChar; CharCount: Integer): Integer;
    function ParseFormatTag(
        Text: PWideChar;
        CharCount: Integer;
        out FieldWidth: Integer;
        out Alignment: Integer
    ): Integer;
    function MatchFormatEndTag(Text: PWideChar; CharCount: Integer): Integer;
    function CountVisibleTaggedCharsUntilFormatEnd(Text: PWideChar; CharCount: Integer): Integer;
    function ParseObjectTagCached(
        Text: PWideChar;
        CharCount: Integer;
        out ObjectIndex: Integer
    ): Integer;
    function ParseObjectTag(Text: PWideChar; CharCount: Integer; out Item: TFontObjectEC): Integer;
    function ParseColorTag(Text: PWideChar; CharCount: Integer; out Color: Cardinal): Integer;
    function MatchColorEndTag(Text: PWideChar; CharCount: Integer): Integer;
    procedure ApplyColorTag(Text: PWideChar; CharCount: Integer);
    procedure ClearColorStack;
    procedure PushColor(Color: Cardinal);
    function PopColor: Cardinal;
    function GetCurrentColor: Cardinal;
    procedure RenderTaggedTextToTexture(
        const Text: WideString;
        Width: Integer;
        Height: Integer;
        AlignX: Integer;
        AlignY: Integer;
        WordWrap: Boolean;
        ActualSize: PPoint;
        var Texture: IDirect3DTexture9
    );
  end;
function AcquireCachedFont(Control: TCacheControlEC): TCFontEC;
procedure LinkRecoveredTypes;
implementation
uses
  EC_Mem,
  GR_DX,
  GR_Main,
  Math,
  SysUtils,
  Windows;
type
  TFontTextCharsEC = array[0..MaxInt div SizeOf(WideChar) - 1] of WideChar;
  PFontTextCharsEC = ^TFontTextCharsEC;
// The + 0 expressions below, including those in Self casts, preserve DCC32's
// native operand evaluation order. They emit no additional instructions.
procedure IncludeGlyphBounds(var Bounds: TRect; var X, Y: Integer; var Glyph: PAftGlyphEC); inline;
begin
  if Glyph.AlphaMaskPlane.DataOffset <> 0 then
  begin
    if (X + 0) + Glyph.AlphaMaskPlane.Left < Bounds.Left then
      Bounds.Left := (X + 0) + Glyph.AlphaMaskPlane.Left;
    if (Y + 0) + Glyph.AlphaMaskPlane.Top < Bounds.Top then
      Bounds.Top := (Y + 0) + Glyph.AlphaMaskPlane.Top;
    if (X + 0) + Glyph.AlphaMaskPlane.Left + Glyph.AlphaMaskPlane.Width > Bounds.Right then
      Bounds.Right := (X + 0) + Glyph.AlphaMaskPlane.Left + Glyph.AlphaMaskPlane.Width;
    if (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > Bounds.Bottom then
      Bounds.Bottom := (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height;
  end;
  if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
  begin
    if (X + 0) + Glyph.OpaqueMaskPlane.Left < Bounds.Left then
      Bounds.Left := (X + 0) + Glyph.OpaqueMaskPlane.Left;
    if (Y + 0) + Glyph.OpaqueMaskPlane.Top < Bounds.Top then
      Bounds.Top := (Y + 0) + Glyph.OpaqueMaskPlane.Top;
    if (X + 0) + Glyph.OpaqueMaskPlane.Left + Glyph.OpaqueMaskPlane.Width > Bounds.Right then
      Bounds.Right := (X + 0) + Glyph.OpaqueMaskPlane.Left + Glyph.OpaqueMaskPlane.Width;
    if (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > Bounds.Bottom then
      Bounds.Bottom := (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height;
  end;
end;

procedure TCFontControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCFontControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCFontEC) = nil then
  begin
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCFontControlEC.CreateData: TCacheDataEC;
begin
  Result := TCFontEC.Create;
end;

function AcquireCachedFont(Control: TCacheControlEC): TCFontEC;
begin
  Result := Control.AcquireDataFromConfig(TCFontEC) as TCFontEC;
  Result.ClearColorStack;
  Result.UseARGBColors := False;
  Result.ColorTagsEnabled := True;
end;

function TCFontControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedFont(Self);
end;

constructor TCFontEC.Create;
begin
  inherited Create;
  ColorTagsEnabled := True;
end;

destructor TCFontEC.Destroy;
begin
  ClearLoadedFontData;
  inherited Destroy;
end;

procedure TCFontEC.ClearLoadedFontData;
begin
  ObjectCount := 0;
  ObjectCapacity := 0;
  Objects := nil;
  if FontData <> nil then
  begin
    FreeEC(FontData);
    FontData := nil;
  end;
  Glyphs := nil;
  GlyphCount := 0;
  if GlyphLookup <> nil then
  begin
    FreeEC(GlyphLookup);
    GlyphLookup := nil;
  end;
  ClearColorStack;
end;

function TCFontEC.GetCenteringHeight: Integer;
begin
  Result := FontData.CenteringHeight;
end;

function TCFontEC.GetLineHeight: Integer;
begin
  Result := FontData.LineHeight + 2;
end;

procedure TCFontEC.ResetTextMeasureState;
begin
  ObjectCount := 0;
  FixedWidthDepth := 0;
end;

function TCFontEC.GetEmbeddedObject(Index: Integer): PFontObjectEC;
begin
  Result := @Objects[Index];
end;

function TCFontEC.MeasureTaggedTextBounds(
    const Text: WideString;
    X, Y: Integer;
    TopAdjustment: PInteger
): TRect;
var
  Index, GlyphIndex, CharCount, PosX, TokenLength, MiddleY: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
  ObjectIndex, SavedObjectCount, FieldWidth, Alignment: Integer;
begin
  SavedObjectCount := ObjectCount;
  CharCount := Length(Text);
  PosX := X;
  Result.Left := 999999999;
  Result.Right := -999999999;
  Result.Top := 999999999;
  Result.Bottom := -999999999;
  Index := 0;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      if ParseObjectTagCached(PWideChar(Text) + Index - 1, CharCount - Index + 1, ObjectIndex)
          > 0 then
        Inc(PosX, Objects[ObjectIndex].Width)
      else if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        TCFontEC(PtrUInt(Self) + 0).FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if ParseFormatTag(
              PWideChar(Text) + Index - 1,
              CharCount - Index + 1,
              FieldWidth,
              Alignment)
          > 0 then
      begin
        Index := Index + TokenLength - 1;
        while Index < CharCount do
        begin
          Ch := Text[Index + 1];
          Inc(Index);
          TokenLength :=
              GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
          if TokenLength > 0 then
          begin
            if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
              Inc(FixedWidthDepth)
            else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
              TCFontEC(PtrUInt(Self) + 0).FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
            else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
            begin
              Index := Index + TokenLength - 1;
              Break;
            end;
            Index := Index + TokenLength - 1;
            Continue;
          end;
          GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
          if GlyphIndex <> 0 then
          begin
            Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
            IncludeGlyphBounds(Result, PosX, Y, Glyph);
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance
            else
              PosX := (PosX + 0) + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
            Dec(FieldWidth);
          end;
        end;
        if FieldWidth > 0 then
        begin
          GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(' ') * 2));
          if GlyphIndex <> 0 then
          begin
            Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * FieldWidth
            else
              PosX := PosX + (Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC) * FieldWidth;
          end;
        end;
        Continue;
      end;
      Index := Index + TokenLength - 1;
      Continue;
    end;
    GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
    if GlyphIndex <> 0 then
    begin
      Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
      IncludeGlyphBounds(Result, PosX, Y, Glyph);
      if FixedWidthDepth > 0 then
        PosX := PosX + MaxGlyphAdvance
      else
        PosX := (PosX + 0) + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
    end;
  end;
  Result.Right := Max(Result.Right, PosX);
  if TopAdjustment <> nil then
    TopAdjustment^ := 0;
  if ObjectCount - SavedObjectCount > 0 then
  begin
    MiddleY := (Result.Top + Result.Bottom) div 2;
    for Index := SavedObjectCount to ObjectCount - 1 do
      if Objects[Index].VerticalMode = 0 then
      begin
        if (TopAdjustment <> nil) and (MiddleY - Objects[Index].Height div 2 < Result.Top) then
          TopAdjustment^ := TopAdjustment^+Result.Top - (MiddleY - Objects[Index].Height div 2);
        Result.Top := Min(Result.Top, MiddleY - Objects[Index].Height div 2);
        Result.Bottom :=
            Max(Result.Bottom, MiddleY - Objects[Index].Height div 2 + Objects[Index].Height);
      end;
  end;
  TCFontEC(PtrUInt(Self) + 0).ObjectCount := SavedObjectCount;
end;

function TCFontEC.GetGlyphAdvance(CharCode: WideChar): Integer; cdecl;
var
  Index: Integer;
  Glyph: PAftGlyphEC;
begin
  Result := 0;
  Index := GlyphLookup^[Ord(CharCode)];
  if Index = 0 then
    Exit;
  Glyph := PAftGlyphEC(PByte(Glyphs) + (Index - 1) * SizeOf(TAftGlyphEC));
  Result := Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
end;

function TCFontEC.HasGlyph(CharCode: WideChar): Boolean;
begin
  Result := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(CharCode) * 2)) > 0;
end;

procedure TCFontEC.WrapTaggedTextIntoLines(
    Lines: TStringsEC;
    const Text: WideString;
    MaxWidth: Integer
);
var
  TokenLength,
  WordStart,
  Index,
  CharCount,
  WordLength,
  FitEnd,
  WordWidth,
  LineWidth,
  LineStart,
  LineLength: Integer;
  FirstLine, SeenCharacter: Boolean;
  ObjectIndex, SavedObjectCount, FieldWidth, Alignment: Integer;
  Ch: WideChar;
begin
  SavedObjectCount := ObjectCount;
  Lines.Clear;
  LineWidth := 0;
  WordStart := 0;
  LineStart := 0;
  LineLength := 0;
  CharCount := Length(Text);
  FirstLine := True;
  while WordStart < CharCount do
  begin
    SeenCharacter := False;
    // Delphi O- left the exhausted FOR index one past the last character.
    // FPC leaves it at the upper bound, so use an explicit scan to make progress.
    Index := WordStart;
    while Index < CharCount do
    begin
      if (Text[Index + 1] = ' ') and SeenCharacter then
        Break;
      SeenCharacter := True;
      Inc(Index);
    end;
    WordLength := Index - WordStart;
    WordWidth := 0;
    Index := WordStart;
    FitEnd := 0;
    while Index <= WordStart + WordLength - 1 do
    begin
      Ch := PFontTextCharsEC(Pointer(Text))^[Index];
      Inc(Index);
      TokenLength :=
          GetTaggedTextTokenLength(
              PWideChar(Text) + Index - 1,
              WordLength - (Index - 1 - WordStart)
          );
      if TokenLength > 0 then
      begin
        if ParseObjectTagCached(
                PWideChar(Text) + Index - 1,
                WordLength - (Index - 1 - WordStart),
                ObjectIndex)
            > 0 then
        begin
          Inc(WordWidth, Objects[ObjectIndex].Width);
          if WordWidth <= MaxWidth then
            FitEnd := Index - 1 + TokenLength - 1;
        end
        else if MatchFixTag(PWideChar(Text) + Index - 1, WordLength - (Index - 1 - WordStart))
            > 0 then
          Inc(FixedWidthDepth)
        else if MatchFixEndTag(PWideChar(Text) + Index - 1, WordLength - (Index - 1 - WordStart))
            > 0 then
          FixedWidthDepth := Max(FixedWidthDepth - 1, 0) + 0
        else if ParseFormatTag(
                PWideChar(Text) + Index - 1,
                WordLength - (Index - 1 - WordStart),
                FieldWidth,
                Alignment)
            > 0 then
        begin
          Index := Index + TokenLength - 1;
          while Index < CharCount do
          begin
            Ch := PFontTextCharsEC(Pointer(Text))^[Index];
            Inc(Index);
            TokenLength :=
                GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
            if TokenLength > 0 then
            begin
              if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
                Inc(FixedWidthDepth)
              else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
                FixedWidthDepth := Max(FixedWidthDepth - 1, 0) + 0
              else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
              begin
                Index := Index + TokenLength - 1;
                if FieldWidth > 0 then
                begin
                  if FixedWidthDepth > 0 then
                    WordWidth := WordWidth + MaxGlyphAdvance * FieldWidth
                  else
                    WordWidth := WordWidth + GetGlyphAdvance(' ') * FieldWidth;
                end;
                Break;
              end;
              Index := Index + TokenLength - 1;
            end
            else
            begin
              Dec(FieldWidth);
              if FixedWidthDepth > 0 then
                WordWidth := WordWidth + MaxGlyphAdvance
              else
                WordWidth := WordWidth + GetGlyphAdvance(Ch);
            end;
          end;
          WordLength := Index - WordStart;
          if WordWidth <= MaxWidth then
            FitEnd := Index - 1 - 1;
          Continue;
        end;
        Index := Index + TokenLength - 1;
      end
      else
      begin
        if FixedWidthDepth > 0 then
          WordWidth := WordWidth + MaxGlyphAdvance
        else
          WordWidth := WordWidth + GetGlyphAdvance(Ch);
        if WordWidth <= MaxWidth then
          FitEnd := Index - 1 - 1;
      end;
    end;
    if LineWidth = 0 then
    begin
      if WordWidth > MaxWidth then
      begin
        TokenLength := 0;
        if not FirstLine then
          while Text[LineStart + 1 + TokenLength] = ' ' do
            Inc(TokenLength);
        if LineLength - TokenLength > 0 then
          Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength)
        else
        begin
          Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, FitEnd + 1 - WordStart);
          WordStart := FitEnd + 1;
          WordLength := 0;
          WordWidth := 0;
        end;
        FirstLine := False;
      end;
      LineStart := WordStart;
      WordStart := WordStart + WordLength;
      LineWidth := WordWidth;
      LineLength := WordLength;
    end
    else if LineWidth + WordWidth <= MaxWidth then
    begin
      WordStart := WordStart + WordLength;
      LineWidth := LineWidth + WordWidth;
      LineLength := LineLength + WordLength;
    end
    else
    begin
      TokenLength := 0;
      if not FirstLine then
        while Text[LineStart + 1 + TokenLength] = ' ' do
          Inc(TokenLength);
      Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength);
      FirstLine := False;
      LineStart := WordStart;
      WordStart := WordStart + WordLength;
      LineWidth := WordWidth;
      LineLength := WordLength;
    end;
  end;
  TokenLength := 0;
  LineLength := CharCount - LineStart;
  if not FirstLine then
    while Text[LineStart + 1 + TokenLength] = ' ' do
      Inc(TokenLength);
  if LineLength - TokenLength > 0 then
    Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength);
  ObjectCount := SavedObjectCount + 0;
end;

procedure TCFontEC.DrawTaggedText16(
    Destination: Pointer;
    PitchBytes, X, Y: Integer;
    const Text: WideString;
    ClipRect: TRect
);
var
  Index, GlyphIndex, CharCount, TokenLength, PosX: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
  ObjectIndex, SavedObjectCount, Top, Bottom, MiddleY, FieldWidth, Alignment: Integer;
  Clip: TRect;
begin
  Top := 999999999;
  Bottom := -999999999;
  SavedObjectCount := ObjectCount;
  Clip.Left := ClipRect.Left;
  Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1;
  Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then
    Exit;
  Index := 0;
  PosX := 0;
  FieldWidth := -1;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      ParseTabTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      ParseAlignTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      if ParseObjectTagCached(PWideChar(Text) + Index - 1, CharCount - Index + 1, ObjectIndex)
          > 0 then
      begin
        Objects[ObjectIndex].X := X + PosX;
        Inc(PosX, Objects[ObjectIndex].Width);
      end
      else if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        TCFontEC(PtrUInt(Self) + 0).FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index - 1,
                  CharCount - Index + 1,
                  FieldWidth,
                  Alignment)
              > 0) then
      begin
        Index := Index + TokenLength - 1;
        Dec(
            FieldWidth,
            CountVisibleTaggedCharsUntilFormatEnd(PWideChar(Text) + Index, CharCount - Index)
        );
        if FieldWidth > 0 then
        begin
          if Alignment = 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + (MaxGlyphAdvance + 0) * (FieldWidth shr 1)
            else
              PosX := PosX + GetGlyphAdvance(' ') * (FieldWidth shr 1);
            FieldWidth := FieldWidth - (FieldWidth shr 1);
          end
          else if Alignment > 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * FieldWidth
            else
              PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
            FieldWidth := -1;
          end;
        end
        else
          FieldWidth := -1;
        Continue;
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
      begin
        if FieldWidth > 0 then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance * FieldWidth
          else
            PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
          FieldWidth := -1;
        end;
      end;
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
      if GlyphIndex <> 0 then
      begin
        Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
        begin
          if (Y + 0) + Glyph.OpaqueMaskPlane.Top < Top then
            Top := (Y + 0) + Glyph.OpaqueMaskPlane.Top;
          if (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > Bottom then
            Bottom := (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height;
          Ex_OKGR_MaskBuf_DrawClip_WORD(
              Destination,
              PitchBytes,
              X + PosX + Glyph.OpaqueMaskPlane.Left,
              (Y + 0) + Glyph.OpaqueMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset),
              GetCurrentColor,
              Clip
          );
        end;
        if Glyph.AlphaMaskPlane.DataOffset <> 0 then
        begin
          if (Y + 0) + Glyph.AlphaMaskPlane.Top < Top then
            Top := (Y + 0) + Glyph.AlphaMaskPlane.Top;
          if (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > Bottom then
            Bottom := (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height;
          Ex_OKGR_TransBuf_FillAlphaClip_16(
              Destination,
              PitchBytes,
              X + PosX + Glyph.AlphaMaskPlane.Left,
              (Y + 0) + Glyph.AlphaMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset),
              Clip,
              GetCurrentColor
          );
        end;
        if FixedWidthDepth > 0 then
          PosX := PosX + MaxGlyphAdvance
        else
          PosX := (PosX + 0) + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
      end;
    end;
  end;
  if ObjectCount - SavedObjectCount > 0 then
  begin
    MiddleY := (Top + Bottom) div 2;
    for Index := SavedObjectCount to ObjectCount - 1 do
      if Objects[Index].VerticalMode = 0 then
        Objects[Index].Y := MiddleY - Objects[Index].Height div 2;
  end;
end;

procedure TCFontEC.DrawTaggedText32(
    Destination: Pointer;
    PitchBytes, X, Y: Integer;
    const Text: WideString;
    ClipRect: TRect
);
var
  Index, GlyphIndex, CharCount, TokenLength, PosX: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
  ObjectIndex, SavedObjectCount, Top, Bottom, MiddleY, FieldWidth, Alignment: Integer;
  Clip: TRect;
begin
  Top := 999999999;
  Bottom := -999999999;
  SavedObjectCount := ObjectCount;
  Clip.Left := ClipRect.Left;
  Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1;
  Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then
    Exit;
  Index := 0;
  PosX := 0;
  FieldWidth := -1;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      ParseTabTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      ParseAlignTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      if ParseObjectTagCached(PWideChar(Text) + Index - 1, CharCount - Index + 1, ObjectIndex)
          > 0 then
      begin
        Objects[ObjectIndex].X := X + PosX;
        Inc(PosX, Objects[ObjectIndex].Width);
      end
      else if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        TCFontEC(PtrUInt(Self) + 0).FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index - 1,
                  CharCount - Index + 1,
                  FieldWidth,
                  Alignment)
              > 0) then
      begin
        Index := Index + TokenLength - 1;
        Dec(
            FieldWidth,
            CountVisibleTaggedCharsUntilFormatEnd(PWideChar(Text) + Index, CharCount - Index)
        );
        if FieldWidth > 0 then
        begin
          if Alignment = 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + (MaxGlyphAdvance + 0) * (FieldWidth shr 1)
            else
              PosX := PosX + GetGlyphAdvance(' ') * (FieldWidth shr 1);
            FieldWidth := FieldWidth - (FieldWidth shr 1);
          end
          else if Alignment > 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * FieldWidth
            else
              PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
            FieldWidth := -1;
          end;
        end
        else
          FieldWidth := -1;
        Continue;
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
      begin
        if FieldWidth > 0 then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance * FieldWidth
          else
            PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
          FieldWidth := -1;
        end;
      end;
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
      if GlyphIndex <> 0 then
      begin
        Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
        begin
          if (Y + 0) + Glyph.OpaqueMaskPlane.Top < Top then
            Top := (Y + 0) + Glyph.OpaqueMaskPlane.Top;
          if (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > Bottom then
            Bottom := (Y + 0) + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height;
          Ex_OKGR_MaskBuf_DrawClip_DWORD(
              Destination,
              PitchBytes,
              X + PosX + Glyph.OpaqueMaskPlane.Left,
              (Y + 0) + Glyph.OpaqueMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset),
              GetCurrentColor,
              Clip
          );
        end;
        if Glyph.AlphaMaskPlane.DataOffset <> 0 then
        begin
          if (Y + 0) + Glyph.AlphaMaskPlane.Top < Top then
            Top := (Y + 0) + Glyph.AlphaMaskPlane.Top;
          if (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > Bottom then
            Bottom := (Y + 0) + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height;
          Ex_OKGR_TransBuf_FillAlphaClip_RGBA(
              Destination,
              PitchBytes,
              X + PosX + Glyph.AlphaMaskPlane.Left,
              (Y + 0) + Glyph.AlphaMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset),
              Clip,
              GetCurrentColor
          );
        end;
        if FixedWidthDepth > 0 then
          PosX := PosX + MaxGlyphAdvance
        else
          PosX := (PosX + 0) + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
      end;
    end;
  end;
  if ObjectCount - SavedObjectCount > 0 then
  begin
    MiddleY := (Top + Bottom) div 2;
    for Index := SavedObjectCount to ObjectCount - 1 do
      if Objects[Index].VerticalMode = 0 then
        Objects[Index].Y := MiddleY - Objects[Index].Height div 2;
  end;
end;

procedure TCFontEC.DrawJustifiedTaggedText16(
    Destination: Pointer;
    PitchBytes, X, Y: Integer;
    const Text: WideString;
    Width: Integer;
    ClipRect: TRect
);
var
  Character: WideChar;
  Lookup: PFontGlyphLookupEC;
  GlyphIndex: Integer;
  GlyphBase, Glyph: PAftGlyphEC;
  ContentWidth, CharCount, Index, SpaceCount: Integer;
  SpaceWidth, PosX: Double;
  Leading: Boolean;
  TokenLength,
  ObjectIndex,
  SavedObjectCount,
  Top,
  Bottom,
  MiddleY,
  FieldWidth,
  Alignment,
  ParsedWidth,
  ParsedAlignment: Integer;
  Clip: TRect;
begin
  Top := 999999999;
  Bottom := -999999999;
  SavedObjectCount := ObjectCount;
  Clip.Left := ClipRect.Left;
  Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1;
  Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then
    Exit;
  ContentWidth := 0;
  SpaceCount := 0;
  Leading := True;
  Index := 0;
  FieldWidth := -1;
  ParsedWidth := -1;
  while Index < CharCount do
  begin
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index, CharCount - Index);
    if TokenLength > 0 then
    begin
      if ParseObjectTagCached(PWideChar(Text) + Index, CharCount - Index, ObjectIndex) > 0 then
      begin
        Inc(ContentWidth, Objects[ObjectIndex].Width);
        Leading := False;
      end
      else if MatchFixTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index,
                  CharCount - Index,
                  ParsedWidth,
                  ParsedAlignment)
              > 0) then
      begin
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        ParsedWidth := -1;
      Inc(Index, TokenLength);
    end
    else
    begin
      if (Text[Index + 1] <> ' ') or (FieldWidth > 0) or (FixedWidthDepth > 0) then
      begin
        if FixedWidthDepth > 0 then
          Inc(ContentWidth, MaxGlyphAdvance)
        else
          Inc(ContentWidth, GetGlyphAdvance(Text[Index + 1]));
        Leading := False;
      end
      else if Leading = True then
        Inc(ContentWidth, GetGlyphAdvance(Text[Index + 1]))
      else
        Inc(SpaceCount);
      Inc(Index);
    end;
  end;
  if SpaceCount < 1 then
  begin
    DrawTaggedText16(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  SpaceWidth := (Width - ContentWidth) / SpaceCount;
  if SpaceWidth < 2.0 then
  begin
    DrawTaggedText16(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  ObjectCount := SavedObjectCount;
  Lookup := GlyphLookup;
  GlyphBase := Glyphs;
  PosX := X;
  Leading := True;
  Index := 0;
  while Index < CharCount do
  begin
    Character := Text[Index + 1];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      if ParseObjectTagCached(PWideChar(Text) + Index - 1, CharCount - Index + 1, ObjectIndex)
          > 0 then
      begin
        Objects[ObjectIndex].X := Trunc(PosX);
        PosX := PosX + Objects[ObjectIndex].Width;
        Leading := False;
      end
      else if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index - 1,
                  CharCount - Index + 1,
                  ParsedWidth,
                  ParsedAlignment)
              > 0) then
      begin
        FieldWidth := ParsedWidth;
        Alignment := ParsedAlignment;
        Index := Index + TokenLength - 1;
        Dec(
            FieldWidth,
            CountVisibleTaggedCharsUntilFormatEnd(PWideChar(Text) + Index, CharCount - Index)
        );
        if FieldWidth > 0 then
        begin
          if Alignment = 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * (FieldWidth shr 1)
            else
              PosX := PosX + GetGlyphAdvance(' ') * (FieldWidth shr 1);
            Dec(FieldWidth, FieldWidth shr 1);
          end
          else if Alignment > 0 then
          begin
            PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
            FieldWidth := -1;
          end;
        end
        else
          FieldWidth := -1;
        Continue;
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
      begin
        ParsedWidth := -1;
        if FieldWidth > 0 then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance * FieldWidth
          else
            PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
          FieldWidth := -1;
        end;
      end;
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := Lookup^[Ord(Character)];
      if GlyphIndex <> 0 then
      begin
        Glyph := PAftGlyphEC(PByte(GlyphBase) + (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
        begin
          if Y + Glyph.OpaqueMaskPlane.Top < Top then
            Top := Y + Glyph.OpaqueMaskPlane.Top;
          if Y + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > Bottom then
            Bottom := Y + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height;
          Ex_OKGR_MaskBuf_DrawClip_WORD(
              Destination,
              PitchBytes,
              Integer(Trunc(PosX)) + Glyph.OpaqueMaskPlane.Left,
              Y + Glyph.OpaqueMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset),
              GetCurrentColor,
              Clip
          );
        end;
        if Glyph.AlphaMaskPlane.DataOffset <> 0 then
        begin
          if Y + Glyph.AlphaMaskPlane.Top < Top then
            Top := Y + Glyph.AlphaMaskPlane.Top;
          if Y + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > Bottom then
            Bottom := Y + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height;
          Ex_OKGR_TransBuf_FillAlphaClip_16(
              Destination,
              PitchBytes,
              Integer(Trunc(PosX)) + Glyph.AlphaMaskPlane.Left,
              Y + Glyph.AlphaMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset),
              Clip,
              GetCurrentColor
          );
        end;
        if (Character <> ' ') or (FieldWidth > 0) or (FixedWidthDepth > 0) then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance
          else
            PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
          Leading := False;
        end
        else if Leading = True then
          PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC
        else
          PosX := PosX + SpaceWidth;
      end;
    end;
  end;
  if ObjectCount - SavedObjectCount > 0 then
  begin
    MiddleY := (Top + Bottom) div 2;
    for Index := SavedObjectCount to ObjectCount - 1 do
      if Objects[Index].VerticalMode = 0 then
        Objects[Index].Y := MiddleY - Objects[Index].Height div 2;
  end;
end;

procedure TCFontEC.DrawJustifiedTaggedText32(
    Destination: Pointer;
    PitchBytes, X, Y: Integer;
    const Text: WideString;
    Width: Integer;
    ClipRect: TRect
);
var
  Character: WideChar;
  Lookup: PFontGlyphLookupEC;
  GlyphIndex: Integer;
  GlyphBase, Glyph: PAftGlyphEC;
  ContentWidth, CharCount, Index, SpaceCount: Integer;
  SpaceWidth, PosX: Double;
  Leading: Boolean;
  TokenLength,
  ObjectIndex,
  SavedObjectCount,
  Top,
  Bottom,
  MiddleY,
  FieldWidth,
  Alignment,
  ParsedWidth,
  ParsedAlignment: Integer;
  Clip: TRect;
begin
  Top := 999999999;
  Bottom := -999999999;
  SavedObjectCount := ObjectCount;
  Clip.Left := ClipRect.Left;
  Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1;
  Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then
    Exit;
  ContentWidth := 0;
  SpaceCount := 0;
  Leading := True;
  Index := 0;
  FieldWidth := -1;
  ParsedWidth := -1;
  while Index < CharCount do
  begin
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index, CharCount - Index);
    if TokenLength > 0 then
    begin
      if ParseObjectTagCached(PWideChar(Text) + Index, CharCount - Index, ObjectIndex) > 0 then
      begin
        Inc(ContentWidth, Objects[ObjectIndex].Width);
        Leading := False;
      end
      else if MatchFixTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index,
                  CharCount - Index,
                  ParsedWidth,
                  ParsedAlignment)
              > 0) then
      begin
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index, CharCount - Index) > 0 then
        ParsedWidth := -1;
      Inc(Index, TokenLength);
    end
    else
    begin
      if (Text[Index + 1] <> ' ') or (FieldWidth > 0) or (FixedWidthDepth > 0) then
      begin
        if FixedWidthDepth > 0 then
          Inc(ContentWidth, MaxGlyphAdvance)
        else
          Inc(ContentWidth, GetGlyphAdvance(Text[Index + 1]));
        Leading := False;
      end
      else if Leading = True then
        Inc(ContentWidth, GetGlyphAdvance(Text[Index + 1]))
      else
        Inc(SpaceCount);
      Inc(Index);
    end;
  end;
  if SpaceCount < 1 then
  begin
    DrawTaggedText32(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  SpaceWidth := (Width - ContentWidth) / SpaceCount;
  if SpaceWidth < 2.0 then
  begin
    DrawTaggedText32(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  ObjectCount := SavedObjectCount;
  Lookup := GlyphLookup;
  GlyphBase := Glyphs;
  PosX := X;
  Leading := True;
  Index := 0;
  while Index < CharCount do
  begin
    Character := Text[Index + 1];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      if ParseObjectTagCached(PWideChar(Text) + Index - 1, CharCount - Index + 1, ObjectIndex)
          > 0 then
      begin
        Objects[ObjectIndex].X := Trunc(PosX);
        PosX := PosX + Objects[ObjectIndex].Width;
        Leading := False;
      end
      else if MatchFixTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        Inc(FixedWidthDepth)
      else if MatchFixEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
        FixedWidthDepth := Max(FixedWidthDepth - 1, 0)
      else if (FieldWidth < 0)
          and (ParseFormatTag(
                  PWideChar(Text) + Index - 1,
                  CharCount - Index + 1,
                  ParsedWidth,
                  ParsedAlignment)
              > 0) then
      begin
        FieldWidth := ParsedWidth;
        Alignment := ParsedAlignment;
        Index := Index + TokenLength - 1;
        Dec(
            FieldWidth,
            CountVisibleTaggedCharsUntilFormatEnd(PWideChar(Text) + Index, CharCount - Index)
        );
        if FieldWidth > 0 then
        begin
          if Alignment = 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * (FieldWidth shr 1)
            else
              PosX := PosX + GetGlyphAdvance(' ') * (FieldWidth shr 1);
            Dec(FieldWidth, FieldWidth shr 1);
          end
          else if Alignment > 0 then
          begin
            if FixedWidthDepth > 0 then
              PosX := PosX + MaxGlyphAdvance * FieldWidth
            else
              PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
            FieldWidth := -1;
          end;
        end
        else
          FieldWidth := -1;
        Continue;
      end
      else if MatchFormatEndTag(PWideChar(Text) + Index - 1, CharCount - Index + 1) > 0 then
      begin
        ParsedWidth := -1;
        if FieldWidth > 0 then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance * FieldWidth
          else
            PosX := PosX + GetGlyphAdvance(' ') * FieldWidth;
          FieldWidth := -1;
        end;
      end;
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := Lookup^[Ord(Character)];
      if GlyphIndex <> 0 then
      begin
        Glyph := PAftGlyphEC(PByte(GlyphBase) + (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
        begin
          if Y + Glyph.OpaqueMaskPlane.Top < Top then
            Top := Y + Glyph.OpaqueMaskPlane.Top;
          if Y + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > Bottom then
            Bottom := Y + Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height;
          Ex_OKGR_MaskBuf_DrawClip_DWORD(
              Destination,
              PitchBytes,
              Integer(Trunc(PosX)) + Glyph.OpaqueMaskPlane.Left,
              Y + Glyph.OpaqueMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset),
              GetCurrentColor,
              Clip
          );
        end;
        if Glyph.AlphaMaskPlane.DataOffset <> 0 then
        begin
          if Y + Glyph.AlphaMaskPlane.Top < Top then
            Top := Y + Glyph.AlphaMaskPlane.Top;
          if Y + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > Bottom then
            Bottom := Y + Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height;
          Ex_OKGR_TransBuf_FillAlphaClip_RGBA(
              Destination,
              PitchBytes,
              Integer(Trunc(PosX)) + Glyph.AlphaMaskPlane.Left,
              Y + Glyph.AlphaMaskPlane.Top,
              AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset),
              Clip,
              GetCurrentColor
          );
        end;
        if (Character <> ' ') or (FieldWidth > 0) or (FixedWidthDepth > 0) then
        begin
          if FixedWidthDepth > 0 then
            PosX := PosX + MaxGlyphAdvance
          else
            PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
          Leading := False;
        end
        else if Leading = True then
          PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC
        else
          PosX := PosX + SpaceWidth;
      end;
    end;
  end;
  if ObjectCount - SavedObjectCount > 0 then
  begin
    MiddleY := (Top + Bottom) div 2;
    for Index := SavedObjectCount to ObjectCount - 1 do
      if Objects[Index].VerticalMode = 0 then
        Objects[Index].Y := MiddleY - Objects[Index].Height div 2;
  end;
end;

function TCFontEC.GetTaggedTextTokenLength(Text: PWideChar; CharCount: Integer): Integer;
var
  Index: Integer;
begin
  Result := 0;
  if CharCount < 2 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] = '<' then
  begin
    Result := 0;
    Exit;
  end;
  Index := 1;
  while Index < CharCount do
  begin
    if Text[Index] = '>' then
      Break;
    Inc(Index);
  end;
  if Index < CharCount then
    Result := Index + 1;
end;

function TCFontEC.ParseTabTagAndAdjustX(
    Text: PWideChar;
    CharCount: Integer;
    var X: Integer
): Integer;
var
  Value, Index: Integer;
begin
  Result := 0;
  if CharCount < 4 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 't') and (Text[1] <> 'T') then
    Exit;
  if (Text[2] <> 'd') and (Text[2] <> 'D') then
    Exit;
  if (Text[3] <> '=') and (Text[3] <> '=') then
    Exit;
  Value := 0;
  Index := 4;
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Value := Value * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if (Index < CharCount) and (Text[Index] = '>') then
  begin
    Result := Index + 1;
    if X < Value then
      X := Value;
  end;
end;

function TCFontEC.ParseAlignTagAndAdjustX(
    Text: PWideChar;
    CharCount: Integer;
    var X: Integer
): Integer;
var
  Ch: WideChar;
  AlignRight: Boolean;
  Index, GlyphIndex, Width, TextLength, TokenLength: Integer;
  Glyph: PAftGlyphEC;
  ObjectIndex, SavedObjectCount: Integer;
  TextCopy: WideString;
begin
  SavedObjectCount := ObjectCount;
  Result := 0;
  if CharCount < 7 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 'a') and (Text[1] <> 'A') then
    Exit;
  if (Text[2] <> 'l') and (Text[2] <> 'L') then
    Exit;
  if (Text[3] <> 'i') and (Text[3] <> 'I') then
    Exit;
  if (Text[4] <> 'g') and (Text[4] <> 'G') then
    Exit;
  if (Text[5] <> 'n') and (Text[5] <> 'N') then
    Exit;
  if (Text[6] <> '=') and (Text[6] <> '=') then
    Exit;
  Index := 0;
  AlignRight := False;
  if CharCount >= 13 then
  begin
    AlignRight :=
        ((Text[7] = 'r') or (Text[1] = 'R'))
            and ((Text[8] = 'i') or (Text[2] = 'I'))
            and ((Text[9] = 'g') or (Text[3] = 'G'))
            and ((Text[10] = 'h') or (Text[4] = 'H'))
            and ((Text[11] = 't') or (Text[5] = 'T'))
            and (Text[12] = '>');
    Index := 13;
  end;
  if not AlignRight then
  begin
    if CharCount < 14 then
      Exit;
    if (Text[7] <> 'c') and (Text[1] <> 'C') then
      Exit;
    if (Text[8] <> 'e') and (Text[2] <> 'E') then
      Exit;
    if (Text[9] <> 'n') and (Text[3] <> 'N') then
      Exit;
    if (Text[10] <> 't') and (Text[4] <> 'T') then
      Exit;
    if (Text[11] <> 'e') and (Text[5] <> 'E') then
      Exit;
    if (Text[12] <> 'r') and (Text[5] <> 'R') then
      Exit;
    if Text[13] <> '>' then
      Exit;
    Index := 14;
  end;
  Result := Index;
  TextCopy := Text;
  TextLength := Length(TextCopy);
  Width := 0;
  while Index < TextLength do
  begin
    Ch := Text[Index];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(Text + Index - 1, TextLength - Index + 1);
    if TokenLength > 0 then
    begin
      if MatchAlignEndTag(Text + Index - 1, TextLength - Index + 1) > 0 then
        Break;
      if ParseObjectTagCached(Text + Index - 1, TextLength - Index + 1, ObjectIndex) > 0 then
        Inc(Width, Objects[ObjectIndex].Width);
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
      if GlyphIndex <> 0 then
      begin
        Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        Width := Glyph.AdvanceA + Width + Glyph.AdvanceB + Glyph.AdvanceC;
      end;
    end;
  end;
  if AlignRight then
    X := X - Width
  else
    X := X - Width div 2;
  ObjectCount := SavedObjectCount;
end;

function TCFontEC.MatchAlignEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount < 8 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] <> '/' then
    Exit;
  if (Text[2] <> 'a') and (Text[2] <> 'A') then
    Exit;
  if (Text[3] <> 'l') and (Text[3] <> 'L') then
    Exit;
  if (Text[4] <> 'i') and (Text[4] <> 'I') then
    Exit;
  if (Text[5] <> 'g') and (Text[5] <> 'G') then
    Exit;
  if (Text[6] <> 'n') and (Text[6] <> 'N') then
    Exit;
  if Text[7] = '>' then
    Result := 8;
end;

function TCFontEC.MatchFixTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount < 5 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 'f') and (Text[1] <> 'F') then
    Exit;
  if (Text[2] <> 'i') and (Text[2] <> 'I') then
    Exit;
  if (Text[3] <> 'x') and (Text[3] <> 'X') then
    Exit;
  if Text[4] = '>' then
    Result := 5;
end;

function TCFontEC.MatchFixEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount < 6 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] <> '/' then
    Exit;
  if (Text[2] <> 'f') and (Text[2] <> 'F') then
    Exit;
  if (Text[3] <> 'i') and (Text[3] <> 'I') then
    Exit;
  if (Text[4] <> 'x') and (Text[4] <> 'X') then
    Exit;
  if Text[5] = '>' then
    Result := 6;
end;

function TCFontEC.ParseFormatTag(
    Text: PWideChar;
    CharCount: Integer;
    out FieldWidth, Alignment: Integer
): Integer;
var
  Index: Integer;
begin
  Result := 0;
  if CharCount < 13 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 'f') and (Text[1] <> 'F') then
    Exit;
  if (Text[2] <> 'o') and (Text[2] <> 'O') then
    Exit;
  if (Text[3] <> 'r') and (Text[3] <> 'R') then
    Exit;
  if (Text[4] <> 'm') and (Text[4] <> 'M') then
    Exit;
  if (Text[5] <> 'a') and (Text[5] <> 'A') then
    Exit;
  if (Text[6] <> 't') and (Text[6] <> 'T') then
    Exit;
  if (Text[7] <> '=') and (Text[7] <> '=') then
    Exit;
  FieldWidth := 0;
  Alignment := 0;
  Index := 8;
  if (Index + 5 <= CharCount)
      and ((Text[Index] = 'r') or (Text[Index] = 'R'))
      and ((Text[Index + 1] = 'i') or (Text[Index + 1] = 'I'))
      and ((Text[Index + 2] = 'g') or (Text[Index + 2] = 'G'))
      and ((Text[Index + 3] = 'h') or (Text[Index + 3] = 'H'))
      and ((Text[Index + 4] = 't') or (Text[Index + 4] = 'T')) then
  begin
    Alignment := 1;
    Inc(Index, 5);
  end
  else if (Index + 4 <= CharCount)
      and ((Text[Index] = 'l') or (Text[Index] = 'L'))
      and ((Text[Index + 1] = 'e') or (Text[Index + 1] = 'E'))
      and ((Text[Index + 2] = 'f') or (Text[Index + 2] = 'F'))
      and ((Text[Index + 3] = 't') or (Text[Index + 3] = 'T')) then
  begin
    Alignment := -1;
    Inc(Index, 4);
  end
  else if (Index + 6 <= CharCount)
      and ((Text[Index] = 'c') or (Text[Index] = 'C'))
      and ((Text[Index + 1] = 'e') or (Text[Index + 1] = 'E'))
      and ((Text[Index + 2] = 'n') or (Text[Index + 2] = 'N'))
      and ((Text[Index + 3] = 't') or (Text[Index + 3] = 'T'))
      and ((Text[Index + 4] = 'e') or (Text[Index + 4] = 'E'))
      and ((Text[Index + 5] = 'r') or (Text[Index + 5] = 'R')) then
  begin
    Alignment := 0;
    Inc(Index, 6);
  end
  else
    Exit;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    FieldWidth := FieldWidth * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if (Index < CharCount) and (Text[Index] = '>') then
    Result := Index + 1;
end;

function TCFontEC.MatchFormatEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount < 9 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] <> '/' then
    Exit;
  if (Text[2] <> 'f') and (Text[2] <> 'F') then
    Exit;
  if (Text[3] <> 'o') and (Text[3] <> 'O') then
    Exit;
  if (Text[4] <> 'r') and (Text[4] <> 'R') then
    Exit;
  if (Text[5] <> 'm') and (Text[5] <> 'M') then
    Exit;
  if (Text[6] <> 'a') and (Text[6] <> 'A') then
    Exit;
  if (Text[7] <> 't') and (Text[7] <> 'T') then
    Exit;
  if Text[8] = '>' then
    Result := 9;
end;

function TCFontEC.CountVisibleTaggedCharsUntilFormatEnd(
    Text: PWideChar;
    CharCount: Integer
): Integer;
var
  Index, GlyphIndex, TokenLength: Integer;
  Ch: WideChar;
begin
  Result := 0;
  Index := 0;
  while Index < CharCount do
  begin
    Ch := PFontTextCharsEC(Text)^[Index];
    Inc(Index);
    TokenLength := GetTaggedTextTokenLength(Text + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      if MatchFormatEndTag(Text + Index - 1, CharCount - Index + 1) > 0 then
        Break;
      Index := Index + TokenLength - 1;
    end
    else
    begin
      GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
      if GlyphIndex <> 0 then
        Inc(Result);
    end;
  end;
end;

function TCFontEC.ParseObjectTagCached(
    Text: PWideChar;
    CharCount: Integer;
    out ObjectIndex: Integer
): Integer;
begin
  if ObjectCount <= ObjectCapacity then
  begin
    ObjectCapacity := ObjectCount + 4;
    SetLength(Objects, ObjectCapacity);
  end;
  ObjectIndex := -1;
  Result := ParseObjectTag(Text, CharCount, Objects[ObjectCount]);
  if Result > 0 then
  begin
    ObjectIndex := ObjectCount;
    Inc(ObjectCount);
  end;
end;

function TCFontEC.ParseObjectTag(
    Text: PWideChar;
    CharCount: Integer;
    out Item: TFontObjectEC
): Integer;
var
  Index: Integer;
begin
  Result := 0;
  if CharCount < 13 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 'o') and (Text[1] <> 'O') then
    Exit;
  if (Text[2] <> 'b') and (Text[2] <> 'B') then
    Exit;
  if (Text[3] <> 'j') and (Text[3] <> 'J') then
    Exit;
  if (Text[4] <> 'e') and (Text[4] <> 'E') then
    Exit;
  if (Text[5] <> 'c') and (Text[5] <> 'C') then
    Exit;
  if (Text[6] <> 't') and (Text[6] <> 'T') then
    Exit;
  if (Text[7] <> '=') and (Text[7] <> '=') then
    Exit;
  Item.ObjectId := 0;
  Item.Width := 0;
  Item.Height := 0;
  Item.VerticalMode := 0;
  Index := 8;
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Item.ObjectId := Item.ObjectId * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Item.Width := Item.Width * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Item.Height := Item.Height * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Item.VerticalMode := Item.VerticalMode * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if (Index < CharCount) and (Text[Index] = '>') then
    Result := Index + 1;
end;

function TCFontEC.ParseColorTag(Text: PWideChar; CharCount: Integer; out Color: Cardinal): Integer;
var
  Red, Green, Blue, Index: Integer;
begin
  Result := 0;
  if CharCount < 13 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if (Text[1] <> 'c') and (Text[1] <> 'C') then
    Exit;
  if (Text[2] <> 'o') and (Text[2] <> 'O') then
    Exit;
  if (Text[3] <> 'l') and (Text[3] <> 'L') then
    Exit;
  if (Text[4] <> 'o') and (Text[4] <> 'O') then
    Exit;
  if (Text[5] <> 'r') and (Text[5] <> 'R') then
    Exit;
  if (Text[6] <> '=') and (Text[6] <> '=') then
    Exit;
  Red := 0;
  Green := 0;
  Blue := 0;
  Index := 7;
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Red := Red * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Green := Green * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> ',' then
    Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then
      Break;
    Blue := Blue * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then
    Exit;
  if Text[Index] <> '>' then
    Exit;
  Result := Index + 1;
  if not UseARGBColors then
    Color := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue)
  else
    Color := (Red shl 16) or (Green shl 8) or Blue or $FF000000;
end;

function TCFontEC.MatchColorEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount < 8 then
    Exit;
  if Text[0] <> '<' then
    Exit;
  if Text[1] <> '/' then
    Exit;
  if (Text[2] <> 'c') and (Text[2] <> 'C') then
    Exit;
  if (Text[3] <> 'o') and (Text[3] <> 'O') then
    Exit;
  if (Text[4] <> 'l') and (Text[4] <> 'L') then
    Exit;
  if (Text[5] <> 'o') and (Text[5] <> 'O') then
    Exit;
  if (Text[6] <> 'r') and (Text[6] <> 'R') then
    Exit;
  if Text[7] = '>' then
    Result := 8;
end;

procedure TCFontEC.ApplyColorTag(Text: PWideChar; CharCount: Integer);
var
  Color: Cardinal;
begin
  if ParseColorTag(Text, CharCount, Color) > 0 then
  begin
    if ColorTagsEnabled then
      PushColor(Color);
  end
  else if MatchColorEndTag(Text, CharCount) > 0 then
  begin
    if ColorTagsEnabled then
      PopColor;
  end;
end;

procedure TCFontEC.ClearColorStack;
begin
  if ColorStack <> nil then
  begin
    FreeEC(ColorStack);
    ColorStack := nil;
  end;
  ColorStackCount := 0;
end;

procedure TCFontEC.PushColor(Color: Cardinal);
begin
  Inc(ColorStackCount);
  ColorStack := ReAllocREC(ColorStack, ColorStackCount * SizeOf(Cardinal));
  WriteIntegerEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)), Color);
end;

function TCFontEC.PopColor: Cardinal;
begin
  if ColorStackCount < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Result := ReadDWordEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)));
  Dec(ColorStackCount);
end;

function TCFontEC.GetCurrentColor: Cardinal;
begin
  if not ColorTagsEnabled or (ColorStackCount < 1) then
    Result := DefaultColor
  else
    Result := ReadDWordEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)));
end;

procedure TCFontEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Index: Integer;
  Glyph: PAftGlyphEC;
begin
  ClearLoadedFontData;
  if SourceBuffer.DataSize < SizeOf(TAftHeaderEC) then
    raise Exception.Create('TCFontEC.Load. Error format file.');
  FontData := AllocEC(SourceBuffer.DataSize);
  CopyMemory(FontData, SourceBuffer.Data, SourceBuffer.DataSize);
  Glyphs := AddPointerOffset(FontData, SizeOf(TAftHeaderEC));
  if (FontData.Magic[0] <> 'a') or (FontData.Magic[1] <> 'f') or (FontData.Magic[2] <> 't') then
    raise Exception.Create('TCFontEC.Load. Error format file.');
  if FontData.Version <> 1 then
    raise Exception.Create('TCFontEC.Load. Unknown version of font.');
  GlyphCount := FontData.GlyphCount;
  GlyphLookup := AllocClearEC(SizeOf(TFontGlyphLookupEC));
  AboveBaseline := 0;
  BelowBaseline := 0;
  MaxGlyphAdvance := 0;
  Glyph := Glyphs;
  for Index := 0 to GlyphCount - 1 do
  begin
    WriteWordEC(AddPointerOffset(GlyphLookup, Glyph.CharCode * 2), Word(Index) + 1);
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
    begin
      if (Glyph.OpaqueMaskPlane.Top <= 0) and (-Glyph.OpaqueMaskPlane.Top + 1 > AboveBaseline) then
        AboveBaseline := -Glyph.OpaqueMaskPlane.Top + 1;
      if (Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > 0)
          and (Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height - 1 > BelowBaseline) then
        BelowBaseline := Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height - 1;
    end;
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then
    begin
      if (Glyph.AlphaMaskPlane.Top <= 0) and (-Glyph.AlphaMaskPlane.Top + 1 > AboveBaseline) then
        AboveBaseline := -Glyph.AlphaMaskPlane.Top + 1;
      if (Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > 0)
          and (Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height - 1 > BelowBaseline) then
        BelowBaseline := Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height - 1;
    end;
    MaxGlyphAdvance := Max(MaxGlyphAdvance, Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC);
    Glyph := AddPointerOffset(Glyph, SizeOf(TAftGlyphEC));
  end;
  ResidentBytes := 0;
end;

procedure TCFontEC.RenderTaggedTextToTexture(
    const Text: WideString;
    Width, Height, AlignX, AlignY: Integer;
    WordWrap: Boolean;
    ActualSize: PPoint;
    var Texture: IDirect3DTexture9
);
var
  TopAdjustment, CurrentY: Integer;
  Lines: TStringsEC;
  Bounds: TRect;
  WrappedLines: TStringsEC;
  DrawX, DrawY: Integer;
  SavedColorTags, CenteredTabs: Boolean;
  ImageSize: TPoint;
  Image: IDirect3DTexture9;
  Locked: TD3DLockedRect;
  Clip: TRect;
  function MeasureFontTextureTextSize: TPoint; // @addr 0x488024 @ida "void __usercall $name(TPoint *Result@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x004883E0"
  var
    First: Boolean;
    ExtraHeight: Integer;
    MergedBounds: TRect;
  begin
    MergedBounds.Left := 0;
    MergedBounds.Right := 0;
    MergedBounds.Top := 0;
    MergedBounds.Bottom := 0;
    CurrentY := 0;
    ExtraHeight := 0;
    Lines.First;
    if not WordWrap then
    begin
      if not Lines.IsAtEnd then
      begin
        MergedBounds := MeasureTaggedTextBounds(Lines.GetCurrentText, 0, CurrentY, @TopAdjustment);
        Inc(CurrentY, GetLineHeight);
        Lines.Next;
      end;
      while not Lines.IsAtEnd do
      begin
        Bounds := MeasureTaggedTextBounds(Lines.GetCurrentText, 0, CurrentY, nil);
        Windows.UnionRect(MergedBounds, MergedBounds, Bounds);
        Inc(CurrentY, GetLineHeight);
        Lines.Next;
      end;
    end
    else
    begin
      First := True;
      while not Lines.IsAtEnd do
      begin
        WrapTaggedTextIntoLines(WrappedLines, Lines.GetCurrentText, Width - 4);
        if not WrappedLines.IsEmpty then
        begin
          WrappedLines.First;
          if First then
          begin
            MergedBounds :=
                MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, CurrentY, @TopAdjustment);
            First := False;
            Inc(CurrentY, GetLineHeight);
            WrappedLines.Next;
          end;
          while not WrappedLines.IsAtEnd do
          begin
            Bounds := MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, CurrentY, nil);
            Windows.UnionRect(MergedBounds, MergedBounds, Bounds);
            Inc(CurrentY, GetLineHeight);
            WrappedLines.Next;
          end;
        end;
        Lines.Next;
      end;
      ExtraHeight := 2;
    end;
    Result :=
        Classes.Point(
            MergedBounds.Right - MergedBounds.Left,
            ExtraHeight + MergedBounds.Bottom - MergedBounds.Top
        );
  end;
begin
  Lines := nil;
  WrappedLines := nil;
  Image := nil;
  try
    Lines := TStringsEC.Create;
    Lines.SetText(Text);
    UseARGBColors := True;
    SavedColorTags := ColorTagsEnabled;
    ColorTagsEnabled := False;
    CenteredTabs := (AlignX = 1) and (Pos(WideString('<td='), Text) > 0);
    if WordWrap then
      WrappedLines := TStringsEC.Create;
    if (Width = 0) and WordWrap then
      RaiseWideMessage('draw text to texture 1');
    ImageSize := MeasureFontTextureTextSize;
    if Width = 0 then
      Width := ImageSize.X;
    if Height = 0 then
      Height := ImageSize.Y;
    DrawX := 0;
    DrawY := 0;
    if (AlignX = 0) or WordWrap or CenteredTabs then
      DrawX := 2
    else if AlignX = 2 then
      DrawX := Width - ImageSize.X - 2
    else if AlignX = 1 then
      DrawX := Width div 2 - ImageSize.X div 2
    else if AlignX = 3 then
    begin
      DrawX := 2;
      Width := ImageSize.X + 4;
    end;
    if AlignY = 0 then
      DrawY := TopAdjustment + 2
    else if AlignY = 3 then
      DrawY := Height - ImageSize.Y - 2 + TopAdjustment
    else if AlignY = 1 then
      DrawY := Height div 2 - ImageSize.Y div 2 + TopAdjustment
    else if AlignY = 2 then
      DrawY := Height div 2 - ImageSize.Y div 2 + TopAdjustment
    else if AlignY = 4 then
    begin
      DrawY := TopAdjustment + 2;
      Height := ImageSize.Y + 4;
    end;
    Clip := Classes.Rect(0, 0, Width, Height);
    Image := GR_CreateTexture(Width, Height, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
    if Image = nil then
      RaiseWideMessage('draw text to texture 2');
    Image.LockRect(0, Locked, nil, 0);
    ColorTagsEnabled := SavedColorTags;
    if not WordWrap then
    begin
      if AlignY = 2 then
        CurrentY :=
            Height div 2
                - (GetLineHeight * (Lines.GetCount - 1) + GetCenteringHeight) div 2
                + GetCenteringHeight
      else
        CurrentY := AboveBaseline + DrawY - 2;
      Lines.First;
      while not Lines.IsAtEnd do
      begin
        DrawTaggedText32(Locked.Bits, Locked.Pitch, DrawX, CurrentY, Lines.GetCurrentText, Clip);
        Inc(CurrentY, GetLineHeight);
        Lines.Next;
      end;
    end
    else
    begin
      CurrentY := AboveBaseline + DrawY - 2;
      Lines.First;
      while not Lines.IsAtEnd do
      begin
        WrapTaggedTextIntoLines(WrappedLines, Lines.GetCurrentText, Width - 4);
        WrappedLines.First;
        while not WrappedLines.IsAtEnd do
        begin
          if (AlignX = 0) or CenteredTabs then
            DrawTaggedText32(
                Locked.Bits,
                Locked.Pitch,
                DrawX,
                CurrentY,
                WrappedLines.GetCurrentText,
                Clip
            )
          else if AlignX = 2 then
          begin
            Bounds := MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, 0, nil);
            DrawTaggedText32(
                Locked.Bits,
                Locked.Pitch,
                Width - (Bounds.Right - Bounds.Left),
                CurrentY,
                WrappedLines.GetCurrentText,
                Clip
            );
          end
          else if AlignX = 1 then
          begin
            Bounds := MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, 0, nil);
            DrawTaggedText32(
                Locked.Bits,
                Locked.Pitch,
                Width div 2 - (Bounds.Right - Bounds.Left) div 2,
                CurrentY,
                WrappedLines.GetCurrentText,
                Clip
            );
          end
          else if (AlignX = 3) and not WrappedLines.IsAtLast then
            DrawJustifiedTaggedText32(
                Locked.Bits,
                Locked.Pitch,
                DrawX,
                CurrentY,
                WrappedLines.GetCurrentText,
                Width - 4,
                Clip
            )
          else
            DrawTaggedText32(
                Locked.Bits,
                Locked.Pitch,
                DrawX,
                CurrentY,
                WrappedLines.GetCurrentText,
                Clip
            );
          Inc(CurrentY, GetLineHeight);
          WrappedLines.Next;
        end;
        Lines.Next;
      end;
    end;
    Image.UnlockRect(0);
  finally
    if Lines <> nil then
      Lines.Free;
    if WrappedLines <> nil then
      WrappedLines.Free;
  end;
  if ActualSize <> nil then
    ActualSize^ := Classes.Point(Width, Height);
  Texture := Image;
end;

procedure LinkRecoveredTypes;
begin
  TCFontEC.ClassName;
end;
end.
