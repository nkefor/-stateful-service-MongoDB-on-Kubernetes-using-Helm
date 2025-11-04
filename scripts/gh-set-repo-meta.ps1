Param(
  [Parameter(Mandatory=$true)][string]$Description,
  [Parameter(Mandatory=$true)][string]$TopicsCsv
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI (gh) not found. Install from https://cli.github.com/"
  exit 2
}

$topics = $TopicsCsv.Split(',')
$args = @('repo','edit','--description', $Description)
foreach ($t in $topics) { $args += @('--add-topic', $t.Trim()) }
Write-Host "→ gh $($args -join ' ')" -ForegroundColor Cyan
gh @args

