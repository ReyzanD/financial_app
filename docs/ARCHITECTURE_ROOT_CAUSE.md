# Root-Cause Analysis: The Suffixed-Key Mismatch Pattern

**Why this document exists:** During the engineering-rigor pass (Phase 1.5 → Phase 4),
22 CRITICAL and 33 HIGH bugs were found and fixed. The single largest class of bugs —
roughly 60% of the CRITICAL category — shared one root cause: **suffixed database column
keys leaking across layer boundaries and being read with the wrong key name.**

This document explains the pattern, why it happened, and how the current architecture
prevents it structurally. It is written for technical reviewers (DAAD / SE-CS admissions)
who will ask "what was the hardest bug you found, and how did you fix it?"

---

## 1. The Problem

The SQLite schema uses column names with a random suffix:

```
transaction_id_232143
amount_232143
category_id_232143
transaction_date_232143
created_at_232143
```

The suffix (`_232143`) was introduced during a schema migration to avoid naming
conflicts with legacy columns. It is an **internal database-layer detail** — no other
layer should ever see it.

### The bug pattern

Raw `sqflite` queries return `Map<String, dynamic>` with the suffixed keys:

```dart
// WRONG — what the old code did
final rows = await db.rawQuery('SELECT * FROM transactions_232143');
final amount = row['amount'];          // null! the column is 'amount_232143'
final category = row['category_id'];  // null!
```

Every consumer — business service, repository, controller, screen — had to know the
suffix and strip it manually. When one layer used `'amount'` and the database
returned `'amount_232143'`, the lookup returned `null` and the app either crashed
(`Null check operator`, `int` cast on `null`) or silently showed wrong data
(empty lists, zero balances, missing categories).

### Concrete examples from the audit

| Bug | Layer A wrote | Layer B read | Result |
|-----|------------------|------------------|--------|
| BudgetEntity.fromJson | `spent_amount_232143` | `spent_amount` | Null → budget showed 0% spent |
| BudgetRepository | `remaining_amount_232143` | `remaining` | Wrong remaining calc |
| GoalRepository | `monthly_target_232143` | `monthly_target` (int) | int/bool comparison crash |
| RecurringTransactions | `recurring_id_232143` | `recurring_id` | Save wrote to wrong column |
| InsightsController | `transaction_date_232143` | `transaction_date` | Empty analytics |
| Transaction History | `created_at_232143` | `created_at` | Wrong sort order |
| AccountModel | `account_type_232143` | `type` | Type mismatch vs schema |
| Analytics spending_chart | `day_of_month_232143` | `day` | Day-of-month collision |

Each was a one-line mismatch, but they compounded: a null at the data layer became a
crash three layers up, or — worse — a silently wrong number in a financial report.

---

## 2. Why It Happened

The original architecture had **no single normalization point**. The suffix was treated as
a cosmetic detail and handled ad-hoc:

- Some models normalized in `fromJson()` with a `json['key_232143'] ?? json['key']` fallback.
- Some services normalized inline.
- Some controllers read raw maps and normalized again.
- Some screens read raw maps directly.

Because the fallback was inconsistent (`?? json['key']` in some places, hard-coded
suffix in others, nothing in others), the same column was read three different ways
depending on the call path. Refactoring one layer silently broke another.

This is a classic **boundary-responsibility violation**: an internal database detail
leaked past the persistence boundary and became everyone's problem.

---

## 3. The Fix — Structural, Not Whack-a-Mole

The fix was **not** to find-and-replace 60 key names. It was to **move the
normalization to exactly one place** and make it impossible for suffixed keys to
escape that place.

### Rule (enforced in code + docs)

> **Suffixed-key normalization happens exactly once, in the data service, at the
> database boundary. The data service returns typed `Model` objects with clean keys.
> No other layer ever sees a `_232143` key.**

### Implementation

1. **Data services own normalization.** Each `*_data_service.dart` in
   `lib/services/data/` does the `json['amount_232143'] ?? json['amount']`
   fallback in exactly one method (`_normalizeRow` / `fromMap`), then returns a
   typed `Model`.

   ```dart
   // lib/services/data/transaction_data_service.dart
   TransactionModel _normalize(Map<String, dynamic> row) {
     return TransactionModel(
       id: row['transaction_id_232143'] ?? row['id'] ?? '',
       amount: (row['amount_232143'] ?? row['amount'] ?? 0).toDouble(),
       categoryId: row['category_id_232143'] ?? row['category_id'],
       // ... every suffixed key handled here, once
     );
   }
   ```

2. **Repositories are thin.** They delegate to the data service and return the typed
   model. They never touch raw maps.

3. **Controllers call the repository interface** (resolved via `get_it`), never the
   data service directly, never raw SQL.

4. **Models normalize in `fromMap()`/`toMap()`** with the same fallback, so even if a
   raw map reaches a model constructor, it survives.

5. **UI never sees a suffixed key.** Screens read `transaction.amount`, not
   `transaction['amount_232143']`.

### Why this prevents regression

- A new column added with a suffix is normalized in **one** method, not 12.
- If a controller accidentally reads a raw map, the model's `fromMap` fallback
  still rescues it — defense in depth.
- The DI lint test (`api_service_bypass_test.dart`) plus `flutter analyze` catch
  direct data-service access from UI code.

---

## 4. The Interview Story

> "The hardest bug class wasn't a single crash — it was a *pattern*. The database
> used suffixed column names (`amount_232143`) as an internal migration detail, but
> that detail leaked across every layer. Different layers read the same column with
> different key names, so values came back `null` and either crashed three layers
> up or silently showed wrong financial numbers. I didn't patch 60 individual
> lookups — I moved normalization to a single boundary (the data service) and made
> it structurally impossible for a suffixed key to escape. That turned 22 critical
> bugs into a one-line-per-column convention."

This is a stronger story than "I fixed 22 bugs" because it demonstrates
**root-cause thinking**: finding the *systemic* cause behind the symptoms, and
fixing the *structure* rather than the *instances*.

---

## 5. Residual Risk

- **New raw-query code** added outside a data service could reintroduce the leak.
  Mitigated by: (a) the DI lint test, (b) code review, (c) the convention
  documented in `ARCHITECTURE.md`.
- **`Map<String, dynamic>` returns** still exist in ~9 features (analytics,
  cash_flow, forecast, insights, net_worth, notification_center, obligations,
  profile, report). These are read-only aggregation results where a typed model adds
  little value; the data service still does the suffix stripping before returning the
  map. Acceptable trade-off, documented as deliberate.
