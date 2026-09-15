{$EXCESSPRECISION OFF}
unit GI_XviD;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_File,
  EC_Buf,
  EC_BlockPar,
  GI_MessageLoop,
  VFW;
type
  TxvidGI = class;
  TXvidFunction =
      function(Handle: Pointer; Option: Integer; Param1: Pointer; Param2: Pointer): Integer; cdecl;
  TXvidGlobalInit = packed record
    Version: Integer;
    CpuFlags: Cardinal;
    Debug: Integer;
  end;
  TXvidDecoderCreate = packed record
    Version: Integer;
    Width: Integer;
    Height: Integer;
    Handle: Pointer;
  end;
  TXvidImage = packed record
    ColorSpace: Integer;
    Planes: array[0..3] of Pointer;
    Strides: array[0..3] of Integer;
  end;
  TXvidDecoderFrame = packed record
    Version: Integer;
    General: Integer;
    Bitstream: Pointer;
    Length: Integer;
    Output: TXvidImage;
    Brightness: Integer;
  end;
  TXvidDecoderStats = packed record
    Version: Integer;
    FrameType: Integer;
    Data: array[0..23] of Byte;
  end;
  TxvidGI = class(TObjectGI)
    SourceFile: TFileEC;
    CompressedFrame: TBufEC;
    Gap128: array[0..7] of Byte;
    DecoderHandle: Pointer;
    DecodedFrameCount: Integer;
    TargetFrame: Integer;
    VideoWidth: Integer;
    VideoHeight: Integer;
    Gap144: array[0..3] of Byte;
    PlaybackFinished: TObjectNotifyEventGI;
    ColorSpace: Integer;
    FillViewport: Boolean;
    Gap155: array[0..2] of Byte;
    AviFile: IAVIFile;
    AviStream: IAVIStream;
    FrameCount: Integer;
    Gap164: array[0..3] of Byte;
    FramesPerSecond: Double;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    function ImageOpen(const FileName: WideString; FillViewport: Boolean): Boolean;
    procedure XvidClose;
    procedure ImageClose;
    procedure ReadVideoConfig(Block: TBlockParEC);
    function DecodeNextFrame: Boolean;
    function SetPlaybackTime(TimeMs: Double): Boolean;
    procedure SetFramePosition(Frame: Integer);
  end;
var
  XvidLibrary: Cardinal = 0;
  XvidGlobal: TXvidFunction = nil;
  XvidDecore: TXvidFunction = nil;
implementation
uses
  Math,
  Windows,
  SysUtils,
  Direct3D9,
  GR_DX,
  GR_Main,
  EC_Str,
  EC_Struct;

constructor TxvidGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;

destructor TxvidGI.Destroy;
begin
  ImageClose;
  inherited Destroy;
end;

procedure TxvidGI.Clear;
begin
  ImageClose;
  inherited Clear;
end;

function TxvidGI.ImageOpen(const FileName: WideString; FillViewport: Boolean): Boolean;
var
  ErrorCode, FormatSize, Status: Integer;
  GlobalInit: TXvidGlobalInit;
  DecoderCreate: TXvidDecoderCreate;
  Format: TBitmapInfoHeader;
  Info: TAVIStreamInfoA;
begin
  Result := True;
  Self.FillViewport := FillViewport;
  ImageClose;
  try
    if XvidLibrary = 0 then
    begin
      XvidLibrary := LoadLibrary('xvidcore.dll');
      if XvidLibrary = 0 then
        RaiseWideMessage('Error xvidcore.dll');
      XvidGlobal := GetProcAddress(XvidLibrary, 'xvid_global');
      if not Assigned(XvidGlobal) then
        RaiseWideMessage('Error xvid_global');
      XvidDecore := GetProcAddress(XvidLibrary, 'xvid_decore');
      if not Assigned(XvidDecore) then
        RaiseWideMessage('Error xvid_decore');
    end;
    FillChar(GlobalInit, SizeOf(GlobalInit), 0);
    GlobalInit.Version := $10100;
    GlobalInit.CpuFlags := 0;
    XvidGlobal(nil, 0, @GlobalInit, nil);
    SourceFile := TFileEC.Create;
    CompressedFrame := TBufEC.Create;
    CompressedFrame.SetSize($180000);
    AVIFileInit;
    Status := AVIFileOpenA(AviFile, PAnsiChar(AnsiString(FileName)), 0, nil);
    if Status <> 0 then
      RaiseWideMessage('Error AVIFileOpenA = ' + IntToStr(Status));
    Status := AVIFileGetStream(AviFile, AviStream, $73646976, 0);
    if Status <> 0 then
      RaiseWideMessage('Error AVIFileGetStream = ' + IntToStr(Status));
    AVIStreamInfoA(AviStream, Info, SizeOf(Info));
    FramesPerSecond := Info.Rate / Info.Scale;
    FormatSize := SizeOf(Format);
    Status := AVIStreamReadFormat(AviStream, 0, @Format, FormatSize);
    if Status <> 0 then
      RaiseWideMessage('Error AVIStreamReadFormat ret = ' + IntToStr(Status));
    FrameCount := AVIStreamLength(AviStream);
    if FrameCount < 0 then
      RaiseWideMessage('Error AVIStreamLength FAVILen = ' + IntToStr(FrameCount));
    FillChar(DecoderCreate, SizeOf(DecoderCreate), 0);
    DecoderCreate.Version := $10100;
    DecoderCreate.Width := Format.biWidth;
    DecoderCreate.Height := Format.biHeight;
    Status := XvidDecore(nil, 0, @DecoderCreate, nil);
    if Status <> 0 then
      RaiseWideMessage('Error xvid_decore_func = ' + IntToStr(Status));
    DecoderHandle := DecoderCreate.Handle;
    DecodedFrameCount := 0;
    ColorSpace := $40;
    VideoWidth := Format.biWidth;
    VideoHeight := Format.biHeight;
    if Direct3DDevice = nil then
      raise Exception.Create('TxvidGI.ImageOpen(..)::GR_D3DDevice = nil');
    ErrorCode :=
        Direct3DDevice.CreateTexture(
            VideoWidth,
            VideoHeight,
            1,
            0,
            D3DFMT_X8R8G8B8,
            D3DPOOL_MANAGED,
            OffscreenTexture,
            nil
        );
    if ErrorCode <> 0 then
      raise Exception.Create(Direct3DErrorText(ErrorCode));
    SetFramePosition(1);
    OffscreenFillViewport := Self.FillViewport;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      Result := False;
      ImageClose;
    end;
  end;
end;

procedure TxvidGI.XvidClose;
var
  Status: Integer;
begin
  if DecoderHandle <> nil then
  begin
    Status := XvidDecore(DecoderHandle, 1, nil, nil);
    DecoderHandle := nil;
    if Status <> 0 then
      AppendLogLineThreadSafe(
          'Error XvidClose: xvid_decore_func - XVID_DEC_DESTROY = ' + IntToStr(Status)
      );
  end;
  if AviStream <> nil then
    AviStream := nil;
  if AviFile <> nil then
    AviFile := nil;
  AVIFileExit;
end;

procedure TxvidGI.ImageClose;
begin
  XvidClose;
  if SourceFile <> nil then
  begin
    SourceFile.Free;
    SourceFile := nil;
  end;
  if CompressedFrame <> nil then
  begin
    CompressedFrame.Free;
    CompressedFrame := nil;
  end;
  if OffscreenTexture <> nil then
    OffscreenTexture := nil;
end;

procedure TxvidGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  ReadVideoConfig(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TxvidGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  ReadVideoConfig(Block);
end;

procedure TxvidGI.ReadVideoConfig(Block: TBlockParEC);
begin
end;

function TxvidGI.DecodeNextFrame: Boolean;
var
  BytesUsed, ErrorCode: Integer;
  BytesRead: Cardinal;
  Data: Pointer;
  LockedRect: TD3DLockedRect;
  Frame: TXvidDecoderFrame;
  Stats: TXvidDecoderStats;
begin
  if DecodedFrameCount >= FrameCount then
  begin
    Result := False;
    Exit;
  end;
  if AVIStreamRead(
          AviStream,
          DecodedFrameCount,
          1,
          CompressedFrame.Data,
          CompressedFrame.DataSize,
          @BytesRead,
          nil)
      <> 0 then
    RaiseWideMessage('AVI stream read');
  Data := CompressedFrame.Data;
  ErrorCode := OffscreenTexture.LockRect(0, LockedRect, nil, 0);
  if ErrorCode <> 0 then
    raise Exception.Create('GR_lpTexAVI.LockRect error');
  while BytesRead > 1 do
  begin
    FillChar(Stats, SizeOf(Stats), 0);
    Stats.Version := $10100;
    FillChar(Frame, SizeOf(Frame), 0);
    Frame.Version := $10100;
    Frame.General := 1;
    Frame.Bitstream := Data;
    Frame.Length := BytesRead;
    Frame.Output.ColorSpace := ColorSpace;
    Frame.Output.Planes[0] := LockedRect.Bits;
    Frame.Output.Strides[0] := LockedRect.Pitch;
    BytesUsed := XvidDecore(DecoderHandle, 2, @Frame, @Stats);
    if BytesUsed < 0 then
      RaiseWideMessage('AVI decode');
    Data := Pointer(PtrUInt(Data) + BytesUsed);
    Dec(BytesRead, BytesUsed);
  end;
  OffscreenTexture.UnlockRect(0);
  Inc(DecodedFrameCount);
  OffscreenFillViewport := FillViewport;
  OffscreenFrameUpdated := True;
  Result := DecodedFrameCount < FrameCount;
end;

function TxvidGI.SetPlaybackTime(TimeMs: Double): Boolean;
var
  Frame: Integer;
begin
  Result := False;
  Frame := Round(0.001 * TimeMs * FramesPerSecond);
  if Frame >= FrameCount then
  begin
    Frame := FrameCount - 1;
    Result := True;
  end;
  SetFramePosition(Frame);
end;

procedure TxvidGI.SetFramePosition(Frame: Integer);
begin
  if DecoderHandle <> nil then
  begin
    TargetFrame := Frame;
    while TargetFrame > DecodedFrameCount do
      if not DecodeNextFrame then
      begin
        XvidClose;
        if Assigned(PlaybackFinished) then
          PlaybackFinished(Self);
        Break;
      end;
  end;
end;

end.
