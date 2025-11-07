@echo off
title Job Automation - Hansen Nkefor
color 0A

echo.
echo ========================================
echo   JOB AUTOMATION SYSTEM
echo   Starting job applications...
echo ========================================
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Run the enhanced job automation
python job_autoapply_enhanced.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Job automation failed!
    echo   Check the logs for details.
    echo ========================================
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Job automation completed successfully!
echo ========================================
echo.
pause
