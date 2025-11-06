# 📱 Google Play In-App Purchase - Adım Adım Kurulum

## 🎯 Genel Bakış

Bu rehber, Google Play Console'da in-app purchase ürünlerini oluşturmanız için detaylı adımları içerir.

**Süre:** 30-60 dakika  
**Gereksinimler:** Google Play Developer hesabı ($25 USD)

---

## 📋 ADIM 1: Google Play Console'a Giriş

1. **Google Play Console'a gidin:** https://play.google.com/console
2. Google hesabınızla giriş yapın
3. Eğer developer hesabınız yoksa:
   - **"Get started"** tıklayın
   - $25 USD ödeme yapın (kredi kartı ile)
   - Developer Agreement'i kabul edin

---

## 📋 ADIM 2: Uygulama Oluşturma

1. **"All apps"** menüsüne gidin
2. **"Create app"** butonuna tıklayın
3. **Bilgileri doldurun:**
   ```
   App name: HemoAI
   Default language: English (United States)
   App or game: App
   Free or paid: Free
   ```
4. **"Create"** tıklayın

---

## 📋 ADIM 3: In-App Purchase Ürünleri Oluşturma

### 3.1 Monetize Sekmesine Gitme

1. Sol menüden **"Monetize"** → **"Products"** → **"In-app products"** seçin
2. **"Create product"** butonuna tıklayın

### 3.2 Ürün 1: Aylık Premium

**Product ID:** `hemoai_premium_monthly`

**Basit bilgiler:**
- **Name:** `HemoAI Premium Monthly`
- **Description:** 
  ```
  Monthly subscription to HemoAI Premium features including:
  - Advanced AI analysis
  - Personalized diet recommendations
  - Unlimited test tracking
  - Family panel features
  - Priority support
  ```

**Subscription details:**
- **Type:** `Subscription` (Auto-renewing subscription)
- **Billing period:** `1 month`
- **Free trial:** `None` (veya istediğiniz süre)
- **Grace period:** `3 days` (önerilen)

**Pricing:**
1. **"Set prices in all countries"** seçin
2. **"Use pricing template"** seçin (veya manuel)
3. **Base price:** $9.99 USD
4. **"Apply template"** tıklayın
5. Türkiye için özel fiyat: **₺99.99** (manuel ayarlayın)

**Save** tıklayın

### 3.3 Ürün 2: Yıllık Premium

**Product ID:** `hemoai_premium_yearly`

**Basit bilgiler:**
- **Name:** `HemoAI Premium Yearly`
- **Description:** 
  ```
  Yearly subscription to HemoAI Premium features.
  Save 17% compared to monthly subscription.
  ```

**Subscription details:**
- **Type:** `Subscription` (Auto-renewing subscription)
- **Billing period:** `1 year`
- **Free trial:** `None`
- **Grace period:** `3 days`

**Pricing:**
- **Base price:** $99.99 USD
- Türkiye: **₺799.99**

**Save** tıklayın

### 3.4 Ürün 3: Yaşam Boyu Premium

**Product ID:** `hemoai_premium_lifetime`

**Basit bilgiler:**
- **Name:** `HemoAI Premium Lifetime`
- **Description:** 
  ```
  Lifetime access to all HemoAI Premium features.
  One-time payment, no recurring charges.
  ```

**Product details:**
- **Type:** `Managed product` (One-time purchase)
- **Note:** Subscription değil, tek seferlik satın alma

**Pricing:**
- **Base price:** $299.99 USD
- Türkiye: **₺2499.99**

**Save** tıklayın

---

## 📋 ADIM 4: Fiyatlandırma Ayarları

### 4.1 Her Ürün İçin

1. Ürünü açın
2. **"Pricing"** sekmesine gidin
3. **"Set prices in all countries"** seçin
4. Ülkeler için fiyatları ayarlayın:
   - **Türkiye:** TRY (₺)
   - **USA:** USD ($)
   - **UK:** GBP (£)
   - **EU:** EUR (€)
   - vs.

### 4.2 Fiyat Önerileri

**Aylık:**
- Türkiye: ₺99.99
- USA: $9.99
- UK: £7.99
- EU: €8.99

**Yıllık:**
- Türkiye: ₺799.99
- USA: $99.99
- UK: £79.99
- EU: €89.99

**Yaşam Boyu:**
- Türkiye: ₺2499.99
- USA: $299.99
- UK: £249.99
- EU: €279.99

---

## 📋 ADIM 5: Test Hesapları

1. **"Setup"** → **"License testing"** bölümüne gidin
2. **"Add testers"** tıklayın
3. Test yapmak istediğiniz **Gmail adreslerini** ekleyin
4. **"Save"** tıklayın

**Not:** Test hesapları ile satın alma yaparken gerçek ödeme alınmaz.

---

## 📋 ADIM 6: Ödeme Profili

1. **"Setup"** → **"Payments profile"** bölümüne gidin
2. **Banka hesabı bilgilerinizi** ekleyin:
   - Türkiye'den bağlanabilirsiniz
   - IBAN ile bağlanabilirsiniz
   - SWIFT kodu gerekebilir
3. **Vergi bilgileri** girin (Türkiye için)
4. **"Save"** tıklayın

---

## 📋 ADIM 7: Ürünleri Aktif Etme

1. Her ürün için **"Active"** durumuna getirin
2. **"Save"** tıklayın

**Not:** Ürünler aktif olmadan önce uygulamanın production'da olması gerekmez. Test için aktif edebilirsiniz.

---

## 📋 ADIM 8: Flutter App'te Kullanım

Ürünler oluşturulduktan sonra, Flutter app'teki `PaymentService` otomatik olarak ürünleri yükler:

```dart
// lib/services/payment_service.dart içinde zaten tanımlı:
static const String _productIdMonthly = 'hemoai_premium_monthly';
static const String _productIdYearly = 'hemoai_premium_yearly';
static const String _productIdLifetime = 'hemoai_premium_lifetime';
```

**Ek bir işlem gerekmez!** Ürünler Google Play Console'da oluşturulduktan sonra otomatik çalışır.

---

## ✅ DOĞRULAMA

1. **Test cihazında uygulamayı açın**
2. **Premium ekranına gidin**
3. **Satın alma butonuna tıklayın**
4. **Google Play ödeme ekranı** görünmeli
5. **Test hesabı ile ödeme yapın** (gerçek ödeme alınmaz)

---

## 🐛 SORUN GİDERME

### Ürün bulunamıyor

- Google Play Console'da ürünün **"Active"** durumda olduğundan emin olun
- Product ID'lerin tam olarak eşleştiğinden emin olun (büyük/küçük harf duyarlı)
- Uygulamanın aynı package name ile yayınlandığından emin olun

### Ödeme yapılamıyor

- Test hesabının License Testing'de olduğundan emin olun
- Google Play Services'in güncel olduğundan emin olun
- İnternet bağlantısını kontrol edin

### Fiyatlar görünmüyor

- Ürünlerin fiyatlandırıldığından emin olun
- Cihazın bölgesinin doğru olduğundan emin olun
- Uygulamayı yeniden başlatın

---

## 📞 DESTEK

**Google Play Console Yardım:**
- https://support.google.com/googleplay/android-developer
- https://support.google.com/googleplay/android-developer/answer/1153481

---

**Son Güncelleme:** 2025-01-04  
**Versiyon:** 1.0

