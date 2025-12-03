#!/usr/bin/env python3
"""
System information helper for vscode-monitor.
Reads host system info from mounted paths to avoid Copilot CLI shell blocking.

Usage:
    python3 /app/system_info.py [command]

Commands:
    mdstat      - Show RAID/array status from /host/proc/mdstat
    loadavg     - Show load average from /host/proc/loadavg
    meminfo     - Show memory info from /host/proc/meminfo
    disks       - Show disk status from /host/emhttp/disks.ini
    all         - Show all system info
"""
import sys
import os

HOST_PROC = "/host/proc"
HOST_EMHTTP = "/host/emhttp"


def read_file(path):
    """Read file contents, return None if not found."""
    try:
        with open(path, 'r') as f:
            return f.read()
    except FileNotFoundError:
        return f"File not found: {path}"
    except PermissionError:
        return f"Permission denied: {path}"
    except Exception as e:
        return f"Error reading {path}: {e}"


def show_mdstat():
    """Show RAID/array status."""
    print("=== Array Status (mdstat) ===")
    print(read_file(f"{HOST_PROC}/mdstat"))


def show_loadavg():
    """Show load average."""
    print("=== Load Average ===")
    content = read_file(f"{HOST_PROC}/loadavg")
    if content and not content.startswith("Error"):
        parts = content.strip().split()
        if len(parts) >= 3:
            print(f"1min: {parts[0]}, 5min: {parts[1]}, 15min: {parts[2]}")
        else:
            print(content)
    else:
        print(content)


def show_meminfo():
    """Show memory info."""
    print("=== Memory Info ===")
    content = read_file(f"{HOST_PROC}/meminfo")
    if content and not content.startswith("Error"):
        # Extract key memory stats
        lines = content.split('\n')
        for line in lines:
            if any(key in line for key in ['MemTotal', 'MemFree', 'MemAvailable', 'SwapTotal', 'SwapFree', 'Cached', 'Buffers']):
                print(line)
    else:
        print(content)


def show_disks():
    """Show disk status from Unraid emhttp."""
    print("=== Disk Status ===")
    content = read_file(f"{HOST_EMHTTP}/disks.ini")
    if content and not content.startswith("Error"):
        # Parse INI-style disk info
        current_disk = None
        disk_info = {}
        
        for line in content.split('\n'):
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                if current_disk and disk_info:
                    # Print previous disk
                    status = disk_info.get('status', 'unknown')
                    temp = disk_info.get('temp', '*')
                    size = disk_info.get('size', '0')
                    name = disk_info.get('name', current_disk)
                    print(f"  {current_disk}: {name} - {status}, {temp}°C, {int(size)//1024//1024//1024}GB")
                current_disk = line[1:-1]
                disk_info = {}
            elif '=' in line:
                key, value = line.split('=', 1)
                disk_info[key.strip()] = value.strip().strip('"')
        
        # Print last disk
        if current_disk and disk_info:
            status = disk_info.get('status', 'unknown')
            temp = disk_info.get('temp', '*')
            size = disk_info.get('size', '0')
            name = disk_info.get('name', current_disk)
            print(f"  {current_disk}: {name} - {status}, {temp}°C, {int(size)//1024//1024//1024}GB")
    else:
        print(content)


def show_all():
    """Show all system info."""
    show_mdstat()
    print()
    show_loadavg()
    print()
    show_meminfo()
    print()
    show_disks()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    cmd = sys.argv[1].lower()
    
    commands = {
        'mdstat': show_mdstat,
        'loadavg': show_loadavg,
        'meminfo': show_meminfo,
        'disks': show_disks,
        'all': show_all,
    }
    
    if cmd in commands:
        commands[cmd]()
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
