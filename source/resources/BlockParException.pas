{$EXCESSPRECISION OFF}
unit BlockParException;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SysUtils;
type
  EBlockPar = class;
  EBlockPar = class(Exception)
    Reportable: Boolean;
    GapD: array[0..2] of Byte;
    constructor Create(Message: AnsiString; AReportable: Boolean);
    function IsReportable: Boolean;
  end;
implementation
uses
  Math;

constructor EBlockPar.Create(Message: AnsiString; AReportable: Boolean);
begin
  inherited Create(Message);
  Reportable := AReportable;
end;

function EBlockPar.IsReportable: Boolean;
begin
  Result := Reportable
end;

end.
