{$EXCESSPRECISION OFF}
unit SE_SoundRnd;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  EC_BlockPar;
type
  TSoundRndSE = class;
  TSoundRndUnitSE = record
    Weight: Integer;
    Group: Integer;
    NextTimeMin: Integer;
    NextTimeMax: Integer;
    SoundNames: array of WideString;
    SoundWeights: array of Integer;
    TotalSoundWeight: Integer;
  end;
  TSoundRndSE = class(TObjectEx)
    Prev: TSoundRndSE;
    Next: TSoundRndSE;
    Name: WideString;
    Groups: array of TSoundRndUnitSE;
    TotalGroupWeight: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromBlock(Block: TBlockParEC);
    function SelectSound(GroupIndex: Integer): WideString;
  end;
var
  FirstRandomSound: TSoundRndSE = nil;
  LastRandomSound: TSoundRndSE = nil;
function CreateRandomSound: TSoundRndSE;
procedure FreeRandomSound(Sound: TSoundRndSE);
procedure FreeAllRandomSounds;
function FindRandomSound(Name: WideString; var GroupIndex: Integer): TSoundRndSE;
implementation
uses
  Math,
  EC_Str,
  GR_Main,
  aMyFunction;

function CreateRandomSound: TSoundRndSE;
var
  Sound: TSoundRndSE;
begin
  Sound := TSoundRndSE.Create;
  if LastRandomSound <> nil then
    LastRandomSound.Next := Sound;
  Sound.Prev := LastRandomSound;
  Sound.Next := nil;
  LastRandomSound := Sound;
  if FirstRandomSound = nil then
    FirstRandomSound := Sound;
  Result := Sound;
end;

procedure FreeRandomSound(Sound: TSoundRndSE);
begin
  if Sound.Prev <> nil then
    Sound.Prev.Next := Sound.Next;
  if Sound.Next <> nil then
    Sound.Next.Prev := Sound.Prev;
  if LastRandomSound = Sound then
    LastRandomSound := Sound.Prev;
  if FirstRandomSound = Sound then
    FirstRandomSound := Sound.Next;
  Sound.Free;
end;

procedure FreeAllRandomSounds;
begin
  while not (FirstRandomSound = nil) do
    FreeRandomSound(LastRandomSound);
end;

function FindRandomSound(Name: WideString; var GroupIndex: Integer): TSoundRndSE;
var
  Sound: TSoundRndSE;
  Index: Integer;
begin
  Sound := FirstRandomSound;
  while Sound <> nil do
  begin
    if Sound.Name = Name then
      Break;
    Sound := Sound.Next;
  end;
  if Sound = nil then
  begin
    Sound := CreateRandomSound;
    Sound.Name := Name;
    Sound.LoadFromBlock(GameDataConfig.GetBlockByPath('SE.Sound.Rnd.' + Name));
  end;
  if Sound.TotalGroupWeight < 1 then
    GroupIndex := -1
  else
  begin
    GroupIndex := RandomIntRange(0, Sound.TotalGroupWeight - 1);
    Index := 0;
    while True do
    begin
      Dec(GroupIndex, Sound.Groups[Index].Weight);
      if GroupIndex < 0 then
      begin
        GroupIndex := Index;
        Break;
      end;
      Inc(Index);
    end;
  end;
  Result := Sound;
end;

constructor TSoundRndSE.Create;
begin
  inherited Create;
end;

destructor TSoundRndSE.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TSoundRndSE.Clear;
var
  Index: Integer;
begin
  for Index := 0 to High(Groups) do
  begin
    Groups[Index].SoundWeights := nil;
    Groups[Index].SoundNames := nil;
  end;
  Groups := nil;
end;

procedure TSoundRndSE.LoadFromBlock(Block: TBlockParEC);
var
  Index, Count, ParamIndex, ParamCount, SoundIndex, SoundCount: Integer;
  GroupBlock: TBlockParEC;
  Text: WideString;
begin
  TotalGroupWeight := 0;
  Count := Block.GetBlockCount;
  SetLength(Groups, Count);
  for Index := 0 to Count - 1 do
  begin
    GroupBlock := Block.GetBlockByIndex(Index);
    Groups[Index].Weight := ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index));
    Inc(TotalGroupWeight, Groups[Index].Weight);
    Groups[Index].Group := ExtractDigitsToIntW(GroupBlock.GetParam('Group'));
    Text := GroupBlock.GetParam('NextTime');
    Groups[Index].NextTimeMin := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, '-'));
    Groups[Index].NextTimeMax := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, '-'));
    SoundCount := 0;
    ParamCount := GroupBlock.GetParamCount;
    for ParamIndex := 0 to ParamCount - 1 do
      if IsIntegerTextW(GroupBlock.GetParamName(ParamIndex)) then
        Inc(SoundCount);
    Groups[Index].TotalSoundWeight := 0;
    SetLength(Groups[Index].SoundNames, SoundCount);
    SetLength(Groups[Index].SoundWeights, SoundCount);
    SoundIndex := 0;
    for ParamIndex := 0 to ParamCount - 1 do
    begin
      Text := GroupBlock.GetParamName(ParamIndex);
      if IsIntegerTextW(Text) then
      begin
        Groups[Index].SoundWeights[SoundIndex] := ExtractDigitsToIntW(Text);
        Groups[Index].SoundNames[SoundIndex] := GroupBlock.GetParamValue(ParamIndex);
        Inc(Groups[Index].TotalSoundWeight, Groups[Index].SoundWeights[SoundIndex]);
        Inc(SoundIndex);
      end;
    end;
  end;
end;

function TSoundRndSE.SelectSound(GroupIndex: Integer): WideString;
var
  Index, Weight: Integer;
begin
  if Groups[GroupIndex].TotalSoundWeight >= 1 then
  begin
    Weight := RandomIntRange(0, Groups[GroupIndex].TotalSoundWeight - 1);
    for Index := 0 to High(Groups[GroupIndex].SoundNames) do
    begin
      Dec(Weight, Groups[GroupIndex].SoundWeights[Index]);
      if Weight < 0 then
      begin
        Result := Groups[GroupIndex].SoundNames[Index];
        Exit;
      end;
    end;
  end;
  Result := '';
end;

end.
