# Job Automation PowerShell Launcher
# Runs job application automation across 16 platforms

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   JOB AUTOMATION - 16 PLATFORMS" -ForegroundColor Green
Write-Host "   Excludes: LinkedIn & Indeed" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Check requirements
Write-Host "[1/3] Checking requirements..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "   ✓ .env found" -ForegroundColor Green

if (-not (Test-Path "config\config.json")) {
    Write-Host "ERROR: config.json not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "   ✓ config.json found" -ForegroundColor Green

# Create logs directory
Write-Host ""
Write-Host "[2/3] Creating logs directory..." -ForegroundColor Yellow
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}
Write-Host "   ✓ Logs ready" -ForegroundColor Green

# Find Python
Write-Host ""
Write-Host "[3/3] Finding Python..." -ForegroundColor Yellow

$pythonCmd = $null

# Try common Python locations
$pythonPaths = @(
    "C:\Python313\python.exe",
    "C:\Python312\python.exe",
    "C:\Python311\python.exe",
    "C:\Python310\python.exe",
    "C:\Program Files\Python313\python.exe",
    "C:\Program Files\Python312\python.exe"
)

foreach ($path in $pythonPaths) {
    if (Test-Path $path) {
        $pythonCmd = $path
        break
    }
}

# Try system Python
if (-not $pythonCmd) {
    $pythonCmd = (Get-Command python -ErrorAction SilentlyContinue).Source
}

if (-not $pythonCmd) {
    Write-Host "ERROR: Python not found!" -ForegroundColor Red
    Write-Host "Please install Python from python.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "   ✓ Using: $pythonCmd" -ForegroundColor Green

# Show configuration
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   CONFIGURATION" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Platforms: Dice, ZipRecruiter, Glassdoor, BuiltIn,"
Write-Host "           JobRight.AI, WeWorkRemotely, Remotive,"
Write-Host "           LetsWorkRemotely, Toptal, Hired, AngelList,"
Write-Host "           TheLadders, Flexa, Zapier, NoDesk, DynamiteJobs"
Write-Host ""
Write-Host "Job Titles: DevOps Engineer, Cloud Engineer, SRE"
Write-Host "Locations: Remote, United States"
Write-Host "Max Searches: 25"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "Ready to start? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "Automation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   STARTING AUTOMATION" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser will open soon..." -ForegroundColor Yellow
Write-Host "You'll have 45 seconds at each platform to interact." -ForegroundColor Yellow
Write-Host ""

# Run automation
& $pythonCmd "job_apply_all_platforms.py"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "   ERROR OCCURRED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs\job_automation_all_platforms.log for details" -ForegroundColor Yellow
    Write-Host ""

    if ($LASTEXITCODE -eq 1 -and (Get-Content "logs\job_automation_all_platforms.log" -ErrorAction SilentlyContinue | Select-String "ModuleNotFoundError")) {
        Write-Host "Python installation appears corrupted." -ForegroundColor Red
        Write-Host "Recommendation: Reinstall Python from python.org" -ForegroundColor Yellow
    }

    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   AUTOMATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Check logs\ directory for results:" -ForegroundColor Yellow
Get-ChildItem -Path "logs\job_automation_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
    Write-Host "   → $($_.Name)" -ForegroundColor Cyan
}
Write-Host ""

Read-Host "Press Enter to exit"
