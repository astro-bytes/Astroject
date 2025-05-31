//
//  EndToEndContainerTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/31/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore
@testable import AstrojectSync

/**
 # SyncContainer End-to-End Test Requirements

 This document outlines the test coverage required for validating the `SyncContainer` component in Astroject.

 ---

 ## ✅ 1. Basic Registration and Resolution

 | ID   | Requirement                 | Description                                                                 |
 |------|-----------------------------|-----------------------------------------------------------------------------|
 | TC1  | Register simple factory     | Register a product with no argument and resolve it successfully             |
 | TC2  | Register argumented factory | Register a product with an argument and resolve it using that argument      |
 | TC3  | Register named factory      | Register a product under a specific name and resolve it using the same name |
 | TC4  | Resolve unregistered type   | Attempt to resolve an unregistered product and expect `noRegistrationFound` |
 | TC5  | Wrong argument type         | Register with one argument type, resolve with another — should fail         |

 ---

 ## 🔁 2. Registration Overriding

 | ID   | Requirement                    | Description                                                                 |
 |------|--------------------------------|-----------------------------------------------------------------------------|
 | TC6  | Allow override                 | Register type twice with `isOverridable: true`; second one replaces first   |
 | TC7  | Disallow override              | Register with `isOverridable: false`, re-register — expect `alreadyRegistered` error |
 | TC8  | Mixed override states conflict | Register `true` then `false` — expect conflict and error                    |

 ---

 ## 🔒 3. Thread Safety

 | ID   | Requirement              | Description                                                                 |
 |------|--------------------------|-----------------------------------------------------------------------------|
 | TC9  | Concurrent register      | Register multiple factories concurrently — no race conditions or crashes     |
 | TC10 | Concurrent resolve       | Resolve multiple types concurrently — all return correct results             |
 | TC11 | Register + resolve mix   | Register and resolve types in parallel — consistent and correct behavior     |

 > 💡 Use `DispatchQueue.concurrentPerform` and `XCTestExpectation` for concurrency tests.

 ---

 ## 🔁 4. Resolution Context Handling

 | ID   | Requirement                   | Description                                                                 |
 |------|-------------------------------|-----------------------------------------------------------------------------|
 | TC12 | Nested resolution works       | A depends on B — resolving A also resolves B correctly with shared context  |
 | TC13 | Circular dependency detected  | A ↔ B — should throw `cyclicDependency` error                               |
 | TC14 | Fresh graph per resolution    | Each top-level resolution should create a new graph ID                      |

 ---

 ## 🧠 5. Behavior Callbacks

 | ID   | Requirement                | Description                                                                 |
 |------|----------------------------|-----------------------------------------------------------------------------|
 | TC15 | `didRegister` gets called  | Registering triggers `didRegister` on all added behaviors                   |
 | TC16 | `didResolve` gets called   | Resolving triggers `didResolve` on all behaviors                            |
 | TC17 | Multiple behaviors work    | All registered behaviors are invoked in order                               |

 ---

 ## 🧹 6. State and Introspection

 | ID   | Requirement                     | Description                                                                 |
 |------|----------------------------------|-----------------------------------------------------------------------------|
 | TC18 | `isRegistered` returns true     | After registering, `isRegistered` returns true                              |
 | TC19 | `isRegistered` returns false    | For unknown or mismatched name/argument types                               |
 | TC20 | `clear()` resets container      | All registrations and behaviors are cleared                                 |
 */
@Suite("End to End Container Tests")
struct EndToEndContainerTests {}
