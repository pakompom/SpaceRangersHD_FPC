program Rangers;
{$MODE delphi}
{$EXCESSPRECISION OFF}
uses
  // CHANGE: PORTABILITY - Windows RTL has native threads and wide strings.
  {$IFDEF UNIX}
  cthreads,
  cwstring,
  {$ENDIF}
  SysUtils,
  Math,
  GameBootstrap;
begin
  // AppKit window creation requires nontrapping IEEE arithmetic.
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  DefaultSystemCodePage := CP_UTF8;
  {$IFDEF MSWINDOWS}
  // CHANGE: PORTABILITY - The game passes UTF-8 paths; Windows RTL file APIs default to
  // the ANSI code page, so Cyrillic save names came back from FindFirst unreadable.
  SetMultiByteFileSystemCodePage(CP_UTF8);
  SetMultiByteRTLFileSystemCodePage(CP_UTF8);
  {$ENDIF}
  RunRangers;
end.
