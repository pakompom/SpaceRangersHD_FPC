unit Forms;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
uses
  Classes;
type
  TApplication = class
    Handle: PtrUInt;
    Active: Boolean;
    OnActivate, OnDeactivate: TNotifyEvent;
    procedure Initialize;
    procedure ProcessMessages;
  end;
var
  Application: TApplication;
implementation
procedure TApplication.Initialize;
begin
  Active := True
end;
procedure TApplication.ProcessMessages;
begin
end;
initialization
  Application := TApplication.Create;
finalization
  Application.Free;
end.
