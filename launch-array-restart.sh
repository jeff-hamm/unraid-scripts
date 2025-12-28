#!/bin/bash
#
# launch-array-restart.sh - Launch the array restart in a detached process
#
# This launcher ensures the restart script will complete even if:
# - SSH disconnects
# - Tailscale drops
# - Terminal closes
# - User logs out
#

SCRIPT="/root/scripts/safe-array-restart.sh"
LOG="/boot/logs/array-restart-launcher.log"

echo "=============================================="
echo "  SAFE ARRAY RESTART LAUNCHER"
echo "=============================================="
echo ""
echo "This will:"
echo "  1. Stop the array"
echo "  2. Wait for disks to settle (10 seconds)"
echo "  3. Restart the array (with 5 retry attempts)"
echo ""
echo "The restart will complete EVEN IF your connection drops."
echo ""
echo "Logs will be saved to: /boot/logs/"
echo ""

# Confirm
read -p "Type 'yes' to proceed: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Launching restart script in background..."
echo ""

# Launch completely detached using nohup + disown + setsid
mkdir -p /boot/logs
nohup setsid "$SCRIPT" > "$LOG" 2>&1 &
RESTART_PID=$!

echo "✓ Restart script launched (PID: $RESTART_PID)"
echo ""
echo "The script is now running independently."
echo "If your connection drops, the array will still restart."
echo ""
echo "To monitor progress:"
echo "  tail -f /boot/logs/array-restart-*.log"
echo ""
echo "Waiting 3 seconds before showing initial log..."
sleep 3
echo ""
echo "=== Current log output ==="
tail -20 /boot/logs/array-restart-*.log 2>/dev/null | tail -20
echo ""
echo "To continue monitoring: tail -f /boot/logs/array-restart-*.log"
