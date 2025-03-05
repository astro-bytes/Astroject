//
//  InstanceError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during instance management.
public enum InstanceError: LocalizedError {
    /// An instance is expected but not found.
    case noInstance
    
    public var errorDescription: String? {
        switch self {
        case .noInstance:
            "An instance was expected but not found."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .noInstance:
            "Attempted to retrieve an instance that was not available."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noInstance:
            "Ensure that the instance has been properly created and stored before attempting to retrieve it."
        }
    }
}

extension InstanceError: Equatable {}
