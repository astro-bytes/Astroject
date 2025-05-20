Feature: Instance Types
This document outlines the requirements for the different instance management types used in the AstrojectCore dependency injection container. These instance types define how objects are created and managed within the container.

1. Transient

Description:

A transient instance creates a new instance of the registered type every time it is resolved. Each request for an instance results in a unique object.

Requirements:

Creation: A new instance of the registered type must be created on each resolution.

Storage: The transient instance should not store any created instances.

Lifecycle: The lifecycle of a transient instance is entirely managed by the caller. The container does not manage its deallocation.

Implementation:

The Transient class must implement the Instance protocol.

The get() method should always return nil or create and return a new instance.

The set(_ product:) method should have no effect.

The release() method should have no effect.

2. Singleton

Description:

A singleton instance creates and stores a single instance of the registered type. This instance is then shared across all resolutions within the container's scope.

Requirements:

Creation: Only one instance of the registered type should be created during the container's lifetime (or until explicitly released).

Storage: The singleton instance must store the created instance.

Lifecycle: The container manages the lifecycle of the singleton instance. However, in the current implementation, the singleton instance is never released.

Implementation:

The Singleton class must implement the Instance protocol.

The get() method should return the stored instance, or nil if it hasn't been created yet.

The set(_ product:) method should store the instance, but only if it hasn't been set before.

The release() method should have no effect in the current implementation.

3. Weak

Description:

A weak instance holds a weak reference to the resolved object. This allows the object to be deallocated when there are no other strong references to it.

Requirements:

Creation: The weak instance receives an instance created by the container.

Storage: The weak instance must store a weak reference to the created instance.

Lifecycle: The weak instance does not prevent the deallocation of the referenced object. If the object is deallocated elsewhere, the weak reference becomes nil.

Applicability: Can only be used with class types (reference types), not structs or enums (value types).

Implementation:

The Weak class must implement the Instance protocol.

The get() method should return the weakly referenced instance, or nil if it has been deallocated.

The set(_ product:) method should store a weak reference to the provided instance, but only if it hasn't been set before.

The release() method should set the weak reference to nil.



Feature: Graph-Specific Object Resolution

Goal: Improve object resolution performance by optimizing the creation and management of objects within a dependency graph.

Detailed Description:

Currently, AstrojectCore uses transitive resolution as the default behavior, creating a new instance of each dependency every time it's resolved. This feature introduces "graph-specific" resolution as the new default.

New Default Behavior: Graph-Specific Resolution

Definition of a Dependency Graph: A dependency graph is defined as the complete set of objects that must be instantiated, starting from the initial object requested via container.resolve(MyObject.self) and including all of its transitive dependencies, until MyObject is fully constructed.

Resolution within a Graph:

When an object is resolved within a dependency graph, AstrojectCore will:

Check if an instance of that object is already being constructed as part of the same graph.

If an instance is being constructed, AstrojectCore will reuse that instance.

If an instance is not being constructed, AstrojectCore will create a new instance.

Lifecycle Management:

Once the root object of the dependency graph (e.g., MyObject in container.resolve(MyObject.self)) is fully constructed:

All objects created during the resolution of that graph are considered "complete."

AstrojectCore will release/deallocate the graph-specific instances.

ARC should handle the deallocation of these instances.

Interaction with Existing Behaviors:

The existing instance behaviors (singleton, weak, and transient) should override the new graph-specific behavior.  For example:

If an object is registered as a singleton, only one instance of that object will ever be created, regardless of graph-specific resolution.

If an object is registered as weak, it will behave as a weak reference, even within a graph.

If an object is registered as transient, a new instance will be created each time, even within the same graph.

Circular Dependencies:

The impact of graph-specific resolution on circular dependencies needs careful consideration. The intended behavior is to not negatively impact existing circular dependency resolution.

Instance Protocol:

The Instance protocol provides further specifics on object lifecycle. The solution might involve modifying this protocol.  (See "Further Details" below)

Further Details:

The Instance protocol will be provided for more information.

Open Questions:

The exact modifications to the Instance protocol need to be determined.

The impact of graph-specific resolution on circular dependencies needs to be evaluated.

Testing strategies for graph-specific resolution, especially with nested dependencies and complex object graphs, need to be defined.

Feature: Argument-Specific Instance Management
Goal: Enhance the dependency injection container to manage object instances based on the arguments used during resolution, providing more flexible instance scoping.

Detailed Description:

Currently, the container manages instances primarily based on the registered type and instance management strategy (singleton, transient, weak). This feature introduces a new dimension to instance management, where the arguments provided during resolution are also considered.

Specific Requirements:

Argument Differentiation:

When resolving an object registered with an argument, the container must:

Check if an instance for the given argument value already exists for that object type.

If an instance exists for the argument value, return that instance.

If an instance does not exist for the argument value, create a new instance using the provided argument.

Argument-Specific Scoping:

Each unique argument value used to resolve a dependency should be treated as a separate scope for instance management.

Multiple resolutions of the same type with the same argument should return the same instance.

Resolutions of the same type with different arguments should return different instances.

Interaction with Singleton:

When an object is registered as a singleton, the argument-specific scoping should still apply.

This means that a singleton instance is created per unique argument value.

By default, these singleton instances (for each unique argument) should persist for the lifetime of the container.

Interaction with Weak:

When an object is registered as a weak instance, the argument-specific scoping should also apply.

However, unlike regular singletons, these weak singleton instances can be deallocated when there are no other strong references to them, even if the container is still alive.

The container should not prevent the deallocation of these weakly referenced instances.

Implementation Details

The RegistrationWithArgument class will be modified to store and retrieve instances based on the argument.

The Instance protocol may need to be extended or modified to support this new behavior.

The container will need to maintain a storage mechanism to track instances per argument value.

Example Scenario:

class MyObject {
    let arg: Int
    init(arg: Int) { self.arg = arg }
}

// ...

let container = Container()

// Register MyObject with an argument
try container.register(MyObject.self, argument: Int.self) { _, arg in
    MyObject(arg: arg)
}

let instance1 = try container.resolve(MyObject.self, argument: 1) // Creates new instance (arg: 1)
let instance2 = try container.resolve(MyObject.self, argument: 2) // Creates new instance (arg: 2)
let instance3 = try container.resolve(MyObject.self, argument: 1) // Returns instance1 (arg: 1)

#expect(instance1 !== instance2)
#expect(instance1 === instance3)

Considerations:

Memory Management: Careful attention must be paid to memory management to avoid leaks, especially with argument-specific singletons. Weak references should be used appropriately.

Performance: The storage and retrieval of instances based on arguments should be efficient.

Thread Safety: The implementation must be thread-safe to handle concurrent resolutions with different arguments.

Interaction with Graph-Specific Resolution: The interaction between this feature and graph-specific resolution needs to be carefully designed to ensure they work together correctly and don't introduce unexpected behavior.

Feature: Registration
This document outlines the requirements for the registration mechanism in the AstrojectCore dependency injection container. Registration is the process of associating a type with a factory that can create instances of that type.

1. Registrable Protocol

Description:

The Registrable protocol defines the interface for objects that can be registered with the container. It provides a way to specify the instance management strategy and post-initialization actions.

Requirements:

Product Type: The protocol must define an associated type Product representing the type of object being registered.

Action Type: The protocol must define an associated type Action representing the type of action to be performed after a product is resolved.

as(_ instance:) Method:

This method should set the instance management strategy for the registration.

It should accept an Instance<Product> object.

It should be marked as @discardableResult to allow chaining.

afterInit(perform:) Method:

This method should add a post-initialization action to the registration.

It should accept a closure of type Action.

It should be marked as @discardableResult to allow chaining.

Convenience Methods:

The protocol should provide convenience methods for common instance management strategies:

asSingleton(): Should set the instance to a Singleton instance.

asWeak(): Should set the instance to a Weak instance.  Should only be available when Product is a class.

asTransient(): Should set the instance to a Transient instance.

2. Registration Class

Description:

The Registration class is a concrete implementation of the Registrable protocol for dependencies that do not require an argument for resolution.

Requirements:

Factory:

The class must store a factory property of type Factory<Product, Resolver>.

The factory is responsible for creating instances of the registered type.

Instance:

The class must store an instance property of type any Instance<Product>.

This property represents the instance management strategy for the registration.

Actions:

The class must store an array of Action closures to be executed after instance creation.

isOverridable:

The class must store a boolean value indicating whether the registration can be overridden.

Initialization:

The class should provide initializers to create a registration with a factory or a factory closure.

The initializers should set the factory, instance, and isOverridable properties.

resolve(_ container:) Method:

This method should resolve the product instance.

It should retrieve the instance from the instance object, or create it using the factory if it doesn't exist.

It should execute the stored actions after instance creation.

It should handle errors from the factory and actions, wrapping them in an AstrojectError.

as(_ instance:) Method:

This method should update the instance property.

It should return self to allow chaining.

afterInit(perform:) Method:

This method should append the provided action to the actions array.

It should return self to allow chaining.

Equatable Conformance:

The class should conform to Equatable when the Product type conforms to Equatable.

Requirements: Resolution Feature
This document outlines the requirements for the resolution feature in the AstrojectCore dependency injection container. Resolution is the process of retrieving an instance of a registered type from the container.

Core Requirements

resolve(_ container:) Method:

The Container class must provide a method to resolve dependencies.

This method should accept the Container itself as a parameter (for nested dependency resolution).

This method should return an instance of the requested type (Product).

This method should be asynchronous.

resolve(_ container:argument:) Method:

The Container class must provide a method to resolve dependencies that require an argument.

This method should accept the Container itself as a parameter.

This method should accept an argument of the specified type.

This method should return an instance of the requested type (Product).

This method should be asynchronous.

Type Resolution:

The container should be able to resolve dependencies based on their type.

When a type is resolved, the container should:

Find the appropriate Registration or RegistrationWithArgument for the requested type.

Use the stored Instance object to manage the lifecycle of the resolved instance (e.g., singleton, transient).

Use the stored Factory to create a new instance if necessary.

Execute any post-initialization actions associated with the registration.

Named Resolution:

The container should support resolving dependencies by name, in addition to resolving by type.

When a dependency is resolved by name, the container should:

Find the Registration or RegistrationWithArgument with the matching type and name.

Resolve the instance as described above.

Argument Resolution:

The container should support resolving dependencies by argument.

When a dependency is resolved with an argument, the container should:

Find the RegistrationWithArgument with the matching type.

Pass the provided argument to the Factory when creating the instance.

Store and retrieve instances based on the argument provided.

Error Handling:

The resolution process should handle potential errors:

If no registration is found for the requested type (or type and name), the resolve method should throw an AstrojectError.noRegistrationFound error.

If the factory or a post-initialization action throws an error, the resolve method should throw an AstrojectError.underlyingError, wrapping the original error.

The resolution process should detect and throw a AstrojectError.circularDependencyDetected error when a circular dependency is encountered.

Circular Dependency Detection:

The container must implement circular dependency detection.

If a circular dependency is detected during resolution, the resolve method should throw an appropriate error.

Thread Safety:

The resolution process should be thread-safe.  Multiple threads should be able to resolve dependencies concurrently without causing data corruption or unexpected behavior.

Interaction with Other Components

Registration: The resolution process relies on the registration mechanism to find the appropriate Registration or RegistrationWithArgument for a given type and name.

Instance Management: The resolution process uses the Instance objects (Singleton, Transient, Weak, etc.) associated with a registration to manage the lifecycle of the resolved instance.

Factory: The resolution process uses the Factory associated with a registration to create new instances when necessary.

Behaviors: The resolution process should notify registered Behaviors of the resolution.

This document describes the requirements for the resolution feature in AstrojectCore. Let me know if you have any questions.

