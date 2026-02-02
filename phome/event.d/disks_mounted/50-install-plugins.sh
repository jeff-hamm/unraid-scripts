#!/bin/bash
# Auto-install plugins from unraid-scripts/plugins/ directory
# Runs on boot to ensure all plugins are installed

# Source environment (app-envs searches for .env automatically)
. app-envs 2>/dev/null || {
    PHOME="${PHOME:-/mnt/pool/appdata/home}"
    [ -f "$PHOME/.local/bin/app-envs" ] && . "$PHOME/.local/bin/app-envs"
}

UNRAID_SCRIPTS_DIR="${UNRAID_SCRIPTS_DIR:-/mnt/pool/appdata/unraid-scripts}"

# Use $1 if it's an existing directory, otherwise use default plugins dir
if [ -n "$1" ] && [ -d "$1" ]; then
    PLUGIN_DIR="$1"
else
    PLUGIN_DIR="$UNRAID_SCRIPTS_DIR/plugins"
fi

# Wait for pool to be available
timeout=30
while [ $timeout -gt 0 ]; do
  if [ -d "$PLUGIN_DIR" ]; then
    break
  fi
  sleep 1
  ((timeout--))
done

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "ERROR: Plugins directory not found: $PLUGIN_DIR" >&2
  exit 1
fi

# Install each plugin if not already installed
for plugin_dir in "$PLUGIN_DIR/"*/; do
  if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/install.sh" ]; then
    plugin_name=$(basename "$plugin_dir")
    
    # Check if plugin is already installed
    if [ ! -f "/boot/config/plugins/$plugin_name.plg" ]; then
      echo "Auto-installing plugin: $plugin_name"
      if ! bash "$plugin_dir/install.sh"; then
        echo "ERROR: Failed to install plugin: $plugin_name" >&2
        # Continue with next plugin instead of exiting
        continue
      fi
    fi
  fi
done
