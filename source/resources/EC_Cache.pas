{$EXCESSPRECISION OFF}
unit EC_Cache;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Data,
  EC_Buf,
  EC_Struct,
  SyncObjs,
  Classes;
type
  TCacheControlEC = class;
  TCacheDataEC = class;
  TCacheEC = class;
  TCacheDataClass = Pointer;
  TCacheControlEC = class(TObjectEx)
    PrevBoundControl: TCacheControlEC;
    NextBoundControl: TCacheControlEC;
    BoundData: TCacheDataEC;
    CacheKey: WideString;
    RetainCount: Integer;
    procedure Reset; virtual;
    procedure SetCacheKey(const NewKey: WideString); virtual;
    procedure QueueLoadIfMissing(PendingLoads: TList); virtual;
    function CreateData: TCacheDataEC; virtual;
    function AcquireData: TCacheDataEC; virtual;
    procedure Release; virtual;
    constructor Create;
    destructor Destroy; override;
    function HasEmptyCacheKey: Boolean;
    function AcquireDataFromConfig(CacheDataClass: TCacheDataClass): TCacheDataEC;
    function AcquireDataFromDirectKey(CacheDataClass: TCacheDataClass): TCacheDataEC;
    procedure EvictData(CacheDataClass: TCacheDataClass);
  end;
  TCacheDataEC = class(TObjectEx)
    PrevData: TCacheDataEC;
    NextData: TCacheDataEC;
    FirstBoundControl: TCacheControlEC;
    LastBoundControl: TCacheControlEC;
    CacheKey: WideString;
    ResidentBytes: Integer;
    LoadCompleteEvent: Cardinal;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); virtual;
    procedure LoadFromKey(const Key: WideString); virtual;
    constructor Create;
    destructor Destroy; override;
    procedure AppendControl(Control: TCacheControlEC);
    procedure UnlinkControl(Control: TCacheControlEC);
  end;
  TCacheEC = class(TObjectEx)
    CacheLock: TCriticalSection;
    MostRecentData: TCacheDataEC;
    LeastRecentData: TCacheDataEC;
    DataRoot: TDataEC;
    ResidentBytes: Integer;
    ResidentByteLimit: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetDataRoot(Root: TDataEC);
    procedure ResetControl(Control: TCacheControlEC);
    procedure AddDataToLruHead(Data: TCacheDataEC);
    procedure RemoveAndFreeData(Data: TCacheDataEC);
    function FindDataByKeyAndClass(
        const Key: WideString;
        CacheDataClass: TCacheDataClass
    ): TCacheDataEC;
    procedure TouchData(Data: TCacheDataEC);
    function OpenDataBuffer(const Path: WideString): TBufEC;
    procedure TrimToBudget(BudgetBytes: Integer);
    procedure QueueNamedLoadIfMissing(
        PendingLoads: TList;
        const CacheKind: WideString;
        const Key: WideString
    );
  end;
procedure EvictMainMenuShipCachesWhenAddressSpaceHigh;
procedure EvictRuinsAndGovernmentCaches;
procedure EvictStarAndBackgroundCaches;
procedure EvictBlockChildrenFromCache(BlockPath: WideString; CacheDataClass: TCacheDataClass);
implementation
uses
  Math,
  EC_CacheSound,
  EC_CacheBitmap,
  EC_CacheTBitmap,
  EC_CacheAlphaBitmap,
  EC_CacheGAI,
  EC_CacheGI,
  EC_CachePlanetTempl,
  GR_DX,
  GR_Main,
  EC_Str,
  GlobalsV,
  SysUtils,
  Windows;

constructor TCacheControlEC.Create;
begin
  inherited Create;
end;

destructor TCacheControlEC.Destroy;
begin
  Reset;
  inherited Destroy;
end;

procedure TCacheControlEC.Reset;
begin
  RetainCount := 0;
  if BoundData <> nil then
  begin
    GlobalCache.CacheLock.Enter;
    BoundData.UnlinkControl(Self);
    GlobalCache.CacheLock.Leave;
    BoundData := nil;
  end;
  CacheKey := '';
end;

procedure TCacheControlEC.SetCacheKey(const NewKey: WideString);
begin
  Reset;
  CacheKey := NewKey;
  if FontSmoothingEnabled then
  begin
    if NewKey = SmallFontName then
      CacheKey := SmoothSmallFontName
    else if NewKey = SmallBoldFontName then
      CacheKey := SmoothSmallBoldFontName
    else if NewKey = NormalFontName then
      CacheKey := SmoothNormalFontName
    else if NewKey = NormalBoldFontName then
      CacheKey := SmoothNormalBoldFontName;
  end;
end;

function TCacheControlEC.HasEmptyCacheKey: Boolean;
begin
  if Length(CacheKey) < 1 then
    Result := True
  else
    Result := False;
end;

procedure TCacheControlEC.QueueLoadIfMissing(PendingLoads: TList);
begin
end;

function TCacheControlEC.CreateData: TCacheDataEC;
begin
  Result := nil;
end;

function TCacheControlEC.AcquireDataFromConfig(CacheDataClass: TCacheDataClass): TCacheDataEC;
var
  Data: TCacheDataEC;
  Buffer: TBufEC;
  PartCount: Integer;
  Path, LoadOption: WideString;
begin
  if HardwareRenderingEnabled and not TextureManagerDisabled then
    EvictTextureCaches(False);
  if RetainCount > 0 then
    Inc(RetainCount)
  else
  begin
    GlobalCache.CacheLock.Enter;
    if BoundData = nil then
    begin
      BoundData := GlobalCache.FindDataByKeyAndClass(CacheKey, CacheDataClass);
      if BoundData = nil then
      begin
        Data := CreateData;
        Data.CacheKey := CacheKey;
        if CacheLoadLoggingEnabled then
          AppendLogLineThreadSafe('Cache Add=' + Data.CacheKey);
        Data.LoadCompleteEvent := CreateEvent(nil, True, False, nil);
        Data.AppendControl(Self);
        BoundData := Data;
        RetainCount := 1;
        GlobalCache.AddDataToLruHead(Data);
        GlobalCache.CacheLock.Leave;
        PartCount := CountDelimitedPartsW(CacheKey, '?');
        if PartCount < 2 then
        begin
          Path := CacheKey;
          LoadOption := '';
        end
        else
        begin
          Path := ExtractDelimitedPartW(CacheKey, 0, '?');
          LoadOption := ExtractDelimitedRangeW(CacheKey, 1, PartCount - 1, '?');
        end;
        Buffer := GlobalCache.OpenDataBuffer(Path);
        try
          Data.LoadFromConfigBuffer(Buffer, LoadOption);
        finally
          GlobalCache.CacheLock.Enter;
          Inc(GlobalCache.ResidentBytes, Data.ResidentBytes);
          SetEvent(Data.LoadCompleteEvent);
          CloseHandle(Data.LoadCompleteEvent);
          Data.LoadCompleteEvent := 0;
          Buffer.Free;
        end;
      end
      else
      begin
        if BoundData.LoadCompleteEvent <> 0 then
        begin
          GlobalCache.CacheLock.Leave;
          WaitForSingleObject(BoundData.LoadCompleteEvent, INFINITE);
          GlobalCache.CacheLock.Enter;
        end;
        BoundData.AppendControl(Self);
        RetainCount := 1;
      end;
    end
    else
      RetainCount := 1;
    GlobalCache.TouchData(BoundData);
    GlobalCache.CacheLock.Leave;
  end;
  Result := BoundData;
  GlobalCache.TrimToBudget(GlobalCache.ResidentByteLimit);
end;

function TCacheControlEC.AcquireDataFromDirectKey(CacheDataClass: TCacheDataClass): TCacheDataEC;
var
  Data: TCacheDataEC;
begin
  if HardwareRenderingEnabled then
    EvictTextureCaches(False);
  if RetainCount > 0 then
    Inc(RetainCount)
  else
  begin
    GlobalCache.CacheLock.Enter;
    if BoundData = nil then
    begin
      BoundData := GlobalCache.FindDataByKeyAndClass(CacheKey, CacheDataClass);
      if BoundData = nil then
      begin
        Data := CreateData;
        Data.CacheKey := CacheKey;
        if CacheLoadLoggingEnabled then
          AppendLogLineThreadSafe('Cache Add=' + Data.CacheKey);
        Data.AppendControl(Self);
        Data.LoadCompleteEvent := CreateEvent(nil, True, False, nil);
        BoundData := Data;
        RetainCount := 1;
        GlobalCache.AddDataToLruHead(Data);
        GlobalCache.CacheLock.Leave;
        try
          Data.LoadFromKey(CacheKey);
        finally
          GlobalCache.CacheLock.Enter;
          Inc(GlobalCache.ResidentBytes, Data.ResidentBytes);
          SetEvent(Data.LoadCompleteEvent);
          CloseHandle(Data.LoadCompleteEvent);
          Data.LoadCompleteEvent := 0;
        end;
      end
      else
      begin
        if BoundData.LoadCompleteEvent <> 0 then
        begin
          GlobalCache.CacheLock.Leave;
          WaitForSingleObject(BoundData.LoadCompleteEvent, INFINITE);
          GlobalCache.CacheLock.Enter;
        end;
        BoundData.AppendControl(Self);
        RetainCount := 1;
      end;
    end
    else
      RetainCount := 1;
    GlobalCache.TouchData(BoundData);
    GlobalCache.CacheLock.Leave;
  end;
  Result := BoundData;
  GlobalCache.TrimToBudget(GlobalCache.ResidentByteLimit);
end;

function TCacheControlEC.AcquireData: TCacheDataEC;
begin
  Result := nil;
end;

procedure TCacheControlEC.Release;
begin
  if RetainCount > 0 then
    Dec(RetainCount)
  else
    RetainCount := 0;
end;

procedure TCacheControlEC.EvictData(CacheDataClass: TCacheDataClass);
begin
  if RetainCount > 0 then
    Exit;
  GlobalCache.CacheLock.Enter;
  if BoundData = nil then
    BoundData := GlobalCache.FindDataByKeyAndClass(CacheKey, CacheDataClass);
  if BoundData <> nil then
  begin
    Dec(GlobalCache.ResidentBytes, BoundData.ResidentBytes);
    GlobalCache.RemoveAndFreeData(BoundData);
    BoundData := nil;
  end;
  GlobalCache.CacheLock.Leave;
end;

constructor TCacheDataEC.Create;
begin
  inherited Create;
end;

destructor TCacheDataEC.Destroy;
begin
  while FirstBoundControl <> nil do
    UnlinkControl(LastBoundControl);
  inherited Destroy;
end;

procedure TCacheDataEC.AppendControl(Control: TCacheControlEC);
begin
  if (LastBoundControl <> nil) then
  begin
    LastBoundControl.NextBoundControl := Control;
  end;
  Control.PrevBoundControl := LastBoundControl;
  Control.NextBoundControl := nil;
  LastBoundControl := Control;
  if (FirstBoundControl = nil) then
  begin
    FirstBoundControl := Control;
  end;
end;

procedure TCacheDataEC.UnlinkControl(Control: TCacheControlEC);
begin
  if (Control.PrevBoundControl <> nil) then
  begin
    Control.PrevBoundControl.NextBoundControl := Control.NextBoundControl;
  end;
  if (Control.NextBoundControl <> nil) then
  begin
    Control.NextBoundControl.PrevBoundControl := Control.PrevBoundControl;
  end;
  if (LastBoundControl = Control) then
  begin
    LastBoundControl := Control.PrevBoundControl;
  end;
  if (FirstBoundControl = Control) then
  begin
    FirstBoundControl := Control.NextBoundControl;
  end;
  Control.PrevBoundControl := nil;
  Control.NextBoundControl := nil;
  Control.BoundData := nil;
end;

procedure TCacheDataEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
end;

procedure TCacheDataEC.LoadFromKey(const Key: WideString);
begin
end;

constructor TCacheEC.Create;
begin
  inherited Create;
  CacheLock := TCriticalSection.Create;
end;

destructor TCacheEC.Destroy;
begin
  Clear;
  CacheLock.Free;
  inherited Destroy;
end;

procedure TCacheEC.Clear;
begin
  while (MostRecentData <> nil) do
  begin
    RemoveAndFreeData(LeastRecentData);
  end;
  ResidentBytes := 0;
end;

procedure TCacheEC.SetDataRoot(Root: TDataEC);
begin
  Clear;
  DataRoot := Root;
end;

procedure TCacheEC.ResetControl(Control: TCacheControlEC);
begin
  Control.Reset;
end;

procedure TCacheEC.AddDataToLruHead(Data: TCacheDataEC);
begin
  if (MostRecentData <> nil) then
  begin
    MostRecentData.PrevData := Data;
  end;
  Data.PrevData := nil;
  Data.NextData := MostRecentData;
  MostRecentData := Data;
  if (LeastRecentData = nil) then
  begin
    LeastRecentData := Data;
  end;
end;

procedure TCacheEC.RemoveAndFreeData(Data: TCacheDataEC);
begin
  if (Data <> nil) then
  begin
    if (Data.PrevData <> nil) then
    begin
      Data.PrevData.NextData := Data.NextData;
    end;
    if (Data.NextData <> nil) then
    begin
      Data.NextData.PrevData := Data.PrevData;
    end;
    if (LeastRecentData = Data) then
    begin
      LeastRecentData := Data.PrevData;
    end;
    if (MostRecentData = Data) then
    begin
      MostRecentData := Data.NextData;
    end;
    Data.Free;
  end;
end;

function TCacheEC.FindDataByKeyAndClass(
    const Key: WideString;
    CacheDataClass: TCacheDataClass
): TCacheDataEC;
var
  Data: TCacheDataEC;
begin
  Data := MostRecentData;
  while Data <> nil do
  begin
    if Pointer(Data.ClassType) = CacheDataClass then
      if Data.CacheKey = Key then
      begin
        Result := Data;
        Exit;
      end;
    Data := Data.NextData;
  end;
  Result := nil;
end;

procedure TCacheEC.TouchData(Data: TCacheDataEC);
begin
  if (Data <> MostRecentData) then
  begin
    if (Data.PrevData <> nil) then
    begin
      Data.PrevData.NextData := Data.NextData;
    end;
    if (Data.NextData <> nil) then
    begin
      Data.NextData.PrevData := Data.PrevData;
    end;
    if (LeastRecentData = Data) then
    begin
      LeastRecentData := Data.PrevData;
    end;
    if (MostRecentData = Data) then
    begin
      MostRecentData := Data.NextData;
    end;
    AddDataToLruHead(Data);
  end;
end;

function TCacheEC.OpenDataBuffer(const Path: WideString): TBufEC;
var
  Buffer: TBufEC;
begin
  Buffer := TBufEC.Create;
  DataRoot.ReadBufferByPath(Path, Buffer);
  Result := Buffer;
end;

procedure TCacheEC.TrimToBudget(BudgetBytes: Integer);
var
  Data, Removed: TCacheDataEC;
  RemainingBytes: Integer;
  Control: TCacheControlEC;
begin
  CacheLock.Enter;
  RemainingBytes := ResidentBytes;
  if RemainingBytes < BudgetBytes then
  begin
    CacheLock.Leave;
    Exit;
  end;
  EvictTextureCaches(True);
  Data := LeastRecentData;
  while (Data <> nil) and (RemainingBytes >= BudgetBytes) do
  begin
    Removed := Data;
    Data := Data.PrevData;
    Control := Removed.FirstBoundControl;
    while Control <> nil do
    begin
      if Control.RetainCount > 0 then
        Break;
      Control := Control.NextBoundControl;
    end;
    if Control <> nil then
      Continue;
    RemainingBytes := RemainingBytes - Removed.ResidentBytes;
    // DCC32 O- folds +0 after register selection, evaluating the size first.
    Dec(ResidentBytes, Removed.ResidentBytes + 0);
    RemoveAndFreeData(Removed);
  end;
  CacheLock.Leave;
end;

procedure TCacheEC.QueueNamedLoadIfMissing(
    PendingLoads: TList;
    const CacheKind: WideString;
    const Key: WideString
);
var
  AlphaBitmap: TCAlphaBitmapControlEC;
  Bitmap: TCBitmapControlEC;
  TBitmap: TCTBitmapControlEC;
  Sound: TCSoundControlEC;
  Gai: TCGaiControlEC;
  Gi: TCGiControlEC;
  PlanetTempl: TCPlanetTemplControlEC;
begin
  if CacheKind = 'Alpha' then
  begin
    if FindDataByKeyAndClass(Key, TCAlphaBitmapEC) = nil then
    begin
      AlphaBitmap := TCAlphaBitmapControlEC.Create;
      ResetControl(AlphaBitmap);
      AlphaBitmap.SetCacheKey(Key);
      PendingLoads.Add(AlphaBitmap);
    end;
  end
  else if CacheKind = 'Bitmap' then
  begin
    if FindDataByKeyAndClass(Key, TCBitmapEC) = nil then
    begin
      Bitmap := TCBitmapControlEC.Create;
      ResetControl(Bitmap);
      Bitmap.SetCacheKey(Key);
      PendingLoads.Add(Bitmap);
    end;
  end
  else if CacheKind = 'Trans' then
  begin
    if FindDataByKeyAndClass(Key, TCTBitmapEC) = nil then
    begin
      TBitmap := TCTBitmapControlEC.Create;
      ResetControl(TBitmap);
      TBitmap.SetCacheKey(Key);
      PendingLoads.Add(TBitmap);
    end;
  end
  else if CacheKind = 'GI' then
  begin
    if FindDataByKeyAndClass(Key, TCGiEC) = nil then
    begin
      Gi := TCGiControlEC.Create;
      ResetControl(Gi);
      Gi.SetCacheKey(Key);
      PendingLoads.Add(Gi);
    end;
  end
  else if CacheKind = 'GAI' then
  begin
    if FindDataByKeyAndClass(Key, TCGaiEC) = nil then
    begin
      Gai := TCGaiControlEC.Create;
      ResetControl(Gai);
      Gai.SetCacheKey(Key);
      PendingLoads.Add(Gai);
    end;
  end
  else if CacheKind = 'Sound' then
  begin
    if FindDataByKeyAndClass(Key, TCSoundEC) = nil then
    begin
      Sound := TCSoundControlEC.Create;
      ResetControl(Sound);
      Sound.SetCacheKey(Key);
      PendingLoads.Add(Sound);
    end;
  end
  else if CacheKind = 'PlanetTempl' then
  begin
    if FindDataByKeyAndClass(Key, TCPlanetTemplEC) = nil then
    begin
      PlanetTempl := TCPlanetTemplControlEC.Create;
      ResetControl(PlanetTempl);
      PlanetTempl.SetCacheKey(Key);
      PendingLoads.Add(PlanetTempl);
    end;
  end;
end;

procedure EvictMainMenuShipCachesWhenAddressSpaceHigh;
var
  i: Integer;
  Control: TCacheControlEC;
  Status: TMemoryStatusEx;
begin
  Status.Length := SizeOf(Status);
  GlobalMemoryStatusEx(Status);
  if GetHeapStatus.TotalAllocated >= $30000000 then
  begin
    Control := TCacheControlEC.Create;
    GlobalCache.ResetControl(Control);
    for i := 1 to 3 do
    begin
      Control.SetCacheKey('Bm.FormMain3.2ShipA' + IntToStr(i));
      Control.EvictData(TCGaiEC);
    end;
    for i := 1 to 3 do
    begin
      Control.SetCacheKey('Bm.FormMain3.2Ship' + IntToStr(i));
      Control.EvictData(TCGiEC);
    end;
    for i := 1 to 3 do
    begin
      Control.SetCacheKey('Bm.FormMain3.AnimGaalShip0' + IntToStr(i) + 'A');
      Control.EvictData(TCGaiEC);
    end;
    for i := 1 to 3 do
    begin
      Control.SetCacheKey('Bm.FormMain3.AnimGaalShip0' + IntToStr(i));
      Control.EvictData(TCGiEC);
    end;
    Control.SetCacheKey('Bm.FormMain3.2BG');
    Control.EvictData(TCGiEC);
    Control.Free;
  end;
end;

procedure EvictRuinsAndGovernmentCaches;
begin
  EvictBlockChildrenFromCache('Bm.FormRuins', TCGaiEC);
  EvictBlockChildrenFromCache('Bm.GovHD', TCGaiEC);
  EvictBlockChildrenFromCache('Bm.Gov', TCGaiEC);
end;

procedure EvictStarAndBackgroundCaches;
begin
  EvictBlockChildrenFromCache('Bm.Star', TCGaiEC);
  EvictBlockChildrenFromCache('Bm.BGO', TCGaiEC);

end;

procedure EvictBlockChildrenFromCache(BlockPath: WideString; CacheDataClass: TCacheDataClass);
var
  i: Integer;
  Control: TCacheControlEC;
  Data: TDataEC;
begin
  Data := CacheDataRoot;
  for i := 0 to CountDelimitedPartsW(BlockPath, '.') - 1 do
    Data := Data.GetData(ExtractDelimitedPartW(BlockPath, i, '.'));
  Control := TCacheControlEC.Create;
  GlobalCache.ResetControl(Control);
  for i := 0 to Data.IndexedEntryCount - 1 do
  begin
    Control.SetCacheKey(BlockPath + '.' + Data.IndexedEntries[i].Name);
    Control.EvictData(CacheDataClass);
  end;
  Control.Free;
end;

end.
