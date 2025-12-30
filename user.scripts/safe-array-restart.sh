#!/bin/bash
#
# safe-array-restart.sh - Safely restart the Unraid array
#
# This script is designed to be connection-safe. Even if Tailscale
# or SSH drops, the array WILL restart.
#
# Usage: ./safe-array-restart.sh
#

LOG="/boot/logs/array-restart-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /boot/logs

# Ensure this script continues even if terminal closes
trap '' HUP

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

restart_array() {
    log "=== SAFE ARRAY RESTART SCRIPT ==="
    log "Log file: $LOG"
    log ""
    
    # Record current state
    log "Current array state:"
    mdcmd status | grep -E "^(mdState|mdNumDisabled)" >> "$LOG" 2>&1
    log ""
    
    # Step 1: Stop the array
    log "Step 1: Stopping array..."
    if mdcmd stop; then
        log "✓ Array stop command issued successfully"
    else
        log "⚠ Array stop command returned error (may already be stopped)"
    fi
    
    # Step 2: Wait for array to fully stop (max 60 seconds)
    log "Step 2: Waiting for array to stop..."
    for i in {1..60}; do
        STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
        if [[ "$STATE" == "STOPPED" ]] || [[ -z "$STATE" ]]; then
            log "✓ Array stopped after ${i} seconds"
            break
        fi
        sleep 1
    done
    
    # Step 3: Wait additional time for disks to settle
    log "Step 3: Waiting 10 seconds for disks to settle..."
    sleep 10
    log "✓ Disk settle time complete"
    
    # Step 4: Start the array (with retries)
    log "Step 4: Starting array..."
    MAX_RETRIES=5
    RETRY_DELAY=10
    
    for attempt in $(seq 1 $MAX_RETRIES); do
        log "Start attempt $attempt of $MAX_RETRIES..."
        
        if mdcmd start; then
            log "✓ Array start command issued"
            
            # Wait for array to come up
            for i in {1..60}; do
                STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
                if [[ "$STATE" == "STARTED" ]]; then
                    log "✓ Array started successfully after ${i} seconds!"
                    log ""
                    log "=== RESTART COMPLETE ==="
                    log ""
                    log "Final array state:"
                    mdcmd status | grep -E "^(mdState|mdNumDisks|mdNumDisabled|mdNumInvalid)" >> "$LOG" 2>&1
                    log ""
                    log "Disk status:"
                    mdcmd status | grep -E "^(diskState|rdevStatus|rdevName)\.[0-9]+" | head -20 >> "$LOG" 2>&1
                    return 0
                fi
                sleep 1
            done
            log "⚠ Array did not start within 60 seconds, retrying..."
        else
            log "⚠ Array start command failed, retrying in ${RETRY_DELAY}s..."
        fi
        
        sleep $RETRY_DELAY
    done
    
    log "❌ FAILED to start array after $MAX_RETRIES attempts!"
    log "Manual intervention required. Check WebUI or run: mdcmd start"
    return 1
}

# Main execution
log "Script started by user"
log "This script will continue even if your connection drops."
log ""

# Run the restart in the background, completely detached
restart_array

log ""
log "Script completed. Check $LOG for full details."
