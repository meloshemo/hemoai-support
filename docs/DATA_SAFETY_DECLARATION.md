# Google Play Data Safety Declaration for HemoAI

Use this when filling out the Data Safety section in Play Console.

---

## Overview
**App Category:** Medical / Health & Fitness
**Data Collection:** Minimal, user-controlled
**Default Behavior:** All data stored locally, no transmission

---

## Data Types Collected

### 1. Health & Fitness Data ✅ COLLECTED

**What:** Blood test results, medications, health metrics, diet tracking

**Purpose:**
- Provide health insights and analysis
- Generate personalized recommendations
- Track health trends over time

**How collected:** User manually enters data or uses OCR scanning

**Shared with:** NO ONE (stored locally only)

**Required:** NO (app works without, but analysis features need data)

**Encrypted in transit:** N/A (never transmitted)

**Encrypted at rest:** YES (device storage + AES-256 encrypted backups)

**Deletion:** Users can delete anytime via app settings

---

### 2. Personal Information ✅ COLLECTED

**What:** Age, gender, height, weight, BMI, profile name

**Purpose:**
- Personalized health calculations
- Contextual recommendations
- User experience optimization

**How collected:** User provides during onboarding or profile setup

**Shared with:** NO ONE

**Required:** NO (optional features)

**Encrypted in transit:** N/A

**Encrypted at rest:** YES

**Deletion:** Users can delete anytime

---

### 3. Photos & Videos ⚠️ COLLECTED (Optional)

**What:** Lab report images for OCR scanning

**Purpose:**
- Extract text from blood test reports
- Accelerate data entry
- Improve accuracy

**How collected:** Camera or photo library picker (permission-based)

**Shared with:** NO ONE

**Required:** NO (manual entry available)

**Encrypted in transit:** N/A

**Encrypted at rest:** YES (if stored in backups)

**Deletion:** Images processed on-device, not permanently stored

---

### 4. App Activity ⚠️ COLLECTED (Optional, Opt-in)

**What:** App usage patterns, feature analytics, crash reports

**Purpose:**
- Improve app stability
- Identify bugs
- Enhance user experience

**How collected:** Optional analytics service (disabled by default)

**Shared with:** Analytics provider (only if enabled)

**Required:** NO

**Encrypted in transit:** YES

**Encrypted at rest:** YES

**Deletion:** Users can disable anytime

---

### 5. Device or Other IDs ⚠️ COLLECTED (Optional)

**What:** Device ID for analytics (if enabled)

**Purpose:**
- Aggregate crash reporting
- Performance monitoring

**How collected:** Optional analytics (disabled by default)

**Shared with:** Analytics provider (only if enabled)

**Required:** NO

**Encrypted in transit:** YES

**Encrypted at rest:** YES

**Deletion:** Users can disable anytime

---

## Data NOT Collected

- ❌ Financial information
- ❌ Location data (GPS)
- ❌ Contacts
- ❌ SMS/Phone logs
- ❌ Email addresses (unless user exports reports)
- ❌ Social media data
- ❌ Files or documents (except OCR scans - temporary)

---

## Data Security Practices

### Encryption ✅
- **Data in transit:** TLS 1.3 when transmitting (cloud features)
- **Data at rest:** AES-256-GCM encryption for backups
- **Key derivation:** PBKDF2-HMAC-SHA256 (100,000 iterations)

### Secure Transmission ✅
- Health data only transmitted if user explicitly enables cloud backup
- All API calls use HTTPS/TLS
- No unencrypted endpoints

### User Control ✅
- Users can view, edit, delete all data
- Export functionality with encryption
- No automatic data collection
- Clear opt-in/opt-out for all features

---

## Data Sharing

### Shared with Third Parties? ❌ NO

**Answer:** Not shared with third parties by default.

**If cloud backup enabled (opt-in):**
- Encrypted data may be stored on Supabase servers
- Fully encrypted, we cannot read it
- User can delete at any time

### Government Requests 📋
- We have received zero requests
- We would comply with legal requirements
- We would notify users if possible and lawful

---

## Data Deletion

### How Users Can Delete ✅
1. **Individual records:** Delete any test result, medication, or reminder
2. **Bulk delete:** Settings → Clear All Data
3. **Export then delete:** Backup data before removal
4. **Uninstall:** App removal from device

### Automatic Deletion ❌
- No automatic deletion
- Data persists until user deletes

### Timeline ⏱️
- Immediate deletion for most data
- Cloud data deletion: within 30 days
- Backups: permanently encrypted, inaccessible without password

---

## Age Requirements

**Target Audience:** 18+ (adults)

**Why:** Handles medical/health information requiring adult decision-making

**COPPA Compliance:** Not applicable (no users under 13)

---

## Regional Compliance

### GDPR (EU) ✅
- Right to access: Users can export all data
- Right to rectification: Edit any information
- Right to erasure: Delete all data
- Right to restrict processing: Disable features
- Data portability: Export format
- Right to object: Opt-out of analytics

### California Consumer Privacy Act (CCPA) ✅
- Data categories disclosed
- No sale of personal information
- Right to delete
- Right to know

### Turkish KVKK (Veri Koruma Kanunu) ✅
- Personal data processed lawfully
- Specific purposes declared
- User consent obtained
- Secure storage implemented

---

## Play Console Form Answers

### Question: "Does your app collect or share any of the required user data types?"

**Answer:** ✅ Yes

### Question: "Does your app collect data from children?"

**Answer:** ❌ No (targets 18+)

### Question: "Is all the user data collected by your app encrypted in transit?"

**Answer:** ✅ Yes (N/A for local-only data)

### Question: "Do you provide a way for users to request deletion of their data?"

**Answer:** ✅ Yes

### Question: "Committed to Follow the Play Families Policy"

**Answer:** ✅ Yes (but app targets 18+)

---

## Additional Details for Google

### Data Type: Health & Fitness ✅
- Category: Medical information
- Sensitivity: High
- Regulation: Medical apps should comply with regional health data laws

### Data Type: Personal Information ✅
- Category: Optional profile data
- Sensitivity: Medium
- Required: No

### Security Practices Summary:
1. Local-first architecture
2. End-to-end encryption for backups
3. Minimal data collection
4. User-controlled sharing
5. Transparent privacy policy
6. No analytics by default
7. Secure authentication (optional biometrics)
8. Regular security updates

---

## Sample Response for "How is data used?"

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

## Common Questions

**Q: Do you sell user data?**
A: No, never. We don't sell, rent, or monetize user health data.

**Q: Can Google review your data?**
A: Google Play reviewers cannot access user health data. All data is locally encrypted or encrypted in transit.

**Q: Do you comply with HIPAA?**
A: While HemoAI is not a "covered entity" under HIPAA, we follow medical data security best practices including encryption, access controls, and audit logging.

**Q: What happens if app is deleted?**
A: Local data remains until manually cleared via device settings. Cloud data can be deleted via app.

---

## Review Checklist for Play Console

Before submitting Data Safety form:
- [x] All data types declared
- [x] Encryption practices stated
- [x] User deletion rights documented
- [x] Privacy policy URL provided
- [x] No data collection by default
- [x] Clear opt-in for optional features
- [x] Age restrictions noted (18+)
- [x] Regional compliance mentioned

---

## Resources

- [Google Play Data Safety Form](https://play.google.com/console/about/data-safety/)
- [GDPR Compliance Guidelines](https://gdpr.eu/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [Medical App Regulations](https://www.fda.gov/medical-devices/mobile-medical-applications)

---

## Contact for Data Requests

If users request data exports or deletions:
- Email: support@meloshemo.com
- Response time: Within 30 days (GDPR requirement)
- Format: JSON, PDF, or Excel based on request


