//
//  FactoryIdentifier.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

struct FactoryKey {
    let type: Any.Type
}

extension FactoryKey: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.type).hash(into: &hasher)
    }
}

extension FactoryKey: Equatable {
    static func == (lhs: FactoryIdentifier, rhs: FactoryIdentifier) -> Bool {
        lhs.type == rhs.type
    }
}
