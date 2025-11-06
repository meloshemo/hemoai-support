# Play Store & App Store Publication Requirements

## ✅ TAMAMLANANLAR

### 1. Teknik Gereksinimler
- ✅ **Android Package Name**: `com.meloshemo.hemoai` (unique)
- ✅ **Version Code**: 400 (pubspec.yaml)
- ✅ **Min SDK**: Android 26 (API Level 26)
- ✅ **Target SDK**: Latest Flutter SDK
- ✅ **iOS Bundle ID**: Configured in Xcode
- ✅ **Signing Config**: Android release signing configured
- ✅ **ProGuard**: Enabled for release builds
- ✅ **Permissions**: All required permissions declared in AndroidManifest.xml
- ✅ **Privacy Descriptions**: iOS Info.plist'te tüm privacy usage descriptions mevcut

### 2. Kod Kalitesi
- ✅ **Lint Errors**: Düzeltildi (duplicate keys)
- ✅ **Compilation**: Başarılı
- ✅ **Localization**: 9 dil desteği (tr, en, es, fr, de, ar, it, pt, ru)
- ✅ **Error Handling**: Snackbar feedback mevcut
- ✅ **State Management**: Provider + Riverpod

### 3. Özellikler
- ✅ **AI Analysis**: Hemogram analizi
- ✅ **Premium Features**: Abonelik sistemi
- ✅ **Payment Integration**: Stripe (international) + Iyzico (Turkey)
- ✅ **OCR**: Lab report scanning
- ✅ **Export**: PDF, Excel, FHIR
- ✅ **Family Panel**: Aile üyeleri takibi
- ✅ **Challenges**: Motivasyon ve rekabet özellikleri
- ✅ **Notifications**: Bildirim sistemi
- ✅ **Dark Mode**: Tema desteği

## ❌ EKSİKLİKLER - ÖNEM SIRASINA GÖRE

### 🔴 KRİTİK (Yayınlamadan Önce Zorunlu)

#### 1. Privacy Policy & Terms of Service
**Durum**: ❌ EKSİK
- Privacy Policy URL'i yok
- Terms of Service URL'i yok
- Settings ekranında linkler eksik
- Play Store ve App Store'da zorunlu

**Çözüm**:
1. Privacy Policy sayfası oluştur (web sitesi veya GitHub Pages)
2. Terms of Service sayfası oluştur
3. Settings ekranına linkler ekle
4. `lib/screens/settings_screen.dart` güncelle

#### 2. App Icons & Launch Screens
**Durum**: ⚠️ KONTROL EDİLMELİ
- Android: `@mipmap/ic_launcher` referansı var ama icon dosyaları kontrol edilmeli
- iOS: LaunchScreen storyboard var ama iconlar kontrol edilmeli
- Tüm gerekli boyutlarda iconlar olmalı:
  - Android: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
  - iOS: 1024x1024 App Store icon

**Kontrol**:
```bash
ls android/app/src/main/res/mipmap-*/
ls ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

#### 3. Data Safety Declaration (Play Store)
**Durum**: ⚠️ HAZIRLANMALI
- Play Store Console'da Data Safety bölümü doldurulmalı
- Toplanan veriler, kullanım amaçları, paylaşım durumu belirtilmeli
- `docs/DATA_SAFETY_DECLARATION.md` var ama console'a girilmeli

#### 4. Content Rating
**Durum**: ⚠️ TAMAMLANMALI
- Play Store: PEGI/ESRB rating
- App Store: Age rating (4+ önerilir)
- Medical disclaimer eklenmeli

#### 5. App Description & Screenshots
**Durum**: ⚠️ HAZIRLANMALI
- Play Store: En az 2 screenshot (telefon)
- App Store: En az 3 screenshot (iPhone)
- Tablet screenshots (opsiyonel ama önerilir)
- Feature graphic (Play Store)
- App preview video (opsiyonel)

**Not**: `docs/PLAY_STORE_LISTING_CONTENT.md` var ama screenshot'lar hazırlanmalı

#### 6. Support Contact Information
**Durum**: ⚠️ EKSİK
- Settings ekranında "Support & Contact" var ama email/URL yok
- Play Store ve App Store'da support email zorunlu
- Support URL eklenmeli

#### 7. Medical Disclaimer
**Durum**: ⚠️ EKSİK
- Settings > About HemoAI'da "Medical Disclaimer" tile var ama içerik eksik
- Uygulama tıbbi tavsiye vermez disclaimer'ı eklenmeli
- Tüm dillere çevrilmeli

### 🟡 ÖNEMLİ (Yayınlama Sonrası İyileştirme)

#### 8. Analytics & Crash Reporting
**Durum**: ⚠️ EKSİK
- Production için crash reporting eklenmeli (Firebase Crashlytics, Sentry)
- Analytics entegrasyonu (opsiyonel, privacy-first)
- Error tracking

#### 9. App Store Review Guidelines Compliance
**Durum**: ⚠️ KONTROL EDİLMELİ
- Subscription management: App Store'da subscription yönetimi ekranı
- Restore purchases: Mevcut ✅
- Auto-renewable subscriptions: Test edilmeli
- Trial period: Doğru yapılandırılmalı

#### 10. Play Store Review Guidelines Compliance
**Durum**: ⚠️ KONTROL EDİLMELİ
- In-app purchases: Test edilmeli
- Subscription management: Google Play Console'da yapılandırılmalı
- Billing library: Doğru entegre edilmeli

#### 11. Performance Optimization
**Durum**: ⚠️ TEST EDİLMELİ
- App size: Optimize edilmeli (şu an ~? MB)
- Startup time: <3 saniye hedef
- Memory usage: Profiling yapılmalı
- Battery usage: Optimize edilmeli

#### 12. Accessibility
**Durum**: ⚠️ İYİLEŞTİRİLMELİ
- Screen reader support: Semantics eklenmeli
- High contrast support: Tema desteği var ✅
- Font scaling: Test edilmeli
- Touch targets: Minimum 44x44 dp

#### 13. Security Audit
**Durum**: ⚠️ TAMAMLANMALI
- SSL pinning: HTTPS kullanımı
- Data encryption: Secure storage ✅
- API security: Backend endpoint'ler güvenli olmalı
- OWASP Mobile Top 10: Kontrol edilmeli

### 🟢 İYİLEŞTİRME ÖNERİLERİ

#### 14. Marketing Materials
- App Store Optimization (ASO): Keywords optimize edilmeli
- App description: SEO-friendly
- Promotional text: 170 karakter
- What's new: Her güncellemede

#### 15. Beta Testing
- Internal testing: Play Store ve TestFlight
- Closed beta: 100-1000 kullanıcı
- Feedback collection: In-app feedback formu

#### 16. Legal Documents
- GDPR compliance: Privacy policy GDPR uyumlu olmalı
- KVKK compliance: Türkiye için KVKK uyumlu
- HIPAA (opsiyonel): ABD'de sağlık verisi için

#### 17. Backend Infrastructure
- Payment webhook: Stripe/Iyzico webhook'ları hazır olmalı
- Email service: Production email service
- Database backup: Otomatik backup
- Monitoring: Server monitoring

## 📋 HEMEN YAPILMASI GEREKENLER (Öncelik Sırası)

### 1. Privacy Policy & Terms (1-2 gün)
```dart
// lib/screens/settings_screen.dart'a ekle:
_Tile(
  icon: Icons.privacy_tip,
  title: 'Privacy Policy',
  onTap: () => launchUrl(Uri.parse('https://yourwebsite.com/privacy')),
),
_Tile(
  icon: Icons.description,
  title: 'Terms of Service',
  onTap: () => launchUrl(Uri.parse('https://yourwebsite.com/terms')),
),
```

### 2. App Icons (1 gün)
- Tüm boyutlarda iconlar oluştur
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: Xcode'da AppIcon set'i doldur

### 3. Medical Disclaimer (1 gün)
```dart
// lib/screens/settings_screen.dart > About HemoAI
_Tile(
  icon: Icons.medical_services,
  title: 'Medical Disclaimer',
  subtitle: 'This app does not provide medical advice...',
  onTap: () => _showMedicalDisclaimer(),
),
```

### 4. Support Contact (1 gün)
- Support email: support@hemoai.com
- Support URL: https://yourwebsite.com/support
- Settings ekranına ekle

### 5. Screenshots & Graphics (2-3 gün)
- Telefon screenshots: En az 2 (farklı ekranlar)
- Tablet screenshots: 1-2 (opsiyonel)
- Feature graphic: 1024x500 (Play Store)

### 6. Data Safety Declaration (1 gün)
- Play Store Console'da doldur
- `docs/DATA_SAFETY_DECLARATION.md` referans al

### 7. Content Rating (1 gün)
- Play Store: PEGI 3+ veya 7+
- App Store: 4+ (sağlık uygulaması)

## 🎯 YAYINLAMA ÖNCESİ CHECKLIST

### Teknik
- [ ] Release build test edildi (Android & iOS)
- [ ] ProGuard rules test edildi
- [ ] Signing key güvenli saklanıyor
- [ ] Version code artırıldı
- [ ] Release notes hazır

### İçerik
- [ ] Privacy Policy URL çalışıyor
- [ ] Terms of Service URL çalışıyor
- [ ] Medical disclaimer ekli
- [ ] Support contact bilgisi ekli
- [ ] App icons tüm boyutlarda mevcut
- [ ] Screenshots hazır
- [ ] App description yazıldı
- [ ] Keywords belirlendi

### Legal
- [ ] Privacy Policy yasalara uygun
- [ ] Terms of Service yasalara uygun
- [ ] GDPR/KVKK uyumlu
- [ ] Medical disclaimer ekli

### Store Requirements
- [ ] Play Store: Data Safety dolduruldu
- [ ] Play Store: Content rating seçildi
- [ ] App Store: Age rating seçildi
- [ ] App Store: Privacy policy URL ekli
- [ ] Her iki store: Support email ekli

## 📞 DESTEK KAYNAKLARI

- Play Store: https://support.google.com/googleplay/android-developer
- App Store: https://developer.apple.com/support/
- Privacy Policy Generator: https://www.privacypolicygenerator.info/
- Terms of Service Generator: https://www.termsofservicegenerator.net/

## ⚠️ ÖNEMLİ NOTLAR

1. **İlk yayınlama**: Beta testing ile başla (Internal/Closed)
2. **Payment testing**: Test account'ları ile ödeme akışını test et
3. **Crash reporting**: Production'da mutlaka crash reporting olsun
4. **Backup**: Signing key'leri güvenli yerde sakla
5. **Updates**: İlk yayınlama sonrası hızlı güncelleme planı hazırla

