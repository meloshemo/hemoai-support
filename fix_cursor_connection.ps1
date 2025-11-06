# Cursor Connection Fix Script
# Bu script Cursor'un cache ve log dosyalarını temizler
# Proje dosyalarınıza dokunmaz, sadece Cursor'un geçici dosyalarını temizler

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cursor Bağlantı Sorunu Çözüm Scripti" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cursorAppData = Join-Path $env:APPDATA "Cursor"
$cursorLocalAppData = Join-Path $env:LOCALAPPDATA "Cursor"

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

Write-Host "1. Cursor'u kapatmanız gerekiyor!" -ForegroundColor Yellow
Write-Host "   Lütfen Cursor'u tamamen kapatın ve Enter'a basın..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "2. Cache ve log dosyalarını temizliyorum..." -ForegroundColor Green

$cleanedCount = 0
$errorCount = 0

foreach ($folder in $foldersToClean) {
    $fullPath = Join-Path $cursorAppData $folder
    if (Test-Path $fullPath) {
        try {
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
            Write-Host "   [OK] Temizlendi: $folder" -ForegroundColor Green
            $cleanedCount++
        } catch {
            Write-Host "   [HATA] Temizlenemedi: $folder - $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
}

# LocalAppData'daki cache'i de temizle
if (Test-Path $cursorLocalAppData) {
    $localCache = Join-Path $cursorLocalAppData "Cache"
    if (Test-Path $localCache) {
        try {
            Remove-Item -Path $localCache -Recurse -Force -ErrorAction Stop
            Write-Host "   [OK] Temizlendi: LocalAppData\Cache" -ForegroundColor Green
            $cleanedCount++
        } catch {
            Write-Host "   [HATA] LocalAppData\Cache temizlenemedi" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Temizleme Tamamlandı!" -ForegroundColor Cyan
Write-Host "   Temizlenen: $cleanedCount klasör" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "   Hatalar: $errorCount" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Şimdi Cursor'u yeniden başlatın!" -ForegroundColor Yellow
Write-Host "Eğer sorun devam ederse:" -ForegroundColor Yellow
Write-Host "  1. İnternet bağlantınızı kontrol edin" -ForegroundColor White
Write-Host "  2. VPN/Proxy ayarlarınızı kontrol edin" -ForegroundColor White
Write-Host "  3. Cursor Settings > AI bölümünden API key'inizi kontrol edin" -ForegroundColor White
Write-Host ""



