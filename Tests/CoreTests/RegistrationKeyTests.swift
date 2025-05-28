//
//  RegistrationKeyTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/28/25.
//

import Testing

@Suite("Registration Key Tests")
struct RegistrationKeyTests {
    /**
     # 📘 Test Plan for `RegistrationKey.swift`
     
     This file is responsible for identifying unique registrations in the DI container. The following areas should be covered by unit tests:
     
     ---
     
     ## ✅ 1. Initialization
     
     Test each initializer to ensure all properties are set correctly.
     
     ### 🔹 `init(factoryType:productType:argumentType:name:)`
     - Should assign all four fields correctly.
     
     ### 🔹 `init(factoryType:productType:name:)`
     - Should assign `argumentType` to `nil`.
     
     ### 🔹 `init(factory: Factory<Product, Resolver>, name:)`
     - Should infer:
     - `productType == Product.self`
     - `factoryType == type(of: block)`
     - Test both `.sync` and `.async` block variants.
     
     ### 🔹 `init(factory: Factory<Product, (Resolver, Argument)>, name:)`
     - Should infer:
     - `productType == Product.self`
     - `argumentType == Argument.self`
     - `factoryType == type(of: block)`
     - Test both `.sync` and `.async` block variants.
     
     ---
     
     ## ✅ 2. Equality (`==`)
     
     Test equivalence and non-equivalence of `RegistrationKey` instances.
     
     ### 🔹 Equal Cases
     - Same `factoryType`, `productType`, `argumentType`, and `name`.
     
     ### 🔹 Unequal Cases
     - Different `name`
     - Different `productType`
     - Different `argumentType`
     - Different `factoryType`
     
     ---
     
     ## ✅ 3. Hashing
     
     Test that hash values match for equal keys and differ for unequal keys.
     
     ### 🔹 Equal Keys
     - Two equal keys must have identical hash values.
     
     ### 🔹 Unequal Keys
     - Keys that differ by any single field should ideally produce different hash values.
     
     ---
     
     ## ✅ 4. Argument Type Differentiation
     
     - Two keys with the same `productType` and `name` but different `argumentType` must not be equal.
     
     ---
     
     ## ✅ 5. Factory Type Differentiation
     
     - Two keys with the same `productType`, `argumentType`, and `name` but different `factoryType` (e.g., `.sync` vs `.async`) must not be equal.
     
     ---
     
     Let me know if you'd like mock types or factory helpers for writing the actual tests!
     
     */
}
