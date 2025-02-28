//
//  ThreadSafeArray.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// A thread-safe array that allows concurrent reads and synchronized writes.
final class ThreadSafeArray<Element: Sendable>: @unchecked Sendable {
    /// The dispatch queue used for synchronization.
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.array", attributes: .concurrent)
    /// The internal array that stores the elements.
    private var array: [Element] = []
    
    /// The number of elements in the array.
    var count: Int {
        self.queue.sync {
            self.array.count
        }
    }
    
    /// Indicates whether the array is empty.
    var isEmpty: Bool {
        self.queue.sync {
            self.array.isEmpty
        }
    }
    
    /// Initializes a new `ThreadSafeArray` instance.
    init() {}
    
    /// Appends an element to the array.
    ///
    /// - Parameter element: The element to append.
    func append(_ element: Element) {
        self.queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    /// Inserts an element at a specific index.
    ///
    /// - Parameters:
    ///   - element: The element to insert.
    ///   - index: The index at which to insert the element.
    func insert(_ element: Element, at index: Int) {
        self.queue.async(flags: .barrier) {
            guard index <= self.array.count else { return }
            self.array.insert(element, at: index)
        }
    }
    
    /// Removes the element at a specific index.
    ///
    /// - Parameter index: The index of the element to remove.
    func remove(at index: Int) {
        self.queue.async(flags: .barrier) {
            guard index < self.array.count else { return }
            self.array.remove(at: index)
        }
    }
    
    /// Retrieves the element at a specific index.
    ///
    /// - Parameter index: The index of the element to retrieve.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    func get(at index: Int) -> Element? {
        var result: Element?
        self.queue.sync {
            guard index < self.array.count else { return }
            result = self.array[index]
        }
        return result
    }
    
    /// Executes a closure for each element in the array.
    ///
    /// - Parameter body: The closure to execute for each element.
    func forEach(_ body: @escaping (Element) -> Void) {
        self.queue.sync {
            self.array.forEach(body)
        }
    }
    
    /// Transforms the elements of the array using a closure.
    ///
    /// - Parameter transform: The closure used to transform the elements.
    /// - Returns: An array of transformed elements.
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        try self.queue.sync {
            try self.array.map(transform)
        }
    }
    
    /// Filters the elements of the array using a closure.
    ///
    /// - Parameter isIncluded: The closure used to filter the elements.
    /// - Returns: An array of filtered elements.
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> [Element] {
        try self.queue.sync {
            try self.array.filter(isIncluded)
        }
    }
    
    /// Removes all elements from the array.
    func removeAll() {
        self.queue.async(flags: .barrier) {
            self.array.removeAll()
        }
    }
}

extension ThreadSafeArray where Element: Equatable {
    /// Checks if the array contains a specific element.
    ///
    /// - Parameter element: The element to check for.
    /// - Returns: `true` if the array contains the element, `false` otherwise.
    func contains(_ element: Element) -> Bool {
        self.queue.sync {
            self.array.contains(element)
        }
    }
}
