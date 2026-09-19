# Yobot on a Stick

A robot head that listens, thinks and talks back — on a USB stick that installs
nothing.

Unzip the download onto a blank thumb drive, plug it into any Windows PC, and
double-click one file. No Python to install, no administrator rights, no
"add Python to PATH" tick box, nothing left behind when you unplug it.

**[Download the latest release](https://github.com/boquetebots/YobotStick/releases/latest)**

---

## What is in the download

About 46 MB zipped, 300 MB on the drive.

```
READ ME FIRST.txt
START HERE (stick).md
TEST THIS COMPUTER.bat      <- run this first on a new machine
START YOBOT.bat
STOP YOBOT.bat
YOBOT SHOW.bat              <- the offline show. No internet, no accounts.
GET THE CHESS ENGINE.bat    <- optional, once, needs internet
PLAY A HUMAN CHESS.bat
ROBOT v ROBOT CHESS.bat
VERSION.txt
python\                     <- Python 3.11.9 and every package, ready to go
OhbotPi2\                   <- the robot code
Chess\                      <- the chess code; the engine is fetched separately
```

## What works with nothing at all

`YOBOT SHOW.bat` plays a full show from recordings already on the drive — voice
and all — with no internet and no accounts. That is the one to rely on in a hall
where the wifi cannot be trusted.

## What needs an account

For Yobot to listen and speak its own words rather than play recordings, it needs
a Microsoft Azure account (pennies for light use). To hold a conversation it needs
one AI account as well — OpenAI, Anthropic, Google Gemini, Groq, or Ollama running
locally, which needs no account at all.

**No keys ship on the drive.** You add your own through the Settings & Keys page in
your browser once Yobot is running; there is no file to edit.

## The chess engine is not included

Stockfish is 109 MB — more than twice the size of everything else here — and is
licensed under the GPL, which places conditions on anyone who redistributes it.
`GET THE CHESS ENGINE.bat` fetches it straight from the Stockfish project. One
run, once, and then chess works offline too.

It fetches **version 18**, deliberately, from a pinned address. The reasoning is
written in full at the top of that file and in `BUILD.md`. Short version:
version 19 shuts itself down on input it dislikes, and nothing in the chess code
catches an engine that dies. Do not change that address to `latest`.

---

## This repository

This repo holds no robot code. It is the packaging: the build script, the files
that land at the top of the stick, and the Releases.

| Repo | Holds |
|---|---|
| [`boquetebots/OhbotPi`](https://github.com/boquetebots/OhbotPi) | The robot code |
| [`boquetebots/YobotChess`](https://github.com/boquetebots/YobotChess) | The chess code |
| `boquetebots/YobotStick` | **This one.** Packaging and downloads. |

`BUILD.md` is how a release is made.

## Licence

MIT, for the code in this repository and the two it packages. Python and each
Python package carry their own licences, all permissive, and are included in the
download. Stockfish is GPL-3 and is **not** included — it is fetched by the person
using it, from its own project.
