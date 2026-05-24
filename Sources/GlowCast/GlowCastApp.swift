import SwiftUI

@main
struct GlowCastApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("GlowCast", systemImage: "mic.fill") {
            ContentView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)
    }
}
