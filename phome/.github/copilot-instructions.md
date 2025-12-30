# Copilot Instructions

## Environment
- **Unraid server** with Docker containers for most services
- Persistent data: `/mnt/user/` and `/mnt/pool/`
- Persistent home: `$PHOME` (`/mnt/pool/appdata/home`) → auto-symlinked to `/root` on boot
- Documentation: `~/docs` (symlinked to `$PHOME/docs`)

### Path Rules
- Use relative paths when possible
- Never use `/dev/null` or `/tmp` directly (use `./null`, `./tmp` symlinks)
- Store persistent files in `$PHOME` - they auto-appear in `/root`
- Use `lnp <source> <target>` for non-PHOME symlinks (auto-persists if target outside `/mnt`)

## Boot & Shutdown Scripts
- **`$PHOME/boot.d/`** - Scripts run on every boot (restore system state)
- **`$PHOME/shutdown.d/`** - Scripts run before shutdown/reboot (cleanup tasks)
- Scripts execute alphabetically (use numeric prefixes: `01-`, `02-`, etc.)

## Git
- Commit early and often (small, descriptive commits make rollback easy)
- Common repo roots (check with `git status` from each):
	- `$PHOME` (`/mnt/pool/appdata/home`)
	- takeout-script (usually under `/mnt/pool/appdata/takeout-script` or `~/appdata/takeout-script`)
	- Unraid User Scripts (usually under `/boot/config/plugins/user.scripts/scripts/` or ~/scripts)

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
3. WAL reset: `docker run --rm --user 999:999 -v /mnt/pool/appdata/immich/postgres:/var/lib/postgresql/data --entrypoint pg_resetwal ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0 -f /var/lib/postgresql/data`
4. Fix ownership: `chown -R 99:100 /mnt/pool/appdata/immich/postgres`
5. Start postgres; drop `clip_index` if needed
