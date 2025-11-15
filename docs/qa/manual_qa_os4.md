# HemoAI Manual QA — OS4 (v4.0.0)

Date: 2025-11-14
Scope: Hemogram sync, Import/Export, PWA offline, Accessibility

## Pre-Reqs
- Environment: Flutter stable; run on web (Edge). App entry: `lib/main.dart`.
- Test account: Any (guest acceptable). Ensure you can add hemograms.
- Network: Ability to toggle offline in Edge DevTools.
- Notes: All user-facing strings must be localized via `LocalizationService`.

### Quick Start
- VS Code task: Run “Run OS4 after cleanup (Edge)”
- Or PowerShell:
  - `Set-Location -LiteralPath "c:\\Users\\omeli\\Desktop\\hemoai"`
  - `flutter run -d edge -t lib/main.dart`

Routes to know: `/dashboard`, `/analysis`, `/hemogram_entry`, `/export_options`, `/data_import`, `/reminders`, `/settings`, `/stats`.

---

## A. Hemogram Sync QA
Goal: Validate “single active hemogram” rule, local persistence, and sync behavior.

1) Insert + Auto-Archive Rule
- Steps:
  - Go to `/hemogram_entry`; create Hemogram A (set distinct date, e.g., 2025-10-01).
  - Create Hemogram B (date: 2025-11-01).
  - Navigate to history (wherever list is shown) or `/analysis`.
- Expected:
  - Hemogram B is `status=active`.
  - Hemogram A auto-archived with `status=archived` and `archived_at` not null.
  - `DatabaseHelper.getHemogramTests` returns exactly one active.

2) Cloud Sync Push/Pull
- Steps:
  - With network online, add a new Hemogram C.
  - Trigger/await sync (via `SyncSchedulerService` or UI action if present).
  - On another browser session or after app refresh, verify C appears.
- Expected:
  - New active record visible after sync.
  - No duplicate active entries; older active becomes archived.

3) Timeout/Network Error Localization
- Steps:
  - Temporarily toggle offline and force sync (or use a sync action/route that attempts network).
- Expected localized messages (no raw English literals):
  - Keys like `timeout_hemogram_sync`/`network_exception_connection_failed_vpn` are reflected via `LocalizationService`.

4) Offline Entry Then Resync
- Steps:
  - Toggle offline.
  - Add Hemogram D; navigate between routes to ensure it persists locally.
  - Go online and trigger sync.
- Expected:
  - D persists offline and syncs upon reconnection.
  - Archived/active state remains consistent.

---

## B. Import / Export QA
Goal: Validate export format, import correctness, error handling, and localization.

1) Export Current Data
- Steps: Go to `/export_options` and export.
- Expected:
  - File saved with hemograms, reminders, medications, water, etc., per app settings.
  - Timestamps and IDs intact; one active hemogram per user.

2) Import Back
- Steps: Go to `/data_import`, select exported file, import.
- Expected:
  - No duplicates for identical records; merges or upserts according to repository logic.
  - Active/archived statuses preserved.

3) Encrypted/Invalid Backup Errors
- Steps:
  - Attempt to import a corrupted/incorrect JSON (e.g., truncate a file or alter header).
- Expected localized errors (no hardcoded English):
  - `backup_invalid_encrypted_file`, `backup_invalid_magic_header`, `backup_unsupported_version`, `backup_invalid_payload`, `backup_truncated_payload`, `backup_decryption_failed`.

4) Metadata Read/Update Timeouts
- Steps: Simulate slow network (DevTools throttling) and re-run import/export operations.
- Expected localized timeouts:
  - `timeout_metadata_read`, `timeout_metadata_update`.

---

## C. PWA Offline QA
Goal: Confirm offline readiness, caching, and graceful behavior.

1) Install PWA
- Steps:
  - In Edge, open the running app → Install as app (Apps → Install this site as an app).
- Expected:
  - App installs and launches as PWA; icon present.

2) Offline Navigation + Caching
- Steps:
  - Toggle offline in DevTools.
  - Restart PWA; navigate to `/dashboard`, `/analysis`, and any summary views.
- Expected:
  - Core UI loads from cache; previously visited screens are available.
  - No blank white screen; any network-dependent widgets degrade gracefully.

3) Offline Data Changes
- Steps:
  - While offline, add hemogram/reminder; close and reopen PWA; verify persistence.
  - Go online; wait for background sync/trigger manual sync.
- Expected:
  - Data persists offline and syncs upon reconnection without conflicts.

4) Service Worker Verification
- Steps:
  - DevTools → Application → Service Workers/Cache Storage.
- Expected:
  - Service worker registered; static assets cached; updates apply on next reload.

---

## D. Accessibility QA
Goal: Validate keyboard, screen reader, contrast, scale, and RTL.

1) Keyboard Navigation
- Steps:
  - Tab through all interactive elements across major routes.
- Expected:
  - Visible focus outlines; logical order; no traps; skip links (if provided) work.

2) Screen Reader (NVDA on Windows)
- Steps:
  - Use NVDA; traverse common screens.
- Expected:
  - Controls have meaningful labels/roles; images have alt; purely decorative images ignored.

3) Contrast & Theming
- Steps:
  - Check primary/secondary colors in light/dark modes.
- Expected:
  - Meets WCAG AA contrast (4.5:1 for text); no text on low-contrast backgrounds.

4) Text Scaling
- Steps:
  - Increase OS/browser zoom and font scaling.
- Expected:
  - UI reflows without truncation/overlap; no hidden critical controls.

5) RTL & Localization
- Steps:
  - Switch to Arabic in settings; revisit all key routes.
- Expected:
  - Proper RTL layout; no mixed-direction rendering; no English literals.

6) Forms & Validation
- Steps:
  - Attempt invalid inputs in hemogram entry.
- Expected:
  - Errors are readable, announced by screen reader, and localized.

---

## Recording Results
Use this template per test:
- Case ID: (e.g., A1)
- Steps:
- Expected:
- Actual:
- Result: Pass/Fail
- Notes/Screenshots:

Bug report template:
- Title:
- Area: Hemogram Sync / Import-Export / PWA / A11y
- Steps to Reproduce:
- Expected vs Actual:
- Logs (if any):
- Locale:
- Screenshot/Video:

---

## Acceptance Criteria
- One active hemogram invariant holds through CRUD and sync.
- Import/export deterministic, idempotent where relevant; errors localized.
- PWA runs offline with cached UI; offline writes persist and sync later.
- Accessibility: No critical blockers; keyboard-only operation, screen reader labels, and contrast meet AA.
