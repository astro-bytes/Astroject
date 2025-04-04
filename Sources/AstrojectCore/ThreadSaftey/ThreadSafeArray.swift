//
// ThreadSafeArray.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// A thread-safe array that allows concurrent reads and synchronized writes.
///
/// The `ThreadSafeArray` class provides a thread-safe wrapper around a standard Swift array.
/// It uses a dispatch queue to synchronize write operations, ensuring data consistency in concurrent environments.
final class ThreadSafeArray<Element>: @unchecked Sendable {
    /// The dispatch queue used for synchronization.
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.array")
    /// The internal array that stores the elements.
    private var array: [Element] = []
    
    /// The number of elements in the array.
    var count: Int {
        return self.queue.sync {
            return self.array.count
        }
    }
    
    /// Indicates whether the array is empty.
    var isEmpty: Bool {
        return self.queue.sync {
            return self.array.isEmpty
        }
    }
    
    /// Initializes a new `ThreadSafeArray` instance.
    init() {}
    
    /// Appends an element to the array.
    ///
    /// - parameter element: The element to append.
    func append(_ element: Element) {
        self.queue.sync {
            self.array.append(element)
        }
    }
    
    /// Inserts an element at a specific index.
    ///
    /// - parameter element: The element to insert.
    /// - parameter index: The index at which to insert the element.
    func insert(_ element: Element, at index: Int) {
        self.queue.sync {
            guard index <= self.array.count, index >= 0 else { return }
            self.array.insert(element, at: index)
        }
    }
    
    /// Removes the element at a specific index.
    ///
    /// - parameter index: The index of the element to remove.
    func remove(at index: Int) {
        self.queue.sync {
            guard index < self.array.count, index >= 0 else { return }
            self.array.remove(at: index)
        }
    }
    
    /// Retrieves the element at a specific index.
    ///
    /// - parameter index: The index of the element to retrieve.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    func get(at index: Int) -> Element? {
        var result: Element?
        self.queue.sync {
            guard index < self.array.count, index >= 0 else { return }
            result = self.array[index]
        }
        return result
    }
    
    /// Executes a closure for each element in the array.
    ///
    /// - parameter body: The closure to execute for each element.
    func forEach(_ body: @escaping (Element) -> Void) {
        self.queue.sync {
            self.array.forEach(body)
        }
    }
    
    /// Transforms the elements of the array using a closure.
    ///
    /// - parameter transform: The closure used to transform the elements.
    /// - Returns: An array of transformed elements.
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        return try self.queue.sync {
            try self.array.map(transform)
        }
    }
    
    /// Filters the elements of the array using a closure.
    ///
    /// - parameter isIncluded: The closure used to filter the elements.
    /// - Returns: An array of filtered elements.
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> [Element] {
        return try self.queue.sync {
            try self.array.filter(isIncluded)
        }
    }
    
    /// Removes all elements from the array.
    func removeAll() {
        self.queue.sync {
            self.array.removeAll()
        }
    }
    
    /// Subscript access to the array elements.
    ///
    /// - parameter index: The index of the element.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    subscript(index: Int) -> Element? {
        get {
            return get(at: index)
        }
        set {
            queue.sync {
                guard let newValue = newValue,
                      index < self.array.count,
                      index >= 0
                else { return }
                self.array[index] = newValue
            }
        }
    }
}

extension ThreadSafeArray where Element: Equatable {
    /// Checks if the array contains a specific element.
    ///
    /// - parameter element: The element to check for.
    /// - Returns: `true` if the array contains the element, `false` otherwise.
    func contains(_ element: Element) -> Bool {
        return self.queue.sync {
            return self.array.contains(element)
        }
    }
}
