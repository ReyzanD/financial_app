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

---

## Phase G — One systems feature, pick ONE (~1–2 months)

**Option A — Offline-first sync with conflict resolution** (last-write-wins + vector clock, or a small CRDT). Strong distributed-systems story, higher risk solo.
**Option B — Performance under scale**: seed 50k+ synthetic transactions, benchmark, optimize (indexing/pagination), document before/after numbers. Concrete, lower risk.

Given solo timeline, I'd lean **Option B** unless you specifically want the distributed-systems story.

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
