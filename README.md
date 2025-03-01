# Astroject

A lightweight and flexible dependency injection container for Swift.

[![Swift Version](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Overview
Astroject is designed to simplify dependency management in your Swift projects. It provides a clean and intuitive API for registering and resolving dependencies, supporting both synchronous and asynchronous factories, various instance scopes (singleton, prototype, weak), and extensible behaviors. Many ideas came from a Sister Library [Swinject](https://github.com/Swinject/Swinject)

## API Documentation
Coming Soon...
[DocC]()

## Features
- **Synchronous and Asynchronous Registrations:** Register dependencies with both synchronous and asynchronous factory closures.
- **Instance Scopes:** Supports singleton, prototype, and weak instance scopes.
- **Named Registrations:** Register dependencies with optional names for disambiguation.
- **Circular Dependency Detection:** Prevents and reports circular dependency issues.
- **Extensible Behaviors:** Add custom behaviors to the container's registration process.
- **Assemblies:** Organize registrations into reusable modules.
- **Thread-Safe Operations:** Designed for safe concurrent access.

## Requirements
- iOS 16.0+ / MacOS 13.0+ / WatchOS ??.?+ / tvOS ??.?+
- Swift 5.5+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add Astroject as a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/astro-bytes/Astroject", from: "1.0.0")
]
```
Then, import Astroject in your Swift files:
```swift
import Astroject
```

## Usage
### Basic Registration and Resolution
This process is the most common usage of Astroject. Registering and resolving synchronous objects.

```swift
import Astroject

protocol Service {
    func doSomething()
}

class ConcreteService: Service {
    func doSomething() {}
}

let container = Container()

// Register a dependency
try container.register(Service.self) { _ in
    ConcreteService()
}

// Resolve the dependency
let service: Service = try container.resolve(Service.self)
service.doSomething()
```

### Asynchronous Registration and Resolution
Asynchronous registration primary supports any initializer that needs to run asynchronously. This tends to happen often with classes wrapped with @MainActor.

```swift
import Astroject

protocol AsyncService {
    func doWork()
}

@MainActor
class ConcreteAsyncService: AsyncService {
    func doWord() {}
}

let container = Container()

// Register an asynchronous dependency
try container.registerAsync(AsyncService.self) { _ in
    await ConcreteAsyncService()
}

// Resolve the dependency asynchronously
let asyncService: AsyncService = try await container.resolveAsync(AsyncService.self)
asyncService.doWork()
```

### Named Registrations and Resolution
Additionally with Synchronous or Asynchronous Registrations you can provide a name attribute to ensure the registration is uniquely stored when storing the same type more than once.
```swift
import Astroject

protocol Database {
    func connect()
}

class MySQLDatabase: Database {
    func connect() {}
}

class PostgreSQLDatabase: Database {
    func connect() {}
}

let container = Container()

try container.register(Database.self, name: "mysql") { _ in
    MySQLDatabase()
}

try container.register(Database.self, name: "postgresql") { _ in
    PostgreSQLDatabase()
}

let mysql: Database = try container.resolve(Database.self, name: "mysql")
mysql.connect()

let postgresql: Database = try container.resolve(Database.self, name: "postgresql")
postgresql.connect()
```

### Intuitive Registration
Coming Soon...

### Resource File Registration
Coming Soon...

### Overriding Registrations
Astroject naturally supports overridable registrations, meaning that when one registration is registered under the same type multiple times the latest registration will be used.

Here we will first register 42 as an Int in container and then immediately register 99 under the same key.
```swift
let container = Container()
try container.register(Int.self) { _ in 42 }
try container.register(Int.self) { _ in 99 }
let value = container.resolve(Int.self) // Returns 99
```
As you can see the value will no longer only return 99. 
This is a powerful natural methodology. Allowing for your code to automatically override objects if you need to inject a Mocked Version of your class when running unit tests.

Additionally we also provide a way to prevent this natural overriding if you ever want to enforce only one registration at a time. This can be done during the registration process like such.
```swift
let container = Container()
container.register(Int.self, overridable: false) { _ in 42}
```
Now if we try to register another Int anywhere else during our registration process the register will fail and throw a `RegistrationError.alreadyRegistered` error. This gives you as the developer more control over registrations and their flows.
```swift
try container.register(Int.self) { _ in 99 } // Fails and throws an error
```

### Arguments
Coming soon...

### Instance Scopes
Astroject out of the box supports the following instance scopes.
```swift 
class MyClass {
    init() {
        print("MyClass initialized")
    }
}

let container = Container()
```
- Prototype(default) - A new instance is generated through every resolve for that object.
    ```swift
    try container.register(MyClass.self, name: "prototype") { _ in
        MyClass()
    }

    // Output: MyClass initialized
    let prototypeInstance1: MyClass = try container.resolve(MyClass.self, name: "prototype") 
    
    // Output: MyClass initialized (new instance)
    let prototypeInstance2: MyClass = try container.resolve(MyClass.self, name: "prototype") 
    ```
- Singleton - Instance maintained and kep throughout the life time of the container.
    ```swift
    try container.register(MyClass.self) { _ in
        MyClass()
    }
    .asSingleton()
    
    // Output: MyClass initialized
    let instance1: MyClass = try container.resolve(MyClass.self) 
    
    // No output (same instance)
    let instance2: MyClass = try container.resolve(MyClass.self) 
    ```
- Weak - As long as you retain an instance to the object the instance remains in the container when asked for. If you have no references to the class then container will deallocate its reference.
    ```swift
    try container.register(MyClass.self) { _ in
        MyClass()
    }
    .asWeak()

    // Output: MyClass initialized
    var instance1: MyClass? = try container.resolve(MyClass.self)
    // No output (same instance)
    var instance2: MyClass? = try container.resolve(MyClass.self)

    // Release instance1 reference
    instance1 = nil

    // No output (same instance) because instance2 was not deallocated
    var instance3: MyClass? = try container.resolve(MyClass.self)

    // Release instance 2 & 3 reference
    instance2 = nil
    instance3 = nil

    // Output: MyClass initialized
    let instance4: MyClass = try container.resolve(MyClass.self)
    ```

#### Custom Scopes
Additionally you can create your own Scopes through utilization of the `Instance` protocol and the `as` function on `any Registrable`.
```swift
class ExampleInstance: Instance {
  // Conform to Instance methods
}

// Insert through `as` function
container.register(Int.self) { _ in 42 }.as(ExampleInstance())
```
Convenience functions can also be created by extending `Registrable`

    ```swift
    extension Registrable {
    @discardableResult
    func exampleInstance() -> Self {
        self.as(ExampleInstance())
    }
    }
    ```

If you need a combination of multiple scopes just create the scopes you need then add them to our `Composite` Instance object. `Composite` takes the first instance not nil from a list of `Instance` objects.
```swift
let composite = Composite([ExampleInstance(), Weak()])
container.register(Int.self) { _ in 42 }.as { composite }
```

### Behaviors
Behaviors allow for additional functionality in the container. They are applied to each registration as they are registered.

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

// Output: Registered Int with name: 42
try container.register(Int.self, name: "42") { _ in 42 }
```

### Nested Containers
Coming Soon...

### Assemblies
Assemblies allow for modularized code structure and can be used to assemble how ever you would like. They provide a function where registration can best be structured as well as provide a function to hook into when all registrations are complete.
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
// Output: Assembly loaded with message: Hello, Astroject!
assembler.apply(assembly: MyAssembly())

let message: String = try container.resolve(String.self)
// Output: Hello, Astroject!
print(message) 
```

### Error Handling
Astroject provides detailed error handling through the `ResolutionError`, `InstanceError` and `RegistrationError` enums.

## Sample Code
Checkout our sample code under the [playgrounds](/Playgrounds) directory.

## Looking to the Future
Listed below are features maintainers plan to bring to this library.
- Add Sample Code via Playgrounds
- Arguments - Pass in additional arguments to a factory or resolution
- Parent Containers
- Intuitive Registration - Registration is based on the initializer of an object
- Resource File Registration - Automatically register object from bundle and resource files
- DocC - Swift Documentation

## Contributing
See [documentation](CONTRIBUTING.md) for more details and guidelines.

## Credits
Astroject was inspired by 
- [Swinject](https://github.com/Swinject/Swinject).
- [SwinjectAutoRegistration](https://github.com/Swinject/SwinjectAutoregistration)
- [SwinjectPropertyLoader](https://github.com/Swinject/SwinjectPropertyLoader)

## License
Astroject is released under the MIT License. See [LICENSE](LICENSE) for details.
