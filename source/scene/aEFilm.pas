{$EXCESSPRECISION OFF}
unit aEFilm;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Str,
  EC_Struct,
  SE_Process,
  SE_Space,
  Types,
  aEObjInfo;
const
  efcSetObjectPosition = 0;
  efcSetObjectOrbitCenter = 1;
  efcSetObjectAlpha = 2;
  efcSetObjectAngle = 3;
  efcAdvanceObject = 4;
  efcAdvanceObjects = 5;
  efcSetPlanetState = 6;
  efcSetShipSizeAndTailMode = 7;
  efcSetWeaponHit = 8;
  efcSetWeaponEndpoints = 9;
  efcSetDestructionEffect = 10;
  efcAttachObject = 11;
  efcDetachObject = 12;
  efcReleaseObject = 13;
  efcReleaseWeaponEffects = 14;
  efcSetViewCenter = 15;
  efcSetRadarCenter = 16;
  efcSetCameraAnchor = 17;
  efcOpenGate = 18;
  efcCloseGate = 19;
  efcSetGateState = 20;
  efcSetHoleState = 21;
  efcSetObjectText = 22;
  efcSetObjectStateBuffer = 23;
  efcBeginTrailingEffects = 24;
  efcPlayPickupSound = 25;
  efcSetRuinsState = 26;
  efcSetGateSize = 27;
  efcPlayObjectSound = 28;
  efcSetGateEffectSize = 29;
  efcSetEffectImagePosition = 30;
  efcSetEffectDurationScale = 31;
  FilmNullObjectIndex = 65535;
type
  TEFilm = class;
  TEFilmObj = class;
  PointerToTEFilmByteCommand = ^TEFilmByteCommand;
  PointerToTEFilmCameraEventArray = ^TEFilmCameraEventArray;
  PointerToTEFilmCommand = ^TEFilmCommand;
  PointerToTEFilmEndpointsCommand = ^TEFilmEndpointsCommand;
  PointerToTEFilmHitCommand = ^TEFilmHitCommand;
  PointerToTEFilmObjectCommand = ^TEFilmObjectCommand;
  PointerToTEFilmSizeCommand = ^TEFilmSizeCommand;
  PointerToTEFilmVectorCommand = ^TEFilmVectorCommand;
  TEFilmObj = class(TObject)
    Prev: TEFilmObj;
    Next: TEFilmObj;
    ObjectId: Cardinal;
    SceneObject: TObjectSE;
    KindName: WideString;
    GraphKey: WideString;
  end;
  PEFilmCommand = PointerToTEFilmCommand;
  TEFilmCommand = packed record
    Prev: PEFilmCommand;
    Next: PEFilmCommand;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Payload: array[0..3 * SizeOf(Pointer) + 3] of Byte;
  end;
  PEFilmObjectCommand = PointerToTEFilmObjectCommand;
  TEFilmObjectCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Value: Integer;
    ExtraValue: Integer;
    Flags: Integer;
  end;
  PEFilmVectorCommand = PointerToTEFilmVectorCommand;
  TEFilmVectorCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Position: TPointF;
    ForceMovement: Boolean;
    Gap1D: array[0..2] of Byte;
  end;
  PEFilmSizeCommand = PointerToTEFilmSizeCommand;
  TEFilmSizeCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Size: TPoint;
    TailMode: Integer;
  end;
  PEFilmByteCommand = PointerToTEFilmByteCommand;
  TEFilmByteCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Value: Byte;
    Gap15: array[0..10] of Byte;
  end;
  PEFilmHitCommand = PointerToTEFilmHitCommand;
  TEFilmHitCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Color: Word;
    Gap16: array[0..1] of Byte;
    Damage: Integer;
    Destroyed: Boolean;
    PlaySound: Boolean;
    Gap1E: array[0..1] of Byte;
  end;
  PEFilmEndpointsCommand = PointerToTEFilmEndpointsCommand;
  TEFilmEndpointsCommand = packed record
    Links: array[0..1] of Pointer;
    Kind: Byte;
    Gap9: array[0..2] of Byte;
    StepIndex: Integer;
    Obj: TEFilmObj;
    Source: TEFilmObj;
    Target: TEFilmObj;
    Gap1C: array[0..3] of Byte;
  end;
  TEFilmCameraEvent = packed record
    StepIndex: Integer;
    Priority: Integer;
    StartPosition: TPointF;
    EndPosition: TPointF;
  end;
  PEFilmCameraEventArray = PointerToTEFilmCameraEventArray;
  TEFilmCameraEventArray = array[0..0] of TEFilmCameraEvent;
  TEFilm = class(TObjectEx)
    FirstObject: TEFilmObj;
    LastObject: TEFilmObj;
    FirstCommand: PEFilmCommand;
    LastCommand: PEFilmCommand;
    FirstFreeCommand: PEFilmCommand;
    LastFreeCommand: PEFilmCommand;
    CameraEvents: array of TEFilmCameraEvent;
    CameraEventCount: Integer;
    StringTable: TStringsEC;
    DataBuffers: TList;
    SystemProcessName: WideString;
    MapDiameter: Integer;
    RadarRange: Integer;
    Turn: Integer;
    PlayerCombatRecorded: Boolean;
    Gap3D: array[0..2] of Byte;
    BackgroundImage: Integer;
    StarGenerationSeed: Cardinal;
    InitialActivity: Integer;
    FinalActivity: Integer;
    CameraAnchor: TPointF;
    ForceCameraMovement: Boolean;
    Gap59: array[0..2] of Byte;
    ObjectInfo: TObject;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ReserveCameraEventSlot;
    procedure AddCameraEvent(
        AStepIndex: Integer;
        AStartPosition: TPointF;
        AEndPosition: TPointF;
        APriority: Integer
    );
    function AllocateObject: TEFilmObj;
    procedure RemoveObject(Obj: TEFilmObj);
    function ObjectCount: Integer;
    function ObjToNom(Obj: TEFilmObj): Integer;
    function FindObjectIndex(Obj: TEFilmObj): Integer;
    function NomToObj(Index: Integer): TEFilmObj;
    function ContainsObject(Obj: TEFilmObj): Boolean;
    function FindObject(
        const KindName: WideString;
        const GraphKey: WideString;
        ObjectId: Cardinal
    ): TEFilmObj;
    function FindObjectById(const KindName: WideString; ObjectId: Cardinal): TEFilmObj;
    procedure GrowCommandPool(Count: Integer);
    procedure RecycleCommands(First: PEFilmCommand; Last: PEFilmCommand);
    procedure AppendCommand(Command: PEFilmCommand);
    procedure InsertCommand(Before: PEFilmCommand; Command: PEFilmCommand);
    function AllocateCommand: PEFilmCommand;
    function AddCommand(StepIndex: Integer): PEFilmCommand;
    function CommandCount: Integer;
    function AddObject(
        ObjectId: Cardinal;
        SceneObject: TObjectSE;
        Unused1: Integer = 0;
        Unused2: Integer = 0
    ): TEFilmObj;
    procedure SetObjectPosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
    procedure SetObjectOrbitCenter(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
    procedure SetObjectAlpha(StepIndex: Integer; Obj: TEFilmObj; Alpha: Byte);
    procedure SetObjectAngle(StepIndex: Integer; Obj: TEFilmObj; Angle: Byte);
    procedure AdvanceObjects(StepIndex: Integer);
    procedure SetPlanetState(
        StepIndex: Integer;
        Obj: TEFilmObj;
        RotationInterval: Integer;
        SurfaceMapStep: Integer;
        ScaleThousandths: Word;
        RingKind: Byte;
        Owner: Byte
    );
    procedure SetShipSizeAndTailMode(
        StepIndex: Integer;
        Obj: TEFilmObj;
        Size: TPoint;
        TailMode: Integer
    );
    procedure SetRuinsState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
    procedure SetWeaponHit(
        StepIndex: Integer;
        Obj: TEFilmObj;
        Color: Word;
        Damage: Integer;
        Destroyed: Boolean;
        PlaySound: Boolean
    );
    procedure SetWeaponEndpoints(
        StepIndex: Integer;
        Obj: TEFilmObj;
        Source: TEFilmObj;
        Target: TEFilmObj
    );
    procedure SetDestructionEffect(StepIndex: Integer; Obj: TEFilmObj; Value: Integer);
    procedure SetEffectImagePosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPoint);
    procedure SetEffectDurationScale(StepIndex: Integer; Obj: TEFilmObj; Scale: Single);
    procedure AttachObject(StepIndex: Integer; Obj: TEFilmObj);
    procedure DetachObject(StepIndex: Integer; Obj: TEFilmObj);
    procedure ReleaseObject(StepIndex: Integer; Obj: TEFilmObj);
    procedure ReleaseWeaponEffects(StepIndex: Integer);
    procedure SetViewCenter(StepIndex: Integer; Position: TPointF);
    procedure SetRadarCenter(StepIndex: Integer; Position: TPointF);
    procedure SetCameraAnchor(StepIndex: Integer; Position: TPointF; ForceMovement: Boolean);
    procedure OpenGate(StepIndex: Integer; Obj: TEFilmObj);
    procedure CloseGate(StepIndex: Integer; Obj: TEFilmObj);
    procedure SetGateState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
    procedure SetGateSize(StepIndex: Integer; Obj: TEFilmObj; Size: Integer);
    procedure SetGateEffectSize(StepIndex: Integer; Obj: TEFilmObj; Size: Integer);
    procedure SetHoleState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
    procedure SetObjectText(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString);
    procedure PlayObjectSound(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString);
    procedure SetObjectStateBuffer(StepIndex: Integer; Obj: TEFilmObj; Buffer: TBufEC);
    procedure BeginTrailingEffects(StepIndex: Integer);
    procedure PlayPickupSound(StepIndex: Integer; Obj: TEFilmObj);
    procedure ExecuteCommand(Process: TProcessSE; Command: PEFilmCommand; ReplayMode: Boolean);
    procedure ReleaseWeaponSceneObjects;
    procedure ReleaseObjectReferences(Obj: TObjectSE);
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
  end;
const
  FilmFormatVersion: Integer = 6;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  SysUtils,
  EC_Mem,
  GR_Main,
  GR_DX,
  GR_GraphBuf,
  SE_Weapon,
  SE_Planet,
  SE_Ship2,
  SE_Ruins,
  SE_Gate,
  SE_Hole,
  SE_GAIEffect,
  Globals,
  GlobalsV,
  aPlayer,
  aMyFunction,
  fFilm,
  fStarMap;

constructor TEFilm.Create;
begin
  inherited Create;
  StringTable := TStringsEC.Create;
  DataBuffers := TList.Create;
  ObjectInfo := TEObjInfo.Create;
end;

destructor TEFilm.Destroy;
var
  NextCommand, Command: PEFilmCommand;
begin
  Clear;
  NextCommand := FirstFreeCommand;
  while NextCommand <> nil do
  begin
    Command := NextCommand;
    NextCommand := NextCommand.Next;
    FreeEC(Command);
  end;
  FirstFreeCommand := nil;
  LastFreeCommand := nil;
  if StringTable <> nil then
  begin
    StringTable.Free;
    StringTable := nil
  end;
  if DataBuffers <> nil then
  begin
    DataBuffers.Free;
    DataBuffers := nil
  end;
  if ObjectInfo <> nil then
  begin
    ObjectInfo.Free;
    ObjectInfo := nil
  end;
  CameraEvents := nil;
  inherited Destroy;
end;

procedure TEFilm.Clear;
var
  I, Count: Integer;
  Obj: TObject;
begin
  if FirstCommand <> nil then
    RecycleCommands(FirstCommand, LastCommand);
  while FirstObject <> nil do
    RemoveObject(LastObject);
  StringTable.Clear;
  Count := DataBuffers.Count;
  for I := 0 to Count - 1 do
  begin
    Obj := TObject(DataBuffers[I]);
    Obj.Free;
  end;
  DataBuffers.Clear;
  CameraEventCount := 0;
end;

procedure TEFilm.ReserveCameraEventSlot;
begin
  if High(CameraEvents) <= CameraEventCount then
    SetLength(CameraEvents, CameraEventCount + 30);
  Inc(CameraEventCount);
end;

procedure TEFilm.AddCameraEvent(
    AStepIndex: Integer;
    AStartPosition, AEndPosition: TPointF;
    APriority: Integer
);
begin
  if High(CameraEvents) <= CameraEventCount then
    SetLength(CameraEvents, CameraEventCount + 30);
  with CameraEvents[CameraEventCount] do
  begin
    StepIndex := AStepIndex;
    Priority := APriority;
    StartPosition := AStartPosition;
    EndPosition := AEndPosition;
  end;
  Inc(CameraEventCount);
end;

function TEFilm.AllocateObject: TEFilmObj;
var
  Obj: TEFilmObj;
begin
  try
    Obj := TEFilmObj.Create
  except
    Obj := nil
  end;
  if Obj = nil then
  begin
    AppendLogTextThreadSafe(
        'Failed to allocate memory for film object, trying to free some textures... '
    );
    EvictTextureCaches(True);
    try
      Obj := TEFilmObj.Create
    except
      Obj := nil
    end;
    if Obj <> nil then
      AppendLogLineThreadSafe('success')
    else
    begin
      AppendLogLineThreadSafe('fail');
      raise Exception.Create('Error in TEFilm.ObjAlloc');
    end;
  end;
  if LastObject <> nil then
    LastObject.Next := Obj;
  Obj.Prev := LastObject;
  Obj.Next := nil;
  LastObject := Obj;
  if FirstObject = nil then
    FirstObject := Obj;
  Result := Obj;
end;

procedure TEFilm.RemoveObject(Obj: TEFilmObj);
begin
  if Obj.Prev <> nil then
    Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then
    Obj.Next.Prev := Obj.Prev;
  if LastObject = Obj then
    LastObject := Obj.Prev;
  if FirstObject = Obj then
    FirstObject := Obj.Next;
  ReleaseSpaceObject(Obj.SceneObject);
  Obj.Free;
end;

function TEFilm.ObjectCount: Integer;
var
  Count: Integer;
  Entry: TEFilmObj;
begin
  Count := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
end;

function TEFilm.ObjToNom(Obj: TEFilmObj): Integer;
var
  Index: Integer;
  Entry: TEFilmObj;
begin
  if Obj = nil then
  begin
    Result := FilmNullObjectIndex;
    Exit
  end;
  Index := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry = Obj then
    begin
      Result := Index;
      Exit
    end;
    Inc(Index);
    Entry := Entry.Next;
  end;
  raise Exception.Create('Error in TEFilm.ObjToNom');
  Result := -1; // Retained after the native raise.
end;

function TEFilm.FindObjectIndex(Obj: TEFilmObj): Integer;
var
  Index: Integer;
  Entry: TEFilmObj;
begin
  if Obj = nil then
  begin
    Result := FilmNullObjectIndex;
    Exit
  end;
  Index := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry = Obj then
    begin
      Result := Index;
      Exit
    end;
    Inc(Index);
    Entry := Entry.Next;
  end;
  Result := -1;
end;

function TEFilm.NomToObj(Index: Integer): TEFilmObj;
var
  Entry: TEFilmObj;
begin
  if Index = FilmNullObjectIndex then
  begin
    Result := nil;
    Exit
  end;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Index = 0 then
    begin
      Result := Entry;
      Exit
    end;
    Dec(Index);
    Entry := Entry.Next;
  end;
  raise Exception.Create('Error in TEFilm.NomToObj');
  Result := nil; // Retained after the native raise.
end;

function TEFilm.ContainsObject(Obj: TEFilmObj): Boolean;
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Obj = Entry then
    begin
      Result := True;
      Exit
    end;
    Entry := Entry.Next;
  end;
  Result := False;
end;

function TEFilm.FindObject(const KindName, GraphKey: WideString; ObjectId: Cardinal): TEFilmObj;
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if (Entry.ObjectId = ObjectId)
        and (Entry.KindName = KindName)
        and (Entry.GraphKey = GraphKey) then
    begin
      Result := Entry;
      Exit
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;

function TEFilm.FindObjectById(const KindName: WideString; ObjectId: Cardinal): TEFilmObj;
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if (Entry.ObjectId = ObjectId) and (Entry.KindName = KindName) then
    begin
      Result := Entry;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;

procedure TEFilm.GrowCommandPool(Count: Integer);
var
  Command: PEFilmCommand;
begin
  while Count > 0 do
  begin
    Command := AllocEC(SizeOf(TEFilmCommand));
    if LastFreeCommand <> nil then
      LastFreeCommand.Next := Command;
    Command.Prev := LastFreeCommand;
    Command.Next := nil;
    LastFreeCommand := Command;
    if FirstFreeCommand = nil then
      FirstFreeCommand := Command;
    Dec(Count);
  end;
end;

procedure TEFilm.RecycleCommands(First, Last: PEFilmCommand);
begin
  if First.Prev <> nil then
    First.Prev.Next := Last.Next;
  if Last.Next <> nil then
    Last.Next.Prev := First.Prev;
  if Last = LastCommand then
    LastCommand := First.Prev;
  if First = FirstCommand then
    FirstCommand := Last.Next;
  if LastFreeCommand <> nil then
    LastFreeCommand.Next := First;
  First.Prev := LastFreeCommand;
  Last.Next := nil;
  LastFreeCommand := Last;
  if FirstFreeCommand = nil then
    FirstFreeCommand := First;
end;

procedure TEFilm.AppendCommand(Command: PEFilmCommand);
begin
  if LastCommand <> nil then
    LastCommand.Next := Command;
  Command.Prev := LastCommand;
  Command.Next := nil;
  LastCommand := Command;
  if FirstCommand = nil then
    FirstCommand := Command;
end;

procedure TEFilm.InsertCommand(Before, Command: PEFilmCommand);
begin
  if Before <> nil then
  begin
    Command.Prev := Before.Prev;
    Command.Next := Before;
    if Before.Prev <> nil then
      Before.Prev.Next := Command;
    Before.Prev := Command;
    if Before = FirstCommand then
      FirstCommand := Command;
  end
  else
  begin
    if LastCommand <> nil then
      LastCommand.Next := Command;
    Command.Prev := LastCommand;
    Command.Next := nil;
    LastCommand := Command;
    if FirstCommand = nil then
      FirstCommand := Command;
  end;
end;

function TEFilm.AllocateCommand: PEFilmCommand;
var
  Command: PEFilmCommand;
begin
  if FirstFreeCommand = LastFreeCommand then
    GrowCommandPool(500);
  Command := FirstFreeCommand;
  Command.Next.Prev := nil;
  FirstFreeCommand := Command.Next;
  FillChar(Command^, SizeOf(TEFilmCommand), 0);
  Result := Command;
end;

function TEFilm.AddCommand(StepIndex: Integer): PEFilmCommand;
var
  Command, Entry: PEFilmCommand;
begin
  Command := AllocateCommand;
  Command.StepIndex := StepIndex;
  if (LastCommand = nil) or (LastCommand.StepIndex <= StepIndex) then
  begin
    AppendCommand(Command);
    Result := Command;
  end
  else
  begin
    Entry := FirstCommand;
    while Entry <> nil do
    begin
      if Entry.StepIndex > StepIndex then
      begin
        InsertCommand(Entry, Command);
        Break;
      end;
      Entry := Entry.Next;
    end;
    if Entry = nil then
      AppendCommand(Command);
    Result := Command;
  end;
end;

function TEFilm.CommandCount: Integer;
var
  Count: Integer;
  Entry: PEFilmCommand;
begin
  Count := 0;
  Entry := FirstCommand;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
end;

function TEFilm.AddObject(
    ObjectId: Cardinal;
    SceneObject: TObjectSE;
    Unused1, Unused2: Integer
): TEFilmObj;
var
  Obj: TEFilmObj;
begin
  Obj := AllocateObject;
  Obj.ObjectId := ObjectId;
  RetainSpaceObject(Obj.SceneObject, SceneObject);
  Obj.KindName := ClassSEtoName(SceneObject);
  Obj.GraphKey := SceneObject.GraphKey;
  Result := Obj;
end;

procedure TEFilm.SetObjectPosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
var
  Command: PEFilmVectorCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmVectorCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectPosition;
  Command.Obj := Obj;
  Command.Position := Position;
end;

procedure TEFilm.SetObjectOrbitCenter(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
var
  Command: PEFilmVectorCommand;
begin
  Command := PEFilmVectorCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectOrbitCenter;
  Command.Obj := Obj;
  Command.Position := Position;
end;

procedure TEFilm.SetObjectAlpha(StepIndex: Integer; Obj: TEFilmObj; Alpha: Byte);
var
  Command: PEFilmByteCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmByteCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectAlpha;
  Command.Obj := Obj;
  Command.Value := Alpha;
end;

procedure TEFilm.SetObjectAngle(StepIndex: Integer; Obj: TEFilmObj; Angle: Byte);
var
  Command: PEFilmByteCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmByteCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectAngle;
  Command.Obj := Obj;
  Command.Value := Angle;
end;

procedure TEFilm.AdvanceObjects(StepIndex: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcAdvanceObjects;
end;

procedure TEFilm.SetPlanetState(
    StepIndex: Integer;
    Obj: TEFilmObj;
    RotationInterval, SurfaceMapStep: Integer;
    ScaleThousandths: Word;
    RingKind, Owner: Byte
);
var
  Command: PEFilmObjectCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetPlanetState;
  Command.Obj := Obj;
  Command.Value := (Integer(RingKind) shl 24) or RotationInterval;
  Command.ExtraValue := SurfaceMapStep;
  Command.Flags := ScaleThousandths or (Integer(Owner) shl 24);
end;

procedure TEFilm.SetShipSizeAndTailMode(
    StepIndex: Integer;
    Obj: TEFilmObj;
    Size: TPoint;
    TailMode: Integer
);
var
  Command: PEFilmSizeCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmSizeCommand(AddCommand(StepIndex));
  Command.Kind := efcSetShipSizeAndTailMode;
  Command.Obj := Obj;
  Command.Size := Size;
  Command.TailMode := TailMode;
end;

procedure TEFilm.SetRuinsState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
var
  Command: PEFilmObjectCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetRuinsState;
  Command.Obj := Obj;
  Command.Value := State;
end;

procedure TEFilm.SetWeaponHit(
    StepIndex: Integer;
    Obj: TEFilmObj;
    Color: Word;
    Damage: Integer;
    Destroyed, PlaySound: Boolean
);
var
  Command: PEFilmHitCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmHitCommand(AddCommand(StepIndex));
  Command.Kind := efcSetWeaponHit;
  Command.Obj := Obj;
  Command.Color := Color;
  Command.Damage := Damage;
  Command.Destroyed := Destroyed;
  Command.PlaySound := PlaySound;
end;

procedure TEFilm.SetWeaponEndpoints(StepIndex: Integer; Obj, Source, Target: TEFilmObj);
var
  Command: PEFilmEndpointsCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmEndpointsCommand(AddCommand(StepIndex));
  Command.Kind := efcSetWeaponEndpoints;
  Command.Obj := Obj;
  Command.Source := Source;
  Command.Target := Target;
end;

procedure TEFilm.SetDestructionEffect(StepIndex: Integer; Obj: TEFilmObj; Value: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetDestructionEffect;
  Command.Obj := Obj;
  Command.Value := Value;
end;

procedure TEFilm.SetEffectImagePosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPoint);
var
  Command: PEFilmSizeCommand;
begin
  Command := PEFilmSizeCommand(AddCommand(StepIndex));
  Command.Kind := efcSetEffectImagePosition;
  Command.Obj := Obj;
  Command.Size := Position;
end;

procedure TEFilm.SetEffectDurationScale(StepIndex: Integer; Obj: TEFilmObj; Scale: Single);
var
  Command: PEFilmObjectCommand;
  ScaleBits: Integer absolute Scale;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetEffectDurationScale;
  Command.Obj := Obj;
  // Copy the Single payload without floating-point conversion or rounding.
  Command.Value := ScaleBits;
end;

procedure TEFilm.AttachObject(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcAttachObject;
  Command.Obj := Obj;
end;

procedure TEFilm.DetachObject(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  if Obj = nil then
    raise Exception.Create('obj=nil');
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcDetachObject;
  Command.Obj := Obj;
end;

procedure TEFilm.ReleaseObject(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcReleaseObject;
  Command.Obj := Obj;
end;

procedure TEFilm.ReleaseWeaponEffects(StepIndex: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcReleaseWeaponEffects;
end;

procedure TEFilm.SetViewCenter(StepIndex: Integer; Position: TPointF);
var
  Command: PEFilmVectorCommand;
begin
  Command := PEFilmVectorCommand(AddCommand(StepIndex));
  Command.Kind := efcSetViewCenter;
  Command.Position := Position;
end;

procedure TEFilm.SetRadarCenter(StepIndex: Integer; Position: TPointF);
var
  Command: PEFilmVectorCommand;
begin
  Command := PEFilmVectorCommand(AddCommand(StepIndex));
  Command.Kind := efcSetRadarCenter;
  Command.Position := Position;
end;

procedure TEFilm.SetCameraAnchor(StepIndex: Integer; Position: TPointF; ForceMovement: Boolean);
var
  Command: PEFilmVectorCommand;
begin
  Command := PEFilmVectorCommand(AddCommand(StepIndex));
  Command.Kind := efcSetCameraAnchor;
  Command.Position := Position;
  Command.ForceMovement := ForceMovement;
end;

procedure TEFilm.OpenGate(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcOpenGate;
  Command.Obj := Obj;
end;

procedure TEFilm.CloseGate(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcCloseGate;
  Command.Obj := Obj;
end;

procedure TEFilm.SetGateState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetGateState;
  Command.Obj := Obj;
  Command.Value := State;
end;

procedure TEFilm.SetGateSize(StepIndex: Integer; Obj: TEFilmObj; Size: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetGateSize;
  Command.Obj := Obj;
  Command.Value := Size;
end;

procedure TEFilm.SetGateEffectSize(StepIndex: Integer; Obj: TEFilmObj; Size: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetGateEffectSize;
  Command.Obj := Obj;
  Command.Value := Size;
end;

procedure TEFilm.SetHoleState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetHoleState;
  Command.Obj := Obj;
  Command.Value := State;
end;

procedure TEFilm.SetObjectText(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectText;
  Command.Obj := Obj;
  StringTable.Add(Text);
  Command.Value := StringTable.GetCount - 1;
end;

procedure TEFilm.PlayObjectSound(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcPlayObjectSound;
  Command.Obj := Obj;
  StringTable.Add(Text);
  Command.Value := StringTable.GetCount - 1;
end;

procedure TEFilm.SetObjectStateBuffer(StepIndex: Integer; Obj: TEFilmObj; Buffer: TBufEC);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcSetObjectStateBuffer;
  Command.Obj := Obj;
  DataBuffers.Add(Buffer);
  Command.Value := DataBuffers.Count - 1;
end;

procedure TEFilm.BeginTrailingEffects(StepIndex: Integer);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcBeginTrailingEffects;
end;

procedure TEFilm.PlayPickupSound(StepIndex: Integer; Obj: TEFilmObj);
var
  Command: PEFilmObjectCommand;
begin
  Command := PEFilmObjectCommand(AddCommand(StepIndex));
  Command.Kind := efcPlayPickupSound;
  Command.Obj := Obj;
end;

procedure TEFilm.ExecuteCommand(Process: TProcessSE; Command: PEFilmCommand; ReplayMode: Boolean);
var
  Obj: TEFilmObj;
  Source, Target: TObjectSE;
  ErrorStep: Integer;
  Ship: TShip2SE;
  Ruins: TRuinsSE;
begin
  { Process is unused in the native routine; playback uses the global SpaceProcess. }
  ErrorStep := 0;
  try
    case Command.Kind of
      efcSetObjectPosition:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command)
              .Obj
              .SceneObject
              .SetPosition(PEFilmVectorCommand(Command).Position);
      efcSetObjectOrbitCenter:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command)
              .Obj
              .SceneObject
              .SetOrbitCenter(PEFilmVectorCommand(Command).Position);
      efcSetObjectAlpha:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command).Obj.SceneObject.SetAlpha(PEFilmByteCommand(Command).Value);
      efcSetObjectAngle:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command).Obj.SceneObject.SetAngle(PEFilmByteCommand(Command).Value);
      efcAdvanceObject:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command).Obj.SceneObject.Advance;
      efcAdvanceObjects:
      begin
        Obj := Self.FirstObject;
        while Obj <> nil do
        begin
          if Obj.SceneObject <> nil then
            Obj.SceneObject.Advance;
          Obj := Obj.Next;
        end;
      end;
      efcSetPlanetState:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TPlanetSE) then
        begin
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE)
              .SetRotationTimerInterval(PEFilmObjectCommand(Command).Value and $FFFFFF);
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE)
              .SetRingKind(PEFilmObjectCommand(Command).Value shr 24);
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE)
              .SetSurfaceMapStep(PEFilmObjectCommand(Command).ExtraValue);
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE).OrbitalVelocity :=
              SmallInt(PEFilmObjectCommand(Command).Flags and $FFFF) / 1000;
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE)
              .SetMinimapOwner(PEFilmObjectCommand(Command).Flags shr 24);
          (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE).Civilized :=
              (PEFilmObjectCommand(Command).Obj.SceneObject as TPlanetSE).MinimapOwner <> 6;
        end;
      efcSetShipSizeAndTailMode:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TShip2SE) then
        begin
          Ship := PEFilmObjectCommand(Command).Obj.SceneObject as TShip2SE;
          Ship.SetSize(PEFilmSizeCommand(Command).Size);
          if (ShipTail = 2)
              or ((ShipTail = 1)
                  and (GetPlayer <> nil)
                  and (GetPlayer.Id = Integer(PEFilmObjectCommand(Command).Obj.ObjectId))) then
            Ship.SetTailMode(PEFilmSizeCommand(Command).TailMode)
          else
            Ship.SetTailMode(0);
        end;
      efcSetRuinsState:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TRuinsSE) then
        begin
          Ruins := PEFilmObjectCommand(Command).Obj.SceneObject as TRuinsSE;
          Ruins.SetState(PEFilmObjectCommand(Command).Value);
        end;
      efcSetWeaponHit:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TWeaponSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TWeaponSE)
              .SetHit(
                  PEFilmHitCommand(Command).Color,
                  PEFilmHitCommand(Command).Damage,
                  PEFilmHitCommand(Command).Destroyed,
                  PEFilmHitCommand(Command).PlaySound);
      efcSetWeaponEndpoints:
      begin
        { Both endpoint scene-object tests are repeated in the native code. }
        Source := nil;
        if (PEFilmEndpointsCommand(Command).Source <> nil)
            and (PEFilmEndpointsCommand(Command).Source.SceneObject <> nil)
            and (PEFilmEndpointsCommand(Command).Source.SceneObject <> nil) then
          Source := PEFilmEndpointsCommand(Command).Source.SceneObject;
        Target := nil;
        if (PEFilmEndpointsCommand(Command).Target <> nil)
            and (PEFilmEndpointsCommand(Command).Target.SceneObject <> nil)
            and (PEFilmEndpointsCommand(Command).Target.SceneObject <> nil) then
          Target := PEFilmEndpointsCommand(Command).Target.SceneObject;
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TWeaponSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TWeaponSE).SetEndpoints(Source, Target);
      end;
      efcSetDestructionEffect:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TWeaponSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TWeaponSE).DestructionEffect :=
              PEFilmObjectCommand(Command).Value;
      efcSetEffectImagePosition:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGAIEffectSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGAIEffectSE)
              .SetImagePosition(PEFilmSizeCommand(Command).Size);
      efcSetEffectDurationScale:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGAIEffectSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGAIEffectSE)
              .SetDurationScale(PEFilmVectorCommand(Command).Position.X);
      efcAttachObject:
      begin
        ErrorStep := 1;
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
        begin
          ErrorStep := 2;
          if PEFilmObjectCommand(Command).Obj.SceneObject is TShip2SE then
          begin
            ErrorStep := 3;
            with PEFilmObjectCommand(Command).Obj.SceneObject as TShip2SE do
            begin
              ErrorStep := 4;
              if ((ShipTail <> 2)
                      and ((ShipTail <> 1)
                          or (GetPlayer = nil)
                          or (GetPlayer.Id <> Integer(PEFilmObjectCommand(Command).Obj.ObjectId))))
                  or (TailMode <= 0) then
                SetTailMode(0);
            end;
          end;
          ErrorStep := 5;
          PEFilmObjectCommand(Command).Obj.SceneObject.AttachToSpace(SpaceProcess.Space);
        end;
      end;
      efcDetachObject:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command).Obj.SceneObject.DetachFromSpace;
      efcReleaseObject:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
        begin
          PEFilmObjectCommand(Command).Obj.SceneObject.DetachFromSpace;
          ReleaseSpaceObject(PEFilmObjectCommand(Command).Obj.SceneObject);
        end;
      efcReleaseWeaponEffects:
      begin
        Obj := Self.FirstObject;
        while Obj <> nil do
        begin
          if (Obj.SceneObject <> nil) and (Obj.SceneObject is TWeaponSE) then
          begin
            Obj.SceneObject.DetachFromSpace;
            ReleaseSpaceObject(Obj.SceneObject);
          end;
          Obj := Obj.Next;
        end;
      end;
      efcSetViewCenter:
        if ReplayMode then
          FilmScreen.FollowViewOffset(TruncatePointF(PEFilmVectorCommand(Command).Position))
        else
          StarMapScreen.SetMapCenter(TruncatePointF(PEFilmVectorCommand(Command).Position));
      efcSetRadarCenter:
      begin
        if ReplayMode then
          FilmScreen.CameraTarget := PEFilmVectorCommand(Command).Position;
        SpaceProcess.RadarCenter := PEFilmVectorCommand(Command).Position;
      end;
      efcSetCameraAnchor:
      begin
        CameraAnchor := PEFilmVectorCommand(Command).Position;
        ForceCameraMovement := PEFilmVectorCommand(Command).ForceMovement;
      end;
      efcOpenGate:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGateSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGateSE).Open;
      efcCloseGate:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGateSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGateSE).Close;
      efcSetGateState:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGateSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGateSE)
              .SetState(PEFilmObjectCommand(Command).Value);
      efcSetGateSize:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGateSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGateSE)
              .SetSize(
                  Classes.Point(
                      PEFilmObjectCommand(Command).Value,
                      PEFilmObjectCommand(Command).Value
                  ));
      efcSetGateEffectSize:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is TGateEffectSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as TGateEffectSE)
              .SetSize(
                  Classes.Point(
                      PEFilmObjectCommand(Command).Value,
                      PEFilmObjectCommand(Command).Value
                  ));
      efcSetHoleState:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject is THoleSE) then
          (PEFilmObjectCommand(Command).Obj.SceneObject as THoleSE)
              .SetState(PEFilmObjectCommand(Command).Value);
      efcSetObjectText:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command)
              .Obj
              .SceneObject
              .SetText(StringTable.GetTextAt(PEFilmObjectCommand(Command).Value));
      efcPlayObjectSound:
        if FilmSoundEffectsEnabled
            and SoundInSpaceEnabled
            and (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject.Space <> nil)
            and PEFilmObjectCommand(Command)
                .Obj
                .SceneObject
                .Space
                .ContainsMapPoint(PEFilmObjectCommand(Command).Obj.SceneObject.Position) then
          SoundManager.PlaySound(StringTable.GetTextAt(PEFilmObjectCommand(Command).Value));
      efcSetObjectStateBuffer:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil) then
          PEFilmObjectCommand(Command)
              .Obj
              .SceneObject
              .LoadStateBuffer(TBufEC(DataBuffers[PEFilmObjectCommand(Command).Value]));
      efcPlayPickupSound:
        if (PEFilmObjectCommand(Command).Obj <> nil)
            and (PEFilmObjectCommand(Command).Obj.SceneObject <> nil)
            and SoundInSpaceEnabled
            and SpaceProcess.Space.ContainsMapPoint(
                PEFilmObjectCommand(Command).Obj.SceneObject.Position) then
          SoundManager.PlaySound('Sound.Take');
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      AppendLogLineThreadSafe(
          'Error in procedure TEFilm.RunOrder, order = '
              + IntToStr(Command.Kind)
              + ', label = '
              + IntToStr(ErrorStep)
      );
      if PEFilmObjectCommand(Command).Obj <> nil then
      begin
        AppendLogLineThreadSafe(PEFilmObjectCommand(Command).Obj.KindName);
        AppendLogLineThreadSafe(PEFilmObjectCommand(Command).Obj.GraphKey);
        if PEFilmObjectCommand(Command).Obj.SceneObject <> nil then
          AppendLogLineThreadSafe(PEFilmObjectCommand(Command).Obj.SceneObject.GraphKey);
      end;
      raise Exception.Create(
          'Error in procedure TEFilm.RunOrder, order = '
              + IntToStr(Command.Kind)
              + ', label = '
              + IntToStr(ErrorStep));
    end;
  end;
end;

procedure TEFilm.ReleaseWeaponSceneObjects;
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry.SceneObject <> nil then
      if Entry.SceneObject is TWeaponSE then
      begin
        Entry.SceneObject.DetachFromSpace;
        ReleaseSpaceObject(Entry.SceneObject);
      end;
    Entry := Entry.Next;
  end;
end;

procedure TEFilm.ReleaseObjectReferences(Obj: TObjectSE);
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry.SceneObject <> nil then
      if Entry.SceneObject = Obj then
      begin
        ReleaseSpaceObject(Entry.SceneObject);
        Entry.ObjectId := 0;
        Entry.KindName := '';
        Entry.GraphKey := '';
      end;
    Entry := Entry.Next;
  end;
end;

procedure TEFilm.SaveToBuffer(Buffer: TBufEC);
var
  Obj: TEFilmObj;
  Command: PEFilmCommand;
  I, Count: Integer;
  Data: TBufEC;
  ObjectIndex: Integer;
begin
  Buffer.Clear;
  Buffer.AddWideStringZ(SystemProcessName);
  Buffer.AddIntegerValue(MaxInt);
  Buffer.AddIntegerValue(FilmFormatVersion);
  Buffer.AddIntegerValue(MapDiameter);
  Buffer.AddIntegerValue(RadarRange);
  Buffer.AddBoolean(PlayerCombatRecorded);
  Buffer.AddDWord(StarGenerationSeed);
  Buffer.AddIntegerValue(BackgroundImage);
  Buffer.AddDWord(InitialActivity);
  Buffer.AddDWord(FinalActivity);
  Buffer.AddSingle(CameraAnchor.X);
  Buffer.AddSingle(CameraAnchor.Y);
  Count := StringTable.GetCount;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
    Buffer.AddWideStringZ(StringTable.GetTextAt(I));
  Count := DataBuffers.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Data := TBufEC(DataBuffers[I]);
    Buffer.AddBuffer(Data);
  end;
  Buffer.AddWideChar(WideChar(ObjectCount));
  Obj := FirstObject;
  while Obj <> nil do
  begin
    Buffer.AddDWord(Obj.ObjectId);
    Buffer.AddWideStringZ(Obj.KindName);
    Buffer.AddWideStringZ(Obj.GraphKey);
    Obj := Obj.Next;
  end;
  Buffer.AddDWord(CommandCount);
  Command := FirstCommand;
  while Command <> nil do
  begin
    Buffer.AddAnsiChar(AnsiChar(Command.Kind));
    Buffer.AddWideChar(WideChar(Command.StepIndex));
    if Command.Kind = efcSetObjectPosition then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetObjectOrbitCenter then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetObjectAlpha then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmByteCommand(Command).Value));
    end
    else if Command.Kind = efcSetObjectAngle then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmByteCommand(Command).Value));
    end
    else if Command.Kind = efcAdvanceObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcAdvanceObjects then
    begin
    end
    else if Command.Kind = efcSetPlanetState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).ExtraValue);
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Flags);
    end
    else if Command.Kind = efcSetShipSizeAndTailMode then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddWideChar(WideChar(PEFilmSizeCommand(Command).Size.X));
      Buffer.AddWideChar(WideChar(PEFilmSizeCommand(Command).Size.Y));
      Buffer.AddAnsiChar(AnsiChar(PEFilmSizeCommand(Command).TailMode));
    end
    else if Command.Kind = efcSetRuinsState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmObjectCommand(Command).Value));
    end
    else if Command.Kind = efcSetWeaponHit then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackRed(PEFilmHitCommand(Command).Color)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackGreen(PEFilmHitCommand(Command).Color)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackBlue(PEFilmHitCommand(Command).Color)));
      Buffer.AddIntegerValue(PEFilmHitCommand(Command).Damage);
      Buffer.AddBoolean(PEFilmHitCommand(Command).Destroyed);
      Buffer.AddBoolean(PEFilmHitCommand(Command).PlaySound);
    end
    else if Command.Kind = efcSetWeaponEndpoints then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      ObjectIndex := FindObjectIndex(PEFilmEndpointsCommand(Command).Source);
      if ObjectIndex = -1 then
      begin
        ObjectIndex := FilmNullObjectIndex;
        PEFilmEndpointsCommand(Command).Source := nil;
      end;
      Buffer.AddWideChar(WideChar(ObjectIndex));
      ObjectIndex := FindObjectIndex(PEFilmEndpointsCommand(Command).Target);
      if ObjectIndex = -1 then
      begin
        ObjectIndex := FilmNullObjectIndex;
        PEFilmEndpointsCommand(Command).Target := nil;
      end;
      Buffer.AddWideChar(WideChar(ObjectIndex));
    end
    else if Command.Kind = efcSetDestructionEffect then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmObjectCommand(Command).Value));
    end
    else if Command.Kind = efcSetEffectImagePosition then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmSizeCommand(Command).Size.X);
      Buffer.AddIntegerValue(PEFilmSizeCommand(Command).Size.Y);
    end
    else if Command.Kind = efcSetEffectDurationScale then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
    end
    else if Command.Kind = efcAttachObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcDetachObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcReleaseObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcReleaseWeaponEffects then
    begin
    end
    else if Command.Kind = efcSetViewCenter then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetRadarCenter then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetCameraAnchor then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
      Buffer.AddBoolean(PEFilmVectorCommand(Command).ForceMovement);
    end
    else if Command.Kind = efcOpenGate then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcCloseGate then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcSetGateState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetGateSize then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetGateEffectSize then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetHoleState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddBoolean(Boolean(PEFilmObjectCommand(Command).Value));
    end
    else if Command.Kind = efcSetObjectText then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcPlayObjectSound then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetObjectStateBuffer then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcBeginTrailingEffects then
    begin
    end
    else if Command.Kind = efcPlayPickupSound then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end;
    Command := Command.Next;
  end;
  Buffer.AddIntegerValue(CameraEventCount);
  for I := 0 to CameraEventCount - 1 do
    with CameraEvents[I] do
    begin
      Buffer.AddIntegerValue(StepIndex);
      Buffer.AddIntegerValue(Priority);
      Buffer.AddSingle(StartPosition.X);
      Buffer.AddSingle(StartPosition.Y);
      Buffer.AddSingle(EndPosition.X);
      Buffer.AddSingle(EndPosition.Y);
    end;
  (ObjectInfo as TEObjInfo).SaveToBuffer(Buffer);
end;

procedure TEFilm.LoadFromBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Obj: TEFilmObj;
  Command: PEFilmCommand;
  Red, Green, Blue: Byte;
  Data: TBufEC;
  Version: Integer;
begin
  Version := 0;
  Clear;
  Buffer.SetPosition(0);
  SystemProcessName := Buffer.ReadWideString;
  MapDiameter := Buffer.GetInt32;
  if MapDiameter = MaxInt then
  begin
    Version := Buffer.GetInt32;
    MapDiameter := Buffer.GetInt32;
  end;
  RadarRange := Buffer.GetInt32;
  PlayerCombatRecorded := Buffer.GetBoolean;
  StarGenerationSeed := Buffer.GetUInt32;
  if Version >= 2 then
    BackgroundImage := Buffer.GetInt32
  else
    BackgroundImage := 0;
  InitialActivity := Buffer.GetUInt32;
  FinalActivity := Buffer.GetUInt32;
  CameraAnchor.X := Buffer.GetSingle;
  CameraAnchor.Y := Buffer.GetSingle;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
    StringTable.Add(Buffer.ReadWideString);
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Data := TBufEC.Create;
    Buffer.ReadLengthPrefixedBuffer(Data);
    DataBuffers.Add(Data);
  end;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Obj := AllocateObject;
    Obj.ObjectId := Buffer.GetUInt32;
    Obj.KindName := Buffer.ReadWideString;
    Obj.GraphKey := Buffer.ReadWideString;
    Obj.SceneObject := nil;
  end;
  Count := Buffer.GetUInt32;
  for I := 0 to Count - 1 do
  begin
    Command := AllocateCommand;
    AppendCommand(Command);
    Command.Kind := Buffer.GetByte;
    Command.StepIndex := Buffer.GetWord;
    if Command.Kind = efcSetObjectPosition then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetObjectOrbitCenter then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetObjectAlpha then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmByteCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcSetObjectAngle then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmByteCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcAdvanceObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcAdvanceObjects then
    begin
    end
    else if Command.Kind = efcSetPlanetState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
      PEFilmObjectCommand(Command).ExtraValue := Buffer.GetInt32;
      PEFilmObjectCommand(Command).Flags := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetShipSizeAndTailMode then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmSizeCommand(Command).Size.X := Buffer.GetWord;
      PEFilmSizeCommand(Command).Size.Y := Buffer.GetWord;
      PEFilmSizeCommand(Command).TailMode := Buffer.GetByte;
    end
    else if Command.Kind = efcSetRuinsState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcSetWeaponHit then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      Red := Buffer.GetByte;
      Green := Buffer.GetByte;
      Blue := Buffer.GetByte;
      PEFilmHitCommand(Command).Color := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
      PEFilmHitCommand(Command).Damage := Buffer.GetInt32;
      PEFilmHitCommand(Command).Destroyed := Buffer.GetBoolean;
      PEFilmHitCommand(Command).PlaySound := Buffer.GetBoolean;
    end
    else if Command.Kind = efcSetWeaponEndpoints then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmEndpointsCommand(Command).Source := NomToObj(Buffer.GetWord);
      PEFilmEndpointsCommand(Command).Target := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcSetDestructionEffect then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcSetEffectImagePosition then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmSizeCommand(Command).Size.X := Buffer.GetInt32;
      PEFilmSizeCommand(Command).Size.Y := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetEffectDurationScale then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
    end
    else if Command.Kind = efcAttachObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcDetachObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcReleaseObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcReleaseWeaponEffects then
    begin
    end
    else if Command.Kind = efcSetViewCenter then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetRadarCenter then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetCameraAnchor then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
      PEFilmVectorCommand(Command).ForceMovement := Buffer.GetBoolean;
    end
    else if Command.Kind = efcOpenGate then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcCloseGate then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcSetGateState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetGateSize then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetGateEffectSize then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetHoleState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Ord(Buffer.GetBoolean);
    end
    else if Command.Kind = efcSetObjectText then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcPlayObjectSound then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetObjectStateBuffer then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcBeginTrailingEffects then
    begin
    end
    else if Command.Kind = efcPlayPickupSound then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end;
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    ReserveCameraEventSlot;
    with CameraEvents[CameraEventCount - 1] do
    begin
      StepIndex := Buffer.GetInt32;
      Priority := Buffer.GetInt32;
      StartPosition.X := Buffer.GetSingle;
      StartPosition.Y := Buffer.GetSingle;
      EndPosition.X := Buffer.GetSingle;
      EndPosition.Y := Buffer.GetSingle;
    end;
  end;
  if Version > 0 then
    (ObjectInfo as TEObjInfo).LoadFromBuffer(Buffer, Version)
  else
    (ObjectInfo as TEObjInfo).Clear;
end;

procedure LinkRecoveredTypes;
begin
  TEObjInfo.ClassName;
  TGAIEffectSE.ClassName;
  TGateEffectSE.ClassName;
  TGateSE.ClassName;
  THoleSE.ClassName;
  TPlanetSE.ClassName;
  TRuinsSE.ClassName;
  TShip2SE.ClassName;
  TWeaponSE.ClassName;
end;
end.
