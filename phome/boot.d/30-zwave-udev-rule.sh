#!/usr/bin/env bash
set -euo pipefail

RULE_FILE="/etc/udev/rules.d/99-zwave-stick.rules"
NULL_SINK="/root/null"

cat >"$RULE_FILE" <<'EOF'
# Zooz 800 Z-Wave Stick (1a86:55d4)
# Create stable symlink: /dev/zwave -> /dev/ttyACM*
SUBSYSTEM=="tty", ENV{ID_VENDOR_ID}=="1a86", ENV{ID_MODEL_ID}=="55d4", SYMLINK+="zwave", GROUP="dialout", MODE="0660"
EOF

udevadm control --reload-rules >"$NULL_SINK" 2>&1 || true
udevadm trigger --subsystem-match=tty >"$NULL_SINK" 2>&1 || true

echo "[zwave-udev] Installed $RULE_FILE"
