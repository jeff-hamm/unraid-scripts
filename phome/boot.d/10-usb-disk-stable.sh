#!/bin/bash
# Disable USB autosuspend for mass storage devices to prevent disconnects
# This runs at boot to keep USB HDDs stable

# Disable autosuspend globally for USB (set to -1 = never suspend)
echo -1 > /sys/module/usbcore/parameters/autosuspend 2>/dev/null

# Also set all current USB devices to "on" (no autosuspend)
for dev in /sys/bus/usb/devices/*/power/control; do
    echo on > "$dev" 2>/dev/null
done

# Specifically target JMicron bridges (common USB-SATA adapters)
for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ]; then
        vendor=$(cat "$dev/idVendor" 2>/dev/null)
        product=$(cat "$dev/idProduct" 2>/dev/null)
        # JMicron JMS56x series
        if [ "$vendor" = "152d" ]; then
            echo on > "$dev/power/control" 2>/dev/null
            # Increase USB timeout for this device
            [ -f "$dev/power/autosuspend_delay_ms" ] && echo -1 > "$dev/power/autosuspend_delay_ms" 2>/dev/null
            logger "Disabled USB autosuspend for JMicron device at $dev"
        fi
    fi
done

# Disable UAS for JMicron JMS56x bridge (known to be flaky with UAS)
# The 'u' flag forces usb-storage instead of uas driver
echo "152d:0565:u" > /sys/module/usb_storage/parameters/quirks 2>/dev/null

echo "USB disk stability settings applied (UAS disabled for JMicron)"
