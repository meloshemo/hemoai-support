# HemoAI Data Inventory & Processing Register

_Last reviewed: 2025-11-10_

This register maps every data element processed by HemoAI to its source, storage location, purpose, retention schedule and legal basis. Keep it synchronized with the product as features evolve. Update the “Last reviewed” header whenever changes are made.

## 1. Summary
- **Data Protection Officer / Owner:** _Assign name & contact_
- **Review cadence:** Quarterly (at minimum)
- **Systems covered:** Flutter mobile apps, Firebase backend (Auth, Firestore, Functions), SendGrid, Stripe

## 2. Inventory Table

> Export this table to CSV/XLSX if regulators request a machine-readable record.

| ID | Data Category | Fields / Examples | Source | Storage / Location | Purpose | Sharing / Recipients | Retention | Legal Basis |
|----|---------------|-------------------|--------|--------------------|---------|----------------------|-----------|-------------|
| DI-001 | Hemogram readings | Hb, Hct, RBC, WBC, notes | User manually enters; OCR import | Local encrypted SQLite; optional encrypted Firestore | Generate AI diet insights, trends | None (user only) | Subscription duration + 24 months or user deletion | Explicit consent (KVKK Art.6/2, GDPR Art.9(2)(a)) |
| DI-002 | Health profile | Age, sex, chronic conditions, medications | Onboarding form | Local encrypted storage; Firestore profile doc | Personalisation, risk stratification | None | Until account deletion | Explicit consent |
| DI-003 | Diet & hydration logs | Meals, hydration targets, mindfulness notes | Daily tracking UI | Local encrypted storage | Progress tracking | None | 12 months inactivity or user deletion | Legitimate interest + consent |
| DI-004 | Account identifiers | Email, UID, auth tokens | Registration | Firebase Auth (EU region), SecureStorage | Authentication, support | Firebase services | Until account deletion | Contract necessity |
| DI-005 | Notifications | Reminder schedules, token IDs | User preference | Firebase Cloud Messaging, Local database | Deliver reminders | Firebase Cloud Messaging | Until user disables reminders | Consent |
| DI-006 | Transaction metadata | Stripe customer ID, plan type | Checkout | Stripe, Firestore subscription doc | Billing, receipts | Stripe, SendGrid (receipt email) | 10 years (tax) | Legal obligation |
| DI-007 | Analytics events (opt-in) | Screen_views, button taps (no PII) | In-app telemetry | Firebase Analytics | Product improvement | Google Firebase | 14 months (default) | Consent |
| DI-008 | Support interactions | Tickets, email thread | Support inbox | Helpdesk tool (TBD) | Customer support | Support vendors | 24 months | Legitimate interest |

_Add new rows for every additional feature or third-party integration._

## 3. Data Flow Diagram (Narrative)
1. **Capture:** User enters hemogram values → encrypted locally (per-user key).  
2. **Optional sync:** If cloud backup enabled, data is encrypted client-side and uploaded to Firestore (`user_data/{uid}/hemogram`).  
3. **Processing:** AI diet service reads local dataset, generates insights (no external APIs).  
4. **Notifications:** Reminder settings stored locally; device token stored in Firestore for push triggers.  
5. **Emails:** Transactional events call Firebase Functions → SendGrid with minimal data (no raw lab values).  
6. **Payments:** Checkout data sent to Stripe; webhook updates Firestore with subscription status.

## 4. Cross-Border Transfer Assessment
- **Firebase:** Default US/EU infrastructure. Activate EU data residency if available; otherwise rely on SCCs.  
- **SendGrid:** US-based; rely on SCCs + Transfer Impact Assessment.  
- **Stripe:** Compliant with GDPR/SCC; confirm data center region configuration.  
- Record decisions and safeguards in `/docs/vendor_assessments/`.

## 5. Retention & Deletion Matrix
| Data Category | Retention Trigger | Deletion Method |
|---------------|-------------------|-----------------|
| Hemogram data | User deletion request OR 24 months after account inactivity | Remove local DB, call Firestore batch delete, purge backups |
| Sync backups | 30 days rolling | Cloud scheduler job purges old encrypted blobs |
| Analytics | 14-month retention toggle | Configure in Firebase console |
| Transaction records | 10 years | Stripe handles; remove app-level copies after 10 years |

## 6. Change Log
| Date | Author | Summary |
|------|--------|---------|
| 2025-11-10 | _Assistant placeholder_ | Initial register created |

Please replace placeholders with actual names and keep signatures for auditors.***

