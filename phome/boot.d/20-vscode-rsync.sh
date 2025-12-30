#!/bin/bash
# Copy persistent VS Code server state into /root to avoid pool dependency during runtime.

set -euo pipefail

PHOME_DEFAULT="/mnt/pool/appdata/home"
PHOME="${PHOME:-$PHOME_DEFAULT}"
SRC="$PHOME/.vscode-server"
DEST="/root/.vscode-server"

if [[ ! -d "$SRC" ]]; then
    echo "[vscode-rsync] Source $SRC not found; skipping copy"
    exit 0
fi

if [[ -L "$DEST" ]]; then
    echo "[vscode-rsync] Removing legacy symlink at $DEST"
    rm -f "$DEST"
fi

mkdir -p "$DEST"
echo "[vscode-rsync] Syncing $SRC -> $DEST"
rsync -a --delete "$SRC"/ "$DEST"/

echo "[vscode-rsync] Done"