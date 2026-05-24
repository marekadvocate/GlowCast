import Foundation
import IOKit.hid
import GlowCastCore

@MainActor
final class HIDDevice {
    enum State: Equatable {
        case disconnected
        case connected
        case notPermitted
        case error(String)
    }

    private let manager: IOHIDManager
    private var device: IOHIDDevice?
    private(set) var state: State = .disconnected {
        didSet { if state != oldValue { onStateChange?(state) } }
    }
    var onStateChange: ((State) -> Void)?

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    func start() {
        // Match on VID+PID only. The vendor RGB collection (0xff13/0xff00) is a
        // NON-primary usage of the controller's interface, so primary-usage
        // matching misses it. We filter for the right interface in connect().
        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: QS2SProtocol.vendorID,
            kIOHIDProductIDKey as String: QS2SProtocol.productID,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { ctx, _, _, dev in
            MainActor.assumeIsolated {
                Unmanaged<HIDDevice>.fromOpaque(ctx!).takeUnretainedValue().connect(dev)
            }
        }, ctx)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { ctx, _, _, dev in
            MainActor.assumeIsolated {
                Unmanaged<HIDDevice>.fromOpaque(ctx!).takeUnretainedValue().remove(dev)
            }
        }, ctx)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult != kIOReturnSuccess {
            state = .error(String(format: "manager open 0x%08x", openResult))
        }
    }

    func stop() {
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func connect(_ dev: IOHIDDevice) {
        // Several HID interfaces share this VID:PID; only the one carrying the
        // vendor RGB collection (usage page 0xff13 / usage 0xff00) accepts packets.
        guard device == nil, hasVendorUsage(dev) else { return }
        let r = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        switch r {
        case kIOReturnSuccess:    device = dev; state = .connected
        case kIOReturnNotPermitted: state = .notPermitted
        default: state = .error(String(format: "open 0x%08x", r))
        }
    }

    private func hasVendorUsage(_ dev: IOHIDDevice) -> Bool {
        let pageKey = kIOHIDDeviceUsagePageKey as String
        let usageKey = kIOHIDDeviceUsageKey as String
        if let pairs = IOHIDDeviceGetProperty(dev, kIOHIDDeviceUsagePairsKey as CFString)
            as? [[String: Int]],
           pairs.contains(where: {
               $0[pageKey] == QS2SProtocol.usagePage && $0[usageKey] == QS2SProtocol.usage
           }) {
            return true
        }
        // Fallback: primary usage.
        let page = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int
        let usage = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? Int
        return page == QS2SProtocol.usagePage && usage == QS2SProtocol.usage
    }

    private func remove(_ dev: IOHIDDevice) {
        if dev == device { device = nil; state = .disconnected }
    }

    /// Send a single 64-byte output report (report id 0). Returns success.
    @discardableResult
    func send(packet: [UInt8]) -> Bool {
        guard let device else { return false }
        let r = packet.withUnsafeBufferPointer {
            IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, $0.baseAddress!, packet.count)
        }
        return r == kIOReturnSuccess
    }
}
