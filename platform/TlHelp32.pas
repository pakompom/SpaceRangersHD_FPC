unit TlHelp32;

{$MODE DELPHI}

// Minimal TOOLHELP32 declarations, enough to compile the Win32 module scan in
// GR_Main. FPC has no Delphi-compatible TlHelp32 unit: its TOOLHELP bindings live
// in the JEDI package, whose jwawinbase unit also declares TCriticalSection as
// the raw CRITICAL_SECTION record and shadows FPC's class of the same name.

interface

uses
  Windows;

const
  TH32CS_SNAPMODULE = $00000008;
  MAX_MODULE_NAME32 = 255;

type
  {$A8}
  tagMODULEENTRY32 = record
    dwSize: DWORD;
    th32ModuleID: DWORD;
    th32ProcessID: DWORD;
    GlblcntUsage: DWORD;
    ProccntUsage: DWORD;
    modBaseAddr: PByte;
    modBaseSize: DWORD;
    hModule: THandle;
    szModule: array [0 .. MAX_MODULE_NAME32] of AnsiChar;
    szExePath: array [0 .. MAX_PATH - 1] of AnsiChar;
  end;
  TModuleEntry32 = tagMODULEENTRY32;
  PModuleEntry32 = ^TModuleEntry32;

function CreateToolhelp32Snapshot(Flags, ProcessId: DWORD): THandle; stdcall;
  external 'kernel32.dll' name 'CreateToolhelp32Snapshot';
function Module32First(Snapshot: THandle; var Entry: TModuleEntry32): BOOL; stdcall;
  external 'kernel32.dll' name 'Module32First';
function Module32Next(Snapshot: THandle; var Entry: TModuleEntry32): BOOL; stdcall;
  external 'kernel32.dll' name 'Module32Next';

implementation

end.
