Param(
  [string]$ProdHost,
  [string]$DevHost,
  [string]$Email,
  [string]$MongoRoot,
  [string]$MongoAppUser,
  [string]$MongoAppPass,
  [string]$S3Endpoint,
  [string]$S3Bucket
)

function Patch-File {
  param([string]$Path, [scriptblock]$Edit)
  Write-Host "→ Patching $Path" -ForegroundColor Cyan
  $content = Get-Content $Path -Raw
  $new = & $Edit $content
  Set-Content -Path $Path -Value $new -Encoding UTF8
}

if ($ProdHost) {
  Patch-File "k8s/overlays/prod/ingress-host.yaml" { param($t)
    $t = [Regex]::Replace($t, '(^\s*host:\s*).+$', "`$1$ProdHost", 'Multiline')
    $t = [Regex]::Replace($t, '(?ms)(hosts:\s*\n)\s*-\s*.+', "`$1        - $ProdHost")
    return $t
  }
}
if ($DevHost) {
  Patch-File "k8s/overlays/dev/ingress-host.yaml" { param($t)
    $t = [Regex]::Replace($t, '(^\s*host:\s*).+$', "`$1$DevHost", 'Multiline')
    $t = [Regex]::Replace($t, '(?ms)(hosts:\s*\n)\s*-\s*.+', "`$1        - $DevHost")
    return $t
  }
}

if ($Email) {
  Patch-File "k8s/cert-manager-clusterissuer.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*email:\s*).+$', "`$1$Email", 'Multiline')
  }
}

if ($MongoRoot) {
  Patch-File "k8s/mongodb-values.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*rootPassword:\s*).+$', "`$1$MongoRoot", 'Multiline')
  }
}
if ($MongoAppUser) {
  Patch-File "k8s/mongodb-values.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*-\s*)appuser$', "`$1$MongoAppUser", 'Multiline')
  }
}
if ($MongoAppPass) {
  Patch-File "k8s/mongodb-values.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*-\s*)CHANGEME-APP$', "`$1$MongoAppPass", 'Multiline')
  }
}

if ($S3Endpoint) {
  Patch-File "k8s/backup/mongo-backup-cronjob.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*S3_ENDPOINT:\s*).+$', "`$1`"$S3Endpoint`"", 'Multiline')
  }
}
if ($S3Bucket) {
  Patch-File "k8s/backup/mongo-backup-cronjob.yaml" { param($t)
    return [Regex]::Replace($t, '(^\s*S3_BUCKET:\s*).+$', "`$1`"$S3Bucket`"", 'Multiline')
  }
}

Write-Host "Config patching complete. Review git diff and commit changes." -ForegroundColor Green

