# HemoAI - Eksik Öğeler Listesi

**Tarih:** 4 Kasım 2025  
**Durum:** Play Store ve App Store için hazırlık aşaması

---

## 🔴 KRİTİK EKSİKLER (Yayın Öncesi Zorunlu)

### 1. **Privacy Policy Hosting** ⚠️
- [ ] Privacy Policy dosyası var (`docs/privacy-policy.html`) ✅
- [ ] **AMA HENÜZ HOST EDİLMEDİ** ❌
- [ ] Public URL gerekiyor (Play Store ve App Store zorunlu)
- **Seçenekler:**
  - GitHub Pages (ücretsiz)
  - Firebase Hosting (ücretsiz tier)
  - Kendi domain'iniz
- **Mevcut URL:** `https://www.privacypolicies.com/live/4cb84299-6103-4a25-b1d5-e290b3321772` (uygulamada var ama store için ayrı URL gerekebilir)

### 2. **Screenshots (Ekran Görüntüleri)** 📸
- [ ] **2-8 adet yüksek kaliteli screenshot gerekli**
- **Gereksinimler:**
  - Çözünürlük: 1080x1920px veya daha yüksek
  - Format: PNG veya JPEG
  - Aspect: 9:16 (telefon) veya 16:9
  - Üzerinde metin olmamalı (store ekler)
- **Çekilmesi Gereken Ekranlar:**
  1. Dashboard (sağlık özeti)
  2. AI Analiz Sonuçları
  3. Diyet Program Önerileri
  4. İlaç Hatırlatıcıları
  5. Aile Sağlık Paneli
  6. Alternatif Tıp
  7. Export Seçenekleri
  8. Ayarlar

### 3. **Feature Graphic (Banner)** 🎨
- [ ] **1024x500px banner görseli gerekli**
- **İçerik:**
  - App logo/marka
  - Tagline: "Smart Hemogram Analysis & Health Tracking"
  - Ana görsel öğeler
  - Profesyonel tasarım
- **Araçlar:** Figma, Canva, PowerPoint

### 4. **Production Build (AAB)** 📦
- [ ] **Release AAB dosyası oluşturulmalı**
- **Komut:**
  ```bash
  flutter build appbundle --release
  ```
- **Çıktı:** `build/app/outputs/bundle/release/app-release.aab`
- **Not:** Şu anda build klasöründe yok

---

## 🟡 ÖNEMLİ EKSİKLER (Yayın İçin Önerilen)

### 5. **Play Console Hesabı** 🚪
- [ ] Google Play Console hesabı oluşturulmalı
- [ ] Developer ücreti ($25 tek seferlik) ödenmeli
- [ ] Developer anlaşması kabul edilmeli

### 6. **App Store Connect Hesabı** 🍎
- [ ] Apple Developer Program üyeliği ($99/yıl)
- [ ] App Store Connect hesabı oluşturulmalı
- [ ] Bundle ID kaydedilmeli

### 7. **Store Listing İçerikleri** 📝
- [x] İçerik hazır (`docs/PLAY_STORE_LISTING_CONTENT.md`) ✅
- [ ] Play Console'a girilmeli:
  - App adı: "HemoAI"
  - Kısa açıklama: "Smart hemogram analysis & health tracking"
  - Tam açıklama (4000 karakter max)
  - Kategori: Health & Fitness
  - Etiketler: health tracker, blood test analyzer, hemogram

### 8. **Data Safety Declaration** 📊
- [x] Cevaplar hazır (`docs/DATA_SAFETY_DECLARATION.md`) ✅
- [ ] Play Console'da form doldurulmalı
- **Ana Noktalar:**
  - Health & Fitness data: ✅ Toplanıyor (sadece local)
  - Personal info: ✅ Toplanıyor (opsiyonel)
  - Photos: ⚠️ Toplanıyor (opsiyonel, OCR için)
  - Data shared: ❌ Hayır
  - Encryption: ✅ Evet
  - Deletion: ✅ Kullanıcı kontrolünde

### 9. **Content Rating** 🎬
- [x] Rehber hazır (`docs/CONTENT_RATING_GUIDE.md`) ✅
- [ ] Play Console'da anket doldurulmalı
- **Beklenen:** PEGI 3 / ESRB Everyone
- **Ana Noktalar:**
  - Şiddet, küfür, cinsel içerik: ❌ Yok
  - Eğitici tıbbi referanslar: ✅ Var
  - İlaç kullanımı: ⚠️ Sadece eğitici
  - Kullanıcı içeriği: ❌ Yok
  - Reklamlar: ⚠️ Gösterilebilir

### 10. **iOS App Store Listing** 🍎
- [ ] App Store Connect'te listing oluşturulmalı
- [ ] Screenshots (iPhone ve iPad için ayrı)
- [ ] App preview videos (opsiyonel ama önerilir)
- [ ] App Store açıklaması
- [ ] Keywords (anahtar kelimeler)
- [ ] Category: Medical / Health & Fitness

---

## 🟢 OPSİYONEL AMA ÖNERİLEN

### 11. **Test Build'leri** 🧪
- [ ] Internal testing (iç ekip)
- [ ] Closed testing (beta grubu)
- [ ] Open testing (geniş beta)

### 12. **Localization (Çoklu Dil)** 🌍
- [x] Uygulama içi dil desteği var ✅
- [ ] Store listing'ler farklı dillere çevrilmeli:
  - Türkçe
  - İspanyolca
  - Fransızca
  - Almanca
  - Arapça

### 13. **Promotional Materials** 📱
- [ ] App icon variations
- [ ] Promo videos (YouTube)
- [ ] "What's New" changelog
- [ ] Social media assets

### 14. **Analytics Setup** 📈
- [ ] Google Analytics for Firebase (opsiyonel)
- [ ] Crashlytics (opsiyonel)
- [ ] Play Console vitals monitoring

---

## ✅ TAMAMLANAN ÖĞELER

### Teknik Hazırlık
- ✅ Release signing configured (keystore + key.properties)
- ✅ Android minSdk: 26
- ✅ Version: 4.0.0+400
- ✅ App ID: com.meloshemo.hemoai
- ✅ ProGuard rules for ML Kit & TFLite
- ✅ Keystore secured in .gitignore
- ✅ App metadata updated

### İkonlar
- ✅ Android icons (tüm DPI boyutları)
- ✅ iOS icons (tüm gerekli boyutlar)
- ✅ Adaptive Icon (Android 8.0+)
- ✅ App Store icon (1024x1024)

### Dokümantasyon
- ✅ Privacy Policy HTML (`docs/privacy-policy.html`)
- ✅ Play Store listing content (`docs/PLAY_STORE_LISTING_CONTENT.md`)
- ✅ Data Safety answers (`docs/DATA_SAFETY_DECLARATION.md`)
- ✅ Content Rating guide (`docs/CONTENT_RATING_GUIDE.md`)
- ✅ Play Store checklist (`docs/PLAY_STORE_CHECKLIST.md`)

### Uygulama İçi
- ✅ Privacy Policy URL (AppConstants)
- ✅ Terms of Use URL (AppConstants)
- ✅ Tüm özellikler lokalize edildi
- ✅ Medical disclaimers

---

## 📋 ÖNCELİK SIRASI

### 1. Hemen Yapılmalı (Store Submission için)
1. **Production AAB build** oluştur
2. **Screenshots** çek (2-8 adet)
3. **Feature Graphic** tasarla (1024x500px)
4. **Privacy Policy** host et (public URL)

### 2. Play Console'da Doldurulmalı
1. Store listing içerikleri
2. Data Safety form
3. Content Rating anketi
4. Screenshots ve feature graphic yükle

### 3. App Store için
1. App Store Connect hesabı
2. iOS screenshots
3. App Store listing içerikleri

---

## 🚀 Hızlı Başlangıç Komutları

### Production Build
```bash
# Android AAB
flutter build appbundle --release

# iOS (Xcode gerekli)
flutter build ios --release
```

### Screenshots
```bash
# Android emulator'de
flutter run
# Sonra emulator'ün screenshot özelliğini kullan

# Fiziksel cihazda
# scripts/take_screenshots.ps1 kullan
```

---

## 📞 Yardım

Herhangi bir adımda yardıma ihtiyacınız olursa, dokümantasyon klasöründeki detaylı rehberlere bakabilirsiniz:
- `docs/PLAY_STORE_PUBLICATION_SUMMARY.md`
- `docs/PLAY_STORE_CHECKLIST.md`
- `docs/ANDROID_ICON_SETUP.md`

---

**Son Güncelleme:** 4 Kasım 2025  
**Durum:** Hazırlık aşaması - Kritik eksikler var


