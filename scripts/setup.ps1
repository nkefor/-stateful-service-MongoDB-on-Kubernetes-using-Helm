Param(
  [Parameter(Mandatory=$true)][string]$HostName,
  [string]$NamespaceData = "data",
  [string]$NamespaceTools = "tools",
  [string]$IngressNs = "ingress-nginx",
  [string]$MongoRelease = "mongo",
  [string]$MongoValues = "k8s/mongodb-values.yaml"
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

$IngressVer = $Versions['HELM_INGRESS_NGINX_CHART_VERSION']
$MongoVer = $Versions['HELM_MONGODB_CHART_VERSION']

Write-Host "Installing NGINX Ingress Controller..." -ForegroundColor Green
Exec "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Exec "helm repo update"
Exec "kubectl create ns $IngressNs --dry-run=client -o yaml | kubectl apply -f -"
if ($IngressVer) {
  Exec "helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n $IngressNs --version $IngressVer"
} else {
  Exec "helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n $IngressNs"
}

Write-Host "Deploying MongoDB (Bitnami) with persistence..." -ForegroundColor Green
Exec "helm repo add bitnami https://charts.bitnami.com/bitnami"
Exec "helm repo update"
Exec "kubectl create ns $NamespaceData --dry-run=client -o yaml | kubectl apply -f -"
if ($MongoVer) {
  Exec "helm upgrade --install $MongoRelease bitnami/mongodb -n $NamespaceData -f $MongoValues --version $MongoVer"
} else {
  Exec "helm upgrade --install $MongoRelease bitnami/mongodb -n $NamespaceData -f $MongoValues"
}

Write-Host "Waiting for MongoDB pods to be Ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready pod -n $NamespaceData -l app.kubernetes.io/name=mongodb --timeout=600s

Write-Host "Installing metrics-server (for HPA) if not present..." -ForegroundColor Green
cmd /c "kubectl get deploy -n kube-system metrics-server" 2>$null
if ($LASTEXITCODE -ne 0) {
  Exec "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}

Write-Host "Preparing Mongo Express secrets and deployment..." -ForegroundColor Green
$rootPw = kubectl get secret -n $NamespaceData ${MongoRelease}-mongodb -o jsonpath='{.data.mongodb-root-password}' | %{ [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
if (-not $rootPw) { throw "Could not retrieve Mongo root password" }

Exec "kubectl create ns $NamespaceTools --dry-run=client -o yaml | kubectl apply -f -"
Exec "kubectl create secret generic mongo-root -n $NamespaceTools --from-literal=password=$rootPw --dry-run=client -o yaml | kubectl apply -f -"

# Apply Mongo Express (includes basic-auth secret). Users should change defaults in file.
Exec "kubectl apply -f k8s/mongo-express.yaml"

Write-Host "Applying HPA for Mongo Express..." -ForegroundColor Green
Exec "kubectl apply -f k8s/mongo-express-hpa.yaml"

Write-Host "Applying Ingress with host: $HostName" -ForegroundColor Green
$ingressPath = "k8s/mongo-express-ingress.yaml"
$ingress = Get-Content $ingressPath -Raw
$ingress = $ingress -replace 'host: .*', "host: $HostName"
Set-Content -Path $ingressPath -Value $ingress -Encoding UTF8
Exec "kubectl apply -f $ingressPath"

Write-Host "Done. Check resources:" -ForegroundColor Green
kubectl get svc -n $IngressNs ingress-nginx-controller
kubectl get deploy,po,svc -n $NamespaceTools
