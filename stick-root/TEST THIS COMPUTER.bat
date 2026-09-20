@echo off
REM ===========================================================================
REM  TEST THIS COMPUTER.bat  -  checks this computer can run Yobot. Run it first on a new machine
REM ===========================================================================
REM  This file lives at the top of the Yobot drive, next to READ ME FIRST.txt.
REM  It looks for OhbotPi2\Windows beside itself first, then inside a
REM  YobotStick folder, so it also works if the whole lot is moved onto a
REM  hard disk later. Nothing here remembers a drive letter.
REM
REM  The other buttons - the show and the chess - are in Utilities, and find
REM  their way from one level down.
REM
REM  A real batch file, never a shortcut: a .lnk remembers the drive letter it
REM  was made on and this stick will not always be the same letter.
REM ===========================================================================

setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "WIN=%ROOT%\OhbotPi2\Windows"
if exist "%WIN%\yobot-test.bat" goto FOUND

set "WIN=%ROOT%\YobotStick\OhbotPi2\Windows"
if exist "%WIN%\yobot-test.bat" goto FOUND

echo.
echo   Cannot find  OhbotPi2\Windows\yobot-test.bat
echo.
echo   This file belongs either at the root of the Yobot drive, or inside
echo   the YobotStick folder. It has to be able to see one of these:
echo.
echo       %ROOT%\OhbotPi2\Windows
echo       %ROOT%\YobotStick\OhbotPi2\Windows
echo.
pause
endlocal
exit /b 1

:FOUND
cd /d "%WIN%"
call "yobot-test.bat"
endlocal
exit /b
