# 💳 Ödeme Entegrasyonu - Türkiye Geliştiriciler İçin Detaylı Rehber

## 📋 Genel Bakış

Bu rehber, Türkiye'den Google Play ve App Store'a uygulama yayınlayan geliştiriciler için ödeme entegrasyonunu adım adım açıklar.

**Ödeme Yöntemleri:**
- **Android/iOS (Mobil):** Google Play In-App Purchase / Apple App Store In-App Purchase
- **Web:** Stripe Checkout (uluslararası kullanıcılar için)

**Türkiye Özel Durum:**
- Türkiye'den Google Play ve App Store'a kayıt olabilirsiniz
- Google Play ve App Store ödemeleri doğrudan sizin hesabınıza yapılır
- Banka hesabınızı bağlayarak ödemeleri alabilirsiniz

---

## 🚀 1. GOOGLE PLAY CONSOLE - In-App Purchase Kurulumu

### 1.1 Google Play Console Hesabı Oluşturma

1. **Google Play Console'a gidin:** https://play.google.com/console
2. **Google hesabı ile giriş yapın** (Türkiye'den yapabilirsiniz)
3. **Developer hesabı oluşturun:**
   - Tek seferlik $25 USD ödeme (kredi kartı ile)
   - Türkiye'den ödeme yapabilirsiniz
   - Developer Agreement'i kabul edin

### 1.2 Uygulama Oluşturma

1. **"All apps" → "Create app"** tıklayın
2. **Bilgileri doldurun:**
   - App name: `HemoAI`
   - Default language: `English (United States)`
   - App or game: `App`
   - Free or paid: `Free`
3. **App ID:** `com.meloshemo.hemoai` (zaten tanımlı)

### 1.3 In-App Purchase Ürünleri Oluşturma

#### Adım 1: Ürünleri Oluştur

1. **Monetize** → **Products** → **In-app products** bölümüne gidin
2. **"Create product"** tıklayın

#### Ürün 1: Aylık Premium
- **Product ID:** `hemoai_premium_monthly`
- **Name:** `HemoAI Premium Monthly`
- **Description:** `Monthly subscription to HemoAI Premium features`
- **Type:** `Subscription` (Auto-renewing subscription)
- **Billing period:** `1 month`
- **Price:** Her ülke için fiyat belirleyin:
  - Türkiye: ₺99.99
  - USA: $9.99
  - UK: £7.99
  - vs.

#### Ürün 2: Yıllık Premium
- **Product ID:** `hemoai_premium_yearly`
- **Name:** `HemoAI Premium Yearly`
- **Description:** `Yearly subscription to HemoAI Premium features`
- **Type:** `Subscription` (Auto-renewing subscription)
- **Billing period:** `1 year`
- **Price:** Her ülke için fiyat belirleyin:
  - Türkiye: ₺799.99
  - USA: $99.99
  - UK: £79.99
  - vs.

#### Ürün 3: Yaşam Boyu Premium
- **Product ID:** `hemoai_premium_lifetime`
- **Name:** `HemoAI Premium Lifetime`
- **Description:** `Lifetime access to HemoAI Premium features`
- **Type:** `Managed product` (One-time purchase)
- **Price:** Her ülke için fiyat belirleyin:
  - Türkiye: ₺2499.99
  - USA: $299.99
  - UK: £249.99
  - vs.

#### Adım 2: Fiyatlandırma

1. Her ürün için **"Pricing"** bölümüne gidin
2. **"Set prices in all countries"** seçin
3. Her ülke için fiyat belirleyin veya **"Use pricing template"** ile otomatik fiyatlandırma yapın
4. **"Save"** tıklayın

#### Adım 3: Test Hesapları

1. **Setup** → **License testing** bölümüne gidin
2. Test yapmak istediğiniz **Gmail adreslerini** ekleyin
3. Test hesapları ile satın alma yaparken gerçek ödeme alınmaz

### 1.4 Ödeme Bilgileri

1. **Setup** → **Payments profile** bölümüne gidin
2. **Banka hesabı bilgilerinizi** ekleyin:
   - Türkiye'den bağlanabilirsiniz
   - IBAN ile bağlanabilirsiniz
   - Ödemeler otomatik olarak hesabınıza aktarılır (aylık)

### 1.5 Yayınlama

1. Ürünleri **"Active"** duruma getirin
2. Uygulamayı yayınladığınızda ürünler otomatik olarak aktif olur

---

## 🍎 2. APP STORE CONNECT - In-App Purchase Kurulumu

### 2.1 Apple Developer Hesabı Oluşturma

1. **Apple Developer Program'a kaydolun:** https://developer.apple.com/programs/
2. **Yıllık ücret:** $99 USD (Türkiye'den ödeme yapabilirsiniz)
3. **Kayıt süreci:** 24-48 saat (Apple onayı gerekir)

### 2.2 App Store Connect'e Giriş

1. **App Store Connect'e gidin:** https://appstoreconnect.apple.com
2. **Apple Developer hesabınızla giriş yapın**

### 2.3 Uygulama Oluşturma

1. **"My Apps"** → **"+"** → **"New App"** tıklayın
2. **Bilgileri doldurun:**
   - Platform: `iOS`
   - Name: `HemoAI`
   - Primary Language: `English (U.S.)`
   - Bundle ID: `com.meloshemo.hemoai`
   - SKU: `hemoai-ios-001`

### 2.4 In-App Purchase Ürünleri Oluşturma

#### Adım 1: Ürünleri Oluştur

1. **Features** → **In-App Purchases** → **"+"** tıklayın

#### Ürün 1: Aylık Premium
- **Type:** `Auto-Renewable Subscription`
- **Reference Name:** `HemoAI Premium Monthly`
- **Product ID:** `hemoai_premium_monthly`
- **Subscription Group:** Yeni bir grup oluşturun (`HemoAI Premium`)
- **Subscription Duration:** `1 Month`
- **Price:** Her ülke için fiyat belirleyin (Apple otomatik fiyatlandırma önerir)

#### Ürün 2: Yıllık Premium
- **Type:** `Auto-Renewable Subscription`
- **Reference Name:** `HemoAI Premium Yearly`
- **Product ID:** `hemoai_premium_yearly`
- **Subscription Group:** Aynı grup (`HemoAI Premium`)
- **Subscription Duration:** `1 Year`
- **Price:** Her ülke için fiyat belirleyin

#### Ürün 3: Yaşam Boyu Premium
- **Type:** `Non-Consumable`
- **Reference Name:** `HemoAI Premium Lifetime`
- **Product ID:** `hemoai_premium_lifetime`
- **Price:** Her ülke için fiyat belirleyin

#### Adım 2: Localization (Yerelleştirme)

Her ürün için:
1. **Localization** bölümüne gidin
2. **Display Name:** `HemoAI Premium Monthly`
3. **Description:** `Monthly subscription to HemoAI Premium features`
4. Türkçe için de ekleyin (opsiyonel)

#### Adım 3: Review Information

1. **Review Information** bölümüne gidin
2. **Review Notes:** Apple review ekibine notlar (opsiyonel)
3. **Screenshot:** Premium özelliklerin screenshot'ları (opsiyonel)

### 2.5 Test Hesapları

1. **Users and Access** → **Sandbox Testers** bölümüne gidin
2. **"+"** tıklayın ve test hesapları ekleyin
3. Test hesapları ile satın alma yaparken gerçek ödeme alınmaz

### 2.6 Ödeme Bilgileri

1. **Agreements, Tax, and Banking** → **Banking** bölümüne gidin
2. **Banka hesabı bilgilerinizi** ekleyin:
   - Türkiye'den bağlanabilirsiniz
   - SWIFT kodu ile bağlanabilirsiniz
   - Ödemeler otomatik olarak hesabınıza aktarılır (aylık)

### 2.7 Yayınlama

1. Ürünleri **"Ready to Submit"** duruma getirin
2. Uygulamayı review için gönderdiğinizde ürünler de review edilir

---

## 🌐 3. STRIPE (Web Ödemeleri İçin)

### 3.1 Stripe Hesabı Oluşturma

1. **Stripe'a kaydolun:** https://stripe.com
2. **Türkiye'den kayıt olabilirsiniz** (ancak Stripe Türkiye'de aktif değil)
3. **Alternatif:** Uluslararası kullanıcılar için kullanın

### 3.2 Stripe Dashboard Kurulumu

1. **Products** → **"+"** → **"Add product"** tıklayın

#### Ürün 1: Aylık Premium
- **Name:** `HemoAI Premium Monthly`
- **Pricing:** `Recurring` → `Monthly`
- **Price:** $9.99 USD
- **Product ID:** Not edin (örn: `prod_xxxxx`)
- **Price ID:** Not edin (örn: `price_xxxxx`)

#### Ürün 2: Yıllık Premium
- **Name:** `HemoAI Premium Yearly`
- **Pricing:** `Recurring` → `Yearly`
- **Price:** $99.99 USD
- **Price ID:** Not edin

#### Ürün 3: Yaşam Boyu Premium
- **Name:** `HemoAI Premium Lifetime`
- **Pricing:** `One-time`
- **Price:** $299.99 USD
- **Price ID:** Not edin

### 3.3 Webhook Kurulumu

1. **Developers** → **Webhooks** → **"Add endpoint"** tıklayın
2. **Endpoint URL:** Firebase Functions webhook URL'inizi girin:
   ```
   https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook
   ```
3. **Events to send:** Şunları seçin:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `payment_intent.succeeded`
4. **Signing secret:** Not edin (webhook secret)

### 3.4 API Keys

1. **Developers** → **API keys** bölümüne gidin
2. **Secret key:** Not edin (sk_live_... veya sk_test_...)
3. **Publishable key:** Not edin (pk_live_... veya pk_test_...)

---

## 🔥 4. FIREBASE FUNCTIONS KURULUMU

### 4.1 Firebase Projesi Oluşturma

1. **Firebase Console'a gidin:** https://console.firebase.google.com
2. **"Add project"** tıklayın
3. **Project name:** `hemoai-payments` (veya istediğiniz isim)
4. **Google Analytics:** Etkinleştirin (opsiyonel)

### 4.2 Firebase Functions Kurulumu

1. **Firebase CLI'yi yükleyin:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase'e giriş yapın:**
   ```bash
   firebase login
   ```

3. **Projeyi başlatın:**
   ```bash
   cd functions
   npm install
   ```

4. **Firebase Functions'i başlatın:**
   ```bash
   cd ..
   firebase init functions
   ```
   - TypeScript yerine **JavaScript** seçin
   - ESLint: Evet
   - Functions directory: `functions`

### 4.3 Configuration

1. **Stripe API keys'leri ayarlayın:**
   ```bash
   firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY"
   firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
   firebase functions:config:set stripe.price_monthly="price_YOUR_MONTHLY_PRICE_ID"
   firebase functions:config:set stripe.price_yearly="price_YOUR_YEARLY_PRICE_ID"
   firebase functions:config:set stripe.price_lifetime="price_YOUR_LIFETIME_PRICE_ID"
   ```

2. **App URLs'leri ayarlayın:**
   ```bash
   firebase functions:config:set app.success_url="https://hemoai.app/payment-success"
   firebase functions:config:set app.cancel_url="https://hemoai.app/payment-cancel"
   ```

### 4.4 Deploy

1. **Functions'ları deploy edin:**
   ```bash
   firebase deploy --only functions
   ```

2. **Deploy edilen URL'leri not edin:**
   - `createStripeCheckoutSession`: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession`
   - `stripeWebhook`: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook`
   - `checkPremiumStatus`: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/checkPremiumStatus`

### 4.5 Flutter App'e URL Ekleme

**Build komutu:**
```bash
flutter build web --release \
  --dart-define=BACKEND_API_URL=https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession
```

---

## ✅ 5. TEST ETME

### 5.1 Google Play Test

1. **Test hesabı ile giriş yapın** (License Testing'de eklediğiniz)
2. Uygulamayı açın
3. Premium satın almayı deneyin
4. Gerçek ödeme alınmaz (test mode)

### 5.2 App Store Test

1. **TestFlight ile test edin:**
   - App Store Connect → TestFlight
   - Internal testing grubu oluşturun
   - Uygulamayı yükleyin
   - Sandbox test hesabı ile test edin

### 5.3 Stripe Test

1. **Stripe test mode'u kullanın:**
   - Dashboard'da test mode'a geçin
   - Test kartı kullanın: `4242 4242 4242 4242`
   - Test webhook'ları Stripe CLI ile test edin

---

## 📊 6. ÖDEME ALMA SÜRECİ

### Google Play
1. Kullanıcı ödeme yapar
2. Google Play ödemeyi alır
3. **%30 komisyon** kesilir (Google'ın payı)
4. Kalan **%70** sizin hesabınıza aktarılır
5. Aylık ödeme yapılır (minimum $100 USD)

### App Store
1. Kullanıcı ödeme yapar
2. Apple ödemeyi alır
3. **%30 komisyon** kesilir (Apple'ın payı)
4. Kalan **%70** sizin hesabınıza aktarılır
5. Aylık ödeme yapılır (minimum $10 USD)

### Stripe
1. Kullanıcı ödeme yapar
2. Stripe ödemeyi alır
3. **%2.9 + $0.30** komisyon kesilir (her işlem için)
4. Kalan tutar sizin Stripe hesabınıza aktarılır
5. Manuel veya otomatik transfer yapabilirsiniz

---

## 🎯 7. SONUÇ

Artık ödeme entegrasyonunuz hazır! Kullanıcılar:
- Android'de Google Play üzerinden ödeme yapabilir
- iOS'ta App Store üzerinden ödeme yapabilir
- Web'de Stripe üzerinden ödeme yapabilir

Ödemeler otomatik olarak hesabınıza aktarılır.

---

## 📞 DESTEK

**Sorularınız için:**
- Google Play: https://support.google.com/googleplay/android-developer
- App Store: https://developer.apple.com/support/
- Stripe: https://support.stripe.com
- Firebase: https://firebase.google.com/support

---

**Son Güncelleme:** 2025-01-04  
**Versiyon:** 1.0  
**Durum:** ✅ Production Ready

