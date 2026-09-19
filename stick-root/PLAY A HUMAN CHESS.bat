@echo off
REM ===========================================================================
REM  PLAY A HUMAN.bat  -  play chess against Yobot
REM
REM  A real batch file, not a Windows shortcut. A .lnk remembers the drive
REM  letter it was made on; this finds its own folder instead, so it works
REM  whatever letter Windows gives the stick - E:, D:, F:, anything.
REM ===========================================================================

if not exist "%~dp0Chess\Play a Human.bat" goto MISSING
cd /d "%~dp0Chess"
call "Play a Human.bat"
exit /b

:MISSING
echo.
echo   Cannot find  Chess\Play a Human.bat
echo.
echo   This file has to sit in the YobotStick folder itself, next to the
echo   OhbotPi2 and Chess folders. If you copied it somewhere on its own,
echo   put it back beside them.
echo.
pause
exit /b
