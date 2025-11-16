# Store Publication Checklist - HemoAI

Bu kontrol listesi, Play Store ve App Store'a yayınlamadan önce tamamlanması gereken tüm adımları içerir.

---

## ✅ Tamamlananlar

### App Icons
- [x] Android launcher icons (tüm boyutlar)
- [x] iOS app icons (tüm boyutlar)
- [x] Web favicon
- [x] Windows/macOS icons
- [x] App Store icon (1024x1024)
- [x] Play Store feature graphic (1024x500) - 3 varyant

### Code Quality
- [x] Kullanılmayan kod temizliği
- [x] BuildContext async gap düzeltmeleri
- [x] Deprecated API kullanımları düzeltildi (`withOpacity` → `withValues`)
- [x] Linter hataları düzeltildi

### Documentation
- [x] Data Safety Declaration dokümantasyonu
- [x] Data Safety Quick Reference
- [x] Screenshots checklist
- [x] Store assets generation scripts

---

## ⏳ Yapılacaklar

### Screenshots (Manuel veya Otomatik)

#### Android (Play Store)
- [ ] Minimum 2 telefon ekran görüntüsü (1080x1920 önerilir)
  - [ ] Dashboard
  - [ ] Hemogram Entry (kategori görünümü)
  - [ ] Analysis (Health Score + Smart Summary)
  - [ ] Notifications (Unread/All)
  - [ ] Reminder List (Upcoming/Overdue/Completed)
  - [ ] Settings (About & Legal bölümü)

**Klasör:** `store_assets/screenshots/android/`

#### iOS (App Store)
- [ ] Minimum 3 iPhone ekran görüntüsü (1284x2778 önerilir)
  - [ ] Dashboard
  - [ ] Hemogram Entry
  - [ ] Analysis
  - [ ] Notifications
  - [ ] Reminder List
  - [ ] Settings

**Klasör:** `store_assets/screenshots/ios/`

**Not:** Integration test ile otomatik alınabilir:
```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_flow_test.dart -d <device>
```

Sonra kopyalama:
```powershell
.\tool\copy_screenshots.ps1
```

---

### Data Safety Declaration (Play Console)

Play Console'da Data Safety formunu doldur:

1. [ ] **Data Safety** bölümüne git
2. [ ] `docs/DATA_SAFETY_QUICK_REFERENCE.md` dosyasını referans al
3. [ ] Tüm soruları doldur:
   - [ ] Veri toplama: ✅ Yes
   - [ ] Çocuk verisi: ❌ No
   - [ ] Şifreleme: ✅ Yes
   - [ ] Veri silme: ✅ Yes
4. [ ] Her veri türü için detayları ekle:
   - [ ] Health & Fitness Data
   - [ ] Personal Information
   - [ ] Photos & Videos (opsiyonel)
   - [ ] App Activity (opsiyonel, opt-in)
   - [ ] Device IDs (opsiyonel)
5. [ ] Gizlilik politikası URL'sini ekle
6. [ ] Gönder ve onay bekle

**Referans:** `docs/DATA_SAFETY_DECLARATION.md` (detaylı)
**Hızlı Referans:** `docs/DATA_SAFETY_QUICK_REFERENCE.md`

---

### App Store Connect (iOS)

#### Content Rating
- [ ] Content Rating formunu doldur
- [ ] Medical/Treatment Information: ✅ Yes
- [ ] Unrestricted Web Access: ❌ No
- [ ] User Generated Content: ❌ No
- [ ] Gambling: ❌ No
- [ ] Age Rating: 17+ (Medical/Treatment Information nedeniyle)

#### App Information
- [ ] App Name: HemoAI
- [ ] Subtitle: AI-Powered Blood Analysis
- [ ] Category: Medical / Health & Fitness
- [ ] Privacy Policy URL: ✅ Eklendi
- [ ] Support URL: support@hemoai.org

#### Screenshots & Preview
- [ ] iPhone 6.7" screenshots (1290x2796)
- [ ] iPhone 6.1" screenshots (1179x2556)
- [ ] App Preview video (opsiyonel)

---

### Play Console (Android)

#### Store Listing
- [ ] App Name: HemoAI
- [ ] Short Description: AI-Powered Blood Analysis
- [ ] Full Description: ✅ Hazır
- [ ] Feature Graphic: ✅ 3 varyant hazır
- [ ] Screenshots: ⏳ Eklenecek
- [ ] App Icon: ✅ Hazır

#### Content Rating
- [ ] IARC rating formunu doldur
- [ ] Medical Information: ✅ Yes
- [ ] Age Rating: PEGI 16+ / ESRB Teen

#### Data Safety
- [ ] Data Safety formunu doldur (yukarıda detaylı)

#### Pricing & Distribution
- [ ] Free app
- [ ] Tüm ülkelerde dağıtım
- [ ] Yaş kısıtlaması: 18+

---

### Final Checks

#### Build Configuration
- [ ] Version code/name doğru
- [ ] Signing keys hazır
- [ ] ProGuard/R8 rules (Android)
- [ ] App icons tüm platformlarda doğru

#### Legal Documents
- [ ] Privacy Policy URL: ✅ Eklendi
- [ ] Terms of Service URL: ✅ Eklendi
- [ ] Medical Disclaimer: ✅ In-app screen

#### Testing
- [ ] Release build test edildi
- [ ] Tüm özellikler çalışıyor
- [ ] Crash-free rate kontrol edildi
- [ ] Performance metrics normal

---

## 📋 Yayınlama Adımları

### 1. Pre-Release
- [ ] Tüm screenshots hazır
- [ ] Data Safety formu dolduruldu
- [ ] Content Rating tamamlandı
- [ ] Store listing bilgileri tamamlandı
- [ ] Release build oluşturuldu

### 2. Internal Testing (Opsiyonel)
- [ ] Internal test track'e yükle
- [ ] Test kullanıcıları ekle
- [ ] Test feedback'i topla

### 3. Production Release
- [ ] Production track'e yükle
- [ ] Release notes yaz
- [ ] Staged rollout başlat (%10, %50, %100)
- [ ] İzleme ve monitoring aktif

---

## 📞 Destek

Sorular için:
- **E-posta:** support@hemoai.org
- **Dokümantasyon:** `docs/` klasörü

---

**Son Güncelleme:** Bugün
**Durum:** Screenshots ve Data Safety formu kaldı

