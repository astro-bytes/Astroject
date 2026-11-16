import Synchronization

/// Identifies one registration: a product type plus an optional name.
///
/// Unlike Astroject 2.x, the key does not include whether the factory is sync or async.
struct Key: Hashable, Sendable, CustomStringConvertible {
    let type: ObjectIdentifier
    let name: String?
    let description: String

    init<Product>(_ type: Product.Type, name: String?) {
        self.type = ObjectIdentifier(type)
        self.name = name
        let typeName = String(describing: type)
        self.description = name.map { "\(typeName)(\"\($0)\")" } ?? typeName
    }

    static func == (lhs: Key, rhs: Key) -> Bool {
        lhs.type == rhs.type && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
    }
}

/// The current resolution path, per task. Cycle detection reads it, so two tasks
/// resolving the same type at once never see each other's path (the 2025 bug).
enum ResolutionPath {
    @TaskLocal static var keys: [Key] = []

    static func push<T>(_ key: Key, _ body: () throws -> T) throws -> T {
        let current = keys
        if current.contains(key) {
            throw ContainerError.cyclicDependency((current + [key]).map(\.description))
        }
        return try $keys.withValue(current + [key]) {
            try body()
        }
    }
}

/// Holds a value the type system can't prove is safe to share.
/// Used only where the container's own locking makes access safe.
final class UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}
