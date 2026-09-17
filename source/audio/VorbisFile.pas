unit VorbisFile;

{$I GameOptions.inc}

interface

uses
  SyncObjs,
  DirectSound,
  EC_FileStream,
  CTypes,
  Vorbis;

type
  PCriticalSection = ^TCriticalSection;
  TOggWorker = class(TObject)
    // The C record contains pointers and C longs. Its size is architecture-dependent;
    // the original 720-byte Win32 byte array is too small on 64-bit Unix.
    VorbisState: OggVorbis_File;
    Lock: PCriticalSection;
    Bitstream: Integer;
    Opened: Boolean;
    Source: TFileStreamEC;
    ReadFailure: string;
    constructor Create(SharedLock: PCriticalSection);
    destructor Destroy; override;
    procedure CloseStream;
  end;

const
  VorbisOutputChannels = 2;
  VorbisOutputSampleRate = 44100;
  VorbisOutputSampleBytes = SizeOf(SmallInt);
  VorbisOutputBlockAlign = VorbisOutputChannels * VorbisOutputSampleBytes;
  VorbisOutputBytesPerSecond = VorbisOutputSampleRate * VorbisOutputBlockAlign;

function ReadVorbisSource(Buffer: Pointer; Size, Count: csize_t; Source: Pointer): csize_t; cdecl;
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

implementation

uses
  SysUtils,
  Math;

{$IFDEF MSWINDOWS}
// The game ships libvorbisfile.dll — the upstream library name, and the one the
// engine itself loads. FPC's oggvorbis package binds 'vorbisfile.dll' instead,
// so the four entry points used here are declared against the game's library.
const
  VorbisFileLibrary = 'libvorbisfile.dll';

function VorbisClear(var Vf: OggVorbis_File): cint; cdecl;
  external VorbisFileLibrary name 'ov_clear';
function VorbisInfo(var Vf: OggVorbis_File; Link: cint): pvorbis_info; cdecl;
  external VorbisFileLibrary name 'ov_info';
function VorbisOpenCallbacks(
    Datasource: Pointer;
    var Vf: OggVorbis_File;
    Initial: Pointer;
    InitialBytes: clong;
    Callbacks: ov_callbacks
): cint; cdecl; external VorbisFileLibrary name 'ov_open_callbacks';
function VorbisRead(
    var Vf: OggVorbis_File;
    Buffer: Pointer;
    Length: cint;
    BigEndian: cbool;
    WordSize: cint;
    Signed: cbool;
    Bitstream: pcint
): clong; cdecl; external VorbisFileLibrary name 'ov_read';
{$ELSE}
// Other targets link libvorbisfile through the package's own declarations.
function VorbisClear(var Vf: OggVorbis_File): cint; cdecl;
begin
  Result := ov_clear(Vf);
end;

function VorbisInfo(var Vf: OggVorbis_File; Link: cint): pvorbis_info; cdecl;
begin
  Result := ov_info(Vf, Link);
end;

function VorbisOpenCallbacks(
    Datasource: Pointer;
    var Vf: OggVorbis_File;
    Initial: Pointer;
    InitialBytes: clong;
    Callbacks: ov_callbacks
): cint; cdecl;
begin
  Result := ov_open_callbacks(Datasource, Vf, Initial, InitialBytes, Callbacks);
end;

function VorbisRead(
    var Vf: OggVorbis_File;
    Buffer: Pointer;
    Length: cint;
    BigEndian: cbool;
    WordSize: cint;
    Signed: cbool;
    Bitstream: pcint
): clong; cdecl;
begin
  Result := ov_read(Vf, Buffer, Length, BigEndian, WordSize, Signed, Bitstream);
end;
{$ENDIF}

function ReadVorbisSource(Buffer: Pointer; Size, Count: csize_t; Source: Pointer): csize_t; cdecl;
begin
  Result := 0;
  if (Size = 0) or (Count = 0) then
    Exit;
  // fread-style callbacks return complete items, not bytes. Bound the request
  // to the game's signed stream length before narrowing native size_t values.
  Count := Min(Count, csize_t(High(Integer)) div Size);
  try
    Result := TOggWorker(Source).Source.Read(Buffer, Size * Count) div Size;
  except
    // Save the failure and raise after libvorbis returns to Pascal. Unwinding
    // through its C callback would skip the decoder's cleanup.
    on E: Exception do
      TOggWorker(Source).ReadFailure := E.ClassName + ': ' + E.Message;
  end;
end;

constructor TOggWorker.Create(SharedLock: PCriticalSection);
begin
  inherited Create;
  Lock := SharedLock;
end;

destructor TOggWorker.Destroy;
begin
  CloseStream;
  inherited Destroy;
end;

procedure TOggWorker.CloseStream;
begin
  if Lock = nil then
    Exit;
  Lock^.Enter;
  try
    if Opened then
      VorbisClear(VorbisState);
    Opened := False;
    Source := nil;
  finally
    Lock^.Leave;
  end;
end;

function OpenVorbisStream(
    Decoder: TOggWorker;
    var Format: TSoundWaveFormat;
    var Stream: TFileStreamEC
): Integer; stdcall;
var
  Callbacks: ov_callbacks;
  Info: pvorbis_info;
begin
  Decoder.CloseStream;
  Callbacks := Default(ov_callbacks);
  Callbacks.Read := ReadVorbisSource;
  Decoder.Lock^.Enter;
  try
    Decoder.Source := Stream;
    Decoder.ReadFailure := '';
    Result := VorbisOpenCallbacks(Decoder, Decoder.VorbisState, nil, 0, Callbacks);
    Decoder.Opened := Result = 0;
    if Decoder.ReadFailure <> '' then
      raise Exception.Create(Decoder.ReadFailure);
    if Result <> 0 then
      raise Exception.Create('Error open audiofile: ' + IntToStr(Result));
    Decoder.Opened := True;
    Decoder.Bitstream := 0;
    Info := VorbisInfo(Decoder.VorbisState, -1);
    if (Info = nil) or not (Info.channels in [1, 2]) or (Info.rate <= 0) then
      raise Exception.Create('Unsupported Vorbis audio format');
    Format := Default(TSoundWaveFormat);
    Format.FormatTag := 1;
    Format.Channels := Info.channels;
    Format.BitsPerSample := 16;
    Format.SamplesPerSecond := Info.rate;
    Format.BlockAlign := Format.Channels * SizeOf(SmallInt);
    Format.AverageBytesPerSecond := Format.SamplesPerSecond * Format.BlockAlign;
    Result := 1;
  finally
    Decoder.Lock^.Leave;
  end;
end;

function ReadVorbisSamples(
    Decoder: TOggWorker;
    Buffer: Pointer;
    var ByteCount: Integer
): Integer; stdcall;
var
  Count: clong;
  Total, Remaining: Integer;
begin
  Total := 0;
  Remaining := ByteCount;
  Decoder.Lock^.Enter;
  try
    while Remaining > 0 do
    begin
      // Decode directly into the bounded destination. The original passed the
      // full remaining length for a fixed 4096-byte scratch buffer.
      Count :=
          VorbisRead(
              Decoder.VorbisState,
              PByte(Buffer) + Total,
              Remaining,
              False,
              SizeOf(SmallInt),
              True,
              @Decoder.Bitstream
          );
      if Decoder.ReadFailure <> '' then
        raise Exception.Create(Decoder.ReadFailure);
      if Count < 0 then
        raise Exception.Create('Vorbis decode error: ' + IntToStr(Count));
      if Count = 0 then
        Break;
      Inc(Total, Count);
      Dec(Remaining, Count);
    end;
  finally
    Decoder.Lock^.Leave;
  end;
  ByteCount := Total;
  Result := Total;
end;

end.
