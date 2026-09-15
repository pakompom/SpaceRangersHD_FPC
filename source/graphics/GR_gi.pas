{$EXCESSPRECISION OFF}
unit GR_gi;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  GR_GraphBuf,
  Types;
type
  TgiGR = class;
  PointerToTgiClipRectDiskGR = ^TgiClipRectDiskGR;
  PointerToTgiHeaderGR = ^TgiHeaderGR;
  PointerToTgiPlaneGR = ^TgiPlaneGR;
  PointerToTGaiHeader = ^TGaiHeader;
  PointerToTGaiSequenceTableHeader = ^TGaiSequenceTableHeader;
  TGaiHeader = packed record
    Gap0: array[0..7] of Byte;
    Bounds: TRect;
    FrameCount: Integer;
    Flags: Cardinal;
    SequenceTableOffset: Integer;
    Gap24: array[0..11] of Byte;
  end;
  PGaiHeader = PointerToTGaiHeader;
  TGaiFrameEntry = packed record
    DataOffset: Integer;
    DataSize: Integer;
  end;
  TGaiSequenceTableHeader = packed record
    SequenceCount: Integer;
    Gap4: array[0..3] of Byte;
  end;
  PGaiSequenceTableHeader = PointerToTGaiSequenceTableHeader;
  TGaiSequenceDirectoryEntry = packed record
    SequenceDataOffset: Integer;
    Gap4: array[0..3] of Byte;
  end;
  TGaiSequenceFrameEntry = packed record
    SourceFrameIndex: Integer;
    FrameDelay: Integer;
  end;
  TGaiSequenceDataBlock = packed record
    FrameCount: Integer;
  end;
  TgiHeaderGR = packed record
    Magic: array[0..3] of AnsiChar;
    Version: Integer;
    Bounds: TRect;
    RedMask: Cardinal;
    GreenMask: Cardinal;
    BlueMask: Cardinal;
    AlphaMask: Cardinal;
    Format: Integer;
    PlaneCount: Integer;
    ClipRectCount: Integer;
    ClipRectTableOffset: Integer;
    Gap38: array[0..7] of Byte;
  end;
  PgiHeaderGR = PointerToTgiHeaderGR;
  TgiPlaneGR = packed record
    DataOffset: Integer;
    DataSize: Integer;
    Bounds: TRect;
    Gap18: array[0..7] of Byte;
  end;
  PgiPlaneGR = PointerToTgiPlaneGR;
  TgiClipRectDiskGR = packed record
    Left: Word;
    Top: Word;
    Bottom: Word;
    Right: Word;
  end;
  PgiClipRectDiskGR = PointerToTgiClipRectDiskGR;
  TgiGR = class(TObjectEx)
    Data: Pointer;
    DataSize: Integer;
    UsesExternalData: Boolean;
    GapD: array[0..2] of Byte;
    Header: PgiHeaderGR;
    constructor Create;
    destructor Destroy; override;
    procedure ClearData;
    function IsEmpty: Boolean;
    procedure LoadRawGiBytes(BufferPtr: Pointer; ByteCount: Integer);
    procedure LoadRawGiFromBuffer(SourceBuffer: TBufEC);
    procedure LoadCompressedGiBytes(BufferPtr: Pointer; ByteCount: Integer);
    function GetBoundsRect: TRect;
    function GetContentSize: TPoint;
    function GetTopLeft: TPoint;
    function GetFormat: Integer;
    function GetPlane(PlaneIndex: Integer): PgiPlaneGR;
    function GetClipRectCount: Integer;
    function GetClipRect(RectIndex: Integer): TRect;
    procedure BuildPalettedFormat4ColorCache;
    procedure DrawToGraphBuf(
        GraphBuf: TGraphBufGR;
        X: Integer;
        Y: Integer;
        DrawRect: TRect;
        BlendMode: Byte;
        Alpha: Byte
    );
    procedure DecodeToGraphBuf(GraphBuf: TGraphBufGR; Keep16BitPixels: Boolean);
    procedure DecodeRawRegion(
        Destination: Pointer;
        PitchBytes: Integer;
        SourceX: Integer;
        SourceY: Integer;
        Width: Integer;
        Height: Integer;
        Keep16BitPixels: Boolean
    );
    procedure DecodeToPixels(
        Destination: Pointer;
        PitchBytes: Integer;
        Width: Integer;
        Height: Integer;
        Keep16BitPixels: Boolean
    );
    procedure CreateFromGraphBuf(GraphBuf: TGraphBufGR; StorageMode: Integer);
    procedure CreateFormat2FromGraphBuf(GraphBuf: TGraphBufGR; TopLeft: TPoint);
  end;
procedure PrepareRawGiColorCache(Data: Pointer);
implementation
uses
  ZLib,
  Math,
  Classes,
  EC_Mem,
  EC_OKGF,
  Windows,
  GR_Main,
  GlobalsV,
  EC_Str;
constructor TgiGR.Create;
begin
  inherited Create;
end;
destructor TgiGR.Destroy;
begin
  ClearData;
  inherited Destroy;
end;
procedure TgiGR.ClearData;
begin
  if (Data <> nil) and not UsesExternalData then
    FreeEC(Data);
  Data := nil;
  DataSize := 0;
  UsesExternalData := False;
  Header := nil;
end;
function TgiGR.IsEmpty: Boolean;
begin
  Result := Header = nil;
end;
procedure TgiGR.LoadRawGiBytes(BufferPtr: Pointer; ByteCount: Integer);
begin
  ClearData;
  Data := BufferPtr;
  DataSize := ByteCount;
  UsesExternalData := True;
  Header := Data;
end;
procedure TgiGR.LoadRawGiFromBuffer(SourceBuffer: TBufEC);
begin
  ClearData;
  DataSize := SourceBuffer.DataSize;
  Data := AllocEC(DataSize);
  CopyMemory(Data, SourceBuffer.Data, DataSize);
  UsesExternalData := False;
  Header := Data;
end;
procedure TgiGR.LoadCompressedGiBytes(BufferPtr: Pointer; ByteCount: Integer);
begin
  ClearData;
  if ByteCount < 8 then
    Exit;
  DataSize := OKGF_ZLib_UnCompress(nil, 0, BufferPtr, ByteCount);
  if DataSize = 0 then
    Exit;
  Data := AllocEC(DataSize);
  DataSize := OKGF_ZLib_UnCompress(Data, DataSize, BufferPtr, ByteCount);
  if DataSize = 0 then
  begin
    FreeEC(Data);
    Data := nil;
  end
  else
  begin
    Header := Data;
    UsesExternalData := False;
  end;
end;
function TgiGR.GetBoundsRect: TRect;
begin
  Result := Header.Bounds;
end;
function TgiGR.GetContentSize: TPoint;
begin
  Result.X := Header.Bounds.Right - Header.Bounds.Left;
  Result.Y := Header.Bounds.Bottom - Header.Bounds.Top;
end;
function TgiGR.GetTopLeft: TPoint;
begin
  Result.X := Header.Bounds.Left;
  Result.Y := Header.Bounds.Top;
end;
function TgiGR.GetFormat: Integer;
begin
  Result := Header.Format;
end;
function TgiGR.GetPlane(PlaneIndex: Integer): PgiPlaneGR;
begin
  Result := Pointer(PlaneIndex * SizeOf(TgiPlaneGR) + SizeOf(TgiHeaderGR) + PtrUInt(Data));
end;
function TgiGR.GetClipRectCount: Integer;
begin
  Result := Header.ClipRectCount;
end;
function TgiGR.GetClipRect(RectIndex: Integer): TRect;
var
  Rect: PgiClipRectDiskGR;
begin
  Rect :=
      Pointer(
          PtrUInt(Data) + Header.ClipRectTableOffset + 1 + RectIndex * SizeOf(TgiClipRectDiskGR)
      );
  Result.Left := Rect.Left;
  Result.Top := Rect.Top;
  Result.Right := Rect.Right;
  Result.Bottom := Rect.Bottom;
end;
procedure TgiGR.BuildPalettedFormat4ColorCache;
var
  Plane: PgiPlaneGR;
  Source, Dest: Pointer;
  Index, Count: Integer;
  Color: Cardinal;
begin
  if HardwareRenderingEnabled or (Header = nil) or (Header.Format <> 4) then
    Exit;
  Plane := GetPlane(1);
  Source := AddPointerOffset(Data, Plane.DataOffset);
  Dest := Source;
  Count := Plane.DataSize div SizeOf(TColorRGBA);
  for Index := 0 to Count - 1 do
  begin
    Color := ReadDWordEC(Source);
    Color :=
        CurrentPixelFormat
            .PackRgbBytes(Color and $FF, (Color shr 8) and $FF, (Color shr 16) and $FF);
    WriteWordEC(Dest, Color);
    Source := AddPointerOffset(Source, SizeOf(TColorRGBA));
    Dest := AddPointerOffset(Dest, SizeOf(Word));
  end;
end;
procedure TgiGR.DrawToGraphBuf(
    GraphBuf: TGraphBufGR;
    X, Y: Integer;
    DrawRect: TRect;
    BlendMode, Alpha: Byte
);
var
  Plane, PalettePlane: PgiPlaneGR;
  InclusiveClip: TRect;
begin
  case Header.Format of
    0:
    begin
      Plane := Pointer(PtrUInt(Data) + SizeOf(TgiHeaderGR));
      if Plane.DataOffset <> 0 then
      begin
        if (Header.RedMask = $FF0000)
            and (Header.GreenMask = $FF00)
            and (Header.BlueMask = $FF)
            and (Header.AlphaMask = $FF000000) then
          DrawAlphaBuffer16Clipped(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(Word),
              Header.Bounds.Right - Header.Bounds.Left,
              Header.Bounds.Bottom - Header.Bounds.Top,
              DrawRect
          )
        else
          CopyBuffer16Clipped(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(Word),
              Header.Bounds.Right - Header.Bounds.Left,
              Header.Bounds.Bottom - Header.Bounds.Top,
              DrawRect,
              Boolean(BlendMode)
          );
      end;
    end;
    1:
    begin
      Plane := Pointer(PtrUInt(Data) + SizeOf(TgiHeaderGR));
      if Plane.DataOffset <> 0 then
        DrawTransparentBuffer16(
            GraphBuf.GetPixels,
            GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left,
            Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PtrUInt(Data) + Plane.DataOffset),
            DrawRect,
            False
        );
    end;
    2:
    begin
      InclusiveClip.Left := DrawRect.Left;
      InclusiveClip.Top := DrawRect.Top;
      InclusiveClip.Right := DrawRect.Right - 1;
      InclusiveClip.Bottom := DrawRect.Bottom - 1;
      Plane := Pointer(PtrUInt(Data) + 128);
      if Plane.DataOffset <> 0 then
        Ex_OKGR_AlphaBuf_DrawClip_16(
            GraphBuf.GetPixels,
            GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left,
            Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PtrUInt(Data) + Plane.DataOffset),
            InclusiveClip
        );
      Plane := Pointer(PtrUInt(Data) + 96);
      if Plane.DataOffset <> 0 then
        Ex_OKGR_TransAlphaBuf_DrawClip_WORD(
            GraphBuf.GetPixels,
            GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left,
            Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PtrUInt(Data) + Plane.DataOffset),
            InclusiveClip
        );
      Plane := Pointer(PtrUInt(Data) + 64);
      if Plane.DataOffset <> 0 then
        Ex_OKGR_TransBuf_DrawClip_WORD(
            GraphBuf.GetPixels,
            GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left,
            Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PtrUInt(Data) + Plane.DataOffset),
            InclusiveClip
        );
    end;
    3:
    begin
      InclusiveClip.Left := DrawRect.Left;
      InclusiveClip.Top := DrawRect.Top;
      InclusiveClip.Right := DrawRect.Right - 1;
      InclusiveClip.Bottom := DrawRect.Bottom - 1;
      if Alpha = 255 then
      begin
        Plane := Pointer(PtrUInt(Data) + 64);
        if Plane.DataOffset <> 0 then
          Ex_OKGR_AlphaIndexed_CopyDrawClip_WORD(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              InclusiveClip
          );
        Plane := Pointer(PtrUInt(Data) + 96);
        if Plane.DataOffset <> 0 then
          Ex_OKGR_AlphaIndexed_AlphaDrawClip_16(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              InclusiveClip
          );
      end
      else if Alpha >= 4 then
      begin
        Plane := Pointer(PtrUInt(Data) + 64);
        if Plane.DataOffset <> 0 then
          Ex_OKGR_AlphaIndexed_CopyDrawClip_Alpha_16(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              InclusiveClip,
              Alpha
          );
        Plane := Pointer(PtrUInt(Data) + 96);
        if Plane.DataOffset <> 0 then
          Ex_OKGR_AlphaIndexed_AlphaDrawClip_Alpha_16(
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left,
              Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PtrUInt(Data) + Plane.DataOffset),
              InclusiveClip,
              Alpha
          );
      end;
    end;
    4:
    begin
      Plane := Pointer(PtrUInt(Data) + SizeOf(TgiHeaderGR));
      PalettePlane := Pointer(PtrUInt(Data) + (SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR)));
      CopyPalettedBuffer16Clipped(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          X + Plane.Bounds.Left - Header.Bounds.Left,
          Y + Plane.Bounds.Top - Header.Bounds.Top,
          Pointer(PtrUInt(Data) + Plane.DataOffset),
          Pointer(PalettePlane.DataOffset + PtrUInt(Data)),
          Header.Bounds.Right - Header.Bounds.Left,
          Header.Bounds.Right - Header.Bounds.Left,
          Header.Bounds.Bottom - Header.Bounds.Top,
          DrawRect
      );
    end;
    5:
    begin
      Plane := Pointer(PtrUInt(Data) + SizeOf(TgiHeaderGR));
      Ex_OKGR_F5_DrawRGBA(
          Pointer(PtrUInt(GraphBuf.GetPixels) + (X * SizeOf(TColorRGBA) + GraphBuf.PitchBytes * Y)),
          GraphBuf.PitchBytes,
          Pointer(PtrUInt(Data) + Plane.DataOffset)
      );
    end;
    6:
    begin
      Plane := Pointer(PtrUInt(Data) + SizeOf(TgiHeaderGR));
      Ex_OKGR_F6_DrawRGBA(
          Pointer(PtrUInt(GraphBuf.GetPixels) + (X * SizeOf(TColorRGBA) + GraphBuf.PitchBytes * Y)),
          GraphBuf.PitchBytes,
          Pointer(PtrUInt(Data) + Plane.DataOffset)
      );
    end;
  end;
end;
procedure TgiGR.DecodeToGraphBuf(GraphBuf: TGraphBufGR; Keep16BitPixels: Boolean);
var
  Plane, PalettePlane: PgiPlaneGR;
  Y: Cardinal;
begin
  if Header.Format = 0 then
  begin
    GraphBuf.AllocateRgba(
        Header.Bounds.Right - Header.Bounds.Left,
        Header.Bounds.Bottom - Header.Bounds.Top,
        (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA)
    );
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
    begin
      if Header.AlphaMask = 0 then
      begin
        if Keep16BitPixels then
          for Y := 0 to Cardinal(GraphBuf.Height) - 1 do
            CopyMemory(
                AddPointerOffset(GraphBuf.GetPixels, GraphBuf.PitchBytes * Y),
                AddPointerOffset(Data, Plane.DataOffset + Y * GraphBuf.Width * SizeOf(Word)),
                GraphBuf.Width * SizeOf(Word)
            )
        else
          Ex_OKGF_Convert565toBGRA(
              AddPointerOffset(Data, Plane.DataOffset),
              GraphBuf.Width * SizeOf(Word),
              GraphBuf.GetPixels,
              GraphBuf.PitchBytes,
              GraphBuf.Width,
              GraphBuf.Height
          );
      end
      else
        CopyMemory(
            GraphBuf.GetPixels,
            AddPointerOffset(Data, Plane.DataOffset),
            GraphBuf.Width * SizeOf(TColorRGBA) * GraphBuf.Height
        );
    end;
  end
  else if Header.Format = 1 then
  begin
    GraphBuf.AllocateRgba(
        Header.Bounds.Right - Header.Bounds.Left,
        Header.Bounds.Bottom - Header.Bounds.Top,
        (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA)
    );
    GraphBuf.ClearPixels;
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransBuf_Draw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 2 then
  begin
    GraphBuf.AllocateRgba(
        Header.Bounds.Right - Header.Bounds.Left,
        Header.Bounds.Bottom - Header.Bounds.Top,
        (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA)
    );
    GraphBuf.ClearPixels;
    Plane := GetPlane(2);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaBuf_Draw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransAlphaBuf_Draw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransBuf_Draw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 3 then
  begin
    GraphBuf.AllocateRgba(
        Header.Bounds.Right - Header.Bounds.Left,
        Header.Bounds.Bottom - Header.Bounds.Top,
        (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA)
    );
    GraphBuf.ClearPixels;
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaIndexed_Draw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaIndexed_AlphaDraw_RGBA(
          AddPointerOffset(
              GraphBuf.GetPixels,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * SizeOf(TColorRGBA)
          ),
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 4 then
  begin
    GraphBuf.AllocateRgba(
        Header.Bounds.Right - Header.Bounds.Left,
        Header.Bounds.Bottom - Header.Bounds.Top,
        (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA)
    );
    GraphBuf.ClearPixels;
    Plane := GetPlane(0);
    PalettePlane := GetPlane(1);
    ExpandPaletteToBgra(
        GraphBuf.GetPixels,
        GraphBuf.PitchBytes,
        GraphBuf.Width,
        GraphBuf.Height,
        AddPointerOffset(Data, Plane.DataOffset),
        GraphBuf.Width,
        AddPointerOffset(Data, PalettePlane.DataOffset)
    );
  end
  else if Header.Format = 5 then
  begin
    if (GraphBuf <> nil)
        and (Header.Bounds.Right - Header.Bounds.Left <= GraphBuf.Width)
        and (Header.Bounds.Bottom - Header.Bounds.Top <= GraphBuf.Height) then
    begin
      Plane := GetPlane(0);
      Ex_OKGR_F5_DrawRGBA(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    end;
  end
  else if Header.Format = 6 then
  begin
    if (GraphBuf <> nil)
        and (Header.Bounds.Right - Header.Bounds.Left <= GraphBuf.Width)
        and (Header.Bounds.Bottom - Header.Bounds.Top <= GraphBuf.Height) then
    begin
      Plane := GetPlane(0);
      Ex_OKGR_F6_DrawRGBA(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    end;
  end;
end;
procedure TgiGR.DecodeRawRegion(
    Destination: Pointer;
    PitchBytes, SourceX, SourceY, Width, Height: Integer;
    Keep16BitPixels: Boolean
);
var
  Plane: PgiPlaneGR;
  Y, SourcePitch: Integer;
begin
  if Header.Format = 0 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
    begin
      if Header.AlphaMask = 0 then
      begin
        SourcePitch := (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(Word);
        if Keep16BitPixels then
          for Y := 0 to Height - 1 do
            CopyMemory(
                AddPointerOffset(Destination, PitchBytes * Y),
                AddPointerOffset(
                    Data,
                    (SourceY + Y) * SourcePitch + SourceX * SizeOf(Word) + Plane.DataOffset
                ),
                Width * SizeOf(Word)
            )
        else
          Ex_OKGF_Convert565toBGRA(
              AddPointerOffset(
                  Data,
                  SourceY * SourcePitch + SourceX * SizeOf(Word) + Plane.DataOffset
              ),
              SourcePitch,
              Destination,
              PitchBytes,
              Width,
              Height
          );
      end
      else
      begin
        SourcePitch := (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(TColorRGBA);
        for Y := 0 to Height - 1 do
          CopyMemory(
              AddPointerOffset(Destination, PitchBytes * Y),
              AddPointerOffset(
                  Data,
                  (Y + SourceY) * SourcePitch + SourceX * SizeOf(TColorRGBA) + Plane.DataOffset
              ),
              Width * SizeOf(TColorRGBA)
          );
      end;
    end;
  end
  else
    AppendLogLineThreadSafe(
        'Error in TgiGR.DrawRGBA()::FZag.format=' + IntToWideString(Header.Format)
    );
end;
procedure TgiGR.DecodeToPixels(
    Destination: Pointer;
    PitchBytes, Width, Height: Integer;
    Keep16BitPixels: Boolean
);
var
  Plane, PalettePlane: PgiPlaneGR;
  Y: Integer;
begin
  if Header.Format = 0 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
    begin
      if Header.AlphaMask = 0 then
      begin
        if Keep16BitPixels then
          for Y := 0 to Height - 1 do
            CopyMemory(
                AddPointerOffset(Destination, PitchBytes * Y),
                AddPointerOffset(Data, Y * Width * SizeOf(Word) + Plane.DataOffset),
                Width * SizeOf(Word)
            )
        else
          Ex_OKGF_Convert565toBGRA(
              AddPointerOffset(Data, Plane.DataOffset),
              Width * SizeOf(Word),
              Destination,
              PitchBytes,
              Width,
              Height
          );
      end
      else
        CopyMemory(Destination, AddPointerOffset(Data, Plane.DataOffset), PitchBytes * Height);
    end;
  end
  else if Header.Format = 1 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransBuf_Draw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 2 then
  begin
    Plane := GetPlane(2);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaBuf_Draw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransAlphaBuf_Draw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_TransBuf_Draw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 3 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaIndexed_Draw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      Ex_OKGR_AlphaIndexed_AlphaDraw_RGBA(
          AddPointerOffset(
              Destination,
              (Plane.Bounds.Left - Header.Bounds.Left) * SizeOf(TColorRGBA)
                  + (Plane.Bounds.Top - Header.Bounds.Top) * PitchBytes
          ),
          PitchBytes,
          AddPointerOffset(Data, Plane.DataOffset)
      );
  end
  else if Header.Format = 4 then
  begin
    Plane := GetPlane(0);
    PalettePlane := GetPlane(1);
    ExpandPaletteToBgra(
        Destination,
        PitchBytes,
        Width,
        Height,
        AddPointerOffset(Data, Plane.DataOffset),
        Width,
        AddPointerOffset(Data, PalettePlane.DataOffset)
    );
  end
  else if Header.Format = 5 then
  begin
    Plane := GetPlane(0);
    Ex_OKGR_F5_DrawRGBA(Destination, PitchBytes, AddPointerOffset(Data, Plane.DataOffset));
  end
  else if Header.Format = 6 then
  begin
    Plane := GetPlane(0);
    Ex_OKGR_F6_DrawRGBA(Destination, PitchBytes, AddPointerOffset(Data, Plane.DataOffset));
  end;
end;
procedure TgiGR.CreateFromGraphBuf(GraphBuf: TGraphBufGR; StorageMode: Integer);
var
  Plane: PgiPlaneGR;
  ByteCount: Cardinal;
  procedure SwapGiSourceRedBlue; // @addr $4782CC @ida "void __usercall $name(void *ParentFrame@<^0>);" @stackpop 0 @calls "0x00478486 0x004784FC"
  var
    Pixels: Pointer;
    Count, I: Integer;
    B: Byte;
    P: PByte;
  begin
    Pixels := GraphBuf.GetPixels;
    Count := GraphBuf.Width * GraphBuf.Height;
    P := Pixels;
    for I := 0 to Count - 1 do
    begin
      B := P[0];
      P[0] := P[2];
      P[2] := B;
      Inc(P, 4)
    end;
  end;
begin
  ClearData;
  ByteCount := GraphBuf.Width * GraphBuf.Height;
  if StorageMode = 2 then
    ByteCount := ByteCount * SizeOf(TColorRGBA)
  else
    ByteCount := ByteCount * SizeOf(Word);
  DataSize := ByteCount + (SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR));
  Data := AllocEC(DataSize);
  Header := Data;
  FillChar(Header^, SizeOf(TgiHeaderGR), 0);
  Header.Magic[0] := 'g';
  Header.Magic[1] := 'i';
  Header.Version := 1;
  Header.Bounds := Classes.Rect(0, 0, GraphBuf.Width, GraphBuf.Height);
  Header.PlaneCount := 1;
  Plane := GetPlane(0);
  Plane.DataOffset := SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR);
  Plane.DataSize := ByteCount;
  Plane.Bounds := Header.Bounds;
  case StorageMode of
    0:
    begin
      Header.RedMask := $FF0000;
      Header.GreenMask := $FF00;
      Header.BlueMask := $FF;
      Header.AlphaMask := $FF000000;
      CopyMemory(AddPointerOffset(Data, Plane.DataOffset), GraphBuf.GetPixels, ByteCount);
    end;
    1:
    begin
      SwapGiSourceRedBlue;
      Header.RedMask := $F800;
      Header.GreenMask := $7E0;
      Header.BlueMask := $1F;
      Ex_OKGF_Convert_8888to565(
          AddPointerOffset(Data, Plane.DataOffset),
          GraphBuf.Width * SizeOf(Word),
          0,
          0,
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          0,
          0,
          GraphBuf.Width,
          GraphBuf.Height
      );
      SwapGiSourceRedBlue;
    end;
  end;
end;
procedure TgiGR.CreateFormat2FromGraphBuf(GraphBuf: TGraphBufGR; TopLeft: TPoint);
var
  Plane: PgiPlaneGR;
  ByteCount, Offset: Integer;
begin
  ClearData;
  ByteCount :=
      Ex_OKGR_TransBuf_BuildFromRGBA_16(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          nil
      );
  Inc(
      ByteCount,
      Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          nil
      )
  );
  Inc(
      ByteCount,
      Ex_OKGR_AlphaBuf_BuildFromRGBA(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          nil
      )
  );
  Offset := SizeOf(TgiHeaderGR) + 3 * SizeOf(TgiPlaneGR);
  DataSize := Offset + ByteCount;
  Data := AllocEC(DataSize);
  Header := Data;
  FillChar(Header^, SizeOf(TgiHeaderGR), 0);
  Header.Magic[0] := 'g';
  Header.Magic[1] := 'i';
  Header.Version := 1;
  Header.Bounds :=
      Classes.Rect(TopLeft.X, TopLeft.Y, TopLeft.X + GraphBuf.Width, TopLeft.Y + GraphBuf.Height);
  Header.Format := 2;
  Header.PlaneCount := 3;
  Header.RedMask := $F800;
  Header.GreenMask := $7E0;
  Header.BlueMask := $1F;
  Plane := GetPlane(0);
  Plane.DataOffset := Offset;
  Plane.DataSize :=
      Ex_OKGR_TransBuf_BuildFromRGBA_16(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          AddPointerOffset(Data, Offset)
      );
  Plane.Bounds := Header.Bounds;
  Inc(Offset, Plane.DataSize);
  Plane := GetPlane(1);
  Plane.DataOffset := Offset;
  Plane.DataSize :=
      Ex_OKGR_TransAlphaBuf_BuildFromRGBA_16(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          AddPointerOffset(Data, Offset)
      );
  Plane.Bounds := Header.Bounds;
  Inc(Offset, Plane.DataSize);
  Plane := GetPlane(2);
  Plane.DataOffset := Offset;
  Plane.DataSize :=
      Ex_OKGR_AlphaBuf_BuildFromRGBA(
          GraphBuf.GetPixels,
          GraphBuf.PitchBytes,
          GraphBuf.Width,
          GraphBuf.Height,
          AddPointerOffset(Data, Offset)
      );
  Plane.Bounds := Header.Bounds;
end;
procedure PrepareRawGiColorCache(Data: Pointer);
var
  Image: TgiGR;
begin
  Image := TgiGR.Create;
  Image.LoadRawGiBytes(Data, 1);
  Image.BuildPalettedFormat4ColorCache;
  Image.Free;
end;
end.
