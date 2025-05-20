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
    @TaskLocal static var current: Context = .init()
    
    /// The current depth of the dependency resolution.
    ///
    /// This property tracks how many levels deep the current dependency resolution
    /// is within the graph. A `depth` of 0 typically indicates the initial context,
    /// while incrementing values indicate nested resolutions.
    var depth: Int = 0
    /// A unique identifier for the current graph resolution scope.
    ///
    /// This `UUID` is used by `Graph` instance management to store and retrieve
    /// instances specific to the current resolution path, ensuring that instances
    /// within a given "graph" or "scope" are consistent.
    var graphID: UUID = UUID()
    
    /// Creates a new `Context` by incrementing the depth and retaining the current `graphID`.
    ///
    /// This method is used when resolving a dependency that is nested within the current
    /// resolution process, maintaining the same graph scope but indicating a deeper level.
    ///
    /// - Returns: A new `Context` instance with an incremented `depth` and the same `graphID`.
    func next() -> Context {
        return Context(depth: depth + 1, graphID: graphID)
    }
    
    /// Creates a new, fresh `Context` with a depth of 1 and a new, unique `graphID`.
    ///
    /// This method is typically called to start a new, top-level dependency resolution process,
    /// establishing a new `graphID` for any `Graph`-scoped instances.
    ///
    /// - Returns: A new `Context` instance with `depth` initialized to 1 and a newly generated `graphID`.
    static func fresh() -> Context {
        return Context(depth: 1, graphID: UUID())
    }
}
