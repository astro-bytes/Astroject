//
//  InstanceError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during instance management.
public enum InstanceError: Error {
    /// An instance is expected but not found.
    case noInstance
}
