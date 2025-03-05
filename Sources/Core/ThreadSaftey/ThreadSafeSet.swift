//
//  ThreadSafeSet.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation

/// A thread-safe set that allows concurrent reads and synchronized writes.
final class ThreadSafeArray<Element>: @unchecked Sendable {
    /// The dispatch queue used for synchronization.
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.array")
    /// The internal set that stores the elements.
    private var set: [Element] = []
    
    /// The number of elements in the set.
    var count: Int {
        self.queue.sync {
            self.set.count
        }
    }
    
    /// Indicates whether the set is empty.
    var isEmpty: Bool {
        self.queue.sync {
            self.set.isEmpty
        }
    }
    
    /// Initializes a new `ThreadSafeArray` instance.
    init() {}
    
    /// Appends an element to the set.
    ///
    /// - Parameter element: The element to append.
    func append(_ element: Element) {
        self.queue.sync {
            self.set.append(element)
        }
    }
    
    /// Inserts an element at a specific index.
    ///
    /// - Parameters:
    ///   - element: The element to insert.
    ///   - index: The index at which to insert the element.
    func insert(_ element: Element, at index: Int) {
        self.queue.sync {
            guard index <= self.set.count else { return }
            self.set.insert(element, at: index)
        }
    }
    
    /// Removes the element at a specific index.
    ///
    /// - Parameter index: The index of the element to remove.
    func remove(at index: Int) {
        self.queue.sync {
            guard index < self.set.count else { return }
            self.set.remove(at: index)
        }
    }
    
    /// Retrieves the element at a specific index.
    ///
    /// - Parameter index: The index of the element to retrieve.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    func get(at index: Int) -> Element? {
        var result: Element?
        self.queue.sync {
            guard index < self.set.count else { return }
            result = self.set[index]
        }
        return result
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
    /// - Returns: An set of transformed elements.
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        try self.queue.sync {
            try self.set.map(transform)
        }
    }
    
    /// Filters the elements of the set using a closure.
    ///
    /// - Parameter isIncluded: The closure used to filter the elements.
    /// - Returns: An set of filtered elements.
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> [Element] {
        try self.queue.sync {
            try self.set.filter(isIncluded)
        }
    }
    
    /// Removes all elements from the set.
    func removeAll() {
        self.queue.sync {
            self.set.removeAll()
        }
    }
    
    subscript(index: Int) -> Element? {
        get {
            return get(at: index)
        }
        
        set {
            queue.sync {
                guard let newValue = newValue,
                      index < self.set.count,
                      index >= 0
                else { return }
                self.set[index] = newValue
            }
        }
    }
}

extension ThreadSafeArray where Element: Equatable {
    /// Checks if the set contains a specific element.
    ///
    /// - Parameter element: The element to check for.
    /// - Returns: `true` if the set contains the element, `false` otherwise.
    func contains(_ element: Element) -> Bool {
        self.queue.sync {
            self.array.contains(element)
        }
    }
}
