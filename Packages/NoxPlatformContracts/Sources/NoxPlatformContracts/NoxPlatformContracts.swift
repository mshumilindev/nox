import Foundation

// MARK: - Activity & context

/// Streams desktop activity observations. macOS implements via `NoxActivityObserver`.
public protocol NoxActivityObserving: Sendable {
    associatedtype Snapshot: Sendable
    associatedtype Event: Sendable
    func activitySnapshots() -> AsyncStream<Snapshot>
    func events() -> AsyncStream<Event>
}

/// Active application and window/document context.
public protocol NoxWindowContextReading: Sendable {
    associatedtype Context: Sendable
    func currentContext() async -> Context?
}

// MARK: - Permissions & capabilities

/// Abstract permission and capability state for the current platform.
public protocol NoxPermissionProviding: Sendable {
    associatedtype CapabilityState: Sendable
    func currentCapabilities() async -> CapabilityState
    func refreshPermissions() async
}

// MARK: - Calendar

public protocol NoxCalendarContextProviding: Sendable {
    associatedtype AccessState: Sendable
    associatedtype DayProfile: Sendable
    func calendarAccessState() async -> AccessState
    func dayProfile(for date: Date) async -> DayProfile?
}

// MARK: - Notifications

public protocol NoxNotificationDelivering: Sendable {
    associatedtype Candidate: Sendable
    func requestAuthorizationIfNeeded() async
    func deliver(_ candidate: Candidate) async
}

// MARK: - System state & actions

public protocol NoxSystemStateProviding: Sendable {
    associatedtype Snapshot: Sendable
    func currentSnapshot() async -> Snapshot
}

public protocol NoxSystemActionExecuting: Sendable {
    associatedtype Candidate: Sendable
    associatedtype Outcome: Sendable
    func perform(_ candidate: Candidate) async -> Outcome
}

public protocol NoxCaffeinateControlling: Sendable {
    associatedtype Token: Sendable
    func startDisplaySleepProtection() throws -> Token
    func stop(_ token: Token)
}

// MARK: - Presence mesh

public protocol NoxPresenceDiscoveryProviding: Sendable {
    associatedtype Node: Sendable
    var discoveredNodes: AsyncStream<[Node]> { get }
    func setDiscoveryActive(_ active: Bool)
}

public protocol NoxPresenceTransportProviding: Sendable {
    associatedtype Message: Sendable
    func send(_ message: Message, to peer: String) async throws
    var incomingMessages: AsyncStream<Message> { get }
}

public protocol NoxIdentityProviding: Sendable {
    associatedtype Identity: Sendable
    func loadOrCreateIdentity() async throws -> Identity
}

public protocol NoxKeychainProviding: Sendable {
    func save(key: String, data: Data) throws
    func load(key: String) throws -> Data?
    func delete(key: String) throws
}

// MARK: - Persistence & media

public protocol NoxPersistencePathProviding: Sendable {
    var databaseURL: URL { get }
    var meshDataDirectory: URL { get }
    var meshIdentityDirectory: URL { get }
}

public protocol NoxImageDecoding: Sendable {
    func decodePNG(data: Data) throws -> Any?
}

public protocol NoxArtworkCaching: Sendable {
    func cachedImage(for key: String) -> Data?
    func store(_ data: Data, for key: String) throws
}
