#!/bin/bash
# SD Card Import Installer
# Installs udev rules for automatic SD card import
# Configure SD_CARD_READER in .env file (co-located with this script)

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_FILE="/var/log/sd-card-import.log"

# Source co-located .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    source <(grep -v '^#' "$SCRIPT_DIR/.env" | grep -E '^[A-Z_]+=' | sed 's/^/export /')
fi

echo "=========================================="
echo "SD Card Auto-Import Setup"
echo "=========================================="
echo ""

# Install udev rule if SD_CARD_READER is configured
SD_RULES_TEMPLATE="$SCRIPT_DIR/99-sd-card-import.rules"
SD_RULES_DEST="/etc/udev/rules.d/99-sd-card-import.rules"

if [ -f "$SD_RULES_TEMPLATE" ]; then
    if [ -n "$SD_CARD_READER" ]; then
        echo "Installing udev rule for SD reader: $SD_CARD_READER"
        # Substitute placeholder and install
        sed "s/YOUR_SD_READER_SERIAL/$SD_CARD_READER/g" "$SD_RULES_TEMPLATE" > "$SD_RULES_DEST"
        udevadm control --reload-rules
        echo "  Installed: $SD_RULES_DEST"
    else
        echo "Skipping udev rule (SD_CARD_READER not configured)"
        echo ""
        echo "To enable auto-import on SD card insert:"
        echo "  1. Find your SD reader serial:"
        echo "     udevadm info --query=all --name=/dev/sdX | grep ID_SERIAL"
        echo ""
        echo "  2. Add to $SCRIPT_DIR/.env:"
        echo "     SD_CARD_READER=\"your-serial-here\""
        echo ""
        echo "  3. Re-run: install-sd-import"
    fi
else
    echo "Warning: udev rules template not found at $SD_RULES_TEMPLATE"
fi

# Create import directory
IMPORTS_PATH="${IMPORTS_PATH:-/mnt/user/jumpdrive/imports}"
echo ""
echo "Creating import directory..."
mkdir -p "$IMPORTS_PATH"
echo "  Created: $IMPORTS_PATH"

# Create log file
echo ""
echo "Creating log file..."
touch "$LOG_FILE"
echo "  Created: $LOG_FILE"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Commands available:"
echo "  sd-card-import <device>  - Import from SD card (e.g., sd-card-import sdd)"
echo "  immich-go-upload <path>  - Upload directory to Immich"
echo ""
