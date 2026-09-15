{$EXCESSPRECISION OFF}
unit SE_Laser;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Str,
  EC_Struct,
  GI_MessageLoop,
  GI_RotateImage2,
  SE_Space,
  Types;
type
  TLaserSE = class;
  TLaserSE = class(TObjectSE)
    FrameImages: TStringsEC;
    FrameInterval: Cardinal;
    TargetPosition: TPointF;
    SegmentSize: Integer;
    Segments: TList;
    FrameIndex: Integer;
    AnimationTimer: PCallbackTimerGI;
    ManualAnimation: Boolean;
    Gap6D: array[0..2] of Byte;
    EndPosition: TPointF;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    procedure SetPosition(APosition: TPointF); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    destructor Destroy; override;
    procedure RebuildSegments;
    procedure ClearSegments;
    procedure UpdateSegmentImages;
    procedure StartAnimationTimer;
    procedure StopAnimationTimer;
    procedure AdvanceAnimationTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  Math,
  GI_Main;

destructor TLaserSE.Destroy;
begin
  if FrameImages <> nil then
  begin
    FrameImages.Free;
    FrameImages := nil;
  end;
  inherited Destroy;
end;

procedure TLaserSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    inherited AttachToSpace(ASpace);
    RebuildSegments;
  end;
end;

procedure TLaserSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    ClearSegments;
    inherited DetachFromSpace;
  end;
end;

procedure TLaserSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
    RebuildSegments;
end;

procedure TLaserSE.RebuildSegments;
var
  Segment: TRotateImage2GI;
  Angle, AngleSin, AngleCos, Distance, BeamLength: Double;
  ImageAngle: Integer;
begin
  ClearSegments;
  Angle := ArcTan2(TargetPosition.X - Position.X, -(TargetPosition.Y - Position.Y));
  AngleSin := Sin(Angle);
  AngleCos := Cos(Angle);
  ImageAngle := Round(Angle / 3.1415926 * 127) and $FF;
  Distance := SegmentSize / 2;
  BeamLength := Sqrt(Sqr(TargetPosition.X - Position.X) + Sqr(TargetPosition.Y - Position.Y));
  Segments := TList.Create;
  Segment := nil;
  while Distance < BeamLength do
  begin
    Segment := TRotateImage2GI.Create(Space.MapPanel);
    Segment.SetPositionModeW(True);
    Segment.SetDepthByName(DepthExpression);
    EndPosition := MakePointF(AngleSin * Distance + Position.X, Position.Y - AngleCos * Distance);
    Segment.SetPosition(TruncatePointF(EndPosition));
    Segment.SetAngle(ImageAngle);
    Segment.SetAlpha(192);
    Segment.SetImage(
        FrameImages.GetTextAt(0),
        Classes.Point(SegmentSize, SegmentSize),
        Classes.Point(SegmentSize div 2, SegmentSize div 2)
    );
    Segments.Add(Segment);
    Distance := Distance + SegmentSize - 4;
  end;
  EndPosition :=
      MakePointF(
          SegmentSize / 2 * AngleSin + EndPosition.X,
          EndPosition.Y - SegmentSize / 2 * AngleCos
      );
  FrameIndex := 0;
  UpdateSegmentImages;
  StartAnimationTimer;
end;

procedure TLaserSE.ClearSegments;
var
  Index: Integer;
  Segment: TObjectGI;
begin
  StopAnimationTimer;
  if Segments <> nil then
  begin
    for Index := 0 to Segments.Count - 1 do
    begin
      Segment := Segments[Index];
      Segment.SetActive(False);
      Space.MapPanel.FreeOwnedChild(Segment);
    end;
    Segments.Free;
    { The native routine leaves the freed list pointer unchanged. }
  end;
end;

procedure TLaserSE.UpdateSegmentImages;
var
  Index: Integer;
  Segment: TRotateImage2GI;
begin
  if (Segments <> nil)
      and (FrameIndex >= 0)
      and (FrameImages <> nil)
      and (FrameIndex < FrameImages.GetCount) then
    for Index := 0 to Segments.Count - 1 do
    begin
      Segment := Segments[Index];
      Segment.SetImage(
          FrameImages.GetTextAt(FrameIndex),
          Classes.Point(SegmentSize, SegmentSize),
          Classes.Point(SegmentSize div 2, SegmentSize div 2)
      );
    end;
end;

procedure TLaserSE.StartAnimationTimer;
begin
  StopAnimationTimer;
  if not ManualAnimation then
    AnimationTimer :=
        Space.Screen.ScheduleCallbackTimer(FrameInterval, FrameInterval, AdvanceAnimationTimer);
end;

procedure TLaserSE.StopAnimationTimer;
begin
  if AnimationTimer <> nil then
  begin
    Space.Screen.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
end;

procedure TLaserSE.AdvanceAnimationTimer(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  Inc(FrameIndex);
  if FrameIndex < FrameImages.GetCount then
    UpdateSegmentImages
  else
  begin
    FrameIndex := 0;
    UpdateSegmentImages;
  end;
end;

procedure TLaserSE.LoadTemplate(Block: TBlockParEC);
var
  Index: Integer;
begin
  inherited LoadTemplate(Block);
  if FrameImages <> nil then
  begin
    FrameImages.Free;
    FrameImages := nil;
  end;
  FrameImages := TStringsEC.Create;
  FrameInterval := ExtractDigitsToIntW(Block.GetParam('Time'));
  Index := 0;
  while Block.CountParams(IntToWideString(Index)) > 0 do
  begin
    FrameImages.Add(TrimWideString(Block.GetParam(IntToWideString(Index))));
    Inc(Index);
  end;
  SegmentSize := ExtractDigitsToIntW(Block.GetParam('RadiusUnit'));
end;

procedure TLaserSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('PosDes') > 0 then
    TargetPosition := PointToPointF(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('ManualAnim') > 0 then
    ManualAnimation := ParseEnabledNameGI(Block.GetParam('ManualAnim'));
end;

procedure TLaserSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Index, Count: Integer;
  Segment: TRotateImage2GI;
begin
  Segment := TRotateImage2GI.Create(Owner);
  Count := FrameImages.GetCount;
  for Index := 0 to Count - 1 do
  begin
    Segment.SetImage(
        FrameImages.GetTextAt(Index),
        Classes.Point(SegmentSize, SegmentSize),
        Classes.Point(SegmentSize div 2, SegmentSize div 2)
    );
    Segment.QueueImageLoad(PendingLoads);
  end;
  Segment.Free;
end;

end.
