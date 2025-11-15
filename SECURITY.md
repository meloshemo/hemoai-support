## Security and configuration guide

This document outlines how HemoAI handles secrets, dependencies, and web security headers. Follow these practices before shipping builds to users.

### Secrets and configuration

- Never hardcode secrets in the repository or the client app. Keep `.env` local; it is gitignored.
- Use `--dart-define` to pass runtime values to Flutter (see `lib/config/environment.dart` and `lib/services/cloud_sync_config.dart`).
- Firebase:
  - Client-side Firebase Web configuration in `lib/firebase/firebase_options.dart` is not a secret (it is required for the web SDK to work).
  - Keep Admin SDK credentials off the client; use backend functions where needed.
- Supabase (CloudSync):
  - Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and optional `SUPABASE_BACKUP_BUCKET` via `--dart-define`.
  - Example (PowerShell):
    flutter run --dart-define=APP_ENV=dev --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
- Email providers (e.g., SendGrid):
  - API keys must never be embedded in the client. Route emails via a trusted backend/service.
  - If a key was ever exposed locally, rotate it immediately and audit usage logs.

### Dependency hygiene

- Run `flutter pub outdated` regularly to review updates and deprecations.
- Prefer two-step upgrades:
  1) `flutter pub upgrade` to apply latest resolvable patch/minor updates within current constraints.
  2) Schedule major version upgrades with migration testing (Firebase plugins, router, permissions, ML kit, etc.).
- Lints and analysis: keep `flutter analyze` green and `analysis_options.yaml` strict; avoid suppressing rules broadly.

### Web security headers (hosting configuration)

Configure these headers at your CDN/host (e.g., Nginx, Firebase Hosting, Vercel). Meta tags alone are insufficient for strong protection.

- Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
- Content-Security-Policy: Start with a permissive policy compatible with Flutter Web and tighten gradually. Example baseline:
  default-src 'self';
  script-src 'self' 'wasm-unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' data: https:;
  connect-src 'self' https: wss:;
  frame-ancestors 'none';
  base-uri 'self';
- Referrer-Policy: no-referrer
- Permissions-Policy: geolocation=(), microphone=(), camera=()
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY

Notes:
- Flutter Web may require `script-src` allowances for WASM; newer engines can work with `'wasm-unsafe-eval'` without `'unsafe-eval'`. Test with Lighthouse and console.
- If you use Firebase, Supabase, or other CDNs, ensure `connect-src` includes their domains.

### Android and iOS identifiers

- Android `applicationId`: see `android/app/build.gradle.kts` (currently `com.meloshemo.hemoai`). Ensure it matches your Play Console listing.
- iOS `PRODUCT_BUNDLE_IDENTIFIER`: set via Xcode project build settings. Match App Store Connect bundle ID and `iosBundleId` in `firebase_options.dart`.
- App version: controlled by `version` in `pubspec.yaml` (e.g., `4.0.0+400`). Increment per release.

### Operational hardening checklist

- [ ] Rotate any keys that were ever committed or shared inadvertently; restrict API scopes to least privilege.
- [ ] Validate that all backend endpoints are HTTPS-only and enforce TLS 1.2+.
- [ ] Run Lighthouse (desktop and mobile) and fix Best Practices/Security category findings.
- [ ] Review error/crash telemetry redaction (no PII in logs).
- [ ] Confirm privacy strings on iOS (Info.plist) and Android (data safety) are accurate.
