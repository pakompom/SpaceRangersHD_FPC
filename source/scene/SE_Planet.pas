{$EXCESSPRECISION OFF}
unit SE_Planet;
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
  GI_GAI,
  GI_Image,
  GI_MessageLoop,
  GI_Planet,
  GR_GraphBuf,
  SE_Space,
  Types;
type
  TPlanetSE = class;
  PointerToTPlanetCollisionCircle = ^TPlanetCollisionCircle;
  PointerToTPlanetMapOrbitPoint = ^TPlanetMapOrbitPoint;
  PPlanetMapOrbitPoint = PointerToTPlanetMapOrbitPoint;
  TPlanetMapOrbitPoint = packed record
    Position: TPoint;
    PixelOffset: Integer;
  end;
  PPlanetCollisionCircle = PointerToTPlanetCollisionCircle;
  TPlanetCollisionCircle = packed record
    Next: PPlanetCollisionCircle;
    Prev: PPlanetCollisionCircle;
    Position: TPointF;
    Radius: Single;
    RadiusSquared: Single;
  end;
  TPlanetSE = class(TObjectSE)
    ImagePath: WideString;
    ImageOrigin: TPoint;
    SurfaceMapOffset: Integer;
    LightAngle: Byte;
    Gap5D: array[0..2] of Byte;
    RotationTimerInterval: Cardinal;
    SurfaceMapStep: Integer;
    MinimapImagePath: WideString;
    MinimapImageOrigin: TPoint;
    Gap74: array[0..3] of Byte;
    OrbitalVelocity: Double;
    Radius: Integer;
    Cloud1ImagePath: WideString;
    Cloud1RelativeRotationSpeed: Single;
    Cloud1MapStep: Integer;
    Cloud1Timer: PSpaceTimerSE;
    Cloud1MapOffset: Integer;
    Cloud2ImagePath: WideString;
    Cloud2RelativeRotationSpeed: Single;
    Cloud2MapStep: Integer;
    Cloud2Timer: PSpaceTimerSE;
    Cloud2MapOffset: Integer;
    Cloud3ImagePath: WideString;
    Cloud3RelativeRotationSpeed: Single;
    Cloud3MapStep: Integer;
    Cloud3Timer: PSpaceTimerSE;
    Cloud3MapOffset: Integer;
    AtmosphereColor: Cardinal;
    SpaceConfigValues: array[0..2] of Integer;
    BackgroundGraph: WideString;
    QuestEnabled: Boolean;
    RingKind: Byte;
    Civilized: Boolean;
    GapD7: array[0..0] of Byte;
    SurfaceAnimationMask: Integer;
    SurfaceAnimationIndex: Integer;
    PlanetControl: TPlanetGI;
    RingControl1: TImageGI;
    RingControl2: TImageGI;
    MinimapControl: TAlphaImageGI;
    RotationTimer: PSpaceTimerSE;
    LegacySurfaceControl: TObjectGI;
    SurfaceImageControl: TImageGI;
    SurfaceAnimationFrame: Integer;
    SurfaceAnimationOffset: TPoint;
    MapOrbitPointCount: Integer;
    MapOrbitPoints: PPlanetMapOrbitPoint;
    CollisionCircle: PPlanetCollisionCircle;
    MinimapOwner: Byte;
    Gap115: array[0..2] of Byte;
    RuinsAnimationPath: WideString;
    RuinsImagePath: WideString;
    RuinsMinimapPath: WideString;
    RuinsAnimationControl: TgaiGI;
    RuinsImageControl: TImageGI;
    RuinsMinimapControl: TImageGI;
    RuinsAnimationFrame: Integer;
    IsRuins: Boolean;
    Gap135: array[0..2] of Byte;
    procedure CopyTo(Destination: TObjectSE); override;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    constructor Create;
    constructor CreateFromGraph(const AGraphKey: WideString; UnusedPosition: TPoint);
    procedure RebuildRings;
    procedure RebuildSurfaceAnimation;
    procedure StartRandomSurfaceAnimation;
    procedure SetMinimapOwner(Owner: Byte);
    procedure SetSurfaceMapOffset(Value: Integer);
    procedure SetCloud1MapOffset(Value: Integer);
    procedure SetCloud2MapOffset(Value: Integer);
    procedure SetCloud3MapOffset(Value: Integer);
    procedure SetLightAngle(Value: Byte);
    procedure SetRotationTimerInterval(Value: Cardinal);
    procedure SetSurfaceMapStep(Value: Integer);
    procedure SetRingKind(Kind: Byte);
    procedure SetSurfaceAnimationMask(Mask: Integer);
    procedure UpdateLightAngleFromStar;
    procedure SurfaceAnimationFinished(Sender: TObjectGI);
    procedure AdvanceRotationTimer(Timer: PSpaceTimerSE; UserData: Integer);
    procedure AdvanceCloudTimer(Timer: PSpaceTimerSE; UserData: Integer);
    procedure RenderToBuffer(Screen: TMessageLoopGI; Buffer: TGraphBufGR; SmallPreview: Boolean);
  end;
var
  FirstPlanetCollisionCircle: PPlanetCollisionCircle = nil;
function AllocatePlanetCollisionCircle: PPlanetCollisionCircle;
procedure FreePlanetCollisionCircle(Entry: PPlanetCollisionCircle);
procedure LinkRecoveredTypes;
implementation
uses
  GI_GI,
  SysUtils,
  Math,
  EC_Str,
  SE_Star,
  GlobalsV,
  Globals,
  GR_Main,
  GI_Main,
  aConst,
  aMyFunction,
  EC_Mem,
  EC_Cache,
  EC_CacheBitmap,
  Windows,
  SE_Process;

constructor TPlanetSE.Create;
begin
  inherited CreateEmpty;
end;

constructor TPlanetSE.CreateFromGraph(const AGraphKey: WideString; UnusedPosition: TPoint);
begin
  IsRuins := FindTextOffsetW(AGraphKey, 'Ruins') = 0;
  inherited Create(AGraphKey, UnusedPosition);
end;

procedure TPlanetSE.CopyTo(Destination: TObjectSE);
begin
  inherited CopyTo(Destination);
  with Destination as TPlanetSE do
  begin
    ImagePath := Self.ImagePath;
    ImageOrigin := Self.ImageOrigin;
    SurfaceMapOffset := Self.SurfaceMapOffset;
    LightAngle := Self.LightAngle;
    RotationTimerInterval := Self.RotationTimerInterval;
    SurfaceMapStep := Self.SurfaceMapStep;
    MinimapImagePath := Self.MinimapImagePath;
    MinimapImageOrigin := Self.MinimapImageOrigin;
    OrbitalVelocity := Self.OrbitalVelocity;
    Radius := Self.Radius;
    RingKind := Self.RingKind;
    MinimapOwner := Self.MinimapOwner;
    Cloud1ImagePath := Self.Cloud1ImagePath;
    Cloud1RelativeRotationSpeed := Self.Cloud1RelativeRotationSpeed;
    Cloud1MapOffset := Self.Cloud1MapOffset;
    Cloud2ImagePath := Self.Cloud2ImagePath;
    Cloud2RelativeRotationSpeed := Self.Cloud2RelativeRotationSpeed;
    Cloud2MapOffset := Self.Cloud2MapOffset;
    Cloud3ImagePath := Self.Cloud3ImagePath;
    Cloud3RelativeRotationSpeed := Self.Cloud3RelativeRotationSpeed;
    Cloud3MapOffset := Self.Cloud3MapOffset;
    AtmosphereColor := Self.AtmosphereColor;
    SpaceConfigValues[0] := Self.SpaceConfigValues[0];
    SpaceConfigValues[1] := Self.SpaceConfigValues[1];
    SpaceConfigValues[2] := Self.SpaceConfigValues[2];
    BackgroundGraph := Self.BackgroundGraph;
    QuestEnabled := Self.QuestEnabled;
    IsRuins := Self.IsRuins;
    RuinsAnimationPath := Self.RuinsAnimationPath;
    RuinsImagePath := Self.RuinsImagePath;
    RuinsMinimapPath := Self.RuinsMinimapPath;
    RuinsAnimationFrame := Self.RuinsAnimationFrame;
  end;
end;

procedure TPlanetSE.AttachToSpace(ASpace: TSpaceSE);
var
  Template: TPlanetTempl;
  Index, Count, Interval, OwnerIndex: Integer;
begin
  if IsAttachedToSpace then
    Exit;
  if Civilized then
    ConfigureLoopSound('Planet.Civil')
  else
    ConfigureLoopSound('Planet.NotCivil');
  if Civilized then
    ConfigureRandomSound('Planet.Civil')
  else
    ConfigureRandomSound('Planet.NotCivil');
  inherited AttachToSpace(ASpace);
  if IsRuins then
  begin
    if AnimShipFull or (CurrentScreenId = screenArcadeBattle) then
    begin
      RuinsAnimationControl := TgaiGI.Create(Space.MapPanel);
      RuinsAnimationControl.SetImagePath(RuinsAnimationPath);
      RuinsAnimationControl.SetSize(RuinsAnimationControl.GetContentSize);
      RuinsAnimationControl.SetOrigin(HalfPoint(RuinsAnimationControl.ClientSize));
      RuinsAnimationControl.SetDepthByName(DepthExpression);
      RuinsAnimationControl.SetPosition(TruncatePointF(Position));
      RuinsAnimationControl.SetPositionModeW(True);
      RuinsAnimationControl.SequenceIndex := 0;
      RuinsAnimationControl.UpdateAutoGeometry;
      RuinsAnimationControl.SetSequenceFrame(RuinsAnimationFrame);
      RuinsAnimationControl.RestartPlayback;
      RuinsAnimationControl.SetAlpha(255);
      Size := RuinsAnimationControl.ClientSize;
    end
    else
    begin
      RuinsImageControl := TImageGI.Create(Space.MapPanel);
      RuinsImageControl.SetImagePath(RuinsImagePath);
      RuinsImageControl.SetSize(RuinsImageControl.GetContentSize);
      RuinsImageControl.SetOrigin(HalfPoint(RuinsImageControl.ClientSize));
      RuinsImageControl.SetDepthByName(DepthExpression);
      RuinsImageControl.SetPosition(TruncatePointF(Position));
      RuinsImageControl.SetPositionModeW(True);
      RuinsImageControl.SetAlpha(255);
      Size := RuinsImageControl.ClientSize;
    end;
    RuinsMinimapControl := TImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    RuinsMinimapControl.SetPositionModeW(True);
    RuinsMinimapControl.SetDepthByName(DepthExpression);
    RuinsMinimapControl.SetPosition(
        TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
    );
    RuinsMinimapControl.SetImagePath(RuinsMinimapPath);
    RuinsMinimapControl.SetSize(RuinsMinimapControl.GetContentSize);
    RuinsMinimapControl.SetOrigin(HalfPoint(RuinsMinimapControl.ClientSize));
  end
  else
  begin
    Template := nil;
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      Template := PlanetRenderTemplates[Index];
      if Template.Radius = Radius then
        Break;
    end;
    if Template = nil then
      raise Exception.Create('Error in TPlanetSE.Connect');
    PlanetControl := TPlanetGI.Create(Space.MapPanel);
    PlanetControl.SetPositionModeW(True);
    PlanetControl.SetDepthByName(DepthExpression);
    PlanetControl.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
    PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
    PlanetControl.SetOrigin(ImageOrigin);
    PlanetControl.SetImageWithRadius(Template.MaskName, ImagePath, Template.LightName, Radius);
    if PlanetClouds then
    begin
      if Cloud1ImagePath <> '' then
        PlanetControl.SetCloud1Image(Cloud1ImagePath);
      if Cloud2ImagePath <> '' then
        PlanetControl.SetCloud2Image(Cloud2ImagePath);
      if Cloud3ImagePath <> '' then
        PlanetControl.SetCloud3Image(Cloud3ImagePath);
      PlanetControl.SetCloud1MapOffset(Cloud1MapOffset);
      PlanetControl.SetCloud2MapOffset(Cloud2MapOffset);
      PlanetControl.SetCloud3MapOffset(Cloud3MapOffset);
    end;
    PlanetControl.SetLightAngle(LightAngle);
    if PlanetAtm and (AtmosphereColor <> 0) then
    begin
      PlanetControl.SetAtmosphere(
          'Bm.Atm.' + GiResourceSuffix + 'atm' + IntToStr(Radius * 2),
          'Bm.Atm.' + GiResourceSuffix + 'mask' + IntToStr(Radius * 2),
          AtmosphereColor
      );
      PlanetControl.SetOrigin(HalfPoint(PlanetControl.ClientSize));
    end;
    MinimapControl := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapControl.SetPositionModeW(True);
    MinimapControl.SetDepthByName(DepthExpression);
    MinimapControl.SetPosition(
        TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale))
    );
    MinimapControl.SetOrigin(MinimapImageOrigin);
    if MinimapOwner <= 7 then
      MinimapControl.SetImagePath('Bm.Planet.M.' + OwnerInfo[MinimapOwner].InternalName)
    else
    begin
      OwnerIndex := MinimapOwner - 7 - 1;
      if OwnerIndex <= 9 then
        MinimapControl.SetImagePath('Bm.Planet.M.0' + IntToWideString(OwnerIndex))
      else
        MinimapControl.SetImagePath('Bm.Planet.M.' + IntToWideString(OwnerIndex));
    end;
    MinimapControl.SetSize(MinimapControl.GetContentSize);
    UpdateLightAngleFromStar;
    CollisionCircle := AllocatePlanetCollisionCircle;
    CollisionCircle.Position.X := Position.X;
    CollisionCircle.Position.Y := Position.Y;
    CollisionCircle.Radius := Radius;
    RebuildRings;
    RebuildSurfaceAnimation;
    RotationTimer := Space.CreateTimer(0, RotationTimerInterval, AdvanceRotationTimer, 0);
    if PlanetClouds then
    begin
      if (Cloud1ImagePath <> '') and (Cloud1RelativeRotationSpeed <> -1) then
      begin
        if Cloud1RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud1RelativeRotationSpeed)))
              );
          Cloud1MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud1RelativeRotationSpeed - 1)))
              );
          Cloud1MapStep := -1;
        end;
        Cloud1Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 1);
      end;
      if (Cloud2ImagePath <> '') and (Cloud2RelativeRotationSpeed <> -1) then
      begin
        if Cloud2RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud2RelativeRotationSpeed)))
              );
          Cloud2MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud2RelativeRotationSpeed - 1)))
              );
          Cloud2MapStep := -1;
        end;
        Cloud2Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 2);
      end;
      if (Cloud3ImagePath <> '') and (Cloud3RelativeRotationSpeed <> -1) then
      begin
        if Cloud3RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud3RelativeRotationSpeed)))
              );
          Cloud3MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud3RelativeRotationSpeed - 1)))
              );
          Cloud3MapStep := -1;
        end;
        Cloud3Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 3);
      end;
    end;
    Size := Classes.Point((Radius + 5) * 2, (Radius + 5) * 2);
  end;
end;

procedure TPlanetSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if IsRuins then
  begin
    if RuinsAnimationControl <> nil then
    begin
      RuinsAnimationFrame := RuinsAnimationControl.SequenceFrame;
      RuinsAnimationControl.Free;
      RuinsAnimationControl := nil;
    end;
    if RuinsImageControl <> nil then
    begin
      RuinsImageControl.SetActive(False);
      RuinsImageControl.Free;
      RuinsImageControl := nil;
    end;
    if RuinsMinimapControl <> nil then
    begin
      RuinsMinimapControl.Free;
      RuinsMinimapControl := nil;
    end;
  end
  else
  begin
    FreePlanetCollisionCircle(CollisionCircle);
    CollisionCircle := nil;
    if MapOrbitPoints <> nil then
    begin
      FreeEC(MapOrbitPoints);
      MapOrbitPoints := nil;
    end;
    if RotationTimer <> nil then
    begin
      Space.DeleteTimer(RotationTimer);
      RotationTimer := nil;
    end;
    if Cloud1Timer <> nil then
    begin
      Space.DeleteTimer(Cloud1Timer);
      Cloud1Timer := nil;
    end;
    if Cloud2Timer <> nil then
    begin
      Space.DeleteTimer(Cloud2Timer);
      Cloud2Timer := nil;
    end;
    if Cloud3Timer <> nil then
    begin
      Space.DeleteTimer(Cloud3Timer);
      Cloud3Timer := nil;
    end;
    Space.MapPanel.FreeOwnedChild(PlanetControl);
    PlanetControl := nil;
    if RingControl1 <> nil then
    begin
      RingControl1.Free;
      RingControl1 := nil;
    end;
    if RingControl2 <> nil then
    begin
      RingControl2.Free;
      RingControl2 := nil;
    end;
    if LegacySurfaceControl <> nil then
    begin
      LegacySurfaceControl.Free;
      LegacySurfaceControl := nil;
    end;
    if SurfaceImageControl <> nil then
    begin
      SurfaceImageControl.Free;
      SurfaceImageControl := nil;
    end;
    if MinimapControl <> nil then
    begin
      MinimapControl.Free;
      MinimapControl := nil;
    end;
  end;
  inherited DetachFromSpace;
end;

procedure TPlanetSE.RebuildRings;
var
  Path: WideString;
  Center, Offset: TPoint;
  Bounds, FirstBounds, SecondBounds: TRect;
begin
  if IsRuins then
    Exit;
  if RingControl1 <> nil then
  begin
    RingControl1.Free;
    RingControl1 := nil;
  end;
  if RingControl2 <> nil then
  begin
    RingControl2.Free;
    RingControl2 := nil;
  end;
  if RingKind <> 0 then
  begin
    Path := 'GI,Bm.PlanetRing.' + GiResourceSuffix + 'r';
    if RingKind - 1 < 10 then
      Path := Path + '0';
    Path := Path + IntToStr(RingKind - 1) + '_';
    if RingKind >= 20 then
      Path := Path + '0'
    else if Radius = 100 then
      Path := Path + '0'
    else if Radius = 90 then
      Path := Path + '1'
    else if Radius = 80 then
      Path := Path + '2'
    else if Radius = 70 then
      Path := Path + '3'
    else if Radius = 60 then
      Path := Path + '4'
    else
      RaiseWideMessage('TPlanetSE.CreateRing');
    RingControl1 := TImageGI.Create(Space.MapPanel);
    RingControl1.SetPositionModeW(True);
    RingControl1.SetDepth(PlanetControl.Depth - 0.01);
    RingControl1.SetImagePath(Path + '_1');
    RingControl1.SetSize(RingControl1.GetContentSize);
    RingControl1.SetPosition(PlanetControl.LocalPosition);
    RingControl2 := TImageGI.Create(Space.MapPanel);
    RingControl2.SetPositionModeW(True);
    RingControl2.SetDepth(PlanetControl.Depth + 0.01);
    RingControl2.SetImagePath(Path + '_2');
    RingControl2.SetSize(RingControl2.GetContentSize);
    RingControl2.SetPosition(PlanetControl.LocalPosition);
    FirstBounds.TopLeft := RingControl1.GetContentOrigin;
    FirstBounds.BottomRight := AddPoints(FirstBounds.TopLeft, RingControl1.ClientSize);
    SecondBounds.TopLeft := RingControl2.GetContentOrigin;
    SecondBounds.BottomRight := AddPoints(SecondBounds.TopLeft, RingControl2.ClientSize);
    Windows.UnionRect(Bounds, FirstBounds, SecondBounds);
    Center := Classes.Point((Bounds.Right + Bounds.Left) div 2, (Bounds.Bottom + Bounds.Top) div 2);
    Offset := Classes.Point(0, Bounds.Right div 2 - Bounds.Bottom div 2);
    if RingKind = 8 then
      Inc(Offset.Y, GiScalePixels(10));
    if RingKind = 8 then
      Inc(Offset.X, GiScalePixels(5));
    if RingKind = 21 then
      Inc(Offset.Y, GiScalePixels(25))
    else if RingKind = 22 then
      Inc(Offset.Y, GiScalePixels(15));
    if RingKind = 21 then
      Dec(Offset.X, GiScalePixels(8))
    else if RingKind = 22 then
      Dec(Offset.X, GiScalePixels(5));
    RingControl1.SetOrigin(SubtractPoints(SubtractPoints(Center, FirstBounds.TopLeft), Offset));
    RingControl2.SetOrigin(SubtractPoints(SubtractPoints(Center, SecondBounds.TopLeft), Offset));
  end;
end;

procedure TPlanetSE.RebuildSurfaceAnimation;
var
  Scale: Single;
begin
  if IsRuins then
    Exit;
  if LegacySurfaceControl <> nil then
  begin
    LegacySurfaceControl.Free;
    LegacySurfaceControl := nil;
  end;
  if SurfaceImageControl <> nil then
  begin
    SurfaceImageControl.Free;
    SurfaceImageControl := nil;
  end;
  if (SurfaceAnimationMask > 0) and (GiResourceVariant = 2) and (Radius = 100) then
  begin
    SurfaceAnimationIndex := -1;
    Scale := (Radius - 60) / 40 * 0.7 + 0.3;
    SurfaceAnimationOffset.X :=
        GiScalePixels(
            Round(PlanetAdvertDefinitions[SurfaceAnimationMask shr 24].Position.X * Scale)
        );
    SurfaceAnimationOffset.Y :=
        GiScalePixels(
            Round(PlanetAdvertDefinitions[SurfaceAnimationMask shr 24].Position.Y * Scale)
        );
    SurfaceAnimationFrame := 0;
    SurfaceImageControl := TImageGI.Create(Space.MapPanel);
    SurfaceImageControl.SetPositionModeW(True);
    SurfaceImageControl.SetDepth(PlanetControl.Depth - 0.02);
    StartRandomSurfaceAnimation;
  end;
end;

procedure TPlanetSE.StartRandomSurfaceAnimation;
var
  Index, Attempts, TotalWeight, Choice: Integer;
begin
  if IsRuins then
    Exit;
  TotalWeight := 0;
  with PlanetAdvertDefinitions[SurfaceAnimationMask shr 24] do
  begin
    for Index := 0 to 23 do
      if (SurfaceAnimationMask and (1 shl Index)) <> 0 then
        Inc(TotalWeight, Lists[Index].Key);
    Attempts := 10;
    while Attempts > 0 do
    begin
      Choice := RandomIntRange(0, TotalWeight - 1);
      for Index := 0 to 23 do
        if (SurfaceAnimationMask and (1 shl Index)) <> 0 then
        begin
          Dec(Choice, Lists[Index].Key);
          if Choice < 0 then
          begin
            SurfaceAnimationIndex := Index;
            Break;
          end;
        end;
      Dec(Attempts);
    end;
  end;
  SurfaceAnimationFrame := 0;
  if GiResourceVariant = 1 then
    SurfaceImageControl.SetImagePath(
        PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
            .Adverts[
                PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
                    .Lists[SurfaceAnimationIndex]
                    .Indices[SurfaceAnimationFrame]]
            .Image1
    )
  else
    SurfaceImageControl.SetImagePath(
        PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
            .Adverts[
                PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
                    .Lists[SurfaceAnimationIndex]
                    .Indices[SurfaceAnimationFrame]]
            .Image2
    );
  SurfaceImageControl.SetSize(SurfaceImageControl.GetContentSize);
  SurfaceImageControl.SetOrigin(HalfPoint(SurfaceImageControl.ClientSize));
  SurfaceImageControl.SetPosition(AddPoints(PlanetControl.LocalPosition, SurfaceAnimationOffset));
  if SurfaceImageControl.GaiImageControl <> nil then
    SurfaceImageControl.GaiImageControl.CycleCompleteCallback := SurfaceAnimationFinished;
  SurfaceImageControl.RestartPlayback;
end;

procedure TPlanetSE.SetMinimapOwner(Owner: Byte);
var
  Index: Integer;
begin
  if IsRuins then
    Exit;
  if MinimapOwner = Owner then
    Exit;
  MinimapOwner := Owner;
  if MinimapControl <> nil then
  begin
    if MinimapOwner <= 7 then
      MinimapControl.SetImagePath('Bm.Planet.M.' + OwnerInfo[MinimapOwner].InternalName)
    else
    begin
      Index := MinimapOwner - 7 - 1;
      if Index <= 9 then
        MinimapControl.SetImagePath('Bm.Planet.M.0' + IntToWideString(Index))
      else
        MinimapControl.SetImagePath('Bm.Planet.M.' + IntToWideString(Index));
    end;
    MinimapControl.SetSize(MinimapControl.GetContentSize);
  end;
end;

procedure TPlanetSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsRuins then
  begin
    if IsAttachedToSpace then
    begin
      if RuinsImageControl <> nil then
        RuinsImageControl.SetPosition(TruncatePointF(APosition));
      if RuinsAnimationControl <> nil then
        RuinsAnimationControl.SetPosition(TruncatePointF(APosition));
      RuinsMinimapControl.SetPosition(
          TruncatePointF(
              MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
          )
      );
    end;
  end
  else
  begin
    if CollisionCircle <> nil then
    begin
      CollisionCircle.Position.X := Position.X;
      CollisionCircle.Position.Y := Position.Y;
      CollisionCircle.Radius := Radius;
      CollisionCircle.RadiusSquared := Radius * Radius;
    end;
    UpdateLightAngleFromStar;
    if IsAttachedToSpace then
    begin
      PlanetControl.SetPosition(Classes.Point(Round(APosition.X), Round(APosition.Y)));
      MinimapControl.SetPosition(
          TruncatePointF(
              MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)
          )
      );
      if RingControl1 <> nil then
        RingControl1.SetPosition(PlanetControl.LocalPosition);
      if RingControl2 <> nil then
        RingControl2.SetPosition(PlanetControl.LocalPosition);
      if LegacySurfaceControl <> nil then
        LegacySurfaceControl
            .SetPosition(AddPoints(PlanetControl.LocalPosition, SurfaceAnimationOffset));
      if SurfaceImageControl <> nil then
        SurfaceImageControl
            .SetPosition(AddPoints(PlanetControl.LocalPosition, SurfaceAnimationOffset));
    end;
  end;
end;

procedure TPlanetSE.SetSurfaceMapOffset(Value: Integer);
begin
  SurfaceMapOffset := Value;
  if (not IsRuins) and IsAttachedToSpace then
    PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
end;

procedure TPlanetSE.SetCloud1MapOffset(Value: Integer);
begin
  Cloud1MapOffset := Value;
  if (not IsRuins) and IsAttachedToSpace then
    PlanetControl.SetCloud1MapOffset(Cloud1MapOffset);
end;

procedure TPlanetSE.SetCloud2MapOffset(Value: Integer);
begin
  Cloud2MapOffset := Value;
  if (not IsRuins) and IsAttachedToSpace then
    PlanetControl.SetCloud2MapOffset(Cloud2MapOffset);
end;

procedure TPlanetSE.SetCloud3MapOffset(Value: Integer);
begin
  Cloud3MapOffset := Value;
  if (not IsRuins) and IsAttachedToSpace then
    PlanetControl.SetCloud3MapOffset(Cloud3MapOffset);
end;

procedure TPlanetSE.SetLightAngle(Value: Byte);
begin
  if IsRuins then
    Exit;
  LightAngle := Value;
  if IsAttachedToSpace then
    PlanetControl.SetLightAngle(LightAngle);
end;

procedure TPlanetSE.SetRotationTimerInterval(Value: Cardinal);
var
  Interval: Integer;
begin
  RotationTimerInterval := Value;
  if IsRuins then
    Exit;
  if IsAttachedToSpace then
  begin
    if RotationTimer <> nil then
    begin
      Space.DeleteTimer(RotationTimer);
      RotationTimer := nil;
    end;
    RotationTimer := Space.CreateTimer(0, RotationTimerInterval, AdvanceRotationTimer, 0);
    if Cloud1Timer <> nil then
    begin
      Space.DeleteTimer(Cloud1Timer);
      Cloud1Timer := nil;
    end;
    if Cloud2Timer <> nil then
    begin
      Space.DeleteTimer(Cloud2Timer);
      Cloud2Timer := nil;
    end;
    if Cloud3Timer <> nil then
    begin
      Space.DeleteTimer(Cloud3Timer);
      Cloud3Timer := nil;
    end;
    if PlanetClouds then
    begin
      if (Cloud1ImagePath <> '') and (Cloud1RelativeRotationSpeed <> -1) then
      begin
        if Cloud1RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud1RelativeRotationSpeed)))
              );
          Cloud1MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud1RelativeRotationSpeed - 1)))
              );
          Cloud1MapStep := -1;
        end;
        Cloud1Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 1);
      end;
      if (Cloud2ImagePath <> '') and (Cloud2RelativeRotationSpeed <> -1) then
      begin
        if Cloud2RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud2RelativeRotationSpeed)))
              );
          Cloud2MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud2RelativeRotationSpeed - 1)))
              );
          Cloud2MapStep := -1;
        end;
        Cloud2Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 2);
      end;
      if (Cloud3ImagePath <> '') and (Cloud3RelativeRotationSpeed <> -1) then
      begin
        if Cloud3RelativeRotationSpeed > -1 then
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (1 + Cloud3RelativeRotationSpeed)))
              );
          Cloud3MapStep := 1;
        end
        else
        begin
          Interval :=
              Max(
                  10,
                  Round(1000 / (1000 / RotationTimerInterval * (-Cloud3RelativeRotationSpeed - 1)))
              );
          Cloud3MapStep := -1;
        end;
        Cloud3Timer := Space.CreateTimer(0, Abs(Interval), AdvanceCloudTimer, 3);
      end;
    end;
  end;
end;

procedure TPlanetSE.SetSurfaceMapStep(Value: Integer);
begin
  SurfaceMapStep := Value;
end;

procedure TPlanetSE.SetRingKind(Kind: Byte);
begin
  if IsRuins then
    Exit;
  RingKind := Kind;
  if IsAttachedToSpace then
    RebuildRings;
end;

procedure TPlanetSE.SetSurfaceAnimationMask(Mask: Integer);
begin
  if IsRuins then
    Exit;
  SurfaceAnimationMask := Mask;
  if IsAttachedToSpace then
    RebuildSurfaceAnimation;
end;

procedure TPlanetSE.UpdateLightAngleFromStar;
var
  Obj: TObjectSE;
begin
  if IsAttachedToSpace and not IsRuins then
  begin
    Obj := Space.FirstObject;
    while Obj <> nil do
    begin
      if Obj is TStarSE then
      begin
        SetLightAngle(
            Trunc(
                ArcTan2(-(Position.X - Obj.Position.X), Position.Y - Obj.Position.Y)
                    * 180
                    / 3.1415926
                    * 256
                    / 360
            )
        );
        Break;
      end;
      Obj := Obj.Next;
    end;
  end;
end;

procedure TPlanetSE.SurfaceAnimationFinished(Sender: TObjectGI);
begin
  if IsRuins then
    Exit;
  Inc(SurfaceAnimationFrame);
  if High(PlanetAdvertDefinitions[SurfaceAnimationMask shr 24].Lists[SurfaceAnimationIndex].Indices)
      < SurfaceAnimationFrame then
    StartRandomSurfaceAnimation
  else
  begin
    if GiResourceVariant = 1 then
      SurfaceImageControl.SetImagePath(
          PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
              .Adverts[
                  PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
                      .Lists[SurfaceAnimationIndex]
                      .Indices[SurfaceAnimationFrame]]
              .Image1
      )
    else
      SurfaceImageControl.SetImagePath(
          PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
              .Adverts[
                  PlanetAdvertDefinitions[SurfaceAnimationMask shr 24]
                      .Lists[SurfaceAnimationIndex]
                      .Indices[SurfaceAnimationFrame]]
              .Image2
      );
    if SurfaceImageControl.GaiImageControl <> nil then
      SurfaceImageControl.GaiImageControl.CycleCompleteCallback := SurfaceAnimationFinished;
    SurfaceImageControl.RestartPlayback;
  end;
end;

procedure TPlanetSE.AdvanceRotationTimer(Timer: PSpaceTimerSE; UserData: Integer);
begin
  if not IsRuins then
    SetSurfaceMapOffset(SurfaceMapOffset + SurfaceMapStep);
end;

procedure TPlanetSE.AdvanceCloudTimer(Timer: PSpaceTimerSE; UserData: Integer);
begin
  if IsRuins then
    Exit;
  if SurfaceMapStep > 0 then
  begin
    if UserData = 1 then
      SetCloud1MapOffset(Cloud1MapOffset + Cloud1MapStep)
    else if UserData = 2 then
      SetCloud2MapOffset(Cloud2MapOffset + Cloud2MapStep)
    else if UserData = 3 then
      SetCloud3MapOffset(Cloud3MapOffset + Cloud3MapStep);
  end
  else
  begin
    if UserData = 1 then
      SetCloud1MapOffset(Cloud1MapOffset - Cloud1MapStep)
    else if UserData = 2 then
      SetCloud2MapOffset(Cloud2MapOffset - Cloud2MapStep)
    else if UserData = 3 then
      SetCloud3MapOffset(Cloud3MapOffset - Cloud3MapStep);
  end;
end;

function TPlanetSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
  begin
    Result := False;
    Exit;
  end;
  Result := False;
  if IsRuins then
  begin
    if RuinsAnimationControl <> nil then
      Result := RuinsAnimationControl.HitTestPixel(RuinsAnimationControl.MessageLoop.GetCursorPoint)
    else if RuinsImageControl <> nil then
      Result := RuinsImageControl.HitTestPixel(RuinsImageControl.MessageLoop.GetCursorPoint);
  end
  else
    Result := PlanetControl.HitTestCursor;
end;

procedure TPlanetSE.DrawMap;
var
  Capacity, Index, X, Y, CenterX, CenterY: Integer;
  ProjectedXi, ProjectedYi, Decision, OrbitRadius, Pitch: Integer;
  ProjectedX, ProjectedY: Single;
  Dest, P0, P1, P2, P3, P4, P5, P6, P7: PPlanetMapOrbitPoint;
  Pixels, Scratch: Pointer;
  OctantCount: Integer;
  Intensity, IntensityStep: Single;
begin
  with Space.Process as TProcessSE do
  begin
    if RadarRange <= 0 then
      Exit;
    if IsRuins then
      RuinsMinimapControl
          .Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height))
    else
    begin
      Pixels := RenderScratchBuffer.GetPixels;
      Pitch := RenderScratchBuffer.PitchBytes;
      ProjectedX := Position.X * Self.Space.MinimapScale;
      ProjectedY := Position.Y * Self.Space.MinimapScale;
      ProjectedXi := Round(ProjectedX);
      ProjectedYi := Round(ProjectedY);
      if MapOrbitPoints = nil then
      begin
        Capacity := RenderScratchBuffer.Width shr 1;
        Scratch := AllocEC(Capacity * 8 * SizeOf(TPlanetMapOrbitPoint));
        OrbitRadius := Round(Sqrt(ProjectedXi * ProjectedXi + ProjectedYi * ProjectedYi));
        CenterX := RenderScratchBuffer.Width shr 1;
        CenterY := RenderScratchBuffer.Height shr 1;
        Decision := 3 - 2 * OrbitRadius;
        X := 0;
        Y := OrbitRadius - 1;
        P0 := Scratch;
        P1 := AddPointerOffset(P0, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P2 := AddPointerOffset(P1, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P3 := AddPointerOffset(P2, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P4 := AddPointerOffset(P3, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P5 := AddPointerOffset(P4, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P6 := AddPointerOffset(P5, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P7 := AddPointerOffset(P6, Capacity * SizeOf(TPlanetMapOrbitPoint));
        OctantCount := 0;
        repeat
          P0.Position.X := CenterX + X;
          P0.Position.Y := CenterY - Y;
          P0 := AddPointerOffset(P0, SizeOf(TPlanetMapOrbitPoint));
          P1.Position.X := CenterX + Y;
          P1.Position.Y := CenterY - X;
          P1 := AddPointerOffset(P1, SizeOf(TPlanetMapOrbitPoint));
          P2.Position.X := CenterX + Y;
          P2.Position.Y := CenterY + X;
          P2 := AddPointerOffset(P2, SizeOf(TPlanetMapOrbitPoint));
          P3.Position.X := CenterX + X;
          P3.Position.Y := CenterY + Y;
          P3 := AddPointerOffset(P3, SizeOf(TPlanetMapOrbitPoint));
          P4.Position.X := CenterX - X;
          P4.Position.Y := CenterY + Y;
          P4 := AddPointerOffset(P4, SizeOf(TPlanetMapOrbitPoint));
          P5.Position.X := CenterX - Y;
          P5.Position.Y := CenterY + X;
          P5 := AddPointerOffset(P5, SizeOf(TPlanetMapOrbitPoint));
          P6.Position.X := CenterX - Y;
          P6.Position.Y := CenterY - X;
          P6 := AddPointerOffset(P6, SizeOf(TPlanetMapOrbitPoint));
          P7.Position.X := CenterX - X;
          P7.Position.Y := CenterY - Y;
          P7 := AddPointerOffset(P7, SizeOf(TPlanetMapOrbitPoint));
          Inc(OctantCount);
          if Decision < 0 then
            Decision := 4 * X + Decision + 6
          else
          begin
            Decision := 4 * (X - Y) + Decision + 10;
            Dec(Y);
          end;
          Inc(X);
        until X > Y;
        MapOrbitPointCount := OctantCount * 8;
        MapOrbitPoints := AllocEC(MapOrbitPointCount * SizeOf(TPlanetMapOrbitPoint));
        Dest := MapOrbitPoints;
        P0 := Scratch;
        P1 :=
            AddPointerOffset(
                Scratch,
                Capacity * SizeOf(TPlanetMapOrbitPoint)
                    + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint)
            );
        P2 := AddPointerOffset(Scratch, Capacity * 2 * SizeOf(TPlanetMapOrbitPoint));
        P3 :=
            AddPointerOffset(
                Scratch,
                Capacity * 3 * SizeOf(TPlanetMapOrbitPoint)
                    + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint)
            );
        P4 := AddPointerOffset(Scratch, Capacity * 4 * SizeOf(TPlanetMapOrbitPoint));
        P5 :=
            AddPointerOffset(
                Scratch,
                Capacity * 5 * SizeOf(TPlanetMapOrbitPoint)
                    + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint)
            );
        P6 := AddPointerOffset(Scratch, Capacity * 6 * SizeOf(TPlanetMapOrbitPoint));
        P7 :=
            AddPointerOffset(
                Scratch,
                Capacity * 7 * SizeOf(TPlanetMapOrbitPoint)
                    + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint)
            );
        X := -10000;
        Y := -10000;
        { Preserve octant traversal and duplicate suppression at the joins. }
        for Index := 0 to OctantCount - 1 do
        begin
          if (P0.Position.X <> X) or (P0.Position.Y <> Y) then
          begin
            Dest.Position.X := P0.Position.X;
            Dest.Position.Y := P0.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P0 := AddPointerOffset(P0, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P1.Position.X <> X) or (P1.Position.Y <> Y) then
          begin
            Dest.Position.X := P1.Position.X;
            Dest.Position.Y := P1.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P1 := AddPointerOffset(P1, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P2.Position.X <> X) or (P2.Position.Y <> Y) then
          begin
            Dest.Position.X := P2.Position.X;
            Dest.Position.Y := P2.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P2 := AddPointerOffset(P2, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P3.Position.X <> X) or (P3.Position.Y <> Y) then
          begin
            Dest.Position.X := P3.Position.X;
            Dest.Position.Y := P3.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P3 := AddPointerOffset(P3, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P4.Position.X <> X) or (P4.Position.Y <> Y) then
          begin
            Dest.Position.X := P4.Position.X;
            Dest.Position.Y := P4.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P4 := AddPointerOffset(P4, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P5.Position.X <> X) or (P5.Position.Y <> Y) then
          begin
            Dest.Position.X := P5.Position.X;
            Dest.Position.Y := P5.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P5 := AddPointerOffset(P5, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P6.Position.X <> X) or (P6.Position.Y <> Y) then
          begin
            Dest.Position.X := P6.Position.X;
            Dest.Position.Y := P6.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P6 := AddPointerOffset(P6, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P7.Position.X <> X) or (P7.Position.Y <> Y) then
          begin
            Dest.Position.X := P7.Position.X;
            Dest.Position.Y := P7.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dec(MapOrbitPointCount);
          P7 := AddPointerOffset(P7, -SizeOf(TPlanetMapOrbitPoint));
        end;
        FreeEC(Scratch);
      end;
      Index :=
          Round(
              RadiansToHeadingDegrees(ArcTan2(ProjectedX, -ProjectedY))
                  / 360
                  * (MapOrbitPointCount - 1)
          );
      Dest := AddPointerOffset(MapOrbitPoints, Index * SizeOf(TPlanetMapOrbitPoint));
      Intensity := 255;
      IntensityStep := -510 / MapOrbitPointCount;
      while Intensity > 0 do
      begin
        BlendPixel16(
            AddPointerOffset(Pixels, Dest.PixelOffset),
            ReadWordEC(AddPointerOffset(InterfaceBlendPalette, Round(Intensity) * 2)),
            Round(Intensity)
        );
        if OrbitalVelocity > 0 then
        begin
          Dec(Index);
          if Index < 0 then
          begin
            Index := MapOrbitPointCount - 1;
            Dest := AddPointerOffset(MapOrbitPoints, Index * SizeOf(TPlanetMapOrbitPoint));
          end
          else
            Dest := AddPointerOffset(Dest, -SizeOf(TPlanetMapOrbitPoint));
        end
        else
        begin
          Inc(Index);
          if Index >= MapOrbitPointCount then
          begin
            Index := 0;
            Dest := MapOrbitPoints;
          end
          else
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
        end;
        Intensity := Intensity + IntensityStep;
      end;
      MinimapControl
          .Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
    end;
  end;
end;

procedure TPlanetSE.RenderToBuffer(
    Screen: TMessageLoopGI;
    Buffer: TGraphBufGR;
    SmallPreview: Boolean
);
var
  Template: TPlanetTempl;
  Planet: TPlanetGI;
  Index, Count, TemplateIndex, Diameter: Integer;
  Control: TCBitmapControlEC;
  RenderRadius: Integer;
  SatelliteTemplate: TSputnikTempl;
begin
  if IsRuins then
    LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(RuinsImagePath, 1, ','), Buffer)
  else if PlanetControl <> nil then
    PlanetControl.RenderSurfaceToBuffer(Buffer)
  else
  begin
    SatelliteTemplate := nil;
    Template := nil;
    if not SmallPreview then
    begin
      Count := PlanetRenderTemplates.Count;
      for Index := 0 to Count - 1 do
      begin
        Template := PlanetRenderTemplates[Index];
        if Template.Radius = Radius then
          Break;
      end;
      if Template = nil then
        raise Exception.Create('Error1 in TPlanetSE.DrawBufRGBA');
    end;
    if SmallPreview then
      RenderRadius := 25
    else
      RenderRadius := (Radius * 2) div 2;
    Diameter := RenderRadius * 2;
    if Diameter < 1 then
      raise Exception.Create('Error2 in TPlanetSE.DrawBufRGBA');
    Planet := TPlanetGI.Create(Screen.ContentPanel);
    if SmallPreview then
    begin
      TemplateIndex := RenderRadius * 2 - MinimumSatelliteTemplateRadius;
      SatelliteTemplate := SatelliteRenderTemplates[TemplateIndex];
      Planet.SetImageFromTemplate(SatelliteTemplate.MaskName, ImagePath, SatelliteTemplate.Radius);
    end
    else
      Planet.SetImageWithRadius(Template.MaskName, ImagePath, Template.LightName, RenderRadius);
    Planet.SetLightAngle(224);
    Planet.HitTestBounds := Classes.Rect(-1, -1, Diameter, Diameter);
    Control := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    if SmallPreview then
      Control.SetCacheKey(ExtractDelimitedPartW(SatelliteTemplate.MaskName, 0, '?') + '?RGBA')
    else
      Control.SetCacheKey(Template.MaskName + '?RGBA');
    AcquireOrCreateBitmap(Control);
    Planet.RenderSurfaceToBuffer(Buffer);
    Planet.Free;
    Control.Release;
    Control.Free;
  end;
end;

procedure TPlanetSE.LoadTemplate(Block: TBlockParEC);
var
  Text: WideString;
begin
  inherited LoadTemplate(Block);
  if IsRuins then
  begin
    RuinsAnimationPath := Block.GetParam('Image');
    RuinsImagePath := Block.GetParam('ImageI');
    RuinsMinimapPath := Block.GetParam('ImageMap');
  end
  else
  begin
    RotationTimerInterval := 100;
    SurfaceMapStep := -1;
    ImagePath := Block.GetParam('Image');
    MinimapImagePath := Block.GetParam('ImageMap');
    ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
    MinimapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
    Radius := StrToInt(Block.GetParam('Radius'));
    if Block.CountParams('Cloud0') > 0 then
    begin
      Text := Block.GetParam('Cloud0');
      Cloud1RelativeRotationSpeed := ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ','));
      Cloud1ImagePath := ExtractDelimitedPartW(Text, 1, ',');
    end;
    if Block.CountParams('Cloud1') > 0 then
    begin
      Text := Block.GetParam('Cloud1');
      Cloud2RelativeRotationSpeed := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
      Cloud2ImagePath := ExtractDelimitedPartW(Text, 1, ',');
    end;
    if Block.CountParams('Cloud2') > 0 then
    begin
      Text := Block.GetParam('Cloud2');
      Cloud3RelativeRotationSpeed := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
      Cloud3ImagePath := ExtractDelimitedPartW(Text, 1, ',');
    end;
    if Block.CountParams('AtmColor') > 0 then
    begin
      Text := Block.GetParam('AtmColor');
      AtmosphereColor := Byte(ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ',')));
      AtmosphereColor :=
          AtmosphereColor or (Byte(ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','))) shl 8);
      AtmosphereColor :=
          AtmosphereColor
              or (Byte(ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','))) shl 16);
    end;
    if Block.CountParams('Space') > 0 then
    begin
      Text := Block.GetParam('Space');
      SpaceConfigValues[0] := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
      SpaceConfigValues[1] := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
      SpaceConfigValues[2] := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
    end;
    if Block.CountParams('BG') > 0 then
      BackgroundGraph := Block.GetParam('BG');
    if Block.CountParams('Quest') > 0 then
      QuestEnabled := ParseEnabledNameGI(Block.GetParam('Quest'));
  end;
end;

procedure TPlanetSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if IsRuins then
    Exit;
  if Block.CountParams('SmeMap') > 0 then
    SetSurfaceMapOffset(StrToInt(Block.GetParam('SmeMap')));
  if Block.CountParams('AngleLight') > 0 then
    SetLightAngle(StrToInt(Block.GetParam('AngleLight')));
  if Block.CountParams('SpeedRotate') > 0 then
    SetRotationTimerInterval(StrToInt(Block.GetParam('SpeedRotate')));
  if Block.CountParams('StepRotate') > 0 then
    SetSurfaceMapStep(StrToInt(Block.GetParam('StepRotate')));
end;

procedure TPlanetSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TPlanetTempl;
  Index, Count: Integer;
  Gai: TgaiGI;
  Image, MapImage: TImageGI;
begin
  if IsRuins then
  begin
    if AnimShipFull or (CurrentScreenId = screenArcadeBattle) then
    begin
      Gai := TgaiGI.Create(Owner);
      Gai.SetImagePath(RuinsAnimationPath);
      Gai.QueueImageLoad(PendingLoads);
      Gai.Free;
    end
    else
    begin
      Image := TImageGI.Create(Owner);
      Image.SetImagePath(RuinsImagePath);
      Image.QueueImageLoad(PendingLoads);
      Image.Free;
    end;
    MapImage := TImageGI.Create(Owner);
    MapImage.SetImagePath(RuinsMinimapPath);
    MapImage.QueueImageLoad(PendingLoads);
    MapImage.Free;
  end
  else
  begin
    Template := nil;
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      Template := PlanetRenderTemplates[Index];
      if Template.Radius = Radius then
        Break;
    end;
    if Template = nil then
      raise Exception.Create('Error in TPlanetSE.BuildLoadList');
    with TPlanetGI.Create(Owner) do
    begin
      SetImageWithRadius(
          Template.SmallMaskName,
          Self.ImagePath,
          Template.SmallLightName,
          Self.Radius
      );
      QueueImageLoad(PendingLoads);
      Free;
    end;
    with TAlphaImageGI.Create(Owner) do
    begin
      SetImagePath(Self.MinimapImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
  end;
end;

function AllocatePlanetCollisionCircle: PPlanetCollisionCircle;
var
  Entry: PPlanetCollisionCircle;
begin
  New(Entry);
  Entry.Next := FirstPlanetCollisionCircle;
  Entry.Prev := nil;
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry;
  FirstPlanetCollisionCircle := Entry;
  Result := Entry;
end;

procedure FreePlanetCollisionCircle(Entry: PPlanetCollisionCircle);
begin
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry.Prev;
  if Entry.Prev <> nil then
    Entry.Prev.Next := Entry.Next;
  if Entry = FirstPlanetCollisionCircle then
    FirstPlanetCollisionCircle := Entry.Next;
  Dispose(Entry);
end;

procedure LinkRecoveredTypes;
begin
  TPlanetSE.ClassName;
  TProcessSE.ClassName;
  TStarSE.ClassName;
end;
end.
