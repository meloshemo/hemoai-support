# Production Configuration Guide

## Overview

Bu dosya HemoAI uygulamasının production ortamında çalışması için gerekli tüm yapılandırma adımlarını içerir.

---

## 1. SendGrid Email Servisi Yapılandırması

### Adım 1: SendGrid Hesabı Oluşturun

1. [SendGrid](https://sendgrid.com) sitesine gidin
2. Ücretsiz hesap oluşturun (ayda 100 email gönderebilirsiniz)
3. Email doğrulamasını tamamlayın

### Adım 2: API Key Oluşturun

1. SendGrid Dashboard > **Settings** > **API Keys**
2. **Create API Key** butonuna tıklayın
3. Key adı: `HemoAI Production`
4. Key permissions: **Full Access** veya **Restricted Access** > **Mail Send**
5. **Create & View** butonuna tıklayın
6. **API Key'i kopyalayın** (sadece bir kere gösterilir!)

### Adım 3: Uygulamaya API Key Ekleyin

**Seçenek 1: Environment Variables (Önerilen)**

`.env` dosyası oluşturun (proje root'unda):
```env
SENDGRID_API_KEY=SG.xxxxx.your-api-key-here
```

**Seçenek 2: main.dart'da Doğrudan (Geçici)**

```dart
// lib/main.dart
import '../services/email_service.dart';

void main() async {
  // ...
  
  // Initialize email service (test mode by default)
  EmailService().initialize(
    apiKey: 'SG.xxxxx.your-api-key-here', // SendGrid API key
    fromEmail: 'noreply@hemoai.com', // Verified sender email
    fromName: 'HemoAI',
    testMode: false, // Production mode
  );
  
  // ...
}
```

### Adım 4: Sender Email Doğrulayın

1. SendGrid Dashboard > **Settings** > **Sender Authentication**
2. **Single Sender Verification** seçin
3. Email adresinizi doğrulayın
4. Gönderen email adresi: `noreply@hemoai.com`

---

## 2. Supabase Cloud Sync Yapılandırması

### Adım 1: Supabase Hesabı Oluşturun

1. [Supabase](https://supabase.com) sitesine gidin
2. Ücretsiz hesap oluşturun
3. Yeni proje oluşturun:
   - Project name: `hemoai-production`
   - Database password: Güçlü bir şifre seçin
   - Region: En yakın bölge

### Adım 2: Storage Bucket Oluşturun

1. Supabase Dashboard > **Storage**
2. **New bucket** butonuna tıklayın
3. Bucket name: `hemoai-backups`
4. Public bucket: **NO** (özel backup'lar için)
5. File size limit: 50 MB (veya daha fazla)
6. **Create bucket** butonuna tıklayın

### Adım 3: Storage Policy Oluşturun

1. Bucket > **Policies** tab
2. **New policy** butonuna tıklayın
3. Policy name: `Authenticated users can backup`
4. Policy definition:
```sql
-- Allow authenticated users to upload backups
CREATE POLICY "Authenticated users can upload backups"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'hemoai-backups');

-- Allow authenticated users to read their backups
CREATE POLICY "Authenticated users can read backups"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'hemoai-backups');

-- Allow authenticated users to update their backups
CREATE POLICY "Authenticated users can update backups"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'hemoai-backups');
```

### Adım 4: API Keys'i Alın

1. Supabase Dashboard > **Settings** > **API**
2. Şu bilgileri kopyalayın:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGc...`

### Adım 5: Backup Metadata Table Oluşturun

1. Supabase Dashboard > **SQL Editor**
2. Yeni sorgu oluşturun:

```sql
-- Create backups metadata table
CREATE TABLE IF NOT EXISTS backups_meta (
    user_id TEXT PRIMARY KEY,
    ts TIMESTAMPTZ NOT NULL,
    platform TEXT NOT NULL,
    size INTEGER NOT NULL,
    schema INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_backups_meta_ts ON backups_meta(ts);

-- Enable Row Level Security
ALTER TABLE backups_meta ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own backups
CREATE POLICY "Users see own backups"
ON backups_meta
FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- Policy: Users can insert their own backups
CREATE POLICY "Users insert own backups"
ON backups_meta
FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = user_id);

-- Policy: Users can update their own backups
CREATE POLICY "Users update own backups"
ON backups_meta
FOR UPDATE
TO authenticated
USING (auth.uid()::text = user_id);
```

3. **Run** butonuna tıklayın

### Adım 6: Uygulamaya API Keys Ekleyin

**Seçenek 1: Dart Defines (Önerilen)**

```bash
# Development
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGc...

# Release build
flutter build apk --release --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

**Seçenek 2: cloud_sync_config.dart Güncelle**

```dart
// lib/services/cloud_sync_config.dart
class CloudSyncConfig {
  // For production, uncomment and fill in:
  static const supabaseUrl = 'https://xxxxx.supabase.co';
  static const supabaseAnonKey = 'eyJhbGc...';
  static const storageBucket = 'hemoai-backups';

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
```

**⚠️ UYARI:** API keys'i Git'e commit etmeyin! `.gitignore`'a ekleyin.

---

## 3. Güvenlik Yapılandırması

### Password Storage

Uygulama şu an Secure Storage kullanıyor:
- ✅ Android: KeyStore
- ✅ iOS: Keychain
- ✅ Web: LocalStorage (encrypted)
- ✅ Fallback: SharedPreferences (şifrelenmiş)

### Ek Güvenlik Önerileri

1. **App Signing Key**: Keystore'u güvenli bir yerde saklayın
2. **API Keys**: `.env` dosyasını Git'e eklemeyin
3. **SSL Pinning**: Production'da sertifika pinning ekleyin
4. **Rate Limiting**: API'lerde rate limit ekleyin

---

## 4. Environment Variables Kullanımı

### .env Dosyası Oluştur

Proje root'unda `.env` dosyası oluşturun:

```env
# SendGrid
SENDGRID_API_KEY=SG.xxxxx.your-api-key-here

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_BACKUP_BUCKET=hemoai-backups

# Environment
ENVIRONMENT=production
```

### .env Dosyasını Kullan

`.env` dosyasını kullanmak için `flutter_dotenv` paketini ekleyin:

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
// lib/main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Use environment variables
  EmailService().initialize(
    apiKey: dotenv.env['SENDGRID_API_KEY'] ?? '',
    testMode: dotenv.env['ENVIRONMENT'] != 'production',
  );
}
```

---

## 5. Production Build

### Android Release Build

```bash
# Build signed APK
flutter build apk --release --dart-define=ENVIRONMENT=production

# Build signed AAB (Play Store için)
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

### iOS Release Build

```bash
# Build for App Store
flutter build ios --release --dart-define=ENVIRONMENT=production

# Xcode'da Archive ve App Store'a yükleyin
```

### Web Release Build

```bash
# Build for production
flutter build web --release --dart-define=ENVIRONMENT=production

# Deploy to hosting (Vercel, Netlify, Firebase Hosting, vb.)
```

---

## 6. Monitoring & Logging

### Crash Reporting

**Firebase Crashlytics** (Önerilen):
1. Firebase Console > Crashlytics
2. Setup instructions'ı takip edin
3. `firebase_crashlytics` paketini ekleyin

### Analytics

**Firebase Analytics**:
```dart
// lib/main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

FirebaseAnalytics analytics = FirebaseAnalytics();
```

---

## 7. Testing Production Setup

### Email Testi

```dart
// Test email gönderimi
final emailService = EmailService();
await emailService.initialize(
  apiKey: 'YOUR_API_KEY',
  testMode: false,
);

final success = await emailService.sendPasswordResetEmail(
  toEmail: 'test@example.com',
  resetToken: 'test-token-123',
  locale: 'en',
);

print('Email sent: $success');
```

### Cloud Sync Testi

```dart
// Test cloud backup
final cloudSync = CloudSyncService();
await cloudSync.signInAnonymously();

final success = await cloudSync.backupNow('test-password');
print('Backup success: $success');

// Test cloud restore
final restored = await cloudSync.restoreLatest('test-password');
print('Restore success: $restored');
```

---

## 8. Troubleshooting

### Email Gönderilemiyor

- ✅ SendGrid API key doğru mu?
- ✅ Sender email doğrulanmış mı?
- ✅ Domain authentication yapıldı mı?
- ✅ Rate limit doldu mu?
- ✅ API key permissions doğru mu?

### Cloud Sync Çalışmıyor

- ✅ Supabase URL ve key doğru mu?
- ✅ Storage bucket oluşturuldu mu?
- ✅ Storage policies doğru mu?
- ✅ Backup metadata table var mı?
- ✅ Network bağlantısı var mı?

### Password Restore Çalışmıyor

- ✅ Secure Storage çalışıyor mu?
- ✅ Password doğru şekilde kaydedildi mi?
- ✅ Token expiry süresi doldu mu?
- ✅ Email servisi çalışıyor mu?

---

## 9. Checklist

Production'a geçmeden önce:

- [ ] SendGrid API key eklendi
- [ ] Sender email doğrulandı
- [ ] Supabase proje oluşturuldu
- [ ] Storage bucket oluşturuldu
- [ ] Storage policies ayarlandı
- [ ] Backup metadata table oluşturuldu
- [ ] API keys environment variables'a eklendi
- [ ] `.env` dosyası `.gitignore`'da
- [ ] Secure Storage test edildi
- [ ] Email gönderimi test edildi
- [ ] Cloud backup test edildi
- [ ] Cloud restore test edildi
- [ ] Crash reporting kuruldu
- [ ] Analytics kuruldu
- [ ] Production build test edildi

---

## 10. Support & Resources

- SendGrid Docs: https://docs.sendgrid.com
- Supabase Docs: https://supabase.com/docs
- Firebase Docs: https://firebase.google.com/docs
- Flutter Secure Storage: https://pub.dev/packages/flutter_secure_storage

---

**Son Güncelleme:** 2025-01-XX

