# Data Tier Evaluation: Supabase vs Firebase Sync

## Current state (v4.0.0)
- Offline-first with encrypted SQLite / shared preferences.
- No automatic multi-device sync; exports handled via user-controlled backups.

## Requirements from stakeholders
1. Preserve offline capabilities.
2. Minimal vendor lock-in and predictable cost.
3. End-to-end encryption where feasible.
4. Support role-based access for family/caregivers.

## Option A: Firebase (Firestore + Cloud Functions)

| Aspect | Notes |
|--------|-------|
| Security | Firebase Auth + Firestore rules; can enforce per-document access. Combine with client-side encryption for PHI. |
| Sync | Real-time listeners, delta updates, offline cache built-in. |
| Cost | Blaze plan (already enabled). Pay per document read/write. |
| Tooling | Existing Functions/Crashlytics stack; reuse analytics and FCM. |
| Challenges | Need HIPAA BAA if US hosting. For encrypted fields, use client crypto wrappers. |

### Suggested approach
- Use Cloud Functions to issue short-lived upload tokens.
- Store sensitive lab data encrypted (AES-256-GCM) before pushing to Firestore.
- Maintain local cache; reconcile via last-write-wins or vector clock metadata.

## Option B: Supabase (Postgres + Edge Functions)

| Aspect | Notes |
|--------|-------|
| Security | Row Level Security (RLS) policies; easy to model family sharing. |
| Sync | Supabase Realtime for change feeds; requires manual conflict resolution. |
| Cost | Free tier generous, paid tiers predictable. Need self-host or EU/US datacentres. |
| Tooling | SQL-based reporting, pgcrypto for server-side encryption. |
| Challenges | Flutter SDK still maturing for offline sync; need background job for push/pull. |

### Suggested approach
- Model lab results per user in dedicated schema (`lab_result`, `medication_log`).
- Use RLS to ensure only owner + invited caregivers can read.
- Encrypt payload columns with pgcrypto and store keys in Vault/Edge secrets.

## Recommendation

Start with Firebase sync:
- Already in the stack (Crashlytics, Functions, Auth).
- Lower integration overhead for push notifications (FCM).
- Offers automatic offline caching.

Next steps:
1. Prototype encrypted Firestore sync for hemogram records.
2. Measure read/write volumes to estimate cost.
3. If Postgres analytics become critical, re-evaluate Supabase as hybrid data warehouse.

