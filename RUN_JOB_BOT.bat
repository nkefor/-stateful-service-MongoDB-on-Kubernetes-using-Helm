@echo off
REM ============================================================================
REM Job Automation Bot Launcher for Windows
REM All improvements applied and working!
REM ============================================================================

echo ========================================================================
echo   JOB AUTOMATION BOT - START SCRIPT
echo ========================================================================
echo.

cd /d "%~dp0jobautomation"

REM Check Python
echo [1/5] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    pause
    exit /b 1
)
echo.

REM Check configuration
echo [2/5] Checking configuration...
if not exist ".env" (
    echo ERROR: .env file not found!
    echo Please copy .env.example to .env and fill in your credentials
    pause
    exit /b 1
)
echo [OK] Configuration found
echo.

REM Check dependencies
echo [3/5] Checking dependencies...
python -c "import selenium" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Selenium not installed. Run: pip install selenium
    pause
    exit /b 1
)
python -c "from dotenv import load_dotenv" >nul 2>&1
if errorlevel 1 (
    echo ERROR: python-dotenv not installed. Run: pip install python-dotenv
    pause
    exit /b 1
)
echo [OK] All dependencies installed
echo.

REM Create directories
echo [4/5] Creating directories...
if not exist "logs" mkdir logs
if not exist "screenshots" mkdir screenshots
if not exist "downloads" mkdir downloads
if not exist "chrome_automation_profile" mkdir chrome_automation_profile
echo [OK] Directories ready
echo.

REM Run the bot
echo [5/5] Starting job automation bot...
echo.
echo ========================================================================
echo   BOT STARTED - A browser window will open
echo ========================================================================
echo.

start /B python job_apply_all_platforms.py > logs\bot_console_output.log 2>&1

echo [OK] Bot is running in background
echo.
echo The bot will:
echo   - Visit 25 job searches across 21 platforms
echo   - Give you 40-50 seconds per page to manually apply
echo   - Save all activity to database
echo   - Auto-close when complete
echo.
echo Commands:
echo   Monitor logs: type logs\job_automation_all_platforms.log
echo   View output:  type logs\bot_console_output.log
echo.
echo Press any key to exit this window (bot will keep running)...
pause >nul
