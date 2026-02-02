# System Monitor Notes

## Last Run: 2026-02-02 12:42 UTC

### Key Findings
- **Array Rebuild**: Disk1 (sdb) in DISK_INVALID state, parity rebuild at 13% - ONGOING
- **gdrive mount**: /mnt/user/gdrive/ does not exist - causing I/O errors in backup services
- **cloudflared-tunnel**: config.yml is a directory instead of file - causing crash loop (127 restarts)

### Persistent Issues to Track
1. **Chadburn issue #127** (goroutine leak): Still open as of 2026-02-02, restarted as workaround
2. **Parity disk configuration**: Parity2 (disk 29) intentionally disabled - this is NORMAL
3. **Home Assistant tile_tracker**: Generates duplicate ID warnings - cosmetic issue, no functional impact

### Useful Commands Discovered
```bash
# Check array rebuild status with percentage
host_cmd cat /proc/mdstat | grep -E "recon|recovery|resync"

# Check Immich jobs via API (better than missing immich-jobs script)
curl -s -H "x-api-key: $IMMICH_API_KEY" http://192.168.1.216:2283/api/jobs | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f\"{k}: active={v.get('jobCounts',{}).get('active',0)} waiting={v.get('jobCounts',{}).get('waiting',0)} paused={v.get('isPaused',False)}\") for k,v in d.items()]"

# Check container restart counts (find crash loops)
docker ps -a --format '{{.Names}}\t{{.RestartCount}}' | awk '$2 > 10'

# Check Docker reclaimable space
docker system df
```

### Next Run TODO
- [ ] Verify array rebuild completion (currently 13%)
- [ ] Check if gdrive mount restored
- [ ] Verify cloudflared-tunnel fixed
- [ ] Monitor disk1 SMART status post-rebuild

### Container Context
- This container runs as `ai-system-monitor` with docker socket access
- Total containers: 39 (25 running normally)
- Scheduled jobs run via chadburn (restarted this run)
