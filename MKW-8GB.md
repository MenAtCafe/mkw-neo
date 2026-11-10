# Mario Kart World on an 8 GB Mac, ported onto current main

This branch is nxnative ` + main + ` with the patches a 1.0.0 dump needs on an Apple A18 Pro with 8 GB: the keyboard map as data,
the CPU upload gate, our squircle and the profile keys below. ` + DM_GUEST_FILE + ` and the frame-step fix are upstream now.

## What is added here

| Patch | Where |
|---|---|
| ` + DM_KBD_MAP + ` (key map as data, over the default layout) | ` + dm/host/pad_kbd.h + `, ` + front_mac.m + `, 44 checks in ` + t_pad_kbd.c + ` |
| CPU upload gate: a file-backed guest block stays off the no-copy upload path | ` + hle_svc.c + `, one line in ` + pkg_upload_ + ` |
| Squircle icon | ` + MAC_ICON + ` in ` + pack_app.py + `, ` + assets/AppIcon.png + ` |
| Profile: ` + mem_map_limit on + `, ` + op_mode handheld + ` | ` + dm/games/0400C3F00006E000/game.tsv + ` |
| Settings and build script | ` + assets/env.txt + `, ` + scripts/build.sh + ` |

## Building

```sh
DUMP=/path/to/dump scripts/build.sh
```

A v0 1.0.0 dump goes straight in: the profile registers exactly that build. The build took 46 minutes here, of which 23 were
11,560 shaders; the chain had moved, so nothing cached.

## Measured

| Session | Frame rate | Dropped of 300 | p99 | Footprint |
|---|---|---|---|---|
| Old build, end of session | 22 to 38 fps, mostly 30 | 25, 84, 130 | 100 to 133 ms | 4.2 GB |
| This build, 1080p, MetalFX, warm | 38 fps mean, 74% of windows at 30 | 0 to 2 | 33.34 ms | 4.1 GB |
| This build, ` + DM_RENDER_SCALE=0.75 + ` | worse: more interval flips | 33 to 65 | 50 to 66 ms | 4.2 GB |

Distribution over 19 windows of the 1080p session: **0% at 60 fps, 74% at 30, 26% in between**, 93 of 5,668 frames
dropped (1.6%), mean 38 fps. The game toggles its own present interval between 1 and 2 (115 times in one session), so it probes
for 60, fails, and settles at 30.

Memory with the gate and ` + DM_GUEST_FILE=1 + `: guest block 4.06 GB in files, footprint 4.1 to 4.2 GB, about 0.94 GB dirty in
memory. That is the shape this game wants on 8 GB.

## What was tried and did not help

- **` + DM_RENDER_SCALE=0.75 + `**: 21 pipelines rebuilt for the resized targets, present upscaling still reports 1920x1080 →
  2816x1584, the game's own dynamic resolution fights the change, and interval flips rose from 115 to 165. Reverted.
- **File backing off** (on the previous branch): guest memory went to 6-7 GB anonymous, macOS swapped, startup crawled.
  File backing stays.
- **Menu idle to warm pipelines**: builds nothing, heats the machine, and costs the next session its headroom.

## Where it stands

30 fps steady at 1080p, upscaled by MetalFX to 1584p, 0 to 2 dropped frames per 300, 4.1 GB, and 60 in short bursts on light
stretches. Holding 60 would take fewer pixels than the game is willing to render, or a bigger GPU: at 0.75 the engine fights
the change instead of gaining from it.

At 110 °C the machine throttles (CPU energy 1.08 W for 22 fps) and the result is the same game 10 fps slower. Cool, charged,
hard surface.
