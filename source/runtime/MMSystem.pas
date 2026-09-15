{$EXCESSPRECISION OFF}
unit MMSystem;

{$R-}
{$Q-}
{$B-}
{$A8}

interface

const
  WAVE_FORMAT_PCM = 1;

  TIME_PERIODIC = $0001;

  TIME_CALLBACK_EVENT_SET = $0010;

function timeBeginPeriod(Period: Cardinal): Cardinal; stdcall;

function timeEndPeriod(Period: Cardinal): Cardinal; stdcall;

function timeGetTime: Cardinal; stdcall;

function timeKillEvent(TimerId: Cardinal): Cardinal; stdcall;

function timeSetEvent(
    Delay: Cardinal;
    Resolution: Cardinal;
    Callback: Cardinal;
    User: Cardinal;
    Flags: Cardinal
): Cardinal; stdcall;

implementation

uses
  Math,
  RangersSupport,
  SysUtils,
  Windows;

function timeBeginPeriod(Period: Cardinal): Cardinal; stdcall;
begin
  Result := 0
end;
function timeEndPeriod(Period: Cardinal): Cardinal; stdcall;
begin
  Result := 0
end;
function timeGetTime: Cardinal; stdcall;
begin
  Result := Cardinal(GetTickCount64)
end;
function timeKillEvent(TimerId: Cardinal): Cardinal; stdcall;
begin
  Result := 0
end;
function timeSetEvent(Delay, Resolution, Callback, User, Flags: Cardinal): Cardinal; stdcall;
begin
  raise Exception.Create('Win32 multimedia timer callbacks are unavailable')
end;
end.
