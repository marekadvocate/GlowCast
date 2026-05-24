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
        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: QS2SProtocol.vendorID,
            kIOHIDProductIDKey as String: QS2SProtocol.productID,
            kIOHIDPrimaryUsagePageKey as String: QS2SProtocol.usagePage,
            kIOHIDPrimaryUsageKey as String: QS2SProtocol.usage,
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
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func connect(_ dev: IOHIDDevice) {
        let r = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        switch r {
        case kIOReturnSuccess:    device = dev; state = .connected
        case kIOReturnNotPermitted: state = .notPermitted
        default: state = .error(String(format: "open 0x%08x", r))
        }
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
