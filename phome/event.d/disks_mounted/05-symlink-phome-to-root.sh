#                   !/bin/bash
# Symlink all items from $PHOME to /root for easy access
# This makes persistent files available directly in /root

PHOME="${PHOME:-/mnt/pool/appdata/home}"
[ -f "$PHOME/.local/bin/app-envs" ] && . "$PHOME/.local/bin/app-envs"

# Items to skip (handled separately or not needed in /root)
SKIP_ITEMS=(
    ".conf"           # Internal config, not needed in /root
    "phome-repo"      # Symlink loop
    "analysis"        # Accessed via docs or direct path
    "vscode-layouts"  # Not needed in /root
)

echo "Symlinking $PHOME contents to /root..."

backup_existing() {
    local target="$1"
    local backup="${target}.existing"
    if [[ -e "$backup" ]]; then
        backup="${target}.existing.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$target" "$backup"
    echo "  ! backed up existing $target -> $backup"
}

sync_dir_contents() {
    local src_dir="$1"
    local dst_dir="$2"

    mkdir -p "$dst_dir"
    rsync -a --backup --suffix=.existing "$src_dir"/ "$dst_dir"/
    echo "  ✓ merged $src_dir -> $dst_dir (backups with .existing)"
}

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
    
    # If target exists and is not a symlink, handle according to type
    if [[ -e "$target" && ! -L "$target" ]]; then
        if [[ -d "$target" && -d "$item" ]]; then
            sync_dir_contents "$item" "$target"
            continue
        fi
        backup_existing "$target"
    fi

    # Remove existing target if it's a symlink
    [[ -L "$target" ]] && rm -f "$target"

    # Create symlink if target doesn't exist
    if [[ ! -e "$target" ]]; then
        ln -s "$item" "$target"
        echo "  ✓ $target -> $item"
    fi
done

echo "PHOME symlinks complete"
