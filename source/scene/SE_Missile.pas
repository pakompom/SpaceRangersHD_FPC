{$EXCESSPRECISION OFF}
unit SE_Missile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_MessageLoop,
  GI_RotateImage5,
  SE_Space;
type
  TMissileSE = class;
  TMissileSE = class(TObjectSE)
    Angle: Byte;
    Gap4D: array[0..2] of Byte;
    ImageScale: Single;
    Image: TRotateImage5GI;
    AnimationTimer: PSpaceTimerSE;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    function GetAngle: Byte; override;
    procedure SetAngle(Value: Byte); override;
    function HitTestCursor: Boolean; override;
    procedure DrawMap; override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    destructor Destroy; override;
    procedure AdvanceAnimationTimer(Timer: PSpaceTimerSE; UserData: Integer);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  aMyFunction,
  SysUtils,
  Types,
  EC_Str,
  Globals,
  GR_Main,
  SE_Process;

destructor TMissileSE.Destroy;
begin
  inherited Destroy;
end;

procedure TMissileSE.AttachToSpace(ASpace: TSpaceSE);
var
  Stage: Integer;
begin
  Stage := 0;
  try
    if IsAttachedToSpace then
      Exit;
    inherited AttachToSpace(ASpace);
    Stage := 1;
    Image := TRotateImage5GI.Create(nil);
    Stage := 2;
    if Space.MapPanel <> nil then
      Space.MapPanel.AttachOwnedChild(Image);
    Stage := 3;
    Image.SetPositionModeW(True);
    Image.SetDepthByName(DepthExpression);
    Image.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
    Image.SetAngle(Angle);
    Image.SetAlpha(255);
    Stage := 4;
    Image.SetImage(
        'Bm.' + GraphKey,
        Classes.Point(Round(ImageScale * 32.0), Round(ImageScale * 32.0)),
        Classes.Point(Round(ImageScale * 16.0), Round(ImageScale * 16.0))
    );
    Stage := 5;
    Image.SetFrameIndex(0);
    AnimationTimer := Space.CreateTimer(50, 50, AdvanceAnimationTimer, 0);
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      AppendLogLineThreadSafe('TMissileSE.Connect');
      AppendLogLineThreadSafe(GraphKey);
      AppendLogLineThreadSafe('lastLabel=' + IntToWideString(RotateImageConstructionStage));
      AppendLogLineThreadSafe('self=' + UIntToStr(PtrUInt(Self)));
      AppendLogLineThreadSafe('sp=' + UIntToStr(PtrUInt(ASpace)));
      AppendLogLineThreadSafe('FSpace=' + UIntToStr(PtrUInt(Space)));
      AppendLogLineThreadSafe('FImage=' + UIntToStr(PtrUInt(Image)));
      if Space <> nil then
        AppendLogLineThreadSafe('PGI=' + UIntToStr(PtrUInt(Space.MapPanel)));
      raise Exception.Create('Error in procedure TMissileSE.Connect, label = ' + IntToStr(Stage));
    end;
  end;
end;

procedure TMissileSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then
    Exit;
  if AnimationTimer <> nil then
  begin
    Space.DeleteTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  Image.SetActive(False);
  Image.Free;
  Image := nil;
  inherited DetachFromSpace;
end;

procedure TMissileSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
    Image.SetPosition(Classes.Point(Trunc(APosition.X), Trunc(APosition.Y)));
end;

function TMissileSE.GetAngle: Byte;
begin
  Result := Angle;
end;

procedure TMissileSE.SetAngle(Value: Byte);
begin
  Angle := Value;
  if IsAttachedToSpace then
    Image.SetAngle(Angle);
end;

function TMissileSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
    Result := False
  else
    Result := Image.HitTestPixel(Image.MessageLoop.GetCursorPoint);
end;

procedure TMissileSE.AdvanceAnimationTimer(Timer: PSpaceTimerSE; UserData: Integer);
var
  Bounds: PRect;
begin
  Bounds := @Image.HitTestBounds;
  if (Cardinal(GameScreenWidth) * -0.1 <= Bounds.Right)
      and (Cardinal(GameScreenWidth) * 1.1 >= Bounds.Left)
      and (Cardinal(GameScreenHeight) * -0.1 <= Bounds.Bottom)
      and (Cardinal(GameScreenHeight) * 1.1 >= Bounds.Top) then
  begin
    Image.SetFrameIndex(Image.FrameIndex + 1);
    if Integer(Image.GetFrameCount) <= Integer(Image.FrameIndex) then
      Image.SetFrameIndex(0);
  end;
end;

procedure TMissileSE.DrawMap;
var
  CurrentProcess: TProcessSE;
  X, Y: Integer;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if PointDistanceSquared(Position, CurrentProcess.RadarCenter)
      < Sqr(CurrentProcess.RadarRange) then
  begin
    X := Round(Position.X * Space.MinimapScale) + (RenderScratchBuffer.Width shr 1);
    Y := Round(Position.Y * Space.MinimapScale) + (RenderScratchBuffer.Height shr 1);
    if (X >= 0)
        and (RenderScratchBuffer.Width > X)
        and (Y >= 0)
        and (RenderScratchBuffer.Height > Y) then
      RenderScratchBuffer.SetPixel16(X, Y, CurrentPixelFormat.PackRgbBytes(0, 255, 0));
  end;
end;

procedure TMissileSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  SetAngle(0);
  if Block.CountParams('Scale') > 0 then
    ImageScale := ExtractDecimalToSingleW(Block.GetParam('Scale'))
  else
    ImageScale := 1.0;
end;

procedure TMissileSE.ApplyConfig(Block: TBlockParEC);
begin
end;

procedure TMissileSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;

procedure LinkRecoveredTypes;
begin
  TProcessSE.ClassName;
end;
end.
