#!/bin/sh
# Run the staged build with a save, a pipeline cache and a temp folder of its own, so the working install keeps its own.
# The host keys all of those by title ID, so without this the two builds would share them.
#   scripts/play-next.sh [app] [data dir]
set -eu
APP="${1:-$HOME/Documents/Switch 2 Files/MKW-next.app}"
DATA="${2:-$HOME/Documents/mkw-next-data}"
[ -x "$APP/Contents/MacOS/nxnative" ] || { echo "no app at $APP" >&2; exit 1; }
mkdir -p "$DATA/save" "$DATA/temp" "$DATA/pso_archive"
export DM_ROOT="$DATA" DM_SAVE="$DATA/save" DM_TEMP="$DATA/temp"
export DM_PSO_ARCHIVE="$DATA/pso_archive" DM_PSO_USER="$DATA/pso_user.tsv"
echo "save, cache and temp under $DATA"
exec "$APP/Contents/MacOS/nxnative"
