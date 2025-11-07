@echo off
color 0A
title Job Automation Setup & Run

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║                                                           ║
echo  ║        JOB AUTO-APPLY BOT - SETUP AND RUN                 ║
echo  ║                                                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo  This script will:
echo  1. Check Python installation
echo  2. Install required packages
echo  3. Help you configure settings
echo  4. Run the automation
echo.
pause

REM Find Python
echo.
echo [1/4] Checking Python installation...
echo.

set PYTHON_EXE=
where py >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_EXE=py
    goto :python_found
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_EXE=python
    goto :python_found
)

REM Check common locations
if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe
    goto :python_found
)

if exist "C:\Python313\python.exe" (
    set PYTHON_EXE=C:\Python313\python.exe
    goto :python_found
)

echo  ✗ Python NOT found!
echo.
echo  Please install Python 3.11 or newer from:
echo  https://www.python.org/downloads/
echo.
echo  IMPORTANT: Check "Add Python to PATH" during installation
echo.
pause
exit /b 1

:python_found
echo  ✓ Python found: %PYTHON_EXE%
%PYTHON_EXE% --version
echo.

REM Install packages
echo [2/4] Installing required packages...
echo This may take 2-3 minutes...
echo.

%PYTHON_EXE% -m pip install --upgrade pip >nul 2>&1

echo  Installing selenium...
%PYTHON_EXE% -m pip install selenium==4.16.0 --quiet
if %errorlevel% neq 0 (
    echo  ✗ Failed to install selenium
    goto :install_error
)
echo  ✓ selenium installed

echo  Installing webdriver-manager...
%PYTHON_EXE% -m pip install webdriver-manager==4.0.1 --quiet
if %errorlevel% neq 0 (
    echo  ✗ Failed to install webdriver-manager
    goto :install_error
)
echo  ✓ webdriver-manager installed

echo  Installing Google API packages...
%PYTHON_EXE% -m pip install google-api-python-client==2.111.0 --quiet
%PYTHON_EXE% -m pip install google-auth==2.25.2 --quiet
%PYTHON_EXE% -m pip install google-auth-oauthlib==1.2.0 --quiet
echo  ✓ Google API packages installed

echo  Installing beautifulsoup4...
%PYTHON_EXE% -m pip install beautifulsoup4==4.12.2 --quiet
if %errorlevel% neq 0 (
    echo  ✗ Failed to install beautifulsoup4
    goto :install_error
)
echo  ✓ beautifulsoup4 installed

echo.
echo  ✓ All packages installed successfully!
echo.

REM Check config
echo [3/4] Checking configuration...
echo.

if not exist "config\config.json" (
    echo  ✗ config\config.json not found
    goto :config_error
)

findstr /C:"Your Full Name" config\config.json >nul
if %errorlevel% equ 0 (
    echo  ⚠ WARNING: You haven't updated config\config.json yet!
    echo.
    echo  You need to edit config\config.json and update:
    echo    - name (line 3)
    echo    - email (line 4)
    echo    - phone (line 5)
    echo    - linkedin_password (line 7)
    echo    - resume_path (line 8)
    echo.
    echo  Do you want to:
    echo  [1] Open config.json now to edit it
    echo  [2] Continue anyway (for testing)
    echo  [3] Exit
    echo.
    choice /C 123 /N /M "Choose (1, 2, or 3): "

    if errorlevel 3 exit /b 0
    if errorlevel 2 goto :check_resume
    if errorlevel 1 (
        notepad config\config.json
        echo.
        echo  ✓ Config opened. Please edit and save it.
        echo    Press any key after you've saved your changes...
        pause >nul
    )
)

echo  ✓ Config file exists

:check_resume
echo  Checking for resume...
if not exist "resumes\*.pdf" (
    echo  ⚠ WARNING: No PDF resume found in resumes\ folder
    echo.
    echo  Please add your resume PDF to the resumes\ folder
    echo  Then update the path in config\config.json
    echo.
    echo  Do you want to:
    echo  [1] Open resumes folder now
    echo  [2] Continue anyway (for testing)
    echo  [3] Exit
    echo.
    choice /C 123 /N /M "Choose (1, 2, or 3): "

    if errorlevel 3 exit /b 0
    if errorlevel 2 goto :ready_to_run
    if errorlevel 1 (
        explorer resumes
        echo.
        echo  ✓ Resumes folder opened. Add your PDF resume there.
        echo    Press any key after you've added your resume...
        pause >nul
    )
) else (
    echo  ✓ Resume found in resumes\ folder
)

:ready_to_run
echo.
echo [4/4] Ready to run!
echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║           EVERYTHING IS SET UP!                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo  The bot will now:
echo  • Open Chrome browser (you'll see it working)
echo  • Login to LinkedIn with your credentials
echo  • Search for jobs matching your preferences
echo  • Automatically apply using "Easy Apply"
echo  • Do the same for Indeed
echo  • Send you an email summary (if Gmail configured)
echo  • Save logs to logs\ folder
echo.
echo  This will take about 15-30 minutes.
echo.
echo  Press any key to start the automation...
pause >nul

echo.
echo ═══════════════════════════════════════════════════════════
echo  STARTING JOB APPLICATION AUTOMATION...
echo ═══════════════════════════════════════════════════════════
echo.

%PYTHON_EXE% job_autoapply.py

echo.
echo ═══════════════════════════════════════════════════════════
echo  AUTOMATION COMPLETE!
echo ═══════════════════════════════════════════════════════════
echo.
echo  Check logs\ folder for:
echo  • job_automation.log (detailed execution log)
echo  • applications_*.json (application history)
echo.
pause
exit /b 0

:install_error
echo.
echo  ✗ Package installation failed!
echo.
echo  Try running these commands manually:
echo    pip install -r requirements.txt
echo.
pause
exit /b 1

:config_error
echo.
echo  ✗ Configuration file is missing!
echo.
echo  The file config\config.json should exist.
echo  Please make sure all files are in place.
echo.
pause
exit /b 1
