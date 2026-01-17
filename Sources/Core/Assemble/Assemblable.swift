//
//  Assemblable.swift
//  Astroject
//
//  Created by Porter McGary on 1/17/26.
//

import Foundation

/// A protocol that defines the requirements for objects that can be managed
/// by an `Assembler`. Types conforming to `Assemblable` can be assembled,
/// checked for assembly status, and have an associated `Assembler`.
public protocol Assemblable {
    
    /// The assembler responsible for assembling this object.
    ///
    /// This property is optional; a conforming type may not have an assembler
    /// assigned initially. Once set, the assembler manages the assembly state
    /// of this object.
    var assembler: Assembler? { get }
    
    /// Checks whether the object has been assembled.
    ///
    /// - Throws: `Assembler.Error.notAssembled` if the object is not yet assembled.
    ///
    /// Implementations can use this method to verify the assembly status
    /// of the object. A default implementation is provided in the protocol extension.
    func isAssembled() throws(Assembler.Error)
}

public extension Assemblable {
    
    /// Default implementation for checking if the object has been assembled.
    ///
    /// - Throws: `Assembler.Error.notAssembled` if `assembler.isAssembled` is `false`.
    ///
    /// This method safely unwraps the optional `assembler` and verifies
    /// that the object has been assembled according to its assembler.
    func isAssembled() throws(Assembler.Error) {
        if let assembler {
            guard assembler.isAssembled else {
                throw Assembler.Error.notAssembled
            }
        }
    }
}
