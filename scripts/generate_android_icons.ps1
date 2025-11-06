# Android İkon Oluşturma Scripti
# Bu script, flutter_launcher_icons paketini kullanarak Android ikonlarını otomatik oluşturur

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Android İkon Oluşturma" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# İkon dosyası kontrolü
$iconPath = "assets/icon/icon.png"
if (-not (Test-Path $iconPath)) {
    Write-Host "HATA: İkon dosyası bulunamadı!" -ForegroundColor Red
    Write-Host "Lutfen ikon dosyanizi su konuma koyun: $iconPath" -ForegroundColor Yellow
    Write-Host "Boyut: 1024x1024 px" -ForegroundColor Yellow
    Write-Host "Format: PNG" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ İkon dosyası bulundu: $iconPath" -ForegroundColor Green
Write-Host ""

# Paketleri yükle
Write-Host "Paketler yukleniyor..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: Paketler yuklenemedi!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Paketler yuklendi" -ForegroundColor Green
Write-Host ""

# İkonları oluştur
Write-Host "Android ikonlari olusturuluyor..." -ForegroundColor Yellow
flutter pub run flutter_launcher_icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: İkonlar olusturulamadi!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Basarili! Android ikonlari olusturuldu" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Olusturulan dosyalar:" -ForegroundColor Cyan
Write-Host "  - android/app/src/main/res/mipmap-*/ic_launcher.png" -ForegroundColor White
Write-Host "  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" -ForegroundColor White
Write-Host ""
Write-Host "Test etmek icin:" -ForegroundColor Yellow
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""

