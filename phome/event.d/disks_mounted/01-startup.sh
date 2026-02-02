#!/bin/bash
#
# startup.sh - Git and logging configuration
# Called from shell_startup via boot.d

PHOME="${PHOME:-/mnt/pool/appdata/home}"
echo "Using PHOME: $PHOME"
if [ -f "$PHOME/.local/bin/app-envs" ]; then
    . "$PHOME/.local/bin/app-envs"
elif command -v app-envs &>/dev/null; then
    . app-envs
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

# Bootstrap lnp first (can't use lnp to create itself)
cat > /usr/local/bin/lnp << EOF
#!/usr/bin/env zsh
exec zsh "$PHOME/.local/bin/lnp.sh" "\$@"
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