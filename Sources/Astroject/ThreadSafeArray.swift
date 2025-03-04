//
//  ThreadSafeArray.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// A thread-safe array that allows concurrent reads and synchronized writes.
actor ThreadSafeArray<Element: Sendable> {
    /// The internal array that stores the elements.
    private var array: [Element] = []

    /// The number of elements in the array.
    var count: Int { array.count }

    /// Indicates whether the array is empty.
    var isEmpty: Bool { array.isEmpty }

    /// Initializes a new `ThreadSafeArray` instance.
    init() {}

    /// Appends an element to the array.
    ///
    /// - Parameter element: The element to append.
    func append(_ element: Element) {
        array.append(element)
    }

    /// Inserts an element at a specific index.
    ///
    /// - Parameters:
    ///   - element: The element to insert.
    ///   - index: The index at which to insert the element.
    func insert(_ element: Element, at index: Int) {
        guard index <= array.count else { return }
        array.insert(element, at: index)
    }

    /// Removes the element at a specific index.
    ///
    /// - Parameter index: The index of the element to remove.
    func remove(at index: Int) {
        guard index < array.count else { return }
        array.remove(at: index)
    }

    /// Retrieves the element at a specific index.
    ///
    /// - Parameter index: The index of the element to retrieve.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    func get(at index: Int) -> Element? {
        guard index < array.count else { return nil }
        return array[index]
    }

    /// Executes a closure for each element in the array.
    ///
    /// - Parameter body: The closure to execute for each element.
    func forEach(_ body: @escaping (Element) -> Void) {
        array.forEach(body)
    }

    /// Transforms the elements of the array using a closure.
    ///
    /// - Parameter transform: The closure used to transform the elements.
    /// - Returns: An array of transformed elements.
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        try array.map(transform)
    }

    /// Filters the elements of the array using a closure.
    ///
    /// - Parameter isIncluded: The closure used to filter the elements.
    /// - Returns: An array of filtered elements.
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> [Element] {
        try array.filter(isIncluded)
    }

    /// Removes all elements from the array.
    func removeAll() {
        array.removeAll()
    }
}

extension ThreadSafeArray where Element: Equatable {
    /// Checks if the array contains a specific element.
    ///
    /// - Parameter element: The element to check for.
    /// - Returns: `true` if the array contains the element, `false` otherwise.
    func contains(_ element: Element) -> Bool {
        array.contains(element)
    }
}
