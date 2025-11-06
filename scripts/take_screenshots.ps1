# Screenshot Alma Scripti
# Kullanım: .\scripts\take_screenshots.ps1

Write-Host "=== HemoAI Screenshot Alma Scripti ===" -ForegroundColor Cyan

# Screenshot klasörü oluştur
$screenshotDir = "screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir | Out-Null
}

Write-Host "`nScreenshot'lar '$screenshotDir' klasörüne kaydedilecek." -ForegroundColor Yellow
Write-Host "Uygulamada istediğiniz ekrana gidin ve Enter'a basın." -ForegroundColor Yellow
Write-Host "Çıkmak için 'q' yazıp Enter'a basın.`n" -ForegroundColor Yellow

$counter = 1
while ($true) {
    $input = Read-Host "Enter'a basın (q=çıkış)"
    
    if ($input -eq "q") {
        break
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "screenshot_$counter`_$timestamp.png"
    $localPath = Join-Path $screenshotDir $filename
    $remotePath = "/sdcard/$filename"
    
    Write-Host "Screenshot alınıyor: $filename..." -ForegroundColor Yellow
    
    # Screenshot al
    adb shell screencap -p $remotePath 2>&1 | Out-Null
    
    # Bilgisayara kopyala
    adb pull $remotePath $localPath 2>&1 | Out-Null
    
    # Telefondan sil
    adb shell rm $remotePath 2>&1 | Out-Null
    
    if (Test-Path $localPath) {
        Write-Host "✅ Kaydedildi: $localPath" -ForegroundColor Green
        $counter++
    } else {
        Write-Host "❌ Hata: Screenshot alınamadı!" -ForegroundColor Red
    }
}

Write-Host "`n✅ Toplam $($counter-1) screenshot alındı." -ForegroundColor Green
Write-Host "Screenshot'lar: $screenshotDir" -ForegroundColor Cyan

