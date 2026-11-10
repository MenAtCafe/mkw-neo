#!/bin/sh
# Launch the app. The host keeps the save, the settings and the pipeline cache by title ID, so this only starts it.
set -eu
APP="${1:-${APP:-$HOME/Documents/Mario Kart World.app}}"
[ -d "$APP" ] || { echo "no app at $APP: run scripts/build.sh, or pass the path" >&2; exit 1; }
echo "launching $APP"
exec "$APP/Contents/MacOS/nxnative" "$@"
