# Otomatik Screenshot Alma - Integration Test Yöntemi

## Durum
`screenshots` paketi null safety desteklemediği için kullanılamıyor. Ancak projede zaten **integration test** ile screenshot alma kodu mevcut!

## Mevcut Integration Test
`integration_test/screenshot_flow_test.dart` dosyası şu ekranları otomatik olarak screenshot alıyor:
1. Notifications (01_notifications)
2. Dashboard (02_dashboard)
3. AI Analysis (03_analysis)
4. Alternative Medicine (04_alternative_medicine)

## Kullanım

### 1. Emulator'ü Başlat
```bash
flutter emulators --launch Medium_Phone_API_36.1
```

### 2. Integration Test'i Çalıştır
```bash
flutter test integration_test/screenshot_flow_test.dart --device-id Medium_Phone_API_36.1
```

### 3. Screenshots Nerede?
Integration test screenshots'ları şu yerlere kaydeder:
- Integration test output: `integration_test/screenshots/`
- External path: Test çıktısında `SCREENSHOT_EXTERNAL_PATH` ile gösterilir

## Alternatif: Manuel Screenshot (Daha Kolay)

Eğer integration test çalışmazsa, manuel yöntem daha kolay:

1. Emulator'ü başlat
2. `flutter run` ile uygulamayı çalıştır
3. İstediğiniz ekrana git
4. **Ctrl + S** tuşlarına bas (veya emulator toolbar'dan 📷)
5. Screenshot kaydedilir: `%LOCALAPPDATA%\Android\sdk\platform-tools\screenshots\`

## Notlar
- Integration test testMode'da çalışır
- Test kullanıcısı otomatik oluşturulur
- ScreenshotOverlayService kullanılıyor (başlık overlay'leri)

