# ``AstrojectNexus``

Register a type by its initializer and let the container resolve every parameter.

## Overview

Nexus adds `register(_:initializer:)` to every `Container`. Each initializer parameter
is resolved from the container by its type, so you no longer write a factory closure
that calls `resolve` for each dependency.

```swift
import AstrojectCore
import AstrojectSync
import AstrojectNexus

let container = SyncContainer()
try container.register(Logger.self, initializer: Logger.init).asSingleton()
try container.register(UserRepository.self, initializer: UserRepository.init)
try container.register(UserService.self, initializer: UserService.init)

let service = try container.resolve(UserService.self)
```

The result is a normal `Registrable`, so scopes, `implements`, names, behaviors and
circular dependency detection keep working. It works with `SyncContainer`,
`AsyncContainer`, and inside an `Assembly`.

### Async initializers

An `AsyncContainer` accepts both regular and `async` initializers and resolves
dependencies with `await`. A `SyncContainer` throws `AstrojectError.invalidFactory`
when given an `async` initializer.

### One runtime argument

When a type needs one value known only at resolve time, make it the first initializer
parameter and pass its type:

```swift
try container.register(PuzzleViewModel.self, argumentType: String.self, initializer: PuzzleViewModel.init)
let viewModel = try container.resolve(PuzzleViewModel.self, argument: "puzzle-42")
```

### Limits

- Every dependency resolves by type, with no name. Use `register(_:block:)` for a
  type that needs named dependencies.
- Only one runtime argument is supported, and it must come first.
- Trailing closures call the existing `block:` overloads. Use the `initializer:` label
  for automatic resolution.
