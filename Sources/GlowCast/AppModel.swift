import SwiftUI
import GlowCastCore

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            store.save(settings)
            updateAudio()
        }
    }
    @Published var statusText: String = "Searching for QuadCast 2 S…"
    @Published var needsPermission = false
    @Published var audioPermissionDenied = false

    private let store: SettingsStore
    private let hid = HIDDevice()
    private lazy var engine = DriverEngine(hid: hid)
    private let audioMonitor = AudioMonitor()

    init(store: SettingsStore = .standard) {
        self.store = store
        self.settings = store.load()

        hid.onStateChange = { [weak self] st in self?.apply(st) }
        engine.settingsProvider = { [weak self] in self?.settings ?? .default }
        engine.audioLevelProvider = { [weak self] in self?.audioMonitor.level ?? 0 }

        audioMonitor.onPermissionDenied = { [weak self] in
            // Already dispatched to main by AudioMonitor.start()
            self?.audioPermissionDenied = true
        }

        hid.start()
        engine.start()
        updateAudio()
    }

    /// Start or stop the audio monitor based on the current mode.
    private func updateAudio() {
        let needsAudio = settings.isOn &&
            (settings.mode == .reactive || settings.mode == .vu)
        if needsAudio {
            audioMonitor.start()
        } else {
            audioMonitor.stop()
        }
    }

    private func apply(_ state: HIDDevice.State) {
        switch state {
        case .connected:    statusText = "QuadCast 2 S connected"; needsPermission = false
        case .disconnected: statusText = "Mic not connected"; needsPermission = false
        case .notPermitted: statusText = "Input Monitoring permission needed"; needsPermission = true
        case .error(let m): statusText = "Error: \(m)"; needsPermission = false
        }
    }

    func setLaunchAtLogin(_ on: Bool) {
        settings.launchAtLogin = on
        LoginItemManager.setEnabled(on)
    }

    func applyPreset(_ hex: String) {
        settings.colorHex = hex
        settings.mode = .solid
    }
}
