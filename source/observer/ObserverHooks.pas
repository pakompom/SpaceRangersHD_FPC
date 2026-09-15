{$EXCESSPRECISION OFF}
unit ObserverHooks;

// Host-only, optional read-only tap. No observer means no allocation or work.
interface
type
  TObserverStep = procedure(Star: TObject; Step, StepCount: Integer);
  TObserverHit =
      procedure(
          Star, Source, Target, Weapon: TObject;
          Damage: Integer;
          Color: Cardinal;
          Kind: Integer
      );
var
  ObserverStep: TObserverStep;
  ObserverHit: TObserverHit;
threadvar
  ObserverVisualRandom: Boolean;
threadvar
  VisualSeed: Cardinal;
function PresentationRandom(Limit: Integer): Integer; overload;
function PresentationRandom(Limit: Int64): Int64; overload;
implementation
// CHANGE: ENHANCEMENT - Keep observer presentation randomness separate from campaign state.
function PresentationRandom(Limit: Integer): Integer;
begin
  if not ObserverVisualRandom then
  begin
    Result := System.Random(Limit);
    Exit
  end;
  VisualSeed := VisualSeed * 1664525 + 1013904223;
  if Limit > 0 then
    Result := VisualSeed mod Cardinal(Limit)
  else
    Result := 0;
end;
// CHANGE: ENHANCEMENT - Keep observer presentation randomness separate from campaign state.
function PresentationRandom(Limit: Int64): Int64;
begin
  if not ObserverVisualRandom then
  begin
    Result := System.Random(Limit);
    Exit
  end;
  VisualSeed := VisualSeed * 1664525 + 1013904223;
  if Limit > 0 then
    Result := QWord(VisualSeed) mod QWord(Limit)
  else
    Result := 0;
end;
end.
