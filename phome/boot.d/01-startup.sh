#!/bin/bash
#
# startup.sh - Git and logging configuration
# Called from shell_startup via boot.d
CALLING_SCRIPT=${1:-/boot/config/plugins/user.scripts/scripts/shell_startup/script}
ENV_FILE="$(dirname "$CALLING_SCRIPT")/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo "Found .env at $ENV_FILE, loading..."
    set -a  # automatically export all variables
    source "$ENV_FILE"
    set +a
fi

PHOME_DEFAULT=${PHOME:-"$(dirname "$(readlink -f "$0")")"}
# Source .env if it exists, then ensure PHOME is set
ENV_FILE="${PHOME_DEFAULT}/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo "Found .env at $ENV_FILE, loading..."
    set -a  # automatically export all variables
    source "$ENV_FILE"
    set +a
else
    echo "No .env found at $PHOME_DEFAULT/.env"
fi
if [[ -z "$PHOME" ]]; then
    export PHOME="$PHOME_DEFAULT"
    # Ensure PHOME is in .env for persistence
    export ENV_FILE="${PHOME}/.env"
    if [[ -f "$ENV_FILE" ]] && ! grep -q "^PHOME=" "$ENV_FILE"; then
        echo "PHOME=$PHOME" >> "$ENV_FILE"
        echo "ENV_FILE=$ENV_FILE" >> "$ENV_FILE"
        echo "  Added PHOME to .env"
    elif [[ ! -f "$ENV_FILE" ]]; then
        mkdir -p "$(dirname "$ENV_FILE")"
        echo "PHOME=$PHOME" > "$ENV_FILE"
        echo "ENV_FILE=$ENV_FILE" >> "$ENV_FILE"
        echo "  Created .env with PHOME"
    fi
fi
if [[ -z "$SCRIPTS_DIR" ]]; then
    SCRIPTS_DIR=$(dirname "$(dirname "$(dirname "$1")")")
    if [[ -z "$SCRIPTS_DIR" ]]; then
        SCRIPTS_DIR="/boot/config/plugins/user.scripts/scripts"
    fi
    echo "SCRIPTS_DIR=$SCRIPTS_DIR" >> "$ENV_FILE"
    echo "  Added SCRIPTS_DIR to .env"
fi

# === FIX /etc/profile ===
# Unraid's default profile has 'cd $HOME' which breaks VS Code Remote SSH
echo "Fixing /etc/profile..."
if grep -q '^cd \$HOME$' /etc/profile 2>/dev/null; then
    sed -i '/^cd \$HOME$/d' /etc/profile
    echo "  Removed 'cd \$HOME' from /etc/profile"
else
    echo "  /etc/profile already fixed"
fi

# Bootstrap pln first (can't use pln to create itself)
cat > /usr/local/bin/lnp << EOF
#!/bin/bash
exec bash "$PHOME/.local/bin/lnp.sh" "\$@"
EOF
chmod +x /usr/local/bin/lnp
echo "  /usr/local/bin/lnp -> lnp.sh (wrapper)"

lnp --apply

# Git configuration
if [[ -n "$GIT_AUTHOR_EMAIL" ]]; then
    git config --global user.email "$GIT_AUTHOR_EMAIL"
    echo "  Git email: $GIT_AUTHOR_EMAIL"
fi
if [[ -n "$GIT_AUTHOR_NAME" ]]; then
    git config --global user.name "$GIT_AUTHOR_NAME"
    echo "  Git name: $GIT_AUTHOR_NAME"
fi

git config --global init.defaultBranch main

# Increase /var/log tmpfs to 1GB (default 128MB fills up quickly)
current_size=$(df /var/log | awk 'NR==2 {print $2}')
if [[ "$current_size" -lt 1000000 ]]; then
    mount -o remount,size=1G /var/log
    echo "  Increased /var/log to 1GB"
else
    echo "  /var/log already sized appropriately"
fi