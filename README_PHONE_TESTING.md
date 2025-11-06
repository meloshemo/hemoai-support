# Telefonda Test ve Screenshot Alma - Hızlı Başlangıç

## 🚀 En Kolay Yöntem: USB ile Direkt Çalıştırma

### 1. Telefonu Hazırlayın:
- **Ayarlar > Telefon Hakkında > Yapı Numarası**'na 7 kez dokunun
- **Ayarlar > Geliştirici Seçenekleri > USB Debugging**'i açın
- Telefonu USB ile bilgisayara bağlayın
- "USB Debugging izni ver" pop-up'ına **"İzin Ver"** deyin

### 2. Komutları Çalıştırın:

```powershell
# Cihaz bağlı mı kontrol et
flutter devices

# Uygulamayı telefonda çalıştır
flutter run --release
```

### 3. Screenshot Alın:
- Telefonun screenshot özelliğini kullanın (Power + Volume Down)
- Veya ADB ile: `adb shell screencap -p /sdcard/screen.png`

---

## 📱 Alternatif: APK Oluşturup Yükleme

### Otomatik Script (Önerilen):

```powershell
.\scripts\build_and_install.ps1
```

Bu script:
1. ✅ Release APK oluşturur
2. ✅ Telefona yükler
3. ✅ Uygulamayı açar

### Manuel Yöntem:

```powershell
# 1. APK oluştur
flutter build apk --release

# 2. Telefona yükle
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

APK dosyası: `build\app\outputs\flutter-apk\app-release.apk`

---

## 📸 Screenshot Alma Scripti

```powershell
.\scripts\take_screenshots.ps1
```

Bu script:
- Uygulamada istediğiniz ekrana gidin
- Enter'a basın
- Screenshot otomatik olarak `screenshots/` klasörüne kaydedilir

---

## 📋 Play Store Screenshot Gereksinimleri

- **Minimum 2 screenshot** (Phone)
- **Boyut:** 1080x1920 (Portrait) veya 1920x1080 (Landscape)
- **Format:** PNG veya JPG

### Önerilen Screenshot Sırası:
1. Ana ekran (Dashboard)
2. Hemogram analiz ekranı
3. AI Insights ekranı
4. Diyet programı ekranı
5. Family panel ekranı
6. Challenges/Motivation ekranı
7. Premium özellikler ekranı

---

## 🔧 Sorun Giderme

### "Device not found":
```powershell
adb kill-server
adb start-server
adb devices
```

### "USB Debugging not working":
- USB kablosunu değiştirin
- Farklı USB port deneyin
- Telefonda USB Debugging iznini tekrar verin

### "Installation failed":
```powershell
adb uninstall com.meloshemo.hemoai
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## 📚 Detaylı Dokümantasyon

Tüm detaylar için: `docs/PHYSICAL_DEVICE_TESTING.md`

