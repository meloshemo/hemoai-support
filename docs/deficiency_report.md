# Pre-Release Deficiency Report (Draft)

This report categorizes remaining gaps before production launch. Updated: 2025-11-10

## 1. Functional
- In-App Purchase Migration (Android/iOS) final QA: need test device validation for product fetch, purchase flow, restore flow, edge cases (network loss, cancellation).
- EmailService production mode: currently using test/fallback; requires SendGrid (or chosen provider) key injection and rate-limit/backoff policies.
- Legal links offline fallback: missing local cached PDF copies for privacy policy & terms.
- Cloud data strategy decision: Firestore vs Supabase path — dual path still partially present (cleanup, remove unused provider implementations if Firestore is definitive).

## 2. QA & Testing
- Automated integration tests for purchase flows (skipped due to store constraints) — create mock layer tests around PaymentService + PremiumService state changes.
- Crashlytics verification: generate non-fatal & fatal events on real release/signed builds, confirm dashboard and symbol uploads.
- FCM background & terminated message handling tests (currently only foreground logging).
- Accessibility test pass (TalkBack/VoiceOver) for premium screen highlights & settings list focus order.

## 3. Security
- Server-side purchase verification endpoint not yet integrated (client falls back to optimistic mapping). Need hardened backend, HMAC auth, fraud logging.
- AES key management: placeholder (stored in prefs) — move key provisioning server-side or via secure remote config; rotate process documentation.
- Privacy & terms URLs: add integrity check (hash or signature) for offline cached copies.
- PII scan hook: extend patterns for family member names, medication names, and potential lab value dumps.

## 4. Performance
- Cold start profiling on low-end Android devices; measure provider initialization cost (PremiumService + FirestoreSyncService + MessagingService).
- Deferred initialization: move non-critical services (DailyAdviceService, SocialChallengeService) to post-frame or background isolate after first frame.
- Firestore snapshot merging: consider batching writes on migration to reduce serverTimestamp overhead.

## 5. UX / Product
- Premium upsell copy localization: ensure dynamic monthly/yearly savings messaging and trial countdown translations.
- Lifetime plan justification section (value proposition) — add modal or inline tooltip.
- Purchase error states: differentiate network vs store rejection vs verification failure.
- Settings screen length: consider virtualized list or collapsible sections for mobile ergonomics.

## 6. Internationalization (i18n)
- Some English literals in premium feature list ("POPÜLER" mixed). Need keys for: pricing_plans, POPÜLER badge, Unlimited Tests, Advanced Analytics, etc.
- New docs created in English only; internal contributor guidance could require Turkish summary segment.

## 7. Accessibility
- Contrast check for red gradients over dark background (Premium status card).
- Add semantic labels for icons (star, lock, check) and progress indicators.
- Focus traversal order in Settings: nested sections may skip headers — wrap headers with Semantics.

## 8. Compliance & Legal
- GDPR/KVKK data deletion SLA wording: confirm with legal; current disclaimer may need revision.
- Medical disclaimer needs localized versions and explicit emergency instruction.
- Subscription terms (auto-renewal disclosure) absent from purchase screen.

## 9. Deployment / DevOps
- Firebase production config placeholders: ensure `google-services.json`, `GoogleService-Info.plist`, and `firebase_options.dart` are populated with prod project (staging separation).
- Symbol upload automation (Android mapping.txt, iOS dSYM) — integrate into CI.
- Web build cache busting & CDN headers (hash filenames, add cache-control docs).
- Stripe/Web payment webhook endpoint not yet present — docs exist but endpoint implementation missing.

## 10. Observability
- Missing metrics for subscription conversion funnel (attempts, failures, cancellations).
- FCM delivery stats instrumentation (log token refresh events count).
- App performance custom traces for provider initialization phases.

## 11. Data Integrity
- Migration dedup heuristics (hemograms/reminders) may produce duplicates if descriptions vary; consider hash-based identity or store server IDs.
- Reminder repeat types mapping (repeat_type vs repeat) normalization required.

## 12. Backlog (Lower Priority)
- Offline PDF export localization for advanced analytics.
- Secure backup password strength meter & iterative KDF (PBKDF2/Argon2) hardening.
- Web push (VAPID) integration for browser notifications.

## Immediate P0 Next Steps
1. Finalize IAP migration (products, test purchases, restore) + subscription terms disclosure.
2. Crashlytics release verification on both platforms.
3. Firebase production config insertion & environment separation.
4. Server purchase verification endpoint + minimal fraud logging.
5. Legal link validation + offline fallback PDFs.

## Ownership Suggestions
- IAP & Subscription: Payments / Backend team.
- Security & Encryption: Security engineering.
- Compliance & Legal: Legal counsel + Product.
- Performance & Observability: Platform team.

## Tracking
Link each item to issue IDs in tracker (placeholder). Use severity tags: P0 (must before launch), P1 (strongly recommended), P2 (post-launch). Current counts: P0=5, P1≈12, P2≈8 (see board for exact).

---
Generated automatically. Update after each remediation sprint.
