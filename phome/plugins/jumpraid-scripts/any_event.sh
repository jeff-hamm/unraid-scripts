#!/bin/bash
#
# jumpraid-scripts: Universal event handler
# Logs all emhttpd events and delegates to PHOME handlers
#
# Called by /usr/local/sbin/emhttp_event with event name as $1
# Additional args may follow depending on the event
#

EVENT="${1:-unknown}"
BOOT_LOG="/root/boot.log"
PHOME="${PHOME:-/mnt/pool/appdata/home}"
EVENT_D="${PHOME}/event.d"

# Skip noisy events that happen frequently
case "$EVENT" in
    poll_attributes)
        # SMART polling happens frequently, don't log
        exit 0
        ;;
esac

# Log the event
log() {
    local msg="[jumpraid-scripts] $*"
    echo "$msg" >> "$BOOT_LOG"
    logger -t "jumpraid-scripts" "$*"
}

log "Event received: $EVENT (args: $*)"

# Delegate to event-specific scripts in PHOME/event.d/<event>/
# e.g., /mnt/pool/appdata/home/event.d/disks_mounted/*.sh
EVENT_DIR="${EVENT_D}/${EVENT}"
if [[ -d "$EVENT_DIR" ]]; then
    for script in "$EVENT_DIR"/*.sh; do
        [[ -x "$script" ]] || continue
        log "Running: $script"
        if "$script" "$@" >> "$BOOT_LOG" 2>&1; then
            log "  ✓ $script completed"
        else
            log "  ✗ $script failed (exit: $?)"
        fi
    done
fi
