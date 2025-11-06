# 🍎 App Store In-App Purchase - Adım Adım Kurulum

## 🎯 Genel Bakış

Bu rehber, App Store Connect'te in-app purchase ürünlerini oluşturmanız için detaylı adımları içerir.

**Süre:** 45-90 dakika  
**Gereksinimler:** Apple Developer Program hesabı ($99 USD/yıl)

---

## 📋 ADIM 1: Apple Developer Program Kaydı

1. **Apple Developer Program'a gidin:** https://developer.apple.com/programs/
2. **"Enroll"** tıklayın
3. **Apple ID ile giriş yapın** (veya yeni hesap oluşturun)
4. **Bilgileri doldurun:**
   - Organization type (Individual veya Company)
   - Contact information
   - Payment information ($99 USD/yıl)
5. **Ödeme yapın** (kredi kartı ile)
6. **Onay bekleyin** (24-48 saat)

---

## 📋 ADIM 2: App Store Connect'e Giriş

1. **App Store Connect'e gidin:** https://appstoreconnect.apple.com
2. **Apple Developer hesabınızla giriş yapın**
3. İlk kez giriş yapıyorsanız:
   - **Agreements** bölümüne gidin
   - **Paid Applications Agreement**'i kabul edin
   - **Banking** ve **Tax** bilgilerini doldurun

---

## 📋 ADIM 3: Uygulama Oluşturma

1. **"My Apps"** menüsüne gidin
2. **"+"** → **"New App"** tıklayın
3. **Bilgileri doldurun:**
   ```
   Platform: iOS
   Name: HemoAI
   Primary Language: English (U.S.)
   Bundle ID: com.meloshemo.hemoai
   SKU: hemoai-ios-001
   ```
4. **"Create"** tıklayın

---

## 📋 ADIM 4: In-App Purchase Ürünleri Oluşturma

### 4.1 Subscription Group Oluşturma

1. **"Features"** → **"In-App Purchases"** bölümüne gidin
2. **"Manage"** → **"Subscription Groups"** → **"+"** tıklayın
3. **Reference Name:** `HemoAI Premium`
4. **"Create"** tıklayın

### 4.2 Ürün 1: Aylık Premium

1. **"In-App Purchases"** → **"+"** tıklayın
2. **Type:** `Auto-Renewable Subscription` seçin
3. **Subscription Group:** `HemoAI Premium` seçin
4. **"Create"** tıklayın

**Product Information:**
- **Reference Name:** `HemoAI Premium Monthly`
- **Product ID:** `hemoai_premium_monthly`
- **Subscription Duration:** `1 Month`

**Pricing and Availability:**
1. **"Pricing"** sekmesine gidin
2. **"Set up pricing"** tıklayın
3. **Base Price:** $9.99 USD seçin
4. Apple otomatik olarak diğer ülkeler için fiyat önerir
5. Türkiye için özel fiyat: **₺99.99** (manuel ayarlayın)

**Localization:**
1. **"Localization"** sekmesine gidin
2. **"+"** → **English (U.S.)** seçin
3. **Display Name:** `HemoAI Premium Monthly`
4. **Description:**
   ```
   Monthly subscription to HemoAI Premium features including:
   - Advanced AI analysis
   - Personalized diet recommendations
   - Unlimited test tracking
   - Family panel features
   - Priority support
   ```

**Save** tıklayın

### 4.3 Ürün 2: Yıllık Premium

1. **"In-App Purchases"** → **"+"** tıklayın
2. **Type:** `Auto-Renewable Subscription` seçin
3. **Subscription Group:** `HemoAI Premium` seçin
4. **"Create"** tıklayın

**Product Information:**
- **Reference Name:** `HemoAI Premium Yearly`
- **Product ID:** `hemoai_premium_yearly`
- **Subscription Duration:** `1 Year`

**Pricing:**
- **Base Price:** $99.99 USD
- Türkiye: **₺799.99**

**Localization:**
- **Display Name:** `HemoAI Premium Yearly`
- **Description:** `Yearly subscription to HemoAI Premium features. Save 17% compared to monthly subscription.`

**Save** tıklayın

### 4.4 Ürün 3: Yaşam Boyu Premium

1. **"In-App Purchases"** → **"+"** tıklayın
2. **Type:** `Non-Consumable` seçin (Subscription değil!)
3. **"Create"** tıklayın

**Product Information:**
- **Reference Name:** `HemoAI Premium Lifetime`
- **Product ID:** `hemoai_premium_lifetime`

**Pricing:**
- **Base Price:** $299.99 USD
- Türkiye: **₺2499.99**

**Localization:**
- **Display Name:** `HemoAI Premium Lifetime`
- **Description:** `Lifetime access to all HemoAI Premium features. One-time payment, no recurring charges.`

**Save** tıklayın

---

## 📋 ADIM 5: Subscription Group Ayarları

1. **Subscription Group**'u açın (`HemoAI Premium`)
2. **Subscription Levels** bölümüne gidin
3. **Aylık ve Yıllık** ürünleri sıralayın:
   - **Level 1:** Aylık (düşük öncelik)
   - **Level 2:** Yıllık (yüksek öncelik - kullanıcıya yıllık önerilir)
4. **Free Trial:** İsterseniz ücretsiz deneme ekleyin
5. **Introductory Offers:** İlk ay/yıl için indirim ekleyin (opsiyonel)

---

## 📋 ADIM 6: Test Hesapları

1. **"Users and Access"** → **"Sandbox Testers"** bölümüne gidin
2. **"+"** tıklayın
3. **Test hesabı bilgilerini** girin:
   - Email (gerçek olmayan bir email)
   - Password
   - First Name / Last Name
   - Country/Region
4. **"Save"** tıklayın

**Not:** Test hesapları ile satın alma yaparken gerçek ödeme alınmaz.

---

## 📋 ADIM 7: Ödeme Profili

1. **"Agreements, Tax, and Banking"** → **"Banking"** bölümüne gidin
2. **"Add Bank Account"** tıklayın
3. **Banka bilgilerinizi** girin:
   - Bank Name
   - Account Number
   - SWIFT Code (Türkiye için)
   - Account Holder Name
4. **"Save"** tıklayın

### 7.1 Vergi Bilgileri

1. **"Tax Information"** bölümüne gidin
2. **W-8BEN formunu** doldurun (Türkiye için)
3. **Vergi bilgilerinizi** girin
4. **"Save"** tıklayın

---

## 📋 ADIM 8: Ürünleri Review için Gönderme

1. Her ürün için **"Ready to Submit"** durumuna getirin
2. **"Submit for Review"** tıklayın
3. Apple review süreci başlar (1-7 gün)

**Not:** Ürünler, uygulama ile birlikte review edilir.

---

## 📋 ADIM 9: Flutter App'te Kullanım

Ürünler oluşturulduktan sonra, Flutter app'teki `PaymentService` otomatik olarak ürünleri yükler:

```dart
// lib/services/payment_service.dart içinde zaten tanımlı:
static const String _productIdMonthly = 'hemoai_premium_monthly';
static const String _productIdYearly = 'hemoai_premium_yearly';
static const String _productIdLifetime = 'hemoai_premium_lifetime';
```

**Ek bir işlem gerekmez!** Ürünler App Store Connect'te oluşturulduktan sonra otomatik çalışır.

---

## ✅ DOĞRULAMA

1. **TestFlight ile uygulamayı yükleyin**
2. **Sandbox test hesabı ile giriş yapın**
3. **Premium ekranına gidin**
4. **Satın alma butonuna tıklayın**
5. **App Store ödeme ekranı** görünmeli
6. **Test hesabı ile ödeme yapın** (gerçek ödeme alınmaz)

---

## 🐛 SORUN GİDERME

### Ürün bulunamıyor

- App Store Connect'te ürünün **"Ready to Submit"** veya **"Approved"** durumunda olduğundan emin olun
- Product ID'lerin tam olarak eşleştiğinden emin olun (büyük/küçük harf duyarlı)
- Uygulamanın aynı Bundle ID ile yayınlandığından emin olun

### Ödeme yapılamıyor

- Sandbox test hesabının doğru olduğundan emin olun
- TestFlight'ta test ettiğinizden emin olun
- Cihazın App Store'a giriş yapmadığından emin olun (sandbox hesabı için)

### Fiyatlar görünmüyor

- Ürünlerin fiyatlandırıldığından emin olun
- Cihazın bölgesinin doğru olduğundan emin olun
- Uygulamayı yeniden başlatın

---

## 📞 DESTEK

**App Store Connect Yardım:**
- https://developer.apple.com/support/
- https://help.apple.com/app-store-connect/

---

**Son Güncelleme:** 2025-01-04  
**Versiyon:** 1.0

