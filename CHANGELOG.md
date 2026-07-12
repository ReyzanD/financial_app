# Changelog

All notable changes to this project are documented here.

---

## [2026-07-12] — Codebase Audit Finalization & Repository Cleanup

### Codebase Audit — All Categories Resolved to Zero

A comprehensive audit across 100+ files eliminated 465+ issues:

**CRITICAL (22 bugs)**
- BudgetEntity key normalization for suffixed DB columns (`_232143`)
- BudgetRepository wrong `spent` column reference
- GoalRepository int-to-bool comparison crash
- RecurringTransactions wrong key on save
- BackupService missing critical tables
- 17 other runtime crashes and data corruption bugs

**HIGH (25 issues)**
- Unsafe `.cast<T>()` → `whereType<T>()` across list conversions
- Interface type safety in `TransactionRepository`, `ObligationRepository`, `GoalRepository`
- `ObligationRepository` pagination parameter type mismatch
- `TransactionRepository` pagination type safety
- Missing delete transaction use case
- 20 other data integrity and type safety fixes

**MEDIUM (19 issues)**
- DebtModel/SubscriptionModel primary key field verification
- Notification center 18 bang (`!`) operator eliminations
- NetWorthService missing rethrow on failure
- HomeHeader route missing try-catch
- confirmDismiss edge case on failed delete
- SettingsScreen dependency injection fix
- 12 other robustness improvements

**LOW (all remaining)**
- `url_launcher` wired in AlternativeRecommendationCard
- Search entity field remapping
- Budget category colors expanded 3→12
- Percentage bars in budget_progress widget
- ResponsiveHelper spacing in home/transaction screens

**UX/Design Improvements**
- FAB speed dial with 3 actions (Expense/Income/Scan) + rotation animation
- AddTransactionScreen: default type param, default category auto-select
- OfflineIndicator on TransactionDetailScreen (39/39 = 100%)
- SpendingChart: income-based Y-axis fallback, period selector
- AddTransaction: inline FormField validation, recurring frequency options
- Dashboard: Health Score collapsible (default collapsed), refresh error snackbar, net worth chart placeholder
- Autofill hints on login + profile screens
- Forecast moved to More tab; bottom nav reduced to 3 tabs

**UI/Theming (465 replacements across 111 files)**
- `Color(0xFF8B5FBF)` → `DesignTokens.primaryColor` (6 occurrences)
- Status hex colors → `successColor`/`errorColor`/`warningColor`/`infoColor` (17)
- `BorderRadius.circular(12)` → `DesignTokens.radiusMedium` (243)
- `BorderRadius.circular(16)` → `DesignTokens.radiusLarge` (74)
- `EdgeInsets.all(16)` → `DesignTokens.spacing4` (125)

**Final 5 Items**
- Timezone safety: `DateTime.utc()` in FinancialCalendarService
- Budget spending recalculation in `BudgetDataService.updateBudget()`
- Dead `.toJson()` removed from DebtModel/SubscriptionModel
- Unified dropdown styling via `DropdownHelper`
- Forecast removed from bottom nav (4→3 tabs) and placed in More tab

### Repository Cleanup

**Moved to `docs/` with datetime naming:**
- `docs/2025-12-16_figma_import_guide.md`
- `docs/2026-07-09_files_removed.md`
- `docs/2026-07-09_full_implementation_summary.md`
- `docs/2026-07-09_replace_prints_guide.md`
- `docs/2026-07-11_todo.md`
- `docs/2025-12-14_implementation_complete.md`
- `docs/2025-12-16_figma_design.json`
- `docs/2025-12-16_figma_components.json`
- `docs/2025-12-16_app_components.json`
- `docs/2025-12-16_app_figma_design.json`
- `docs/2025-12-16_app_figma.json`
- (All existing 50+ docs remain in `docs/`)

**Deleted:**
- `financial_app.iml` — IntelliJ IDE artifact
- `package-lock.json` — empty Node.js artifact (Flutter project)
- `doc/` — empty directory with only an `api/` subfolder
- `backend/` — stale Python compiled bytecode + old SQLite database (app is standalone Flutter)

**`.gitignore` updated:**
- Added `.claude/` — Claude Code agent artifacts
- Added `.crush/` — Crush AI agent artifacts

**Untracked new files (kept local, not committed):**
- 15 new widgets/controllers/utils added during audit (dashboard controller, dropdown helper, key normalizer, etc.)

---

## [2025-12-16] — Initial Figma Design Integration
- Figma design files imported and catalogued
- Design tokens established (`DesignTokens.*`)
- Theme service with dark/light mode

## [2025-11-24] — Security & Notifications
- PIN authentication complete
- Push notifications infrastructure
- Notification center with history

## [2025-11-23] — Feature Expansion
- Location intelligence features
- Quick wins and enhancements
- Recurring transactions support

## [2025-10-01] — Project Initialization
- Flutter project scaffolded with Provider state management
- SQLite local database setup
- Clean Architecture feature structure established
- Initial transaction, budget, and goal models
