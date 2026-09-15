{$EXCESSPRECISION OFF}
unit aGalaxyEvent;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Struct,
  aGalaxy;
type
  TGalaxyEvent = class;
  TGalaxyEvent = class(TObjectEx)
    EventType: WideString;
    Turn: Integer;
    Data: TList;
    TextData: TList;
    constructor Create(EventType: WideString);
    destructor Destroy; override;
    procedure AddData(Value: Integer);
    procedure AddTextData(Value: WideString);
    function GetData(Index: Integer): Integer;
    function GetTextData(Index: Integer): WideString;
    procedure ClearData;
    procedure ClearTextData;
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SaveToBuffer(Buffer: TBufEC);
  end;
function AddGalaxyEvent(EventType: WideString; Galaxy: TGalaxy = nil): TGalaxyEvent;
implementation
uses
  Math;

constructor TGalaxyEvent.Create(EventType: WideString);
begin
  Self.EventType := EventType;
  Turn := 0;
  Data := nil;
  TextData := nil;
end;

destructor TGalaxyEvent.Destroy;
begin
  ClearData;
  ClearTextData;
end;

procedure TGalaxyEvent.AddData(Value: Integer);
begin
  if Data = nil then
    Data := TList.Create;
  Data.Add(Pointer(Value));
end;

procedure TGalaxyEvent.AddTextData(Value: WideString);
var
  Cell: PWideString;
begin
  if TextData = nil then
    TextData := TList.Create;
  New(Cell);
  Cell^ := Value;
  TextData.Add(Cell);
end;

function TGalaxyEvent.GetData(Index: Integer): Integer;
begin
  Result := 0;
  if Data = nil then
    Exit;
  if Index < 0 then
    Exit;
  if Data.Count <= Index then
    Exit;
  Result := Integer(Data[Index]);
end;

function TGalaxyEvent.GetTextData(Index: Integer): WideString;
begin
  Result := '';
  if TextData = nil then
    Exit;
  if Index < 0 then
    Exit;
  if TextData.Count <= Index then
    Exit;
  Result := PWideString(TextData[Index])^;
end;

procedure TGalaxyEvent.ClearData;
begin
  if Data <> nil then
  begin
    Data.Clear;
    Data.Free;
    Data := nil;
  end;
end;

procedure TGalaxyEvent.ClearTextData;
var
  i, Count: Integer;
begin
  if TextData <> nil then
  begin
    Count := TextData.Count;
    for i := 0 to Count - 1 do
      Dispose(TextData[i]);
    TextData.Clear;
    TextData.Free;
    TextData := nil;
  end;
end;

procedure TGalaxyEvent.LoadFromBuffer(Buffer: TBufEC);
var
  i, Count: Integer;
  Cell: PWideString;
begin
  EventType := Buffer.ReadWideString;
  Turn := Buffer.GetInt32;
  Data := nil;
  Count := Buffer.GetInt32;
  if Count > 0 then
  begin
    Data := TList.Create;
    for i := 0 to Count - 1 do
      Data.Add(Pointer(Buffer.GetInt32));
  end;
  TextData := nil;
  Count := Buffer.GetInt32;
  if Count > 0 then
  begin
    TextData := TList.Create;
    for i := 0 to Count - 1 do
    begin
      New(Cell);
      Cell^ := Buffer.ReadWideString;
      TextData.Add(Cell);
    end;
  end;
end;

procedure TGalaxyEvent.SaveToBuffer(Buffer: TBufEC);
var
  i, Count: Integer;
begin
  Buffer.AddWideStringZ(EventType);
  Buffer.AddIntegerValue(Turn);
  if Data = nil then
    Buffer.AddIntegerValue(0)
  else
  begin
    Count := Data.Count;
    Buffer.AddIntegerValue(Count);
    for i := 0 to Count - 1 do
      Buffer.AddIntegerValue(Integer(Data[i]));
  end;
  if TextData = nil then
    Buffer.AddIntegerValue(0)
  else
  begin
    Count := TextData.Count;
    Buffer.AddIntegerValue(Count);
    for i := 0 to Count - 1 do
      Buffer.AddWideStringZ(PWideString(TextData[i])^);
  end;
end;

function AddGalaxyEvent(EventType: WideString; Galaxy: TGalaxy): TGalaxyEvent;
var
  Target: TGalaxy;
begin
  if Galaxy <> nil then
    Target := Galaxy
  else
    Target := aGalaxy.Galaxy;
  if Target = nil then
  begin
    Result := nil;
    Exit;
  end;
  Result := TGalaxyEvent.Create(EventType);
  Result.Turn := Target.CurrentTurn;
  Target.GalaxyEvents.Add(Result);
  while Target.GalaxyEvents.Count >= 10000 do
  begin
    TObject(Target.GalaxyEvents[0]).Free;
    Target.GalaxyEvents.Delete(0);
  end;
end;

end.
