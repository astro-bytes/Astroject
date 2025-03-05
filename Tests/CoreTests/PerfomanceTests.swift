//
//  MockPerformanceBehavior.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//


//
//  PerformanceTests.swift
//  AstrojectTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Astroject // Replace Astroject with your actual module name

// Mock Behavior for performance testing
class MockPerformanceBehavior: Behavior {
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        // Simulate some non-trivial work
        for _ in 0..<100 {
            _ = sin(Double.random(in: 0..<1))
        }
    }
}

@Suite("Performance")
struct PerformanceTests {

    @Test func testRegistrationPerformance() async {
        let container = Container()
        let iterations = 1000

        await measure {
            for i in 0..<iterations {
                try container.register(Int.self, name: "int\(i)") { i }
            }
        }
    }

    @Test func testAsyncRegistrationPerformance() async {
        let container = Container()
        let iterations = 1000

        await measure {
            for i in 0..<iterations {
                try container.register(Int.self, name: "int\(i)") { i }
            }
        }
    }

    @Test func testResolutionPerformance() async {
        let container = Container()
        try! container.register(Int.self) { 42 }

        await measure {
            for _ in 0..<1000 {
                _ = try await container.resolve(Int.self, name: nil)
            }
        }
    }

    @Test func testComplexResolutionPerformance() async {
        let container = Container()
        try! container.register(Int.self) { 42 }
        try! container.register(String.self) { "test" }
        try! container.register(Double.self) { resolver in
            let intValue = try await resolver.resolve(Int.self, name: nil)
            let stringValue = try await resolver.resolve(String.self, name: nil)
            return Double(intValue) + Double(stringValue.count)
        }

        await measure {
            for _ in 0..<1000 {
                _ = try await container.resolve(Double.self, name: nil)
            }
        }
    }

    @Test func testConcurrentResolutionPerformance() async {
        let container = Container()
        try! container.register(Int.self) { 42 }
        let iterations = 1000
        let concurrentTasks = 10

        await measure {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    for _ in 0..<concurrentTasks {
                        group.addTask {
                            _ = try await container.resolve(Int.self, name: nil)
                        }
                    }
                }
            }
        }
    }

    @Test func testBehaviorPerformance() async {
        let container = Container()
        let behavior = MockPerformanceBehavior()
        container.add(behavior)
        let iterations = 1000

        await measure {
            for i in 0..<iterations {
                try container.register(Int.self, name: "int\(i)") { i }
            }
        }
    }

    @Test func testThreadSafeDictionaryPerformance() async {
        let dictionary = ThreadSafeDictionary<Int, Int>()
        let iterations = 10000
        let concurrentTasks = 10

        await measure {
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    for _ in 0..<concurrentTasks {
                        group.addTask {
                            if Int.random(in: 0..<2) == 0 {
                                dictionary.insert(i, for: i)
                            } else {
                                _ = dictionary.getValue(for: Int.random(in: 0..<iterations))
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func testThreadSafeArrayPerformance() async {
        let array = ThreadSafeArray<Int>()
        let iterations = 10000
        let concurrentTasks = 10

        await measure {
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    for _ in 0..<concurrentTasks {
                        group.addTask {
                            if Int.random(in: 0..<2) == 0 {
                                array.append(i)
                            } else {
                                _ = array.get(at: Int.random(in: 0..<array.count))
                            }
                        }
                    }
                }
            }
        }
    }
}