#!/bin/bash
# Symlink all items from $PHOME to /root for easy access
# This makes persistent files available directly in /root

PHOME="${PHOME:-/mnt/pool/appdata/home}"

# Items to skip (handled separately or not needed in /root)
SKIP_ITEMS=(
    ".conf"           # Internal config, not needed in /root
    "phome-repo"      # Symlink loop
    "analysis"        # Accessed via docs or direct path
    "vscode-layouts"  # Not needed in /root
)

echo "Symlinking $PHOME contents to /root..."

for item in "$PHOME"/{.,}*; do
    # Skip . and ..
    [[ "$(basename "$item")" == "." ]] && continue
    [[ "$(basename "$item")" == ".." ]] && continue
    
    # Get item name
    item_name="$(basename "$item")"
    
    # Skip if in skip list
    skip=false
    for skip_item in "${SKIP_ITEMS[@]}"; do
        if [[ "$item_name" == "$skip_item" ]]; then
            skip=true
            break
        fi
    done
    $skip && continue
    
    # Skip if doesn't exist
    [[ ! -e "$item" ]] && continue
    
    target="/root/$item_name"
    
    # Check if already correct
    if [[ -L "$target" ]]; then
        current_target="$(readlink -f "$target")"
        expected_target="$(readlink -f "$item")"
        if [[ "$current_target" == "$expected_target" ]]; then
            continue
        fi
    fi
    
    # Remove existing target if it's a symlink
    [[ -L "$target" ]] && rm -f "$target"
    
    # Create symlink if target doesn't exist or is a symlink
    if [[ ! -e "$target" ]]; then
        ln -s "$item" "$target"
        echo "  ✓ $target -> $item"
    fi
done

echo "PHOME symlinks complete"
