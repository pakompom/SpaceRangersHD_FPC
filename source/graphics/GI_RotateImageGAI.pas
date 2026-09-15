{$EXCESSPRECISION OFF}
unit GI_RotateImageGAI;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_CacheGAI,
  EC_CacheRotateBuf,
  GI_MessageLoop,
  GR_GraphBufPal,
  Types,
  Direct3D9,
  GR_DX;
type
  TRotateImageGaiGI = class;
  TRotateImageGaiGI = class(TObjectGI)
    ImageCache: TCGaiControlEC;
    RotationCache: TCRotateBufControlEC;
    RotatedImage: TGraphBufPalGR;
    RenderedAngle: Byte;
    Angle: Byte;
    Alpha: Byte;
    ImageDirty: Boolean;
    RenderedFrameIndex: Integer;
    FrameIndex: Integer;
    FrameCount: Integer;
    FrameIndexTable: PInteger;
    FrameDelayTable: PInteger;
    AnimationIndex: Integer;
    ImageSize: TPoint;
    Vertices: array[0..3] of TScreenVertexGR;
    FrameTexture: IDirect3DTexture9;
    procedure Clear; override;
    procedure QueueImageLoad(PendingLoads: TList); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetAngle(Value: Byte);
    procedure SetAlpha(Value: Byte);
    procedure SetImage(Path: WideString; ImageSize: TPoint; Pivot: TPoint);
    procedure SetFrame(Value: Integer);
    procedure ClearFrameSequence;
    function GetFrameSourceIndex(Index: Integer): Integer;
    procedure LoadImageProperties(Block: TBlockParEC);
  end;
implementation
uses
  GlobalsV,
  SysUtils,
  Math,
  EC_Cache,
  EC_Mem,
  GI_GAI,
  GI_Main,
  GR_Main,
  GR_GraphBuf,
  GR_gi;

constructor TRotateImageGaiGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
  RotatedImage := TGraphBufPalGR.Create;
  RenderedAngle := 0;
  Angle := 0;
  Alpha := 255;
  ImageDirty := True;
  AnimationIndex := -1;
  FrameTexture := nil;
end;

destructor TRotateImageGaiGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  RotatedImage.Free;
  RotatedImage := nil;
  FrameTexture := nil;
  ClearFrameSequence;
  inherited Destroy;
end;

procedure TRotateImageGaiGI.Clear;
begin
  RenderedFrameIndex := 0;
  FrameIndex := 0;
  ImageDirty := True;
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited Clear;
end;

procedure TRotateImageGaiGI.SetAngle(Value: Byte);
begin
  if Value <> Angle then
  begin
    Angle := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;

procedure TRotateImageGaiGI.SetAlpha(Value: Byte);
begin
  if Value <> Alpha then
  begin
    Alpha := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;

procedure TRotateImageGaiGI.SetImage(Path: WideString; ImageSize, Pivot: TPoint);
var
  Data: TCGaiEC;
  Radius: Double;
begin
  RenderedFrameIndex := 0;
  ImageCache.SetCacheKey(Path);
  Data := AcquireCachedGai(ImageCache);
  try
    try
      RotationCache.SetCacheKey(
          IntToStr(ImageSize.X)
              + ','
              + IntToStr(ImageSize.Y)
              + ','
              + IntToStr(Data.GetCanvasSize.X)
              + ','
              + IntToStr(Data.GetCanvasSize.Y)
              + ','
              + IntToStr(Pivot.X)
              + ','
              + IntToStr(Pivot.Y)
      );
    except
      raise Exception.Create('Error in TRotateImageGaiGI.SetImage');
    end;
    Self.ImageSize := ImageSize;
    Radius := Sqr(Pivot.X - 0) + Sqr(Pivot.Y - 0);
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - 0));
    Radius := Max(Radius, Sqr(Pivot.X - 0) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Floor(Sqrt(Radius) * 2.0 + 2.0);
    SetSize(Classes.Point(Trunc(Radius), Trunc(Radius)));
    SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
    if (RotatedImage.Width <> ClientSize.X) or (RotatedImage.Height <> ClientSize.Y) then
      RotatedImage.AllocateBuffer(ClientSize.X, ClientSize.Y, 256, ClientSize.X);
    ImageDirty := True;
  finally
    ImageCache.Release;
  end;
  Invalidate;
end;

procedure TRotateImageGaiGI.SetFrame(Value: Integer);
begin
  if Value <> FrameIndex then
  begin
    FrameIndex := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;

procedure TRotateImageGaiGI.ClearFrameSequence;
begin
  if FrameIndexTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, FrameIndexTable);
    FrameIndexTable := nil;
  end;
  if FrameDelayTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, FrameDelayTable);
    FrameDelayTable := nil;
  end;
  RenderedFrameIndex := 0;
  FrameCount := 0;
end;

function TRotateImageGaiGI.GetFrameSourceIndex(Index: Integer): Integer;
begin
  Result := ReadIntegerEC(AddPointerOffset(FrameIndexTable, Index * SizeOf(Integer)));
end;

procedure TRotateImageGaiGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TRotateImageGaiGI.LoadFromBlock(Block: TBlockParEC);
begin
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
  ImageDirty := True;
end;

procedure TRotateImageGaiGI.LoadImageProperties(Block: TBlockParEC);
begin
  if (Block.CountParams('Image') > 0)
      and (Block.CountParams('Size') > 0)
      and (Block.CountParams('Sme') > 0) then
    SetImage(
        Block.GetParam('Image'),
        GetPointGI(Block.GetParam('Size')),
        GetPointGI(Block.GetParam('Sme'))
    );
  if Block.CountParams('Angle') > 0 then
    SetAngle(StrToInt(Block.GetParam('Angle')));
  if Block.CountParams('Trans') > 0 then
    SetAlpha(StrToInt(Block.GetParam('Trans')));
end;

procedure TRotateImageGaiGI.UpdateAutoGeometry;
var
  Data: TCGaiEC;
begin
  if AnimationIndex >= 0 then
  begin
    ClearFrameSequence;
    if (ImageCache <> nil) and (ImageCache.CacheKey <> '') then
    begin
      Data := AcquireCachedGai(ImageCache);
      try
        if (AnimationIndex < 0) or (Data.GetSequenceCount <= AnimationIndex) then
          raise Exception.Create('TgaiGI.AfterLoad. Anim not found.');
        FrameCount := Data.GetSequenceFrameCount(AnimationIndex);
        FrameIndexTable :=
            ReAllocFromHeapREC(GaiFrameHeap, FrameIndexTable, FrameCount * SizeOf(Integer));
        FrameDelayTable :=
            ReAllocFromHeapREC(GaiFrameHeap, FrameDelayTable, FrameCount * SizeOf(Integer));
        Data.FillSequenceFrameIndexTable(AnimationIndex, FrameIndexTable, SizeOf(Integer));
        Data.FillSequenceFrameDelayTable(AnimationIndex, FrameDelayTable, SizeOf(Integer));
      finally
        ImageCache.Release;
      end;
    end;
  end;
end;

procedure TRotateImageGaiGI.Draw(ClipRect: TRect);
var
  Data: TCGaiEC;
  Rotation: TCRotateBufEC;
  FrameGi: TgiGR;
  IndexPlane, PalettePlane: PgiPlaneGR;
  Degrees, C, S, LeftX, RightX, TopY, BottomY, CenterX, CenterY: Single;
  OldClip: TRect;
begin
  if (HitTestBounds.Left + ClientSize.X < 0)
      or (HitTestBounds.Left - ClientSize.X div 2 > GameScreenWidth)
      or (HitTestBounds.Top + ClientSize.Y < 0)
      or (HitTestBounds.Top - ClientSize.Y div 2 > GameScreenHeight) then
    Exit;
  if HardwareRenderingEnabled then
  begin
    if (RenderedAngle <> Angle)
        or (ImageDirty = True)
        or (FrameIndex <> RenderedFrameIndex)
        or (FrameTexture = nil) then
    begin
      ImageDirty := False;
      RenderedAngle := Angle;
      RenderedFrameIndex := FrameIndex;
      Data := nil;
      try
        Data := AcquireCachedGai(ImageCache);
        FrameTexture := Data.GetOrCreateFrameSurface(GetFrameSourceIndex(RenderedFrameIndex));
      finally
        if Data <> nil then
          ImageCache.Release;
      end;
    end;
    Vertices[0].Color := (Cardinal(Alpha) shl 24) or $FFFFFF;
    Vertices[1].Color := Vertices[0].Color;
    Vertices[2].Color := Vertices[0].Color;
    Vertices[3].Color := Vertices[0].Color;
    Vertices[0].Z := 1.0;
    Vertices[1].Z := 1.0;
    Vertices[2].Z := 1.0;
    Vertices[3].Z := 1.0;
    Vertices[0].Rhw := 1.0;
    Vertices[1].Rhw := 1.0;
    Vertices[2].Rhw := 1.0;
    Vertices[3].Rhw := 1.0;
    Vertices[0].U := 0.0;
    Vertices[0].V := 0.0;
    Vertices[1].U := 1.0;
    Vertices[1].V := 0.0;
    Vertices[2].U := 1.0;
    Vertices[2].V := 1.0;
    Vertices[3].U := 0.0;
    Vertices[3].V := 1.0;
    LeftX := -ImageSize.X / 2;
    TopY := -ImageSize.Y / 2;
    RightX := ImageSize.X / 2;
    BottomY := ImageSize.Y / 2;
    CenterX := ClientSize.X / 2;
    CenterY := ClientSize.Y / 2;
    Degrees := Angle / 256 * 360;
    C := Cos((3.1415926 / 180) * Degrees);
    S := Sin((3.1415926 / 180) * Degrees);
    Vertices[0].X := LeftX * C - TopY * S + CenterX + HitTestBounds.Left;
    Vertices[0].Y := LeftX * S + TopY * C + CenterY + HitTestBounds.Top;
    Vertices[1].X := RightX * C - TopY * S + CenterX + HitTestBounds.Left;
    Vertices[1].Y := RightX * S + TopY * C + CenterY + HitTestBounds.Top;
    Vertices[2].X := RightX * C - BottomY * S + CenterX + HitTestBounds.Left;
    Vertices[2].Y := RightX * S + BottomY * C + CenterY + HitTestBounds.Top;
    Vertices[3].X := LeftX * C - BottomY * S + CenterX + HitTestBounds.Left;
    Vertices[3].Y := LeftX * S + BottomY * C + CenterY + HitTestBounds.Top;
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(@ClipRect);
    Direct3DDevice.SetTexture(0, FrameTexture);
    Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLEFAN, 2, @Vertices, SizeOf(TScreenVertexGR));
    Direct3DDevice.SetTexture(0, nil);
    Direct3DDevice.SetScissorRect(@OldClip);
  end
  else
  begin
    if (RenderedAngle <> Angle) or (ImageDirty = True) or (FrameIndex <> RenderedFrameIndex) then
    begin
      ImageDirty := False;
      RenderedAngle := Angle;
      RenderedFrameIndex := FrameIndex;
      Data := nil;
      Rotation := nil;
      try
        Data := AcquireCachedGai(ImageCache);
        Rotation := AcquireOrCreateRotateBuf(RotationCache);
        RotatedImage.ClearPixels;
        FrameGi := Data.LoadFrameGi(GetFrameSourceIndex(RenderedFrameIndex));
        if FrameGi.GetFormat <> 4 then
          RaiseWideMessage('rotate GAI 1');
        if (FrameGi.GetContentSize.X <> Data.GetCanvasSize.X)
            or (FrameGi.GetContentSize.Y <> Data.GetCanvasSize.Y) then
          RaiseWideMessage('rotate GAI 2');
        IndexPlane := FrameGi.GetPlane(0);
        PalettePlane := FrameGi.GetPlane(1);
        RotatedImage.SetPalette(
            PColorRGBA(PAnsiChar(FrameGi.Data) + PalettePlane.DataOffset),
            Cardinal(PalettePlane.DataSize) shr 2
        );
        Ex_OKGR_RotateBuf_Draw_BYTE(
            RotatedImage.Pixels,
            RotatedImage.PitchBytes,
            Pointer(PAnsiChar(FrameGi.Data) + IndexPlane.DataOffset),
            FrameGi.GetContentSize.X,
            OriginPoint.X,
            OriginPoint.Y,
            Angle,
            Rotation.Buffer
        );
        { Native software alpha adjustment uses Pixels with a four-byte stride. }
        if Alpha <> 255 then
          Ex_OKGR_Light_BYTE(
              AddPointerOffset(RotatedImage.Pixels, 3),
              4,
              RotatedImage.PitchBytes - RotatedImage.Width * 4,
              RotatedImage.Width,
              RotatedImage.Height,
              Alpha
          );
      finally
        if Data <> nil then
          ImageCache.Release;
        if Rotation <> nil then
          RotationCache.Release;
      end;
    end;
    DrawPaletteAlphaBuffer16Clipped(
        ScreenRenderBuffer.GetPixels,
        ScreenRenderBuffer.PitchBytes,
        HitTestBounds.Left,
        HitTestBounds.Top,
        RotatedImage,
        ClipRect
    );
  end;
end;

procedure TRotateImageGaiGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;

end.
