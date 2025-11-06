# 🇹🇷 Türkiye için Ödeme Sistemi Özeti

## ✅ Yapılanlar

1. ✅ **TurkishPaymentService** oluşturuldu (`lib/services/turkish_payment_service.dart`)
2. ✅ **Premium Screen** güncellendi (otomatik Türkiye algılama)
3. ✅ **Türkçe ödeme entegrasyonu rehberi** hazırlandı
4. ✅ **Mobil ödemeler** zaten çalışıyor (Google Play/App Store)

## 🎯 Nasıl Çalışıyor?

### Otomatik Seçim
- Uygulama dili **Türkçe** ise → `TurkishPaymentService` (İyzico)
- Uygulama dili **diğer diller** ise → `PaymentService` (Stripe)

### Ödeme Yöntemleri

#### 📱 Mobil Uygulamalar (Android/iOS)
- ✅ **Google Play Billing** (Android) - Türkiye'de çalışıyor
- ✅ **App Store In-App Purchase** (iOS) - Türkiye'de çalışıyor
- ✅ Türk Lirası (TRY) ile fiyatlandırma yapılabilir

#### 🌐 Web Uygulaması
- ⚠️ **Backend servisi gerekli** (İyzico entegrasyonu için)
- Backend servisi İyzico API'yi çağırır
- Kullanıcı İyzico ödeme sayfasına yönlendirilir
- Ödeme sonrası webhook ile premium aktif edilir

## 🔧 Yapılacaklar (Web Ödemeleri için)

### 1. İyzico Hesabı Oluşturma
- [İyzico.com](https://www.iyzico.com) üzerinden başvuru
- API Key ve Secret Key alma

### 2. Backend Servisi Kurulumu
- Node.js/Python/Dart ile backend servisi
- İyzico REST API entegrasyonu
- Webhook endpoint oluşturma

### 3. TurkishPaymentService Güncelleme
`lib/services/turkish_payment_service.dart` dosyasında:
```dart
static const String _backendPaymentUrl = 'https://your-backend.com/api/payment/create';
```
Bu URL'i kendi backend servisinizin URL'i ile değiştirin.

### 4. Test
- Test ödemesi yapma
- Webhook'u test etme
- Premium aktivasyonunu doğrulama

## 📚 Dokümantasyon

Detaylı bilgi için:
- **`docs/TURKISH_PAYMENT_INTEGRATION.md`** - Türkiye ödeme entegrasyonu rehberi
- **`docs/PAYMENT_INTEGRATION_GUIDE.md`** - Genel ödeme rehberi (Stripe için)
- **`docs/STRIPE_WEBHOOK_EXAMPLE.md`** - Webhook örnekleri (İyzico için de uyarlanabilir)

## 💡 Önemli Notlar

1. **Mobil uygulamalar** için ekstra bir şey yapmanıza gerek yok, Google Play ve App Store zaten Türkiye'de çalışıyor
2. **Web ödemeleri** için backend servisi şart (güvenlik için API key'ler backend'de olmalı)
3. **İyzico komisyonu**: ~%2.9 + ₺0.25
4. **Ödeme süresi**: 2-3 iş günü içinde hesabınıza aktarılır

## 🚀 Hızlı Başlangıç

1. İyzico hesabı oluşturun
2. Backend servisi kurun (veya outsourcing yapın)
3. `TurkishPaymentService`'te backend URL'ini güncelleyin
4. Test ödemesi yapın
5. Production'a geçin

---

**Son Güncelleme**: 2024

