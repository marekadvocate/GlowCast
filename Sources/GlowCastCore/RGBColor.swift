import Foundation

public struct RGBColor: Equatable, Sendable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r; self.g = g; self.b = b
    }

    public static let black = RGBColor(r: 0, g: 0, b: 0)

    public init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        self.init(r: UInt8((value >> 16) & 0xff),
                  g: UInt8((value >> 8) & 0xff),
                  b: UInt8(value & 0xff))
    }

    public var hexString: String {
        String(format: "%02x%02x%02x", r, g, b)
    }

    public func scaled(brightness: Int) -> RGBColor {
        let f = max(0, min(100, brightness))
        func s(_ v: UInt8) -> UInt8 { UInt8(Int(v) * f / 100) }
        return RGBColor(r: s(r), g: s(g), b: s(b))
    }

    /// HSV with hue/saturation/value in 0...1.
    public init(hue: Double, saturation: Double, value: Double) {
        let h = (hue.truncatingRemainder(dividingBy: 1.0) + 1.0)
            .truncatingRemainder(dividingBy: 1.0) * 6.0
        let c = value * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = value - c
        let (r1, g1, b1): (Double, Double, Double)
        switch Int(h) {
        case 0: (r1, g1, b1) = (c, x, 0)
        case 1: (r1, g1, b1) = (x, c, 0)
        case 2: (r1, g1, b1) = (0, c, x)
        case 3: (r1, g1, b1) = (0, x, c)
        case 4: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }
        func u(_ v: Double) -> UInt8 { UInt8(max(0, min(255, (v + m) * 255.0 + 0.5))) }
        self.init(r: u(r1), g: u(g1), b: u(b1))
    }
}
