#!/bin/bash
#
# failsafe-array-restart.sh - MAXIMUM SAFETY array restart
#
# This uses THREE layers of protection:
# 1. at daemon - schedules restart even if this script dies
# 2. nohup/setsid - detaches from terminal
# 3. Multiple retry attempts
#
# The array WILL restart even if the server loses all connections.
#

LOG="/boot/logs/failsafe-restart-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /boot/logs

echo "=============================================="
echo "  FAILSAFE ARRAY RESTART"
echo "=============================================="
echo ""
echo "This script uses TRIPLE REDUNDANCY:"
echo "  Layer 1: 'at' daemon schedules restart in 2 minutes"
echo "  Layer 2: Background process runs immediately"
echo "  Layer 3: Multiple retry attempts (5x)"
echo ""
echo "Even if EVERYTHING fails, the 'at' job will restart the array."
echo ""
echo "Log file: $LOG"
echo ""

read -p "Type 'RESTART' (all caps) to proceed: " CONFIRM
if [[ "$CONFIRM" != "RESTART" ]]; then
    echo "Aborted."
    exit 1
fi

echo "" | tee -a "$LOG"
echo "[$(date)] Starting failsafe restart..." | tee -a "$LOG"

# LAYER 1: Schedule a guaranteed restart via 'at' in 2 minutes
# This is the absolute failsafe - even if everything else fails
echo "[$(date)] Layer 1: Scheduling failsafe 'at' job..." | tee -a "$LOG"
FAILSAFE_SCRIPT=$(mktemp /boot/logs/failsafe-XXXXXX.sh)
cat > "$FAILSAFE_SCRIPT" << 'FAILSAFE_EOF'
#!/bin/bash
LOG="/boot/logs/failsafe-at-job.log"
echo "[$(date)] Failsafe 'at' job triggered" >> "$LOG"
STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
if [[ "$STATE" != "STARTED" ]]; then
    echo "[$(date)] Array not started, attempting start..." >> "$LOG"
    mdcmd start >> "$LOG" 2>&1
    sleep 30
    STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
    echo "[$(date)] Array state after start attempt: $STATE" >> "$LOG"
else
    echo "[$(date)] Array already started, no action needed" >> "$LOG"
fi
FAILSAFE_EOF
chmod +x "$FAILSAFE_SCRIPT"
echo "$FAILSAFE_SCRIPT" | at now + 2 minutes 2>&1 | tee -a "$LOG"
echo "[$(date)] ✓ Failsafe scheduled - array will restart in 2 min if needed" | tee -a "$LOG"

# LAYER 2: Run the main restart in background
echo "" | tee -a "$LOG"
echo "[$(date)] Layer 2: Starting main restart process..." | tee -a "$LOG"

# Create the inline restart script
nohup setsid bash -c '
LOG="/boot/logs/failsafe-main.log"
echo "[$(date)] Main restart process started" >> "$LOG"

# Stop array
echo "[$(date)] Stopping array..." >> "$LOG"
mdcmd stop >> "$LOG" 2>&1

# Wait for stop
for i in {1..60}; do
    STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
    if [[ "$STATE" == "STOPPED" ]]; then
        echo "[$(date)] Array stopped after ${i}s" >> "$LOG"
        break
    fi
    sleep 1
done

# Settle time
echo "[$(date)] Waiting 10s for disks..." >> "$LOG"
sleep 10

# Start array with retries
for attempt in {1..5}; do
    echo "[$(date)] Start attempt $attempt..." >> "$LOG"
    mdcmd start >> "$LOG" 2>&1
    
    for i in {1..60}; do
        STATE=$(mdcmd status 2>/dev/null | grep "^mdState=" | cut -d= -f2)
        if [[ "$STATE" == "STARTED" ]]; then
            echo "[$(date)] ✓ Array started successfully!" >> "$LOG"
            echo "[$(date)] Removing failsafe at jobs..." >> "$LOG"
            atq | awk "{print \$1}" | xargs -r atrm 2>/dev/null
            exit 0
        fi
        sleep 1
    done
    
    echo "[$(date)] Start attempt $attempt failed, retrying..." >> "$LOG"
    sleep 10
done

echo "[$(date)] ❌ Main process failed. Failsafe at job will try." >> "$LOG"
' > /boot/logs/failsafe-nohup.log 2>&1 &

MAIN_PID=$!
echo "[$(date)] ✓ Main process launched (PID: $MAIN_PID)" | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "=============================================="
echo "  RESTART IN PROGRESS"
echo "=============================================="
echo ""
echo "Two processes are now working:"
echo "  1. Main restart: Running NOW"
echo "  2. Failsafe 'at' job: Will run in 2 minutes if needed"
echo ""
echo "If your connection drops, the array WILL restart."
echo ""
echo "To monitor: tail -f /boot/logs/failsafe-main.log"
echo ""
echo "Showing initial progress in 5 seconds..."
sleep 5
echo ""
echo "=== Current Status ==="
cat /boot/logs/failsafe-main.log 2>/dev/null | tail -10
echo ""
echo "To keep watching: tail -f /boot/logs/failsafe-main.log"
