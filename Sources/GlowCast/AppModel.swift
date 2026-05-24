import SwiftUI
import GlowCastCore

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings { didSet { store.save(settings) } }
    @Published var statusText: String = "Searching for QuadCast 2 S…"
    @Published var needsPermission = false

    private let store: SettingsStore
    private let hid = HIDDevice()
    private lazy var engine = DriverEngine(hid: hid)

    init(store: SettingsStore = .standard) {
        self.store = store
        self.settings = store.load()

        hid.onStateChange = { [weak self] st in self?.apply(st) }
        engine.settingsProvider = { [weak self] in self?.settings ?? .default }
        hid.start()
        engine.start()
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
