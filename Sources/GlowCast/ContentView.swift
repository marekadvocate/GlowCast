import SwiftUI
import GlowCastCore

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(model.settings.color) },
            set: { model.settings.colorHex = $0.rgbHex }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(model.needsPermission ? .orange : .green).frame(width: 8, height: 8)
                Text(model.statusText).font(.caption).foregroundStyle(.secondary)
            }

            if model.needsPermission {
                Button("Open Input Monitoring settings…") {
                    PermissionManager.openInputMonitoringSettings()
                }
            }

            Toggle("Lighting on", isOn: $model.settings.isOn)

            ColorPicker("Color", selection: colorBinding, supportsOpacity: false)

            Picker("Mode", selection: $model.settings.mode) {
                ForEach(LightingMode.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }

            VStack(alignment: .leading) {
                Text("Brightness \(model.settings.brightness)%").font(.caption)
                Slider(value: Binding(
                    get: { Double(model.settings.brightness) },
                    set: { model.settings.brightness = Int($0) }), in: 0...100)
            }

            if model.settings.mode != .solid {
                VStack(alignment: .leading) {
                    Text("Speed").font(.caption)
                    Slider(value: Binding(
                        get: { Double(model.settings.speed) },
                        set: { model.settings.speed = Int($0) }), in: 0...100)
                }
            }

            HStack {
                ForEach(model.settings.presets, id: \.self) { hex in
                    Button {
                        model.applyPreset(hex)
                    } label: {
                        Circle().fill(Color(GlowCastCore.RGBColor(hex: hex) ?? .black))
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(.secondary.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Toggle("Launch at login", isOn: Binding(
                get: { model.settings.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }))

            Button("Quit GlowCast") { NSApplication.shared.terminate(nil) }
        }
        .padding(14)
        .frame(width: 260)
    }
}

extension Color {
    init(_ c: GlowCastCore.RGBColor) {
        self.init(.sRGB, red: Double(c.r)/255, green: Double(c.g)/255, blue: Double(c.b)/255)
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
