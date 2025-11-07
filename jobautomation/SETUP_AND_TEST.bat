@echo off
color 0B
title Job Automation - Setup and Test

echo.
echo ================================================================
echo           JOB AUTOMATION - SETUP AND TEST
echo ================================================================
echo.
echo This script will:
echo   1. Install all required packages
echo   2. Run system checks
echo   3. Guide you through configuration
echo.
pause

REM Change to script directory
cd /d "%~dp0"

echo.
echo ================================================================
echo STEP 1: Installing Required Packages
echo ================================================================
echo.
echo This may take 2-3 minutes...
echo.

py -m pip install --upgrade pip --quiet
py -m pip install selenium==4.16.0 --quiet
py -m pip install webdriver-manager==4.0.1 --quiet
py -m pip install google-api-python-client==2.111.0 --quiet
py -m pip install google-auth==2.25.2 --quiet
py -m pip install google-auth-oauthlib==1.2.0 --quiet
py -m pip install beautifulsoup4==4.12.2 --quiet

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Package installation failed
    echo.
    echo Try running manually:
    echo   py -m pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo STEP 2: Running System Checks
echo ================================================================
echo.

py test_setup.py

echo.
echo ================================================================
echo SETUP COMPLETE
echo ================================================================
echo.
echo Next steps:
echo   1. Edit config\config.json with your LinkedIn credentials
echo   2. Add your resume PDF to resumes\ folder
echo   3. Run: RUN.bat
echo.
pause
