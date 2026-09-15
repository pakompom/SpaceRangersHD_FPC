unit RTLFileSystem;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
function FileExistsBySearch(const FileName: AnsiString): Boolean;
function FileExists(const FileName: AnsiString): Boolean;
implementation
uses
  SysUtils,
  Windows;
function FileExistsBySearch(const FileName: AnsiString): Boolean;
begin
  Result := SysUtils.FileExists(NativePath(FileName))
end;
function FileExists(const FileName: AnsiString): Boolean;
begin
  Result := FileExistsBySearch(FileName)
end;
end.
