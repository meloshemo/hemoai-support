# Flutter APK Build and Install Script for Windows
# Kullanım: .\scripts\build_and_install.ps1

Write-Host "=== HemoAI APK Build and Install Script ===" -ForegroundColor Cyan

# 1. Cihazları kontrol et
Write-Host "`n1. Bağlı cihazları kontrol ediyorum..." -ForegroundColor Yellow
$devices = flutter devices 2>&1 | Select-String -Pattern "android|device"
if ($devices.Count -eq 0) {
    Write-Host "HATA: Bağlı Android cihaz bulunamadı!" -ForegroundColor Red
    Write-Host "Lütfen telefonunuzu USB ile bağlayın ve USB Debugging'i açın." -ForegroundColor Yellow
    exit 1
}
Write-Host "Cihaz bulundu: $devices" -ForegroundColor Green

# 2. Release APK oluştur
Write-Host "`n2. Release APK oluşturuluyor..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: APK oluşturulamadı!" -ForegroundColor Red
    exit 1
}
Write-Host "APK başarıyla oluşturuldu!" -ForegroundColor Green

# 3. APK yolunu belirle
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "HATA: APK dosyası bulunamadı: $apkPath" -ForegroundColor Red
    exit 1
}

# 4. Eski uygulamayı kaldır (isteğe bağlı)
Write-Host "`n3. Eski uygulama kaldırılıyor (varsa)..." -ForegroundColor Yellow
adb uninstall com.meloshemo.hemoai 2>&1 | Out-Null

# 5. APK'yı yükle
Write-Host "`n4. APK telefona yükleniyor..." -ForegroundColor Yellow
adb install -r $apkPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: APK yüklenemedi!" -ForegroundColor Red
    Write-Host "Manuel olarak yüklemek için APK konumu: $apkPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ Başarılı! Uygulama telefona yüklendi." -ForegroundColor Green
Write-Host "APK konumu: $apkPath" -ForegroundColor Cyan
Write-Host "`nScreenshot almak için uygulamayı açın ve telefonun screenshot özelliğini kullanın." -ForegroundColor Yellow

