# Linting & Concurrency

Use when:

- SwiftLint flags `async_without_await` or other concurrency warnings.
- Need to decide: suppress, fix, or reconfigure concurrency lint rule.

Skip if:

- Compiler diagnostic, not lint rule. Use `actors.md`, `sendable.md`, or `threading.md`.

Jump to:

- SwiftLint Concurrency Rules Overview
- `async_without_await` Rule
- Suppression Strategies

## SwiftLint Concurrency Rules Overview

SwiftLint targets async/await and concurrency patterns. Fix vs. suppress decision is critical.

| Rule | Default | Purpose |
|------|---------|---------|
| `async_without_await` | warning | Flags `async` functions that never await |
| `unowned_variable_capture` | warning | Warns about `unowned` in closures (risky in async) |
| `class_delegate_protocol` | warning | Ensures delegates are class-bound (AnyObject) |
| `weak_delegate` | warning | Delegates should be weak to avoid retain cycles |

## SwiftLint: `async_without_await`

- **Intent**: No `async` declaration without awaiting.
- **Never "fix"** with fake suspension (e.g. `await Task.yield()`, `await Task { ... }.value`). Masks real issue, adds meaningless suspension points.
- **Legit use of `Task.yield()`**: OK in tests or scheduling control when yield truly needed; not as lint workaround.

### Diagnose why declaration is `async`
1) **Protocol requirement** — protocol method/property is `async`.
2) **Override requirement** — base class API is `async`.
3) **`@concurrent` requirement** — stays `async` even without `await`.
4) **Accidental/legacy `async`** — no caller needs async semantics.

### Preferred fixes (order)
1) **Remove `async`** (adjust call sites) when no async semantics needed.
2) If `async` required (protocol/override/@concurrent):
   - Re-evaluate upstream API if you own it (can it be non-async?).
   - If can't change it, keep `async` and **narrowly suppress** where appropriate (common for mocks/stubs/overrides).

### Suppression examples (keep scope tight)
```swift
// swiftlint:disable:next async_without_await
func fetch() async { perform() }

// For a block:
// swiftlint:disable async_without_await
func makeMock() async { perform() }
// swiftlint:enable async_without_await
```

### Quick checklist
- [ ] Confirm if `async` truly required (protocol/override/@concurrent).
- [ ] If not required, remove `async` and update callers.
- [ ] If required, prefer localized suppression over dummy awaits.
- [ ] Avoid new suspension points without intent.

## Compiler Warnings: Sendable & Isolation

Swift compiler generates concurrency warnings based on strict concurrency checking level.

### Common Warning Patterns

**"Capture of non-sendable type"**
```swift
// Warning: Capture of 'self' with non-sendable type 'MyClass' in a `@Sendable` closure
Task {
    self.doWork() // 'self' is non-Sendable
}
```

**Fixes (preference order):**
1. Make type `Sendable` if truly thread-safe
2. Use `@MainActor` isolation if UI-related
3. Capture only Sendable values instead of `self`
4. Use `@unchecked Sendable` with documented safety invariant (last resort)

**"Non-sendable result returned"**
```swift
// Warning: Non-sendable type 'MyResult' returned by implicitly async call
let result = await actor.getData() // Returns non-Sendable type
```

**Fixes:**
1. Make return type Sendable
2. Return Sendable projections (IDs, copies of data)
3. Keep processing within actor's isolation

### Actor Isolation Warnings

**"Main actor-isolated property accessed from non-isolated context"**
```swift
// Warning: Main actor-isolated property 'title' cannot be referenced from a non-isolated context
func updateTitle() {
    viewModel.title = "New" // viewModel is @MainActor
}
```

**Fixes:**
1. Mark calling function `@MainActor`
2. Use `await MainActor.run { }` for one-off access
3. Reconsider if property truly needs @MainActor isolation

## Suppression Strategies

### When to Suppress vs. Fix

**Fix when:**
- Warning identifies real data race risk
- Fix is straightforward (add Sendable, adjust isolation)
- Code is new or actively maintained

**Suppress when:**
- Protocol/inheritance requires signature
- Third-party code forces pattern
- Migration in progress (with tracked ticket)

### Suppression Annotations

```swift
// Suppress Sendable warnings for legacy imports
@preconcurrency import LegacyFramework

// Suppress for a single declaration
nonisolated(unsafe) var legacyCallback: (() -> Void)?

// Type-level suppression (use sparingly)
struct LegacyWrapper: @unchecked Sendable {
    // Document why this is safe
    private let lock = NSLock()
    private var value: Int
}
```

### Documentation Requirements

When using suppression annotations, document:
1. **Why** suppression needed
2. **What** invariant makes it safe
3. **When** it can be removed (link to migration ticket)

```swift
/// Thread-safe: Internal lock protects all mutations.
/// TODO: Remove @unchecked when migrated to actor (JIRA-1234)
final class ThreadSafeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
}
```