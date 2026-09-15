{$EXCESSPRECISION OFF}
unit DirectXRenderException;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SysUtils;
type
  EDirectXRender = class;
  EDirectXRender = class(Exception)
    ErrorCode: Integer;
    constructor Create(Message: AnsiString);
    constructor CreateCode(Message: AnsiString; Code: Integer);
  end;
implementation
uses
  Math,
  GR_Main;

constructor EDirectXRender.Create(Message: AnsiString);
begin
  inherited Create(Message);
end;

constructor EDirectXRender.CreateCode(Message: AnsiString; Code: Integer);
begin
  inherited Create(Message + ' = ' + Direct3DErrorText(Code));
  ErrorCode := Code;
end;

end.
