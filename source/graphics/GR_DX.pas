{$EXCESSPRECISION OFF}
unit GR_DX;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Direct3D9,
  Classes,
  Types;
type
  TTextureGR = class;
  TScreenVertexGR = packed record
    X: Single;
    Y: Single;
    Z: Single;
    RHW: Single;
    Color: Cardinal;
    U: Single;
    V: Single;
  end;
  TScreenVerticesGR = array[0..15] of TScreenVertexGR;
  TCircleTableGR = array[0..360] of Single;
  TLineAlphaTableGR = array[0..359] of Byte;
  TTextureGR = class(TObject)
    LastUseTick: Cardinal;
    SurfaceCount: Integer;
    Surfaces: array of IDirect3DTexture9;
    ResidentBytes: Cardinal;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ReleaseSurfaces;
    function GetSurface(Index: Integer): IDirect3DTexture9;
    procedure SetSurface(Value: IDirect3DTexture9; Index: Integer);
  end;
var
  TextureManagerDisabled: Boolean = False;
  MaxTextureSize: TPoint;
  DrawVertices: TScreenVerticesGR;
  PendingPoints: array of TScreenVertexGR;
  TextureCaches: TList = nil;
  AvailableTextureBytes: Cardinal = 0;
  CircleCos: TCircleTableGR;
  CircleSin: TCircleTableGR;
  LineAlphaTable: TLineAlphaTableGR;
  ReservedTextureBytes: Cardinal = 0;
  TextureIdleSeconds: Integer = 120;
  LastTextureEvictionTick: Cardinal = 0;
  PendingPointCount: Integer = 0;
  PendingPointCapacity: Integer = 0;
  ResidentTextureBytes: Cardinal = 0;
function CreateTextureCache: TTextureGR;
procedure FreeTextureCache(Cache: TTextureGR);
procedure ReleaseAllTextureSurfaces;
procedure EvictTextureCaches(Force: Boolean);
function GR_CreateTexture(
    Width: Integer;
    Height: Integer;
    Format: Cardinal;
    Pool: Cardinal
): IDirect3DTexture9;
function CreateTextureFromPixels(
    Width: Integer;
    Height: Integer;
    Format: Cardinal;
    Pixels: Pointer;
    PitchBytes: Integer;
    Pool: Cardinal
): IDirect3DTexture9;
procedure ClearTexturePixels(Texture: IDirect3DTexture9);
procedure QueueDrawPoint(X: Integer; Y: Integer; Color: Cardinal; Alpha: Integer);
procedure FlushDrawPoints(ClipRect: PRect);
procedure DrawAlphaLine(
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    Color: Cardinal;
    Alpha: Integer;
    ClipRect: PRect
);
procedure DrawGradientLine(
    X1: Integer;
    Y1: Integer;
    Color1: Cardinal;
    X2: Integer;
    Y2: Integer;
    Color2: Cardinal;
    ClipRect: PRect
);
procedure DrawAntialiasedLineDX(
    StartX: Integer;
    StartY: Integer;
    FinishX: Integer;
    FinishY: Integer;
    Color: Cardinal;
    Alpha: Integer;
    UnusedClipRect: PRect
);
procedure DrawAnimatedLineDX(
    StartX: Integer;
    StartY: Integer;
    FinishX: Integer;
    FinishY: Integer;
    Color: Cardinal;
    Phase: Integer;
    UnusedClipRect: PRect
);
procedure DrawColoredTriangle(
    X1: Integer;
    Y1: Integer;
    Color1: Cardinal;
    X2: Integer;
    Y2: Integer;
    Color2: Cardinal;
    X3: Integer;
    Y3: Integer;
    Color3: Cardinal;
    Filled: Boolean;
    ClipRect: PRect
);
procedure DrawColoredRect(
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    Color: Cardinal;
    Alpha: Integer;
    Filled: Boolean;
    ClipRect: PRect
);
procedure DrawAntialiasedCircle(
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Cardinal;
    Alpha: Integer;
    ClipRect: PRect
);
procedure DrawCircle(
    X: Integer;
    Y: Integer;
    Radius: Integer;
    Color: Cardinal;
    Alpha: Integer;
    Mode: Integer;
    ClipRect: PRect
);
procedure DrawTexture(
    Texture: IDirect3DTexture9;
    X: Integer;
    Y: Integer;
    Alpha: Integer;
    Color: Cardinal;
    ClipRect: PRect;
    UsePreparedVertices: Boolean;
    MirrorHorizontal: Boolean
);
procedure DrawTextureSized(
    Texture: IDirect3DTexture9;
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    Alpha: Integer;
    Color: Cardinal;
    ClipRect: PRect;
    UsePreparedVertices: Boolean;
    MirrorHorizontal: Boolean
);
function Color565ToArgb(Color: Cardinal): Cardinal;
function ColorWithAlpha(Color: Cardinal; Alpha: Cardinal): Cardinal;
function GetTextureByteSize(Texture: IDirect3DTexture9): Cardinal;
procedure AddResidentTextureBytes(ByteCount: Cardinal);
procedure SubtractResidentTextureBytes(ByteCount: Cardinal);
procedure LinkRecoveredTypes;
implementation
uses
  MMSystem,
  EC_Mem,
  GR_Main,
  EC_Str,
  Math,
  Windows;
// @unit-initialization $8779F0
// @unit-finalization $851D10

function CreateTextureCache: TTextureGR;
var
  Texture: TTextureGR;
begin
  if TextureCaches = nil then
    TextureCaches := TList.Create;
  Texture := TTextureGR.Create;
  TextureCaches.Add(Texture);
  Result := Texture;
end;

procedure FreeTextureCache(Cache: TTextureGR);
var
  Index: Integer;
begin
  if Cache <> nil then
  begin
    if TextureCaches <> nil then
    begin
      Index := TextureCaches.IndexOf(Cache);
      if Index >= 0 then
        TextureCaches.Delete(Index);
    end;
    Cache.Free;
  end;
end;

procedure ReleaseAllTextureSurfaces;
var
  Index: Integer;
  Texture: TTextureGR;
begin
  if TextureCaches <> nil then
  begin
    Index := 0;
    while TextureCaches.Count > Index do
    begin
      Texture := TextureCaches[Index];
      Texture.ReleaseSurfaces;
      Inc(Index);
    end;
  end;

end;

procedure EvictTextureCaches(Force: Boolean);
var
  i: Integer;
  Texture: TObject;
  AvailableBytes: Cardinal;
  LastUsed, NowTick: Cardinal;
begin
  if TextureCaches = nil then
    Exit;
  if Direct3DDevice = nil then
    Exit;
  NowTick := timeGetTime;
  if (NowTick - LastTextureEvictionTick < 10) and not Force then
    Exit;
  LastTextureEvictionTick := NowTick;
  AvailableBytes := Max(0, Integer(Direct3DDevice.GetAvailableTextureMem - ReservedTextureBytes));
  if (ResidentTextureBytes < $10000000) and (AvailableBytes > $1400000) and not Force then
    Exit;
  i := 0;
  while i < TextureCaches.Count do
  begin
    Texture := TextureCaches[i];
    if Texture is TTextureGR then
    begin
      LastUsed := TTextureGR(Texture).LastUseTick;
      if NowTick - LastUsed > Cardinal(TextureIdleSeconds * 1000) then
        TTextureGR(Texture).ReleaseSurfaces;
    end;
    Inc(i);
  end;
  AvailableBytes := Max(0, Integer(Direct3DDevice.GetAvailableTextureMem - ReservedTextureBytes));
  if (AvailableBytes > 30 * 1024 * 1024.0) and (TextureIdleSeconds < 120) then
    Inc(TextureIdleSeconds, 10);
  if (ResidentTextureBytes > $10000000) or (AvailableBytes < $1400000) then
    if TextureIdleSeconds > 20 then
      Dec(TextureIdleSeconds, 10);
end;

function GR_CreateTexture(Width, Height: Integer; Format, Pool: Cardinal): IDirect3DTexture9;
var
  Texture: IDirect3DTexture9;
  ErrorCode: Integer;
begin
  if Direct3DDevice = nil then
  begin
    Result := nil;
    Exit;
  end;
  if Width < 16 then
    Width := 16;
  if Height < 16 then
    Height := 16;
  ErrorCode := Direct3DDevice.CreateTexture(Width, Height, 1, 0, Format, Pool, Texture, nil);
  if ErrorCode = LongInt($8007000E) then
  begin
    AppendLogTextThreadSafe('Failed to create texture, trying to free some textures... ');
    EvictTextureCaches(True);
    ErrorCode := Direct3DDevice.CreateTexture(Width, Height, 1, 0, Format, Pool, Texture, nil);
    if ErrorCode = 0 then
      AppendLogLineThreadSafe('success')
    else
    begin
      AppendLogLineThreadSafe('fail');
      LogMemoryUsage;
      AppendLogLineThreadSafe(
          'GR_CreateTexture()::CreateTexture('
              + IntToWideString(Width)
              + ','
              + IntToWideString(Height)
              + ') error='
              + IntToWideString(ErrorCode)
      );
    end;
  end;
  ClearTexturePixels(Texture);
  Result := Texture;
end;

function CreateTextureFromPixels(
    Width, Height: Integer;
    Format: Cardinal;
    Pixels: Pointer;
    PitchBytes: Integer;
    Pool: Cardinal
): IDirect3DTexture9;
var
  Y: Integer;
  Staging, Texture: IDirect3DTexture9;
  Locked: TD3DLockedRect;
  BytesPerPixel: Integer;
begin
  if Direct3DDevice = nil then
  begin
    Result := nil;
    Exit;
  end;
  if Pool = D3DPOOL_DEFAULT then
  begin
    Direct3DDevice.CreateTexture(Width, Height, 1, 0, Format, D3DPOOL_SYSTEMMEM, Staging, nil);
    Staging.LockRect(0, Locked, nil, 0);
    BytesPerPixel := PitchBytes div Width;
    for Y := 0 to Height - 1 do
      CopyMemory(
          AddPointerOffset(Locked.Bits, Locked.Pitch * Y),
          AddPointerOffset(Pixels, PitchBytes * Y),
          Width * BytesPerPixel
      );
    Staging.UnlockRect(0);
    Direct3DDevice.CreateTexture(Width, Height, 1, 0, Format, Pool, Texture, nil);
    Direct3DDevice.UpdateTexture(Staging, Texture);
    Staging := nil;
  end
  else
  begin
    Direct3DDevice.CreateTexture(Width, Height, 1, 0, Format, Pool, Texture, nil);
    Texture.LockRect(0, Locked, nil, 0);
    BytesPerPixel := PitchBytes div Width;
    for Y := 0 to Height - 1 do
      CopyMemory(
          AddPointerOffset(Locked.Bits, Locked.Pitch * Y),
          AddPointerOffset(Pixels, PitchBytes * Y),
          Width * BytesPerPixel
      );
    Texture.UnlockRect(0);
  end;
  Result := Texture;
end;

procedure ClearTexturePixels(Texture: IDirect3DTexture9);
var
  Locked: TD3DLockedRect;
  Y: Cardinal;
  Desc: TD3DSurfaceDesc;
begin
  if Texture <> nil then
  begin
    Texture.GetLevelDesc(0, Desc);
    Texture.LockRect(0, Locked, nil, 0);
    if Locked.Bits <> nil then
      for Y := 0 to Desc.Height - 1 do
        FillMemory(Pointer(Integer(Y) * Locked.Pitch + PtrUInt(Locked.Bits)), Locked.Pitch, 0);
    Texture.UnlockRect(0);
  end;
end;

constructor TTextureGR.Create;
begin
  SurfaceCount := 0;
  LastUseTick := 0;
  ResidentBytes := 0;
end;

destructor TTextureGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TTextureGR.Clear;
var
  Index: Integer;
begin
  Index := 0;
  while Index < SurfaceCount do
  begin
    if Surfaces[Index] <> nil then
      Surfaces[Index] := nil;
    Inc(Index);
  end;
  if ResidentBytes > 0 then
    SubtractResidentTextureBytes(ResidentBytes);
  ResidentBytes := 0;
  SetLength(Surfaces, 0);
  SurfaceCount := 0;
  LastUseTick := 0;
end;

procedure TTextureGR.ReleaseSurfaces;
var
  i: Integer;
begin
  i := 0;
  while i < SurfaceCount do
  begin
    Surfaces[i] := nil;
    Inc(i);
  end;
  if ResidentBytes > 0 then
    SubtractResidentTextureBytes(ResidentBytes);
  ResidentBytes := 0;
  LastUseTick := 0;
end;

function TTextureGR.GetSurface(Index: Integer): IDirect3DTexture9;
begin
  Result := nil;
  if (Index < 0) or (Index >= SurfaceCount) then
    Exit;
  LastUseTick := timeGetTime;
  Result := Surfaces[Index];
end;

procedure TTextureGR.SetSurface(Value: IDirect3DTexture9; Index: Integer);
var
  i: Integer;
  ByteCount: Cardinal;
begin
  if (Index < 0) or (Index = SurfaceCount) then
  begin
    Index := SurfaceCount;
    Inc(SurfaceCount);
    SetLength(Surfaces, SurfaceCount);
  end
  else if Index > SurfaceCount then
  begin
    i := SurfaceCount;
    SurfaceCount := Index + 1;
    SetLength(Surfaces, SurfaceCount);
    while i < SurfaceCount do
    begin
      Surfaces[i] := nil;
      Inc(i);
    end;
  end;
  if Surfaces[Index] <> nil then
  begin
    ByteCount := GetTextureByteSize(Surfaces[Index]);
    if ByteCount > 0 then
    begin
      Dec(ResidentBytes, ByteCount);
      SubtractResidentTextureBytes(ByteCount);
    end;
  end;
  ByteCount := GetTextureByteSize(Value);
  Inc(ResidentBytes, ByteCount);
  AddResidentTextureBytes(ByteCount);
  Surfaces[Index] := nil;
  Surfaces[Index] := Value;
end;

procedure QueueDrawPoint(X, Y: Integer; Color: Cardinal; Alpha: Integer);
var
  Index: Integer;
begin
  if Alpha = 0 then
    Exit;
  if PendingPointCount >= PendingPointCapacity then
  begin
    Inc(PendingPointCapacity, 256);
    SetLength(PendingPoints, PendingPointCapacity);
  end;
  Index := PendingPointCount;
  Inc(PendingPointCount);
  PendingPoints[Index].Color := ColorWithAlpha(Color, Alpha);
  PendingPoints[Index].X := X;
  PendingPoints[Index].Y := Y;
  PendingPoints[Index].Z := 1;
  PendingPoints[Index].RHW := 1;
  PendingPoints[Index].U := 0;
  PendingPoints[Index].V := 0;
end;

procedure FlushDrawPoints(ClipRect: PRect);
var
  OldClip: TRect;
begin
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  Direct3DDevice.DrawPrimitiveUP(
      D3DPT_POINTLIST,
      PendingPointCount,
      Pointer(PendingPoints),
      SizeOf(TScreenVertexGR)
  );
  PendingPointCount := 0;
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

procedure DrawAlphaLine(X1, Y1, X2, Y2: Integer; Color: Cardinal; Alpha: Integer; ClipRect: PRect);
begin
  DrawGradientLine(
      X1,
      Y1,
      ColorWithAlpha(Color, Alpha),
      X2,
      Y2,
      ColorWithAlpha(Color, Alpha),
      ClipRect
  );
end;

procedure DrawGradientLine(
    X1, Y1: Integer;
    Color1: Cardinal;
    X2, Y2: Integer;
    Color2: Cardinal;
    ClipRect: PRect
);
var
  OldClip: TRect;
begin
  DrawVertices[0].Color := Color1;
  DrawVertices[0].X := X1;
  DrawVertices[0].Y := Y1;
  DrawVertices[1].Color := Color2;
  DrawVertices[1].X := X2;
  DrawVertices[1].Y := Y2;
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  Direct3DDevice.DrawPrimitiveUP(D3DPT_LINESTRIP, 1, @DrawVertices, SizeOf(TScreenVertexGR));
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

procedure DrawAntialiasedLineDX(
    StartX, StartY, FinishX, FinishY: Integer;
    Color: Cardinal;
    Alpha: Integer;
    UnusedClipRect: PRect
);
var
  Slope, DX, DY, Gap, EndX, EndY, InterY, Coverage1, Coverage2: Double;
  X, FirstX, LastX, FirstY, LastY: Integer;
  Steep: Boolean;
  Temp, X1, Y1, X2, Y2: Double;
  function LineFractionDX(
      Value: Double
  ): Double; // @addr $850398 @ida "double __userpurge $name@<st0>(double Value@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x008505E5 0x00850626 0x00850640 0x0085073E 0x00850787 0x0085079E 0x0085088B 0x008508A5"
  begin
    Result := Value - Floor(Value);
  end;
begin
  X1 := StartX;
  Y1 := StartY;
  X2 := FinishX;
  Y2 := FinishY;
  DX := X2 - X1;
  DY := Y2 - Y1;
  if (DX = 0) and (DY = 0) then
    Exit;
  if Abs(DX) > Abs(DY) then
    Steep := False
  else
  begin
    Steep := True;
    Temp := X1;
    X1 := Y1;
    Y1 := Temp;
    Temp := X2;
    X2 := Y2;
    Y2 := Temp;
    Temp := DX;
    DX := DY;
    DY := Temp;
  end;
  if X1 > X2 then
  begin
    Temp := X1;
    X1 := X2;
    X2 := Temp;
    Temp := Y1;
    Y1 := Y2;
    Y2 := Temp;
    DX := X2 - X1;
    DY := Y2 - Y1;
  end;
  Slope := DY / DX;
  EndX := Floor(X1 + 0.5);
  EndY := Y1 + (EndX - X1) * Slope;
  Gap := 1 - LineFractionDX(X1 + 0.5);
  FirstX := Floor(X1 + 0.5);
  FirstY := Floor(EndY);
  Coverage1 := (1 - LineFractionDX(EndY)) * Gap;
  Coverage2 := LineFractionDX(EndY) * Gap;
  if Steep then
  begin
    QueueDrawPoint(FirstY, FirstX, Color, Ceil(Alpha * Coverage1));
    QueueDrawPoint(FirstY + 1, FirstX, Color, Ceil(Alpha * Coverage2));
  end
  else
  begin
    QueueDrawPoint(FirstX, FirstY, Color, Ceil(Alpha * Coverage1));
    QueueDrawPoint(FirstX, FirstY + 1, Color, Ceil(Alpha * Coverage2));
  end;
  X := FirstX + 1;
  InterY := EndY + Slope;
  EndX := Floor(X2 + 0.5);
  EndY := Y2 + (EndX - X2) * Slope;
  Gap := 1 - LineFractionDX(X2 - 0.5);
  LastX := Floor(X2 + 0.5);
  LastY := Floor(EndY);
  while LastX - 1 >= X do
  begin
    Coverage1 := 1 - LineFractionDX(InterY);
    Coverage2 := LineFractionDX(InterY);
    if Steep then
    begin
      QueueDrawPoint(Floor(InterY), X, Color, Ceil(Alpha * Coverage1));
      QueueDrawPoint(Floor(InterY) + 1, X, Color, Ceil(Alpha * Coverage2));
    end
    else
    begin
      QueueDrawPoint(X, Floor(InterY), Color, Ceil(Alpha * Coverage1));
      QueueDrawPoint(X, Floor(InterY) + 1, Color, Ceil(Alpha * Coverage2));
    end;
    InterY := InterY + Slope;
    Inc(X);
  end;
  Coverage1 := (1 - LineFractionDX(EndY)) * Gap;
  Coverage2 := LineFractionDX(EndY) * Gap;
  if Steep then
  begin
    QueueDrawPoint(LastY, LastX, Color, Ceil(Alpha * Coverage1));
    QueueDrawPoint(LastY + 1, LastX, Color, Ceil(Alpha * Coverage2));
  end
  else
  begin
    QueueDrawPoint(LastX, LastY, Color, Ceil(Alpha * Coverage1));
    QueueDrawPoint(LastX, LastY + 1, Color, Ceil(Alpha * Coverage2));
  end;
  FlushDrawPoints(nil);
end;

procedure DrawAnimatedLineDX(
    StartX, StartY, FinishX, FinishY: Integer;
    Color: Cardinal;
    Phase: Integer;
    UnusedClipRect: PRect
);
var
  Slope, DX, DY, Gap, EndX, EndY, InterY, Coverage1, Coverage2: Double;
  X, FirstX, LastX, FirstY, LastY: Integer;
  Steep: Boolean;
  Temp, X1, Y1, X2, Y2: Double;
  function AnimatedLineFractionDX(
      Value: Double
  ): Double; // @addr $85095C @ida "double __userpurge $name@<st0>(double Value@<^0>, void *ParentFrame@<^8>);" @stackpop 8 @calls "0x00850BCD 0x00850C0E 0x00850C28 0x00850D79 0x00850DC2 0x00850DD9 0x00850F20 0x00850F3A"
  begin
    Result := Value - Floor(Value);
  end;
  procedure AdvanceLinePhase; // @addr $850988 @ida "void __usercall $name(void *ParentFrame@<^0>);" @stackpop 0 @calls "0x00850D10 0x00850EF9"
  begin
    Inc(Phase, 20);
    if Phase >= 360 then
      Dec(Phase, 360);
  end;
begin
  X1 := StartX;
  Y1 := StartY;
  X2 := FinishX;
  Y2 := FinishY;
  DX := X2 - X1;
  DY := Y2 - Y1;
  if (DX = 0) and (DY = 0) then
    Exit;
  if Abs(DX) > Abs(DY) then
    Steep := False
  else
  begin
    Steep := True;
    Temp := X1;
    X1 := Y1;
    Y1 := Temp;
    Temp := X2;
    X2 := Y2;
    Y2 := Temp;
    Temp := DX;
    DX := DY;
    DY := Temp;
  end;
  if X1 > X2 then
  begin
    Temp := X1;
    X1 := X2;
    X2 := Temp;
    Temp := Y1;
    Y1 := Y2;
    Y2 := Temp;
    DX := X2 - X1;
    DY := Y2 - Y1;
  end;
  Slope := DY / DX;
  EndX := Floor(X1 + 0.5);
  EndY := Y1 + (EndX - X1) * Slope;
  Gap := 1 - AnimatedLineFractionDX(X1 + 0.5);
  FirstX := Floor(X1 + 0.5);
  FirstY := Floor(EndY);
  Coverage1 := (1 - AnimatedLineFractionDX(EndY)) * Gap;
  Coverage2 := AnimatedLineFractionDX(EndY) * Gap;
  if Steep then
  begin
    QueueDrawPoint(FirstY, FirstX, Color, Ceil(LineAlphaTable[Phase] * Coverage1));
    QueueDrawPoint(FirstY + 1, FirstX, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
  end
  else
  begin
    QueueDrawPoint(FirstX, FirstY, Color, Ceil(LineAlphaTable[Phase] * Coverage1));
    QueueDrawPoint(FirstX, FirstY + 1, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
  end;
  AdvanceLinePhase;
  X := FirstX + 1;
  InterY := EndY + Slope;
  EndX := Floor(X2 + 0.5);
  EndY := Y2 + (EndX - X2) * Slope;
  Gap := 1 - AnimatedLineFractionDX(X2 - 0.5);
  LastX := Floor(X2 + 0.5);
  LastY := Floor(EndY);
  while LastX - 1 >= X do
  begin
    Coverage1 := 1 - AnimatedLineFractionDX(InterY);
    Coverage2 := AnimatedLineFractionDX(InterY);
    if Steep then
    begin
      QueueDrawPoint(Floor(InterY), X, Color, Ceil(LineAlphaTable[Phase] * Coverage1));
      QueueDrawPoint(Floor(InterY) + 1, X, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
    end
    else
    begin
      QueueDrawPoint(X, Floor(InterY), Color, Ceil(LineAlphaTable[Phase] * Coverage1));
      QueueDrawPoint(X, Floor(InterY) + 1, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
    end;
    AdvanceLinePhase;
    InterY := InterY + Slope;
    Inc(X);
  end;
  Coverage1 := (1 - AnimatedLineFractionDX(EndY)) * Gap;
  Coverage2 := AnimatedLineFractionDX(EndY) * Gap;
  if Steep then
  begin
    QueueDrawPoint(LastY, LastX, Color, Ceil(LineAlphaTable[Phase] * Coverage1));
    QueueDrawPoint(LastY + 1, LastX, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
  end
  else
  begin
    QueueDrawPoint(LastX, LastY, Color, Ceil(LineAlphaTable[Phase] * Coverage1));
    QueueDrawPoint(LastX, LastY + 1, Color, Ceil(LineAlphaTable[Phase] * Coverage2));
  end;
  FlushDrawPoints(nil);
end;

procedure DrawColoredTriangle(
    X1, Y1: Integer;
    Color1: Cardinal;
    X2, Y2: Integer;
    Color2: Cardinal;
    X3, Y3: Integer;
    Color3: Cardinal;
    Filled: Boolean;
    ClipRect: PRect
);
var
  OldClip: TRect;
begin
  DrawVertices[0].Color := Color1;
  DrawVertices[0].X := X1;
  DrawVertices[0].Y := Y1;
  DrawVertices[1].Color := Color2;
  DrawVertices[1].X := X2;
  DrawVertices[1].Y := Y2;
  DrawVertices[2].Color := Color3;
  DrawVertices[2].X := X3;
  DrawVertices[2].Y := Y3;
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  // Native $8510D3/$851102 set state 8 to 2/3: wireframe/solid fill.
  if not Filled then
    Direct3DDevice.SetRenderState(D3DRS_FILLMODE, D3DFILL_WIREFRAME);
  Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, 1, @DrawVertices, SizeOf(TScreenVertexGR));
  Direct3DDevice.SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

procedure DrawColoredRect(
    X, Y, Width, Height: Integer;
    Color: Cardinal;
    Alpha: Integer;
    Filled: Boolean;
    ClipRect: PRect
);
var
  OldClip: TRect;
begin
  DrawVertices[0].Color := ColorWithAlpha(Color, Alpha);
  DrawVertices[0].X := X - 0.5;
  DrawVertices[0].Y := Y - 0.5;
  DrawVertices[1].Color := DrawVertices[0].Color;
  DrawVertices[1].X := X + Width - 0.5;
  DrawVertices[1].Y := Y - 0.5;
  DrawVertices[2].Color := DrawVertices[0].Color;
  DrawVertices[2].X := X + Width - 0.5;
  DrawVertices[2].Y := Y + Height - 0.5;
  DrawVertices[3].Color := DrawVertices[0].Color;
  DrawVertices[3].X := X - 0.5;
  DrawVertices[3].Y := Y + Height - 0.5;
  DrawVertices[4].Color := DrawVertices[0].Color;
  DrawVertices[4].X := X - 0.5;
  DrawVertices[4].Y := Y - 0.5;
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  if Filled then
    Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLEFAN, 4, @DrawVertices, SizeOf(TScreenVertexGR))
  else
    Direct3DDevice.DrawPrimitiveUP(D3DPT_LINESTRIP, 4, @DrawVertices, SizeOf(TScreenVertexGR));
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

procedure DrawAntialiasedCircle(
    X, Y, Radius: Integer;
    Color: Cardinal;
    Alpha: Integer;
    ClipRect: PRect
);
var
  DX, DY, SX, SY, Quadrant: Integer;
  PreviousCoverage, Coverage: Single;
  PreviousDX: Integer;
begin
  DX := Radius;
  PreviousDX := Radius;
  DY := 0;
  PreviousCoverage := 0;
  Quadrant := 0;
  while Quadrant < 4 do
  begin
    SX := (Quadrant mod 2) * 2 - 1;
    SY := ((Quadrant div 2) mod 2) * 2 - 1;
    QueueDrawPoint(SX * DX + X, SY * DY + Y, Color, Alpha);
    QueueDrawPoint(SX * DY + X, SY * DX + Y, Color, Alpha);
    Inc(Quadrant);
  end;
  while DX > DY do
  begin
    Inc(DY);
    Coverage := Sqrt(Sqr(Radius) - Sqr(DY));
    Coverage := Ceil(Coverage) - Coverage;
    if Coverage < PreviousCoverage then
      Dec(DX);
    if DX < DY then
      Break;
    if (DX = DY) and (PreviousDX = DX) then
      Break;
    Quadrant := 0;
    while Quadrant < 4 do
    begin
      SX := (Quadrant mod 2) * 2 - 1;
      SY := ((Quadrant div 2) mod 2) * 2 - 1;
      QueueDrawPoint(SX * DX + X, SY * DY + Y, Color, Trunc((1 - Coverage) * Alpha));
      QueueDrawPoint(SX * DY + X, SY * DX + Y, Color, Trunc((1 - Coverage) * Alpha));
      if DX - 1 >= DY then
      begin
        QueueDrawPoint((DX - 1) * SX + X, SY * DY + Y, Color, Trunc(Alpha * Coverage));
        QueueDrawPoint(SX * DY + X, (DX - 1) * SY + Y, Color, Trunc(Alpha * Coverage));
      end;
      Inc(Quadrant);
    end;
    PreviousCoverage := Coverage;
    PreviousDX := DX;
  end;
  FlushDrawPoints(ClipRect);
end;

procedure DrawCircle(X, Y, Radius: Integer; Color: Cardinal; Alpha, Mode: Integer; ClipRect: PRect);
var
  Index: Integer;
  Vertices: array[0..4] of TScreenVertexGR;
  OldClip: TRect;
begin
  Index := 0;
  repeat
    Vertices[Index].Color := ColorWithAlpha(Color, Alpha);
    Vertices[Index].X := X;
    Vertices[Index].Y := Y;
    Vertices[Index].Z := 1;
    Vertices[Index].RHW := 1;
    Inc(Index);
  until Index = 5;
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  if Mode = 0 then
    DrawAntialiasedCircle(X, Y, Radius, Color, Alpha, ClipRect)
  else if Mode = 1 then
  begin
    Index := 0;
    repeat
      Vertices[0].X := Radius * CircleCos[Index] + X;
      Vertices[0].Y := Radius * CircleSin[Index] + Y;
      Vertices[1].X := Radius * CircleCos[Index + 1] + X;
      Vertices[1].Y := Radius * CircleSin[Index + 1] + Y;
      Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, 1, @Vertices, SizeOf(TScreenVertexGR));
      Inc(Index);
    until Index = 360;
  end
  else if Mode = 2 then
  begin
    Index := 0;
    repeat
      Vertices[1].X := X + Trunc(Radius * CircleCos[Index + 1]);
      Vertices[1].Y := Y + Trunc(Radius * CircleSin[Index + 1]);
      Vertices[2].X := X + Trunc(Radius * CircleCos[Index]);
      Vertices[2].Y := Y + Trunc(Radius * CircleSin[Index]);
      if Index < 90 then
      begin
        Vertices[0].X := X + Radius;
        Vertices[0].Y := Y + Radius;
      end
      else if Index < 180 then
      begin
        Vertices[0].X := X - Radius;
        Vertices[0].Y := Y + Radius;
      end
      else if Index < 270 then
      begin
        Vertices[0].X := X - Radius;
        Vertices[0].Y := Y - Radius;
      end
      else
      begin
        Vertices[0].X := X + Radius;
        Vertices[0].Y := Y - Radius;
      end;
      Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, 1, @Vertices, SizeOf(TScreenVertexGR));
      Inc(Index);
    until Index = 360;
  end;
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

procedure DrawTexture(
    Texture: IDirect3DTexture9;
    X, Y, Alpha: Integer;
    Color: Cardinal;
    ClipRect: PRect;
    UsePreparedVertices, MirrorHorizontal: Boolean
);
begin
  DrawTextureSized(
      Texture,
      X,
      Y,
      0,
      0,
      Alpha,
      Color,
      ClipRect,
      UsePreparedVertices,
      MirrorHorizontal
  );
end;

procedure DrawTextureSized(
    Texture: IDirect3DTexture9;
    X, Y, Width, Height, Alpha: Integer;
    Color: Cardinal;
    ClipRect: PRect;
    UsePreparedVertices, MirrorHorizontal: Boolean
);
var
  Desc: TD3DSurfaceDesc;
  OldClip: TRect;
begin
  if Texture = nil then
    Exit;
  if not UsePreparedVertices then
  begin
    Texture.GetLevelDesc(0, Desc);
    if Width = 0 then
      Width := Desc.Width;
    if Height = 0 then
      Height := Desc.Height;
    DrawVertices[0].Color := ColorWithAlpha(Color, Alpha);
    DrawVertices[0].X := X - 0.5;
    DrawVertices[0].Y := Y - 0.5;
    DrawVertices[0].U := Integer(MirrorHorizontal);
    DrawVertices[0].V := 0;
    DrawVertices[1].Color := DrawVertices[0].Color;
    DrawVertices[1].X := X + Width - 0.5;
    DrawVertices[1].Y := Y - 0.5;
    DrawVertices[1].U := 1 - Integer(MirrorHorizontal);
    DrawVertices[1].V := 0;
    DrawVertices[2].Color := DrawVertices[0].Color;
    DrawVertices[2].X := X + Width - 0.5;
    DrawVertices[2].Y := Y + Height - 0.5;
    DrawVertices[2].U := 1 - Integer(MirrorHorizontal);
    DrawVertices[2].V := 1;
    DrawVertices[3].Color := DrawVertices[0].Color;
    DrawVertices[3].X := X - 0.5;
    DrawVertices[3].Y := Y + Height - 0.5;
    DrawVertices[3].U := Integer(MirrorHorizontal);
    DrawVertices[3].V := 1;
  end;
  if ClipRect <> nil then
  begin
    Direct3DDevice.GetScissorRect(OldClip);
    Direct3DDevice.SetScissorRect(ClipRect);
  end;
  Direct3DDevice.SetTexture(0, Texture);
  Direct3DDevice.DrawPrimitiveUP(D3DPT_TRIANGLEFAN, 2, @DrawVertices, SizeOf(TScreenVertexGR));
  Direct3DDevice.SetTexture(0, nil);
  if ClipRect <> nil then
    Direct3DDevice.SetScissorRect(@OldClip);
end;

function Color565ToArgb(Color: Cardinal): Cardinal;
begin
  Result :=
      ((Color shl 3) and $F8)
          or (((Color shr 3) and $FC) shl 8)
          or (((Color shr 8) and $F8) shl 16)
          or $FF000000;
end;

function ColorWithAlpha(Color, Alpha: Cardinal): Cardinal;
begin
  Result := (Color and $FFFFFF) or ((Alpha and $FF) shl 24);
end;

function GetTextureByteSize(Texture: IDirect3DTexture9): Cardinal;
var
  ByteCount: Cardinal;
  Desc: TD3DSurfaceDesc;
begin
  ByteCount := 0;
  if Texture <> nil then
  begin
    Texture.GetLevelDesc(0, Desc);
    if (Desc.Format = D3DFMT_A8R8G8B8) or (Desc.Format = D3DFMT_A8R8G8B8) then
      ByteCount := 4
    else if Desc.Format = D3DFMT_R8G8B8 then
      ByteCount := 3
    else if Desc.Format = D3DFMT_R5G6B5 then
      ByteCount := 2
    else if Desc.Format = D3DFMT_A8 then
      ByteCount := 1;
    ByteCount := Desc.Width * Desc.Height * ByteCount;
  end;
  Result := ByteCount;
end;

procedure AddResidentTextureBytes(ByteCount: Cardinal);
begin
  Inc(ResidentTextureBytes, ByteCount);
end;

procedure SubtractResidentTextureBytes(ByteCount: Cardinal);
begin
  if ResidentTextureBytes > ByteCount then
  begin
    Dec(ResidentTextureBytes, ByteCount);
    Exit;
  end;
  ResidentTextureBytes := 0;
end;

procedure LinkRecoveredTypes;
begin
  TTextureGR.ClassName;
end;
end.
