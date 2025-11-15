# Firestore Sync Overview

This document outlines Firestore integration for HemoAI (OS4) focusing on privacy, offline-first, and migration from local SQLite.

## Collections & Data Model
```
users/{uid}
  profile (doc fields: name, age, gender, ...)
  hemograms/{hemogramId}
  dietPlans/{planId}
  medications/{medId}
  reminders/{remId}
  hydrationLogs/{logId}
```
Common fields in each doc:
- userId: string (redundant to path, used for queries)
- createdAt: serverTimestamp
- updatedAt: serverTimestamp (conflict resolution: last-write-wins)

## Security Rules (firestore.rules)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{collection}/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
Test locally with the Firebase Emulator:
```bash
firebase emulators:start --only firestore
# or
firebase emulators:exec --only firestore "npm test"
```

## Offline Persistence
Enabled via:
```dart
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
```
Firestore caches writes/reads; app writes locally first to SQLite for fast queries and UI state.

## Sync Strategy
- Local-first: user interactions write to SQLite.
- FirestoreSyncService listens to snapshot streams; merges new remote docs if not present.
- Conflict Resolution: last-write-wins determined by `updatedAt` serverTimestamp (future: vector clocks or field-level merge).
- Migration utility pushes existing local data to Firestore on opt-in.

## Sensitive Data
Personal health data is stored in Firestore (encrypted at rest). For extra confidentiality, optional client-side AES encryption can be applied for selected fields before upload.

## Service Lifecycle
Initialized in `main.dart` as a provider:
```dart
ChangeNotifierProvider(create: (_) => FirestoreSyncService()..initialize()),
```
Disposes snapshot listeners when sync disabled or user logs out.

## Enabling / Disabling Cloud Sync
Reuses existing `auto_cloud_backup_enabled` preference until a dedicated toggle is implemented. When disabled, listeners are torn down.

## Migration
Call `FirestoreSyncService().migrateLocalToFirestore(userId: ...)` after user opts in to cloud backup.

## Future Enhancements
- Dedicated toggle & UI in Settings.
- Field-level encryption using envelope keys stored in Functions config.
- Batched writes and throttling.
- Structured indexes for queries (hemograms by date, reminders by time).
- Incremental sync with lastSync marker rather than full snapshot scan.
- Automated integrity verification (checksum per doc set).

## Pre-Commit PII Protections
Add patterns for dumps to the pre-commit hook to prevent accidental commit of raw hemogram exports.
