# Mario Kart World on an 8 GB Mac: the refresh branch

Mario Kart World, the Switch 2 game, running natively on a MacBook Neo: Apple A18 Pro, 8 GB of unified memory, macOS 27.
There is no emulator here. The game's own ARM64 code runs, Horizon's services are reimplemented under it and NVN2 is
translated to Metal, which is what [nxnative](https://github.com/seedds/nxnative) does.

**This branch is the same port on a newer engine.** It is nxnative main `4b10c73f`, 245 commits past the `c4ffb9df`
that `main` is built on, plus one fix taken from [plumber-racer-2](https://github.com/cheemu21/plumber-racer-2).
`main` keeps the build that was measured; this one has not been run at all, so the numbers on `main` are still the only
numbers. [REFRESH.md](REFRESH.md) has the reasoning, and what was deliberately left out.

Nothing from the game is in here. No ROM, no keys, no built app. You need your own copy of the game to build it.

## What is different from main

| | `main` | this branch |
|---|---|---|
| Engine | nxnative main `c4ffb9df` | nxnative main `4b10c73f` |
| Frame step | a stub keyed by build ID, so v0 only | upstream's, placed by the function's fingerprint, v0 and 1.8.0 |
| Guest memory in files | our own, one file chunked by hand | upstream's `DM_GUEST_FILE`, with `DM_GUEST_FILE_CHUNK`, hole punching and a free-space floor |
| Render targets that the dynamic resolution resizes | new Metal memory for every size | upstream's recycled heaps |
| Thread deadlines | the presenting thread only | the acquire, queue replay and encode threads |
| The game's dynamic resolution | off in practice (one GPU timestamp per submission read about 0, so the scene never stepped down) | on (segment timestamps without the GPU's idle gaps are the default) |
| Render scale | not offered for this game | `DM_RENDER_SCALE`, 0.5 to 1.0, 1.0 the game's own sizes |
| Pipeline archive | skipped (`--gpu none`), so the app compiled its bases on first use | built for this Mac and carried in the app |
| Texture uploads over file-backed memory | on the CPU | on the CPU too, and the branch adds `DM_GUEST_FILE_CPU_UP=0`, which turns that off, to compare with upstream's path |
| Measured | yes, [PERFORMANCE.md](PERFORMANCE.md) | no |

The keyboard map, the icon, the 8 GB profile keys, the build scripts and the settings are the same as `main`, because they
were right the first time.

## What the new controls do

**Render scale.** A **Render scale** row now appears in the launcher under Game: 0.5 to 1.0, 1.0 by default. It multiplies
the six `For3D` entries of the game's resolution table and leaves the screen entries alone, so the final picture stays
1920x1080 and the HUD stays sharp while the 3D is smaller. The game's own dynamic resolution then steps down from whatever
ceiling it is given, so 0.75 means it starts at 1440x810 and can go lower, not that it renders at 1440x810.

**The game's own dynamic resolution.** The game times its GPU work from the timestamp reports the host returns. With one
time for the whole submission that difference is about zero, so it kept full size however long the GPU took. Per-segment
reports fix that, and upstream now leaves out the GPU's idle time between command buffers, which is what used to make the
size swing and distant detail flicker. This is the change that should let the game trade resolution for frames.

**`DM_GUEST_FILE_CPU_UP=0` turns the upload gate off.** The gate itself is the same as on `main` and stays on by default: a
no-copy Metal buffer over file pages is read into memory and wired when it enters the residency set, so such a texture is
deswizzled and staged on the CPU instead. Upstream now reads a large pool through a buffer of its own that the upload batch
holds, which may make the gate unnecessary, and the switch puts the uploads back on the GPU path so that can be measured.

Everything else is unchanged: `DM_FPS_HOLD=off`, MetalFX upscaling, the keyboard map, `mem_map_limit` and handheld mode.

## What to expect

**Better.** This is the first build where the game can lower its own 3D resolution under load, which is the lever that
matters on a GPU this small. Upstream measured that change on a 16 GB M1 Pro at 33.5 to 42 fps in a race. Recycled render
targets should also cut the long frames the resize used to cause: 1.8 GB of new Metal memory per 300 frames became 0.34. And the build carries a pipeline archive now, so a first
visit should not spend itself compiling.

**Worse.** The picture. Expect the 3D below 1080p most of the time, and on a smaller GPU than the ones upstream measured,
lower still: their 16 GB M6 held a mean scene width of 1433 to 1760 out of 2048. And whether segment times cost smoothness
is not settled upstream: 12 and 17 frames over two vsyncs per 2,400 with the old behaviour, against 19, 229 and 50 with them.

**Unknown.** Whether the frame pace under upstream's frame step behaves like the 52 fps `main` measured with
`DM_FPS_HOLD=off`, and whether the CPU upload gate is still the right trade.

`tex_soft` is off in this profile. Our earlier build found one level down tiles Mario Kart World's terrain UVs wrongly, since
its terrain shaders read a texture's size to lay out those UVs; plumber-racer-2 runs it on and reports no broken textures,
so that finding may belong to the older engine. Untested here.

## What is not measured

- The frame rate, dropped frames and footprint of this build, here or anywhere.
- What a render scale below 1.0 buys or costs.
- Whether the CPU upload gate is still needed.

## How to play

Build the app, then double-click it or run `scripts/play.sh`. Hold **Option** at launch for the launcher: frame-rate cap,
hold, console mode, upscaling, render scale and language. [docs/playing.md](docs/playing.md) has every switch and the
controller notes.

| Key | Pad |
|---|---|
| C X V Y | A B X Y |
| Q O | ZL ZR |
| E U | L R |
| F H | click left / right stick |
| WASD | left stick |
| I J K L | right stick (camera) |
| arrows | D-pad |
| Shift with an arrow | the same direction on the right stick |
| = - | + - |
| Space | shake |

That is what `assets/env.txt` bakes in. Without it the default is Nintendo's layout, which is J K U I for A B X Y and no
camera at all; [keyboard-layout.md](keyboard-layout.md) has the map format, so a layout of your own is one line.

## Building

You need the game's dump (v0 1.0.0 for this profile; a folder or a NUP), Xcode 27.2, Homebrew, an arm64 Python 3.12 and the
toolchain nxnative lists. Then:

```sh
DUMP="/path/to/your/dump" scripts/build.sh
```

The first build is the long one, and this branch cannot avoid it: the shader chain moved from `cb2e91c138e3` to
`4b57309b93d2`, so `main`'s translated libraries do not apply and all 11,560 shaders are translated again, about 46 minutes
of it. Later builds of this branch are the short ones, about 5 minutes.

The script packs the Mac host and shaders, bakes in the settings and the keyboard map, puts the icon in, signs the two
executables and removes the bundle seal so macOS does not re-hash the 22 GB RomFS before the first launch.

The build makes the pipeline archive for this Mac's GPU, so the app's first start opens it instead of compiling its way
through the course, and by default the pipelines the archive leaves to the device as well (`--prebake`). That adds an hour
or more on top of the shader build here, and it is unmeasured on this branch. The archive is for one GPU, so an app built
here still builds its own bases on another Mac. `GPU=none` skips it, which is what the first builds of this port did, and
`--no-prebake` keeps the archive but drops the second half. Expect the app to grow: the archive this game built for itself
at runtime was about 1.5 GB.

`DUMP` has no default on purpose: it is your path, never the repository one. `OUT` and `WORK` default to `~/Documents`, and
all of them can come from `scripts/local.conf`, which is not tracked. `DM_GUEST_FILE` needs 4 GB free on the temp volume;
without it the game falls back to anonymous memory and the footprint climbs to 8 GB.

## Running

```sh
scripts/play.sh
```

Double-click the app, or run the script if you want a terminal. The host keys its save, its pipeline cache and its temp files
by title ID, in `~/Library/Application Support/nxnative/0400C3F00006E000/`; the log is at
`~/Library/Logs/nxnative/0400C3F00006E000.log`.

## Measurements

[PERFORMANCE.md](PERFORMANCE.md) is `main`'s, and it stays there as the reference for what the game did before this branch, not
as a claim about it. Three runs would replace it:

1. One warm-cache race: frame rate, dropped frames of 300, footprint, and the scene width the log reports.
2. The same race at render scale 1.0 and at 0.75.
3. `DM_GUEST_FILE_CPU_UP=0`, which turns the CPU upload gate off, to see whether upstream's buffer path is enough.

Until then this page states no numbers for this branch.

## Where this came from

Three builds on `main`, two weeks, and then this refresh.

**The first, early November 2026.** A fork of plumber-racer-2, itself a port of nxnative to this game. It carried the memory
work that first got Mario Kart World running on an 8 GB laptop: the guest memory in a file mapping, texture levels dropped
to save space, tiles released once uploaded, and a cap on how much memory the game could map. 40 to 57 fps, 4.48 GB.

**The second, a week later.** 3.7 to 4.0 GB, 0 to 10 dropped frames of 300 on a warm course, a bundled pipeline archive,
and the keyboard map, the texture gate and the profile work. It reported 60 fps in races, which was true in a narrow sense:
when frames ran long the game stretched its own clock, so the counter held while the world slowed.

**The third.** nxnative main, which carries `DM_GUEST_FILE` and the host frame step for this game, plus the keyboard map, the
texture gate, the icon, the 8 GB profile keys and `DM_FPS_HOLD=off`. 1.000 real speed, about 52 fps in a race and 57.5 in
free roam, 4.4 GB.

**This branch** is the fourth: the same port on 245 newer commits of the engine, plus the render scale stub. It exists to be
measured, not to be quoted.

## Credits

The engine is [nxnative](https://github.com/seedds/nxnative) by seedds, which builds on
[plumber-racer-2](https://github.com/cheemu21/plumber-racer-2), whose Mario Kart World bring-up and memory work this build
started from. The render scale stub is plumber-racer-2's find, re-ported here. The keyboard map (sent upstream as
[PR #1535](https://github.com/seedds/nxnative/pull/1535)), the texture upload gate, the profile changes and the measurements
on `main` are ours. Ryujinx, LibHac, SPIRV-Cross and MacNativeGames are in that stack too.

No game files, no keys, no built application. The project is not affiliated with Nintendo.
