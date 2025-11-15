# Compliance & Data Governance Checklist

_Last updated: 2025-11-11_

## 1. Data Processing Inventory

| Data Category | Source | Purpose | Storage | Retention | Notes |
| --- | --- | --- | --- | --- | --- |
| Account profile (name, email, phone) | User input (mobile/web) | Account access, personalization | Secure SQLite (device), Supabase (cloud) | Until account deletion | Email optional for OTP |
| Hemogram & wellness metrics | Manual entry, OCR, import | Analytics, recommendations | SQLite, Supabase | 36 months (default) | Users can export/delete |
| Medical consent status | In-app consent dialog | Legal requirement | SharedPreferences | Until account deletion | `medical_consent.json` removed when deleting user |
| Notification preferences | Settings screen | Reminders, engagement | SharedPreferences | Until user reset/deletion | Includes snooze/dnd |
| Payment metadata | Stripe / platform IAP | Premium access reconciliation | Supabase | 7 years (tax compliance) | No card data stored locally |
| Crash & analytics events | Firebase Crashlytics/Performance | Reliability & performance | Google Cloud (region EU) | 24 months | Anonymised identifiers only |

## 2. User Rights & Deletion Flow

| Right | Status | Implementation |
| --- | --- | --- |
| Access | ✅ | Export via `Settings → Data & Privacy → Export data` (CSV/JSON) |
| Rectification | ✅ | Users can edit profile & health entries |
| Erasure | ✅ | `Settings → Data & Privacy → Delete account` triggers `PreferencesService.deleteAll()` and Supabase row purge (script `tool/delete_user_records.mjs`) |
| Restrict processing | 🚧 | Toggle for analytics to be exposed (`enhanced_analytics_service` flag ready) |
| Data portability | ✅ | Exports zipped JSON + PDF summary |

> Action: expose analytics opt-out toggle in `settings_screen.dart` before store release.

## 3. Logging & Retention

- **App logs**: stored in-memory only, optional export for support (user initiated).
- **Crash logs**: Crashlytics retention 24 ay, PII yok.
- **Audit logs** (`audit_log_service.dart`): Supabase'te 12 ay saklanır, otomatik TTL job ayarlı.
- **Backup exports**: `backup_service` dosyaları cihazda 30 gün sonra otomatik silinir (WorkManager planı).

## 4. Documentation & Links

- Privacy Policy: `https://meloshemo.github.io` – son güncelleme 2025-11-11, e-Devlet kaldırıldı.
- Terms of Use: `https://meloshemo.github.io/terms.html`.
- Data Import Policy: `docs/data_import_policy.md` (uygulama içi banner & ayarlar bağlantısı).
- Incident Response Runbook: `docs/incident_response_runbook.md`.

## 5. Pending Tasks

- [ ] Settings ekranında "Analytics verilerini paylaş" toggle'ını expose et ve varsayılanı `false` yap.
- [ ] Supabase RLS policy review (tarih: 2025-11-30).
- [ ] Annual DPIA güncellemesi (sorumlu: privacy@hemoai.org).

