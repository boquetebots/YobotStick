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

REM  The working stick. Several things a stick needs are gitignored and so
REM  cannot come out of a clone - the recordings, the live motor calibration,
REM  the drive icon. stick-extras.txt lists them and they are copied from
REM  here. Note this is the working STICK, not D:\Projects\OhbotPi2, which
REM  has neither voice_cache nor a live calibration.
set "STICK_SRC=D:\Projects\YobotStick"

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

REM  Two different mismatches are possible here and only ONE of them is a
REM  problem. The first version of this script treated them the same and
REM  stopped a build that was perfectly safe, which is worse than useless -
REM  it teaches you to reach for 'force', and then 'force' stops meaning
REM  anything on the day it matters.
REM
REM    GitHub AHEAD of this PC  - the Mac pushed work this PC has not pulled.
REM                               Building from GitHub ships the NEWER code,
REM                               which is what you want. Carry on.
REM    This PC AHEAD of GitHub  - this PC has commits GitHub has never seen.
REM                               Building from GitHub would silently ship
REM                               OLDER code than the machine you are sat at.
REM                               Stop.
REM    Diverged                 - both have commits the other lacks. Stop,
REM                               because nobody can say which is correct.
REM
REM  merge-base --is-ancestor answers this. It exits 0 when the first commit
REM  is an ancestor of the second.

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

if not defined DIRTY goto SYNCCHECK
call :SAY ""
call :SAY "        [!] STOP. %LOCAL_OHBOT% has changes that are not committed."
call :SAY "            Those changes will NOT be in the download."
call :SAY "            Commit and push them first, or run:  build-stick.bat force"
call :SAY ""
if /i not "%~1"=="force" goto FAIL
call :SAY "        'force' given - carrying on anyway."

:SYNCCHECK
if not defined LOCAL_SHA goto SKIPSYNC
if not defined ORIGIN_SHA goto SKIPSYNC
if "%LOCAL_SHA%"=="%ORIGIN_SHA%" (
    call :SAY "        ok - this PC and GitHub match."
    goto SKIPSYNC
)

git -C "%LOCAL_OHBOT%" merge-base --is-ancestor %LOCAL_SHA% %ORIGIN_SHA% >nul 2>&1
if not errorlevel 1 goto BEHIND
git -C "%LOCAL_OHBOT%" merge-base --is-ancestor %ORIGIN_SHA% %LOCAL_SHA% >nul 2>&1
if not errorlevel 1 goto AHEAD
goto DIVERGED

:BEHIND
call :SAY "        ok - GitHub is ahead of this PC, which is the safe way round."
call :SAY "             this PC: %LOCAL_SHA%"
call :SAY "             GitHub : %ORIGIN_SHA%"
call :SAY "             The download gets GitHub's newer code. Nothing is lost."
call :SAY ""
call :SAY "             Worth knowing: that newer code has not been run on THIS"
call :SAY "             machine. Do the 'click what a stranger clicks' check in"
call :SAY "             BUILD.md once the ZIP is made. Pulling on this PC later"
call :SAY "             would keep the two in step."
goto SKIPSYNC

:AHEAD
call :SAY ""
call :SAY "        [!] STOP. This PC has commits GitHub has never seen."
call :SAY "              this PC: %LOCAL_SHA%"
call :SAY "              GitHub : %ORIGIN_SHA%"
call :SAY "            The download is built from GitHub, so it would ship code"
call :SAY "            OLDER than what is on this machine, and look fine doing"
call :SAY "            it. Push first, or run:  build-stick.bat force"
call :SAY ""
if /i not "%~1"=="force" goto FAIL
call :SAY "        'force' given - carrying on anyway."
goto SKIPSYNC

:DIVERGED
call :SAY ""
call :SAY "        [!] STOP. This PC and GitHub have each got commits the other"
call :SAY "            has not. They have genuinely split."
call :SAY "              this PC: %LOCAL_SHA%"
call :SAY "              GitHub : %ORIGIN_SHA%"
call :SAY "            Sort that out in the robot project before building - no"
call :SAY "            script can decide which of the two is the right one."
call :SAY "            Or run:  build-stick.bat force  to ship GitHub's side."
call :SAY ""
if /i not "%~1"=="force" goto FAIL
call :SAY "        'force' given - shipping GitHub's side."
goto SKIPSYNC

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
REM  STEP 7  -  cut it down to EXACTLY what a stick contains
REM ===========================================================================
REM  This replaces the old "delete the three files we know about" step, which
REM  was not good enough. The git export is the WHOLE robot project - Mac,
REM  Raspberry Pi and Windows together - and a stick is Windows only. Naming
REM  the bad files one at a time means every new Mac or Pi file added to the
REM  robot project silently lands on the next stick.
REM
REM  So it works the other way round now: stick-manifest.txt says what a stick
REM  contains, and anything else in the pruned folders goes. A new Mac file
REM  drops out on its own, and a missing required file stops the build in
REM  step 8b rather than turning up on a stranger's laptop.
REM ===========================================================================

set "MANIFEST=%REPO%\stick-manifest.txt"
if not exist "%MANIFEST%" (
    call :SAY "        [X] stick-manifest.txt is missing. Cannot tell what belongs."
    goto FAIL
)

call :SAY "  [7/9] Cutting down to what a stick actually contains..."

REM  Keys and logs first. git archive cannot produce a .env, but belt and
REM  braces is the right posture for a public download - and the prune below
REM  would only remove these as a side effect of them not being listed, which
REM  is not the same as deliberately deleting them.
if exist "%STICK%\OhbotPi2\.env" del /q "%STICK%\OhbotPi2\.env"
if exist "%STICK%\Chess\.env" del /q "%STICK%\Chess\.env"
if exist "%STICK%\OhbotPi2\git_keys.txt" del /q "%STICK%\OhbotPi2\git_keys.txt"

REM  Logs can hold transcripts of what people said to the robot.
if exist "%STICK%\OhbotPi2\logs" rd /s /q "%STICK%\OhbotPi2\logs"
if exist "%STICK%\Chess\logs" rd /s /q "%STICK%\Chess\logs"

REM  __pycache__ folders nest deeper than the three pruned folders, so the
REM  manifest never sees them. This is the only thing that removes them.
for /d /r "%STICK%" %%d in (__pycache__) do if exist "%%d" rd /s /q "%%d"

REM  --- who decides what goes: prune-list.ps1, not findstr -----------------
REM  findstr got this wrong twice in one hour, silently both times: once
REM  because the manifest had LF line endings (it then matched nothing and
REM  deleted all 105 files it looked at), and once on the single entry whose
REM  name starts with a dot, .env.example, because of how it handles a
REM  backslash followed by a dot in a supposedly literal search.
REM
REM  82 right out of 83 is worse than obviously broken. prune-list.ps1 does
REM  plain string comparison with no escaping rules and reads either kind of
REM  line ending. It writes the list; this script does the deleting.
if not exist "%REPO%\prune-list.ps1" (
    call :SAY "        [X] prune-list.ps1 is missing from the repo folder."
    goto FAIL
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO%\prune-list.ps1" -Manifest "%MANIFEST%" -Stick "%STICK%" -OutDir "%WORK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Could not work out what to drop. See the log."
    goto FAIL
)
if not exist "%WORK%\to-drop.txt" (
    call :SAY "        [X] No drop list was produced. See the log."
    goto FAIL
)

set "DROPPED=0"
set "KEPT=0"
for /f "usebackq delims=" %%E in ("%WORK%\to-drop.txt") do call :DROP "%%E"
for /f "usebackq tokens=1,2" %%A in ("%WORK%\prune-counts.txt") do set "KEPT=%%A"

call :SAY "        %KEPT% kept, %DROPPED% dropped - each drop listed in the log."

REM  --- the sanity gate ------------------------------------------------------
REM  A healthy prune drops maybe thirty things and keeps eighty. If it drops
REM  MORE than it keeps, the manifest is not being read properly - the source
REM  tree is not suddenly full of junk. Stop here and say so plainly, instead
REM  of deleting the whole stick and reporting eighty confusing MISSING lines
REM  two steps later, which is what happened the first time.
REM
REM  A guard that turns a silent catastrophe into one clear sentence is worth
REM  more than the check that eventually caught it.
if %DROPPED% GTR %KEPT% (
    call :SAY ""
    call :SAY "        [X] STOP. That dropped more than it kept, which cannot be"
    call :SAY "            right - it means the manifest is not being matched,"
    call :SAY "            not that the robot project is full of rubbish."
    call :SAY ""
    call :SAY "            Look at stick-manifest.txt and at to-drop.txt in the"
    call :SAY "            build folder - between them they will show which side"
    call :SAY "            of the comparison went wrong."
    call :SAY "            Nothing was published and nothing of yours was touched."
    goto FAIL
)
call :SAY ""

REM ===========================================================================
REM  STEP 8  -  the recordings, the stick's own files, and the check
REM ===========================================================================

call :SAY "  [8/9] Adding the recordings and the stick's own files..."

REM  --- 8a. everything git cannot provide -----------------------------------
REM  Driven by stick-extras.txt. Was a single hardcoded voice_cache copy until
REM  2026-09-20, when a stick shipped without the live motor calibration and
REM  THE ROBOT THRASHED AGAINST ITS STOPS and had to be unplugged.
REM
REM  The fault was not the missing file, it was the mechanism: one special
REM  case for the one gitignored thing anybody had thought of. There were
REM  four. Now there is a list, and the build stops if any of it is absent.
if not exist "%REPO%\copy-extras.ps1" (
    call :SAY "        [X] copy-extras.ps1 is missing from the repo folder."
    goto FAIL
)
if not exist "%REPO%\stick-extras.txt" (
    call :SAY "        [X] stick-extras.txt is missing from the repo folder."
    goto FAIL
)
if not exist "%STICK_SRC%" (
    call :SAY "        [X] Cannot see the working stick at:"
    call :SAY "            %STICK_SRC%"
    call :SAY "            The recordings and the motor calibration live there and"
    call :SAY "            cannot come from git. Not shipping without them."
    goto FAIL
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO%\copy-extras.ps1" -List "%REPO%\stick-extras.txt" -Source "%STICK_SRC%" -Stick "%STICK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Something in stick-extras.txt could not be copied."
    call :SAY "            See the log. Nothing was published."
    goto FAIL
)
set "NWAV=0"
for %%F in ("%STICK%\OhbotPi2\voice_cache\*.wav") do set /a NWAV+=1
call :SAY "        ok - extras copied in, %NWAV% recordings among them."

REM  --- 8a2. the per-machine files, GENERATED not copied --------------------
REM  These three are gitignored on purpose. The robot repo's own .gitignore
REM  explains why: "Real robot profiles live in ohbotData/robots/ and ARE
REM  shared." They describe one particular machine, so they should not be in
REM  git - and equally should not be copied off Michael's stick, which would
REM  ship his robot's state to strangers.
REM
REM  So they are made here, from ohbotData\robots\Ohbot.omd, which IS in git.
REM  Ohbot.omd is a stock Ohbot's calibration - conservative ranges, proper
REM  Center values - intended as a starting point, to be replaced by running
REM  Calibration.
REM
REM  Before this existed, a stick had no live calibration at all, the library
REM  fell back to a stale file from May with no Center values and an inverted
REM  eyelid, and THE ROBOT THRASHED AGAINST ITS STOPS. 2026-09-20.
set "ODATA=%STICK%\OhbotPi2\ohbotData"

if not exist "%ODATA%\robots\Ohbot.omd" (
    call :SAY "        [X] ohbotData\robots\Ohbot.omd is not in the robot repo."
    call :SAY "            That is the generic starting calibration, and without"
    call :SAY "            it a fresh stick has no motor limits at all. Push it"
    call :SAY "            to OhbotPi first - see BUILD.md."
    goto FAIL
)

copy /y "%ODATA%\robots\Ohbot.omd" "%ODATA%\MotorDefinitionsv21.omd" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

REM  Written with no trailing newline, to match what the working stick has.
REM  'Ohbot' with the capital, to match the profile file Ohbot.omd. The
REM  Launcher compares the two exactly, and lower case ("rubia" against
REM  Rubia.omd) is what made the dropdown show the wrong robot on 2026-09-20.
REM  robot_profiles.get_active() resolves the case too now, so this is belt
REM  and braces - but written right beats written wrong and corrected later.
powershell -NoProfile -ExecutionPolicy Bypass -Command "[IO.File]::WriteAllText('%ODATA%\active_robot.txt','Ohbot')" >> "%LOG%" 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "[IO.File]::WriteAllText('%ODATA%\language.txt',\"es`r`n\")" >> "%LOG%" 2>&1

REM  The one that costs hardware if it is wrong. Checked by name, on purpose,
REM  as well as by the manifest below - belt and braces for the only file on
REM  this stick whose absence can damage a robot.
if not exist "%ODATA%\MotorDefinitionsv21.omd" (
    call :SAY "        [X] The live motor calibration was not created."
    call :SAY "            Without it the robot is driven to its mechanical stops."
    goto FAIL
)
if not exist "%ODATA%\active_robot.txt" (
    call :SAY "        [X] active_robot.txt was not created."
    goto FAIL
)
call :SAY "        ok - calibration set from the generic Ohbot profile."

REM  --- 8a3. the language this drive starts in -------------------------------
REM  i18n.js carries two constants and its own comment says "change these two
REM  lines per stick". DEFAULT_LANG is what a browser shows the FIRST time it
REM  opens a Yobot page on that computer; after that the language pill wins.
REM
REM  Patched here rather than changed in the robot repo, because i18n.js is
REM  shared with the Pi, the Mac and the installed route, and this choice is
REM  about this download and not about those.
REM
REM  Note that ohbotData\language.txt is NOT what the interface reads. The
REM  page WRITES that file, to tell Python which language to speak. Shipping
REM  language.txt on its own did nothing on 2026-09-20 - the first page load
REM  posted 'en' straight over the top of it.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%STICK%\OhbotPi2\i18n.js'; $t=[IO.File]::ReadAllText($f); $n=$t.Replace(\"const DEFAULT_LANG = 'en';\",\"const DEFAULT_LANG = 'es';\"); if($n -eq $t){exit 1}; [IO.File]::WriteAllText($f,$n)" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :SAY "        [X] Could not set the stick's default language."
    call :SAY "            i18n.js no longer has the line this expects:"
    call :SAY "                const DEFAULT_LANG = 'en';"
    call :SAY "            Reformatted, or already changed upstream. Stopping"
    call :SAY "            rather than shipping an English stick by accident."
    goto FAIL
)
call :SAY "        ok - this drive starts in Spanish."

REM  --- 8b. the corrected chess launchers ------------------------------------
REM  The repo versions look for %USERPROFILE%\yobot-venv BEFORE the stick's own
REM  Python, which is right on an installed machine and wrong here. See
REM  chess-overrides\ and BUILD.md.
copy /y "%REPO%\chess-overrides\*.bat" "%STICK%\Chess\" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

REM  --- 8c. the files people actually click ----------------------------------
xcopy /e /i /y /q "%REPO%\stick-root\*" "%STICK%\" >> "%LOG%" 2>&1
if errorlevel 1 goto FAIL

if not exist "%STICK%\Utilities" mkdir "%STICK%\Utilities"
(
echo Yobot on a Stick  v%VERSION%
echo Built      %DATE%
echo OhbotPi    %OHBOT_SHA%
echo Chess      %CHESS_SHA%
echo Python     3.11.9 embeddable
echo Recordings %NWAV% files
echo Stockfish  18  ^(sf_18, x86-64 plain build^) - fetched, not included
) > "%STICK%\Utilities\VERSION.txt"

REM  --- 8d. is everything the manifest promises actually here? ---------------
REM  The half of the allow list that earns its keep. Dropping the wrong file is
REM  loud and immediate here, instead of silent until somebody double-clicks.
call :SAY "        checking every file the manifest promises is present..."
set "MISSING=0"
for /f "usebackq eol=# delims=" %%L in ("%MANIFEST%") do call :NEEDS "%%L"
if not "%MISSING%"=="0" (
    call :SAY ""
    call :SAY "        [X] %MISSING% thing(s) the manifest promises are not in the"
    call :SAY "            build. Listed above. Nothing was published."
    goto FAIL
)
call :SAY "        ok - nothing promised is missing."
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
call :SAY "    OhbotPi %OHBOT_SHA%   Chess %CHESS_SHA%   %NWAV% recordings"
call :SAY ""
call :SAY "    Before you upload it to a GitHub Release, do the two checks in"
call :SAY "    BUILD.md under 'Before you publish'. They take one minute and"
call :SAY "    they are the difference between a download and an incident."
call :SAY ""
pause
endlocal
exit /b 0

REM ===========================================================================
REM  Helpers
REM ===========================================================================

:DROP
call :SAY "        - dropped  %~1"
if exist "%STICK%\%~1\" (rd /s /q "%STICK%\%~1") else (del /q "%STICK%\%~1")
set /a DROPPED+=1
exit /b 0

REM  Complain if something the manifest promises is not in the build.
:NEEDS
if exist "%STICK%\%~1" exit /b 0
if exist "%STICK%\%~1\" exit /b 0
call :SAY "        - MISSING  %~1"
set /a MISSING+=1
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
