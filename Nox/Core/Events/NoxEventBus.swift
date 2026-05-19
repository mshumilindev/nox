import Foundation

@MainActor
final class NoxEventBus {
    typealias Handler = (NoxEvent) -> Void

    private var handlers: [UUID: Handler] = [:]

    func subscribe(_ handler: @escaping Handler) -> UUID {
        let id = UUID()
        handlers[id] = handler
        return id
    }

    func unsubscribe(_ id: UUID) {
        handlers.removeValue(forKey: id)
    }

    func publish(_ event: NoxEvent) {
        for handler in handlers.values {
            handler(event)
        }
    }
}
