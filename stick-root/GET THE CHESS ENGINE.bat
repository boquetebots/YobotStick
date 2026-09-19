@echo off
title Get the chess engine
REM ===========================================================================
REM  GET THE CHESS ENGINE.bat
REM ===========================================================================
REM
REM  Only needed if you want to play chess. Everything else on this stick
REM  works without it, and without the internet.
REM
REM  Stockfish is the program that actually decides the moves. It is not on
REM  the stick for two reasons: it is 109 MB, more than twice the size of
REM  everything else here put together, and it is licensed under the GPL,
REM  which puts conditions on anyone who redistributes it. Downloading it
REM  yourself, straight from the people who make it, avoids both.
REM
REM  You need to be online for this one run. Once. After that chess works
REM  with no internet at all, apart from the robot's voice.
REM
REM ===========================================================================
REM  WHY THIS ADDRESS AND NOT THE LATEST ONE  -  do not "helpfully" update it
REM ===========================================================================
REM
REM  Stockfish 19 came out on 5 September 2026. This deliberately fetches 18.
REM
REM  Version 19 tightened what it accepts as a legal board position. On input
REM  it dislikes it prints "CRITICAL ERROR" and shuts itself down on the spot,
REM  where 18 shrugged and carried on. Nothing in the chess code catches the
REM  engine dying, so under 19 one position it does not like ends the show in
REM  front of an audience with no way back. Until that is handled, 18.
REM
REM  There is a trap in the addresses, too. Version 19 ships ONE Windows file
REM  called ...universal.zip; version 18 ships several named after the chip
REM  and no universal one. So the tempting "releases/latest/download/
REM  ...universal.zip" can only ever give you 19 - the exact version being
REM  avoided - and it would do it silently.
REM
REM  The file fetched below is the PLAIN x86-64 build, with nothing after the
REM  x86-64 in its name. That is on purpose as well. The faster avx2 build
REM  needs instructions that older laptops do not have, and on one of those it
REM  does not fail politely - it crashes with an illegal instruction, which
REM  reads to the person holding the laptop as "this software is broken".
REM  Plain runs everywhere.
REM
REM ===========================================================================

setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "CHESS=%HERE%\Chess"
if not exist "%CHESS%\chess_server.py" set "CHESS=%HERE%\YobotStick\Chess"
if not exist "%CHESS%\chess_server.py" goto WRONGPLACE

set "URL=https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64.zip"
set "ZIP=%CHESS%\stockfish-download.zip"
set "EXE=%CHESS%\stockfish-windows-x86-64.exe"

echo.
echo   ======================================================================
echo     Getting the chess engine
echo   ======================================================================
echo.

if exist "%EXE%" (
    echo     You already have it:
    echo        %EXE%
    echo.
    echo     Nothing to do. You can close this window and play.
    echo.
    pause
    endlocal
    exit /b 0
)

where curl >nul 2>&1
if errorlevel 1 (
    echo   [X] curl is missing. It is part of Windows 10 and 11, so this is
    echo       an unusually old machine. Open the address below in a browser,
    echo       unzip it, and put stockfish-windows-x86-64.exe in the Chess
    echo       folder by hand:
    echo.
    echo       %URL%
    echo.
    pause
    endlocal
    exit /b 1
)

echo     Downloading about 40 MB. This can take a few minutes on slow wifi.
echo     Leave the window open.
echo.

curl -L -# -o "%ZIP%" "%URL%"
if errorlevel 1 goto DOWNLOADFAILED
if not exist "%ZIP%" goto DOWNLOADFAILED

echo.
echo     Unpacking...
tar -xf "%ZIP%" -C "%CHESS%"
if errorlevel 1 goto UNPACKFAILED

REM  The zip puts the .exe inside a folder of its own. Find it and bring it
REM  up beside the chess files, where the game looks for it.
for /r "%CHESS%" %%F in (stockfish-windows-x86-64.exe) do (
    if not "%%~dpF"=="%CHESS%\" copy /y "%%F" "%EXE%" >nul
)

if exist "%CHESS%\stockfish" rd /s /q "%CHESS%\stockfish"
del /q "%ZIP%" 2>nul

if not exist "%EXE%" goto UNPACKFAILED

echo.
echo   ======================================================================
echo     DONE
echo   ======================================================================
echo.
echo     The engine is in place. You can close this window.
echo.
echo     Now click  PLAY A HUMAN CHESS.bat  to play against the robot, or
echo     ROBOT v ROBOT CHESS.bat  to watch two of them play each other.
echo.
pause
endlocal
exit /b 0

:DOWNLOADFAILED
echo.
echo   [X] The download did not finish.
echo.
echo       Almost always this is the internet rather than anything here. Try
echo       again on a better connection. If it keeps failing, open this in a
echo       browser, unzip it, and put stockfish-windows-x86-64.exe straight
echo       into the Chess folder:
echo.
echo       %URL%
echo.
del /q "%ZIP%" 2>nul
pause
endlocal
exit /b 1

:UNPACKFAILED
echo.
echo   [X] It downloaded but would not unpack.
echo.
echo       Open %ZIP% by double-clicking it, find
echo       stockfish-windows-x86-64.exe inside, and drag it into the Chess
echo       folder. That is all this script was trying to do.
echo.
pause
endlocal
exit /b 1

:WRONGPLACE
echo.
echo   [X] Cannot find the Chess folder.
echo.
echo       This file belongs at the top level of the Yobot stick, beside the
echo       folders called Chess, OhbotPi2 and python. If you copied it
echo       somewhere on its own, put it back.
echo.
pause
endlocal
exit /b 1
