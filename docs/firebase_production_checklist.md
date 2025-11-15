# Firebase Production Checklist (Android • iOS • Web)

This checklist hardens Firebase for release: Crashlytics, Messaging (FCM), Performance, Auth, Firestore, and platform configs. Follow it before pushing to stores.

## 1) Projects and configs
- Use the production Firebase project (not playground). Ensure:
  - android/app/google-services.json (prod)
  - ios/Runner/GoogleService-Info.plist (prod)
  - lib/firebase_options.dart points to the same prod project (via flutterfire configure)
- Environment separation (optional): keep dev/prod files under `firebase/dev/` and `firebase/prod/`, swap via CI or flavors.

## 2) Crashlytics
- Enable Crashlytics in Firebase console for prod.
- Android:
  - In release builds, mapping files upload automatically via Gradle when `com.google.firebase.crashlytics` plugin is applied.
  - Verify by generating an APK/AAB and checking the “Builds” tab.
- iOS:
  - dSYMs upload via Xcode build step or `upload-symbols` script.
- In-app test: use the debug-only “Crash Test (Crashlytics)” tile in `Settings` and confirm the crash appears on the dashboard (filter by app version/build).

## 3) Messaging (FCM)
- Android:
  - Android 13+ requires POST_NOTIFICATIONS permission. Already present in `android/app/src/main/AndroidManifest.xml`.
  - No additional service declarations needed; FCM plugin merges them.
  - Optional: provide a default notification icon/color (vector, light monochrome) if you post system notifications from native. Current app shows in-app list; you can add an icon later.
- iOS:
  - Enable Capabilities: Push Notifications + Background Modes (Remote notifications).
  - Upload APNs Auth Key (.p8) or certificates; link to the Firebase iOS app.
  - Request notification permission at runtime (MessagingService.handlePermission on iOS already does this).
- Web (optional):
  - Place a `firebase-messaging-sw.js` at project root served by host; include your sender ID and `onBackgroundMessage` handler.

## 4) Firestore & Auth
- Rules: deploy strict user-isolation rules (each user can only read/write their doc space). See `firestore.rules` in repo.
- Indexes: create compound indexes if required by queries (Firestore console will suggest).
- Auth: Anonymous or email auth allowed? Update sign-in providers accordingly.

## 5) Performance Monitoring & Analytics
- Enable Performance and Analytics in console.
- Respect user privacy toggle in app (`analytics_opt_in`). When off, avoid logging.

## 6) Build and validation
- flutter analyze → PASS
- flutter test → PASS
- Android release:
  - `flutter build appbundle` (or apk)
  - Install on a real device, trigger Crash Test tile, verify Crashlytics.
- iOS release:
  - Archive from Xcode, run on device, trigger Crash Test tile, verify Crashlytics. Confirm dSYMs uploaded.

## 7) Push end-to-end test
- Toggle push permission ON in app settings.
- From Firebase console, send a test message to your device token (MessagingService registers tokens under `users/{uid}/devices/{token}`). Verify receipt foreground/background.

## 8) Security and PII
- Do not commit credentials. google-services files should be stored securely.
- If syncing sensitive fields to Firestore, prefer client- or server-side encryption. See docs/firestore_sync.md for the model.

## 9) Release notes
- Document project id, app id (Android/iOS), SHA-1 fingerprints (Android), and APNs key id/team id (iOS) for future maintenance.

---
Tip: If you switch projects later, re-run `flutterfire configure` and replace options + service files, then rebuild both platforms.