# This branch: the refresh onto current nxnative main

main is the build that was measured. This branch is the same port on a newer engine: nxnative main
`4b10c73f` (14 November 2026), 245 commits past the `c4ffb9df` main was built on. Nothing has been run
or measured here yet. What follows is what changed underneath and what to measure first.

## What upstream does now, so this branch carries none of it

- **Guest memory in files.** `DM_GUEST_FILE` with `DM_GUEST_FILE_CHUNK` (1 GB by default, at least 64 MB, at
  most 1024 files), hole punching when the game gives memory back, a free-space floor that stops the game
  before the disk fills, and a dirty-page scan. The last build carried its own single-file version.
- **Recycled render-target memory.** The game's dynamic resolution resizes its targets nearly every frame, and
  upstream now hands those heaps to the next texture of a matching size instead of making new ones. Upstream
  measured 1.8 GB added per 300 frames before and 0.34 GB after.
- **Frame-deadline declarations for the acquire, queue replay and encode threads.** On an iPhone this is what
  tells the scheduler each thread's deadline; before, only the presenting thread declared one.
- **The frame step, placed by the function's fingerprint**, covering v0 and 1.8.0. This port used to carry a
  stub keyed by build ID, which only ever applied to v0.
- **Segment timestamps with the GPU's idle time between command buffers left out**, now the default for every
  game. This is what plumber-racer-2 carries as `seg_gap_before`; it landed upstream as `seg_idle_before`.

## What it carries unchanged

The keyboard map (`DM_KBD_MAP`, `pad_kbd.h`), the icon (`MAC_ICON`), the 8 GB profile keys, the CPU
upload gate for a file-backed guest block, the build and play scripts, the settings in `assets/env.txt`, and
the write-up.

## What came from plumber-racer-2

The render scale stub, and nothing else. It multiplies the six `For3D` entries of the game's resolution table
by `DM_RENDER_SCALE` and leaves the screen entries alone, so the final picture stays 1920x1080 and the HUD stays
sharp while the 3D is smaller. It is in `dm/games/0400C3F00006E000/patches.py` and the game note has the detail.

It is registered under `STUBS` rather than `FRAME_STEP` on purpose. `patch_nso.py` only looks for a
function-matched frame step when the build is not in `FRAME_STEP`, so registering one for v0 would have
silently replaced upstream's stub and dropped 1.8.0. `STUBS` now gets the frame step state page's offset and
honours `ctx.render_scale`, which is what puts `RENDER_SCALE 1` in the fixups table and makes the launcher
offer the setting.

## What was not taken, and why

- **`mem_file` and its 1 GB chunking.** The same idea as `DM_GUEST_FILE`, further behind. Two guest-memory
  implementations in one tree is a trap.
- **The frame step change at `+0xe8`.** It makes the game read the whole frame, present wait included, so every
  late present looks like the game's own slowness. That couples game speed to host pacing. Upstream hands the
  interval to the host instead, and that is what this port measured.
- **The present-rate cap (30, 40, 45, 60).** 40 and 45 fps need a step of 1.33 and 1.5, and the game steps whole
  vsyncs, so the motion is uneven in a way 30 and 60 are not.
- **Screen shape / `DM_ASPECT`.** plumber-racer-2 tried it and left it off, and the finding is worth keeping:
  the fixed 1280x720 pair is both the cameras' aspect and a scale divisor for the 3D buffers and the composite,
  so widening it stretches the 3D and the HUD alike and no value in that table fixes both. A camera stub would.
- **`tex_soft` level 2.** It drops another level from large textures for phones with less memory. The Mac is
  not short.

## What is different for a build of this branch

The game's own dynamic resolution now runs, because segment timestamps are the default. Expect the 3D to be
softer than the 1080p that PERFORMANCE.md describes, and the frame rate to be something else. The launcher also
shows a render scale row it did not show before; 1.0 is the game's own sizes.

## What to measure first, in this order

1. One race, warm cache: frame rate, dropped frames of 300, footprint, and the scene width from the log, with the
   dynamic resolution on.
2. The same race at render scale 1.0 and at 0.75.
3. `DM_GUEST_FILE_CPU_UP=0` in `assets/env.txt`, to see whether upstream's transient source buffer made the CPU
   upload gate unnecessary.

PERFORMANCE.md gets its numbers back when those exist, not before.
