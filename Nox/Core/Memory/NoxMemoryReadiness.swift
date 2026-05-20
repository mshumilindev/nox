import Foundation

enum NoxMemoryReadiness: Equatable, Sendable {
    case observing
    case building
    case ready

    var emptyTitle: String {
        emptyTitle(for: .transient)
    }

    var emptyDetail: String {
        emptyDetail(for: .transient)
    }

    func emptyTitle(for maturity: NoxMemoryMaturity) -> String {
        switch self {
        case .observing:
            switch maturity {
            case .transient:
                return NoxHumanContextCopy.recentContextSettling
            case .emerging:
                return "Patterns are beginning to appear"
            case .stable, .durable:
                return "Recent memory"
            }
        case .building:
            switch maturity {
            case .transient, .emerging:
                return "Repeated activity is being recognized"
            case .stable, .durable:
                return "Contexts are forming"
            }
        case .ready:
            return "Recent memory"
        }
    }

    func emptyDetail(for maturity: NoxMemoryMaturity) -> String {
        switch self {
        case .observing:
            return NoxHumanContextCopy.contextsGathering
        case .building:
            switch maturity {
            case .transient:
                return "Recent context is filling in."
            case .emerging:
                return "Repeated activity may be forming across sessions."
            case .stable, .durable:
                return "Recent context is filling in."
            }
        case .ready:
            return ""
        }
    }
}
