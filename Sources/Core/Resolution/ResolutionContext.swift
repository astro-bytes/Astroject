//
//  ResolutionContext.swift
//  Astroject
//
//  Created by Porter McGary on 5/31/25.
//

import Foundation

/// A structure representing the current resolution context within a dependency graph.
///
/// `Context` is used to track the depth of dependency resolution and to provide a unique
/// identifier (`graphID`) for instances managed within a `Graph` instance management scope.
/// It conforms to `Sendable` to allow safe usage across concurrent tasks.
public struct ResolutionContext: Context {
    /// The task-local current resolution context.
    ///
    /// This value tracks the current `ResolutionContext` during dependency resolution,
    /// allowing context-sensitive instance management (e.g., for graph-scoped instances).
    /// It is automatically propagated across async tasks and allows Astroject to maintain
    /// isolation between different resolution flows.
    ///
    /// Example:
    /// - When resolving dependencies concurrently, each task will have its own context.
    /// - When resolving a dependency graph, `graphID` allows sharing the same instances.
    @TaskLocal public static var currentContext: ResolutionContext = .init()
    
    public static var current: TaskLocal<ResolutionContext> { $currentContext }
    
    public private(set) var depth: Int = 0
    public private(set) var graphID: UUID = UUID()
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
    
    public func next() -> ResolutionContext {
        return ResolutionContext(depth: depth + 1, graphID: graphID, graph: graph)
    }
    
    public static func fresh() -> ResolutionContext {
        return ResolutionContext(depth: 1, graphID: UUID())
    }
    
    public func push(_ key: RegistrationKey) -> ResolutionContext {
        var newGraph = graph
        newGraph.append(key)
        return ResolutionContext(depth: depth, graphID: graphID, graph: newGraph)
    }
    
    public func pop() -> ResolutionContext {
        var newGraph = graph
        if !newGraph.isEmpty {
            newGraph.removeLast()
        }
        return ResolutionContext(depth: depth, graphID: graphID, graph: newGraph)
    }
}
