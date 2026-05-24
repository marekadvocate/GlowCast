import Foundation

public struct SettingsStore {
    private let defaults: UserDefaults
    private let key = "glowcast.settings"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public static var standard: SettingsStore { SettingsStore() }

    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .default }
        return s
    }

    public func save(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
