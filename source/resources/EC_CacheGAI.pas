unit EC_CacheGAI;

{$I GameOptions.inc}

interface

uses
  Classes,
  EC_Buf,
  EC_Cache,
  GR_DX,
  GR_gi,
  Types,
  Direct3D9;

type

  TCGaiControlEC = class;

  TCGaiEC = class;

  TCGaiControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;

  TCGaiEC = class(TCacheDataEC)
    RawGaiData: Pointer;
    Header: PGaiHeader;
    DecodedFrameGi: TgiGR;
    SequenceTableData: PGaiSequenceTableHeader;
    SkipPalettedColorCacheBuild: Boolean;
    FrameSurfaceCache: TTextureGR;
    CachedFrameOrigins: array of TPoint;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
    function GetFrameCount: Integer;
    function HasPlaybackFlags: Boolean;
    function GetBoundsRect: TRect;
    function GetCanvasSize: TPoint;
    function GetOrCreateFrameSurface(FrameIndex: Integer): IDirect3DTexture9;
    function GetFrameOrigin(FrameIndex: Integer): TPoint;
    function LoadFrameGi(FrameIndex: Integer): TgiGR;
    function IsFrameCompressed(FrameIndex: Integer): Boolean;
    function GetSequenceCount: Integer;
    function GetSequenceFrameCount(SequenceIndex: Integer): Integer;
    procedure FillSequenceFrameIndexTable(
        SequenceIndex: Integer;
        DestTable: Pointer;
        EntryStride: Integer
    );
    procedure FillSequenceFrameDelayTable(
        SequenceIndex: Integer;
        DestTable: Pointer;
        EntryStride: Integer
    );
    function GetSequenceFrameIndex(SequenceIndex: Integer; FrameInSequence: Integer): Integer;
    function GetSequenceFrameDelay(SequenceIndex: Integer; FrameInSequence: Integer): Integer;
    procedure ApplyAB2BackgroundFixup(SourceBuffer: TBufEC; const ResourceKey: WideString);
  end;

function AcquireCachedGai(Control: TCacheControlEC): TCGaiEC;

implementation

uses
  EC_Mem,
  EC_Str,
  EC_Struct,
  GR_Main,
  GR_GraphBuf;

// Native directory indexing adds the two header dwords separately.
function ReadGaiSequenceOffset(
    const Table: PGaiSequenceTableHeader;
    const Index: Integer
): Cardinal; inline;
begin
  Result :=
      ReadDWordEC(AddPointerOffset(Table, Index * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4));
end;

procedure TCGaiControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCGaiControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCGaiEC) = nil then
  begin
    Control := TCGaiControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCGaiControlEC.CreateData: TCacheDataEC;
begin
  Result := TCGaiEC.Create;
end;

function AcquireCachedGai(Control: TCacheControlEC): TCGaiEC;
begin
  Result := Control.AcquireDataFromConfig(TCGaiEC) as TCGaiEC;
end;

function TCGaiControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedGai(Self);
end;

constructor TCGaiEC.Create;
begin
  inherited Create;
  DecodedFrameGi := TgiGR.Create;
  FrameSurfaceCache := nil;
end;

destructor TCGaiEC.Destroy;
begin
  if RawGaiData <> nil then
  begin
    FreeEC(RawGaiData);
    RawGaiData := nil;
  end;
  DecodedFrameGi.Free;
  if FrameSurfaceCache <> nil then
  begin
    FreeTextureCache(FrameSurfaceCache);
    FrameSurfaceCache := nil;
    SetLength(CachedFrameOrigins, 0);
  end;
  inherited Destroy;
end;

function TCGaiEC.GetFrameCount: Integer;
begin
  Result := Header.FrameCount;
end;

function TCGaiEC.HasPlaybackFlags: Boolean;
begin
  Result := Header.Flags <> 0;
end;

function TCGaiEC.GetBoundsRect: TRect;
begin
  Result := Header.Bounds;
end;

function TCGaiEC.GetCanvasSize: TPoint;
begin
  Result := SubtractPoints(Header.Bounds.BottomRight, Header.Bounds.TopLeft);
end;

function TCGaiEC.GetOrCreateFrameSurface(FrameIndex: Integer): IDirect3DTexture9;
var
  Texture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
  FrameSize, Origin: TPoint;
  Frame: TgiGR;
begin
  if FrameSurfaceCache = nil then
    FrameSurfaceCache := CreateTextureCache;
  Texture := FrameSurfaceCache.GetSurface(FrameIndex);
  if Texture = nil then
  begin
    Frame := LoadFrameGi(FrameIndex);
    if Frame <> nil then
    begin
      FrameSize := Frame.GetContentSize;
      if (FrameSize.X = 0) or (FrameSize.Y = 0) then
      begin
        Result := nil;
        Exit;
      end;
      if (Frame.Header.Format = 0) and (Frame.Header.AlphaMask = 0) then
        Texture := GR_CreateTexture(FrameSize.X, FrameSize.Y, D3DFMT_R5G6B5, D3DPOOL_MANAGED)
      else
        Texture := GR_CreateTexture(FrameSize.X, FrameSize.Y, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED);
      if Texture <> nil then
      begin
        Texture.LockRect(0, Locked, nil, 0);
        if Locked.Bits <> nil then
        begin
          Frame.DecodeToPixels(Locked.Bits, Locked.Pitch, FrameSize.X, FrameSize.Y, True);
          Texture.UnlockRect(0);
        end;
      end;
      Origin := Frame.GetTopLeft;
      CachedFrameOrigins[FrameIndex].X := Origin.X - Header.Bounds.Left;
      CachedFrameOrigins[FrameIndex].Y := Origin.Y - Header.Bounds.Top;
      FrameSurfaceCache.SetSurface(Texture, FrameIndex);
    end;
  end;
  Result := Texture;
end;

function TCGaiEC.GetFrameOrigin(FrameIndex: Integer): TPoint;
begin
  Result := CachedFrameOrigins[FrameIndex];
end;

function TCGaiEC.LoadFrameGi(FrameIndex: Integer): TgiGR;
var
  Offset: Integer;
begin
  Result := nil;
  if (FrameIndex < 0) or (Header.FrameCount <= FrameIndex) then
    Exit;
  Offset :=
      ReadDWordEC(
          AddPointerOffset(RawGaiData, FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader))
      );
  if Offset = 0 then
  begin
    Result := nil;
    Exit;
  end;
  if ReadWordEC(AddPointerOffset(RawGaiData, Offset)) = $4C5A then
  begin
    DecodedFrameGi.LoadCompressedGiBytes(
        AddPointerOffset(RawGaiData, Offset),
        ReadDWordEC(
            AddPointerOffset(
                RawGaiData,
                Integer(
                    @PGaiFrameEntry(FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader))
                        .DataSize
                )
            )
        )
    );
    if not SkipPalettedColorCacheBuild then
      DecodedFrameGi.BuildPalettedFormat4ColorCache;
  end
  else
    DecodedFrameGi.LoadRawGiBytes(
        AddPointerOffset(RawGaiData, Offset),
        ReadDWordEC(
            AddPointerOffset(
                RawGaiData,
                Integer(
                    @PGaiFrameEntry(FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader))
                        .DataSize
                )
            )
        )
    );
  if not DecodedFrameGi.IsEmpty then
    Result := DecodedFrameGi;
end;

function TCGaiEC.IsFrameCompressed(FrameIndex: Integer): Boolean;
var
  Offset: Integer;
begin
  Offset :=
      ReadDWordEC(
          AddPointerOffset(RawGaiData, FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader))
      );
  if Offset = 0 then
    Result := False
  else
    Result := ReadWordEC(AddPointerOffset(RawGaiData, Offset)) = $4C5A;
end;

function TCGaiEC.GetSequenceCount: Integer;
begin
  if SequenceTableData = nil then
    Result := 0
  else
    Result := ReadDWordEC(@SequenceTableData.SequenceCount);
end;

function TCGaiEC.GetSequenceFrameCount(SequenceIndex: Integer): Integer;
begin
  Result :=
      ReadDWordEC(
          AddPointerOffset(
              SequenceTableData,
              ReadGaiSequenceOffset(SequenceTableData, SequenceIndex)
          )
      );
end;

procedure TCGaiEC.FillSequenceFrameIndexTable(
    SequenceIndex: Integer;
    DestTable: Pointer;
    EntryStride: Integer
);
var
  Source: Pointer;
  Index, Count: Integer;
begin
  Source :=
      AddPointerOffset(SequenceTableData, ReadGaiSequenceOffset(SequenceTableData, SequenceIndex));
  Count := ReadDWordEC(Source);
  Source := AddPointerOffset(Source, SizeOf(TGaiSequenceDataBlock));
  for Index := 0 to Count - 1 do
  begin
    WriteIntegerEC(DestTable, ReadDWordEC(Source));
    DestTable := AddPointerOffset(DestTable, EntryStride);
    Source := AddPointerOffset(Source, SizeOf(TGaiSequenceFrameEntry));
  end;
end;

procedure TCGaiEC.FillSequenceFrameDelayTable(
    SequenceIndex: Integer;
    DestTable: Pointer;
    EntryStride: Integer
);
var
  Source: Pointer;
  Index, Count: Integer;
begin
  Source :=
      AddPointerOffset(SequenceTableData, ReadGaiSequenceOffset(SequenceTableData, SequenceIndex));
  Count := ReadDWordEC(Source);
  Source := AddPointerOffset(Source, SizeOf(TGaiSequenceDataBlock) + SizeOf(Integer));
  for Index := 0 to Count - 1 do
  begin
    WriteIntegerEC(DestTable, ReadDWordEC(Source));
    DestTable := AddPointerOffset(DestTable, EntryStride);
    Source := AddPointerOffset(Source, SizeOf(TGaiSequenceFrameEntry));
  end;
end;

function TCGaiEC.GetSequenceFrameIndex(SequenceIndex, FrameInSequence: Integer): Integer;
begin
  Result :=
      ReadDWordEC(
          AddPointerOffset(
              SequenceTableData,
              ReadGaiSequenceOffset(SequenceTableData, SequenceIndex)
                  + Integer(
                      @PGaiSequenceFrameEntry(
                              FrameInSequence * SizeOf(TGaiSequenceFrameEntry)
                                  + SizeOf(TGaiSequenceDataBlock))
                          .SourceFrameIndex)
          )
      );
end;

function TCGaiEC.GetSequenceFrameDelay(SequenceIndex, FrameInSequence: Integer): Integer;
begin
  Result :=
      ReadDWordEC(
          AddPointerOffset(
              SequenceTableData,
              ReadGaiSequenceOffset(SequenceTableData, SequenceIndex)
                  + Integer(
                      @PGaiSequenceFrameEntry(
                              FrameInSequence * SizeOf(TGaiSequenceFrameEntry)
                                  + SizeOf(TGaiSequenceDataBlock))
                          .FrameDelay)
          )
      );
end;

procedure TCGaiEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  FrameIndex: Integer;
  Frame: TgiGR;
begin
  if LoadOption = 'NoConvertPF' then
    SkipPalettedColorCacheBuild := True;
  ApplyAB2BackgroundFixup(SourceBuffer, CacheKey);
  try
    RawGaiData := AllocEC(SourceBuffer.DataSize);
    System.Move(Pointer(SourceBuffer.Data)^, Pointer(RawGaiData)^, SourceBuffer.DataSize);
    ResidentBytes := SourceBuffer.DataSize;
  except
    RawGaiData := nil;
    ResidentBytes := 0;
  end;
  Header := RawGaiData;
  if (SourceBuffer.DataSize < SizeOf(TGaiHeader)) or (RawGaiData = nil) then
  begin
    AppendLogLineThreadSafe('Error Load Gai');
    Header := AllocClearEC(SizeOf(TGaiHeader));
  end;
  if Header.SequenceTableOffset <> 0 then
    SequenceTableData := AddPointerOffset(RawGaiData, Header.SequenceTableOffset);
  for FrameIndex := 0 to Header.FrameCount - 1 do
    if not IsFrameCompressed(FrameIndex) then
    begin
      Frame := LoadFrameGi(FrameIndex);
      if (Frame <> nil) and not SkipPalettedColorCacheBuild then
        Frame.BuildPalettedFormat4ColorCache;
    end;
  SetLength(CachedFrameOrigins, Header.FrameCount);
end;

procedure TCGaiEC.ApplyAB2BackgroundFixup(SourceBuffer: TBufEC; const ResourceKey: WideString);
var
  Image: TgiGR;
  GraphBuf: TGraphBufGR;
  ByteCount, Offset: Integer;
  OldHeader: TGaiHeader;
  LayoutSize: TPoint;

  procedure LogGaiRescaleStart;
  begin
    AppendLogTextThreadSafe('Rescaling ' + ResourceKey + '... ');
  end;

  procedure LogGaiRescaleDone;
  begin
    AppendLogLineThreadSafe('ok');
  end;

begin
  if FindTextOffsetW(ResourceKey, 'Bm.FormAB2.2bg') = 0 then
  begin
    LogGaiRescaleStart;
    System.Move(Pointer(SourceBuffer.Data)^, Pointer(@OldHeader)^, SizeOf(TGaiHeader));
    if OldHeader.FrameCount <> 1 then
      Exit;
    Offset := ReadDWordEC(AddPointerOffset(SourceBuffer.Data, SizeOf(TGaiHeader)));
    ByteCount := ReadDWordEC(AddPointerOffset(SourceBuffer.Data, SizeOf(TGaiHeader) + 4));
    if (Offset = 0) or (ByteCount = 0) then
      Exit;
    Image := TgiGR.Create;
    if ReadWordEC(AddPointerOffset(SourceBuffer.Data, Offset)) = $4C5A then
      Image.LoadCompressedGiBytes(AddPointerOffset(SourceBuffer.Data, Offset), ByteCount)
    else
      Image.LoadRawGiBytes(AddPointerOffset(SourceBuffer.Data, Offset), ByteCount);
    if Image.IsEmpty then
      Exit;
    GraphBuf := TGraphBufGR.Create(False);
    GraphBuf.AllocateRgbaTight(Image.GetContentSize.X, Image.GetContentSize.Y);
    Image.DecodeToGraphBuf(GraphBuf, False);
    Image.ClearData;
    LayoutSize := GetNormalGameLayoutSize;
    GraphBuf.RescaleRgbaLinear(LayoutSize.X, LayoutSize.Y, True, 1, 1);
    Image.CreateFromGraphBuf(GraphBuf, 1);
    GraphBuf.Clear;
    OldHeader.Bounds.Right := LayoutSize.X;
    OldHeader.Bounds.Bottom := LayoutSize.Y;
    SourceBuffer.Clear;
    SourceBuffer.AddBytes(@OldHeader, SizeOf(TGaiHeader));
    SourceBuffer.AddDWord(SizeOf(TGaiHeader) + SizeOf(TGaiFrameEntry));
    SourceBuffer.AddDWord(Image.DataSize);
    SourceBuffer.AddBytes(Image.Data, Image.DataSize);
    Image.ClearData;
    Image.Free;
    LogGaiRescaleDone;
  end;
end;

end.
