# Android Release Signing Setup

Follow these steps to sign HemoAI for Play Store release.

## 1) Generate a Keystore

Run in PowerShell (Windows):

```
keytool -genkeypair -v -storetype JKS -keystore app\keystore\release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias hemoai
```

Notes:
- Create the folder first if it doesn't exist: `app\keystore`.
- Remember the passwords you set.

## 2) Create key.properties

Copy `android/key.properties.example` to `android/key.properties` and fill the values:

```
storeFile=app/keystore/release.jks
storePassword=<your_store_password>
keyAlias=hemoai
keyPassword=<your_key_password>
```

Do NOT commit `key.properties` or the `.jks` file.

## 3) Build a signed release

From the repository root (PowerShell):

```
flutter clean
flutter pub get
flutter build appbundle --release
```

The Gradle script in `app/build.gradle.kts` already uses release signing automatically when `key.properties` is present; otherwise it falls back to debug signing for local runs.

## 4) Play Console Upload

- Upload the generated `.aab` from `build\app\outputs\bundle\release\app-release.aab`.
- Fill in Data Safety per the sections in the release checklist (notifications, contacts, user content). No advertising SDKs or tracking.

## 5) Rotating Keys (optional)

Keep a secure backup of the `.jks` and `key.properties` contents in a password manager or secret vault. Consider using Google Play App Signing with key upload for safer rotations.
