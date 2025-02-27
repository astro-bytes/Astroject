//
//  RegistrationError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency registration.
public enum RegistrationError: Error {
    /// A registration is attempted with a ProductKey that already exists.
    case alreadyRegistered
}
