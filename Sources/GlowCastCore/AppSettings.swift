import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var mode: LightingMode
    public var colorHex: String
    public var brightness: Int   // 0...100
    public var speed: Int        // 0...100
    public var isOn: Bool
    public var launchAtLogin: Bool
    public var presets: [String]

    public init(mode: LightingMode, colorHex: String, brightness: Int, speed: Int,
                isOn: Bool, launchAtLogin: Bool, presets: [String]) {
        self.mode = mode; self.colorHex = colorHex; self.brightness = brightness
        self.speed = speed; self.isOn = isOn; self.launchAtLogin = launchAtLogin
        self.presets = presets
    }

    public static let `default` = AppSettings(
        mode: .solid, colorHex: "06b6d4", brightness: 100, speed: 50,
        isOn: true, launchAtLogin: false,
        presets: ["06b6d4", "4b0082", "ffe0b2", "06ffd4"]
    )

    public var color: RGBColor { RGBColor(hex: colorHex) ?? .black }
}
