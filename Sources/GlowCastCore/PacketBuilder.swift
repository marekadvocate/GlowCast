import Foundation

public enum PacketBuilder {
    public static func headerPacket() -> [UInt8] {
        var p = [UInt8](repeating: 0, count: QS2SProtocol.packetSize)
        p[0] = QS2SProtocol.displayCode
        p[1] = QS2SProtocol.headerCmd
        p[2] = UInt8(QS2SProtocol.dataPacketCount)
        return p
    }

    /// 6 data packets carrying up to 108 LED colors (padded/truncated to 108).
    public static func dataPackets(colors: [RGBColor]) -> [[UInt8]] {
        var leds = colors
        if leds.count < QS2SProtocol.ledCount {
            leds += Array(repeating: .black, count: QS2SProtocol.ledCount - leds.count)
        } else if leds.count > QS2SProtocol.ledCount {
            leds = Array(leds.prefix(QS2SProtocol.ledCount))
        }

        var packets = (0..<QS2SProtocol.dataPacketCount).map { idx -> [UInt8] in
            var p = [UInt8](repeating: 0, count: QS2SProtocol.packetSize)
            p[0] = QS2SProtocol.displayCode
            p[1] = QS2SProtocol.dataCmd
            p[2] = UInt8(idx)
            return p
        }

        for (t, color) in leds.enumerated() {
            let packet = t / QS2SProtocol.triplesPerPacket
            let pos = QS2SProtocol.headerOffset + (t % QS2SProtocol.triplesPerPacket) * 3
            packets[packet][pos] = color.r
            packets[packet][pos + 1] = color.g
            packets[packet][pos + 2] = color.b
        }
        return packets
    }

    public static func sequence(colors: [RGBColor]) -> [[UInt8]] {
        [headerPacket()] + dataPackets(colors: colors)
    }

    public static func sequence(solid color: RGBColor) -> [[UInt8]] {
        sequence(colors: Array(repeating: color, count: QS2SProtocol.ledCount))
    }
}
