//
//  Identifier.swift
//  Astroject
//
//  Created by Porter McGary on 5/19/25.
//

import Foundation

public struct Identifier: Identifiable, Hashable, Equatable {
    public let id: UUID = .init()
}
