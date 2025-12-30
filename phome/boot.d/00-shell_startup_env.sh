# Source shell_startup environment variables
# Symlinked to /etc/profile.d/shell_startup_env.sh
STARTUP_SCRIPT_DIR=${1:-${STARTUP_SCRIPT_DIR:-"/boot/config/plugins/user.scripts/scripts/shell_startup"}}
if [[ -f "$STARTUP_SCRIPT_DIR/.env" ]]; then
    set -a
    source "$STARTUP_SCRIPT_DIR/.env"
    set +a
fi
shift;
PERSISTENT_HOME="${1:-${PERSISTENT_HOME:-/mnt/pool/appdata/home}}"
if [[ -f "$PERSISTENT_HOME/.env" ]]; then
    set -a
    source "$PERSISTENT_HOME/.env"
    set +a
fi
