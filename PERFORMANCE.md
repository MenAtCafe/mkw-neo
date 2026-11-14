# Performance

Two builds are measured in this file. The first section is `upstream-refresh`, run on 14 November 2026. Everything from
**The build this file was written for** down is `main`'s build, on the older engine.

## The refresh branch: three runs

Apple A18 Pro, 8 GB, macOS 27.2, dump v0 1.0.0. Build: this branch at `d6f41259`, shader chain `4b57309b93d2`, with the
pipeline archive made for this Mac (`applegpu_g17p`) and carried in the app. Settings are the four in `assets/env.txt`:
`DM_GUEST_FILE=1`, the keyboard map, `DM_PRESENT_UPSCALE=metalfx` and `DM_FPS_HOLD=off`. Mario Bros. Circuit, three runs in
one session: render scale 1.0, then 0.75, then 1.0 again.

| Run | Render scale | Race mean frame | That is | GPU p50 | Dropped of 300 |
|---|---|---|---|---|---|
| First, cold | 1.00 | 36.7 ms | 27.2 fps | 19.8 ms | 229 mean, 262 worst |
| Second | 0.75 | 21.1 ms | 47.5 fps | 12.0 ms | 96 mean, 139 worst |
| Third, warm | 1.00 | 30.8 ms | 32.5 fps | 16.9 ms | 202 mean, 236 worst |

The race is the windows where the 3D is loaded. The menus before and after it run at 60 fps with the GPU at 2 to 6 ms, and
the footprint was 4.1 to 4.6 GB across the three. The app ships with 1.0, the game's own sizes, because the sharper
picture was worth more than the frames to the person playing it; the launcher's Render scale row is left free, so 0.75 is one
setting away.

**Render scale is worth about 15 fps.** 0.75 takes the GPU from 17 to 20 ms down to 12.0, inside the 16.67 ms slot, and
roughly halves the dropped frames. At 1.0 the GPU is over budget before the CPU does anything.

**Two runs at the same setting differ by 5 fps.** The third run beat the first at the same 1.0, which is warm caches: fewer
pipelines built during the race. Anything under about 5 fps here is noise.

**The limiter is the CPU now.** In the 0.75 run the queue replay thread, which turns the game's NVN calls into Metal, took
12.73 ms a frame at 1.32 GHz while the GPU took 12.0. At 1.0 it took 15.99 ms at 1.53 GHz. Both sit near the 16.67 ms slot,
so a render scale below 0.75 has little left to win.

**What moves is the clock, not the code.** The same thread took 3.72 ms at 2.77 GHz in the menus after the race. During the
race it sits at 1.3 to 1.5 GHz with about 1 W of CPU energy, which is this laptop's power and heat ceiling.

**The pipeline archive works but is not complete.** It opened in 3.8 s, 775.1 MB, and held the bases of every probed shader
pair (16 of 16). During the race the game still asked for more: 44 bases over 16.3 s of thread time on the 1.0 run, 25 over
6.9 s on the 0.75 run. That is the empty `pso_manifest.tsv`. One `[RED]` line appeared once, "swizzled texture storage is
not in a memory pool; falling back to the CPU".

### The stutters

The 0.75 race had 228 frames over 16.7 ms. Of those, 23 involved a pipeline or a shader library and 49 had more than a
megabyte of texture uploads, so compiles are no longer the main cause. The worst frames are not NVN at all:

```
frame 3091 (90.91 s) whole frame 258.4 ms, submit+present 13.2 ms, GPU 10.6 ms;
new pipelines 0 + shader libraries 0; texture uploads 4 first + 0 re-uploads, 10.7 MB / 4.4 ms
```

258 ms with 13 ms of submit and 11 ms of GPU accounted for. Frames 2850, 3840 and 3850 have the same shape, 215 to 247 ms
with double-digit submit and GPU times. Whatever that is, it is in the game's own threads or the host around them, and it
is open.

### What is not measured on this branch

- A second course, so whether Mario Bros. Circuit is typical is unknown.
- Render scale 0.5, which would say whether the replay thread is really the floor.
- What those 200 ms stalls are.

## The build this file was written for

Apple A18 Pro, 8 GB, macOS 27.2. Dump v0 1.0.0. Build: nxnative main `cb2e91c138e3` plus the patches in the README.
Settings: `DM_GUEST_FILE=1`, `op_mode handheld` (1080p), `mem_map_limit on`, `DM_PRESENT_UPSCALE=metalfx`, `DM_FPS_HOLD=off`.

## Words used here

**Frame time.** How long one picture took, in milliseconds. At 60 fps a frame has 16.67 ms; at 30 fps, 33.34 ms. Every
number in this file is frame time, dropped frames or memory, because those are what you feel.

**Dropped frame.** A frame that missed its slot: the picture on screen lingered while the new one was late. Three dropped
frames in a second looks like a small skip, thirty looks like a slideshow. A window is 300 frames, five seconds at 60 Hz.

**p99.** The 99th percentile, the slowest one frame in a hundred. It matters because an average hides stutter: a run can
average 16 ms and still have every hundredth frame take 80 ms, which is the hitch you notice. p99 16.67 ms means 99 frames
of 100 hit 60 fps; p99 33.34 ms means the slow ones took two refreshes.

**Footprint.** The process's own memory as macOS counts it for an app, not including the game's files on disk. This laptop
has 8 GB shared with everything else, so the footprint is what decides whether the machine swaps.

**Present interval, and holding.** How many display refreshes each picture waits for: 1 is 60 fps, 2 is 30. This game sets
the interval itself. `DM_FPS_HOLD` decides whether a late frame may take a second vsync; with it on, a slow frame holds and
the game runs 30 for a while, which is where the 30/60 flipping came from. With it off, the frame is dropped and the next
one goes out on time.

**Frame step.** How much game time one frame advances. The profile gives this game `fps_target 60` and a function-matched
stub, so the game steps by the host's clock instead of stretching its own when it is late. This is why game speed reads
1.000 here and read 0.989 on the previous build.

**Pipeline.** A shader plus every setting it runs with: blending, depth, vertex layout, what it draws into. Thousands of
combinations exist and each has to be built before first use, which is why a new course hitches.

**Pipeline cache, warm and cold.** Built pipelines are saved in `pso_user.tsv` under the title's Application Support
folder, so the next run loads them instead of building again. The cache is keyed by the shader translation chain: it
survives a rebuild of the app, and stops matching when the chain moves. This build ships no bundled archive (`--gpu none`).

**RomFS.** The game's data, 21.7 GB of levels, textures, audio and models, packed as one file inside the app.

**Guest memory.** The memory the game thinks it has. The host lends it, and `DM_GUEST_FILE` decides where it physically
lives: anonymous pages, or sparse files that stay out of the footprint.

## What counts as a first visit

- **Warm cache.** The area has been opened before, so its pipelines are in `pso_user.tsv`. This is the ordinary case, and
  the numbers in "The configuration that ships" below.
- **Cold cache.** A new area, a new course or a moved chain. Its pipelines compile while you play: 29 to 326 during a
  session here, each one a hitch.
- **First launch on a new chain.** The app compiles its pipelines before the first frame behind a progress screen, about an
  hour on this machine for 33,190 pairs on the previous title; this game uses far fewer.

## The configuration that ships

Koopa Troopa Beach, warm cache, one long session:

| Metric | Value |
|---|---|
| Frames dropped | 10 to 35 of 300 |
| p99 | 33.34 ms |
| Mean frame rate | about 52 fps |
| Vsync split | 1800 frames at 1, 0 at 2 |
| Game time | 1.000 of real time |
| Footprint | 4.4 GB |
| Guest block | 4.06 GB in files, about 0.9 GB dirty in memory |

Free roam, after the area had built its pipelines (29 of them during the session): **57.5 fps**, 10 dropped of 300,
p99 33.34 ms, 4.3 GB. The opening windows of a new area drop 78 to 95 of 300 while those pipelines compile.

## The alternates

| Setting | Frame rate | Dropped of 300 | p99 | Catch |
|---|---|---|---|---|
| Hold on (upstream default) | 37 to 38 fps, a third of frames at 30 | 1 to 3% | 33 ms | the 30/60 flipping |
| **Hold off (ships)** | **50.7 to 57.5 fps, all one vsync** | **9.5%** | **33 ms** | judder instead of 30 fps stretches |
| Cap 30 | 29 to 30 steady, all 2 vsyncs | 70 of 4,175 (1.7%) | 33 ms | startup and loading take twice as long |
| `DM_FPS_TARGET=0` | 30, slow motion | 163 of 4,737 | 50 ms | the game stretches time again |

In the hand, the 30 cap is the smoothest of the three: every frame gets 33.34 ms against about 10 ms of GPU work, so
none arrive late, the interval never flips, and the game's dynamic resolution sits at the top of its range. 52 fps with
9.5% irregular drops reads as stutter even though it is more pictures. Film at 24 fps is smooth for the same reason.

Holding on keeps more frames but spends a third of the session at 30. Holding off pays in dropped frames, which in a
racing game reads as judder rather than as stalling. The cap at 30 is the calm option.

## What each change was worth

| Change | Worth |
|---|---|
| Host frame step, `fps_target 60` (`7d8dcdf` upstream) | game time from 0.989 to 1.000, no slow motion |
| `DM_FPS_HOLD=off` | 38 fps with 30 fps stretches to 52 fps at one vsync, for 9.5% dropped instead of 1 to 3% |
| `DM_GUEST_FILE=1` | footprint from 8 to 9 GB down to 4.4, and startup that finishes instead of crawling |
| CPU upload gate | removed the tens of milliseconds a frame from wiring file pages into the residency set |
| Keyboard map | the game is playable without a controller at all |
| `DM_RENDER_SCALE=0.75` | nothing: 33 to 65 dropped, worse |
| Bundled pipeline archive | not built for this branch; it would remove the 78 to 95 frame first-visit window, at an hour of build |

## Against the previous build

| | Previous build | This one |
|---|---|---|
| Dropped of 300, end of session | 84, 25, 130 | 10 to 35 |
| p99 | 100 to 133 ms | 33 ms |
| Frame step | the game's own | the host's, 60 |
| Game speed | stretched when frames ran long | 1.000 of real time |
| Profile | no `fps_target` | `fps_target 60` and `MATCH_FRAME_STEP` |
| Footprint | 3.7 to 4.0 GB | 4.1 to 4.5 GB |

The old numbers were higher and less honest. A racing game that runs at real speed is a better racing game than one that
prints 60 while the world wades. The footprint grew because this build renders 1080p with MetalFX instead of a smaller
picture.

## What was tried and did not work

- **`DM_RENDER_SCALE=0.75`**: 33 to 65 dropped, p99 50 to 66 ms, interval flips up from 115 to 165, and MetalFX still
  presented 1920x1080 to 2816x1584. The game's own dynamic resolution fights a scaled view. Reverted.
- **`DM_PRESENT_INTERVAL=display`**: the cut applied, the distribution did not move. 0 of 18 windows at 60, more drops.
- **`DM_FPS_TARGET=0`**: see the table above, worse on every line.

## What is not measured here

- A bundled pipeline archive on this branch. The cost would be an hour of build; the gain would be the first-visit window.
- Grand Prix and online play, and any course other than Koopa Troopa Beach.
- A machine other than this one, or a different dump version.
- Sustained play past about twenty minutes, where heat starts to matter more than any setting.

## Heat

At 110 °C the machine throttles: CPU energy 1.08 W for 22 fps, and the game drops its dynamic resolution on top, so the
picture goes soft as well as slow. Charged, hard surface, short sessions, and let it cool closed between them.
