import Foundation

@MainActor
public final class NoxEventBus {
    public typealias Handler = (NoxEvent) -> Void

    private var handlers: [UUID: Handler] = [:]

    public init() {}

    public func subscribe(_ handler: @escaping Handler) -> UUID {
        let id = UUID()
        handlers[id] = handler
        return id
    }

    public func unsubscribe(_ id: UUID) {
        handlers.removeValue(forKey: id)
    }

    public func publish(_ event: NoxEvent) {
        for handler in handlers.values {
            handler(event)
        }
    }
}
