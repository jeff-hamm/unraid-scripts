#!/bin/bash
# BlueZ installation script for Unraid
# Persists across reboots via /boot/config and /mnt/user/appdata/bluez

BLUEZ_APPDATA="/mnt/user/appdata/bluez"
BLUEZ_BOOT="/boot/config/plugins/bluez"
SLACKWARE_VERSION="15.0"

echo "=== BlueZ Setup for Unraid ==="

# Wait for array to be available
while [ ! -d "/mnt/user/appdata" ]; do
    echo "Waiting for /mnt/user/appdata to be available..."
    sleep 5
done

# Create persistent directories
mkdir -p "${BLUEZ_APPDATA}"/{bin,lib,etc/bluetooth,var/lib/bluetooth}
mkdir -p "${BLUEZ_BOOT}"

# Check if BlueZ packages exist in appdata
if [ -f "${BLUEZ_APPDATA}/packages/bluez-5.*.txz" ]; then
    echo "Found BlueZ packages in appdata, installing from cache..."
    installpkg "${BLUEZ_APPDATA}"/packages/*.txz
else
    echo "Downloading BlueZ packages..."
    mkdir -p "${BLUEZ_APPDATA}/packages"
    
    # Download from Slackware mirror
    MIRROR="https://mirrors.slackware.com/slackware/slackware64-${SLACKWARE_VERSION}/slackware64"
    
    cd "${BLUEZ_APPDATA}/packages"
    
    # Download BlueZ and dependencies
    wget -c "${MIRROR}/n/bluez-5.63-x86_64-2.txz"
    wget -c "${MIRROR}/l/libical-3.0.14-x86_64-4.txz"
    
    if [ -f "bluez-5.63-x86_64-2.txz" ]; then
        echo "Installing BlueZ packages..."
        installpkg *.txz
    else
        echo "ERROR: Failed to download BlueZ packages"
        exit 1
    fi
fi

# Create basic BlueZ configuration
cat > /etc/bluetooth/main.conf << 'EOF'
[General]
Name = Unraid
Class = 0x000100
DiscoverableTimeout = 0
AlwaysPairable = false
PairableTimeout = 0

[Policy]
AutoEnable=true
EOF

# Start bluetoothd with experimental features (required for passive BLE scanning)
if ! pgrep -x bluetoothd > /dev/null; then
    echo "Starting bluetoothd with --experimental..."
    /usr/libexec/bluetooth/bluetoothd --experimental &
    sleep 2
fi

# Bind TP-Link Bluetooth adapter (2357:0604) to btusb driver
if lsusb -d 2357:0604 >/dev/null 2>&1; then
    echo "Binding TP-Link Bluetooth adapter to btusb driver..."
    echo "2357 0604" > /sys/bus/usb/drivers/btusb/new_id 2>/dev/null || true
    sleep 2
fi

# Bring up Bluetooth adapter
if [ -f /usr/bin/bluetoothctl ]; then
    echo "Enabling Bluetooth adapter..."
    timeout 5 bluetoothctl power on 2>/dev/null || true
    timeout 5 bluetoothctl pairable on 2>/dev/null || true
fi

# Check status
if hciconfig 2>/dev/null | grep -q "UP RUNNING"; then
    echo "✓ BlueZ is running and adapter is UP"
    hciconfig
else
    echo "⚠ BlueZ installed but adapter may not be ready"
    echo "Check with: hciconfig -a"
fi

echo "=== BlueZ Setup Complete ==="
