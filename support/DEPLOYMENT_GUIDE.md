# 🚀 HemoAI Support Page - Deployment Guide

## 📋 Önkoşullar

- GitHub hesabı (ücretsiz)
- Formspree hesabı (ücretsiz) veya alternatif form servisi

---

## 🎯 Adım 1: GitHub Repository Oluşturma

1. **GitHub'a giriş yapın:** https://github.com/login

2. **Yeni repository oluşturun:**
   - Sağ üstteki "+" butonuna tıklayın → "New repository"
   - **Repository name:** `hemoai-support`
   - **Description:** `HemoAI Support Page - Modern, responsive support page with 9-language support`
   - **Visibility:** ✅ Public (GitHub Pages için gerekli)
   - **Initialize:** ❌ README, .gitignore, license eklemeyin (dosyalar hazır)
   - **"Create repository"** tıklayın

---

## 🎯 Adım 2: Dosyaları Yükleme

### Seçenek 1: Web Arayüzü (Kolay)

1. Repository sayfasında **"uploading an existing file"** linkine tıklayın
2. `index.html` dosyasını sürükleyip bırakın
3. `README.md` dosyasını da ekleyin (opsiyonel)
4. **"Commit changes"** tıklayın

### Seçenek 2: Git Komutları (Geliştiriciler için)

```bash
cd support
git init
git add index.html README.md
git commit -m "Initial commit: HemoAI support page"
git branch -M main
git remote add origin https://github.com/meloshemo/hemoai-support.git
git push -u origin main
```

---

## 🎯 Adım 3: GitHub Pages'i Etkinleştirme

1. Repository sayfasında **"Settings"** sekmesine gidin

2. Sol menüden **"Pages"** seçin

3. **Source** bölümünde:
   - **Branch:** `main` (veya `master`)
   - **Folder:** `/ (root)`
   - **Save** tıklayın

4. Birkaç dakika bekleyin, GitHub Pages otomatik olarak deploy edecek

5. **URL'iniz hazır:**
   ```
   https://meloshemo.github.io/hemoai-support/
   ```

---

## 🎯 Adım 4: Formspree Kurulumu

### 4.1 Formspree Hesabı Oluşturma

1. **Formspree'e gidin:** https://formspree.io/accounts/signup
2. **Ücretsiz hesap oluşturun** (Google ile giriş yapabilirsiniz)
3. E-posta doğrulaması yapın

### 4.2 Yeni Form Oluşturma

1. **Dashboard'a gidin:** https://dashboard.formspree.io
2. **"New Form"** butonuna tıklayın
3. **Form bilgileri:**
   - **Form name:** `HemoAI Support`
   - **Email to receive submissions:** `support@hemoai.org`
   - **Form type:** `Contact Form`
   - **"Create Form"** tıklayın

4. **Form ID'yi kopyalayın:**
   - Form ID şu formatta: `xxxxxxxxxxxx` (12 karakter)
   - Bu ID'yi not edin

### 4.3 HTML'i Güncelleme

1. GitHub'da `index.html` dosyasını açın
2. **"Edit"** (kalem ikonu) tıklayın
3. Şu satırı bulun:
   ```html
   <form id="supportForm" action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
   ```
4. `YOUR_FORM_ID` yerine gerçek Form ID'nizi yazın:
   ```html
   <form id="supportForm" action="https://formspree.io/f/xxxxxxxxxxxx" method="POST">
   ```
5. **"Commit changes"** tıklayın

---

## 🎯 Adım 5: Test Etme

1. **Sayfayı ziyaret edin:**
   ```
   https://meloshemo.github.io/hemoai-support/
   ```

2. **Formu test edin:**
   - Tüm alanları doldurun
   - "Gönder" butonuna tıklayın
   - Başarı mesajını görün

3. **E-postanızı kontrol edin:**
   - `support@hemoai.org` adresine form gönderimi gelecek
   - Spam klasörünü de kontrol edin

---

## 🎯 Adım 6: Özel Domain (Opsiyonel)

Eğer `support.hemoai.app` gibi özel bir domain kullanmak isterseniz:

### 6.1 CNAME Dosyası Oluşturma

1. GitHub repository'de **"Add file"** → **"Create new file"** tıklayın
2. Dosya adı: `CNAME` (büyük harfle)
3. İçerik:
   ```
   support.hemoai.app
   ```
4. **"Commit new file"** tıklayın

### 6.2 DNS Yapılandırması

Domain sağlayıcınızda (ör. Namecheap, GoDaddy):

1. **DNS Ayarlarına** gidin
2. **CNAME kaydı** ekleyin:
   - **Host:** `support`
   - **Value:** `meloshemo.github.io`
   - **TTL:** 3600 (veya varsayılan)

3. **Kaydet** ve 24-48 saat bekleyin (DNS propagation)

4. **Test edin:**
   ```
   https://support.hemoai.app
   ```

---

## ✅ Deployment Checklist

- [ ] GitHub repository oluşturuldu
- [ ] `index.html` yüklendi
- [ ] GitHub Pages etkinleştirildi
- [ ] Formspree hesabı oluşturuldu
- [ ] Form ID HTML'e eklendi
- [ ] Test formu gönderildi
- [ ] E-posta alındı
- [ ] Tüm diller test edildi
- [ ] Dark mode test edildi
- [ ] Mobil görünüm test edildi
- [ ] (Opsiyonel) Özel domain yapılandırıldı

---

## 🔧 Sorun Giderme

### Form gönderilmiyor

1. **Form ID'yi kontrol edin:**
   - Formspree Dashboard → Form → Settings → Endpoint
   - HTML'deki action URL ile eşleşmeli

2. **Browser console'u kontrol edin:**
   - F12 → Console
   - Hata mesajlarını kontrol edin

3. **Formspree limitlerini kontrol edin:**
   - Ücretsiz plan: 50 form/ay
   - Limit aşıldıysa ücretli plana geçin

### Sayfa yüklenmiyor

1. **GitHub Pages ayarlarını kontrol edin:**
   - Repository → Settings → Pages
   - Branch ve folder doğru mu?

2. **Cache'i temizleyin:**
   - Ctrl+F5 (Windows) veya Cmd+Shift+R (Mac)

3. **URL'yi kontrol edin:**
   - `https://meloshemo.github.io/hemoai-support/` (doğru)
   - `https://meloshemo.github.io/hemoai-support/index.html` (da çalışır)

### E-posta gelmiyor

1. **Spam klasörünü kontrol edin**
2. **Formspree Dashboard → Submissions** kontrol edin
3. **E-posta adresini doğrulayın:** `support@hemoai.org`

---

## 📊 Analytics (Opsiyonel)

Eğer ziyaretçi sayısını takip etmek isterseniz:

### Google Analytics (Ücretsiz)

1. Google Analytics hesabı oluşturun
2. Tracking ID alın (örn: `G-XXXXXXXXXX`)
3. `index.html` içine `<head>` bölümüne ekleyin:
   ```html
   <!-- Google Analytics -->
   <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag(){dataLayer.push(arguments);}
     gtag('js', new Date());
     gtag('config', 'G-XXXXXXXXXX');
   </script>
   ```

**Not:** GDPR uyumluluğu için kullanıcıdan izin alınmalı (şu an eklenmemiş).

---

## 🎨 Özelleştirme

### Logo Ekleme

1. Logo dosyasını repository'ye yükleyin (örn: `logo.png`)
2. `index.html` içinde header'a ekleyin:
   ```html
   <img src="logo.png" alt="HemoAI Logo" style="max-width: 200px; margin-bottom: 20px;">
   ```

### Renkleri Değiştirme

`index.html` içindeki CSS variables'ı güncelleyin:
```css
:root {
    --primary-color: #E53E3E;  /* Ana renk */
    --primary-dark: #C53030;   /* Koyu ton */
    /* ... */
}
```

---

## 📞 Destek

Sorularınız için:
- **Email:** support@hemoai.org
- **Formspree:** https://help.formspree.io
- **GitHub Pages:** https://docs.github.com/pages

---

**Hazırlayan:** Auto (AI Assistant)  
**Tarih:** 2025  
**Versiyon:** 1.0

