# Git Hooks

This directory contains git hooks for the unraid-scripts repository.

## Post-Checkout Hook

The `post-checkout` hook automatically sets up bind mounts after cloning the repository.

### Installation

The hook is automatically installed if you clone this repo on an Unraid system. For manual installation:

```bash
cp hooks/post-checkout .git/hooks/post-checkout
chmod +x .git/hooks/post-checkout
```

### What it does

After cloning, the hook creates bind mounts so the directories in this repo point to the actual file locations:

- `phome/` → `/mnt/pool/appdata/home`
- `user.scripts/` → `/boot/config/plugins/user.scripts/scripts`
- `ai-system-monitor/` → `/mnt/pool/appdata/ai-system-monitor`

This allows git to track files at their real locations without copying or symlinking.

### Manual Setup

If the hook didn't run automatically or you need to set up mounts manually:

```bash
sudo .git/hooks/post-checkout 0000000000000000000000000000000000000000 HEAD 1
```

Or run the boot script directly:
```bash
sudo phome/boot.d/35-mount-git-repo.sh
```
