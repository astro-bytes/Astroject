//
//  Context.swift
//  Astroject
//
//  Created by Porter McGary on 5/20/25.
//

import Foundation

/// A structure representing the current resolution context within a dependency graph.
///
/// `Context` is used to track the depth of dependency resolution and to provide a unique
/// identifier (`graphID`) for instances managed within a `Graph` instance management scope.
/// It conforms to `Sendable` to allow safe usage across concurrent tasks.
public struct Context: Sendable {
    /// A `TaskLocal` variable that holds the current `Context` for the executing task.
    ///
    /// This allows for implicit passing of the context through a call stack,
    /// making it convenient to access the current resolution context without
    /// explicitly passing it as a function argument. It defaults to a new, empty context.
    @TaskLocal public static var current: Context = .init()
    /// The current depth of the dependency resolution.
    ///
    /// This property tracks how many levels deep the current dependency resolution
    /// is within the graph. A `depth` of 0 typically indicates the initial context,
    /// while incrementing values indicate nested resolutions.
    public private(set) var depth: Int = 0
    /// A unique identifier for the current graph resolution scope.
    ///
    /// This `UUID` is used by `Graph` instance management to store and retrieve
    /// instances specific to the current resolution path, ensuring that instances
    /// within a given "graph" or "scope" are consistent.
    public private(set) var graphID: UUID = UUID()
    /// The current resolution path, represented as an array of `RegistrationKey`s.
    ///
    /// This array tracks the sequence of dependencies being resolved, which is crucial
    /// for detecting and preventing **circular dependencies**. Each key represents a
    /// dependency currently being constructed in the resolution graph.
    public private(set) var graph: [RegistrationKey] = []

    /// Initializes a new `Context` instance with specified depth, graph ID, and resolution graph.
    ///
    /// - Parameters:
    ///   - depth: The current depth of the resolution process. Defaults to 0 for an initial context.
    ///   - graphID: A unique identifier for the current resolution graph. Defaults to a new `UUID`.
    ///   - graph: The array representing the current resolution path. Defaults to an empty array.
    private init(depth: Int = 0, graphID: UUID = UUID(), graph: [RegistrationKey] = []) {
        self.depth = depth
        self.graphID = graphID
        self.graph = graph
    }

    /// Creates a new `Context` by incrementing the depth and retaining the current `graphID`.
    ///
    /// This method is used when resolving a dependency that is nested within the current
    /// resolution process, maintaining the same graph scope but indicating a deeper level.
    ///
    /// - Returns: A new `Context` instance with an incremented `depth` and the same `graphID`.
    public func next() -> Context {
        return Context(depth: depth + 1, graphID: graphID, graph: graph)
    }

    /// Creates a new, fresh `Context` with a depth of 1 and a new, unique `graphID`.
    ///
    /// This method is typically called to start a new, top-level dependency resolution process,
    /// establishing a new `graphID` for any `Graph`-scoped instances.
    ///
    /// - Returns: A new `Context` instance with `depth` initialized to 1 and a newly generated `graphID`.
    public static func fresh() -> Context {
        return Context(depth: 1, graphID: UUID())
    }

    /// Pushes a `RegistrationKey` onto the current resolution graph (path).
    ///
    /// This method creates a new `Context` with the provided `RegistrationKey` appended
    /// to the `graph` array. This is used to track the dependency being resolved
    /// and is essential for detecting circular dependencies.
    ///
    /// - Parameter key: The `RegistrationKey` to push onto the graph.
    /// - Returns: A new `Context` instance with the updated resolution graph.
    public func push(_ key: RegistrationKey) -> Context {
        var newGraph = graph
        newGraph.append(key)
        return Context(depth: depth, graphID: graphID, graph: newGraph)
    }

    /// Pops the last `RegistrationKey` from the current resolution graph (path).
    ///
    /// This method creates a new `Context` with the last `RegistrationKey` removed
    /// from the `graph` array. This signifies that the resolution of the last dependency
    /// in the path has completed, and the context is returning to a shallower level.
    ///
    /// - Returns: A new `Context` instance with the updated resolution graph.
    public func pop() -> Context {
        var newGraph = graph
        if !newGraph.isEmpty {
            newGraph.removeLast()
        }
        return Context(depth: depth, graphID: graphID, graph: newGraph)
    }
}
