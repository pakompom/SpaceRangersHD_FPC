{$EXCESSPRECISION OFF}
unit EC_CacheSound;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  EC_Cache;
type
  TCSoundControlEC = class;
  TCSoundEC = class;
  TWaveFormatEx = packed record
    FormatTag: Word;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    AverageBytesPerSecond: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    ExtraSize: Word;
  end;
  TWaveFileHeader = packed record
    Gap0: array[0..21] of Byte;
    Channels: Word;
    SamplesPerSecond: Cardinal;
    Gap1C: array[0..3] of Byte;
    BlockAlign: Word;
    BitsPerSample: Word;
    DataId: Cardinal;
    DataSize: Cardinal;
  end;
  TCSoundControlEC = class(TCacheControlEC)
    procedure QueueLoadIfMissing(PendingLoads: TList); override;
    function CreateData: TCacheDataEC; override;
    function AcquireData: TCacheDataEC; override;
  end;
  TCSoundEC = class(TCacheDataEC)
    Format: TWaveFormatEx;
    Gap32: array[0..1] of Byte;
    SampleData: Pointer;
    SampleDataSize: Cardinal;
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override;
    constructor Create;
    destructor Destroy; override;
  end;
function AcquireCachedSound(Control: TCacheControlEC): TCSoundEC;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  EC_Mem,
  GR_Main,
  MMSystem;
const
  WaveDataChunkId = $61746164; // little-endian 'data'
  WaveChunkHeaderSize = 2 * SizeOf(Cardinal);

procedure TCSoundControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCSoundControlEC;
begin
  if RetainCount > 0 then
    Exit;
  if BoundData <> nil then
    Exit;
  if HasEmptyCacheKey then
    Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCSoundEC) = nil then
  begin
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;

function TCSoundControlEC.CreateData: TCacheDataEC;
begin
  Result := TCSoundEC.Create;
end;

function AcquireCachedSound(Control: TCacheControlEC): TCSoundEC;
begin
  Result := Control.AcquireDataFromConfig(TCSoundEC) as TCSoundEC;
end;

function TCSoundControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedSound(Self);
end;

constructor TCSoundEC.Create;
begin
  inherited Create;
end;

destructor TCSoundEC.Destroy;
begin
  if SampleData <> nil then
  begin
    FreeEC(SampleData);
    SampleData := nil;
  end;
  inherited Destroy;
end;

procedure TCSoundEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Offset: Integer;
  Header: TWaveFileHeader;
begin
  SourceBuffer.ReadBytes(@Header, SizeOf(Header));
  if Header.DataId <> WaveDataChunkId then
  begin
    Offset := 0;
    while SourceBuffer.DataSize - WaveChunkHeaderSize > Offset do
    begin
      if SourceBuffer.GetUInt32At(Offset) = WaveDataChunkId then
        Break;
      Inc(Offset);
    end;
    if SourceBuffer.DataSize - WaveChunkHeaderSize <= Offset then
      RaiseWideMessage('WAVE format');
    Header.DataId := WaveDataChunkId;
    Header.DataSize := SourceBuffer.GetUInt32At(Offset + SizeOf(Header.DataId));
    SourceBuffer.SetPosition(Offset + WaveChunkHeaderSize);
  end;
  Format.FormatTag := WAVE_FORMAT_PCM;
  Format.Channels := Header.Channels;
  Format.SamplesPerSecond := Header.SamplesPerSecond;
  Format.BitsPerSample := Header.BitsPerSample;
  Format.BlockAlign := Header.BlockAlign;
  Format.AverageBytesPerSecond := Format.BlockAlign * Format.SamplesPerSecond;
  Format.ExtraSize := 0;
  SampleDataSize := Header.DataSize;
  if SampleData <> nil then
  begin
    FreeEC(SampleData);
    SampleData := nil;
  end;
  SampleData := AllocEC(SampleDataSize);
  SourceBuffer.ReadBytes(SampleData, SampleDataSize);
end;

procedure LinkRecoveredTypes;
begin
  TCSoundEC.ClassName;
end;
end.
