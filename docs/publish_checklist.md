# Publish Checklist

This concise checklist helps engineers and store teams verify the app is ready for release (Android, iOS, Web).

## Technical readiness
- CI green: Flutter analyze, tests, localization validator, and web build pass on main.
- Version bump: Update pubspec.yaml version and build number; note changes in CHANGELOG.
- Secrets: Verify no `.export.json`, dumps, or PII tracked; pre-commit hooks installed (`pre-commit install`).
- Firebase: Crashlytics/Performance enabled in release; Firestore rules deployed; anonymous auth allowed if used.
- Migrations: Run Firestore migration for opted-in accounts; verify data integrity on a test account.

## Data & privacy
- Data export/import: Smoke test JSON backup, encrypted backup, restore flows.
- Privacy policy & terms: URLs configured in `AppConstants`; verify they open externally.
- PII storage: Email/phone in secure storage; localization strings contain no personal info.
- Consent: Ensure KVKK/GDPR wording visible in Settings and during onboarding where applicable.

## Payments (if enabled)
- Products: Create in-store products (monthly, yearly, lifetime) with IDs documented in `docs/subscription_integration.md`.
- Verification: Backend receipt verification reachable; sandbox purchase tested end-to-end.
- Entitlements: App reads subscription status at startup; gracefully handles expired/invalid receipts.

## UX & content
- Localization: `dart run tool/validate_localization.dart` clean; no hardcoded TR/EN strings.
- Accessibility: Primary screens navigable; color contrast acceptable in dark/light modes.
- Store assets: Screenshots, icon, feature graphics prepared per store requirements.

## Deployment
- Android: `flutter build appbundle`; test on emulator and physical device; upload to Play Console internal testing.
- iOS: `flutter build ipa`; validate via Transporter; TestFlight internal testing.
- Web: `flutter build web --release`; ensure base-href matches hosting; deploy to Pages or hosting of choice.

## Rollout & monitoring
- Staged rollout plan defined; crash-free session target configured.
- Uptime & screenshot workflows monitored; set alerts for failures.
- Post-release checklist: Review analytics funnels and crash reports at 24h/72h.

Tip: Keep this doc updated with any process changes.
