#!/bin/bash
# Mount bind points for unraid-scripts git repo
# This allows git to track files at their real locations

REPO_DIR="${REPO_DIR:-/mnt/pool/appdata/unraid-scripts}"
APPDATA_ROOT="$(dirname "$REPO_DIR")"

# Wait for pool to be available
timeout=30
while [ $timeout -gt 0 ]; do
  if [ -d "$REPO_DIR" ]; then
    break
  fi
  sleep 1
  ((timeout--))
done

if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: Repo directory not found: $REPO_DIR" >&2
  exit 1
fi

# Create mount point directories if needed
mkdir -p "$REPO_DIR/phome"
mkdir -p "$REPO_DIR/user.scripts"
mkdir -p "$REPO_DIR/ai-system-monitor"

# Bind mount each location
if ! mountpoint -q "$REPO_DIR/phome"; then
  mount --bind "$APPDATA_ROOT/home" "$REPO_DIR/phome" && \
    echo "Mounted: $REPO_DIR/phome -> $APPDATA_ROOT/home"
fi

if ! mountpoint -q "$REPO_DIR/user.scripts"; then
  mount --bind /boot/config/plugins/user.scripts/scripts "$REPO_DIR/user.scripts" && \
    echo "Mounted: $REPO_DIR/user.scripts -> /boot/config/plugins/user.scripts/scripts"
fi

if ! mountpoint -q "$REPO_DIR/ai-system-monitor"; then
  mount --bind "$APPDATA_ROOT/ai-system-monitor" "$REPO_DIR/ai-system-monitor" && \
    echo "Mounted: $REPO_DIR/ai-system-monitor -> $APPDATA_ROOT/ai-system-monitor"
fi
