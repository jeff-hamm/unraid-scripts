#!/bin/bash
set -euo pipefail

# Boot-time installer for SD card auto-import
# - Installs udev rule into /etc/udev/rules.d
# - Symlinks helper scripts into /usr/local/bin
# - Ensures executable bits are set

log() {
  echo "[sd-import-install] $*"
}

die() {
  echo "[sd-import-install][ERROR] $*" >&2
  exit 1
}

SRC_DIR="/mnt/pool/appdata/sd-import"
[ -d "$SRC_DIR" ] || die "Missing sd-import source dir: $SRC_DIR"

RULE_SRC="$SRC_DIR/99-sd-card-import.rules"
IMPORT_SRC="$SRC_DIR/sd-card-import.sh"
UPLOAD_SRC="$SRC_DIR/immich-go-upload.sh"

[ -f "$RULE_SRC" ] || die "Missing udev rule: $RULE_SRC"
[ -f "$IMPORT_SRC" ] || die "Missing import script: $IMPORT_SRC"
[ -f "$UPLOAD_SRC" ] || die "Missing upload script: $UPLOAD_SRC"

log "Using source dir: $SRC_DIR"

# 1) Install udev rule
RULE_DEST="/etc/udev/rules.d/99-sd-card-import.rules"
log "Installing udev rule -> $RULE_DEST"
cp -f "$RULE_SRC" "$RULE_DEST"
chmod 0644 "$RULE_DEST"

INSTALL_LOG_FILE="/var/log/sd-card-import-install.log"
if command -v udevadm >"$INSTALL_LOG_FILE" 2>&1; then
  log "Reloading udev rules"
  udevadm control --reload-rules >>"$INSTALL_LOG_FILE" 2>&1 || true
else
  log "udevadm not found; skipping reload"
fi

# 2) Symlink scripts into /usr/local/bin
mkdir -p /usr/local/bin

log "Symlinking installer -> /usr/local/bin/install-sd-import"
ln -sf /root/phome/boot.d/60-sd-import-install.sh /usr/local/bin/install-sd-import

log "Symlinking sd-card-import.sh -> /usr/local/bin/sd-card-import.sh"
ln -sf "$IMPORT_SRC" /usr/local/bin/sd-card-import.sh

log "Symlinking sd-card-import.sh -> /usr/local/bin/sd-card-import"
ln -sf "$IMPORT_SRC" /usr/local/bin/sd-card-import

log "Symlinking immich-go-upload -> /usr/local/bin/immich-go-upload"
ln -sf "$UPLOAD_SRC" /usr/local/bin/immich-go-upload

# 3) Ensure executables
log "Ensuring scripts are executable"
chmod +x "$IMPORT_SRC" "$UPLOAD_SRC"
chmod +x /root/phome/boot.d/60-sd-import-install.sh || true
chmod +x /usr/local/bin/install-sd-import /usr/local/bin/sd-card-import.sh /usr/local/bin/sd-card-import /usr/local/bin/immich-go-upload || true

# 4) Ensure log file exists
LOG_FILE="/var/log/sd-card-import.log"
log "Ensuring log file exists at $LOG_FILE"
touch "$LOG_FILE" || true

log "Done. Current status:"
ls -la "$RULE_DEST" /usr/local/bin/install-sd-import /usr/local/bin/sd-card-import.sh /usr/local/bin/sd-card-import /usr/local/bin/immich-go-upload | cat
