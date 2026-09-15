unit GR_Music;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
uses
  EC_Buf;
type
  TNativeMusicTrack = class
    Data: TBufEC;
    Handle: Pointer;
    FileName: WideString;
    BaseVolume: Single;
    constructor Create(const Name: WideString);
    destructor Destroy; override;
    function IsIntro: Boolean;
  end;
  TMusicControl = class
  private
    Current, Queued: TNativeMusicTrack;
    FadeLevel, FadeStep: Integer;
    FadeTick, StartQueuedAt: QWord;
    procedure FinishCurrent(Tick: QWord);
    procedure FadeCurrent(Tick: QWord);
  public
    // Retain the last played name after completion for the original repeat rules.
    CurrentFileName, CategoryOverride: WideString;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetVolume(Value: Single);
    procedure Update;
    procedure PlayFile(const FileName: WideString);
    procedure PlayCategory(const Category: WideString);
    procedure RequestFadeOut;
    procedure StopImmediately;
    function GetCurrentFileName: WideString;
    function HasSelectedMusic: Boolean;
    function IsPlaying: Boolean;
  end;
function ChooseMusicFile(const Category, CurrentFile: WideString): WideString;
implementation
uses
  GameNative,
  SysUtils,
  Math,
  GR_Main,
  GR_Sound,
  GlobalsV,
  EC_Str,
  EC_BlockPar;
procedure TMusicControl.SetVolume(Value: Single);
begin
  Value := Max(0, Min(1, Value));
  if Queued <> nil then
    Queued.BaseVolume := Value;
  if Current <> nil then
  begin
    Current.BaseVolume := Value;
    sr_music_volume(SoundVolumeAttenuation(Value, FadeLevel / 10));
  end;
end;
function TMusicControl.GetCurrentFileName: WideString;
begin
  if Current <> nil then
    Result := Current.FileName
  else
    Result := ''
end;
constructor TNativeMusicTrack.Create(const Name: WideString);
begin
  inherited Create;
  FileName := LowerCaseWideString(Name);
  BaseVolume := MusicVolume * MusicVolumeScale;
  Data := TBufEC.Create;
  Data.LoadFromWideFilePath(PWideChar(FileName));
  Handle := sr_music_load(Data.Data, Data.DataSize);
  if Handle = nil then
    raise Exception.Create('SDL music: ' + string(sr_error));
end;
destructor TNativeMusicTrack.Destroy;
begin
  // SDL's decoder borrows the packaged bytes until its handle is released.
  sr_music_free(Handle);
  Data.Free;
  inherited Destroy;
end;
function TNativeMusicTrack.IsIntro: Boolean;
begin
  Result :=
      (FileName = 'music\1c.dat')
          or (FileName = 'music\logo.dat')
          or (FileName = 'music\intro.dat');
end;
constructor TMusicControl.Create;
begin
  inherited Create
end;
destructor TMusicControl.Destroy;
begin
  Clear;
  inherited Destroy
end;
procedure TMusicControl.Clear;
begin
  sr_music_stop;
  FreeAndNil(Current);
  FreeAndNil(Queued);
  FadeStep := 0;
  StartQueuedAt := 0;
  CurrentFileName := '';
end;
procedure TMusicControl.FinishCurrent(Tick: QWord);
begin
  sr_music_stop;
  FreeAndNil(Current);
  FadeStep := 0;
  if Queued <> nil then
    StartQueuedAt := Tick + 210;
end;
procedure TMusicControl.FadeCurrent(Tick: QWord);
begin
  // Intro tracks deliberately skip both ramps in the recovered implementation.
  if (Current = nil) or Current.IsIntro or (FadeStep < 0) then
    Exit;
  FadeStep := -1;
  FadeTick := Tick;
end;
procedure TMusicControl.Update;
var
  Tick, Steps: QWord;
  Remaining: Double;
begin
  Tick := GetTickCount64;
  if Current <> nil then
  begin
    if sr_music_playing = 0 then
      FinishCurrent(Tick)
    else
    begin
      // SDL exposes playback time rather than the old compressed-stream fill level.
      // Start the normal one-second ramp when one second of decoded audio remains.
      if not Current.IsIntro and (FadeStep >= 0) then
      begin
        Remaining := sr_music_remaining(Current.Handle);
        if (Remaining >= 0) and (Remaining <= 1) then
          FadeCurrent(Tick);
      end;
      if FadeStep <> 0 then
      begin
        Steps := Min(QWord(10), (Tick - FadeTick) div 100);
        if Steps > 0 then
        begin
          Inc(FadeTick, Steps * 100);
          FadeLevel := Max(0, Min(10, FadeLevel + FadeStep * Integer(Steps)));
          if (FadeStep < 0) and (FadeLevel = 0) then
            FinishCurrent(Tick)
          else
          begin
            sr_music_volume(SoundVolumeAttenuation(Current.BaseVolume, FadeLevel / 10));
            if FadeLevel = 10 then
              FadeStep := 0;
          end;
        end;
      end;
    end;
  end;
  if (Current = nil) and (Queued <> nil) then
  begin
    // Original controller sleeps 10 ms, then the deferred decoder waits 200 ms.
    if StartQueuedAt = 0 then
      StartQueuedAt := Tick + 210;
    if Tick >= StartQueuedAt then
    begin
      Current := Queued;
      Queued := nil;
      StartQueuedAt := 0;
      CurrentFileName := Current.FileName;
      if Current.IsIntro then
      begin
        FadeLevel := 10;
        FadeStep := 0
      end
      else
      begin
        FadeLevel := 0;
        FadeStep := 1
      end;
      FadeTick := Tick;
      if sr_music_start(Current.Handle, SoundVolumeAttenuation(Current.BaseVolume, FadeLevel / 10))
          = 0 then
        raise Exception.Create('SDL music: ' + string(sr_error));
    end;
  end;
end;
procedure TMusicControl.PlayFile(const FileName: WideString);
var
  Track: TNativeMusicTrack;
  Tick: QWord;
begin
  if not MusicEnabled or (FileName = '') then
    Exit;
  // Prepare the replacement before changing playback or releasing an older queue.
  Track := TNativeMusicTrack.Create(FileName);
  try
    Update;
    FreeAndNil(Queued);
    Queued := Track;
    Track := nil;
    Tick := GetTickCount64;
    StartQueuedAt := 0;
    if Current <> nil then
      FadeCurrent(Tick)
    else
      StartQueuedAt := Tick + 210;
  finally
    Track.Free
  end;
end;
procedure TMusicControl.PlayCategory(const Category: WideString);
var
  Chosen, PlayingFile: WideString;
  Attempts: Integer;
begin
  if not MusicEnabled then
    Exit;
  Update;
  PlayingFile := '';
  if Current <> nil then
    PlayingFile := Current.FileName;
  if CategoryOverride = '' then
  begin
    Chosen := ChooseMusicFile(Category, PlayingFile);
    if (Chosen <> '') and (Chosen = CurrentFileName) then
      Chosen := ChooseMusicFile('All', PlayingFile);
  end
  else
  begin
    Attempts := 0;
    repeat
      Chosen := ChooseMusicFile(CategoryOverride, PlayingFile);
      Inc(Attempts);
      if Attempts > 20 then
        Break;
    until (Chosen = '') or (Chosen <> CurrentFileName);
  end;
  if Chosen <> '' then
    PlayFile(Chosen);
end;
procedure TMusicControl.RequestFadeOut;
begin
  if not MusicEnabled then
    Exit;
  Update;
  FadeCurrent(GetTickCount64);
end;
procedure TMusicControl.StopImmediately;
begin
  if not MusicEnabled then
    Exit;
  Update;
  // Like the original, stop the current track without discarding a queued one.
  if Current <> nil then
    FinishCurrent(GetTickCount64);
end;
function TMusicControl.HasSelectedMusic: Boolean;
begin
  Update;
  Result := (Current <> nil) or (Queued <> nil)
end;
function TMusicControl.IsPlaying: Boolean;
begin
  Update;
  Result := sr_music_playing <> 0
end;
function ChooseMusicFile(const Category, CurrentFile: WideString): WideString;
var
  Block: TBlockParEC;
  Count, Index, Weight: Integer;
begin
  Result := '';
  try
    Block := MainDataConfig.GetBlockByPath('Music.' + Category);
    Count := Block.GetParamCount;
    for Index := 0 to Count - 1 do
      if (Block.GetParamValue(Index) <> '')
          and (TrimWideString(LowerCaseWideString(Block.GetParamValue(Index))) = CurrentFile) then
      begin
        Result := '';
        Exit;
      end;
    Weight := 0;
    for Index := 0 to Count - 1 do
      if Block.GetParamValue(Index) <> '' then
        Inc(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
    if Weight <= 0 then
      Exit;
    Weight := Random(Weight);
    for Index := 0 to Count - 1 do
      if Block.GetParamValue(Index) <> '' then
      begin
        Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
        if Weight < 0 then
        begin
          Result := TrimWideString(LowerCaseWideString(Block.GetParamValue(Index)));
          AppendLogLineThreadSafe(AnsiString(Result));
          Exit;
        end;
      end;
  except
    Result := '';
  end;
end;
end.
