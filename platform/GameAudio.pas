unit GameAudio;

{$MODE DELPHI}
{$POINTERMATH ON}

interface

uses
  DirectSound;

function CreateGameSound(
    Guid: Pointer;
    out Sound: IDirectSound;
    Outer: IInterface
): LongInt; stdcall;
function EnumerateGameSound(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;

implementation

uses
  Classes,
  SysUtils,
  Math,
  SDL2,
  GameEvents;

const
  MixerFrames = 1024;

type
  TGameSound = class;
  TGameAudioMixer = class;
  TGameSoundBuffer = class(TInterfacedObject, IDirectSoundBuffer, IDirectSoundNotify)
  private
    Owner: TGameSound;
    OwnerReference: IDirectSound;
    Data: array of Byte;
    Wave: TSoundWaveFormat;
    Playing, Looping, Primary: Boolean;
    Cursor: Double;
    VolumeDb, PanDb: Integer;
    LeftGain, RightGain: Single;
    Notifications: array of TDSPositionNotify;
    procedure UpdateGains;
    function Sample(Frame, Channel: Integer): Single;
    procedure Mix(Output: PSingle; Frames: Integer);
  public
    constructor Create(AOwner: TGameSound; const Desc: TDSBufferDesc);
    destructor Destroy; override;
    function GetCaps(Caps: Pointer): LongInt; stdcall;
    function GetCurrentPosition(PlayCursor: PCardinal; WriteCursor: PCardinal): LongInt; stdcall;
    function GetFormat(Format: Pointer; Size: Cardinal; Written: PCardinal): LongInt; stdcall;
    function GetVolume(out Volume: Integer): LongInt; stdcall;
    function GetPan(out Pan: Integer): LongInt; stdcall;
    function GetFrequency(out Frequency: Cardinal): LongInt; stdcall;
    function GetStatus(out Status: Cardinal): LongInt; stdcall;
    function Initialize(DirectSound: Pointer; const Desc: TDSBufferDesc): LongInt; stdcall;
    function Lock(
        Offset: Cardinal;
        Bytes: Cardinal;
        Audio1: PPointer;
        Bytes1: PCardinal;
        Audio2: PPointer;
        Bytes2: PCardinal;
        Flags: Cardinal
    ): LongInt; stdcall;
    function Play(Reserved1: Cardinal; Reserved2: Cardinal; Flags: Cardinal): LongInt; stdcall;
    function SetCurrentPosition(Position: Cardinal): LongInt; stdcall;
    function SetFormat(Format: Pointer): LongInt; stdcall;
    function SetVolume(Volume: Integer): LongInt; stdcall;
    function SetPan(Pan: Integer): LongInt; stdcall;
    function SetFrequency(Frequency: Cardinal): LongInt; stdcall;
    function Stop: LongInt; stdcall;
    function Unlock(
        Audio1: Pointer;
        Bytes1: Cardinal;
        Audio2: Pointer;
        Bytes2: Cardinal
    ): LongInt; stdcall;
    function Restore: LongInt; stdcall;
    function SetNotificationPositions(
        Count: Cardinal;
        Positions: PDSPositionNotify
    ): LongInt; stdcall;
  end;
  TGameSound = class(TInterfacedObject, IDirectSound)
    Device: Cardinal;
    Buffers: TFPList;
    MixerLock: TRTLCriticalSection;
    MixerLockReady: Boolean;
    Mixer: TGameAudioMixer;
    procedure Lock;
    procedure Unlock;
    procedure Mix(Samples: PSingle; Frames: Integer);
    constructor Create;
    destructor Destroy; override;
    function CreateSoundBuffer(
        const Desc: TDSBufferDesc;
        out Buffer: IDirectSoundBuffer;
        Outer: IInterface
    ): LongInt; stdcall;
    function GetCaps(Caps: Pointer): LongInt; stdcall;
    function DuplicateSoundBuffer(
        Original: IDirectSoundBuffer;
        out Duplicate: IDirectSoundBuffer
    ): LongInt; stdcall;
    function SetCooperativeLevel(Window: Cardinal; Level: Cardinal): LongInt; stdcall;
    function Compact: LongInt; stdcall;
    function GetSpeakerConfig(out Configuration: Cardinal): LongInt; stdcall;
    function SetSpeakerConfig(Configuration: Cardinal): LongInt; stdcall;
    function Initialize(Guid: Pointer): LongInt; stdcall;
  end;

  TGameAudioMixer = class(TThread)
    Owner: TGameSound;
    constructor Create(AOwner: TGameSound);
    procedure Execute; override;
  end;

procedure TGameSound.Mix(Samples: PSingle; Frames: Integer);
var
  Index: Integer;
begin
  FillChar(Samples^, Frames * 2 * SizeOf(Single), 0);
  // Buffer edits, destruction and mixing share the same critical section.
  for Index := 0 to Buffers.Count - 1 do
    TGameSoundBuffer(Buffers[Index]).Mix(Samples, Frames);
  for Index := 0 to Frames * 2 - 1 do
    Samples[Index] := EnsureRange(Samples[Index], -1.0, 1.0);
end;

constructor TGameAudioMixer.Create(AOwner: TGameSound);
begin
  inherited Create(True);
  Owner := AOwner;
end;

procedure TGameAudioMixer.Execute;
var
  PCM: array[0..MixerFrames * 2 - 1] of Single;
begin
  while not Terminated do
  begin
    if SDL_GetQueuedAudioSize(Owner.Device) > SizeOf(PCM) then
    begin
      Sleep(2);
      Continue;
    end;
    Owner.Lock;
    try
      Owner.Mix(@PCM[0], MixerFrames);
    finally
      Owner.Unlock;
    end;
    // SDL owns the queued copy. Never wait for its audio thread while holding
    // the game mixer lock or invoking notification handlers.
    if SDL_QueueAudio(Owner.Device, @PCM[0], SizeOf(PCM)) < 0 then
      raise Exception.Create('Cannot queue audio: ' + string(SDL_GetError));
  end;
end;

procedure TGameSound.Lock;
begin
  EnterCriticalSection(MixerLock);
end;

procedure TGameSound.Unlock;
begin
  LeaveCriticalSection(MixerLock);
end;

constructor TGameSound.Create;
var
  Desired: TSDL_AudioSpec;
begin
  inherited Create;
  InitCriticalSection(MixerLock);
  MixerLockReady := True;
  Buffers := TFPList.Create;
  if SDL_InitSubSystem(SDL_INIT_AUDIO) < 0 then
    raise Exception.Create(string(SDL_GetError));
  Desired := Default(TSDL_AudioSpec);
  Desired.Frequency := 44100;
  Desired.Format := AUDIO_F32SYS;
  Desired.Channels := 2;
  Desired.Samples := MixerFrames;
  // A nil callback selects SDL's queue. Keep at most two mixer blocks queued
  // (about 46 ms at 44.1 kHz), using the same path on every platform.
  Device := SDL_OpenAudioDevice(nil, 0, @Desired, nil, 0);
  if Device = 0 then
    raise Exception.Create(string(SDL_GetError));
  Mixer := TGameAudioMixer.Create(Self);
  Mixer.Start;
  SDL_PauseAudioDevice(Device, 0);
end;

destructor TGameSound.Destroy;
begin
  if Mixer <> nil then
  begin
    Mixer.Terminate;
    Mixer.WaitFor;
    Mixer.Free;
  end;
  if Device <> 0 then
    SDL_CloseAudioDevice(Device);
  if MixerLockReady then
    DoneCriticalSection(MixerLock);
  Buffers.Free;
  SDL_QuitSubSystem(SDL_INIT_AUDIO);
  inherited Destroy;
end;

constructor TGameSoundBuffer.Create(AOwner: TGameSound; const Desc: TDSBufferDesc);
begin
  inherited Create;
  Owner := AOwner;
  OwnerReference := AOwner;
  Primary := Desc.Flags and DSBCAPS_PRIMARYBUFFER <> 0;
  if Desc.WaveFormat <> nil then
    Move(Desc.WaveFormat^, Wave, SizeOf(Wave));
  SetLength(Data, Desc.BufferBytes);
  if Wave.BitsPerSample = 8 then
    if Length(Data) > 0 then
      FillChar(Data[0], Length(Data), $80);
  UpdateGains;
  Owner.Lock;
  try
    Owner.Buffers.Add(Self);
  finally
    Owner.Unlock;
  end;
end;

destructor TGameSoundBuffer.Destroy;
begin
  Owner.Lock;
  try
    Owner.Buffers.Remove(Self);
  finally
    Owner.Unlock;
  end;
  inherited Destroy;
end;

procedure TGameSoundBuffer.UpdateGains;
var
  Gain: Single;
begin
  if VolumeDb <= -10000 then
    Gain := 0
  else
    Gain := Power(10, VolumeDb / 2000);
  LeftGain := Gain;
  RightGain := Gain;
  if PanDb > 0 then
    LeftGain := Gain * Power(10, -PanDb / 2000)
  else if PanDb < 0 then
    RightGain := Gain * Power(10, PanDb / 2000);
end;

function TGameSoundBuffer.Sample(Frame, Channel: Integer): Single;
var
  Offset: Integer;
  Value: SmallInt;
begin
  if Wave.Channels = 1 then
    Channel := 0;
  Offset := Frame * Wave.BlockAlign + Channel * (Wave.BitsPerSample div 8);
  if Wave.BitsPerSample = 8 then
    Result := (Integer(Data[Offset]) - 128) / 128
  else
  begin
    Move(Data[Offset], Value, SizeOf(Value));
    Result := LEtoN(Value) / 32768;
  end;
end;

procedure TGameSoundBuffer.Mix(Output: PSingle; Frames: Integer);
var
  Index, FrameCount, Frame, NextFrame, Channel, Notice: Integer;
  OldByte, NewByte: Cardinal;
  Fraction, Step, Value: Double;
  Wrapped: Boolean;
begin
  if not Playing or Primary or (Wave.BlockAlign = 0) then
    Exit;
  FrameCount := Length(Data) div Wave.BlockAlign;
  if FrameCount = 0 then
    Exit;
  Step := Wave.SamplesPerSecond / 44100;
  for Index := 0 to Frames - 1 do
  begin
    Frame := Trunc(Cursor);
    NextFrame := Frame + 1;
    if NextFrame >= FrameCount then
      if Looping then
        NextFrame := 0
      else
        NextFrame := Frame;
    Fraction := Cursor - Frame;
    for Channel := 0 to 1 do
    begin
      Value := Sample(Frame, Channel) * (1 - Fraction) + Sample(NextFrame, Channel) * Fraction;
      if Channel = 0 then
        Value := Value * LeftGain
      else
        Value := Value * RightGain;
      Output[Index * 2 + Channel] := Output[Index * 2 + Channel] + Value;
    end;
    OldByte := Frame * Wave.BlockAlign;
    Cursor := Cursor + Step;
    Wrapped := Cursor >= FrameCount;
    NewByte := Min(Trunc(Cursor), FrameCount) * Wave.BlockAlign;
    for Notice := 0 to High(Notifications) do
      if (Notifications[Notice].Offset >= OldByte) and (Notifications[Notice].Offset < NewByte) then
        SetGameEvent(Notifications[Notice].EventHandle);
    if Wrapped then
    begin
      if not Looping then
      begin
        Playing := False;
        Cursor := 0;
        Break;
      end;
      while Cursor >= FrameCount do
        Cursor := Cursor - FrameCount;
      NewByte := Trunc(Cursor) * Wave.BlockAlign;
      for Notice := 0 to High(Notifications) do
        if Notifications[Notice].Offset < NewByte then
          SetGameEvent(Notifications[Notice].EventHandle);
    end;
  end;
end;

function TGameSoundBuffer.GetCaps(Caps: Pointer): LongInt;
begin
  Result := DSERR_UNSUPPORTED;
end;
function TGameSoundBuffer.GetCurrentPosition(
    PlayCursor: PCardinal;
    WriteCursor: PCardinal
): LongInt;
var
  Position: Cardinal;
begin
  Owner.Lock;
  try
    Position := Trunc(Cursor) * Wave.BlockAlign;
    if PlayCursor <> nil then
      PlayCursor^ := Position;
    // The mixer consumes PCM while holding this lock. Lock/Unlock exclude
    // mixing during refill; the SDL queue holds already mixed samples.
    if WriteCursor <> nil then
      WriteCursor^ := Position;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.GetFormat(Format: Pointer; Size: Cardinal; Written: PCardinal): LongInt;
begin
  if Written <> nil then
    Written^ := SizeOf(Wave);
  if Format <> nil then
  begin
    if Size < SizeOf(Wave) then
      Exit(DSERR_INVALIDPARAM);
    Move(Wave, Format^, SizeOf(Wave));
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.GetVolume(out Volume: Integer): LongInt;
begin
  Volume := VolumeDb;
  Result := DS_OK;
end;
function TGameSoundBuffer.GetPan(out Pan: Integer): LongInt;
begin
  Pan := PanDb;
  Result := DS_OK;
end;
function TGameSoundBuffer.GetFrequency(out Frequency: Cardinal): LongInt;
begin
  Frequency := Wave.SamplesPerSecond;
  Result := DS_OK;
end;
function TGameSoundBuffer.GetStatus(out Status: Cardinal): LongInt;
begin
  Owner.Lock;
  try
    Status := Ord(Playing) * DSBSTATUS_PLAYING;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.Initialize(DirectSound: Pointer; const Desc: TDSBufferDesc): LongInt;
begin
  Result := DSERR_ALREADYINITIALIZED;
end;
function TGameSoundBuffer.Lock(
    Offset, Bytes: Cardinal;
    Audio1: PPointer;
    Bytes1: PCardinal;
    Audio2: PPointer;
    Bytes2: PCardinal;
    Flags: Cardinal
): LongInt;
var
  First: Cardinal;
begin
  if Flags and DSBLOCK_ENTIREBUFFER <> 0 then
  begin
    Offset := 0;
    Bytes := Length(Data);
  end;
  if (Length(Data) = 0)
      or (Offset >= Cardinal(Length(Data)))
      or (Bytes > Cardinal(Length(Data)))
      or (Audio1 = nil)
      or (Bytes1 = nil) then
    Exit(DSERR_INVALIDPARAM);
  First := Min(Bytes, Cardinal(Length(Data)) - Offset);
  if (First <> Bytes) and ((Audio2 = nil) or (Bytes2 = nil)) then
    Exit(DSERR_INVALIDPARAM);
  Owner.Lock;
  Audio1^ := @Data[Offset];
  Bytes1^ := First;
  if Audio2 <> nil then
    if First < Bytes then
      Audio2^ := @Data[0]
    else
      Audio2^ := nil;
  if Bytes2 <> nil then
    Bytes2^ := Bytes - First;
  Result := DS_OK;
end;
function TGameSoundBuffer.Unlock(
    Audio1: Pointer;
    Bytes1: Cardinal;
    Audio2: Pointer;
    Bytes2: Cardinal
): LongInt;
begin
  Owner.Unlock;
  Result := DS_OK;
end;
function TGameSoundBuffer.Play(Reserved1, Reserved2, Flags: Cardinal): LongInt;
begin
  Owner.Lock;
  try
    Looping := Flags and DSBPLAY_LOOPING <> 0;
    Playing := True;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.SetCurrentPosition(Position: Cardinal): LongInt;
begin
  if (Wave.BlockAlign = 0) or (Position >= Cardinal(Length(Data))) then
    Exit(DSERR_INVALIDPARAM);
  Owner.Lock;
  try
    Cursor := Position div Wave.BlockAlign;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.SetFormat(Format: Pointer): LongInt;
var
  Value: TSoundWaveFormat;
begin
  if Format = nil then
    Exit(DSERR_INVALIDPARAM);
  Move(Format^, Value, SizeOf(Value));
  if (Value.FormatTag <> 1)
      or not (Value.Channels in [1, 2])
      or not (Value.BitsPerSample in [8, 16])
      or (Value.SamplesPerSecond = 0)
      or (Value.BlockAlign <> Value.Channels * (Value.BitsPerSample div 8)) then
    Exit(DSERR_BADFORMAT);
  Owner.Lock;
  try
    Wave := Value;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.SetVolume(Volume: Integer): LongInt;
begin
  Owner.Lock;
  try
    VolumeDb := EnsureRange(Volume, -10000, 0);
    UpdateGains;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.SetPan(Pan: Integer): LongInt;
begin
  Owner.Lock;
  try
    PanDb := EnsureRange(Pan, -10000, 10000);
    UpdateGains;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.SetFrequency(Frequency: Cardinal): LongInt;
begin
  if Frequency = 0 then
    Exit(DSERR_INVALIDPARAM);
  Owner.Lock;
  try
    Wave.SamplesPerSecond := Frequency;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.Stop: LongInt;
begin
  Owner.Lock;
  try
    Playing := False;
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSoundBuffer.Restore: LongInt;
begin
  Result := DS_OK;
end;
function TGameSoundBuffer.SetNotificationPositions(
    Count: Cardinal;
    Positions: PDSPositionNotify
): LongInt;
begin
  if (Count <> 0) and (Positions = nil) then
    Exit(DSERR_INVALIDPARAM);
  Owner.Lock;
  try
    SetLength(Notifications, Count);
    if Count <> 0 then
      Move(Positions^, Notifications[0], Count * SizeOf(TDSPositionNotify));
  finally
    Owner.Unlock;
  end;
  Result := DS_OK;
end;
function TGameSound.CreateSoundBuffer(
    const Desc: TDSBufferDesc;
    out Buffer: IDirectSoundBuffer;
    Outer: IInterface
): LongInt;
begin
  Buffer := nil;
  if Outer <> nil then
    Exit(DSERR_NOAGGREGATION);
  if (Desc.Flags and DSBCAPS_PRIMARYBUFFER = 0) and (Desc.WaveFormat = nil) then
    Exit(DSERR_BADFORMAT);
  Buffer := TGameSoundBuffer.Create(Self, Desc);
  if Desc.WaveFormat <> nil then
  begin
    Result := Buffer.SetFormat(Desc.WaveFormat);
    if Result <> DS_OK then
      Buffer := nil;
  end
  else
    Result := DS_OK;
end;
function TGameSound.GetCaps(Caps: Pointer): LongInt;
begin
  Result := DSERR_UNSUPPORTED;
end;
function TGameSound.DuplicateSoundBuffer(
    Original: IDirectSoundBuffer;
    out Duplicate: IDirectSoundBuffer
): LongInt;
begin
  Duplicate := nil;
  Result := DSERR_UNSUPPORTED;
end;
function TGameSound.SetCooperativeLevel(Window, Level: Cardinal): LongInt;
begin
  Result := DS_OK;
end;
function TGameSound.Compact: LongInt;
begin
  Result := DS_OK;
end;
function TGameSound.GetSpeakerConfig(out Configuration: Cardinal): LongInt;
begin
  Configuration := 4;
  Result := DS_OK;
end;
function TGameSound.SetSpeakerConfig(Configuration: Cardinal): LongInt;
begin
  if Configuration = 4 then
    Result := DS_OK
  else
    Result := DSERR_UNSUPPORTED;
end;
function TGameSound.Initialize(Guid: Pointer): LongInt;
begin
  Result := DSERR_ALREADYINITIALIZED;
end;
function CreateGameSound(
    Guid: Pointer;
    out Sound: IDirectSound;
    Outer: IInterface
): LongInt; stdcall;
begin
  Sound := nil;
  if Outer <> nil then
    Exit(DSERR_NOAGGREGATION);
  try
    Sound := TGameSound.Create;
    Result := DS_OK;
  except
    on E: Exception do
      Result := DSERR_NODRIVER;
  end;
end;
function EnumerateGameSound(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;
begin
  if Assigned(Callback) then
    Callback(nil, 'SDL default audio device', 'SDL2', Context);
  Result := DS_OK;
end;

end.
