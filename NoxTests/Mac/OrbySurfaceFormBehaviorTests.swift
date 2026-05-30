import Foundation
import Testing
@testable import Nox

@Test func notchAllowsSleepAndIdleMicrobehaviors() {
  #expect(OrbySurfaceFormBehavior.allowsSleepCycle(.notch))
  #expect(OrbySurfaceFormBehavior.allowsIdleMicrobehaviors(.notch))
}

@Test func notchSuppressesLaunchGreetingAndHeavySkyLayers() {
  #expect(!OrbySurfaceFormBehavior.allowsLaunchGreeting(.notch))
  #expect(OrbySurfaceFormBehavior.allowsLaunchGreeting(.bubble))
  #expect(!OrbySurfaceFormBehavior.usesAmbientSkyMeteors(.notch))
  #expect(OrbySurfaceFormBehavior.usesAmbientSkyMeteors(.bubble))
  #expect(OrbySurfaceFormBehavior.usesSimplifiedOrbMaterial(.notch))
  #expect(!OrbySurfaceFormBehavior.usesSimplifiedOrbMaterial(.bubble))
}
