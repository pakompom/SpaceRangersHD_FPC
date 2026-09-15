{$EXCESSPRECISION OFF}
unit aEFilmEnd;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  SE_Space,
  aEFilm;
type
  TEFilmEnd = class;
  PointerToTEFilmEndEntry = ^TEFilmEndEntry;
  PEFilmEndEntry = PointerToTEFilmEndEntry;
  TEFilmEndEntry = packed record
    Prev: PEFilmEndEntry;
    Next: PEFilmEndEntry;
    SceneObject: TObjectSE;
    RelatedObject1: TObjectSE;
    RelatedObject2: TObjectSE;
  end;
  TEFilmEnd = class(TObjectEx)
    FirstEntry: PEFilmEndEntry;
    LastEntry: PEFilmEndEntry;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AppendEntry: PEFilmEndEntry;
    procedure RemoveEntry(Entry: PEFilmEndEntry);
    procedure TakeTrailingEffects(Film: TEFilm);
    procedure AdvanceEffects;
    procedure ReleaseObjectReferences(Obj: TObjectSE);
    procedure RemoveLinkedWeaponEffects;
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Mem,
  GR_Main,
  SE_GAIEffect,
  SE_Hole,
  SE_Weapon;

constructor TEFilmEnd.Create;
begin
  inherited Create
end;

destructor TEFilmEnd.Destroy;
begin
  Clear;
  inherited Destroy
end;

procedure TEFilmEnd.Clear;
begin
  while FirstEntry <> nil do
    RemoveEntry(LastEntry)
end;

function TEFilmEnd.AppendEntry: PEFilmEndEntry;
var
  Entry: PEFilmEndEntry;
begin
  Entry := AllocEC(SizeOf(TEFilmEndEntry));
  if LastEntry <> nil then
    LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then
    FirstEntry := Entry;
  Entry.SceneObject := nil;
  Entry.RelatedObject1 := nil;
  Entry.RelatedObject2 := nil;
  Result := Entry;
end;

procedure TEFilmEnd.RemoveEntry(Entry: PEFilmEndEntry);
begin
  if Entry.Prev <> nil then
    Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then
    LastEntry := Entry.Prev;
  if FirstEntry = Entry then
    FirstEntry := Entry.Next;
  if Entry.SceneObject <> nil then
  begin
    Entry.SceneObject.DetachFromSpace;
    ReleaseSpaceObject(Entry.SceneObject)
  end;
  if Entry.RelatedObject1 <> nil then
  begin
    Entry.RelatedObject1.DetachFromSpace;
    ReleaseSpaceObject(Entry.RelatedObject1)
  end;
  if Entry.RelatedObject2 <> nil then
  begin
    Entry.RelatedObject2.DetachFromSpace;
    ReleaseSpaceObject(Entry.RelatedObject2)
  end;
  FreeEC(Entry);
end;

procedure TEFilmEnd.TakeTrailingEffects(Film: TEFilm);
var
  Command, FirstTrailing: PEFilmCommand;
  Obj: TEFilmObj;
  Entry: PEFilmEndEntry;
  Weapon: TWeaponSE;
begin
  FirstTrailing := Film.LastCommand;
  while FirstTrailing <> nil do
  begin
    if FirstTrailing.Kind = efcBeginTrailingEffects then
      Break;
    FirstTrailing := FirstTrailing.Prev;
  end;
  FirstTrailing := FirstTrailing.Next;
  Obj := Film.FirstObject;
  while Obj <> nil do
  begin
    if Obj.SceneObject is TGAIEffectSE then
    begin
      if TGAIEffectSE(Obj.SceneObject).Animation <> nil then
        TGAIEffectSE(Obj.SceneObject).Animation.RestartPlayback;
    end
    else if Obj.SceneObject is TWeaponSE then
    begin
      Weapon := Obj.SceneObject as TWeaponSE;
      Entry := AppendEntry;
      RetainSpaceObject(Entry.SceneObject, Weapon);
      if Weapon.TargetDestroyed then
      begin
        Command := FirstTrailing;
        while Command <> nil do
        begin
          if (Command.Kind = efcReleaseObject)
              and (PEFilmObjectCommand(Command).Obj <> nil)
              and (PEFilmObjectCommand(Command).Obj.SceneObject = Weapon.TargetObject) then
          begin
            RetainSpaceObject(Entry.RelatedObject1, PEFilmObjectCommand(Command).Obj.SceneObject);
            ReleaseSpaceObject(PEFilmObjectCommand(Command).Obj.SceneObject);
            Break;
          end;
          Command := Command.Next;
        end;
      end;
      ReleaseSpaceObject(Obj.SceneObject);
    end
    else if Obj.SceneObject is THoleSE then
    begin
      Command := FirstTrailing;
      while Command <> nil do
      begin
        if (Command.Kind = efcReleaseObject)
            and (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject = Obj.SceneObject) then
        begin
          Entry := AppendEntry;
          RetainSpaceObject(Entry.SceneObject, Obj.SceneObject);
          ReleaseSpaceObject(Obj.SceneObject);
          Break;
        end;
        Command := Command.Next;
      end;
    end;
    Obj := Obj.Next;
  end;
end;

procedure TEFilmEnd.AdvanceEffects;
var
  NextEntry, Entry: PEFilmEndEntry;
begin
  NextEntry := FirstEntry;
  while NextEntry <> nil do
  begin
    Entry := NextEntry;
    NextEntry := NextEntry.Next;
    try
      Entry.SceneObject.Advance;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
        AppendLogLineThreadSafe('Error in Event.Step');
        if Entry.SceneObject <> nil then
          AppendLogLineThreadSafe(
              'event ' + Entry.SceneObject.ClassName + ' ' + Entry.SceneObject.GraphKey
          );
        if Entry.RelatedObject1 <> nil then
          AppendLogLineThreadSafe(
              'obj ' + Entry.RelatedObject1.ClassName + ' ' + Entry.RelatedObject1.GraphKey
          );
        if Entry.RelatedObject2 <> nil then
          AppendLogLineThreadSafe(
              'obj2 ' + Entry.RelatedObject2.ClassName + ' ' + Entry.RelatedObject2.GraphKey
          );
        raise Exception.Create('Error in TEFilmEnd.Run');
      end;
    end;
    if not Entry.SceneObject.IsAttachedToSpace then
    begin
      Entry.SceneObject.DetachFromSpace;
      ReleaseSpaceObject(Entry.SceneObject);
      if Entry.RelatedObject1 <> nil then
      begin
        Entry.RelatedObject1.DetachFromSpace;
        ReleaseSpaceObject(Entry.RelatedObject1);
      end;
      if Entry.RelatedObject2 <> nil then
      begin
        Entry.RelatedObject2.DetachFromSpace;
        ReleaseSpaceObject(Entry.RelatedObject2);
      end;
      RemoveEntry(Entry);
    end;
  end;
end;

procedure TEFilmEnd.ReleaseObjectReferences(Obj: TObjectSE);
var
  Entry: PEFilmEndEntry;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if Entry.SceneObject <> nil then
      if Entry.SceneObject = Obj then
        ReleaseSpaceObject(Entry.SceneObject);
    if Entry.RelatedObject1 <> nil then
      if Entry.RelatedObject1 = Obj then
        ReleaseSpaceObject(Entry.RelatedObject1);
    if Entry.RelatedObject2 <> nil then
      if Entry.RelatedObject2 = Obj then
        ReleaseSpaceObject(Entry.RelatedObject2);
    Entry := Entry.Next;
  end;
end;

procedure TEFilmEnd.RemoveLinkedWeaponEffects;
var
  NextEntry, Entry: PEFilmEndEntry;
begin
  NextEntry := FirstEntry;
  while NextEntry <> nil do
  begin
    Entry := NextEntry;
    NextEntry := NextEntry.Next;
    if Entry.SceneObject is TWeaponSE then
      if (Entry.SceneObject as TWeaponSE).Projectile <> nil then
        RemoveEntry(Entry);
  end;
end;

procedure LinkRecoveredTypes;
begin
  TGAIEffectSE.ClassName;
  THoleSE.ClassName;
  TWeaponSE.ClassName;
end;
end.
