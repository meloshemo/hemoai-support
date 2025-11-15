# HemoAI Privacy, Security & Regulatory Compliance Playbook

_Last updated: 2025-11-10_

---

## 1. Executive Summary
- **Purpose:** Ensure lawful, ethical and secure processing of hemogram and wellness data across Turkey, the EU and the US.
- **Regimes covered:** KVKK (Turkey), GDPR (EU/EEA), HIPAA (US – wellness scenario; only applies if we act as a covered entity/business associate).
- **Data classification:** All hemogram readings, diagnoses, diet programs and notification logs are **Special Category / Sensitive Health Data**.
- **Risk appetite:** Zero tolerance for uncontrolled disclosure or processing without explicit consent. Continuous monitoring and encryption mandatory.

---

## 2. Data Inventory & Processing Map
| Data Asset | Source | Storage | Purpose | Retention | Legal Basis |
|------------|--------|---------|---------|-----------|-------------|
| Hemogram metrics, physician notes | User entry / import (OCR) | Device SQLite (encrypted), optional Firestore (encrypted at rest) | Generate personalised diet plans & wellness alerts | Active subscription + 24 months (unless user requests deletion) | Explicit consent (KVKK Art.6/2), GDPR Art.9(2)(a) |
| Wellness goals, reminders, hydration data | User entry | Device SQLite (encrypted) | Habit tracking, recommendations | Until user deletes or 12 months inactivity | Legitimate interest + consent |
| Email + push tokens | User onboarding | Firebase Auth, FCM | Authentication, notification delivery | Active use + 12 months | Contract performance |
| AI insight logs | In-app only (no remote storage) | Local encrypted cache (max 30 days) | Debug insight accuracy | Legitimate interest; anonymise where possible |
| Analytics events | Firebase Analytics (only after opt-in) | Google servers (EU data residency toggle) | Product improvement | 14 months (configurable) | Consent (opt-in toggle) |

> **Action:** Keep the table up to date in `/docs/data_inventory.xlsx` (create if absent) and share with the DPO.

---

## 3. Regulatory Requirements Checklist

### 3.1 KVKK (Turkey)
1. **Explicit consent** before collecting any health data (Art.6).  
2. **Data minimisation & purpose limitation** (Art.4).  
3. **Data subject rights:** access, correction, deletion within 30 days.  
4. **Data controller obligations:** keep _Veri Sorumluları Sicil Bilgi Sistemi (VERBIS)_ registration current if thresholds met.  
5. **Cross-border transfer:** either user consent or ensure adequate safeguards (Standard Contractual Clauses).  
6. **Breach notification:** inform KVKK Authority and data subjects within 72 hours.

### 3.2 GDPR (EU)
1. **Art.6 & Art.9 lawful basis:** explicit consent for special category data.  
2. **Data Protection Impact Assessment (DPIA)** for high-risk processing.  
3. **Records of Processing Activities (RoPA)** maintained.  
4. **Data Processing Agreements** with Firebase (Google), SendGrid (Twilio) referencing SCCs.  
5. **Data subject requests** fulfilled within 30 days (extendable to 60).  
6. **Security:** encryption, pseudonymisation, access controls (Art.32).  
7. **International transfers:** rely on SCCs + Transfer Impact Assessment.  
8. **Breach notification:** supervisory authority within 72 hours; affected users without undue delay.

### 3.3 HIPAA (if applicable)
1. Determine whether HemoAI is a **Business Associate** (serving clinics) or direct-to-consumer (potentially non-covered).  
2. When acting under HIPAA scope: execute **Business Associate Agreements (BAA)** with covered entities and vendors (Firebase BAAs available via Google Cloud, SendGrid requires Twilio BAA).  
3. Implement **Administrative, Technical, Physical safeguards**: access logging, role-based access, workstation security.  
4. Maintain **Policies & Procedures** and annual risk analysis.  
5. **Breach notification** in line with 45 CFR §164.400–414 (≤60 days).

---

## 4. Consent & User Experience Requirements
1. **Onboarding Consent Flow**
   - Step 1: Display concise notice of data categories, purposes, storage locations.  
   - Step 2: Provide toggle buttons for:
     - Health data processing (mandatory for functionality).  
     - Email notifications (optional).  
     - Analytics/Crash diagnostics (optional).  
   - Step 3: Link to full Privacy Policy, Terms of Service, KVKK/GDPR rights page.
   - Step 4: Persist consent flags in secure local storage + Firestore `consent_records` (timestamp, version, locale).
2. **Consent Withdrawal**
   - Offer in-app screen under `Settings > Privacy` with toggles and delete account option.  
   - On withdrawal, revoke analytics, stop SendGrid triggers, queue data deletion job.
3. **Document templates**
   - `/legal/privacy_policy_<lang>.md`  
   - `/legal/terms_of_service_<lang>.md`  
   - `/legal/data_processing_addendum.md`

---

## 5. Security Controls

### 5.1 Encryption
| Layer | Current State | Required Actions |
|-------|---------------|------------------|
| Device storage (SQLite, Hive) | App uses `encrypt` library; confirm AES-256-GCM with per-user key derived from secure storage. | Audit `PreferencesService.ensurePiiSecured()` and `DatabaseHelper`. Implement key rotation policy and PBKDF2 iterations ≥100k. |
| Firestore / Firebase | Google-managed AES-256 at rest, TLS in transit. | Enforce **end-to-end encryption** for particularly sensitive fields using `firestore_encryption.dart`. Store keys in Firebase KMS or Supabase Vault. |
| SendGrid | TLS enforced during SMTP/API. | Ensure templates do not contain raw medical data; only anonymised summaries. |
| Backups | AutoBackupService (local). | Encrypt backup files with user-provided passphrase; store in `SecureStorage`. |

### 5.2 Access Management
- Restrict Firebase project roles: developers → least privilege IAM roles, production Firestore read/write via service accounts.
- Implement admin dashboard with multi-factor authentication (if built).
- Maintain access log `/logs/access_audit.log`, rotate monthly.

### 5.3 Network & API Security
- All HTTP calls enforce HTTPS with certificate pinning where possible (Dio interceptors).
- Implement rate limiting on Firebase Functions (via `functions.runWith({timeoutSeconds, memory, invocationsPerToken})` or Cloud Armor).
- Validate all client payloads using schemas and reject excess fields.

### 5.4 Monitoring & Incident Response
- Enable Firebase Security Rules logging.  
- Configure Cloud Logging alert when rules deny >100 requests/hour.  
- Incident Runbook: `/docs/incident_response_runbook.md` (to create) with triage matrix, communication tree, regulatory timelines.

---

## 6. Data Subject Rights (DSR) Handling
| Request Type | Workflow | SLA |
|--------------|----------|-----|
| Access | Generate export via Firebase Functions → zip (JSON + CSV) → secure download link, log action. | ≤30 days |
| Rectification | Allow manual edit in app; log change metadata. | Immediate |
| Erasure | Trigger `deleteAccount` function → remove Firestore docs, SendGrid marketing lists, Stripe customer, cached device DB. | ≤30 days (KVKK/GDPR) |
| Restrict processing | Toggle flag in Firestore `users.status = paused`; halt AI plan generation & emails. | ≤3 days |
| Portability | Produce machine-readable JSON/CSV dataset covering hemogram history, diet plans. | ≤30 days |

Maintain request log `/docs/dsr_register.xlsx`, capturing requester identity verification steps.

---

## 7. Vendor Management
| Vendor | Role | Agreement | Actions |
|--------|------|-----------|--------|
| Google Firebase | Hosting, Auth, Analytics | Google Data Processing Terms + SCCs (auto) | Activate EU data residency (if on Firebase Enterprise). Sign optional BAA if HIPAA scope. |
| Twilio SendGrid | Transactional email | Twilio DPA + SCC | Restrict templates; enable 2FA; rotate API keys quarterly. |
| Stripe | Payments | Stripe Services Agreement + DPA | Tokenise card data (Stripe handles PCI). Ensure webhooks signed. |
| Supabase (future) | Sync/backup | Supabase DPA | Evaluate before production. |

Keep vendor risk assessments in `/docs/vendor_assessments/`.

---

## 8. Documentation & Training
- Appoint **Data Protection Officer (DPO)** or privacy lead.
- Conduct annual security awareness training for engineers & support staff; record attendance.
- Maintain change log of privacy policy versions.
- Schedule quarterly compliance reviews (include penetration testing, vulnerability scanning).

---

## 9. Implementation Backlog
1. Build `PrivacyConsentScreen` (Flutter) with multilingual copy; integrate with onboarding.
2. Extend `PreferencesService` to persist consent & encryption keys (PBKDF2 + SecureStorage).
3. Create `consent_records` collection in Firestore with Cloud Functions enforcement.
4. Implement data export/delete endpoints in `functions/index.js`.
5. Add `privacy_policy_tr.md/en.md/de.md` etc. to `/legal/`.
6. Write Cloud Security Rules to restrict hemogram access per user.
7. Automate backups with encryption (Google Cloud KMS).
8. Draft DPIA template in `/docs/dpia_template.docx`.
9. Configure monitoring alerts (Firebase, Google Cloud Logging).
10. Prepare incident response tabletop exercise.

---

## 10. Compliance Timeline (Suggested)
| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 0 (Week 0) | Current | Publish this playbook; assign DPO. |
| Phase 1 (Weeks 1-4) | | Consent UX, legal documents, encryption review, vendor DPAs. |
| Phase 2 (Weeks 5-8) | | Data export/delete automation, monitoring, incident runbook. |
| Phase 3 (Weeks 9-12) | | DPIA completion, penetration test, audit readiness review. |

---

## 11. Audit Readiness Checklist
- [ ] Privacy Policy & Terms published for every supported language.  
- [ ] Consent records stored with timestamp + version.  
- [ ] Encryption keys documented & rotated.  
- [ ] Access logs retained ≥12 months.  
- [ ] DSR processes tested quarterly.  
- [ ] Vendor DPAs and SCCs stored in `/legal/vendor-agreements/`.  
- [ ] Incident response drill completed in last 12 months.  
- [ ] DPIA reviewed & signed by DPO.  
- [ ] VERBIS registration submitted (if thresholds met).  
- [ ] HIPAA scope decision documented.

---

## 12. References & Resources
- KVKK Law No. 6698 (Kişisel Verilerin Korunması Kanunu)  
- GDPR (Regulation (EU) 2016/679)  
- HIPAA Security Rule (45 CFR Part 164 Subpart C)  
- Google Cloud & Firebase Privacy Resources  
- Twilio SendGrid DPA & Security FAQs  
- ENISA recommendations for health data security

---

**Owner:** Privacy & Security Lead  
**Distribution:** Founders, Engineering Lead, Legal Counsel, DPO  
**Confidentiality:** Internal use only (do not distribute externally)


