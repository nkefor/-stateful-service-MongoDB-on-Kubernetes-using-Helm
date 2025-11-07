@echo off
title Job Application Automation - Hansen Nkefor
color 0B

echo.
echo ============================================================
echo    JOB APPLICATION AUTOMATION SYSTEM
echo    For: Hansen Nkefor
echo ============================================================
echo.

REM Change to the script directory
cd /d "%~dp0"

echo [1/5] Checking environment...
echo.

REM Check if .env exists
if not exist ".env" (
    echo ERROR: .env file not found!
    echo Please copy .env.example to .env and fill in your credentials.
    echo.
    pause
    exit /b 1
)
echo    ✓ .env file found

REM Check if config.json exists
if not exist "config\config.json" (
    echo ERROR: config\config.json file not found!
    echo.
    pause
    exit /b 1
)
echo    ✓ config.json found

REM Check if resume exists
if not exist "resumes\Hansen_Nkefor_Resume_2025.pdf" (
    echo ERROR: Resume not found!
    echo Expected: resumes\Hansen_Nkefor_Resume_2025.pdf
    echo.
    pause
    exit /b 1
)
echo    ✓ Resume found

echo.
echo [2/5] Creating logs directory...
if not exist "logs" mkdir logs
echo    ✓ Logs directory ready

echo.
echo [3/5] Installing required Python packages...
echo    This may take a few minutes...
echo.

REM Install packages individually to handle errors better
python -m pip install --quiet --upgrade pip 2>nul
python -m pip install --quiet selenium==4.16.0 2>nul
python -m pip install --quiet webdriver-manager==4.0.1 2>nul
python -m pip install --quiet beautifulsoup4==4.12.2 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo    WARNING: Some packages may have failed to install
    echo    Continuing anyway...
)
echo    ✓ Packages installed

echo.
echo [4/5] Configuration Summary:
echo.
python simple_config_loader.py 2>nul

echo.
echo ============================================================
echo    IMPORTANT NOTICE - READ CAREFULLY
echo ============================================================
echo.
echo This automation will:
echo  • Open Chrome browser (visible, not headless)
echo  • Visit job platforms (LinkedIn, Indeed, Dice, etc.)
echo  • Search for DevOps/Cloud Engineer positions
echo  • Navigate to job listings
echo.
echo You will need to:
echo  • Log in manually to each platform (if not already logged in)
echo  • The script waits 120 seconds per platform for login
echo  • Monitor the browser and help with CAPTCHAs if needed
echo.
echo Locations being searched:
echo  → Remote, Hybrid, Onsite
echo  → Atlanta, Dallas, Houston, Austin, Texas
echo  → North Carolina, Florida, Alabama, Tennessee, Arizona
echo.
echo Job titles:
echo  → DevOps Engineer
echo  → Cloud Engineer
echo  → Site Reliability Engineer
echo  → Infrastructure Engineer
echo  → Platform Engineer
echo.
echo Maximum applications per run: 25
echo Delay between applications: 10 seconds
echo.
echo ============================================================
echo.

set /p CONFIRM="Ready to start? (Y/N): "
if /i "%CONFIRM%" NEQ "Y" (
    echo.
    echo Job automation cancelled by user.
    echo.
    pause
    exit /b 0
)

echo.
echo [5/5] Starting job application automation...
echo.
echo ============================================================
echo    AUTOMATION STARTING - DO NOT CLOSE THIS WINDOW
echo ============================================================
echo.

REM Run the enhanced job automation
python job_autoapply_enhanced.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================
    echo    ERROR: Job automation encountered an error!
    echo ============================================================
    echo.
    echo Check the logs in: logs\job_automation.log
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo    JOB AUTOMATION COMPLETED SUCCESSFULLY!
echo ============================================================
echo.
echo Check logs directory for application details:
echo  → logs\job_automation.log
echo  → logs\applications_*.json
echo.
echo NEXT STEPS:
echo  1. Review the log files to see which jobs were applied to
echo  2. Check your email for application confirmations
echo  3. Follow up on applications manually if needed
echo.
echo ============================================================
echo.
pause
