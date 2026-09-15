{$EXCESSPRECISION OFF}
unit SE_Sputnik;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Buf,
  EC_Struct,
  GI_MessageLoop,
  GI_Planet,
  SE_Space;
type
  TSputnikSE = class;
  TSputnikSE = class(TObjectSE)
    ImagePath: WideString;
    DepthOrder: Integer;
    OrbitCenter: TPointF;
    OrbitInclination: Single;
    OrbitRotation: Single;
    OrbitAngleStep: Single;
    OrbitTimerInterval: Cardinal;
    OrbitRadius: Single;
    MinDisplayRadius: Integer;
    MaxDisplayRadius: Integer;
    RotationTimerInterval: Cardinal;
    SurfaceMapStep: Integer;
    OrbitAngle: Single;
    SurfaceMapOffset: Integer;
    DisplayRadius: Integer;
    LightAngle: Byte;
    Gap8D: array[0..2] of Byte;
    InclinationCos: Single;
    InclinationSin: Single;
    RotationCos: Single;
    RotationSin: Single;
    MinOrbitDepth: Single;
    MaxOrbitDepth: Single;
    PlanetControl: TPlanetGI;
    OrbitTimer: PCallbackTimerGI;
    RotationTimer: PCallbackTimerGI;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetOrbitCenter(Center: TPointF); override;
    function GetOrbitCenter: TPointF; override;
    function BuildStateBuffer: TBufEC; override;
    procedure LoadStateBuffer(Buffer: TBufEC); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    procedure RebuildOrbitTransform;
    procedure UpdateOrbitDisplay;
    procedure AdvanceOrbitTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure AdvanceRotationTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  Math,
  GlobalsV,
  Globals,
  GR_Main,
  aMyFunction,
  Types;

procedure TSputnikSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not SputnikShow then
    Exit;
  if IsAttachedToSpace then
    Exit;
  inherited AttachToSpace(ASpace);
  PlanetControl := TPlanetGI.Create(Space.MapPanel);
  PlanetControl.SetPositionModeW(True);
  PlanetControl.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
  PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
  RebuildOrbitTransform;
  UpdateOrbitDisplay;
  OrbitTimer :=
      Space.Screen.ScheduleCallbackTimer(OrbitTimerInterval, OrbitTimerInterval, AdvanceOrbitTimer);
  RotationTimer :=
      Space.Screen.ScheduleCallbackTimer(
          RotationTimerInterval,
          RotationTimerInterval,
          AdvanceRotationTimer
      );
end;

procedure TSputnikSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if OrbitTimer <> nil then
  begin
    Space.Screen.CancelCallbackTimer(OrbitTimer);
    OrbitTimer := nil;
  end;
  if RotationTimer <> nil then
  begin
    Space.Screen.CancelCallbackTimer(RotationTimer);
    RotationTimer := nil;
  end;
  PlanetControl.Free;
  PlanetControl := nil;
  inherited DetachFromSpace;
end;

procedure TSputnikSE.SetOrbitCenter(Center: TPointF);
begin
  OrbitCenter := Center;
  UpdateOrbitDisplay;
end;

function TSputnikSE.GetOrbitCenter: TPointF;
begin
  Result := OrbitCenter;
end;

function TSputnikSE.BuildStateBuffer: TBufEC;
var
  Buffer: TBufEC;
begin
  Buffer := TBufEC.Create;
  Buffer.AddAnsiChar(AnsiChar(DepthOrder));
  Buffer.AddSingle(OrbitInclination);
  Buffer.AddSingle(OrbitRotation);
  Buffer.AddSingle(OrbitAngleStep);
  Buffer.AddDWord(OrbitTimerInterval);
  Buffer.AddSingle(OrbitRadius);
  Buffer.AddIntegerValue(MinDisplayRadius);
  Buffer.AddIntegerValue(MaxDisplayRadius);
  Buffer.AddDWord(RotationTimerInterval);
  Buffer.AddIntegerValue(SurfaceMapStep);
  Result := Buffer;
end;

procedure TSputnikSE.LoadStateBuffer(Buffer: TBufEC);
begin
  Buffer.SetPosition(0);
  DepthOrder := Buffer.GetByte;
  OrbitInclination := Buffer.GetSingle;
  OrbitRotation := Buffer.GetSingle;
  OrbitAngleStep := Buffer.GetSingle;
  OrbitTimerInterval := Buffer.GetUInt32;
  OrbitRadius := Buffer.GetSingle;
  MinDisplayRadius := Buffer.GetInt32;
  MaxDisplayRadius := Buffer.GetInt32;
  RotationTimerInterval := Buffer.GetUInt32;
  SurfaceMapStep := Buffer.GetInt32;
  RebuildOrbitTransform;
  UpdateOrbitDisplay;
end;

procedure TSputnikSE.RebuildOrbitTransform;
var
  Angle: Single;
begin
  Angle := HeadingDegreesToRadians(OrbitRotation);
  RotationCos := Cos(Angle);
  RotationSin := Sin(Angle);
  Angle := HeadingDegreesToRadians(OrbitInclination);
  InclinationCos := Cos(Angle);
  InclinationSin := Sin(Angle);
  MaxOrbitDepth := Abs(-InclinationSin * OrbitRadius);
  MinOrbitDepth := -MaxOrbitDepth;
end;

procedure TSputnikSE.UpdateOrbitDisplay;
var
  X, Y, Z, Angle, OrbitX, OrbitY: Single;
  Index: Integer;
  Template: TSputnikTempl;
begin
  if not IsAttachedToSpace then
    Exit;
  Angle := HeadingDegreesToRadians(OrbitAngle);
  OrbitX := Sin(Angle) * OrbitRadius;
  OrbitY := Cos(Angle) * -OrbitRadius;
  X := InclinationCos * RotationCos * OrbitX + -RotationSin * OrbitY + OrbitCenter.X;
  Y := InclinationCos * RotationSin * OrbitX + OrbitY * RotationCos + OrbitCenter.Y;
  Z := -InclinationSin * OrbitX;
  Position := MakePointF(X, Y);
  DisplayRadius :=
      Round(
          (Z - MinOrbitDepth)
                  / (MaxOrbitDepth - MinOrbitDepth)
                  * (MaxDisplayRadius - MinDisplayRadius)
              + MinDisplayRadius
      );
  if DisplayRadius < MinDisplayRadius then
    DisplayRadius := MinDisplayRadius
  else if DisplayRadius > MaxDisplayRadius then
    DisplayRadius := MaxDisplayRadius;
  if Cardinal(GameScreenHeight) < 768 then
    DisplayRadius := Round(DisplayRadius * 800 / 1024);
  LightAngle := Round(ArcTan2(-Position.X, Position.Y) * 180 / 3.1415926 * 256 / 360);
  Index := DisplayRadius - MinimumSatelliteTemplateRadius;
  Template := SatelliteRenderTemplates[Index];
  PlanetControl.SetImageFromTemplate(Template.MaskName, ImagePath, Template.Radius);
  PlanetControl.SetLightAngle(LightAngle);
  PlanetControl.SetPosition(TruncatePointF(Position));
  PlanetControl.SetOrigin(Classes.Point(Template.Radius, Template.Radius));
  if Z < 0 then
    PlanetControl.SetDepth(DepthOrder + PlanetDepth + 1)
  else
    PlanetControl.SetDepth(PlanetDepth - DepthOrder - 1);
end;

procedure TSputnikSE.AdvanceOrbitTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  OrbitAngle := WrapHeadingDegrees(OrbitAngle + OrbitAngleStep);
  UpdateOrbitDisplay;
end;

procedure TSputnikSE.AdvanceRotationTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  SurfaceMapOffset := SurfaceMapOffset + SurfaceMapStep;
  PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
end;

procedure TSputnikSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
end;

procedure TSputnikSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure TSputnikSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TSputnikTempl;
begin
  Template := SatelliteRenderTemplates[0];
  with TPlanetGI.Create(Owner) do
  begin
    SetImageFromTemplate(Template.MaskName, Self.ImagePath, Template.Radius);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;

end.
