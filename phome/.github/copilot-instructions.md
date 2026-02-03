# Copilot Instructions

## ⚠️ CRITICAL: Unraid Persistence Rules ⚠️

**UNRAID RESETS MOST OF THE FILESYSTEM ON REBOOT**

### What Gets WIPED:
- `/usr/local/bin/`, `/usr/bin/`, `/etc/`, `/tmp/`, `/var/`
- `/root/` (except symlinked dirs from `$PHOME`)

### What PERSISTS:
- `/boot/` - USB flash (FAT32, no symlinks/perms)
- `/mnt/pool/`, `/mnt/user/` - Array storage
- `$PHOME` (`/mnt/pool/appdata/home`) - Persistent home

### Persistence Strategy:
1. Store files in `$PHOME`, never directly in volatile locations
2. Use `event.d/starting/04-disks_mounted/` scripts to restore state on boot
3. Use `lnp` tool for persistent symlinks to volatile locations

## Environment

| Path | Purpose |
|------|---------|
| `$PHOME` | `/mnt/pool/appdata/home` - persistent home, symlinked to `/root` on boot |
| `~/.local/bin/` | Personal scripts (zsh, in PATH, git-tracked) |
| `~/.local/opt/bin/` | External binaries (gitignored, in PATH) |
| `~/docs/` | Documentation (symlinked to `$PHOME/docs`) |

- **Shell**: zsh + Oh My Zsh
- **Git repo**: `/root/appdata/unraid-scripts` with `$PHOME` bind-mounted at `phome/`

## Scripts & Functions

**All scripts/functions MUST have `# @desc` comment for autodiscovery.**

### Scripts (`~/.local/bin/`)
```zsh
#!/usr/bin/env zsh
# @desc Stop mover and array, then tail the log
```

### Functions (`~/.zsh/functions/<category>.zsh`)
```zsh
# @desc Docker ps (formatted)
dps() { docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" "$@" }
```

### Zsh Completions
- Location: `~/.zsh/completions/_command-name`
- **Always generate completions for new commands** - user loves autocompletion
- Use `_arguments` with grouped options: `'(--all -a)'{--all,-a}'[description]'`
- Run `reload-completions` after adding

## Event System (jumpraid-scripts)

Scripts in `$PHOME/event.d/` run on Unraid lifecycle events:

```
event.d/
├── starting/
│   ├── 01-driver_loaded/
│   ├── 02-starting/
│   ├── 03-array_started/
│   ├── 04-disks_mounted/     ← boot scripts (main)
│   ├── 05-svcs_restarted/
│   ├── 06-docker_started/
│   ├── 07-libvirt_started/
│   └── 08-started/
└── stopping/
    ├── 01-stopping/
    ├── 02-stopping_libvirt/
    ├── 03-stopping_docker/
    ├── 04-stopping_svcs/
    ├── 05-unmounting_disks/  ← shutdown scripts (main)
    ├── 06-stopping_array/
    └── 07-stopped/
```

- Scripts execute alphabetically (use `01-`, `02-` prefixes)
- Handler: `/usr/local/emhttp/plugins/jumpraid-scripts/event/any_event`
- Docs: `$PHOME/docs/system/unraid-event-system.md`

## Persistent Symlinks (`lnp`)

```bash
lnp <source> <target>    # Create symlink (auto-persists if target is volatile)
lnp -l                   # List configured symlinks
lnp -a                   # Apply all from symlinks.conf
```

- Config: `$PHOME/.conf/symlinks.conf`
- Creates wrappers for `/bin/` targets (handles sourcing vs execution)
- Reapplied on boot automatically

## Docker Compose (`dc`)

```bash
dc <command> <project>   # dc up immich -d, dc logs jumpflix -f
```

- Config: `$PHOME/.conf/dc-projects.conf` (add new projects here)

## Git Workflow

```bash
cd /root/appdata/unraid-scripts
git add phome/
git commit -m "description"
git push
```

`$PHOME` is bind-mounted to `phome/` - changes are immediately visible in git.

## Documentation

```
~/docs/
├── system/              # Host-level: array, networking, Docker
└── projects/<name>/     # Project work, analysis, copilot notes
```

Prefer updating existing docs over creating new files.
