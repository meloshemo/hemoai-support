# Manual QA Results — 2025-11-14

Tester:
Environment: Edge (PWA/Web)
Locale(s) Tested:

## Summary
- A. Hemogram Sync: 
- B. Import/Export: 
- C. PWA Offline: 
- D. Accessibility: 

## Detailed Results

### A1) Insert + Auto-Archive Rule
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### A2) Cloud Sync Push/Pull
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### A3) Timeout/Network Error Localization
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### A4) Offline Entry Then Resync
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

---

### B1) Export Current Data
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### B2) Import Back
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### B3) Encrypted/Invalid Backup Errors
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

### B4) Metadata Read/Update Timeouts
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes:

---

### C1) Install PWA
- Steps: Edge'te http://localhost:60320/ adresini aç; adres çubuğundaki yükleme simgesine tıkla (veya Edge menü → Apps → Install this site as an app); kurulumdan sonra PWA pencere olarak aç.
- Expected: Uygulama adı/ikon doğru; kendi penceresinde çalışır; ilk çalıştırmadan sonra manifest ve SW önbellekleri hazırlanır.
- Actual:
- Result: Pass/Fail
- Notes:

### C2) Offline Navigation + Caching
- Steps: PWA penceresinde F12 → Network → Offline; sayfayı yenile; dashboard → hemogram listesi → ayarlar arasında gez.
- Expected: Çekirdek ekranlar önbellekten yüklenir; sadece ağ gerektiren aksiyonlarda yerelleştirilmiş çevrimdışı/bağlantı uyarıları görülür.
- Actual: DevTools Network ekranında core asset'ler (main.dart.js, canvaskit.wasm, ikonlar, manifest) ServiceWorker/disk cache tarafından karşılandı. Uygulama çevrimdışıyken kaynaklar yükleniyor; ekran içi gezinti doğrulaması bekleniyor.
- Result: Pass/Fail
- Notes:

### C3) Offline Data Changes
- Steps: Offline modda yeni hemogram ekle (veya su tüketimi değiştir); uygulamayı kapat; ağı geri aç; uygulamayı aç.
- Expected: Yerel değişiklik kuyruklanır; yeniden bağlanınca otomatik eşitlenir; yeni hemogram eklendiyse önceki aktif otomatik arşivlenir; yinelenen kayıt olmaz; yerelleştirilmiş başarı/çatışma durumları gösterilir.
- Actual:
- Result: Pass/Fail
- Notes:

### C4) Service Worker Verification
- Steps: Edge DevTools → Application → Service Workers; kayıtlı worker'ı ve cache içeriklerini incele.
- Expected: Tek aktif service worker vardır; önbellek main.dart.js, manifest ve ikonları içerir; bayat (stale) worker kalıntısı yoktur.
- Actual:
- Result: Pass/Fail
- Notes:

---

### D1) Keyboard Navigation
- Steps: Dashboard ve formlarda Tab/Shift+Tab ile tüm odaklanabilir öğeleri dolaş; ESC ile modalları kapat.
- Expected: Odak halkası görünür; odak sırası mantıklı; ESC modalları kapatır.
- Actual:
- Result: Pass/Fail
- Notes:

### D2) Screen Reader
- Steps: Windows Narrator'ı aç; dashboard ve hemogram giriş ekranındaki kontrolleri gez.
- Expected: Anlamlı, yerelleştirilmiş etiketler okunur; etiketsiz buton yok; ana/gezinti gibi semantik alanlar mevcut.
- Actual:
- Result: Pass/Fail
- Notes:

### D3) Contrast & Theming
- Steps: Ayarlardan açık/koyu tema arasında geçiş yap; birincil/ikincil/hata metinlerini her iki temada gözle.
- Expected: Metin okunabilirliği iyi; hedef kontrast oranı ≥ 4.5:1.
- Actual:
- Result: Pass/Fail
- Notes:

### D4) Text Scaling
- Steps: Windows Ayarları → Ekran → Ölçek %150; uygulamayı yeniden aç.
- Expected: Taşma/taşan metin yok; butonlar tıklanabilir kalır; yerelleştirilmiş uzun metinler kırpılmaz.
- Actual:
- Result: Pass/Fail
- Notes:

### D5) RTL & Localization
- Steps: Uygulama içinden Arapça (veya başka bir RTL) diline geç.
- Expected: Yön sağdan sola döner; listeler/sıralar doğru; karışık LTR parçalar görünmez; tüm metinler yerelleştirilmiş.
- Actual:
- Result: Pass/Fail
- Notes:

### D6) Forms & Validation
- Steps: Hemogram formunu eksik alanla ve aralık dışı değerle gönder; şifre değiştirmede zayıf şifre dene.
- Expected: Yerelleştirilmiş doğrulama mesajları; odak ilk hatalı alana döner; ham İngilizce metin gösterilmez.
- Actual:
- Result: Pass/Fail
- Notes:

---

## Issues Logged
- ID / Title / Area / Severity / Link
- 

## Conclusion
- Overall Status:
- Follow-ups:
