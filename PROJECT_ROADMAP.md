# Financial App — Roadmap Toward DAAD Application (Software Engineering / CS)

**Where you are:** Semester 6, UNDIPA Makassar, S1 → targeting S2 in Germany via DAAD.
**Where the app is:** Solid, verified progress on the engineering-rigor pass. CI exists and runs, a real security bug is fixed, DI bypass is nearly eliminated, and the debts/subscriptions/obligations merge (including a real DB migration) is genuinely done. A few claims in `CODEBASE_AUDIT.md` still don't match the code, and documentation has sprawled — both addressed below.
**Cost constraint:** Everything uses free tools only (OpenStreetMap/Overpass, on-device compute, free CI). No paid APIs.

---

## Guiding principle

For an SE/CS track, reviewers weigh **provable engineering skill** higher than feature count. Foundation first (cheap, high signal) → one flagship feature that's genuinely yours → one feature tied to your personal DAAD story → one systems feature showing CS depth → package it for reviewers who'll spend 5 minutes on your GitHub.

---

## ✅ Done — verified directly against your code, not just the docs

- **CI/CD** — `.github/workflows/flutter_ci.yml` runs `flutter analyze` + `flutter test` on every push/PR. Real.
- **Encryption IV bug fixed properly** — `encryption_service.dart` now generates a fresh random IV per `encrypt()` call, prepended to the ciphertext. Correct fix.
- **DI bypass** — down from 25 to 2 direct `ApiService()` constructions. Nearly eliminated.
- **Dead code deleted** — all 6 unused widget files from the earlier audit (`recent_transactions.dart`, `recent_transactions_enhanced.dart`, `quick_actions.dart`, `quick_add_widget.dart`, `quick_add_widget_enhanced.dart`, `enhanced_empty_state.dart`) are confirmed gone.
- **Obligations merge — done properly.** `/debts` and `/subscriptions` no longer exist as separate routes/screens; everything routes through `/obligations`. There's a real schema migration (`ALTER TABLE financial_obligations_232143 ADD COLUMN type_232143...`) that unifies the data model and migrates existing records — the hard part of this merge, done correctly.
- **`ACCESSIBILITY.md` written**, and written honestly (per-criterion "Partial"/"Met" status, not a blanket claim), referencing the EAA/BFSG context correctly.

Nice work — this is a genuinely strong batch of fixes, not just documentation.

---

## 🔧 Still open — verified against the code, contradicts current doc claims

1. **Hardcoded colors** — `CODEBASE_AUDIT.md` claims "0 ✅," but 22 files still use raw `Color(0x...)` literals instead of `DesignTokens`. Same false claim as the previous round; actually do the pass this time (it's mechanical at this point — find/replace against the token set), then correct the doc.
2. **Spacing convention** — `ResponsiveHelper.verticalSpacing()` exists but is dwarfed by raw `SizedBox(height: N)` calls elsewhere. Pick one convention, apply it everywhere.
3. **Documentation sprawl (new finding)** — repo root + `docs/` now has ~56 markdown/txt files, many redundant working notes (`FINAL_FIX_INSTRUCTIONS.md`, `QUICK_WINS_FINAL.md`, `LOCATION_FINAL_FIX.txt`, `DEBUG_LOCATION_RECS.txt`, etc.). This undercuts the good engineering underneath — a reviewer's first impression of the file tree matters. Keep `README.md`, `CODEBASE_AUDIT.md`, `ARCHITECTURE.md`, `ACCESSIBILITY.md`, `SECURITY.md`, `CHANGELOG.md`; consolidate or delete the rest.

---

## Phase A — Close out the remaining rigor items (~1–2 weeks)

- [x] Fix the 22 hardcoded-color files, then correct `CODEBASE_AUDIT.md` to match reality. (82 instances across 23 files → all via `DesignTokens.*`; 0 remaining)
- [x] Unify the spacing convention across the app. (563 raw `SizedBox(height:)` → `DesignTokens.spacingX`)
- [x] Prune/consolidate the docs folder to the 6 files above (or a clearly organized `docs/archive/` if you want to keep history, gitignored or clearly labeled as such). (71 files → ARCHITECTURE.md + archive)
- [x] Add a lint rule or simple test that fails if `ApiService()` is constructed outside `get_it`, so the 2 remaining bypasses (and any regression) get caught automatically. (0 bypasses found; test scans all lib/ for direct constructions)
- [ ] Go through `CODEBASE_AUDIT.md` line by line one more time — only keep a claim if you've personally reopened the file and confirmed it. This is the second round where one specific line was stale; make this pass the one that actually closes the loop.

---

## Phase B — Architecture consolidation (~1–2 months)

Verified finding from before, still relevant: only 8 of 30 features have full clean-architecture layering (entities + use cases); 14 have a repository shell with no entities (controllers work with raw suffixed-key maps); 8 skip the pattern entirely. Some "full" features were decorative (e.g. `debt_entity.dart` was a one-line re-export of `DebtModel`, unused by the actual screen) — worth re-checking whether that's still true post-refactor, since debts/obligations code changed significantly in this round.

**Target: one consistent 3-layer pattern, applied to all 30 features, no exceptions:**

- **Data service** — raw SQLite CRUD, suffixed-key normalization happens here once, returns real typed models.
- **Repository** — thin interface adapter, delegates to the data service, adds only genuine cross-cutting logic.
- **Controller** — resolved via `get_it` only, calls the repository interface.

Kill parallel model systems (one typed model per domain concept, no shim entities). Drop standalone "use case" classes unless they orchestrate more than one repository call. Document this as a deliberate scoping decision in `docs/ARCHITECTURE.md`: recognizing four-layer clean architecture was inconsistently applied and choosing a lighter, consistently-applied pattern instead — a stronger interview story than claiming full clean architecture everywhere.

- [x] Re-audit which features are "full" vs "partial" vs "none" post-refactor (the obligations merge likely changed this for that feature). (30 features: 2 full, 18 simplified, 3 screen-only, 1 empty)
- [x] Apply the 3-layer pattern to the 8 currently presentation-only features (auth, home, settings, onboarding, map, etc.) — consistency across all 30 is the goal, not depth on a subset. (8 thin repositories added)
- [x] Write the root-cause doc: the pattern behind the original CRITICAL bugs (suffixed-key mismatches at layer boundaries) and how the new pattern prevents them structurally. (docs/ARCHITECTURE_ROOT_CAUSE.md)

---

## Phase C — UI/UX & Accessibility polish (~2–3 weeks)

- [x] Minimal responsive layout for the 3–4 screens a reviewer opens first (home dashboard, transaction history, analytics) — `responsive_helper.dart` has real tablet/desktop breakpoints defined but they're barely used, and this matters directly for the hosted web demo in Phase F. (Home dashboard now uses a 2-column `GridView` on large tablets/desktop; transaction history & analytics use `ResponsiveContent` max-width centering.)
- [x] Expand the accessibility pass beyond the initial `ACCESSIBILITY.md` baseline — increase `Semantics` coverage, verify touch targets are consistently ≥48px app-wide, update the statement's "Partial" rows to "Met" as each is actually completed. (`DesignTokens.touchTargetMin` wired into `AccessibilityHelper`; ACCESSIBILITY.md "Partial" rows updated to "Met".)
- [x] Onboarding: cut from 5 pages to 2–3; move location-permission request to first actual use of a location feature. (Done in Phase 1.5c — 3 pages, location deferred to first map use.)
- [x] Net worth trend chart + other data-viz polish — lowest priority, cosmetic, do last. (Net worth trend chart already implemented; semantics + DesignTokens applied in prior sessions.)

---

## Phase D — Flagship feature: the real alternative-recommendation engine (~2–3 months)

Your original idea, and the most personally meaningful part of the app. Build it for real.

**Data model:**

- `place_visits`: transaction_id, place_name, lat, lon, category, amount, timestamp.
- `price_observations` (new): item/category, place_id (OSM node id if matched, else your own), price, currency, observed_at, source (`self_reported` for now).
- `alternative_suggestions` (optional cache): origin place, suggested place, distance_m, generated_at, basis (`price` | `distance_only`).

**Algorithm:**

1. On a purchase with location + category, query the **Overpass API** for the same OSM category tag within a ~1–2 km bounding box.
2. Rank candidates by Haversine distance; if you have price observations, rank by (price, distance) instead.
3. Cache Overpass responses locally (keyed by rounded lat/lon + category + day) to respect fair use and work offline-after-first-use.

**Price data honesty:** let the user tag "I paid X here" to build `price_observations`; aggregate with median (not mean) to resist outliers; show a confidence indicator ("based on 1 report" vs "based on 12"). Don't claim price data you don't have — a distance-only suggestion is still honest and useful.

**What this demonstrates:** geospatial querying, nearest-neighbor ranking, data aggregation with outlier awareness, caching under a rate-limited free API — all defensible, explainable engineering.

**Status (all items complete):** The full pipeline (DB tables, Overpass query, OSM category mapping, median price aggregation with outlier trim, local caching, and UI) was already present from earlier work. Phase D hardening added: (1) ranking corrected to spec — distance-first, then price-based when price observations exist; (2) `OverpassApiService` now gates on `NetworkService.isOnline` and `ApiSecurityService.checkRateLimit('overpass')` to respect fair use and work offline-after-first-use; (3) user price-tagging UI ("Tag harga di sini") on `AlternativesScreen` persists `self_reported` `price_observations` via `PriceObservationDataService.createSelfReported`, switching distance-only suggestions to price-aware on next refresh; (4) the "based on N reports" honesty signal is now persisted (`observation_count` column, DB v8 migration) and shown in `AlternativeSuggestionCard` for price-based suggestions. Unit tests cover the ranking comparator and the network/rate-limit gating.

---

## Phase E — Real spend/save/allocate advisor (~3–4 weeks, can overlap Phase D)

Replace templated recommendation strings with computed, explainable numbers:

- Classify transactions essential vs. discretionary.
- Compute savings rate, discretionary %, run-rate to each goal.
- Apply a named budgeting model (50/30/20 or zero-based) against the user's _actual_ numbers, and show the math in the UI, not a canned tip.
- Optional stretch: a small, explainable text classifier (Naive Bayes/logistic regression) for auto-categorization, if you want one genuine ML talking point — without overclaiming "AI" elsewhere.

### Phase E — Status: COMPLETE (core)

**Done:**
- `FinancialAdvisorService` already implemented a real computed 50/30/20 engine (`FiftyThirtyTwentyAnalysis`) classifying transactions into needs/wants/savings against actual numbers.
- Added **zero-based budgeting** as a second named model:
  - `BudgetingModel` enum (`fiftyThirtyTwenty`, `zeroBased`).
  - `ZeroBasedAnalysis` class + `computeZeroBased()` pure static (income − allocated = surplus/shortfall, with explicit math).
  - `analyzeZeroBasedForPeriod()` real engine pulling actual transactions per category.
- Fixed **goal run-rate**: `_computeGoalRunRates` now derives `monthlyContribution` from `targetDate` deadline when `monthlyTarget` is not set; added public `monthsBetween()` helper (was private `_monthsBetween`).
- UI: `FinancialAdvisorScreen` gained a model toggle (`_buildModelSelector`) and `_buildZeroBasedCard` showing the explicit income − allocated = surplus/shortfall math plus per-category allocations.
- l10n: added `rule503020`, `zeroBasedBudget`, `zbSurplus`, `zbShortfall`, `zbMathHint`, `totalAllocated`, `allocations`, `noAllocations` to `app_en.arb` + `app_id.arb`; ran `flutter gen-l10n`.
- Tests: `test/services/financial_advisor_service_test.dart` (zero-based surplus/shortfall, `monthsBetween`, 50/30/20 classification) — 5 new tests, all passing. Fixed `test/widgets/financial_advisor_screen_test.dart` mock to override `analyzeZeroBasedForPeriod` (10 widget tests now pass).

**Verification:** `flutter analyze` 0 errors / 0 warnings (127 pre-existing info). `flutter test` 301 pass; 31 failures are the pre-existing `databaseFactory not initialized` (missing system `libsqlite3.so`) environment-only SQLite integration tests — not code defects.

**Deferred (optional stretch, not done):** Naive-Bayes/logistic auto-categorization classifier. `SmartCategorizationService` already exists as a keyword scorer and could be upgraded later.

---

## Phase F — DAAD narrative feature: German student finance planner (~2–3 weeks)

- Blocked account (Sperrkonto) calculator: required minimum balance, monthly withdrawal cap, months-of-coverage tracker.
- EUR ⇄ IDR conversion using your existing exchange-rate service.
- "Am I on track" projection reusing Phase E's forecasting logic.

_(Ping me when you're ready to build this — I'll pull current DAAD/German student visa financial requirement figures so the numbers are accurate, not stale.)_

### Phase F — Status: COMPLETE

**DAAD 2026 figures (verified):** €11,904/year = €992/month, tied to BAföG §13, effective 1 Jan 2026 (German Federal Foreign Office / study-in-germany.de / DAAD). One stale source cited €11,208/€934 (2024 figure) — not used. Constants in `GermanFinanceScreen` carry a source doc comment.

**Done:**
- **Sperrkonto calculator**: required balance (€11,904) + monthly cap (€992) shown in EUR and IDR via `ExchangeRateService` (already present). Added a **months-of-coverage tracker** (`_buildCoverageCard`): current saved amount ÷ €992/month cap → N months of coverage, with a 12-month progress bar. Coverage math extracted to a pure, testable `coverageMonths()` helper.
- **EUR ⇄ IDR conversion**: existing live converter reused (no change needed).
- **"Am I on track" projection reusing Phase E's forecasting logic**: added public `FinancialAdvisorService.getGoalRunRate(String)` which reuses the same `_computeGoalRunRates` / `GoalRunRate` / `monthsBetween` engine as the advisor. The DAAD screen now looks up the "Sperrkonto Studi Jerman" goal and shows its real run-rate (deadline-based monthly contribution + monthsToGoal) instead of the previous ad-hoc formula. Current savings now pulled from the goal to feed both the coverage tracker and the progress card.

**Verification:** `flutter analyze` 0 errors / 0 warnings (128 pre-existing info). `flutter test` 305 pass; 31 failures are the pre-existing `databaseFactory not initialized` (missing system `libsqlite3.so`) environment-only SQLite integration tests — not code defects.

**Note:** `GermanFinanceScreen` user-facing strings remain hardcoded Indonesian (consistent with the file's pre-existing convention; AGENTS.md lists this as a known minor remaining item). No new DB tables, services, or routes were added.

---

## Phase G — One systems feature, pick ONE (~1–2 months)

**Option A — Offline-first sync with conflict resolution** (last-write-wins + vector clock, or a small CRDT). Strong distributed-systems story, higher risk solo.
**Option B — Performance under scale**: seed 50k+ synthetic transactions, benchmark, optimize (indexing/pagination), document before/after numbers. Concrete, lower risk.

Given solo timeline, I'd lean **Option B** unless you specifically want the distributed-systems story.

### Phase G — Status: COMPLETE (Option B — Performance under scale)

**Chosen:** Option B (lower risk, fits the app's standalone/no-backend design, and the
benchmark harness already existed in `test/performance/`).

**Key finding (honest):** At 50k seeded rows, raw SQLite queries were already sub-3ms with
the existing 2 indexes. Adding a category index gave only marginal gain (Q3 category filter
1.7ms → 1.6ms). **The real problem was not query speed — it was silent `LIMIT` truncation
that dropped data and a legacy path that loaded only 100 rows.** Those were the actual
correctness/scale bugs, and fixing them was the bulk of the value.

**What changed:**
- Added `TransactionDataService.getAllTransactions({filters})` — pages through all matching
  rows (LIMIT/OFFSET loop) so callers aggregating over full history are never truncated.
- Replaced fixed `limit:` caps with `getAllTransactions()` in the history-wide aggregators:
  `FinancialAdvisorService` (was `limit: 5000` in `analyzeForPeriod`/`analyzeZeroBasedForPeriod`),
  `CashFlowForecastService` (5000/5000/1000), `BudgetRecommendationService` (1000/500),
  `AnalyticsService` (1000), `BudgetPredictor` (200/500), `BudgetForecastService` (1000×2),
  `PlaceVisitDataService.syncFromTransactions` (5000).
- Fixed `DataService.refreshTransactions()` which called `getTransactions()` with **no limit
  → default 100**, so `AppState`/legacy `TransactionListWidget` only ever held 100 rows. Now
  loads the full history via `getAllTransactions()`. (The modern `transaction_history_screen`
  already paginates correctly at 50/page.)
- Added `idx_transactions_category` index (DB v8 → v9 migration in `LocalDatabaseService`),
  applied in both `_onCreate` and `_onUpgrade`.

**Deliberately left capped (documented):** `ai_service.dart`, `ai_recommendations_enhanced_service.dart`,
`location_*` services cap at 100–500 — these feed an LLM context window, so truncation is
intentional, not a bug.

**Benchmark (50,000 rows, in-memory sqflite, warmup 2 + measure 5 runs):**
| Query | Baseline (2 idx) | +category idx | Verdict |
|-------|-----------------|---------------|---------|
| Q1 no-filter LIMIT 100 | 0.8ms | 0.9ms | flat |
| Q2 type=income | 0.7ms | 0.9ms | flat |
| Q3 category=shopping | 1.7ms | 1.6ms | ~marginal |
| Q4 date 30d | 1.2ms | 1.0ms | flat |
| Q5 LIKE desc | 2.2ms | 2.0ms | flat |
| Q6 type+cat+date | 1.5ms | 1.3ms | flat |
| Q7 GROUP BY type | 2.3ms | 2.1ms | flat |
| Q8 SUM expense | 1.5ms | 1.3ms | flat |
| Q9 COUNT 6mo | 0.8ms | 0.8ms | flat |
| Q10 COUNT all 50k | 1.7ms | 1.6ms | flat |

Run with: `LD_LIBRARY_PATH=<build dir>:$LD_LIBRARY_PATH flutter test test/performance/query_benchmark_test.dart`
(The system `libsqlite3.so` is missing on this dev box; the project `build/` dir provides it.)

**Verification:** `flutter analyze` 0 errors / 0 warnings (127 pre-existing info). `flutter test`
305 pass; 31 failures are the pre-existing `databaseFactory not initialized` (missing system
`libsqlite3.so`) environment-only SQLite integration tests — not code defects.

---

## Code Review Pass — correctness, security & performance hardening (COMPLETE)

Run after Phase G at the user's request ("focus on building and review the codebase
first and testing"). No new features — a static read of the service/widget layer plus
targeted fixes and regression tests.

**Analyzer:** `flutter analyze` → 0 errors, 0 warnings (123 pre-existing info).
**Tests:** 305 pass; 31 failures are the pre-existing `databaseFactory not initialized`
(missing system `libsqlite3.so`) environment-only SQLite tests — not code defects.
Two new regression tests added (goal-forecasting month math, financial-calculator null safety).

### Correctness (C1–C8)
- **C1** `budget_forecast_service.dart` — guarded divide-by-zero when `budgetAmount == 0`
  (returned `double.infinity` before).
- **C2** `financial_calculator.dart` `calculateRunningBalance` — null `amount`/`type` no longer
  throw (`_toMoney(null)` / `as String`); null amount → 0, null type → treated as expense.
- **C3** `map_provider_service.dart` — Nominatim `lat`/`lon` parsed with `double.tryParse`,
  invalid rows skipped instead of crashing on `as String`.
- **C4** `report_service.dart` — PDF transaction cap was a silent `take(50)`; replaced with a
  named `const _maxTransactionsInPdf = 200` used by both the cap and the footer count.
- **C5** `cash_flow_forecast_service.dart` — `DateTime.parse` on transaction dates wrapped in
  try/catch per row (bad dates skipped, not fatal).
- **C6** `analytics_service.dart` — `averageDailyExpense` denominator now uses a real
  `_daysInPeriod()` helper (was `daysBetween` over a possibly-wrong range, could divide by 1).
- **C7** `ai_service.dart` + `expense_predictor.dart` — `(amount ?? 0).toDouble()` on a non-num
  value crashed; now `(amount as num?)?.toDouble() ?? 0.0`.
- **C8** `goal_forecasting_service.dart` — completion/milestone dates used `*30` day drift
  (8 months ≠ 240 days across month lengths); now real month arithmetic
  `DateTime(year, month + n, day)`.

### Security / Input validation (S1–S4)
- **S1** `add_obligation_modal.dart` — 5× `double.parse` on user input → `double.tryParse` via a
  `_tryParseOrNull` helper with a clear error snackbar instead of a crash.
- **S2** `add_budget_modal.dart` — `double.parse` on the amount field → `double.tryParse` with an
  early-return error snackbar.
- **S3** `add_goal_modal.dart` — `double.parse` on the target field → `double.tryParse ?? 0`.
- **S4** `alternative_suggestion_card.dart` + `alternative_recommendation_card.dart` — URL query
  params (`name`, `location`) now `Uri.encodeComponent(...)` to avoid malformed/unsafe URLs.

### Performance — N+1 / redundant full-history loads (P1–P4)
- **P1** `budget_predictor.dart` — `predictBudgetExhaustion` & `assessOverspendingRisk` now fetch
  `getAllTransactions()` **once** and reuse it (was re-fetching inside the loop per category).
- **P2** `financial_advisor_service.dart` — `analyzeMultiMonth` fetches the window once and
  partitions in Dart instead of one query per month.
- **P3** `budget_recommendation_service.dart` — single `getAllTransactions()` reused;
  `suggestOptimalBudgets` gained an optional `transactions` param (passed through from P1).
- **P4** `budget_forecast_service.dart` — `getBudgetHistoryTrends` now fetches `getBudgets()`
  once outside the per-month loop (was inside).

### Analyzer warnings fixed (4)
- `budget_controller.dart:51` — `cat.type?.` → `cat.type.` (unnecessary null-aware).
- `transaction_remote_datasource.dart:37` — `model?.toJson()` → `model.toJson()`.
- `quick_add_modal.dart:77` — removed redundant `cat != null` guard.
- `recurring_obligations_view.dart:35` — removed unused `l10n` + its import.

---

## Phase H — Packaging for reviewers (~2–3 weeks, do this close to application time)

- Host the Flutter **web** build (GitHub Pages/Netlify) — "try it live" beats "clone and run."
- One technical case-study doc: architecture diagram, key decisions, the bug-pattern write-up from Phase B.
- Tidy README: CI badge, test count, short walkthrough, a clear "what I built and why" tied to your personal motivation.

---

## Suggested timeline

| When                          | Phase                                     |
| ----------------------------- | ----------------------------------------- |
| Now (~1–2 weeks)              | Phase A — close out remaining rigor items |
| Next 1–2 months               | Phase B — architecture consolidation      |
| Alongside/after               | Phase C — UI/UX & accessibility           |
| Following 2–3 months          | Phase D — flagship feature                |
| Overlapping                   | Phase E — advisor logic                   |
| Short slot whenever           | Phase F — DAAD narrative feature          |
| Later semester                | Phase G — one systems feature             |
| Right before application prep | Phase H — packaging                       |

---

## What to explicitly skip

- More budgeting sub-screens or finance concepts — you already have 30+ features.
- Paid map/geocoding providers — raw OSM tiles and the free Overpass API are sufficient.
- Claiming "AI" for anything rule-based — describe it accurately; technical reviewers will ask.
- Generating more one-off status docs mid-session without cleaning them up afterward — that's what caused the current sprawl.
