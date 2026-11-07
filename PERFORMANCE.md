# Performance

Everything here was measured on one machine: a MacBook Neo, Apple A18 Pro (2 performance and 4 efficiency cores, 6-core
GPU), 8 GB of unified memory, macOS 27.2. 1080p, upscaled into the window, handheld mode. No other apps fighting for memory.

The game sets its own present interval, flipping between 1 and 2 when a frame is late, which is a 60 fps target that drops
to 30 for a moment. That is why a dropped-frame count matters more here than an average frame rate: the average hides the
flip, the drops do not.

## What counts as a first visit

Two kinds of run are below, and they are not the same thing:

- **Cache warm.** The course has been opened before, so its pipelines are in the archive. This is the ordinary case after
  a few minutes of play, and the second Koopa Troopa Beach table is it.
- **Cache cold.** A course never opened before on a machine that has never played it. We have not measured that, and none
  of the figures here should be quoted as if we had. Even the "first visit" runs below happened after earlier roaming and
  testing on the same install, so some of their pipelines were already there.

The old build's 5,292 pipelines and 31.19 s of compiling did come from a genuinely empty cache, which is why that
comparison is still worth making.

## Koopa Troopa Beach, Grand Prix, cache partly warm

First run on the course, after earlier play on the same install:

| Window | Dropped | p99 | Footprint |
|---|---|---|---|
| first 300 frames (startup) | 23 | 116.70 ms | 3.0 GB |
| to frame 600 | 4 | 33.35 ms | 3.2 GB |
| to frame 900 | **0** | **16.67 ms** | 3.1 GB |
| to frame 1200 | 8 | 33.34 ms | 3.2 GB |

Second run, cache warm:

| Window | Dropped | p99 | Footprint |
|---|---|---|---|
| frame 4800 | 1 | 33.34 ms | 3732 MiB |
| frame 5100 | 1 | 33.34 ms | 3738 MiB |
| frame 5700 | **0** | 33.34 ms | 3786 MiB |
| frame 6000 | 2 | 33.34 ms | 3771 MiB |
| peak | | | 3913 MiB |

Worst frame of a three minute session: **26.4 ms**. Pipelines compiled during the session: **81**, of which 60 were
during the first run. Crashes: 0.

Neither table has a window with everything at 16.67 ms, and it would be wrong to call the frame rate locked. Most frames hit
it, a handful per 300 do not, and the game itself drops to a 30 fps interval for a moment when one is late.

## The same course on the previous build

From the build this repository replaces, same machine, same mode:

| Measured | Previous build | This build |
|---|---|---|
| First visit, dropped | 243 of 300 | 23, then 0 |
| Pipelines, first visit | 5,292 | 60 |
| Time spent compiling | 31.19 s | 0.0 s |
| Second visit, dropped | 2 of 300 | 0 to 4 of 300 |
| Peak footprint | 4.48 GB | 3.91 GB |
| Best window | not recorded | 300 of 300, p99 16.67 ms |

## A Grand Prix of new courses, one session

Four courses played for the first time in a row, Peach Beach and the three after it, on an install that had already played
other courses, so the archive was warm for the cup but not for these tracks:

| Measured | Value |
|---|---|
| Pipelines compiled, whole session | 175 |
| Dropped per 300 frames after the opening window | 0 to 10 |
| Opening window (the cup loading) | 34 dropped of 300 |
| Worst frame of the session | 44.5 ms |
| Peak footprint | 4.0 GB |
| Crashes | 0 |

So the first-visit tax is real and small now. Each new course costs a handful of pipelines and a visible hitch, then the
frames settle at 0 to 10 dropped per 300, which is a game you can play rather than a slideshow. The old build compiled
5,292 pipelines on a single first visit and dropped 243 frames of 300 doing it.

## What each change was worth

**Guest memory in files (`DM_GUEST_FILE=1`)**: 8.2 GB to 3.4 GB in free roam, flat instead of climbing as the world
streams in. Without it the footprint grew to 8.2 GB in about three minutes and the machine was swapping.

**The CPU upload gate**: with the files on and no gate, the GPU took 57 to 67 ms a frame, all of it waiting, because every
packaged texture became a no-copy buffer over file pages that the driver kept wiring. With the gate, 18 to 25 ms, and the
dropped-frame count fell from 299 of 300 to 0 to 4.

**Turning `tex_soft` off**: it saved 0.4 GB (3.85 to 3.45 GB) and cost the picture. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

**The bundled pipeline archive**: the single biggest change in feel. It is made at build time for this GPU, 469.9 MB, and
holds the bases of every shader pair. A first visit compiles 60 pipelines instead of 5,292.

## What is not measured here

Other courses, two-player, and long free roam sessions. Koopa Troopa Beach is used because the previous build has numbers
for it, which makes the comparison honest rather than flattering.
