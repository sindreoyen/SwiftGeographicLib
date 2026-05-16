# Threading

Use when:

- Need to understand relationship between tasks and threads.
- Debugging suspension points, actor reentrancy, or unexpected execution contexts.
- Need Swift 6.2 behavior guidance (`nonisolated async`, `@concurrent`, `nonisolated(nonsending)`).

Skip if:

- Mainly need to protect mutable state. Use `actors.md`.
- Need to make types safe to transfer. Use `sendable.md`.

Jump to:

- Core Concepts (Tasks vs Threads)
- Cooperative Thread Pool
- Suspension Points and Actor Reentrancy
- Swift 6.2 Changes (SE-461, SE-466)
- Default Isolation Domain
- Debugging Thread Execution
- Common Misconceptions
- Migration Strategy

## Core Concepts

### What is a Thread?

System-level resource that runs instructions. High overhead for creation and switching. Swift Concurrency abstracts thread management away.

### Tasks vs Threads

**Tasks** = units of async work, not tied to specific threads. Swift dynamically schedules tasks on available threads from cooperative pool.

**Key insight**: No direct 1:1 task-to-thread relationship.

**Important (Swift 6+)**: Avoid `Thread.current` inside async contexts. Swift 6 language mode makes `Thread.current` unavailable from async contexts — compile error. Prefer reasoning via isolation domains; use Instruments and debugger to observe execution.

## Cooperative Thread Pool

Swift creates only as many threads as CPU cores. Tasks share these threads efficiently.

### How it works

1. **Limited threads**: Count matches CPU cores
2. **Task scheduling**: Tasks scheduled onto available threads
3. **Suspension**: At `await`, task suspends, thread freed for other work
4. **Resumption**: Task resumes on any available thread (not necessarily same one)

```swift
func example() async {
    print("Started on: \(Thread.current)")
    
    try await Task.sleep(for: .seconds(1))
    
    print("Resumed on: \(Thread.current)") // Likely different thread
}
```

### Benefits over GCD

**Prevents thread explosion**:
- No excessive thread creation
- No high memory overhead from idle threads
- No excessive context switching
- No priority inversion

**Better performance**:
- Fewer threads = less context switching
- Continuations instead of blocking
- CPU cores stay busy efficiently

## Threading Mindset → Isolation Mindset

### Old way (GCD)

```swift
// Thinking about threads
DispatchQueue.main.async {
    // Update UI on main thread
}

DispatchQueue.global(qos: .background).async {
    // Heavy work on background thread
}
```

### New way (Swift Concurrency)

```swift
// Thinking about isolation domains
@MainActor
func updateUI() {
    // Runs on main actor (usually main thread)
}

func heavyWork() async {
    // Runs on any available thread in pool
}
```

### Think in isolation domains

**Don't ask**: "What thread should this run on?"

**Ask**: "What isolation domain should own this work?"

- `@MainActor` for UI updates
- Custom actors for specific state
- Nonisolated for general async work

### Provide hints, not commands

```swift
Task(priority: .userInitiated) {
    await doWork()
}
```

Describes nature of work, not thread assignment. Swift optimizes execution.

## Suspension Points

### What is a suspension point?

Moment where task **may** pause to allow other work. Marked by `await`.

```swift
let data = await fetchData() // Potential suspension
```

**Critical**: `await` marks *possible* suspension, not guaranteed. If operation completes synchronously, no suspension occurs.

### Why suspension points matter

1. **Code may pause unexpectedly** — resumes later, possibly different thread
2. **State can change** — mutable state may be modified during suspension
3. **Actor reentrancy** — other tasks can access actor during suspension

Same entry-isolation rule applies to any unstructured task: choose startup isolation by what synchronous prefix needs. If nothing before first `await` needs main actor — whether that first op is `Task.sleep`, actor hop, `print`, or Sendable computation — prefer `Task { @concurrent in ... }` and hop back with `MainActor.run` only for UI mutation. If synchronous prefix already needs main actor for one statement, keep nearby cheap lines on main with it instead of splitting them out.

### Actor reentrancy example

```swift
actor BankAccount {
    private var balance: Int = 0
    
    func deposit(amount: Int) async {
        balance += amount
        print("Balance: \(balance)")
        
        await logTransaction(amount) // ⚠️ Suspension point
        
        balance += 10 // Bonus
        print("After bonus: \(balance)")
    }
    
    func logTransaction(_ amount: Int) async {
        try? await Task.sleep(for: .seconds(1))
    }
}

// Two concurrent deposits
async let _ = account.deposit(amount: 100)
async let _ = account.deposit(amount: 100)

// Unexpected: 100 → 200 → 210 → 220
// Expected:   100 → 110 → 210 → 220
```

**Why**: During `logTransaction`, second deposit runs, modifying balance before first completes.

### Avoiding reentrancy bugs

**Complete actor work before suspending**:

```swift
func deposit(amount: Int) async {
    balance += amount
    balance += 10 // Bonus applied first
    print("Final balance: \(balance)")
    
    await logTransaction(amount) // Suspend after state changes
}
```

**Rule**: Don't mutate actor state after suspension points.


## Choosing Task entry isolation

For unstructured `Task { ... }`, choose entry isolation based on synchronous prefix (everything before first `await`), not on where task was created.

Two common reasons bare `Task { ... }` starts on `@MainActor`:
- Task spawned from `@MainActor` context.
- Module enables default main-actor isolation (e.g., `defaultIsolation(MainActor.self)`).

Rule:
- Synchronous prefix contains main-actor work → keep inherited main-actor entry.
- Synchronous prefix contains no main-actor work → start with `Task { @concurrent in ... }`, hop back to `MainActor` only when needed.

```swift
// ❌ Synchronous prefix is empty; first work hops away
Task {
    await hopToOtherIsolationDomain()
}

// ❌ Synchronous prefix is only `print` (trivial, non-main); first await hops away
Task {
    print("Also not main-thread-bound")
    await hopToOtherIsolationDomain()
}

// ✅ Start off the main actor, hop back only for UI work
Task { @concurrent in
    await hopToOtherIsolationDomain()
    await MainActor.run { updateUI() }
}

// ✅ Synchronous prefix DOES contain main-actor work — keep inheritance
Task {
    print("debug")              // trivial, non-main — rides along
    self.isLoading = true       // needs @MainActor, before any await
    await fetchData()
}
```

Delayed-retry `Task.sleep` pattern (see `performance.md` "Match Task entry isolation to its synchronous prefix") is specialization of this rule: wait usually not UI-owned, final mutation is.

Note: `Task { @concurrent in ... }` changes closure isolation, so any capture of non-Sendable state from enclosing actor must move inside `MainActor.run { ... }` hop, or be captured weakly (e.g., `[weak self]` + `guard let self`) before use. Examples above stay safe by keeping `self` use inside `MainActor.run`. If body needs to touch non-Sendable state directly, see `sendable.md` before reaching for `@concurrent`.

## Thread Execution Patterns

### Default: Background threads

Tasks run on cooperative thread pool (background threads):

```swift
Task {
    print(Thread.current) // Background thread
}
```

### Main thread execution

Use `@MainActor` for main thread:

```swift
@MainActor
func updateUI() {
    Task {
        print(Thread.current) // Main thread
    }
}
```

### Inheritance example

```swift
@MainActor
func updateUI() {
    print("Main thread: \(Thread.current)")
    
    await backgroundTask() // Switches to background
    
    print("Back on main: \(Thread.current)") // Returns to main
}

func backgroundTask() async {
    print("Background: \(Thread.current)")
}
```

## Swift 6.2 Changes

### Nonisolated async functions (SE-461)

**Old behavior**: Nonisolated async functions always switch to background.

**New behavior**: Inherit caller's isolation by default.

```swift
class NotSendable {
    func performAsync() async {
        print(Thread.current)
    }
}

@MainActor
func caller() async {
    let obj = NotSendable()
    await obj.performAsync()
    // Old: Background thread
    // New: Main thread (inherits @MainActor)
}
```

### Enabling new behavior

In Xcode 16+:

```swift
// Build setting or swift-settings
.enableUpcomingFeature("NonisolatedNonsendingByDefault")
```

### Opting out with @concurrent

Force function to switch away from caller's isolation:

```swift
@concurrent
func performAsync() async {
    print(Thread.current) // Always background
}
```

### nonisolated(nonsending)

Prevent sending non-Sendable values across isolation:

```swift
nonisolated(nonsending) func storeTouch(...) async {
    // Runs on caller's isolation, no value sending
}
```

**Use when**: Method doesn't need to switch isolation, avoiding Sendable requirements.

## Default Isolation Domain (SE-466)

### Configuring default isolation

**Build setting** (Xcode 16+):
- Default Actor Isolation: `MainActor` or `None`

**Swift Package**:

```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .defaultIsolation(MainActor.self)
    ]
)
```

### Why change default?

Most app code runs on main thread. Setting `@MainActor` as default:
- Reduces false warnings
- Avoids "concurrency rabbit hole"
- Easier migration

### Inference with @MainActor default

```swift
// With @MainActor as default:

func f() {} // Inferred: @MainActor

class C {
    init() {} // Inferred: @MainActor
    static var value = 10 // Inferred: @MainActor
}

@MyActor
struct S {
    func f() {} // Inferred: @MyActor (explicit override)
}

```

### Per-module setting

Must opt in per module/package. Not global across dependencies.

### Backward compatibility

Opt-in only. Default remains `nonisolated` if not specified.

## Debugging Thread Execution

### Print current thread

**⚠️ Important**: `Thread.current` unavailable in Swift 6 language mode from async contexts. Compiler error: "Class property 'current' is unavailable from asynchronous contexts; Thread.current cannot be used from async contexts."

**Workaround** (Swift 6+ mode only):

```swift
extension Thread {
    public static var currentThread: Thread {
        Thread.current
    }
}

print("Thread: \(Thread.currentThread)")
```

### Debug navigator

1. Set breakpoint in task
2. Debug → Pause
3. Check Debug Navigator for thread info

### Verify main thread

```swift
assert(Thread.isMainThread)
```

## Common Misconceptions

### ❌ Each Task runs on new thread

**Wrong**. Tasks share limited thread pool, reuse threads.

### ❌ await blocks the thread

**Wrong**. `await` suspends task without blocking thread. Other tasks can use the thread.

### ❌ Task execution order is guaranteed

**Wrong**. Tasks execute based on system scheduling. Use `await` to enforce order.

### ❌ Same task = same thread

**Wrong**. Task can resume on different thread after suspension.

## Why Sendable Matters

Tasks move between threads unpredictably:

```swift
func example() async {
    print("Thread 1: \(Thread.current)")
    
    await someWork()
    
    print("Thread 2: \(Thread.current)") // Different thread
}
```

Values crossing suspension points may cross threads. **Sendable** ensures safety.

## Best Practices

1. **Stop thinking about threads** — think isolation domains
2. **Trust the system** — Swift optimizes thread usage
3. **Use @MainActor for UI** — clear, explicit main thread execution
4. **Minimize suspension points in actors** — avoid reentrancy bugs
5. **Complete state changes before suspending** — prevent inconsistent state
6. **Use priorities as hints** — not guarantees
7. **Make types Sendable** — safe across thread boundaries
8. **Enable Swift 6.2 features** — easier migration, better defaults
9. **Set default isolation for apps** — reduce false warnings
10. **Don't force thread switching** — let Swift optimize

## Migration Strategy

### For new projects (Xcode 16+)

1. Set default isolation to `@MainActor`
2. Enable `NonisolatedNonsendingByDefault`
3. Use `@concurrent` for explicit background work

### For existing projects

1. Gradually enable Swift 6 language mode
2. Consider default isolation change
3. Use `@concurrent` to maintain old behavior where needed
4. Migrate module by module

## Decision Tree

```
Need to control execution?
├─ UI updates? → @MainActor
├─ Specific state isolation? → Custom actor
├─ Background work? → Regular async (trust Swift)
└─ Need to force background? → @concurrent (Swift 6.2+)

Seeing Sendable warnings?
├─ Can make type Sendable? → Add conformance
├─ Same isolation OK? → nonisolated(nonsending)
└─ Need different isolation? → Make Sendable or refactor
```

## GCD to Isolation Domain Migration

Don't ask "what thread should this run on?" — ask "what isolation domain should own this work?"

- `DispatchQueue.main.async { }` → `@MainActor func updateUI()`
- `DispatchQueue.global().async { }` → `func work() async` (or `@concurrent` if must leave caller isolation)
- `DispatchQueue(label:).sync { }` → `actor` or `Mutex` for protecting state
- Serial queue for ordering → `actor` (guarantees serial access)

## Decision Rules

- UI state → usually `@MainActor`
- Mutable shared state → usually `actor`
- Plain async work with no isolated state → `async` API with explicit ownership
- Work that must hop away from caller isolation under Swift 6.2-era behavior → consider `@concurrent`

## Common Mistakes Agents Make

- Recommending GCD queue hopping when actor isolation already expresses ownership model.
- Debugging correctness by thread ID instead of by isolation and ordering.
- Treating `await` as blocking call — suspends task, frees thread.
- Mapping each `Task` to conceptual thread.
- Picking task entry isolation by enclosing context instead of task's synchronous prefix. `Task { ... }` from `@MainActor` whose first `await` immediately hops away (no main-actor work before it) should usually be `Task { @concurrent in ... }`.

## Performance Insights

### Why fewer threads = better performance

- **Less context switching**: CPU spends more time on actual work
- **Better cache utilization**: Threads stay on same cores longer
- **No thread explosion**: Predictable resource usage
- **Forward progress**: Threads never block, always productive

### Cooperative pool advantages

- Matches hardware (one thread per core)
- Prevents oversubscription
- Efficient task scheduling
- Automatic load balancing