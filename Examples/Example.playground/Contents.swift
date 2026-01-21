// MARK: - Imports

/**
 Core frameworks used by the playground.

 - AstrojectCore / AstrojectSync:
   Dependency Injection framework used to register and resolve services.
 - Observation:
   Enables @Observable macro for SwiftUI-friendly state updates.
 - SwiftUI:
   UI framework used to render the message list and input controls.
 */

import AstrojectCore
import AstrojectSync
import Foundation
import Observation
import SwiftUI


// MARK: - Service Layer

/**
 A protocol describing a message transport service.

 This abstraction allows:
 - Easy mocking for tests
 - Decoupling the UI and repository from networking details
 */
protocol MessageService: Sendable {
    /// Fetches all messages from the backend.
    func fetch() async -> [Message]

    /// Sends a single message to the backend.
    func put(_ message: Message) async
}


// MARK: - Repository Layer

/**
 A generic repository abstraction.

 A repository:
 - Owns cached state
 - Exposes an `AsyncStream` for observation
 - Knows how to refresh and clear its data
 */
protocol Repository<Value>: Sendable {
    associatedtype Value

    /// A stream that emits values whenever the repository changes.
    var stream: AsyncStream<Value> { get async }

    /// Forces a refresh from the underlying data source.
    func refresh() async -> Value

    /// Clears all cached data.
    func clear() async
}

/// A concrete specialization of Repository for messages.
protocol MessageRepository: Repository<[Message]> {}


// MARK: - Model

/**
 Represents a single chat message.

 Conforms to:
 - Identifiable: required for SwiftUI Lists
 - Codable: required for network transport
 - Sendable: required for concurrency safety
 */
struct Message: Identifiable, Codable, Sendable {

    /// Indicates whether the message was sent or received.
    enum Origin: Codable {
        case recipient
        case sender
    }

    /// Explicit coding keys for clarity and future extensibility.
    enum CodingKeys: String, CodingKey {
        case origin
        case content
        case date
    }

    /// Stable identifier for SwiftUI diffing.
    let id: UUID = .init()

    var origin: Origin
    var content: String
    var date: Date
}


// MARK: - Network Service Implementation

/**
 Concrete implementation of `MessageService`.

 Responsible solely for:
 - Building requests
 - Talking to the network
 - Encoding / decoding data

 It has **no state** and no UI knowledge.
 */
struct Service: MessageService {

    let session: URLSession

    /// Base request used for all message endpoints.
    var request: URLRequest {
        let url = URL(string: "https://api.astroject.com/messages")!
        return URLRequest(url: url)
    }

    /// Fetches messages from the server.
    func fetch() async -> [Message] {
        do {
            var request = self.request
            request.httpMethod = "GET"

            let (data, _) = try await session.data(for: request)
            return try JSONDecoder().decode([Message].self, from: data)
        } catch {
            // In a real app, you'd surface errors to the UI or logging system.
            return []
        }
    }

    /// Sends a message to the server.
    func put(_ message: Message) async {
        do {
            var request = self.request
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(message)

            _ = try await session.data(for: request)
        } catch {
            // Errors intentionally ignored for playground simplicity.
        }
    }
}


// MARK: - Repository Implementation

/**
 Actor-backed message repository.

 Responsibilities:
 - Own message cache
 - Coordinate network refreshes
 - Publish updates via AsyncStream

 Using an actor guarantees thread safety.
 */
actor AppMessageRepository: MessageRepository {

    private let service: MessageService
    private var messages: [Message] = []
    private var continuation: AsyncStream<[Message]>.Continuation?

    /// Stream emitting the current message list whenever it changes.
    var stream: AsyncStream<[Message]> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.messages)
        }
    }

    init(service: MessageService) {
        self.service = service
    }

    /// Refreshes messages from the backend.
    func refresh() async -> [Message] {
        self.messages = await service.fetch()
        continuation?.yield(messages)
        return messages
    }

    /// Clears all messages.
    func clear() {
        messages = []
        continuation?.yield(messages)
    }
}


// MARK: - Dependency Injection Assemblies

/**
 Registers network-related dependencies.
 */
struct NetworkAssembly: Assembly {
    func assemble(container: any Container) throws {
        try container.register(URLSession.self) {
            URLSession.shared
        }
    }
}

/**
 Registers miscellaneous utility dependencies.
 */
struct UtilityAssembly: Assembly {
    func assemble(container: any Container) throws {
        try container.register(Bundle.self) {
            Bundle.main
        }

        try container.register(ProcessInfo.self) {
            ProcessInfo()
        }
    }
}

/**
 Registers all message-related services and repositories.
 */
struct MessageAssembly: Assembly {

    /// Declares dependencies on other assemblies.
    static var requiredAssemblies: [Assembly.Type] {
        [NetworkAssembly.self]
    }

    func assemble(container: any Container) throws {

        /// Register the message network service.
        try container.register(MessageService.self) { resolver in
            Service(
                session: try resolver.resolve(URLSession.self)
            )
        }

        /// Register the message repository as a singleton.
        try container.register((any MessageRepository).self) { resolver in
            AppMessageRepository(
                service: try resolver.resolve(MessageService.self)
            )
        }
        .asSingleton()
    }
}


// MARK: - View Model

/**
 ViewModel responsible for:
 - Exposing observable state to SwiftUI
 - Coordinating repository observation
 - Handling message sending
 */
@MainActor
@Observable
class MessageViewModel {

    let repository: any MessageRepository
    let service: MessageService

    /// Text currently being typed.
    var message: String = ""

    /// Messages rendered by the UI.
    var messages: [Message] = []

    /// Used to prevent duplicate sends.
    var task: Task<Void, Never>?

    /// Indicates whether a message is currently sending.
    var isSending: Bool { task != nil }

    nonisolated init(repository: any MessageRepository, service: MessageService) {
        self.repository = repository
        self.service = service
    }

    /// Observes the repository stream and updates UI state.
    @Sendable
    func observeMessages() async {
        for await messages in await repository.stream {
            self.messages = messages
        }
    }

    /// Sends the current message and refreshes the repository.
    func sendMessage() {
        guard task == nil else { return }

        task = Task {
            let message = Message(
                origin: .sender,
                content: self.message,
                date: .now
            )

            await service.put(message)
            await repository.refresh()

            self.message = ""
            self.task = nil
        }
    }

    /// Manually refreshes messages.
    @Sendable
    func refresh() async {
        await repository.refresh()
    }
}

/**
 Composition root for the MessageViewModel.

 This assembly demonstrates environment-specific dependency graphs:

 - In production, it depends on `MessageAssembly`
 - In tests, it depends on `TestMessageAssembly`

 This allows the ViewModel to be resolved identically in both
 environments, with only the service layer swapped.
 */
struct ViewModelAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] {
        #if TEST
        [ TestMessageAssembly.self ]
        #else
        [ MessageAssembly.self ]
        #endif
    }

    func assemble(container: any Container) throws {
        try container.register(MessageViewModel.self) { resolver in
            MessageViewModel(
                repository: try resolver.resolve((any MessageRepository).self),
                service: try resolver.resolve(MessageService.self)
            )
        }
    }
}

// MARK: - SwiftUI Views

/**
 Displays the list of messages and input controls.
 */
struct MessageList: View {

    @State var model: MessageViewModel

    /// Resolves dependencies from the DI container.
    init(container: Container) {
        let model = try! container.resolve(MessageViewModel.self)
        self._model = .init(initialValue: model)
    }

    var body: some View {
        VStack {
            List {
                ForEach(model.messages) { message in
                    Text(message.content)
                        .font(.largeTitle.bold())
                }
            }
            .refreshable(action: model.refresh)

            HStack {
                TextField("message", text: $model.message)
                    .onSubmit(model.sendMessage)

                Button(action: model.sendMessage) {
                    Image(systemName: "arrow.up")
                }
                .disabled(model.isSending)
            }
        }
        .task(model.observeMessages)
    }
}


// MARK: - Application Entry Point

/**
 Minimal SwiftUI App entry point for the playground.

 - Creates a DI container
 - Registers assemblies
 - Launches the MessageList view
 */
struct SampleApp: App {

    let container: SyncContainer

    init() {
        container = SyncContainer(createAssembler: true)

        try! container.assembler?
            .add(assembly: MessageAssembly())
            .assemble()
    }

    var body: some Scene {
        WindowGroup {
            MessageList(container: container)
        }
    }
}


// MARK: - Testing & Dependency Overrides

/**
 This section demonstrates how to test the application using
 **Swift Testing** while keeping everything in a single playground file.

 Key ideas showcased here:

 - Overriding dependencies using assemblies
 - Mocking only the service layer
 - Testing repositories in isolation
 - Testing view models without SwiftUI
 - Resolving the full object graph through DI in integration tests

 The production code above remains completely unchanged.
 */

import Testing


// MARK: - Mock Implementations

/**
 A mock implementation of `MessageService`.

 This actor replaces the real network-backed service and stores messages
 entirely in memory. Because it is an actor, it is:

 - Thread-safe
 - Sendable
 - Deterministic
 - Ideal for async tests
 */
actor MockMessageService: MessageService {

    /// In-memory message storage used by tests.
    private(set) var storedMessages: [Message] = []

    /// Returns all stored messages.
    func fetch() async -> [Message] {
        storedMessages
    }

    /// Appends a message to in-memory storage.
    func put(_ message: Message) async {
        storedMessages.append(message)
    }
}


// MARK: - Test Assembly

/**
 A test-only assembly that overrides the service layer.

 This assembly intentionally replaces **only** `MessageService`,
 allowing the following components to remain real:

 - `AppMessageRepository`
 - `MessageViewModel`

 This demonstrates how dependency injection enables precise,
 minimal mocking without polluting production code.
 */
struct TestMessageAssembly: Assembly {
    func assemble(container: any Container) throws {
        /// Override the real network service with an in-memory mock
        try container.register(MessageService.self) {
            MockMessageService()
        }
        .asSingleton()
    }
}


// MARK: - Repository Tests

/**
 Tests for `AppMessageRepository`.

 These tests validate:
 - Fetching data from the service
 - Publishing updates through `AsyncStream`

  These repository tests resolve dependencies through the DI container
  to demonstrate that repositories remain testable even when constructed
  via assemblies.
 */
@Suite("Message Repository Tests")
struct MessageRepositoryTests {

    @Test("refresh() loads messages from the service")
    func refreshLoadsMessages() async throws {
        let container = try SyncContainer(assemblies: [ViewModelAssembly()])
        let service = try await container.resolve(MessageService.self)
        let repository = try await container.resolve((any MessageRepository).self)

        let message = Message(
            origin: .sender,
            content: "Hello Repository",
            date: .now
        )

        await service.put(message)

        let result = await repository.refresh()

        #expect(result.count == 1)
        #expect(result.first?.content == "Hello Repository")
    }

    @Test("stream emits updated values after refresh")
    func streamEmitsOnRefresh() async throws {
        let container = try SyncContainer(assemblies: [ViewModelAssembly()])
        let service = try await container.resolve(MessageService.self)
        let repository = try await container.resolve((any MessageRepository).self)

        await service.put(
            Message(origin: .sender, content: "Stream Test", date: .now)
        )

        let stream = await repository.stream

        let task = Task<[Message], Never> {
            for await messages in stream {
                return messages
            }
            return []
        }

        _ = await repository.refresh()
        let messages = await task.value

        #expect(messages.count == 1)
        #expect(messages[0].content == "Stream Test")
    }
}


// MARK: - ViewModel Tests

/**
 Tests for `MessageViewModel`.

 These tests:
 - Run on the main actor
 - Avoid SwiftUI rendering
 - Validate observable state transitions
 */
@Suite("Message ViewModel Tests")
@MainActor
struct MessageViewModelTests {

    @Test("sendMessage() clears input and updates messages")
    func sendMessageUpdatesState() async throws {
        let model = try await SyncContainer(assemblies: [ViewModelAssembly()])
            .resolve(MessageViewModel.self)

        model.message = "Hello ViewModel"
        model.sendMessage()

        try? await Task.sleep(for: .milliseconds(50))

        #expect(model.message.isEmpty)
        #expect(model.messages.count == 1)
        #expect(model.messages.first?.content == "Hello ViewModel")
    }

    @Test("isSending reflects task lifecycle")
    func isSendingReflectsTaskState() async throws {
        let model = try await SyncContainer(assemblies: [ViewModelAssembly()])
            .resolve(MessageViewModel.self)

        model.message = "Sending…"
        model.sendMessage()

        #expect(model.isSending)

        try? await Task.sleep(for: .milliseconds(50))

        #expect(!model.isSending)
    }
}
