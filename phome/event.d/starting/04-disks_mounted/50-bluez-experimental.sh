#!/usr/bin/env bash
set -euo pipefail

BLUETOOTHD_BIN="/usr/sbin/bluetoothd"
CRON_FILE="/etc/cron.d/bluetooth-watchdog"
NULL_SINK="/root/null"

log() {
  echo "[bluez-experimental] $*"
}

start_bluetoothd_experimental() {
  if ! command -v "$BLUETOOTHD_BIN" >/dev/null 2>&1; then
    log "bluetoothd not found at $BLUETOOTHD_BIN; skipping"
    return 0
  fi

  # Ensure system D-Bus is present before starting bluetoothd.
  if [[ ! -S /var/run/dbus/system_bus_socket && ! -S /run/dbus/system_bus_socket ]]; then
    log "system D-Bus socket not found; skipping"
    return 0
  fi

  local running
  running="$(pgrep -ax bluetoothd || true)"

  if [[ -n "$running" ]]; then
    if echo "$running" | grep -q -- "--experimental"; then
      log "bluetoothd already running with --experimental"
      return 0
    fi

    log "bluetoothd running without --experimental; restarting"
    pkill -x bluetoothd || true
    sleep 1
  else
    log "bluetoothd not running; starting"
  fi

  # On some systems bluetoothd may not daemonize as expected; always start it
  # detached so this script never blocks boot.
  # CRITICAL: cd / first to avoid holding /mnt/user (prevents array stop)
  (cd / && nohup "$BLUETOOTHD_BIN" --experimental >"$NULL_SINK" 2>&1 &)

  # Wait briefly for the process to appear.
  local i
  for i in {1..20}; do
    if pgrep -ax bluetoothd | grep -q -- "--experimental"; then
      break
    fi
    sleep 0.1
  done

  if pgrep -ax bluetoothd | grep -q -- "--experimental"; then
    log "bluetoothd started with --experimental"
  else
    log "bluetoothd start did not verify --experimental (check logs)"
  fi
}

install_watchdog_cron() {
  if [[ ! -x "$BLUETOOTHD_BIN" ]]; then
    rm -f "$CRON_FILE" 2>/dev/null || true
    log "bluetoothd not present; watchdog cron not installed"
    return 0
  fi

  # Unraid rootfs is ephemeral; re-install this file every boot.
  cat >"$CRON_FILE" <<'EOF'
# Ensure bluetoothd stays running with --experimental.
# Recreated at boot by phome/boot.d/50-bluez-experimental.sh
* * * * * root /bin/bash -lc 'test -x /usr/sbin/bluetoothd || exit 0; pgrep -ax bluetoothd | /usr/bin/grep -q -- "--experimental" || { /usr/bin/pkill -x bluetoothd >/root/null 2>&1 || true; cd / && /usr/bin/nohup /usr/sbin/bluetoothd --experimental >/root/null 2>&1 & }'
EOF

  chmod 0644 "$CRON_FILE" || true
  log "installed watchdog cron: $CRON_FILE"
}

main() {
  start_bluetoothd_experimental
  install_watchdog_cron
}

main "$@"
