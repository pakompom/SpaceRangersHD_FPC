unit ShellAPI;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
uses
  Windows;
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
implementation
uses
  SysUtils,
  URIParser;
{$IFDEF ANDROID}
function SDL_OpenURL(URL: PAnsiChar): Integer; cdecl; external 'SDL2';
function sr_android_open_document(
    Path: PWideChar;
    Length: Integer
): Integer; cdecl; external 'gamenative';
{$ENDIF}
function ShellExecuteA(
    Window: Windows.THandle;
    Operation, FileName, Parameters, Directory: PAnsiChar;
    ShowCommand: Integer
): Windows.THandle;
var
  Target, LocalPath: AnsiString;
  IsFile: Boolean;
{$IFDEF ANDROID}
  WideTarget: WideString;
{$ENDIF}
begin
  Result := 2;
  Target := AnsiString(FileName);
  if Target = '' then
    Exit;
  IsFile := not IsAbsoluteURI(Target);
  if SameText(Copy(Target, 1, 5), 'file:') then
  begin
    IsFile := URIToFilename(Target, LocalPath);
    if IsFile then
      Target := LocalPath;
  end;
  if IsFile then
  begin
    // CHANGE: PORTABILITY - Mod/manual paths use Windows separators. Resolve
    // them from the game working directory, preserving URL query strings.
    Target := NativePath(Target);
    if (Target <> '') and (Target[1] <> '/') and (Directory <> nil) and (Directory^ <> #0) then
      Target := IncludeTrailingPathDelimiter(NativePath(AnsiString(Directory))) + Target;
    Target := ExpandFileName(Target);
  end;
{$IFDEF ANDROID}
  if IsFile then
  begin
    // External Android browsers cannot read our private extracted game files.
    WideTarget := UTF8Decode(Target);
    if sr_android_open_document(PWideChar(WideTarget), Length(WideTarget)) <> 0 then
      Result := 33;
  end
  else if SDL_OpenURL(PAnsiChar(Target)) = 0 then
    Result := 33;
{$ELSE}
  if ExecuteProcess('/usr/bin/open', [Target]) = 0 then
    Result := 33
  else
    Result := 2;
{$ENDIF}
end;
end.
