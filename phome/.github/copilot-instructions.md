# Copilot Instructions

## ⚠️ CRITICAL: Unraid Persistence Rules ⚠️

**UNRAID HAS VOLATILE STORAGE - MOST OF THE FILESYSTEM IS RESET ON REBOOT**

### What Gets WIPED on Reboot:
- **`/usr/local/bin/`, `/usr/bin/`** - ALL scripts/binaries you create here **WILL BE LOST**
- **`/etc/`** - Configuration files **VANISH** unless they're on flash or managed by plugins
- **`/tmp/`, `/var/`** - Temporary storage **ALWAYS DELETED**
- **`/root/` (except symlinked dirs)** - Most content **DISAPPEARS**

### What PERSISTS:
- **`/boot/`** - Unraid USB flash drive (FAT32, no symlinks/perms)
- **`/mnt/pool/` and `/mnt/user/`** - Array and cache pool storage
- **`$PHOME` (`/mnt/pool/appdata/home`)** - Your persistent home directory

### MANDATORY Persistence Strategy:
1. **NEVER directly edit files in `/usr/`, `/etc/`, or `/root/` expecting them to persist**
2. **ALWAYS store originals in `$PHOME` or `/boot/config/`**
3. **Use `event.d/starting/04-disks_mounted/` scripts to restore state on every boot**
4. **Use `lnp` tool for symlinks/wrappers to volatile locations**

**IF YOU CREATE A SCRIPT IN `/usr/local/bin/`, IT WILL BE GONE AFTER REBOOT UNLESS:**
- It's managed by `lnp` (auto-creates symlinks.conf entry)
- You manually create an event.d/starting/04-disks_mounted/ script to recreate it
- You add it to a plugin's install.sh

**NO EXCEPTIONS. Double-check EVERY file modification for persistence.**

## Environment
- **Unraid server** with Docker containers for most services
- **Default shell**: zsh + Oh My Zsh (robbyrussell theme, git/docker/docker-compose plugins)
- Persistent data: `/mnt/user/` and `/mnt/pool/`
- Persistent home: `$PHOME` (`/mnt/pool/appdata/home`) -> auto-symlinked to `/root` on boot
- Documentation: `~/docs` (symlinked to `$PHOME/docs`)

### Shell & Scripting
- **zsh** is the default shell (auto-installed on boot via event.d/starting/04-disks_mounted/02-install-zsh.sh)
- **Oh My Zsh** installed to `$PHOME/.oh-my-zsh` (persistent)
- **Completions**: `$PHOME/.zsh/completions/` - symlinked to `~/.zsh/completions/`
  - **IMPORTANT**: User loves zsh completion scripts. Always look to install them when possible. Always Generate zsh completion scripts for new commands/tools when creating them
  - Completion files follow naming: `_command-name` (e.g., `_lnp`, `_dc`)
  - User loves autocompletion - it's a priority feature, not an afterthought
  - **Use `_arguments` not `_values` for options**: Produces aligned format like `uname` showing `--option -o -- description`
  - Group related short/long options: `'(--all -a)'{--all,-a}'[description]'` displays them together
- All scripts in `$PHOME/.local/bin/` use `#!/usr/bin/env zsh` shebang
- Boot/shutdown scripts can still use bash (they're called via `bash "$script"` explicitly)

### Personal Scripts & Functions Organization

**MANDATORY: All scripts and functions MUST have a `# @desc` comment for autodiscovery.**

#### Scripts (`$PHOME/.local/bin/`)
- Place executable scripts here with `#!/usr/bin/env zsh` shebang
- Add `# @desc` right after the shebang (supports multiline):
  ```zsh
  #!/usr/bin/env zsh
  # @desc Stop mover and array, then tail the log
  #   Waits for mover to stop before stopping array
  ```

#### Functions (`$PHOME/.zsh/functions/`)
- Organized by category: `docker.zsh`, `unraid.zsh`, `general.zsh`, `shell.zsh`, etc.
- Add `# @desc` comment immediately before each function (supports multiline):
  ```zsh
  # @desc Docker ps (formatted)
  #   Shows container names, status, and ports in table format
  dps() { docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" "$@" }
  ```
- Functions auto-loaded via `$PHOME/.zsh/functions.zsh`
- **Use aliases for simple pass-throughs**, functions for logic/autodiscovery

#### Discovery System
- **`utils`**: Wrapper to discover/run all personal utilities
  - `utils` (no args): Lists all scripts and functions with descriptions
  - `utils <tab>`: Autocomplete with descriptions
  - `utils <name> [args]`: Run any script or function
- **`_utils`**: Completion script that parses `@desc` dynamically
- **`$PHOME/.zsh/lib/parse-utils.zsh`**: Parser for `@desc` extraction (supports multiline)
- **`reload-completions`**: Reload completions without restarting shell

#### Adding New Utilities
1. Create script in `~/.local/bin/` or function in `~/.zsh/functions/<category>.zsh`
2. Add `# @desc Description` comment (REQUIRED, can be multiline)
3. Run `fix-missing-descriptions` if you forget
4. Run `reload-completions` or `exec zsh`

#### Fixing Missing Descriptions
Run `fix-missing-descriptions` to:
- Scan all scripts and functions for missing `@desc` comments
- Show which files need attention
- Optionally use GitHub Copilot CLI to suggest descriptions

### Docker Compose Helper (`dc`)
- Smart wrapper in `$PHOME/.local/bin/dc` for quick docker-compose access
- Usage: `dc <command> <project-name>` or `dc <command>` (in current directory)
- **When adding new docker-compose projects**: Update `$PHOME/.conf/dc-projects.conf`
  - Add entry to `DC_PROJECTS` associative array
  - Both `dc` command and autocomplete read from this single config file
- Examples: `dc up immich -d`, `dc logs jumpflix -f`, `dc down hammassistant`

### Storage Notes
- `/boot` (Unraid flash) is FAT32: symlinks + unix perms/ownership are limited
- Avoid tools that try to preserve owner/group/perms/times when writing to `/boot` (e.g. `rsync -a`)
- For git repos under `/boot`, prefer `git config core.filemode false` and `git config core.symlinks false`
- `$PHOME` on `/mnt/pool` is the "real" editable workspace; `/root/*` is a convenience view via boot-time symlinks

### Local Binaries
- `$PHOME/.local/bin/` - Your scripts (tracked in git, in PATH)
- `$PHOME/.local/opt/bin/` - External binaries (gitignored, in PATH)
  - cloudflared, gh, git-filter-repo, lazydocker
  - Installed by boot scripts to `.local/opt/bin/`
- Both directories added to PATH via `/etc/profile.d/phome-path.sh` (created by boot.d)

## Persistent Symlinks & Wrappers (`lnp`)

**Tool**: `lnp` - Persistent symlink manager that handles Unraid's volatile filesystem

### Basic Usage:
```bash
lnp <source> <target>              # Create symlink (auto-persists if outside /mnt)
lnp <source> <target> -p           # Explicitly persist to symlinks.conf
lnp -l                             # List configured symlinks
lnp -a                             # Apply all from symlinks.conf
```

### How It Works:
1. Creates symlinks OR wrapper scripts (for `/bin/` targets)
2. Stores config in `$PHOME/.conf/symlinks.conf` with path variables
3. Auto-reapplied on boot via `$PHOME/boot.d/` script
4. **Wrappers handle both sourcing and execution** (for shell scripts)

### Wrapper Script Behavior:
When target is in `*/bin/*`, `lnp` creates a wrapper that:
- **If sourced** (`. script`): Sources the real script (no output)
- **If executed** (`script`): Runs with appropriate interpreter
- **Persists across reboots** via symlinks.conf

### Auto-Persistence:
`lnp` automatically persists when target is outside `/mnt/*`:
```bash
lnp $PHOME/.local/bin/myscript /usr/local/bin/myscript  # Auto-persists (volatile target)
lnp /mnt/pool/data /root/data                           # Optional persist (both persistent)
```

### Path Variables in symlinks.conf:
Uses `$PHOME`, `$APP_ROOT`, `$SCRIPTS_DIR` for portability:
```
$PHOME/.local/bin/app-envs,/usr/local/bin/app-envs
$PHOME/scripts/backup.sh,/usr/local/bin/backup
```

### CRITICAL for Scripts that Get Sourced:
If your script in `/usr/local/bin/` needs to be sourceable (like `app-envs`):
1. Store real script in `$PHOME/.local/bin/`
2. Use `lnp` to create wrapper in `/usr/local/bin/`
3. Wrapper auto-detects sourcing vs execution
4. **NEVER manually edit the wrapper** - regenerate with `lnp -a`

## Event-Driven Scripts (jumpraid-scripts plugin)
- **`$PHOME/event.d/`** - Event handlers for emhttpd lifecycle events
- **Event structure**: `event.d/starting/<event>/` and `event.d/stopping/<event>/`
- **Boot scripts**: `event.d/starting/04-disks_mounted/` (runs when array mounts)
- **Shutdown scripts**: `event.d/stopping/05-unmounting_disks/` (runs before unmount)
- Scripts execute alphabetically (use numeric prefixes: `01-`, `02-`, etc.)
- Handler: `/usr/local/emhttp/plugins/jumpraid-scripts/event/any_event` (auto-installed)
- See: `$PHOME/docs/system/unraid-event-system.md` for full documentation

## Git
- Commit early and often (small, descriptive commits make rollback easy)
- Common repo roots (check with `git status` from each):
- `$PHOME` (`/mnt/pool/appdata/home`)
- takeout-script (usually under `/mnt/pool/appdata/takeout-script` or `~/appdata/takeout-script`)
- Unraid User Scripts (usually under `/boot/config/plugins/user.scripts/scripts/` or ~/scripts)

### Keeping GitHub Up To Date
- `$PHOME` is the live editable copy; `unraid-scripts` repo has it bind-mounted at `phome/`
- Changes to `$PHOME` are immediately reflected in the git repo (bind mount)
- **Workflow**: Make changes in `$PHOME`, then `cd /root/appdata/unraid-scripts && git add phome/ && git commit && git push`
- Old sync tool (`phome-sync-to-git`) is deprecated - no longer needed with bind mount

## Unraid Plugins
Plugins live in `unraid-scripts/plugins/<name>/` and auto-install on boot if missing.

### Plugin Structure
```
plugins/<name>/
├── <name>.plg           # Plugin metadata (minimal XML, version info only)
├── install.sh           # Does all installation work
├── <Name>.page          # UI page definition (PHP + HTML)
├── <name>-icon.svg      # Plugin icon
├── README.md            # Documentation
└── scripts/
    ├── boot.d/          # Scripts to copy to $PHOME/boot.d/
    └── starting/        # Scripts to copy to $PHOME/event.d/starting/<event>/
    └── stopping/        # Scripts to copy to $PHOME/event.d/stopping/<event>

### install.sh Pattern
```bash
#!/bin/bash
set -e
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHOME="/mnt/pool/appdata/home"

# 1. Install dependencies (binaries, packages, etc.)
# 2. Copy boot.d scripts to $PHOME/boot.d/ (chmod +x)
# 3. Copy event scripts to $PHOME/event.d/starting/<event>/ (chmod +x)
# 3. Copy shutdown scripts to $PHOME/event.d/stopping/<event>/ (chmod +x)
# 4. Install UI files to /usr/local/emhttp/plugins/<name>/
# 5. Copy .plg to /boot/config/plugins/<name>.plg
# 6. Trigger jumpraid-scripts to run event handlerinstall /boot/config/plugins/<name>.plg
```

### Creating Top-Level Tabs
For tabs in main menu bar (like Dashboard, Settings, Tools):
```php
Menu="Tasks:99"    // "Tasks" is parent menu; 99 is sort order (Dashboard=1, Settings=4, Tools=90)
Type="xmenu"       // External menu item
Tabs="false"       // No sub-tabs
Icon="name.png"    // Icon filename (in plugins/<name>/images/)
Title="Display Name"
```
**Critical**: Filename (without .page) becomes display name if Title not set. Use `PascalCase.page` for clean names.

### Nginx Reverse Proxy
Add to `/etc/nginx/conf.d/locations.conf` via boot script:
```nginx
location ^~ /path/ {           # ^~ gives priority over regex patterns like ~^/[A-Z].*
    satisfy any;
    allow all;
    auth_request off;          # Bypass Unraid auth
    proxy_pass http://127.0.0.1:PORT/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    chunked_transfer_encoding on;    # Fix large file downloads
    proxy_buffering off;
}
```
**Path separation**: Use different paths for page (e.g., `/VSCode`) and proxy (e.g., `/vscode-server/`) to prevent iframe nesting.

## Documentation
```
~/docs/
├── system/           # System-wide notes
└── projects/<name>/  # Project-specific docs
```

- Put notes in `~/docs`, not in `/tmp`, appdata state dirs, or random folders
- Use `~/docs/system/` for host-level things (array/mover, networking, storage, Docker/Unraid quirks)
- Use `~/docs/projects/<project>/` for project work; keep:
- `analysis/` for reports, investigations, runbooks, postmortems
- `copilot/` for AI-specific context, prompts, and operational notes
- Prefer updating existing docs over creating many new one-off files

## Postgres/Immich Recovery
If Postgres fails with WAL corruption:
1. Stop Immich containers
2. Backup: `cp -a --reflink=always /mnt/pool/appdata/immich/postgres /mnt/pool/appdata/immich/postgres.backup_$(date +%Y%m%d_%H%M%S)`
3. Reset:
```bash
docker run --rm --user 999:999 -v /mnt/pool/appdata/immich/postgres:/var/lib/postgresql/data --entrypoint pg_resetwal ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0 -f /var/lib/postgresql/data &&
chown -R 99:100 /mnt/pool/appdata/immich/postgres
```
4. Start postgres; drop `clip_index` if needed
