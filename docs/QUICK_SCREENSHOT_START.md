# 🚀 Hızlı Screenshot Başlangıç Rehberi

## En Kolay 3 Yöntem (Hızlıdan Yavaşa)

---

## ⚡ Yöntem 1: Flutter Screenshots Paketi (ÖNERİLEN - Otomatik)

### Avantajlar:
- ✅ Tek komutla tüm screenshots
- ✅ Otomatik boyut ayarlama
- ✅ Frame ekleme desteği
- ✅ Tüm cihazlar için otomatik

### Kurulum (5 dakika):

```bash
# 1. Paketi ekle
flutter pub add --dev screenshots

# 2. Windows için ImageMagick kur (sadece frame eklemek için gerekli)
# İndir: https://imagemagick.org/script/download.php#windows
# Frame istemiyorsanız bu adımı atlayın

# 3. Emulator'ü başlat
flutter emulators --launch Pixel_7_Pro_API_33

# 4. Uygulamayı çalıştır
flutter run

# 5. Screenshots al (başka terminal'de)
flutter pub run screenshots
```

**Sonuç:** Screenshots `screenshots/` klasörüne kaydedilir!

**Not:** Integration test dosyası gerekli. Yoksa Yöntem 2'yi kullanın.

---

## 🎯 Yöntem 2: Manuel Screenshot (EN BASİT - Hemen Başla)

### Avantajlar:
- ✅ Hiçbir ekstra kurulum gerekmez
- ✅ Hemen başlayabilirsiniz
- ✅ Tam kontrol sizde

### Adımlar (10 dakika):

#### Android:
1. Android Studio'da emulator başlat (Pixel 7 Pro)
2. `flutter run` ile uygulamayı çalıştır
3. İstediğiniz ekrana git
4. **Ctrl + S** tuşlarına bas (veya emulator toolbar'dan 📷)
5. Screenshot kaydedilir: `C:\Users\<kullanıcı>\AppData\Local\Android\sdk\platform-tools\screenshots\`

#### iOS (Mac):
1. Xcode Simulator'ü başlat (iPhone 15 Pro)
2. `flutter run` ile uygulamayı çalıştır
3. İstediğiniz ekrana git
4. **Cmd + S** tuşlarına bas
5. Screenshot Desktop'a kaydedilir

#### Boyutları Düzenle:
- **Online:** [Squoosh.app](https://squoosh.app) - Ücretsiz, tarayıcıda
- **Windows:** Paint 3D veya Photos uygulaması
- **Mac:** Preview

**Gerekli Boyutlar:**
- Play Store: 1080 × 1920 px
- App Store (iPhone 15 Pro): 1290 × 2796 px

---

## 🎨 Yöntem 3: Online Araçlar ile Frame Ekleme

### Adımlar:
1. Yöntem 2 ile screenshot alın
2. [Screenshot.rocks](https://screenshot.rocks/) sitesine gidin
3. Screenshot'ı yükleyin
4. Cihaz frame'i seçin (iPhone 15 Pro, Pixel 7 Pro, vb.)
5. İndirin

**Alternatif:** [Squoosh.app](https://squoosh.app) ile boyut düzenleme

---

## 📋 Screenshot Listesi (Hangi Ekranlar?)

### Öncelik Sırası:
1. ✅ **Dashboard** - Ana ekran
2. ✅ **Analysis** - Hemogram analiz sonuçları
3. ✅ **Diet Program** - Beslenme planı
4. ✅ **Family Panel** - Aile üyeleri
5. ✅ **Reminders** - Hatırlatıcılar
6. ✅ **Challenges** - Motivasyon (opsiyonel)

### Play Store:
- Minimum: 4 screenshot
- Önerilen: 6-8 screenshot
- Feature Graphic: 1024 × 500 px (1 adet, zorunlu)

### App Store:
- Minimum: 3 screenshot (her cihaz boyutu için)
- Önerilen: 5-6 screenshot

---

## 💡 Hızlı İpuçları

### Veri Hazırlığı:
- Test kullanıcısı: Phone `5551234567`, Password `1234`
- Gerçekçi hemogram verileri ekleyin
- Aile üyeleri ekleyin
- Hatırlatıcılar oluşturun

### Ekran Hazırlığı:
- Debug banner'ı kapatın (MaterialApp'te)
- Status bar: Saat 10:00, batarya dolu
- Notification'ları kapatın

### Kalite Kontrol:
- ✅ Text okunabilir mi?
- ✅ Kişisel bilgi var mı? (isim, telefon)
- ✅ Boyutlar doğru mu?

---

## 🛠️ Hangi Aracı Kullanmalıyım?

| Durum | Önerilen Yöntem |
|-------|----------------|
| Hızlı başlamak istiyorum | **Yöntem 2: Manuel** |
| Otomatik istiyorum | **Yöntem 1: Flutter Screenshots** |
| Frame eklemek istiyorum | **Yöntem 3: Online Tools** |
| Profesyonel görünüm | **Yöntem 1 + Frame** |

---

## 📚 Detaylı Rehber

Daha detaylı bilgi için: `docs/SCREENSHOT_GUIDE.md`

---

**Hızlı Başlangıç:** Yöntem 2 ile başlayın, sonra frame ekleyin!

