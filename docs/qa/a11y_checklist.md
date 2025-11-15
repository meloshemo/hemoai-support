# Accessibility Checklist (Web/PWA)

Date: 2025-11-14
Scope: Keyboard, Screen Reader (NVDA), Contrast, Scaling, RTL

## Keyboard Navigation
- Tab order: Logical across `/`, `/dashboard`, `/analysis`, `/hemogram_entry`, `/settings`.
- Focus visible: All interactive controls show visible focus ring.
- Escape/Back: Dialogs, modals, sheets dismiss via Esc/Back.
- Traps: No focus traps; tab cycles naturally.

## Screen Reader (NVDA on Windows)
- Landmarks: App contains named regions (e.g., main content).
- Labels: Buttons/inputs have meaningful labels; icons have accessible names.
- Images: Non-informative images marked decorative; informative images have alt.
- Announcements: Error and validation messages are announced.

## Contrast & Theming
- Contrast: Text/background meet WCAG AA (>= 4.5:1; large text 3:1).
- Modes: Check both light/dark via theme settings.
- States: Disabled/hover/pressed maintain sufficient contrast.

## Text Scaling & Zoom
- Browser zoom 125% / 150%: Layout reflows; no overlaps/truncation.
- OS text scaling: Ensure controls remain usable; no clipped text.

## RTL & Localization
- Switch to Arabic in settings; verify full RTL mirroring.
- No mixed-direction issues; punctuation aligns; numerals readable.
- No English literals; all user-facing strings localized.

## Forms & Validation
- Field labels linked to inputs.
- Errors appear inline and are descriptive + localized.
- Keyboard submission (Enter) works; focus shifts to first error.

## Recording Results
Use `docs/qa/results/manual_qa_results_2025-11-14.md` under D1–D6 sections.
