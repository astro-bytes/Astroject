//
//  Registrable.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

protocol Registrable {
    associatedtype Product
    
    var factory: Factory<Product> { get }
    var instance: any Instance<Product> { get }
}
