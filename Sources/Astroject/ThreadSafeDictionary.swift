//
//  ThreadSafeDictionary.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

class ThreadSafeDictionary<Key: Hashable, Value> {
    private var queue: DispatchQueue = .init(label: "com.astrobytes.astroject")
    private var dictionary: [Key: Value]
    
    init(from dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }
    
    convenience init() {
        self.init(from: [:])
    }
    
    func getValue(for key: Key) -> Value? {
        queue.sync {
            dictionary[key]
        }
    }
    
    func insert(_ value: Value, for key: Key) {
        queue.sync {
            dictionary[key] = value
        }
    }
    
    func forEach(_ block: ((key: Key, value: Value)) -> Void) {
        queue.sync {
            dictionary.forEach(block)
        }
    }
    
    func map<T>(_ transform: ((key:Key, value: Value)) throws -> T) rethrows -> [T] {
        try queue.sync {
            try dictionary.map(transform)
        }
    }
    
    func removeAll() {
        queue.sync {
            self.dictionary.removeAll()
        }
    }
}
