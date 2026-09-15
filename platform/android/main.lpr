library main;
{$MODE delphi}
// Use FPC Unicode tables; Android hides its private system ICU libraries.
uses
  cthreads,
  fpwidestring,
  cpall,
  SysUtils,
  Math,
  GameBootstrap;

function SDL_main(Count: LongInt; Arguments: PPAnsiChar): LongInt; cdecl;
begin
  argc := Count;
  argv := Arguments;
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  DefaultSystemCodePage := CP_UTF8;
  RunRangers;
  Result := System.ExitCode;
end;

exports
  SDL_main;
begin
end.
