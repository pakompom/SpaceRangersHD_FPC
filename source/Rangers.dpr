program Rangers;
{$MODE delphi}
{$EXCESSPRECISION OFF}
uses
  cthreads,
  cwstring,
  SysUtils,
  Math,
  GameBootstrap;
begin
  // AppKit window creation requires nontrapping IEEE arithmetic.
  SetExceptionMask(
      [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]
  );
  DefaultSystemCodePage := CP_UTF8;
  RunRangers;
end.
