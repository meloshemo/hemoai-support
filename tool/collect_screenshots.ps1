param(
    [string]$DateTag = $(Get-Date -Format 'yyyy-MM-dd-HHmm')
)

$ErrorActionPreference = 'Stop'

function Get-UniquePath([string]$Path){
    if(-not (Test-Path -LiteralPath $Path)){ return $Path }
    $dir = Split-Path -Parent $Path
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $ext = [System.IO.Path]::GetExtension($Path)
    $i = 1
    while($true){
        $candidate = Join-Path $dir ("{0}_{1}{2}" -f $name,$i,$ext)
        if(-not (Test-Path -LiteralPath $candidate)){ return $candidate }
        $i++
    }
}

Write-Host "Collecting screenshots..." -ForegroundColor Cyan
$root = [string](Get-Location).Path
$srcCandidates = @(
    [System.IO.Path]::Combine($root, 'build', 'integration_test_screenshots'),
    [System.IO.Path]::Combine($root, 'build', 'integration_test_assets'),
    [System.IO.Path]::Combine($root, 'integration_test', 'screenshots'),
    [System.IO.Path]::Combine($root, 'screenshots')
)

$dest = [System.IO.Path]::Combine($root, 'docs', 'screenshots', $DateTag)
if(-not (Test-Path -LiteralPath $dest)){
    New-Item -ItemType Directory -Path $dest | Out-Null
}

$pngs = @()
foreach($src in $srcCandidates){
    if(Test-Path -LiteralPath $src){
        $found = Get-ChildItem -LiteralPath $src -Recurse -Include *.png -File -ErrorAction SilentlyContinue
        if($found){ $pngs += $found }
    }
}

if(-not $pngs -or $pngs.Count -eq 0){
    Write-Warning "No PNG screenshots found in known locations."
    Write-Host "Checked:" -ForegroundColor DarkGray
    $srcCandidates | ForEach-Object { Write-Host " - $_" -ForegroundColor DarkGray }
    exit 0
}

$copied = @()
foreach($f in $pngs){
    $target = [System.IO.Path]::Combine($dest, $f.Name)
    $target = Get-UniquePath -Path $target
    Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    $copied += $target
}

# Generate index.md
$indexPath = [System.IO.Path]::Combine($dest, 'index.md')
"# Screenshots ($DateTag)" | Out-File -LiteralPath $indexPath -Encoding utf8
"" | Add-Content -LiteralPath $indexPath
foreach($img in ($copied | Sort-Object)){
    $rel = Split-Path -Leaf $img
    "- $rel" | Add-Content -LiteralPath $indexPath
}
"" | Add-Content -LiteralPath $indexPath
foreach($img in ($copied | Sort-Object)){
    $rel = Split-Path -Leaf $img
    "![]($rel)" | Add-Content -LiteralPath $indexPath
}

Write-Host "Copied $($copied.Count) screenshot(s) to $dest" -ForegroundColor Green
Write-Host "Index: $indexPath" -ForegroundColor Green
