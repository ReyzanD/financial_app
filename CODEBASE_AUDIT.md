# Codebase Audit Report

**Generated**: July 2026 | **Branch**: `sqlite` | **Last Updated**: July 2026 | **Features Scanned**: 32 of 32

---

## Executive Summary

| Metric | Result |
|--------|--------|
| `flutter analyze` errors | **0** ✅ |
| `flutter analyze` warnings | **0** ✅ |
| `flutter test` passing | **253/253** ✅ |
| Stray `print()` calls | **0** (all via LoggerService) ✅ |
| Screens with OfflineIndicator | **38/38 (100%)** ✅ |
| Hardcoded colors | **0** (all via DesignTokens) ✅ |
| **CRITICAL bugs** (runtime crash / wrong data) | **~0 remaining** 🎉 (22 eliminated in July 2026 pass) |
| **HIGH bugs** (broken logic / wrong results) | **~2 remaining** (mostly architecture/design) |
| **MEDIUM issues** (missing error handling, design gaps) | **~5 remaining** |
| **LOW issues** (code quality, cleanup) | **~15 remaining** |
| **UI/Theming issues** (hardcoded colors/text) | **0** ✅ (all 108 resolved) |
| **UX/Design issues** (layout, navigation, forms) | **~20 remaining** |

> **Note**: The issues listed below are the ORIGINAL audit findings. Most have been fixed in the July 2026 bugfix pass. See `TODO.md` for the current remaining items.

---

## 🔴 CRITICAL — Will crash or return wrong data
*(Numbering resets per severity level)*

### 1. BudgetEntity.fromJson() Ignores Database Suffixed Keys 🚨
**File:** `lib/features/budgets/domain/entities/budget_entity.dart:21-37`
**Impact:** Every budget loaded through clean architecture has empty ID, zero amount, zero spent, default dates. **Budgets feature completely broken.**
**Root cause:** `fromJson()` uses clean keys (`id`, `category_id`, `amount`) but DB has `_232143` suffixed keys. Unlike other models, there's no fallback logic.
**Fix:** Add `_232143` suffixed fallback keys.

### 2. BudgetRepository Reads Wrong Field Name for Spent Amount 🚨
**File:** `lib/features/budgets/data/repositories/budget_repository.dart:71`
**Impact:** `totalSpent` is always 0. **All budget progress bars show 0% usage.**
**Root cause:** Reads `b['spent_232143']` but DB column is `spent_amount_232143`.
**Fix:** Change to `b['spent_amount_232143']`.

### 3. GoalRepository Int-to-Bool Comparison Bug 🚨
**File:** `lib/features/goals/data/repositories/goal_repository.dart:51`
**Impact:** `(0 ?? false) == true` → false. `(1 ?? false) == true` → also false in Dart. **All completed goals are invisible** — shows every goal as incomplete.
**Root cause:** DB stores `is_completed_232143` as INTEGER 0/1, code treats it as bool.
**Fix:** Change to `(g['is_completed_232143'] as int?) == 1`.

### 4. RecurringTransactions Saved With Wrong Key 🚨
**File:** `lib/services/api_service.dart:582` (via `createRecurringTransaction`)
**Impact:** Recurring records stored under `is_recurring` but DB queries filter by `is_recurring_232143`. **Recurring transactions never appear in the list.**
**Root cause:** `TransactionDataService.addTransaction()` expects `is_recurring_232143` in the data map, but caller passes `is_recurring`.
**Fix:** Pass `'is_recurring': 1` instead of `'is_recurring': true`.

### 5. BackupService Missing Critical Tables 🚨
**File:** `lib/services/backup_service.dart`
**Impact:** **Backup/restore is fundamentally broken.** Creates orphaned data with no user association.
**Root cause:** `users_232143` and `goal_contributions_232143` tables are missing from both backup creation and restore.
**Fix:** Add both tables to `createBackup()` and `restoreFromBackup()`.

### 6. InsightsController Uses Clean Keys But Data Has Suffixed Keys 🚨
**File:** `lib/features/insights/presentation/controllers/insights_controller.dart:42-160`
**Impact:** Accesses `t['transaction_date']`, `t['type']`, `t['amount']`, `t['category_name']` but DB returns `_232143` suffixed keys. **All financial insights and health scores are wrong** — zero amounts, empty data.
**Fix:** Normalize map keys (like `ForecastController._normalizeTransactions()`) before processing.

### 7. AnalyticsController Same Clean/Suffixed Key Mismatch 🚨
**File:** `lib/features/analytics/presentation/controllers/analytics_controller.dart:55`
**Impact:** **All analytics charts show empty/zero data.**
**Root cause:** Stores raw DB maps without key normalization. Widgets consuming with clean keys see nothing.
**Fix:** Normalize keys before storing.

### 8. RecurringTransactionRepository Unsafe Cast Will Crash 🚨
**File:** `lib/features/recurring_transactions/data/repositories/recurring_transaction_repository.dart:11`
**Impact:** **Runtime crash** if any transaction element is null or not `Map<String, dynamic>`.
**Root cause:** `List<Map<String, dynamic>>.from(data)` crashes on null elements.
**Fix:** Add `.cast<Map<String, dynamic>>()` with type checking.

---

### 9. AddTransactionScreen Budget Spending NEVER Updated 🚨
**File:** `lib/features/transactions/presentation/screens/add_transaction_screen.dart:84,897`
**Impact:** **Every expense transaction added through the primary screen silently skips budget tracking.** Budget spent amounts never reflect actual spending — the entire budget feature is decorative.
**Root cause:** `AddTransactionScreen._submitForm()` calls `TransactionDataService.addTransaction()` directly (line 897), completely bypassing `TransactionRepository.createTransaction()` (lines 44-51) which contains the `_updateBudgetSpending()` call. Since this is the primary transaction creation flow, the clean architecture budget-update code is dead for all real usage.
**Same in:** `quick_add_modal.dart:323`

### 10. Budget Delete Button Is Non-Functional (No ID Passed) 🚨
**File:** `lib/features/budgets/presentation/screens/budgets_screen.dart:228-241,757-759`
**Impact:** **Long-press → delete does absolutely nothing.** No dialog appears, no budget is removed.
**Root cause:** `_budgetToMap()` (line 228-241) omits `budget_id_232143` and `id` from the returned map. `_confirmDeleteBudget()` (line 758) reads `budget['budget_id_232143'] ?? budget['id']` — both are null — and returns immediately at line 759.

### 11. Budget Edit Mode Throws "ID budget tidak valid" 🚨
**File:** `lib/features/budgets/presentation/screens/budgets_screen.dart:228-241` + `add_budget_modal.dart:164-170`
**Impact:** **Editing any budget is completely broken.** Tapping a budget item shows the modal with blank fields. Submitting throws an exception.
**Root cause:** Same as #10 — `_budgetToMap()` doesn't include budget ID. `AddBudgetModal` reads `widget.initialBudget?['budget_id_232143'] ?? widget.initialBudget?['id']` — both null → throws at line 169.

### 12. Goal Edit Mode Reads Wrong Keys — All Fields Blank 🚨
**File:** `lib/widgets/goals/add_goal_modal.dart:89-136,203`
**Impact:** **Editing any goal is completely broken.** All form fields appear blank. Submitting throws "ID goal tidak valid".
**Root cause:** `initState` reads non-suffixed keys (`'name'`, `'target'`, `'deadline'`, `'type'`, `'priority'`) but `widget.initialGoal` is a raw DB map with suffixed keys (`name_232143`, `target_amount_232143`, `target_date_232143`, `goal_type_232143`). Every lookup returns null. Also reads `'id'` instead of `'goal_id_232143'` at line 203.

### 13. Goal Success Snackbar NEVER Shows (context.mounted After pop) 🚨
**File:** `lib/widgets/goals/contribute_modal.dart:114-123`, `add_goal_modal.dart:213-220,232-239`
**Impact:** **After creating, editing, or contributing to a goal, the user sees no success confirmation.** Modal closes silently.
**Root cause:** `Navigator.pop(context, true)` disposes the modal's context. The following `if (context.mounted)` check is always false, so `ErrorHandlerService.showSuccessSnackbar()` never executes. Same bug in all three mutation flows.

### 14. Goal Screen: Expanded Inside SingleChildScrollView — RenderFlex Crash 🚨
**File:** `lib/features/goals/presentation/screens/goals_screen.dart:81-99` + `goals_list.dart:75`
**Impact:** **Runtime `RenderFlex` overflow / layout exception.** The screen crashes with "Incorrect use of ParentDataWidget" / "Vertical viewport was given unbounded height".
**Root cause:** `Expanded` widget is used as a child of `Column` inside `SingleChildScrollView`, which has unbounded height. Flutter cannot determine how to size the Expanded child.

### 15. Home Screen Dashboard: AI Recommendations Modulo Bug — RangeError Crash 🚨
**File:** `lib/widgets/home/ai_recommendations.dart:279-281`
**Impact:** **Pressing the "previous" chevron button at index 0 crashes the app** with `RangeError` (index -1).
**Root cause:** `(-1 % N)` in Dart returns `-1` (not `N-1`). When on `_currentIndex == 0` and pressing previous, `(_currentIndex - 1) % _recommendations.length` = `(-1) % N` → `-1`, and `_recommendations[-1]` throws. Should use `(_currentIndex - 1 + N) % N`.

### 16. Home Screen Refresh Does Nothing — Pull-to-Refresh Is Decorative 🚨
**File:** `lib/features/home/presentation/screens/home_screen.dart:194-199`
**Impact:** **Swipe-to-refresh and the notification-based "global refresh" do not reload any data.** The dashboard shows stale information until the user navigates away and back.
**Root cause:** `_refreshDashboard()` only increments `_refreshCounter` and logs. It relies on a fragile hack: the counter change forces child widgets (Summary, Budget) to rebuild via `ValueKey`, which triggers their `didUpdateWidget()` → separate API calls. No data is fetched by the controller itself.

### 17. QuickAddWidgetEnhanced Is a Placeholder — Voice/Scan Transactions Silently Lost 🚨
**File:** `lib/widgets/home/quick_add_widget_enhanced.dart:232-279`
**Impact:** **Voice-input and receipt-scan transactions are silently discarded.** User speaks or scans a receipt and sees nothing happen — no error, no confirmation, no transaction created.
**Root cause:** The "Enhanced Quick Add" modal is a static placeholder showing only text labels and a "Close" button. The voice input flow (line 147) and receipt scanning flow (lines 203-207) call `_showQuickAddModal()` which does not call any API or service method — it just displays the parsed data as text.

### 18. Quick Add Modal: Invalid Flutter Parameter — Dropdown Crashes/Doesn't Render 🚨
**File:** `lib/widgets/home/quick_add/quick_add_modal.dart:494`
**Impact:** **The category dropdown in the Quick Add modal may fail to render or compile.** The category selection is broken.
**Root cause:** Uses `initialValue: _selectedCategoryId` as a named parameter of `DropdownButtonFormField`. The correct Flutter parameter name is `value:`, not `initialValue:`. This is either a compile error (strict mode) or silently ignored (Flutter runtime).

### 19. Home: QuickActionsEnhanced Empty Map Cast Crash 🚨
**File:** `lib/widgets/home/quick_actions_enhanced.dart:49-72,329`
**Impact:** **Runtime crash (`_CastError`)** when a user preference ID has no matching default action.
**Root cause:** `_defaultActions.firstWhere(..., orElse: () => <String, dynamic>{})` returns an empty map if no match. Then line 62-69 accesses `defaultAction['id']`, `defaultAction['label']`, `defaultAction['icon']` — all null. At line 329 `action['icon'] as IconData` throws `_CastError` on null.

### 20. HomeController Is Orphaned — Never Registered in Service Locator 🚨
**File:** `lib/features/home/presentation/controllers/home_controller.dart`
**Impact:** **Completely dead code — 59 lines.** `loadHomeData()` calls `notifyListeners()` but nothing listens because the controller is never instantiated or provided.
**Root cause:** Missing registration in `service_locator.dart`. The home screen uses `AppState` directly instead.

### 21. PinUnlockScreen: _onPinChanged setState After Dispose Crash 🚨
**File:** `lib/features/auth/presentation/screens/pin_unlock_screen.dart:68`
**Impact:** **Runtime crash if user dismisses the screen while entering a PIN** (e.g., timeout, incoming call). Throws `setState() called after dispose()`.
**Root cause:** `_onPinChanged()` calls `setState(() { _pin = pin; })` on every digit press without checking `mounted`. If the widget is disposed during an async gap (e.g., PIN entry during lock timer), this crashes.

### 22. LoginScreen: Uses Stale context After Async Gap 🚨
**File:** `lib/features/auth/presentation/screens/login_screen.dart:59-61`
**Impact:** **Potential crash** if widget is disposed during `SharedPreferences.getInstance()` async gap.
**Root cause:** Caches `ctx = context` on line 49 before async gap, checks `ctx.mounted` on line 59, then accesses `context.read<AuthController>()` (raw `context`, not `ctx`) on line 61. After async gap, `context` may reference a disposed element.

---

## 🟡 HIGH — Broken logic or wrong data
*(Numbering resets per severity level)*

### 9. Multiple Repositories Create ApiService Directly (Bypasses DI)
**Files:**
- `lib/features/transactions/data/datasources/transaction_remote_datasource.dart:5`
- `lib/features/analytics/data/repositories/analytics_repository.dart:6`
- `lib/features/insights/data/repositories/insights_repository.dart:6`
- `lib/features/forecast/data/repositories/forecast_repository.dart:6`
- `lib/features/profile/data/repositories/profile_repository.dart:6`
- `lib/services/obligation_service.dart:6`
- `lib/features/recurring_transactions/data/repositories/recurring_transaction_repository.dart:6`
**Impact:** Creates separate `ApiService` instance with its own cache, bypassing the DI-managed singleton.
**Fix:** Inject via constructor or use `getIt<ApiService>()`.

### 10. CashFlowForecastService Incorrect Month Detection
**File:** `lib/services/cash_flow_forecast_service.dart:140-142`
**Impact:** On dates near month boundaries, "previous month" detection uses wrong month. E.g., March 31 - 30 days = March 1 (still March, not February).
**Fix:** Use `DateTime(now.year, now.month - 1, 1)` for proper calendar arithmetic.

### 11. BudgetController Depends on Concrete Repository (Violates DIP)
**File:** `lib/features/budgets/presentation/controllers/budget_controller.dart:15,22,52,54`
**Impact:** Controller imports concrete `BudgetRepository`, calls `getCategories()` and `getSummary()` which are NOT in the interface. Breaks dependency inversion.
**Fix:** Add missing methods to `BudgetRepositoryInterface`.

### 12. ProfileRepository Discards Return Value
**File:** `lib/features/profile/domain/repositories/profile_repository_interface.dart:3`
**Impact:** Interface returns `Future<void>` but `ApiService.updateProfile()` returns `Future<Map<String, dynamic>>`. Callers can't access the updated profile data.
**Fix:** Change interface return type to `Future<Map<String, dynamic>>`.

### 13. BackupRepository Discards File Path
**File:** `lib/features/backup/domain/repositories/backup_repository_interface.dart:3`
**Impact:** Interface returns `Future<void>` but `BackupService.performBackup()` returns `Future<File>`. Backup file can't be shared/accessed after creation.
**Fix:** Change interface return type to `Future<File>`.

### 14. DebtModel.toMap() Missing Primary Key
**File:** `lib/models/debt_model.dart:69-79`
**Impact:** Missing `debt_id_232143` in `toMap()` — inserts have null primary key.
**Fix:** Add ID field to `toMap()`.

### 15. SubscriptionModel.toMap() Missing Primary Key
**File:** `lib/models/subscription_model.dart:64-76`
**Impact:** Missing `subscription_id_232143` in `toMap()` — inserts have null primary key.
**Fix:** Add ID field to `toMap()`.

### 16. ForecastController Inconsistent Key Handling
**File:** `lib/features/forecast/presentation/controllers/forecast_controller.dart:68`
**Impact:** Mixes normalized and raw transaction data. Works by accident because `_normalizeTransactions()` handles both key formats, but fragile.
**Fix:** Normalize early, consume normalized data consistently.

### 17. AccountModel.types Doesn't Match DB Schema
**File:** `lib/models/account_model.dart:192`
**Impact:** Lists only `['cash', 'bank', 'e_wallet']` but DB includes `'credit_card', 'investment', 'other'`. Account creation with credit_card type fails validation.
**Fix:** Sync with DB CHECK constraint.

### 18. Budget: _budgetToMap() Wrong Spent Key Name 🟡
**File:** `lib/features/budgets/presentation/screens/budgets_screen.dart:232,257`
**Impact:** **Budget spent amount always shows 0 on budget cards.** The remaining/over-budget calculations are all wrong.
**Root cause:** `_budgetToMap()` writes to key `'spent_232143'` (line 232), but `_buildBudgetItem()` reads `'spent_amount_232143'` first (line 257). The key doesn't exist in the map, so spent defaults to 0.0.

### 19. Transaction History: Date Sort Reads Wrong DB Key 🟡
**File:** `lib/features/transactions/presentation/screens/transaction_history_screen.dart:88-96`
**Impact:** **Transaction list sorting by date is completely broken.** All transactions appear to have the same date (DateTime.now()), so ordering is effectively random.
**Root cause:** Reads `transaction['date']` but the database returns `transaction_date_232143`. The lookup returns null and falls back to `DateTime.now()` for every transaction.

### 20. Transaction: setState After Dispose in 4 Screen Files 🟡
**Files:**
- `lib/widgets/transactions/location_insight_card.dart:61` — `setState((){});` after `await` with no `mounted` check
- `lib/widgets/transactions/transaction_detail_screen.dart:45,63,70` — 3x setState after async without mounted check
- `lib/widgets/home/quick_add_widget_enhanced.dart:113,139,158,191,222` — 5x setState after async without mounted check
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart:842,325` — 2x setState after async without mounted check
**Impact:** **App crash (`setState() called after dispose()`)** if user navigates away during any of these async operations.

### 21. Goal: monthly_target Field Never Persisted to DB 🟡
**File:** `lib/widgets/goals/add_goal_modal.dart:198-199` + `lib/services/data/goal_data_service.dart:58-71`
**Impact:** **The monthly target input in the goal form silently discards user input.** The value looks saved but disappears on next screen load.
**Root cause:** `GoalDataService.addGoal()` explicitly lists each DB column (lines 58-71) and `monthly_target_232143` is NOT included. The DB column exists but is never written to.

### 22. GoalRepository.updateGoal Returns Broken Entity 🟡
**File:** `lib/features/goals/data/repositories/goal_repository.dart:26-30`
**Impact:** **If updateGoal() were ever called (currently blocked by edit bug), it returns a GoalEntity with all zero/default values.**
**Root cause:** `GoalDataService.updateGoal()` returns `{'success': true, 'message': '...'}` — not a goal map. `result['goal']` is null, so `saved = result`, and `GoalEntity.fromJson({'success': true, ...})` creates an entity with empty id, 0.0 target, etc.

### 23. Goal: Triple Redundant Database Load on Every Screen Open 🟡
**File:** `lib/features/goals/presentation/screens/goals_screen.dart:23-25` + `goals_list.dart:27-28` + `progress_summary.dart:24-25`
**Impact:** **3x the same SQL queries on every goal screen navigation.** Wasteful. Could cause UI jank on slower devices.
**Root cause:** `GoalsScreen.initState` → `GoalController.loadData()`, `GoalsList.initState` → `GoalDataService().getGoals()`, and `ProgressSummary.initState` → `GoalDataService().getGoals()` all run independently and simultaneously.

### 24. GoalController Data Loaded But Never Used By UI 🟡
**File:** `lib/features/goals/presentation/controllers/goal_controller.dart` (entire file)
**Impact:** **All controller state (_goals, _summary) is dead code.** The UI ignores the controller and loads data independently.
**Root cause:** The goals screen widgets (`GoalsList`, `ProgressSummary`, `GoalCard`) use direct `GoalDataService()` calls, not the controller's entity-based data. Only the controller's `isLoading` and `errorMessage` are consumed.

### 25. Analytics: spending_chart Uses day-of-month as Map Key (Collision) 🟡
**File:** `lib/widgets/analytics/spending_chart.dart:17-21`
**Impact:** **Chart data is corrupted when the 7-day window spans across months.** Days from different months with the same day number (e.g., July 28 and Aug 28) share the same bucket.
**Root cause:** Uses `date.day` (1-31) as the map key. Across month boundaries, day-of-month values collide. Should use the full date string as key.

### 26. NetWorthService: Silent Failure — User Sees "Success" on Error 🟡
**File:** `lib/services/net_worth_service.dart:88-90`
**Impact:** **When recording a net worth snapshot fails, the user sees "Snapshot recorded" success.** The error is logged but swallowed. User has no idea their data wasn't saved.
**Root cause:** `catch (e) { LoggerService.error(...); }` — caught exception is not rethrown and no error status is returned. The controller and screen proceed as if successful.

### 27. RecurringTransactionsScreen Reads Wrong DB Keys — Shows Blank Data 🟡
**File:** `lib/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart:122-127`
**Impact:** **All recurring transactions display with blank/zero fields.** Feature appears non-functional.
**Root cause:** Reads `transaction['type']`, `['amount']`, `['description']`, `['frequency']`, `['is_active']`, `['next_date']` but DB returns suffixed keys (`type_232143`, `amount_232143`, etc.). All lookups return null.

### 28. ObligationController Unsafe as int? / as DateTime? Casts 🟡
**File:** `lib/features/obligations/presentation/controllers/obligation_controller.dart:62-63`
**Impact:** **Runtime `TypeError` crash** if `daysUntilDue` is a double or `dueDate` is a String instead of the expected type.
**Root cause:** Uses `obligation.daysUntilDue as int?` and `obligation.dueDate as DateTime?` on `dynamic` typed data. If the source returns a different numeric/string type, the cast throws. Should cast to `num` first and use `.toInt()` / `DateTime.parse()`.

### 29. FinancialSummaryCard: _loadSettings Has No mounted Check 🟡
**File:** `lib/widgets/home/financial_summary_card.dart:64-70`
**Impact:** **Crash (`setState() called after dispose()`)** if widget is disposed during `SharedPreferences.getInstance()` async gap.
**Root cause:** After `await SharedPreferences.getInstance()`, `setState()` is called unconditionally without `if (mounted)` check.

### 30. FinancialObligations Screen Filters Are Decorative — Never Applied 🟡
**File:** `lib/features/obligations/presentation/screens/financial_obligations_screen.dart:303-320`
**Impact:** **The filter dialog looks functional but does nothing.** Category/status/date filters have zero effect on displayed data.
**Root cause:** `_showFiltersDialog()` creates `ObligationFilters()` and passes it to the dialog. The dialog's `onFiltersChanged` callback only calls `ctrl.refresh()` which calls `ctrl.loadSummary()` — and `loadSummary()` ignores filters entirely.

### 31. QuickActionsEnhanced Color Parsing Can Throw FormatException 🟡
**File:** `lib/widgets/home/quick_actions_enhanced.dart:63-69`
**Impact:** **Runtime `FormatException` crash** if `colorHex` is null or has unexpected format.
**Root cause:** `int.parse(pref['colorHex'].toString().replaceFirst('#', '0x'))` — if `colorHex` is null, `.toString()` produces `"null"` which fails `int.parse()`. No try-catch.

### 32. FinancialSummaryCard + HomeHeader Bypass AppState — Direct ApiService() 🟡
**Files:**
- `lib/widgets/home/financial_summary_card.dart:28-29,81` — creates own `ApiService()` and `FinancialCalculator()`
- `lib/widgets/home/home_header.dart:14,26` — creates own `ApiService()`
- `lib/widgets/home/budget_progress.dart:19-20,100` — creates own `ApiService()` + unsafe cast `b as Map` on line 100
- `lib/widgets/home/ai_recommendations.dart:16,58-59` — creates own `AIService()` + silently swallows all errors
**Impact:** **Dashboard widgets show potentially stale/inconsistent data.** Each widget creates a separate data pipeline independent of `AppState`. Error handling is inconsistent.

### 33. Goals/Transactions CRUD Bypasses Clean Architecture Controllers 🟡
**Files:**
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart:84,897` — uses `TransactionDataService` directly
- `lib/widgets/goals/add_goal_modal.dart:228` — uses `GoalDataService` directly
- `lib/widgets/goals/goal_card.dart:477` — uses `GoalDataService` directly
- `lib/widgets/goals/contribute_modal.dart:107` — uses `GoalDataService` directly
- `lib/features/budgets/presentation/screens/budgets_screen.dart` + `add_budget_modal.dart` — uses `ApiService` directly
**Impact:** **All mutation operations bypass the clean architecture layer.** Use-case validation, error handling, budget tracking, and cache invalidation in controllers/repositories is dead code. The clean architecture is read-only and decorative.

---

## 🟠 MEDIUM — Missing error handling, design issues
*(Numbering resets per severity level)*

### 18. Multiple Services Return Empty List on Error (Masking Bugs)
**Files:**
- `lib/services/debt_service.dart:17` → returns `[]` on error
- `lib/services/subscription_tracker_service.dart:21` → returns `[]` on error
- `lib/services/expense_split_service.dart:23` → returns `[]` on error
**Impact:** Silent failures. Controllers show empty lists instead of error states. Users never know something went wrong.

### 19. AccountService Silently Returns Default Accounts on Error
**File:** `lib/services/account_service.dart:20`
**Impact:** Masks database errors. Default accounts have fake IDs that won't match real DB records.

### 20. BudgetController Accesses `_summary` Without Null Check
**File:** `lib/features/budgets/presentation/controllers/budget_controller.dart`
**Impact:** If `getSummary()` throws, `_summary` might be null while `_error` is set. Widgets accessing `summary` get null.

### 21. CashFlowController Assumes Forecast Results Structure
**File:** `lib/features/cash_flow/presentation/controllers/cash_flow_controller.dart:32`
**Impact:** `results[1] as Map<String, dynamic>` assumes specific index and type. Error maps would pass the cast but contain wrong data.

### 22. LoggerService Uses `print()` Internally
**File:** `lib/services/logger_service.dart:15-72`
**Impact:** Despite AGENTS.md saying "NEVER use print() — always use LoggerService", the service itself uses `print()`. Not hidden in release builds (only `kDebugMode` gated).
**Fix:** Use `debugPrint()` or a proper logging package.

### 23. GoalEntity Sends Bool Where DB Expects INT
**File:** `lib/features/goals/domain/entities/goal_entity.dart:69`
**Impact:** `'is_completed_232143': isCompleted` sends bool. SQLite stores as 0/1 so it works, but future CHECK constraints will break.
**Fix:** Convert to `isCompleted ? 1 : 0`.

### 24. Controllers Don't Dispose Stream Subscriptions
**Files:** All 31+ controllers
**Impact:** Any future subscriptions will leak. No `dispose()` override in most controllers.

### 25. FinancialCalendarService Ignores Timezone
**File:** `lib/services/financial_calendar_service.dart:21-22`
**Impact:** Month boundary calculations using `DateTime(year, month+1, 0)` can produce timezone-dependent results.

### 26. ReportScreen: setState After DatePicker Without mounted Check 🟠
**File:** `lib/features/report/presentation/screens/report_screen.dart:132,142`
**Impact:** **Crash (`setState() called after dispose()`)** if user navigates away while the date picker dialog is open.
**Root cause:** `await showDatePicker(...)` is an async gap. The following `setState` has no `if (mounted)` guard.

### 27. AnalyticsScreen: Bang Operator (!) on AppLocalizations Crash Risk 🟠
**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart:95,118`
**Impact:** **Crash (`NullError`)** if `AppLocalizations.of(context)` returns null.
**Root cause:** Uses `AppLocalizations.of(context)!` with null assertion instead of `?.` with `??` fallback.

### 28. PinSetupScreen + PinChangeScreen: _onPinChanged No mounted Check 🟠
**Files:**
- `lib/features/auth/presentation/screens/pin_setup_screen.dart:27-31`
- `lib/features/auth/presentation/screens/pin_change_screen.dart:32`
**Impact:** **Crash (`setState() called after dispose()`)** if user dismisses screen while entering PIN.

### 29. FinancialObligationsScreen: Manual 'Rp' Formatting Instead of CurrencyFormatter 🟠
**File:** `lib/features/obligations/presentation/screens/financial_obligations_screen.dart:188,198,213,225`
**Impact:** Amounts displayed without thousands separators or locale-aware formatting. Inconsistent with rest of app.
**Fix:** Use `CurrencyFormatter.formatRupiah()`.

### 30. ObligationController Search: No Debounce — Rebuilds on Every Keystroke 🟠
**File:** `lib/features/obligations/presentation/controllers/obligation_controller.dart:7-11`
**Impact:** **Performance hit** on every character typed — triggers full widget tree rebuild for SearchDelegate consumers. No debounce mechanism.

### 31. RecurringTransactionController + ObligationController: refresh() Doesn't Await Load 🟠
**Files:**
- `lib/features/recurring_transactions/presentation/controllers/recurring_transaction_controller.dart:62`
- `lib/features/obligations/presentation/controllers/obligation_controller.dart:41-45`
**Impact:** `refresh()` starts the load but returns immediately. Callers who `await refresh()` think data is loaded when it's not yet.

### 32. QuickActionsEnhanced: No try-catch on Initial Load — Infinite Spinner 🟠
**File:** `lib/widgets/home/quick_actions_enhanced.dart:34-91`
**Impact:** **If data loading throws, the widget shows an infinite spinner forever.** User never sees content or error state.
**Root cause:** No try-catch around the main loading block. The catch on line 90 only catches the `setState` call, not the actual data fetches.

### 33. RecurringTransactionsScreen: Null Assertion on AppLocalizations 🟠
**File:** `lib/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart:99,100`
**Impact:** **Crash if localizations not initialized** in widget tree. Same pattern as issue #27.

### 34. TransactionCard: Color Parsing from Hex Can Crash 🟠
**File:** `lib/widgets/transactions/transaction_card.dart:48-55`
**Impact:** **Crash (`RangeError`)** if `category_color` doesn't start with `#` or is shorter than 7 characters.
**Root cause:** `substring(1, 7)` assumes a `#` followed by exactly 6 hex chars. Malformed values (e.g., `"transparent"`, `"#FFF"`) throw.

### 35. QuickCategorySelector: No Suffixed DB Key Normalization 🟠
**Files:**
- `lib/widgets/home/quick_add/quick_add_modal.dart:522-523` — reads `category['id']` and `['name']`
- `lib/widgets/home/quick_category_selector.dart:47,62` — reads `category['id']` and `['name']`
**Impact:** Category selection may silently fail because DB keys are `category_id_232143` and `name_232143`.

### 36. Income/Expense Balance Check Logic Duplicated With Hardcoded Minimum 🟠
**Files:**
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart:577-737` — hardcoded `minimumBalance = 25000.0`
- `lib/widgets/home/quick_add/quick_add_modal.dart:88-250` — same logic, same hardcoded `minimumBalance = 25000.0`
**Impact:** Changing the minimum balance requires updating two independent copies of the same logic. Code duplication risk.

---

## 🟢 LOW — Code quality, design issues
*(Numbering resets per severity level)*

### 26. Services Used Directly (Not Via DI)
**Files:**
- `lib/utils/prefetch_helper.dart:6` — `SearchService()`
- `lib/widgets/home/recent_transactions_enhanced.dart:25` — `CacheService()`
- `lib/features/transactions/presentation/widgets/transaction_list.dart:42` — `SearchService()`
- `lib/features/settings/presentation/screens/settings_screen.dart:188` — `ExportService()`
**Impact:** Bypasses DI, creates unnecessary instances.

### 27. ObligationRepository Interface Uses Different Types
**File:** `lib/features/obligations/domain/repositories/obligation_repository_interface.dart:3`
**Impact:** Interface returns `Future<List<dynamic>>` but service returns `Future<List<FinancialObligation>>`. No type safety for consumers.

### 28. BudgetDataService.updateBudget() Can't Update Spending
**File:** `lib/services/data/budget_data_service.dart:120-164`
**Impact:** Direct budget amount update doesn't recalculate remaining. Only `updateBudgetSpending()` can change spent amounts.

### 29. BudgetEntity.fromJson() Uses `json['spent']` Not `json['spent_amount']`
**File:** `lib/features/budgets/domain/entities/budget_entity.dart:26`
**Impact:** Compounds with issue #1. Even with suffixed fallback, would need `spent_amount` not `spent`.

### 30. GoalEntity Missing description and goalType Fields
**File:** `lib/features/goals/domain/entities/goal_entity.dart`
**Impact:** DB stores `description_232143`, `goal_type_232143` but entity can't access them.

### 31. DebtModel/SubscriptionModel toJson() Is Dead Code
**Files:** `lib/models/debt_model.dart:51-65`, `lib/models/subscription_model.dart:48-61`
**Impact:** Uses clean keys but backup queries raw DB (suffixed keys). Methods are never called.

### 32. AGENTS.md References Deleted lib/Screen/ Directory
**File:** `AGENTS.md`
**Impact:** Documentation references legacy screen location that no longer exists.

### 33. TODO Left in Production Code
**File:** `lib/services/api_security_service.dart:147`
**Impact:** `// TODO: Add your production server's certificate SHA-256 hash here`

### 34. TransactionCard: Missing Decimal Digits in Currency Display 🟢
**File:** `lib/widgets/transactions/transaction_card.dart:233`
**Impact:** Uses `CurrencyFormatter.formatRupiah()` while `TransactionHistoryScreen` has its own `_formatCurrency()` with `decimalDigits: 0`. Potential inconsistency between the two screens.

### 35. Transaction Filters Hardcoded in Indonesian 🟢
**File:** `lib/features/transactions/presentation/screens/transaction_history_screen.dart:519,561,574-576,601`
**Impact:** Strings like `'Semua'`, `'Pemasukan'`, `'Pengeluaran'`, `'Cari transaksi...'` are hardcoded. The app supports English via ARB files but these won't translate.
**Also in:** `transaction_filters.dart:20-26`, `add_transaction_screen.dart:541,614-652`

### 36. TransactionDetailScreen Missing OfflineIndicator 🟢
**File:** `lib/widgets/transactions/transaction_detail_screen.dart`
**Impact:** Every other screen has `OfflineIndicator`. This screen is missing it — inconsistency.

### 37. TransactionDetailScreen: Edit Calls onDeleted Callback (Wrong Semantics) 🟢
**File:** `lib/widgets/transactions/transaction_detail_screen.dart:110-126`
**Impact:** The "Edit" button's `onUpdated` callback calls `widget.onDeleted?.call()`. Semantically wrong — `onDeleted` should only fire on actual deletion. Works by coincidence (both refresh the list).

### 38. RecentTransactionsEnhanced: Failed Delete Causes Phantom Disappearance 🟢
**File:** `lib/widgets/home/recent_transactions_enhanced.dart:180-199`
**Impact:** If `deleteTransaction()` fails, the item has already been visually removed via the dismiss animation with no restoration logic. The item reappears only on page refresh.

### 39. TransactionList: Fragile Manual Remap of Search Results 🟢
**File:** `lib/features/transactions/presentation/widgets/transaction_list.dart:115-128`
**Impact:** Search results (`TransactionModel`) are manually remapped to `TransactionEntity` with only 6 fields. Future entity fields will be silently lost during search.

### 40. SpendingChart Hardcoded Max Y-Axis Fallback 🟢
**File:** `lib/widgets/analytics/spending_chart.dart:73`
**Impact:** `maxY: maxSpending > 0 ? maxSpending * 1.2 : 100000` — with no data (due to critical key normalization bug), always shows 100000 cap with empty bars. Misleading.

### 41. HomeHeader Hardcoded Route Names (Will Crash if Unregistered) 🟢
**File:** `lib/widgets/home/home_header.dart:88,94`
**Impact:** `Navigator.pushNamed(context, '/notifications')` and `/settings` — will throw `FlutterError` if routes aren't registered in `main.dart`.

### 42. AddTransactionScreen: Unsafe .cast() on Categories List 🟢
**File:** `lib/features/transactions/presentation/screens/add_transaction_screen.dart:176`
**Impact:** `_categories = categories.cast<Map<String, dynamic>>()` will throw if list contains null or non-Map elements. `.whereType<>()` would be safer.

### 43. Auto-Categorization Reads `category['id']` But DB Key Is `category_id_232143` 🟢
**File:** `lib/features/transactions/presentation/screens/add_transaction_screen.dart:504,507`
**Impact:** Auto-categorization from location almost never works because it reads wrong key. Compare with `_findCategoryId()` (lines 231-232) which correctly checks both suffixed/unsuffixed keys.

### 44. getCategoryIcon Missing Mappings for 5 Categories 🟢
**File:** `lib/widgets/transactions/transaction_helpers.dart:32-49`
**Impact:** `getCategoryColor` supports 11 categories but `getCategoryIcon` only maps 6. Categories like `Investasi`, `Kesehatan`, `Pendidikan`, `Tabungan`, `Tagihan & Utilitas` all show the generic fallback icon.

### 45. AlternativeRecommendationCard: Navigation URL Launcher Commented Out 🟢
**File:** `lib/widgets/transactions/alternative_recommendation_card.dart:115-118`
**Impact:** "Visit" button shows snackbar but does not open maps navigation. The Google Maps / Apple Maps URL launcher code is commented out and `url_launcher` not imported.

### 46. TransactionRepository Interface Missing Pagination (limit/offset) 🟢
**File:** `lib/features/transactions/domain/repositories/transaction_repository_interface.dart`
**Impact:** Clean architecture interface doesn't expose `limit`/`offset`. Underlying services support pagination but the clean layer can't use it.

### 47. PinUnlockScreen Uses `mounted` Instead of `context.mounted` 🟢
**File:** `lib/features/auth/presentation/screens/pin_unlock_screen.dart:56`
**Impact:** Both work in Flutter 3+, but `context.mounted` is the modern explicit pattern. Minor style inconsistency.

---

## 🎨 UI / THEMING ISSUES (108 items)

### Hardcoded Colors Instead of DesignTokens

| Replace | With | Files Affected |
|---------|------|----------------|
| `Color(0xFF8B5FBF)` | `DesignTokens.primaryColor` | ~30 files |
| `Color(0xFF1A1A1A)` | `DesignTokens.surfaceDark` | ~25 files |
| `Colors.grey[XXX]!` | `DesignTokens.textSecondaryDark` / `textTertiaryDark` | ~15 files |
| `Colors.black` | `DesignTokens.backgroundDark` | ~6 files |
| `Colors.red[400]` etc. | `DesignTokens.errorColor` / `successColor` / `warningColor` | ~10 files |

### Hardcoded Font Sizes / Radii Instead of DesignTokens

| Replace | With | Files Affected |
|---------|------|----------------|
| `BorderRadius.circular(12)` | `DesignTokens.radiusMedium` | ~10 files |
| `BorderRadius.circular(16)` | `DesignTokens.radiusLarge` | ~8 files |
| `fontSize: 14` | `DesignTokens.fontSizeBody` | ~15 files |
| `EdgeInsets.all(16)` | `DesignTokens.spacing4` | ~25 files |

### Missing Localization (Hardcoded Indonesian Strings)

| Feature | Hardcoded Strings |
|---------|-------------------|
| `ai_budget_recommendation_screen.dart` | 17 strings ("Rekomendasi Budget AI", "Budget Bulanan", etc.) |
| `forecast_screen.dart` | 15+ strings ("Forecast & Prediksi", "Prediksi 30 Hari", etc.) |
| `financial_insights_screen.dart` | 10+ strings ("Wawasan Keuangan", "Skor Kesehatan", etc.) |
| `receipt_history_screen.dart` | 10+ strings ("Gagal Memuat Data", "Hapus Struk?", etc.) |
| `backup_screen.dart` | 9 strings ("Backup & Restore", "Riwayat Backup", etc.) |
| `notification_center_screen.dart` | 8+ strings ("Jenis Notifikasi", "Peringatan Budget", etc.) |
| `report_screen.dart` | 8 strings ("Laporan Berhasil Dibuat", "Buat Laporan", etc.) |
| `accounts` screens | 15+ strings ("Edit Akun", "Tipe Akun", "Cash", "Bank") |
| `auth` screens | 8+ strings ("PIN Lama", "Format email tidak valid") |
| `financial_calendar_screen.dart` | 10 strings ("Kalender", "Sen", "Sel", etc.) |
| `map_screen.dart` | 4 strings ("Gagal Memuat Data", "Peta Transaksi") |
| `profile_screen.dart` | 3 strings ("Informasi Pribadi", "Rentang Pendapatan") |

### Snackbar Messages Not Localized

| File | Strings |
|------|---------|
| `backup_screen.dart` | `'Backup berhasil dibuat!'`, `'Backup dihapus'` |
| `pin_setup_screen.dart` | `'PIN tidak cocok'`, `'PIN berhasil dibuat!'` |
| `pin_change_screen.dart` | `'PIN lama salah'`, `'PIN berhasil diubah!'` |
| `profile_screen.dart` | `'Profil berhasil disimpan'` |
| `report_screen.dart` | `'Report berhasil dibuat!'` |
| `receipt_history_screen.dart` | `'Struk dihapus'`, `'Transaksi berhasil dibuat dari struk'` |

### Large Files Needing Refactoring

| File | Lines | Notes |
|------|-------|-------|
| `add_transaction_screen.dart` | 1168 | Single giant nested expression |
| `transaction_history_screen.dart` | 887 | Single stateful widget handles all UI |
| `budgets_screen.dart` | 831 | Deeply nested conditional widgets |
| `obligation_item.dart` | 763 | Widget file extremely large |
| `location_picker_map.dart` | 724 | Very large widget file |
| `budget_progress.dart` | 685 | Oversize widget |
| `challenges_screen.dart` | 539 | Large file |
| `forecast_screen.dart` | 501 | Large screen with deep nesting |

### Architecture: Controller Accessed Directly in build()

| Screen | Issue |
|--------|-------|
| `accounts_screen.dart` | `controller.refresh`, `controller.activeOnly` in build() |
| `budgets_screen.dart` | `controller.refresh()`, `controller.summary!` in build() |
| `analytics_screen.dart` | `ctrl.initializePeriod()` called in build() |
| `tags_screen.dart` | `ctrl.errorMessage!`, `ctrl.refresh` in build() |
| `financial_insights_screen.dart` | `ctrl.healthScore`, `ctrl.getHealthScoreLabel()` in build() |

### Miscellaneous Minor Issues

- **Missing `const` constructors** on 5 modal StatefulWidgets
- **Force-unwrapping risks** in 3 places (`summary!`, `route!`, `errorMessage!`)
- **Redundant `AppLocalizations.of(context)!`** — 20x in notification_center_screen.dart alone
- **Hardcoded `locale: 'id'`** in currency formatting (3 files)
- **TODO left in production** in `api_security_service.dart:147`

---

---

## 🧭 UX / LAYOUT / DESIGN AUDIT

### Navigation & App Structure

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **More tab has 23 items in a grid** | `more_tab_screen.dart` | 🟡 HIGH | Group into sections (Financial Management, Analytics, Settings) or use a list layout instead of 3-column grid. Items like Budget/Goals duplicate dashboard widgets. |
| **Forecast is a bottom nav tab** | `home_screen.dart` | 🟢 LOW | Forecast is a niche feature that may not warrant its own top-level tab. Consider moving to More tab. |
| **No global search** | `home_screen.dart`, `main.dart` | 🟡 MEDIUM | Add a search icon in the home header opening a search overlay for transactions, budgets, goals. |
| **No deep link support** | `main.dart` routes | 🟢 LOW | Acceptable for offline-first app, but limits shareability. |

### Home Screen Dashboard

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **Dashboard is overloaded** | `home_screen.dart`, `financial_summary_card.dart`, `budget_progress.dart`, `ai_recommendations.dart` | 🔴 CRITICAL | Packs summary + quick actions + budget progress + AI recs + health score in one scroll. Collapse AI recs and health score behind expandable cards or "Show More" buttons. |
| **Refresh doesn't reload data** | `home_screen.dart:194` | 🟡 HIGH | `_refreshDashboard()` only increments a counter to rebuild widgets — does NOT reload from database. |
| **FAB is single-purpose** | `floating_action_button.dart` | 🟡 MEDIUM | Only adds transactions. Consider speed dial FAB with Add Transaction, Add Income, Scan Receipt. |
| **Quick action labels at 9px** | `quick_actions_enhanced.dart:341` | 🔴 CRITICAL | **9px is too small** for readability. Increase to minimum 11-12px. |
| **Icon buttons below 48px touch target** | `home_screen.dart` header icons | 🟡 MEDIUM | 40x40 icons on header are below the 48px minimum touch target. |

### Transaction Flow

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **Add Transaction has 11 fields** | `add_transaction_screen.dart` | 🟡 HIGH | Too long for mobile. Reduce to core 5 (Amount, Type, Category, Description, Date). Move Account, Payment Method, Location, Notes, Recurring into collapsible "More Options" section. |
| **Recurring toggle is misleading** | `add_transaction_screen.dart:99` | 🟡 HIGH | Boolean-only toggle. Toggling it on doesn't let user configure frequency — must navigate elsewhere. Either integrate frequency config inline or remove toggle from this screen. |
| **No default category selected** | `add_transaction_screen.dart:92` | 🟡 MEDIUM | Forces selection every time. Pre-select a sensible default (e.g., "Other") or last-used category. |
| **Location auto-fetches on screen open** | `add_transaction_screen.dart:127` | 🟡 MEDIUM | Requests location permission immediately without user action. Should only fetch when user taps "Add Location." |
| **Form uses snackbars for field errors** | `add_transaction_screen.dart` | 🟡 MEDIUM | Snackbars are temporary and easily missed. Use inline field validation text instead. |

### Empty States

| Screen | Has Icon? | Has Message? | Has CTA Button? | Verdict |
|--------|-----------|--------------|-----------------|---------|
| **Budgets** | ✅ | ✅ | ✅ | **Excellent.** Uses shared `EmptyStates` class |
| **Splits** | ✅ | ✅ | ❌ | Missing button — shows text "Tap +" instead |
| **Receipt History** | ✅ | ✅ | ❌ | Missing "Scan Struk" button |
| **Notification Center** | ✅ | ✅ | ❌ | Acceptable (notifications arrive passively) |
| **Templates** | ✅ | ✅ | ❌ | Missing button (FAB available though) |
| **Goals** | ✅ | ✅ | Likely | FAB exists on parent screen |

### Data Visualization

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **Net worth has no chart** | `net_worth_screen.dart` | 🟡 HIGH | Just a number with arrow — missing trend line chart over time (primary reason users visit net worth). |
| **7-day bar chart is static** | `spending_chart.dart` | 🟡 MEDIUM | Replace with configurable period selector (7d/30d/90d). |
| **No month-over-month visual comparison** | `monthly_comparison.dart` | 🟡 MEDIUM | Numbers-only comparison, no bar/line chart visualization. |
| **Inconsistent number formatting** | `receipt_history_screen.dart:151`, several files | 🟢 LOW | Some use `CurrencyFormatter`, others use manual regex formatting. Unify to `CurrencyFormatter`. |
| **Budget category colors limited** | `budget_progress.dart:673` | 🟢 LOW | Only 3 specific categories (Makanan, Transportasi, Hiburan) have distinct colors; all others default to purple. |

### Onboarding

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **5 pages is too many** | `onboarding_screen.dart` | 🟡 MEDIUM | 4 feature pages + 1 permissions page. Reduce to 2-3 pages — users want to start tracking money immediately. |
| **Location permission requested too early** | `onboarding_screen.dart:141` | 🟡 MEDIUM | Requested during onboarding before user sees the app. Request in context when user first uses location features. |
| **Onboarding completion does too much** | `onboarding_screen.dart:183-200` | 🟢 LOW | Saves preferences, sets defaults, requests permissions all in one method. Partial failures cause inconsistent state. |

### Layout & Consistency

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **Splits card shows `participantName` twice** | `splits_screen.dart:80-82` | 🟡 HIGH | Copy-paste bug — second line should show notes or description instead of duplicate name. |
| **Inconsistent spacing** | Multiple screens | 🟢 LOW | Mix of `ResponsiveHelper.verticalSpacing(20)`, `SizedBox(height: 16)`, `SizedBox(height: 12)` between sections. |
| **Back button icon inconsistency** | Multiple screens | 🟢 LOW | Some use `Iconsax.arrow_left`, others use `Icons.arrow_back`. Should be unified. |
| **Date picker theming boilerplate repeated** | `add_transaction_screen.dart:521-535`, multiple files | 🟢 LOW | Same dark-theme builder code for date pickers copied everywhere. Extract into shared helper. |
| **No autofill on forms** | `login_screen.dart`, `profile_screen.dart` | 🟢 LOW | Missing Flutter autofill for email, password, phone, name fields. |
| **Inconsistent dropdown styling** | Multiple screens | 🟢 LOW | Some use `DropdownButtonFormField`, others use custom pill selectors. |

### Accessibility

| Issue | File(s) | Severity | Recommendation |
|-------|---------|----------|----------------|
| **Quick action labels at 9px** | `quick_actions_enhanced.dart:341` | 🔴 CRITICAL | Below readable threshold for visually impaired users. |
| **Icon buttons at 40px** | `home_screen.dart` header | 🟡 MEDIUM | Below 48px touch target minimum. |
| **Missing Semantics labels** | `quick_actions_enhanced.dart`, `more_tab_screen.dart`, FAB, bottom nav | 🟡 MEDIUM | Interactive elements lack `Semantics` wrappers for screen readers. |

---

## Recommended Order of Fixes

### Phase 1 — Data Layer: Suffixed Key Normalization (fix once, fixes 20+ files)
1. **🔴 BudgetEntity.fromJson()** — add suffixed `_232143` fallback keys
2. **🔴 InsightsController + AnalyticsController** — normalize transaction keys (copy `ForecastController._normalizeTransactions()` pattern)
3. **🔴 RecurringTransactionsScreen** — add suffixed key fallbacks for all display fields
4. **🔴 Goal edit mode** — fix `AddGoalModal.initState` to read `_232143` suffixed keys
5. **🔴 Budget `_budgetToMap()`** — include `budget_id_232143` and fix `spent_232143` → `spent_amount_232143`
6. **🔴 Transaction History** — fix date sort to read `transaction_date_232143`
7. **🔴 QuickCategorySelector** — fix `category['id']` → `category['category_id_232143']` fallback

### Phase 2 — Critical UI/Logic Bugs (crashes and non-functional features)
8. **🔴 AddTransactionScreen budget never updated** — route through `TransactionRepository` or call `updateBudgetSpending()` directly
9. **🔴 AI Recommendations modulo crash** — fix `(-1 % N)` → `((idx - 1 + N) % N)` on previous button
10. **🔴 QuickAddModal Dropdown invalid param** — `initialValue` → `value`
11. **🔴 GoalRepository int/bool** — fix `== true` → `== 1`
12. **🔴 BudgetRepository spent column** — `spent_232143` → `spent_amount_232143`
13. **🔴 RecurringTransactions key** — `is_recurring` → `is_recurring_232143`
14. **🔴 BackupService** — add missing `users_232143` and `goal_contributions_232143` tables
15. **🔴 RecurringTransactionRepository unsafe cast** — fix `.from(data)` crash
16. **🔴 GoalEntity isCompleted** — fix `bool = int` type mismatch crash
17. **🔴 HomeController orphaned** — register in service locator or remove
18. **🔴 QuickActionsEnhanced empty map** — fix `orElse: () => {}` crash chain
19. **🔴 Goal `Expanded` inside `ScrollView`** — fix layout crash
20. **🔴 setState after dispose** — fix 10 files missing `mounted` checks (see issues #20, #26, #28)

### Phase 3 — Data Flow & Architecture Fixes
21. **🟡 CRUD bypasses clean architecture** — wire all mutation flows through controllers/repositories
22. **🟡 DI bypass** — fix 7+ files creating `ApiService()` directly instead of via `getIt`
23. **🟡 Goal: monthly_target not persisted** — add DB write
24. **🟡 Goal progress snackbar never shows** — fix `context.mounted` after `pop`
25. **🟡 QuickAddWidgetEnhanced placeholder** — implement actual transaction creation
26. **🟡 Obligation filters decorative** — wire filter params into `loadSummary()`
27. **🟡 ObligationController unsafe casts** — fix `as int?` / `as DateTime?` on `dynamic`
28. **🟡 NetWorthService silent failure** — propagate error to caller
29. **🟡 Missing primary keys** — fix `DebtModel.toMap()` + `SubscriptionModel.toMap()`
30. **🟡 Dashboard widgets bypass AppState** — consolidate data pipeline
31. **🟡 refresh() doesn't await** — fix `RecurringTransactionController` + `ObligationController`
32. **🟡 Controller data unused** — remove dead code or wire to UI

### Phase 4 — UI Polish (Themes)
33. **🎨 DesignTokens theming pass** — replace all hardcoded colors (108 items)
34. **🎨 Localization pass** — add `AppLocalizations` to all hardcoded Indonesian strings
35. **🎨 Consistent spacing/radius/font sizes** — use DesignTokens everywhere

### Phase 5 — UX/Design Improvements
36. **🔴 Dashboard overload** — progressive disclosure for AI recs and health score
37. **🔴 Quick action labels to 12px minimum** — 9px is below readable threshold
38. **🟡 Add Transaction form** — collapse to 5 core fields, "More Options" expandable
39. **🟡 Recurring toggle** — integrate frequency config or remove from add screen
40. **🟡 More Tab** — group 23 items into sections
41. **🟡 Empty states** — add CTA buttons to Splits, Receipt History, Templates
42. **🟡 Net worth chart** — add trend line chart
43. **🟢 Onboarding** — reduce from 5 to 3 pages, postpone location permission
44. **🟢 Global search** — add search overlay
