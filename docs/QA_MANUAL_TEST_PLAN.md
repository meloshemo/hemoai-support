# HemoAI Manual QA Playbook

**Objective:** Validate all high-risk user journeys before store submission. Every checklist item must have a recorded ✅/❌ result, tester name, device, build, and timestamp.

---

## 1. Test Session Metadata
- **Build:** `app-release.aab` (release, minify enabled)
- **Environment:** Production API + Supabase staging
- **Crash Reporting:** Verify Sentry initialization in logs (`Sentry SDK initialized`)
- **Test Devices:**
  - Android: Pixel 7 (Android 14)
  - iOS: iPhone 15 (iOS 18) *(if targeting iOS)*
  - Optional: Web Chrome latest, Windows 11 desktop
- **Accounts:**
  - Primary tester account (premium-capable)
  - Secondary account for social/family scenarios

Record session details in `docs/QA_TEST_RUN_LOG.md` (create per run).

---

## 2. Smoke Checklist (15 minutes)

| Step | Expected | Result | Notes |
|------|----------|--------|-------|
| Launch app | Splash → Auth gate with no crashes | | |
| Sign in with existing credentials | Dashboard loads with latest data | | |
| Toggle dark/light theme | Theme update persists | | |
| Switch language (TR ↔ EN) | UI fully localized, no clipped strings | | |
| Navigate each bottom tab | Correct screen renders, no blank states | | |

---

## 3. Core Navigation Coverage

### 3.1 Dashboard & Analytics
- Validate cards render real data (hemogram insights, daily tips).
- Open `Advanced Analytics`, verify charts load and filters respond.
- Check `Performance` screen for trend charts and no divide-by-zero errors.

### 3.2 Motivation & Challenges
- Verify weekly points animation runs and streaks show accurate counts.
- Trigger `Daily Challenge` completion → confirm points updated.
- Inspect friend competition states: winning, losing, pending approvals.
- Open diet plan modal from shared AI plan; ensure localized strings.

### 3.3 Notifications & Reminders
- Create reminder → push local notification scheduled (use debug log).
- Edit and delete reminder, confirm snackbars localized.
- Trigger `Notification Debug` (debug builds only) for regression.

### 3.4 Hemogram & Analysis Flow
- Add new hemogram manually and via OCR (Google ML Kit) → verify normalized values.
- Export report as PDF & Excel, open file to ensure content.
- Share via `share_plus` (Android share sheet opens).

### 3.5 Diet Programs
- Generate AI diet plan (requires premium). Confirm plan saved & localized.
- Start 2-week shared plan with partner profile; ensure progress cards sync.
- Cancel plan, check status resets.

### 3.6 Family & Social
- Add family member, update profile photo (image picker).
- Invite friend (requires secondary account). Validate pending request UI.
- Approve request, check leaderboard updates.

### 3.7 Settings & Account
- Change privacy toggles (analytics opt-in, crash sharing) and restart app to confirm persistence.
- Open support portal → Sentry crumb should log success or fallback to clipboard.
- Open privacy policy & terms (webview or external browser) and ensure links reachable.
- Validate backup settings: toggle auto-backup, run manual backup, inspect generated archive.

---

## 4. Premium Flow Validation
- Attempt premium feature on web → ensure “mobile-only premium” message appears.
- On Android, initiate Google Play billing sandbox flow:
  1. Purchase monthly SKU
  2. Verify `PremiumService` flags updated
  3. Simulate expiry via Play Console test or manual override
- Confirm receipt of premium activation email (mock).
- Ensure `in_app_purchase` restore purchases path works after reinstall.

---

## 5. Backup & Restore Deep Dive
- Run manual backup (local path).
- Inspect encrypted backup metadata file for timestamp.
- Clear local data (use in-app “Reset” or reinstall).
- Restore from backup, confirm hemogram records, reminders, diet plans restored accurately.
- Validate cloud sync queue processes pending items after reconnecting offline data.

---

## 6. Localization & Accessibility Sweep
- Cycle through all supported locales (TR, EN, ES, FR, DE, AR).
- Verify RTL alignment in Arabic (cards, lists, icon mirroring).
- Use screen reader (TalkBack/VoiceOver) for primary screens.
- Check text scaling at 200% and 80%—no overflow or truncation.
- Confirm accessible widgets expose semantic labels and actions.

---

## 7. Regression Guardrails
- Run automated suite: `flutter test`.
- Execute integration tests (if applicable).
- Manually review Sentry dashboard for captured breadcrumbs/crash test.
- Trigger handled exception via hidden debug gesture, ensure graceful snackbar + Sentry capture.

---

## 8. Exit Criteria
Release is ready once:
- ✅ All steps above marked PASS (no high/critical defects outstanding).
- ✅ Sentry dashboard shows at least one test event per platform.
- ✅ Privacy Policy & Terms links verified live.
- ✅ Store assets prepared and documented (see `docs/STORE_ASSETS_DELIVERABLES.md`).
- ✅ QA lead signs off with date + signature in `docs/QA_SIGNOFF.md`.

---

## 9. Reporting Template
Create or update `docs/QA_TEST_RUN_LOG.md` with table:

| Date | Tester | Build | Device(s) | Result | Issues Filed |
|------|--------|-------|-----------|--------|--------------|

Attach Jira/GitHub issue IDs with severity. Escalate blockers immediately to release manager.


