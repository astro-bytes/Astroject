# Prototype: one container, sync graph, async setup

Throwaway prototype for the Astroject 3.0/4.0 container design. It is a separate Swift 6.2 package and is not part of the `Astroject` package, so nothing here ships.

```sh
swift test --package-path Prototypes/UnifiedContainer
Prototypes/CompileChecks/check.sh   # code that must not compile
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

All 25 tests pass with strict concurrency and warnings as errors, and the compile checks fail where they should.

1. **The design holds up.** Async setup, providers (transient and lazy singleton), actors, `@MainActor` view models and 200 concurrent resolves all work, and every error depends only on how a type was registered.
2. **The container and its registrations are checked `Sendable`.** The container's only stored property is a `Mutex`. `register` and `registerProvider` take `@Sendable` factories (see 7), so `Registration` and `ProviderSource` no longer need `@unchecked`. The one unchecked spot left is the cached singleton: a singleton of a non-`Sendable` type is handed to every caller, as in Astroject 2.x.
3. **Main-actor resolving is a separate entry point.** Swift doesn't allow two methods that differ only in `@MainActor` (the prototype was written around that rule rather than testing it), so main-actor code resolves with `container.main.resolve(_:)`.
4. **Async code has to `await` the container initializer.** In an async function, Swift picks `init(assemblies:) async` over the sync one, so it's `try await UnifiedContainer(assemblies:)` there.
5. **Default main-actor isolation needs Swift 6.2 features.** In those apps assemblies are main-actor types. The async initializer and `AsyncSetup.setUp` had to be `nonisolated(nonsending)` (run on the caller's actor), or the compiler reports sending main-actor assemblies off the main actor as a data race. `registerMainActor` worked without changes.
6. **A lazy async singleton must be `Sendable`.** `registerProvider(...).asSingleton()` is only available for `Sendable` products, because one instance goes to many tasks. The compiler enforces it.
7. **`register` factories must be `@Sendable`, or default main-actor apps get a silent data race.** Before this change, a plain closure written in a default main-actor module, like `register(String.self) { _ in sharedSettings.theme }`, was a main-actor closure. Resolved from `Task.detached`, it ran on a background thread and read main-actor state, on macOS and Linux, with no trap and no warning. The `@unchecked Sendable` registration storage hid it from the compiler, and Swift adds no runtime check there.

   With `@Sendable` factories, `Prototypes/CompileChecks` (run by `check.sh` in CI) shows what the compiler now says:
   - Reading main-actor state in a `register` closure: "main actor-isolated property 'theme' can not be referenced from a Sendable closure".
   - Calling an explicit main-actor `init`: "call to main actor-isolated initializer 'init(theme:)' in a synchronous nonisolated context". Use `registerMainActor`.
   - A main-actor class's synthesized `init()` still compiles in `register`. That's safe: the object is main-actor isolated, and every use of its state still needs the main actor.
   - The cost: capturing a non-`Sendable` value no longer compiles ("capture of 'db' with non-Sendable type 'Database' in a '@Sendable' closure"). Register it with `register(_:instance:)` and resolve it instead, which is better DI style anyway.

   Nothing else in the tests had to change, apart from one default main-actor test moving to `registerMainActor`.
