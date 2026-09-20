@echo off
REM ===========================================================================
REM  PLAY A HUMAN CHESS.bat  -  a person plays the robot
REM
REM  Needs the chess engine. Run GET THE CHESS ENGINE.bat first, once, with
REM  the internet connected. The board and the game need no accounts; only
REM  the robot speaking does.
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
if exist "%ROOT%\Chess\Play a Human.bat" goto FOUND
for %%I in ("%HERE%\..") do set "ROOT=%%~fI"
if exist "%ROOT%\Chess\Play a Human.bat" goto FOUND
set "ROOT=%HERE%\YobotStick"
if exist "%ROOT%\Chess\Play a Human.bat" goto FOUND
goto MISSING

:FOUND
cd /d "%ROOT%\Chess"
call "Play a Human.bat"
endlocal
exit /b

:MISSING
echo.
echo   Cannot find  Chess\Play a Human.bat
echo.
echo   This file belongs in the Utilities folder on the Yobot drive, with
echo   the OhbotPi2, Chess and python folders one level above it.
echo.
pause
endlocal
exit /b 1
