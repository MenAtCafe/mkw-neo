# Performance

Everything here was measured on one machine: a MacBook Neo, Apple A18 Pro (2 performance and 4 efficiency cores, 6-core
GPU), 8 GB of unified memory, macOS 27.2. 1080p, upscaled into the window, handheld mode. No other apps fighting for memory.

The game sets its own present interval, flipping between 1 and 2 when a frame is late, which is a 60 fps target that drops
to 30 for a moment. That is why a dropped-frame count matters more here than an average frame rate: the average hides the
flip, the drops do not.

## Current build, Koopa Troopa Beach, Grand Prix

First visit, with the bundled pipeline archive:

| Window | Dropped | p99 | Footprint |
|---|---|---|---|
| first 300 frames (startup) | 23 | 116.70 ms | 3.0 GB |
| to frame 600 | 4 | 33.35 ms | 3.2 GB |
| to frame 900 | **0** | **16.67 ms** | 3.1 GB |
| to frame 1200 | 8 | 33.34 ms | 3.2 GB |

Second visit, cache warm:

| Window | Dropped | p99 | Footprint |
|---|---|---|---|
| frame 4800 | 1 | 33.34 ms | 3732 MiB |
| frame 5100 | 1 | 33.34 ms | 3738 MiB |
| frame 5700 | **0** | 33.34 ms | 3786 MiB |
| frame 6000 | 2 | 33.34 ms | 3771 MiB |
| peak | | | 3913 MiB |

Worst frame of a three minute session: **26.4 ms**. Pipelines compiled during the session: **81** (60 on the first visit).
Crashes: 0.

## The same course on the previous build

From the build this repository replaces, same machine, same mode:

| Measured | Previous build | This build |
|---|---|---|
| First visit, dropped | 243 of 300 | 23, then 0 |
| Pipelines, first visit | 5,292 | 60 |
| Time spent compiling | 31.19 s | 0.0 s |
| Second visit, dropped | 2 of 300 | 0 to 4 of 300 |
| Peak footprint | 4.48 GB | 3.91 GB |
| Locked 60 window | not recorded | yes, 16.67 ms p99 |

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
