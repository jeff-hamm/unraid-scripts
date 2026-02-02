#!/bin/bash
#
PHOME="${PHOME:-/mnt/pool/appdata/home}"

# Source app-envs if available
if command -v app-envs &>/dev/null; then
    . app-envs
elif [ -f "$PHOME/.local/bin/app-envs" ]; then
    . "$PHOME/.local/bin/app-envs"
fi

# === RUN BOOT.D SCRIPTS ===
BOOT_D="${PHOME}/boot.d"
if [[ -d "$BOOT_D" ]]; then
    echo "Running boot.d scripts..."
    for script in "$BOOT_D"/*.sh; do
        if [[ -x "$script" ]]; then
            echo "  Running $(basename "$script")..."
            source "$script" "$STARTUP_SCRIPT"
        fi
    done
fi
