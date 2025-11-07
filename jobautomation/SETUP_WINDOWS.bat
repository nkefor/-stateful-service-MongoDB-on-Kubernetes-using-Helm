@echo off
REM Job Automation Setup Script for Windows
REM This script installs all required dependencies

echo ========================================
echo Job Automation Setup for Windows
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo Python is installed:
python --version
echo.

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip
echo.

REM Install required packages
echo Installing required Python packages...
echo This may take a few minutes...
echo.

pip install selenium
pip install webdriver-manager
pip install google-api-python-client
pip install google-auth
pip install google-auth-oauthlib
pip install beautifulsoup4
pip install lxml

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Edit config/config.json with your personal information
echo 2. Put your resume in the resumes/ folder
echo 3. Get Gmail API credentials:
echo    - Go to: https://console.cloud.google.com/
echo    - Create a project
echo    - Enable Gmail API
echo    - Create OAuth credentials
echo    - Download credentials.json to config/ folder
echo 4. Run: python job_autoapply.py
echo.
pause
