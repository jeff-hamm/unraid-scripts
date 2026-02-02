#!/bin/bash
# Script to prevent Docker from stopping when array stops
# This patches the array stop process to skip Docker shutdown

. app-envs 2>/dev/null || PHOME="${PHOME:-/mnt/pool/appdata/home}"
SHUTDOWN_D="$PHOME/shutdown.d"

# Backup original rc.docker if not already backed up
if [ ! -f /etc/rc.d/rc.docker.original ]; then
    cp /etc/rc.d/rc.docker /etc/rc.d/rc.docker.original
fi

# Create a wrapper that ignores stop commands from array
cat > /etc/rc.d/rc.docker.wrapper << 'EOF'
#!/bin/bash
# Wrapper to prevent array from stopping Docker

# Source the original rc.docker functions
ORIGINAL_SCRIPT="/etc/rc.d/rc.docker.original"
SHUTDOWN_D="/mnt/pool/appdata/home/shutdown.d"

# Check if this is being called during array stop
# by checking the calling process
CALLER=$(ps -o comm= $PPID)

case "$1" in
'stop'|'restart')
  # Run shutdown.d scripts on array stop BEFORE Docker would stop
  if [[ "$CALLER" == "emhttp" ]] || [[ "$CALLER" == "mdcmd" ]]; then
    if [ -d "$SHUTDOWN_D" ]; then
      logger "[array-stop] Running shutdown.d scripts..."
      for script in "$SHUTDOWN_D"/*.sh; do
        if [ -x "$script" ]; then
          logger "[array-stop] Executing: $script"
          MODE="array-stop" "$script" || logger "[array-stop] WARNING: $script returned error"
        fi
      done
      logger "[array-stop] Completed shutdown.d scripts"
    fi
  fi

  # Allow genuine powerdown/reboot paths to stop Docker cleanly
  if [[ "$CALLER" =~ ^(powerdown|reboot|shutdown|init|rc\.6|rc\.K|rc\.shutdown)$ ]]; then
    exec $ORIGINAL_SCRIPT "$@"
  fi

  # If called from emhttp/mdcmd (array operations), skip Docker stop
  if [[ "$CALLER" == "emhttp" ]] || [[ "$CALLER" == "mdcmd" ]] || pgrep -f "mdcmd stop" > /tmp/mdcmd.check; then
    logger "Array is stopping but keeping Docker running (cache pool independent)"
    exit 0
  fi

  # Otherwise, allow normal Docker stop (manual or system shutdown)
  exec $ORIGINAL_SCRIPT "$@"
  ;;
*)
  # Pass through all other commands
  exec $ORIGINAL_SCRIPT "$@"
  ;;
esac
EOF

chmod +x /etc/rc.d/rc.docker.wrapper

# Replace rc.docker with our wrapper
cp /etc/rc.d/rc.docker.wrapper /etc/rc.d/rc.docker

echo "Docker will now stay running when array stops"
echo "Docker runs on: $(docker info 2>&1 | grep 'Docker Root Dir')"
echo ""
echo "To revert: cp /etc/rc.d/rc.docker.original /etc/rc.d/rc.docker"
