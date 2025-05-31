//
//  Context.swift
//  Astroject
//
//  Created by Porter McGary on 5/20/25.
//

import Foundation

/// A protocol representing the resolution context within a dependency injection graph.
///
/// `Context` is used to track the resolution state as dependencies are resolved,
/// including nesting depth, a unique graph identifier, and the current resolution path.
/// Conforming types must be `Sendable` to support usage in concurrent environments.
public protocol Context: Sendable {
    
    /// The current resolution context for the executing task.
    ///
    /// This property allows for implicit propagation of context during resolution,
    /// typically implemented using `@TaskLocal`. It enables tracking resolution state
    /// without explicitly passing the context through each method.
    static var current: TaskLocal<Self> { get }
    
    /// Creates a new, fresh resolution context.
    ///
    /// This is used to start a new top-level resolution graph. It should reset the depth
    /// and assign a new unique graph identifier, isolating it from any existing context.
    ///
    /// - Returns: A fresh `Context` instance ready to track a new resolution cycle.
    static func fresh() -> Self
    
    /// The current depth of the resolution process.
    ///
    /// Indicates how deep into the dependency graph the current resolution call stack is.
    /// A depth of 0 typically means no resolution has started.
    var depth: Int { get }
    
    /// The unique identifier associated with the current resolution graph.
    ///
    /// Used to scope `Graph`-managed instances to a specific resolution cycle.
    var graphID: UUID { get }
    
    /// The current resolution path as an ordered list of registration keys.
    ///
    /// This array is used to track which dependencies are actively being resolved.
    /// It can be used to detect circular dependencies.
    var graph: [RegistrationKey] { get }
    
    /// Returns a new `Context` representing a deeper resolution level.
    ///
    /// Typically used when beginning to resolve a nested dependency.
    ///
    /// - Returns: A copy of the current context with incremented depth.
    func next() -> Self
    
    /// Returns a new `Context` with a given key pushed onto the resolution path.
    ///
    /// This method is used to track the current dependency being resolved.
    ///
    /// - Parameter key: The `RegistrationKey` to append.
    /// - Returns: A new `Context` with the updated path.
    func push(_ key: RegistrationKey) -> Self
    
    /// Returns a new `Context` with the most recently pushed key removed.
    ///
    /// Indicates that resolution of the most recent dependency has completed.
    ///
    /// - Returns: A new `Context` with the path truncated by one element.
    func pop() -> Self
}
