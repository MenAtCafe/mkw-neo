#!/bin/sh
# Build the app: your dump, the icon and settings in assets/, and a pipeline archive made for this Mac's GPU.
#   DUMP="/path/to/dump" scripts/build.sh [extra options]
# Defaults for this machine live in scripts/local.conf (not tracked); every path can also be set as an environment variable.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/scripts/local.conf" ] && . "$ROOT/scripts/local.conf"
PY="${PY:-python3}"
DUMP="${DUMP:-$HOME/Documents/Switch 2 Files/Mario Kart World Rom}"
OUT="${OUT:-$HOME/Documents/Mario Kart World.app}"
WORK="${WORK:-$HOME/Documents/mkw-build}"
ICON="${ICON:-$ROOT/assets/AppIcon.png}"
ENVFILE="${ENVFILE:-$ROOT/assets/env.txt}"
[ -d "$DUMP" ] || { echo "no dump at $DUMP: set DUMP= or add it to scripts/local.conf" >&2; exit 1; }
export DOTNET_ROOT="${DOTNET_ROOT:-/opt/homebrew/opt/dotnet/libexec}"
export MAC_ICON="$ICON"   # pack_app.py turns it into AppIcon.icns before the app is signed, so no second signing pass
echo "building $OUT"
echo "  dump     $DUMP"
echo "  work     $WORK"
echo "  icon     $ICON"
echo "  settings $ENVFILE"
"$PY" "$ROOT/scripts/build_ipa_from_nsp.py" "$DUMP" --platform mac-app -o "$OUT" --work-dir "$WORK" --env-file "$ENVFILE" "$@"
status=$?
if [ "$status" -eq 0 ]; then
    # Sign the two executables and drop the bundle seal. The seal covers every file in Contents, including the 22 GB
    # RomFS, so macOS re-hashes the whole thing before the first launch and shows "Verifying Mario Kart World…" for
    # minutes. The launcher runs the binary directly, which needs the binary's own signature and nothing else.
    codesign --force --sign - "$OUT/Contents/MacOS/dmhost" >/dev/null 2>&1 || true
    codesign --force --sign - "$OUT/Contents/MacOS/nxnative" >/dev/null 2>&1 || true
    rm -rf "$OUT/Contents/_CodeSignature"
    xattr -cr "$OUT" 2>/dev/null || true
fi
exit $status
