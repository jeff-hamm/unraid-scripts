# AI Agent Notes - System Health Monitor

## Last Run: 2025-12-03 06:03:34 UTC

### Key Findings from This Run
1. **Home Assistant VM "hammassistant"** - Started from shut off state but not responding
   - Successfully started via `host_cmd virsh start hammassistant`
   - VM shows running in virsh list, but API not responding on port 8123 after 2+ min
   - Requires user investigation of boot logs/console
   
2. **Parity disk 0 is DISABLED** - Confirmed this is EXPECTED per instructions
   - System only uses Parity Disk 1 (disk 29/sdd)
   - Not an alert condition for this system

3. **Immich failed jobs baseline: 26** (tracked for future comparison)
   - Thumbnail Generation: 13 failed
   - Video Conversion: 6 failed
   - Background Tasks: 6 failed
   - Storage Template Migration: 1 failed
   - Monitor for increases in future runs

4. **High load (7.72)** - Temporary spike from backup activity
   - takeout-backup at 68% CPU during active operation
   - Should normalize in next check

5. **Cloudflared containers unhealthy** - Known issue with minimal image
   - Health checks fail: `/bin/sh: no such file or directory`
   - May also be impacted by HA VM being down
   - User should restart after HA recovery

### Tool Locations (for reference)
- Immich jobs script: `/app/takeout-script/immich_jobs.sh` (wrapper)
  - Actual script: `/app/takeout-script/scripts/immich_jobs.py`
- System info helper: `/app/system_info.py`
- Alert helper: `/app/alert_helper.py`
- Host command wrapper: `host_cmd <command>`

### Command Reference
```bash
# Check Immich jobs
/app/takeout-script/immich_jobs.sh

# System info
python3 /app/system_info.py all

# VMs
host_cmd virsh list --all
host_cmd virsh start <vm_name>

# Disk space
host_cmd df -h /boot /mnt/user /mnt/cache

# Send notification
python3 /app/alert_helper.py -e "event" -s "subject" -d "desc" -i "normal|warning|alert" -l "/state/analysis/FILE.md"
```

### Alert Thresholds
- Memory: > 90% (currently 36% - healthy)
- Disk space: > 95% (currently 40% user, 1% boot - healthy)
- Load: > 2x CPU cores (7.72 on 4-core = temporary spike)
- Disabled disks: Expected for this system (Parity 0 always disabled)

### Container Health Patterns
- Cloudflared containers: Known to show unhealthy due to minimal image
- Scheduled containers (gdrive-backup, takeout, version-watcher): Exit after completion (normal)
- Exit code 0 = success, 137 = killed/terminated (not necessarily error), 128 = startup issue
- unbound-config-generator exits 128 but config generation succeeds

### Home Assistant Checks (when VM is operational)
```bash
# Quick health
curl -s -H "Authorization: Bearer $HA_TOKEN" http://192.168.1.179:8123/api/config | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(f'HA {d[\"version\"]} @ {d[\"location_name\"]}')"

# Check for updates
curl -s -H "Authorization: Bearer $HA_TOKEN" \
  http://192.168.1.179:8123/api/states/update.home_assistant_core_update | \
  python3 -c "import sys,json; s=json.load(sys.stdin); a=s['attributes']; print(f\"Core: {a.get('installed_version')} -> {a.get('latest_version')} ({'UPDATE' if s['state']=='on' else 'up to date'})\")"

# Problem entities
curl -s -H "Authorization: Bearer $HA_TOKEN" http://192.168.1.179:8123/api/states | \
  python3 -c "import sys,json; states=json.load(sys.stdin); problems=[s for s in states if s['state'] in ('unavailable','unknown')]; print(f'{len(problems)} problem entities') if problems else print('No problems')"
```

### Next Run Priorities
1. Check if HA VM is responding on port 8123
2. Verify cloudflared containers recovered
3. Compare Immich failed job count (baseline: 26)
4. Confirm system load normalized
5. Check if unbound/local-proxy started

### System Context
- CPU cores: 4
- Total RAM: 46.8GB
- Array: 11TB total, 4.4TB used
- Boot: 120GB SSD
- VM: hammassistant at 192.168.1.179
