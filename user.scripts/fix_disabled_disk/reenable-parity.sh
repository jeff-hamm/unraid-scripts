#!/bin/bash
# Re-enable disabled parity disk after USB reconnection

echo "=== Parity Disk Re-enabler ==="
echo ""

# Check if array is stopped
if mdcmd status | grep -q "mdState=STARTED"; then
    echo "❌ Array is running. Stopping array first..."
    if ! mdcmd stop; then
        echo "Failed to stop array. Please stop it manually from the WebUI."
        exit 1
    fi
    sleep 2
fi

echo "✓ Array is stopped"
echo ""

# Find the parity disk ID from config
PARITY_ID=$(grep "diskIdSlot.0=" /boot/config/disk.cfg | cut -d'"' -f2)

if [ "$PARITY_ID" = "-" ] || [ -z "$PARITY_ID" ]; then
    echo "❌ No parity disk configured in disk.cfg"
    echo ""
    echo "Available disks:"
    ls -la /dev/sd* | grep "^brw"
    echo ""
    echo "You need to assign a disk as parity through the WebUI"
    exit 1
fi

echo "Parity disk ID: $PARITY_ID"
echo ""

# Check if the disk is present
DISK_FOUND=false
for DEV in /dev/sd*; do
    if [ -b "$DEV" ] && [[ ! "$DEV" =~ [0-9]$ ]]; then
        # Get disk serial/ID
        DISK_ID=$(smartctl -i "$DEV" 2>&1 | grep -E "Serial Number|Device Model" | tr '\n' '_' | sed 's/[^a-zA-Z0-9_-]//g')
        if [[ "$DISK_ID" =~ "$PARITY_ID" ]] || [[ "$PARITY_ID" =~ "$DISK_ID" ]]; then
            echo "✓ Found parity disk: $DEV"
            DISK_FOUND=true
            break
        fi
    fi
done

if [ "$DISK_FOUND" = false ]; then
    echo "❌ Parity disk not detected!"
    echo ""
    echo "Current disks:"
    for DEV in /dev/sd*; do
        if [ -b "$DEV" ] && [[ ! "$DEV" =~ [0-9]$ ]]; then
            echo "  $DEV:"
            smartctl -i "$DEV" 2>&1 | grep -E "Model|Serial" | sed 's/^/    /'
        fi
    done
    echo ""
    echo "🔌 Please reconnect the USB parity disk and run this script again"
    exit 1
fi

echo ""
echo "Starting array with parity disk..."
if mdcmd start; then
    echo "✓ Array started successfully!"
    echo ""
    echo "Checking parity status..."
    sleep 2
    mdcmd status | grep -E "diskState.0|rdevStatus.0|rdevName.0"
    echo ""
    echo "✓ Parity disk re-enabled"
else
    echo "❌ Failed to start array"
    echo "Check the WebUI for details"
    exit 1
fi
