//
//  FactoryRegistrable.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

protocol FactoryRegistrable {
    associatedtype Product
    
    var factory: Factory<Product> { get }
}
