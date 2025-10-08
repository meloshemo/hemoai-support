# Platform Privacy and Permissions

This app collects and processes data locally on-device. Network analytics are disabled by default and only available as an explicit, local-only opt-in (no telemetry).

Android permissions:
- INTERNET, ACCESS_NETWORK_STATE: basic connectivity.
- CAMERA: optional, for OCR of lab reports.
- READ_MEDIA_IMAGES (Android 13+): to pick images.
- READ/WRITE_EXTERNAL_STORAGE (maxSdkVersion capped): legacy devices for export/pick.
- POST_NOTIFICATIONS (Android 13+): for reminders.

iOS privacy usage descriptions:
- NSCameraUsageDescription: scan lab reports (OCR), profile photo.
- NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription: pick/save images when exporting.
- NSFaceIDUsageDescription: optional app lock.
- NSHealthShareUsageDescription, NSHealthUpdateUsageDescription: if you enable health data sync (off by default).

Data storage and backup:
- Web: SharedPreferences stores JSON under app-specific keys.
- Native: SQLite (sqflite) database; preferences in SharedPreferences.
- Backup: JSON export with optional AES-GCM encryption (.hemoenc). Backup includes preferences, web store lists, per-user reminders/notifications/medications/water, and diet tracking (web and native).
- Restore: Merge or Replace strategy. Merge avoids overwriting existing per-user keys; Replace overwrites.

Security notes:
- Encrypted backups use PBKDF2-HMAC-SHA256 to derive a 256-bit AES-GCM key with random salt and nonce.
- No PII is sent to servers. Cloud sync is not enabled by default.

Build notes:
- Android 13+: request POST_NOTIFICATIONS and READ_MEDIA_IMAGES at runtime via `permission_handler` if needed.
- iOS: ensure capabilities are set if HealthKit is later used.
