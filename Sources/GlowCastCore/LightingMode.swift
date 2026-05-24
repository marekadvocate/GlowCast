import Foundation

public enum LightingMode: String, CaseIterable, Codable, Sendable {
    case solid, breathing, pulse, strobe, cycle, rainbow, wave, fire, police, party, reactive, vu

    public var displayName: String {
        switch self {
        case .solid:     return "Solid"
        case .breathing: return "Breathing"
        case .pulse:     return "Pulse"
        case .strobe:    return "Strobe"
        case .cycle:     return "Color Cycle"
        case .rainbow:   return "Rainbow"
        case .wave:      return "Wave"
        case .fire:      return "Fire"
        case .police:    return "Police"
        case .party:     return "Party"
        case .reactive:  return "Reactive"
        case .vu:        return "VU Meter"
        }
    }

    public var symbol: String {
        switch self {
        case .solid:     return "circle.fill"
        case .breathing: return "wind"
        case .pulse:     return "waveform.path"
        case .strobe:    return "bolt.fill"
        case .cycle:     return "arrow.triangle.2.circlepath"
        case .rainbow:   return "rainbow"
        case .wave:      return "water.waves"
        case .fire:      return "flame.fill"
        case .police:    return "light.beacon.max.fill"
        case .party:     return "party.popper.fill"
        case .reactive:  return "waveform"
        case .vu:        return "chart.bar.fill"
        }
    }
}
