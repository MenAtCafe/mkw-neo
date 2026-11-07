#!/bin/sh
# Run the app. Its save, pipeline cache and temp files are the host's own, keyed by title ID under
# ~/Library/Application Support/nxnative/0400C3F00006E000/, and the settings the build baked in are read from there too.
#   scripts/play.sh [app]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$ROOT/scripts/local.conf" ] && . "$ROOT/scripts/local.conf"
APP="${1:-${APP:-$HOME/Documents/Mario Kart World.app}}"
[ -x "$APP/Contents/MacOS/nxnative" ] || { echo "no app at $APP" >&2; exit 1; }
export DM_GUEST_FILE="${DM_GUEST_FILE:-1}"
exec "$APP/Contents/MacOS/nxnative"
