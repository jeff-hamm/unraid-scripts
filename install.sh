#!/bin/bash
# Installation script for unraid-scripts repository
# Sets up git hooks and bind mounts

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Unraid Scripts Repository Setup ==="
echo ""

# Install git hook
echo "Installing git hooks..."
if [ -f "$REPO_DIR/hooks/post-checkout" ]; then
  mkdir -p "$REPO_DIR/.git/hooks"
  cp "$REPO_DIR/hooks/post-checkout" "$REPO_DIR/.git/hooks/post-checkout"
  chmod +x "$REPO_DIR/.git/hooks/post-checkout"
  echo "✓ Installed post-checkout hook"
else
  echo "⚠ Warning: hooks/post-checkout not found"
fi

echo ""

# Set up bind mounts
echo "Setting up bind mounts..."
MOUNT_SCRIPT="$REPO_DIR/phome/boot.d/35-mount-git-repo.sh"

if [ -x "$MOUNT_SCRIPT" ]; then
  "$MOUNT_SCRIPT"
  echo "✓ Bind mounts configured"
else
  echo "⚠ Warning: Mount script not found or not executable: $MOUNT_SCRIPT"
  echo "You may need to manually set up bind mounts."
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Repository structure:"
echo "  phome/             -> /mnt/pool/appdata/home"
echo "  user.scripts/      -> /boot/config/plugins/user.scripts/scripts"
echo "  ai-system-monitor/ -> /mnt/pool/appdata/ai-system-monitor"
echo ""
echo "You can now use git commands to track changes in all three locations."
