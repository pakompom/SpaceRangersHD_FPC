{$EXCESSPRECISION OFF}
unit SE_Ship2;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_AlphaImage,
  GI_MessageLoop,
  GI_RotateImage5,
  GI_Tail,
  SE_Space,
  Types;
type
  TShip2AnimSE = class;
  TShip2SE = class;
  TShip2AnimSE = class(TObject)
    Prev: TShip2AnimSE;
    Next: TShip2AnimSE;
    Weight: Integer;
    FrameCount: Integer;
    Frames: array of Word;
    Delays: array of Word;
    destructor Destroy; override;
    procedure Clear;
    procedure Load(Specification: WideString);
  end;
  TShip2SE = class(TObjectSE)
    ImageSize: TPoint;
    ImageScale: TPointF;
    ImageOrigin: TPoint;
    ImageCenter: TPointF;
    Angle: Byte;
    Alpha: Byte;
    AlphaLimit: Byte;
    Gap6F: array[0..0] of Byte;
    MinimapImagePath: WideString;
    AlternateImagePath: WideString;
    MinimapImageOrigin: TPoint;
    StateIntervalMs: Integer;
    ImagePath: WideString;
    ReducedImagePath: WideString;
    TailOrigins: array[1..10] of TPointF;
    TailEmitIntervalMs: Cardinal;
    Image: TRotateImage5GI;
    MinimapImage: TAlphaImageGI;
    Tails: array[1..10] of TTailGI;
    TailPrefix: WideString;
    WeaponPortCount: Cardinal;
    WeaponPorts: array[1..10] of TPointF;
    SharedAnimations: Boolean;
    Gap169: array[0..2] of Byte;
    FirstAnimation: TShip2AnimSE;
    LastAnimation: TShip2AnimSE;
    FirstReducedAnimation: TShip2AnimSE;
    LastReducedAnimation: TShip2AnimSE;
    CurrentAnimation: TShip2AnimSE;
    NextAnimation: TShip2AnimSE;
    DefaultAnimation: TShip2AnimSE;
    DefaultReducedAnimation: TShip2AnimSE;
    CurrentFrameIndex: Integer;
    AnimationTimer: PCallbackTimerGI;
    StateTimer: PCallbackTimerGI;
    TotalAnimationWeight: PtrInt;
    TotalReducedAnimationWeight: Integer;
    TailMode: Integer;
    PanelPartnerImage: WideString;
    SmallSize: Integer;
    LargeSize: Integer;
    TargetSizeScale: Single;
    AngleOverride: Integer;
    procedure CopyTo(Destination: TObjectSE); override;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure SetDepth(Value: Single); override;
    function GetDepth: Single; override;
    function GetOrbitCenter: TPointF; override;
    function GetAlpha: Byte; override;
    procedure SetAlpha(Value: Byte); override;
    function GetAngle: Byte; override;
    procedure SetAngle(Value: Byte); override;
    procedure SetSize(Value: TPoint); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    constructor CreateEmpty;
    constructor Create(const GraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    procedure CopyDataFromMirrorImage(Destination: TObjectSE);
    procedure SetTailMode(Value: Integer);
    function GetImagePath: WideString;
    procedure SetTailDepth(Value: Single);
    procedure OffsetTailsAlongHeading(Distance: Single);
    procedure OffsetTails(Delta: TPointF);
    procedure SetTailsEmitting(Value: Boolean);
    function ScaleImagePoint(Point: TPointF): TPointF;
    function ImagePointToWorld(Point: TPointF): TPointF;
    function GetTargetPoint(Heading: Byte; Seed: Integer): TPointF;
    function GetWeaponPortPoint(Heading: Byte; Seed: Cardinal): TPointF;
    function AddAnimation: TShip2AnimSE;
    procedure DeleteAnimation(Animation: TShip2AnimSE);
    function AddReducedAnimation: TShip2AnimSE;
    procedure DeleteReducedAnimation(Animation: TShip2AnimSE);
    procedure StartAnimationTimer;
    procedure StopAnimationTimer;
    procedure StartStateTimer;
    procedure StopStateTimer;
    procedure AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure SelectNextAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  ObserverHooks,
  Math,
  SysUtils,
  aMyFunction,
  aPlayer,
  EC_Str,
  GI_Main,
  Globals,
  GlobalsV,
  GR_Main,
  SE_Process;

destructor TShip2AnimSE.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TShip2AnimSE.Clear;
begin
  if Frames <> nil then
    Frames := nil;
  if Delays <> nil then
    Delays := nil;
  Weight := 1;
  FrameCount := 0;
end;

procedure TShip2AnimSE.Load(Specification: WideString);
var
  Index, RangeCount, FrameOffset, Count, Delay, First, Last: Integer;
  RangeText: WideString;
begin
  Clear;
  Index := CountDelimitedPartsW(Specification, ',');
  if Index < 3 then
    raise Exception.Create('Error in TShip2AnimSE.Load');
  Weight := ExtractDigitsToIntW(ExtractDelimitedPartW(Specification, 0, ','));
  Specification := ExtractDelimitedRangeW(Specification, 1, Index - 1, ',');
  RangeCount := (CountDelimitedPartsW(Specification, '[]') - 1) div 2;
  for Index := 0 to RangeCount - 1 do
  begin
    RangeText := ExtractDelimitedPartW(Specification, Index * 2 + 1, '[]');
    Delay := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 0, ',-'));
    First := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 1, ',-'));
    Last := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 2, ',-'));
    Count := Abs(First - Last) + 1;
    Inc(FrameCount, Count);
    SetLength(Frames, FrameCount);
    SetLength(Delays, FrameCount);
    for FrameOffset := 0 to Count - 1 do
    begin
      Frames[FrameCount - Count + FrameOffset] := First;
      Delays[FrameCount - Count + FrameOffset] := Delay;
      if First < Last then
        Inc(First)
      else
        Dec(First);
    end;
  end;
end;

constructor TShip2SE.CreateEmpty;
begin
  inherited CreateEmpty;
  AlphaLimit := 255;
  AngleOverride := -1;
end;

constructor TShip2SE.Create(const GraphKey: WideString; UnusedPosition: TPoint);
begin
  AngleOverride := -1;
  if CountDelimitedPartsW(GraphKey, ',') > 1 then
  begin
    inherited Create(ExtractDelimitedPartW(GraphKey, 0, ','), UnusedPosition);
    AlphaLimit := ExtractDigitsToIntW(ExtractDelimitedPartW(GraphKey, 1, ','));
  end
  else
  begin
    inherited Create(GraphKey, UnusedPosition);
    AlphaLimit := 255;
  end;
end;

destructor TShip2SE.Destroy;
begin
  StopStateTimer;
  StopAnimationTimer;
  CurrentAnimation := nil;
  NextAnimation := nil;
  if not SharedAnimations then
  begin
    while FirstAnimation <> nil do
      DeleteAnimation(LastAnimation);
    while FirstReducedAnimation <> nil do
      DeleteReducedAnimation(LastReducedAnimation);
  end;
  SharedAnimations := False;
  inherited Destroy;
end;

procedure TShip2SE.CopyTo(Destination: TObjectSE);
var
  Ship: TShip2SE;
  Index: Integer;
begin
  inherited CopyTo(Destination);
  Ship := Destination as TShip2SE;
  Ship.ImagePath := ImagePath;
  Ship.ReducedImagePath := ReducedImagePath;
  Ship.ImageSize := ImageSize;
  Ship.ImageScale := ImageScale;
  Ship.ImageOrigin := ImageOrigin;
  Ship.ImageCenter := ImageCenter;
  Ship.Angle := Angle;
  Ship.Alpha := Alpha;
  Ship.AlphaLimit := AlphaLimit;
  Ship.MinimapImagePath := MinimapImagePath;
  Ship.MinimapImageOrigin := MinimapImageOrigin;
  Ship.StateIntervalMs := StateIntervalMs;
  Ship.SharedAnimations := True;
  Ship.FirstAnimation := FirstAnimation;
  Ship.LastAnimation := LastAnimation;
  Ship.DefaultAnimation := DefaultAnimation;
  Ship.FirstReducedAnimation := FirstReducedAnimation;
  Ship.LastReducedAnimation := LastReducedAnimation;
  Ship.DefaultReducedAnimation := DefaultReducedAnimation;
  Ship.TotalAnimationWeight := TotalAnimationWeight;
  Ship.TotalReducedAnimationWeight := TotalReducedAnimationWeight;
  for Index := Low(TailOrigins) to High(TailOrigins) do
    Ship.TailOrigins[Index] := TailOrigins[Index];
  Ship.TailPrefix := TailPrefix;
  Ship.WeaponPortCount := WeaponPortCount;
  for Index := Low(WeaponPorts) to High(WeaponPorts) do
    Ship.WeaponPorts[Index] := WeaponPorts[Index];
  Ship.SmallSize := SmallSize;
  Ship.LargeSize := LargeSize;
  Ship.TargetSizeScale := TargetSizeScale;
end;

procedure TShip2SE.CopyDataFromMirrorImage(Destination: TObjectSE);
var
  Ship: TShip2SE;
  SourceAnimation, DestinationAnimation: TShip2AnimSE;
  Index: Integer;
begin
  Ship := Destination as TShip2SE;
  Ship.GraphKey := GraphKey;
  if (Ship.ImagePath <> ImagePath) or (Ship.ReducedImagePath <> ReducedImagePath) then
  begin
    AppendLogLineThreadSafe('Warning from CopyDataFromMirrorImage: image mismatch');
    Ship.ImagePath := ImagePath;
    Ship.ReducedImagePath := ReducedImagePath;
  end;
  Ship.MinimapImagePath := MinimapImagePath;
  SourceAnimation := FirstAnimation;
  DestinationAnimation := Ship.FirstAnimation;
  while (SourceAnimation <> nil) and (DestinationAnimation <> nil) do
  begin
    if DefaultAnimation = SourceAnimation then
      Ship.DefaultAnimation := DestinationAnimation;
    DestinationAnimation.Weight := SourceAnimation.Weight;
    DestinationAnimation := DestinationAnimation.Next;
    SourceAnimation := SourceAnimation.Next;
  end;
  if (SourceAnimation <> nil) or (DestinationAnimation <> nil) then
    AppendLogLineThreadSafe('Warning from CopyDataFromMirrorImage: animation mismatch');
  SourceAnimation := FirstReducedAnimation;
  DestinationAnimation := Ship.FirstReducedAnimation;
  while (SourceAnimation <> nil) and (DestinationAnimation <> nil) do
  begin
    if DefaultReducedAnimation = SourceAnimation then
      Ship.DefaultReducedAnimation := DestinationAnimation;
    DestinationAnimation.Weight := SourceAnimation.Weight;
    DestinationAnimation := DestinationAnimation.Next;
    SourceAnimation := SourceAnimation.Next;
  end;
  if (SourceAnimation <> nil) or (DestinationAnimation <> nil) then
    AppendLogLineThreadSafe('Warning from CopyDataFromMirrorImage: animation mismatch');
  Ship.TotalAnimationWeight := TotalAnimationWeight;
  Ship.TotalReducedAnimationWeight := TotalReducedAnimationWeight;
  for Index := Low(TailOrigins) to High(TailOrigins) do
    Ship.TailOrigins[Index] := TailOrigins[Index];
  Ship.TailPrefix := TailPrefix;
  Ship.WeaponPortCount := WeaponPortCount;
  for Index := Low(WeaponPorts) to High(WeaponPorts) do
    Ship.WeaponPorts[Index] := WeaponPorts[Index];
  Ship.SmallSize := SmallSize;
  Ship.LargeSize := LargeSize;
  Ship.TargetSizeScale := TargetSizeScale;
end;

procedure TShip2SE.AttachToSpace(ASpace: TSpaceSE);
var
  Index, Stage: Integer;
begin
  Stage := 0;
  try
    if IsAttachedToSpace then
      Exit;
    ConfigureLoopSound('Ship');
    ConfigureRandomSound('Ship');
    Stage := 1;
    inherited AttachToSpace(ASpace);
    Stage := 2;
    Image := TRotateImage5GI.Create(nil);
    Stage := 3;
    if Space.MapPanel <> nil then
      Space.MapPanel.AttachOwnedChild(Image);
    Stage := 4;
    Image.SetPositionModeW(True);
    Image.SetDepthByName(DepthExpression);
    Image.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
    if AngleOverride >= 0 then
      Image.SetAngle(AngleOverride)
    else
      Image.SetAngle(Angle);
    Image.SetAlpha(Math.Min(Alpha, AlphaLimit) shr ASpace.AlphaShift);
    Stage := 5;
    MinimapImage := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    Stage := 6;
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(
        TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
    );
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.GetContentSize));
    Stage := 7;
    if AnimShipFull then
      CurrentAnimation := FirstAnimation
    else
      CurrentAnimation := FirstReducedAnimation;
    NextAnimation := CurrentAnimation;
    CurrentFrameIndex := RandomIntRange(0, CurrentAnimation.FrameCount - 1);
    Stage := 8;
    if AnimShipFull then
      Image.SetImage(ImagePath, Size, RoundPointF(GetOrbitCenter))
    else
      Image.SetImage(ReducedImagePath, Size, RoundPointF(GetOrbitCenter));
    Image.SetFrameIndex(CurrentAnimation.Frames[CurrentFrameIndex]);
    Stage := 9;
    if TailMode > 0 then
      for Index := Low(TailOrigins) to High(TailOrigins) do
        if TailOrigins[Index].Y > 0 then
        begin
          Tails[Index] := TTailGI.Create(Space.MapPanel);
          if TailEmitIntervalMs > 0 then
            Tails[Index].EmitIntervalMs := TailEmitIntervalMs;
          Tails[Index].SetSize(Classes.Point(1000000, 1000000));
          Tails[Index].SetOrigin(HalfPoint(Tails[Index].ClientSize));
          Tails[Index].SetDepthByName('Tail');
          Tails[Index].SetPositionModeW(True);
          Tails[Index].SetImagePath('Bm.Tail.' + TailPrefix + '0' + IntToStr(TailMode - 1));
          Tails[Index].SetEmitting((Alpha = 255) and (Space.AlphaShift = 0));
        end;
    Stage := 10;
    StartAnimationTimer;
    StartStateTimer;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      AppendLogLineThreadSafe('TShip2SE.Connect');
      AppendLogLineThreadSafe(GraphKey);
      AppendLogLineThreadSafe('lastLabel=' + IntToWideString(RotateImageConstructionStage));
      AppendLogLineThreadSafe('self=' + UIntToStr(PtrUInt(Self)));
      AppendLogLineThreadSafe('sp=' + UIntToStr(PtrUInt(ASpace)));
      AppendLogLineThreadSafe('FSpace=' + UIntToStr(PtrUInt(Space)));
      AppendLogLineThreadSafe('FImage=' + UIntToStr(PtrUInt(Image)));
      if Space <> nil then
        AppendLogLineThreadSafe('PGI=' + UIntToStr(PtrUInt(Space.MapPanel)));
      raise Exception.Create('Error in procedure TShip2SE.Connect, label = ' + IntToStr(Stage));
    end;
  end;
end;

procedure TShip2SE.DetachFromSpace;
var
  Index: Integer;
begin
  if IsAttachedToSpace then
  begin
    StopStateTimer;
    StopAnimationTimer;
    CurrentAnimation := nil;
    NextAnimation := nil;
    Image.SetActive(False);
    Image.Free;
    Image := nil;
    MinimapImage.Free;
    MinimapImage := nil;
    for Index := Low(Tails) to High(Tails) do
      if Tails[Index] <> nil then
      begin
        Tails[Index].Free;
        Tails[Index] := nil;
      end;
    inherited DetachFromSpace;
  end;
end;

procedure TShip2SE.SetTailMode(Value: Integer);
var
  Index: Integer;
begin
  TailMode := Value;
  for Index := Low(Tails) to High(Tails) do
    if Tails[Index] <> nil then
    begin
      Tails[Index].SetActive(Value > 0);
      if Value > 0 then
      begin
        if TailMode = 1 then
          if Tails[Index].GetImagePath <> 'Bm.Tail.' + TailPrefix + '00' then
          begin
            Tails[Index].SetImagePath('Bm.Tail.' + TailPrefix + '00');
            Tails[Index].SetEmitting((Alpha = 255) and (Space.AlphaShift = 0));
            Continue;
          end;
        if TailMode = 2 then
          if Tails[Index].GetImagePath <> 'Bm.Tail.' + TailPrefix + '01' then
          begin
            Tails[Index].SetImagePath('Bm.Tail.' + TailPrefix + '01');
            Tails[Index].SetEmitting((Alpha = 255) and (Space.AlphaShift = 0));
          end;
      end;
    end;
end;

function TShip2SE.GetImagePath: WideString;
begin
  if AnimShipFull then
    Result := ImagePath
  else
    Result := ReducedImagePath;
end;

procedure TShip2SE.SetSize(Value: TPoint);
begin
  if (Size.X <> Value.X) or (Size.Y <> Value.Y) then
  begin
    inherited SetSize(Value);
    ImageScale.X := Size.X / ImageSize.X;
    ImageScale.Y := Size.Y / ImageSize.Y;
  end;
end;

procedure TShip2SE.SetPosition(APosition: TPointF);
var
  PixelPosition: TPoint;
  Index: Integer;
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    PixelPosition := Classes.Point(Trunc(APosition.X), Trunc(APosition.Y));
    Image.SetPosition(PixelPosition);
    MinimapImage.SetPosition(
        TruncatePointF(
            MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
        )
    );
    for Index := Low(Tails) to High(Tails) do
      if Tails[Index] <> nil then
        Tails[Index].EmitterPosition := ImagePointToWorld(TailOrigins[Index]);
  end;
end;

procedure TShip2SE.SetTailDepth(Value: Single);
var
  Index: Integer;
begin
  if TailMode > 0 then
    for Index := Low(Tails) to High(Tails) do
    begin
      if Tails[Index] = nil then
        Break;
      Tails[Index].SetDepth(Value);
    end;
end;

procedure TShip2SE.SetDepth(Value: Single);
begin
  Image.SetDepth(Value);
end;

function TShip2SE.GetDepth: Single;
begin
  Result := Image.Depth;
end;

function TShip2SE.GetAngle: Byte;
begin
  Result := Angle;
end;

procedure TShip2SE.SetAngle(Value: Byte);
var
  Index: Integer;
  Velocity: TPointF;
begin
  Angle := Value;
  if IsAttachedToSpace then
  begin
    if AngleOverride >= 0 then
      Image.SetAngle(AngleOverride)
    else
      Image.SetAngle(Angle);
    Velocity.X := 0;
    Velocity.Y := 0;
    for Index := Low(Tails) to High(Tails) do
      if Tails[Index] <> nil then
      begin
        Tails[Index].EmitterPosition := ImagePointToWorld(TailOrigins[Index]);
        Tails[Index].SegmentVelocity := Velocity;
      end;
  end;
end;

procedure TShip2SE.OffsetTailsAlongHeading(Distance: Single);
var
  Radians: Single;
  Delta: TPointF;
  Index: Integer;
begin
  if IsAttachedToSpace then
  begin
    Radians := GetAngle / 256 * (2 * Pi) + Pi;
    Delta.X := Sin(Radians) * Distance;
    Delta.Y := Cos(Radians) * -Distance;
    for Index := Low(Tails) to High(Tails) do
      if Tails[Index] <> nil then
        Tails[Index].OffsetSegments(Delta);
  end;
end;

procedure TShip2SE.OffsetTails(Delta: TPointF);
var
  Index: Integer;
begin
  for Index := Low(Tails) to High(Tails) do
    if Tails[Index] <> nil then
      Tails[Index].OffsetSegments(Delta);
end;

procedure TShip2SE.SetTailsEmitting(Value: Boolean);
var
  Index: Integer;
begin
  for Index := Low(Tails) to High(Tails) do
    if Tails[Index] <> nil then
      Tails[Index].SetEmitting(Value);
end;

function TShip2SE.GetAlpha: Byte;
begin
  Result := Alpha;
end;

procedure TShip2SE.SetAlpha(Value: Byte);
var
  Index: Integer;
begin
  Alpha := Value;
  if IsAttachedToSpace then
  begin
    Image.SetAlpha(Math.Min(Alpha, AlphaLimit) shr Space.AlphaShift);
    for Index := Low(Tails) to High(Tails) do
      if Tails[Index] <> nil then
        Tails[Index].SetEmitting((Alpha = 255) and (Space.AlphaShift = 0));
  end;
end;

function TShip2SE.GetOrbitCenter: TPointF;
begin
  Result.X := ImageOrigin.X * ImageScale.X;
  Result.Y := ImageOrigin.Y * ImageScale.Y;
end;

function TShip2SE.ScaleImagePoint(Point: TPointF): TPointF;
begin
  Result.X := (Point.X - ImageOrigin.X) * ImageScale.X;
  Result.Y := (Point.Y - ImageOrigin.Y) * ImageScale.Y;
end;

function TShip2SE.ImagePointToWorld(Point: TPointF): TPointF;
var
  Radians, Sine, Cosine: Double;
begin
  Point := ScaleImagePoint(Point);
  Radians := Angle / 256 * 6.2831852;
  Sine := Sin(Radians);
  Cosine := Cos(Radians);
  Result.X := Point.X * Cosine - Point.Y * Sine + Position.X;
  Result.Y := Point.X * Sine + Point.Y * Cosine + Position.Y;
end;

function TShip2SE.GetTargetPoint(Heading: Byte; Seed: Integer): TPointF;
var
  Radians, Sine, Cosine: Double;
  Point: TPointF;
begin
  Point := ScaleImagePoint(MakePointF(Seed mod ImageSize.X, (Seed * 45452 + 3247) mod ImageSize.Y));
  Point.X := Point.X * TargetSizeScale;
  Point.Y := Point.Y * TargetSizeScale;
  Radians := Heading / 256 * 6.2831852;
  Sine := Sin(Radians);
  Cosine := Cos(Radians);
  Result.X := Point.X * Cosine - Point.Y * Sine + Position.X;
  Result.Y := Point.X * Sine + Point.Y * Cosine + Position.Y;
end;

function TShip2SE.GetWeaponPortPoint(Heading: Byte; Seed: Cardinal): TPointF;
var
  Radians, Sine, Cosine: Double;
  Point: TPointF;
begin
  if WeaponPortCount < 1 then
  begin
    Result := Position;
    Exit;
  end;
  Point := ScaleImagePoint(WeaponPorts[1 + (Sqr(Seed) div 11) mod WeaponPortCount]);
  Radians := Heading / 256 * 6.2831852;
  Sine := Sin(Radians);
  Cosine := Cos(Radians);
  Result.X := Point.X * Cosine - Point.Y * Sine + Position.X;
  Result.Y := Point.X * Sine + Point.Y * Cosine + Position.Y;
end;

function TShip2SE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Image.HitTestPixel(Image.MessageLoop.GetCursorPoint);
end;

function TShip2SE.AddAnimation: TShip2AnimSE;
var
  Animation: TShip2AnimSE;
begin
  Animation := TShip2AnimSE.Create;
  if LastAnimation <> nil then
    LastAnimation.Next := Animation;
  Animation.Prev := LastAnimation;
  Animation.Next := nil;
  LastAnimation := Animation;
  if FirstAnimation = nil then
    FirstAnimation := Animation;
  Result := Animation;
end;

procedure TShip2SE.DeleteAnimation(Animation: TShip2AnimSE);
begin
  if Animation.Prev <> nil then
    Animation.Prev.Next := Animation.Next;
  if Animation.Next <> nil then
    Animation.Next.Prev := Animation.Prev;
  if LastAnimation = Animation then
    LastAnimation := Animation.Prev;
  if FirstAnimation = Animation then
    FirstAnimation := Animation.Next;
  Animation.Free;
end;

function TShip2SE.AddReducedAnimation: TShip2AnimSE;
var
  Animation: TShip2AnimSE;
begin
  Animation := TShip2AnimSE.Create;
  if LastReducedAnimation <> nil then
    LastReducedAnimation.Next := Animation;
  Animation.Prev := LastReducedAnimation;
  Animation.Next := nil;
  LastReducedAnimation := Animation;
  if FirstReducedAnimation = nil then
    FirstReducedAnimation := Animation;
  Result := Animation;
end;

procedure TShip2SE.DeleteReducedAnimation(Animation: TShip2AnimSE);
begin
  if Animation.Prev <> nil then
    Animation.Prev.Next := Animation.Next;
  if Animation.Next <> nil then
    Animation.Next.Prev := Animation.Prev;
  if LastReducedAnimation = Animation then
    LastReducedAnimation := Animation.Prev;
  if FirstReducedAnimation = Animation then
    FirstReducedAnimation := Animation.Next;
  Animation.Free;
end;

procedure TShip2SE.StartAnimationTimer;
var
  Delay: Integer;
begin
  StopAnimationTimer;
  Delay := CurrentAnimation.Delays[CurrentFrameIndex];
  AnimationTimer := Space.Screen.ScheduleCallbackTimer(Delay, Delay, AdvanceAnimation);
end;

procedure TShip2SE.StopAnimationTimer;
begin
  if AnimationTimer <> nil then
  begin
    Space.Screen.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
end;

procedure TShip2SE.StartStateTimer;
begin
  StopStateTimer;
  SelectNextAnimation(nil, 0);
  StateTimer :=
      Space.Screen.ScheduleCallbackTimer(StateIntervalMs, StateIntervalMs, SelectNextAnimation);
end;

procedure TShip2SE.StopStateTimer;
begin
  if StateTimer <> nil then
  begin
    Space.Screen.CancelCallbackTimer(StateTimer);
    StateTimer := nil;
  end;
end;

procedure TShip2SE.AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  with Image.HitTestBounds do
    if (Cardinal(GameScreenWidth) * -0.1 > Right)
        or (Cardinal(GameScreenWidth) * 1.1 < Left)
        or (Cardinal(GameScreenHeight) * -0.1 > Bottom)
        or (Cardinal(GameScreenHeight) * 1.1 < Top) then
    begin
      SetTailsEmitting(False);
      Exit;
    end;
  SetTailsEmitting(True);
  Inc(CurrentFrameIndex);
  if CurrentAnimation.FrameCount > CurrentFrameIndex then
  begin
    Image.SetFrameIndex(CurrentAnimation.Frames[CurrentFrameIndex]);
    StartAnimationTimer;
    Exit;
  end;
  CurrentFrameIndex := 0;
  if AnimShipFull then
  begin
    if CurrentAnimation = LastAnimation then
      CurrentAnimation := DefaultAnimation
    else
      CurrentAnimation := NextAnimation;
    NextAnimation := DefaultAnimation;
  end
  else
  begin
    if CurrentAnimation = LastReducedAnimation then
      CurrentAnimation := DefaultReducedAnimation
    else
      CurrentAnimation := NextAnimation;
    NextAnimation := DefaultReducedAnimation;
  end;
  Image.SetFrameIndex(CurrentAnimation.Frames[CurrentFrameIndex]);
  StartAnimationTimer;
end;

procedure TShip2SE.SelectNextAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Weight: Integer;
  Animation: TShip2AnimSE;
begin
  if AnimShipFull then
  begin
    if NextAnimation = LastAnimation then
      Exit;
    Weight := PresentationRandom(TotalAnimationWeight);
    Animation := FirstAnimation;
    while Animation <> nil do
    begin
      if Weight < Animation.Weight then
      begin
        NextAnimation := Animation;
        Break;
      end;
      Dec(Weight, Animation.Weight);
      Animation := Animation.Next;
    end;
  end
  else
  begin
    if NextAnimation = LastReducedAnimation then
      Exit;
    Weight := PresentationRandom(TotalReducedAnimationWeight);
    Animation := FirstReducedAnimation;
    while Animation <> nil do
    begin
      if Weight < Animation.Weight then
      begin
        NextAnimation := Animation;
        Break;
      end;
      Dec(Weight, Animation.Weight);
      Animation := Animation.Next;
    end;
  end;
end;

procedure TShip2SE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if (PointDistanceSquared(Position, CurrentProcess.RadarCenter) < Sqr(CurrentProcess.RadarRange))
      or ((AlternateImagePath <> '') and (CurrentProcess.RadarRange > 0))
      or ((GetPlayer <> nil) and (GetPlayer.Graphic = Self)) then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

procedure TShip2SE.LoadTemplate(Block: TBlockParEC);
var
  AnimBlock: TBlockParEC;
  Index: Integer;
  Normal, Animation, ReducedNormal, ReducedAnimation: TShip2AnimSE;
begin
  inherited LoadTemplate(Block);
  SharedAnimations := False;
  if Block.CountParams('AngleOverride') > 0 then
    AngleOverride := ExtractDigitsToIntW(Block.GetParam('AngleOverride'))
  else
    AngleOverride := -1;
  SetAngle(0);
  SetAlpha(255);
  ImagePath := Block.GetParam('Image');
  ReducedImagePath := Block.GetParam('ImageS');
  MinimapImagePath := Block.GetParam('ImageMap');
  if Block.CountParams('ImageI') > 0 then
    AlternateImagePath := Block.GetParam('ImageI')
  else
    AlternateImagePath := '';
  if Block.CountParams('PanelPartnerImage') > 0 then
    PanelPartnerImage := Block.GetParam('PanelPartnerImage')
  else
    PanelPartnerImage := '';
  ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
  MinimapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
  ImageSize := GetPointGI(Block.GetParam('SizeImage'));
  ImageCenter := PointToPointF(GetPointGI(Block.GetParam('SmeCenterImage')));
  for Index := Low(TailOrigins) to High(TailOrigins) do
  begin
    TailOrigins[Index] := MakePointF(0, 0);
    if Block.CountParams('Tail' + IntToWideString(Index)) > 0 then
      TailOrigins[Index] :=
          PointToPointF(GetPointGI(Block.GetParam('Tail' + IntToWideString(Index))));
  end;
  if Block.CountParams('TailPrefix') > 0 then
    TailPrefix := Block.GetParam('TailPrefix')
  else
    TailPrefix := '';
  WeaponPortCount := 0;
  for Index := Low(WeaponPorts) to High(WeaponPorts) do
  begin
    if Block.CountParams('WeaponPort' + IntToWideString(Index)) <= 0 then
      Break;
    WeaponPorts[Index] :=
        PointToPointF(GetPointGI(Block.GetParam('WeaponPort' + IntToWideString(Index))));
    Inc(WeaponPortCount);
  end;
  StateIntervalMs := StrToInt(Block.GetParam('StateTime'));
  AnimBlock := Block.GetBlock('Anim');
  Normal := AddAnimation;
  Normal.Load(AnimBlock.GetParam('Normal'));
  TotalAnimationWeight := Normal.Weight;
  DefaultAnimation := LastAnimation;
  Index := 0;
  while AnimBlock.CountParams(IntToStr(Index)) > 0 do
  begin
    Animation := AddAnimation;
    Animation.Load(AnimBlock.GetParam(IntToStr(Index)));
    Inc(TotalAnimationWeight, Animation.Weight);
    if LastAnimation.Weight > DefaultAnimation.Weight then
      DefaultAnimation := LastAnimation;
    Inc(Index);
  end;
  AnimBlock := Block.GetBlock('AnimS');
  ReducedNormal := AddReducedAnimation;
  ReducedNormal.Load(AnimBlock.GetParam('Normal'));
  TotalReducedAnimationWeight := ReducedNormal.Weight;
  DefaultReducedAnimation := LastReducedAnimation;
  Index := 0;
  while AnimBlock.CountParams(IntToStr(Index)) > 0 do
  begin
    ReducedAnimation := AddReducedAnimation;
    ReducedAnimation.Load(AnimBlock.GetParam(IntToStr(Index)));
    Inc(TotalReducedAnimationWeight, ReducedAnimation.Weight);
    if LastReducedAnimation.Weight > DefaultReducedAnimation.Weight then
      DefaultReducedAnimation := LastReducedAnimation;
    Inc(Index);
  end;
  if Block.CountParams('SizeSmall') > 0 then
    SmallSize := ExtractDigitsToIntW(Block.GetParam('SizeSmall'))
  else
    SmallSize := 0;
  if Block.CountParams('SizeLarge') > 0 then
    LargeSize := ExtractDigitsToIntW(Block.GetParam('SizeLarge'))
  else
    LargeSize := 0;
  if Block.CountParams('TargetSizeK') > 0 then
    TargetSizeScale := ExtractDecimalToSingleW(Block.GetParam('TargetSizeK'))
  else
    TargetSizeScale := 0.3;
  SetSize(Classes.Point(64, 64));
end;

procedure TShip2SE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('Angle') > 0 then
    SetAngle(StrToInt(Block.GetParam('Angle')));
end;

procedure TShip2SE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  MainImage: TRotateImage5GI;
  MapImage: TAlphaImageGI;
begin
  MainImage := TRotateImage5GI.Create(Owner);
  if AnimShipFull then
    MainImage.QueueImagePath(PendingLoads, ImagePath)
  else
    MainImage.QueueImagePath(PendingLoads, ReducedImagePath);
  MainImage.Free;
  MapImage := TAlphaImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;

procedure LinkRecoveredTypes;
begin
  TProcessSE.ClassName;
  TShip2SE.ClassName;
end;
end.
