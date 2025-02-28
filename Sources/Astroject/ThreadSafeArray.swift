//
//  ThreadSafeArray.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

final class ThreadSafeArray<Element: Sendable>: @unchecked Sendable {
    private let queue: DispatchQueue = .init(label: "com.astrobytes.astroject.array", attributes: .concurrent)
    private var array: [Element] = []
    
    var count: Int {
        self.queue.sync {
            self.array.count
        }
    }
    
    var isEmpty: Bool {
        self.queue.sync {
            self.array.isEmpty
        }
    }
    
    init() {}
    
    func append(_ element: Element) {
        self.queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    func insert(_ element: Element, at index: Int) {
        self.queue.async(flags: .barrier) {
            guard index <= self.array.count else { return }
            self.array.insert(element, at: index)
        }
    }
    
    func remove(at index: Int) {
        self.queue.async(flags: .barrier) {
            guard index < self.array.count else { return }
            self.array.remove(at: index)
        }
    }
    
    func get(at index: Int) -> Element? {
        var result: Element?
        self.queue.sync {
            guard index < self.array.count else { return }
            result = self.array[index]
        }
        return result
    }
    
    func forEach(_ body: @escaping (Element) -> Void) {
        self.queue.sync {
            self.array.forEach(body)
        }
    }
    
    func map<T>(_ transform: @escaping (Element) throws -> T) rethrows -> [T] {
        try self.queue.sync {
            try self.array.map(transform)
        }
    }
    
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> [Element] {
        try self.queue.sync {
            try self.array.filter(isIncluded)
        }
    }
    
    func removeAll() {
        self.queue.async(flags: .barrier) {
            self.array.removeAll()
        }
    }
}

extension ThreadSafeArray where Element: Equatable {
    func contains(_ element: Element) -> Bool {
        self.queue.sync {
            self.array.contains(element)
        }
    }
}
