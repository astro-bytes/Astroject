Markdown
# Astroject

A lightweight and flexible dependency injection container for Swift.

[![Swift Version](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Overview

Astroject is designed to simplify dependency management in your Swift projects. It provides a clean and intuitive API for registering and resolving dependencies, supporting both synchronous and asynchronous factories, various instance scopes (singleton, prototype, weak), and extensible behaviors.

## Features

-   **Synchronous and Asynchronous Registrations:** Register dependencies with both synchronous and asynchronous factory closures.
-   **Instance Scopes:** Supports singleton, prototype, and weak instance scopes.
-   **Named Registrations:** Register dependencies with optional names for disambiguation.
-   **Circular Dependency Detection:** Prevents and reports circular dependency issues.
-   **Extensible Behaviors:** Add custom behaviors to the container's registration process.
-   **Assemblies:** Organize registrations into reusable modules.
-   **Thread-Safe Operations:** Designed for safe concurrent access.

## Installation

### Swift Package Manager

Add Astroject as a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "YOUR_GITHUB_REPO_URL", from: "1.0.0") // Replace with your repo URL and version
]
```
Then, import Astroject in your Swift files:
```swift
import Astroject
```

## Usage
### Basic Registration and Resolution
```swift
import Astroject

protocol Service {
    func doSomething()
}

class ConcreteService: Service {
    func doSomething() {
        print("Doing something...")
    }
}

let container = Container()

// Register a dependency
try container.register(Service.self) { _ in
    ConcreteService()
}

// Resolve the dependency
let service: Service = try container.resolve(Service.self)
service.doSomething() // Output: Doing something...
```

### Asynchronous Registration
```swift
import Astroject

protocol AsyncService {
    func doAsyncWork() async
}

class ConcreteAsyncService: AsyncService {
    func doAsyncWork() async {
        print("Doing asynchronous work...")
    }
}

let container = Container()

// Register an asynchronous dependency
try container.registerAsync(AsyncService.self) { _ in
    ConcreteAsyncService()
}

// Resolve the dependency asynchronously
let asyncService: AsyncService = try await container.resolveAsync(AsyncService.self)
await asyncService.doAsyncWork() // Output: Doing asynchronous work...
```

### Named Registrations
```swift
import Astroject

protocol Database {
    func connect()
}

class MySQLDatabase: Database {
    func connect() {
        print("Connecting to MySQL database...")
    }
}

class PostgreSQLDatabase: Database {
    func connect() {
        print("Connecting to PostgreSQL database...")
    }
}

let container = Container()

try container.register(Database.self, name: "mysql") { _ in
    MySQLDatabase()
}

try container.register(Database.self, name: "postgresql") { _ in
    PostgreSQLDatabase()
}

let mysql: Database = try container.resolve(Database.self, name: "mysql")
mysql.connect() // Output: Connecting to MySQL database...

let postgresql: Database = try container.resolve(Database.self, name: "postgresql")
postgresql.connect() // Output: Connecting to PostgreSQL database...
```
### Instance Scopes
```swift
import Astroject

class MyClass {
    init() {
        print("MyClass initialized")
    }
}

let container = Container()

// Singleton scope
try container.register(MyClass.self) { _ in
    MyClass()
}.singletonScope()

let instance1: MyClass = try container.resolve(MyClass.self) // Output: MyClass initialized
let instance2: MyClass = try container.resolve(MyClass.self) // No output (same instance)

// Prototype scope (default)
try container.register(MyClass.self, name: "prototype") { _ in
    MyClass()
}.prototypeScope()

let prototypeInstance1: MyClass = try container.resolve(MyClass.self, name: "prototype") // Output: MyClass initialized
let prototypeInstance2: MyClass = try container.resolve(MyClass.self, name: "prototype") // Output: MyClass initialized (new instance)
```

### Behaviors

```Swift
import Astroject

class LoggingBehavior: Behavior {
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: Registration<Product>,
        with name: String?
    ) {
        print("Registered \(type) with name: \(name ?? "nil")")
    }
}

let container = Container()
container.add(LoggingBehavior())

try container.register(Int.self) { _ in 42 } // Output: Registered Int with name: nil
```
### Assemblies

```Swift
import Astroject

class MyAssembly: Assembly {
    func assemble(container: Container) {
        try? container.register(String.self) { _ in "Hello, Astroject!" }
    }

    func loaded(resolver: Resolver) {
        if let message: String = try? resolver.resolve(String.self) {
            print("Assembly loaded with message: \(message)")
        }
    }
}

let container = Container()
let assembler = Assembler(container: container)
assembler.apply(assembly: MyAssembly()) // Output: Assembly loaded with message: Hello, Astroject!

let message: String = try container.resolve(String.self)
print(message) // Output: Hello, Astroject!
```
### Error Handling
Astroject provides detailed error handling through the ResolutionError and RegistrationError enums.

### Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues.

### License
Astroject is released under the MIT License. See [LICENSE](LICENSE) for details.
