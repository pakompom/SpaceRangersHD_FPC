{$EXCESSPRECISION OFF}
unit NoSteamAchievemens;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SimpleSteamApi,
  EC_BlockPar;
procedure NotifyLocalAchievement(Block: TBlockParEC);
procedure LoadLocalAchievements;
procedure SaveLocalAchievements;
function UnlockLocalAchievement(Block: TBlockParEC): Boolean;
function IncreaseLocalAchievementProgress(Block: TBlockParEC; Amount: Integer): Boolean;
procedure GetLocalAchievementData(Key: WideString; Data: PAchievementData);
implementation
uses
  GI_Main,
  PopUp,
  aMyFunction,
  SysUtils,
  EC_Buf,
  GR_Main,
  GI_MessageLoop,
  Achievements,
  EC_File,
  DateUtils,
  Math,
  GlobalsV,
  aConst;

procedure NotifyLocalAchievement(Block: TBlockParEC);
var
  Text, ImagePath: WideString;
begin
  if PopupController <> nil then
  begin
    Text := LocalizedColorText('Achievements.AchievementReceived');
    ReplaceTextToken(
        Text,
        '<Achievement>',
        LocalizedColorText('Achievements.' + Block.GetParam('Id') + '.Name'),
        '<color=0,71,234>'
    );
    ImagePath := 'GI,Bm.FormAchievements.Img.' + Block.GetParam('Id');
    PopupController.QueueNotification(Text, ImagePath);
  end;
end;

procedure LoadLocalAchievements;
var
  Index, Size, Count: Integer;
  FileName: WideString;
  Buffer: TBufEC;
  Block: TBlockParEC;
  Version: Integer;
  Key: WideString;
  Seed, Checksum: Integer;
  Cursor: PByte;
begin
  FileName := GetGameUserDirectory + 'achievements.dat';
  if FileExists(AnsiString(FileName)) then
  begin
    Buffer := TBufEC.Create;
    try
      Buffer.LoadFromWideFilePath(PWideChar(FileName));
      Buffer.ExpandZlibPayloadInPlace;
      Version := Buffer.GetInt32At(0);
      if Version <> 0 then
        raise EAbort.Create('Error unpacking achievements.dat');
      Seed :=
          Buffer.GetByteAt(6)
              or (Buffer.GetByteAt(7) shl 8)
              or (Buffer.GetByteAt(4) shl 16)
              or (Buffer.GetByteAt(5) shl 24);
      Cursor := PByte(PAnsiChar(Buffer.Data) + 8);
      Size := Buffer.DataSize;
      for Index := 8 to Size - 1 do
      begin
        Cursor^ := Cursor^ xor Byte(Seed - 1);
        Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
        if Seed <= 0 then
          Inc(Seed, $7FFFFFFF);
        Cursor := PByte(PAnsiChar(Cursor) + 1);
      end;
      Checksum := 0;
      Cursor := PByte(PAnsiChar(Buffer.Data) + 12);
      for Index := 12 to Size - 1 do
      begin
        Inc(Checksum, Byte(Cursor^ xor $FF));
        Cursor := PByte(PAnsiChar(Cursor) + 1);
      end;
      if Buffer.GetUInt32At(8) <> Cardinal(Checksum) then
        raise EAbort.Create('Error unpacking achievements.dat');
      Buffer.SetPosition(12);
      Count := Buffer.GetInt32;
      for Index := 0 to Count - 1 do
      begin
        Key := Buffer.ReadWideString;
        Block := AchievementDefinitions.FindBlock(Key);
        if Block <> nil then
        begin
          if Buffer.GetBoolean then
            Block.SetOrAddParam('Achieved', 'Yes');
          Block.SetOrAddParam('Date', WideString(IntToStr(Int64(Buffer.GetUInt32))));
          Block.SetOrAddParam('Value', WideString(IntToStr(Buffer.GetInt32)));
        end;
      end;
    finally
      Buffer.Free;
    end;
  end;
end;

procedure SaveLocalAchievements;
var
  Buffer: TBufEC;
  Index, Size, Count, Seed: Integer;
  Cursor: PByte;
  FileHandle: TFileEC;
  Checksum: Integer;
  Block: TBlockParEC;
begin
  Seed := Random(MaxInt);
  Buffer := TBufEC.Create;
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.SetByteAt(6, Byte(Seed));
  Buffer.SetByteAt(7, Byte(Seed shr 8));
  Buffer.SetByteAt(4, Byte(Seed shr 16));
  Buffer.SetByteAt(5, Byte(Seed shr 24));
  Count := AchievementDefinitions.GetBlockCount;
  Buffer.AddIntegerValue(Count);
  for Index := 0 to Count - 1 do
  begin
    Block := AchievementDefinitions.GetBlockByIndex(Index);
    Buffer.AddWideStringZ(AchievementDefinitions.GetBlockNameByIndex(Index));
    Buffer.AddBoolean(ParseEnabledNameGI(Block.GetParam('Achieved')));
    Buffer.AddDWord(StrToInt64(AnsiString(Block.GetParam('Date'))));
    Buffer.AddIntegerValue(StrToInt(AnsiString(Block.GetParam('Value'))));
  end;
  Size := Buffer.DataSize;
  Checksum := 0;
  Cursor := PByte(PAnsiChar(Buffer.Data) + 12);
  for Index := 12 to Size - 1 do
  begin
    Inc(Checksum, Byte(Cursor^ xor $FF));
    Cursor := PByte(PAnsiChar(Cursor) + 1);
  end;
  Buffer.SetInt32At(8, Checksum);
  Cursor := PByte(PAnsiChar(Buffer.Data) + 8);
  for Index := 8 to Size - 1 do
  begin
    Cursor^ := Cursor^ xor Byte(Seed - 1);
    Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
    if Seed <= 0 then
      Inc(Seed, $7FFFFFFF);
    Cursor := PByte(PAnsiChar(Cursor) + 1);
  end;
  Buffer.CompressZlibPayloadInPlace(False);
  FileHandle := TFileEC.Create;
  FileHandle.SetFileName(GetGameUserDirectory + 'achievements.dat');
  FileHandle.CreateNew;
  FileHandle.WriteBuffer(Buffer.Data, Buffer.DataSize);
  FileHandle.Free;
  Buffer.Free;
end;

function UnlockLocalAchievement(Block: TBlockParEC): Boolean;
begin
  Result := True;
  if not ParseEnabledNameGI(Block.GetParam('Achieved')) or (Block.GetParam('Date') = '0') then
  begin
    Block.SetOrAddParam('Achieved', 'Yes');
    Block.SetOrAddParam('Date', IntToStr(DateTimeToUnix(Now)));
    NotifyLocalAchievement(Block);
    SaveLocalAchievements;
  end;
end;

function IncreaseLocalAchievementProgress(Block: TBlockParEC; Amount: Integer): Boolean;
var
  OldValue, NewValue, MaxValue: Integer;
begin
  Result := False;
  if Amount <= 0 then
    Exit;
  if ParseEnabledNameGI(Block.GetParam('Achieved')) and (Block.GetParam('Date') <> '0') then
    Exit;
  MaxValue := StrToInt(AnsiString(Block.GetParam('MaxValue')));
  if MaxValue = 0 then
    Exit;
  OldValue := StrToInt(AnsiString(Block.GetParam('Value')));
  if OldValue >= MaxValue then
    Exit;
  Result := True;
  NewValue := Min(MaxValue, OldValue + Amount);
  Block.SetOrAddParam('Value', IntToStr(NewValue));
  if NewValue >= MaxValue then
  begin
    Block.SetOrAddParam('Achieved', 'Yes');
    Block.SetOrAddParam('Date', IntToStr(DateTimeToUnix(Now)));
    NotifyLocalAchievement(Block);
  end;
  SaveLocalAchievements;
end;

procedure GetLocalAchievementData(Key: WideString; Data: PAchievementData);
var
  Block: TBlockParEC;
begin
  Block := AchievementDefinitions.FindBlock(Key);
  if Block <> nil then
  begin
    Data.Achieved := ParseEnabledNameGI(Block.GetParam('Achieved'));
    Data.Name^ := LocalizedColorText('Achievements.' + Key + '.Name');
    Data.Description^ := LocalizedColorText('Achievements.' + Key + '.Description');
    Data.Reserved0C := 0;
    Data.MaxValue := StrToInt(AnsiString(Block.GetParam('MaxValue')));
    Data.HasProgress := Data.MaxValue > 0;
    Data.Value := StrToInt(AnsiString(Block.GetParam('Value')));
    Data.IconPath^ := 'null';
    Data.Date := StrToInt64(AnsiString(Block.GetParam('Date')));
  end;
end;

end.
