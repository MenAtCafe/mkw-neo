#!/bin/sh
# Build the staged app: this dump, our icon, the isolated work folder and output.
#   scripts/build-next.sh [extra build options]
# Override with DUMP=, OUT=, WORK=, ICON=, PY=.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PY="${PY:-$HOME/Documents/DeepSeek R&D/Switch 2 - Mario Kart World/tooling/plumber-racer-2/.venv/bin/python}"
DUMP="${DUMP:-$HOME/Documents/Switch 2 Files/Mario Kart World Rom}"
OUT="${OUT:-$HOME/Documents/Switch 2 Files/MKW-next.app}"
WORK="${WORK:-$HOME/Documents/DeepSeek R&D/mkw-next-build}"
ICON="${ICON:-$HOME/Documents/DeepSeek R&D/Switch 2 - Mario Kart World/tooling/plumber-racer-2/macbook-neo/assets/AppIcon.png}"
export DOTNET_ROOT="${DOTNET_ROOT:-/opt/homebrew/opt/dotnet/libexec}"
export MAC_ICON="$ICON"   # pack_app.py turns it into AppIcon.icns before the app is signed, so no second signing pass
echo "building $OUT from $DUMP"
echo "  work $WORK"
echo "  icon $ICON"
"$PY" "$ROOT/scripts/build_ipa_from_nsp.py" "$DUMP" --platform mac-app -o "$OUT" --work-dir "$WORK" "$@"
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
