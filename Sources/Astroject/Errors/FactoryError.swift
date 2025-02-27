//
//  FactoryError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during factory creation.
public enum FactoryError: Error {
    /// An error that occurred within the factory closure.
    case underlyingError(Error)
}
