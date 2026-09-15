{$EXCESSPRECISION OFF}
unit SequenceClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Struct;
type
  TSequence = class;
  TSequence = class(TObjectEx)
    UnknownFlag: Byte;
    Gap5: array[0..2] of Byte;
    TraversalLimit: Integer;
    Locations: TList;
    Paths: TList;
    constructor Create;
    destructor Destroy; override;
    procedure SetTraversalLimit(Value: Integer);
    procedure RecomputeTraversalLimit;
    procedure AddLocation(Location: Pointer);
    procedure AddPath(Path: Pointer);
    procedure PrependPath(Path: Pointer);
  end;
implementation
uses
  Math,
  LocationClass,
  PathClass;

constructor TSequence.Create;
begin
  inherited Create;
  Locations := TList.Create;
  Paths := TList.Create;
  TraversalLimit := 0;
  UnknownFlag := 0;
end;

destructor TSequence.Destroy;
var
  i: Integer;
  Location: TLocation;
  Path: TPath;
begin
  for i := 0 to Locations.Count - 1 do
  begin
    Location := TLocation(Locations[i]);
    Location.Sequence := nil;
  end;
  for i := 0 to Paths.Count - 1 do
  begin
    Path := TPath(Paths[i]);
    Path.Sequence := nil;
  end;
  Locations.Clear;
  Locations.Free;
  Locations := nil;
  Paths.Clear;
  Paths.Free;
  Paths := nil;
  inherited Destroy;
end;

procedure TSequence.SetTraversalLimit(Value: Integer);
var
  i: Integer;
  Location: TLocation;
  Path: TPath;
begin
  TraversalLimit := Value;
  for i := 0 to Locations.Count - 1 do
  begin
    Location := TLocation(Locations[i]);
    Location.VisitLimit := TraversalLimit;
  end;
  for i := 0 to Paths.Count - 1 do
  begin
    Path := TPath(Paths[i]);
    Path.TraversalLimit := TraversalLimit;
  end;
end;

procedure TSequence.RecomputeTraversalLimit;
var
  i: Integer;
  Location: TLocation;
  Path: TPath;
begin
  TraversalLimit := 0;
  for i := 0 to Locations.Count - 1 do
  begin
    Location := TLocation(Locations[i]);
    if Location.VisitLimit > 0 then
      if (TraversalLimit = 0) or (Location.VisitLimit < TraversalLimit) then
        TraversalLimit := Location.VisitLimit;
  end;
  for i := 0 to Paths.Count - 1 do
  begin
    Path := TPath(Paths[i]);
    if Path.TraversalLimit > 0 then
      if (TraversalLimit = 0) or (Path.TraversalLimit < TraversalLimit) then
        TraversalLimit := Path.TraversalLimit;
  end;
  SetTraversalLimit(TraversalLimit);
end;

procedure TSequence.AddLocation(Location: Pointer);
var
  Member: TLocation;
begin
  Member := Location;
  Locations.Add(Location);
  Member.Sequence := Self;
end;

procedure TSequence.AddPath(Path: Pointer);
var
  Member: TPath;
begin
  Member := Path;
  Paths.Add(Path);
  Member.Sequence := Self;
end;

procedure TSequence.PrependPath(Path: Pointer);
var
  Member: TPath;
begin
  Member := Path;
  Paths.Insert(0, Path);
  Member.Sequence := Self;
end;

end.
