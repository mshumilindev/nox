import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public struct NoxObservatoryBucket {
    public let index: Int
    public let start: Date
    public let end: Date
    public var activeSeconds: TimeInterval = 0
    public var semanticSeconds: TimeInterval = 0
    public var sustainedSemanticSeconds: TimeInterval = 0
    public var fragmentedSemanticSeconds: TimeInterval = 0
    public var focusBlockSeconds: TimeInterval = 0
    public var focusContinuitySeconds: TimeInterval = 0
    public var deepWorkSeconds: TimeInterval = 0
    public var deepContextSeconds: TimeInterval = 0
    public var fragmentedSeconds: TimeInterval = 0
    public var workSeconds: TimeInterval = 0
    public var communicationSeconds: TimeInterval = 0
    public var passiveSeconds: TimeInterval = 0
    public var focusScoreSeconds: TimeInterval = 0
    public var focusSwitches = 0
    public var switchEvents = 0
    public var interruptionEvents = 0
    public var interruptions = 0
    public var spanCount = 0
    public var shortSpanCount = 0
    public var appNames = Set<String>()
    public var categories = Set<NoxActivityCategory>()
    public var semanticStates = Set<NoxSemanticState>()
    public var fusionLabels = Set<NoxFusionLabel>()
    public var cadencePressure: Double = 0
    public var behavioralPressure: Double = 0
    public var utilityRecovery: Double = 0
    public var utilityDecompression: Double = 0

    public init(index: Int, start: Date, end: Date) {
        self.index = index
        self.start = start
        self.end = end
    }
}
