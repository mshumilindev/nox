import Foundation
import Testing
@testable import NoxShrineCore

struct NoxShrineCoreCodableTests {
    @Test func behaviorPacketRoundTripsThroughJSON() throws {
        let packet = NoxShrineBehaviorPacket(
            faceState: .concerned,
            animation: .attentionPulse,
            sound: .softPing,
            text: "Focus appears active while work is still moving.",
            urgency: .notice,
            actions: [.dismiss, .snooze, .openFullShrine]
        )

        let decoded = try roundTrip(packet)

        #expect(decoded == packet)
    }

    @Test func surfaceDescriptorRoundTripsThroughJSON() throws {
        let descriptor = NoxShrineSurfaceDescriptor(
            surfaceId: "shrine-physical-desk",
            nodeId: "nox-i",
            displayName: "Desk Shrine",
            surfaceKind: .physical,
            surfaceForm: .physicalDisplay,
            surfaceMode: .primary,
            capabilities: [
                .displayPixelFace,
                .audioSoundEffects,
                .audioLocalSpeaker,
                .inputDismiss,
                .inputSnooze,
                .constellationMdnsDiscovery,
                .constellationSecurePairing,
            ],
            isPhysicalNearby: true,
            lastHeartbeatISO8601: "2026-05-29T10:00:00Z",
            roomHint: "Desk"
        )

        let decoded = try roundTrip(descriptor)

        #expect(decoded == descriptor)
    }

    @Test func eventRoundTripsThroughJSON() throws {
        let event = NoxShrineEvent(
            type: .miniBubbleDragged,
            timestampISO8601: "2026-05-29T10:05:00Z",
            confidence: 0.92,
            sourceCapability: .inputDrag,
            metadata: [
                "displayId": "internal",
                "reason": "userCorrection",
            ]
        )

        let decoded = try roundTrip(event)

        #expect(decoded == event)
    }

    @Test func allEnumCasesRemainCodable() throws {
        try assertCasesRoundTrip(NoxShrineSurfaceKind.allCases)
        try assertCasesRoundTrip(NoxShrineSurfaceMode.allCases)
        try assertCasesRoundTrip(NoxShrineSurfaceForm.allCases)
        try assertCasesRoundTrip(NoxShrineCapability.allCases)
        try assertCasesRoundTrip(NoxShrineFaceState.allCases)
        try assertCasesRoundTrip(NoxShrineAnimation.allCases)
        try assertCasesRoundTrip(NoxShrineSoundCue.allCases)
        try assertCasesRoundTrip(NoxShrineUrgency.allCases)
        try assertCasesRoundTrip(NoxShrineAction.allCases)
        try assertCasesRoundTrip(NoxShrineEventType.allCases)
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func assertCasesRoundTrip<T: Codable & Equatable>(_ cases: [T]) throws {
        let decoded = try roundTrip(cases)
        #expect(decoded == cases)
    }
}
