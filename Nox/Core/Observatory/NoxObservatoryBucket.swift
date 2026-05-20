import Foundation

struct NoxObservatoryBucket {
    let index: Int
    let start: Date
    let end: Date
    var activeSeconds: TimeInterval = 0
    var semanticSeconds: TimeInterval = 0
    var sustainedSemanticSeconds: TimeInterval = 0
    var fragmentedSemanticSeconds: TimeInterval = 0
    var focusBlockSeconds: TimeInterval = 0
    var focusContinuitySeconds: TimeInterval = 0
    var deepWorkSeconds: TimeInterval = 0
    var deepContextSeconds: TimeInterval = 0
    var fragmentedSeconds: TimeInterval = 0
    var workSeconds: TimeInterval = 0
    var communicationSeconds: TimeInterval = 0
    var passiveSeconds: TimeInterval = 0
    var focusScoreSeconds: TimeInterval = 0
    var focusSwitches = 0
    var switchEvents = 0
    var interruptionEvents = 0
    var interruptions = 0
    var spanCount = 0
    var shortSpanCount = 0
    var appNames = Set<String>()
    var categories = Set<NoxActivityCategory>()
    var semanticStates = Set<NoxSemanticState>()
    var fusionLabels = Set<NoxFusionLabel>()
    var cadencePressure: Double = 0
    var behavioralPressure: Double = 0
    var utilityRecovery: Double = 0
    var utilityDecompression: Double = 0
}
