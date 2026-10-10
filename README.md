# Garmin-Flag-Game
An application built for the Garmin Vivo Active 5 to guess country/sovereign state flags

## How to play

1. Pick a region (World, Africa, Americas, Asia, Europe, Oceania) and how many flags.
2. A flag appears. Guess in your head, then tap (or press the top button) to reveal the name.
3. Swipe right if you were correct, left if you were wrong.
4. Swipe down on the next flag to undo a mis-swipe.
5. The back button ends the session early. The summary shows your accuracy; tap it to list the flags you missed.

Nothing is saved between sessions.

## Building

Needs the Connect IQ SDK with the `vivoactive5` device files, Java, and a developer key.

In VS Code with the Monkey C extension: `Monkey C: Build Current Project`, or press F5 to run in the simulator.

From a terminal, with the SDK `bin` folder and Java on `PATH`:

```
monkeyc -f monkey.jungle -o bin/FlagQuiz.prg -y <path to developer_key> -d vivoactive5 -w
```

Start the simulator (`simulator`), then load the app with `monkeydo bin/FlagQuiz.prg vivoactive5`.

To install on a watch, connect it over USB and copy `bin/FlagQuiz.prg` into `GARMIN/APPS`.

### Tests

```
monkeyc -f monkey.jungle -o bin/FlagQuizTest.prg -y <path to developer_key> -d vivoactive5 -t
monkeydo bin/FlagQuizTest.prg vivoactive5 /t
```

### Regenerating flags

`python tools/build_flags.py` (needs Pillow) downloads the flags from flagcdn.com and regenerates
`resources/drawables/flags/`, `resources/drawables/flags.xml`, `resources/drawables/launcher_icon.png`
and `source/Countries.mc`. The country list lives in that script.
