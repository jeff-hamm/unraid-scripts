#!/bin/bash
# Start pool-only containers when array is down but cache pool is available
# This provides resilience when the main array has issues but cache pool works

set -e

LOG_TAG="[pool-only-containers]"

log() {
    echo "$LOG_TAG $*"
}

# Check if array is mounted
if mountpoint -q /mnt/user 2>/dev/null; then
    log "Array is mounted, normal boot - skipping pool-only mode"
    exit 0
fi

log "Array is NOT mounted - checking for cache pool availability"

# Check if pool is available
if [ ! -d /mnt/pool/appdata ]; then
    log "Cache pool not available (/mnt/pool/appdata missing) - cannot start containers"
    exit 1
fi

log "Cache pool is available - entering pool-only container mode"

# Wait for docker to be available (it may be starting)
max_wait=30
waited=0
while ! docker info >/dev/null 2>&1; do
    if [ $waited -ge $max_wait ]; then
        log "Docker daemon not ready after ${max_wait}s, attempting to start it"
        /etc/rc.d/rc.docker start || true
        sleep 5
        break
    fi
    log "Waiting for Docker daemon... (${waited}s)"
    sleep 2
    waited=$((waited + 2))
done

# Verify docker is actually running
if ! docker info >/dev/null 2>&1; then
    log "ERROR: Docker daemon failed to start"
    exit 1
fi

log "Docker daemon is ready"

# Get list of all containers
containers=$(docker ps -a --format '{{.Names}}' 2>/dev/null)

if [ -z "$containers" ]; then
    log "No containers found"
    exit 0
fi

started_count=0
skipped_count=0

for container in $containers; do
    # Get bind mounts for this container (Source paths)
    # We look at both Mounts and HostConfig.Binds to catch all cases
    mounts=$(docker inspect "$container" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{end}}{{end}}' 2>/dev/null)
    
    # Check if container has any mounts
    if [ -z "$mounts" ]; then
        log "Starting $container (no bind mounts)"
        docker start "$container" >/dev/null 2>&1 && started_count=$((started_count + 1))
        continue
    fi
    
    # Check if all bind mounts are under /mnt/pool
    pool_only=true
    IFS='|'
    for mount in $mounts; do
        # Skip empty entries
        [ -z "$mount" ] && continue
        
        # Check if mount is under /mnt/pool or /mnt/cache
        if [[ ! "$mount" =~ ^/mnt/pool ]] && [[ ! "$mount" =~ ^/mnt/cache ]]; then
            pool_only=false
            log "Skipping $container (has mount outside pool: $mount)"
            skipped_count=$((skipped_count + 1))
            break
        fi
    done
    unset IFS
    
    if [ "$pool_only" = true ]; then
        log "Starting $container (all mounts on pool)"
        docker start "$container" >/dev/null 2>&1 && started_count=$((started_count + 1))
    fi
done

log "Pool-only mode complete: started $started_count containers, skipped $skipped_count"
