#!/bin/bash
# Stop containers that have array volume mounts
# Keep containers that only use cache pool (appdata/vmdrive)

logger "Checking for containers with array mounts..."

# Get all running containers
CONTAINERS=$(docker ps --format '{{.ID}}:{{.Names}}')

if [ -z "$CONTAINERS" ]; then
    logger "No running containers to check"
    exit 0
fi

# Track containers to stop
STOP_LIST=()

while IFS=: read -r ID NAME; do
    # Get all volume mounts for this container
    MOUNTS=$(docker inspect "$ID" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}')
    
    # Check if any mount is to the array (not cache pool)
    HAS_ARRAY_MOUNT=false
    
    while IFS= read -r MOUNT; do
        # Skip empty lines
        [ -z "$MOUNT" ] && continue
        
        # Check if mount is under /mnt/
        if [[ "$MOUNT" =~ ^/mnt/ ]]; then
            # Exclude appdata and vmdrive (these are typically on cache)
            if [[ ! "$MOUNT" =~ /mnt/[^/]+/(appdata|vmdrive) ]]; then
                # This is an array mount (e.g., /mnt/user/media, /mnt/disk1/data, etc.)
                HAS_ARRAY_MOUNT=true
                logger "Container $NAME has array mount: $MOUNT"
                break
            fi
        fi
    done <<< "$MOUNTS"
    
    if [ "$HAS_ARRAY_MOUNT" = true ]; then
        STOP_LIST+=("$ID:$NAME")
    fi
done <<< "$CONTAINERS"

# Stop containers with array mounts
if [ ${#STOP_LIST[@]} -gt 0 ]; then
    echo "Stopping containers with array mounts:"
    for CONTAINER in "${STOP_LIST[@]}"; do
        ID="${CONTAINER%%:*}"
        NAME="${CONTAINER#*:}"
        echo "  - $NAME"
        logger "Stopping container $NAME (has array mounts)"
        docker stop "$ID" -t 30
    done
else
    echo "No containers need to be stopped (all use cache pool only)"
    logger "No containers with array mounts found"
fi
