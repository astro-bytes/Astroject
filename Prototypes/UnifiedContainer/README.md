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

## Results (Swift 6.2.4, Xcode 26.3 on macOS and `swift:6.2` on Linux)

All 26 tests pass with strict concurrency and warnings as errors.

1. **The design holds up.** Async setup, providers (transient and lazy singleton), actors, `@MainActor` view models and 200 concurrent resolves all work, and every error depends only on how a type was registered.
2. **The container is checked `Sendable`.** Its only stored property is a `Mutex`. `Registration` and `ProviderSource` are still `@unchecked Sendable`, because they hold the user's factory closures, which aren't `@Sendable`. Requiring `@Sendable` factories would remove that, but it would also break factories that capture non-`Sendable` state.
3. **Main-actor resolving is a separate entry point.** Swift doesn't allow two methods that differ only in `@MainActor` (the prototype was written around that rule rather than testing it), so main-actor code resolves with `container.main.resolve(_:)`.
4. **Async code has to `await` the container initializer.** In an async function, Swift picks `init(assemblies:) async` over the sync one, so it's `try await UnifiedContainer(assemblies:)` there.
5. **Default main-actor isolation needs Swift 6.2 features.** In those apps assemblies are main-actor types. The async initializer and `AsyncSetup.setUp` had to be `nonisolated(nonsending)` (run on the caller's actor), or the compiler reports sending main-actor assemblies off the main actor as a data race. Plain `register` closures and `registerMainActor` worked without changes.
6. **A lazy async singleton must be `Sendable`.** `registerProvider(...).asSingleton()` is only available for `Sendable` products, because one instance goes to many tasks. The compiler enforces it.

7. **Plain `register` closures in default main-actor apps run off the main actor without any error.** This is a real data race, not a crash. In a module with default main-actor isolation, `register(String.self) { _ in sharedSettings.theme }` compiles as a main-actor closure, so it may read main-actor state. Resolved from `Task.detached`, it ran on a background thread and returned the value, on both macOS and Linux, with no trap and no warning (`BackgroundResolveTests`). The hole is `Registration`'s `@unchecked Sendable`: the compiler trusts it, and Swift adds no runtime isolation check for these closures. `registerMainActor` is safe (it throws `mainActorRequired` off the main actor), and so is a `@Sendable` factory building a `nonisolated` type (20 concurrent resolves, one singleton).

   The likely fix is to require `@Sendable` on `register` factories, so the same code becomes a compile error and main-actor types have to go through `registerMainActor`. That isn't in the prototype yet.
