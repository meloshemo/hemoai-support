# Manuel Screenshot Alma Talimatları

Flutter integration test screenshots otomatik olarak kaydedilmediği için, screenshots'ları manuel olarak almanız gerekiyor.

## Adımlar

1. **Uygulamayı çalıştır:**
   ```bash
   flutter run -d emulator-5554
   ```

2. **Her ekran için screenshot al:**
   - Dashboard
   - Hemogram Entry
   - Analysis
   - Notifications
   - Reminders
   - Settings

3. **Screenshots'ları kaydet:**
   - Android: `store_assets/screenshots/android/`
   - iOS: `store_assets/screenshots/ios/`

4. **Dosya isimleri:**
   - `01_dashboard.png`
   - `02_hemogram_entry.png`
   - `03_analysis.png`
   - `04_notifications.png`
   - `05_reminders.png`
   - `06_settings.png`

## Alternatif: Emulator Screenshot

Android Emulator'da:
1. Emulator toolbar'daki kamera ikonuna tıkla
2. Screenshot'ı kaydet
3. `store_assets/screenshots/android/` klasörüne kopyala

iOS Simulator'da (macOS):
1. Cmd+S veya File > New Screenshot
2. Screenshot'ı kaydet
3. `store_assets/screenshots/ios/` klasörüne kopyala

