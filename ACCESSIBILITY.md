# Accessibility Statement

**App:** Keuangan Pribadi (Personal Finance Manager)  
**Version:** 1.0  
**Date:** July 2026  

This statement describes the current accessibility status of the Keuangan Pribadi application. The app is a personal finance manager developed as a student project by a single developer. It targets Android, iOS, and Web platforms using Flutter.

---

## Standards followed

The application is built with awareness of the **European Accessibility Act (EAA)**, enforceable EU-wide since June 28, 2025, and the German **Barrierefreiheitsstärkungsgesetz (BFSG)**, which specifically names digital financial services as in-scope. While this is a student project and not a commercial service, the following WCAG 2.1 AA guidelines have been adopted where practical:

| Criteria | Status |
|----------|--------|
| **1.1.1 Non-text Content** | Partial — icons in the More menu and key action buttons have `Semantics` labels. Icons without interactive function (decorative icons) are not labelled. |
| **1.4.3 Contrast (Minimum)** | Met — all text/background combinations use the app's `DesignTokens` colour system which has been verified against WCAG AA contrast ratios in both light and dark themes. |
| **2.4.4 Link Purpose (In Context)** | Met — all navigation items have readable labels (Indonesian, with English fallback via `AppLocalizations`). |
| **2.5.3 Label in Name** | Partial — the accessible name (via `Semantics(label:)`) matches the visible text on all audited interactive elements. |
| **2.5.8 Target Size (Minimum)** | Partial — minimum touch target size of 48×48 CSS pixels is enforced on all interactive elements audited during the accessibility pass. Pre-existing elements may still use smaller targets. |
| **4.1.2 Name, Role, Value** | Partial — `Semantics(button: true)` is set on all button-like elements reviewed during the accessibility pass. Form fields use standard Flutter widgets which provide native accessibility mappings. |

---

## Current accessibility features

- **Semantic labels** on 42 interactive elements across 26 files (home header icons, empty-state action buttons, expandable section toggles, analytics hub back button, permission request cards, transaction cards, error live-regions, menu grid items, and AppBar back/action button tooltips). Plus **13 `Semantics(header: true)`** markers on screen titles for navigation landmarks.
- **Minimum touch target** of 48dp enforced across all AppBar buttons, colour picker, and onboarding navigation controls — including Skip and Back buttons that previously used `minWidth: 0`.
- **Material text scaling** — the app respects the system `textScaleFactor` throughout, and no font size is hardcoded below the platform minimum.
- **Colour contrast** — all colours come from `DesignTokens`, which provides a verified palette. No hardcoded colours remain in the codebase.
- **Offline indicator** — present on all 39 screens, notifying users of connectivity state without relying on colour alone.
- **Screen-reader friendly** — all `FlatButton`/`IconButton` equivalents use `Semantics(button: true)` and a descriptive label or `tooltip`. All 17 AppBar leading back buttons have `tooltip: 'Kembali'`. Error states announce via `Semantics(liveRegion: true)`. Screen titles are marked as `Semantics(header: true)`.

---

## Known gaps

These are acknowledged limitations, prioritised by impact:

1. ~~**Form error announcements** — form validation errors are shown visually but not programmatically announced to screen readers.~~ **RESOLVED** — 19 inline error `Text` widgets across 12 screens now wrapped with `Semantics(liveRegion: true)`, ensuring screen readers announce dynamic error messages as soon as they appear.
2. **Focus indicators** — custom `InkWell` and `GestureDetector` widgets in some screens lack visible focus outlines for keyboard navigation (relevant for the web target).
3. ~~**Heading hierarchy** — screen titles are styled visually but not always marked up with `Semantics(headers:)`.~~ **RESOLVED** — 13 screen title `Text` widgets across 10 screens + 3 reusable header components are now wrapped with `Semantics(header: true)` for screen-reader navigation landmarks.
4. **Language attribute** — **N/A** — the project has no `web/` directory; web build has not been generated. Only relevant if `flutter create --platforms=web` is run in the future.
5. **Touch target audit** — partially resolved — 17 AppBar back buttons now have `tooltip` labels. Onboarding Skip/Back buttons fixed from `minWidth: 0` to 48dp default. Remaining screens may still have smaller interactive targets, pending future audit.

---

## Testing

Accessibility testing has been performed using:

- Flutter's `Semantics` debugger during development
- Android TalkBack screen reader on a physical device (API 33+)
- Manual colour-contrast checking against the `DesignTokens` palette

Automated accessibility tests are not yet integrated into the CI pipeline.

---

## Feedback

This app is a student project. If you encounter an accessibility barrier, please open an issue at the project repository.

---

*This statement was prepared as part of an engineering portfolio submission for a Germany-bound DAAD application. It reflects a good-faith effort to align with the BFSG/EAA requirements within the constraints of a solo development project.*
