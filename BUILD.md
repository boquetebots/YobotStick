# Making a release

For me, later, when I have forgotten all of this.

---

## The short version

1. Push any robot or chess changes to GitHub first.
2. Double-click `build-stick.bat`. A few minutes.
3. Do the two checks under **Before you publish** below. One minute.
4. Draft a Release on GitHub, attach `dist\Yobot-on-a-Stick-Windows-v1.0.zip`,
   paste `VERSION.txt` into the notes.

`last build log.txt` has everything the build did. Read it before changing
anything when a build fails — the reason is almost always in the last twenty
lines.

---

## Never build by zipping the stick

It is quicker and it is how keys get published.

The stick that has been carried around and plugged into other people's laptops
has a `.env` on it with live keys. `build-stick.bat` takes everything from a
fresh `git archive` instead, so the keys cannot come out — they were never in
git in the first place.

`git archive` also honours the `export-ignore` rules in the robot repo's
`.gitattributes`, so the bench scripts and the planning notes drop out exactly
as they do from GitHub's own Download-ZIP button. One exclusion list, already
written and commented, rather than a second one here that would drift out of
step.

---

## What the build does, and the bits that are not obvious

**It checks your PC against GitHub first.** The build clones from GitHub, so
anything committed only on this machine would be left out of the download and
look perfectly fine. If the working copy is dirty or ahead of `origin/main`,
the build stops. `build-stick.bat force` overrides that when you mean it.

**The Python path file.** `python311._pth` is the fiddly bit, and the usual way
this fails. The embeddable Python ships sealed: `import site` commented out and
nothing outside its own folder importable, so pip does not work and the robot's
own code is invisible. Three lines fix it, and the build writes them rather
than rediscovering them:

```
import site
..\OhbotPi2
..\Chess
```

Relative, which is what lets the stick work on any drive letter.

**pip and setuptools stay in.** They are about 40 MB of the 172 MB, roughly
12 MB zipped. Some packages reach for `pkg_resources` at runtime, so removing
them buys an unexplainable import error on a stranger's laptop for 12 MB. Not a
trade worth making.

---

## Three files the build deletes, and why

All three are written for the *installed* route and land on the stick verbatim
unless stopped.

**`OhbotPi2\Windows\SETUP.bat`** builds a virtual environment at
`%USERPROFILE%\yobot-venv` and installs every package into it. On the stick that
is not merely redundant — it dumps a second 200 MB Python into a stranger's home
folder for nothing. `Windows\START HERE.md` calls it Step 3, which is why
`stick-root\START HERE (stick).md` exists and says up front to ignore any guide
that mentions it.

**`OhbotPi2\Windows\catch-up-from-github.bat`** looks for a `.git` folder, does
not find one on the stick, and stops with *"This folder is not a git copy of the
project."* Harmless, but baffling, and baffling is exactly what this download
cannot afford.

**`Chess\SETUP.bat`** is the same story a third time — it builds the venv *and*
downloads Stockfish. On the stick, `GET THE CHESS ENGINE.bat` does the engine
and nothing needs a venv.

---

## `chess-overrides\` — the wrong-Python bug, again

**Found 2026-09-19 while building this repo. It is live on the current stick.**

`Chess\Play Chess.bat` and `Chess\Play a Human.bat` choose their Python like
this:

```
set "VENVPY=%USERPROFILE%\yobot-venv\Scripts\python.exe"
if exist "%VENVPY%" set "PY=%VENVPY%"        <- venv first
...then  where python  ...then  where py
```

**The stick's own Python is not in that list at all.** So:

- On a stranger's laptop there is no venv, so it falls through to the system
  `python` — which has none of the packages. Chess dies with a missing-package
  error on a drive that is carrying every package it needs.
- On a laptop that *does* have a venv — mine — it runs the venv instead, and
  works. Which is why this survived testing.

The robot project already gets this right;
`OhbotPi2\Windows\yobot-launcher.bat` tries `..\python\python.exe` first, then
the venv, then bare `python`. The two files in `chess-overrides\` are the chess
launchers with that same order, and the build copies them over the top after the
`git archive`.

**This override is a patch, not the fix.** The fix belongs upstream in
`boquetebots/YobotChess`, and the order there needs care: on an *installed*
machine the venv genuinely should win, because that is where the Azure voice
lives. Looking for `..\python\python.exe` first is safe in both cases, since
that folder only exists on the stick. Once YobotChess carries that, delete
`chess-overrides\` and this section.

This is the same lesson as `wrong_python_trap.md`, wearing a different hat:
**never name a Python; inherit the one that is already running, and when you
must choose, choose the one beside the code.**

---

## Stockfish is pinned to 18, on purpose

Version 19 came out on 5 September 2026. `GET THE CHESS ENGINE.bat` fetches 18
anyway.

**Not** because the strength dials changed — they did not. `Skill Level`,
`UCI_LimitStrength` and `UCI_Elo` are all still there in 19, undeprecated, and
`chess_server.py` keeps working.

Because 19 tightened validation of board positions, FEN strings and UCI
commands, and on input it dislikes it prints `info string CRITICAL ERROR` and
**terminates immediately**, where 18 tolerated it. Nothing in the chess code
catches `EngineTerminatedError` — `chess_dropout.py` handles Azure speech
dropping out, not the engine dying. Under 19, one position the engine dislikes
ends the show in front of an audience with no recovery.

### The address trap

Version 19 restructured the Windows downloads. Checked by HTTP status
2026-09-19:

| Tag | `...-x86-64.zip` | `...-avx2.zip` | `...-universal.zip` |
|---|---|---|---|
| `sf_18` | **200** | **200** | 404 |
| `sf_19` | 404 | 404 | **200** |

So `releases/latest/download/...universal.zip` can only ever resolve to 19 —
the exact version being avoided — and would do it silently. **Never `latest`.**
The pinned address is in `GET THE CHESS ENGINE.bat` with the reasoning beside
it.

### And it is the plain build, not avx2

The current stick carries `stockfish-windows-x86-64-avx2.exe`. The project's own
`Chess/STOCKFISH_SETUP.md` says to pick the plainest name, with nothing after
the `x86-64` — and it is right. On an older laptop without AVX2 the avx2 binary
does not fail politely, it crashes with an illegal instruction, which reads to
the person holding the laptop as "your software is broken". The pinned address
is the plain build, so the download gets this right by default.

**The file on the existing physical stick is still the avx2 one and is worth
swapping by hand.**

### Revisiting 19

Cheap test, worth doing once before an audience needs it: drop the 19 universal
build in on the Windows PC, run a full demo game, watch the console for
`CRITICAL ERROR`. If it never appears, 19 is worth up to 44 Elo for nothing.
Catching `EngineTerminatedError` first would make the whole question much less
interesting, which is the better order.

---

## Pushing: two different failures that look alike

**The old token expired on 19 September 2026.** A new one was made on the Mac,
and this PC has never seen it — what Windows has saved is the dead one.

So a refused push now has two possible causes, and they need opposite fixes:

| The log says | What it is | Fix |
|---|---|---|
| `denied to boquetebots`, 403 | The login worked. The fine-grained token just doesn't list a repo that didn't exist when it was made. | Add `YobotStick` to the token's repository list in GitHub settings. The token value doesn't change. |
| `Authentication failed`, `Invalid username or token`, `could not read Username` | The login itself was rejected — Windows is offering the expired token. | Credential Manager → Windows Credentials → remove `git:https://github.com` → push again → username `boquetebots`, password = **the new token**. |

`MAKE THE REPO AND PUSH.bat` now reads its own log and tells you which one you
have, because guessing wrong here costs an afternoon.

Getting the new token from the Mac to the PC: password manager, or type it by
hand. Not email. **Do not paste it into `git_keys.txt`** — that is exactly how
the last one came to be sitting in a project folder for three months.

**Building needs no token at all.** Both repos are public and `build-stick.bat`
only reads them; it sets `GIT_TERMINAL_PROMPT=0` so it fails fast rather than
hanging on an invisible credentials prompt. An expired token stops a push, not
a build.

---

## Before you publish

Two minutes, and the difference between a download and an incident.

**1. No keys in the ZIP.** Open it and confirm there is no `.env`, no
`git_keys.txt`, nothing matching `*key*`. This should be automatic — it all
comes from `git archive` — but confirm it every single time, because the cost of
being wrong once is unbounded.

**2. Click the files a stranger will click.** Extract the ZIP to a scratch
folder, then run `TEST THIS COMPUTER.bat` and `YOBOT SHOW.bat` from *there*, not
from the stick. Every guide that ships must name a file that actually exists,
in the folder it says. This is how the missing-`SETUP.bat` problem was found the
first time, and checking takes thirty seconds.

**Separately: `git_keys.txt` in `D:\Projects\OhbotPi2` holds the token that
expired on 19 September 2026, so it is no longer live — but delete it anyway.
A file of dead credentials is a trap for whoever reads it next, and leaving it
there invites the new token being pasted into it. It is gitignored either way,
so it was never going to reach the ZIP.**

---

## Versioning

`VERSION.txt` records commit hashes rather than tags — neither `OhbotPi` nor
`YobotChess` is tagged, and the build is perfectly reproducible from a hash.
Tags can be added later without changing anything here.

```
Yobot on a Stick  v1.0
Built      19/09/2026
OhbotPi    ec9c583
Chess      a1b2c3d
Python     3.11.9 embeddable
Stockfish  18  (sf_18, x86-64 plain build) - fetched, not included
```

Paste it into the Release notes. It makes every future bug report answerable.

---

## No updater in v1

To move to a new version: download the new ZIP, extract, copy over the stick,
copy your `.env` back. An updater that preserves `.env`, `ohbotData\` and
`sequences\` is worth building once somebody is actually using this. Not for an
audience of zero.
