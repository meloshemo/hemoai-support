# Notification Sync Roadmap (Local Reminders + FCM)

## Goals
1. Keep existing local reminder reliability (alarms, notifications).
2. Extend to cloud-delivered reminders so users receive alerts on every device.
3. Support caregiver visibility and override rules (e.g., parent receives alerts for child).

## Architecture Overview
```
Flutter app ── Firebase Messaging token ──► Firestore (user_devices)
          │                                   │
          └── Local reminder scheduler        └── Cloud Functions (reminder dispatcher)

Cloud scheduler / App logic ──► Cloud Functions ──► FCM topics / direct tokens ──► Devices
```

## Phases

### Phase 1 – Token registration (client)
- Add `firebase_messaging` dependency.
- Request notification permission (iOS prompt, Android channel).
- Register foreground/background handlers.
- Save `FirebaseMessaging.instance.getToken()` to Firestore:
  - Collection: `user_devices/{userId}/tokens/{token}`
  - Metadata: platform, locale, timezone, lastActive, appVersion.
- Subscribe to per-user topic: `user_{userId}`.

### Phase 2 – Cloud dispatcher
- Cloud Function `scheduleReminderPush` triggered by Firestore changes or cron.
- Reads upcoming reminders (`reminders` collection or exported schedule document).
- Sends `data` payloads via FCM (`sendMulticast`), includes reminder ID and snooze actions.
- Implements exponential backoff + logging with structured context (requestId, userId).

### Phase 3 – Cross-device acknowledgement
- When a reminder is completed on one device, publish confirmation to `user_{userId}` topic.
- Other devices consume `onMessage` and cancel local notification if already delivered.

### Security
- Firestore rules restrict token writes to authenticated user.
- Tokens purge job (scheduled) deletes stale tokens older than 30 days.
- Payloads avoid PHI; send only reminder IDs. Device fetches details securely from local database/Firestore.

### Tooling
- Add `tool/fcm_test_notification.dart` (future work) to send test pushes via service account.
- Monitor via Firebase Console + custom Ops automation (Stackdriver log-based alerts).

## Current Status
- Documentation + plan only (no code integration yet).
- Next implementation tasks:
  1. Add `firebase_messaging` dependency, set up API on Android/iOS (Gradle, plist entitlements).
  2. Create `NotificationSyncService` in Flutter to manage tokens, permission prompts, and cross-device sync toggles.
  3. Build Cloud Function dispatcher using Firestore scheduled exports or cron.

