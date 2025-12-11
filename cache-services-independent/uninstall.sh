#!/bin/bash
# Uninstall: Restore original Docker and VM behavior

echo "Uninstalling cache-services-independent patches..."
echo ""

CHANGED=0
ERRORS=0

# === DOCKER ===
echo "Restoring Docker..."
if [ -f /etc/rc.d/rc.docker.original ]; then
    if cp -p /etc/rc.d/rc.docker.original /etc/rc.d/rc.docker; then
        rm -f /etc/rc.d/rc.docker.original
        logger "cache-services-independent: Restored original rc.docker"
        echo "  ✓ Docker restored to original"
        CHANGED=1
    else
        echo "  ✗ Failed to restore Docker"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  - No Docker backup found (not installed or already uninstalled)"
fi

# === VMs (LIBVIRT) ===
echo ""
echo "Restoring VMs (libvirt)..."
if [ -f /etc/rc.d/rc.libvirt.original ]; then
    if cp -p /etc/rc.d/rc.libvirt.original /etc/rc.d/rc.libvirt; then
        rm -f /etc/rc.d/rc.libvirt.original
        logger "cache-services-independent: Restored original rc.libvirt"
        echo "  ✓ VMs restored to original"
        CHANGED=1
    else
        echo "  ✗ Failed to restore VMs"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  - No VM backup found (not installed or already uninstalled)"
fi

# Summary
echo ""
if [ $ERRORS -gt 0 ]; then
    echo "Uninstallation completed with $ERRORS error(s)"
    exit 1
elif [ $CHANGED -eq 1 ]; then
    echo "✓ Uninstallation successful!"
    echo ""
    echo "Docker and VMs will now stop with the array (default Unraid behavior)"
else
    echo "Nothing to uninstall (patches not found)"
fi
