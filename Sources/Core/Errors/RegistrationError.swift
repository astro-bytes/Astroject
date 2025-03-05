//
//  RegistrationError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency registration.
public enum RegistrationError<Product>: LocalizedError {
    /// A registration is attempted with a ProductKey that already exists.
    case alreadyRegistered(type: Product.Type, name: String? = nil)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered:
            "A registration with the same ProductKey already exists."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .alreadyRegistered:
            "Attempting to register a dependency with a ProductKey that has already been used."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .alreadyRegistered:
            "Use a different ProductKey or remove the existing registration before registering a new one."
        }
    }
}

extension RegistrationError: Equatable where Product: Equatable {
    public static func == (lhs: RegistrationError<Product>, rhs: RegistrationError<Product>) -> Bool {
        switch (lhs, rhs) {
        case (.alreadyRegistered(let lhsType, let lhsName), .alreadyRegistered(type: let rhsType, name: let rhsName)):
            lhsType == rhsType && lhsName == rhsName
        }
    }
}
