# Android İkon Kurulum Rehberi

## ✅ Yeni İkon Değerlendirmesi

Yeni ikonunuz **mükemmel** ve Android için tamamen uygun:

### ✅ Güçlü Yönler
- ✅ Metin yok (Play Store kurallarına uygun)
- ✅ Yuvarlatılmış kare (Android Adaptive Icon için ideal)
- ✅ Merkezi kompozisyon (safe zone içinde)
- ✅ Basit ve temiz tasarım
- ✅ Yüksek kontrast (kırmızı-beyaz-gri)
- ✅ Modern görünüm

## 📐 Gerekli Dosyalar

### 1. Ana İkon (Zorunlu)
- **Konum:** `assets/icon/icon.png`
- **Boyut:** 1024x1024 px
- **Format:** PNG (32-bit)
- **İçerik:** 
  - Açık gri yuvarlatılmış kare
  - Merkezde kırmızı kan damlası
  - İçinde beyaz devre/aygıt deseni
  - Hafif gölge efekti

### 2. Foreground İkon (Opsiyonel)
- **Konum:** `assets/icon/icon_foreground.png`
- **Boyut:** 1024x1024 px
- **Format:** PNG (şeffaf arka plan)
- **İçerik:** Sadece kan damlası + desen (arka plan olmadan)

## 🚀 Kurulum Adımları

### Adım 1: İkon Dosyasını Yerleştirin

1. İkon dosyanızı hazırlayın (1024x1024 px PNG)
2. `assets/icon/` klasörüne koyun:
   ```
   assets/icon/icon.png
   ```

### Adım 2: Paketleri Yükleyin

```bash
flutter pub get
```

### Adım 3: İkonları Oluşturun

```bash
flutter pub run flutter_launcher_icons
```

Bu komut otomatik olarak:
- ✅ Tüm Android DPI boyutlarını oluşturur (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- ✅ Android Adaptive Icon yapılandırmasını oluşturur
- ✅ `ic_launcher.xml` dosyasını oluşturur

### Adım 4: Test Edin

```bash
flutter run
```

Android cihazda veya emülatörde ikonu kontrol edin.

## 📁 Oluşturulan Dosyalar

Komut çalıştırıldıktan sonra şu dosyalar oluşturulur:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
└── mipmap-anydpi-v26/
    └── ic_launcher.xml (Adaptive Icon)
```

## 🎨 Android Adaptive Icon

Android 8.0+ (API 26+) için Adaptive Icon kullanılır:

### Yapılandırma
- **Background:** Açık gri (#E0E0E0) - `pubspec.yaml`'da tanımlı
- **Foreground:** Kan damlası + desen (merkezde)
- **Safe Zone:** 432x432 px (merkez %42)

### Mask Çeşitleri
Android sistemi farklı maskeler uygular:
- **Yuvarlak** (çoğu cihaz)
- **Yuvarlatılmış kare** (Pixel)
- **Kare** (bazı cihazlar)

İkonunuz tüm maskelerde iyi görünecek şekilde tasarlanmış.

## ✅ Kontrol Listesi

Kurulumdan önce:
- [ ] İkon dosyası 1024x1024 px mi?
- [ ] PNG formatında mı?
- [ ] Metin içermiyor mu?
- [ ] Merkeze hizalı mı?
- [ ] `assets/icon/icon.png` konumunda mı?

Kurulumdan sonra:
- [ ] `flutter pub get` çalıştırıldı mı?
- [ ] `flutter pub run flutter_launcher_icons` çalıştırıldı mı?
- [ ] Uygulama derlendi mi?
- [ ] İkon cihazda görünüyor mu?
- [ ] Farklı maskelerde test edildi mi?

## 🐛 Sorun Giderme

### İkon görünmüyor
1. `flutter clean` çalıştırın
2. `flutter pub get` çalıştırın
3. `flutter pub run flutter_launcher_icons` çalıştırın
4. Uygulamayı yeniden derleyin

### İkon bulanık
- Ana ikon dosyası 1024x1024 px olmalı
- Yüksek kaliteli PNG kullanın (32-bit)

### Adaptive Icon çalışmıyor
- `mipmap-anydpi-v26/ic_launcher.xml` dosyası oluşturuldu mu?
- Background rengi doğru mu?

## 📝 Play Store İçin

Play Store'a yüklerken:
- **512x512 px** ikon gereklidir (otomatik oluşturulur)
- **Yuvarlak mask** uygulanır
- **Safe zone** içindeki içerik görünür

## 🎯 Sonuç

İkonunuz Android için tamamen hazır! Sadece dosyayı yerleştirip komutları çalıştırmanız yeterli.

**Sıradaki Adımlar:**
1. İkon dosyanızı `assets/icon/icon.png` olarak kaydedin
2. `flutter pub get` çalıştırın
3. `flutter pub run flutter_launcher_icons` çalıştırın
4. Test edin!

