//
// ThreadSafeDictionary.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A thread-safe dictionary that allows synchronized access to its key-value pairs.
///
/// The `ThreadSafeDictionary` class provides a thread-safe wrapper around a standard Swift dictionary.
/// It uses a dispatch queue to synchronize access to the dictionary, ensuring data
/// consistency in concurrent environments.
final class ThreadSafeDictionary<Key: Hashable, Value>: @unchecked Sendable {
    /// The dispatch queue used for synchronization.
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.dictionary")
    /// The internal dictionary that stores the key-value pairs.
    private var dictionary: [Key: Value]
    
    /// The number of key-value pairs in the dictionary.
    var count: Int {
        return queue.sync {
            return dictionary.count
        }
    }
    
    /// Indicates whether the dictionary is empty.
    var isEmpty: Bool {
        return queue.sync {
            return dictionary.isEmpty
        }
    }
    
    /// Initializes a new `ThreadSafeDictionary` instance with an initial dictionary.
    ///
    /// - parameter dictionary: The initial dictionary.
    init(from dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }
    
    /// Initializes a new empty `ThreadSafeDictionary` instance.
    convenience init() {
        self.init(from: [:])
    }
    
    /// Retrieves the value associated with a key.
    ///
    /// - parameter key: The key to retrieve the value for.
    /// - Returns: The value associated with the key, or `nil` if the key is not found.
    func getValue(for key: Key) -> Value? {
        return queue.sync {
            return dictionary[key]
        }
    }
    
    /// Inserts or updates a key-value pair in the dictionary.
    ///
    /// - parameter value: The value to insert or update.
    /// - parameter key: The key to associate with the value.
    func insert(_ value: Value, for key: Key) {
        queue.sync {
            dictionary[key] = value
        }
    }
    
    /// Checks if the dictionary contains a specific key.
    ///
    /// - parameter key: The key to check for.
    /// - Returns: `true` if the dictionary contains the key, `false` otherwise.
    func contains(_ key: Key) -> Bool {
        return queue.sync {
            return dictionary.keys.contains(key)
        }
    }
    
    /// Executes a closure for each key-value pair in the dictionary.
    ///
    /// - parameter block: The closure to execute for each key-value pair.
    func forEach(_ block: ((key: Key, value: Value)) -> Void) {
        queue.sync {
            dictionary.forEach(block)
        }
    }
    
    /// Transforms the key-value pairs of the dictionary using a closure.
    ///
    /// - parameter transform: The closure used to transform the key-value pairs.
    /// - Returns: An array of transformed elements.
    func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        return try queue.sync {
            try dictionary.map(transform)
        }
    }
    
    /// Removes all key-value pairs from the dictionary.
    func removeAll() {
        queue.sync {
            self.dictionary.removeAll()
        }
    }
}
