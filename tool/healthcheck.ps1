param([switch]$NoBuild)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
Set-Location $root
$log = Join-Path $root "healthcheck.log"
"" | Out-File -FilePath $log -Encoding utf8

function Step($name, $cmd) {
  Write-Host "`n=== $name ==="
  "=== $name ===" | Out-File -FilePath $log -Append -Encoding utf8
  try {
    & $cmd *>> $log
    if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) { throw "$name failed with exit $LASTEXITCODE" }
    Write-Host "OK: $name"
  } catch {
    Write-Host "FAILED: $name"
    Write-Host "See healthcheck.log"
    exit 1
  }
}

Step "Flutter check" { { flutter --version } }
Step "Flutter clean" { { flutter clean } }
Step "Pub get" { { flutter pub get } }

if (Test-Path "$root\tool\validate_localization.dart") {
  Step "Localization validator" { { dart run tool/validate_localization.dart } }
}

Step "Analyze" { { flutter analyze } }

$hasTests = Test-Path "$root\test"
if ($hasTests) { Step "Tests" { { flutter test } } }

if (-not $NoBuild) {
  if ($IsWindows) { Step "Build Windows" { { flutter build windows --release } } }
  Step "Build Web" { { flutter build web --release } }
}

Write-Host "`nAll checks completed. See healthcheck.log"