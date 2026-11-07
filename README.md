# Mario Kart World on an 8 GB Mac

Mario Kart World, the Switch 2 game, running natively on a MacBook Neo: Apple A18 Pro, 8 GB of unified memory, macOS 27.2.
There is no emulator here. The game's own ARM64 code runs, Horizon's services are reimplemented under it and NVN2 is
translated to Metal, which is what [nxnative](https://github.com/seedds/nxnative) does.

This repository is that build. It is current nxnative main plus the handful of changes it took to fit this game on a
machine with 8 GB, a keyboard layout made for it, and the measurements that came out of running it for a few hours.

Nothing from the game is in here. No ROM, no keys, no built app. You need your own copy of the game to build it.

## What it does here

| | |
|---|---|
| Render | 1080p, upscaled into the window |
| Footprint | 3.7 to 3.9 GB while racing |
| First visit to a course | 60 pipelines compiled, no stall |
| Second visit, Koopa Troopa Beach | 0 to 4 dropped frames per 300 |
| Best 300-frame window | 300 of 300, p99 16.67 ms |
| Worst frame in a session | 26 ms |

The first visit used to be the painful part. The build now ships a 469.9 MB Metal 4 pipeline archive made for this GPU,
so a course loads with its pipelines already compiled instead of compiling 5,292 of them mid race.

## What this repository adds to nxnative

**The guest memory stays in files** (`DM_GUEST_FILE=1`, set by the launcher). It takes the footprint from 8.2 GB to
3.4 GB on this machine. Upstream has the feature; this build turns it on and gates texture uploads so the GPU does not
choke on it (see below).

**Packaged textures upload on the CPU when the guest memory is in files.** A no-copy Metal buffer over file pages is read
into memory and wired when it enters the residency set, which measured 65 ms of GPU a frame before this gate.

**A keyboard map, `DM_KBD_MAP`,** in `dm/host/pad_kbd.h`: the default layout on the Mac is J K U I for A B X Y and
nothing for the camera, which is unusable without a controller. The map is data, 25 actions, and it is the change we sent
upstream as [PR #1535](https://github.com/seedds/nxnative/pull/1535).

**A profile fitted to a 1.0.0 dump**: three modules and the RomFS marker this dump has, `mem_map_limit on`, handheld mode,
and the shader tables split from this dump rather than another version's.

**`tex_soft`, a port of the old fork's texture softening, off by default.** It is in the tree because it works and it
saves about 0.4 GB, and it is off because Mario Kart World's terrain shaders read a texture's size to lay out their UVs,
so a texture kept one level down tiles half as often and the road turns into flat plates. `DM_NVN_TEX_SOFT=1` turns it on
for a comparison run.

## Building

You need the game's dump (base plus any update, as a folder or a NUP), Xcode 27.2, Homebrew, an arm64 Python 3.12 and the
toolchain nxnative lists. Then:

```sh
scripts/build-next.sh
```

It builds from the dump in `~/Documents/Switch 2 Files/Mario Kart World Rom`, packs the Mac host and shaders, makes the
pipeline archive for this Mac's GPU, puts the icon in, signs the two executables and removes the bundle seal so macOS does
not re-hash the 22 GB RomFS before the first launch. Two hours the first time, most of it shaders.

Override paths with `DUMP=`, `OUT=`, `WORK=`, `ICON=`.

## Running

```sh
scripts/play-next.sh
```

The host keys its save, its pipeline cache and its temp files by title ID, so the launcher points all of them at
`~/Documents/mkw-next-data` to keep them apart from any other build of the same game. It also sets `DM_GUEST_FILE=1`.

Launch it through that script or the `.command` file beside the app, not from Finder or the Dock: the build removes the
bundle seal, and LaunchServices wants it.

## Measurements

[PERFORMANCE.md](PERFORMANCE.md) has the runs behind the numbers above, both visits to Koopa Troopa Beach, the two crashes
that came before it worked, and what each fix was worth.

## Credits

The engine is [nxnative](https://github.com/seedds/nxnative) by seedds, which builds on
[plumber-racer-2](https://github.com/cheemu21/plumber-racer-2), whose Mario Kart World bring-up and memory work this build
started from. Ryujinx, LibHac, SPIRV-Cross and MacNativeGames are in that stack too. The measurements, the keyboard map and
the profile changes are ours.

No game files, no keys, no built application. The project is not affiliated with Nintendo.
