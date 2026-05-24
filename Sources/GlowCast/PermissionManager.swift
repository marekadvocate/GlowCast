import AppKit

enum PermissionManager {
    /// Opens System Settings → Privacy & Security → Input Monitoring.
    static func openInputMonitoringSettings() {
        let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }

    /// Opens System Settings → Privacy & Security → Microphone.
    static func openMicrophoneSettings() {
        let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }
}
