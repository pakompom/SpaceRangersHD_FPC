{$EXCESSPRECISION OFF}
unit fFilmFile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  aEFilm,
  EC_Buf,
  EC_Struct,
  SyncObjs;
type
  TFilmFile = class;
  PointerToTFilmHistoryEntry = ^TFilmHistoryEntry;
  PFilmHistoryEntry = PointerToTFilmHistoryEntry;
  TFilmHistoryEntry = packed record
    Prev: PFilmHistoryEntry;
    Next: PFilmHistoryEntry;
    Turn: Integer;
    Buffer: TBufEC;
  end;
  TFilmFile = class(TObjectEx)
    FirstEntry: PFilmHistoryEntry;
    LastEntry: PFilmHistoryEntry;
    Lock: TCriticalSection;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AppendEntry: PFilmHistoryEntry;
    procedure RemoveEntry(Entry: PFilmHistoryEntry);
    function GetCount: Integer;
    function GetEntry(Index: Integer): PFilmHistoryEntry;
    procedure AddFilm(Film: TEFilm);
    procedure DeleteEntry(Entry: PFilmHistoryEntry);
    procedure LoadFilm(Entry: PFilmHistoryEntry; Film: TEFilm);
    procedure SaveEntryToBuffer(Entry: PFilmHistoryEntry; Buffer: TBufEC);
    procedure LoadEntryFromBuffer(Buffer: TBufEC);
  end;
implementation
uses
  Math,
  EC_Mem,
  Globals,
  GlobalsV,
  SysUtils;

constructor TFilmFile.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
end;

destructor TFilmFile.Destroy;
begin
  Clear;
  if Lock <> nil then
  begin
    Lock.Free;
    Lock := nil;
  end;
  inherited Destroy;
end;

procedure TFilmFile.Clear;
begin
  Lock.Enter;
  while FirstEntry <> nil do
    RemoveEntry(LastEntry);
  Lock.Leave;
end;

function TFilmFile.AppendEntry: PFilmHistoryEntry;
var
  Entry: PFilmHistoryEntry;
begin
  Entry := AllocClearEC(SizeOf(TFilmHistoryEntry));
  if LastEntry <> nil then
    LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then
    FirstEntry := Entry;
  Result := Entry;
end;

procedure TFilmFile.RemoveEntry(Entry: PFilmHistoryEntry);
begin
  if Entry.Prev <> nil then
    Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then
    Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then
    LastEntry := Entry.Prev;
  if FirstEntry = Entry then
    FirstEntry := Entry.Next;
  if Entry.Buffer <> nil then
  begin
    Entry.Buffer.Free;
    Entry.Buffer := nil;
  end;
  FreeEC(Entry);
end;

function TFilmFile.GetCount: Integer;
var
  Entry: PFilmHistoryEntry;
  Count: Integer;
begin
  Lock.Enter;
  Count := 0;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
  Lock.Leave;
end;

function TFilmFile.GetEntry(Index: Integer): PFilmHistoryEntry;
var
  Entry: PFilmHistoryEntry;
begin
  Lock.Enter;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if Index = 0 then
    begin
      Result := Entry;
      Lock.Leave;
      Exit;
    end;
    Dec(Index);
    Entry := Entry.Next;
  end;
  Lock.Leave;
  raise Exception.Create('Error in TFilmFile.InfoGet');
end;

procedure TFilmFile.AddFilm(Film: TEFilm);
var
  Entry, Oldest: PFilmHistoryEntry;
  Turn: Integer;
  Buffer: TBufEC;
begin
  Buffer := nil;
  Lock.Enter;
  try
    while GetCount >= FilmHistoryLimit do
    begin
      Oldest := FirstEntry;
      Turn := Oldest.Turn;
      Entry := Oldest.Next;
      while Entry <> nil do
      begin
        if Entry.Turn < Turn then
        begin
          Turn := Entry.Turn;
          Oldest := Entry;
        end;
        Entry := Entry.Next;
      end;
      DeleteEntry(Oldest);
    end;
    Buffer := TBufEC.Create;
    Film.SaveToBuffer(Buffer);
    Buffer.SetPosition(0);
    if Buffer.DataSize < 1 then
    begin
      raise Exception.Create('Error in TFilmFile.FilmAdd');
    end;
    Entry := AppendEntry;
    Entry.Turn := Film.Turn;
    Entry.Buffer := Buffer;
    Buffer := nil; // The history entry now owns the serialized film.
  finally
    Buffer.Free;
    Lock.Leave;
  end;
end;

procedure TFilmFile.DeleteEntry(Entry: PFilmHistoryEntry);
begin
  Lock.Enter;
  RemoveEntry(Entry);
  Lock.Leave;
end;

procedure TFilmFile.LoadFilm(Entry: PFilmHistoryEntry; Film: TEFilm);
begin
  Lock.Enter;
  Entry.Buffer.SetPosition(0);
  Film.LoadFromBuffer(Entry.Buffer);
  Entry.Buffer.SetPosition(0);
  Lock.Leave;
end;

procedure TFilmFile.SaveEntryToBuffer(Entry: PFilmHistoryEntry; Buffer: TBufEC);
begin
  Buffer.Clear;
  Lock.Enter;
  Buffer.AddIntegerValue(Entry.Turn);
  Buffer.AddBuffer(Entry.Buffer);
  Lock.Leave;
end;

procedure TFilmFile.LoadEntryFromBuffer(Buffer: TBufEC);
var
  Entry: PFilmHistoryEntry;
begin
  Lock.Enter;
  Entry := AppendEntry;
  Entry.Turn := Buffer.GetInt32;
  Entry.Buffer := TBufEC.Create;
  Buffer.ReadLengthPrefixedBuffer(Entry.Buffer);
  Lock.Leave;
end;

end.
