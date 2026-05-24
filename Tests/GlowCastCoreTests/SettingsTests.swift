import XCTest
@testable import GlowCastCore

final class SettingsTests: XCTestCase {
    func testDefaults() {
        let s = AppSettings.default
        XCTAssertEqual(s.mode, .solid)
        XCTAssertEqual(s.colorHex, "06b6d4")
        XCTAssertEqual(s.brightness, 100)
        XCTAssertTrue(s.isOn)
        XCTAssertEqual(s.color, RGBColor(r: 6, g: 182, b: 212))
    }

    func testColorFallback() {
        var s = AppSettings.default
        s.colorHex = "garbage"
        XCTAssertEqual(s.color, .black)   // invalid hex -> black, never crashes
    }

    func testRoundTripThroughStore() {
        let defaults = UserDefaults(suiteName: "glowcast.test.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)
        var s = AppSettings.default
        s.mode = .rainbow
        s.brightness = 42
        s.presets = ["06b6d4", "4b0082"]
        store.save(s)
        XCTAssertEqual(store.load(), s)
    }

    func testLoadReturnsDefaultWhenEmpty() {
        let defaults = UserDefaults(suiteName: "glowcast.test.\(UUID().uuidString)")!
        XCTAssertEqual(SettingsStore(defaults: defaults).load(), .default)
    }
}
