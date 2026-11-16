//
//  Container+Autoregister.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import AstrojectCore

// MARK: - Without an argument

public extension Container {
    /// Registers a product by its initializer, resolving every initializer parameter from the container.
    ///
    /// Each parameter is resolved by its type, with no name. The returned registration
    /// can be configured like any other, for example with `.asSingleton()` or `afterInit`.
    ///
    /// ```swift
    /// try container.register(UserService.self, initializer: UserService.init)
    ///     .asSingleton()
    /// ```
    ///
    /// The container's `ResolutionMode` decides how dependencies are resolved: a `.sync`
    /// container resolves them synchronously, an `.async` container resolves them with `await`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name for the registration.
    ///   - isOverridable: Whether a later registration can override this one. Defaults to `true`.
    ///   - initializer: The initializer (or any function) that creates the product from its dependencies.
    /// - Returns: The registration, for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, each Dependency>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        initializer: @escaping (repeat each Dependency) throws -> Product
    ) throws -> any Registrable<Product> {
        let factory: Factory<Product, Resolver>
        switch resolutionMode {
        case .sync:
            factory = Factory(.sync { resolver in
                try initializer(repeat resolver.resolve((each Dependency).self))
            })
        case .async:
            factory = Factory(.async { resolver in
                try await initializer(repeat resolver.resolve((each Dependency).self))
            })
        }
        return try register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: factory
        )
    }

    /// Registers a product by its `async` initializer, resolving every initializer parameter from the container.
    ///
    /// Only containers whose `ResolutionMode` is `.async`, such as `AsyncContainer`, can run an
    /// `async` initializer.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name for the registration.
    ///   - isOverridable: Whether a later registration can override this one. Defaults to `true`.
    ///   - initializer: The `async` initializer that creates the product from its dependencies.
    /// - Returns: The registration, for further configuration.
    /// - Throws: `AstrojectError.invalidFactory` if the container resolves synchronously,
    ///           or `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, each Dependency>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        initializer: @escaping (repeat each Dependency) async throws -> Product
    ) throws -> any Registrable<Product> {
        guard resolutionMode == .async else {
            throw AstrojectError.invalidFactory
        }
        return try register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { resolver in
                try await initializer(repeat resolver.resolve((each Dependency).self))
            })
        )
    }
}

// MARK: - With an argument

public extension Container {
    /// Registers a product whose initializer takes one runtime argument first,
    /// resolving every other parameter from the container.
    ///
    /// ```swift
    /// // init(puzzleID: String, repository: PuzzleRepository)
    /// try container.register(
    ///     PuzzleViewModel.self,
    ///     argumentType: String.self,
    ///     initializer: PuzzleViewModel.init
    /// )
    /// let viewModel = try container.resolve(PuzzleViewModel.self, argument: "puzzle-42")
    /// ```
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the runtime argument, passed as the initializer's first parameter.
    ///   - name: An optional name for the registration.
    ///   - isOverridable: Whether a later registration can override this one. Defaults to `true`.
    ///   - initializer: The initializer that creates the product from the argument and its dependencies.
    /// - Returns: The registration, for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable, each Dependency>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        initializer: @escaping (Argument, repeat each Dependency) throws -> Product
    ) throws -> any Registrable<Product> {
        let factory: Factory<Product, (Resolver, Argument)>
        switch resolutionMode {
        case .sync:
            factory = Factory(.sync { resolver, argument in
                try initializer(argument, repeat resolver.resolve((each Dependency).self))
            })
        case .async:
            factory = Factory(.async { resolver, argument in
                try await initializer(argument, repeat resolver.resolve((each Dependency).self))
            })
        }
        return try register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: factory
        )
    }

    /// Registers a product whose `async` initializer takes one runtime argument first,
    /// resolving every other parameter from the container.
    ///
    /// Only containers whose `ResolutionMode` is `.async`, such as `AsyncContainer`, can run an
    /// `async` initializer.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the runtime argument, passed as the initializer's first parameter.
    ///   - name: An optional name for the registration.
    ///   - isOverridable: Whether a later registration can override this one. Defaults to `true`.
    ///   - initializer: The `async` initializer that creates the product from the argument and dependencies.
    /// - Returns: The registration, for further configuration.
    /// - Throws: `AstrojectError.invalidFactory` if the container resolves synchronously,
    ///           or `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable, each Dependency>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        initializer: @escaping (Argument, repeat each Dependency) async throws -> Product
    ) throws -> any Registrable<Product> {
        guard resolutionMode == .async else {
            throw AstrojectError.invalidFactory
        }
        return try register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { resolver, argument in
                try await initializer(argument, repeat resolver.resolve((each Dependency).self))
            })
        )
    }
}
