# Troubleshooting

## "Verifying Mario Kart World…" hangs for minutes before it launches

The app's signature sealed every file inside the bundle, including the 22 GB RomFS, and macOS re-hashes a sealed bundle
before the first launch. The build now signs the two executables and removes `Contents/_CodeSignature`, so there is no
bundle seal left to verify, so the app opens straight from Finder.

## It crashes a few seconds into the first race with `CRASH sig=10` in `pkg_upload`

Two causes lived here, both in our texture work and both fixed:

1. A copied level offset. `nvn_deswizzle` adds the level's offset itself (`nvn_deswizzle_geom`), so shifting the source
   pointer as well read past the texture into unmapped guest memory.
2. A placement sparse texture read by level offset. Those live 32 GB into a virtual pool and only resolve through the
   4 KB page table, so a level offset bypasses the mapping. `tex_soft` now excludes `nvn_sparse_pool` pools.

If you see `sig=10` again, the backtrace in the log names the function; `docs/agents/symptoms.md` maps it to a cause.

## The road and other large surfaces look like flat plates

`tex_soft` is on. Mario Kart World's terrain shaders read a texture's size to lay out their UVs, so a texture kept one
level down tiles half as often. It is off in the profile. If you turned it on with `DM_NVN_TEX_SOFT=1`, that is what you
are seeing.

## Memory climbs to 8 GB and the Mac starts swapping

`DM_GUEST_FILE` is off. The launcher sets it to 1. With it, the guest memory is a set of unlinked sparse files, out of the
footprint, and the game sits at 3.4 GB. It costs disk: about 8 GB of temp files while it runs.

## Frames of 60 ms with nothing compiling

Packaged textures are reaching the GPU as no-copy buffers over file-backed guest memory. That is the CPU upload gate
missing; see `keep_cpu` in `pkg_upload_` (`dm/gfx/nvn/nvn_mtl.m`).

## The first race stutters on a build with no bundled archive

Expected. Without the app's `Contents/Resources/pso/<gpu>.mtl4a`, pipelines are compiled the first time each is used. The
build makes that archive; `scripts/build.sh` includes it.
