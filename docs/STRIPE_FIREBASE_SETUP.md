# 🔥 Stripe + Firebase Functions - Detaylı Kurulum Rehberi

## 📋 Genel Bakış

Bu rehber, Stripe ödemeleri için Firebase Functions backend servisini kurmanız için adım adım talimatlar içerir.

**Süre:** 30-60 dakika  
**Gereksinimler:** 
- Stripe hesabı
- Firebase hesabı
- Node.js (Firebase CLI için)

---

## 🚀 ADIM 1: Firebase Projesi Oluşturma

### 1.1 Firebase Console'a Giriş

1. **Firebase Console'a gidin:** https://console.firebase.google.com
2. **"Add project"** tıklayın
3. **Proje bilgileri:**
   - Project name: `hemoai-payments` (veya istediğiniz isim)
   - Google Analytics: Etkinleştirin (opsiyonel)
4. **"Create project"** tıklayın

### 1.2 Firebase CLI Kurulumu

1. **Node.js yükleyin** (eğer yoksa): https://nodejs.org
2. **Firebase CLI'yi yükleyin:**
   ```bash
   npm install -g firebase-tools
   ```

3. **Firebase'e giriş yapın:**
   ```bash
   firebase login
   ```

---

## 🚀 ADIM 2: Firebase Functions Kurulumu

### 2.1 Projeyi Başlatma

1. **Proje klasörüne gidin:**
   ```bash
   cd C:\Users\omeli\Desktop\hemoai
   ```

2. **Firebase'i başlatın:**
   ```bash
   firebase init functions
   ```

3. **Soruları cevaplayın:**
   - Use an existing project? → **Evet**, projenizi seçin
   - Language: **JavaScript** (TypeScript değil)
   - ESLint: **Evet**
   - Install dependencies: **Evet**

### 2.2 Functions Klasörü Kontrolü

`functions/` klasörü oluşturulmuş olmalı:
- `functions/index.js` ✅ (zaten oluşturuldu)
- `functions/package.json` ✅ (zaten oluşturuldu)

### 2.3 Dependencies Yükleme

```bash
cd functions
npm install
```

**Yüklenecek paketler:**
- `firebase-admin`
- `firebase-functions`
- `stripe`

---

## 🚀 ADIM 3: Stripe Ürünleri Oluşturma

### 3.1 Stripe Dashboard'a Giriş

1. **Stripe Dashboard'a gidin:** https://dashboard.stripe.com
2. **Test mode** veya **Live mode** seçin
3. **Products** → **"+"** → **"Add product"** tıklayın

### 3.2 Ürün 1: Aylık Premium

**Product Information:**
- **Name:** `HemoAI Premium Monthly`
- **Description:** `Monthly subscription to HemoAI Premium features`

**Pricing:**
- **Pricing model:** `Recurring`
- **Billing period:** `Monthly`
- **Price:** $9.99 USD

**Product ID ve Price ID'yi not edin:**
- Product ID: `prod_xxxxx` (not edin)
- Price ID: `price_xxxxx` (not edin - bu önemli!)

### 3.3 Ürün 2: Yıllık Premium

**Product Information:**
- **Name:** `HemoAI Premium Yearly`
- **Description:** `Yearly subscription to HemoAI Premium features`

**Pricing:**
- **Pricing model:** `Recurring`
- **Billing period:** `Yearly`
- **Price:** $99.99 USD

**Price ID:** `price_xxxxx` (not edin)

### 3.4 Ürün 3: Yaşam Boyu Premium

**Product Information:**
- **Name:** `HemoAI Premium Lifetime`
- **Description:** `Lifetime access to HemoAI Premium features`

**Pricing:**
- **Pricing model:** `One-time`
- **Price:** $299.99 USD

**Price ID:** `price_xxxxx` (not edin)

### 3.5 API Keys

1. **Developers** → **API keys** bölümüne gidin
2. **Secret key:** `sk_live_...` veya `sk_test_...` (not edin)
3. **Publishable key:** `pk_live_...` veya `pk_test_...` (not edin)

---

## 🚀 ADIM 4: Firebase Functions Configuration

### 4.1 Stripe API Keys'i Ayarlama

```bash
firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY"
```

**Test mode için:**
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_TEST_SECRET_KEY"
```

### 4.2 Price ID'leri Ayarlama

```bash
firebase functions:config:set stripe.price_monthly="price_YOUR_MONTHLY_PRICE_ID"
firebase functions:config:set stripe.price_yearly="price_YOUR_YEARLY_PRICE_ID"
firebase functions:config:set stripe.price_lifetime="price_YOUR_LIFETIME_PRICE_ID"
```

### 4.3 Webhook Secret Ayarlama

1. **Stripe Dashboard** → **Developers** → **Webhooks**
2. **"Add endpoint"** tıklayın
3. **Endpoint URL:** (şimdilik boş bırakın, deploy sonrası ekleyeceğiz)
4. **Events:** Şunları seçin:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `payment_intent.succeeded`
5. **"Add endpoint"** tıklayın
6. **Signing secret:** `whsec_...` (not edin)

```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

### 4.4 App URLs Ayarlama

```bash
firebase functions:config:set app.success_url="https://hemoai.app/payment-success"
firebase functions:config:set app.cancel_url="https://hemoai.app/payment-cancel"
```

---

## 🚀 ADIM 5: Firestore Database Kurulumu

### 5.1 Firestore'u Etkinleştirme

1. **Firebase Console** → **Firestore Database**
2. **"Create database"** tıklayın
3. **Security rules:** Start in test mode (production'da değiştireceğiz)
4. **Location:** Seçin (en yakın bölge)

### 5.2 Security Rules

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /premium_subscriptions/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Only server-side writes via Functions
    }
  }
}
```

---

## 🚀 ADIM 6: Functions'ları Deploy Etme

### 6.1 Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 6.2 Deploy Edilen URL'leri Not Edin

Deploy sonrası şu URL'ler görünecek:

```
✔ functions[createStripeCheckoutSession(us-central1)] Successful create operation.
Function URL (createStripeCheckoutSession): https://us-central1-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession

✔ functions[stripeWebhook(us-central1)] Successful create operation.
Function URL (stripeWebhook): https://us-central1-YOUR_PROJECT.cloudfunctions.net/stripeWebhook

✔ functions[checkPremiumStatus(us-central1)] Successful create operation.
Function URL (checkPremiumStatus): https://us-central1-YOUR_PROJECT.cloudfunctions.net/checkPremiumStatus
```

**Bu URL'leri not edin!**

### 6.3 Stripe Webhook URL'ini Güncelleme

1. **Stripe Dashboard** → **Developers** → **Webhooks**
2. Daha önce oluşturduğunuz endpoint'i açın
3. **Endpoint URL** alanını güncelleyin:
   ```
   https://us-central1-YOUR_PROJECT.cloudfunctions.net/stripeWebhook
   ```
4. **"Save"** tıklayın

---

## 🚀 ADIM 7: Flutter App'e URL Ekleme

### 7.1 Build Komutu

```bash
flutter build web --release \
  --dart-define=BACKEND_API_URL=https://us-central1-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession
```

### 7.2 Veya Environment Variable

`.env` dosyası oluşturun (opsiyonel):
```
BACKEND_API_URL=https://us-central1-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession
```

---

## ✅ ADIM 8: Test Etme

### 8.1 Test Mode'da Test

1. **Stripe Dashboard'da test mode'a geçin**
2. **Test kartı kullanın:** `4242 4242 4242 4242`
3. **Web uygulamasında premium satın almayı deneyin**
4. **Stripe Checkout açılmalı**
5. **Test kartı ile ödeme yapın**
6. **Firestore'da premium status kontrol edin**

### 8.2 Webhook Test

1. **Stripe Dashboard** → **Developers** → **Webhooks**
2. **Endpoint'i açın**
3. **"Send test webhook"** tıklayın
4. **Event:** `checkout.session.completed` seçin
5. **"Send test webhook"** tıklayın
6. **Firebase Functions logs** kontrol edin:
   ```bash
   firebase functions:log
   ```

---

## 🐛 Sorun Giderme

### Functions deploy edilemiyor

```bash
# Node.js versiyonunu kontrol edin
node --version  # 18 veya üzeri olmalı

# Dependencies'i yeniden yükleyin
cd functions
rm -rf node_modules
npm install
```

### Webhook çalışmıyor

1. **Stripe webhook secret'ın doğru olduğundan emin olun**
2. **Firebase Functions logs kontrol edin:**
   ```bash
   firebase functions:log --only stripeWebhook
   ```
3. **Stripe Dashboard'da webhook event'lerini kontrol edin**

### Checkout session oluşturulamıyor

1. **Price ID'lerin doğru olduğundan emin olun**
2. **Stripe API key'in doğru olduğundan emin olun**
3. **Firebase Functions logs kontrol edin:**
   ```bash
   firebase functions:log --only createStripeCheckoutSession
   ```

---

## 📊 Monitoring

### Firebase Functions Logs

```bash
# Tüm logs
firebase functions:log

# Belirli function
firebase functions:log --only createStripeCheckoutSession

# Son 1 saat
firebase functions:log --since 1h
```

### Stripe Dashboard

- **Payments:** Tüm ödemeleri görüntüleyin
- **Webhooks:** Webhook event'lerini kontrol edin
- **Customers:** Müşteri bilgilerini görüntüleyin

### Firestore

- **premium_subscriptions collection:** Premium durumlarını kontrol edin

---

## 🔒 Production Checklist

- [ ] Stripe Live mode'a geçin
- [ ] Live API keys'i kullanın
- [ ] Firestore security rules'u production'a uygun hale getirin
- [ ] Webhook URL'ini production URL ile güncelleyin
- [ ] Error monitoring ekleyin (Sentry, vb.)
- [ ] Rate limiting ekleyin (opsiyonel)
- [ ] Backup stratejisi (Firestore'u düzenli yedekleyin)

---

## 📞 Destek

**Firebase:**
- https://firebase.google.com/support
- https://firebase.google.com/docs/functions

**Stripe:**
- https://support.stripe.com
- https://stripe.com/docs

---

**Son Güncelleme:** 2025-01-04  
**Versiyon:** 1.0

