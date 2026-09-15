{$EXCESSPRECISION OFF}
unit VFW;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Types;
type
  IAVIFile = interface;
  IAVIStream = interface;
  TAVIStreamInfoA = packed record
    StreamType: Cardinal;
    Handler: Cardinal;
    Flags: Cardinal;
    Caps: Cardinal;
    Priority: Word;
    Language: Word;
    Scale: Cardinal;
    Rate: Cardinal;
    Start: Cardinal;
    Length: Cardinal;
    InitialFrames: Cardinal;
    SuggestedBufferSize: Cardinal;
    Quality: Cardinal;
    SampleSize: Cardinal;
    Frame: TRect;
    EditCount: Cardinal;
    FormatChangeCount: Cardinal;
    Name: array[0..63] of AnsiChar;
  end;
  IAVIFile = interface(IInterface)
  end;
  IAVIStream = interface(IInterface)
  end;
procedure AVIFileInit; stdcall;
procedure AVIFileExit; stdcall;
function AVIFileOpenA(
    var FileHandle: IAVIFile;
    FileName: PAnsiChar;
    Mode: Cardinal;
    Handler: Pointer
): Integer; stdcall;
function AVIFileGetStream(
    const FileHandle: IAVIFile;
    var Stream: IAVIStream;
    StreamType: Cardinal;
    Index: Integer
): Integer; stdcall;
function AVIStreamInfoA(
    const Stream: IAVIStream;
    var Info: TAVIStreamInfoA;
    Size: Integer
): Integer; stdcall;
function AVIStreamReadFormat(
    const Stream: IAVIStream;
    Position: Integer;
    Format: Pointer;
    var FormatSize: Integer
): Integer; stdcall;
function AVIStreamRead(
    const Stream: IAVIStream;
    Start: Integer;
    Samples: Integer;
    Buffer: Pointer;
    BufferSize: Integer;
    BytesRead: PCardinal;
    SamplesRead: PCardinal
): Integer; stdcall;
function AVIStreamLength(const Stream: IAVIStream): Integer; stdcall;
implementation
uses
  Math,
  RangersSupport,
  SysUtils,
  Windows;
procedure AVIFileInit; stdcall;
begin
end;
procedure AVIFileExit; stdcall;
begin
end;
function AVIFileOpenA(
    var FileHandle: IAVIFile;
    FileName: PAnsiChar;
    Mode: Cardinal;
    Handler: Pointer
): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
function AVIFileGetStream(
    const FileHandle: IAVIFile;
    var Stream: IAVIStream;
    StreamType: Cardinal;
    Index: Integer
): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
function AVIStreamInfoA(
    const Stream: IAVIStream;
    var Info: TAVIStreamInfoA;
    Size: Integer
): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
function AVIStreamReadFormat(
    const Stream: IAVIStream;
    Position: Integer;
    Format: Pointer;
    var FormatSize: Integer
): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
function AVIStreamRead(
    const Stream: IAVIStream;
    Start: Integer;
    Samples: Integer;
    Buffer: Pointer;
    BufferSize: Integer;
    BytesRead: PCardinal;
    SamplesRead: PCardinal
): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
function AVIStreamLength(const Stream: IAVIStream): Integer; stdcall;
begin
  raise Exception.Create('Win32 multimedia API is unavailable in the native host')
end;
end.
