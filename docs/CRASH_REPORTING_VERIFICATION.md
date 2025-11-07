# Crash Reporting Verification Guide

## 1. Configuration Summary
- SDK: `sentry_flutter` 7.20.2
- DSN: Read from compile-time env `--dart-define=SENTRY_DSN=...`
- Enabled flag: `--dart-define=ENABLE_CRASH_REPORTING=true` (defaults to true)
- Release identifier: `com.meloshemo.hemoai@4.0.0+400`
- Sample rate: 20% in production, 100% in debug/profile

## 2. Build Setup
Run the app with crash reporting enabled:

```
flutter run --release \
  --dart-define=SENTRY_DSN=YOUR_DSN \
  --dart-define=ENABLE_CRASH_REPORTING=true
```

For automated builds:

```
flutter build appbundle \
  --dart-define=SENTRY_DSN=${SENTRY_DSN} \
  --dart-define=ENABLE_CRASH_REPORTING=true
```

## 3. Smoke Test Procedure
1. Launch the app and open developer console/logcat.
2. Confirm log entry: `CrashReportingService: disabled...` **does not** appear.
3. Trigger handled error via hidden debug action (`Settings → Advanced → Trigger Test Error`).
4. Verify Sentry dashboard shows event with breadcrumb trail and environment.
5. Force crash (e.g., throw from isolate) to ensure uncaught errors propagate.
6. Check Sentry release health tab for new session.

## 4. Privacy Validation
- Ensure privacy policy references Sentry as crash processor.
- Provide opt-out toggle inside app (`Settings → Privacy`).
- Confirm opt-out stops new events (toggle, restart app, repeat step 3).

## 5. Maintenance
- Rotate DSN or scrub credentials via CI secrets manager.
- Enable alerting (email/Slack) for `Fatal` level events.
- Review Sentry issues weekly and triage within 24 hours.


