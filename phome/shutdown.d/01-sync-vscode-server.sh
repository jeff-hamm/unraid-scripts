#!/bin/bash
# Backup VS Code server data from /root to persistent storage on shutdown

SOURCE="/root/.vscode-server"
DEST="/mnt/pool/appdata/home/.vscode-server"

logger "Syncing VS Code server data to persistent storage..."

# Check if source exists
if [ ! -d "$SOURCE" ]; then
    logger "VS Code server directory not found at $SOURCE"
    exit 0
fi

# Create destination if it doesn't exist
mkdir -p "$DEST"

# Rsync with archive mode, delete removed files, exclude only logs (keep caches for transparency)
rsync -av --delete \
    --exclude='*.log' \
    --exclude='logs/' \
    "$SOURCE/" "$DEST/"

if [ $? -eq 0 ]; then
    logger "VS Code server data synced successfully"
else
    logger "VS Code server sync failed with exit code $?"
fi
