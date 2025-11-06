# Fiziksel Cihazda Test ve Screenshot Alma Rehberi

## Yöntem 1: USB Debugging ile Direkt Çalıştırma (Önerilen)

### Adımlar:

1. **USB Debugging'i Aktifleştir:**
   - Telefonda: Ayarlar > Telefon Hakkında > Yapı Numarası'na 7 kez dokunun (Developer Options açılır)
   - Ayarlar > Geliştirici Seçenekleri > USB Debugging'i açın

2. **USB ile Bağlayın:**
   - Telefonu USB ile bilgisayara bağlayın
   - Telefonda "USB Debugging izni ver" pop-up'ına "İzin Ver" deyin

3. **Cihazı Kontrol Edin:**
   ```bash
   flutter devices
   ```
   Telefonunuz listede görünmeli.

4. **Uygulamayı Çalıştırın:**
   ```bash
   flutter run --release
   ```
   veya debug modunda:
   ```bash
   flutter run
   ```

5. **Screenshot Alma:**
   - Android Studio: View > Tool Windows > Device File Explorer
   - ADB ile: `adb shell screencap -p /sdcard/screenshot.png`
   - Telefonun kendi screenshot özelliğini kullanın (Power + Volume Down)

## Yöntem 2: APK Oluşturup Manuel Yükleme

### Release APK Oluşturma:

1. **APK Oluşturun:**
   ```bash
   flutter build apk --release
   ```
   
   APK dosyası şu konumda oluşur:
   `build/app/outputs/flutter-apk/app-release.apk`

2. **APK'yı Telefona Aktarın:**
   - USB ile: `build/app/outputs/flutter-apk/app-release.apk` dosyasını telefona kopyalayın
   - Email/Cloud: APK'yı kendinize email ile gönderin veya cloud'a yükleyin
   - ADB ile direkt yükleme:
     ```bash
     flutter install
     ```
     veya:
     ```bash
     adb install build/app/outputs/flutter-apk/app-release.apk
     ```

3. **Telefonda Yükleyin:**
   - Dosya Yöneticisi'nde APK'yı bulun
   - Bilinmeyen kaynaklardan yükleme izni verin (gerekirse)
   - APK'ya dokunup yükleyin

4. **Screenshot Alma:**
   - Uygulamayı açıp istediğiniz ekranlara gidin
   - Telefonun screenshot özelliğini kullanın

## Yöntem 3: App Bundle (AAB) Oluşturma (Play Store için)

Play Store'a yüklemek için AAB formatı gereklidir:

```bash
flutter build appbundle --release
```

AAB dosyası:
`build/app/outputs/bundle/release/app-release.aab`

**Not:** AAB dosyasını doğrudan telefona yükleyemezsiniz. Play Store'da internal testing track'e yükleyip test edebilirsiniz.

## Yöntem 4: Internal Testing Track (Play Store)

1. Play Console'da Internal Testing track oluşturun
2. AAB dosyasını yükleyin
3. Test kullanıcıları ekleyin (kendi email'inizi ekleyebilirsiniz)
4. Play Store'dan indirip test edin

## Screenshot Alma Araçları

### ADB ile Screenshot:
```bash
# Screenshot al
adb shell screencap -p /sdcard/screenshot.png

# Bilgisayara kopyala
adb pull /sdcard/screenshot.png .
```

### Frame-by-Frame Screenshot Script:
```bash
# Windows PowerShell
$counter = 1
while ($true) {
    adb shell screencap -p /sdcard/screen$counter.png
    adb pull /sdcard/screen$counter.png
    $counter++
    Start-Sleep -Seconds 2
}
```

### Android Studio:
- View > Tool Windows > Device File Explorer
- `/sdcard/` klasörüne gidin
- Screenshot dosyalarını bulun ve indirin

## Önerilen Screenshot Boyutları (Play Store)

- **Phone Screenshots:**
  - Minimum: 320px
  - Maximum: 3840px
  - Aspect Ratio: 16:9 veya 9:16
  - Önerilen: 1080x1920 (Portrait) veya 1920x1080 (Landscape)

- **Tablet Screenshots:**
  - Minimum: 320px
  - Maximum: 3840px
  - Aspect Ratio: 16:9 veya 9:16

- **TV Screenshots:**
  - 1280x720 minimum

## Hızlı Komutlar

### APK Oluştur ve Yükle:
```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Cihaz Listesi:
```bash
flutter devices
adb devices
```

### Logları İzle:
```bash
flutter logs
# veya
adb logcat
```

## Troubleshooting

### "USB Debugging not working":
- USB kablosunu değiştirin
- Farklı USB port deneyin
- Telefonda "USB Debugging" iznini tekrar verin

### "Device not found":
```bash
adb kill-server
adb start-server
adb devices
```

### "Installation failed":
- Eski uygulamayı silin: `adb uninstall com.example.hemoai`
- Tekrar deneyin

## Play Store Screenshot Gereksinimleri

1. **Minimum 2 screenshot** (Phone)
2. **Tablet screenshot** (opsiyonel ama önerilir)
3. **Feature Graphic** (1024x500)
4. **Promo Graphic** (180x120)
5. **App Icon** (512x512)

## Önerilen Screenshot Sırası

1. Ana ekran (Home/Dashboard)
2. Hemogram analiz ekranı
3. AI Insights ekranı
4. Diyet programı ekranı
5. Family panel ekranı
6. Challenges/Motivation ekranı
7. Premium özellikler ekranı

