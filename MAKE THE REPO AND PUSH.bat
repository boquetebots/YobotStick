@echo off
title Create the YobotStick repo and push it
REM ===========================================================================
REM  MAKE THE REPO AND PUSH.bat
REM ===========================================================================
REM
REM  Run this ONCE, to get this folder onto GitHub the first time.
REM  Safe to run again - it skips whatever is already done.
REM
REM  BEFORE YOU RUN IT, do this in a browser. It takes thirty seconds:
REM
REM     1. github.com, then  New repository
REM     2. Owner: boquetebots     Name: YobotStick
REM     3. Public
REM     4. Do NOT tick "Add a README", "Add .gitignore" or "Choose a license".
REM        This folder already has all three, and ticking those boxes puts a
REM        commit in the new repo that this one does not have, which turns a
REM        thirty second job into an argument with git about unrelated
REM        histories.
REM     5. Create repository. Close the page. Come back here.
REM
REM  EXPECT THE FIRST PUSH TO BE REFUSED. This is not a mistake in this script.
REM  ---------------------------------------------------------------------
REM  It happened on the first push of YobotChess too, and it will happen every
REM  time a new repo is created under boquetebots. The error reads:
REM
REM     remote: Permission to boquetebots/YobotStick.git denied to boquetebots.
REM     fatal: ... The requested URL returned error: 403
REM
REM  It is not about ownership and there is no organisation approval to hunt
REM  for - boquetebots is a User account. The saved login is a fine-grained
REM  personal access token limited to SELECTED repositories, and a repo made
REM  five minutes ago is not on its list.
REM
REM  The fix, in a browser, nothing to run:
REM     github.com, your avatar, Settings, Developer settings,
REM       Personal access tokens, Fine-grained tokens, click the token,
REM       Repository access: add YobotStick (or switch to All repositories),
REM       Repository permissions: Contents = Read and write, then
REM       Update token.
REM  The token VALUE does not change, so nothing needs re-entering anywhere.
REM  Then run this file again.
REM
REM  BUT THERE IS A SECOND, DIFFERENT REASON A PUSH CAN FAIL - and on this PC,
REM  right now, it is the more likely of the two.
REM  ---------------------------------------------------------------------
REM  The old token EXPIRED on 19 September 2026 and a new one was made on the
REM  Mac. This PC has never seen the new one. What Windows has saved is the
REM  old, dead token, and it will keep offering it.
REM
REM  That failure looks DIFFERENT. It says "Authentication failed", or
REM  "Invalid username or token", or "could not read Username". It does NOT
REM  say "denied to boquetebots". Two different problems, two different fixes,
REM  and using the wrong fix wastes an afternoon - so this script now reads
REM  its own log and tells you which one you have got.
REM
REM  The fix for THAT one is to throw away the saved login:
REM     Start menu, type  Credential Manager , open it
REM     Windows Credentials
REM     find  git:https://github.com   (there may be more than one)
REM     Remove
REM  Then run this file again. Git will ask who you are. Username is
REM  boquetebots and the PASSWORD IS THE NEW TOKEN, pasted in - not your
REM  GitHub account password, which has not worked for years. Some setups
REM  open a GitHub sign-in window in your browser instead; that works too.
REM
REM  Get the new token off the Mac and onto this PC in something that is not
REM  email - a password manager, or type it by hand. And do not paste it into
REM  git_keys.txt: that file is how the last one ended up sitting in a project
REM  folder for three months.
REM
REM ===========================================================================

setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"
set "URL=https://github.com/boquetebots/YobotStick.git"
set "LOG=%HERE%\last push log.txt"

cd /d "%HERE%"

echo Push log - %DATE% %TIME% > "%LOG%"

echo.
echo   ======================================================================
echo     Putting this folder on GitHub
echo   ======================================================================
echo.
echo     Folder: %HERE%
echo     Repo  : %URL%
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo   [X] git is not installed, or not on the PATH.
    pause
    endlocal
    exit /b 1
)

if not exist "%HERE%\build-stick.bat" (
    echo   [X] This does not look like the YobotStick folder - build-stick.bat
    echo       is not beside me. Put this file back where it belongs.
    pause
    endlocal
    exit /b 1
)

REM --- git init -------------------------------------------------------------
if exist "%HERE%\.git" (
    echo   - already a git folder, leaving it alone.
) else (
    echo   - starting git here...
    git init -b main >> "%LOG%" 2>&1
    if errorlevel 1 goto FAIL
)

REM --- the remote -----------------------------------------------------------
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo   - pointing it at GitHub...
    git remote add origin "%URL%" >> "%LOG%" 2>&1
) else (
    echo   - remote already set, updating it to be sure...
    git remote set-url origin "%URL%" >> "%LOG%" 2>&1
)

REM --- who is making this commit --------------------------------------------
REM  Git refuses to commit until it knows a name and an email to put on it,
REM  and this PC has never been told one globally - OhbotPi2 has an identity
REM  set inside that one folder, which is why this has never come up before.
REM  A brand-new folder starts with nothing, so the FIRST run here failed on
REM  the commit and never even reached the push. Fixed here rather than left
REM  as a thing to remember.
REM
REM  Set inside this folder only, which is the same way OhbotPi2 does it and
REM  changes nothing else on the machine. To stop it happening for every new
REM  repo, run these two once in any Command Prompt:
REM     git config --global user.name "Michael"
REM     git config --global user.email "carolinaudio@gmail.com"
git config user.email >nul 2>&1
if errorlevel 1 (
    echo   - no name on file for git here, setting one for this folder...
    git config user.email "carolinaudio@gmail.com" >> "%LOG%" 2>&1
    git config user.name "Michael (via Claude)" >> "%LOG%" 2>&1
)

REM --- commit ---------------------------------------------------------------
echo   - staging and committing...
git add -A >> "%LOG%" 2>&1
git diff --cached --quiet
if errorlevel 1 (
    git commit -m "Packaging repo for Yobot on a Stick" >> "%LOG%" 2>&1
    if errorlevel 1 goto FAIL
) else (
    echo     nothing changed since the last commit.
)

REM --- push -----------------------------------------------------------------
REM  The output is captured to the log on purpose. The one line that explains
REM  a refusal is the "remote:" line, and it goes with the window when the
REM  window is closed. Read the log, not the screen.
echo   - pushing...
echo. >> "%LOG%"
git push -u origin main >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" goto REFUSED

echo   ======================================================================
echo     DONE - it is on GitHub.
echo   ======================================================================
echo.
echo     %URL%
echo.
echo     Next: run  build-stick.bat  to make the ZIP, then attach the ZIP to
echo     a Release on that page.
echo.
pause
endlocal
exit /b 0

:REFUSED
REM  Read our own log back and work out WHICH failure this is, because the
REM  two look similar on screen and have completely different fixes.
findstr /i /c:"denied to" "%LOG%" >nul 2>&1
if not errorlevel 1 goto SCOPE
findstr /i /c:"Authentication failed" "%LOG%" >nul 2>&1
if not errorlevel 1 goto BADTOKEN
findstr /i /c:"could not read Username" "%LOG%" >nul 2>&1
if not errorlevel 1 goto BADTOKEN
findstr /i /c:"Invalid username or token" "%LOG%" >nul 2>&1
if not errorlevel 1 goto BADTOKEN
findstr /i /c:"Invalid username or password" "%LOG%" >nul 2>&1
if not errorlevel 1 goto BADTOKEN
goto OTHER

:SCOPE
echo   ======================================================================
echo     REFUSED - the token does not cover this repo yet
echo   ======================================================================
echo.
echo     Expected on a brand-new repo. The login worked; it is simply not
echo     allowed to touch a repo that did not exist when it was made.
echo.
echo     In a browser:
echo        github.com, your avatar, Settings, Developer settings,
echo        Personal access tokens, Fine-grained tokens, click the token,
echo        Repository access: add YobotStick, or switch to All repositories,
echo        Repository permissions: Contents = Read and write,
echo        Update token.
echo.
echo     The token value does not change, so nothing here needs re-entering.
echo     Then run this file again.
echo.
pause
endlocal
exit /b 1

:BADTOKEN
echo   ======================================================================
echo     REFUSED - Windows is offering the OLD, EXPIRED token
echo   ======================================================================
echo.
echo     This is not the repo-permissions problem. The login itself was
echo     rejected. The old token expired on 19 September 2026 and the new
echo     one was made on the Mac, so this PC has never had it.
echo.
echo     1. Start menu, type  Credential Manager , open it.
echo     2. Windows Credentials.
echo     3. Find  git:https://github.com  - there may be more than one.
echo     4. Remove each of them.
echo     5. Run this file again.
echo.
echo     Git will then ask who you are:
echo        Username: boquetebots
echo        Password: PASTE THE NEW TOKEN  (not your GitHub password)
echo.
echo     Some setups open a GitHub sign-in page in your browser instead.
echo     That is fine - sign in there and it will carry on.
echo.
echo     Get the token across from the Mac in a password manager, or type it
echo     by hand. Not email. And do not save it into git_keys.txt.
echo.
pause
endlocal
exit /b 1

:OTHER
echo   ======================================================================
echo     THE PUSH FAILED - and not in either of the two usual ways
echo   ======================================================================
echo.
echo     Open this file:
echo.
echo        %LOG%
echo.
echo     and read the last twenty lines. The line beginning "remote:" is
echo     almost always the whole diagnosis.
echo.
echo     Two things worth ruling out before anything else:
echo       - Did you create the empty repo on github.com first? Step 1 at the
echo         top of this file. Pushing to a repo that does not exist gives a
echo         confusing "not found" rather than a clear error.
echo       - Is this PC online?
echo.
pause
endlocal
exit /b 1

:FAIL
echo.
echo   [X] Stopped before the push. The reason is in:
echo.
echo        %LOG%
echo.
echo     Read the LAST few lines of it. If it says "Please tell me who you
echo     are", git has no name and email on this computer - this script now
echo     sets one automatically, so simply run it again.
echo.
pause
endlocal
exit /b 1
