{$EXCESSPRECISION OFF}
unit BreakMessageGIException;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SysUtils;
type
  EBreakMessageGI = class;
  EBreakMessageGI = class(EAbort)
  end;
implementation
uses
  Math;
end.
