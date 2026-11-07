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
# A freshly built bundle carries no quarantine, but a copy made by hand or a download would: clear it so Gatekeeper does not
# hold the launch for minutes while it verifies 23 GB
xattr -cr "$OUT" 2>/dev/null || true
exit $status
