# Financial App — Roadmap Toward DAAD Application (Software Engineering / CS)

**Where you are:** Semester 6, UNDIPA Makassar, S1 → targeting S2 in Germany via DAAD.
**Where the app is:** ~66k lines of Dart, clean-architecture Flutter app, local SQLite, mostly working, with a documented internal audit already done. "AI"/location features exist but are currently rule-based on your own transaction history, not the real "find a cheaper alternative nearby" feature you originally wanted.
**Cost constraint:** Everything below uses free tools only (OpenStreetMap/Overpass, on-device compute, free CI). No paid APIs.

---

## Guiding principle

For an SE/CS track, reviewers weigh **provable engineering skill** higher than feature count. So the plan is sequenced: fix and prove the foundation first (cheap to do, high signal), then build one flagship feature that's genuinely yours (the alternative-recommendation engine), then add one feature that ties to your personal DAAD story, then one "systems" feature that shows CS depth, then package it for reviewers who will spend 5 minutes looking at your GitHub.

---

## Phase 0 — Right now (this month)

Small, fast wins that cost little time but remove obvious red flags.

- [x] Fix the AES IV reuse bug in `encryption_service.dart` (generate a fresh random IV per encrypt call, store it alongside the ciphertext instead of once globally).
- [x] Add a GitHub Actions workflow: run `flutter analyze` + `flutter test` on every push/PR. Add the status badge to `README.md`.
- [x] Confirm the test/analyze claims locally — running today: **280/280 tests passing, 0 analyze errors, 0 analyze warnings** (was 253 tests).
- [x] **Reconcile `CODEBASE_AUDIT.md`** — verified all 24 hardcoded-color files were already fixed (0 remaining). Audit summary now matches reality.
- [x] Commit these as clearly-labeled commits (not squashed) — commit history: `e5a6a20` (audit/cleanup), `2041050` (AES fix + CI), `bbd3397` (dead code), `29e4780` (DI bypass).

**Why first:** these are the kind of things a technical reviewer checks in the first five minutes (does CI exist, is there a shipped security bug in a finance app). Cheap to fix, disproportionately damaging if left.

---

## Phase 1 — Engineering rigor (next ~1–2 months)

This is the part that's tedious but most directly provable and most valuable for an SE application, regardless of what university you come from.

1. **Target architecture — collapse to one consistent 3-layer pattern, applied to all 30 features, no exceptions.**
   Verified finding: only 8 of 30 features have full clean-architecture layering (entities + use cases); 14 have a repository shell but no entities (controllers work with raw suffixed-key maps — the root cause of most bugs in the original audit); 8 skip the pattern entirely. Worse, some "full" features are decorative — `lib/features/debts/domain/entities/debt_entity.dart` is a one-line re-export of `lib/models/DebtModel`, unused by anything, while `DebtsScreen` uses `DebtModel` directly. Don't try to finish four-layer clean architecture everywhere — that's over-engineering for a solo project. Instead, collapse to:
   - **Data service** — raw SQLite CRUD; suffixed-key normalization happens here once, returns real typed models (not maps).
   - **Repository** — thin interface adapter, delegates to the data service, adds only genuine cross-cutting logic (e.g. "creating a transaction also updates budget spent" is real repository logic; "get all budgets" is not).
   - **Controller** — resolved via `get_it` only, never constructed directly, calls the repository interface.
   Kill the parallel model systems: one typed model per domain concept (promote `lib/models/` classes to be the real domain type, delete shim entities like `debt_entity.dart`). Drop standalone "use case" classes unless they orchestrate more than one repository call. Apply this pattern to **every** feature, including the 8 that currently have nothing (auth, home, settings, onboarding, map, etc.) — consistency across all 30 is the actual goal, not depth on 8.
   Document this as a deliberate scoping decision in `docs/ARCHITECTURE.md`: "audited my own architecture, found it inconsistently applied and partly cosmetic, chose to simplify to a pattern I could apply consistently rather than half-implement a heavier one." That's a stronger interview story than claiming full clean architecture.
   - [x] `docs/ARCHITECTURE.md` written (157 lines, documents the 3-layer pattern with rationale)
   - [x] **Major milestone: `ApiService` migration** — all ~40 files that consumed `ApiService` instance methods migrated to typed data services (`TransactionDataService`, `BudgetDataService`, `GoalDataService`, `CategoryDataService`, `ObligationDataService`). `ApiService` itself stripped from 662→42 lines. This eliminates the last indirection layer between controllers/repositories and raw SQLite data. (Phases 4a–4f, 16 commits)

2. **Fix the DI bypass.** ~22 places construct `ObligationService()`, `AccountService()`, `NetworkService()`, etc. directly instead of resolving via `get_it`. Root cause: redundant data-access paths make it easy to grab a service by its default constructor. 
   - [x] **Done** — 22 files converted to `getIt<ServiceType>()` (committed in `29e4780`). Fixed services: `ObligationService` (9 files), `AccountService` (2), `NetworkService` (1), `NotificationService` (3), `BiometricService` (1), `EncryptionService` (1), `ReceiptScanningService` (1), `SmartCategorizationService` (1), `GoalForecastingService` (1), `NotificationHistoryService` (1), `BudgetRecommendationService` (1). Also fixed pre-existing `CurrencyFormatter` undefined import. Remaining work: add a lint rule or simple test that fails if a service is constructed directly (after the architecture consolidation removes redundant paths).

3. **Raise integration test coverage at layer boundaries.** Your audit found that most critical bugs happened exactly at the repository ↔ controller ↔ UI seams (suffixed DB keys not matching clean keys, IDs not passed through, etc). Write integration tests that specifically exercise those seams (create → read back → verify fields match) for each feature, not just unit tests on isolated calculators.

4. **Write one short doc:** "Bugs I found and why they happened" — a page in `docs/` summarizing the *pattern* behind the CRITICAL bugs in your audit.
   - [x] **Done** — `docs/BUGS_I_FOUND.md` documents the AES IV reuse bug (security, root cause analysis, fix rationale) and the DI bypass pattern (22 files, architectural root cause). Each entry covers: what the bug was, how to reproduce, why it existed (convergence of 2–3 design failures), what the fix does, and why it demonstrates engineering skill for a reviewer.

**Deliverable at end of Phase 1:** CI green, architecture consistent, a documented example of you finding and systematically fixing a whole class of bug (not just patching symptoms).

---

## Phase 1.5 — Feature consolidation (do this right after Phase 1, ~2–3 weeks)

Confirmed by directly reading the code (not guesses):

### Delete — dead code, not imported anywhere
- [x] **Done** — 7 files deleted (2,296 lines) in commit `bbd3397`. Flutter analyze and tests still pass (280/280). Files removed:
  - `lib/widgets/home/recent_transactions.dart` (219 lines)
  - `lib/widgets/home/recent_transactions_enhanced.dart` (499 lines)
  - `lib/widgets/home/quick_actions.dart` (165 lines) — `quick_actions_enhanced.dart` is the one actually used
  - `lib/widgets/home/quick_add_widget.dart` (370 lines)
  - `lib/widgets/home/quick_add_widget_enhanced.dart` (655 lines) — superseded by `widgets/home/quick_add/quick_add_modal.dart`
  - `lib/widgets/common/enhanced_empty_state.dart` (171 lines) — `empty_state.dart` is the one actually used
  - `lib/services/transaction_template_service.dart` (singular) — confirmed `transaction_templates_service.dart` (plural) is the real one, then deleted the singular

~2,200+ lines of confirmed dead weight, zero functional risk to remove.

### Merge — Debts + Subscriptions + Recurring Transactions + Financial Obligations
This is a real architectural problem, not just a UI one. Confirmed by reading `local_database_service.dart`'s schema: these are **three separate SQLite tables** for what is conceptually one domain (money you owe / pay repeatedly):
- `financial_obligations_232143` — generic bills, no `type` column to distinguish anything (confirmed: `ObligationDataService.getObligations()` has a comment "type filtering would need additional field in schema" — it was never finished)
- `debts_232143` (+ `debt_payments_232143`)
- `subscriptions_232143`
- recurring transactions live somewhere in `transactions_232143` via `is_recurring_232143`, a fourth mechanism

And `main.dart` registers **four separate routes** (`/financial-obligations`, `/debts`, `/subscriptions`, `/recurring-transactions`) to **four separate screens**, even though `FinancialObligationsScreen` already internally reuses `DebtsView` and `SubscriptionsView` widgets as tabs (`obligation_view_tabs.dart` has All/Upcoming/Overdue/Debts/Subscriptions tabs) — someone already started this consolidation and didn't finish it.

**Plan:**
1. Design one schema: extend `financial_obligations_232143` with a `type` column (`bill` | `debt` | `subscription` | `recurring`) and the type-specific columns each currently needs (e.g. `interest_rate` for debts, `billing_cycle` for subscriptions), or keep three tables but query them through one repository/controller.
2. Migrate `debts_232143` and `subscriptions_232143` data into the unified model (write a one-time migration in `local_database_service.dart`'s upgrade path).
3. Delete `lib/features/debts/`, `lib/features/subscriptions/` route-level screens (`debts_screen.dart`, `subscriptions_screen.dart`) — keep the `DebtModel`/`SubscriptionModel` shapes if useful, but stop them being separate top-level features.
4. Fold recurring transactions in as a tab or a `type` filter on the same hub.
5. Update `main.dart` and `more_tab_screen.dart` to a single `/obligations` route.

This is good, concrete "found and fixed a fragmented data model" material for an interview — much stronger than "I added a feature."

### Merge — Analytics + Insights + Net Worth + Cash Flow + Reports
Five separate `/analytics`, `/financial-insights`, `/net-worth`, `/cash-flow`, `/reports` routes, all "view my numbers differently." Combine into one hub with a tab/segmented-control switcher. Lower priority than the obligations merge (no confirmed duplicate storage here, just navigation/UX sprawl) — do this after the obligations merge if time allows.

### Merge — Category Customization + Tags
Two separate routes (`/categories`, `/tags`) for transaction labeling. Combine into one screen with a mode toggle.

### Group the remaining `/more` menu (22 → fewer, sectioned)
After the merges above, group what's left instead of one flat list:
- **Money Management** — Accounts, Budgets, Goals, Obligations (merged)
- **Insights** — Analytics hub (merged), Financial Insights
- **Tools** — Templates, Splits, Challenges, Calendar, Receipt History
- **Account** — Profile, Settings, Backup

---

## Phase 1.5c — UI/UX & Accessibility (~2–3 weeks, alongside 1.5)

Theme system itself is solid (`ThemeService` defines proper light/dark themes, defaults to system) — no work needed there. The gaps:

1. **Fix the 24 files with hardcoded colors** (see Phase 0 doc-reconciliation note) and unify spacing — `ResponsiveHelper.verticalSpacing()` exists but is used in only 123 places against 563 raw `SizedBox(height: N)` calls. Pick one convention and apply it everywhere, don't just document the intention.

2. **Minimal responsive layout for demo-critical screens.** `responsive_helper.dart` has real tablet/desktop breakpoints defined but `isTablet`/`isDesktop` is referenced in only 2 files (one of which is on the delete list above) — the app is functionally phone-only. This matters directly for Phase 6: a hosted web demo at desktop width will look like a stretched phone screenshot otherwise. Don't rebuild every screen — just add a max-content-width constraint + a real two-column layout for the 3–4 screens a reviewer opens first (home dashboard, transaction history, analytics).

3. **Real accessibility pass.** `Semantics(` is used only 11 times across 66k lines. Add proper semantics labels, verify contrast, fix touch targets under 48px (home header icons are 40px). This is more than generic polish for this specific application: the European Accessibility Act has been enforceable EU-wide since June 28, 2025, and Germany's implementing law (Barrierefreiheitsstärkungsgesetz / BFSG, enforced by the Bundesnetzagentur) specifically names banking/financial services as in-scope. Write a short `ACCESSIBILITY.md` accessibility statement for the app — that's literally one of the artifacts EAA-covered services are expected to publish, so producing one for a student project is a small, authentic, on-narrative touch for a Germany-bound application.

4. **Onboarding**: cut from 5 pages to 2–3; move location-permission request to first actual use of a location feature instead of upfront. (Confirmed still open in your own `TODO.md`.)

5. **Net worth trend chart** and other data-viz polish (spending chart period selector, month-over-month comparison chart) — lowest priority, cosmetic, do last.

---

## Phase 2 — Flagship feature: the real alternative-recommendation engine (~2–3 months)

This is your original idea and the most personally meaningful part of the app. Build it for real.

### 2.1 Data model
- `place_visits` table: transaction_id, place_name, lat, lon, category, amount, timestamp (you likely have most of this already via `location_data.dart`).
- `price_observations` table (new): item/category label, place_id (OSM node id if matched, else your own), price, currency, observed_at, source (`self_reported` for now).
- `alternative_suggestions` table (optional, for caching): origin place, suggested place, distance_m, generated_at, basis (`price` | `distance_only`).

### 2.2 Nearby-alternatives algorithm
1. On a purchase with location + category, build an **Overpass QL** query for the same OSM category tag (e.g. `shop=convenience`, `amenity=cafe`) within a bounding box around the transaction's lat/lon (start with ~1–2 km radius).
2. Compute distance from the original point to each candidate using the **Haversine formula**.
3. Rank candidates:
   - If you have price observations for the same category near the candidate → rank by (price, distance).
   - Else → rank by distance only, and be honest in the UI that it's a distance-based suggestion, not a price-verified one.
4. Cache the Overpass response locally (keyed by rounded lat/lon + category + day) so you don't re-query the same area repeatedly — respects the free API's fair-use expectations and makes the feature fast offline-after-first-use.

### 2.3 Making the price data real (not fabricated)
Since you can't pay for a commercial pricing API, be honest about data provenance:
- Let the user (you, initially) tag "I paid X here" after transactions with a location — this feeds `price_observations`.
- Aggregate with median (not mean, to resist outliers) per category+place.
- Show a confidence indicator in the UI: "based on 1 report" vs "based on 12 reports" — this is good, honest UX and also a legitimate small data-engineering problem (aggregation, staleness, outlier handling) you can describe in an interview.
- Don't claim price data you don't have — a distance-only "there's another option here" suggestion is still useful and honest.

### 2.4 What this demonstrates technically
Geospatial querying, nearest-neighbor ranking, basic data aggregation with outlier awareness, caching strategy under a rate-limited free API, and an interface for a real external data source (Overpass/OSM) — all defensible, explainable engineering, no black-box "AI" claims you can't back up.

---

## Phase 3 — Real spend/save/allocate advisor (~3–4 weeks, can overlap Phase 2)
- [x] **Complete** — `FinancialAdvisorService` + `FinancialAdvisorScreen` with full 50/30/20 budget analysis, category breakdowns, goal run-rates, multi-month trends, 31 passing tests.

Replace templated recommendation strings with computed, explainable numbers.

- Classify transactions essential vs. discretionary (rule-based on category is fine).
- Compute: savings rate, monthly discretionary %, run-rate to each goal (reuse `goal_forecasting_service.dart`).
- Apply a named budgeting model (50/30/20 or zero-based) against the user's *actual* numbers.
- UI shows the math: "You're at 42% discretionary spend vs. a 30% target — that's Rp X/month over" — not a canned tip.
- Optional stretch: a simple text classifier (Naive Bayes/logistic regression) trained on your own labeled transaction descriptions for auto-categorization — a small, real, explainable ML component if you want one for a Data-Science-adjacent talking point, without overclaiming "AI."

---

## Phase 4 — DAAD narrative feature: German student finance planner (~2–3 weeks)

Directly useful to you, and a strong motivation-letter anecdote ("I extended my own app to solve a problem I had while applying").

- Blocked account (Sperrkonto) calculator: required minimum balance, monthly withdrawal cap, months-of-coverage tracker.
- EUR ⇄ IDR conversion using your existing `exchange_rate_service.dart`.
- A simple "am I on track" projection against your current savings rate (reuses Phase 3's forecasting logic — good code reuse story).

*(Check the current DAAD/German student visa financial requirement figures before building the exact numbers in — I can pull those for you when you're ready to build this.)*

---

## Phase 5 — One systems feature, pick ONE (~1–2 months, later in your timeline)

Don't do both — depth over breadth.

**Option A — Offline-first sync with conflict resolution.**
App is currently single-device/local-only. Add optional sync (even a simple self-hosted endpoint) with a documented conflict strategy (last-write-wins + vector clock, or a small CRDT for the transaction list). Strong distributed-systems talking point.

**Option B — Performance under scale.**
Seed the local DB with 50k+ synthetic transactions, benchmark query/render times, then optimize (indexing, pagination — you already have `pagination_service.dart`) and document before/after numbers in a table in `docs/`. Concrete, verifiable evidence, lower risk than Option A.

Given your timeline and that this is solo work, I'd lean **Option B** unless you specifically want the distributed-systems story.

---

## Phase 6 — Packaging for reviewers (~2–3 weeks, do this close to when you assemble your application)

- Build and host the Flutter **web** target (GitHub Pages/Netlify) — a "try it live" link beats "clone and run" for almost every reviewer.
- Write one **technical case-study doc**: architecture diagram, key decisions (why clean architecture, why local SQLite, why Overpass over a paid API), and the bug-pattern doc from Phase 1. This is what you'll actually link and talk about in an interview.
- Tidy the README: badges (CI status, test count), a short GIF/screenshot walkthrough, and a clear "what I built and why" section that ties back to your personal motivation.

---

## Suggested timeline (given you're in semester 6 now)

| When | Phase |
|---|---|
| This month | Phase 0 |
| Next 1–2 months | Phase 1 (engineering rigor) |
| Right after | Phase 1.5 + 1.5c (delete dead code, merge overlapping features, UI/UX & accessibility) |
| Following 2–3 months | Phase 2 (flagship feature) |
| Overlapping/after | Phase 3 (advisor logic) |
| Short slot whenever | Phase 4 (DAAD feature) |
| Later semester | Phase 5 (pick one systems feature) |
| Right before application prep | Phase 6 (packaging) |

This leaves buffer — DAAD applications and any subsequent university admission processes take time, so having the flagship feature and engineering rigor done well before you're also writing motivation letters and gathering documents is the goal.

---

## What to explicitly skip
- More budgeting sub-screens or finance concepts — you already have 30+ features.
- Paid map/geocoding providers (MapTiler/Mapbox) — raw OSM tiles are free and sufficient.
- Claiming "AI" for anything that's actually rule-based — describe it accurately (rule-based recommendation engine, nearest-neighbor search, etc.) since technical reviewers will ask.
