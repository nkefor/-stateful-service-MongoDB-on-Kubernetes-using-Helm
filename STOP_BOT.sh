#!/bin/bash
################################################################################
# Stop Job Automation Bot
################################################################################

cd "$(dirname "$0")/jobautomation" || exit 1

if [ -f "logs/bot.pid" ]; then
    PID=$(cat logs/bot.pid)
    echo "Stopping bot (PID: $PID)..."
    kill $PID 2>/dev/null && echo "✓ Bot stopped" || echo "Bot not running"
    rm -f logs/bot.pid
else
    echo "No PID file found. Searching for running processes..."
    pkill -f "python job_apply_all_platforms.py" && echo "✓ Bot stopped" || echo "No bot process found"
fi
