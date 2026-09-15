unit Dialogs;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
procedure ShowMessage(const Text: string);
implementation
uses
  Windows;
procedure ShowMessage(const Text: string);
begin
  MessageBoxA(0, PAnsiChar(Text), 'Space Rangers HD', MB_OK)
end;
end.
