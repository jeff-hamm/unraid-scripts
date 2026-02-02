#!/bin/bash
#
# PHOME Installer - Sets up jumpraid-scripts plugin and persistent home
#
# Run this once after restoring PHOME to a new system:
#   bash /mnt/pool/appdata/home/install.sh
#
# What it does:
#   1. Installs jumpraid-scripts plugin (event handler for emhttpd events)
#   2. Runs disks_mounted scripts immediately to configure the system
#
# See: $PHOME/docs/system/unraid-event-system.md for architecture details
#

set -e

PHOME="${PHOME:-/mnt/pool/appdata/home}"
PLUGIN_DIR="/usr/local/emhttp/plugins/jumpraid-scripts"
EVENT_DIR="${PHOME}/event.d/disks_mounted"

echo "=== PHOME Installer ==="
echo "PHOME: $PHOME"
echo ""

# Verify PHOME exists
if [[ ! -d "$PHOME" ]]; then
    echo "ERROR: $PHOME does not exist!"
    echo "Restore PHOME first, then run this installer."
    exit 1
fi

# === 1. Install jumpraid-scripts plugin ===
echo "Installing jumpraid-scripts plugin..."
mkdir -p "$PLUGIN_DIR/event"

# Copy the any_event handler from PHOME
if [[ -f "$PHOME/plugins/jumpraid-scripts/any_event.sh" ]]; then
    cp "$PHOME/plugins/jumpraid-scripts/any_event.sh" "$PLUGIN_DIR/event/any_event"
    chmod +x "$PLUGIN_DIR/event/any_event"
    echo "  Created: $PLUGIN_DIR/event/any_event"
else
    echo "  ERROR: $PHOME/plugins/jumpraid-scripts/any_event.sh not found!"
    exit 1
fi

# Create event.d directory structure in PHOME if it doesn't exist
mkdir -p "$PHOME/event.d/disks_mounted"
mkdir -p "$PHOME/event.d/unmounting_disks"
echo "  Created: $PHOME/event.d/ (for event-specific handlers)"

# === 2. Run disks_mounted scripts now ===
echo ""
echo "Running disks_mounted scripts..."
echo "========================================" 

if "$PLUGIN_DIR/event/any_event" disks_mounted; then
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "PHOME is now configured:"
    echo ""
    echo "  Boot/Shutdown triggers:"
    echo "    - jumpraid-scripts plugin   → runs event.d scripts on emhttpd events"
    echo ""
    echo "  Script directories:"
    echo "    - $PHOME/event.d/disks_mounted/      → boot scripts (run on array start)"
    echo "    - $PHOME/event.d/unmounting_disks/   → shutdown scripts (run before disks unmount)"
    echo "    - $PHOME/event.d/<event>/            → per-event handlers"
    echo ""
    echo "  Logs:"
    echo "    - /root/boot.log                     → all boot/event activity"
    echo ""
    echo "  Documentation:"
    echo "    - $PHOME/docs/system/unraid-event-system.md"
else
    echo ""
    echo "WARNING: Scripts had errors (see above)"
    echo "Installation completed with warnings."
fi
