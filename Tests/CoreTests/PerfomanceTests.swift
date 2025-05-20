//
//  PerformanceTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import XCTest
@testable import AstrojectCore

// swiftlint:disable identifier_name

class PerformanceTests: XCTestCase {
    let iterations = 1_000
    
    func testRegistrationPerformance() async throws {
        let container = Container()
        let iterations = iterations
        
        measure {
            for i in 0..<iterations {
                do {
                    try container.register(Int.self, name: "int\(i)") { i }
                } catch {
                    XCTAssertNotNil(error, "\(error)")
                }
            }
        }
    }
    
    func testResolutionPerformance() async throws {
        let container = Container()
        let iterations = iterations
        try container.register(Int.self) { 42 }
        
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                Task {
                    for _ in 0..<iterations {
                        _ = try await container.resolve(Int.self, name: nil)
                    }
                    semaphore.signal()
                }
            }
            
            semaphore.wait()
        }
    }
    
    func testComplexResolutionPerformance() async throws {
        let container = Container()
        let iterations = iterations
        try container.register(Int.self) { 42 }
        try container.register(String.self) { "test" }
        try container.register(Double.self) { resolver in
            let intValue = try await resolver.resolve(Int.self, name: nil)
            let stringValue = try await resolver.resolve(String.self, name: nil)
            return Double(intValue) + Double(stringValue.count)
        }
        
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                Task {
                    for _ in 0..<iterations {
                        _ = try await container.resolve(Double.self, name: nil)
                    }
                    semaphore.signal()
                }
            }
            
            semaphore.wait()
        }
    }
    
    func testConcurrentResolutionPerformance() async throws {
        let container = Container()
        try container.register(Int.self) { 42 }
        let iterations = 100
        let concurrentTasks = 10
        
        measure {
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for _ in 0..<iterations {
                        for _ in 0..<concurrentTasks {
                            group.addTask {
                                do {
                                    _ = try await container.resolve(Int.self)
                                } catch {
                                    XCTFail("Failed with Error - \(error)")
                                }
                            }
                        }
                    }
                    await group.waitForAll()
                }
            }
        }
    }
    
    func testBehaviorPerformance() async throws {
        let container = Container()
        let behavior = MockPerformanceBehavior()
        container.add(behavior)
        let iterations = iterations
        
        measure {
            for i in 0..<iterations {
                do {
                    try container.register(Int.self, name: "int\(i)") { i }
                } catch {
                    XCTAssertNotNil(error, "\(error)")
                }
            }
        }
    }
}

// swiftlint:enable identifier_name
