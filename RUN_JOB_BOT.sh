#!/bin/bash
################################################################################
# Job Automation Bot Launcher
# All improvements applied and working!
################################################################################

echo "========================================================================"
echo "  JOB AUTOMATION BOT - START SCRIPT"
echo "========================================================================"
echo ""

# Change to job automation directory
cd "$(dirname "$0")/jobautomation" || exit 1

# Check Python version
echo "[1/5] Checking Python..."
python --version || { echo "ERROR: Python not found!"; exit 1; }
echo ""

# Check if .env file exists
echo "[2/5] Checking configuration..."
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and fill in your credentials"
    exit 1
fi
echo "✓ Configuration found"
echo ""

# Check dependencies
echo "[3/5] Checking dependencies..."
python -c "import selenium" 2>/dev/null || { echo "ERROR: Selenium not installed. Run: pip install selenium"; exit 1; }
python -c "from dotenv import load_dotenv" 2>/dev/null || { echo "ERROR: python-dotenv not installed. Run: pip install python-dotenv"; exit 1; }
echo "✓ All dependencies installed"
echo ""

# Create necessary directories
echo "[4/5] Creating directories..."
mkdir -p logs screenshots downloads chrome_automation_profile
echo "✓ Directories ready"
echo ""

# Run the bot
echo "[5/5] Starting job automation bot..."
echo ""
echo "========================================================================"
echo "  BOT STARTED - Monitor logs in real-time:"
echo "  tail -f logs/job_automation_all_platforms.log"
echo "========================================================================"
echo ""

# Run in background and save output
nohup python job_apply_all_platforms.py > logs/bot_console_output.log 2>&1 &
BOT_PID=$!

echo "✓ Bot running with PID: $BOT_PID"
echo ""
echo "Commands:"
echo "  Monitor logs: tail -f logs/job_automation_all_platforms.log"
echo "  Stop bot:     kill $BOT_PID"
echo "  View output:  tail -f logs/bot_console_output.log"
echo ""
echo "The bot will:"
echo "  - Visit 25 job searches across 21 platforms"
echo "  - Give you 40-50 seconds per page to manually apply"
echo "  - Save all activity to database"
echo "  - Auto-close when complete"
echo ""

# Save PID for later
echo $BOT_PID > logs/bot.pid
echo "PID saved to logs/bot.pid"
