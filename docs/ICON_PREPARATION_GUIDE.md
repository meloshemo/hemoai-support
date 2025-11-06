# İkon Hazırlama Rehberi

## 📐 Gerekli Boyutlar

### Play Store (Android)
- **512x512 px** (Play Store listing icon)
- **Adaptive Icon:**
  - Foreground: 1024x1024 px (safe zone: 432x432 px merkez)
  - Background: 1024x1024 px (opsiyonel, gradient veya düz renk)

### App Store (iOS)
- **1024x1024 px** (App Store listing icon)
- Tüm boyutlar otomatik oluşturulur (Xcode)

## 🎨 Tasarım Kuralları

### ❌ YAPMAYIN
- İkon içinde metin kullanmayın
- Telif hakkı ihlali yapabilecek görseller kullanmayın
- Şeffaf arka plan kullanmayın (Android Adaptive Icon için)
- Kenarlarda önemli detaylar bırakmayın (maskelenir)

### ✅ YAPIN
- Sadece görsel simge kullanın
- Merkeze hizalayın (safe zone)
- Yüksek kontrast kullanın
- Basit ve anlaşılır tasarım
- Farklı arka planlarda test edin

## 🔧 İkon Oluşturma Adımları

### 1. Ana İkonu Hazırlayın
```
Boyut: 1024x1024 px
Format: PNG (32-bit)
Arka Plan: Teal dairesel disk (veya gradient)
Ön Plan: Kırmızı kan damlası + grafik deseni
Metin: YOK (sadece görsel)
```

### 2. Android Adaptive Icon Oluşturun

**Foreground Layer:**
- 1024x1024 px
- Safe zone: 432x432 px (merkez %42)
- Önemli detaylar safe zone içinde olmalı

**Background Layer (Opsiyonel):**
- 1024x1024 px
- Düz renk veya gradient
- Teal renk önerilir

**Oluşturma:**
```bash
# Android Studio'da:
# File > New > Image Asset
# Launcher Icons (Adaptive and Legacy)
# Foreground: Kan damlası ikonu
# Background: Teal renk veya gradient
```

### 3. iOS İkon Oluşturun

**Ana İkon:**
- 1024x1024 px
- PNG formatı
- Şeffaf arka plan olabilir (iOS otomatik yuvarlar)

**Xcode'da:**
```
Runner.xcworkspace aç
Assets.xcassets > AppIcon
1024x1024 ikonu sürükle-bırak
Xcode otomatik olarak tüm boyutları oluşturur
```

### 4. Web İkonları (Opsiyonel)

**Boyutlar:**
- 192x192 px
- 512x512 px
- Maskable: 192x192, 512x512 (Android PWA için)

## 🛠️ Araçlar

### Online İkon Oluşturucular
1. **Android Asset Studio** (Google)
   - https://romannurik.github.io/AndroidAssetStudio/
   - Adaptive Icon oluşturur

2. **App Icon Generator**
   - https://www.appicon.co/
   - Tüm platformlar için otomatik oluşturur

3. **IconKitchen** (Google)
   - https://icon.kitchen/
   - Adaptive Icon için

### Desktop Araçlar
- **Adobe Photoshop/Illustrator**
- **Figma** (ücretsiz)
- **GIMP** (ücretsiz)
- **Sketch** (Mac)

### Flutter Paketleri
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

**Kullanım:**
```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # 1024x1024 px
  adaptive_icon_background: "#0175C2"  # Teal
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
```

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## ✅ Test Checklist

- [ ] 20x20 px boyutunda okunabilir mi?
- [ ] 512x512 px Play Store boyutunda net mi?
- [ ] 1024x1024 px App Store boyutunda net mi?
- [ ] Android Adaptive Icon safe zone içinde mi?
- [ ] Farklı arka planlarda (açık/koyu) görünür mü?
- [ ] Maskelendiğinde (yuvarlak) detaylar kayboluyor mu?
- [ ] Metin var mı? (Olmamalı)
- [ ] Telif hakkı sorunu var mı?

## 📦 İkon Dosyalarını Yerleştirme

### Android
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
└── mipmap-anydpi-v26/ic_launcher.xml (Adaptive Icon)
```

### iOS
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
└── Icon-App-1024x1024@1x.png (1024x1024)
```

### Web
```
web/icons/
├── Icon-192.png
├── Icon-512.png
├── Icon-maskable-192.png
└── Icon-maskable-512.png
```

## 🚀 Hızlı Başlangıç

### Otomatik Oluşturma (Önerilen)

1. **1024x1024 px ana ikonu hazırla** (metin olmadan)
2. **pubspec.yaml'a ekle:**
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#0175C2"
```

3. **Çalıştır:**
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

4. **Test et:**
```bash
flutter run
```

## 📝 Notlar

- İkon içinde metin kullanmayın (Play Store/App Store kuralları)
- Android Adaptive Icon için safe zone'a dikkat edin
- Farklı boyutlarda test edin
- Telif hakkı ihlali yapmayın
- Basit ve anlaşılır tutun


