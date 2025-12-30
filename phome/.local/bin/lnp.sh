#!/bin/bash
#
# lnp - Persistent Symlink Manager
# Creates symlinks and optionally adds them to shell_startup's symlinks.conf
# Usage: lnp <source> <target> [-p|--persist]
#

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_SYMLINKS_CONF=${PHOME:-/mnt/pool/appdata/home}/.conf/symlinks.conf
SYMLINKS_CONF="${SYMLINKS_CONF:-$DEFAULT_SYMLINKS_CONF}"
usage() {
    cat << 'EOF'
lnp - Persistent Symlink Manager

Usage: lnp <source> <target> [-p|--persist]
       lnp -l|--list
       lnp -a|--apply [config_file]

Options:
  -p, --persist    Add symlink to symlinks.conf for persistence across reboots
  -l, --list       List all configured symlinks
  -a, --apply      Apply all symlinks from symlinks.conf
  -h, --help       Show this help

Examples:
  lnp /mnt/pool/data /root/data              # Create symlink (session only)
  lnp /mnt/pool/data /root/data -p           # Create and persist
  lnp script.sh /usr/local/bin/mycmd -p      # Creates wrapper script for bin/

Notes:
  - Targets in */bin/* directories get wrapper scripts (FAT32 compatibility)
  - Use $APP_ROOT, $SCRIPTS_DIR, $STARTUP_SCRIPT_DIR in symlinks.conf
EOF
}

# Expand variables in a string
expand_vars() {
    # Use eval to expand all environment variables
    eval echo "\"$1\""
}

# Compress path back to variables for storage
compress_vars() {
    local str="$1"
    # Order matters - most specific first
    str="${str//$STARTUP_SCRIPT_DIR/\$STARTUP_SCRIPT_DIR}"
    str="${str//$SCRIPTS_DIR/\$SCRIPTS_DIR}"
    str="${str//$APP_ROOT/\$APP_ROOT}"
    str="${str//$PHOME/\$PHOME}"
    echo "$str"
}

# Create a single symlink or wrapper
create_link() {
    local source="$1"
    local target="$2"
    
    if [[ ! -e "$source" ]]; then
        echo "SKIP: $source (not found)"
        return 0
    fi
    
    # Check if target already exists and points to the right place
    if [[ -L "$target" ]]; then
        local current_target="$(readlink -f "$target")"
        local expected_target="$(readlink -f "$source")"
        if [[ "$current_target" == "$expected_target" ]]; then
            echo "OK: $target -> $source (already correct)"
            return 0
        fi
    fi
    
    # Check if target is in a bin directory
    if [[ "$target" == */bin/* ]]; then
        # Create wrapper script
        local canonical_source="$(readlink -f "$source")"
        local shebang=$(head -1 "$canonical_source" 2>/dev/null)
        local interpreter="bash"
        
        case "$shebang" in
            *python3*|*python*) interpreter="python3" ;;
            *bash*) interpreter="bash" ;;
            *sh*) interpreter="sh" ;;
        esac
        
        rm -f "$target"
        cat > "$target" << EOF
#!/bin/bash
exec $interpreter "$canonical_source" "\$@"
EOF
        chmod +x "$target"
        echo "Created wrapper: $target -> $canonical_source ($interpreter)"
    else
        # Handle existing target
        if [[ -e "$target" && ! -L "$target" ]]; then
            # It's a real file or directory, not a symlink
            if [[ -d "$target" ]]; then
                # Directory - check if non-empty
                if [[ -n "$(ls -A "$target" 2>/dev/null)" ]]; then
                    mv "$target" "${target}.replaced"
                    echo "Renamed existing directory: $target -> ${target}.replaced"
                else
                    rm -rf "$target"
                fi
            elif [[ -s "$target" ]]; then
                # Non-empty file
                mv "$target" "${target}.replaced"
                echo "Renamed existing file: $target -> ${target}.replaced"
            else
                # Empty file
                rm -f "$target"
            fi
        else
            # Symlink or doesn't exist - safe to remove
            rm -f "$target" 2>/dev/null
        fi
        
        ln -s "$source" "$target"
        echo "Created symlink: $target -> $source"
    fi
}

# Add entry to symlinks.conf
add_to_conf() {
    local source="$1"
    local target="$2"
    
    # Compress to use variables
    local conf_source=$(compress_vars "$source")
    local conf_target=$(compress_vars "$target")
    local entry="$conf_source,$conf_target"
    
    # Check if already exists
    if grep -qF "$conf_target" "$SYMLINKS_CONF" 2>/dev/null; then
        echo "Already in symlinks.conf: $conf_target"
        return 0
    fi
    
    # Append to file
    echo "$entry" >> "$SYMLINKS_CONF"
    echo "Added to symlinks.conf: $entry"
}

# List all configured symlinks
list_symlinks() {
    echo "Configured symlinks in $SYMLINKS_CONF:"
    echo "========================================"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        local source="${line%,*}"
        local target="${line#*,}"
        local exp_source=$(expand_vars "$source")
        local exp_target=$(expand_vars "$target")
        
        if [[ -e "$exp_target" ]]; then
            echo "✓ $exp_target -> $exp_source"
        else
            echo "✗ $exp_target -> $exp_source (not created)"
        fi
    done < "$SYMLINKS_CONF"
}

# Apply all symlinks from config
apply_all() {
    local conf_file="${1:-$SYMLINKS_CONF}"
    
    if [[ ! -f "$SYMLINKS_CONF" ]]; then
        echo "ERROR: Config file not found: $SYMLINKS_CONF" >&2
        exit 1
    fi
    
    echo "Applying symlinks from $SYMLINKS_CONF..."
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        local source="${line%,*}"
        local target="${line#*,}"
        local exp_source=$(expand_vars "$source")
        local exp_target=$(expand_vars "$target")
        
        if [[ -e "$exp_source" ]]; then
            create_link "$exp_source" "$exp_target"
        else
            echo "SKIP: $exp_source (not found)"
        fi
    done < "$SYMLINKS_CONF"
}

# Main
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -l|--list)
        list_symlinks
        exit 0
        ;;
    -a|--apply)
        shift
        apply_all "$1"
        exit 0
        ;;
    "")
        usage
        exit 1
        ;;
esac

# Parse arguments
source=""
target=""
persist=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--persist)
            persist=true
            shift
            ;;
        -s|-f|-n|-v|--symbolic|--force|--no-clobber|--verbose)
            # Silently ignore common ln flags (we always create symlinks)
            shift
            ;;
        -sf|-fs|-sv|-vs|-fv|-vf|-sfv|-svf|-fsv|-fvs|-vsf|-vfs)
            # Silently ignore combined ln flags
            shift
            ;;
        --)
            # End of options
            shift
            break
            ;;
        -*)
            # Unknown flag - ignore but warn
            echo "Warning: ignoring unknown option: $1" >&2
            shift
            ;;
        *)
            if [[ -z "$source" ]]; then
                source="$1"
            elif [[ -z "$target" ]]; then
                target="$1"
            fi
            shift
            ;;
    esac
done

# Collect any remaining positional arguments after --
while [[ $# -gt 0 ]]; do
    if [[ -z "$source" ]]; then
        source="$1"
    elif [[ -z "$target" ]]; then
        target="$1"
    fi
    shift
done

if [[ -z "$source" || -z "$target" ]]; then
    echo "ERROR: Both source and target required" >&2
    usage
    exit 1
fi

# Resolve to absolute paths
[[ "$source" != /* ]] && source="$(pwd)/$source"
[[ "$target" != /* ]] && target="$(pwd)/$target"

# Auto-persist if target is not under /mnt (volatile storage)
if [[ "$target" != /mnt/* ]] && ! $persist; then
    persist=true
    echo "Auto-persisting: target $target is outside /mnt (volatile storage)"
fi

# Create the link
create_link "$source" "$target" || exit 1

# Persist if requested
if $persist; then
    add_to_conf "$source" "$target"
fi
