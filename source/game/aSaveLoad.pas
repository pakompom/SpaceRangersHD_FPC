{$EXCESSPRECISION OFF}
unit aSaveLoad;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Thread,
  SyncObjs;
type
  TSaver = class;
  TSaver = class(TThreadEC)
    FileName: WideString;
    HeaderBuffer: TBufEC;
    PreviewBuffer: TBufEC;
    SecondaryPreviewBuffer: TBufEC;
    GameStateBuffer: TBufEC;
    FilmBuffer: TBufEC;
    ErrorText: AnsiString;
    procedure Execute; override;
    procedure QueueSave(
        AFileName: WideString;
        Header: TBufEC;
        Preview: TBufEC;
        SecondaryPreview: TBufEC;
        GameState: TBufEC;
        Films: TBufEC
    );
  end;
var
  MemorySnapshotBuffer: TBufEC = nil;
  SaveLoadLock: TCriticalSection = nil;
  SaveWriter: TSaver = nil;
  LastSaveLoadError: WideString;
function SaveGameToFile(FileName: WideString; Description: WideString): Boolean;
procedure LoadGameFromSaveBuffer(Buffer: TBufEC);
function LoadGameFromFile(FileName: WideString): Boolean;
procedure SaveGameToMemorySnapshot;
procedure RestoreGameFromMemorySnapshot;
procedure InitializeSaveWriter;
procedure FinalizeSaveWriter;
procedure LinkRecoveredTypes;
implementation

uses
  aCalc,
  RTLFileSystem,
  Math,
  aMyFunction,
  aGalaxyStruct,
  aKling,
  Windows,
  SysUtils,
  EC_File,
  EC_Str,
  EC_BlockPar,
  aGalaxy,
  aConst,
  aPlayer,
  GR_Main,
  Globals,
  GlobalsV,
  fSaveManager,
  fShip2,
  fStarMap,
  fFilmFile,
  GI_Main,
  GI_MessageBox,
  EC_Struct,
  Types,
  aShip,
  aRuins,
  GI_MessageLoop,
  fGov,
  fEquipmentShop,
  fCount2,
  fRating2,
  fJournal,
  fSelectFace,
  fScaner,
  fGalaxy2,
  fGameMenu,
  fRewards,
  fChameleon,
  fTalk,
  ab_MainForm,
  fLoad,
  fGameLoad,
  fHangar,
  fPlanet,
  fPlanetNO,
  fPlanetQuest,
  fGoodsShop2,
  fRuinsTalk,
  fInfo,
  fJump;

var
  MemorySnapshotGalaxy: TGalaxy = nil;

procedure TSaver.Execute;
var
  F: TFileEC;
  Size, I, Seed: Integer;
  SourceName, TargetName, NewName, OldName, Prefix, QuickName, TempName: WideString;
  FastCompression: Boolean;
begin
  SaveLoadLock.Enter;
  F := nil;
  TempName := '';
  try
    try
      // CHANGE: PERFORMANCE - Use cheaper compression for fast-travel autosaves.
      FastCompression := FastTravelTransitions and (FileName = SaveManagerScreen.GetAutoSavePath);
      QuickName := SaveManagerScreen.GetQuickSavePath(1);
      if not ForceDirectories(NativePath(GetGameUserDirectory + 'Save')) then
        raise Exception.Create('Cannot create save directory');
      F := TFileEC.Create;
      TempName := GetGameUserDirectory + 'Save\save.tmp';
      if FileExists(AnsiString(TempName)) then
        DeleteFileA(PAnsiChar(AnsiString(TempName)));
      F.SetFileName(TempName);
      F.CreateNew;
      HeaderBuffer.SaveToFile(F);
      if PreviewBuffer.DataSize > 0 then
        PreviewBuffer.CompressZlibPayloadInPlace(FastCompression);
      Size := PreviewBuffer.DataSize;
      F.WriteBuffer(@Size, 4);
      if Size > 0 then
        F.WriteBuffer(PreviewBuffer.Data, Size);
      if SecondaryPreviewBuffer.DataSize > 0 then
        SecondaryPreviewBuffer.CompressZlibPayloadInPlace(FastCompression);
      Size := SecondaryPreviewBuffer.DataSize;
      F.WriteBuffer(@Size, 4);
      if Size > 0 then
        F.WriteBuffer(SecondaryPreviewBuffer.Data, Size);
      GameStateBuffer.CompressZlibPayloadInPlace(FastCompression);
      Size := GameStateBuffer.ComputeCrc32;
      F.WriteBuffer(@Size, 4);
      Seed := RandomIntRange(0, 2000000000);
      GameStateBuffer.ApplyDatXorCipher(Seed);
      F.WriteBuffer(@Seed, 4);
      Size := GameStateBuffer.DataSize;
      F.WriteBuffer(@Size, 4);
      if Size > 0 then
        F.WriteBuffer(GameStateBuffer.Data, Size);
      FilmBuffer.CompressZlibPayloadInPlace(FastCompression);
      Size := FilmBuffer.DataSize;
      F.WriteBuffer(FilmBuffer.Data, Size);
      F.ReleaseHandle;
      SourceName := TempName;
      TargetName := FileName;
      if (FileName = QuickName) and (QuickSaveExtraSlots > 0) then
      begin
        Prefix :=
            TrimWideString(ExtractFileDirW(QuickName))
                + '\'
                + TrimWideString(ExtractFileNameNoExtW(QuickName));
        NewName := Prefix + IntToWideString(QuickSaveExtraSlots + 1) + '.sav';
        for I := QuickSaveExtraSlots downto 1 do
        begin
          if I > 1 then
            OldName := Prefix + IntToWideString(I) + '.sav'
          else
            OldName := QuickName;
          if RTLFileSystem.FileExists(UTF8Encode(OldName)) then
            if not MoveFileW(PWideChar(OldName), PWideChar(NewName)) then
              raise Exception.Create('Cannot rotate quicksave: ' + UTF8Encode(OldName));
          NewName := OldName;
        end;
      end;
      // CHANGE: BUGFIX - Replace the destination only after writing and closing the complete save.
      // POSIX rename atomically replaces the destination; keep the old save until
      // the complete temporary file has been closed successfully.
      if not MoveFileW(PWideChar(SourceName), PWideChar(TargetName)) then
        raise Exception.Create('Cannot commit save: ' + UTF8Encode(TargetName));

    except
      on E: Exception do
      begin
        ErrorText := E.ClassName + ': ' + E.Message;
        AppendLogLineThreadSafe('Save failed: ' + ErrorText);
        LogExceptionBackTrace;
      end;
    end;
  finally
    try
      F.Free;
      if (TempName <> '') and RTLFileSystem.FileExists(UTF8Encode(TempName)) then
        DeleteFileA(PAnsiChar(UTF8Encode(TempName)));
      FreeAndNil(HeaderBuffer);
      FreeAndNil(PreviewBuffer);
      FreeAndNil(SecondaryPreviewBuffer);
      FreeAndNil(GameStateBuffer);
      FreeAndNil(FilmBuffer);
    finally
      SaveLoadLock.Leave;
    end;
  end;

end;
procedure TSaver.QueueSave(
    AFileName: WideString;
    Header, Preview, SecondaryPreview, GameState, Films: TBufEC
);
begin
  if IsRunning then
    WaitForIdle(INFINITE);
  ErrorText := '';
  FileName := AFileName;
  HeaderBuffer := Header;
  PreviewBuffer := Preview;
  SecondaryPreviewBuffer := SecondaryPreview;
  GameStateBuffer := GameState;
  FilmBuffer := Films;
  Start;
end;
function SaveGameToFile(FileName, Description: WideString): Boolean;
var
  Header, Preview, SecondaryPreview, GameState, Films, FilmEntry: TBufEC;
  Size, I, Count: Integer;
  Message: TMessagePlayer;
  Entry: TPlayerHoldUnit;
  AutoName, TurnName, QuickName: WideString;
begin
  Result := False;
  LastSaveLoadError := '';
  Header := nil;
  Preview := nil;
  SecondaryPreview := nil;
  GameState := nil;
  Films := nil;
  if (Galaxy <> nil) and (GetPlayer <> nil) then
  begin
    FilmEntry := nil;
    AutoName := SaveManagerScreen.GetAutoSavePath;
    TurnName := SaveManagerScreen.GetTurnSavePath;
    QuickName := SaveManagerScreen.GetQuickSavePath(1);
    if FileName = AutoName then
      Description := SaveManagerScreen.BuildCurrentSaveDescription;
    try
      Header := TBufEC.Create;
      Header.AddWideStringZ('RSG');
      Header.AddWideStringZ('v' + IntToStr(CurrentSaveVersion));
      Header.AddWideStringZ(Description);
      Header.AddWideStringZ(IntToStr(Galaxy.CurrentTurn));
      Header.AddWideStringZ(IntToStr(GetPlayer.Money));
      Header.AddWideStringZ(GetPlayer.Name);
      if GetPlayer.OwnerId = Byte(oiPirate) then
        Header.AddWideStringZ(
            OwnerInfo[Ord(oiPirate)].InternalName
                + OwnerInfo[Integer(RaceToOwner(GetPlayer.PilotRace)) and $7F].InternalName
        )
      else
        Header.AddWideStringZ(OwnerInfo[GetPlayer.OwnerId].InternalName);
      Header.AddWideStringZ('EZ');
      Preview := TBufEC.Create;
      if SavePreviewGraph <> nil then
        SavePreviewGraph.SaveToBuffer(Preview);
      SecondaryPreview := TBufEC.Create;
      if SecondarySavePreviewGraph <> nil then
        SecondarySavePreviewGraph.SaveToBuffer(SecondaryPreview);
      GameState := TBufEC.Create;
      GameState.AddIntegerValue(Ord(SaveManagerReturnScreenId));
      GameState.AddIntegerValue(StarMapScreen.GetMapCenter.X);
      GameState.AddIntegerValue(StarMapScreen.GetMapCenter.Y);
      GameState.AddBoolean(StarMapWeaponPanelOpen);
      GameState.AddAnsiChar(#0);
      GameState.AddBoolean(FilmCameraFollow);
      GameState.AddAnsiChar(#0);
      GameState.AddAnsiChar(#0);
      GameState.AddAnsiChar(#0);
      GameState.AddBoolean(False);
      GameState.AddBoolean(PlayerStarDayPrepared);
      GameState.AddDWord(ShownPlayerTips);
      GameState.AddIntegerValue(0);
      Count := CountPersistentPlayerMessages;
      GameState.AddIntegerValue(Count);
      Message := FirstPersistentPlayerMessage;
      while Message <> nil do
      begin
        Message.SaveToBuffer(GameState);
        Message := Message.Next;
      end;
      PlayerHoldShip := GetPlayer;
      RefreshPlayerHoldView(False);
      Count := PlayerHoldEntries.Count;
      GameState.AddWideChar(WideChar(Count));
      for I := 0 to Count - 1 do
      begin
        Entry := PlayerHoldEntries[I];
        GameState.AddAnsiChar(AnsiChar(Entry.Kind));
        GameState.AddAnsiChar(AnsiChar(Entry.GoodsIndex));
        GameState.AddDWord(Entry.ItemId);
      end;
      Galaxy.SaveToBuffer(GameState);
      Films := TBufEC.Create;
      FilmEntry := TBufEC.Create;
      Count := 0;
      Count := FilmHistory.GetCount;
      Films.AddBytes(@Count, 4);
      for I := 0 to Count - 1 do
      begin
        FilmHistory.SaveEntryToBuffer(FilmHistory.GetEntry(I), FilmEntry);
        Size := FilmEntry.DataSize;
        Films.AddBytes(@Size, 4);
        if Size > 0 then
          Films.AddBytes(FilmEntry.Data, Size);
      end;
      SaveWriter.QueueSave(FileName, Header, Preview, SecondaryPreview, GameState, Films);
      Header := nil;
      Preview := nil;
      SecondaryPreview := nil;
      GameState := nil;
      Films := nil; // Ownership passed to the writer.
      SaveWriter.WaitForIdle(INFINITE);
      if SaveWriter.ErrorText <> '' then
        raise Exception.Create(SaveWriter.ErrorText);
      if Galaxy.CampaignFlag183 <> 0 then
      begin
        EditableSaveFileName := SaveManagerScreen.GetSaveConfigPath(FileName);
        if (UserSettingsConfig.CountParams('UnicodeDump') > 0)
            and ParseEnabledNameGI(
                TrimWideString(UserSettingsConfig.GetParamByPathOrMarker('UnicodeDump'))) then
          EditableSaveBlock.SaveTextFile(PWideChar(EditableSaveFileName), False, False)
        else
          EditableSaveBlock.SaveTextFile(PWideChar(EditableSaveFileName), True, False);
        EditableSaveBlock.Clear;
        Galaxy.CampaignFlag183 := 0;
      end;
      Result := True;
    except
      on E: Exception do
      begin
        LastSaveLoadError := E.ClassName + ': ' + E.Message;
        AppendLogLineThreadSafe(UTF8Encode(LastSaveLoadError));
        LogExceptionBackTrace;
        if FileName = AutoName then
          Galaxy.ShowLocalizedWarning('Warning.AutoSaveFailed');
        if FileName = TurnName then
          Galaxy.ShowLocalizedWarning('Warning.TurnSaveFailed');
        if FileName = QuickName then
          Galaxy.ShowLocalizedWarning('Warning.QuickSaveFailed');
      end;
    end;
    Header.Free;
    Preview.Free;
    SecondaryPreview.Free;
    GameState.Free;
    Films.Free;
    if FilmEntry <> nil then
      FilmEntry.Free;
    if Result = True then
      FreeSavePreviewBuffers;
  end;

end;
procedure LoadGameFromSaveBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Entry: TPlayerHoldUnit;
  LoadingGalaxy: TGalaxy;
begin
  InitializePlayerHoldView;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Entry := TPlayerHoldUnit.Create;
    PlayerHoldEntries.Add(Entry);
    Entry.Kind := TPlayerHoldKind(Buffer.GetByte);
    Entry.GoodsIndex := Buffer.GetByte;
    Entry.ItemId := Buffer.GetUInt32;
  end;
  LoadingGalaxy := Galaxy;
  Galaxy := nil;
  LoadingGalaxy.LoadFromBuffer(Buffer);
  if ApplyEditableSaveOnLoad then
  begin
    Galaxy.ApplyEditableState;
    ApplyEditableSaveOnLoad := False;
    aCalc.WaitForTurnCalculationUI;
  end;
  Galaxy.RunConfigOnLoadHandlers;
end;
function LoadGameFromFile(FileName: WideString): Boolean;
var
  F: TFileEC;
  Buffer, Films: TBufEC;
  Center: TPoint;
  Size, I, Count, Seed: Integer;
  Crc: Cardinal;
  Message: TMessagePlayer;
begin
  Result := False;
  LastSaveLoadError := '';
  LoadedSaveModSet := SelectedMods;

  SaveLoadLock.Enter;

  try
    F := nil;
    Buffer := nil;
    try
      if MemorySnapshotBuffer <> nil then
        MemorySnapshotBuffer.Free;
      MemorySnapshotBuffer := nil;
      MemorySnapshotActive := False;
      if (Galaxy <> nil) and not Galaxy.Destroying then
        Galaxy.Free;
      Galaxy := nil;

      F := TFileEC.Create;
      F.SetFileName(FileName);
      if not F.TryAcquireReadHandle(False) then
        raise EAbort.Create('Cannot open file ' + FileName);
      if F.ReadWideString <> 'RSG' then
        raise EAbort.Create('Bad pre-signature of file' + FileName);
      LoadedSaveVersion := ExtractDigitsToIntW(F.ReadWideString);
      F.ReadWideString;
      StrToInt(F.ReadWideString);
      StrToInt(F.ReadWideString);
      F.ReadWideString;
      F.ReadWideString;
      if F.ReadWideString <> 'EZ' then
        raise EAbort.Create('Bad post-signature of file' + FileName);
      Buffer := TBufEC.Create;
      F.ReadBuffer(@Size, 4);
      if Size > 0 then
        F.SetPointer(Size, 1);
      F.ReadBuffer(@Size, 4);
      if Size > 0 then
        F.SetPointer(Size, 1);
      F.ReadBuffer(@Crc, 4);
      F.ReadBuffer(@Seed, 4);
      F.ReadBuffer(@Size, 4);
      if Size > 0 then
      begin
        Buffer.SetSize(Size);
        try
          F.ReadBuffer(Buffer.Data, Size);
        except
          ShowMessageBoxGI(nil, 'Compressed galaxy read fail', 1, 0, 0, 0);
        end;
      end;

      Buffer.ApplyDatXorCipher(Seed);
      if Buffer.ComputeCrc32 <> Crc then
        raise EAbort.Create('Integrity check fail');

      Buffer.ExpandZlibPayloadInPlace;

      ActiveLoadBuffer := Buffer;
      RequestedScreenId := TGameScreenId(Buffer.GetInt32);
      Galaxy := TGalaxy.Create;
      Center.X := Buffer.GetInt32;
      Center.Y := Buffer.GetInt32;
      SpaceViewPosition := PointToPointF(Center);
      StarMapScreen.SetMapCenterManually(Center);
      StarMapWeaponPanelOpen := Buffer.GetBoolean;
      Buffer.GetByte;
      FilmCameraFollow := Buffer.GetBoolean;
      Buffer.GetByte;
      Buffer.GetByte;
      Buffer.GetByte;
      Buffer.GetBoolean;
      PlayerStarDayPrepared := Buffer.GetBoolean;
      ShownPlayerTips := Buffer.GetUInt32;
      Buffer.GetInt32;
      Count := Buffer.GetInt32;
      for I := 0 to Count - 1 do
      begin
        Message := CreatePersistentPlayerMessage;
        Message.LoadFromBuffer(Buffer);
      end;

      LoadGameFromSaveBuffer(Buffer);

      Films := nil;
      try
        Films := TBufEC.Create;
        Films.Clear;
        Size := F.GetSize - F.GetPointer;
        if Size > 0 then
        begin
          Films.SetSize(Size);
          F.ReadBuffer(Films.Data, Size);
          Films.ExpandZlibPayloadInPlace;
          FilmHistory.Clear;
          Films.ReadBytes(@Count, 4);
          LoadingFilmCount := Count;
          LoadedFilmCount := 0;
          for I := 0 to Count - 1 do
          begin
            Films.ReadBytes(@Size, 4);
            if Size > 0 then
            begin
              Buffer.SetSize(Size);
              Films.ReadBytes(Buffer.Data, Size);
              Buffer.SetPosition(0);
              FilmHistory.LoadEntryFromBuffer(Buffer);
            end;
            Inc(LoadedFilmCount);
          end;
          LoadingFilmCount := -1;
        end;
      finally
        if Films <> nil then
          Films.Free;
      end;
      LoadingFilmCount := -1;

      PreviousFilmActivity := 0;
      Result := True;
    except
      on E: Exception do
      begin
        LastSaveLoadError := E.ClassName + ': ' + E.Message;
        AppendLogLineThreadSafe('Load failed: ' + UTF8Encode(LastSaveLoadError));
        LogExceptionBackTrace;
        if MemorySnapshotBuffer <> nil then
          MemorySnapshotBuffer.Free;
        MemorySnapshotBuffer := nil;
        MemorySnapshotActive := False;
        if (Galaxy <> nil) and not Galaxy.Destroying then
        begin
          try
            Galaxy.Free;
          finally
            Galaxy := nil;
          end;
        end;
        if EditableSaveBlock <> nil then
          EditableSaveBlock.Clear;
      end;
    end;
    LoadingFilmCount := -1;
    ActiveLoadBuffer := nil;
    if Buffer <> nil then
      Buffer.Free;
    if F <> nil then
      F.Free;
  finally
    SaveLoadLock.Leave;
  end;

end;
procedure SaveGameToMemorySnapshot;
var
  I, Count: Integer;
  Message: TMessagePlayer;
  Entry: TPlayerHoldUnit;
  Loop: TMessageLoopGI;
begin
  MemorySnapshotBuffer := TBufEC.Create;
  if (CurrentScreenId <> screenPlanetQuest)
      and ((CurrentScreenId <> screenGovernment) or (GovernmentScreen.PendingTransition = 0))
      and ((CurrentScreenId <> screenStarMap) or (StarMapScreen.PlanetBattleState = 0)) then
    (TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI).OnClose;
  for I := MessageLoopStack.Count - 1 downto 0 do
  begin
    Loop := MessageLoopStack[I];
    if Loop is TfShip2 then
      (Loop as TfShip2).ReturnSelectedHoldEntry;
  end;
  if (GetPlayer.IsOnPlanet and (GetPlayer.CurrentPlanet.OwnerId <> Byte(oiUninhabited)))
      or (GetPlayer.IsDockedToShip and (GetPlayer.DockedTo is TRuins)) then
    RestoreTemporaryShopStock;
  Count := CountPersistentPlayerMessages;
  MemorySnapshotBuffer.AddIntegerValue(Count);
  Message := FirstPersistentPlayerMessage;
  while Message <> nil do
  begin
    Message.SaveToBuffer(MemorySnapshotBuffer);
    Message := Message.Next;
  end;
  MemorySnapshotBuffer.AddDWord(ShownPlayerTips);
  PlayerHoldShip := GetPlayer;
  RefreshPlayerHoldView(False);
  Count := PlayerHoldEntries.Count;
  MemorySnapshotBuffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Entry := PlayerHoldEntries[I];
    MemorySnapshotBuffer.AddAnsiChar(AnsiChar(Entry.Kind));
    MemorySnapshotBuffer.AddAnsiChar(AnsiChar(Entry.GoodsIndex));
    MemorySnapshotBuffer.AddDWord(Entry.ItemId);
  end;
  Dec(Galaxy.SaveCount);
  Galaxy.SaveToBuffer(MemorySnapshotBuffer);
  if Galaxy.ContainsShipReference(TalkShip) then
    MemorySnapshotBuffer.AddDWord(TalkShip.Id)
  else
    MemorySnapshotBuffer.AddDWord(0);
  if Galaxy.ContainsPlanetReference(TalkPlanet) then
    MemorySnapshotBuffer.AddDWord(TalkPlanet.Id)
  else
    MemorySnapshotBuffer.AddDWord(0);
  if Galaxy.ContainsShipReference(ShipScreen.ShipToInspect) then
    MemorySnapshotBuffer.AddDWord(ShipScreen.ShipToInspect.Id)
  else
    MemorySnapshotBuffer.AddDWord(0);
  MemorySnapshotGalaxy := Galaxy;
  Galaxy := nil;
  BlazerShip := nil;
  KellerShip := nil;
  TerronShip := nil;
  MemorySnapshotActive := True;
end;
procedure RestoreGameFromMemorySnapshot;
var
  ReopenScreen: Boolean;
  I, Count: Integer;
  Entry: TPlayerHoldUnit;
  Message: TMessagePlayer;
  Loop: TMessageLoopGI;
begin
  ReopenScreen := True;
  Galaxy := MemorySnapshotGalaxy;
  MemorySnapshotGalaxy := nil;
  if DominatorSpawnPlanet <> nil then
  begin
    DominatorSpawnPlanet.Free;
    DominatorSpawnPlanet := nil;
  end;
  Galaxy.Free;
  MemorySnapshotBuffer.SetPosition(0);
  MemorySnapshotActive := True;
  Galaxy := TGalaxy.Create;
  LoadedSaveVersion := CurrentSaveVersion;
  Count := MemorySnapshotBuffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Message := CreatePersistentPlayerMessage;
    Message.LoadFromBuffer(MemorySnapshotBuffer);
  end;
  ShownPlayerTips := MemorySnapshotBuffer.GetUInt32;
  InitializePlayerHoldView;
  Count := MemorySnapshotBuffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Entry := TPlayerHoldUnit.Create;
    PlayerHoldEntries.Add(Entry);
    Entry.Kind := TPlayerHoldKind(MemorySnapshotBuffer.GetByte);
    Entry.GoodsIndex := MemorySnapshotBuffer.GetByte;
    Entry.ItemId := MemorySnapshotBuffer.GetUInt32;
  end;
  Galaxy.LoadFromBuffer(MemorySnapshotBuffer);
  Dec(Galaxy.LoadCount);
  TalkShip := Galaxy.IdToShip(MemorySnapshotBuffer.GetUInt32, True);
  TalkPlanet := Galaxy.IdToPlanet(MemorySnapshotBuffer.GetUInt32);
  ShipScreen.ShipToInspect := Galaxy.IdToShip(MemorySnapshotBuffer.GetUInt32, True);
  for I := MessageLoopStack.Count - 1 downto 0 do
  begin
    Loop := MessageLoopStack[I];
    if Loop is TMessageBoxGI then
      Loop.RequestClose(254)
    else if Loop is TfCount2 then
      Loop.RequestClose(254)
    else if (Loop is TfStarMap) and (StarMapScreen.PlanetBattleState <> 0) then
      ReopenScreen := False
    else if Loop is TfRating2 then
      Loop.RequestClose(1)
    else if Loop is TfJournal then
      Loop.RequestClose(1)
    else if Loop is TfSelectFace then
      Loop.RequestClose(254)
    else if Loop is TfScaner then
    begin
      RequestedScreenId := ScannerReturnScreenId;
      Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if (Loop is TfShip2) and not GetPlayer.InNormalSpace then
      Loop.RequestClose(1)
    else if (Loop is TfGalaxy2) and not GetPlayer.InNormalSpace then
      Loop.RequestClose(1)
    else if (Loop is TfShip2) and GetPlayer.InNormalSpace then
    begin
      RequestedScreenId := ShipReturnScreenId;
      Loop.RequestClose(1);
    end
    else if (Loop is TfGalaxy2) and GetPlayer.InNormalSpace then
    begin
      RequestedScreenId := GalaxyReturnScreenId;
      Loop.RequestClose(1);
    end
    else if Loop is TfGameMenu then
    begin
      RequestedScreenId := GameMenuReturnScreenId;
      Loop.RequestClose(1);
    end
    else if Loop is TfSaveManager then
    begin
      RequestedScreenId := SaveManagerReturnScreenId;
      Loop.RequestClose(1);
    end
    else if Loop is TfRewards then
      Loop.RequestClose(254)
    else if Loop is TfChameleon then
      Loop.RequestClose(254)
    else if Loop is TfTalk then
    begin
      RequestedScreenId := TalkReturnScreenId;
      if TalkScripted then
        RaiseWideMessage('gtalk AI');
      Loop.RequestClose(1);
    end
    else if Loop is TfAB then
    begin
      RequestedScreenId := screenMainMenu;
      Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if Loop is TfLoad then
    begin
      if GetPlayer.InNormalSpace then
      begin
        RequestedScreenId := screenStarMap;
        StarMapScreen.ResumeMode := smrOrders;
      end;
      PostLoadScreenId := RequestedScreenId;
      Loop.RequestClose(1);
    end
    else if Loop is TfGameLoad then
    begin
      Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if GetPlayer.InNormalSpace
        and ((Loop is TfHangar)
            or (Loop is TfPlanet)
            or (Loop is TfPlanetNO)
            or (Loop is TfGov)
            or (Loop is TfPlanetQuest)
            or (Loop is TfEquipmentShop)
            or (Loop is TfGoodsShop2)
            or (Loop is TfRuinsTalk)
            or (Loop is TfInfo)) then
    begin
      RequestedScreenId := screenStarMap;
      StarMapScreen.ResumeMode := smrOrders;
      if Loop is TfGoodsShop2 then
      begin
        Loop.RequestClose(2);
        TalkScreen.Flag128 := 0;
        GoodsShopScreen.FlagEC := False;
        StarMapScreen.RequestClose(1);
      end
      else
        Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if (GetPlayer.IsOnPlanet or GetPlayer.IsDockedToShip) and (Loop is TfStarMap) then
    begin
      Loop.RequestClose(1);
      if GetPlayer.IsOnPlanet and (GetPlayer.CurrentPlanet.OwnerId = Byte(oiUninhabited)) then
        RequestedScreenId := screenPlanetNO
      else if GetPlayer.IsOnPlanet and (GetPlayer.CurrentPlanet.OwnerId <> Byte(oiUninhabited)) then
        RequestedScreenId := screenPlanet
      else if GetPlayer.IsDockedToShip then
        RequestedScreenId := screenRuinsTalk;
    end
    else if GetPlayer.InHyperspace
        and (GetPlayer.Order = soJumpHole)
        and ((Loop is TfStarMap) or (Loop is TfAB)) then
    begin
      RequestedScreenId := screenMainMenu;
      Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if GetPlayer.InHyperspace and (GetPlayer.Order = soJump) and (Loop is TfStarMap) then
    begin
      RequestedScreenId := screenJump;
      Loop.RequestClose(1);
      ReopenScreen := False;
    end
    else if Loop is TfPlanetQuest then
      ReopenScreen := False
    else if (Loop is TfGov) and (GovernmentScreen.PendingTransition <> 0) then
      ReopenScreen := False
    else if Loop is TfJump then
      JumpScreen.RestoreOrdersOnArrival := True;
  end;
  if (GetPlayer.IsOnPlanet and (GetPlayer.CurrentPlanet.OwnerId <> Byte(oiUninhabited)))
      or (GetPlayer.IsDockedToShip and (GetPlayer.DockedTo is TRuins)) then
    BuildTemporaryShopSlotGrid;
  if ReopenScreen then
    (TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI).OnOpen;
  aCalc.WaitForTurnCalculationUI;
  MemorySnapshotBuffer.Free;
  MemorySnapshotBuffer := nil;
  MemorySnapshotActive := False;
  Galaxy.RunConfigOnLoadHandlers;
end;
procedure InitializeSaveWriter;
begin
  SaveWriter := TSaver.Create;
end;
procedure FinalizeSaveWriter;
begin
  if SaveWriter <> nil then
  begin
    if SaveWriter.IsRunning then
      SaveWriter.WaitForIdle(INFINITE);
    SaveWriter.Free;
    SaveWriter := nil;
  end;
end;
procedure LinkRecoveredTypes;
begin
  TMessageBoxGI.ClassName;
  TMessageLoopGI.ClassName;
  TRuins.ClassName;
  TfAB.ClassName;
  TfChameleon.ClassName;
  TfCount2.ClassName;
  TfEquipmentShop.ClassName;
  TfGalaxy2.ClassName;
  TfGameLoad.ClassName;
  TfGameMenu.ClassName;
  TfGoodsShop2.ClassName;
  TfGov.ClassName;
  TfHangar.ClassName;
  TfInfo.ClassName;
  TfJournal.ClassName;
  TfJump.ClassName;
  TfLoad.ClassName;
  TfPlanet.ClassName;
  TfPlanetNO.ClassName;
  TfPlanetQuest.ClassName;
  TfRating2.ClassName;
  TfRewards.ClassName;
  TfRuinsTalk.ClassName;
  TfSaveManager.ClassName;
  TfScaner.ClassName;
  TfSelectFace.ClassName;
  TfShip2.ClassName;
  TfStarMap.ClassName;
  TfTalk.ClassName;
end;
end.
