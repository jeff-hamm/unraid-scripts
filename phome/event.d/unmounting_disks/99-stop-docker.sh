#!/bin/bash
# 99-stop-docker.sh - Gracefully stop Docker on system shutdown/reboot
# This runs LAST in shutdown.d (99-) to allow other scripts to use Docker first
#
# On shutdown/reboot: Stop ALL containers and Docker daemon
# On array-stop: Stop only containers with mounts outside APP_ROOT (they need array)

# Source app-envs directly (not through wrapper) to avoid stdout pollution
PHOME="${PHOME:-/mnt/pool/appdata/home}"
if [[ -f "$PHOME/.local/bin/app-envs" ]]; then
    source "$PHOME/.local/bin/app-envs"
fi
APP_ROOT="${APP_ROOT:-/mnt/pool/appdata}"
ORIGINAL_SCRIPT="/etc/rc.d/rc.docker.original"
DOCKER_TIMEOUT="${DOCKER_TIMEOUT:-30}"

log() {
    echo "[99-stop-docker] $*"
    logger -t stop-docker "$*"
}

# Check if Docker is running
if ! pgrep -x dockerd > /dev/null 2>&1; then
    log "Docker is not running, nothing to stop"
    exit 0
fi

# Get containers with volume mounts outside of APP_ROOT
# These containers depend on the array and must be stopped before array-stop
get_array_dependent_containers() {
    local containers=""
    for container_id in $(docker ps -q 2>/dev/null); do
        # Get all bind mount sources for this container
        local mounts=$(docker inspect "$container_id" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}{{"\n"}}{{end}}{{end}}' 2>/dev/null)
        
        while IFS= read -r mount_path; do
            [[ -z "$mount_path" ]] && continue
            
            # Check if mount is outside APP_ROOT (i.e., depends on array)
            # Array paths: /mnt/user/*, /mnt/disk*/*
            # Cache paths: /mnt/pool/*, APP_ROOT/*
            if [[ "$mount_path" == /mnt/user/* ]] || [[ "$mount_path" == /mnt/disk* ]]; then
                containers="$containers $container_id"
                break  # Found one array mount, no need to check more
            fi
        done <<< "$mounts"
    done
    echo "$containers" | xargs  # trim whitespace
}

# Array-stop mode: only stop containers that need the array
if [[ "${MODE:-}" == "array-stop" ]]; then
    log "Array-stop mode: checking for containers with array mounts..."
    
    ARRAY_CONTAINERS=$(get_array_dependent_containers)
    
    if [[ -z "$ARRAY_CONTAINERS" ]]; then
        log "No containers have mounts outside $APP_ROOT, nothing to stop"
        exit 0
    fi
    
    log "Stopping containers with array mounts: $ARRAY_CONTAINERS"
    docker stop -t "$DOCKER_TIMEOUT" $ARRAY_CONTAINERS 2>&1 | while read line; do
        log "  $line"
    done
    
    log "Array-dependent containers stopped, Docker daemon stays running"
    exit 0
fi

# Full shutdown mode: stop everything
log "Stopping Docker gracefully (timeout: ${DOCKER_TIMEOUT}s)..."

# Stop all containers first with timeout
if command -v docker &> /dev/null; then
    RUNNING=$(docker ps -q 2>/dev/null)
    if [[ -n "$RUNNING" ]]; then
        log "Stopping $(echo "$RUNNING" | wc -l) running container(s)..."
        docker stop -t "$DOCKER_TIMEOUT" $RUNNING 2>&1 | while read line; do
            log "  $line"
        done
    fi
fi

# Now stop the Docker daemon using original script
if [[ -x "$ORIGINAL_SCRIPT" ]]; then
    log "Stopping Docker daemon via rc.docker.original..."
    "$ORIGINAL_SCRIPT" stop
else
    log "WARNING: $ORIGINAL_SCRIPT not found, using pkill"
    pkill -SIGTERM dockerd
    sleep 5
    pkill -SIGKILL dockerd 2>/dev/null
fi

log "Docker shutdown complete"
