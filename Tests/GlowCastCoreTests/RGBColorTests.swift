import XCTest
@testable import GlowCastCore

final class RGBColorTests: XCTestCase {
    func testHexParse() {
        XCTAssertEqual(RGBColor(hex: "06b6d4"), RGBColor(r: 6, g: 182, b: 212))
        XCTAssertEqual(RGBColor(hex: "#06B6D4"), RGBColor(r: 6, g: 182, b: 212))
        XCTAssertNil(RGBColor(hex: "xyz"))
        XCTAssertNil(RGBColor(hex: "12345"))
    }

    func testHexString() {
        XCTAssertEqual(RGBColor(r: 6, g: 182, b: 212).hexString, "06b6d4")
    }

    func testBrightnessScale() {
        let c = RGBColor(r: 100, g: 200, b: 50)
        XCTAssertEqual(c.scaled(brightness: 100), c)
        XCTAssertEqual(c.scaled(brightness: 0), RGBColor(r: 0, g: 0, b: 0))
        XCTAssertEqual(c.scaled(brightness: 50), RGBColor(r: 50, g: 100, b: 25))
    }

    func testHSV() {
        // hue 0.5 (cyan-ish), full sat/val -> green/blue mix, red channel 0
        let c = RGBColor(hue: 0.5, saturation: 1, value: 1)
        XCTAssertEqual(c.r, 0)
        XCTAssertEqual(c.g, 255)
        XCTAssertEqual(c.b, 255)
        // hue 0 = pure red
        XCTAssertEqual(RGBColor(hue: 0, saturation: 1, value: 1), RGBColor(r: 255, g: 0, b: 0))
    }
}
