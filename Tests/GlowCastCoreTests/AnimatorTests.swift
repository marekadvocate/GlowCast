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

    // MARK: - New mode tests

    func testWaveNonUniform() {
        let c = Animator.colors(mode: .wave, base: base, brightness: 100, speed: 50, on: true, time: 1.0)
        XCTAssertNotEqual(c.first, c[54], "Wave should produce non-uniform brightness across LEDs")
    }

    func testFireWarmColors() {
        let c = Animator.colors(mode: .fire, base: base, brightness: 100, speed: 50, on: true, time: 1.0)
        XCTAssertEqual(c.count, 108)
        let avgR = Double(c.map { Int($0.r) }.reduce(0, +)) / Double(c.count)
        let avgG = Double(c.map { Int($0.g) }.reduce(0, +)) / Double(c.count)
        let avgB = Double(c.map { Int($0.b) }.reduce(0, +)) / Double(c.count)
        XCTAssertGreaterThanOrEqual(avgR, avgG, "Fire: average R should be >= average G")
        XCTAssertGreaterThanOrEqual(avgG, avgB, "Fire: average G should be >= average B")
    }

    func testPoliceHasBothRedAndBlue() {
        let c = Animator.colors(mode: .police, base: base, brightness: 100, speed: 50, on: true, time: 0)
        XCTAssertEqual(c.count, 108)
        // At least one LED is "pure-ish" red: r > 200, g < 30, b < 30
        let hasRed = c.contains { $0.r > 200 && $0.g < 30 && $0.b < 30 }
        // At least one LED is "pure-ish" blue: b > 200, r < 30, g < 30
        let hasBlue = c.contains { $0.b > 200 && $0.r < 30 && $0.g < 30 }
        XCTAssertTrue(hasRed, "Police should have at least one red LED")
        XCTAssertTrue(hasBlue, "Police should have at least one blue LED")
    }

    func testPartyUniformAcrossLEDs() {
        let c = Animator.colors(mode: .party, base: base, brightness: 100, speed: 50, on: true, time: 1.0)
        XCTAssertTrue(c.allSatisfy { $0 == c[0] }, "Party mode should be uniform across all LEDs at a fixed time")
    }

    func testPartyChangesOverTime() {
        let period = Animator.period(forSpeed: 50, mode: .party)
        let c0 = Animator.colors(mode: .party, base: base, brightness: 100, speed: 50, on: true, time: 0)
        let c1 = Animator.colors(mode: .party, base: base, brightness: 100, speed: 50, on: true, time: 5 * period)
        XCTAssertNotEqual(c0[0], c1[0], "Party color at time=0 should differ from time=5*period")
    }

    func testReactiveAtAudioLevelZeroIsBlack() {
        let c = Animator.colors(mode: .reactive, base: base, brightness: 100, speed: 50, on: true, audioLevel: 0, time: 0)
        XCTAssertTrue(c.allSatisfy { $0 == .black }, "Reactive at audioLevel=0 should be all black")
    }

    func testReactiveAtAudioLevelOneIsFullBase() {
        let c = Animator.colors(mode: .reactive, base: base, brightness: 100, speed: 50, on: true, audioLevel: 1, time: 0)
        XCTAssertTrue(c.allSatisfy { $0 == base }, "Reactive at audioLevel=1, brightness=100 should equal base color")
    }

    func testVUAtLevelOneIsRedDominant() {
        let c = Animator.colors(mode: .vu, base: base, brightness: 100, speed: 50, on: true, audioLevel: 1, time: 0)
        XCTAssertEqual(c.count, 108)
        let led = c[0]
        XCTAssertGreaterThan(Int(led.r), Int(led.g), "VU at audioLevel=1 should have r > g (red dominant)")
        XCTAssertGreaterThan(Int(led.r), Int(led.b), "VU at audioLevel=1 should have r > b (red dominant)")
    }

    func testVUAtLevelZeroIsGreenDominant() {
        let c = Animator.colors(mode: .vu, base: base, brightness: 100, speed: 50, on: true, audioLevel: 0, time: 0)
        XCTAssertEqual(c.count, 108)
        let led = c[0]
        XCTAssertGreaterThan(Int(led.g), Int(led.r), "VU at audioLevel=0 should have g > r (green dominant)")
        XCTAssertGreaterThan(Int(led.g), Int(led.b), "VU at audioLevel=0 should have g > b (green dominant)")
    }
}
