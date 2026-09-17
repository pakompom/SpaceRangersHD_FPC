@echo off
rem Build Space Rangers HD for 32-bit Windows with Free Pascal.
rem
rem Requires FPC 3.2.2 (in PATH, or point the FPC variable at fpc.exe). SDL2.dll
rem and the game's own okgf.dll / xvidcore.dll have to be placed next to the
rem produced Rangers.exe — see docs/build-win32.md.
rem
rem Output: .local\win32\Rangers.exe

setlocal
set ROOT=%~dp0..
set OUT=%ROOT%\.local\win32

if not defined FPC set FPC=fpc

if not exist "%OUT%\units" mkdir "%OUT%\units"

"%FPC%" -Mdelphi -FcUTF8 -vw ^
 -Fi"%ROOT%\source" ^
 -Fu"%ROOT%\platform" ^
 -Fu"%ROOT%\source" ^
 -Fu"%ROOT%\source\arcade" ^
 -Fu"%ROOT%\source\audio" ^
 -Fu"%ROOT%\source\core" ^
 -Fu"%ROOT%\source\game" ^
 -Fu"%ROOT%\source\graphics" ^
 -Fu"%ROOT%\source\platform" ^
 -Fu"%ROOT%\source\quests" ^
 -Fu"%ROOT%\source\resources" ^
 -Fu"%ROOT%\source\runtime" ^
 -Fu"%ROOT%\source\scene" ^
 -Fu"%ROOT%\source\screens" ^
 -Fu"%ROOT%\source\script" ^
 -Fu"%ROOT%\source\ui" ^
 -FU"%OUT%\units" -FE"%OUT%" ^
 "%ROOT%\source\Rangers.dpr"
set RESULT=%ERRORLEVEL%

if not "%RESULT%"=="0" (
  echo.
  echo Build failed with exit code %RESULT%.
  exit /b %RESULT%
)

echo.
echo Built %OUT%\Rangers.exe
