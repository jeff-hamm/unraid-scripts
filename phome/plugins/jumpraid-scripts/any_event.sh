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

# Delegate to event-specific scripts in PHOME/event.d/starting|stopping/<numbered-event>/
# Event directories are organized by lifecycle phase:
#   starting/04-disks_mounted/*.sh
#   stopping/05-unmounting_disks/*.sh
# Search both starting/ and stopping/ for matching event directories
for phase_dir in "$EVENT_D"/starting "$EVENT_D"/stopping; do
    [[ -d "$phase_dir" ]] || continue
    
    # Find directories matching the event name (with or without number prefix)
    # e.g., "disks_mounted" matches "04-disks_mounted"
    for event_dir in "$phase_dir"/*-"$EVENT" "$phase_dir"/"$EVENT"; do
        [[ -d "$event_dir" ]] || continue
        
        log "Checking: $event_dir"
        for script in "$event_dir"/*.sh; do
            [[ -x "$script" ]] || continue
            log "Running: $script"
            if "$script" "$@" >> "$BOOT_LOG" 2>&1; then
                log "  ✓ $script completed"
            else
                log "  ✗ $script failed (exit: $?)"
            fi
        done
    done
done
