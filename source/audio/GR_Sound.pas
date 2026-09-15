{$EXCESSPRECISION OFF}
unit GR_Sound;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  DirectSound,
  SyncObjs,
  VorbisFile;
type
  TSoundBuffer = class;
  TSoundBufferControl = class;
  TSoundControl = class;
  TSoundBuffer = class(TObjectEx)
    NativeSound: Pointer;
    NativePan: Single;
    Prev: TSoundBuffer;
    Next: TSoundBuffer;
    AutoRelease: Boolean;
    Streaming: Boolean;
    Started: Boolean;
    GapF: array[0..0] of Byte;
    DirectBuffer: IDirectSoundBuffer;
    Notify: IDirectSoundNotify;
    StopEvent: Cardinal;
    ChunkEvents: array[0..2] of Cardinal;
    VolumeEvent: Cardinal;
    BufferBytes: Integer;
    WaveFormat: TSoundWaveFormat;
    VolumeTimer: Cardinal;
    Volume: Single;
    VolumeScale: Single;
    VolumeStep: Single;
    FadingOut: Boolean;
    Gap55: array[0..2] of Byte;
    SoundGroup: Integer;
    Controller: TSoundBufferControl;
    WriteOffset: Integer;
    LastPlayCursor: Cardinal;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SignalStop;
    procedure SetVolumeScale(Value: Single);
    procedure StartVolumeRamp(Interval: Cardinal; Step: Single);
    procedure Init(ByteCount: Integer; Format: Pointer);
    procedure ClearBuf;
    procedure Write(Data: Pointer; ByteCount: Cardinal; Format: Pointer);
    procedure Play(Looping: Boolean);
    function IsPlaying: Boolean;
    procedure SetVolume(Value: Single);
    procedure SetPan(Value: Single);
    function WaitForChunk: Integer;
    procedure InitStream(ChunkBytes: Integer; Format: Pointer);
    function WriteStream(Chunk: Integer; var Decoder: TOggWorker): Boolean;
  end;
  TSoundBufferControl = class(TObjectEx)
    SoundPath: WideString;
    SoundGroup: Integer;
    Looping: Boolean;
    GapD: array[0..2] of Byte;
    Buffer: TSoundBuffer;
    Volume: Single;
    Pan: Single;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Configure(const Path: WideString; Group: Integer; ALooping: Boolean);
    procedure SetVolume(Value: Single);
    procedure SetPan(Value: Single);
    procedure Play;
    function IsPlaying: Boolean;
  end;
  TSoundControl = class(TObjectEx)
    FirstBuffer: TSoundBuffer;
    LastBuffer: TSoundBuffer;
    DirectSound: IDirectSound;
    PrimaryBuffer: IDirectSoundBuffer;
    WaveFormat: TSoundWaveFormat;
    Lock: TCriticalSection;
    LastFadeTick: Cardinal;
    destructor Destroy; override;
    procedure Clear;
    function AddBuffer: TSoundBuffer;
    procedure RemoveBuffer(Buffer: TSoundBuffer);
    function SuppressGroup(Group: Integer; Volume: Single): Boolean;
    procedure StopUncontrolledSounds;
    procedure RemoveFinishedBuffers;
    procedure SignalStop;
    procedure UpdateFades;
    procedure PlaySound(const Path: WideString);
    function PlayEffect(
        const Path: WideString;
        Group: Integer;
        Volume: Single;
        Pan: Single
    ): TSoundBuffer;
    function PlayLoop(
        const Path: WideString;
        Group: Integer;
        Volume: Single;
        Pan: Single
    ): TSoundBuffer;
    constructor Create;
  end;
function SoundVolumeAttenuation(Volume, Scale: Single): Integer;
function SoundErrorText(Code: Integer): AnsiString;
function EnumerateSoundDevice(
    Guid: Pointer;
    Description: PAnsiChar;
    Module: PAnsiChar;
    Context: Pointer
): LongBool; stdcall;
implementation
uses
  GameNative,
  GlobalsV,
  RangersSupport,
  Windows,
  SysUtils,
  GR_Main,
  MMSystem,
  EC_Cache,
  EC_CacheSound,
  EC_Str,
  EC_Mem,
  Math;
function SoundVolumeAttenuation(Volume, Scale: Single): Integer;
begin
  // The original uses -30 dB at scale zero, but mutes a zero base volume.
  if Volume = 0 then
    Result := -10000
  else
    Result := Round(3000 * (Volume * Scale) - 3000);
end;
{ @routine $7F59EC TSoundBufferControl_Create }
constructor TSoundBufferControl.Create;
begin
  inherited Create;
end;
{ @end $7F59EC }
{ @routine $7F5A30 TSoundBufferControl_Destroy }
destructor TSoundBufferControl.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $7F5A30 }
{ @routine $7F5A6C TSoundBufferControl_Clear }
procedure TSoundBufferControl.Clear;
begin
  if Buffer <> nil then
  begin
    Buffer.Controller := nil;
    Buffer.Clear;
    Buffer := nil;
    Volume := 0;
    Pan := 0;
  end;
end;
{ @end $7F5A6C }
{ @routine $7F5AB0 TSoundBufferControl_Configure }
procedure TSoundBufferControl.Configure(const Path: WideString; Group: Integer; ALooping: Boolean);
begin
  if SoundPath <> Path then
  begin
    Clear;
    SoundGroup := Group;
    SoundPath := Path;
    Looping := ALooping;
  end;
end;
{ @end $7F5AB0 }
{ @routine $7F5B00 TSoundBufferControl_SetVolume }
procedure TSoundBufferControl.SetVolume(Value: Single);
begin
  if Volume = Value then
    Exit;
  if Looping then
  begin
    if Value = 0 then
    begin
      if Buffer <> nil then
        Clear;
    end
    else
    begin
      Volume := Value;
      if Buffer = nil then
      begin
        Buffer := SoundManager.PlayLoop(SoundPath, SoundGroup, Volume, Pan);
        if Buffer <> nil then
          Buffer.Controller := Self;
      end
      else
        Buffer.SetVolumeScale(Volume);
    end;
  end
  else
  begin
    Volume := Value;
    if Buffer <> nil then
      Buffer.SetVolumeScale(Volume);
  end;
end;
{ @end $7F5B00 }
{ @routine $7F5BE4 TSoundBufferControl_SetPan }
procedure TSoundBufferControl.SetPan(Value: Single);
begin
  if Pan = Value then
    Exit;
  Pan := Value;
  if Looping then
  begin
    if Buffer = nil then
    begin
      Buffer := SoundManager.PlayLoop(SoundPath, SoundGroup, Volume, Pan);
      if Buffer <> nil then
        Buffer.Controller := Self;
    end
    else
      Buffer.SetPan(Pan);
  end
  else if Buffer <> nil then
    Buffer.SetPan(Pan);
end;
{ @end $7F5BE4 }
{ @routine $7F5C8C TSoundBufferControl_Play }
procedure TSoundBufferControl.Play;
begin
  if Looping then
    Exit;
  if Buffer <> nil then
    Clear;
  Buffer := SoundManager.PlayEffect(SoundPath, SoundGroup, Volume, Pan);
  if Buffer <> nil then
    Buffer.Controller := Self;
end;
{ @end $7F5C8C }
{ @routine $7F5CF0 TSoundBufferControl_IsPlaying }
function TSoundBufferControl.IsPlaying: Boolean;
begin
  Result := False;
  if Buffer <> nil then
    Result := Buffer.IsPlaying;
end;
{ @end $7F5CF0 }
{ @routine $7F5D1C TSoundBuffer_Create }
constructor TSoundBuffer.Create;
begin
  inherited Create;
  Volume := 1;
  VolumeScale := 1
end;
{ @end $7F5D1C }
{ @routine $7F5E5C TSoundBuffer_Destroy }
destructor TSoundBuffer.Destroy;
begin
  Clear;
  inherited Destroy
end;
{ @end $7F5E5C }
{ @routine $7F5F08 TSoundBuffer_Clear }
procedure TSoundBuffer.Clear;
begin
  if Controller <> nil then
  begin
    Controller.Buffer := nil;
    Controller.Volume := 0;
    Controller := nil
  end;
  sr_sound_free(NativeSound);
  NativeSound := nil;
  BufferBytes := 0;
  Streaming := False;
  Started := False;
end;
{ @end $7F5F08 }
{ @routine $7F70D8 TSoundBuffer_SignalStop }
procedure TSoundBuffer.SignalStop;
begin
  sr_sound_stop(NativeSound);
  Started := False
end;
{ @end $7F70D8 }
{ @routine $7F735C TSoundBuffer_SetVolumeScale }
procedure TSoundBuffer.SetVolumeScale(Value: Single);
begin
  VolumeScale := Value;
  if VolumeScale < 0 then
    VolumeScale := 0
  else if VolumeScale > 1 then
    VolumeScale := 1;
  SetVolume(Volume);
end;
{ @end $7F735C }
{ @routine $7F73C0 TSoundBuffer_StartVolumeRamp }
procedure TSoundBuffer.StartVolumeRamp(Interval: Cardinal; Step: Single);
begin
  VolumeStep := Step;
  FadingOut := Step < 0
end;
{ @end $7F73C0 }
{ @routine $7F7CB4 TSoundControl_Destroy }
destructor TSoundControl.Destroy;
begin
  Clear;
  PrimaryBuffer := nil;
  DirectSound := nil;
  sr_audio_close;
  Lock.Free;
  inherited Destroy;
end;
{ @end $7F7CB4 }
{ @routine $7F7D10 TSoundControl_Clear }
procedure TSoundControl.Clear;
begin
  while FirstBuffer <> nil do
    RemoveBuffer(FirstBuffer);
end;
{ @end $7F7D10 }
{ @routine $7F7DA4 TSoundControl_AddBuffer }
function TSoundControl.AddBuffer: TSoundBuffer;
var
  Buffer: TSoundBuffer;
begin
  Lock.Enter;
  try
    Buffer := TSoundBuffer.Create;
    if LastBuffer <> nil then
      LastBuffer.Next := Buffer;
    Buffer.Prev := LastBuffer;
    Buffer.Next := nil;
    LastBuffer := Buffer;
    if FirstBuffer = nil then
      FirstBuffer := Buffer;
  finally
    Lock.Leave;
  end;
  Result := Buffer;
end;
{ @end $7F7DA4 }
{ @routine $7F7E48 TSoundControl_RemoveBuffer }
procedure TSoundControl.RemoveBuffer(Buffer: TSoundBuffer);
begin
  Lock.Enter;
  try
    if Buffer.Prev <> nil then
      Buffer.Prev.Next := Buffer.Next;
    if Buffer.Next <> nil then
      Buffer.Next.Prev := Buffer.Prev;
    if LastBuffer = Buffer then
      LastBuffer := Buffer.Prev;
    if FirstBuffer = Buffer then
      FirstBuffer := Buffer.Next;
    Buffer.Free;
  finally
    Lock.Leave;
  end;
end;
{ @end $7F7E48 }
{ @routine $7F7EF8 TSoundControl_SuppressGroup }
function TSoundControl.SuppressGroup(Group: Integer; Volume: Single): Boolean;
var
  Buffer: TSoundBuffer;
begin
  Result := False;
  Lock.Enter;
  try
    Buffer := FirstBuffer;
    while Buffer <> nil do
    begin
      if Buffer.SoundGroup = Group then
      begin
        if Buffer.VolumeScale >= Volume then
        begin
          Result := True;
          Exit;
        end;
        Buffer.FadingOut := True;
        if Buffer.Controller <> nil then
        begin
          Buffer.Controller.Buffer := nil;
          Buffer.Controller.Volume := 0;
          Buffer.Controller := nil;
        end;
      end;
      Buffer := Buffer.Next;
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $7F7EF8 }
{ @routine $7F7D34 TSoundControl_StopUncontrolledSounds }
procedure TSoundControl.StopUncontrolledSounds;
var
  NextBuffer, Buffer: TSoundBuffer;
begin
  Lock.Enter;
  NextBuffer := FirstBuffer;
  while NextBuffer <> nil do
  begin
    Buffer := NextBuffer;
    NextBuffer := NextBuffer.Next;
    if (Buffer.Controller = nil) and not Buffer.Streaming and Buffer.IsPlaying then
      RemoveBuffer(Buffer);
  end;
  Lock.Leave;
end;
{ @end $7F7D34 }
{ @routine $7F7FBC TSoundControl_RemoveFinishedBuffers }
procedure TSoundControl.RemoveFinishedBuffers;
var
  NextBuffer, Buffer: TSoundBuffer;
begin
  Lock.Enter;
  try
    NextBuffer := FirstBuffer;
    while NextBuffer <> nil do
    begin
      Buffer := NextBuffer;
      NextBuffer := NextBuffer.Next;
      if Buffer.AutoRelease and not Buffer.IsPlaying then
        RemoveBuffer(Buffer);
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $7F7FBC }
{ @routine $7F84D0 TSoundControl_SignalStop }
procedure TSoundControl.SignalStop;
var
  Buffer: TSoundBuffer;
begin
  Lock.Enter;
  Buffer := FirstBuffer;
  while Buffer <> nil do
  begin
    Buffer.SignalStop;
    Buffer := Buffer.Next;
  end;
  Lock.Leave;
end;
{ @end $7F84D0 }
{ @routine $7F8048 TSoundControl_UpdateFades }
procedure TSoundControl.UpdateFades;
var
  NextBuffer, Buffer: TSoundBuffer;
  NewVolume: Single;
  Tick: Cardinal;
begin
  Tick := timeGetTime;
  if Tick - LastFadeTick < 10 then
    Exit;
  LastFadeTick := Tick;
  Lock.Enter;
  try
    NextBuffer := FirstBuffer;
    while NextBuffer <> nil do
    begin
      Buffer := NextBuffer;
      NextBuffer := NextBuffer.Next;
      if Buffer.FadingOut then
      begin
        NewVolume := Max(0, Buffer.VolumeScale - 0.05);
        if NewVolume > 0.05 then
          Buffer.SetVolumeScale(NewVolume)
        else
          RemoveBuffer(Buffer);
      end;
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $7F8048 }
{ @routine $7F815C TSoundControl_PlaySound }
procedure TSoundControl.PlaySound(const Path: WideString);
var
  Control: TCSoundControlEC;
  Sound: TCSoundEC;
  Buffer: TSoundBuffer;
begin
  if Path = '' then
    Exit;
  if not SoundEnabled then
    Exit;
  Control := nil;
  RemoveFinishedBuffers;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(1);
    Buffer.Play(False);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $7F815C }
{ @routine $7F8258 TSoundControl_PlayEffect }
function TSoundControl.PlayEffect(
    const Path: WideString;
    Group: Integer;
    Volume, Pan: Single
): TSoundBuffer;
var
  Control: TCSoundControlEC;
  Sound: TCSoundEC;
  Buffer: TSoundBuffer;
begin
  Result := nil;
  if Path = '' then
    Exit;
  if not SoundEnabled then
    Exit;
  Control := nil;
  RemoveFinishedBuffers;
  if (Group <> 0) and SuppressGroup(Group, Volume) then
    Exit;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.SoundGroup := Group;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(Volume);
    Buffer.SetPan(Pan);
    Buffer.Play(False);
    Result := Buffer;
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $7F8258 }
{ @routine $7F8394 TSoundControl_PlayLoop }
function TSoundControl.PlayLoop(
    const Path: WideString;
    Group: Integer;
    Volume, Pan: Single
): TSoundBuffer;
var
  Control: TCSoundControlEC;
  Sound: TCSoundEC;
  Buffer: TSoundBuffer;
begin
  Result := nil;
  if Path = '' then
    Exit;
  if not SoundEnabled then
    Exit;
  Control := nil;
  RemoveFinishedBuffers;
  if (Group <> 0) and SuppressGroup(Group, Volume) then
    Exit;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.SoundGroup := Group;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(Volume);
    Buffer.SetPan(Pan);
    Buffer.Play(True);
    Result := Buffer;
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $7F8394 }
{ @routine $7F5360 SoundErrorText }
function SoundErrorText(Code: Integer): AnsiString;
begin
  Result := '';
  case Code of
    DS_OK: Result := 'DS_OK';
    DS_NO_VIRTUALIZATION: Result := 'DS_NO_VIRTUALIZATION';
    DS_INCOMPLETE: Result := 'DS_INCOMPLETE';
    DSERR_ALLOCATED: Result := 'DSERR_ALLOCATED';
    DSERR_CONTROLUNAVAIL: Result := 'DSERR_CONTROLUNAVAIL';
    DSERR_INVALIDPARAM: Result := 'DSERR_INVALIDPARAM';
    DSERR_INVALIDCALL: Result := 'DSERR_INVALIDCALL';
    DSERR_GENERIC: Result := 'DSERR_GENERIC';
    DSERR_PRIOLEVELNEEDED: Result := 'DSERR_PRIOLEVELNEEDED';
    DSERR_OUTOFMEMORY: Result := 'DSERR_OUTOFMEMORY';
    DSERR_BADFORMAT: Result := 'DSERR_BADFORMAT';
    DSERR_UNSUPPORTED: Result := 'DSERR_UNSUPPORTED';
    DSERR_NODRIVER: Result := 'DSERR_NODRIVER';
    DSERR_ALREADYINITIALIZED: Result := 'DSERR_ALREADYINITIALIZED';
    DSERR_NOAGGREGATION: Result := 'DSERR_NOAGGREGATION';
    DSERR_BUFFERLOST: Result := 'DSERR_BUFFERLOST';
    DSERR_OTHERAPPHASPRIO: Result := 'DSERR_OTHERAPPHASPRIO';
    DSERR_UNINITIALIZED: Result := 'DSERR_UNINITIALIZED';
    DSERR_NOINTERFACE: Result := 'DSERR_NOINTERFACE';
    DSERR_ACCESSDENIED: Result := 'DSERR_ACCESSDENIED';
    DSERR_BUFFERTOOSMALL: Result := 'DSERR_BUFFERTOOSMALL';
    DSERR_DS8_REQUIRED: Result := 'DSERR_DS8_REQUIRED';
    DSERR_SENDLOOP: Result := 'DSERR_SENDLOOP';
    DSERR_BADSENDBUFFERGUID: Result := 'DSERR_BADSENDBUFFERGUID';
    DSERR_OBJECTNOTFOUND: Result := 'DSERR_OBJECTNOTFOUND';
    DSERR_FXUNAVAILABLE: Result := 'DSERR_FXUNAVAILABLE';
  else
    Result := 'unrecognized DirectSound error ' + CardinalToHexWideString(Code);
  end;
end;
{ @end $7F5360 }
{ @routine $7F5FEC TSoundBuffer_Init }
procedure TSoundBuffer.Init(ByteCount: Integer; Format: Pointer);
begin
  Clear;
  BufferBytes := ByteCount;
  Move(Format^, WaveFormat, SizeOf(WaveFormat))
end;
{ @end $7F5FEC }
{ @routine $7F657C TSoundBuffer_ClearBuf }
procedure TSoundBuffer.ClearBuf;
begin
  sr_sound_stop(NativeSound)
end;
{ @end $7F657C }
{ @routine $7F674C TSoundBuffer_Write }
procedure TSoundBuffer.Write(Data: Pointer; ByteCount: Cardinal; Format: Pointer);
begin
  Init(ByteCount, Format);
  NativeSound :=
      sr_sound_create(
          Data,
          ByteCount,
          WaveFormat.SamplesPerSecond,
          WaveFormat.Channels,
          WaveFormat.BitsPerSample
      );
  if NativeSound = nil then
    raise Exception.Create('SDL sound: ' + string(sr_error));
end;
{ @end $7F674C }
{ @routine $7F6CE0 TSoundBuffer_Play }
procedure TSoundBuffer.Play(Looping: Boolean);
begin
  sr_sound_volume(
      NativeSound,
      SoundVolumeAttenuation(Volume, VolumeScale),
      Round(10000 * NativePan)
  );
  Started := sr_sound_play(NativeSound, Ord(Looping)) <> 0;
end;
{ @end $7F6CE0 }
{ @routine $7F6FC0 TSoundBuffer_IsPlaying }
function TSoundBuffer.IsPlaying: Boolean;
begin
  Result := sr_sound_playing(NativeSound) <> 0
end;
{ @end $7F6FC0 }
{ @routine $7F70F0 TSoundBuffer_SetVolume }
procedure TSoundBuffer.SetVolume(Value: Single);
begin
  Volume := Max(0, Min(1, Value));
  sr_sound_volume(
      NativeSound,
      SoundVolumeAttenuation(Volume, VolumeScale),
      Round(10000 * NativePan)
  )
end;
{ @end $7F70F0 }
{ @routine $7F7420 TSoundBuffer_SetPan }
procedure TSoundBuffer.SetPan(Value: Single);
begin
  NativePan := Max(-1, Min(1, Value));
  sr_sound_volume(
      NativeSound,
      SoundVolumeAttenuation(Volume, VolumeScale),
      Round(10000 * NativePan)
  )
end;
{ @end $7F7420 }
{ @routine $7F6EC4 TSoundBuffer_WaitForChunk }
function TSoundBuffer.WaitForChunk: Integer;
begin
  raise Exception.Create('Native music uses SDL streaming')
end;
{ @end $7F6EC4 }
{ @routine $7F6184 TSoundBuffer_InitStream }
procedure TSoundBuffer.InitStream(ChunkBytes: Integer; Format: Pointer);
begin
  raise Exception.Create('Native music uses SDL streaming')
end;
{ @end $7F6184 }
{ @routine $7F6940 TSoundBuffer_WriteStream }
function TSoundBuffer.WriteStream(Chunk: Integer; var Decoder: TOggWorker): Boolean;
begin
  raise Exception.Create('Native music uses SDL streaming')
end;
{ @end $7F6940 }
{ @routine $7F7560 EnumerateSoundDevice }
function EnumerateSoundDevice(
    Guid: Pointer;
    Description, Module: PAnsiChar;
    Context: Pointer
): LongBool; stdcall;
var
  Text: WideString;
begin
  Text := SysUtils.Format('- %s', [Description]);
  AppendLogLineThreadSafe(Text);
  if FindTextOffsetW(Text, 'Xonar', 0) >= 0 then
    XonarSoundDevice := True;
  Result := True;
end;
{ @end $7F7560 }
{ @routine $7F7634 TSoundControl_Create }
constructor TSoundControl.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  if (SoundEnabled or MusicEnabled) and (sr_audio_open = 0) then
  begin
    AppendLogLineThreadSafe('Audio unavailable: ' + string(sr_error));
    SoundEnabled := False;
    MusicEnabled := False
  end;
end;
{ @end $7F7634 }
end.
