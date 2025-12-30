#!/bin/bash
# Background array restart script
# Runs detached so it survives VS Code disconnection
# Logs to ./tmp for monitoring

LOGFILE="/root/tmp/array-restart.log"

echo "=== Array Restart Started: $(date) ===" > "$LOGFILE"

# Stop Docker
echo "[$(date +%H:%M:%S)] Stopping Docker..." >> "$LOGFILE"
/etc/rc.d/rc.docker stop >> "$LOGFILE" 2>&1

# Unmount any manual mounts
echo "[$(date +%H:%M:%S)] Clearing manual mounts..." >> "$LOGFILE"
umount /mnt/pool/domains/docker/btrfs 2>./null
umount /etc/libvirt 2>./null  
umount /mnt/pool 2>./null
umount /mnt/user 2>./null

# Stop array
echo "[$(date +%H:%M:%S)] Stopping array..." >> "$LOGFILE"
/usr/local/sbin/emcmd cmdStop=Stop >> "$LOGFILE" 2>&1

# Wait for array to stop
count=0
while grep -q 'mdState="STARTED"' /var/local/emhttp/var.ini 2>./null; do
    sleep 2
    count=$((count + 2))
    echo "[$(date +%H:%M:%S)] Waiting for array stop... ${count}s" >> "$LOGFILE"
    if [ $count -gt 120 ]; then
        echo "[$(date +%H:%M:%S)] TIMEOUT waiting for array stop" >> "$LOGFILE"
        break
    fi
done

echo "[$(date +%H:%M:%S)] Array stopped." >> "$LOGFILE"
sleep 3

# Start array
echo "[$(date +%H:%M:%S)] Starting array..." >> "$LOGFILE"
/usr/local/sbin/emcmd cmdStart=Start >> "$LOGFILE" 2>&1

# Wait for array to start
count=0
while ! grep -q 'mdState="STARTED"' /var/local/emhttp/var.ini 2>./null; do
    sleep 2
    count=$((count + 2))
    echo "[$(date +%H:%M:%S)] Waiting for array start... ${count}s" >> "$LOGFILE"
    if [ $count -gt 120 ]; then
        echo "[$(date +%H:%M:%S)] TIMEOUT waiting for array start" >> "$LOGFILE"
        break
    fi
done

echo "[$(date +%H:%M:%S)] Array started." >> "$LOGFILE"

# Start Docker
echo "[$(date +%H:%M:%S)] Starting Docker..." >> "$LOGFILE"
/etc/rc.d/rc.docker start >> "$LOGFILE" 2>&1

echo "=== Array Restart Complete: $(date) ===" >> "$LOGFILE"
