//
//  RegistrationKey.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

struct RegistrationKey {
    let productType: Any.Type
    let name: String?
    
    init<Product>(productType: Product.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
    }
}

extension RegistrationKey: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.productType).hash(into: &hasher)
        self.name?.hash(into: &hasher)
    }
}

extension RegistrationKey: Equatable {
    static func == (lhs: RegistrationKey, rhs: RegistrationKey) -> Bool {
        lhs.productType == rhs.productType && lhs.name == rhs.name
    }
}
