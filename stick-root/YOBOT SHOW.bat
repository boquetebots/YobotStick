@echo off
REM ===========================================================================
REM  YOBOT SHOW.bat  -  runs the offline cue show
REM
REM  A real batch file, not a Windows shortcut. A .lnk remembers the drive
REM  letter it was made on; this finds its own folder instead, so it works
REM  whatever letter Windows gives the stick - E:, D:, F:, anything.
REM ===========================================================================

if not exist "%~dp0OhbotPi2\Windows\yobot-show.bat" goto MISSING
cd /d "%~dp0OhbotPi2\Windows"
call "yobot-show.bat"
exit /b

:MISSING
echo.
echo   Cannot find  OhbotPi2\Windows\yobot-show.bat
echo.
echo   This file has to sit in the YobotStick folder itself, next to the
echo   OhbotPi2 and Chess folders. If you copied it somewhere on its own,
echo   put it back beside them.
echo.
pause
exit /b
