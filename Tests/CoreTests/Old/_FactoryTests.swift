////
////  FactoryTests.swift
////  CoreTests
////
////  Created by Porter McGary on 3/4/25.
////
//
//import Foundation
//import Testing
//@testable import Mocks
//@testable import AstrojectCore
//
//@Suite("Factory")
//struct FactoryTests {
//    @Test("Init")
//    func initialization() {
//        #expect(Factory(.sync { 20 }) != Factory(.sync { 20 }))
//        #expect(Factory(.async { 20 }) != Factory(.sync { 20 }))
//        #expect(Factory(.async { 20 }) != Factory(.async { 20 }))
//    }
//    
//    @Test("Equality")
//    func equality() {
//        let factory1 = Factory(.sync { 10 })
//        let factory2 = Factory(.async { 10 })
//        #expect(factory1 != factory2)
//        #expect(factory1 == factory1)
//    }
//    
//    @Test("Call as Function")
//    func asyncFunctionCall() async throws {
//        let factory = Factory(.async { 48 })
//        let result = try await factory()
//        #expect(result == 48)
//    }
//    
//    @Test("Call as Function")
//    func syncFunctionCall() throws {
//        let factory = Factory(.sync { 47 })
//        let result = try factory()
//        #expect(result == 47)
//    }
//    
//    @Test("Throws Errors")
//    func throwsErrorAsync() async throws {
//        let factory2 = Factory(.async {
//            throw MockError()
//        })
//        
//        await #expect(throws: MockError.self) {
//            try await factory2()
//        }
//    }
//    
//    @Test("Throws Error")
//    func throwsErrorSync() throws {
//        let factory1 = Factory(.sync {
//            throw MockError()
//        })
//        #expect(throws: MockError.self) {
//            try factory1()
//        }
//    }
//}
//
//private extension Factory where Arguments == () {
//    func callAsFunction() async throws -> Product {
//        try await block()
//    }
//    
//    func callAsFunction() throws -> Product {
//        try block()
//    }
//}
//
//private extension Factory.Block where Arguments == Void {
//    func callAsFunction() async throws -> Product {
//        switch self {
//        case .sync(let syncBlock):
//            try syncBlock(Void())
//        case .async(let asyncBlock):
//            try await asyncBlock(Void())
//        }
//    }
//    
//    func callAsFunction() throws -> Product {
//        switch self {
//        case .sync(let syncBlock):
//            try syncBlock(Void())
//        case .async:
//            throw AstrojectError.invalidFactory
//        }
//    }
//}
