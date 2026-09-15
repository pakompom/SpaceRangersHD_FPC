{$EXCESSPRECISION OFF}
unit GameApplication;

{$R-}
{$Q-}
{$B-}
{$A8}

interface

uses
  SysUtils;

type

  TAD = class;
  TAD = class(TObject)
    procedure ApplicationActivated(Sender: TObject);
    procedure ApplicationDeactivated(Sender: TObject);
  end;

procedure HandleApplicationActivated;

procedure HandleApplicationDeactivated;

procedure PurgeCacheDirectoryFiles;

function CollectInstallLanguageCodes: WideString;

procedure LinkRecoveredTypes;

implementation

uses
  Math,
  RangersSupport,
  Windows,
  MMSystem,
  GR_Main,
  GR_Sound,
  GlobalsV,
  Globals,
  GI_MessageLoop,
  aSaveLoad,
  aGalaxy,
  aPlayer,
  ThreadCalc;

{ @routine $873540 HandleApplicationActivated }
procedure HandleApplicationActivated;
var
  Buffer: TSoundBuffer;
begin
  RuntimeActive := True;
  if SoundManager <> nil then
  begin
    Buffer := SoundManager.FirstBuffer;
    while Buffer <> nil do
    begin
      if Buffer.Streaming then
        Buffer.SetVolume(MusicVolume * MusicVolumeScale)
      else
        Buffer.SetVolume(SoundVolume);
      Buffer := Buffer.Next;
    end;
  end;
  if RegisteredScreens[Ord(CurrentScreenId)] <> nil then
  begin
    FullFrameRedrawRequested := True;
    (TObject(RegisteredScreens[Ord(CurrentScreenId)]) as TMessageLoopGI).InvalidateViewport;
  end;
  if MemorySnapshotActive then
    RestoreGameFromMemorySnapshot;
end;
{ @end $873540 }

{ @routine $873600 TAD_ApplicationActivated }
procedure TAD.ApplicationActivated(Sender: TObject);
begin
  HandleApplicationActivated;
end;
{ @end $873600 }

{ @routine $873618 HandleApplicationDeactivated }
// CHANGE: CLEANUP - Drop the unreachable deactivation snapshot path.
procedure HandleApplicationDeactivated;
begin
  if WindowedModeRequested then
    Exit;
  RuntimeActive := False;
end;
{ @end $873618 }

{ @routine $8737B0 TAD_ApplicationDeactivated }
procedure TAD.ApplicationDeactivated(Sender: TObject);
begin
  HandleApplicationDeactivated;
end;
{ @end $8737B0 }

{ @routine $87382C PurgeCacheDirectoryFiles }
procedure PurgeCacheDirectoryFiles;
var
  FileName, OldDirectory: AnsiString;
  Search: TSearchRec;
begin
  OldDirectory := GetCurrentDir;
  SetCurrentDir(AnsiString(GetGameUserDirectory + 'Cache\'));
  if SysUtils.FindFirst('*.*', faAnyFile, Search) = 0 then
  begin
    repeat
      FileName := Search.Name;
      if (FileName <> '.') and (FileName <> '..') then
        SysUtils.DeleteFile(AnsiString(GetGameUserDirectory + 'Cache\' + WideString(FileName)));
    until SysUtils.FindNext(Search) <> 0;
    SysUtils.FindClose(Search);
  end;
  SetCurrentDir(OldDirectory);
end;
{ @end $87382C }

{ @routine $873A3C CollectInstallLanguageCodes }
function CollectInstallLanguageCodes: WideString;
var
  FileName, LanguageCode: WideString;
  LowerCode: AnsiString;
  NameLength: Integer;
  Search: TSearchRec;
begin
  Result := '';
  if SysUtils.FindFirst('*', faAnyFile, Search) = 0 then
  begin
    repeat
      FileName := Search.Name;
      // CHANGE: PORTABILITY - Match installation language files on case-sensitive filesystems.
      if (Pos('INSTALL_', UpperCase(Search.Name)) <> 1)
          or (UpperCase(ExtractFileExt(Search.Name)) <> '.TXT') then
        Continue;
      NameLength := Length(FileName);
      LanguageCode := Copy(FileName, 9, NameLength - 12);
      LowerCode := AnsiLowerCase(AnsiString(LanguageCode));
      if Result = '' then
        Result := WideString(LowerCode)
      else
        Result := Result + ',' + WideString(LowerCode);
    until SysUtils.FindNext(Search) <> 0;
    SysUtils.FindClose(Search);
  end;
end;
{ @end $873A3C }

procedure LinkRecoveredTypes;
begin
  TMessageLoopGI.ClassName;
end;

end.
