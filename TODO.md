# TODO — Remaining Work

## Build Health
- `dart analyze`: **0 errors, 0 warnings** ✅
- `flutter test`: **253/253 passing** ✅

---

## Immediate (high-impact, quick)
- [ ] `api_security_service.dart:147` — Replace TODO placeholder with production cert hash config

## UX/Design Polish
- [ ] **Dashboard overload** — Collapse AI recommendations and health score behind expandable cards
- [ ] **More Tab (23 items)** — Group into sections (Financial Management, Analytics, Settings) or switch to list layout
- [ ] **Net worth chart** — Add trend line chart over time
- [ ] **Add Transaction form** — Reduce to 5 core fields, move account/payment/location/recurring into "More Options"
- [ ] **Recurring toggle** — Either integrate frequency config or remove from add screen
- [ ] **9px → 12px** ✅ DONE
- [ ] **Empty state CTA buttons** ✅ DONE (Splits, Receipt History, Templates)
- [ ] **Goal triple load** ✅ DONE (single load now)
- [ ] **QuickAddWidgetEnhanced voice/scan** ✅ DONE (basic wire-up to real modal)

## Localization
- [ ] Move hardcoded Indonesian strings to ARB files (see CODEBASE_AUDIT.md for the full list)
- [ ] Audit snackbar messages for localization

## Architecture (deferred)
- [ ] **CRUD bypasses controllers** — Wire mutation flows through clean architecture controllers/repositories
- [ ] **Dashboard widgets bypass AppState** — Consolidate data pipeline
- [ ] **HomeController orphaned** — Register in service locator or remove (59 lines dead code)

## Testing
- [ ] Add tests for suffixed-key normalization helpers
- [ ] Add tests for new BudgetController null-guarded summary getter
- [ ] Add tests for QuickAddModal presetDescription wiring

## Low Priority
- [ ] TransactionCard: Edit button calls onDeleted callback (wrong semantics)
- [ ] getCategoryIcon missing mappings for 5 categories
- [ ] Date picker theming boilerplate duplicated across multiple screens
- [ ] Back button icon inconsistency (some use `Iconsax.arrow_left`, others `Icons.arrow_back`)
- [ ] No Semantics labels on quick actions, bottom nav, FAB

## Reference
- See `CODEBASE_AUDIT.md` for the full detailed audit with line numbers
- See `AGENTS.md` for project conventions
