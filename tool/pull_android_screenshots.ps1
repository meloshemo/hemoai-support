param(
  [Parameter(Mandatory=$false)][string]$OutFolder = "docs/screenshots/2025-11-17-android"
)

$ErrorActionPreference = 'Stop'

function Resolve-AdbPath {
  $candidates = @()
  if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe') }
  if ($env:ANDROID_HOME)   { $candidates += (Join-Path $env:ANDROID_HOME   'platform-tools\adb.exe') }
  $cmd = (Get-Command adb -ErrorAction SilentlyContinue)
  if ($cmd) { $candidates += $cmd.Source }
  foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
  throw 'adb not found in PATH or standard locations.'
}

$adb = Resolve-AdbPath

$pkgs = @('com.meloshemo.hemoai','com.example.hemoai')
$dateTag = '2025-11-17-android'
$roots = @('/data/user/0','/data/data')
$found = $false
$remoteDir = ''
$pkgSel = ''
$useExternal = $false
$zipFound = $false
$zipPath = ''
foreach ($p in $pkgs) {
  foreach ($root in $roots) {
    try {
      $probeBase = "$root/$p/app_flutter"
      $out = & $adb shell run-as $p ls -1 $probeBase 2>&1
      if ($LASTEXITCODE -eq 0 -and $out -notmatch 'No such file') {
        # Prefer a prebuilt zip if present
        $zipCandidate = "$probeBase/hemoai_screens_${dateTag}.zip"
        $zls = & $adb shell run-as $p ls -1 "$zipCandidate" 2>&1
        if ($LASTEXITCODE -eq 0 -and $zls -and $zls -notmatch 'No such file') {
          $pkgSel = $p; $zipPath = $zipCandidate; $zipFound = $true; $found = $true; break
        }
        $candidate = "$probeBase/hemoai_screens"
        $ls = & $adb shell run-as $p ls -1 $candidate 2>&1
        if ($LASTEXITCODE -eq 0 -and $ls -and $ls -notmatch 'No such file') {
          $pkgSel = $p
          $remoteDir = $candidate
          $found = $true
          break
        }
      }
    } catch {}
  }
  if ($found) { break }
}
if (-not $found) {
  # Fallback: try external storage locations which are adb-readable without run-as
  $externalRoots = @('/sdcard/Android/data','/storage/emulated/0/Android/data')
  foreach ($p in $pkgs) {
    foreach ($root in $externalRoots) {
      try {
        $candidate = "$root/$p/files/hemoai_screens"
        $out = & $adb shell ls -1 "$candidate" 2>&1
        if ($LASTEXITCODE -eq 0 -and $out -and $out -notmatch 'No such file') {
          $pkgSel = $p
          $remoteDir = $candidate
          $useExternal = $true
          $found = $true
          break
        }
      } catch {}
    }
    if ($found) { break }
  }
}

if (-not $found) {
  # Final fallback: a zip file placed in public Downloads by the test
  $dlCandidates = @(
    "/sdcard/Download/HemoAI-${dateTag}.zip",
    "/storage/emulated/0/Download/HemoAI-${dateTag}.zip"
  )
  foreach ($c in $dlCandidates) {
    $probe = & $adb shell ls -1 "$c" 2>&1
    if ($LASTEXITCODE -eq 0 -and $probe -and $probe -notmatch 'No such file') {
      $zipFound = $true
      $zipPath = $c
      $found = $true
      break
    }
  }
}

if (-not $found) { throw 'No hemoai_screens directory found under known package names and roots (internal or external).' }

$dest = Join-Path (Get-Location) $OutFolder
if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

if ($zipFound -and $zipPath -like '*/Download/*') {
  Write-Host "Pulling public zip: $zipPath"
  $localZip = Join-Path $dest ("hemoai_screens_" + $dateTag + ".zip")
  & $adb pull "$zipPath" "$localZip" | Out-Null
  if (Test-Path -LiteralPath $localZip) {
    try { Expand-Archive -LiteralPath $localZip -DestinationPath $dest -Force } catch {}
  }
} elseif ($zipFound) {
  Write-Host "Pulling zip: $zipPath"
  $localZip = Join-Path $dest ("hemoai_screens_" + $dateTag + ".zip")
  $cmdLine = '"' + $adb + '" exec-out run-as ' + $pkgSel + ' cat ' + '"' + $zipPath + '" > ' + '"' + $localZip + '"'
  cmd.exe /c $cmdLine | Out-Null
  if (Test-Path -LiteralPath $localZip) {
    try { Expand-Archive -LiteralPath $localZip -DestinationPath $dest -Force } catch {}
  }
} elseif ($useExternal) {
  # Pull whole directory when using external path
  Write-Host "Pulling external directory: $remoteDir"
  & $adb pull "$remoteDir" "$dest" | Out-Null
  $nested = Join-Path $dest 'hemoai_screens'
  if (Test-Path -LiteralPath $nested) {
    Get-ChildItem -LiteralPath $nested -File | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination (Join-Path $dest $_.Name) -Force }
    Remove-Item -LiteralPath $nested -Recurse -Force
  }
} else {
  # Pull files via exec-out run-as cat
  $files = (& $adb shell run-as $pkgSel ls -1 $remoteDir | Where-Object { $_ -match '\.png$' })
  foreach ($f in $files) {
    $remoteFile = "$remoteDir/$f"
    $localFile  = Join-Path $dest $f
    Write-Host "Pulling: $f"
    # Use cmd.exe redirection to avoid PowerShell parsing quirks
    $cmdLine = '"' + $adb + '" exec-out run-as ' + $pkgSel + ' cat ' + '"' + $remoteFile + '" > ' + '"' + $localFile + '"'
    cmd.exe /c $cmdLine | Out-Null
  }
}

# Generate a simple index.md
$indexPath = Join-Path $dest 'index.md'
$sourceText = if ($useExternal) { 'Source: external' } elseif ($zipFound) { 'Source: zip' } else { 'Source: internal (run-as)' }
$lines = @()
$lines += '# Android Screenshots'
$lines += ''
$lines += ('Collected from package: ' + $pkgSel)
$lines += $sourceText
$lines += ''
Get-ChildItem -LiteralPath $dest -File | Sort-Object Name | ForEach-Object { $lines += ('- ' + $_.Name) }
$lines | Set-Content -Encoding UTF8 -Path $indexPath

Get-ChildItem -LiteralPath $dest -File | Select-Object Name,Length | Format-Table -AutoSize
Write-Host "Done. Output: $dest"