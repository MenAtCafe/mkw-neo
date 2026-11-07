# mkw-neo-next

A workbench for an 8 GB Mac build of Mario Kart World: current nxnative main, the keyboard map from
[mkw-neo](https://github.com/MenAtCafe/mkw-neo), and a port of the soft-texture memory saving that the older fork used to fit
this game on 8 GB of memory.

Nothing here has been packed into an app or played yet. The host builds; the game has not run on it.

## Where this stands

| Piece | State |
|---|---|
| nxnative main | current, branch `next` |
| Keyboard map (`DM_KBD_MAP`) | ported, 44 tests pass, [open upstream as #1535](https://github.com/seedds/nxnative/pull/1535) |
| Profile fitted to a 1.0.0 dump | done, three modules and the RomFS marker the dump has |
| `mem_map_limit on`, `op_mode handheld` | done |
| `tex_soft` (texture memory) | ported, host builds |
| `mem_file` (guest memory in a file) | **not ported** |
| `tex_release` (placement tile pages) | **not ported** |
| App built from this tree | **not yet** |
| Race played on 8 GB | **not yet** |

## What the soft-texture port does

A large block-compressed texture the game loads from its files is kept without its finest mip level. The host texture starts
at level 1, which is half the width and height, and the pages only level 0 held are given back to the system once the upload
has lived a while. Sampling normalised coordinates still lands in the right place, as if nothing had been dropped.

On the iPhone this took a game's wrapped texture pools from 3.7 GB to 851 MB, and a whole cup ran at 3.9 GB. That is the
saving this build is after.

| File | What it adds |
|---|---|
| `dm/games/game.py` | the `tex_soft` key, emitted as `DM_GAME_TEX_SOFT` |
| `dm/gfx/nvn/nvn_dirty.c` | `nvn_dirty_release`: whole pages still protected since their upload go back with `MADV_FREE_REUSABLE`, and a page taken back is the game's again before it writes |
| `dm/gfx/nvn/nvn_mtl.m` | `tex_soft`, `tex_soft_level`, `soft_harden`, `soft_sweep`, `mtl_pool_wrapped`, the level shift in all three upload loops, and the copy and view paths |
| `dm/games/0400C3F00006E000/game.tsv` | `tex_soft on` beside the two memory keys |

Two switches can turn it off for a comparison run: `DM_NVN_TEX_SOFT=0` and removing the profile key.

## What is still open

`mem_file` and `tex_release` are not here. `mem_file` keeps guest memory in a file mapping, out of the footprint, which
matters most on iOS; `tex_release` follows a placement sparse texture's tiles. Either may be needed before this fits 8 GB.

Nothing in the texture path has been exercised by a game yet. The failure to look for is a texture sampled one level off or a
page returned while the game still reads it, which shows as corruption during play rather than at build time.

## Building

From a unpacked dump folder (base/ and updates/<version>/, no keys needed):

```sh
python3 scripts/build_ipa_from_nsp.py "<your dump folder>" --platform mac-app \
    -o "$HOME/Documents/Switch 2 Files/MKW-next.app" \
    --work-dir "$HOME/Documents/DeepSeek R&D/mkw-next-build"
```

The build rewrites, splits and compiles the game's shaders first, which is most of its two hours. The host is built by the
same command.

## Running it without touching your cache

The host keys its save, its pipeline cache and its temporary files by title ID, so a second build of this game would share
them with the first. Redirect them for the new app:

```sh
DATA="$HOME/Documents/mkw-next-data"
"$HOME/Documents/Switch 2 Files/MKW-next.app/Contents/MacOS/nxnative" \
    DM_ROOT="$DATA" DM_SAVE="$DATA/save" DM_TEMP="$DATA/temp" \
    DM_PSO_ARCHIVE="$DATA/pso_archive" DM_PSO_USER="$DATA/pso_user.tsv"
```

The first race will be slow: a fresh pipeline cache has nothing in it. That is expected, and it is also when the footprint
number to watch is printed.

## Not in here

No game files, no keys, no built app. Nothing from Nintendo.
