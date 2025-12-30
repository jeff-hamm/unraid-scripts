# Cache Services Independent

Keep Docker and VMs running when the array stops, since they run on the cache pool.

## What It Does

1. **Docker stays running** - Docker daemon continues when array stops
2. **VMs stay running** - libvirt/VMs continue when array stops  
3. **Smart container management** - Stops only containers with array mounts

## Container Detection Logic

When the array stops, the script:
- ✅ **Keeps running**: Containers that only use cache pool paths:
  - `/mnt/*/appdata/*`
  - `/mnt/*/vmdrive/*`
  
- ⏹️ **Stops**: Containers with array mounts:
  - `/mnt/user/*` (except appdata/vmdrive)
  - `/mnt/disk*/*` (except appdata/vmdrive)
  - Any other `/mnt/*` paths

## Installation

### Option 1: User Scripts (Recommended)
1. Go to **Settings → User Scripts**
2. Find **cache-services-independent**
3. Set schedule to **At Startup of Array**
4. Click **Run in Background**

### Option 2: Manual
```bash
/boot/config/plugins/user.scripts/scripts/cache-services-independent/install.sh
```

## Uninstallation

### Option 1: Run uninstall script
```bash
/boot/config/plugins/user.scripts/scripts/cache-services-independent/uninstall.sh
```

### Option 2: Manual restoration
```bash
cp /etc/rc.d/rc.docker.original /etc/rc.d/rc.docker
cp /etc/rc.d/rc.libvirt.original /etc/rc.d/rc.libvirt
```

## Testing

Check which containers would be stopped:
```bash
/boot/config/plugins/user.scripts/scripts/cache-services-independent/stop-array-containers.sh
```

## Files Modified

- `/etc/rc.d/rc.docker` - Patched to intercept array stop
- `/etc/rc.d/rc.libvirt` - Patched to intercept array stop

Backups are saved as `.original` files.

## Requirements

- Docker must be configured to use cache pool (`/mnt/pool` or similar)
- VMs should be stored on cache pool for best results
