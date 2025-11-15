# Performance Traces

Drop timeline JSON snapshots captured from DevTools here.

Suggested naming:
- YYYY-MM-DD-timeline-android.json
- YYYY-MM-DD-timeline-web.json
- YYYY-MM-DD-timeline-android-offline.json
- YYYY-MM-DD-timeline-web-offline.json

Include a short markdown summary below with device/emulator, build hash/date, and key findings.

## Summary (add runs here)

- Date: 2025-11-12
- Target: Web (Edge)
- Files:
	- 2025-11-12-timeline-web.json
	- 2025-11-12-timeline-web-offline.json
- Saved at: docs/performance/
- Notes:
	- These exports appear to be binary (likely gzipped) traces. Load them in Chrome/Edge DevTools Performance panel via "Load profile..." to view.
	- Keep both online and offline variants for comparison.
	- If needed for diffing, gunzip first to get plain JSON.
