@echo off
REM Simple installation script that tries multiple Python locations

echo ========================================
echo Installing Job Automation Dependencies
echo ========================================
echo.

REM Try the Microsoft Store Python first (usually most reliable)
if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe
    goto :install
)

if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe
    goto :install
)

if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe
    goto :install
)

REM Try C:\ Python installations
if exist "C:\Python313\python.exe" (
    set PYTHON_EXE=C:\Python313\python.exe
    goto :install
)

if exist "C:\Python312\python.exe" (
    set PYTHON_EXE=C:\Python312\python.exe
    goto :install
)

REM Try using 'py' launcher
where py >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_EXE=py
    goto :install
)

REM Try using 'python' command
where python >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_EXE=python
    goto :install
)

echo ERROR: Could not find Python installation
echo.
echo Please install Python from: https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH" during installation
echo.
pause
exit /b 1

:install
echo Found Python: %PYTHON_EXE%
echo.
%PYTHON_EXE% --version
echo.

echo Installing packages...
echo This will take 2-3 minutes...
echo.

%PYTHON_EXE% -m pip install --upgrade pip
%PYTHON_EXE% -m pip install selenium==4.16.0
%PYTHON_EXE% -m pip install webdriver-manager==4.0.1
%PYTHON_EXE% -m pip install google-api-python-client==2.111.0
%PYTHON_EXE% -m pip install google-auth==2.25.2
%PYTHON_EXE% -m pip install google-auth-oauthlib==1.2.0
%PYTHON_EXE% -m pip install beautifulsoup4==4.12.2

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Edit config\config.json with your info
echo 2. Put your resume in resumes\ folder
echo 3. Run: RUN.bat
echo.
pause
