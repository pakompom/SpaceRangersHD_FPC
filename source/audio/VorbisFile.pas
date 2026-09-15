{$EXCESSPRECISION OFF}
unit VorbisFile;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SyncObjs,
  DirectSound,
  EC_FileStream;
type
  PointerToTCriticalSection = ^TCriticalSection;
const
  VorbisOutputChannels = 2;
  VorbisOutputSampleRate = 44100;
  VorbisOutputSampleBytes = SizeOf(SmallInt);
  VorbisOutputBlockAlign = VorbisOutputChannels * VorbisOutputSampleBytes;
  VorbisOutputBytesPerSecond = VorbisOutputSampleRate * VorbisOutputBlockAlign;
type
  TOggWorker = class;
  PCriticalSection = PointerToTCriticalSection;
  TOggWorker = class(TObject)
    Gap4: array[0..3] of Byte;
    VorbisState: array[0..719] of Byte;
    Lock: PCriticalSection;
    Bitstream: Integer;
    ExternalLibrary: Boolean;
    Gap2E1: array[0..2] of Byte;
    constructor Create(SharedLock: PCriticalSection; UseExternalLibrary: Boolean);
    destructor Destroy; override;
  end;
  TVorbisReadCallback =
      function(Buffer: Pointer; Size: Cardinal; Count: Cardinal; Source: Pointer): Cardinal; cdecl;
  TVorbisSeekCallback = function(Source: Pointer; Offset: Int64; Origin: Integer): Integer; cdecl;
  TVorbisCloseCallback = function(Source: Pointer): Integer; cdecl;
  TVorbisTellCallback = function(Source: Pointer): Integer; cdecl;
  TVorbisCallbacks = record
    Read: TVorbisReadCallback;
    Seek: TVorbisSeekCallback;
    Close: TVorbisCloseCallback;
    Tell: TVorbisTellCallback;
  end;
  TVorbisFileStatus = function(State: Pointer): Integer; cdecl;
  TVorbisFOpen = function(Path: PAnsiChar; State: Pointer): Integer; cdecl;
  TVorbisOpenCallbacks =
      function(
          Source: Pointer;
          State: Pointer;
          Initial: PAnsiChar;
          InitialBytes: Integer;
          Callbacks: TVorbisCallbacks
      ): Integer; cdecl;
  TVorbisLinkStatus = function(State: Pointer; Link: Integer): Integer; cdecl;
  TVorbisLinkCount = function(State: Pointer; Link: Integer): Int64; cdecl;
  TVorbisLinkTime = function(State: Pointer; Link: Integer): Double; cdecl;
  TVorbisSeekOffset = function(State: Pointer; Offset: Int64): Integer; cdecl;
  TVorbisSeekTime = function(State: Pointer; Seconds: Double): Integer; cdecl;
  TVorbisTellOffset = function(State: Pointer): Int64; cdecl;
  TVorbisTellTime = function(State: Pointer): Double; cdecl;
  TVorbisLinkInfo = function(State: Pointer; Link: Integer): Pointer; cdecl;
  TVorbisReadFloat =
      function(
          State: Pointer;
          var Channels: Pointer;
          Samples: Integer;
          var Bitstream: Integer
      ): Integer; cdecl;
  TVorbisRead =
      function(
          State: Pointer;
          Buffer: Pointer;
          Length: Integer;
          BigEndian: Integer;
          WordSize: Integer;
          SignedSamples: Integer;
          var Bitstream: Integer
      ): Integer; cdecl;
var
  VorbisLoaded: Boolean = False;
  VorbisClear: TVorbisFileStatus;
  VorbisFOpen: TVorbisFOpen;
  VorbisOpenCallbacks: TVorbisOpenCallbacks;
  VorbisTestCallbacks: TVorbisOpenCallbacks;
  VorbisTestOpen: TVorbisFileStatus;
  VorbisBitrate: TVorbisLinkStatus;
  VorbisBitrateInstant: TVorbisFileStatus;
  VorbisStreams: TVorbisFileStatus;
  VorbisSeekable: TVorbisFileStatus;
  VorbisSerialNumber: TVorbisLinkStatus;
  VorbisRawTotal: TVorbisLinkCount;
  VorbisPcmTotal: TVorbisLinkCount;
  VorbisTimeTotal: TVorbisLinkTime;
  VorbisRawSeek: TVorbisSeekOffset;
  VorbisPcmSeek: TVorbisSeekOffset;
  VorbisPcmSeekPage: TVorbisSeekOffset;
  VorbisTimeSeek: TVorbisSeekTime;
  VorbisTimeSeekPage: TVorbisSeekTime;
  VorbisRawTell: TVorbisTellOffset;
  VorbisPcmTell: TVorbisTellOffset;
  VorbisTimeTell: TVorbisTellTime;
  VorbisInfo: TVorbisLinkInfo;
  VorbisComment: TVorbisLinkInfo;
  VorbisReadFloat: TVorbisReadFloat;
  VorbisRead: TVorbisRead;
  VorbisUseCount: Integer;
  VorbisCallbacks: TVorbisCallbacks;
  VorbisLibrary: Cardinal;
function ReadVorbisSource(
    Buffer: Pointer;
    Size: Cardinal;
    Count: Cardinal;
    Source: Pointer
): Cardinal; cdecl;
function OpenVorbisStream(
    Decoder: TOggWorker;
    var Format: TSoundWaveFormat;
    var Stream: TFileStreamEC
): Integer; stdcall;
function ReadVorbisSamples(
    Decoder: TOggWorker;
    Buffer: Pointer;
    var ByteCount: Integer
): Integer; stdcall;
procedure LoadVorbisLibrary;
implementation
uses
  Math,
  EC_Mem,
  GR_Main,
  SysUtils,
  Windows,
  MMSystem;
const
  // libvorbis codec.h status codes returned by ov_read.
  OV_HOLE = -3;
  OV_EINVAL = -131;
  OV_EBADLINK = -137;
  VorbisLittleEndian = 0;
  VorbisSignedSamples = 1;
  VorbisScratchBytes = 4096;

function ReadVorbisSource(Buffer: Pointer; Size, Count: Cardinal; Source: Pointer): Cardinal; cdecl;
var
  Stream: TFileStreamEC;
begin
  Stream := Source;
  Result := Stream.Read(Buffer, Size * Count);
end;

constructor TOggWorker.Create(SharedLock: PCriticalSection; UseExternalLibrary: Boolean);
begin
  inherited Create;
  // Materialize the value before Self, as in the native DCC32 assignment.
  Lock := PCriticalSection(PtrUInt(SharedLock) + 0);
  if not UseExternalLibrary then
  begin
    Lock^.Enter;
    if not VorbisLoaded then
    begin
      VorbisUseCount := 1;
      LoadVorbisLibrary;
    end
    else
      Inc(VorbisUseCount);
    Lock^.Leave;
  end;
  ExternalLibrary := UseExternalLibrary;
end;

destructor TOggWorker.Destroy;
begin
  if not ExternalLibrary then
  begin
    Lock^.Enter;
    Dec(VorbisUseCount);
    // The native routine still compares the count, but has no unload body.
    Lock^.Leave;
  end;
  inherited Destroy;
end;

function OpenVorbisStream(
    Decoder: TOggWorker;
    var Format: TSoundWaveFormat;
    var Stream: TFileStreamEC
): Integer; stdcall;
begin
  Format.FormatTag := WAVE_FORMAT_PCM;
  Format.Channels := VorbisOutputChannels;
  Format.BitsPerSample := VorbisOutputSampleBytes * 8;
  Format.ExtraSize := 0;
  Format.SamplesPerSecond := VorbisOutputSampleRate;
  Format.BlockAlign := VorbisOutputBlockAlign;
  Format.AverageBytesPerSecond := VorbisOutputBytesPerSecond;
  Decoder.Bitstream := 0;
  Decoder.Lock^.Enter;
  Result := VorbisOpenCallbacks(Stream, @Decoder.VorbisState, nil, 0, VorbisCallbacks);
  Decoder.Lock^.Leave;
  if Result <> 0 then
    raise Exception.Create('Error open audiofile.')
  else
    Result := 1;
end;

function ReadVorbisSamples(
    Decoder: TOggWorker;
    Buffer: Pointer;
    var ByteCount: Integer
): Integer; stdcall;
var
  Total, Count, Remaining: Integer;
  Temp: array of AnsiChar;
  Done: Boolean;
begin
  SetLength(Temp, VorbisScratchBytes);
  Total := 0;
  Remaining := ByteCount;
  Done := False;
  Decoder.Lock^.Enter;
  while not Done do
  begin
    Count :=
        VorbisRead(
            @Decoder.VorbisState,
            Pointer(Temp),
            Remaining,
            VorbisLittleEndian,
            VorbisOutputSampleBytes,
            VorbisSignedSamples,
            Decoder.Bitstream
        );
    if Count = OV_EBADLINK then
      Break;
    if Count = OV_HOLE then
      Break;
    if Count = OV_EINVAL then
      Break;
    if Count = 0 then
      Break;
    CopyMemory(AddPointerOffset(Buffer, Total), @Temp[0], Count);
    Inc(Total, Count);
    Dec(Remaining, Count);
    if Remaining = 0 then
      Break;
  end;
  Decoder.Lock^.Leave;
  ByteCount := Total;
  Result := Total;
end;

procedure LoadVorbisLibrary;
begin
  AppendLogTextThreadSafe('Loading libvorbisfile.dll....');
  VorbisLibrary := Windows.LoadLibrary('libvorbisfile.dll');
  if VorbisLibrary <> 0 then
  begin
    AppendLogLineThreadSafe('ok!');
    VorbisLoaded := True;
    @VorbisClear := GetProcAddress(VorbisLibrary, 'ov_clear');
    @VorbisFOpen := GetProcAddress(VorbisLibrary, 'ov_fopen');
    @VorbisOpenCallbacks := GetProcAddress(VorbisLibrary, 'ov_open_callbacks');
    @VorbisTestCallbacks := GetProcAddress(VorbisLibrary, 'ov_test_callbacks');
    @VorbisTestOpen := GetProcAddress(VorbisLibrary, 'ov_test_open');
    @VorbisBitrate := GetProcAddress(VorbisLibrary, 'ov_bitrate');
    @VorbisBitrateInstant := GetProcAddress(VorbisLibrary, 'ov_bitrate_instant');
    @VorbisStreams := GetProcAddress(VorbisLibrary, 'ov_streams');
    @VorbisSeekable := GetProcAddress(VorbisLibrary, 'ov_seekable');
    @VorbisSerialNumber := GetProcAddress(VorbisLibrary, 'ov_serialnumber');
    @VorbisRawTotal := GetProcAddress(VorbisLibrary, 'ov_raw_total');
    @VorbisPcmTotal := GetProcAddress(VorbisLibrary, 'ov_pcm_total');
    @VorbisTimeTotal := GetProcAddress(VorbisLibrary, 'ov_time_total');
    @VorbisRawSeek := GetProcAddress(VorbisLibrary, 'ov_raw_seek');
    @VorbisPcmSeek := GetProcAddress(VorbisLibrary, 'ov_pcm_seek');
    @VorbisPcmSeekPage := GetProcAddress(VorbisLibrary, 'ov_pcm_seek_page');
    @VorbisTimeSeek := GetProcAddress(VorbisLibrary, 'ov_time_seek');
    @VorbisTimeSeekPage := GetProcAddress(VorbisLibrary, 'ov_time_seek_page');
    @VorbisRawTell := GetProcAddress(VorbisLibrary, 'ov_raw_tell');
    @VorbisPcmTell := GetProcAddress(VorbisLibrary, 'ov_pcm_tell');
    @VorbisTimeTell := GetProcAddress(VorbisLibrary, 'ov_time_tell');
    @VorbisInfo := GetProcAddress(VorbisLibrary, 'ov_info');
    @VorbisComment := GetProcAddress(VorbisLibrary, 'ov_comment');
    @VorbisReadFloat := GetProcAddress(VorbisLibrary, 'ov_read_float');
    @VorbisRead := GetProcAddress(VorbisLibrary, 'ov_read');
  end
  else
  begin
    AppendLogTextThreadSafe('FAIL');
    AppendLogLineThreadSafe(' GetLastError=' + IntToStr(Int64(GetLastError)));
    raise Exception.Create('Error load=libvorbisfile.dll ' + SysErrorMessage(GetLastError));
  end;
  VorbisCallbacks.Read := ReadVorbisSource;
  VorbisCallbacks.Seek := nil;
  VorbisCallbacks.Tell := nil;
  VorbisCallbacks.Close := nil;
end;

end.
