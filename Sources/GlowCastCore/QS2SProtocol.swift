import Foundation

public enum QS2SProtocol {
    public static let vendorID = 0x03f0
    public static let productID = 0x02b5      // QuadCast 2 S controller
    public static let usagePage = 0xff13       // vendor RGB collection
    public static let usage = 0xff00

    public static let packetSize = 64
    public static let dataPacketCount = 6
    public static let ledCount = 108
    public static let triplesPerPacket = 20    // (64-4 header bytes) / 3

    public static let displayCode: UInt8 = 0x44
    public static let headerCmd: UInt8 = 0x01  // QS2S_PACKET_CNT_CODE
    public static let dataCmd: UInt8 = 0x02    // QS2S_RGB_PACKET_CODE
    public static let headerOffset = 4         // bytes before triples in a data packet
}
