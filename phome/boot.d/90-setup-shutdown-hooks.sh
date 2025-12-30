#!/bin/bash
# Script to setup shutdown hooks that run scripts in shutdown.d
# This patches the shutdown process to execute cleanup scripts before powerdown

SHUTDOWN_D="/mnt/pool/appdata/home/shutdown.d"

# Backup original rc.shutdown if not already backed up
if [ ! -f /etc/rc.d/rc.shutdown.original ]; then
    cp /etc/rc.d/rc.shutdown /etc/rc.d/rc.shutdown.original
fi

# Create wrapper that runs shutdown.d scripts before actual shutdown
cat > /etc/rc.d/rc.shutdown.wrapper << 'WRAPPER_EOF'
#!/bin/bash
# Wrapper to run shutdown.d scripts before shutdown

SHUTDOWN_D="/mnt/pool/appdata/home/shutdown.d"
ORIGINAL_SCRIPT="/etc/rc.d/rc.shutdown.original"

# Run all scripts in shutdown.d if directory exists
if [ -d "$SHUTDOWN_D" ]; then
    logger "Running shutdown.d scripts..."
    for script in "$SHUTDOWN_D"/*.sh; do
        if [ -x "$script" ]; then
            logger "Executing shutdown script: $script"
            "$script"
        fi
    done
    logger "Completed shutdown.d scripts"
fi

# Execute original shutdown script
exec $ORIGINAL_SCRIPT "$@"
WRAPPER_EOF

chmod +x /etc/rc.d/rc.shutdown.wrapper

# Replace rc.shutdown with our wrapper
cp /etc/rc.d/rc.shutdown.wrapper /etc/rc.d/rc.shutdown

echo "Shutdown hooks configured - scripts in $SHUTDOWN_D will run on system shutdown"
echo "To revert: cp /etc/rc.d/rc.shutdown.original /etc/rc.d/rc.shutdown"
