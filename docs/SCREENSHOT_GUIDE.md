# Store Screenshots Hazırlama Rehberi

Bu rehber, HemoAI uygulaması için Play Store ve App Store screenshots hazırlamanın en kolay yollarını açıklar.

---

## 🎯 Hızlı Başlangıç: En Kolay Yöntemler

### 1. **Flutter Screenshots Paketi (Önerilen - Otomatik)**
**En kolay ve otomatik yöntem!**

#### Kurulum:
```bash
# pubspec.yaml'a ekleyin (dev_dependencies)
flutter pub add --dev screenshots

# macOS/Linux için ImageMagick gerekli
# Windows için: https://imagemagick.org/script/download.php#windows
```

#### Kullanım:
1. `screenshots.yaml` dosyasını düzenleyin (zaten mevcut)
2. Emulator/Simulator'ü başlatın
3. Çalıştırın:
```bash
flutter pub run screenshots
```

**Avantajları:**
- ✅ Otomatik screenshot alma
- ✅ Tüm cihaz boyutları için otomatik resize
- ✅ Frame ekleme (telefon çerçevesi)
- ✅ Tek komutla tüm screenshots

---

### 2. **Manuel Screenshot Alma (En Basit - Hızlı)**

#### Android (Android Studio Emulator):
1. Emulator'ü başlatın (Pixel 7 Pro önerilir)
2. Uygulamayı çalıştırın: `flutter run`
3. İstediğiniz ekrana gidin
4. **Ctrl + S** (veya emulator toolbar'dan 📷 ikonu)
5. Screenshot otomatik kaydedilir: `C:\Users\<kullanıcı>\AppData\Local\Android\sdk\platform-tools\screenshots\`

#### iOS (Xcode Simulator):
1. Simulator'ü başlatın (iPhone 15 Pro önerilir)
2. Uygulamayı çalıştırın: `flutter run`
3. İstediğiniz ekrana gidin
4. **Cmd + S** (veya Device > Screenshot)
5. Screenshot Desktop'a kaydedilir

#### Boyutları Düzenleme:
- **Online Tool:** [Squoosh.app](https://squoosh.app) - Ücretsiz, tarayıcıda çalışır
- **Windows:** Paint 3D veya Photos uygulaması
- **Mac:** Preview (Cmd + Shift + 4 ile ekran görüntüsü)

---

### 3. **Fastlane Screenshots (iOS için - Gelişmiş)**

Projede zaten `ios/fastlane/Snapfile` mevcut!

#### Kullanım:
```bash
cd ios
fastlane screenshots
```

**Avantajları:**
- ✅ Otomatik tüm cihaz boyutları
- ✅ Frame ekleme
- ✅ App Store'a direkt yükleme desteği

**Kurulum:**
```bash
# macOS gerekli
gem install fastlane
cd ios
fastlane init
```

---

## 📐 Gerekli Boyutlar

### Play Store
| Asset | Boyut | Format | Notlar |
|-------|-------|--------|--------|
| Phone Screenshots | 1080 × 1920 px | PNG/JPG | Min 4, Max 8 adet |
| Feature Graphic | 1024 × 500 px | PNG/JPG | 1 adet (zorunlu) |
| Tablet Screenshots | 1920 × 1200 px | PNG/JPG | Opsiyonel |

### App Store
| Asset | Boyut | Format | Notlar |
|-------|-------|--------|--------|
| iPhone 6.7" (15 Pro Max) | 1290 × 2796 px | PNG/JPG | Min 3 adet |
| iPhone 6.5" (14 Pro Max) | 1284 × 2778 px | PNG/JPG | Min 3 adet |
| iPhone 5.5" (8 Plus) | 1242 × 2208 px | PNG/JPG | Min 3 adet |

---

## 🎨 Screenshot İçeriği Önerileri

### Öncelik Sırası (En Önemliden):
1. **Dashboard** - Ana ekran, sağlık metrikleri
2. **Analysis Screen** - Hemogram analiz sonuçları
3. **Diet Program** - Kişiselleştirilmiş beslenme planı
4. **Family Panel** - Aile üyeleri yönetimi
5. **Reminders** - Hatırlatıcılar listesi
6. **Challenges** - Motivasyon ve rozetler
7. **Settings** - Ayarlar ekranı (opsiyonel)

### İpuçları:
- ✅ **Temiz veri kullanın:** Gerçekçi ama kişisel olmayan veriler
- ✅ **Dark & Light mode:** Her ikisinden de screenshot alın
- ✅ **Tutarlı dil:** Tüm screenshots aynı dilde (TR veya EN)
- ✅ **Status bar:** Saat 10:00, batarya dolu gösterin
- ✅ **Demo hesap:** Test kullanıcısı ile doldurulmuş veriler

---

## 🛠️ Pratik Araçlar ve Eklentiler

### 1. **Flutter Screenshots Paketi**
```yaml
# pubspec.yaml
dev_dependencies:
  screenshots: ^3.2.0
```

**Kurulum:**
```bash
flutter pub get
```

**screenshots.yaml örneği:**
```yaml
devices:
  - name: Pixel 7 Pro
    deviceId: pixel_7_pro
    orientation: Portrait

screens:
  - name: dashboard
    route: /dashboard
  - name: analysis
    route: /analysis
  - name: diet
    route: /diet_program
```

**Çalıştırma:**
```bash
flutter pub run screenshots
```

---

### 2. **VS Code Eklentileri**

#### Flutter Screenshot (VS Code Extension)
- **Adı:** "Flutter Screenshot"
- **Kurulum:** VS Code Extensions'dan arayın
- **Kullanım:** Command Palette (Ctrl+Shift+P) > "Flutter: Take Screenshot"

#### Android Screenshot (VS Code Extension)
- **Adı:** "Android Screenshot"
- Emulator'den direkt screenshot alır

---

### 3. **Online Araçlar**

#### [Squoosh.app](https://squoosh.app)
- ✅ Ücretsiz
- ✅ Tarayıcıda çalışır
- ✅ Boyut düzenleme, sıkıştırma
- ✅ Format dönüştürme

#### [Remove.bg](https://www.remove.bg/)
- Arka plan kaldırma (frame eklemek için)

#### [Canva](https://www.canva.com/)
- Frame ekleme, text overlay
- Store screenshot şablonları mevcut

---

### 4. **Desktop Uygulamaları**

#### Windows:
- **ShareX** (Ücretsiz, açık kaynak)
  - Otomatik screenshot alma
  - Düzenleme araçları
  - Upload desteği
  - İndir: https://getsharex.com/

- **Greenshot** (Ücretsiz, açık kaynak)
  - Basit ve hafif
  - Annotation araçları
  - İndir: https://getgreenshot.org/

#### macOS:
- **CleanShot X** (Ücretli, $29)
  - Profesyonel screenshot aracı
  - Annotation, blur, frame ekleme
  - İndir: https://cleanshot.com/

- **Skitch** (Ücretsiz)
  - Evernote'un screenshot aracı
  - Basit düzenleme

---

### 5. **Frame Ekleme (Telefon Çerçevesi)**

#### Ücretsiz Seçenekler:
1. **Device Frames (Figma)**
   - Figma'da açık kaynak device frame'ler
   - Export PNG olarak

2. **Screenshot Framer (Online)**
   - https://screenshot.rocks/
   - Ücretsiz, tarayıcıda çalışır
   - Çok sayıda cihaz şablonu

3. **App Store Screenshot Builder**
   - https://www.appstorescreenshot.com/
   - Ücretsiz
   - Otomatik frame ekleme

#### Ücretli Seçenekler:
- **Screenshots.pro** ($9/ay)
- **StoreScreenshot** ($19/ay)

---

## 📋 Adım Adım: Manuel Screenshot Alma

### Android için:

1. **Emulator Hazırlığı:**
```bash
# Android Studio'da emulator başlat
# Veya komut satırından:
flutter emulators --launch Pixel_7_Pro_API_33
```

2. **Uygulamayı Çalıştır:**
```bash
flutter run --release
```

3. **Screenshot Al:**
   - Emulator toolbar'dan 📷 ikonuna tıklayın
   - Veya **Ctrl + S** tuşlarına basın
   - Screenshot kaydedilir: `%LOCALAPPDATA%\Android\sdk\platform-tools\screenshots\`

4. **Boyutları Kontrol Et:**
   - Screenshot genelde 1080x1920 olmalı
   - Gerekirse [Squoosh.app](https://squoosh.app) ile resize edin

### iOS için:

1. **Simulator Hazırlığı:**
```bash
# Xcode'da simulator başlat (iPhone 15 Pro)
# Veya komut satırından:
open -a Simulator
```

2. **Uygulamayı Çalıştır:**
```bash
flutter run --release
```

3. **Screenshot Al:**
   - **Cmd + S** tuşlarına basın
   - Veya Device > Screenshot menüsünden
   - Screenshot Desktop'a kaydedilir

4. **Boyutları Kontrol Et:**
   - iPhone 15 Pro: 1290 × 2796 px
   - Gerekirse Preview ile resize edin

---

## 🚀 Hızlı Başlangıç: Flutter Screenshots Paketi

### 1. Paketi Ekleyin:
```bash
flutter pub add --dev screenshots
```

### 2. screenshots.yaml'ı Düzenleyin:
```yaml
# screenshots.yaml
devices:
  - name: Pixel 7 Pro
    deviceId: pixel_7_pro
    orientation: Portrait

screens:
  - name: dashboard
    route: /dashboard
  - name: analysis
    route: /analysis
  - name: diet
    route: /diet_program
  - name: family
    route: /family_panel
  - name: reminders
    route: /reminders
  - name: challenges
    route: /challenges

frame: true  # Telefon çerçevesi ekle
```

### 3. Çalıştırın:
```bash
# Emulator'ü başlatın
flutter emulators --launch Pixel_7_Pro_API_33

# Screenshots alın
flutter pub run screenshots
```

### 4. Sonuçlar:
Screenshots `screenshots/` klasörüne kaydedilir!

---

## 💡 İpuçları ve Best Practices

### 1. **Veri Hazırlığı:**
- Test kullanıcısı oluşturun (phone: 5551234567, password: 1234)
- Gerçekçi hemogram verileri ekleyin
- Aile üyeleri ekleyin
- Hatırlatıcılar oluşturun

### 2. **Ekran Hazırlığı:**
- Debug banner'ı kapatın: `MaterialApp(debugShowCheckedModeBanner: false)`
- Status bar'ı düzenleyin (saat 10:00, batarya dolu)
- Notification'ları kapatın

### 3. **Kalite Kontrol:**
- ✅ Text okunabilir mi? (100% zoom'da kontrol)
- ✅ Renk kontrastı yeterli mi? (WCAG AA)
- ✅ Kişisel bilgi var mı? (isim, telefon, email)
- ✅ Boyutlar doğru mu? (1080x1920, 1290x2796, vb.)

### 4. **Organizasyon:**
```
release/
  assets/
    play-store/
      screenshots/
        01_dashboard.png
        02_analysis.png
        03_diet.png
        ...
      feature-graphic.png
    app-store/
      iphone-6.7/
        01_dashboard.png
        ...
```

---

## 🎯 Önerilen Workflow

### Seçenek 1: Otomatik (Flutter Screenshots)
1. `screenshots.yaml` düzenle
2. `flutter pub run screenshots` çalıştır
3. Frame ekle (opsiyonel)
4. Store'a yükle

**Süre:** ~30 dakika

### Seçenek 2: Yarı-Otomatik (Manuel + Online Tools)
1. Emulator'den manuel screenshot al
2. [Squoosh.app](https://squoosh.app) ile resize et
3. [Screenshot.rocks](https://screenshot.rocks) ile frame ekle
4. Store'a yükle

**Süre:** ~2-3 saat

### Seçenek 3: Tam Manuel (En Kontrollü)
1. Emulator'den screenshot al
2. Photoshop/Figma ile düzenle
3. Frame ekle, text overlay ekle
4. Store'a yükle

**Süre:** ~1 gün

---

## 📚 Ek Kaynaklar

- [Flutter Screenshots Paketi](https://pub.dev/packages/screenshots)
- [Play Store Screenshot Gereksinimleri](https://support.google.com/googleplay/android-developer/answer/9866151)
- [App Store Screenshot Gereksinimleri](https://developer.apple.com/app-store/product-page/)
- [Fastlane Screenshots](https://docs.fastlane.tools/actions/snapshot/)

---

## ❓ Sık Sorulan Sorular

**S: Hangi yöntemi kullanmalıyım?**
A: Hızlı başlamak için **Flutter Screenshots paketi** önerilir. Daha fazla kontrol istiyorsanız **manuel + online tools** kullanın.

**S: Frame eklemek zorunlu mu?**
A: Hayır, ama profesyonel görünüm için önerilir. Play Store'da frame'siz screenshots da kabul edilir.

**S: Kaç screenshot yeterli?**
A: Play Store: Minimum 4, önerilen 6-8. App Store: Minimum 3, önerilen 5-6.

**S: Screenshot'ları hangi dilde hazırlamalıyım?**
A: Ana pazarınıza göre. Türkiye için Türkçe, global için İngilizce önerilir.

---

**Son Güncelleme:** 2025-01-XX  
**Hazırlayan:** AI Assistant

