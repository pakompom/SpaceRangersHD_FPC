{$EXCESSPRECISION OFF}
unit SearchBookmarks;

interface

uses
  Globals,
  aGalaxy;

function ResolveSearchBookmarkTarget(
    Message: TMessagePlayer;
    Star: TStar;
    out Target: TPlayerMessageTarget
): Boolean;

implementation

uses
  Classes,
  SysUtils,
  EC_Str,
  aPlanet,
  aShip,
  aRuins;

// CHANGE: ENHANCEMENT - Resolve the destination stored in a saved search result.
function ResolveSearchBookmarkTarget(
    Message: TMessagePlayer;
    Star: TStar;
    out Target: TPlayerMessageTarget
): Boolean;
var
  Reference: QWord;
  Lines: TStringList;
  I: Integer;
  Planet: TPlanet;
  Ship: TShip;
  function HasLocationValue(const Name: WideString): Boolean;
  var
    N, Colon: Integer;
    Line: WideString;
  begin
    Result := False;
    if Name = '' then
      Exit;
    for N := 0 to Lines.Count - 1 do
    begin
      Line := UTF8Decode(Lines[N]);
      Colon := Pos(':', Line);
      if (Colon > 0) and (Trim(Copy(Line, Colon + 1, MaxInt)) = Name) then
        Exit(True);
    end;
  end;
begin
  FillChar(Target, SizeOf(Target), 0);
  Result := False;
  if (Message = nil) or (Message.Kind <> 7) then
    Exit;
  if Copy(Message.Key, 1, 6) = 'GOODS ' then
  begin
    if not TryStrToQWord(Copy(Message.Key, 7, MaxInt), Reference)
        or (Reference > High(Cardinal))
        or ((Reference and $7FFFFFFF) = 0) then
      Exit;
    if (Reference and $80000000) <> 0 then
      Target.ShipId := Cardinal(Reference) and $7FFFFFFF
    else
      Target.PlanetId := Cardinal(Reference);
    Exit(True);
  end;
  // Older equipment bookmarks contain only the rendered location text.
  if (Message.Key <> '') or (Star = nil) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.CaseSensitive := True;
    Lines.Text := UTF8Encode(RemoveTextTagsW(Message.Text));
    // Compare the complete saved value, independently of the current UI language.
    if not HasLocationValue(Star.Name) then
      Exit;
    for I := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[I]);
      if HasLocationValue(Planet.Name) then
      begin
        Target.PlanetId := Planet.Id;
        Exit(True);
      end;
    end;
    for I := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[I]);
      if (Ship is TRuins)
          and (Lines.IndexOf(UTF8Encode(RemoveTextTagsW(Ship.GetFullName(' ')))) >= 0) then
      begin
        Target.ShipId := Ship.Id;
        Exit(True);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

end.
