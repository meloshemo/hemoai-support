# Data Safety Declaration - Quick Reference

Bu belge, Play Console'da Data Safety formunu doldururken hızlı referans için hazırlanmıştır.

## ✅ Hızlı Cevaplar

### 1. "Does your app collect or share any of the required user data types?"
**Cevap:** ✅ **Yes**

### 2. "Does your app collect data from children?"
**Cevap:** ❌ **No** (18+ hedef kitle)

### 3. "Is all the user data collected by your app encrypted in transit?"
**Cevap:** ✅ **Yes** (N/A for local-only data)

### 4. "Do you provide a way for users to request deletion of their data?"
**Cevap:** ✅ **Yes**

---

## 📋 Toplanan Veri Türleri

### 1. Health & Fitness Data ✅
- **Ne:** Kan test sonuçları, ilaçlar, sağlık metrikleri, diyet takibi
- **Amaç:** Sağlık analizi, kişiselleştirilmiş öneriler, trend takibi
- **Paylaşım:** ❌ HİÇ KİMSEYLE (sadece yerel depolama)
- **Gerekli:** ❌ Hayır
- **Şifreleme (transit):** N/A (hiçbir zaman iletim yok)
- **Şifreleme (rest):** ✅ Evet (AES-256)

### 2. Personal Information ✅
- **Ne:** Yaş, cinsiyet, boy, kilo, BMI, profil adı
- **Amaç:** Kişiselleştirilmiş hesaplamalar, öneriler
- **Paylaşım:** ❌ HİÇ KİMSEYLE
- **Gerekli:** ❌ Hayır
- **Şifreleme (transit):** N/A
- **Şifreleme (rest):** ✅ Evet

### 3. Photos & Videos ⚠️ (Opsiyonel)
- **Ne:** OCR için lab rapor görüntüleri
- **Amaç:** Metin çıkarma, hızlı veri girişi
- **Paylaşım:** ❌ HİÇ KİMSEYLE
- **Gerekli:** ❌ Hayır (manuel giriş mevcut)
- **Şifreleme (rest):** ✅ Evet (yedeklerde)

### 4. App Activity ⚠️ (Opsiyonel, Opt-in)
- **Ne:** Kullanım desenleri, analitik, crash raporları
- **Amaç:** Uygulama stabilitesi, hata düzeltme
- **Paylaşım:** Analytics provider (sadece etkinse)
- **Gerekli:** ❌ Hayır
- **Şifreleme (transit):** ✅ Evet
- **Şifreleme (rest):** ✅ Evet

### 5. Device or Other IDs ⚠️ (Opsiyonel)
- **Ne:** Analytics için cihaz ID (etkinse)
- **Amaç:** Crash raporlama, performans izleme
- **Paylaşım:** Analytics provider (sadece etkinse)
- **Gerekli:** ❌ Hayır
- **Şifreleme (transit):** ✅ Evet
- **Şifreleme (rest):** ✅ Evet

---

## ❌ Toplanmayan Veriler

- ❌ Finansal bilgiler
- ❌ Konum verisi (GPS)
- ❌ Kişiler
- ❌ SMS/Telefon logları
- ❌ E-posta adresleri (kullanıcı rapor dışa aktarmadıkça)
- ❌ Sosyal medya verileri

---

## 🔒 Güvenlik Uygulamaları

### Şifreleme
- **Transit:** TLS 1.3 (bulut özellikleri için)
- **Rest:** AES-256-GCM (yedekler için)
- **Key derivation:** PBKDF2-HMAC-SHA256 (100,000 iterasyon)

### Kullanıcı Kontrolü
- ✅ Tüm verileri görüntüleme, düzenleme, silme
- ✅ Şifreli dışa aktarma
- ✅ Otomatik veri toplama yok
- ✅ Tüm özellikler için açık opt-in/opt-out

---

## 📤 Veri Paylaşımı

### Üçüncü Taraflarla Paylaşım?
**Cevap:** ❌ **NO**

- Varsayılan olarak paylaşım yok
- Bulut yedekleme etkinse (opt-in): Şifreli veriler Supabase sunucularında saklanabilir
- Tamamen şifreli, biz okuyamayız
- Kullanıcı istediği zaman silebilir

---

## 🗑️ Veri Silme

### Kullanıcı Nasıl Silebilir?
1. **Tekil kayıtlar:** Herhangi bir test sonucu, ilaç veya hatırlatıcıyı silme
2. **Toplu silme:** Ayarlar → Tüm Verileri Temizle
3. **Dışa aktarma sonrası silme:** Veriyi yedekle, sonra kaldır
4. **Kaldırma:** Uygulamayı cihazdan kaldırma

### Otomatik Silme?
**Cevap:** ❌ **No**

### Zaman Çizelgesi
- Çoğu veri için anında silme
- Bulut veri silme: 30 gün içinde
- Yedekler: Kalıcı olarak şifreli, şifre olmadan erişilemez

---

## 📝 "How is data used?" Örnek Cevap

```
Primary Uses:
- Generate AI-powered health insights from blood test data
- Provide personalized diet and lifestyle recommendations
- Track health trends and generate reports
- Remind users about medications, tests, and appointments

Secondary Uses:
- Improve app stability and fix bugs (crash reporting, opt-in)
- Enhance user experience (usage analytics, opt-in)
- Support and troubleshooting (technical logs, opt-in)

Security and Fraud Prevention:
- Verify user identity via optional biometrics
- Encrypt sensitive health data
- Detect and prevent unauthorized access
```

---

## 🌍 Bölgesel Uyumluluk

### GDPR (EU) ✅
- Erişim hakkı: Kullanıcılar tüm verileri dışa aktarabilir
- Düzeltme hakkı: Herhangi bir bilgiyi düzenleme
- Silme hakkı: Tüm verileri silme
- İşlemeyi kısıtlama hakkı: Özellikleri devre dışı bırakma
- Veri taşınabilirliği: Dışa aktarma formatı
- İtiraz hakkı: Analitikten çıkış

### CCPA (California) ✅
- Veri kategorileri açıklandı
- Kişisel bilgi satışı yok
- Silme hakkı
- Bilme hakkı

### KVKK (Türkiye) ✅
- Kişisel veriler yasal olarak işleniyor
- Spesifik amaçlar beyan edildi
- Kullanıcı onayı alındı
- Güvenli depolama uygulandı

---

## 📞 Veri İstekleri İçin İletişim

- **E-posta:** support@hemoai.org
- **Yanıt süresi:** 30 gün içinde (GDPR gereksinimi)
- **Format:** JSON, PDF veya Excel (isteğe bağlı)

---

## ✅ Gönderim Öncesi Kontrol Listesi

- [x] Tüm veri türleri beyan edildi
- [x] Şifreleme uygulamaları belirtildi
- [x] Kullanıcı silme hakları dokümante edildi
- [x] Gizlilik politikası URL'si sağlandı
- [x] Varsayılan olarak veri toplama yok
- [x] Opsiyonel özellikler için açık opt-in
- [x] Yaş kısıtlamaları not edildi (18+)
- [x] Bölgesel uyumluluk bahsedildi

---

**Detaylı bilgi için:** `docs/DATA_SAFETY_DECLARATION.md`

