# Lighthouse Audits

Run Lighthouse against the local release build (http://localhost:8080).

Recommended captures:
- Desktop: Performance + Best Practices + Accessibility + SEO
- Mobile (Simulated): Performance + Best Practices + Accessibility + SEO

How to capture (Edge/Chrome):
1) Open http://localhost:8080
2) F12 → Lighthouse tab
3) Choose Mode: Navigation, Device: Desktop (then repeat for Mobile)
4) Analyze. When done, use the Download button:
   - Save HTML report to docs/audit/YYYY-MM-DD-lighthouse-[desktop|mobile].html
   - Save JSON report to docs/audit/YYYY-MM-DD-lighthouse-[desktop|mobile].json

Notes:
- Use an InPrivate/Incognito window to reduce extensions noise.
- Close other tabs/apps to reduce throttling variance.
- For repeatability, run each profile twice and keep the better of 2.

## 2025-11-12 captures

Saved HTML reports (kept original filenames):

- Desktop (simulated):
   - new1.html  (fetch ~09:30Z)
   - new2.html  (fetch ~09:31Z)
   - new3.html  (fetch ~09:31Z)
   - new4.html  (fetch ~09:32Z)
   - localhost_56931-20251112T105146.html
   - localhost_56931-20251112T105243.html
   - localhost_56931-20251112T105319.html
   - localhost_56931-20251112T105347.html
   - localhost_56931-20251112T105418.html

- Mobile (simulated):
   - device.html    (fetch ~09:33Z)
   - device 1.html  (fetch ~09:33Z)

Tip: You can rename to a consistent scheme if desired, e.g.:
- 2025-11-12-lighthouse-desktop-1.html ... -4.html
- 2025-11-12-lighthouse-mobile-1.html ... -2.html

If JSON exports are available, drop them here as well following the same naming.
