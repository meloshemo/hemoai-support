# 🚀 Production Hazırlık Gereksinimleri

## ⚠️ Mevcut Durum: DEMO/TEST MODU

Bu uygulama şu an **sadece demo/test** amaçlı kullanılabilir. Play Store'a yüklemeden önce aşağıdaki kritik gereksinimler tamamlanmalıdır.

---

## ❌ Eksik Özellikler

### 1. Cloud Senkronizasyon - KRİTİK
**Sorun:** Tüm veriler sadece cihazda tutuluyor
**Sonuç:** Uygulama silinince veya cihaz değişince veriler kaybolur

**Çözüm:**
```bash
# 1. Supabase hesabı oluşturun
https://supabase.com

# 2. Proje oluşturun
Project name: hemoai
Region: Europe (Türkiye için en yakın)

# 3. API Keys alın
Dashboard > Settings > API

# 4. Veritabanı tablolarını oluşturun
Dashboard > SQL Editor > New Query

# 5. Storage bucket oluşturun
Dashboard > Storage > Create Bucket
Bucket name: hemoai-backups
Public: false

# 6. Build komutunu güncelleyin
flutter build appbundle --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx
```

### 2. Şifre Sıfırlama - KRİTİK
**Sorun:** "Şifremi Unuttum" butonu çalışmıyor
**Sonuç:** Kullanıcılar şifresini unutursa hesaba erişemez

**Çözüm Seçenekleri:**

**A) Email Servisi (Önerilen):**
```dart
// SendGrid, Mailgun, AWS SES kullanın
await EmailService.sendPasswordReset(
  to: email,
  resetLink: 'hemoai://reset?token=$token'
);
```

**B) SMS Servisi:**
```dart
// Twilio, AWS SNS kullanın
await SMSService.sendPasswordResetCode(
  phone: phone,
  code: '123456'
);
```

**C) Güvenlik Soruları (Basit):**
```dart
// Kullanıcı kayıt olurken sorular sor
"What was your first pet's name?"
"What city were you born in?"

// Şifre sıfırlarken doğrula
if (answersCorrect) {
  allowPasswordReset();
}
```

### 3. Otomatik Yedekleme - KRİTİK
**Sorun:** Kullanıcı manuel yedek almalı
**Sonuç:** Çoğu kullanıcı unutur, veri kaybı riski

**Çözüm:**
```dart
// Her giriş sonrası
await CloudSyncService().syncTables(userId);

// Her 24 saatte bir otomatik
await CloudSyncService().backupNow(password);

// Uygulama kapanırken
await CloudSyncService().syncNow();
```

### 4. Veri Bütünlüğü Kontrolü - ÖNEMLİ
**Sorun:** Veri kaybı tespit edilemiyor
**Sonuç:** Kullanıcı farkına varmayabilir

**Çözüm:**
```dart
// Onboarding'de uyarı
"Verileriniz güvende tutuluyor mu kontrol edin!"

// Profilde sync durumu
"Son senkronizasyon: 2 dakika önce ✓"
"Senkronizasyon hatası! Manuel yedek alın."

// Dashboard'da uyarı
if (lastSync > 7 days) {
  showWarning("24 saatten fazladır senkronizasyon yapılmadı!");
}
```

---

## 🔧 Hızlı Çözümler

### Geçici Çözüm 1: Manuel Yedekleme Uyarısı
```dart
// lib/screens/onboarding/welcome_screen.dart sonuna ekle:
void _showBackupWarning() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('⚠️ Önemli Uyarı'),
      content: Text(
        'Verileriniz şu an sadece bu cihazda saklanıyor.\n\n'
        'Her hafta yedek almanızı öneriyoruz!\n\n'
        'Ayarlar > Yedekleme > Yedek Al'
      ),
      actions: [
        TextButton(
          child: Text('Anladım'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

### Geçici Çözüm 2: Basit Şifre Sıfırlama
```dart
// lib/core/services/auth_service.dart'da güncelle:
Future<bool> resetPassword(String email) async {
  // Gerçek email gönderemediğimiz için manuel yardım
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Şifre Sıfırlama'),
      content: Text(
        'Şifre sıfırlama özelliği şu an geliştiriliyor.\n\n'
        'Lütfen destek ekibimizle iletişime geçin:\n'
        'destek@hemoai.com'
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Tamam'))],
    ),
  );
  return false;
}
```

### Geçici Çözüm 3: Test Modu Uyarısı
```dart
// lib/main.dart'da splash screen'de:
void _showTestModeWarning() {
  if (isProduction) return; // Production'da gösterilmez
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('🧪 TEST MODU'),
      content: Text(
        'Bu uygulama test modunda çalışıyor.\n\n'
        'Veriler kaybolabilir!\n\n'
        'Production sürümü yakında...'
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Devam Et'),
        ),
      ],
    ),
  );
}
```

---

## 📋 Production Checklist

### Backend Altyapısı
- [ ] Supabase projesi oluşturuldu
- [ ] Veritabanı tabloları oluşturuldu
- [ ] Storage bucket oluşturuldu
- [ ] API keys yapılandırıldı
- [ ] Row Level Security (RLS) politikaları ayarlandı

### E-posta/SMS Servisi
- [ ] Email servisi (SendGrid/Mailgun) entegre edildi
- [ ] SMS servisi (Twilio) entegre edildi veya
- [ ] Güvenlik soruları sistemi kuruldu
- [ ] Şifre sıfırlama test edildi

### Cloud Sync
- [ ] Login sonrası otomatik sync
- [ ] 24 saatte bir otomatik backup
- [ ] Uygulama kapanırken son sync
- [ ] Çakışma çözümleme stratejisi (LWW)
- [ ] Offline-first çalışma

### Güvenlik
- [ ] Şifreler Argon2id ile hash'leniyor
- [ ] Hassas veriler şifreleniyor
- [ ] SQL injection koruması
- [ ] Rate limiting
- [ ] Audit logging

### Kullanıcı Deneyimi
- [ ] Onboarding'de yedekleme uyarısı
- [ ] Profilde sync durumu
- [ ] Hata durumlarında bilgilendirme
- [ ] Şifre sıfırlama akışı
- [ ] Yardım/Destek kanalı

### Test
- [ ] Cihazlar arası senkronizasyon testi
- [ ] Uygulama silip yeniden yükleme testi
- [ ] Şifre sıfırlama testi
- [ ] Offline senaryo testleri
- [ ] Çakışma senaryosu testleri

### Play Store Hazırlığı
- [ ] Privacy Policy güncellendi (cloud storage açıklaması)
- [ ] Data Safety form güncellendi
- [ ] Beta test programı başlatıldı
- [ ] Kullanıcı geri bildirimleri toplandı

---

## 🎯 Minimum Viable Product (MVP)

Play Store'a ilk sürüm için **en az** şu gereklidir:

### Zorunlu (MUST HAVE):
1. ✅ Manuel yedekleme sistemi (MEVCUT)
2. ❌ Şifre sıfırlama (destek e-postası ile)
3. ❌ Production uyarısı dialog'u
4. ❌ Privacy policy güncellemesi

### İstenen (SHOULD HAVE):
1. ❌ Otomatik yedekleme (ayarlarda toggle)
2. ❌ Sync durumu göstergesi
3. ❌ Hatırlatıcılar

### İleride Eklenebilir (NICE TO HAVE):
1. Otomatik cloud sync
2. Gerçek zamanlı senkronizasyon
3. Cihazlar arası anında senkronizasyon

---

## 📞 Hemen Yapılması Gerekenler

### Bugün:
1. ❌ Production uyarısı ekleyin
2. ❌ Şifre sıfırlama için destek e-postası formu
3. ❌ Manuel yedekleme onboarding'de uyarı

### Bu Hafta:
1. ❌ Supabase kurulumu
2. ❌ Otomatik yedekleme ayarı
3. ❌ Email servisi entegrasyonu

### Bu Ay:
1. ❌ Beta test programı
2. ❌ Production rollout
3. ❌ Kullanıcı geri bildirimi

---

**ÖNEMLİ:** Bu uygulamayı Play Store'a yüklemeden önce kullanıcıların veri kaybetmeyeceğinden emin olun!

**Current Status:** ❌ Production için HAZIR DEĞİL
**Test Duration:** 2-4 hafta önerilir
**Launch Date:** Beta test sonrası karar verilebilir

---

## 📚 Kaynaklar

- [Supabase Kurulum](https://supabase.com/docs/guides/getting-started)
- [SendGrid Email](https://sendgrid.com/docs/for-developers/sending-email/flutter/)
- [Twilio SMS](https://www.twilio.com/docs/sms/quickstart/flutter)
- [Flutter Cloud Sync Patterns](https://docs.flutter.dev/data-and-backend/state-mgmt/options)

