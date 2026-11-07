#!/bin/sh
# Run the app. Its save, pipeline cache and temp files are the host's own, keyed by title ID under
# ~/Library/Application Support/nxnative/0400C3F00006E000/, and env.txt there carries the keyboard map and DM_GUEST_FILE=1.
#   scripts/play.sh [app]
set -eu
APP="${1:-$HOME/Documents/Switch 2 Files/Mario Kart World.app}"
[ -x "$APP/Contents/MacOS/nxnative" ] || { echo "no app at $APP" >&2; exit 1; }
export DM_GUEST_FILE="${DM_GUEST_FILE:-1}"
exec "$APP/Contents/MacOS/nxnative"
