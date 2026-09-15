{$EXCESSPRECISION OFF}
unit MessageText;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar;
type
  TQuestMessages = class;
  TQuestMessages = class(TObject)
    Entries: TBlockParEC;
    constructor Create;
    destructor Destroy; override;
    function GetText(Path: WideString): WideString;
    function GetTextOrKey(Key: WideString): WideString;
  end;
var
  QuestMessages: TQuestMessages;
implementation
uses
  Math,
  EC_Str;

constructor TQuestMessages.Create;
begin
  inherited Create;
  Entries := TBlockParEC.Create;
end;

destructor TQuestMessages.Destroy;
begin
  if Entries <> nil then
  begin
    Entries.Free;
    Entries := nil;
  end;
  inherited Destroy;
end;

function TQuestMessages.GetText(Path: WideString): WideString;
var
  i, PartCount: Integer;
  Name: WideString;
  Block: TBlockParEC;
begin
  Result := Path;
  PartCount := CountDelimitedPartsW(Path, '.');
  Block := Entries;
  for i := 0 to PartCount - 2 do
  begin
    Name := ExtractDelimitedPartW(Path, i, '.');
    if Block.CountBlocks(Name) <= 0 then
      Exit;
    Block := Block.GetBlock(Name);
  end;
  Name := ExtractDelimitedPartW(Path, PartCount - 1, '.');
  Result := Block.GetParam(Name);
end;

function TQuestMessages.GetTextOrKey(Key: WideString): WideString;
begin
  if Entries.CountParams(Key) > 0 then
    Result := Entries.GetParam(Key)
  else
    Result := Key;
end;

end.
