#!/bin/bash
# Auto-install plugins from unraid-scripts/plugins/ directory
# Runs on boot to ensure all plugins are installed

# Source environment (app-envs searches for .env automatically)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHOME="${PHOME:-/mnt/pool/appdata/home}"

if ! command -v app-envs &> /dev/null; then
  ENVS_SCRIPT="$SOURCE_DIR/../scripts/app-envs.sh"
  if [ ! -f "$ENVS_SCRIPT" ]; then
    ENVS_SCRIPT="$PHOME/.local/bin/app-envs"
    if [ ! -f "$ENVS_SCRIPT" ]; then
      echo "Could not find app-envs script"
      exit 1
    fi
  fi
  chmod +x "$ENVS_SCRIPT"
  . "$ENVS_SCRIPT" "$1"
  
  # Copy to PHOME if not there
  if [ ! -f "$PHOME/.local/bin/app-envs" ]; then
    mkdir -p "$PHOME/.local/bin"
    cp "$ENVS_SCRIPT" "$PHOME/.local/bin/app-envs"
  fi
fi

# Add PHOME bin to PATH via profile.d
if [ ! -f "/etc/profile.d/phome-path.sh" ]; then
  cat > /etc/profile.d/phome-path.sh << EOF
export PATH="\$PATH:$PHOME/.local/bin"
EOF
  chmod +x /etc/profile.d/phome-path.sh
  echo "  Created /etc/profile.d/phome-path.sh"
fi
