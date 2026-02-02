#!/bin/bash
# Install BlueZ (bluetoothd + tools) and ensure bluetoothd runs with --experimental.
# Runs before 50-bluez-experimental.sh by filename ordering.

set -euo pipefail

NULL_SINK="/root/null"

BLUEZ_APPDATA="/mnt/user/appdata/bluez"
BLUEZ_BOOT="/boot/config/plugins/bluez"
SLACKWARE_VERSION="15.0"

echo "=== BlueZ Setup for Unraid ==="

# Wait for array/user shares to be available
while [[ ! -d "/mnt/user/appdata" ]]; do
    echo "Waiting for /mnt/user/appdata to be available..."
    sleep 5
done

# Create persistent directories
mkdir -p "${BLUEZ_APPDATA}"/{bin,lib,etc/bluetooth,var/lib/bluetooth,packages}
mkdir -p "${BLUEZ_BOOT}"

PACKAGES_DIR="${BLUEZ_APPDATA}/packages"

if compgen -G "${PACKAGES_DIR}/bluez-5.*.txz" >/dev/null; then
    echo "Found BlueZ packages in appdata, installing from cache..."
    installpkg "${PACKAGES_DIR}"/*.txz
else
    echo "Downloading BlueZ packages..."

    MIRROR="https://mirrors.slackware.com/slackware/slackware64-${SLACKWARE_VERSION}/slackware64"
    cd "${PACKAGES_DIR}"

    # BlueZ and dependency (keep versions pinned for repeatability)
    wget -c "${MIRROR}/n/bluez-5.63-x86_64-2.txz"
    wget -c "${MIRROR}/l/libical-3.0.14-x86_64-4.txz"

    if [[ -f "bluez-5.63-x86_64-2.txz" ]]; then
        echo "Installing BlueZ packages..."
        installpkg ./*.txz
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

BLUETOOTHD_BIN="/usr/sbin/bluetoothd"
if [[ ! -x "$BLUETOOTHD_BIN" && -x /usr/libexec/bluetooth/bluetoothd ]]; then
    BLUETOOTHD_BIN="/usr/libexec/bluetooth/bluetoothd"
fi

# Some packages install bluetoothd under libexec; keep /usr/sbin/bluetoothd available
if [[ ! -x /usr/sbin/bluetoothd && -x /usr/libexec/bluetooth/bluetoothd ]]; then
    ln -sf /usr/libexec/bluetooth/bluetoothd /usr/sbin/bluetoothd || true
fi

# Start bluetoothd with experimental features (required for passive BLE scanning)
if ! pgrep -ax bluetoothd | grep -q -- "--experimental"; then
    echo "Starting bluetoothd with --experimental..."
    pkill -x bluetoothd >"$NULL_SINK" 2>&1 || true
    nohup "$BLUETOOTHD_BIN" --experimental >"$NULL_SINK" 2>&1 &
    sleep 2
fi

# Bind TP-Link Bluetooth adapter (2357:0604) to btusb driver
if command -v lsusb >/dev/null 2>&1 && lsusb -d 2357:0604 >"$NULL_SINK" 2>&1; then
    echo "Binding TP-Link Bluetooth adapter to btusb driver..."
    echo "2357 0604" > /sys/bus/usb/drivers/btusb/new_id 2>"$NULL_SINK" || true
    sleep 2
fi

# Bring up Bluetooth adapter
if [ -f /usr/bin/bluetoothctl ]; then
    echo "Enabling Bluetooth adapter..."
    timeout 5 bluetoothctl power on 2>"$NULL_SINK" || true
    timeout 5 bluetoothctl pairable on 2>"$NULL_SINK" || true
fi

# Check status
if command -v hciconfig >/dev/null 2>&1 && hciconfig 2>"$NULL_SINK" | grep -q "UP RUNNING"; then
    echo "✓ BlueZ is running and adapter is UP"
    hciconfig
else
    echo "⚠ BlueZ installed but adapter may not be ready"
    echo "Check with: hciconfig -a"
fi

echo "=== BlueZ Setup Complete ==="
