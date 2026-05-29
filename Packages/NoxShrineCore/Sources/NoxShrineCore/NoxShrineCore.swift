import Foundation

public enum NoxShrineSurfaceKind: String, Codable, CaseIterable, Sendable {
    case software
    case physical
}

public enum NoxShrineSurfaceMode: String, Codable, CaseIterable, Sendable {
    case primary
    case mirror
    case passive
    case disabled
}

public enum NoxShrineSurfaceForm: String, Codable, CaseIterable, Sendable {
    case notch
    case floatingBubble
    case fullInterface
    case physicalDisplay
    case passiveMirror
}

public enum NoxShrineCapability: String, Codable, CaseIterable, Sendable {
    case displayPixelFace = "display.pixelFace"
    case displayCards = "display.cards"
    case audioSoundEffects = "audio.soundEffects"
    case audioLocalSpeaker = "audio.localSpeaker"
    case audioHomepodRelayOptional = "audio.homepodRelay.optional"
    case inputDismiss = "input.dismiss"
    case inputSnooze = "input.snooze"
    case inputConfirm = "input.confirm"
    case inputTouch = "input.touch"
    case inputButton = "input.button"
    case inputDrag = "input.drag"
    case expressionLedHalo = "expression.ledHalo"
    case presenceMmwave = "presence.mmwave"
    case presenceBle = "presence.ble"
    case visionPersonDetection = "vision.personDetection"
    case visionCatDetection = "vision.catDetection"
    case identityGuestRecognition = "identity.guestRecognition"
    case environmentTemperature = "environment.temperature"
    case environmentHumidity = "environment.humidity"
    case environmentLight = "environment.light"
    case environmentNoise = "environment.noise"
    case environmentCo2 = "environment.co2"
    case environmentPm25 = "environment.pm25"
    case constellationMdnsDiscovery = "constellation.mdnsDiscovery"
    case constellationSecurePairing = "constellation.securePairing"
    case surfaceNotch = "surface.notch"
    case surfaceFloatingBubble = "surface.floatingBubble"
    case surfaceFullInterface = "surface.fullInterface"
    case surfaceAutoSummon = "surface.autoSummon"
    case surfaceCollisionAvoidance = "surface.collisionAvoidance"
    case surfaceVideoAwareHiding = "surface.videoAwareHiding"
    case aiBehaviorGenerationOptional = "ai.behaviorGeneration.optional"
}

public enum NoxShrineFaceState: String, Codable, CaseIterable, Sendable {
    case idle
    case focused
    case sleepy
    case concerned
    case alarmed
    case pleased
    case annoyed
    case disconnected
    case passive
    case muted
    case physicalShrineActive
}

public enum NoxShrineAnimation: String, Codable, CaseIterable, Sendable {
    case none
    case blink
    case lookAround
    case wake
    case sleepBreath
    case sideEye
    case glitch
    case softPulse
    case attentionPulse
    case dismissShrink
    case dragSquish
}

public enum NoxShrineSoundCue: String, Codable, CaseIterable, Sendable {
    case none
    case softPing
    case confirm
    case dismiss
    case alarmGentle
    case alarmStrong
    case guestHello
    case attention
    case physicalShrineConnected
    case physicalShrineLost
}

public enum NoxShrineUrgency: String, Codable, CaseIterable, Sendable {
    case ambient
    case notice
    case interrupt
}

public enum NoxShrineAction: String, Codable, CaseIterable, Sendable {
    case dismiss
    case snooze
    case confirm
    case switchFocus
    case openNox
    case openFullShrine
    case muteShrine
    case hideShrine
}

public struct NoxShrineBehaviorPacket: Codable, Equatable, Sendable {
    public var faceState: NoxShrineFaceState
    public var animation: NoxShrineAnimation
    public var sound: NoxShrineSoundCue
    public var text: String?
    public var urgency: NoxShrineUrgency
    public var actions: [NoxShrineAction]

    public init(
        faceState: NoxShrineFaceState,
        animation: NoxShrineAnimation,
        sound: NoxShrineSoundCue,
        text: String? = nil,
        urgency: NoxShrineUrgency,
        actions: [NoxShrineAction] = []
    ) {
        self.faceState = faceState
        self.animation = animation
        self.sound = sound
        self.text = text
        self.urgency = urgency
        self.actions = actions
    }
}

public struct NoxShrineSurfaceDescriptor: Codable, Equatable, Sendable {
    public var surfaceId: String
    public var nodeId: String
    public var displayName: String
    public var surfaceKind: NoxShrineSurfaceKind
    public var surfaceForm: NoxShrineSurfaceForm
    public var surfaceMode: NoxShrineSurfaceMode
    public var capabilities: [NoxShrineCapability]
    public var isPhysicalNearby: Bool
    public var lastHeartbeatISO8601: String?
    public var roomHint: String?

    public init(
        surfaceId: String,
        nodeId: String,
        displayName: String,
        surfaceKind: NoxShrineSurfaceKind,
        surfaceForm: NoxShrineSurfaceForm,
        surfaceMode: NoxShrineSurfaceMode,
        capabilities: [NoxShrineCapability],
        isPhysicalNearby: Bool = false,
        lastHeartbeatISO8601: String? = nil,
        roomHint: String? = nil
    ) {
        self.surfaceId = surfaceId
        self.nodeId = nodeId
        self.displayName = displayName
        self.surfaceKind = surfaceKind
        self.surfaceForm = surfaceForm
        self.surfaceMode = surfaceMode
        self.capabilities = capabilities
        self.isPhysicalNearby = isPhysicalNearby
        self.lastHeartbeatISO8601 = lastHeartbeatISO8601
        self.roomHint = roomHint
    }
}

public enum NoxShrineEventType: String, Codable, CaseIterable, Sendable {
    case dismissed
    case snoozed
    case confirmed
    case openedFullInterface
    case closedFullInterface
    case miniBubbleDragged
    case notchExpanded
    case notchCollapsed
    case miniBubblePinned
    case miniBubbleUnpinned
    case autoSummoned
    case autoHidden
    case movedToSafeZone
    case surfaceFormAutoChanged
    case videoDetected
    case fullscreenDetected
    case presenceDetected
    case presenceLost
    case personDetected
    case catDetected
    case knownGuestLikelyPresent
    case unknownPersonDetected
    case sensorUnavailable
    case soundPlayed
    case faceStateChanged
}

public struct NoxShrineEvent: Codable, Equatable, Sendable {
    public var type: NoxShrineEventType
    public var timestampISO8601: String
    public var confidence: Double?
    public var sourceCapability: NoxShrineCapability?
    public var metadata: [String: String]

    public init(
        type: NoxShrineEventType,
        timestampISO8601: String,
        confidence: Double? = nil,
        sourceCapability: NoxShrineCapability? = nil,
        metadata: [String: String] = [:]
    ) {
        self.type = type
        self.timestampISO8601 = timestampISO8601
        self.confidence = confidence
        self.sourceCapability = sourceCapability
        self.metadata = metadata
    }
}
