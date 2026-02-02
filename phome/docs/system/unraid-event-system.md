# Unraid Event System & jumpraid-scripts

This document explains how Unraid's plugin event system works and how the `jumpraid-scripts` plugin integrates with it.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           UNRAID BOOT SEQUENCE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  System Boot                                                            │
│       │                                                                 │
│       ▼                                                                 │
│  /boot/config/go  ───────────────────────────────► boot.sh (early)     │
│       │                           runs before array, limited services   │
│       ▼                                                                 │
│  /usr/libexec/unraid/emhttpd  (C binary daemon)                        │
│       │                                                                 │
│       ├──► Event: driver_loaded                                         │
│       ├──► Event: starting                                              │
│       ├──► Event: array_started      (md devices valid)                │
│       ├──► Event: disks_mounted  ────► jumpraid-scripts ──► boot.sh   │
│       ├──► Event: svcs_restarted     (network services up)            │
│       ├──► Event: docker_started     (Docker ready)                    │
│       ├──► Event: libvirt_started    (VMs ready)                       │
│       └──► Event: started            (array fully started)            │
│                                                                         │
│  Array Stop                                                             │
│       │                                                                 │
│       ├──► Event: stopping                                              │
│       ├──► Event: stopping_libvirt                                      │
│       ├──► Event: stopping_docker                                       │
│       ├──► Event: stopping_svcs  ────► jumpraid-scripts logs          │
│       ├──► Event: unmounting_disks                                      │
│       ├──► Event: stopping_array                                        │
│       └──► Event: stopped                                               │
│                                                                         │
│  System Shutdown                                                        │
│       │                                                                 │
│       ▼                                                                 │
│  /boot/config/stop  ─────────────────────────────► shutdown.d/*.sh     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. emhttpd - The Core Daemon
**Path:** `/usr/libexec/unraid/emhttpd`

The main Unraid daemon (compiled C/C++ binary) that:
- Manages array operations (start/stop)
- Updates state files in `/var/local/emhttp/*.ini`
- **Calls `/usr/local/sbin/emhttp_event` when events occur**

**Important:** emhttpd blocks until `emhttp_event` completes, so event handlers must be fast.

### 2. emhttp_event - The Event Dispatcher
**Path:** `/usr/local/sbin/emhttp_event`

A bash script that distributes events to all plugins:

```bash
# First, invoke all 'any_event' handlers (receive ALL events)
for Dir in /usr/local/emhttp/plugins/* ; do
  if [ -d $Dir/event/any_event ]; then
    for File in $Dir/event/any_event/* ; do
      [ -x $File ] && $File "$@"
    done
  elif [ -x $Dir/event/any_event ]; then
    $Dir/event/any_event "$@"
  fi
done

# Then, invoke event-specific handlers
for Dir in /usr/local/emhttp/plugins/* ; do
  if [ -d $Dir/event/$1 ]; then
    for File in $Dir/event/$1/* ; do
      [ -x $File ] && $File "$@"
    done
  elif [ -x $Dir/event/$1 ]; then
    $Dir/event/$1 "$@"
  fi
done
```

### 3. Plugin Event Handlers
**Path:** `/usr/local/emhttp/plugins/<plugin-name>/event/`

Plugins can create:
- `event/any_event` - Receives ALL events (first argument is event name)
- `event/<event-name>` - Receives only that specific event
- Both can be files (executable) or directories (all executables inside run)

## Event Reference

### Array Start Events (in order)

| Event | When | What's Available |
|-------|------|------------------|
| `driver_loaded` | Early init | Status info only |
| `starting` | cmdStart begins | Nothing mounted yet |
| `array_started` | md devices created | `/dev/md*` valid |
| `disks_mounted` | Disks mounted | `/mnt/disk*`, `/mnt/cache`, `/mnt/user` |
| `svcs_restarted` | Network services up | NFS/SMB exports available |
| `docker_started` | Docker enabled & running | Docker API available |
| `libvirt_started` | libvirt enabled & running | VM management available |
| `started` | cmdStart complete | Everything ready |

### Array Stop Events (in order)

| Event | When | What's Happening |
|-------|------|------------------|
| `stopping` | cmdStop begins | Shutdown initiated |
| `stopping_libvirt` | Before libvirt stops | Last chance for VM cleanup |
| `stopping_docker` | Before docker stops | Last chance for container cleanup |
| `stopping_svcs` | Before services stop | Network services about to stop |
| `unmounting_disks` | Before unmount | Disks spun up, synced, about to unmount |
| `stopping_array` | Before array stops | Disks unmounted, array stopping |
| `stopped` | cmdStop complete | Array fully stopped |

### Other Events

| Event | When |
|-------|------|
| `poll_attributes` | After SMART data polling |

## jumpraid-scripts Plugin

**Path:** `/usr/local/emhttp/plugins/jumpraid-scripts/`

Our custom plugin that bridges emhttpd events to PHOME scripts.

### Features

1. **Logs all events** to `/root/boot.log` and syslog
2. **Delegates to `$PHOME/event.d/<event>/*.sh`** for custom per-event handlers
3. **Runs `boot.sh` on first `disks_mounted`** (similar to user.scripts behavior)

### Handler Location
**Path:** `/usr/local/emhttp/plugins/jumpraid-scripts/event/any_event`

```bash
#!/bin/bash
EVENT="${1:-unknown}"
BOOT_LOG="/root/boot.log"
PHOME="${PHOME:-/mnt/pool/appdata/home}"

# Skip noisy events
case "$EVENT" in
    poll_attributes) exit 0 ;;
esac

# Log the event
log "Event received: $EVENT"

# Run all executable scripts in PHOME/event.d/<event>/
if [[ -d "${PHOME}/event.d/${EVENT}" ]]; then
    for script in "${PHOME}/event.d/${EVENT}"/*.sh; do
        [[ -x "$script" ]] && "$script" "$@"
    done
fi
```

## Directory Structure

```
$PHOME/
├── event.d/                    # Event-specific handlers
│   ├── disks_mounted/          # Scripts run when array mounts
│   │   ├── 00-setup-envs.sh
│   │   ├── 01-startup.sh
│   │   ├── 02-install-zsh.sh
│   │   ├── 05-symlink-phome-to-root.sh
│   │   └── ... (all boot scripts run alphabetically)
│   ├── unmounting_disks/       # Scripts run before disks unmount (shutdown)
│   │   ├── 00-unmount-git-binds.sh
│   │   ├── 10-cloudflared.sh
│   │   ├── 50-code-server.sh
│   │   └── ... (all shutdown scripts)
│   ├── docker_started/         # Scripts run when Docker starts  
│   │   └── 10-start-containers.sh
│   └── stopping_svcs/          # Scripts run before services stop
│       └── 10-cleanup.sh
└── install.sh                  # Installer that sets up everything
```

## Boot Triggers Comparison

| Trigger | When | What's Available | Use For |
|---------|------|------------------|---------|
| `disks_mounted` event | Array started | Pool, disks, user shares | All boot scripts, services, containers |
| `docker_started` event | Docker ready | Docker API | Container operations |
| `unmounting_disks` event | Before unmount | Everything, disks synced | Shutdown cleanup, saving state |
| `stopped` event | Array stopped | Minimal | Final cleanup |

### Execution Flow

1. **System boot** → Unraid starts → emhttpd daemon running
2. **Array start** → emhttpd → `disks_mounted` event → jumpraid-scripts → `event.d/disks_mounted/*.sh` (all boot scripts)
3. **Array stop** → emhttpd → `unmounting_disks` event → jumpraid-scripts → `event.d/unmounting_disks/*.sh` (all shutdown scripts)

**Note:** All boot and shutdown configuration happens via emhttpd events. No /boot/config/go or /boot/config/stop needed.
2. **Runs:** `/usr/local/emhttp/plugins/user.scripts/startSchedule.php start`
3. **Reads:** `/boot/config/plugins/user.scripts/schedule.json`
4. **Executes scripts with:** `frequency: "AtArrayStart"` or `"AtStartup"`

The "At First Array Start Only" behavior uses `/tmp/user.scripts/booted` marker.

## Cron Integration

The plugin system also manages cron:

1. Plugins create `.cron` files in `/boot/config/plugins/<plugin>/`
2. On `disks_mounted`, `/usr/local/sbin/update_cron` runs
3. Combines all `.cron` files into system crontab at `/etc/cron.d/`

## Debugging

### View Event Log
```bash
tail -f /root/boot.log
```

### Test Event Handler
```bash
# Manually trigger an event (for testing)
/usr/local/sbin/emhttp_event disks_mounted
```

### Check Plugin Registration
```bash
ls -la /usr/local/emhttp/plugins/jumpraid-scripts/event/
```

### View All Plugin Events
```bash
for p in /usr/local/emhttp/plugins/*/event; do
    echo "=== $p ==="
    ls -la "$p" 2>/dev/null
done
```

## Important Notes

1. **Events are synchronous** - emhttpd waits for all handlers to complete
2. **Keep handlers fast** - Slow handlers delay array start
3. **No systemd** - Unraid doesn't use systemd; path/timer units won't work
4. **Volatile filesystem** - Plugin files in `/usr/local/emhttp/` are lost on reboot
5. **Reinstall on boot** - `install.sh` must recreate the plugin on each boot

## Installation

Run once to set up everything:
```bash
bash /mnt/pool/appdata/home/install.sh
```

This:
1. Creates `/usr/local/emhttp/plugins/jumpraid-scripts/`
2. Creates `event.d/disks_mounted/` and `event.d/unmounting_disks/` directories
3. Runs disks_mounted scripts immediately

No /boot/config/go or /boot/config/stop modifications needed - everything runs via emhttpd events.

This:
1. Creates `/usr/local/emhttp/plugins/jumpraid-scripts/`
2. Adds hook to `/boot/config/go` to reinstall on boot
3. Creates `/boot/config/stop` for shutdown scripts
4. Runs `boot.sh` immediately
