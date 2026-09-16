unit ZLib;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
function OKGF_ZLib_Compress(Dest, Source: Pointer; SourceSize, Mode: Integer): Integer; stdcall;
function OKGF_ZLib_UnCompress(
    Dest: Pointer;
    DestCapacity: Integer;
    Source: Pointer;
    SourceSize: Integer
): Integer; stdcall;
function OKGF_ZLib_UnCompress2(
    Dest: Pointer;
    DestCapacity: Integer;
    Source: Pointer;
    SourceSize: Integer
): Integer; stdcall;
implementation
uses
  SysUtils;

// CHANGE: PORTABILITY - zlib's uLong is C long: 32-bit on Windows (LLP64), in zlib1.dll.
type
  ZULong = {$IFDEF MSWINDOWS}Cardinal{$ELSE}QWord{$ENDIF};
const
  ZLibName = {$IFDEF MSWINDOWS}'zlib1'{$ELSE}'z'{$ENDIF};

function uncompress(
    Dest: Pointer;
    var DestSize: ZULong;
    Source: Pointer;
    SourceSize: ZULong
): Integer; cdecl; external ZLibName;
function compress2(
    Dest: Pointer;
    var DestSize: ZULong;
    Source: Pointer;
    SourceSize: ZULong;
    Level: Integer
): Integer; cdecl; external ZLibName;
function compressBound(Size: ZULong): ZULong; cdecl; external ZLibName;

function OKGF_ZLib_Compress(Dest, Source: Pointer; SourceSize, Mode: Integer): Integer; stdcall;

var
  N: ZULong;
  Temp: Pointer;
  Level: Integer;

begin
  Result := 0;
  if SourceSize < 0 then
    Exit;
  N := compressBound(SourceSize);
  GetMem(Temp, N);
  try
    Level := 6;
    if Mode <> 0 then
      Level := 1;
    if compress2(Temp, N, Source, SourceSize, Level) <> 0 then
      Exit;

    if N + 8 >= QWord(SourceSize) then
      Exit;

    Result := N + 8;
    if Dest = nil then
      Exit;
    PCardinal(Dest)^ := $31304C5A;
    PCardinal(PByte(Dest) + 4)^ := SourceSize;
    Move(Temp^, (PByte(Dest) + 8)^, N);
  finally
    FreeMem(Temp)
  end;
end;
function OKGF_ZLib_UnCompress(
    Dest: Pointer;
    DestCapacity: Integer;
    Source: Pointer;
    SourceSize: Integer
): Integer; stdcall;

var
  N: ZULong;
  Expected: Cardinal;
  Magic: Cardinal;

begin
  Result := 0;
  if SourceSize < 8 then
    Exit;
  Move(Source^, Magic, 4);
  if (Magic <> $31304C5A) and (Magic <> $32304C5A) then
    Exit;
  Move((PByte(Source) + 4)^, Expected, 4);
  if Expected > 512 * 1024 * 1024 then
    raise Exception.Create('ZL payload is too large');
  if Dest = nil then
    Exit(Expected);
  if DestCapacity < Integer(Expected) then
    Exit;
  N := DestCapacity;
  if (uncompress(Dest, N, PByte(Source) + 8, SourceSize - 8) = 0) and (N = Expected) then
    Result := N;
end;
function OKGF_ZLib_UnCompress2(
    Dest: Pointer;
    DestCapacity: Integer;
    Source: Pointer;
    SourceSize: Integer
): Integer; stdcall;
begin
  Result := OKGF_ZLib_UnCompress(Dest, DestCapacity, Source, SourceSize)
end;
end.
