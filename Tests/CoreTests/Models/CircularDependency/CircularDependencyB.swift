//
//  CircularDependencyB.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

class CircularDependencyB {
    var classA: CircularDependencyA?
    
    init(classA: CircularDependencyA?) {
        self.classA = classA
    }
}
