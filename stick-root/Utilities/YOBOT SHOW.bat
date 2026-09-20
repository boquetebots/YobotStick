@echo off
REM ===========================================================================
REM  YOBOT SHOW.bat  -  the pre-recorded show
REM
REM  Plays from recordings already on this drive. No internet, no accounts,
REM  voice and all. This is the one to rely on in a hall with poor wifi.
REM
REM  A real batch file, never a shortcut: a .lnk remembers the drive letter
REM  it was made on, and this stick will not always be the same letter.
REM ===========================================================================

setlocal
set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

REM  Find the top of the Yobot drive.
REM
REM  This file lives in Utilities\, one level down, so the usual answer is
REM  the folder above this one. It also works if somebody moves it back to
REM  the top of the drive, or into a YobotStick folder, because all three
REM  are tried in turn. Nothing here remembers a drive letter.
set "ROOT=%HERE%"
if exist "%ROOT%\OhbotPi2\Windows\yobot-show.bat" goto FOUND
for %%I in ("%HERE%\..") do set "ROOT=%%~fI"
if exist "%ROOT%\OhbotPi2\Windows\yobot-show.bat" goto FOUND
set "ROOT=%HERE%\YobotStick"
if exist "%ROOT%\OhbotPi2\Windows\yobot-show.bat" goto FOUND
goto MISSING

:FOUND
cd /d "%ROOT%\OhbotPi2\Windows"
call "yobot-show.bat"
endlocal
exit /b

:MISSING
echo.
echo   Cannot find  OhbotPi2\Windows\yobot-show.bat
echo.
echo   This file belongs in the Utilities folder on the Yobot drive, with
echo   the OhbotPi2, Chess and python folders one level above it. If it was
echo   copied somewhere on its own, put it back.
echo.
pause
endlocal
exit /b 1
