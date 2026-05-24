import SwiftUI
import GlowCastCore

// MARK: - Palette

private struct PaletteColor: Identifiable {
    let id: String  // hex
    let name: String
    var hex: String { id }
}

private let basicPalette: [PaletteColor] = [
    .init(id: "ff3b30", name: "Red"),
    .init(id: "ff9500", name: "Orange"),
    .init(id: "ffcc00", name: "Yellow"),
    .init(id: "34c759", name: "Green"),
    .init(id: "00c7be", name: "Mint"),
    .init(id: "30b0c7", name: "Teal"),
    .init(id: "06b6d4", name: "Cyan"),
    .init(id: "5ac8fa", name: "Light Blue"),
    .init(id: "007aff", name: "Blue"),
    .init(id: "5856d6", name: "Indigo"),
    .init(id: "af52de", name: "Purple"),
    .init(id: "ff2d55", name: "Pink"),
    .init(id: "ff00aa", name: "Magenta"),
    .init(id: "a2845e", name: "Brown"),
    .init(id: "ffe4b5", name: "Warm White"),
    .init(id: "ffffff", name: "White"),
]

// MARK: - Helpers

extension Color {
    init(_ c: GlowCastCore.RGBColor) {
        self.init(.sRGB, red: Double(c.r) / 255, green: Double(c.g) / 255, blue: Double(c.b) / 255)
    }

    /// Best-effort hex from a SwiftUI Color via NSColor.
    var rgbHex: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        let r = UInt8((ns.redComponent * 255).rounded())
        let g = UInt8((ns.greenComponent * 255).rounded())
        let b = UInt8((ns.blueComponent * 255).rounded())
        return GlowCastCore.RGBColor(r: r, g: g, b: b).hexString
    }
}

// MARK: - Root view

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(model.settings.color) },
            set: { model.settings.colorHex = $0.rgbHex }
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                StatusHeader()
                    .environmentObject(model)

                Divider().opacity(0.5)

                PowerAndHeroSection(colorBinding: colorBinding)
                    .environmentObject(model)

                Divider().opacity(0.5)

                ColorPaletteSection()
                    .environmentObject(model)

                Divider().opacity(0.5)

                ControlsSection(colorBinding: colorBinding)
                    .environmentObject(model)

                Divider().opacity(0.5)

                FooterSection()
                    .environmentObject(model)
            }
        }
        .frame(width: 300)
        // Let scroll view size itself; cap height for very small screens
        .frame(maxHeight: 620)
        .background(.regularMaterial)
    }
}

// MARK: - Status header

private struct StatusHeader: View {
    @EnvironmentObject var model: AppModel

    private var dotColor: Color {
        if model.needsPermission { return .orange }
        return model.statusText.contains("connected") ? .green : .secondary
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: dotColor.opacity(0.6), radius: 3)

                Text(model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if model.needsPermission {
                Button {
                    PermissionManager.openInputMonitoringSettings()
                } label: {
                    Label("Open Input Monitoring Settings", systemImage: "lock.shield")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Power + hero

private struct PowerAndHeroSection: View {
    @EnvironmentObject var model: AppModel
    let colorBinding: Binding<Color>

    private var currentColor: Color {
        Color(model.settings.color)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Color hero circle
            Circle()
                .fill(currentColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: currentColor.opacity(0.5), radius: 8)
                .overlay(
                    // Dim overlay when off
                    Circle()
                        .fill(Color.black.opacity(model.settings.isOn ? 0 : 0.45))
                        .animation(.easeInOut(duration: 0.2), value: model.settings.isOn)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("GlowCast")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(model.settings.mode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Prominent power toggle
            Toggle(isOn: $model.settings.isOn) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .controlSize(.regular)
            .tint(.green)
            .help(model.settings.isOn ? "Turn lighting off" : "Turn lighting on")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Color palette

private struct ColorPaletteSection: View {
    @EnvironmentObject var model: AppModel

    // 8 columns × 2 rows
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "Colors", icon: "paintpalette")

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(basicPalette) { entry in
                    ColorSwatch(entry: entry)
                        .environmentObject(model)
                }
            }

            // Custom color picker row
            HStack(spacing: 6) {
                ColorPicker("", selection: Binding(
                    get: { Color(model.settings.color) },
                    set: { model.settings.colorHex = $0.rgbHex }
                ), supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28, height: 28)

                Text("Custom color…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct ColorSwatch: View {
    @EnvironmentObject var model: AppModel
    let entry: PaletteColor

    @State private var isHovered = false

    private var isSelected: Bool {
        model.settings.colorHex.lowercased() == entry.hex.lowercased()
            && model.settings.mode == .solid
    }

    private var swatchColor: Color {
        Color(GlowCastCore.RGBColor(hex: entry.hex) ?? .black)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                model.settings.colorHex = entry.hex
                model.settings.mode = .solid
            }
        } label: {
            ZStack {
                Circle()
                    .fill(swatchColor)

                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                }
            }
            .frame(width: 28, height: 28)
            .shadow(color: swatchColor.opacity(isHovered ? 0.6 : 0.3), radius: isHovered ? 5 : 3)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(entry.name)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Controls (mode, brightness, speed, presets)

private struct ControlsSection: View {
    @EnvironmentObject var model: AppModel
    let colorBinding: Binding<Color>

    private var brightnessBinding: Binding<Double> {
        Binding(
            get: { Double(model.settings.brightness) },
            set: { model.settings.brightness = Int($0) }
        )
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { Double(model.settings.speed) },
            set: { model.settings.speed = Int($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode picker
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(title: "Mode", icon: "sparkles")

                Picker("", selection: $model.settings.mode) {
                    ForEach(LightingMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Brightness slider
            SliderRow(
                icon: "sun.max.fill",
                label: "Brightness",
                value: brightnessBinding,
                range: 0...100,
                valueLabel: "\(model.settings.brightness)%"
            )

            // Speed slider — only for animated modes
            if model.settings.mode != .solid {
                SliderRow(
                    icon: "hare.fill",
                    label: "Speed",
                    value: speedBinding,
                    range: 0...100,
                    valueLabel: "\(model.settings.speed)%"
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Presets row
            if !model.settings.presets.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(title: "Presets", icon: "bookmark")

                    HStack(spacing: 8) {
                        ForEach(model.settings.presets, id: \.self) { hex in
                            PresetSwatch(hex: hex)
                                .environmentObject(model)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.2), value: model.settings.mode)
    }
}

private struct SliderRow: View {
    let icon: String
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let valueLabel: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(valueLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range)
        }
    }
}

private struct PresetSwatch: View {
    @EnvironmentObject var model: AppModel
    let hex: String

    @State private var isHovered = false

    private var color: Color {
        Color(GlowCastCore.RGBColor(hex: hex) ?? .black)
    }

    var body: some View {
        Button {
            model.applyPreset(hex)
        } label: {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(.secondary.opacity(0.4), lineWidth: 1))
                .shadow(color: color.opacity(isHovered ? 0.5 : 0.2), radius: isHovered ? 4 : 2)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help("Apply preset #\(hex)")
        .onHover { isHovered = $0 }
    }
}

// MARK: - Footer (launch at login, quit)

private struct FooterSection: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 4) {
            Toggle(isOn: Binding(
                get: { model.settings.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            )) {
                Label("Launch at Login", systemImage: "arrow.clockwise.circle")
                    .font(.callout)
            }
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().opacity(0.5).padding(.vertical, 4)

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit GlowCast", systemImage: "power")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Reusable section label

private struct SectionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
