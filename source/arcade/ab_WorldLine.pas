{$EXCESSPRECISION OFF}
unit ab_WorldLine;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_PolyLine;
type
  PointerToTabWorldLine = ^TabWorldLine;
  PabWorldLine = PointerToTabWorldLine;
  TabWorldLine = record
    Prev: PabWorldLine;
    Next: PabWorldLine;
    First: TVector3D;
    Last: TVector3D;
    Segment: PPolyLineSegmentGI;
    Kind: Integer;
    FrontColor: Cardinal;
    BackColor: Cardinal;
    FrontEndColor: Cardinal;
    BackEndColor: Cardinal;
    ShowBehindSphere: Boolean;
    Gap51: array[0..6] of Byte;
  end;
var
  WorldLineHeap: Cardinal = 0;
  FirstWorldLine: PabWorldLine = nil;
  LastWorldLine: PabWorldLine = nil;
procedure ab_WorldLine_Clear;
function ab_WorldLine_Add: PabWorldLine;
procedure ab_WorldLine_Delete(Line: PabWorldLine);
function ab_WorldLine_Create(
    First: TVector3D;
    Last: TVector3D;
    Kind: Integer;
    FrontColor: Cardinal;
    BackColor: Cardinal;
    ShowBehindSphere: Boolean
): PabWorldLine;
procedure ab_WorldLine_Set(
    Line: PabWorldLine;
    First: TVector3D;
    Last: TVector3D;
    Kind: Integer;
    FrontColor: Cardinal;
    BackColor: Cardinal;
    ShowBehindSphere: Boolean
);
procedure ab_WorldLine_Update;
implementation
uses
  Math,
  Windows,
  Classes,
  SysUtils,
  EC_Mem,
  GI_Tail,
  ab_Global,
  Globals;

procedure ab_WorldLine_Clear;
begin
  while not (FirstWorldLine = nil) do
    ab_WorldLine_Delete(LastWorldLine);
  if WorldLineHeap <> 0 then
  begin
    HeapDestroy(WorldLineHeap);
    WorldLineHeap := 0;
  end;
end;

function ab_WorldLine_Add: PabWorldLine;
var
  Line: PabWorldLine;
begin
  if WorldLineHeap = 0 then
  begin
    WorldLineHeap := HeapCreate(1, $8000, 0);
    if WorldLineHeap = 0 then
      raise Exception.Create('ab_WorldLine_Add.HeapCreate');
  end;
  Line := AllocClearFromHeapEC(WorldLineHeap, SizeOf(TabWorldLine));
  if LastWorldLine <> nil then
    LastWorldLine.Next := Line;
  Line.Prev := LastWorldLine;
  Line.Next := nil;
  LastWorldLine := Line;
  if FirstWorldLine = nil then
    FirstWorldLine := Line;
  Result := Line;
end;

procedure ab_WorldLine_Delete(Line: PabWorldLine);
begin
  if Line.Prev <> nil then
    Line.Prev.Next := Line.Next;
  if Line.Next <> nil then
    Line.Next.Prev := Line.Prev;
  if LastWorldLine = Line then
    LastWorldLine := Line.Prev;
  if FirstWorldLine = Line then
    FirstWorldLine := Line.Next;
  if Line.Segment <> nil then
  begin
    ArcadeBattleScreen.WorldLines.RetireSegment(Line.Segment);
    Line.Segment := nil;
  end;
  if WorldLineHeap <> 0 then
    FreeFromHeapEC(WorldLineHeap, Line);
end;

function ab_WorldLine_Create(
    First, Last: TVector3D;
    Kind: Integer;
    FrontColor, BackColor: Cardinal;
    ShowBehindSphere: Boolean
): PabWorldLine;
var
  Line: PabWorldLine;
begin
  Line := ab_WorldLine_Add;
  Line.First := First;
  Line.Last := Last;
  Line.FrontColor := FrontColor;
  Line.BackColor := BackColor;
  Line.Kind := Kind;
  Line.ShowBehindSphere := ShowBehindSphere;
  Result := Line;
end;

procedure ab_WorldLine_Set(
    Line: PabWorldLine;
    First, Last: TVector3D;
    Kind: Integer;
    FrontColor, BackColor: Cardinal;
    ShowBehindSphere: Boolean
);
begin
  Line.First := First;
  Line.Last := Last;
  Line.FrontColor := FrontColor;
  Line.BackColor := BackColor;
  if Line.Kind <> Kind then
  begin
    Line.Kind := Kind;
    if Line.Segment <> nil then
    begin
      ArcadeBattleScreen.WorldLines.RetireSegment(Line.Segment);
      Line.Segment := nil;
    end;
  end;
  Line.ShowBehindSphere := ShowBehindSphere;
end;

procedure ab_WorldLine_Update;
var
  Line: PabWorldLine;
  Behind: Boolean;
  First, Last, Center: TVector3D;
begin
  Center := MakeVector3D(0, 0, 0);
  Center := ProjectPointByMatrix(SphereProjectionMatrix, Center);
  Line := FirstWorldLine;
  while Line <> nil do
  begin
    if Line.Kind = 0 then
    begin
      Line := Line.Next;
      Continue;
    end;
    First := ProjectPointByMatrix(SphereProjectionMatrix, Line.First);
    Last := ProjectPointByMatrix(SphereProjectionMatrix, Line.Last);
    Behind := not IsDepthBeforeSphereHorizon(First.Z) or not IsDepthBeforeSphereHorizon(Last.Z);
    if Behind and not Line.ShowBehindSphere then
    begin
      if Line.Segment <> nil then
      begin
        ArcadeBattleScreen.WorldLines.RetireSegment(Line.Segment);
        Line.Segment := nil;
      end;
    end
    else
    begin
      if Line.Segment = nil then
      begin
        Line.Segment :=
            ArcadeBattleScreen.WorldLines.AddLine(
                Classes.Point(Round(First.X), Round(First.Y)),
                Classes.Point(Round(Last.X), Round(Last.Y)),
                Line.FrontColor
            );
        Line.Segment.Animated := Line.Kind = 2;
        if Line.Kind < 3 then
          Line.Segment.Kind := 0
        else if Line.Kind = 3 then
          Line.Segment.Kind := 1
        else
          Line.Segment.Kind := 2;
      end
      else
      begin
        Line.Segment.First.X := Round(First.X);
        Line.Segment.First.Y := Round(First.Y);
        Line.Segment.Last.X := Round(Last.X);
        Line.Segment.Last.Y := Round(Last.Y);
        ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Line.Segment);
      end;
      if Behind then
      begin
        Line.Segment.Color := Line.BackColor;
        Line.Segment.EndColor := Line.BackEndColor;
      end
      else
      begin
        Line.Segment.Color := Line.FrontColor;
        Line.Segment.EndColor := Line.FrontEndColor;
      end;
    end;
    Line := Line.Next;
  end;
end;

end.
