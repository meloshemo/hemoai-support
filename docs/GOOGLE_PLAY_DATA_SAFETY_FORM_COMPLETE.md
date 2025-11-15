# 📋 Google Play Data Safety Form - Tam Doldurulmuş Versiyon

**Uygulama:** HemoAI - Smart Hemogram Analysis & Health Tracking  
**Package ID:** `com.meloshemo.hemoai`  
**Versiyon:** 4.0.0+400  
**Tarih:** 2025-01-27  

---

## 🎯 FORM CEVAPLARI (Play Console'da Kullanılacak)

### 1. Does your app collect or share any of the required user data types?

**Cevap:** ✅ **YES**

**Açıklama:** Uygulama kullanıcı sağlık verilerini, kişisel bilgileri ve opsiyonel olarak fotoğrafları toplar. Tüm veriler yerel olarak saklanır ve varsayılan olarak paylaşılmaz.

---

### 2. Data Types Collected

#### A. Health & Fitness ✅ COLLECTED

**What data is collected?**
- Blood test results (hemogram values)
- Medications and dosages
- Health metrics (BMI, weight, height)
- Diet tracking data
- Reminder schedules
- Family member health data (if user enables family features)

**Why is this data collected?**
- Provide AI-powered health insights and analysis
- Generate personalized diet and lifestyle recommendations
- Track health trends over time
- Enable medication and appointment reminders
- Support family health management features

**How is this data collected?**
- User manually enters data through app interface
- OCR scanning of lab reports (optional, on-device processing)
- Import from backup files (user-initiated)

**Is this data shared?** ❌ **NO**
- Data is stored locally on device only
- Not shared with third parties
- Not shared with Google or other services
- Only shared if user explicitly enables cloud backup (opt-in feature)

**Is collection of this data required?** ❌ **NO**
- App works without health data, but analysis features require data
- Users can use app in guest mode without providing health data

**Is this data encrypted in transit?** ✅ **YES** (N/A for local-only data)
- When cloud backup is enabled (opt-in), data is encrypted with TLS 1.3
- Local data never transmitted unless user enables cloud backup

**Is this data encrypted at rest?** ✅ **YES**
- Local database encrypted with device security
- Backup files encrypted with AES-256-GCM
- Key derivation: PBKDF2-HMAC-SHA256 (100,000 iterations)

**Can users request deletion?** ✅ **YES**
- Users can delete individual records anytime
- Settings → Clear All Data for bulk deletion
- Cloud data deletion: within 30 days
- Immediate deletion for local data

---

#### B. Personal Information ✅ COLLECTED

**What data is collected?**
- Name (profile name, not real name required)
- Age
- Gender
- Height and weight (for BMI calculation)
- Email address (optional, for support/backup)
- Phone number (optional, for family invitations)

**Why is this data collected?**
- Personalized health calculations (BMI, age-appropriate ranges)
- Contextual health recommendations
- User experience optimization
- Support communication (if user provides email)
- Family member invitations (if user enables family features)

**How is this data collected?**
- User provides during onboarding or profile setup
- Optional fields can be skipped

**Is this data shared?** ❌ **NO**
- Stored locally only
- Email/phone stored in secure storage (encrypted)
- Not shared with third parties

**Is collection of this data required?** ❌ **NO**
- Most fields are optional
- App works with minimal information

**Is this data encrypted in transit?** ✅ **YES** (N/A for local-only)
**Is this data encrypted at rest?** ✅ **YES**
- Sensitive fields (email, phone) in Flutter Secure Storage
- Other fields in encrypted local database

**Can users request deletion?** ✅ **YES**
- Delete anytime via Settings
- Immediate deletion

---

#### C. Photos & Videos ⚠️ COLLECTED (Optional)

**What data is collected?**
- Lab report images (for OCR text extraction)
- Profile photos (optional)

**Why is this data collected?**
- Extract text from blood test reports using on-device OCR
- Accelerate data entry
- Improve accuracy of manual entry
- Personalize user experience (profile photo)

**How is this data collected?**
- Camera permission (for taking photos)
- Photo library permission (for selecting images)
- User explicitly chooses to use OCR feature

**Is this data shared?** ❌ **NO**
- Images processed on-device only
- OCR results stored, images not permanently stored
- Not shared with third parties

**Is collection of this data required?** ❌ **NO**
- OCR is optional feature
- Users can manually enter data instead

**Is this data encrypted in transit?** ✅ **YES** (N/A - not transmitted)
**Is this data encrypted at rest?** ✅ **YES** (if stored in encrypted backups)

**Can users request deletion?** ✅ **YES**
- Images not permanently stored (processed and discarded)
- OCR results can be deleted like other health data

---

#### D. App Activity ⚠️ COLLECTED (Optional, Opt-in)

**What data is collected?**
- App usage patterns (screen views)
- Feature usage analytics
- Crash reports and error logs
- Performance metrics

**Why is this data collected?**
- Improve app stability and fix bugs
- Enhance user experience
- Identify popular features
- Optimize performance

**How is this data collected?**
- Optional analytics service (disabled by default)
- User must explicitly opt-in via Settings
- Local logging only (no network calls by default)

**Is this data shared?** ⚠️ **ONLY IF OPTED-IN**
- Default: Not shared (analytics disabled)
- If user opts-in: May be shared with analytics provider (Firebase, if configured)
- Always anonymized, no PII

**Is collection of this data required?** ❌ **NO**
- Disabled by default
- User can opt-out anytime

**Is this data encrypted in transit?** ✅ **YES** (if shared)
**Is this data encrypted at rest?** ✅ **YES**

**Can users request deletion?** ✅ **YES**
- Disable analytics anytime in Settings
- Immediate effect

---

#### E. Device or Other IDs ⚠️ COLLECTED (Optional)

**What data is collected?**
- Device ID (for analytics, if enabled)
- Installation ID (for app functionality)

**Why is this data collected?**
- Aggregate crash reporting (if analytics enabled)
- Performance monitoring
- App functionality (installation tracking)

**How is this data collected?**
- System-provided device identifiers
- Only used if analytics is opted-in

**Is this data shared?** ⚠️ **ONLY IF ANALYTICS OPTED-IN**
- Default: Not shared
- If analytics enabled: May be shared with analytics provider

**Is collection of this data required?** ❌ **NO**
- Only collected if user opts-in to analytics

**Is this data encrypted in transit?** ✅ **YES**
**Is this data encrypted at rest?** ✅ **YES**

**Can users request deletion?** ✅ **YES**
- Disable analytics to stop collection

---

### 3. Data NOT Collected ❌

Uygulama şu veri tiplerini **TOPLAMAZ**:

- ❌ Financial information (credit cards, bank accounts)
- ❌ Location data (GPS coordinates)
- ❌ Contacts (except for family invitations - user selects manually)
- ❌ SMS or call logs
- ❌ Email content (except user-provided email for support)
- ❌ Social media data
- ❌ Biometric data (except optional Face ID/Touch ID for app lock)
- ❌ Audio recordings
- ❌ Calendar events (except user-created reminders)

---

### 4. Data Sharing

#### Does your app share data with third parties?

**Cevap:** ⚠️ **ONLY IF USER OPTS-IN TO CLOUD BACKUP**

**Default:** ❌ **NO** - Data is not shared

**If cloud backup enabled (opt-in):**
- Encrypted data may be stored on Supabase servers
- Data is end-to-end encrypted (we cannot read it)
- User can delete at any time
- User controls what is backed up

#### Government Requests

**Have you received any government requests for user data?**
- ❌ **NO** - Zero requests received

**What would you do if you received a request?**
- Comply with legal requirements
- Notify users if possible and lawful
- Provide only data we can access (we cannot decrypt user backups)

---

### 5. Data Security

#### Security Practices ✅

1. **Encryption:**
   - Data in transit: TLS 1.3 (when cloud backup enabled)
   - Data at rest: AES-256-GCM encryption for backups
   - Key derivation: PBKDF2-HMAC-SHA256 (100,000 iterations)

2. **Secure Storage:**
   - Sensitive data (email, phone) in Flutter Secure Storage
   - Health data in encrypted SQLite database
   - Backup files encrypted with user-provided password

3. **Access Controls:**
   - Optional biometric authentication (Face ID/Touch ID)
   - No automatic data collection
   - User-controlled sharing

4. **Privacy by Design:**
   - Local-first architecture
   - Minimal data collection
   - Opt-in for all optional features
   - Transparent privacy policy

---

### 6. Data Deletion

#### How Users Can Delete Data ✅

1. **Individual Records:**
   - Delete any test result, medication, or reminder from respective screens
   - Immediate deletion

2. **Bulk Delete:**
   - Settings → Clear All Data
   - Removes all local data
   - Immediate effect

3. **Export then Delete:**
   - Users can export data before deletion
   - Settings → Export Data

4. **Uninstall:**
   - Removing app from device
   - Local data removed (device-dependent)

5. **Cloud Data:**
   - Delete via app settings
   - Deletion within 30 days
   - User can request immediate deletion via support email

#### Timeline ⏱️

- **Local data:** Immediate deletion
- **Cloud data:** Within 30 days
- **Backups:** Permanently encrypted, inaccessible without password

---

### 7. Age Requirements

#### Does your app collect data from children?

**Cevap:** ❌ **NO**

**Target Audience:** 18+ (adults)

**Why:** 
- Handles medical/health information requiring adult decision-making
- Health data analysis requires mature judgment
- Not designed for children

**COPPA Compliance:** Not applicable (no users under 13)

---

### 8. Regional Compliance

#### GDPR (EU) ✅

- ✅ Right to access: Users can export all data
- ✅ Right to rectification: Edit any information
- ✅ Right to erasure: Delete all data
- ✅ Right to restrict processing: Disable features
- ✅ Data portability: Export in JSON/PDF/Excel
- ✅ Right to object: Opt-out of analytics

#### California Consumer Privacy Act (CCPA) ✅

- ✅ Data categories disclosed
- ✅ No sale of personal information
- ✅ Right to delete
- ✅ Right to know

#### Turkish KVKK (Veri Koruma Kanunu) ✅

- ✅ Personal data processed lawfully
- ✅ Specific purposes declared
- ✅ User consent obtained
- ✅ Secure storage implemented

---

## 📝 PLAY CONSOLE FORM ADIM ADIM

### Adım 1: Data Collection Overview

**Question:** "Does your app collect or share any of the required user data types?"

**Answer:** ✅ **YES**

**Reason:** App collects health data, personal information, and optionally photos for OCR.

---

### Adım 2: Data Types

Her veri tipi için yukarıdaki detaylı açıklamaları kullanın.

**Önemli Noktalar:**
- Health & Fitness: ✅ Collected, ❌ Not Shared, ❌ Not Required
- Personal Information: ✅ Collected, ❌ Not Shared, ❌ Not Required  
- Photos: ⚠️ Collected (Optional), ❌ Not Shared, ❌ Not Required
- App Activity: ⚠️ Collected (Opt-in), ⚠️ Shared (if opted-in), ❌ Not Required
- Device IDs: ⚠️ Collected (Opt-in), ⚠️ Shared (if opted-in), ❌ Not Required

---

### Adım 3: Data Sharing

**Question:** "Does your app share data with third parties?"

**Answer:** ⚠️ **ONLY IF USER OPTS-IN**

**Details:**
- Default: No sharing
- If cloud backup enabled: Encrypted data stored on Supabase
- Analytics (if opted-in): May share with Firebase (anonymized)

---

### Adım 4: Security Practices

**Question:** "Is all the user data collected by your app encrypted in transit?"

**Answer:** ✅ **YES**

**Details:**
- TLS 1.3 for cloud backup (if enabled)
- N/A for local-only data (never transmitted)

**Question:** "Is all the user data collected by your app encrypted at rest?"

**Answer:** ✅ **YES**

**Details:**
- AES-256-GCM for backups
- Device security for local database
- Flutter Secure Storage for sensitive fields

---

### Adım 5: Data Deletion

**Question:** "Do you provide a way for users to request deletion of their data?"

**Answer:** ✅ **YES**

**Details:**
- Settings → Clear All Data
- Individual record deletion
- Cloud data deletion within 30 days
- Support email for requests: support@hemoai.org

---

### Adım 6: Age Requirements

**Question:** "Does your app collect data from children?"

**Answer:** ❌ **NO**

**Details:**
- Target audience: 18+
- COPPA not applicable

---

### Adım 7: Committed to Follow Play Families Policy

**Answer:** ✅ **YES**

**Note:** App targets 18+ but commits to family safety standards.

---

## 🔗 GEREKLİ URL'LER

**Privacy Policy URL:**
```
https://meloshemo.github.io
```

**Support URL:**
```
https://meloshemo.github.io/hemoai-support
```

**Email for Data Requests:**
```
support@hemoai.org
```

---

## ✅ FORM GÖNDERME ÖNCESİ KONTROL LİSTESİ

- [x] Tüm veri tipleri tanımlandı
- [x] Şifreleme uygulamaları belirtildi
- [x] Kullanıcı silme hakları dokümante edildi
- [x] Privacy Policy URL sağlandı
- [x] Varsayılan olarak veri toplama yok
- [x] Opsiyonel özellikler için açık opt-in
- [x] Yaş kısıtlamaları belirtildi (18+)
- [x] Bölgesel uyumluluk (GDPR, CCPA, KVKK) belirtildi
- [x] Veri paylaşımı politikası açıklandı
- [x] Güvenlik uygulamaları detaylandırıldı

---

## 📌 ÖNEMLİ NOTLAR

1. **Privacy-First Yaklaşım:**
   - Varsayılan olarak hiçbir veri toplanmaz veya paylaşılmaz
   - Tüm opsiyonel özellikler için açık opt-in gerekir
   - Kullanıcılar istedikleri zaman opt-out yapabilir

2. **Local-First Architecture:**
   - Tüm veriler varsayılan olarak yerel cihazda saklanır
   - Cloud backup tamamen opsiyonel ve kullanıcı kontrolündedir

3. **Transparency:**
   - Privacy Policy'de tüm veri kullanımları açıkça belirtilmiştir
   - Kullanıcılar verilerinin nasıl kullanıldığını görebilir

4. **User Control:**
   - Kullanıcılar tüm verilerini silebilir
   - Export özelliği ile veri taşınabilirliği sağlanır
   - Analytics ve cloud backup tamamen kullanıcı kontrolündedir

---

## 🎯 FORM DOLDURMA İPUÇLARI

1. **Detaylı Açıklamalar:**
   - Her veri tipi için "Why" kısmını detaylı doldurun
   - Kullanıcı deneyimini iyileştirme amaçlarını belirtin

2. **Güvenlik:**
   - Şifreleme uygulamalarınızı vurgulayın
   - Local-first yaklaşımınızı belirtin

3. **Kullanıcı Kontrolü:**
   - Opt-in/opt-out mekanizmalarınızı açıklayın
   - Silme haklarını vurgulayın

4. **Compliance:**
   - GDPR, CCPA, KVKK uyumluluğunuzu belirtin
   - Privacy Policy URL'inizi doğru girin

---

## 📞 DESTEK

Form doldurma sırasında sorularınız için:
- **Email:** support@hemoai.org
- **Privacy Policy:** https://meloshemo.github.io
- **Support Portal:** https://meloshemo.github.io/hemoai-support

---

**Son Güncelleme:** 2025-01-27  
**Durum:** ✅ Form için hazır, Play Console'a girilebilir
