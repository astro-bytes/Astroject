# Messages Playground

---

## Overview

This Swift playground demonstrates a **modern Swift architecture** for a simple messaging app, combining:

- **Dependency Injection** with `AstrojectCore` / `AstrojectSync`  
- **Async / actor-based repositories** for concurrency-safe state management  
- **SwiftUI** for reactive UI  
- **Test-driven design**, with isolated repository and view model tests  

The playground is fully self-contained and can be used as a **learning resource**, **proof-of-concept**, or **reference architecture** for Swift projects.

---

## Architecture Highlights

### 1. Service Layer

`MessageService` is an **async, sendable protocol** defining the interface for sending and fetching messages.  

The concrete `Service` implementation:

- Encodes/decodes `Message` objects with `Codable`
- Uses `URLSession` for network communication
- Is stateless and UI-independent

This separation enables **easy mocking for tests**.

---

### 2. Repository Layer

`Repository<Value>` is a **generic, async, actor-backed cache** abstraction.

Key features:

- Holds cached state
- Exposes an `AsyncStream` to observe updates
- Supports `refresh()` and `clear()`
- Thread-safe via `actor`

`AppMessageRepository` implements `MessageRepository` (messages specifically) and coordinates network fetching and publishing updates to its stream.

---

### 3. Model

`Message` is a **simple chat message model**:

- `Identifiable` – compatible with SwiftUI Lists  
- `Codable` – for network serialization  
- `Sendable` – concurrency-safe  
- Contains `Origin` enum to differentiate sender and recipient  

---

### 4. Dependency Injection

Assemblies handle **object graph composition**:

- `NetworkAssembly` – registers `URLSession`  
- `UtilityAssembly` – registers `Bundle` and `ProcessInfo`  
- `MessageAssembly` – registers `MessageService` and `MessageRepository`  
- `ViewModelAssembly` – registers `MessageViewModel` and handles `#if TEST` to swap in mocks  

DI allows **testable, composable, environment-specific dependency graphs**.

---

### 5. View Model

`MessageViewModel`:

- Observes the repository via `AsyncStream`
- Handles sending messages asynchronously
- Exposes observable state for SwiftUI
- Uses `nonisolated init` for DI safety while keeping all mutable state `@MainActor`

---

### 6. SwiftUI View

`MessageList` renders:

- A list of messages
- A text input field
- A send button
- Pull-to-refresh behavior via `refreshable`  
- Observes ViewModel state with `.task(model.observeMessages)`

---

### 7. Testing

The playground includes a **fully documented testing section** using Swift’s `Testing` library:

- `MockMessageService` – in-memory, async-safe mock
- `TestMessageAssembly` – overrides only the service layer
- Repository tests – validate caching and stream updates
- ViewModel tests – validate observable state and sending logic
- DI integration tests – demonstrate resolving a fully functional ViewModel with mock dependencies

This demonstrates **dependency injection as a testability enabler**.

---

## How to Run

1. Open the playground in Xcode 15+  
2. Run the playground to launch `SampleApp`  
3. Observe messages loading, sending, and UI updating in real time  
4. Optional: run the test section to validate repository and ViewModel logic

---

## Key Learning Points

- **Actor-based state management** for thread safety  
- **Async streams** for reactive data flow without Combine  
- **Dependency injection** using `AstrojectCore` for easy environment swapping  
- **Test-first design** – mock services, isolated repository and view model tests  
- **SwiftUI integration** with minimal boilerplate  

---

## Future Extensions

- Add **error handling and retry strategies**  
- Introduce **message timestamps and formatting**  
- Expand tests to cover **failure and empty state**  
- Implement **UI snapshots or SwiftUI previews**  
- Explore **time-controlled async testing** with `TestClock`  

---

## Contact / Credit

Created as a **teaching playground** to illustrate:

- Modern Swift concurrency patterns  
- DI-driven architecture  
- Testable SwiftUI + async logic
