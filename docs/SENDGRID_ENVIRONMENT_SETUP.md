# 📧 SendGrid Production Anahtarı & Ortam Değişkenleri

HemoAI uygulamasında e-posta gönderimleri `EmailService` üzerinden SendGrid API
ile yapılır. Aşağıdaki adımlar, test modundan production moduna geçiş için
gereken tüm konfigürasyonları kapsar.

---

## 1. SendGrid hesabı ve API anahtarı

1. [https://sendgrid.com](https://sendgrid.com) adresinden hesabını oluştur.
2. Dashboard → **Settings → API Keys → Create API Key**.
   - Name: `HemoAI Production`
   - Permissions: **Full Access** (veya minimum gerekli izinler)
   - Anahtarı bir password manager’da sakla (sonradan tekrar görüntülenmez).
3. **Sender Identity**
   - İlk etapta *Single Sender* (kişisel e-posta) yeterlidir.
   - Production ortamı için Domain Authentication yap (örn. `hemoai.com`).

---

## 2. Ortam değişkenleri

Flutter tarafında anahtarları `--dart-define` ile geçiriyoruz.

### 2.1 Yerel geliştirme

`.env.example` dosyasına örnek değerler eklendi (dosyayı oluşturup commit et):

```env
SENDGRID_API_KEY=SG.xxxxxx
SENDGRID_FROM_EMAIL=support@hemoai.org
SENDGRID_FROM_NAME=HemoAI Support
```

Yerelde çalışırken:

```bash
flutter run --dart-define=SENDGRID_API_KEY=SG.xxxxxx \
            --dart-define=SENDGRID_FROM_EMAIL=support@hemoai.org \
            --dart-define=SENDGRID_FROM_NAME="HemoAI Support"
```

### 2.2 CI/CD (GitHub Actions örneği)

```yaml
env:
  SENDGRID_API_KEY: ${{ secrets.SENDGRID_API_KEY }}
  SENDGRID_FROM_EMAIL: support@hemoai.org
  SENDGRID_FROM_NAME: "HemoAI Support"

run: |
  flutter build appbundle --release \
    --dart-define=SENDGRID_API_KEY=$SENDGRID_API_KEY \
    --dart-define=SENDGRID_FROM_EMAIL=$SENDGRID_FROM_EMAIL \
    --dart-define=SENDGRID_FROM_NAME="$SENDGRID_FROM_NAME"
```

---

## 3. Flutter kodunda konfigürasyon

`lib/services/email_service.dart` içinde şu satırlar bulunur:

```dart
const String.fromEnvironment('SENDGRID_API_KEY', defaultValue: '');
const String.fromEnvironment('SENDGRID_FROM_EMAIL', defaultValue: '');
const String.fromEnvironment('SENDGRID_FROM_NAME', defaultValue: '');
```

- `SENDGRID_API_KEY` boşsa servis otomatik olarak **test moduna** düşer ve gerçek
  API çağrısı yapılmaz.
- Production’da `initialize()` çağrısı anahtarların yüklendiğini log’lar.

---

## 4. Test ve doğrulama

1. `flutter run --dart-define=...` komutu ile app’i başlat.
2. Destek e-postası gönderme/şifre sıfırlama gibi akışları tetikle.
3. SendGrid Dashboard → **Activity** üzerinde logları kontrol et.
4. Spam/Bounce listelerini temiz tut.

---

## 5. Güvenlik notları

- API anahtarını **sakın** repoya commit etme.
- CI/CD’de secret olarak sakla.
- Anahtar sızarsa SendGrid dashboard’dan revoke et ve yenisini oluştur.
- Privacy Policy’de (https://meloshemo.github.io) e-posta sağlayıcısı bilgisi güncel.

Bu adımları tamamladıktan sonra uygulama production e-posta gönderimine hazır
hale gelir.

