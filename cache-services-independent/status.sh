#!/bin/bash
# Show current status of cache-services-independent patches

echo "=== Cache Services Independent Status ==="
echo ""

# Check Docker patch
echo "Docker:"
if [ -f /etc/rc.d/rc.docker.original ]; then
    if grep -q "# PATCHED: Keep Docker running" /etc/rc.d/rc.docker; then
        echo "  ✓ Patched (will stay running when array stops)"
    else
        echo "  ⚠ Backup exists but not currently patched"
    fi
else
    echo "  ✗ Not patched (default Unraid behavior)"
fi

# Check VM patch
echo ""
echo "VMs (libvirt):"
if [ -f /etc/rc.d/rc.libvirt.original ]; then
    if grep -q "# PATCHED: Keep VMs running" /etc/rc.d/rc.libvirt; then
        echo "  ✓ Patched (will stay running when array stops)"
    else
        echo "  ⚠ Backup exists but not currently patched"
    fi
else
    echo "  ✗ Not patched (default Unraid behavior)"
fi

# Check running containers
echo ""
echo "=== Docker Containers ==="
TOTAL=$(docker ps --format '{{.Names}}' | wc -l)
echo "Total running: $TOTAL"

if [ $TOTAL -gt 0 ]; then
    echo ""
    echo "Checking for array mounts..."
    
    CONTAINERS=$(docker ps --format '{{.ID}}:{{.Names}}')
    KEEP_COUNT=0
    STOP_COUNT=0
    
    echo ""
    echo "Would KEEP running (cache pool only):"
    while IFS=: read -r ID NAME; do
        MOUNTS=$(docker inspect "$ID" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}')
        HAS_ARRAY_MOUNT=false
        
        while IFS= read -r MOUNT; do
            [ -z "$MOUNT" ] && continue
            if [[ "$MOUNT" =~ ^/mnt/ ]] && [[ ! "$MOUNT" =~ /mnt/[^/]+/(appdata|vmdrive) ]]; then
                HAS_ARRAY_MOUNT=true
                break
            fi
        done <<< "$MOUNTS"
        
        if [ "$HAS_ARRAY_MOUNT" = false ]; then
            echo "  ✓ $NAME"
            KEEP_COUNT=$((KEEP_COUNT + 1))
        fi
    done <<< "$CONTAINERS"
    
    echo ""
    echo "Would STOP (has array mounts):"
    while IFS=: read -r ID NAME; do
        MOUNTS=$(docker inspect "$ID" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}')
        HAS_ARRAY_MOUNT=false
        ARRAY_MOUNTS=()
        
        while IFS= read -r MOUNT; do
            [ -z "$MOUNT" ] && continue
            if [[ "$MOUNT" =~ ^/mnt/ ]] && [[ ! "$MOUNT" =~ /mnt/[^/]+/(appdata|vmdrive) ]]; then
                HAS_ARRAY_MOUNT=true
                ARRAY_MOUNTS+=("$MOUNT")
            fi
        done <<< "$MOUNTS"
        
        if [ "$HAS_ARRAY_MOUNT" = true ]; then
            echo "  ⏹ $NAME"
            for MOUNT in "${ARRAY_MOUNTS[@]}"; do
                echo "      → $MOUNT"
            done
            STOP_COUNT=$((STOP_COUNT + 1))
        fi
    done <<< "$CONTAINERS"
    
    echo ""
    echo "Summary: $KEEP_COUNT would keep running, $STOP_COUNT would stop"
fi

echo ""
echo "=== Actions Available ==="
echo "Install:   ./install.sh"
echo "Uninstall: ./uninstall.sh"
