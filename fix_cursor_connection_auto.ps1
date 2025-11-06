# Cursor Connection Fix Script - Otomatik
# Bu script Cursor'un cache ve log dosyalarını temizler
# Proje dosyalarınıza dokunmaz

$ErrorActionPreference = "Continue"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cursor Bağlantı Sorunu Otomatik Çözüm" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cursorAppData = Join-Path $env:APPDATA "Cursor"
$cleanedCount = 0
$errorCount = 0
$lockedCount = 0

# Temizlenecek klasörler (güvenli - sadece cache ve log)
$foldersToClean = @(
    "Cache",
    "logs",
    "Network",
    "Code Cache",
    "GPUCache",
    "blob_storage",
    "CachedData",
    "CachedConfigurations",
    "CachedExtensionVSIXs",
    "Crashpad",
    "sentry"
)

Write-Host "Cache ve log dosyalarını temizliyorum..." -ForegroundColor Green
Write-Host ""

foreach ($folder in $foldersToClean) {
    $fullPath = Join-Path $cursorAppData $folder
    if (Test-Path $fullPath) {
        try {
            # Dosyaların kilitli olup olmadığını kontrol et
            $items = Get-ChildItem -Path $fullPath -Recurse -ErrorAction SilentlyContinue
            $canDelete = $true
            
            # Kilitli dosyaları atla, diğerlerini sil
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
            Write-Host "   [OK] Temizlendi: $folder" -ForegroundColor Green
            $cleanedCount++
        } catch {
            if ($_.Exception.Message -like "*being used*" -or $_.Exception.Message -like "*kullan*") {
                Write-Host "   [KILITLI] Cursor açık olduğu için temizlenemedi: $folder" -ForegroundColor Yellow
                Write-Host "            Lütfen Cursor'u kapatıp tekrar deneyin" -ForegroundColor Yellow
                $lockedCount++
            } else {
                Write-Host "   [HATA] Temizlenemedi: $folder" -ForegroundColor Red
                Write-Host "          Hata: $($_.Exception.Message)" -ForegroundColor Gray
                $errorCount++
            }
        }
    }
}

# LocalAppData'daki cache'i de temizle
$cursorLocalAppData = Join-Path $env:LOCALAPPDATA "Cursor"
if (Test-Path $cursorLocalAppData) {
    $localCache = Join-Path $cursorLocalAppData "Cache"
    if (Test-Path $localCache) {
        try {
            Remove-Item -Path $localCache -Recurse -Force -ErrorAction Stop
            Write-Host "   [OK] Temizlendi: LocalAppData\Cache" -ForegroundColor Green
            $cleanedCount++
        } catch {
            if ($_.Exception.Message -like "*being used*" -or $_.Exception.Message -like "*kullan*") {
                Write-Host "   [KILITLI] LocalAppData\Cache - Cursor açık" -ForegroundColor Yellow
                $lockedCount++
            } else {
                Write-Host "   [HATA] LocalAppData\Cache temizlenemedi" -ForegroundColor Red
                $errorCount++
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Temizleme Sonuçları:" -ForegroundColor Cyan
Write-Host "   Temizlenen: $cleanedCount klasör" -ForegroundColor Green
if ($lockedCount -gt 0) {
    Write-Host "   Kilitli: $lockedCount klasör (Cursor açık)" -ForegroundColor Yellow
}
if ($errorCount -gt 0) {
    Write-Host "   Hatalar: $errorCount" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($lockedCount -gt 0) {
    Write-Host "UYARI: Bazı dosyalar Cursor açık olduğu için temizlenemedi!" -ForegroundColor Yellow
    Write-Host "Çözüm:" -ForegroundColor Yellow
    Write-Host "  1. Cursor'u tamamen kapatın (tüm pencereler)" -ForegroundColor White
    Write-Host "  2. Görev Yöneticisi'nde kalan Cursor işlemlerini sonlandırın" -ForegroundColor White
    Write-Host "  3. Bu scripti tekrar çalıştırın" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Temizleme tamamlandı! Cursor'u yeniden başlatın." -ForegroundColor Green
    Write-Host ""
    Write-Host "Eğer sorun devam ederse:" -ForegroundColor Yellow
    Write-Host "  1. İnternet bağlantınızı kontrol edin" -ForegroundColor White
    Write-Host "  2. VPN/Proxy ayarlarınızı kontrol edin" -ForegroundColor White
    Write-Host "  3. Cursor Settings > AI bölümünden API key'inizi kontrol edin" -ForegroundColor White
}

Write-Host ""



