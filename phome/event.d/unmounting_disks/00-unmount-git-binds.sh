#!/bin/bash
# Unmount git repo bind mounts on array stop or shutdown
# Runs via shutdown.d with MODE environment variable

REPO_BASE="/mnt/pool/appdata/unraid-scripts"

log() {
  local mode="${MODE:-unknown}"
  echo "[unmount-git-binds:$mode] $*"
  logger -t "unmount-git-binds:$mode" "$*"
}

unmount_if_mounted() {
  local path="$1"
  if mountpoint -q "$path" 2>/dev/null; then
    log "Unmounting: $path"
    if umount "$path" 2>&1 | logger -t unmount-git-binds; then
      log "Successfully unmounted: $path"
    else
      log "WARNING: Failed to unmount $path"
      return 1
    fi
  fi
  return 0
}

main() {
  # Run during shutdown (before array unmounts)
  if [ "$MODE" != "shutdown" ]; then
    log "Skipping (only runs on shutdown, current mode: ${MODE:-unset})"
    return 0
  fi
  
  log "Unmounting git repository bind mounts..."
  
  # Unmount in reverse order (deepest first)
  unmount_if_mounted "$REPO_BASE/phome"
  unmount_if_mounted "$REPO_BASE/user.scripts"
  unmount_if_mounted "$REPO_BASE/ai-system-monitor"
  unmount_if_mounted "$REPO_BASE/code-server"
  
  log "Git bind mount cleanup complete"
}

main "$@"
