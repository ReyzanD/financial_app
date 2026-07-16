# Architecture — Financial App

## Guiding Principle

**Consistency over depth.** The original codebase attempted Clean Architecture (4-layer) on some features but left most features partially implemented or entirely pattern-free. Rather than half-finishing a heavy architecture across 30 features, this project adopts a simplified 3-layer pattern that is applied uniformly to every feature. A pattern that exists everywhere is more valuable than a perfect pattern that exists in one place.

---

## The 3-Layer Pattern

### 1. Data Service (`lib/services/data/`)

Responsible for raw database operations against SQLite.

- **CRUD only** — `getAll()`, `getById()`, `create()`, `update()`, `delete()`
- **Suffixed-key normalization happens here** — database columns use `_232143` suffixed keys (e.g., `amount_232143`). The data service strips these suffixes and returns typed Model objects, not raw `Map<String, dynamic>`.
- **One data service per domain concept** — `TransactionDataService`, `AccountDataService`, `BudgetDataService`, etc.
- **Never used directly by UI code** — always called through a repository.

**Before (original):** Data services returned raw maps with `_232143` keys. Every consumer (business service, repository, screen) had to normalize keys manually or risk bugs.

**After (target):** Data services return typed `Model` objects with clean keys. Suffix stripping is done once, in one place, at the database boundary.

### 2. Repository (`lib/features/*/data/repositories/`)

A thin interface adapter between the data service and the controller.

- **Delegates CRUD to the data service** — most methods are one-liners that call the data service.
- **Adds cross-cutting logic only when needed** — e.g., "creating a transaction also updates budget spent" is real business logic; "get all transactions" is not.
- **Implements a repository interface** defined in `domain/repositories/`.
- **Returns typed Model objects** — never raw maps.

**Rule of thumb:** If a repository method just calls `dataService.getAll()` and returns the result, it's fine — the repository exists to provide a consistent access point and enable testing, not to add useless wrapper methods.

### 3. Controller (`lib/features/*/presentation/controllers/`)

Manages UI state and user interactions for a feature.

- **Resolved exclusively via `getIt<ControllerType>()`** — never constructed with `new`. This ensures testability (mocks can be injected) and lifecycle management.
- **Calls the repository interface** — not the data service directly.
- **Handles loading/error states** — exposes `isLoading`, `errorMessage`, and the data stream to the UI.

---

## What Was Removed

### Shim Entity Files (deleted)

6 feature entities were one-line re-exports of model classes (`export 'package:.../model.dart' show ClassName;`). They added zero value — every consumer imported the model directly, not through the entity. Deleted:

- `features/investments/domain/entities/investment_entity.dart`
- `features/accounts/domain/entities/account_entity.dart`
- `features/debts/domain/entities/debt_entity.dart`
- `features/challenges/domain/entities/challenge_entity.dart`
- `features/splits/domain/entities/split_entity.dart`
- `features/subscriptions/domain/entities/subscription_entity.dart`

### Standalone Use Cases (to be removed)

Single-repository use case classes that just call one method and return the result add no value — the controller can call the repository directly. Use cases are only retained when they orchestrate more than one repository call.

### Business Services That Duplicate Data Services (partially merged)

Services like `AccountService`, `DebtService`, `SubscriptionTrackerService` existed as thin wrappers. As of Phase 1.5:
- **DebtService** and **SubscriptionTrackerService** now delegate to the unified `ObligationDataService` instead of separate `DebtDataService`/`SubscriptionDataService`.
- The old `DebtDataService` and `SubscriptionDataService` remain as internal implementation details of `ObligationDataService`.
- `AccountService` still wraps `AccountDataService` — a future pass should consolidate similarly.

### Redundant Routes Removed

Phase 1.5 removed 8 route definitions from `main.dart` that all pointed to the same screen with a different initial tab:

| Removed Route | Unified Into |
|---------------|-------------|
| `/debts`, `/subscriptions`, `/recurring-transactions` | `/obligations` |
| `/reports`, `/financial-insights`, `/net-worth`, `/cash-flow` | `/analytics` |
| `/tags` | `/categories` |

These were only registered in `main.dart` and never navigated to from anywhere — they were dead routes left over from before the UI was unified into tabbed hub screens.

---

## Root-Cause Analysis

See [`ARCHITECTURE_ROOT_CAUSE.md`](./ARCHITECTURE_ROOT_CAUSE.md) for the
deep-dive on the suffixed-key mismatch pattern that caused ~60% of the
CRITICAL bugs, and how the current single-normalization-point design prevents
it structurally.

---

## Model Strategy

All domain models live in `lib/models/`:

| Model | Used By | Notes |
|-------|---------|-------|
| `AccountModel` | accounts feature, account widgets | Full `fromMap`/`toMap` with suffix normalization |
| `BudgetEntity` | budgets feature | Domain entity (no model counterpart exists) |
| `CategoryModel` | AppState, category widgets | |
| `ChallengeModel` | challenges feature | |
| `CurrencyModel` | ExchangeRateService | |
| `DebtModel` | debts feature, DebtService | |
| `FinancialObligation` | obligations feature | |
| `GoalModel` / `GoalEntity` | goals feature | GoalEntity is the domain type; GoalModel is legacy |
| `InvestmentModel` | investments feature | |
| `LocationData` | map, transaction screens | |
| `SplitModel` | splits feature | |
| `SubscriptionModel` | subscriptions feature | |
| `TransactionEntity` | transactions feature | Domain entity (no model counterpart) |
| `TransactionModel` | reports, search | Used for data views, not feature state |

**Key rule:** One typed model per domain concept. No parallel model systems. Where both a `Model` and `Entity` exist for the same concept (`GoalModel`/`GoalEntity`, `TransactionModel`/`TransactionEntity`), the Entity is the domain type used by features, and the Model is used by data views or legacy code. New code should converge on a single type.

---

## Dependency Injection

All services, repositories, and controllers are registered in `lib/core/di/service_locator.dart` via `get_it`.

**Rule:** The only acceptable way to obtain a service/repository/controller instance is `getIt<Type>()`. Direct constructor calls (`ServiceName()`) are banned. A CI step (`flutter analyze` + a custom lint rule) enforces this.

**Current status:** Previously 22+ files bypassed DI. All known bypasses have been fixed (commit `29e4780`). Any newly introduced bypass will be caught by code review.

---

## Feature Status (Architecture Coverage)

Accurate as of July 16, 2026 (30 feature directories after the obligations merge):

| Layer | Count | Description |
|-------|-------|-------------|
| **Full Clean Architecture** (domain/ + data/ + presentation/) | **2** | `goals`, `transactions` — the only features with domain entities, use cases, and repository interfaces |
| **Simplified 2-layer** (data/repositories/ + presentation/) | **18** | Concrete repository + controller, no domain layer. Repository wraps a DataService directly. |
| **Presentation only** | **11** | Screen + optional controller, backed by existing services. No dedicated data layer. |
| **Empty** (directory, no files) | **1** | `recurring_transactions` — directory scaffolding from initial setup, never populated. Widgets for recurring transactions live in `lib/widgets/transactions/`. |

Features with no dedicated controller (screen uses services directly): `daad`, `financial_advisor`, `more_tab`.

**Note on the obligations merge (Phase 4):** the old `debts` and `subscriptions`
feature directories were removed. Their UI now lives under `lib/widgets/obligations/`
and is served by the unified `ObligationDataService` (which internally wraps the
former `DebtDataService` / `SubscriptionDataService` logic). This reduced the
feature count from 32 to 30 and eliminated two parallel data services.

**Target:** Every feature should have at least a Controller + Repository + Data Service. Features that are pure UI over existing services (auth, home, settings, onboarding) may omit the data service if they don't own a database table.

---

## Key Decisions

### Why local SQLite instead of a backend?
- Offline-first by default — the app works without any network connection.
- No backend infrastructure to maintain — zero server cost, zero API versioning.
- Data privacy — all financial data stays on the device.
- The app's data model is a personal financial journal, not a multi-user system. SQLite is the correct tool.

### Why simplified 3-layer instead of full Clean Architecture?
The original codebase had 4-layer Clean Architecture on 8 features but the pattern was inconsistently applied — entities that were just re-exports, use cases that added no orchestration, repositories that talked to services that talked to other services. Rather than "complete" this inconsistent architecture, I collapsed to a simpler 3-layer pattern that I could apply consistently to all 30 features. A consistent simple pattern is more maintainable and more testable than an inconsistently applied complex one.

### Why `_232143` suffixed database keys?
The suffix was introduced during a database migration to avoid naming conflicts with legacy columns. The suffix is internal to the database layer — models normalize it in `fromMap()`/`toMap()`, and data services strip it before returning typed objects. The UI layer never sees a suffixed key.

### Why no ORM (floor, drift, etc.)?
Raw SQLite via `sqflite` gives full control over queries, migrations, and performance. The schema is stable and well-understood (16 tables). An ORM would add a dependency and a learning curve without providing meaningful benefit for this data volume.

---

## Document History

- **2026-07-13** — Initial version, documenting the collapsed 3-layer pattern after auditing the original 4-layer implementation for inconsistencies.
- **2026-07-15** — Updated feature counts after full survey (34 features, 2 full-CA, 18 simplified, 11 presentation-only, 3 skeletons). Added Phase 1.5 route consolidation and obligations data-layer unification.
