import Foundation

public enum LightingMode: String, CaseIterable, Codable, Sendable {
    case solid, breathing, cycle, rainbow, strobe, pulse

    public var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .breathing: return "Breathing"
        case .cycle: return "Color Cycle"
        case .rainbow: return "Rainbow"
        case .strobe: return "Strobe"
        case .pulse: return "Pulse"
        }
    }
}
