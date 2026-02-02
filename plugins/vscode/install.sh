#!/bin/bash
# Install VS Code plugin for Unraid
# This script handles:
# - Installing code-server binary
# - Setting up boot/shutdown scripts
# - Installing Unraid plugin files
# - Configuring nginx reverse proxy

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_FILE="$PLUGIN_DIR/vscode.plg"
BOOT_PLUGIN_DIR="/boot/config/plugins"
BOOT_PLUGIN_FILE="$BOOT_PLUGIN_DIR/vscode.plg"

# Source environment (app-envs searches for .env automatically)
. app-envs 2>/dev/null || PHOME="${PHOME:-/mnt/pool/appdata/home}"
CODE_SERVER_VERSION="4.107.0"
CODE_SERVER_DIR="/mnt/pool/appdata/code-server"
CODE_SERVER_BIN="$CODE_SERVER_DIR/code-server-$CODE_SERVER_VERSION-linux-amd64/bin/code-server"

echo "========================================"
echo "Installing VS Code Plugin for Unraid"
echo "========================================"

# 1. Install code-server binary if not present
if [ ! -f "$CODE_SERVER_BIN" ]; then
    echo ""
    echo "Installing code-server $CODE_SERVER_VERSION..."
    mkdir -p "$CODE_SERVER_DIR"
    cd "$CODE_SERVER_DIR"
    
    wget "https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VERSION/code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz"
    tar -xzf "code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz"
    rm "code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz"
    
    # Create persistent symlink
    $PHOME/.local/bin/lnp "$CODE_SERVER_BIN" /usr/local/bin/code-server
    
    echo "✓ code-server installed"
else
    echo "✓ code-server already installed"
fi

# 2. Install boot scripts
echo ""
echo "Installing boot scripts..."
mkdir -p "$PHOME/boot.d"
cp "$PLUGIN_DIR/scripts/boot.d/50-code-server.sh" "$PHOME/boot.d/"
chmod +x "$PHOME/boot.d/50-code-server.sh"
echo "✓ Installed boot.d/50-code-server.sh"

# Clean up old split scripts if they exist
rm -f "$PHOME/boot.d/51-code-server-nginx.sh"

# 3. Install shutdown scripts
echo ""
echo "Installing shutdown scripts..."
mkdir -p "$PHOME/shutdown.d"
cp "$PLUGIN_DIR/scripts/shutdown.d/50-code-server.sh" "$PHOME/shutdown.d/"
chmod +x "$PHOME/shutdown.d/50-code-server.sh"
echo "✓ Installed shutdown.d/50-code-server.sh"

# 4. Install Unraid plugin files
echo ""
echo "Installing Unraid plugin..."
mkdir -p /usr/local/emhttp/plugins/vscode/images

# Copy .page file
cp "$PLUGIN_DIR/VSCode.page" /usr/local/emhttp/plugins/vscode/
echo "✓ Installed VSCode.page"

# Copy icon
cp "$PLUGIN_DIR/vscode-icon.svg" /usr/local/emhttp/plugins/vscode/images/vscode.png
echo "✓ Installed icon"

# Copy .plg file to boot
cp "$PLUGIN_FILE" "$BOOT_PLUGIN_FILE"
echo "✓ Copied plugin to $BOOT_PLUGIN_FILE"

# 5. Start code-server and configure nginx
echo ""
echo "Starting code-server and configuring nginx..."
bash "$PHOME/boot.d/50-code-server.sh"

# 6. Install the plugin via Unraid
echo ""
echo "Registering plugin with Unraid..."
/usr/local/sbin/plugin install "$BOOT_PLUGIN_FILE"

echo ""
echo "========================================"
echo "✓ VS Code Plugin Installation Complete"
echo "========================================"
echo ""
echo "Access VS Code:"
echo "  - Via Unraid UI: Click 'VSCode' tab in top menu"
echo "  - Direct access: https://$(hostname)/vscode-server/"
echo ""
echo "The VSCode tab will appear after nginx reloads."
echo ""

