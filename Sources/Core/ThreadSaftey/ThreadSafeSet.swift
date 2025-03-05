//
// ThreadSafeSet.swift
// Astroject
//
// Created by Porter McGary on 3/4/25.
//

import Foundation

/// A thread-safe set that allows synchronized access.
///
/// The `ThreadSafeSet` class provides a thread-safe wrapper around a standard Swift `Set`.
/// It uses a dispatch queue to synchronize access to the set, ensuring data consistency in concurrent environments.
final class ThreadSafeSet<Element: Hashable>: @unchecked Sendable {
    /// The dispatch queue used for synchronization.
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.set") // Serial queue
    /// The internal set that stores the elements.
    private var set: Set<Element> = []
    
    /// The number of elements in the set.
    var count: Int {
        return self.queue.sync {
            return self.set.count
        }
    }
    
    /// Indicates whether the set is empty.
    var isEmpty: Bool {
        return self.queue.sync {
            return self.set.isEmpty
        }
    }
    
    /// Initializes a new `ThreadSafeSet` instance.
    init() {}
    
    /// Inserts an element into the set.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: `true` if the element was inserted, `false` if it was already present.
    @discardableResult
    func insert(_ element: Element) -> Bool {
        return self.queue.sync {
            let (result, _) = self.set.insert(element)
            return result
        }
    }
    
    /// Removes an element from the set.
    ///
    /// - Parameter element: The element to remove.
    /// - Returns: The removed element, or `nil` if it was not found.
    @discardableResult
    func remove(_ element: Element) -> Element? {
        return self.queue.sync {
            return self.set.remove(element)
        }
    }
    
    /// Checks if the set contains a specific element.
    ///
    /// - Parameter element: The element to check for.
    /// - Returns: `true` if the set contains the element, `false` otherwise.
    func contains(_ element: Element) -> Bool {
        return self.queue.sync {
            return self.set.contains(element)
        }
    }
    
    /// Executes a closure for each element in the set.
    ///
    /// - Parameter body: The closure to execute for each element.
    func forEach(_ body: @escaping (Element) -> Void) {
        self.queue.sync {
            self.set.forEach(body)
        }
    }
    
    /// Transforms the elements of the set using a closure.
    ///
    /// - Parameter transform: The closure used to transform the elements.
    /// - Returns: A set of transformed elements.
    func map<T: Hashable>(_ transform: @escaping (Element) throws -> T) rethrows -> Set<T> {
        return try self.queue.sync {
            try Set(self.set.map(transform))
        }
    }
    
    /// Filters the elements of the set using a closure.
    ///
    /// - Parameter isIncluded: The closure used to filter the elements.
    /// - Returns: A set of filtered elements.
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> Set<Element> {
        return try self.queue.sync {
            try self.set.filter(isIncluded)
        }
    }
    
    /// Removes all elements from the set.
    func removeAll() {
        self.queue.sync {
            self.set.removeAll()
        }
    }
}
