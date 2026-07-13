# Bugs I Found and Why They Happened

## 1. AES IV Reuse in Encryption Service

**Severity:** Critical (security)

**File:** `lib/services/encryption_service.dart`

**The bug:** `encrypt()` initialized its `_ivStorageKey` and `_encryptionIV` fields once at construction time and reused the same IV for every encryption call. AES-CBC requires a fresh, random IV per encryption — reusing an IV with the same key allows an attacker to:
- Detect whether two plaintexts share a common prefix (the "tell" for repeated IVs in CBC)
- Recover the plaintext via crib-dragging if enough ciphertext blocks are captured

Since this is a finance app storing transaction details, account balances, and potentially export data, this was a real vulnerability, not a theoretical one.

**Root cause:** Three design problems converged:

1. **The IV was treated as a configuration parameter, not a per-message random value.** The original code stored it in a class field and initialized it once, following the same pattern as the encryption key. But a key is a long-lived secret; an IV is per-message metadata that should travel with the ciphertext.

2. **No unit tests for encryption.** The service had no test coverage at all, so the IV-reuse behavior was never caught — neither by a developer testing manually nor by CI. The service was implicitly trusted because "it's just encryption."

3. **No security review process.** The file had been in the codebase since the project's inception; the IV pattern was cargo-culted from an example without understanding why the example used a static IV (most examples are for demonstration only, where security is irrelevant).

**The fix:** Each `encrypt()` call now generates a fresh 16-byte random IV via `SecureRandom`, prepends it (base64-encoded) to the ciphertext, and `decrypt()` extracts the first 16 bytes before deciphering. A single existing field and its storage key (`_ivStorageKey`, `_encryptionIV`) were removed. Nine unit tests now verify: unique output per call, round-trip correctness, and wrong-key rejection.

**Why this matters for an SE review:** This is the kind of bug that automated security scanners (SonarQube, Semgrep, etc.) would miss because the IV is generated correctly (using `SecureRandom` from the `encrypt` package) — it's the *calling pattern* that's wrong, not the primitive. It demonstrates that I can find, diagnose, and fix a security vulnerability that requires understanding the semantics of a cryptographic mode, not just running a linter.

---

## 2. Dependency Injection Bypass (22 files)

**Severity:** High (architecture/maintainability)

**Files:** 22 files across `lib/`, including services, widgets, screens, modal bottom sheets, and a utility

**The bug:** `ApiService()`, `ObligationService()`, `AccountService()`, `NetworkService()`, `NotificationService()`, `BudgetRecommendationService()` — each of these was constructed directly with `new` somewhere in the codebase instead of being resolved through `getIt<ServiceType>()`. The project already had a registered service locator (`get_it`) with all services registered as lazy singletons, but ~25 construction sites bypassed it entirely.

**Root cause:**

1. **No lint rule or convention enforcement.** The project had `get_it` set up but no automated check (analyzer rule, test, or CI step) that would fail on direct `ServiceName()`. Without enforcement, the bypass pattern spread by copy-paste.

2. **The bypass was invisible in tests.** These direct constructions scattered through widget files were invisible to service-level tests — you'd only notice during an integration test or a runtime crash if the service had non-trivial initialization. The bypass pattern hid behind "it works in my local run because the default constructor still works."

3. **The bypass defeated the service locator's purpose.** All singleton management, lifecycle control, and testability gains (swapping a mock service for a real one) were silently circumvented. A test that registered `MockObligationService` in `get_it` would find that the widget still used the real `ObligationService()` directly.

**The fix:** All 22 files converted to `getIt<ServiceType>()`. Added a `setUp`/`tearDown` pair to `offline_indicator_test.dart` to register `NetworkService` in `get_it` (the widget switched from a direct constructor to `getIt`). Removed the direct constructor calls and the associated import of the concrete class in most cases — `service_locator.dart` handles the resolution now.

**What prevented me from fixing more:** The underlying `ApiService` is a 620-line facade wrapping 5+ data services, which creates multiple redundant data-access paths. The roadmap calls for collapsing the architecture to a consistent 3-layer pattern first, which will remove the redundant services entirely — making many more bypasses structurally impossible rather than requiring per-file patching.

---

## Pattern Summary

Both bugs share a common root: **the project had good infrastructure (encryption primitives, a service locator) but lacked the organizational habits to use it correctly** — no unit tests for security-critical code, no enforcement of DI conventions, no code review process that would catch pattern violations. These are culture problems, not technology problems, and fixing them required both the immediate patch and a process change (tests for security code, CI checks, documented conventions).

The AES bug specifically is the stronger interview artifact because it shows:
- Understanding of cryptographic primitive semantics (IVs in CBC mode)
- Ability to find a vulnerability in a pattern, not just in a function call
- Willingness to add tests that prove the fix works
- Documentation of *why* the fix is correct, not just *what* changed
