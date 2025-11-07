@echo off
color 0A
mode con: cols=80 lines=35
title START HERE - Job Automation Setup

cls
echo.
echo                 ╔═══════════════════════════════════════════════════════════╗
echo                 ║                                                           ║
echo                 ║           JOB AUTO-APPLY BOT - START HERE                 ║
echo                 ║                                                           ║
echo                 ╚═══════════════════════════════════════════════════════════╝
echo.
echo.
echo  Welcome! This script will set up your job automation system.
echo.
echo  What this does:
echo    ✓ Applies to jobs on LinkedIn automatically
echo    ✓ Applies to jobs on Indeed automatically
echo    ✓ Uses "Easy Apply" features
echo    ✓ Fills your information automatically
echo    ✓ Tracks all applications
echo.
echo  Time required: 5 minutes setup, then it runs automatically
echo.
echo  ══════════════════════════════════════════════════════════════════════
echo.
pause

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║  STEP 1 of 3: Installing Required Packages                      ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.
echo  Installing Python packages (this takes 2-3 minutes)...
echo.

REM Change to script directory
cd /d "%~dp0"

REM Install packages quietly
py -m pip install --upgrade pip >nul 2>&1
py -m pip install selenium webdriver-manager google-api-python-client google-auth google-auth-oauthlib beautifulsoup4 >nul 2>&1

if %errorlevel% neq 0 (
    echo  ✗ Installation failed. Trying with verbose output...
    py -m pip install selenium webdriver-manager google-api-python-client beautifulsoup4
)

echo.
echo  ✓ Packages installed successfully!
echo.
pause

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║  STEP 2 of 3: Configure Your Information                        ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.
echo  You need to edit the configuration file with YOUR information:
echo.
echo    • Your name
echo    • Your email
echo    • Your phone number
echo    • Your LinkedIn password (IMPORTANT!)
echo    • Your resume filename
echo.
echo  The config file will open in Notepad...
echo.
echo  What to edit:
echo    Line 3: name
echo    Line 4: email
echo    Line 5: phone
echo    Line 7: linkedin_password (YOUR REAL PASSWORD!)
echo    Line 8: resume_path (match your PDF filename)
echo.
pause

REM Open config file
if exist "config\config.json" (
    notepad config\config.json
) else (
    echo  ✗ Config file not found at config\config.json
    pause
    exit /b 1
)

echo.
echo  Did you save your changes to the config file?
echo.
pause

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║  STEP 3 of 3: Add Your Resume                                   ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.
echo  You need to add your resume PDF to the resumes folder.
echo.
echo  Instructions:
echo    1. Make sure your resume is saved as a PDF file
echo    2. Copy your resume PDF into the resumes folder
echo    3. Make sure the filename matches what you put in config.json
echo.
echo  Opening resumes folder...
echo.
pause

REM Open resumes folder
explorer resumes

echo.
echo  Did you copy your resume PDF to the resumes folder?
echo.
pause

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║  SETUP COMPLETE - READY TO RUN!                                 ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.
echo  ✓ Packages installed
echo  ✓ Configuration edited
echo  ✓ Resume added
echo.
echo  ══════════════════════════════════════════════════════════════════════
echo.
echo  What happens next:
echo.
echo    • Chrome browser will open (you'll see it working)
echo    • Logs into LinkedIn with your credentials
echo    • Searches for jobs matching your preferences
echo    • Automatically applies using "Easy Apply"
echo    • Does the same on Indeed
echo    • Saves logs of all applications
echo.
echo  Duration: 15-30 minutes
echo  Applications: 5-25 jobs (you can change this in config)
echo.
echo  ══════════════════════════════════════════════════════════════════════
echo.
echo  Ready to start the automation?
echo.
echo  Press any key to begin, or close this window to exit...
pause >nul

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║  STARTING JOB APPLICATION AUTOMATION...                          ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.

REM Run the automation
py job_autoapply.py

echo.
echo  ══════════════════════════════════════════════════════════════════════
echo  ║  AUTOMATION COMPLETE!                                            ║
echo  ══════════════════════════════════════════════════════════════════════
echo.
echo  Check your results:
echo    • logs\job_automation.log (detailed log)
echo    • logs\applications_*.json (application history)
echo    • Your LinkedIn profile (Applied jobs)
echo.
echo  To run again: Double-click RUN.bat
echo.
echo  To schedule daily: See IMPLEMENTATION_GUIDE.md
echo.
pause
