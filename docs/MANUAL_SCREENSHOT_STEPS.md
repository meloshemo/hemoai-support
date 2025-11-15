# Manuel Screenshot Alma - Adım Adım

## ✅ En Kolay ve Güvenilir Yöntem

### 1. Emulator'ü Başlat
```bash
flutter emulators --launch Medium_Phone_API_36.1
```

### 2. Uygulamayı Çalıştır
```bash
flutter run
```

### 3. Test Kullanıcısı ile Giriş Yap
- **Telefon:** 5551234567
- **Şifre:** 1234

### 4. Screenshot Al
- Emulator toolbar'dan **📷** ikonuna tıklayın
- VEYA **Ctrl + S** tuşlarına basın
- Screenshot otomatik kaydedilir

### 5. Screenshot Konumu
Windows'ta screenshots şuraya kaydedilir:
```
C:\Users\<kullanıcı>\AppData\Local\Android\sdk\platform-tools\screenshots\
```

### 6. Boyutları Kontrol Et
- Screenshot genelde **1080 × 1920 px** olmalı
- Gerekirse [Squoosh.app](https://squoosh.app) ile resize edin

---

## 📋 Alınacak Screenshots Listesi

### Öncelik Sırası:
1. ✅ **Dashboard** - Ana ekran, sağlık metrikleri
2. ✅ **Analysis** - Hemogram analiz sonuçları  
3. ✅ **Diet Program** - Kişiselleştirilmiş beslenme planı
4. ✅ **Family Panel** - Aile üyeleri yönetimi
5. ✅ **Reminders** - Hatırlatıcılar listesi
6. ✅ **Challenges** - Motivasyon ve rozetler (opsiyonel)

### Play Store Gereksinimleri:
- **Minimum:** 4 screenshot
- **Önerilen:** 6-8 screenshot
- **Boyut:** 1080 × 1920 px
- **Format:** PNG veya JPG

---

## 🎨 Screenshot İçeriği İpuçları

### Veri Hazırlığı:
- Test kullanıcısı ile giriş yapın
- Gerçekçi hemogram verileri ekleyin
- Aile üyeleri ekleyin
- Hatırlatıcılar oluşturun

### Ekran Hazırlığı:
- Debug banner'ı kapatın (MaterialApp'te)
- Status bar: Saat 10:00, batarya dolu
- Notification'ları kapatın

### Kalite Kontrol:
- ✅ Text okunabilir mi? (100% zoom'da kontrol)
- ✅ Kişisel bilgi var mı? (isim, telefon)
- ✅ Boyutlar doğru mu? (1080×1920)

---

## 🛠️ Boyut Düzenleme

### Online Tool (Önerilen):
1. [Squoosh.app](https://squoosh.app) sitesine gidin
2. Screenshot'ı yükleyin
3. Boyutu 1080 × 1920 px'e ayarlayın
4. İndirin

### Windows:
- **Paint 3D:** Resize > 1080 × 1920
- **Photos:** Edit > Resize

---

## 📁 Dosya Organizasyonu

Screenshots'ları şu şekilde organize edin:
```
release/
  assets/
    play-store/
      screenshots/
        01_dashboard.png
        02_analysis.png
        03_diet.png
        04_family.png
        05_reminders.png
      feature-graphic.png
```

---

## ⚡ Hızlı İpuçları

1. **Hızlı Navigasyon:** Her ekranda screenshot alın, sonra düzenleyin
2. **Batch İşleme:** Tüm screenshots'ları bir kerede [Squoosh.app](https://squoosh.app) ile resize edin
3. **Frame Ekleme (Opsiyonel):** [Screenshot.rocks](https://screenshot.rocks/) ile telefon çerçevesi ekleyin

---

**Tahmini Süre:** 30-60 dakika (6 screenshot için)

