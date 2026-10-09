unit SimpleSteamApi;

{$I GameOptions.inc}

interface

uses
  WStringUtils;

type

  PointerToTAchievementData = ^TAchievementData;

  TAchievementData = record
    Name: PStartupWideString;
    Description: PStartupWideString;
    Achieved: Boolean;
    HasProgress: Boolean;
    Reserved0C: Integer;
    MaxValue: Integer;
    Value: Integer;
    IconPath: PStartupWideString;
    Date: Int64;
  end;

  PAchievementData = PointerToTAchievementData;

  TSteamAchievementData = procedure(Index: Integer; Data: PAchievementData); cdecl;

  TSteamUserId = function: Int64; cdecl;

  TSteamInit =
      function(var Language: WideString; var AvailableLanguages: WideString): Boolean; cdecl;

  TSteamCreateAchievements = procedure(Count: Integer); cdecl;

  TSteamInitAchievement =
      procedure(
          Index: Integer;
          const AchievementName: AnsiString;
          const StatName: AnsiString;
          MaxValue: Integer
      ); cdecl;

  TSteamLocal = function(AppId: Integer): Boolean; cdecl;

  TSteamRunCallbacks = procedure; cdecl;

  TSteamUnlockAchievement = function(Index: Integer): Boolean; cdecl;

  TSteamIncreaseStat = function(Index: Integer; Amount: Integer): Boolean; cdecl;

  TSteamFree = procedure; cdecl;

  TSteamAchievementsCount = function: Integer; cdecl;

var

  SteamInitialized: Boolean = False;

  SteamUserId: TSteamUserId;

  SteamInit: TSteamInit;

  SteamCreateAchievements: TSteamCreateAchievements;

  SteamInitAchievement: TSteamInitAchievement;

  SteamLocal: TSteamLocal;

  SteamRunCallbacks: TSteamRunCallbacks;

  SteamResetAchievements: Pointer;

  SteamUnlockAchievement: TSteamUnlockAchievement;

  SteamStat: Pointer;

  SteamIncreaseStat: TSteamIncreaseStat;

  SteamFree: TSteamFree;

  SteamAchievementsOverlay: Pointer;

  SteamAchievementsCount: TSteamAchievementsCount;

  SteamAchievementData: TSteamAchievementData;

  SteamStatus: Pointer;

procedure LoadSteamApi;

procedure UnloadSteamApi;

procedure InitializeSteamAchievements;

implementation

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  SysUtils,
  EC_BlockPar,
  Achievements;

{$IF Defined(MSWINDOWS) and Defined(CPU386)}
procedure LoadSteamApi;
var
  Module: HMODULE;
  Error: Integer;
begin
  Module := Windows.LoadLibrary('steam_ach.dll');
  if Module = 0 then
  begin
    Error := GetLastError;
    if Error = 126 then
      raise Exception.Create('cant load steam_ach.dll, missing some file')
    else if Error = 193 then
      raise Exception.Create('cant load steam_ach.dll, module versions mismatch')
    else
      raise Exception.Create('cant load steam_ach.dll, lasterror=' + IntToStr(Error));
  end;
  SteamUserId := GetProcAddress(Module, 'steamUserID');
  SteamInit := GetProcAddress(Module, 'steamInit');
  SteamCreateAchievements := GetProcAddress(Module, 'createAchievements');
  SteamInitAchievement := GetProcAddress(Module, 'initAchievement');
  SteamLocal := GetProcAddress(Module, 'steamLocal');
  SteamRunCallbacks := GetProcAddress(Module, 'steamCallBacks');
  SteamResetAchievements := GetProcAddress(Module, 'steamResetAchievements');
  SteamUnlockAchievement := GetProcAddress(Module, 'steamAchievement');
  SteamStat := GetProcAddress(Module, 'steamStat');
  SteamIncreaseStat := GetProcAddress(Module, 'steamStatIncrease');
  SteamFree := GetProcAddress(Module, 'steamFree');
  SteamAchievementsOverlay := GetProcAddress(Module, 'steamAchievementsOverlay');
  SteamAchievementsCount := GetProcAddress(Module, 'steamAchievementsCount');
  SteamAchievementData := GetProcAddress(Module, 'steamAchievementData');
  SteamStatus := GetProcAddress(Module, 'steamStatus');
end;

procedure UnloadSteamApi;
var
  Module: HMODULE;
begin
  Module := Windows.GetModuleHandle('steam_ach.dll');
  if Module <> 0 then
  begin
    SteamFree;
    FreeLibrary(Module);
  end;
end;

{$ELSE}
procedure LoadSteamApi;
begin
  // steam_ach.dll exposes the original game's Win32-only wrapper ABI.
  // Startup catches this and continues with local achievements.
  raise Exception.Create('Steam integration requires the original 32-bit Windows wrapper');
end;

procedure UnloadSteamApi;
begin
end;
{$ENDIF}

procedure InitializeSteamAchievements;
var
  Index, MaxValue, Number: Integer;
  Block: TBlockParEC;
  AchievementName, StatName: AnsiString;
begin
  SteamCreateAchievements(82);
  for Index := 0 to AchievementDefinitions.GetBlockCount - 1 do
  begin
    Block := AchievementDefinitions.GetBlockByIndex(Index);
    AchievementName := AnsiString(AchievementDefinitions.GetBlockNameByIndex(Index));
    Number := StrToInt(AnsiString(Block.GetParam('Num')));
    MaxValue := StrToInt(AnsiString(Block.GetParam('MaxValue')));
    if MaxValue > 0 then
      StatName := 'STAT_' + AchievementName
    else
      StatName := 'null';
    AchievementName := 'ACH_' + AchievementName;
    SteamInitAchievement(Number, AchievementName, StatName, MaxValue);
  end;
end;

end.
