# Store Asset Production Guide

This guide defines the production-ready graphics and hosting requirements before submitting HemoAI to Google Play and the App Store.

---

## 1. Mandatory Assets

| Asset | Spec | Notes |
|-------|------|-------|
| Feature Graphic | 1024 × 500 px, PNG | Include logo, gradient background, key value proposition. Maintain 64 px safe margin. |
| Phone Screenshots | 1080 × 1920 px (min 4, max 8) | Capture Dashboard, Motivation & Challenges, Analysis, Diet Plan, Family Panel. Use clean data, dark & light variants. |
| Tablet Screenshots *(optional but recommended)* | 1920 × 1200 px | Focus on analytics dashboards and streak card UI. |
| App Icon Master | 1024 × 1024 px | Already produced (`assets/icon/icon.png`). Validate against store guidelines. |
| Promo Video *(optional)* | 30 s MP4 | Scripted walkthrough with captions. |

Save final exports under `release/assets/<platform>/` with naming `01_dashboard.png`, `02_challenges.png`, etc.

---

## 2. Capture Instructions

1. **Environment preparation**
   - Run `flutter build apk --release` and install on emulator/physical device.
   - Seed demo account with realistic data (streaks, badges, family members).
   - Disable debug banners and ensure device language EN for baseline shots; capture TR variant separately.

2. **Framing**
   - Use Android Emulator: Pixel 7 Pro, 100% scale, status bar time 10:00.
   - Disable notifications and gestures.
   - For Play screenshots, capture raw PNGs; overlays added later via Figma template (`design/store-assets.fig`).

3. **Editing**
   - Leverage provided Figma template (link placeholder). Replace sample screens, update captions.
   - Export @1x PNG, verify <8 MB per image.

4. **Quality Checklist**
   - Text readability at 100% zoom.
   - Localization: capture TR version for at least 2 screenshots.
   - No personally identifiable data. Use synthetic names.
   - Check color contrast (WCAG AA).

---

## 3. Privacy Policy Hosting

- Upload `docs/privacy-policy.html` to GitHub Pages `/hemoai-support/privacy-policy.html` (already referenced in `AppConstants`).
- Validate HTTPS response and mobile rendering.
- Update README or `PLAY_STORE_CHECKLIST.md` with final URL confirmation.

---

## 4. Submission Artifacts Folder Structure

```
release/
  assets/
    play-store/
      feature-graphic.png
      screenshots/
        01_dashboard.png
        02_challenges.png
        ...
    app-store/
      6.7-inch/
      5.5-inch/
    marketing/
      promo-video.mp4
  docs/
    qa-signoff.pdf
    privacy-policy-url.txt
    store-copy/
```

---

## 5. Review & Approval

- Assign designer + reviewer.
- Log approvals in `docs/STORE_ASSET_APPROVAL_LOG.md`.
- Only upload assets signed off by product + legal.


