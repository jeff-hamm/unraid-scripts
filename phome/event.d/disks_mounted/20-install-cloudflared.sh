# #!/bin/bash
# #
# # Install and run cloudflared natively (not in Docker)
# # Keeps Cloudflare Tunnel running even when Docker is down

# PHOME="${PHOME:-/mnt/pool/appdata/home}"
# AUTH_DIR=${AUTH_DIR:-$PHOME/.auth}
# CLOUDFLARED_BIN="/mnt/pool/appdata/home/.local/opt/bin/cloudflared"
# CONFIG_DIR="/mnt/pool/appdata/networking"
# CLOUDFLARED_CONFIG="$CONFIG_DIR/cloudflared/config.yml"
# CREDENTIALS_FILE="$AUTH_DIR/cloudflared/.credentials.json"
# LOG_DIR="/var/log/cloudflared"
# PID_FILE="/var/run/cloudflared.pid"

# echo "=== Cloudflared Native Installation ==="

# # Get the latest cloudflared version from GitHub
# get_latest_version() {
#     curl -fsSL "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" | \
#         grep -o '"tag_name": *"[^"]*"' | \
#         sed 's/"tag_name": *"\(.*\)"/\1/'
# }

# # Get currently installed version
# get_installed_version() {
#     if [ -f "$CLOUDFLARED_BIN" ]; then
#         "$CLOUDFLARED_BIN" --version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]\+\.[0-9]\+' || echo "none"
#     else
#         echo "none"
#     fi
# }

# # Download and install cloudflared
# install_cloudflared() {
#     local version="$1"
#     echo "Installing cloudflared $version..."
    
#     # Create directory if it doesn't exist
#     mkdir -p "$(dirname "$CLOUDFLARED_BIN")"
    
#     local download_url="https://github.com/cloudflare/cloudflared/releases/download/${version}/cloudflared-linux-amd64"
    
#     if ! curl -fsSL -o "$CLOUDFLARED_BIN" "$download_url"; then
#         echo "  ERROR: Failed to download cloudflared"
#         return 1
#     fi
    
#     chmod +x "$CLOUDFLARED_BIN"
    
#     if ! "$CLOUDFLARED_BIN" --version >/dev/null 2>&1; then
#         echo "  ERROR: Downloaded binary is not executable"
#         return 1
#     fi
    
#     echo "  Installed: $("$CLOUDFLARED_BIN" --version | head -1)"
#     return 0
# }

# # Get latest version from GitHub
# echo "  Checking for latest cloudflared version..."
# LATEST_VERSION=$(get_latest_version)

# if [ -z "$LATEST_VERSION" ]; then
#     echo "  WARNING: Could not fetch latest version from GitHub"
#     if [ ! -f "$CLOUDFLARED_BIN" ]; then
#         echo "  ERROR: No cloudflared binary and cannot fetch latest version"
#         exit 1
#     fi
#     echo "  Using existing installation"
# else
#     echo "  Latest version: $LATEST_VERSION"
#     INSTALLED_VERSION=$(get_installed_version)
#     echo "  Installed version: $INSTALLED_VERSION"
    
#     # Install or upgrade if needed
#     if [ "$INSTALLED_VERSION" = "none" ]; then
#         install_cloudflared "$LATEST_VERSION" || exit 1
#     elif [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
#         echo "  Upgrading cloudflared from $INSTALLED_VERSION to $LATEST_VERSION..."
#         install_cloudflared "$LATEST_VERSION" || exit 1
#     else
#         echo "  cloudflared is up to date: $("$CLOUDFLARED_BIN" --version | head -1)"
#     fi
# fi

# # Verify config and credentials exist
# if [ ! -f "$CLOUDFLARED_CONFIG" ]; then
#     echo "  ERROR: Config file not found: $CLOUDFLARED_CONFIG"
#     exit 1
# fi

# if [ ! -f "$CREDENTIALS_FILE" ]; then
#     echo "  ERROR: Credentials file not found: $CREDENTIALS_FILE"
#     exit 1
# fi

# # Create log directory
# mkdir -p "$LOG_DIR"

# # Stop existing cloudflared if running
# stop_cloudflared() {
#     if [ -f "$PID_FILE" ]; then
#         local old_pid=$(cat "$PID_FILE")
#         if kill -0 "$old_pid" 2>/dev/null; then
#             echo "  Stopping existing cloudflared (PID: $old_pid)..."
#             kill "$old_pid" 2>/dev/null
#             sleep 2
#             kill -9 "$old_pid" 2>/dev/null || true
#         fi
#         rm -f "$PID_FILE"
#     fi
    
#     # Kill any stray cloudflared processes
#     pkill -f "cloudflared tunnel" 2>/dev/null || true
# }

# stop_cloudflared

# # Start cloudflared in background
# echo "  Starting cloudflared tunnel..."
# nohup "$CLOUDFLARED_BIN" tunnel \
#     --config "$CLOUDFLARED_CONFIG" \
#     --credentials-file "$CREDENTIALS_FILE" \
#     run \
#     > "$LOG_DIR/cloudflared.log" 2>&1 &

# CLOUDFLARED_PID=$!
# echo "$CLOUDFLARED_PID" > "$PID_FILE"

# # Wait and verify it started successfully
# sleep 3
# if kill -0 "$CLOUDFLARED_PID" 2>/dev/null; then
#     echo "  ✓ Cloudflared started (PID: $CLOUDFLARED_PID)"
#     echo "  Log: $LOG_DIR/cloudflared.log"
# else
#     echo "  ERROR: Cloudflared failed to start"
#     echo "  Last 20 lines of log:"
#     tail -20 "$LOG_DIR/cloudflared.log" 2>/dev/null || echo "  No log file found"
#     exit 1
# fi

# echo "=== Cloudflared Setup Complete ==="
