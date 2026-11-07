# mkw-neo-next

A private staging repo for the next Mario Kart World build: current nxnative main, the keyboard map from
mkw-neo, and eventually the low-memory host work and the engine improvements from the Ocarina of Time branch.

Nothing here is built or measured yet. Treat it as a workbench, not a release.

## Where this starts

| Piece | State |
|---|---|
| nxnative main | current, branch `next` off `origin/main` |
| Keyboard map (`DM_KBD_MAP`) | applied, 44 tests pass |
| MKW profile reconciled with the 1.0.0 dump | **not yet** |
| `tex_soft`, `mem_file`, `tex_release` | **not yet**, they are host code in the old fork |
| OoT branch engine work | **not yet**, 46 conflicting files |
| Built and measured on the 8 GB machine | **not yet** |

## What stands in the way, concretely

**The profile does not match the dump.** Upstream's `game.tsv` for this title declares
`modules main subsdk0 subsdk1 sdk` and `romfs_marker Movie/StaffRoll_00.webm`. A 1.0.0 dump has
`main subsdk0 sdk` and the marker `System/Resource/ResourceSizeTable.Product.100.Nin_Ounce_NVN2.rsizetable.zs`.
Until those are reconciled, a build stops at the module list.

**The memory features are code, not settings.** Only `mem_map_limit` and `op_mode` of the six keys are accepted by
current `game.py`. `tex_soft` (texture path, `nvn_mtl.m`), `mem_file` (guest memory, `hle_svc.c` and
`nvn_dirty.c`) and `tex_release` have to be ported onto today's code, then tested on 8 GB hardware. That is the
core of the work, and it is where a mistake shows up as corrupted textures rather than a failed build.

**The OoT branch is a different engine, not a diff.** A trial merge into current main gives 46 conflicting files,
and `dmsh_chain.h` is one of them: the branches sit on different shader chains, so merging means picking one chain
and rebuilding every shader (about 1 h 41 m on this laptop).

## Order of work

1. Reconcile the profile with the 1.0.0 dump, build, measure the footprint. This tells us what upstream's engine
   does on 8 GB before any of our code is involved.
2. Port `tex_soft`, then `mem_file`, one build and one race each.
3. Decide on the OoT engine work only after 1 and 2, and only one change at a time.

## Not in here

No game files, no keys, no built app. Nothing from Nintendo.
