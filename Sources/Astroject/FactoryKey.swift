//
//  FactoryKey.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

struct FactoryKey {
    let productType: Any.Type
    let name: String?
    
    init(productType: Any.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
    }
}

extension FactoryKey: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.productType).hash(into: &hasher)
        self.name?.hash(into: &hasher)
    }
}

extension FactoryKey: Equatable {
    static func == (lhs: FactoryKey, rhs: FactoryKey) -> Bool {
        lhs.productType == rhs.productType && lhs.name == rhs.name
    }
}
