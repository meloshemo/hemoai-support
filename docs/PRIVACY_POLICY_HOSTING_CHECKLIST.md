# Privacy Policy Hosting Checklist

**Goal:** Ensure the production privacy policy and terms URLs meet store compliance requirements.

---

## 1. Hosting Steps
1. Build GitHub Pages site under `meloshemo.github.io/hemoai-support/`.
2. Copy `docs/privacy-policy.html` → `./privacy-policy.html` in repository root.
3. Copy `docs/terms-of-use.html` → `./terms-of-use.html` to host updated terms document.
4. Enable Pages (main branch → `/` root).
5. Verify deployed URLs:
   - Privacy Policy: `https://meloshemo.github.io/hemoai-support/privacy-policy.html`
   - Terms of Use: `https://meloshemo.github.io/hemoai-support/terms-of-use.html`
6. Update DNS/custom domain if applicable.

## 2. Validation Checklist
- [ ] HTTPS lock icon present.
- [ ] Content renders on mobile and desktop.
- [ ] Last updated date matches latest policy edit.
- [ ] Links within document resolve correctly.
- [ ] Text is selectable and copyable (no images only).
- [ ] Policy references crash reporting provider (Sentry) and data collection scope.

## 3. App Integration
- Confirm `AppConstants.privacyPolicyUrl` and `AppConstants.termsOfUseUrl` point to live URLs.
- Validate Settings → Privacy Policy / Terms open external browser (Android + iOS).
- Confirm links included in store listing metadata.

## 4. Documentation
- Record completion in `PLAY_STORE_CHECKLIST.md`.
- Attach screenshots of live policy to compliance archive (`release/docs/privacy-policy-proof/`).


