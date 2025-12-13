# Copilot Instructions

## Terminal Commands

**Never use output redirection to /dev/null** - it prevents auto-approval of commands.
- ❌ `command >/dev/null`
- ❌ `command 2>/dev/null`  
- ❌ `command &>/dev/null`
- Try to use relative paths instead of absolute paths where possible

## Environment

This is an Unraid server environment. Key details:
- Host commands via `host_cmd <command>` from within containers
- VMs managed via `virsh`
- Docker containers for most services
- Persistent data on `/mnt/user/` and `/mnt/pool/`

### Persistent Storage & Configuration

- **User files and scripts**: Store in `$PHOME` (persistent home directory)
  - Use `$PHOME/boot.d/` for scripts that should run on every boot to restore Unraid user state
  - Boot scripts execute automatically to maintain system configuration across reboots
- **Symbolic links**: Use `lnp <source> <target>` to create persistent symlinks on the main system drive
  - These links are restored on each boot
  - Useful for creating convenient links in `/root` to config files or tools
- **Git repositories**: Commit changes frequently to maintain history and enable easy rollback