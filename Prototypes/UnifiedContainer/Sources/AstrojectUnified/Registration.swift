import Synchronization

/// How long a resolved instance lives.
public enum Scope: Sendable {
    /// A new instance on every resolve.
    case transient
    /// One instance, created on first resolve and kept.
    case singleton
}

/// One stored registration.
///
/// This is `@unchecked Sendable` because it stores the user's factory closure, which is
/// not `@Sendable` (requiring that would break factories that capture non-`Sendable`
/// state). Its mutable state is behind a `Mutex`.
final class Registration: @unchecked Sendable {
    enum Kind {
        /// A sync factory. Resolves from anywhere.
        case sync((any Resolver) throws -> Any)
        /// A `@MainActor` factory. Resolves only through `MainResolver`.
        case mainActor(@MainActor (MainResolver) throws -> Any)
        /// The type is created asynchronously; its `AsyncProvider` is registered separately.
        case providerMarker
    }

    private struct State: Sendable {
        var scope: Scope = .transient
        var cached: UncheckedBox<Any>?
    }

    let key: Key
    let kind: Kind
    private let state = Mutex(State())

    init(key: Key, kind: Kind) {
        self.key = key
        self.kind = kind
    }

    func setScope(_ scope: Scope) {
        state.withLock {
            $0.scope = scope
            $0.cached = nil
        }
    }

    /// Returns the cached instance, or builds one.
    ///
    /// The lock is not held while `build` runs, because factories resolve other
    /// registrations. If two threads race on a singleton, both may build one, but
    /// both get back the same stored instance.
    func instance(build: () throws -> Any) throws -> Any {
        let (scope, cached) = state.withLock { ($0.scope, $0.cached) }
        if let cached {
            return cached.value
        }
        let made = try build()
        guard scope == .singleton else {
            return made
        }
        let boxed = UncheckedBox<Any>(made)
        let stored = state.withLock { state -> UncheckedBox<Any> in
            if let existing = state.cached {
                return existing
            }
            state.cached = boxed
            return boxed
        }
        return stored.value
    }
}

/// Returned by `register`, for setting the scope.
public struct RegistrationHandle: Sendable {
    let registration: Registration

    @discardableResult
    public func asSingleton() -> RegistrationHandle {
        registration.setScope(.singleton)
        return self
    }

    @discardableResult
    public func asTransient() -> RegistrationHandle {
        registration.setScope(.transient)
        return self
    }
}
