@echo off
REM ===========================================================================
REM  STOP YOBOT.bat  -  stops everything Yobot, however it was started
REM ===========================================================================
REM  This file works in TWO places, on purpose:
REM
REM    E:\STOP YOBOT.bat                 <- the root of the drive
REM    E:\YobotStick\STOP YOBOT.bat      <- inside the project folder
REM
REM  It looks for OhbotPi2\Windows beside itself first, then one level down
REM  inside YobotStick. So you can keep a copy at the root of the drive where
REM  it is the obvious thing to click, and it still works if the folder is
REM  moved onto a hard disk later.
REM
REM  A real batch file, never a shortcut: a .lnk remembers the drive letter it
REM  was made on and this stick will not always be the same letter.
REM ===========================================================================

setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "WIN=%ROOT%\OhbotPi2\Windows"
if exist "%WIN%\yobot-stop.bat" goto FOUND

set "WIN=%ROOT%\YobotStick\OhbotPi2\Windows"
if exist "%WIN%\yobot-stop.bat" goto FOUND

echo.
echo   Cannot find  OhbotPi2\Windows\yobot-stop.bat
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
call "yobot-stop.bat"
endlocal
exit /b
