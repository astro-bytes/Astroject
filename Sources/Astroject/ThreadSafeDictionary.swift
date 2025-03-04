//
//  ThreadSafeDictionary.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// A thread-safe dictionary that allows synchronized access to its key-value pairs.
actor ThreadSafeDictionary<Key: Hashable, Value> {
    /// The internal dictionary that stores the key-value pairs.
    private var dictionary: [Key: Value]
    
    /// The number of key-value pairs in the dictionary.
    var count: Int { dictionary.count }
    /// Indicates whether the dictionary is empty.
    var isEmpty: Bool { dictionary.isEmpty }
    
    /// Initializes a new `ThreadSafeDictionary` instance with an initial dictionary.
    ///
    /// - Parameter dictionary: The initial dictionary.
    init(from dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }
    
    /// Initializes a new empty `ThreadSafeDictionary` instance.
    init() {
        self.init(from: [:])
    }
    
    /// Retrieves the value associated with a key.
    ///
    /// - Parameter key: The key to retrieve the value for.
    /// - Returns: The value associated with the key, or `nil` if the key is not found.
    func getValue(for key: Key) -> Value? {
        dictionary[key]
    }
    
    /// Inserts or updates a key-value pair in the dictionary.
    ///
    /// - Parameters:
    ///   - value: The value to insert or update.
    ///   - key: The key to associate with the value.
    func insert(_ value: Value, for key: Key) {
        dictionary[key] = value
    }
    
    /// Checks if the dictionary contains a specific key.
    ///
    /// - Parameter key: The key to check for.
    /// - Returns: `true` if the dictionary contains the key, `false` otherwise.
    func contains(_ key: Key) -> Bool {
        dictionary.keys.contains(key)
    }
    
    /// Executes a closure for each key-value pair in the dictionary.
    ///
    /// - Parameter block: The closure to execute for each key-value pair.
    func forEach(_ block: ((key: Key, value: Value)) -> Void) {
        dictionary.forEach(block)
    }
    
    /// Transforms the key-value pairs of the dictionary using a closure.
    ///
    /// - Parameter transform: The closure used to transform the key-value pairs.
    /// - Returns: An array of transformed elements.
    func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        try dictionary.map(transform)
    }
    
    /// Removes all key-value pairs from the dictionary.
    func removeAll() {
        self.dictionary.removeAll()
    }
}
