#!/bin/bash
# Stop cloudflared on shutdown/array-stop
# Must run BEFORE unmounting pool since binary is at $PHOME/.local/opt/bin/cloudflared

log() {
  local mode="${MODE:-unknown}"
  echo "[cloudflared:$mode] $*"
  logger -t "cloudflared:$mode" "$*"
}

main() {
  log "Stopping cloudflared..."
  
  if pgrep -x cloudflared > /dev/null; then
    local pid=$(pgrep -x cloudflared)
    log "Found cloudflared running (PID: $pid)"
    
    # Graceful stop
    pkill -x cloudflared
    
    # Wait up to 5 seconds for graceful shutdown
    local count=0
    while pgrep -x cloudflared > /dev/null && [ $count -lt 5 ]; do
      sleep 1
      ((count++))
    done
    
    # Force kill if still running
    if pgrep -x cloudflared > /dev/null; then
      log "Graceful shutdown failed, force killing..."
      pkill -9 -x cloudflared
      sleep 1
    fi
    
    log "cloudflared stopped"
  else
    log "cloudflared is not running"
  fi
}

main "$@"
