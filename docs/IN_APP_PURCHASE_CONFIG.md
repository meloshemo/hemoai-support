# 🛒 In-App Purchase Ürün Konfigürasyonu

Bu doküman, HemoAI’nin Premium özelliğini monetise etmek için Google Play
Console ve App Store Connect üzerinde oluşturulması gereken ürünleri ve Flutter
tarafındaki kontrol listesini içerir.

---

## 1. Google Play Console

1. Google Play Console → Uygulamayı seç → **Monetize** → **Products**.
2. Ürünleri oluştur:
   | Product ID | Tip | Önerilen Fiyat |
   |------------|-----|----------------|
   | `hemoai_premium_monthly` | Subscription | 9.99 USD / ay |
   | `hemoai_premium_yearly`  | Subscription | 99.99 USD / yıl |
   | `hemoai_premium_lifetime`| One-time     | 299.99 USD |
3. Ürün açıklamalarını TR/EN başta olmak üzere lokalize et.
4. “Managed publishing” altında taslakları yayınlanabilir duruma getir.
5. License testing kullanıcılarını ekle (Settings → License testing).

### Test
- Internal testing track oluştur, uygulamayı yayımla.
- Test cihaza yine aynı Google hesabıyla giriş yapıp satın alma akışını doğrula.

---

## 2. App Store Connect

1. App Store Connect → My Apps → Uygulama → **Features → In-App Purchases**.
2. Aynı Product ID’lerle 3 ürün oluştur (TR/EN isim & açıklama gir).
3. Fiyatları App Store para birimlerinde tanımla.
4. Review için gerekli ekran görüntülerini ekle.
5. “Ready to Submit” durumuna getir.
6. Sandbox tester kullanıcıları oluştur (Users and Access → Sandbox testers).

### Test
- TestFlight build gönder.
- AppleID sandbox hesabıyla cihazdan satın alma akışını doğrula.

---

## 3. Flutter tarafı kontrol listesi

- `lib/services/premium_service.dart` ve `lib/services/payment_service.dart`
  dosyalarında **aynı Product ID’lerin** tanımlı olduğundan emin ol.
- Android `billing` ve iOS `StoreKit` izinleri manifest/Info.plist içinde mevcut.
- Stripe backend’e gönderilen `planType` değerleri (`monthly`, `yearly`,
  `lifetime`) ile bu Product ID eşleşmeleri tutarlı.
- Satın alma başarısızlıklarında kullanıcıya geri bildirim gösteriliyor.
- QA sırasında test purchase’ları yapılıp ekran kayıtları alınacak.

---

## 4. Release öncesi hızlandırılmış kontrol listesi

- [ ] Google Play ürünleri “Active”.
- [ ] App Store ürünleri “Ready to Submit”.
- [ ] Test purchase (Android) → Başarılı.
- [ ] Test purchase (iOS Sandbox) → Başarılı.
- [ ] Stripe webhook’ları abonelik durumunu güncelliyor.
- [ ] Premium ekranında satın alma sonrası premium yetkileri açılıyor.
- [ ] Tüm metin/price bilgilerinin lokalizasyonu tam.

Bu adımlar tamamlandıktan sonra monetizasyon akışı production’a hazırdır.

