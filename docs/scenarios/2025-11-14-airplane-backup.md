# Scenario Report — Hemogram + Airplane Mode, Backup Export/Summary (2025-11-14)

Scope
- Validate adding a hemogram entry (active/latest appears) and editing a reminder while offline-like (local persistence).
- Validate backup export and content summary after seeding data.

Environment
- OS: Windows (PowerShell)
- Branch: os4-dev
- App target: test harness (headless)
- Storage: sqflite_common_ffi (native) + SharedPreferences (mocked for tests)

Test Artifacts
- Integration test: `test/integration/airplane_backup_flow_test.dart`
- Test run: PASS (3 tests)

---

1) Hemogram Record (Online) — Insert and verify active/latest
- Steps
  - Insert hemogram via `DatabaseHelper.insertHemogramTest({ user_id, test_date: now, hemoglobin: 13.6, status: 'active' })`.
  - Fetch latest via `DatabaseHelper.getHemogramTests(userId)`.
- Expected
  - The inserted record is active and appears as the latest.
- Result
  - PASS. Latest row status=active; hemoglobin=13.6.
- Messages/Snackbars
  - N/A (test harness; UI not invoked).
- Screenshots
  - UI-only. Suggested path: `docs/screenshots/2025-11-14/dashboard-latest-hemogram.png` (not captured in headless tests).

2) Airplane Mode — Edit reminder locally and persist
- Steps
  - Create in-app medication reminder (NotificationService), then update scheduled time as if offline.
  - Verify updated time persisted locally via lookup by id.
- Expected
  - Local edit persists; sync warning may show in app if network actions are attempted.
- Result
  - PASS. Time update persisted locally. No network call required.
- Messages/Snackbars
  - In-app builds may show localized network messages if a sync is attempted. Example key: `network_exception_no_connection`.
- Screenshots
  - UI-only. Suggested paths:
    - `docs/screenshots/2025-11-14/reminders-list-before.png`
    - `docs/screenshots/2025-11-14/reminders-list-after.png`

3) Backup Export and Summary
- Steps
  - Seed hemogram + reminder + settings (daily motivation time).
  - Export backup via `BackupService.exportAll()`.
  - Summarize via `BackupService.summarize(bytes)`.
- Expected
  - Export returns bytes; summary reports preferences and hemogram entries present.
- Result
  - PASS. Export non-empty; summary.preferencesCount >= 1; summary.hemogramTests >= 1.
- Messages/Snackbars
  - Not applicable in tests. In UI, export flows display localized success messages in Settings > Backup.
- Screenshots
  - UI-only. Suggested paths:
    - `docs/screenshots/2025-11-14/backup-export-success.png`

Notes / Localization
- Notification and settings strings are localized across 9 languages.
- Keys referenced: `medication_reminder_title`, `medication_reminder_body`, `notification_settings_saved`, `network_exception_no_connection`, frequencies and medication unit labels.

How to re-run (optional)
- Run only this integration suite:
  - VS Code Test Explorer or terminal: `flutter test test/integration/airplane_backup_flow_test.dart`

Status Summary
- Hemogram insert: PASS
- Airplane-mode reminder edit (local): PASS
- Backup export + summary: PASS
- Analyzer: PASS

Follow-ups
- Manual UI capture of snackbars/screens for documentation if needed.
- Web restore validation tests added: `test/integration/web_restore_test.dart` (merge/replace semantics)

---

Appendix A — Web Restore (merge/replace)
- Added focused tests to validate `BackupService.restoreWithStrategy` for Flutter Web (SharedPreferences store):
  - Merge: unions list sections by id; preserves existing per-user keys; adds missing ones.
  - Replace: overwrites list sections and per-user keys with incoming payload.
- Run:
  - `flutter test test/integration/web_restore_test.dart`
- Expected:
  - 2 tests pass; SharedPreferences keys reflect strategy.

Appendix B — PWA & Offline Verification (manual)
- Build web release:
  - `flutter build web --release`
- Serve locally (examples):
  - `npx --yes http-server -p 8081 build/web -a 127.0.0.1`
  - or `dart pub global run dhttpd --path build/web --port 8081`
- Service worker:
  - In Chrome DevTools → Application → Service Workers, verify `flutter_service_worker.js` is registered.
- Offline reload:
  - In DevTools, toggle Network → Offline; reload.
  - Expected: Dashboard, Reminders, Alerts open from cache; offline banner/notifications shown.
- Capture artifacts:
  - Screenshots: `docs/screenshots/2025-11-14/pwa-offline/sw-registered.png`, `docs/screenshots/2025-11-14/pwa-offline/offline-reload.png`
  - Console logs export: `docs/screenshots/2025-11-14/pwa-offline/console.log.txt`
  - Network HAR: `docs/screenshots/2025-11-14/pwa-offline/network.har`

Appendix C — Accessibility Checks (manual)
- Keyboard navigation (Tab/Shift+Tab):
  - Screens: Dashboard, Reminders, Settings.
  - Verify all actionable widgets are reachable and show focus outline.
  - Record issues/successes: `docs/screenshots/2025-11-14/a11y/keyboard-nav.md` with screenshots.
- Screen reader/empty states (NVDA/ChromeVox):
  - Empty lists (e.g., no reminders): ensure spoken text is meaningful. Keys available: `no_reminders_scheduled`, `no_reminders`.
  - Diet warnings: confirm semantics/labels read correctly; note any missing semantics.
  - Save notes/screens: `docs/screenshots/2025-11-14/a11y/sr-empty-states.md`, `.../diet-warnings.png`.
