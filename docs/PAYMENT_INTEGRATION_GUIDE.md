# 🏦 HemoAI Ödeme Entegrasyonu Rehberi

## 📋 Genel Bakış

HemoAI uygulaması iki farklı ödeme yöntemini destekler:
- **Mobil (Android/iOS)**: Google Play Billing ve App Store In-App Purchases
- **Web**: Stripe Checkout

Bu rehber, ödeme sisteminin nasıl kurulacağını ve ödemelerin sizin hesabınıza nasıl yansıyacağını açıklar.

---

## 🔧 1. Stripe Hesabı Kurulumu (Web Ödemeleri)

### 1.1 Stripe Hesabı Oluşturma
1. [Stripe.com](https://stripe.com) adresine gidin
2. "Sign up" ile hesap oluşturun
3. E-posta doğrulamasını tamamlayın
4. İş bilgilerinizi girin (şirket adı, vergi bilgisi, vb.)

### 1.2 Stripe Dashboard'a Erişim
- Dashboard: https://dashboard.stripe.com
- Test modu ve canlı mod arasında geçiş yapabilirsiniz

### 1.3 Ödeme Ürünlerini Oluşturma

Stripe Dashboard'da **Products** > **Add product** ile üç ürün oluşturun:

#### Aylık Premium
- **Name**: HemoAI Premium Monthly
- **Price**: $4.99 USD (veya TRY eşdeğeri)
- **Billing**: Recurring - Monthly
- **Product ID**: `hemoai_premium_monthly`

#### Yıllık Premium
- **Name**: HemoAI Premium Yearly
- **Price**: $39.99 USD (veya TRY eşdeğeri)
- **Billing**: Recurring - Yearly
- **Product ID**: `hemoai_premium_yearly`

#### Yaşam Boyu Premium
- **Name**: HemoAI Premium Lifetime
- **Price**: $99.99 USD (veya TRY eşdeğeri)
- **Billing**: One-time
- **Product ID**: `hemoai_premium_lifetime`

### 1.4 Stripe Checkout URL'lerini Oluşturma

Stripe Dashboard'da **Checkout** > **Create checkout link** ile her ürün için ödeme linki oluşturun:

1. Ürünü seçin
2. "Create payment link" tıklayın
3. Oluşan URL'yi kopyalayın

Örnek URL formatı:
```
https://buy.stripe.com/test_xxxxx_monthly
https://buy.stripe.com/test_xxxxx_yearly
https://buy.stripe.com/test_xxxxx_lifetime
```

⚠️ **Önemli**: Production'da test linklerini değiştirmeyi unutmayın!

---

## 🔐 2. Backend Webhook Servisi Kurulumu

### 2.1 Webhook Nedir?
Stripe, ödeme tamamlandığında backend servisinize bir webhook (HTTP POST) gönderir. Bu webhook ile ödemenin gerçek olduğunu doğrulayıp kullanıcının premium durumunu güncelleyebilirsiniz.

### 2.2 Webhook Endpoint Oluşturma

Aşağıdaki örnek Node.js/Express backend servisini kullanabilirsiniz:

```javascript
// server.js
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const app = express();

// Stripe webhook middleware
app.use('/webhook', express.raw({type: 'application/json'}));

app.post('/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    // Webhook'u doğrula
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Ödeme başarılı olduğunda
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const customerEmail = session.customer_email;
    const amount = session.amount_total / 100; // Stripe cent cinsinden tutar

    console.log(`Payment successful: ${customerEmail} - $${amount}`);

    // Kullanıcının premium durumunu güncelle
    await updateUserPremiumStatus(customerEmail, session.metadata);
  }

  res.json({received: true});
});

async function updateUserPremiumStatus(email, metadata) {
  // Burada kendi veritabanınızı güncelleyin
  // Örnek:
  // - Kullanıcıyı email ile bul
  // - Premium tier'ı güncelle
  // - Subscription expiry date'i set et
  // - Premium özelliklerini aktif et
  
  console.log(`Updating premium for: ${email}`);
  // TODO: Veritabanı güncelleme işlemi
}

app.listen(3000, () => {
  console.log('Webhook server running on port 3000');
});
```

### 2.3 Webhook Secret Key'i Alma

1. Stripe Dashboard > **Developers** > **Webhooks**
2. "Add endpoint" tıklayın
3. Endpoint URL'i girin: `https://yourdomain.com/webhook`
4. "Select events" ile şu event'leri seçin:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. "Add endpoint" ile oluşturun
6. "Signing secret" kopyalayın (WH_... ile başlar)

### 2.4 Environment Variables

Backend servisinizde şu environment variable'ları ayarlayın:

```bash
STRIPE_SECRET_KEY=sk_live_xxxxx  # Production secret key
STRIPE_WEBHOOK_SECRET=whsec_xxxxx  # Webhook signing secret
```

---

## 💳 3. Ödeme Akışı ve Para Transferi

### 3.1 Ödeme Süreci

1. **Kullanıcı Premium ekranında ödeme yapmak ister**
2. **Web'de**: Stripe Checkout URL'i açılır
3. **Kullanıcı kart bilgilerini girer** (Stripe güvenli formu)
4. **Ödeme tamamlanır**
5. **Stripe webhook gönderir** → Backend servisiniz
6. **Backend servisi kullanıcıyı premium yapar**
7. **Para Stripe hesabınıza geçer**

### 3.2 Para Nasıl Hesabınıza Gelir?

Stripe, ödemeleri otomatik olarak hesabınıza aktarır:

- **Test Modu**: Para gerçek değildir, test amaçlıdır
- **Canlı Mod**: 
  - İlk ödemeler 2-7 gün içinde Stripe hesabınıza aktarılır
  - Daha sonraki ödemeler genellikle 2 iş günü içinde gelir
  - Stripe, ödemeleri banka hesabınıza otomatik olarak aktarır

### 3.3 Stripe Ücretleri

Stripe şu komisyonları alır:
- **Kredi Kartı**: %2.9 + $0.30 (ABD), %3.4 + ₺1.95 (Türkiye)
- **Diğer ödeme yöntemleri**: Farklı oranlar

Stripe Dashboard'dan tam detayları görebilirsiniz.

### 3.4 Para Çekme

1. Stripe Dashboard > **Payouts**
2. Bağlı banka hesabınızı ekleyin (Settings > Bank accounts)
3. Para otomatik olarak aktarılır veya manuel çekebilirsiniz

---

## 📱 4. Mobil Uygulama Ödemeleri (Android/iOS)

### 4.1 Google Play Console (Android)

1. [Google Play Console](https://play.google.com/console) > Uygulamanızı seçin
2. **Monetize** > **Products** > **Subscriptions** veya **In-app products**
3. Üç ürün oluşturun:
   - `hemoai_premium_monthly`: Monthly subscription
   - `hemoai_premium_yearly`: Yearly subscription  
   - `hemoai_premium_lifetime`: One-time purchase

4. **Fiyatlandırma**: Ülkeye göre fiyatları ayarlayın
5. **Publish** ile yayınlayın

### 4.2 App Store Connect (iOS)

1. [App Store Connect](https://appstoreconnect.apple.com) > Uygulamanızı seçin
2. **Features** > **In-App Purchases**
3. Üç ürün oluşturun:
   - Monthly Auto-Renewable Subscription
   - Yearly Auto-Renewable Subscription
   - Non-Consumable (Lifetime)

4. **Product ID**: `hemoai_premium_monthly`, `hemoai_premium_yearly`, `hemoai_premium_lifetime`
5. Fiyatlandırmayı ayarlayın

### 4.3 Mobil Ödeme Komisyonları

- **Google Play**: %15-30 (ilk $1M'dan sonra %15)
- **App Store**: %15-30 (ilk $1M'dan sonra %15)

---

## 🔄 5. PaymentService Güncellemesi

`lib/services/payment_service.dart` dosyasını güncelleyin:

```dart
// Gerçek Stripe Checkout URL'lerini ekleyin
static const String _stripeMonthlyUrl = 'https://buy.stripe.com/YOUR_MONTHLY_LINK';
static const String _stripeYearlyUrl = 'https://buy.stripe.com/YOUR_YEARLY_LINK';
static const String _stripeLifetimeUrl = 'https://buy.stripe.com/YOUR_LIFETIME_LINK';
```

---

## ✅ 6. Ödeme Doğrulama ve Premium Aktivasyon

### 6.1 Webhook ile Doğrulama (Önerilen)

Backend servisiniz Stripe'dan gelen webhook'u doğrular ve kullanıcının premium durumunu günceller. Ardından uygulamaya bildirim gönderebilirsiniz (push notification veya email).

### 6.2 Alternatif: Client-Side Polling

Web ödemelerinde, ödeme sonrası kullanıcı uygulamaya döndüğünde, backend'den premium durumunu kontrol edebilirsiniz:

```dart
// Premium ekranında ödeme sonrası kontrol
Future<void> checkPaymentStatus() async {
  final userId = await PreferencesService().getCurrentUserId();
  final response = await http.get(
    Uri.parse('https://yourbackend.com/api/user/$userId/premium-status')
  );
  // Premium durumunu güncelle
}
```

---

## 🔒 7. Güvenlik Önlemleri

1. **Webhook Secret**: Mutlaka kullanın, webhook'ları doğrulayın
2. **HTTPS**: Tüm iletişim HTTPS üzerinden olmalı
3. **Rate Limiting**: Webhook endpoint'inize rate limiting ekleyin
4. **Logging**: Tüm ödemeleri loglayın
5. **Error Handling**: Hataları yakalayıp kullanıcıya bildirin

---

## 📊 8. Ödeme İstatistikleri

Stripe Dashboard'dan şunları takip edebilirsiniz:
- Günlük/haftalık/aylık gelir
- Aktif aboneler
- İptal oranları
- Ülkeye göre ödemeler
- Başarısız ödemeler

---

## 🚀 9. Production'a Geçiş

### Test Modundan Canlı Moda Geçiş

1. Stripe Dashboard'da test modundan çıkın
2. Gerçek API key'leri kullanın (`sk_live_...`)
3. Production Checkout URL'lerini `PaymentService`'e ekleyin
4. Backend webhook'u production URL'e güncelleyin
5. Webhook secret'ı production secret ile değiştirin
6. Test ödemesi yaparak doğrulayın

---

## 📞 10. Destek

- **Stripe Dokümantasyonu**: https://stripe.com/docs
- **Stripe Support**: support@stripe.com
- **Google Play Billing**: https://developer.android.com/google/play/billing
- **App Store Connect**: https://developer.apple.com/app-store-connect/

---

## ✅ Checklist

- [ ] Stripe hesabı oluşturuldu
- [ ] Üç ürün (monthly/yearly/lifetime) oluşturuldu
- [ ] Checkout URL'leri alındı
- [ ] Backend webhook servisi kuruldu
- [ ] Webhook endpoint Stripe'a kaydedildi
- [ ] Webhook secret key alındı
- [ ] PaymentService URL'leri güncellendi
- [ ] Test ödemesi yapıldı
- [ ] Mobil uygulama için Google Play/App Store ürünleri oluşturuldu
- [ ] Production'a geçiş yapıldı

---

## 💡 Önemli Notlar

1. **Kart Bilgileri**: Stripe PCI-DSS uyumludur, kart bilgileri uygulamanızda saklanmaz
2. **Gerçek Ödeme**: Test modunda gerçek para geçmez, sadece canlı modda geçer
3. **Webhook Gecikmesi**: Bazen webhook gecikebilir, bu durumda client-side polling yapın
4. **Yasal Gereklilikler**: Ödeme işlemleri için KVKK/GDPR uyumluluğu gerekir
5. **Vergi**: Ödemelerden elde ettiğiniz gelir için vergi beyanı yapmanız gerekebilir

---

**Son Güncelleme**: 2024

