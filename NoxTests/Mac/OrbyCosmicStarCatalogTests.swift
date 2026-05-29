import XCTest
@testable import Nox

final class OrbyCosmicStarCatalogTests: XCTestCase {
  func testSharedStarCount() {
    XCTAssertEqual(OrbyCosmicStarCatalog.shared.count, OrbyCosmicMaterialConfig.default.starCount)
  }

  func testDeterministicLayout() {
    let a = OrbyCosmicStarCatalog.make(count: 24, seed: 99)
    let b = OrbyCosmicStarCatalog.make(count: 24, seed: 99)
    XCTAssertEqual(a.map(\.nx), b.map(\.nx))
    XCTAssertEqual(a.map(\.color), b.map(\.color))
  }

  func testFaceSafeZoneDimsCenter() {
    let center = OrbyCosmicStarCatalog.faceSafeDimming(
      nx: 0.5,
      ny: 0.46,
      config: OrbyCosmicMaterialConfig(faceSafeZoneDimming: 0.55)
    )
    XCTAssertLessThan(center, 0.75)
    let edge = OrbyCosmicStarCatalog.faceSafeDimming(
      nx: 0.12,
      ny: 0.12,
      config: .default
    )
    XCTAssertEqual(edge, 1, accuracy: 0.001)
  }
}
