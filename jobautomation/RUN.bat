@echo off
REM Quick run script for Job Automation

echo ========================================
echo Starting Job Application Automation
echo ========================================
echo.

REM Check if config exists
if not exist "config\config.json" (
    echo ERROR: config/config.json not found
    echo Please run SETUP_WINDOWS.bat first
    pause
    exit /b 1
)

REM Check if credentials.json exists
if not exist "config\credentials.json" (
    echo WARNING: config/credentials.json not found
    echo You need Gmail API credentials to send email notifications
    echo Get them from: https://console.cloud.google.com/
    echo.
    echo Continue anyway? (Y/N)
    set /p continue=
    if /i not "%continue%"=="Y" exit /b 0
)

REM Run the script
echo Running job application automation...
echo.
python job_autoapply.py

echo.
echo ========================================
echo Automation Complete!
echo ========================================
echo Check logs/ folder for application logs
echo.
pause
