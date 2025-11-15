# Local Data Import & Retention Policy

_Last updated: 2025-11-11_

## 1. Kapsam

Bu politika, HemoAI uygulamasında gerçekleşen **OCR, QR, JSON/CSV, manuel metin** ve dosya tabanlı tüm yerel veri içe aktarma işlemlerini kapsar.

## 2. Veri İşleme Adımları

1. **Kullanıcı onayı**: `Settings → Data & Privacy → Local Import Policy` banner’ı üzerinden onay alınır.
2. **Geçici saklama**: İçeri aktarılan dosyalar yalnızca uygulama sandbox’ında RAM/ geçici dizinde işlenir, kalıcı depolamaya yazılmaz.
3. **Normalize & eşleştirme**: `DataImportService` veriyi hemogram alanlarına map eder, hatalı kayıtlar kullanıcıya bildirilir.
4. **Kalıcı kayıt**: Başarılı kayıtlar SQLite veritabanına ve opsiyonel olarak Supabase senkron kuyruğuna eklenir.

## 3. Saklama Süreleri

| Veri Tipi | Varsayılan Saklama | Kullanıcı Kontrolü |
| --- | --- | --- |
| Ham dosya (OCR görüntüsü, JSON vb.) | Anında imha (işleme sonrası silinir) | Kullanıcı ek aksiyonuna gerek yok |
| İçe aktarılan test sonuçları | 36 ay | `Settings → Data & Privacy → Delete imported data` |
| Log kayıtları (import hataları) | 30 gün | `Settings → Data & Privacy → Clear import logs` |

## 4. Kullanıcı Bilgilendirmesi

- Uygulama içinde **banner**: `Medical & Safety` bölümüne “Yerel Veri İçe Aktarma Politikası” linki eklendi.
- Ayarlar ekranında bilgilendirme metni ve “Politikayı oku” butonu mevcut.
- Privacy Policy’de (03. Veri Saklama) güncel saklama süreleri belirtildi.

## 5. Güvenlik Önlemleri

- Dosyalar yalnızca uygulamanın özel dizininde işlenir, 3. parti uygulamalar erişemez.
- OCR/JSON işleme thread’leri tamamlandığında `SecureDeleteUtils.wipeTemp()` çağrılır.
- Supabase senkronizasyonu TLS üzerinden yapılır; import edilen kayıtlar için UUID audit log tutulur.

## 6. İlgili Kod/Referanslar

- `lib/services/data_import_service.dart`
- `lib/screens/data_import_screen.dart`
- `docs/privacy-policy.html` (Veri saklama bölümü)
- `docs/compliance.md`

## 7. Sorular & İletişim

Politika hakkında sorular için: **privacy@hemoai.org**

