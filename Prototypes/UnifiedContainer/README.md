# Prototype: one container, sync graph, async setup

Throwaway prototype for the Astroject 3.0/4.0 container design. It is a separate Swift 6.2 package and is not part of the `Astroject` package, so nothing here ships.

```sh
swift test --package-path Prototypes/UnifiedContainer
```

## The idea

- Factories and `resolve` are sync only. Nothing in the graph is async, so async can't spread from one registration to the ones that depend on it.
- Async work runs once, in `AsyncSetup.setUp(container:)`, before that assembly's `assemble(container:)`. Its result is registered with `register(_:instance:)`.
- A type whose creation needs `await` each time, such as one with an `async init`, is registered with `registerProvider`. Code resolves `AsyncProvider<Product>` synchronously and calls `try await provider()` where it can await. `.asSingleton()` on a provider creates once, with concurrent first calls sharing one creation.
- `@MainActor` types are registered with `registerMainActor` and resolved with `container.main.resolve(_:)`.
- Every error depends only on how something is registered, never on timing.

## What the tests cover

- `AstrojectUnifiedTests`: scopes, names, last-one-wins, cycles, 200 concurrent resolves of one type (the 2025 false-cycle bug), actors, async setup, the sync initializer refusing async setup, transient and singleton providers, `@MainActor` view models on and off the main actor.
- `DefaultMainActorTests`: the same kind of app code compiled with `.defaultIsolation(MainActor.self)`, the default for new Xcode 26 app targets.

## Not in the prototype

Arguments, graph scope, weak and disposable singletons, behaviors, forwarding, the registration report, environments and Nexus. They don't depend on the sync/async question.
