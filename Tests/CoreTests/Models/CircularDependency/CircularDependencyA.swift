//
//  CircularDependencyA.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

class CircularDependencyA {
    weak var classB: CircularDependencyB?
    
    init(classB: CircularDependencyB?) {
        self.classB = classB
    }
}
