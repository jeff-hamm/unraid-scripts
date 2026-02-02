#!/bin/bash
# Mount bind points for unraid-scripts git repo
# This allows git to track files at their real locations

. app-envs 2>/dev/null || {
    PHOME="${PHOME:-/mnt/pool/appdata/home}"
    [ -f "$PHOME/.local/bin/app-envs" ] && . "$PHOME/.local/bin/app-envs"
}

UNRAID_SCRIPTS_DIR="${UNRAID_SCRIPTS_DIR:-/mnt/pool/appdata/unraid-scripts}"
APP_ROOT="${APP_ROOT:-/mnt/pool/appdata}"

# Wait for pool to be available
timeout=30
while [ $timeout -gt 0 ]; do
  if [ -d "$UNRAID_SCRIPTS_DIR" ]; then
    break
  fi
  sleep 1
  ((timeout--))
done

if [ ! -d "$UNRAID_SCRIPTS_DIR" ]; then
  echo "ERROR: Repo directory not found: $UNRAID_SCRIPTS_DIR" >&2
  exit 1
fi

# Create mount point directories if needed
mkdir -p "$UNRAID_SCRIPTS_DIR/phome"
mkdir -p "$UNRAID_SCRIPTS_DIR/user.scripts"
mkdir -p "$UNRAID_SCRIPTS_DIR/ai-system-monitor"

# Bind mount each location
if ! mountpoint -q "$UNRAID_SCRIPTS_DIR/phome"; then
  mount --bind "$APP_ROOT/home" "$UNRAID_SCRIPTS_DIR/phome" && \
    echo "Mounted: $UNRAID_SCRIPTS_DIR/phome -> $APP_ROOT/home"
fi

if ! mountpoint -q "$UNRAID_SCRIPTS_DIR/user.scripts"; then
  mount --bind /boot/config/plugins/user.scripts/scripts "$UNRAID_SCRIPTS_DIR/user.scripts" && \
    echo "Mounted: $UNRAID_SCRIPTS_DIR/user.scripts -> /boot/config/plugins/user.scripts/scripts"
fi

if ! mountpoint -q "$UNRAID_SCRIPTS_DIR/ai-system-monitor"; then
  mount --bind "$APP_ROOT/ai-system-monitor" "$UNRAID_SCRIPTS_DIR/ai-system-monitor" && \
    echo "Mounted: $UNRAID_SCRIPTS_DIR/ai-system-monitor -> $APP_ROOT/ai-system-monitor"
fi