import Foundation

public enum Animator {
    /// Map speed 0...100 to a period in seconds (higher speed = shorter period).
    public static func period(forSpeed speed: Int, mode: LightingMode) -> Double {
        let s = Double(max(0, min(100, speed))) / 100.0
        let (slow, fast): (Double, Double)
        switch mode {
        case .strobe: (slow, fast) = (1.5, 0.1)
        case .breathing, .pulse: (slow, fast) = (8.0, 1.0)
        case .cycle, .rainbow: (slow, fast) = (30.0, 2.0)
        case .solid: (slow, fast) = (1.0, 1.0)
        }
        return slow + (fast - slow) * s
    }

    public static func colors(mode: LightingMode, base: RGBColor, brightness: Int,
                              speed: Int, on: Bool, time: Double) -> [RGBColor] {
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
        }
    }
}
