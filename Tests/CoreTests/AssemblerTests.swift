//
//  AssemblerTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Foundation
import Testing
@testable import Mocks
@testable import AstrojectCore

/**
 # Test Cases for `Assembler`

 ## 1. Initialization Tests

 - **Init with container only**
   - Verify `Assembler` initializes correctly with a given container.
   - Check `container` property matches the passed container.
   - Check `resolver` property returns the same container.

 - **Convenience init with assemblies array**
   - Given valid assemblies, verify it runs all lifecycle methods (`preloaded`, `assemble`, `loaded`).
   - Confirm all assemblies are processed.
   - Check container is correctly passed to assemblies.
   - Verify `run(assemblies:)` completes without error.

 - **Convenience init with single assembly**
   - Verify it internally calls the array initializer with one assembly.
   - Confirm all lifecycle methods are called on the single assembly.
   - Confirm correct container usage.

 ## 2. Apply Method Tests

 - **Apply single assembly**
   - Confirm `apply(assembly:)` calls `run(assemblies:)` with one assembly.
   - Verify lifecycle methods `preloaded`, `assemble`, and `loaded` are called.
   - Verify no changes to container or resolver references.

 - **Apply assemblies array**
   - Confirm `apply(assemblies:)` calls `run(assemblies:)` with given assemblies.
   - Verify lifecycle methods called on all assemblies.
   - Confirm order of calls (`preloaded` → `assemble` → `loaded`).

 ## 3. Run Method Tests

 - **Correct sequence of method calls**
   - Verify `preloaded()` is called before `assemble(container:)`.
   - Verify `assemble(container:)` is called before `loaded(resolver:)`.
   - Ensure all assemblies receive calls in correct order.

 - **Error propagation**
   - If `preloaded()` throws, verify `run(assemblies:)` throws same error.
   - If `assemble(container:)` throws, verify `run(assemblies:)` throws same error.
   - If `loaded(resolver:)` throws, verify `run(assemblies:)` throws same error.

 ## 4. Edge Cases

 - **Empty assemblies array**
   - Verify `run(assemblies:)` with empty array completes without error and no calls made.
   - Applying empty assemblies via convenience initializers works without error.

 - **Multiple assemblies with side effects**
   - Test multiple assemblies registering different services.
   - Verify all registrations exist in the container after assembly.

 - **Re-application**
   - Applying same assembly multiple times calls lifecycle methods each time.
   - Confirm no residual state causes failures.

 ## 5. Property Access

 - **`container` property**
   - Confirm it returns the container passed to initializer.

 - **`resolver` property**
   - Confirm it returns the container instance.
   - Confirm `resolver` methods resolve dependencies correctly post-assembly.

 ## 6. Integration Tests (optional)

 - **Full assembly lifecycle**
   - Use mock `Assembly` implementations that record method calls.
   - Verify `preloaded`, `assemble`, and `loaded` called in correct order.
   - Verify dependencies registered in `assemble` are resolvable via `resolver`.

 ## Bonus: Performance

 - Test `run(assemblies:)` completes within reasonable time for many assemblies.

 */

@Suite("Assembler Tests")
struct AssemblerTests {
    @Test("Init with Container")
    func initWithContainer() {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(container === assembler.container)
        #expect(container === assembler.resolver)
    }
    
    @Test("Init with Assemblies")
    func initWithAssemblies() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        
        let assembler = try Assembler(assemblies: [assembly1, assembly2], container: container)
        
        #expect(assembler.container === container)
        #expect(assembler.resolver === container)
        #expect(assembly1.preloadedCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.loadedCalled)
    }
    
    @Test("Init with Assembly")
    func initWithAssembly() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        
        let assembler = try Assembler(assembly: assembly, container: container)
        
        #expect(assembler.container === container)
        #expect(assembler.resolver === container)
        #expect(assembly.preloadedCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.loadedCalled)
    }
    
    @Test("Apply Single Assembly")
    func applySingleAssembly() throws {
        let assembly = MockAssembly()
        let assembler = Assembler(container: MockContainer())
        
        try assembler.apply(assembly: assembly)
        
        #expect(assembly.preloadedCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.loadedCalled)
    }
    
    @Test("Apply Multiple Assemblies")
    func applyMultipleAssemblies() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.apply(assemblies: [assembly1, assembly2])
        
        #expect(assembly1.preloadedCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.loadedCalled)
        #expect(assembly2.preloadedCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembly2.loadedCalled)
    }
    
    @Test("Runs Assembly in Correct Squence")
    func correctSequence() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        var preloadedDate: Date?
        var assembledDate: Date?
        var loadedDate: Date?
        assembly.whenPreloaded = { preloadedDate = .now }
        assembly.whenAssemble = { assembledDate = .now }
        assembly.whenLoaded = { loadedDate = .now }
        let assembler = Assembler(container: container)
        
        try assembler.run(assemblies: [assembly])
        
        #expect(preloadedDate! < assembledDate!)
        #expect(assembledDate! < loadedDate!)
    }
}
