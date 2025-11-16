# PowerShell script to copy integration test screenshots to store_assets folders
# Usage: .\tool\copy_screenshots.ps1

$integrationResults = "integration_test\screenshots"
$androidTarget = "store_assets\screenshots\android"
$iosTarget = "store_assets\screenshots\ios"

# Create target directories if they don't exist
if (-not (Test-Path $androidTarget)) {
    New-Item -ItemType Directory -Path $androidTarget -Force | Out-Null
}
if (-not (Test-Path $iosTarget)) {
    New-Item -ItemType Directory -Path $iosTarget -Force | Out-Null
}

# Check if integration test screenshots exist
if (Test-Path $integrationResults) {
    $screenshots = Get-ChildItem -Path $integrationResults -Filter "*.png" -Recurse
    
    if ($screenshots.Count -eq 0) {
        Write-Host "No screenshots found in $integrationResults" -ForegroundColor Yellow
        Write-Host "Run integration test first:" -ForegroundColor Yellow
        Write-Host "  flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_flow_test.dart -d <device>" -ForegroundColor Cyan
        exit 1
    }
    
    Write-Host "Found $($screenshots.Count) screenshot(s)" -ForegroundColor Green
    
    # Copy to both Android and iOS folders (you can filter by device type if needed)
    foreach ($screenshot in $screenshots) {
        $androidPath = Join-Path $androidTarget $screenshot.Name
        $iosPath = Join-Path $iosTarget $screenshot.Name
        
        Copy-Item -Path $screenshot.FullName -Destination $androidPath -Force
        Copy-Item -Path $screenshot.FullName -Destination $iosPath -Force
        
        Write-Host "Copied: $($screenshot.Name)" -ForegroundColor Gray
    }
    
    Write-Host "`nScreenshots copied to:" -ForegroundColor Green
    Write-Host "  - $androidTarget" -ForegroundColor Cyan
    Write-Host "  - $iosTarget" -ForegroundColor Cyan
} else {
    Write-Host "Integration test screenshots directory not found: $integrationResults" -ForegroundColor Yellow
    Write-Host "Run integration test first to generate screenshots." -ForegroundColor Yellow
    exit 1
}

