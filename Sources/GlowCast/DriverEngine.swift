import Foundation
import GlowCastCore

@MainActor
final class DriverEngine {
    private let hid: HIDDevice
    private var timer: DispatchSourceTimer?
    private var startTime = Date()

    /// The engine pulls current settings each frame.
    var settingsProvider: () -> AppSettings = { .default }

    init(hid: HIDDevice) { self.hid = hid }

    func start() {
        stop()
        startTime = Date()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .milliseconds(33), leeway: .milliseconds(5))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    func stop() { timer?.cancel(); timer = nil }

    private func tick() {
        let s = settingsProvider()
        let time = Date().timeIntervalSince(startTime)
        let colors = Animator.colors(mode: s.mode, base: s.color, brightness: s.brightness,
                                     speed: s.speed, on: s.isOn, audioLevel: 0, time: time)
        for packet in PacketBuilder.sequence(colors: colors) {
            hid.send(packet: packet)
        }
    }
}
