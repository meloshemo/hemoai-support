# 💳 Türkiye için Ödeme Entegrasyonu Rehberi (İyzico/PayTR)

## 🇹🇷 Türkiye'de Mevcut Ödeme Sistemleri

Türkiye'de Stripe mevcut olmadığı için aşağıdaki BDDK lisanslı ödeme sistemlerini kullanabilirsiniz:

### 1. **İyzico** (Önerilen ⭐)
- ✅ En yaygın kullanılan ödeme gateway'i
- ✅ İyi dokümantasyon ve destek
- ✅ REST API ile kolay entegrasyon
- ✅ Abonelik (subscription) desteği
- ✅ Komisyon: ~%2.9 + ₺0.25
- 🌐 Website: https://www.iyzico.com

### 2. **PayTR**
- ✅ Hızlı başvuru süreci
- ✅ Basit entegrasyon
- ✅ Abonelik desteği
- 🌐 Website: https://www.paytr.com

### 3. **PayU**
- ✅ Yaygın kullanılan
- ✅ E-ticaret odaklı
- 🌐 Website: https://www.payu.com.tr

### 4. **Shopier**
- ✅ Dijital ürünler için uygun
- ✅ Küçük işletmeler için pratik
- 🌐 Website: https://www.shopier.com

### 5. **Craftgate**
- ✅ Çoklu POS desteği
- ✅ Büyük işletmeler için
- 🌐 Website: https://www.craftgate.io

---

## 🚀 İyzico Entegrasyonu (Önerilen)

### 1. İyzico Hesabı Oluşturma

1. [İyzico.com](https://www.iyzico.com) adresine gidin
2. "Başvuru Yap" ile hesap oluşturun
3. Şirket bilgilerinizi girin
4. Başvurunuz onaylandıktan sonra API anahtarlarınızı alın

### 2. İyzico API Bilgileri

İyzico panelinden şunları alacaksınız:
- **API Key**: `sandbox-xxxxx` (test) veya `prod-xxxxx` (canlı)
- **Secret Key**: `sandbox-xxxxx` veya `prod-xxxxx`
- **Base URL**: 
  - Test: `https://sandbox-api.iyzipay.com`
  - Canlı: `https://api.iyzipay.com`

### 3. Flutter Entegrasyonu

İyzico için Flutter SDK yok, ancak REST API'yi kullanabilirsiniz. `PaymentService`'i İyzico için güncelleyeceğiz.

---

## 📱 Mobil Uygulama Ödemeleri (Türkiye'de Çalışıyor)

### Android (Google Play Billing)
- ✅ Türkiye'de tam destekleniyor
- ✅ Türk Lirası ile ödeme alabilirsiniz
- ✅ Google Play Console'da TRY fiyatlandırma yapabilirsiniz

### iOS (App Store In-App Purchase)
- ✅ Türkiye'de tam destekleniyor
- ✅ Türk Lirası ile ödeme alabilirsiniz
- ✅ App Store Connect'te TRY fiyatlandırma yapabilirsiniz

**Önemli**: Mobil uygulamalar için Google Play ve App Store ödemelerini kullanabilirsiniz. Sadece web ödemeleri için İyzico/PayTR kullanmanız gerekir.

---

## 🔧 İyzico REST API Kullanımı

### Örnek: Tek Ödeme (One-Time Payment)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';

class IyzicoPaymentService {
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _secretKey = 'YOUR_SECRET_KEY';
  static const String _baseUrl = 'https://sandbox-api.iyzipay.com'; // veya canlı URL

  // İyzico API'ye ödeme isteği gönder
  Future<Map<String, dynamic>> createPayment({
    required double price,
    required String currency,
    required String email,
    required String name,
    String? planType, // 'monthly', 'yearly', 'lifetime'
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': DateTime.now().millisecondsSinceEpoch.toString(),
      'price': price.toStringAsFixed(2),
      'paidPrice': price.toStringAsFixed(2),
      'currency': currency,
      'basketId': 'BASKET${DateTime.now().millisecondsSinceEpoch}',
      'paymentCard': {
        'cardHolderName': name,
        'cardNumber': '', // İyzico iFrame kullanıldığında gerekli değil
      },
      'buyer': {
        'id': email,
        'name': name,
        'surname': name.split(' ').last,
        'gsmNumber': '',
        'email': email,
        'identityNumber': '',
        'lastLoginDate': DateTime.now().toIso8601String(),
        'registrationDate': DateTime.now().toIso8601String(),
        'registrationAddress': '',
        'ip': '',
        'city': '',
        'country': 'Turkey',
        'zipCode': '',
      },
      'shippingAddress': {
        'contactName': name,
        'city': '',
        'country': 'Turkey',
        'address': '',
        'zipCode': '',
      },
      'billingAddress': {
        'contactName': name,
        'city': '',
        'country': 'Turkey',
        'address': '',
        'zipCode': '',
      },
      'basketItems': [
        {
          'id': 'BI101',
          'name': planType == 'lifetime' 
              ? 'HemoAI Premium Yaşam Boyu' 
              : planType == 'yearly'
                  ? 'HemoAI Premium Yıllık'
                  : 'HemoAI Premium Aylık',
          'category1': 'Premium Subscription',
          'itemType': 'VIRTUAL',
          'price': price.toStringAsFixed(2),
        }
      ],
      'metadata': {
        'plan_type': planType ?? 'monthly',
      },
    };

    // İyzico signature oluştur
    final authorization = _createAuthorization(request);
    
    final response = await http.post(
      Uri.parse('$_baseUrl/payment/auth'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorization,
      },
      body: jsonEncode(request),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Payment failed: ${response.body}');
    }
  }

  // İyzico authorization header oluştur
  String _createAuthorization(Map<String, dynamic> request) {
    final randomString = _generateRandomString();
    final requestString = jsonEncode(request);
    
    // SHA256 hash oluştur
    final hashInput = '${_secretKey}${randomString}${requestString}';
    final hash = sha256.convert(utf8.encode(hashInput)).toString();
    
    final authorization = base64Encode(utf8.encode(
      '${_apiKey}:${hash}:${randomString}'
    ));
    
    return 'IYZWS $authorization';
  }

  String _generateRandomString() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random;
  }
}
```

### İyzico iFrame Yöntemi (Önerilen)

İyzico, güvenli ödeme için iFrame yöntemi kullanır. Bu yöntemde:

1. Ödeme sayfasını iFrame olarak gösterirsiniz
2. Kullanıcı kart bilgilerini İyzico'nun güvenli sayfasına girer
3. Ödeme tamamlandığında callback alırsınız

**Web için**: İyzico'nun JavaScript SDK'sını kullanabilirsiniz (Flutter Web'de JS interop ile).

---

## 🔄 Ödeme Akışı (İyzico)

1. **Kullanıcı ödeme yapmak ister**
2. **Backend servisiniz İyzico'ya ödeme isteği gönderir**
3. **İyzico ödeme sayfası URL'i döner**
4. **Kullanıcı URL'ye yönlendirilir ve kart bilgilerini girer**
5. **Ödeme tamamlanır, callback URL'inize yönlendirilir**
6. **Backend webhook'tan ödemeyi doğrular ve premium aktif eder**

---

## 💰 Para Transferi (İyzico)

- **İlk ödemeler**: 2-3 iş günü içinde hesabınıza aktarılır
- **Düzenli ödemeler**: Genellikle 1-2 iş günü
- **Komisyon**: İyzico komisyonu keser (~%2.9 + ₺0.25)
- **Para çekme**: İyzico panelinden banka hesabınıza çekebilirsiniz

---

## 🔐 Güvenlik

1. **API Key ve Secret Key**: Asla client-side'da saklamayın, sadece backend'de kullanın
2. **HTTPS**: Tüm iletişim HTTPS üzerinden olmalı
3. **Webhook Signature**: İyzico webhook'larını mutlaka doğrulayın
4. **PCI-DSS**: İyzico PCI-DSS uyumludur, kart bilgileri sizde saklanmaz

---

## 📝 Backend Webhook (İyzico)

İyzico, ödeme tamamlandığında webhook gönderir. Backend servisinizde:

```javascript
// Node.js örneği
app.post('/webhook/iyzico', async (req, res) => {
  const signature = req.headers['x-iyz-signature'];
  const body = req.body;
  
  // Signature doğrula
  const isValid = verifyIyzicoSignature(signature, body);
  if (!isValid) {
    return res.status(400).send('Invalid signature');
  }
  
  // Ödeme başarılı
  if (body.status === 'success') {
    const email = body.buyer.email;
    const planType = body.metadata?.plan_type;
    
    // Premium'u aktif et
    await activatePremium(email, planType);
  }
  
  res.json({ received: true });
});
```

---

## 🎯 Önerilen Yaklaşım

### Web Ödemeleri için:
1. **İyzico kullanın** (en yaygın ve güvenilir)
2. Backend servisi kurun (Node.js/Python/Dart)
3. İyzico API'yi backend'den çağırın
4. Webhook ile ödemeyi doğrulayın

### Mobil Ödemeler için:
1. **Google Play Billing** (Android) - Zaten mevcut ✅
2. **App Store In-App Purchase** (iOS) - Zaten mevcut ✅
3. Türk Lirası fiyatlandırma yapın

---

## 📞 Destek

- **İyzico Destek**: support@iyzico.com
- **İyzico Dokümantasyon**: https://dev.iyzipay.com
- **İyzico API Referans**: https://dev.iyzipay.com/tr/api/referans

---

## ✅ Checklist

- [ ] İyzico hesabı oluşturuldu
- [ ] API Key ve Secret Key alındı
- [ ] Backend servisi kuruldu
- [ ] İyzico entegrasyonu yapıldı
- [ ] Webhook endpoint oluşturuldu
- [ ] Test ödemesi yapıldı
- [ ] Production'a geçiş yapıldı
- [ ] Google Play/App Store ürünleri TRY ile fiyatlandırıldı

---

**Son Güncelleme**: 2024

