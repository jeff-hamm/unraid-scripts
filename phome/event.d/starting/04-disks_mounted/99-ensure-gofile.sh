# === ENSURE GO FILE IS CONFIGURED ===
GO_FILE="/boot/config/go"
REQUIRED_LINE="bash /boot/config/plugins/user.scripts/scripts/shell_startup/script /mnt/pool/appdata/home"

if [[ -f "$GO_FILE" ]]; then
    # Check if the correct line exists
    if ! grep -qF "$REQUIRED_LINE" "$GO_FILE"; then
        echo "Adding shell_startup to $GO_FILE..."
        
        # Remove old 'source' line if it exists
        if grep -qF "source /boot/config/plugins/user.scripts/scripts/shell_startup/script" "$GO_FILE"; then
            sed -i '\|source /boot/config/plugins/user.scripts/scripts/shell_startup/script|d' "$GO_FILE"
            echo "  Removed old 'source' line"
        fi
        
        # Add the correct line
        cat >> "$GO_FILE" << EOF

# === SHELL STARTUP ===
# Run the shell_startup script for symlinks, bashrc, profile.d, env vars
# This also runs scripts from /mnt/pool/appdata/home/boot.d/ including:
#   - startup.sh (git config, /var/log resize)
#   - install-bluez.sh (Bluetooth stack for Home Assistant Docker)
$REQUIRED_LINE
EOF
        echo "  Added shell_startup to go file"
    else
        echo "Shell startup already configured in go file"
    fi
else
    echo "Warning: $GO_FILE not found"
fi
