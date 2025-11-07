@echo off
title Job Automation - Direct Launch
color 0B

echo.
echo ============================================================
echo    LAUNCHING JOB AUTOMATION
echo    16 Platforms (No LinkedIn/Indeed)
echo ============================================================
echo.

cd /d "%~dp0"

REM Try to find working Python
set PYTHON_CMD=

REM Try common Python locations
if exist "C:\Python313\python.exe" set PYTHON_CMD=C:\Python313\python.exe
if exist "C:\Python312\python.exe" set PYTHON_CMD=C:\Python312\python.exe
if exist "C:\Python311\python.exe" set PYTHON_CMD=C:\Python311\python.exe
if exist "C:\Python310\python.exe" set PYTHON_CMD=C:\Python310\python.exe

REM If not found, try system Python
if "%PYTHON_CMD%"=="" (
    where python >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set PYTHON_CMD=python
    )
)

if "%PYTHON_CMD%"=="" (
    echo ERROR: Python not found!
    echo Please install Python from python.org
    pause
    exit /b 1
)

echo Using Python: %PYTHON_CMD%
echo.

REM Run the automation
%PYTHON_CMD% job_apply_all_platforms.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================
    echo    AUTOMATION ENCOUNTERED AN ERROR
    echo ============================================================
    echo.
    echo The Python installation may be corrupted.
    echo Try reinstalling Python from python.org
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo    AUTOMATION COMPLETED!
echo ============================================================
echo.
pause
