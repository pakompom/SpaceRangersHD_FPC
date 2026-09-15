{$EXCESSPRECISION OFF}
unit ObserverEffects;

// Replays native weapon visuals from immutable simulation events. Endpoints
// belong to this renderer, never to the worker or to a live game ship.
interface
uses
  Classes,
  Contnrs,
  ObserverCapture,
  SE_Space,
  SE_Weapon;
type
  TObserverEffectPlayer = class
    Data: TObserverSystem;
    Space: TSpaceSE;
    Active: Contnrs.TObjectList;
    NextEvent, Spawned: Integer;
    constructor Create(ASpace: TSpaceSE);
    destructor Destroy; override;
    procedure Bind(AData: TObserverSystem);
    procedure Update(Progress: Double; Still: Boolean; Zoom: Double);
  end;
implementation
uses
  Math,
  SysUtils,
  Types,
  EC_Struct;
type
  TLiveEffect = class
    Graphic: TWeaponSE;
    StartStep: Double;
    Age: Integer;
    SourceKey, TargetKey: AnsiString;
    destructor Destroy; override;
  end;
destructor TLiveEffect.Destroy;
begin
  Graphic.Free;
  inherited Destroy
end;
constructor TObserverEffectPlayer.Create(ASpace: TSpaceSE);
begin
  inherited Create;
  Space := ASpace;
  Active := Contnrs.TObjectList.Create(True)
end;
destructor TObserverEffectPlayer.Destroy;
begin
  Active.Free;
  inherited Destroy
end;
procedure TObserverEffectPlayer.Bind(AData: TObserverSystem);
var
  I: Integer;
begin
  for I := 0 to Active.Count - 1 do
    TLiveEffect(Active[I]).StartStep := TLiveEffect(Active[I]).StartStep - 200;
  Data := AData;
  NextEvent := 0;
end;
procedure TObserverEffectPlayer.Update(Progress: Double; Still: Boolean; Zoom: Double);
var
  E: TObserverEffect;
  L: TLiveEffect;
  A, B: TObjectSE;
  I, TargetAge: Integer;
  Time: Double;
  procedure PositionEndpoint(Obj: TObjectSE; const Key: AnsiString);
  var
    Track: TObserverTrack;
    P: TObserverPose;
  begin
    if (Obj = nil) or (Key = '') then
      Exit;
    Track := TObserverTrack(Data.Tracks.Find(Key));
    if Track = nil then
      Exit;
    P := SampleObserverPose(Track, Progress, Data.Steps, False);
    if P.Visible then
      Obj.SetPosition(P.Position);
  end;
begin
  if Still then
    Exit;
  Time := Progress * 200;
  while NextEvent < Data.Effects.Count do
  begin
    E := TObserverEffect(Data.Effects[NextEvent]);
    if E.AtTime * 200 > Time then
      Break;
    Inc(NextEvent);
    if Time - E.AtTime * 200 > 160 then
      Continue;
    L := TLiveEffect.Create;
    Active.Add(L);
    L.StartStep := E.AtTime * 200;
    L.SourceKey := E.SourceKey;
    L.TargetKey := E.TargetKey;
    L.Graphic := TWeaponSE.Create(E.GraphKey, Point(0, 0), E.Palette, -1);
    A := TObjectSE.CreateEmpty;
    B := TObjectSE.CreateEmpty;
    A.SetPosition(E.SourcePosition);
    B.SetPosition(E.TargetPosition);
    B.SetSize(E.TargetSize);
    L.Graphic.SetEndpoints(A, B); // Effect owns both refcounted endpoint proxies.
    L.Graphic.SetPosition(E.TargetPosition);
    L.Graphic.DestructionEffect := E.Destruction;
    if Zoom >= 0.45 then
      L.Graphic.SetHit(E.Color, E.Damage, E.Destroyed, False)
    else
      L.Graphic.SetHit(0, E.Damage, E.Destroyed, False);
    L.Graphic.AttachToSpace(Space);
    Inc(Spawned);
  end;
  for I := Active.Count - 1 downto 0 do
  begin
    L := TLiveEffect(Active[I]);
    PositionEndpoint(L.Graphic.SourceObject, L.SourceKey);
    PositionEndpoint(L.Graphic.TargetObject, L.TargetKey);
    TargetAge := Floor(Time - L.StartStep);
    while (L.Age < TargetAge) and L.Graphic.IsAttachedToSpace do
    begin
      L.Graphic.Advance;
      Inc(L.Age)
    end;
    if not L.Graphic.IsAttachedToSpace or (TargetAge > 300) then
      Active.Delete(I);
  end;
end;
end.
