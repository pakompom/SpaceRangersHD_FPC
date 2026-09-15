unit ShellAPI;
{$MODE delphi}
interface
uses
  Windows;
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
implementation
function SDL_OpenURL(URL: PAnsiChar): Integer; cdecl; external 'SDL2';
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
begin
  if SDL_OpenURL(FileName) = 0 then
    Result := 33
  else
    Result := 2;
end;
end.
