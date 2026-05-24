import XCTest
@testable import GlowCastCore

final class PacketBuilderTests: XCTestCase {
    let cyan = RGBColor(r: 0x06, g: 0xb6, b: 0xd4)

    func testHeaderPacket() {
        let h = PacketBuilder.headerPacket()
        XCTAssertEqual(h.count, 64)
        XCTAssertEqual(Array(h.prefix(3)), [0x44, 0x01, 0x06])
        XCTAssertEqual(Array(h.suffix(60)), Array(repeating: 0, count: 60))
    }

    func testSolidSequenceShape() {
        let seq = PacketBuilder.sequence(solid: cyan)
        XCTAssertEqual(seq.count, 7)           // 1 header + 6 data
        for p in seq { XCTAssertEqual(p.count, 64) }
    }

    func testSolidDataPacket0MatchesDevice() {
        // First data packet from real device dump: 44 02 00 00 then cyan triples
        let p0 = PacketBuilder.sequence(solid: cyan)[1]
        XCTAssertEqual(Array(p0.prefix(16)),
            [0x44, 0x02, 0x00, 0x00,
             0x06, 0xb6, 0xd4, 0x06, 0xb6, 0xd4, 0x06, 0xb6, 0xd4, 0x06, 0xb6, 0xd4])
        // packet 0 is fully filled: 20 triples
        XCTAssertEqual(Array(p0.suffix(3)), [0x06, 0xb6, 0xd4])
    }

    func testSolidDataPacket5MatchesDevice() {
        // Last data packet: 44 02 05 00 + 8 cyan triples + 36 zero bytes
        let p5 = PacketBuilder.sequence(solid: cyan)[6]
        XCTAssertEqual(Array(p5.prefix(4)), [0x44, 0x02, 0x05, 0x00])
        // 8 triples = bytes 4..27 are cyan
        for t in 0..<8 {
            let i = 4 + t * 3
            XCTAssertEqual(Array(p5[i..<i+3]), [0x06, 0xb6, 0xd4], "triple \(t)")
        }
        // bytes 28..63 are zero
        XCTAssertEqual(Array(p5[28..<64]), Array(repeating: 0, count: 36))
    }

    func testPerLEDColors() {
        var colors = Array(repeating: RGBColor.black, count: 108)
        colors[0] = RGBColor(r: 1, g: 2, b: 3)
        colors[20] = RGBColor(r: 9, g: 8, b: 7)   // first triple of packet 1
        let data = PacketBuilder.dataPackets(colors: colors)
        XCTAssertEqual(Array(data[0][4..<7]), [1, 2, 3])
        XCTAssertEqual(Array(data[1][4..<7]), [9, 8, 7])
    }
}
