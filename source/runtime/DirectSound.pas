{$EXCESSPRECISION OFF}
unit DirectSound;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
type
  IDirectSoundNotify = interface;
  IDirectSoundBuffer = interface;
  IDirectSound = interface;
  PointerToTDSPositionNotify = ^TDSPositionNotify;
  TDSPositionNotify = record
    Offset: Cardinal;
    EventHandle: Cardinal;
  end;
  PDSPositionNotify = PointerToTDSPositionNotify;
  IDirectSoundNotify = interface(IInterface)
    ['{B0210783-89CD-11D0-AF08-00A0C925CD16}']
    function SetNotificationPositions(
        Count: Cardinal;
        Positions: PDSPositionNotify
    ): LongInt; stdcall;
  end;
  TDSBufferDesc = record
    Size: Cardinal;
    Flags: Cardinal;
    BufferBytes: Cardinal;
    Reserved: Cardinal;
    WaveFormat: Pointer;
    Algorithm: TGUID;
  end;
  IDirectSoundBuffer = interface(IInterface)
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
  end;
  TSoundWaveFormat = record
    FormatTag: Word;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    AverageBytesPerSecond: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    ExtraSize: Word;
    Gap12: array[0..1] of Byte;
  end;
  IDirectSound = interface(IInterface)
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
  end;
  TDSEnumCallback =
      function(
          Guid: Pointer;
          Description: PAnsiChar;
          Module: PAnsiChar;
          Context: Pointer
      ): LongBool; stdcall;
  TDirectSoundCreate =
      function(Guid: Pointer; out DirectSound: IDirectSound; Outer: IInterface): LongInt; stdcall;
  TDirectSoundEnumerate = function(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;
const
  DS_OK = 0;
  DS_NO_VIRTUALIZATION = 142082058;
  DS_INCOMPLETE = 142082068;
  DSERR_ALLOCATED = -2005401590;
  DSERR_CONTROLUNAVAIL = -2005401570;
  DSERR_INVALIDPARAM = -2147024809;
  DSERR_INVALIDCALL = -2005401550;
  DSERR_GENERIC = -2147467259;
  DSERR_PRIOLEVELNEEDED = -2005401530;
  DSERR_OUTOFMEMORY = -2147024882;
  DSERR_BADFORMAT = -2005401500;
  DSERR_UNSUPPORTED = -2147467263;
  DSERR_NODRIVER = -2005401480;
  DSERR_ALREADYINITIALIZED = -2005401470;
  DSERR_NOAGGREGATION = -2147221232;
  DSERR_BUFFERLOST = -2005401450;
  DSERR_OTHERAPPHASPRIO = -2005401440;
  DSERR_UNINITIALIZED = -2005401430;
  DSERR_NOINTERFACE = -2147467262;
  DSERR_ACCESSDENIED = -2147024891;
  DSERR_BUFFERTOOSMALL = -2005401420;
  DSERR_DS8_REQUIRED = -2005401410;
  DSERR_SENDLOOP = -2005401400;
  DSERR_BADSENDBUFFERGUID = -2005401390;
  DSERR_OBJECTNOTFOUND = -2005397151;
  DSERR_FXUNAVAILABLE = -2005401380;
  DSBCAPS_PRIMARYBUFFER = $00000001;
  DSBCAPS_STATIC = $00000002;
  DSBCAPS_LOCSOFTWARE = $00000008;
  DSBCAPS_CTRLPAN = $00000040;
  DSBCAPS_CTRLVOLUME = $00000080;
  DSBCAPS_CTRLPOSITIONNOTIFY = $00000100;
  DSBCAPS_GETCURRENTPOSITION2 = $00010000;
  DSBPLAY_LOOPING = 1;
  DSBLOCK_ENTIREBUFFER = 2;
  DSBSTATUS_PLAYING = 1;
  DSSCL_PRIORITY = 2;
  DSBVOLUME_MIN = -10000;
  DSBPAN_LEFT = -10000;
  DSBPAN_RIGHT = 10000;
var
  DirectSoundCreate: TDirectSoundCreate;
  DirectSoundEnumerate: TDirectSoundEnumerate;
function DirectSoundEnumerateA(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;
implementation
uses
  Math,
  RangersSupport,
  SysUtils,
  Windows;
function DirectSoundEnumerateA(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
end.
