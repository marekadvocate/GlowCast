import Foundation

public enum Animator {
    /// Map speed 0...100 to a period in seconds (higher speed = shorter period).
    public static func period(forSpeed speed: Int, mode: LightingMode) -> Double {
        let s = Double(max(0, min(100, speed))) / 100.0
        let (slow, fast): (Double, Double)
        switch mode {
        case .strobe, .police: (slow, fast) = (1.5, 0.1)
        case .breathing, .pulse: (slow, fast) = (8.0, 1.0)
        case .cycle, .rainbow, .wave: (slow, fast) = (30.0, 2.0)
        case .solid: (slow, fast) = (1.0, 1.0)
        case .fire: (slow, fast) = (0.5, 0.1)
        case .party: (slow, fast) = (8.0, 1.0)
        }
        return slow + (fast - slow) * s
    }

    public static func colors(mode: LightingMode, base: RGBColor, brightness: Int,
                              speed: Int, on: Bool,
                              time: Double) -> [RGBColor] {
        let n = QS2SProtocol.ledCount
        guard on else { return Array(repeating: .black, count: n) }
        let period = period(forSpeed: speed, mode: mode)

        switch mode {
        case .solid:
            return Array(repeating: base.scaled(brightness: brightness), count: n)

        case .breathing:
            let factor = (1 - cos(2 * .pi * time / period)) / 2
            let eff = Int(Double(brightness) * factor)
            return Array(repeating: base.scaled(brightness: eff), count: n)

        case .pulse:
            // sharper than breathing: square the curve
            let raw = (1 - cos(2 * .pi * time / period)) / 2
            let eff = Int(Double(brightness) * raw * raw)
            return Array(repeating: base.scaled(brightness: eff), count: n)

        case .strobe:
            let phase = (time / period).truncatingRemainder(dividingBy: 1.0)
            let color = phase < 0.5 ? base.scaled(brightness: brightness) : .black
            return Array(repeating: color, count: n)

        case .cycle:
            let hue = (time / period).truncatingRemainder(dividingBy: 1.0)
            let v = Double(brightness) / 100.0
            return Array(repeating: RGBColor(hue: hue, saturation: 1, value: v), count: n)

        case .rainbow:
            let v = Double(brightness) / 100.0
            let shift = time / period
            return (0..<n).map { i in
                let hue = Double(i) / Double(n) + shift
                return RGBColor(hue: hue, saturation: 1, value: v)
            }

        case .wave:
            return (0..<n).map { i in
                let phase = Double(i) / Double(n) - time / period
                let factor = (1 + cos(2 * .pi * phase)) / 2
                return base.scaled(brightness: Int(Double(brightness) * factor))
            }

        case .fire:
            return (0..<n).map { i in
                let tick = Int(time * 10.0 * max(1.0, Double(speed)) / 50.0)
                // Two independent hashes for flicker value and hue offset
                let h1 = murmur(i &* 2654435761 &+ tick)
                let h2 = murmur(i &* 2246822519 &+ tick &+ 1)
                let f  = Double(h1 & 0xFFFF) / 65535.0   // 0...1
                let f2 = Double(h2 & 0xFFFF) / 65535.0   // 0...1
                let hue = 0.12 * f2                        // red → orange → yellow
                let value = (0.5 + 0.5 * f) * Double(brightness) / 100.0
                return RGBColor(hue: hue, saturation: 1.0, value: value)
            }

        case .police:
            let firstHalfRed = (Int(time / period) % 2 == 0)
            let red  = RGBColor(r: 255, g: 0, b: 0).scaled(brightness: brightness)
            let blue = RGBColor(r: 0, g: 0, b: 255).scaled(brightness: brightness)
            return (0..<n).map { i in
                if i < 54 {
                    return firstHalfRed ? red : blue
                } else {
                    return firstHalfRed ? blue : red
                }
            }

        case .party:
            let step = Int(time / period)
            let hue = (Double(step) * 0.61803398875).truncatingRemainder(dividingBy: 1.0)
            let v = Double(brightness) / 100.0
            let color = RGBColor(hue: hue, saturation: 1, value: v)
            return Array(repeating: color, count: n)
        }
    }

    // MARK: - Private helpers

    /// Fast deterministic integer hash (Murmur3-inspired finalizer).
    private static func murmur(_ input: Int) -> UInt32 {
        var x = UInt32(bitPattern: Int32(truncatingIfNeeded: input))
        x ^= x >> 16
        x &*= 0x85ebca6b
        x ^= x >> 13
        x &*= 0xc2b2ae35
        x ^= x >> 16
        return x
    }
}
