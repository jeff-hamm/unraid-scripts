#!/bin/bash
# Script to setup shutdown hooks that run scripts in shutdown.d
# This uses /boot/config/stop which is called by rc.local_shutdown before array stop
# Array-stop hooks are handled separately by 95-keep-docker-running.sh via rc.docker wrapper

. app-envs 2>/dev/null || PHOME="${PHOME:-/mnt/pool/appdata/home}"
SHUTDOWN_D="$PHOME/shutdown.d"

# Create /boot/config/stop script (called by rc.local_shutdown on shutdown/reboot)
# This file is on the flash drive so it persists, but we ensure it's correct on every boot
cat > /boot/config/stop << 'STOP_EOF'
#!/bin/bash
# Run shutdown.d scripts on system shutdown/reboot
# This is called by /etc/rc.d/rc.local_shutdown before array stop

SHUTDOWN_D="/mnt/pool/appdata/home/shutdown.d"

logger "[shutdown] Running shutdown.d scripts from /boot/config/stop..."

if [ -d "$SHUTDOWN_D" ]; then
    for script in "$SHUTDOWN_D"/*.sh; do
        if [ -x "$script" ]; then
            logger "[shutdown] Executing: $script"
            MODE="shutdown" "$script" 2>&1 | logger -t "shutdown.d" || logger "[shutdown] WARNING: $script returned error"
        fi
    done
    logger "[shutdown] Completed shutdown.d scripts"
else
    logger "[shutdown] WARNING: $SHUTDOWN_D does not exist"
fi
STOP_EOF

chmod +x /boot/config/stop

echo "Shutdown hooks configured:"
echo "  - System shutdown/reboot: /boot/config/stop runs $SHUTDOWN_D scripts with MODE=shutdown"
echo "  - Array stop: handled by 95-keep-docker-running.sh (scripts run with MODE=array-stop)"
