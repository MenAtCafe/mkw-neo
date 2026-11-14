#!/bin/sh
# Build the Mac app on current nxnative main: our keyboard map, the 8 GB settings and our icon are built in.
#   DUMP=/path/to/dump scripts/build.sh [extra options]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/scripts/local.conf" ] && . "$ROOT/scripts/local.conf"
PY="${PY:-python3}"
DUMP="${DUMP:-}"
OUT="${OUT:-$HOME/Documents/Mario Kart World.app}"
WORK="${WORK:-$HOME/Documents/mkw-build}"
ENVFILE="${ENVFILE:-$ROOT/assets/env.txt}"
ICON="${ICON:-$ROOT/assets/AppIcon.png}"
PACKAGE="${PACKAGE:-}"
GPU="${GPU:-}"   # the pipeline archive's GPU, default this Mac's; none skips the archive
[ -n "$DUMP" ] || { echo "set DUMP= to your game dump, or put it in scripts/local.conf" >&2; exit 1; }
[ -e "$DUMP" ] || { echo "no game at $DUMP" >&2; exit 1; }
# The console goes into the work folder too, so a build without a terminal (a script, a scheduler) can be watched
# while it runs: tail -f "$WORK/build.log". A terminal keeps the live output as before.
if [ ! -t 1 ]; then mkdir -p "$WORK"; echo "build log: $WORK/build.log" >&2; exec > "$WORK/build.log" 2>&1; fi
export DOTNET_ROOT="${DOTNET_ROOT:-/opt/homebrew/opt/dotnet/libexec}"
export MAC_ICON="$ICON"   # pack_app.py turns it into AppIcon.icns before the app is signed
echo "building $OUT"
echo "  dump     $DUMP"
echo "  work     $WORK"
echo "  settings $ENVFILE"
echo "  icon     $ICON"
echo "  base     ${GPU:-this machine} (GPU=none skips the pipeline archive)"
set -- "$DUMP" --platform mac-app -o "$OUT" --work-dir "$WORK" --env-file "$ENVFILE" "$@"
# The pipeline archive (dm/gfx/tools/pso_offline.py through metal-tt) for this Mac's GPU, which the app carries and its first start
# opens instead of building the bases itself. It is a long step, and it is skipped by GPU=none, which is what the first builds of
# this port used. --no-prebake drops the second half, the pipelines pso_offline.py leaves to the device.
[ -n "$GPU" ] && set -- "$@" --gpu "$GPU"
[ -n "$PACKAGE" ] && set -- "$@" -p "$PACKAGE"
status=0
"$PY" "$ROOT/scripts/build_ipa_from_nsp.py" "$@" || status=$?   # set -e would end the script here, before the icon and the seal
if [ -d "$OUT" ]; then
    codesign --force --sign - "$OUT/Contents/MacOS/dmhost" >/dev/null 2>&1 || true
    codesign --force --sign - "$OUT/Contents/MacOS/nxnative" >/dev/null 2>&1 || true
    rm -rf "$OUT/Contents/_CodeSignature"
    xattr -cr "$OUT" 2>/dev/null || true
fi
exit $status
