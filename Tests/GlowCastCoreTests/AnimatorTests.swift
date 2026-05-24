import XCTest
@testable import GlowCastCore

final class AnimatorTests: XCTestCase {
    let base = RGBColor(r: 200, g: 100, b: 50)

    func testOffIsBlack() {
        let c = Animator.colors(mode: .solid, base: base, brightness: 100, speed: 50, on: false, time: 0)
        XCTAssertEqual(c.count, 108)
        XCTAssertTrue(c.allSatisfy { $0 == .black })
    }

    func testSolidUniform() {
        let c = Animator.colors(mode: .solid, base: base, brightness: 100, speed: 50, on: true, time: 1.23)
        XCTAssertTrue(c.allSatisfy { $0 == base })
    }

    func testSolidBrightness() {
        let c = Animator.colors(mode: .solid, base: base, brightness: 50, speed: 50, on: true, time: 0)
        XCTAssertEqual(c[0], base.scaled(brightness: 50))
    }

    func testBreathingStartsDark() {
        // factor = (1 - cos(0))/2 = 0  -> black at t=0
        let c = Animator.colors(mode: .breathing, base: base, brightness: 100, speed: 50, on: true, time: 0)
        XCTAssertEqual(c[0], .black)
    }

    func testBreathingPeakAtHalfPeriod() {
        let period = Animator.period(forSpeed: 50, mode: .breathing)
        let c = Animator.colors(mode: .breathing, base: base, brightness: 100, speed: 50, on: true, time: period / 2)
        XCTAssertEqual(c[0], base)   // factor = (1 - cos(pi))/2 = 1
    }

    func testStrobeOnThenOff() {
        let period = Animator.period(forSpeed: 50, mode: .strobe)
        let on = Animator.colors(mode: .strobe, base: base, brightness: 100, speed: 50, on: true, time: 0)
        let off = Animator.colors(mode: .strobe, base: base, brightness: 100, speed: 50, on: true, time: period * 0.75)
        XCTAssertEqual(on[0], base)
        XCTAssertEqual(off[0], .black)
    }

    func testCycleUniformHueRotates() {
        let c0 = Animator.colors(mode: .cycle, base: base, brightness: 100, speed: 50, on: true, time: 0)
        XCTAssertTrue(c0.allSatisfy { $0 == c0[0] })          // uniform across LEDs
        XCTAssertEqual(c0[0], RGBColor(hue: 0, saturation: 1, value: 1))  // starts at red
    }

    func testRainbowSpreadsAcrossLEDs() {
        let c = Animator.colors(mode: .rainbow, base: base, brightness: 100, speed: 50, on: true, time: 0)
        XCTAssertNotEqual(c[0], c[54])   // different hues along the strip
    }
}
