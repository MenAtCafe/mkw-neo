# Mario Kart World on an 8 GB Mac

Mario Kart World, the Switch 2 game, running natively on a MacBook Neo: Apple A18 Pro, 8 GB of unified memory, macOS 27.
No emulator. The game's own ARM64 code runs, Horizon's services are reimplemented under it, and NVN2 is translated to
Metal, which is what [nxnative](https://github.com/seedds/nxnative) does.

This repository is that build: current nxnative main plus the handful of changes this game needs on 8 GB, a keyboard
layout made for it, and the measurements that came out of running it.

Nothing from the game is in here. No ROM, no keys, no built app. You need your own copy of the game to build it.

## What it does here

| Metric | This machine |
|---|---|
| Render | 1080p, upscaled to the window by MetalFX |
| Footprint | 4.1 to 4.5 GB while racing |
| Frame rate | 30 fps steady, brief 60 on light stretches, about 38 fps mean |
| Typical window | 3 to 8 dropped frames of 300 |
| Game speed | 0.989 of real time, so no slow motion |
| Frame-rate cap 30 | 0 to 2 dropped of 300, loads take twice as long |

For comparison, the previous build measured 84 to 130 dropped of 300 on the same course, with a p99 past 100 ms. The
gain is not a bigger fps number: it is that a long frame now costs a frame instead of making the game run in slow motion.

## What this branch changes

Upstream nxnative main already carries `DM_GUEST_FILE` and the host frame step for this game. What is ours:

| Change | Where |
|---|---|
| Keyboard map as data (`DM_KBD_MAP`) over the default layout | `dm/host/pad_kbd.h`, `front_mac.m`, 44 checks |
| CPU upload gate: a file-backed guest block stays off the no-copy upload path | `dm/host/hle_svc.c`, one line in `pkg_upload_` |
| The squircle icon | `MAC_ICON` in `dm/mac/pack_app.py`, `assets/AppIcon.png` |
| Profile: `mem_map_limit on`, `op_mode handheld` | `dm/games/0400C3F00006E000/game.tsv` |
| Settings and one-command build | `assets/env.txt`, `scripts/build.sh` |

`DM_GUEST_FILE` takes the guest block out of the process footprint. On this game it is the difference between 4.4 GB and
8 to 9 GB, and without it the machine swaps until even the startup shader preparation crawls. It stays on.

## Building

You need your own dump (v0 1.0.0 for this profile), Xcode 27.2, Homebrew, an arm64 Python 3.12 and the toolchain nxnative
lists. Then:

```sh
DUMP="/path/to/your/dump" scripts/build.sh
```

The build takes about 46 minutes here, 23 of them 11,560 shaders. Rebuilds reuse the cache. A bundled pipeline archive is
skipped (`--gpu none`); the app builds its pipelines on the first launch instead, a few hundred pairs, one hitch each.

`DUMP` has no default on purpose: it is your path, never the repository's. `OUT` and `WORK` default to `~/Documents`, and
all three can come from `scripts/local.conf`, which is not tracked.

## How to play

Double-click the app. Its save, settings and cache are in
`~/Library/Application Support/nxnative/0400C3F00006E000/`, its log in `~/Library/Logs/nxnative/0400C3F00006E000.log`.

| Key | Pad |
|---|---|
| C X V Y | A B X Y |
| Q E | ZL ZR |
| E R | L R |
| F H | left and right stick press |
| WASD | left stick |
| I J K L | right stick (camera) |
| Shift with a letter | the same direction on the right stick |
| = - | + - |
| Space | shake |

Set `DM_KBD_MAP` to change any of it; the format is in [keyboard-layout.md](keyboard-layout.md). Hold Option at launch for
the launcher: frame-rate cap, console mode, upscaling, display mode, language.

## What it is not

- **Not 60 fps in races.** The GPU sits at 1080p and the game needs about twice the pixels it can afford to hold 60. It
  presents 60 in short stretches and settles at 30. A 30 cap makes that consistent at the cost of slower loading.
- **Not a bigger number than the old build.** The old build reported 60 because the game stretched time when frames ran
  long. This one runs at real speed and says 30.
- **Not immune to heat.** At 110 °C the machine throttles and the same scene drops from 30 to 22 fps. Charged, hard
  surface, short sessions.

## Credits

The port is [nxnative](https://github.com/seedds/nxnative) by seedds and its contributors; this repository adds the 8 GB
profile work, the keyboard map and the measurements. No game files, no keys, no built application, and no affiliation with
Nintendo.
