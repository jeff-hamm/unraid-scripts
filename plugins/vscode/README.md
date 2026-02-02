# VS Code Plugin for Unraid

This plugin adds a VS Code Server tab to the Unraid web UI, providing a full VS Code experience directly in your browser.

## Features

- **Top-level tab** in Unraid UI
- **Folder selector** with dropdown for /root and all user shares
- **Nginx reverse proxy** at `/vscode-server/` with auth bypass
- **Auto-start** on boot via boot.d scripts
- **Graceful shutdown** via shutdown.d scripts
- **Chunked transfer encoding** support for large files

## Directory Structure

```
plugins/vscode/
├── vscode.plg                      # Plugin metadata (minimal)
├── install.sh                      # Main installer (does all the work)
├── VSCode.page                     # Unraid UI page definition
├── vscode-icon.svg                 # Plugin icon
├── README.md                       # This file
└── scripts/
    ├── boot.d/
    │   └── 50-code-server.sh      # Start code-server + configure nginx
    └── shutdown.d/
        └── 50-code-server.sh      # Stop code-server on shutdown
```

## Installation

From the unraid-scripts repository:

```bash
bash /root/appdata/unraid-scripts/plugins/vscode/install.sh
```

Or install all plugins at once:

```bash
bash /root/appdata/unraid-scripts/install.sh
```

## What install.sh Does

1. **Installs code-server binary** (v4.107.0) to `/mnt/pool/appdata/code-server/`
2. **Creates persistent symlink** via `lnp` to `/usr/local/bin/code-server`
3. **Copies boot script** to `$PHOME/boot.d/50-code-server.sh`
   - Starts code-server on port 8443
   - Configures nginx reverse proxy
4. **Copies shutdown script** to `$PHOME/shutdown.d/50-code-server.sh`
5. **Installs UI files**:
   - `VSCode.page` → `/usr/local/emhttp/plugins/vscode/`
   - `vscode-icon.svg` → `/usr/local/emhttp/plugins/vscode/images/vscode.png`
6. **Copies .plg file** to `/boot/config/plugins/vscode.plg`
7. **Starts code-server** if not already running
8. **Configures nginx** reverse proxy
9. **Registers plugin** with Unraid via `/usr/local/sbin/plugin install`

## Boot Process

On every boot, the following happens automatically:

1. **35-mount-git-repo.sh** - Checks if `/boot/config/plugins/vscode.plg` exists
   - If missing, runs `install.sh` to install the plugin
2. **50-code-server.sh** - Starts code-server and configures nginx
   - Unsets `VSCODE_IPC_HOOK_CLI` to prevent connection issues
   - Uses clean environment via `env -i`
   - Starts code-server on port 8443
   - Adds `location ^~ /vscode-server/` to nginx if not present
   - Reloads nginx

## Nginx Configuration

The plugin adds this location block to `/etc/nginx/conf.d/locations.conf`:

```nginx
location ^~ /vscode-server/ {
    satisfy any;
    allow all;
    auth_request off;
    proxy_pass http://127.0.0.1:8443/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 86400;
    proxy_read_timeout 86400;
    
    # Disable buffering for better streaming
    proxy_buffering off;
    proxy_request_buffering off;
    
    # Handle large files
    proxy_max_temp_file_size 0;
    client_max_body_size 0;
    
    # Chunked transfer encoding fix
    chunked_transfer_encoding on;
}
```

**Key features:**
- `^~` prefix gives priority over regex patterns like `~^/[A-Z].*`
- `auth_request off` bypasses Unraid's authentication
- `chunked_transfer_encoding on` fixes large file downloads
- Long timeouts for persistent connections

## Path Architecture

- **Unraid Page**: `/VSCode` (capital V to match top-level tabs pattern)
- **Nginx Proxy**: `/vscode-server/` (lowercase, different path to prevent nesting)
- **Code-Server**: `http://127.0.0.1:8443/` (local only, no external access)

This separation prevents infinite iframe nesting issues.

## Menu System

The VSCode.page uses:
- `Menu="Tasks:99"` - Places tab in Tasks parent menu (top-level tabs)
- `Type="xmenu"` - Makes it an external menu item
- `Tabs="false"` - No sub-tabs

The display name comes from the filename (VSCode).

## Troubleshooting

### Tab not appearing
```bash
# Check if plugin is installed
ls -la /boot/config/plugins/vscode.plg

# Check if .page file exists
ls -la /usr/local/emhttp/plugins/vscode/VSCode.page

# Reload nginx
nginx -s reload
```

### Code-server not running
```bash
# Check process
ps aux | grep code-server

# Check logs
tail -f /var/log/code-server.log

# Restart manually
bash /mnt/pool/appdata/home/boot.d/50-code-server.sh
```

### Nginx errors
```bash
# Check config syntax
nginx -t

# Check if location exists
grep -A 5 "vscode-server" /etc/nginx/conf.d/locations.conf

# Test proxy
curl -I http://127.0.0.1:8443/
```

## Uninstallation

The plugin's remove script will:
1. Remove `/usr/local/emhttp/plugins/vscode/`
2. Remove boot scripts from `$PHOME/boot.d/`
3. Remove shutdown scripts from `$PHOME/shutdown.d/`
4. Stop code-server process

**Manual step required**: Remove the nginx location block from `/etc/nginx/conf.d/locations.conf`

## Version History

- **2024.12.30d** - Reorganized into multiple files, comprehensive install.sh
- **2024.12.30c** - Fixed top-level tab placement
- **2024.12.30** - Initial release
