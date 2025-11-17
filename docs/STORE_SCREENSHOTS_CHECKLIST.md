# Store Screenshots Checklist

This checklist helps you capture Play Store and App Store screenshots quickly and consistently.

## Target sizes

- Android phone (Play Store):
  - 1080 × 1920 (portrait) — recommended
- iPhone (App Store):
  - iPhone 6.7" (1290 × 2796) or 1284 × 2778 (portrait)
  - iPhone 6.1" (1179 × 2556) or 1170 × 2532 (portrait)
  - iPhone 5.5" (1242 × 2208) optional

Store paths:

- `store_assets/screenshots/android/`
- `store_assets/screenshots/ios/`

## Required screens (minimum set)

1) Dashboard / Home
2) Hemogram Entry (kategori görünümü)
3) Analysis (Health Score + Smart Summary)
4) Notifications (Unread / All)
5) Reminder List (Upcoming / Overdue / Completed)
6) Settings (About & Legal bölümü)

Optional:
- Family Panel
- Diet Program
- Alternative Medicine

## Capture instructions (manual)

1. Start the app (logged in or guest):
   - Web: `flutter run -d edge`
   - Android Emulator: `flutter emulators --launch <emulator>` → `flutter run -d <id>`
   - iOS Simulator (macOS): `open -a Simulator` → `flutter run -d <id>`

2. Navigate to each screen and ensure the UI is populated (use sample data if needed).

3. Capture:
   - Android Emulator: Toolbar camera icon
   - iOS Simulator: Cmd+S (or File > New Screenshot)
   - Web: OS-level screenshot (win+shift+s), then crop to viewport

4. Save with names:
   - Android: `store_assets/screenshots/android/<screen>-1080x1920.png`
   - iOS: `store_assets/screenshots/ios/<screen>-1284x2778.png`

## Quality checklist

- Status bar clean (time, battery) if possible
- No debug banners in release build
- Text legible (not too small)
- Consistent brand color
- No personal/sensitive info

## Post-process (optional)

- Add device frames (fastlane frameit or Figma mockups)
- Slight contrast/brightness tweaks if needed

## Final deliverables

- Android: min 2 phone screenshots
- iOS: min 3 iPhone screenshots


