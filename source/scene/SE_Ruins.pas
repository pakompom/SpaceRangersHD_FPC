{$EXCESSPRECISION OFF}
unit SE_Ruins;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_GAI,
  GI_Image,
  GI_MessageLoop,
  SE_Space,
  Types;
type
  TRuinsSE = class;
  TRuinsSE = class(TObjectSE)
    ImagePath: WideString;
    StaticImagePath: WideString;
    MinimapImagePath: WideString;
    Animation: TgaiGI;
    StaticImage: TImageGI;
    MinimapImage: TImageGI;
    FrameIndex: Integer;
    Alpha: Byte;
    AlphaLimit: Byte;
    Gap6A: array[0..1] of Byte;
    WeaponPortCount: Cardinal;
    WeaponPorts: array[1..10] of TPointF;
    HasTransitionImages: Boolean;
    GapC1: array[0..2] of Byte;
    State: Integer;
    FadeTimer: PCallbackTimerGI;
    KeepSize: Boolean;
    GapCD: array[0..2] of Byte;
    PanelPartnerImage: WideString;
    HideOnStarInfo: Boolean;
    GapD5: array[0..2] of Byte;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure SetDepth(Value: Single); override;
    function GetDepth: Single; override;
    function GetAlpha: Byte; override;
    procedure SetAlpha(Value: Byte); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    constructor Create(GraphKey: WideString; UnusedPosition: TPoint);
    procedure SetState(Value: Integer);
    procedure AnimationCycleComplete(Sender: TObjectGI);
    procedure AdvanceFade(Timer: PCallbackTimerGI; UserData: PtrInt);
    function GetWeaponPortPoint(Seed: Cardinal): TPointF;
  end;
procedure LinkRecoveredTypes;
implementation
uses
  ObserverHooks,
  Math,
  SysUtils,
  EC_Str,
  Globals,
  GlobalsV,
  GR_Main,
  SE_Process;

constructor TRuinsSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
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
  HasTransitionImages :=
      CacheDataRoot.FileExistsByPath(ImagePath + 'To')
          and CacheDataRoot.FileExistsByPath(ImagePath + 'From');
  State := 0;
  Alpha := 255;
end;

procedure TRuinsSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    ConfigureLoopSound(
        'Ruins.' + ExtractDelimitedPartW(ImagePath, CountDelimitedPartsW(ImagePath, '.') - 1, '.')
    );
    ConfigureRandomSound(
        'Ruins.' + ExtractDelimitedPartW(ImagePath, CountDelimitedPartsW(ImagePath, '.') - 1, '.')
    );
    inherited AttachToSpace(ASpace);
    if AnimShipFull or (CurrentScreenId = screenArcadeBattle) then
    begin
      Animation := TgaiGI.Create(Space.MapPanel);
      if State = 3 then
      begin
        Animation.SetImagePath(ImagePath + 'From');
        Animation.CycleCompleteCallback := AnimationCycleComplete;
        FrameIndex := 0;
      end
      else if State = 2 then
      begin
        Animation.SetImagePath(ImagePath + 'To');
        Animation.CycleCompleteCallback := AnimationCycleComplete;
        State := 4;
        FrameIndex := 0;
      end
      else
        Animation.SetImagePath(ImagePath);
      Animation.SetSize(Animation.GetContentSize);
      Animation.SetOrigin(HalfPoint(Animation.ClientSize));
      Animation.SetDepthByName(DepthExpression);
      Animation.SetPosition(TruncatePointF(Position));
      Animation.SetPositionModeW(True);
      Animation.SequenceIndex := 0;
      Animation.UpdateAutoGeometry;
      if not (State in [2, 3]) then
        FrameIndex := PresentationRandom(Animation.SequenceFrameCount - 1);
      Animation.SetSequenceFrame(FrameIndex);
      Animation.RestartPlayback;
      Animation.SetAlpha(Math.Min(Alpha, AlphaLimit) shr Space.AlphaShift);
      if not KeepSize then
        Size := Animation.ClientSize;
    end
    else
    begin
      StaticImage := TImageGI.Create(Space.MapPanel);
      StaticImage.SetImagePath(StaticImagePath);
      StaticImage.SetSize(StaticImage.GetContentSize);
      StaticImage.SetOrigin(HalfPoint(StaticImage.ClientSize));
      StaticImage.SetDepthByName(DepthExpression);
      StaticImage.SetPosition(TruncatePointF(Position));
      StaticImage.SetPositionModeW(True);
      StaticImage.SetAlpha(Math.Min(Alpha, AlphaLimit) shr Space.AlphaShift);
      if State = 3 then
      begin
        FadeTimer := Space.Screen.ScheduleCallbackTimer(20, 20, AdvanceFade);
        SetAlpha(0);
      end
      else if State = 2 then
      begin
        FadeTimer := Space.Screen.ScheduleCallbackTimer(20, 20, AdvanceFade);
        SetAlpha(255);
      end;
      if not KeepSize then
        Size := StaticImage.ClientSize;
    end;
    MinimapImage := TImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(
        TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
    );
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.ClientSize));
  end;
end;

procedure TRuinsSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    if FadeTimer <> nil then
    begin
      Space.Screen.CancelCallbackTimer(FadeTimer);
      FadeTimer := nil;
    end;
    if Animation <> nil then
    begin
      FrameIndex := Animation.SequenceFrame;
      Animation.Free;
      Animation := nil;
    end;
    if StaticImage <> nil then
    begin
      StaticImage.SetActive(False);
      StaticImage.Free;
      StaticImage := nil;
    end;
    if MinimapImage <> nil then
    begin
      MinimapImage.Free;
      MinimapImage := nil;
    end;
    inherited DetachFromSpace;
  end;
end;

procedure TRuinsSE.SetState(Value: Integer);
begin
  if not IsAttachedToSpace then
  begin
    State := Value;
    Exit;
  end;
  if State = Value then
    Exit;
  State := Value;
  if Animation <> nil then
  begin
    if not (State in [0, 1]) then
      Animation.CycleCompleteCallback := AnimationCycleComplete;
  end
  else if StaticImage <> nil then
  begin
    if State in [2, 3] then
      FadeTimer := Space.Screen.ScheduleCallbackTimer(20, 20, AdvanceFade)
    else if FadeTimer <> nil then
    begin
      Space.Screen.CancelCallbackTimer(FadeTimer);
      FadeTimer := nil;
    end;
  end;
end;

procedure TRuinsSE.AnimationCycleComplete(Sender: TObjectGI);
begin
  if State = 2 then
  begin
    Animation.SetImagePath(ImagePath + 'To');
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetSequenceFrame(0);
    Animation.RestartPlayback;
    State := 4;
  end
  else if (State = 3) or (State = 1) then
  begin
    Animation.SetImagePath(ImagePath);
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetSequenceFrame(0);
    Animation.RestartPlayback;
    Animation.CycleCompleteCallback := nil;
    State := 1;
  end
  else
  begin
    Animation.CycleCompleteCallback := nil;
    DetachFromSpace;
  end;
end;

procedure TRuinsSE.AdvanceFade(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  if State = 2 then
  begin
    SetAlpha(Math.Max(0, GetAlpha - 5));
    if GetAlpha = 0 then
    begin
      State := 1;
      DetachFromSpace;
    end;
  end
  else
  begin
    SetAlpha(Math.Min(255, GetAlpha + 5));
    if GetAlpha = 255 then
    begin
      State := 1;
      if FadeTimer <> nil then
      begin
        Space.Screen.CancelCallbackTimer(FadeTimer);
        FadeTimer := nil;
      end;
    end;
  end;
end;

procedure TRuinsSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    if StaticImage <> nil then
      StaticImage.SetPosition(TruncatePointF(APosition));
    if Animation <> nil then
      Animation.SetPosition(TruncatePointF(APosition));
    MinimapImage.SetPosition(
        TruncatePointF(
            MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
        )
    );
  end;
end;

procedure TRuinsSE.SetDepth(Value: Single);
begin
  if Animation <> nil then
    Animation.SetDepth(Value);
  if StaticImage <> nil then
    StaticImage.SetDepth(Value);
end;

function TRuinsSE.GetDepth: Single;
begin
  Result := 0;
  if Animation <> nil then
    Result := Animation.Depth;
  if StaticImage <> nil then
    Result := StaticImage.Depth;
end;

function TRuinsSE.GetAlpha: Byte;
begin
  Result := Alpha;
end;

procedure TRuinsSE.SetAlpha(Value: Byte);
begin
  Alpha := Value;
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
      Animation.SetAlpha(Math.Min(Alpha, AlphaLimit) shr Space.AlphaShift);
    if StaticImage <> nil then
      StaticImage.SetAlpha(Math.Min(Alpha, AlphaLimit) shr Space.AlphaShift);
  end;
end;

procedure TRuinsSE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if CurrentProcess.RadarRange > 0 then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;

function TRuinsSE.GetWeaponPortPoint(Seed: Cardinal): TPointF;
var
  Point: TPointF;
begin
  if WeaponPortCount < 1 then
  begin
    Result := Position;
    Exit;
  end;
  Point := WeaponPorts[1 + (Sqr(Seed) div 11) mod WeaponPortCount];
  Result.X := Position.X + Point.X;
  Result.Y := Position.Y + Point.Y;
end;

function TRuinsSE.HitTestCursor: Boolean;
begin
  Result := False;
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
      Result := Animation.HitTestPixel(Animation.MessageLoop.GetCursorPoint)
    else if StaticImage <> nil then
      Result := StaticImage.HitTestPixel(StaticImage.MessageLoop.GetCursorPoint);
  end;
end;

procedure TRuinsSE.LoadTemplate(Block: TBlockParEC);
var
  Index: Integer;
  function ParseRuinsPoint(
      PointText: WideString
  ): TPoint; // @addr $71DEA8 @ida "void __usercall $name(unsigned __int16 *PointText@<eax>, TPoint *Result@<edx>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x71E2B1"
  begin
    if CountDelimitedPartsW(PointText, ',') < 2 then
      raise Exception.Create('GetPointGI. tstr=' + PointText);
    Result :=
        Classes.Point(
            StrToInt(ExtractDelimitedPartW(PointText, 0, ',')),
            StrToInt(ExtractDelimitedPartW(PointText, 1, ','))
        );
  end;
  function ParseRuinsEnabled(
      Name: WideString
  ): Boolean; // @addr $71DFEC @ida "bool __usercall $name@<al>(unsigned __int16 *Name@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x71E22D"
  begin
    if (Name = 'Yes')
        or (Name = 'yes')
        or (Name = 'True')
        or (Name = 'true')
        or (Name = 'TRUE')
        or (Name = '1') then
      Result := True
    else
      Result := False;
  end;
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  StaticImagePath := Block.GetParam('ImageI');
  MinimapImagePath := Block.GetParam('ImageMap');
  HasTransitionImages :=
      CacheDataRoot.FileExistsByPath(ImagePath + 'To')
          and CacheDataRoot.FileExistsByPath(ImagePath + 'From');
  if Block.CountParams('PanelPartnerImage') > 0 then
    PanelPartnerImage := Block.GetParam('PanelPartnerImage')
  else
    PanelPartnerImage := '';
  if Block.CountParams('HideOnStarInfo') > 0 then
    HideOnStarInfo := ParseRuinsEnabled(Block.GetParam('HideOnStarInfo'))
  else
    HideOnStarInfo := False;
  WeaponPortCount := 0;
  for Index := Low(WeaponPorts) to High(WeaponPorts) do
  begin
    if Block.CountParams('WeaponPort' + IntToWideString(Index)) <= 0 then
      Break;
    WeaponPorts[Index] :=
        PointToPointF(ParseRuinsPoint(Block.GetParam('WeaponPort' + IntToWideString(Index))));
    Inc(WeaponPortCount);
  end;
end;

procedure TRuinsSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure TRuinsSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Anim: TgaiGI;
  Image, MapImage: TImageGI;
begin
  if AnimShipFull or (CurrentScreenId = screenArcadeBattle) then
  begin
    Anim := TgaiGI.Create(Owner);
    Anim.SetImagePath(ImagePath);
    Anim.QueueImageLoad(PendingLoads);
    Anim.Free;
  end
  else
  begin
    Image := TImageGI.Create(Owner);
    Image.SetImagePath(StaticImagePath);
    Image.QueueImageLoad(PendingLoads);
    Image.Free;
  end;
  MapImage := TImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;

procedure LinkRecoveredTypes;
begin
  TProcessSE.ClassName;
end;
end.
