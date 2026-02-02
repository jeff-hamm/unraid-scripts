#!/bin/bash
# Kill all processes using /mnt/pool before unmounting
# This is a safety net - specific service scripts should run first

log() {
  local mode="${MODE:-unknown}"
  echo "[kill-pool-users:$mode] $*"
  logger -t "kill-pool-users:$mode" "$*"
}

main() {
  log "Checking for processes using /mnt/pool..."
  
  # Get list of processes using /mnt/pool
  local pids=$(fuser -c /mnt/pool 2>/dev/null | xargs)
  
  if [ -z "$pids" ]; then
    log "No processes using /mnt/pool"
    return 0
  fi
  
  log "Found processes using /mnt/pool: $pids"
  
  # Show what's using it for debugging
  fuser -vm /mnt/pool 2>&1 | while read line; do
    log "$line"
  done
  
  # Try graceful kill first
  log "Sending SIGTERM to processes..."
  fuser -k -TERM /mnt/pool 2>/dev/null
  
  # Wait up to 5 seconds
  local count=0
  while [ $count -lt 5 ]; do
    sleep 1
    ((count++))
    pids=$(fuser -c /mnt/pool 2>/dev/null | xargs)
    if [ -z "$pids" ]; then
      log "All processes terminated gracefully"
      return 0
    fi
  done
  
  # Force kill remaining
  log "Force killing remaining processes..."
  fuser -k -9 /mnt/pool 2>/dev/null
  sleep 1
  
  # Final check
  pids=$(fuser -c /mnt/pool 2>/dev/null | xargs)
  if [ -z "$pids" ]; then
    log "All processes killed"
  else
    log "WARNING: Some processes may still be using /mnt/pool: $pids"
  fi
}

main "$@"
