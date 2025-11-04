Param(
  [string]$NamespaceData = "data",
  [string]$NamespaceTools = "tools",
  [string]$IngressNs = "ingress-nginx",
  [string]$MongoRelease = "mongo"
)

function Exec {
  param([string]$Cmd)
  Write-Host "→ $Cmd" -ForegroundColor Cyan
  $LASTEXITCODE = 0
  cmd /c $Cmd
}

Write-Host "Removing Ingress and Mongo Express..." -ForegroundColor Green
Exec "kubectl delete -f k8s/mongo-express-ingress.yaml --ignore-not-found"
Exec "kubectl delete -f k8s/mongo-express.yaml --ignore-not-found"

Write-Host "Uninstalling MongoDB chart..." -ForegroundColor Green
Exec "helm uninstall $MongoRelease -n $NamespaceData"
Exec "kubectl delete ns $NamespaceTools --ignore-not-found"
Exec "kubectl delete ns $NamespaceData --ignore-not-found"

Write-Host "Removing ingress controller..." -ForegroundColor Green
Exec "helm uninstall ingress-nginx -n $IngressNs"
Exec "kubectl delete ns $IngressNs --ignore-not-found"

Write-Host "Teardown complete." -ForegroundColor Green

