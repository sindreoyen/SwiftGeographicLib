# Async/Await Basics

Use when:

- Starting fresh with async/await, need foundational patterns.
- Converting callback-based code to async/await.
- Need to understand execution order and sync-to-async bridge.

Skip if:

- Need parallel execution with task groups or `async let`. Use `tasks.md`.
- Need stream-based async iteration. Use `async-sequences.md`.

Jump to:

- Function Declaration
- Execution Order
- Parallel Execution with async let
- URLSession with Async/Await
- Migration Strategy

## Function Declaration

Mark functions with `async` for async work:

```swift
func fetchData() async -> Data {
    // async work
}

func fetchData() async throws -> Data {
    // async work that can fail
}
```

**Key benefit over closures**: Compiler enforces return values. No forgotten completion handlers.

## Calling Async Functions

### From synchronous context

Use `Task` to bridge sync to async:

```swift
Task {
    let data = try await fetchData()
}
```

### From async context

Use `await` directly:

```swift
func processData() async throws {
    let data = try await fetchData()
    // process data
}
```

## Execution Order

Structured concurrency executes top-to-bottom:

```swift
let first = try await fetchData(1)   // Waits for completion
let second = try await fetchData(2)  // Starts after first completes
let third = try await fetchData(3)   // Starts after second completes
```

Code after `await` only runs once awaited function returns.

## Parallel Execution with async let

Use `async let` for concurrent operations:

```swift
async let data1 = fetchData(1)
async let data2 = fetchData(2)
async let data3 = fetchData(3)

let results = try await [data1, data2, data3]
```

### How async let works

- **Starts immediately**: Executes right away, before `await`
- **Structured concurrency**: Auto-canceled when leaving scope
- **Error handling**: One failure implicitly cancels others when awaiting grouped results
- **No redundant keywords**: Don't use `try await` in `async let` line itself

```swift
// Redundant - avoid this
async let data = try await fetchData()

// Correct - errors handled at await point
async let data = fetchData()
let result = try await data
```

### When to use async let

**Use when:**
- Tasks don't depend on each other
- Task count known at compile-time
- Want auto-cancellation on scope exit

**Avoid when:**
- Tasks must run sequentially
- Need dynamic task spawning (use `TaskGroup`)
- Need manual cancellation control

### Limitations

- Can't use at top-level declarations (function bodies only)
- Non-awaited tasks may be implicitly canceled

## URLSession with Async/Await

URLSession provides async alternatives to closure-based APIs:

```swift
// Closure-based (old)
URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else { return }
    // handle response
}.resume()

// Async/await (modern)
let (data, response) = try await URLSession.shared.data(for: request)
```

### Benefits over closures

- No optional `data` or `response` to unwrap
- Automatic error throwing
- Compiler enforces return values
- Simpler error handling with do-catch

### Complete network request pattern

```swift
func fetchUser(id: Int) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse
    }
    
    return try JSONDecoder().decode(User.self, from: data)
}
```

### POST requests with JSON

```swift
func createUser(_ user: User) async throws -> User {
    let url = URL(string: "https://api.example.com/users")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(user)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse
    }
    
    return try JSONDecoder().decode(User.self, from: data)
}
```

## Typed Errors (Swift 6)

Specify exact error types for better API contracts:

```swift
enum NetworkError: Error {
    case invalidResponse
    case decodingFailed(DecodingError)
    case requestFailed(URLError)
}

func fetchData() async throws(NetworkError) -> Data {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch let error as URLError {
        throw .requestFailed(error)
    } catch {
        throw .invalidResponse
    }
}
```

Callers know exactly which errors to handle.

## Migration Strategy

Converting closure-based code:

1. **Add new async method alongside old one** — keeps code compiling
2. **Update method signature** — add `async`, remove completion parameter
3. **Replace closure calls with await** — use URLSession async APIs
4. **Remove optional unwrapping** — async APIs return non-optional values
5. **Simplify error handling** — use do-catch instead of nested closures
6. **Return directly** — compiler enforces return values

## Common Patterns

### Sequential execution (when order matters)

```swift
let user = try await fetchUser(id: 1)
let posts = try await fetchPosts(userId: user.id)
let comments = try await fetchComments(postIds: posts.map(\.id))
```

### Parallel execution (when independent)

```swift
async let user = fetchUser(id: 1)
async let settings = fetchSettings()
async let notifications = fetchNotifications()

let (userData, settingsData, notificationsData) = try await (user, settings, notifications)
```

### Mixed execution

```swift
// Fetch user first (required for next step)
let user = try await fetchUser(id: 1)

// Then fetch related data in parallel
async let posts = fetchPosts(userId: user.id)
async let followers = fetchFollowers(userId: user.id)
async let following = fetchFollowing(userId: user.id)

let profile = Profile(
    user: user,
    posts: try await posts,
    followers: try await followers,
    following: try await following
)
```