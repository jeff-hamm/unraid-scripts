#!/bin/bash
# USB stability fixes for Sabrent dock with JMicron JMS56x controller (152d:0565)
# Prevents USB disconnects, timeouts, and UAS-related issues

set -e

# 1. Disable USB autosuspend globally
echo -1 > /sys/module/usbcore/parameters/autosuspend

# 2. Set all USB devices to always-on power mode
for device in /sys/bus/usb/devices/*/power/control; do
    echo on > "$device" 2>/dev/null
done

# 3. Disable UAS (USB Attached SCSI) for JMicron - can cause instability
# This forces the drive to use traditional usb-storage instead
# Add quirk: 152d:0565:u (u = disable UAS)
if ! grep -q "152d:0565" /sys/module/usb_storage/parameters/quirks 2>/dev/null; then
    echo "152d:0565:u" > /sys/module/usb_storage/parameters/quirks 2>/dev/null || true
fi

# 4. Increase SCSI timeout for USB drives (default 30s, increase to 180s)
for disk in /sys/block/sd*/device/timeout; do
    echo 180 > "$disk" 2>/dev/null
done

# 5. Disable drive spindown via hdparm (if available)
if command -v hdparm &> /dev/null; then
    for drive in /dev/sdb /dev/sdc /dev/sdd /dev/sde; do
        [ -b "$drive" ] && hdparm -S 0 "$drive" 2>/dev/null
    done
fi
