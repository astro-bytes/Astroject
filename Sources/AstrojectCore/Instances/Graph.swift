//
//  File.swift
//  Astroject
//
//  Created by Porter McGary on 5/19/25.
//

import Foundation

public class Graph<Product>: Instance {
    class Weak<Wrapped> {
        private weak var wrapped: AnyObject?
        
        var value: Wrapped? {
            get { wrapped as? Wrapped }
            set { wrapped = newValue as AnyObject }
        }
        
        init(_ wrapped: Wrapped) {
            self.value = wrapped
        }
    }
    
    let serialQueue = DispatchQueue(label: "graph.serialQueue")
    var instances: [Identifier: Weak<Product>] = [:]
    
    public func get(for identifier: Identifier) -> Product? {
        serialQueue.sync {
            instances[identifier]?.value
        }
    }
    
    public func set(_ product: Product, for identifier: Identifier) {
        serialQueue.sync {
            if instances[identifier] == nil {
                instances[identifier] = Weak(product)
            } else {
                instances[identifier]?.value = product
            }
        }
    }
    
    public func release(for identifier: Identifier?) {
        serialQueue.sync {
            guard let identifier else {
                self.instances.removeAll()
                return
            }
            self.instances.removeValue(forKey: identifier)
        }
    }
}
