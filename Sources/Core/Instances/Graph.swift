//  Graph.swift
//  Astroject
//
//  Created by Porter McGary on 5/19/25.
//

import Foundation

/// A thread-safe, in-memory store for `Product` instances, uniquely identified by `UUID`.
///
/// The `Graph` class provides a mechanism to store, retrieve, and release instances of a generic `Product` type.
/// It ensures thread safety for all operations using a private serial dispatch queue, making it suitable
/// for environments where multiple threads might access or modify the stored products concurrently.
public final class Graph<Product>: Instance, @unchecked Sendable {
    /// The private storage dictionary where `Product` instances are held.
    ///
    /// Each product is stored with a `UUID` as its key, which is typically derived from a `Context` object.
    /// Access to this dictionary is synchronized via `serialQueue` to prevent data corruption from concurrent access.
    private(set) var storage: [UUID: Product] = [:]
    /// A private serial dispatch queue used to synchronize access to the `storage` dictionary.
    ///
    /// All operations that read from or write to `storage` are performed within this queue
    /// to ensure thread safety and prevent race conditions.
    private let serialQueue = DispatchQueue(label: "com.astrobytes.astroject.graph.instance")
    
    public init() {}
    
    public func get(for context: any Context) -> Product? {
        serialQueue.sync {
            storage[context.graphID]
        }
    }
    
    public func set(_ product: Product, for context: any Context) {
        serialQueue.sync {
            storage[context.graphID] = product
        }
    }
    
    public func release(for context: (any Context)?) {
        guard let context = context else {
            serialQueue.sync {
                storage.removeAll()
            }
            return
        }
        
        serialQueue.sync {
            _ = storage.removeValue(forKey: context.graphID)
        }
    }
}
