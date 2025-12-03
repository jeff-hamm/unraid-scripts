#!/bin/bash
# Copilot System Monitor - Run Script
# Builds the Docker image if needed, then runs the system monitor

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
IMAGE_NAME="copilot-system-monitor"
CONTAINER_NAME="copilot-system-monitor"

# Source co-located .env if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Load auth tokens from files if env vars are empty
if [ -z "$GH_TOKEN" ] && [ -f "/root/.auth/.copilot-token" ]; then
    export GH_TOKEN="$(cat /root/.auth/.copilot-token)"
fi
if [ -z "$HA_TOKEN" ] && [ -f "/root/.auth/.ha_api_key" ]; then
    export HA_TOKEN="$(cat /root/.auth/.ha_api_key)"
fi
if [ -z "$IMMICH_API_KEY" ] && [ -f "/root/.auth/.immich_api_key" ]; then
    export IMMICH_API_KEY="$(cat /root/.auth/.immich_api_key)"
fi

# Export defaults for docker-compose
export APP_ROOT="${APP_ROOT:-/mnt/pool/appdata}"
export STATE_DIR="${STATE_DIR:-/mnt/pool/appdata/copilot-system-monitor/state}"
export COPILOT_MODEL="${COPILOT_MODEL:-claude-sonnet-4.5}"

build_image() {
    echo "=========================================="
    echo "Building Copilot System Monitor Image"
    echo "=========================================="
    
    cd "$SCRIPT_DIR"
    docker-compose build
    
    if [ $? -eq 0 ]; then
        echo "Successfully built $IMAGE_NAME:latest"
    else
        echo "ERROR: Failed to build image"
        exit 1
    fi
}

run_monitor() {
    echo "=========================================="
    echo "Running Copilot System Monitor"
    echo "=========================================="
    
    # Create state directory if needed
    mkdir -p "$STATE_DIR/analysis" "$STATE_DIR/copilot"
    
    # Check for copilot token
    if [ ! -f "/root/.auth/.copilot-token" ]; then
        echo "WARNING: Copilot token not found at /root/.auth/.copilot-token"
    fi
    
    cd "$SCRIPT_DIR"
    docker-compose run --rm copilot-system-monitor
}

case "${1:-run}" in
    build)
        build_image
        ;;
    run)
        # Build if image doesn't exist
        if ! docker image inspect "$IMAGE_NAME:latest" >/dev/null 2>&1; then
            echo "Image not found, building..."
            build_image
        fi
        run_monitor
        ;;
    rebuild)
        build_image
        run_monitor
        ;;
    *)
        echo "Usage: $0 [build|run|rebuild]"
        echo "  build   - Build the Docker image only"
        echo "  run     - Run the monitor (builds if needed)"
        echo "  rebuild - Force rebuild and run"
        exit 1
        ;;
esac
