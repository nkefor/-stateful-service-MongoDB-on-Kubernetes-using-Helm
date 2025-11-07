# PowerShell script to fix Python and install dependencies

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Job Automation - Dependency Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Try to find Python in Microsoft Store location (often more reliable)
$pythonPaths = @(
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python313\python.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312\python.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311\python.exe",
    "C:\Python313\python.exe",
    "C:\Python312\python.exe",
    "C:\Python311\python.exe"
)

$pythonExe = $null
foreach ($path in $pythonPaths) {
    if (Test-Path $path) {
        $pythonExe = $path
        Write-Host "Found Python at: $pythonExe" -ForegroundColor Green
        break
    }
}

if (-not $pythonExe) {
    Write-Host "ERROR: Could not find Python installation" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    pause
    exit 1
}

# Test Python
Write-Host ""
Write-Host "Testing Python..." -ForegroundColor Yellow
& $pythonExe --version

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Python is not working correctly" -ForegroundColor Red
    Write-Host "Please reinstall Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host ""
Write-Host "Installing required packages..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Yellow
Write-Host ""

# Install packages one by one to see which one fails
$packages = @(
    "selenium==4.16.0",
    "webdriver-manager==4.0.1",
    "google-api-python-client==2.111.0",
    "google-auth==2.25.2",
    "google-auth-oauthlib==1.2.0",
    "google-auth-httplib2==0.2.0",
    "beautifulsoup4==4.12.2",
    "lxml==5.0.0"
)

$failed = @()
$succeeded = @()

foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Cyan
    & $pythonExe -m pip install $package --quiet --disable-pip-version-check

    if ($LASTEXITCODE -eq 0) {
        $succeeded += $package
        Write-Host "  ✓ $package installed successfully" -ForegroundColor Green
    } else {
        $failed += $package
        Write-Host "  ✗ $package failed to install" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful: $($succeeded.Count)" -ForegroundColor Green
Write-Host "Failed: $($failed.Count)" -ForegroundColor Red

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed packages:" -ForegroundColor Red
    foreach ($pkg in $failed) {
        Write-Host "  - $pkg" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Edit config/config.json with your information"
Write-Host "2. Put your resume in resumes/ folder"
Write-Host "3. Run: python job_autoapply.py"
Write-Host ""
Write-Host "Or just double-click RUN.bat"
Write-Host ""
pause
