Param(
  [Parameter(Mandatory=$true)][string]$HostName,
  [Parameter(Mandatory=$true)][string]$Email,
  [string]$IngressNs = "ingress-nginx"
)

function Exec {
  param([string]$Cmd)
  Write-Host "→ $Cmd" -ForegroundColor Cyan
  $LASTEXITCODE = 0
  cmd /c $Cmd
  if ($LASTEXITCODE -ne 0) { throw "Command failed: $Cmd" }
}

# Load versions.env if present
$Versions = @{}
if (Test-Path -Path "versions.env") {
  Get-Content versions.env | ForEach-Object {
    if ($_ -and ($_ -notmatch '^#')) {
      $parts = $_.Split('=')
      if ($parts.Length -ge 2) {
        $key = $parts[0]
        $val = $parts[1..($parts.Length-1)] -join '='
        $Versions[$key] = $val
      }
    }
  }
}
$CertVer = $Versions['HELM_CERT_MANAGER_CHART_VERSION']

Write-Host "Installing cert-manager via Helm..." -ForegroundColor Green
Exec "helm repo add jetstack https://charts.jetstack.io"
Exec "helm repo update"
Exec "kubectl create ns cert-manager --dry-run=client -o yaml | kubectl apply -f -"
if ($CertVer) {
  Exec "helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true --version $CertVer"
} else {
  Exec "helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true"
}

Write-Host "Applying ClusterIssuer with email: $Email" -ForegroundColor Green
$issuer = Get-Content k8s/cert-manager-clusterissuer.yaml -Raw
$issuer = $issuer -replace 'email: .*', "email: $Email"
Set-Content -Path k8s/cert-manager-clusterissuer.yaml -Value $issuer -Encoding UTF8
Exec "kubectl apply -f k8s/cert-manager-clusterissuer.yaml"

Write-Host "Patching Ingress host and enabling TLS: $HostName" -ForegroundColor Green
$ing = Get-Content k8s/mongo-express-ingress.yaml -Raw
$ing = $ing -replace 'host: .*', "host: $HostName"
$ing = $ing -replace '(hosts:\s*\n\s*- ).*', "`$1$HostName"
Set-Content -Path k8s/mongo-express-ingress.yaml -Value $ing -Encoding UTF8
Exec "kubectl apply -f k8s/mongo-express-ingress.yaml"

Write-Host "TLS setup complete. Inspect cert resources in tools namespace." -ForegroundColor Green
cmd /c "kubectl -n tools get certificate,order,challenge"
