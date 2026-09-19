@echo off
title Build Yobot on a Stick
REM ===========================================================================
REM  build-stick.bat  -  makes the downloadable ZIP
REM ===========================================================================
REM
REM  Double-click this. It takes a few minutes and needs the internet.
REM
REM  When it finishes there is one file in  dist\  that anybody can download,
REM  unzip onto a blank USB stick, and run. No installing, no Python, no keys
REM  needed to try it.
REM
REM  WHY IT BUILDS FROM GIT AND NOT FROM THE STICK
REM  ---------------------------------------------
REM  It would be far easier to zip up E:\ and be done. Do not. The stick that
REM  has been carried around and plugged into other people's laptops has a
REM  .env file on it with live API keys. Building from a fresh git export is
REM  what makes it impossible for a key to get into a public download: the
REM  keys are not in git, so they cannot come out of git.
REM
REM  WHAT YOU NEED ON THIS PC
REM  ------------------------
REM     git          - already installed, this is how you push to GitHub
REM     curl, tar    - built into Windows 10 and 11, nothing to install
REM     internet     - for the two clones and the Python download
REM
REM  YOU DO NOT NEED A GITHUB TOKEN TO BUILD. Both repos are public, and this
REM  script only ever READS them. So an expired or missing token does not stop
REM  a build - it only stops a push. If a credentials window ever appears
REM  during a build, something is wrong; cancel it rather than feeding it.
REM
REM  Everything it writes goes in  build\  and  dist\  beside this file.
REM  Both are wiped at the start of every run and both are in .gitignore.
REM
REM ===========================================================================

setlocal

REM ---------------------------------------------------------------------------
REM  SETTINGS - the only part you would ever change
REM ---------------------------------------------------------------------------

set "VERSION=1.0"

REM  Your working copy of the robot project. The build does NOT take files from
REM  here - it only looks at it to warn you if it has commits GitHub has not
REM  seen, which would mean the ZIP ships older code than the PC you are on.
set "LOCAL_OHBOT=D:\Projects\OhbotPi2"

REM  Note the robot repo is OhbotPi, not OhbotPi2. The folder is called
REM  OhbotPi2 on both machines; the repo it came from never was.
set "OHBOT_URL=https://github.com/boquetebots/OhbotPi.git"
set "CHESS_URL=https://github.com/boquetebots/YobotChess.git"

set "PY_URL=https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
set "GETPIP_URL=https://bootstrap.pypa.io/get-pip.py"

REM ---------------------------------------------------------------------------

REM  Never sit waiting for a username and password. Everything here reads
REM  public repos, so a prompt can only mean something is misconfigured - and
REM  an unattended build that hangs on an invisible prompt looks like a crash.
REM  This makes git fail immediately and say so instead.
set "GIT_TERMINAL_PROMPT=0"

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"
set "WORK=%REPO%\build"
set "OUT=%REPO%\dist"
set "STICK=%WORK%\stick"
set "LOG=%REPO%\last build log.txt"
set "ZIPNAME=Yobot-on-a-Stick-Windows-v%VERSION%.zip"

REM  Start a fresh log. Everything printed on screen also lands here, because
REM  the one line that explains a failure is always the one that scrolled past
REM  or went with the window when it was closed.
echo Yobot stick build - %DATE% %TIME% > "%LOG%"

call :SAY ""
call :SAY "  ======================================================================"
call :SAY "    Building  Yobot on a Stick  v%VERSION%"
call :SAY "  ======================================================================"
call :SAY ""

REM ===========================================================================
REM  STEP 0  -  is everything here that we need
REM ===========================================================================

call :SAY "  [0/9] Checking this computer has what the build needs..."

where git >nul 2>&1
if errorlevel 1 (
    call :SAY "        [X] git is not installed, or not on the PATH."
    call :SAY "            Install Git for Windows, then run this again."
    goto FAIL
)
where curl >nul 2>&1
if errorlevel 1 (
    call :SAY "        [X] curl not found. It is part of Windows 10 and 11."
    goto FAIL
)
where tar >nul 2>&1
if errorlevel 1 (
    call :SAY "        [X] tar not found. It is part of Windows 10 and 11."
    goto FAIL
)
call :SAY "        ok - git, curl and tar are all here."
call :SAY ""

REM ===========================================================================
REM  STEP 1  -  does this PC have work GitHub has not seen
REM ===========================================================================
REM  The build clones from GitHub, so anything committed only on this PC would
REM  be silently left out of the download. Worse, it would look fine. So check.
REM ===========================================================================

call :SAY "  [1/9] Checking your local copy is level with GitHub..."

if not exist "%LOCAL_OHBOT%\.git" (
    call :SAY "        [!] No git copy at %LOCAL_OHBOT% - skipping this check."
    call :SAY "            The build will use whatever is on GitHub."
    goto SKIPSYNC
)

git -C "%LOCAL_OHBOT%" fetch origin --quiet >> "%LOG%" 2>&1
if errorlevel 1 call :SAY "        [!] Could not reach GitHub to compare. Carrying on."

set "LOCAL_SHA="
set "ORIGIN_SHA="
for /f %%i in ('git -C "%LOCAL_OHBOT%" rev-parse HEAD 2^>nul') do set "LOCAL_SHA=%%i"
for /f %%i in ('git -C "%LOCAL_OHBOT%" rev-parse origin/main 2^>nul') do set "ORIGIN_SHA=%%i"

set "DIRTY="
for /f "delims=" %%i in ('git -C "%LOCAL_OHBOT%" status --porcelain 2^>nul') do set "DIRTY=1"

if defined DIRTY (
    call :SAY ""
    call :SAY "        [!] STOP. %LOCAL_OHBOT% has changes that are not committed."
    call :SAY "            Those changes will NOT be in the download."
    call :SAY "            Commit and push them first, or run:  build-stick.bat force"
    call :SAY ""
    if /i not "%~1"=="force" goto FAIL
    call :SAY "        'force' given - carrying on anyway."
)

if not "%LOCAL_SHA%"=="%ORIGIN_SHA%" (
    call :SAY ""
    call :SAY "        [!] STOP. This PC and GitHub are not on the same commit."
    call :SAY "              this PC: %LOCAL_SHA%"
    call :SAY "              GitHub : %ORIGIN_SHA%"
    call :SAY "            The download is built from GitHub, so it would ship"
    call :SAY "            the GitHub one. Push first, or run: build-stick.bat force"
    call :SAY ""
    if /i not "%~1"=="force" goto FAIL
    call :SAY "        'force' given - carrying on anyway."
)

if not defined DIRTY if "%LOCAL_SHA%"=="%ORIGIN_SHA%" call :SAY "        ok - this PC and GitHub match."

:SKIPSYNC
call :SAY ""

REM ===========================================================================
REM  STEP 2  -  clean slate
REM ===========================================================================

call :SAY "  [2/9] Clearing the work folder..."
if exist "%WORK%" rd /s /q "%WORK%"
mkdir "%WORK%" || goto FAIL
mkdir "%STICK%" || goto FAIL
if not exist "%OUT%" mkdir "%OUT%"
if exist "%OUT%\%ZIPNAME%" del /q "%OUT%\%ZIPNAME%"
call :SAY "        ok"
call :SAY ""

REM ===========================================================================
REM  STEP 3  -  the robot code
REM ===========================================================================
REM  git archive, not a plain copy. git archive honours the export-ignore rules
REM  in .gitattributes, so the bench scripts, the handoff notes and the planning
REM  documents drop out exactly as they do from GitHub's own Download ZIP
REM  button. That list is already written and commented in the robot repo;
REM  this reuses it rather than inventing a second list that would drift.
REM ===========================================================================

call :SAY "  [3/9] Fetching the robot code from GitHub..."
git clone --quiet --depth 1 "%OHBOT_URL%" "%WORK%\src-ohbot" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Could not clone %OHBOT_URL%"
    goto FAIL
)
set "OHBOT_SHA="
for /f %%i in ('git -C "%WORK%\src-ohbot" rev-parse --short HEAD') do set "OHBOT_SHA=%%i"

git -C "%WORK%\src-ohbot" archive --format=zip --output="%WORK%\ohbot.zip" HEAD >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL
mkdir "%STICK%\OhbotPi2"
tar -xf "%WORK%\ohbot.zip" -C "%STICK%\OhbotPi2" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL
call :SAY "        ok - OhbotPi at %OHBOT_SHA%"
call :SAY ""

REM ===========================================================================
REM  STEP 4  -  the chess code
REM ===========================================================================

call :SAY "  [4/9] Fetching the chess code from GitHub..."
git clone --quiet --depth 1 "%CHESS_URL%" "%WORK%\src-chess" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Could not clone %CHESS_URL%"
    goto FAIL
)
set "CHESS_SHA="
for /f %%i in ('git -C "%WORK%\src-chess" rev-parse --short HEAD') do set "CHESS_SHA=%%i"

git -C "%WORK%\src-chess" archive --format=zip --output="%WORK%\chess.zip" HEAD >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL
mkdir "%STICK%\Chess"
tar -xf "%WORK%\chess.zip" -C "%STICK%\Chess" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL
call :SAY "        ok - YobotChess at %CHESS_SHA%"
call :SAY ""

REM ===========================================================================
REM  STEP 5  -  Python, complete, with every package
REM ===========================================================================
REM  This is the whole point of the stick. The embeddable build of Python is a
REM  22 MB zip that needs no installer and touches nothing on the machine it
REM  runs on - no registry, no PATH, no "add Python to PATH" tick box that
REM  half the people forget.
REM
REM  It does need one fiddly edit, below, and getting it wrong is the classic
REM  way this fails. The answer baked in here is the one already proved on the
REM  working stick. Do not "tidy" it.
REM ===========================================================================

call :SAY "  [5/9] Downloading Python 3.11.9 (about 22 MB)..."
curl -L -s -S -o "%WORK%\python-embed.zip" "%PY_URL%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Download failed. Check the internet and try again."
    goto FAIL
)
mkdir "%STICK%\python"
tar -xf "%WORK%\python-embed.zip" -C "%STICK%\python" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

REM  --- the fiddly edit -------------------------------------------------
REM  python311._pth tells this Python where it may look for code. Out of the
REM  box it is deliberately sealed: "import site" is commented out and nothing
REM  outside its own folder is on the path. That means pip does not work and
REM  the robot's own files are invisible. Three changes fix it:
REM
REM     import site      turns the normal import machinery back on, which is
REM                      what lets pip install and then be found
REM     ..\OhbotPi2      so "import yobot_core" finds the robot code
REM     ..\Chess         so the chess files can be found the same way
REM
REM  The paths are relative, which is what makes the stick work on any drive
REM  letter. The block below REPLACES the file rather than adding to it, so
REM  a second run does not end up with the lines twice.
(
echo python311.zip
echo .
echo.
echo # import site is ON. pip and the project folders below depend on it.
echo import site
echo ..\OhbotPi2
echo ..\Chess
) > "%STICK%\python\python311._pth"

call :SAY "        ok - Python unpacked and its path file written."
call :SAY ""

call :SAY "  [6/9] Installing the Python packages (this is the slow bit)..."
curl -L -s -S -o "%WORK%\get-pip.py" "%GETPIP_URL%" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL
"%STICK%\python\python.exe" "%WORK%\get-pip.py" --no-warn-script-location >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] pip would not install. See 'last build log.txt'."
    goto FAIL
)
"%STICK%\python\python.exe" -m pip install --no-warn-script-location -r "%REPO%\requirements-stick.txt" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] A package would not install. See 'last build log.txt'."
    goto FAIL
)
call :SAY "        ok - all packages installed."
call :SAY ""

REM  pip and setuptools stay. Removing them saves about 12 MB in the ZIP and
REM  some packages reach for pkg_resources at run time, so it buys an
REM  unexplainable import error on a stranger's laptop for 12 MB. Not worth it.

REM ===========================================================================
REM  STEP 7  -  take out what must not ship
REM ===========================================================================

call :SAY "  [7/9] Removing what must not go in the download..."

REM  Keys. git archive cannot produce these, so this is belt and braces - but
REM  belt and braces is the right posture for a public download.
if exist "%STICK%\OhbotPi2\.env" del /q "%STICK%\OhbotPi2\.env"
if exist "%STICK%\Chess\.env" del /q "%STICK%\Chess\.env"
if exist "%STICK%\OhbotPi2\git_keys.txt" del /q "%STICK%\OhbotPi2\git_keys.txt"

REM  Logs can contain transcripts of what people said to the robot.
if exist "%STICK%\OhbotPi2\logs" rd /s /q "%STICK%\OhbotPi2\logs"
if exist "%STICK%\Chess\logs" rd /s /q "%STICK%\Chess\logs"

REM  __pycache__ - a couple of hundred folders of nothing useful.
for /d /r "%STICK%" %%d in (__pycache__) do if exist "%%d" rd /s /q "%%d"

REM  --- the two files written for the INSTALLED route, which are wrong here --
REM
REM  OhbotPi2\Windows\SETUP.bat builds a second Python at
REM  %USERPROFILE%\yobot-venv and installs every package into it. On the stick
REM  that is not just pointless, it dumps 200 MB into a stranger's home folder
REM  for nothing. And Windows\START HERE.md calls it Step 3.
if exist "%STICK%\OhbotPi2\Windows\SETUP.bat" del /q "%STICK%\OhbotPi2\Windows\SETUP.bat"
REM
REM  catch-up-from-github.bat looks for a .git folder, does not find one on the
REM  stick, and stops with "This folder is not a git copy of the project."
REM  Harmless, but baffling, and baffling is the thing to avoid here.
if exist "%STICK%\OhbotPi2\Windows\catch-up-from-github.bat" del /q "%STICK%\OhbotPi2\Windows\catch-up-from-github.bat"
REM
REM  Chess\SETUP.bat is the same story a third time: it builds the venv AND
REM  downloads Stockfish. On the stick, GET THE CHESS ENGINE.bat does the
REM  engine and nothing needs a venv.
if exist "%STICK%\Chess\SETUP.bat" del /q "%STICK%\Chess\SETUP.bat"

call :SAY "        ok"
call :SAY ""

REM ===========================================================================
REM  STEP 8  -  put the stick's own files on top
REM ===========================================================================

call :SAY "  [8/9] Adding the stick's own files..."

REM  The corrected chess launchers. See chess-overrides\ and BUILD.md - the
REM  repo versions look for %USERPROFILE%\yobot-venv BEFORE the stick's own
REM  Python, which is right on an installed machine and wrong here.
copy /y "%REPO%\chess-overrides\*.bat" "%STICK%\Chess\" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

REM  And the top-level files people actually click.
xcopy /e /i /y /q "%REPO%\stick-root\*" "%STICK%\" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

(
echo Yobot on a Stick  v%VERSION%
echo Built      %DATE%
echo OhbotPi    %OHBOT_SHA%
echo Chess      %CHESS_SHA%
echo Python     3.11.9 embeddable
echo Stockfish  18  ^(sf_18, x86-64 plain build^) - fetched, not included
) > "%STICK%\VERSION.txt"

call :SAY "        ok"
call :SAY ""

REM ===========================================================================
REM  STEP 9  -  zip it
REM ===========================================================================

call :SAY "  [9/9] Zipping. A minute or two - there are a lot of small files..."
pushd "%STICK%"
tar -a -c -f "%OUT%\%ZIPNAME%" * >> "%LOG%" 2>&1
set "ZIPRC=%ERRORLEVEL%"
popd
if not "%ZIPRC%"=="0" (
    call :SAY "        tar could not do it - trying PowerShell instead..."
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%STICK%\*' -DestinationPath '%OUT%\%ZIPNAME%' -Force" >> "%LOG%" 2>&1
    if errorlevel 1 goto FAIL
)
if not exist "%OUT%\%ZIPNAME%" goto FAIL

call :SAY ""
call :SAY "  ======================================================================"
call :SAY "    DONE"
call :SAY "  ======================================================================"
call :SAY ""
call :SAY "    %OUT%\%ZIPNAME%"
call :SAY ""
call :SAY "    OhbotPi %OHBOT_SHA%   Chess %CHESS_SHA%"
call :SAY ""
call :SAY "    Before you upload it to a GitHub Release, do the two checks in"
call :SAY "    BUILD.md under 'Before you publish'. They take one minute and"
call :SAY "    they are the difference between a download and an incident."
call :SAY ""
pause
endlocal
exit /b 0

REM ===========================================================================

:SAY
REM  echo( survives an empty string; a plain "echo %~1" would print
REM  "ECHO is on." instead of a blank line. And the redirect goes FIRST,
REM  because a line of text ending in a digit merges with the append
REM  arrows into a numbered redirect, and the line vanishes.
echo(%~1
>>"%LOG%" echo(%~1
exit /b 0

:FAIL
call :SAY ""
call :SAY "  ======================================================================"
call :SAY "    BUILD FAILED"
call :SAY "  ======================================================================"
call :SAY ""
call :SAY "    The reason is in:  %LOG%"
call :SAY "    Open it and read the LAST twenty lines. Nothing was published."
call :SAY ""
pause
endlocal
exit /b 1
