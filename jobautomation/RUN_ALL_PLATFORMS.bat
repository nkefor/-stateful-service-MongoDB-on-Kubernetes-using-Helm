@echo off
title Job Automation - All Platforms (No LinkedIn/Indeed)
color 0B

echo.
echo ============================================================
echo    JOB AUTOMATION - 16 PLATFORMS
echo    For: Hansen Nkefor
echo    Excludes: LinkedIn ^& Indeed
echo ============================================================
echo.
echo Platforms: Dice, ZipRecruiter, Glassdoor, BuiltIn,
echo            JobRight.AI, WeWorkRemotely, Remotive,
echo            LetsWorkRemotely, Toptal, Hired, AngelList,
echo            TheLadders, Flexa, Zapier, NoDesk, DynamiteJobs
echo.
echo ============================================================
echo.

cd /d "%~dp0"

echo [1/3] Checking requirements...
if not exist ".env" (
    echo ERROR: .env file not found!
    pause
    exit /b 1
)
echo    √ .env found

if not exist "config\config.json" (
    echo ERROR: config.json not found!
    pause
    exit /b 1
)
echo    √ config.json found

echo.
echo [2/3] Creating logs directory...
if not exist "logs" mkdir logs
echo    √ Logs ready

echo.
echo [3/3] Starting automation...
echo.
echo ============================================================
echo    BROWSER WILL OPEN - DON'T CLOSE THIS WINDOW!
echo ============================================================
echo.
echo You'll have 45 seconds at each platform to:
echo   • Log in (if needed)
echo   • Browse jobs
echo   • Click Apply on interesting positions
echo.
echo The browser will automatically move to the next platform.
echo.
pause

python job_apply_all_platforms.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================
    echo    ERROR OCCURRED!
    echo ============================================================
    echo.
    echo Check logs\job_automation_all_platforms.log
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo    COMPLETED SUCCESSFULLY!
echo ============================================================
echo.
echo Check logs\ directory for details
echo.
pause
