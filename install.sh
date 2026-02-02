#!/bin/bash
# Installation script for unraid-scripts repository
# Sets up git hooks and bind mounts

set -euo pipefail


echo "=== Unraid Scripts Repository Setup ==="
echo ""
UNRAID_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALLER_DIR=${1:-$UNRAID_SCRIPTS_DIR}

if ! command -v app-envs &> /dev/null; then
  ENVS_SCRIPT="$UNRAID_SCRIPTS_DIR/scripts/app-envs.sh"
  if [ ! -f "$ENVS_SCRIPT" ]; then
    echo "Could not find $ENVS_SCRIPT"
    exit 1
  fi
  chmod +x "$ENVS_SCRIPT";
  . "$ENVS_SCRIPT" "$CALLER_DIR"
  if [ ! -f "$PHOME/.local/bin/app-envs" ]; then
    mkdir -p "$PHOME/.local/bin"
    cp "$ENVS_SCRIPT" "$PHOME/.local/bin/app-envs"
  fi
fi

# Ensure environment variables are persisted in .env
ENV_FILE="$PHOME/.env"
mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"

# Check and append UNRAID_SCRIPTS_DIR if not defined
if ! grep -q "^UNRAID_SCRIPTS_DIR=" "$ENV_FILE" 2>/dev/null; then
    echo "UNRAID_SCRIPTS_DIR=\"$UNRAID_SCRIPTS_DIR\"" >> "$ENV_FILE"
    echo "  Added UNRAID_SCRIPTS_DIR to .env"
    export UNRAID_SCRIPTS_DIR="$UNRAID_SCRIPTS_DIR"
fi

# Check and append PHOME if not defined
if ! grep -q "^PHOME=" "$ENV_FILE" 2>/dev/null; then
    echo "PHOME=\"$PHOME\"" >> "$ENV_FILE"
    echo "  Added PHOME to .env"
fi

# Check and append APP_ROOT if not defined
if ! grep -q "^APP_ROOT=" "$ENV_FILE" 2>/dev/null; then
    APP_ROOT_VAL="$(dirname "$UNRAID_SCRIPTS_DIR")"
    echo "APP_ROOT=\"$APP_ROOT_VAL\"" >> "$ENV_FILE"
    echo "  Added APP_ROOT to .env"
    export APP_ROOT="$APP_ROOT_VAL"
fi


# Copy installation scripts to boot.d for auto-run on boot
echo ""
echo "Installing boot scripts..."
mkdir -p "$PHOME/boot.d"
chmod +x "$UNRAID_SCRIPTS_DIR/scripts/boot.sh"
cp "$UNRAID_SCRIPTS_DIR/scripts/boot.sh" "$PHOME/boot.sh"
for script in "$UNRAID_SCRIPTS_DIR/install.d/"*.sh; do
    if [ -f "$script" ]; then
        script_name="$(basename "$script")"
        cp "$script" "$PHOME/boot.d/$script_name"
        chmod +x "$PHOME/boot.d/$script_name"
        echo "  Installed boot.d/$script_name"
    fi
done

bash "$PHOME/boot.sh"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Repository structure:"
echo "  phome/             -> /mnt/pool/appdata/home"
echo "  user.scripts/      -> /boot/config/plugins/user.scripts/scripts"
echo "  ai-system-monitor/ -> /mnt/pool/appdata/ai-system-monitor"
echo ""
echo "You can now use git commands to track changes in all three locations."
