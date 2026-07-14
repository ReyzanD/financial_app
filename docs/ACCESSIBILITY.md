# Accessibility Statement

**App:** Financial App (local SQLite, offline-first finance manager)  
**Last updated:** July 2026  
**Compliance target:** European Accessibility Act (EAA) / German Barrierefreiheitsstärkungsgesetz (BFSG)

---

## 1. Commitment

This application is designed to be usable by people with a wide range of abilities.
As the developer, I recognise that accessibility is a legal and ethical
responsibility, especially for financial-management software which the German
BFSG explicitly names as in-scope (effective June 28, 2025).

This statement documents current conformance, known gaps, and the roadmap toward
full WCAG 2.1 AA compliance.

---

## 2. Current accessibility features

### 2.1 Touch targets

- All interactive elements meet or exceed the Material Design minimum of
  **48 × 48 dp** (`DesignTokens.touchTargetMin`).
- A reusable `ensureTouchTarget` helper in `AccessibilityHelper` wraps widgets
  that would otherwise fall below this threshold.

### 2.2 Colour contrast

- A `getContrastRatio` / `meetsWCAGAA` pair in `AccessibilityHelper` validates
  foreground–background pairs against WCAG 2.1 thresholds (4.5:1 for normal
  text, 3:1 for large text).
- `getAccessibleTextColor` selects white or black text automatically based on
  the background colour to maximise contrast.
- The `DesignTokens` colour palette was chosen with dark-theme-first contrast
  in mind; typical text–surface pairs (`textPrimaryDark` on `surfaceDark`)
  exceed the 4.5:1 ratio.

### 2.3 Screen-reader support (Semantics)

The following widgets carry explicit `Semantics` annotations:

| Location | Element | Label |
|----------|---------|-------|
| Home FAB | Add / quick-action buttons | "Tambah Transaksi", "Riwayat Resi" |
| Quick actions grid | Each action tile | Visible label text |
| More tab grid | Each menu tile | `item.label` |
| Accounts list | Each account card | Account name + balance |
| Budgets list | Each budget card | Budget name + progress |
| Error state | Retry button | "Coba Lagi" |
| Permission request card | Grant / deny buttons | Action + permission name |

### 2.4 Theme and text scaling

- The app supports both light and dark themes, toggled by the user or following
  the system setting (`ThemeMode.system`).
- A `textScaler`-aware `getAccessibleFontSize` helper limits the effective
  scaling factor to 1.5× to prevent layout breakage at extreme sizes.
- The `ResponsiveHelper` `fontSize()` method accounts for both device size and
  the user's text-scale preference.

### 2.5 Keyboard and gesture independence

- All navigation is available through `Navigator.pushNamed` routes — no
  gesture-only interactions.
- Pull-to-refresh is supplemented by a refresh button on every screen that uses
  it.
- Modal bottom sheets (add transaction, add budget, etc.) can be dismissed with
  a back-gesture or the system back button.

---

## 3. Tested configurations

| Configuration | Status |
|---------------|--------|
| TalkBack (Android 14) — home screen navigation | ✅ |
| TalkBack — transaction list scrolling | ✅ |
| TalkBack — add-transaction form (text fields) | ✅ |
| High-contrast text mode | ⚠️ Partially tested |
| Font scale 1.5× | ⚠️ Partially tested |
| Keyboard-only navigation | ❌ Not tested |
| Switch Access | ❌ Not tested |
| VoiceOver (iOS) | ❌ Not tested (no iOS device) |

---

## 4. Known gaps and roadmap

These are ordered by priority for the next development cycles:

| Priority | Issue | Target fix |
|----------|-------|------------|
| **High** | Transaction list items lack `Semantics` — screen-reader users hear unlabelled containers when browsing past transactions. | Add `Semantics(label: ..., button: true)` wrapper to each transaction card in `lib/widgets/transactions/transaction_card.dart`. |
| **High** | Dashboard financial summary card (income / expense / balance figures) has no semantic label — values are announced as raw numbers without context. | Wrap each summary figure in `Semantics(label: 'Pemasukan: …')`. |
| **Medium** | Budget progress bars render as unlabelled containers. | Add `Semantics(value: ..., increasedValue: ..., decreasedValue: ...)` to progress indicators. |
| **Medium** | Charts in Analytics / Insights tabs (`fl_chart`) have no `Semantics` — chart data is invisible to screen readers. | Use `fl_chart`'s built-in `BarTouchData` / `LineTouchData` with `Semantics` tooltip builders. |
| **Low** | Modal bottom sheets lack focus trapping — after dismissal, focus may return to an unexpected element. | Add `TraversalEdgeBehavior` or test with TalkBack. |
| **Low** | No formal screen-reader testing on iOS (VoiceOver). | Test when an iOS device is available. |

**Target:** WCAG 2.1 AA for all screens in the reviewer-facing flow (home
dashboard, transaction history, analytics hub) by the end of Phase 1.5c.

---

## 5. Feedback

If you encounter an accessibility barrier while using this app, please open a
GitHub issue or contact the developer directly. I am committed to responding
within 14 days and resolving confirmed barriers within the next development
cycle.

---

## 6. Declaration of conformity (preliminary)

This application is **partially conformant** with WCAG 2.1 Level AA as of July
2026. Partial conformance is claimed for the reviewer-facing screens listed in
§4 above; the remaining screens will be brought into conformance during the
next development phases.

The German Barrierefreiheitsstärkungsgesetz (BFSG), which transposes the
European Accessibility Act (Directive 2019/882) into national law, applies to
financial-services software made available after June 28, 2025. This project is
a student portfolio application, not a commercial product, but I have chosen to
align with the EAA/BFSG requirements as a demonstration of inclusive
engineering practice.

Signed,

*Developer*  
July 2026
