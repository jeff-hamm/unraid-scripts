#!/bin/bash
# Stop code-server on shutdown/array-stop

log() {
  local mode="${MODE:-unknown}"
  echo "[code-server:$mode] $*"
  logger -t "code-server:$mode" "$*"
}

main() {
  log "Stopping code-server..."
  
  # Find and kill code-server processes
  if pgrep -f "code-server-.*-linux-amd64" > /dev/null; then
    local pid=$(pgrep -f "code-server-.*-linux-amd64")
    log "Found code-server running (PID: $pid)"
    
    pkill -f "code-server-.*-linux-amd64"
    sleep 1
    
    # Force kill if still running
    if pgrep -f "code-server-.*-linux-amd64" > /dev/null; then
      log "Graceful shutdown failed, force killing..."
      pkill -9 -f "code-server-.*-linux-amd64"
    fi
    
    log "code-server stopped"
  else
    log "code-server is not running"
  fi
}

main "$@"
