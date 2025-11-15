# Compliance Action Plan – Q4 2025

_Last updated: 2025-11-10_

This checklist operationalises the privacy/security commitments described in `privacy_compliance_plan.md`. Update statuses weekly during stand-up.

## 1. Consent & UX
| Task | Owner | Deadline | Status | Notes |
|------|-------|----------|--------|-------|
| Design multilingual privacy consent screen (opt-ins, legal notices) | Product Design | 2025-11-24 | ☐ | Use copy from legal docs |
| Implement `PrivacyConsentScreen` in Flutter | Mobile Team | 2025-12-01 | ☐ | Persist flags in SecureStorage + Firestore |
| Build `Settings > Privacy` management page (withdraw consent, delete account) | Mobile Team | 2025-12-08 | ☐ | Integrate with Functions |

## 2. Encryption & Security
| Task | Owner | Deadline | Status | Notes |
|------|-------|----------|--------|-------|
| Audit local DB encryption (AES mode, key rotation) | Security Lead | 2025-11-17 | ☐ | Document in security wiki |
| Implement client-side encryption for Firestore sync | Backend | 2025-12-05 | ☐ | Use `firestore_encryption.dart` helpers |
| Secure backup flow (encrypted ZIP, passphrase) | Mobile Team | 2025-12-05 | ☐ | Update AutoBackupService |

## 3. Data Subject Rights (DSR)
| Task | Owner | Deadline | Status | Notes |
|------|-------|----------|--------|-------|
| Implement `/exportData` Cloud Function | Backend | 2025-11-30 | ☐ | Generates ZIP, time-limited URL |
| Implement `/deleteAccount` Cloud Function workflow | Backend | 2025-11-30 | ☐ | Cascade deletes Firestore, SendGrid, Stripe |
| Create DSR request intake form (internal + public) | Support | 2025-11-20 | ☐ | Link to knowledge base |

## 4. Vendor & Legal
| Task | Owner | Deadline | Status | Notes |
|------|-------|----------|--------|-------|
| Execute DPAs / SCCs (Firebase, SendGrid, Stripe) | Legal | 2025-11-18 | ☐ | Store in `/legal/vendor-agreements/` |
| Evaluate HIPAA applicability & BAA requirements | Legal + Product | 2025-11-25 | ☐ | Document decision in DPIA |
| File VERBIS registration (if thresholds met) | Legal | 2025-12-15 | ☐ | Provide registration number |

## 5. Documentation & Training
| Task | Owner | Deadline | Status | Notes |
|------|-------|----------|--------|-------|
| Publish privacy policy (EN/TR/DE) on website/app | Marketing | 2025-11-22 | ☐ | Include last updated date |
| Draft Terms of Service update | Legal | 2025-11-22 | ☐ | Align with privacy commitments |
| Schedule quarterly compliance review meeting | DPO | 2025-11-15 | ☐ | Add to company calendar |
| Plan incident response tabletop exercise | Security Lead | 2025-12-10 | ☐ | Use runbook scenario |

Use ☑ when completed and keep the document under version control for audit trail.***

