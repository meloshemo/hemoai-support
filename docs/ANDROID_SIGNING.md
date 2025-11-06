# Android Release Signing (Play Store AAB)

This app is configured to load release signing credentials from `android/key.properties`.
The keystore and credentials must remain private and are ignored by git.

## 1) Generate a keystore (one-time)

Use the Java `keytool` (bundled with Android Studio / JDK) to create a release keystore.

Example (customize alias, name, and DN fields):

```
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias hemoai
```

- Keystore file: `android/app/keystore/release.jks` (recommended)
- Alias: `hemoai` (or your choice)
- Set strong passwords for the keystore and the key

> Keep the keystore file and passwords safe. Losing them means you cannot update the app.

## 2) Place the keystore

Create a folder:

```
android/app/keystore/
```

Then move your `release.jks` into it:

```
android/app/keystore/release.jks
```

Git is configured to ignore `*.jks` and the entire `keystore/` folder.

## 3) Create `android/key.properties`

Copy the example and fill your secrets:

```
cp android/key.properties.example android/key.properties
```

Then edit:

```
storeFile=app/keystore/release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=hemoai
keyPassword=YOUR_KEY_PASSWORD
```

`android/key.properties` is in `.gitignore`.

## 4) Build a signed AAB

From the repository root:

```
flutter build appbundle --release
```

Gradle will automatically pick up `android/key.properties` and sign the release.

## 5) Troubleshooting

- If `key.properties` is missing, the release build falls back to debug signing (for local runs). Create `android/key.properties` to enable real signing.
- Wrong passwords or wrong path in `storeFile` will fail the build with a signing error.
- Ensure `JAVA_HOME` points to a JDK (11+), and `keytool` is on your PATH.

## 6) Security notes

- Never commit keystores or passwords. The repo `.gitignore` already excludes them.
- Consider storing passwords in a password manager. For CI, use secure secrets store (GitHub Actions secrets) and inject at build time (not covered here).
