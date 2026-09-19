# Start here

This drive runs Yobot without installing anything on your computer.

There is no Step 1 that says "install Python". That is the whole point of it.
Python is already here, on the drive, with everything it needs. If you find a
guide anywhere in these folders that tells you to run `SETUP.bat`, that guide
was written for people who downloaded the project instead of getting this
drive. Ignore it — and tell me, because it should not have shipped.

---

## The three files you actually use

| Double-click this | What happens |
|---|---|
| `TEST THIS COMPUTER.bat` | Checks this machine, in plain words. Run it first on any new computer. |
| `START YOBOT.bat` | Opens the Yobot control page in your browser. |
| `STOP YOBOT.bat` | Stops everything, however it was started. |

A black window opens and stays open. **Leave it there.** It is not an error
message, it is the program running. Closing it stops Yobot.

If the browser says it cannot reach the page, give it another ten seconds and
refresh. The first start on a new computer is slower than the rest.

---

## Plugging the robot in

The robot connects by USB. Plug it in **before** you start Yobot — if you plug
it in afterwards, stop and start again so it gets noticed.

`TEST THIS COMPUTER.bat` will tell you whether it can see the robot, and say so
in words rather than in a code. You can run Yobot with no robot attached; the
control page works, there is just nothing to move.

The first time you run it, **Windows Firewall will ask permission.** Click
*Allow access*. Yobot is not reaching out to the internet there — it is opening
a page for your own browser on your own machine. Refuse and the page will not
load.

---

## What works with nothing at all

`YOBOT SHOW.bat` runs a show from recordings already on the drive. No internet,
no accounts, no keys. Voice included.

**This is the one to use in front of people**, and the one to use in a hall
where the wifi cannot be trusted. Everything else depends on a connection at
the moment you need it most.

---

## Giving Yobot a voice of its own

To have Yobot *listen* and *speak its own words* rather than play recordings,
it needs a Microsoft Azure account. Light use costs pennies. It is the only
account Yobot genuinely cannot work without.

To have Yobot *hold a conversation*, add one AI account as well — any one of
OpenAI, Anthropic, Google Gemini or Groq. Or run Ollama on your own computer,
which needs no account and no money, just a reasonably fast machine.

**You do not have to edit any file.** Start Yobot, and on the page that opens
click **Settings & Keys**. Paste the keys in there and it will test each one
and tell you whether it works. That is much easier than getting a file called
`.env` right on Windows, where the file browser hides the ending and quietly
saves it as `.env.txt`.

There are no keys on this drive when it arrives. When you add yours, they are
saved **onto the drive** — so you only do it once, and so anyone you lend the
drive to has them too. Worth remembering before you hand it over.

---

## Chess

Three files, in the order you use them:

1. `GET THE CHESS ENGINE.bat` — once, with internet. Fetches Stockfish, the
   program that decides the moves. It is 109 MB and has its own licence, which
   is why it is fetched rather than carried.
2. `PLAY A HUMAN CHESS.bat` — you against the robot.
3. `ROBOT v ROBOT CHESS.bat` — two robots against each other, which is the one
   audiences like.

The board and the game itself need no accounts. Only the robot's commentary
does, and that is the Azure key above.

---

## Moving it off the drive

You can copy everything here onto a hard disk and it will still work. The files
find their own folder rather than remembering a drive letter, so `E:` becoming
`F:` on the next machine does not break anything.

Keep the folders together: `python`, `OhbotPi2` and `Chess` must stay beside
each other, because that is how they find one another.

---

## Updating later

There is no update button in this version. To move to a newer one: download the
new ZIP, extract it, copy the contents over the drive, and copy your `.env`
back across if you made one. Your recordings and your robot's calibration live
in `OhbotPi2\ohbotData` and `OhbotPi2\sequences` — keep those too.

---

## When something is wrong

**Run `TEST THIS COMPUTER.bat` again.** It is written to explain what it finds,
not just to pass or fail, and it catches most of it.

**Nothing changed after an update.** The browser is showing you a saved copy of
the page. Hold Ctrl and press F5.

**It greets you and then goes quiet.** It is listening to the wrong microphone —
a laptop usually has two or three, and Windows does not always pick the one you
mean. The Settings page lets you choose.

**Chess says a Python package is missing.** Something started the wrong Python.
Make sure you are clicking the files at the top of the drive rather than ones
inside the `Chess` folder.

**Windows blocked the file.** Right-click it, Properties, tick *Unblock* at the
bottom, OK.

When you ask for help, open `VERSION.txt` on this drive and quote it. It says
precisely which build you have, which turns guesswork into an answer.
