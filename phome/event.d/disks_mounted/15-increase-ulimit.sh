#!/bin/bash
# Increase file descriptor limits for Docker and system

# Set soft and hard limits for file descriptors
ulimit -n 65536

# Set system-wide limits
sysctl -w fs.file-max=4906459 >/dev/null

# Persist in limits.conf if not already set
if ! grep -q "^* soft nofile 65536" /etc/security/limits.conf 2>/dev/null; then
  cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
EOF
fi

echo "File descriptor limits increased: ulimit -n 65536"
