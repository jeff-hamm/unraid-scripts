#!/bin/bash
# Configure Docker daemon with high ulimits to prevent "too many open files" errors
set -e

DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

echo "[$(date)] Checking Docker ulimits configuration..."

# Create /etc/docker directory if it doesn't exist
mkdir -p /etc/docker

# Check if already configured
if [ -f "$DOCKER_DAEMON_JSON" ] && grep -q '"nofile"' "$DOCKER_DAEMON_JSON" 2>/dev/null; then
  echo "[$(date)] Docker ulimits already configured, skipping"
  exit 0
fi

# Generate daemon.json with high ulimits
echo "[$(date)] Creating daemon.json with high ulimits..."
cat > "$DOCKER_DAEMON_JSON" <<'EOF'
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 1048576,
      "Soft": 1048576
    },
    "nproc": {
      "Name": "nproc",
      "Hard": 1048576,
      "Soft": 1048576
    }
  }
}
EOF

echo "[$(date)] Docker daemon.json created"

# Restart Docker daemon to apply changes if it's already running
if pgrep -x dockerd > /dev/null; then
  echo "[$(date)] Restarting Docker daemon (this may take 30-60 seconds)..."
  /etc/rc.d/rc.docker restart
  echo "[$(date)] Docker daemon restarted"
else
  echo "[$(date)] Docker not yet running, ulimits will be applied on next start"
fi
