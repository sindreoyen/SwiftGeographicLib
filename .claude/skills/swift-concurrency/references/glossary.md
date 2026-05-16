# Glossary

Use when:

- Need quick definition of Swift Concurrency term.
- Encounter unfamiliar terminology in other reference files.

Skip if:

- Need implementation patterns, not definitions. Use relevant reference file instead.

## Actor isolation

Compiler rule: actor-isolated state only accessible from actor's executor. Cross-actor access requires `await`.

## Global actor

Shared isolation domain applied via `@MainActor` or custom `@globalActor`. Types/functions on same global actor interact without crossing isolation.

## Default actor isolation

Module/target-level setting changing default isolation of declarations. App targets often choose `@MainActor` as default to reduce migration noise, but changes behavior and diagnostics.

## Strict concurrency checking

Compiler enforcement levels for Sendable and isolation diagnostics (minimal/targeted/complete). Raising level reveals more issues, can trigger "concurrency rabbit hole" unless migrated incrementally.

## Sendable

Marker protocol indicating type safe to transfer across isolation boundaries. Compiler verifies stored properties and captured values for thread-safety.

## @Sendable

Annotation for function types/closures executable concurrently. Tightens capture rules (captured values must be Sendable or safely transferred).

## Suspension point

`await` site where task may suspend and later resume. After suspension, assume other work ran and (for actors) state may have changed (reentrancy).

## Reentrancy (actors)

While actor suspended at `await`, other tasks can enter and mutate state. Code after `await` must not assume actor state unchanged.

## nonisolated

Marks declaration not isolated to surrounding actor/global actor. Use only when it truly does not touch isolated mutable state (typically immutable Sendable data).

## nonisolated(nonsending) (Swift 6.2+ behavior)

Opt-out preventing "sending" non-Sendable values across isolation while allowing async function to run in caller's isolation. Reduces Sendable friction when executor hop not needed.

## @concurrent (Swift 6.2+ behavior)

Explicitly opts nonisolated async function into concurrent execution (not inheriting caller's actor). Used during migration when enabling `NonisolatedNonsendingByDefault`.
Also valid on `Task { @concurrent in ... }` to opt task body out of enclosing actor's isolation; use when task's synchronous prefix (everything before first `await`) does not need main actor.

## @preconcurrency

Suppresses Sendable-related diagnostics from module predating concurrency annotations. Reduces noise but shifts safety responsibility to you.

## Region-based isolation / sending

Models ownership transfer so certain non-Sendable values move between regions safely. `sending` keyword enforces value no longer used after transfer.

## AsyncSequence

Protocol for types providing asynchronous sequential iteration. Conforms to `for await` loop pattern. Use for streaming data where elements arrive over time.

## AsyncStream

Concrete `AsyncSequence` bridging callback/delegate APIs to async/await. Provides `yield()` to emit values and `finish()` to complete stream.

## Continuation

Bridges callback APIs to async/await. `withCheckedContinuation` and `withCheckedThrowingContinuation` provide safe bridging with runtime checks. `withUnsafeContinuation` variants skip checks for performance-critical code.

## Task Local

Task-scoped storage propagating values through task hierarchy automatically. Declared with `@TaskLocal`, accessed via wrapper's static property. Child tasks inherit parent task locals.

## Cooperative thread pool

Tasks run on limited thread pool managed by runtime. Tasks yield cooperatively at suspension points. Avoid blocking operations that starve the pool.

## Executor

Scheduling mechanism determining where/when actor code runs. `MainActor` uses main thread executor. Custom actors use default executor unless custom specified.

## Structured concurrency

Child tasks have well-defined relationship to parent. Child tasks must complete before parent scope exits. Provides automatic cancellation propagation, prevents orphaned tasks. Implemented via `async let` and `TaskGroup`.

## Isolation domain

Boundary protecting mutable state from concurrent access. Each actor instance defines own isolation domain. `@MainActor` defines shared domain for UI work. Crossing boundaries requires explicit `await`.

## Task priority

Hint to runtime about task importance. Priorities: `.high`, `.medium`, `.low`, `.userInitiated`, `.utility`, `.background`. Higher priority tasks scheduled first. Priority can escalate when high-priority task awaits low-priority one.

## Cancellation

Cooperative mechanism to signal task should stop. Check `Task.isCancelled` or call `Task.checkCancellation()` (throws) in long-running work. Propagates to child tasks in structured concurrency.

## Debounce

Wait for inactivity period before emitting value. Reduces API calls for rapid inputs like search fields. Implemented as `debounce(for:tolerance:clock:)` in AsyncAlgorithms.

## Throttle

Emit at most one value per time interval, discarding intermediates. Prevents excessive calls from repeated actions like button taps. Implemented as `throttle(for:clock:reducing:)` in AsyncAlgorithms.

## Merge (AsyncAlgorithms)

Combines multiple async sequences into one, emitting values as they arrive from any source. Order interleaved by emission timing. Stable operator.

## CombineLatest (AsyncAlgorithms)

Combines multiple async sequences, emitting tuple whenever any source emits. Always uses latest value from each sequence. Stable operator.

## Zip (AsyncAlgorithms)

Combines multiple async sequences by pairing elements in order. Waits for all sequences to emit before producing tuple. Stable operator.

## AsyncChannel

`AsyncSequence` with backpressure sending semantics. Multiple producers send values safely to multiple consumers with flow control. Stable operator.

## AsyncThrowingChannel

Like AsyncChannel but can emit errors through stream. Stable operator.

## AsyncTimerSequence

`AsyncSequence` emitting value at regular intervals. Replaces timer-based publishers and manual sleep loops. Stable operator.