{$EXCESSPRECISION OFF}
unit GI_SpaceImg;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  EC_Struct,
  EC_BlockPar,
  Types;
type
  TSpaceImgGI = class;
  PointerToTSpaceImageGI = ^TSpaceImageGI;
  TSpaceImageGI = record
    TemplateIndex: Integer;
    FrameIndex: Integer;
    FrameTicks: Integer;
    X: Single;
    Y: Single;
    Depth: Single;
    InverseDepth: Single;
    Gap1C: array[0..3] of Byte;
    OrbitCenter: TVector3D;
    Unknown38: TVector3D;
    ImageSize: TPoint;
    ImageOffset: TPoint;
    PixelPosition: TPoint;
    OrbitStepDegrees: Double;
    Unknown70: Integer;
    Gap74: array[0..3] of Byte;
    OrbitAngleRadians: Double;
    OrbitRadius: Double;
  end;
  PSpaceImageGI = PointerToTSpaceImageGI;
  TSpaceImgGI = class(TObjectGI)
    ImageCount: Integer;
    Images: PSpaceImageGI;
    ViewDirty: Boolean;
    Gap129: array[0..2] of Byte;
    ViewPosition: TPointF;
    AnimationTimer: PCallbackTimerGI;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure Invalidate; override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure ClearImages;
    function AllocateImage(Depth: Single): PSpaceImageGI;
    function AddImage(TemplateIndex: Integer; X: Single; Y: Single; Depth: Single): PSpaceImageGI;
    function NearestImageDistance(X: Single; Y: Single): Single;
    procedure UpdateImageOrbitAndFrame(Image: PSpaceImageGI);
    procedure ProjectImages;
    function GetImage(Index: Integer): PSpaceImageGI;
    procedure AnimateImages(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure SetViewPosition(Position: TPointF);
    procedure LoadSpaceImageProperties(Block: TBlockParEC);
  end;
implementation
uses
  EC_Mem,
  EC_CacheGAI,
  GlobalsV,
  GR_Main,
  GR_gi,
  GR_DX,
  Windows,
  Direct3D9,
  aMyFunction,
  Math;
constructor TSpaceImgGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ViewDirty := True;
end;
destructor TSpaceImgGI.Destroy;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  ClearImages;
  inherited Destroy;
end;
procedure TSpaceImgGI.ClearImages;
begin
  if Images <> nil then
  begin
    FreeEC(Images);
    Images := nil;
  end;
  ImageCount := 0;
end;
function TSpaceImgGI.AllocateImage(Depth: Single): PSpaceImageGI;
var
  Image: PSpaceImageGI;
  I, J: Integer;
begin
  Inc(ImageCount);
  Images := ReAllocREC(Images, ImageCount * SizeOf(TSpaceImageGI));
  Image := Images;
  I := 0;
  while ImageCount - 1 > I do
  begin
    if Depth > Image.Depth then
      Break;
    Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
    Inc(I);
  end;
  J := ImageCount - 1;
  while J > I do
  begin
    CopyMemory(
        AddPointerOffset(Images, J * SizeOf(TSpaceImageGI)),
        AddPointerOffset(Images, (J - 1) * SizeOf(TSpaceImageGI)),
        SizeOf(TSpaceImageGI)
    );
    Dec(J);
  end;
  Result := AddPointerOffset(Images, I * SizeOf(TSpaceImageGI));
end;
function TSpaceImgGI.AddImage(TemplateIndex: Integer; X, Y, Depth: Single): PSpaceImageGI;
var
  Image: PSpaceImageGI;
  Data: TCGaiEC;
begin
  Image := AllocateImage(Depth);
  Image.TemplateIndex := TemplateIndex mod (High(SpaceImageTemplates) + 1);
  Image.X := X;
  Image.Y := Y;
  Image.Depth := Depth;
  Image.InverseDepth := 1.0 / Depth;
  Data := AcquireCachedGai(TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl));
  try
    Image.ImageSize := Data.GetCanvasSize;
    Image.ImageOffset := HalfPoint(Image.ImageSize);
    Image.FrameIndex := RandomIntRange(0, Data.GetSequenceFrameCount(0) - 1);
    Image.FrameTicks := Round(Data.GetSequenceFrameDelay(0, Image.FrameIndex) / 10.0);
  finally
    TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl).Release;
  end;
  Image.Unknown38 := MakeVector3D(0, 0, 0);
  Image.Unknown70 := 0;
  Image.OrbitAngleRadians := 0;
  Image.OrbitRadius := 0;
  Image.OrbitCenter := MakeVector3D(0, 0, 0);
  Image.OrbitStepDegrees := 0;
  ViewDirty := True;
  Result := Image;
end;
function TSpaceImgGI.NearestImageDistance(X, Y: Single): Single;
var
  I: Integer;
  Image: PSpaceImageGI;
  DistanceSquared: Single;
begin
  Result := 1e10;
  Image := Images;
  for I := 0 to ImageCount - 1 do
  begin
    DistanceSquared := Sqr(X - Image.X) + Sqr(Y - Image.Y);
    if DistanceSquared < Result then
      Result := DistanceSquared;
    Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
  end;
  Result := Sqrt(Result);
end;
procedure TSpaceImgGI.UpdateImageOrbitAndFrame(Image: PSpaceImageGI);
var
  Data: TCGaiEC;
begin
  Image.OrbitRadius :=
      Sqrt(Sqr(Image.X - Image.OrbitCenter.X) + Sqr(Image.Y - Image.OrbitCenter.Y));
  if Image.OrbitRadius = 0 then
    Image.OrbitAngleRadians := 0
  else
    Image.OrbitAngleRadians :=
        ArcTan2(Image.X - Image.OrbitCenter.X, -(Image.Y - Image.OrbitCenter.Y));
  Data := AcquireCachedGai(TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl));
  try
    Image.ImageSize := Data.GetCanvasSize;
    Image.ImageOffset := HalfPoint(Image.ImageSize);
    Image.FrameIndex := Image.FrameIndex mod Data.GetSequenceFrameCount(0);
    Image.FrameTicks := Round(Data.GetSequenceFrameDelay(0, Image.FrameIndex) / 10.0);
  finally
    TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl).Release;
  end;
end;
procedure TSpaceImgGI.ProjectImages;
var
  I: Integer;
  Image: PSpaceImageGI;
begin
  if ImageCount < 1 then
    Exit;
  Image := Images;
  for I := 0 to ImageCount - 1 do
  begin
    Image.PixelPosition.X :=
        AbsolutePosition.X + Integer(Round((Image.X - ViewPosition.X) * Image.InverseDepth));
    Image.PixelPosition.Y :=
        AbsolutePosition.Y + Integer(Round((Image.Y - ViewPosition.Y) * Image.InverseDepth));
    Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
  end;
  ViewDirty := False;
end;
function TSpaceImgGI.GetImage(Index: Integer): PSpaceImageGI;
begin
  Result := AddPointerOffset(Images, Index * SizeOf(TSpaceImageGI));
end;
procedure TSpaceImgGI.AnimateImages(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Image: PSpaceImageGI;
  I: Integer;
  Data: TCGaiEC;
begin
  Image := Images;
  for I := 0 to ImageCount - 1 do
  begin
    Dec(Image.FrameTicks);
    if Image.FrameTicks <= 0 then
    begin
      Data :=
          AcquireCachedGai(TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl));
      try
        Inc(Image.FrameIndex);
        if Data.GetSequenceFrameCount(0) <= Image.FrameIndex then
          Image.FrameIndex := 0;
        Image.FrameTicks := Round(Data.GetSequenceFrameDelay(0, Image.FrameIndex) / 10.0);
      finally
        TCGaiControlEC(SpaceImageTemplates[Image.TemplateIndex].CacheControl).Release;
      end;
    end;
    if (Image.OrbitRadius <> 0) and (Image.OrbitStepDegrees <> 0) then
    begin
      Image.OrbitAngleRadians :=
          (3.1415926 / 180) * Image.OrbitStepDegrees + Image.OrbitAngleRadians;
      Image.X := Sin(Image.OrbitAngleRadians) * Image.OrbitRadius + Image.OrbitCenter.X;
      Image.Y := Image.OrbitCenter.Y - Cos(Image.OrbitAngleRadians) * Image.OrbitRadius;
    end;
    Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
  end;
  ProjectImages;
end;
procedure TSpaceImgGI.SetViewPosition(Position: TPointF);
begin
  if (ViewPosition.X <> Position.X) or (ViewPosition.Y <> Position.Y) then
  begin
    Invalidate;
    ViewPosition := Position;
    ViewDirty := True;
    ProjectImages;
    Invalidate;
  end;
end;
procedure TSpaceImgGI.Invalidate;
var
  Image: PSpaceImageGI;
  I: Integer;
  Bounds: TRect;
begin
  Image := Images;
  for I := 0 to ImageCount - 1 do
  begin
    Bounds.Left := Image.PixelPosition.X + Image.ImageOffset.X;
    Bounds.Top := Image.PixelPosition.Y + Image.ImageOffset.Y;
    Bounds.Right := Bounds.Left + Image.ImageSize.X;
    Bounds.Bottom := Bounds.Top + Image.ImageSize.Y;
    MessageLoop.QueueUpdateRect(Bounds);
    Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
  end;
end;
procedure TSpaceImgGI.OnActivate;
begin
  inherited OnActivate;
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  AnimationTimer := MessageLoop.ScheduleCallbackTimer(10, 10, AnimateImages);
end;
procedure TSpaceImgGI.OnDeactivate;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  inherited OnDeactivate;
end;
procedure TSpaceImgGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadSpaceImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
procedure TSpaceImgGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadSpaceImageProperties(Block);
end;
procedure TSpaceImgGI.LoadSpaceImageProperties(Block: TBlockParEC);
begin
end;
procedure TSpaceImgGI.UpdateAutoGeometry;
begin
end;
procedure TSpaceImgGI.Draw(ClipRect: TRect);
var
  Image: PSpaceImageGI;
  I: Integer;
  Data: TCGaiEC;
  Frame: TgiGR;
  Origin: TPoint;
  Bounds, Intersection: TRect;
begin
  for I := 0 to High(SpaceImageTemplates) do
    SpaceImageTemplates[I].CachedData := nil;
  try

    for I := 0 to High(SpaceImageTemplates) do
      SpaceImageTemplates[I].CachedData :=
          AcquireCachedGai(TCGaiControlEC(SpaceImageTemplates[I].CacheControl));

    Image := Images;
    for I := 0 to ImageCount - 1 do
    begin
      Bounds.Left := Image.PixelPosition.X + Image.ImageOffset.X;
      Bounds.Top := Image.PixelPosition.Y + Image.ImageOffset.Y;
      Bounds.Right := Bounds.Left + Image.ImageSize.X;
      Bounds.Bottom := Bounds.Top + Image.ImageSize.Y;
      if IntersectRects(Intersection, Bounds, ClipRect) then
      begin

        Data := TCGaiEC(SpaceImageTemplates[Image.TemplateIndex].CachedData);
        Frame := Data.LoadFrameGi(Data.GetSequenceFrameIndex(0, Image.FrameIndex));
        if HardwareRenderingEnabled then
        begin
          Data.GetOrCreateFrameSurface(Data.GetSequenceFrameIndex(0, Image.FrameIndex));
          Origin := Data.GetFrameOrigin(Data.GetSequenceFrameIndex(0, Image.FrameIndex));
          DrawTexture(
              Data.GetOrCreateFrameSurface(Data.GetSequenceFrameIndex(0, Image.FrameIndex)),
              Bounds.Left + Origin.X,
              Bounds.Top + Origin.Y,
              255,
              $FFFFFF,
              @ClipRect,
              False,
              False
          );
        end
        else
          Frame.DrawToGraphBuf(
              ScreenRenderBuffer,
              Bounds.Left + Frame.GetBoundsRect.Left - Data.GetBoundsRect.Left,
              Bounds.Top + Frame.GetBoundsRect.Top - Data.GetBoundsRect.Top,
              ClipRect,
              0,
              255
          );
      end;
      Image := AddPointerOffset(Image, SizeOf(TSpaceImageGI));
    end;
  finally
    for I := 0 to High(SpaceImageTemplates) do
      if TCGaiEC(SpaceImageTemplates[I].CachedData) <> nil then
      begin
        TCGaiControlEC(SpaceImageTemplates[I].CacheControl).Release;
        SpaceImageTemplates[I].CachedData := nil;
      end;
  end;
end;
end.
