# 🚀 Hızlı Başlangıç: Production Yapılandırma

## ⚡ 5 Dakikada Production'a Geçin!

Ben kodları hazırladım, siz sadece şunları yapın:

---

## 1️⃣ SendGrid Hesabı Oluşturun (2 dakika)

### Adım 1: Hesap Oluştur
1. https://sendgrid.com adresine gidin
2. "Start for Free" butonuna tıklayın
3. Email'inizi doğrulayın
4. **Ücretsiz plan:** Ayda 100 email göndermek için yeterli!

### Adım 2: API Key Oluştur
1. SendGrid Dashboard'da sol menüden **Settings** > **API Keys** seçin
2. **"Create API Key"** butonuna tıklayın
3. Key adı: `HemoAI Production`
4. **"Full Access"** seçin (veya sadece "Mail Send" permission)
5. **"Create & View"** tıklayın
6. **API KEY'I KOPYALAYIN** (sadece bir kere gösterilir!)

### Adım 3: Sender Doğrula (Opsiyonel ama Önerilir)
1. **Settings** > **Sender Authentication** > **Single Sender Verification**
2. Kendi email'inizi ekleyin (örn: noreply@yourdomain.com)
3. Email'deki doğrulama linkine tıklayın

---

## 2️⃣ Supabase Projesi Oluşturun (3 dakika)

### Adım 1: Hesap Oluştur
1. https://supabase.com adresine gidin
2. "Start your project" butonuna tıklayın
3. GitHub hesabınızla giriş yapın
4. **Ücretsiz plan:** Yeterli! 500MB storage, 2GB bandwidth

### Adım 2: Proje Oluştur
1. **"New Project"** butonuna tıklayın
2. **Name:** `hemoai-production`
3. **Database Password:** Güçlü bir şifre (not alın!)
4. **Region:** İstanbul veya en yakın bölge
5. **"Create new project"** tıklayın (2-3 dakika sürer)

### Adım 3: API Keys'i Al
1. Proje açıldığında sol menüden **Settings** > **API** seçin
2. **Project URL** kopyalayın (örn: `https://xxxxx.supabase.co`)
3. **anon/public key** kopyalayın (uzun bir string)

### Adım 4: Storage Bucket Oluştur
1. Sol menüden **Storage** > **"New bucket"**
2. **Name:** `hemoai-backups`
3. **Public bucket:** KAPALI (özel backup'lar için)
4. **File size limit:** 50 MB
5. **"Create bucket"** tıklayın

---

## 3️⃣ API Keys'leri Uygulamaya Ekleyin

### Yöntem 1: Dart Define (Önerilen)

**Windows PowerShell:**
```powershell
flutter run --dart-define=SENDGRID_API_KEY=SG.xxxxx --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

**macOS/Linux:**
```bash
flutter run \
  --dart-define=SENDGRID_API_KEY=SG.xxxxx \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

### Yöntem 2: main.dart'da (Geçici Test)

`lib/main.dart` dosyasını açın ve şunu güncelleyin:

```dart
// Initialize email service
await EmailService().initialize(
  apiKey: 'SG.xxxxx.YOUR_SENDGRID_KEY', // SendGrid API key'iniz
  fromEmail: 'noreply@hemoai.com',
  testMode: false, // Production mode
);

// Initialize cloud sync (cloud_sync_config.dart'da zaten var)
```

---

## 4️⃣ Production Build Alın

### Android (Play Store için)
```bash
flutter build appbundle --release \
  --dart-define=SENDGRID_API_KEY=SG.xxxxx \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

### iOS (App Store için)
```bash
flutter build ios --release \
  --dart-define=SENDGRID_API_KEY=SG.xxxxx \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

### Web
```bash
flutter build web --release \
  --dart-define=SENDGRID_API_KEY=SG.xxxxx \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

---

## 5️⃣ Test Edin

### Email Testi
1. Uygulama açıldığında "Şifremi Unuttum" tıklayın
2. Email girin
3. Gerçek email gelmeli! ✅

### Cloud Backup Testi
1. Yeni hesap oluşturun
2. Test verileri ekleyin
3. Settings > Automatic Backup
4. "Backup Now" tıklayın
5. Supabase Storage'da dosya görünecek ✅

---

## 📝 Örnek Kopyala-Yapıştır

API keys'lerinizi bulduktan sonra bu komutu doldurun:

```bash
flutter run --release \
  --dart-define=SENDGRID_API_KEY=SG.BURAYA_KENDI_KEYINIZ \
  --dart-define=SUPABASE_URL=https://BURAYA_PROJECT_URL.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=BURAYA_ANON_KEY
```

---

## 🆘 Yardım

### SendGrid Limitleri
- **Free Plan:** 100 email/gün
- Daha fazla gerekiyorsa paid plan'lara bakın

### Supabase Limitleri
- **Free Plan:** 500MB storage, 2GB bandwidth
- Yeterli! Kullanıcı başına ortalama 50KB backup = 10,000 kullanıcı

### Sorun Giderme
1. API key yanlış → Console'da hata görünecek
2. Email gelmiyor → SendGrid Activity'de kontrol edin
3. Backup yok → Supabase Storage bucket'ı kontrol edin

---

## 🎉 Tamam!

Hepsi bu! Toplam **5 dakika** sürer.

**Detaylı rehber için:** `PRODUCTION_CONFIG_GUIDE.md` dosyasına bakın.

---

**Not:** API keys'leri **ASLA** Git'e commit etmeyin! `.env` dosyası kullanın veya `--dart-define` ile çalıştırın.

