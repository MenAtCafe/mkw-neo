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
[ -n "$DUMP" ] || { echo "set DUMP= to your game dump, or put it in scripts/local.conf" >&2; exit 1; }
[ -e "$DUMP" ] || { echo "no game at $DUMP" >&2; exit 1; }
export DOTNET_ROOT="${DOTNET_ROOT:-/opt/homebrew/opt/dotnet/libexec}"
export MAC_ICON="$ICON"   # pack_app.py turns it into AppIcon.icns before the app is signed
echo "building $OUT"
echo "  dump     $DUMP"
echo "  work     $WORK"
echo "  settings $ENVFILE"
echo "  icon     $ICON"
set -- "$DUMP" --platform mac-app -o "$OUT" --work-dir "$WORK" --env-file "$ENVFILE" --gpu "${GPU:-none}" "$@"
[ -n "$PACKAGE" ] && set -- "$@" -p "$PACKAGE"
"$PY" "$ROOT/scripts/build_ipa_from_nsp.py" "$@"
status=$?
if [ -d "$OUT" ]; then
    codesign --force --sign - "$OUT/Contents/MacOS/dmhost" >/dev/null 2>&1 || true
    codesign --force --sign - "$OUT/Contents/MacOS/nxnative" >/dev/null 2>&1 || true
    rm -rf "$OUT/Contents/_CodeSignature"
    xattr -cr "$OUT" 2>/dev/null || true
fi
exit $status
