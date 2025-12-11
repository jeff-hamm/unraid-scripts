#!/bin/bash
# Install: Make Docker and VMs independent from array state
# Applies patches to rc.docker and rc.libvirt

echo "Installing cache-services-independent patches..."
echo ""

CHANGED=0
ERRORS=0

# === DOCKER ===
echo "Patching Docker..."
if [ ! -f /etc/rc.d/rc.docker.original ]; then
    if cp -p /etc/rc.d/rc.docker /etc/rc.d/rc.docker.original; then
        logger "cache-services-independent: Backed up original rc.docker"
        echo "  ✓ Backed up rc.docker"
    else
        echo "  ✗ Failed to backup rc.docker"
        ERRORS=$((ERRORS + 1))
    fi
fi

if ! grep -q "# PATCHED: Keep Docker running" /etc/rc.d/rc.docker; then
    cat > /tmp/rc.docker.patched << 'DOCKERPATCH'
#!/bin/bash
# PATCHED: Keep Docker running when array stops (Docker on cache pool)

# Check if this is an array-stop operation
PARENT_CMD=$(ps -o args= $PPID | head -1)
if [[ "$1" == "stop" ]] && [[ "$PARENT_CMD" =~ (mdcmd|emhttp|array) ]]; then
    logger "Array stopping but keeping Docker running (cache pool independent)"
    echo "Docker staying active - runs on cache pool, not array"
    
    # Stop containers that have array mounts (not appdata/vmdrive)
    /boot/config/plugins/user.scripts/scripts/cache-services-independent/stop-array-containers.sh
    
    exit 0
fi

# Otherwise, source and run the original script
source /etc/rc.d/rc.docker.original
DOCKERPATCH
    
    if cp /tmp/rc.docker.patched /etc/rc.d/rc.docker && chmod +x /etc/rc.d/rc.docker; then
        logger "cache-services-independent: Docker configured to stay running when array stops"
        echo "  ✓ Docker patched successfully"
        CHANGED=1
    else
        echo "  ✗ Failed to patch Docker"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ✓ Docker already patched"
fi

# === VMs (LIBVIRT) ===
echo ""
echo "Patching VMs (libvirt)..."
if [ ! -f /etc/rc.d/rc.libvirt.original ]; then
    if cp -p /etc/rc.d/rc.libvirt /etc/rc.d/rc.libvirt.original; then
        logger "cache-services-independent: Backed up original rc.libvirt"
        echo "  ✓ Backed up rc.libvirt"
    else
        echo "  ✗ Failed to backup rc.libvirt"
        ERRORS=$((ERRORS + 1))
    fi
fi

if ! grep -q "# PATCHED: Keep VMs running" /etc/rc.d/rc.libvirt; then
    cat > /tmp/rc.libvirt.patched << 'VMPATCH'
#!/bin/bash
# PATCHED: Keep VMs running when array stops (VMs on cache pool)

# Check if this is an array-stop operation
PARENT_CMD=$(ps -o args= $PPID | head -1)
if [[ "$1" == "stop" ]] && [[ "$PARENT_CMD" =~ (mdcmd|emhttp|array) ]]; then
    logger "Array stopping but keeping VMs running (cache pool independent)"
    echo "VMs staying active - stored on cache pool, not array"
    exit 0
fi

# Otherwise, source and run the original script
source /etc/rc.d/rc.libvirt.original "$@"
VMPATCH

    if cp /tmp/rc.libvirt.patched /etc/rc.d/rc.libvirt && chmod +x /etc/rc.d/rc.libvirt; then
        logger "cache-services-independent: VMs configured to stay running when array stops"
        echo "  ✓ VMs patched successfully"
        CHANGED=1
    else
        echo "  ✗ Failed to patch VMs"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ✓ VMs already patched"
fi

# Summary
echo ""
if [ $ERRORS -gt 0 ]; then
    echo "Installation completed with $ERRORS error(s)"
    exit 1
elif [ $CHANGED -eq 1 ]; then
    echo "✓ Installation successful!"
    echo ""
    echo "Docker and VMs now run independently from array state"
    echo "  - Services on cache pool stay running"
    echo "  - Containers with array mounts will be stopped"
    echo ""
    echo "To uninstall, run the uninstall script"
else
    echo "✓ Already installed"
fi
