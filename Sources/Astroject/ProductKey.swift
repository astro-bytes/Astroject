//
//  ProductKey.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

struct ProductKey {
    let productType: Any.Type
    let name: String?
    
    init(productType: Any.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
    }
}

extension ProductKey: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.productType).hash(into: &hasher)
        self.name?.hash(into: &hasher)
    }
}

extension ProductKey: Equatable {
    static func == (lhs: ProductKey, rhs: ProductKey) -> Bool {
        lhs.productType == rhs.productType && lhs.name == rhs.name
    }
}
