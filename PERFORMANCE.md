# Performance

Apple A18 Pro, 8 GB, macOS 27.2. Dump v0 1.0.0. Build: nxnative main `dedc9391c30b`, our patches on top. Settings:
`DM_GUEST_FILE=1`, `op_mode handheld` (1080p), `mem_map_limit on`, MetalFX upscaling, no render scale.

## The configuration that ships

Default frame step (profile `fps_target 60`), one long session:

| Metric | Value |
|---|---|
| Frames dropped | 3 to 8 of 300 |
| p99 | 33.34 ms |
| Mean frame rate | 37 to 38 fps |
| Interval split | 686 frames at 1 vsync, 1114 at 2 |
| Game time | 49.17 s in 49.73 s, 0.989 of real time |
| Footprint | 4.4 GB |
| Guest block | 4.06 GB in files, about 0.9 GB dirty |

`0.989 of real time` is the point of this build: frames that run long cost a frame, they do not slow the game down.

## The alternates

| Setting | Frame rate | Dropped of 300 | p99 | Catch |
|---|---|---|---|---|
| Default 60 | 37 fps mean, brief 60 | 3 to 8 | 33 ms | toggles between 1 and 2 vsyncs |
| Cap 30 | 30 steady | 0 to 2 | 33 ms | startup and loading take about twice as long |
| `DM_FPS_TARGET=0` | 30, slow motion | 163 of 4,737 | 50 ms | the game stretches time |

The 30 cap is the calmest thing measured. The `0` setting is the old build's behaviour: the counter looks better, the
game runs slower than real time, and the tail is worse.

## Against the previous build

| | Previous build | This one |
|---|---|---|
| Dropped of 300, end of session | 84, 25, 130 | 3 to 8 |
| p99 | 100 to 133 ms | 33 ms |
| Frame step | the game's own | the host's, 60 |
| Game speed | stretched when frames ran long | 0.989 of real time |
| Profile | no `fps_target` | `fps_target 60` and `MATCH_FRAME_STEP` |

The old numbers were higher and less honest. A racing game that runs at 0.989 speed is a better racing game than one that
prints 60 while the world wades.

## What was tried and did not work

- **`DM_RENDER_SCALE=0.75`**: 33 to 65 dropped, p99 50 to 66 ms, interval flips up from 115 to 165, and MetalFX still
  presented 1920x1080 to 2816x1584. The game's own dynamic resolution fights a scaled view. Reverted.
- **`DM_PRESENT_INTERVAL=display`**: the cut applied, the distribution did not move. 0 of 18 windows at 60, more drops.
- **`DM_FPS_TARGET=0`**: see the table above, worse on every line.
- **Warming the cache by idling in the menu for two hours**: builds nothing, heats the machine, and costs the next
  session its headroom. Course pipelines build by playing courses.

## The shape of the game on this GPU

Koopa Troopa Beach, warmed cache: 0 to 8 dropped of 300, p99 33 ms, GPU 7 to 12 ms a frame, 4.4 GB. The GPU is not the
wall at that track. The wall is that the game runs its own resolution-and-pacing logic and settles at 30 when it decides it
cannot hold 60, which on this GPU it mostly cannot.

At 110 °C, the machine throttles: CPU energy 1.08 W for 22 fps, the game drops its dynamic resolution, and the picture
goes soft on top of the frame loss. Cool it, charge it, keep it on a hard surface.
