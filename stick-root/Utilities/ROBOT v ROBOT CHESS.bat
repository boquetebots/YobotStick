@echo off
REM ===========================================================================
REM  ROBOT v ROBOT CHESS.bat  -  two robots play each other
REM
REM  Needs the chess engine. Run GET THE CHESS ENGINE.bat first, once, with
REM  the internet connected. This is the one audiences like.
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
if exist "%ROOT%\Chess\Play Chess.bat" goto FOUND
for %%I in ("%HERE%\..") do set "ROOT=%%~fI"
if exist "%ROOT%\Chess\Play Chess.bat" goto FOUND
set "ROOT=%HERE%\YobotStick"
if exist "%ROOT%\Chess\Play Chess.bat" goto FOUND
goto MISSING

:FOUND
cd /d "%ROOT%\Chess"
call "Play Chess.bat"
endlocal
exit /b

:MISSING
echo.
echo   Cannot find  Chess\Play Chess.bat
echo.
echo   This file belongs in the Utilities folder on the Yobot drive, with
echo   the OhbotPi2, Chess and python folders one level above it.
echo.
pause
endlocal
exit /b 1
