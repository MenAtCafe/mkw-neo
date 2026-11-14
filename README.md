# Mario Kart World on an 8 GB Mac

Mario Kart World, the Switch 2 game, running natively on a MacBook Neo: Apple A18 Pro, 8 GB of unified memory, macOS 27.
There is no emulator here. The game's own ARM64 code runs, Horizon's services are reimplemented under it and NVN2 is
translated to Metal, which is what [nxnative](https://github.com/seedds/nxnative) does.

This repository is that build: current nxnative main plus the handful of changes it took to fit this game on a machine
with 8 GB, a keyboard layout made for it, and the measurements that came out of running it.

> **There is a newer build on a branch: [`upstream-refresh`](https://github.com/MenAtCafe/mkw-neo/tree/upstream-refresh).**
> It moves 245 commits forward on the engine, turns the game's own dynamic resolution back on, adds a render scale and
> carries a pipeline archive, so the game can lower its 3D resolution under load for the first time and a first visit
> should not spend itself compiling. That is the change most likely to raise the frame rate on a machine like this, and
> nothing about it is measured yet: it is there to be built and tried, and its README says what to expect, good and bad.
> The numbers below are this build's, not its.

Nothing from the game is in here. No ROM, no keys, no built app. You need your own copy of the game to build it.

## What it does here

| Metric | This machine |
|---|---|
| Render | 1080p, upscaled to the window by MetalFX |
| Footprint | 4.1 to 4.5 GB while racing |
| Frame rate | about 52 fps mean in a race, 57.5 in free roam, every frame one vsync |
| Typical window | 10 to 35 dropped frames of 300, at true speed |
| Game speed | 1.000 of real time, so no slow motion |
| Frame-rate cap 30 | 0 to 2 dropped of 300, loads take twice as long |
| First visit to an area | 78 to 95 dropped of 300 while its pipelines compile |

For comparison, the first build of this project measured 84 to 130 dropped of 300 on the same course, with a p99 past
100 ms. The gain is not a bigger fps number: it is that a long frame now costs a frame instead of making the game run in
slow motion. [PERFORMANCE.md](PERFORMANCE.md) has the runs behind every number here.

## What this repository adds to nxnative

**A keyboard map, `DM_KBD_MAP`, in `dm/host/pad_kbd.h`.** The Mac layout is J K U I for A B X Y and nothing for the
camera, which is unusable without a controller. The map is data, 25 actions, and it is the change we sent upstream as
[PR #1535](https://github.com/seedds/nxnative/pull/1535). See [keyboard-layout.md](keyboard-layout.md).

**The guest memory stays in files** (`DM_GUEST_FILE=1`). Upstream has the feature now; this build turns it on.

**Packaged textures upload on the CPU when the guest memory is in files.** A no-copy Metal buffer over file pages is read
into memory and wired when it enters the residency set, which measured tens of milliseconds of GPU a frame before this
gate. `keep_cpu` in `pkg_upload_` is the gate; `dm_guest_file_backed()` in `hle_svc.c` is what it asks.

**A profile fitted to a 1.0.0 dump**: the modules and RomFS marker this dump has, `mem_map_limit on`, and handheld mode,
which targets 1080p rather than a docked 4K picture.

**A squircle icon**, through `MAC_ICON` in `dm/mac/pack_app.py`, instead of the game's own icon.

**One-command build and play**: `scripts/build.sh` bakes the settings and the icon and drops the bundle seal;
`scripts/play.sh` launches the app. `DM_FPS_HOLD=off` is part of the build because it is what made the race feel steady.

`tex_soft`, the old fork's texture softening, is **not** carried here. Our build of it saved about 0.4 GB and broke Mario
Kart World's terrain UVs: its terrain shaders read a texture's size to lay out those UVs, so a texture one level down tiles
half as often and the road becomes flat plates. plumber-racer-2 now runs `tex_soft` on for this game and reports no broken
textures, so that finding may belong to the older engine. Untested here.

## How to play

Build the app, then double-click it or run `scripts/play.sh`. Hold **Option** at launch for the launcher: frame-rate cap,
console mode, upscaling, display mode and language. [docs/playing.md](docs/playing.md) has the switches and the controller
notes.

| Key | Pad |
|---|---|
| C X V Z | A B X Y |
| Q O | ZL ZR |
| E U | L R |
| F H | click left / right stick |
| WASD | left stick |
| I J K L | right stick (camera) |
| arrows | D-pad |
| Shift with an arrow | the same direction on the right stick |
| = - | + - |
| Space | shake |

## Building

You need the game's dump (v0 1.0.0 for this profile; a folder or a NUP), Xcode 27.2, Homebrew, an arm64 Python 3.12 and
the toolchain nxnative lists. Then:

```sh
DUMP="/path/to/your/dump" scripts/build.sh
```

It builds from the dump named in `DUMP`, packs the Mac host and shaders, bakes in the settings and the keyboard map, puts
the icon in, signs the two executables and removes the bundle seal so macOS does not re-hash the 22 GB RomFS before the
first launch. About 46 minutes the first time, 23 of them 11,560 shaders; about 5 minutes after that, because the shader
cache is reused.

The pipeline archive is skipped (`--gpu none`). The app builds its pipelines on first use instead, which is the 78 to 95
dropped frames in the table. A build with `GPU=<gpu>` makes the archive instead, for the cost of an hour.

`DUMP` has no default on purpose: it is your path, never the repository one. `OUT` and `WORK` default to `~/Documents`,
and all of them can come from `scripts/local.conf`, which is not tracked. `DM_GUEST_FILE` needs about 10 GB free on the
temp volume (a 2 GB floor plus 8 GB, since a Mac can swap); without it the game falls back to anonymous memory and the
footprint climbs to 8 GB.

## Running

```sh
scripts/play.sh
```

Double-click the app, or run the script if you want a terminal. The host keys its save, its pipeline cache and its temp
files by title ID, in `~/Library/Application Support/nxnative/0400C3F00006E000/`; the log is at
`~/Library/Logs/nxnative/0400C3F00006E000.log`.

## Measurements

[PERFORMANCE.md](PERFORMANCE.md) has the runs behind the numbers above: Koopa Troopa Beach with a warm cache, free roam,
the first visit to an area, the alternates (cap 30, `DM_FPS_TARGET=0`, `DM_RENDER_SCALE=0.75`), what each change was
worth, and what is not measured here.

## Where this came from

Three builds, two weeks.

**The first one, early November 2026.** A fork of [plumber-racer-2](https://github.com/cheemu21/plumber-racer-2), itself a
port of [nxnative](https://github.com/seedds/nxnative) to this game. It carried the memory work that first got Mario Kart
World running on an 8 GB laptop: the guest memory in a file mapping, texture levels dropped to save space, tiles released
once uploaded, and a cap on how much memory the game could map. That build reached 40 to 57 fps with a 4.48 GB footprint,
and compiled 5,292 pipelines during a first visit, which cost 31 seconds and dropped 243 frames of 300.

**The second one, a week later.** This repository before the rebase: 3.7 to 4.0 GB, 0 to 10 dropped frames of 300 on a
warm course, a bundled 469.9 MB pipeline archive, and the keyboard map, the texture gate and the profile work. It reported
60 fps in races, and that was true in a narrow sense: when frames ran long, the game stretched its own clock, so the
counter held while the world slowed. That is the slow motion the next build removes.

**This one.** nxnative main as it stands, which now carries `DM_GUEST_FILE` itself and the host frame step for this game,
plus the keyboard map, the texture gate, the icon, the 8 GB profile keys and `DM_FPS_HOLD=off`. It runs at 1.000 real
speed, reports about 52 fps in a race and 57.5 in free roam, and sits at 4.4 GB. The old measurements are still in
[PERFORMANCE.md](PERFORMANCE.md), because a claim that nothing was lost is worth more next to the numbers it replaced.

**A fourth, on a branch.** [`upstream-refresh`](https://github.com/MenAtCafe/mkw-neo/tree/upstream-refresh) is the same port on
245 newer commits of the engine, plus a render scale taken from plumber-racer-2 and a pipeline archive in the build. Nothing
about it is measured. It is the one to try if you want to know whether this machine can beat 52 fps.

## Credits

The engine is [nxnative](https://github.com/seedds/nxnative) by seedds. This port started from
[plumber-racer-2](https://github.com/cheemu21/plumber-racer-2), a Mario Kart World port of nxnative whose bring-up and
memory work this build builds on. Ryujinx, LibHac, SPIRV-Cross and MacNativeGames are in that stack too. The measurements,
the keyboard map, the texture gate and the profile changes are ours.

No game files, no keys, no built application. The project is not affiliated with Nintendo.
