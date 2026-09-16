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
{$IF DEFINED(ANDROID) OR DEFINED(MSWINDOWS)}
function SDL_OpenURL(URL: PAnsiChar): Integer; cdecl; external 'SDL2';
{$ENDIF}
{$IFDEF ANDROID}
function sr_android_open_document(
    Path: PWideChar;
    Length: Integer
): Integer; cdecl; external 'gamenative';
{$ENDIF}
function IsAbsoluteNativePath(const Path: AnsiString): Boolean;
begin
{$IFDEF MSWINDOWS}
  // CHANGE: PORTABILITY - Windows roots are drive letters and UNC prefixes.
  Result := ((Length(Path) >= 3) and (Path[2] = ':') and (Path[3] in ['/', '\']))
      or ((Length(Path) >= 2) and (Path[1] in ['/', '\']) and (Path[2] in ['/', '\']));
{$ELSE}
  Result := (Path <> '') and (Path[1] = '/');
{$ENDIF}
end;
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
    if not IsAbsoluteNativePath(Target) and (Directory <> nil) and (Directory^ <> #0) then
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
  {$IFDEF MSWINDOWS}
  // CHANGE: PORTABILITY - Windows has no /usr/bin/open; SDL_OpenURL passes both
  // resolved file paths and URLs to ShellExecuteW.
  if SDL_OpenURL(PAnsiChar(Target)) = 0 then
  {$ELSE}
  if ExecuteProcess('/usr/bin/open', [Target]) = 0 then
  {$ENDIF}
    Result := 33
  else
    Result := 2;
{$ENDIF}
end;
end.
