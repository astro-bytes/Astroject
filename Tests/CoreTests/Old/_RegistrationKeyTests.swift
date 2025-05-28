////
////  RegistrationKeyTests.swift
////  Astroject
////
////  Created by Porter McGary on 5/22/25.
////
//
//import Testing
//@testable import AstrojectCore
//
//@Suite("Registration Key")
//struct RegistrationKeyTests {
//    @Test("Different Inits Product Same Key")
//    func differentInitsProductSameKey() {
//        typealias F = Factory<Int, Resolver>
//        
//        let syncFactory = F(.sync({ _ in 1 }))
//        let syncFactoryKey = RegistrationKey(factory: syncFactory)
//        let syncFactoryTypeKey = RegistrationKey(factoryType: F.SyncBlock.self, productType: Int.self)
//        
//        let asyncFactory = F(.async({ _ in 1 }))
//        let asyncFactoryKey = RegistrationKey(factory: asyncFactory)
//        let asyncFactoryTypeKey = RegistrationKey(factoryType: F.AsyncBlock.self, productType: Int.self)
//        
//        #expect(syncFactoryKey.hashValue == syncFactoryTypeKey.hashValue)
//        #expect(asyncFactoryKey.hashValue == asyncFactoryTypeKey.hashValue)
//        #expect(syncFactoryKey.hashValue != asyncFactoryKey.hashValue)
//        #expect(syncFactoryTypeKey.hashValue != asyncFactoryTypeKey.hashValue)
//    }
//    
//    @Test("Different Blocks Product Different Keys")
//    func differentBlocksProductDifferentKeys() {
//        typealias F = Factory<Int, Resolver>
//        
//        let asyncKey = RegistrationKey(factoryType: F.AsyncBlock.self, productType: Int.self)
//        let blockKey = RegistrationKey(factoryType: F.Block.self, productType: Int.self)
//        let syncKey = RegistrationKey(factoryType: F.SyncBlock.self, productType: Int.self)
//        
//        #expect(syncKey != asyncKey)
//        #expect(blockKey != syncKey)
//        #expect(asyncKey != blockKey)
//    }
//}
