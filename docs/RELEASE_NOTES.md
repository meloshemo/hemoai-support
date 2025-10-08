# OS 4 HemoAI (v4.0.0+400)

Release date: October 2025

What’s new:
- Smart Summary on Analysis with risk score, top flags, and next steps.
- Adaptive Reminders with streak tracking, Mark as Done, and 10-minute Snooze.
- Settings screen accessibility improvements and routes for tools (performance, notifications, stats, about).

Compatibility:
- Database version bumped to v4 (adds reminder_streaks and reminder_logs).
- Web storage parity ensured for new tables via SharedPreferences.

Validation:
- All tests passing at release cut.
- Localization validator passes with new keys.

Notes:
- Legacy go_router file remains unused and may be removed in a future cleanup.
