import Foundation

/// Structured semantic memory types — scalable units for long-term reasoning.
enum NoxTypedMemoryKind: String, Codable, Sendable, CaseIterable {
    case projectArc
    case routine
    case interest
    case travelPlanning
    case creativePhase
    case researchPattern
    case behavioralRhythm
    case workPattern
    case aiWorkflow
    case longTermContext

    var displayName: String {
        switch self {
        case .projectArc: "Project Arc"
        case .routine: "Routine"
        case .interest: "Interest"
        case .travelPlanning: "Travel Planning"
        case .creativePhase: "Creative Phase"
        case .researchPattern: "Research Pattern"
        case .behavioralRhythm: "Behavioral Rhythm"
        case .workPattern: "Work Pattern"
        case .aiWorkflow: "AI Workflow"
        case .longTermContext: "Long-Term Context"
        }
    }
}
